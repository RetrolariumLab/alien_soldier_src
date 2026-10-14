#!/usr/bin/env python3
"""Round-trip the global pitch and PSG-volume envelope tables."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import rebuild_source  # noqa: E402
from authoring.sound_studio_model import PROFILES  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks, parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
FORMAT = "treasure-smps-global-envelope-tables"
SOURCE_PATH = "src/sound/psg_playback_and_envelopes.s"
POINTER_DIRECTIVE = re.compile(r"\bdc\.l\s+([^;]+)", re.IGNORECASE)
LABEL_LINE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):", re.MULTILINE)
COMMAND_NAMES = {
    0x80: "restart",
    0x81: "repeat_previous",
    0x82: "jump",
    0x83: "end",
    0x84: "add_transpose",
}
FAMILIES = (
    {
        "id": "pitch",
        "pointer_table": "Sound_PitchEnvelopePointerTable",
        "label_prefix": "Sound_PitchEnvelope_",
        "valid_commands": frozenset(range(0x80, 0x85)),
        "reader": "Sound_ApplyPitchEffects",
    },
    {
        "id": "psg_volume",
        "pointer_table": "Sound_PSGVolumeEnvelopePointerTable",
        "label_prefix": "Sound_PSGVolumeEnvelope_",
        "valid_commands": frozenset(range(0x80, 0x84)),
        "reader": "Sound_UpdatePSGVolumeEnvelope",
    },
)


def _signed(value: int) -> int:
    return value - 0x100 if value >= 0x80 else value


def _raw(value: Any, context: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or not -128 <= value <= 127:
        raise ValueError("%s is not a signed byte" % context)
    return value & 0xFF


def _pointer_labels(lines: tuple[str, ...], table: str) -> list[str]:
    labels = []
    for line in lines:
        match = POINTER_DIRECTIVE.search(line)
        if match is None:
            continue
        labels.extend(token.strip() for token in match.group(1).split(","))
    if not labels or any(not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", item) for item in labels):
        raise ValueError("%s is not a symbol-only pointer table" % table)
    if len(labels) != len(set(labels)):
        raise ValueError("%s contains duplicate envelope pointers" % table)
    return labels


def envelope_selector_limits(root: Path) -> dict[str, int]:
    """Read one-based envelope selector limits from the source pointer tables."""
    _stored, bodies = labelled_blocks(root)
    return {
        family["id"]: len(_pointer_labels(
            bodies[family["pointer_table"]], family["pointer_table"]))
        for family in FAMILIES
    }


def _physical_labels(source: str, prefix: str, pointers: list[str]) -> list[str]:
    wanted = set(pointers)
    labels = [
        match.group(1) for match in LABEL_LINE.finditer(source)
        if match.group(1).startswith(prefix)
    ]
    if set(labels) != wanted or len(labels) != len(wanted):
        raise ValueError("%s physical labels differ from its pointer table" % prefix)
    return labels


def _walk(
    region: bytes, entry: int, valid_commands: frozenset[int], family: str,
) -> tuple[set[int], dict[int, dict[str, Any]], set[int]]:
    """Return reachable values, commands, and operands from one table entry."""
    pending = [0]
    visited: set[int] = set()
    values: set[int] = set()
    commands: dict[int, dict[str, Any]] = {}
    operands: set[int] = set()
    while pending:
        cursor = pending.pop()
        absolute = entry + cursor
        if absolute in visited:
            continue
        if not 0 <= absolute < len(region):
            raise ValueError("%s envelope cursor $%02X leaves its table" % (family, cursor))
        visited.add(absolute)
        opcode = region[absolute]
        if opcode not in valid_commands:
            values.add(absolute)
            pending.append(cursor + 1)
            continue
        command: dict[str, Any] = {
            "offset": absolute,
            "opcode": opcode,
            "name": COMMAND_NAMES[opcode],
        }
        if opcode in (0x82, 0x84):
            operand_offset = absolute + 1
            if operand_offset >= len(region):
                raise ValueError("%s envelope command at $%02X is truncated" % (family, cursor))
            operand = region[operand_offset]
            operands.add(operand_offset)
            visited.add(operand_offset)
            command["operand_offset"] = operand_offset
            command["operand"] = operand
        commands[absolute] = command
        if opcode == 0x80:
            pending.append(0)
        elif opcode == 0x81:
            if cursor == 0:
                raise ValueError("%s repeat command has no preceding value" % family)
            pending.append(cursor - 1)
        elif opcode == 0x82:
            command["target"] = entry + command["operand"]
            pending.append(command["operand"])
        elif opcode == 0x84:
            pending.append(cursor + 2)
    return values, commands, operands


def _family_document(
    source: str, stored: dict[str, Any], bodies: dict[str, tuple[str, ...]],
    definition: dict[str, Any],
) -> dict[str, Any]:
    table = definition["pointer_table"]
    pointers = _pointer_labels(bodies[table], table)
    physical = _physical_labels(source, definition["label_prefix"], pointers)
    starts: dict[str, int] = {}
    region = bytearray()
    for label in physical:
        body = stored.get(label)
        if not isinstance(body, bytes) or not body:
            raise ValueError("%s has no byte body" % label)
        starts[label] = len(region)
        region.extend(body)

    roles: dict[int, str] = {}
    commands: dict[int, dict[str, Any]] = {}
    envelopes = []
    for index, label in enumerate(pointers, 1):
        values, selected_commands, operands = _walk(
            bytes(region), starts[label], definition["valid_commands"], definition["id"])
        classifications = [
            (values, "value"),
            (set(selected_commands), "command"),
            (operands, "operand"),
        ]
        for offsets, role in classifications:
            for offset in offsets:
                previous = roles.setdefault(offset, role)
                if previous != role:
                    raise ValueError(
                        "%s byte $%04X is both %s and %s" % (
                            definition["id"], offset, previous, role))
        for offset, command in selected_commands.items():
            existing = commands.setdefault(offset, command)
            if existing != command:
                raise ValueError("%s command has conflicting interpretations" % definition["id"])
        reachable = sorted(values | set(selected_commands) | operands)
        envelopes.append({
            "id": index,
            "entry_label": label,
            "entry_offset": starts[label],
            "reachable_offsets": reachable,
        })

    blocks = []
    for block_index, label in enumerate(physical):
        body = stored[label]
        start = starts[label]
        values = []
        protected = []
        for local, byte in enumerate(body):
            absolute = start + local
            if roles.get(absolute) == "value":
                values.append({"offset": local, "value": _signed(byte)})
            elif roles.get(absolute) is None:
                protected.append({"offset": local, "byte": byte})
        block_commands = []
        for absolute, command in sorted(commands.items()):
            if start <= absolute < start + len(body):
                item = dict(command)
                item["offset"] -= start
                if "operand_offset" in item:
                    item["operand_offset"] -= start
                if "target" in item:
                    item["target"] -= start
                block_commands.append(item)
        blocks.append({
            "physical_index": block_index,
            "name": label,
            "capacity": len(body),
            "values": values,
            "commands": block_commands,
            "protected_bytes": protected,
        })
    return {
        "id": definition["id"],
        "reader": definition["reader"],
        "pointer_table": table,
        "command_opcodes": sorted(definition["valid_commands"]),
        "envelope_count": len(envelopes),
        "capacity": len(region),
        "value_count": sum(len(block["values"]) for block in blocks),
        "command_count": len(commands),
        "protected_byte_count": sum(
            len(block["protected_bytes"]) for block in blocks) + len({
                offset for offset, role in roles.items() if role == "operand"
            }),
        "envelopes": envelopes,
        "blocks": blocks,
    }


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown sound-envelope profile: %s" % profile)
    stored, bodies = labelled_blocks(root)
    source = (root / SOURCE_PATH).read_text(encoding="utf-8")
    families = [_family_document(source, stored, bodies, item) for item in FAMILIES]
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "source_path": SOURCE_PATH,
        "family_count": len(families),
        "envelope_count": sum(item["envelope_count"] for item in families),
        "capacity": sum(item["capacity"] for item in families),
        "value_count": sum(item["value_count"] for item in families),
        "command_count": sum(item["command_count"] for item in families),
        "protected_byte_count": sum(item["protected_byte_count"] for item in families),
        "families": families,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load sound-envelope document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("sound-envelope document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def _block_bytes(
    record: dict[str, Any], original: dict[str, Any], body: bytes,
    command_opcodes: set[int],
) -> bytes:
    for field in (
        "physical_index", "name", "capacity", "commands", "protected_bytes",
    ):
        if record.get(field) != original[field]:
            raise ValueError("%s: %s differs from the source-owned value" % (original["name"], field))
    values = record.get("values")
    expected = original["values"]
    if not isinstance(values, list) or len(values) != len(expected):
        raise ValueError("%s: value inventory differs" % original["name"])
    result = bytearray(body)
    for index, (value, baseline) in enumerate(zip(values, expected)):
        if not isinstance(value, dict) or value.get("offset") != baseline["offset"]:
            raise ValueError("%s: value %d changes identity" % (original["name"], index))
        raw = _raw(value.get("value"), "%s value %d" % (original["name"], index))
        if raw in command_opcodes:
            raise ValueError("%s value %d becomes a control command" % (original["name"], index))
        result[value["offset"]] = raw
    return bytes(result)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "source_path", "family_count",
        "envelope_count", "capacity", "value_count", "command_count",
        "protected_byte_count",
    ):
        if document.get(field) != baseline[field]:
            errors.append("%s differs from the source-owned value" % field)
    families = document.get("families")
    if not isinstance(families, list):
        return errors + ["families is not a list"]
    originals = {item["id"]: item for item in baseline["families"]}
    ids = [item.get("id") for item in families if isinstance(item, dict)]
    if len(ids) != len(families) or len(set(ids)) != len(ids) or set(ids) != set(originals):
        errors.append("family inventory differs from the source")
    stored, _bodies = labelled_blocks(root)
    for family in families:
        if not isinstance(family, dict) or family.get("id") not in originals:
            continue
        original = originals[family["id"]]
        for field in (
            "reader", "pointer_table", "command_opcodes", "envelope_count", "capacity",
            "value_count", "command_count", "protected_byte_count", "envelopes",
        ):
            if family.get(field) != original[field]:
                errors.append("%s: %s differs from the source-owned value" % (original["id"], field))
        blocks = family.get("blocks")
        expected = {item["name"]: item for item in original["blocks"]}
        if not isinstance(blocks, list):
            errors.append("%s: blocks is not a list" % original["id"])
            continue
        names = [item.get("name") for item in blocks if isinstance(item, dict)]
        if len(names) != len(blocks) or len(set(names)) != len(names) or set(names) != set(expected):
            errors.append("%s: block inventory differs from the source" % original["id"])
        for block in blocks:
            if not isinstance(block, dict) or block.get("name") not in expected:
                continue
            try:
                _block_bytes(
                    block, expected[block["name"]], stored[block["name"]],
                    set(original["command_opcodes"]),
                )
            except (KeyError, TypeError, ValueError) as error:
                errors.append(str(error))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    authority = validation_root or root
    validate_document(document, authority, profile)
    baseline = export_document(authority, profile)
    originals = {
        block["name"]: block
        for family in baseline["families"] for block in family["blocks"]
    }
    stored, _bodies = labelled_blocks(root)
    replacements = {}
    for family in document["families"]:
        for block in family["blocks"]:
            definition = next(item for item in baseline["families"] if item["id"] == family["id"])
            body = _block_bytes(
                block, originals[block["name"]], stored[block["name"]],
                set(definition["command_opcodes"]),
            )
            if body != stored[block["name"]]:
                replacements[block["name"]] = body
    if not replacements:
        return []
    path = root / SOURCE_PATH
    rebuilt = rebuild_source(root, SOURCE_PATH, replacements)
    if rebuilt == path.read_text(encoding="utf-8"):
        return []
    if write:
        from authoring.atomic_output import atomic_write_text as _write_text
        _write_text(path, rebuilt)
    return [SOURCE_PATH]


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return [
        "zero-edit sound envelopes would change %s" % path
        for path in apply_document(document, root, profile, write=False)
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "export", "validate"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=PROFILES, default="jp")
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
            print("[OK] %s sound envelopes: %d tables, %d values, %d commands" % (
                args.profile, document["envelope_count"], document["value_count"],
                document["command_count"]))
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
