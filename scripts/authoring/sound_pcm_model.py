#!/usr/bin/env python3
"""Split and round-trip the cartridge DPCM banks through their headers."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import source_paths  # noqa: E402
from authoring.sound_pcm_codec import codec_contract  # noqa: E402
from authoring.sound_studio_model import PROFILES  # noqa: E402
from authoring.stage_tilemap_model import (  # noqa: E402
    labelled_blocks, parse_number, parsed_read_phase, with_parsed_operation)


SCHEMA_VERSION = 1
FORMAT = "treasure-dpcm-headered-banks"
WORD_DIRECTIVE = re.compile(r"\bdc\.w\s+([^;]+)", re.IGNORECASE)
BANK_EXPRESSION = re.compile(
    r"^\(Sound_PCMBank([1-9])\s*>>\s*\$8\)$")
DESCRIPTOR_TABLES = (
    {
        "id": "music",
        "label": "Sound_PCMSampleDescriptors",
        "reader": "Sound_ProcessPCMSequence",
        "first_id": 0x81,
        "dispatchable_count": 22,
    },
    {
        "id": "voice",
        "label": "Sound_VoiceDACDescriptors",
        "reader": "Sound_ProcessVoiceDACRequest",
        "first_id": 0x10,
        "dispatchable_count": 47,
    },
)


def _u16le(data: bytes) -> int:
    return int.from_bytes(data, "little")


def _header_offset(word: int) -> int:
    """Mirror the byte loads in Sound_ReadDACSampleHeader."""
    return (((word & 0xFF) << 8) | (word >> 8)) & 0x7FFF


def _parse_bank(label: str, path: str, body: bytes) -> dict[str, Any]:
    if len(body) < 4:
        raise ValueError("%s is too short for a DPCM header" % label)
    header_bytes = _u16le(body[:2]) & 0x7FFF
    if header_bytes == 0 or header_bytes % 4 or header_bytes > len(body):
        raise ValueError("%s has invalid first-sample offset $%04X" % (label, header_bytes))
    samples = []
    cursor = header_bytes
    for index, header_offset in enumerate(range(0, header_bytes, 4)):
        start_word = _u16le(body[header_offset:header_offset + 2])
        start = start_word & 0x7FFF
        byte_count = _u16le(body[header_offset + 2:header_offset + 4])
        if start != cursor:
            raise ValueError(
                "%s sample %d starts at $%04X after $%04X" % (
                    label, index, start, cursor))
        end = start + byte_count
        if end > len(body):
            raise ValueError("%s sample %d leaves its bank" % (label, index))
        samples.append({
            "index": index,
            "header_offset": header_offset,
            "start_word": start_word,
            "start_offset": start,
            "byte_count": byte_count,
            "data": body[start:end].hex().upper(),
            "consumers": [],
        })
        cursor = end
    padding = body[cursor:]
    return {
        "name": label,
        "path": path,
        "capacity": len(body),
        "header_byte_count": header_bytes,
        "sample_count": len(samples),
        "sample_byte_count": sum(item["byte_count"] for item in samples),
        "padding_byte_count": len(padding),
        "padding_sha256": hashlib.sha256(padding).hexdigest(),
        "samples": samples,
    }


def _word_tokens(lines: tuple[str, ...], label: str) -> list[str]:
    tokens = []
    for line in lines:
        match = WORD_DIRECTIVE.search(line)
        if match is not None:
            tokens.extend(item.strip() for item in match.group(1).split(","))
    if not tokens or len(tokens) % 4:
        raise ValueError("%s is not a table of four-word descriptors" % label)
    return tokens


def music_sample_ids(bodies: dict[str, tuple[str, ...]]) -> frozenset[int]:
    """IDs addressable inside the source-owned ordinary DAC descriptor table."""
    definition = next(item for item in DESCRIPTOR_TABLES if item["id"] == "music")
    label = definition["label"]
    count = len(_word_tokens(bodies[label], label)) // 4
    first = definition["first_id"]
    return frozenset(range(first, first + count))


def _descriptor_table(
    bodies: dict[str, tuple[str, ...]], definition: dict[str, Any],
    banks: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    tokens = _word_tokens(bodies[definition["label"]], definition["label"])
    records = []
    for index in range(0, len(tokens), 4):
        fields = tokens[index:index + 4]
        bank_match = BANK_EXPRESSION.fullmatch(fields[0])
        if bank_match is None:
            raise ValueError("%s descriptor has an invalid bank expression" % definition["label"])
        bank_name = "Sound_PCMBank%s" % bank_match.group(1)
        words = [parse_number(field) & 0xFFFF for field in fields[1:]]
        header_offset = _header_offset(words[0])
        if header_offset % 4:
            raise ValueError("%s descriptor header offset is not four-byte aligned" % definition["label"])
        sample_index = header_offset // 4
        if bank_name not in banks or sample_index >= banks[bank_name]["sample_count"]:
            raise ValueError("%s descriptor leaves %s headers" % (definition["label"], bank_name))
        record_index = index // 4
        records.append({
            "id": definition["first_id"] + record_index,
            "dispatchable": record_index < definition["dispatchable_count"],
            "bank": bank_name,
            "header_offset": header_offset,
            "sample_index": sample_index,
            "descriptor_words": words,
        })
    if definition["dispatchable_count"] > len(records):
        raise ValueError("%s has fewer records than its reader accepts" % definition["label"])
    return {
        "id": definition["id"],
        "label": definition["label"],
        "reader": definition["reader"],
        "first_id": definition["first_id"],
        "record_count": len(records),
        "dispatchable_count": definition["dispatchable_count"],
        "records": records,
    }


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown sound-PCM profile: %s" % profile)
    stored, bodies = labelled_blocks(root)
    paths = source_paths(root)
    bank_list = []
    for index in range(1, 10):
        label = "Sound_PCMBank%d" % index
        body = stored.get(label)
        path = paths.get(label)
        if not isinstance(body, bytes) or path is None:
            raise ValueError("PCM bank source is missing: %s" % label)
        bank_list.append(_parse_bank(label, path, body))
    banks = {item["name"]: item for item in bank_list}
    tables = [_descriptor_table(bodies, item, banks) for item in DESCRIPTOR_TABLES]
    for table in tables:
        for record in table["records"]:
            consumer = {
                "table": table["id"],
                "id": record["id"],
                "dispatchable": record["dispatchable"],
            }
            banks[record["bank"]]["samples"][record["sample_index"]]["consumers"].append(consumer)
    referenced = sum(
        bool([consumer for consumer in sample["consumers"] if consumer["dispatchable"]])
        for bank in bank_list for sample in bank["samples"]
    )
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "codec": codec_contract(root),
        "bank_count": len(bank_list),
        "sample_count": sum(item["sample_count"] for item in bank_list),
        "sample_byte_count": sum(item["sample_byte_count"] for item in bank_list),
        "decoded_value_count": sum(item["sample_byte_count"] for item in bank_list) * 2,
        "header_byte_count": sum(item["header_byte_count"] for item in bank_list),
        "padding_byte_count": sum(item["padding_byte_count"] for item in bank_list),
        "descriptor_record_count": sum(item["record_count"] for item in tables),
        "dispatchable_descriptor_count": sum(item["dispatchable_count"] for item in tables),
        "referenced_sample_count": referenced,
        "unreferenced_sample_count": sum(item["sample_count"] for item in bank_list) - referenced,
        "descriptor_tables": tables,
        "banks": bank_list,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load sound-PCM document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("sound-PCM document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def _sample_bytes(sample: dict[str, Any], original: dict[str, Any], bank: str) -> bytes:
    for field in (
        "index", "header_offset", "start_word", "start_offset", "byte_count", "consumers",
    ):
        if sample.get(field) != original[field]:
            raise ValueError("%s sample %d changes %s" % (bank, original["index"], field))
    value = sample.get("data")
    if not isinstance(value, str) or len(value) != original["byte_count"] * 2:
        raise ValueError("%s sample %d has invalid encoded length" % (bank, original["index"]))
    try:
        result = bytes.fromhex(value)
    except ValueError as error:
        raise ValueError("%s sample %d is not hexadecimal" % (bank, original["index"])) from error
    if len(result) != original["byte_count"]:
        raise ValueError("%s sample %d has invalid encoded data" % (bank, original["index"]))
    return result


def _bank_bytes(
    record: dict[str, Any], original: dict[str, Any], current: bytes,
    authority: bytes,
) -> bytes:
    for field in (
        "name", "path", "capacity", "header_byte_count", "sample_count",
        "sample_byte_count", "padding_byte_count", "padding_sha256",
    ):
        if record.get(field) != original[field]:
            raise ValueError("%s: %s differs from the source-owned value" % (original["name"], field))
    samples = record.get("samples")
    expected = original["samples"]
    if not isinstance(samples, list) or len(samples) != len(expected):
        raise ValueError("%s: sample inventory differs" % original["name"])
    header_end = original["header_byte_count"]
    sample_end = header_end + original["sample_byte_count"]
    if len(current) != len(authority):
        raise ValueError("%s staged capacity differs" % original["name"])
    if current[:header_end] != authority[:header_end]:
        raise ValueError("%s staged headers differ" % original["name"])
    if current[sample_end:] != authority[sample_end:]:
        raise ValueError("%s staged padding differs" % original["name"])
    result = bytearray(current)
    for sample, baseline in zip(samples, expected):
        data = _sample_bytes(sample, baseline, original["name"])
        start = baseline["start_offset"]
        result[start:start + len(data)] = data
    return bytes(result)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "codec", "bank_count", "sample_count",
        "sample_byte_count", "decoded_value_count", "header_byte_count", "padding_byte_count",
        "descriptor_record_count", "dispatchable_descriptor_count",
        "referenced_sample_count", "unreferenced_sample_count", "descriptor_tables",
    ):
        if document.get(field) != baseline[field]:
            errors.append("%s differs from the source-owned value" % field)
    banks = document.get("banks")
    if not isinstance(banks, list):
        return errors + ["banks is not a list"]
    originals = {item["name"]: item for item in baseline["banks"]}
    names = [item.get("name") for item in banks if isinstance(item, dict)]
    if len(names) != len(banks) or len(set(names)) != len(names) or set(names) != set(originals):
        errors.append("bank inventory differs from the source")
    stored, _bodies = labelled_blocks(root)
    for bank in banks:
        if not isinstance(bank, dict) or bank.get("name") not in originals:
            continue
        original = originals[bank["name"]]
        try:
            _bank_bytes(bank, original, stored[bank["name"]], stored[bank["name"]])
        except (KeyError, TypeError, ValueError) as error:
            errors.append(str(error))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any], root: Path, profile: str, write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    authority_root = validation_root or root
    validate_document(document, authority_root, profile)
    baseline = export_document(authority_root, profile)
    originals = {item["name"]: item for item in baseline["banks"]}
    current, _bodies = labelled_blocks(root)
    authority, _authority_bodies = labelled_blocks(authority_root)
    changed = []
    for bank in document["banks"]:
        name = bank["name"]
        rebuilt = _bank_bytes(bank, originals[name], current[name], authority[name])
        if rebuilt == current[name]:
            continue
        changed.append(bank["path"])
        if write:
            path = root / bank["path"]
            from authoring.atomic_output import atomic_write_bytes as _write_bytes
            _write_bytes(path, rebuilt)
    return sorted(changed)


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return [
        "zero-edit PCM samples would change %s" % path
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
            print("[OK] %s PCM samples: %d banks, %d samples, %d bytes" % (
                args.profile, document["bank_count"], document["sample_count"],
                document["sample_byte_count"]))
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
