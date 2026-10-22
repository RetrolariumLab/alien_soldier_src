#!/usr/bin/env python3
"""Apply a research batch through the module-aware symbol renamer."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

import rename_symbols
from research_movie import report_for_movie


def load_report(path: Path) -> tuple[list[str], list[dict[str, str]]] | None:
    if not path.is_file():
        return None
    with path.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        fields = list(reader.fieldnames or [])
        if "procedure" not in fields:
            raise ValueError(f"{path}: report has no procedure column")
        return fields, list(reader)


def mark_processed(path: Path, report: tuple[list[str], list[dict[str, str]]], old_names: set[str]) -> int:
    fields, rows = report
    if "processed" not in fields:
        fields.append("processed")
    marked = 0
    for row in rows:
        if row["procedure"] in old_names and row.get("processed") != "true":
            row["processed"] = "true"
            marked += 1

    if marked == 0:
        return 0

    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)
    return marked


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", default="workflow/rename_batch.csv")
    parser.add_argument("--movie-file", default="workflow/.movie")
    args = parser.parse_args(argv)

    database = Path(args.database)
    if not database.is_file():
        parser.error(f"rename table not found: {database}")
    try:
        report_path = report_for_movie(Path(args.movie_file))
        report = load_report(report_path)
    except ValueError as error:
        parser.error(str(error))

    # rename_symbols validates the whole batch before touching any module.
    renames = rename_symbols.load_renames(database)
    result = rename_symbols.main([str(database)])
    if result != 0:
        return result

    if report is None:
        print(f"[INFO] no analysis report at {report_path}; no processed flags changed")
    else:
        marked = mark_processed(report_path, report, {old for old, _ in renames})
        print(f"[OK] marked {marked} procedures processed in {report_path}")
    print("[INFO] review all source-module diffs, update name evidence, then make verify")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
