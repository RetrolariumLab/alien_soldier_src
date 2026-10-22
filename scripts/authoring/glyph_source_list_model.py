#!/usr/bin/env python3
"""Model fixed word-packed glyph source lists used by UI sequences."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import source_owners  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402
from authoring.text_document_contract import record_names, source_value_matches  # noqa: E402


SCHEMA_VERSION = 1
PROFILES = ("jp", "eu")
END_LIST = 0xFF
FONT_PATH = Path("data/artunc/font.bin")
GLYPH_BYTES = 64
NAMES = (
    "StageIntro_GlyphSourceList",
    "BattleBanner_GlyphSourceList",
    "Results_TimeBonusGlyphSourceList",
    "StageIntro_EmergencyGlyphSourceList",
)
LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
WORD_LINE = re.compile(
    r"^(?P<prefix>(?:[A-Za-z_][A-Za-z0-9_]*:\s*)?\s*dc\.w\s+)"
    r"(?P<body>[^;]+?)(?P<suffix>\s*(?:;.*)?)$"
)


def font_glyph_count(root: Path) -> int:
    size = (root / FONT_PATH).stat().st_size
    if size == 0 or size % GLYPH_BYTES:
        raise ValueError("shared font size is not a whole number of glyphs")
    return size // GLYPH_BYTES


def words_to_bytes(words: tuple[int, ...]) -> bytes:
    output = bytearray()
    for value in words:
        output.extend((value & 0xFFFF).to_bytes(2, "big"))
    return bytes(output)


def bytes_to_words(body: bytes) -> tuple[int, ...]:
    if len(body) % 2:
        raise ValueError("word-packed glyph list has an odd byte count")
    return tuple(int.from_bytes(body[offset : offset + 2], "big") for offset in range(0, len(body), 2))


def parse_list(words: tuple[int, ...], name: str, glyph_limit: int) -> dict[str, Any]:
    body = words_to_bytes(words)
    try:
        end = body.index(END_LIST)
    except ValueError as error:
        raise ValueError("%s has no $FF terminator" % name) from error
    glyphs = list(body[:end])
    if any(value >= glyph_limit for value in glyphs):
        raise ValueError("%s selects a glyph outside the shared font" % name)
    return {
        "word_capacity": len(words),
        "encoded_byte_count": len(body),
        "glyph_count": len(glyphs),
        "padding": list(body[end + 1 :]),
        "glyphs": glyphs,
    }


def export_document(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown glyph-source profile: %s" % profile)
    data, _bodies = labelled_blocks(root)
    owners = source_owners(root)
    glyph_limit = font_glyph_count(root)
    lists = []
    for name in NAMES:
        words = data.get(name)
        if not isinstance(words, tuple):
            raise ValueError("glyph source list is missing: %s" % name)
        record = parse_list(words, name, glyph_limit)
        record.update({"name": name, "path": owners[name], "storage": "source"})
        lists.append(record)
    return {
        "schema_version": SCHEMA_VERSION,
        "profile": profile,
        "format": "word-packed-ff-glyph-source-lists",
        "font_path": FONT_PATH.as_posix(),
        "font_glyph_count": glyph_limit,
        "list_count": len(lists),
        "glyph_count": sum(item["glyph_count"] for item in lists),
        "encoded_byte_count": sum(item["encoded_byte_count"] for item in lists),
        "lists": lists,
    }


def load_document(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load glyph-source document %s: %s" % (path, error)) from error
    if not isinstance(document, dict):
        raise ValueError("glyph-source document is not an object")
    return document


def atomic_write_json(path: Path, document: dict[str, Any]) -> None:
    from authoring.atomic_output import atomic_write_json as _write_json

    _write_json(path, document, ensure_ascii=True)


def encode_list(record: dict[str, Any]) -> tuple[int, ...]:
    body = bytes(record["glyphs"] + [END_LIST] + record["padding"])
    return bytes_to_words(body)


def parse_word(token: str) -> int:
    token = token.strip()
    return int(token[1:], 16) if token.startswith("$") else int(token)


def format_word(value: int) -> str:
    return str(value) if value < 10 else "$%X" % value


def rewrite_word_body(body: str, values: tuple[int, ...]) -> str:
    tokens = body.split(",")
    if len(tokens) != len(values):
        raise ValueError("glyph-source word count changed while rebuilding")
    rendered = []
    for token, value in zip(tokens, values):
        match = re.match(r"^(\s*)(.*?)(\s*)$", token)
        assert match is not None
        original = match.group(2)
        replacement = original if parse_word(original) == value else format_word(value)
        rendered.append(match.group(1) + replacement + match.group(3))
    return ",".join(rendered)


def rebuild_source(root: Path, source_path: str, payloads: dict[str, tuple[int, ...]]) -> str:
    path = root / source_path
    lines = path.read_text(encoding="utf-8").split("\n")
    locations: dict[str, list[tuple[int, re.Match[str]]]] = {}
    current = None
    for index, line in enumerate(lines):
        label = LABEL.match(line)
        if label is not None:
            current = label.group(1)
        match = WORD_LINE.match(line)
        if match is not None and current in payloads:
            locations.setdefault(current, []).append((index, match))
    missing = sorted(set(payloads) - set(locations))
    if missing:
        raise ValueError("cannot locate glyph source lists: %s" % ", ".join(missing))
    output = list(lines)
    for name, spans in locations.items():
        desired = payloads[name]
        cursor = 0
        for line_index, match in spans:
            count = len(match.group("body").split(","))
            values = desired[cursor : cursor + count]
            if len(values) != count:
                raise ValueError("%s source exceeds its fixed word slot" % name)
            body = rewrite_word_body(match.group("body"), values)
            output[line_index] = match.group("prefix") + body + match.group("suffix")
            cursor += count
        if cursor != len(desired):
            raise ValueError("%s encoded word count differs" % name)
    return "\n".join(output)


def document_errors(document: dict[str, Any], root: Path, profile: str) -> list[str]:
    baseline = export_document(root, profile)
    errors = []
    for field in (
        "schema_version",
        "profile",
        "format",
        "font_path",
        "font_glyph_count",
        "list_count",
        "glyph_count",
        "encoded_byte_count",
    ):
        if not source_value_matches(document.get(field), baseline[field]):
            errors.append("%s differs from the source-owned value" % field)
    lists = document.get("lists")
    if not isinstance(lists, list):
        return errors + ["lists is not a list"]
    originals = {item["name"]: item for item in baseline["lists"]}
    names = record_names(lists)
    if len(names) != len(lists) or len(set(names)) != len(names):
        errors.append("list names are missing or not unique")
    if set(names) != set(originals):
        errors.append("list inventory differs from the source")
    for record in lists:
        if not isinstance(record, dict) or not isinstance(record.get("name"), str):
            continue
        name = record.get("name", "<missing>")
        original = originals.get(name)
        if original is None:
            continue
        for field in (
            "path",
            "storage",
            "word_capacity",
            "encoded_byte_count",
            "glyph_count",
            "padding",
        ):
            if not source_value_matches(record.get(field), original[field]):
                errors.append("%s: %s differs" % (name, field))
        glyphs = record.get("glyphs")
        if not isinstance(glyphs, list) or len(glyphs) != original["glyph_count"]:
            errors.append("%s: glyph capacity differs" % name)
            continue
        if any(
            not isinstance(value, int) or isinstance(value, bool) or not 0 <= value < baseline["font_glyph_count"]
            for value in glyphs
        ):
            errors.append("%s: invalid glyph index" % name)
        try:
            if len(encode_list(record)) != original["word_capacity"]:
                errors.append("%s: encoded word count differs" % name)
        except (KeyError, TypeError, ValueError):
            pass
    return errors


def validate_document(document: dict[str, Any], root: Path, profile: str) -> None:
    errors = document_errors(document, root, profile)
    if errors:
        raise ValueError("; ".join(errors))


def apply_document(
    document: dict[str, Any],
    root: Path,
    profile: str,
    write: bool = True,
    validation_root: Path | None = None,
) -> list[str]:
    validate_document(document, validation_root or root, profile)
    data, _bodies = labelled_blocks(root)
    changes: dict[str, dict[str, tuple[int, ...]]] = {}
    for record in document["lists"]:
        words = encode_list(record)
        if words != data[record["name"]]:
            changes.setdefault(record["path"], {})[record["name"]] = words
    for relative, payloads in changes.items():
        if write:
            path = root / relative
            rebuilt = rebuild_source(root, relative, payloads)
            from authoring.atomic_output import atomic_write_text as _write_text

            _write_text(path, rebuilt)
    return sorted(changes)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "export", "validate"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=PROFILES, default="jp")
    parser.add_argument("--document")
    parser.add_argument("--output")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        if args.command == "check":
            document = export_document(root, args.profile)
            validate_document(document, root, args.profile)
            if apply_document(document, root, args.profile, write=False):
                raise ValueError("zero-edit glyph source lists would change files")
            print(
                "[OK] %s glyph source lists: %d lists, %d glyph slots"
                % (args.profile, document["list_count"], document["glyph_count"])
            )
        elif args.command == "export":
            atomic_write_json(Path(args.output), export_document(root, args.profile))
        else:
            validate_document(load_document(Path(args.document)), root, args.profile)
        return 0
    except (KeyError, OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
