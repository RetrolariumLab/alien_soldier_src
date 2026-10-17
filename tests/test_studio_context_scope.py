"""Tiny physical parser-scope controls, not model/native fidelity evidence."""
from contextlib import redirect_stdout
import io
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "scripts")]
from authoring import content_workspace, graphics_studio, level_studio
from authoring import screen_studio, sound_studio, text_studio
from authoring import stage_tilemap_model as source


STUDIOS = (level_studio, graphics_studio, screen_studio, text_studio, sound_studio)


class StudioContextScopeTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="studio-context-scope-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name) / "primary"
        self.foreign = Path(temporary.name) / "staged"
        for root in (self.root, self.foreign):
            (root / "src").mkdir(parents=True)
            (root / "data").mkdir()
            (root / "src/main.s").write_bytes(b'Blob: binclude "data/blob.bin"\n')
            (root / "data/blob.bin").write_bytes(b"\x12\x34")

    def read(self, root):
        self.assertEqual(b"\x12\x34", source.labelled_blocks(root)[0]["Blob"])

    def test_five_preparations_close_originals_before_return_without_model_result_reuse(self):
        for studio in STUDIOS:
            operations = []
            def prepare(project, profile):
                operation = source._PARSED_OPERATION.get()
                self.assertIsNotNone(operation)
                self.assertFalse(operation.closed)
                operations.append(operation)
                self.read(project)
                self.read(project)
                return {"project": project, "profile": profile}
            with self.subTest(studio=studio.__name__), \
                    mock.patch.object(studio, "_load_context", side_effect=prepare) as body:
                first = studio.load_context(self.root, "jp")
                self.assertTrue(operations[-1].closed)
                self.assertIsNone(source._PARSED_OPERATION.get())
                second = studio.load_context(self.root, "jp")
            self.assertEqual(first, second)
            self.assertIsNot(first, second)
            self.assertIsNot(operations[0], operations[1])
            self.assertTrue(all(operation.closed for operation in operations))
            self.assertEqual(2, body.call_count)
            # A later staged-tree operation gets its own genuine scope.
            with source.parsed_operation(self.foreign):
                self.read(self.foreign)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_project_keyword_arguments_enter_the_scope_and_preserve_profile(self):
        for studio in STUDIOS:
            operations = []
            def prepare(project, profile):
                operations.append(source._PARSED_OPERATION.get())
                self.read(project)
                return profile
            with self.subTest(studio=studio.__name__), \
                    mock.patch.object(studio, "_load_context", side_effect=prepare) as body:
                self.assertEqual("eu", studio.load_context(project=self.root, profile="eu"))
            body.assert_called_once_with(self.root, "eu")
            self.assertIsNotNone(operations[0])
            self.assertTrue(operations[0].closed)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_same_size_original_rewrite_with_restored_mtime_refuses_return(self):
        path = self.root / "data/blob.bin"
        original, clock = path.read_bytes(), path.stat()
        for studio in STUDIOS:
            operations = []
            def prepare(project, _profile):
                operations.append(source._PARSED_OPERATION.get())
                self.read(project)
                path.write_bytes(b"\x12\x35")
                os.utime(path, ns=(clock.st_atime_ns, clock.st_mtime_ns))
                return {"not": "a completed preparation"}
            try:
                with self.subTest(studio=studio.__name__), \
                        mock.patch.object(studio, "_load_context", side_effect=prepare), \
                        self.assertRaises(ValueError):
                    studio.load_context(self.root, "jp")
            finally:
                path.write_bytes(original)
            self.assertTrue(operations[0].closed)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_late_source_addition_refuses_return_and_restores_context(self):
        path = self.root / "src/late.s"
        for studio in STUDIOS:
            def prepare(project, _profile):
                self.read(project)
                path.write_bytes(b"Late: dc.b 7\n")
                return None
            try:
                with self.subTest(studio=studio.__name__), \
                        mock.patch.object(studio, "_load_context", side_effect=prepare), \
                        self.assertRaises(ValueError):
                    studio.load_context(self.root, "jp")
            finally:
                path.unlink(missing_ok=True)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_private_preparation_failure_still_physically_closes_both_original_trees(self):
        for studio in STUDIOS:
            def prepare(project, _profile):
                self.read(project)
                raise RuntimeError("genuine preparation exception")
            with self.subTest(studio=studio.__name__), \
                    mock.patch.object(source.guarded_inventory, "close", wraps=source.guarded_inventory.close) as close, \
                    mock.patch.object(studio, "_load_context", side_effect=prepare), \
                    self.assertRaisesRegex(RuntimeError, "genuine preparation exception"):
                studio.load_context(self.root, "jp")
            self.assertEqual({self.root / "src", self.root / "data"},
                             {call.args[0] for call in close.call_args_list})
            self.assertEqual(2, close.call_count)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_foreign_primary_root_cannot_reuse_or_replace_an_existing_scope(self):
        for studio in STUDIOS:
            with self.subTest(studio=studio.__name__), source.parsed_operation(self.root) as operation, \
                    mock.patch.object(studio, "_load_context") as body:
                with self.assertRaisesRegex(ValueError, "mix preservation roots"):
                    studio.load_context(self.foreign, "jp")
                body.assert_not_called()
                self.assertIs(operation, source._PARSED_OPERATION.get())
                self.assertFalse(operation.closed)
            self.assertTrue(operation.closed)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_workspace_validation_keyword_scope_closes_and_rejects_late_original_drift(self):
        manifest = {"artifacts": []}
        path = self.root / "data/blob.bin"
        operations = []
        for mutate in (False, True):
            def load(root, actual_manifest, profile):
                self.assertIs(manifest, actual_manifest)
                self.assertEqual("jp", profile)
                operations.append(source._PARSED_OPERATION.get())
                self.read(root)
                if mutate:
                    path.write_bytes(b"\x12\x35")
                return {}
            try:
                with self.subTest(mutate=mutate), \
                        mock.patch.object(content_workspace, "load_workspace", side_effect=load) as body, \
                        redirect_stdout(io.StringIO()):
                    if mutate:
                        with self.assertRaises(ValueError):
                            content_workspace.validate_workspace(root=self.root, manifest=manifest, profile="jp")
                    else:
                        self.assertIsNone(content_workspace.validate_workspace(
                            root=self.root, manifest=manifest, profile="jp"))
                body.assert_called_once_with(self.root, manifest, "jp")
                self.assertIsNotNone(operations[-1])
                self.assertTrue(operations[-1].closed)
                self.assertIsNone(source._PARSED_OPERATION.get())
            finally:
                path.write_bytes(b"\x12\x34")


if __name__ == "__main__":
    unittest.main()
