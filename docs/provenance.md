# Source provenance

The canonical input identity is recorded in `assets/manifest.json` (and the
revisions' hashes in `config/game_profile.json`); the assembler and `p2bin` come
from Retrolarium Kit, which verifies them.

The assembly initially carried 4,822 unique mappings from the current symbol to
the original IDA-generated name. They use `; was: sub_...`, `loc_...`,
`locret_...`, or `nullsub_...`. In 298 cases the historical annotation is on the
first instruction after the owning label, which is how the earlier rename tool
wrote it; such a marker belongs to the most recent definition, and both sides
stay unique. Reviewed RAM renames add mappings such as `; was: word_FFA284`, so
the total may grow but never fall below the original 4,822 (the source lint of
the earlier preservation releases checked this). Reviewed preserved-data
definitions retain their exact imported spelling too; for example,
`Sound_UnreferencedSFXChannelPointers` records `; was: unused_10` after its six
pointer values were identified.

These mappings establish symbol continuity, not semantic correctness. Their
default evidence level is `hypothesis`. Correcting a semantic name must retain
the same historical mapping unless a documented source correction proves that
the mapping itself was wrong.

The reconstruction carries 16,053 mappings. The total grows when a live
address-derived ROM or RAM definition receives an evidence-backed name;
corrections to an already renamed symbol retain its existing imported IDA
mapping and therefore do not inflate this count.
