# Naming contract

Names describe behavior only as strongly as the available evidence permits. The
source originated in an automated interpretation pass. Current spelling and
confidence must be read from the exact-address evidence registry, not inferred
from that origin or from a name that sounds plausible.

## Rules

- Prefer `Subsystem_ActionObject` for behavior with direct evidence, for example
  `Sound_LoadZ80Driver`.
- During migration, leave an existing address-derived name unchanged until its
  references have been reviewed. Release 1.0 contains no live address-derived
  identifiers: unresolved definitions receive stable role-neutral names and a
  corresponding unknowns-register entry. A wrong semantic name is worse than an
  explicit unknown.
- Use a broad role-neutral concept name for a module whose exact ownership is
  not yet established. ROM addresses and containers such as `bank` or
  `boss_code` are not module identities.
- Preserve the original IDA symbol through its `; was:` provenance mapping when
  renaming a definition.
- Record corrections to earlier generated semantic names, including their
  evidence basis, in `config/name_audit.json`.
- Rename all references atomically and require `make verify` afterward.
- Do not infer behavior solely from a caller name that is itself provisional.

## Subsystem vocabulary

Every definition in assembly source must satisfy one of three rules, which
`make lint` checks:

- the name is owned by a declared subsystem, which is the segment before the
  first underscore or, for a name without one, its leading capitalised word;
- the name derives from a symbol that exists, as `Owner_Detail` derives from
  `Owner` and `Block_End` from `Block`;
- the name is a declared hardware exception.

The vocabulary is the `naming.subsystem_vocabulary` list in
`config/source_policy.json`. It is closed: a name owned by a token that is not
on the list fails lint until the token is added deliberately. The list was
adopted from the reviewed state of the source at Source Reconstruction 1.0
rather than designed in advance, so it records which subsystems this program
actually has.

The hardware exceptions are the definitions in `src/equals.inc`, `src/ports.inc`
and `src/ram_addrs.inc`, which name the machine rather than the program, plus
two sets named by their formats: the twelve 68000 exception vector targets
referenced from `Sys_VectorTable`, which keep the name of the vector they serve,
and the Mega Drive cartridge header fields, which keep the name the header
format gives them.

## Evidence levels

- `unknown`: no supported semantic claim.
- `hypothesis`: plausible static interpretation; not independently verified.
- `static`: supported by instructions, data flow, and call sites.
- `runtime`: observed through a named emulator scenario or trace.
- `confirmed`: supported by independent static and runtime evidence, or by an
  authoritative hardware/data-format specification plus matching behavior.

Descriptions and maps must state the level when a reader could otherwise mistake
a hypothesis for a confirmed fact.

An evidence value alone is not proof: its basis must identify the instruction,
field, table, caller or observation supporting the exact record. make
semantic-audit reports review queues; repeated wording is not by itself wrong,
because one proved table format may legitimately have many members.
config/duplicate_basis_reviews.json records accepted uniform groups with exact
addresses, names, modules and reasons. Membership drift reopens review.

The full 1.0 investigation record stays in `docs/unknowns.md` at the
`source-reconstruction-1.0` tag; the active VIS/CODE/DATA entries are in
[unknowns](unknowns.md). Static role evidence does not establish a visual boss
identity; a resolved name can coexist with unobserved artwork or entry paths.

## Mechanical style

- Global labels and EQU definitions begin in column zero; instructions and
  directives remain indented.
- `src/main.s` owns cartridge module includes. The separate Z80 assembly
  entrypoint owns its own CPU-specific includes; see
  [source layout](source_layout.md).
- Source paths are lowercase and source files end with a newline.
- Assembly lines are at most 200 characters. This accommodates imported XREF
  comments without allowing generated annotations to grow without bound.

The preservation subset of these rules is currently enforced by `make lint`. The
stricter destination and its migration order are described in
`docs/modularization_plan.md`. Passing mechanical style checks never establishes
semantic confidence in a label.
