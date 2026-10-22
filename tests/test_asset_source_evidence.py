from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class AssetSourceEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = {
            item["address"]: item
            for item in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }

    def test_debris_frame_variants_have_distinct_table_positions(self) -> None:
        source = (ROOT / "src/cutscenes/ship_piece_and_debris.s").read_text(encoding="utf-8")
        table = source.split("ShipDebris_SpriteFrameTable:", 1)[1].split("ShipDebris_InitialXVelocities:", 1)[0]
        frames = re.findall(r"dc\.l\s+(ShipDebris_SpriteFrame\d+)", table)
        self.assertEqual("ShipDebris_SpriteFrame2", frames[3])
        self.assertEqual("ShipDebris_SpriteFrame4", frames[6])
        self.assertIn("move.w  #$310,(a4)", source)
        self.assertIn("move.l  ShipDebris_SpriteFrameTable(pc,d0.w),8(a4)", source)
        self.assertNotEqual(
            self.records["0x1A9C04"]["basis"],
            self.records["0x1A9C58"]["basis"],
        )

    def test_treasure_sources_have_exact_descriptor_slots_and_forms(self) -> None:
        source = (ROOT / "src/credits/palette_data.s").read_text(encoding="utf-8")
        section = source.split("Credits_TreasureAssetLoadList:", 1)[1].split("Credits_SegaPalette:", 1)[0]
        descriptors = re.findall(
            r"dc\.l\s+(Credits_Treasure(?:TileArt|MappingData)\d)\s+"
            r"; field_2\s+dc\.w\s+(\$?[0-9A-F]+)",
            section,
        )
        self.assertEqual(
            [
                ("Credits_TreasureTileArt0", "0"),
                ("Credits_TreasureTileArt1", "$8000"),
                ("Credits_TreasureMappingData0", "$C000"),
                ("Credits_TreasureMappingData1", "$E000"),
            ],
            descriptors,
        )
        assets = (ROOT / "src/data/credits_scene_assets.s").read_text(encoding="utf-8")
        self.assertRegex(assets, r"Credits_TreasureTileArt0:\s+binclude")
        self.assertRegex(assets, r"Credits_TreasureTileArt1:\s+binclude")
        self.assertRegex(assets, r"Credits_TreasureMappingData0:\s+binclude")
        self.assertRegex(assets, r"Credits_TreasureMappingData1:\s+dc\.b")

    def test_boss_load_sources_do_not_claim_following_archives(self) -> None:
        lists = (ROOT / "src/rendering/boss_asset_sets.s").read_text(encoding="utf-8")
        art = (ROOT / "src/data/xi_tiger_and_boss_art.s").read_text(encoding="utf-8")
        cases = (
            ("WolfGaropa", ("$3C00", "$5100"), "UnreferencedWolfGaropaTileArt2"),
            ("ZLeo", ("$5000", "$7000"), "UnreferencedZLeoTileArt2"),
        )
        for owner, destinations, following in cases:
            with self.subTest(owner=owner):
                section = lists.split(f"Boss_{owner}GraphicsLoadList:", 1)[1]
                section = section.split("dc.w    $FFFF", 1)[0]
                for index, destination in enumerate(destinations):
                    symbol = f"Boss_{owner}TileArt{index}"
                    self.assertRegex(
                        section,
                        rf"dc\.l\s+{symbol}\s+; field_2\s+dc\.w\s+"
                        rf"{re.escape(destination)}",
                    )
                    self.assertRegex(art, rf"{symbol}:\s+binclude")
                first_archive = art.split(f"Boss_{owner}TileArt1:", 1)[1]
                self.assertIn(following + ":", first_archive)
                self.assertLess(
                    first_archive.index(following + ":"),
                    first_archive.index(f"Boss_{owner}TileArt1_End:"),
                )


if __name__ == "__main__":
    unittest.main()
