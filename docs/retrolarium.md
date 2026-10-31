# Editing in Retrolarium

Alien Soldier is edited in Retrolarium Studio, not by tools in this repository.
Open `alien_soldier.rlj` at the repository root in the studio and choose a
revision. It checks the ROM (`Alien Soldier (J) [!].bin` or
`Alien Soldier (E) [!].bin`, copied next to `alien_soldier.rlj` and never
committed), copies this repository into `.retrolarium/<revision>/` and keeps the
edits there: the game is rebuilt from its assembly source with the edited data,
so the studio works on its own copy. The folder is not tracked.

## What is edited

`config/game_profile.json` tells the kit how the source builds (the Z80 sound
program, then the 68000 program, and each revision's defines and checksum range)
and which screens are static; the kit reads every table from the source when a
project opens. The data comes from your ROM: the kit cuts it out by
`assets/manifest.json`, as `make split` does. The studio offers:

- Levels: one level per block set (the stages that load the same chunks and
  patterns), each stage on the part of the shared map its camera covers, with
  its objects (spawn lists), its 32×32 blocks and its stage record, and playtest
  from any stage through the password screen;
- Tiles: the compressed (LZSS and the tile codec) and plain art, painted in the
  stage's palettes;
- Metatiles: the 32×32 blocks, their 8×8 chunks and the plane maps;
- Palettes, with the stage or screen that uses them as a preview;
- Objects: every block of sprite mappings, drawn with the tiles and colours the
  game uses for it;
- Animations: the scripts that play the sprite frames, drawn the same way;
- Screens: the title, story and options-and-password screens (the two load the
  same maps and art), the ending, and the credits' twenty picture scenes;
- Text: the story, menus, stage and boss messages, credits and results;
- Sound: the songs and effects on a piano roll, with Listen (the kit plays the
  68000 driver's sequences through a YM2612 and PSG renderer; it follows the
  driver's channel state frame by frame), the FM instruments, the PSG envelopes
  and the DAC samples;
- Demo: the four attract demos, looped or recorded with a controller.

An edited payload keeps its allocated size: compressed art must fit its original
slot, and a song keeps every instruction where it was. Unchanged compressed
payloads retain their original bytes. [Authored data formats](data_formats.md)
describes each layout, its reader, the fourteen editable documents and three
derived views, and what can change without violating these constraints.

## The game's names and tables

Retrolarium keeps nothing taken from the game; this repository gives it what it
needs. `config/names.json` holds the stage names as the results screen gives
them, in English, and the characters each glyph of the shared font draws (the
Japanese story font's glyphs are shown as numbers). The studio and the kit read
it when a project opens and show the names as they are, untranslated; without it
they show numbers instead. Its `guard` list names what Retrolarium's own
repositories must never contain.

A sprite's static pieces take their tiles from whatever the game loaded into
VRAM, which the source does not tie to each mapping. `config/object_art.json`
records what play showed, by mapping block: the attribute objects drew it with
(base tile, palette line, priority), the art payloads its tiles were found in
with the VRAM address each was loaded at, and the palette commands that wrote
the colour lines its pieces use, or, where the code copies a colour table into a
line itself (the SEGA logo's `SegaScreenPalette`), that table and line as
`tables`. It was taken in MAME by starting every stage through the password
screen and logging each mapping the renderer drew, with the VRAM and colour RAM
the CPU had written. Lambda Bunny's blocks were taken the same way with stage 2
loading its asset set in place of Antroid's: the viewer it runs draws its sprite
mappings (`lambda_bunny_sprite_mappings.s`) in its own art and colours. A block
it does not list borrows the record of another block of its file; one with none
draws as outlines.

Its `spawns` list says what each placement of the stages' spawn lists draws, so
the studio's levels show the objects in their art: the list and index, the type
and parameter (which find the placement again after edits), the mapping block
and frame it first drew and the attribute it drew with. In MAME each placement
was put into a free slot of its range as `Sys_SpawnObject` does, at the stage's
start, and its first mapping logged. A placement it does not list (a few never
draw on their own) shows as a marker.

Its `outlines` list names mapping blocks the game never draws (Love Penguin's
second form hangs the game before it does, see `docs/love_penguin.md`); they
draw as outlines, never in another block's art.

## Shared boss preview composition

Boss previews in Palettes and the code-driven bosses in Objects use the same
assembled image, framed around its visible pixels rather than the bounds of
every frame in an animation. The Objects part hit areas follow that composition;
Fit can reduce a long reference image to keep it entirely visible. Palette
panels follow the framed image's width and stay beside the swatches from the
top, including palettes with only one or two rows. `config/names.json` owns the
optional `catalogs.boss_palette_previews` catalog (schema version 1), keyed by a
boss's setup symbol. Its settings affect these reference previews:

- `title` overrides its displayed label; `pose` selects a zero-based row of the
  exported pose table, otherwise a configured preview uses the neutral channels.
- `part_positions` and `part_offsets` place or shift numbered parts in pixels.
- `hidden_parts` omits redundant detached parts while retaining the source's
  part indices and the rest of the assembled boss.
- `chains` lists parts in order and an axial `direction` (`[1, 0]`, `[0, 1]`,
  `[-1, 0]` or `[0, -1]`). Parts are packed by their visible bounds from the
  root's edge. `pixel_scale` requests an integer enlargement before framing.
- `palette` optionally overrides these settings only in Palettes. `body_columns`
  keeps the leading columns of a plane body. Caterpillar uses a short body
  fragment and a nearby detached head for colour editing; Objects retains the
  entire body and its parts.

These settings do not edit pose tables, sprite mappings, the boss editor or the
ROM. Separate objects can be placed closer together for reference without
becoming connected game objects. A project without the catalog keeps the first
animation's still, with the same tight pixel framing.

The recorded Objects contexts in `config/object_art.json` are also checked
against the source-decoded boss. A capture can contain stale tile loads or
palette writes from a different encounter. Corrected contexts keep the object's
attributes and use the art loads and palette command order of its own boss; the
Objects viewer and the assembled boss then share their colours and art.

The five legacy planet/ship/star sprite grids have no verified loading context.
They are listed in `outlines`, so they no longer borrow unrelated ending art or
colours merely because those mappings share a source file. The ending planet,
bursts and debris use the ending's own asset loads and palette list. A missing
context is not evidence that a similarly sized unreferenced archive belongs to
the old grids.

## Checking the repository

`make studio-check` runs `rltool studio check alien_soldier.rlj`. In a throwaway
copy of the repository it prepares each revision, validates each document and
rebuilds the ROM with no edits, requiring it byte for byte. It needs both ROMs
and the Retrolarium kit (`rltool` on `PATH`, or `RLTOOL=...`), and never reads
or writes `.retrolarium/`.

## Reader catalogs and regression references

`config/names.json` also owns `catalogs.boss_readers` (schema version 1): the
checked setup routines, builders run as complete record chains, part traversals
and the traversal that retains extended reach. These are source symbols,
including aliases retained for older source layouts. The kit reads them from
this repository and includes the same catalog in source snapshots and temporary
builds. A missing or malformed catalog fails explicitly; it must not silently
hide bosses. Refresh older source repositories and their snapshots before
exporting with a kit that requires this catalog.

`tests/fixtures/retrolarium.json` keeps independent Kit and Studio regression
references: source labels, expected counts, poses, frame boundaries, positions
and palette observations. They were transcribed from the existing assertions,
not generated by the exporter under test. Kit executes the Python assertions;
Studio executes its C++ model checks. Python tagged values preserve tuples,
sets, byte strings and integer-keyed mappings. Each Kit case retains the
original evidence notes beside its values.

The Studio session test takes a prepared project, plus an optional explicit path
to this fixture. Without that argument it looks for the fixture in the project's
repository. An explicit fixture lets the same regression checks read an older
prepared project without modifying it. Test references are not a runtime
dependency of the editor or its build.
