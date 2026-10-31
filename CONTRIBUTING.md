# Contributing

This is a preservation project. The measure of every change is that the build
still reproduces the original cartridges byte for byte.

## From a fresh clone

```bash
# Place the original cartridge dumps in the project root:
#   Alien Soldier (J) [!].bin
#   Alien Soldier (E) [!].bin
make split              # Cut the data out of both ROMs into data/
make verify-revisions   # Build both and compare them byte for byte
make hooks              # Once per clone: Git checks stop words and runs make lint
```

`make split` writes the extracted segments into `data/` by
`assets/manifest.json`. Nothing derived from the cartridge is ever committed;
`.gitignore` keeps it out. Retrolarium Kit (`rltool`) builds, splits and checks;
the repository holds no assembler.

## Before you commit

```bash
make format   # Normalize the assembly layout and format the rest; it must never move a byte
make lint     # The shared linter
make test     # Unit tests, both ROMs byte for byte, the moved build, the studio check
```

`make verify-revisions` is not optional after any change under `src/`, including
a pure rename. Formatting and renaming are byte-neutral by definition, so a
divergence means the change was not what it appeared to be. After a change that
moves code, run `make test-full` too: it plays the attract run in MAME on the
build with every procedure moved and compares the game's RAM with the
original's.

For data-format changes, update [the format guide](docs/data_formats.md) with
the reader, binary layout, editable fields and capacity or round-trip limits.
The [3.0 release scope](README.md#release-scope) retains the current checks; the
full MAME scenario migration and further test simplification are 3.1 work.

## Naming a symbol

Read [`docs/naming.md`](docs/naming.md) first. In short:

- A name is owned by one of the subsystems the source already uses, derives from
  a symbol that exists, or is a hardware exception.
- An address is never an identity. If you cannot support a semantic name with
  static or runtime evidence, give the symbol an honest role-neutral name and
  add an entry to [`docs/unknowns.md`](docs/unknowns.md).
- Renaming a definition keeps its `; was:` provenance marker; say in the commit
  what evidence justifies the new name.
- Rename references atomically and run `make verify-revisions` afterwards.

A wrong semantic name is worse than an explicit unknown.

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

- Do not commit the cartridges, anything extracted from them, or a built image.
- Do not let documentation claim more than the source, the build and the
  recorded runs support.
- Do not add editing tools here: the game's content is edited in Retrolarium
  ([editing in Retrolarium](docs/retrolarium.md)).
