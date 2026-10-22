"""Small source-palette and bounded sequence tests without ROM or a GUI."""

from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.text_glyph_picker import (  # noqa: E402
    CELL_HEIGHT,
    CELL_WIDTH,
    COLUMNS,
    ROWS,
    GlyphPicker,
    GlyphRange,
    source_pixels,
)
from authoring.text_studio import Window  # noqa: E402
from authoring.text_studio_state import Workspace  # noqa: E402


def documents():
    return {
        "frontend_text_strings": {"strings": [{"name": "sample", "glyphs": [0, 127, 227]}]},
        "japanese_glyph_sequence": {"first_code": 0x20, "art_glyph_count": 295, "codes": [0x20] * 986 + [0x146]},
        "credits_text_sequence": {
            "max_glyph_id": 227,
            "records": [
                {
                    "upper_delay": 2,
                    "upper_count": 2,
                    "upper_glyphs": [23, 0],
                    "lower_delay": 5,
                    "lower_count": 1,
                    "lower_glyphs": [227],
                }
            ],
        },
        "story_text_rows": {
            "rows": [
                {
                    "index": 0,
                    "primary": [0] * 33 + [0xFF],
                    "accent": [1, 0xFF] + [0] * 31 + [0xFF],
                }
            ]
        },
    }


class GlyphRangeTests(unittest.TestCase):
    def test_font_pages_have_exact_source_ranges(self):
        for font, sizes in (
            (GlyphRange("shared", 0, 227), (64, 64, 64, 36)),
            (GlyphRange("japanese", 0x20, 0x146), (64, 64, 64, 64, 39)),
        ):
            with self.subTest(family=font.family):
                pages = [list(font.values(page)) for page in range(font.page_count)]
                self.assertEqual(sizes, tuple(map(len, pages)))
                self.assertEqual(
                    list(range(font.minimum, font.maximum + 1)), [value for page in pages for value in page]
                )
                for page, values in enumerate(pages):
                    self.assertTrue(all(font.page_for(value) == page for value in values))
                for value in (True, float(font.minimum), font.minimum - 1, font.maximum + 1):
                    with self.assertRaises(ValueError):
                        font.page_for(value)

    def test_blank_final_cells_and_canvas_edges_are_inert(self):
        font = GlyphRange("shared", 0, 227)
        self.assertEqual(192, font.value_at(3, 0, 0))
        self.assertEqual(227, font.value_at(3, 3 * CELL_WIDTH + 1, 2 * CELL_HEIGHT + 1))
        for x, y in (
            (4 * CELL_WIDTH, 2 * CELL_HEIGHT),
            (-1, 0),
            (0, -1),
            (COLUMNS * CELL_WIDTH, 0),
            (0, ROWS * CELL_HEIGHT),
        ):
            self.assertIsNone(font.value_at(3, x, y))

    def test_shared_tiles_remain_in_source_order_and_separated(self):
        tiles = ([[1] * 8 for _ in range(8)], [[2] * 8 for _ in range(8)])
        with mock.patch("authoring.text_glyph_picker.glyph_tiles", return_value=tiles):
            self.assertEqual([[1] * 8 + [0] + [2] * 8] * 8, source_pixels(ROOT, "shared", 4))
        with mock.patch("authoring.text_glyph_picker.credits_glyph_tiles", return_value=None):
            self.assertEqual([[0] * 17] * 8, source_pixels(ROOT, "credits", 0))
        with mock.patch("authoring.text_glyph_picker.glyph_pixels", return_value=[[3]]) as pixels:
            self.assertEqual([[3]], source_pixels(ROOT, "japanese", 0x146))
            pixels.assert_called_once_with(ROOT, 0x146)


class GlyphEditingTests(unittest.TestCase):
    def setUp(self):
        self.state = Workspace(documents())

    def test_credits_fixture_counts_match_fixed_glyph_slots_and_safe_delay_bounds(self):
        self.state.select_artifact("credits_text_sequence")
        record = self.state.documents["credits_text_sequence"]["records"][0]
        self.assertEqual(record["upper_count"], len(record["upper_glyphs"]))
        self.assertEqual(record["lower_count"], len(record["lower_glyphs"]))
        self.state.select_field(2)
        self.assertEqual((0, 0x7F), (self.state.field.minimum, self.state.field.maximum))

    def test_picker_replaces_only_the_selected_slot(self):
        for artifact, field, index, replacement, family in (
            ("frontend_text_strings", 0, 1, 227, "shared"),
            ("japanese_glyph_sequence", 0, 986, 0x20, "japanese"),
            ("credits_text_sequence", 1, 0, 0, "credits"),
            ("story_text_rows", 1, 0, 227, "shared"),
        ):
            with self.subTest(artifact=artifact):
                state = Workspace(documents())
                state.select_artifact(artifact)
                state.select_field(field)
                state.select_value(index)
                expected = copy.deepcopy(state.documents)
                expected_field = Workspace(expected)
                expected_field.select_artifact(artifact)
                expected_field.select_field(field)
                expected_field.field.container[expected_field.field.key][index] = replacement
                self.assertEqual(family, state.glyph_range.family)
                state.set_glyph(replacement)
                self.assertEqual(expected, state.documents)
                self.assertEqual({artifact}, state.dirty)

    def test_delay_and_boundary_slots_cannot_accept_palette_glyphs(self):
        for artifact, field, index in (
            ("credits_text_sequence", 0, 0),
            ("credits_text_sequence", 2, 0),
            ("story_text_rows", 1, 1),
        ):
            with self.subTest(artifact=artifact, field=field):
                self.state.select_artifact(artifact)
                self.state.select_field(field)
                self.state.select_value(index)
                before = copy.deepcopy(self.state.documents)
                self.assertIsNone(self.state.glyph_range)
                with self.assertRaisesRegex(ValueError, "not an editable glyph"):
                    self.state.set_glyph(0)
                self.assertEqual(before, self.state.documents)
                self.assertEqual(set(), self.state.dirty)

    def test_invalid_glyph_does_not_change_the_selected_slot(self):
        for value in (-1, 228, 0xFF, True, 1.0):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    self.state.set_glyph(value)
                self.assertEqual(0, self.state.value)
                self.assertEqual(set(), self.state.dirty)

    def test_long_sequence_reads_only_32_values_around_selection(self):
        self.state.select_artifact("japanese_glyph_sequence")
        for index in (0, 31, 500, 986):
            with self.subTest(index=index):
                self.state.select_value(index)
                with mock.patch.object(self.state.field, "value", wraps=self.state.field.value) as read:
                    start, values = self.state.sequence_window()
                    self.assertEqual(32, read.call_count)
                self.assertEqual(32, len(values))
                self.assertLessEqual(start, index)
                self.assertLess(index, start + len(values))
                self.assertEqual(self.state.value, values[index - start])
        self.assertEqual(955, start)
        self.state.select_artifact("frontend_text_strings")
        self.assertEqual((0, [0, 127, 227]), self.state.sequence_window())

    def test_picker_click_uses_validation_and_rolls_back_a_rejected_change(self):
        window = Window.__new__(Window)
        window.state, window.project, window.profile = self.state, ROOT, "jp"
        window.context = {
            "frontend_text_strings": {
                "document": self.state.documents["frontend_text_strings"],
                "validate": mock.Mock(side_effect=ValueError("fixture rejection")),
            }
        }
        window.show_value, window.messagebox, window.status = mock.Mock(), mock.Mock(), mock.Mock()
        picker = GlyphPicker.__new__(GlyphPicker)
        picker.owner, picker.font_range, picker.page = window, self.state.glyph_range, 0
        before = copy.deepcopy(self.state.documents)
        picker.choose(SimpleNamespace(x=CELL_WIDTH + 1, y=1))
        self.assertEqual(before, self.state.documents)
        self.assertEqual(set(), self.state.dirty)
        window.messagebox.showerror.assert_called_once_with("Text Studio", "fixture rejection")


if __name__ == "__main__":
    unittest.main()
