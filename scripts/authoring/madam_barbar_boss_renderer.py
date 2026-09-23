"""Source-only two-plane background for Madam Barbar's static-scroll phase.

The stage already streams plane A. Boss setup fills a separate indexed
plane-B table, loads tile art at VRAM $6000, and plays the default
palette fade. No HBlank raster effect is active in the supported poses.
Sprites, HUD, and other boss states are outside this bounded preview.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from authoring.stage5_6_boss_rendering import (
    build_boss_display, draw_boss_rows)


@dataclass(frozen=True)
class MadamBarbarPose:
    primary_hscroll: int
    secondary_hscroll: int
    primary_vscroll: int
    secondary_vscroll: int
    fade_phase: int
    shared_color54: int = 0


def draw_madam_barbar_background(
        root: Path, pose: MadamBarbarPose, *,
        top: int = 32, bottom: int = 224, width: int = 320,
) -> list[list[tuple[int, int, int]]]:
    """Render a supported static-scroll pose from preservation source data."""
    displayed = build_boss_display(
        root, "madam_barbar", pose.fade_phase, pose.shared_color54)
    return draw_boss_rows(
        displayed, pose.primary_hscroll, pose.secondary_hscroll,
        pose.primary_vscroll, lambda _y: pose.secondary_vscroll,
        top, bottom, width)
