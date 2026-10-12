from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import extract_symbols  # noqa: E402


class ExtractSymbolsTests(unittest.TestCase):
    def extract(self, listing: str, *, resolved_only=False) -> dict[int, str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "main.lst"
            path.write_text(listing, encoding="latin-1")
            return extract_symbols.extract_symbols(path, resolved_only=resolved_only)

    def test_included_labels_data_and_equates(self) -> None:
        symbols = self.extract(
            "\n".join(
                [
                    "(1)    7/     200 :                     Reset: rts",
                    "(1)    8/     202 : 4E75                loc_202: rts",
                    "(1)    9/       0 : =$FFFFA284           GameModeIndex equ $FFFFA284",
                    "(1)   10/       0 : =0                   ZERO_FLAG equ $0",
                    "      11/     204 :                     MainFileLabel: rts",
                ]
            )
        )
        self.assertEqual("Reset", symbols[0x200])
        self.assertEqual("loc_202", symbols[0x202])
        self.assertEqual("MainFileLabel", symbols[0x204])
        self.assertEqual("GameModeIndex", symbols[0xFFA284])
        self.assertNotIn(0, symbols)

    def test_reviewed_alias_wins_at_same_address(self) -> None:
        symbols = self.extract(
            "\n".join(
                [
                    "(1)    1/   2B6D4 :                     sub_2B6D4:",
                    "(1)    2/   2B6D4 :                     Object_UpdateProximityPickupEmitterType48:",
                ]
            )
        )
        self.assertEqual("Object_UpdateProximityPickupEmitterType48", symbols[0x2B6D4])

    def test_default_filter_excludes_address_derived_names(self) -> None:
        symbols = {
            0x200: "Reset",
            0x202: "loc_202",
            0x204: "word_204",
            0xFFFFA284: "GameModeIndex",
        }
        self.assertEqual(
            {0x200: "Reset", 0xFFFFA284: "GameModeIndex"},
            extract_symbols.filter_symbols(symbols),
        )

    def test_resolved_filter_runs_before_canonical_alias_selection(self):
        listing = ("(1)    1/     200 :".ljust(40) + "InactiveReviewedAlias:\n"
                   + "(1)    2/     200 :".ljust(40) + "sub_200:\n"
                   + "(1)    3/     200 :".ljust(40) + "Reset:\n"
                   + "Symbol Table (* = unused):\n SUB_200 : 200 C | RESET : 200 C |\n")
        self.assertEqual({0x200: "InactiveReviewedAlias"}, self.extract(listing))
        self.assertEqual({0x200: "Reset"}, self.extract(listing, resolved_only=True))

    def test_strict_export_rejects_missing_table_conflicts_and_wrong_row_address(self):
        label = "(1)    1/     200 :".ljust(40) + "Reset:\n"
        for table in ("", "Symbol Table (* = unused):\n RESET : 202 C |\n",
                      "Symbol Table (* = unused):\n RESET : 200 C | RESET : 202 C |\n"):
            with self.subTest(table=table), self.assertRaises(ValueError):
                self.extract(label + table, resolved_only=True)

    def test_strict_aliases_keep_actual_RAM_bus_addresses(self):
        listing = ("(1)    1/       0 : =$FFFFA284".ljust(40) + "GameModeIndex equ $FFFFA284\n"
                   + "Symbol Table (* = unused):\n GAMEMODEINDEX : FFFFA284 I |\n")
        self.assertEqual({0xFFA284: "GameModeIndex"}, self.extract(listing, resolved_only=True))

    def test_source_or_comment_symbol_table_spoof_is_ignored_before_real_boundary(self):
        listing = ("(1)    1/     200 :".ljust(40) + "Reset:\n"
                   + "(1)    2/     200 :".ljust(40) + "; RESET : 202 C |\n"
                   + " RESET : 202 C |\n"
                   + "Symbol Table (* = unused):\n RESET : 200 C |\n")
        self.assertEqual({0x200: "Reset"}, self.extract(listing, resolved_only=True))

    def test_combined_strict_views_read_one_body_without_reopening(self):
        listing = ("(1)    1/     200 :".ljust(40) + "Reset:\n"
                   + "Symbol Table (* = unused):\n RESET : 200 C |\n")
        with patch.object(Path, "read_text", autospec=True, return_value=listing) as read:
            resolved, addressed = extract_symbols.read_listing_symbols(Path("fresh.lst"))
        self.assertEqual({"RESET": 0x200}, resolved)
        self.assertEqual({0x200: "Reset"}, addressed)
        read.assert_called_once_with(Path("fresh.lst"), encoding="latin-1")

    def test_combined_strict_views_do_not_cache_a_previous_file_verdict(self):
        label = "(1)    1/     200 :".ljust(40) + "Reset:\n"
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "fresh.lst"
            path.write_text(label + "Symbol Table (* = unused):\n RESET : 200 C |\n", encoding="latin-1")
            self.assertEqual({"RESET": 0x200}, extract_symbols.read_listing_symbols(path)[0])
            path.write_text(label + "Symbol Table (* = unused):\n RESET : 202 C |\n", encoding="latin-1")
            with self.assertRaisesRegex(ValueError, "source row differs"):
                extract_symbols.read_listing_symbols(path)


if __name__ == "__main__":
    unittest.main()
