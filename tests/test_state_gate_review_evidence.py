"""Check exact gates behind paired enemy, banner, boss, and credits reviews."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def routine(path: str, label: str) -> str:
    source = (ROOT / path).read_text(encoding="utf-8")
    match = re.search(
        rf"(?ms)^{re.escape(label)}:.*?; End of function {re.escape(label)}",
        source,
    )
    if match is None:
        raise AssertionError(f"missing routine {label} in {path}")
    return match.group()


class StateGateReviewEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in self.reviews[basis]["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.records[address]["current_name"])
            self.assertIn(basis, self.records[address]["basis"])

    def test_zero_animation_selector_returns_without_pointer_write(self) -> None:
        for path, name, pointer_table in (
            (
                "src/enemies/spawn_and_movement.s",
                "Enemy_UpdateBehaviorAnimation",
                "Enemy_BehaviorSpriteAnimationPointers",
            ),
            (
                "src/enemies/stage_10_wasp_and_falling_shot.s",
                "Enemy_UpdateStage10WaspAnimation",
                "Enemy_Stage10WaspAnimationMappings",
            ),
        ):
            with self.subTest(name=name):
                body = routine(path, name)
                self.assertRegex(body, rf"move\.w\s+\$5C\(a5\),d0\s+beq\.s\s+{name}_Return")
                self.assertIn(f"move.l  {pointer_table}(pc,d0.w),8(a5)", body)
                self.assertIn("clr.w   $C(a5)", body)
                self.assertRegex(body, rf"(?m)^{name}_Return:.*?\n\s+rts")
        self.assert_review(
            "States that requested no animation return here.",
            (
                ("0x02C54E", "Enemy_UpdateBehaviorAnimation_Return"),
                ("0x02E0AC", "Enemy_UpdateStage10WaspAnimation_Return"),
            ),
        )

    def test_banner_descriptors_have_distinct_values_and_callers(self) -> None:
        data = (ROOT / "src/ui/message_scripts_and_glyph_lists.s").read_text(encoding="utf-8")
        engine = (ROOT / "src/ui/message_sequence_engine.s").read_text(encoding="utf-8")
        renderer = (ROOT / "src/ui/stage_message_sequences.s").read_text(encoding="utf-8")
        self.assertRegex(
            data, r"BattleBanner_StaticSpriteLine:\s+dc\.l\s+\$C6A0010A[^\n]*\n(?:[^\n]*\n)*?\s+dc\.l\s+\$680B0004"
        )
        self.assertRegex(data, r"BattleBanner_MovingSpriteLine:\s+dc\.l\s+\$C6AA00FF\s+[^\n]*\n\s+dc\.l\s+\$680B0006")
        self.assertEqual(2, engine.count("movea.l #BattleBanner_StaticSpriteLine,a0"))
        self.assertEqual(1, engine.count("movea.l #BattleBanner_MovingSpriteLine,a0"))
        self.assertIn("bsr.s   Message_WriteSpriteLine", renderer)
        self.assertIn("move.w  (a0)+,d7", renderer)
        self.assert_review(
            "The READY/FIGHT state handlers pass this compact two-entry line descriptor to the shared message sprite-line renderer.",
            (("0x00B43E", "BattleBanner_StaticSpriteLine"), ("0x00B446", "BattleBanner_MovingSpriteLine")),
        )

    def test_terobuster_exit_order_reverses_comparison_polarity(self) -> None:
        source = (ROOT / "src/bosses/terobuster_core.s").read_text(encoding="utf-8")
        for variant, first, second, branch in (
            ("A", "8", "$18", "beq.w"),
            ("B", "$10", "$20", "bne.w"),
        ):
            with self.subTest(variant=variant):
                start = f"Boss_TerobusterMissileAttack{variant}ChooseExitOrder"
                end = f"Boss_TerobusterMissileAttack{variant}Update"
                match = re.search(rf"(?ms)^{start}:.*?(?=^{end}:)", source)
                self.assertIsNotNone(match)
                block = match.group()
                self.assertIn(f"moveq   #{first},d0", block)
                self.assertIn(f"moveq   #{second},d1", block)
                self.assertIn("tst.w   $A(a5)", block)
                self.assertIn("exg     d0,d1", block)
                self.assertIn("cmp.w   $58(a5),d0", block)
                self.assertIn(f"{branch}   Boss_TerobusterSelectPartOrderA", block)
                self.assertIn("bra.w   Boss_TerobusterSelectPartOrderB", block)
        self.assert_review(
            "The active pose cursor selects which part order is installed before returning to the decision state.",
            (
                ("0x0387D8", "Boss_TerobusterMissileAttackAExitByPose"),
                ("0x038892", "Boss_TerobusterMissileAttackBExitByPose"),
            ),
        )

    def test_fish_brake_and_edge_gates_remain_distinct(self) -> None:
        path = "src/enemies/stage_11_fish.s"
        outward = routine(path, "Enemy_Stage11FishBrakeOutwardMotionState")
        inward = routine(path, "Enemy_Stage11FishBrakeInwardMotionState")
        self.assertIn("tst.l   $18(a5)", outward)
        self.assertIn("bne.s   Enemy_Stage11FishBrakeOutwardMotionState_Return", outward)
        self.assertIn("#Enemy_Stage11FishSpriteMapping02,8(a5)", outward)
        self.assertIn("bne.s   Enemy_Stage11FishBrakeInwardMotionState_Return", inward)
        self.assertIn("#Enemy_Stage11FishSpriteMapping01,8(a5)", inward)
        self.assert_review(
            "The braking frames return here.",
            (
                ("0x02ED9A", "Enemy_Stage11FishBrakeOutwardMotionState_Return"),
                ("0x02EE42", "Enemy_Stage11FishBrakeInwardMotionState_Return"),
            ),
        )
        inner = routine(path, "Enemy_Stage11FishWaitForInnerEdgeState")
        outer = routine(path, "Enemy_Stage11FishWaitForOuterEdgeState")
        for block, thresholds in ((inner, ("$E0", "$160")), (outer, ("$1A0", "$A0"))):
            for threshold in thresholds:
                self.assertIn(f"cmpi.w  #{threshold},$10(a5)", block)
        self.assertIn("move.w  #$40,$48(a5)", outer)
        self.assert_review(
            "The frames before the edge return here.",
            (
                ("0x02EE0A", "Enemy_Stage11FishWaitForInnerEdgeState_Return"),
                ("0x02EEBE", "Enemy_Stage11FishWaitForOuterEdgeState_Return"),
            ),
        )

    def test_zleo_below_marker_threshold_uses_distinct_branches(self) -> None:
        path = "src/credits/z_leo_sequence.s"
        first = routine(path, "Boss_ZLeoWaitMarkerPosition")
        final = routine(path, "Boss_ZLeoWaitForMarkerEnd")
        for block in (first, final):
            self.assertIn("cmpi.w  #$1E0,(PrimaryEntityXPos).w", block)
        self.assertIn("bcs.s   Boss_ZLeoWaitMarkerPosition_Return", first)
        self.assertIn("clr.w   (PrimaryEntityXVelocity).w", first)
        self.assertIn("addi.l  #$1000,(PrimaryEntityXVelocity).w", final)
        self.assertIn("blt.s   Boss_ZLeoWaitForMarkerEnd_Return", final)
        self.assert_review(
            "The frames before the marker arrives return here.",
            (("0x02219A", "Boss_ZLeoWaitMarkerPosition_Return"), ("0x0222DC", "Boss_ZLeoWaitForMarkerEnd_Return")),
        )


if __name__ == "__main__":
    unittest.main()
