#!/usr/bin/env python3
"""Check the declared ROM layout against source, listing, and built image."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path


INCLUDE_ROW = re.compile(r'^\s*\d+/\s*([0-9A-F]+) :\s+include "([^"]+)"')
LISTING_ROW = re.compile(r"^\(\d+\)\s+\d+/\s*([0-9A-F]+)\s*:")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
BINCLUDE_ROW = re.compile(r'^\(\d+\)\s+\d+/\s*([0-9A-F]+)\s*:.*binclude\s+"([^"]+)"')


def number(value: str | int) -> int:
    if isinstance(value, int):
        return value
    return int(value, 16) if value.lower().startswith("0x") else int(value, 0)


def listing_includes(lines: list[str]) -> list[tuple[int, str]]:
    rows = []
    for line in lines:
        match = INCLUDE_ROW.match(line)
        if match:
            rows.append((int(match.group(1), 16), match.group(2).replace("\\", "/")))
    return rows


def listing_symbols(lines: list[str]) -> dict[str, int]:
    symbols: dict[str, int] = {}
    for line in lines:
        row = LISTING_ROW.match(line)
        if not row or len(line) < 40:
            continue
        label = LABEL.match(line[40:])
        if label:
            symbols[label.group(1)] = int(row.group(1), 16)
    return symbols


def listing_payloads(lines: list[str], expected_paths: set[str] | None = None) -> dict[str, int]:
    """Where selected binincluded payloads landed, by data/ path.

    AS prints inactive conditional branches in its listing too.  When a
    profile manifest is available, restrict the result to that manifest so a
    regional alternative is not mistaken for a second emitted payload.
    """
    payloads: dict[str, int] = {}
    for line in lines:
        match = BINCLUDE_ROW.match(line)
        if match:
            path = match.group(2).replace("\\", "/")
            if expected_paths is None or path in expected_paths:
                payloads[path] = int(match.group(1), 16)
    return payloads


def check_dma_alignment(layout: dict, lines: list[str], manifest_path: Path, errors: list[str]) -> int:
    """No payload the VDP transfers may straddle a DMA source block boundary.

    The VDP latches the upper bits of a DMA source address, so a transfer that
    crosses a block boundary wraps back to the start of that block instead of
    continuing. The cartridge is laid out so that this never happens, and the
    $FF gaps between regions are part of how it is avoided: they are alignment,
    not filler. Nothing in the emulator catches a violation, because the
    vendored Gens increments the ROM source address without masking it, so this
    invariant has to be checked against the listing instead.
    """
    rules = layout.get("dma_alignment")
    if not rules:
        errors.append("ROM layout declares no DMA alignment rule")
        return 0
    block = number(rules["block_size"])
    regions = set(rules["transferred_regions"])
    ceiling = int(rules["maximum_crossings"])

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assets = {("data/" + item["path"]).replace("\\", "/"): item for item in manifest["assets"]}
    from build_z80 import ENTRY, OUTPUT, REFERENCE

    generated, reference = OUTPUT.as_posix(), REFERENCE.as_posix()
    payloads = listing_payloads(lines, set(assets) | {generated})
    if generated in payloads:
        # The Z80 image is now assembled, but it still occupies exactly the
        # authenticated reference asset's range. Do not waive the asset census
        # or accept a generated file merely because its name matches.
        try:
            if reference not in assets or reference in payloads:
                raise ValueError("missing or duplicate Z80 reference payload")
            root = manifest_path.resolve().parent.parent
            if not (root / ENTRY).is_file():
                raise ValueError("missing Z80 source owner")
            body = (root / OUTPUT).read_bytes()
            asset = assets[reference]
            if len(body) != asset["size"] or hashlib.sha1(body).hexdigest() != asset["sha1"]:
                raise ValueError("assembled Z80 payload differs from its asset identity")
            payloads[reference] = payloads.pop(generated)
        except (OSError, KeyError, ValueError) as error:
            errors.append("assembled Z80 layout binding: " + str(error))
    if len(payloads) != len(assets):
        missing = sorted(set(assets) - set(payloads))
        errors.append(f"listing places {len(payloads)} payloads; the asset manifest declares {len(assets)}")
        for path in missing[:10]:
            errors.append(f"manifest payload is absent from the listing: {path}")
        if len(missing) > 10:
            errors.append(f"... and {len(missing) - 10} more missing manifest payloads")

    checked = 0
    crossings = []
    for path, start in sorted(payloads.items()):
        asset = assets.get(path)
        if asset is None or asset["region"] not in regions:
            continue
        checked += 1
        end = start + int(asset["size"])
        if start // block != (end - 1) // block:
            crossings.append(f"{asset['name']} spans 0x{start:06X}-0x{end:06X}, crossing a 0x{block:X} DMA boundary")
    if len(crossings) > ceiling:
        for crossing in crossings[:10]:
            errors.append(crossing)
        if len(crossings) > 10:
            errors.append(f"... and {len(crossings) - 10} more DMA boundary crossings")
    return checked


def check_modules(layout: dict, lines: list[str], errors: list[str]) -> int:
    includes = listing_includes(lines)
    actual_modules = [row for row in includes if row[1].endswith(".s")]
    actual_shared = [path for _, path in includes if path.endswith(".inc")]
    declared = layout["modules"]

    if len(actual_modules) != len(declared):
        errors.append(f"listing has {len(actual_modules)} modules; layout declares {len(declared)}")
        return 0

    image_size = number(layout["rom_image"]["size"])
    line_limit = layout["target"]["max_module_lines"]
    for index, (entry, (start, path)) in enumerate(zip(declared, actual_modules)):
        end = actual_modules[index + 1][0] - 1 if index + 1 < len(actual_modules) else image_size - 1
        if entry["file"] != path:
            errors.append(f"module {index}: listing has {path}; layout declares {entry['file']}")
            continue
        if number(entry["start"]) != start or number(entry["end"]) != end:
            errors.append(
                f"{path}: listing range 0x{start:06X}-0x{end:06X}; layout range {entry['start']}-{entry['end']}"
            )
        source = Path(path)
        if not source.is_file():
            errors.append(f"module is missing: {path}")
        else:
            line_count = len(source.read_text(encoding="utf-8").splitlines())
            if line_count > line_limit:
                errors.append(f"{path}: {line_count} lines exceeds limit {line_limit}")

    expected_shared = [entry["file"] for entry in layout["shared_definitions"]]
    if actual_shared != expected_shared:
        errors.append(f"shared includes are {actual_shared}; layout declares {expected_shared}")
    return len(declared)


def check_landmarks(layout: dict, lines: list[str], errors: list[str]) -> int:
    symbols = listing_symbols(lines)
    landmarks = layout["rom_image"].get("landmarks", [])
    for landmark in landmarks:
        name = landmark["symbol"]
        if name not in symbols:
            errors.append(f"landmark {name} is absent from the listing")
        elif symbols[name] != number(landmark["address"]):
            errors.append(f"landmark {name} is at 0x{symbols[name]:06X}; layout declares {landmark['address']}")
    return len(landmarks)


def check_image(layout: dict, rom_path: Path, errors: list[str]) -> int:
    if not rom_path.is_file():
        errors.append(f"built ROM is missing: {rom_path}")
        return 0
    data = rom_path.read_bytes()
    image = layout["rom_image"]
    if len(data) != number(image["size"]):
        errors.append(f"{rom_path}: size {len(data)}; layout declares {image['size']}")
        return 0

    padding = number(image["padding_byte"])
    checked = 0
    for gap in image.get("gaps", []):
        start, end = number(gap["start"]), number(gap["end"])
        expected_size = end - start + 1
        if expected_size != number(gap["size"]):
            errors.append(f"gap {gap['start']}-{gap['end']} has inconsistent size")
            continue
        wrong = next((offset for offset in range(start, end + 1) if data[offset] != padding), None)
        if wrong is not None:
            errors.append(
                f"gap {gap['start']}-{gap['end']} is not all {image['padding_byte']}; first mismatch at 0x{wrong:06X}"
            )
        checked += expected_size
    return checked


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", default="config/rom_layout.json")
    parser.add_argument("--listing", default="build/main.lst")
    parser.add_argument("--rom", default="asbuilt.bin")
    parser.add_argument("--manifest", default="assets/manifest.json")
    args = parser.parse_args()

    layout_path = Path(args.layout)
    layout = json.loads(layout_path.read_text(encoding="utf-8"))
    if layout.get("schema_version") != 1:
        print("[ERROR] unsupported ROM layout schema", file=sys.stderr)
        return 1
    listing_path = Path(args.listing)
    if not listing_path.is_file():
        print(f"[ERROR] listing is missing: {listing_path}", file=sys.stderr)
        return 1
    lines = listing_path.read_text(encoding="latin-1").splitlines()

    errors: list[str] = []
    modules = check_modules(layout, lines, errors)
    landmarks = check_landmarks(layout, lines, errors)
    padding = check_image(layout, Path(args.rom), errors)
    transferred = check_dma_alignment(layout, lines, Path(args.manifest), errors)
    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        return 1
    print(
        f"[OK] ROM layout: {modules} modules, {landmarks} landmarks, "
        f"{padding} padding bytes, {transferred} DMA payloads inside their blocks"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
