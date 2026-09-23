"""Source-only and local TAS checks for Sniper Honeyviper name-table writes."""

from __future__ import annotations

import hashlib
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.stage4_boss_tilemap_model import (  # noqa: E402
    PLANE_COLUMNS, PLANE_ROWS, PRIMARY_TRANSFER_ROWS,
    build_sniper_honeyviper_name_tables)
from authoring.stage_renderer import read_once, scene  # noqa: E402
from authoring.stage_tilemap_model import decompress  # noqa: E402
from runtime_state import Genstate  # noqa: E402


STATE_SHA256 = {
    5399: "427eea49bf03aed91ab89cbeac85f84344cd95ffb4565e1bd0282c095c9189ac",
    5499: "263f038ab8eb7c05eac84324796dff6856082bf82a83cd020725f470679e80c7",
    5599: "9899ae7d717054ca8db7b18cdc6a354c462ae1cab712b4a07f8be307b825a633",
    5799: "aa164dfcd1036b1cfb8beec0b7ab8206e50e6786ed12cc12c631c6b0798501c4",
}


class SniperHoneyviperNameTableTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tables = build_sniper_honeyviper_name_tables(ROOT)

    def test_source_writers_and_table_shapes_are_explicit(self) -> None:
        source = (ROOT / "src/bosses/sniper_honeyviper_core.s").read_text(
            encoding="utf-8")
        self.assertIn("Boss_SniperHoneyviperBackgroundConfig:  dc.w    $FFFF, $7000, $FFFF, $6800, $FFFF, $2000, 0, $4000", source)
        self.assertIn("move.w  #$13,(TilemapRowCountdown).w", source)
        self.assertIn("jsr     (Tilemap_QueueIndexedColumns).l", source)
        self.assertEqual(8128, self.tables.shared_mapping_bytes)
        self.assertEqual(PRIMARY_TRANSFER_ROWS, len(self.tables.primary_transferred_rows))
        self.assertTrue(all(len(row) == PLANE_COLUMNS
                            for row in self.tables.primary_transferred_rows))
        self.assertEqual(PLANE_ROWS, len(self.tables.secondary_rows))
        self.assertTrue(all(len(row) == PLANE_COLUMNS
                            for row in self.tables.secondary_rows))
        mapping = decompress(read_once(ROOT)["data"]["SharedBossMappingData2020"])
        self.assertEqual(
            "24f93c449abba469a4f92b34c0c60196ddc6a46b6dc95131354a21c29466b453",
            hashlib.sha256(mapping).hexdigest())
        for rows, expected in (
                (self.tables.primary_transferred_rows,
                 "0cd12b06795c8fa3e96117c8054f5ef92132deab13db4113e3fcad1ed020b1a4"),
                (self.tables.secondary_rows,
                 "852798f84c143190edf3d8577630b2318f7cff92a6e16f2a8be2db38129218e1")):
            raw = b"".join(word.to_bytes(2, "big")
                           for row in rows for word in row)
            self.assertEqual(expected, hashlib.sha256(raw).hexdigest())

        baseline = scene(ROOT, 3).plane_b
        changed = sum(
            self.tables.secondary_rows[row][column]
            != baseline.name_word(column * 8, row * 8)
            for row in range(PLANE_ROWS)
            for column in range(PLANE_COLUMNS))
        self.assertEqual(206, changed)

    def test_local_boss_tables_match_vdp_when_available(self) -> None:
        observed = 0
        baseline = scene(ROOT, 3).plane_b
        mapping = decompress(read_once(ROOT)["data"]["SharedBossMappingData2020"])
        for frame in (5399, 5499, 5599, 5799):
            path = ROOT / f"reference/tas/{frame:06d}.genstate"
            if not path.is_file():
                continue
            observed += 1
            with self.subTest(frame=frame):
                self.assertEqual(
                    STATE_SHA256[frame], hashlib.sha256(path.read_bytes()).hexdigest())
                state = Genstate.read(path)
                self.assertEqual(3, state.m68k_u16(0xFFFFA204) // 2)
                vram = state.sections[0x10]
                for row, words in enumerate(self.tables.primary_transferred_rows):
                    for column, word in enumerate(words):
                        at = 0xC000 + (row * PLANE_COLUMNS + column) * 2
                        self.assertEqual(
                            word, int.from_bytes(vram[at:at + 2], "little"))
                if frame == 5399:
                    # The indexed-column command has not yet replaced B.
                    for row in range(PLANE_ROWS):
                        for column in range(PLANE_COLUMNS):
                            at = 0xE000 + (row * PLANE_COLUMNS + column) * 2
                            self.assertEqual(
                                baseline.name_word(column * 8, row * 8),
                                int.from_bytes(vram[at:at + 2], "little"))
                    continue
                self.assertEqual(
                    mapping,
                    bytes(state.m68k_u8(0xFFFF2020 + index)
                          for index in range(len(mapping))))
                for row, words in enumerate(self.tables.secondary_rows):
                    for column, word in enumerate(words):
                        at = 0xE000 + (row * PLANE_COLUMNS + column) * 2
                        self.assertEqual(
                            word, int.from_bytes(vram[at:at + 2], "little"))
        if observed == 0:
            self.skipTest("private Stage 4 boss genstates are unavailable")


if __name__ == "__main__":
    unittest.main()
