# Module-aware procedure research workflow

This is optional research, not a release gate. Start with
[tooling status](tooling_status.md), [naming](naming.md),
[provenance](provenance.md) and [contribution rules](../CONTRIBUTING.md).
The prior automated naming pass is not evidence that its semantic claims were
correct. The live reviewed audit, not a processed-report flag, owns confidence.

## Prepare a bounded investigation

make find-unanalyzed selects hypothesis-level procedures from the reviewed name
audit in ROM order. An empty result means that particular queue is empty; it
does not prove all semantics or indirect paths are known. Active unknowns live
in [the unknown register](unknowns.md).

make prepare-batch COUNT=40 writes an ignored workflow/batch_procedures.txt with
module-owned code and available analysis context. make set-movie MOVIE=tas
selects the research movie. reference, analyze and report are exploratory;
their older workflows are not the release scenario set. Read their current
tooling-status limitations before requesting a run. Runtime permission and
pinned inputs are explicit, never inferred from a naming task.

## Propose, review and apply a name

1. Locate the exact current definition in src/ and its callers, consumers,
   tables, shared state and profile branches. src/main.s is the cartridge
   include index; the standalone Z80 entrypoint has its own source namespace.
2. Establish the narrow role from instructions and data flow. A screenshot,
   caller name, RAM difference or scene alone is not sufficient to infer a
   boss identity or complete function. Keep unresolved semantics role-neutral.
3. Produce the private CSV workflow/rename_batch.csv with header
   old_name,new_name,description. Require unique valid symbols and the owning
   subsystem vocabulary. A description records the actual evidence, not a guess.
4. Review the proposal before make rename. The current renamer updates the
   module tree atomically and retains original was markers. Do not use the
   retired single-file mutator or hand-copy output to alien_soldier_j.s.
5. Update exact-address evidence and active unknown records together,
   following their real schemas. Generated spelling mappings
   do not upgrade evidence. Check both regional assembled addresses when the
   changed shared source or profile interface makes that relevant.
6. Run make lint and make verify-all, plus focused
   regression controls for the changed contract. Review git diff and commit
   only intended tracked source/configuration/documentation changes with the
   required substantive English message. See [release verification](release_check.md)
   for the stronger release gate; a naming loop is not a release PASS.

## Private data and failed experiments

ROMs, extracted data, reference screenshots/states, diffs, reports and private
workflow files stay ignored. They are not source evidence suitable for Git
merely because a local producer created them. Never stage the original ROM.

If assembly or identity fails, inspect the exact diff and diagnostic before
changing anything else. Do not restore a broad backup or discard another
agent's work. Preserve the failed experiment with its input epoch; do not
claim it passed because a different build or later source eventually worked.

The old batch instruction remains available through
[the Claude command entry](../.claude/commands/document.md), which delegates to
this same policy instead of maintaining separate naming heuristics.
