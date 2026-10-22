"""Assemble the shared DAC program from Z80 source before a cartridge build."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ENTRY = Path("src/sound/z80/driver.asm")
OUTPUT = Path("build/z80/driver.bin")
REFERENCE = Path("data/sound/z80_data.bin")
IMAGE_BYTES = 3072


def build(root: Path, assembler: Path, converter: Path) -> Path:
    root, assembler, converter = root.resolve(), assembler.resolve(), converter.resolve()
    source = root / ENTRY
    if not source.is_file():
        raise ValueError("missing Z80 assembly entrypoint: " + str(source))
    output = root / OUTPUT
    for parent in (output.parent, *output.parent.parents):
        if parent.is_symlink() or getattr(parent, "is_junction", lambda: False)():
            raise ValueError("Z80 build output crosses a filesystem link")
        if parent == root:
            break
    output.parent.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment["AS_MSGPATH"] = str(assembler.parent)
    with tempfile.TemporaryDirectory(prefix=".assemble-", dir=output.parent) as directory:
        work = Path(directory)
        obj, image = work / "driver.p", work / "driver.bin"
        subprocess.run(
            [str(assembler), "-i", str(root), "-maxerrors", "2", "-o", str(obj), str(source)],
            cwd=root,
            env=environment,
            check=True,
        )
        subprocess.run([str(converter), str(obj), str(image), "-p=00"], cwd=root, env=environment, check=True)
        body = image.read_bytes()
        if len(body) != IMAGE_BYTES:
            raise ValueError("Z80 image must fit the exact 3072-byte loader contract")
        # Never publish a partial or failed assembly. Keep identical outputs'
        # timestamps stable for direct listing and other Make consumers.
        if not output.exists() or output.read_bytes() != body:
            os.replace(image, output)
    return output


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--as-bin", type=Path, default=Path("bin/windows_i386/asw.exe"))
    parser.add_argument("--p2bin", type=Path, default=Path("bin/windows_i386/p2bin.exe"))
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args(argv)
    try:
        output = build(args.root, args.as_bin, args.p2bin)
        body = output.read_bytes()
        if args.verify:
            original = (args.root / REFERENCE).read_bytes()
            if body != original:
                raise ValueError("assembled Z80 program differs from the preservation reference")
        print("[OK] assembled Z80 program: %d bytes, SHA256 %s" % (len(body), hashlib.sha256(body).hexdigest()))
        return 0
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print("[ERROR] " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
