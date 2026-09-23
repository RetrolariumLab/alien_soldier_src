#!/usr/bin/env python3
"""Read the cartridge's tile art, and look at it.

  validate  every art payload must parse, and match what config declares
  sheet     write one payload out as a PNG grid of its tiles

The validate half is the gate: a decoder that cannot account for all 289
payloads does not understand the format, and a preview drawn from a format
that is half understood is worse than no preview at all.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# The Makefile runs this without setting PYTHONPATH, because a recipe that sets
# an environment variable inline is shell syntax and make falls back to cmd.exe
# on Windows. Finding scripts/ from the file itself works under any shell.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from authoring.tile_graphics import (
    ART_DIRECTORY, CRAM_LEVELS, CRAM_LEVELS_LINEAR, decode_tile, declared_art,
    encode_tile, greyscale_palette, palette_rgb, read_palette_words, read_sheet,
    sheet_image, survey, write_png)


def validate(root):
    errors = []
    found = survey(root)
    declared = declared_art(root)
    for field in ("payloads", "tiles"):
        if found[field] != declared[field]:
            errors.append("%s: counted %d, config declares %d"
                          % (field, found[field], declared[field]))
    if found["kinds"] != declared["shapes"]:
        errors.append("payload shapes: counted %s, config declares %s"
                      % (found["kinds"], declared["shapes"]))
    for path in sorted((root / ART_DIRECTORY).glob("*.bin")):
        sheet = read_sheet(path)
        for block in sheet.blocks:
            body = sheet.data[block.offset:block.offset + block.byte_count]
            rebuilt = b"".join(encode_tile(decode_tile(body, at))
                               for at in range(0, len(body), 32))
            if rebuilt != body:
                errors.append("%s: a tile did not survive being decoded" % path.name)
                break
    if errors:
        for error in errors:
            print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    print("[OK] tile art: %d payloads, %d tiles, %s, all decode and re-encode"
          % (found["payloads"], found["tiles"],
             ", ".join("%d %s" % (count, kind)
                       for kind, count in sorted(found["kinds"].items()))))
    return 0


def load_palette(root, argument, levels):
    """A palette line given as a file of CRAM words, or nothing for greyscale."""
    if not argument:
        return greyscale_palette()
    data = (root / argument).read_bytes()
    count = min(64, len(data) // 2)
    words = read_palette_words(data, 0, count)
    colours = palette_rgb(words, levels)
    return colours + greyscale_palette()[len(colours):]


def sheet(root, name, output, columns, line, palette_path, levels):
    path = root / ART_DIRECTORY / name
    if not path.is_file():
        print("[ERROR] no art payload named %s" % name, file=sys.stderr)
        return 1
    art = read_sheet(path)
    palette = load_palette(root, palette_path, levels)
    write_png(root / output, sheet_image(art, palette, columns, line))
    print("[OK] wrote %s: %d tiles in %d block(s), %s"
          % (output, art.tile_count, len(art.blocks),
             "length-prefixed" if art.chained else "bare"))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("validate", "sheet"))
    parser.add_argument("--name", default="sega.bin")
    parser.add_argument("--output", default="build/art/sheet.png")
    parser.add_argument("--columns", type=int, default=16)
    parser.add_argument("--line", type=int, default=0)
    parser.add_argument("--palette", default="")
    parser.add_argument("--linear-levels", action="store_true",
                        help="use the evenly spaced colour ramp instead")
    args = parser.parse_args()
    root = Path.cwd()
    levels = CRAM_LEVELS_LINEAR if args.linear_levels else CRAM_LEVELS

    if args.action == "validate":
        return validate(root)
    return sheet(root, args.name, args.output, args.columns, args.line,
                 args.palette, levels)


if __name__ == "__main__":
    raise SystemExit(main())
