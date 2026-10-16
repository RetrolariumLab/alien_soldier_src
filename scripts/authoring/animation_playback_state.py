"""Lazy, bounded viewer state for the source-qualified animation reader.

Viewer pause/cadence never changes the modeled object or FrameControlFlags.
The GUI owns scheduling; this module only counts actual reader invocations.
"""

from __future__ import annotations

from pathlib import Path

from authoring import animation_preview_model as reader


class PlaybackController:
    """Snapshot unsaved documents only when the user requests playback."""

    def __init__(self, project: Path, profile: str):
        self.project, self.profile = project, profile
        self.caller = reader.CallerState(0xE0, 0)
        self.invalidate()

    def invalidate(self) -> None:
        self.catalog = None
        self.state = None
        self.selected_script = None
        self.last = None
        self.invocations = 0
        self.playing = False

    def prepare(self, script: str, animation_document: dict,
                mapping_document: dict) -> None:
        if self.selected_script != script:
            self.invalidate()
        if self.catalog is not None:
            return
        catalog = reader.build_catalog(
            self.project, self.profile, animation_document,
            mapping_document=mapping_document)
        state = reader.PlaybackState(reader.Cursor(script))
        reader.simulate(catalog, state, self.caller, 0)
        entry = catalog.entry(state.cursor)
        geometry = catalog.mappings[entry.target]
        if geometry.dynamic:
            raise reader.UnsupportedPlayback(
                "qualified static timed caller cannot consume an eight-byte dynamic mapping")
        self.catalog, self.state, self.selected_script = catalog, state, script

    @property
    def geometry(self):
        if self.state is None:
            return None
        return self.catalog.mappings[self.catalog.entry(self.state.cursor).target]

    def advance(self):
        if self.catalog is None or self.state is None:
            raise ValueError("animation playback has not been prepared")
        if self.invocations >= reader.MAX_STEPS:
            raise reader.UnsupportedPlayback(
                "viewer invocation budget exhausted (%d); Reset to restart" % reader.MAX_STEPS)
        observed = reader.step(self.catalog, self.state, self.caller)
        self.state, self.last = observed.after, observed
        self.invocations += 1
        if (self.invocations == reader.MAX_STEPS
                or observed.event == "hold-negative-low-byte"):
            self.playing = False
        return observed

    def details(self) -> str:
        if self.state is None:
            return "Press Play, Step or Reset to qualify the selected script."
        state, geometry = self.state, self.geometry
        event = self.last.event if self.last else "reset; no reader invocation"
        jump = ("; jump via %s[%d]" % (
            self.last.jump_entry.script, self.last.jump_entry.index)
            if self.last and self.last.jump_entry else "")
        return ("%s[%d] -> %s; timer $%04X; calls %d/%d; %s%s\n"
                "%d static pieces; bounds %s; source %s" % (
                    state.cursor.script, state.cursor.index, geometry.symbol,
                    state.timer, self.invocations, reader.MAX_STEPS, event, jump,
                    len(geometry.pieces), geometry.bounds, geometry.source_path))


def draw_geometry(canvas, geometry, width: int, height: int) -> None:
    """Draw source-relative pieces, never fabricate art/palette/OAM pixels."""
    canvas.delete("all")
    if geometry is None:
        return
    left, top, span_x, span_y = geometry.bounds
    right, bottom = max(0, left + span_x), max(0, top + span_y)
    left, top = min(0, left), min(0, top)
    scale = min(3.0, (width - 40) / max(1, right - left),
                (height - 40) / max(1, bottom - top))
    origin_x, origin_y = (width - (left + right) * scale) / 2, (height - (top + bottom) * scale) / 2
    canvas.create_line(0, origin_y, width, origin_y, fill="#505050")
    canvas.create_line(origin_x, 0, origin_x, height, fill="#505050")
    for index, piece in enumerate(geometry.pieces):
        x, y = origin_x + piece.x * scale, origin_y + piece.y * scale
        right, bottom = x + piece.width * scale, y + piece.height * scale
        canvas.create_rectangle(x, y, right, bottom, fill="#4b6f8f", outline="#d0d0d0")
        canvas.create_text((x + right) / 2, (y + bottom) / 2, text=str(index), fill="#ffffff")
