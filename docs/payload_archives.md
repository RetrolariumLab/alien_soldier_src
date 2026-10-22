# Compressed payload boundaries

The preservation source includes the original bytes. Eight former payload files
contained two consecutive LZSS archives but exposed only the first archive's
name. The ranges below are now independent extracted assets and `binclude`
symbols. `tests/test_payload_archives.py` checks their headers, exact lengths,
decoded tile counts, and the pointers that use them.

| Second archive ROM address | First symbol                                | Second symbol                            | Decoded tiles |
| -------------------------- | ------------------------------------------- | ---------------------------------------- | ------------: |
| `$104F32`                  | `Stage15TileArt`                            | `Stage15TileArt2`                        |            28 |
| `$105B9E`                  | `Stage22And24TileArt`                       | `Stage22And24TileArt2`                   |           123 |
| `$123172`                  | `Boss_BackStringerTileArt`                  | `Boss_BackStringerTileArt2`              |            27 |
| `$1291DE`                  | `EntityType3F0TileArt`                      | `UnreferencedEntityType3F0TileArt2`      |           303 |
| `$138EE4`                  | `Boss_WolfGaropaTileArt1`                   | `UnreferencedWolfGaropaTileArt2`         |            75 |
| `$13D42A`                  | `Boss_ZLeoTileArt1`                         | `UnreferencedZLeoTileArt2`               |           322 |
| `$188A16`                  | `StoryScreenMappingData6000`                | `UnreferencedIntroSceneSpriteArt`        |           194 |
| `$1BE2CA`                  | `SevenForcesVictoryCutsceneMappingData4020` | `UnreferencedSevenForcesCutsceneTileArt` |            44 |

The first six second archives are in `data/artcomp/`; the last two follow
mapping payloads in `data/mappings/`. Their tile counts come from decoding the
individual second archives, not from their filenames. `Unreferenced` means no
even-aligned absolute pointer to the archive start was found in the canonical
ROM; it does not prove runtime inaccessibility.

Three compact load commands formerly formed a second-archive address by adding
the first archive's length. They now name the archive directly:

| Command                    | Former expression              | Direct symbol               |
| -------------------------- | ------------------------------ | --------------------------- |
| `Stage7TileAssetCommands`  | `Stage15TileArt+$410`          | `Stage15TileArt2`           |
| `Stage16TileAssetCommands` | `Boss_VictorTileArt_End+$1840` | `Boss_BackStringerTileArt2` |
| `Stage18TileAssetCommands` | `Stage22And24TileArt+$A08`     | `Stage22And24TileArt2`      |

The original expression and direct symbol have exactly the same canonical
address. This fixes a source-level relocation hazard but does not establish that
it caused any observed rendering failure.

Two purported archive ends also had non-archive data after the compressed
stream. The archive at `$1BE2CA` ends at `$1BE722`; its 64-byte remainder is
`UnreferencedSevenForcesCutscenePostArtData`. The archive at `$19BF9E` ends at
`$19C492`; its 18-byte remainder is `UnreferencedPostStageTileArtSpriteMapping`.
The latter has three six-byte sprite-command-shaped records, with the final
record's high bit set. The 64-byte tail also begins with command-shaped records,
but its full purpose and visual owner remain unverified. Both retain
role-neutral names pending a reader trace. All 128 `artcomp` assets now end
exactly at the first archive's header-defined boundary. The extracted asset
count is 589.

## Stage 4 rendering report: not reproduced in controlled shifts

The parallel repacker worktree reported a missing platform before Sniper
Honeyviper after moving payloads. Its saved `build/tmp_fullshift.bin` is
byte-for-byte the same image as `alien_soldier_shifted_godmode.bin`; its code
already differs from the canonical ROM at `$05E7`, and the pinned TAS shows a
different game state by frame 600. It cannot serve as a relocation-only control
for a Stage 4 regression. This does not disprove the original visual
observation; the exact failing screenshot, frame and build are not preserved
here.

On the current preservation branch, `shift_payloads.py` was run without a debug
define. It moved 190 original compressed payloads, unchanged, first by 16 bytes
within a 2 MiB image and then by 8 KiB within a 4 MiB image. The large-shift
build also inserted 19,786 alignment bytes to keep DMA payloads inside their
`$20000`-byte blocks and updated the ROM header and checksum. Both experimental
ROMs assembled successfully.

The pinned emulator replayed each ROM and the canonical Japanese ROM with the
same movies. At 100-frame intervals through TAS frame 7000, all 70 PNGs from
each shifted ROM were byte-identical to the canonical captures. At 200-frame
intervals through longplay frame 23600, all 118 PNGs from each shifted ROM also
matched; this includes all 14 sampled frames from 21000 to 23600 around Stage 4
and the boss entrance. These were sequential runs with peak emulator memory
below 48 MiB, not a full-game runtime proof. A brief between-sample glitch or a
different repacker variant remains untested.

Stage 4's compact asset list selects indices 0 and 8 in
`Stage_SharedTileSourceTable`. The two table pointers and the Sniper Honeyviper
tile-art bytes relocate in the saved shifted images; none of those sources is
simply omitted. The three corrected interior pointers above do not belong to
Stage 4. If the platform is still missing in another build, the next input
needed is that exact ROM plus its movie/frame or screenshot; then the first
divergent VRAM or tilemap transfer can be traced against this controlled
baseline. We do not attribute the non-reproduction specifically to the archive
split without that before/after control.
