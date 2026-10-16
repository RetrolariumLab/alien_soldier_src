"""Tiny explicit HUMAN-ANSWER fixtures, never cartridge character guesses."""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import text_character_map as model  # noqa: E402
from authoring.text_studio import Window  # noqa: E402
from authoring.text_studio_state import Workspace  # noqa: E402
from authoring import text_studio  # noqa: E402


ASSETS = {
    "shared": {"first": 0, "count": 4, "sha256": "a" * 64},
    "japanese": {"first": 0x20, "count": 3, "sha256": "b" * 64},
    "credits": {"first": 0, "count": 4, "sha256": "a" * 64},
}


def answer(index, text, family="shared", evidence="visual", notes="tiny human-answer fixture"):
    return {"set": family, "index": index, "transcription": text,
            "evidence": evidence, "notes": notes}


def worksheet(*records):
    return {"schema_version": 1,
            "source_hashes": {name: asset["sha256"] for name, asset in ASSETS.items()},
            "answers": list(records)}


def character_map(*records, profile="jp"):
    with mock.patch.object(model, "inventory", return_value=ASSETS):
        return model.CharacterMap(model.from_answers(ROOT, profile, worksheet(*records)))


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.patch = mock.patch.object(model, "inventory", return_value=ASSETS)
        self.patch.start()

    def tearDown(self):
        self.patch.stop()
        self.temp.cleanup()

    def test_import_retains_exact_answers_source_hashes_and_explicit_profile(self):
        records = worksheet(answer(0, "A", evidence="source", notes="fixture reader line 12"),
                            answer(1, "", evidence="unknown_or_unused"))
        source = self.root / "answers.json"
        source.write_text(json.dumps(records), encoding="utf-8")
        imported = model.import_answers(self.root, "jp", source)
        self.assertEqual("jp", imported["profile"])
        self.assertEqual(records["answers"], imported["answers"])
        self.assertEqual(ASSETS, imported["source_fonts"])
        self.assertEqual(imported, model.load_document(self.root, "jp"))
        self.assertEqual([], model.load_document(self.root, "eu")["answers"])
        self.assertFalse(model.map_path(self.root, "eu").exists())
        with self.assertRaisesRegex(ValueError, "profile differs"):
            model.validate_document(imported, self.root, "eu")

    def test_bad_evidence_or_art_does_not_create_a_map(self):
        valid = worksheet(answer(0, "A", evidence="in_game", notes="fixture frame 1"))
        changed = deepcopy(valid)
        changed["source_hashes"]["shared"] = "c" * 64
        bad_notes = deepcopy(valid)
        bad_notes["answers"][0]["notes"] = ""
        duplicate = dict(valid, answers=valid["answers"] * 2)
        for malformed in (changed, bad_notes, duplicate, dict(valid, schema_version=True)):
            with self.subTest(malformed=malformed), self.assertRaises(ValueError):
                model.from_answers(self.root, "jp", malformed)
        self.assertFalse(model.map_path(self.root, "jp").exists())

    def test_saved_map_metadata_cannot_relabel_or_resize_the_fonts(self):
        baseline = model.from_answers(self.root, "jp", worksheet())
        for field, value in (("count", 4.0), ("first", False), ("sha256", "c" * 64)):
            changed = deepcopy(baseline)
            changed["source_fonts"]["shared"][field] = value
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, "source art differs"):
                model.validate_document(changed, self.root, "jp")

    def test_replace_is_explicit_and_failed_import_preserves_old_map(self):
        source = self.root / "answers.json"
        source.write_text(json.dumps(worksheet(answer(0, "A"))), encoding="utf-8")
        model.import_answers(self.root, "jp", source)
        destination = model.map_path(self.root, "jp")
        before = destination.read_bytes()
        source.write_text(json.dumps(worksheet(answer(0, "B"))), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "explicitly approve"):
            model.import_answers(self.root, "jp", source)
        self.assertEqual(before, destination.read_bytes())
        with mock.patch.object(model, "atomic_write_json", side_effect=OSError("fixture failure")):
            with self.assertRaises(OSError):
                model.import_answers(self.root, "jp", source, replace=True)
        self.assertEqual(before, destination.read_bytes())
        model.import_answers(self.root, "jp", source, replace=True)
        self.assertEqual("B", model.load_document(self.root, "jp")["answers"][0]["transcription"])

    def test_profile_and_linked_workspace_paths_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "profile must"):
            model.map_path(self.root, "../../other")
        parent = self.root / "content/workspace"
        parent.mkdir(parents=True)
        target = self.root / "elsewhere"
        target.mkdir()
        try:
            (parent / "jp").symlink_to(target, target_is_directory=True)
        except OSError as error:
            self.skipTest("directory symlinks are unavailable: " + str(error))
        with self.assertRaisesRegex(ValueError, "crosses a link"):
            model.map_path(self.root, "jp")


class CodecTests(unittest.TestCase):
    def test_unknown_and_unreviewed_ids_stay_lossless_raw_tokens(self):
        mapping = character_map(answer(0, "A"), answer(1, "", evidence="unknown_or_unused"))
        self.assertEqual("A[[$001]][[$002]][[$003]]", mapping.decode([0, 1, 2, 3], "shared"))
        self.assertEqual([0, 1, 2, 3], mapping.encode(
            mapping.decode([0, 1, 2, 3], "shared"), "shared", length=4))
        with self.assertRaisesRegex(ValueError, "unmapped"):
            mapping.encode("B", "shared", length=1)

    def test_duplicate_transcriptions_never_choose_a_first_id(self):
        mapping = character_map(answer(0, "A"), answer(1, "A"))
        self.assertEqual("[[$000]][[$001]]", mapping.decode([0, 1], "shared"))
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            mapping.encode("A", "shared", length=1)
        self.assertEqual([1], mapping.encode("[[$001]]", "shared", length=1))

    def test_unreviewed_claims_are_rejected_even_by_the_low_level_codec_constructor(self):
        document = {"schema_version": 1, "profile": "jp", "source_fonts": ASSETS,
                    "answers": [answer(0, "A", evidence="")]}
        with self.assertRaisesRegex(ValueError, "evidence"):
            model.CharacterMap(document)

    def test_prefix_overlaps_reject_greedy_segmentation_and_decode_to_ids(self):
        mapping = character_map(answer(0, "A"), answer(1, "B"), answer(2, "AB"))
        for values in ([0, 1], [2]):
            text = mapping.decode(values, "shared")
            self.assertIn("[[$", text)
            self.assertEqual(values, mapping.encode(text, "shared", length=len(values)))
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            mapping.encode("AB", "shared", length=1)
        self.assertEqual([2, 0], mapping.encode("[[$002]]A", "shared", length=2))

    def test_japanese_codepoints_are_not_normalized_or_transferred_to_shared_font(self):
        mapping = character_map(answer(0x20, "が", "japanese"),
                                answer(0x21, "か\u3099", "japanese"))
        self.assertEqual([0x20], mapping.encode("が", "japanese", length=1))
        self.assertEqual([0x21], mapping.encode("か\u3099", "japanese", length=1))
        self.assertEqual("がか\u3099", mapping.decode([0x20, 0x21], "japanese"))
        with self.assertRaisesRegex(ValueError, "unmapped"):
            mapping.encode("が", "shared", length=1)

    def test_credits_blank_is_not_an_inferred_space_and_sets_remain_independent(self):
        mapping = character_map(answer(0, " ", "credits"), answer(1, "A", "shared"))
        self.assertEqual("[[$000]][[$001]]", mapping.decode([0, 1], "credits"))
        with self.assertRaisesRegex(ValueError, "unmapped"):
            mapping.encode(" ", "credits", length=1)
        with self.assertRaisesRegex(ValueError, "unmapped"):
            mapping.encode("A", "credits", length=1)

    def test_reserved_transcriptions_cannot_hijack_explicit_ids(self):
        mapping = character_map(answer(1, "[[$002]]"))
        self.assertEqual("[[$001]]", mapping.decode([1], "shared"))
        self.assertEqual([2], mapping.encode("[[$002]]", "shared", length=1))

    def test_fixed_lengths_font_ranges_and_protected_boundaries_are_checked(self):
        mapping = character_map(answer(0, "A"), answer(1, "B"))
        text = mapping.decode([0, 0xFF, 1], "shared", protected={1: 0xFF})
        self.assertEqual("A[[$0FF]]B", text)
        self.assertEqual([0, 0xFF, 1], mapping.encode(
            text, "shared", length=3, protected={1: 0xFF}))
        for invalid in ("A[[$0FF]]", "[[$0FF]]AB", "AAB", "A[[$0FE]]B"):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                mapping.encode(invalid, "shared", length=3, protected={1: 0xFF})
        for invalid in ("[[$004]]", "[[foo]]", "[[$XYZ]]", "[[$0]]x"):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                mapping.encode(invalid, "shared", length=1)

    def test_long_unique_runs_use_bounded_segmentation_without_normalization(self):
        mapping = character_map(answer(0, "A"), answer(1, " "))
        text = " A" * 1000
        self.assertEqual([1, 0] * 1000, mapping.encode(text, "shared", length=2000))
        self.assertEqual(text, mapping.decode([1, 0] * 1000, "shared"))


class FieldEditingTests(unittest.TestCase):
    def setUp(self):
        self.mapping = character_map(answer(0, "A"), answer(1, "B"), answer(2, "C"))
        self.state = Workspace({
            "frontend_text_strings": {"profile": "jp", "strings": [{
                "name": "tiny", "glyphs": [0, 1, 2]}]},
            "story_text_rows": {"profile": "jp", "rows": [{
                "index": 0, "primary": [0, 1, 2, 0xFF], "accent": [0, 0xFF, 1, 0xFF]}]},
            "credits_text_sequence": {"profile": "jp", "max_glyph_id": 3, "records": [{
                "upper_delay": 1, "upper_count": 1, "upper_glyphs": [1],
                "lower_delay": 2, "lower_count": 1, "lower_glyphs": [2]}]},
        })

    def test_credits_fixture_counts_match_fixed_glyph_slots_and_safe_delay_bounds(self):
        self.state.select_artifact("credits_text_sequence")
        record = self.state.documents["credits_text_sequence"]["records"][0]
        self.assertEqual(record["upper_count"], len(record["upper_glyphs"]))
        self.assertEqual(record["lower_count"], len(record["lower_glyphs"]))
        self.state.select_field(2)
        self.assertEqual((0, 0x7F), (self.state.field.minimum, self.state.field.maximum))

    def test_field_text_edits_only_its_existing_glyph_slots(self):
        self.assertEqual("ABC", self.state.field_text(self.mapping))
        validate = mock.Mock()
        self.state.set_text("CBA", self.mapping, validate)
        self.assertEqual([2, 1, 0], self.state.values())
        self.assertEqual({"frontend_text_strings"}, self.state.dirty)
        validate.assert_called_once_with(self.state.documents["frontend_text_strings"])

    def test_failed_full_validator_restores_all_slots_and_prior_dirty_set(self):
        original = deepcopy(self.state.documents)
        reference = self.state.field.container["glyphs"]
        self.state.dirty.add("story_text_rows")
        validate = mock.Mock(side_effect=ValueError("reader rejected candidate"))
        with self.assertRaisesRegex(ValueError, "reader rejected"):
            self.state.set_text("CBA", self.mapping, validate)
        self.assertEqual(original, self.state.documents)
        self.assertIs(reference, self.state.field.container["glyphs"])
        self.assertEqual({"story_text_rows"}, self.state.dirty)

    def test_unchanged_text_still_runs_the_document_validator_without_marking_dirty(self):
        validate = mock.Mock()
        self.state.set_text("ABC", self.mapping, validate)
        validate.assert_called_once()
        self.assertEqual(set(), self.state.dirty)

    def test_story_boundaries_and_final_terminator_do_not_move(self):
        self.state.select_artifact("story_text_rows")
        self.state.select_field(1)
        self.state.select_value(1)
        self.assertIsNone(self.state.glyph_range)
        self.assertEqual("shared", self.state.font_family)
        self.assertEqual("A[[$0FF]]B", self.state.field_text(self.mapping))
        self.state.set_text("C[[$0FF]]A", self.mapping)
        self.assertEqual([2, 0xFF, 0, 0xFF], self.state.field.container["accent"])
        original = deepcopy(self.state.documents)
        with self.assertRaisesRegex(ValueError, "protected"):
            self.state.set_text("CAB", self.mapping)
        self.assertEqual(original, self.state.documents)

    def test_timing_fields_and_wrong_profile_maps_are_rejected(self):
        other = character_map(profile="eu")
        with self.assertRaisesRegex(ValueError, "profile differs"):
            self.state.field_text(other)
        with self.assertRaisesRegex(ValueError, "profile differs"):
            self.state.set_text("[[$000]][[$001]][[$002]]", other)
        self.state.select_artifact("credits_text_sequence")
        for operation in (lambda: self.state.field_text(self.mapping),
                          lambda: self.state.set_text("A", self.mapping)):
            with self.assertRaisesRegex(ValueError, "timing fields"):
                operation()

    def test_gui_apply_uses_the_same_full_validator_and_preserves_failure_state(self):
        window = Window.__new__(Window)
        window.state, window.character_map = self.state, self.mapping
        window.project, window.profile = ROOT, "jp"
        window.field_text = mock.Mock()
        window.field_text.get.return_value = "CBA"
        validate = mock.Mock(side_effect=ValueError("fixture validator"))
        window.context = {"frontend_text_strings": {
            "document": self.state.documents["frontend_text_strings"], "validate": validate}}
        window.show_value, window.messagebox, window.status = mock.Mock(), mock.Mock(), mock.Mock()
        original = deepcopy(self.state.documents)
        window.apply_text()
        validate.assert_called_once_with(self.state.documents["frontend_text_strings"], ROOT, "jp")
        self.assertEqual(original, self.state.documents)
        self.assertFalse(self.state.dirty)
        window.messagebox.showerror.assert_called_once()
        window.status.configure.assert_not_called()


class CartridgeFontBindingTests(unittest.TestCase):
    def test_empty_regional_maps_bind_the_real_source_fonts_without_transcribing_them(self):
        for profile in ("jp", "eu"):
            document = model.empty_document(ROOT, profile)
            model.validate_document(document, ROOT, profile)
            self.assertEqual(profile, document["profile"])
            self.assertEqual(228, document["source_fonts"]["shared"]["count"])
            self.assertEqual(295, document["source_fonts"]["japanese"]["count"])
            self.assertEqual([], document["answers"])
            mapping = model.CharacterMap(document)
            for family, values in (("shared", [0, 227]), ("japanese", [0x20, 0x146]),
                                   ("credits", [0, 227])):
                text = mapping.decode(values, family)
                self.assertEqual(values, mapping.encode(text, family, length=2))


class CharacterMapWidgetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from tk_test_lifetime import tk_main_thread_lifetime
        cls.enterClassContext(tk_main_thread_lifetime())
        try:
            import tkinter as tk
            from tkinter import ttk
            probe = tk.Tk()
            probe.withdraw()
            probe.destroy()
            cls.tk, cls.ttk = tk, ttk
        except Exception as error:
            if os.environ.get("TEXT_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("Text character-map GUI is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable: " + str(error))

    def test_hidden_widgets_import_explicit_answers_apply_and_reject_bad_text(self):
        actual_tk = self.tk.Tk

        def hidden_tk():
            window = actual_tk()
            window.withdraw()
            return window

        for profile in ("jp", "eu"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                source = root / "answers.json"
                source.write_text(json.dumps(worksheet(
                    answer(0, "A"), answer(1, "B"), answer(2, "C"))), encoding="utf-8")
                document = {"profile": profile, "strings": [{"name": "tiny", "glyphs": [0, 1, 2]}]}
                validate = mock.Mock()
                context = {"frontend_text_strings": {"document": document, "validate": validate}}
                dialogs, messages = mock.Mock(), mock.Mock()
                dialogs.askopenfilename.return_value = str(source)
                with (mock.patch.object(self.tk, "Tk", new=hidden_tk),
                      mock.patch.object(model, "inventory", return_value=ASSETS),
                      mock.patch.object(text_studio, "shared_glyph_tiles", return_value=(
                          [[1] * 8 for _ in range(8)], [[2] * 8 for _ in range(8)]))):
                    window = Window(root, profile, context, self.tk, self.ttk, messages, dialogs)
                    try:
                        self.assertEqual("[[$000]][[$001]][[$002]]", window.field_text.get())
                        self.assertTrue(window.text_entry.bind("<Return>"))
                        window.import_character_map()
                        self.assertEqual("ABC", window.field_text.get())
                        self.assertTrue(model.map_path(root, profile).is_file())
                        self.assertFalse(window.state.dirty)
                        window.field_text.set("CBA")
                        window.text_button.invoke()
                        self.assertEqual([2, 1, 0], window.state.values())
                        validate.assert_called_once_with(document, root, profile)
                        self.assertEqual({"frontend_text_strings"}, window.state.dirty)
                        window.field_text.set("AB")
                        window.text_button.invoke()
                        self.assertEqual([2, 1, 0], window.state.values())
                        self.assertEqual("CBA", window.field_text.get())
                        messages.showerror.assert_called_once()
                        dialogs.askopenfilename.return_value = ""
                        old_map = window.character_map
                        window.import_character_map()
                        self.assertIs(old_map, window.character_map)
                    finally:
                        window.window.destroy()


if __name__ == "__main__":
    os.environ.setdefault("TEXT_WIDGET_REQUIRE_GUI", "1")
    unittest.main()
