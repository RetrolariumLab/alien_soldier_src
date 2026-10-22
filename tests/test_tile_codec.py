from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "scripts" / "authoring"))

from authoring.tile_codec import (  # noqa: E402
    TILE_BYTES,
    TILE_PIXELS,
    Bits,
    BitWriter,
    compress,
    decode_tile,
    decompress,
    pack_tile,
    report,
    unpack_tile,
)
from authoring.lzss_codec import LABEL_BYTES, read_asset_records  # noqa: E402


def tile_codec_payloads():
    """Every payload an asset list loads with command two or three."""
    binclude = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"([^"]+)"')
    names = {}
    for path in sorted((ROOT / "src").rglob("*.s")):
        for line in path.read_text(encoding="utf-8").splitlines():
            match = binclude.match(line)
            if match:
                names[match.group(1)] = match.group(2)
    wanted = {}
    for path in sorted((ROOT / "src").rglob("*.s")):
        lines = path.read_text(encoding="utf-8").splitlines()
        label, body = None, []
        for index, line in enumerate(lines + [""]):
            head = LABEL_BYTES.match(line)
            if head or index == len(lines):
                if label and body:
                    for command, source in read_asset_records(body) or []:
                        if command in (2, 3) and source in names:
                            wanted[source] = names[source]
                if head:
                    label, body = head.group("name"), [head.group("rest")]
                continue
            if label is not None:
                body.append(line)
    return wanted


class CartridgeTests(unittest.TestCase):
    """The seven payloads the second codec carries."""

    def setUp(self) -> None:
        self.payloads = tile_codec_payloads()
        if not self.payloads:
            self.skipTest("no tile-codec payloads found")

    def test_the_set_is_the_seven_we_know_about(self) -> None:
        self.assertEqual(7, len(self.payloads))
        self.assertIn("SharedMenuType3DataF680", self.payloads)

    def test_every_one_decodes_to_whole_tiles(self) -> None:
        for name, relative in sorted(self.payloads.items()):
            facts = report((ROOT / relative).read_bytes())
            self.assertEqual(0, facts["bytes"] % TILE_BYTES, name)
            self.assertEqual(facts["tiles"] * TILE_BYTES, facts["bytes"], name)

    def test_every_one_consumes_its_input_exactly(self) -> None:
        """The check that caught the header fault in the other codec.

        A wrong reading of the format would stop early or run off the end; ending
        on the final byte, give or take the padding of a partial one, is what
        says the format was read right.
        """
        for name, relative in sorted(self.payloads.items()):
            facts = report((ROOT / relative).read_bytes())
            self.assertIn(facts["slack"], (0, 1), "%s read %d of %d bytes" % (name, facts["read"], facts["size"]))


class FormatTests(unittest.TestCase):
    def test_a_tile_is_sixty_four_pixels_in_thirty_two_bytes(self) -> None:
        self.assertEqual(64, TILE_PIXELS)
        self.assertEqual(32, TILE_BYTES)

    def test_packing_puts_the_first_pixel_in_the_high_nibble(self) -> None:
        slot = [0] * TILE_PIXELS
        slot[0], slot[1] = 0xA, 0xB
        self.assertEqual(0xAB, pack_tile(slot)[0])

    def test_the_bit_stream_reads_most_significant_first(self) -> None:
        bits = Bits(bytes([0b10110000, 0b01000000]), 0)
        self.assertEqual(0b101, bits.read(3))
        self.assertEqual(0b10000, bits.read(5))
        self.assertEqual(0b010, bits.read(3))

    def test_a_run_carries_the_colour_a_marker_seeded(self) -> None:
        """The whole point of the format: a marker turns the fill that reaches it."""
        found = False
        for name, relative in sorted(tile_codec_payloads().items()):
            raw = (ROOT / relative).read_bytes()
            bits = Bits(raw, 1)
            slot = decode_tile(bits)
            if len(set(slot)) > 2:
                found = True
                break
        self.assertTrue(found, "no tile used more than two colours")

    def test_a_short_payload_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            decompress(b"\x00")


class EncodeTests(unittest.TestCase):
    """What we write, the cartridge's own decoder has to read back."""

    def test_every_payload_survives_a_round_trip(self) -> None:
        for name, relative in sorted(tile_codec_payloads().items()):
            plain = decompress((ROOT / relative).read_bytes())
            self.assertEqual(plain, decompress(compress(plain)), name)

    def test_what_we_write_is_larger_than_the_original(self) -> None:
        """Honest about the bargain: no markers means no edge coding.

        A marker places a pixel on the row below for two bits where a run needs
        a fresh token, so the original is much the smaller. The streams decode
        to the same pixels, which is what matters; this pins the cost so that
        an encoder which learns to emit markers shows up as a change here.
        """
        original = mine = 0
        for name, relative in sorted(tile_codec_payloads().items()):
            raw = (ROOT / relative).read_bytes()
            original += len(raw)
            mine += len(compress(decompress(raw)))
        self.assertGreater(mine, original)
        self.assertLess(mine, original * 2)

    def test_a_payload_is_an_even_number_of_bytes(self) -> None:
        """The decoder fetches words, and every original is even."""
        for name, relative in sorted(tile_codec_payloads().items()):
            plain = decompress((ROOT / relative).read_bytes())
            self.assertEqual(0, len(compress(plain)) % 2, name)
            self.assertEqual(0, len((ROOT / relative).read_bytes()) % 2, name)

    def test_the_count_byte_says_how_many_tiles(self) -> None:
        one = compress(bytes(TILE_BYTES))
        self.assertEqual(0, one[0])
        self.assertEqual(TILE_BYTES, len(decompress(one)))
        four = compress(bytes(TILE_BYTES * 4))
        self.assertEqual(3, four[0])

    def test_a_part_tile_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            compress(bytes(TILE_BYTES - 1))

    def test_the_writer_is_the_reader_turned_round(self) -> None:
        out = BitWriter()
        for value, width in ((0b101, 3), (0b10000, 5), (0b010, 3)):
            out.write(value, width)
        bits = Bits(out.finish(), 0)
        self.assertEqual(0b101, bits.read(3))
        self.assertEqual(0b10000, bits.read(5))
        self.assertEqual(0b010, bits.read(3))

    def test_packing_and_unpacking_are_inverse(self) -> None:
        slot = [(index * 7) % 16 for index in range(TILE_PIXELS)]
        self.assertEqual(slot, unpack_tile(pack_tile(slot)))


class SpecTests(unittest.TestCase):
    """docs/tile_codec_spec.md carries its own code, so it has to still run.

    The document goes out on its own, without this repository, and its worth
    depends on someone being able to paste the reference decoder and encoder
    and have them work. That is checked here rather than assumed.
    """

    def source(self) -> str:
        spec = ROOT / "docs/tile_codec_spec.md"
        fence = "```python\n(.*?)```"
        blocks = re.findall(fence, spec.read_text(encoding="utf-8"), re.S)
        self.assertGreaterEqual(len(blocks), 2, "the spec lost its code")
        return "\n".join(blocks)

    def test_the_spec_code_runs_and_agrees_with_ours(self) -> None:
        namespace: dict = {}
        exec(compile(self.source(), "spec", "exec"), namespace)
        payloads = tile_codec_payloads()
        if not payloads:
            self.skipTest("no tile-codec payloads found")
        for name, relative in sorted(payloads.items()):
            raw = (ROOT / relative).read_bytes()
            plain = decompress(raw)
            self.assertEqual(plain, namespace["decompress"](raw), name)
            self.assertEqual(compress(plain), namespace["compress"](plain), name)

    def test_the_benchmark_table_is_still_true(self) -> None:
        namespace: dict = {}
        exec(compile(self.source(), "spec", "exec"), namespace)
        payloads = tile_codec_payloads()
        if not payloads:
            self.skipTest("no tile-codec payloads found")
        original = naive = 0
        for name, relative in sorted(payloads.items()):
            raw = (ROOT / relative).read_bytes()
            original += len(raw)
            naive += len(namespace["compress"](namespace["decompress"](raw)))
        spec = (ROOT / "docs/tile_codec_spec.md").read_text(encoding="utf-8")
        self.assertIn("**%d**" % original, spec, "the total original size moved")
        self.assertIn("**%d**" % naive, spec, "the total naive size moved")


if __name__ == "__main__":
    unittest.main()
