# Documentation

Start with the [README](../README.md) and [contributing](../CONTRIBUTING.md).

## Build and check

| Document                                 | What it covers                                                                  |
| ---------------------------------------- | ------------------------------------------------------------------------------- |
| [Regional profiles](region_profiles.md)  | The two cartridges, their identities and outputs, and what differs              |
| [Release verification](release_check.md) | What `make release-check` runs, in order                                        |
| [Runtime verification](runtime.md)       | The twelve Japanese scenarios, building the pinned emulator, reference captures |
| [Tool provenance](../bin/README.md)      | The vendored assembler                                                          |
| [State dumps](gens_state_dump_spec.md)   | The emulator's state-dump format                                                |

## Understand or change the source

Read [the subsystem map](source_map.md) for the architecture, then
[source layout](source_layout.md) for include order, the standalone Z80 program,
size decisions, DMA boundaries and what may move. A first code pass can follow
boot, main loop, object dispatch, player state and collision in the order the
subsystem map gives. Do not infer a call or an identity only from an
address-ordered neighbour.

- [RAM map](ram_map.md) keeps shared scene overlays and entity fields together;
  [symbols](symbols.md) explains the debugger exports.
- [Naming](naming.md), [assembly style](assembly_style.md) and
  [provenance](provenance.md) govern edits;
  [regional name provenance](regional_name_provenance.md) explains the assembled
  European addresses.
- [Unknowns](unknowns.md) lists open questions.
  [The dormant type-$1C0 family](dormant_entity_1c0.md) and
  [payload boundaries](payload_archives.md) keep two investigations;
  [external dormant-content notes](unused_content.md) are unverified
  attributions, not naming authority.
- [Sound driver](sound_driver.md) covers the 68000 and Z80 halves and the
  request IDs.
- [Modularization](modularization_plan.md) records how the source got its
  semantic modules.

## Edit content

[Content authoring](content_authoring.md) is the common workflow and lists all
twenty formats. Start there before opening a Studio.

| Task                                       | Formats                                                                         | Studio                                                               |
| ------------------------------------------ | ------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Stage objects, configuration and maps      | [Stage maps](stage_map_model.md), [map reference audit](map_reference_audit.md) | [Level Studio](level_studio.md), [level playtest](level_playtest.md) |
| Tiles, palettes, mappings and animation    | [Graphics models](graphics_models.md), [tile codec](tile_codec_spec.md)         | Graphics Studio, in the graphics guide                               |
| Static screens                             | [Screen Studio](screen_studio.md)                                               | Screen Studio                                                        |
| Text and glyphs                            | [Text Studio](text_studio.md)                                                   | Text Studio                                                          |
| Sequences, instruments, envelopes and DPCM | [Sound models](sound_models.md)                                                 | [Sound Studio](sound_studio.md)                                      |

[Studio actions](workstation_actions.md) describes Save, Reload, Build and
Close.

## Research tools

[Tooling status](tooling_status.md) separates the release commands from the
exploratory ones, and [the research workflow](claude_instructions.md) describes
the naming loop.
