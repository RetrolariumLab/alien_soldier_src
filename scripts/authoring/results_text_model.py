#!/usr/bin/env python3
"""Fixed-capacity results detail rows and word-packed summary labels."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.glyph_source_list_model import (  # noqa: E402
    bytes_to_words,
    rebuild_source,
    words_to_bytes,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_read_phase, with_parsed_operation  # noqa: E402
from authoring.text_document_contract import source_value_matches  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
FORMAT = "results-fixed-detail-and-summary-glyphs"
TABLE = "data/other/results_stage_detail_text.bin"
SOURCE = "src/ui/results_data.s"
ROW_BYTES = 22
ROW_GLYPHS = ROW_BYTES - 1
TERMINATOR = 0xFF
FONT_ART = "data/artunc/font.bin"
GLYPH_BYTES = 64
SUMMARY_LABELS = (
    ("Results_TotalTimeLabel", "byte"),
    ("Results_TotalClearTimeLabel", "byte"),
    ("Results_TotalContinueLabel", "word"),
)


def source_contract(root: Path) -> None:
    source = (root / SOURCE).read_text(encoding="utf-8")
    for signature in (
        "mulu.w  #$16,d0",
        "move.w  d0,(ResultsDetailTextOffset).w",
        "lea     Results_StageDetailTextTable(pc),a0",
        "adda.w  (ResultsDetailTextOffset).w,a0",
        "jsr     (Text_QueueDoubleHeightStringWrapped).l",
        'Results_StageDetailTextTable:   binclude "' + TABLE + '"',
    ):
        if signature not in source:
            raise ValueError("results detail reader/source owner changed: %s" % signature)
    if "Results_BuildSummaryRows:" not in source:
        raise ValueError("results summary row builder is missing")
    builder = source.split("Results_BuildSummaryRows:", 1)[1].split("; End of function Results_BuildSummaryRows", 1)[0]
    if builder.count("move.w  #$15,d7") != len(SUMMARY_LABELS):
        raise ValueError("results summary label copy width changed")
    for name, _terminal_storage in SUMMARY_LABELS:
        if ("lea     " + name + "(pc),a1") not in builder:
            raise ValueError("results summary copy source changed: %s" % name)
        if ("lea     " + name + "(pc),a0") not in source:
            raise ValueError("results summary display reader changed: %s" % name)
    if "jmp     Gfx_QueueLargeFontDMACommand81" not in (root / "src/ui/results_screen.s").read_text(encoding="utf-8"):
        raise ValueError("final results no longer queues the large font")
    if "jmp     Gfx_QueueLargeFontDMACommand81" not in (root / "src/ui/post_stage_results_flow.s").read_text(
        encoding="utf-8"
    ):
        raise ValueError("post-stage results no longer queue the large font")
    font_size = (root / FONT_ART).stat().st_size
    if not font_size or font_size % GLYPH_BYTES:
        raise ValueError("shared font is not complete two-tile glyph records")


def summary_records(root: Path, maximum: int) -> list[dict[str, Any]]:
    data, bodies = labelled_blocks(root)
    records = []
    for name, terminal_storage in SUMMARY_LABELS:
        words = data.get(name)
        lines = bodies.get(name, ())
        expected = 11 if terminal_storage == "byte" else 12
        if not isinstance(words, tuple) or len(words) != expected:
            raise ValueError("results summary word capacity changed: %s" % name)
        if terminal_storage == "byte":
            if not any(line.strip() == "dc.b    $FF" for line in lines):
                raise ValueError("results summary byte terminator changed: %s" % name)
        elif words[-1] != 0xFFFF:
            raise ValueError("results summary word terminator changed: %s" % name)
        glyphs = list(words_to_bytes(words[:11]))
        if any(value > maximum for value in glyphs):
            raise ValueError("results summary glyph exceeds loaded shared font: %s" % name)
        records.append(
            {
                "name": name,
                "path": SOURCE,
                "word_capacity": expected,
                "terminator_storage": terminal_storage,
                "glyphs": glyphs,
            }
        )
    return records


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown results-text profile: %s" % profile)
    source_contract(root)
    body = (root / TABLE).read_bytes()
    if not body or len(body) % ROW_BYTES:
        raise ValueError("results detail table is not whole 22-byte rows")
    rows = [body[offset : offset + ROW_BYTES] for offset in range(0, len(body), ROW_BYTES)]
    if any(row[-1] != TERMINATOR for row in rows):
        raise ValueError("results detail row has no final $FF")
    maximum = (root / FONT_ART).stat().st_size // GLYPH_BYTES - 1
    if any(value > maximum for row in rows for value in row[:-1]):
        raise ValueError("results detail glyph exceeds loaded shared font")
    summaries = summary_records(root, maximum)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "path": TABLE,
        "row_bytes": ROW_BYTES,
        "row_count": len(rows),
        "glyph_count": len(rows) * ROW_GLYPHS,
        "encoded_byte_count": len(body),
        "max_glyph_id": maximum,
        "summary_label_count": len(summaries),
        "summary_glyph_count": sum(len(item["glyphs"]) for item in summaries),
        "summary_encoded_byte_count": sum(
            len(item["glyphs"]) + (1 if item["terminator_storage"] == "byte" else 2) for item in summaries
        ),
        "rows": [
            {"index": index, "glyphs": list(row[:-1]), "terminator": TERMINATOR} for index, row in enumerate(rows)
        ],
        "summary_labels": summaries,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load results text document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("results text document is not an object")
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def encoded(document: dict[str, Any]) -> bytes:
    return b"".join(bytes(row["glyphs"] + [TERMINATOR]) for row in document["rows"])


def encoded_summary_words(record: dict[str, Any]) -> tuple[int, ...]:
    words = bytes_to_words(bytes(record["glyphs"]))
    return words + ((0xFFFF,) if record["terminator_storage"] == "word" else ())


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "path",
        "row_bytes",
        "row_count",
        "glyph_count",
        "encoded_byte_count",
        "max_glyph_id",
        "summary_label_count",
        "summary_glyph_count",
        "summary_encoded_byte_count",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    rows = document.get("rows")
    if not isinstance(rows, list) or len(rows) != baseline["row_count"]:
        return errors + ["results detail row inventory differs"]
    for index, row in enumerate(rows):
        if not isinstance(row, dict) or not source_value_matches(row.get("index"), index):
            errors.append("results detail row %d index differs" % index)
            continue
        if not source_value_matches(row.get("terminator"), TERMINATOR):
            errors.append("results detail row %d terminator differs" % index)
        glyphs = row.get("glyphs")
        if not isinstance(glyphs, list) or len(glyphs) != ROW_GLYPHS:
            errors.append("results detail row %d capacity differs" % index)
            continue
        if any(type(value) is not int or not 0 <= value <= baseline["max_glyph_id"] for value in glyphs):
            errors.append("results detail row %d has an invalid glyph" % index)
    summaries = document.get("summary_labels")
    if not isinstance(summaries, list) or len(summaries) != len(SUMMARY_LABELS):
        return errors + ["results summary label inventory differs"]
    for index, (record, original) in enumerate(zip(summaries, baseline["summary_labels"])):
        if not isinstance(record, dict):
            errors.append("results summary label %d is not an object" % index)
            continue
        for field in ("name", "path", "word_capacity", "terminator_storage"):
            if not source_value_matches(record.get(field), original[field]):
                errors.append("results summary label %d %s differs" % (index, field))
        glyphs = record.get("glyphs")
        if not isinstance(glyphs, list) or len(glyphs) != 22:
            errors.append("results summary label %d capacity differs" % index)
        elif any(type(value) is not int or not 0 <= value <= baseline["max_glyph_id"] for value in glyphs):
            errors.append("results summary label %d has an invalid glyph" % index)
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True, validation_root: Path | None = None
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    output = encoded(document)
    path = root / TABLE
    changes = []
    if path.read_bytes() != output:
        changes.append(TABLE)
    originals = {
        record["name"]: record for record in export_document(validation_root or root, profile)["summary_labels"]
    }
    edited = [
        record for record in document["summary_labels"] if record["glyphs"] != originals[record["name"]]["glyphs"]
    ]
    word_changes = {}
    if edited:
        data, _bodies = labelled_blocks(root)
        word_changes = {
            record["name"]: encoded_summary_words(record)
            for record in edited
            if data[record["name"]] != encoded_summary_words(record)
        }
    rebuilt = rebuild_source(root, SOURCE, word_changes) if word_changes else None
    if rebuilt is not None:
        changes.append(SOURCE)
    if write and TABLE in changes:
        from authoring.atomic_output import atomic_write_bytes as _write_bytes

        _write_bytes(path, output)
    if write and rebuilt is not None:
        source_path = root / SOURCE
        from authoring.atomic_output import atomic_write_text as _write_text

        _write_text(source_path, rebuilt)
    return sorted(changes)


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    validate_document(document, root, profile)
    return [
        "zero-edit results detail would change %s" % path
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
                "[OK] %s results text: %d detail rows, %d summary labels"
                % (args.profile, document["row_count"], document["summary_label_count"])
            )
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] results detail exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] results detail document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
