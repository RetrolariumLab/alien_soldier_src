"""Source-derived Stage 4 Sniper Honeyviper scroll-profile boundary.

This models the 200 words written by
Stage4_FillSniperHoneyviperHorizontalRasterOffsets. It does not model the
subsequent scroll-buffer copier, other raster producers, or the boss picture.
"""

from __future__ import annotations


SECONDARY_LINES = 0x80
PRIMARY_LINES = 0x48
VISIBLE_PRIMARY_PROFILE_LINES = 0xC0


def sniper_honeyviper_horizontal_profile(primary_camera_x: int) -> tuple[int, ...]:
    """Return the source routine's 128 secondary and 72 primary scroll words.

    The caller runs Scroll_UpdateQuarterHorizontalPosition before the profile
    writer. The encounter handler later stores $C0 in SecondaryCameraXPos,
    *after* writing this profile; that later value must not replace the
    quarter-camera value already captured here.
    """
    if not 0 <= primary_camera_x <= 0x7FFF:
        raise ValueError("Stage 4 primary camera X must be a positive signed word")
    secondary_camera_x = primary_camera_x >> 2
    return (-secondary_camera_x & 0xFFFF,) * SECONDARY_LINES + (-primary_camera_x & 0xFFFF,) * PRIMARY_LINES


def sniper_honeyviper_primary_rows(profile: tuple[int, ...], shake_offset: int) -> tuple[int, ...]:
    """Copy the 192 visible A rows from the profile into HScroll rows 32..223.

    Scroll_CopyHorizontalProfile offsets its source pointer by the plane-A
    shake value before the 192-word copy. This bounded model covers only
    non-negative offsets that remain inside the 200-word Stage 4 profile;
    other cases require the adjacent RAM and are deliberately unsupported.
    """
    if len(profile) != SECONDARY_LINES + PRIMARY_LINES:
        raise ValueError("Stage 4 profile must contain exactly 200 words")
    if not 0 <= shake_offset <= len(profile) - VISIBLE_PRIMARY_PROFILE_LINES:
        raise ValueError("shake offset reads outside the modelled profile")
    return profile[shake_offset : shake_offset + VISIBLE_PRIMARY_PROFILE_LINES]


def sniper_honeyviper_secondary_rows(current_x: int, current_y: int, anchor_x: int, anchor_y: int) -> tuple[int, ...]:
    """Model the boss writer's plane-B HScroll words for display rows 32..223.

    Entity fields +$10/+$14 supply the current position; +$70/+$74 supply the
    interpolation anchor. The source fills 192 rows with -$80, overwrites 51
    descending upper rows, interpolates between upper and lower offsets with
    the 68000's signed quotient truncated toward zero, and fills 70 lower
    rows. This model fails closed if those writes leave the display interval.
    """
    positions = (current_x, current_y, anchor_x, anchor_y)
    if any(not 0 <= value <= 0x7FFF for value in positions):
        raise ValueError("Sniper Honeyviper positions must be positive signed words")

    first_row = anchor_y - 0x80
    span = anchor_y - current_y - 0x38
    last_row = first_row - 51 - span - 69
    if not 1 <= span <= VISIBLE_PRIMARY_PROFILE_LINES:
        raise ValueError("Sniper Honeyviper interpolation span is unsupported")
    if first_row > 223 or last_row < 32:
        raise ValueError("Sniper Honeyviper raster writes leave display rows")

    delta = current_x - anchor_x
    numerator = delta << 4
    quotient = (abs(numerator) // span) * (-1 if numerator < 0 else 1)
    if not -0x8000 <= quotient <= 0x7FFF:
        raise ValueError("Sniper Honeyviper signed division overflows")
    step = quotient << 12
    upper = anchor_x - 0xA8
    lower = current_x - 0xA8
    rows = [(-0x80) & 0xFFFF] * VISIBLE_PRIMARY_PROFILE_LINES
    row = first_row
    for _ in range(51):
        rows[row - 32] = upper & 0xFFFF
        row -= 1
    fixed = upper << 16
    for _ in range(span):
        rows[row - 32] = (fixed >> 16) & 0xFFFF
        row -= 1
        fixed += step
    for _ in range(70):
        rows[row - 32] = lower & 0xFFFF
        row -= 1
    return tuple(rows)
