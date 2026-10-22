#!/usr/bin/env python3
"""
Find Unnamed Procedures in Alien Soldier Disassembly

Identifies procedures that need proper naming:
1. All sub_* labels (subroutines/functions)
2. Labels referenced in offset tables (jump tables): dc.w Label-Base or dc.l Label

Offset tables look like:
    off_15062:  dc.w Player_HandleJump-Player_HandleDeathSequence
                dc.w Boss_UpdateHealthBar-Player_HandleDeathSequence
                dc.w sub_15B8C-Player_HandleDeathSequence
                dc.w loc_169E0-Player_HandleDeathSequence

Usage:
    # Find all unnamed procedures
    python scripts/find_unnamed_procedures.py --list --output procedures_list.txt

    # Get only unanalyzed procedures
    python scripts/find_unnamed_procedures.py --list --exclude-analyzed analysis_results.csv --output unanalyzed.txt
"""

import re
import argparse
import csv
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Set

try:
    from tqdm import tqdm
except ImportError:
    print("Warning: tqdm not installed. Progress bars will be disabled.")

    class tqdm:
        def __init__(self, iterable=None, **kwargs):
            self.iterable = iterable

        def __iter__(self):
            return iter(self.iterable)

        def __enter__(self):
            return self

        def __exit__(self, *args):
            pass

        def update(self, n=1):
            pass


def read_disassembly(file_path: str) -> List[str]:
    """Read the disassembly file and return lines."""
    with open(file_path, "r", encoding="utf-8") as f:
        return f.readlines()


def load_analyzed_procedures(csv_file: str) -> Set[str]:
    """Load set of already analyzed procedures from CSV."""
    analyzed = set()

    try:
        with open(csv_file, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                analyzed.add(row["procedure"])
    except FileNotFoundError:
        print(f"Warning: {csv_file} not found, treating all as unanalyzed")
        return set()

    return analyzed


def find_unnamed_procedures(lines: List[str]) -> Tuple[List[Tuple[str, int]], List[Tuple[str, int]], Dict[str, int]]:
    """
    Find all unnamed procedures that need naming.

    Returns:
        - sub_labels: List of (label_name, line_number) for sub_* labels
        - table_labels: List of (label_name, line_number) for labels in offset tables
        - label_lines: Dict mapping label_name -> line_number for all labels
    """
    sub_labels = []
    table_labels_set = set()  # Use set to avoid duplicates
    label_lines = {}  # Map label name -> line number

    # Pattern to find sub_* label definitions
    sub_pattern = re.compile(r"^(sub_[0-9A-Fa-f]+):")

    # Pattern to find any label definition (for line number lookup)
    any_label_pattern = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*):")

    # Pattern to find offset table entries: dc.w/dc.l Label-Base or dc.w Label
    # Matches: dc.w sub_1234-Base, dc.w loc_5678-Base, dc.l SomeProc, etc.
    offset_table_pattern = re.compile(
        r"dc\.[wl]\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:-\s*[a-zA-Z_][a-zA-Z0-9_]*)?(?:\s*;|$)"
    )

    print(f"Analyzing {len(lines):,} lines...")

    # First pass: collect all label definitions and their line numbers
    print("Pass 1: Collecting label definitions...")
    for line_num, line in enumerate(tqdm(lines, desc="Finding labels", unit="lines"), start=1):
        label_match = any_label_pattern.match(line)
        if label_match:
            label_name = label_match.group(1)
            label_lines[label_name] = line_num

            # Also check if it's a sub_* label
            if label_name.startswith("sub_"):
                sub_labels.append((label_name, line_num))

    # Second pass: find labels referenced in offset tables
    print("Pass 2: Finding offset table references...")
    in_offset_table = False

    for line_num, line in enumerate(tqdm(lines, desc="Finding table refs", unit="lines"), start=1):
        stripped = line.strip()

        # Detect start of offset table (off_* label or label followed by dc.w/dc.l)
        if re.match(r"^off_[0-9A-Fa-f]+:", line):
            in_offset_table = True
            continue

        # Check for dc.w/dc.l entries
        if "dc.w" in line or "dc.l" in line:
            # Find all label references in this line
            matches = offset_table_pattern.findall(line)
            for label_name in matches:
                # Only add if it's an unnamed label (sub_, loc_, locret_, nullsub_)
                if (
                    label_name.startswith("sub_")
                    or label_name.startswith("loc_")
                    or label_name.startswith("locret_")
                    or label_name.startswith("nullsub_")
                ):
                    table_labels_set.add(label_name)
        else:
            # If not a dc.w/dc.l line and not a comment/empty, we're out of the table
            if stripped and not stripped.startswith(";") and not stripped.startswith("dc."):
                in_offset_table = False

    # Convert set to sorted list with line numbers
    table_labels = []
    for label_name in table_labels_set:
        # Skip sub_* labels as they're already in sub_labels
        if label_name.startswith("sub_"):
            continue
        line_num = label_lines.get(label_name, 0)
        if line_num > 0:
            table_labels.append((label_name, line_num))

    # Sort by line number
    sub_labels.sort(key=lambda x: x[1])
    table_labels.sort(key=lambda x: x[1])

    return sub_labels, table_labels, label_lines


def format_simple_list(sub_labels: List[Tuple[str, int]], table_labels: List[Tuple[str, int]]) -> str:
    """Format as simple list (one procedure name per line) for analysis."""
    output = []

    # Add all sub_* labels
    for label_name, _ in sub_labels:
        output.append(label_name)

    # Add all table labels (loc_, locret_, nullsub_)
    for label_name, _ in table_labels:
        output.append(label_name)

    return "\n".join(output)


def format_output(
    sub_labels: List[Tuple[str, int]], table_labels: List[Tuple[str, int]], show_stats: bool = False
) -> str:
    """Format the output for display or file writing."""
    output = []
    output.append("=" * 80)
    output.append("UNNAMED PROCEDURES IN ALIEN SOLDIER DISASSEMBLY")
    output.append("=" * 80)
    output.append(f"Total sub_* procedures: {len(sub_labels)}")
    output.append(f"Total offset table entries (loc_/locret_/nullsub_): {len(table_labels)}")
    output.append(f"TOTAL PROCEDURES TO NAME: {len(sub_labels) + len(table_labels)}")
    output.append("=" * 80)
    output.append("")

    if show_stats:
        # Count by type
        loc_count = sum(1 for name, _ in table_labels if name.startswith("loc_"))
        locret_count = sum(1 for name, _ in table_labels if name.startswith("locret_"))
        nullsub_count = sum(1 for name, _ in table_labels if name.startswith("nullsub_"))

        output.append("\nStatistics:")
        output.append(f"  sub_* procedures:           {len(sub_labels):5d}")
        output.append(f"  loc_* in offset tables:     {loc_count:5d}")
        output.append(f"  locret_* in offset tables:  {locret_count:5d}")
        output.append(f"  nullsub_* in offset tables: {nullsub_count:5d}")
        output.append(f"  Total:                      {len(sub_labels) + len(table_labels):5d}")
        return "\n".join(output)

    # Show full list
    output.append("\nSUB_* PROCEDURES ({} total):".format(len(sub_labels)))
    output.append("-" * 80)

    if sub_labels:
        prev_range = None
        for label_name, line_num in sub_labels:
            addr = label_name[4:]  # Remove 'sub_'
            addr_range = addr[0] if addr else "?"

            if addr_range != prev_range:
                output.append(f"\n  {addr_range}xxxx range:")
                prev_range = addr_range

            output.append(f"    Line {line_num:6d}: {label_name}")

    output.append("\n\nOFFSET TABLE ENTRIES ({} total):".format(len(table_labels)))
    output.append("-" * 80)
    output.append("(loc_*, locret_*, nullsub_* referenced in jump tables)")

    if table_labels:
        prev_range = None
        for label_name, line_num in table_labels:
            # Get address from label name
            parts = label_name.split("_")
            addr = parts[1] if len(parts) > 1 else "?"
            addr_range = addr[0] if addr else "?"

            if addr_range != prev_range:
                output.append(f"\n  {addr_range}xxxx range:")
                prev_range = addr_range

            output.append(f"    Line {line_num:6d}: {label_name}")

    return "\n".join(output)


def main():
    print(
        "ERROR: find_unnamed_procedures.py targets the retired monolithic "
        "disassembly. Use make find-unanalyzed for the module-aware "
        "hypothesis review queue."
    )
    return 1

    parser = argparse.ArgumentParser(description="Find unnamed procedures in Alien Soldier disassembly")

    parser.add_argument(
        "input", nargs="?", default="alien_soldier_j.s", help="Input disassembly file (default: alien_soldier_j.s)"
    )

    parser.add_argument("--output", help="Output file for results")

    parser.add_argument("--stats", action="store_true", help="Show statistics only")

    parser.add_argument(
        "--list", action="store_true", help="Output as simple list (one procedure per line) instead of detailed report"
    )

    parser.add_argument(
        "--exclude-analyzed", metavar="CSV_FILE", help="Exclude procedures already analyzed (from analysis_results.csv)"
    )

    args = parser.parse_args()

    print("=" * 80)
    print("ALIEN SOLDIER - UNNAMED PROCEDURES FINDER")
    print("=" * 80)
    print(f"Input file: {args.input}")
    print("=" * 80)
    print()

    # Read file
    lines = read_disassembly(args.input)
    print(f"OK Loaded {len(lines):,} lines from {args.input}")
    print()

    # Find procedures
    sub_labels, table_labels, label_lines = find_unnamed_procedures(lines)
    print(f"OK Found {len(sub_labels):,} sub_* procedures")
    print(f"OK Found {len(table_labels):,} offset table entries (loc_/locret_/nullsub_)")

    # Filter out already analyzed procedures if requested
    if args.exclude_analyzed:
        print(f"Loading analyzed procedures from {args.exclude_analyzed}...")
        analyzed = load_analyzed_procedures(args.exclude_analyzed)
        print(f"OK Found {len(analyzed):,} already analyzed procedures")

        # Filter
        sub_labels = [(name, line) for name, line in sub_labels if name not in analyzed]
        table_labels = [(name, line) for name, line in table_labels if name not in analyzed]

        print(
            f"OK Remaining after filtering: {len(sub_labels):,} sub_* + {len(table_labels):,} table = {len(sub_labels) + len(table_labels):,} total"
        )

    print()
    print("=" * 80)
    print()

    # Format output
    if args.list:
        output_text = format_simple_list(sub_labels, table_labels)
    else:
        output_text = format_output(sub_labels, table_labels, args.stats)

    # Print to console (only if not writing to file or if stats mode)
    if not args.output or args.stats:
        print(output_text)

    # Write to file if requested
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_text)
        print(f"\nOK Results saved to {args.output}")
        if args.list:
            print(f"OK Saved {len(sub_labels) + len(table_labels)} procedure names (one per line)")


if __name__ == "__main__":
    raise SystemExit(main())
