#!/usr/bin/env python3
"""Select hypothesis-level code procedures for a new runtime review."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

from prepare_batch import source_modules


LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
FUNCTION_END = re.compile(r"^; End of function\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s|$)")


def review_candidates(source: Path, audit: Path) -> tuple[list[str], list[str]]:
    records = json.loads(audit.read_text(encoding="utf-8"))["records"]
    hypotheses = {record["current_name"] for record in records if record.get("evidence") == "hypothesis"}
    selected: list[str] = []
    defined: set[str] = set()
    for module in source_modules(source):
        lines = module.read_text(encoding="utf-8").splitlines()
        functions = {match.group(1) for line in lines if (match := FUNCTION_END.match(line))}
        for line in lines:
            match = LABEL.match(line)
            if not match or match.group(1) not in hypotheses:
                continue
            name = match.group(1)
            if name in defined:
                raise ValueError(f"hypothesis {name} is defined in more than one module")
            defined.add(name)
            if name in functions:
                selected.append(name)
    unresolved = sorted(hypotheses - defined)
    if unresolved:
        raise ValueError(f"hypotheses absent from source: {', '.join(unresolved)}")
    missing = sorted(defined - set(selected))
    return selected, missing


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default="src/main.s")
    parser.add_argument("--audit", default="config/name_audit.json")
    parser.add_argument("--output", default="workflow/unanalyzed_procedures.txt")
    args = parser.parse_args(argv)

    try:
        selected, missing = review_candidates(Path(args.source), Path(args.audit))
    except (OSError, ValueError, KeyError) as error:
        parser.error(str(error))
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(name + "\n" for name in selected), encoding="utf-8")
    print(f"[OK] {len(selected)} hypothesis-level code procedures in {output}")
    if missing:
        print(f"[INFO] {len(missing)} hypotheses are not delimited code: {', '.join(missing)}")
    print("[INFO] old analysis_results.csv is not release evidence and does not suppress candidates")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
