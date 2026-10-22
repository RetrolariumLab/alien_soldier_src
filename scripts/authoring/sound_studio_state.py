#!/usr/bin/env python3
"""Headless selection and fixed-capacity editing state for Sound Studio."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from authoring.sound_semantic_model import (
    FM_REGISTERS,
    OPERATOR_REGISTER_OFFSETS,
    describe_event,
    event_controls,
    fm_controls,
)


@dataclass
class Value:
    """One editable integer stored directly or inside a byte-hex string."""

    container: dict[str, Any]
    key: str
    index: int | None
    minimum: int
    maximum: int

    def get(self) -> int:
        stored = self.container[self.key]
        if self.index is None:
            return stored
        if isinstance(stored, str):
            start = self.index * 2
            return int(stored[start : start + 2], 16)
        return stored[self.index]

    def set(self, value: int) -> None:
        if not isinstance(value, int) or isinstance(value, bool):
            raise ValueError("sound value must be an integer")
        if not self.minimum <= value <= self.maximum:
            raise ValueError("sound value must be between %d and %d" % (self.minimum, self.maximum))
        stored = self.container[self.key]
        if self.index is None:
            self.container[self.key] = value
        elif isinstance(stored, str):
            start = self.index * 2
            self.container[self.key] = stored[:start] + "%02X" % value + stored[start + 2 :]
        else:
            stored[self.index] = value


@dataclass
class Field:
    artifact: str
    label: str
    values: list[Value]
    representation: str = "byte"
    payload: dict[str, Any] | None = None

    @property
    def length(self) -> int:
        return len(self.values)

    def value(self, index: int) -> int:
        if not 0 <= index < self.length:
            raise ValueError("value index is outside the selected sound field")
        return self.values[index].get()

    def set_value(self, index: int, value: int) -> None:
        if not 0 <= index < self.length:
            raise ValueError("value index is outside the selected sound field")
        self.values[index].set(value)

    def bounds(self, index: int) -> tuple[int, int]:
        if not 0 <= index < self.length:
            raise ValueError("value index is outside the selected sound field")
        value = self.values[index]
        return value.minimum, value.maximum


def _ref(
    container: dict[str, Any],
    key: str,
    index: int | None = None,
    minimum: int = 0,
    maximum: int = 0xFF,
) -> Value:
    return Value(container, key, index, minimum, maximum)


def _sequence_fields(identifier: str, document: dict[str, Any]) -> list[Field]:
    fields = []
    for payload in document["payloads"]:
        values = []
        for instruction in payload["instructions"]:
            kind = instruction["kind"]
            data = instruction["data"]
            if kind == "duration":
                values.append(_ref(instruction, "data", 0, 0, 0x7F))
            elif kind == "note":
                values.append(_ref(instruction, "data", 0, 0x80, 0xDF))
                if len(data) == 2:
                    values.append(_ref(instruction, "data", 1, 0, 0x7F))
            elif instruction.get("opcode") == 0xFF:
                values.extend(_ref(instruction, "data", index) for index in range(2, len(data)))
            elif instruction.get("opcode") not in (0xF6, 0xF7, 0xF8):
                start = 2 if instruction.get("opcode") == 0xE4 else 1
                values.extend(_ref(instruction, "data", index) for index in range(start, len(data)))
        if values:
            fields.append(
                Field(
                    identifier,
                    "%s / %s / reachable event values" % (payload["family"], payload["name"]),
                    values,
                    payload=payload,
                )
            )
    return fields


def _instrument_fields(identifier: str, document: dict[str, Any]) -> list[Field]:
    fields = []
    register_groups = (
        "detune_multiplier",
        "rate_scale_attack",
        "am_decay",
        "sustain_rate",
        "sustain_level_release",
        "total_level",
    )
    for payload in document["payloads"]:
        for instrument in payload["instruments"]:
            values = [_ref(instrument, "algorithm_feedback")]
            for group in register_groups:
                values.extend(_ref(instrument, group, index) for index in range(4))
            fields.append(
                Field(
                    identifier,
                    "%s / instrument %d / YM2612 register bytes" % (payload["name"], instrument["index"]),
                    values,
                    payload=payload,
                )
            )
    return fields


def _envelope_fields(identifier: str, document: dict[str, Any]) -> list[Field]:
    fields = []
    for family in document["families"]:
        for block in family["blocks"]:
            values = [_ref(record, "value", minimum=-128, maximum=127) for record in block["values"]]
            if values:
                fields.append(
                    Field(
                        identifier,
                        "%s / %s / signed values" % (family["id"], block["name"]),
                        values,
                        representation="signed",
                    )
                )
    return fields


def _pcm_fields(identifier: str, document: dict[str, Any]) -> list[Field]:
    fields = []
    for bank in document["banks"]:
        for sample in bank["samples"]:
            values = [_ref(sample, "data", index) for index in range(sample["byte_count"])]
            fields.append(
                Field(
                    identifier,
                    "%s / sample %d / encoded DPCM bytes" % (bank["name"], sample["index"]),
                    values,
                    representation="dpcm",
                )
            )
    return fields


def fields_for_document(identifier: str, document: dict[str, Any]) -> list[Field]:
    if identifier == "sound_sequences":
        fields = _sequence_fields(identifier, document)
    elif identifier == "sound_instruments":
        fields = _instrument_fields(identifier, document)
    elif identifier == "sound_envelopes":
        fields = _envelope_fields(identifier, document)
    elif identifier == "sound_pcm_samples":
        fields = _pcm_fields(identifier, document)
    else:
        raise ValueError("unsupported Sound Studio artifact: %s" % identifier)
    if not fields or any(field.length == 0 for field in fields):
        raise ValueError("Sound Studio artifact has no editable fields: %s" % identifier)
    return fields


class Workspace:
    def __init__(self, documents: dict[str, dict[str, Any]]):
        if not documents:
            raise ValueError("Sound Studio has no documents")
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
    def bounds(self) -> tuple[int, int]:
        return self.field.bounds(self.value_index)

    def select_artifact(self, value: int | str) -> None:
        if isinstance(value, str):
            if value not in self.artifact_ids:
                raise ValueError("unknown Sound Studio artifact: %s" % value)
            value = self.artifact_ids.index(value)
        if not isinstance(value, int) or not 0 <= value < len(self.artifact_ids):
            raise ValueError("artifact index is outside Sound Studio")
        self.artifact_index = value
        self.field_index = 0
        self.value_index = 0

    def select_field(self, index: int) -> None:
        if not isinstance(index, int) or not 0 <= index < len(self.artifact_fields):
            raise ValueError("field index is outside the selected sound artifact")
        self.field_index = index
        self.value_index = 0

    def select_value(self, index: int) -> None:
        if not isinstance(index, int) or not 0 <= index < self.field.length:
            raise ValueError("value index is outside the selected sound field")
        self.value_index = index

    def set_value(self, value: int) -> None:
        if value == self.value:
            return
        self.field.set_value(self.value_index, value)
        self.dirty.add(self.artifact_id)

    def visible_values(self, radius: int = 16) -> tuple[int, list[int]]:
        start = max(0, self.value_index - radius)
        end = min(self.field.length, self.value_index + radius + 1)
        return start, [self.field.value(index) for index in range(start, end)]

    def semantic_context(self, owners=(), sample_ids=None):
        ref = self.field.values[self.value_index]
        if self.artifact_id == "sound_sequences":
            controls = event_controls(ref.container, ref.index, owners, sample_ids)
            return describe_event(ref.container, owners), controls
        if self.artifact_id == "sound_instruments":
            register = FM_REGISTERS[ref.key]
            operator = "channel"
            if ref.index is not None:
                register += OPERATOR_REGISTER_OFFSETS[ref.index]
                operator = "source operator slot %d" % ref.index
            return (
                "%s / relative YM2612 register $%02X / raw $%02X\n"
                "Subfield edits preserve all other bits; no waveform claim" % (operator, register, ref.get()),
                fm_controls(ref.key),
            )
        return "", ()

    def set_semantic(self, control, value, validate=None, *, owners=(), sample_ids=None):
        _description, allowed_controls = self.semantic_context(owners, sample_ids)
        if control not in allowed_controls:
            raise ValueError("semantic control does not belong to the selected operand")
        original = self.value
        dirty_before = set(self.dirty)
        candidate = control.replace(original, value)
        try:
            self.set_value(candidate)
            if validate is not None:
                validate(self.documents[self.artifact_id])
        except Exception:
            self.field.set_value(self.value_index, original)
            self.dirty = dirty_before
            raise
