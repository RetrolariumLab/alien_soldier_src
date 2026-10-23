#!/usr/bin/env python3
"""The source with its code moved: every procedure shifts against the others.

A copy of the source duplicates every return (`rts`) that ends a procedure,
so each procedure starts a little further on than the one before. A second
rts is never reached and costs no cycle (a nop would cost four, which moves
the frame counter and desynchronises a recorded movie), so the moved ROM
plays exactly like the original wherever every reference is symbolic. An rts
that is the first slot of a `jmp Table(pc,d0.w)` branch table is left alone:
a return is followed by a label, a table slot by another instruction. In the
modules SKIPPED a short branch stops reaching its target across an inserted
word.

    relocate.py --output-dir build/relocated     write the copy (main.s there)
    relocate.py --finish IMAGE --revision jp     fix the header checksum

The copy is assembled like the original; --finish then writes the checksum
the revision's boot code compares (the ranges are config/game_profile.json's).
Nothing under src/ is touched.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / "config/game_profile.json"
SKIPPED = {
    "src/sound/psg_playback_and_envelopes.s",
    "src/player/terrain_responses.s",
    "src/system/game_variables.s",
    "src/bosses/shellshogun_rendering.s",
    "src/bosses/missiray_segments.s",
}
INCLUDE = re.compile(r'include "(src/[^"]+)"')
RTS_LINE = re.compile(r"^\s+rts\s*(;.*)?$")
LABEL_LINE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*:")
CHECKSUM = 0x18E


def is_return(lines: list[str], index: int) -> bool:
    """The rts at `index` ends a procedure rather than filling a table slot."""
    for line in lines[index + 1 :]:
        stripped = line.strip()
        if stripped and not stripped.startswith(";"):
            return bool(LABEL_LINE.match(line))
    return True


def write_copy(root: Path, output: Path) -> tuple[int, int]:
    """Write output/main.s and the modules it replaces; (returns, modules)."""
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    main = (root / "src/main.s").read_text(encoding="utf-8")
    inserted = modules = 0
    for include in INCLUDE.findall(main):
        if include in SKIPPED or not include.endswith(".s"):
            continue
        lines = (root / include).read_text(encoding="utf-8").split("\n")
        rewritten, count = [], 0
        for index, line in enumerate(lines):
            rewritten.append(line)
            if RTS_LINE.match(line) and is_return(lines, index):
                rewritten.append("                rts")
                count += 1
        if not count:
            continue
        copy = output / include.replace("/", "__")
        copy.write_text("\n".join(rewritten), encoding="utf-8", newline="\n")
        # Include paths stay relative to the repository root, the assembler's
        # include directory.
        relative = copy.resolve().relative_to(root.resolve()).as_posix()
        main = main.replace(f'include "{include}"', f'include "{relative}"', 1)
        inserted += count
        modules += 1
    (output / "main.s").write_text(main, encoding="utf-8", newline="\n")
    return inserted, modules


def finish(image: Path, revision: str) -> int:
    """Write the header checksum the revision's boot code expects."""
    settings = json.loads(PROFILE.read_text(encoding="utf-8"))["source"]["revisions"][revision]
    first, end = (int(str(value), 0) for value in settings["checksum"])
    data = bytearray(image.read_bytes())
    total = 0
    for offset in range(first, min(end, len(data)), 2):
        total += int.from_bytes(bytes(data[offset : offset + 2]).ljust(2, b"\0"), "big")
    data[CHECKSUM : CHECKSUM + 2] = (total & 0xFFFF).to_bytes(2, "big")
    image.write_bytes(bytes(data))
    return total & 0xFFFF


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--finish", type=Path, metavar="IMAGE")
    parser.add_argument("--revision", default="jp")
    args = parser.parse_args()
    if args.output_dir:
        inserted, modules = write_copy(ROOT, (ROOT / args.output_dir).resolve())
        print(f"[OK] {inserted} returns duplicated in {modules} modules: {args.output_dir}/main.s")
    if args.finish:
        print(f"[OK] {args.finish}: checksum ${finish(args.finish, args.revision):04X}")
    if not args.output_dir and not args.finish:
        parser.error("say --output-dir or --finish")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
