#!/usr/bin/env python3
"""Rename assembly symbols across every source file, preserving provenance."""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path


DEFINITION_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)(?=:|\s+equ\b|\s+macro\b)", re.IGNORECASE)
PROVENANCE_RE = re.compile(r";\s*was:")


def provenance_start(line: str) -> int | None:
    """Locate a provenance marker outside quoted assembly literals."""
    index = 0
    while index < len(line):
        quote = line[index]
        if quote in {'"', "'"}:
            index += 1
            while index < len(line):
                if line[index] == quote:
                    index += 1
                    if index < len(line) and line[index] == quote:
                        index += 1
                        continue
                    break
                index += 1
            continue
        if quote == ";" and PROVENANCE_RE.match(line, index):
            return index
        index += 1
    return None


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def source_files() -> list[Path]:
    return sorted(Path("src").rglob("*.s")) + sorted(Path("src").rglob("*.inc"))


def load_renames(path: Path) -> list[tuple[str, str]]:
    renames: list[tuple[str, str]] = []
    with path.open(encoding="utf-8", newline="") as handle:
        for row_index, row in enumerate(csv.reader(handle)):
            if not row or row[0].startswith("#"):
                continue
            if len(row) < 2:
                fail(f"{path}: expected 'old,new', got {row!r}")
            old, new = row[0].strip(), row[1].strip()
            if not old or (
                row_index == 0 and old.lower() in {"old", "old_name"} and new.lower() in {"new", "new_name"}
            ):
                continue
            renames.append((old, new))
    return renames


def collect_symbols(files: list[Path]) -> set[str]:
    symbols: set[str] = set()
    for path in files:
        for line in path.read_text(encoding="utf-8").split("\n"):
            if match := DEFINITION_RE.match(line):
                symbols.add(match.group(1))
    return symbols


def substitute_unquoted(line: str, pattern: re.Pattern[str], mapping: dict[str, str]) -> tuple[str, int]:
    """Replace symbols outside quoted assembly literals."""
    pieces: list[str] = []
    start = 0
    index = 0
    replaced = 0

    while index < len(line):
        quote = line[index]
        if quote not in {'"', "'"}:
            index += 1
            continue

        segment, count = pattern.subn(lambda match: mapping[match.group(1)], line[start:index])
        pieces.append(segment)
        replaced += count

        literal_start = index
        index += 1
        while index < len(line):
            if line[index] == quote:
                index += 1
                if index < len(line) and line[index] == quote:
                    index += 1
                    continue
                break
            index += 1
        pieces.append(line[literal_start:index])
        start = index

    segment, count = pattern.subn(lambda match: mapping[match.group(1)], line[start:])
    pieces.append(segment)
    return "".join(pieces), replaced + count


def apply_renames(files: list[Path], renames: list[tuple[str, str]], provenance: bool) -> tuple[int, int]:
    mapping = dict(renames)
    pattern = re.compile(r"\b(" + "|".join(re.escape(old) for old in mapping) + r")\b")
    replaced = 0
    annotated = 0

    for path in files:
        lines = path.read_text(encoding="utf-8").split("\n")
        changed = False
        for index, line in enumerate(lines):
            if not pattern.search(line):
                continue

            definition = DEFINITION_RE.match(line)
            defines = definition.group(1) if definition else None
            # The `was:` suffix is historical evidence, not a live reference.
            # In particular, a previous name can be another symbol in this
            # batch; rewriting it would silently falsify provenance.
            marker = provenance_start(line)
            if marker is not None:
                new_prefix, count = substitute_unquoted(line[:marker], pattern, mapping)
                new_line = new_prefix + line[marker:]
            else:
                new_line, count = substitute_unquoted(line, pattern, mapping)
            replaced += count

            if provenance and defines in mapping and not PROVENANCE_RE.search(new_line):
                new_line = f"{new_line.rstrip()}  ; was: {defines}"
                annotated += 1

            if new_line != line:
                lines[index] = new_line
                changed = True

        if changed:
            path.write_text("\n".join(lines), encoding="utf-8", newline="")

    return replaced, annotated


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", help="CSV of old,new symbol pairs")
    parser.add_argument(
        "--no-provenance",
        action="store_true",
        help="Do not append '; was: <old>' to definition lines",
    )
    args = parser.parse_args(argv)

    csv_path = Path(args.csv_file)
    if not csv_path.is_file():
        fail(f"rename table not found: {csv_path}")

    renames = load_renames(csv_path)
    if not renames:
        fail(f"{csv_path} contains no renames")

    files = source_files()
    symbols = collect_symbols(files)
    problems: list[str] = []
    seen_new: dict[str, str] = {}
    seen_old: set[str] = set()

    for old, new in renames:
        if old in seen_old:
            problems.append(f"'{old}' occurs more than once in the rename table")
        seen_old.add(old)
        if old not in symbols:
            problems.append(f"'{old}' is not defined in the source")
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", new):
            problems.append(f"'{new}' is not a valid symbol name")
        if new in symbols and new != old:
            problems.append(f"'{new}' already exists; pick another name for '{old}'")
        if new in seen_new:
            problems.append(f"'{new}' is used for both '{seen_new[new]}' and '{old}'")
        seen_new[new] = old

    if problems:
        for problem in problems:
            print(f"[ERROR] {problem}", file=sys.stderr)
        print(f"[FAIL] {len(problems)} problem(s); nothing was renamed", file=sys.stderr)
        return 1

    replaced, annotated = apply_renames(files, renames, not args.no_provenance)
    print(f"[OK] renamed {len(renames)} symbols, {replaced} references, {annotated} annotated")
    print("[INFO] renaming must not move a byte -- run 'make verify'")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
