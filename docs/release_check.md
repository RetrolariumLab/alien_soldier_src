# Release check

`make release-check` is the single ordered release gate. It runs:

1. private asset identity and range policy;
2. source and project lint: style, naming vocabulary, provenance, branch-target
   resolution and text hygiene across every tracked text file;
3. Python verification tests;
4. cleanup of reproducible outputs;
5. a fresh byte-identical Japanese ROM build plus layout verification, which
   includes the 128 KiB DMA source boundary the emulator cannot check;
6. canonical symbol export and contract coverage, and a relocation probe that
   rebuilds the ROM with its layout perturbed and requires every pointer to
   follow;
7. all twelve emulator scenarios and 78 named RAM expectations.

The gate intentionally performs a clean build. `make clean` removes only the
canonical assembler outputs, source inventory and the exact PNG/genstate pairs
declared by the current runtime scenarios. It preserves unrelated research in
`build/` and `runtime/captures/`, as well as the user-supplied ROM, all 589
extracted segments, movies, traces, workflow files, source backups and emulator
configuration. Each runtime scenario is replayed and its declared pair is
captured anew.

A passing gate does not create or move a release tag.
