#!/usr/bin/env python3
"""
Extract data addresses from AS listing file.

Parses listing file to find all binclude directives and their addresses.
Outputs data_addrs.txt in format: name,start,end
"""

import os
import re
import sys
import argparse


def main():
    parser = argparse.ArgumentParser(description="Extract data addresses from listing")
    parser.add_argument("listing", help="AS listing file (.lst)")
    parser.add_argument("--data-dir", default="data", help="Data directory to check file sizes")
    parser.add_argument("-o", "--output", default="data/data_addrs.txt", help="Output file")

    args = parser.parse_args()

    if not os.path.exists(args.listing):
        print(f"Error: Listing file not found: {args.listing}")
        return 1

    # Pattern to match binclude lines in listing
    # Format: "   line/  addr :    label: binclude "path""
    # We need to extract the label name which contains the actual intended address
    # e.g., "118915/  11A664 :  byte_11A644: binclude ..." - label has 11A644, not listing addr 11A664
    pattern = re.compile(r'^\s*\d+/\s*([0-9A-Fa-f]+)\s*:\s*(\w+):\s*binclude\s+"([^"]+)"')

    entries = []

    print(f"Parsing {args.listing}...")
    with open(args.listing, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            match = pattern.match(line)
            if match:
                listing_addr = match.group(1)
                label = match.group(2)
                filepath = match.group(3)

                # Extract address from label name (e.g., byte_11A644 -> 11A644)
                # For labels with hex address suffix, use that address
                # For other labels (PCMPart1, sega_tiles, etc.), use listing address
                addr_match = re.search(r"_([0-9A-Fa-f]{5,6})$", label)
                if addr_match:
                    addr_hex = addr_match.group(1)
                else:
                    # Use listing address for special labels
                    addr_hex = listing_addr

                # Get filename without path and extension
                filename = os.path.basename(filepath)
                name = os.path.splitext(filename)[0]

                # Remove data_ prefix if present
                if name.startswith("data_"):
                    name = name[5:]

                start_addr = int(addr_hex, 16)

                # Get file size to calculate end address
                full_path = os.path.join(os.path.dirname(args.listing), filepath)
                if os.path.exists(full_path):
                    size = os.path.getsize(full_path)
                    end_addr = start_addr + size
                else:
                    # Try relative to current directory
                    if os.path.exists(filepath):
                        size = os.path.getsize(filepath)
                        end_addr = start_addr + size
                    else:
                        print(f"  Warning: File not found: {filepath}")
                        continue

                entries.append((name, start_addr, end_addr))

    # Sort by start address
    entries.sort(key=lambda x: x[1])

    print(f"Found {len(entries)} data segments")

    # Write output
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w") as f:
        f.write("# Alien Soldier ROM binary data segments (binclude addresses)\n")
        f.write("# Format: name,start,end\n")
        f.write(f"# Generated from {os.path.basename(args.listing)}\n")
        f.write("\n")
        for name, start, end in entries:
            f.write(f"{name},0x{start:X},0x{end:X}\n")

    print(f"Written to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
