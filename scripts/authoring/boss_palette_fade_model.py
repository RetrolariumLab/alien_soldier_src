"""The default boss fade applied to source-owned palette command words.

`Gfx_UpdateBossPaletteColorFade` reads shadow colors for the counted
`PaletteFade_DefaultEntryOffsets` list and writes clamped RGB deltas
to the active palette. The shared color at index 54 is deliberately not
in that list and is preserved separately by the palette loader.
"""

from __future__ import annotations

from authoring.palette_model import PaletteCommand, read_commands


ACTIVE_PALETTE_BASE = 0xE300
FIRST_BOSS_COLOR = 49
BOSS_COLOR_COUNT = 15
SHARED_COLOR = 54
SUPPORTED_PHASES = frozenset((0, 5, 10, 15, 20, 25))


def default_fade_indices(source_words: tuple[int, ...]) -> tuple[int, ...]:
    """Decode the DBF count and active-buffer addresses from the ASM table."""
    if (not isinstance(source_words, tuple) or not source_words
            or source_words[0] != 13 or len(source_words) < 15):
        raise ValueError("default boss fade entry table is unsupported")
    indices = []
    for address in source_words[1:15]:
        if (address & 1 or not ACTIVE_PALETTE_BASE <= address <
                ACTIVE_PALETTE_BASE + 128):
            raise ValueError("default boss fade target leaves active palette")
        indices.append((address - ACTIVE_PALETTE_BASE) // 2)
    if (len(set(indices)) != 14 or
            set(indices) != set(range(FIRST_BOSS_COLOR,
                                      FIRST_BOSS_COLOR + BOSS_COLOR_COUNT))
            - {SHARED_COLOR}):
        raise ValueError("default boss fade target set is unsupported")
    return tuple(indices)


def faded_boss_colors(
        command: PaletteCommand, targets: tuple[int, ...],
        phase: int, shared_color: int,
) -> tuple[int, ...]:
    """Return active palette indices 49..63 after one supported fade phase."""
    if (command.first_colour != FIRST_BOSS_COLOR or
            command.count != BOSS_COLOR_COUNT):
        raise ValueError("boss palette command must cover colors 49..63")
    if phase not in SUPPORTED_PHASES:
        raise ValueError("unsupported default boss fade phase")
    if not 0 <= shared_color <= 0x0EEE:
        raise ValueError("preserved boss palette color is not a CRAM word")
    if set(targets) != (set(range(FIRST_BOSS_COLOR,
                                  FIRST_BOSS_COLOR + BOSS_COLOR_COUNT))
                        - {SHARED_COLOR}):
        raise ValueError("unsupported default boss fade targets")
    active = list(command.colours)
    active[SHARED_COLOR - FIRST_BOSS_COLOR] = shared_color
    green_delta = (phase << 4) & 0xFFE0
    blue_delta = (phase << 8) & 0xFE00
    for index in targets:
        shadow = command.colours[index - FIRST_BOSS_COLOR]
        red = min(0xE, (shadow & 0xE) + phase)
        green = min(0xE0, (shadow & 0xE0) + green_delta)
        blue = min(0xE00, (shadow & 0xE00) + blue_delta)
        active[index - FIRST_BOSS_COLOR] = red | green | blue
    return tuple(active)


def boss_faded_line_from_source(
        data: dict, command_name: str, phase: int,
        shared_color: int = 0,
) -> tuple[int, ...]:
    """Read one source command and its default fade table, then play them."""
    raw = data.get(command_name)
    if not isinstance(raw, bytes):
        raise ValueError("boss palette source command is missing")
    commands = read_commands(raw, command_name)
    if len(commands) != 1:
        raise ValueError("boss palette source must contain one command")
    targets = default_fade_indices(
        data.get("PaletteFade_DefaultEntryOffsets"))
    return faded_boss_colors(
        commands[0], targets, phase, shared_color)
