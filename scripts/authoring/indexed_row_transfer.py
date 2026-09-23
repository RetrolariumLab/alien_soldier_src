"""Replay the bounded plane-B indexed-row descriptors used by three bosses.

`Tilemap_QueueIndexedRows` copies four name words per pattern index and
stages four rows for every row group. The descriptors modelled here all start
at plane-B row 2, read 32-byte patterns from RAM $2000, and cover no more
than the 32-by-64 VDP name table. Other descriptor layouts fail closed.
"""

from __future__ import annotations


PLANE_COLUMNS = 64
PLANE_ROWS = 32
DESCRIPTOR_PREFIX = bytes.fromhex("61002000")
SOURCE_PATTERN_BYTES = 32


def descriptor_bytes(data: dict, name: str) -> bytes:
    """Read one source-owned `dc.w` or `dc.b` descriptor as physical bytes."""
    raw = data.get(name)
    if isinstance(raw, bytes):
        encoded = raw
    elif isinstance(raw, tuple) and all(
            isinstance(word, int) and 0 <= word <= 0xFFFF for word in raw):
        encoded = b"".join(word.to_bytes(2, "big") for word in raw)
    else:
        raise ValueError("indexed-row descriptor is missing: %s" % name)
    if len(encoded) < 6 or encoded[:4] != DESCRIPTOR_PREFIX:
        raise ValueError("unsupported indexed-row descriptor: %s" % name)
    groups, blocks = encoded[4] + 1, encoded[5] + 1
    if (groups * 4 > PLANE_COLUMNS or
            2 + blocks * 4 > PLANE_ROWS or
            len(encoded) < 6 + groups * blocks):
        raise ValueError("indexed-row descriptor exceeds plane or index data: %s" % name)
    return encoded


def apply_indexed_rows(
        original: list[list[int]], ram: bytes | bytearray,
        descriptor: bytes) -> tuple[tuple[int, ...], ...]:
    """Apply the source routine's writes to a caller-owned initial name table."""
    if len(original) != PLANE_ROWS or any(
            len(row) != PLANE_COLUMNS for row in original):
        raise ValueError("indexed-row initial plane must be 32 by 64 words")
    if len(ram) < 0x4000 or descriptor[:4] != DESCRIPTOR_PREFIX:
        raise ValueError("indexed-row RAM or descriptor is unsupported")
    groups, blocks = descriptor[4] + 1, descriptor[5] + 1
    if (groups * 4 > PLANE_COLUMNS or 2 + blocks * 4 > PLANE_ROWS
            or len(descriptor) < 6 + groups * blocks):
        raise ValueError("indexed-row descriptor exceeds plane or index data")
    pattern_base = int.from_bytes(descriptor[2:4], "big")
    rows = [list(row) for row in original]
    for group in range(groups):
        for column in range(4):
            for block in range(blocks):
                pattern = descriptor[6 + group + block * groups]
                address = pattern_base + pattern * SOURCE_PATTERN_BYTES + column * 2
                for part in range(4):
                    word_at = address + part * 8
                    if not 0x2000 <= word_at <= 0x3FFE:
                        raise ValueError("indexed-row pattern reads outside bounded RAM")
                    rows[2 + block * 4 + part][group * 4 + column] = (
                        int.from_bytes(ram[word_at:word_at + 2], "big"))
    return tuple(tuple(row) for row in rows)
