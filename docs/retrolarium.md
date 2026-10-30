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

An edited payload keeps its size: compressed art is packed again into its slot,
and a song keeps every instruction where it was.

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

## Checking the repository

`make studio-check` runs `rltool studio check alien_soldier.rlj`. In a throwaway
copy of the repository it prepares each revision, validates each document and
rebuilds the ROM with no edits, requiring it byte for byte. It needs both ROMs
and the Retrolarium kit (`rltool` on `PATH`, or `RLTOOL=...`), and never reads
or writes `.retrolarium/`.
