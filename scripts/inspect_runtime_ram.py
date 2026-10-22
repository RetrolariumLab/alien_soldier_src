#!/usr/bin/env python3
"""Print low-valued RAM bytes that change across named state captures."""

from __future__ import annotations

import argparse
from pathlib import Path

from runtime_state import Genstate


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("states", nargs="+", metavar="NAME=FILE")
    parser.add_argument("--max-value", type=lambda value: int(value, 0), default=0x20)
    parser.add_argument("--limit", type=int, default=500)
    parser.add_argument("--start", type=lambda value: int(value, 0), default=0xFF0000)
    parser.add_argument("--end", type=lambda value: int(value, 0), default=0xFFFFFF)
    parser.add_argument("--address", action="append", type=lambda value: int(value, 0))
    parser.add_argument("--width", choices=("u8", "u16", "u32"), default="u8")
    parser.add_argument("--find-u16", type=lambda value: int(value, 0))
    args = parser.parse_args()

    named: list[tuple[str, Genstate]] = []
    for item in args.states:
        if "=" not in item:
            parser.error(f"state must be NAME=FILE: {item}")
        name, filename = item.split("=", 1)
        named.append((name, Genstate.read(Path(filename))))

    print("address " + " ".join(f"{name:>10}" for name, _ in named))
    if args.find_u16 is not None:
        for name, state in named:
            matches = [
                address for address in range(args.start, args.end, 2) if state.m68k_u16(address) == args.find_u16
            ]
            print(f"{name}: " + " ".join(f"{address:06X}" for address in matches))
        return 0

    if args.address:
        reader = {
            "u8": Genstate.m68k_u8,
            "u16": Genstate.m68k_u16,
            "u32": Genstate.m68k_u32,
        }[args.width]
        digits = {"u8": 2, "u16": 4, "u32": 8}[args.width]
        for address in args.address:
            values = [reader(state, address) for _, state in named]
            print(f"{address:06X} " + " ".join(f"{value:0{digits}X}".rjust(10) for value in values))
        return 0

    shown = 0
    for address in range(args.start, args.end + 1):
        values = [state.m68k_u8(address) for _, state in named]
        if len(set(values)) < 2 or max(values) > args.max_value:
            continue
        print(f"{address:06X} " + " ".join(f"{value:10X}" for value in values))
        shown += 1
        if shown >= args.limit:
            break
    print(f"shown={shown}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
