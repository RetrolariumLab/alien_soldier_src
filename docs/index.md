# Documentation

Start with the [README](../README.md) and [contributing](../CONTRIBUTING.md).

## Build and check

| Document                      | What it covers                                                     |
| ----------------------------- | ------------------------------------------------------------------ |
| [Revisions](revisions.md)     | The two cartridges, their identities and outputs, and what differs |
| [Movies](../movies/README.md) | The attract run `make test-full` plays in MAME                     |

`make help` lists the targets. The research and release tooling of the earlier
releases (runtime scenarios in Gens, symbol exports, the naming workflow and the
audits) stays at their tags, up to `source-reconstruction-3.0`.

## Understand or change the source

Read [the subsystem map](source_map.md) for the architecture, then
[source layout](source_layout.md) for include order, the standalone Z80 program,
size decisions, DMA boundaries and what may move. A first code pass can follow
boot, main loop, object dispatch, player state and collision in the order the
subsystem map gives. Do not infer a call or an identity only from an
address-ordered neighbour.

- [RAM map](ram_map.md) keeps shared scene overlays and entity fields together.
- [Naming](naming.md), [assembly style](assembly_style.md) and
  [provenance](provenance.md) govern edits.
- [Unknowns](unknowns.md) lists open questions.
  [The dormant type-$1C0 family](dormant_entity_1c0.md) and
  [payload boundaries](payload_archives.md) keep two investigations;
  [external dormant-content notes](unused_content.md) are unverified
  attributions, not naming authority.
- [Sound driver](sound_driver.md) covers the 68000 and Z80 halves and the
  request IDs.

## Edit content

[Editing in Retrolarium](retrolarium.md): the game opens in Retrolarium Studio
through `alien_soldier.rlj`, and the kit reads and writes its twenty data
formats. The [tile codec](tile_codec_spec.md) describes the hardest of them.
