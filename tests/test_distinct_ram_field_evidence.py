from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "config/name_audit.json"


class DistinctRamFieldEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}

    def test_dormant_type_1c0_ram_ownership_stays_distinct(self) -> None:
        overlays = {
            "PrimaryEntityWork58": "EntityType1C0ChainRootOffset",
            "PrimaryEntityWork5A": "EntityType1C0PartYReference",
            "PrimaryEntityWork5C": "EntityType1C0BodyPartCount",
            "PrimaryEntityWork5E": "EntityType1C0AnimationProgress",
            "SecondaryEntityWork58": "EntityType1C0OscillationPhase",
            "FifthEntityWork5C": "EntityType1C0TurnControl",
        }
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        source = "\n".join(
            (ROOT / f"src/bosses/entity_type_1c0_{module}.s").read_text(encoding="utf-8")
            for module in ("core", "attacks", "transition_and_defeat")
        )
        for structural, overlay in overlays.items():
            with self.subTest(overlay=overlay):
                self.assertRegex(
                    ram,
                    rf"(?m)^{re.escape(overlay)}[ \t]+equ[ \t]+{re.escape(structural)}$",
                )
                self.assertIn(overlay, source)
                self.assertNotRegex(source, rf"\b{re.escape(structural)}\b")
        for address in (
            "0xFFC678",
            "0xFFC67A",
            "0xFFC67C",
            "0xFFC67E",
            "0xFFC6D8",
            "0xFFC6DC",
            "0xFFC738",
            "0xFFC73C",
            "0xFFC73E",
            "0xFFC79C",
            "0xFFC7F8",
            "0xFFC7FC",
            "0xFFC7FD",
        ):
            with self.subTest(address=address):
                self.assertFalse(any("Sunset Sting" in basis for basis in self.records[address]["basis"]))

    def test_active_and_shadow_palette_roles_are_distinct(self) -> None:
        active = self.records["0xFFE300"]["basis"]
        shadow = self.records["0xFFE380"]["basis"]
        self.assertNotEqual(active, shadow)
        self.assertIn("CRAM", active[0])
        self.assertIn("fade", shadow[0])

        transfer = (ROOT / "src/rendering/vblank_dma.s").read_text(encoding="utf-8")
        self.assertIn("Gfx_RunVBlankTransfers_UploadPalette:", transfer)
        self.assertIn("move.w  #$9580,(a0)", transfer)
        self.assertIn("move.w  #$96F1,(a0)", transfer)
        fades = (ROOT / "src/rendering/palette_fades.s").read_text(encoding="utf-8")
        self.assertIn("lea     (PaletteActiveBuffer).w,a0", fades)
        self.assertIn("lea     (PaletteShadowBuffer).w,a1", fades)

    def test_weapon_menu_offsets_follow_separate_axes(self) -> None:
        x_basis = self.records["0xFFFF8032"]["basis"][-1]
        y_basis = self.records["0xFFFF8034"]["basis"][-1]
        self.assertNotEqual(x_basis, y_basis)
        self.assertIn("X accumulator d5", x_basis)
        self.assertIn("Y accumulator d6", y_basis)
        source = (ROOT / "src/weapons/special_firing_and_feedback.s").read_text(encoding="utf-8")
        self.assertIn("add.w   (WeaponMenuSpawnXOffset).w,d5", source)
        self.assertIn("add.w   (WeaponMenuSpawnYOffset).w,d6", source)

    def test_vdp_register_shadows_have_separate_roles(self) -> None:
        reg1 = self.records["0xFFF7D2"]["basis"]
        reg7 = self.records["0xFFF7DE"]["basis"]
        self.assertNotEqual(reg1, reg7)
        self.assertIn("display-enable", reg1[0])
        self.assertIn("backdrop", reg7[0])
        vblank = (ROOT / "src/rendering/vblank_dma.s").read_text(encoding="utf-8")
        self.assertIn("move.w  (VDPReg1Shadow).w,(a0)", vblank)
        self.assertIn("move.w  (VDPReg7Shadow).w,(a0)", vblank)
        demo = (ROOT / "src/demo/playback.s").read_text(encoding="utf-8")
        self.assertIn("bclr    #6,(VDPReg1Shadow+1).w", demo)
        self.assertIn("move.b  #$10,(VDPReg7Shadow+1).w", demo)

    def test_shared_pattern_rows_have_exact_physical_range_review(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        basis = (
            "Many mutually exclusive scene and boss users overlap this range, so the "
            "physical row name does not claim one subsystem owner."
        )
        review = next(item for item in reviews if item["basis"] == basis)
        self.assertEqual(
            ["0xFFFF9400", "0xFFFF9420"],
            [member["address"] for member in review["members"]],
        )
        source = (ROOT / "src/effects/transition_scroll.s").read_text(encoding="utf-8")
        self.assertIn("movea.w #(TransitionPatternRow0-M68K_RAM),a0", source)
        self.assertIn("movea.w #(TransitionPatternRow1-M68K_RAM),a1", source)
        self.assertIn("dbf     d7,Effect_ApplyTransitionMask_Loop", source)

    def test_epsilon_tables_are_physical_overlays_not_independent_allocations(self) -> None:
        reviews = {
            item["basis"]: item
            for item in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        cases = (
            (
                "The table is accessed from its base by indexed or sequential word operations; Results independently overlaps the same storage.",
                ("0xFFFF946A", "0xFFFF946E"),
                "Epsilon1RowOffsetTable",
                "SharedPatternStateLong3",
                "$FFFF9466",
            ),
            (
                "This longword supplies the next four bytes of Epsilon1RingPhaseTable and is cleared with that table's first half.",
                ("0xFFFF9452", "0xFFFF9456"),
                "Epsilon1RingPhaseTable",
                "SharedPatternStateLong0",
                "$FFFF944E",
            ),
        )
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        core = (ROOT / "src/bosses/epsilon_1_core.s").read_text(encoding="utf-8")
        for basis, addresses, alias, first, location in cases:
            with self.subTest(alias=alias):
                self.assertEqual(
                    list(addresses),
                    [member["address"] for member in reviews[basis]["members"]],
                )
                self.assertRegex(ram, rf"(?m)^{re.escape(alias)}[ \t]+equ[ \t]+{re.escape(first)}$")
                self.assertRegex(ram, rf"(?m)^{re.escape(first)}[ \t]+equ[ \t]+{re.escape(location)}(?:[ \t]|$)")
                for offset in ("", "+4", "+8"):
                    self.assertIn(f"clr.l   ({alias}{offset}).w", core)
                for address in addresses:
                    self.assertIn(basis, self.records[address]["basis"])
        scroll = (ROOT / "src/bosses/epsilon_1_shared_support.s").read_text(encoding="utf-8")
        projectiles = (ROOT / "src/projectiles/epsilon_1_projectiles.s").read_text(encoding="utf-8")
        results = (ROOT / "src/ui/results_scrolling.s").read_text(encoding="utf-8")
        self.assertIn("lea     (Epsilon1RowOffsetTable).w,a4", scroll)
        self.assertIn("add.w   (a4)+,d3", scroll)
        self.assertIn("lea     (Epsilon1RowOffsetTable).w,a1", projectiles)
        self.assertIn("lea     (Epsilon1RingPhaseTable).w,a1", projectiles)
        self.assertIn("lea     (ResultsStageRowBuffer).w,a0", results)


if __name__ == "__main__":
    unittest.main()
