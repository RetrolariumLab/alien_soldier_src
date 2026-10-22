"""Bounded source-only two-plane background during Joker's raster phase.

This combines the source boss art, indexed plane-B table, default boss
palette fade, and Joker's perspective VScroll buffer. It excludes sprites,
the HUD, other color effects, and unmodelled raster phases.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from authoring.joker_raster_model import copy_boss_transition_window, joker_perspective_rows
from authoring.stage5_6_boss_rendering import build_boss_display, draw_boss_rows


@dataclass(frozen=True)
class JokerRasterPose:
    primary_hscroll: int
    secondary_hscroll: int
    frame_counter: int
    secondary_frame_offset: int
    body_y: int
    body_height: int
    fade_phase: int
    shared_color54: int = 0
    primary_vscroll: int = 0
    initial_secondary_vscroll: int = 0


def _signed_word(value: int) -> int:
    return value - 0x10000 if value & 0x8000 else value


def draw_joker_raster_background(
    root: Path,
    pose: JokerRasterPose,
    *,
    top: int = 32,
    bottom: int = 224,
    width: int = 320,
) -> list[list[tuple[int, int, int]]]:
    """Render the supported boss background; row 2 uses raster word zero."""
    if pose.primary_vscroll != 0 or pose.initial_secondary_vscroll != 0:
        raise ValueError("Joker raster preview supports zero initial VScroll")

    displayed = build_boss_display(
        root,
        "joker",
        pose.fade_phase,
        pose.shared_color54,
        frame_counter=pose.frame_counter,
        secondary_frame_offset=pose.secondary_frame_offset,
    )
    perspective = joker_perspective_rows(pose.body_y, pose.body_height)
    active = copy_boss_transition_window((0,) * 15, perspective)

    def secondary_vscroll_at(screen_y: int) -> int:
        # Gens begins HInt_Counter at register 10 (=1), renders the current
        # line before executing its HBlank IRQ, then applies each written
        # VScroll2 word to the next two lines. The first active word is
        # therefore visible on scanlines 2 and 3.
        raster_index = (screen_y - 2) // 2
        return _signed_word(active[raster_index])

    return draw_boss_rows(
        displayed,
        pose.primary_hscroll,
        pose.secondary_hscroll,
        pose.primary_vscroll,
        secondary_vscroll_at,
        top,
        bottom,
        width,
    )
