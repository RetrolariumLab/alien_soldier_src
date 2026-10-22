#!/usr/bin/env python3
"""Read the cartridge's sprite mappings, and draw the ones that can be drawn.

  validate  every mapping must re-encode, and every dynamic one must line up
            with the art its pieces point at
  list      the blocks, and how many mappings and pieces each holds
  inspect   one mapping's pieces, field by field
  draw      one dynamic mapping as a PNG

Only the dynamic mappings can be drawn on their own. A static mapping's tile
field is added to whatever base tile the object happens to be carrying, so its
pixels live wherever that object last uploaded them; a dynamic mapping carries
a pointer to its own art in every piece, which is exactly what makes it
drawable without running the game.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# The Makefile runs this without setting PYTHONPATH, because a recipe that sets
# an environment variable inline is shell syntax and make falls back to cmd.exe
# on Windows. Finding scripts/ from the file itself works under any shell.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from authoring.palette_model import named_sets
from authoring.sprite_mapping_model import (
    art_payloads,
    compose_image,
    mapping_tiles,
    read_blocks,
    round_trip_errors,
    survey,
)
from authoring.tile_graphics import CRAM_LEVELS, CRAM_LEVELS_LINEAR, write_png


def all_mappings(root):
    blocks, _ = read_blocks(root)
    return [(block, mapping) for block in blocks for mapping in block.mappings]


def validate(root):
    errors = list(round_trip_errors(root))
    payloads = art_payloads(root)
    drawn = 0
    for _, mapping in all_mappings(root):
        if not mapping.dynamic:
            continue
        try:
            drawn += len(mapping_tiles(root, mapping, payloads))
        except ValueError as error:
            errors.append(str(error))
    if errors:
        for error in errors:
            print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    found = survey(root)
    print(
        "[OK] sprite mappings: %d mappings in %d blocks, %d pieces, "
        "%d dynamic ones resolving %d tiles of art"
        % (found["mappings"], found["blocks"], found["pieces"], found["dynamic_mappings"], drawn)
    )
    return 0


def show_list(root):
    blocks, skipped = read_blocks(root)
    print("%-52s %-8s %8s %7s" % ("block", "storage", "mappings", "pieces"))
    for block in blocks:
        if len(block.mappings) < 2 and block.storage != "payload":
            continue
        print(
            "%-52s %-8s %8d %7d"
            % (block.name, block.storage, len(block.mappings), sum(len(item.pieces) for item in block.mappings))
        )
    print("\n(only the blocks holding more than one mapping, and the payloads)")
    for name, reason in sorted(skipped.items()):
        print("skipped %s: %s" % (name, reason))
    return 0


def find(root, name):
    matches = [
        (block, mapping)
        for block, mapping in all_mappings(root)
        if mapping.label == name or block.name == name or block.name.lower().startswith(name.lower())
    ]
    if not matches:
        print("[ERROR] no sprite mapping named %s" % name, file=sys.stderr)
        return None
    return matches[0]


def inspect(root, name):
    match = find(root, name)
    if match is None:
        return 1
    block, mapping = match
    print("%s  (%s, in %s)" % (mapping.label, block.storage, block.source))
    left, top, width, height = mapping.bounds()
    print("covers %dx%d pixels from (%d, %d)" % (width, height, left, top))
    print("%5s %6s %6s %5s %5s %6s %6s %s" % ("#", "attrs", "tile", "size", "flip", "y", "x", "art"))
    for index, piece in enumerate(mapping.pieces):
        flip = "".join(("h" if piece.hflip_relative else "-", "v" if piece.vflip_relative else "-"))
        print(
            "%5d  $%04X  $%03X  %dx%d    %s  %6d %6d %s"
            % (
                index,
                piece.attributes,
                piece.tile,
                piece.tiles_wide,
                piece.tiles_high,
                flip,
                piece.y,
                piece.x,
                piece.art,
            )
        )
    return 0


def draw(root, name, output, line, palette_name, scale, levels):
    match = find(root, name)
    if match is None:
        return 1
    _, mapping = match
    if not mapping.dynamic:
        print(
            "[ERROR] %s is a static mapping: its tiles are whatever its "
            "object had in VRAM, so it cannot be drawn on its own" % mapping.label,
            file=sys.stderr,
        )
        return 1
    sets = named_sets(root, levels)
    chosen = next((item for item in sets if item["name"].lower().startswith(palette_name.lower())), None)
    if chosen is None:
        print("[ERROR] no palette list named %s" % palette_name, file=sys.stderr)
        return 1
    tiles = mapping_tiles(root, mapping)
    image = compose_image(mapping, tiles, chosen["rgb"], line, (24, 24, 32))
    if scale > 1:
        image = [[pixel for pixel in row for _ in range(scale)] for row in image for _ in range(scale)]
    write_png(root / output, image)
    print(
        "[OK] wrote %s: %s, %d pieces through %s line %d"
        % (output, mapping.label, len(mapping.pieces), chosen["name"], line)
    )
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("validate", "list", "inspect", "draw"))
    parser.add_argument("--mapping", default="")
    parser.add_argument("--output", default="build/art/mapping.png")
    parser.add_argument("--palette", default="StageStart")
    parser.add_argument("--line", type=int, default=3)
    parser.add_argument("--scale", type=int, default=3)
    parser.add_argument("--linear-levels", action="store_true")
    args = parser.parse_args()
    root = Path.cwd()
    levels = CRAM_LEVELS_LINEAR if args.linear_levels else CRAM_LEVELS

    if args.action == "validate":
        return validate(root)
    if args.action == "list":
        return show_list(root)
    if not args.mapping:
        print("[ERROR] %s needs --mapping NAME" % args.action, file=sys.stderr)
        return 1
    if args.action == "inspect":
        return inspect(root, args.mapping)
    return draw(root, args.mapping, args.output, args.line, args.palette, max(1, args.scale), levels)


if __name__ == "__main__":
    raise SystemExit(main())
