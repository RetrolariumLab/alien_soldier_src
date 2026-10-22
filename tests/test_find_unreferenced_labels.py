from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import find_unreferenced_labels  # noqa: E402


class FindUnreferencedLabelsTests(unittest.TestCase):
    def test_counts_cross_module_and_include_references(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "src"
            source.mkdir()
            (source / "main.s").write_text(
                '                include "src/refs.inc"\n'
                '                include "src/first.s"\n'
                '                include "src/second.s"\n',
                encoding="utf-8",
            )
            (source / "refs.inc").write_text("                dc.l FromInc\n", encoding="utf-8")
            (source / "first.s").write_text(
                "Shared:\n                rts\n"
                "FromInc:\n                rts\n"
                "Unused:\n                rts\n"
                'Asset: binclude "data/Unused.bin" ; Shared\n'
                "Unused_End:\n",
                encoding="utf-8",
            )
            (source / "second.s").write_text("                jsr Shared\n", encoding="utf-8")

            records = find_unreferenced_labels.find_unreferenced_labels(source / "main.s")

            self.assertEqual({"Unused", "Asset"}, {name for name, *_ in records})
            self.assertTrue(all(module.endswith("first.s") for _, module, *_ in records))

    def test_comment_marker_inside_literal_is_not_a_comment(self) -> None:
        self.assertIn(
            "Unused",
            find_unreferenced_labels.strip_comment('dc.b "text; part",Unused ; comment'),
        )


if __name__ == "__main__":
    unittest.main()
