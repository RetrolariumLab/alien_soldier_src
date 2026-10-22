#!/usr/bin/env python3
"""Evidence-bound text transcription with lossless explicit glyph-ID tokens.

No characters are supplied by this module. A human worksheet may supply them;
its exact source-font hashes and evidence are retained in a regional workspace.
Unknown IDs, duplicates and reserved token spellings remain explicit [[$HHH]].
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from copy import deepcopy
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.atomic_output import atomic_write_json  # noqa: E402
from authoring.content_workspace import checked_path  # noqa: E402
from authoring.text_glyph_review import inventory, validate_answers  # noqa: E402


PROFILES = ("jp", "eu")
FAMILIES = ("shared", "japanese", "credits")
WORKSPACE = Path("content/workspace")
RAW_TOKEN = re.compile(r"\[\[\$([0-9A-Fa-f]{1,4})\]\]")


def source_fonts(root: Path) -> dict:
    """Do not infer regional aliases: pin the actual current source art."""
    return {
        name: {field: asset[field] for field in ("first", "count", "sha256")} for name, asset in inventory(root).items()
    }


def map_path(root: Path, profile: str) -> Path:
    if profile not in PROFILES:
        raise ValueError("character-map profile must be jp or eu")
    owner = WORKSPACE / profile
    return checked_path(root, owner / "text/character_map.json", owner)


def empty_document(root: Path, profile: str) -> dict:
    map_path(root, profile)
    fonts = source_fonts(root)
    return {"schema_version": 1, "profile": profile, "source_fonts": fonts, "answers": []}


def validate_document(document: dict, root: Path, profile: str) -> None:
    map_path(root, profile)
    if not isinstance(document, dict) or set(document) != {"schema_version", "profile", "source_fonts", "answers"}:
        raise ValueError("character-map fields differ from the workspace schema")
    if type(document["schema_version"]) is not int or document["schema_version"] != 1:
        raise ValueError("character-map schema is unsupported")
    if document["profile"] != profile:
        raise ValueError("character-map profile differs from the selected workspace")
    fonts = source_fonts(root)
    recorded = document["source_fonts"]
    if not isinstance(recorded, dict) or set(recorded) != set(fonts):
        raise ValueError("character-map source fonts differ")
    for family, expected in fonts.items():
        actual = recorded[family]
        if (
            not isinstance(actual, dict)
            or set(actual) != set(expected)
            or any(type(actual[key]) is not type(value) or actual[key] != value for key, value in expected.items())
        ):
            raise ValueError("character-map source art differs: " + family)
    validate_answers(
        {
            "schema_version": 1,
            "source_hashes": {name: asset["sha256"] for name, asset in fonts.items()},
            "answers": document["answers"],
        },
        fonts,
    )


def from_answers(root: Path, profile: str, answers: dict) -> dict:
    document = empty_document(root, profile)
    if not isinstance(answers, dict) or type(answers.get("schema_version")) is not int:
        raise ValueError("glyph answers have an unsupported schema")
    validate_answers(answers, document["source_fonts"])
    document["answers"] = deepcopy(answers["answers"])
    validate_document(document, root, profile)
    return document


def import_answers(root: Path, profile: str, path: Path, *, replace=False) -> dict:
    """Only replace the regional map after all input/source checks succeed."""
    answers = json.loads(path.read_text(encoding="utf-8"))
    document = from_answers(root, profile, answers)
    destination = map_path(root, profile)
    if destination.exists() and not replace:
        raise ValueError("character map already exists; explicitly approve replacement")
    atomic_write_json(destination, document)
    return document


def load_document(root: Path, profile: str) -> dict:
    path = map_path(root, profile)
    if not path.exists():
        return empty_document(root, profile)
    document = json.loads(path.read_text(encoding="utf-8"))
    validate_document(document, root, profile)
    return document


class CharacterMap:
    """An already validated map, without normalization or implicit aliases."""

    def __init__(self, document: dict):
        if (
            type(document.get("schema_version")) is not int
            or document["schema_version"] != 1
            or document.get("profile") not in PROFILES
        ):
            raise ValueError("character-map schema or profile is unsupported")
        fonts = document.get("source_fonts")
        if not isinstance(fonts, dict) or set(fonts) != set(FAMILIES):
            raise ValueError("character-map source fonts differ")
        for font in fonts.values():
            if (
                not isinstance(font, dict)
                or set(font) != {"first", "count", "sha256"}
                or type(font["first"]) is not int
                or not 0 <= font["first"] <= 0xFFFF
                or type(font["count"]) is not int
                or not 1 <= font["count"] <= 0x10000 - font["first"]
                or not isinstance(font["sha256"], str)
                or re.fullmatch(r"[0-9a-f]{64}", font["sha256"]) is None
            ):
                raise ValueError("character-map source font metadata is invalid")
        validate_answers(
            {
                "schema_version": 1,
                "source_hashes": {name: font["sha256"] for name, font in fonts.items()},
                "answers": document.get("answers"),
            },
            fonts,
        )
        self.profile = document["profile"]
        self.fonts = deepcopy(document["source_fonts"])
        self.labels = {family: {} for family in FAMILIES}
        for answer in document["answers"]:
            text, family, index = answer["transcription"], answer["set"], answer["index"]
            if (
                answer["evidence"] == "unknown_or_unused"
                or not text
                or "[[" in text
                or "]]" in text
                or family == "credits"
                and index == 0
            ):
                continue
            self.labels[family][index] = text
        self.reverse = {family: {} for family in FAMILIES}
        for family, labels in self.labels.items():
            for index, text in labels.items():
                self.reverse[family].setdefault(text, []).append(index)

    def _family(self, family: str) -> dict:
        if family not in self.fonts:
            raise ValueError("character-map font is unknown: " + str(family))
        return self.fonts[family]

    def _plain_ids(self, text: str, family: str) -> list[int]:
        """Unique segmentation, including multi-codepoint human transcriptions.

        Count at most two alternatives at each character boundary. This avoids
        greedy prefix guesses and exponential enumeration of ambiguous runs.
        """
        choices = self.reverse[family]
        starts = {}
        for transcription, ids in choices.items():
            starts.setdefault(transcription[0], []).append((transcription, ids))
        ways = [0] * (len(text) + 1)
        previous = [None] * (len(text) + 1)
        ways[0] = 1
        for at, char in enumerate(text):
            if not ways[at]:
                continue
            for transcription, ids in starts.get(char, ()):
                if not text.startswith(transcription, at):
                    continue
                end = at + len(transcription)
                count = min(2, ways[at] * len(ids))
                if not ways[end] and count == 1:
                    previous[end] = (at, ids[0])
                ways[end] = min(2, ways[end] + count)
        if ways[-1] == 0:
            raise ValueError("text has an unmapped character sequence; use explicit glyph IDs")
        if ways[-1] != 1:
            raise ValueError("text has ambiguous glyph IDs or segmentation; use explicit glyph IDs")
        result, at = [], len(text)
        while at:
            at, glyph = previous[at]
            result.append(glyph)
        return result[::-1]

    def encode(self, text: str, family: str, *, length: int, protected: dict[int, int] | None = None) -> list[int]:
        font = self._family(family)
        if not isinstance(text, str):
            raise ValueError("text must be a string")
        if type(length) is not int or length < 0:
            raise ValueError("text field capacity must be a nonnegative integer")
        protected = protected or {}
        values, at = [], 0
        while at < len(text):
            if text.startswith("[[", at):
                token = RAW_TOKEN.match(text, at)
                if token is None:
                    raise ValueError("invalid explicit glyph token; expected [[$HHH]]")
                values.append(int(token.group(1), 16))
                at = token.end()
                continue
            end = text.find("[[", at)
            end = len(text) if end < 0 else end
            values.extend(self._plain_ids(text[at:end], family))
            at = end
        if len(values) != length:
            raise ValueError("text must retain exactly %d glyph slots; got %d" % (length, len(values)))
        for index, glyph in enumerate(values):
            if index in protected:
                if glyph != protected[index]:
                    raise ValueError("text changes a protected glyph boundary at slot %d" % index)
            elif not font["first"] <= glyph < font["first"] + font["count"]:
                raise ValueError("explicit glyph ID is outside the source font at slot %d" % index)
        return values

    def decode(self, values: list[int], family: str, *, protected: dict[int, int] | None = None) -> str:
        self._family(family)
        protected = protected or {}
        reverse, labels = self.reverse[family], self.labels[family]

        def raw(glyph):
            return "[[$%03X]]" % glyph

        pieces = [
            labels[glyph]
            if index not in protected and glyph in labels and len(reverse[labels[glyph]]) == 1
            else raw(glyph)
            for index, glyph in enumerate(values)
        ]
        text = "".join(pieces)
        try:
            if self.encode(text, family, length=len(values), protected=protected) == values:
                return text
        except ValueError:
            pass
        # Prefix-overlapping transcriptions can make a concatenated run
        # ambiguous even when each individual label has only one ID.
        text = "".join(raw(glyph) for glyph in values)
        self.encode(text, family, length=len(values), protected=protected)
        return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("import", "check"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=PROFILES, default="jp")
    parser.add_argument("--answers", type=Path)
    parser.add_argument("--replace", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        if args.command == "import":
            if args.answers is None:
                raise ValueError("import requires --answers")
            document = import_answers(root, args.profile, args.answers, replace=args.replace)
        else:
            document = load_document(root, args.profile)
        print(
            "[OK] %s character map: %d reviewed records; no inferred transcriptions"
            % (args.profile, len(document["answers"]))
        )
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
