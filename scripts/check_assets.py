#!/usr/bin/env python3
"""Validate locally extracted ROM segments without modifying them."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="assets/manifest.json")
    parser.add_argument("--asset-dir", default="data")
    parser.add_argument(
        "--preserve-manifest", action="append", default=[],
        help="Additional manifest whose paths are allowed during stale-file checks",
    )
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.is_file():
        fail(f"Asset manifest not found: {manifest_path}")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1:
        fail(f"Unsupported asset manifest schema: {manifest.get('schema_version')}")

    assets = manifest.get("assets", [])
    if not assets:
        fail("Asset manifest contains no extracted segments")

    asset_dir = Path(args.asset_dir)
    problems: list[str] = []
    expected_paths = {Path(asset["path"]) for asset in assets}
    for preserve_manifest in args.preserve_manifest:
        preserve_document = json.loads(
            Path(preserve_manifest).read_text(encoding="utf-8")
        )
        expected_paths.update(
            Path(asset["path"])
            for asset in preserve_document.get("assets", [])
        )
    managed_regions = {asset["region"] for asset in assets}
    for asset in assets:
        path = asset_dir / asset["path"]
        if not path.is_file():
            problems.append(f"{asset['path']}: missing (run 'make split')")
            continue
        data = path.read_bytes()
        if len(data) != asset["size"]:
            problems.append(f"{asset['path']}: size {len(data)}, expected {asset['size']}")
            continue
        digest = hashlib.sha1(data).hexdigest()
        if digest != asset["sha1"]:
            problems.append(f"{asset['path']}: SHA1 {digest}, expected {asset['sha1']}")

    for region in managed_regions:
        region_dir = asset_dir / region
        if not region_dir.is_dir():
            continue
        for path in region_dir.rglob("*.bin"):
            relative = path.relative_to(asset_dir)
            if relative not in expected_paths:
                problems.append(f"{relative.as_posix()}: unexpected stale extracted file")

    if problems:
        for problem in problems:
            print(f"[ERROR] {problem}", file=sys.stderr)
        print(
            f"[FAIL] {len(problems)} of {len(assets)} extracted segments are missing or altered",
            file=sys.stderr,
        )
        return 1

    profile = manifest.get("reference_rom", {}).get("profile", "declared")
    print(f"[OK] {len(assets)} extracted segments match the {profile} manifest")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
