#!/usr/bin/env python3
"""What the Level Studio knows, with no window attached.

The window is Tk and cannot be tested without a display; what it shows can be.
Everything here is the studio minus its widgets: which stage is open, where
each placement lands on the drawn background, which one is selected, and what
an edit does to it.

Placing an object over the background needs one fact that neither model holds
on its own. `Sys_SpawnObject` writes

    move.w  (a4),d0 / sub.w (PrimaryCameraXPosition).w,d0 / addi.w #$80,d0
    move.w  2(a4),d1 / add.w (PrimaryCameraYPosition).w,d1

so an object's coordinates are OAM coordinates, biased by $80, and the camera
is folded into both. The streamer folds the camera into the background the
other way -- `neg.w d1` on the camera Y, and a column queued at camera X plus
$158. Cancel the camera out of both and the two land in the same space:

    map X = entry X
    map Y = entry Y - $80

which is why a placement can be drawn on the background without knowing where
the camera happens to be. The bias is the only constant in it, and it is the
$80 the spawner adds.
"""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass, replace
from pathlib import Path

from authoring.level_studio_model import (
    CONFIG_FIELDS,
    FIELD_ORDER,
    SIZE_LIMIT,
    SpawnEntry,
    SpawnList,
    StageConfiguration,
    apply_document,
    editable_stage_slot_locations,
    export_document,
    handler_names,
    read_source_lists,
    stage_configurations,
    validate_document,
)
from authoring.map_reference_guard import periodic_reference_error, visible_reference_errors
from authoring.ram_map_workspace import merged_edit_streams, resolve_map_cell
from authoring.stage_renderer import draw, read_once, scene
from authoring.stage_tilemap_model import build_ram


# Object coordinates are OAM coordinates; Sys_SpawnObject adds $80 to X and the
# sprite hardware carries the same bias in Y.
OAM_BIAS = 0x80
EDITABLE_FIELDS = ("x", "y", "object_type", "parameter", "slot_first", "slot_limit")
WORD_MAXIMUM = 0xFFFF
DEFAULT_MAP_DESCRIPTOR = "Gfx_DefaultVRAMTransferParameters"
MAP_VIEW_WIDTH = 960
MAP_VIEW_HEIGHT = 288
MAP_PAGE_STEP = 896


@dataclass
class Placement:
    """One spawn entry, and where it lands on the drawn background."""

    index: int
    entry: SpawnEntry
    handler: str

    @property
    def map_x(self):
        return self.entry.x

    @property
    def map_y(self):
        return self.entry.y - OAM_BIAS

    @property
    def gate(self):
        if self.entry.hard_only:
            return "hard only"
        if self.entry.easy_only:
            return "easy only"
        return ""

    def describe(self):
        return "%s at $%X,$%X%s" % (
            self.handler or "type $%X" % self.entry.object_type,
            self.entry.x,
            self.entry.y,
            "  (%s)" % self.gate if self.gate else "",
        )


def locate_stage_map_cell(studio, document, x, y, role, plane_name="plane_a", camera_a_x=0):
    """Trace a viewport pixel through a selected plane to its RAM writer.

    Plane B uses its camera origin for the viewport, not a quarter-scaled
    screen pixel. Its alternate descriptor is allowed only when the final
    RAM writer is already a source-owned record in the stage-map document.
    """
    if type(x) is not int or type(y) is not int or not 0 <= x < studio.width or not 0 <= y < 8192:
        raise ValueError("point is outside the stage map preview")
    if plane_name == "plane_a":
        plane = studio.scene.tilemap
        default = read_once(studio.root)["descriptors"][DEFAULT_MAP_DESCRIPTOR]
        if plane is None or (plane.descriptor.coarse, plane.descriptor.chunks, plane.descriptor.patterns) != (
            default.coarse,
            default.chunks,
            default.patterns,
        ):
            raise ValueError("plane A has no supported default map descriptor")
        world_x = x
    elif plane_name == "plane_b":
        if type(camera_a_x) is not int or not 0 <= camera_a_x <= x:
            raise ValueError("invalid plane A camera origin for plane B")
        plane = studio.scene.plane_b
        if plane is None:
            raise ValueError("plane B has no supported map")
        world_x = studio.scene.plane_b_source_x(studio.scene.parallax_x(camera_a_x) + x - camera_a_x)
    else:
        raise ValueError("stage map plane must be plane_a or plane_b")
    return resolve_map_cell(plane, document, world_x, y, role)


@dataclass
class Studio:
    """One stage, open for looking at and changing."""

    root: Path
    index: int
    scene: object
    spawn_list: object
    placements: list
    handlers: dict
    profile: str = "jp"
    document_data: dict | None = None
    selection: int = -1
    edited: bool = False
    source_scene: object | None = None
    map_document: dict | None = None
    map_baseline: dict | None = None
    screen_document: dict | None = None
    screen_baseline: dict | None = None
    palette_override: str = ""

    @property
    def spawn_list_name(self):
        return self.spawn_list.name if self.spawn_list else ""

    @property
    def width(self):
        """As wide as the stage defines chunks, which is its scrollable extent.

        Either plane can be absent: an entry mode of zero fills the plane with
        one word and reads no map, and index 16 does exactly that for plane A.
        """
        planes = [plane for plane in (self.scene.tilemap, self.scene.plane_b) if plane is not None]
        return max([256] + [plane.chunks_defined * 256 for plane in planes])

    def selected(self):
        if 0 <= self.selection < len(self.placements):
            return self.placements[self.selection]
        return None

    def spawn_trigger_x(self, index):
        """The camera threshold for this row is the prefix maximum of X values."""
        if not 0 <= index < len(self.placements):
            raise ValueError("no placement %d" % index)
        return max(placement.entry.x for placement in self.placements[: index + 1])

    @property
    def configuration(self):
        return self.scene.configuration

    @property
    def route_editable(self):
        return self.index in editable_stage_slot_locations(self.root)

    def _install_document(self, candidate):
        """Build a complete replacement before exposing any changed live state."""
        validate_document(candidate, self.root, self.profile)
        refreshed = open_stage(
            self.root,
            self.index,
            palette_override=self.palette_override,
            profile=self.profile,
            document=candidate,
            map_document=self.map_document,
            map_baseline=self.map_baseline,
            screen_document=self.screen_document,
            screen_baseline=self.screen_baseline,
        )
        old_spawn_name = self.spawn_list_name
        self.document_data = candidate
        self.scene = refreshed.scene
        self.source_scene = refreshed.source_scene
        self.spawn_list = refreshed.spawn_list
        self.placements = refreshed.placements
        if old_spawn_name != self.spawn_list_name or self.selection >= len(self.placements):
            self.selection = -1
        self.edited = True

    def set_stage_configuration(self, name):
        """Route a plain stage wrapper to a known configuration record."""
        if not self.route_editable:
            raise ValueError("this stage has a fixed special initializer route")
        if name == self.configuration.name:
            return self.configuration
        candidate = self.document()
        candidate["stage_slots"][self.index]["configuration"] = name
        self._install_document(candidate)
        return self.configuration

    def set_configuration_fields(self, values):
        """Validate and replace all fields of this stage's shared record.

        Several stage slots intentionally share a configuration record. The
        workspace document models that fact, so editing one slot updates every
        slot that names the same record rather than cloning hidden ROM data.
        """
        if self.configuration is None:
            raise ValueError("this stage slot has no configuration record")
        document = self.document()
        candidate = deepcopy(document)
        record = next(item for item in candidate["configurations"] if item["name"] == self.configuration.name)
        parsed = {}
        for field, size in CONFIG_FIELDS:
            raw = str(values[field]).strip()
            if not raw:
                raise ValueError("%s may not be empty" % field)
            if field in {"spawn_list", "palette_list"} and not (raw.startswith("$") or raw[0].isdigit()):
                parsed[field] = raw
                continue
            number = int(raw[1:], 16) if raw.startswith("$") else int(raw)
            if not 0 <= number <= SIZE_LIMIT[size]:
                raise ValueError("%s must fit dc.%s" % (field, size))
            parsed[field] = number
        record["fields"] = parsed
        self._install_document(candidate)
        return self.configuration

    def select_at(self, map_x, map_y, radius=16):
        """The nearest placement to a point, or none within reach."""
        best, distance = -1, radius * radius
        for placement in self.placements:
            gap = (placement.map_x - map_x) ** 2 + (placement.map_y - map_y) ** 2
            if gap <= distance:
                best, distance = placement.index, gap
        self.selection = best
        return self.selected()

    def set_fields(self, index, values):
        """Validate a complete placement edit before changing live studio state."""
        if not 0 <= index < len(self.placements):
            raise ValueError("no placement %d" % index)
        if not values or any(field not in EDITABLE_FIELDS for field in values):
            raise ValueError("placement edit has no supported fields")
        placement = self.placements[index]
        fields = dict(placement.entry.__dict__)
        for field, value in values.items():
            raw = str(value).strip()
            number = int(raw[1:], 16) if raw.startswith("$") else int(raw)
            if not 0 <= number <= WORD_MAXIMUM:
                raise ValueError("%s must be a word, 0 to $FFFF, not %d" % (field, number))
            fields[field] = number
        changed = SpawnEntry(**fields)
        handler = self.handlers.get(changed.object_type & ~3, "")
        candidate = self.document()
        record = next(item for item in candidate["spawn_lists"] if item["name"] == self.spawn_list.name)
        record["entries"][index] = {**fields, "handler": handler}
        validate_document(candidate, self.root, self.profile)
        self.placements[index] = Placement(index, changed, handler)
        self.spawn_list.entries[index] = changed
        self.document_data = candidate
        self.edited = True
        return self.placements[index]

    def set_field(self, index, field, value):
        """Change one field of one placement, or say why it cannot be changed."""
        return self.set_fields(index, {field: value})

    def image(self, x, y, width, height, cache=None):
        return draw(self.scene, x, y, width, height, cache=cache)

    def refresh_map_preview(self, map_document, map_baseline, screen_document=None, screen_baseline=None):
        """Rebuild from the unedited scene so reverting a cell restores it."""
        refreshed = preview_stage_maps(
            self.root, self.source_scene or self.scene, map_document, map_baseline, screen_document, screen_baseline
        )
        self.scene = refreshed
        self.map_document = map_document
        self.map_baseline = map_baseline
        self.screen_document = screen_document
        self.screen_baseline = screen_baseline

    def document(self):
        """The whole tree as a document, with this stage's edits folded in.

        The document is built from the tree and only the list being edited is
        replaced, so a stage nobody changed cannot be rewritten by having been
        looked at.
        """
        document = deepcopy(
            self.document_data if self.document_data is not None else export_document(self.root, self.profile)
        )
        if self.spawn_list is None:
            return document
        for item in document["spawn_lists"]:
            if item["name"] != self.spawn_list.name:
                continue
            item["entries"] = [
                {
                    "x": placement.entry.x,
                    "y": placement.entry.y,
                    "object_type": placement.entry.object_type,
                    "parameter": placement.entry.parameter,
                    "slot_first": placement.entry.slot_first,
                    "slot_limit": placement.entry.slot_limit,
                    "handler": placement.handler,
                }
                for placement in self.placements
            ]
        self.document_data = document
        return document

    def write_back(self, write=False):
        """Report staged changes; canonical write-back is intentionally forbidden."""
        if write:
            raise ValueError("Level Studio may write only through the staged content build")
        return apply_document(self.document(), self.root, self.profile, write=False)


def _document_configurations(document):
    """Return stage configurations in slot order from a workspace document."""
    records = {item["name"]: StageConfiguration(item["name"], item["fields"]) for item in document["configurations"]}
    return [records.get(slot["configuration"]) for slot in document["stage_slots"]]


def stage_rows(root, document=None):
    """Every stage table index, as the studio's stage chooser lists it."""
    if document is None:
        lists = {item.name: item for item in read_source_lists(root)[0]}
        configurations = stage_configurations(root)
    else:
        lists = {item["name"]: item for item in document["spawn_lists"]}
        configurations = _document_configurations(document)
    rows = []
    for index, configuration in enumerate(configurations):
        name = configuration.spawn_list if configuration else ""
        spawn = lists.get(name) if isinstance(name, str) else None
        rows.append(
            {
                "index": index,
                "record": configuration.name if configuration else "",
                "spawn_list": name if isinstance(name, str) else "$%08X" % name,
                "placements": (
                    len(spawn.entries) if isinstance(spawn, SpawnList) else len(spawn["entries"]) if spawn else 0
                ),
                "palette": configuration.palette_list if configuration else "",
            }
        )
    return rows


def _spawn_list_from_document(root, document, name):
    """Materialize one editable list while preserving source-owned metadata."""
    if not isinstance(name, str):
        return None
    originals = {item.name: item for item in read_source_lists(root)[0]}
    original = originals.get(name)
    record = next((item for item in document["spawn_lists"] if item["name"] == name), None)
    if original is None or record is None:
        return None
    entries = [SpawnEntry(*(entry[field] for field in FIELD_ORDER)) for entry in record["entries"]]
    return SpawnList(original.name, original.storage, original.payload, entries, original.terminated)


def preview_stage_maps(root, built, map_document, map_baseline, screen_document=None, screen_baseline=None):
    """Replay edited RAM streams into a scene without writing source files.

    The caller supplies a validated document. Replaying the loader order is
    essential: a later RAM transfer can cover an earlier edit to the same
    address, just as it does in the cartridge.
    """
    base = built.tilemap or built.plane_b
    if base is None:
        return built
    loaded = {source for _list, source, _offset, _length in base.written}
    pairs = [(map_document, map_baseline)]
    if screen_document is not None:
        if screen_baseline is None:
            raise ValueError("a source-owned screen-map baseline is required for preview")
        pairs.append((screen_document, screen_baseline))
    changed = merged_edit_streams(*pairs, only_names=loaded)
    if not changed:
        return built
    read = read_once(root)
    data = dict(read["data"])
    data.update(changed)
    ram, written = build_ram(root, base.lists, read["lists"], data)
    updates = {"ram": ram, "written": tuple(written)}
    return replace(
        built,
        tilemap=replace(built.tilemap, **updates) if built.tilemap else None,
        plane_b=replace(built.plane_b, **updates) if built.plane_b else None,
    )


def validate_stage_scene_references(source, candidate, width, index, profile):
    """Check editor pages, then every addressable cell in the map period."""
    last_page = max(0, width - MAP_VIEW_WIDTH)
    pages = sorted(set((*range(0, last_page + 1, MAP_PAGE_STEP), last_page)))
    for page_x in pages:
        record = {
            "id": "stage %d page $%X" % (index, page_x),
            "camera_a_x": page_x,
            "camera_a_y": {profile: 0},
            "width": min(MAP_VIEW_WIDTH, width - page_x),
            "height": MAP_VIEW_HEIGHT,
        }
        errors = visible_reference_errors(source, candidate, record, profile)
        if errors:
            raise ValueError("new undefined stage map reference: " + errors[0])
    error = periodic_reference_error(source, candidate, "stage %d" % index)
    if error is not None:
        raise ValueError("new undefined periodic stage map reference: " + error)


def validate_stage_map_references(
    root, profile, level_document, map_document, map_baseline, screen_document, screen_baseline
):
    """Check every stage reached by a changed map stream before content build."""
    changed = merged_edit_streams((map_document, map_baseline), (screen_document, screen_baseline))
    if not changed:
        return
    indices = sorted(
        {
            use["stage_table_index"]
            for record in map_baseline["payloads"]
            if record["name"] in changed
            for use in record["uses"]
        }
    )
    for index in indices:
        studio = open_stage(
            root,
            index,
            profile=profile,
            document=level_document,
            map_document=map_document,
            map_baseline=map_baseline,
            screen_document=screen_document,
            screen_baseline=screen_baseline,
        )
        validate_stage_scene_references(studio.source_scene, studio.scene, studio.width, index, profile)


def open_stage(
    root,
    index,
    palette_override="",
    profile="jp",
    document=None,
    map_document=None,
    map_baseline=None,
    screen_document=None,
    screen_baseline=None,
):
    configurations = _document_configurations(document) if document is not None else stage_configurations(root)
    if not 0 <= index < len(configurations):
        raise ValueError("stage table index %d is not one of 0..%d" % (index, len(configurations) - 1))
    configuration = configurations[index]
    palette = palette_override
    if not palette and configuration and isinstance(configuration.palette_list, str):
        palette = configuration.palette_list
    built = scene(root, index, palette, configuration_override=configuration)
    source_scene = built
    if map_document is not None:
        if map_baseline is None:
            raise ValueError("a source-owned map baseline is required for preview")
        built = preview_stage_maps(root, built, map_document, map_baseline, screen_document, screen_baseline)
    if document is None:
        lists = {item.name: item for item in read_source_lists(root)[0]}
    else:
        lists = None
    name = configuration.spawn_list if configuration else ""
    spawn = (
        lists.get(name)
        if lists is not None and isinstance(name, str)
        else _spawn_list_from_document(root, document, name)
        if document is not None
        else None
    )
    handlers = handler_names(root)
    placements = []
    if spawn:
        placements = [
            Placement(at, entry, handlers.get(entry.object_type & ~3, "")) for at, entry in enumerate(spawn.entries)
        ]
    return Studio(
        root,
        index,
        built,
        spawn,
        placements,
        handlers,
        profile,
        deepcopy(document) if document is not None else None,
        source_scene=source_scene,
        map_document=map_document,
        map_baseline=map_baseline,
        screen_document=screen_document,
        screen_baseline=screen_baseline,
        palette_override=palette_override,
    )


def sprite_library(root):
    """Everything needed to turn a handler into a picture, read once."""
    from authoring.object_sprite_model import (
        indexed_sprite_entries,
        read_animation_scripts,
        source_index,
        tile_attribute_slots,
    )
    from authoring.sprite_mapping_model import read_blocks

    blocks, _ = read_blocks(root)
    mappings = {}
    for block in blocks:
        if block.mappings:
            mappings.setdefault(block.name, block.mappings[0])
    lines, index = source_index(root)
    return {
        "scripts": read_animation_scripts(root),
        "mappings": mappings,
        "lines": lines,
        "index": index,
        "resting": {},
        "attributes": {},
        "tile_slots": tile_attribute_slots(root),
        "indexed_sprites": indexed_sprite_entries(lines, index),
    }


def resting_mapping(library, handler, parameter=None, stage_index=None):
    """The mapping a handler shows at rest, or None when the chain stops."""
    from authoring.object_sprite_model import (
        INDEXED_SPRITE_HANDLER,
        STAGE18_PLATFORM_HANDLER,
        resolve_mapping,
        resting_symbol,
        stage18_platform_variant,
        selected_indexed_sprite_entry,
    )

    if handler == STAGE18_PLATFORM_HANDLER:
        variant = stage18_platform_variant(library["lines"], library["index"], stage_index)
        if variant is None:
            return "", None
        symbol = variant[0]
        return symbol, library["mappings"].get(symbol)

    if handler == INDEXED_SPRITE_HANDLER:
        selected = selected_indexed_sprite_entry(library["indexed_sprites"], parameter)
        if selected is None:
            return "", None
        symbol = selected[0]
        return symbol, resolve_mapping(symbol, library["scripts"], library["mappings"])

    if handler not in library["resting"]:
        symbol = resting_symbol(library["lines"], library["index"], handler)
        library["resting"][handler] = (
            symbol,
            resolve_mapping(symbol, library["scripts"], library["mappings"]) if symbol else None,
        )
    return library["resting"][handler]


def object_attribute(
    library, handler, stage_default, *, stage_attributes=None, priority=0, parameter=None, stage_index=None
):
    """The tile attribute a handler gives its object, or None when unknown.

    A mapping's tile index is relative, so drawing one through the wrong base
    shows a different enemy's art in the right shape. That is worse than a
    marker, so a handler whose own attribute cannot be found is not drawn.
    """
    from authoring.object_sprite_model import (
        INDEXED_SPRITE_HANDLER,
        WEAPON_SELECTION_HANDLER,
        resting_attribute,
        selected_indexed_sprite_entry,
        weapon_selection_initial_attribute,
    )

    if handler == INDEXED_SPRITE_HANDLER:
        selected = selected_indexed_sprite_entry(library["indexed_sprites"], parameter)
        return (selected[1], "indexed sprite table") if selected is not None else (None, "")

    if handler == WEAPON_SELECTION_HANDLER:
        if stage_index is None:
            return None, ""
        initial = weapon_selection_initial_attribute(library["lines"], library["index"], priority)
        return (
            (initial, "initial stage configuration priority; runtime can change") if initial is not None else (None, "")
        )

    stage_attributes = stage_attributes or {}
    key = (handler, stage_default, tuple(sorted(stage_attributes.items())), priority, parameter, stage_index)
    if key not in library["attributes"]:
        library["attributes"][key] = resting_attribute(
            library["lines"],
            library["index"],
            handler,
            stage_default,
            stage_attributes,
            priority,
            library["tile_slots"],
            parameter,
            stage_index,
        )
    return library["attributes"][key]


def placement_sprite(studio, library, placement, background=None):
    """One placement drawn as its resting frame, or None where it has none."""
    from authoring.object_sprite_model import (
        WEAPON_SELECTION_ART_END,
        WEAPON_SELECTION_ART_START,
        WEAPON_SELECTION_HANDLER,
        compose_static,
        weapon_selection_carried_art,
    )

    _, mapping = resting_mapping(library, placement.handler, placement.entry.parameter, studio.index)
    attribute, _ = object_attribute(
        library,
        placement.handler,
        studio.scene.object_attribute,
        stage_attributes=studio.scene.object_attributes,
        priority=studio.scene.configuration.sprite_priority,
        parameter=placement.entry.parameter,
        stage_index=studio.index,
    )
    if mapping is None or attribute is None:
        return None
    vram = studio.scene.vram
    if placement.handler == WEAPON_SELECTION_HANDLER:
        carried = weapon_selection_carried_art(studio.root, studio.index)
        if carried is None or len(vram) != WEAPON_SELECTION_ART_END:
            return None
        vram = vram[:WEAPON_SELECTION_ART_START] + carried
    image, left, top = compose_static(mapping, vram, studio.scene.palette, attribute, background)
    return image, placement.map_x + left, placement.map_y + top


def overlay_placements(studio, image, x, y, library=None):
    """Draw every placement that has a sprite onto an already drawn background.

    The ones without are left to the caller's marker. A handler is only drawn
    when both halves resolve: the mapping it rests on, and its own tile
    attribute. Drawing a mapping through somebody else's base gives the right
    shape in the wrong enemy's art, which is a more convincing kind of wrong
    than a marker.
    """
    library = library if library is not None else sprite_library(studio.root)
    height, width = len(image), len(image[0]) if image else 0
    drawn = []
    for placement in studio.placements:
        sprite = placement_sprite(studio, library, placement)
        if sprite is None:
            continue
        pixels, left, top = sprite
        drawn.append(placement.index)
        for row, line in enumerate(pixels):
            at_y = top + row - y
            if not 0 <= at_y < height:
                continue
            for column, pixel in enumerate(line):
                at_x = left + column - x
                if pixel is not None and 0 <= at_x < width:
                    image[at_y][at_x] = pixel
    return drawn
