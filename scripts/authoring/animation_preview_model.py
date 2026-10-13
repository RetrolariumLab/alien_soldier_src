"""Source-qualified timed mapping playback, not native animation fidelity.

A tick is one call to Anim_ResolveTimedMappingFrame, not an assumed emulator
frame. The public object-list caller selects this six-byte mapping path only
when its flag byte has bits 6 and 5 set. Dynamic/player and byte-offset readers
are different consumers and are not silently interpreted by this model.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
from pathlib import Path
import re
from types import MappingProxyType
from typing import Mapping

from authoring import animation_studio_model as workspace
from authoring.sprite_mapping_model import SpritePiece, labelled_blocks, read_one_block


SOURCE = "src/rendering/sprite_object_pipeline.s"
MAX_STEPS = 4096
MAX_SCRIPTS = 4096
MAX_ENTRIES = 65536
MAX_PIECES = 512
SYMBOL = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
# All 43 comment-free operations of the Source 1.0 object-list caller. This
# excludes extra writers/branches between the reviewed selection fragments.
CALLER_OPERATIONS_SHA256 = "98dc2043a113aa322dec51895ec56e97aca864b729e22f575da81b34c6e6297f"
NORMAL_CALLER = (
    "move.b 2(a5),d7", "bpl.s Sprite_RenderObjectList_HandleAlternateFlags",
    "add.b d7,d7", "bpl.w Sprite_RenderSingleObjectEntry",
    "movea.l 8(a5),a4", "add.b d7,d7",
    "bpl.s Sprite_RenderObjectList_RenderMapping", "bsr.w Anim_ResolveTimedMappingFrame",
)
ALTERNATE_CALLER = (
    "beq.s Sprite_RenderObjectList_NextObject", "add.b d7,d7",
    "bpl.s Sprite_RenderObjectList_NextObject", "add.b d7,d7",
    "bpl.s Sprite_RenderObjectList_NextObject", "movea.l 8(a5),a4",
    "pea Sprite_RenderObjectList_NextObject(pc)", "bra.w Anim_ResolveTimedMappingFrame",
)


class UnsupportedPlayback(ValueError):
    """The chosen state crosses a consumer boundary this model cannot prove."""


def _unsigned(value, bits: int, description: str) -> None:
    if type(value) is not int or not 0 <= value < (1 << bits):
        raise ValueError(description + " must be a typed unsigned %d-bit value" % bits)


def _operations(text: str, start: str, end: str) -> tuple[str, ...]:
    starts = list(re.finditer(r"^" + re.escape(start) + r":", text, re.MULTILINE))
    if len(starts) != 1 or text.count(end) != 1:
        raise ValueError("animation preview source boundary is missing or ambiguous: " + start)
    body = text[starts[0].end():].split(end, 1)[0]
    return tuple(code for line in body.splitlines()
                 if (code := " ".join(line.split(";", 1)[0].split())))


def prove_reader(root: Path) -> dict:
    """Bind exact 68000 operations and the two eligible object-list routes."""
    from authoring.content_workspace import checked_path

    path = checked_path(root, SOURCE)
    if path.stat().st_size > 1024 * 1024:
        raise ValueError("animation preview source reader is oversized")
    payload = path.read_bytes()
    text = payload.decode("utf-8")
    reader = _operations(text, "Anim_ResolveTimedMappingFrame",
                         "; End of function Anim_ResolveTimedMappingFrame")
    if reader != workspace.TIMED_READER_OPERATIONS:
        raise ValueError("animation preview timed reader operations changed")
    caller = _operations(text, "Sprite_RenderObjectList",
                         "; End of function Sprite_RenderObjectList")
    caller_hash = hashlib.sha256("\n".join(caller).encode("ascii")).hexdigest()
    if caller_hash != CALLER_OPERATIONS_SHA256:
        raise ValueError("animation preview complete caller operations changed")
    clock = ("move.b (FrameControlFlags).w,d3", "ror.l #8,d3")
    for required in (clock, NORMAL_CALLER):
        if not any(caller[index:index + len(required)] == required
                   for index in range(len(caller) - len(required) + 1)):
            raise ValueError("animation preview caller selection/pause operations changed")
    alternate = caller.index("Sprite_RenderObjectList_HandleAlternateFlags:") + 1
    if caller[alternate:] != ALTERNATE_CALLER:
        raise ValueError("animation preview advance-only caller operations changed")
    return {"source": SOURCE, "source_sha256": hashlib.sha256(payload).hexdigest(),
            "caller_operations_sha256": caller_hash,
            "reader": "Anim_ResolveTimedMappingFrame", "source_reader_verified": True,
            "source_caller_verified": True, "compiled_reader_verified": False,
            "native_run": False, "runtime_fidelity_verified": False,
            "tick_unit": "one_qualified_reader_invocation_not_an_assumed_native_frame"}


@dataclass(frozen=True)
class Cursor:
    script: str
    index: int = 0


@dataclass(frozen=True)
class PlaybackState:
    cursor: Cursor
    timer: int = 0


@dataclass(frozen=True)
class CallerState:
    object_flags: int
    frame_control_flags: int = 0
    consumer_path: str = "static-object-list-timed-reader"

    def validate(self) -> None:
        _unsigned(self.object_flags, 8, "object flag byte")
        _unsigned(self.frame_control_flags, 8, "FrameControlFlags")
        if self.consumer_path != "static-object-list-timed-reader":
            raise UnsupportedPlayback("caller belongs to an unsupported animation reader/producer path")
        if self.object_flags & 0x60 != 0x60:
            raise UnsupportedPlayback("object flags do not select the source-proved timed object-list reader")

    @property
    def render_route_selected(self) -> bool:
        """Selects the mapping renderer; clipping/OAM delivery are not proved."""
        return bool(self.object_flags & 0x80)

    @property
    def paused(self) -> bool:
        return bool(self.frame_control_flags & 0x80)


@dataclass(frozen=True)
class Entry:
    target: str
    duration: int

    @property
    def jump(self) -> bool:
        return self.duration == 0


@dataclass(frozen=True)
class FrameGeometry:
    symbol: str
    pieces: tuple[SpritePiece, ...]
    source_path: str = ""

    @property
    def dynamic(self) -> bool:
        return self.pieces[0].dynamic

    @property
    def bounds(self) -> tuple[int, int, int, int]:
        left = min(piece.x for piece in self.pieces)
        top = min(piece.y for piece in self.pieces)
        return (left, top, max(piece.x + piece.width for piece in self.pieces) - left,
                max(piece.y + piece.height for piece in self.pieces) - top)

    def document(self) -> dict:
        return {"symbol": self.symbol, "source_path": self.source_path,
                "bounds": list(self.bounds), "piece_format": "dynamic-eight-byte" if self.dynamic else "static-six-byte",
                "pieces": [{"attributes": piece.attributes, "size": piece.size, "link": piece.link,
                            "x": piece.x, "y": piece.y, "width": piece.width, "height": piece.height,
                            "tile_offset": piece.tile, "art": piece.art, "art_addend": piece.art_addend}
                           for piece in self.pieces],
                "scope": "source_relative_piece_geometry_not_OAM_art_palette_or_pixels"}


@dataclass(frozen=True)
class Catalog:
    scripts: Mapping[str, tuple[Entry, ...]]
    mappings: Mapping[str, FrameGeometry]
    proof: Mapping

    def __post_init__(self):
        # Copy before validating: later caller mutation cannot alter playback.
        scripts = {name: tuple(entries) for name, entries in self.scripts.items()}
        mappings = dict(self.mappings)
        if not scripts or len(scripts) > MAX_SCRIPTS or sum(map(len, scripts.values())) > MAX_ENTRIES:
            raise ValueError("animation preview script inventory is absent or outside bounds")
        for name, entries in scripts.items():
            if not isinstance(name, str) or not SYMBOL.fullmatch(name) or not entries:
                raise ValueError("animation preview script has no valid name/entries")
            for entry in entries:
                if not isinstance(entry, Entry) or not isinstance(entry.target, str) or not SYMBOL.fullmatch(entry.target):
                    raise ValueError("animation preview entry target is malformed")
                _unsigned(entry.duration, 16, "animation entry duration")
        for entries in scripts.values():
            for entry in entries:
                if entry.jump:
                    if entry.target not in scripts:
                        raise ValueError("animation preview jump destination is missing: " + entry.target)
                    if scripts[entry.target][0].jump:
                        raise UnsupportedPlayback("zero-duration jump chain/cycle is not a proved mapping destination")
                elif entry.target not in mappings:
                    raise ValueError("animation preview mapping is missing: " + entry.target)
        for name, geometry in mappings.items():
            if (not isinstance(geometry, FrameGeometry) or geometry.symbol != name
                    or not geometry.pieces or len(geometry.pieces) > MAX_PIECES):
                raise ValueError("animation preview mapping geometry is absent or outside bounds")
            for index, piece in enumerate(geometry.pieces):
                if not isinstance(piece, SpritePiece):
                    raise ValueError("animation preview piece is not source mapping data")
                for value, bits in ((piece.attributes, 16), (piece.size, 8), (piece.link, 8)):
                    _unsigned(value, bits, "animation mapping piece field")
                if (type(piece.x) is not int or type(piece.y) is not int
                        or not -128 <= piece.x <= 127 or not -128 <= piece.y <= 127
                        or piece.dynamic != geometry.dynamic
                        or piece.last != (index == len(geometry.pieces) - 1)):
                    raise ValueError("animation preview piece position/terminator is malformed")
        object.__setattr__(self, "scripts", MappingProxyType(scripts))
        object.__setattr__(self, "mappings", MappingProxyType(mappings))
        object.__setattr__(self, "proof", MappingProxyType(dict(self.proof)))

    def entry(self, cursor: Cursor) -> Entry:
        if (not isinstance(cursor, Cursor) or not isinstance(cursor.script, str)
                or cursor.script not in self.scripts
                or type(cursor.index) is not int or not 0 <= cursor.index < len(self.scripts[cursor.script])):
            raise UnsupportedPlayback("cursor has no source-owned animation entry")
        return self.scripts[cursor.script][cursor.index]


def _mapping_overlay(root: Path, profile: str, document: dict,
                     mappings: dict[str, FrameGeometry]) -> int:
    """Overlay a complete validated editor document, not a partial frame patch."""
    from authoring import mapping_studio_model

    if not isinstance(document, dict) or not isinstance(document.get("blocks"), list):
        raise ValueError("animation preview mapping document must contain source-owned blocks")
    # The fixed-format validator compares some metadata using equality. Refuse
    # bool/int aliases and unhashable inventories before invoking that validator.
    for field in ("schema_version", "block_count", "mapping_count", "piece_count",
                  "static_mapping_count", "dynamic_mapping_count", "payload_block_count", "excluded_count"):
        _unsigned(document.get(field), 32, "mapping metadata " + field)
    for block in document["blocks"]:
        if (not isinstance(block, dict) or not isinstance(block.get("name"), str)
                or not isinstance(block.get("mappings"), list)):
            raise ValueError("animation preview mapping block inventory is malformed")
        for field in ("mapping_count", "piece_count"):
            _unsigned(block.get(field), 32, "mapping block " + field)
        for mapping in block["mappings"]:
            if not isinstance(mapping, dict) or not isinstance(mapping.get("pieces"), list):
                raise ValueError("animation preview mapping record is malformed")
            for field in ("offset", "piece_count"):
                _unsigned(mapping.get(field), 32, "mapping record " + field)
            if type(mapping.get("dynamic")) is not bool:
                raise ValueError("mapping dynamic metadata must be a typed boolean")
            for piece in mapping["pieces"]:
                if not isinstance(piece, dict) or not isinstance(piece.get("art"), str):
                    raise ValueError("animation preview mapping piece is malformed")
                _unsigned(piece.get("index"), 32, "mapping piece index")
                _unsigned(piece.get("art_addend"), 24, "mapping art addend")
    mapping_studio_model.validate_document(document, root, profile)
    applied = 0
    for block in document["blocks"]:
        name = block["name"]
        if name not in mappings:
            continue
        first = next((item for item in block["mappings"] if item["offset"] == 0), None)
        original = mappings[name]
        if (first is None or block["source_path"] != original.source_path
                or first["dynamic"] != original.dynamic
                or first["piece_count"] != len(original.pieces)):
            raise ValueError("animation preview overlay does not own the exact first mapping: " + name)
        pieces = tuple(SpritePiece(piece["attributes"], piece["size"], piece["link"],
                                   piece["y"], piece["x"], piece["art"], piece["art_addend"])
                       for piece in first["pieces"])
        mappings[name] = FrameGeometry(name, pieces, original.source_path)
        applied += 1
    return applied


def build_catalog(root: Path, profile: str, document: dict | None = None, *,
                  mapping_document: dict | None = None) -> Catalog:
    """Read all exact frame targets, including names without SpriteMapping.

    This authenticates source operation/format evidence only. Retarget edits
    also pass the workspace's cartridge-backed pointer-domain validator. The
    A complete unsaved mapping document may supply edited first-frame pieces;
    exact targets outside that editor's inventory retain their source geometry.
    The result deliberately does not certify compiled or native timing fidelity.
    """
    document = workspace.export_document(root, profile) if document is None else document
    workspace.validate_document(document, root, profile)
    proof = prove_reader(root)
    proof["profile"] = profile
    scripts = {record["name"]: tuple(Entry(frame["target"], frame["duration"]) for frame in record["frames"])
               for record in document["scripts"]}
    targets = {entry.target for entries in scripts.values() for entry in entries if not entry.jump}
    mappings = {}
    for name, source, tokens in labelled_blocks(root):
        if name not in targets:
            continue
        if name in mappings:
            raise ValueError("animation preview mapping has duplicate source owners: " + name)
        blocks, skipped = [], {}
        read_one_block(root, blocks, name, source, tokens, {kind for kind, _token in tokens}, skipped)
        if len(blocks) != 1 or not blocks[0].mappings or blocks[0].mappings[0].offset != 0:
            raise ValueError("animation preview target has no proved first mapping: " + name)
        mappings[name] = FrameGeometry(name, tuple(blocks[0].mappings[0].pieces), source)
    proof["unsaved_mapping_document_supplied"] = mapping_document is not None
    proof["mapping_editor_targets_applied"] = (
        _mapping_overlay(root, profile, mapping_document, mappings) if mapping_document is not None else 0)
    return Catalog(scripts, mappings, proof)


@dataclass(frozen=True)
class Step:
    before: PlaybackState
    after: PlaybackState
    geometry: FrameGeometry
    event: str
    render_route_selected: bool
    timer_written: bool
    cursor_written: bool
    jump_entry: Cursor | None = None

    def document(self) -> dict:
        def state(value):
            return {"script": value.cursor.script, "index": value.cursor.index, "timer": value.timer}
        return {"before": state(self.before), "after": state(self.after), "event": self.event,
                "mapping_render_route_selected": self.render_route_selected, "timer_written": self.timer_written,
                "cursor_written": self.cursor_written,
                "jump_entry": None if self.jump_entry is None else {
                    "script": self.jump_entry.script, "index": self.jump_entry.index},
                "mapping": self.geometry.document(), "native_run": False,
                "runtime_fidelity_verified": False}


def _playback_inputs(catalog: Catalog, state: PlaybackState, caller: CallerState) -> Entry:
    if not isinstance(catalog, Catalog) or not isinstance(state, PlaybackState) or not isinstance(caller, CallerState):
        raise ValueError("animation playback needs typed catalog/state/caller inputs")
    caller.validate()
    _unsigned(state.timer, 16, "object animation timer")
    current = catalog.entry(state.cursor)
    if current.jump:
        raise UnsupportedPlayback("caller cursor starts on a jump rather than a mapping entry")
    return current


def step(catalog: Catalog, state: PlaybackState, caller: CallerState) -> Step:
    """Replay branch/CCR effects of one qualified 68000 reader invocation."""
    current = _playback_inputs(catalog, state, caller)
    cursor, timer = state.cursor, state.timer
    timer_written, cursor_written, jump_entry = True, False, None
    low = timer & 0xFF
    if low & 0x80:
        event, timer_written = "hold-negative-low-byte", False
    elif low == 0:
        timer, event, cursor_written = current.duration, "load-current-entry-timer", True
    elif caller.paused:
        # TST.L d3 is negative/nonzero, so BNE at TickTimer holds the word.
        event = "paused-countdown"
    else:
        timer = (timer - 1) & 0xFFFF
        event = "countdown"
        if timer == 0:
            advanced = Cursor(cursor.script, cursor.index + 1)
            if advanced.index == len(catalog.scripts[advanced.script]):
                raise UnsupportedPlayback("animation reached unproved script fall-through; no implicit stop")
            following = catalog.entry(advanced)
            cursor, timer, cursor_written = advanced, following.duration, True
            event = "next-timed-entry"
            if following.jump:
                jump_entry = advanced
                cursor = Cursor(following.target)
                destination = catalog.entry(cursor)
                if destination.jump:
                    raise UnsupportedPlayback("zero-duration jump chain/cycle is not resolved recursively")
                timer, event = destination.duration, "one-relative-jump"
    resolved = catalog.entry(cursor)
    geometry = catalog.mappings[resolved.target]
    if geometry.dynamic:
        raise UnsupportedPlayback("qualified static timed caller cannot consume an eight-byte dynamic mapping")
    return Step(state, PlaybackState(cursor, timer), geometry, event, caller.render_route_selected,
                timer_written, cursor_written, jump_entry)


def simulate(catalog: Catalog, initial: PlaybackState, caller: CallerState, steps: int) -> tuple[Step, ...]:
    """Bounded immutable trajectory; changing caller flags uses step directly."""
    if type(steps) is not int or not 0 <= steps <= MAX_STEPS:
        raise ValueError("animation preview invocation count is outside 0..%d" % MAX_STEPS)
    _playback_inputs(catalog, initial, caller)
    output = []
    state = initial
    for _index in range(steps):
        observed = step(catalog, state, caller)
        output.append(observed)
        state = observed.after
    return tuple(output)
