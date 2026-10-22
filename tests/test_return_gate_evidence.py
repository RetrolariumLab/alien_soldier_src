from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ReturnGateEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = {
            item["address"]: item
            for item in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            item["basis"]: item
            for item in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }

    def assert_review(self, basis: str, addresses: list[str]) -> None:
        self.assertEqual(
            addresses,
            [member["address"] for member in self.reviews[basis]["members"]],
        )

    def test_jampan_branches_have_distinct_evidence(self) -> None:
        move = self.records["0x049878"]["basis"][0]
        delay = self.records["0x049A0C"]["basis"][0]
        self.assertNotEqual(move, delay)
        self.assertIn("SharedPatternRow0Long2", move)
        self.assertIn("DifficultyMode", delay)
        source = (ROOT / "src/bosses/jampan_core.s").read_text(encoding="utf-8")
        self.assertIn("bcs.s   Boss_JampanMoveRightTowardScreenThreshold", source)
        self.assertIn("addq.w  #2,(SharedPatternRow0Long2).w", source)
        self.assertIn("addi.l  #$8000,$10(a5)", source)
        self.assertIn("tst.w   (DifficultyMode).w", source)
        self.assertIn("bne.s   Boss_JampanUseShortOffsetAttackDelay", source)
        self.assertIn("move.w  #$40,$48(a5)", source)
        self.assertIn("move.w  #$10,$48(a5)", source)

    def test_zero_animation_request_preserves_pointer_and_cursor(self) -> None:
        basis = "A zero request leaves the current animation in place."
        self.assert_review(basis, ["0x02C982", "0x02CA8E"])
        source = (ROOT / "src/enemies/jetsripper_stage_actors.s").read_text(encoding="utf-8")
        for owner, table in (
            ("Enemy", "PeriodicShotEnemySpriteAnimationPointers"),
            ("Projectile", "Enemy_ProjectileAnimationPointers"),
        ):
            with self.subTest(owner=owner):
                block = source.split(f"Anim_Update{owner}Animation:", 1)[1]
                block = block.split(f"; End of function Anim_Update{owner}Animation", 1)[0]
                self.assertIn("move.w  $5C(a5),d0", block)
                self.assertIn(f"beq.s   Anim_Update{owner}Animation_Return", block)
                self.assertIn(f"move.l  {table}(pc,d0.w),8(a5)", block)
                self.assertIn("clr.w   $C(a5)", block)

    def test_paced_particle_and_projectile_returns_share_two_gates(self) -> None:
        basis = "Both the paced frames and a full pool return here."
        self.assert_review(basis, ["0x02A554", "0x02A5B4"])
        source = (ROOT / "src/actors/shared_object_helpers.s").read_text(encoding="utf-8")
        for entry, ret in (
            ("Effect_SpawnParticleLoop", "Effect_SpawnParticleLoop_Return"),
            ("Projectile_FallingSpawner", "Projectile_FallingSpawner_Return"),
        ):
            with self.subTest(entry=entry):
                block = source.split(entry + ":", 1)[1].split(ret + ":", 1)[0]
                self.assertIn("subq.w  #1,$48(a5)", block)
                self.assertIn(f"bpl.s   {ret}", block)
                self.assertIn("move.w  #2,$48(a5)", block)
                self.assertIn("(Projectile_FindFreeSlotForward).l", block)
                self.assertRegex(block, rf"bne\.[sw]\s+{re.escape(ret)}")

    def test_two_speed_projectile_returns_share_three_gates(self) -> None:
        basis = "An active initial timer, clear terrain test, or failed impact allocation returns through this RTS."
        self.assert_review(basis, ["0x02B2EE", "0x02B43A"])
        source = (ROOT / "src/projectiles/directional_and_gravity_shots.s").read_text(encoding="utf-8")
        for prefix in ("", "Type254"):
            with self.subTest(prefix=prefix):
                ret = f"Projectile_{prefix}TwoSpeedShotReturn"
                self.assertIn(f"bpl.s   {ret}", source)
                self.assertIn(f"beq.s   {ret}", source)
                self.assertIn(f"bne.s   {ret}", source)
                self.assertIn(ret + ":", source)

    def test_defeat_debris_returns_have_different_cadences(self) -> None:
        self.assert_review(
            "Skipped and emitted defeat-debris paths return here.",
            ["0x047752", "0x050F3C"],
        )
        epsilon = (ROOT / "src/projectiles/epsilon_1_projectiles.s").read_text(encoding="utf-8")
        wolf = (ROOT / "src/bosses/wolf_garopa_attack_effects_and_transition.s").read_text(encoding="utf-8")
        for source, owner, cadence in (
            (epsilon, "Boss_Epsilon1UpdateRingObjectDefeatFall", "andi.w  #3,d0"),
            (wolf, "Boss_WolfGaropaDefeatTransition", "btst    #0,(FrameCounter+1).w"),
        ):
            with self.subTest(owner=owner):
                ret = owner + "Return"
                self.assertIn(cadence, source)
                self.assertEqual(2, source.count(f"bne.s   {ret}"))
                self.assertIn("(Projectile_FindFreeSlotForward).l", source)
                self.assertIn("(Projectile_InitType88).l", source)
                self.assertIn(ret + ":", source)

    def test_between_shots_returns_have_distinct_periods(self) -> None:
        self.assert_review(
            "The frames between shots return here.",
            ["0x02CA3E", "0x02ED20"],
        )
        periodic = (ROOT / "src/enemies/jetsripper_stage_actors.s").read_text(encoding="utf-8")
        fish = (ROOT / "src/enemies/stage_11_fish.s").read_text(encoding="utf-8")
        self.assertIn("andi.w  #$1F,d0", periodic)
        self.assertIn("bne.s   Enemy_TryPeriodicShot_Return", periodic)
        self.assertIn("(Projectile_SpawnAimedArcFromEnemy).l", periodic)
        self.assertIn("subq.w  #1,$48(a5)", fish)
        self.assertIn("bne.s   Enemy_Stage11FishFireVolleyState_Return", fish)
        self.assertIn("move.w  #8,$48(a5)", fish)
        self.assertIn("move.w  #$40,$48(a5)", fish)

    def test_animation_step_returns_share_timer_but_not_end_marker(self) -> None:
        self.assert_review(
            "The frames inside one step return here.",
            ["0x02A764", "0x02A794"],
        )
        source = (ROOT / "src/actors/shared_object_helpers.s").read_text(encoding="utf-8")
        for routine in ("Anim_UpdateScriptAndHide", "Anim_UpdateLoopingScript"):
            with self.subTest(routine=routine):
                block = source.split(routine + ":", 1)[1].split("; End of function " + routine, 1)[0]
                self.assertIn("subq.w  #1,$4C(a5)", block)
                self.assertIn(f"bne.s   {routine}_Return", block)
                self.assertIn(f"{routine}_Return:", block)
        self.assertIn("andi.w  #$7FFF,2(a5)", source)
        self.assertIn("bra.s   Anim_UpdateLoopingScript_ReadFrame", source)


if __name__ == "__main__":
    unittest.main()
