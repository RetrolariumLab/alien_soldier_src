# Alien Soldier tile codec: format, reference code, and an open problem

Self-contained. Nothing here needs the rest of this repository.

Alien Soldier (Mega Drive, Treasure, 1995) compresses data with two formats. One
is an ordinary LZSS. The other, the subject of this document, is used by seven
payloads of interface art and is built around something tile graphics actually
have: edges that continue onto the row below. Its decoder lives in the ROM at
`TileCodec_DecodeTile`.

We can read the format and write it back. What we cannot yet do is write it
*well*: our encoder emits about half as many bytes again as the original. The
open problem is at the end.

## The unit of work

A tile is 8x8 pixels, each pixel a 4-bit palette index, so 64 pixels packed into
32 bytes, two pixels per byte, high nibble first. The decoder builds a tile in a
64-slot scratch buffer and packs it at the end.

Because a tile is eight wide, a pixel `p` and the pixels `p+6 ... p+10` are the
row below it, from one column left to one column right. That relationship is the
whole idea of the format.

```
    p-1   p   p+1        ...  p   ...
    p+7  p+8  p+9        p+6 p+7 p+8 p+9 p+10
```

## Payload framing

```
byte 0          : tile count minus one (so 1...256 tiles)
bytes 1 onward  : the bit stream, most significant bit first
```

The bit stream is read as one continuous sequence of bits over bytes 1, 2, 3,
... A payload is padded to an even total length, because the ROM decoder fetches
the stream a 16-bit word at a time. The final byte is zero-padded.

The ROM keeps a 16-bit rotating reservoir plus a count of unconsumed bits, and
reloads a word when the count runs out. That is an implementation detail: the
observable behaviour is a plain MSB-first bit stream, and treating it as one
reproduces the ROM exactly on all seven payloads.

## The token loop

Decoding a tile means running this until 64 slots are filled:

1. **Token -- 5 bits.** The top 4 bits are a colour; the low bit says whether a
   marker sequence follows. The colour is written to the current slot, which is
   then no longer seeded, and the position advances by one.

2. **Marker sequence -- only if the low bit was set.** A cumulative walk forward
   that seeds the *same* colour at slots the fill has not reached yet:

   | bits         | meaning         |
   | ------------ | --------------- |
   | `01`         | step 7          |
   | `10`         | step 8          |
   | `11`         | step 9          |
   | `00` `1` `0` | step 6          |
   | `00` `1` `1` | step 10         |
   | `00` `0`     | end of sequence |

   The steps accumulate. Writing `q` for the position of the token's own pixel,
   after steps `s1, s2, s3 ...` the seeded slots are `q+s1`, `q+s1+s2`,
   `q+s1+s2+s3` and so on. A seed beyond slot 63 is discarded, not an error.
   Ending the sequence always costs its own 3 bits.

3. **Run length -- always, whether or not markers were emitted.** Count 1-bits
   until a 0; call the number of bits read including that 0 `k`. Read `k` more
   bits as `payload`. The run is

   ```
   run = 2**k + payload - 2
   ```

   pixels of the current colour. `k` is not a free choice: `payload` must fit in
   `k` bits and be non-negative, which pins `k = floor(log2(run + 2))`.

   **The run is where seeding pays off.** Walking forward, if the slot it is
   about to write was seeded by a marker, the run *adopts that slot's colour*
   and carries on in the new colour. One token can therefore paint a stretch of
   several colours, and an edge laid down earlier is what turns the fill.

A run may carry the position past slot 63; the ROM writes past its buffer and
stops on the next check. An encoder should never rely on that.

## Reference decoder

```python
TILE_PIXELS = 64
TILE_BYTES = 32
NEAR = {1: 7, 2: 8, 3: 9}


class Bits:
    """MSB-first bit reader."""

    def __init__(self, data, at=0):
        self.data, self.at, self.bit = data, at, 0

    def read(self, count):
        value = 0
        for _ in range(count):
            if self.at >= len(self.data):
                raise ValueError("the bit stream ran out")
            value = (value << 1) | ((self.data[self.at] >> (7 - self.bit)) & 1)
            self.bit += 1
            if self.bit == 8:
                self.bit, self.at = 0, self.at + 1
        return value


def decode_tile(bits):
    """64 palette indices."""
    slot = [0] * TILE_PIXELS
    seeded = [False] * TILE_PIXELS
    at = 0
    while at < TILE_PIXELS:
        token = bits.read(5)
        colour = token >> 1
        slot[at], seeded[at] = colour, False
        at += 1
        if token & 1:                                  # marker sequence
            ahead = 0
            while True:
                near = bits.read(2)
                if near:
                    ahead += NEAR[near]
                elif not bits.read(1):
                    break
                else:
                    ahead += 10 if bits.read(1) else 6
                target = at - 1 + ahead
                if target < TILE_PIXELS:
                    slot[target], seeded[target] = colour, True
        k = 1                                          # run length
        while bits.read(1):
            k += 1
        run = (1 << k) + bits.read(k) - 2
        for _ in range(run):
            if at >= TILE_PIXELS:
                break
            if seeded[at]:
                colour = slot[at]
                seeded[at] = False
            slot[at] = colour
            at += 1
    return slot


def pack_tile(slot):
    return bytes(((slot[i] & 0xF) << 4) | (slot[i + 1] & 0xF)
                 for i in range(0, TILE_PIXELS, 2))


def decompress(payload):
    bits = Bits(payload, 1)
    out = bytearray()
    for _ in range(payload[0] + 1):
        out += pack_tile(decode_tile(bits))
    return bytes(out)
```

## Reference encoder, the naive one

It emits no markers at all: each maximal run of one colour becomes one token
plus one run. Correct, and roughly 150% of the original size.

```python
class BitWriter:
    def __init__(self):
        self.out, self.pending, self.bit = bytearray(), 0, 0

    def write(self, value, count):
        for shift in range(count - 1, -1, -1):
            self.pending = (self.pending << 1) | ((value >> shift) & 1)
            self.bit += 1
            if self.bit == 8:
                self.out.append(self.pending)
                self.pending, self.bit = 0, 0

    def finish(self):
        if self.bit:
            self.out.append(self.pending << (8 - self.bit))
            self.pending = self.bit = 0
        return bytes(self.out)


def write_run(out, run):
    k = (run + 2).bit_length() - 1
    for _ in range(k - 1):
        out.write(1, 1)
    out.write(0, 1)
    out.write(run + 2 - (1 << k), k)


def encode_tile(out, slot):
    at = 0
    while at < TILE_PIXELS:
        colour = slot[at]
        end = at + 1
        while end < TILE_PIXELS and slot[end] == colour:
            end += 1
        out.write((colour & 0xF) << 1, 5)        # low bit clear: no markers
        write_run(out, end - at - 1)
        at = end


def unpack_tile(tile):
    slot = []
    for byte in tile:
        slot += [byte >> 4, byte & 0xF]
    return slot


def compress(data):
    assert data and len(data) % TILE_BYTES == 0
    count = len(data) // TILE_BYTES
    assert count <= 256
    out = BitWriter()
    for i in range(count):
        encode_tile(out, unpack_tile(data[i * TILE_BYTES:(i + 1) * TILE_BYTES]))
    payload = bytes([count - 1]) + out.finish()
    return payload if len(payload) % 2 == 0 else payload + bytes(1)
```

## Cost model

| construct                  | bits                     |
| -------------------------- | ------------------------ |
| token                      | 5                        |
| marker step of 7, 8 or 9   | 2                        |
| marker step of 6 or 10     | 4                        |
| marker sequence terminator | 3                        |
| run of length `R`          | `2 * floor(log2(R + 2))` |

A token with no markers costs `5 + 2k`. A token with `m` markers costs
`5 + (sum of step costs) + 3 + 2k`.

Note what makes markers worth it. A vertical edge one pixel wide, eight rows
tall, costs eight tokens the naive way -- at least `8 * 7 = 56` bits. As one
token with seven markers of step 8 it costs `5 + 7*2 + 3 + 2k`, about 24 bits,
and the runs that sweep past those seeds get shorter and cheaper too.

## The problem

The standalone encoder above remains a run-only reference. The authoring
pipeline now additionally uses `scripts/authoring/tile_codec_edit.py`: it reads
the original token stream and attributes final pixels to their literal colour
tokens, including marker seeds consumed by later runs. If edited pixels owned by
a token still share one colour, that literal can be changed while retaining the
original marker paths and run lengths. Otherwise a changed tile can fall back to
the reference run encoding. Unchanged tiles retain their original unaligned bit
intervals. The shorter legal candidate is selected per changed tile, and the
complete stream is decoded again before use.

This source-guided path recolours all seven cartridge streams within their
original slots and preserves exact original bytes at zero edit. It uses one
64-pixel ownership plan at a time, with no growing search frontier. It does not
solve the general optimization problem below: arbitrary new art may still fail
the fixed-capacity check in Graphics Studio.

**Given 64 target pixels, emit the fewest bits that decode to exactly them.**

Exactly: the decoder above, fed the output, must produce the target list, and
the position must land on 64 without the final run overshooting.

What makes it more than a greedy walk:

- A marker sequence is cumulative and unbounded in reach, so a single token can
  seed a whole column, or a diagonal, or any path whose steps are all in 6...10.
- Seeds change what later runs paint. A run does not simply lay down one colour;
  it changes colour at every seeded slot it crosses. So the choice of markers
  and the choice of run lengths are not independent.
- A seed can be overwritten by a later token's own pixel before the fill ever
  reaches it, which wastes it -- or can be used deliberately.
- `k` is forced by `R`, so run length has no encoding slack, but *where you end
  one token and start the next* is free, and the cost is not linear in length.

A natural formulation is a shortest-path search over states of
`(position, pending seeds at slots ahead)`, with edges for each legal token
choice. The pending-seed component is what makes it interesting: it is unbounded
in principle but small in practice, because a seed is consumed as soon as the
fill reaches it.

An encoder is *correct* if every tile round-trips through the reference decoder.
It is *good* in proportion to how far below 152% of the original it gets. The
original encoder is a 1995 production tool, so matching it exactly is not
expected; beating the naive encoder substantially should be straightforward, and
approaching the original would be a real result.

## Benchmark

The seven payloads in the shipped cartridge, with the size the original encoder
achieved and the size the naive encoder above produces:

| payload                           | tiles | original  | naive     | naive / original |
| --------------------------------- | ----- | --------- | --------- | ---------------- |
| `SharedTitleAndOptionsType3DataA` | 256   | 5204      | 7686      | 148%             |
| `XiTigerCutsceneType3Data0000`    | 128   | 1956      | 3134      | 160%             |
| `SharedMenuType3DataF680`         | 76    | 1370      | 1894      | 138%             |
| `ResultsPostStageType3Data0000`   | 256   | 1316      | 2180      | 166%             |
| `WeaponSetupType3Data5800`        | 38    | 594       | 972       | 164%             |
| `DebugMenuInitialType3DataF680`   | 64    | 614       | 1000      | 163%             |
| `SharedTitleAndOptionsType3DataB` | 32    | 468       | 638       | 136%             |
| **total**                         | 850   | **11522** | **17504** | **152%**         |

Sizes include the one count byte and the even-length padding.

Two checks caught a real fault in the other codec and are worth keeping here:
every payload must decode to a whole number of tiles, and must consume its input
to the last byte, give or take the padding of a partial one. All seven originals
satisfy both.
