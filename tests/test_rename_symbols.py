from __future__ import annotations

import re
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import rename_symbols  # noqa: E402


class RenameSymbolsTests(unittest.TestCase):
    def test_preserves_provenance_while_renaming_live_references(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "module.s"
            source.write_text(
                "Old:  ; was: sub_1234\n"
                "                jsr Old\n"
                '                dc.b "text; was: Old",Old  ; was: Old\n'
                "Another:  ; was: Old\n",
                encoding="utf-8",
            )

            replaced, annotated = rename_symbols.apply_renames([source], [("Old", "New")], provenance=True)

            self.assertEqual(3, replaced)
            self.assertEqual(0, annotated)
            self.assertEqual(
                "New:  ; was: sub_1234\n"
                "                jsr New\n"
                '                dc.b "text; was: Old",New  ; was: Old\n'
                "Another:  ; was: Old\n",
                source.read_text(encoding="utf-8"),
            )

    def test_provenance_marker_in_quoted_literal_is_not_a_comment(self) -> None:
        line = 'Old: dc.b "text; was: Old",Old  ; was: sub_1234'
        self.assertEqual(
            line.rfind("; was:"),
            rename_symbols.provenance_start(line),
        )

    def test_replaces_symbols_but_preserves_quoted_asset_paths(self) -> None:
        mapping = {"word_1234": "Demo_InputStream"}
        pattern = re.compile(r"\b(word_1234)\b")
        line = 'word_1234: binclude "data/word_1234.bin" ; word_1234'

        renamed, count = rename_symbols.substitute_unquoted(line, pattern, mapping)

        self.assertEqual(
            'Demo_InputStream: binclude "data/word_1234.bin" ; Demo_InputStream',
            renamed,
        )
        self.assertEqual(2, count)

    def test_preserves_single_quoted_assembly_constants(self) -> None:
        mapping = {"SEGA": "Renamed"}
        pattern = re.compile(r"\b(SEGA)\b")

        renamed, count = rename_symbols.substitute_unquoted("move.l #'SEGA',SEGA", pattern, mapping)

        self.assertEqual("move.l #'SEGA',Renamed", renamed)
        self.assertEqual(1, count)


if __name__ == "__main__":
    unittest.main()
