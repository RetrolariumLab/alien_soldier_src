# Alien Soldier source reconstruction

Assembly source for Treasure's Alien Soldier (Mega Drive, 1995). One shared,
address-ordered 68000 source reproduces both the Japanese and the European
cartridges byte for byte, and the Z80 sound program inside them is assembled
from its own source. Every pointer is symbolic, so code and data can move.

Source Reconstruction 1.0 (tag `source-reconstruction-1.0`) rebuilt the Japanese
cartridge. 2.0 adds the European cartridge, the Z80 source and fixed-format
content editing: twenty data formats with headless models and five Tk Studios
that build an edited ROM without touching the preservation source.

## Build and verify

Put your own dumps of the original cartridges in the project root:

- `Alien Soldier (J) [!].bin`
- `Alien Soldier (E) [!].bin`

ROMs, extracted data and edited outputs are private and never go into Git. The
AS assembler and `p2bin` are vendored in `bin/` and hash-pinned in
`config/toolchain.json` ([tool provenance](bin/README.md)).

```text
python -m pip install -r requirements-dev.txt
make init PROFILE=jp      # extract the data from the Japanese dump, build, verify
make init PROFILE=eu      # the same for the European dump
make verify-all           # both cartridges, byte for byte
```

`PROFILE=jp` is the default. Initialize only the profiles whose dumps you have;
[regional profiles](docs/region_profiles.md) lists the exact identities.

## Checks

```text
make lint                # assembly style, source policy, project hygiene
make test                # every test module, eight at a time (about two minutes)
make verify-relocation   # move code and data; every pointer must follow
make verify-symbols      # export and check the debugger symbols
make check-content       # every content model and Studio against both cartridges
make release-check       # all of the above from a clean build, plus the game in Gens
```

`make release-check` also replays twelve Japanese scenarios in the pinned Gens
build and boots the European cartridge to its attract demo. It needs the
[gens_automation](https://github.com/oranguthang/gens_automation) emulator at
the pinned commit (`GENS_DIR=...`); see
[release verification](docs/release_check.md).

## Edit content

The Studios edit an ignored workspace in `content/workspace/<profile>/`, never
`src/` or `data/`, and build the edited ROM into `build/content/`.

```text
make level-studio STAGE_INDEX=0
make graphics-studio GRAPHICS_PAYLOAD=0
make screen-studio SCREEN_ID=title_background
make text-studio
make sound-studio
make build-content
make playtest-level PLAYTEST_STAGE=1
```

Add `CONTENT_PROFILE=eu` to work on the European cartridge.
[Content authoring](docs/content_authoring.md) describes the formats, their
fixed capacities and what is not editable yet.

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
- [Gens automation](https://github.com/oranguthang/gens_automation)
- Inspired by
  [lab313ru's Quackshot disassembly](https://github.com/lab313ru/quackshot_src/)

## License

This is a work of reverse engineering for educational and preservation purposes.
The original game is copyright Treasure and Sega. This repository grants no
license to the game itself.
