#!/usr/bin/env python3
"""Derive a profile ROM layout from an assembler listing."""

from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

from verify_layout import listing_includes, listing_symbols, number


GAP_START_SYMBOLS = (
    "Math_PackedBCDLookup_End",
    "Sound_PCMBank9_End",
    "Credits_SegaMappingData_End",
)


def derive_layout(base: dict, listing_lines: list[str], profile: str) -> dict:
    """Return a profile-specific layout with listing-owned addresses."""
    layout = copy.deepcopy(base)
    layout["profile"] = profile

    modules = [row for row in listing_includes(listing_lines) if row[1].endswith(".s")]
    declared = layout["modules"]
    if [path for _, path in modules] != [entry["file"] for entry in declared]:
        raise ValueError("listing module order does not match the base layout")

    image_size = number(layout["rom_image"]["size"])
    for index, (start, _) in enumerate(modules):
        end = modules[index + 1][0] - 1 if index + 1 < len(modules) else image_size - 1
        declared[index]["start"] = f"0x{start:06X}"
        declared[index]["end"] = f"0x{end:06X}"

    symbols = listing_symbols(listing_lines)
    for landmark in layout["rom_image"]["landmarks"]:
        symbol = landmark["symbol"]
        if symbol not in symbols:
            raise ValueError(f"landmark is absent from listing: {symbol}")
        landmark["address"] = f"0x{symbols[symbol]:06X}"

    gaps = layout["rom_image"]["gaps"]
    if len(gaps) != len(GAP_START_SYMBOLS):
        raise ValueError("base layout gap count has no derivation rule")
    for gap, symbol in zip(gaps, GAP_START_SYMBOLS):
        if symbol not in symbols:
            raise ValueError(f"gap boundary is absent from listing: {symbol}")
        start = symbols[symbol]
        end = number(gap["end"])
        gap["start"] = f"0x{start:06X}"
        gap["size"] = end - start + 1

    return layout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", default="config/rom_layout.json")
    parser.add_argument("--listing", required=True)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    base = json.loads(Path(args.base).read_text(encoding="utf-8"))
    lines = Path(args.listing).read_text(encoding="latin-1").splitlines()
    layout = derive_layout(base, lines, args.profile)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(layout, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"[OK] derived {args.profile} ROM layout: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
