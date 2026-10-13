"""Display-free cell selection and transactional edits for RAM-map studios."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable


def parse_value(text: str, bits: int) -> int:
    text = text.strip()
    if text.startswith("$"):
        value = int(text[1:], 16)
    else:
        value = int(text, 0)
    if not 0 <= value < (1 << bits):
        raise ValueError("value is outside unsigned %d-bit range" % bits)
    return value


@dataclass
class Workspace:
    document: dict
    payload_index: int = 0
    value_index: int = 0
    dirty: bool = False

    @property
    def payloads(self):
        return self.document["payloads"]

    @property
    def payload(self):
        return self.payloads[self.payload_index]

    @property
    def value(self):
        return self.payload["values"][self.value_index]

    def select_payload(self, index: int) -> None:
        if not 0 <= index < len(self.payloads):
            raise ValueError("payload index is outside the RAM-map document")
        self.payload_index = index
        self.value_index = 0

    def select_value(self, index: int) -> None:
        if not 0 <= index < len(self.payload["values"]):
            raise ValueError("value index is outside the selected payload")
        self.value_index = index

    def set_value(self, value: int) -> None:
        maximum = (1 << self.payload["value_bits"]) - 1
        if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= maximum:
            raise ValueError("value must be an unsigned %d-bit integer" % self.payload["value_bits"])
        if value == self.value:
            return
        self.payload["values"][self.value_index] = value
        self.dirty = True

    def replace_value(self, value: int, validate: Callable[[dict], None]) -> None:
        previous = self.value
        was_dirty = self.dirty
        self.set_value(value)
        try:
            validate(self.document)
        except Exception:
            self.payload["values"][self.value_index] = previous
            self.dirty = was_dirty
            raise

    def location(self) -> dict[str, int]:
        width = self.payload["unit_width"]
        height = self.payload["unit_height"]
        per_unit = width * height
        within = self.value_index % per_unit
        return {
            "unit": self.value_index // per_unit,
            "x": within % width,
            "y": within // width,
        }

    @property
    def unit_count(self) -> int:
        per_unit = self.payload["unit_width"] * self.payload["unit_height"]
        return (len(self.payload["values"]) + per_unit - 1) // per_unit

    def unit_values(self, unit: int) -> list[int | None]:
        if not 0 <= unit < self.unit_count:
            raise ValueError("unit index is outside the selected payload")
        per_unit = self.payload["unit_width"] * self.payload["unit_height"]
        first = unit * per_unit
        values = self.payload["values"][first:first + per_unit]
        return values + [None] * (per_unit - len(values))

    def select_cell(self, unit: int, x: int, y: int) -> None:
        width = self.payload["unit_width"]
        height = self.payload["unit_height"]
        if not 0 <= x < width or not 0 <= y < height:
            raise ValueError("cell is outside the selected map unit")
        if not 0 <= unit < self.unit_count:
            raise ValueError("unit index is outside the selected payload")
        self.select_value(unit * width * height + y * width + x)

    def select_pixel(self, unit: int, x: int, y: int, size: int = 256) -> None:
        if size <= 0 or not 0 <= x < size or not 0 <= y < size:
            raise ValueError("pixel is outside the map-unit grid")
        self.select_cell(
            unit,
            x * self.payload["unit_width"] // size,
            y * self.payload["unit_height"] // size,
        )

    def paint_pixel(
        self, unit: int, x: int, y: int, value: int,
        validate: Callable[[dict], None],
    ) -> None:
        selection = (self.payload_index, self.value_index)
        try:
            self.select_pixel(unit, x, y)
            self.replace_value(value, validate)
        except Exception:
            self.payload_index, self.value_index = selection
            raise
