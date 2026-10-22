#!/usr/bin/env python3
"""Headless selection and editing state for Text Studio."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from authoring.credits_text_model import lower_delay_maximum
from authoring.shared_font_preview import SOURCE_FONT_GLYPH_COUNT
from authoring.text_glyph_picker import GlyphRange


@dataclass
class Field:
    artifact: str
    label: str
    container: dict[str, Any]
    key: str
    minimum: int
    maximum: int
    visible_length: int | None = None
    protected_indices: frozenset[int] = frozenset()

    @property
    def scalar(self) -> bool:
        return not isinstance(self.container[self.key], list)

    @property
    def length(self) -> int:
        if self.scalar:
            return 1
        values = self.container[self.key]
        return self.visible_length if self.visible_length is not None else len(values)

    def value(self, index: int) -> int:
        if not 0 <= index < self.length:
            raise ValueError("value index is outside the selected field")
        return self.container[self.key] if self.scalar else self.container[self.key][index]

    def set_value(self, index: int, value: int) -> None:
        if index in self.protected_indices:
            raise ValueError("text value is a protected $FF boundary")
        if not isinstance(value, int) or isinstance(value, bool):
            raise ValueError("text value must be an integer")
        if not self.minimum <= value <= self.maximum:
            raise ValueError("text value must be between %d and %d" % (self.minimum, self.maximum))
        if not 0 <= index < self.length:
            raise ValueError("value index is outside the selected field")
        if self.scalar:
            self.container[self.key] = value
        else:
            self.container[self.key][index] = value


def fields_for_document(identifier: str, document: dict[str, Any]) -> list[Field]:
    fields = []
    if identifier == "story_text_rows":
        for row in document["rows"]:
            for key in ("primary", "accent"):
                protected = frozenset(index for index, value in enumerate(row[key][:-1]) if value == 0xFF)
                fields.append(
                    Field(
                        identifier,
                        "row %03d / %s" % (row["index"], key),
                        row,
                        key,
                        0,
                        SOURCE_FONT_GLYPH_COUNT - 1,
                        visible_length=len(row[key]) - 1,
                        protected_indices=protected,
                    )
                )
    elif identifier == "frontend_text_strings":
        for record in document["strings"]:
            fields.append(
                Field(
                    identifier,
                    record["name"],
                    record,
                    "glyphs",
                    0,
                    SOURCE_FONT_GLYPH_COUNT - 1,
                )
            )
    elif identifier == "results_detail_text":
        for row in document["rows"]:
            fields.append(
                Field(
                    identifier,
                    "results detail / row %02d" % row["index"],
                    row,
                    "glyphs",
                    0,
                    document["max_glyph_id"],
                )
            )
        for record in document["summary_labels"]:
            fields.append(
                Field(
                    identifier,
                    "results summary / " + record["name"],
                    record,
                    "glyphs",
                    0,
                    document["max_glyph_id"],
                )
            )
    elif identifier == "stage_message_sequences":
        for stream in document["streams"]:
            for sequence_index, sequence in enumerate(stream["sequences"]):
                for entry_index, entry in enumerate(sequence):
                    fields.append(
                        Field(
                            identifier,
                            "%s / sequence %d / entry %d / row %d"
                            % (stream["name"], sequence_index, entry_index, entry["row"]),
                            entry,
                            "glyphs",
                            0,
                            SOURCE_FONT_GLYPH_COUNT - 1,
                        )
                    )
    elif identifier == "boss_and_ship_message_scripts":
        maximum = document["font_glyph_count"] - 1
        for script in document["scripts"]:
            for index, record in enumerate(script["records"]):
                fields.append(
                    Field(
                        identifier,
                        "%s / record %d" % (script["name"], index),
                        record,
                        "glyphs",
                        0,
                        maximum,
                    )
                )
    elif identifier == "credits_text_sequence":
        maximum = document["max_glyph_id"]
        for index, record in enumerate(document["records"]):
            prefix = "record %02d" % index
            fields.append(
                Field(
                    identifier,
                    prefix + " / upper delay",
                    record,
                    "upper_delay",
                    0,
                    0x7F,
                )
            )
            if record["upper_glyphs"]:
                fields.append(
                    Field(
                        identifier,
                        prefix + " / upper glyphs",
                        record,
                        "upper_glyphs",
                        0,
                        maximum,
                    )
                )
            fields.append(
                Field(
                    identifier,
                    prefix + " / lower delay",
                    record,
                    "lower_delay",
                    0,
                    lower_delay_maximum(record["lower_count"]),
                )
            )
            if record["lower_glyphs"]:
                fields.append(
                    Field(
                        identifier,
                        prefix + " / lower glyphs",
                        record,
                        "lower_glyphs",
                        0,
                        maximum,
                    )
                )
    elif identifier == "glyph_source_lists":
        maximum = document["font_glyph_count"] - 1
        for record in document["lists"]:
            fields.append(
                Field(
                    identifier,
                    record["name"],
                    record,
                    "glyphs",
                    0,
                    maximum,
                )
            )
    elif identifier == "japanese_glyph_sequence":
        fields.append(
            Field(
                identifier,
                "story glyph stream",
                document,
                "codes",
                document["first_code"],
                document["first_code"] + document["art_glyph_count"] - 1,
            )
        )
    else:
        raise ValueError("unsupported Text Studio artifact: %s" % identifier)
    if not fields or any(field.length == 0 for field in fields):
        raise ValueError("Text Studio artifact has no editable fields: %s" % identifier)
    return fields


class Workspace:
    def __init__(self, documents: dict[str, dict[str, Any]]):
        if not documents:
            raise ValueError("Text Studio has no documents")
        self.documents = documents
        self.artifact_ids = list(documents)
        self.fields = {
            identifier: fields_for_document(identifier, document) for identifier, document in documents.items()
        }
        self.artifact_index = 0
        self.field_index = 0
        self.value_index = 0
        self.dirty: set[str] = set()

    @property
    def artifact_id(self) -> str:
        return self.artifact_ids[self.artifact_index]

    @property
    def artifact_fields(self) -> list[Field]:
        return self.fields[self.artifact_id]

    @property
    def field(self) -> Field:
        return self.artifact_fields[self.field_index]

    @property
    def value(self) -> int:
        return self.field.value(self.value_index)

    @property
    def glyph_range(self) -> GlyphRange | None:
        field = self.field
        if field.scalar or self.value_index in field.protected_indices:
            return None
        family = {
            "japanese_glyph_sequence": "japanese",
            "credits_text_sequence": "credits",
        }.get(self.artifact_id, "shared")
        return GlyphRange(family, field.minimum, field.maximum)

    @property
    def font_family(self) -> str | None:
        """A whole glyph field stays text-editable even on a protected slot."""
        if self.field.scalar:
            return None
        return {"japanese_glyph_sequence": "japanese", "credits_text_sequence": "credits"}.get(
            self.artifact_id, "shared"
        )

    def field_text(self, character_map) -> str:
        if self.font_family is None:
            raise ValueError("timing fields are not glyph text")
        self._check_character_map_profile(character_map)
        protected = {index: self.field.value(index) for index in self.field.protected_indices}
        return character_map.decode(self.values(), self.font_family, protected=protected)

    def set_text(self, text: str, character_map, validate=None) -> None:
        """Replace a fixed field and restore every byte/dirty flag on failure."""
        family = self.font_family
        if family is None:
            raise ValueError("timing fields are not glyph text")
        self._check_character_map_profile(character_map)
        field = self.field
        protected = {index: field.value(index) for index in field.protected_indices}
        values = character_map.encode(text, family, length=field.length, protected=protected)
        if values == self.values():
            if validate is not None:
                validate(self.documents[self.artifact_id])
            return
        original = list(field.container[field.key])
        dirty_before = set(self.dirty)
        try:
            for index, value in enumerate(values):
                if index not in protected:
                    field.set_value(index, value)
            if validate is not None:
                validate(self.documents[self.artifact_id])
            self.dirty.add(self.artifact_id)
        except Exception:
            field.container[field.key][:] = original
            self.dirty = dirty_before
            raise

    def _check_character_map_profile(self, character_map):
        profile = self.documents[self.artifact_id].get("profile")
        if profile is not None and character_map.profile != profile:
            raise ValueError("character-map profile differs from the selected text document")

    def select_artifact(self, value: int | str) -> None:
        if isinstance(value, str):
            if value not in self.artifact_ids:
                raise ValueError("unknown Text Studio artifact: %s" % value)
            value = self.artifact_ids.index(value)
        if not isinstance(value, int) or not 0 <= value < len(self.artifact_ids):
            raise ValueError("artifact index is outside Text Studio")
        self.artifact_index = value
        self.field_index = 0
        self.value_index = 0

    def select_field(self, index: int) -> None:
        if not isinstance(index, int) or not 0 <= index < len(self.artifact_fields):
            raise ValueError("field index is outside the selected artifact")
        self.field_index = index
        self.value_index = 0

    def select_value(self, index: int) -> None:
        if not isinstance(index, int) or not 0 <= index < self.field.length:
            raise ValueError("value index is outside the selected field")
        self.value_index = index

    def set_value(self, value: int) -> None:
        if value == self.value:
            return
        self.field.set_value(self.value_index, value)
        self.dirty.add(self.artifact_id)

    def set_glyph(self, value: int) -> None:
        font_range = self.glyph_range
        if font_range is None:
            raise ValueError("the selected slot is not an editable glyph")
        font_range.page_for(value)
        self.set_value(value)

    def sequence_window(self, limit: int = 32) -> tuple[int, list[int]]:
        if type(limit) is not int or limit < 1:
            raise ValueError("sequence window size must be positive")
        length = self.field.length
        start = max(0, min(self.value_index - limit // 2, length - limit))
        end = min(start + limit, length)
        return start, [self.field.value(index) for index in range(start, end)]

    def values(self) -> list[int]:
        return [self.field.value(index) for index in range(self.field.length)]
