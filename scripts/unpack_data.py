#!/usr/bin/env python3
"""
Unpack LZSS-compressed data from extracted .bin files.

Scans data subdirectories and attempts to decompress all .bin files.
Creates 'uncompressed' subfolder in each directory where at least one
file was successfully decompressed.
"""

import os
import sys
import argparse
from array import array
from pathlib import Path


def unpack_data(data):
    """
    Decompress LZSS data.

    Format:
    - First 2 bytes: size of compressed data
    - Rest: LZSS compressed data

    Returns:
        (decompressed_bytes, error_message)
        - On success: (data, None)
        - On failure: (None, "error description")
    """
    if len(data) < 3:
        return None, f"file too small ({len(data)} bytes)"

    arr = array("B", data)
    res = array("B")
    idx = 2
    idx_res = 0
    size = arr[0] * 0x100 + arr[1]

    if size < 2:
        return None, f"invalid size header: {size}"

    if size > len(arr):
        return None, f"size header ({size}) exceeds file ({len(arr)} bytes)"

    try:
        while idx <= size and idx < len(arr):
            byte_read = arr[idx]

            if byte_read >= 0x80:  # Backreference
                tmp = byte_read
                cnt = ((byte_read >> 2) & 0x1F) + 1
                tmp = (tmp << 8) & 0xFFFF
                idx += 1
                if idx >= len(arr):
                    return None, f"unexpected end at offset {idx} (backreference)"
                s = arr[idx]
                tmp += s
                tmp = (tmp & 0x3FF) + 1
                idx_window = idx_res - tmp
                if idx_window < 0:
                    return None, f"invalid backreference at offset {idx}"
                for _ in range(cnt + 1):
                    if idx_window >= len(res):
                        return None, f"backreference out of bounds at offset {idx}"
                    s = res[idx_window]
                    idx_window += 1
                    res.append(s)
                    idx_res += 1
            else:
                if (byte_read & (1 << 5)) != 0:
                    if (byte_read & (1 << 6)) != 0:  # RLE with varying second byte
                        cnt = (byte_read & 0x1F) + 1
                        idx += 1
                        if idx >= len(arr):
                            return None, f"unexpected end at offset {idx} (RLE varying)"
                        z = arr[idx]
                        for _ in range(cnt + 1):
                            res.append(z)
                            idx += 1
                            if idx >= len(arr):
                                return None, f"unexpected end at offset {idx}"
                            s = arr[idx]
                            res.append(s)
                            idx_res += 2
                    else:  # RLE single byte
                        cnt = (byte_read & 0x1F) + 1
                        idx += 1
                        if idx >= len(arr):
                            return None, f"unexpected end at offset {idx} (RLE single)"
                        s = arr[idx]
                        for _ in range(cnt + 1):
                            res.append(s)
                            idx_res += 1
                else:
                    if (byte_read & (1 << 6)) != 0:  # RLE byte pairs
                        cnt = (byte_read & 0x1F) + 1
                        if idx + 2 >= len(arr):
                            return None, f"unexpected end at offset {idx} (RLE pairs)"
                        s1 = arr[idx + 1]
                        s2 = arr[idx + 2]
                        idx += 2
                        for _ in range(cnt + 1):
                            res.append(s1)
                            res.append(s2)
                            idx_res += 2
                    else:  # Literal run
                        cnt = byte_read & 0x1F
                        for _ in range(cnt + 1):
                            idx += 1
                            if idx >= len(arr):
                                return None, f"unexpected end at offset {idx} (literal)"
                            s = arr[idx]
                            res.append(s)
                            idx_res += 1

            idx += 1

    except IndexError as e:
        return None, f"index error at offset {idx}: {e}"

    if len(res) == 0:
        return None, "decompression produced no output"

    return bytes(res), None


def process_directory(dir_path, verbose=False):
    """
    Process all .bin files in a directory.
    Returns (success_count, total_count, results_list)
    """
    bin_files = list(dir_path.glob("*.bin"))
    if not bin_files:
        return 0, 0, []

    results = []
    success = 0

    for bin_file in sorted(bin_files):
        with open(bin_file, "rb") as f:
            data = f.read()

        result, error = unpack_data(data)

        if error:
            results.append((bin_file.name, None, len(data), error))
        else:
            ratio = len(result) / len(data) if len(data) > 0 else 0
            results.append((bin_file.name, result, len(data), f"{ratio:.1f}x"))
            success += 1

    return success, len(bin_files), results


def main():
    parser = argparse.ArgumentParser(description="Unpack LZSS-compressed data from extracted .bin files")
    parser.add_argument("--data-dir", default="data", help="Data directory (default: data)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all files, not just successful ones")

    args = parser.parse_args()
    data_dir = Path(args.data_dir)

    if not data_dir.exists():
        print(f"Error: Data directory not found: {data_dir}")
        return 1

    # Find all subdirectories
    subdirs = [d for d in data_dir.iterdir() if d.is_dir() and d.name != "uncompressed"]

    if not subdirs:
        print(f"No subdirectories found in {data_dir}")
        return 0

    print(f"Scanning {len(subdirs)} subdirectories in {data_dir}/\n")

    total_success = 0
    total_files = 0

    for subdir in sorted(subdirs):
        success, total, results = process_directory(subdir, args.verbose)
        total_success += success
        total_files += total

        if total == 0:
            continue

        print(f"{subdir.name}/: {success}/{total} files decompressed")

        # Create uncompressed subfolder if we have successes
        if success > 0:
            output_dir = subdir / "uncompressed"
            output_dir.mkdir(exist_ok=True)

            for name, result, orig_size, info in results:
                if result is not None:
                    output_file = output_dir / name
                    with open(output_file, "wb") as f:
                        f.write(result)
                    if args.verbose:
                        print(f"  {name}: {orig_size} -> {len(result)} bytes ({info})")

            print(f"  -> saved to {subdir.name}/uncompressed/")

        # Show failures in verbose mode
        if args.verbose:
            for name, result, orig_size, info in results:
                if result is None:
                    print(f"  {name}: SKIP ({info})")

        print()

    # Summary
    print("=" * 50)
    print(f"Total: {total_success}/{total_files} files decompressed")

    return 0


if __name__ == "__main__":
    sys.exit(main())
