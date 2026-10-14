from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.glyph_source_list_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
)


class GlyphSourceListTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def test_inventory_preserves_word_packing_and_padding(self) -> None:
        self.assertEqual(4, self.document["list_count"])
        self.assertEqual(57, self.document["glyph_count"])
        self.assertEqual(62, self.document["encoded_byte_count"])
        records = {item["name"]: item for item in self.document["lists"]}
        self.assertEqual(
            [0], records["Results_TimeBonusGlyphSourceList"]["padding"]
        )

    def test_both_profiles_round_trip_without_writes(self) -> None:
        for profile in ("jp", "eu"):
            document = export_document(ROOT, profile)
            self.assertEqual([], apply_document(document, ROOT, profile, write=False))

    def test_edit_targets_the_shared_source_owner(self) -> None:
        document = copy.deepcopy(self.document)
        record = document["lists"][0]
        record["glyphs"][0] ^= 1
        self.assertEqual(
            [record["path"]], apply_document(document, ROOT, "jp", write=False)
        )

    def test_capacity_padding_and_font_bound_are_guarded(self) -> None:
        document = copy.deepcopy(self.document)
        document["lists"][0]["glyphs"].pop()
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("glyph capacity differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["lists"][-2]["padding"] = [1]
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("padding differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["lists"][0]["glyphs"][0] = document["font_glyph_count"]
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("invalid glyph index" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
