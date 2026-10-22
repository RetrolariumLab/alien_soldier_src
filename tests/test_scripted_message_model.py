from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.scripted_message_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
)


class ScriptedMessageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def test_inventory_is_reader_reachable_only(self) -> None:
        self.assertEqual(9, self.document["script_count"])
        self.assertGreater(self.document["record_count"], 0)
        self.assertGreater(self.document["unexposed_byte_count"], 0)
        for script in self.document["scripts"]:
            self.assertEqual("end", script["commands"][-1]["kind"])

    def test_both_profiles_round_trip_without_writes(self) -> None:
        for profile in ("jp", "eu"):
            document = export_document(ROOT, profile)
            self.assertEqual([], apply_document(document, ROOT, profile, write=False))

    def test_edit_targets_the_shared_source_owner(self) -> None:
        document = copy.deepcopy(self.document)
        script = document["scripts"][0]
        script["records"][0]["glyphs"][0] ^= 1
        self.assertEqual([script["path"]], apply_document(document, ROOT, "jp", write=False))

    def test_commands_attributes_and_capacity_are_read_only(self) -> None:
        for field, mutate in (
            ("commands", lambda script: script["commands"][0].update(target=0)),
            ("attributes", lambda script: script["records"][0]["attributes"].__setitem__(0, 0)),
            ("capacity", lambda script: script.update(capacity=script["capacity"] + 1)),
        ):
            document = copy.deepcopy(self.document)
            script = document["scripts"][0]
            mutate(script)
            errors = document_errors(document, ROOT, "jp")
            self.assertTrue(any(field in error for error in errors), errors)

    def test_glyph_index_must_exist_in_the_shared_font(self) -> None:
        document = copy.deepcopy(self.document)
        script = document["scripts"][0]
        script["records"][0]["glyphs"][0] = document["font_glyph_count"]
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("invalid glyph index" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
