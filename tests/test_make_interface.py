"""Literal Make graph controls and actual public help, without ROM/native work."""
from pathlib import Path
import shutil
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from make_interface import make_digest, make_files, make_text, public_targets


class MakeInterfaceControls(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def write(self, relative, body):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")

    def test_nested_literal_graph_has_one_owner_and_original_reader(self):
        self.write("Makefile", "all: build\ninclude mk/build.mk\n")
        self.write("mk/build.mk", "include mk/identity.mk\nbuild:\n\t@echo build\n")
        self.write("mk/identity.mk", "verify:\n\t@echo verify\n")
        reads = []
        def original(relative):
            reads.append(relative)
            return (self.root / relative).read_bytes()
        files = make_files(self.root, original)
        self.assertEqual(["Makefile", "mk/build.mk", "mk/identity.mk"], reads)
        self.assertEqual(reads, [name for name, _body in files])
        self.assertIn("verify:\n\t@echo verify", make_text(self.root))

    def test_missing_optional_dynamic_escaping_and_cyclic_includes_are_rejected(self):
        for directive in ("include absent.mk", "-include absent.mk", "sinclude absent.mk",
                          "include $(DYNAMIC)", "include ../outside.mk", "include /outside.mk",
                          "include mk/*.mk", "include Makefile"):
            self.write("Makefile", "all:\n" + directive + "\n")
            with self.subTest(directive=directive), self.assertRaises(ValueError):
                make_files(self.root)
        self.write("Makefile", "all:\ninclude mk/one.mk mk/one.mk\n")
        self.write("mk/one.mk", "one:\n")
        with self.assertRaisesRegex(ValueError, "repeated or cyclic"):
            make_files(self.root)

    def test_digest_binds_names_order_and_every_fragment_with_only_line_end_equivalence(self):
        rows = (("Makefile", b"all:\ninclude mk/build.mk\n"), ("mk/build.mk", b"build:\n\t@echo build\n"))
        original = make_digest(rows)
        self.assertEqual(original, make_digest(tuple((name, body.replace(b"\n", b"\r\n")) for name, body in rows)))
        for changed in (rows[::-1], (rows[0], ("mk/other.mk", rows[1][1])),
                        (rows[0], (rows[1][0], rows[1][1] + b"# changed\n")),
                        ((rows[0][0], rows[0][1] + b"x"), rows[1])):
            self.assertNotEqual(original, make_digest(changed))

    def test_bounds_and_redirected_fragment_are_rejected(self):
        from unittest import mock
        self.write("Makefile", "all:\ninclude mk/build.mk\n")
        self.write("mk/build.mk", "build:\n")
        with mock.patch("make_interface.MAX_BYTES", 1), self.assertRaisesRegex(ValueError, "byte bound"):
            make_files(self.root)
        with mock.patch("make_interface.MAX_FILES", 1), self.assertRaisesRegex(ValueError, "file bound"):
            make_files(self.root)
        selected = self.root / "mk/build.mk"
        real = Path.is_symlink
        with mock.patch.object(Path, "is_symlink", lambda path: path == selected or real(path)):
            with self.assertRaisesRegex(ValueError, "redirected"):
                make_files(self.root)

    def test_real_help_covers_every_public_target_and_default_remains_all(self):
        make = shutil.which("make")
        self.assertIsNotNone(make)
        help_result = subprocess.run([make, "--no-print-directory", "help", "PYTHON=" + sys.executable],
                                     cwd=ROOT, capture_output=True, text=True, timeout=30)
        self.assertEqual(0, help_result.returncode, help_result.stderr)
        inventory = public_targets(ROOT)
        self.assertGreater(len(inventory), 1)
        for owner, targets in inventory.items():
            self.assertIn("  " + owner + ": " + ", ".join(targets), help_result.stdout)
        database = subprocess.run([make, "--no-print-directory", "-np", "profile-info"],
                                  cwd=ROOT, capture_output=True, text=True, timeout=30)
        self.assertEqual(0, database.returncode, database.stderr)
        self.assertIn(".DEFAULT_GOAL := all", database.stdout)
        self.assertNotIn(".PHONY", {target for targets in inventory.values() for target in targets})
        logical = make_text(ROOT).replace("\\\n", " ")
        phony = {target for row in re.findall(r"^\.PHONY:[ \t]*(.*)$", logical, re.M) for target in row.split()}
        self.assertEqual(set(), {target for targets in inventory.values() for target in targets} - phony)


if __name__ == "__main__":
    unittest.main()
