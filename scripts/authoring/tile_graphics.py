#!/usr/bin/env python3
"""Decode Mega Drive tile art into the pixels the Level Studio draws.

A tile is eight by eight pixels at four bits each: thirty-two bytes, two
pixels per byte, the high nibble on the left. The nibble is not a colour, it
is an index into whichever sixteen-colour line of CRAM the name-table entry
or the sprite attribute selects, so a tile cannot be drawn without saying
which palette line it is drawn through.

The payloads under `data/artunc/` are not all the same shape, and the
difference matters to anything that reads them:

    256 files   a length word, then that many bytes of tiles
      2 files   two such blocks, one after the other
     31 files   tiles with no length word at all

The length word is the DMA byte count. `Sprite_RenderDynamicMapping` reads a
piece pointer out of a mapping and records it as a transfer source, and the
count travels with the art rather than with the mapping, which is why most
pieces carry it and the handful uploaded by fixed-size code do not.
`read_blocks` parses the chain and returns None when the bytes are not one,
so a caller never has to guess: every one of the 289 payloads is either a
chain or a whole number of bare tiles.
"""

from __future__ import annotations

import json
import struct
import zlib
from dataclasses import dataclass
from pathlib import Path


TILE_SIZE = 8
TILE_BYTES = 32                  # 8 rows of 8 pixels at 4 bits
PALETTE_LINE = 16                # colours in one CRAM line
PALETTE_LINES = 4                # lines in CRAM
CRAM_COLOURS = PALETTE_LINE * PALETTE_LINES

# A CRAM word is 0000 BBB0 GGG0 RRR0: three bits per channel, eight levels.
# The levels are not evenly spaced on real hardware; the ramp used here is
# declared in config/authoring/graphics.json together with the reason.
CRAM_LEVELS = (0, 52, 87, 116, 144, 172, 206, 255)
CRAM_LEVELS_LINEAR = tuple(value * 255 // 7 for value in range(8))

ART_DIRECTORY = Path("data/artunc")
GRAPHICS_CONFIG = Path("config/authoring/graphics.json")


def cram_to_rgb(word, levels=CRAM_LEVELS):
    """One CRAM word as eight-bit red, green and blue."""
    return (levels[(word >> 1) & 7], levels[(word >> 5) & 7], levels[(word >> 9) & 7])


def rgb_to_cram(red, green, blue, levels=CRAM_LEVELS):
    """The CRAM word whose colour is nearest the one asked for."""
    def nearest(value):
        return min(range(8), key=lambda index: abs(levels[index] - value))
    return (nearest(blue) << 9) | (nearest(green) << 5) | (nearest(red) << 1)


def read_palette_words(data, offset=0, count=PALETTE_LINE):
    return list(struct.unpack_from(">%dH" % count, data, offset))


def palette_rgb(words, levels=CRAM_LEVELS):
    return [cram_to_rgb(word, levels) for word in words]


@dataclass(frozen=True)
class TileBlock:
    """A run of tiles, and whether the payload declared its length."""

    offset: int                  # first byte of tile data within the payload
    byte_count: int
    declared: bool               # a length word preceded the tiles

    @property
    def tile_count(self):
        return self.byte_count // TILE_BYTES


@dataclass
class TileSheet:
    """One art payload, read as the blocks it actually holds."""

    name: str
    data: bytes
    blocks: list

    @property
    def tile_count(self):
        return sum(block.tile_count for block in self.blocks)

    @property
    def chained(self):
        return bool(self.blocks) and self.blocks[0].declared

    def tile(self, index):
        """Tile `index`, counting across the blocks in order."""
        remaining = index
        for block in self.blocks:
            if remaining < block.tile_count:
                return decode_tile(self.data, block.offset + remaining * TILE_BYTES)
            remaining -= block.tile_count
        raise IndexError("tile %d is past the end of %s" % (index, self.name))


def read_blocks(data):
    """Parse the payload as a chain of length-prefixed tile blocks.

    Returns None when the bytes are not such a chain, which is the caller's
    signal to read them as bare tiles instead.
    """
    blocks = []
    at = 0
    while at < len(data):
        if at + 2 > len(data):
            return None
        count = struct.unpack_from(">H", data, at)[0]
        if count == 0 or count % TILE_BYTES or at + 2 + count > len(data):
            return None
        blocks.append(TileBlock(at + 2, count, True))
        at += 2 + count
    return blocks or None


def read_sheet(path, name=None):
    return sheet_from_bytes(name or path.name, path.read_bytes())


def sheet_from_bytes(name, data):
    blocks = read_blocks(data)
    if blocks is None:
        if len(data) % TILE_BYTES:
            raise ValueError("%s: %d bytes is neither a block chain nor whole tiles"
                             % (name, len(data)))
        blocks = [TileBlock(0, len(data), False)]
    return TileSheet(name, data, blocks)


def decode_tile(data, offset=0):
    """Thirty-two bytes as sixty-four palette indices, left to right."""
    if offset + TILE_BYTES > len(data):
        raise ValueError("tile at %d runs past %d bytes" % (offset, len(data)))
    pixels = []
    for byte in data[offset:offset + TILE_BYTES]:
        pixels.append(byte >> 4)
        pixels.append(byte & 0x0F)
    return pixels


def encode_tile(pixels):
    if len(pixels) != TILE_SIZE * TILE_SIZE:
        raise ValueError("a tile is %d pixels, not %d"
                         % (TILE_SIZE * TILE_SIZE, len(pixels)))
    return bytes((pixels[at] << 4) | pixels[at + 1] for at in range(0, len(pixels), 2))


def tile_rgb(pixels, palette, line=0):
    """Colour a tile's indices through one sixteen-colour line."""
    base = line * PALETTE_LINE
    return [palette[base + index] for index in pixels]


def greyscale_palette(count=CRAM_COLOURS):
    """A stand-in for looking at art before its real palette is known."""
    return [((index % PALETTE_LINE) * 17,) * 3 for index in range(count)]


def sheet_image(sheet, palette, columns=16, line=0):
    """Lay a sheet out as a grid of tiles and return its pixel rows."""
    count = sheet.tile_count
    columns = min(columns, count) if count else 1
    columns = max(1, columns)
    rows = (count + columns - 1) // columns
    width, height = columns * TILE_SIZE, rows * TILE_SIZE
    background = palette[line * PALETTE_LINE]
    image = [[background] * width for _ in range(height)]
    for index in range(count):
        pixels = tile_rgb(sheet.tile(index), palette, line)
        left = (index % columns) * TILE_SIZE
        top = (index // columns) * TILE_SIZE
        for y in range(TILE_SIZE):
            image[top + y][left:left + TILE_SIZE] = pixels[y * TILE_SIZE:(y + 1) * TILE_SIZE]
    return image


def write_png(path, image, compression=9):
    """A truecolour PNG, written with nothing but the standard library.

    The studio has to run wherever the build runs, and the build has no
    third-party Python. Pillow may be installed; it is not required.

    `compression` is zlib's level. Nine for a file worth keeping; one for a
    wide stage the studio is about to load and throw away.
    """
    height = len(image)
    width = len(image[0]) if height else 0
    raw = bytearray()
    for row in image:
        raw.append(0)                        # filter: none
        for red, green, blue in row:
            raw += bytes((red, green, blue))

    def chunk(kind, body):
        return (struct.pack(">I", len(body)) + kind + body
                + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

    header = struct.pack(">2I5B", width, height, 8, 2, 0, 0, 0)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(b"\x89PNG\r\n\x1a\n"
                     + chunk(b"IHDR", header)
                     + chunk(b"IDAT", zlib.compress(bytes(raw), compression))
                     + chunk(b"IEND", b""))


def survey(root):
    """Classify every art payload by the shape it turns out to have."""
    kinds = {}
    tiles = 0
    for path in sorted((root / ART_DIRECTORY).glob("*.bin")):
        sheet = read_sheet(path)
        tiles += sheet.tile_count
        kind = "chain-%d" % len(sheet.blocks) if sheet.chained else "bare"
        kinds.setdefault(kind, []).append(path.name)
    return {"payloads": sum(len(names) for names in kinds.values()),
            "tiles": tiles,
            "kinds": {kind: len(names) for kind, names in sorted(kinds.items())}}


def declared_art(root):
    """What config/authoring/graphics.json says the art should look like."""
    config = json.loads((root / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
    return config["uncompressed_art"]
