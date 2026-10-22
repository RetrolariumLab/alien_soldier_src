#!/usr/bin/env python3
"""Enforce structural, provenance, and unknown-name source policy."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
EQUATE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s+equ\b", re.IGNORECASE)
INDENTED_DEFINITION = re.compile(r"^\s+([A-Za-z_][A-Za-z0-9_]*(?::|\s+equ\b))", re.IGNORECASE)
BRANCH_MNEMONIC = (
    r"jsr|jmp|bsr|bra|dbf|dbra|dbeq|dbne"
    r"|b(?:hi|ls|cc|cs|ne|eq|vc|vs|pl|mi|ge|lt|gt|le)"
)
# A branch or call whose destination is written as a symbol, in any of the three
# forms the source uses: bare, parenthesised absolute, or PC-relative.
CALL_TARGET = re.compile(
    r"^\s+(?:" + BRANCH_MNEMONIC + r")(?:\.[bwsl])?\s+(?:[^,;]*,)?"
    r"\s*\(?\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)?(?:\.[wl])?"
    r"\s*(?:\(pc[^)]*\))?\s*(?:;.*)?$",
    re.IGNORECASE,
)
# A work RAM address formed from a raw literal rather than from a name. Only
# address-forming instructions are covered: the same bit pattern in moveq or
# move.l is almost always a negative constant, not an address.
RAW_RAM_ADDRESS = re.compile(
    r"^\s+(?:movea\.[wl]|cmpa\.[wl]|lea|pea|suba\.l|adda\.l)\s+[^;]*\$FFFF[0-9A-Fa-f]{4}",
    re.IGNORECASE,
)
REGISTER = re.compile(r"^(?:[da][0-7]|sp|pc|sr|ccr|usp)$", re.IGNORECASE)
INCLUDE = re.compile(r'^\s*include\s+"([^"]+)"', re.IGNORECASE)
WAS = re.compile(r";\s*was:\s*([A-Za-z_][A-Za-z0-9_]*)\s*$")
XREF_COMMENT = re.compile(r";\s*(?:(?:CODE|DATA)\s+XREF:|ROM:)\s*([^;]*)")
IDENTIFIER = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
OWNER_TOKEN = re.compile(r"^[A-Z][a-z0-9]*")
EMITTING = re.compile(
    r"^\s*(?:dc\.[bwl]|dcb\.[bwl]|binclude|incbin|org0?|align0?|cnop0?)\b",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class Inventory:
    definitions: dict[str, str]
    provenance: dict[str, tuple[str, str]]
    address_derived: dict[str, str]
    errors: list[str]
    call_targets: int = 0


def source_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.s")) + sorted(root.rglob("*.inc"))


def scan(policy: dict, project_root: Path) -> Inventory:
    source_root = project_root / policy["assembly_root"]
    old_name = re.compile(policy["provenance"]["legacy_name_pattern"], re.IGNORECASE)
    address_name = re.compile(policy["unknowns"]["address_derived_name_pattern"], re.IGNORECASE)
    entrypoint = project_root / policy["entrypoint"]
    layout = json.loads((project_root / policy["layout"]).read_text(encoding="utf-8"))
    line_limit = layout["target"]["max_module_lines"]
    style = policy["style"]

    definitions: dict[str, str] = {}
    provenance: dict[str, tuple[str, str]] = {}
    old_symbols: dict[str, str] = {}
    address_derived: dict[str, str] = {}
    call_targets: list[tuple[str, str]] = []
    errors: list[str] = []

    for path in source_files(source_root):
        relative = path.relative_to(project_root).as_posix()
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        if style["lowercase_source_paths"] and relative != relative.lower():
            errors.append(f"{relative}: source path is not lowercase")
        if style["require_final_newline"] and text and not text.endswith("\n"):
            errors.append(f"{relative}: missing final newline")
        if path.suffix == ".s" and path != entrypoint and len(lines) > line_limit:
            errors.append(f"{relative}: {len(lines)} lines exceeds limit {line_limit}")

        current_label: str | None = None
        for number, line in enumerate(lines, 1):
            where = f"{relative}:{number}"
            if line.rstrip(" \t") != line:
                errors.append(f"{where}: trailing whitespace")
            if len(line) > style["maximum_line_length"]:
                errors.append(f"{where}: line has {len(line)} characters; limit is {style['maximum_line_length']}")
            xref = XREF_COMMENT.search(line)
            if xref:
                for token in IDENTIFIER.findall(xref.group(1)):
                    if address_name.fullmatch(token):
                        errors.append(f"{where}: cross-reference comment uses retired address-derived name {token}")
            if style["definitions_column_zero"] and INDENTED_DEFINITION.match(line):
                errors.append(f"{where}: global definition must start in column zero")
            if style["includes_only_in_entrypoint"] and path != entrypoint and INCLUDE.match(line):
                errors.append(f"{where}: include is only allowed in {policy['entrypoint']}")

            match = LABEL.match(line) or EQUATE.match(line)
            if match:
                name = match.group(1)
                current_label = name
                if name in definitions:
                    errors.append(f"{where}: {name} already defined at {definitions[name]}")
                else:
                    definitions[name] = where
                if address_name.fullmatch(name):
                    address_derived[name] = where

            if RAW_RAM_ADDRESS.match(line.split(";")[0]):
                errors.append(
                    f"{where}: work RAM address written as a raw literal; use the name from src/ram_addrs.inc"
                )

            call = CALL_TARGET.match(line)
            if call and not REGISTER.match(call.group(1)):
                call_targets.append((call.group(1), where))

            marker = WAS.search(line)
            if marker:
                legacy = marker.group(1)
                if not old_name.fullmatch(legacy):
                    errors.append(f"{where}: malformed legacy name {legacy}")
                if current_label is None:
                    errors.append(f"{where}: provenance marker has no owning global label")
                elif current_label in provenance:
                    errors.append(f"{where}: duplicate provenance for {current_label}")
                elif legacy in old_symbols:
                    errors.append(f"{where}: {legacy} already mapped at {old_symbols[legacy]}")
                else:
                    provenance[current_label] = (legacy, where)
                    old_symbols[legacy] = where

    # A branch into a name nothing defines would assemble only by accident, or
    # not at all. Resolving every one against the definitions this scan already
    # collected is what keeps the source self-contained.
    for target, where in call_targets:
        if target not in definitions:
            errors.append(f"{where}: branch target {target} is not defined in the source")

    naming = policy["naming"]
    vocabulary = set(naming["subsystem_vocabulary"])
    hardware_files = set(naming["hardware_exception_files"])
    hardware_names = set(naming["hardware_exception_names"])
    for name, where in definitions.items():
        if where.rsplit(":", 1)[0] in hardware_files or name in hardware_names:
            continue
        if "_" in name:
            parent = name.rsplit("_", 1)[0]
            if parent != name and parent in definitions:
                continue
            token = name.split("_", 1)[0]
        else:
            leading = OWNER_TOKEN.match(name)
            token = leading.group(0) if leading else name
        if token not in vocabulary:
            errors.append(
                f"{where}: {name} is owned by {token}, which is not a declared subsystem; "
                "name it after one, derive it from a symbol that exists, or declare it"
            )

    minimum = policy["provenance"]["minimum_unique_mappings"]
    if len(provenance) < minimum:
        errors.append(f"provenance has {len(provenance)} mappings; policy requires at least {minimum}")
    maximum = policy["unknowns"]["maximum_address_derived_definitions"]
    if len(address_derived) > maximum:
        errors.append(f"source has {len(address_derived)} address-derived definitions; ceiling is {maximum}")

    main_text = entrypoint.read_text(encoding="utf-8")
    for number, line in enumerate(main_text.splitlines(), 1):
        if EMITTING.match(line):
            errors.append(f"{policy['entrypoint']}:{number}: entrypoint must not emit bytes")
    actual_modules = [
        match.group(1).replace("\\", "/")
        for line in main_text.splitlines()
        if (match := INCLUDE.match(line)) and match.group(1).endswith(".s")
    ]
    expected_modules = [entry["file"] for entry in layout["modules"]]
    if actual_modules != expected_modules:
        errors.append("entrypoint module order differs from config/rom_layout.json")
    for included in [match.group(1) for line in main_text.splitlines() if (match := INCLUDE.match(line))]:
        if not (project_root / included).is_file():
            errors.append(f"{policy['entrypoint']}: missing include {included}")

    return Inventory(definitions, provenance, address_derived, errors, len(call_targets))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--policy", default="config/source_policy.json")
    args = parser.parse_args()
    project_root = Path.cwd()
    policy = json.loads((project_root / args.policy).read_text(encoding="utf-8"))
    if policy.get("schema_version") != 1:
        print("[ERROR] unsupported source policy schema", file=sys.stderr)
        return 1
    inventory = scan(policy, project_root)
    if inventory.errors:
        for error in inventory.errors[:100]:
            print(f"[ERROR] {error}", file=sys.stderr)
        if len(inventory.errors) > 100:
            print(f"[ERROR] ... and {len(inventory.errors) - 100} more", file=sys.stderr)
        return 1
    print(
        f"[OK] source policy: {len(inventory.definitions)} definitions, "
        f"{len(inventory.provenance)} provenance mappings, "
        f"{len(inventory.address_derived)} address-derived unknowns, "
        f"{len(policy['naming']['subsystem_vocabulary'])} declared subsystems, "
        f"{inventory.call_targets} resolved branch targets"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
