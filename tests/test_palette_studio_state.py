from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import palette_studio_model  # noqa: E402
from authoring.palette_studio_state import (  # noqa: E402
    PaletteWorkspace,
    channel_levels,
    replace_channels,
)


class PaletteWorkspaceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.document = palette_studio_model.export_document(ROOT, "jp")
        self.state = PaletteWorkspace(self.document)

    def test_navigation_resets_colour_and_checks_bounds(self) -> None:
        self.state.select_colour(len(self.state.colours) - 1)
        self.state.select_command(1)
        self.assertEqual(0, self.state.colour_index)
        with self.assertRaisesRegex(ValueError, "command index"):
            self.state.select_command(len(self.state.commands))
        with self.assertRaisesRegex(ValueError, "colour index"):
            self.state.select_colour(len(self.state.colours))

    def test_channel_edit_preserves_raw_ignored_bits(self) -> None:
        self.state.set_word(0xFFFF)
        self.state.dirty = False
        self.state.set_channels(1, 2, 3)
        self.assertEqual(0xF111, self.state.word & 0xF111)
        self.assertEqual((1, 2, 3), self.state.channels)
        self.assertTrue(self.state.dirty)
        palette_studio_model.validate_document(self.document, ROOT, "jp")

    def test_raw_word_and_channels_are_strictly_bounded(self) -> None:
        with self.assertRaisesRegex(ValueError, "16-bit"):
            self.state.set_word(0x10000)
        with self.assertRaisesRegex(ValueError, "0 through 7"):
            self.state.set_channels(8, 0, 0)
        self.assertEqual((7, 7, 7), channel_levels(0x0EEE))
        self.assertEqual(0x0EEE, replace_channels(0, 7, 7, 7))


if __name__ == "__main__":
    unittest.main()
