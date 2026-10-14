"""Source-backed results detail/summary text and staged edit tests."""

from __future__ import annotations

import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import results_text_model as model  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402


class ResultsTextModelTests(unittest.TestCase):
    def test_both_profiles_round_trip_the_reader_sized_table(self) -> None:
        original = (ROOT / model.TABLE).read_bytes()
        for profile in model.PROFILES:
            with self.subTest(profile=profile):
                document = model.export_document(ROOT, profile)
                self.assertEqual((31, 22, 651, 682, 227), (
                    document["row_count"], document["row_bytes"],
                    document["glyph_count"], document["encoded_byte_count"],
                    document["max_glyph_id"],
                ))
                self.assertEqual(original, model.encoded(document))
                self.assertEqual((3, 66, 70), (
                    document["summary_label_count"],
                    document["summary_glyph_count"],
                    document["summary_encoded_byte_count"],
                ))
                self.assertEqual(("byte", "byte", "word"), tuple(
                    item["terminator_storage"]
                    for item in document["summary_labels"]
                ))
                self.assertTrue(all(
                    set(row["glyphs"]) == {0}
                    for row in document["rows"][25:]
                ))
                self.assertEqual([], model.round_trip_errors(ROOT, profile))

    def test_reader_bounds_and_fixed_terminators_reject_invalid_edits(self) -> None:
        baseline = model.export_document(ROOT, "jp")
        for change, fragment in (
            (lambda doc: doc["rows"][0]["glyphs"].append(0), "capacity"),
            (lambda doc: doc["rows"][0]["glyphs"].__setitem__(0, 0xFF),
             "invalid glyph"),
            (lambda doc: doc["rows"][0].__setitem__("terminator", 0),
             "terminator"),
            (lambda doc: doc["rows"][0].__setitem__("index", 1), "index"),
            (lambda doc: doc["summary_labels"][0]["glyphs"].append(0),
             "capacity"),
            (lambda doc: doc["summary_labels"][0]["glyphs"].__setitem__(0, 0xFF),
             "invalid glyph"),
            (lambda doc: doc["summary_labels"][2].__setitem__(
                "terminator_storage", "byte"), "terminator_storage"),
        ):
            with self.subTest(fragment=fragment):
                changed = copy.deepcopy(baseline)
                change(changed)
                with self.assertRaisesRegex(ValueError, fragment):
                    model.validate_document(changed, ROOT, "jp")


    def test_one_edit_rewrites_only_the_disposable_binary_owner(self) -> None:
        document = model.export_document(ROOT, "eu")
        original = (ROOT / model.TABLE).read_bytes()
        document["rows"][0]["glyphs"][0] = 1
        with tempfile.TemporaryDirectory() as temporary:
            stage = Path(temporary)
            destination = stage / model.TABLE
            destination.parent.mkdir(parents=True)
            shutil.copyfile(ROOT / model.TABLE, destination)
            self.assertEqual([model.TABLE], model.apply_document(
                document, stage, "eu", validation_root=ROOT))
            changed = destination.read_bytes()
            self.assertEqual(len(original), len(changed))
            self.assertEqual(1, changed[0])
            self.assertEqual(original[1:], changed[1:])
            self.assertEqual(original, (ROOT / model.TABLE).read_bytes())

    def test_summary_edit_rewrites_only_its_word_packed_source_record(self) -> None:
        document = model.export_document(ROOT, "jp")
        document["summary_labels"][0]["glyphs"][0] = 1
        with tempfile.TemporaryDirectory() as temporary:
            stage = Path(temporary)
            for relative in (model.TABLE, model.SOURCE):
                destination = stage / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / relative, destination)
            self.assertEqual([model.SOURCE], model.apply_document(
                document, stage, "jp", validation_root=ROOT))
            before, _ = labelled_blocks(ROOT)
            after, _ = labelled_blocks(stage)
            for name, _storage in model.SUMMARY_LABELS:
                if name == "Results_TotalTimeLabel":
                    self.assertEqual((0x100, *before[name][1:]), after[name])
                else:
                    self.assertEqual(before[name], after[name])
            self.assertEqual((ROOT / model.TABLE).read_bytes(),
                             (stage / model.TABLE).read_bytes())


if __name__ == "__main__":
    unittest.main()
