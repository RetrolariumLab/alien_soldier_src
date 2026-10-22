# Tooling status

The release commands are the ones `make release-check` runs
([release verification](release_check.md)). They are module-aware.

The exploratory commands `analyze`, `find-unanalyzed`, `prepare-batch`, and
`rename` remain outside the release interface. The `find-unanalyzed` selects
hypothesis-level code procedures from the name audit in ROM order; its queue is
currently empty because no record retains that evidence level. The six `unknown`
records stay in `docs/unknowns.md`, not in that automatic queue. `analyze`
resolves selected names to owning modules and perturbs a private worker copy,
one worker by default; its emulator workflow has not been rerun against the
pinned host and movie, so its output is not release evidence. `debug-pointers`
and `report-pointers` are retired safely: their old address-name search found no
current targets, and their cleanup could remove prior diff data.
`make verify-relocation` is the module-aware pointer check used by the release
gate. `make rename` preserves provenance, but a rename still needs independent
semantic evidence and `make verify`; the report's processed flag is not proof.
The `set-movie`, `show-movie`, and `prepare-batch` recipes are portable Python
calls, and batch extraction follows the ROM-ordered modules. Their report inputs
remain exploratory rather than release evidence.

`find_unreferenced_labels.py` scans the ROM-ordered modules and their included
equate files, so references across module boundaries count. Its output means
only "no symbolic source reference": cartridge-header fields, raw-address uses
and runtime-computed references can still be live. The legacy
`split_data_from_listing.py` CLI is retired because it rewrote one source file
and emitted binaries outside the preservation asset manifest; use `make split`
for canonical extraction.

Read-only trace parsing and report generation do not mutate source and remain
useful, but their output is evidence only when its ROM, movie, emulator commit,
frame range, and interpretation are recorded.

The name-audit test discovers definitions across every `.s` and `.inc` module in
one pass and compares the resulting symbol set with the audit registry. This
preserves the exact missing-name check while avoiding one whole-source regular
expression scan per audit record; at 9,818 records the local test time fell from
about 271 seconds to less than one second.

`make semantic-audit` is the module-aware, read-only queue for the remaining
Sonnet-name review. It joins provenance-owning current definitions against the
exact current names in `config/name_audit.json`, reports the backlog by source
module, and separates binary-backed `_End` aliases from ordinary end labels that
still need semantic review. It never rewrites source and does not require a
listing, ROM build, trace, or emulator. It also counts identical evidence
sentences across exact-address records. Run
`python scripts/semantic_audit_queue.py --duplicate-bases --limit 10` to see the
largest groups with addresses and source modules, or add `--basis-contains TEXT`
to inspect every member of a matching group. Repetition is a review queue, not
proof of a bad name: ROM-ordered mapping records can share a valid format
explanation. Reviewed groups live in `config/duplicate_basis_reviews.json`;
their exact addresses, current names, and modules must still match. The ordinary
duplicate listing omits accepted groups, while the summary reports both accepted
and open counts.

`make trace` passes an inert screenshot interval to the pinned emulator. This is
required because that emulator currently evaluates its maximum-frame and
movie-finished termination checks only while screenshot automation is enabled.
The workaround produces no periodic captures, bounds the TAS trace at its pinned
90,000-frame limit, and lets the longplay/menu traces stop at movie end when a
requested breakpoint is never reached. Rendering uses frameskip 8 to keep a
negative breakpoint search practical; emulated frame numbers and CPU execution
remain unchanged.
