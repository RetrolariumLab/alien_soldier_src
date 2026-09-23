#!/usr/bin/env python3
"""Verify vendored build tools and the pinned runtime emulator."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def platform_key(explicit: str | None) -> str:
    if explicit:
        return explicit
    return "windows_i386" if sys.platform == "win32" else "linux_x86_64"


def check_files(entries: list[dict], errors: list[str], notes: list[str]) -> int:
    checked = 0
    for entry in entries:
        path = Path(entry["path"])
        if not path.is_file():
            if entry.get("observed_only"):
                notes.append(f"{path} is not present; nothing to record")
                continue
            errors.append(f"{path} is missing")
            continue
        size = path.stat().st_size
        digest = sha256_of(path)
        if entry.get("observed_only"):
            notes.append(f"observed runtime {path}: {size} bytes, SHA256 {digest}")
            if digest != entry["sha256"] or size != entry["size"]:
                notes.append(f"{path} differs from the observed pinned runtime build")
            continue
        if size != entry["size"]:
            errors.append(f"{path} is {size} bytes, expected {entry['size']}")
        if digest != entry["sha256"]:
            errors.append(
                f"{path} SHA256 differs\n"
                f"        expected {entry['sha256']}\n"
                f"        actual   {digest}"
            )
        checked += 1
    return checked


def emulator_paths(
    entries: list[dict], override: Path | None, errors: list[str],
) -> tuple[Path | None, list[dict]]:
    """Bind the declared runtime files to the explicitly selected checkout.

    The manifest's first executable lives in its checkout's Output directory.
    Preserve each declared path relative to that checkout, without mutating the
    manifest or treating an override as permission to change its source pin.
    """
    if not entries:
        errors.append("emulator has no declared executable path")
        return None, []
    configured_checkout = Path(entries[0]["path"]).parent.parent.resolve()
    if override is None:
        return configured_checkout, entries
    checkout = override.resolve()
    remapped: list[dict] = []
    for entry in entries:
        path = Path(entry["path"]).resolve()
        try:
            relative = path.relative_to(configured_checkout)
        except ValueError:
            errors.append(f"declared emulator file {path} escapes its checkout")
            continue
        remapped.append({**entry, "path": str(checkout / relative)})
    return checkout, remapped


def emulator_git(checkout: Path, arguments: list[str], errors: list[str]) -> str | None:
    try:
        result = subprocess.run(
            ["git", "-C", str(checkout), *arguments],
            capture_output=True,
            text=True,
            timeout=15,
        )
    except (OSError, subprocess.SubprocessError) as error:
        errors.append(f"could not inspect emulator checkout at {checkout}: {error}")
        return None
    if result.returncode != 0:
        errors.append(f"could not inspect emulator checkout at {checkout}: {result.stderr.strip()}")
        return None
    return result.stdout.strip()


def check_emulator_commit(
    component: dict, errors: list[str], notes: list[str], checkout: Path | None = None,
) -> None:
    if checkout is None:
        checkout, _ = emulator_paths(component.get("files", {}).get("any", []), None, errors)
    if checkout is None:
        return
    if not (checkout / ".git").exists():
        errors.append(f"emulator Git checkout is absent at {checkout}")
        return
    top_level = emulator_git(checkout, ["rev-parse", "--show-toplevel"], errors)
    if top_level is None:
        return
    if Path(top_level).resolve() != checkout.resolve():
        errors.append(f"emulator directory {checkout} is not the checkout root {top_level}")
        return
    actual = emulator_git(checkout, ["rev-parse", "HEAD"], errors)
    expected = component["source_commit"]
    if actual is not None and actual != expected:
        errors.append(f"emulator is at {actual}, expected pinned commit {expected}")
    changes = emulator_git(
        checkout, ["status", "--porcelain=v1", "--untracked-files=no", "--ignore-submodules=none"], errors,
    )
    if changes:
        errors.append(f"emulator has tracked changes at {checkout}:\n{changes}")
    if actual == expected and changes == "":
        notes.append(f"emulator source is clean at {checkout}: {actual}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config/toolchain.json")
    parser.add_argument("--platform")
    parser.add_argument("--require-emulator", action="store_true")
    parser.add_argument(
        "--emulator-dir", type=Path,
        help="verify runtime files in this Git checkout instead of the manifest's default; requires a built emulator",
    )
    args = parser.parse_args(argv)

    config = json.loads(Path(args.config).read_text(encoding="utf-8"))
    key = platform_key(args.platform)
    errors: list[str] = []
    notes: list[str] = []
    checked = 0
    emulator_seen = False
    for component in config["components"]:
        files = component.get("files", {})
        entries = files.get(key, files.get("any", []))
        if component["id"] == "emulator":
            emulator_seen = True
            checkout, entries = emulator_paths(entries, args.emulator_dir, errors)
            if checkout is None:
                continue
            present = any(Path(entry["path"]).is_file() for entry in entries)
            if not present and not args.require_emulator and args.emulator_dir is None:
                notes.append("emulator is not built; it is required only by runtime targets")
                continue
            if not present:
                errors.append(f"emulator is not built at {checkout}; run 'make build-gens' for that checkout")
                continue
            check_emulator_commit(component, errors, notes, checkout)
        checked += check_files(entries, errors, notes)
    if not emulator_seen and (args.require_emulator or args.emulator_dir is not None):
        errors.append("toolchain manifest does not declare the required emulator")

    for note in notes:
        print(f"[INFO] {note}")
    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        print(f"[FAIL] toolchain does not match {args.config}", file=sys.stderr)
        return 1
    print(f"[OK] toolchain matches {args.config}: {checked} file(s) verified for {key}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
