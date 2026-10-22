#!/usr/bin/env python3
"""
Validate Movie Description Files

Validates frame interval descriptions in movies/*.txt files:
1. First interval starts at frame 20
2. In each interval: left < right
3. No overlap: previous_right < next_left
4. Proper spacing: next_left = previous_right + 20

Usage:
    python scripts/validate_movie_descriptions.py
"""

import os
import re
from pathlib import Path


def parse_interval_line(line):
    """Parse a line like '20-300, Sega screen' into (left, right, description)."""
    # Match pattern: digits-digits, text
    pattern = r"^(\d+)-(\d+),\s*(.+)$"
    match = re.match(pattern, line.strip())

    if not match:
        return None

    left = int(match.group(1))
    right = int(match.group(2))
    description = match.group(3)

    return (left, right, description)


def validate_description_file(file_path):
    """Validate a single movie description file."""
    print(f"\nValidating: {file_path}")
    print("=" * 80)

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if len(lines) < 2:
        print(f"  ERROR: File too short (expected header + data)")
        return False

    # Skip header line
    header = lines[0].strip()
    if header != "Frames, Scene":
        print(f"  WARNING: Unexpected header: '{header}'")

    intervals = []
    errors = []
    warnings = []

    # Parse all intervals
    for line_num, line in enumerate(lines[1:], start=2):
        line = line.strip()
        if not line:
            continue

        parsed = parse_interval_line(line)
        if parsed is None:
            errors.append(f"  Line {line_num}: Failed to parse: '{line}'")
            continue

        intervals.append((line_num, parsed))

    if not intervals:
        print(f"  ERROR: No valid intervals found")
        return False

    # Validation 1: First interval should start at frame 20
    first_line_num, (first_left, first_right, first_desc) = intervals[0]
    if first_left != 20:
        errors.append(f"  Line {first_line_num}: First interval should start at frame 20, got {first_left}")

    # Validation 2, 3 & 4: Check each interval
    prev_line_num = None
    prev_right = None

    for line_num, (left, right, desc) in intervals:
        # Check left < right
        if left >= right:
            errors.append(f"  Line {line_num}: Invalid interval {left}-{right} (left >= right)")

        # Check no overlap with previous interval (except for first line)
        if prev_right is not None:
            if prev_right >= left:
                errors.append(
                    f"  Line {line_num}: Overlap detected - previous interval ends at {prev_right}, current starts at {left}"
                )

        # Check interval continuity (except for first line)
        if prev_right is not None:
            expected_left = prev_right + 20
            if left != expected_left:
                gap = left - prev_right
                errors.append(
                    f"  Line {line_num}: Interval should start at {expected_left} (prev_right + 20), got {left} (gap: {gap})"
                )

        prev_line_num = line_num
        prev_right = right

    # Print results
    if errors:
        print(f"\n  Found {len(errors)} error(s):")
        for error in errors:
            print(error)

    if warnings:
        print(f"\n  Found {len(warnings)} warning(s):")
        for warning in warnings:
            print(warning)

    if not errors and not warnings:
        print(f"  OK: All {len(intervals)} intervals are valid")
        print(f"  OK: First interval: {first_left}-{first_right}")
        print(f"  OK: Last interval: {prev_right}")
        print(f"  OK: Total frames covered: {prev_right - first_left}")

    return len(errors) == 0


def main():
    """Validate all movie description files."""
    movies_dir = Path("movies")

    if not movies_dir.exists():
        print("Error: movies/ directory not found")
        return 1

    # Find all *_description.txt files
    description_files = sorted(movies_dir.glob("*_description.txt"))

    if not description_files:
        print("Error: No *_description.txt files found in movies/")
        return 1

    print("=" * 80)
    print("MOVIE DESCRIPTION VALIDATOR")
    print("=" * 80)
    print(f"Found {len(description_files)} description file(s)")

    all_valid = True
    for desc_file in description_files:
        valid = validate_description_file(desc_file)
        if not valid:
            all_valid = False

    print("\n" + "=" * 80)
    if all_valid:
        print("RESULT: ALL FILES VALID")
    else:
        print("RESULT: VALIDATION FAILED - Please fix errors above")
    print("=" * 80)

    return 0 if all_valid else 1


if __name__ == "__main__":
    exit(main())
