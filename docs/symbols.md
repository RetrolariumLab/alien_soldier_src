# Symbol export

`make symbols` converts the AS listing into `logs/symbols.txt`. The file uses
one `address<TAB>name` row per canonical 24-bit bus address and is suitable for
the trace tooling in `scripts/bintrace_parser.py`.

The exporter understands AS include rows, which carry a `(1)` prefix in this
single-translation-unit build. When labels alias the same address, a reviewed
semantic name is preferred over an address-derived or local name. Small EQU
values are flags or enum members and are deliberately excluded so they cannot
collide with ROM addresses. Sign-extended work-RAM EQU values are normalized to
the Mega Drive's 24-bit address bus.

`make verify-symbols` guards against parser regressions. It currently requires
at least 15,000 addressed symbols, all ROM landmarks declared in
`config/rom_layout.json`, and every base RAM symbol used by
`config/runtime_scenarios.json`. It also checks every one of the 15,833
`config/name_audit.json` current names against its exact assembled address in
the listing, retaining same-address aliases that the canonical export omits.
Sign-extended RAM EQU values are compared on the 24-bit bus. The count is a
coverage floor, not a semantic quality score; correctness of a name still
requires its own evidence.
