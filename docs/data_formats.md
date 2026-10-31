# Authored data formats

Alien Soldier's data lives in assembly tables and private payloads extracted
from the cartridge. `make split` uses
[the asset manifest](../assets/manifest.json) to check each ROM's identity and
each segment's range and hash before writing `data/`. The 68000 source includes
those segments with `binclude`; the Z80 program is assembled separately from
`src/sound/z80/driver.asm`.

This guide describes the binary layouts, their readers and the limits of editing
them in Retrolarium. JP and EU share the source and codecs; their asset ranges
and revision-specific payloads come from the manifest, not from filenames that
happen to contain a Japanese ROM address. See [revisions](revisions.md) for
cartridge identities.

## The segments

The Japanese manifest contains 589 segments. The table groups them rather than
repeating all the ranges and hashes; the manifest is the complete inventory for
both revisions, including EU overrides under `profiles/`.

| Directory    | JP segments | Contents and interpretation                                                                                 |
| ------------ | ----------: | ----------------------------------------------------------------------------------------------------------- |
| `artcomp/`   |         128 | LZSS tile art; each archive has its own length header                                                       |
| `artunc/`    |         289 | Raw 4bpp tiles, bare or in DMA-length-prefixed blocks; includes fonts                                       |
| `mappings/`  |          76 | Compressed plane data and related payloads; a directory name alone does not determine the format            |
| `other/`     |          55 | Interface art, maps, text, demo streams, palette data and miscellaneous tables, classified by their readers |
| `credits/`   |           1 | Animated credits glyph stream                                                                               |
| `cutscenes/` |           1 | Game-over perspective lookup                                                                                |
| `sound/`     |          39 | Music, effects, FM instruments, DAC banks and the preserved Z80 image                                       |

Extraction is not a claim that every segment is editable. For example, an
unreferenced archive stays preserved even when no Studio view owns it. Some
files once contained two consecutive archives;
[payload boundaries](payload_archives.md) records their separation and the tails
that are not compressed data.

## LZSS

`Data_LZSSDecomp` reads a big-endian word giving the compressed stream's byte
length, followed by tokens. Retrolarium Kit implements the decoder and encoder
in `games/alien_soldier/lzss.py`.

| Control byte `c` | Following data and output                                                                           |
| ---------------- | --------------------------------------------------------------------------------------------------- |
| `$00-$1F`        | Copy `(c & $1F) + 1` literal bytes                                                                  |
| `$20-$3F`        | Repeat the next byte `(c & $1F) + 2` times                                                          |
| `$40-$5F`        | Repeat the next two-byte pair `(c & $1F) + 2` times                                                 |
| `$60-$7F`        | Read one fixed byte and `(c & $1F) + 2` varying bytes; emit the fixed byte before each varying byte |
| `$80-$FF`        | Read one more byte; copy `((c >> 2) & $1F) + 2` bytes from a distance of `(token_word & $3FF) + 1`  |

The VRAM loader resets its output pointer after every `$400` decoded bytes.
Back-references must stay within that block. RAM-only stage and screen maps may
use matches across these boundaries because their loaders keep the output
pointer. The encoder chooses the mode from the actual loaders of a payload; data
also used as VRAM art must satisfy the stricter rule.

Recompression can produce a different legal stream. An unchanged payload keeps
its original bytes; an edited stream must fit its original compressed capacity
and is padded after its length-delimited stream so the next payload stays put.

## Tile codec

Asset commands two and three use `TileCodec_DecodeTile`, a separate format used
by seven interface-art payloads. Byte zero is the tile count minus one. The
remaining bits describe colour tokens, downward marker paths and runs that fill
an 8x8 tile; the complete payload is padded to even length.

[The tile codec specification](tile_codec_spec.md) gives the bit grammar,
reference implementation and benchmarks. Kit's `tile_codec.py` preserves the
bits of unchanged tiles, tries recolouring the original tokens for changed
tiles, and otherwise uses plain runs. It selects the shorter legal candidate and
checks the decoded pixels. Arbitrary replacement art can still exceed the
original slot; fitting every possible image is not guaranteed.

## Uncompressed tiles and fonts

A Mega Drive tile is 8x8 pixels at 4bpp: 32 bytes, two palette indices per byte,
high nibble first. `Sprite_RenderDynamicMapping` uploads art stored as chains of
blocks, each beginning with a big-endian word counting the following tile bytes.
Other payloads are bare tiles. `tiles.py` distinguishes these shapes; editing
changes pixels while retaining block counts, lengths and headers.

The shared font uses two vertically stacked tiles per glyph (64 bytes). The
Japanese story font uses four tiles per glyph (128 bytes), ordered top-left,
bottom-left, top-right, bottom-right. These fonts use the same 4bpp tile
encoding. Glyph interpretation belongs to the text reader below.

## Stage records and object placements

`Stage_ApplyConfigurationRecord` reads a 30-byte stage record:

| Fields, in order                                                | Storage              |
| --------------------------------------------------------------- | -------------------- |
| State offset; spawn-list pointer; enemy spawn director          | Word, longword, word |
| Primary and secondary palette-effect offsets; sprite attributes | Byte, byte, word     |
| Primary camera X/Y; secondary camera X/Y                        | Four words           |
| Plane A and B entry modes                                       | Two words            |
| Player start X/Y, biased by `$80`; palette-list pointer         | Byte, byte, longword |

`levels.py` reads the records in `src/stages/configuration_records.s` and
follows `Stage_InitializerOffsets`. Numeric edits must remain valid for the
tables the readers index. The spawn-list and palette-list identities stay fixed.

`Sys_ProcessSpawnList` consumes six big-endian words per placement: X, Y, type,
parameter, first object slot and slot limit. The type is a byte offset into
`Entity_UpdateHandlerTable`; its low two bits select difficulty restrictions.
`$7FFF` ends a list. Eight lists intentionally run into the next list without a
terminator. Edits retain placement counts and this termination structure.

## Stage maps and static screens

Plane descriptors interpret decompressed RAM as three layers:

- A pattern is 4x4 VDP name-table words: sixteen 8x8 tiles, or 32x32 pixels.
- A chunk is 8x8 byte-sized pattern indices, covering 256x256 pixels.
- A coarse map is 32x32 byte-sized chunk indices.

The name-table word carries the tile index, horizontal and vertical flips,
palette line and priority. `maps.py` exports pattern values as 16-bit words and
the other two layers as bytes. Their counts stay fixed, and recompressed maps
must fit their original slots. A payload also used as tile art has one editable
owner, in the compressed-tile document, rather than two conflicting copies.

Static screens use the same asset loaders and plane descriptors. The game
profile identifies the title, story, options/password and ending screens;
`screens.py` reads their maps and describes the title's post-load index
transforms for previews. Credits scenes pair a sixteen-colour palette with an
asset list and a name table 64 cells wide. Editable map values keep their width,
count and compressed capacity; loader and preview metadata are derived.

## Palette commands

`Gfx_LoadPaletteCommand` reads a destination byte (an even byte offset into the
64-colour palette buffer), a count byte storing the colour count minus one, then
that many big-endian CRAM words. A label can contain one command or a bank of
commands. `src/rendering/palettes.s` also holds relative offset lists that
select commands; the multiple-palette loader plays the common command first.

`palettes.py` exposes colours and the lists needed for previews. Editing keeps
destinations, counts and list entries intact. A Genesis colour uses three bits
per component in word mask `$0EEE`.

## Sprite mappings and animation scripts

`Sprite_RenderMapping` reads six-byte static pieces: an attribute word, size
byte, link byte, signed Y byte and signed X byte. Attribute bit 15 ends the
mapping; it is not a priority flag here. The renderer overwrites the link byte.
Size is `(width - 1) << 2 | (height - 1)` in tiles, and tile and flip attributes
are relative to the object's attributes.

Dynamic pieces are eight bytes: an attribute word, a longword combining the art
pointer with a size byte in its top byte, then packed Y/X bytes. `mappings.py`
retains piece counts and end marks. Dynamic pieces keep their tile and size; art
can be replaced by another eligible source block of equal length.

`Anim_ResolveTimedMappingFrame` reads word pairs: `Target-*` and duration. A
nonzero duration names a mapping and counts reader calls; zero makes the target
a jump to another script entry. The assembler resolves symbolic displacements.
`animations.py` preserves entry counts and frame/jump roles while allowing
supported target and timing edits.

## Text and credits

Text is glyph indices, not an ASCII or Unicode string. `text.py` retains record
boundaries and assigns each value a role: editable glyph (`g`), editable credits
delay (`d`), or fixed structural data (`f`). Lengths and roles cannot change.

| Reader group          | Layout                                                   |
| --------------------- | -------------------------------------------------------- |
| Story                 | 34-byte rows ending `$FF`; `$FE` ends the stream         |
| Frontend              | Glyph strings ending `$FF`                               |
| Stage messages        | Row byte, glyphs, `$FF`; `$FD` ends the sequence         |
| Boss and ship scripts | Addressed records: attribute word, glyphs, `$FF`         |
| Credits               | Two rows of delay, count and glyphs                      |
| Glyph lists           | Glyphs ending `$FF`, packed as words in source           |
| Japanese story        | Word-sized glyph indices biased by `$20`, ending `$FFFF` |
| Results               | 22-byte rows ending `$FF`, and 22-glyph labels           |

`config/names.json` supplies the shared font's displayed characters; Japanese
story glyphs are shown by number. Changing display names does not change text
encoding or authorize resizing a record.

## Sound program, sequences, envelopes and DAC banks

The reconstructed Z80 program is executable source, assembled before the 68000
image. It is distinct from the preserved image in the split assets. Music and
effects are Treasure's 68000 SMPS data;
[the sound-driver guide](sound_driver.md) describes the division between the two
processors and the request IDs.

`sound.py` reads BGM headers containing an instrument-table offset, channel
counts, tick multiplier and tempo, followed by four-byte FM/DAC and six-byte PSG
channel records. SFX headers have an instrument offset, tick multiplier and
channel count followed by six-byte channel records. Sequence bytes encode
durations below `$80`, notes at `$80-$DF`, commands at `$E0-$FE` and extended
commands at `$FF`; jumps, loops and calls use signed word displacements. An FM
instrument occupies 25 bytes in operator order 1, 3, 2, 4.

Editing changes notes, durations, supported non-flow operands and instrument
bytes. Payload size, headers, instruction boundaries, opcodes and flow targets
stay fixed and are checked by decoding again. A piano-roll edit is not a
general-purpose sequence relinker.

Pitch and PSG volume envelopes are byte streams selected by one-based pointer
tables. Values are signed; `$80` restarts, `$81` holds the last value, `$82`
jumps to the following byte's index, `$83` ends, and pitch `$84` changes the
scale. `envelopes.py` allows value edits while preserving commands, operands and
lengths, including envelopes that run into the next physical table.

The nine DAC banks contain DPCM, not raw PCM samples. Their headers are
four-byte little-endian records: an in-bank start (bit 15 ignored) and byte
count. The first start also gives the table size. The Z80 starts from `$80` and
applies two deltas per packed byte, using the high- and low-nibble delta pages
in its source. `pcm.py` keeps sample lengths, descriptors and trailing bank
bytes fixed; imported audio must be cut or padded to that capacity.

## Attract-demo streams

`Demo_PlaybackSystem` selects a stage through `Demo_StageIndexTable` and a
stream through `Demo_InputStreamPointers`. A stream begins with a big-endian
word of idle frames, then pairs of words: held/newly pressed buttons in the
high/low bytes, followed by a frame count. A demo runs for `$1000` frames unless
Start interrupts it. `demos.py` preserves the stream capacity, pads unused space
with zeroes and extends the final step when needed to cover the demo duration.

These are in-game data. The external MAME [input movie](../movies/README.md)
drives the controller from power-on and is a separate format and test fixture.

## Jointed bosses

`Sprite_InitializeLinkedMetaspriteParts` constructs `$60`-byte child records
from a descriptor longword, radius byte and link word per part. Descriptors
select inline sprites, mappings or direction tables and carry display flags; the
radius gives bone length, and the link names the parent, palette and sort depth.
Pose tables store one angle byte per channel. Typical animation commands combine
a pose offset with timing; `$80NN` plays sound, `$FFFF` loops and `$FFFE` holds
the last pose. Some bosses use different byte scripts or code instead of this
pose format.

`bosses.py` exports the source's skeletons, editable poses and supported
animation data, together with derived setup/pose programs, RAM, art and plane
bodies needed for previews. Derived execution state is not another authored
binary format. Part topology and script structure have source-specific
validators; this is not a facility to replace arbitrary boss code.

The game-owned `catalogs.boss_readers` in `config/names.json` identifies the
reader entry points and exceptions. Independent expectations live in
`tests/fixtures/retrolarium.json`; neither belongs in shared Kit or Studio
source. [Editing in Retrolarium](retrolarium.md) explains the catalog, snapshots
and regression references.

## Project documents and round trips

Kit's `games/alien_soldier/workspace.py` exports fourteen editable JSON
documents. These are views of source and payloads in a prepared project, not
additional ROM files to commit.

| Project document                 | Codec module          |
| -------------------------------- | --------------------- |
| `levels/levels.json`             | `levels.py`           |
| `levels/maps.json`               | `maps.py`             |
| `levels/demos.json`              | `demos.py`            |
| `graphics/tiles.json`            | `tiles.py`            |
| `graphics/compressed_tiles.json` | `compressed_tiles.py` |
| `graphics/palettes.json`         | `palettes.py`         |
| `graphics/mappings.json`         | `mappings.py`         |
| `graphics/animations.json`       | `animations.py`       |
| `screens/screens.json`           | `screens.py`          |
| `text/text.json`                 | `text.py`             |
| `sound/sound.json`               | `sound.py`            |
| `sound/envelopes.json`           | `envelopes.py`        |
| `sound/pcm.json`                 | `pcm.py`              |
| `graphics/bosses.json`           | `bosses.py`           |

Three further views, `levels/stages.json`, `graphics/objects.json` and
`graphics/art.json`, are derived context, not additional editable payload
owners. Game facts in `config/game_profile.json`, `config/names.json` and
`config/object_art.json` supply revision settings, labels and observed art
associations.

The build applies documents to a temporary source tree, assembles the Z80 and
then the 68000 program, and updates the appropriate revision's checksum after an
edit. Unchanged documents leave original source and payload bytes intact.
`make studio-check` validates all fourteen documents and requires a zero-edit
ROM rebuild to match each original revision byte for byte.
`make verify-revisions` checks the ordinary JP and EU builds independently.

For edited compressed data, the promise is decoded content plus fixed capacity,
not reproduction of the original compressor's choices. A capacity error is a
rejected edit, not permission to truncate the stream or move unrelated data.
Byte-exact unedited builds and valid edited round trips do not by themselves
prove every scene's runtime behaviour. The current MAME coverage and the planned
3.1 scenario migration are described in
[the release scope](../README.md#release-scope).
