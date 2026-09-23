"""Source-derived plane-B name tables for the Madam Barbar and Joker setups.

Both boss asset sets load SharedBossMappingData2020 to RAM $2020. Their
setup routines then queue different indexed-row descriptors at plane-B row 2.
The bounded initial table here is zero-filled, as observed immediately
before the Madam Barbar transfer. Joker's body renderer subsequently writes
two eight-word rows selected by FrameCounter and its $29C frame offset.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from authoring.indexed_row_transfer import (
    PLANE_COLUMNS, PLANE_ROWS, apply_indexed_rows, descriptor_bytes)
from authoring.stage_tilemap_model import (
    decompress, labelled_blocks, read_asset_lists)


SHARED_MAPPING = "SharedBossMappingData2020"
MAPPING_DESTINATION = 0x2020
MAPPING_LENGTH = 8128
BOSSES = {
    "madam_barbar": (
        "Boss_MadamBarbarGraphicsLoadList",
        "Boss_MadamBarbarTileLoadCommands",
    ),
    "joker": (
        "Boss_JokerGraphicsLoadList",
        "Boss_JokerIndexedRowTransferDescriptor",
    ),
}


@dataclass(frozen=True)
class StageBossSecondaryTable:
    boss: str
    descriptor_name: str
    descriptor: bytes
    mapping: bytes
    rows: tuple[tuple[int, ...], ...]

    def name_words(self) -> bytes:
        return b"".join(word.to_bytes(2, "big")
                        for row in self.rows for word in row)


def _apply_joker_body_frame(
        rows: tuple[tuple[int, ...], ...], data: dict,
        frame_counter: int, secondary_frame_offset: int,
) -> tuple[tuple[int, ...], ...]:
    """Replay Joker's two DMA rows at $6188/$6208 after indexed setup."""
    if not 0 <= frame_counter <= 0xFFFF:
        raise ValueError("Joker frame counter is not a word")
    if secondary_frame_offset not in (0, 4, 8, 12):
        raise ValueError("Joker secondary tile frame offset is unsupported")
    cycling = data.get("Boss_JokerCyclingTileWords")
    secondary = data.get("Boss_JokerSecondaryTileFrameWords")
    if (not isinstance(cycling, tuple) or len(cycling) != 32
            or not isinstance(secondary, tuple) or len(secondary) != 16):
        raise ValueError("Joker tile-frame word tables are missing")
    cycle_at = (frame_counter & 0x1C) // 2
    frame_at = secondary_frame_offset // 2
    first, second = cycling[cycle_at:cycle_at + 2]
    third, fourth = cycling[cycle_at + 16:cycle_at + 18]
    fifth, sixth = secondary[frame_at:frame_at + 2]
    seventh, eighth = secondary[frame_at + 8:frame_at + 10]
    upper = (
        sixth + 0x800, fifth + 0x800,
        second + 0x800, first + 0x800,
        first, second, fifth, sixth,
    )
    lower = (
        eighth + 0x800, seventh + 0x800,
        fourth + 0x800, third + 0x800,
        third, fourth, seventh, eighth,
    )
    updated = [list(row) for row in rows]
    updated[3][4:12] = [word & 0xFFFF for word in upper]
    updated[4][4:12] = [word & 0xFFFF for word in lower]
    return tuple(tuple(row) for row in updated)


def build_boss_secondary_table(
        root: Path, boss: str, *,
        frame_counter: int | None = None,
        secondary_frame_offset: int | None = None,
) -> StageBossSecondaryTable:
    if boss not in BOSSES:
        raise ValueError("unsupported Stage 5/6 boss: %s" % boss)
    if (frame_counter is None) != (secondary_frame_offset is None):
        raise ValueError("Joker tile animation needs both frame inputs")
    if boss != "joker" and frame_counter is not None:
        raise ValueError("only Joker has this tile animation")
    list_name, descriptor_name = BOSSES[boss]
    data, bodies = labelled_blocks(root)
    lists = read_asset_lists(root, bodies)
    if list_name not in lists or not any(
            command.command == 6
            and command.source == SHARED_MAPPING
            and command.destination == MAPPING_DESTINATION
            for command in lists[list_name]):
        raise ValueError("%s does not load the shared mapping to $2020" % list_name)
    source = data.get(SHARED_MAPPING)
    if not isinstance(source, bytes):
        raise ValueError("shared boss mapping stream is missing")
    mapping = decompress(source)
    if len(mapping) != MAPPING_LENGTH:
        raise ValueError("shared boss mapping has unexpected decoded length")
    ram = bytearray(0x4000)
    ram[MAPPING_DESTINATION:MAPPING_DESTINATION + len(mapping)] = mapping
    descriptor = descriptor_bytes(data, descriptor_name)
    if descriptor[:6] != bytes.fromhex("610020000302"):
        raise ValueError("unsupported Stage 5/6 indexed-row layout")
    empty = [[0] * PLANE_COLUMNS for _ in range(PLANE_ROWS)]
    rows = apply_indexed_rows(empty, ram, descriptor)
    if frame_counter is not None:
        rows = _apply_joker_body_frame(
            rows, data, frame_counter, secondary_frame_offset)
    return StageBossSecondaryTable(boss, descriptor_name, descriptor, mapping, rows)
