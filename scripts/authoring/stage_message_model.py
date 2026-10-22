#!/usr/bin/env python3
"""Model the fixed-capacity interstage message sequences."""

from __future__ import annotations

import argparse
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
    source_paths,
)
from authoring.shared_font_preview import glyph_count  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402
from authoring.text_document_contract import record_names, source_value_matches  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
END_RECORD = 0xFF
END_STREAM = 0xFD
NAMES = (
    "StageTransitionMessageSequence_StageZero",
    "StageTransitionMessageSequence_Shared",
    "StageTransitionMessageSequence_TrainAndBugmax",
    "StageTransitionMessageSequence_PostFlyingNeo",
)


def parse_payload(body: bytes, name: str) -> tuple[list[list[dict[str, Any]]], list[int]]:
    sequences = []
    at = 0
    while at < len(body) and body[at] != END_RECORD:
        entries = []
        while at < len(body) and body[at] != END_STREAM:
            row = body[at]
            at += 1
            try:
                end = body.index(END_RECORD, at)
            except ValueError as error:
                raise ValueError("%s record has no $FF terminator" % name) from error
            entries.append({"row": row, "glyphs": list(body[at:end])})
            at = end + 1
        if at >= len(body):
            raise ValueError("%s has no $FD stream terminator" % name)
        sequences.append(entries)
        at += 1
    return sequences, list(body[at:])


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown stage-message profile: %s" % profile)
    data, _bodies = labelled_blocks(root)
    paths = source_paths(root)
    owners = source_owners(root)
    streams = []
    for name in NAMES:
        body = data.get(name)
        if not isinstance(body, bytes):
            raise ValueError("stage-message payload is missing: %s" % name)
        sequences, padding = parse_payload(body, name)
        streams.append(
            {
                "name": name,
                "path": paths.get(name, owners.get(name)),
                "storage": "payload" if name in paths else "source",
                "capacity": len(body),
                "sequence_count": len(sequences),
                "entry_count": sum(len(sequence) for sequence in sequences),
                "padding": padding,
                "sequences": sequences,
            }
        )
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "stage-message-row-byte-ff-records-fd-stream",
        "stream_count": len(streams),
        "entry_count": sum(item["entry_count"] for item in streams),
        "encoded_byte_count": sum(item["capacity"] for item in streams),
        "streams": streams,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load stage-message document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("stage-message document is not an object")
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def encode_stream(record: dict[str, Any]) -> bytes:
    output = bytearray()
    for sequence in record["sequences"]:
        for entry in sequence:
            output.append(entry["row"])
            output.extend(entry["glyphs"])
            output.append(END_RECORD)
        output.append(END_STREAM)
    output.extend(record["padding"])
    return bytes(output)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    maximum_glyph = glyph_count(root) - 1
    errors = []
    for field in ("schema_version", "profile", "format", "stream_count", "entry_count", "encoded_byte_count"):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("streams")
    if not isinstance(records, list):
        return errors + ["streams is not a list"]
    originals = {item["name"]: item for item in baseline["streams"]}
    names = record_names(records)
    if len(names) != len(records) or len(names) != len(set(names)) or set(names) != set(originals):
        errors.append("stream inventory differs from the source")
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("name"), str) or record["name"] not in originals:
            continue
        original = originals[record["name"]]
        for field in ("path", "storage", "capacity", "sequence_count", "entry_count", "padding"):
            if not source_value_matches(record.get(field), original[field]):
                errors.append("%s: %s differs" % (record["name"], field))
        sequences = record.get("sequences")
        if not isinstance(sequences, list) or len(sequences) != original["sequence_count"]:
            errors.append("%s: sequence inventory differs" % record["name"])
            continue
        for sequence_index, (sequence, source_sequence) in enumerate(zip(sequences, original["sequences"])):
            if not isinstance(sequence, list) or len(sequence) != len(source_sequence):
                errors.append("%s sequence %d: entry inventory differs" % (record["name"], sequence_index))
                continue
            for index, (entry, source) in enumerate(zip(sequence, source_sequence)):
                if not isinstance(entry, dict) or not source_value_matches(entry.get("row"), source["row"]):
                    errors.append("%s entry %d: row byte differs" % (record["name"], index))
                    continue
                glyphs = entry.get("glyphs")
                if not isinstance(glyphs, list) or len(glyphs) != len(source["glyphs"]):
                    errors.append("%s entry %d: glyph capacity differs" % (record["name"], index))
                    continue
                if any(
                    not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= maximum_glyph
                    for value in glyphs
                ):
                    errors.append("%s entry %d: glyph exceeds the shared font" % (record["name"], index))
        try:
            if len(encode_stream(record)) != original["capacity"]:
                errors.append("%s: encoded size differs" % record["name"])
        except (KeyError, TypeError, ValueError):
            pass
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(document, root: Path, profile: str, write=True, validation_root=None):
    validate_document(document, validation_root or root, profile)
    data, _bodies = labelled_blocks(root)
    changed = []
    source_changes = {}
    for record in document["streams"]:
        body = encode_stream(record)
        if data[record["name"]] == body:
            continue
        if record["storage"] == "source":
            source_changes.setdefault(record["path"], {})[record["name"]] = body
        else:
            changed.append(record["path"])
            if write:
                path = root / record["path"]
                from authoring.atomic_output import atomic_write_bytes as _write_bytes

                _write_bytes(path, body)
    for relative, payloads in source_changes.items():
        changed.append(relative)
        if write:
            path = root / relative
            rebuilt = rebuild_source(root, relative, payloads)
            from authoring.atomic_output import atomic_write_text as _write_text

            _write_text(path, rebuilt)
    return sorted(changed)


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
                raise ValueError("zero-edit stage messages would change files")
            print(
                "[OK] %s stage messages: %d streams, %d records"
                % (args.profile, document["stream_count"], document["entry_count"])
            )
        elif args.command == "export":
            atomic_write_json(Path(args.output), export_document(root, args.profile))
        else:
            validate_document(load_document(Path(args.document)), root, args.profile)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
