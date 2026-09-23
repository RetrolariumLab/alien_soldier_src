#!/usr/bin/env python3
"""Rebuild the cartridge with every payload compressed by our own encoder.

The point is not byte identity -- the original encoder is a fast heuristic and
an optimal parse beats it by twelve to twenty-six per cent, so a repacked image
cannot match and does not try. The point is the only thing an editor needs: a
payload this project wrote is one the game reads back correctly, and the ROM
around it still boots.

Nothing under `src/` or `data/` is touched. The tree is mirrored into
`build/repack/`, the payloads are rewritten there, and the assembler is pointed
at the mirror, the same way `verify_relocation.py` builds its perturbed image.

Two things have to be got right or the image is dead on arrival:

  * every payload must decode back to the bytes that went in, checked against
    `scripts/unpack_data.py`, which is the model of `Data_LZSSDecomp`;
  * the boot checksum must be recomputed. `ChecksumCheck` adds the words from
    `Reset` to `$60000` and compares them with the word at `Checksum`; on a
    mismatch it jumps to `Boot_ShowRedScreen` and the game never starts. A
    repacked image shifts everything after the first changed payload, so the
    stored word is always wrong until it is written again.
"""

from __future__ import annotations

import argparse
import shutil
import struct
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from authoring.lzss_codec import (                                        # noqa: E402
    cartridge_payloads, compress, decompress, decompress_as_vram)


MIRROR = Path("build/repack")
DMA_BLOCK = 0x20000              # the VDP latches the bits above this
TRANSFERRED = "data/artunc/"     # the region config/rom_layout.json declares
ALIGN_ROUNDS = 8
CHECKSUM_AT = 0x18E              # the word ChecksumCheck compares against
CHECKSUM_FROM = 0x200            # Reset
CHECKSUM_TO = 0x60000            # the hardcoded limit in the loop
BINCLUDE = "binclude \""


def payload_files(root):
    """Compressed payloads that live in a file rather than inline in the source."""
    import re

    pattern = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s+binclude\s+"([^"]+)"')
    named = {}
    for path in sorted((root / "src").rglob("*.s")):
        for line in path.read_text(encoding="utf-8").split("\n"):
            match = pattern.match(line)
            if match:
                named[match.group(1)] = match.group(2)
    return {name: named[name] for name in cartridge_payloads(root) if name in named}


def mirror(root, output):
    """A copy of the tree the assembler can be pointed at instead."""
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    shutil.copytree(root / "src", output / "src")
    shutil.copytree(root / "data", output / "data")
    return output


def split_archives(raw):
    """The archives a payload file holds, and whatever is left after them.

    Eight of the files hold two archives back to back, one label pointing only
    at the first: tiles_136512.bin is Wolf Garopa's art twice over. Reading the
    header as the whole file loses the second one, which is how a repack could
    leave that fight a field of broken tiles while every check still passed.
    """
    import struct as _struct

    found = []
    at = 0
    while at + 2 < len(raw):
        header = _struct.unpack_from(">H", raw, at)[0]
        if header == 0 or at + 2 + header > len(raw):
            break
        size = 2 + header + (header % 2)
        found.append(raw[at:at + size])
        at += size
    return found, raw[at:]


def repack(root, output, payloads):
    """Rewrite each payload in the mirror, and say what it cost."""
    before = after = 0
    errors = []
    for name, relative in sorted(payloads.items()):
        original = (root / relative).read_bytes()
        chunks, tail = split_archives(original)
        if not chunks:
            errors.append("%s: holds no archive" % name)
            continue
        rebuilt = bytearray()
        failed = False
        for index, chunk in enumerate(chunks):
            plain = decompress_as_vram(chunk)
            fresh = compress(plain)
            # Checked against the VRAM loader's semantics, which reset the
            # output pointer every $400. The RAM loader's do not, so checking
            # against those accepts a stream the hardware will read wrong.
            try:
                if decompress_as_vram(fresh) != plain:
                    errors.append("%s: archive %d decodes back to something else"
                                  % (name, index))
                    failed = True
                    break
            except ValueError as error:
                errors.append("%s: archive %d: %s" % (name, index, error))
                failed = True
                break
            if len(chunks) > 1:
                # Something reaches the later archives by an address inside the
                # file, so each one is padded back to the length it had and
                # every offset within the file stays where it was
                if len(fresh) <= len(chunk):
                    fresh = fresh + bytes([0xFF]) * (len(chunk) - len(fresh))
                else:
                    fresh = chunk
            rebuilt += fresh
        if failed:
            continue
        rebuilt += tail
        (output / relative).write_bytes(bytes(rebuilt))
        before += len(original)
        after += len(rebuilt)
    return before, after, errors


def assemble(root, mirrored, as_bin, p2bin, rom, defines=()):
    listing = mirrored / "main.lst"
    obj = mirrored / "main.p"
    command = [str(as_bin.resolve()), "-i", str(mirrored.resolve()), "-L",
               "-olist", str(listing), "-o", str(obj), "-maxerrors", "2"]
    for define in defines:
        command += ["-D", define]
    command.append(str((mirrored / "src/main.s").resolve()))
    result = subprocess.run(command, cwd=root, capture_output=True, text=True)
    # AS still writes a .p when it has complained, and a layout that overflows
    # an `org` complains rather than failing outright, so the object file
    # existing is not enough to call the build good
    import re as _re

    counts = dict(_re.findall(r"(\d+)\s+(errors?|warnings?)", result.stdout))
    tally = {kind.rstrip("s"): int(number)
             for number, kind in _re.findall(r"(\d+)\s+(errors?|warnings?)",
                                             result.stdout)}
    if result.returncode != 0 or tally.get("error", 0) or tally.get("warning", 0):
        print("[ERROR] the assembler reported %d error(s) and %d warning(s)"
              % (tally.get("error", 0), tally.get("warning", 0)), file=sys.stderr)
        for line in result.stdout.splitlines():
            if _re.search(r"error|warning|overlap|already", line, _re.I)                     and not _re.match(r"\s*\d+\s+(errors?|warnings?)", line):
                print("[ERROR] assembler: %s" % line.strip()[:160], file=sys.stderr)
        return None
    if not obj.is_file():
        print(result.stdout[-2000:], file=sys.stderr)
        return None
    subprocess.run([str(p2bin.resolve()), str(obj), str(rom), "-p=FF"],
                   cwd=root, capture_output=True, text=True)
    return rom if rom.is_file() else None


def misplaced(listing, rom, root):
    """Payloads whose bytes are not where the listing says they are.

    AS treats `org` as a plain move of the counter, so a layout that grows past
    a pinned address silently emits over what is already there and reports no
    error and no warning at all; p2bin then resolves the overlap without a word.
    The only way to know the image is sound is to look for each payload where
    it was placed.
    """
    import re

    line = re.compile(r"^\(\d+\)\s+\d+/\s*([0-9A-F]+) :")
    include = re.compile(r'binclude\s+"(data/[^"]+)"')
    image = Path(rom).read_bytes()
    wrong = []
    for text in Path(listing).read_text(encoding="utf-8", errors="replace").splitlines():
        name = include.search(text)
        address = line.match(text)
        if not (name and address):
            continue
        start = int(address.group(1), 16)
        want = (root / name.group(1)).read_bytes()
        if image[start:start + len(want)] != want:
            wrong.append((name.group(1), start))
    return wrong


def crossings(listing, root):
    """Transferred payloads that straddle a DMA block, worst first.

    The VDP latches the bits above $20000, so a transfer that crosses one wraps
    to the start of the block instead of continuing. Repacking moves every
    payload after the first change, which is how a stage's *uncompressed*
    sprite art ends up corrupted by a compression change.
    """
    import re

    line = re.compile(r"^\(\d+\)\s+\d+/\s*([0-9A-F]+) :")
    include = re.compile(r'binclude\s+"(' + TRANSFERRED + r'[^"]+)"')
    found = []
    for text in Path(listing).read_text(encoding="utf-8", errors="replace").splitlines():
        name = include.search(text)
        address = line.match(text)
        if not (name and address):
            continue
        start = int(address.group(1), 16)
        size = (root / name.group(1)).stat().st_size
        if start // DMA_BLOCK != (start + size - 1) // DMA_BLOCK:
            found.append((name.group(1), start, size))
    return found


def pad_before(mirrored, payload, count):
    """Push one payload forward by that many bytes, in the mirror only."""
    for path in sorted(mirrored.joinpath("src").rglob("*.s")):
        text = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(text):
            if BINCLUDE + payload + '"' not in line:
                continue
            filler = ["                dc.b    [$%X]$FF" % chunk
                      for chunk in split_filler(count)]
            text[index:index] = filler
            path.write_text(chr(10).join(text), encoding="utf-8", newline="")
            return True
    return False


def split_filler(count):
    """AS refuses a very large repeat, so the fill goes in pieces."""
    limit = 0x1000
    while count > 0:
        take = min(limit, count)
        yield take
        count -= take


def fix_checksum(rom):
    """Write the word ChecksumCheck will compute, or the game shows red."""
    image = bytearray(rom.read_bytes())
    total = 0
    at = CHECKSUM_FROM
    while at <= CHECKSUM_TO:
        total = (total + struct.unpack_from(">H", image, at)[0]) & 0xFFFF
        at += 2
    was = struct.unpack_from(">H", image, CHECKSUM_AT)[0]
    struct.pack_into(">H", image, CHECKSUM_AT, total)
    rom.write_bytes(bytes(image))
    return was, total


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--as-bin", required=True)
    parser.add_argument("--p2bin", required=True)
    parser.add_argument("--rom", default="alien_soldier_repacked.bin")
    parser.add_argument("--define", action="append", default=[],
                        help="a symbol for the assembler, such as GOD_MODE=1")
    args = parser.parse_args()
    root = Path.cwd()

    payloads = payload_files(root)
    output = mirror(root, root / MIRROR)
    before, after, errors = repack(root, output, payloads)
    if errors:
        for error in errors:
            print("[ERROR] %s" % error, file=sys.stderr)
        return 1

    rom = assemble(root, output, Path(args.as_bin), Path(args.p2bin),
                   root / args.rom, args.define)
    if rom is None:
        print("[ERROR] the repacked tree did not assemble", file=sys.stderr)
        return 1

    padded = 0
    for _ in range(ALIGN_ROUNDS):
        straddling = crossings(output / "main.lst", root)
        if not straddling:
            break
        name, start, size = straddling[0]
        count = (start // DMA_BLOCK + 1) * DMA_BLOCK - start
        if not pad_before(output, name, count):
            print("[ERROR] could not find %s to pad before" % name, file=sys.stderr)
            return 1
        padded += count
        rom = assemble(root, output, Path(args.as_bin), Path(args.p2bin),
                       root / args.rom, args.define)
        if rom is None:
            print("[ERROR] the padded tree did not assemble", file=sys.stderr)
            return 1
    straddling = crossings(output / "main.lst", root)
    if straddling:
        for name, start, size in straddling:
            print("[ERROR] %s at $%06X still crosses a DMA block" % (name, start),
                  file=sys.stderr)
        return 1
    was, now = fix_checksum(rom)
    print("[OK] repacked %d payloads: %d -> %d bytes (%.1f%% of the original)"
          % (len(payloads), before, after, 100.0 * after / before))
    print("[OK] %s is %d bytes, checksum $%04X rewritten to $%04X"
          % (args.rom, rom.stat().st_size, was, now))
    print("[OK] %d bytes of alignment kept every transferred payload inside "
          "its $20000 block" % padded)
    print("     every payload decodes back to what went in; the original "
          "encoder cannot be matched byte for byte and this does not try")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
