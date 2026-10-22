#!/usr/bin/env python3
"""Verify that the exported symbol map covers layout and runtime contracts."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

from extract_symbols import EQU, LABEL, LISTING_ROW, SOURCE_COLUMN, load_resolved_symbols
from rom_profiles import load_profiles


SYMBOL_ROW = re.compile(r"^([0-9A-Fa-f]{8})\s+([A-Za-z_][A-Za-z0-9_]*)$")
PROFILE_FLAGS = {"jp": {"BuildProfileJP": 1, "BuildProfileEU": 0}, "eu": {"BuildProfileJP": 0, "BuildProfileEU": 1}}
IDENTITY_FIELDS = ("current_name", "address", "previous_name", "legacy_name")
ERROR_LIMIT = 20
JP_ONLY_NAME = "Reset_ChecksumLoop"
EXCLUSION_SOURCE = "src/system/boot.s"


def checksum_exclusion_proof(root: Path) -> dict:
    """One explicit exclusion: scalar JP checksum is the EU condition's else."""
    lines = tuple(
        " ".join(line.split(";", 1)[0].split())
        for line in (root / EXCLUSION_SOURCE).read_text(encoding="utf-8").splitlines()
    )
    first, following = "ChecksumCheck:", "movea.l #Checksum,a1"
    if lines.count(first) != 1 or lines.count(following) != 1:
        raise ValueError("JP-only checksum source has no unique conditional bounds")
    block = tuple(line for line in lines[lines.index(first) + 1 : lines.index(following)] if line)
    expected = (
        "movea.l #Reset,a0",
        "if BuildProfileEU",
        "move.w #$1FFD,d0",
        "moveq #0,d1",
        "Reset_ChecksumUnrolledLoop:",
        ".words := $80",
        "while .words > 0",
        "add.w (a0)+,d1",
        ".words := .words-1",
        "endm",
        "dbf d0,Reset_ChecksumUnrolledLoop",
        "else",
        "move.l #$60000,d0",
        "moveq #0,d1",
        "Reset_ChecksumLoop:",
        "add.w (a0)+,d1",
        "cmp.l a0,d0",
        "bcc.s Reset_ChecksumLoop",
        "endif",
    )
    if block != expected:
        raise ValueError("JP-only checksum conditional source differs from its proved branch")
    return {
        "source": EXCLUSION_SOURCE,
        "condition": "BuildProfileEU",
        "branch": "else",
        "normalized_block_sha256": canonical_sha256(block),
    }


def canonical_sha256(value) -> str:
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("ascii")
    ).hexdigest()


def origin_identity(records: list[dict]) -> str:
    """Fingerprint naming identity, not the prose basis of a reviewed name."""
    rows, seen = [], set()
    for record in records:
        name = record["current_name"]
        if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name) or name in seen:
            raise ValueError("invalid or duplicate origin name: %s" % name)
        seen.add(name)
        if isinstance(record["address"], bool):
            raise ValueError("invalid origin address: " + name)
        previous, legacy = record["previous_name"], record["legacy_name"]
        if any(value is not None and not isinstance(value, str) for value in (previous, legacy)):
            raise ValueError("invalid origin legacy identity: %s" % name)
        rows.append([name, number(record["address"]) & 0xFFFFFF, previous, legacy])
    return canonical_sha256(sorted(rows))


def original_rom_identities(profiles: dict) -> dict:
    return {
        profile: {key: profiles["profiles_by_id"][profile]["reference_rom"][key] for key in ("size", "sha256")}
        for profile in ("jp", "eu")
    }


def load_profile_flags(path: Path) -> dict[str, int]:
    """Read AS's resolved symbol table, including command-line EU definitions."""
    table = load_resolved_symbols(path)
    return {name: table[name.upper()] for name in PROFILE_FLAGS["jp"] if name.upper() in table}


def validate_profile_flags(profile: str, flags: dict[str, int]) -> list[str]:
    if flags != PROFILE_FLAGS[profile]:
        return ["listing resolved flags do not identify profile %s: %s" % (profile, flags)]
    return []


def load_resolved_listing_names(path: Path, wanted: set[str]) -> dict[str, int]:
    """Only AS's final table defines a symbol; inactive source rows do not."""
    canonical = {name.upper(): name for name in wanted}
    if len(canonical) != len(wanted):
        raise ValueError("regional origin names collide in the assembler's case-insensitive table")
    return {
        canonical[name]: value & 0xFFFFFF for name, value in load_resolved_symbols(path).items() if name in canonical
    }


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def load_profile_address_map(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    if not isinstance(value, dict):
        raise ValueError("regional address ledger is not an object")
    return value


def validate_profile_address_map(
    records: list[dict],
    listing_names: dict[str, int],
    ledger: dict,
    profiles: dict,
    *,
    jp_listing_names: dict[str, int] | None = None,
    root: Path | None = None,
) -> list[str]:
    """Compare against frozen explicit EU pairs, never infer from this listing."""
    errors = []
    if (
        ledger.get("schema_version") != 1
        or ledger.get("profile") != "eu"
        or ledger.get("origin_profile") != "jp"
        or ledger.get("origin_identity_fields") != list(IDENTITY_FIELDS)
    ):
        errors.append("regional address ledger schema/profile/origin contract differs")
    if ledger.get("origin_identity_sha256") != origin_identity(records):
        errors.append("regional address ledger origin naming identity changed")
    if ledger.get("original_roms") != original_rom_identities(profiles):
        errors.append("regional address ledger original ROM identities differ from profiles")
    generation = ledger.get("generation")
    if not isinstance(generation, dict):
        errors.append("regional address ledger lacks generation provenance")
    else:
        for key in (
            "profiles_manifest_sha256",
            "name_audit_sha256",
            "generator_sha256",
            "verifier_sha256",
            "extractor_sha256",
        ):
            if not isinstance(generation.get(key), str) or not re.fullmatch(r"[0-9a-f]{64}", generation[key]):
                errors.append("invalid regional generation digest: " + key)
        proof = generation.get("profiles", {})
        for profile in ("jp", "eu"):
            item = proof.get(profile) if isinstance(proof, dict) else None
            if (
                not isinstance(item, dict)
                or item.get("resolved_flags") != PROFILE_FLAGS[profile]
                or item.get("build_rom_sha256") != original_rom_identities(profiles)[profile]["sha256"]
                or item.get("original_rom_sha256") != original_rom_identities(profiles)[profile]["sha256"]
                or type(item.get("printed_byte_rows")) is not int
                or item["printed_byte_rows"] < 1
                or not isinstance(item.get("listing_sha256"), str)
                or not re.fullmatch(r"[0-9a-f]{64}", item["listing_sha256"])
            ):
                errors.append("invalid authenticated generation proof for " + profile)
    rows = ledger.get("records")
    if not isinstance(rows, list):
        return errors + ["regional address ledger records are not a list"]
    if ledger.get("record_count") != len(records) or len(rows) != len(records):
        errors.append("regional address ledger does not account for every origin record")
    if ledger.get("records_sha256") != canonical_sha256(rows):
        errors.append("regional address ledger frozen address inventory changed")
    origins = {record["current_name"]: number(record["address"]) & 0xFFFFFF for record in records}
    seen = set()
    rom_size = profiles["profiles_by_id"]["eu"]["reference_rom"]["size"]
    for row in rows:
        normal_fields = {"current_name", "jp_address", "eu_address", "status"}
        if not isinstance(row, dict) or set(row) not in (normal_fields, normal_fields | {"exclusion"}):
            errors.append("invalid regional address ledger row")
            continue
        name = row["current_name"]
        if not isinstance(name, str) or name not in origins:
            errors.append("regional address ledger has non-audited name: %s" % name)
            continue
        if name in seen:
            errors.append("duplicate regional address ledger name: " + name)
        seen.add(name)
        if row.get("status") == "not_assembled":
            if (
                name != JP_ONLY_NAME
                or row.get("eu_address") is not None
                or "exclusion" not in row
                or row.get("jp_address") != "0x%06X" % origins[name]
            ):
                errors.append("invalid not-assembled regional exception for " + name)
                continue
            if name in listing_names:
                errors.append("JP-only checksum symbol unexpectedly assembled in EU")
            if jp_listing_names is None or jp_listing_names.get(name) != origins[name]:
                errors.append("JP-only checksum origin is missing or moved in resolved JP listing")
            if root is None:
                errors.append("JP-only checksum exception requires its source-owned conditional proof")
            else:
                try:
                    if row["exclusion"] != checksum_exclusion_proof(root):
                        errors.append("JP-only checksum exclusion proof changed")
                except (OSError, ValueError) as error:
                    errors.append(str(error))
            continue
        if row.get("status") != "assembled" or "exclusion" in row or name == JP_ONLY_NAME:
            errors.append("invalid assembled regional availability for " + name)
            continue
        if (
            not isinstance(row["jp_address"], str)
            or not isinstance(row["eu_address"], str)
            or not re.fullmatch(r"0x[0-9A-F]{6}", row["jp_address"])
            or not re.fullmatch(r"0x[0-9A-F]{6}", row["eu_address"])
        ):
            errors.append("invalid regional address pair for " + name)
            continue
        original, expected = number(row["jp_address"]), number(row["eu_address"])
        if original != origins[name]:
            errors.append("regional address ledger JP origin address changed for " + name)
        if original >= 0x800000:
            if expected != original:
                errors.append("regional RAM/hardware identity moved for " + name)
        elif not 0 <= expected < rom_size:
            errors.append("regional ROM address exceeds the original image for " + name)
        actual = listing_names.get(name)
        if actual is None:
            errors.append("name-audit symbol missing from EU listing: " + name)
        elif actual != expected:
            errors.append("regional name-audit %s says 0x%06X; listing has 0x%06X" % (name, expected, actual))
    for name in sorted(set(origins) - seen):
        errors.append("regional address ledger is missing origin name: " + name)
    return errors


def print_errors(errors: list[str]) -> None:
    for error in errors[:ERROR_LIMIT]:
        print("[ERROR] " + error)
    print("[ERROR] %d validation errors (showing first %d)" % (len(errors), min(len(errors), ERROR_LIMIT)))


def number(value: str | int) -> int:
    if isinstance(value, int):
        return value
    return int(value, 16) if value.lower().startswith("0x") else int(value, 0)


def load_symbols(path: Path) -> tuple[dict[int, str], dict[str, int], list[str]]:
    by_address: dict[int, str] = {}
    by_name: dict[str, int] = {}
    errors: list[str] = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = SYMBOL_ROW.match(raw)
        if not match:
            errors.append(f"{path}:{line_number}: invalid symbol row")
            continue
        address = int(match.group(1), 16)
        name = match.group(2)
        if address > 0xFFFFFF:
            errors.append(f"{path}:{line_number}: address exceeds the 68000 bus")
        if address in by_address:
            errors.append(f"{path}:{line_number}: duplicate address 0x{address:06X}")
        if name in by_name:
            errors.append(f"{path}:{line_number}: duplicate name {name}")
        by_address[address] = name
        by_name[name] = address
    return by_address, by_name, errors


def load_all_listing_names(path: Path) -> tuple[dict[str, int], list[str]]:
    """Keep aliases discarded by the canonical symbol export."""
    by_name: dict[str, int] = {}
    errors: list[str] = []
    with path.open(encoding="latin-1") as listing:
        for line_number, line in enumerate(listing, 1):
            row = LISTING_ROW.match(line)
            if not row or len(line) <= SOURCE_COLUMN:
                continue
            source = line[SOURCE_COLUMN:].lstrip()
            label = LABEL.match(source)
            equ = EQU.match(source)
            if label:
                name = label.group(1)
                address = int(row.group(1), 16) & 0xFFFFFF
            elif equ:
                name = equ.group(1)
                address = int(equ.group(2), 16) & 0xFFFFFF
            else:
                continue
            previous = by_name.setdefault(name, address)
            if previous != address:
                errors.append(
                    f"{path}:{line_number}: {name} has listing addresses 0x{previous:06X} and 0x{address:06X}"
                )
    return by_name, errors


def validate_name_audit_addresses(records: list[dict], listing_names: dict[str, int]) -> list[str]:
    """Compare every provenance record to its assembled, 24-bit bus address."""
    errors: list[str] = []
    seen: set[str] = set()
    for record in records:
        name = record["current_name"]
        if name in seen:
            errors.append(f"duplicate name-audit record for {name}")
        seen.add(name)
        if name not in listing_names:
            errors.append(f"name-audit symbol missing from listing: {name}")
            continue
        expected = number(record["address"]) & 0xFFFFFF
        actual = listing_names[name]
        if expected != actual:
            errors.append(f"name-audit {name} says 0x{expected:06X}; listing has 0x{actual:06X}")
    return errors


def required_symbols(layout: dict, runtime: dict) -> dict[str, int]:
    required = {item["symbol"]: number(item["address"]) for item in layout["rom_image"]["landmarks"]}
    for scenario in runtime["scenarios"]:
        for expectation in scenario["expectations"]:
            symbol = expectation["symbol"]
            base = number(expectation["address"]) - number(expectation.get("offset", 0))
            previous = required.setdefault(symbol, base)
            if previous != base:
                raise ValueError(f"conflicting required addresses for {symbol}")
    return required


def validate(
    by_address: dict[int, str],
    by_name: dict[str, int],
    required: dict[str, int],
    minimum: int,
) -> list[str]:
    errors = []
    if len(by_address) < minimum:
        errors.append(f"only {len(by_address)} addressed symbols; expected at least {minimum}")
    for name, address in required.items():
        if name not in by_name:
            errors.append(f"required symbol missing: {name}")
        elif by_name[name] != address:
            errors.append(f"{name} is 0x{by_name[name]:06X}; expected 0x{address:06X}")
        elif by_address.get(address) != name:
            errors.append(f"{name} is not canonical at 0x{address:06X}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--symbols", required=True)
    parser.add_argument("--layout", required=True)
    parser.add_argument("--runtime", required=True)
    parser.add_argument("--listing", required=True)
    parser.add_argument("--name-audit", required=True)
    parser.add_argument("--minimum", type=int, default=15000)
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--profile-address-map")
    parser.add_argument("--profiles", default="config/rom_profiles.json")
    parser.add_argument("--resolved-exports", action="store_true")
    parser.add_argument("--origin-listing", default="build/main.lst")
    parser.add_argument("--root", type=Path, default=Path("."))
    args = parser.parse_args()
    try:
        if args.profile == "eu" and not args.profile_address_map:
            raise ValueError("EU provenance requires a frozen --profile-address-map")
        if args.profile == "jp" and args.profile_address_map:
            raise ValueError("JP provenance uses the original exact-address audit, not a regional ledger")
        by_address, by_name, errors = load_symbols(Path(args.symbols))
        layout = json.loads(Path(args.layout).read_text(encoding="utf-8"))
        runtime = json.loads(Path(args.runtime).read_text(encoding="utf-8"))
        required = required_symbols(layout, runtime)
        errors.extend(validate(by_address, by_name, required, args.minimum))
        listing_names, listing_errors = load_all_listing_names(Path(args.listing))
        errors.extend(listing_errors)
        name_records = json.loads(Path(args.name_audit).read_text(encoding="utf-8"))["records"]
        resolved_names = None
        if args.profile == "eu" or args.resolved_exports:
            errors.extend(validate_profile_flags(args.profile, load_profile_flags(Path(args.listing))))
            resolved_names = load_resolved_listing_names(
                Path(args.listing), set(by_name) | {record["current_name"] for record in name_records}
            )
            for name, address in by_name.items():
                if resolved_names.get(name) != address:
                    errors.append("exported regional symbol differs from its resolved listing: " + name)
        if args.profile == "eu":
            origin_listing = Path(args.origin_listing)
            errors.extend(validate_profile_flags("jp", load_profile_flags(origin_listing)))
            regional_ledger = load_profile_address_map(Path(args.profile_address_map))
            errors.extend(
                validate_profile_address_map(
                    name_records,
                    resolved_names,
                    regional_ledger,
                    load_profiles(Path(args.profiles)),
                    jp_listing_names=load_resolved_listing_names(
                        origin_listing, {record["current_name"] for record in name_records}
                    ),
                    root=args.root.resolve(),
                )
            )
        else:
            errors.extend(
                validate_name_audit_addresses(name_records, resolved_names if args.resolved_exports else listing_names)
            )
    except (OSError, ValueError, KeyError, TypeError) as error:
        print_errors([str(error)])
        return 1
    if errors:
        print_errors(errors)
        return 1
    rom = sum(address < 0x400000 for address in by_address)
    mapped = len(by_address) - rom
    print(
        f"[OK] symbols: {len(by_address)} canonical addresses "
        f"({rom} ROM, {mapped} RAM/hardware), {len(required)} contract symbols"
    )
    if args.profile == "eu":
        excluded = sum(row["status"] == "not_assembled" for row in regional_ledger["records"])
        print(
            f"[OK] name provenance: {len(name_records)} accounted records "
            f"({len(name_records) - excluded} exact addresses, {excluded} source-proved JP-only exclusion) match EU/JP listings"
        )
    else:
        print(f"[OK] name provenance: {len(name_records)} exact-address records match the jp assembler listing")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
