"""Compile the recovered driver without a ROM, emulator, or extracted assets."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import build_z80


class Z80SourceTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        shutil.copytree(ROOT / "src/sound/z80", self.root / "src/sound/z80")
        suite = ROOT / "bin" / ("windows_i386" if os.name == "nt" else "linux_x86_64")
        self.assembler = suite / ("asw.exe" if os.name == "nt" else "asl")
        self.converter = suite / ("p2bin.exe" if os.name == "nt" else "p2bin")

    def build(self):
        return build_z80.build(self.root, self.assembler, self.converter)

    def test_source_reproduces_the_complete_independently_pinned_driver(self):
        body = self.build().read_bytes()
        self.assertEqual(3072, len(body))
        self.assertEqual(
            "42ed1d2c4133d88d36c4024ff535a710f064dcb5d791b892eb3a07f6ded6ef27", hashlib.sha256(body).hexdigest()
        )
        sources = "\n".join(path.read_text() for path in (self.root / "src/sound/z80").glob("*.asm"))
        self.assertNotIn("binclude", sources.lower())
        self.assertNotIn("    jp 93", sources)

    def test_source_instruction_edits_change_the_image_without_private_inputs(self):
        original = self.build().read_bytes()
        source = self.root / "src/sound/z80/reset_and_pcm.asm"
        source.write_text(source.read_text().replace("    di\n", "    nop\n", 1))
        changed = self.build().read_bytes()
        self.assertNotEqual(original, changed)
        self.assertEqual(b"\0" + original[1:], changed)
        self.assertFalse((self.root / "data").exists())

    def test_failed_assembly_preserves_the_last_complete_output(self):
        output = self.build()
        original = output.read_bytes()
        entry = self.root / build_z80.ENTRY
        entry.write_text(entry.read_text() + "\n    invalid_instruction\n")
        with self.assertRaises(subprocess.CalledProcessError):
            self.build()
        self.assertEqual(original, output.read_bytes())


if __name__ == "__main__":
    unittest.main()
