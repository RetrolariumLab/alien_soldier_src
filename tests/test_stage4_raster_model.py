"""Bounded source and local TAS checks for the Stage 4 raster-profile writer."""

from __future__ import annotations

import hashlib
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.stage4_raster_model import (  # noqa: E402
    PRIMARY_LINES, SECONDARY_LINES, VISIBLE_PRIMARY_PROFILE_LINES,
    sniper_honeyviper_horizontal_profile, sniper_honeyviper_primary_rows,
    sniper_honeyviper_secondary_rows)
from authoring.stage_tilemap_model import decompress  # noqa: E402
from runtime_state import Genstate  # noqa: E402


LOCAL_STATES = (
    (5399, 0x26,
     "427eea49bf03aed91ab89cbeac85f84344cd95ffb4565e1bd0282c095c9189ac",
     "21641206e5d96aa4e96bf22241634454175c2355458ca6e57d83aa60238aa7de"),
    (5499, 0x28,
     "263f038ab8eb7c05eac84324796dff6856082bf82a83cd020725f470679e80c7",
     "d2d7306909759212b13d391e1147fdb4feadd2e05a41003de53ac0646624833c"),
    (5599, 0x28,
     "9899ae7d717054ca8db7b18cdc6a354c462ae1cab712b4a07f8be307b825a633",
     "41678b2ed573aab90ee9440db3d8d97a8cb3b026e6336ac7f2d08b8f401a94d3"),
    (5799, 0x28,
     "aa164dfcd1036b1cfb8beec0b7ab8206e50e6786ed12cc12c631c6b0798501c4",
     "567e3be2f0e83c53d57e2a77bc585f4b41389f76b9d4095a37e6c64f52b2912d"),
)


class Stage4RasterProfileTests(unittest.TestCase):
    def test_boss_tile_asset_matches_loaded_vram_when_locally_available(self) -> None:
        source = (ROOT / "src/bosses/sniper_honeyviper_core.s").read_text(
            encoding="utf-8")
        start = source.index("Boss_SniperHoneyviperInitialAssetDescriptors:")
        end = source.index("Boss_SniperHoneyviperQueueIndexedTileColumnsAfterAssets:")
        self.assertIn("dc.w    7", source[start:end])
        self.assertIn("dc.l    Boss_SniperHoneyviperTileArt", source[start:end])
        self.assertIn("dc.w    $6000", source[start:end])
        art_source = (ROOT / "src/data/gameplay_tile_art.s").read_text(
            encoding="utf-8")
        self.assertIn('Boss_SniperHoneyviperTileArt:           binclude "data/artcomp/tiles_10DA6C.bin"',
                      art_source)
        body = decompress((ROOT / "data/artcomp/tiles_10DA6C.bin").read_bytes())
        self.assertEqual(8832, len(body))
        self.assertEqual(
            "01249845dc27b40e0110bf5140ab772e0578fa6a6a974b9f4917121c116a5d03",
            hashlib.sha256(body).hexdigest())
        observed = 0
        for frame in (5499, 5599, 5799):
            path = ROOT / f"reference/tas/{frame:06d}.genstate"
            if not path.is_file():
                continue
            observed += 1
            with self.subTest(frame=frame):
                state = Genstate.read(path)
                vram = state.sections[0x10][0x6000:0x6000 + len(body)]
                # Gens serializes VRAM as little-endian words; source art
                # and the cartridge DMA stream are in 68000 byte order.
                cartridge_order = bytes(
                    byte for index in range(0, len(vram), 2)
                    for byte in (vram[index + 1], vram[index]))
                self.assertEqual(body, cartridge_order)
        if observed == 0:
            self.skipTest("private Stage 4 boss genstates are unavailable")

    def test_source_loop_widths_and_order_are_explicit(self) -> None:
        source = (ROOT / "src/stages/early_stage_process_states.s").read_text(
            encoding="utf-8")
        start = source.index("Stage4_FillSniperHoneyviperHorizontalRasterOffsets:")
        end = source.index("; End of function Stage4_FillSniperHoneyviperHorizontalRasterOffsets")
        block = source[start:end]
        self.assertLess(block.index("(SecondaryCameraXPos).w"),
                        block.index("#$7F,d7"))
        self.assertLess(block.index("#$7F,d7"),
                        block.index("(PrimaryCameraXPosition).w"))
        self.assertIn("#$47,d7", block)
        self.assertEqual(0x80, SECONDARY_LINES)
        self.assertEqual(0x48, PRIMARY_LINES)
        copier = (ROOT / "src/rendering/scroll_plane_buffers.s").read_text(
            encoding="utf-8")
        start = copier.index("Scroll_CopyHorizontalProfile:")
        end = copier.index("Scroll_CopyHorizontalCellProfile:")
        block = copier[start:end]
        self.assertIn("move.w  #$BF,d7", block)
        self.assertIn("move.w  d1,d0", block)
        self.assertEqual(0xC0, VISIBLE_PRIMARY_PROFILE_LINES)

    def test_quarter_camera_profile_keeps_the_write_time_value(self) -> None:
        words = sniper_honeyviper_horizontal_profile(0x1AF8)
        self.assertEqual(200, len(words))
        self.assertEqual(((-0x6BE) & 0xFFFF,) * 128, words[:128])
        self.assertEqual(((-0x1AF8) & 0xFFFF,) * 72, words[128:])
        self.assertEqual(words[:192], sniper_honeyviper_primary_rows(words, 0))
        self.assertEqual(words[1:193], sniper_honeyviper_primary_rows(words, 1))
        with self.assertRaises(ValueError):
            sniper_honeyviper_horizontal_profile(0x8000)
        with self.assertRaises(ValueError):
            sniper_honeyviper_primary_rows(words, -1)
        with self.assertRaises(ValueError):
            sniper_honeyviper_primary_rows(words, 9)

    def test_secondary_writer_preserves_descending_spans_and_signed_steps(self) -> None:
        source = (ROOT / "src/bosses/sniper_honeyviper_scroll_and_effects.s").read_text(
            encoding="utf-8")
        start = source.index("Boss_SniperHoneyviperUpdatePositionAndLineScroll:")
        end = source.index("; End of function Boss_SniperHoneyviperUpdatePositionAndLineScroll")
        block = source[start:end]
        for operation in (
                "HScrollPlaneBRow32", "move.w  #$BF,d7", "moveq   #$32,d7",
                "divs.w  d7,d1", "moveq   #$45,d7"):
            self.assertIn(operation, block)
        rows = sniper_honeyviper_secondary_rows(560, 265, 564, 330)
        self.assertEqual(192, len(rows))
        self.assertEqual((-128) & 0xFFFF, rows[32 - 32])
        self.assertEqual(392, rows[73 - 32])
        self.assertEqual(393, rows[145 - 32])
        self.assertEqual(396, rows[202 - 32])
        self.assertEqual((-128) & 0xFFFF, rows[203 - 32])
        rising = sniper_honeyviper_secondary_rows(409, 263, 398, 336)
        self.assertEqual(239, rising[142 - 32])
        self.assertEqual(236, rising[146 - 32])
        self.assertEqual(230, rising[208 - 32])
        with self.assertRaises(ValueError):
            sniper_honeyviper_secondary_rows(560, 265, 564, 100)

    def test_local_boss_states_match_source_profile_and_vblank_dma(self) -> None:
        observed = 0
        for frame, state_offset, state_sha256, scroll_sha256 in LOCAL_STATES:
            path = ROOT / f"reference/tas/{frame:06d}.genstate"
            if not path.is_file():
                continue
            observed += 1
            with self.subTest(frame=frame):
                self.assertEqual(
                    state_sha256, hashlib.sha256(path.read_bytes()).hexdigest())
                state = Genstate.read(path)
                self.assertEqual(3, state.m68k_u16(0xFFFFA204) // 2)
                self.assertEqual(state_offset, state.m68k_u16(0xFFFFA950))
                self.assertEqual(3, state.sections[0x13][11])
                self.assertEqual(0x3C, state.sections[0x13][13])
                primary = state.m68k_u16(0xFFFFA900)
                expected = sniper_honeyviper_horizontal_profile(primary)
                observed_profile = tuple(
                    state.m68k_u16(0xFFFF8800 + 2 * index)
                    for index in range(len(expected)))
                self.assertEqual(expected, observed_profile)
                shake = state.m68k_u16(0xFFFFA012)
                self.assertIn(shake, (0, 1))
                self.assertEqual(
                    sniper_honeyviper_primary_rows(expected, shake),
                    tuple(state.m68k_u16(0xFFFFE400 + 4 * row)
                          for row in range(32, 224)))
                if state_offset == 0x28:
                    boss = 0xFFFFC620
                    self.assertEqual(0x24, state.m68k_u16(boss))
                    fields = tuple(state.m68k_u16(boss + offset)
                                   for offset in (0x10, 0x14, 0x70, 0x74))
                    self.assertEqual(
                        sniper_honeyviper_secondary_rows(*fields),
                        tuple(state.m68k_u16(0xFFFFE402 + 4 * row)
                              for row in range(32, 224)))
                if frame == 5499:
                    # The handler overwrites this field after filling the profile.
                    self.assertEqual(0xC0, state.m68k_u16(0xFFFFA908))

                vram = state.sections[0x10]
                hscroll = vram[0xF000:0xF380]
                self.assertEqual(scroll_sha256, hashlib.sha256(hscroll).hexdigest())
                self.assertEqual(
                    tuple(state.m68k_u16(0xFFFFE400 + 2 * index)
                          for index in range(448)),
                    tuple(int.from_bytes(hscroll[2 * index:2 * index + 2],
                                         "little") for index in range(448)))
        if observed == 0:
            self.skipTest("private Stage 4 boss genstates are unavailable")


if __name__ == "__main__":
    unittest.main()
