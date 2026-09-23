# Documentation Index

## Start here

| Document | What it answers |
| --- | --- |
| [`source_layout.md`](source_layout.md) | Where the code lives and why it is split that way |
| [`source_map.md`](source_map.md) | What the program does and which module owns each part |
| [`release_check.md`](release_check.md) | Which command proves what, and in which order |
| [`provenance.md`](provenance.md) | Where every name and every extracted byte came from |
| [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | The workflow, from a fresh clone to a reviewed change |

## Working on the source

| Document | What it answers |
| --- | --- |
| [`naming.md`](naming.md) | How to name a symbol, and what to do when you cannot |
| [`assembly_style.md`](assembly_style.md) | The layout rules the formatter enforces |
| [`ram_map.md`](ram_map.md) | What every work RAM address is for |
| [`symbols.md`](symbols.md) | Exporting symbols and using them in a debugger |
| [`unknowns.md`](unknowns.md) | What is still unresolved, and what would settle it |
| [`modularization_plan.md`](modularization_plan.md) | How the single translation unit became modules |
| [`tooling_status.md`](tooling_status.md) | Which commands are release evidence and which are research |
| [`tooling_progress.md`](tooling_progress.md) | Incremental evidence for migrating legacy tools to modules |

## Evidence and hardware

| Document | What it answers |
| --- | --- |
| [`runtime.md`](runtime.md) | The replayed scenarios, what they observe, and how to read a dump |
| [`gens_state_dump_spec.md`](gens_state_dump_spec.md) | The format of an emulator state dump |
| [`sound_driver.md`](sound_driver.md) | What is known about the Z80 driver and what is not |
| [`unused_content.md`](unused_content.md) | External dormant-content notes, and why they are not evidence |

## Reading order

For a first pass at the program itself, follow the ROM:

1. `src/system/boot.s` — hardware bring-up, checksum and the exception vectors.
2. `src/gameplay/main_loop.s` — the frame, phase by phase.
3. `src/gameplay/object_dispatch_table.s` — the object type table every enemy,
   projectile and effect is reached through.
4. `src/player/core_states.s` — the player state machine and its 48-slot table.
5. `src/collision/detection.s` — how a frame's hits are found and resolved.

`config/rom_layout.json` is the authority on module order and ranges; the
include order in `src/main.s` is ROM order.
