#!/usr/bin/env python3
"""Read the cartridge's palettes as the commands that load them.

A palette is never stored as sixty-four colours. It is stored as commands,
each writing a run of CRAM words into one place in the palette buffer, and a
screen's colours are whatever is left after a list of them has been played in
order. `Gfx_LoadPaletteCommand` is the whole format:

    moveq   #0,d0
    move.b  (a0)+,d0            ; destination
    addi.w  #-$1D00,d0
    move.w  d0,d1
    addi.w  #$80,d1
    movea.w d0,a1               ; PaletteActiveBuffer + destination
    movea.w d1,a2               ; PaletteShadowBuffer + destination
    ...
    move.b  (a0)+,d7            ; one less than the word count
    ...
    move.w  (a0),(a1)+
    move.w  (a0)+,(a2)+
    dbf     d7,...

So a command is two header bytes and then that many CRAM words, and it is
`2 + 2 * count` bytes long. The destination byte is a byte offset into the
buffer, because `dest - $1D00` sign-extends to exactly `PaletteActiveBuffer`,
which `src/ram_addrs.inc` puts at $FFFFE300 with the shadow buffer $80 above
it. A destination of $62 is therefore colour $31 -- line three, colour one --
and the commands that start at an odd colour are the ones that leave a line's
transparent colour alone.

A full palette is `dc.b 0, $3F` and sixty-four words: $82 bytes. That is the
figure the offset lists step by, and it is why three of the labels in
`src/rendering/palettes.s` are banks rather than single commands.

`Gfx_LoadMultiplePalettes` clears eight words of the buffer, plays
`CommonPaletteCommand`, and then walks a list of signed offsets relative to
`Gfx_LoadPalettePreservingSharedColor` until it reads a zero. Those offsets
are written in the source as `(Bank+$disp)-Gfx_LoadPalettePreservingSharedColor`,
so a list can be resolved without knowing a single address: the symbol names
the block and the displacement indexes into it.
"""

from __future__ import annotations

import re
import struct
from dataclasses import dataclass
from pathlib import Path

from authoring.tile_graphics import CRAM_LEVELS, cram_to_rgb


PALETTE_SOURCE = Path("src/rendering/palettes.s")
LOADER_SYMBOL = "Gfx_LoadPalettePreservingSharedColor"
PRELUDE_COMMAND = "CommonPaletteCommand"
PALETTE_COLOURS = 64
PALETTE_BYTES = PALETTE_COLOURS * 2
ACTIVE_BUFFER = 0xFFFFE300
SHADOW_BUFFER = 0xFFFFE380
DESTINATION_BIAS = 0x1D00  # dest - $1D00 sign-extends to the buffer

LABEL_LINE = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*):(?P<rest>.*)$")
DIRECTIVE = re.compile(r"^\s*(?P<kind>dc\.[bwl]|binclude)\s+(?P<body>[^;]+?)\s*(?:;.*)?$")
# (Symbol+$disp)-Loader, Symbol-Loader, or a bare terminator.
OFFSET_TERM = re.compile(
    r"^\(?(?P<symbol>[A-Za-z_][A-Za-z0-9_]*)"
    r"(?:\+\$(?P<displacement>[0-9A-Fa-f]+))?\)?-" + LOADER_SYMBOL + r"$"
)


def parse_number(token):
    token = token.strip()
    if token.startswith("$"):
        return int(token[1:], 16)
    if token.startswith("-$"):
        return -int(token[2:], 16)
    return int(token)


@dataclass(frozen=True)
class PaletteCommand:
    """One run of colours, and where in the buffer it lands."""

    block: str
    offset: int  # byte offset within its block
    destination: int  # byte offset into the palette buffer
    colours: tuple  # CRAM words, in order

    @property
    def count(self):
        return len(self.colours)

    @property
    def size(self):
        return 2 + 2 * self.count

    @property
    def first_colour(self):
        return self.destination // 2

    @property
    def line(self):
        return self.destination // 32

    @property
    def full_palette(self):
        return self.destination == 0 and self.count == PALETTE_COLOURS

    @property
    def active_address(self):
        return ACTIVE_BUFFER + self.destination

    @property
    def label(self):
        return self.block if self.offset == 0 else "%s+$%X" % (self.block, self.offset)

    def encode(self):
        return bytes((self.destination, self.count - 1)) + struct.pack(">%dH" % self.count, *self.colours)


def read_commands(data, block):
    """Walk a block as a chain of commands, or raise if it is not one."""
    commands = []
    at = 0
    while at < len(data):
        if at + 2 > len(data):
            raise ValueError("%s: a command header is cut off at $%X" % (block, at))
        destination, encoded = data[at], data[at + 1]
        count = encoded + 1
        size = 2 + 2 * count
        if destination % 2 or destination + 2 * count > PALETTE_BYTES:
            raise ValueError(
                "%s+$%X: destination $%X and %d colours leave the buffer" % (block, at, destination, count)
            )
        if at + size > len(data):
            raise ValueError("%s+$%X: %d colours run past the block" % (block, at, count))
        colours = struct.unpack_from(">%dH" % count, data, at + 2)
        commands.append(PaletteCommand(block, at, destination, colours))
        at += size
    return commands


@dataclass
class Block:
    """A labelled run of bytes in the palette source."""

    name: str
    storage: str  # "source" or "payload"
    payload: str
    data: bytes


@dataclass
class OffsetList:
    """A named list of commands, played in order onto the buffer."""

    name: str
    index: int  # which run, for a label holding several lists
    entries: tuple  # (symbol, displacement) pairs

    @property
    def label(self):
        return self.name if self.index == 0 else "%s[%d]" % (self.name, self.index)


def read_source(root):
    """Every labelled byte block and every palette offset list in the source."""
    lines = (root / PALETTE_SOURCE).read_text(encoding="utf-8").split("\n")
    blocks = {}
    lists = []
    name = None
    kind = None
    tokens = []

    def flush():
        if name is None or not tokens:
            return
        if kind == "binclude":
            payload = tokens[0].strip().strip('"')
            blocks[name] = Block(name, "payload", payload, (root / payload).read_bytes())
        elif kind == "dc.b":
            blocks[name] = Block(name, "source", "", bytes(parse_number(token) for token in tokens))
        elif kind == "dc.w" and all(OFFSET_TERM.match(token.strip()) or parse_number(token) == 0 for token in tokens):
            runs = [[]]
            for token in tokens:
                match = OFFSET_TERM.match(token.strip())
                if match is None:
                    runs.append([])
                    continue
                runs[-1].append((match.group("symbol"), int(match.group("displacement") or "0", 16)))
            for index, run in enumerate(run for run in runs if run):
                lists.append(OffsetList(name, index, tuple(run)))

    for line in lines:
        head = LABEL_LINE.match(line)
        if head:
            flush()
            name, kind, tokens = head.group("name"), None, []
            line = head.group("rest")
        directive = DIRECTIVE.match(line)
        if directive is None or name is None:
            continue
        if kind is None:
            kind = directive.group("kind")
        elif kind != directive.group("kind"):
            continue
        tokens.extend(directive.group("body").split(","))
    flush()
    return blocks, lists


def command_index(blocks):
    """Every command in every block that is a chain of them."""
    commands = {}
    other = {}
    for name, block in sorted(blocks.items()):
        try:
            found = read_commands(block.data, name)
        except ValueError as error:
            other[name] = str(error)
            continue
        for command in found:
            commands[(name, command.offset)] = command
    return commands, other


def apply_commands(commands, prelude=None):
    """Play commands onto a palette buffer and return its sixty-four words."""
    buffer = [0] * PALETTE_COLOURS
    for command in list(prelude or []) + list(commands):
        for step, word in enumerate(command.colours):
            buffer[command.first_colour + step] = word
    return buffer


def resolve(offset_list, commands):
    """The commands a list plays, in order. Raises if one misses a boundary."""
    found = []
    for symbol, displacement in offset_list.entries:
        key = (symbol, displacement)
        if key not in commands:
            raise ValueError("%s: %s+$%X is not the start of a command" % (offset_list.label, symbol, displacement))
        found.append(commands[key])
    return found


def named_sets(root, levels=CRAM_LEVELS):
    """Each offset list as the sixty-four colours it leaves in the buffer."""
    blocks, lists = read_source(root)
    commands, _ = command_index(blocks)
    prelude = [commands[(PRELUDE_COMMAND, 0)]] if (PRELUDE_COMMAND, 0) in commands else []
    sets = []
    for offset_list in lists:
        played = resolve(offset_list, commands)
        words = apply_commands(played, prelude)
        sets.append(
            {
                "name": offset_list.label,
                "commands": [command.label for command in played],
                "words": words,
                "rgb": [cram_to_rgb(word, levels) for word in words],
            }
        )
    return sets


def round_trip_errors(root):
    """Every command must re-encode to the bytes it was read from."""
    errors = []
    blocks, lists = read_source(root)
    commands, other = command_index(blocks)
    for name, block in sorted(blocks.items()):
        if name in other:
            continue
        rebuilt = b"".join(command.encode() for key, command in sorted(commands.items()) if key[0] == name)
        if rebuilt != block.data:
            errors.append("%s: re-encoded commands differ from the tree" % name)
    for offset_list in lists:
        try:
            resolve(offset_list, commands)
        except ValueError as error:
            errors.append(str(error))
    return errors


def survey(root):
    blocks, lists = read_source(root)
    commands, other = command_index(blocks)
    return {
        "blocks": len(blocks),
        "command_blocks": len(blocks) - len(other),
        "commands": len(commands),
        "full_palettes": sum(1 for command in commands.values() if command.full_palette),
        "offset_lists": len(lists),
        "referenced_commands": len({entry for item in lists for entry in item.entries}),
        "not_command_chains": other,
    }
