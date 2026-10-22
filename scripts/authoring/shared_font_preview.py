#!/usr/bin/env python3
"""Expose the two raw 8x8 tiles addressed by one shared-font index."""

from __future__ import annotations

from pathlib import Path

from authoring.tile_graphics import decode_tile


FONT_PATH = Path("data/artunc/font.bin")
GLYPH_BYTES = 64
TILE_BYTES = 32
SOURCE_FONT_GLYPH_COUNT = 228


def glyph_count(root: Path) -> int:
    art = (root / FONT_PATH).read_bytes()
    if not art or len(art) % GLYPH_BYTES:
        raise ValueError("shared font is not complete 64-byte records")
    return len(art) // GLYPH_BYTES


def glyph_tiles(root: Path, index: int) -> tuple[list[list[int]], list[list[int]]]:
    """Return source-order tiles, without asserting their on-screen placement."""
    art = (root / FONT_PATH).read_bytes()
    if not art or len(art) % GLYPH_BYTES:
        raise ValueError("shared font is not complete 64-byte records")
    count = len(art) // GLYPH_BYTES
    if isinstance(index, bool) or not isinstance(index, int) or not 0 <= index < count:
        raise ValueError("shared-font index is outside its art")
    start = index * GLYPH_BYTES
    tiles = []
    for offset in (0, TILE_BYTES):
        pixels = decode_tile(art, start + offset)
        tiles.append([pixels[row * 8 : row * 8 + 8] for row in range(8)])
    return tiles[0], tiles[1]
