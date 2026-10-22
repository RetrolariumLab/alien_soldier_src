#!/usr/bin/env python3
"""Export, validate, and stage fixed-capacity sprite animation scripts."""

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

from authoring.object_sprite_model import (  # noqa: E402
    parse_number,
    read_animation_scripts,
    source_index,
)
from authoring.stage_tilemap_model import parsed_read_phase, with_parsed_operation  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
SYMBOL = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
WORD_LINE = re.compile(
    r"^(?P<prefix>(?:[A-Za-z_][A-Za-z0-9_]*:\s*)?\s*dc\.w\s+)"
    r"(?P<body>[^;]+?)(?P<suffix>\s*(?:;.*)?)$"
)
RELATIVE = re.compile(r"^(?P<symbol>[A-Za-z_][A-Za-z0-9_]*)-\*$")
SIGNED_POINTER_MIN = -0x8000
SIGNED_POINTER_MAX = 0x7FFF
TIMED_READER_OPERATIONS = (
    "move.w $C(a5),d0",
    "tst.b d0",
    "bmi.s Anim_ResolveTimedMappingFrame_ResolveMappingPointer",
    "beq.s Anim_ResolveTimedMappingFrame_LoadInitialTimer",
    "tst.l d3",
    "bmi.s Anim_ResolveTimedMappingFrame_TickTimer",
    "subq.w #1,d0",
    "Anim_ResolveTimedMappingFrame_TickTimer:",
    "bne.s Anim_ResolveTimedMappingFrame_StoreTimer",
    "addq.w #4,a4",
    "move.w 2(a4),d0",
    "bne.s Anim_ResolveTimedMappingFrame_StoreSequencePointer",
    "adda.w (a4),a4",
    "Anim_ResolveTimedMappingFrame_LoadInitialTimer:",
    "move.w 2(a4),d0",
    "Anim_ResolveTimedMappingFrame_StoreSequencePointer:",
    "move.l a4,8(a5)",
    "Anim_ResolveTimedMappingFrame_StoreTimer:",
    "move.w d0,$C(a5)",
    "Anim_ResolveTimedMappingFrame_ResolveMappingPointer:",
    "adda.w (a4),a4",
    "rts",
)


def relative_pointer(origin: int, target: int) -> int:
    """ADDA.W sign extends the displacement; wrapping a dc.w is not valid."""
    if (
        type(origin) is not int
        or type(target) is not int
        or not 0 <= origin < 0x200000
        or not 0 <= target < 0x200000
        or origin % 2
        or target % 2
    ):
        raise ValueError("animation pointer requires aligned proved ROM addresses")
    displacement = target - origin
    if not SIGNED_POINTER_MIN <= displacement <= SIGNED_POINTER_MAX:
        raise ValueError("animation signed16 displacement is outside -32768..32767")
    return displacement


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate animation address-evidence key: " + key)
        result[key] = value
    return result


def pointer_evidence(root: Path, profile: str, baseline: dict) -> tuple[dict, bytes, dict]:
    """Authenticate fixed-slot addresses and mapping reader shapes, read-only.

    The frozen paired ledger is a source-release artifact, not a nearest-name
    guess or a regional offset heuristic. When a preservation listing exists,
    its resolved names/flags and printed bytes must independently agree. A
    missing listing retains the frozen ledger plus exact cartridge/source-byte
    proof. Missing ROM/provenance/reader evidence makes retargeting unknown;
    unchanged source references and duration-only edits need no new pointer.
    """
    from authoring.content_workspace import checked_path
    from authoring.sprite_mapping_model import read_blocks
    from derive_profile_name_addresses import bind_listing_bytes
    from rom_profiles import load_profiles
    import verify_symbols

    def read(relative):
        path = checked_path(root, relative)
        if not path.is_file() or path.stat().st_size > 8 * 1024 * 1024:
            raise ValueError("animation address evidence is missing or oversized: " + relative)
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
        if not isinstance(value, dict):
            raise ValueError("animation address evidence must be an object: " + relative)
        return value

    profiles = load_profiles(checked_path(root, "config/rom_profiles.json"))
    audit = read("config/name_audit.json").get("records")
    if not isinstance(audit, list):
        raise ValueError("animation origin naming records must be a list")
    origin_fields = {"current_name", "address", "previous_name", "legacy_name"}
    for row in audit:
        if not isinstance(row, dict) or not origin_fields <= set(row):
            raise ValueError("animation origin naming row must be an object with identity fields")
    ledger = read("config/name_addresses_eu.json")
    rows = ledger.get("records")
    if not isinstance(rows, list):
        raise ValueError("animation frozen address records must be a list")
    if any(not isinstance(row, dict) for row in rows):
        raise ValueError("animation frozen address row must be an object")
    if (
        type(ledger.get("schema_version")) is not int
        or ledger["schema_version"] != 1
        or ledger.get("profile") != "eu"
        or ledger.get("origin_profile") != "jp"
        or ledger.get("origin_identity_fields") != list(verify_symbols.IDENTITY_FIELDS)
        or ledger.get("origin_identity_sha256") != verify_symbols.origin_identity(audit)
        or ledger.get("original_roms") != verify_symbols.original_rom_identities(profiles)
        or not isinstance(rows, list)
        or type(ledger.get("record_count")) is not int
        or ledger["record_count"] != len(audit)
        or len(rows) != len(audit)
        or ledger.get("records_sha256") != verify_symbols.canonical_sha256(rows)
    ):
        raise ValueError("animation frozen regional address evidence differs")
    origins = {row["current_name"]: verify_symbols.number(row["address"]) & 0xFFFFFF for row in audit}
    generation = ledger.get("generation")
    if not isinstance(generation, dict):
        raise ValueError("animation frozen address generation proof is missing")
    regional_proofs = generation.get("profiles")
    if not isinstance(regional_proofs, dict):
        raise ValueError("animation address generation profiles must be an object")
    for region in PROFILES:
        proof = regional_proofs.get(region)
        if not isinstance(proof, dict):
            raise ValueError("animation address generation profile proof must be an object: " + region)
        sha = profiles["profiles_by_id"][region]["reference_rom"]["sha256"]
        if (
            proof.get("resolved_flags") != verify_symbols.PROFILE_FLAGS[region]
            or proof.get("build_rom_sha256") != sha
            or proof.get("original_rom_sha256") != sha
            or type(proof.get("printed_byte_rows")) is not int
            or proof["printed_byte_rows"] < 1
            or not isinstance(proof.get("listing_sha256"), str)
            or not re.fullmatch(r"[0-9a-f]{64}", proof["listing_sha256"])
        ):
            raise ValueError("animation frozen address generation proof differs for " + region)
    addresses = {}
    seen = set()
    for row in rows:
        name = row.get("current_name")
        if not isinstance(name, str) or name in seen or name not in origins:
            raise ValueError("animation frozen address inventory has an unknown/duplicate name")
        seen.add(name)
        normal_fields = {"current_name", "jp_address", "eu_address", "status"}
        if set(row) not in (normal_fields, normal_fields | {"exclusion"}):
            raise ValueError("animation frozen address row fields differ")
        if row.get("status") == "not_assembled":
            if (
                name != verify_symbols.JP_ONLY_NAME
                or row.get("eu_address") is not None
                or row.get("jp_address") != "0x%06X" % origins[name]
            ):
                raise ValueError("animation regional unavailable-name evidence differs")
            continue
        if (
            row.get("status") != "assembled"
            or "exclusion" in row
            or any(
                not isinstance(row.get(key), str) or not re.fullmatch(r"0x[0-9A-F]{6}", row[key])
                for key in ("jp_address", "eu_address")
            )
            or int(row["jp_address"], 16) != origins[name]
        ):
            raise ValueError("animation frozen regional address pair differs: " + name)
        addresses[name] = int(row[profile + "_address"], 16)
    record = profiles["profiles_by_id"][profile]
    reference = record["reference_rom"]
    image = checked_path(root, reference["filename"]).read_bytes()
    if len(image) != reference["size"] or hashlib.sha256(image).hexdigest() != reference["sha256"]:
        raise ValueError("animation pointer evidence requires the authenticated regional original")
    names = set(baseline["frame_targets"]) | {item["name"] for item in baseline["scripts"]}
    if any(name not in addresses for name in names):
        raise ValueError("animation pointer name has no frozen regional address evidence")
    listing = checked_path(root, record["listing"])
    if listing.exists():
        flags = verify_symbols.load_profile_flags(listing)
        errors = verify_symbols.validate_profile_flags(profile, flags)
        resolved = verify_symbols.load_resolved_listing_names(listing, names)
        if errors or any(resolved.get(name) != addresses[name] for name in names):
            raise ValueError("animation preservation listing profile/addresses differ from frozen evidence")
        bind_listing_bytes(listing, image)
    reader = checked_path(root, "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
    first, last = "Anim_ResolveTimedMappingFrame:", "; End of function Anim_ResolveTimedMappingFrame"
    heads = list(re.finditer(r"^" + re.escape(first), reader, re.MULTILINE))
    if len(heads) != 1 or reader.count(last) != 1:
        raise ValueError("animation signed-word reader evidence is unknown")
    body = reader[heads[0].end() :].split(last, 1)[0]
    operations = tuple(code for line in body.splitlines() if (code := " ".join(line.split(";", 1)[0].split())))
    if operations != TIMED_READER_OPERATIONS:
        raise ValueError("animation signed-word reader contract changed")
    blocks, _skipped = read_blocks(root)
    mappings = {}
    for block in blocks:
        if block.name in mappings:
            raise ValueError("animation mapping shape has duplicate source owners")
        if block.mappings and block.mappings[0].offset == 0:
            mappings[block.name] = (block, block.mappings[0])
    return addresses, image, mappings


def _mapping_shape(name: str, evidence: tuple[dict, bytes, dict]) -> str:
    """Bind the first source mapping, including dynamic art pointers, to ROM."""
    addresses, image, mappings = evidence
    if name not in addresses or name not in mappings:
        raise ValueError("animation mapping consumer shape is unknown: " + name)
    block, mapping = mappings[name]
    if mapping.dynamic:
        encoded = bytearray()
        for piece in mapping.pieces:
            if piece.art not in addresses:
                raise ValueError("animation dynamic art address is unknown: " + piece.art)
            encoded.extend(piece.attributes.to_bytes(2, "big"))
            encoded.extend((addresses[piece.art] + (piece.size << 24) + piece.art_addend).to_bytes(4, "big"))
            encoded.extend((piece.y & 0xFF, piece.x & 0xFF))
        shape = "dynamic-eight-byte-art-pointer"
    else:
        encoded = block.data[: len(mapping.pieces) * 6]
        shape = "static-six-byte-piece"
    start = addresses[name]
    if not encoded or image[start : start + len(encoded)] != encoded:
        raise ValueError("animation mapping source bytes differ from the regional original: " + name)
    return shape


def _script_encoding(script: dict, evidence: tuple[dict, bytes, dict]) -> None:
    """Bind every four-byte original source entry before using its domain."""
    addresses, image, _mappings = evidence
    encoded = bytearray()
    for source_frame in script["frames"]:
        at = addresses[script["name"]] + source_frame["index"] * 4
        displacement = relative_pointer(at, addresses[source_frame["target"]])
        encoded.extend((displacement & 0xFFFF).to_bytes(2, "big"))
        encoded.extend(source_frame["duration"].to_bytes(2, "big"))
    start = addresses[script["name"]]
    if image[start : start + len(encoded)] != encoded:
        raise ValueError("animation source caller encoding differs from regional original")


def _script_shapes(script: dict, evidence: tuple[dict, bytes, dict]) -> frozenset[str]:
    """A jump may not change the source-owned piece-reader family mid-stream."""
    _script_encoding(script, evidence)
    shapes = frozenset(_mapping_shape(frame["target"], evidence) for frame in script["frames"] if not frame["jump"])
    if not shapes:
        raise ValueError("animation jump destination has no proved mapping consumer")
    return shapes


def pointer_domain_error(
    original: dict, frame: dict, originals: dict, evidence: tuple[dict, bytes, dict]
) -> str | None:
    """Check one changed mapping/jump against its actual signed reader domain."""
    addresses, _image, _mappings = evidence
    try:
        origin = addresses[original["name"]] + frame["index"] * 4
        relative_pointer(origin, addresses[frame["target"]])
        _script_encoding(original, evidence)
        before = original["frames"][frame["index"]]
        if frame["jump"]:
            old_script = originals[before["target"]]
            new_script = originals[frame["target"]]
            if old_script["frames"][0]["jump"] or new_script["frames"][0]["jump"]:
                raise ValueError("animation jump destination has no proved initial mapping")
            if _script_shapes(old_script, evidence) != _script_shapes(new_script, evidence):
                raise ValueError("animation target crosses static/dynamic consumer domains")
        else:
            if _mapping_shape(before["target"], evidence) != _mapping_shape(frame["target"], evidence):
                raise ValueError("animation target crosses static/dynamic consumer domains")
    except (KeyError, OverflowError, ValueError) as error:
        return str(error)
    return None


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown animation profile: %s" % profile)
    scripts = read_animation_scripts(root)
    _lines, index = source_index(root)
    records = []
    frame_targets = set()
    jumps = 0
    for name, frames in scripts.items():
        source = index[name][0].relative_to(root).as_posix()
        entries = []
        for number, frame in enumerate(frames):
            entries.append(
                {
                    "index": number,
                    "target": frame.mapping,
                    "duration": frame.duration,
                    "jump": frame.is_jump,
                }
            )
            if frame.is_jump:
                jumps += 1
            else:
                frame_targets.add(frame.mapping)
        records.append(
            {
                "name": name,
                "source_path": source,
                "frame_count": len(entries),
                "frames": entries,
            }
        )
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "relative-target-duration-word-pairs",
        "script_count": len(records),
        "frame_count": sum(record["frame_count"] for record in records),
        "jump_count": jumps,
        "frame_targets": sorted(frame_targets),
        "scripts": records,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load animation document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("animation document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def _source_value_matches(value: Any, original: Any) -> bool:
    return type(value) is type(original) and value == original


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    if type(document) is not dict:
        return ["animation document is not an object"]
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "script_count",
        "frame_count",
        "jump_count",
        "frame_targets",
    ):
        if not _source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    scripts = document.get("scripts")
    if not isinstance(scripts, list):
        return errors + ["scripts is not a list"]
    originals = {record["name"]: record for record in baseline["scripts"]}
    names = [record["name"] for record in scripts if isinstance(record, dict) and type(record.get("name")) is str]
    if len(names) != len(scripts) or len(set(names)) != len(names):
        errors.append("script names are missing or not unique")
    if set(names) != set(originals):
        errors.append("animation script inventory differs from the source")
    known_scripts = set(originals)
    known_targets = set(baseline["frame_targets"])
    evidence = None
    evidence_error = None
    evidence_checked = False
    for record in scripts:
        if not isinstance(record, dict) or type(record.get("name")) is not str:
            continue
        original = originals.get(record.get("name"))
        if original is None:
            continue
        for field in ("source_path", "frame_count"):
            if not _source_value_matches(record.get(field), original[field]):
                errors.append("%s: %s differs from the source-owned value" % (original["name"], field))
        frames = record.get("frames")
        if not isinstance(frames, list):
            errors.append("%s: frames is not a list" % original["name"])
            continue
        if len(frames) != len(original["frames"]):
            errors.append("%s: frame count differs from fixed capacity" % original["name"])
            continue
        for frame, original_frame in zip(frames, original["frames"]):
            if not isinstance(frame, dict):
                errors.append("%s: frame is not an object" % original["name"])
                continue
            number = original_frame["index"]
            if type(frame.get("index")) is not int or frame["index"] != number:
                errors.append("%s frame %d: index differs from the source" % (original["name"], number))
            if type(frame.get("jump")) is not bool or frame["jump"] != original_frame["jump"]:
                errors.append("%s frame %d: jump role differs from the source" % (original["name"], number))
            target = frame.get("target")
            duration = frame.get("duration")
            if not isinstance(target, str) or not SYMBOL.fullmatch(target):
                errors.append("%s frame %d: target is not a symbol" % (original["name"], number))
            elif frame.get("jump") and target not in known_scripts:
                errors.append("%s frame %d: jump target is not an animation script" % (original["name"], number))
            elif not frame.get("jump") and target not in known_targets:
                errors.append("%s frame %d: target is not a proved frame mapping" % (original["name"], number))
            elif (
                target != original_frame["target"]
                and type(frame.get("index")) is int
                and frame["index"] == number
                and type(frame.get("jump")) is bool
                and frame["jump"] == original_frame["jump"]
            ):
                if not evidence_checked:
                    evidence_checked = True
                    try:
                        evidence = pointer_evidence(root, profile, baseline)
                    except (OSError, ValueError, KeyError, TypeError) as error:
                        evidence_error = "unknown/non-writable pointer evidence: " + str(error)
                problem = evidence_error or pointer_domain_error(original, frame, originals, evidence)
                if problem:
                    errors.append("%s frame %d: %s" % (original["name"], number, problem))
            if type(duration) is not int or not 0 <= duration <= 0xFFFF:
                errors.append("%s frame %d: duration is not an unsigned word" % (original["name"], number))
            elif bool(duration == 0) != original_frame["jump"]:
                errors.append("%s frame %d: zero-duration jump role is source-owned" % (original["name"], number))
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def _rewrite_token(token: str, target: str | int) -> str:
    match = re.match(r"^(\s*)(.*?)(\s*)$", token)
    assert match is not None
    original = match.group(2)
    if isinstance(target, str):
        relative = RELATIVE.fullmatch(original)
        replacement = original if relative and relative.group("symbol") == target else target + "-*"
    else:
        replacement = (
            original if parse_number(original) & 0xFFFF == target else (str(target) if target < 10 else "$%X" % target)
        )
    return match.group(1) + replacement + match.group(3)


def rebuild_source(root: Path, source_path: str, scripts: list[dict[str, Any]]) -> str:
    path = root / source_path
    lines = path.read_text(encoding="utf-8").split("\n")
    wanted = {
        record["name"]: [value for frame in record["frames"] for value in (frame["target"], frame["duration"])]
        for record in scripts
    }
    locations: dict[str, list[tuple[int, re.Match[str]]]] = {}
    current = None
    for index, line in enumerate(lines):
        label = LABEL.match(line)
        if label is not None:
            current = label.group(1)
        match = WORD_LINE.match(line)
        if match is not None and current in wanted:
            locations.setdefault(current, []).append((index, match))
    missing = sorted(set(wanted) - set(locations))
    if missing:
        raise ValueError("cannot locate animation scripts: %s" % ", ".join(missing))
    output = list(lines)
    for name, spans in locations.items():
        desired = wanted[name]
        cursor = 0
        for line_index, match in spans:
            originals = match.group("body").split(",")
            values = desired[cursor : cursor + len(originals)]
            if len(values) != len(originals):
                raise ValueError("%s source has more tokens than its document" % name)
            body = ",".join(_rewrite_token(token, value) for token, value in zip(originals, values))
            output[line_index] = match.group("prefix") + body + match.group("suffix")
            cursor += len(originals)
        if cursor != len(desired):
            raise ValueError("%s source token count differs from its document" % name)
    return "\n".join(output)


def apply_document(
    document: dict[str, Any],
    root: Path,
    profile: str,
    write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    grouped: dict[str, list[dict[str, Any]]] = {}
    for record in document["scripts"]:
        grouped.setdefault(record["source_path"], []).append(record)
    changes = []
    writes = []
    for source_path, scripts in sorted(grouped.items()):
        path = root / source_path
        rebuilt = rebuild_source(root, source_path, scripts)
        if rebuilt != path.read_text(encoding="utf-8"):
            changes.append(source_path)
            writes.append((path, rebuilt))
    if write:
        for path, content in writes:
            from authoring.atomic_output import atomic_write_text as _write_text

            _write_text(path, content)
    return changes


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
        changes = apply_document(document, root, profile, write=False)
    except ValueError as error:
        return [str(error)]
    return ["zero-edit animation document would change %s" % path for path in changes]


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
                "[OK] %s animation workspace: %d scripts, %d fixed frames"
                % (args.profile, document["script_count"], document["frame_count"])
            )
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] animation document exported: %s" % args.output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] animation document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
