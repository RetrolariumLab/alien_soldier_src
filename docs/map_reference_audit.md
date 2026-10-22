# Map-reference audit

`make check-map-references` (part of `make check-content`) checks that every map
read of every static stage and screen plane lands on loaded data that an asset
list wrote. It runs:

```text
python scripts/authoring/check_map_references.py --profile all
```

The atomic JSON report is written to ignored
`build/content/map-reference-audit.json`. `--profile jp` or `--profile eu`
selects one region. A custom `--output` must remain a JSON file under
`build/content`; the gate cannot replace a source file or workspace document. No
ROM build, emulator, image rendering, asset mutation, or workspace staging is
involved. A missing source payload, configuration, descriptor, unavailable
scene, malformed RAM range, or accepted negative probe fails the command.

## Scope and exclusions

Each region inventories 50 raw static descriptor planes: 46 stage planes and
four planes from the three supported screen compositions. All 26 stage slots are
accounted for, but this is not a claim that all 26 have reproduced static
backgrounds:

- Stage-table indices 17 and 18 exclude both planes. Their exact existing
  `planes_not_reproduced` explanations are retained in the report. Their planes
  are driven by `Stage18_UpdateScrollAndRenderTilemap` and
  `Tilemap_PopulateStage18UnqueuedColumn`, rather than this static replay.
- Mode-zero stage planes 16A and 22B are constant fills with no map reads.
- Thirteen static nonzero descriptors have no loaded chunk/pattern route. They
  are still inventoried, with `loaded=false`, actual asset lists, RAM ownership
  and gaps. This includes slots 20–22, which load shared data only. They are not
  silently counted as supported drawable previews.
- Secondary planes 7B and 8B are audited and retained by the bounded renderer,
  despite sharing the primary plane's source maps. Independent camera origins do
  not imply a different source payload, nor do they establish later runtime
  scroll/raster fidelity. Their already indexed primary-descriptor sources keep
  the existing schema-2 workspace provenance without redundant uses.
- Title contributes A and B; options contributes B; story contributes A. The
  absent options A and story B are recorded as constant fills. The eleven
  unsupported Screen Studio routes retain their configured reasons, including
  procedural, timed-text, sprite, raster and transition behavior.

Stage modes, descriptor choices and secondary Y offsets come from current source
configuration through `read_once`, `scene` and `plane_descriptor`, not
stage-number guesses. The screen model receives the actual selected profile. In
particular, EU title B has a +16 map Y offset while JP has zero. The report
records the configured build defines (`[]` for JP, `BuildProfileEU=1` for EU)
without claiming that this source-reading gate assembles a ROM. Its map payloads
are checked against the corresponding preservation asset manifest; 54 unique RAM
sources are recorded per region. Current map assets are shared, so matching
regional counts are expected, not evidence that both entire ROMs are identical.
Workspace or staged edits are not substituted for this canonical baseline.

## What is counted

The source descriptor's complete 8192×8192 periodic domain contains 1,024 coarse
cells, 65,536 coarse-to-chunk links and 1,048,576 pattern-word reads per plane.
These are tile-word positions, not pixels or observed camera positions. The
implementation folds repeated chunk and pattern facts; it does not render a
million-pixel picture.

Every tile read belongs to exactly one category, using first-failure graph
order:

1. coarse byte has no final asset-list writer;
2. coarse value addresses an unloaded chunk;
3. chunk byte has no final asset-list writer;
4. chunk value addresses an unloaded pattern;
5. pattern word has no single final asset-list writer;
6. valid: all three reads are loaded and owned.

Writer IDs reflect transfer order, including overlapping later transfers. Both
bytes of a pattern word must have the same final writer; a one-byte overwrite
therefore makes the word unowned. The report retains transfer ranges and their
remaining owned byte counts. "Final writer" here means the last asset-list RAM
transfer, not an assertion that no later game instruction ever writes that RAM.
The screen model's proved title post-load index transforms are applied before
inventory while retaining their asset-source ownership.

Each plane records SHA-256 digests of RAM, writer ranges and the folded graph.
The graph digest includes descriptor/Y-offset metadata, source values and
ownership. The combined inventory digest binds the detailed report. Counts alone
would not detect a valid-to-valid pattern-word edit; the graph/RAM digests do.

Canonical gaps are an inventory, not newly forbidden original content. The gate
does not infer whether a periodic coordinate is reachable in gameplay, whether a
gap is unused, or whether procedural runtime writes fill it later.

## The canonical result

Each region accounts for exactly 52,428,800 pattern-word reads across its 50
descriptors:

| Category             |         JP |         EU |
| -------------------- | ---------: | ---------: |
| Valid                | 31,914,028 | 31,914,028 |
| Unowned coarse byte  |  5,242,880 |  5,242,880 |
| Unloaded chunk       | 10,175,488 | 10,175,488 |
| Unowned chunk byte   |    252,928 |    252,928 |
| Unloaded pattern     |        112 |        112 |
| Unowned pattern word |  4,843,364 |  4,843,364 |

Totals per region are 10,175,600 unloaded and 10,339,172 unowned reads. Those
numbers must not be interpreted as a milestone completion percentage or as that
many broken pixels in the game.

The two regions differ only in digests, not counts: the European title B plane
has a +16 map Y offset.

## Negative probes

Each descriptor supplies a source-valid witness if one exists. The gate makes
one private 64 KiB RAM clone at a time, changes only one owned coarse or chunk
byte, and requires `periodic_reference_error` to reject the newly invalid read.
No extracted asset, compressed stream, source configuration or writer record is
edited. Existing source-invalid coordinates are not reclassified as new editor
damage.

Per region, 71 probes were rejected as required. The 29 explicitly
non-applicable cases are:

- 26 probes on the thirteen descriptors with no source-valid read;
- three chunk probes whose full 8-bit target domain retains the selected
  source-valid word, so inventing an "invalid" target would be dishonest.

Each applicable probe records the changed RAM address, old/new byte and exact
guard error. Coarse probes prefer the last source-valid coarse cell, exercising
the full periodic domain beyond a normal starting viewport. A shared chunk byte
can affect several world coordinates; the first reported failure need not equal
the witness coordinate.

`tests/test_map_reference_audit.py` covers partial ownership, unloaded targets,
split word writers, shared secondary descriptors, output-path safety and a
deliberately broken guard that accepts a mutant.
