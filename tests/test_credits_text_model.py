from __future__ import annotations

import copy
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.credits_text_model import (  # noqa: E402
    apply_document,
    atomic_write_json,
    document_errors,
    export_document,
    glyph_tiles,
    glyph_tiles_from_art,
    migrate_document,
    migrate_path,
)


class CreditsTextTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def test_inventory_follows_the_two_row_reader(self) -> None:
        self.assertEqual(37, self.document["record_count"])
        self.assertEqual(874, self.document["encoded_byte_count"])
        self.assertEqual(2, self.document["schema_version"])
        self.assertEqual("SharedFontTileArt", self.document["tile_art_name"])
        self.assertEqual(456, self.document["tile_art_tile_count"])
        self.assertEqual(227, self.document["max_glyph_id"])
        self.assertEqual(0xFF, self.document["terminator"])
        self.assertEqual([0xFF], self.document["padding"])

    def test_both_profiles_round_trip_without_writes(self) -> None:
        for profile in ("jp", "eu"):
            document = export_document(ROOT, profile)
            self.assertEqual([], apply_document(document, ROOT, profile, write=False))

    def test_edit_targets_the_credits_payload(self) -> None:
        document = copy.deepcopy(self.document)
        document["records"][0]["upper_glyphs"][0] ^= 1
        self.assertEqual(
            [document["path"]], apply_document(document, ROOT, "jp", write=False)
        )

    def test_counts_and_terminator_are_read_only(self) -> None:
        document = copy.deepcopy(self.document)
        document["records"][0]["upper_count"] += 1
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("upper_count differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["terminator"] = 0x80
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("terminator differs" in error for error in errors))

    def test_delays_and_glyphs_keep_reader_and_art_bounds(self) -> None:
        document = copy.deepcopy(self.document)
        document["records"][0]["upper_delay"] = 0x80
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("invalid upper delay" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["records"][0]["upper_glyphs"][0] = document["max_glyph_id"] + 1
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("invalid glyph" in error for error in errors))

    def test_credits_glyph_preview_uses_two_tiles_after_blank_slot(self) -> None:
        art = (bytes([0x00]) * 32 + bytes([0x00]) * 32
               + bytes([0x11]) * 32 + bytes([0x22]) * 32)
        self.assertIsNone(glyph_tiles_from_art(art, 0))
        first, second = glyph_tiles_from_art(art, 1)
        self.assertEqual([1] * 8, first[0])
        self.assertEqual([2] * 8, second[7])
        for value in (-1, 2, True, 0.5):
            with self.assertRaises(ValueError):
                glyph_tiles_from_art(art, value)
        with self.assertRaises(ValueError):
            glyph_tiles_from_art(art[:-1], 1)

    def test_real_credits_glyph_preview_respects_art_bounds(self) -> None:
        self.assertIsNone(glyph_tiles(ROOT, 0))
        tiles = glyph_tiles(ROOT, self.document["max_glyph_id"])
        self.assertEqual(2, len(tiles))
        self.assertTrue(all(len(row) == 8 for tile in tiles for row in tile))
        first, second = glyph_tiles(ROOT, 23)
        self.assertEqual({0, 1, 2}, {pixel for tile in (first, second)
                                      for row in tile for pixel in row})

    def test_legacy_workspace_migrates_without_losing_edits(self) -> None:
        legacy = copy.deepcopy(self.document)
        legacy.update({
            "schema_version": 1,
            "tile_art_name": "CreditsAndEndingTileArt",
            "tile_art_tile_count": 109,
            "max_glyph_id": 53,
        })
        legacy["records"][0]["upper_glyphs"][0] ^= 1
        migrated = migrate_document(legacy, ROOT, "jp")
        self.assertEqual(legacy["records"], migrated["records"])
        self.assertEqual(2, migrated["schema_version"])
        self.assertEqual("SharedFontTileArt", migrated["tile_art_name"])
        self.assertEqual([], document_errors(migrated, ROOT, "jp"))
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "credits_sequence.json"
            atomic_write_json(path, legacy)
            original = path.read_bytes()
            self.assertTrue(migrate_path(path, ROOT, "jp"))
            self.assertEqual(original, path.with_suffix(
                ".json.pre-shared-font-v1").read_bytes())
            self.assertFalse(migrate_path(path, ROOT, "jp"))


if __name__ == "__main__":
    unittest.main()
