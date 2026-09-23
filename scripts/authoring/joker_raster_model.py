"""Source-derived Joker perspective words before the per-line VScroll writer.

`Boss_JokerRenderBody` first writes 96 descending words at `$FFFF9520`,
then overwrites 31 pairs around its body-Y-dependent center. At VBlank,
`RasterBuffer_CopyBossTransitionWindow` copies those 96 words into the
active raster buffer after its first 15 words. This models the buffer
contents, not yet the HBlank timing or final screenshot pixels.
"""

from __future__ import annotations


PERSPECTIVE_BASE = 0x9520
PERSPECTIVE_WORDS = 96
ACTIVE_PREFIX_WORDS = 15
BODY_PAIRS = 31


def _swap32(value: int) -> int:
    return ((value & 0xFFFF) << 16) | ((value >> 16) & 0xFFFF)


def _signed16(value: int) -> int:
    return value - 0x10000 if value & 0x8000 else value


def joker_perspective_rows(body_y: int, body_height: int) -> tuple[int, ...]:
    """Replay Joker's 68k word stores to the 96-word source window."""
    if not 0 <= body_y <= 0xFFFF:
        raise ValueError("Joker body Y must be a word")
    if not 1 <= body_height <= 0x7FFF:
        raise ValueError("Joker body height must be a positive signed word")

    rows = [(0x80 - 2 * index) & 0xFFFF
            for index in range(PERSPECTIVE_WORDS)]
    difference = _signed16((body_height - 0x40) & 0xFFFF)
    dividend = difference << 8
    # 68k DIVS truncates toward zero; Python's // rounds negatives down.
    quotient = ((abs(dividend) // body_height)
                * (-1 if dividend < 0 else 1))
    step = (quotient << 9) & 0xFFFFFFFF
    left = right = (0x1B0 - body_y) & 0xFFFFFFFF
    center = (body_y - 0x6B78) & 0xFFFE

    def store(address: int, word: int) -> None:
        offset = ((address & 0xFFFF) - PERSPECTIVE_BASE) // 2
        if (PERSPECTIVE_BASE <= (address & 0xFFFF)
                < PERSPECTIVE_BASE + 2 * PERSPECTIVE_WORDS):
            rows[offset] = word & 0xFFFF

    for pair in range(BODY_PAIRS):
        store(center - 2 - 2 * pair, left)
        store(center + 2 * pair, right)
        left = _swap32((_swap32(left) + step) & 0xFFFFFFFF)
        right = _swap32((_swap32(right) - step) & 0xFFFFFFFF)
    return tuple(rows)


def copy_boss_transition_window(
        active_prefix: tuple[int, ...],
        perspective: tuple[int, ...],
) -> tuple[int, ...]:
    """Replay the 192-byte VBlank copy into active raster words 15..110."""
    if len(active_prefix) != ACTIVE_PREFIX_WORDS:
        raise ValueError("Joker active raster prefix must contain 15 words")
    if len(perspective) != PERSPECTIVE_WORDS:
        raise ValueError("Joker perspective source must contain 96 words")
    if any(not 0 <= word <= 0xFFFF
           for word in active_prefix + perspective):
        raise ValueError("Joker raster values must be words")
    return active_prefix + perspective
