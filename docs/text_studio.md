# Text Studio

Text Studio edits eight text formats, each through a model of the reader that
consumes it. Values are glyph indices: no Unicode character is guessed from the
artwork. A reviewed character map can be added (see below), and without one
every field is still editable by ID, with the source art of the selected glyph
shown beside it.

```text
make text-studio CONTENT_PROFILE=jp
```

## The formats

**Story rows** (`text/story_rows.json`). `StoryText_UpdateScroll` advances the
primary and accent streams together by `$22` bytes, so the document keeps them
as paired 34-byte rows; every row keeps its final `$FF` and each stream its
final `$FE`. The Japanese cartridge has 99 pairs, the European one 123. Both
rows go through `Text_QueueDoubleHeightStringWrapped`, which turns a glyph byte
into two tiles of the shared font (not the separate Japanese story font). Accent
rows contain internal `$FF` run boundaries (the Japanese path queues one run,
the European path can queue a second); their positions are protected. Glyph IDs
are limited to the 228 complete records of the shared font.

**Frontend strings** (`text/frontend_strings.json`). 37 named `Text_*` strings
of the title, options, continue, retry and results screens: 429 glyph indices in
466 bytes, each string with its fixed `$FF`. Two adjacent numeric placeholder
aliases without terminators of their own are left out. Edits rewrite only the
staged `src/rendering/text_and_numbers.s` and cannot move a terminator or resize
a string. The double-height reader multiplies each glyph by two to select a tile
pair, so IDs above 227 are refused.

**Stage messages** (`text/stage_messages.json`). Four payloads holding five
`$FD`-terminated sequences of 38 row-prefixed, `$FF`-terminated records in 808
bytes. `StageTransitionMessageSequence_TrainAndBugmax` holds two consecutive
sequences, not one plus trailing data; the lone final `$FF` of the
post-Flying-Neo payload is kept as padding. Row prefixes and boundaries are not
glyph data.

**Boss and ship messages** (`text/boss_and_ship_messages.json`).
`MessageScript_DispatchCommand` reads word offsets relative to each command,
`$FFFE` plus a longword as a tile DMA command and `$FFFF` as the end. A
referenced record starts with a two-byte tilemap attribute and ends at `$FF`;
its glyph bytes index the 228 64-byte records of `data/artunc/font.bin`. The
nine scripts hold 17 reachable records and 389 glyph slots. 418 of their 910
bytes are not addressed by any command; they may look like text but are kept
only as a protected layout hash. No ordinary route into these scripts is known
([unknowns](unknowns.md)).

**Credits** (`text/credits_sequence.json`). 874 bytes, 37 records, each an upper
and a lower row of delay, count and glyphs; the first negative delay ends the
stream and one extra `$FF` is padding. 724 glyph slots and the delays are
editable. `Credits_InitXiTiger` queues `Gfx_QueueLargeFontDMACommand81`, which
loads the shared font to VRAM `$6000`, so IDs up to 227 fit; ID zero is the
reader's blank slot, and every other ID is doubled to select a sprite tile.
`CreditsAndEndingTileArt` at `$4000` is the scene, not the text. Workspaces made
with the older wrong bound (`0..53`) are migrated by
`make migrate-credits-text CONTENT_PROFILE=jp` (and `eu`), which keeps every
edit and writes a `.json.pre-shared-font-v1` backup first.

**Glyph source lists** (`text/glyph_source_lists.json`). The four word-packed
lists that preload glyphs for the stage number, READY/FIGHT, time bonus and
EMERGENCY: 57 shared-font indices in 62 bytes, `$FF` boundaries and the time
bonus padding byte fixed.

**Japanese story font** (`text/japanese_glyph_sequence.json`).
`StoryFont_StreamNextGlyph` takes each big-endian word of
`data/mappings/font_japanese.bin`, subtracts `$20` and multiplies by `$80` to
index `data/artunc/font_japanese.bin`. 987 words are editable, the final `$FFFF`
is not; the art has 295 glyphs, so codes `$20..$146` are valid. Each glyph is
four 8x8 tiles: top-left, bottom-left, top-right, bottom-right.

**Results** (`text/results_details.json`). The results detail table: 31 rows of
22 bytes (651 glyph bytes, one `$FF` per row), shared by both cartridges; rows
25 to 30 are zero-filled. Plus the three summary labels used by
`Results_BuildSummaryRows`: 66 glyph bytes packed eleven words to a label, the
builder copying exactly 22 bytes from each. The time and clear labels keep
one-byte `$FF` terminators, the continue label a final `dc.w $FFFF`.

All eight validators also keep the JSON types of source metadata (a float or
boolean may not replace a count or offset) and refuse duplicate or malformed
record names, so two copies of a stream cannot compete for one payload.

## The window

Choose an artifact, a record and field, and a slot. The window shows raw
hexadecimal indices, their bounds and up to 32 values around the selected one;
**Previous**, **Next** and **Go** reach every slot. For shared-font formats it
shows the two source tiles of the selected glyph; for story rows it also lays
out the 33 slots of the primary and accent rows as two double-height strips,
where clicking a cell selects its byte. Japanese story-font codes show their
16x16 arrangement. These are greyscale source pixels, not an emulator frame.

**Choose glyph...** opens a page of 64 source-art entries; clicking one replaces
the selected slot through the same validation as typing a number. Delays and
protected boundaries cannot be picked.

Save, Reload, Build and Close follow
[the common Studio actions](workstation_actions.md).

## Character maps

`python scripts/authoring/text_glyph_review.py` writes an offline worksheet,
`reference/text_glyph_review_shared_font.html`, showing all 228 shared-font
records, the 295 Japanese story-font records and the credits IDs. A reviewer
marks each glyph with a transcription and its evidence (visual, in-game, source,
or unknown/unused) and downloads a JSON answer file; `--validate-answers PATH`
checks it against the current art.

**Import glyph answers** (or
`text_character_map.py import --profile jp --answers PATH`) turns those answers
into `content/workspace/<profile>/text/character_map.json`, bound to the profile
and to each font's hash. Unknown and empty entries do not become characters.
Each profile is imported separately, an existing map is replaced only when
asked, and a map that no longer matches the art is refused on load.

With a map, the **Fixed-field text** entry edits the selected field as text:
reviewed characters, plus explicit tokens such as `[[$023]]` for everything
else. A run that could be several glyphs or segmentations is refused; type the
IDs instead. Nothing is normalized, trimmed or padded, and credits ID zero is
never a typed space. The edited field must keep its exact slot count and every
protected `$FF`, and the full document validator runs before the change is
accepted.

## Checks

`make check-text-workspace` round-trips both workspaces unchanged, and
`make check-text-studio` makes a bounded edit and staged write for all eight
formats in both profiles without a window. The widget tests open hidden Tk
windows.
