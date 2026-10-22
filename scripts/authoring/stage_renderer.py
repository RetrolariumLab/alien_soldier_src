#!/usr/bin/env python3
"""Draw a stage the way the hardware would, from the data alone.

Everything the picture needs is already modelled and each piece was verified
on its own; this puts them together and nothing more:

  * `stage_tilemap_model` unfolds the coarse map, chunks and patterns into the
    name-table word for any world position;
  * the same asset lists that fill those maps fill VRAM, through asset command
    7, `LoadCompressedToVRAM`, which is the plain LZSS the project already
    decompresses;
  * `level_studio_model` reads the stage's configuration record, whose last
    longword names the palette offset list;
  * `palette_model` plays that list into sixty-four colours and
    `tile_graphics` turns a tile plus one of its lines into pixels.

A name-table word is a VDP word and is read as one: bits 0-10 the tile, bit 11
horizontal flip, bit 12 vertical, bits 13-14 the palette line, bit 15 priority.
Unlike a sprite mapping's attribute word, these are absolute -- nothing
exclusive-ors them against an object.

A stage draws two planes, not one, and the configuration record's two entry
modes say which maps each reads. They are composited the way the VDP layers
them: high-priority plane A, then high-priority plane B, then low-priority A,
then low-priority B, then the backdrop, with colour index 0 transparent
throughout. The backdrop is register 7, which `Gfx_GameVDPRegisterValues` sets
to $10 -- palette line one, colour zero -- and not the first colour of CRAM.

Nine transfers into VRAM use asset command 3, `Gfx_LoadCompressedGfx`, which
runs the bit-token codec in `src/rendering/tile_processing.s` rather than LZSS.
They are decoded by the independent cartridge codec model; this matters for
frontend screens even though no stage background reaches one of those streams.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field, replace
from pathlib import Path

from authoring.object_sprite_model import expand_tile_commands, read_visual_loaders, source_index
from authoring.palette_model import named_sets
from authoring.level_studio_model import stage_configurations
from authoring.stage_tilemap_model import (
    BACKDROP_REGISTER_VALUE,
    PLANE_A_TABLE,
    PLANE_B_TABLE,
    SHARED_LOADER,
    decompress,
    labelled_blocks,
    loader_lists,
    plane_descriptor,
    read_asset_lists,
    read_descriptors,
    read_plane_tables,
    stage_loaders,
    stage_tilemaps,
)
from authoring.tile_graphics import GRAPHICS_CONFIG, TILE_SIZE, decode_tile, write_png


COPY_TO_VRAM = 1  # LoadObjDataHandlers[1] is Gfx_LoadDataToVRAM
DECODE_TO_VRAM = 3  # ...[3] is Gfx_LoadCompressedGfx, the bit codec
DECOMPRESS_TO_VRAM = 7  # ...[7] is LoadCompressedToVRAM, plain LZSS
VRAM_SIZE = 0x10000
TILE_MASK = 0x07FF
HFLIP = 0x0800
VFLIP = 0x1000
PALETTE_SHIFT = 13
PRIORITY = 0x8000

# Scroll_UpdateQuarterHorizontalPosition is the stage parallax:
#     move.w  (PrimaryCameraXPosition).w,d0
#     asr.w   #2,d0
#     move.w  d0,(SecondaryCameraXPos).w
# so plane B moves at a quarter of plane A. A flat picture of a whole stage
# cannot show a parallax layer exactly - which part of it lines up with a given
# world position depends on where the camera is - so plane B is drawn as it
# would look with the camera at that point, which is what a level editor wants
# and is exact at the stage's starting camera. The first three stage slots use
# the absolute quarter-camera routine even when their configuration starts
# plane A partway through the level.
PARALLAX_SHIFT = 2
# The first three stage slots initially call Scroll_UpdateQuarterHorizontalPosition
# and stream only primary-plane columns. Their secondary plane keeps the
# 64-cell name table filled at stage entry and scrolls it as a 512-pixel ring.
# Later boss/transition effects are separate from this starting-scene model.
EARLY_STATIC_BACK_PLANE = frozenset((0, 1, 2))
BACK_PLANE_RING_PIXELS = 64 * TILE_SIZE


@dataclass
class Scene:
    """One stage table index, with everything needed to draw it."""

    index: int
    tilemap: object  # plane A, or None where the mode is a fill
    plane_b: object
    vram: bytes
    palette: list
    palette_name: str
    configuration: object
    missing_codecs: tuple  # (list, payload) pairs this model cannot decode
    backdrop: tuple = (0, 0, 0)
    planes: tuple = ()  # the descriptor each plane reads, for reporting
    parallax_shift: int = PARALLAX_SHIFT
    parallax_origin: int = 0  # plane A's configured starting camera X
    parallax_offset: int = 0  # plane B's configured starting camera X
    object_attribute: int = 0  # what Enemy_SetupBehaviorSprite puts in $E(a5)
    absolute_quarter_scroll: bool = False
    plane_b_wrap_pixels: int = 0
    object_attributes: dict[int, int] = field(default_factory=dict)

    def parallax_x(self, x):
        """Plane B's camera origin for a plane A camera position.

        The early-stage routine overwrites the configured secondary position
        with absolute primary X >> 2. Other scenes retain their configured
        origins. Screen pixels advance 1:1 after the camera origin is chosen;
        they must not themselves be divided by four.
        """
        if self.absolute_quarter_scroll:
            return x >> self.parallax_shift
        return ((x - self.parallax_origin) >> self.parallax_shift) + self.parallax_offset

    def plane_b_source_x(self, x):
        """Map the visible secondary-plane coordinate through its VRAM ring."""
        return x % self.plane_b_wrap_pixels if self.plane_b_wrap_pixels else x


def signed_word(value):
    return value - 0x10000 if value >= 0x8000 else value


def play_palette_command(root, name, words, colours):
    """Lay a palette command the visual loader plays over the stage's colours.

    Eighteen of the loaders play one before their tiles, and it is where the
    object palette line comes from; the stage's own offset list leaves that
    line empty.
    """
    from authoring.palette_model import command_index, read_source
    from authoring.tile_graphics import cram_to_rgb

    blocks, _ = read_source(root)
    commands, _ = command_index(blocks)
    command = commands.get((name, 0))
    if command is None:
        return colours
    played = list(colours)
    for step, word in enumerate(command.colours):
        played[command.first_colour + step] = cram_to_rgb(word)
    return played


def merge(vram, commands, data):
    """Lay the visual loader's transfers over the ones already in VRAM."""
    merged = bytearray(vram)
    for command in commands:
        if command.source not in data:
            continue
        body = decompress(data[command.source])
        merged[command.destination : command.destination + len(body)] = body
    return bytes(merged)


def build_vram(root, list_names, lists, data):
    """Play the lists' transfers into VRAM, and say what was skipped."""
    vram = bytearray(VRAM_SIZE)
    missing = []
    for name in list_names:
        for command in lists[name]:
            if command.source not in data or not isinstance(data[command.source], bytes):
                continue
            if command.command == DECOMPRESS_TO_VRAM:
                body = decompress(data[command.source])
            elif command.command == COPY_TO_VRAM:
                body = data[command.source]
            elif command.command == DECODE_TO_VRAM:
                from authoring.tile_codec import decompress as decode_tiles

                body = decode_tiles(data[command.source])
            else:
                continue
            at = command.destination
            vram[at : at + len(body)] = body
    return bytes(vram), tuple(missing)


_READ = {}


def read_once(root):
    """Everything a scene needs from the tree, read once per run.

    Drawing 26 stages otherwise reparses the whole of src/ 26 times. The cache
    is keyed on the tree and dropped by `forget`, which the tests use when they
    mean to read a changed tree.
    """
    key = str(Path(root).resolve())
    if key not in _READ:
        data, bodies = labelled_blocks(root)
        _READ[key] = {
            "data": data,
            "bodies": bodies,
            "lists": read_asset_lists(root, bodies),
            "loaders": stage_loaders(root, data),
            "tilemaps": stage_tilemaps(root),
            "configurations": stage_configurations(root),
            "palettes": {item["name"]: item for item in named_sets(root)},
            "descriptors": read_descriptors(root),
            "plane_tables": read_plane_tables(root),
            "not_reproduced": not_reproduced(root),
            "visual_loaders": read_visual_loaders(root),
            "source_index": source_index(root),
        }
    return _READ[key]


def forget(root=None):
    """Drop one changed source tree, or every cached tree when omitted."""
    if root is None:
        _READ.clear()
    else:
        _READ.pop(str(Path(root).resolve()), None)


def not_reproduced(root):
    """Stages whose planes the entry path cannot be replayed for.

    Declared rather than detected, because the reason is a routine the stage
    runs every frame rather than anything in the data: see the `why` beside
    each one in config/authoring/graphics.json.
    """
    config = json.loads((root / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
    return {item["index"]: item["why"] for item in config["stage_rendering"]["two_planes"]["planes_not_reproduced"]}


def planes_for(read, index, configuration=None):
    """The two planes a stage's configuration record asks for.

    Either can be None, which means the mode is zero and the plane is a
    constant fill of name-table word zero rather than a map.
    """
    configuration = configuration or read["configurations"][index]
    base = read["tilemaps"][index]
    if index in read["not_reproduced"]:
        name, offset = plane_descriptor(configuration.plane_a_mode, read["plane_tables"][PLANE_A_TABLE])
        plane = None if name is None else replace(base, descriptor=read["descriptors"][name], y_offset=offset)
        return [(plane, name or "constant fill"), (None, "not reproduced: " + read["not_reproduced"][index])]
    built = []
    for mode, table in ((configuration.plane_a_mode, PLANE_A_TABLE), (configuration.plane_b_mode, PLANE_B_TABLE)):
        name, offset = plane_descriptor(mode, read["plane_tables"][table], offset_variant=table == PLANE_A_TABLE)
        if name is None:
            built.append((None, "constant fill"))
            continue
        plane = replace(base, descriptor=read["descriptors"][name], y_offset=offset)
        # A mode can name a descriptor whose maps this stage never loaded --
        # Stage 18 asks for the alternate plane B and fills neither $FFFF6800
        # nor $FFFF2000. Reading them anyway produces noise, so an empty region
        # means the plane is not there, which is a fact about the asset lists
        # rather than a guess.
        if not (plane.region(plane.descriptor.chunks) and plane.region(plane.descriptor.patterns)):
            built.append((None, name + ", whose maps this stage does not load"))
            continue
        # Shared source maps do not make the two VDP planes interchangeable.
        # The entry streamer uses each plane's own camera and destination;
        # draw() samples them at independent origins before compositing. In
        # particular, the bounded editor viewport is not a flattened atlas.
        built.append((plane, name + ("+$%X" % offset if offset else "")))
    return built


def scene(root, index, palette_override="", configuration_override=None):
    """Assemble one stage table index into something drawable."""
    read = read_once(root)
    data, lists, loaders = read["data"], read["lists"], read["loaders"]
    if not 0 <= index < len(loaders):
        raise ValueError("stage table index %d is not one of 0..%d" % (index, len(loaders) - 1))
    bodies = read["bodies"]
    names = loader_lists(root, bodies, lists, SHARED_LOADER) + loader_lists(root, bodies, lists, loaders[index])
    vram, missing = build_vram(root, names, lists, data)

    # The second dispatch table. Stage_DispatchVisualAssetLoader submits a
    # compact command list of its own, which is both how a stage's object art
    # reaches VRAM and where SpawnedEnemyTileAttr comes from.
    lines, symbols = read["source_index"]
    visual, visual_palette = read["visual_loaders"][index] if index < len(read["visual_loaders"]) else ("", "")
    attributes = {}
    if visual:
        extra, attributes = expand_tile_commands(data, lines, symbols, visual)
        vram = merge(vram, extra, data)
    configuration = configuration_override or read["configurations"][index]
    (plane_a, name_a), (plane_b, name_b) = planes_for(read, index, configuration)

    wanted = palette_override or (configuration.palette_list if configuration else "")
    sets = read["palettes"]
    chosen = sets.get(wanted)
    if chosen is None:
        chosen = next((item for name, item in sets.items() if name.lower().startswith(str(wanted).lower())), None)
    if chosen is None:
        raise ValueError("no palette offset list named %s" % wanted)
    colours = list(chosen["rgb"])
    if visual_palette:
        colours = play_palette_command(root, visual_palette, chosen["words"], colours)
    backdrop = colours[((BACKDROP_REGISTER_VALUE >> 4) & 3) * 16 + (BACKDROP_REGISTER_VALUE & 0x0F)]
    if plane_b is not None:
        plane_b = replace(
            plane_b,
            y_offset=plane_b.y_offset
            + signed_word(configuration.camera_y)
            - signed_word(configuration.secondary_camera_y),
        )
    # Enemy_SetupBehaviorSprite: SpawnedEnemyTileAttr[0] or the stage's
    # GlobalSpritePriorityBit, stored at $E(a5).
    attribute = (attributes.get(0, 0) | configuration.sprite_priority) & 0xFFFF
    return Scene(
        index,
        plane_a,
        plane_b,
        vram,
        colours,
        chosen["name"],
        configuration,
        missing,
        backdrop,
        (name_a, name_b),
        PARALLAX_SHIFT,
        signed_word(configuration.camera_x),
        signed_word(configuration.secondary_camera_x),
        attribute,
        absolute_quarter_scroll=index in EARLY_STATIC_BACK_PLANE,
        plane_b_wrap_pixels=(BACK_PLANE_RING_PIXELS if index in EARLY_STATIC_BACK_PLANE else 0),
        object_attributes=attributes,
    )


def tile_rows(scene_, word, show_priority=False):
    """One name-table word as its colours, its indices and its priority.

    A wide stage draws tens of thousands of tiles and repeats almost all of
    them, so the work is done once per distinct word and then copied. The
    indices come back too, because compositing two planes needs to know which
    pixels are transparent, not only what colour they would be.
    """
    pixels = decode_tile(scene_.vram, (word & TILE_MASK) * 32)
    line = ((word >> PALETTE_SHIFT) & 3) * 16
    lift = 24 if (show_priority and word & PRIORITY) else 0
    colours, indices = [], []
    for at_y in range(TILE_SIZE):
        source_y = TILE_SIZE - 1 - at_y if word & VFLIP else at_y
        row = pixels[source_y * TILE_SIZE : (source_y + 1) * TILE_SIZE]
        if word & HFLIP:
            row = row[::-1]
        colour = [scene_.palette[line + index] for index in row]
        if lift:
            colour = [
                (min(255, red + lift), min(255, green + lift), min(255, blue + lift)) for red, green, blue in colour
            ]
        indices.append(row)
        colours.append(colour)
    return colours, indices, bool(word & PRIORITY)


def plane_rows(scene_, plane, x, y, cache, show_priority):
    """One tile of one plane, or None where the plane is a constant fill."""
    if plane is None or not plane.defined(x, y):
        return None
    word = plane.name_word(x, y)
    found = cache.get(word)
    if found is None:
        found = cache[word] = tile_rows(scene_, word, show_priority)
    return found


def plane_scanline(scene_, plane, camera_x, world_y, width, cache, show_priority, wrap_pixels=0):
    """Sample one plane, optionally wrapping a static VRAM name table."""
    colours = [scene_.backdrop] * width
    indices = [0] * width
    priorities = [False] * width
    tile_y = world_y - world_y % TILE_SIZE
    row = world_y % TILE_SIZE
    at = 0
    while at < width:
        world_x = (camera_x + at) % wrap_pixels if wrap_pixels else camera_x + at
        offset = world_x % TILE_SIZE
        span = min(TILE_SIZE - offset, width - at)
        tile = plane_rows(scene_, plane, world_x - offset, tile_y, cache, show_priority)
        if tile is not None:
            tile_colours, tile_indices, priority = tile
            colours[at : at + span] = tile_colours[row][offset : offset + span]
            indices[at : at + span] = tile_indices[row][offset : offset + span]
            priorities[at : at + span] = [priority] * span
        at += span
    return colours, indices, priorities


def draw(scene_, x=0, y=0, width=512, height=224, show_priority=False, cache=None):
    """Composite two one-to-one planes at independent scroll-camera origins."""
    cache = {} if cache is None else cache
    back_x = scene_.parallax_x(x)
    image = []
    for screen_y in range(height):
        front = plane_scanline(scene_, scene_.tilemap, x, y + screen_y, width, cache, show_priority)
        back = plane_scanline(
            scene_, scene_.plane_b, back_x, y + screen_y, width, cache, show_priority, scene_.plane_b_wrap_pixels
        )
        front_colours, front_indices, front_priorities = front
        back_colours, back_indices, back_priorities = back
        row = []
        for at in range(width):
            if front_indices[at] and front_priorities[at]:
                row.append(front_colours[at])
            elif back_indices[at] and back_priorities[at]:
                row.append(back_colours[at])
            elif front_indices[at]:
                row.append(front_colours[at])
            elif back_indices[at]:
                row.append(back_colours[at])
            else:
                row.append(scene_.backdrop)
        image.append(row)
    return image


def compose(front, back, at_y, span, backdrop):
    """One row of eight pixels of plane A over plane B.

    High-priority A, then high-priority B, then low-priority A, then
    low-priority B, then the backdrop. Index zero is transparent in both.
    """
    if front is None and back is None:
        return [backdrop] * span
    if back is None:
        colours, indices, _ = front
        return [colours[at_y][at] if indices[at_y][at] else backdrop for at in range(span)]
    if front is None:
        colours, indices, _ = back
        return [colours[at_y][at] if indices[at_y][at] else backdrop for at in range(span)]

    front_colours, front_indices, front_priority = front
    back_colours, back_indices, back_priority = back
    opaque = front_indices[at_y]
    if all(opaque[:span]) and (front_priority or not back_priority):
        return front_colours[at_y][:span]
    if not any(opaque[:span]) and all(back_indices[at_y][:span]):
        return back_colours[at_y][:span]

    out = []
    for at in range(span):
        ahead = opaque[at]
        behind = back_indices[at_y][at]
        if ahead and front_priority:
            out.append(front_colours[at_y][at])
        elif behind and back_priority:
            out.append(back_colours[at_y][at])
        elif ahead:
            out.append(front_colours[at_y][at])
        elif behind:
            out.append(back_colours[at_y][at])
        else:
            out.append(backdrop)
    return out


def render_to_png(
    root,
    index,
    output,
    x=0,
    y=0,
    width=512,
    height=224,
    palette_override="",
    scale=1,
    show_priority=False,
    objects=False,
):
    built = scene(root, index, palette_override)
    image = draw(built, x, y, width, height, show_priority)
    if objects:
        from authoring.level_studio_state import open_stage, overlay_placements

        overlay_placements(open_stage(root, index, palette_override), image, x, y)
    if scale > 1:
        image = [[pixel for pixel in row for _ in range(scale)] for row in image for _ in range(scale)]
    write_png(root / output, image)
    return built
