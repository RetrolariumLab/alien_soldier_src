from __future__ import annotations

import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.japanese_glyph_model import (  # noqa: E402
    ART_PATH,
    SOURCE_PATH,
    apply_document,
    export_document,
    glyph_pixels,
    validate_document,
)


class JapaneseGlyphModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def test_inventory_and_zero_edit_both_profiles(self) -> None:
        self.assertEqual(987, self.document["entry_count"])
        self.assertEqual(295, self.document["art_glyph_count"])
        self.assertEqual(1976, self.document["encoded_byte_count"])
        for profile in ("jp", "eu"):
            document = export_document(ROOT, profile)
            self.assertEqual([], apply_document(document, ROOT, profile, write=False))

    def test_edit_only_mapping_word_in_staged_tree(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            stage = Path(temporary)
            for owner in (SOURCE_PATH, ART_PATH):
                target = stage / owner
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / owner, target)
            document = copy.deepcopy(self.document)
            document["codes"][16] = 0x20 if document["codes"][16] != 0x20 else 0x21
            before = (stage / SOURCE_PATH).read_bytes()
            art_before = (stage / ART_PATH).read_bytes()
            self.assertEqual(
                [SOURCE_PATH],
                apply_document(document, stage, "jp", validation_root=ROOT),
            )
            after = (stage / SOURCE_PATH).read_bytes()
            self.assertEqual(len(before), len(after))
            self.assertEqual(before[-2:], after[-2:])
            self.assertEqual(before[:32], after[:32])
            self.assertNotEqual(before[32:34], after[32:34])
            self.assertEqual(before[34:], after[34:])
            self.assertEqual(art_before, (stage / ART_PATH).read_bytes())

    def test_capacity_bound_and_profile_are_guarded(self) -> None:
        for mutation in (
            lambda d: d["codes"].pop(),
            lambda d: d["codes"].__setitem__(0, 0x147),
            lambda d: d.__setitem__("profile", "eu"),
            lambda d: d.__setitem__("encoded_byte_count", 1974),
        ):
            document = copy.deepcopy(self.document)
            mutation(document)
            with self.assertRaises(ValueError):
                validate_document(document, ROOT, "jp")

    def test_glyph_pixels_follow_reader_tile_order(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            stage = Path(temporary)
            art = stage / ART_PATH
            art.parent.mkdir(parents=True, exist_ok=True)
            art.write_bytes(b"".join(bytes([value * 0x11]) * 32 for value in range(4)))
            pixels = glyph_pixels(stage, 0x20)
            self.assertEqual(16, len(pixels))
            self.assertTrue(all(len(row) == 16 for row in pixels))
            self.assertEqual(0, pixels[0][0])
            self.assertEqual(2, pixels[0][8])
            self.assertEqual(1, pixels[8][0])
            self.assertEqual(3, pixels[8][8])


if __name__ == "__main__":
    unittest.main()
