#!/usr/bin/env python3
"""Model the fixed-capacity frontend and results glyph-index strings."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import rebuild_source  # noqa: E402
from authoring.shared_font_preview import glyph_count  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks, parsed_read_phase, with_parsed_operation  # noqa: E402
from authoring.text_document_contract import record_names, source_value_matches  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
OWNER = "src/rendering/text_and_numbers.s"
TERMINATOR = 0xFF


def inventory(root: Path) -> dict[str, bytes]:
    data, _bodies = labelled_blocks(root)
    return {
        name: value
        for name, value in data.items()
        if name.startswith("Text_") and isinstance(value, bytes)
        and value and value[-1] == TERMINATOR
    }


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown frontend-text profile: %s" % profile)
    records = [
        {
            "name": name,
            "path": OWNER,
            "capacity": len(body),
            "terminator": TERMINATOR,
            "glyphs": list(body[:-1]),
        }
        for name, body in sorted(inventory(root).items())
    ]
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "frontend-fixed-glyph-index-strings",
        "string_count": len(records),
        "glyph_count": sum(len(record["glyphs"]) for record in records),
        "encoded_byte_count": sum(record["capacity"] for record in records),
        "strings": records,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load frontend-text document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("frontend-text document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def encoded(record: dict[str, Any]) -> bytes:
    return bytes(record["glyphs"] + [TERMINATOR])


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    maximum_glyph = glyph_count(root) - 1
    errors = []
    for field in (
        "schema_version", "profile", "format", "string_count", "glyph_count",
        "encoded_byte_count",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("strings")
    if not isinstance(records, list):
        return errors + ["strings is not a list"]
    originals = {record["name"]: record for record in baseline["strings"]}
    names = record_names(records)
    if len(names) != len(records) or len(set(names)) != len(names):
        errors.append("string names are missing or not unique")
    if set(names) != set(originals):
        errors.append("string inventory differs from the source")
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("name"), str):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in ("path", "capacity", "terminator"):
            if not source_value_matches(record.get(field), original[field]):
                errors.append("%s: %s differs from the source-owned value" % (name, field))
        glyphs = record.get("glyphs")
        if not isinstance(glyphs, list) or len(glyphs) != original["capacity"] - 1:
            errors.append("%s: glyph count differs from fixed capacity" % name)
            continue
        invalid = next(
            (index for index, value in enumerate(glyphs)
             if not isinstance(value, int) or isinstance(value, bool)
             or not 0 <= value <= maximum_glyph),
            None,
        )
        if invalid is not None:
            errors.append("%s glyph %d exceeds the shared font" % (name, invalid))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    source = inventory(root)
    changes = {
        record["name"]: encoded(record)
        for record in document["strings"]
        if source[record["name"]] != encoded(record)
    }
    if not changes:
        return []
    path = root / OWNER
    rebuilt = rebuild_source(root, OWNER, changes)
    if write:
        from authoring.atomic_output import atomic_write_text as _write_text
        _write_text(path, rebuilt)
    return [OWNER]


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return ["zero-edit frontend text would change %s" % path
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
            print("[OK] %s frontend text: %d strings, %d fixed bytes" % (
                args.profile, document["string_count"], document["encoded_byte_count"]))
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] frontend-text document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] frontend-text document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
