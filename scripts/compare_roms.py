#!/usr/bin/env python3
"""
ROM Comparison Tool

Compares built ROM with original ROM to verify they are identical.
"""

import sys
import argparse
import hashlib
import json
from pathlib import Path


def compare_files(file1, file2):
    """Compare two binary files byte-by-byte."""
    with open(file1, 'rb') as f1, open(file2, 'rb') as f2:
        data1 = f1.read()
        data2 = f2.read()

    return compare_files_bytes(data1, data2)


def compare_files_bytes(data1, data2):
    """Compare in-memory images; kept separate for negative-path tests."""
    if len(data1) != len(data2):
        return False, f"Size mismatch: {len(data1)} vs {len(data2)} bytes"

    if data1 == data2:
        return True, "Files are identical"

    # Find first difference
    for i, (b1, b2) in enumerate(zip(data1, data2)):
        if b1 != b2:
            return False, f"First difference at offset 0x{i:X}: 0x{b1:02X} vs 0x{b2:02X}"

    return True, "Files are identical"


def main():
    parser = argparse.ArgumentParser(description='Compare built ROM with original')
    parser.add_argument('--built', default='asbuilt.bin', help='Built ROM file')
    parser.add_argument('--original', default='Alien Soldier (J) [!].bin', help='Canonical ROM file')
    parser.add_argument('--manifest', default='assets/manifest.json', help='Asset manifest')
    parser.add_argument('--project-dir', default='.', help='Project directory')

    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    built_file = project_dir / args.built
    original_file = project_dir / args.original

    # Check files exist
    if not built_file.exists():
        print(f"Error: Built ROM not found: {built_file}")
        print("Run 'make build' first")
        return 1

    if not original_file.exists():
        print(f"Error: Original ROM not found: {original_file}")
        return 1

    manifest = json.loads(Path(args.manifest).read_text(encoding='utf-8'))
    reference = manifest['reference_rom']
    original_data = original_file.read_bytes()
    original_sha1 = hashlib.sha1(original_data).hexdigest()
    if len(original_data) != reference['size'] or original_sha1 != reference['sha1']:
        reference_name = reference.get('name', 'declared preservation')
        print(f"Error: {original_file.name} is not the {reference_name} ROM")
        print(f"  Expected: {reference['size']} bytes, SHA1 {reference['sha1']}")
        print(f"  Actual:   {len(original_data)} bytes, SHA1 {original_sha1}")
        return 1

    # Compare files
    identical, message = compare_files(built_file, original_file)

    if identical:
        print("=" * 60)
        print("SUCCESS: ROMs are identical!")
        print("=" * 60)
        print(f"  Built:    {built_file.name} ({built_file.stat().st_size:,} bytes)")
        print(f"  Original: {original_file.name} ({original_file.stat().st_size:,} bytes)")
        print()
        reference_name = reference.get('name', 'declared preservation')
        print(f"[OK] Byte-identical {reference_name} ROM reproduced (SHA1 {original_sha1})")
        print("[OK] The complete assembled source preserves every declared byte")
        return 0
    else:
        print("=" * 60)
        print("MISMATCH: ROMs differ!")
        print("=" * 60)
        print(f"  Built:    {built_file.name} ({built_file.stat().st_size:,} bytes)")
        print(f"  Original: {original_file.name} ({original_file.stat().st_size:,} bytes)")
        print()
        print(f"Difference: {message}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
