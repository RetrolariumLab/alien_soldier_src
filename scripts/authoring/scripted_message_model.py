#!/usr/bin/env python3
"""Model the relative-offset boss and ship message scripts."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import (  # noqa: E402
    rebuild_source,
    source_owners,
)
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402
from authoring.text_document_contract import record_names, source_value_matches  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
END_RECORD = 0xFF
DMA_COMMAND = 0xFFFE
END_SCRIPT = 0xFFFF
FONT_PATH = Path("data/artunc/font.bin")
GLYPH_BYTES = 64
NAMES = (
    "BossMessageScript_CommonGroup",
    "BossMessageScript_ShellshogunGroup",
    "BossMessageScript_UnusedSlot2",
    "BossMessageScript_AntroidGroup",
    "BossMessageScript_DeepStriderGroup",
    "BossMessageScript_MadamBarbar",
    "BossMessageScript_FlyingNeo",
    "BossMessageScript_JokerGroup",
    "ShipAndValkirieMessageScript",
)


def read_word(body: bytes, offset: int, name: str) -> int:
    if offset < 0 or offset + 2 > len(body):
        raise ValueError("%s command word exceeds its fixed slot" % name)
    return int.from_bytes(body[offset:offset + 2], "big")


def signed_word(value: int) -> int:
    return value - 0x10000 if value >= 0x8000 else value


def font_glyph_count(root: Path) -> int:
    size = (root / FONT_PATH).stat().st_size
    if size == 0 or size % GLYPH_BYTES:
        raise ValueError("shared font size is not a whole number of glyphs")
    return size // GLYPH_BYTES


def parse_script(body: bytes, name: str, glyph_limit: int) -> dict[str, Any]:
    commands = []
    targets = []
    cursor = 0
    while True:
        value = read_word(body, cursor, name)
        if value == END_SCRIPT:
            commands.append({"offset": cursor, "kind": "end"})
            cursor += 2
            break
        if value == DMA_COMMAND:
            if cursor + 6 > len(body):
                raise ValueError("%s DMA command exceeds its fixed slot" % name)
            commands.append({
                "offset": cursor,
                "kind": "dma",
                "source_pointer": int.from_bytes(body[cursor + 2:cursor + 6], "big"),
            })
            cursor += 6
            continue
        target = cursor + signed_word(value)
        commands.append({
            "offset": cursor,
            "kind": "record",
            "relative_offset": signed_word(value),
            "target": target,
        })
        targets.append(target)
        cursor += 2

    if len(set(targets)) != len(targets):
        raise ValueError("%s command list repeats a record target" % name)

    occupied = set(range(cursor))
    records = []
    for target in targets:
        if target < cursor or target + 2 > len(body):
            raise ValueError("%s record target is outside the data area" % name)
        try:
            end = body.index(END_RECORD, target + 2)
        except ValueError as error:
            raise ValueError("%s record has no $FF terminator" % name) from error
        span = set(range(target, end + 1))
        if occupied & span:
            raise ValueError("%s record ranges overlap" % name)
        occupied.update(span)
        glyphs = list(body[target + 2:end])
        if any(value >= glyph_limit for value in glyphs):
            raise ValueError("%s record selects a glyph outside the shared font" % name)
        records.append({
            "target": target,
            "attributes": list(body[target:target + 2]),
            "glyph_capacity": len(glyphs),
            "glyphs": glyphs,
        })

    layout = bytearray(body)
    for record in records:
        start = record["target"] + 2
        layout[start:start + record["glyph_capacity"]] = bytes(record["glyph_capacity"])
    return {
        "capacity": len(body),
        "command_count": len(commands),
        "record_count": len(records),
        "glyph_count": sum(record["glyph_capacity"] for record in records),
        "unexposed_byte_count": len(body) - len(occupied),
        "layout_sha256": hashlib.sha256(layout).hexdigest(),
        "commands": commands,
        "records": records,
    }


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown scripted-message profile: %s" % profile)
    data, _bodies = labelled_blocks(root)
    owners = source_owners(root)
    glyph_limit = font_glyph_count(root)
    scripts = []
    for name in NAMES:
        body = data.get(name)
        if not isinstance(body, bytes):
            raise ValueError("scripted-message payload is missing: %s" % name)
        record = parse_script(body, name, glyph_limit)
        record.update({
            "name": name,
            "path": owners[name],
            "storage": "source",
        })
        scripts.append(record)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "relative-word-message-script-with-ff-records",
        "font_path": FONT_PATH.as_posix(),
        "font_glyph_count": glyph_limit,
        "script_count": len(scripts),
        "command_count": sum(item["command_count"] for item in scripts),
        "record_count": sum(item["record_count"] for item in scripts),
        "glyph_count": sum(item["glyph_count"] for item in scripts),
        "encoded_byte_count": sum(item["capacity"] for item in scripts),
        "unexposed_byte_count": sum(
            item["unexposed_byte_count"] for item in scripts),
        "scripts": scripts,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError(
            "cannot load scripted-message document %s: %s" % (path, error)
        ) from error
    if not isinstance(document, dict):
        raise ValueError("scripted-message document is not an object")
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    fields = (
        "schema_version", "profile", "format", "font_path", "font_glyph_count",
        "script_count", "command_count", "record_count", "glyph_count",
        "encoded_byte_count", "unexposed_byte_count",
    )
    for field in fields:
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    scripts = document.get("scripts")
    if not isinstance(scripts, list):
        return errors + ["scripts is not a list"]
    originals = {item["name"]: item for item in baseline["scripts"]}
    names = record_names(scripts)
    if len(names) != len(scripts) or len(set(names)) != len(names):
        errors.append("script names are missing or not unique")
    if set(names) != set(originals):
        errors.append("script inventory differs from the source")
    for script in scripts:
        if not isinstance(script, dict) or not isinstance(script.get("name"), str):
            continue
        name = script.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in (
            "path", "storage", "capacity", "command_count", "record_count",
            "glyph_count", "unexposed_byte_count", "layout_sha256", "commands",
        ):
            if not source_value_matches(script.get(field), original[field]):
                errors.append("%s: %s differs" % (name, field))
        records = script.get("records")
        if not isinstance(records, list) or len(records) != original["record_count"]:
            errors.append("%s: record inventory differs" % name)
            continue
        for index, (record, source) in enumerate(zip(records, original["records"])):
            if not isinstance(record, dict):
                errors.append("%s record %d is not an object" % (name, index))
                continue
            for field in ("target", "attributes", "glyph_capacity"):
                if not source_value_matches(record.get(field), source[field]):
                    errors.append("%s record %d: %s differs" % (name, index, field))
            glyphs = record.get("glyphs")
            if not isinstance(glyphs, list) or len(glyphs) != source["glyph_capacity"]:
                errors.append("%s record %d: glyph capacity differs" % (name, index))
                continue
            if any(
                not isinstance(value, int) or isinstance(value, bool)
                or not 0 <= value < baseline["font_glyph_count"]
                for value in glyphs
            ):
                errors.append("%s record %d: invalid glyph index" % (name, index))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def encode_script(script: dict[str, Any], body: bytes) -> bytes:
    output = bytearray(body)
    if len(output) != script["capacity"]:
        raise ValueError("%s source capacity changed" % script["name"])
    for record in script["records"]:
        start = record["target"] + 2
        end = start + record["glyph_capacity"]
        output[start:end] = bytes(record["glyphs"])
    return bytes(output)


def apply_document(
    document: dict[str, Any],
    root: Path,
    profile: str,
    write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    data, _bodies = labelled_blocks(root)
    changes: dict[str, dict[str, bytes]] = {}
    for script in document["scripts"]:
        body = encode_script(script, data[script["name"]])
        if body != data[script["name"]]:
            changes.setdefault(script["path"], {})[script["name"]] = body
    for relative, payloads in changes.items():
        if write:
            path = root / relative
            rebuilt = rebuild_source(root, relative, payloads)
            from authoring.atomic_output import atomic_write_text as _write_text
            _write_text(path, rebuilt)
    return sorted(changes)


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
            document = export_document(root, args.profile)
            validate_document(document, root, args.profile)
            if apply_document(document, root, args.profile, write=False):
                raise ValueError("zero-edit scripted messages would change files")
            print(
                "[OK] %s scripted messages: %d scripts, %d reachable records"
                % (args.profile, document["script_count"], document["record_count"])
            )
        elif args.command == "export":
            atomic_write_json(Path(args.output), export_document(root, args.profile))
        else:
            validate_document(load_document(Path(args.document)), root, args.profile)
        return 0
    except (KeyError, OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
