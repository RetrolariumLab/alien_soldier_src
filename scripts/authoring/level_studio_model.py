#!/usr/bin/env python3
"""Decode, validate, and stage Alien Soldier object placements."""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))


from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation  # noqa: E402


SPAWN_ENTRY_BYTES = 12
TERMINATOR = 0x7FFF
SPAWN_SOURCE = Path("src/gameplay/object_spawner.s")
HANDLER_SOURCE = Path("src/gameplay/object_dispatch_table.s")
FIELD_ORDER = (
    "x",
    "y",
    "object_type",
    "parameter",
    "slot_first",
    "slot_limit",
)
LIST_HEAD = re.compile(
    r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*ObjectSpawnList):\s+"
    r"(?P<kind>dc\.w|binclude)\s+(?P<body>[^;]+?)\s*(?P<comment>;.*)?$"
)
CONTINUATION = re.compile(r"^\s+dc\.w\s+(?P<body>[^;]+?)\s*(?P<comment>;.*)?$")
LABEL = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*:")
HANDLER_ENTRY = re.compile(r"dc\.l\s+([A-Za-z_][A-Za-z0-9_]*)")
CONTINUATION_PREFIX = "                dc.w    "
CONFIG_SOURCE = Path("src/stages/configuration_records.s")
INITIALIZER_SOURCE = Path("src/stages/configuration.s")
CONFIG_RECORD_BYTES = 30
CONFIG_FIELDS = (
    ("state_offset", "w"),
    ("spawn_list", "l"),
    ("spawn_director", "w"),
    ("palette_primary", "b"),
    ("palette_secondary", "b"),
    ("sprite_priority", "w"),
    ("camera_x", "w"),
    ("camera_y", "w"),
    ("secondary_camera_x", "w"),
    ("secondary_camera_y", "w"),
    ("plane_a_mode", "w"),
    ("plane_b_mode", "w"),
    ("player_x", "b"),
    ("player_y", "b"),
    ("palette_list", "l"),
)
CONFIG_HEAD = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*ConfigRecord):")
DIRECTIVE_VALUE = re.compile(
    r"^(?P<prefix>.*?\bdc\.(?P<size>[bwl])\s+)"
    r"(?P<value>[^,;\s]+)(?P<suffix>.*)$"
)
INITIALIZER_TABLE = "Stage_InitializerOffsets"
INITIALIZER_ANCHOR = "Weapon_ClearAmmoRegenTimers"
INITIALIZER_ENTRY = re.compile(r"^\s*dc\.w\s+([A-Za-z_][A-Za-z0-9_]*)-" + INITIALIZER_ANCHOR + r"\s*(?:;.*)?$")
CONFIG_LEA = re.compile(
    r"^\s+lea\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*ConfigRecord)"
    r"\(pc\),a0\s*(?:;.*)?$"
)
SIZE_LIMIT = {"b": 0xFF, "w": 0xFFFF, "l": 0xFFFFFFFF}
PLAYER_POSITION_BIAS = 0x80
SPAWN_DIRECTOR_SOURCE = Path("src/enemies/spawn_and_movement.s")
SPAWN_DIRECTOR_TABLE = "EnemySpawn_DirectorHandlers"
SPAWN_DIRECTOR_ANCHOR = "EnemySpawn_ResetDirectorState"
PALETTE_EFFECT_SOURCE = Path("src/rendering/palette_effects.s")


@dataclass
class SpawnEntry:
    """One twelve-byte object placement consumed by Sys_ProcessSpawnList."""

    x: int
    y: int
    object_type: int
    parameter: int
    slot_first: int
    slot_limit: int

    @property
    def easy_only(self) -> bool:
        return bool(self.object_type & 2)

    @property
    def hard_only(self) -> bool:
        return bool(self.object_type & 1)

    def words(self) -> list[int]:
        return [getattr(self, field) for field in FIELD_ORDER]

    @classmethod
    def from_words(cls, words: list[int]) -> "SpawnEntry":
        return cls(*words)


@dataclass
class SpawnList:
    """A named placement stream and its source-owned storage form."""

    name: str
    storage: str
    payload: str | None
    entries: list[SpawnEntry]
    terminated: bool

    def to_document(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "storage": self.storage,
            "payload": self.payload,
            "terminated": self.terminated,
            "entries": [asdict(entry) for entry in self.entries],
        }


@dataclass
class StageConfiguration:
    """One parsed thirty-byte record with field-style access for renderers."""

    name: str
    fields: dict[str, int | str]

    def __getattr__(self, field: str) -> int | str:
        try:
            return self.fields[field]
        except KeyError:
            raise AttributeError(field) from None

    @property
    def player_start(self) -> tuple[int, int]:
        return (
            int(self.fields["player_x"]) + PLAYER_POSITION_BIAS,
            int(self.fields["player_y"]) + PLAYER_POSITION_BIAS,
        )


def parse_word(token: str) -> int:
    token = token.strip()
    return int(token[1:], 16) if token.startswith("$") else int(token)


def format_word(value: int) -> str:
    return f"${value:X}" if value > 9 else str(value)


def group_entries(words: list[int], name: str) -> tuple[list[SpawnEntry], bool]:
    terminated = bool(words) and len(words) % 6 == 1 and words[-1] == TERMINATOR
    if terminated:
        words = words[:-1]
    if len(words) % 6:
        raise ValueError(f"{name}: {len(words)} words is not a whole number of entries")
    return (
        [SpawnEntry.from_words(words[index : index + 6]) for index in range(0, len(words), 6)],
        terminated,
    )


def decode_payload(data: bytes) -> tuple[list[SpawnEntry], bool]:
    terminated = len(data) % SPAWN_ENTRY_BYTES == 2 and struct.unpack_from(">H", data, len(data) - 2)[0] == TERMINATOR
    if terminated:
        data = data[:-2]
    if len(data) % SPAWN_ENTRY_BYTES:
        raise ValueError(f"payload of {len(data)} bytes is not a whole number of entries")
    return (
        [
            SpawnEntry.from_words(list(struct.unpack_from(">6H", data, index)))
            for index in range(0, len(data), SPAWN_ENTRY_BYTES)
        ],
        terminated,
    )


def encode_payload(entries: list[SpawnEntry], terminated: bool) -> bytes:
    body = b"".join(struct.pack(">6H", *entry.words()) for entry in entries)
    return body + (struct.pack(">H", TERMINATOR) if terminated else b"")


def read_source_lists(root: Path) -> tuple[list[SpawnList], dict[str, tuple[int, int]]]:
    """Read every source and binincluded placement stream in ROM order."""
    lines = (root / SPAWN_SOURCE).read_text(encoding="utf-8").split("\n")
    lists: list[SpawnList] = []
    spans: dict[str, tuple[int, int]] = {}
    index = 0
    while index < len(lines):
        head = LIST_HEAD.match(lines[index])
        if head is None:
            index += 1
            continue
        name = head.group("name")
        if head.group("kind") == "binclude":
            payload = head.group("body").strip().strip('"')
            entries, terminated = decode_payload((root / payload).read_bytes())
            lists.append(SpawnList(name, "payload", payload, entries, terminated))
            index += 1
            continue
        words = [parse_word(token) for token in head.group("body").split(",")]
        start = index
        index += 1
        while index < len(lines):
            if LABEL.match(lines[index]):
                break
            more = CONTINUATION.match(lines[index])
            if more is not None:
                words.extend(parse_word(token) for token in more.group("body").split(","))
                index += 1
                continue
            if not lines[index].strip() or lines[index].strip().startswith(";"):
                index += 1
                continue
            break
        spans[name] = (start, index)
        entries, terminated = group_entries(words, name)
        lists.append(SpawnList(name, "source", None, entries, terminated))
    return lists, spans


def handler_names(root: Path) -> dict[int, str]:
    """Map the byte offset stored as object type to its dispatch routine."""
    names = HANDLER_ENTRY.findall((root / HANDLER_SOURCE).read_text(encoding="utf-8"))
    return {index * 4: name for index, name in enumerate(names)}


def parse_config_value(token: str) -> int | str:
    if token.startswith("$") or token[0].isdigit():
        return parse_word(token)
    return token


def read_configurations(
    root: Path,
) -> tuple[list[dict[str, Any]], dict[str, list[tuple[int, re.Match[str]]]]]:
    """Read every fixed-width stage record and remember each value token."""
    lines = (root / CONFIG_SOURCE).read_text(encoding="utf-8").split("\n")
    configurations = []
    spans: dict[str, list[tuple[int, re.Match[str]]]] = {}
    index = 0
    while index < len(lines):
        head = CONFIG_HEAD.match(lines[index])
        if head is None:
            index += 1
            continue
        name = head.group("name")
        values: dict[str, int | str] = {}
        locations: list[tuple[int, re.Match[str]]] = []
        scan = index
        for field, expected_size in CONFIG_FIELDS:
            while scan < len(lines):
                if scan != index and CONFIG_HEAD.match(lines[scan]):
                    break
                directive = DIRECTIVE_VALUE.match(lines[scan])
                scan += 1
                if directive is None:
                    continue
                if directive.group("size") != expected_size:
                    raise ValueError(f"{name}: {field} uses dc.{directive.group('size')}, expected dc.{expected_size}")
                values[field] = parse_config_value(directive.group("value"))
                locations.append((scan - 1, directive))
                break
            else:
                break
            if field not in values:
                break
        if len(values) != len(CONFIG_FIELDS):
            raise ValueError(f"{name}: incomplete {CONFIG_RECORD_BYTES}-byte record")
        configurations.append({"name": name, "fields": values})
        spans[name] = locations
        index = scan
    return configurations, spans


def read_configuration_records(root: Path) -> dict[str, StageConfiguration]:
    """Compatibility view keyed by record name for renderers and tests."""
    return {item["name"]: StageConfiguration(item["name"], item["fields"]) for item in read_configurations(root)[0]}


def stage_slots(root: Path) -> list[dict[str, Any]]:
    """Resolve each StageTableIndex slot to the configuration it applies."""
    lines = (root / INITIALIZER_SOURCE).read_text(encoding="utf-8").split("\n")
    routines: list[str] = []
    for index, line in enumerate(lines):
        if not line.startswith(INITIALIZER_TABLE + ":"):
            continue
        for follow in lines[index:]:
            match = INITIALIZER_ENTRY.match(follow.replace(INITIALIZER_TABLE + ":", " " * 8))
            if match is not None:
                routines.append(match.group(1))
            elif follow.strip() and not follow.strip().startswith(";") and routines:
                break
        break
    bodies: dict[str, list[str]] = {}
    routine = None
    for line in lines:
        head = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", line)
        if head is not None:
            routine = head.group(1)
            bodies[routine] = []
        elif routine is not None:
            bodies[routine].append(line)
    slots = []
    for index, routine in enumerate(routines):
        configuration = ""
        for line in bodies.get(routine, []):
            match = CONFIG_LEA.match(line)
            if match is not None:
                configuration = match.group("name")
                break
        slots.append({"index": index, "initializer": routine, "configuration": configuration})
    return slots


def stage_initializers(root: Path) -> list[str]:
    """Compatibility view: configuration name selected by each stage slot."""
    return [slot["configuration"] for slot in stage_slots(root)]


def stage_configurations(root: Path) -> list[StageConfiguration | None]:
    """Configuration object selected by each stage slot in table order."""
    records = read_configuration_records(root)
    return [records.get(name) for name in stage_initializers(root)]


def editable_stage_slot_locations(
    root: Path,
) -> dict[int, tuple[int, re.Match[str]]]:
    """Find only three-instruction wrappers with no stage-specific side effects.

    Their LEA operand can select another source-owned configuration record
    without changing the initializer selected by Stage_InitializerOffsets.
    Any wrapper with additional instructions remains fixed.
    """
    lines = (root / INITIALIZER_SOURCE).read_text(encoding="utf-8").split("\n")
    labels = {
        match.group(1): index
        for index, line in enumerate(lines)
        if (match := re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", line))
    }
    locations = {}
    for slot in stage_slots(root):
        start = labels.get(slot["initializer"])
        if start is None:
            continue
        instructions = []
        for index in range(start + 1, len(lines)):
            if LABEL.match(lines[index]):
                break
            code = lines[index].split(";", 1)[0].strip()
            if code:
                instructions.append((index, code))
        if len(instructions) != 3:
            continue
        first = CONFIG_LEA.match(lines[instructions[0][0]])
        if (
            first is not None
            and instructions[1][1] == "nop"
            and re.fullmatch(r"bra\.w\s+Stage_ApplyConfigurationRecord", instructions[2][1])
        ):
            locations[slot["index"]] = (instructions[0][0], first)
    return locations


def export_document(root: Path, profile: str) -> dict[str, Any]:
    lists, _ = read_source_lists(root)
    handlers = handler_names(root)
    configurations, _ = read_configurations(root)
    document: dict[str, Any] = {
        "schema_version": 1,
        "profile": profile,
        "entry_bytes": SPAWN_ENTRY_BYTES,
        "field_order": list(FIELD_ORDER),
        "object_handlers": {f"0x{key:03X}": value for key, value in sorted(handlers.items())},
        "slot_boundaries": sorted(
            {value for item in lists for entry in item.entries for value in (entry.slot_first, entry.slot_limit)}
        ),
        "configuration_record_bytes": CONFIG_RECORD_BYTES,
        "configuration_fields": [{"name": name, "size": size} for name, size in CONFIG_FIELDS],
        "stage_slots": stage_slots(root),
        "configurations": configurations,
        "spawn_lists": [item.to_document() for item in lists],
    }
    for entry in (entry for item in document["spawn_lists"] for entry in item["entries"]):
        entry["handler"] = handlers.get(entry["object_type"] & ~3, "")
    return document


def configuration_index_domains(root: Path) -> dict[str, frozenset[int]]:
    """Derive the legal byte offsets from the actual configuration readers.

    Plane mode zero bypasses its longword table. Normal primary-plane entry
    masks bit 15 before looking up a negative mode; secondary entry does not.
    The separate Xi-Tiger record is not in this writable record inventory.
    EnemySpawn_UpdateDirector and the two palette-effect dispatchers index
    relative word tables directly. Palette bytes are offsets, not color IDs.
    """
    from authoring.stage_tilemap_model import (
        PLANE_A_TABLE,
        PLANE_B_TABLE,
        read_plane_tables,
    )

    tables = read_plane_tables(root)
    domains = {}
    for field, table in (("plane_a_mode", PLANE_A_TABLE), ("plane_b_mode", PLANE_B_TABLE)):
        entries = tables.get(table)
        if not entries:
            raise ValueError("configuration reader table is missing: " + table)
        offsets = {4 * (index + 1) for index in range(len(entries))}
        if field == "plane_a_mode":
            offsets |= {0x8000 | offset for offset in offsets}
        domains[field] = frozenset({0, *offsets})

    entry = re.compile(r"^\s*dc\.w\s+[A-Za-z_][A-Za-z0-9_]*-" + re.escape(SPAWN_DIRECTOR_ANCHOR) + r"\s*$")
    active = False
    count = 0
    for line in (root / SPAWN_DIRECTOR_SOURCE).read_text(encoding="utf-8").splitlines():
        code = line.split(";", 1)[0]
        if code.startswith(SPAWN_DIRECTOR_TABLE + ":"):
            active = True
            code = code.split(":", 1)[1]
        elif active and LABEL.match(code):
            break
        if not active or not code.strip():
            continue
        if not entry.fullmatch(code):
            raise ValueError("configuration reader table has an unsupported entry: " + SPAWN_DIRECTOR_TABLE)
        count += 1
    if not count:
        raise ValueError("configuration reader table is missing: " + SPAWN_DIRECTOR_TABLE)
    domains["spawn_director"] = frozenset(2 * index for index in range(count))
    domains.update(palette_effect_index_domains(root))
    return domains


def palette_effect_index_domains(root: Path) -> dict[str, frozenset[int]]:
    """Prove the byte field writers and exact unmasked word-table readers."""

    def blocks(path):
        found, current = {}, None
        for line in path.read_text(encoding="utf-8").splitlines():
            code = line.split(";", 1)[0].strip()
            match = re.fullmatch(r"(\w+):(.*)", code)
            if match:
                current, code = match.groups()
                if current in found:
                    raise ValueError("duplicate palette configuration source label: " + current)
                found[current] = []
            if current is not None and code.strip():
                found[current].append(re.sub(r"\s+", " ", code.strip()))
        return found

    writer = blocks(root / CONFIG_SOURCE).get("Stage_ApplyConfigurationRecord", ())
    if list(writer[:5]) != [
        "move.w (a0)+,(StageStateOffset).w",
        "move.l (a0)+,(StageObjectSpawnCursor).w",
        "move.w (a0)+,(EnemySpawnDirectorState).w",
        "move.b (a0)+,(PalettePrimaryIndex+1).w",
        "move.b (a0)+,(PaletteSecondaryIndex+1).w",
    ]:
        raise ValueError("stage configuration palette-byte writers changed")
    source = blocks(root / PALETTE_EFFECT_SOURCE)
    found = {}
    for field, slot, reader, table, anchor in (
        (
            "palette_primary",
            "PalettePrimaryIndex",
            "Palette_UpdatePrimaryEffect_Dispatch",
            "Palette_PrimaryEffectOffsets",
            "Palette_UpdateSharedAnimatedColors",
        ),
        (
            "palette_secondary",
            "PaletteSecondaryIndex",
            "Palette_UpdateSecondaryEffect_Dispatch",
            "Palette_SecondaryEffectOffsets",
            "Palette_UpdatePairedEntryLists",
        ),
    ):
        if source.get(reader) != [
            f"move.w ({slot}).w,d0",
            f"movea.w {table}(pc,d0.w),a0",
            f"adda.l #{anchor},a0",
            "jmp (a0)",
        ]:
            raise ValueError("palette-effect indexed reader changed: " + reader)
        entries = source.get(table, ())
        if not entries or any(re.fullmatch(r"dc\.w \w+-" + re.escape(anchor), line) is None for line in entries):
            raise ValueError("palette-effect word-offset table changed: " + table)
        found[field] = frozenset(2 * index for index in range(len(entries)))
    return found


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(f"cannot load level document {path}: {error}") from error
    if not isinstance(document, dict):
        raise ValueError(f"level document is not an object: {path}")
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def _metadata_errors(document: dict[str, Any], baseline: dict[str, Any]) -> list[str]:
    errors = []
    for field in (
        "schema_version",
        "profile",
        "entry_bytes",
        "field_order",
        "object_handlers",
        "slot_boundaries",
        "configuration_record_bytes",
        "configuration_fields",
    ):
        if document.get(field) != baseline[field]:
            errors.append(f"{field} differs from the source-owned value")
    return errors


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    """Return every condition that makes applying a level document unsafe."""
    baseline = export_document(root, profile)
    errors = _metadata_errors(document, baseline)
    index_domains = configuration_index_domains(root)
    from authoring.level_state_domains import state_errors

    errors.extend(state_errors(root, document, baseline))
    slots = document.get("stage_slots")
    original_slots = baseline["stage_slots"]
    editable_slots = editable_stage_slot_locations(root)
    configuration_names = {item["name"] for item in baseline["configurations"]}
    if not isinstance(slots, list) or len(slots) != len(original_slots):
        errors.append("stage-slot inventory differs from the source")
    else:
        for index, (slot, original) in enumerate(zip(slots, original_slots)):
            if not isinstance(slot, dict):
                errors.append(f"stage slot {index} is not an object")
                continue
            if (
                set(slot) != set(original)
                or type(slot.get("index")) is not int
                or slot["index"] != original["index"]
                or slot.get("initializer") != original["initializer"]
            ):
                errors.append(f"stage slot {index} identity differs from the source")
            target = slot.get("configuration")
            if not isinstance(target, str) or target not in configuration_names:
                errors.append(f"stage slot {index} has no known configuration")
            elif index not in editable_slots and target != original["configuration"]:
                errors.append(f"stage slot {index} has a fixed special initializer route")
    configurations = document.get("configurations")
    if not isinstance(configurations, list):
        errors.append("configurations is not a list")
    else:
        originals = {item["name"]: item for item in baseline["configurations"]}
        names = [item.get("name") for item in configurations if isinstance(item, dict)]
        if len(names) != len(configurations) or len(set(names)) != len(names):
            errors.append("configuration names are missing or not unique")
        if set(names) != set(originals):
            errors.append("configuration inventory differs from the source")
        spawn_symbols = {item["name"] for item in baseline["spawn_lists"]}
        palette_symbols = {
            item["fields"]["palette_list"]
            for item in baseline["configurations"]
            if isinstance(item["fields"]["palette_list"], str)
        }
        for configuration in configurations:
            if not isinstance(configuration, dict):
                continue
            name = configuration.get("name", "<missing>")
            original = originals.get(name)
            if original is None:
                continue
            fields = configuration.get("fields")
            if not isinstance(fields, dict) or set(fields) != {field for field, _ in CONFIG_FIELDS}:
                errors.append(f"{name}: configuration fields differ")
                continue
            for field, size in CONFIG_FIELDS:
                value = fields[field]
                if field == "spawn_list" and isinstance(value, str):
                    if value not in spawn_symbols:
                        errors.append(f"{name}: spawn_list is not a known spawn list")
                    continue
                if field == "palette_list" and isinstance(value, str):
                    if value not in palette_symbols:
                        errors.append(f"{name}: palette_list is not a known palette list")
                    continue
                if isinstance(value, bool) or not isinstance(value, int):
                    errors.append(f"{name}: {field} has the wrong value type")
                    continue
                if not 0 <= value <= SIZE_LIMIT[size]:
                    errors.append(f"{name}: {field} does not fit dc.{size}")
                if field in index_domains and value not in index_domains[field]:
                    errors.append(f"{name}: {field} is not a reader-owned aligned table offset")
                if field in {"spawn_list", "palette_list"} and value != original["fields"][field]:
                    errors.append(f"{name}: numeric {field} pointer may only be preserved")
    records = document.get("spawn_lists")
    if not isinstance(records, list):
        return errors + ["spawn_lists is not a list"]
    originals = {item["name"]: item for item in baseline["spawn_lists"]}
    names = [item.get("name") for item in records if isinstance(item, dict)]
    if len(names) != len(records) or len(set(names)) != len(names):
        errors.append("spawn-list names are missing or not unique")
    if set(names) != set(originals):
        errors.append("spawn-list inventory differs from the source")
    handlers = {int(key, 16) for key in baseline["object_handlers"]}
    boundaries = set(baseline["slot_boundaries"])
    for item in records:
        if not isinstance(item, dict):
            continue
        name = item.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in ("storage", "payload", "terminated"):
            if item.get(field) != original[field]:
                errors.append(f"{name}: {field} differs from the source-owned value")
        entries = item.get("entries")
        if not isinstance(entries, list):
            errors.append(f"{name}: entries is not a list")
            continue
        if len(entries) != len(original["entries"]):
            errors.append(f"{name}: entry count differs from fixed capacity")
        for index, entry in enumerate(entries):
            if not isinstance(entry, dict):
                errors.append(f"{name} entry {index}: entry is not an object")
                continue
            for field in FIELD_ORDER:
                value = entry.get(field)
                if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= 0xFFFF:
                    errors.append(f"{name} entry {index}: {field} is not an unsigned word")
            x = entry.get("x")
            if type(x) is int and x >= TERMINATOR:
                errors.append(f"{name} entry {index}: x must precede the $7FFF stop word")
            object_type = entry.get("object_type")
            if isinstance(object_type, int) and object_type & ~3 not in handlers:
                errors.append(f"{name} entry {index}: object_type has no dispatch handler")
            for field in ("slot_first", "slot_limit"):
                value = entry.get(field)
                if isinstance(value, int) and value not in boundaries:
                    errors.append(f"{name} entry {index}: {field} is not an object-pool boundary")
            first, limit = entry.get("slot_first"), entry.get("slot_limit")
            if type(first) is int and type(limit) is int:
                if first >= max(boundaries):
                    errors.append(f"{name} entry {index}: slot_first is beyond the object pool")
                if first > limit:
                    errors.append(f"{name} entry {index}: slot_first exceeds slot_limit")
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def lists_from_document(document: dict[str, Any], root: Path, profile: str) -> list[SpawnList]:
    validate_document(document, root, profile)
    originals = {item.name: item for item in read_source_lists(root)[0]}
    lists = []
    for record in document["spawn_lists"]:
        original = originals[record["name"]]
        entries = [SpawnEntry(*(entry[field] for field in FIELD_ORDER)) for entry in record["entries"]]
        lists.append(
            SpawnList(
                original.name,
                original.storage,
                original.payload,
                entries,
                original.terminated,
            )
        )
    return lists


def flatten(item: SpawnList) -> list[int]:
    words = [word for entry in item.entries for word in entry.words()]
    if item.terminated:
        words.append(TERMINATOR)
    return words


def format_words(words: list[int]) -> str:
    return ", ".join(format_word(word) for word in words)


def rewrite_in_place(block: list[str], words: list[int]) -> list[str]:
    rebuilt = []
    offset = 0
    for line in block:
        match = LIST_HEAD.match(line) or CONTINUATION.match(line)
        if match is None:
            rebuilt.append(line)
            continue
        count = len(match.group("body").split(","))
        body = format_words(words[offset : offset + count])
        offset += count
        rebuilt.append(line[: match.start("body")] + body + line[match.end("body") :])
    return rebuilt


def rebuild_source_text(lists: list[SpawnList], spans: dict[str, tuple[int, int]], lines: list[str]) -> list[str]:
    """Rewrite value tokens without changing comments, whitespace, or length."""
    output = list(lines)
    by_name = {item.name: item for item in lists if item.storage == "source"}
    for name, (start, end) in sorted(spans.items(), key=lambda pair: -pair[1][0]):
        output[start:end] = rewrite_in_place(lines[start:end], flatten(by_name[name]))
    return output


def atomic_write_text(path: Path, text: str) -> None:
    from authoring.atomic_output import atomic_write_text as _write_text

    _write_text(path, text)


def atomic_write_bytes(path: Path, data: bytes) -> None:
    from authoring.atomic_output import atomic_write_bytes as _write_bytes

    _write_bytes(path, data)


def rebuild_configuration_text(document: dict[str, Any], root: Path, lines: list[str]) -> list[str]:
    """Substitute only fixed-width configuration value tokens."""
    _, spans = read_configurations(root)
    output = list(lines)
    by_name = {item["name"]: item["fields"] for item in document["configurations"]}
    for name, locations in spans.items():
        fields = by_name[name]
        for (field, _), (line_index, match) in zip(CONFIG_FIELDS, locations):
            value = fields[field]
            token = value if isinstance(value, str) else format_word(value)
            output[line_index] = (
                lines[line_index][: match.start("value")] + token + lines[line_index][match.end("value") :]
            )
    return output


def rebuild_initializer_text(document: dict[str, Any], root: Path, lines: list[str]) -> list[str]:
    """Replace only the LEA symbol of a proven plain stage wrapper."""
    output = list(lines)
    for index, (line_index, match) in editable_stage_slot_locations(root).items():
        target = document["stage_slots"][index]["configuration"]
        output[line_index] = lines[line_index][: match.start("name")] + target + lines[line_index][match.end("name") :]
    return output


def apply_document(document: dict[str, Any], root: Path, profile: str, write: bool = True) -> list[str]:
    """Apply validated placements to a staged tree and return changed paths."""
    lists = lists_from_document(document, root, profile)
    _, spans = read_source_lists(root)
    source_path = root / SPAWN_SOURCE
    lines = source_path.read_text(encoding="utf-8").split("\n")
    updated = rebuild_source_text(lists, spans, lines)
    changed: list[str] = []
    if updated != lines:
        changed.append(SPAWN_SOURCE.as_posix())
        if write:
            atomic_write_text(source_path, "\n".join(updated))
    for item in lists:
        if item.storage != "payload" or item.payload is None:
            continue
        path = root / item.payload
        body = encode_payload(item.entries, item.terminated)
        if body != path.read_bytes():
            changed.append(item.payload)
            if write:
                atomic_write_bytes(path, body)
    config_path = root / CONFIG_SOURCE
    config_lines = config_path.read_text(encoding="utf-8").split("\n")
    config_updated = rebuild_configuration_text(document, root, config_lines)
    if config_updated != config_lines:
        changed.append(CONFIG_SOURCE.as_posix())
        if write:
            atomic_write_text(config_path, "\n".join(config_updated))
    initializer_path = root / INITIALIZER_SOURCE
    initializer_lines = initializer_path.read_text(encoding="utf-8").split("\n")
    initializer_updated = rebuild_initializer_text(document, root, initializer_lines)
    if initializer_updated != initializer_lines:
        changed.append(INITIALIZER_SOURCE.as_posix())
        if write:
            atomic_write_text(initializer_path, "\n".join(initializer_updated))
    return changed


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    """Prove the exported baseline applies without changing any source byte."""
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    changes = apply_document(document, root, profile, write=False)
    return [f"zero-edit level document would change {path}" for path in changes]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "export", "validate"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", default="jp", choices=("jp", "eu"))
    parser.add_argument("--document")
    parser.add_argument("--output")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        if args.command == "check":
            with parsed_read_phase(root):
                errors = round_trip_errors(root, args.profile)
                if errors:
                    raise ValueError("; ".join(errors))
                document = export_document(root, args.profile)
            count = sum(len(item["entries"]) for item in document["spawn_lists"])
            print(f"[OK] {args.profile} level model: {len(document['spawn_lists'])} spawn lists, {count} placements")
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print(f"[OK] level document exported: {args.output}")
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print(f"[OK] level document is valid: {args.document}")
        return 0
    except (OSError, ValueError) as error:
        print(f"[ERROR] {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
