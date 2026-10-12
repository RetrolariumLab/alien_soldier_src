#!/usr/bin/env python3
"""
Extract symbols from AS assembler listing file (.lst)

Parses the listing format:
  - Code labels:  "  156/     200 :                     Reset:"
  - EQU constants: "(1)   2/       0 : =$A10008             IO_CT1_CTRL equ"

Output: Simple text format (address<tab>symbol) for use with bintrace_parser.py
"""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys


LISTING_ROW = re.compile(
    r'^\s*(?:\(\d+\)\s*)?\d+/\s*([0-9A-Fa-f]+)\s*:'
)
LABEL = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
EQU = re.compile(
    r'^([A-Za-z_][A-Za-z0-9_]*)\s+equ\s+\$([0-9A-Fa-f]+)(?:\s|$)',
    re.IGNORECASE,
)
SOURCE_COLUMN = 40
GENERIC_PREFIXES = (
    'asc_', 'byte_', 'dword_', 'loc_', 'locret_', 'nullsub_',
    'off_', 'stru_', 'sub_', 'unk_', 'word_',
)


def is_generic(name):
    return name.startswith(GENERIC_PREFIXES)


def symbol_rank(name):
    """Prefer reviewed names, then address-derived names, then local labels."""
    if name.startswith(('loc_', 'locret_')):
        return 0
    if is_generic(name):
        return 1
    return 2


def load_resolved_symbols(lst_path):
    """Read AS's final table; inactive source-column labels are not symbols."""
    with Path(lst_path).open(encoding='latin-1') as listing:
        return _resolved_symbols(listing)


def _resolved_symbols(lines):
    names = {}
    in_table = False
    pattern = re.compile(r'\b([A-Z_][A-Z_0-9]*)\s*:\s*([0-9A-Fa-f]+)\s+[-A-Z]\s*\|')
    for line in lines:
        if line.strip() == 'Symbol Table (* = unused):':
            in_table = True
            continue
        if not in_table:
            continue
        for match in pattern.finditer(line):
            name, address = match[1], int(match[2], 16)
            if name in names and names[name] != address:
                raise ValueError('conflicting resolved listing symbol: ' + name)
            names[name] = address
    return names


def extract_symbols(lst_path, *, resolved_only=False):
    """Return one deterministic, best available symbol for every address."""
    if resolved_only:
        return read_listing_symbols(lst_path)[1]
    return _addressed_symbols(Path(lst_path).read_text(encoding='latin-1').splitlines(), None)


def read_listing_symbols(lst_path):
    """Parse both strict symbol views from one freshly read listing body.

    This shares input bytes, not a validation result or a persistent cache.
    Every call rereads the file; callers still close original raw identities.
    """
    body = Path(lst_path).read_text(encoding='latin-1')
    # File iteration splits on normalized newlines, not every Unicode line
    # separator; preserve that behavior for the resolved-table boundary.
    resolved = _resolved_symbols(body.split('\n'))
    if not resolved:
        raise ValueError('strict symbol export requires the final assembler symbol table')
    return resolved, _addressed_symbols(body.splitlines(), resolved)


def _addressed_symbols(lines, resolved):
    symbols = {}

    for line in lines:
        row = LISTING_ROW.match(line)
        if not row or len(line) <= SOURCE_COLUMN:
            continue

        # EQU rows are indented one extra column by AS; source directives and
        # labels otherwise start at the fixed listing source column.
        source = line[SOURCE_COLUMN:].lstrip()
        label = LABEL.match(source)
        equ = EQU.match(source)
        if label:
            name = label.group(1)
            addr = int(row.group(1), 16)
        elif equ:
            name = equ.group(1)
            addr = int(equ.group(2), 16) & 0xFFFFFF
            # Small EQU values are flags and enum constants, not addressable
            # symbols. Keeping them would overwrite ROM labels at 0x000000...
            if addr < 0x800000:
                continue
        else:
            continue

        if resolved is not None:
            if name.upper() not in resolved:
                continue
            if (resolved[name.upper()] & 0xFFFFFF) != (addr & 0xFFFFFF):
                raise ValueError('source row differs from resolved symbol table: ' + name)

        current = symbols.get(addr)
        if current is None or symbol_rank(name) > symbol_rank(current):
            symbols[addr] = name

    return symbols


def filter_symbols(symbols, include_loc=False, include_word=False,
                   min_addr=None, max_addr=None):
    """Filter symbols based on criteria."""
    filtered = {}

    for addr, name in symbols.items():
        # Address range filter
        if min_addr is not None and addr < min_addr:
            continue
        if max_addr is not None and addr > max_addr:
            continue

        # Name filters
        if not include_loc and name.startswith(('loc_', 'locret_')):
            continue
        if not include_word and is_generic(name):
            continue

        filtered[addr] = name

    return filtered

def main():
    parser = argparse.ArgumentParser(
        description='Extract symbols from AS assembler listing file'
    )
    parser.add_argument('lst_file', help='Input .lst file')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    parser.add_argument('--include-loc', action='store_true',
                       help='Include loc_XXX labels')
    parser.add_argument('--include-generic', action='store_true',
                       help='Include word_/byte_/dword_ labels')
    address_range = parser.add_mutually_exclusive_group()
    address_range.add_argument('--rom-only', action='store_true',
                               help='Only ROM addresses (0x000000-0x3FFFFF)')
    address_range.add_argument('--ram-only', action='store_true',
                               help='Only RAM addresses (0xFF0000-0xFFFFFF)')
    parser.add_argument('--all', action='store_true',
                       help='Include all symbols (no filtering)')
    parser.add_argument('--stats', action='store_true',
                       help='Print statistics')
    parser.add_argument('--json', action='store_true',
                       help='Output as JSON')
    parser.add_argument('--resolved-only', action='store_true',
                       help='Exclude inactive source rows using the final AS symbol table')

    args = parser.parse_args()

    # Extract all symbols
    symbols = extract_symbols(args.lst_file, resolved_only=args.resolved_only)

    # Apply filters
    if args.all:
        filtered = symbols
    else:
        min_addr = None
        max_addr = None

        if args.rom_only:
            min_addr = 0
            max_addr = 0x3FFFFF
        elif args.ram_only:
            min_addr = 0xFF0000
            max_addr = 0xFFFFFF

        filtered = filter_symbols(
            symbols,
            include_loc=args.include_loc,
            include_word=args.include_generic,
            min_addr=min_addr,
            max_addr=max_addr
        )

    # Statistics
    if args.stats:
        print(f"Addressed symbols: {len(symbols)}", file=sys.stderr)
        print(f"Exported symbols: {len(filtered)}", file=sys.stderr)
        counts = Counter(
            next((prefix for prefix in GENERIC_PREFIXES if name.startswith(prefix)),
                 'named')
            for name in filtered.values()
        )
        for prefix, count in sorted(counts.items(), key=lambda x: -x[1]):
            print(f"  {prefix}: {count}", file=sys.stderr)

    # Output
    out = open(args.output, 'w') if args.output else sys.stdout

    if args.json:
        # Output as hex strings for JSON
        json_data = {f"0x{addr:06X}": name for addr, name in sorted(filtered.items())}
        json.dump(json_data, out, indent=2)
        out.write('\n')
    else:
        # Simple format: address<tab>symbol
        for addr, name in sorted(filtered.items()):
            out.write(f"{addr:08X}\t{name}\n")

    if args.output:
        out.close()
        print(f"Written {len(filtered)} symbols to {args.output}", file=sys.stderr)

if __name__ == '__main__':
    raise SystemExit(main())
