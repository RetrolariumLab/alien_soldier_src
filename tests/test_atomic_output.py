"""Atomic authoring saves must not write through a predictable temporary."""

from __future__ import annotations

import importlib
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.atomic_output import (  # noqa: E402
    atomic_write_bytes,
    atomic_write_json,
    atomic_write_text,
)


WRITERS = {
    "content_workspace": False,
    "level_studio_model": False,
    "graphics_studio_model": False,
    "ram_map_workspace": False,
    "credits_text_model": True,
    "sound_pcm_model": True,
}


class AtomicOutputTests(unittest.TestCase):
    def test_json_bytes_keep_the_existing_ascii_modes_and_final_lf(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for ensure_ascii in (False, True):
                with self.subTest(ensure_ascii=ensure_ascii):
                    path = Path(directory) / ("mode_%d.json" % ensure_ascii)
                    atomic_write_json(path, {"glyph": "é"}, ensure_ascii=ensure_ascii)
                    self.assertEqual(
                        (json.dumps({"glyph": "é"}, indent=2, ensure_ascii=ensure_ascii) + "\n").encode("utf-8"),
                        path.read_bytes(),
                    )

    def test_staged_text_and_binary_bytes_are_not_newline_translated(self) -> None:
        from authoring.level_studio_model import (
            atomic_write_bytes as write_level_bytes,
            atomic_write_text as write_level_text,
        )

        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            text_path = folder / "stage.s"
            binary_path = folder / "stage.bin"
            fixed_text = folder / "stage.s.tmp"
            fixed_binary = folder / "stage.bin.tmp"
            fixed_text.write_bytes(b"other text")
            fixed_binary.write_bytes(b"other binary")
            source = "label:\r\n    dc.w $00E9\n; é\n"
            payload = bytes((0, 255, 13, 10))
            atomic_write_text(text_path, source)
            write_level_text(text_path, source)
            write_level_bytes(binary_path, payload)
            self.assertEqual(source.encode("utf-8"), text_path.read_bytes())
            self.assertEqual(payload, binary_path.read_bytes())
            self.assertEqual(b"other text", fixed_text.read_bytes())
            self.assertEqual(b"other binary", fixed_binary.read_bytes())

    def test_studio_writers_leave_an_existing_fixed_tmp_alone(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for module_name, ensure_ascii in WRITERS.items():
                with self.subTest(module=module_name):
                    folder = Path(directory) / module_name
                    folder.mkdir()
                    path = folder / "document.json"
                    sentinel = path.with_suffix(".json.tmp")
                    sentinel.write_bytes(b"another output")
                    writer = importlib.import_module("authoring." + module_name).atomic_write_json
                    writer(path, {"glyph": "é"})
                    self.assertEqual(b"another output", sentinel.read_bytes())
                    self.assertEqual(
                        (json.dumps({"glyph": "é"}, indent=2, ensure_ascii=ensure_ascii) + "\n").encode("utf-8"),
                        path.read_bytes(),
                    )

    def test_fixed_tmp_symlink_cannot_redirect_a_document_save(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            protected = folder / "protected.json"
            protected.write_bytes(b"keep")
            target = folder / "document.json"
            try:
                os.symlink(protected, folder / "document.json.tmp")
            except OSError as error:
                self.skipTest("file symlinks are unavailable: %s" % error)
            atomic_write_json(target, {"value": 1})
            self.assertEqual(b"keep", protected.read_bytes())
            self.assertEqual({"value": 1}, json.loads(target.read_text("utf-8")))

    def test_failed_replace_removes_only_its_new_temporary(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            target = folder / "document.bin"
            target.write_bytes(b"old")
            with mock.patch("authoring.atomic_output.os.replace", side_effect=OSError("replace failed")):
                with self.assertRaisesRegex(OSError, "replace failed"):
                    atomic_write_bytes(target, b"new")
            self.assertEqual(b"old", target.read_bytes())
            self.assertEqual(["document.bin"], sorted(path.name for path in folder.iterdir()))

    def test_all_studio_json_writers_delegate_to_the_exclusive_writer(self) -> None:
        paths = [
            path
            for path in (ROOT / "scripts/authoring").glob("*.py")
            if path.name != "atomic_output.py" and "def atomic_write_json(" in path.read_text(encoding="utf-8")
        ]
        self.assertEqual(20, len(paths))
        for path in paths:
            with self.subTest(path=path.name):
                source = path.read_text(encoding="utf-8")
                start = source.index("def atomic_write_json(")
                end = source.find("\n\ndef ", start + 1)
                body = source[start : end if end >= 0 else None]
                self.assertIn("from authoring.atomic_output import atomic_write_json as _write_json", body)
                self.assertIn("_write_json(path, document, ensure_ascii=", body)
                self.assertNotIn("with_suffix(path.suffix", body)

    def test_no_authoring_output_uses_a_fixed_tmp_suffix(self) -> None:
        for path in (ROOT / "scripts/authoring").glob("*.py"):
            with self.subTest(path=path.name):
                source = path.read_text(encoding="utf-8")
                self.assertNotIn('with_suffix(path.suffix + ".tmp")', source)
                self.assertNotIn('with_suffix(target.suffix + ".tmp")', source)
                self.assertNotIn('with_suffix(output.suffix + ".tmp")', source)
                self.assertNotIn('with_suffix(destination.suffix + ".tmp")', source)
                self.assertNotIn('with_suffix(source_path.suffix + ".tmp")', source)


if __name__ == "__main__":
    unittest.main()
