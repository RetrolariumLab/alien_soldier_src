"""Physical CLI read lifetimes; format and codec callbacks are explicit seams."""
from collections import defaultdict
from contextlib import redirect_stdout, redirect_stderr
import importlib
import io
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import stage_tilemap_model as parsed

MODELS = (
    "animation_studio", "compressed_graphics", "frontend_text", "graphics_studio",
    "japanese_glyph", "level_studio", "mapping_studio", "palette_studio",
    "results_text", "screen_map", "sound_envelope", "sound_instrument",
    "sound_pcm", "sound_sequence", "stage_map", "story_text",
)
STDOUT_ERRORS = frozenset((
    "animation_studio", "compressed_graphics", "graphics_studio", "level_studio",
    "mapping_studio", "palette_studio",
))


class ModelCliReadScopeTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="model-cli-read-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "src").mkdir()
        (self.root / "data").mkdir()
        self.source = self.root / "src/main.s"
        self.source.write_bytes(b"Value: dc.b 1\n")

    def invoke(self, module, *, errors=(), mutate=False):
        operations, calls = [], []
        def check(root, profile):
            self.assertEqual((self.root, "jp"), (root, profile))
            operation = parsed._PARSED_OPERATION.get()
            self.assertIsNotNone(operation)
            operations.append(operation)
            calls.append("round-trip")
            self.assertEqual(b"\x01", parsed.labelled_blocks(root)[0]["Value"])
            return list(errors)
        def export(root, profile):
            self.assertEqual((self.root, "jp"), (root, profile))
            self.assertIs(operations[-1], parsed._PARSED_OPERATION.get())
            self.assertEqual(b"\x01", parsed.labelled_blocks(root)[0]["Value"])
            calls.append("summary-export")
            if mutate:
                before = self.source.stat()
                self.source.write_bytes(b"Value: dc.b 2\n")
                os.utime(self.source, ns=(before.st_atime_ns, before.st_mtime_ns))
            return defaultdict(int, spawn_lists=[])
        output, stderr = io.StringIO(), io.StringIO()
        actual_print = print
        def closed_print(*args, **kwargs):
            self.assertIsNone(parsed._PARSED_OPERATION.get())
            self.assertTrue(all(operation.closed for operation in operations))
            return actual_print(*args, **kwargs)
        with mock.patch.object(sys, "argv", [module.__file__, "check", "--root",
                str(self.root), "--profile", "jp"]), mock.patch.object(
                module, "round_trip_errors", side_effect=check), mock.patch.object(
                module, "export_document", side_effect=export), mock.patch(
                "builtins.print", side_effect=closed_print), redirect_stdout(output), redirect_stderr(stderr):
            code = module.main()
        self.assertIsNone(parsed._PARSED_OPERATION.get())
        self.assertTrue(all(operation.closed for operation in operations))
        return code, calls, output.getvalue(), stderr.getvalue(), operations

    def test_all_sixteen_cli_checks_share_only_inputs_and_repeat_both_callbacks(self):
        for name in MODELS:
            module = importlib.import_module("authoring." + name + "_model")
            with self.subTest(model=name), mock.patch.object(
                    parsed, "_parse_labelled_blocks", wraps=parsed._parse_labelled_blocks) as parse:
                first = self.invoke(module)
                second = self.invoke(module)
                self.assertEqual(2, parse.call_count)
                self.assertIsNot(first[4][0], second[4][0])
                for code, calls, stdout, stderr, _ in (first, second):
                    self.assertEqual(0, code)
                    self.assertEqual(["round-trip", "summary-export"], calls)
                    self.assertIn("[OK]", stdout)
                    self.assertEqual("", stderr)

    def test_each_round_trip_failure_closes_before_error_and_never_exports_summary(self):
        for name in MODELS:
            with self.subTest(model=name):
                module = importlib.import_module("authoring." + name + "_model")
                code, calls, stdout, stderr, _ = self.invoke(module, errors=("first", "second"))
                self.assertEqual(1, code)
                self.assertEqual(["round-trip"], calls)
                self.assertNotIn("[OK]", stdout)
                self.assertNotIn("[OK]", stderr)
                error, other = (stdout, stderr) if name in STDOUT_ERRORS else (stderr, stdout)
                self.assertIn("[ERROR] first; second", error)
                self.assertEqual("", other)

    def test_each_late_summary_rewrite_refuses_before_any_success_message(self):
        for name in MODELS:
            with self.subTest(model=name):
                self.source.write_bytes(b"Value: dc.b 1\n")
                module = importlib.import_module("authoring." + name + "_model")
                code, calls, stdout, stderr, _ = self.invoke(module, mutate=True)
                self.assertEqual(1, code)
                self.assertEqual(["round-trip", "summary-export"], calls)
                self.assertNotIn("[OK]", stdout)
                self.assertNotIn("[OK]", stderr)
                error, other = (stdout, stderr) if name in STDOUT_ERRORS else (stderr, stdout)
                self.assertIn("raw file changed", error)
                self.assertEqual("", other)


if __name__ == "__main__":
    unittest.main()
