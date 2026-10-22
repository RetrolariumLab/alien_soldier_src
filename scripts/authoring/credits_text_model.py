#!/usr/bin/env python3
"""Model the fixed-capacity two-row animated credits text stream."""

from __future__ import annotations

import argparse
import copy
import json
import re
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.lzss_codec import decompress_as_vram  # noqa: E402
from authoring.shared_font_preview import (  # noqa: E402
    FONT_PATH as SHARED_FONT_PATH,
    GLYPH_BYTES as SHARED_GLYPH_BYTES,
)
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402
from authoring.text_document_contract import source_value_matches  # noqa: E402
from authoring.tile_graphics import TILE_BYTES, decode_tile  # noqa: E402


SCHEMA_VERSION = 2
PROFILES = ("jp", "eu")
DATA_NAME = "CreditsGlyphSequenceData"
DATA_PATH = Path("data/credits/animated_glyph_sequence.bin")
TILE_ART_NAME = "SharedFontTileArt"
SCENE_ART_NAME = "CreditsAndEndingTileArt"
TILES_PER_GLYPH = 2
TERMINATOR = 0xFF


def decoded_credits_scene_art(root: Path) -> bytes:
    """Decode the separate Xi-Tiger/ending scene art loaded at VRAM $4000."""
    data, _bodies = labelled_blocks(root)
    encoded = data.get(SCENE_ART_NAME)
    if not isinstance(encoded, bytes):
        raise ValueError("credits scene tile art is missing")
    return decompress_as_vram(encoded)


def glyph_art(root: Path) -> bytes:
    """Read the shared font actually queued for credits glyphs at VRAM $6000."""
    credits = (root / "src/credits/main.s").read_text(encoding="utf-8")
    dma = (root / "src/rendering/vdp_asset_transfers.s").read_text(encoding="utf-8")
    owner = (root / "src/data/shared_frontend_and_gameplay_tile_art.s").read_text(encoding="utf-8")
    if not re.search(r"Credits_InitXiTiger:[\s\S]*?jsr\s+\(Gfx_QueueLargeFontDMACommand81\)\.l", credits):
        raise ValueError("credits no longer queue the shared font DMA")
    if (
        not re.search(r"Gfx_QueueLargeFontDMACommand81:[\s\S]*?move\.w\s+#\$6000,-\(a1\)", dma)
        or "move.l  #SharedFontTileArt,d0" not in dma
    ):
        raise ValueError("credits shared font DMA source or VRAM destination differs")
    if not re.search(r'^SharedFontTileArt:\s+binclude\s+"data/artunc/font\.bin"', owner, re.MULTILINE):
        raise ValueError("shared font source owner differs")
    art = (root / SHARED_FONT_PATH).read_bytes()
    if not art or len(art) % SHARED_GLYPH_BYTES:
        raise ValueError("credits shared font has incomplete glyph records")
    return art


def glyph_bounds(root: Path) -> tuple[int, int]:
    count = len(glyph_art(root)) // SHARED_GLYPH_BYTES
    return count * TILES_PER_GLYPH, count - 1


def glyph_tiles_from_art(
    decoded: bytes,
    glyph_id: int,
) -> tuple[list[list[int]], list[list[int]]] | None:
    """Return the two source-order tiles for a nonblank credits glyph ID."""
    if not decoded or len(decoded) % TILE_BYTES:
        raise ValueError("credits glyph tile art has a partial tile")
    maximum = (len(decoded) // TILE_BYTES - TILES_PER_GLYPH) // TILES_PER_GLYPH
    if isinstance(glyph_id, bool) or not isinstance(glyph_id, int) or not (0 <= glyph_id <= maximum):
        raise ValueError("credits glyph ID indexes outside its art")
    if glyph_id == 0:
        return None  # The ROM skips the object for ID zero.
    start = glyph_id * TILES_PER_GLYPH * TILE_BYTES
    tiles = []
    for offset in (0, TILE_BYTES):
        pixels = decode_tile(decoded, start + offset)
        tiles.append([pixels[row * 8 : row * 8 + 8] for row in range(8)])
    return tiles[0], tiles[1]


def glyph_tiles(root: Path, glyph_id: int) -> tuple[list[list[int]], list[list[int]]] | None:
    """Preview the two shared-font source tiles used by a credits glyph."""
    return glyph_tiles_from_art(glyph_art(root), glyph_id)


def parse_stream(body: bytes, glyph_limit: int) -> tuple[list[dict[str, Any]], int, list[int]]:
    records = []
    cursor = 0
    while cursor < len(body):
        upper_delay = body[cursor]
        cursor += 1
        if upper_delay & 0x80:
            return records, upper_delay, list(body[cursor:])
        if cursor >= len(body):
            raise ValueError("credits record has no upper-row count")
        upper_count = body[cursor]
        cursor += 1
        upper_end = cursor + upper_count
        if upper_end > len(body):
            raise ValueError("credits upper row exceeds the fixed stream")
        upper = list(body[cursor:upper_end])
        cursor = upper_end
        if cursor + 2 > len(body):
            raise ValueError("credits record has no lower-row header")
        lower_delay = body[cursor]
        lower_count = body[cursor + 1]
        cursor += 2
        lower_end = cursor + lower_count
        if lower_end > len(body):
            raise ValueError("credits lower row exceeds the fixed stream")
        lower = list(body[cursor:lower_end])
        cursor = lower_end
        if any(value > glyph_limit for value in upper + lower):
            raise ValueError("credits record selects glyph tile art out of bounds")
        records.append(
            {
                "upper_delay": upper_delay,
                "upper_count": upper_count,
                "upper_glyphs": upper,
                "lower_delay": lower_delay,
                "lower_count": lower_count,
                "lower_glyphs": lower,
            }
        )
    raise ValueError("credits stream has no negative terminator")


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown credits-text profile: %s" % profile)
    body = (root / DATA_PATH).read_bytes()
    tile_count, glyph_limit = glyph_bounds(root)
    records, terminator, padding = parse_stream(body, glyph_limit)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "credits-two-row-delay-count-glyph-stream",
        "name": DATA_NAME,
        "path": DATA_PATH.as_posix(),
        "tile_art_name": TILE_ART_NAME,
        "tile_art_tile_count": tile_count,
        "tiles_per_glyph": TILES_PER_GLYPH,
        "max_glyph_id": glyph_limit,
        "record_count": len(records),
        "glyph_slot_count": sum(record["upper_count"] + record["lower_count"] for record in records),
        "encoded_byte_count": len(body),
        "terminator": terminator,
        "padding": padding,
        "records": records,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load credits-text document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("credits-text document is not an object")
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def encode_document(document: dict[str, Any]) -> bytes:
    output = bytearray()
    for record in document["records"]:
        output.extend((record["upper_delay"], record["upper_count"]))
        output.extend(record["upper_glyphs"])
        output.extend((record["lower_delay"], record["lower_count"]))
        output.extend(record["lower_glyphs"])
    output.append(document["terminator"])
    output.extend(document["padding"])
    return bytes(output)


def lower_delay_maximum(lower_count: int) -> int:
    """The byte count inherits delay*2's high byte unless its byte BEQ skips."""
    if type(lower_count) is not int or not 0 <= lower_count <= 0xFF:
        raise ValueError("credits lower count must be an exact fixed unsigned byte")
    return 0x7F if lower_count else 0xFF


def document_errors_against(document: dict[str, Any], baseline: dict[str, Any]) -> list[str]:
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "name",
        "path",
        "tile_art_name",
        "tile_art_tile_count",
        "tiles_per_glyph",
        "max_glyph_id",
        "record_count",
        "glyph_slot_count",
        "encoded_byte_count",
        "terminator",
        "padding",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("records")
    if not isinstance(records, list) or len(records) != baseline["record_count"]:
        return errors + ["record inventory differs from the source"]
    for index, (record, source) in enumerate(zip(records, baseline["records"])):
        if not isinstance(record, dict):
            errors.append("record %d is not an object" % index)
            continue
        for field in ("upper_count", "lower_count"):
            if not source_value_matches(record.get(field), source[field]):
                errors.append("record %d: %s differs" % (index, field))
        upper_delay = record.get("upper_delay")
        if not isinstance(upper_delay, int) or isinstance(upper_delay, bool) or not 0 <= upper_delay < 0x80:
            errors.append("record %d: invalid upper delay" % index)
        lower_delay = record.get("lower_delay")
        if (
            not isinstance(lower_delay, int)
            or isinstance(lower_delay, bool)
            or not 0 <= lower_delay <= lower_delay_maximum(source["lower_count"])
        ):
            errors.append("record %d: invalid lower delay" % index)
        for field, count_field in (
            ("upper_glyphs", "upper_count"),
            ("lower_glyphs", "lower_count"),
        ):
            glyphs = record.get(field)
            if not isinstance(glyphs, list) or len(glyphs) != source[count_field]:
                errors.append("record %d: %s capacity differs" % (index, field))
                continue
            if any(
                not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= baseline["max_glyph_id"]
                for value in glyphs
            ):
                errors.append("record %d: %s contains an invalid glyph" % (index, field))
    try:
        if len(encode_document(document)) != baseline["encoded_byte_count"]:
            errors.append("encoded byte count differs from the fixed capacity")
    except (KeyError, TypeError, ValueError):
        pass
    return errors


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    return document_errors_against(document, export_document(root, profile))


def migrate_document(document: dict[str, Any], root: Path, profile: str) -> dict[str, Any]:
    """Preserve every valid legacy edit while correcting the glyph-art owner."""
    current = export_document(root, profile)
    legacy = copy.deepcopy(current)
    scene_art = decoded_credits_scene_art(root)
    if len(scene_art) % TILE_BYTES or len(scene_art) // TILE_BYTES != 109:
        raise ValueError("legacy credits scene art capacity differs")
    legacy.update(
        {
            "schema_version": 1,
            "tile_art_name": SCENE_ART_NAME,
            "tile_art_tile_count": 109,
            "max_glyph_id": 53,
        }
    )
    errors = document_errors_against(document, legacy)
    if errors:
        raise ValueError("cannot migrate credits text workspace: " + "; ".join(errors))
    migrated = copy.deepcopy(document)
    for field in ("schema_version", "tile_art_name", "tile_art_tile_count", "max_glyph_id"):
        migrated[field] = current[field]
    validate_document(migrated, root, profile)
    return migrated


def migrate_path(path: Path, root: Path, profile: str) -> bool:
    document = load_document(path)
    if document.get("schema_version") == SCHEMA_VERSION:
        validate_document(document, root, profile)
        return False
    migrated = migrate_document(document, root, profile)
    backup = path.with_suffix(path.suffix + ".pre-shared-font-v1")
    if backup.exists():
        raise ValueError("credits migration backup already exists: %s" % backup)
    backup.write_bytes(path.read_bytes())
    atomic_write_json(path, migrated)
    return True


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
    body = encode_document(document)
    path = root / document["path"]
    if path.read_bytes() == body:
        return []
    if write:
        from authoring.atomic_output import atomic_write_bytes as _write_bytes

        _write_bytes(path, body)
    return [document["path"]]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "export", "validate", "migrate"))
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
                raise ValueError("zero-edit credits text would change files")
            print(
                "[OK] %s credits text: %d records, %d glyph slots"
                % (args.profile, document["record_count"], document["glyph_slot_count"])
            )
        elif args.command == "export":
            atomic_write_json(Path(args.output), export_document(root, args.profile))
        elif args.command == "migrate":
            if not args.document:
                raise ValueError("migrate requires --document")
            changed = migrate_path(Path(args.document), root, args.profile)
            print(
                "[OK] %s credits text workspace %s"
                % (args.profile, "migrated to shared font" if changed else "already current")
            )
        else:
            validate_document(load_document(Path(args.document)), root, args.profile)
        return 0
    except (KeyError, OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
