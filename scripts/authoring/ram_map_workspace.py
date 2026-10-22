"""Shared fixed-slot codec and conflict rules for RAM-backed map editors."""

from __future__ import annotations

import json
import struct
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from authoring.compressed_graphics_model import rebuild_source
from authoring.lzss_codec import compress, decompress
from authoring.stage_tilemap_model import (
    CHUNK_BYTES,
    COARSE_COLUMNS,
    PATTERN_BYTES,
    RAM_BASE,
    TERRAIN_COLLISION_BUFFER,
    labelled_blocks,
)


ROLE_SHAPES = {
    "patterns": {"value_bits": 16, "unit_width": 4, "unit_height": 4},
    "chunks": {"value_bits": 8, "unit_width": 8, "unit_height": 8},
    "coarse": {"value_bits": 8, "unit_width": 32, "unit_height": 32},
}
RECORD_METADATA = (
    "path",
    "storage",
    "role",
    "value_bits",
    "unit_width",
    "unit_height",
    "decoded_byte_count",
    "compressed_capacity",
    "value_count",
    "consuming_asset_lists",
    "uses",
)


@dataclass(frozen=True)
class MapHit:
    """One source-owned map value selected by a pixel on a plane."""

    payload_index: int
    value_index: int
    source: str
    role: str
    ram_address: int
    world_x: int
    world_y: int


def resolve_map_cell(plane, document: dict[str, Any], x: int, y: int, role: str) -> MapHit:
    """Trace a plane pixel through its descriptor to the last RAM writer."""
    if role not in ROLE_SHAPES:
        raise ValueError("unsupported stage-map role: %s" % role)
    if type(x) is not int or type(y) is not int:
        raise ValueError("map coordinates must be integers")
    if plane is None or not plane.defined(x, y):
        raise ValueError("plane has no defined map cell at this point")
    map_y = y + plane.y_offset
    if role == "coarse":
        offset = ((map_y >> 8) & 31) * COARSE_COLUMNS + ((x >> 8) & 31)
        base, size = plane.descriptor.coarse, 1
    elif role == "chunks":
        offset = plane.coarse_index(x, y) * CHUNK_BYTES + ((map_y >> 5) & 7) * 8 + ((x >> 5) & 7)
        base, size = plane.descriptor.chunks, 1
    else:
        offset = plane.chunk_index(x, y) * PATTERN_BYTES + ((map_y >> 3) & 3) * 8 + ((x >> 3) & 3) * 2
        base, size = plane.descriptor.patterns, 2
    address = base - RAM_BASE + offset
    records = {record["name"]: (index, record) for index, record in enumerate(document["payloads"])}
    for _list, source, start, length in reversed(plane.written):
        if start < address + size and address < start + length:
            if not start <= address or address + size > start + length:
                raise ValueError("map value crosses two RAM transfer owners")
            found = records.get(source)
            if found is None or found[1]["role"] != role:
                raise ValueError("final RAM writer is not an editable %s map" % role)
            payload_index, record = found
            within = address - start
            if within % size or within + size > record["decoded_byte_count"]:
                raise ValueError("map value is outside its source payload")
            value_index = within // size
            if value_index >= record["value_count"]:
                raise ValueError("map value index is outside its source payload")
            return MapHit(payload_index, value_index, source, role, RAM_BASE + address, x, y)
    raise ValueError("no source RAM transfer owns this map value")


def role_at(descriptor, address: int) -> tuple[str, int] | None:
    """Return the descriptor region and byte offset containing an address."""
    bases = {
        "patterns": descriptor.patterns,
        "chunks": descriptor.chunks,
        "coarse": descriptor.coarse,
    }
    ordered = sorted((*bases.values(), TERRAIN_COLLISION_BUFFER))
    for role, base in bases.items():
        limit = next((value for value in ordered if value > base), RAM_BASE + 0x10000)
        if base <= address < limit:
            return role, address - base
    return None


def decode_values(role: str, plain: bytes) -> list[int]:
    if role == "patterns":
        if len(plain) % 2:
            raise ValueError("pattern payload has an odd decoded byte count")
        return list(struct.unpack(">%dH" % (len(plain) // 2), plain))
    return list(plain)


def encode_values(record: dict[str, Any]) -> bytes:
    values = record["values"]
    if record["role"] == "patterns":
        return struct.pack(">%dH" % len(values), *values)
    return bytes(values)


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load RAM-map document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("RAM-map document is not an object: %s" % path)
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=False)


def encoded_slot(record: dict[str, Any]) -> bytes:
    encoded = compress(encode_values(record))
    capacity = record["compressed_capacity"]
    if len(encoded) > capacity:
        raise ValueError(
            "%s: recompressed size %d exceeds fixed capacity %d" % (record["name"], len(encoded), capacity)
        )
    return encoded + bytes([0xFF]) * (capacity - len(encoded))


def merged_edit_streams(
    *documents_and_baselines: tuple[dict[str, Any], dict[str, Any]],
    only_names: set[str] | None = None,
) -> dict[str, bytes]:
    """Compose Studio edits by source symbol, rejecting different shared values.

    Workstation callers validate each document against its source-owned
    baseline before previewing. This helper only resolves value edits and
    fixed-slot encoding; it does not write a file or change the baselines.
    """
    chosen: dict[str, tuple[bytes, bytes]] = {}
    for document, baseline in documents_and_baselines:
        originals = {record["name"]: record for record in baseline["payloads"]}
        for record in document["payloads"]:
            name = record["name"]
            if only_names is not None and name not in only_names:
                continue
            if record["values"] == originals[name]["values"]:
                continue
            plain = encode_values(record)
            previous = chosen.get(name)
            if previous is not None and previous[0] != plain:
                raise ValueError("conflicting map workspace edits: %s" % name)
            if previous is None:
                chosen[name] = (plain, encoded_slot(record))
    return {name: encoded for name, (_plain, encoded) in chosen.items()}


def document_errors_against(document: dict[str, Any], baseline: dict[str, Any]) -> list[str]:
    """Reject changed topology or metadata; only bounded values are editable."""
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "payload_count",
        "value_count",
        "decoded_byte_count",
        "compressed_capacity",
    ):
        if document.get(field) != baseline[field]:
            errors.append("%s differs from the source-owned value" % field)
    records = document.get("payloads")
    if not isinstance(records, list):
        return errors + ["payloads is not a list"]
    originals = {record["name"]: record for record in baseline["payloads"]}
    names = [record.get("name") for record in records if isinstance(record, dict)]
    if len(names) != len(records) or any(not isinstance(name, str) for name in names) or len(set(names)) != len(names):
        errors.append("payload names are missing or not unique")
        return errors
    if set(names) != set(originals):
        errors.append("payload inventory differs from the source")
    for record in records:
        if not isinstance(record, dict):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in RECORD_METADATA:
            if record.get(field) != original[field]:
                errors.append("%s: %s differs from the source-owned value" % (name, field))
        values = record.get("values")
        if not isinstance(values, list):
            errors.append("%s: values is not a list" % name)
            continue
        if len(values) != original["value_count"]:
            errors.append("%s: value count differs from fixed decoded capacity" % name)
            continue
        maximum = (1 << original["value_bits"]) - 1
        invalid = next(
            (
                index
                for index, value in enumerate(values)
                if not isinstance(value, int) or isinstance(value, bool) or not 0 <= value <= maximum
            ),
            None,
        )
        if invalid is not None:
            errors.append("%s value %d is not an unsigned %d-bit integer" % (name, invalid, original["value_bits"]))
            continue
        if values != original["values"]:
            try:
                encoded_slot(record)
            except (KeyError, TypeError, ValueError, struct.error) as error:
                errors.append(str(error))
    return errors


def apply_fixed_map_document(
    document: dict[str, Any],
    root: Path,
    baseline: dict[str, Any],
    write: bool = True,
) -> list[str]:
    """Apply only explicit edits, rejecting conflicting changes by another Studio."""
    errors = document_errors_against(document, baseline)
    if errors:
        raise ValueError("; ".join(errors))
    stored, _bodies = labelled_blocks(root)
    originals = {record["name"]: record for record in baseline["payloads"]}
    payload_changes: dict[str, bytes] = {}
    source_changes: dict[str, dict[str, bytes]] = {}
    for record in document["payloads"]:
        name = record["name"]
        wanted = encode_values(record)
        original = encode_values(originals[name])
        if wanted == original:
            continue
        current = decompress(stored[name])
        if current != original and current != wanted:
            raise ValueError("conflicting staged RAM-map edits: %s" % name)
        if current == wanted:
            continue
        body = encoded_slot(record)
        if record["storage"] == "source":
            source_changes.setdefault(record["path"], {})[name] = body
        else:
            payload_changes[record["path"]] = body

    # Build every replacement before writing any file, so invalid source
    # fragments cannot leave one part of the staged tree updated.
    replacements = dict(payload_changes)
    for source_path, payloads in sorted(source_changes.items()):
        rebuilt = rebuild_source(root, source_path, payloads)
        if rebuilt != (root / source_path).read_text(encoding="utf-8"):
            replacements[source_path] = rebuilt.encode("utf-8")
    if write:
        for relative, body in sorted(replacements.items()):
            path = root / relative
            from authoring.atomic_output import atomic_write_bytes as _write_bytes

            _write_bytes(path, body)
    return sorted(replacements)
