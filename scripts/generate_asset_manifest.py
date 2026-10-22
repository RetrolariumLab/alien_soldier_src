#!/usr/bin/env python3
"""Regenerate asset range hashes from the canonical private ROM."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_ranges(path: Path) -> list[dict]:
    assets: list[dict] = []
    seen_paths: set[str] = set()
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = [part.strip() for part in line.split(",")]
        if len(parts) != 4:
            fail(f"{path}:{line_number}: expected name,start,end,region")
        name, start_text, end_text, region = parts
        start = int(start_text, 16)
        end = int(end_text, 16)
        if end <= start:
            fail(f"{path}:{line_number}: invalid range {start_text}-{end_text}")
        asset_path = f"{region}/{name}.bin"
        if asset_path in seen_paths:
            fail(f"{path}:{line_number}: duplicate asset path {asset_path}")
        seen_paths.add(asset_path)
        assets.append(
            {
                "name": name,
                "path": asset_path,
                "region": region,
                "address": f"0x{start:X}",
                "end": f"0x{end:X}",
                "size": end - start,
            }
        )
    return assets


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="assets/manifest.json")
    parser.add_argument("--rom", default="Alien Soldier (J) [!].bin")
    parser.add_argument("--ranges", default="data/data_addrs.txt")
    parser.add_argument("--asset-dir", default="data")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    reference = manifest["reference_rom"]
    rom = Path(args.rom).read_bytes()
    rom_sha1 = hashlib.sha1(rom).hexdigest()
    if len(rom) != reference["size"] or rom_sha1 != reference["sha1"]:
        fail(f"Input is not the canonical ROM: {len(rom)} bytes, SHA1 {rom_sha1}")

    assets = parse_ranges(Path(args.ranges))
    asset_dir = Path(args.asset_dir)
    for asset in assets:
        start = int(asset["address"], 16)
        end = int(asset["end"], 16)
        if end > len(rom):
            fail(f"{asset['path']}: range ends beyond the canonical ROM")
        data = rom[start:end]
        extracted_path = asset_dir / asset["path"]
        if not extracted_path.is_file() or extracted_path.read_bytes() != data:
            fail(f"{asset['path']}: extracted file is missing or differs; run 'make split'")
        asset["sha1"] = hashlib.sha1(data).hexdigest()

    manifest["assets"] = assets
    # newline="" keeps LF on Windows, where the default would write CRLF into a
    # tracked file and fail the repository text-hygiene check.
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="",
    )
    print(f"[OK] Recorded {len(assets)} canonical asset ranges in {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
