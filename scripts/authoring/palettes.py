#!/usr/bin/env python3
"""Read the cartridge's palettes, and look at them.

  validate  every command must re-encode, and every offset must land on one
  list     name the offset lists and the commands each one plays
  show     print one list's sixty-four colours
  strip    write one list out as a PNG of its four palette lines

A palette is stored as commands rather than as colours, so "the stage's
palette" is a thing that has to be played, not read. `validate` is the gate:
a model that cannot put the commands back byte for byte has not understood
them, and a preview drawn from a half-understood format misleads.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# The Makefile runs this without setting PYTHONPATH, because a recipe that sets
# an environment variable inline is shell syntax and make falls back to cmd.exe
# on Windows. Finding scripts/ from the file itself works under any shell.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from authoring.palette_model import PALETTE_COLOURS, named_sets, round_trip_errors, survey
from authoring.tile_graphics import CRAM_LEVELS, CRAM_LEVELS_LINEAR, write_png


def validate(root):
    errors = round_trip_errors(root)
    if errors:
        for error in errors:
            print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    found = survey(root)
    print(
        "[OK] palettes: %d commands in %d blocks, %d full palettes, "
        "%d offset lists all landing on command boundaries"
        % (found["commands"], found["command_blocks"], found["full_palettes"], found["offset_lists"])
    )
    return 0


def show_list(root, levels):
    for item in named_sets(root, levels):
        print("%-46s %s" % (item["name"], ", ".join(item["commands"])))
    return 0


def find(root, name, levels):
    sets = named_sets(root, levels)
    match = next((item for item in sets if item["name"] == name or item["name"].lower().startswith(name.lower())), None)
    if match is None:
        print("[ERROR] no palette list named %s" % name, file=sys.stderr)
        print("known: %s" % ", ".join(item["name"] for item in sets), file=sys.stderr)
    return match


def show(root, name, levels):
    match = find(root, name, levels)
    if match is None:
        return 1
    print("%s <- %s" % (match["name"], ", ".join(match["commands"])))
    for line in range(PALETTE_COLOURS // 16):
        words = match["words"][line * 16 : (line + 1) * 16]
        print("  line %d  %s" % (line, " ".join("%03X" % word for word in words)))
    return 0


def strip(root, name, output, scale, levels):
    match = find(root, name, levels)
    if match is None:
        return 1
    image = []
    for line in range(PALETTE_COLOURS // 16):
        row = [colour for colour in match["rgb"][line * 16 : (line + 1) * 16] for _ in range(scale)]
        image.extend([list(row) for _ in range(scale)])
    write_png(root / output, image)
    print("[OK] wrote %s: %s" % (output, match["name"]))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("validate", "list", "show", "strip"))
    parser.add_argument("--set", dest="name", default="")
    parser.add_argument("--output", default="build/art/palette.png")
    parser.add_argument("--scale", type=int, default=16)
    parser.add_argument("--linear-levels", action="store_true", help="use the evenly spaced colour ramp instead")
    args = parser.parse_args()
    root = Path.cwd()
    levels = CRAM_LEVELS_LINEAR if args.linear_levels else CRAM_LEVELS

    if args.action == "validate":
        return validate(root)
    if args.action == "list":
        return show_list(root, levels)
    if not args.name:
        print("[ERROR] %s needs --set NAME" % args.action, file=sys.stderr)
        return 1
    if args.action == "show":
        return show(root, args.name, levels)
    return strip(root, args.name, args.output, max(1, args.scale), levels)


if __name__ == "__main__":
    raise SystemExit(main())
