#!/usr/bin/env python3
"""Work out what a placed object looks like, without running the game.

A spawn entry names a handler, not a picture. Getting from one to the other
takes three links, and each is in the code rather than in the data.

**The animation script.** An object's `8(a5)` holds either a sprite mapping or
a script, and `Anim_ResolveTimedMappingFrame` in
`src/rendering/sprite_object_pipeline.s` is the format:

    addq.w  #4,a4           ; entries are four bytes
    move.w  2(a4),d0        ; the duration
    bne.s   ...             ; zero means the first word is a jump instead
    adda.w  (a4),a4
    ...
    adda.w  (a4),a4         ; the mapping is at this word plus its own address

so an entry is a signed offset to a mapping and a duration, and the source
writes the offset as `Mapping-*`, which resolves by name with no addresses at
all. A duration of zero turns the first word into a relative jump, which is
how a script loops.

**Which script a handler uses.** Most handlers write it straight in, as
`move.l #Something,8(a5)`; the rest pick from a table with
`move.l Table(pc,d0.w),8(a5)`, whose first entry is the resting state. What is
written can be a script or a mapping, because `2(a5)` bit 5 says which, so both
are followed.

**The object's base tile.** A static mapping's tile index is relative, and
`Enemy_SetupBehaviorSprite` supplies the base:

    move.w  (SpawnedEnemyTileAttr).w,d1
    or.w    (GlobalSpritePriorityBit).w,d1
    move.w  d1,$E(a5)

`SpawnedEnemyTileAttr` is filled by `Stage_ExpandAndSubmitTileAssetCommands`
from the stage's compact tile commands, as `(destination >> 5) | $800` -- the
tile number the art was uploaded to, with bit 11 set so that a mapping piece's
own bit 11 exclusive-ors back to no flip.

Those compact commands are also how a stage's object art reaches VRAM at all,
through a second dispatch table, `Stage_VisualAssetLoaderOffsets`, that the
tilemap model never followed.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from authoring.stage_tilemap_model import (                          # noqa: E402
    AssetCommand, SHARED_LOADER, SOURCE_ROOT, labelled_blocks,
    loader_lists, parse_number, source_texts)


VISUAL_SOURCE = Path("src/stages/visual_asset_loading.s")
VISUAL_TABLE = "Stage_VisualAssetLoaderOffsets"
VISUAL_ANCHOR = "Stage_ExpandAndSubmitTileAssetCommands"
SHARED_TILE_SOURCES = "Stage_SharedTileSourceTable"
DECOMPRESS_TO_VRAM = 7           # what the expansion writes for an indexed command
TILE_ATTRIBUTE_BIT = 0x0800      # ori.w #$800 on every SpawnedEnemyTileAttr entry
TILE_SHIFT = 5                   # lsr.w #5: a VRAM address to a tile number
FULL_COMMAND_BIT = 1             # btst #0: an odd word is a whole record
WEAPON_SELECTION_HANDLER = "UI_WeaponSelectionObject"
WEAPON_SELECTION_ART_SOURCE = "SharedMenuType3DataF680"
WEAPON_SELECTION_ART_START = 0xF680
WEAPON_SELECTION_ART_END = 0x10000

LABEL_LINE = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*):(?P<rest>.*)$")
DIRECTIVE = re.compile(r"^\s*(?P<kind>dc\.[bwl])\s+(?P<body>[^;]+?)\s*(?:;.*)?$")
VISUAL_ENTRY = re.compile(
    r"^\s*dc\.w\s+([A-Za-z_][A-Za-z0-9_]*)-" + VISUAL_ANCHOR + r"\s*(?:;.*)?$")
LEA_COMMANDS = re.compile(r"^\s+lea\s+([A-Za-z_][A-Za-z0-9_]*)\(pc\),a0\s*(?:;.*)?$")
LEA_PALETTE = re.compile(r"^\s+lea\s+\(([A-Za-z_][A-Za-z0-9_]*)\)\.l,a0\s*(?:;.*)?$")
RELATIVE_FRAME = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)-\*$")
SET_ANIMATION = re.compile(r"^\s+move\.l\s+#([A-Za-z_][A-Za-z0-9_]*),8\(a5\)")
SET_FROM_TABLE = re.compile(
    r"^\s+move\.l\s+([A-Za-z_][A-Za-z0-9_]*)\(pc,\w+\.w\),8\(a5\)")
CALLS = re.compile(r"^\s+(?:bsr|jsr|bra|jmp)\S*\s+\(?([A-Za-z_][A-Za-z0-9_]*)")
POINTER_ENTRY = re.compile(r"^\s*dc\.l\s+([A-Za-z_][A-Za-z0-9_]*)")
ROUTINE_LIMIT = 200              # lines to read before giving up on an end marker


@dataclass(frozen=True)
class Frame:
    """One entry of an animation script."""

    mapping: str
    duration: int

    @property
    def is_jump(self):
        """A duration of zero makes the first word a relative jump, not a frame."""
        return self.duration == 0


def source_index(root):
    """Every label in the assembly, and the lines that follow it."""
    lines = {}
    index = {}
    for path, source in source_texts(root):
        text = source.split("\n")
        lines[path] = text
        for number, line in enumerate(text):
            head = LABEL_LINE.match(line)
            if head and head.group("name") not in index:
                index[head.group("name")] = (path, number)
    return lines, index


def routine(lines, index, name, limit=ROUTINE_LIMIT):
    """One routine's body, up to its end marker."""
    if name not in index:
        return []
    path, at = index[name]
    body = []
    for line in lines[path][at:at + limit]:
        body.append(line)
        if line.startswith("; End of function "):
            break
    return body


def read_animation_scripts(root):
    """Animation scripts, read from the source text so the offsets stay symbolic.

    `labelled_blocks` turns `dc.w` into numbers, and the whole point of a frame
    is the symbol it names, so this reads the tokens instead.
    """
    from authoring.stage_tilemap_model import _read_operation
    active = _read_operation(root)
    if active is not None:
        return active.animation_scripts()
    return _parse_animation_scripts(root)


def _parse_animation_scripts(root, *, original=None):
    """The unchanged symbolic dc.w parser over fresh or ORIGINAL source texts."""
    scripts = {}
    sources = (original.texts() if original is not None else
               ((path, path.read_text(encoding="utf-8"))
                for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s"))))
    for _path, source in sources:
        name = None
        kind = None
        tokens = []

        def flush():
            if not (name and tokens and kind == "dc.w" and len(tokens) % 2 == 0):
                return
            frames = []
            for at in range(0, len(tokens), 2):
                head = RELATIVE_FRAME.match(tokens[at])
                if head is None:
                    return
                try:
                    duration = parse_number(tokens[at + 1])
                except ValueError:
                    return
                frames.append(Frame(head.group(1), duration))
            if frames:
                scripts[name] = tuple(frames)

        for line in source.split("\n"):
            head = LABEL_LINE.match(line)
            if head:
                flush()
                name, kind, tokens = head.group("name"), None, []
                line = head.group("rest")
            directive = DIRECTIVE.match(line)
            if directive is None or name is None:
                continue
            if kind is None:
                kind = directive.group("kind")
            elif kind != directive.group("kind"):
                continue
            tokens.extend(token.strip() for token in directive.group("body").split(","))
        flush()
    return scripts


def read_pointer_table(lines, index, name):
    """The symbols a `dc.l` table names, in order."""
    if name not in index:
        return []
    path, at = index[name]
    found = []
    for line in lines[path][at:]:
        head = LABEL_LINE.match(line)
        if head and found:
            break
        if head:
            line = head.group("rest")
        entry = POINTER_ENTRY.match(line)
        if entry:
            found.append(entry.group(1))
        elif line.strip() and not line.strip().startswith(";") and found:
            break
    return found


def resting_candidates(lines, index, handler, depth=0, seen=None):
    """Every symbol a handler could put in 8(a5), tagged with how it got there."""
    seen = seen if seen is not None else set()
    if depth > 3 or handler in seen:
        return []
    seen.add(handler)
    body = routine(lines, index, handler)
    found = []
    for line in body:
        table = SET_FROM_TABLE.match(line)
        if table:
            entries = read_pointer_table(lines, index, table.group(1))
            if entries:
                found.append(("table", entries[0]))
        direct = SET_ANIMATION.match(line)
        if direct:
            found.append(("direct", direct.group(1)))
    for line in body:
        call = CALLS.match(line)
        if call:
            found.extend(resting_candidates(lines, index, call.group(1), depth + 1, seen))
    return found


def resting_symbol(lines, index, handler):
    """What a handler shows at rest: a script or a mapping, by name.

    A table indexed by the object's state has the resting state first, so it is
    preferred over an unconditional immediate wherever both are reachable. In a
    controller an immediate is as likely to be the defeat frame as the idle one
    -- Enemy_BehaviorController reaches Enemy_BehaviorDefeatSpriteAnimation
    before it reaches Enemy_BehaviorSpriteAnimationPointers.
    """
    if handler == STAGE12_TEDDY_HANDLER:
        return stage12_teddy_resting_symbol(lines, index)
    found = resting_candidates(lines, index, handler)
    for kind in ("table", "direct"):
        for at, symbol in found:
            if at == kind:
                return symbol
    return ""


def read_visual_loaders(root):
    """StageTableIndex to the tile commands and palette command it submits.

    Eighteen of the twenty-six play a palette command before their tiles, and
    that is where the object palette line comes from: without it an enemy draws
    as a correctly shaped black silhouette, because the stage's own offset list
    leaves line three empty for it.
    """
    text = (root / VISUAL_SOURCE).read_text(encoding="utf-8").split("\n")
    routines = []
    for number, line in enumerate(text):
        if not line.startswith(VISUAL_TABLE + ":"):
            continue
        for follow in text[number:]:
            match = VISUAL_ENTRY.match(follow.replace(VISUAL_TABLE + ":", " " * 8))
            if match:
                routines.append(match.group(1))
            elif follow.strip() and not follow.strip().startswith(";") and routines:
                break
        break
    lines, index = source_index(root)
    chosen = []
    for name in routines:
        commands = ""
        palette = ""
        for line in routine(lines, index, name):
            match = LEA_COMMANDS.match(line)
            if match and not commands:
                commands = match.group(1)
            match = LEA_PALETTE.match(line)
            if match and not palette:
                palette = match.group(1)
        chosen.append((commands, palette))
    return chosen


def _full_tile_command_sources(lines, index, name):
    """Recover `dc.l` owners omitted from labelled_blocks' word tuples."""
    if name not in index:
        return []
    path, start = index[name]
    found = []
    for offset, line in enumerate(lines[path][start:]):
        head = LABEL_LINE.match(line)
        if head and offset:
            break
        if head:
            line = head.group("rest")
        pointer = POINTER_ENTRY.match(line)
        if pointer:
            found.append(pointer.group(1))
    return found


def expand_tile_commands(blocks, lines, index, name):
    """One compact tile command list, as asset commands and tile attributes.

    A word with bit 0 clear is an index into `Stage_SharedTileSourceTable`
    followed by a VRAM destination; one with bit 0 set is a whole record of
    command, source and destination copied through. A negative word ends it.
    """
    words = blocks.get(name)
    sources = read_pointer_table(lines, index, SHARED_TILE_SOURCES)
    full_sources = _full_tile_command_sources(lines, index, name)
    commands = []
    attributes = {}
    if not isinstance(words, tuple):
        return commands, attributes
    at = 0
    full_at = 0
    while at < len(words):
        value = words[at]
        if value & 0x8000:
            break
        if value & FULL_COMMAND_BIT:
            if at + 1 >= len(words) or full_at >= len(full_sources):
                raise ValueError("full tile command has no source or destination: " + name)
            commands.append(AssetCommand(value, full_sources[full_at], words[at + 1]))
            full_at += 1
            at += 2  # labelled_blocks omits the dc.l pointer from its word tuple
            continue
        if at + 1 >= len(words):
            break
        destination = words[at + 1]
        entry = value // 2
        if entry < len(sources):
            commands.append(AssetCommand(DECOMPRESS_TO_VRAM, sources[entry], destination))
        attributes[value] = ((destination >> TILE_SHIFT) | TILE_ATTRIBUTE_BIT) & 0xFFFF
        at += 2
    if full_at != len(full_sources):
        raise ValueError("full tile command source count differs: " + name)
    return commands, attributes


def _source_code(lines, index, name):
    return "\n".join(line.split(";", 1)[0]
                     for line in routine(lines, index, name))


def weapon_selection_initial_attribute(lines, index, priority):
    """Read the source-backed attribute at the stage-configuration snapshot."""
    if priority not in (0, 0x8000):
        return None
    initialized = _source_code(lines, index, "UI_InitWeaponSelectionObject")
    configured = _source_code(lines, index, "Stage_ApplyConfigurationRecord")
    if not re.search(
            r"\bmove\.w\s+\(GlobalSpritePriorityBit\)\.w,\$E\(a5\)", initialized):
        return None
    if not re.search(
            r"\bmove\.w\s+\(a0\)\+,\(GlobalSpritePriorityBit\)\.w", configured):
        return None
    return priority


def weapon_selection_carried_art(root, stage_index):
    """Prove the normal stage-entry art at VRAM $F680..$FFFF survives loading."""
    from authoring.lzss_codec import decompress as decode_lzss
    from authoring.stage_renderer import read_once
    from authoring.tile_codec import decompress as decode_tiles

    read = read_once(root)
    lines, index = read["source_index"]
    ready = _source_code(lines, index, "StageReady_Initialize")
    reset = _source_code(lines, index, "Gfx_ClearStagingAndFirst48KiBVRAM")
    if (not re.search(r"\bmovea\.l\s+#StageEntryAssetLoadList,a0", ready)
            or not re.search(r"\bjsr\s+\(LoadObjData\)\.l", ready)
            or not re.search(r"\bbsr\.w\s+Gfx_ClearVRAMFirst48KiB", reset)):
        return None

    data, lists = read["data"], read["lists"]
    entry_list = lists.get("StageEntryAssetLoadList", ())
    entry = [(at, command) for at, command in enumerate(entry_list)
             if command.source == WEAPON_SELECTION_ART_SOURCE]
    if (len(entry) != 1 or entry[0][1].command != 3
            or entry[0][1].destination != WEAPON_SELECTION_ART_START):
        return None
    raw = data.get(WEAPON_SELECTION_ART_SOURCE)
    if not isinstance(raw, bytes):
        return None
    art = decode_tiles(raw)
    if len(art) != WEAPON_SELECTION_ART_END - WEAPON_SELECTION_ART_START:
        return None

    if not 0 <= stage_index < len(read["loaders"]):
        return None
    names = (loader_lists(root, read["bodies"], lists, SHARED_LOADER)
             + loader_lists(root, read["bodies"], lists, read["loaders"][stage_index]))
    commands = list(entry_list[entry[0][0] + 1:])
    commands.extend(command for name in names for command in lists[name])
    visual, _palette = read["visual_loaders"][stage_index]
    if visual:
        extra, _attributes = expand_tile_commands(data, lines, index, visual)
        commands.extend(extra)
    for command in commands:
        # Both loader tables route 0/2/4/6 to RAM and 1/5 to raw VRAM copies.
        # An unmodelled handler cannot prove that the carried range survives.
        if command.command in (0, 2, 4, 6):
            continue
        if command.command not in (1, 3, 5, 7):
            return None
        raw = data.get(command.source)
        if not isinstance(raw, bytes):
            return None
        if command.command in (1, 5):
            # The first word is the byte count, not art. Require a complete,
            # positive longword-aligned body, safe for the immediate reader's
            # lsr.w #2 / subq.w #1 / dbf loop as well as the queued DMA reader.
            if len(raw) < 2:
                return None
            size = int.from_bytes(raw[:2], "big")
            if not 0 < size < 0x8000 or size % 4 or size + 2 > len(raw):
                return None
        else:
            size = len(decode_tiles(raw) if command.command == 3 else
                       decode_lzss(raw))
        if not 0 <= command.destination < WEAPON_SELECTION_ART_END:
            return None
        if command.destination + size > WEAPON_SELECTION_ART_START:
            return None
    return art


OBJECT_TILE_MASK = 0x07FF
OBJECT_ATTRIBUTE_MASK = 0xF800   # what Sprite_RenderMapping exclusive-ors


def resolve_mapping(symbol, scripts, mappings):
    """The mapping a resting symbol names, whether or not it is a script."""
    if symbol in scripts:
        frames = [frame for frame in scripts[symbol] if not frame.is_jump]
        symbol = frames[0].mapping if frames else scripts[symbol][0].mapping
    return mappings.get(symbol)


def compose_static(mapping, vram, palette, attribute, background=None):
    """Draw a static mapping through an object's tile attribute.

    `Sprite_RenderMapping` does `eor.w d7,d1` on bits 11-15 and `add.w d2,d1`
    on the tile, where d7 and d2 are the object's attribute split at $F800 and
    $7FF, so both the flips and the tile index of a piece are relative to the
    object rather than absolute.

    Bit 11 of the object does more than that. `btst #$B,d7` picks a different
    offset path for the whole mapping, and that path reflects every piece:
    `neg.w d0` on its X and then minus its own width less one tile. Bit 12 does
    the same downward, minus its height. So an object carrying either is not
    drawn with mirrored pieces in the same places -- the places move too, and
    leaving that out puts the right arm where the left one goes.

    Sprite_RenderMapping emits OAM entries in mapping order. At equal VDP
    priority the earlier entry wins overlapping nontransparent pixels, so
    software compositing paints the entries from last to first.
    """
    from authoring.tile_graphics import TILE_SIZE, decode_tile

    base = attribute & OBJECT_TILE_MASK
    high = attribute & OBJECT_ATTRIBUTE_MASK
    reflect_x, reflect_y = bool(high & 0x0800), bool(high & 0x1000)
    placed = []
    for piece in mapping.pieces:
        at_x, at_y = piece.x, piece.y
        if reflect_x:
            at_x = -at_x - (piece.tiles_wide - 1) * TILE_SIZE
        if reflect_y:
            at_y = -at_y - piece.tiles_high * TILE_SIZE
        placed.append((piece, at_x, at_y))
    if not placed:
        return [], 0, 0
    left = min(at_x for _, at_x, _ in placed)
    top = min(at_y for _, _, at_y in placed)
    width = max(at_x + piece.tiles_wide * TILE_SIZE
                for piece, at_x, _ in placed) - left
    height = max(at_y + piece.tiles_high * TILE_SIZE
                 for piece, _, at_y in placed) - top
    image = [[background] * width for _ in range(height)]
    for piece, piece_x, piece_y in reversed(placed):
        combined = (piece.attributes & OBJECT_ATTRIBUTE_MASK) ^ high
        line = ((combined >> 13) & 3) * 16
        flip_x, flip_y = bool(combined & 0x0800), bool(combined & 0x1000)
        tile = (base + piece.tile) & OBJECT_TILE_MASK
        for column in range(piece.tiles_wide):
            for row in range(piece.tiles_high):
                index = tile + column * piece.tiles_high + row
                if (index + 1) * 32 > len(vram):
                    continue
                pixels = decode_tile(vram, index * 32)
                at_column = piece.tiles_wide - 1 - column if flip_x else column
                at_row = piece.tiles_high - 1 - row if flip_y else row
                for y in range(TILE_SIZE):
                    for x in range(TILE_SIZE):
                        value = pixels[(TILE_SIZE - 1 - y if flip_y else y) * TILE_SIZE
                                       + (TILE_SIZE - 1 - x if flip_x else x)]
                        if not value:
                            continue
                        at_y = piece_y - top + at_row * TILE_SIZE + y
                        at_x = piece_x - left + at_column * TILE_SIZE + x
                        if 0 <= at_y < height and 0 <= at_x < width:
                            image[at_y][at_x] = palette[line + value]
    return image, left, top


SET_ATTRIBUTE = re.compile(r"^\s+move\.w\s+#\$([0-9A-Fa-f]+),\$E\(a[05]\)")
OFFSET_DISPATCH = re.compile(r"^\s+movea\.w\s+([A-Za-z_][A-Za-z0-9_]*)\(pc,\w+\.w\),a\d")
OFFSET_ENTRY = re.compile(
    r"^\s*dc\.w\s+([A-Za-z_][A-Za-z0-9_]*)-(?:\*|[A-Za-z_][A-Za-z0-9_]*)\s*(?:;.*)?$")
BEHAVIOUR_SETUP = "Enemy_SetupBehaviorSprite"
FAMILY_TILE_READERS = {
    "Enemy_BirdController": (
        "Enemy_DispatchBirdState", "Enemy_BirdStateOffsets",
        "Enemy_BirdInit", "Enemy_InitBirdSprite", "BirdEnemyTileAttr", "d1", "relative"),
    "Enemy_CirclingController": (
        "Enemy_DispatchCirclingState", "Enemy_CirclingStateOffsets",
        "Enemy_CirclingApproachState", "Enemy_InitCirclingSprite",
        "CirclingEnemyTileAttr", "d1", "relative"),
    "Enemy_HomingAttackController": (
        "Enemy_DispatchHomingAttackState", "Enemy_HomingAttackStateOffsets",
        "Enemy_HomingAttackInit", "Sprite_InitializeProjectileSprite",
        "EnemyProjectileTileAttr", "d0", "absolute_base"),
    "Enemy_PhasePatternController": (
        "Enemy_DispatchPhasePatternState", "Enemy_PhasePatternStateOffsets",
        "Enemy_PhasePatternInit", "Enemy_SetupPhasePatternSprite",
        "PhaseEnemyTileAttr", "d1", "relative"),
    "Enemy_Stage10WaspController": (
        "Enemy_DispatchStage10WaspState", "Enemy_Stage10WaspStateOffsets",
        "Enemy_Stage10WaspInitState", "Enemy_Stage10WaspInit",
        "Stage10WaspTileAttr", "d1", "relative"),
}
INDEXED_SPRITE_HANDLER = "Object_InitIndexedSpriteGraphics"
STAGE18_PLATFORM_HANDLER = "Stage18_MovingPlatform"
STAGE12_TEDDY_HANDLER = "Stage12_TeddyBearMain"


def stage12_teddy_resting_symbol(lines, index):
    """Follow only the teddy bear's state-zero dispatch and paired sprite setup."""
    controller = "\n".join(routine(lines, index, STAGE12_TEDDY_HANDLER))
    if not re.search(
            r"\bmove\.w\s+4\(a5\),d0\s*\n"
            r"\s*movea\.w\s+Stage12_TeddyBearStateTable\(pc,d0\.w\),a0\s*\n"
            r"\s*adda\.l\s+#Stage12_TeddyBearInit,a0\s*\n"
            r"\s*jmp\s+\(a0\)", controller):
        return ""
    if read_offset_table(lines, index, "Stage12_TeddyBearStateTable")[:1] != [
            "Stage12_TeddyBearInit"]:
        return ""
    initializer = "\n".join(routine(lines, index, "Stage12_TeddyBearInit"))
    match = re.search(
        r"\bmove\.w\s+#\$8000,\$E\(a5\)\s*\n"
        r"\s*move\.l\s+#([A-Za-z_][A-Za-z0-9_]*),8\(a5\)",
        initializer)
    return match.group(1) if match else ""


def stage18_platform_variant(lines, index, stage_index):
    """Select the platform mapping and base from its guarded stage-index branch."""
    if (isinstance(stage_index, bool) or not isinstance(stage_index, int)
            or not 0 <= stage_index < 26):
        return None
    body = "\n".join(routine(lines, index, STAGE18_PLATFORM_HANDLER))
    if not re.search(
            r"\btst\.w\s+4\(a5\)\s*\n"
            r"\s*bne\.w\s+Stage18_MovingPlatform_Update\s*\n"
            r"\s*addq\.w\s+#2,4\(a5\)", body):
        return None
    if not re.search(
            r"\bmove\.l\s+#Stage18MovingPlatformSpriteMapping,8\(a5\)\s*\n"
            r"\s*move\.w\s+#\$4470,\$E\(a5\)\s*\n"
            r"\s*cmpi\.w\s+#\$18,\(StageTableIndex\)\.w\s*\n"
            r"\s*bcc\.s\s+Stage18_MovingPlatform_FinishInit\s*\n"
            r"\s*move\.l\s+#Stage18_MovingPlatformSpriteMapping,8\(a5\)\s*\n"
            r"\s*move\.w\s+#\$4000,\$E\(a5\)", body):
        return None
    if stage_index < 0x18:
        return "Stage18_MovingPlatformSpriteMapping", 0x4000
    return "Stage18MovingPlatformSpriteMapping", 0x4470


def indexed_sprite_entries(lines, index):
    """Read the interleaved eight-byte pointer/attribute selector table."""
    body = "\n".join(routine(lines, index, INDEXED_SPRITE_HANDLER))
    spawner = "\n".join(routine(lines, index, "Sys_SpawnObject"))
    required = (
        r"\bmove\.w\s+\$5E\(a5\),d0",
        r"\bbclr\s+#\$F,d0",
        r"\bmove\.l\s+Object_IndexedSpriteAnimationPointers\(pc,d0\.w\),8\(a5\)",
        r"\bmove\.w\s+Object_IndexedSpriteAttributes\(pc,d0\.w\),\$E\(a5\)",
    )
    if (not re.search(r"\bmove\.w\s+6\(a4\),\$5E\(a5\)", spawner)
            or any(not re.search(pattern, body) for pattern in required)):
        raise ValueError("indexed sprite selector source route differs")
    name = "Object_IndexedSpriteAnimationPointers"
    attr_name = "Object_IndexedSpriteAttributes"
    if name not in index or attr_name not in index:
        raise ValueError("indexed sprite selector table is missing")
    path, at = index[name]
    attr_path, attr_at = index[attr_name]
    if path != attr_path or attr_at != at + 1:
        raise ValueError("indexed sprite pointer and attribute rows differ")
    values = []
    for row in lines[path][at:]:
        label = LABEL_LINE.match(row)
        if label:
            if len(values) == 0 and label.group("name") != name:
                break
            if len(values) == 1 and label.group("name") != attr_name:
                break
            if len(values) > 1:
                break
            row = label.group("rest")
        entry = re.match(r"^\s*dc\.l\s+([^\s;]+)", row)
        if entry is None:
            if values and row.strip() and not row.strip().startswith(";"):
                break
            continue
        values.append(entry.group(1))
    if not values or len(values) % 2:
        raise ValueError("indexed sprite table is not complete eight-byte records")
    records = []
    for at in range(0, len(values), 2):
        symbol = values[at]
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", symbol):
            raise ValueError("indexed sprite animation entry is not symbolic")
        packed = parse_number(values[at + 1])
        if not 0 <= packed <= 0xFFFFFFFF:
            raise ValueError("indexed sprite attribute entry is not a longword")
        records.append((symbol, packed >> 16))
    return tuple(records)


def selected_indexed_sprite_entry(entries, parameter):
    """Bit 15 changes graphics mode; remaining bits index eight-byte records."""
    if (isinstance(parameter, bool) or not isinstance(parameter, int)
            or not 0 <= parameter <= 0xFFFF):
        return None
    offset = parameter & 0x7FFF
    if offset % 8 or offset // 8 >= len(entries):
        return None
    return entries[offset // 8]


def tile_attribute_slots(root):
    """Byte offsets from the expander's first RAM destination, not guessed slots."""
    text = (root / "src/ram_addrs.inc").read_text(encoding="utf-8")
    values = {}
    for symbol in ("SpawnedEnemyTileAttr", "EnemyProjectileTileAttr",
                   "BirdEnemyTileAttr", "PhaseEnemyTileAttr",
                   "Stage10WaspTileAttr", "CirclingEnemyTileAttr"):
        match = re.search(r"^" + symbol + r"\s+equ\s+\$([0-9A-Fa-f]+)\b",
                          text, re.MULTILINE)
        if match is None:
            raise ValueError("missing RAM tile attribute symbol: " + symbol)
        values[symbol] = int(match.group(1), 16)
    base = values.pop("SpawnedEnemyTileAttr")
    offsets = {name: address - base for name, address in values.items()}
    if any(offset < 0 or offset % 2 or offset >= 16
           for offset in offsets.values()):
        raise ValueError("enemy family tile attributes are outside the command slots")
    return offsets


def read_offset_table(lines, index, name):
    """The routines a `dc.w Target-Anchor` dispatch table names."""
    if name not in index:
        return []
    path, at = index[name]
    found = []
    for line in lines[path][at:]:
        head = LABEL_LINE.match(line)
        if head and found:
            break
        if head:
            line = head.group("rest")
        entry = OFFSET_ENTRY.match(line)
        if entry:
            found.append(entry.group(1))
        elif line.strip() and not line.strip().startswith(";") and found:
            break
    return found


def reachable(lines, index, handler, limit=5):
    """Every routine a handler can reach, nearest first.

    A state machine is entered with `movea.w Table(pc,d0.w),a0` and a `jmp`,
    which no amount of following `bsr` will discover, and that is exactly how
    Enemy_BehaviorController reaches Enemy_SetupBehaviorSprite.

    The order is breadth first and it matters: the answer is whichever routine
    nearest the handler sets the thing being looked for. Returning a set here
    made the result depend on hash order, so the same tree gave two different
    tile bases on two different runs.
    """
    seen = [handler] if handler in index else []
    frontier = list(seen)
    for _ in range(limit):
        following = []
        for name in frontier:
            for line in routine(lines, index, name):
                call = CALLS.match(line)
                if call and call.group(1) in index and call.group(1) not in seen:
                    seen.append(call.group(1))
                    following.append(call.group(1))
                table = OFFSET_DISPATCH.match(line)
                if table:
                    for target in read_offset_table(lines, index, table.group(1)):
                        if target in index and target not in seen:
                            seen.append(target)
                            following.append(target)
        if not following:
            break
        frontier = following
    return seen


def _family_attribute(lines, index, handler, attributes, priority, slots,
                      parameter):
    """Prove the state-zero initializer and its stage-owned RAM tile slot."""
    route = FAMILY_TILE_READERS.get(handler)
    if route is None or not attributes:
        return None
    dispatch, table, first_state, initializer, symbol, register, style = route
    if (symbol == "PhaseEnemyTileAttr" and
            (parameter is None or parameter & 0x80)):
        return None
    if not any((match := CALLS.match(line)) and match.group(1) == dispatch
               for line in routine(lines, index, handler)):
        return None
    dispatch_body = "\n".join(routine(lines, index, dispatch))
    if style == "relative":
        if not re.search(r"\blea\s+" + table + r"\(pc,d0\.w\),a0", dispatch_body):
            return None
        if not re.search(r"\badda\.w\s+\(a0\),a0\s*\n\s*jmp\s+\(a0\)",
                         dispatch_body):
            return None
    else:
        if not re.search(r"\bmovea\.w\s+" + table +
                         r"\(pc,d0\.w\),a0\s*\n\s*adda\.l\s+#" +
                         first_state + r",a0\s*\n\s*jmp\s+\(a0\)",
                         dispatch_body):
            return None
    targets = read_offset_table(lines, index, table)
    if not targets or targets[0] != first_state:
        return None
    if initializer != first_state and not any(
            (match := CALLS.match(line)) and match.group(1) == initializer
            for line in routine(lines, index, first_state)):
        return None
    init_body = "\n".join(routine(lines, index, initializer))
    if not re.search(
            r"\bmove\.w\s+\(" + symbol + r"\)\.w," + register + r"\s*\n"
            r"\s*or\.w\s+\(GlobalSpritePriorityBit\)\.w," + register + r"\s*\n"
            r"\s*move\.w\s+" + register + r",\$E\(a5\)", init_body):
        return None
    slot = slots.get(symbol)
    if slot not in attributes:
        return None
    return (attributes[slot] | priority) & 0xFFFF, "stage " + symbol


def _spawn_parameter_attribute(lines, index, handler, parameter):
    """Follow the type-$48 initializer's bit-1 choice from the spawn word."""
    if handler != "Object_UpdateProximityPickupEmitterType48" or (
            isinstance(parameter, bool) or not isinstance(parameter, int)
            or not 0 <= parameter <= 0xFFFF):
        return None
    spawner = "\n".join(routine(lines, index, "Sys_SpawnObject"))
    if not re.search(r"\bmove\.w\s+6\(a4\),\$5E\(a5\)", spawner):
        return None
    body = "\n".join(routine(lines, index, handler))
    match = re.search(
        r"\bmove\.w\s+#\$([0-9A-Fa-f]+),d0\s*\n"
        r"\s*btst\s+#([0-7]),\$5F\(a5\)\s*\n"
        r"\s*beq\.s\s+([A-Za-z_][A-Za-z0-9_]*)\s*\n"
        r"\s*bset\s+#\$([0-9A-Fa-f]+),d0\s*\n"
        r"\3:[^\n]*\n\s*move\.w\s+d0,\$E\(a5\)", body)
    if match is None:
        return None
    base, input_bit, attribute_bit = (
        int(match.group(1), 16), int(match.group(2)), int(match.group(4), 16))
    value = base | ((1 << attribute_bit) if parameter & (1 << input_bit) else 0)
    return value & 0xFFFF, "spawn parameter bit %d" % input_bit


def _stage12_floater_attribute(lines, index, handler):
    """Accept the floater's constructed base only through its state-zero route."""
    if handler != "Enemy_Stage12FloaterController":
        return None
    controller = "\n".join(routine(lines, index, handler))
    dispatch = "Enemy_DispatchStage12FloaterState"
    table = "Enemy_Stage12FloaterStateOffsets"
    first_state = "Enemy_Stage12FloaterInitState"
    initializer = "Enemy_InitStage12FloatingSprite"
    if not re.search(r"\bbsr\.s\s+" + dispatch, controller):
        return None
    dispatch_body = "\n".join(routine(lines, index, dispatch))
    if not re.search(r"\blea\s+" + table + r"\(pc,d0\.w\),a0\s*\n"
                     r"\s*adda\.w\s+\(a0\),a0\s*\n\s*jmp\s+\(a0\)",
                     dispatch_body):
        return None
    if read_offset_table(lines, index, table)[:1] != [first_state]:
        return None
    state = "\n".join(routine(lines, index, first_state))
    if not re.search(r"\bmoveq\s+#0,d0\s*\n\s*bsr\.w\s+" + initializer,
                     state):
        return None
    body = "\n".join(routine(lines, index, initializer))
    if not re.search(r"\bmoveq\s+#0,d1\s*\n"
                     r"\s*ori\.w\s+#\$8000,d1\s*\n"
                     r"\s*move\.w\s+d1,\$E\(a5\)", body):
        return None
    return 0x8000, "stage 12 floater initializer"


def resting_attribute(lines, index, handler, stage_default,
                      stage_attributes=None, priority=0, slots=None,
                      parameter=None, stage_index=None):
    """The tile attribute a handler gives its object, and how it was found.

    Enemy_MainStateMachine enters Enemy_SetupBehaviorSprite with d0 zero, so
    the behaviour family takes SpawnedEnemyTileAttr[0] or'd with the stage's
    priority bit; everything else that sets $E(a5) does it with an immediate.
    A handler that does neither is reported rather than drawn with somebody
    else's tiles.
    """
    if handler == STAGE18_PLATFORM_HANDLER:
        variant = stage18_platform_variant(lines, index, stage_index)
        return ((variant[1], "stage-index platform branch") if variant is not None
                else (None, ""))
    for name in reachable(lines, index, handler):
        for line in routine(lines, index, name):
            found = SET_ATTRIBUTE.match(line)
            if found:
                return int(found.group(1), 16), "immediate"
    parameter_attribute = _spawn_parameter_attribute(lines, index, handler, parameter)
    if parameter_attribute is not None:
        return parameter_attribute
    family = _family_attribute(lines, index, handler,
                               stage_attributes or {}, priority, slots or {},
                               parameter)
    if family is not None:
        return family
    floater = _stage12_floater_attribute(lines, index, handler)
    if floater is not None:
        return floater
    if BEHAVIOUR_SETUP in reachable(lines, index, handler):
        return stage_default, "the stage default"
    return None, ""
