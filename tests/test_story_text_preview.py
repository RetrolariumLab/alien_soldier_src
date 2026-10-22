"""The story strip is a bounded view of source tiles, not a runtime image."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.shared_font_preview import glyph_tiles  # noqa: E402
from authoring.story_text_model import export_document  # noqa: E402
from authoring.story_text_preview import (  # noqa: E402
    ROW_CELLS,
    paired_row_tiles,
    render_row_tiles,
)


class StoryTextPreviewTests(unittest.TestCase):
    def test_both_profiles_render_paired_source_tile_strips(self) -> None:
        for profile, expected in (("jp", 99), ("eu", 123)):
            with self.subTest(profile=profile):
                rows = export_document(ROOT, profile)["rows"]
                self.assertEqual(expected, len(rows))
                primary, accent = paired_row_tiles(ROOT, rows[0])
                for strip in (primary, accent):
                    self.assertEqual(16, len(strip))
                    self.assertTrue(all(len(line) == ROW_CELLS * 8 for line in strip))
                glyph = rows[0]["primary"][0]
                upper, lower = glyph_tiles(ROOT, glyph)
                self.assertEqual(upper, [line[:8] for line in primary[:8]])
                self.assertEqual(lower, [line[:8] for line in primary[8:]])

    def test_internal_accent_boundaries_remain_blank(self) -> None:
        for profile, minimum in (("jp", 1), ("eu", 2)):
            with self.subTest(profile=profile):
                rows = export_document(ROOT, profile)["rows"]
                row = next(row for row in rows if row["accent"][:-1].count(0xFF) >= minimum)
                accent = render_row_tiles(ROOT, row["accent"])
                for column, value in enumerate(row["accent"][:-1]):
                    if value == 0xFF:
                        self.assertTrue(
                            all(pixel == 0 for line in accent for pixel in line[column * 8 : (column + 1) * 8])
                        )

    def test_one_glyph_edit_only_changes_its_column(self) -> None:
        values = export_document(ROOT, "jp")["rows"][0]["primary"].copy()
        original = render_row_tiles(ROOT, values)
        glyph = values[0]
        replacement = next(
            candidate for candidate in range(228) if glyph_tiles(ROOT, candidate) != glyph_tiles(ROOT, glyph)
        )
        values[0] = replacement
        edited = render_row_tiles(ROOT, values)
        self.assertNotEqual([line[:8] for line in original], [line[:8] for line in edited])
        self.assertEqual([line[8:] for line in original], [line[8:] for line in edited])

    def test_malformed_rows_fail_closed(self) -> None:
        valid = [0] * ROW_CELLS + [0xFF]
        for values in (valid[:-1], valid[:-1] + [0], [228] + valid[1:], [True] + valid[1:]):
            with self.subTest(values=values[:2]):
                with self.assertRaises(ValueError):
                    render_row_tiles(ROOT, values)


if __name__ == "__main__":
    unittest.main()
