"""Distinguish Xi-Tiger cutscene's RAM and VRAM decompression routes."""

from __future__ import annotations

import hashlib
import json
import re
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from unpack_data import unpack_data  # noqa: E402


def directives(source: str, start: str, end: str) -> list[str]:
    body = source.split(start, 1)[1].split(end, 1)[0]
    return [value.strip() for value in re.findall(r"\bdc\.[wl]\s+([^;\r\n]+)", body)]


class XiTigerCutsceneLoadRouteTests(unittest.TestCase):
    def test_first_three_commands_use_distinct_destinations(self) -> None:
        source = (ROOT / "src/cutscenes/xi_tiger.s").read_text(encoding="utf-8")
        words = directives(
            source,
            "XiTigerCutscene_AssetLoadDescriptors:",
            "XiTigerCutscene_Update:",
        )
        self.assertEqual(
            [
                "7",
                "XiTigerCutsceneTileArt",
                "$6000",
                "6",
                "XiTigerCutsceneTilemapWordSource",
                "$4000",
                "6",
                "XiTigerCutsceneTilemapBlockIndices",
                "$6000",
            ],
            words[:9],
        )
        self.assertIn("lea     XiTigerCutscene_AssetLoadDescriptors(pc),a0", source)
        self.assertIn("jsr     (LoadObjData).l", source)

    def test_loader_types_dispatch_to_different_address_spaces(self) -> None:
        loader = (ROOT / "src/gameplay/object_data.s").read_text(encoding="utf-8")
        handlers = directives(loader, "LoadObjDataHandlers:", "; The source word")
        self.assertEqual("LoadCompressedToRAM", handlers[6])
        self.assertEqual("LoadCompressedToVRAM", handlers[7])
        ram = loader.split("LoadCompressedToRAM:", 1)[1].split("; End of function LoadCompressedToRAM", 1)[0]
        vram = loader.split("LoadCompressedToVRAM:", 1)[1].split("; End of function LoadCompressedToVRAM", 1)[0]
        self.assertIn("moveq   #$FFFFFFFF,d0", ram)
        self.assertIn("move.w  (a0)+,d0", ram)
        self.assertIn("movea.l d0,a2", ram)
        self.assertIn("bsr.w   Data_LZSSDecomp", ram)
        self.assertIn("move.w  (a0)+,d0", vram)
        self.assertIn("movea.l d0,a3", vram)
        self.assertIn("bsr.w   Data_LZSSDecomp", vram)
        self.assertIn("lea     (VDP_DATA).l,a5", vram)

    def test_decoded_sources_and_direct_tilemap_reader(self) -> None:
        source = (ROOT / "src/data/xi_tiger_and_boss_art.s").read_text(encoding="utf-8")
        inline = source.split("XiTigerCutsceneTilemapBlockIndices:", 1)[1].split(
            "XiTigerCutsceneTilemapWordSource:", 1
        )[0]
        parts = [line.split("dc.b", 1)[1].split(";", 1)[0] for line in inline.splitlines() if "dc.b" in line]
        tokens = [token.strip() for part in parts for token in part.split(",")]
        block_indices = bytes(int(token[1:], 16) if token.startswith("$") else int(token) for token in tokens)
        word_source = (ROOT / "data/mappings/byte_11A644.bin").read_bytes()
        self.assertEqual(42, len(block_indices))
        self.assertEqual(696, len(word_source))
        decoded_words, word_error = unpack_data(word_source)
        decoded_indices, index_error = unpack_data(block_indices)
        self.assertIsNone(word_error)
        self.assertIsNone(index_error)
        self.assertIsNotNone(decoded_words)
        self.assertIsNotNone(decoded_indices)
        self.assertEqual(1352, len(decoded_words))
        self.assertEqual(64, len(decoded_indices))
        self.assertEqual(
            "fafc9a67f8eaed0c44c85710e1b8ffbd79998bd406d8f22ffb07d801d7732df2",
            hashlib.sha256(decoded_words).hexdigest(),
        )
        self.assertEqual(
            "b34b9bc9b661439a0d606a41fb6b0ce9d1e260ea17a5ce7fe39bd2a14e13835f",
            hashlib.sha256(decoded_indices).hexdigest(),
        )

        cutscene = (ROOT / "src/cutscenes/xi_tiger.s").read_text(encoding="utf-8")
        self.assertIn("jsr     (Tilemap_DirectTransferFromPrimaryCamera).l", cutscene)
        self.assertIn("jmp     Tilemap_DirectTransferFromSecondaryCamera", cutscene)
        transfer = (ROOT / "src/rendering/tilemap_row_streaming.s").read_text(encoding="utf-8")
        self.assertIn("lea     Gfx_TitleAndZLeoVRAMTransferParameters(pc),a0", transfer)
        self.assertIn("move.b  (a1,d2.w),d4", transfer)
        self.assertIn("move.w  (a1,d3.w),(a2)+", transfer)
        parameters = (ROOT / "src/rendering/boss_asset_sets.s").read_text(encoding="utf-8")
        self.assertRegex(
            parameters,
            r"Gfx_TitleAndZLeoVRAMTransferParameters:\s+dc\.l\s+\$FFFF7000, \$FFFF6000, \$FFFF4000, \$14000",
        )

    def test_name_evidence_distinguishes_all_three_sources(self) -> None:
        records = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        expected = (
            ("0x1198E4", "XiTigerCutsceneTileArt", "type 7", "VRAM $6000"),
            ("0x11A61A", "XiTigerCutsceneTilemapBlockIndices", "type 6", "RAM $FFFF6000"),
            ("0x11A644", "XiTigerCutsceneTilemapWordSource", "type 6", "RAM $FFFF4000"),
        )
        for address, name, loader_type, destination in expected:
            with self.subTest(address=address):
                record = records[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                self.assertIn(loader_type, record["basis"][0])
                self.assertIn(destination, record["basis"][0])
        self.assertEqual("XiTigerCutsceneMappingDataB", records["0x11A61A"]["previous_name"])
        self.assertEqual("byte_11A61A", records["0x11A61A"]["legacy_name"])
        self.assertEqual("XiTigerCutsceneMappingDataA", records["0x11A644"]["previous_name"])
        self.assertEqual("byte_11A644", records["0x11A644"]["legacy_name"])


if __name__ == "__main__":
    unittest.main()
