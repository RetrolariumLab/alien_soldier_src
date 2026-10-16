#!/usr/bin/env python3
"""Display-free editing state for the Graphics Studio tile workstation."""

from __future__ import annotations

from dataclasses import dataclass


TILE_SIDE = 8
PALETTE_INDICES = 16


def payload_tile_count(record: dict) -> int:
    return sum(len(block["tiles"]) for block in record["blocks"])


def tile_location(record: dict, tile_index: int) -> tuple[int, int]:
    if tile_index < 0:
        raise ValueError("tile index may not be negative")
    remaining = tile_index
    for block_index, block in enumerate(record["blocks"]):
        if remaining < len(block["tiles"]):
            return block_index, remaining
        remaining -= len(block["tiles"])
    raise ValueError("tile %d is outside %s" % (tile_index, record["name"]))


@dataclass
class Workspace:
    document: dict
    payload_index: int = 0
    tile_index: int = 0
    colour: int = 1
    dirty: bool = False

    @property
    def payloads(self):
        return self.document["payloads"]

    @property
    def payload(self):
        return self.payloads[self.payload_index]

    @property
    def tile_count(self):
        return payload_tile_count(self.payload)

    def select_payload(self, index: int) -> None:
        if not 0 <= index < len(self.payloads):
            raise ValueError("payload index is outside the document")
        self.payload_index = index
        self.tile_index = 0

    def select_tile(self, index: int) -> None:
        tile_location(self.payload, index)
        self.tile_index = index

    def tile_text(self) -> str:
        block, tile = tile_location(self.payload, self.tile_index)
        return self.payload["blocks"][block]["tiles"][tile]

    def pixels(self) -> list[int]:
        return [int(pixel, 16) for pixel in self.tile_text()]

    def select_colour(self, value: int) -> None:
        if not 0 <= value < PALETTE_INDICES:
            raise ValueError("colour index must be 0..15")
        self.colour = value

    def set_pixel(self, x: int, y: int, value: int | None = None) -> None:
        if not 0 <= x < TILE_SIDE or not 0 <= y < TILE_SIDE:
            raise ValueError("pixel coordinate must be inside an 8x8 tile")
        colour = self.colour if value is None else value
        if not 0 <= colour < PALETTE_INDICES:
            raise ValueError("colour index must be 0..15")
        pixels = list(self.tile_text())
        offset = y * TILE_SIDE + x
        replacement = "%X" % colour
        if pixels[offset] == replacement:
            return
        pixels[offset] = replacement
        block, tile = tile_location(self.payload, self.tile_index)
        self.payload["blocks"][block]["tiles"][tile] = "".join(pixels)
        self.dirty = True
