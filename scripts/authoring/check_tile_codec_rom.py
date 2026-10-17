#!/usr/bin/env python3
"""Compile one tile-codec edit per region and compare every resulting ROM byte."""

from __future__ import annotations

import argparse
import hashlib
import json
import shlex
import sys
import tempfile
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.build_content import assembler_args, update_boot_checksum, validate_reference  # noqa: E402
from authoring.compressed_graphics_model import apply_document, export_document  # noqa: E402
from authoring.content_workspace import checked_path, load_manifest, profile_record, stage_tree  # noqa: E402
from authoring.tile_codec import decompress  # noqa: E402
from build_rom import assemble_main_src, first_difference, get_default_tools  # noqa: E402
from verify_symbols import load_all_listing_names  # noqa: E402


PAYLOAD = "SharedTitleAndOptionsType3DataA"


def check_profile(root: Path, profile: str, as_bin: Path, p2bin: Path) -> dict:
    manifest = load_manifest(root / "config/authoring/content_studios.json", root)
    record = profile_record(manifest, profile)
    original = validate_reference(checked_path(root, record["reference_rom"]["filename"]),
                                  record["reference_rom"])
    document = export_document(root, profile)
    payload = next(item for item in document["payloads"] if item["name"] == PAYLOAD)
    if payload["codec"] != "tile-codec":
        raise ValueError("ROM edit probe does not select a tile-codec stream")
    source = checked_path(root, payload["path"])
    source_bytes = source.read_bytes()
    assets = json.loads(checked_path(root, record["asset_manifest"]).read_text(encoding="utf-8"))
    relative = Path(payload["path"]).relative_to("data").as_posix()
    owners = [item for item in assets["assets"] if item["path"] == relative]
    if len(owners) != 1:
        raise ValueError("tile-codec ROM probe has no unique profile asset range")
    owner = owners[0]
    start, end = int(owner["address"], 0), int(owner["end"], 0)
    if (end - start != payload["compressed_capacity"]
            or original[start:end] != source_bytes):
        raise ValueError("profile ROM range differs from the original tile-codec asset")
    payload["blocks"][0]["tiles"] = [
        "".join("%X" % (int(pixel, 16) ^ 1) for pixel in tile)
        for tile in payload["blocks"][0]["tiles"]]
    expected_pixels = bytes(value ^ 0x11 for value in decompress(source_bytes))
    generated = checked_path(root, "build/content")
    generated.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="tile-codec-rom-", dir=generated) as directory:
        temporary = Path(directory)
        tree = temporary / profile / "tree"
        stage_tree(root, tree)
        changed = apply_document(document, tree, profile)
        if changed != [payload["path"]]:
            raise ValueError("tile-codec probe changed unexpected staged owners: %r" % changed)
        encoded = (tree / payload["path"]).read_bytes()
        if len(encoded) != end - start or decompress(encoded) != expected_pixels:
            raise ValueError("staged tile-codec edit differs from its expected pixels or slot")
        listing = temporary / "main.lst"
        base_args = shlex.join(["-q", "-maxerrors", "2", "-L", "-olist", str(listing)])
        output = temporary / "edited.bin"
        status = assemble_main_src(
            str(tree), str(tree / "src/main.s"), str(temporary / "main.p"), str(output),
            str(as_bin), str(p2bin), assembler_args(base_args, manifest, profile),
            record["reference_rom"]["padding_byte"].removeprefix("0x"))
        if status:
            raise ValueError("tile-codec ROM probe assembly failed with code %d" % status)
        symbols, errors = load_all_listing_names(listing)
        if errors or symbols.get(PAYLOAD) != start or symbols.get(PAYLOAD + "_End") != end:
            raise ValueError("edited listing does not retain the source-owned asset boundaries")
        expected = bytearray(original)
        expected[start:end] = encoded
        checksum = update_boot_checksum(expected, profile)
        actual = output.read_bytes()
        # Content publication updates this checksum after assembly. Reproduce
        # that exact step and then compare the full image, not just its tiles.
        published = bytearray(actual)
        update_boot_checksum(published, profile)
        if published != expected:
            raise ValueError("edited ROM differs outside its declared changes at $%06X"
                             % first_difference(published, expected))
        if source.read_bytes() != source_bytes:
            raise ValueError("the canonical tile-codec source asset changed during the probe")
        facts = {"profile": profile, "payload": PAYLOAD, "start": start, "end": end,
                 "rom_size": len(published), "checksum": checksum,
                 "changed_asset_bytes": sum(a != b for a, b in zip(source_bytes, encoded)),
                 "edited_rom_sha256": hashlib.sha256(published).hexdigest(),
                 "reference_sha256": hashlib.sha256(original).hexdigest()}
    return facts


def main() -> int:
    default_as, default_converter = get_default_tools()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu", "all"), default="all")
    parser.add_argument("--as-bin", default=default_as)
    parser.add_argument("--p2bin", default=default_converter)
    args = parser.parse_args()
    try:
        root = Path(args.root).resolve()
        profiles = ("jp", "eu") if args.profile == "all" else (args.profile,)
        for profile in profiles:
            facts = check_profile(root, profile, Path(args.as_bin).resolve(), Path(args.p2bin).resolve())
            print("[OK] tile-codec edited ROM: " + json.dumps(facts, sort_keys=True))
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
