from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class FrontendBoundaryAndRamEvidenceTests(unittest.TestCase):
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

    def test_frontend_lists_have_distinct_lengths_and_stop_conditions(self) -> None:
        source = (ROOT / "src/ui/options_shared_helpers_and_assets.s").read_text(encoding="utf-8")
        title = source.split("Frontend_TitleAssetLoadDescriptors:", 1)[1].split("Options_AssetLoadDescriptors:", 1)[0]
        options = source.split("Options_AssetLoadDescriptors:", 1)[1].split("Options_OnLabelTiles:", 1)[0]
        self.assertEqual(8, len(re.findall(r"\bdc\.l\s+", title)))
        self.assertEqual(5, len(re.findall(r"\bdc\.l\s+", options)))
        self.assertRegex(title, r"dc\.w\s+\$FFFF\s*$")
        self.assertNotIn("$FFFF", options)
        self.assertRegex(source, r"Options_OnLabelTiles:\s+dc\.w\s+\$8332")
        loader = (ROOT / "src/gameplay/object_data.s").read_text(encoding="utf-8")
        self.assertIn("move.w  (a0)+,d0", loader)
        self.assertIn("bmi.w   LoadObjData_Return", loader)
        self.assertIn("LoadCompressedToRAM", loader)
        self.assertNotEqual(
            self.records["0x00A1B6"]["basis"],
            self.records["0x00A1F8"]["basis"],
        )

    def test_cursor_tables_use_different_selectors_and_lengths(self) -> None:
        source = (ROOT / "src/ui/options_shared_helpers_and_assets.s").read_text(encoding="utf-8")
        self.assertIn(
            "Options_CursorYPositions:   dc.w    $B3, $D3, $E3, $FB, $10B, $11B",
            source,
        )
        self.assertIn(
            "SecondaryOptions_CursorYPositions:  dc.w    $CA, $DA, $EA, $FA, $10A",
            source,
        )
        self.assertIn("move.w  (OptionsHandlerOffset).w,d0", source)
        self.assertIn("move.w  (OptionsSelection).w,d0", source)
        self.assertIn("move.w  (a0,d0.w),$14(a1)", source)
        self.assertNotEqual(
            self.records["0x00A112"]["basis"],
            self.records["0x00A15E"]["basis"],
        )

    def test_unnamed_ram_origins_keep_only_positive_usage_evidence(self) -> None:
        cutscene = self.records["0xFFFF0400"]["basis"]
        stage = self.records["0xFFFF6000"]["basis"]
        self.assertEqual(1, len(cutscene))
        self.assertEqual(1, len(stage))
        self.assertIn("CutsceneProjection_BuildFrame", cutscene[0])
        self.assertIn("Gfx_ResampleStage3Phase2Tiles", stage[0])
        projection = (ROOT / "src/cutscenes/frame_projection.s").read_text(encoding="utf-8")
        resample = (ROOT / "src/rendering/stage3_tile_resampling.s").read_text(encoding="utf-8")
        self.assertIn("movea.l #CutsceneFrameSourceBuffer,a0", projection)
        self.assertIn("movea.l #Stage3ResampleBuffer,a2", resample)

    def test_sharpssteel_priority_loops_have_opposite_effects(self) -> None:
        clear = self.records["0x0486AA"]["basis"][0]
        set_ = self.records["0x0486BE"]["basis"][0]
        self.assertNotEqual(clear, set_)
        self.assertIn("clears memory bit seven", clear)
        self.assertIn("sets memory bit seven", set_)
        source = (ROOT / "src/bosses/sharpssteel_blades.s").read_text(encoding="utf-8")
        for entry, operation in (
            ("Boss_SharpssteelClearBladePartPriorityBits", "bclr"),
            ("Boss_SharpssteelSetBladePartPriorityBits", "bset"),
        ):
            with self.subTest(entry=entry):
                block = source.split(entry + ":", 1)[1].split("; End of function " + entry, 1)[0]
                self.assertIn("moveq   #$11,d7", block)
                self.assertIn(f"{operation}    d0,$E(a0)", block)

    def test_z80_voice_slot_flag_review_is_exact(self) -> None:
        basis = "Descriptor byte five is copied here and selection compares its upper priority bits with new requests."
        self.assert_review(basis, ["0xA01F87", "0xA01FA7"])
        source = (ROOT / "src/sound/command_dispatch_and_dac.s").read_text(encoding="utf-8")
        self.assertIn("move.b  5(a0),(Z80VoiceSlotAFlags).l", source)
        self.assertIn("move.b  5(a0),(Z80VoiceSlotBFlags).l", source)
        self.assertIn("move.b  (Z80VoiceSlotAFlags).l,d2", source)
        self.assertIn("move.b  (Z80VoiceSlotBFlags).l,d3", source)

    def test_viblack_return_review_distinguishes_slot_searches(self) -> None:
        basis = "Disabled-spawn and allocation-failure paths return here."
        self.assert_review(basis, ["0x04418C", "0x04427A"])
        source = (ROOT / "src/bosses/viblack_support.s").read_text(encoding="utf-8")
        for entry, ret, finder in (
            (
                "Boss_ViblackSpawnNearbyDefeatParticle",
                "Boss_ViblackSpawnNearbyDefeatParticleReturn",
                "Projectile_FindFreeSlotForward",
            ),
            (
                "Boss_ViblackSpawnTransitionDebris",
                "Boss_ViblackSpawnTransitionDebrisReturn",
                "Projectile_FindFreeSlotReverse",
            ),
        ):
            with self.subTest(entry=entry):
                block = source.split(entry + ":", 1)[1].split(ret + ":", 1)[0]
                self.assertIn("btst    #0,(FrameCounter+1).w", block)
                self.assertRegex(block, rf"bne\.[sw]\s+{ret}")
                self.assertIn(f"({finder}).l", block)


if __name__ == "__main__":
    unittest.main()
