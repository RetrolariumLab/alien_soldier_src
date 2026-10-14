from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.stage_message_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
)


class StageMessageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def test_inventory_distinguishes_sequences_from_padding(self) -> None:
        self.assertEqual(4, self.document["stream_count"])
        self.assertEqual(38, self.document["entry_count"])
        self.assertEqual(808, self.document["encoded_byte_count"])
        records = {item["name"]: item for item in self.document["streams"]}
        self.assertEqual(
            2, records["StageTransitionMessageSequence_TrainAndBugmax"]["sequence_count"])
        self.assertEqual(
            [0xFF], records["StageTransitionMessageSequence_PostFlyingNeo"]["padding"])

    def test_both_profiles_round_trip_without_writes(self) -> None:
        for profile in ("jp", "eu"):
            document = export_document(ROOT, profile)
            self.assertEqual([], apply_document(document, ROOT, profile, write=False))

    def test_edit_targets_the_correct_inline_owner(self) -> None:
        document = copy.deepcopy(self.document)
        record = document["streams"][0]
        record["sequences"][0][0]["glyphs"][0] ^= 1
        self.assertEqual(
            [record["path"]], apply_document(document, ROOT, "jp", write=False)
        )

    def test_row_delimiter_and_glyph_capacity_are_read_only(self) -> None:
        document = copy.deepcopy(self.document)
        entry = document["streams"][0]["sequences"][0][0]
        entry["row"] += 1
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("row byte differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["streams"][0]["sequences"][0][0]["glyphs"].pop()
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("glyph capacity differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["streams"][0]["sequences"][0][0]["glyphs"][0] = 228
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("exceeds the shared font" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
