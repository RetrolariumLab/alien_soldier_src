from __future__ import annotations

import struct
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.lzss_codec import (  # noqa: E402
    ALTERNATE_CONTROL,
    BLOCK,
    LITERAL_CONTROL,
    MATCH_CONTROL,
    MAX_DISTANCE,
    MAX_LITERAL,
    MAX_MATCH,
    MAX_REPEAT,
    PAIR_CONTROL,
    RUN_CONTROL,
    cartridge_payloads,
    compress,
    decompress,
    decompress_as_vram,
    emit,
    parse,
)


SAMPLES = [
    b"\x00",
    b"ab",
    bytes(300),
    b"\xaa" * 40,
    b"\xaa\xbb" * 40,
    bytes(range(256)),
    bytes(range(64)) * 8,
    b"the quick brown fox jumps over the quick brown fox",
    bytes(range(16)) * 100,
    bytes([7, 0] * 50),
]


class TokenTests(unittest.TestCase):
    """Each token type must survive the game's own decoder."""

    def test_every_shape_round_trips(self) -> None:
        for data in SAMPLES:
            self.assertEqual(data, decompress(compress(data)), data[:8])

    def test_the_header_counts_the_bytes_the_decoder_consumes(self) -> None:
        """Not an offset: the hardware stops at body_start + header.

        Data_ProcessPointer_StoreEndPointer builds the stop address that way
        and Data_LZSSDecomp leaves on `cmpa.l a4,a1 / bcc`, so a header one too
        large makes the cartridge read a control byte past the end and append
        up to 33 bytes of whatever follows. All 122 originals end exactly on
        this boundary, and obey the parity law asserted below along with it.
        """
        payload = compress(b"\xaa" * 40)
        size = struct.unpack_from(">H", payload, 0)[0]
        self.assertIn(len(payload) - size, (2, 3), "the header counts the body")
        self.assertEqual(size % 2, len(payload) - size - 2, "a pad byte appears exactly when the header is odd")
        self.assertEqual(b"\xaa" * 40, decompress(payload))

    def test_nothing_to_compress_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            compress(b"")

    def test_a_run_is_cheaper_than_the_literals_it_replaces(self) -> None:
        tokens = parse(b"\xaa" * 33)
        self.assertEqual([("run", 33, 0xAA)], tokens)
        self.assertEqual(2, len(emit(b"\xaa" * 33, tokens)))

    def test_a_pair_run_is_used_where_two_bytes_repeat(self) -> None:
        data = b"\x12\x34" * 20
        kinds = {kind for kind, _, _ in parse(data)}
        self.assertIn("pair", kinds)
        self.assertEqual(data, decompress(compress(data)))

    def test_a_match_reaches_back_no_further_than_the_window(self) -> None:
        data = b"abcdefgh" + bytes(MAX_DISTANCE) + b"abcdefgh"
        self.assertEqual(data, decompress(compress(data)))
        for kind, length, detail in parse(data):
            if kind == "match":
                self.assertLessEqual(detail, MAX_DISTANCE)
                self.assertLessEqual(length, MAX_MATCH)

    def test_the_control_ranges_do_not_overlap(self) -> None:
        self.assertEqual(0x00, LITERAL_CONTROL)
        self.assertEqual(0x20, RUN_CONTROL)
        self.assertEqual(0x40, PAIR_CONTROL)
        self.assertEqual(0x60, ALTERNATE_CONTROL)
        self.assertEqual(0x80, MATCH_CONTROL)
        self.assertEqual(32, MAX_LITERAL)
        self.assertEqual(33, MAX_REPEAT)

    def test_a_literal_run_never_exceeds_its_count_field(self) -> None:
        data = bytes(range(200, 256)) + bytes(range(100))
        for kind, length, _ in parse(data):
            if kind == "literal":
                self.assertLessEqual(length, MAX_LITERAL)
        self.assertEqual(data, decompress(compress(data)))


class CartridgeTests(unittest.TestCase):
    """The real payloads, which is what an editor will be writing back."""

    def test_a_sample_of_the_real_payloads_round_trips(self) -> None:
        found = sorted(cartridge_payloads(ROOT).items())
        self.assertGreater(len(found), 200)
        for name, raw in found[::17]:
            plain = decompress(raw)
            self.assertEqual(plain, decompress(compress(plain)), name)

    def test_our_encoder_is_smaller_than_the_original(self) -> None:
        """Which is why byte identity is a different problem, not this one."""
        found = sorted(cartridge_payloads(ROOT).items())
        original = mine = 0
        for _, raw in found[::17]:
            original += len(raw)
            mine += len(compress(decompress(raw)))
        self.assertLess(mine, original)


class BlockTests(unittest.TestCase):
    """LoadCompressedToVRAM resets the output pointer every $400."""

    def test_no_token_crosses_a_block_boundary(self) -> None:
        data = bytes(range(251)) * 30
        at = 0
        for _, length, _ in parse(data):
            self.assertEqual(at // BLOCK, (at + length - 1) // BLOCK, "a token spanning %d" % at)
            at += length

    def test_no_match_reaches_into_an_earlier_block(self) -> None:
        data = bytes(range(64)) * 60
        at = 0
        for kind, length, detail in parse(data):
            if kind == "match":
                self.assertLessEqual(detail, at - (at // BLOCK) * BLOCK, "a match at %d reaching past its block" % at)
            at += length

    def test_the_strict_decoder_rejects_what_the_loose_one_accepts(self) -> None:
        """A match across a boundary decodes under the RAM loader, not the VRAM one."""
        # Exactly one block of literals, then a match reaching one byte back.
        # At the start of block two that is before the staging buffer.
        body = bytearray()
        for _ in range(BLOCK // MAX_LITERAL):
            body.append(LITERAL_CONTROL | (MAX_LITERAL - 1))
            body.extend(bytes(MAX_LITERAL))
        body.extend([MATCH_CONTROL | (2 << 2), 0x00])
        crossing = struct.pack(">H", len(body)) + bytes(body)
        self.assertEqual(BLOCK + 4, len(decompress(crossing)))
        with self.assertRaises(ValueError):
            decompress_as_vram(crossing)

    def test_every_real_payload_survives_the_strict_decoder(self) -> None:
        for name, raw in sorted(cartridge_payloads(ROOT).items())[::17]:
            plain = decompress(raw)
            self.assertEqual(plain, decompress_as_vram(compress(plain)), name)

    def test_the_originals_obey_the_same_rule(self) -> None:
        """Which is how the rule was found: all of them already do."""
        for name, raw in sorted(cartridge_payloads(ROOT).items())[::23]:
            self.assertEqual(decompress(raw), decompress_as_vram(raw), name)


class AlignmentTests(unittest.TestCase):
    """An odd payload moves everything after it onto an odd address."""

    def test_every_payload_is_an_even_number_of_bytes(self) -> None:
        for data in SAMPLES:
            self.assertEqual(0, len(compress(data)) % 2, data[:8])
        for name, raw in sorted(cartridge_payloads(ROOT).items())[::17]:
            self.assertEqual(0, len(compress(decompress(raw))) % 2, name)

    def test_the_pad_sits_past_what_the_decoder_reads(self) -> None:
        payload = compress(b"abcabcabcabcabc")
        size = struct.unpack_from(">H", payload, 0)[0]
        self.assertIn(len(payload) - size, (2, 3))
        self.assertEqual(size % 2, len(payload) - size - 2)
        self.assertEqual(b"abcabcabcabcabc", decompress(payload))

    def test_the_originals_are_even_too(self) -> None:
        """231 of 232, which is why a VDP DMA source can be a word address."""
        found = cartridge_payloads(ROOT)
        odd = [name for name, raw in found.items() if len(raw) % 2]
        self.assertEqual(["Stage3Phase6MappingData7800"], odd)


if __name__ == "__main__":
    unittest.main()


class HeaderLawTests(unittest.TestCase):
    """The convention the originals follow, pinned so it cannot drift back.

    The encoder once wrote the header as an offset rather than a count, one
    larger than it should be. Nothing caught it, because the decoder used for
    checking read it the same way, so every payload round-tripped while the
    cartridge read a control byte past the end of each one.
    """

    def originals(self):
        found = sorted((ROOT / "data/artcomp").glob("*.bin"))
        if not found:
            self.skipTest("no original payloads to compare against")
        return found

    def test_every_original_pads_exactly_when_its_header_is_odd(self) -> None:
        even_unpadded = odd_padded = 0
        for path in self.originals():
            raw = path.read_bytes()
            if len(raw) < 4:
                continue
            header = struct.unpack_from(">H", raw, 0)[0]
            slack = (len(raw) - 2) - header
            if slack not in (0, 1):
                continue
            self.assertEqual(header % 2, slack, "%s breaks the parity law" % path.name)
            even_unpadded += slack == 0
            odd_padded += slack == 1
        self.assertGreater(even_unpadded, 40)
        self.assertGreater(odd_padded, 40)

    def test_what_we_emit_obeys_the_same_law(self) -> None:
        for path in self.originals()[:24]:
            plain = decompress_as_vram(path.read_bytes())
            mine = compress(plain)
            header = struct.unpack_from(">H", mine, 0)[0]
            self.assertIn(len(mine) - header, (2, 3), path.name)
            self.assertEqual(header % 2, len(mine) - header - 2, path.name)
            self.assertEqual(plain, decompress_as_vram(mine), path.name)


class OneArchivePerFileTests(unittest.TestCase):
    """Every payload file holds exactly one archive, and nothing reaches inside.

    Eight of them used to hold two, with one label on the first, and three
    descriptors reached the second by adding a byte offset to the first's
    symbol. A repack re-encoded what the header described, wrote that back and
    lost the rest: Wolf Garopa's fight became a field of broken tiles while
    every check passed, because everything the checks knew about was the first
    archive. Splitting them gave the second halves their own labels and their
    own files, which is what these two invariants now hold in place.
    """

    def setUp(self) -> None:
        import sys as _sys

        _sys.path.insert(0, str(ROOT / "scripts"))
        from verify_repack import split_archives, payload_files

        self.split = split_archives
        self.payloads = payload_files(ROOT)
        if not self.payloads:
            self.skipTest("no payloads to inspect")

    def test_no_file_holds_a_second_archive(self) -> None:
        several = {}
        for relative in sorted(set(self.payloads.values())):
            chunks, _ = self.split((ROOT / relative).read_bytes())
            if len(chunks) > 1:
                several[Path(relative).name] = len(chunks)
        self.assertEqual({}, several)

    def test_nothing_points_inside_a_payload(self) -> None:
        """A byte offset onto a payload symbol would be size-sensitive again."""
        import re as _re

        payload_symbols = set()
        binclude = _re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"')
        for path in sorted((ROOT / "src").rglob("*.s")):
            for line in path.read_text(encoding="utf-8").splitlines():
                match = binclude.match(line)
                if match:
                    payload_symbols.add(match.group(1))
                    payload_symbols.add(match.group(1) + "_End")

        reference = _re.compile(r"dc\.l\s+([A-Za-z_][A-Za-z0-9_]*)\+\$([0-9A-Fa-f]+)")
        found = set()
        for path in sorted((ROOT / "src").rglob("*.s")):
            relative = path.relative_to(ROOT).as_posix()
            for line in path.read_text(encoding="utf-8").splitlines():
                match = reference.search(line.split(";")[0])
                if not match:
                    continue
                # almost every other symbol+value here is a sprite pointer with
                # attribute bits in the top byte, so a real offset is small
                if match.group(1) in payload_symbols and int(match.group(2), 16) < 0x10000:
                    found.add((relative, match.group(1), match.group(2)))
        self.assertEqual(set(), found)
