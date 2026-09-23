#!/usr/bin/env python3
"""Export, validate, and stage fixed-capacity Mega Drive tile art."""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.tile_graphics import (
    ART_DIRECTORY, TILE_BYTES, decode_tile, encode_tile, read_sheet)
from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
PIXELS = re.compile(r"^[0-9A-F]{64}$")


def tile_text(data: bytes, offset: int) -> str:
    if (type(data) is bytes or type(data) is bytearray) and type(offset) is int:
        if offset + TILE_BYTES > len(data):
            raise ValueError("tile at %d runs past %d bytes" % (offset, len(data)))
        return data[offset:offset + TILE_BYTES].hex().upper()
    return "".join("%X" % pixel for pixel in decode_tile(data, offset))


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown graphics profile: %s" % profile)
    payloads = []
    tile_count = 0
    for path in sorted((root / ART_DIRECTORY).glob("*.bin")):
        sheet = read_sheet(path)
        blocks = []
        for block in sheet.blocks:
            tiles = [
                tile_text(sheet.data, block.offset + index * TILE_BYTES)
                for index in range(block.tile_count)
            ]
            tile_count += len(tiles)
            blocks.append({
                "declared_length": block.declared,
                "tile_count": block.tile_count,
                "tiles": tiles,
            })
        payloads.append({
            "name": path.name,
            "path": path.relative_to(root).as_posix(),
            "byte_count": len(sheet.data),
            "blocks": blocks,
        })
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "megadrive-4bpp-fixed-payloads",
        "tile_width": 8,
        "tile_height": 8,
        "bits_per_pixel": 4,
        "payload_count": len(payloads),
        "tile_count": tile_count,
        "payloads": payloads,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load graphics document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("graphics document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def payload_bytes(record: dict[str, Any]) -> bytes:
    output = bytearray()
    for block in record["blocks"]:
        tiles = block["tiles"]
        if block["declared_length"]:
            output += struct.pack(">H", len(tiles) * TILE_BYTES)
        for pixels in tiles:
            output += encode_tile([int(pixel, 16) for pixel in pixels])
    return bytes(output)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "tile_width", "tile_height",
        "bits_per_pixel", "payload_count", "tile_count",
    ):
        if document.get(field) != baseline[field]:
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("payloads")
    if not isinstance(records, list):
        return errors + ["payloads is not a list"]
    originals = {item["name"]: item for item in baseline["payloads"]}
    names = [item.get("name") for item in records if isinstance(item, dict)]
    if len(names) != len(records) or len(set(names)) != len(names):
        errors.append("payload names are missing or not unique")
    if set(names) != set(originals):
        errors.append("payload inventory differs from the source")
    for record in records:
        if not isinstance(record, dict):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in ("path", "byte_count"):
            if record.get(field) != original[field]:
                errors.append("%s: %s differs from the source-owned value" % (name, field))
        blocks = record.get("blocks")
        if not isinstance(blocks, list):
            errors.append("%s: blocks is not a list" % name)
            continue
        if len(blocks) != len(original["blocks"]):
            errors.append("%s: block count differs from fixed capacity" % name)
            continue
        for index, (block, source) in enumerate(zip(blocks, original["blocks"])):
            if not isinstance(block, dict):
                errors.append("%s block %d is not an object" % (name, index))
                continue
            for field in ("declared_length", "tile_count"):
                if block.get(field) != source[field]:
                    errors.append("%s block %d: %s differs" % (name, index, field))
            tiles = block.get("tiles")
            if not isinstance(tiles, list):
                errors.append("%s block %d: tiles is not a list" % (name, index))
                continue
            if len(tiles) != source["tile_count"]:
                errors.append("%s block %d: tile count differs from fixed capacity"
                              % (name, index))
            for tile_index, pixels in enumerate(tiles):
                if not isinstance(pixels, str) or PIXELS.fullmatch(pixels) is None:
                    errors.append("%s block %d tile %d is not 64 uppercase nibbles"
                                  % (name, index, tile_index))
        try:
            encoded = payload_bytes(record)
        except (KeyError, TypeError, ValueError) as error:
            errors.append("%s: cannot encode payload (%s)" % (name, error))
        else:
            if len(encoded) != original["byte_count"]:
                errors.append("%s: encoded size %d differs from fixed %d"
                              % (name, len(encoded), original["byte_count"]))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True
) -> list[str]:
    """Apply graphics only to a staged tree, preserving every payload size."""
    validate_document(document, root, profile)
    changed = []
    for record in document["payloads"]:
        path = root / record["path"]
        body = payload_bytes(record)
        if path.read_bytes() == body:
            continue
        changed.append(record["path"])
        if write:
            from authoring.atomic_output import atomic_write_bytes as _write_bytes
            _write_bytes(path, body)
    return changed


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return ["zero-edit graphics document would change %s" % path
            for path in apply_document(document, root, profile, write=False)]


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
            print("[OK] %s graphics workspace: %d payloads, %d fixed tiles" % (
                args.profile, document["payload_count"], document["tile_count"]))
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] graphics document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] graphics document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
