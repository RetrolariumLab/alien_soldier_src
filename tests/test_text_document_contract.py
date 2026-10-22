"""Reject ambiguous text workspace metadata before editing or staging writes."""

from __future__ import annotations

import copy
from contextlib import ExitStack
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import (  # noqa: E402
    credits_text_model,
    frontend_text_model,
    glyph_source_list_model,
    japanese_glyph_model,
    results_text_model,
    scripted_message_model,
    stage_message_model,
    story_text_model,
)
from authoring.text_studio import Window  # noqa: E402


MODELS = (
    credits_text_model,
    frontend_text_model,
    glyph_source_list_model,
    japanese_glyph_model,
    results_text_model,
    scripted_message_model,
    stage_message_model,
    story_text_model,
)
NAMED = (
    (frontend_text_model, "strings"),
    (glyph_source_list_model, "lists"),
    (scripted_message_model, "scripts"),
    (stage_message_model, "streams"),
)
EDITABLE_KEYS = {
    "glyphs",
    "upper_delay",
    "lower_delay",
    "upper_glyphs",
    "lower_glyphs",
    "primary",
    "accent",
    "codes",
}


def source_integer_paths(value, path=()):
    """Visit only immutable integer metadata in exported JSON documents."""
    if type(value) is int:
        yield path
    elif isinstance(value, dict):
        for key, item in value.items():
            if key not in EDITABLE_KEYS:
                yield from source_integer_paths(item, (*path, key))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            yield from source_integer_paths(item, (*path, index))


def value_owner(document, path):
    for key in path[:-1]:
        document = document[key]
    return document, path[-1]


class TextDocumentContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Export the small source inventories once; mutation checks below use
        # these pinned in-memory baselines, with no repeated source traversal.
        cls.baselines = {model: model.export_document(ROOT, "jp") for model in MODELS}

    def source_baseline(self, model, profile="jp"):
        baseline = copy.deepcopy(self.baselines[model])
        baseline["profile"] = profile
        stack = ExitStack()
        self.addCleanup(stack.close)
        stack.enter_context(mock.patch.object(model, "export_document", return_value=baseline))
        if hasattr(model, "glyph_count"):
            stack.enter_context(mock.patch.object(model, "glyph_count", return_value=228))
        return baseline

    def test_all_fixed_integer_metadata_rejects_equal_valued_floats(self):
        for model in MODELS:
            baseline = self.source_baseline(model)
            for path in source_integer_paths(baseline):
                with self.subTest(model=model.__name__, path=path):
                    document = copy.deepcopy(baseline)
                    owner, key = value_owner(document, path)
                    owner[key] = float(owner[key])
                    with self.assertRaises(ValueError):
                        model.validate_document(document, ROOT, "jp")

    def test_fixed_zero_and_one_metadata_rejects_booleans(self):
        for model in MODELS:
            baseline = self.source_baseline(model)
            for path in source_integer_paths(baseline):
                document = copy.deepcopy(baseline)
                owner, key = value_owner(document, path)
                if owner[key] not in (0, 1):
                    continue
                with self.subTest(model=model.__name__, path=path):
                    owner[key] = bool(owner[key])
                    with self.assertRaises(ValueError):
                        model.validate_document(document, ROOT, "jp")

    def test_named_inventories_reject_malformed_names_without_type_errors(self):
        for model, collection in NAMED:
            baseline = self.source_baseline(model)
            for name in (None, [], {}, 0, False):
                with self.subTest(model=model.__name__, name=name):
                    document = copy.deepcopy(baseline)
                    document[collection][0]["name"] = name
                    with self.assertRaises(ValueError):
                        model.validate_document(document, ROOT, "jp")

    def test_duplicate_records_are_rejected_before_staging_for_both_profiles(self):
        for model, collection in NAMED:
            for profile in ("jp", "eu"):
                with self.subTest(model=model.__name__, profile=profile):
                    baseline = self.source_baseline(model, profile)
                    document = copy.deepcopy(baseline)
                    duplicate = copy.deepcopy(document[collection][0])
                    if collection == "streams":
                        duplicate["sequences"][0][0]["glyphs"][0] ^= 1
                    document[collection].append(duplicate)
                    with self.assertRaises(ValueError):
                        model.apply_document(document, ROOT, profile, write=False)

    def test_reordering_named_records_keeps_zero_edit_documents_valid(self):
        for model, collection in NAMED:
            with self.subTest(model=model.__name__):
                document = copy.deepcopy(self.source_baseline(model))
                document[collection].reverse()
                model.validate_document(document, ROOT, "jp")

    def test_save_keeps_dirty_edits_and_writes_nothing_for_invalid_metadata(self):
        baseline = self.source_baseline(credits_text_model)
        document = copy.deepcopy(baseline)
        document["records"][0]["upper_count"] = float(document["records"][0]["upper_count"])
        writer = mock.Mock()
        window = Window.__new__(Window)
        window.project, window.profile = ROOT, "jp"
        window.context = {
            "credits_text_sequence": {
                "document": document,
                "validate": credits_text_model.validate_document,
                "write": writer,
                "path": ROOT / "unused-test-destination.json",
            }
        }
        window.state = SimpleNamespace(dirty={"credits_text_sequence"})
        window.messagebox, window.status = mock.Mock(), mock.Mock()
        window.save()
        writer.assert_not_called()
        window.messagebox.showerror.assert_called_once()
        self.assertEqual({"credits_text_sequence"}, window.state.dirty)
        window.status.configure.assert_not_called()


if __name__ == "__main__":
    unittest.main()
