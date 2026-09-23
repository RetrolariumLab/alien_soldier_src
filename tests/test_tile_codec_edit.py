"""Reader-owned marker shapes and edited tile-codec streams."""

from __future__ import annotations

import random
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.tile_codec import (  # noqa: E402
    Bits, BitWriter, compress, decompress, pack_tile,
)
from authoring.tile_codec_edit import compress_edited, read_plan  # noqa: E402
from tests.test_tile_codec import tile_codec_payloads  # noqa: E402


def marker_fixture() -> bytes:
    out = BitWriter()
    out.write(3, 5)  # colour 1, with a seed at pixel 8
    out.write(2, 2)  # cumulative +8
    out.write(0, 3)  # marker terminator
    out.write(0, 1)
    out.write(0, 1)  # zero run
    out.write(4, 5)  # colour 2; fill pixels 1..63, switching at seed 8
    out.write(0b111110, 6)
    out.write(0, 6)  # run = 64 + 0 - 2 = 62
    result = b"\0" + out.finish()
    return result + bytes(len(result) % 2)


class EditedCodecTests(unittest.TestCase):
    def test_source_marker_owns_pixels_reached_by_later_fill(self):
        source = marker_fixture()
        plan = read_plan(Bits(source, 1))
        self.assertEqual((0,) + (1,) * 7 + (0,) * 56, plan.owners)
        self.assertEqual(pack_tile([1] + [2] * 7 + [1] * 56), decompress(source))

    def test_recolouring_preserves_marker_paths_and_bit_length(self):
        source = marker_fixture()
        expected = pack_tile([7] + [4] * 7 + [7] * 56)
        encoded = compress_edited(source, expected)
        self.assertEqual(expected, decompress(encoded))
        self.assertEqual(len(source), len(encoded))
        old = read_plan(Bits(source, 1))
        new = read_plan(Bits(encoded, 1))
        self.assertEqual((old.start, old.end, old.owners),
                         (new.start, new.end, new.owners))

    def test_single_pixel_can_break_a_source_colour_group(self):
        source = marker_fixture()
        target = bytearray(decompress(source))
        target[10] ^= 0x10
        encoded = compress_edited(source, bytes(target))
        self.assertEqual(bytes(target), decompress(encoded))

    def test_changed_tile_can_shift_the_next_unaligned_source_tile(self):
        source = compress(pack_tile([1] * 64) + pack_tile([2] * 64))
        target = bytearray(decompress(source))
        target[0] = 0x31
        encoded = compress_edited(source, bytes(target))
        self.assertEqual(bytes(target), decompress(encoded))
        self.assertEqual(decompress(source)[32:], decompress(encoded)[32:])

    def test_zero_edit_preserves_padding_and_exact_original_bytes(self):
        source = marker_fixture() + b"\xff\xfe"
        self.assertEqual(source, compress_edited(source, decompress(source)))

    def test_tile_count_and_malformed_source_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "tile count"):
            compress_edited(marker_fixture(), bytes(64))
        with self.assertRaises(ValueError):
            compress_edited(b"\0", bytes(32))

    def test_bounded_random_edits_round_trip(self):
        rng = random.Random(4130)
        for _ in range(24):
            original = compress(pack_tile([rng.randrange(4) for _ in range(64)]))
            target = bytearray(decompress(original))
            target[rng.randrange(32)] = rng.randrange(256)
            self.assertEqual(bytes(target), decompress(compress_edited(original, bytes(target))))


class SourceTemplateTests(unittest.TestCase):
    def test_all_seven_source_streams_recolour_inside_their_existing_slots(self):
        payloads = tile_codec_payloads()
        self.assertEqual(7, len(payloads))
        for name, path in sorted(payloads.items()):
            with self.subTest(name=name):
                original = (ROOT / path).read_bytes()
                plain = decompress(original)
                recoloured = bytes(((value >> 4 ^ 1) << 4) | ((value & 15) ^ 1)
                                   for value in plain)
                edited = compress_edited(original, recoloured)
                self.assertEqual(recoloured, decompress(edited))
                self.assertLessEqual(len(edited), len(original))
                self.assertEqual(original, compress_edited(original, plain))


if __name__ == "__main__":
    unittest.main()
