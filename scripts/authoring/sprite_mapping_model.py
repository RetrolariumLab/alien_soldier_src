#!/usr/bin/env python3
"""Read the cartridge's sprite mappings as the pieces they place.

An object is not one sprite. It is a mapping: a short list of pieces, each an
OAM entry positioned relative to the object, and the renderers in
`src/rendering/sprite_mapping_and_oam.s` are the whole specification.

`Sprite_RenderMapping` walks six-byte pieces:

    move.w  (a4)+,d3        ; +$00 attribute word
    move.w  (a4)+,d0        ; +$02 size byte, then a link byte
    ...
    move.b  (a4)+,d0        ; +$04 signed Y offset
    ...
    move.b  (a4)+,d0        ; +$05 signed X offset

`Sprite_RenderDynamicMapping` walks eight-byte pieces, where the two middle
words are one longword that is both the size byte and a pointer to the art:

    move.w  (a4)+,d3        ; +$00 attribute word
    move.l  (a4)+,d0        ; +$02 size byte in bits 24-31, art pointer below
    move.l  d0,(a2)+        ;      recorded as a DMA source
    swap    d0
    move.b  d4,d0           ;      the OAM link byte lands over the pointer
    ...

so the art a piece draws with travels inside the piece, and the pointer's own
top byte is never part of the address. That is why the source writes these as
`dc.l Piece+$0E000000`: the addend is the size.

Three things are true of both forms and worth stating, because none of them is
what the bits look like:

  * Bit 15 of the attribute word is the end of the mapping, not priority.
    `add.w d3,d3 / bcc` and `move.w d3,d1 / bmi` are the two spellings.
  * The attribute word is combined with the object's own, not used as it
    stands. `eor.w d7,d1` flips bits 11-15 against the object's, so bit 11 of
    a piece means "mirrored relative to the object", and `add.w d2,d1` adds
    the object's base tile, so the tile index is relative too.
  * The size byte is an OAM size field: bits 2-3 are one less than the width
    in tiles, bits 0-1 one less than the height. The renderers read it back
    out of the piece to mirror the X offset by the piece's own width.

A labelled block may hold more than one mapping, one after another, exactly as
the palette banks hold more than one command. Twelve do, and the two payloads
under `data/other/` hold eighty-nine and twenty.
"""

from __future__ import annotations

import re
import struct
from dataclasses import dataclass
from pathlib import Path


STATIC_ENTRY_BYTES = 6
DYNAMIC_ENTRY_BYTES = 8
LAST_PIECE = 0x8000
TILE_INDEX_MASK = 0x07FF

SOURCE_ROOT = Path("src")
# Two spellings for the same format: a block of pieces. The frames of the
# shared combat animations are named ...SpriteFrameNN and are mappings like
# any other, which only became visible when the animation scripts started
# naming them.
NAME_MARKERS = ("SpriteMapping", "SpriteFrame", "Mapping")
# Named for the metasprite system rather than for this format: part links,
# pose angles and descriptor tables, which are a different shape entirely.
# A name that says Mapping as well is still a mapping -- the four
# Boss_ValkirieMetaspriteMapping blocks are what its descriptor table points
# at -- so the exclusion only bites when Mapping is absent.
EXCLUDED_MARKER = "Metasprite"
EXCLUDED_BLOCKS = {
    "Terrain_StampObjectSpriteMapping":
        "four bytes, not a whole piece; Terrain_ObjectStampPattern reads it as "
        "a stamp pattern rather than as a mapping",
    "Stage24SceneObject_CompositeSpriteFrame":
        "seventy bytes, which is eleven pieces and four bytes over, and only "
        "its first piece sets the end-of-mapping bit; whatever the Stage 24 "
        "scene object reads it as, it is not a chain of pieces",
}

LABEL_LINE = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*):(?P<rest>.*)$")
DIRECTIVE = re.compile(r"^\s*(?P<kind>dc\.[bwl]|binclude)\s+(?P<body>[^;]+?)\s*(?:;.*)?$")
ART_OPERAND = re.compile(
    r"^(?P<symbol>[A-Za-z_][A-Za-z0-9_]*)(?:\+\$(?P<addend>[0-9A-Fa-f]+))?$")


def parse_number(token):
    token = token.strip()
    if token.startswith("$"):
        return int(token[1:], 16)
    if token.startswith("-$"):
        return -int(token[2:], 16)
    return int(token)


def signed_byte(value):
    return value - 0x100 if value >= 0x80 else value


@dataclass(frozen=True)
class SpritePiece:
    """One OAM entry, placed relative to its object."""

    attributes: int
    size: int
    link: int                    # a placeholder; the renderer writes the index
    y: int                       # signed, pixels from the object
    x: int                       # signed, pixels from the object
    art: str = ""                # the art symbol, for a dynamic piece
    art_addend: int = 0          # what is left of the addend below the size

    @property
    def last(self):
        return bool(self.attributes & LAST_PIECE)

    @property
    def tile(self):
        """Added to the object's base tile, so it is an offset, not an index."""
        return self.attributes & TILE_INDEX_MASK

    @property
    def hflip_relative(self):
        """Bit 11, exclusive-ored with the object's, so it is a relative flip."""
        return bool(self.attributes & 0x0800)

    @property
    def vflip_relative(self):
        return bool(self.attributes & 0x1000)

    @property
    def palette_relative(self):
        """Bits 13-14. Only the entry-attribute renderer keeps them."""
        return (self.attributes >> 13) & 3

    @property
    def tiles_wide(self):
        return ((self.size >> 2) & 3) + 1

    @property
    def tiles_high(self):
        return (self.size & 3) + 1

    @property
    def width(self):
        return self.tiles_wide * 8

    @property
    def height(self):
        return self.tiles_high * 8

    @property
    def tile_count(self):
        return self.tiles_wide * self.tiles_high

    @property
    def dynamic(self):
        return bool(self.art)

    def encode(self):
        if self.dynamic:
            raise ValueError("a dynamic piece holds a symbol, not bytes")
        return struct.pack(">HBBbb", self.attributes, self.size, self.link,
                           self.y, self.x)


@dataclass
class SpriteMapping:
    """One run of pieces, ending at the piece with bit 15 set."""

    block: str
    offset: int                  # byte offset within its block, or piece index
    pieces: tuple

    @property
    def label(self):
        return self.block if self.offset == 0 else "%s+$%X" % (self.block, self.offset)

    @property
    def dynamic(self):
        return bool(self.pieces) and self.pieces[0].dynamic

    def bounds(self):
        """The rectangle the pieces cover, relative to the object."""
        if not self.pieces:
            return (0, 0, 0, 0)
        left = min(piece.x for piece in self.pieces)
        top = min(piece.y for piece in self.pieces)
        right = max(piece.x + piece.width for piece in self.pieces)
        bottom = max(piece.y + piece.height for piece in self.pieces)
        return (left, top, right - left, bottom - top)


@dataclass
class MappingBlock:
    """A labelled run of mapping data, and the mappings it turned out to hold."""

    name: str
    source: str
    storage: str                 # "words", "bytes", "payload" or "dynamic"
    payload: str
    data: bytes
    mappings: tuple


def read_static(data, block):
    """Walk bytes as six-byte pieces grouped into mappings."""
    if len(data) % STATIC_ENTRY_BYTES:
        raise ValueError("%s: %d bytes is not a whole number of pieces"
                         % (block, len(data)))
    mappings = []
    pieces = []
    start = 0
    for at in range(0, len(data), STATIC_ENTRY_BYTES):
        attributes, size, link, y, x = struct.unpack_from(">HBBbb", data, at)
        if not pieces:
            start = at
        pieces.append(SpritePiece(attributes, size, link, y, x))
        if attributes & LAST_PIECE:
            mappings.append(SpriteMapping(block, start, tuple(pieces)))
            pieces = []
    if pieces:
        raise ValueError("%s: the last piece does not end the mapping" % block)
    return mappings


def read_dynamic(tokens, block):
    """Walk (word, longword, word) triples as eight-byte pieces."""
    if len(tokens) % 3:
        raise ValueError("%s: %d operands is not a whole number of pieces"
                         % (block, len(tokens)))
    mappings = []
    pieces = []
    start = 0
    for index in range(0, len(tokens), 3):
        kinds = tuple(kind for kind, _ in tokens[index:index + 3])
        if kinds != ("dc.w", "dc.l", "dc.w"):
            raise ValueError("%s: piece %d is %s, not word/long/word"
                             % (block, index // 3, "/".join(kinds)))
        attributes = parse_number(tokens[index][1])
        operand = ART_OPERAND.match(tokens[index + 1][1].strip())
        if operand is None:
            raise ValueError("%s: piece %d does not point at an art symbol"
                             % (block, index // 3))
        addend = int(operand.group("addend") or "0", 16)
        position = parse_number(tokens[index + 2][1])
        if not pieces:
            start = (index // 3) * DYNAMIC_ENTRY_BYTES
        pieces.append(SpritePiece(
            attributes, (addend >> 24) & 0xFF, 0,
            signed_byte((position >> 8) & 0xFF), signed_byte(position & 0xFF),
            operand.group("symbol"), addend & 0x00FFFFFF))
        if attributes & LAST_PIECE:
            mappings.append(SpriteMapping(block, start, tuple(pieces)))
            pieces = []
    if pieces:
        raise ValueError("%s: the last piece does not end the mapping" % block)
    return mappings


def labelled_blocks(root, *, original=None):
    """Every labelled run of directives in the assembly, in file order."""
    blocks = []
    sources = (((path, path.read_text(encoding="utf-8"))
                for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s")))
               if original is None else original.texts())
    for path, text in sources:
        relative = path.relative_to(root).as_posix()
        name = None
        tokens = []
        for line in text.split("\n"):
            head = LABEL_LINE.match(line)
            if head:
                if name and tokens:
                    blocks.append((name, relative, tuple(tokens)))
                name, tokens = head.group("name"), []
                line = head.group("rest")
            directive = DIRECTIVE.match(line)
            if directive is None or name is None:
                continue
            for token in directive.group("body").split(","):
                tokens.append((directive.group("kind"), token.strip()))
        if name and tokens:
            blocks.append((name, relative, tuple(tokens)))
    return blocks


def read_blocks(root):
    """Every sprite mapping block, and every block deliberately left out."""
    from authoring.stage_tilemap_model import _read_operation
    active = _read_operation(root)
    if active is not None:
        return active.mapping_blocks()
    return _parse_read_blocks(root)


def _parse_read_blocks(root, *, original=None):
    """Unchanged source parser, optionally fed only captured ORIGINAL inputs."""
    from authoring.stage_tilemap_model import _OriginalSourceChanged, _UncachedInclude
    found = []
    skipped = {}
    blocks = labelled_blocks(root) if original is None else labelled_blocks(root, original=original)
    for name, source, tokens in blocks:
        if not any(marker in name for marker in NAME_MARKERS):
            continue
        if EXCLUDED_MARKER in name and "Mapping" not in name:
            continue
        if name in EXCLUDED_BLOCKS:
            skipped[name] = EXCLUDED_BLOCKS[name]
            continue
        kinds = {kind for kind, _ in tokens}
        try:
            if original is None:
                read_one_block(root, found, name, source, tokens, kinds, skipped)
            else:
                read_one_block(root, found, name, source, tokens, kinds, skipped, original=original)
        except (_OriginalSourceChanged, _UncachedInclude):
            raise  # Raw drift/external input is not a malformed mapping reason.
        except ValueError as error:
            # Widening the name filter to SpriteFrame brought in blocks that
            # share the word but not the format. Record what each one is
            # instead of stopping, so nothing is silently dropped either.
            skipped[name] = str(error)
    return found, skipped


def read_one_block(root, found, name, source, tokens, kinds, skipped, *, original=None):
        if kinds == {"dc.l"}:
            skipped[name] = "a table of pointers to mappings, not mapping data"
            return
        if kinds == {"binclude"}:
            payload = tokens[0][1].strip('"')
            data = ((root / payload).read_bytes() if original is None
                    else original._bytes(root / payload))
            found.append(MappingBlock(name, source, "payload", payload, data,
                                      tuple(read_static(data, name))))
        elif kinds == {"dc.w"}:
            data = b"".join(struct.pack(">H", parse_number(token))
                            for _, token in tokens)
            found.append(MappingBlock(name, source, "words", "", data,
                                      tuple(read_static(data, name))))
        elif kinds == {"dc.b"}:
            data = bytes(parse_number(token) & 0xFF for _, token in tokens)
            found.append(MappingBlock(name, source, "bytes", "", data,
                                      tuple(read_static(data, name))))
        elif kinds == {"dc.w", "dc.l"}:
            found.append(MappingBlock(name, source, "dynamic", "", b"",
                                      tuple(read_dynamic(list(tokens), name))))
        else:
            skipped[name] = "directives %s are not a mapping" % "/".join(sorted(kinds))


def round_trip_errors(root):
    """Every static mapping must re-encode to the bytes it was read from."""
    errors = []
    blocks, _ = read_blocks(root)
    for block in blocks:
        if block.storage == "dynamic":
            for mapping in block.mappings:
                for piece in mapping.pieces:
                    if piece.art_addend:
                        errors.append("%s: %s carries $%06X below its size byte"
                                      % (mapping.label, piece.art, piece.art_addend))
            continue
        rebuilt = b"".join(piece.encode() for mapping in block.mappings
                           for piece in mapping.pieces)
        if rebuilt != block.data:
            errors.append("%s: re-encoded pieces differ from the tree" % block.name)
    return errors


def survey(root):
    blocks, skipped = read_blocks(root)
    mappings = [mapping for block in blocks for mapping in block.mappings]
    pieces = [piece for mapping in mappings for piece in mapping.pieces]
    return {
        "blocks": len(blocks),
        "mappings": len(mappings),
        "pieces": len(pieces),
        "static_mappings": sum(1 for item in mappings if not item.dynamic),
        "dynamic_mappings": sum(1 for item in mappings if item.dynamic),
        "payload_blocks": sum(1 for block in blocks if block.storage == "payload"),
        "blocks_holding_several": sum(1 for block in blocks if len(block.mappings) > 1),
        "skipped": skipped,
    }


BINCLUDE_LABEL = re.compile(
    r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"([^"]+)"')


def art_payloads(root):
    """Every symbol that names a binincluded payload, and the file it names."""
    payloads = {}
    for path in sorted(root.joinpath(SOURCE_ROOT).rglob("*.s")):
        for line in path.read_text(encoding="utf-8").split("\n"):
            match = BINCLUDE_LABEL.match(line)
            if match:
                payloads[match.group(1)] = match.group(2)
    return payloads


def mapping_tiles(root, mapping, payloads=None):
    """The tiles a dynamic mapping uploads, in the order it uploads them.

    Each piece names its own art, and the pieces are transferred one after
    another, so a piece's tile field should be the running total of everything
    uploaded before it. It is, everywhere, which is what makes this worth
    checking rather than assuming: the tile field comes from the mapping and
    the payload sizes come from the DMA length words, and the two agree.
    """
    from authoring.tile_graphics import decode_tile, read_sheet

    if not mapping.dynamic:
        raise ValueError("%s is a static mapping: its tiles are whatever the "
                         "object already had in VRAM" % mapping.label)
    payloads = payloads if payloads is not None else art_payloads(root)
    tiles = []
    for piece in mapping.pieces:
        if piece.art not in payloads:
            raise ValueError("%s: %s is not a binincluded payload"
                             % (mapping.label, piece.art))
        if piece.tile != len(tiles):
            raise ValueError("%s: %s starts at tile $%X but $%X are uploaded"
                             % (mapping.label, piece.art, piece.tile, len(tiles)))
        sheet = read_sheet(root / payloads[piece.art])
        # A piece takes the payload's first block. Two payloads hold a second
        # block that no symbol names: the extraction cut on referenced
        # addresses, so a piece that nothing points at was swallowed by the one
        # before it. The piece's own size is the authority on how much it draws.
        block = sheet.blocks[0]
        available = block.tile_count
        if available != piece.tile_count:
            raise ValueError("%s: %s gives %d tiles but the piece says %dx%d"
                             % (mapping.label, piece.art, available,
                                piece.tiles_wide, piece.tiles_high))
        tiles.extend(decode_tile(sheet.data, block.offset + index * 32)
                     for index in range(available))
    return tiles


def compose_image(mapping, tiles, palette, line=0, background=None):
    """Draw a dynamic mapping's pieces into one image, index 0 transparent.

    Sprite tiles run down each column before moving right, which is why the
    tile picked for a piece's cell is `tile + column * height + row`.
    """
    from authoring.tile_graphics import TILE_SIZE

    left, top, width, height = mapping.bounds()
    ground = background if background is not None else palette[line * 16]
    image = [[ground] * width for _ in range(height)]
    for piece in mapping.pieces:
        for column in range(piece.tiles_wide):
            for row in range(piece.tiles_high):
                pixels = tiles[piece.tile + column * piece.tiles_high + row]
                for y in range(TILE_SIZE):
                    for x in range(TILE_SIZE):
                        index = pixels[y * TILE_SIZE + x]
                        if not index:
                            continue          # colour 0 is transparent
                        at_y = piece.y - top + row * TILE_SIZE + y
                        at_x = piece.x - left + column * TILE_SIZE + x
                        if 0 <= at_y < height and 0 <= at_x < width:
                            image[at_y][at_x] = palette[line * 16 + index]
    return image
