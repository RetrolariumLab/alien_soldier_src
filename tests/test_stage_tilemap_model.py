from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.stage_tilemap_model import (  # noqa: E402
    CHUNK_BYTES,
    COARSE_BYTES,
    COARSE_COLUMNS,
    DECOMPRESS_TO_RAM,
    LOAD_HANDLERS,
    PATTERN_BYTES,
    RAM_BASE,
    AssetCommand,
    Descriptor,
    Tilemap,
    decompress,
    labelled_blocks,
    read_asset_list,
    read_asset_lists,
    read_descriptors,
    stage_loaders,
    stage_tilemaps,
    survey,
)
from authoring.tile_graphics import GRAPHICS_CONFIG  # noqa: E402


def fake_ram(coarse, chunks, patterns):
    ram = bytearray(0x10000)
    ram[0x7000 : 0x7000 + len(coarse)] = coarse
    ram[0x6000 : 0x6000 + len(chunks)] = chunks
    ram[0x4000 : 0x4000 + len(patterns)] = patterns
    return Tilemap("fixture", (), bytes(ram), Descriptor("fixture", 0xFFFF7000, 0xFFFF6000, 0xFFFF4000, False, 0x4000))


class LookupTests(unittest.TestCase):
    def test_a_position_is_split_the_way_the_streamer_splits_it(self) -> None:
        """X >> 8 picks the chunk, (X >> 5) & 7 the pattern, (X >> 3) & 3 the word."""
        coarse = bytearray(COARSE_BYTES)
        coarse[0 * COARSE_COLUMNS + 2] = 5  # chunk 5 at x $200, y 0
        chunks = bytearray(CHUNK_BYTES * 6)
        chunks[5 * CHUNK_BYTES + 1 * 8 + 3] = 9  # pattern 9 at (x&$FF)=$60..7F, y $20..3F
        patterns = bytearray(PATTERN_BYTES * 10)
        patterns[9 * PATTERN_BYTES + 2 * 8 + 1 * 2] = 0x12
        patterns[9 * PATTERN_BYTES + 2 * 8 + 1 * 2 + 1] = 0x34
        tilemap = fake_ram(coarse, chunks, patterns)

        x = 0x200 + (3 << 5) + (1 << 3)
        y = (1 << 5) + (2 << 3)
        self.assertEqual(5, tilemap.coarse_index(x, y))
        self.assertEqual(9, tilemap.chunk_index(x, y))
        self.assertEqual(0x1234, tilemap.name_word(x, y))

    def test_the_three_levels_are_the_sizes_the_shifts_imply(self) -> None:
        # lsl.w #6 on a coarse byte, lsl.w #5 on a chunk byte.
        self.assertEqual(64, CHUNK_BYTES)
        self.assertEqual(32, PATTERN_BYTES)
        self.assertEqual(32 * 32, COARSE_BYTES)

    def test_a_region_runs_to_the_next_base(self) -> None:
        tilemap = fake_ram(bytes(COARSE_BYTES), bytes(CHUNK_BYTES), bytes(PATTERN_BYTES))
        tilemap.written = (("list", "payload", 0x4020, PATTERN_BYTES * 4), ("list", "payload", 0x6000, CHUNK_BYTES * 3))
        # A payload landing at $4020 still counts towards the pattern region.
        self.assertEqual(4 + 1, tilemap.patterns_defined)
        self.assertEqual(3, tilemap.chunks_defined)


class AssetListTests(unittest.TestCase):
    def test_a_record_is_a_command_a_source_and_a_destination(self) -> None:
        lines = ["    dc.w    6", "    dc.l    SomePayload", "    dc.w    $7000", "    dc.w    $FFFF"]
        commands = read_asset_list("fixture", lines)
        self.assertEqual(1, len(commands))
        self.assertEqual(DECOMPRESS_TO_RAM, commands[0].command)
        self.assertEqual("SomePayload", commands[0].source)
        self.assertTrue(commands[0].to_ram)
        self.assertEqual(0x7000, commands[0].ram_offset)

    def test_a_destination_is_sign_extended_into_the_ram_mirror(self) -> None:
        self.assertEqual(0x7000, AssetCommand(6, "x", 0x7000).ram_offset)
        self.assertEqual(RAM_BASE + 0x7000, RAM_BASE + AssetCommand(6, "x", 0x7000).ram_offset)

    def test_something_that_is_not_a_list_is_not_read_as_one(self) -> None:
        self.assertIsNone(read_asset_list("code", ["    move.w  d0,d1"]))
        self.assertIsNone(read_asset_list("short", ["    dc.w    6", "    dc.w    $FFFF"]))
        self.assertIsNone(read_asset_list("unterminated", ["    dc.w    6", "    dc.l    P", "    dc.w    $10"]))
        self.assertIsNone(
            read_asset_list("unknown", ["    dc.w    9", "    dc.l    P", "    dc.w    $10", "    dc.w    $FFFF"])
        )

    def test_the_handler_table_has_eight_entries(self) -> None:
        self.assertEqual(8, len(LOAD_HANDLERS))
        self.assertEqual("LoadCompressedToRAM", LOAD_HANDLERS[DECOMPRESS_TO_RAM])


class CartridgeTilemapTests(unittest.TestCase):
    """Read the real source, not a fixture that agrees with the code."""

    def test_every_payload_bound_for_ram_decompresses(self) -> None:
        data, bodies = labelled_blocks(ROOT)
        lists = read_asset_lists(ROOT, bodies)
        checked = 0
        for commands in lists.values():
            for command in commands:
                if not command.to_ram:
                    continue
                self.assertIn(command.source, data, command.source)
                self.assertTrue(decompress(data[command.source]))
                checked += 1
        self.assertEqual(survey(ROOT)["decompress_to_ram"], checked)

    def test_the_shared_coarse_map_is_exactly_one_kilobyte(self) -> None:
        data, _ = labelled_blocks(ROOT)
        coarse = decompress(data["SharedMappingData7000"])
        self.assertEqual(COARSE_BYTES, len(coarse))
        # Row zero counts up, so a coarse index is mostly just the chunk number
        # and the shape of a level lives in the chunk map.
        self.assertEqual(list(range(COARSE_COLUMNS)), list(coarse[:COARSE_COLUMNS]))

    def test_a_descriptor_is_three_pointers_a_flag_and_a_plane_base(self) -> None:
        descriptors = read_descriptors(ROOT)
        default = descriptors["Gfx_DefaultVRAMTransferParameters"]
        self.assertEqual(0xFFFF7000, default.coarse)
        self.assertEqual(0xFFFF6000, default.chunks)
        self.assertEqual(0xFFFF4000, default.patterns)
        self.assertFalse(default.mirror_to_plane_buffer)
        self.assertEqual(0x4000, default.plane_base)
        self.assertTrue(descriptors["Gfx_TitleAndZLeoVRAMTransferParameters"].mirror_to_plane_buffer)

    def test_every_stage_table_index_reaches_its_asset_lists(self) -> None:
        data, _ = labelled_blocks(ROOT)
        loaders = stage_loaders(ROOT, data)
        maps = stage_tilemaps(ROOT)
        self.assertEqual(len(loaders), len(maps))
        for tilemap in maps:
            self.assertIn("Stage_SharedMappingsLoadList", tilemap.lists)

    def test_the_counts_match_what_config_declares(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        declared = config["stage_tilemaps"]
        found = survey(ROOT)
        for field in (
            "asset_lists",
            "asset_commands",
            "decompress_to_ram",
            "ram_payloads",
            "stage_table_entries",
            "descriptors",
        ):
            self.assertEqual(declared[field], found[field], field)
        self.assertEqual(found["ram_payloads"], found["ram_payloads_decoded"])
        self.assertTrue(declared["format_why"].strip())

    def test_a_known_stage_produces_real_name_table_words(self) -> None:
        tilemap = stage_tilemaps(ROOT)[0]
        self.assertGreater(tilemap.chunks_defined, 0)
        self.assertGreater(tilemap.patterns_defined, 0)
        words = [tilemap.name_word(x * 8, 0) for x in range(32)]
        self.assertTrue(any(word & 0x07FF for word in words), "some column of the first row names a tile")
        for word in words:
            self.assertLess(word & 0x07FF, 0x800)


if __name__ == "__main__":
    unittest.main()
