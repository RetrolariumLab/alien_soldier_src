# Stage RAM map workspace

The writable level-geometry model covers RAM maps loaded through asset command
6, `LoadCompressedToRAM`, at addresses in the default stage streaming descriptor
and five alternate plane-B pattern streams. Those additional streams are
included only where the model's 320x224 viewport at the configured secondary X
origin and editor Y zero reads their words through its descriptor and final RAM
writer. `Tilemap_QueueColumnFromDescriptor` consumes three layers: 16-bit name
words in 4-by-4 patterns, 8-bit pattern indices in 8-by-8 chunks, and 8-bit
chunk indices in the 32-by-32 coarse map. The RAM bases and stage asset-list
reachability are derived from the source, not inferred from screenshots.

`make check-level-map-model` checks both regional workspaces: 42 compressed map
payloads, comprising 17 pattern, 22 chunk, and three coarse streams. Together
they hold 51,596 editable values in 86,808 decoded bytes and 42,420 original
compressed bytes. Twenty-five streams live in extracted binary segments; 17 are
inline assembly bytes. Eleven distinct stage RAM transfers remain outside the
proved map inventory. A transfer in the broad plane-B pattern address interval
alone is not evidence: only the five streams reached by actual tile reads were
added. Exceptional runtime descriptors and scroll overrides still need separate
evidence. Several stage 10/teleport and stage 20 starting-view tile reads fall
in a plane-B RAM gap with no asset-list writer. The editor's zero-filled RAM
image is not proof of the cartridge's runtime contents there; these addresses
are not exported as editable ROM payloads, and full background fidelity remains
open.

The workspace documents live at
`content/workspace/{jp,eu}/level/stage_maps.json`. Each value is editable within
its original width and number of slots. Re-encoding must fit the original
compressed slot; shorter streams receive inert padding after their size header.
The staged content build changes only its disposable `src/` and `data/` copies,
never the preservation inputs. Metadata, source owners, map roles, stage
consumers, value counts, and compressed capacity cannot be changed by a
workspace document. The unchanged JP and EU documents both round-trip without
touching a byte.

The workspace schema is 2. Existing schema-1 documents can be upgraded without
losing valid edits by running, for each profile:

```text
python scripts/authoring/stage_map_model.py migrate --profile jp --document content/workspace/jp/level/stage_maps.json
python scripts/authoring/stage_map_model.py migrate --profile eu --document content/workspace/eu/level/stage_maps.json
```

Migration verifies the old source-owned topology and capacity before copying its
37 value streams into the new 42-stream document. New plane-B streams start at
canonical values. Malformed or over-capacity edits are rejected; the operation
does not touch preservation `src/` or `data/`.

`SharedMappingData7000` is consumed by both a stage and a static screen. The two
documents therefore share one physical ROM stream. An unchanged document cannot
undo the other's edit during the staged build; if both documents propose
different bytes, the build rejects the conflict before writing either map. Level
and Screen Studio previews compose the saved peer document in the same order as
the content build. Identical edits to the shared stream agree; different edits
fail before rendering. This rule is tested both in memory and on a disposable
source/data copy.

The Level Studio window has a `Map values` tab for the streams loaded by the
selected stage. It shows one source-owned pattern, chunk, or coarse unit at a
time in a bounded 256-pixel raw-value grid; entries and click-to-paint use the
same width/capacity validator as the headless document. Save, Reload, Build ROM,
and Playtest include both level documents and dirty-close protects map edits.
The stage viewport is rebuilt in memory after a successful edit: the loader
order is replayed with the edited stream, without writing `src/`, `data/`, or a
temporary full ROM. Reverting a value restores the original RAM scene.
`make check-level-studio` exercises a real map edit and reopened preview for JP
and EU without creating Tk widgets; the widget tests drive Apply and Save in a
hidden window, including a rejected over-capacity edit. `Refresh other maps`
reloads saved Screen Studio map edits into this preview without discarding
unsaved Level Studio edits. It reports a conflicting shared stream and keeps the
previous scene.

The viewport picker selects plane A or B, then traces a click to the
source-owned value behind that pixel. Plane B uses its independent parallax
camera origin for the selected page, not a quarter-scaled pixel coordinate. The
role selector chooses the 8x8-pixel pattern word, 32x32-pixel chunk index, or
256x256-pixel coarse index; the yellow outline uses the selected plane's camera
and map-Y offset. With `Paint with value above` enabled, the click writes the
numeric brush through the existing width, compressed-slot, and shared-stream
validators. The resolver follows the actual descriptor map addresses and final
RAM transfer. Plane A still requires the default map layout; plane B accepts an
alternate descriptor only when its final writer is in this stage-map artifact.
Stage 1 plane-B coarse, chunk, and `$2000` pattern values are supported. JP and
EU headless smoke show separate plane-A and plane-B chunk edits and a plane-B
pattern edit changing rendered tiles. For the initial views of the first three
stages, a plane-B click resolves through the static 512-pixel VRAM ring; a Stage
2 click past X = 512 reaches the source cell at the wrapped coordinate. The
highlight marks every visible copy of that source cell in the editor viewport.
The stage reference guard checks the affected slots across every horizontal
960x288 editor page at Y zero, comparing new reads with the source-owned
baseline. It checks both numeric limits and the final RAM writer of each coarse,
chunk, and pattern value. `validate-content` rejects new unowned reads before
staging; the live brush rolls back its map value and scene. This is not a proof
for other vertical positions or procedural cameras.

Painting writes raw map values and does not identify art. Plane-B reachability
outside the first views, reference bounds at other vertical positions and the
descriptors of exceptional stages are still open. Unsaved edits in the other
Studio are not seen until they are saved and refreshed.
