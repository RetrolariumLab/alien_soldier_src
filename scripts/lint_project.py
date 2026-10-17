#!/usr/bin/env python3
"""Check repository-owned configuration, Python, docs, and file naming."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


MARKDOWN_LINK = re.compile(r"\[[^]]+\]\(([^)]+)\)")
SOURCE_MAP_ROW = re.compile(
    r"^\| `0x([0-9A-F]+)-0x([0-9A-F]+)` \|[^|]*\|\s*(\d+)\s*\|[^|]*\|$"
)
TEXT_SUFFIXES = {".mk", ".s", ".asm", ".inc", ".py", ".md", ".txt", ".json", ".dot"}
TEXT_FILENAMES = {".gitattributes", ".gitignore", ".editorconfig", "Makefile"}


def tracked_text_files(project_root: Path) -> list[Path]:
    """Every tracked file the repository treats as text.

    Line endings and whitespace are checked against the working tree rather
    than the index, because that is what an editor, a generator script and the
    assembler all see. .gitattributes normalizes what git stores; nothing but
    this check notices when a tool writes CRLF back into the tree.
    """
    result = subprocess.run(
        ["git", "ls-files"], cwd=project_root,
        capture_output=True, text=True, check=False,
    )
    if result.returncode != 0:
        return []
    paths = [project_root / line for line in result.stdout.splitlines() if line]
    return [
        path for path in paths
        if path.is_file() and (path.suffix in TEXT_SUFFIXES or path.name in TEXT_FILENAMES)
    ]


def check_text_hygiene(project_root: Path, path: Path, errors: list[str]) -> None:
    relative = path.relative_to(project_root).as_posix()
    try:
        text = path.read_bytes().decode("utf-8")
    except UnicodeDecodeError:
        errors.append(f"{relative}: not valid UTF-8")
        return
    if "\r" in text:
        errors.append(f"{relative}: contains CR; text files use LF")
    if text and not text.endswith("\n"):
        errors.append(f"{relative}: missing final newline")
    if text.endswith("\n\n"):
        errors.append(f"{relative}: more than one final newline")
    for number, line in enumerate(text.split("\n"), 1):
        if line != line.rstrip():
            errors.append(f"{relative}:{number}: trailing whitespace")


def check_source_map(project_root: Path, errors: list[str]) -> None:
    """Keep the human-readable ROM ranges and file counts aligned with the layout."""
    try:
        layout = json.loads(
            (project_root / "config/rom_layout.json").read_text(encoding="utf-8")
        )
        modules = [
            (int(entry["start"], 0), int(entry["end"], 0))
            for entry in layout["modules"]
        ]
        lines = (project_root / "docs/source_map.md").read_text(
            encoding="utf-8"
        ).splitlines()
    except (
        OSError, UnicodeError, json.JSONDecodeError, KeyError, TypeError, ValueError
    ) as error:
        errors.append(f"docs/source_map.md: cannot compare with ROM layout: {error}")
        return
    rows = []
    for line_number, line in enumerate(lines, 1):
        if not line.startswith("| `0x"):
            continue
        match = SOURCE_MAP_ROW.fullmatch(line)
        if match is None:
            errors.append(f"docs/source_map.md:{line_number}: malformed ROM range row")
            continue
        start = int(match.group(1), 16)
        end = int(match.group(2), 16)
        count = int(match.group(3))
        rows.append((start, end, count, line_number))

    if not modules or not rows:
        errors.append("docs/source_map.md: no ROM modules or range rows")
        return
    next_start = modules[0][0]
    for start, end, count, line_number in rows:
        if start != next_start or end < start:
            errors.append(
                f"docs/source_map.md:{line_number}: ROM ranges are not contiguous"
            )
        owned = sum(
            start <= module_start and module_end <= end
            for module_start, module_end in modules
        )
        if owned != count:
            errors.append(
                f"docs/source_map.md:{line_number}: files count {count}, layout has {owned}"
            )
        next_start = end + 1
    if next_start != modules[-1][1] + 1:
        errors.append("docs/source_map.md: ROM ranges do not end at the final module")
    for module_start, module_end in modules:
        if sum(
            start <= module_start and module_end <= end
            for start, end, _, _ in rows
        ) != 1:
            errors.append(
                f"docs/source_map.md: module 0x{module_start:06X}-0x{module_end:06X} "
                "is not owned by exactly one range"
            )


def check(project_root: Path) -> list[str]:
    errors: list[str] = []

    for path in tracked_text_files(project_root):
        check_text_hygiene(project_root, path, errors)

    for path in sorted((project_root / "docs").glob("*")):
        if path.is_file() and path.name != path.name.lower():
            errors.append(f"{path.relative_to(project_root)}: documentation filename is not lowercase")

    for path in sorted(project_root.glob("config/*.json")) + [project_root / "assets/manifest.json"]:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeError, json.JSONDecodeError) as error:
            errors.append(f"{path.relative_to(project_root)}: invalid JSON: {error}")

    check_source_map(project_root, errors)

    python_files = sorted((project_root / "scripts").rglob("*.py")) + sorted(
        (project_root / "tests").rglob("*.py")
    )
    for path in python_files:
        try:
            source = path.read_text(encoding="utf-8")
            compile(source, str(path), "exec")
        except (OSError, UnicodeError, SyntaxError) as error:
            errors.append(f"{path.relative_to(project_root)}: invalid Python: {error}")

    markdown_files = [project_root / "README.md"] + sorted((project_root / "docs").glob("*.md"))
    for path in markdown_files:
        text = path.read_text(encoding="utf-8")
        for target in MARKDOWN_LINK.findall(text):
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            clean_target = target.split("#", 1)[0]
            if clean_target and not (path.parent / clean_target).resolve().exists():
                errors.append(f"{path.relative_to(project_root)}: broken link {target}")

    return errors


def main() -> int:
    errors = check(Path.cwd())
    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        return 1
    print(
        "[OK] project policy: text hygiene across "
        f"{len(tracked_text_files(Path.cwd()))} tracked text files, "
        "JSON, Python, documentation names and links"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
