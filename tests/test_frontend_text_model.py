from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.frontend_text_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
    round_trip_errors,
)


class FrontendTextTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def test_inventory_has_fixed_capacity_and_no_placeholder_aliases(self) -> None:
        self.assertEqual(37, self.document["string_count"])
        self.assertEqual(429, self.document["glyph_count"])
        self.assertEqual(466, self.document["encoded_byte_count"])
        names = {record["name"] for record in self.document["strings"]}
        self.assertNotIn("Text_SixteenDigitPlaceholder", names)
        self.assertNotIn("Text_FourDigitPlaceholder", names)

    def test_both_profiles_round_trip_the_shared_source(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT, "jp"))
        self.assertEqual([], round_trip_errors(ROOT, "eu"))

    def test_edit_targets_only_the_assembly_owner(self) -> None:
        document = copy.deepcopy(self.document)
        document["strings"][0]["glyphs"][0] ^= 1
        self.assertEqual(
            ["src/rendering/text_and_numbers.s"],
            apply_document(document, ROOT, "jp", write=False),
        )

    def test_capacity_and_glyphs_outside_the_shared_font_are_rejected(self) -> None:
        document = copy.deepcopy(self.document)
        document["strings"][0]["glyphs"].pop()
        self.assertTrue(any("glyph count differs" in error for error in document_errors(document, ROOT, "jp")))

        document = copy.deepcopy(self.document)
        for invalid in (228, 0xFF):
            document = copy.deepcopy(self.document)
            document["strings"][0]["glyphs"][0] = invalid
            self.assertTrue(any("exceeds the shared font" in error for error in document_errors(document, ROOT, "jp")))


if __name__ == "__main__":
    unittest.main()
