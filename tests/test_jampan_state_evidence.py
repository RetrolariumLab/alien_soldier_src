from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class JampanStateEvidenceTests(unittest.TestCase):
    def test_three_transition_labels_have_distinct_evidence(self) -> None:
        records = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        source = (ROOT / "src/bosses/jampan_attacks.s").read_text(encoding="utf-8")
        cases = (
            (
                "0x049AA2",
                "Boss_JampanBeginShieldCycleDelay",
                ("move.w  #$10,$48(a5)", "addq.w  #2,4(a5)"),
            ),
            (
                "0x049D2E",
                "Boss_JampanMoveAlternatePatternUpward",
                ("subq.w  #1,$14(a5)",),
            ),
            (
                "0x049D34",
                "Boss_JampanBeginAlternatePatternOscillation",
                (
                    "bset    #2,$4C(a5)",
                    "move.l  #$FFFF0000,$1C(a5)",
                    "move.l  #$2000,$54(a5)",
                    "andi.w  #$1F8,(SharedPatternRow0Long1).w",
                    "addq.w  #2,4(a5)",
                ),
            ),
        )
        self.assertIn("beq.s   Boss_JampanBeginShieldCycleDelay", source)
        self.assertIn("beq.s   Boss_JampanBeginAlternatePatternOscillation", source)
        self.assertIn("bpl.s   Boss_JampanMoveAlternatePatternUpward", source)
        bases = []
        for address, label, instructions in cases:
            with self.subTest(address=address):
                body = source.split(label + ":", 1)[1].split("rts", 1)[0]
                for instruction in instructions:
                    self.assertIn(instruction, body)
                self.assertEqual(label, records[address]["current_name"])
                bases.append(records[address]["basis"][0])
        self.assertEqual(len(cases), len(set(bases)))


if __name__ == "__main__":
    unittest.main()
