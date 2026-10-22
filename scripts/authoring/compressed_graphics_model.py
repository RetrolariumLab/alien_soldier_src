#!/usr/bin/env python3
"""Export, validate, and stage fixed-slot LZSS and tile-codec graphics."""

from __future__ import annotations

import argparse
from copy import deepcopy
import json
import re
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.lzss_codec import compress, decompress_as_vram  # noqa: E402
from authoring.object_sprite_model import (  # noqa: E402
    read_pointer_table,
    source_index,
)
from authoring.stage_tilemap_model import (  # noqa: E402
    labelled_blocks,
    read_asset_lists,
    source_texts,
    parsed_read_phase,
    with_parsed_operation,
)
from authoring.tile_graphics import TILE_BYTES, decode_tile, encode_tile  # noqa: E402
from authoring.tile_codec import decompress as decode_tile_codec  # noqa: E402
from authoring.tile_codec_edit import compress_edited  # noqa: E402
from authoring.text_document_contract import record_names, source_value_matches  # noqa: E402


SCHEMA_VERSION = 2
FORMAT = "megadrive-4bpp-compressed-fixed-slots"
LEGACY_FORMAT = "megadrive-4bpp-lzss-fixed-slots"
PROFILES = ("jp", "eu")
SHARED_TILE_SOURCES = "Stage_SharedTileSourceTable"
DECOMPRESS_TO_VRAM = 7
PIXELS = re.compile(r"^[0-9A-F]{64}$")
BINCLUDE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"([^"]+)"')
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
BYTE_LINE = re.compile(
    r"^(?P<prefix>(?:[A-Za-z_][A-Za-z0-9_]*:\s*)?\s*dc\.b\s+)"
    r"(?P<body>[^;]+?)(?P<suffix>\s*(?:;.*)?)$"
)
NON_TILE_VRAM_PAYLOADS = {
    "Credits_SegaMappingData": ("command 7 transfers 408 mapping bytes to VRAM, not a whole number of 32-byte tiles"),
}


def source_paths(root: Path) -> dict[str, str]:
    found = {}
    for path, text in source_texts(root):
        for line in text.splitlines():
            match = BINCLUDE.match(line)
            if match:
                found[match.group(1)] = match.group(2)
    return found


def source_owners(root: Path) -> dict[str, str]:
    found = {}
    for path, text in source_texts(root):
        relative = path.relative_to(root).as_posix()
        for line in text.splitlines():
            match = LABEL.match(line)
            if match:
                found[match.group(1)] = relative
    return found


def vram_sources(root: Path, command_ids: tuple[int, ...] = (7,)) -> set[str]:
    _data, bodies = labelled_blocks(root)
    lists = read_asset_lists(root, bodies)
    direct = {command.source for commands in lists.values() for command in commands if command.command in command_ids}
    if DECOMPRESS_TO_VRAM not in command_ids:
        return direct
    lines, index = source_index(root)
    return direct | set(read_pointer_table(lines, index, SHARED_TILE_SOURCES))


def tile_text(data: bytes, offset: int) -> str:
    if (type(data) is bytes or type(data) is bytearray) and type(offset) is int:
        if offset + TILE_BYTES > len(data):
            raise ValueError("tile at %d runs past %d bytes" % (offset, len(data)))
        return data[offset : offset + TILE_BYTES].hex().upper()
    return "".join("%X" % pixel for pixel in decode_tile(data, offset))


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown compressed graphics profile: %s" % profile)
    data, _bodies = labelled_blocks(root)
    paths = source_paths(root)
    owners = source_owners(root)
    records = []
    excluded = {}
    tile_sources = vram_sources(root, (2, 3))
    for name in sorted(vram_sources(root) | tile_sources):
        raw = data.get(name)
        if not isinstance(raw, bytes):
            raise ValueError("compressed VRAM source has no byte payload: %s" % name)
        storage = "payload" if name in paths else "source"
        path = paths.get(name, owners.get(name))
        if path is None:
            raise ValueError("compressed VRAM source has no owner: %s" % name)
        codec = "tile-codec" if name in tile_sources else "lzss"
        plain = decode_tile_codec(raw) if codec == "tile-codec" else decompress_as_vram(raw)
        if len(plain) % TILE_BYTES:
            excluded[name] = NON_TILE_VRAM_PAYLOADS.get(name, "unclassified non-tile data")
            continue
        tiles = [tile_text(plain, offset) for offset in range(0, len(plain), TILE_BYTES)]
        records.append(
            {
                "name": name,
                "codec": codec,
                "path": path,
                "storage": storage,
                "compressed_capacity": len(raw),
                "decoded_byte_count": len(plain),
                "tile_count": len(tiles),
                "blocks": [
                    {
                        "declared_length": False,
                        "tile_count": len(tiles),
                        "tiles": tiles,
                    }
                ],
            }
        )
    if excluded != NON_TILE_VRAM_PAYLOADS:
        raise ValueError("compressed non-tile exclusions differ: %r" % excluded)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "tile_width": 8,
        "tile_height": 8,
        "bits_per_pixel": 4,
        "payload_count": len(records),
        "tile_count": sum(record["tile_count"] for record in records),
        "decoded_byte_count": sum(record["decoded_byte_count"] for record in records),
        "compressed_capacity": sum(record["compressed_capacity"] for record in records),
        "excluded": excluded,
        "payloads": records,
    }


def upgrade_legacy_document(document: dict[str, Any], root: Path, profile: str) -> dict[str, Any]:
    """Preserve validated schema-1 LZSS edits and add the source-owned tile art."""
    baseline = export_document(root, profile)
    legacy_records = [record for record in baseline["payloads"] if record["codec"] == "lzss"]
    expected = {**baseline, "schema_version": 1, "format": LEGACY_FORMAT, "payload_count": len(legacy_records)}
    for field in ("tile_count", "decoded_byte_count", "compressed_capacity"):
        expected[field] = sum(record[field] for record in legacy_records)
    for field, value in expected.items():
        if field != "payloads" and not source_value_matches(document.get(field), value):
            raise ValueError("legacy compressed graphics %s differs from source ownership" % field)
    candidate = deepcopy(document)
    records = candidate.get("payloads")
    if not isinstance(records, list) or any(not isinstance(record, dict) or "codec" in record for record in records):
        raise ValueError("legacy compressed graphics payload inventory differs")
    for record in records:
        record["codec"] = "lzss"
    records.extend(deepcopy(record) for record in baseline["payloads"] if record["codec"] == "tile-codec")
    records.sort(key=lambda record: record.get("name", "") if isinstance(record.get("name"), str) else "")
    for field in (
        "schema_version",
        "format",
        "payload_count",
        "tile_count",
        "decoded_byte_count",
        "compressed_capacity",
    ):
        candidate[field] = baseline[field]
    validate_document(candidate, root, profile)
    return candidate


def load_document(path: Path, root: Path | None = None, profile: str | None = None) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load compressed graphics document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("compressed graphics document is not an object: %s" % path)
    if document.get("schema_version") == 1 and root is not None and profile is not None:
        return upgrade_legacy_document(document, root, profile)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def payload_plain(record: dict[str, Any]) -> bytes:
    output = bytearray()
    for block in record["blocks"]:
        for pixels in block["tiles"]:
            output += encode_tile([int(pixel, 16) for pixel in pixels])
    return bytes(output)


def encoded_slot(record: dict[str, Any], original: bytes | None = None) -> bytes:
    if record.get("codec", "lzss") == "tile-codec":
        if original is None:
            raise ValueError("tile-codec encoding requires the original source stream")
        encoded = compress_edited(original, payload_plain(record))
    else:
        encoded = compress(payload_plain(record))
    capacity = record["compressed_capacity"]
    if len(encoded) > capacity:
        raise ValueError(
            "%s: recompressed size %d exceeds fixed capacity %d" % (record["name"], len(encoded), capacity)
        )
    return encoded + bytes([0xFF]) * (capacity - len(encoded))


def parse_byte(token: str) -> int:
    token = token.strip()
    return int(token[1:], 16) if token.startswith("$") else int(token)


def format_byte(value: int) -> str:
    return str(value) if value < 10 else "$%X" % value


def rewrite_byte_body(body: str, values: bytes) -> str:
    tokens = body.split(",")
    if len(tokens) != len(values):
        raise ValueError("compressed source token count changed while rebuilding")
    rendered = []
    for token, value in zip(tokens, values):
        match = re.match(r"^(\s*)(.*?)(\s*)$", token)
        assert match is not None
        original = match.group(2)
        replacement = original if parse_byte(original) == value else format_byte(value)
        rendered.append(match.group(1) + replacement + match.group(3))
    return ",".join(rendered)


def rebuild_source(root: Path, source_path: str, payloads: dict[str, bytes]) -> str:
    path = root / source_path
    lines = path.read_text(encoding="utf-8").split("\n")
    locations: dict[str, list[tuple[int, re.Match[str]]]] = {}
    current = None
    for index, line in enumerate(lines):
        label = LABEL.match(line)
        if label is not None:
            current = label.group(1)
        match = BYTE_LINE.match(line)
        if match is not None and current in payloads:
            locations.setdefault(current, []).append((index, match))
    missing = sorted(set(payloads) - set(locations))
    if missing:
        raise ValueError("cannot locate compressed source blocks: %s" % ", ".join(missing))
    output = list(lines)
    for name, spans in locations.items():
        desired = payloads[name]
        cursor = 0
        for line_index, match in spans:
            count = len(match.group("body").split(","))
            values = desired[cursor : cursor + count]
            if len(values) != count:
                raise ValueError("%s source has more tokens than its fixed slot" % name)
            body = rewrite_byte_body(match.group("body"), values)
            output[line_index] = match.group("prefix") + body + match.group("suffix")
            cursor += count
        if cursor != len(desired):
            raise ValueError("%s source holds %d bytes, document encodes %d" % (name, cursor, len(desired)))
    return "\n".join(output)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "tile_width",
        "tile_height",
        "bits_per_pixel",
        "payload_count",
        "tile_count",
        "decoded_byte_count",
        "compressed_capacity",
        "excluded",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("payloads")
    if not isinstance(records, list):
        return errors + ["payloads is not a list"]
    originals = {item["name"]: item for item in baseline["payloads"]}
    names = record_names(records)
    if len(names) != len(records) or len(set(names)) != len(names):
        errors.append("payload names are missing or not unique")
    if set(names) != set(originals):
        errors.append("payload inventory differs from the source")
    stored, _bodies = labelled_blocks(root)
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("name"), str):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in (
            "path",
            "storage",
            "codec",
            "compressed_capacity",
            "decoded_byte_count",
            "tile_count",
        ):
            if not source_value_matches(record.get(field), original[field]):
                errors.append("%s: %s differs from the source-owned value" % (name, field))
        blocks = record.get("blocks")
        if not isinstance(blocks, list) or len(blocks) != 1:
            errors.append("%s: block inventory differs" % name)
            continue
        block = blocks[0]
        tiles = block.get("tiles") if isinstance(block, dict) else None
        if not isinstance(tiles, list):
            errors.append("%s: tiles is not a list" % name)
            continue
        if block.get("declared_length") is not False:
            errors.append("%s: declared_length differs" % name)
        if not source_value_matches(block.get("tile_count"), original["tile_count"]):
            errors.append("%s: block tile_count differs" % name)
        if len(tiles) != original["tile_count"]:
            errors.append("%s: tile count differs from fixed decoded capacity" % name)
        malformed = False
        for index, pixels in enumerate(tiles):
            if not isinstance(pixels, str) or PIXELS.fullmatch(pixels) is None:
                errors.append("%s tile %d is not 64 uppercase nibbles" % (name, index))
                malformed = True
        if malformed or len(tiles) != original["tile_count"]:
            continue
        if tiles != original["blocks"][0]["tiles"]:
            try:
                encoded_slot(record, stored[name])
            except (KeyError, TypeError, ValueError) as error:
                errors.append(str(error))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(document: dict[str, Any], root: Path, profile: str, write: bool = True) -> list[str]:
    """Recompress edited tiles into their original fixed-size binary slots."""
    # Share only ORIGINAL parsed inputs during preparation; close before any
    # payload/source writer. A foreign active scope retains its fresh reader.
    with parsed_read_phase(root):
        validate_document(document, root, profile)
        stored, _bodies = labelled_blocks(root)
    changed = []
    source_changes: dict[str, dict[str, bytes]] = {}
    for record in document["payloads"]:
        path = root / record["path"]
        baseline = stored[record["name"]]
        decoder = decode_tile_codec if record["codec"] == "tile-codec" else decompress_as_vram
        if decoder(baseline) == payload_plain(record):
            continue
        body = encoded_slot(record, baseline)
        if record["storage"] == "source":
            source_changes.setdefault(record["path"], {})[record["name"]] = body
            continue
        changed.append(record["path"])
        if write:
            from authoring.atomic_output import atomic_write_bytes as _write_bytes

            _write_bytes(path, body)
    for source_path, payloads in sorted(source_changes.items()):
        path = root / source_path
        rebuilt = rebuild_source(root, source_path, payloads)
        if rebuilt != path.read_text(encoding="utf-8"):
            changed.append(source_path)
            if write:
                from authoring.atomic_output import atomic_write_text as _write_text

                _write_text(path, rebuilt)
    return changed


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return [
        "zero-edit compressed graphics document would change %s" % path
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
            print(
                "[OK] %s compressed graphics: %d payloads, %d tiles, "
                "%d fixed bytes"
                % (args.profile, document["payload_count"], document["tile_count"], document["compressed_capacity"])
            )
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] compressed graphics document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document), root, args.profile), root, args.profile)
            print("[OK] compressed graphics document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
