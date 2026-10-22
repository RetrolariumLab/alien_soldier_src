from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class MedusaWormEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }

    def test_medusa_pose_entry_worker_and_four_part_helper(self) -> None:
        source = (ROOT / "src/bosses/medusa.s").read_text(encoding="utf-8")
        entry = source.split("Boss_RenderMedusaPose:", 1)[1].split("; End of function Boss_RenderMedusaPose", 1)[0]
        self.assertIn("bsr.w   Boss_UpdateMedusaPoseScript", entry)
        self.assertIn("bsr.w   Boss_ApplyMedusaPoseToParts", entry)
        self.assertIn("moveq   #$13,d7", entry)
        self.assertIn("jmp     Sprite_BeginMetaspritePartTraversal", entry)

        worker = source.split("Boss_ApplyMedusaPoseToParts:", 1)[1].split(
            "; End of function Boss_ApplyMedusaPoseToParts", 1
        )[0]
        for instruction in (
            "move.w  #0,$B6(a5)",
            "move.w  #$80,$296(a5)",
            "move.w  #$100,$476(a5)",
            "move.w  #$180,$656(a5)",
        ):
            self.assertIn(instruction, worker)
        self.assertEqual(4, worker.count("bsr.w   Boss_OffsetMedusaPosePartGroup"))
        helper = source.split("Boss_OffsetMedusaPosePartGroup:", 1)[1].split(
            "; End of function Boss_OffsetMedusaPosePartGroup", 1
        )[0]
        for read, write in (("$B2", "$B4"), ("$112", "$114"), ("$172", "$174"), ("$1D2", "$1D4")):
            self.assertIn(f"move.w  {read}(a1),d0", helper)
            self.assertIn(f"move.w  d0,{write}(a1)", helper)
        self.assertEqual(4, helper.count("add.w   d1,d0"))
        addresses = ("0x056EB4", "0x056EC4", "0x056FF6")
        self.assertEqual(3, len({self.audit[address]["basis"][0] for address in addresses}))

    def test_worm_direction_tables_keep_exact_rom_order(self) -> None:
        source = (ROOT / "src/enemies/stage_18.s").read_text(encoding="utf-8")
        table_list = source.split("Stage18_SegmentedWormDirectionFrameTables:", 1)[1].split(
            "Stage18_SegmentedWormDirectionFramesA:", 1
        )[0]
        self.assertEqual(
            ("A", "B", "C"),
            tuple(re.findall(r"\bdc\.l\s+Stage18_SegmentedWormDirectionFrames([ABC])\b", table_list)),
        )
        cases = (
            ("A", 0, ("0x0EB4B2", "0x0EB4CA", "0x0EB4D6")),
            ("B", 4, ("0x0EB4FA", "0x0EB506", "0x0EB512")),
            ("C", 8, ("0x0EB52A", "0x0EB542", "0x0EB54E")),
        )
        for index, (letter, base, addresses) in enumerate(cases):
            with self.subTest(table=letter):
                label = f"Stage18_SegmentedWormDirectionFrames{letter}"
                next_label = (
                    f"Stage18_SegmentedWormDirectionFrames{cases[index + 1][0]}"
                    if index < 2
                    else "Stage18_SegmentedWormTileAttributes"
                )
                section = source.split(label + ":", 1)[1].split(next_label + ":", 1)[0]
                frames = tuple(
                    int(value)
                    for value in re.findall(
                        r"\bdc\.l\s+Stage18_SegmentedWormSpriteMapping(\d\d)",
                        section,
                    )
                )
                pattern = (base, base + 3, base + 2, base + 1) * 2
                pattern += (base, base + 1, base + 2, base + 3) * 2
                self.assertEqual(pattern, frames)
                basis = f"{label} references this address-ordered worm mapping."
                self.assertEqual(
                    addresses,
                    tuple(member["address"] for member in self.reviews[basis]["members"]),
                )
                for address in addresses:
                    self.assertIn(basis, self.audit[address]["basis"])


if __name__ == "__main__":
    unittest.main()
