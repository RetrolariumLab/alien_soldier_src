#!/usr/bin/env python3
"""The cartridge's second codec: `TileCodec_DecodeTile`.

Seven payloads use it, all interface art, and every one of them is invisible to
the rest of the tooling because nothing here could read the format. This reads
it. `lzss_codec.py` is the model for the shape of the file.

Where LZSS works on bytes, this works on bits and on one 8x8 tile at a time,
and it is built around the thing tile art actually has: edges that continue
onto the next row.

The framing, from `Data_ProcessPointer_ReadCompressedHeader`: byte zero is the
tile count less one, and the bit stream is every byte after it, most
significant bit first. The cartridge keeps a sixteen-bit rotating reservoir and
a count of the bits left in it, which comes to the same thing.

A tile is decoded into sixty-four slots, one per pixel, and each token is:

  * five bits -- the top four are a colour, the low bit says whether a marker
    sequence follows;
  * then, if it does, pairs of bits placing that same colour further along:
    one, two or three mean six, seven or eight pixels past the last placement,
    and zero introduces a third bit that either ends the sequence or selects
    six or ten. Six to ten pixels ahead of a pixel in an eight-wide tile is the
    row below it, from one column left to one column right, so a marker sequence
    is an edge being traced downward;
  * then a run length, always: ones counted up to a zero give `k`, then `k`
    more bits give a payload, and the run is `2**k + payload - 2` pixels of the
    current colour. When the run reaches a slot a marker has already seeded, it
    takes that slot's colour and carries on with it, which is how an edge laid
    down earlier turns the fill.

`TileCodec_PackDecodedTile` then folds the sixty-four slots into the ordinary
Mega Drive 4bpp tile, two pixels to a byte, high nibble first.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


TILE_PIXELS = 64  # an 8x8 tile, one slot per pixel
TILE_BYTES = 32  # the same tile packed, two pixels to a byte
SEEDED = 0x8000  # the bit a marker leaves on a slot
NEAR_OFFSETS = (0, 7, 8, 9)  # what a two-bit marker means, zero excepted
FAR_SHORT = 6
FAR_LONG = 10


class Bits:
    """The bit stream, most significant bit first, starting at `at`."""

    def __init__(self, data: bytes, at: int) -> None:
        self.data = data
        self.at = at
        self.bit = 0

    def read(self, count: int) -> int:
        value = 0
        for _ in range(count):
            if self.at >= len(self.data):
                raise ValueError("the bit stream ran out")
            value = (value << 1) | ((self.data[self.at] >> (7 - self.bit)) & 1)
            self.bit += 1
            if self.bit == 8:
                self.bit = 0
                self.at += 1
        return value

    def spent(self) -> int:
        """Bytes consumed, rounded up, for checking against the file length."""
        return self.at + (1 if self.bit else 0)


def decode_tile(bits: Bits) -> list:
    """Sixty-four palette indices, the way TileCodec_DecodeTile builds them."""
    slot = [0] * TILE_PIXELS
    seeded = [False] * TILE_PIXELS
    at = 0
    overrun = 0
    while at < TILE_PIXELS:
        token = bits.read(5)
        colour = token >> 1
        slot[at] = colour
        seeded[at] = False
        at += 1
        if token & 1:
            ahead = 0
            while True:
                near = bits.read(2)
                if near:
                    ahead += NEAR_OFFSETS[near]
                elif not bits.read(1):
                    break
                else:
                    ahead += FAR_LONG if bits.read(1) else FAR_SHORT
                target = at - 1 + ahead
                if target < TILE_PIXELS:
                    slot[target] = colour
                    seeded[target] = True
                else:
                    overrun += 1
        length = 0
        while bits.read(1):
            length += 1
        length += 1
        run = (1 << length) + bits.read(length) - 2
        for _ in range(run):
            if at >= TILE_PIXELS:
                overrun += 1
                continue
            if seeded[at]:
                colour = slot[at]
                seeded[at] = False
            slot[at] = colour
            at += 1
    return slot


def pack_tile(slot: list) -> bytes:
    """Two pixels to a byte, high nibble first, eight rows of four."""
    out = bytearray()
    for at in range(0, TILE_PIXELS, 2):
        out.append(((slot[at] & 0xF) << 4) | (slot[at + 1] & 0xF))
    return bytes(out)


def decompress(payload: bytes) -> bytes:
    """Every tile the payload holds, packed."""
    if len(payload) < 2:
        raise ValueError("there is no header here")
    count = payload[0] + 1
    bits = Bits(payload, 1)
    out = bytearray()
    for index in range(count):
        try:
            out += pack_tile(decode_tile(bits))
        except ValueError as error:
            raise ValueError("tile %d of %d: %s" % (index + 1, count, error))
    return bytes(out)


class BitWriter:
    """The other end of `Bits`: most significant bit first."""

    def __init__(self) -> None:
        self.out = bytearray()
        self.pending = 0
        self.bit = 0

    def write(self, value: int, count: int) -> None:
        for shift in range(count - 1, -1, -1):
            self.pending = (self.pending << 1) | ((value >> shift) & 1)
            self.bit += 1
            if self.bit == 8:
                self.out.append(self.pending)
                self.pending = 0
                self.bit = 0

    def finish(self) -> bytes:
        if self.bit:
            self.out.append(self.pending << (8 - self.bit))
            self.pending = self.bit = 0
        return bytes(self.out)


def unpack_tile(tile: bytes) -> list:
    """Thirty-two bytes back into sixty-four palette indices."""
    slot = []
    for byte in tile:
        slot.append(byte >> 4)
        slot.append(byte & 0xF)
    return slot


def encode_tile(out: BitWriter, slot: list) -> None:
    """One tile, as runs of one colour and nothing else.

    Markers are not emitted. They are what makes the original small, since an
    edge traced downward costs a few bits where a run would cost a token a row,
    but they are an optimisation: a stream without them decodes to the same
    pixels, and this is the same bargain the LZSS encoder strikes.
    """
    at = 0
    while at < TILE_PIXELS:
        colour = slot[at]
        end = at + 1
        while end < TILE_PIXELS and slot[end] == colour:
            end += 1
        out.write((colour & 0xF) << 1, 5)  # low bit clear: no markers
        run = end - at - 1
        length = (run + 2).bit_length() - 1  # the largest k that fits
        for _ in range(length - 1):
            out.write(1, 1)
        out.write(0, 1)
        out.write(run + 2 - (1 << length), length)
        at = end


def compress(data: bytes) -> bytes:
    """Whole tiles in, one payload out, ready for command two or three."""
    if not data or len(data) % TILE_BYTES:
        raise ValueError("%d bytes is not a whole number of tiles" % len(data))
    count = len(data) // TILE_BYTES
    if count > 256:
        raise ValueError("the count byte holds 256 tiles at most, not %d" % count)
    out = BitWriter()
    for index in range(count):
        encode_tile(out, unpack_tile(data[index * TILE_BYTES : (index + 1) * TILE_BYTES]))
    payload = bytes([count - 1]) + out.finish()
    # The decoder fetches words, and every original payload is an even length
    return payload if len(payload) % 2 == 0 else payload + bytes(1)


def report(payload: bytes) -> dict:
    """Decode and say how it went, for checking a whole set at once."""
    count = payload[0] + 1
    bits = Bits(payload, 1)
    out = bytearray()
    for _ in range(count):
        out += pack_tile(decode_tile(bits))
    return {
        "tiles": count,
        "bytes": len(out),
        "read": bits.spent(),
        "size": len(payload),
        "slack": len(payload) - bits.spent(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", default="tile_codec", help="where to write the decoded tiles")
    args = parser.parse_args()
    root = Path.cwd()
    sys.path.insert(0, str(root / "scripts" / "authoring"))
    import re

    wanted = {}
    binclude = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"([^"]+)"')
    from lzss_codec import read_asset_records, LABEL_BYTES

    names = {}
    for path in sorted((root / "src").rglob("*.s")):
        for line in path.read_text(encoding="utf-8").splitlines():
            match = binclude.match(line)
            if match:
                names[match.group(1)] = match.group(2)
    for path in sorted((root / "src").rglob("*.s")):
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

    out_dir = root / args.out_dir
    out_dir.mkdir(exist_ok=True)
    print("%-38s %5s %6s %7s %6s" % ("payload", "tiles", "bytes", "read", "slack"))
    bad = 0
    for name, relative in sorted(wanted.items()):
        raw = (root / relative).read_bytes()
        try:
            facts = report(raw)
        except (ValueError, IndexError) as error:
            print("%-38s FAILED: %s" % (name, error))
            bad += 1
            continue
        (out_dir / ("%s.bin" % name)).write_bytes(decompress(raw))
        print("%-38s %5d %6d %7d %6d" % (name, facts["tiles"], facts["bytes"], facts["read"], facts["slack"]))
    print()
    print("%d payload(s) written to %s/, %d failed" % (len(wanted) - bad, args.out_dir, bad))
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
