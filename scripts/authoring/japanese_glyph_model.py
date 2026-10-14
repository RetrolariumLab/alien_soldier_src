#!/usr/bin/env python3
"""Round-trip the story screen's fixed Japanese glyph stream."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.tile_graphics import decode_tile  # noqa: E402
from authoring.text_document_contract import source_value_matches  # noqa: E402
from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
FORMAT = "story-japanese-glyph-word-stream"
SOURCE_PATH = "data/mappings/font_japanese.bin"
ART_PATH = "data/artunc/font_japanese.bin"
FIRST_CODE = 0x20
TERMINATOR = 0xFFFF
GLYPH_BYTES = 128


def _source(root: Path) -> tuple[list[int], int]:
    data = (root / SOURCE_PATH).read_bytes()
    art = (root / ART_PATH).read_bytes()
    if len(data) < 4 or len(data) % 2:
        raise ValueError("Japanese glyph stream is not complete words")
    if not art or len(art) % GLYPH_BYTES:
        raise ValueError("Japanese glyph art is not complete 128-byte glyphs")
    codes = [int.from_bytes(data[index:index + 2], "big") for index in range(0, len(data), 2)]
    if codes[-1] != TERMINATOR or TERMINATOR in codes[:-1]:
        raise ValueError("Japanese glyph stream has a misplaced terminator")
    art_count = len(art) // GLYPH_BYTES
    if any(not FIRST_CODE <= code < FIRST_CODE + art_count for code in codes[:-1]):
        raise ValueError("Japanese glyph stream indexes outside its art")
    return codes[:-1], art_count


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown Japanese glyph profile: %s" % profile)
    codes, art_count = _source(root)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "source_path": SOURCE_PATH,
        "art_path": ART_PATH,
        "first_code": FIRST_CODE,
        "terminator": TERMINATOR,
        "glyph_bytes": GLYPH_BYTES,
        "art_glyph_count": art_count,
        "entry_count": len(codes),
        "encoded_byte_count": (len(codes) + 1) * 2,
        "codes": codes,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load Japanese glyph document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("Japanese glyph document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    baseline = export_document(root, profile)
    for field in (
        "schema_version", "profile", "format", "source_path", "art_path",
        "first_code", "terminator", "glyph_bytes", "art_glyph_count",
        "entry_count", "encoded_byte_count",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            raise ValueError("Japanese glyph %s differs from source ownership" % field)
    codes = document.get("codes")
    if not isinstance(codes, list) or len(codes) != baseline["entry_count"]:
        raise ValueError("Japanese glyph entry count differs")
    end = FIRST_CODE + baseline["art_glyph_count"]
    if any(
        isinstance(code, bool) or not isinstance(code, int)
        or not FIRST_CODE <= code < end
        for code in codes
    ):
        raise ValueError("Japanese glyph code indexes outside its art")


def encode_document(document: dict[str, Any]) -> bytes:
    return b"".join(
        code.to_bytes(2, "big") for code in document["codes"] + [TERMINATOR]
    )


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    path = root / SOURCE_PATH
    current = path.read_bytes()
    encoded = encode_document(document)
    if len(current) != len(encoded) or current[-2:] != b"\xFF\xFF":
        raise ValueError("staged Japanese glyph stream structure differs")
    if current == encoded:
        return []
    if write:
        from authoring.atomic_output import atomic_write_bytes as _write_bytes
        _write_bytes(path, encoded)
    return [SOURCE_PATH]


def glyph_pixels(root: Path, code: int) -> list[list[int]]:
    """Rebuild the 16x16 tile order used by StoryFont_QueueIndexRows."""
    art = (root / ART_PATH).read_bytes()
    if not art or len(art) % GLYPH_BYTES:
        raise ValueError("Japanese glyph art is not complete 128-byte glyphs")
    if isinstance(code, bool) or not isinstance(code, int) or not (
        FIRST_CODE <= code < FIRST_CODE + len(art) // GLYPH_BYTES
    ):
        raise ValueError("Japanese glyph code indexes outside its art")
    start = (code - FIRST_CODE) * GLYPH_BYTES
    # DMA uploads four tiles. Top row uses even tile indices; bottom row uses
    # each even index + 1, exactly as StoryFont_QueueIndexRows constructs it.
    tiles = [decode_tile(art, start + index * 32) for index in range(4)]
    rows = []
    for y in range(16):
        left = tiles[0 if y < 8 else 1]
        right = tiles[2 if y < 8 else 3]
        row = y % 8
        rows.append(left[row * 8:row * 8 + 8] + right[row * 8:row * 8 + 8])
    return rows


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return [
        "zero-edit Japanese glyph stream would change %s" % path
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
            print("[OK] %s Japanese glyph stream: %d entries, %d art glyphs" % (
                args.profile, document["entry_count"], document["art_glyph_count"]))
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
