"""Source-only Sniper Honeyviper background below the 32-pixel HUD band.

The boss phase combines a streamed plane-A table, indexed plane-B columns,
one later tile-art transfer, the initial boss palette command, and two
line-scroll writers. Later palette effects, sprite actors, the HUD, top
raster rows, and other phases are not modelled here.
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from pathlib import Path

from authoring.stage4_boss_tilemap_model import PLANE_COLUMNS, PLANE_ROWS, build_sniper_honeyviper_name_tables
from authoring.stage4_raster_model import (
    sniper_honeyviper_horizontal_profile,
    sniper_honeyviper_primary_rows,
    sniper_honeyviper_secondary_rows,
)
from authoring.stage_renderer import plane_scanline, play_palette_command, read_once, scene
from authoring.stage_tilemap_model import decompress


FIRST_BACKGROUND_ROW = 32
LAST_BACKGROUND_ROW = 224
BOSS_PRIMARY_CAMERA_X = 0x1AF8
BOSS_TILE_ART_VRAM = 0x6000


@dataclass(frozen=True)
class SniperHoneyviperPose:
    primary_camera_x: int
    primary_camera_y: int
    primary_shake_offset: int
    current_x: int
    current_y: int
    anchor_x: int
    anchor_y: int


@dataclass(frozen=True)
class _NameTablePlane:
    rows: tuple[tuple[int, ...], ...]

    def defined(self, x: int, y: int) -> bool:
        return True

    def name_word(self, x: int, y: int) -> int:
        return self.rows[(y // 8) & (PLANE_ROWS - 1)][(x // 8) & (PLANE_COLUMNS - 1)]


def _signed_word(word: int) -> int:
    return word - 0x10000 if word & 0x8000 else word


def draw_sniper_honeyviper_background(
    root: Path,
    pose: SniperHoneyviperPose,
    top: int = FIRST_BACKGROUND_ROW,
    bottom: int = LAST_BACKGROUND_ROW,
    width: int = 320,
) -> list[list[tuple[int, int, int]]]:
    """Render boss background rows with source assets and the initial palette.

    Stage 4 locks the primary camera at ($1AF8, 0) for these captures. Its
    pre-boss plane-A ring survives in rows 20..31; the visible columns at
    that locked camera are source-owned. Unsupported camera/viewport states
    fail closed instead of appearing to be a complete gameplay renderer.
    """
    if pose.primary_camera_x != BOSS_PRIMARY_CAMERA_X:
        raise ValueError("Sniper Honeyviper boss camera must be locked at $1AF8")
    if pose.primary_camera_y != 0:
        raise ValueError("Sniper Honeyviper boss camera Y must be zero")
    if not FIRST_BACKGROUND_ROW <= top < bottom <= LAST_BACKGROUND_ROW:
        raise ValueError("boss background supports only rows 32..223")
    if not 1 <= width <= 320:
        raise ValueError("boss background viewport width must be 1..320")

    base = scene(root, 3)
    tables = build_sniper_honeyviper_name_tables(root)
    source_art = read_once(root)["data"].get("Boss_SniperHoneyviperTileArt")
    if source_art is None:
        raise ValueError("Sniper Honeyviper tile art is unavailable")
    art = decompress(source_art)
    vram = bytearray(base.vram)
    if BOSS_TILE_ART_VRAM + len(art) > len(vram):
        raise ValueError("Sniper Honeyviper tile art exceeds VRAM")
    vram[BOSS_TILE_ART_VRAM : BOSS_TILE_ART_VRAM + len(art)] = art

    page = pose.primary_camera_x & ~0x1FF
    primary_rows = tables.primary_transferred_rows + tuple(
        tuple(base.tilemap.name_word(page + column * 8, row * 8) for column in range(PLANE_COLUMNS))
        for row in range(20, PLANE_ROWS)
    )
    palette = play_palette_command(root, "Boss_SniperHoneyviperPaletteCommand", (), base.palette)
    displayed = replace(
        base,
        vram=bytes(vram),
        palette=palette,
        backdrop=palette[16],
        tilemap=_NameTablePlane(primary_rows),
        plane_b=_NameTablePlane(tables.secondary_rows),
    )

    profile = sniper_honeyviper_horizontal_profile(pose.primary_camera_x)
    primary_scroll = sniper_honeyviper_primary_rows(profile, pose.primary_shake_offset)
    secondary_scroll = sniper_honeyviper_secondary_rows(pose.current_x, pose.current_y, pose.anchor_x, pose.anchor_y)
    secondary_vscroll = -0x30 - pose.current_y
    image = []
    cache = {}
    for screen_y in range(top, bottom):
        line = screen_y - FIRST_BACKGROUND_ROW
        camera_a = -_signed_word(primary_scroll[line])
        camera_b = -_signed_word(secondary_scroll[line])
        # Scroll_PreparePlaneBuffersAndRegisterShadows adds the same shake
        # offset to plane A's VScroll word as the profile copier uses for A's
        # horizontal rows. Without this vertical sample offset, the
        # one-pixel-shake frames cannot match their saved VDP output.
        front = plane_scanline(
            displayed, displayed.tilemap, camera_a, screen_y + pose.primary_shake_offset, width, cache, False
        )
        back = plane_scanline(displayed, displayed.plane_b, camera_b, screen_y + secondary_vscroll, width, cache, False)
        front_colours, front_indices, front_priorities = front
        back_colours, back_indices, back_priorities = back
        row = []
        for x in range(width):
            if front_indices[x] and front_priorities[x]:
                row.append(front_colours[x])
            elif back_indices[x] and back_priorities[x]:
                row.append(back_colours[x])
            elif front_indices[x]:
                row.append(front_colours[x])
            elif back_indices[x]:
                row.append(back_colours[x])
            else:
                row.append(displayed.backdrop)
        image.append(row)
    return image
