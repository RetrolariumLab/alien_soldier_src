#!/usr/bin/env python3
"""Find ROM labels with no symbolic references across the module graph.

This is a source-text review queue, never proof that code or data is unused:
runtime-computed and raw-address references are outside its scope.
"""

import re
import argparse
from pathlib import Path

from prepare_batch import source_modules


def strip_comment(line: str) -> str:
    """Keep assembly tokens, excluding quoted literals and comments."""
    result = []
    index = 0
    while index < len(line):
        char = line[index]
        if char == ";":
            break
        if char in {'"', "'"}:
            quote = char
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
        result.append(char)
        index += 1
    return "".join(result)


def classify_label(label_name: str) -> str:
    """Classify a label by its naming pattern."""
    if label_name.startswith("sub_"):
        return "sub"
    elif label_name.startswith("loc_"):
        return "loc"
    elif label_name.startswith("locret_"):
        return "locret"
    elif label_name.startswith("byte_"):
        return "byte"
    elif label_name.startswith("word_"):
        return "word"
    elif label_name.startswith("dword_"):
        return "dword"
    elif label_name.startswith("off_"):
        return "off"
    elif label_name.startswith("unk_"):
        return "unk"
    elif label_name.startswith("stru_"):
        return "stru"
    elif label_name.startswith("nullsub_"):
        return "nullsub"
    else:
        return "custom"


def find_unreferenced_labels(source_file: str | Path) -> list[tuple[str, str, int, str]]:
    """Return (name, module, line, type) for labels with no symbolic use."""
    source = Path(source_file)
    modules = source_modules(source)
    includes = []
    if source.name == "main.s":
        base = source.resolve().parent.parent
        for line in source.read_text(encoding="utf-8").splitlines():
            if match := re.match(r'^\s*include\s+"([^"]+\.inc)"', line, re.IGNORECASE):
                include = base / match.group(1)
                if not include.is_file():
                    raise FileNotFoundError(f"{source}: missing include {include}")
                includes.append(include)
    definition_pattern = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
    identifier_pattern = re.compile(r"\b([A-Za-z_][A-Za-z0-9_]*)\b")
    definitions: dict[str, tuple[str, int, str]] = {}

    for module in modules:
        for line_number, line in enumerate(module.read_text(encoding="utf-8").splitlines(), 1):
            if match := definition_pattern.match(line):
                name = match.group(1)
                if name in definitions:
                    raise ValueError(f"{name}: duplicate definition in {module}")
                definitions[name] = (module.as_posix(), line_number, classify_label(name))

    referenced: set[str] = set()
    for path in [*modules, *includes]:
        for line in path.read_text(encoding="utf-8").splitlines():
            code = strip_comment(line)
            if definition := definition_pattern.match(code):
                code = code[definition.end() :]
            referenced.update(set(identifier_pattern.findall(code)) & definitions.keys())

    return [
        (name, module, line, kind)
        for name, (module, line, kind) in definitions.items()
        if name not in referenced and not name.endswith("_End")
    ]


def main():
    parser = argparse.ArgumentParser(description="List ROM labels without symbolic source references")
    parser.add_argument(
        "input", nargs="?", default="src/main.s", help="ROM-ordered source include index (default: src/main.s)"
    )
    parser.add_argument("--output", help="Output file for results")

    args = parser.parse_args()

    try:
        unreferenced = find_unreferenced_labels(args.input)
    except (OSError, ValueError) as error:
        parser.error(str(error))

    output_lines = [f"{name}\t{module}:{line}\t{kind}" for name, module, line, kind in unreferenced]
    output_text = "\n".join(output_lines) + ("\n" if output_lines else "")
    print(f"[OK] {len(unreferenced)} labels have no symbolic source reference")
    print("[INFO] raw-address and runtime-computed uses are not ruled out")
    if args.output:
        Path(args.output).write_text(output_text, encoding="utf-8")
        print(f"[OK] wrote {args.output}")
    else:
        print(output_text, end="")

    return 0


if __name__ == "__main__":
    exit(main())
