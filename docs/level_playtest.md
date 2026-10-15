# Level playtest

`make playtest-level` builds the content workspace and starts the edited ROM
at a chosen stage, without touching the preservation build:

```text
make playtest-level CONTENT_PROFILE=jp PLAYTEST_STAGE=13
make playtest-level CONTENT_PROFILE=eu PLAYTEST_STAGE=13
```

It gets there through the cartridge's own front end, driven by a Lua script
that reads named RAM:

1. if the cold boot enters the story, press and release Start once
   `StoryScreen_MainLoop`'s palette and loader guards accept it;
2. wait until `TitleScreen_Update` runs and the entry fade has finished;
3. select `PasswordMenu_Initialize` through `GameModeIndex`;
4. after the password screen's fade, write the stage's four-byte code from
   `Password_StageCodeTable` into `PasswordDigits` and select the confirm
   field;
5. press and release C, the raw controller bit 5 that
   `PasswordValidation_RenderMatch` tests;
6. let `PasswordMenu_HandleInput` set `StageTableIndex` and `DifficultyMode` and
   call `Password_InitializeSelectedStage` itself;
7. accept the default loadout, controller layout and exit page with C, waiting
   for each setup page to scroll;
8. press Start at `WeaponSetup_WaitForConfirmInput` and let the stage load;
9. report ready when gameplay mode `$10`, the requested stage index and player
   object type `$008` agree.

The launcher never writes `StageTableIndex`, `DifficultyMode`, health, weapons
or session state; the game's own initializer sets them. Mode `$48` alone does
not mean the password screen is ready, because `PasswordMenu_Activate` sets it
before resetting the cursor and its VRAM transfers span frames; waiting for
`PaletteFadeMode` and `PaletteFadeColorOffset` to reach zero keeps a late
initializer write from erasing the selection. In the pinned Gens Lua API the
button names are case-sensitive: `start` is lowercase, `C` uppercase.

Before launching, the ROM must have the profile's length and cartridge header
(apart from the checksum word), and its checksum must satisfy that region's
boot loop, so a Japanese ROM given with `--profile eu` is refused. Each launch
runs in its own session under `build/content/<profile>/level-runtime/` with a
private Gens configuration and empty patch and SRAM directories.

## Automated runs

`scripts/authoring/level_playtest.py --check` runs the same route hidden,
unthrottled and silent, and writes one result line with the observed RAM to
the `.txt` given by `--result` (inside `build/`), plus a diagnostic JSON with
the phase, PC, named RAM, button frames and the last state changes.
`--check-all` cold boots all 25 password stages in turn:

```text
python scripts/authoring/level_playtest.py --check-all --profile jp --rom build/content/jp/alien_soldier.bin --gens <Gens.exe> --result build/content/jp/level_coldboot.txt
```

It works on a private copy of the ROM, so a rebuild during the run does not
affect it, writes one report per stage and `level_coldboot_all.json` with the
results, and stops its own emulators on timeout. Every stage of both unedited
cartridges reaches gameplay in roughly a thousand frames.

## Limits

Only stages 1 to 25 have passwords; the 26th stage-table slot has no known
entry path and is refused.

Each stage has two consecutive password records, nominally for the branches
that set difficulty zero and two, but all 25 second records are identical to
the first. The comparison tries the first record first, so the second branch is
never taken, and only the `easy` path is offered.
