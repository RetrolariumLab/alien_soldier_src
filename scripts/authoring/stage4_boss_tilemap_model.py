"""Source-derived name tables for Sniper Honeyviper's background transition.

The stage initially displays its secondary plane from the Stage 4 source
maps. The boss queues 20 of those rows into plane A, then loads the shared
mapping stream and applies its indexed-column descriptor to plane B. These
tables alone do not include raster scrolling, sprites, or other VRAM art.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from authoring.indexed_row_transfer import apply_indexed_rows, descriptor_bytes
from authoring.stage_renderer import read_once, scene
from authoring.stage_tilemap_model import decompress


PLANE_COLUMNS = 64
PLANE_ROWS = 32
PRIMARY_TRANSFER_ROWS = 20
SHARED_MAPPING_RAM_OFFSET = 0x2020
INDEXED_DESCRIPTOR_NAME = "Boss_SniperHoneyviperTileDmaDescriptor"


@dataclass(frozen=True)
class BossStage4NameTables:
    primary_transferred_rows: tuple[tuple[int, ...], ...]
    secondary_rows: tuple[tuple[int, ...], ...]
    shared_mapping_bytes: int


def build_sniper_honeyviper_name_tables(root: Path) -> BossStage4NameTables:
    """Build only the name words whose boss-phase writers have known sources."""
    stage = scene(root, 3)
    plane = stage.plane_b
    if plane is None:
        raise ValueError("Stage 4 source secondary plane is unavailable")
    primary = tuple(
        tuple(plane.name_word(column * 8, row * 8)
              for column in range(PLANE_COLUMNS))
        for row in range(PRIMARY_TRANSFER_ROWS))
    secondary = [
        [plane.name_word(column * 8, row * 8)
         for column in range(PLANE_COLUMNS)]
        for row in range(PLANE_ROWS)]

    data = read_once(root)["data"]
    source = data.get("SharedBossMappingData2020")
    if source is None:
        raise ValueError("shared boss mapping payload is unavailable")
    mapping = decompress(source)
    ram = bytearray(plane.ram)
    end = SHARED_MAPPING_RAM_OFFSET + len(mapping)
    if end > len(ram):
        raise ValueError("shared boss mapping exceeds the RAM image")
    ram[SHARED_MAPPING_RAM_OFFSET:end] = mapping

    descriptor = descriptor_bytes(data, INDEXED_DESCRIPTOR_NAME)
    if descriptor[:6] != bytes.fromhex("610020000204"):
        raise ValueError("unsupported Sniper Honeyviper indexed-column layout")
    secondary = apply_indexed_rows(secondary, ram, descriptor)
    return BossStage4NameTables(
        primary, secondary, len(mapping))
