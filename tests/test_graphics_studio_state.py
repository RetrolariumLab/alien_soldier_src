from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import graphics_studio, graphics_studio_model  # noqa: E402
from authoring.graphics_studio_state import (  # noqa: E402
    Workspace, payload_tile_count, tile_location)


class WorkspaceStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.document = graphics_studio_model.export_document(ROOT, "jp")
        self.state = Workspace(self.document)

    def test_payload_and_tile_navigation_respects_block_boundaries(self) -> None:
        chained = next(
            (index, item) for index, item in enumerate(self.state.payloads)
            if len(item["blocks"]) == 2
        )
        self.state.select_payload(chained[0])
        first_count = len(chained[1]["blocks"][0]["tiles"])
        self.assertEqual((0, first_count - 1), tile_location(chained[1], first_count - 1))
        self.assertEqual((1, 0), tile_location(chained[1], first_count))
        self.assertEqual(payload_tile_count(chained[1]), self.state.tile_count)

    def test_one_pixel_edit_changes_only_the_selected_nibble(self) -> None:
        before = self.state.tile_text()
        replacement = (int(before[0], 16) + 1) & 0x0F
        self.state.set_pixel(0, 0, replacement)
        self.assertEqual("%X" % replacement + before[1:], self.state.tile_text())
        self.assertTrue(self.state.dirty)
        graphics_studio_model.validate_document(self.document, ROOT, "jp")

    def test_repeated_colour_and_bounds_are_checked(self) -> None:
        self.state.select_colour(15)
        self.assertEqual(15, self.state.colour)
        with self.assertRaisesRegex(ValueError, "0..15"):
            self.state.select_colour(16)
        with self.assertRaisesRegex(ValueError, "8x8"):
            self.state.set_pixel(8, 0)
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.select_tile(self.state.tile_count)

    def test_greyscale_is_a_stable_index_view_not_a_palette_guess(self) -> None:
        self.assertEqual("#000000", graphics_studio.index_colour(0))
        self.assertEqual("#ffffff", graphics_studio.index_colour(15))


if __name__ == "__main__":
    unittest.main()
