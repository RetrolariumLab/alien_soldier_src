#!/usr/bin/env python3
"""Export, validate, and stage the regional fixed-width story row streams."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.shared_font_preview import glyph_count
from authoring.text_document_contract import source_value_matches
from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation


ROW_BYTES = 34
ROW_TERMINATOR = 0xFF
STREAM_TERMINATOR = 0xFE
SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
PATHS = {
    "jp": {
        "primary": "data/other/story_text_primary_rows.bin",
        "accent": "data/other/story_text_accent_rows.bin",
    },
    "eu": {
        "primary": "data/profiles/eu/other/story_text_primary_rows.bin",
        "accent": "data/profiles/eu/other/story_text_accent_rows.bin",
    },
}


def split_rows(data: bytes, name: str) -> list[list[int]]:
    if not data or data[-1] != STREAM_TERMINATOR:
        raise ValueError("%s has no final $FE stream terminator" % name)
    body = data[:-1]
    if len(body) % ROW_BYTES:
        raise ValueError("%s is not a sequence of 34-byte rows" % name)
    rows = [list(body[offset : offset + ROW_BYTES]) for offset in range(0, len(body), ROW_BYTES)]
    if any(row[-1] != ROW_TERMINATOR for row in rows):
        raise ValueError("%s has a row without a final $FF" % name)
    return rows


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown story-text profile: %s" % profile)
    paths = PATHS[profile]
    primary = split_rows((root / paths["primary"]).read_bytes(), "primary")
    accent = split_rows((root / paths["accent"]).read_bytes(), "accent")
    if len(primary) != len(accent):
        raise ValueError("primary and accent story streams have different row counts")
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "story-paired-fixed-rows",
        "row_bytes": ROW_BYTES,
        "row_terminator": ROW_TERMINATOR,
        "stream_terminator": STREAM_TERMINATOR,
        "row_count": len(primary),
        "paths": paths,
        "rows": [
            {"index": index, "primary": first, "accent": second}
            for index, (first, second) in enumerate(zip(primary, accent))
        ],
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load story-text document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("story-text document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def stream_bytes(document: dict[str, Any], field: str) -> bytes:
    output = bytearray()
    for row in document["rows"]:
        output.extend(row[field])
    output.append(STREAM_TERMINATOR)
    return bytes(output)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    maximum_glyph = glyph_count(root) - 1
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "row_bytes",
        "row_terminator",
        "stream_terminator",
        "row_count",
        "paths",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    rows = document.get("rows")
    if not isinstance(rows, list):
        return errors + ["rows is not a list"]
    if len(rows) != baseline["row_count"]:
        errors.append("row count differs from the fixed stream")
        return errors
    for index, row in enumerate(rows):
        if not isinstance(row, dict):
            errors.append("row %d is not an object" % index)
            continue
        if not source_value_matches(row.get("index"), index):
            errors.append("row %d has a different fixed index" % index)
        for field in ("primary", "accent"):
            values = row.get(field)
            if not isinstance(values, list) or len(values) != ROW_BYTES:
                errors.append("row %d %s is not 34 bytes" % (index, field))
                continue
            invalid = next(
                (
                    offset
                    for offset, value in enumerate(values)
                    if not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= 0xFF
                ),
                None,
            )
            if invalid is not None:
                errors.append("row %d %s byte %d is not unsigned" % (index, field, invalid))
                continue
            if values[-1] != ROW_TERMINATOR:
                errors.append("row %d %s does not end in $FF" % (index, field))
            source_values = baseline["rows"][index][field]
            source_boundaries = [offset for offset, value in enumerate(source_values[:-1]) if value == ROW_TERMINATOR]
            boundaries = [offset for offset, value in enumerate(values[:-1]) if value == ROW_TERMINATOR]
            if boundaries != source_boundaries:
                errors.append("row %d %s changes fixed $FF boundaries" % (index, field))
            invalid_glyph = next(
                (
                    offset
                    for offset, value in enumerate(values[:-1])
                    if value != ROW_TERMINATOR and value > maximum_glyph
                ),
                None,
            )
            if invalid_glyph is not None:
                errors.append("row %d %s glyph %d exceeds the shared font" % (index, field, invalid_glyph))
        primary = row.get("primary")
        if isinstance(primary, list) and ROW_TERMINATOR in primary[:-1]:
            errors.append("row %d primary contains an early $FF" % index)
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any],
    root: Path,
    profile: str,
    write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    changed = []
    for field, relative in document["paths"].items():
        path = root / relative
        body = stream_bytes(document, field)
        if path.read_bytes() == body:
            continue
        changed.append(relative)
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
    return [
        "zero-edit story-text document would change %s" % path
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
            print("[OK] %s story text: %d paired fixed rows" % (args.profile, document["row_count"]))
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] story-text document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] story-text document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
