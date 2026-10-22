# Source layout

`src/main.s` is the cartridge assembly entrypoint. AS processes it as one
translation unit, so the ordered `include` list is also the ROM layout; there is
no linker or linker script.

The standalone `src/sound/z80/driver.asm` entrypoint assembles the shared
3,072-byte DAC program loaded at Z80 address zero. Its reset/PCM routines,
voice-stream routines, memory aliases and four fixed lookup pages have separate
source owners in `src/sound/z80/`. Cartridge and staged content builds consume
the generated `build/z80/driver.bin`, never the extracted executable as source.
`make verify-z80-source` independently checks that output against the private
preservation reference; the cartridge layout check also binds it to the original
asset census. See [sound driver](sound_driver.md).

The ranges, subsystem ownership, fixed landmarks, padding gaps, and maximum
module size are declared in `config/rom_layout.json`. Run `make verify-layout`
to compare that declaration with the assembler listing, module files, and built
ROM. `make verify` runs this check after the byte-identity build.

## Module size policy

The Source Reconstruction 1.0 layout is normally 200-700 lines per cohesive
module, with a default hard ceiling of 1,000 lines. The sole possible exception
is one concrete boss whose state machine and private data cannot be split
without harming readability. Exceptions are reviewed individually. See
`docs/modularization_plan.md` for the migration rules and measured baseline.

The 1,000-line ceiling is set in `config/rom_layout.json`, and `make lint`
checks every declared module against it.

At the Source Reconstruction 1.0 snapshot, the 17 modules above the preferred
700-line target were all concrete boss modules (703–869 lines); none exceeded
the hard ceiling. Their length alone is not grounds for another split: a
proposed boundary must isolate a coherent state family or private-data owner
without separating a procedure from its tables. The size inventory is a review
queue, not a waiver for unexamined semantics.

The only module now above 900 lines is
[`src/bosses/entity_type_1c0_core.s`](../src/bosses/entity_type_1c0_core.s), at
922\. Its dormant type-$1C0 controller, body-part recipe, angle data and the
family-shared readers next to them stay together in ROM order; it is still under
the 1,000-line ceiling.

The former 889-line `ui/options_screen.s` had a real ownership boundary at ROM
`$009F8E`: both options-menu controllers and their selection table end before
the shared BCD/DMA, cursor, and UI asset helpers begin. The ordered
`options_menu_controllers.s` and `options_shared_helpers_and_assets.s` modules
preserve that exact byte sequence at 560 and 329 lines respectively. In
contrast, the long player sprite-mapping family remains together because a
line-count-only split would obscure its shared consumer.

The transition dispatcher and the asteroid, Destroyer Proto, Shield Viper, and
Wolf Garopa entry states now end at ROM `$00F7F9`. The Missiray, Stage 24, and
Z-Leo entry states begin at `$00F7FA` in `missiray_stage24_z_leo_transitions.s`.
This is a complete function boundary; both modules are inside the preferred band
at 583 and 278 lines.

The ship-arrival timeline, pattern reveal, and their private graphics tables
remain together in a 644-line `ship_sequence.s` module. The ROM boundary at
`$008F90` starts the separate piece/debris spawning scripts and object update
handlers in `ship_piece_and_debris.s`. That module is 167 lines, below the
preferred band because the actor family is complete there; merging unrelated
timeline helpers into it would hide the ownership boundary.

The stage-entry and time-bonus states, radial-text renderer, and their shared
helpers occupy the 544-line `stage_message_sequences.s` module. The boundary at
ROM `$00B43E` separates a 213-line message-script bank containing battle banner
descriptors, boss/ship script selectors, glyph lists, and encoded scripts. It is
`message_scripts_and_glyph_lists.s`; the encoded script bytes remain untouched.

Definition-only `.inc` files are outside this limit. They will receive their own
structure and policy as the RAM and hardware maps mature.

## Naming confidence

Directory names identify the best-supported broad subsystem. Existing mixed and
address-derived filenames are migration debt, not a naming convention. Release
1.0 permits neither ROM-address filenames nor containers such as
`boss_code_31540.s`; uncertain code receives a role-neutral concept name until
stronger evidence supports a narrower identity.

Many symbol descriptions were generated during an earlier automated pass and
must be treated as hypotheses. Existing `; was:` annotations retain the IDA name
as provenance. A semantic name may be corrected whenever stronger static or
runtime evidence appears; byte identity, references, documentation, and the
unknowns register must be updated together.

## Padding is alignment

The `$FF` gaps between regions are not filler. The VDP latches the upper bits of
a DMA source address, so a transfer crossing a 128 KiB boundary wraps to the
start of that block instead of continuing, and the cartridge is laid out so that
no transferred payload straddles one: all 289 uncompressed art payloads sit
inside a single block. The `org` directives that skip those gaps are what holds
that arrangement.

`config/rom_layout.json` declares the rule in `dma_alignment` and
`make verify-layout` enforces it with a ceiling of zero. Compressed art is
exempt, because the 68000 expands it rather than the VDP transferring it; three
`artcomp` payloads cross a boundary in the canonical image and always have.

The pinned Gens DMA loop masks the ROM source once before incrementing it,
rather than wrapping it inside the 128 KiB block as hardware does. Runtime RAM
checks cannot replace this static invariant: a crossing corrupts VRAM and can
remain invisible in that emulator. The old cached-entity-pointer explanation was
superseded; relocation by the exact padding displacement is expected, not
evidence of a stale pointer.

Two directives in the source are alignment for the same kind of reason and must
not be treated as decoration either: `align $8000` before the PCM banks keeps
them on the 32 KiB granularity the Z80 bank register selects, and `align0 2`
keeps word data even. Both survive relocation on their own; the `org` gaps do
not, because they encode absolute positions.

## Pointers are checked by moving the layout

A reference the assembler owns moves when the layout moves. A value written as a
literal does not. `make verify-relocation` separates the two by rebuilding the
ROM twice with the layout perturbed, under `build/relocation/`, and requiring
every reference to follow. Nothing under `src/` is touched and no emulator is
involved: the perturbed entrypoint and the files it replaces are generated and
assembled from the output directory.

Two perturbations are declared in `config/rom_layout.json`:

| Probe     | What moves                                                                                                                                      | What it tests                                                                |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `content` | Every padding gap grows by whole DMA blocks, so all content moves                                                                               | References to data, with the DMA alignment invariant deliberately held still |
| `code`    | Unreachable `nop`s are inserted inside the code region, so code labels move relative to one another while the `org` directives hold the content | References to code, and the relative offsets between code labels             |
| `returns` | Every safe `rts` is duplicated, so every procedure moves relative to every other one                                                            | That the source still assembles with the whole code region rearranged        |

The filler for `returns` is a second `rts` rather than a `nop` for a reason
worth stating. A `nop` costs four cycles, and four cycles anywhere move the
frame counter, which desynchronises a recorded movie on a ROM that plays
perfectly by hand — a failure that looks exactly like a broken pointer and is
not one. A second `rts` after an existing one is unreachable by construction and
free. It is not inserted after every `rts`: five in the tree are the first entry
of a branch table of two-byte instructions reached by `jmp Table(pc,d0.w)`,
where an extra entry shifts every later mode, and those are told apart by what
follows them — a return is followed by a label, a table slot by another
instruction.

A value that equals the address of a symbol which moved, and that did not move
with it, is reported. Both defects found this way were the same shape: a 32-bit
address encoded as two `dc.w` constants, in the stage tile asset command lists
and in `EntityType1C0_BodyPartInitTable`.

Precision is the hard part, because with fifteen thousand symbols a four-byte
window matches one by accident often. Four rules cut that down, each stated
rather than tuned: a window that runs past the statement that emitted it is
reading across two statements; a word- or byte-sized instruction cannot carry a
32-bit address; a site authored as a symbol is relocated by the assembler and
cannot be stale; and bytes inside a `binclude` payload are opaque, so nothing
about the source follows from them. What survives is listed in
`accepted_coincidences` with the reason it is a number rather than an address.

The probe cannot detect a pointer that carries flags in its high bits by a plain
equality search. `EntityType1C0_BodyPartInitTable` had 24 such entries encoded
as `dc.w` pairs. They are now `dc.l` expressions with symbolic bases, without
changing ROM bytes. The reader consumes longwords, so the table's source width
must match it; see `docs/dormant_entity_1c0.md`.

A reader-first triage also checked direct `lea`/`movea` table loads followed
locally by longword reads, plus direct calls that pass the table register to a
longword-reading callee. Eight local and 24 cross-call sites started with
`dc.w`/`dc.b`; the reviewed examples are mixed-width records or word tilemaps
copied four bytes at a time. In particular, `Object_InitGroupFromTable` starts
each descriptor with a word and two bytes, then copies two long fields; an
initial `dc.w` is expected. This bounded scan is not an exhaustive pointer
proof: each long field must still be classified by its consumer before being
rewritten as a relocatable address.

## Adjacent data as a loader stop word

`Options_AssetLoadDescriptors` contains five records but has no explicit `$FFFF`
terminator. `LoadObjData` reads the next word and returns when it is negative;
that word is `$8332`, the first entry of the immediately following
`Options_OnLabelTiles` table. The title asset list, in contrast, has eight
records and its own `$FFFF`. Do not separate the options list from its following
table or change that first word without adding an explicit negative stop word.
The records have a type, source pointer, and destination word; tag 6 is
`LoadCompressedToRAM`, so not every destination is VRAM.

## Editing rules

- Keep module includes in ascending ROM order.
- Do not place emitting directives directly in `src/main.s`.
- Do not hide layout changes behind an `org`; declare intentional gaps.
- Run `make verify` after moving code, data, or includes.
- A source rename is not evidence by itself. Record how a semantic claim was
  established before treating it as confirmed.
