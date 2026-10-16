#!/usr/bin/env python3
"""Display-free editing state for Graphics Studio palette commands."""

from __future__ import annotations

from dataclasses import dataclass


CRAM_UNUSED_BITS = 0xF111
CHANNEL_MAX = 7


def channel_levels(word: int) -> tuple[int, int, int]:
    """Return red, green, and blue hardware levels from a raw CRAM word."""
    if isinstance(word, bool) or not isinstance(word, int) or not 0 <= word <= 0xFFFF:
        raise ValueError("palette word must be an unsigned 16-bit value")
    return (word >> 1) & 7, (word >> 5) & 7, (word >> 9) & 7


def replace_channels(word: int, red: int, green: int, blue: int) -> int:
    """Change visible channels while preserving the cartridge's ignored bits."""
    channel_levels(word)
    if any(
        isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= CHANNEL_MAX
        for value in (red, green, blue)
    ):
        raise ValueError("palette channels must be integers from 0 through 7")
    return (word & CRAM_UNUSED_BITS) | (blue << 9) | (green << 5) | (red << 1)


@dataclass
class PaletteWorkspace:
    document: dict
    command_index: int = 0
    colour_index: int = 0
    dirty: bool = False

    @property
    def commands(self) -> list[dict]:
        return self.document["commands"]

    @property
    def command(self) -> dict:
        return self.commands[self.command_index]

    @property
    def colours(self) -> list[int]:
        return self.command["colours"]

    @property
    def word(self) -> int:
        return self.colours[self.colour_index]

    @property
    def channels(self) -> tuple[int, int, int]:
        return channel_levels(self.word)

    def select_command(self, index: int) -> None:
        if not 0 <= index < len(self.commands):
            raise ValueError("palette command index is outside the document")
        self.command_index = index
        self.colour_index = 0

    def select_colour(self, index: int) -> None:
        if not 0 <= index < len(self.colours):
            raise ValueError("colour index is outside the palette command")
        self.colour_index = index

    def set_word(self, word: int) -> None:
        channel_levels(word)
        if self.word == word:
            return
        self.colours[self.colour_index] = word
        self.dirty = True

    def set_channels(self, red: int, green: int, blue: int) -> None:
        self.set_word(replace_channels(self.word, red, green, blue))
