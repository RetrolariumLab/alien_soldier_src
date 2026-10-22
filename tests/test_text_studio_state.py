from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.text_studio import load_context, parse_value  # noqa: E402
from authoring.text_studio_state import Workspace  # noqa: E402


class TextStudioStateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.context = load_context(ROOT, "jp")

    def setUp(self) -> None:
        context = load_context(ROOT, "jp")
        self.state = Workspace({identifier: record["document"] for identifier, record in context.items()})

    def test_every_manifest_artifact_has_editable_fields(self) -> None:
        self.assertEqual(
            {
                "boss_and_ship_message_scripts",
                "credits_text_sequence",
                "frontend_text_strings",
                "glyph_source_lists",
                "japanese_glyph_sequence",
                "results_detail_text",
                "stage_message_sequences",
                "story_text_rows",
            },
            set(self.state.artifact_ids),
        )
        for identifier in self.state.artifact_ids:
            self.state.select_artifact(identifier)
            self.assertGreater(len(self.state.artifact_fields), 0)
            self.assertGreater(self.state.field.length, 0)

    def test_edit_marks_only_the_selected_artifact_dirty(self) -> None:
        self.state.select_artifact("credits_text_sequence")
        self.state.select_field(1)
        before = self.state.value
        replacement = 1 if before == 0 else 0
        self.state.set_value(replacement)
        self.assertEqual({"credits_text_sequence"}, self.state.dirty)
        self.assertEqual(replacement, self.state.value)

    def test_story_terminators_are_not_editable(self) -> None:
        self.state.select_artifact("story_text_rows")
        row = self.state.documents["story_text_rows"]["rows"][0]
        self.assertEqual(len(row["primary"]) - 1, self.state.field.length)
        self.assertEqual(0xFF, row["primary"][-1])
        with self.assertRaisesRegex(ValueError, "outside the selected field"):
            self.state.select_value(self.state.field.length)

        self.state.select_field(1)
        boundary = self.state.documents["story_text_rows"]["rows"][0]["accent"].index(0xFF)
        self.state.select_value(boundary)
        self.assertIn(boundary, self.state.field.protected_indices)
        with self.assertRaisesRegex(ValueError, "protected \\$FF boundary"):
            self.state.set_value(0)
        self.assertEqual(0xFF, self.state.value)
        self.assertEqual(227, self.state.field.maximum)

    def test_scalar_delays_and_sequence_navigation_are_bounded(self) -> None:
        self.state.select_artifact("credits_text_sequence")
        self.state.select_field(0)
        self.assertTrue(self.state.field.scalar)
        self.assertEqual(1, self.state.field.length)
        with self.assertRaisesRegex(ValueError, "between 0 and 127"):
            self.state.set_value(0x80)

        self.state.select_artifact("glyph_source_lists")
        self.state.select_value(self.state.field.length - 1)
        self.assertIsInstance(self.state.value, int)

    def test_workstation_numeric_parser_is_explicit(self) -> None:
        self.assertEqual(0x2A, parse_value("$2A"))
        self.assertEqual(0x2A, parse_value("0x2a"))
        self.assertEqual(42, parse_value("42"))

    def test_japanese_glyph_bounds_and_sentinel(self) -> None:
        self.state.select_artifact("japanese_glyph_sequence")
        self.assertEqual(987, self.state.field.length)
        self.assertEqual(0x20, self.state.field.minimum)
        self.assertEqual(0x146, self.state.field.maximum)
        with self.assertRaisesRegex(ValueError, "between"):
            self.state.set_value(0x147)

    def test_results_detail_rows_keep_their_terminators_and_font_bounds(self) -> None:
        self.state.select_artifact("results_detail_text")
        self.assertEqual(34, len(self.state.artifact_fields))
        self.assertEqual(21, self.state.field.length)
        self.assertEqual(227, self.state.field.maximum)
        self.assertEqual(0xFF, self.state.documents["results_detail_text"]["rows"][0]["terminator"])
        with self.assertRaisesRegex(ValueError, "between"):
            self.state.set_value(0xE4)
        self.state.select_field(31)
        self.assertIn("Results_TotalTimeLabel", self.state.field.label)
        self.assertEqual(22, self.state.field.length)

    def test_frontend_and_stage_message_fields_stop_at_shared_font_art(self) -> None:
        for artifact in ("frontend_text_strings", "stage_message_sequences"):
            with self.subTest(artifact=artifact):
                self.state.select_artifact(artifact)
                self.assertEqual(227, self.state.field.maximum)
                with self.assertRaisesRegex(ValueError, "between"):
                    self.state.set_value(228)

    def test_manifest_publishes_the_workstation_contract(self) -> None:
        document = json.loads((ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8"))
        studio = next(item for item in document["studios"] if item["id"] == "text")
        self.assertEqual("check-text-workspace", studio["workspace_gate"])
        self.assertEqual("check-text-studio", studio["workstation_gate"])
        self.assertEqual(
            ["save", "reload", "build", "dirty-close"],
            studio["workstation_actions"],
        )


if __name__ == "__main__":
    unittest.main()
