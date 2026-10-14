"""Public zero-edit scope controls; tiny originals, no ROM or native execution."""

from contextlib import ExitStack
import importlib
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import stage_tilemap_model as parsed


MODULES = tuple(importlib.import_module("authoring." + name) for name in (
    "level_studio_model", "graphics_studio_model", "compressed_graphics_model",
    "palette_studio_model", "mapping_studio_model", "animation_studio_model",
    "screen_map_model", "stage_map_model", "frontend_text_model",
    "japanese_glyph_model", "results_text_model", "story_text_model",
    "sound_envelope_model", "sound_instrument_model", "sound_pcm_model",
    "sound_sequence_model",
))


class ModelOperationBoundaryTests(unittest.TestCase):
    def setUp(self):
        owner = ROOT / "build/test-fixtures/model-operation-boundaries"
        owner.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(prefix="owner-", dir=owner)
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "src").mkdir()
        (self.root / "data").mkdir()
        (self.root / "src/first.s").write_bytes(b'Blob: binclude "data/blob.bin"\n')
        self.payload = self.root / "data/blob.bin"
        self.payload.write_bytes(b"one")

    def change_original(self):
        before = self.payload.stat()
        self.payload.write_bytes(b"two")
        os.utime(self.payload, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual(before.st_size, self.payload.stat().st_size)
        self.assertEqual(before.st_mtime_ns, self.payload.stat().st_mtime_ns)

    def callbacks(self, stack, module, *, final=None):
        """Replace model semantics, not the genuine parser/original-byte scope."""
        document, calls = {"sentinel": []}, []

        def export(root, profile):
            self.assertEqual((self.root, "jp"), (root, profile))
            parsed.labelled_blocks(root)
            calls.append("export")
            return document

        def validate(value, root, profile):
            self.assertIs(document, value)
            self.assertEqual((self.root, "jp"), (root, profile))
            parsed.labelled_blocks(root)
            calls.append("validate")

        def apply(value, root, profile, *, write):
            self.assertIs(document, value)
            self.assertEqual((self.root, "jp", False), (root, profile, write))
            parsed.labelled_blocks(root)
            calls.append("apply")
            if final is not None:
                final()
            return []

        stack.enter_context(mock.patch.object(module, "export_document", side_effect=export))
        stack.enter_context(mock.patch.object(module, "validate_document", side_effect=validate))
        stack.enter_context(mock.patch.object(module, "apply_document", side_effect=apply))
        return calls

    def test_each_public_round_trip_scopes_positional_and_keyword_root(self):
        for module in MODULES:
            for keyword in (False, True):
                with self.subTest(module=module.__name__, keyword=keyword), ExitStack() as stack:
                    calls = self.callbacks(stack, module)
                    parser = stack.enter_context(mock.patch.object(
                        parsed, "_parse_labelled_blocks", wraps=parsed._parse_labelled_blocks))
                    result = (module.round_trip_errors(root=self.root, profile="jp") if keyword
                              else module.round_trip_errors(self.root, "jp"))
                    self.assertEqual([], result)
                    self.assertEqual(["export", "validate", "apply"], calls)
                    self.assertEqual(1, parser.call_count)
                    self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_final_close_rejects_late_same_size_original_edit_outside_model_try(self):
        for module in MODULES:
            with self.subTest(module=module.__name__), ExitStack() as stack:
                calls = self.callbacks(stack, module, final=self.change_original)
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    module.round_trip_errors(root=self.root, profile="jp")
                self.assertEqual(["export", "validate", "apply"], calls)
                self.assertIsNone(parsed._PARSED_OPERATION.get())
            self.payload.write_bytes(b"one")

    def test_nested_same_root_retains_outer_originals_until_its_last_callback(self):
        for module in MODULES:
            with self.subTest(module=module.__name__), ExitStack() as stack:
                self.callbacks(stack, module)
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    with parsed.parsed_operation(self.root) as outer:
                        self.assertEqual([], module.round_trip_errors(self.root, "jp"))
                        self.assertIs(outer, parsed._PARSED_OPERATION.get())
                        self.assertFalse(outer.closed)
                        self.change_original()
                self.assertTrue(outer.closed)
                self.assertIsNone(parsed._PARSED_OPERATION.get())
            self.payload.write_bytes(b"one")

    def test_exception_does_not_hide_physical_drift_or_leave_a_scope_active(self):
        def fail_after_change():
            self.change_original()
            raise RuntimeError("model callback failed")

        for module in MODULES:
            with self.subTest(module=module.__name__), ExitStack() as stack:
                self.callbacks(stack, module, final=fail_after_change)
                with self.assertRaisesRegex(ValueError, "raw file changed"):
                    module.round_trip_errors(self.root, "jp")
                self.assertIsNone(parsed._PARSED_OPERATION.get())
            self.payload.write_bytes(b"one")

    def test_early_profile_refusal_remains_lazy_and_unchanged(self):
        for module in MODULES:
            with self.subTest(module=module.__name__), mock.patch.object(
                    module, "export_document", side_effect=TypeError("original profile refusal")), \
                    mock.patch.object(parsed.guarded_inventory, "capture") as capture:
                with self.assertRaisesRegex(TypeError, "original profile refusal"):
                    module.round_trip_errors(root=object(), profile="unsupported")
                capture.assert_not_called()
                self.assertIsNone(parsed._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
