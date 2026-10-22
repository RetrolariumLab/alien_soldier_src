#!/usr/bin/env python3
"""Compress data the way the cartridge's decompressor expects to read it.

`Data_LZSSDecomp` in `src/gameplay/object_data.s` reads five kinds of token,
and `scripts/unpack_data.py` is the decoder. Taking all 232 compressed payloads
back apart with the same rules recovers the encoder's own choices, and this is
the encoder written to produce a stream that decoder accepts:

| Control | Token | Input | Output |
|---|---|---|---|
| `$00-$1F` | literal run of `(c & $1F) + 1` | `1 + n` | `n` |
| `$20-$3F` | one byte `(c & $1F) + 2` times | 2 | `n` |
| `$40-$5F` | one pair `(c & $1F) + 2` times | 3 | `2n` |
| `$60-$7F` | a fixed byte alternating with `(c & $1F) + 2` literals | `2 + n` | `2n` |
| `$80-$FF` | a match, length `((c >> 2) & $1F) + 2`, distance from the low ten bits plus one | 2 | `length` |

The output is cut into `$400` blocks and each is encoded on its own, because
`Data_LZSSDecomp` decodes until its output pointer reaches `start + $400` and
`LoadCompressedToVRAM` resets that pointer to the staging buffer every call:

    LoadCompressedToVRAM_BlockLoop:
        lea     (GraphicsStagingBuffer).w,a2
        bsr.w   Data_LZSSDecomp

so a match that reaches back across a block boundary reads whatever sits
before the buffer rather than the bytes it meant. Taking the cartridge's own
archives apart confirms the rule and shows it is not only the VRAM ones: all
233 payloads, both loaders, have a token boundary at every multiple of `$400`
and not one match that crosses one. Ignoring this is what made a repacked
image draw a corrupted title screen while its maps stayed intact.

The parse is optimal within each block: a shortest-path over output positions
with those exact costs. That is *not* what the original encoder did. Taking its own output apart
shows it chose the longest available match only nine times in ten, and among
equal-length matches it picked neither the nearest nor the farthest, which is
the signature of a bounded hash-chain search. An optimal parse is 12 to 26 per
cent smaller than the original on every payload measured, so this compressor
cannot reproduce the cartridge byte for byte and does not pretend to. What it
does promise is the only thing an editor needs: the game's own decompressor
reads the result back as exactly the bytes that went in.
"""

from __future__ import annotations

import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from unpack_data import unpack_data  # noqa: E402


BLOCK = 0x400  # what one call to Data_LZSSDecomp produces
MAX_DISTANCE = 1024  # ten bits of distance, plus one
MAX_MATCH = 33  # five bits of length, plus two
MIN_MATCH = 2
MAX_LITERAL = 32  # five bits of count, plus one
MAX_REPEAT = 33  # five bits of count, plus two
LITERAL_CONTROL = 0x00
RUN_CONTROL = 0x20
PAIR_CONTROL = 0x40
ALTERNATE_CONTROL = 0x60
MATCH_CONTROL = 0x80
HASH_BITS = 12  # candidate buckets for the match search


def decompress(payload):
    """The cartridge's own decoder, so a round trip is checked against it."""
    out, error = unpack_data(payload)
    if out is None:
        raise ValueError(error)
    return bytes(out)


def decompress_as_vram(payload):
    """Decode the way LoadCompressedToVRAM does, resetting every $400.

    `unpack_data` models the RAM loader, whose output pointer runs on, so it
    happily accepts a stream whose matches reach across a block boundary. The
    VRAM loader does not: it hands Data_LZSSDecomp the staging buffer again
    each time. Checking against this is what catches the difference.
    """
    import struct as _struct

    # The header counts the bytes to consume, so the stop index is past them
    end = 2 + _struct.unpack_from(">H", payload, 0)[0]
    if end > len(payload):
        raise ValueError("the header claims %d bytes and the payload holds %d" % (end - 2, len(payload) - 2))
    at = 2
    out = bytearray()
    while at < end:
        base = len(out)
        while len(out) - base < BLOCK and at < end:
            control = payload[at]
            if control >= 0x80:
                length = ((control >> 2) & 0x1F) + 2
                distance = (((control << 8) | payload[at + 1]) & 0x3FF) + 1
                source = len(out) - distance
                if source < base:
                    raise ValueError("a match at %d reaches %d bytes before its block" % (len(out), base - source))
                for _ in range(length):
                    out.append(out[source])
                    source += 1
                at += 2
            elif control & 0x20:
                if control & 0x40:
                    count = (control & 0x1F) + 2
                    fixed = payload[at + 1]
                    at += 2
                    for _ in range(count):
                        out.append(fixed)
                        out.append(payload[at])
                        at += 1
                else:
                    count = (control & 0x1F) + 2
                    out.extend(bytes([payload[at + 1]]) * count)
                    at += 2
            elif control & 0x40:
                count = (control & 0x1F) + 2
                out.extend(payload[at + 1 : at + 3] * count)
                at += 3
            else:
                count = (control & 0x1F) + 1
                out.extend(payload[at + 1 : at + 1 + count])
                at += 1 + count
        produced = len(out) - base
        if produced % BLOCK and at < end:
            raise ValueError("a block produced %d bytes, not a whole $400" % produced)
    return bytes(out)


def run_length(data, at, limit):
    """How far the same byte repeats from here."""
    length = 1
    while length < limit and data[at + length] == data[at]:
        length += 1
    return length


def pair_run(data, at, left):
    """How many times the pair starting here repeats."""
    count = 1
    while (
        count < min(MAX_REPEAT, left // 2)
        and data[at + count * 2] == data[at]
        and data[at + count * 2 + 1] == data[at + 1]
    ):
        count += 1
    return count


def alternating_run(data, at, left):
    """How many pairs share this first byte, whatever their second."""
    count = 1
    while count < min(MAX_REPEAT, left // 2) and data[at + count * 2] == data[at]:
        count += 1
    return count


def build_chains(data):
    """Where each two-byte sequence was last seen, as a chain of positions."""
    heads = {}
    previous = [-1] * len(data)
    for at in range(len(data) - 1):
        key = (data[at] << 8) | data[at + 1]
        previous[at] = heads.get(key, -1)
        heads[key] = at
    return heads, previous


def longest_match(data, at, limit, heads, previous):
    """The longest match at this position, and how far back it starts."""
    if limit < MIN_MATCH or at + 1 >= len(data):
        return 0, 0
    best_length, best_distance = 0, 0
    source = heads.get((data[at] << 8) | data[at + 1], -1)
    floor = at - MAX_DISTANCE
    while source >= 0 and source > floor:
        if source >= at:
            source = previous[source]
            continue
        length = 0
        while length < limit and data[source + length] == data[at + length]:
            length += 1
        if length > best_length:
            best_length, best_distance = length, at - source
            if length == limit:
                break
        source = previous[source]
    return (best_length, best_distance) if best_length >= MIN_MATCH else (0, 0)


def parse(data):
    """The cheapest tokens for this data, block by independent block."""
    tokens = []
    for start in range(0, len(data), BLOCK):
        tokens.extend(parse_block(data[start : start + BLOCK]))
    return tokens


def parse_block(data):
    """The cheapest sequence of tokens for one block, never leaving it."""
    size = len(data)
    heads, previous = build_chains(data)
    matches = [(0, 0)] * size
    frontier = type(data) is bytes or type(data) is bytearray
    for at in range(size):
        if frontier and at + 1 < size:
            # Skip only future links; retain the nearest-first candidate order.
            heads[(data[at] << 8) | data[at + 1]] = previous[at]
        matches[at] = longest_match(data, at, min(MAX_MATCH, size - at), heads, previous)

    cost = [0] * (size + 1)
    choice = [None] * (size + 1)
    for at in range(size - 1, -1, -1):
        left = size - at
        best = 2 + cost[at + 1]
        pick = ("literal", 1, None)

        for length in range(2, min(MAX_LITERAL, left) + 1):
            here = 1 + length + cost[at + length]
            if here < best:
                best, pick = here, ("literal", length, None)

        repeats = run_length(data, at, min(MAX_REPEAT, left))
        for length in range(MIN_MATCH, repeats + 1):
            here = 2 + cost[at + length]
            if here < best:
                best, pick = here, ("run", length, data[at])

        if left >= 4:
            for count in range(2, pair_run(data, at, left) + 1):
                here = 3 + cost[at + count * 2]
                if here < best:
                    best, pick = here, ("pair", count * 2, data[at : at + 2])
            for count in range(2, alternating_run(data, at, left) + 1):
                here = 2 + count + cost[at + count * 2]
                if here < best:
                    best, pick = here, ("alternate", count * 2, data[at])

        length, distance = matches[at]
        for take in range(MIN_MATCH, length + 1):
            here = 2 + cost[at + take]
            if here < best:
                best, pick = here, ("match", take, distance)
        cost[at] = best
        choice[at] = pick

    tokens = []
    at = 0
    while at < size:
        kind, length, detail = choice[at]
        tokens.append((kind, length, detail))
        at += length
    return tokens


def emit(data, tokens):
    """The tokens as the bytes the decoder reads, without the size header."""
    out = bytearray()
    at = 0
    for kind, length, detail in tokens:
        if kind == "literal":
            out.append(LITERAL_CONTROL | (length - 1))
            out.extend(data[at : at + length])
        elif kind == "run":
            out.append(RUN_CONTROL | (length - 2))
            out.append(detail)
        elif kind == "pair":
            out.append(PAIR_CONTROL | (length // 2 - 2))
            out.extend(detail)
        elif kind == "alternate":
            count = length // 2
            out.append(ALTERNATE_CONTROL | (count - 2))
            out.append(detail)
            out.extend(data[at + step * 2 + 1] for step in range(count))
        else:
            distance = detail - 1
            out.append(MATCH_CONTROL | ((length - 2) << 2) | (distance >> 8))
            out.append(distance & 0xFF)
        at += length
    return bytes(out)


def emit_blocks(data, tokens):
    """The tokens as bytes, with each block encoded against its own start."""
    out = bytearray()
    at = 0
    for start in range(0, len(data), BLOCK):
        block = data[start : start + BLOCK]
        taken = []
        produced = 0
        while produced < len(block):
            kind, length, detail = tokens[at]
            taken.append((kind, length, detail))
            produced += length
            at += 1
        out.extend(emit(block, taken))
    return bytes(out)


def compress(data):
    """One payload, ready for LoadCompressedToRAM or LoadCompressedToVRAM."""
    if not data:
        raise ValueError("there is nothing to compress")
    body = emit_blocks(data, parse(data))
    # The header is the exact number of bytes the decoder consumes, not an
    # offset. Data_ProcessPointer_StoreEndPointer computes the stop address as
    # body_start + header and Data_LZSSDecomp stops on `cmpa.l a4,a1 / bcc`,
    # so a header one larger makes the hardware read one control byte past the
    # end and append up to 33 bytes of whatever follows. Every one of the 122
    # original payloads ends exactly on this boundary, and the pad byte below
    # appears in precisely the 52 of them whose header is odd.
    payload = struct.pack(">H", len(body)) + body
    # An odd payload pushes everything after it to an odd address, and a VDP
    # DMA source is a word address: an odd one cannot be expressed, so the
    # transfer reads from a byte earlier and the art comes out in vertical
    # slices. It is the uncompressed sprite art that shows it, which is the
    # confusing part - nothing decompressed it, it just moved. 231 of the 232
    # original payloads are an even number of bytes for the same reason. The
    # pad sits past `size`, so no decoder ever reads it.
    return payload if len(payload) % 2 == 0 else payload + bytes(1)


def round_trip_errors(root, payloads=None):
    """Every payload must come back out of the game's decoder unchanged."""
    errors = []
    for name, raw in sorted((payloads or cartridge_payloads(root)).items()):
        original = decompress(raw)
        try:
            rebuilt = compress(original)
        except ValueError as error:
            errors.append("%s: %s" % (name, error))
            continue
        try:
            back = decompress(rebuilt)
        except ValueError as error:
            errors.append("%s: the decoder refused the result (%s)" % (name, error))
            continue
        if back != original:
            errors.append("%s: decoded back to %d bytes, not %d" % (name, len(back), len(original)))
    return errors


SHARED_TILE_SOURCES = "Stage_SharedTileSourceTable"
ANY_DIRECTIVE = re.compile(r"^\s*(dc\.[bwl])\s+([^;]+?)\s*(?:;.*)?$")
SYMBOL = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
ASSET_SOURCE = re.compile(r"^\s*dc\.l\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:;.*)?$")
LABEL_BINCLUDE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"([^"]+)"')
LABEL_BYTES = re.compile(r"^(?P<name>[A-Za-z_][A-Za-z0-9_]*):(?P<rest>.*)$")
BYTE_DIRECTIVE = re.compile(r"^\s*dc\.b\s+([^;]+?)\s*(?:;.*)?$")


def read_asset_records(lines):
    """One label's directives as `LoadObjData` records, or None if it is not a list.

    A record is `dc.w command`, `dc.l source`, `dc.w destination`, and the list
    ends at a word with bit 15 set. Reading whole lists rather than grepping for
    a command word is what keeps a `dc.w 7` that happens to be some other datum
    out of the set.
    """
    tokens = []
    for line in lines:
        directive = ANY_DIRECTIVE.match(line)
        if directive is None:
            if line.strip() and not line.strip().startswith(";"):
                return None
            continue
        for token in directive.group(2).split(","):
            tokens.append((directive.group(1), token.strip()))
    records = []
    at = 0
    while at < len(tokens):
        kind, token = tokens[at]
        if kind != "dc.w":
            return None
        try:
            value = int(token[1:], 16) if token.startswith("$") else int(token)
        except ValueError:
            return None
        if value & 0x8000:
            return records if records and at + 1 == len(tokens) else None
        if value > 7 or at + 2 >= len(tokens):
            return None
        if tokens[at + 1][0] != "dc.l" or tokens[at + 2][0] != "dc.w":
            return None
        records.append((value, tokens[at + 1][1]))
        at += 3
    return None


def payload_sources(root):
    """Symbols an asset list decompresses, plus the shared tile sources.

    Commands six and seven are the two that decompress, to RAM and to VRAM.
    The compact tile commands name their source indirectly:
    `Stage_ExpandAndSubmitTileAssetCommands` turns an index into an entry of
    `Stage_SharedTileSourceTable` and submits it as a command seven.
    """
    wanted = set()
    for path in sorted((root / "src").rglob("*.s")):
        lines = path.read_text(encoding="utf-8").splitlines()
        name = None
        body = []
        for index, line in enumerate(lines + [""]):
            head = LABEL_BYTES.match(line)
            if head or index == len(lines):
                if name and body:
                    records = read_asset_records(body)
                    for command, source in records or []:
                        if command in (6, 7) and SYMBOL.match(source):
                            wanted.add(source)
                if name == SHARED_TILE_SOURCES:
                    for entry in body:
                        found = ASSET_SOURCE.match(entry)
                        if found:
                            wanted.add(found.group(1))
                if head:
                    name, body = head.group("name"), [head.group("rest")]
                continue
            if name is not None:
                body.append(line)
    return wanted


def labelled_payloads(root):
    """Every label that holds bytes, whether binincluded or written inline."""
    found = {}
    for path in sorted((root / "src").rglob("*.s")):
        name = None
        tokens = []

        def flush():
            if name and tokens:
                try:
                    found.setdefault(name, bytes(v & 0xFF for v in tokens))
                except (TypeError, ValueError):
                    pass

        for line in path.read_text(encoding="utf-8").splitlines():
            included = LABEL_BINCLUDE.match(line)
            if included:
                flush()
                name, tokens = None, []
                target = root / included.group(2)
                if target.is_file():
                    found[included.group(1)] = target.read_bytes()
                continue
            head = LABEL_BYTES.match(line)
            if head:
                flush()
                name, tokens = head.group("name"), []
                line = head.group("rest")
            if name is None:
                continue
            directive = BYTE_DIRECTIVE.match(line)
            if directive is None:
                if line.strip() and not line.strip().startswith(";"):
                    flush()
                    name, tokens = None, []
                continue
            for token in directive.group(1).split(","):
                token = token.strip()
                try:
                    tokens.append(int(token[1:], 16) if token.startswith("$") else int(token))
                except ValueError:
                    flush()
                    name, tokens = None, []
                    break
        flush()
    return found


def cartridge_payloads(root):
    """Every compressed payload a stage actually loads."""
    held = labelled_payloads(root)
    return {name: held[name] for name in sorted(payload_sources(root)) if name in held}
