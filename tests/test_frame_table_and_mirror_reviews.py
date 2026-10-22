"""Pin exact consumers and variant differences for paired mapping reviews."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def block(source: str, label: str) -> str:
    match = re.search(rf"(?ms)^{re.escape(label)}:(.*?)(?=^[A-Za-z_]\w*:|\Z)", source)
    if match is None:
        raise AssertionError(f"missing label {label}")
    return match.group(1)


class FrameTableAndMirrorReviewTests(unittest.TestCase):
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

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in self.reviews[basis]["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.audit[address]["current_name"])
            self.assertIn(basis, self.audit[address]["basis"])

    def test_player_secondary_variants_share_frame_bit_selector(self) -> None:
        data = (ROOT / "src/data/player_special_and_death_sprite_mappings.s").read_text(encoding="utf-8")
        a = block(data, "Player_SpecialAttackSecondarySpriteMappingA")
        b = block(data, "Player_SpecialAttackSecondarySpriteMappingB")
        self.assertIn("Player_SpecialAttackSecondarySpriteArtAPiece00+$5000000", a)
        self.assertIn("Player_SpecialAttackSecondarySpriteArtBPiece00+$E000000", b)
        for path in (
            "src/player/fall_and_special_attack.s",
            "src/player/seven_forces_battle.s",
            "src/player/cutscene_and_damage_states.s",
        ):
            with self.subTest(path=path):
                source = (ROOT / path).read_text(encoding="utf-8")
                self.assertIn("movea.l #Player_SpecialAttackSecondarySpriteMappingA,a2", source)
                self.assertIn("btst    #0,(FrameCounter+1).w", source)
                self.assertIn("movea.l #Player_SpecialAttackSecondarySpriteMappingB,a2", source)
        self.assert_review(
            "Special-attack, recovery, and Seven Forces rendering paths select this secondary mapping as one of two frame-counter variants.",
            (
                ("0x0E8F3A", "Player_SpecialAttackSecondarySpriteMappingA"),
                ("0x0E8F6A", "Player_SpecialAttackSecondarySpriteMappingB"),
            ),
        )

    def test_sirene_state_fourteen_selects_distinct_four_pointer_sets(self) -> None:
        source = (ROOT / "src/bosses/sirene.s").read_text(encoding="utf-8")
        for suffix, final in (("0", "2"), ("1", "1")):
            name = f"Sirene_State14PoseScriptSet{suffix}"
            pointers = re.findall(r"\bdc\.l\s+(Sirene_State14PoseScript\d+)", block(source, name))
            self.assertEqual(
                ["Sirene_State14PoseScript0"] * 2 + [f"Sirene_State14PoseScript{final}"] * 2,
                pointers,
            )
        for instruction in (
            "lea     Sirene_State14PoseScriptSet0(pc),a0",
            "tst.w   $54(a5)",
            "lea     Sirene_State14PoseScriptSet1(pc),a0",
            "andi.w  #$C,d0",
            "move.l  (a0,d0.w),$71C(a5)",
        ):
            self.assertIn(instruction, source)
        self.assert_review(
            "State $14 chooses one of these four-entry pose-script pointer sets from the facing selector and the random phase.",
            (("0x05781C", "Sirene_State14PoseScriptSet0"), ("0x05782C", "Sirene_State14PoseScriptSet1")),
        )

    def test_sharpssteel_blade_tables_feed_six_iteration_loop(self) -> None:
        source = (ROOT / "src/bosses/sharpssteel_blades.s").read_text(encoding="utf-8")
        for variant in ("A", "B"):
            with self.subTest(variant=variant):
                name = f"Boss_SharpssteelBladeGraphicsMappings{variant}"
                pointers = re.findall(r"\bdc\.l\s+(Boss_SharpssteelBladeGraphics\w+)", block(source, name))
                self.assertEqual(
                    [f"Boss_SharpssteelBladeGraphics{variant}Mapping{index}" for index in range(6)],
                    pointers,
                )
                self.assertIn(f"lea     {name}(pc),a0", source)
        self.assertIn("moveq   #5,d7", source)
        self.assertIn("move.l  (a0)+,8(a1)", source)
        self.assertIn("dbf     d7,Boss_SharpssteelApplyBladeGraphicsSetLoop", source)
        self.assert_review(
            "The corresponding graphics-set routine consumes these six pointers while configuring embedded blade parts.",
            (
                ("0x04890A", "Boss_SharpssteelBladeGraphicsMappingsB"),
                ("0x048922", "Boss_SharpssteelBladeGraphicsMappingsA"),
            ),
        )

    def test_antroid_variants_use_same_range_but_different_exits(self) -> None:
        source = (ROOT / "src/bosses/antroid_core.s").read_text(encoding="utf-8")
        for variant, suffix in (("A", ".s"), ("B", ".w")):
            with self.subTest(variant=variant):
                label = f"Boss_AntroidLeapAttack{variant}CheckScreenRange"
                body = block(source, label)
                self.assertIn("cmpi.w  #$C70,$BC(a5)", body)
                self.assertIn("cmpi.w  #$D10,$BC(a5)", body)
                self.assertIn("subq.w  #1,$11C(a5)", body)
                self.assertIn(f"bmi{suffix}", body)
        self.assertIn("bmi.s   Boss_AntroidLeapAttackAFinish", block(source, "Boss_AntroidLeapAttackACheckScreenRange"))
        self.assertIn(
            "bmi.w   Boss_AntroidReturnToNeutralLoadAnimation", block(source, "Boss_AntroidLeapAttackBCheckScreenRange")
        )
        self.assert_review(
            "The normal phase checks the derived screen coordinate against the bounded $C70..$D10 interval.",
            (
                ("0x037830", "Boss_AntroidLeapAttackACheckScreenRange"),
                ("0x0378FE", "Boss_AntroidLeapAttackBCheckScreenRange"),
            ),
        )

    def test_story_title_rows_advance_different_source_strides(self) -> None:
        source = (ROOT / "src/cutscenes/story_screen_and_title_transition.s").read_text(encoding="utf-8")
        for side, source_step in (("Left", "adda.l  #$C,a0"), ("Right", "addq.l  #4,a0")):
            with self.subTest(side=side):
                name = f"StoryTitle_Character{side}AdvanceRow"
                body = block(source, name)
                for instruction in (
                    source_step,
                    "addq.l  #4,a2",
                    "movea.l a2,a1",
                    f"dbf     d6,StoryTitle_Character{side}NextRow",
                ):
                    self.assertIn(instruction, body)
        self.assertGreaterEqual(source.count("move.w  #$F,d6"), 2)
        self.assert_review(
            "The path advances the source and destination row bases before repeating the sixteen-row loop.",
            (("0x004DBC", "StoryTitle_CharacterLeftAdvanceRow"), ("0x004E16", "StoryTitle_CharacterRightAdvanceRow")),
        )


if __name__ == "__main__":
    unittest.main()
