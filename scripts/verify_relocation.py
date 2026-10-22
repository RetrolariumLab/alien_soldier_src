#!/usr/bin/env python3
"""Rebuild the ROM with its layout perturbed and check that every pointer moved.

Three perturbations, declared in config/rom_layout.json:

  content  grows each padding gap by whole DMA blocks, so all content moves
           while the code keeps its shape;
  code     inserts unreachable nops inside the code region, so code labels move
           relative to one another while the content stays where it was;
  returns  duplicates every safe rts, so every procedure moves relative to every
           other one without costing a cycle.

Either way the assembler must rewrite every reference. A value that equals the
address of a symbol which moved, and that did not move with it, was written as a
literal rather than as a reference - which is the defect this looks for. Nothing
under src/ is touched: the perturbed entrypoint and the files it replaces are
generated under the output directory and assembled from there.
"""

from __future__ import annotations

import argparse
import bisect
import json
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path


LISTING_ROW = re.compile(r"^\(\d+\)\s+\d+/\s*([0-9A-F]+)\s*:")
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
INCLUDE_ROW = re.compile(r'^\s*\d+/\s*([0-9A-F]+) :\s+include "([^"]+)"')
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
# Bit operations take a bit number and an operand, never a 32-bit immediate.
BIT_OPERATIONS = {"btst", "bset", "bclr", "bchg"}
RTS_LINE = re.compile(r"^\s+rts\s*(;.*)?$")
LABEL_LINE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*:")


HEX_WORD = re.compile(r"^[0-9A-F]{2,4}$")


def number(value: str | int) -> int:
    return value if isinstance(value, int) else int(value, 0)


def source_text(line: str) -> str:
    """The source half of a listing row.

    The emitted-byte column is as wide as the statement needs, so the source
    text does not start at a fixed position; the bytes are stripped token by
    token instead.
    """
    _, _, rest = line.partition(" : ")
    tokens = rest.split()
    index = 0
    while index < len(tokens) and HEX_WORD.match(tokens[index]):
        index += 1
    return " ".join(tokens[index:])


class Listing:
    """Addresses and source text recovered from an assembler listing."""

    def __init__(self, path: Path) -> None:
        self.symbols: dict[str, int] = {}
        self.includes: list[tuple[int, str]] = []
        statements: list[tuple[int, str]] = []
        for line in path.read_text(encoding="latin-1").splitlines():
            include = INCLUDE_ROW.match(line)
            if include:
                self.includes.append((int(include.group(1), 16), include.group(2).replace("\\", "/")))
                continue
            row = LISTING_ROW.match(line)
            if not row or len(line) < 40:
                continue
            address = int(row.group(1), 16)
            text = source_text(line)
            label = LABEL.match(text)
            if label:
                self.symbols.setdefault(label.group(1), address)
            if text.strip():
                statements.append((address, text.split(";", 1)[0].rstrip()))
        statements.sort()
        self.statement_addresses = [address for address, _ in statements]
        self.statement_text = [text for _, text in statements]

    def statement(self, offset: int) -> tuple[int, int, str]:
        """The statement covering an offset, as (start, end, source text).

        A bare label emits nothing, so when one covers the offset the directive
        that actually produced the bytes is the one before it.
        """
        index = bisect.bisect_right(self.statement_addresses, offset) - 1
        if index < 0:
            return (0, 0, "")
        start = self.statement_addresses[index]
        end = self.statement_addresses[index + 1] if index + 1 < len(self.statement_addresses) else 1 << 24
        walk = index
        while walk >= 0 and not LABEL.sub("", self.statement_text[walk].strip(), count=1).strip():
            walk -= 1
        text = self.statement_text[walk] if walk >= 0 else self.statement_text[index]
        return (start, end, text)


def module_shifts(before: Listing, after: Listing) -> list[tuple[int, int, int]]:
    """Per-module (start, end, shift), in canonical address order."""
    landed = {}
    for address, path in after.includes:
        landed.setdefault(path, address)
    ordered = sorted(before.includes)
    rows = []
    for index, (start, path) in enumerate(ordered):
        end = ordered[index + 1][0] if index + 1 < len(ordered) else 1 << 24
        if path in landed:
            rows.append((start, end, landed[path] - start))
    return rows


def shift_at(rows: list[tuple[int, int, int]], offset: int) -> int | None:
    index = bisect.bisect_right([row[0] for row in rows], offset) - 1
    if index < 0:
        return None
    start, end, delta = rows[index]
    return delta if start <= offset < end else None


def returns_are_safe(lines: list[str], index: int) -> bool:
    """True when the rts at `index` is a return rather than a branch table slot.

    A branch table built from two-byte instructions is reached by
    `jmp Table(pc,d0.w)` and starts with an rts as entry zero; duplicating that
    adds a slot and shifts every later mode. A real return is followed by a
    label, or by nothing.
    """
    for line in lines[index + 1 :]:
        stripped = line.strip()
        if not stripped or stripped.startswith(";"):
            continue
        return bool(LABEL_LINE.match(line))
    return True


def add_returns(root: Path, main: str, skip: set[str], output: Path) -> tuple[str, int, int]:
    """Duplicate every safe rts, moving each procedure without costing a cycle.

    A nop would cost four, and four cycles anywhere move the frame counter,
    which desynchronises a recorded movie on a ROM that is otherwise perfectly
    playable. A second rts is unreachable by construction and free.
    """
    inserted = modules = 0
    for include in re.findall(r'include "(src/[^"]+)"', main):
        if include in skip:
            continue
        lines = (root / include).read_text(encoding="utf-8").split("\n")
        rewritten, count = [], 0
        for index, line in enumerate(lines):
            rewritten.append(line)
            if RTS_LINE.match(line) and returns_are_safe(lines, index):
                rewritten.append("                rts")
                count += 1
        if not count:
            continue
        copy = output / include.replace("/", "__")
        copy.write_text("\n".join(rewritten), encoding="utf-8", newline="")
        relative = copy.resolve().relative_to(root.resolve()).as_posix()
        main = main.replace(f'include "{include}"', f'include "{relative}"', 1)
        inserted += count
        modules += 1
    return main, inserted, modules


def generate(root: Path, probe: dict, output: Path) -> Path:
    """Write a perturbed copy of the entrypoint and the files it replaces."""
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    main = (root / "src/main.s").read_text(encoding="utf-8")
    for entry in probe.get("gap_growth", []):
        source = Path(entry["file"])
        original = "                org     $%X\n" % number(entry["org"])
        grown = "                org     $%X\n" % (
            number(entry["org"]) + number(entry["blocks"]) * number(probe["block_size"])
        )
        main = replace_include(root, main, source, original, grown, output)
    for entry in probe.get("code_filler", []):
        source = Path(entry["file"])
        filler = "                dc.w    [%d]$4E71\n" % number(entry["words"])
        main = replace_include(root, main, source, "", filler, output)
    returns = probe.get("return_filler")
    if returns:
        main, inserted, modules = add_returns(root, main, set(returns["skip_modules"]), output)
        probe["_returns"] = (inserted, modules)
    entrypoint = output / "main.s"
    entrypoint.write_text(main, encoding="utf-8", newline="\n")
    return entrypoint


def replace_include(root: Path, main: str, source: Path, original: str, replacement: str, output: Path) -> str:
    text = (root / source).read_text(encoding="utf-8")
    if original:
        if text.count(original) != 1:
            raise SystemExit(f"[ERROR] expected exactly one {original.strip()!r} in {source}")
        text = text.replace(original, replacement, 1)
    else:
        text = replacement + text
    copy = output / source.name
    copy.write_text(text, encoding="utf-8", newline="\n")
    include = f'include "{source.as_posix()}"'
    if include not in main:
        raise SystemExit(f"[ERROR] src/main.s does not include {source}")
    # The include path stays relative to the project root, which is the assembler
    # include directory; an absolute one with a drive letter does not open.
    relative = copy.resolve().relative_to(root.resolve()).as_posix()
    return main.replace(include, f'include "{relative}"', 1)


def assemble(root: Path, entrypoint: Path, as_bin: Path, p2bin: Path, output: Path, padding: str) -> tuple[Path, Path]:
    listing = output / "main.lst"
    obj = output / "main.p"
    rom = output / "perturbed.bin"
    result = subprocess.run(
        [
            str(as_bin.resolve()),
            "-i",
            str(root),
            "-L",
            "-olist",
            str(listing),
            "-o",
            str(obj),
            "-maxerrors",
            "2",
            str(entrypoint),
        ],
        cwd=root,
        capture_output=True,
        text=True,
    )
    if not obj.is_file():
        print(result.stdout[-2000:], file=sys.stderr)
        raise SystemExit("[ERROR] the perturbed source did not assemble")
    subprocess.run(
        [str(p2bin.resolve()), str(obj), str(rom), f"-p={padding}"], cwd=root, capture_output=True, text=True
    )
    if not rom.is_file():
        raise SystemExit("[ERROR] the perturbed object did not convert")
    return listing, rom


def owning_module(includes: list[tuple[int, str]], address: int) -> str:
    ordered = sorted(includes)
    index = bisect.bisect_right([start for start, _ in ordered], address) - 1
    return ordered[index][1] if index >= 0 else ""


def compare(
    before: Listing,
    after: Listing,
    canonical: bytes,
    perturbed: bytes,
    accepted: list[dict],
    content_modules: tuple[str, ...],
    alignment: int,
) -> tuple[int, list[str]]:
    rows = module_shifts(before, after)
    # Only content symbols are considered, and only those that do not sit on a
    # $8000 boundary. A pointer written as a literal is the defect being looked
    # for, and with fifteen thousand symbols in the image a four-byte window
    # matches one often enough that the code labels, which are by far the
    # densest, drown the signal. The boundary-aligned symbols are the PCM banks,
    # whose addresses are exactly the round numbers this ROM uses for VDP
    # commands and 16.16 constants, and which are referenced as (symbol >> 8)
    # anyway, so a 32-bit scan never sees a real one.
    moved = {
        address: after.symbols[name] - address
        for name, address in before.symbols.items()
        if name in after.symbols
        and after.symbols[name] != address
        and owning_module(before.includes, address).startswith(content_modules)
        and address % alignment
    }
    names_at: dict[int, str] = {}
    for name, address in before.symbols.items():
        names_at.setdefault(address, name)
    known = set(before.symbols)

    followed = 0
    findings: list[str] = []
    for offset in range(0, len(canonical) - 4, 2):
        value = struct.unpack_from(">I", canonical, offset)[0]
        delta = moved.get(value)
        if delta is None:
            continue
        here = shift_at(rows, offset)
        if here is None:
            continue
        if struct.unpack_from(">I", perturbed, offset + here)[0] == value + delta:
            followed += 1
            continue
        start, end, text = before.statement(offset)
        # A window that runs past the end of the statement that emitted it is a
        # coincidence spanning two statements, not an operand.
        if offset + 4 > end:
            continue
        # A site authored as a symbol is relocated by the assembler, so it can
        # only be here by coincidence too. The label a statement defines is not
        # one of its operands, so it is stripped before looking.
        operands = LABEL.sub("", text.strip(), count=1)
        if any(token in known for token in IDENTIFIER.findall(operands)):
            continue
        operands_only = operands.strip()
        directive = operands_only.split()[0] if operands_only else "?"
        # Bytes inside an extracted payload are opaque: the assembler cannot
        # relocate them and the source cannot express them differently, so a
        # window matching an address there says nothing about the source.
        if directive == "binclude":
            continue
        # A word- or byte-sized instruction cannot carry a 32-bit address, so a
        # window that lands inside one is reading across its operands.
        if directive.endswith((".w", ".b")) and not directive.startswith("dc"):
            continue
        if directive in BIT_OPERATIONS:
            continue
        if any(number(rule["value"]) == value and rule["directive"] == directive for rule in accepted):
            continue
        findings.append(
            f"ROM ${offset:06X} holds ${value:06X}, the address of "
            f"{names_at.get(value, 'a symbol')}, which moved by ${delta:X}; the value did not. "
            f"Source: {text.strip()[:60]}"
        )
    return followed, findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", default="config/rom_layout.json")
    parser.add_argument("--listing", default="build/main.lst")
    parser.add_argument("--rom", default="asbuilt.bin")
    parser.add_argument("--as-bin", default="bin/windows_i386/asw.exe")
    parser.add_argument("--p2bin", default="bin/windows_i386/p2bin.exe")
    parser.add_argument("--probe", default="")
    args = parser.parse_args()

    root = Path.cwd()
    layout = json.loads((root / args.layout).read_text(encoding="utf-8"))
    probe_config = layout.get("relocation_probe")
    if not probe_config:
        print("[ERROR] ROM layout declares no relocation probe", file=sys.stderr)
        return 1
    listing_path = root / args.listing
    if not listing_path.is_file():
        print(f"[ERROR] listing is missing: {listing_path}; run make build first", file=sys.stderr)
        return 1

    before = Listing(listing_path)
    canonical = (root / args.rom).read_bytes()
    accepted = probe_config.get("accepted_coincidences", [])
    base_output = root / probe_config.get("output_dir", "build/relocation")

    total_followed = 0
    failed = False
    for probe in probe_config["probes"]:
        if args.probe and probe["id"] != args.probe:
            continue
        probe = dict(probe, block_size=probe_config["block_size"])
        output = base_output / probe["id"]
        entrypoint = generate(root, probe, output)
        listing, rom = assemble(
            root,
            entrypoint,
            Path(args.as_bin),
            Path(args.p2bin),
            output,
            layout["rom_image"].get("padding_byte", "FF") if isinstance(layout.get("rom_image"), dict) else "FF",
        )
        after = Listing(listing)
        perturbed = rom.read_bytes()
        moved_modules = sum(1 for _, _, delta in module_shifts(before, after) if delta)
        if probe.get("return_filler"):
            inserted, moved = probe.get("_returns", (0, 0))
            skipped = len(probe["return_filler"]["skip_modules"])
            ceiling = int(probe["return_filler"]["maximum_skipped_modules"])
            if skipped > ceiling:
                failed = True
                print(
                    f"[ERROR] probe {probe['id']}: {skipped} modules cannot take an extra "
                    f"return; the ceiling is {ceiling}",
                    file=sys.stderr,
                )
            else:
                print(
                    f"[OK] probe {probe['id']}: {inserted} extra returns across {moved} "
                    f"modules assemble, {skipped} module(s) declared unable to take one"
                )
            continue
        followed, findings = compare(
            before,
            after,
            canonical,
            perturbed,
            accepted,
            tuple(probe_config["content_modules"]),
            number(probe_config["ignore_symbols_aligned_to"]),
        )
        total_followed += followed
        if findings:
            failed = True
            print(f"[ERROR] probe {probe['id']}: {len(findings)} reference(s) did not move", file=sys.stderr)
            for finding in findings[:20]:
                print(f"[ERROR]   {finding}", file=sys.stderr)
        else:
            print(f"[OK] probe {probe['id']}: {moved_modules} modules moved, {followed} references followed them")
    if failed:
        return 1
    print(f"[OK] relocation: {total_followed} pointer references followed the layout")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
