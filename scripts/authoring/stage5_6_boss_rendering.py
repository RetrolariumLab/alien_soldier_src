"""Shared source assets and two-plane compositing for Stage 5/6 bosses."""

from __future__ import annotations

from dataclasses import dataclass, replace
from pathlib import Path
from typing import Callable

from authoring.boss_palette_fade_model import boss_faded_line_from_source
from authoring.stage5_6_boss_tilemap_model import build_boss_secondary_table
from authoring.stage_renderer import plane_scanline, read_once, scene
from authoring.stage_tilemap_model import decompress
from authoring.tile_graphics import cram_to_rgb


BOSS_DISPLAY = {
    "madam_barbar": (4, "Boss_MadamBarbarTileArt", "Boss_MadamBarbarPaletteCommand"),
    "joker": (5, "Boss_JokerTileArt", "Boss_JokerPaletteCommand"),
}


@dataclass(frozen=True)
class _NameTablePlane:
    rows: tuple[tuple[int, ...], ...]

    def defined(self, x: int, y: int) -> bool:
        return True

    def name_word(self, x: int, y: int) -> int:
        return self.rows[(y // 8) & 31][(x // 8) & 63]


def build_boss_display(
    root: Path,
    boss: str,
    fade_phase: int,
    shared_color54: int = 0,
    *,
    frame_counter: int | None = None,
    secondary_frame_offset: int | None = None,
):
    """Overlay the boss's source art, faded colors, and indexed B table."""
    if boss not in BOSS_DISPLAY:
        raise ValueError("unsupported Stage 5/6 boss display")
    index, art_name, palette_name = BOSS_DISPLAY[boss]
    base = scene(root, index)
    table = build_boss_secondary_table(
        root, boss, frame_counter=frame_counter, secondary_frame_offset=secondary_frame_offset
    )
    data = read_once(root)["data"]
    compressed_art = data.get(art_name)
    if not isinstance(compressed_art, bytes):
        raise ValueError("boss tile art is unavailable")
    art = decompress(compressed_art)
    if 0x6000 + len(art) > len(base.vram):
        raise ValueError("boss tile art exceeds VRAM")
    vram = bytearray(base.vram)
    vram[0x6000 : 0x6000 + len(art)] = art
    line3 = boss_faded_line_from_source(data, palette_name, fade_phase, shared_color54)
    palette = list(base.palette)
    palette[49:64] = [cram_to_rgb(word) for word in line3]
    return replace(base, vram=bytes(vram), palette=palette, plane_b=_NameTablePlane(table.rows))


def draw_boss_rows(
    displayed,
    primary_hscroll: int,
    secondary_hscroll: int,
    primary_vscroll: int,
    secondary_vscroll_at: Callable[[int], int],
    top: int,
    bottom: int,
    width: int,
) -> list[list[tuple[int, int, int]]]:
    """Composite independent A/B scroll samples, excluding sprites/HUD."""
    if not 32 <= top < bottom <= 224:
        raise ValueError("boss background supports rows 32..223")
    if not 1 <= width <= 320:
        raise ValueError("boss viewport width must be 1..320")
    if any(not -0x8000 <= scroll <= 0x7FFF for scroll in (primary_hscroll, secondary_hscroll, primary_vscroll)):
        raise ValueError("boss scroll must be a signed word")
    image = []
    cache = {}
    for screen_y in range(top, bottom):
        back_vscroll = secondary_vscroll_at(screen_y)
        if not -0x8000 <= back_vscroll <= 0x7FFF:
            raise ValueError("boss secondary VScroll must be a signed word")
        front = plane_scanline(
            displayed, displayed.tilemap, -primary_hscroll, screen_y + primary_vscroll, width, cache, False
        )
        back = plane_scanline(
            displayed, displayed.plane_b, -secondary_hscroll, screen_y + back_vscroll, width, cache, False, 512
        )
        front_colors, front_indices, front_priorities = front
        back_colors, back_indices, back_priorities = back
        row = []
        for x in range(width):
            if front_indices[x] and front_priorities[x]:
                row.append(front_colors[x])
            elif back_indices[x] and back_priorities[x]:
                row.append(back_colors[x])
            elif front_indices[x]:
                row.append(front_colors[x])
            elif back_indices[x]:
                row.append(back_colors[x])
            else:
                row.append(displayed.backdrop)
        image.append(row)
    return image
