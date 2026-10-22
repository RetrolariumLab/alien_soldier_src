#!/usr/bin/env python3
"""Export, validate, and stage the compressed maps used by static screens."""

from __future__ import annotations

import argparse
from copy import deepcopy
import json
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import (  # noqa: E402
    source_owners,
    source_paths,
)
from authoring.lzss_codec import decompress  # noqa: E402
from authoring.screen_studio_model import (  # noqa: E402
    build_scene,
    load_config,
    screen_record,
)
from authoring.content_workspace import checked_path  # noqa: E402
from authoring.ram_map_workspace import (  # noqa: E402
    ROLE_SHAPES,
    apply_fixed_map_document,
    atomic_write_json,
    decode_values,
    document_errors_against,
    encode_values,
    encoded_slot,
    load_document,
    role_at,
)
from authoring.stage_tilemap_model import (  # noqa: E402
    RAM_BASE,
    labelled_blocks,
    read_asset_lists,
    read_descriptors,
    parsed_read_phase,
    with_parsed_operation,
)


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")


def map_uses(root: Path) -> dict[str, list[dict[str, Any]]]:
    """Derive every supported-screen interpretation of each RAM payload."""
    found: dict[str, list[dict[str, Any]]] = {}
    for record in load_config(root)["supported"]:
        scene = build_scene(root, "jp", record)
        for plane_name, tilemap in (("plane_a", scene.tilemap), ("plane_b", scene.plane_b)):
            if tilemap is None:
                continue
            for list_name, source, offset, _length in tilemap.written:
                located = role_at(tilemap.descriptor, RAM_BASE + offset)
                if located is None:
                    continue
                role, byte_offset = located
                value_bytes = ROLE_SHAPES[role]["value_bits"] // 8
                if byte_offset % value_bytes:
                    raise ValueError("%s is not aligned for %s values in %s" % (source, role, tilemap.descriptor.name))
                use = {
                    "screen": record["id"],
                    "plane": plane_name,
                    "asset_list": list_name,
                    "descriptor": tilemap.descriptor.name,
                    "destination": RAM_BASE + offset,
                    "role": role,
                    "base_value_index": byte_offset // value_bytes,
                }
                if use not in found.setdefault(source, []):
                    found[source].append(use)
    return found


def export_document(root: Path, profile: str) -> dict[str, Any]:
    with parsed_read_phase(root):
        return _export_document(root, profile)


def _export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown screen-map profile: %s" % profile)
    stored, bodies = labelled_blocks(root)
    paths = source_paths(root)
    owners = source_owners(root)
    all_lists = read_asset_lists(root, bodies)
    uses = map_uses(root)
    records = []
    for name in sorted(uses):
        raw = stored.get(name)
        if not isinstance(raw, bytes):
            raise ValueError("screen map has no compressed byte payload: %s" % name)
        ranked = sorted(
            uses[name],
            key=lambda item: (item["base_value_index"], item["role"], item["screen"]),
        )
        nearest = ranked[0]["base_value_index"]
        roles = {item["role"] for item in ranked if item["base_value_index"] == nearest}
        if len(roles) != 1:
            raise ValueError("screen map has conflicting nearest roles: %s" % name)
        role = roles.pop()
        storage = "payload" if name in paths else "source"
        path = paths.get(name, owners.get(name))
        if path is None:
            raise ValueError("screen map has no storage owner: %s" % name)
        plain = decompress(raw)
        consumers = sorted(
            list_name
            for list_name, commands in all_lists.items()
            if any(command.source == name for command in commands)
        )
        consumers = sorted(set(consumers) | {item["asset_list"] for item in uses[name]})
        shape = ROLE_SHAPES[role]
        records.append(
            {
                "name": name,
                "path": path,
                "storage": storage,
                "role": role,
                "value_bits": shape["value_bits"],
                "unit_width": shape["unit_width"],
                "unit_height": shape["unit_height"],
                "decoded_byte_count": len(plain),
                "compressed_capacity": len(raw),
                "value_count": len(plain) // (shape["value_bits"] // 8),
                "consuming_asset_lists": consumers,
                "uses": sorted(
                    uses[name],
                    key=lambda item: (item["screen"], item["plane"], item["descriptor"]),
                ),
                "values": decode_values(role, plain),
            }
        )
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "screen-ram-maps-lzss-fixed-slots",
        "payload_count": len(records),
        "value_count": sum(record["value_count"] for record in records),
        "decoded_byte_count": sum(record["decoded_byte_count"] for record in records),
        "compressed_capacity": sum(record["compressed_capacity"] for record in records),
        "payloads": records,
    }


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    return document_errors_against(document, export_document(root, profile))


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def migrate_story_plane(document: dict[str, Any], root: Path, profile: str) -> dict[str, Any]:
    """Return an explicit old-A/default to actual-B/scroll metadata migration.

    No input document, source value, edited value, capacity, or storage path is
    changed. Only the three source-proved story use records may differ from
    the current source metadata; arbitrary stale documents are not repaired.
    The caller must explicitly choose where to keep the returned document.
    """
    record = screen_record(load_config(root), "story_background")
    if record.get("plane_a") is not None or record.get("plane_b") != "Gfx_ScrollVRAMTransferParameters":
        raise ValueError("story registry has not selected the proved physical plane B")
    descriptors = read_descriptors(root)
    primary = descriptors["Gfx_DefaultVRAMTransferParameters"]
    secondary = descriptors["Gfx_ScrollVRAMTransferParameters"]
    if (
        (primary.coarse, primary.chunks, primary.patterns) != (secondary.coarse, secondary.chunks, secondary.patterns)
        or primary.plane_base != 0x4000
        or secondary.plane_base != 0x6000
    ):
        raise ValueError("story descriptor migration would change its source RAM maps")
    baseline = export_document(root, profile)
    legacy = deepcopy(baseline)
    expected = {
        "SharedMappingData7000": ("coarse", secondary.coarse),
        "StoryScreenMappingData6000": ("chunks", secondary.chunks),
        "StoryScreenMappingData4000": ("patterns", secondary.patterns),
    }
    seen = set()
    for payload in legacy["payloads"]:
        for use in payload["uses"]:
            if use["screen"] != "story_background":
                continue
            if (
                payload["name"] not in expected
                or payload["name"] in seen
                or (use["role"], use["destination"]) != expected[payload["name"]]
                or use["plane"] != "plane_b"
                or use["descriptor"] != secondary.name
                or use["asset_list"] != record["asset_list"]
                or use["base_value_index"] != 0
            ):
                raise ValueError("story source-use inventory differs from the bounded migration")
            seen.add(payload["name"])
            use["plane"], use["descriptor"] = "plane_a", primary.name
    if seen != set(expected):
        raise ValueError("story source-use inventory is incomplete for the migration")
    if not isinstance(document, dict) or set(document) != set(baseline):
        raise ValueError("story migration document fields differ from the source inventory")
    records = document.get("payloads")
    if not isinstance(records, list) or any(
        not isinstance(item, dict) or set(item) != set(baseline["payloads"][0]) for item in records
    ):
        raise ValueError("story migration payload fields differ from the source inventory")

    def metadata(candidate):
        value = deepcopy(candidate)
        for item in value["payloads"]:
            item.pop("values")
        value["payloads"].sort(key=lambda item: item["name"])
        return json.dumps(value, sort_keys=True)

    try:
        matches = metadata(document) in (metadata(baseline), metadata(legacy))
    except (KeyError, TypeError, ValueError) as error:
        raise ValueError("invalid story migration metadata") from error
    if not matches:
        raise ValueError("story migration metadata is neither the exact legacy nor current source inventory")
    errors = document_errors_against(document, baseline)
    if errors:
        legacy_errors = document_errors_against(document, legacy)
        if legacy_errors:
            raise ValueError("not an exact source-owned legacy story document: " + "; ".join(legacy_errors))
    migrated = deepcopy(document)
    originals = {item["name"]: item for item in baseline["payloads"]}
    for payload in migrated["payloads"]:
        payload["uses"] = deepcopy(originals[payload["name"]]["uses"])
    if errors := document_errors_against(migrated, baseline):
        raise ValueError("; ".join(errors))
    # Preserve legitimate user edits, but do not bless new undefined references
    # merely because replacing consumer metadata made the schema current.
    from authoring.screen_studio_state import validate_screen_map_references
    from authoring.stage_map_model import export_document as export_stage_maps

    stage = export_stage_maps(root, profile)
    validate_screen_map_references(root, profile, migrated, baseline, stage, stage)
    return migrated


def apply_document(
    document: dict[str, Any],
    root: Path,
    profile: str,
    write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    """Apply changed maps only to fixed-size slots in an isolated tree."""
    baseline = export_document(validation_root or root, profile)
    return apply_fixed_map_document(document, root, baseline, write)


@with_parsed_operation
def round_trip_errors(root: Path, profile: str) -> list[str]:
    document = export_document(root, profile)
    try:
        validate_document(document, root, profile)
    except ValueError as error:
        return [str(error)]
    return [
        "zero-edit screen-map document would change %s" % path
        for path in apply_document(document, root, profile, write=False)
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "export", "validate", "migrate-story-plane"))
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
                "[OK] %s screen maps: %d payloads, %d values, %d fixed bytes"
                % (args.profile, document["payload_count"], document["value_count"], document["compressed_capacity"])
            )
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] screen-map document exported: %s" % args.output)
        elif args.command == "migrate-story-plane":
            if not args.document or not args.output:
                raise ValueError("migrate-story-plane requires --document and --output")
            source = Path(args.document)
            relative = source.relative_to(root) if source.is_absolute() else source
            source = checked_path(root, relative)
            output = Path(args.output)
            relative = output.relative_to(root) if output.is_absolute() else output
            output = checked_path(root, relative, Path("build/content") / args.profile)
            if output.exists():
                raise ValueError("migration output already exists; choose a new generated path")
            migrated = migrate_story_plane(load_document(source), root, args.profile)
            atomic_write_json(output, migrated)
            print("[OK] story plane metadata migrated to %s; original document unchanged" % output)
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] screen-map document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
