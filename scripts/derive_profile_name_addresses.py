#!/usr/bin/env python3
"""One-time, non-overwriting explicit EU provenance-address ledger derivation."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import tempfile
import zlib

from rom_profiles import load_profiles
import verify_symbols as symbols
import extract_symbols


_LISTING_ROW = symbols.LISTING_ROW
_LISTING_COLUMN = symbols.SOURCE_COLUMN


def _listing_parser_policy():
    """Only the unchanged pure row grammar may supply scoped input facts."""
    if (
        type(symbols.LISTING_ROW) is not re.Pattern
        or symbols.LISTING_ROW is not _LISTING_ROW
        or type(symbols.SOURCE_COLUMN) is not int
        or symbols.SOURCE_COLUMN != _LISTING_COLUMN
        or getattr(_parse_listing_rows, "__code__", None) is not _LISTING_PARSER_CODE
    ):
        return None
    return (_LISTING_ROW.pattern, _LISTING_ROW.flags, _LISTING_COLUMN, _LISTING_PARSER_CODE)


def _parse_listing_rows(raw):
    """Decode input rows, not whether they match any particular ROM image."""
    # Match Path.open's Latin-1 universal-newline iteration exactly. str.splitlines
    # would additionally split VT, FF and NEL, changing legacy line positions.
    with io.TextIOWrapper(io.BytesIO(raw), encoding="latin-1", newline=None) as stream:
        for line_number, line in enumerate(stream, 1):
            row = symbols.LISTING_ROW.match(line)
            if row is None or len(line) <= symbols.SOURCE_COLUMN:
                continue
            field = line[line.index(":") + 1 : symbols.SOURCE_COLUMN].strip()
            if not re.fullmatch(r"(?:[0-9A-Fa-f]{2,8}\s*)+", field):
                continue
            yield line_number, int(row[1], 16), bytes.fromhex(field)


_LISTING_PARSER_CODE = _parse_listing_rows.__code__


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def owned_path(root: Path, relative: str | Path) -> Path:
    relative = Path(relative)
    if relative.is_absolute() or not relative.parts or ".." in relative.parts:
        raise ValueError("ledger derivation requires a root-relative path: %s" % relative)
    path = root.resolve()
    for part in relative.parts:
        path /= part
        if path.is_symlink() or getattr(path, "is_junction", lambda: False)():
            raise ValueError("ledger derivation path crosses a link: %s" % path)
    return path


def authenticated_image(path: Path, reference: dict) -> bytes:
    image = path.read_bytes()
    actual = {
        "size": len(image),
        "sha256": hashlib.sha256(image).hexdigest(),
        "sha1": hashlib.sha1(image).hexdigest(),
        "md5": hashlib.md5(image).hexdigest(),
        "crc32": "%08X" % (zlib.crc32(image) & 0xFFFFFFFF),
    }
    if any(actual[key] != reference[key] for key in actual):
        raise ValueError("ROM is not the authenticated original profile image: %s" % path)
    return image


def bind_listing_bytes(path: Path, image: bytes) -> int:
    """Bind each fully printed AS byte field to the authenticated ROM.

    EQU/conditional and abbreviated binclude fields are not machine bytes.
    Such rows are excluded explicitly, not expanded by a guessed parser.
    """
    from authoring.stage_tilemap_model import _listing_operation, _LISTING_MAX_FILE

    operation, policy = _listing_operation(path), _listing_parser_policy()
    if operation is not None and policy is not None and type(image) is bytes:
        # A generated listing may legitimately be replaced in this operation.
        # Every call reads its CURRENT bytes; neither mtime nor a cached result
        # can identify the next call's input. Oversized inputs keep streaming.
        with path.open("rb") as stream:
            raw = stream.read(_LISTING_MAX_FILE + 1)
        rows = operation.listing_rows(path, raw, policy)
        if rows is not None:
            checked = 0
            for line_number, address, encoded in rows:
                if address + len(encoded) > len(image) or image[address : address + len(encoded)] != encoded:
                    raise ValueError(
                        "listing bytes differ from original ROM: %s:%d at $%06X" % (path, line_number, address)
                    )
                checked += 1
            if not checked:
                raise ValueError("listing has no authenticated printed ROM byte fields: %s" % path)
            return checked
    checked = 0
    with path.open(encoding="latin-1") as stream:
        for line_number, line in enumerate(stream, 1):
            row = symbols.LISTING_ROW.match(line)
            if row is None or len(line) <= symbols.SOURCE_COLUMN:
                continue
            field = line[line.index(":") + 1 : symbols.SOURCE_COLUMN].strip()
            if not re.fullmatch(r"(?:[0-9A-Fa-f]{2,8}\s*)+", field):
                continue
            encoded = bytes.fromhex(field)
            address = int(row[1], 16)
            if address + len(encoded) > len(image) or image[address : address + len(encoded)] != encoded:
                raise ValueError(
                    "listing bytes differ from original ROM: %s:%d at $%06X" % (path, line_number, address)
                )
            checked += 1
    if not checked:
        raise ValueError("listing has no authenticated printed ROM byte fields: %s" % path)
    return checked


def derive(
    root: Path,
    profiles_path: str | Path = "config/rom_profiles.json",
    audit_path: str | Path = "config/name_audit.json",
) -> dict:
    """Use manifest-owned JP/EU listings/images, not alternate worktree inputs."""
    root = root.resolve()
    manifest_file, audit_file = owned_path(root, profiles_path), owned_path(root, audit_path)
    declaration_hashes = {"profiles": digest(manifest_file), "audit": digest(audit_file)}
    profiles = load_profiles(manifest_file)
    records = json.loads(audit_file.read_text(encoding="utf-8"))["records"]
    origin = symbols.origin_identity(records)
    files = {
        "profiles": manifest_file,
        "audit": audit_file,
        "generator": Path(__file__).resolve(),
        "verifier": Path(symbols.__file__).resolve(),
        "extractor": Path(extract_symbols.__file__).resolve(),
    }
    if any(record["current_name"] == symbols.JP_ONLY_NAME for record in records):
        files["exclusion_source"] = owned_path(root, symbols.EXCLUSION_SOURCE)
    for profile in ("jp", "eu"):
        entry = profiles["profiles_by_id"][profile]
        if entry["status"] != "supported":
            raise ValueError("ledger derivation requires supported profile: " + profile)
        files[profile + "_listing"] = owned_path(root, entry["listing"])
        files[profile + "_rom"] = owned_path(root, entry["output"])
        files[profile + "_original"] = owned_path(root, entry["reference_rom"]["filename"])
    before = {key: digest(path) for key, path in files.items()}
    if any(before[key] != value for key, value in declaration_hashes.items()):
        raise ValueError("ledger declarations changed while being read")
    names, proof = {}, {}
    for profile in ("jp", "eu"):
        entry = profiles["profiles_by_id"][profile]
        image = authenticated_image(files[profile + "_rom"], entry["reference_rom"])
        original = authenticated_image(files[profile + "_original"], entry["reference_rom"])
        if image != original:
            raise ValueError("preservation build is not byte-identical to its original dump")
        listing = files[profile + "_listing"]
        flags = symbols.load_profile_flags(listing)
        errors = symbols.validate_profile_flags(profile, flags)
        names[profile], parse_errors = symbols.load_all_listing_names(listing)
        errors.extend(parse_errors)
        if profile == "jp":
            errors.extend(symbols.validate_name_audit_addresses(records, names[profile]))
        resolved = symbols.load_resolved_listing_names(listing, {record["current_name"] for record in records})
        for name, address in resolved.items():
            if names[profile].get(name) != address:
                errors.append("source row and resolved symbol table disagree: " + name)
        names[profile] = resolved
        if profile == "jp":
            errors.extend(symbols.validate_name_audit_addresses(records, names[profile]))
        if errors:
            raise ValueError("; ".join(errors[: symbols.ERROR_LIMIT]) + " (%d errors)" % len(errors))
        proof[profile] = {
            "listing": entry["listing"],
            "listing_sha256": before[profile + "_listing"],
            "resolved_flags": flags,
            "printed_byte_rows": bind_listing_bytes(listing, image),
            "build_rom": entry["output"],
            "build_rom_sha256": before[profile + "_rom"],
            "original_rom": entry["reference_rom"]["filename"],
            "original_rom_sha256": before[profile + "_original"],
        }
    pairs = []
    for record in sorted(records, key=lambda item: item["current_name"]):
        name = record["current_name"]
        if name == symbols.JP_ONLY_NAME:
            if name in names["eu"]:
                raise ValueError("JP-only checksum unexpectedly assembled in EU")
            pairs.append(
                {
                    "current_name": name,
                    "jp_address": "0x%06X" % names["jp"][name],
                    "eu_address": None,
                    "status": "not_assembled",
                    "exclusion": symbols.checksum_exclusion_proof(root),
                }
            )
            continue
        if name not in names["eu"]:
            raise ValueError("EU listing does not account for origin name: " + name)
        pairs.append(
            {
                "current_name": name,
                "jp_address": "0x%06X" % (symbols.number(record["address"]) & 0xFFFFFF),
                "eu_address": "0x%06X" % names["eu"][name],
                "status": "assembled",
            }
        )
    ledger = {
        "schema_version": 1,
        "profile": "eu",
        "origin_profile": "jp",
        "origin_identity_fields": list(symbols.IDENTITY_FIELDS),
        "origin_identity_sha256": origin,
        "original_roms": symbols.original_rom_identities(profiles),
        "record_count": len(records),
        "records_sha256": symbols.canonical_sha256(pairs),
        "generation": {
            "profiles_manifest_sha256": before["profiles"],
            "name_audit_sha256": before["audit"],
            "generator_sha256": before["generator"],
            "verifier_sha256": before["verifier"],
            "extractor_sha256": before["extractor"],
            "profiles": proof,
        },
        "records": pairs,
    }
    errors = symbols.validate_profile_address_map(
        records, names["eu"], ledger, profiles, jp_listing_names=names["jp"], root=root
    )
    if errors:
        raise ValueError("; ".join(errors[: symbols.ERROR_LIMIT]) + " (%d errors)" % len(errors))
    if before != {key: digest(path) for key, path in files.items()}:
        raise ValueError("ledger derivation inputs changed before publication")
    return ledger


def ledger_text(ledger: dict) -> str:
    """Indented JSON with one record per line, so a name is one line of text."""
    head = {key: value for key, value in ledger.items() if key != "records"}
    text = json.dumps(head, indent=2, ensure_ascii=True)
    rows = ",\n".join("    " + json.dumps(record, ensure_ascii=True) for record in ledger["records"])
    return text[:-2] + ',\n  "records": [\n' + rows + "\n  ]\n}\n"


def publish_new(root: Path, relative: str | Path, ledger: dict) -> Path:
    path = owned_path(root, relative)
    if Path(relative).parts[0] not in {"config", "build"} or path.suffix != ".json":
        raise ValueError("new ledger must be a .json under config/ or build/")
    if path.exists():
        raise ValueError("refusing to overwrite existing regional ledger: %s" % path)
    payload = ledger_text(ledger).encode("ascii")
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent, prefix="." + path.name + ".", suffix=".tmp", delete=False
        ) as stream:
            temporary = Path(stream.name)
            stream.write(payload)
        owned_path(root, relative)
        # A same-directory hard link publishes atomically and fails if the
        # destination exists; os.replace would silently replace prior evidence.
        os.link(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--profiles", default="config/rom_profiles.json")
    parser.add_argument("--name-audit", default="config/name_audit.json")
    parser.add_argument("--output", default="config/name_addresses_eu.json")
    args = parser.parse_args()
    try:
        # Reject an existing output before authentication or any temporary writes.
        if owned_path(args.root, args.output).exists():
            raise ValueError("refusing to overwrite existing regional ledger")
        ledger = derive(args.root, args.profiles, args.name_audit)
        output = publish_new(args.root, args.output, ledger)
        print(
            "[OK] frozen EU provenance: %d explicit pairs, origin %s; %s"
            % (ledger["record_count"], ledger["origin_identity_sha256"], output)
        )
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        symbols.print_errors([str(error)])
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
