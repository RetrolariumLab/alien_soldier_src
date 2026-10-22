"""Pin three exact-address evidence reviews without visual assumptions."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ResultsSunsetTransitionEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {
            row["address"]: row
            for row in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            row["basis"]: row
            for row in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        }

    def test_summary_labels_are_distinct_and_followed_by_matching_totals(self) -> None:
        source = (ROOT / "src/ui/results_data.s").read_text(encoding="utf-8")
        labels = (
            ("0x020910", "Results_TotalTimeLabel", "$1613", "ResultsTotalTimeBCD"),
            (
                "0x020927",
                "Results_TotalClearTimeLabel",
                "$D16",
                "ResultsTotalClearBCD",
            ),
            (
                "0x02093E",
                "Results_TotalContinueLabel",
                "$D19",
                "ResultsTotalVisitsBCD",
            ),
        )
        bases = []
        for address, label, fifth_word, aggregate in labels:
            with self.subTest(label=label):
                row = self.audit[address]
                self.assertEqual(label, row["current_name"])
                self.assertEqual(1, len(row["basis"]))
                self.assertIn(aggregate, row["basis"][0])
                bases.append(row["basis"][0])
                data_line = source.split(label + ":", 1)[1].splitlines()[0]
                self.assertIn("dc.w", data_line)
                self.assertIn(fifth_word, data_line)
                entry = source.split("Results_BuildSummaryRows:", 1)[1].split(
                    "; End of function Results_BuildSummaryRows", 1
                )[0]
                self.assertIn(f"lea     {label}(pc),a1", entry)
                self.assertIn(f"lea     ({aggregate}).w,a1", entry)
        self.assertEqual(3, len(set(bases)))

    def test_sunset_commands_are_selected_through_four_pointer_slots(self) -> None:
        source = (ROOT / "src/bosses/sunset_sting_main.s").read_text(encoding="utf-8")
        table = source.split("Boss_SunsetStingTileLoadCommands:", 1)[1].split("Boss_SunsetStingTileLoadCommandA:", 1)[0]
        slots = [line.split("dc.l", 1)[1].split(";", 1)[0].strip() for line in table.splitlines() if "dc.l" in line]
        self.assertEqual(
            [
                "Boss_SunsetStingTileLoadCommandA",
                "Boss_SunsetStingTileLoadCommandB",
                "Boss_SunsetStingTileLoadCommandC",
                "Boss_SunsetStingTileLoadCommandB",
            ],
            slots,
        )
        for address, label, last_word in (
            ("0x042AC6", "Boss_SunsetStingTileLoadCommandA", "$6700"),
            ("0x042ACE", "Boss_SunsetStingTileLoadCommandB", "$6800"),
            ("0x042AD6", "Boss_SunsetStingTileLoadCommandC", "$6B00"),
        ):
            with self.subTest(label=label):
                self.assertEqual(label, self.audit[address]["current_name"])
                self.assertIn(last_word, self.audit[address]["basis"][0])
                command_line = next(line for line in source.split(label + ":", 1)[1].splitlines() if "dc.w" in line)
                self.assertIn(
                    f"dc.w    $625C, $2000, 0, {last_word}",
                    command_line,
                )
        self.assertIn("movea.l Boss_SunsetStingTileLoadCommands(pc,d0.w),a0", source)
        self.assertIn("jsr     (Tilemap_QueueIndexedRows).l", source)

    def test_transition_descriptors_share_exact_loader_contract(self) -> None:
        basis = "This terminated LoadObjData descriptor loads the shared transition asset at VRAM $E000."
        review = self.reviews[basis]
        expected = (
            (
                "0x026976",
                "AlternateTransition_GraphicsLoadDescriptor",
                "AlternateTransition_LoadGraphics",
                "src/effects/defeat_transition_control.s",
            ),
            (
                "0x026A4E",
                "TransitionEffect_GraphicsLoadDescriptor",
                "TransitionEffect_LoadGraphics",
                "src/effects/defeat_transition_control.s",
            ),
            (
                "0x027982",
                "TunnelTransition_GraphicsLoadDescriptor",
                "TunnelTransition_LoadGraphics",
                "src/effects/tunnel_transition.s",
            ),
        )
        self.assertEqual([item[0] for item in expected], [m["address"] for m in review["members"]])
        for address, descriptor, loader, filename in expected:
            with self.subTest(descriptor=descriptor):
                self.assertEqual([basis], self.audit[address]["basis"])
                self.assertEqual(descriptor, self.audit[address]["current_name"])
                source = (ROOT / filename).read_text(encoding="utf-8")
                entry = source.split(loader + ":", 1)[1].split("; End of function " + loader, 1)[0]
                self.assertIn(f"lea     {descriptor}(pc),a0", entry)
                self.assertIn("jsr     (LoadObjData).l", entry)
                block = source.split(descriptor + ":", 1)[1].splitlines()
                self.assertIn("dc.w    7", block[0])
                self.assertIn("dc.l    CreditsAndTransitionTileArtE000", "\n".join(block[:4]))
                self.assertIn("dc.w    $E000", "\n".join(block[:5]))
                self.assertIn("dc.w    $FFFF", "\n".join(block[:6]))


if __name__ == "__main__":
    unittest.main()
