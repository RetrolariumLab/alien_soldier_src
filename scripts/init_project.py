#!/usr/bin/env python3
"""
Initialize Alien Soldier project from original ROM.

Steps:
1. Check original ROM exists
2. Extract data segments from original ROM
3. Build ROM from source
4. Verify the build byte for byte against the canonical ROM
"""

import os
import sys
import argparse
import subprocess
import hashlib
import json


def main():
    parser = argparse.ArgumentParser(description="Initialize Alien Soldier project")
    parser.add_argument("--orig-rom", required=True, help="Original ROM file")
    parser.add_argument("--manifest", required=True, help="Canonical ROM manifest")
    parser.add_argument("--data-dir", required=True, help="Data directory")
    parser.add_argument("--data-addrs", required=True, help="Data addresses file")
    parser.add_argument("--source", required=True, help="Assembly source file")
    parser.add_argument("--obj", required=True, help="AS object file")
    parser.add_argument("--output", required=True, help="Output ROM file")
    parser.add_argument("--as-bin", required=True, help="AS assembler binary")
    parser.add_argument("--p2bin", required=True, help="P2BIN converter")
    parser.add_argument("--as-args", default="", help="AS assembler arguments")
    parser.add_argument(
        "--preserve-manifest",
        action="append",
        default=[],
        help="Additional asset manifest whose extracted files must survive cleanup",
    )

    args = parser.parse_args()

    # Step 1: Check original ROM exists
    if not os.path.exists(args.orig_rom):
        print()
        print("ERROR: Original ROM not found!")
        print()
        print("Please place the original ROM file in the project root:")
        print(f"  {args.orig_rom}")
        print()
        return 1

    print("=== Initializing project ===")
    print()

    with open(args.orig_rom, "rb") as rom_file:
        original = rom_file.read()
    with open(args.manifest, "r", encoding="utf-8") as manifest_file:
        reference = json.load(manifest_file)["reference_rom"]
    original_sha1 = hashlib.sha1(original).hexdigest()
    if len(original) != reference["size"] or original_sha1 != reference["sha1"]:
        reference_name = reference.get("name", "declared preservation")
        print(f"ERROR: Input is not the {reference_name} ROM!")
        print(f"  Expected: {reference['size']} bytes, SHA1 {reference['sha1']}")
        print(f"  Actual:   {len(original)} bytes, SHA1 {original_sha1}")
        return 1

    # Step 2: Extract data segments
    print("Step 1: Extracting data from original ROM...")
    scripts_dir = os.path.dirname(os.path.abspath(__file__))
    split_script = os.path.join(scripts_dir, "split_data_from_rom.py")

    split_command = [
        sys.executable,
        split_script,
        "--rom-file",
        args.orig_rom,
        "--output",
        args.data_dir,
        "--addrs",
        args.data_addrs,
        "--manifest",
        args.manifest,
    ]
    for preserve_manifest in args.preserve_manifest:
        split_command.extend(["--preserve-manifest", preserve_manifest])
    result = subprocess.run(split_command)

    if result.returncode != 0:
        print("ERROR: Failed to extract data!")
        return 1
    print()

    result = subprocess.run(
        [
            sys.executable,
            os.path.join(scripts_dir, "check_assets.py"),
            "--manifest",
            args.manifest,
            "--asset-dir",
            args.data_dir,
        ]
    )
    if result.returncode != 0:
        print("ERROR: Extracted assets do not match the manifest!")
        return 1

    # Step 3: Build ROM from source
    print("Step 2: Building ROM from source...")
    build_script = os.path.join(scripts_dir, "build_rom.py")

    result = subprocess.run(
        [
            sys.executable,
            build_script,
            "--source",
            args.source,
            "--obj",
            args.obj,
            "--output",
            args.output,
            "--as-bin",
            args.as_bin,
            "--p2bin",
            args.p2bin,
            "--as-args=" + args.as_args,
            "--manifest",
            args.manifest,
            "--original-rom",
            args.orig_rom,
            "--verify",
        ]
    )

    if result.returncode != 0:
        print("ERROR: Failed to build ROM!")
        return 1
    print()

    print("=== Project initialized successfully! ===")
    print()
    print("Declared preservation ROM reproduced. You can now:")
    print("  make build   - Build ROM from source")
    print("  make compare - Compare with reference")
    return 0


if __name__ == "__main__":
    sys.exit(main())
