from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.shared_font_preview import (  # noqa: E402
    FONT_PATH,
    SOURCE_FONT_GLYPH_COUNT,
    glyph_count,
    glyph_tiles,
)


class SharedFontPreviewTests(unittest.TestCase):
    def test_real_font_has_228_complete_records(self) -> None:
        self.assertEqual(228, SOURCE_FONT_GLYPH_COUNT)
        self.assertEqual(SOURCE_FONT_GLYPH_COUNT, glyph_count(ROOT))
        self.assertEqual(228 * 64, (ROOT / FONT_PATH).stat().st_size)
        for index in (0, 227):
            tiles = glyph_tiles(ROOT, index)
            self.assertEqual(2, len(tiles))
            self.assertTrue(all(len(tile) == 8 for tile in tiles))
            self.assertTrue(all(len(row) == 8 for tile in tiles for row in tile))

    def test_decodes_two_source_order_tiles_without_layout_assumption(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            path = root / FONT_PATH
            path.parent.mkdir(parents=True)
            path.write_bytes(bytes([0x11]) * 32 + bytes([0x22]) * 32)
            first, second = glyph_tiles(root, 0)
            self.assertEqual([1] * 8, first[0])
            self.assertEqual([2] * 8, second[7])

    def test_rejects_out_of_bounds_or_incomplete_art(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            path = root / FONT_PATH
            path.parent.mkdir(parents=True)
            path.write_bytes(bytes(64))
            for index in (-1, 1, True, 0.5):
                with self.assertRaises(ValueError):
                    glyph_tiles(root, index)
            path.write_bytes(bytes(63))
            with self.assertRaises(ValueError):
                glyph_tiles(root, 0)
