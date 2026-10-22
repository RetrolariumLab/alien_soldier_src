# Graphics and stage-rendering models

The Graphics Studio models read the cartridge formats that Level Studio needs to
render a stage, and expose guarded tile, palette, mapping and animation
documents. They do not claim that every object looks exactly as in the game.

`make init-content-all` exports all 3,230 tiles as 64 palette-index nibbles
apiece. The validator fixes the inventory, chain headers, block counts, tile
counts, and encoded byte length of every payload. `build-content` applies edits
only to the staged `data/artunc` copy, so a pixel edit cannot move later ROM
data or modify the preservation assets. `make check-graphics-workspace` proves a
zero-edit round trip for JP and EU.

The same content workspace exports all 95 palette commands in 55 blocks. Their
destinations and capacities are fixed, the 29 offset lists remain read-only
source metadata, and the encoder routes changes to `palettes.s` or one of the
three extracted command banks according to the command's actual owner. Original
raw words such as `$FFFF` are legal: the Mega Drive ignores their unused CRAM
bits, so normalizing those bits would corrupt preservation data. Palette edits
are accepted by the staged content build and the workstation palette panel.

The mapping workspace exports all 1,169 mappings and 3,566 pieces recognized by
the proved static and dynamic readers. Its fixed inventory spans 764 blocks,
including nine binary payloads and every assembly owner explicitly named in the
content manifest. Static pieces retain their exact six-byte capacity. Dynamic
pieces keep their art symbol, upload tile offset, and payload-derived size fixed
while permitting bounded position and attribute edits. Terminator bits remain
source-owned so one edit cannot merge or split mappings. The complete raw size
byte is retained because the renderer consumes only its low OAM bits and
original data sometimes sets the ignored high nibble. The staged content build
applies this document, and the workstation exposes a bounded geometry panel for
every mapping. It intentionally draws piece rectangles rather than guessing art
for static mappings; exact sprite imagery belongs to the object gallery where
art and palette bindings can be proved together.

The animation workspace exposes all 112 relative-offset scripts and 670 fixed
frame slots. It keeps each slot's normal-frame or zero-duration-jump role fixed,
bounds durations to the encoded word, and restricts targets to the 272 symbols
already observed as frames or to the known script inventory for jumps. The
staged encoder preserves the `Target-*` relocation form across all 17 owners.
The workstation animation panel edits role-aware targets and durations without
allowing a slot to change its interpretation.

The compressed-tile workspace covers the 146 LZSS streams proved to reach
`LoadCompressedToVRAM` and decode to complete 32-byte Mega Drive tiles: 28,555
tiles in 586,536 bytes of original compressed capacity. One command-seven
stream, `Credits_SegaMappingData`, decodes to 408 bytes and is explicitly
excluded as non-tile data. The encoder retains the original stream unchanged at
zero edit. Once pixels change it uses the verified block-safe compressor,
rejects output larger than that stream's original slot, and pads shorter output
past the compressed-size header so later ROM addresses never move. This works
for 140 binary includes and six inline `dc.b` streams.

Schema 2 also exposes the seven command-two/three tile-codec streams: 850 tiles
in 11,522 fixed bytes. The combined compressed-art document has 153 streams and
29,405 tiles. The **Compressed tiles** selector identifies each stream's codec.
Original marker/run shapes can retain their bit length when the colours of the
pixels they own change together; otherwise an edited tile uses run encoding.
Unchanged tiles retain their source tokens. Rebuilt streams must decode back to
every requested pixel and fit their original capacity. Some freehand edits still
exceed capacity; the editor reports that failure.

Opening a schema-1 document migrates it in memory, retaining validated LZSS
edits and adding the seven tile streams from the source. Save writes schema 2.
`make init-content` also persists that migration without `FORCE`; it rejects
invalid source metadata, inventory or unfitting edits before replacing the old
document. Its zero-edit path keeps every original compressed byte intact.

The object gallery is a derived view rather than another editable document. It
indexes all 314 fixed stage placements through their source-owned spawn lists,
stage configurations, and handler table. Selecting Preview creates a disposable
tree below `build/content/gallery/<profile>/`, applies the current Level Studio
document and all five in-memory Graphics Studio documents, and decodes only the
selected placement's sample stage. A sprite is displayed only when its resting
mapping and tile attribute are proved by the staged source; otherwise the view
reports the missing binding instead of borrowing art or guessing a palette. Each
preview also stages the graphics policy used to exclude unsupported background
planes, and invalidates the cached source snapshot for that destination before
rebuilding it. Repeated previews therefore read current palette and art edits
from the same workspace instead of retaining the first preview's data. A tiny
two-preview regression exercises the actual staging and source-cache boundary,
including the required graphics-policy read; it does not copy the full cartridge
source or launch the emulator.

`make graphics-studio CONTENT_PROFILE=jp` opens a thin workstation over all five
documents. Its two tile tabs select fixed-size and fixed-slot LZSS payloads and
paint indices 0 through 15. Its palette tab selects commands and colours, edits
three-bit hardware channels without discarding ignored raw bits, and also
permits an explicit raw word edit. Its mapping tab edits bounded piece geometry
and raw attributes while protecting dynamic art bindings and mapping boundaries.
Save validates and atomically replaces all five documents. Its animation tab
edits proved frame targets and durations while preserving jump roles.
Dirty-close protection covers every editable tab, and Build ROM invokes the
isolated content build. The tile swatches remain a greyscale index view rather
than a claim about which CRAM palette uses the art. `make check-graphics-studio`
exercises every profile-bound loading path and proves the 314-record gallery
inventory without creating a display or eagerly rendering every stage.
`make check-graphics-widget` separately opens hidden real Tk windows for both
profile labels using one tiny record per editable format and a derived-gallery
fixture. It checks five in-memory edit paths, the six tabs, and dirty-close
handling without parsing large graphics workspaces, staging a stage, or writing
source files. The real JP/EU documents, encoders, and gallery inventory remain
the responsibility of the headless checks.

`make check-graphics-models` runs five source-derived gates:

- 289 uncompressed-art payloads decode and re-encode as 3,230 4bpp tiles;
- 95 palette commands in 55 blocks and 29 offset lists land on command
  boundaries;
- 1,169 mappings in 764 blocks round-trip all 3,566 sprite pieces, including 68
  dynamic mappings whose 1,591 tiles are checked against their art;
- 123 stage asset lists replay 369 commands and decode 93 RAM payloads;
- all 26 stage table entries resolve through six streaming descriptors.

The machine-counted authority is `config/authoring/graphics.json`.
`scripts/authoring/graphics_inventory.py` fails when names or counts drift and
can update the derived fields explicitly with `--write`.

## Stage renderer

The renderer replays the source-owned asset lists into RAM and VRAM, unfolds the
32-by-32 coarse map, 8-by-8 chunks, 4-by-4 patterns, and VDP name words, then
composites plane A and plane B by priority and transparency. It applies the
configuration record's entry modes, camera origins, quarter-rate plane-B
parallax, register-7 backdrop colour, palette list, and visual-loader palette
and tile commands.

The horizontal parallax calculation changes only plane B's camera origin; both
planes advance one source pixel per screen pixel, including partial tiles at
unaligned camera edges. The initial views of the first three stages use absolute
quarter scroll and a static 512-pixel ring for plane B. A Stage 4 boss probe
reproduces source-driven line scroll, the full plane-B name table, 20 streamed
plane-A rows and one 8,832-byte tile-art transfer at the Sniper Honeyviper
fight; Level Studio's read-only JP boss reference viewer shows those poses,
outside the editable viewport.

Placed objects are resolved from object type to handler, resting animation,
mapping, stage tile base, art, and palette. A sprite is drawn only when that
chain is proved; otherwise Level Studio must use a labelled marker. The current
model draws 275 of 314 placements. The previously covered 74 circling enemies
and 33 birds use their own stage-loaded RAM tile-base slots, not the common
enemy slot. `Sys_SpawnObject` clears the 96-byte object record before the first
update, making the dispatcher's initial state word zero. The source-owned
state-zero dispatch, initializer, RAM symbols, and each stage's compact tile
commands all agree on those bases. Another 35 type-$48 objects now follow the
source's `$C80` base and its optional bit-12 attribute from spawn parameter bit
1; both input variants are tested on JP and EU. A missing slot or parameter
still produces a marker. Seven type-$12C objects also use their spawn parameter
as an eight-byte selector into paired animation-pointer and attribute records;
bit 15 changes graphics mode but not that selector. All five table choices
produce source-tile previews in JP and EU. Seven more placed homing,
phase-pattern, and wasp enemies read stage-loaded RAM slots at offsets 4, 8, and
10\. Their initial state routes and visible source tiles are checked;
phase-pattern's separate parameter-bit-7 branch remains a marker. Three Stage 12
floaters follow their state-zero initializer, which constructs attribute `$8000`
directly. Their first shared animation reads tile `$150` onward from the Stage
10/12 common asset list's art at VRAM `$0000`, which covers `$2A00`; this gives
visible JP/EU previews. This proves the static initial frame only. The placed
Stage 12 teddy bear adds one more proved preview: its first dispatch entry
reaches an initializer that pairs `SharedTeddyHazardLoopAnimation` with `$8000`.
In TAS state 23676, type `$368` points to that exact animation, and all 14
initial-frame tile records match the source-built Stage 12 VRAM. The JP and EU
galleries both draw this source-owned initial frame. Thirteen placed handlers
still lack a proved resting mapping, and twelve lack a proved tile base; these
sets overlap and are not all classified as invisible. These previews do not
establish runtime sprite-pixel fidelity.

The visual-asset reader also preserves nine full `dc.w / dc.l / dc.w` load
records embedded among compact indexed commands. The original tuple decoder
omits `dc.l` source pointers, so the parser now recovers those labels from their
ROM-order assembly blocks and keeps the following destination word. Stage 7's
full command is checked against its decoded source art at VRAM `$8000`; the
other eight command/source/destination triples are pinned too. This fills
source-owned art in the stage renderer without claiming every runtime sprite is
visible or pixel-identical.

The 15 placed moving platforms also require a stage-index branch: below
`StageTableIndex=$18`, the object replaces its initial mapping/base with
`Stage18_MovingPlatformSpriteMapping` and `$4000`. All current placements take
this lower route. The previous generic first-write path selected `$4470` and the
other mapping, leaving two pieces blank in four placements. A bounded inventory
now checks that every piece of all 275 previewable placements has nonblank
staged tile art. Nonblank art alone is not a runtime pixel-fidelity claim.

Two TAS states (frames 667 and 9021) showed how the weapon-selection object is
drawn. Mapping pieces are emitted first to last, but where they overlap the
earlier OAM piece wins, so software compositing must paint last to first. At
frame 9022 the object also loses pieces to the H40 limit of 320 sprite pixels
per scanline: following the SAT link chain, earlier entries 42 and 8 use up the
budget and plane A shows through. The hardware limit is documented in Sega's
[Genesis Software Manual](https://segaretro.org/images/9/95/GenesisSoftwareManual.pdf);
the exact pixel ownership here is independently checked against the captured
state and screenshot. The object's final `$FE00` VRAM tiles are absent from the
static stage scene. Source inspection explains that gap:
`StageEntryAssetLoadList` transfers `SharedMenuType3DataF680` to VRAM
`$F680..$FFFF`, while the stage-entry clear touches only the first 48 KiB. The
decoded 2432-byte payload matches that VRAM range in both states. The preview
checks that no subsequent initial-stage transfer overlaps the range; otherwise
it remains a marker. The object's initializer reads the stage configuration's
initial priority into `$E(a5)`. This source-backed carryover gives the 17 placed
weapon-selection objects a 552-pixel static preview in JP and EU, but does not
prove their later runtime priority, animation, or palette in every context.

Five stage indices intentionally produce no complete static background. Slots 20
through 22 load no stage tilemap beyond the shared list. Slots 17 and 18 have
runtime scroll routines that override the entry-mode planes; replaying only
their initial descriptor would display a screen the game does not show. These
exclusions and their evidence are recorded under `stage_rendering` in the
graphics inventory rather than filled with guessed artwork.

## Codec boundary

The weapon-selection carryover guard treats commands 1 and 5 as raw VRAM copies,
bounds them by their declared size word, and rejects incomplete or unknown
transfers. The derived drawable count uses this same carryover check once per
relevant stage, so a refused preview cannot remain counted as drawn.

The LZSS reader and optimizing encoder, tile codec, palette commands, static and
dynamic sprite mappings, and stage tilemap loaders are verified headlessly. The
stage renderer now decodes the nine command-three VRAM transfers with the
verified bit-token decoder, which lets Screen Studio reconstruct the title and
options background art. The fixed-slot compressed-art workspace now permits both
tile-codec load commands with reader-checked encoding and capacity bounds. The
executable codec description is in [`tile_codec_spec.md`](tile_codec_spec.md).
The repack audit also checks that a file containing consecutive archives is not
mistaken for one archive and that no source pointer lands inside a
size-sensitive payload.

## Timed animation source model and safe retargets

Animation target edits now require the original regional cartridge, the
authenticated name/address ledger, the exact signed-word reader and matching
source/ROM mapping formats. A retarget must fit the aligned signed16 relative
pointer and preserve the reader's piece format; a jump must enter an
authenticated script whose first entry is a mapping. If those facts are unknown,
the retarget is refused rather than guessed. Unchanged documents and
duration-only edits do not invent a new pointer obligation. Staged builds
validate against the canonical project while writing only their private tree.

`animation_preview_model.py` models the timed static object-list reader using
all its operations and the complete43-operation caller. Its bounded trajectory
contains real mapping pieces, coordinates and dimensions. A tick is one
qualified reader invocation, not an assumed emulator frame. In particular,
negative low-byte timers hold indefinitely, a zero low byte reloads the word,
the source flag can pause countdown, and a zero-duration transition follows
exactly one relative jump rather than recursively resolving jump chains.
Different callers, dynamic mappings and unproved fall-through fail explicitly.

The JP/EU catalog contains112 scripts,670 entries and272 exact mapping labels,
including `Projectile_BugmaxSpreadFrame00/01` which a previous name-only filter
missed. `tests/test_animation_pointer_domains.py` and the animation preview
tests cover the pointer domains, the playback model and the Tk controls.

The Animations tab now has Play, Pause, Step and Reset controls. The lazy
catalog snapshots both unsaved animation and mapping documents after complete
fixed-format validation. Its270 editor-owned frame targets receive edited
pieces; the two Bugmax targets outside that editor's inventory keep their exact
source geometry. Document changes cannot mutate an existing trajectory. Piece
rectangles show actual coordinates and dimensions, not guessed artwork.

The displayed caller is explicitly synthetic: object flags `$E0` and
`FrameControlFlags=$00`. A100ms viewer callback means one reader invocation, not
a native frame or a game-specific frame rate. Pause stops the viewer, not a
modeled game flag. Playback stops on a source negative-byte hold or at4096
invocations. Selection, accepted edits/reload and approved close cancel owned Tk
callbacks; declined dirty reload/close retain the running viewer. Unsupported
readers, dynamic pieces and unproved fall-through are visible errors. Shared
validation also forbids reordering records inside packed mapping blocks: the
encoder writes document order, so accepting a reordered offset inventory would
make staged bytes disagree with first-frame preview. Source-owned count/index
metadata rejects bool/float aliases and malformed inventories with ordinary
validation errors. The playback follows the source reader; it does not reproduce
SAT/OAM, palettes or real frame timing.
