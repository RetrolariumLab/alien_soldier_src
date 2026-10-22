"""Source-relative bounds and RAM-writer checks for tilemap editors."""

from __future__ import annotations

from array import array
from functools import lru_cache

from authoring.stage_tilemap_model import (
    CHUNK_BYTES,
    COARSE_COLUMNS,
    PATTERN_BYTES,
    RAM_BASE,
    RAM_SIZE,
)


@lru_cache(maxsize=16)
def writer_ids(written):
    """Final asset-list transfer for each RAM byte; zero means unwritten."""
    owners = array("H", [0]) * RAM_SIZE
    for index, (_list, _source, start, length) in enumerate(written, 1):
        owners[start : start + length] = array("H", [index]) * length
    return owners


def _owned(owners, address, width):
    return (
        0 <= address
        and address + width <= RAM_SIZE
        and owners[address] != 0
        and owners[address] == owners[address + width - 1]
    )


def reference_issue(plane, x, y, owners, chunk_bytes, pattern_bytes):
    """Describe an unloaded index or a read with no single RAM writer."""
    coarse = plane.coarse_index(x, y)
    if coarse * CHUNK_BYTES >= chunk_bytes:
        return "coarse index $%02X exceeds %d loaded chunks" % (coarse, chunk_bytes // CHUNK_BYTES)
    chunk = plane.chunk_index(x, y)
    if chunk * PATTERN_BYTES >= pattern_bytes:
        return "chunk index $%02X exceeds %d loaded patterns" % (chunk, pattern_bytes // PATTERN_BYTES)
    map_y = y + plane.y_offset
    addresses = (
        ("coarse", plane.descriptor.coarse - RAM_BASE + ((map_y >> 8) & 31) * COARSE_COLUMNS + ((x >> 8) & 31), 1),
        (
            "chunk",
            plane.descriptor.chunks - RAM_BASE + coarse * CHUNK_BYTES + ((map_y >> 5) & 7) * 8 + ((x >> 5) & 7),
            1,
        ),
        (
            "pattern",
            plane.descriptor.patterns - RAM_BASE + chunk * PATTERN_BYTES + ((map_y >> 3) & 3) * 8 + ((x >> 3) & 3) * 2,
            2,
        ),
    )
    for role, address, width in addresses:
        if not _owned(owners, address, width):
            return "%s RAM $%08X has no asset-list writer" % (role, RAM_BASE + address)
    return None


def _visible_samples(camera, length):
    """Visit every intersecting tile, including partial viewport edges."""
    first = (-camera) % 8
    return (0, *(position for position in range(first or 8, length, 8)))


def visible_reference_errors(baseline, candidate, record, profile, *, viewport_y=None):
    """Compare visible reads; an explicit screen lookup leaves Level semantics intact."""
    if viewport_y is not None and type(viewport_y) is not int:
        raise ValueError("visible viewport Y must be an integer")
    errors = []
    for plane_name in ("plane_a", "plane_b"):
        original = baseline.tilemap if plane_name == "plane_a" else baseline.plane_b
        changed = candidate.tilemap if plane_name == "plane_a" else candidate.plane_b
        if original is None or changed is None:
            continue
        source_owners = writer_ids(original.written)
        changed_owners = writer_ids(changed.written)
        source_chunks = original.region(original.descriptor.chunks)
        source_patterns = original.region(original.descriptor.patterns)
        changed_chunks = changed.region(changed.descriptor.chunks)
        changed_patterns = changed.region(changed.descriptor.patterns)
        camera_x = record["camera_a_x"] if plane_name == "plane_a" else baseline.parallax_x(record["camera_a_x"])
        camera_y = record["camera_a_y"][profile] if viewport_y is None else viewport_y
        for y in _visible_samples(camera_y + original.y_offset, record["height"]):
            for x in _visible_samples(camera_x, record["width"]):
                world_x, world_y = camera_x + x, camera_y + y
                if plane_name == "plane_b":
                    world_x = baseline.plane_b_source_x(world_x)
                if (
                    reference_issue(original, world_x, world_y, source_owners, source_chunks, source_patterns)
                    is not None
                ):
                    continue
                reason = reference_issue(changed, world_x, world_y, changed_owners, changed_chunks, changed_patterns)
                if reason is not None:
                    errors.append("%s %s at (%d,%d): %s" % (record["id"], plane_name, x, y, reason))
    return errors


def _pattern_masks(plane, owners):
    """Valid pattern-word positions for each possible 8-bit chunk value."""
    base = plane.descriptor.patterns - RAM_BASE
    length = plane.region(plane.descriptor.patterns)
    masks = [0] * 256
    for chunk in range(256):
        if chunk * PATTERN_BYTES >= length:
            continue
        for word in range(16):
            if _owned(owners, base + chunk * PATTERN_BYTES + word * 2, 2):
                masks[chunk] |= 1 << word
    return masks


def _chunk_value(plane, owners, coarse, position, length):
    if coarse * CHUNK_BYTES >= length:
        return None
    address = plane.descriptor.chunks - RAM_BASE + coarse * CHUNK_BYTES + position
    return plane.ram[address] if _owned(owners, address, 1) else None


def _periodic_plane_error(original, changed, plane_name, context):
    if original.descriptor != changed.descriptor or original.y_offset != changed.y_offset:
        raise ValueError("map reference comparison changed its plane descriptor")
    source_owners, changed_owners = writer_ids(original.written), writer_ids(changed.written)
    source_masks = _pattern_masks(original, source_owners)
    changed_masks = _pattern_masks(changed, changed_owners)
    source_chunks = original.region(original.descriptor.chunks)
    changed_chunks = changed.region(changed.descriptor.chunks)
    changed_patterns = changed.region(changed.descriptor.patterns)
    coarse_base = original.descriptor.coarse - RAM_BASE
    for cell in range(COARSE_COLUMNS * COARSE_COLUMNS):
        address = coarse_base + cell
        if not _owned(source_owners, address, 1):
            continue
        source_coarse = original.ram[address]
        changed_coarse = changed.ram[address] if _owned(changed_owners, address, 1) else None
        for position in range(CHUNK_BYTES):
            source_chunk = _chunk_value(original, source_owners, source_coarse, position, source_chunks)
            if source_chunk is None or not source_masks[source_chunk]:
                continue
            changed_chunk = (
                _chunk_value(changed, changed_owners, changed_coarse, position, changed_chunks)
                if changed_coarse is not None
                else None
            )
            missing = (
                source_masks[source_chunk]
                if changed_chunk is None
                else source_masks[source_chunk] & ~changed_masks[changed_chunk]
            )
            if not missing:
                continue
            word = (missing & -missing).bit_length() - 1
            x = (cell % COARSE_COLUMNS) * 256 + (position % 8) * 32 + (word % 4) * 8
            map_y = (cell // COARSE_COLUMNS) * 256 + (position // 8) * 32 + (word // 4) * 8
            y = (map_y - original.y_offset) & 0x1FFF
            reason = reference_issue(changed, x, y, changed_owners, changed_chunks, changed_patterns)
            return "%s %s at ($%04X,$%04X): %s" % (context, plane_name, x, y, reason)
    return None


def periodic_reference_error(baseline, candidate, context):
    """Find the first new invalid read in the full 8192x8192 map period."""
    for plane_name in ("plane_a", "plane_b"):
        original = baseline.tilemap if plane_name == "plane_a" else baseline.plane_b
        changed = candidate.tilemap if plane_name == "plane_a" else candidate.plane_b
        if original is None or changed is None:
            continue
        if (
            original.ram == changed.ram
            and original.written == changed.written
            and original.descriptor == changed.descriptor
            and original.y_offset == changed.y_offset
        ):
            continue
        error = _periodic_plane_error(original, changed, plane_name, context)
        if error is not None:
            return error
    return None
