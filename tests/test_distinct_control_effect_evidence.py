"""Keep executable, data, return, stage, and effect evidence separate."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def section(source: str, start: str, end: str) -> str:
    return source.split(start, 1)[1].split(end, 1)[0]


class DistinctControlEffectEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {
            row["address"]: row
            for row in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }

    def assert_distinct_bases(self, first: str, second: str) -> None:
        self.assertFalse(set(self.audit[first]["basis"]) & set(self.audit[second]["basis"]))

    def test_control_test_loop_is_not_its_eight_record_layout(self) -> None:
        source = (ROOT / "src/ui/weapon_setup_screen.s").read_text(encoding="utf-8")
        loop = section(
            source,
            "WeaponSetup_RenderControlTestTextLoop:",
            "; End of function WeaponSetup_RenderControlTestRowsAndLoadPalette",
        )
        self.assertIn("lea     WeaponSetup_ControlTestTextLayout(pc),a1", loop)
        self.assertIn("movea.l 4(a1,d1.w),a0", loop)
        self.assertIn("jsr     (Text_QueueDoubleHeightStringWrapped).l", loop)
        self.assertIn("addi.w  #8,(WeaponSetupCursorOffset).w", loop)
        self.assertIn("cmpi.w  #$40,(WeaponSetupCursorOffset).w", loop)
        self.assertIn("jmp     Gfx_LoadMultiplePalettes", loop)
        layout = section(
            source,
            "WeaponSetup_ControlTestTextLayout:",
            "WeaponSetup_WaitForConfirmInput:",
        )
        self.assertEqual(8, layout.count("dc.l    WeaponSetup_"))
        self.assertEqual(16, layout.count("dc.w    $"))
        self.assertIn("dc.l    WeaponSetup_HoveringControlText", layout)
        self.assertIn("executable loop", self.audit["0x01F3EE"]["basis"][0])
        self.assertIn("eight-record", self.audit["0x01F424"]["basis"][0])
        self.assert_distinct_bases("0x01F3EE", "0x01F424")

    def test_stage_4_and_5_loaders_have_distinct_command_streams(self) -> None:
        source = (ROOT / "src/stages/visual_asset_loading.s").read_text(encoding="utf-8")
        table = section(source, "Stage_VisualAssetLoaderOffsets:", "Stage_LoadStage1VisualAssets:")
        self.assertLess(
            table.index("Stage_LoadStage4VisualAssets-"),
            table.index("Stage_LoadStage5VisualAssets-"),
        )
        for address, stage, command, words in (
            (
                "0x011EEE",
                "Stage_LoadStage4VisualAssets",
                "Stage4TileAssetCommands",
                "0, $7000, 8, $8000, $FFFF",
            ),
            (
                "0x011F0E",
                "Stage_LoadStage5VisualAssets",
                "Stage5TileAssetCommands",
                "0, $6000, 2, $7000, 6, $8000, $FFFF",
            ),
        ):
            with self.subTest(stage=stage):
                self.assertEqual(stage, self.audit[address]["current_name"])
                entry = section(source, stage + ":", "; End of function " + stage)
                self.assertIn("lea     (SharedStagePaletteCommand).l,a0", entry)
                self.assertIn("lea     " + command + "(pc),a0", entry)
                self.assertIn("bra.w   Stage_ExpandAndSubmitTileAssetCommands", entry)
                self.assertIn(command + ":    dc.w    " + words, source)
        self.assert_distinct_bases("0x011EEE", "0x011F0E")

    def test_valkirie_and_sirene_returns_do_not_claim_entire_helper(self) -> None:
        valkirie = (ROOT / "src/bosses/valkirie_battle.s").read_text(encoding="utf-8")
        damage = section(
            valkirie,
            "Entity_TestValkirieDamageFlash:",
            "; End of function Entity_TestValkirieDamageFlash",
        )
        self.assertIn("tst.w   (DifficultyMode).w", damage)
        self.assertIn("bclr    #6,$23E(a5)", damage)
        self.assertIn("btst    #0,(RandomNumberState).w", damage)
        self.assertEqual(2, damage.count("beq.s   Entity_TestValkirieDamageFlashReturn"))
        self.assertIn("Entity_TestValkirieDamageFlashReturn:", damage)
        self.assertIn("shared RTS", self.audit["0x055E7C"]["basis"][0])
        self.assert_distinct_bases("0x055E68", "0x055E7C")

        sirene = (ROOT / "src/bosses/sirene.s").read_text(encoding="utf-8")
        spawn = section(
            sirene,
            "Boss_SpawnSirenePeriodicProjectile:",
            "; End of function Boss_SpawnSirenePeriodicProjectile",
        )
        self.assertIn("andi.w  #$1F,d0", spawn)
        self.assertIn("jsr     (Projectile_FindFreeSlotForward4).l", spawn)
        self.assertEqual(2, spawn.count("bne.s   Boss_SpawnSirenePeriodicProjectileReturn"))
        self.assertIn("move.w  #$490,(a0)", spawn)
        self.assertIn("move.l  #SharedCombatSpriteAnimation22,8(a0)", spawn)
        self.assertIn("Boss_SpawnSirenePeriodicProjectileReturn:", spawn)
        self.assertIn("RTS", self.audit["0x057DF2"]["basis"][0])
        self.assert_distinct_bases("0x057D88", "0x057DF2")

    def test_two_non_palette_effects_have_positive_distinct_evidence(self) -> None:
        zleo = (ROOT / "src/credits/z_leo_sequence.s").read_text(encoding="utf-8")
        particle = section(zleo, "Boss_ZLeoSpawnParticles:", "; End of function Boss_ZLeoSpawnParticles")
        for operation in (
            "move.w  d0,$10(a0)",
            "move.w  d0,$14(a0)",
            "move.l  d0,$18(a0)",
            "move.l  Boss_ZLeoParticleSpritePointers(pc,d0.w),8(a0)",
            "jsr     (Sound_QueueSFXRequest).l",
        ):
            self.assertIn(operation, particle)
        shield = (ROOT / "src/bosses/shield_viper_debug_and_effects.s").read_text(encoding="utf-8")
        phase = section(
            shield,
            "Boss_ShieldViperUpdatePatternPhaseB:",
            "; End of function Boss_ShieldViperUpdatePatternPhaseB",
        )
        for operation in (
            "(ShieldViperEffectStepB).w",
            "(ShieldViperEffectPhaseB).w",
            "btst    #6,(PrimaryEntityStatus).w",
            "btst    #7,(PrimaryEntityFlags).w",
            "bra.w   Boss_ShieldViperFillPatternRange",
        ):
            self.assertIn(operation, phase)
        self.assertIn("allocated object", self.audit["0x02249A"]["basis"][-1])
        self.assertIn("ShieldViperEffectStepB", self.audit["0x04F7C0"]["basis"][-1])
        self.assert_distinct_bases("0x02249A", "0x04F7C0")


if __name__ == "__main__":
    unittest.main()
