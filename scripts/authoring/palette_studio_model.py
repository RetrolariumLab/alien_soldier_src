#!/usr/bin/env python3
"""Export, validate, and stage fixed-layout palette commands."""

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

from authoring.palette_model import (  # noqa: E402
    PALETTE_SOURCE, command_index, parse_number, read_source)
from authoring.tile_graphics import cram_to_rgb  # noqa: E402
from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
BYTE_LINE = re.compile(
    r"^(?P<prefix>(?:[A-Za-z_][A-Za-z0-9_]*:\s*)?\s*dc\.b\s+)"
    r"(?P<body>[^;]+?)(?P<suffix>\s*(?:;.*)?)$"
)
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown palette profile: %s" % profile)
    blocks, lists = read_source(root)
    commands, other = command_index(blocks)
    if other:
        raise ValueError("palette source contains non-command blocks: %s"
                         % ", ".join(sorted(other)))
    records = []
    for (block, offset), command in sorted(commands.items()):
        owner = blocks[block]
        records.append({
            "block": block,
            "offset": offset,
            "label": command.label,
            "storage": owner.storage,
            "source_path": (
                PALETTE_SOURCE.as_posix()
                if owner.storage == "source" else owner.payload
            ),
            "destination": command.destination,
            "colour_count": command.count,
            "colours": list(command.colours),
        })
    offset_lists = [
        {
            "name": item.name,
            "index": item.index,
            "label": item.label,
            "entries": [
                {"block": block, "offset": offset}
                for block, offset in item.entries
            ],
        }
        for item in lists
    ]
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "destination-count-cram-words",
        "source": PALETTE_SOURCE.as_posix(),
        "block_count": len(blocks),
        "command_count": len(records),
        "offset_list_count": len(offset_lists),
        "commands": records,
        "offset_lists": offset_lists,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load palette document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("palette document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def command_key(record: dict[str, Any]) -> tuple[str, int]:
    return record.get("block"), record.get("offset")


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "source", "block_count",
        "command_count", "offset_list_count", "offset_lists",
    ):
        if document.get(field) != baseline[field]:
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("commands")
    if not isinstance(records, list):
        return errors + ["commands is not a list"]
    originals = {command_key(item): item for item in baseline["commands"]}
    keys = [command_key(item) for item in records if isinstance(item, dict)]
    if len(keys) != len(records) or len(set(keys)) != len(keys):
        errors.append("command keys are missing or not unique")
    if set(keys) != set(originals):
        errors.append("command inventory differs from the source")
    for record in records:
        if not isinstance(record, dict):
            continue
        key = command_key(record)
        original = originals.get(key)
        if original is None:
            continue
        for field in (
            "label", "storage", "source_path", "destination", "colour_count",
        ):
            if record.get(field) != original[field]:
                errors.append("%s: %s differs from the source-owned value"
                              % (original["label"], field))
        colours = record.get("colours")
        if not isinstance(colours, list):
            errors.append("%s: colours is not a list" % original["label"])
            continue
        if len(colours) != original["colour_count"]:
            errors.append("%s: colour count differs from fixed capacity"
                          % original["label"])
        for index, word in enumerate(colours):
            if isinstance(word, bool) or not isinstance(word, int) or not 0 <= word <= 0xFFFF:
                errors.append("%s colour %d is not an unsigned word"
                              % (original["label"], index))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def encoded_blocks(document: dict[str, Any]) -> dict[str, bytes]:
    grouped: dict[str, list[tuple[int, dict[str, Any]]]] = {}
    for record in document["commands"]:
        grouped.setdefault(record["block"], []).append((record["offset"], record))
    output = {}
    for block, records in grouped.items():
        body = bytearray()
        for offset, record in sorted(records):
            if offset != len(body):
                raise ValueError("%s command offset $%X follows $%X bytes"
                                 % (block, offset, len(body)))
            count = record["colour_count"]
            body += bytes((record["destination"], count - 1))
            for word in record["colours"]:
                body += bytes((word >> 8, word & 0xFF))
        output[block] = bytes(body)
    return output


def source_spans(root: Path, block_names: set[str]):
    lines = (root / PALETTE_SOURCE).read_text(encoding="utf-8").split("\n")
    spans: dict[str, list[tuple[int, re.Match[str]]]] = {}
    current = None
    for index, line in enumerate(lines):
        label = LABEL.match(line)
        if label is not None:
            current = label.group(1)
        match = BYTE_LINE.match(line)
        if match is not None and current in block_names:
            spans.setdefault(current, []).append((index, match))
    return lines, spans


def format_byte(value: int) -> str:
    return str(value) if value < 10 else "$%X" % value


def rewrite_byte_body(body: str, values: bytes) -> str:
    """Replace changed byte tokens without reformatting untouched source."""
    tokens = body.split(",")
    if len(tokens) != len(values):
        raise ValueError("palette source token count changed while rebuilding")
    rendered = []
    for token, value in zip(tokens, values):
        match = re.match(r"^(\s*)(.*?)(\s*)$", token)
        assert match is not None
        original = match.group(2)
        replacement = original if parse_number(original) == value else format_byte(value)
        rendered.append(match.group(1) + replacement + match.group(3))
    return ",".join(rendered)


def rebuild_source(
    document: dict[str, Any], root: Path, source_blocks: set[str]
) -> list[str]:
    blocks = encoded_blocks(document)
    lines, spans = source_spans(root, source_blocks)
    output = list(lines)
    for block, locations in spans.items():
        data = blocks[block]
        cursor = 0
        for line_index, match in locations:
            count = len(match.group("body").split(","))
            body = rewrite_byte_body(
                match.group("body"), data[cursor:cursor + count])
            cursor += count
            output[line_index] = match.group("prefix") + body + match.group("suffix")
        if cursor != len(data):
            raise ValueError("%s source holds %d byte tokens, document encodes %d"
                             % (block, cursor, len(data)))
    if set(spans) != source_blocks:
        missing = sorted(source_blocks - set(spans))
        raise ValueError("cannot locate palette source blocks: %s" % ", ".join(missing))
    return output


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True
) -> list[str]:
    validate_document(document, root, profile)
    encoded = encoded_blocks(document)
    baseline, _ = read_source(root)
    source_blocks = {
        name for name, block in baseline.items()
        if name in encoded and block.storage == "source"
    }
    path = root / PALETTE_SOURCE
    lines = path.read_text(encoding="utf-8").split("\n")
    rebuilt = rebuild_source(document, root, source_blocks)
    changes = []
    writes: list[tuple[Path, bytes | str, bool]] = []
    if rebuilt != lines:
        changes.append(PALETTE_SOURCE.as_posix())
        writes.append((path, "\n".join(rebuilt), True))
    for name, block in sorted(baseline.items()):
        if name not in encoded or block.storage != "payload":
            continue
        if encoded[name] != block.data:
            changes.append(block.payload)
            writes.append((root / block.payload, encoded[name], False))
    if write:
        for target, content, is_text in writes:
            if is_text:
                from authoring.atomic_output import atomic_write_text

                atomic_write_text(target, content)
            else:
                from authoring.atomic_output import atomic_write_bytes

                atomic_write_bytes(target, content)
    return changes


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
        changes = apply_document(document, root, profile, write=False)
    except ValueError as error:
        return [str(error)]
    return ["zero-edit palette document would change %s" % path for path in changes]


def preview(record: dict[str, Any]) -> list[tuple[int, int, int]]:
    return [cram_to_rgb(word) for word in record["colours"]]


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
            print("[OK] %s palette workspace: %d fixed commands in %d blocks" % (
                args.profile, document["command_count"], document["block_count"]))
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] palette document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] palette document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
