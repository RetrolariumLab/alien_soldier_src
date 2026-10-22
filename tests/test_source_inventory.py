from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import source_inventory  # noqa: E402


class SourceInventoryTests(unittest.TestCase):
    def test_procedure_provenance_and_generic_container_are_reported(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "src" / "boss_code_12345.s"
            path.parent.mkdir(parents=True)
            path.write_text(
                "Boss_TestMain:\n"
                "                rts                             ; was: sub_12345\n"
                "loc_1234A:\n"
                "                bra.s   loc_1234A\n",
                encoding="utf-8",
            )
            item = source_inventory.inspect_module(
                root,
                {
                    "file": "src/boss_code_12345.s",
                    "subsystem": "bosses",
                    "start": "0x12345",
                    "end": "0x12349",
                },
            )
        self.assertEqual(4, item["lines"])
        self.assertEqual(2, item["definitions"])
        self.assertEqual(1, item["address_derived_definitions"])
        self.assertEqual(1, item["provenance_procedures"])
        self.assertTrue(item["generic_container_name"])
        self.assertEqual("Boss_TestMain", item["procedure_anchors"][0]["name"])

    def test_listing_symbols_read_included_definition_rows(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "main.lst"
            path.write_text(
                "(1)    7/     200 :                     Reset: rts\n",
                encoding="latin-1",
            )
            symbols = source_inventory.listing_symbols(path)
        self.assertEqual({"Reset": 0x200}, symbols)

    def test_semantic_hex_letters_do_not_look_like_an_address_suffix(self) -> None:
        self.assertIsNone(source_inventory.GENERIC_CONTAINER.search("palette_fades"))
        self.assertIsNotNone(source_inventory.GENERIC_CONTAINER.search("stage_systems_0d714"))


if __name__ == "__main__":
    unittest.main()
