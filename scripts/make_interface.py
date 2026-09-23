"""Read the explicit, project-owned Make include graph without executing Make.

This is a source inventory, not a Make evaluator. Dynamic, optional or escaping
includes are refused rather than silently hiding release commands. Callers that
reuse reviewed commands bind every path and normalized byte, not just Makefile.
"""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path, PurePosixPath
import re

ROOT = Path(__file__).resolve().parents[1]
MAX_BYTES = 512 * 1024
MAX_FILES = 32
INCLUDE = re.compile(r"^\s*(-?include|sinclude)(?:\s+(.*))?$")
TARGET = re.compile(r"^([A-Za-z0-9_][A-Za-z0-9_.-]*)\s*:(?!=)", re.M)


def make_files(root: Path, read_bytes=None) -> tuple[tuple[str, bytes], ...]:
    """Return each literal include in encounter order, with bounded raw bytes.

    ``read_bytes(relative)`` may authenticate bytes against an operation's
    original tracked census. Make resolves include names from the project root,
    not from the directory of the including file; this reader does the same.
    """
    root = root.resolve()
    rows, visited, total = [], set(), 0

    def visit(relative):
        nonlocal total
        if (not re.fullmatch(r"[A-Za-z0-9_./-]+", relative)
                or PurePosixPath(relative).is_absolute()
                or any(part in {"", ".", ".."} for part in relative.split("/"))):
            raise ValueError("Make include path is not a literal project path: " + relative)
        if relative in visited:
            raise ValueError("Make include is repeated or cyclic: " + relative)
        if len(visited) >= MAX_FILES:
            raise ValueError("Make include graph exceeds its file bound")
        path = root
        for part in relative.split("/"):
            path /= part
            if path.is_symlink() or getattr(path, "is_junction", lambda: False)():
                raise ValueError("Make include path is redirected: " + relative)
        if not path.is_file() or not path.resolve().is_relative_to(root):
            raise ValueError("Make include source is missing: " + relative)
        if read_bytes is None:
            with path.open("rb") as stream:
                body = stream.read(MAX_BYTES - total + 1)
        else:
            body = read_bytes(relative)
        if type(body) is not bytes:
            raise ValueError("Make include reader did not return original bytes")
        total += len(body)
        if total > MAX_BYTES:
            raise ValueError("Make include graph exceeds its byte bound")
        text = body.decode("utf-8")
        visited.add(relative)
        rows.append((relative, body))
        for line in text.splitlines():
            if line.startswith("\t"):
                continue  # A recipe may print a word that resembles include.
            match = INCLUDE.fullmatch(line.split("#", 1)[0].rstrip())
            if match is None:
                continue
            if match[1] != "include" or not match[2]:
                raise ValueError("Make includes must be explicit and mandatory")
            for child in match[2].split():
                visit(child)

    visit("Makefile")
    return tuple(rows)


def make_text(root: Path, read_bytes=None) -> str:
    """Complete target/selector source, preserving each file's recipe bytes."""
    return "\n".join(body.decode("utf-8").replace("\r\n", "\n")
                     for _name, body in make_files(root, read_bytes))


def make_digest(files: tuple[tuple[str, bytes], ...]) -> str:
    """Unambiguous path-and-byte binding; only CRLF/LF are equivalent."""
    digest = hashlib.sha256()
    for name, body in files:
        for field in (name.encode("utf-8"), body.replace(b"\r\n", b"\n")):
            digest.update(len(field).to_bytes(8, "big"))
            digest.update(field)
    return digest.hexdigest()


def public_targets(root: Path) -> dict[str, tuple[str, ...]]:
    """Group all literal public commands by their workflow owner."""
    return {name: tuple(sorted(set(TARGET.findall(body.decode("utf-8")))))
            for name, body in make_files(root)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--list", action="store_true", help="List the complete literal public command inventory")
    args = parser.parse_args()
    try:
        inventory = public_targets(args.root)
    except (OSError, UnicodeError, ValueError) as error:
        parser.exit(1, "[FAIL] " + str(error) + "\n")
    print("\nComplete public commands (workflow owner):")
    for owner, targets in inventory.items():
        print("  " + owner + ": " + ", ".join(targets))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
