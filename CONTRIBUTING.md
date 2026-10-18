# Contributing

This is a preservation project. The measure of every change is that the build
still reproduces the original cartridge byte for byte.

## From a fresh clone

```bash
# Place the original cartridge dumps in the project root:
#   Alien Soldier (J) [!].bin
#   Alien Soldier (E) [!].bin
make init PROFILE=jp   # Validate the ROM, extract data, build and verify
make init PROFILE=eu
make release-check     # The full ordered check, as a release runs it
```

`make init` writes the extracted segments into `data/`. Nothing derived from
the cartridge is ever committed; `.gitignore` keeps it out.
[Release verification](docs/release_check.md) lists what the full check runs.

## Before you commit

```bash
make format   # Normalize assembly style; it must never move a byte
make lint     # Source policy, naming, branch targets and text hygiene
make test     # Every test module
make verify-all   # Byte identity against both cartridge dumps
```

`make verify-all` is not optional after any change under `src/`, including a pure
rename. Formatting and renaming are byte-neutral by definition, so a divergence
means the change was not what it appeared to be.

## Naming a symbol

Read [`docs/naming.md`](docs/naming.md) first. In short:

- A name is owned by one of the declared subsystems in
  `config/source_policy.json`, derives from a symbol that exists, or is a
  declared hardware exception. `make lint` rejects anything else.
- An address is never an identity. If you cannot support a semantic name with
  static or runtime evidence, give the symbol an honest role-neutral name and
  add an entry to [`docs/unknowns.md`](docs/unknowns.md).
- Renaming a definition keeps its `; was:` provenance marker and adds or updates
  its exact-address record in `config/name_audit.json`, with the evidence that
  justifies the new name.
- Rename references atomically, with `scripts/rename_symbols.py`, and run
  `make verify-all` afterwards.

A wrong semantic name is worse than an explicit unknown.

Every `jsr`, `jmp`, `bsr`, `bra`, `dbf` and conditional branch written against a
symbol must resolve to a definition in the source. `make lint` reports the count
it resolved and fails on the first one it cannot, so a rename that misses a call
site is caught before the assembler decides what to do about it.

## Commit messages

English, with a title that names the result concretely and does not end in a
period. `Fix`, `Update` and `WIP` are not titles.

After the title and a blank line, write two or three paragraphs:

1. what changed and which subsystems it touched;
2. why, and what it makes possible or what it fixes;
3. how it was checked.

The body describes the actual diff.

One commit is one architectural or release task. Empty commits are not used for
any purpose, including release markers: the release is an annotated tag on a
commit that really changed something.

## What not to do

- Do not commit the cartridge, anything extracted from it, or a built image.
- Do not weaken a threshold in `config/` to make a gate pass.
- Do not use the older analysis commands listed in
  [`docs/tooling_status.md`](docs/tooling_status.md) as evidence; they predate
  the split into modules and mutate a single translation unit.
- Do not let documentation claim more than the source, the tests and the runtime
  evidence support.
- Do not edit `src/` or `data/` from a content tool; edits go through the
  workspace in `content/workspace/` and are built into `build/content/`.
