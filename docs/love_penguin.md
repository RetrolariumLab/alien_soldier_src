# Love Penguin: evidence and relocation fault

This page records what the Japanese ROM and source establish. It corrects the
earlier grouping of two adjacent but separate boss families under Sunset Sting.
The investigation originated in the parallel repacker worktree report
`unused_boss_entity_1c0.md`; no repacker feature or debug patch is required by
the preservation build.

## Ownership boundary

| Family | Entity types           | Source                                                                                             | Observed mechanism                                                                                     |
| ------ | ---------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| A      | `$1C0`, `$1C4`, `$1C8` | `src/bosses/love_penguin_core.s`, `love_penguin_attacks.s`, `love_penguin_transition_and_defeat.s` | Parent-linked body parts with radius and angle descriptors; second-form pool cleanup preserves `$1C8`. |
| B      | `$1EC`, `$1F0`, `$1F4` | `src/bosses/sunset_sting_main.s`, `sunset_sting_segments.s`, `sunset_sting_wave.s`                 | Sixteen segments and a wave; its pool cleanup preserves `$1EC`.                                        |

`Stage15_InitializeSunsetStingEncounter` loads the asset set whose entity type
is `$1EC`. TAS frame 32,124 shows its stretched appearance; frame 32,200 shows
its pre-fight flower appearance. These observations do not assign an appearance
to family A. The former mixed transition module was split at `$0427B0`; the
tables at `$04258E` and `$0426DA` belong to family A, while the following angle
helpers are shared code.

The asset record `Boss_LovePenguinAssetSet` at `$011538` contains type `$1C0`,
graphics pointer `$011542`, and palette pointer `$00C404`. No known stock loader
selects this record. A published patch replaces the Bugmax asset-set record at
`$01147C` with those three fields; the parallel worktree's
`Debug_LovePenguinPatch` reproduces that experiment. Its stage-13 password is
`2 A 4 1`. The patch's separate checksum-bypass edit at `$00036C` is not a boss
pointer. Played that way in MAME, the record draws Love Penguin: its 25 linked
parts and its body match the kit's reading of the builder byte for byte, so the
source names the family after it. The evidence does not establish that no other,
as-yet-unfound stock path could ever select the asset record.

## Hidden relocation failure

`Boss_LovePenguinBodyPartInitTable` begins at `$041568` and spans 244 bytes: 61
longwords. `Boss_LovePenguinInitBodyParts` reads each entry with `move.l (a1)+`.
The top bits indicate control data and which part field receives the low-address
portion; the next two words in a part record carry additional parameters.
Previously, 24 pointer-bearing longwords were spelled as numeric `dc.w` pairs:
five values equivalent to `$20000000+Boss_LovePenguinEarlyFormPartMapping`
(`$040D2E`) and 19 equivalent to
`$60000000+Boss_LovePenguinPartAnimationMappings` (`$041548`). The bytes at
`$040D2E` are a six-byte sprite mapping, not an unreferenced tail.

The table now uses 61 `dc.l` entries, including symbolic expressions for all 24
flagged pointers. This retains byte identity in the canonical layout but lets
the assembler move the addresses when preceding source grows. The second-form
body-part table was already written with longword symbols; two tables feeding
the same reader had disagreed in source type.

`make verify` compares bytes at the canonical positions, so it could not detect
the previous literal encoding, and the earlier static relocation check followed
assembler-owned references, so it could not see addresses hidden as numbers.
Under a layout shift, stale pointers sent the sprite renderer into unrelated
mapping data; the sprite list filled and later sprites, including shots and the
weapon overlay, disappeared. This explains the repacker experiment, not an
observed fault in the preservation ROM.

The general check is reader-first: when code advances a table with
`move.l (aN)+`, inspect whether the table is typed as longwords and whether any
of those values are addresses. A disagreement between tables consumed by the
same reader is especially strong evidence. A broad scan for values that look
like addresses is noisy: the parallel investigation found 115 candidate values
in the moving region, mostly palette/config constants. A targeted shift probe
can confirm a candidate. Pointers into the fixed `org` regions beginning at
`$82324`, `$E8000`, `$180000`, and `$1FFFFF` correctly do not shift.

## The second form never runs

Type `$1C8`, the second form, is spawned by nothing in the stock game. Put in
place of the first form's type in its asset set and brought into stage 2 in
MAME, it hangs the game in its graphics state, the frame it starts: VRAM is
never written again. `Boss_LovePenguinSecondFormLoadGraphicsState` passes
`Boss_LovePenguinSecondFormObjectInitTable` to `Object_InitGroupFromTable`,
which reads 14-byte entries (an object address, two bytes, two longwords, two
bytes; Antroid's table has that shape), but the table holds ten 10-byte entries:
an address, then `$1408 $E41C $E41C $0010` or `$1008 $F010 $F010 $0010`. Read 14
bytes at a time, it never lands on its `$FFFE` end and runs on into the code
after it. The table predates the reader's present entry format, so the form
cannot have been played in this build. It loads no art of its own either: its
`Tilemap_QueueIndexedRows` calls write name-table rows, and its sprite mapping
`Boss_LovePenguinSecondFormSpriteMapping` indexes whatever art is at its tiles.
`config/object_art.json` lists that mapping under `outlines`, so the studio
draws it as an outline, not in the first form's art.

## Remaining limits

The ROM-level identity of family A's art, any stock route selecting its asset
record, and the screen appearance of Sunset Sting's `$04309E` state have not
been demonstrated here. The source names do not depend on those claims.
