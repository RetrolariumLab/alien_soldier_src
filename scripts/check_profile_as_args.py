"""Reject caller-owned profile defines; PROFILE owns preservation selection."""
from __future__ import annotations

import argparse
import shlex
import sys

RESERVED = {"buildprofileeu", "buildprofilejp"}


def validate_flags(flags: str) -> None:
    """Inspect AS -D name=value operands, not arbitrary assembler semantics."""
    tokens = shlex.split(flags)
    index = 0
    while index < len(tokens):
        token = tokens[index]
        operand = None
        if token.casefold() == "-d":
            index += 1
            if index == len(tokens):
                raise ValueError("AS_ARGS -D is missing its symbol operand")
            operand = tokens[index]
        elif token[:2].casefold() == "-d" and len(token) > 2:
            operand = token[2:]
        if operand is not None:
            name = operand.partition("=")[0].strip()
            if not name:
                raise ValueError("AS_ARGS -D has an empty symbol name")
            if name.casefold() in RESERVED:
                raise ValueError("AS_ARGS may not define %s; select PROFILE=jp or PROFILE=eu instead" % name)
        index += 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flags", required=True)
    arguments = parser.parse_args()
    try:
        validate_flags(arguments.flags)
    except ValueError as error:
        print("[ERROR] " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
