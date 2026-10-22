from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class HBlankFixedCopyTests(unittest.TestCase):
    def test_three_load_func_descriptors_copy_fixed_rom_spans(self) -> None:
        source = (ROOT / "src/rendering/hblank_effects.s").read_text(encoding="utf-8")
        loader = (ROOT / "src/gameplay/object_data.s").read_text(encoding="utf-8")
        self.assertRegex(loader, r"LoadObjDataHandlers:\s+dc\.l\s+LoadFuncToRAM")
        copy = loader.split("LoadFuncToRAM:", 1)[1].split("; End of function LoadFuncToRAM", 1)[0]
        for instruction in (
            "move.w  (a1)+,d1",
            "lsr.w   #2,d1",
            "subq.w  #1,d1",
            "move.l  (a1)+,(a2)+",
            "dbf     d1,Data_CopyFunctionLoop",
        ):
            self.assertIn(instruction, copy)

        audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        cases = (
            (
                "HBlank_ApplyEpsilon1VScrollAndPlaneMode",
                "0x0019CC",
                "0x0019D6",
            ),
            ("HBlank_ApplyZLeoRasterCommands", "0x001B6E", "0x001B78"),
            ("HBlank_SetWindowPositionAfterDelay", "0x001C6C", "0x001C76"),
        )
        basis = (
            "LoadFuncToRAM reads this $200 source word as a byte count and "
            "copies 512 bytes starting at the following ROM byte to RAM "
            "$FFFFEE00; RTE does not terminate the fixed copy."
        )
        self.assertEqual(
            [length for _, _, length in cases],
            [member["address"] for member in reviews[basis]["members"]],
        )
        for prefix, list_address, length_address in cases:
            with self.subTest(prefix=prefix):
                list_label = prefix + "_InstallList"
                length_label = prefix + "_CopyLength"
                section = source.split(list_label + ":", 1)[1].split(length_label + ":", 1)[0]
                self.assertRegex(section, r"\bdc\.w\s+0\b")
                self.assertIn(f"dc.l    {length_label}", section)
                self.assertRegex(section, r"\bdc\.w\s+\$EE00\b")
                self.assertRegex(section, r"\bdc\.w\s+\$FFFF\b")
                length_data = source.split(length_label + ":", 1)[1]
                self.assertRegex(length_data, r"^\s+dc\.w\s+\$200\b")
                self.assertIn("fixed span", audit[list_address]["basis"][0])
                self.assertIn(basis, audit[length_address]["basis"])

        for (_, _, source_word), (_, next_list, _) in zip(cases, cases[1:]):
            start = int(source_word, 16) + 2
            self.assertLess(start, int(next_list, 16))
            self.assertLess(int(next_list, 16), start + 0x200)

    def test_story_and_pair_descriptors_each_request_fixed_40_byte_copy(self) -> None:
        basis = "This descriptor field supplies the 0x40-byte copy length for the following HBlank code block."
        reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        self.assertEqual(
            ["0x0016F0", "0x00176E"],
            [member["address"] for member in reviews[basis]["members"]],
        )
        source = (ROOT / "src/rendering/vblank_effects.s").read_text(encoding="utf-8")
        for owner in ("HBlank_UpdateStoryDisplay", "HBlank_WriteVScrollPair"):
            with self.subTest(owner=owner):
                length = owner + "_CopyLength"
                descriptor = source.split(owner + "_InstallList:", 1)[1].split(length + ":", 1)[0]
                self.assertIn(f"dc.l    {length}", descriptor)
                self.assertIn("dc.w    $EE00", descriptor)
                self.assertRegex(source.split(length + ":", 1)[1], r"^\s+dc\.w\s+\$40\b")
                self.assertIn(owner + ":", source)


if __name__ == "__main__":
    unittest.main()
