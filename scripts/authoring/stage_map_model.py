#!/usr/bin/env python3
"""Export, validate, and stage source-owned RAM maps used by levels.

This owns fixed pattern, chunk, and coarse payloads in the default streaming
descriptor, plus alternate plane-B pattern streams actually reached by a
source-derived starting viewport. Other RAM transfers are not inferred to be
maps merely because they sit in a descriptor's broad address interval.
"""

from __future__ import annotations

import argparse
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
from authoring.level_studio_model import stage_configurations  # noqa: E402
from authoring.stage_renderer import (  # noqa: E402
    not_reproduced,
    planes_for,
    signed_word,
)
from authoring.ram_map_workspace import (  # noqa: E402
    ROLE_SHAPES,
    apply_fixed_map_document,
    atomic_write_json,
    decode_values,
    document_errors_against,
    load_document,
    role_at,
)
from authoring.stage_tilemap_model import (  # noqa: E402
    PATTERN_BYTES,
    RAM_BASE,
    labelled_blocks,
    read_asset_lists,
    read_descriptors,
    read_plane_tables,
    stage_tilemaps,
    parsed_read_phase,
    with_parsed_operation,
)


SCHEMA_VERSION = 2
PROFILES = ("jp", "eu")


def map_uses(root: Path, include_plane_b: bool = True) -> dict[str, list[dict[str, Any]]]:
    """Index source-owned map transfers by every stage that plays them."""
    found: dict[str, list[dict[str, Any]]] = {}
    # Export must read the current tree: the renderer's read_once cache may
    # describe an earlier staged edit at the same path.
    read = {
        "tilemaps": stage_tilemaps(root),
        "configurations": stage_configurations(root),
        "descriptors": read_descriptors(root),
        "plane_tables": read_plane_tables(root),
        "not_reproduced": not_reproduced(root),
    }
    for index, tilemap in enumerate(read["tilemaps"]):
        for list_name, source, offset, _length in tilemap.written:
            located = role_at(tilemap.descriptor, RAM_BASE + offset)
            if located is None:
                continue
            role, byte_offset = located
            value_bytes = ROLE_SHAPES[role]["value_bits"] // 8
            if byte_offset % value_bytes:
                raise ValueError("%s is not aligned for %s values" % (source, role))
            use = {
                "stage_table_index": index,
                "asset_list": list_name,
                "destination": RAM_BASE + offset,
                "role": role,
                "base_value_index": byte_offset // value_bytes,
            }
            if use not in found.setdefault(source, []):
                found[source].append(use)
    if not include_plane_b:
        return found
    for index, configuration in enumerate(read["configurations"]):
        primary, plane = [item[0] for item in planes_for(read, index, configuration)]
        if plane is None:
            continue
        # When both drawable planes share the same maps, the default transfers
        # are already fully indexed above. Do not append redundant use metadata
        # to existing schema-2 documents. A mode-zero/unloaded primary plane
        # cannot establish this duplication: preserve B's existing use records.
        # This is provenance deduplication, not a rendering exclusion: the
        # renderer and brush still keep plane B with its independent camera.
        if primary is not None and (plane.descriptor.coarse, plane.descriptor.chunks, plane.descriptor.patterns) == (
            primary.descriptor.coarse,
            primary.descriptor.chunks,
            primary.descriptor.patterns,
        ):
            continue
        # Match scene(): the secondary map's Y offset is source-owned stage
        # configuration, not a property of the compressed payload itself.
        plane.y_offset += signed_word(configuration.camera_y) - signed_word(configuration.secondary_camera_y)
        camera_x = signed_word(configuration.secondary_camera_x)
        for screen_y in _tile_samples(plane.y_offset, 224):
            for screen_x in _tile_samples(camera_x, 320):
                x, y = camera_x + screen_x, screen_y
                if not plane.defined(x, y):
                    continue
                map_y = y + plane.y_offset
                address = (
                    plane.descriptor.patterns
                    - RAM_BASE
                    + plane.chunk_index(x, y) * PATTERN_BYTES
                    + ((map_y >> 3) & 3) * 8
                    + ((x >> 3) & 3) * 2
                )
                for list_name, source, start, length in reversed(plane.written):
                    if not start <= address or address + 2 > start + length:
                        continue
                    pattern_start = plane.descriptor.patterns - RAM_BASE
                    if start < pattern_start or (start - pattern_start) % 2 or length % 2:
                        raise ValueError("unaligned plane-B pattern source: %s" % source)
                    use = {
                        "stage_table_index": index,
                        "asset_list": list_name,
                        "destination": RAM_BASE + start,
                        "role": "patterns",
                        "base_value_index": (start - pattern_start) // 2,
                        "plane": "plane_b",
                        "descriptor": plane.descriptor.name,
                    }
                    if use not in found.setdefault(source, []):
                        found[source].append(use)
                    break
    return found


def _tile_samples(origin: int, length: int) -> tuple[int, ...]:
    """One coordinate per intersecting 8-pixel tile, including edge tiles."""
    first = (-origin) % 8
    return (0, *(position for position in range(first or 8, length, 8)))


def export_document(root: Path, profile: str, include_plane_b: bool = True) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown stage-map profile: %s" % profile)
    stored, bodies = labelled_blocks(root)
    paths = source_paths(root)
    owners = source_owners(root)
    all_lists = read_asset_lists(root, bodies)
    uses = map_uses(root, include_plane_b)
    records = []
    for name in sorted(uses):
        raw = stored.get(name)
        if not isinstance(raw, bytes):
            raise ValueError("stage map has no compressed byte payload: %s" % name)
        roles = {item["role"] for item in uses[name]}
        if len(roles) != 1:
            raise ValueError("stage map has conflicting roles: %s" % name)
        role = roles.pop()
        storage = "payload" if name in paths else "source"
        path = paths.get(name, owners.get(name))
        if path is None:
            raise ValueError("stage map has no storage owner: %s" % name)
        plain = decompress(raw)
        shape = ROLE_SHAPES[role]
        values = decode_values(role, plain)
        consumers = sorted(
            {
                list_name
                for list_name, commands in all_lists.items()
                if any(command.source == name for command in commands)
            }
        )
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
                "value_count": len(values),
                "consuming_asset_lists": consumers,
                "uses": sorted(
                    uses[name], key=lambda item: (item["stage_table_index"], item["asset_list"], item["destination"])
                ),
                "values": values,
            }
        )
    return {
        "schema_version": SCHEMA_VERSION if include_plane_b else 1,
        "profile": profile,
        "format": "stage-ram-maps-lzss-fixed-slots",
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


def migrate_document(document: dict[str, Any], root: Path, profile: str) -> dict[str, Any]:
    """Preserve every valid schema-1 edit while adding proved plane-B streams."""
    legacy = export_document(root, profile, include_plane_b=False)
    errors = document_errors_against(document, legacy)
    if errors:
        raise ValueError("cannot migrate stage-map workspace: " + "; ".join(errors))
    old = {record["name"]: record for record in document["payloads"]}
    migrated = export_document(root, profile)
    for record in migrated["payloads"]:
        if record["name"] in old:
            record["values"] = list(old[record["name"]]["values"])
    validate_document(migrated, root, profile)
    return migrated


def apply_document(
    document: dict[str, Any],
    root: Path,
    profile: str,
    write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    """Apply explicit edits to fixed slots in an isolated staged tree."""
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
        "zero-edit stage-map document would change %s" % path
        for path in apply_document(document, root, profile, write=False)
    ]


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
            with parsed_read_phase(root):
                errors = round_trip_errors(root, args.profile)
                if errors:
                    raise ValueError("; ".join(errors))
                document = export_document(root, args.profile)
            print(
                "[OK] %s stage maps: %d payloads, %d values, %d fixed bytes"
                % (args.profile, document["payload_count"], document["value_count"], document["compressed_capacity"])
            )
        elif args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            atomic_write_json(Path(args.output), export_document(root, args.profile))
            print("[OK] stage-map document exported: %s" % args.output)
        elif args.command == "migrate":
            if not args.document:
                raise ValueError("migrate requires --document")
            path = Path(args.document)
            current = load_document(path)
            if current.get("schema_version") == SCHEMA_VERSION:
                validate_document(current, root, args.profile)
                print("[OK] stage-map document is already schema %d: %s" % (SCHEMA_VERSION, path))
            else:
                migrated = migrate_document(current, root, args.profile)
                target = Path(args.output) if args.output else path
                atomic_write_json(target, migrated)
                print("[OK] stage-map document migrated to schema %d: %s" % (SCHEMA_VERSION, target))
        else:
            if not args.document:
                raise ValueError("validate requires --document")
            validate_document(load_document(Path(args.document)), root, args.profile)
            print("[OK] stage-map document is valid: %s" % args.document)
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
