from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class PairedTransitionEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.reviews = {
            item["basis"]: item
            for item in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        cls.records = {
            item["address"]: item
            for item in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }

    def assert_review(self, basis: str, addresses: list[str]) -> None:
        self.assertEqual(
            addresses,
            [member["address"] for member in self.reviews[basis]["members"]],
        )

    def test_sirene_paths_share_only_shake_continuation(self) -> None:
        basis = "Both completion paths continue from here into the recurring Sirene camera-shake update."
        self.assert_review(basis, ["0x00EA02", "0x00EA20"])
        source = (ROOT / "src/stages/seven_forces_stage_states.s").read_text(encoding="utf-8")
        for label in (
            "Stage_SevenForcesAdvanceSireneShake",
            "Stage_SevenForcesFinishSireneShake",
        ):
            block = source.split(label + ":", 1)[1].split("; End of function", 1)[0]
            self.assertIn("bra.w   Stage_SevenForcesUpdateSireneShake", block)
        self.assertIn("move.w  #$D0,(PlayerXPosition).w", source)
        self.assertIn("move.w  #$40,(SevenForcesTimer).w", source)

    def test_completed_logo_rows_share_52_byte_loop_not_wrap_direction(self) -> None:
        basis = "Both ordinary and wrapped source-pointer paths converge here before continuing the 52-byte row."
        self.assert_review(basis, ["0x005060", "0x0050CC"])
        source = (ROOT / "src/cutscenes/story_screen_and_title_transition.s").read_text(encoding="utf-8")
        self.assertEqual(2, source.count("move.w  #$33,d5"))
        self.assertIn("suba.l  #$78,a0", source)
        self.assertIn("adda.l  #$78,a0", source)
        for side in ("Left", "Right"):
            self.assertIn(
                f"dbf     d5,StoryTitle_CompletedLogo{side}NextSourceByte",
                source,
            )

    def test_pose_anchor_and_control_word_common_blocks_are_bounded(self) -> None:
        anchor_basis = (
            "Both pose-cursor anchor choices converge here to copy the selected "
            "linked-object pointer into fields $48/$4A before updating parts."
        )
        control_basis = (
            "Both prefixed and ordinary commands converge here to read the control word and test stop marker $FFFE."
        )
        self.assert_review(anchor_basis, ["0x03A856", "0x03A8D2"])
        self.assert_review(control_basis, ["0x03AC10", "0x03BCE0"])
        barbar = (ROOT / "src/bosses/madam_barbar_core.s").read_text(encoding="utf-8")
        joker = (ROOT / "src/bosses/joker_rendering.s").read_text(encoding="utf-8")
        for side in ("Left", "Right"):
            block = barbar.split(f"Boss_MadamBarbarAnchorPlayer{side}SidePose:", 1)[1]
            block = block.split("; ---------------------------------------------------------------------------", 1)[0]
            self.assertIn("move.w  #$C8,$14(a0)", block)
            self.assertIn("move.w  a0,$48(a5)", block)
            self.assertIn("move.w  a0,$4A(a5)", block)
            self.assertIn("bra.w   Boss_MadamBarbarUpdateParts", block)
        for owner, source in (("MadamBarbar", barbar), ("Joker", joker)):
            block = source.split(f"Boss_{owner}ReadPoseControlWord:", 1)[1]
            block = block.split("; ---------------------------------------------------------------------------", 1)[0]
            self.assertIn("move.w  (a1,d0.w),d3", block)
            self.assertIn("cmpi.w  #$FFFE,d3", block)
            self.assertIn("move.w  d3,$58(a5)", block)

    def test_terobuster_bind_blocks_share_writes_but_not_selection_ranges(self) -> None:
        basis = (
            "Both slot-selection paths converge here to bind the active part, "
            "align its Y coordinate, and render the metasprite."
        )
        self.assert_review(basis, ["0x038814", "0x0388DE"])
        source = (ROOT / "src/bosses/terobuster_core.s").read_text(encoding="utf-8")
        for attack in ("A", "B"):
            block = source.split(f"Boss_TerobusterMissileAttack{attack}BindPart:", 1)[1]
            block = block.split("; ---------------------------------------------------------------------------", 1)[0]
            self.assertIn("move.w  a0,$48(a5)", block)
            self.assertIn("move.w  a0,$4A(a5)", block)
            self.assertIn("move.w  #$14C,$14(a0)", block)
            self.assertIn("bra.w   Boss_TerobusterUpdateMetaspriteAndProjectile", block)
        self.assertIn("cmpi.w  #5,$58(a5)", source)
        self.assertIn("cmpi.w  #$10,$58(a5)", source)

    def test_sniper_and_bugmax_return_bases_are_distinct(self) -> None:
        pairs = (
            ("0x036824", "0x036894", "$1E00", "$2000"),
            ("0x04CE42", "0x04D1D4", "$4A(a5)", "$4C(a5)"),
        )
        for left, right, left_token, right_token in pairs:
            with self.subTest(pair=(left, right)):
                left_basis = self.records[left]["basis"][0]
                right_basis = self.records[right]["basis"][0]
                self.assertNotEqual(left_basis, right_basis)
                self.assertIn(left_token, left_basis)
                self.assertIn(right_token, right_basis)
        sniper = (ROOT / "src/bosses/sniper_honeyviper_core.s").read_text(encoding="utf-8")
        self.assertIn("addi.l  #$1E00,$78(a5)", sniper)
        self.assertIn("subi.l  #$2000,$78(a5)", sniper)
        bugmax = (ROOT / "src/bosses/bugmax_battle_and_final_sequence.s").read_text(encoding="utf-8")
        self.assertIn("subq.w  #1,$4A(a5)", bugmax)
        self.assertIn("subq.w  #1,$4C(a5)", bugmax)


if __name__ == "__main__":
    unittest.main()
