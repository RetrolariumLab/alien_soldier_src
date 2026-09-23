from __future__ import annotations

import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.tile_graphics import (  # noqa: E402
    ART_DIRECTORY, CRAM_LEVELS, GRAPHICS_CONFIG, TILE_BYTES, TILE_SIZE,
    cram_to_rgb, decode_tile, declared_art, encode_tile, greyscale_palette,
    read_blocks, read_sheet, rgb_to_cram, sheet_from_bytes, sheet_image,
    survey, write_png)


class ColourTests(unittest.TestCase):
    def test_a_cram_word_puts_each_channel_where_the_vdp_does(self) -> None:
        """0000 BBB0 GGG0 RRR0, three bits apiece."""
        self.assertEqual((0, 0, 0), cram_to_rgb(0x0000))
        self.assertEqual((255, 255, 255), cram_to_rgb(0x0EEE))
        self.assertEqual((255, 0, 0), cram_to_rgb(0x000E))
        self.assertEqual((0, 255, 0), cram_to_rgb(0x00E0))
        self.assertEqual((0, 0, 255), cram_to_rgb(0x0E00))

    def test_the_unused_bits_of_a_cram_word_change_nothing(self) -> None:
        # Bits 0, 4, 8 and 12-15 are not part of the colour.
        self.assertEqual(cram_to_rgb(0x0246), cram_to_rgb(0xF357))

    def test_every_level_is_distinct_so_a_colour_survives_the_round_trip(self) -> None:
        self.assertEqual(8, len(set(CRAM_LEVELS)))
        self.assertEqual(sorted(CRAM_LEVELS), list(CRAM_LEVELS))
        for blue in range(8):
            for green in range(8):
                for red in range(8):
                    word = (blue << 9) | (green << 5) | (red << 1)
                    self.assertEqual(word, rgb_to_cram(*cram_to_rgb(word)))


class TileTests(unittest.TestCase):
    def test_a_tile_is_two_pixels_per_byte_high_nibble_first(self) -> None:
        data = bytes([0x12, 0x34]) + bytes(TILE_BYTES - 2)
        pixels = decode_tile(data)
        self.assertEqual(TILE_SIZE * TILE_SIZE, len(pixels))
        self.assertEqual([1, 2, 3, 4], pixels[:4])
        self.assertEqual(data, encode_tile(pixels))

    def test_a_short_tile_is_refused_rather_than_padded(self) -> None:
        with self.assertRaises(ValueError):
            decode_tile(bytes(TILE_BYTES - 1))
        with self.assertRaises(ValueError):
            encode_tile([0] * 63)

    def test_a_length_word_is_read_and_bare_tiles_are_not_invented(self) -> None:
        tiles = bytes(range(64))                            # two tiles
        chained = sheet_from_bytes("chained", struct.pack(">H", len(tiles)) + tiles)
        self.assertTrue(chained.chained)
        self.assertEqual(2, chained.tile_count)
        self.assertEqual(2, chained.blocks[0].offset)

        bare = sheet_from_bytes("bare", tiles)
        self.assertFalse(bare.chained)
        self.assertEqual(2, bare.tile_count)
        self.assertEqual(0, bare.blocks[0].offset)
        self.assertEqual(chained.tile(1), bare.tile(1))

    def test_bytes_that_are_neither_shape_are_refused(self) -> None:
        self.assertIsNone(read_blocks(b"\x00\x21" + bytes(0x21)))   # not whole tiles
        self.assertIsNone(read_blocks(b"\x00\x20" + bytes(0x1F)))   # runs off the end
        with self.assertRaises(ValueError):
            sheet_from_bytes("ragged", bytes(TILE_BYTES + 1))


class CartridgeArtTests(unittest.TestCase):
    """Read the real payloads, not a fixture that agrees with the code."""

    def test_every_payload_is_a_shape_the_decoder_knows(self) -> None:
        found = survey(ROOT)
        declared = declared_art(ROOT)
        self.assertEqual(declared["payloads"], found["payloads"])
        self.assertEqual(declared["tiles"], found["tiles"])
        self.assertEqual(declared["shapes"], found["kinds"])
        self.assertEqual(len(list((ROOT / ART_DIRECTORY).glob("*.bin"))),
                         found["payloads"])

    def test_a_declared_length_is_the_bytes_that_follow_it(self) -> None:
        for path in sorted((ROOT / ART_DIRECTORY).glob("*.bin")):
            sheet = read_sheet(path)
            if not sheet.chained:
                continue
            for block in sheet.blocks:
                declared = struct.unpack_from(">H", sheet.data, block.offset - 2)[0]
                self.assertEqual(declared, block.byte_count, path.name)
            self.assertEqual(len(sheet.data),
                             sum(block.byte_count + 2 for block in sheet.blocks),
                             path.name)

    def test_the_two_payloads_that_hold_two_blocks_are_read_as_two(self) -> None:
        chained = {path.name: read_sheet(path)
                   for path in sorted((ROOT / ART_DIRECTORY).glob("*.bin"))}
        pairs = sorted(name for name, sheet in chained.items() if len(sheet.blocks) == 2)
        self.assertEqual(["sprite_F8D86.bin", "sprite_FC7AA.bin"], pairs)

    def test_a_real_payload_survives_being_decoded_and_re_encoded(self) -> None:
        sheet = read_sheet(ROOT / ART_DIRECTORY / "sega.bin")
        self.assertEqual(48, sheet.tile_count)
        rebuilt = b"".join(encode_tile(sheet.tile(index))
                           for index in range(sheet.tile_count))
        self.assertEqual(sheet.data, rebuilt)

    def test_reading_past_the_last_tile_is_an_error(self) -> None:
        sheet = read_sheet(ROOT / ART_DIRECTORY / "sega.bin")
        with self.assertRaises(IndexError):
            sheet.tile(sheet.tile_count)


class ImageTests(unittest.TestCase):
    def test_a_sheet_is_laid_out_as_whole_tiles(self) -> None:
        sheet = read_sheet(ROOT / ART_DIRECTORY / "sega.bin")
        image = sheet_image(sheet, greyscale_palette(), columns=16)
        self.assertEqual(16 * TILE_SIZE, len(image[0]))
        self.assertEqual(3 * TILE_SIZE, len(image))

    def test_the_png_writer_produces_a_png(self) -> None:
        image = [[(1, 2, 3), (4, 5, 6)], [(7, 8, 9), (10, 11, 12)]]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "out.png"
            write_png(path, image)
            data = path.read_bytes()
        self.assertEqual(b"\x89PNG\r\n\x1a\n", data[:8])
        self.assertEqual(struct.pack(">2I5B", 2, 2, 8, 2, 0, 0, 0), data[16:29])
        start = data.index(b"IDAT") + 4
        length = struct.unpack_from(">I", data, start - 8)[0]
        raw = zlib.decompress(data[start:start + length])
        self.assertEqual(b"\x00\x01\x02\x03\x04\x05\x06\x00\x07\x08\x09\x0a\x0b\x0c", raw)


class ConfigTests(unittest.TestCase):
    def test_config_and_code_agree_on_what_a_tile_is(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        self.assertEqual(TILE_SIZE, config["tile"]["width"])
        self.assertEqual(TILE_SIZE, config["tile"]["height"])
        self.assertEqual(TILE_BYTES, config["tile"]["bytes"])
        self.assertEqual(list(CRAM_LEVELS), config["cram"]["levels"])
        self.assertTrue(config["cram"]["levels_why"].strip())
        self.assertTrue(config["uncompressed_art"]["shapes_why"].strip())


if __name__ == "__main__":
    unittest.main()
