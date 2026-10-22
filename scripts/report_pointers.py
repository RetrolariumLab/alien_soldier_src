#!/usr/bin/env python3
"""Retired report for the monolithic pointer experiment.

The CLI refuses to run and never removes old diff directories. Use
``make verify-relocation`` for the current source layout.
"""

import os
import sys
import re
import argparse
import shutil
from pathlib import Path
from collections import defaultdict


def extract_address_from_label(label):
    """Extract hex address from label name like byte_121932 -> 0x121932"""
    match = re.match(r"(byte|word|dword|off|unk)_([0-9A-Fa-f]+)", label, re.IGNORECASE)
    if match:
        try:
            return int(match.group(2), 16)
        except ValueError:
            pass
    return None


def get_diff_frame_range(folder_path):
    """Get range of frames with visual differences (*_diff.png files).

    Returns: (min_frame, max_frame) or None if no diffs found
    """
    diff_files = [f for f in os.listdir(folder_path) if f.endswith("_diff.png")]

    if not diff_files:
        return None

    frames = []
    for f in diff_files:
        # Extract frame number from filename like "014220_diff.png"
        match = re.match(r"(\d+)_diff\.png", f)
        if match:
            frames.append(int(match.group(1)))

    if not frames:
        return None

    return (min(frames), max(frames))


def cleanup_empty_dirs(pointers_dir):
    """Remove empty directories and directories without *_diff.png files."""
    removed = 0
    kept = 0

    if not os.path.exists(pointers_dir):
        return removed, kept

    for label_dir in os.listdir(pointers_dir):
        label_path = os.path.join(pointers_dir, label_dir)

        if not os.path.isdir(label_path):
            continue

        # Check if directory has *_diff.png files
        diff_files = [f for f in os.listdir(label_path) if f.endswith("_diff.png")]

        if not diff_files:
            # Remove directory without visual diffs
            shutil.rmtree(label_path)
            removed += 1
        else:
            kept += 1

    return removed, kept


def analyze_results(pointers_dir):
    """Analyze results and build frame_range -> addresses mapping.

    Returns: dict mapping (min_frame, max_frame) -> list of (address, label)
    """
    frame_ranges = defaultdict(list)

    if not os.path.exists(pointers_dir):
        return frame_ranges

    for label_dir in os.listdir(pointers_dir):
        label_path = os.path.join(pointers_dir, label_dir)

        if not os.path.isdir(label_path):
            continue

        # Get frame range for this label
        frame_range = get_diff_frame_range(label_path)
        if frame_range is None:
            continue

        # Extract address from label
        address = extract_address_from_label(label_dir)
        if address is None:
            continue

        frame_ranges[frame_range].append((address, label_dir))

    return frame_ranges


def generate_report(frame_ranges):
    """Generate report from frame_ranges mapping."""
    if not frame_ranges:
        print("No problematic blocks found.")
        return

    print("=" * 80)
    print("POINTER DEBUG REPORT")
    print("=" * 80)
    print()

    # Sort by frame range start
    sorted_ranges = sorted(frame_ranges.items(), key=lambda x: x[0][0])

    # Collect all data for summary
    all_entries = []

    for (min_frame, max_frame), addresses in sorted_ranges:
        # Find max address for this range
        addresses.sort(key=lambda x: x[0], reverse=True)
        max_addr, max_label = addresses[0]

        all_entries.append(
            {
                "frame_range": (min_frame, max_frame),
                "max_address": max_addr,
                "max_label": max_label,
                "all_addresses": addresses,
            }
        )

    # Print summary (compact format for easy parsing)
    print("SUMMARY (frame_range -> max_problematic_address):")
    print("-" * 80)

    for entry in all_entries:
        min_f, max_f = entry["frame_range"]
        print(f"broken at {min_f:06d}-{max_f:06d}: max address ${entry['max_address']:06X} ({entry['max_label']})")

    print()
    print("=" * 80)
    print("DETAILED BREAKDOWN")
    print("=" * 80)

    for entry in all_entries:
        min_f, max_f = entry["frame_range"]
        print()
        print(f"Frame range {min_f:06d}-{max_f:06d}:")
        print(f"  Max problematic address: ${entry['max_address']:06X} ({entry['max_label']})")
        print(f"  All addresses causing breaks in this range ({len(entry['all_addresses'])} total):")

        # Show top 10 addresses
        for i, (addr, label) in enumerate(entry["all_addresses"][:10]):
            print(f"    ${addr:06X} - {label}")

        if len(entry["all_addresses"]) > 10:
            print(f"    ... and {len(entry['all_addresses']) - 10} more")

    print()
    print("=" * 80)

    # Find overall max address
    overall_max = max(all_entries, key=lambda x: x["max_address"])
    print()
    print("OVERALL HIGHEST PROBLEMATIC ADDRESS:")
    print(f"  ${overall_max['max_address']:06X} ({overall_max['max_label']})")
    print(f"  Breaks at frames {overall_max['frame_range'][0]:06d}-{overall_max['frame_range'][1]:06d}")
    print()
    print("This is the maximum address where inserting padding breaks the ROM.")
    print("Look for hardcoded references to data at or near this address.")
    print("=" * 80)


def main():
    print(
        "ERROR: the legacy pointer report is retired with debug-pointers. "
        "It used address-derived labels and removed prior diff directories. "
        "Use make verify-relocation for the current source layout."
    )
    return 1

    parser = argparse.ArgumentParser(description="Analyze pointer debug results")
    parser.add_argument("--diffs-dir", required=True, help="Diffs directory (e.g., diffs/tas)")
    parser.add_argument("--no-cleanup", action="store_true", help="Do not remove empty directories")

    args = parser.parse_args()

    diffs_dir = Path(args.diffs_dir)
    pointers_dir = diffs_dir / "pointers"

    if not pointers_dir.exists():
        print(f"ERROR: Pointers directory not found: {pointers_dir}")
        print("Run 'make debug-pointers' first to generate data.")
        return 1

    print(f"Analyzing: {pointers_dir}")
    print()

    # Cleanup empty directories
    if not args.no_cleanup:
        print("Cleaning up empty directories...")
        removed, kept = cleanup_empty_dirs(str(pointers_dir))
        print(f"  Removed: {removed} empty directories")
        print(f"  Kept:    {kept} directories with visual diffs")
        print()

    # Analyze results
    frame_ranges = analyze_results(str(pointers_dir))

    # Generate report
    generate_report(frame_ranges)

    return 0


if __name__ == "__main__":
    sys.exit(main())
