#!/usr/bin/env python3
"""Source-tile strips for one paired story row, not a gameplay screenshot."""

from __future__ import annotations

from pathlib import Path

from authoring.shared_font_preview import SOURCE_FONT_GLYPH_COUNT, glyph_tiles


ROW_CELLS = 33
TILE_SIZE = 8
ROW_HEIGHT = 16
BOUNDARY = 0xFF


def render_row_tiles(root: Path, values: list[int]) -> list[list[int]]:
    """Lay out top/bottom source tiles at raw byte positions.

    The story reader queues two tile rows with glyph*2 then glyph*2+1.
    Accent run splitting, palette, scroll, and layer priority are intentionally
    not simulated here. An internal $FF leaves an empty marked column.
    """
    if len(values) != ROW_CELLS + 1 or values[-1] != BOUNDARY:
        raise ValueError("story preview needs a terminated 34-byte row")
    image = [[0] * (ROW_CELLS * TILE_SIZE) for _ in range(ROW_HEIGHT)]
    cache = {}
    for column, value in enumerate(values[:-1]):
        if isinstance(value, bool) or not isinstance(value, int):
            raise ValueError("story preview glyph is not an unsigned byte")
        if value == BOUNDARY:
            continue
        if not 0 <= value < SOURCE_FONT_GLYPH_COUNT:
            raise ValueError("story preview glyph exceeds shared font art")
        if value not in cache:
            cache[value] = glyph_tiles(root, value)
        upper, lower = cache[value]
        left = column * TILE_SIZE
        for y in range(TILE_SIZE):
            image[y][left:left + TILE_SIZE] = upper[y]
            image[y + TILE_SIZE][left:left + TILE_SIZE] = lower[y]
    return image


def paired_row_tiles(root: Path, row: dict) -> tuple[list[list[int]], list[list[int]]]:
    return render_row_tiles(root, row["primary"]), render_row_tiles(root, row["accent"])
