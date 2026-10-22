# Runtime verification

`config/runtime_scenarios.json` defines twelve checkpoints across three pinned
movies, replayed under the pinned emulator commit. Screenshots are retained only
as diagnostic evidence; pass or fail is decided by named RAM assertions, each
resolved through `src/ram_addrs.inc`.

## The movies

Every movie is pinned by SHA-256 and checked before any replay starts.

| ID         | File                                       | What it reaches                                               |
| ---------- | ------------------------------------------ | ------------------------------------------------------------- |
| `tas`      | `movies/dammit,truncated-aliensoldier.gmv` | Boot, the title screen, every stage, and the ending sequence  |
| `longplay` | `movies/alien_soldier_j_longplay.gmv`      | The options screen and the weapon setup screen before Stage 1 |
| `menus`    | `movies/alien_soldier_j_menus.gmv`         | The story screen, the sound tests and demo playback           |

Three movies are used because one run cannot reach every screen. The
tool-assisted run never opens the options screen, and the menu tour never
finishes a stage.

## The scenarios

| Scenario           | Movie    | Frame |   Mode | What it pins                                                                       |
| ------------------ | -------- | ----: | -----: | ---------------------------------------------------------------------------------- |
| `boot`             | tas      |    20 | `0x00` | Work RAM is still cleared and the region check owns the dispatch slot              |
| `title`            | tas      |   320 | `0x14` | The title screen was entered through its initialize handler                        |
| `options_screen`   | longplay |   700 | `0x20` | The options screen per-frame handler                                               |
| `title_idle`       | longplay |   900 | `0x18` | The title screen per-frame handler, with a difficulty chosen in the options screen |
| `story_screen`     | menus    |  5000 | `0x28` | The story screen scrolling text through the shared cutscene workspace              |
| `weapon_select`    | longplay |  1400 | `0x74` | The weapon setup screen, with the menu slot tracking `WeaponSlotOffset`            |
| `gameplay_start`   | tas      |   700 | `0x10` | Stage 1, full loadout, three continues                                             |
| `boss_transition`  | tas      |   900 | `0x10` | The type-`$48` proximity object in the pool, timer running                         |
| `stage_change`     | tas      |  1920 | `0x10` | Stage 2 entered, weapon state back at its idle index                               |
| `stage_transition` | tas      |  6800 | `0x10` | The Stage 4 to 5 transition, with the stage timer parked                           |
| `demo_playback`    | menus    | 36000 | `0x10` | Attract-mode playback driving the gameplay loop from a recorded stream             |
| `credits`          | tas      | 70000 | `0x90` | The credits main loop running its staff sequence                                   |

## Why the mode values are evidence and not labels

`Sys_DispatchGameState` reads `GameModeIndex` and uses it directly as the byte
offset into `Sys_GameStateHandlers`, a `dc.l` table. A mode value therefore
names a routine, and an observed value is a statement about which routine owns
the frame:

|   Mode | Handler                               |   Mode | Handler                                    |
| -----: | ------------------------------------- | -----: | ------------------------------------------ |
| `0x00` | `Sys_CheckRegionLock`                 | `0x4C` | `UI_InitSecondaryOptionsMenu`              |
| `0x04` | `Frontend_InitializeSegaSequence`     | `0x50` | `UI_UpdateSecondaryOptionsMenu`            |
| `0x08` | `Frontend_UpdateOpeningSequence`      | `0x54` | `Results_InitializeSecondaryOptionsReturn` |
| `0x0C` | `Stage_UpdateGameplayEntry`           | `0x58` | `RetryPrompt_Initialize`                   |
| `0x10` | `Sys_GameplayMainLoop`                | `0x5C` | `RetryPrompt_Update`                       |
| `0x14` | `TitleScreen_Initialize`              | `0x60` | `Credits_InitializeScreen`                 |
| `0x18` | `TitleScreen_Update`                  | `0x64` | `Credits_UpdateFadeAndTransitionBuffers`   |
| `0x1C` | `UI_InitOptionsScreen`                | `0x68` | `Sys_TransitionToStageInit`                |
| `0x20` | `UI_UpdateOptionsScreen`              | `0x6C` | `Sys_StageTransitionUpdate`                |
| `0x24` | `StoryScreen_Initialize`              | `0x70` | `WeaponSetup_InitializeScreen`             |
| `0x28` | `StoryScreen_MainLoop`                | `0x74` | `WeaponSetup_UpdateScreen`                 |
| `0x2C` | `Results_InitializePostStageFlow`     | `0x78` | `GameOver_InitializeScreen`                |
| `0x30` | `Results_DispatchPostStageState`      | `0x7C` | `GameOver_CopyTransitionBufferAndDispatch` |
| `0x34` | `StageTransition_Initialize`          | `0x80` | `XiTigerStage_UpdateGameplayEntry`         |
| `0x38` | `StageTransition_UpdateMessageScreen` | `0x84` | `Results_InitializeFinalSummary`           |
| `0x3C` | `StageReady_Initialize`               | `0x88` | `Results_UpdateFinalSummary`               |
| `0x40` | `StageReady_Update`                   | `0x8C` | `Credits_InitXiTiger`                      |
| `0x44` | `PasswordMenu_Initialize`             | `0x90` | `Credits_MainLoop`                         |
| `0x48` | `PasswordMenu_Update`                 |        |                                            |

The sound tests are not a separate checkpoint because they run under
`UI_UpdateOptionsScreen` (`0x20`) like the rest of the options screen, so a
capture there would repeat `options_screen` rather than cover new dispatch.

Two other values carry the same kind of static backing. `StageTableIndex` is
cleared by `Game_InitializeNewSession` and advanced by `addq.w #2` per stage,
and indexes the 26-entry `Stage_InitializerOffsets` table; the checkpoints
observe it at `0x00`, `0x02` and `0x08` alongside `StageNumberBCD` values 1, 2
and 5. Object type `0x08` is the third `Entity_UpdateHandlerTable` entry,
`Player_Update`, so `PlayerObjectType == 0x0008` states that the player slot is
dispatching through the player state machine.

## Running it

`make runtime-capture` replays the scenarios and `make runtime-validate` checks
their RAM; `make runtime` builds the Japanese cartridge first and does both.
Captures go to `runtime/captures/`, which Git ignores. For each scenario only
that scenario's PNG and state dump are replaced.

Each scenario is a separate emulator run from power-on, so its cost grows with
its frame number; the twelve frame numbers add up to 124,660. The runner gives
each run a deadline sized from its frame count.

`scripts/runtime_capture_frames.lua` drives the replay. It runs the emulator
unthrottled and advances whole frames without writing to the controllers, RAM,
registers or VDP; the movie owns all input. The command-line `-turbo` option is
not used: in the pinned emulator it turns `-frameskip 0` into eight skipped
frames, and skipped frames never reach the capture hook. The emulator dumps the
state of the requested frame only, and the runner checks that the dump's header
names that frame before publishing the PNG and the state under the same
six-digit name.

Every run starts in a fresh, empty startup directory with a private `Gens.cfg`
whose patch, SRAM, state and similar directories all point inside the session.
The emulator reads its configuration from the working directory before the
command line overrides it, so running it in the repository or in its own
checkout could pick up someone else's settings. Movies are checked against their
SHA-256 before anything is replayed, and the ROM and movies are copied into the
session first. `capture_receipt.json` lists what was captured; the validator,
with `--require-receipt`, also checks that the captures came from the pinned
emulator and the canonical Japanese ROM.

## Building the pinned emulator

The runtime checks use the
[gens_automation](https://github.com/oranguthang/gens_automation) fork at the
commit pinned in `config/toolchain.json`
(`e14b92535acf85755321788634bf9179b621d8c0`). Check it out separately, for
example under `build/runtime-emulator/pinned-e14b925`, build it, and pass that
checkout as `GENS_DIR`; `make verify-runtime-toolchain` refuses a checkout at
another commit or with tracked changes.

With MSVC, the pinned project file misses `src/sound_trace.c` and three globals
link under different names. `config/gens_pinned_msvc.targets` supplies both
without touching the emulator source; pass it to MSBuild (VS 2019, toolset
`v142`, `Release|Win32`):

```text
msbuild Gens.vcxproj /p:Configuration=Release /p:Platform=Win32 /p:ForceImportAfterCppTargets=<repository>/config/gens_pinned_msvc.targets
```

## Watching it yourself

`make play MOVIE=tas` opens the emulator and plays a movie at normal speed with
sound, capturing nothing. `ROM=<image>` points it at any image, which is how a
relocated or resized build gets looked at:

```bash
make play MOVIE=tas ROM=alien_soldier_stretched_4mb.bin
make play MOVIE=longplay TURBO=1 MUTE=1 FRAMES=20000
```

`MOVIE` is `tas`, `longplay` or `menus`; `ROM` defaults to the built image;
`TURBO`, `MUTE` and `FRAMES` are off unless set. This is not a gate and proves
nothing on its own. It is here because the two limits below mean some kinds of
damage reach a person's eyes and nothing else.

## Frame-by-frame reference archive

`make reference MOVIE=tas` verifies the Japanese cartridge, then replays the
pinned movie once through `scripts/capture_reference.py` and saves a PNG and a
full `.genstate` for every frame into a new `capture-<unique>/` directory under
`reference/tas/`. Both files of a frame share its six-digit number, so a
screenshot can be paired with the work RAM, VRAM and CPU state behind it.
`REFERENCE_INTERVAL=20` keeps every twentieth frame instead, and
`REFERENCE_MAX_FRAMES` bounds the run.

The TAS runs to frame 90,000, past the end of its input, so the credits are
included; the menu tour runs to the end of its 90,860 input records; the
longplay (206,611 records) needs an explicit bound of at most 100,000. A state
dump is about 211 KB, so the full TAS archive is about 20 GB and 180,000 files:
start with a short bound. Every capture is checked as it is written (the frame
in its header, its sections, the PNG's chunks), and an earlier archive is never
overwritten. The archive is ignored by Git and is not part of the release check.

## What the replay cannot see

Two limits are worth stating, because a green `make runtime` does not cover
them.

The scenarios compare work RAM, not video memory. Corrupted graphics reach a RAM
expectation only if they later change the game's own state, and often they never
do.

More importantly, the vendored Gens does not model the VDP's 128 KiB DMA source
boundary. Its transfer loop masks the ROM source address once before the loop
and then increments it unmasked, so a transfer reads straight across a block
boundary where hardware wraps back to the start of the block. A ROM layout that
violates that constraint replays perfectly here and breaks on hardware. That is
why the constraint is checked statically by `make verify-layout` against the
assembler listing, with a ceiling of zero crossings, rather than being left to
the replay.

An expectation may only name a RAM symbol that `src/ram_addrs.inc` defines with
a literal address. The 281 context aliases in that file, which give a shared
scratch address a second name inside one subsystem, are deliberately out of
reach: the same bytes mean different things to different callers, so a value
read there would not settle which meaning applies.
