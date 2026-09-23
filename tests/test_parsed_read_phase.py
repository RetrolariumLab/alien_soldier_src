"""Tiny physical read-phase admission and legacy fallback controls."""

import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import stage_tilemap_model as model


class ParsedReadPhaseTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="parsed-read-phase-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        (self.root / "src").mkdir()
        self.source = self.root / "src/main.s"
        self.source.write_bytes(b"Value: dc.b 1\n")

    def test_source_only_tree_stays_genuinely_fresh_without_invented_owner(self):
        with mock.patch.object(model, "_parse_labelled_blocks", wraps=model._parse_labelled_blocks) as parse:
            with model.parsed_read_phase(self.root) as operation:
                # Identity-only checkpoints do not request corpus admission.
                self.assertIs(operation, model._read_operation(self.root, create=False))
                self.assertEqual(b"\x01", model.labelled_blocks(self.root)[0]["Value"])
                self.source.write_bytes(b"Value: dc.b 2\n")
                self.assertEqual(b"\x02", model.labelled_blocks(self.root)[0]["Value"])
                self.assertEqual((), operation._owners)
                self.assertIs(operation, model._read_operation(self.root, create=False))
                self.assertEqual(2, parse.call_count)
        self.assertFalse((self.root / "data").exists())
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_admitted_originals_never_fall_back_when_the_owner_disappears(self):
        (self.root / "data").mkdir()
        with self.assertRaisesRegex(ValueError, "missing"), mock.patch.object(
                model, "_parse_labelled_blocks", wraps=model._parse_labelled_blocks) as parse:
            with model.parsed_read_phase(self.root):
                model.labelled_blocks(self.root)
                (self.root / "data").rmdir()
                model.labelled_blocks(self.root)
                self.assertEqual(1, parse.call_count)
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_absence_does_not_hide_an_unsafe_existing_owner(self):
        (self.root / "data").write_bytes(b"not a directory")
        with self.assertRaisesRegex(ValueError, "not a directory"):
            with model.parsed_read_phase(self.root):
                model.labelled_blocks(self.root)
        self.assertIsNone(model._PARSED_OPERATION.get())
        (self.root / "data").unlink()
        actual = model.guarded_inventory._checked_stat
        def unsafe_after_missing(path):
            if path == self.root / "src":
                raise FileNotFoundError(str(path))
            if path == self.root / "data":
                raise ValueError("source/owner path crosses a link/reparse point")
            return actual(path)
        with mock.patch.object(model.guarded_inventory, "_checked_stat", side_effect=unsafe_after_missing):
            with self.assertRaisesRegex(ValueError, "link/reparse"):
                with model.parsed_read_phase(self.root):
                    model.labelled_blocks(self.root)
        self.assertIsNone(model._PARSED_OPERATION.get())

    def test_existing_primary_and_foreign_reads_keep_the_original_scope_and_close(self):
        (self.root / "data").mkdir()
        foreign = self.root / "build/staged"
        (foreign / "src").mkdir(parents=True)
        source = foreign / "src/main.s"
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            with model.parsed_operation(self.root) as outer:
                model.labelled_blocks(self.root)
                with model.parsed_read_phase(self.root) as same:
                    self.assertIs(same, outer)
                for value in (3, 4):
                    source.write_bytes(("Value: dc.b %d\n" % value).encode())
                    with model.parsed_read_phase(foreign) as active:
                        self.assertIs(active, outer)
                        self.assertEqual(bytes([value]), model.labelled_blocks(foreign)[0]["Value"])
                self.assertFalse(outer.closed)
                self.assertEqual(b"\x01", model.labelled_blocks(self.root)[0]["Value"])
                before = self.source.stat()
                self.source.write_bytes(b"Value: dc.b 2\n")
                os.utime(self.source, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertTrue(outer.closed)
        self.assertIsNone(model._PARSED_OPERATION.get())
        with model.parsed_read_phase(self.root):
            self.assertEqual(b"\x02", model.labelled_blocks(self.root)[0]["Value"])

    def test_source_only_fallback_never_bypasses_closed_or_foreign_pid_lifetime(self):
        for invalid in ("closed", "pid"):
            with self.subTest(invalid=invalid), model.parsed_operation(self.root) as active:
                original_pid = active.pid
                if invalid == "closed":
                    active.closed = True
                else:
                    active.pid += 1
                try:
                    with self.assertRaisesRegex(ValueError, "closed or outside"), mock.patch.object(
                            model, "_parse_labelled_blocks") as parse:
                        model.labelled_blocks(self.root)
                    parse.assert_not_called()
                finally:
                    active.closed, active.pid = False, original_pid


if __name__ == "__main__":
    unittest.main()
