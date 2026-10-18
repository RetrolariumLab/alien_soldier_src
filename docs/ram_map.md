# RAM map

`src/ram_addrs.inc` is the machine-consumed RAM inventory. It currently defines
976 observed 68000 work-RAM addresses and 28 observed Z80-RAM addresses.
The symbolic aliases preserve observed access widths and shared overlays; none
is a claim that one scene interpretation applies globally. Reviewed fields include
`GameModeIndex`, `GameSubstateIndex`, `StageTableIndex`, `Entity_ObjectPool`,
`DifficultyMode`, `MessageMode`, `SoundDisableFlags`, `StageTimeRemaining`,
`ScoreValueBCD`, `ScoreAddendBCD`, `ScoreAddendPrefixByte`,
`StagePhaseSplitTimes`, `StageCompletionTimes`, `StageResultVisits`,
`SharedSequenceState`, `SharedSequenceCursor`, `SharedSequenceTimer`,
`ContinueCreditsBCD`, `HighScoreBCD`, `PostStageEntryCountBCD`,
`DestroyedEnemyCountBCD`, `PlayerDamageBCD`,
`MessageSequenceState`, `MessageSequenceFlags`, `MessageAdvanceButtons`,
`MessageDisplayFlags`, `StageMessageCursor`,
`PendingStageBGMRequest`, `FontTileDMAVRAMAddress`,
`FontTileDMACounter`, `FontTileDMASourceOffset`, `XiTigerConfigIndex`,
`CutsceneScaleStep`, `CutsceneScaleSnapshot`, `CutsceneOffsetCenter`,
`CutsceneRowLoopLimit`, `CutsceneVerticalOffset`, `CutsceneLineOffsetTable`,
`SetupTransitionIndex`, `PlayerHealth`, `PlayerMaxHealth`,
`DisplayedPlayerHealth`, `BossHealth`, `BossMaxHealth`,
`DisplayedBossHealth`, `WeaponStateIndex`,
`WeaponSlotOffset`, `WeaponSavedSlotOffset`, `WeaponMenuRadius`,
`WeaponMenuAngle`, `WeaponStateCooldown`, `WeaponMenuAngularStep`, and
`WeaponMenuSlotOffset`, `ShootingMode`, `ControlLayoutFlags`, and
`RandomNumberState`, `DemoPlaybackActive`, `DemoPlaybackState`,
`DemoStageTableIndex`, `VBlankFrameCounter`, `PasswordDigits`, `FrameCounter`,
`PaletteEffectControl`,
`PaletteEntryLists`, `PalettePrimaryIndex`, and `PaletteSecondaryIndex`;
`VDPCommand` predates this review. All remain
subject to the evidence policy in `docs/naming.md`.

## Address spaces

| Space | Range | Access | Current evidence |
|---|---|---|---|
| 68000 work RAM | `0xFF0000-0xFFFFFF` | native 68000 | hardware fact |
| Sign-extended work RAM notation | `0xFFFF0000-0xFFFFFFFF` | assembler operands | static encoding fact |
| Z80 RAM window | `0xA00000-0xA01FFF` | 68000 via bus request | hardware fact |
| YM2612 ports | from `0xA04000` | shared sound hardware | hardware fact |

`M68K_RAM_PHYSICAL` and `M68K_RAM_END_PHYSICAL` exist specifically for ROM
header fields, which store 24-bit physical addresses. Most instructions use
the sign-extended `0xFFFFxxxx` form because that is how their absolute-short or
absolute-long operands were reconstructed.

## Reviewed shared sequence scratch fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `SharedSequenceState` | `$FFFF00EC` | The Sega and title transition dispatchers use this even word as their state-table offset. Credits reuses it for the five-state animated-glyph sequence; each owner clears it before dispatch. |
| `SharedSequenceCursor` | `$FFFF00F8` | Story text advances this longword through fixed-size row records, while the credits-glyph sequence advances it through its variable-size two-row records. |
| `SharedSequenceTimer` | `$FFFF00FC` | Story text uses the word as its row cadence; the credits-glyph parser stores record delays here and the sequence delay state counts it down. |

The names deliberately preserve their scratch/shared lifetime. Naming these
fields after only story text or credits would misdescribe the other proven
owner.

## Reviewed cutscene-projection fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `CutsceneScaleStep` | `$FFFF9F08` | Initialized to fixed-point `$1.FFFE`, accumulated while selecting symmetric source columns, and reduced by `$0.1800` during the Xi-Tiger reveal. |
| `CutsceneScaleSnapshot` | `$FFFF9F0C` | Captures the current scale step once per frame before the line-offset increment is derived. |
| `CutsceneOffsetCenter` | `$FFFF9F10` | Holds byte offset `$1E` from the line-table base; the offset builder expands left and right from that point. |
| `CutsceneRowLoopLimit` | `$FFFF9F12` | Supplies the `$B` `DBF` limit to both the row-copy and transfer-queue loops, yielding twelve projected rows. |
| `CutsceneVerticalOffset` | `$FFFF9F14` | Derived from the Xi-Tiger layer phase, added to projected line offsets, and subtracted from the marker object's Y anchor. |
| `CutsceneLineOffsetTable` | `$FFFF9F80` | The frame builder fills bounded word offsets through `$FFFF9FBF`; the Xi-Tiger VRAM-layout initializer consumes the same base. |

These names describe the observed representation rather than an assumed visual
intent. In particular, the original initializer did not decompress data: it
only established projection, raster-effect, and layout state.

## Reviewed options fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `DifficultyMode` | `$FFFFFF0E` | The first normal options handler toggles bit 1 and renders the SUPER EASY/SUPER HARD labels from this word. |
| `MessageMode` | `$FFFFFF2A` | The otherwise unreferenced message-row handler toggles this word and renders ON/OFF at the MESSAGE SWITCH screen position. |
| `SoundDisableFlags` | `$FFFFFF38` | Options handlers toggle bit 1 for BGM and bit 2 for SFX; the game-side sound wrappers test the same bits before queueing requests. |

`MessageMode` has a statically identified options-row consumer, but the route
that makes that row user-visible is not yet proven. Its runtime effect on boss
messages therefore remains an open validation item rather than a confirmed
behavioral claim.

## Reviewed stage-results fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ScoreAddendPrefixByte` | `$FFFFA005` | The packed-BCD score adder clears this byte immediately before staging its four-byte operand at the following address. No other source reference accesses it independently. |
| `ScoreAddendBCD` | `$FFFFA006` | The score adder writes `d0` here and consumes all four bytes with predecrement `ABCD` instructions. |
| `ScoreValueBCD` | `$FFFFA212` | Gameplay rewards and the result time bonus add packed-BCD values here; initialization clears it, while the HUD and results screen render all eight digits. |
| `ContinueCreditsBCD` | `$FFFFA228` | New-game setup initializes this packed-BCD word to three. Continue setup requires it to be nonzero, the hard-mode accepted path decrements its low byte with `SBCD`, and the continue screen renders it beside `CREDIT`. |
| `HighScoreBCD` | `$FFFFFF2C` | Boot initializes this packed-BCD longword to 100000. The results summary replaces it when `ScoreValueBCD` is greater and renders it under `HIGH SCORE`. |
| `PostStageEntryCountBCD` | `$FFFFFF40` | New-game setup clears this packed-BCD word and post-stage initialization increments it once, saturating at 9999. Its only renderer is present but unreferenced. |
| `DestroyedEnemyCountBCD` | `$FFFFFF42` | Enemy-destruction collision paths increment this packed-BCD word; the results summary renders it beside `DESTROYED ENEMIES`. |
| `PlayerDamageBCD` | `$FFFFFF44` | Hostile-contact damage adds packed-BCD units to this word, saturating at 9999; the results summary renders it beside `PLAYER DAMAGE`. |
| `StageTimeRemaining` | `$FFFFA270` | Loaded from the 25-entry packed-BCD stage time-limit table, decremented once per second, rendered by the HUD, and saved at phase/result boundaries. |
| `StagePhaseSplitTimes` | `$FFFFAA00` | `Results_StorePhaseSplitTime` stores one word selected by `StageTableIndex`; the results builder traverses 25 entries. |
| `StageCompletionTimes` | `$FFFFAA80` | `Results_StoreStageCompletionTime` stores the final per-stage timer snapshot; the results builder traverses 25 entries and derives elapsed intervals. |
| `StageResultVisits` | `$FFFFAB00` | The results transition increments the current stage entry, saturating at 999, and the summary traverses the same 25 words. |

The three history arrays are initialized together to `$FFFF`, the missing-value
sentinel. `StageResultVisits` deliberately uses the neutral word
“visit”: the ROM renders its aggregate under `TOTAL CONTINUE`, but static code
alone does not yet prove the exact player-facing counting convention.

## Reviewed pseudo-random state

| Symbol | Address | Static evidence |
|---|---:|---|
| `RandomNumberState` | `$FFFFFF08` | `RandomNumber` replaces this longword on every call, and gameplay consumers sample its bytes and words. Demo playback writes a fixed seed here so its recorded input remains deterministic. |

## Reviewed password field

| Symbol | Address | Static evidence |
|---|---:|---|
| `PasswordDigits` | `$FFFFFF3A` | Boot initializes the four bytes to one. The title-menu editor changes and clamps each byte from one through `$0A`, validates the longword against `Password_StageCodeTable`, and the Continue display stores the selected stage code back into the same field. |
| `PasswordStageTensGlyph` | `$FFFF9906` | A successful validation writes the one-based stage number's high packed-BCD digit into this primary confirmation-row position. |
| `PasswordStageOnesGlyph` | `$FFFF9907` | The corresponding low packed-BCD digit occupies the following confirmation-row byte. |
| `PasswordSecondaryBuffer` | `$FFFF9980` | The password menu clears and fills this terminated buffer for its secondary text row; the continue screen reuses it for the selected four-character password before rendering. |

## Reviewed demo-playback fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `DemoPlaybackActive` | `$FFFFFF5A` | The title timer sets this word at frame `$700`; `Demo_PlaybackSystem` gates all initialization and updates on it and clears it when returning to title mode. |
| `DemoPlaybackState` | `$FFFFFF5C` | The title trigger clears this word; demo playback treats zero as initialization and advances it by four before using the continuing playback path. |
| `DemoStageTableIndex` | `$FFFFFF64` | Demo initialization stores an entry from `Demo_StageIndexTable` here, and title confirmation copies it to `StageTableIndex` before gameplay starts. |

## Reviewed message-sequence fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `MessageSequenceFlags` | `$FFFF80A8` | Bit zero prevents the dispatcher from mirroring controller direction state during the ship-name path. `ShipName_StartScript` sets it; `BossMessage_Start` clears it. |
| `MessageSequenceState` | `$FFFF80C2` | The central dispatcher uses this even word directly as an offset into its handler table. Stage, result, boss, and ship-cutscene callers publish a starting state here and wait for it to return to zero. |
| `MessageAdvanceButtons` | `$FFFF8310` | The dispatcher stores the controller byte masked with `$70`; the glyph-delay state advances immediately when the result is nonzero. |
| `MessageDisplayFlags` | `$FFFFFF31` | Message-script entry sets bit 7 and finalization clears it. The signed HUD path suppresses its update while that bit is set; initialization clears the whole byte. |
| `MessageGlyphTileBuffer` | `$FFFFA300` | Both message glyph paths write exactly sixteen longwords, staging one 64-byte 8x8 4bpp tile before queuing its DMA transfer. |
| `MessageWorkWord0` | `$FFFF80C4` | Shared physical slot: glyph loaders use `MessageGlyphVRAMCursor`, results use `ResultsTimeBonusX0`/`LinearSpriteX`, and the wait state uses `MessageWaitTimer`. |
| `MessageWorkWord1` | `$FFFF80C6` | Shared physical slot for `BattleBannerTimer`, `MessageGlyphDelay`, `MessageTileChunkIndex`, `StageIntroBannerX`, and the result/radial angle aliases. |
| `MessageWorkLong0` | `$FFFF80C8` | Shared physical slot for `MessageScriptCursor`, `BattleBannerVelocity`, `StageIntroSoundRequest`, and result or generic hold timers. |
| `MessageWorkWord2` | `$FFFF80CC` | Encoded glyphs use `MessageTilemapVRAMPos`; radial result rendering reuses it through the vertical-center aliases. |
| `MessageWorkLong1` | `$FFFF80CE` | Shared source pointer, READY/FIGHT delay or motion offset, stage-intro delay, script-end timer, and radial radius storage. |
| `MessageWorkWord3` | `$FFFF80D2` | `MessageGlyphTileWord` starts at `$86A0` plus decoded priority bits and advances by two after each emitted glyph. |
| `MessageWorkWord4` | `$FFFF80D4` | Encoded tilemap attributes, stage-intro banner timer, and result/radial sprite Y occupy this slot in mutually exclusive states. |
| `MessageWorkWord5` | `$FFFF80D6` | Results use `ResultsTimeBonusX1`; glyph setup also writes `$000C`, but no source path reads that value before overwrite. |

The numbered names identify the contiguous physical workspace rather than
pretending that one state owns it permanently. Code uses the contextual aliases
where the lifetime is proven. `StageEntrySoundRequestByStage` and
`StageIntroSoundRequestByStage` both publish values consumed directly by
`Sound_QueueSFXRequest`; their former display-value and message-start-state names were
therefore corrected.

## Reviewed interstage-transition fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `StageMessageCursor` | `$FFFFA22C` | Stage and boss transition handlers assign one of four message-sequence addresses. The interstage message updater queues the current record, advances this cursor, and clears it at the `$FD` terminator. |
| `PendingStageBGMRequest` | `$FFFFA230` | Visual-asset dispatch clears this byte, selected transitions store sound request IDs, and both interstage setup paths submit it through `Sound_QueueBGMOrStop` when nonzero. |
| `FontTileDMAVRAMAddress` | `$FFFF8146` | The dormant interstage graphics setup initializes this destination to `$6000`; `Gfx_QueueNextFontTileDMA` encodes it into the VDP command and advances it by `$400`. |
| `FontTileDMACounter` | `$FFFF8148` | Initialized to 15 by the dormant setup, tested for negative completion, and decremented after each queued font tile. |
| `FontTileDMASourceOffset` | `$FFFF814A` | Added to `tiles_font` to form the DMA source and advanced by `$400` after each queued tile. |

## Reviewed health fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `PlayerHealth` | `$FFFFA216` | Player-damage paths subtract from this word and clamp it at zero or one according to their invulnerability rules. Pickups restore it up to `PlayerMaxHealth`, while gameplay initialization and the HUD copy or render it. |
| `PlayerMaxHealth` | `$FFFFA218` | New-game initialization sets this and `PlayerHealth` to `$200`; pickups cap health against it, stage 25 can increase it to `$400`, and both HUD presentations use it as the maximum. |
| `DisplayedPlayerHealth` | `$FFFF820A` | Gameplay and Xi-Tiger initialization copy `PlayerHealth` here. The HUD approaches the current value in small steps before rendering the visible health bar. |
| `BossHealth` | `$FFFF8200` | Boss setup routines initialize it, combat collision paths subtract damage and clear it at defeat, and boss state machines use it for health thresholds. |
| `BossMaxHealth` | `$FFFF8202` | Boss setup initializes this alongside `BossHealth`; collision defeat paths clear both, and the alternate HUD presentation renders it as the reference maximum. |
| `DisplayedBossHealth` | `$FFFF8206` | Stage and Xi-Tiger setup copy or initialize boss health here. The boss HUD approaches `BossHealth` in `$100` steps before rendering it. |
| `BossCombatCounter` | `$FFFF8234` | Boss setup loads the stage-specific default, boss state machines adjust the current value, and the HUD clamps it against `BossCombatCounterMax`. |
| `BossCombatCounterMax` | `$FFFF8236` | Setup initializes this from the same table entry as the mutable counter; the HUD retains it as the paired upper bound. |
| `BossCounterMaxFlag` | `$FFFF8260` | The HUD clears this bit before clamping `BossCombatCounter`, sets it when the counter reaches its maximum, and boss transition states wait for that event. |

These names describe the stable cross-subsystem role of the words, not a
particular boss or cutscene. The Xi-Tiger transition reuses the same health
fields to seed its displayed state.

## Reviewed setup and transition selector fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `SetupTransitionIndex` | `$FFFFA29C` | The weapon-setup updater uses even values as offsets into its seven-entry page/state table. The later transition dispatcher reuses values `0`, `2`, and `4` to select Xi-Tiger, the Z-Leo ending scene, or the shared ending sequence. |
| `XiTigerConfigIndex` | `$FFFF814C` | The Xi-Tiger cutscene initializer writes zero, and stage initialization uses the word as an offset into the adjacent Xi-Tiger configuration table. Only the zero entry and zero writer are currently present in source. |
| `GameplayExitMode` | `$FFFF8230` | Palette-fade completion maps zero, one, three, and the remaining nonzero values to distinct gameplay exits; stage, defeat, and ending paths publish those values before requesting the fade. |
| `StagePlaneAEntryMode` | `$FFFF80AA` | Stage configuration supplies zero, four, eight, or high-bit-marked eight; gameplay entry selects constant fill, direct row streaming, or mirrored Plane A streaming from that value. |
| `StagePlaneBEntryMode` | `$FFFF80AC` | Stage configuration supplies zero, four, or eight; gameplay entry uses it to select constant fill or one of the Plane B row-stream parameter sets. |
| `SceneSequenceFlags` | `$FFFFA958` | Scene-local objects publish milestone bits and their coordinating stage/cutscene states test and clear them. Bit zero is a common handshake; asteroid transitions additionally publish `$40` and `$80`. |
| `StageSceneWorkLong0` | `$FFFFA960` | Physical stage workspace reused as `GustheadArenaVelocity`, `AsteroidFieldVelocity`, `MissirayParallaxSpeed`, `MidgameVerticalPhase`, and `SevenForcesTimer`. |
| `StageSceneWorkWord1` / `Stage9FlyCorridorY` | `$FFFFA962` | Stage 8 and Seven Forces use the first word as a delay or closing span; Stage 9 instead stores a 16.16 corridor coordinate beginning here. |
| `StageSceneWorkLong1` | `$FFFFA964` | `AsteroidFieldPosition` and `FlyingNeoYVelocity` are exclusive users; its first word is overlapped by the Stage 9 coordinate beginning at `$FFFFA962`. |
| `StageSceneWorkWord2` | `$FFFFA968` | Asteroid scrolling uses `AsteroidBoundaryPhase`; Gusthead uses `GustheadFinalPhaseFlag`. |
| `TransitionEdgeSpan` | `$FFFF80A0` | Standard, alternate, and tunnel transitions initialize this 16.16 numerator to `$00018000`; edge builders divide it by transition progress, while the standard effect contracts it by `$3C0` per update. |
| `TransitionModeOffset` | `$FFFF807A` | This even byte offset selects corresponding entries in both transition raster-configuration and output-buffer dispatch tables; observed publishers choose modes zero, one, or four with values zero, two, or eight. |
| `TransitionProgress` (`GameOverLandscapeAngle` overlay) | `$FFFF807C` | Transition effects advance this word toward `$7F` and use it for interpolation, palette, and mask phases; the mutually exclusive Game Over landscape uses the same storage as its lookup-table angle offset. |
| `TransitionOriginXY` (`GameOverLandscapeDepth` overlay) | `$FFFF807E` | Transition objects publish their high-word X and Y positions as a packed pair for buffer construction; Game Over reuses the first word as the perspective depth divisor. |
| `TransitionMaskStep` (`GameOverViewOffset` overlay) | `$FFFF8082` | Transition setup clears this mask step and the tunnel effect derives it from progress; Game Over reuses the word as the signed view offset added to its perspective accumulator. |
| `SharedSceneControl` (`PasswordCursorMoveFlag`, `StageEventTimer`, `PaletteTestSelector` overlays) | `$FFFF806E` | Password navigation uses this word as a cursor-motion gate, Stage 9/12/13 use it as encounter or exit countdowns, and an unreferenced controller routine uses it as a packed palette target/value selector. |

`SetupTransitionIndex` is deliberately named for both observed lifetimes. A
narrow weapon-page or cutscene-route name would be false because the same RAM
word is reused after the setup screen. Nonzero `XiTigerConfigIndex` values and
their runtime reachability remain unproven.

## Reviewed weapon-state and selection fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `WeaponStateIndex` | `$FFFFA21C` | This even word directly indexes `Weapon_StateHandlerOffsets`; values `$12` and `$14` enter the four-slot selection-overlay initializer and updater. |
| `WeaponSlotOffset` | `$FFFFA24E` | Values `0`, `2`, `4`, and `6` select the active weapon record at `$FFFFA250`. |
| `WeaponSavedSlotOffset` | `$FFFFA220` | The special-state transition saves and restores this slot before recovering the active weapon record. |
| `WeaponMenuRadius` | `$FFFF8030` | Selection initialization sets `$A0`; the open-state update contracts it to `$20` before accepting input. |
| `WeaponMenuAngle` | `$FFFF8036` | The updater compares this angle with `WeaponSelect_TargetAngles` and advances it by the signed angular step. |
| `WeaponStateCooldown` | `$FFFF8038` | The shared updater decrements this field; the selection close path sets it to eight before committing the transition. |
| `WeaponMenuAngularStep` | `$FFFF803A` | Rotation input writes `+$10` or `-$10`, which the angle updater consumes. |
| `WeaponMenuSlotOffset` | `$FFFF803C` | Directional input maps to one of four slot offsets; the commit helper copies it to `WeaponSlotOffset`. |

## Reviewed weapon-setup fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ShootingMode` | `$FFFFA22A` | The setup screen selects and highlights the encoded `MOVING`/`FIX` options from this zero-or-two word. Player rendering and every weapon-fire family branch on the same value. |
| `ControlLayoutFlags` | `$FFFFFF30` | The setup screen maps this stored byte through a 26-entry controller-layout table and displays the matching `TYPE 1`--`TYPE 26` string. HUD/input-prompt code tests its bits, while demo playback saves and restores it. |

## Reviewed sprite OAM pipeline fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `SpriteOAMEntryCount` | `$FFFFBE00` | Every OAM renderer loads and advances this byte as the generated-entry count; the hard limit is 80 Genesis sprite entries. |
| `SpriteOAMFreeSlots` | `$FFFFBE01` | Finalization stores 80 minus `SpriteOAMEntryCount` here after linking the priority buckets. |
| `SpriteOAMWritePointer` | `$FFFFBE02` | Renderers load this word as the next OAM write address and store the advanced pointer after appending entries. |
| `SpritePriorityBuckets` | `$FFFFBE04` | Initialization fills 64 four-byte bucket records; renderers update their tail pointers and finalization joins the nonempty buckets into one hardware link chain. |
| `SpriteOAMBuildActive` | `$FFFFF744` | Priority-bucket initialization sets this byte while a batch is open, and finalization clears it. |
| `SpriteOAMStartCount` | `$FFFFF756` | Initialization uses this word as the starting entry count and derives the first OAM write pointer from it, substituting one when it is zero. |

## Reviewed palette, scroll, and VDP-control fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `PaletteActiveBuffer` | `$FFFFE300` | Palette loaders write the visible 64-color image here, and VBlank DMA uploads this 128-byte buffer to CRAM. |
| `PaletteShadowBuffer` | `$FFFFE380` | Palette loaders mirror the active image here; fades and palette effects use it as the stable source while changing the active buffer. |
| `HScrollBuffer` | `$FFFFE400` | Camera and effect code publish horizontal scroll words here; the VBlank DMA command targets the VRAM horizontal-scroll table at `$F000`. |
| `VScrollBuffer` | `$FFFFEC00` | Camera and effect code publish vertical scroll words here; the corresponding VBlank DMA command targets VSRAM. |
| `HScrollDMASource` | `$FFFFF710` | Initialization points this longword at `HScrollBuffer`; the horizontal-scroll DMA builder encodes it as the transfer source. |
| `VScrollDMASource` | `$FFFFF714` | Initialization points this longword at `VScrollBuffer`; the vertical-scroll DMA builder encodes it as the transfer source. |
| `FrameTimingDebugFlag` | `$FFFFF746` | A debug controller chord toggles its sign bit; the gameplay loop then emits VDP timing markers between subsystem updates and runs the debug backdrop helpers. |
| `SnakeScrollAccumulators` | `$FFFFA3E0` | The Snake renderer updates exactly eight consecutive fixed-point values, two for each of four background row pairs, before selecting tile-index nibbles from their integer parts. |
| `PlaneAScrollModeFlags` | `$FFFFA95A` | Plane A buffer preparation interprets bits 0/1 as scalar-write suppression, bits 2/3 as horizontal/vertical fills, and bits 4/5 as horizontal/vertical profile copies. |
| `PlaneBScrollModeFlags` | `$FFFFA95B` | Plane B uses the same independently published bit layout before writing its horizontal and vertical buffers. |

## Reviewed object-buffer boundaries

| Name | Address | Established role |
|---|---:|---|
| `ObjectBufferSecondHalf` | `$FFFFA600` | The full clear spans 1024 bytes from `$FFFFA400`; the paired 512-byte helpers split that range exactly here. |
| `OrphanedObjectType` | `$FFFFA800` | Offset zero of a 96-byte object-shaped record. Initialization clears it, while the only field-population helper has no reconstructed caller and leaves this word zero. |
| `OrphanedObjectFlags` | `$FFFFA802` | The unreferenced helper copies `PlayerObjectFlags` here. |
| `OrphanedObjectSpriteMap` | `$FFFFA808` | The same helper copies `PlayerSpriteMapping` here. |
| `OrphanedObjectAnimTimer` | `$FFFFA80C` | The same helper copies `PlayerAnimationTimer` here. |
| `OrphanedObjectAttr` | `$FFFFA80E` | The same helper copies `PlayerSpriteAttributes` here. |
| `OrphanedObjectXPosition` / `OrphanedObjectXFraction` | `$FFFFA810` / `$FFFFA812` | The helper stores integer X `$0120` and zero fractional X. |
| `OrphanedObjectYPosition` / `OrphanedObjectYFraction` | `$FFFFA814` / `$FFFFA816` | The helper stores integer Y `$00F0` and zero fractional Y. |
| `OrphanedObjectXVelocity` / `OrphanedObjectYVelocity` | `$FFFFA818` / `$FFFFA81C` | The helper clears the two 32-bit fields at the standard object velocity offsets. No reader proves later motion. |

The active palette aliases use zero-padded decimal CRAM indices. Full-word
aliases name a 12-bit Genesis color; byte aliases explicitly name only the
high-byte view used by byte-oriented code.

| Symbols | Buffer positions | Static evidence |
|---|---|---|
| `PaletteActiveColorNN` for indices 01, 02, 03, 06, 08, 10, 11, 12, 14--16, 18--22, 29--34, 46, 48--52, 54, and 59--63 | Corresponding word indices in `$FFFFE300-$FFFFE37F` | Their addresses are aligned entries inside the 64-word active palette image; palette fades, frontend code, cutscenes, and bosses read or write them as Genesis colors. |
| `PaletteActiveColor17Hi`, `PaletteActiveColor41Hi`, `PaletteActiveColor56Hi`, `PaletteActiveColor58Hi` | High bytes of active colors 17, 41, 56, and 58 | These aliases expose only one byte of the corresponding active CRAM word and therefore do not claim a full-color access. |
| `PaletteShadowColorNN` for indices 01, 03, 20--22, 29, 30, 49, 50, 54, and 61--63 | Corresponding word indices in `$FFFFE380-$FFFFE3FF` | These aligned entries belong to the stable shadow palette image used as a fade source and mirrored color store. |
| `PaletteShadowPair16`, `PaletteShadowPair33`, `PaletteShadowPair41`, `PaletteShadowPair47`, and `PaletteShadowColor32Hi` | Two-color pairs beginning at indices 16, 33, 41, and 47, plus the high byte of color 32 | The access widths are retained explicitly: longword users span two adjacent CRAM colors, while the byte alias exposes only one component byte. |

The visible H-scroll table stores one Plane A word followed by one Plane B word
per scanline. Row numbers in the aliases below are decimal. Several imported
`byte_*` names are intentionally replaced by word-row names because every live
consumer uses the even address as a word-aligned destination.

| Symbols | Workspace positions | Static evidence |
|---|---|---|
| `HScrollPlaneBRow0`, `HScrollPlaneBRow2`, `HScrollPlaneBRow4`, `HScrollPlaneBRow32`, `HScrollPlaneBRow104`, `HScrollPlaneBRow112`, `HScrollPlaneBRow128` | Plane B word of the stated visible-table row | Scroll writers advance by four bytes per row; VBlank and effect code consume the interleaved Plane A/Plane B layout. |
| `HScrollPlaneARow32`, `HScrollPlaneARow72`, `HScrollPlaneARow75`, `HScrollPlaneARow96`, `HScrollPlaneARow104`, `HScrollPlaneARow112`, `HScrollPlaneARow184`, `HScrollPlaneARow200` | Plane A word of the stated visible-table row | Stage, cutscene, and boss raster builders use these aligned row anchors and preserve the four-byte row stride. |
| `HScrollAuxBuffer` | `$FFFFE800`, second half of the 2,048-byte H-scroll workspace | The Seven Forces diagnostic builds a second scroll table here; the normal 448-word H-scroll DMA begins at `HScrollBuffer`, so this name does not claim that the auxiliary half is directly displayed. |

The first half of `VScrollBuffer` mirrors the Mega Drive VSRAM column-scroll
layout: twenty screen columns, each containing a Plane A word followed by a
Plane B word. Column numbers below are decimal. Imported byte aliases at
columns 4 and at the auxiliary-half boundary are replaced according to the
word accesses made by their live consumers.

| Symbols | Workspace positions | Static evidence |
|---|---|---|
| `VScrollPlaneAColumn1`--`VScrollPlaneAColumn19`, for the represented columns | Plane A word of the stated VSRAM column | Cutscene, transition, and boss writers address same-plane values with a four-byte column stride. |
| `VScrollPlaneBColumn0`, `VScrollPlaneBColumn4`, `VScrollPlaneBColumn8`, `VScrollPlaneBColumn9`, `VScrollPlaneBColumn10` | Plane B word of the stated VSRAM column | VBlank and scroll writers address these words two bytes after their corresponding Plane A position. |
| `VScrollAuxBuffer` | `$FFFFEC50`, second half of the 160-byte V-scroll workspace | The Seven Forces diagnostic constructs a mirrored secondary table here; normal V-scroll DMA begins at `VScrollBuffer`. |
| `PaletteFadeStep` | `$FFFFF75C` | The full-screen fade engine adds this signed word to `PaletteFadeProgress`; zero means no active fade. |
| `PaletteFadeProgress` | `$FFFFF75E` | Its high byte supplies the per-channel delta, and the fade engine clamps the word at zero or `$1000`. |
| `VDPReg1Shadow` | `$FFFFF7D2` | The VDP settings loader writes this `$81xx` command word; display helpers clear or restore register 1 display-enable bit 6. |
| `VDPReg7Shadow` | `$FFFFF7DE` | The VDP settings loader writes this `$87xx` command word, and backdrop helpers restore it after diagnostic writes. |
| `PaletteFillColor` | `$FFFFFF28` | With palette DMA disabled, VBlank fills all 64 CRAM entries with this word; zero/nonzero also selects the black/white endpoint in the full-screen fade engine. |

## Reviewed palette-effect control fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `VBlankFrameCounter` | `$FFFFA280` | `Sys_UpdateTimers` increments this word on every VBlank dispatch. Frontend, cutscene, HUD, effect, and boss code use its low bits for cadence and animation; demo initialization clears it. |
| `FrameCounter` | `$FFFFA000` | Gameplay and frontend loops increment this word once per completed frame. Animation, palette, projectile, and boss code use its low bits as periodic phase selectors, while demo initialization clears it before deterministic playback. |
| `PaletteEffectControl` | `$FFFF8218` | Palette handlers consume this word as a countdown, RGB delta, or bitfield controlling selected color-cycle slots; producers set it together with an effect selector. |
| `PaletteEntryLists` | `$FFFF821A` | Stage 8 and 9 lightning flows point this longword at two consecutive counted palette-entry lists; the paired-list handler applies opposite RGB deltas to them. |
| `PalettePrimaryIndex` | `$FFFF8220` | Stage configuration writes this even selector, and the primary dispatcher uses it directly as an offset into its ten-entry handler table. |
| `PaletteSecondaryIndex` | `$FFFF8222` | Stage configuration and transition code write this even selector, and the secondary dispatcher uses it directly as an offset into its four-entry handler table. |

## Reviewed cutscene and story-title fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `StoryTitleGlyphCursor` | `$FFFF0100` | Only the story-title reveal stores and advances this longword pointer through the twelve glyph codes in `StoryTitle_LogoRevealCharacters`. |
| `CutsceneTimer` | `$FFFF0106` | Story, credits, starfield, and planet states initialize and decrement this shared word as their state timer; planet zoom also uses its low bits for update cadence. |
| `StoryTitleExpandSpan` | `$FFFF0108` | Only the story-title states initialize this word to `$21`, reduce it by four, and use it as the horizontal pixel and scroll-run span. |
| `StoryTitleGlyphsLeft` | `$FFFF010A` | Only the story-title reveal initializes this word to twelve and decrements it after each revealed `ALIENSOLDIER` glyph. |
| `CutscenePaletteStep` | `$FFFF010C` | Story-title, credits, starfield, and planet states use this shared word as the signed or indexed step supplied to their palette-update routines. |

## Reviewed cutscene grid and pattern-dissolve fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `PatternVDPCommand` | `$FFFF00C0` | Planet and frontend setups store the base VDP write command here; dissolve selection adds its chosen pattern-word offset before queuing DMA. |
| `PatternDissolveStep` | `$FFFF00C6` | Erase and reveal routines move this signed index through the 64-entry shuffled word order and test its `$40` and negative endpoints. |
| `PatternFrameMask` | `$FFFF00C8` | Pattern-step routines AND the frame counter with this value to select their update cadence. |
| `ShipPatternVDPCommand` | `$FFFF00CA` | Ship-grid setup stores the pattern VRAM command here; ship dissolve selection adds the selected word offset. |
| `ShipPatternStep` | `$FFFF00D0` | Ship erase and reveal routines move this signed index through the common dissolve order. |
| `ShipPatternFrameMask` | `$FFFF00D2` | Ship pattern-step routines AND the frame counter with this value to select their cadence. |
| `SpriteGridCenterY` | `$FFFF00D4` | The planet-object copier and frontend setups write the vertical center consumed by the generic grid renderer. |
| `SpriteGridCenterX` | `$FFFF00D6` | The planet-object copier and frontend setups write the horizontal center consumed by the generic grid renderer. |
| `SpriteGridRowLimit` | `$FFFF00D8` | The generic renderer uses this DBF limit both to center and enumerate grid rows. |
| `SpriteGridColumnLimit` | `$FFFF00DA` | The generic renderer uses this DBF limit both to center and enumerate grid columns. |
| `SpriteGridFirstTile` | `$FFFF00DC` | Setup code stores the first tile attribute here and the renderer increments it across emitted cells. |
| `ShipGridCenterY` | `$FFFF00DE` | The ship-grid renderer copies the object's vertical coordinate here before centering rows. |
| `ShipGridCenterX` | `$FFFF00E0` | The ship-grid renderer copies the object's horizontal coordinate here before centering columns. |
| `ShipGridRowLimit` | `$FFFF00E2` | The ship renderer uses this DBF limit to center and enumerate its rows. |
| `ShipGridColumnLimit` | `$FFFF00E4` | The ship renderer uses this DBF limit to center and enumerate its columns. |
| `ShipGridFirstTile` | `$FFFF00E6` | Ship-grid setup stores the first tile attribute here and the renderer increments it across emitted cells. |
| `StarRowSeparation` | `$FFFF00E8` | Expansion and collapse change this word while the updater subtracts it from the upper row and adds it to the lower row. |
| `StarRowState` | `$FFFF00EA` | The star-row dispatcher uses this even word directly as its six-entry table index. |
| `PlanetGridState` | `$FFFF00EE` | The planet-grid dispatcher uses this even word directly as its eleven-entry table index. |
| `ShipGridState` | `$FFFF00F0` | The ship-grid dispatcher uses this even word directly as its ten-entry table index. |
| `PlanetGridTimer` | `$FFFF00F2` | Planet-grid setup and hold states load and decrement this word as their frame timer. |
| `ShipGridTimer` | `$FFFF00F4` | Ship-grid delay and hold states load and decrement this word as their frame timer. |
| `StarRowTimer` | `$FFFF00FE` | Star-row delay and hold states load and decrement this word as their frame timer. |

## Reviewed story-text streaming fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `StoryTextVRAMAddress` | `$FFFF00F6` | The story row streamer advances this circular plane-A destination by `$180` and wraps it at `$5000`. |
| `StoryFontGlyphCursor` | `$FFFF0120` | The Japanese-font states initialize this pointer to `font_japanese_mappings` and advance it by one word after every glyph. |
| `StoryFontState` | `$FFFF0126` | The Japanese-font dispatcher uses this even word directly as its three-entry state-table index. |
| `StoryTextAccentCursor` | `$FFFF0172` | Story initialization and streaming advance this longword through the 99 fixed-size accent rows. |
| `StoryTextState` | `$FFFF0178` | Frontend and story initialization clear this word; `StoryText_Dispatch` uses it as its two-state table index. |
| `StoryFontScrollY` | `$FFFF0180` | The font update decrements this word once or twice per frame, and VBlank writes it to the VDP vertical-scroll data port. |
| `StoryFontNextGlyphY` | `$FFFF0182` | The glyph streamer compares this threshold with `StoryFontScrollY` and subtracts `$10` after each queued glyph. |
| `StoryFontVRAMAddress` | `$FFFF0184` | The glyph streamer advances this circular destination by `$80` and wraps from `$8000` to `$7000`. |

## Reviewed ending-starfield and planet fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `EndingScrollPhase` | `$FFFF0110` | The ending planet and credits perspective effects integrate their signed fixed-point scroll position here before deriving symmetric H/V scroll bands. |
| `EndingScrollRate` | `$FFFF0114` | Perspective states add `$80` acceleration to this longword and then add the resulting rate to `EndingScrollPhase`. |
| `PlanetZoomFrameIndex` | `$FFFF0118` | The zoom loop advances this word up to `$3E` and uses it to select fixed-size entries from `Sprite_SharedGraphicsFrameTable`. |
| `PlanetZoomAngle` | `$FFFF011A` | Planet zoom initializes this word to `$1A0`, subtracts four per frame, and passes it to the sine/cosine lookup. |
| `PlanetZoomRadius` | `$FFFF011C` | Planet zoom initializes this fixed-point radius to `$200000` and subtracts `$8000` per frame until it reaches zero. |

## Reviewed ship-sequence fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ShipPieceScriptCursor` | `$FFFF0128` | Timeline initialization points this cursor at `ShipPiece_SpawnScript`; each matching seven-word record advances it to the following ship-piece event. |
| `ShipDebrisCursor` | `$FFFF012C` | Timeline initialization points this cursor at `ShipDebris_SpawnScript`; each matching four-word record advances it to the following debris event. |
| `ShipSequenceFrame` | `$FFFF0130` | The controller increments this master timeline frame, and both spawn scripts compare their next event trigger with it. |
| `ShipSequenceState` | `$FFFF0132` | The controller uses this even word directly as the sixteen-entry `ShipSequence_TimelineStates` index. |
| `ShipVerticalPosition` | `$FFFF0134` | Scroll integration adds velocity to this signed 16.16 position and publishes its integer word to vertical-scroll bands. |
| `ShipVerticalVelocity` | `$FFFF0138` | Arrival and flash states adjust this signed 16.16 velocity before the scroll updater integrates it. |
| `ShipTileLoadTimer` | `$FFFF013C` | The five arrival tile loaders use this word for their repeated `$20`-frame spacing. |
| `ShipRowRevealProgress` | `$FFFF0140` | Eighteen consecutive words independently track the next shuffled nibble for each pattern row. |
| `ShipRevealFrame` | `$FFFF0164` | The revealer divides this incrementing frame by eight to activate up to eighteen rows progressively. |
| `ShipMainFadeStep` | `$FFFF0166` | The final state raises this main-palette fade step from `$FFF2` toward two. |
| `ShipAccentFadeStep` | `$FFFF0168` | The final state lowers this accent-palette fade step from `$000E` every fourth frame. |
| `ShipFlashState` | `$FFFF016A` | The arrival-flash dispatcher uses this even word directly as its three-entry state index. |
| `ShipFlashTimer` | `$FFFF016C` | The active and restart flash states count this word through `$40`- and `$60`-frame phases. |
| `ShipJitterState` | `$FFFF016E` | Only the statically unreferenced vertical-jitter dispatcher reads this private three-state index. |
| `ShipJitterTimer` | `$FFFF0170` | Only the statically unreferenced vertical-jitter states initialize and count down this private timer. |

## Reviewed VBlank transfer and VDP-shadow fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `SpriteOAMBuffer` | `$FFFFE000` | Sprite renderers build eight-byte hardware entries here and cap the list at 80; VBlank uploads the complete 640-byte table to VRAM `$F400`. |
| `VBlankUpdateReady` | `$FFFFF704` | Reset sets this byte before enabling interrupts; the extended VBlank path requires it, clears it around transfers/input/timer work, and restores it before returning. |
| `VDPQueueStagingBoundary` | `$FFFFF400` | Initialization resets both VDP queue cursors to this pivot; 16-byte command records grow downward, staged payload grows upward, and VBlank finishes traversal back at this address. |
| `VDPCommandQueueHead` | `$FFFFF70C` | Command producers prepend 16-byte records below the `$F400` pivot; VBlank traverses from this address back to the pivot. |
| `VDPStagingDataCursor` | `$FFFFF70E` | Graphics producers allocate payload bytes upward from `$F400`, encode this cursor as the DMA source, and advance it by the payload size. |
| `VDPTransferPending` | `$FFFFF754` | Transfer setup sets this byte, synchronous callers wait on it, and the VBlank transfer tail clears it after issuing the queued work. |
| `PaletteDMAHIntEnabled` | `$FFFFF755` | Zero selects a full-CRAM fill and suppresses register 0 horizontal interrupts; nonzero selects palette DMA and preserves the register 0 shadow. |
| `VDPReg0Shadow` | `$FFFFF7D0` | The contiguous initialization loop stores the `$80xx` register command here; HBlank/VBlank code modifies its horizontal-interrupt bit. |
| `VDPReg2Shadow` | `$FFFFF7D4` | The initialization loop stores the `$82xx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg3Shadow` | `$FFFFF7D6` | The initialization loop stores the `$83xx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg4Shadow` | `$FFFFF7D8` | The initialization loop stores the `$84xx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg5Shadow` | `$FFFFF7DA` | The initialization loop stores the `$85xx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg10Shadow` | `$FFFFF7E4` | The initialization loop stores the `$8Axx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg11Shadow` | `$FFFFF7E6` | Its scroll-mode bits select the horizontal and vertical table lengths used by VBlank DMA. |
| `VDPReg12Shadow` | `$FFFFF7E8` | The initialization loop stores the `$8Cxx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg13Shadow` | `$FFFFF7EA` | The initialization loop stores the `$8Dxx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg15Shadow` | `$FFFFF7EE` | The initialization loop stores the `$8Fxx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg16Shadow` | `$FFFFF7F0` | The initialization loop stores the `$90xx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg17Shadow` | `$FFFFF7F2` | The initialization loop stores the `$91xx` register command here and the per-frame writer sends it to the VDP. |
| `VDPReg18Shadow` | `$FFFFF7F4` | The initialization loop stores the `$92xx` register command here and the per-frame writer sends it to the VDP. |

## Reviewed visible-object list

The list at `$FFFFED00` contains 16-bit low-address pointers to active object
records. Producers append one pointer at a time; rendering and camera-motion
passes consume the resulting count.

| Symbol | Address | Static evidence |
|---|---:|---|
| `VisibleObjectList` | `$FFFFED00` | Object and projectile scanners append 16-bit record pointers here; sprite rendering and camera-relative motion iterate the same base. |
| `VisibleObjectListCursor` | `$FFFFF758` | The begin routine initializes this word to `$ED00`; each accepted object advances it by two before the count is derived. |
| `VisibleObjectCount` | `$FFFFF75A` | The finalizer computes `(cursor - $ED00) / 2`; rendering and camera-motion loops use the result as their entry count. |

## Reviewed VBlank sound scheduling

| Symbol | Address | Static evidence |
|---|---:|---|
| `SoundUpdateBusy` | `$FFFFF745` | The VBlank event handler skips a nested sound update while this byte is nonzero and brackets `Sound_UpdateThunk` by setting and clearing it. |
| `VBlankSoundRequestDelay` | `$FFFFF762` | While nonzero, the VBlank event handler decrements this word and defers processing the pending sound-request byte. |
| `VBlankPendingSound` | `$FFFFF764` | When the delay is zero, VBlank passes this byte to `Sound_QueueRequest` and clears it only after the request is accepted. |
| `PALSoundCompensationCounter` | `$FFFFFF68` | The European profile increments this word after each VBlank sound update. Every fifth PAL VBlank clears it and performs one additional update, preserving the sound driver's 60 Hz update cadence on 50 Hz hardware. The Japanese profile does not reference this word. |

## Reviewed sound-driver global state

The driver stores 48-byte playback records consecutively from `$FFF840`.
Names for sparse absolute aliases use the statically proven record family and
zero-based index; they do not claim a musical voice identity.

| Symbol | Address | Static evidence |
|---|---:|---|
| `SoundCurrentPriority` | `$FFFFF800` | Request selection compares queued priorities with this byte, updates it for the accepted request, and clears it when ordinary SFX playback stops. |
| `SoundTempoCounter` | `$FFFFF801` | Tempo processing decrements this byte and reloads it from `SoundTempoReload` on expiry. |
| `SoundTempoReload` | `$FFFFF802` | BGM headers and sequence command `$EA` install this value; each tempo expiry copies it to `SoundTempoCounter`. |
| `SoundCommunicationByte` | `$FFFFF803` | Sequence command `$E2` copies its single parameter here; no reconstructed reader proves a narrower communication endpoint. |
| `SoundFadeStepsRemaining` | `$FFFFF804` | Music fade-out initializes this byte to 40 and consumes one step every time the tick counter expires. |
| `SoundFadeTickCounter` | `$FFFFF806` | Fade-out initializes and reloads this byte to three, decrementing it between volume steps. |
| `SoundPauseState` | `$FFFFF807` | VBlank posts pause/resume values; the sound update consumes them and uses `$FF` as the stable paused state. |
| `SoundPCMEventFlag` | `$FFFFF808` | The driver clears this byte before FM processing and sets bit 7 after decoding a PCM sequence event; stopped-channel handling tests that bit. |
| `SoundSelectedRequest` | `$FFFFF809` | Priority selection stores the winning sound ID here; dispatch consumes it and restores the empty `$FF` sentinel. |
| `SoundRequestQueue` | `$FFFFF80A` | `Sound_QueueRequest` fills four consecutive request bytes and the driver priority scan consumes the same four slots. |
| `SoundChannelGroupFlags` | `$FFFFF80E` | The update loop publishes zero for BGM, `$80` for ordinary SFX, and `$40` for special SFX while shared sequence handlers run. |
| `SoundFM3SpecialMode` | `$FFFFF80F` | The FM3 special-mode command sets this byte; frequency and stopped-channel paths use it to select operator-frequency handling. |
| `SoundBGMFM3Offsets` | `$FFFFF810` | Four words hold BGM FM3 operator frequency offsets selected when `SoundChannelGroupFlags` is zero. |
| `SoundSFXFM3Offsets` | `$FFFFF818` | Four words hold the corresponding non-BGM FM3 operator offsets. |
| `SoundBGMDataPtr` | `$FFFFF820` | BGM initialization resolves this pointer from the selected header; shared LFO and instrument handlers reload it as BGM data. |
| `SoundSpecialSFXDataPtr` | `$FFFFF824` | Special-SFX loading resolves this pointer; shared instrument and channel-restoration paths use it for the dedicated records. |
| `SoundManualVolumeState` | `$FFFFF828` | Extended commands request attenuation or restoration through this byte; the volume-transition state machine consumes those states. |
| `SoundFMVolumeStep` | `$FFFFF829` | Manual or voice-DAC ducking setup stores the FM attenuation step consumed by all active BGM FM records. |
| `SoundPSGVolumeStep` | `$FFFFF82A` | The matching PSG attenuation step is applied to all active BGM PSG records. |
| `SoundVoiceDuckingState` | `$FFFFF82B` | Voice-DAC launch and Z80 status transitions advance this byte through pending, active, and released ducking states. |
| `SoundVoiceSlotToggle` | `$FFFFF82C` | Voice-DAC allocation tests, sets, or clears bit zero while choosing between the two Z80 playback slots. |
| `SoundPCMChannelRecord` | `$FFFFF840` | The main update treats this 48-byte record as the BGM PCM sequence channel before advancing to FM records. |
| `SoundBGMFMChannels` | `$FFFFF870` | This is the first of six consecutive 48-byte BGM FM records processed by update, fade, and volume-transition loops. |
| `SoundBGMFMChannel3` | `$FFFFF900` | This sparse alias is BGM FM record index three; dedicated special FM SFX marks and restores its override flags. |
| `SoundBGMPSGChannels` | `$FFFFF990` | This is the first of three consecutive 48-byte BGM PSG records initialized and processed after the FM range. |
| `SoundBGMPSGChannel2` | `$FFFFF9F0` | This sparse alias is BGM PSG record index two; the dedicated special PSG channel overrides and restores it. |
| `SoundSFXFMChannels` | `$FFFFFA20` | This is the first of three consecutive 48-byte ordinary SFX FM records. |
| `SoundSFXFMChannel1` | `$FFFFFA50` | This sparse alias is ordinary SFX FM record index one and is checked when special SFX ownership changes. |
| `SoundSFXPSGChannel2` | `$FFFFFB10` | This sparse alias is ordinary SFX PSG record index two and is checked when special PSG ownership changes. |
| `SoundSpecialSFXFM` | `$FFFFFB40` | Dedicated special-SFX loading, playback, stop, and restoration paths use this 48-byte FM record. |
| `SoundSpecialSFXPSG` | `$FFFFFB70` | The matching dedicated 48-byte PSG record is selected for negative channel types. |
| `SoundFMShadowIndexBase` | `$FFFFFBA0` | YM2612 writers add register numbers `$40-$4F` to this adjusted base to address the port-zero total-level shadows. |
| `SoundFMPort1IndexBase` | `$FFFFFBB0` | Its offset from `SoundFMShadowIndexBase` selects the parallel port-one total-level shadows. |
| `SoundFMLevelShadows` | `$FFFFFBE0` | The resulting 32-byte region stores both ports' operator total-level values and is saved across pause muting. |
| `SoundFMShadowsEnd` | `$FFFFFC00` | Pause handling uses this exclusive end address while restoring the 32-byte shadow region backward. |

## Reviewed Z80 RAM exchange fields

The 68000 accesses these bytes only while holding the Z80 bus. Slot A and B
store parallel voice-DAC records. Unknown DPCM header members remain numbered
by their verified byte order rather than receiving invented codec meanings.

| Symbol | Address | Static evidence |
|---|---:|---|
| `PauseMenuZ80SpriteData` | `$A00C00` | The pause renderer submits this fixed Z80-RAM address as one of its two sprite-data sources. |
| `Z80DriverBusy` | `$A01F2A` | YM2612 and pause paths poll this byte under bus ownership and retry while it is nonzero. |
| `Z80VoiceSlotADesc0` | `$A01F80` | Voice-slot setup copies descriptor byte zero to the first byte of slot A. |
| `Z80VoiceSlotADesc1` | `$A01F81` | Voice-slot setup copies descriptor byte one to the second byte of slot A. |
| `Z80VoiceSlotAHeader0` | `$A01F82` | Slot A receives byte zero of the four-byte DPCM sample header here. |
| `Z80VoiceSlotAHeader1` | `$A01F83` | Slot A receives byte one of the DPCM sample header here. |
| `Z80VoiceSlotAHeader2` | `$A01F84` | Slot A receives byte two of the DPCM sample header here. |
| `Z80VoiceSlotAHeader3` | `$A01F85` | Slot A receives byte three of the DPCM sample header here. |
| `Z80VoiceSlotAActive` | `$A01F86` | The 68000 writes `$80` when publishing slot A and later reads the byte to test availability. |
| `Z80VoiceSlotAFlags` | `$A01F87` | Descriptor byte five is copied here; selection compares its upper priority bits with new requests. |
| `Z80VoiceSlotBDesc0` | `$A01FA0` | Voice-slot setup copies descriptor byte zero to the first byte of slot B. |
| `Z80VoiceSlotBDesc1` | `$A01FA1` | Voice-slot setup copies descriptor byte one to the second byte of slot B. |
| `Z80VoiceSlotBHeader0` | `$A01FA2` | Slot B receives byte zero of the four-byte DPCM sample header here. |
| `Z80VoiceSlotBHeader1` | `$A01FA3` | Slot B receives byte one of the DPCM sample header here. |
| `Z80VoiceSlotBHeader2` | `$A01FA4` | Slot B receives byte two of the DPCM sample header here. |
| `Z80VoiceSlotBHeader3` | `$A01FA5` | Slot B receives byte three of the DPCM sample header here. |
| `Z80VoiceSlotBActive` | `$A01FA6` | The 68000 writes `$80` when publishing slot B and later reads the byte to test availability. |
| `Z80VoiceSlotBFlags` | `$A01FA7` | Descriptor byte five is copied here; selection compares its upper priority bits with new requests. |
| `Z80DACCommandByte2` | `$A01FE6` | Immediate PCM and voice paths copy logical descriptor byte two to this mailbox position. |
| `Z80DACCommandByte3` | `$A01FE7` | Immediate PCM and voice paths copy logical descriptor byte three to this mailbox position. |
| `Z80DACCommandByte0` | `$A01FE8` | Immediate PCM and voice paths copy logical descriptor byte zero to this mailbox position. |
| `Z80DACCommandByte1` | `$A01FE9` | Immediate PCM and voice paths copy logical descriptor byte one to this mailbox position. |
| `Z80DACPanningUpdate` | `$A01FF8` | Active DAC pan changes are written here only when the Z80 request-state byte permits the update. |
| `Z80DACPanning` | `$A01FF9` | PCM submission publishes channel panning here; resume logic reads it back for YM2612 restoration. |
| `Z80DACCommandByte6` | `$A01FFA` | Immediate requests copy descriptor byte six here; slot requests publish the fixed `$C0` control value. |
| `Z80DACCommandByte5` | `$A01FFB` | PCM and voice submissions copy logical descriptor byte five to this shared mailbox byte. |
| `Z80DACStatus` | `$A01FFC` | Selection and ducking paths read its active-slot, priority, and voice-active status bits under bus ownership. |
| `Z80DACRequestState` | `$A01FFD` | PCM writes one and voice requests write `$80`; later paths test zero/sign before replacing data or panning. |
| `Z80DACCommandByte4` | `$A01FFE` | Immediate requests copy descriptor byte four here; slot-preemption setup may instead publish `$80`. |
| `Z80VBlankActive` | `$A01FFF` | The interrupt path sets this byte after acquiring the Z80 bus and clears it before releasing the VBlank-side bus window. |

## Reviewed raster-effect control fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `HBlankRAMCode` | `$FFFFEE00` | Function-copy descriptors install raster handlers here, the level-4 interrupt vector jumps here, and disabling the effect writes the `RTE` opcode `$4E73`. The largest observed descriptor copies `$200` bytes, through `$FFFFEFFF`. |
| `RasterEffectIndex` | `$FFFFF74A` | This even word directly indexes the 23-entry raster-effect handler table. Scene and boss setup code publishes its selected table offset here. |
| `RasterEffectInitState` | `$FFFFF74E` | Every raster-effect handler tests this word as its one-time installation guard and advances it from zero to four after installing RAM code. |

## Reviewed graphics staging fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ClearedWorkBuffer512` | `$FFFFB200` | The standalone clear routine writes 32 groups of four longwords, covering exactly 512 bytes; no reconstructed static caller or other direct reference proves a narrower owner. |
| `GraphicsStagingBuffer` | `$FFFFB400` | Initialization clears the full 1 KiB region. The tile codec uses its first 128 bytes as word-sized pixel output, while LZSS-to-VRAM loading uses it as a `$400`-byte staging block. |
| `TileDecodeBufferEnd` | `$FFFFB480` | The tile decoder stops at this address, exactly 64 word-sized pixels after `GraphicsStagingBuffer`. |
| `TileDMABatchBuffer` | `$FFFFB600` | The batched tile path packs at most 16 32-byte tiles into this 512-byte half-buffer before queuing its DMA transfer. |
| `ClearedWorkBuffer192` | `$FFFFB800` | Game-buffer initialization clears 12 groups of four longwords, covering exactly 192 bytes; no other direct reference establishes its contents. |

## Reviewed data-loader state

| Symbol | Address | Static evidence |
|---|---:|---|
| `DataLoaderControl` | `$FFFFF720` | Descriptor setup stores the handler selector with bit 15 set; the dispatcher selects a loader from it, clears it at the terminator, and clients test its sign bit as the busy state. |
| `DataLoaderLength` | `$FFFFF722` | Descriptor parsing stores the transfer or decode length here; copy, DMA, and decompression handlers consume it as their remaining word or block count. |
| `DataLoaderRecordPtr` | `$FFFFF724` | Descriptor setup saves the cursor for the next record; the dispatcher reloads it before processing subsequent work. |
| `DataLoaderSourcePtr` | `$FFFFF728` | Descriptor parsing stores the source pointer here and every copy or decompression handler reloads it as the source. |
| `DataLoaderDestination` | `$FFFFF72C` | Descriptor parsing stores the target address here; RAM-copy, DMA, and decompression handlers reload it as their destination. |
| `DataLoaderCodecState` | `$FFFFF730` | Tile decoding uses the two halves as bit count and bit buffer, while LZSS loading stores its source-end pointer in the same longword; the union name avoids claiming one incompatible role. |

## Reviewed palette-transition and results fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ResultsFirstColorOffset` | `$FFFF8014` | Post-stage setup clears this word; the selected-range fade passes it through RGB-component preparation only for the first four colors. |
| `ResultsOtherColorOffset` | `$FFFF8016` | Post-stage setup initializes this word to `$FFF2`; the range helper applies it to each of the remaining three palette ranges. |
| `PaletteFadeColorOffset` | `$FFFF80F0` | The shared transition advances this signed value toward a mode-specific limit and expands it into RGB component offsets. |
| `PaletteFadeMode` | `$FFFF80F2` | Zero disables processing; the low bits select the first or second mode and the sign selects transition direction. |
| `PaletteFadeMaskStatus` | `$FFFF80F4` | The upper bits select adjusted color channels, while completion paths publish status bits zero and one in the same word. |
| `PaletteFadeControlFlags` | `$FFFF80F8` | Bits zero and one force completion of the respective modes; bit two controls second-mode frame pacing. |
| `AlternateTimeBonusSound` | `$FFFF80FA` | Selected encounter-completion paths set this byte; results uses it to request BGM `$83` instead of the normal time-bonus SFX. |

## Reviewed story and credits control fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `EndingInitWriteOnlyFlag` | `$FFFF010E` | Ending initialization writes one; no reconstructed source reads the word, so its unknown downstream purpose is not invented. |
| `ScenePaletteFadeOffset` | `$FFFF0176` | Story and credits states step this signed value between zero and `$FFF2` and pass it to the shared palette-fade helper. |
| `CreditsSceneState` | `$FFFF017C` | The credits scene dispatcher uses this even word directly as its handler-table index. |
| `CreditsClearedSceneWord` | `$FFFF017E` | Initial scene setup clears this word, and no reconstructed source reads or otherwise writes it. |
| `StoryHBlankDelayCounter` | `$FFFF0186` | The story HBlank handler initializes it to `$10` and decrements it in a private busy-wait before changing the plane base. |
| `CreditsMasterCountdown` | `$FFFF0188` | The top-level credits dispatcher decrements it every frame; state changes and music cues compare fixed milestones. |
| `CreditsSceneDataCursor` | `$FFFF018A` | It starts at `Credits_SceneDataPointers`, supplies two pointers per normal scene, and advances by eight bytes. |
| `CreditsSceneTimer` | `$FFFF018E` | Scene states reload and count it down to pace loading, display, fades, and special scenes. |
| `CreditsPaletteTarget` | `$FFFF0190` | Normal scene loads copy palette data to this RAM pointer and alternate its destination by XORing `$40`. |
| `CreditsPaletteFadeIndex` | `$FFFF0194` | The ordered palette fade clears and advances this word as a byte offset into `Credits_PaletteFadeOrder`. |

## Reviewed cutscene pattern scratch fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ShipPatternMaskBuffer` | `$FFFF0020` | Ship setup fills eight longwords here; dissolve selection updates one of the resulting sixteen mask words. |
| `PlanetPatternFillBuffer` | `$FFFF0040` | Planet reveal and erase paths repeat the selected mask word across this sixteen-word DMA source. |
| `ShipPatternFillBuffer` | `$FFFF0060` | Ship reveal and erase paths repeat the selected mask word across this sixteen-word DMA source. |
| `PlanetPatternRowBuffer` | `$FFFF0080` | The planet row composer writes sixteen words here and queues sixteen matching DMA records. |
| `ShipPatternRowBuffer` | `$FFFF00A0` | The ship row composer writes sixteen words here and queues sixteen matching DMA records. |
| `PlanetPatternWriteOnly` | `$FFFF00C4` | Several planet/frontend setup paths write `$000F`; no reconstructed source reads the word. |
| `ShipPatternWriteOnly` | `$FFFF00CE` | Both ship-grid setup paths write `$000F`; no reconstructed source reads the word. |

## Reviewed frame and RGB-adjust control fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `FrameFreezeTimer` | `$FFFF813C` | Impact/destruction paths load the timer; the gameplay loop decrements it and asserts the frame-control high bit while it remains nonnegative. |
| `FrameControlFlags` | `$FFFF813E` | The gameplay loop combines freeze and pause state here; a negative byte gates object, player, collision, palette, and message processing. |
| `VBlankFrameDivider` | `$FFFF8096` | VBlank counts this word down, then reloads it from four minus `FrameSkipLevel`; the extended handler uses value one as its early-exit boundary. |
| `PaletteRGBAdjustLevel` | `$FFFF8140` | The RGB-adjust routine converts this level to a component delta and reduces it by the configured step until zero. |
| `PaletteRGBChannelMask` | `$FFFF8142` | Bits five through seven independently enable the red, green, and blue computed deltas. |
| `PaletteRGBAdjustStep` | `$FFFF8143` | The RGB-adjust routine zero-extends this byte and subtracts it from the active level each update. |
| `PlayerModeFlags` | `$FFFF8144` | Player update uses bit one to clear the object and bits zero/two to select the two Seven Forces processing modes. |
| `PlayerDefeatPhase` | `$FFFF80E6` | Zero permits normal player processing, negative `$8000` marks the animated defeat sequence, and positive two selects the final timed defeat/exit state. |
| `GlobalSpriteFlipBits` | `$FFFF8092` | The camera/object pass cycles the four combinations from `SpriteFlipBitsTable`; projectile, pickup, and effect renderers merge bits 11/12 into their sprite attributes. |
| `GlobalSpritePriorityBit` | `$FFFF808A` | Stage configuration and scripted transitions publish zero or `$8000`; player, weapon, enemy, pickup, projectile, and effect renderers merge it into their sprite attributes. |

## Reviewed wave, HUD, and enemy-spawn fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `SharedTransitionControl` (`FrontendHoldTimer`, `WaveControlWord` overlays) | `$FFFF8100` | Frontend transition states load and count down hold durations here; the separate wave initializer and stop helper write mode values two and zero without a reconstructed reader, so neither use owns the physical word. |
| `WaveParameterIndex` | `$FFFF8102` | Wave routines use this even word to index parameter, step, and start-offset tables and move it in two-byte increments. |
| `WaveStateOffset` | `$FFFF8104` | The wave controller uses this byte offset to select a longword handler; states move it by four bytes. |
| `HUDDynamicStripTileAttr` | `$FFFF8110` | The HUD builder emits this word as the tile attribute of all six entries in the optional dynamic strip. |
| `HUDDynamicStripXOffset` | `$FFFF8112` | The HUD builder adds this signed word to the fourth OAM word, moving the six-entry vertical strip horizontally; Caterpillar and Viblack flows move or remove the strip through it. |
| `EnemySpawnDirectorState` | `$FFFF8114` | The enemy-spawn director uses this even word to select its idle, start, or timed-update handler. |
| `EnemySpawnDelayTimer` | `$FFFF8116` | The director counts down its low word and reloads it with a randomized `$20`--`$9F` delay; reset clears the containing longword. |
| `StageSpawnCountdown` | `$FFFF808C` | The object spawner decrements nonnegative values toward the normal negative state; enemy and projectile handlers reset or suppress themselves while the countdown is active. |

## Reviewed pickup and scripted-input fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `EnemySpawnClearedLongA` | `$FFFF811A` | The orphaned director-clear routine zeros this longword; no other reconstructed source access establishes its purpose. |
| `EnemySpawnClearedLongB` | `$FFFF811E` | The orphaned director-clear routine zeros this longword; no other reconstructed source access establishes its purpose. |
| `EnemySpawnClearedLongC` | `$FFFF8122` | The orphaned director-clear routine zeros this longword; no other reconstructed source access establishes its purpose. |
| `ActivePickupCountMinus1` | `$FFFF8126` | Collision-list construction starts at minus one and increments for each primary object with field-`$23` bit five; pickup creation sets that bit and enforces its cap through this value. |
| `ScriptedInputActive` | `$FFFF8138` | Script initializers set this word, completion and timeout paths clear it, and stage transitions wait for zero. |
| `ScriptedInputTimeout` | `$FFFF813A` | Script initializers load `$100` or `$200`; the per-frame scripted-input update decrements it and clears the active word after expiry. |

## Reviewed HUD, debug, and command-buffer fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ColorFadePhase` | `$FFFF80EE` | The color-fade engine steps this word downward by five or advances its low phase modulo sixteen to derive RGB deltas. |
| `BossColorEffectFlags` | `$FFFF80EC` | Combat collision and boss controllers use bits zero through three to request or gate boss hit/color effects; the color-fade engine consumes and clears the corresponding request bits. |
| `ColorFadeTriggerState` | `$FFFF8246` | Zero selects cyclic RGB deltas, a positive trigger starts one randomized-channel fade, and the resulting negative state returns the next update to the normal fade path. |
| `StageTimerFrameCounter` | `$FFFF8204` | Active gameplay reloads this byte to `$3B`; each expiry decrements the packed-BCD stage timer once. |
| `CombatPercentIndex` | `$FFFF8210` | Flagged hits copy the target damage-scale field here; the transient HUD halves it to index `CombatPercentDisplayTable`. |
| `CombatPercentTimer` | `$FFFF809A` | Successful flagged hits load `$20`; the weapon HUD decrements it while showing `CombatPercentIndex`, then parks it at minus one. |
| `MidgameLightningMode` | `$FFFF821E` | Stage 8/9 mode one suppresses the randomized lightning composite, Xi-Tiger mode two suppresses its sound, and a negative value disables the updater. |
| `DebugMenuStateOffset` | `$FFFF8226` | The debug dispatcher uses this even word as its handler-table byte offset. |
| `DebugSoundRequestId` | `$FFFF8228` | Debug controls edit and render its low byte, which the dormant handler can submit as a sound request. |
| `ResultsTimeBonusBCD` | `$FFFF822C` | Results preserves the masked stage time here and renders its four packed-BCD digits. |
| `StageNumberBCD` | `$FFFF8232` | The stage-index conversion writes a packed-BCD stage number that the message renderer splits into two digits. |
| `ContactDamageCooldown` | `$FFFF825D` | Hostile collision permits contact damage only after this signed byte expires; cutscene exit reloads `$30`. |
| `SpecialTargetCount` | `$FFFF829E` | Stage 12 initializes fifteen marked targets, defeat collision decrements only objects with flag bit six, the HUD renders the remaining count, and the Sharpssteel transition waits for zero. |
| `StageAssetCommandBuffer` | `$FFFF82A0` | The stage loader expands compact commands into terminated eight-byte load records beginning here. |
| `RasterLayoutOffset` | `$FFFF8090` | VBlank uses this even word directly as the byte offset into `RasterBuffer_LayoutOffsets`; scene, boss, and transition initializers select the required copy layout. |
| `AsteroidBoundaryFlag` | `$FFFFA96A` | The asteroid-field updater clears it each step and sets it when the accumulated scroll crosses the tested `$100` boundary; the transition state waits for that event. |
| `LowTimeWarningTimer` | `$FFFF8306` | Below time `$30`, expiry reloads `$26`, plays the warning sound, and blanks the displayed timer for that frame. |
| `WeaponIconDMABuffer` | `$FFFF8478` | VBlank submits the complete 16-byte weapon-icon VDP command block from this address. |
| `WeaponIconDMABufferEnd` | `$FFFF8488` | Weapon-icon setup predecrements from this exclusive end while constructing the command block. |

## Reviewed stage enemy tile-attribute slots

`Stage_ExpandAndSubmitTileAssetCommands` writes these seven consecutive words
from compact command indices `$00` through `$0C`. Each consumer combines the
loaded tile base with the active palette or orientation bits.

| Symbol | Address | Static consumer |
|---|---:|---|
| `SpawnedEnemyTileAttr` | `$FFFF826E` | Shared spawned-enemy setup. |
| `StandardEnemyTileAttr` | `$FFFF8270` | Standard enemy sprite setup. |
| `EnemyProjectileTileAttr` | `$FFFF8272` | Shared enemy-projectile setup. |
| `BirdEnemyTileAttr` | `$FFFF8274` | Bird-family setup. |
| `PhaseEnemyTileAttr` | `$FFFF8276` | Phase-pattern enemy setup. |
| `Stage10WaspTileAttr` | `$FFFF8278` | Stage 10 wasp setup. |
| `CirclingEnemyTileAttr` | `$FFFF827A` | Circling-enemy and Stage 9 fly setup. |

## Reviewed player targeting and health-feedback fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `StatusDisplayModeOffset` | `$FFFF820C` | The dormant status-display dispatcher uses this even word as its four-entry handler-table offset; transitions clear it. |
| `DebugResourceRefill` | `$FFFF822A` | Debug health selection `$FF` enables this word; collision update then restores maximum health and time `$5000`. |
| `WeaponFireCooldown` | `$FFFF8238` | Fire handlers require a negative value and load weapon-specific delays; weapon update counts it down. |
| `StageMotionXDelta` | `$FFFF8240` | Stage and arena controllers publish this signed 16.16 horizontal motion; physics, weapons, debris, pickups, and effects apply it as global compensation. |
| `PlayerActionStateFlags` | `$FFFF8244` | Player damage, jump, dash, shot, and teleport states set bits in this byte; camera, physics, boss, stage, weapon, and scripted-input paths test those bits as current player-action conditions. Player state initialization clears the byte. |
| `PlayerRestrictionFlags` | `$FFFF8245` | Scripted movement, boss entrances, and encounter transitions set bits that suppress selected playfield bounds, hostile collision, terrain probes, or weapon fire. Script reset clears the byte. |
| `PlayerCenterX` | `$FFFF8248` | Player update computes hitbox midpoint plus object X; targeting code consumes the result. |
| `PlayerCenterY` | `$FFFF824A` | Player update computes hitbox midpoint plus object Y; targeting code consumes the result. |
| `ForcedPositionTimer` | `$FFFF824E` | Boss-contact publishers load a duration; the forced-position player state applies the shared coordinates until its elapsed counter exceeds that value. |
| `ForcedPositionX` | `$FFFF8250` | Bugmax, Madam Barbar, Deep Strider, and Back Stringer contact paths publish an X coordinate that the player state copies directly. |
| `ForcedPositionY` | `$FFFF8252` | The same contact paths publish the corresponding object-relative Y coordinate. |
| `ForcedPositionFlags` | `$FFFF825C` | Bits zero and two request normal or immediate placement; bit one handshakes between the player state and the publishing contact object. |
| `PlayerAirMoveUsedFlags` (`PlayerAirDashUsedFlag`, `PlayerAirShotUsedFlag`) | `$FFFF8224` | The two byte flags prevent another dash or special shot while the player remains in the same airborne action lifetime; grounded, landing, and reset states clear the pair. |
| `PlayerKnockbackXVel` | `$FFFF8300` | Hostile collision records the damaging object's horizontal velocity; player knockback consumes it when nonzero and otherwise derives direction from facing. |
| `PhoenixAttackStatus` | `$FFFF8304` | The Counter Force input tail and selected dash checks publish the signed health/max difference here; Phoenix dash paths require zero, then reuse the word as the `$78`-to-zero particle/status countdown. |
| `CombatHitFlags` | `$FFFF8308` | Successful weapon collision publishes target status bits and a hit bit; Epsilon 1 consumes bits two and zero as forced-state and direction events. |
| `DashActiveWriteOnly` | `$FFFF809C` | Ordinary, Phoenix, and Seven Forces dash paths write one on active frames; no 68000 source path reads the word. |
| `StageMotionYDelta` | `$FFFF830A` | Stage 12 publishes the paired signed 16.16 vertical motion; shared physics and pickup movement consume it as global compensation. |
| `HealthDeltaDisplayValue` | `$FFFF8262` | Damage sets bit 15 and pickups leave it clear; renderers consume the sign and lower three decimal digits. |
| `TransientValueScreenX` | `$FFFF8264` | Transient-value rendering uses this as the first digit X and advances by eight; its source writer is not reconstructed. |
| `TransientValueScreenY` | `$FFFF8266` | Rendering moves this Y upward every other frame and clamps it at `$A0`. |
| `HealthDeltaDisplayTimer` | `$FFFF8268` | Damage and pickups load `$30`; it paces HUD health convergence and expires the transient value. |
| `CounterForceInputTimer` | `$FFFF826A` | The updater decrements this before testing B. A first press seeds `$10`; a second press during the next 16 update calls raises `CounterForceTriggerFlag`. |
| `CounterForceTriggerFlag` | `$FFFF826C` | Bit zero requests the terrain-specific Counter Force state and is cleared by ordinary player-state resets. |
| `SoundFadeOutDelay` | `$FFFF830E` | Scene and boss-transition writers load one or two frames; VBlank decrements the byte and queues sound control request 1, the music fade-out command, when it expires. |
| `ExplosionSoundDelay` | `$FFFF809E` | Defeat and barrage sequences load a delay; shared explosion-projectile helpers count it down before enabling their randomized explosion sound cadence. |

## Reviewed HUD DMA and debug tile buffers

Each DMA buffer is exactly 16 bytes: its producer predecrements from the
adjacent tile-buffer start, and VBlank consumes three longwords plus two words.
The weapon and boss tile regions are reused by the two debug pages.

| Symbol | Address | Static evidence |
|---|---:|---|
| `PrimaryHUDDMABuffer` | `$FFFF84A0` | Primary HUD transfer command block. |
| `PrimaryHUDTileBuffer` | `$FFFF84B0` | Player-health and score tile words. |
| `WeaponDebugDMABuffer` | `$FFFF8500` | Weapon HUD or primary-debug transfer command block. |
| `WeaponDebugTileBuffer` | `$FFFF8510` | Weapon HUD and primary-debug tile words. |
| `DebugHealthCursorTile` | `$FFFF8512` | Blinking health-selection cursor. |
| `DebugHealthHighTile` | `$FFFF851E` | Health selection high hexadecimal digit. |
| `DebugHealthLowTile` | `$FFFF8520` | Health selection low hexadecimal digit. |
| `BossClearCursorTile` | `$FFFF8522` | Blinking boss-clear cursor. |
| `PaletteEntryCursorTile` | `$FFFF8532` | Palette-entry cursor when channel edit is inactive. |
| `PalettePreviewBuffer` | `$FFFF8534` | Sixteen-word selected palette preview. |
| `ColorEditCursorTile` | `$FFFF8554` | Palette-channel cursor while color edit is active. |
| `BossDebugDMABuffer` | `$FFFF8560` | Boss HUD or secondary-debug transfer command block. |
| `BossDebugTileBuffer` | `$FFFF8570` | Boss HUD and secondary-debug tile words. |
| `DebugSoundCursorTile` | `$FFFF8572` | Blinking sound-request cursor. |
| `DebugSoundHighTile` | `$FFFF857E` | Sound request high hexadecimal digit. |
| `DebugSoundLowTile` | `$FFFF8580` | Sound request low hexadecimal digit. |
| `PaletteLineCursorTile` | `$FFFF8582` | Blinking palette-line cursor. |
| `PaletteLineNumberTile` | `$FFFF858A` | Selected palette-line digit. |
| `StageTimerTileBuffer` | `$FFFF85A8` | Stage timer portion of the boss/status tile row. |
| `DebugColorRedTile` | `$FFFF85B6` | Selected color red-component digit. |
| `DebugColorGreenTile` | `$FFFF85B8` | Selected color green-component digit. |
| `DebugColorBlueTile` | `$FFFF85BA` | Selected color blue-component digit. |

## Reviewed player input, scripted movement, and scroll fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `PlayerInputMask` | `$FFFF830F` | The input reader ANDs both held and pressed controller bytes with this mask; player states select `$7F`, dash/Phoenix states `$73`, and teleport states `$70`. |
| `PlayerDashStopFlag` | `$FFFF8311` | Player update clears this byte before state dispatch; Wolf Garopa's boundary effect sets it after pushing the player, and active dash states then terminate. |
| `ScrollPlaneBufferOffset` | `$FFFF8640` | Scroll preparation uses this word to select alternate VDP plane bases and offsets both horizontal and vertical buffer pairs; Sunset Sting sets it to two and clears it on exit. |
| `TargetReticleScanDelay` | `$FFFF8642` | Targeting update decrements the word before each scan, clears it while scanning, and reloads `$80` after a complete pass finds no eligible target. |
| `ScriptedInputStepTimer` | `$FFFF8644` | Scripted-input states load or copy this timer and count it down before advancing delayed run, input-hold, and Xi-Tiger intro steps. |
| `ScriptedInputTargetX` | `$FFFF8646` | Post-boss and Flying Neo sequences load fixed world-X destinations and compare them with the computed scripted player position. |
| `ScriptedInputDelay` | `$FFFF8648` | Post-boss runs load `$16` and copy it into the step timer; Flying Neo entry reuses the word as a direct `$0E`-tick vertical-motion delay. |
| `ScriptedPlayerWorldX` | `$FFFF8652` | The scripted-input dispatcher adds the camera X coordinate to the player's screen X every update; movement states compare this world position with their target. |

## Reviewed collision pointer lists

`Collision_BuildEntityLists` initializes every count to minus one and appends
16-bit object pointers to five adjacent `$80`-byte lists. Consumers load the
corresponding count into a `DBF` loop, so the stored values are explicitly
`count - 1` rather than ordinary counts.

| Symbol | Address | Static evidence |
|---|---:|---|
| `PrimaryListCountMinus1` | `$FFFF8D76` | Incremented for each alternating-frame primary collision entry and consumed with `PrimaryCollisionList`. |
| `TargetListCountMinus1` | `$FFFF8D78` | Incremented for entities carrying either target flag and consumed with `CollisionTargetList`. |
| `LockOnListCountMinus1` | `$FFFF8D7A` | Incremented for the lock-on subset and consumed by weapon targeting with `LockOnTargetList`. |
| `PlatformListCountMinus1` | `$FFFF8D7C` | Incremented for objects carrying the moving-platform flag and consumed with `MovingPlatformList`. |
| `WeaponListCountMinus1` | `$FFFF8D7E` | Incremented for objects carrying the player-weapon collision flag and consumed with `PlayerWeaponList`. |
| `PrimaryCollisionList` | `$FFFF8D80` | Pointer list used by player-hostile and special-attack collision scans. |
| `CollisionTargetList` | `$FFFF8E00` | Pointer list used by player-weapon, special-attack, and target-selection scans. |
| `LockOnTargetList` | `$FFFF8E80` | Subset of collision targets carrying flag bit four; targeting code scans it for lock-on objects. |
| `MovingPlatformList` | `$FFFF8F00` | Pointer list whose entries have cached previous/current positions for player-platform collision. |
| `PlayerWeaponList` | `$FFFF8F80` | Pointer list used as the weapon side of player-weapon-versus-enemy collision. |

## Reviewed sprite and scroll scratch fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `PlayerSpritePieceBuffer` | `$FFFF8780` | Player composite rendering expands primary and secondary frame streams into this buffer and publishes its address through the player object's sprite-piece pointer. |
| `HorizontalScrollProfile` | `$FFFF8800` | Stage-specific producers fill horizontal line/cell values here; the scroll writer copies this profile into alternating horizontal-scroll output words. |
| `VerticalScrollProfile` | `$FFFF8A00` | Caterpillar, Viblack, and Epsilon 1 build twenty-word profiles from this base; the vertical scroll writer copies exactly twenty consecutive words into its output column. |
| `MidgameParallaxValue0` | `$FFFF8A04` | Stage 8 subtracts `$41` from the first of four cyclic parallax values. |
| `MidgameParallaxValue1` | `$FFFF8A08` | Stage 8 subtracts a randomized value from `$08` through `$0F` from the second cyclic parallax value. |
| `MidgameParallaxValue2` | `$FFFF8A0C` | Stage 8 subtracts `$10` from the third cyclic parallax value. |
| `MidgameParallaxValue3` | `$FFFF8A10` | Stage 8 subtracts `$13` from the fourth cyclic parallax value. |

The four midgame words are stage-specific overlays inside the shared vertical
profile scratch region. The frame counter rotates their order and the producer
repeats the resulting four-word group into `HorizontalScrollProfile`.

## Reviewed encounter raster, timing, and trail fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `GameOverRasterBuffer` | `$FFFF9000` | The Game Over perspective projector writes four interleaved words per row from this base; the raster-layout copier expands fourteen 64-byte blocks into `HScrollBuffer`. |
| `SharedPatternWorkBuffer` (`TransitionPatternRow2`, `ShieldViperBranchParity` overlays) | `$FFFF9440` | Transition masking treats this address as the third 32-byte pattern row; Shield Viper separately toggles its first word between zero and one to alternate the optional post-tracking branch. |
| `SharedPatternWorkWord1` (`ResultsLayoutModeCopy` overlay) | `$FFFF9442` | Results copies and clears `ResultsExtendedLayout` here, then uses the copy to enable the controller-bit-seven frontend restart and select the extended automatic-scroll target; transition masking reuses the same bytes inside its third pattern row. |
| `SharedPatternWorkWord2` (`Epsilon1TileBandIndex` overlay) | `$FFFF9444` | Epsilon 1 seeds this word with zero, two, or four and advances it while submitting paired animated tile bands; transition masking reuses the same bytes inside its third pattern row. |
| `SharedPatternStateLong0-2` (`Epsilon1RingPhaseTable`, `ResultsStageRowBuffer`, `ShieldViperEffectStepA-C` overlays) | `$FFFF944E-$FFFF9459` | Epsilon 1 addresses a twelve-word ring phase table from the first longword; Results begins its variable-length stage rows at base plus two; Shield Viper advances three overlapping 16.16 effect steps at offsets `+$02`, `+$06`, and `+$0A`. |
| `SharedPatternStateWord0-2` (`ShieldViperEffectPhaseA-C` overlays) | `$FFFF945C-$FFFF9461` | Shield Viper accumulates and wraps three pattern range phases at `$30`; Epsilon 1 independently reaches these words through later indices of its ring phase table, while Results uses them inside its stage-row records. |
| `SharedPatternStateLong3-5` (`Epsilon1RowOffsetTable` overlay) | `$FFFF9466-$FFFF9471` | Epsilon 1 treats these three longwords as six row-offset words used by scroll-profile construction and ring-object defeat motion; Results independently overlaps the range with stage-row data. |
| `MedusaSpawnSequenceFlag` | `$FFFF9804` | The Seven Forces transition and Medusa state A set this word to one; the scripted-spawn handler runs only while it is nonzero and clears it when the current schedule terminates. |
| `Epsilon1ProximityTimer` | `$FFFF9472` | Epsilon 1 increments this word while the player remains within twelve pixels and the proximity flag is clear; difficulty selects a `$40` or `$80` threshold. |
| `Epsilon1ProximityFlag` | `$FFFF9474` | The proximity threshold sets this word; it changes attack selection and terminates ring repetitions until battle-center recovery clears it. |
| `Epsilon1VerticalAccel` | `$FFFF9478` | Epsilon 1 attack states load signed acceleration values here, and the shared motion helper adds the longword to the boss vertical velocity. |
| `SharedProfileBuffer` (`TransitionRampBuffer`, `Epsilon1AngleHistory`, `ViblackScrollSamples` overlays) | `$FFFF9480` | Transition code builds a 63-pair symmetric ramp here, Epsilon 1 shifts and samples angle history, and Viblack builds then copies its scroll samples; the modes are mutually exclusive. |
| `SharedPatternOverlay` (`GustheadMappingCounts`, `SirenePatternAltB` overlays) | `$FFFF9502` | Gusthead indexes a word counter array from this base by the selected segment mapping. Sirene independently writes the second alternate pattern patch here before its queued VDP transfer. |
| `SirenePatternNormalA`, `SirenePatternAltA`, `SirenePatternNormalB` | `$FFFF9508`, `$FFFF9510`, `$FFFF951A` | Sirene patches these words, together with `SirenePatternAltB`, after filling its alternating 32-byte battle-effect pattern; the frame parity selects the normal or alternate pair. |
| `SharedPosePatternBase` (`BackStringerPoseGroup`, `SevenForcesPatchA` overlays) | `$FFFF9608` | Back Stringer reads four strided pose bytes from this base to derive linked-part angles. The Seven Forces debug-pattern path independently patches the first primary marker here after filling its 64-byte pattern. |
| `SharedCameraPatternWord` (`ZLeoPreviousCameraY`, `SevenForcesAltPatchB` overlays) | `$FFFF9602` | Z-Leo retains the previous camera Y here to detect threshold crossings for tile-row streaming. The Seven Forces debug-pattern path independently writes its second alternate marker at the same word. |
| `ZLeoTileDMARecord` | `$FFFF9604` | Z-Leo builds a 12-byte indexed-row descriptor here with VRAM destination, source base, row count, and six tile-chunk indices before calling `Tilemap_QueueIndexedRows`. |
| `SharedScrollPatternLong` (`SevenForcesMedusaSpeed`, `SevenForcesAltPatchA`, `JokerTileWordGroupB` overlays) | `$FFFF9610` | The Seven Forces stage transition treats this as signed 16.16 Medusa camera speed and its debug path patches the first alternate marker here. Joker independently uses the second cycling tile-word group from this base. |
| `SharedPoseTileLong` (`SevenForcesPlaneASpeed` overlay) | `$FFFF9614` | Seven Forces accelerates and clamps this signed 16.16 speed for the primary Sylpheed and Sirene planes. Back Stringer reads its first byte through `BackStringerPoseGroup+12`, while Joker writes both words through `JokerTileWordGroupB+4`. |
| `SevenForcesPlaneBSpeed` | `$FFFF961C` | Seven Forces accelerates and clamps this signed 16.16 speed for the secondary Sylpheed and Sirene plane motion, clearing it at the corresponding stage-transition entries. |
| `SevenForcesPatchB-D`, `SevenForcesAltPatchC-D` | `$FFFF961A`, `$FFFF9628`, `$FFFF963A`, `$FFFF9630`, `$FFFF9622` | Frame parity selects one of two marker sets patched into the C-filled 64-byte Seven Forces debug pattern before its queued VDP transfer. The still-shared first two alternate patches remain separately tracked. |
| `SharedWordWorkspace` (`DestroyerMK2RowSpeeds`, `ShieldViperAngleDelay`, `SevenForcesFadeValue` overlays) | `$FFFF9620` | Destroyer MK2 clears and integrates a word array of scroll-row speeds, Shield Viper shifts a 65-word trailing-angle delay, and an unreferenced Seven Forces palette helper uses the first word as a clamped fade value. |
| `BossPerspectiveRows` | `$FFFF9520` | Joker and Bugmax initialize 96 descending perspective-row words here and update them for their boss-specific projections; the raster-layout copier transfers exactly three 64-byte blocks from this base. |
| `DestroyerMK2ScrollRows` | `$FFFF9820` | Destroyer MK2 clears 128 longwords from this base, treats the first 255 words as scroll-row offsets paired with `DestroyerMK2RowSpeeds`, and updates selected rows through its band descriptors. |
| `BugmaxPositionHistory` | `$FFFF95E0` | Bugmax seeds eight packed position samples, shifts a new boss X/Y pair through the history, and reads delayed endpoints for linked-chain projection. |
| `BugmaxAuxAngleHistory` | `$FFFF9680` | Bugmax shifts eight rows of eight auxiliary-chain angle samples and copies delayed row values into the secondary linked-part records. |
| `ShieldViperTrailAngles` | `$FFFF94A0` | Shield Viper initializes and shifts angle-history words from this base, then applies or interpolates them across linked body records. |
| `ShieldViperPoseHistory` | `$FFFF9700` | Shield Viper shifts 24 packed X/Y longwords in parallel with its trail angles and applies the delayed coordinates to the 24 linked body records. |
| `Epsilon1TileDMARecord` | `$FFFF9446` | The animated-tile helper builds one four-word destination/source/count/frame record here before submitting it to the indexed-column loader. |
| `FlyingNeoVScrollRamp` | `$FFFF9506` | Flying Neo's line-scroll builder writes its descending vertical ramp and camera-relative tail from this address. |
| `FlyingNeoAngleTapBase` | `$FFFF9806` | Flying Neo starts eight stride-eight word reads here; each sample supplies a delayed angular step for one linked part before sine/cosine position lookup. |
| `JetsripperAngleTapBase` | `$FFFF9808` | Jetsripper starts seventeen stride-eight word reads here; each delayed angle is combined with the segment phase before sine/cosine placement. |
| `SunsetStingWaveTable` / `SunsetStingWaveTableEnd` | `$FFFF9810-$FFFF99A0` | The wave generator writes 400 bytes backward from the exclusive end to the base; the following 25-row merge reads sixteen bytes per row across exactly the same range. |
| `SharpssteelTargetTail` | `$FFFF960A` | The attack selector loads this sixth blade-target history word into its active target field. |
| `ResultsSummaryRowBuffer` | `$FFFF9852` | Results appends the three aggregate label/value rows from this exact workspace destination. |
| `DestroyerMK2ScrollTable` | `$FFFF98B0` | Destroyer MK2 walks this word table while constructing its paired scroll-row effect. |
| `BossBackdropBandBufferA` | `$FFFF981E` | The transition builder fills 96 words with the current fixed-point backdrop displacement, repeating each of 24 samples four times. |
| `BossBackdropBandBufferB` | `$FFFF9B1E` | The paired 96-word band workspace receives bounded or fallback line values, likewise repeated four times per sample. |
| `TransitionEdgeCenter4` | `$FFFF9A80` | Mode four writes 63 mirrored sample pairs around this center, producing the contiguous transition edge range `$FFFF9A02-$FFFF9AFC`. |
| `SharedTransitionBuffer` (`TransitionEdgeCenter1`, `BossBackdropCopySource` overlays) | `$FFFF9B00` | Mode one writes 127 mirrored sample pairs around this center across `$FFFF9A02-$FFFF9BFC`; encounter-backdrop code separately copies 224 bytes forward from the same address. |
| `ShieldViperBackdropRow` | `$FFFF9B80` | The Shield Viper transition fills 64 tile words here and immediately submits this base to the VDP command builder. |
| `RasterVScrollPairBuffer` | `$FFFF9C04` | The scene-transition VBlank initializer exposes this base to the installed HBlank routine, which consumes one longword as a two-word VSRAM pair per interrupt. |
| `WeaponSetupRasterLines` | `$FFFF9C1E` | Weapon setup initializes 97 signed line offsets from this base before applying its animated dither displacement. |
| `WeaponSetupOffsetCenter` | `$FFFF9C80` | Weapon setup uses this point as the signed-index center while building two phase-dependent offset tables inside the line workspace. |
| `RasterStagingBuffer` (`FlyCorridorRasterBuffer`, `ShieldViperXferBuffer` overlays) | `$FFFF9C00` | Layout and HBlank paths use this common staging base; Stage 9 builds its fly-corridor rows here, while Shield Viper separately submits it as the rendering-transfer source. |
| `SharedLineOffsetBuffer` (`StoryTitleScrollOffsets`, `SunsetStingWaveOffsets` overlays) | `$FFFF9CE0` | The story-title expansion and Sunset Sting wave transition independently construct line-offset runs from this same base. |
| `SharedPatternBuffer` (`BackdropScrollPattern`, `ShieldViperEffectBuffer` overlays) | `$FFFF9D80` | The segmented transition uses the first eight words as a divided scroll pattern; Shield Viper separately clears and fills 96 longword effect entries from the same base. |
| `BackdropRasterSpan` | `$FFFF9D90` | The boss-backdrop raster builder uses the signed 16.16 high word as its compressed/expanded span and derives the per-line interpolation step from the full value. |
| `BackdropBandOffset` | `$FFFF9D94` | The builder derives this signed word from `BackdropPositionA` and uses it to place and index the active band windows. |
| `BackdropLinePhase` | `$FFFF9D96` | The transition initializes this 16.16 line phase and advances it by half of `BackdropVelocityB` before emitting repeated band values. |
| `BackdropVelocityA` | `$FFFF9DA2` | The segmented-transition updater clamps this 16.16 velocity, integrates it into `BackdropPositionA` and `BackdropCameraYPos`, and later decelerates it through zero. |
| `BackdropVelocityB` | `$FFFF9D9E` | The paired 16.16 velocity is clamped independently and integrated into `BackdropPositionB`, whose high word generates the divided scroll pattern. |
| `BackdropPositionA` | `$FFFF9DAA` | This 16.16 position drives the band offset and span geometry while the transition states reset or reduce it. |
| `BackdropPositionB` | `$FFFF9DA6` | This 16.16 position accumulates `BackdropVelocityB`; its high word is successively divided into the segmented scroll pattern. |
| `BackdropCameraYPos` | `$FFFF9DB2` | The updater integrates `BackdropVelocityA` into this 16.16 output and publishes it to `SecondaryCameraYPos`, with alternate-frame half-speed sampling. |
| `BossBackdropFadeLevel` | `$FFFF9DAE` | Destroyer Proto and Shield Viper transition states initialize and decrement this word; the shared palette updater applies it with opposite signs to the full and upper palette ranges. |
| `StageSceneDelayTimer` | `$FFFF9DB0` | Destroyer Proto and Missiray entry states load and count down this shared inter-state delay word. |
| `WolfGaropaBackdropYVel` | `$FFFF9DB6` | The Wolf Garopa approach initializes this signed 16.16 vertical step, accelerates it upward, and subtracts it from the secondary backdrop camera position. |
| `WolfGaropaEffectActive` | `$FFFF9DBA` | Wolf Garopa attack-effect loaders set this byte after creating their boundary pair; the boundary, boss states, and transition scroll all gate lifetime or phase changes on it. |
| `ShieldViperRowVRAMPos` | `$FFFF9DFC` | The Shield Viper transition advances this word by `$80` after each queued 64-word backdrop row and passes the adjusted value as the VDP destination. |
| `ShieldViperRowIndex` | `$FFFF9DFE` | Each queued Shield Viper row derives its repeated tile word from this index, increments it, and completes the row-build phase after twelve rows. |
| `ActiveRasterBuffer` (`ZLeoRasterBuildBuffer` overlay) | `$FFFF9E00` | Layout copiers populate this common HBlank stream for several modes; Z-Leo builds its four eight-byte command segments here before they are copied to the secondary buffer. |
| `SniperHoneyviperRasterControl` | `$FFFF9E02` | Sniper Honeyviper derives this VScroll control word from its vertical extent, and the selected layout copies it into the first active raster word. |
| `BossBackdropLeadBands` | `$FFFF9E0E` | The boss-backdrop builder reads the first nine word samples from here into the leading active raster bands. |
| `BossTransitionRaster` | `$FFFF9E1E` | The raster-layout copier writes three 64-byte blocks from the transition workspace to this contextual destination. |
| `RasterSecondaryBuffer` (`ZLeoRasterCommands`, `BossBackdropBandSource` overlays) | `$FFFF9E40` | Z-Leo copies and executes a 32-byte raster command stream here; the mutually exclusive boss-backdrop builder reads its remaining band samples from the same base. |
| `SharedRasterSplitPoint` (`BackdropLineOffsetsEnd`, `WaveSineTableCenter` overlays) | `$FFFF9F00` | The transition backdrop builder writes 96 words backward from this boundary, while the wave generator writes 128 words in each direction around the same point. |
| `XiTigerVScrollBuffer` | `$FFFF9FC0` | The raster-layout copier moves one 64-byte `CutsceneLineOffsetTable` block here, and the Xi-Tiger VBlank selector exposes this address to the installed HBlank writer. |
| `Stage10HBlankScrollData` | `$FFFF9FF8` | Stage 10 VBlank writes two vertical-scroll words and one selected horizontal-scroll word here; the installed HBlank routine consumes those three words in order. |

## Reviewed screen-shake and player-script fields

The shake update owns a level and current offset for each scroll plane. Both
offsets feed the plane scroll builders; the Plane A offset additionally becomes
the Y compensation applied to world sprites so foreground sprites remain
aligned with the shaken plane.

| Symbol | Address | Static evidence |
|---|---:|---|
| `SpriteShakeYOffset` | `$FFFF8086` | Each update copies `PlaneAShakeOffset` here; every world-sprite renderer subtracts the value from its OAM Y coordinate. |
| `PlaneBShakeWriteOnly` | `$FFFF8088` | Each update copies `PlaneBShakeOffset` here, but reconstructed source contains no reader, so no downstream purpose is claimed. |
| `PlaneAShakeLevel` | `$FFFFA010` | Impact and explosion paths load a small level; the shake updater decrements it every eight frames and publishes it as the Plane A offset. |
| `PlaneAShakeOffset` | `$FFFFA012` | The updater derives this offset from the Plane A level; Plane A horizontal/vertical scroll, HBlank effects, and sprite Y compensation consume it. |
| `PlaneBShakeLevel` | `$FFFFA014` | Impact and explosion paths load a small level; the shake updater decrements it every eight frames and publishes it as the Plane B offset. |
| `PlaneBShakeOffset` | `$FFFFA016` | The updater derives this offset from the Plane B level; Plane B horizontal and vertical scroll consumers apply it. |
| `PlayerScriptStateOffset` | `$FFFFA02A` | The player scripted-input dispatcher uses this even word as its handler-table offset; cutscene states select offsets and completion paths clear it. |

## Reviewed shared sprite scratch overlays

Initialization clears `$FFFFA100–A1FF`. Most consumers build temporary
eight-byte sprite entries here; spread-shot and Viblack allocation briefly
reuse the beginning as an object-pointer list, so the base is intentionally
named as shared scratch rather than as a persistent OAM buffer.

| Symbol | Address | Static evidence |
|---|---:|---|
| `SharedSpriteScratch` | `$FFFFA100` | Base of the 256-byte cleared scratch region used for temporary sprite lists and short-lived object-pointer lists. |
| `SpriteScratchTileWord0` | `$FFFFA104` | `Message_LoadSpriteTileIndices` writes the first entry's tile word here and advances in eight-byte entry strides. |
| `SpriteScratchEntry1` | `$FFFFA108` | The debug-menu HUD path submits the list from this second-entry boundary. |
| `RadialSpriteYBackward` / `RadialSpriteXBackward` | `$FFFFA120` / `$FFFFA126` | First radial-pair cursors, stepped backward by eight bytes for five entries. |
| `RadialSpriteYForward` / `RadialSpriteXForward` | `$FFFFA128` / `$FFFFA12E` | Opposite radial-pair cursors, stepped forward by eight bytes for five entries. |
| `LinearSpriteYStart` / `LinearSpriteXStart` | `$FFFFA150` / `$FFFFA156` | Start of the five-entry linear sprite row written after radial positioning. |
| `TimeDigitTileWordStart` | `$FFFFA17C` | Start of four tile words adjusted from the packed-BCD remaining-time bonus. |

## Reviewed global gameplay and stage-route fields

`GameplayStateBlock` is a structural start alias rather than a standalone
longword value. Full-game initialization clears 128 bytes from this address,
covering the adjacent stage, score, health, weapon, and route state.

| Symbol | Address | Static evidence |
|---|---:|---|
| `GameplayStateBlock` | `$FFFFA200` | `Sys_ClearGameplayStateBlock` clears eight groups of four longwords from this base, establishing the 128-byte block extent. |
| `StageProcessTableOffset` | `$FFFFA206` | Stage loaders select offsets `$00`, `$04`, `$08`, or `$0C`; the gameplay dispatcher uses the value to index the longword `Stage_ProcessHandlerTable`. |
| `StageRouteFlags` | `$FFFFA209` | Bit 0 is set by password/transition entry and tested by Stage 9 and Stage 12 route logic; bit 1 is set by post-stage entry and consumed by the boss-message initializer. |
| `StageObjectSpawnCursor` | `$FFFFA20E` | Configuration records load a spawn-list pointer; the spawner advances it over 12-byte records, while the sign bit suspends list processing. |

## Reviewed weapon loadout and ammunition fields

The four weapon slots use parallel word arrays. `WeaponSlotOffset` takes the
values 0, 2, 4, or 6 and selects the same slot in each array. The first array
stores the setup-screen configuration code; the following arrays hold a
regeneration delay, current ammunition, and maximum ammunition.

| Symbol | Address | Static evidence |
|---|---:|---|
| `WeaponSlotConfig0` | `$FFFFA250` | First setup configuration word; HUD, firing, selection, and regeneration consumers select it with slot offset zero. |
| `WeaponSlotConfig1` | `$FFFFA252` | Second setup configuration word selected with slot offset two. |
| `WeaponSlotConfig2` | `$FFFFA254` | Third setup configuration word selected with slot offset four. |
| `WeaponSlotConfig3` | `$FFFFA256` | Fourth setup configuration word selected with slot offset six. |
| `WeaponAmmoRegenTimers` | `$FFFFA258` | Base of four word timers; stage initialization clears them and the regeneration loop decrements and reloads each timer. |
| `WeaponSlotAmmo0` | `$FFFFA260` | First current-ammunition word; firing subtracts costs and inactive-slot regeneration adds two up to the paired maximum. |
| `WeaponSlotAmmo1` | `$FFFFA262` | Second current-ammunition word. |
| `WeaponSlotAmmo2` | `$FFFFA264` | Third current-ammunition word. |
| `WeaponSlotAmmo3` | `$FFFFA266` | Fourth current-ammunition word. |
| `WeaponSlotAmmoMax0` | `$FFFFA268` | First regeneration ceiling and stage-entry source for `WeaponSlotAmmo0`; recommitting the same selected weapon adds 250 up to 2000 and refills current ammunition from the result. |
| `WeaponSlotAmmoMax1` | `$FFFFA26A` | Second regeneration ceiling; the same selected-weapon commit path can raise and refill slot one. |
| `WeaponSlotAmmoMax2` | `$FFFFA26C` | Third regeneration ceiling; the same selected-weapon commit path can raise and refill slot two. |
| `WeaponSlotAmmoMax3` | `$FFFFA26E` | Fourth regeneration ceiling; the same selected-weapon commit path can raise and refill slot three. |

The previously generated “slot animation” names were incorrect. The loop
does not touch sprite-frame state: it reloads a delay from the configuration-
indexed `Weapon_AmmoRegenStepDelays`, increments current ammunition by two,
and clamps it to the slot maximum.

## Reviewed timer-control fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `StageTimerPauseFlag` | `$FFFFA272` | Bit 0 suppresses the stage-time decrement and low-time warning; boss/transition paths set it and STAGE/FIGHT message paths clear it. |
| `VBlankCountdown` | `$FFFFA282` | Decremented once per VBlank while nonzero; no reconstructed writer or completion consumer proves a narrower role. |

## Reviewed player-object header and motion fields

The object record beginning at `$FFFFA400` is the live player object. Its first
word is type `$0008`; the following fields use the same offsets as the shared
object update and rendering machinery.

| Symbol | Address | Static evidence |
|---|---:|---|
| `PlayerObjectType` | `$FFFFA400` | Player initialization writes type `$0008`; disabling player processing clears this word and the adjacent flags. |
| `PlayerObjectFlags` | `$FFFFA402` | Initialized to `$4D00`; update, renderer, camera, and cutscene paths manipulate individual control/display bits. |
| `PlayerStateOffset` | `$FFFFA404` | Even values select the player state dispatcher; initialization clears it and transitions install later states. |
| `PlayerWallContactFlags` | `$FFFFA407` | The low byte of object offset six: left/right wall resolution sets bits zero/one and direct wall probes set bits two/three. |
| `PlayerSpriteMapping` | `$FFFFA408` | Player rendering consumes the pointer, the secondary-object copier preserves it, and the motion-projectile path compares it with the teleport-dash mapping. |
| `PlayerAnimationTimer` | `$FFFFA40C` | Animation paths count it down and reload frame delays; state setup commonly primes it with `$FFFF`. |
| `PlayerSpriteAttributes` | `$FFFFA40E` | Initialized to `$4DC0`; facing, rendering, and cutscene paths manipulate its attribute bits. |
| `PlayerXPosition` | `$FFFFA410` | Signed 16.16 world X coordinate consumed by camera, targeting, enemies, bosses, and projectile placement. Sirene's active position/distortion routine also adds an angle-derived longword delta directly to it. |
| `PlayerYPosition` | `$FFFFA414` | Signed 16.16 world Y coordinate consumed by camera, targeting, bosses, and projectile placement. Sirene's active position/distortion routine adds an angle-derived longword delta and caps its integer word at `$158`. |
| `PlayerXVelocity` | `$FFFFA418` | Signed 16.16 horizontal velocity integrated into the X position by shared physics. |
| `PlayerYVelocity` | `$FFFFA41C` | Signed 16.16 vertical velocity integrated into the Y position by shared physics. |
| `PlayerOAMBucketOffset` | `$FFFFA420` | Renderers mask this byte with `$FC` and use it as a four-byte-aligned offset into the 64 OAM priority buckets. |
| `PlayerStateWorkHighWord` | `$FFFFA448` | High word of state-dependent work at object offset `$48`; states reuse it for dash velocity, timers, and direction, while the motion-effect path consumes only its sign. |
| `PlayerInvulnTimer` | `$FFFFA45E` | Counted down by the player invulnerability/flash updater; initialization and damage/death transitions install positive durations. |

## Reviewed controller-input fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `ControllerHeldState` | `$FFFFF706` | Two bytes hold the current active-high button masks for controller ports one and two. |
| `ControllerPressedState` | `$FFFFF708` | Per-port `current AND (previous XOR current)` values identify newly pressed buttons. |
| `ControllerReleasedState` | `$FFFFF70A` | Per-port `previous AND (previous XOR current)` values identify newly released buttons. |
| `PlayerPressedInput` | `$FFFFA46A` | Player input copies and masks the first pressed-state byte here; scripted input can synthesize the same field. |

## Reviewed primary-camera fields

| Symbol | Address | Static evidence |
|---|---:|---|
| `PrimaryCameraXPosition` | `$FFFFA900` | Signed 16.16 X coordinate updated by horizontal follow and stage-scroll paths and consumed by primary tilemap streaming. |
| `PrimaryCameraYPosition` | `$FFFFA904` | Signed 16.16 Y coordinate updated by vertical camera/stage paths and consumed by primary tilemap streaming. |
| `SecondaryCameraXPos` | `$FFFFA908` | Signed 16.16 secondary-camera X coordinate consumed by secondary tilemap streaming and Plane B horizontal scroll generation. |
| `SecondaryCameraYPos` | `$FFFFA90C` | Signed 16.16 secondary-camera Y coordinate consumed by secondary tilemap streaming and Plane B vertical scroll generation. |
| `CameraXDelta` | `$FFFFA910` | Current primary-camera X minus its previous-frame snapshot; applied to camera-relative objects and secondary scrolling. |
| `CameraYDelta` | `$FFFFA914` | Current primary-camera Y minus its previous-frame snapshot; applied to camera-relative objects. |
| `Stage9RasterScrollPhase` | `$FFFFA918` | Stage 9 advances this 16.16 phase by `$8000`, combines it with secondary-camera X, and emits the high word across its raster rows. |
| `StageCameraYVelocity` | `$FFFFA91C` | Signed 16.16 velocity integrated into primary-camera Y by the Caterpillar bounce path; Xi-Tiger landing paths load its initial upward impulse. |
| `PreviousCameraXPosition` | `$FFFFA928` | Previous high word of `PrimaryCameraXPosition`, refreshed after deriving `CameraXDelta`. |
| `PreviousCameraYPosition` | `$FFFFA92C` | Previous high word of `PrimaryCameraYPosition`, refreshed after deriving `CameraYDelta`. |
| `CameraDeltaLowerLimit` | `$FFFFA930` | An unreferenced player-state camera helper clamps computed signed 16.16 horizontal deltas against this lower limit; no reconstructed writer exists. |
| `PhysicsXVelocityLimit` | `$FFFFA938` | Symmetric horizontal velocity clamp used before object X integration; player initialization loads `$74000`. |
| `PhysicsYVelocityLimit` | `$FFFFA93C` | Symmetric vertical velocity clamp used before object Y integration; player initialization loads `$74000`. |

## Reviewed tilemap-row transfer state

| Symbol | Address | Static evidence |
|---|---:|---|
| `TilemapTransferBase` | `$FFFFA940` | Scrolling mode stores a VRAM-parameter pointer; constant/direct fill modes reuse the high word as a VDP destination base. |
| `TilemapRowCountdown` | `$FFFFA944` | Initialized to rows-minus-one, decremented after each queued row, and considered complete when negative. |
| `TilemapRowXOrFillWord` | `$FFFFA946` | Camera X in scrolling mode; repeated tile word in constant-row and direct-plane-fill modes. |
| `TilemapRowYPosition` | `$FFFFA948` | World Y used by the scrolling row builder and reduced by eight after each row. |

## Reviewed stage-dispatch and camera-motion controls

| Symbol | Address | Static evidence |
|---|---:|---|
| `StageStateOffset` | `$FFFFA950` | Stage records install an even handler offset; the selected stage subsystem dispatches it and transitions advance it by two. |
| `CameraMotionLockFlags` | `$FFFFA959` | Bit 6 suppresses X camera displacement and bit 7 suppresses Y displacement before camera-relative objects are moved. |

## Reviewed horizontal-camera bounds

| Symbol | Address | Static evidence |
|---|---:|---|
| `CameraXLowerBound` | `$FFFFA970` | Horizontal follow clamps the primary camera to this lower world-X limit; stage and boss transitions move it, and projectile bounds checks consume it. |
| `CameraXUpperBound` | `$FFFFA974` | Horizontal follow clamps the primary camera to this upper world-X limit; stage and boss transitions move it, and projectile bounds checks consume it. |

## Reviewed second-controller debug commands

| Symbol | Address | Static evidence |
|---|---:|---|
| `P2DebugCoarseXValue` | `$FFFFA00A` | An unreferenced controller-two helper subtracts or adds `$20` for newly pressed left or right; no reconstructed reader proves that the value belongs to a camera. |
| `P2DebugCoarseYValue` | `$FFFFA00C` | The same helper subtracts or adds `$20` for newly pressed up or down; no reconstructed reader exists. |
| `P2DebugFineYValue` | `$FFFFA00E` | A separate unreferenced helper adds or subtracts one for controller-two up or down while modifier bit four is held; no reconstructed reader exists. |
| `DebugJumpInput` | `$FFFFA980` | Written as one for newly pressed controller-two bit 4; no reconstructed static reader proves its downstream effect. |
| `DebugAttackInput` | `$FFFFA9C0` | Written as one for newly pressed controller-two bit 6; no reconstructed static reader proves its downstream effect. |
| `DebugInputXDirection` | `$FFFFA9D0` | Cleared as a longword, then its leading word receives -1 or +1 for controller-two left or right; no reconstructed static reader exists. |
| `DebugInputYDirection` | `$FFFFA9D4` | Cleared as a longword, then its leading word receives -1 or +1 for controller-two up or down; no reconstructed static reader exists. |

## Reviewed shared effect-object pool

| Symbol | Address | Static evidence |
|---|---:|---|
| `SharedEffectObjectPool` | `$FFFFBFC0` | Weapon, projectile, player-effect, and collision paths scan 96-byte object records from this base; common helpers clear between eight and seventeen consecutive records. |
| `EffectCollisionOddStart` | `$FFFFC020` | Collision processing alternates between the pool base and this second 96-byte record on successive frame parities. |
| `PlayerEffectObjectPool` | `$FFFFC2C0` | Base of eight 96-byte records used by player special attacks, weapon-selection sprites, projectile companions, target sight, Phoenix trails, and triple shots. |
| `PlayerEffectAllocStart` | `$FFFFC320` | One record after the player-effect base; free-slot allocation scans seven records from here, and weapon selection uses the first four for its slot sprites. |
| `PlayerSpecialObjectSlot` | `$FFFFC5C0` | Dedicated record initialized or cleared by player dash, teleport, projectile, impact, and Seven Forces paths and checked separately for special-attack collisions. |

`Sys_ClearInitializationObjectPools` first clears one 96-byte record at each
of `$FFFFA400`, `$FFFFA600`, and `$FFFFA800`, then clears 77 consecutive
96-byte records from `SharedEffectObjectPool` through `$FFFFDCFF`. This span
contains 16 shared-effect records and 61 entity records; the last entity record
at `$FFFFDCA0` currently has no dedicated absolute-field references. The name
deliberately records object-pool ownership rather than the graphics subsystem
of its caller.

## Fields named by the raw-literal conversion

Two addresses were reachable only through a raw `$FFFFxxxx` immediate and had no
imported symbol of any kind, so retiring the last address-forming literals meant
naming them from what the code does with them.

| Symbol | Address | Static evidence |
|---|---:|---|
| `CutsceneFrameSourceBuffer` | `$FFFF0400` | `CutsceneProjection_BuildFrame` loads it into `a0` and reads the frame through it at `$26(a0,d1.w)` and `$28(a0,d2.w)` while writing the resampled rows elsewhere, so it is the projection's pixel source. |
| `Stage3ResampleBuffer` | `$FFFF6000` | `Gfx_ResampleStage3Phase2Tiles` loads it into `a2`, fills it with `move.l (a0,d6.w),(a2)+` and `move.b d0,(a2)+`, then reloads the same address and reads the result back through `(a2,d4.w)`. |

Four further sites were bounds rather than bases and are written as offsets from
the workspace they belong to: the story-title glyph walks already used
`#CutsceneWorkBuffer` as their lower bound, so their upper bounds became
`#(CutsceneWorkBuffer+$A00)` and `#(CutsceneWorkBuffer+$1E00)` instead of
anchoring on an ending-sequence alias that merely sits at the same address.

## Reviewed primary entity record

`Entity_ObjectPool` is the base of 61 consecutive 96-byte records ending at
`$FFDCFF`. The first record's concrete owner changes between stages, bosses,
cutscenes, and credits. Absolute references to that record therefore use
structural `PrimaryEntity` names rather than a boss name.

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `PrimaryEntityFlags` | `$FFFFC622` | `$02` | Display/control flags matching offset two of all ordinary entity records. |
| `PrimaryEntityState` | `$FFFFC624` | `$04` | Even state-table offset cleared by setup, advanced by transitions, and compared by entity handlers. |
| `PrimaryEntityMapping` | `$FFFFC628` | `$08` | Sprite-mapping pointer; password-screen paths replace it with the selected cursor mapping. |
| `PrimaryEntitySpriteAttr` | `$FFFFC62E` | `$0E` | Sprite/tile attribute word; the ending-planet animation writes its attribute cycle here. |
| `PrimaryEntityXPos` | `$FFFFC630` | `$10` | Signed 16.16 world-X coordinate used by bosses, projectiles, cutscenes, and credits. |
| `PrimaryEntityYPos` | `$FFFFC634` | `$14` | Signed 16.16 world-Y coordinate used by linked parts, projectiles, cutscenes, and credits. |
| `PrimaryEntityXVelocity` | `$FFFFC638` | `$18` | Signed 16.16 horizontal velocity; some boss code deliberately reuses the primary record field as scratch motion state. |
| `PrimaryEntityAngle` | `$FFFFC640` | `$20` | Primary entity angle compared with linked Jampan objects' offset-`$20` angles. |
| `PrimaryEntityStatus` | `$FFFFC641` | `$21` | Broad entity status/control byte; only Shield Viper bit-six tests are proven for the absolute alias. |
| `PrimaryEntityWork4A` | `$FFFFC66A` | `$4A` | Owner-dependent work byte; Gusthead tests bit seven to distinguish attached and detached segment handling. |
| `PrimaryEntityWork4B` | `$FFFFC66B` | `$4B` | Owner-dependent work byte copied by one VBlank effect into the register-10 shadow; no stable entity-wide role is proven. |
| `PrimaryEntityWork4C` | `$FFFFC66C` | `$4C` | Owner-dependent work word used as Epsilon 1 mode bits and independently as a Stage 3 orbit-angle offset. |
| `PrimaryEntityWork58` | `$FFFFC678` | `$58` | Owner-dependent work word used as a Shield Viper defeat flag and the type-$1C0 family's selected-chain offset. |
| `PrimaryEntityWork5A` | `$FFFFC67A` | `$5A` | Owner-dependent work word used by the type-$1C0 transition as a vertical reference for linked parts. |
| `PrimaryEntityWork5C` | `$FFFFC67C` | `$5C` | Owner-dependent work word populated and consumed as the type-$1C0 family's linked-body-part count. |
| `PrimaryEntityWork5E` | `$FFFFC67E` | `$5E` | Owner-dependent work word cleared and advanced as the type-$1C0 family's graphics-animation progress. |

The type-`$1C0/$1C8` handlers use owner-specific overlays for these four
fields: `EntityType1C0ChainRootOffset`,
`EntityType1C0PartYReference`, `EntityType1C0BodyPartCount`, and
`EntityType1C0AnimationProgress`. The structural aliases remain available to
other owners; the overlay names are not claims about the entire entity pool.

## Reviewed secondary entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `SecondaryEntityType` | `$FFFFC680` | `$00` | Object type and base of the second 96-byte pool record; clearing it deactivates the record. |
| `SecondaryEntityFlags` | `$FFFFC682` | `$02` | Display/control flags written by scene setup and manipulated across linked records. |
| `SecondaryEntityState` | `$FFFFC684` | `$04` | Even state-table offset used by the ending planet's vertical-motion dispatcher. |
| `SecondaryEntityXPos` | `$FFFFC690` | `$10` | Signed 16.16 X coordinate of the second entity; Epsilon 1 uses it as its battle center. |
| `SecondaryEntityYPos` | `$FFFFC694` | `$14` | Signed 16.16 Y coordinate of the second entity; Epsilon 1 movement and other boss paths consume it. |
| `SecondaryEntityXVel` | `$FFFFC698` | `$18` | Signed 16.16 X velocity installed, reversed, and cleared during Epsilon 1 transitions. |
| `SecondaryEntityYVel` | `$FFFFC69C` | `$1C` | Signed 16.16 Y velocity accelerated for the battle center and copied to spawned ring projectiles. |
| `SecondaryEntityStatus` | `$FFFFC6A1` | `$21` | Second-record status byte set and cleared with linked Destroyer MK2 objects. |
| `SecondaryEntityWork40` | `$FFFFC6C0` | `$40` | Owner-specific work word; Destroyer Proto uses it as a linked-part angle. |
| `SecondaryEntityWork46` | `$FFFFC6C6` | `$46` | Owner-specific work word written by the Viblack transition setup. |
| `SecondaryEntityWork4C` | `$FFFFC6CC` | `$4C` | Union work word used as an angle by Bugmax/Stage 3 and as a body offset by Epsilon 1. |
| `SecondaryEntityWork52` | `$FFFFC6D2` | `$52` | Owner-specific linked-object control word used by Jampan. |
| `SecondaryEntityWork58` | `$FFFFC6D8` | `$58` | Union work longword used for Epsilon 1 motion and the type-$1C0 family's oscillation phase. |
| `SecondaryEntityWork5C` | `$FFFFC6DC` | `$5C` | Union work longword used as motion or byte-granular control state by different owners. |

`EntityType1C0OscillationPhase` overlays the low word of
`SecondaryEntityWork58`; Epsilon 1 separately uses the full longword as
motion. The type-$1C0 family also accesses the two bytes of
`SecondaryEntityWork5C` for distinct aim/phase control, so that union retains
its structural name.

## Reviewed tertiary entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `TertiaryEntityType` | `$FFFFC6E0` | `$00` | Object type and base of the third 96-byte pool record; clearing it deactivates the record. |
| `TertiaryEntityFlags` | `$FFFFC6E2` | `$02` | Display/control flags written by cutscene setup and cleared during transition cleanup. |
| `TertiaryEntityAttr` | `$FFFFC6EE` | `$0E` | Sprite-attribute word whose priority bit is toggled by the ship-arrival flash. |
| `TertiaryEntityXPos` | `$FFFFC6F0` | `$10` | Signed 16.16 X coordinate consumed by Bugmax linked-chain geometry. |
| `TertiaryEntityYPos` | `$FFFFC6F4` | `$14` | Signed 16.16 Y coordinate consumed by Bugmax geometry and direction calculations. |
| `TertiaryEntityStatus` | `$FFFFC701` | `$21` | Status byte set and cleared with linked Destroyer MK2 records and cleared during Epsilon 1 defeat. |
| `TertiaryEntityWork40` | `$FFFFC720` | `$40` | Owner-specific work word used as a linked-part angle by Destroyer Proto. |
| `TertiaryEntityWork4C` | `$FFFFC72C` | `$4C` | Owner-specific work word used as Bugmax's second joint angle. |
| `TertiaryEntityWork50` | `$FFFFC730` | `$50` | Owner-specific work word used as a Bugmax linked-part projection radius. |
| `TertiaryEntityWork52` | `$FFFFC732` | `$52` | Owner-specific linked-object control word used by Jampan. |
| `EntityType1C0TrailSpan` | `$FFFFC738` | `$58` | Vertical span used to distribute the type-$1C0 family's eight trail objects. |
| `EntityType1C0TrailStep` | `$FFFFC73C` | `$5C` | Accumulating contraction step subtracted from the trail span. |
| `EntityType1C0AimAngle` | `$FFFFC73E` | `$5E` | Cached angle-to-player sample used by the second-form body layout. |

## Reviewed quaternary entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `QuaternaryEntityType` | `$FFFFC740` | `$00` | Object type and base of the fourth 96-byte pool record; boss, projectile, cutscene, and credits code use it as a record base. |
| `QuaternaryEntityFlags` | `$FFFFC742` | `$02` | Display/control flags initialized with the preceding star-row entity records. |
| `QuaternaryEntityState` | `$FFFFC744` | `$04` | Even state-table offset tested by Destroyer MK2 cleanup and Epsilon 1 defeat handling. |
| `QuaternaryEntityStatus` | `$FFFFC761` | `$21` | Status byte cleared with the controller and third record when Epsilon 1 begins defeat. |
| `QuaternaryEntityWork40` | `$FFFFC780` | `$40` | Owner-specific work word used as a linked-part angle by Destroyer Proto. |
| `QuaternaryEntityWork46` | `$FFFFC786` | `$46` | Owner-specific second angle word used by Destroyer Proto. |
| `QuaternaryEntityWork52` | `$FFFFC792` | `$52` | Owner-specific linked-part control word used by Jampan. |
| `EntityType1C0ChainPeriod` | `$FFFFC79C` | `$5C` | Reload period for the second-form active-chain countdown. |

## Reviewed fifth entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `FifthEntityType` | `$FFFFC7A0` | `$00` | Object type and base of the fifth 96-byte pool record; several subsystems traverse later records from here. |
| `FifthEntityFlags` | `$FFFFC7A2` | `$02` | Display/control flags initialized with adjacent star-row records. |
| `FifthEntityState` | `$FFFFC7A4` | `$04` | Epsilon 1 ring-controller state and common linked-record state field checked by Destroyer MK2. |
| `FifthEntityWork40` | `$FFFFC7E0` | `$40` | Owner-specific work word used as a linked-part angle by Destroyer Proto. |
| `FifthEntityWork52` | `$FFFFC7F2` | `$52` | Owner-specific linked-part control word used by Jampan. |
| `EntityType1C0ChainCycle` | `$FFFFC7F8` | `$58` | Packed chain selector and per-chain countdown used by the type-$1C0 family's second form. |
| `FifthEntityWork5C` | `$FFFFC7FC` | `$5C` | Union word/byte storage used for type-$1C0 turning and Madam Barbar rotation bounds. |
| `EntityType1C0PoseRadius` | `$FFFFC7FD` | `$5D` | Low-byte pose radius derived from randomness and player distance. |
| `FifthEntityWork5E` | `$FFFFC7FE` | `$5E` | Union work word used for Epsilon 1 ring commands and Madam Barbar rotation bounds. |

`EntityType1C0TurnControl` overlays the high byte of `FifthEntityWork5C` in
the dormant family; Madam Barbar uses the structural word separately.

## Reviewed sixth entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `SixthEntityType` | `$FFFFC800` | `$00` | Object type and base of the sixth 96-byte pool record. |
| `SixthEntityFlags` | `$FFFFC802` | `$02` | Display/control flags initialized with adjacent star-row records. |
| `SixthEntityState` | `$FFFFC804` | `$04` | Linked-part state activated and polled by Destroyer MK2. |
| `SixthEntityWork40` | `$FFFFC840` | `$40` | Owner-specific work word used as a linked-part angle by Destroyer Proto. |
| `SixthEntityWork52` | `$FFFFC852` | `$52` | Owner-specific linked-part control word used by Jampan. |
| `SixthEntityWork56` | `$FFFFC856` | `$56` | Owner-specific work byte used as a pose-grid anchor by Sirene. |

## Reviewed seventh entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `SeventhEntityType` | `$FFFFC860` | `$00` | Object type and base of the seventh 96-byte pool record. |
| `SeventhEntityFlags` | `$FFFFC862` | `$02` | Display/control flags manipulated by Jampan and ordinary record-based code. |
| `SeventhEntityState` | `$FFFFC864` | `$04` | Linked-part state activated and polled by Destroyer MK2. |
| `SeventhEntityXPos` | `$FFFFC870` | `$10` | Signed 16.16 X coordinate copied by Jampan into spawned attack objects. |
| `SeventhEntityYPos` | `$FFFFC874` | `$14` | Signed 16.16 Y coordinate; Bugmax also reuses its high word as owner-specific scratch. |
| `SeventhEntityXVel` | `$FFFFC878` | `$18` | Signed 16.16 horizontal velocity seeded and consumed by Bugmax. |
| `SeventhEntityYVel` | `$FFFFC87C` | `$1C` | Signed 16.16 vertical velocity seeded and consumed by Bugmax. |
| `SeventhEntityWork40` | `$FFFFC8A0` | `$40` | Owner-specific linked-part angle word used by Destroyer Proto. |
| `SeventhEntityWork46` | `$FFFFC8A6` | `$46` | Owner-specific second linked-part angle word used by Destroyer Proto. |
| `SeventhEntityWork4A` | `$FFFFC8AA` | `$4A` | Owner-specific work word used as a Jampan shield-formation angle base. |
| `SeventhEntityWork4C` | `$FFFFC8AC` | `$4C` | Union work word used by Jampan formation geometry and Bugmax linked-part spin. |
| `SeventhEntityWork4E` | `$FFFFC8AE` | `$4E` | Owner-specific work word used as a Jampan shield-formation angle base. |
| `SeventhEntityWork52` | `$FFFFC8B2` | `$52` | Owner-specific linked-part control word used by Jampan. |

## Reviewed eighth entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `EighthEntityType` | `$FFFFC8C0` | `$00` | Object type and base of the eighth 96-byte pool record. |
| `EighthEntityFlags` | `$FFFFC8C2` | `$02` | Display/control flags initialized with adjacent star-row records. |
| `EighthEntityState` | `$FFFFC8C4` | `$04` | Linked-part state activated and polled by Destroyer MK2. |

## Reviewed ninth entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `NinthEntityType` | `$FFFFC920` | `$00` | Object type and base of the ninth 96-byte pool record. |
| `NinthEntityFlags` | `$FFFFC922` | `$02` | Display/control flags initialized with adjacent star-row records. |

## Reviewed tenth entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `TenthEntityType` | `$FFFFC980` | `$00` | Object type and base of the tenth 96-byte pool record. |
| `TenthEntityFlags` | `$FFFFC982` | `$02` | Display/control flags initialized with adjacent star-row records. |
| `ValkirieAuxFlags` | `$FFFFC9DE` | `$5E` | Bitfield coordinating Valkirie auxiliary attachment, launch, rotation, and targeting transitions. |

## Reviewed eleventh entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `EleventhEntityType` | `$FFFFC9E0` | `$00` | Object type and base of the eleventh 96-byte pool record. |
| `EleventhEntityFlags` | `$FFFFC9E2` | `$02` | Display/control flags and active bit used by the planet-grid sequence. |
| `EleventhEntityXPos` | `$FFFFC9F0` | `$10` | Integer X-position half copied into the sprite-grid center. |
| `EleventhEntityYPos` | `$FFFFC9F4` | `$14` | Integer Y-position half copied into the sprite-grid center. |
| `EleventhEntityXVel` | `$FFFFC9F8` | `$18` | Signed 16.16 horizontal velocity used by the first planet-grid sequence. |
| `EleventhEntityYVel` | `$FFFFC9FC` | `$1C` | Signed 16.16 vertical velocity used by the second planet-grid sequence. |

## Reviewed twelfth entity record

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `TwelfthEntityType` | `$FFFFCA40` | `$00` | Object type and base of the twelfth 96-byte pool record. |
| `TwelfthEntityFlags` | `$FFFFCA42` | `$02` | Display/control flags and active bit used by the ship-grid sequence. |
| `TwelfthEntityXPos` | `$FFFFCA50` | `$10` | Integer X-position half copied into the ship-grid center. |
| `TwelfthEntityYPos` | `$FFFFCA54` | `$14` | Integer Y-position half copied into the ship-grid center. |
| `TwelfthEntityXVel` | `$FFFFCA58` | `$18` | Signed 16.16 horizontal velocity used by the first ship-grid sequence. |
| `TwelfthEntityYVel` | `$FFFFCA5C` | `$1C` | Signed 16.16 vertical velocity used by the second ship-grid sequence. |

## Reviewed later entity record bases

| Symbol | Address | Record | Static evidence |
|---|---:|---:|---|
| `ThirteenthEntityType` | `$FFFFCAA0` | 13 | Flying Neo traverses ordinary linked-object fields from this record base. |
| `FourteenthEntityType` | `$FFFFCB00` | 14 | Sharpssteel and linked-object code use this fixed record base. |
| `FourteenthEntityXPos` | `$FFFFCB10` | 14 | Valkirie targeting reads the record's integer X coordinate. |
| `FourteenthEntityYPos` | `$FFFFCB14` | 14 | Valkirie targeting reads the record's integer Y coordinate. |
| `FifteenthEntityType` | `$FFFFCB60` | 15 | Bugmax and Antroid select this fixed object record. |
| `SixteenthEntityType` | `$FFFFCBC0` | 16 | Sniper Honeyviper and Artemis select this fixed object record. |
| `SixteenthEntityWork56` | `$FFFFCC16` | 16 | Sirene uses this owner-specific work byte as a pose-grid anchor. |
| `SeventeenthEntityType` | `$FFFFCC20` | 17 | Destroyer MK2 fragments and Medusa pose parts traverse from this record. |
| `EighteenthEntityType` | `$FFFFCC80` | 18 | Enemy-projectile allocation and Valkirie selection use this record base. |
| `NineteenthEntityType` | `$FFFFCCE0` | 19 | Valkirie bullet allocation and part commands use this record base. |
| `TwentiethEntityType` | `$FFFFCD40` | 20 | Joker linked objects and Victor ring setup use this record base. |
| `TwentyFirstEntityType` | `$FFFFCDA0` | 21 | Artemis, Joker, Victor, and Z-Leo use this fixed record. |
| `TwentyFirstEntityWork4C` | `$FFFFCDEC` | 21 | Owner-specific work word assigned during Victor ring deployment. |
| `TwentySecondEntityType` | `$FFFFCE00` | 22 | Enemy allocation and Joker linked-part rendering use this record base. |
| `TwentyThirdEntityType` | `$FFFFCE60` | 23 | Jampan shield traversal and Joker linked-part rendering use this record. |
| `TwentyThirdEntityAttr` | `$FFFFCE6E` | 23 | Sprite attribute whose priority bit controls Jampan shield collision. |
| `TwentyThirdEntityStatus` | `$FFFFCE81` | 23 | Status byte set and cleared with Jampan shield activation. |
| `TwentyThirdEntityWork26` | `$FFFFCE86` | 23 | Owner-specific shield collision control word. |
| `TwentyThirdEntityWork2C` | `$FFFFCE8C` | 23 | Owner-specific paired shield collision extents. |
| `TwentyFourthEntityType` | `$FFFFCEC0` | 24 | Destroyer Proto projectiles and Z-Leo wing code use this record base. |
| `TwentyFourthEntityFlags` | `$FFFFCEC2` | 24 | Display/control flags initialized by Destroyer Proto projectile setup. |
| `TwentyFifthEntityType` | `$FFFFCF20` | 25 | Shellshogun and Wolf Garopa use this fixed part record. |
| `TwentySixthEntityType` | `$FFFFCF80` | 26 | Forward projectile allocation and several fixed boss parts start here. |
| `TwentySixthEntityWork56` | `$FFFFCFD6` | 26 | Sirene uses this owner-specific work byte as a pose-row anchor. |
| `TwentySeventhEntityType` | `$FFFFCFE0` | 27 | Valkirie, Madam Barbar, and Z-Leo use this fixed linked-object record. |
| `TwentyEighthEntityType` | `$FFFFD040` | 28 | Jampan, Madam Barbar, Shellshogun, and Wolf Garopa use this record. |
| `TwentyEighthEntityAttr` | `$FFFFD04E` | 28 | Sprite attribute copied into Jampan's projected shield objects. |
| `JampanShieldWork20` | `$FFFFD060` | 28 | Owner-specific byte copied into each projected Jampan shield's offset `$20`. |
| `TwentyNinthEntityType` | `$FFFFD0A0` | 29 | Jampan's post-defeat shield and Madam Barbar use this fixed record. |
| `TwentyNinthEntityFlags` | `$FFFFD0A2` | 29 | Display/control flags updated during Jampan's post-defeat transition. |
| `TwentyNinthEntityXPos` | `$FFFFD0B0` | 29 | Integer X position copied into Jampan's post-defeat controller. |
| `TwentyNinthEntityYPos` | `$FFFFD0B4` | 29 | Integer Y position tested and copied during Jampan's defeat. |
| `TwentyNinthEntityYVel` | `$FFFFD0BC` | 29 | Signed 16.16 vertical velocity cleared after the defeat-shield descent. |
| `ThirtiethEntityType` | `$FFFFD100` | 30 | Z-Leo uses this fixed linked-part record. |
| `ThirtiethEntityXPos` | `$FFFFD110` | 30 | Integer X source position used by Artemis projectile setup. |
| `ThirtiethEntityYPos` | `$FFFFD114` | 30 | Integer Y source position used by Artemis projectile setup. |
| `ThirtyFirstEntityType` | `$FFFFD160` | 31 | Wolf Garopa uses this fixed orb record. |
| `ThirtySecondEntityType` | `$FFFFD1C0` | 32 | Victor starts reverse ring-link traversal from this record. |
| `VictorRingEndMapping` | `$FFFFD1C8` | 32 | Mapping pointer switched when Victor reverses ring deployment. |
| `ThirtySecondEntityXPos` | `$FFFFD1D0` | 32 | Integer X coordinate measured by Valkirie's tracking state. |
| `ThirtySecondEntityYPos` | `$FFFFD1D4` | 32 | Integer Y coordinate measured by Valkirie's tracking state. |
| `ThirtyThirdEntityType` | `$FFFFD220` | 33 | Z-Leo uses this fixed linked-part record. |
| `ThirtyFourthEntityType` | `$FFFFD280` | 34 | Caterpillar and the type-$1C0 family begin bounded projectile searches here. |
| `ThirtyEighthEntityType` | `$FFFFD400` | 38 | Joker begins a bounded descending-shot allocation range here. |
| `FortySixthEntityType` | `$FFFFD700` | 46 | Several boss and stage paths begin bounded projectile allocation here. |
| `EndingPlanetDebrisType` | `$FFFFD820` | 49 | Fixed ending-planet debris object type and record base. |
| `EndingPlanetDebrisFlags` | `$FFFFD822` | 49 | Display/control flags of the ending-planet debris object. |
| `EndingPlanetDebrisXVel` | `$FFFFD838` | 49 | Signed 16.16 horizontal velocity accelerated during debris motion. |
| `FiftiethEntityType` | `$FFFFD880` | 50 | Sirene and Terobuster begin bounded projectile searches here. |
| `AmbientParticlePool` | `$FFFFD8E0` | 51 | Six consecutive Stage 10/11 ambient-particle records. |
| `FiftyThirdEntityType` | `$FFFFD9A0` | 53 | Back Stringer tail slots and the reverse projectile scan start here. |

## Reviewed entity record 57

| Symbol | Address | Offset | Static evidence |
|---|---:|---:|---|
| `Entity57Type` | `$FFFFDB20` | `$00` | Shared record type used by effects, transitions, enemies, bosses, and projectiles. |
| `Entity57Flags` | `$FFFFDB22` | `$02` | Display/control flags manipulated by transitions and Z-Leo. |
| `Entity57State` | `$FFFFDB24` | `$04` | Even state index cleared by transitions and advanced by Stage 12 logic. |
| `Entity57XPos` | `$FFFFDB30` | `$10` | Signed 16.16 X position copied or compared by multiple owners. |
| `Entity57YPos` | `$FFFFDB34` | `$14` | Signed 16.16 Y position and shared vertical reference. |
| `Entity57XVel` | `$FFFFDB38` | `$18` | Signed 16.16 horizontal velocity used by Sharpssteel. |
| `Entity57YVel` | `$FFFFDB3C` | `$1C` | Signed 16.16 vertical velocity used by Z-Leo and Sharpssteel. |
| `Entity57Status` | `$FFFFDB41` | `$21` | Status byte cleared during record reconfiguration. |
| `Entity57CollisionFlags` | `$FFFFDB42` | `$22` | Object collision flags; the rising-shot path sets bit six. |
| `Entity57Work24` | `$FFFFDB44` | `$24` | Owner-dependent work word initialized by Stage 10-to-13 setup. |
| `Entity57Work56` | `$FFFFDB76` | `$56` | Owner-dependent Medusa pose and movement gate byte. |
| `Entity57Work58` | `$FFFFDB78` | `$58` | Owner-dependent Sharpssteel phase-control word. |
| `Entity57Work5A` | `$FFFFDB7A` | `$5A` | Owner-dependent Sharpssteel complex-phase flag byte. |

## Reviewed entity records 58–60

| Symbol | Address | Record/offset | Static evidence |
|---|---:|---:|---|
| `Entity58Type` | `$FFFFDB80` | 58/`$00` | Shared Valkirie, Z-Leo, transition, and arena-boundary record. |
| `Entity58YPos` | `$FFFFDB94` | 58/`$14` | Integer Y coordinate of the companion created by the Stage 24 scene transition; the scene-object growth state also writes it directly. |
| `Entity59Type` | `$FFFFDBE0` | 59/`$00` | Shared transition and arena-boundary record type. |
| `Entity59State` | `$FFFFDBE4` | 59/`$04` | Even object state advanced by Sharpssteel. |
| `Entity59XPos` | `$FFFFDBF0` | 59/`$10` | Integer X coordinate computed by Sharpssteel. |
| `Entity59YPos` | `$FFFFDBF4` | 59/`$14` | Integer Y coordinate computed by Sharpssteel. |
| `Entity59XVel` | `$FFFFDBF8` | 59/`$18` | Signed 16.16 horizontal velocity initialized by Sharpssteel. |
| `Entity59YVel` | `$FFFFDBFC` | 59/`$1C` | Signed 16.16 vertical velocity initialized by Sharpssteel. |
| `Entity60Type` | `$FFFFDC40` | 60/`$00` | Shared Seven Forces and late-boss record type. |
| `Entity60XPos` | `$FFFFDC50` | 60/`$10` | Integer X coordinate checked during Wolf Garopa transition. |
| `Entity60XVel` | `$FFFFDC58` | 60/`$18` | Signed 16.16 horizontal velocity consumed by Sylpheed. |
| `Entity60YVel` | `$FFFFDC5C` | 60/`$1C` | Signed 16.16 vertical velocity consumed by Sylpheed. |

## Reviewed gameplay and weapon-mode state

| Symbol | Address | Static evidence |
|---|---:|---|
| `GameplayStateBuffer` | `$FFFF8000` | Full initialization and the separate broad clear helper each clear the complete 8 KiB state region at `$FFFF8000-$FFFF9FFF`. |
| `WeaponTargetOrFrame` | `$FFFF801C` | Targeting modes store an object pointer here; icon mode reuses the word as its even frame counter. |
| `WeaponIconFrameTile` | `$FFFF801E` | State-twelve icon animation copies the selected frame's tile word here after clearing it with the other runtime parameters. |
| `WeaponAnimationDataPtr` | `$FFFF8020` | Circle-attack setup and weapon icon mode install and consume an animation-data pointer here. |
| `WeaponYMotionParameter` | `$FFFF8024` | Weapon setup derives a fixed-point vertical motion term here; impact particles add it to vertical velocity. |
| `WeaponXMotionParameter` | `$FFFF8028` | The paired fixed-point term is added to horizontal velocity; other weapon modes intentionally reuse its halves as parameters. |
| `WeaponModeParameter` | `$FFFF802C` | Weapon modes store either a direction-vector pointer or a word-sized state value here: state 2 supplies projectile lifetime and state 4 supplies an ammo-threshold flag. The neutral union name is intentional. |
| `WeaponMenuSpawnXOffset` | `$FFFF8032` | Weapon-select entry paths initialize this word; the rotating selection marker adds it to the player's X position. |
| `WeaponMenuSpawnYOffset` | `$FFFF8034` | Weapon-select entry paths initialize this word; the rotating selection marker adds it to the player's Y position. |

These weapon fields are mode-dependent unions. The map records all observed
roles rather than pretending that one weapon state's interpretation applies to
every state.

## Reviewed large tilemap and terrain workspaces

| Symbol | Address | Static evidence |
|---|---:|---|
| `LargeTilemapBuffer` | `$FFFF4000` | Frontend and ending paths walk `$800` longwords from this base, proving an 8 KiB shared tilemap workspace. |
| `FlyingNeoTileAttrRangeA` | `$FFFF4020` | Flying Neo clears the priority bit on 240 consecutive tile words beginning here. |
| `FlyingNeoTileAttrRangeB` | `$FFFF4AC0` | The second range in the same operation contains sixteen consecutive tile words. |
| `FlyingNeoTileAttrRangeC` | `$FFFF4360` | The third range contains 48 consecutive tile words whose priority bits are cleared. |
| `FlyingNeoTileAttrRangeD` | `$FFFF4400` | The fourth range contains the matching 48 tile words. |
| `LargeTilemapPage2` | `$FFFF5000` | This address is exactly 4 KiB after the shared buffer base; Stage 8 writes its first tile and credits edits 256 words from it. |
| `CreditsXiTigerTilemap` | `$FFFF5180` | Credits updates tile indices across three 16-word rows loaded for the Xi-Tiger scene. |
| `XiTigerCreditsFineTable` | `$FFFF6180` | Credits clears exactly 128 bytes here; the primary tilemap descriptor consumes the enclosing `$FFFF6000` byte table as its second-level lookup. |
| `XiTigerCreditsPatch0` | `$FFFF6194` | Credits seeds the first four-byte patch with indices `$81,$82,$83,$00`. |
| `XiTigerCreditsPatch1` | `$FFFF619C` | The next patch is one eight-byte lookup-row stride later and contains `$85,$86,$87,$00`. |
| `XiTigerCreditsPatch2` | `$FFFF61A4` | The third patch follows the same stride and contains `$89,$8A,$8B,$00`. |
| `Stage8StridedControl` | `$FFFF615D` | Train and Flying Neo profiles write three byte pairs at offsets zero, eight, and sixteen from this base. |
| `TerobusterIntroPalette` | `$FFFF644A` | Terobuster initialization writes its five-byte intro palette sequence beginning here. |
| `WeaponSetupWriteFlag` | `$FFFF7001` | Weapon-setup initialization writes one here; no reconstructed reader supports a narrower role. |
| `TerrainCollisionBuffer` | `$FFFF7800` | Terrain probes and enemy placement consistently pass this base with an `$80` bound; stage transitions clear 224 bytes from it. |
| `Stage8TilemapMode` | `$FFFF780C` | Stage 8 setup writes `$82`, and the Stage 9 corridor transition clears the same byte. |
| `Stage9TilemapMode` | `$FFFF780D` | Stage 9 writes `$82` after filling its four plane-map rows. |
| `WeaponSetupTilemapMode` | `$FFFF78FF` | Weapon setup writes `$82` after initializing its three plane-map color tables. |
| `Stage20PlaneMode0` | `$FFFF7981` | Stage 20 plane setup writes `$82`; the Sylpheed cleanup clears it with the adjacent mode bytes. |
| `Stage20PlaneMode1` | `$FFFF7982` | Stage 20 plane setup writes `$90`; the Sylpheed cleanup clears it. |
| `Stage20PlaneMode2` | `$FFFF7983` | Stage 20 plane setup writes `$92`; the Sylpheed cleanup clears it. |
| `Stage17TilemapMode` | `$FFFF7AFF` | Stage 17 writes `$82` after filling four complete plane-map rows. |
| `SevenForcesTilemapMode` | `$FFFF7B00` | Artemis setup writes two before filling its row; the shared Seven Forces cleanup clears it. |

The three paired bytes at `Stage8StridedControl` and the write-only weapon flag
remain deliberately structural names because no current reader proves their
bit-level protocol.

## Reviewed plane-tilemap and cutscene work buffers

The `$FFFF0000` plane map uses 64 words (`$80` bytes) per row. These sparse
anchors are the rows explicitly initialized by stage and frontend code; no
ownership beyond the observed shared plane-map storage is implied.

| Symbol | Address | Static evidence |
|---|---:|---|
| `PlaneTilemapRow9` | `$FFFF0480` | Stage 8 fills 64 words here in parallel with rows 10 and 24. |
| `PlaneTilemapRow10` | `$FFFF0500` | This is the next `$80`-byte row and receives the same 64-word Stage 8 fill. |
| `PlaneTilemapRow22` | `$FFFF0B00` | Artemis setup fills this complete 64-word tilemap row with tile `$0300`. |
| `PlaneTilemapRow24` | `$FFFF0C00` | Stage 8 and Stage 17 fill this complete row; its address is 24 row strides from the plane-map base. |
| `PlaneTilemapRow25` | `$FFFF0C80` | Stage 9, Stage 17, and Stage 20 setup fill this 64-word row. |
| `PlaneTilemapRow26` | `$FFFF0D00` | Stage and weapon-setup paths fill this complete 64-word row. |
| `PlaneTilemapRow27` | `$FFFF0D80` | Stage and weapon-setup paths fill this complete 64-word row. |
| `PlaneTilemapRow28` | `$FFFF0E00` | Stage and weapon-setup paths fill this complete 64-word row. |
| `PlaneTilemapRow29` | `$FFFF0E80` | The unreferenced Stage 20 variant fills this complete 64-word row. |
| `CutsceneWorkBuffer` | `$FFFF1000` | Story-title expansion clears and builds here, the ship reveal uses it as a `$240`-byte pattern buffer, and ending starfield reuses it for X positions. |
| `EndingStarYPositions` | `$FFFF1400` | Starfield initialization writes 256 fixed-point Y positions and the updater selects one of four `$100`-byte banks. |
| `StoryTitleLeftOrigin` | `$FFFF14C3` | Story-title expansion starts its leftward destination traversal from this byte in the shared workspace. |
| `StoryTitleRightOrigin` | `$FFFF1500` | The matching rightward expansion traversal starts from this aligned workspace address. |
| `EndingStarDepthValues` | `$FFFF1800` | Starfield initialization creates 256 depth/frame accumulators and update selects one of four banks. |
| `EndingStarXVelocities` | `$FFFF1C00` | Starfield initialization stores the fixed-point horizontal velocity paired with each X position. |
| `EndingStarYVelocities` | `$FFFF2000` | Starfield initialization stores the fixed-point vertical velocity paired with each Y position. |
| `SharedTilemapWorkspace` (`ShipArrivalTilemap` overlay) | `$FFFF2020` | Title, frontend, results, Seven Forces, Wolf Garopa, Z-Leo, and ship-arrival paths all transform staged tile words from this base; the ship overlay toggles priority on exactly `$160` words. |
| `SharedGraphicsOverlay` (`StoryTitleLogoPixels`, `ZLeoPriorityFirstRow`) | `$FFFF2080` | Story-title completion writes thirteen 128-byte mirrored glyphs here, while Z-Leo treats the same address as the first of four adjusted tilemap rows and clears priority on selected first-row columns. |
| `ZLeoPriorityLastRow` | `$FFFF20E0` | This address is three 32-byte tilemap rows after `ZLeoPriorityFirstRow`; Z-Leo clears priority on the complementary column pairs in that fourth row. |
| `ZLeoPriorityLastCol2` | `$FFFF20E4` | The first explicit Z-Leo priority clear in the fourth row targets column two at this address. |
| `StoryTitleMirroredGlyph` | `$FFFF2380` | Glyph setup writes 128 bytes of mirrored source nibbles beginning here. |
| `StoryTitleGlyphReadBase` | `$FFFF2384` | Both title-expansion paths begin their reverse source traversal relative to this interior glyph-buffer anchor. |

## Reviewed shared scene scratch

Stage-transition initialization clears four consecutive longwords at
`$FFFF8128-$FFFF8137`. They are not one persistent structure: mutually
exclusive game modes overlay different state on the same physical storage.

| Physical symbol | Address | Proven contextual overlays |
|---|---:|---|
| `SceneScratchLong0` | `$FFFF8128` | Weapon force index/vertical-scroll target, Xi-Tiger state/phase, ending completion/state, Game Over landscape index, stage-transition timer, and Epsilon 1 transition Y. |
| `SceneScratchLong1` | `$FFFF812C` | Weapon controller-layout index, Xi-Tiger motion step, and Epsilon 1 parallax position. |
| `SceneScratchLong2` | `$FFFF8130` | Weapon background phase, Xi-Tiger state counter/palette level, and Epsilon 1 parallax step. |
| `SceneScratchLong3` | `$FFFF8134` | Weapon highlight phase, Xi-Tiger wave phase/sprite X offset, Epsilon 1 V-scroll value, and the European Stage 15 Sunset Sting asset delay in its low word. |

## Reviewed frame, input, and system-state boundaries

| Symbol | Address | Static evidence |
|---|---:|---|
| `SpriteVDPStagingBuffer` | `$FFFFF000` | The clear loop writes 112 groups of four longwords, covering exactly `$700` bytes through `$FFFFF6FF`; the queue cursors subsequently meet at the interior `$FFFFF400` boundary. |
| `GameplayControlFlags` | `$FFFFF705` | Bits zero and one select the controller whose Start edge may toggle bit seven; bit six enables that pause-control path and secondary-button mapping; bit seven suppresses gameplay, HUD, spawn, and palette updates. |
| `SystemStateBlock` | `$FFFFFF00` | Reset clears 64 longwords from this base, exactly covering the final `$100` bytes of 68000 RAM that contain controller, option, result, and demo state. Controller initialization also clears the first longword. |
| `BootInitializedWord` | `$FFFFFF36` | Reset explicitly writes zero after the surrounding system block was cleared; no reconstructed reader establishes a narrower role. |
| `M68K_RAM_LAST_BYTE` | `$FFFFFFFF` | This structural constant identifies the final byte of the sign-extended 64 KiB 68000 work-RAM window. |

`BootInitializedWord` deliberately records only the observed initialization
role. It must not acquire an option or gameplay meaning without a reader or
runtime trace.

## Reviewed controller, timing, results, and demo state

| Symbol | Address | Static evidence |
|---|---:|---|
| `Controller1TypeID` | `$FFFFFF06` | Port-one polling stores the four-bit hardware response and accepts `$D` as the connected controller signature. |
| `Controller2TypeID` | `$FFFFFF07` | Port-two polling stores the corresponding hardware response before applying the same `$D` connection test. |
| `DeveloperSignatureTREA` | `$FFFFFF10` | Reset compares this longword with `TREA` and writes it as the first half of the warm-reset developer signature. |
| `DeveloperSignatureSURE` | `$FFFFFF14` | Reset compares this longword with `SURE` and writes it as the second half of the warm-reset developer signature. |
| `P1ButtonASourceBit` | `$FFFFFF20` | Optional port-one remapping reads this byte as the source bit mapped onto output button A; reset installs identity bit six. |
| `P2ButtonASourceBit` | `$FFFFFF21` | Optional port-two remapping reads this byte as the source bit mapped onto output button A; reset installs identity bit six. |
| `P1ButtonBSourceBit` | `$FFFFFF22` | Optional port-one remapping reads this byte as the source bit mapped onto output button B; reset installs identity bit four. |
| `P2ButtonBSourceBit` | `$FFFFFF23` | Optional port-two remapping reads this byte as the source bit mapped onto output button B; reset installs identity bit four. |
| `P1ButtonCSourceBit` | `$FFFFFF24` | Optional port-one remapping reads this byte as the source bit mapped onto output button C; reset installs identity bit five. |
| `P2ButtonCSourceBit` | `$FFFFFF25` | Optional port-two remapping reads this byte as the source bit mapped onto output button C; reset installs identity bit five. |
| `ConsoleVersionFlags` | `$FFFFFF26` | Reset snapshots the console version register; VBlank tests its bit six before applying the alternate timing delay. |
| `FrameSkipLevel` | `$FFFFFF3E` | HUD controls clamp this value to zero through three, while VBlank subtracts it from the update interval. |
| `ResultsExtendedLayout` | `$FFFFFF46` | Credits sets this word before entering results; results consumes and clears it while selecting extended scroll bounds. |
| `DemoCurrentInputWord` | `$FFFFFF48` | Playback holds the current packed held/pressed input here; recording retains the previous sample for run-length encoding. |
| `DemoInputRunFrames` | `$FFFFFF4A` | Playback counts down the current input run, while recording increments and emits the same run length. |
| `DemoInputStreamPtr` | `$FFFFFF4C` | Playback saves and advances the pointer to the next run-length encoded input record. |
| `DemoRecordingOffset` | `$FFFFFF50` | Recording advances this word by four bytes for each count/input pair written into its RAM buffer. |
| `DemoPlaybackInputWord` | `$FFFFFF52` | Playback copies the selected packed input here before publishing its two bytes to held and pressed controller state. |
| `DemoRecordingMode` | `$FFFFFF56` | Zero selects ROM playback; a nonzero value selects the RAM recording path and suppresses input injection. |
| `DemoFramesRemaining` | `$FFFFFF58` | Demo startup loads `$1000`; each update decrements the word and exits on zero. |
| `SavedDifficultyMode` | `$FFFFFF5E` | Demo entry saves the selected difficulty here and restores it on exit. |
| `SavedSoundDisableFlags` | `$FFFFFF60` | Demo and credits temporarily save the sound-disable options here and restore them on exit. |
| `DemoRotationIndex` | `$FFFFFF62` | Each completed demo advances this even index modulo eight to select the next stage and input stream. |
| `SavedControlLayoutFlags` | `$FFFFFF66` | Demo entry saves the control-layout byte here and restores it on exit. |

## Reviewed tile-interpolation block

| Symbol | Address | Static evidence |
|---|---:|---|
| `TileInterpolationBlockB` | `$FFFF9880` | The tile interpolator clears the enclosing `$FFFF9800-$FFFF99FF` workspace. Its dispatcher writes a `$40`- or `$60`-byte payload length at this second `$80`-byte block, then passes the same address to the type-one data loader; that loader consumes the word and transfers the following payload to VRAM. |

## Reviewed shared scene overlay at `$FFFF9900`

| Physical symbol | Contextual alias | Static evidence |
|---|---|---|
| `SharedSceneOverlayWord` | `TileInterpolationBlockC` | The three-block dispatcher writes a `$60`-byte payload length here and submits the same address as the third interpolated-tile source. |
| `SharedSceneOverlayWord` | `PasswordPrimaryBuffer` | Password code clears 24 bytes, appends terminator `$FF`, copies the selected text record, and passes this buffer to the wrapped double-height renderer. |
| `SharedSceneOverlayWord` | `FlyingNeoSineTable` | Flying Neo generates the four-quadrant trigonometric table from this base and reads its longword samples as linked-part vertical offsets. Sniper Honeyviper's separate table also reaches the physical word indirectly from its `$FFFF9400` base. |

## Reviewed shared scene overlay at `$FFFF9500`

| Physical symbol | Contextual alias | Static evidence |
|---|---|---|
| `SharedSceneOverlayBase` | `TransitionWorkingBuffer` | Transition modes copy four or seven 32-byte output blocks here; the standard and alternate raster-layout handlers consume those blocks. |
| `SharedSceneOverlayBase` | `FlyingNeoRasterBuffer` | The Flying Neo raster-layout handler copies one 64-byte block from this base into the active raster buffer. |
| `SharedSceneOverlayBase` | `SniperHoneyviperCosineTable` | Sniper Honeyviper reads this quarter-cycle view of the trigonometric table generated from `$FFFF9400` as tentacle X offsets. |
| `SharedSceneOverlayBase` | `SirenePatternBuffer` | Sirene writes and queues a 32-byte alternating pattern here before applying frame-parity marker patches. |
| `SharedSceneOverlayBase` | `ZLeoDropProjectileFlag` | Every active Z-Leo drop projectile sets the word; the boss renderer tests it for the rising-return palette branch and the boss core clears it once per update. |

## Reviewed shared scene workspace at `$FFFF9600`

`SharedSceneWorkspace` has no persistent single owner. Direct consumers use
the following contextual views:

| Contextual alias | Static evidence |
|---|---|
| `TransitionVScrollBuffer` | Transition processors write duplicated V-scroll words and the raster-layout handlers copy or repeat those rows into Plane B H-scroll storage. |
| `BugmaxAngleHistoryRows` | Bugmax initializes and shifts eight rows of four joint-angle words, then publishes delayed samples to linked parts. |
| `BackStringerPoseBuffer` | Back Stringer loads pose bytes, computes interpolation deltas, advances the interpolation, and publishes selected pose angles from this base. |
| `SevenForcesPattern` | The debug path fills and queues 64 bytes of C-nibble pattern data before applying its parity-selected marker words. |
| `JokerTileWordGroupA` | Joker writes the first of two cycling tile-word groups here; the paired group starts at `$FFFF9610`. |
| `ZLeoTileScrollIndex` | Z-Leo adjusts this even table index when camera Y crosses forward or reverse tile-stream thresholds. |
| `SharpssteelTargetTrail` | Sharpssteel fills and shifts six blade-target samples and consumes the first or tail sample during blade motion. |
| `FlyCorridorTilemap` | Stage 9 clears one selected column across 23 rows with a `$20`-byte row stride. |
| `TileInterpSourceB` | Ending and teleport setup pass this as the second source pattern to the tile interpolator. |

## Reviewed shared geometry workspace at `$FFFF9A00`

| Physical symbol | Contextual alias | Static evidence |
|---|---|---|
| `SharedGeometryWorkspace` | `TransitionRasterWork` | Transition modes generate 128-word sine or linear rows here, then sample and copy the resulting raster data. |
| `SharedGeometryWorkspace` | `GameOverRasterSource` | Game Over copies sixteen 32-byte blocks from this base and the raster-layout copier consumes seven 64-byte blocks from it. |
| `SharedGeometryWorkspace` | `BossBackdropWorkBuffer` | The encounter-backdrop builder copies seven 32-byte blocks into this destination before constructing its paired band buffers. |
| `SharedGeometryWorkspace` | `FlyingNeoCosineTable` | Flying Neo reads the quarter-cycle-shifted view of the generated sine table here as linked-part horizontal offsets. |
| `SharedGeometryWorkspace` | `SniperHoneyviperRotationHistory` | Sniper Honeyviper shifts five delayed angle words here and uses them to index its generated X/Y trigonometric tables. |
| `SharedGeometryWorkspace` | `ShieldViperOffsetTable` | The effect updates 96 longword accumulators with progressively negative deltas and copies each high word into Plane B H-scroll rows. |

## Reviewed shared scene data buffer at `$FFFF9800`

`SharedSceneDataBuffer` is an overlay anchor rather than a persistent object.
The direct contextual views are:

| Alias | Static evidence |
|---|---|
| `TileInterpolationBlockA` | The interpolator clears 512 bytes from this base, writes the first block's payload-length word, fills its payload, and submits the address to the VRAM loader. |
| `TransitionHScrollBuffer` | Transition processors generate one H-scroll word per output row here; layout handlers later copy the paired rows to active H-scroll RAM. |
| `GameOverRowWorkBuffer` | Game Over initializes 112 pairs of descending row values and updates them while projecting the landscape. |
| `CaterpillarPhaseTable` | Caterpillar writes its phase ramp and each segment reads an indexed phase to derive wave height. |
| `FlyingNeoAngleHistory` | Flying Neo shifts and later clears 36 delayed angle words used by its linked-part orbit updates. |
| `JetsripperAngleHistory` | Jetsripper fills or shifts 72 angle words and reads strided taps for its segment chain. |
| `PasswordDigitTextBuffer` | Password input writes four digits plus separators and terminator `$FF`, then renders the buffer as double-height text. |
| `MadamBarbarWorkObject` | Madam Barbar constructs a small object/mapping record here and points its root object at that record; wobble updates its coordinate words. |
| `MedusaSequenceOffset` | Medusa indexes eight-byte scripted-spawn entries with this word, advances it by eight, and clears it at segment boundaries. |
| `SunsetStingSharedState` | Sunset Sting core and segment handlers share flags, rotation delta, and motion step fields beginning at this base. |
| `SirenePoseHistory` | Sirene shifts pose-derived values through three rows of twelve words before publishing delayed values to its parts. |
| `Stage3ScaleStepTable` | Stage 3 writes 96 longword resampling steps and passes the same address as the resampler destination. |
| `CRAMWriteEffectBuffer` | The installed HBlank handler advances through words from this base and writes each one to CRAM color index five. |
| `WaveOutputBuffer` | The wave controller clears 81 longwords here, then fills and samples the buffer while generating the deformation. |

Formation-wave setup and the currently inert Viblack missile handler only load
the pointer without a reconstructed use, so they deliberately retain the
neutral physical name.

## Reviewed shared pattern rows at `$FFFF9400-$FFFF943F`

The first two 32-byte rows of the shared scene workspace have neutral physical
names because results, cutscenes, rendering effects, and many bosses overlay
the same storage with incompatible layouts. The transition subsystem exposes
contextual aliases rather than claiming ownership of the physical addresses.

| Physical range | Contextual alias | Static evidence |
|---|---|---|
| `SharedPatternRow0Long0` through `SharedPatternRow0Long7` (`$FFFF9400-$FFFF941F`) | `TransitionPatternRow0`; base also exposed as `TransitionPatternBuffer` | `Effect_ApplyTransitionMask` advances across two longwords per iteration for four iterations, consuming exactly eight longwords. Transition initialization and byte-mask helpers build and mutate the larger buffer from the same base. Results independently overlays display state, row counters and offsets, scroll state, selected-row state, and packed-BCD operands. |
| `SharedPatternRow1Long0` through `SharedPatternRow1Long7` (`$FFFF9420-$FFFF943F`) | `TransitionPatternRow1` | The same four-iteration mask loop consumes the second row in lockstep with rows zero and two, proving its 32-byte extent and element width. Results independently overlays its current-row pointer, completion-music latch, three aggregate BCD values, two aggregate counters, navigation latch, and vertical bounds. |

The results-history code exposes exact contextual aliases for those two rows:
`ResultsDisplayState`, rendered-row and row-offset fields, scroll target and
steps, selected-row fields, BCD start/end operands, aggregate time/visit
fields, and viewport bounds. These aliases are used only by
`ui/results_scrolling.s` and `ui/results_data.s`; the neutral physical names
remain authoritative for other mutually exclusive users of the workspace.

## Reviewed shared transfer workspace at `$FFFF8058-$FFFF8061`

| Physical symbol | Contextual aliases | Static evidence |
|---|---|---|
| `SharedTransferWorkLong0` (`$FFFF8058`) | `TileCoarseLookupOffset`, `TileFineLookupOffset`, `IndexedDMACommand`, `IndexedDMALowByte`, `Stage3ScaleTablePtr`, `Stage7ExitDelay`, `Stage9RevealColumn` | Streaming derives two lookup offsets from camera coordinates; indexed transfers construct and patch a four-byte VDP command. Other scenes independently store a scale-table pointer, exit delay, or revealed-column index. |
| `SharedTransferWorkWord0` (`$FFFF805C`) | `TilePatternOffset`, `IndexedStagingStart`, `PasswordDifficulty` | Streaming derives a pattern offset, indexed transfers preserve the staging cursor for optional mirroring, and password validation records the matched difficulty. |
| `SharedTransferWorkLong1` (`$FFFF805E`) | `TilePlaneBufferOffset`, `IndexedGroupStride`, `PasswordStageNumber`, `OptionsSelection`, `OptionsCursorMoving`, `OptionsBGMIndex` | Streaming derives a destination-buffer offset, indexed transfers retain a source stride, password validation records a stage, and options screens overlay selection and animation fields. |

## Reviewed shared runtime workspace at `$FFFF8040-$FFFF804B`

These four physical fields have no single semantic owner. Forty-four
contextual aliases make the local protocol visible at every executable use.

| Physical symbol | Representative contextual views | Static evidence |
|---|---|---|
| `SharedRuntimeWorkLong0` (`$FFFF8040`) | `DMASourceEncoding`, `PoseCommandWord`, `PoseDurationByte`, `MetaspriteBaseTileWord`, `MetaspriteParentPtr`, `MetaspritePartCountM1`, `CutsceneRowSource`, `CutsceneRowVRAM`, `WaveStateTimer`, `TileInterpSpan`, `TileInterpReadBaseA`, `Stage3PackedTilePtr`, `MessageGlyphHiNibbleScratch`, `PaletteColorPair`, `HitboxMirrorScratchA` | Independent code paths use the bytes as a DMA source encoding, command word, two-word pair, pointer, counter, glyph-pixel nibble scratch, or mirrored hitbox. |
| `SharedRuntimeWorkLong1` (`$FFFF8044`) | `CircleAttackOffsetY`, `TileInterpReadBaseB`, `TileInterpSpanStep`, `MessageGlyphLoNibbleScratch`, `HitboxMirrorScratchB` | Fixed-point attack offset, interpolation read base/step, glyph-pixel nibble scratch, and hitbox bytes occupy incompatible layouts. |
| `SharedRuntimeWorkWord0` (`$FFFF8048`) | `MetaspriteSineScratch`, `CircleAttackTargetDX`, `BCDIncrementScratch`, `TileInterpVRAM`, `Stage3ResampleGroupsM1`, `Stage9SecondaryXCopy` | Consumers store a trigonometric sample, signed delta, packed BCD one, VRAM cursor, loop count, or camera snapshot. |
| `SharedRuntimeWorkWord1` (`$FFFF804A`) | `MetaspriteCosScratch`, `CircleAttackTargetDY`, `BCDIncrementEnd`, `TileInterpStepsLeft`, `Stage3ResamplePassesM1` | Consumers store a second trigonometric sample or delta, use the address as a BCD exclusive end, or retain independent loop state. |

## Reviewed shared control workspace at `$FFFF8062-$FFFF806D`

The final raw RAM cluster is a twelve-byte overlay whose meaning follows the
active scene. Neutral physical longwords preserve that allocation; all 190
executable references use one of 33 contextual views.

| Physical symbol | Representative contextual views | Static evidence |
|---|---|---|
| `SharedControlWorkLong0` (`$FFFF8062`) | `AsteroidVScrollSpeed`, `BackdropLineSpeed`, `WolfGaropaScrollSpeed`, `TerobusterIntroTimer`, `TerobusterProjectileY`, `LightningEffectTimer`, `XiTigerEntranceTimer`, `PostViblackVScrollVel`, `OptionsHandlerOffset`, `OptionsCursorFlashTimer`, `PasswordCursorFlash` | Separate scene paths treat the longword as signed fixed-point scroll speed or split it into independent timer, coordinate, handler-offset, and flash words. |
| `SharedControlWorkLong1` (`$FFFF8066`) | `AsteroidVScrollPos`, `BackdropLinePosition`, `ArtemisForegroundState`, `TerobusterTileRowIndex`, `TeleportSnakeScrollVel`, `MidgameFadeLevel`, `ContinueCountdownValue`, `TitleMenuSelection`, `OptionsSFXIndex`, `OptionsRepeatTimer`, `PasswordCursorOffset` | The same bytes hold integrated positions, motion state, row progress, a fixed-point countdown or velocity, and mutually exclusive front-end fields. |
| `SharedControlWorkLong2` (`$FFFF806A`) | `BackdropTailPosition`, `Stage12TeleportFade`, `Stage16CameraSnapshot`, `PostViblackPalettePos`, `OptionsPressedCopy`, `OptionsHeldCopy`, `OptionsVoiceIndex`, `PasswordHeldNibble`, `PasswordRepeatTimer` | Transition and Stage 16 code use overlapping word and longword state, while front-end paths address individual controller bytes, selection bytes, and repeat timers. |

## Review policy

- `byte_`, `word_`, and `dword_` state observed access width, not purpose.
- Overlapping names may be valid when code accesses fields at different widths;
  do not merge them from address proximity alone.
- A semantic rename requires cross-reference analysis and preferably a runtime
  assertion that exercises both reads and writes.
- Record structure extent only after bounds are supported by iteration limits,
  adjacent accesses, or runtime traces.
- Runtime scenarios should use reviewed semantic aliases. Raw address names are
  acceptable only while the expectation is explicitly marked `unknown` or
  `hypothesis`.

This is a subsystem-organized RAM reference, not an append-only experiment log
or a claim that every alias has one universal semantic role. Its size is
intentional: comparing mutually exclusive scene overlays in one address-space
reference is safer than splitting a single memory owner into unrelated pages.
The exact definitions remain in `src/ram_addrs.inc`; semantic evidence remains
in `config/name_audit.json`. The twelve inherited JP scenarios use named fields
but do not exercise every overlay; see [runtime verification](runtime.md).
