# Unknowns register

The machine-readable thresholds live in `config/source_policy.json`.

## Active visual-identity unknowns

These stable IDs track three encounter-level investigations originally behind
seven `NAME-003` hypothesis records. Three definitions have pinned same-frame
and human visual evidence; four use static, identity-neutral names. None of the
seven retains hypothesis-level naming evidence. Source comments cite each ID.
The `CODE` and `DATA` entries below retain seven historical IDs, of which six
exact-address name-audit records still have `unknown` evidence. The full
investigation record, with its superseded interpretations, is `docs/unknowns.md`
at the `source-reconstruction-1.0` tag; see also
[the dormant-family investigation](dormant_entity_1c0.md). Keep an entry and its
evidence when it is resolved.

The five returns without a demonstrated entry path and the unselected transfer
tuple remain `unknown`, not assertions of dead code. Unverified dormant-entity
artwork names stay neutral; enabling cut content and exploring Jampan or
dialogue patches belong to later modding work. The Stage 4 rendering report
remains an unreproduced observation.

### VIS-001 Type-$390 linked-chain controller identity

- **Status:** resolved for source naming; visual identity open
- **Confidence:** high for chain ownership; low for visual identity
- **Location:** `src/enemies/entity_type_390_linked_chain.s`, `$0310E6`
- **Evidence:** The type-`$390` controller owns an eight-object chain of types
  `$394` and `$398`. At pinned TAS frames 21,989 and 22,000 it is in slot 2; the
  visible fat bird dropping shots is instead the separate type-`$90` enemy in
  slot 5, identified by the human reviewer. The `$390` controller has no sprite
  mapping in those states, and its children at frame 22,000 are at Y `$170`,
  below the captured 224-pixel image. The bird screenshot therefore cannot
  establish Gusthead ownership or the chain's appearance. A later paired
  capture, `reference/tas/022643.png` and `.genstate`, was identified by the
  human reviewer as Gusthead. Its object pool has a type-`$1B0` root in slot 0
  and sixteen type-`$1BC` parts in slots 1–16; their mapping addresses select
  `Boss_GustheadRootMappingA` and the `Boss_GustheadSegmentMapping*` family. No
  `$390/$394/$398` object is active in that capture. This independently
  corroborates the existing Gusthead root/segment names, but does not identify
  the earlier type-`$390` chain. The source keeps role-only type-`$390` names.
- **Experiment:** Capture a frame where type-`$394/$398` parts are actually
  visible, paired with their same-frame state and the `$390` controller. A
  boss-specific name requires that additional evidence; role-only names do not
  depend on it.

### VIS-002 Stage 13 chained boss identity

- **Status:** resolved
- **Confidence:** high
- **Location:** `src/bosses/snake.s`, `$04079E` and `$040AF6`
- **Evidence:** Pinned TAS frame 28,000 shows the Snake head and body. Its
  paired `.genstate` has type `$298` in slot 0, state `$04`, and 23 type-`$29C`
  children in slots 1–23. The human reviewer confirmed both the boss identity
  and that these children are its segments.
- **Experiment:** Completed with `reference/tas/028000.png` and
  `reference/tas/028000.genstate`; the archive is local and ignored by Git.

### VIS-003 Dormant type-$1C0 family versus stage-15 Sunset Sting

- **Status:** resolved for source ownership; visual identity of dormant family
  open
- **Confidence:** high for code ownership; low for external graphic attribution
- **Location:** `src/bosses/entity_type_1c0_core.s` at `$040CEE`,
  `src/bosses/entity_type_1c0_attacks.s` at `$0418FC`, and
  `src/bosses/sunset_sting_main.s` at `$042A10` and `$04309E`
- **Evidence:** Stage 15 loads the `$1EC` asset set. The human reviewer
  identified its vertically stretched appearance at TAS frame 32,124 and its
  pre-fight flower at frame 32,200; both are type `$1EC`, slot 0. The separate
  `$1C0/$1C4/$1C8` family builds a hierarchy of body parts with radii and
  angles, and its second form preserves `$1C8` during pool cleanup. The stage-15
  controller builds sixteen segments and preserves `$1EC`. An unselected asset
  record at `$011538` carries type `$1C0` and pointers to graphics `$011542` and
  palette `$00C404`; outside material calls the art Love Penguin, but that name
  is not established by the ROM. The `$04309E` state increases
  `BossCombatCounter` and oscillates position; its appearance was not observed.
  See `docs/dormant_entity_1c0.md`.
- **Experiment:** The source naming is now neutral for `$1C0/$1C8` and
  behavior-specific for `$04309E`. Further pictures or traces can identify
  appearances but are not needed to justify the current names.

## Active unknown-evidence records

The code entries below are *statically unreferenced*, not proven impossible to
execute. An indirect dispatch or an unobserved input could still reach them. An
exact big-endian longword scan of the canonical 2 MiB Japanese ROM found zero
copies of each of the six open addresses (`$040CEC`, `$0586F2`, `$058BA0`,
`$059BAA`, `$08277C`, `$011356`). This rules out a literal 32-bit absolute
pointer to those entry addresses in the image; it does not rule out PC-relative
references, computed addresses, or other indirect selection.

### CODE-001 Snake trailing return

- **Status:** open
- **Confidence:** low
- **Location:** `src/bosses/snake.s`, `$040CEC`
- **Evidence:** This isolated `rts` follows the Snake animation-frame table. No
  direct source call, branch, or table pointer selects it.
- **Experiment:** Trace PCs and indirect targets during the pinned Snake
  encounter. Record a concrete reaching path before assigning a stronger role;
  lack of hits in one replay is not proof that the entry is dead.

### DATA-001 Type-$1C0 early-form part mapping

- **Status:** resolved
- **Confidence:** high
- **Location:** `src/bosses/entity_type_1c0_core.s`, `$040D2E`
- **Evidence:** Five flagged pointers in the 61-long body-part table at
  `$041568` select these six bytes as a sprite mapping. The reader consumes each
  entry with `move.l (a1)+`. Their earlier `dc.w` spelling hid the pointers from
  relocation checks; the table is now symbolically typed.
- **Experiment:** Completed by comparing the table encoding to the reader; a
  shifted build remains a useful regression probe.

### CODE-002 Artemis pose-script return

- **Status:** open
- **Confidence:** low
- **Location:** `src/bosses/artemis_rendering.s`, `$0586F2`
- **Evidence:** An isolated `rts` separates the pose-script updater from its
  frame loader; no direct source reference selects the return.
- **Experiment:** Trace PC and indirect dispatch through Artemis pose-script
  transitions. Document a reaching path before claiming its function.

### CODE-003 Artemis emitter return

- **Status:** open
- **Confidence:** low
- **Location:** `src/projectiles/artemis.s`, `$058BA0`
- **Evidence:** An isolated `rts` lies between the radial-emitter updater and
  sprite-attribute table; no direct source reference selects it.
- **Experiment:** Trace PC and indirect targets during Artemis projectile
  patterns. Preserve the entry without asserting runtime reachability.

### CODE-004 Sylpheed pose-script return

- **Status:** open
- **Confidence:** low
- **Location:** `src/bosses/sylpheed_pose.s`, `$059BAA`
- **Evidence:** An isolated `rts` lies between the pose-script updater and frame
  loader; no direct source reference selects it.
- **Experiment:** Trace PC and indirect dispatch through Sylpheed pose-script
  transitions. Document a reaching path before assigning a stronger role.

### CODE-005 Pitch-envelope stack-skip return

- **Status:** open
- **Confidence:** low
- **Location:** `src/sound/driver_core.s`, `$08277C`
- **Evidence:** This helper adds four to `sp` and returns, but no static call,
  branch, table pointer, or envelope-command dispatch selects it.
- **Experiment:** Trace the sound-driver PC and pitch-envelope command stream
  under the pinned runtime to find a real entry path, if one exists.

### DATA-002 Unselected VRAM transfer tuple

- **Status:** open
- **Confidence:** low
- **Location:** `src/rendering/boss_asset_sets.s`, `$011356`
- **Evidence:** Four longwords have the neighboring RAM/VRAM transfer tuple
  shape, but no symbolic source reference selects this one. The former
  `ScrollWide` interpretation was inferred from adjacency alone.
- **Experiment:** Find a concrete pointer or runtime read selecting the tuple,
  then establish its owner and use. Keep the neutral name in the meantime.

The parallel repacker worktree reported a disappearing Stage 4 platform before
Sniper Honeyviper. A controlled retest on this branch did not reproduce it: both
16-byte and 8-KiB relocation-only builds matched every sampled TAS and longplay
screenshot through the boss entrance (70/70 and 118/118 per build). The saved
older full-shift image equals the debug/godmode variant and diverges from
canonical TAS gameplay by frame 600, so it is not a clean control. A transient
unsampled glitch or another exact failing build is still possible; the missing
ROM/frame is the remaining evidence gap, not a known stale Stage 4 pointer. The
two archive-adjacent tails at `$1BE722` and `$19C492` are also unassigned beyond
their observable command-like byte structure. See `docs/payload_archives.md`.

## Other open investigations

- [Dormant type-$1C0 family](dormant_entity_1c0.md): distinguish proven pointer
  ownership from external artwork attribution and unobserved stock entry paths.
- [Compressed payloads](payload_archives.md): two archive-adjacent tails retain
  neutral names; the Stage 4 rendering report still lacks a reproducible exact
  failing image/frame. Controlled sampled shifts are not an all-frame proof.
- Scripted messages: no ordinary route into the boss and ship message scripts is
  known. `BossMessage_Start` takes READY/FIGHT when `StageRouteFlags` bit 1 is
  set and otherwise needs `MessageMode` below 4, but the known gameplay,
  weapon-setup, password and options exits all write 4 through
  `UI_ResetPaletteAndMessageMode_Clear`; boot writes 0. `ShipName_StartScript`
  has its own entrance, and the type-$308 initializer that reaches it is not in
  the live Stage 17 handler table. These are bounded findings, not proof that no
  indirect path exists. The scripts stay editable in Text Studio.
- [Graphics models](graphics_models.md): unbound mapping, art and palette
  associations remain visible as unknown markers.
- Orphaned cross-stage dispatch: the first offset at ROM $02FC46 resolves to
  $0304B2, inside a bsr.w displacement rather than a procedure entry. Its
  constructor and possible indirect runtime selection remain unknown; the bytes
  and symbolic expressions are preserved in the historical record.
- [Sound reference safety](sound_models.md): canonical out-of-table PSG reads
  are retained by exact source-relative identity, not silently repaired.
  [Sound driver](sound_driver.md) also separates assembled Z80 source identity
  from incomplete indirect-flow, scheduling and native waveform semantics.

## Resolved naming work

The naming policy, exact-address evidence and reviewed duplicate groups live in
`config/source_policy.json`, `config/name_audit.json` and
`config/duplicate_basis_reviews.json`; `make lint` and `make semantic-audit`
check them. Resolving an unknown does not delete its ID or strengthen old
evidence. Keep the CODE, DATA and VIS entries above in step with the source
comments that cite them.
