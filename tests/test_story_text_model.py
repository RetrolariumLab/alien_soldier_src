from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.story_text_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
    round_trip_errors,
    stream_bytes,
)


class StoryTextTests(unittest.TestCase):
    def test_regional_row_counts_and_fixed_shape_are_source_derived(self) -> None:
        jp = export_document(ROOT, "jp")
        eu = export_document(ROOT, "eu")
        self.assertEqual((99, 123), (jp["row_count"], eu["row_count"]))
        for document in (jp, eu):
            self.assertEqual(34, document["row_bytes"])
            self.assertTrue(
                all(
                    len(row[field]) == 34 and row[field][-1] == 0xFF
                    for row in document["rows"]
                    for field in ("primary", "accent")
                )
            )

    def test_both_profiles_have_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT, "jp"))
        self.assertEqual([], round_trip_errors(ROOT, "eu"))

    def test_one_glyph_index_changes_only_its_regional_primary_stream(self) -> None:
        document = export_document(ROOT, "jp")
        document["rows"][0]["primary"][0] ^= 1
        self.assertEqual(
            [document["paths"]["primary"]],
            apply_document(document, ROOT, "jp", write=False),
        )
        encoded = stream_bytes(document, "primary")
        self.assertEqual(99 * 34 + 1, len(encoded))
        self.assertEqual(0xFE, encoded[-1])

    def test_row_boundaries_terminators_and_byte_width_are_immutable(self) -> None:
        baseline = export_document(ROOT, "eu")

        document = copy.deepcopy(baseline)
        document["rows"][0]["primary"].pop()
        self.assertTrue(any("not 34 bytes" in error for error in document_errors(document, ROOT, "eu")))

        document = copy.deepcopy(baseline)
        document["rows"][0]["primary"][-1] = 0
        self.assertTrue(any("does not end in $FF" in error for error in document_errors(document, ROOT, "eu")))

        document = copy.deepcopy(baseline)
        document["rows"][0]["accent"][0] = 256
        self.assertTrue(any("is not unsigned" in error for error in document_errors(document, ROOT, "eu")))

    def test_primary_cannot_hide_an_early_row_terminator(self) -> None:
        document = export_document(ROOT, "jp")
        document["rows"][0]["primary"][0] = 0xFF
        self.assertTrue(any("contains an early $FF" in error for error in document_errors(document, ROOT, "jp")))

    def test_accent_run_boundaries_and_shared_font_capacity_are_protected(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                baseline = export_document(ROOT, profile)
                row = next(item for item in baseline["rows"] if 0xFF in item["accent"][:-1])
                boundary = row["accent"].index(0xFF)
                document = copy.deepcopy(baseline)
                document["rows"][row["index"]]["accent"][boundary] = 0
                self.assertTrue(
                    any("changes fixed $FF boundaries" in error for error in document_errors(document, ROOT, profile))
                )

                for field in ("primary", "accent"):
                    document = copy.deepcopy(baseline)
                    document["rows"][0][field][0] = 228
                    self.assertTrue(
                        any("exceeds the shared font" in error for error in document_errors(document, ROOT, profile))
                    )

        eu = export_document(ROOT, "eu")
        two_run = next(item for item in eu["rows"] if item["accent"][:-1].count(0xFF) == 2)
        second_boundary = [offset for offset, value in enumerate(two_run["accent"][:-1]) if value == 0xFF][1]
        document = copy.deepcopy(eu)
        document["rows"][two_run["index"]]["accent"][second_boundary] = 0
        self.assertTrue(any("changes fixed $FF boundaries" in error for error in document_errors(document, ROOT, "eu")))


if __name__ == "__main__":
    unittest.main()
