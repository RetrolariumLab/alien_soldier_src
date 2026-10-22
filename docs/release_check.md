# Release check

`make release-check` runs everything a release needs, in order, and stops at the
first failure:

01. the extracted data of both cartridges against their manifests
    (`make check-assets PROFILE=jp` and `PROFILE=eu`);
02. `make lint`: assembly style, naming vocabulary, provenance markers, branch
    targets and text hygiene across every tracked text file;
03. `make test`: every test module;
04. `make clean`, so that nothing below can be satisfied by an old output;
05. `make verify-all`: the Z80 program, then both cartridges, each byte for byte
    with its layout checked, including the 128 KiB DMA source boundary that the
    emulator cannot see;
06. `make verify-symbols verify-relocation` for each cartridge: the debugger
    symbols, and a rebuild with the layout perturbed in which every pointer has
    to follow its target;
07. `make check-content-zero-edit`: an unedited content workspace must build
    both original cartridges;
08. `make check-content`: every content model, workspace and Studio check
    against both cartridges;
09. `make runtime-capture`: the twelve Japanese scenarios of
    `config/runtime_scenarios.json`, replayed from three movies in the pinned
    Gens build, with 78 named RAM expectations checked
    ([runtime verification](runtime.md));
10. `make check-region-runtime-eu`: the European cartridge boots from cold,
    idles on the title screen and runs its attract demo, with the console region
    flags set to Europe.

Steps 9 and 10 need the
[gens_automation](https://github.com/oranguthang/gens_automation) emulator at
the commit pinned in `config/toolchain.json`; point `GENS_DIR` at its checkout.
Everything before them needs only Python, the vendored assembler and the two
cartridge dumps.

`make clean` removes the assembler outputs, the source inventory and the exact
PNG/state pairs of the runtime scenarios. It keeps the cartridge dumps, the
extracted data, movies, traces, workflow files, research captures and the
content workspace.

The check does not create or move a tag. Tagging and publishing are separate
steps.
