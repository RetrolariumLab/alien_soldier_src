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

- Levels: each stage slot's objects (spawn lists), their 32×32 blocks and the
  stage records, with playtest from any stage through the password screen;
- Tiles: the compressed (LZSS and the tile codec) and plain art, painted in the
  stage's palettes;
- Metatiles: the 32×32 blocks, their 8×8 chunks and the plane maps;
- Palettes, with the stage or screen that uses them as a preview;
- Animations: every sprite frame and the scripts that play them;
- Screens: the title, options and story screens;
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

## Checking the repository

`make studio-check` runs `rltool studio check alien_soldier.rlj`. In a throwaway
copy of the repository it prepares each revision, validates each document and
rebuilds the ROM with no edits, requiring it byte for byte. It needs both ROMs
and the Retrolarium kit (`rltool` on `PATH`, or `RLTOOL=...`), and never reads
or writes `.retrolarium/`.
