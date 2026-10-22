"""Guard exact-address basis corrections and the control flow behind them."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from patch_name_audit_bases import patch_bytes  # noqa: E402


class NameAuditBasisCorrectionTests(unittest.TestCase):
    def test_byte_preserving_patch_is_strict_and_idempotent(self) -> None:
        original = b'{"records":[\r\n  {"address":"0x000100","current_name":"Example","basis":["old"]}\r\n]}\r\n'
        change = {
            "address": "0x000100",
            "current_name": "Example",
            "old_basis": "old",
            "new_basis": "new",
        }
        updated, count = patch_bytes(original, [change])
        self.assertEqual(1, count)
        self.assertEqual(original.replace(b'["old"]', b'["new"]'), updated)
        self.assertEqual((updated, 0), patch_bytes(updated, [change]))
        with self.assertRaisesRegex(ValueError, "expected old basis"):
            patch_bytes(original, [{**change, "old_basis": "wrong"}])
        with self.assertRaisesRegex(ValueError, "current name changed"):
            patch_bytes(original, [{**change, "current_name": "Other"}])

    def test_multi_basis_patch_requires_the_full_prior_list(self) -> None:
        original = b'{"records":[\n  {"address":"0x000100","current_name":"Example","basis":["kept","old"]}\n]}\n'
        change = {
            "address": "0x000100",
            "current_name": "Example",
            "old_basis": "old",
            "new_basis": "new",
            "prior_bases": ["kept", "old"],
        }
        updated, count = patch_bytes(original, [change])
        self.assertEqual(1, count)
        self.assertEqual(original.replace(b'"old"', b'"new"'), updated)
        self.assertEqual((updated, 0), patch_bytes(updated, [change]))
        with self.assertRaisesRegex(ValueError, "expected old basis"):
            patch_bytes(original, [{**change, "prior_bases": ["different", "old"]}])
        with self.assertRaisesRegex(ValueError, "invalid prior basis list"):
            patch_bytes(original, [{**change, "prior_bases": ["old", "old"]}])

    def test_correction_ledger_matches_audit_and_exact_source_gates(self) -> None:
        changes = json.loads((ROOT / "config/name_audit_basis_corrections.json").read_text(encoding="utf-8"))[
            "corrections"
        ]
        audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        self.assertEqual(26, len(changes))
        self.assertEqual(26, len({change["address"] for change in changes}))
        for change in changes:
            with self.subTest(address=change["address"]):
                record = audit[change["address"]]
                self.assertEqual(change["current_name"], record["current_name"])
                prior = change.get("prior_bases", [change["old_basis"]])
                self.assertEqual(
                    [change["new_basis"] if basis == change["old_basis"] else basis for basis in prior],
                    record["basis"],
                )
                self.assertNotEqual(change["old_basis"], change["new_basis"])

        seven = (ROOT / "src/player/seven_forces_battle.s").read_text(encoding="utf-8")
        ceiling = (ROOT / "src/player/air_and_ground_states.s").read_text(encoding="utf-8")
        self.assertIn("btst    #1,$69(a5)", seven)
        self.assertIn("bne.w   Player_ToggleSevenForcesShootingMode", seven)
        self.assertIn("btst    #0,$69(a5)", ceiling)
        self.assertIn("bne.w   Player_ToggleShootingMode", ceiling)
        for source in (seven, ceiling):
            self.assertIn("btst    #6,$6A(a5)", source)
            self.assertIn("tst.w   (WeaponStateCooldown).w", source)

        terrain = (ROOT / "src/player/terrain_collision.s").read_text(encoding="utf-8")
        lower = terrain.split("Physics_CheckLowerTerrainWhenDescending:", 1)[1].split(
            "; End of function Physics_CheckLowerTerrainWhenDescending", 1
        )[0]
        upper = terrain.split("Physics_CheckUpperTerrainWhenRising:", 1)[1].split(
            "; End of function Physics_CheckUpperTerrainWhenRising", 1
        )[0]
        self.assertEqual(3, lower.count("bmi.s   Physics_CheckLowerTerrainWhenDescending_Return"))
        self.assertEqual(3, upper.count("bpl.s   Physics_CheckUpperTerrainWhenRising_Return"))

        valkirie = (ROOT / "src/bosses/valkirie_rendering.s").read_text(encoding="utf-8")
        for instruction in (
            "tst.w   $23E(a5)",
            "move.l  #$2C000,$1F8(a5)",
            "move.l  #$FFFD4000,$1F8(a5)",
            "bclr    #6,$21(a5)",
            "move.w  #4,$5C(a5)",
            "move.l  #$12000,$1F8(a5)",
            "move.l  #$FFFEE000,$1F8(a5)",
        ):
            self.assertIn(instruction, valkirie)
        self.assertIn("beq.s   Entity_SetValkirieAuxiliaryFastNegativeVelocity", valkirie)
        self.assertIn("beq.s   Entity_SetValkirieAuxiliarySlowNegativeVelocity", valkirie)

        velocity = (ROOT / "src/player/terrain_wrappers.s").read_text(encoding="utf-8")
        self.assertIn("cmpi.l  #$FFFD6000,d0", velocity)
        self.assertIn("bmi.s   Physics_AccelerateHorizontalNegative_Store", velocity)
        self.assertIn("subi.l  #$A800,d0", velocity)
        self.assertIn("cmpi.l  #$2A000,d0", velocity)
        self.assertIn("bpl.s   Physics_AccelerateHorizontalPositive_Store", velocity)
        self.assertIn("addi.l  #$A800,d0", velocity)

        terrain = (ROOT / "src/player/terrain_collision.s").read_text(encoding="utf-8")
        for level, base, flag in (
            ("Lower", "Physics_HandleLowerLeftOuterTerrain", 0),
            ("Upper", "Physics_HandleUpperLeftOuterTerrain", 1),
        ):
            right = f"Physics_Handle{level}RightInnerTerrain"
            self.assertIn(f"movea.w Physics_{level}RightInnerResponseTable(pc,d2.w),a4", terrain)
            self.assertIn(f"adda.l  #{base},a4", terrain)
            self.assertIn(f"bset    #{flag},6(a5)", terrain)
            self.assertIn(right + "_Dispatch:", terrain)
        self.assertIn("bset    #2,6(a5)", terrain)

        bullet = (ROOT / "src/projectiles/shared_boss_projectiles.s").read_text(encoding="utf-8")
        entry = bullet.split("Projectile_InitValkirieBulletFromSource:", 1)[1].split(
            "; End of function Projectile_InitValkirieBulletFromSource", 1
        )[0]
        packed = entry.split("Projectile_CopyValkiriePackedSizeFields:", 1)[1]
        self.assertIn("move.w  #$480,(a0)", entry)
        self.assertIn("move.w  d3,$48(a0)", entry)
        self.assertIn("move.w  d4,$4A(a0)", entry)
        self.assertIn("btst    #6,2(a0)", entry)
        self.assertIn("bne.s   Projectile_CopyValkiriePackedSizeFields", entry)
        self.assertIn("move.l  8(a1),8(a0)", packed)
        self.assertNotIn("#$480", packed)

        responses = (ROOT / "src/player/terrain_responses.s").read_text(encoding="utf-8")
        for helper, seed, branch, caller in (
            (
                "Physics_PrepareVerticalOffset6",
                6,
                "Physics_AlignFloorQuarterSubtractOffset",
                "Physics_ApplyOffset6Sub10",
            ),
            ("Physics_PrepareQuarterAddOffset3", 3, "Physics_AlignFloorQuarterAddOffset", "Physics_ApplyOffset3Sub6"),
        ):
            with self.subTest(helper=helper):
                body = responses.split(helper + ":", 1)[1].split("; End of function " + helper, 1)[0]
                self.assertIn(f"moveq   #{seed},d3", body)
                self.assertIn(f"bra.s   {branch}", body)
                self.assertIn(f"bsr.s   {helper}", responses)
                self.assertIn(caller + ":", responses)

        vblank = (ROOT / "src/rendering/vblank_effects.s").read_text(encoding="utf-8")
        setup = vblank.split("VBlank_InitSplitVScrollEffect:", 1)[1].split("VBlank_InitSplitVScrollEffect_Update:", 1)[
            0
        ]
        update = vblank.split("VBlank_InitSplitVScrollEffect_Update:", 1)[1].split(
            "; End of function VBlank_InitSplitVScrollEffect", 1
        )[0]
        self.assertIn("bne.s   VBlank_InitSplitVScrollEffect_Update", setup)
        self.assertIn("HBlank_WriteSplitVScroll2AndStop_InstallList(pc),a0", setup)
        self.assertIn("jsr     (LoadObjData).l", setup)
        self.assertIn("ori.b   #$10,(VDPReg0Shadow+1).w", setup)
        self.assertNotIn("LoadObjData", update)
        self.assertIn("move.w  (VScrollPlaneAColumn1).w,(VDP_DATA).l", update)
        self.assertIn("move.b  (PrimaryEntityWork4B).w,(VDPReg10Shadow+1).w", update)
        self.assertIn("move.w  (VDPReg10Shadow).w,(VDP_CTRL).l", update)

        dma = (ROOT / "src/gameplay/math_and_buffer_helpers.s").read_text(encoding="utf-8")
        reset = (ROOT / "src/system/boot.s").read_text(encoding="utf-8")
        self.assertIn("bset    #0,(IO_Z80BUS).l", dma)
        self.assertIn("bne.s   Gfx_DmaTransferWithZ80Halt_RequestBus", dma)
        self.assertIn("dc.l    IO_Z80BUS", reset)
        self.assertIn("move.w  d7,(a1)", reset)
        wait = reset.split("Reset_WaitForZ80Bus:", 1)[1].split("Reset_CopyZ80BootstrapLoop:", 1)[0]
        self.assertIn("btst    d0,(a1)", wait)
        self.assertIn("bne.s   Reset_WaitForZ80Bus", wait)
        self.assertNotIn("move.w", wait)

        jampan = (ROOT / "src/bosses/jampan_support.s").read_text(encoding="utf-8")
        radial = jampan.split("Boss_JampanRadialLinkedObjectMain:", 1)[1].split(
            "; End of function Boss_JampanRadialLinkedObjectMain", 1
        )[0]
        animation = jampan.split("Boss_JampanLinkedAnimationObjectMain:", 1)[1].split(
            "; End of function Boss_JampanLinkedAnimationObjectMain", 1
        )[0]
        self.assertIn("move.b  $20(a5),d0", radial)
        self.assertIn("move.b  $20(a1),$20(a5)", animation)
        for block, clear in (
            (radial, "Boss_JampanClearRadialObjectPriorityFlag"),
            (animation, "Boss_JampanClearAnimationObjectPriorityFlag"),
        ):
            self.assertIn("cmp.b   (PrimaryEntityAngle).w,d0", block)
            self.assertIn(f"bhi.s   {clear}", block)
            self.assertIn("andi.w  #$7FFF,$E(a5)", block)

        sunset = (ROOT / "src/bosses/sunset_sting_segments.s").read_text(encoding="utf-8")
        self.assertGreaterEqual(sunset.count("lea     (Entity_ObjectPool).w,a3"), 2)
        for owner, limit, mapping in (
            ("Boss_SunsetStingSegment", "$80", "Boss_SunsetStingSegmentMappings"),
            ("Boss_SunsetStingSecondarySegment", "$98", "Boss_SunsetStingDestroyedSegmentMappings"),
        ):
            with self.subTest(owner=owner):
                orbit = sunset.split(owner + "OrbitState:", 1)[1].split(owner + "OrbitUpdatePosition:", 1)[0]
                position = sunset.split(owner + "OrbitUpdatePosition:", 1)[1].split(owner + "LaunchFromRing:", 1)[0]
                self.assertIn(f"cmpi.w  #{limit},d2", orbit)
                self.assertIn("bsr.w   Math_GetScaledSinCos", position)
                self.assertIn("add.l   $10(a3),d0", position)
                self.assertIn("add.l   $14(a3),d1", position)
                self.assertIn("move.l  d0,$10(a5)", position)
                self.assertIn("move.l  d1,$14(a5)", position)
                self.assertIn(f"lea     {mapping}(pc),a0", position)

        ship = (ROOT / "src/cutscenes/ship_piece_and_debris.s").read_text(encoding="utf-8")
        table = ship.split("ShipDebris_SpriteFrameTable:", 1)[1].split("ShipDebris_InitialXVelocities:", 1)[0]
        self.assertEqual(2, table.count("dc.l    ShipDebris_SpriteFrame1"))
        self.assertEqual(2, table.count("dc.l    ShipDebris_SpriteFrame3"))


if __name__ == "__main__":
    unittest.main()
