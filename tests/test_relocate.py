import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from scripts import relocate


class ReturnsTests(unittest.TestCase):
    def test_returns_double_and_table_slots_and_skipped_modules_stay(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src" / "sound").mkdir(parents=True)
            (root / "src" / "code.s").write_text(
                "First:\n                rts\nSecond:\n                rts\n"
                "Table:\n                rts\n                bra.s   First\n",
                encoding="utf-8",
            )
            skipped = sorted(relocate.SKIPPED)[0]
            (root / skipped).parent.mkdir(parents=True, exist_ok=True)
            (root / skipped).write_text("Skipped:\n                rts\nAfter:\n", encoding="utf-8")
            (root / "src" / "main.s").write_text(
                f'                include "src/code.s"\n                include "{skipped}"\n', encoding="utf-8"
            )
            inserted, modules = relocate.write_copy(root, root / "build" / "relocated")
            self.assertEqual((inserted, modules), (2, 1))
            main = (root / "build" / "relocated" / "main.s").read_text(encoding="utf-8")
            self.assertIn('include "build/relocated/src__code.s"', main)
            self.assertIn(f'include "{skipped}"', main)
            code = (root / "build" / "relocated" / "src__code.s").read_text(encoding="utf-8")
            self.assertEqual(code.count("rts"), 5)
            self.assertIn("Table:\n                rts\n                bra.s", code)


class ChecksumTests(unittest.TestCase):
    def test_the_header_gets_the_sum_of_the_revision_s_range(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            profile = root / "game_profile.json"
            profile.write_text(json.dumps({"source": {"revisions": {"jp": {"checksum": ["0x200", "0x204"]}}}}))
            image = root / "image.bin"
            data = bytearray(0x300)
            data[0x200:0x204] = bytes((0x12, 0x34, 0xFF, 0xFF))
            data[0x204:0x206] = bytes((0x55, 0x55))
            image.write_bytes(bytes(data))
            with mock.patch.object(relocate, "PROFILE", profile):
                self.assertEqual(relocate.finish(image, "jp"), 0x1233)
            self.assertEqual(image.read_bytes()[0x18E:0x190], bytes((0x12, 0x33)))


if __name__ == "__main__":
    unittest.main()
