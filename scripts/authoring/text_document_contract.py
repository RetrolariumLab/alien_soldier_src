"""Type-exact checks for source-owned JSON text metadata."""

from __future__ import annotations

from typing import Any


def source_value_matches(value: Any, source: Any) -> bool:
    """Keep counts, offsets and boundaries intact, including their JSON types."""
    if type(value) is not type(source):
        return False
    if isinstance(source, dict):
        return value.keys() == source.keys() and all(
            source_value_matches(value[key], item) for key, item in source.items())
    if isinstance(source, list):
        return len(value) == len(source) and all(
            source_value_matches(item, original)
            for item, original in zip(value, source))
    return value == source


def record_names(records: list[Any]) -> list[str]:
    """Only strings participate in a named inventory; malformed records stay out."""
    return [record["name"] for record in records
            if isinstance(record, dict) and isinstance(record.get("name"), str)]
