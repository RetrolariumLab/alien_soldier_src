#!/usr/bin/env python3
"""Round-trip fixed-capacity reachable BGM and SFX sequence instructions."""

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
from authoring.sound_envelope_model import envelope_selector_limits  # noqa: E402
from authoring.sound_pcm_model import music_sample_ids  # noqa: E402
from authoring.sound_period_references import period_contract, validate_period_references  # noqa: E402
from authoring.sound_studio_model import (  # noqa: E402
    PROFILES,
    decode_bgm_header,
    decode_reachable_sequence,
    decode_sfx_header,
    export_inventory,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
FORMAT = "fixed-capacity-reachable-smps-sequences"


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
            path = includes.get(name, owners.get(name))
            if path is None:
                raise ValueError("sound payload has no source owner: %s" % name)
            sequence = payload["sequence"]
            records.append({
                "name": name,
                "family": family,
                "path": path,
                "storage": "binary" if name in includes else "source",
                "capacity": len(body),
                "header_byte_count": payload["header_byte_count"],
                "instrument_offset": payload["instrument_offset"],
                "entry_offsets": sequence["entry_offsets"],
                "instruction_count": sequence["instruction_count"],
                "reachable_byte_count": sequence["reachable_byte_count"],
                "instructions": [
                    {
                        **instruction,
                        "data": list(body[
                            instruction["offset"]:
                            instruction["offset"] + instruction["size"]
                        ]),
                    }
                    for instruction in sequence["instructions"]
                ],
            })
    return records


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown sound-sequence profile: %s" % profile)
    payloads = _payload_records(root, profile)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": FORMAT,
        "payload_count": len(payloads),
        "instruction_count": sum(item["instruction_count"] for item in payloads),
        "reachable_byte_count": sum(item["reachable_byte_count"] for item in payloads),
        "payloads": payloads,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load sound-sequence document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("sound-sequence document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def _instruction_identity(instruction: dict[str, Any]) -> dict[str, Any]:
    return {
        key: instruction.get(key)
        for key in (
            "offset", "size", "kind", "opcode", "extension",
            "name", "flow", "target",
        )
        if key in instruction
    }


def _encoded_payload(
    record: dict[str, Any], original: dict[str, Any], body: bytes,
) -> bytes:
    result = bytearray(body)
    instructions = record.get("instructions")
    originals = original["instructions"]
    if not isinstance(instructions, list) or len(instructions) != len(originals):
        raise ValueError("%s: instruction inventory differs" % original["name"])
    for index, (instruction, source) in enumerate(zip(instructions, originals)):
        if not isinstance(instruction, dict):
            raise ValueError("%s instruction %d is not an object" % (original["name"], index))
        for field, value in _instruction_identity(source).items():
            if instruction.get(field) != value:
                raise ValueError(
                    "%s instruction $%04X changes %s"
                    % (original["name"], source["offset"], field)
                )
        values = instruction.get("data")
        if not isinstance(values, list) or len(values) != source["size"]:
            raise ValueError(
                "%s instruction $%04X changes encoded size"
                % (original["name"], source["offset"])
            )
        if any(
            not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= 0xFF
            for value in values
        ):
            raise ValueError(
                "%s instruction $%04X has a non-byte value"
                % (original["name"], source["offset"])
            )
        if source.get("opcode") == 0xF7 and values != source["data"]:
            raise ValueError("%s instruction $%04X changes a source-owned loop control operand" % (
                original["name"], source["offset"]))
        start = source["offset"]
        result[start:start + source["size"]] = bytes(values)
    return bytes(result)


def _decoded_payload(record: dict[str, Any], body: bytes) -> dict[str, Any]:
    if record["family"] == "bgm":
        return decode_bgm_header(record["name"], body)
    return decode_sfx_header(record["name"], body)


def _validate_envelope_references(
    instructions: list[dict[str, Any]], limits: dict[str, int],
) -> None:
    """Keep edited selectors inside the tables indexed by the cartridge readers."""
    for instruction in instructions:
        opcode = instruction.get("opcode")
        if opcode not in (0xF1, 0xF4, 0xF5):
            continue
        family = "psg_volume" if opcode == 0xF5 else "pitch"
        # Pitch masks the high flag bit before lookup; PSG uses the full byte.
        mask = 0xFF if family == "psg_volume" else 0x7F
        for operand_index, operand in enumerate(instruction["operands"], 1):
            selector = operand & mask
            if selector > limits[family]:
                raise ValueError(
                    "instruction $%04X operand %d selects %s envelope %d "
                    "outside 0..%d (zero disables the envelope)"
                    % (instruction["offset"], operand_index, family,
                       selector, limits[family])
                )


def _validate_dac_references(
    family: str, decoded: dict[str, Any], body: bytes, sample_ids: frozenset[int],
) -> None:
    """Constrain notes reached by the dedicated BGM DAC slot, including calls."""
    if family != "bgm" or not decoded["fm_or_dac_channel_count"]:
        return
    # Sound_LoadBGMRequest starts header channel records at SoundPCMChannelRecord.
    # Channel type $06 alone is ambiguous: the final regular FM slot also uses it.
    start = decoded["channels"][0]["sequence_offset"]
    sequence = decode_reachable_sequence(
        decoded["label"], body, [start], decoded["instrument_offset"],
        minimum_offset=decoded["header_byte_count"],
    )
    for instruction in sequence["instructions"]:
        if instruction["kind"] != "note":
            continue
        value = instruction["value"]
        if value != 0x80 and value not in sample_ids:
            raise ValueError(
                "DAC instruction $%04X selects sample $%02X outside "
                "descriptor IDs $%02X..$%02X ($80 is rest)"
                % (instruction["offset"], value, min(sample_ids), max(sample_ids))
            )


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version", "profile", "format", "payload_count",
        "instruction_count", "reachable_byte_count",
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
    limits = envelope_selector_limits(root)
    sample_ids = music_sample_ids(_bodies)
    period_source = period_contract(root, stored, _bodies)
    period_limit = period_source["word_count"]
    period_identity = tuple(period_source[key] for key in ("table", "word_count", "table_sha256", "reader_sha256"))
    for record in payloads:
        if not isinstance(record, dict):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in (
            "family", "path", "storage", "capacity", "header_byte_count",
            "instrument_offset", "entry_offsets", "instruction_count",
            "reachable_byte_count",
        ):
            if record.get(field) != original[field]:
                errors.append("%s: %s differs from the source-owned value" % (name, field))
        try:
            encoded = _encoded_payload(record, original, stored[name])
            decoded = _decoded_payload(original, encoded)
            source_instructions = original["instructions"]
            edited_instructions = decoded["sequence"]["instructions"]
            _validate_envelope_references(edited_instructions, limits)
            _validate_dac_references(original["family"], decoded, encoded, sample_ids)
            source_decoded = _decoded_payload(original, stored[name])
            validate_period_references(original["family"], source_decoded, stored[name], decoded, encoded, period_limit, period_identity)
            if len(edited_instructions) != len(source_instructions):
                raise ValueError("reachable instruction inventory changes")
            for source, edited in zip(source_instructions, edited_instructions):
                if _instruction_identity(source) != _instruction_identity(edited):
                    raise ValueError(
                        "instruction identity changes at $%04X" % source["offset"])
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
        original = originals[record["name"]]
        body = _encoded_payload(record, original, stored[record["name"]])
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
        "zero-edit sound sequences would change %s" % path
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
            print("[OK] %s sound sequences: %d payloads, %d instructions" % (
                args.profile, document["payload_count"], document["instruction_count"]))
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
