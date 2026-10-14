#!/usr/bin/env python3
"""Round-trip the 25-byte FM instrument records owned by sound payloads."""

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
from authoring.sound_studio_model import (  # noqa: E402
    FM_INSTRUMENT_BYTES,
    PROFILES,
    export_inventory,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
FORMAT = "treasure-smps-25-byte-fm-instruments"
PARAMETER_FIELDS = (
    "detune_multiplier",
    "rate_scale_attack",
    "am_decay",
    "sustain_rate",
    "sustain_level_release",
    "total_level",
)


def decode_instrument(index: int, body: bytes) -> dict[str, Any]:
    if len(body) != FM_INSTRUMENT_BYTES:
        raise ValueError("FM instrument %d is not 25 bytes" % index)
    cursor = 1
    record: dict[str, Any] = {
        "index": index,
        "algorithm_feedback": body[0],
    }
    for field in PARAMETER_FIELDS:
        record[field] = list(body[cursor:cursor + 4])
        cursor += 4
    return record


def encode_instrument(record: dict[str, Any]) -> bytes:
    values = [record["algorithm_feedback"]]
    for field in PARAMETER_FIELDS:
        values.extend(record[field])
    return bytes(values)


def _payload_records(root: Path, profile: str) -> list[dict[str, Any]]:
    inventory = export_inventory(root, profile)
    owners = source_owners(root)
    includes = source_paths(root)
    data, _bodies = labelled_blocks(root)
    records = []
    for family, payloads in (
        ("bgm", inventory["bgm_payloads"]),
        ("sfx", inventory["sfx_payloads"]),
    ):
        for payload in payloads:
            name = payload["label"]
            body = data[name]
            start = payload["instrument_offset"]
            count = (len(body) - start) // FM_INSTRUMENT_BYTES
            end = start + count * FM_INSTRUMENT_BYTES
            overlaps = [
                instruction["offset"]
                for instruction in payload["sequence"]["instructions"]
                if instruction["offset"] < end
                and instruction["offset"] + instruction["size"] > start
            ]
            if overlaps:
                raise ValueError(
                    "%s reachable sequence overlaps its instrument table at $%04X"
                    % (name, overlaps[0])
                )
            path = includes.get(name, owners.get(name))
            if path is None:
                raise ValueError("sound payload has no source owner: %s" % name)
            records.append({
                "name": name,
                "family": family,
                "path": path,
                "storage": "binary" if name in includes else "source",
                "capacity": len(body),
                "instrument_offset": start,
                "instrument_count": count,
                "trailing_padding": list(body[end:]),
                "instruments": [
                    decode_instrument(
                        index,
                        body[
                            start + index * FM_INSTRUMENT_BYTES:
                            start + (index + 1) * FM_INSTRUMENT_BYTES
                        ],
                    )
                    for index in range(count)
                ],
            })
    return records


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown sound-instrument profile: %s" % profile)
    payloads = _payload_records(root, profile)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "payload_count": len(payloads),
        "instrument_count": sum(item["instrument_count"] for item in payloads),
        "parameter_byte_count": sum(
            item["instrument_count"] * FM_INSTRUMENT_BYTES for item in payloads),
        "padding_byte_count": sum(len(item["trailing_padding"]) for item in payloads),
        "payloads": payloads,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load sound-instrument document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("sound-instrument document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def _record_bytes(record: dict[str, Any], original: dict[str, Any], body: bytes) -> bytes:
    instruments = record.get("instruments")
    originals = original["instruments"]
    if not isinstance(instruments, list) or len(instruments) != len(originals):
        raise ValueError("%s: instrument inventory differs" % original["name"])
    result = bytearray(body)
    start = original["instrument_offset"]
    for index, (instrument, source) in enumerate(zip(instruments, originals)):
        if not isinstance(instrument, dict) or instrument.get("index") != source["index"]:
            raise ValueError("%s instrument %d changes identity" % (original["name"], index))
        algorithm = instrument.get("algorithm_feedback")
        if not isinstance(algorithm, int) or isinstance(algorithm, bool) or not 0 <= algorithm <= 0xFF:
            raise ValueError("%s instrument %d has invalid algorithm/feedback" % (
                original["name"], index))
        for field in PARAMETER_FIELDS:
            values = instrument.get(field)
            if not isinstance(values, list) or len(values) != 4 or any(
                not isinstance(value, int) or isinstance(value, bool)
                or not 0 <= value <= 0xFF for value in values
            ):
                raise ValueError("%s instrument %d has invalid %s" % (
                    original["name"], index, field))
        encoded = encode_instrument(instrument)
        offset = start + index * FM_INSTRUMENT_BYTES
        result[offset:offset + FM_INSTRUMENT_BYTES] = encoded
    return bytes(result)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "payload_count", "instrument_count",
        "parameter_byte_count", "padding_byte_count",
    ):
        if document.get(field) != baseline[field]:
            errors.append("%s differs from the source-owned value" % field)
    payloads = document.get("payloads")
    if not isinstance(payloads, list):
        return errors + ["payloads is not a list"]
    originals = {item["name"]: item for item in baseline["payloads"]}
    names = [item.get("name") for item in payloads if isinstance(item, dict)]
    if len(names) != len(payloads) or len(set(names)) != len(names):
        errors.append("payload names are missing or not unique")
    if set(names) != set(originals):
        errors.append("payload inventory differs from the source")
    stored, _bodies = labelled_blocks(root)
    for record in payloads:
        if not isinstance(record, dict):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in (
            "family", "path", "storage", "capacity", "instrument_offset",
            "instrument_count", "trailing_padding",
        ):
            if record.get(field) != original[field]:
                errors.append("%s: %s differs from the source-owned value" % (name, field))
        try:
            _record_bytes(record, original, stored[name])
        except (KeyError, TypeError, ValueError) as error:
            errors.append("%s: %s" % (name, error))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    authority = validation_root or root
    validate_document(document, authority, profile)
    baseline = export_document(authority, profile)
    originals = {item["name"]: item for item in baseline["payloads"]}
    stored, _bodies = labelled_blocks(root)
    changed = []
    source_changes: dict[str, dict[str, bytes]] = {}
    for record in document["payloads"]:
        body = _record_bytes(record, originals[record["name"]], stored[record["name"]])
        if body == stored[record["name"]]:
            continue
        if record["storage"] == "source":
            source_changes.setdefault(record["path"], {})[record["name"]] = body
            continue
        changed.append(record["path"])
        if write:
            path = root / record["path"]
            from authoring.atomic_output import atomic_write_bytes as _write_bytes
            _write_bytes(path, body)
    for relative, replacements in sorted(source_changes.items()):
        path = root / relative
        rebuilt = rebuild_source(root, relative, replacements)
        if rebuilt == path.read_text(encoding="utf-8"):
            continue
        changed.append(relative)
        if write:
            from authoring.atomic_output import atomic_write_text as _write_text
            _write_text(path, rebuilt)
    return sorted(changed)


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return [
        "zero-edit sound instruments would change %s" % path
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
            print("[OK] %s FM instruments: %d records, %d parameter bytes" % (
                args.profile, document["instrument_count"],
                document["parameter_byte_count"]))
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
