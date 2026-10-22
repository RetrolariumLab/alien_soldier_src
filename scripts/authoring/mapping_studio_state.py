#!/usr/bin/env python3
"""Display-free editing state for Graphics Studio sprite mappings."""

from __future__ import annotations

from dataclasses import dataclass


LAST_PIECE = 0x8000
TILE_INDEX_MASK = 0x07FF


def piece_dimensions(piece: dict) -> tuple[int, int]:
    size = piece["size"]
    return ((((size >> 2) & 3) + 1) * 8, ((size & 3) + 1) * 8)


@dataclass
class MappingWorkspace:
    document: dict
    mapping_index: int = 0
    piece_index: int = 0
    dirty: bool = False

    def __post_init__(self) -> None:
        self.entries = [(block, mapping) for block in self.document["blocks"] for mapping in block["mappings"]]

    @property
    def block(self) -> dict:
        return self.entries[self.mapping_index][0]

    @property
    def mapping(self) -> dict:
        return self.entries[self.mapping_index][1]

    @property
    def pieces(self) -> list[dict]:
        return self.mapping["pieces"]

    @property
    def piece(self) -> dict:
        return self.pieces[self.piece_index]

    def select_mapping(self, index: int) -> None:
        if not 0 <= index < len(self.entries):
            raise ValueError("mapping index is outside the document")
        self.mapping_index = index
        self.piece_index = 0

    def select_piece(self, index: int) -> None:
        if not 0 <= index < len(self.pieces):
            raise ValueError("piece index is outside the mapping")
        self.piece_index = index

    def set_piece(self, *, x: int, y: int, attributes: int, size: int, link: int) -> None:
        if any(
            isinstance(value, bool) or not isinstance(value, int)
            for value in (
                x,
                y,
                attributes,
                size,
                link,
            )
        ):
            raise ValueError("piece fields must be integers")
        if not -128 <= x <= 127 or not -128 <= y <= 127:
            raise ValueError("piece coordinates must be signed bytes")
        if not 0 <= attributes <= 0xFFFF:
            raise ValueError("piece attributes must be an unsigned word")
        if not 0 <= size <= 0xFF or not 0 <= link <= 0xFF:
            raise ValueError("piece size and link must be unsigned bytes")
        current = self.piece
        if bool(attributes & LAST_PIECE) != bool(current["attributes"] & LAST_PIECE):
            raise ValueError("the mapping terminator bit is source-owned")
        if self.mapping["dynamic"]:
            if attributes & TILE_INDEX_MASK != current["attributes"] & TILE_INDEX_MASK:
                raise ValueError("a dynamic piece's upload tile offset is source-owned")
            if size != current["size"] or link != current["link"]:
                raise ValueError("a dynamic piece's art size and link are source-owned")
        changes = {
            "x": x,
            "y": y,
            "attributes": attributes,
            "size": size,
            "link": link,
        }
        if all(current[field] == value for field, value in changes.items()):
            return
        current.update(changes)
        self.dirty = True

    def geometry(self) -> list[tuple[int, int, int, int]]:
        return [(piece["x"], piece["y"], *piece_dimensions(piece)) for piece in self.pieces]
