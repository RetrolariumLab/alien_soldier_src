# Alien Soldier source reconstruction

Assembly source for Treasure's Alien Soldier (Mega Drive, 1995). One shared,
address-ordered 68000 source reproduces both the Japanese and the European
cartridges byte for byte, and the Z80 sound program inside them is assembled
from its own source. Every pointer is symbolic, so code and data can move.

Source Reconstruction 1.0 (tag `source-reconstruction-1.0`) rebuilt the Japanese
cartridge. 2.0 added the European cartridge, the Z80 source and fixed-format
content editing. In 3.0 the editing moved to Retrolarium: the game opens in
Retrolarium Studio and Kit through `alien_soldier.rlj`. 3.1 keeps only what
builds and checks the source: both ROMs byte for byte, a build with every
procedure moved, and a recorded run in MAME on it.

## Build and verify

Put your own dumps of the original cartridges in the project root:

- `Alien Soldier (J) [!].bin`
- `Alien Soldier (E) [!].bin`

ROMs, extracted data and edited outputs are private and never go into Git. The
build needs Python and [Retrolarium Kit](https://github.com/Retrolarium)
(`rltool` on `PATH`, or `RLTOOL=...`), which brings the AS assembler and
`p2bin`.

```text
make split               # cut the data out of both ROMs, once
make verify-revisions    # both cartridges, byte for byte
```

`make build` and `make verify` take `REVISION=eu` for the European cartridge
(`jp` is the default); [revisions](docs/revisions.md) lists their identities and
what differs.

## Checks

```text
make lint                # assembly layout and the shared formatters
make test                # unit tests, both ROMs, the moved build, the studio check
make test-full           # test, then the attract run in MAME on the moved build
make play                # watch that run in a MAME window
```

`make test-full` and `make play` need MAME (`MAME=...`, or the one
`rltool movie mame` remembers); [the movies](movies/README.md) describes the
run.

## Edit content

Alien Soldier is edited in [Retrolarium Studio](https://github.com/Retrolarium):
open `alien_soldier.rlj` and choose a revision. The studio copies this
repository into the ignored `.retrolarium/<revision>/` and rebuilds the edited
ROM from the source; [editing in Retrolarium](docs/retrolarium.md) lists what it
edits.

## Find your way around

- `src/main.s` is the cartridge's include order.
  [Source layout](docs/source_layout.md) explains the modules, the standalone
  Z80 program, DMA alignment and what may move;
  [the subsystem map](docs/source_map.md) gives the architecture.
- [RAM map](docs/ram_map.md), [naming](docs/naming.md) and
  [unknowns](docs/unknowns.md) cover names, evidence and open questions.
- [Sound driver](docs/sound_driver.md) explains the 68000 and Z80 halves.
- [The documentation index](docs/index.md) lists everything else;
  [contributing](CONTRIBUTING.md) describes the change workflow.

## Credits

- Original game by Treasure (1995)
- Disassembly work using IDA Pro
- Alien Soldier SMPS/Treasure format research and sound data mapping by Valley
  Bell and the
  [SMPS Research project](https://github.com/sonicretro/smps-rips/tree/master/68k/Alien%20Soldier)
- AS Macro Assembler by Alfred Arnold
- [Gens automation](https://github.com/oranguthang/gens_automation), with which
  the earlier releases were researched and the movies recorded
- Inspired by
  [lab313ru's Quackshot disassembly](https://github.com/lab313ru/quackshot_src/)

## License

This is a work of reverse engineering for educational and preservation purposes.
The original game is copyright Treasure and Sega. This repository grants no
license to the game itself.
