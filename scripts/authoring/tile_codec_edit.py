"""Edit tile-codec art using source token shapes and bounded run encoding."""

from __future__ import annotations

from dataclasses import dataclass

from authoring.tile_codec import (
    FAR_LONG, FAR_SHORT, NEAR_OFFSETS, TILE_BYTES, TILE_PIXELS,
    Bits, BitWriter, decompress, encode_tile, pack_tile, unpack_tile,
)


@dataclass(frozen=True)
class TilePlan:
    start: int
    end: int
    colours: tuple[tuple[int, int], ...]
    owners: tuple[int, ...]


def bit_position(bits: Bits) -> int:
    return bits.at * 8 + bits.bit


def read_plan(bits: Bits) -> TilePlan:
    """Attribute each final pixel to the literal colour that paints it.

    Markers carry the originating token's colour through subsequent runs.
    A later literal or marker can overwrite that ownership, just as in the
    cartridge reader. No marker path or run length is guessed from an image.
    """
    start = bit_position(bits)
    owners = [-1] * TILE_PIXELS
    seeded = [False] * TILE_PIXELS
    colours = []
    at = 0
    while at < TILE_PIXELS:
        colour_bit = bit_position(bits)
        token = bits.read(5)
        owner = len(colours)
        colours.append((colour_bit, token >> 1))
        owners[at] = owner
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
                    owners[target] = owner
                    seeded[target] = True
        width = 1
        while bits.read(1):
            width += 1
        run = (1 << width) + bits.read(width) - 2
        # A source overrun does not paint another pixel of this tile. Avoid
        # iterating its ignored tail; edited run encodings never overrun.
        finish = min(TILE_PIXELS, at + run)
        while at < finish:
            if seeded[at]:
                owner = owners[at]
                seeded[at] = False
            owners[at] = owner
            at += 1
    return TilePlan(start, bit_position(bits), tuple(colours), tuple(owners))


def copy_bits(out: BitWriter, data: bytes, start: int, end: int) -> None:
    """Copy an unaligned source interval without retaining a whole bit list."""
    bits = Bits(data, start // 8)
    bits.bit = start % 8
    while start < end:
        count = min(32, end - start)
        out.write(bits.read(count), count)
        start += count


def template_colours(plan: TilePlan, pixels: list[int]) -> tuple[int, ...] | None:
    replacements = [None] * len(plan.colours)
    for owner, pixel in zip(plan.owners, pixels):
        previous = replacements[owner]
        if previous is not None and previous != pixel:
            return None
        replacements[owner] = pixel
    return tuple(original if replacement is None else replacement
                 for (_bit, original), replacement in zip(plan.colours, replacements))


def write_template(
    out: BitWriter, original: bytes, plan: TilePlan, colours: tuple[int, ...],
) -> None:
    cursor = plan.start
    for (position, _original), replacement in zip(plan.colours, colours):
        copy_bits(out, original, cursor, position)
        out.write(replacement, 4)
        cursor = position + 4
    copy_bits(out, original, cursor, plan.end)


def compress_edited(original: bytes, data: bytes) -> bytes:
    """Encode edits, retaining exact zero-edit bytes and unchanged tile tokens.

    For each edited tile, choose the shorter legal encoding: the original
    marker/run shape with new literal colours, if it can paint the requested
    pixels, or the run-only encoder. The caller must enforce the ROM slot's
    capacity. Work is linear in the source stream and uses one 64-pixel plan
    at a time; this is not a search for a globally optimal marker arrangement.
    """
    baseline = decompress(original)
    if len(data) != len(baseline):
        raise ValueError("edited art must retain the source tile count")
    if data == baseline:
        return original
    out = BitWriter()
    bits = Bits(original, 1)
    for offset in range(0, len(data), TILE_BYTES):
        plan = read_plan(bits)
        tile = data[offset:offset + TILE_BYTES]
        source_tile = pack_tile([plan.colours[owner][1] for owner in plan.owners])
        if source_tile != baseline[offset:offset + TILE_BYTES]:
            raise ValueError("source token ownership differs from the tile decoder")
        if tile == source_tile:
            copy_bits(out, original, plan.start, plan.end)
            continue
        pixels = unpack_tile(tile)
        replacements = template_colours(plan, pixels)
        naive = BitWriter()
        encode_tile(naive, pixels)
        naive_size = len(naive.out) * 8 + naive.bit
        if replacements is not None and plan.end - plan.start <= naive_size:
            write_template(out, original, plan, replacements)
        else:
            copy_bits(out, naive.finish(), 0, naive_size)
    result = original[:1] + out.finish()
    if len(result) % 2:
        result += b"\0"
    if decompress(result) != data:
        raise ValueError("edited tile-codec stream does not round-trip")
    return result
