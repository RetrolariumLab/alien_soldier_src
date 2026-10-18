# Screen Studio

Screen Studio edits the maps behind three static compositions: the title
background (planes A and B), the options background (plane B) and the story
background (plane B). `make check-screen-model` rebuilds each 320x224 view for
both cartridges from the real asset lists, transfer descriptors, compressed RAM
and VRAM payloads and palette commands; no screenshot is used as data.

## The three compositions

**Title.** Both title planes are uploaded at source Y zero; only afterwards
does the European cartridge set the primary camera Y to -16.
`Scroll_PreparePlaneBuffersAndRegisterShadows` negates that value and the VDP
adds VSRAM to the raster line, so the Japanese title reads plane A at Y zero and
the European one at Y +16, while plane B stays at zero. The manifest keeps the
camera value -16; `screen_view_y` gives the separate lookup origins, so drawing,
picking and highlights agree. Source guards refuse changes to the zero-origin
uploads, the European camera write or the scroll negation rather than guessing
a new route.

The title also replays both post-load tile-index passes of
`TitleScreen_FinalizeInitialization`: 624 words at `$FFFF4020` through
`Gfx_AdjustTileIndexRows`, then 3,072 words at `$FFFF2020` through
`Gfx_UpdateTilemapIndices`. They change the rendered view and the preview; the
document keeps the original compressed values. The seven double-height title
strings (four placed by the initializer, three menu entries placed every
update) are text, not background, and are not drawn.

**Options.** The options asset list has no terminator of its own: the reader
stops on the negative first word of the adjacent `Options_OnLabelTiles`. That
dependency is explicit in `config/authoring/screens.json`, and the model stops
on the same word.

**Story.** The static story background is physical plane B, through
`Gfx_ScrollVRAMTransferParameters` as selected by
`StoryScreen_FadeInAndStartScroll`. Its RAM map pointers equal the default
descriptor's, but it transfers to `$6000` (VRAM `$E000`) instead of `$4000`
(`$C000`). The scrolling story text on the primary camera is not part of it.

The views leave out runtime text, cursors, values, sprites, fades, palette
animation, raster effects and transitions. Eleven complete screens are listed
as unsupported, each with the procedural or timed reader that prevents a
static view: Sega intro, complete title, complete options, password, complete
story, post-stage results, final results, continue, weapon setup, Game Over
and credits.

## The document

`content/workspace/<profile>/screens/maps.json` holds the eight LZSS RAM-map
streams these compositions read: 5,800 pattern words, 896 chunk bytes and
2,048 coarse bytes (8,744 values in 14,544 decoded bytes). Roles, lengths,
owners and compressed slots are fixed; a changed stream is recompressed only
in the staged content tree and refused if it no longer fits its slot (4,836
bytes in total). Four streams are binary includes and four inline assembly.

Several streams are also read by results, credits, transitions, cutscenes and
gameplay stages, so the document lists every asset list that consumes each of
them. `SharedMappingData7000` is shared with a Level Studio stage map: the two
documents may not propose different bytes for it ([stage maps](stage_map_model.md)).

Older documents that name plane A for the story streams can be migrated to a
new file, keeping every value, and adopted after review:

```text
make migrate-screen-workspace CONTENT_PROFILE=jp
```

The command writes `build/content/<profile>/story-plane-migrated.json` (or
`MIGRATION_OUTPUT`) and refuses to overwrite an existing file. A stale document
keeps failing validation until a migrated one replaces it.

## The window

```text
make screen-studio CONTENT_PROFILE=jp SCREEN_ID=title_background
```

Choose a composition and one of its map streams. A 256-pixel grid shows one
unit of the stream at a time (4x4 patterns, 8x8 chunks or 32x32 coarse
values) as raw grey values; clicking selects a cell and, with Paint on, writes
the brush value after validating the whole document. `Pick map from
static-screen preview` instead resolves a click on the rendered image through
the chosen plane and layer to the last source-owned RAM writer, and outlines
its 8-, 32- or 256-pixel footprint. An absent plane, an undefined read, a
split transfer or a writer that is not a map is refused.

Refresh copies the source under `build/content/screen-preview`, applies the
current compressed art, palettes, the saved Level Studio stage maps and the
in-memory screen maps in content-build order, renders, and caches the decoded
RAM transfers. Later map edits replay those transfers in memory and redraw only
the composition; reverting a cell restores the original image. Differing edits
to a shared stream are refused before rendering or saving. Unsaved edits in a
Level Studio window are not seen until saved and refreshed. Save, Reload, Build
and Close follow [the common Studio actions](workstation_actions.md).

## The reference guard

Every edit is checked against the canonical scene of its profile: a new coarse
reference may not point past loaded chunks, a new chunk reference past loaded
patterns, and no map read may hit RAM without a final asset-list writer; a
pattern word split across two transfers fails too. The check uses the real
camera origins and plane-B parallax, including partial edge tiles, and then
compares every source-valid read across the whole 8192x8192 periodic map space
of both planes. Existing gaps in the original are left alone. Only compositions
that load an edited stream are replayed. The workstation and `validate-content`
both run it ([map reference audit](map_reference_audit.md)).

## Checks

`make check-screen-model` and `make check-screen-workspace` rebuild the views
and round-trip both workspaces unchanged. `make check-screen-studio` loads both
profiles without a window, picks and edits a story chunk, and checks that the
in-memory result equals a fully staged build of the same edit. The widget tests
open hidden Tk windows.

Title and options art use the command-three bit-token codec
([tile codec](tile_codec_spec.md)); the map streams use LZSS.
