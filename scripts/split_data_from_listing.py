#!/usr/bin/env python3
"""Retired single-file data splitter, retained as historical source.

The CLI refuses to run: it bypassed the preservation asset manifest and
cannot operate on the ROM-ordered modules. The canonical extraction path is
``make split``.
"""

import re
import argparse
import shutil
from pathlib import Path
from datetime import datetime


def parse_dc_value(value_str, dc_type):
    """Parse a single dc value and return bytes."""
    value_str = value_str.strip()
    if not value_str:
        return None

    # String literal: 'text' or "text"
    if value_str.startswith(("'", '"')):
        text = value_str[1:-1]
        return text.encode("latin1")

    # Hex: $XXXX or 0xXXXX (check BEFORE label detection!)
    if value_str.startswith("$"):
        try:
            num = int(value_str[1:], 16)
        except ValueError:
            return None  # Invalid hex = probably a label
    elif value_str.startswith("0x") or value_str.startswith("0X"):
        try:
            num = int(value_str, 16)
        except ValueError:
            return None
    # Binary: %XXXX
    elif value_str.startswith("%"):
        try:
            num = int(value_str[1:], 2)
        except ValueError:
            return None
    # Decimal
    elif value_str.lstrip("-").isdigit():
        num = int(value_str)
    else:
        # Not a recognized numeric format - must be a label reference
        return None

    # Convert to bytes
    if dc_type == "dc.b":
        if num < 0:
            num = (256 + num) & 0xFF
        return bytes([num & 0xFF])
    elif dc_type == "dc.w":
        if num < 0:
            num = (65536 + num) & 0xFFFF
        return num.to_bytes(2, "big", signed=False)
    elif dc_type == "dc.l":
        if num < 0:
            num = (4294967296 + num) & 0xFFFFFFFF
        return num.to_bytes(4, "big", signed=False)

    return None


def parse_dc_line(line):
    """
    Parse a dc.b/dc.w/dc.l line and return binary data.
    Returns None if line contains label references.
    """
    # Extract dc directive and values
    match = re.match(r"^\s*(dc\.[bwl])\s+(.+?)(?:\s*;.*)?$", line, re.IGNORECASE)
    if not match:
        return None

    dc_type = match.group(1).lower()
    values_str = match.group(2)

    # Split by comma (handling quotes)
    values = []
    current = ""
    in_quote = False
    quote_char = None

    for char in values_str + ",":
        if char in ('"', "'") and not in_quote:
            in_quote = True
            quote_char = char
            current += char
        elif char == quote_char and in_quote:
            in_quote = False
            quote_char = None
            current += char
        elif char == "," and not in_quote:
            if current.strip():
                values.append(current.strip())
            current = ""
        else:
            current += char

    # Convert to binary
    result = bytearray()
    for val in values:
        data = parse_dc_value(val, dc_type)
        if data is None:
            return None  # Label reference found
        result.extend(data)

    return bytes(result) if result else None


def split_data_blocks(lines, min_size=1024, label_filter=None):
    """
    Find and extract data blocks.
    Returns list of blocks with binary data.
    """
    filter_info = f", filter: {label_filter}" if label_filter else ""
    print(f"Scanning for data blocks (min {min_size} bytes{filter_info})...")

    label_re = re.compile(r"^([a-zA-Z_][a-zA-Z0-9_]*):")
    dc_re = re.compile(r"^\s*dc\.[bwl]\s+", re.IGNORECASE)

    def matches_filter(label):
        if label_filter is None:
            return True
        return re.match(label_filter, label) is not None

    blocks = []
    current_block = None

    for line_num, line in enumerate(lines, 1):
        # Skip empty lines and pure comments
        if not line.strip() or line.strip().startswith(";"):
            continue

        # Check for label
        label_match = label_re.match(line)
        if label_match:
            # Finalize previous block if large enough and matches filter
            if current_block and len(current_block["data"]) >= min_size and matches_filter(current_block["label"]):
                blocks.append(current_block)
                print(
                    f"  [{len(blocks)}] {current_block['label']}: {len(current_block['data'])} bytes "
                    f"(lines {current_block['start_line']}-{current_block['end_line']})"
                )

            # Start new block
            label = label_match.group(1)
            rest = line[len(label) + 1 :].strip()

            # Check if label line has dc data
            if rest and dc_re.match(rest):
                data = parse_dc_line(rest)
                if data:
                    current_block = {
                        "label": label,
                        "start_line": line_num,
                        "end_line": line_num,
                        "data": bytearray(data),
                    }
                else:
                    current_block = None
            else:
                current_block = None
            continue

        # Check for dc line
        if current_block and dc_re.match(line):
            data = parse_dc_line(line)
            if data:
                current_block["data"].extend(data)
                current_block["end_line"] = line_num
            else:
                # Label reference - finalize block
                if len(current_block["data"]) >= min_size and matches_filter(current_block["label"]):
                    blocks.append(current_block)
                    print(
                        f"  [{len(blocks)}] {current_block['label']}: {len(current_block['data'])} bytes "
                        f"(lines {current_block['start_line']}-{current_block['end_line']})"
                    )
                current_block = None
        elif current_block:
            # Non-dc line - finalize block
            if len(current_block["data"]) >= min_size and matches_filter(current_block["label"]):
                blocks.append(current_block)
                print(
                    f"  [{len(blocks)}] {current_block['label']}: {len(current_block['data'])} bytes "
                    f"(lines {current_block['start_line']}-{current_block['end_line']})"
                )
            current_block = None

    # Finalize last block
    if current_block and len(current_block["data"]) >= min_size and matches_filter(current_block["label"]):
        blocks.append(current_block)
        print(
            f"  [{len(blocks)}] {current_block['label']}: {len(current_block['data'])} bytes "
            f"(lines {current_block['start_line']}-{current_block['end_line']})"
        )

    return blocks


def save_binary_files(blocks, data_dir, prefix=""):
    """Save binary data to files."""
    data_dir.mkdir(exist_ok=True)

    for block in blocks:
        # Don't add prefix if label already starts with tiles_ or sprite_
        if block["label"].startswith(("tiles_", "sprite_")):
            filename = f"{block['label']}.bin"
        else:
            filename = f"{prefix}{block['label']}.bin" if prefix else f"{block['label']}.bin"
        filepath = data_dir / filename

        with open(filepath, "wb") as f:
            f.write(block["data"])

        block["filename"] = filename


def replace_with_binclude(lines, blocks, data_dir):
    """Replace data blocks with binclude directives."""
    new_lines = lines.copy()
    offset = 0

    for block in blocks:
        start_idx = block["start_line"] - 1 + offset
        end_idx = block["end_line"] + offset

        # Get label line
        label_line = new_lines[start_idx]
        label_match = re.match(r"^([a-zA-Z_][a-zA-Z0-9_]*:)(.*)", label_line)

        if not label_match:
            print(f"Warning: Could not find label at line {block['start_line']}")
            continue

        label_part = label_match.group(1)
        rest = label_match.group(2)

        # Extract comment if present
        comment = ""
        if ";" in rest:
            comment_start = rest.index(";")
            comment = rest[comment_start:].rstrip()

        # Create replacement
        replacement = f'{label_part}\tbinclude\t"{data_dir.name}/{block["filename"]}"\t{comment}\n'
        replacement += f"{block['label']}_End:\n"

        # Replace block
        num_lines = end_idx - start_idx
        new_lines[start_idx:end_idx] = [replacement]
        offset -= num_lines - 1

    return new_lines


def main():
    print(
        "ERROR: split_data_from_listing.py is retired. It would rewrite one "
        "source file and generate payloads outside the asset manifest. "
        "Use make split for canonical ROM extraction."
    )
    return 1

    parser = argparse.ArgumentParser(description="Split large data blocks to binary files with binclude")
    parser.add_argument("--source", default="alien_soldier_j.s", help="Assembly source file")
    parser.add_argument("--data-dir", default="data", help="Directory for binary files")
    parser.add_argument("--min-size", type=int, default=1024, help="Minimum block size in bytes")
    parser.add_argument("--project-dir", default=".", help="Project directory")
    parser.add_argument("--dry-run", action="store_true", help="Preview without making changes")
    parser.add_argument("--label-filter", default=None, help='Regex pattern to filter labels (e.g., "sprite_F.*")')

    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    asm_file = project_dir / args.source
    data_dir = project_dir / args.data_dir

    if not asm_file.exists():
        print(f"Error: Assembly file not found: {asm_file}")
        return 1

    # Read source
    print(f"Reading {asm_file}...")
    with open(asm_file, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    print(f"Source: {len(lines):,} lines\n")

    # Find and parse data blocks
    blocks = split_data_blocks(lines, args.min_size, args.label_filter)

    if not blocks:
        print("\nNo data blocks found")
        return 0

    # Summary
    total_bytes = sum(len(b["data"]) for b in blocks)
    total_lines = sum(b["end_line"] - b["start_line"] + 1 for b in blocks)

    print(f"\nSummary:")
    print(f"  Blocks found: {len(blocks)}")
    print(f"  Total data: {total_bytes:,} bytes ({total_bytes / 1024:.1f} KB)")
    print(f"  Lines to replace: {total_lines:,}")
    print(f"  New lines: ~{len(blocks) * 2:,}")
    print(f"  Savings: ~{total_lines - len(blocks) * 2:,} lines")

    if args.dry_run:
        print("\n*** DRY RUN - No files modified ***")
        return 0

    # Create backup
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = asm_file.parent / f"{asm_file.stem}_backup_{timestamp}{asm_file.suffix}"
    print(f"\nCreating backup: {backup_file.name}")
    shutil.copy2(asm_file, backup_file)

    # Save binary files
    print(f"\nSaving binary files to {data_dir}/...")
    save_binary_files(blocks, data_dir)

    # Replace in source
    print(f"\nReplacing blocks with binclude directives...")
    new_lines = replace_with_binclude(lines, blocks, data_dir)

    # Write modified source
    print(f"Writing modified source...")
    with open(asm_file, "w", encoding="utf-8", newline="\n") as f:
        f.writelines(new_lines)

    print(f"\n[OK] Success!")
    print(f"  Extracted {len(blocks)} blocks to {data_dir}/")
    print(f"  Modified: {asm_file}")
    print(f"  Backup: {backup_file}")
    print(f"  Reduced by {total_lines - len(new_lines):,} lines")
    print(f"\nNext step: make build")

    return 0


if __name__ == "__main__":
    import sys

    sys.exit(main())
