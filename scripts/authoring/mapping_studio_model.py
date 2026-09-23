#!/usr/bin/env python3
"""Export, validate, and stage every proved sprite-mapping block."""

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

from authoring.sprite_mapping_model import (  # noqa: E402
    ART_OPERAND,
    LAST_PIECE,
    TILE_INDEX_MASK,
    parse_number,
    read_blocks,
)
from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
DATA_LINE = re.compile(
    r"^(?P<prefix>(?:[A-Za-z_][A-Za-z0-9_]*:\s*)?\s*"
    r"(?P<kind>dc\.[bwl])\s+)(?P<body>[^;]+?)(?P<suffix>\s*(?:;.*)?)$"
)


def piece_record(piece, index: int) -> dict[str, Any]:
    return {
        "index": index,
        "attributes": piece.attributes,
        "size": piece.size,
        "link": piece.link,
        "y": piece.y,
        "x": piece.x,
        "art": piece.art,
        "art_addend": piece.art_addend,
    }


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown mapping profile: %s" % profile)
    blocks, skipped = read_blocks(root)
    records = []
    mappings = 0
    pieces = 0
    static_mappings = 0
    dynamic_mappings = 0
    for block in blocks:
        mapped = []
        for mapping in block.mappings:
            mapped.append({
                "offset": mapping.offset,
                "label": mapping.label,
                "dynamic": mapping.dynamic,
                "piece_count": len(mapping.pieces),
                "pieces": [
                    piece_record(piece, index)
                    for index, piece in enumerate(mapping.pieces)
                ],
            })
            mappings += 1
            pieces += len(mapping.pieces)
            if mapping.dynamic:
                dynamic_mappings += 1
            else:
                static_mappings += 1
        records.append({
            "name": block.name,
            "source_path": block.source,
            "storage": block.storage,
            "payload_path": block.payload,
            "mapping_count": len(mapped),
            "piece_count": sum(item["piece_count"] for item in mapped),
            "mappings": mapped,
        })
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "fixed-piece-chains",
        "block_count": len(records),
        "mapping_count": mappings,
        "piece_count": pieces,
        "static_mapping_count": static_mappings,
        "dynamic_mapping_count": dynamic_mappings,
        "payload_block_count": sum(
            1 for block in records if block["storage"] == "payload"
        ),
        "excluded_count": len(skipped),
        "blocks": records,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load mapping document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("mapping document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def _unsigned(value: Any, maximum: int) -> bool:
    return type(value) is int and 0 <= value <= maximum


def _signed_byte(value: Any) -> bool:
    return type(value) is int and -128 <= value <= 127


def _source_value_matches(value: Any, original: Any) -> bool:
    return type(value) is type(original) and value == original


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    if type(document) is not dict:
        return ["mapping document is not an object"]
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "block_count", "mapping_count",
        "piece_count", "static_mapping_count", "dynamic_mapping_count",
        "payload_block_count", "excluded_count",
    ):
        if not _source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    blocks = document.get("blocks")
    if not isinstance(blocks, list):
        return errors + ["blocks is not a list"]
    originals = {block["name"]: block for block in baseline["blocks"]}
    names = [block["name"] for block in blocks
             if isinstance(block, dict) and type(block.get("name")) is str]
    if len(names) != len(blocks) or len(set(names)) != len(names):
        errors.append("block names are missing or not unique")
    if set(names) != set(originals):
        errors.append("mapping block inventory differs from the source")
    for block in blocks:
        if not isinstance(block, dict) or type(block.get("name")) is not str:
            continue
        original_block = originals.get(block.get("name"))
        if original_block is None:
            continue
        for field in (
            "source_path", "storage", "payload_path", "mapping_count", "piece_count",
        ):
            if not _source_value_matches(block.get(field), original_block[field]):
                errors.append("%s: %s differs from the source-owned value"
                              % (original_block["name"], field))
        mapped = block.get("mappings")
        if not isinstance(mapped, list):
            errors.append("%s: mappings is not a list" % original_block["name"])
            continue
        original_mappings = {
            item["offset"]: item for item in original_block["mappings"]
        }
        offsets = [item["offset"] for item in mapped
                   if isinstance(item, dict) and type(item.get("offset")) is int]
        # The encoder emits these packed records in document order. A set-only
        # check would accept moving another mapping over this label's first one.
        if len(offsets) != len(mapped) or offsets != list(original_mappings):
            errors.append("%s: mapping inventory or packed record order differs from the source"
                          % original_block["name"])
        for mapping in mapped:
            if not isinstance(mapping, dict) or type(mapping.get("offset")) is not int:
                continue
            original_mapping = original_mappings.get(mapping.get("offset"))
            if original_mapping is None:
                continue
            for field in ("label", "dynamic", "piece_count"):
                if not _source_value_matches(mapping.get(field), original_mapping[field]):
                    errors.append("%s: %s differs from the source-owned value"
                                  % (original_mapping["label"], field))
            edited_pieces = mapping.get("pieces")
            if not isinstance(edited_pieces, list):
                errors.append("%s: pieces is not a list" % original_mapping["label"])
                continue
            if len(edited_pieces) != len(original_mapping["pieces"]):
                errors.append("%s: piece count differs from fixed capacity"
                              % original_mapping["label"])
                continue
            for piece, original_piece in zip(
                edited_pieces, original_mapping["pieces"]
            ):
                if not isinstance(piece, dict):
                    errors.append("%s: piece is not an object" % original_mapping["label"])
                    continue
                index = original_piece["index"]
                if not _source_value_matches(piece.get("index"), index):
                    errors.append("%s piece %d: index differs from the source"
                                  % (original_mapping["label"], index))
                for field in ("art", "art_addend"):
                    if not _source_value_matches(piece.get(field), original_piece[field]):
                        errors.append("%s piece %d: %s differs from the source"
                                      % (original_mapping["label"], index, field))
                attributes = piece.get("attributes")
                size = piece.get("size")
                link = piece.get("link")
                if not _unsigned(attributes, 0xFFFF):
                    errors.append("%s piece %d: attributes are not an unsigned word"
                                  % (original_mapping["label"], index))
                elif bool(attributes & LAST_PIECE) != bool(
                    original_piece["attributes"] & LAST_PIECE
                ):
                    errors.append("%s piece %d: terminator bit differs from the source"
                                  % (original_mapping["label"], index))
                if not _unsigned(size, 0xFF):
                    errors.append("%s piece %d: raw size is not an unsigned byte"
                                  % (original_mapping["label"], index))
                if not _unsigned(link, 0xFF):
                    errors.append("%s piece %d: link is not an unsigned byte"
                                  % (original_mapping["label"], index))
                if not _signed_byte(piece.get("x")) or not _signed_byte(piece.get("y")):
                    errors.append("%s piece %d: coordinates leave signed-byte bounds"
                                  % (original_mapping["label"], index))
                if original_mapping["dynamic"]:
                    if size != original_piece["size"]:
                        errors.append("%s piece %d: dynamic art size is source-owned"
                                      % (original_mapping["label"], index))
                    if (_unsigned(attributes, 0xFFFF)
                            and attributes & TILE_INDEX_MASK
                            != original_piece["attributes"] & TILE_INDEX_MASK):
                        errors.append("%s piece %d: dynamic tile offset is source-owned"
                                      % (original_mapping["label"], index))
                    if link != 0:
                        errors.append("%s piece %d: dynamic link placeholder is source-owned"
                                      % (original_mapping["label"], index))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def _static_bytes(block: dict[str, Any]) -> bytes:
    output = bytearray()
    for mapping in block["mappings"]:
        for piece in mapping["pieces"]:
            output += struct.pack(
                ">HBBbb", piece["attributes"], piece["size"], piece["link"],
                piece["y"], piece["x"],
            )
    return bytes(output)


def desired_tokens(block: dict[str, Any]) -> list[tuple[str, int | str]]:
    if block["storage"] in {"bytes", "payload", "words"}:
        data = _static_bytes(block)
        if block["storage"] == "bytes":
            return [("dc.b", value) for value in data]
        if block["storage"] == "words":
            return [
                ("dc.w", int.from_bytes(data[index:index + 2], "big"))
                for index in range(0, len(data), 2)
            ]
        return []
    tokens = []
    for mapping in block["mappings"]:
        for piece in mapping["pieces"]:
            addend = (piece["size"] << 24) | piece["art_addend"]
            art = piece["art"] + ("+$%X" % addend if addend else "")
            position = ((piece["y"] & 0xFF) << 8) | (piece["x"] & 0xFF)
            tokens.extend((
                ("dc.w", piece["attributes"]),
                ("dc.l", art),
                ("dc.w", position),
            ))
    return tokens


def _format_number(value: int) -> str:
    return str(value) if value < 10 else "$%X" % value


def _rewrite_token(token: str, kind: str, value: int | str) -> str:
    match = re.match(r"^(\s*)(.*?)(\s*)$", token)
    assert match is not None
    original = match.group(2)
    if isinstance(value, str):
        operand = ART_OPERAND.match(original)
        if operand is None:
            raise ValueError("dynamic art operand is no longer symbolic: %s" % original)
        addend = int(operand.group("addend") or "0", 16)
        actual = operand.group("symbol") + ("+$%X" % addend if addend else "")
        if actual != value:
            raise ValueError("dynamic art operand differs from its fixed owner")
        replacement = original
    else:
        mask = {"dc.b": 0xFF, "dc.w": 0xFFFF}[kind]
        replacement = original if parse_number(original) & mask == value else _format_number(value)
    return match.group(1) + replacement + match.group(3)


def rebuild_source(root: Path, source_path: str, blocks: list[dict[str, Any]]) -> str:
    path = root / source_path
    lines = path.read_text(encoding="utf-8").split("\n")
    wanted = {block["name"]: desired_tokens(block) for block in blocks}
    locations: dict[str, list[tuple[int, re.Match[str]]]] = {}
    current = None
    for index, line in enumerate(lines):
        label = LABEL.match(line)
        if label is not None:
            current = label.group(1)
        match = DATA_LINE.match(line)
        if match is not None and current in wanted:
            locations.setdefault(current, []).append((index, match))
    missing = sorted(set(wanted) - set(locations))
    if missing:
        raise ValueError("cannot locate mapping source blocks: %s" % ", ".join(missing))
    output = list(lines)
    for name, spans in locations.items():
        desired = wanted[name]
        cursor = 0
        for line_index, match in spans:
            originals = match.group("body").split(",")
            selected = desired[cursor:cursor + len(originals)]
            if len(selected) != len(originals):
                raise ValueError("%s source has more tokens than its document" % name)
            if any(kind != match.group("kind") for kind, _ in selected):
                raise ValueError("%s directive width differs from its fixed source" % name)
            body = ",".join(
                _rewrite_token(token, kind, value)
                for token, (kind, value) in zip(originals, selected)
            )
            output[line_index] = match.group("prefix") + body + match.group("suffix")
            cursor += len(originals)
        if cursor != len(desired):
            raise ValueError("%s source token count differs from its document" % name)
    return "\n".join(output)


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True
) -> list[str]:
    validate_document(document, root, profile)
    by_source: dict[str, list[dict[str, Any]]] = {}
    payloads: list[dict[str, Any]] = []
    for block in document["blocks"]:
        if block["storage"] == "payload":
            payloads.append(block)
        else:
            by_source.setdefault(block["source_path"], []).append(block)
    changes = []
    writes: list[tuple[Path, str | bytes, bool]] = []
    for source_path, blocks in sorted(by_source.items()):
        path = root / source_path
        rebuilt = rebuild_source(root, source_path, blocks)
        if rebuilt != path.read_text(encoding="utf-8"):
            changes.append(source_path)
            writes.append((path, rebuilt, True))
    for block in payloads:
        path = root / block["payload_path"]
        encoded = _static_bytes(block)
        if encoded != path.read_bytes():
            changes.append(block["payload_path"])
            writes.append((path, encoded, False))
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
    return ["zero-edit mapping document would change %s" % path for path in changes]


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
            print("[OK] %s mapping workspace: %d mappings, %d fixed pieces" % (
                args.profile, document["mapping_count"], document["piece_count"]))
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] mapping document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] mapping document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
