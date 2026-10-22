#!/usr/bin/env python3
"""Inventory current source modules without proposing mechanical splits."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re


DEFINITION = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)(?::|\s+(?:equ|macro)\b)", re.IGNORECASE)
PROVENANCE = re.compile(r";\s*was:\s*([A-Za-z_][A-Za-z0-9_]*)\s*$")
ADDRESS_DERIVED = re.compile(
    r"^(?:loc|locret|nullsub|sub|off|unk|unknown|byte|word|dword|flt|stru|asc)_[0-9A-F]+$",
    re.IGNORECASE,
)
GENERIC_CONTAINER = re.compile(
    r"(?:^|_)(?:boss_code|bank)(?:_|$)|_(?=[0-9a-f]*[0-9])[0-9a-f]{5,}$",
    re.IGNORECASE,
)
PROCEDURE_LEGACY = re.compile(r"^(?:sub|nullsub)_[0-9A-F]+$", re.IGNORECASE)
LISTING_ROW = re.compile(r"^\(\d+\)\s+\d+/\s*([0-9A-F]+)\s*:")
LISTING_LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")


def number(value: str | int) -> int:
    if isinstance(value, int):
        return value
    return int(value, 16) if value.lower().startswith("0x") else int(value, 0)


def category(name: str) -> str:
    return name.split("_", 1)[0] if "_" in name else "uncategorized"


def listing_symbols(path: Path) -> dict[str, int]:
    symbols: dict[str, int] = {}
    for line in path.read_text(encoding="latin-1").splitlines():
        row = LISTING_ROW.match(line)
        if not row or len(line) <= 40:
            continue
        label = LISTING_LABEL.match(line[40:])
        if label:
            symbols[label.group(1)] = int(row.group(1), 16)
    return symbols


def inspect_module(root: Path, entry: dict, symbols: dict[str, int] | None = None) -> dict:
    path = root / entry["file"]
    lines = path.read_text(encoding="utf-8").splitlines()
    definitions: list[dict] = []
    procedures: list[dict] = []
    current: dict | None = None

    for line_number, line in enumerate(lines, 1):
        match = DEFINITION.match(line)
        if match:
            name = match.group(1)
            current = {
                "name": name,
                "line": line_number,
                "address_derived": bool(ADDRESS_DERIVED.fullmatch(name)),
            }
            if symbols is not None and name in symbols:
                current["address"] = f"0x{symbols[name]:06X}"
            definitions.append(current)
        marker = PROVENANCE.search(line)
        if marker and current is not None:
            current["legacy_name"] = marker.group(1)
            if PROCEDURE_LEGACY.fullmatch(marker.group(1)):
                procedures.append(
                    {
                        "name": current["name"],
                        "line": current["line"],
                        "legacy_name": marker.group(1),
                        **({"address": current["address"]} if "address" in current else {}),
                    }
                )

    categories = Counter(category(item["name"]) for item in definitions)
    return {
        "file": entry["file"],
        "subsystem": entry["subsystem"],
        "start": f"0x{number(entry['start']):06X}",
        "end": f"0x{number(entry['end']):06X}",
        "lines": len(lines),
        "definitions": len(definitions),
        "address_derived_definitions": sum(item["address_derived"] for item in definitions),
        "provenance_procedures": len(procedures),
        "generic_container_name": bool(GENERIC_CONTAINER.search(path.stem)),
        "dominant_categories": [{"name": name, "definitions": count} for name, count in categories.most_common(8)],
        "first_definition": definitions[0]["name"] if definitions else None,
        "last_definition": definitions[-1]["name"] if definitions else None,
        "procedure_anchors": procedures,
    }


def build_inventory(root: Path, layout: dict, symbols: dict[str, int] | None = None) -> dict:
    modules = [inspect_module(root, entry, symbols) for entry in layout["modules"]]
    line_counts = sorted(item["lines"] for item in modules)
    total_lines = sum(line_counts)
    return {
        "schema_version": 1,
        "source": layout["target"]["entrypoint"],
        "modules": modules,
        "summary": {
            "module_count": len(modules),
            "source_lines": total_lines,
            "mean_module_lines": round(total_lines / len(modules), 1),
            "median_module_lines": line_counts[(len(line_counts) - 1) // 2],
            "largest_module_lines": line_counts[-1],
            "modules_over_1000_lines": sum(value > 1000 for value in line_counts),
            "generic_container_names": sum(item["generic_container_name"] for item in modules),
            "definitions": sum(item["definitions"] for item in modules),
            "address_derived_definitions": sum(item["address_derived_definitions"] for item in modules),
            "provenance_procedures": sum(item["provenance_procedures"] for item in modules),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", default="config/rom_layout.json")
    parser.add_argument("--listing", default="build/main.lst")
    parser.add_argument("--output", default="build/source_inventory.json")
    args = parser.parse_args()
    root = Path.cwd()
    layout = json.loads((root / args.layout).read_text(encoding="utf-8"))
    symbols = listing_symbols(root / args.listing)
    inventory = build_inventory(root, layout, symbols)
    output = root / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(inventory, indent=2) + "\n", encoding="utf-8")
    summary = inventory["summary"]
    print(
        f"[OK] source inventory: {summary['module_count']} modules, "
        f"mean {summary['mean_module_lines']} lines, "
        f"{summary['modules_over_1000_lines']} over 1000, "
        f"{summary['generic_container_names']} generic filenames"
    )
    print(f"[OK] wrote {output.relative_to(root).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
