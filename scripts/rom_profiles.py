#!/usr/bin/env python3
"""Load and validate Alien Soldier preservation-profile declarations."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


PROFILE_ID = re.compile(r"[a-z][a-z0-9_-]*\Z")
HEX_DIGESTS = {"sha1": 40, "sha256": 64, "md5": 32}
PROFILE_PATH_FIELDS = (
    "source",
    "object",
    "listing",
    "output",
    "asset_manifest",
    "asset_ranges",
    "asset_directory",
    "rom_layout",
)


class ProfileError(ValueError):
    """Raised when the profile contract is malformed or incomplete."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ProfileError(message)


def _validate_reference(profile_id: str, reference: Any) -> None:
    _require(isinstance(reference, dict), f"profile {profile_id}: reference_rom is not an object")
    for field in ("name", "filename", "padding_byte"):
        _require(
            isinstance(reference.get(field), str) and reference[field],
            f"profile {profile_id}: reference_rom.{field} is missing",
        )
    _require(
        isinstance(reference.get("size"), int) and reference["size"] > 0,
        f"profile {profile_id}: reference_rom.size is invalid",
    )
    for field, length in HEX_DIGESTS.items():
        value = reference.get(field, "")
        _require(
            isinstance(value, str) and re.fullmatch(rf"[0-9a-f]{{{length}}}", value),
            f"profile {profile_id}: reference_rom.{field} is invalid",
        )
    crc32 = reference.get("crc32", "")
    _require(
        isinstance(crc32, str) and re.fullmatch(r"[0-9A-F]{8}", crc32),
        f"profile {profile_id}: reference_rom.crc32 is invalid",
    )
    _require(
        re.fullmatch(r"0x[0-9A-Fa-f]{2}", reference["padding_byte"]) is not None,
        f"profile {profile_id}: reference_rom.padding_byte is invalid",
    )


def load_profiles(path: Path) -> dict[str, Any]:
    """Return a validated profile manifest indexed by profile id."""
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ProfileError(f"cannot read profile manifest {path}: {error}") from error
    _require(document.get("schema_version") == 1, "unsupported ROM-profile schema")
    records = document.get("profiles")
    _require(isinstance(records, list) and records, "profile manifest contains no profiles")
    profiles: dict[str, dict[str, Any]] = {}
    for record in records:
        _require(isinstance(record, dict), "profile entry is not an object")
        profile_id = record.get("id", "")
        _require(
            isinstance(profile_id, str) and PROFILE_ID.fullmatch(profile_id) is not None,
            f"invalid profile id: {profile_id!r}",
        )
        _require(profile_id not in profiles, f"duplicate profile id: {profile_id}")
        _require(
            record.get("status") in {"integration", "supported"},
            f"profile {profile_id}: invalid status",
        )
        for field in PROFILE_PATH_FIELDS:
            _require(
                isinstance(record.get(field), str) and record[field],
                f"profile {profile_id}: {field} is missing",
            )
        _validate_reference(profile_id, record.get("reference_rom"))
        profiles[profile_id] = record
    default = document.get("default_profile")
    _require(default in profiles, "default_profile does not name a declared profile")
    document["profiles_by_id"] = profiles
    return document


def select_profile(path: Path, profile_id: str, require_supported: bool = False) -> dict[str, Any]:
    """Return one declared profile, optionally requiring release support."""
    document = load_profiles(path)
    try:
        profile = document["profiles_by_id"][profile_id]
    except KeyError as error:
        known = ", ".join(document["profiles_by_id"])
        raise ProfileError(f"unknown ROM profile {profile_id!r}; expected one of: {known}") from error
    if require_supported and profile["status"] != "supported":
        raise ProfileError(f"ROM profile {profile_id!r} is {profile['status']}, not supported")
    return profile


def nested_value(record: dict[str, Any], field: str) -> Any:
    value: Any = record
    for part in field.split("."):
        if not isinstance(value, dict) or part not in value:
            raise ProfileError(f"profile field is not declared: {field}")
        value = value[part]
    if isinstance(value, (dict, list)):
        return json.dumps(value, separators=(",", ":"))
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default="config/rom_profiles.json")
    parser.add_argument("--profile")
    parser.add_argument("--field")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--require-supported", action="store_true")
    args = parser.parse_args()
    try:
        document = load_profiles(Path(args.config))
        if args.list:
            for profile in document["profiles"]:
                print(f"{profile['id']}\t{profile['status']}\t{profile['name']}")
            return 0
        profile_id = args.profile or document["default_profile"]
        profile = select_profile(Path(args.config), profile_id, require_supported=args.require_supported)
        if args.field:
            print(nested_value(profile, args.field))
        else:
            print(json.dumps(profile, indent=2))
        return 0
    except ProfileError as error:
        print(f"[ERROR] {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
