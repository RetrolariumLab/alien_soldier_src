# Content authoring

Edits live in a workspace beside the preservation build, never inside it. The
Japanese and European cartridges are separate bases, and each workspace records
which one it targets.

| Pipeline | Inputs | Output | Rule |
| --- | --- | --- | --- |
| Preservation | `src/` and `data/` | `asbuilt.bin` / `asbuilt_eu.bin` | Must equal the selected cartridge |
| Content | `content/workspace/<profile>/` over a staged copy of the source | `build/content/<profile>/alien_soldier.bin` | May differ after edits |
| Zero edit | Tracked preservation inputs only | `build/content/zero-edit/<profile>/alien_soldier.bin` | Must equal both cartridges |

The ignored `content/workspace/` directory belongs to the user.
Initialization creates only missing files unless `FORCE=true` is given. The
editors save there and never modify `src/`, `data/`, the asset manifests or the
preservation outputs.

## Commands

```text
make init-content CONTENT_PROFILE=jp     # create missing workspace documents
make init-content-all                    # both profiles
make inspect-content CONTENT_PROFILE=eu  # which documents differ from the source
make validate-content CONTENT_PROFILE=jp
make build-content CONTENT_PROFILE=eu    # the edited ROM
make check-content-zero-edit             # unedited source must build both cartridges
make check-content                       # every model and Studio check, both profiles
```

The Studios: `make level-studio`, `graphics-studio`, `screen-studio`,
`text-studio` and `sound-studio`, each with `CONTENT_PROFILE=jp` or `eu`.
Each also has a `check-…-studio` target that loads every document and makes a
real bounded edit and staged write for both profiles without opening a window.

## How a content build works

`make build-content` copies `src/` and `data/` into a disposable tree under
`build/content/` and applies the workspace documents there, so includes and
binary includes resolve inside the staged tree. Staging refuses symbolic links
and junctions on the way in and out, and replaces the staged tree only after
both inputs check out, so a failed run never deletes the previous output.

The ROM is assembled into a fresh sibling directory and moved into place only
when it converts and has the profile's two-megabyte size. The header checksum
is then recalculated with the profile's own boot loop: the Japanese one
includes the word at `$60000`, the European one sums through `$1FFFFE`.
`check-content-zero-edit` ignores the workspace, builds both profiles from the
tracked source and requires the exact SHA-1 values of `config/rom_profiles.json`;
it rewrites no checksum.

Every workspace writer replaces its file through a uniquely named temporary
beside it, keeping the format's JSON escaping and final newline. Each file is
replaced atomically, but a Save of several documents is not one transaction: a
later failure can leave earlier documents saved, with every edit still marked
unsaved so it can be retried ([workstation actions](workstation_actions.md)).

`config/authoring/content_studios.json` lists every editable artifact, its
workspace path and its Studio.

## Level Studio

[Stage maps](stage_map_model.md) and [Level Studio](level_studio.md) cover
the details.

- `level/levels.json`: all 314 fixed object placements and the thirty stage
  configuration records. Adding or removing placements, special initializers
  and asset lists are not editable.
- `level/stage_maps.json`: 42 compressed pattern, chunk and coarse-map streams in
  fixed slots, including five alternate plane-B pattern streams. The window
  paints raw map cells on a bounded stage viewport, composes saved Screen Studio
  edits to shared maps and rejects conflicting edits before rendering.
- `make playtest-level` builds the workspace and starts a stage by its password
  ([level playtest](level_playtest.md)).

## Graphics Studio

[Graphics models](graphics_models.md) and the [tile codec](tile_codec_spec.md)
cover the formats.

- `graphics/tile_art.json`: 289 uncompressed payloads, 3,230 tiles, each tile
  as 64 palette-index nibbles. Payload paths, block headers and tile counts stay
  fixed.
- `graphics/compressed_tile_art.json`: 146 LZSS streams that decode to whole
  tiles (six of them inline assembly) and seven command-two/three tile-codec
  streams, 29,405 tiles in all. An edit is recompressed and must fit the
  original compressed size; shorter streams are padded after their end.
  `Credits_SegaMappingData` is left out because its 408 decoded bytes are not
  tiles. Older schema-1 documents are migrated on `init-content`.
- `graphics/palettes.json`: the colour words of all 95 palette commands in 55
  blocks and 29 offset lists. Destinations, counts and owners are fixed; raw
  16-bit words are kept exactly, including the `$FFFF` values whose unused CRAM
  bits the hardware ignores.
- `graphics/sprite_mappings.json`: 1,169 mappings, 3,566 pieces in 764 blocks
  across 65 source owners. Coordinates, attributes, links and static sizes are
  editable within their widths; dynamic art bindings and terminator bits are
  not.
- `graphics/sprite_animations.json`: 112 scripts with 670 fixed frame slots,
  63 of them zero-duration jumps. A frame may select only one of the 272
  symbols proved to be frame targets, a jump only a proved script, and a slot
  cannot switch between the two roles.

The tile tab shows palette indices as greys rather than guessing a palette.
The gallery tab applies the current level and graphics documents to a copy
under `build/content/gallery` and renders the selected placement; mappings
whose art binding is not known are marked as such, not filled in.

## Screen Studio

`screens/maps.json` covers eight fixed-slot LZSS RAM maps: 8,744 editable
values in 14,544 decoded bytes, recompressed into their original 4,836 bytes
of capacity. The window renders three static compositions (title, options and
story backgrounds) for both profiles, lists every consumer of a shared map and
paints on the composed screen for a chosen plane and layer. Eleven procedural
screens are listed as unsupported. See [Screen Studio](screen_studio.md).

## Text Studio

Eight reader-specific documents, all edited as glyph indices rather than
guessed Unicode text ([Text Studio](text_studio.md)):

- `text/story_rows.json`: the primary and accent story streams, paired at the
  reader's 34-byte cadence; 99 row pairs in the Japanese cartridge and 123 in
  the European one.
- `text/frontend_strings.json`: 37 title, options, continue, retry and results
  strings, 429 glyph indices in 466 bytes.
- `text/stage_messages.json`: four interstage payloads, five sequences, 38 rows.
- `text/boss_and_ship_messages.json`: the 17 command-referenced records and their
  389 glyph slots; offsets, attributes, terminators and the 418 unreferenced
  bytes are fixed.
- `text/credits_sequence.json`: 37 two-row records, 724 glyph slots and their
  delays.
- `text/glyph_source_lists.json`: the four preload lists for stage, battle,
  results and emergency messages, 57 glyph slots.
- `text/japanese_glyph_sequence.json`: the story-font stream, 987 glyph codes
  over 295 glyphs of art, with a greyscale preview of each 16x16 glyph.
- `text/results_details.json`: the results screen's detail rows and three
  summary labels.

Terminators, row positions, padding and capacities are never editable.

## Sound Studio

Four documents ([sound models](sound_models.md), [Sound Studio](sound_studio.md)):

- `sound/sequences.json`: 182 music and effect payloads, 33,062 reachable
  instructions. Notes, durations and operands may change only when the edited
  stream decodes to the same instruction graph and every selected instrument
  stays in range; offsets, widths, opcodes and jump targets are fixed.
- `sound/instruments.json`: all 901 25-byte FM instruments in those payloads.
- `sound/envelopes.json`: eight pitch and ten PSG-volume envelopes, 343
  values. Envelope 6 of each family falls through into the block after it, so
  pointer order and storage order are kept separately; a value that its reader
  would take for a command is refused.
- `sound/pcm_samples.json`: the nine DPCM banks split into 90 samples
  (253,502 bytes) through their four-byte `(start,length)` headers. Headers and
  the bytes after the last sample stay fixed. 57 samples are reachable from the
  music and voice tables, 33 are not; voice ID `$3F` is stored but the 68000
  rejects it.

The Z80 decodes each DPCM byte through two delta pages; the codec decodes all
samples to 507,004 levels and re-encodes them exactly. The playback rate is not
proved yet, so a WAV export asks for one. `make audition-sound` plays a request
through the cartridge's own driver on the saved workspace.
