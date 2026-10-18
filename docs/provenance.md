# Source provenance

The canonical input identity is recorded in `assets/manifest.json`; tool binary
identity and origin are recorded in `config/toolchain.json`.

The assembly initially carried 4,822 unique mappings from the current symbol to the
original IDA-generated name. They use `; was: sub_...`, `loc_...`,
`locret_...`, or `nullsub_...`. In 298 cases the historical annotation is on
the first instruction after the owning label, which is how the earlier rename
tool wrote it. `scripts/lint_source.py` deliberately associates such a marker
with the most recent definition and checks that both sides remain unique.
Reviewed RAM renames add mappings such as `; was: word_FFA284`, so the checked
total is allowed to grow but never to fall below the original 4,822. Reviewed
preserved-data definitions retain their exact imported spelling too; for
example, `Sound_UnreferencedSFXChannelPointers` records `; was: unused_10`
after its six pointer values were identified.

These mappings establish symbol continuity, not semantic correctness. Their
default evidence level is `hypothesis`. Correcting a semantic name must retain
the same historical mapping unless a documented source correction proves that
the mapping itself was wrong.

The current reconstruction carries 16,053 checked mappings. The total grows
when a live address-derived ROM or RAM definition receives an evidence-backed
name; corrections to an already renamed symbol retain its existing imported
IDA mapping and therefore do not inflate this count.

## Runtime toolchain selection

The emulator source identity remains the exact `source_commit` in
`config/toolchain.json`; selecting another checkout is not a repin. Verify an
isolated build explicitly before using it for runtime evidence:

```text
python scripts/verify_toolchain.py --config config/toolchain.json --platform windows_i386 --require-emulator --emulator-dir build/runtime-emulator/pinned-e14b925
```

`--emulator-dir` resolves the manifest's declared runtime files relative to the
selected checkout, including `Output/Gens.exe`. It does not inspect the default
`../gens_automation` executable instead or change the manifest. The selected
directory must be a Git checkout root, its HEAD must equal the recorded source
commit, and staged or unstaged tracked changes cause a failure. Linked Git
worktrees are supported. Ignored generated outputs do not make tracked source
dirty. Git inspection failures, a missing checkout, and a missing explicit
executable fail closed. An explicit override requires the runtime even without
`--require-emulator`; absent default runtimes remain optional only when neither
option is supplied, allowing preservation-only builds without an emulator.

Executable size and SHA-256 are printed for the selected build. The emulator's
`observed_only` entry remains an observation, not a universal binary hash gate:
different supported compiler builds can produce different executable bytes.
A clean source pin does not prove how an existing executable was compiled;
keep the source, build recipe, executable hash and runtime result together.
[Runtime verification](runtime.md#building-the-pinned-emulator) gives the MSVC
recipe for the pinned commit.
