# Level Studio

Level Studio edits the nineteen object spawn lists read by
`Sys_ProcessSpawnList` (314 placement records), the thirty stage configuration
records, the stage routes that are plain wrappers, and the compressed stage
maps. Capacities are fixed: records cannot be added or removed, and special
stage initializers and asset lists are not editable.

## Placements

Each placement is twelve bytes, six big-endian words:

| Field | Runtime meaning |
| --- | --- |
| `x` | World X and the camera trigger for spawning |
| `y` | Y position before the runtime camera adjustment |
| `object_type` | Byte offset into `Entity_UpdateHandlerTable`; low bits gate difficulty |
| `parameter` | Object-specific word copied to the new slot |
| `slot_first` | First permitted object-pool boundary |
| `slot_limit` | Limiting object-pool boundary |

Eleven lists are assembly directives and eight are extracted binary payloads,
some of them empty; each keeps its storage form and terminator. The validator
requires real dispatch-table offsets and object-pool boundaries seen in the
source. An X may not reach the `$7FFF` stop word, and the first pool slot must
be inside the pool and no later than the limit (equal boundaries are a valid
one-slot range).

The spawner reads records in order until one X exceeds camera X plus `$140`,
so a later record with a smaller X waits behind the largest X before it. Stage
5 has `$400` followed by `$3E0` on purpose; Level Studio shows the second
record's effective spawn X as `$400` and recomputes it after edits. The list is
never sorted.

## Stage configuration

A configuration record is the thirty-byte structure read by
`Stage_ApplyConfigurationRecord`: state and spawn-director words, the
spawn-list pointer, two palette bytes, sprite priority, four camera words, two
plane entry modes, two player-position bytes and a palette-list pointer.
Values must fit their widths, and pointers may select only spawn lists and
palette lists the source already has. The unusual numeric Stage 20 cursor is
kept but cannot become another literal.

Indexed fields are checked against the tables they index, with capacities read
from the source:

- `palette_primary` and `palette_secondary` are dispatch offsets into
  `Palette_PrimaryEffectOffsets` and `Palette_SecondaryEffectOffsets`, not
  colours: even values `0..18` and `0..6`.
- The plane entry modes are zero (constant fill) or an aligned four-byte
  offset, biased by four, into their pointer tables. The primary reader masks
  bit 15 to select the `$1000` map-Y variant, the secondary one does not, so
  A allows `0`, `4`, `8`, `$8004` and `$8008` and B allows `0`, `4` and `8`.
  The Xi-Tiger record has its own reader and table and is not editable here.
- The spawn director is an offset into `EnemySpawn_DirectorHandlers`: `0`, `2`
  or `4`.
- `state_offset` must be an aligned offset into the state table that each
  stage slot's asset loader actually selects (tables of 60, 59, 82 and 79
  words, including the Stage 17 entry override). A record shared by several
  slots must satisfy all of them; a record whose reader is unknown keeps its
  state word.

A valid offset is not a guarantee that the effect or state suits that stage.
An invalid one fails validation before anything is staged, and a failed edit
leaves the document and the selection as they were.

## Routes

All 26 `StageTableIndex` slots go through `Stage_InitializerOffsets`, whose
entries stay fixed. Sixteen slots use a three-instruction wrapper (load a
configuration pointer, `nop`, branch to the common reader); for those the
workspace may select another existing configuration record, and the staged
build rewrites only that wrapper's `lea` in `src/stages/configuration.s`. The
other ten run more setup code and keep their routes. A route edit does not
change the slot's asset loader.

## Maps and rendering

The headless renderer follows every stage slot through its asset lists,
configuration, palettes, VRAM transfers, both plane descriptors and placements
([graphics models](graphics_models.md)). Five slots need runtime-specific
treatment that it does not reproduce, and placements without a known sprite or
tile base are drawn as labelled markers.

The stage-map document makes 42 pattern, chunk and coarse streams editable in
their fixed compressed slots, including five alternate plane-B pattern streams
([stage maps](stage_map_model.md)). The window lists the streams the selected
stage uses as a grid of raw values and replays the edited RAM transfers in
memory, so a changed or reverted cell updates the preview at once. Saved Screen
Studio edits to shared maps are composed in; `Refresh other maps` reloads them,
and conflicting edits to one stream are refused before rendering.

Clicking plane A or B selects the last source-owned writer of that cell: a
pattern word, chunk index or coarse index. Plane B uses the secondary camera.
In the first views of stage slots 0 to 2 the plane-B brush follows the same
512-pixel VRAM ring as the renderer, including Stage 2's seam, and highlights
both copies when a cell appears twice. Slots 7 and 8 keep both planes with
their own camera origins; their later scroll and raster effects are not
reproduced.

Every map edit also passes a reference guard: a new coarse or chunk index may
not point past loaded data, and a new read may not hit RAM that no asset list
writes. It is checked for every page of the editor viewport and, by a bounded
traversal, across the whole 8192x8192 periodic map space of both planes. For
example, Stage 1 plane-B chunk `$FF` fits its slot but reads unwritten pattern
RAM at `$FFFF3FE0`, so it is refused. The brush rolls back on failure, and
`validate-content` runs the same check on every stage a changed stream reaches
([map reference audit](map_reference_audit.md)).

Stages can be more than ten thousand pixels long, so the window renders a
960-pixel viewport and pages through the stage.

## The window

```text
make level-studio CONTENT_PROFILE=jp STAGE_INDEX=0
```

It opens the profile's `content/workspace/<profile>/level/levels.json` and
`stage_maps.json`, not a fresh export. Edits survive switching stages, and a
shared configuration record stays shared. Applying a configuration edit
rebuilds the scene before committing it: camera and palette changes show at
once, a new spawn-list pointer shows that list's placements, and the selection
is cleared rather than moved to a different object. Single-field edits and
Apply all validate the whole document first, so Apply all never commits half
of its fields.

For Japanese stage slots 3 (Sniper Honeyviper), 4 (Madam Barbar) and 5
(Joker), `JP boss reference` opens read-only 320x192 renders of the boss
background at poses listed in `config/authoring/stage4_boss_jp_fidelity.json`
and `stage5_6_jp_fidelity.json`. HUD and sprites are not drawn, and workspace
edits are not applied.

Playtest saves and runs `make playtest-level` for the selected stage
([level playtest](level_playtest.md)); Save, Reload, Build and Close follow
[the common Studio actions](workstation_actions.md).

## Checks

`make check-level-model` exports each profile's baseline and applies it again
in memory; an unchanged document must change no file. `make check-level-studio`
opens both workspaces without a window, makes a placement edit and a map edit
and checks that the map edit reaches the stage RAM preview. The widget tests
open hidden Tk windows with a small fixture.
