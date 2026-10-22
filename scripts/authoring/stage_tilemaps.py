#!/usr/bin/env python3
"""Read the three maps a stage's scrolling background is folded into.

  validate  every asset list must parse and every RAM payload decompress
  list      each stage table index, its asset lists and what they define
  inspect   one index: the coarse row, and the name-table words it produces
  draw      one index as a PNG, with the palette its configuration record names

A stage's background is not stored as a tilemap. It is a coarse map of chunk
indices, chunks of pattern indices, and patterns of name-table words, all three
decompressed into RAM by the stage's asset lists. `validate` proves the model
can rebuild that RAM; `inspect` shows what the streamer would write from it.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# The Makefile runs this without setting PYTHONPATH, because a recipe that sets
# an environment variable inline is shell syntax and make falls back to cmd.exe
# on Windows. Finding scripts/ from the file itself works under any shell.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from authoring.stage_renderer import render_to_png
from authoring.stage_tilemap_model import (
    COARSE_COLUMNS,
    CHUNK_PIXELS,
    decompress,
    labelled_blocks,
    read_asset_lists,
    stage_loaders,
    stage_tilemaps,
    survey,
)


def validate(root):
    errors = []
    data, bodies = labelled_blocks(root)
    lists = read_asset_lists(root, bodies)
    for name, commands in sorted(lists.items()):
        for command in commands:
            if not command.to_ram:
                continue
            if command.source not in data:
                errors.append("%s: %s is not a payload in the tree" % (name, command.source))
                continue
            try:
                decompress(data[command.source])
            except ValueError as error:
                errors.append("%s: %s does not decompress (%s)" % (name, command.source, error))
    maps = stage_tilemaps(root)
    if not maps:
        errors.append("no stage table entries found")
    if errors:
        for error in errors:
            print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    found = survey(root)
    print(
        "[OK] stage tilemaps: %d asset lists, %d commands, %d decompress to RAM, "
        "%d payloads all decoding, %d stage table entries through %d descriptors"
        % (
            found["asset_lists"],
            found["asset_commands"],
            found["decompress_to_ram"],
            found["ram_payloads_decoded"],
            found["stage_table_entries"],
            found["descriptors"],
        )
    )
    return 0


def show_list(root):
    data, _ = labelled_blocks(root)
    loaders = stage_loaders(root, data)
    print("%-5s %-34s %7s %9s  %s" % ("index", "loader", "chunks", "patterns", "lists"))
    for index, tilemap in enumerate(stage_tilemaps(root)):
        print(
            "%-5d %-34s %7d %9d  %s"
            % (
                index,
                loaders[index] if index < len(loaders) else "",
                tilemap.chunks_defined,
                tilemap.patterns_defined,
                ", ".join(tilemap.lists),
            )
        )
    return 0


def inspect(root, index, rows, columns):
    maps = stage_tilemaps(root)
    if not 0 <= index < len(maps):
        print("[ERROR] stage table index %d is not one of 0..%d" % (index, len(maps) - 1), file=sys.stderr)
        return 1
    tilemap = maps[index]
    print("%s  %s" % (tilemap.name, ", ".join(tilemap.lists)))
    print(
        "descriptor %s: coarse $%X, chunks $%X, patterns $%X, plane base $%X"
        % (
            tilemap.descriptor.name,
            tilemap.descriptor.coarse,
            tilemap.descriptor.chunks,
            tilemap.descriptor.patterns,
            tilemap.descriptor.plane_base,
        )
    )
    print("%d chunks and %d patterns defined" % (tilemap.chunks_defined, tilemap.patterns_defined))
    print(
        "coarse row 0: %s"
        % " ".join("%02X" % tilemap.coarse_index(column * CHUNK_PIXELS, 0) for column in range(COARSE_COLUMNS))
    )
    for row in range(rows):
        y = row * 8
        print("y=%4d  %s" % (y, " ".join("%04X" % tilemap.name_word(column * 8, y) for column in range(columns))))
    return 0


def draw(root, index, output, x, y, width, height, palette, scale, show_priority, objects=False):
    try:
        built = render_to_png(root, index, output, x, y, width, height, palette, scale, show_priority, objects)
    except ValueError as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    print(
        "[OK] wrote %s: stage table index %d at (%d, %d), %dx%d, palette %s"
        % (output, index, x, y, width, height, built.palette_name)
    )
    print("      plane A: %s" % built.planes[0])
    print("      plane B: %s" % built.planes[1])
    for name, payload in built.missing_codecs:
        print("      %s: %s needs the bit-token codec and was left out" % (name, payload))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("validate", "list", "inspect", "draw"))
    parser.add_argument("--stage", type=int, default=0)
    parser.add_argument("--rows", type=int, default=8)
    parser.add_argument("--columns", type=int, default=16)
    parser.add_argument("--output", default="build/art/stage.png")
    parser.add_argument("--x", type=int, default=0)
    parser.add_argument("--y", type=int, default=0)
    parser.add_argument("--width", type=int, default=512)
    parser.add_argument("--height", type=int, default=224)
    parser.add_argument("--palette", default="")
    parser.add_argument("--scale", type=int, default=1)
    parser.add_argument("--show-priority", action="store_true")
    parser.add_argument("--objects", action="store_true", help="draw the stage's placed objects on top")
    args = parser.parse_args()
    root = Path.cwd()

    if args.action == "validate":
        return validate(root)
    if args.action == "list":
        return show_list(root)
    if args.action == "draw":
        return draw(
            root,
            args.stage,
            args.output,
            args.x,
            args.y,
            max(8, args.width),
            max(8, args.height),
            args.palette,
            max(1, args.scale),
            args.show_priority,
            args.objects,
        )
    return inspect(root, args.stage, max(1, args.rows), max(1, args.columns))


if __name__ == "__main__":
    raise SystemExit(main())
