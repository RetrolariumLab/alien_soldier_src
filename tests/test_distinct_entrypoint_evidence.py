"""Keep entrypoint, inner-loop, VBlank, and HBlank evidence distinct."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def between(source: str, start: str, end: str) -> str:
    return source.split(start, 1)[1].split(end, 1)[0]


class DistinctEntrypointEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }

    def test_entry_and_loop_bases_do_not_conflate_work(self) -> None:
        pairs = (
            ("0x00306C", "0x003076", "448 bytes", "16 bytes"),
            ("0x0566B6", "0x0566BC", "metasprite group", "DBF loop"),
            ("0x0017B6", "0x001848", "recurring VBlank", "installed HBlank"),
            ("0x001904", "0x00194A", "installs", "CRAM byte address"),
        )
        for entry, inner, entry_claim, inner_claim in pairs:
            with self.subTest(entry=entry, inner=inner):
                entry_bases = self.audit[entry]["basis"]
                inner_bases = self.audit[inner]["basis"]
                self.assertTrue(any(entry_claim in basis for basis in entry_bases))
                self.assertTrue(any(inner_claim in basis for basis in inner_bases))
                self.assertFalse(set(entry_bases) & set(inner_bases))

        vblank = self.audit["0x0017B6"]
        self.assertEqual(
            "VBlank_InitStage10Effect_RefreshScrollAndBuffer",
            vblank["current_name"],
        )
        self.assertEqual("VBlank_InitStage10Effect_UpdateRegisters", vblank["previous_name"])
        self.assertEqual("loc_17B6", vblank["legacy_name"])

    def test_clear_loops_have_different_scope_from_entrypoints(self) -> None:
        oam = (ROOT / "src/system/memory_initialization.s").read_text(encoding="utf-8")
        oam = between(oam, "Sprite_ClearOAMBuildState:", "; End of function Sprite_ClearOAMBuildState")
        self.assertIn("lea     (SpriteOAMEntryCount).w,a0", oam)
        self.assertIn("move.w  #$1B,d1", oam)
        loop = oam.split("Sprite_ClearOAMBuildState_Loop:", 1)[1]
        self.assertEqual(4, loop.count("move.l  d0,(a0)+"))
        self.assertIn("dbf     d1,Sprite_ClearOAMBuildState_Loop", loop)

        valkirie = (ROOT / "src/bosses/valkirie_rendering.s").read_text(encoding="utf-8")
        valkirie = between(
            valkirie,
            "Entity_InitValkirieAuxiliaryGroup:",
            "; End of function Entity_InitValkirieAuxiliaryGroup",
        )
        self.assertIn("moveq   #5,d7", valkirie)
        loop = valkirie.split("Entity_ClearValkirieAuxiliaryGroupLoop:", 1)[1]
        self.assertIn("jsr     (Object_ClearRecord96Bytes).l", loop)
        self.assertIn("dbf     d7,Entity_ClearValkirieAuxiliaryGroupLoop", loop)
        self.assertIn("jsr     (Sprite_InitializeLinkedMetaspriteParts).l", loop)

    def test_vblank_prepares_buffers_and_hblank_consumes_them(self) -> None:
        source = (ROOT / "src/rendering/vblank_effects.s").read_text(encoding="utf-8")
        stage10 = between(
            source,
            "VBlank_InitStage10Effect:",
            "; End of function VBlank_InitStage10Effect",
        )
        self.assertIn("bne.w   VBlank_InitStage10Effect_RefreshScrollAndBuffer", stage10)
        self.assertIn("(Stage10HBlankScrollData-M68K_RAM),a0", stage10)
        self.assertIn("(Stage10HBlankScrollData-M68K_RAM),a6", stage10)
        hblank = between(source, "HBlank_UpdateStage10Display:", "; End of function HBlank_UpdateStage10Display")
        self.assertIn("move.w  (a6)+,(VDP_DATA).l", hblank)

        cram_setup = between(
            source,
            "VBlank_InitCRAMWriteEffect:",
            "; End of function VBlank_InitCRAMWriteEffect",
        )
        self.assertIn("HBlank_WriteCRAMColor5_InstallList(pc),a0", cram_setup)
        self.assertIn("jsr     (LoadObjData).l", cram_setup)
        self.assertIn("(CRAMWriteEffectBuffer).w,a6", cram_setup)
        cram_hblank = between(source, "HBlank_WriteCRAMColor5:", "; End of function HBlank_WriteCRAMColor5")
        self.assertIn("move.l  #$C00A0000,(VDP_CTRL).l", cram_hblank)
        self.assertIn("move.w  (a6)+,(VDP_DATA).l", cram_hblank)
        self.assertIn("rte", cram_hblank)


if __name__ == "__main__":
    unittest.main()
