#!/usr/bin/env python3
"""Open the profile-bound Alien Soldier Graphics Studio workstation."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.content_workspace import (  # noqa: E402
    ContentError,
    artifact_path,
    checked_path,
    load_manifest,
)
from authoring.animation_studio_model import (  # noqa: E402
    atomic_write_json as write_animation_document,
    load_document as load_animation_document,
    validate_document as validate_animation_document,
)
from authoring.animation_studio_state import AnimationWorkspace  # noqa: E402
from authoring.animation_playback_state import (  # noqa: E402
    PlaybackController,
    draw_geometry,
)
from authoring.compressed_graphics_model import (  # noqa: E402
    atomic_write_json as write_compressed_document,
    load_document as load_compressed_document,
    validate_document as validate_compressed_document,
)
from authoring.graphics_studio_model import (  # noqa: E402
    atomic_write_json as write_tile_document,
    load_document as load_tile_document,
    validate_document as validate_tile_document,
)
from authoring.graphics_studio_state import Workspace  # noqa: E402
from authoring.mapping_studio_model import (  # noqa: E402
    atomic_write_json as write_mapping_document,
    load_document as load_mapping_document,
    validate_document as validate_mapping_document,
)
from authoring.mapping_studio_state import MappingWorkspace  # noqa: E402
from authoring.palette_studio_model import (  # noqa: E402
    atomic_write_json as write_palette_document,
    load_document as load_palette_document,
    validate_document as validate_palette_document,
)
from authoring.palette_studio_state import PaletteWorkspace  # noqa: E402
from authoring.level_studio_model import (  # noqa: E402
    load_document as load_level_document,
    validate_document as validate_level_document,
)
from authoring.object_gallery_model import catalogue, stage_preview, survey  # noqa: E402
from authoring.tile_graphics import cram_to_rgb  # noqa: E402
from authoring.stage_tilemap_model import parsed_operation  # noqa: E402


MANIFEST = "config/authoring/content_studios.json"
PIXEL_SIZE = 48
TILE_SIDE = 8
PALETTE_SIZE = 24
COMMAND_SWATCH = 32
COMMAND_COLUMNS = 16
MAPPING_CANVAS_WIDTH = 520
MAPPING_CANVAS_HEIGHT = 300
ANIMATION_CANVAS_HEIGHT = 160
# Display pacing only: a callback advances one qualified reader invocation.
ANIMATION_VIEW_INTERVAL_MS = 100


def graphics_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "tile_art")


def palette_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "palette_commands")


def compressed_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "compressed_tile_art")


def mapping_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "sprite_mappings")


def animation_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "sprite_animations")


def level_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "level_layouts")


def gallery_choices(records):
    return ["%s  [%s #%d]" % (record["handler"], record["spawn_list"], record["placement_index"]) for record in records]


def load_context(project: Path, profile: str):
    with parsed_operation(project):
        return _load_context(project, profile)


def _load_context(project: Path, profile: str):
    manifest = load_manifest(checked_path(project, MANIFEST), project)
    tile_path = artifact_path(project, manifest, profile, graphics_artifact(manifest))
    compressed_path = artifact_path(project, manifest, profile, compressed_artifact(manifest))
    palette_path = artifact_path(project, manifest, profile, palette_artifact(manifest))
    mapping_path = artifact_path(project, manifest, profile, mapping_artifact(manifest))
    animation_path = artifact_path(project, manifest, profile, animation_artifact(manifest))
    level_path = artifact_path(project, manifest, profile, level_artifact(manifest))
    tile_document = load_tile_document(tile_path)
    compressed_document = load_compressed_document(compressed_path, project, profile)
    palette_document = load_palette_document(palette_path)
    mapping_document = load_mapping_document(mapping_path)
    animation_document = load_animation_document(animation_path)
    level_document = load_level_document(level_path)
    validate_tile_document(tile_document, project, profile)
    validate_compressed_document(compressed_document, project, profile)
    validate_palette_document(palette_document, project, profile)
    validate_mapping_document(mapping_document, project, profile)
    validate_animation_document(animation_document, project, profile)
    validate_level_document(level_document, project, profile)
    return (
        tile_path,
        tile_document,
        compressed_path,
        compressed_document,
        palette_path,
        palette_document,
        mapping_path,
        mapping_document,
        animation_path,
        animation_document,
        level_path,
        level_document,
    )


def index_colour(index: int) -> str:
    value = index * 17
    return "#%02x%02x%02x" % (value, value, value)


def rgb_colour(word: int) -> str:
    return "#%02x%02x%02x" % cram_to_rgb(word)


class Window:
    """Tk widgets only; all editable state lives in Workspace."""

    def __init__(
        self,
        project,
        profile,
        tile_path,
        tile_document,
        compressed_path,
        compressed_document,
        palette_path,
        palette_document,
        mapping_path,
        mapping_document,
        animation_path,
        animation_document,
        level_path,
        level_document,
        payload,
        tk,
        ttk,
        messagebox,
    ):
        self.project = project
        self.profile = profile
        self.tile_path = tile_path
        self.compressed_path = compressed_path
        self.palette_path = palette_path
        self.mapping_path = mapping_path
        self.animation_path = animation_path
        self.level_path = level_path
        self.level_document = level_document
        self.tk = tk
        self.ttk = ttk
        self.messagebox = messagebox
        self.state = Workspace(tile_document)
        self.compressed_state = Workspace(compressed_document)
        self.palette_state = PaletteWorkspace(palette_document)
        self.mapping_state = MappingWorkspace(mapping_document)
        self.animation_state = AnimationWorkspace(animation_document)
        self.animation_playback = PlaybackController(project, profile)
        self.animation_after = None
        self.animation_epoch = 0
        self.gallery_records = catalogue(level_document, mapping_document, animation_document)
        self.gallery_index = 0
        self.state.select_payload(payload)

        self.window = tk.Tk()
        self.window.geometry("860x650")
        self.window.protocol("WM_DELETE_WINDOW", self.close)
        self._build_toolbar()
        self._build_editor()
        self.refresh()

    def _build_toolbar(self):
        bar = self.ttk.Frame(self.window, padding=(8, 6))
        bar.pack(side="top", fill="x")
        self.ttk.Label(bar, text="Payload").pack(side="left")
        self.choice = self.tk.StringVar()
        values = [
            "%s  (%d tiles)" % (item["name"], sum(len(block["tiles"]) for block in item["blocks"]))
            for item in self.state.payloads
        ]
        self.chooser = self.ttk.Combobox(bar, values=values, textvariable=self.choice, state="readonly", width=45)
        self.chooser.pack(side="left", padx=8)
        self.chooser.bind("<<ComboboxSelected>>", self.select_payload)
        self.ttk.Button(bar, text="Save", command=self.save).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Reload", command=self.reload).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Build ROM", command=self.build_rom).pack(side="left", padx=2)

    def _build_editor(self):
        notebook = self.ttk.Notebook(self.window)
        notebook.pack(fill="both", expand=True, padx=8, pady=(2, 8))
        tile_page = self.ttk.Frame(notebook)
        compressed_page = self.ttk.Frame(notebook)
        palette_page = self.ttk.Frame(notebook)
        mapping_page = self.ttk.Frame(notebook)
        animation_page = self.ttk.Frame(notebook)
        gallery_page = self.ttk.Frame(notebook)
        notebook.add(tile_page, text="Tile art")
        notebook.add(compressed_page, text="Compressed tiles")
        notebook.add(palette_page, text="Palettes")
        notebook.add(mapping_page, text="Sprite mappings")
        notebook.add(animation_page, text="Animations")
        notebook.add(gallery_page, text="Object gallery")
        self._build_tile_editor(tile_page)
        self._build_compressed_tile_editor(compressed_page)
        self._build_palette_editor(palette_page)
        self._build_mapping_editor(mapping_page)
        self._build_animation_editor(animation_page)
        self._build_gallery_editor(gallery_page)

    def _build_tile_editor(self, parent):
        holder = self.ttk.Frame(parent, padding=(12, 8))
        holder.pack(fill="both", expand=True)
        left = self.ttk.Frame(holder)
        left.pack(side="left", fill="y")
        tile_bar = self.ttk.Frame(left)
        tile_bar.pack(fill="x", pady=(0, 6))
        self.ttk.Button(tile_bar, text="Previous", command=lambda: self.step_tile(-1)).pack(side="left")
        self.tile_label = self.ttk.Label(tile_bar, width=24, anchor="center")
        self.tile_label.pack(side="left", padx=8)
        self.ttk.Button(tile_bar, text="Next", command=lambda: self.step_tile(1)).pack(side="left")

        size = TILE_SIDE * PIXEL_SIZE
        self.canvas = self.tk.Canvas(left, width=size, height=size, highlightthickness=1, highlightbackground="#606060")
        self.canvas.pack()
        self.canvas.bind("<Button-1>", self.paint)
        self.canvas.bind("<B1-Motion>", self.paint)
        self.canvas.bind("<Button-3>", self.erase)
        self.canvas.bind("<B3-Motion>", self.erase)

        right = self.ttk.Frame(holder, padding=(18, 36))
        right.pack(side="left", fill="y")
        self.ttk.Label(right, text="Palette indices").pack(anchor="w")
        self.palette = self.tk.Canvas(right, width=PALETTE_SIZE * 4, height=PALETTE_SIZE * 4, highlightthickness=0)
        self.palette.pack(pady=(6, 12))
        self.palette.bind("<Button-1>", self.select_colour)
        self.colour_label = self.ttk.Label(right, text="")
        self.colour_label.pack(anchor="w")
        self.help = self.ttk.Label(
            right,
            wraplength=260,
            text="Left click paints the selected palette index. Right click erases "
            "to index 0. Greyscale denotes indices, not an inferred game palette.",
        )
        self.help.pack(anchor="w", pady=(12, 0))
        self.status = self.ttk.Label(right, wraplength=260, foreground="#806000")
        self.status.pack(anchor="w", pady=(18, 0))

    def _build_compressed_tile_editor(self, parent):
        holder = self.ttk.Frame(parent, padding=(12, 8))
        holder.pack(fill="both", expand=True)
        left = self.ttk.Frame(holder)
        left.pack(side="left", fill="y")
        selector = self.ttk.Frame(left)
        selector.pack(fill="x", pady=(0, 6))
        self.compressed_choice = self.tk.StringVar()
        self.compressed_chooser = self.ttk.Combobox(
            selector,
            values=[
                "%s  (%s, %d tiles, %d bytes)"
                % (record["name"], record.get("codec", "lzss"), record["tile_count"], record["compressed_capacity"])
                for record in self.compressed_state.payloads
            ],
            textvariable=self.compressed_choice,
            state="readonly",
            width=58,
        )
        self.compressed_chooser.pack(side="left")
        self.compressed_chooser.bind("<<ComboboxSelected>>", self.select_compressed_payload)

        tile_bar = self.ttk.Frame(left)
        tile_bar.pack(fill="x", pady=(0, 6))
        self.ttk.Button(
            tile_bar,
            text="Previous",
            command=lambda: self.step_compressed_tile(-1),
        ).pack(side="left")
        self.compressed_tile_label = self.ttk.Label(tile_bar, width=24, anchor="center")
        self.compressed_tile_label.pack(side="left", padx=8)
        self.ttk.Button(
            tile_bar,
            text="Next",
            command=lambda: self.step_compressed_tile(1),
        ).pack(side="left")

        size = TILE_SIDE * PIXEL_SIZE
        self.compressed_canvas = self.tk.Canvas(
            left, width=size, height=size, highlightthickness=1, highlightbackground="#606060"
        )
        self.compressed_canvas.pack()
        self.compressed_canvas.bind("<Button-1>", self.paint_compressed)
        self.compressed_canvas.bind("<B1-Motion>", self.paint_compressed)
        self.compressed_canvas.bind("<Button-3>", self.erase_compressed)
        self.compressed_canvas.bind("<B3-Motion>", self.erase_compressed)

        right = self.ttk.Frame(holder, padding=(18, 36))
        right.pack(side="left", fill="y")
        self.ttk.Label(right, text="Palette indices").pack(anchor="w")
        self.compressed_palette = self.tk.Canvas(
            right, width=PALETTE_SIZE * 4, height=PALETTE_SIZE * 4, highlightthickness=0
        )
        self.compressed_palette.pack(pady=(6, 12))
        self.compressed_palette.bind("<Button-1>", self.select_compressed_colour)
        self.compressed_colour_label = self.ttk.Label(right, text="")
        self.compressed_colour_label.pack(anchor="w")
        self.compressed_help = self.ttk.Label(
            right,
            wraplength=270,
            text="Edits are recompressed into the source-owned fixed slot. "
            "Save rejects a stream that exceeds its original byte capacity; "
            "unused bytes are padding and never move later ROM data.",
        )
        self.compressed_help.pack(anchor="w", pady=(12, 0))
        self.compressed_status = self.ttk.Label(right, wraplength=270, foreground="#806000")
        self.compressed_status.pack(anchor="w", pady=(18, 0))

    def _build_palette_editor(self, parent):
        holder = self.ttk.Frame(parent, padding=(12, 10))
        holder.pack(fill="both", expand=True)
        selector = self.ttk.Frame(holder)
        selector.pack(fill="x")
        self.ttk.Label(selector, text="Command").pack(side="left")
        self.palette_choice = self.tk.StringVar()
        self.palette_chooser = self.ttk.Combobox(
            selector,
            values=[record["label"] for record in self.palette_state.commands],
            textvariable=self.palette_choice,
            state="readonly",
            width=58,
        )
        self.palette_chooser.pack(side="left", padx=8)
        self.palette_chooser.bind("<<ComboboxSelected>>", self.select_palette_command)

        self.command_info = self.ttk.Label(holder, text="")
        self.command_info.pack(anchor="w", pady=(8, 4))
        self.command_canvas = self.tk.Canvas(
            holder,
            width=COMMAND_SWATCH * COMMAND_COLUMNS,
            height=COMMAND_SWATCH * 4,
            highlightthickness=1,
            highlightbackground="#606060",
        )
        self.command_canvas.pack(anchor="w")
        self.command_canvas.bind("<Button-1>", self.select_palette_colour)

        controls = self.ttk.Frame(holder)
        controls.pack(anchor="w", pady=(12, 0))
        self.palette_colour_label = self.ttk.Label(controls, width=22)
        self.palette_colour_label.pack(side="left")
        self.red = self.tk.IntVar()
        self.green = self.tk.IntVar()
        self.blue = self.tk.IntVar()
        for label, variable in (("R", self.red), ("G", self.green), ("B", self.blue)):
            self.ttk.Label(controls, text=label).pack(side="left", padx=(8, 2))
            self.ttk.Spinbox(controls, from_=0, to=7, width=3, textvariable=variable).pack(side="left")
        self.ttk.Button(controls, text="Apply RGB", command=self.apply_palette_channels).pack(side="left", padx=(12, 4))
        self.raw_word = self.tk.StringVar()
        self.ttk.Entry(controls, textvariable=self.raw_word, width=7).pack(side="left", padx=(8, 2))
        self.ttk.Button(controls, text="Apply raw", command=self.apply_palette_word).pack(side="left")

        self.palette_help = self.ttk.Label(
            holder,
            wraplength=720,
            text="RGB uses the Mega Drive's three-bit channel levels. Visible channel "
            "edits preserve ignored raw CRAM bits; Apply raw accepts an exact "
            "16-bit hexadecimal bus word.",
        )
        self.palette_help.pack(anchor="w", pady=(12, 0))
        self.palette_status = self.ttk.Label(holder, wraplength=720, foreground="#806000")
        self.palette_status.pack(anchor="w", pady=(12, 0))

    def _build_mapping_editor(self, parent):
        holder = self.ttk.Frame(parent, padding=(12, 10))
        holder.pack(fill="both", expand=True)
        selector = self.ttk.Frame(holder)
        selector.pack(fill="x")
        self.ttk.Label(selector, text="Mapping").pack(side="left")
        self.mapping_choice = self.tk.StringVar()
        self.mapping_chooser = self.ttk.Combobox(
            selector,
            values=[mapping["label"] for _block, mapping in self.mapping_state.entries],
            textvariable=self.mapping_choice,
            state="readonly",
            width=62,
        )
        self.mapping_chooser.pack(side="left", padx=8)
        self.mapping_chooser.bind("<<ComboboxSelected>>", self.select_mapping)

        self.mapping_info = self.ttk.Label(holder, text="")
        self.mapping_info.pack(anchor="w", pady=(8, 4))
        self.mapping_canvas = self.tk.Canvas(
            holder,
            width=MAPPING_CANVAS_WIDTH,
            height=MAPPING_CANVAS_HEIGHT,
            highlightthickness=1,
            highlightbackground="#606060",
            background="#202020",
        )
        self.mapping_canvas.pack(anchor="w")
        self.mapping_canvas.bind("<Button-1>", self.select_mapping_piece)

        controls = self.ttk.Frame(holder)
        controls.pack(anchor="w", pady=(10, 0))
        self.ttk.Button(controls, text="Previous piece", command=lambda: self.step_mapping_piece(-1)).pack(side="left")
        self.mapping_piece_label = self.ttk.Label(controls, width=18, anchor="center")
        self.mapping_piece_label.pack(side="left", padx=6)
        self.ttk.Button(controls, text="Next piece", command=lambda: self.step_mapping_piece(1)).pack(side="left")

        fields = self.ttk.Frame(holder)
        fields.pack(anchor="w", pady=(10, 0))
        self.mapping_fields = {}
        for label, name, width in (
            ("X", "x", 5),
            ("Y", "y", 5),
            ("Attributes", "attributes", 7),
            ("Raw size", "size", 5),
            ("Link", "link", 5),
        ):
            self.ttk.Label(fields, text=label).pack(side="left", padx=(8, 2))
            variable = self.tk.StringVar()
            self.ttk.Entry(fields, textvariable=variable, width=width).pack(side="left")
            self.mapping_fields[name] = variable
        self.ttk.Button(fields, text="Apply piece", command=self.apply_mapping_piece).pack(side="left", padx=(12, 0))

        self.mapping_help = self.ttk.Label(
            holder,
            wraplength=790,
            text="The canvas is a geometry preview; it does not guess static art or a "
            "palette. Attributes, coordinates, raw size, and link are hexadecimal "
            "where prefixed by $. Dynamic art size/upload offsets and all mapping "
            "terminators remain source-owned.",
        )
        self.mapping_help.pack(anchor="w", pady=(10, 0))
        self.mapping_status = self.ttk.Label(holder, wraplength=790, foreground="#806000")
        self.mapping_status.pack(anchor="w", pady=(8, 0))

    def _build_animation_editor(self, parent):
        holder = self.ttk.Frame(parent, padding=(12, 10))
        holder.pack(fill="both", expand=True)
        selector = self.ttk.Frame(holder)
        selector.pack(fill="x")
        self.ttk.Label(selector, text="Script").pack(side="left")
        self.animation_choice = self.tk.StringVar()
        self.animation_chooser = self.ttk.Combobox(
            selector,
            values=[record["name"] for record in self.animation_state.scripts],
            textvariable=self.animation_choice,
            state="readonly",
            width=62,
        )
        self.animation_chooser.pack(side="left", padx=8)
        self.animation_chooser.bind("<<ComboboxSelected>>", self.select_animation)

        self.animation_info = self.ttk.Label(holder, text="")
        self.animation_info.pack(anchor="w", pady=(10, 8))
        timeline = self.ttk.Frame(holder)
        timeline.pack(anchor="w")
        self.ttk.Button(timeline, text="Previous frame", command=lambda: self.step_animation_frame(-1)).pack(
            side="left"
        )
        self.animation_frame_label = self.ttk.Label(timeline, width=22, anchor="center")
        self.animation_frame_label.pack(side="left", padx=8)
        self.ttk.Button(timeline, text="Next frame", command=lambda: self.step_animation_frame(1)).pack(side="left")

        fields = self.ttk.Frame(holder)
        fields.pack(anchor="w", pady=(14, 0))
        self.ttk.Label(fields, text="Target").pack(side="left")
        self.animation_target = self.tk.StringVar()
        self.animation_target_chooser = self.ttk.Combobox(
            fields,
            textvariable=self.animation_target,
            state="readonly",
            width=50,
        )
        self.animation_target_chooser.pack(side="left", padx=(6, 12))
        self.ttk.Label(fields, text="Duration").pack(side="left")
        self.animation_duration = self.tk.StringVar()
        self.ttk.Entry(fields, textvariable=self.animation_duration, width=8).pack(side="left", padx=6)
        self.ttk.Button(fields, text="Apply frame", command=self.apply_animation_frame).pack(side="left", padx=(8, 0))

        self.animation_help = self.ttk.Label(
            holder,
            wraplength=790,
            text="Normal frames may select only symbols already proved as mapping "
            "targets. Zero-duration entries are jumps and may select only known "
            "animation scripts. Their roles and the number of slots cannot change.",
        )
        self.animation_help.pack(anchor="w", pady=(16, 0))
        self.animation_status = self.ttk.Label(holder, wraplength=790, foreground="#806000")
        self.animation_status.pack(anchor="w", pady=(10, 0))
        playback = self.ttk.Frame(holder)
        playback.pack(anchor="w", pady=(8, 0))
        self.animation_playback_buttons = {}
        for label, command in (
            ("Play", self.play_animation),
            ("Pause", self.pause_animation),
            ("Step", self.step_animation),
            ("Reset", self.reset_animation),
        ):
            button = self.ttk.Button(playback, text=label, command=command)
            button.pack(side="left", padx=(0, 6))
            self.animation_playback_buttons[label] = button
        self.animation_playback_details = self.ttk.Label(holder, wraplength=790, text=self.animation_playback.details())
        self.animation_playback_details.pack(anchor="w", pady=4)
        self.animation_canvas = self.tk.Canvas(
            holder,
            width=MAPPING_CANVAS_WIDTH,
            height=ANIMATION_CANVAS_HEIGHT,
            background="#202020",
            highlightthickness=0,
        )
        self.animation_canvas.pack(anchor="w")
        self.ttk.Label(
            holder,
            wraplength=790,
            text=(
                "Source-relative geometry only; synthetic static caller flags $E0, "
                "FrameControlFlags $00. Dynamic/other reader paths are unsupported. "
                "One tick is one qualified reader invocation, not an emulator frame. "
                "UI cadence: %d ms/call; Pause pauses this viewer, not the game." % ANIMATION_VIEW_INTERVAL_MS
            ),
        ).pack(anchor="w", pady=4)

    def _build_gallery_editor(self, parent):
        holder = self.ttk.Frame(parent, padding=(12, 10))
        holder.pack(fill="both", expand=True)
        selector = self.ttk.Frame(holder)
        selector.pack(fill="x")
        self.ttk.Label(selector, text="Placed object").pack(side="left")
        self.gallery_choice = self.tk.StringVar()
        self.gallery_chooser = self.ttk.Combobox(
            selector,
            values=gallery_choices(self.gallery_records),
            textvariable=self.gallery_choice,
            state="readonly",
            width=66,
        )
        self.gallery_chooser.pack(side="left", padx=8)
        self.gallery_chooser.bind("<<ComboboxSelected>>", self.select_gallery_record)
        self.ttk.Button(selector, text="Stage and preview", command=self.preview_gallery_record).pack(
            side="left", padx=4
        )

        self.gallery_info = self.ttk.Label(holder, text="", wraplength=790)
        self.gallery_info.pack(anchor="w", pady=(10, 6))
        self.gallery_canvas = self.tk.Canvas(
            holder, width=520, height=360, background="#202020", highlightthickness=1, highlightbackground="#606060"
        )
        self.gallery_canvas.pack(anchor="w")
        self.gallery_help = self.ttk.Label(
            holder,
            wraplength=790,
            text="Preview copies preservation inputs to build/content/gallery, applies "
            "the current level, uncompressed and compressed tile, palette, "
            "mapping, and animation documents, then decodes only this object's "
            "sample stage. Unsupported bindings are reported instead of guessed.",
        )
        self.gallery_help.pack(anchor="w", pady=(10, 0))
        self.gallery_status = self.ttk.Label(holder, wraplength=790, foreground="#806000")
        self.gallery_status.pack(anchor="w", pady=(8, 0))

    def select_payload(self, _event=None):
        self.state.select_payload(self.chooser.current())
        self.refresh()

    def step_tile(self, amount):
        index = max(0, min(self.state.tile_index + amount, self.state.tile_count - 1))
        self.state.select_tile(index)
        self.refresh()

    def _pixel(self, event):
        return event.x // PIXEL_SIZE, event.y // PIXEL_SIZE

    def paint(self, event):
        self._set_pixel(*self._pixel(event), self.state.colour)

    def erase(self, event):
        self._set_pixel(*self._pixel(event), 0)

    def _set_pixel(self, x, y, colour):
        try:
            self.state.set_pixel(x, y, colour)
        except ValueError:
            return
        self.refresh_tile()
        self._title()
        self.status.configure(text="Workspace edit is not saved yet.")

    def select_colour(self, event):
        x, y = event.x // PALETTE_SIZE, event.y // PALETTE_SIZE
        index = y * 4 + x
        if 0 <= index < 16:
            self.state.select_colour(index)
            self.refresh_palette()

    def select_compressed_payload(self, _event=None):
        self.compressed_state.select_payload(self.compressed_chooser.current())
        self.refresh_compressed_tile()

    def step_compressed_tile(self, amount):
        index = max(
            0,
            min(
                self.compressed_state.tile_index + amount,
                self.compressed_state.tile_count - 1,
            ),
        )
        self.compressed_state.select_tile(index)
        self.refresh_compressed_tile()

    def paint_compressed(self, event):
        self._set_compressed_pixel(*self._pixel(event), self.compressed_state.colour)

    def erase_compressed(self, event):
        self._set_compressed_pixel(*self._pixel(event), 0)

    def _set_compressed_pixel(self, x, y, colour):
        try:
            self.compressed_state.set_pixel(x, y, colour)
        except ValueError:
            return
        self.refresh_compressed_tile()
        self._title()
        self.compressed_status.configure(text="Workspace edit is not saved or capacity-checked yet.")

    def select_compressed_colour(self, event):
        x, y = event.x // PALETTE_SIZE, event.y // PALETTE_SIZE
        index = y * 4 + x
        if 0 <= index < 16:
            self.compressed_state.select_colour(index)
            self.refresh_compressed_palette()

    def select_palette_command(self, _event=None):
        self.palette_state.select_command(self.palette_chooser.current())
        self.refresh_palette_command()

    def select_palette_colour(self, event):
        index = (event.y // COMMAND_SWATCH) * COMMAND_COLUMNS + event.x // COMMAND_SWATCH
        try:
            self.palette_state.select_colour(index)
        except ValueError:
            return
        self.refresh_palette_command()

    def apply_palette_channels(self):
        try:
            self.palette_state.set_channels(self.red.get(), self.green.get(), self.blue.get())
        except (ValueError, self.tk.TclError) as error:
            self.messagebox.showerror("Graphics Studio", str(error))
            return
        self.refresh_palette_command()
        self._title()
        self.palette_status.configure(text="Palette edit is not saved yet.")

    def apply_palette_word(self):
        text = self.raw_word.get().strip()
        if text.startswith("$"):
            text = text[1:]
        elif text.lower().startswith("0x"):
            text = text[2:]
        try:
            self.palette_state.set_word(int(text, 16))
        except ValueError as error:
            self.messagebox.showerror("Graphics Studio", str(error))
            return
        self.refresh_palette_command()
        self._title()
        self.palette_status.configure(text="Palette edit is not saved yet.")

    def select_mapping(self, _event=None):
        self.mapping_state.select_mapping(self.mapping_chooser.current())
        self.refresh_mapping()

    def step_mapping_piece(self, amount):
        index = max(
            0,
            min(
                self.mapping_state.piece_index + amount,
                len(self.mapping_state.pieces) - 1,
            ),
        )
        self.mapping_state.select_piece(index)
        self.refresh_mapping()

    def select_mapping_piece(self, event):
        for left, top, right, bottom, index in reversed(self.mapping_rects):
            if left <= event.x <= right and top <= event.y <= bottom:
                self.mapping_state.select_piece(index)
                self.refresh_mapping()
                return

    @staticmethod
    def parse_mapping_field(text):
        text = text.strip()
        if text.startswith("$"):
            return int(text[1:], 16)
        if text.lower().startswith("0x"):
            return int(text[2:], 16)
        return int(text, 10)

    def apply_mapping_piece(self):
        self._cancel_animation_timer()
        try:
            values = {name: self.parse_mapping_field(variable.get()) for name, variable in self.mapping_fields.items()}
            self.mapping_state.set_piece(**values)
        except ValueError as error:
            self.messagebox.showerror("Graphics Studio", str(error))
            return
        self.refresh_mapping()
        self._invalidate_animation_playback()
        self._title()
        self.mapping_status.configure(text="Mapping edit is not saved yet.")

    def select_animation(self, _event=None):
        self._invalidate_animation_playback()
        self.animation_state.select_script(self.animation_chooser.current())
        self.refresh_animation()

    def step_animation_frame(self, amount):
        index = max(
            0,
            min(
                self.animation_state.frame_index + amount,
                len(self.animation_state.frames) - 1,
            ),
        )
        self.animation_state.select_frame(index)
        self.refresh_animation()

    def apply_animation_frame(self):
        self._cancel_animation_timer()
        try:
            duration = self.parse_mapping_field(self.animation_duration.get())
            self.animation_state.set_frame(self.animation_target.get(), duration)
        except ValueError as error:
            self.messagebox.showerror("Graphics Studio", str(error))
            return
        self.refresh_animation()
        self._invalidate_animation_playback()
        self._title()
        self.animation_status.configure(text="Animation edit is not saved yet.")

    def _cancel_animation_timer(self):
        self.animation_epoch = getattr(self, "animation_epoch", 0) + 1
        token = getattr(self, "animation_after", None)
        self.animation_after = None
        if token is not None:
            self.window.after_cancel(token)
        playback = getattr(self, "animation_playback", None)
        if playback is not None:
            playback.playing = False

    def _invalidate_animation_playback(self):
        self._cancel_animation_timer()
        playback = getattr(self, "animation_playback", None)
        if playback is not None:
            playback.invalidate()
            self._show_animation_playback()

    def _prepare_animation_playback(self):
        self.animation_playback.prepare(
            self.animation_state.script["name"], self.animation_state.document, self.mapping_state.document
        )

    def _show_animation_playback(self):
        self.animation_playback_details.configure(text=self.animation_playback.details())
        draw_geometry(
            self.animation_canvas, self.animation_playback.geometry, MAPPING_CANVAS_WIDTH, ANIMATION_CANVAS_HEIGHT
        )

    def _animation_playback_error(self, error):
        self._cancel_animation_timer()
        self.animation_status.configure(text="Playback stopped: " + str(error))
        self.messagebox.showerror("Animation playback", str(error))

    def play_animation(self):
        self._cancel_animation_timer()
        try:
            self._prepare_animation_playback()
        except (OSError, ValueError) as error:
            self._animation_playback_error(error)
            return
        self.animation_playback.playing = True
        self._animation_tick(self.animation_epoch)

    def pause_animation(self):
        self._cancel_animation_timer()
        self.animation_status.configure(text="Viewer paused; source state is unchanged.")

    def step_animation(self):
        self._cancel_animation_timer()
        try:
            self._prepare_animation_playback()
            self.animation_playback.advance()
            self._show_animation_playback()
            self.animation_status.configure(text="Advanced one qualified reader invocation.")
        except (OSError, ValueError) as error:
            self._animation_playback_error(error)

    def reset_animation(self):
        self._invalidate_animation_playback()
        try:
            self._prepare_animation_playback()
            self._show_animation_playback()
            self.animation_status.configure(text="Reset to script start; timer $0000; no invocation yet.")
        except (OSError, ValueError) as error:
            self._animation_playback_error(error)

    def _animation_tick(self, epoch):
        if epoch != self.animation_epoch or not self.animation_playback.playing:
            return
        self.animation_after = None
        try:
            observed = self.animation_playback.advance()
            self._show_animation_playback()
            status = "Playing source-qualified reader invocations."
            if not self.animation_playback.playing:
                status = (
                    "Source timer holds this mapping; viewer stopped."
                    if observed.event == "hold-negative-low-byte"
                    else "4096-invocation viewer budget reached; Reset to restart."
                )
            self.animation_status.configure(text=status)
            if self.animation_playback.playing:
                self.animation_after = self.window.after(
                    ANIMATION_VIEW_INTERVAL_MS, lambda: self._animation_tick(epoch)
                )
        except (OSError, ValueError) as error:
            self._animation_playback_error(error)

    def select_gallery_record(self, _event=None):
        self.gallery_index = self.gallery_chooser.current()
        self.refresh_gallery(clear=True)

    def refresh_gallery(self, clear=False):
        record = self.gallery_records[self.gallery_index]
        self.gallery_chooser.current(self.gallery_index)
        stages = ", ".join(str(index) for index in record["stage_indices"])
        self.gallery_info.configure(
            text=(
                "Stages %s; handler %s; object type $%04X; %s entry %d"
                % (stages, record["handler"], record["object_type"], record["spawn_list"], record["placement_index"])
            )
        )
        if clear:
            self.gallery_canvas.delete("all")
            self.gallery_photo = None
            self.gallery_status.configure(text="Press Stage and preview to render this workspace state.")

    @staticmethod
    def _photo_rows(pixels):
        rows = []
        for y, line in enumerate(pixels):
            colours = []
            for x, pixel in enumerate(line):
                if pixel is None:
                    shade = 42 if (x // 8 + y // 8) % 2 else 30
                    colours.append("#%02x%02x%02x" % (shade, shade, shade))
                else:
                    colours.append("#%02x%02x%02x" % tuple(pixel))
            rows.append("{%s}" % " ".join(colours))
        return " ".join(rows)

    def preview_gallery_record(self):
        record = self.gallery_records[self.gallery_index]
        tree = self.project / "build/content/gallery" / self.profile / "tree"
        try:
            preview = stage_preview(
                self.project,
                self.profile,
                tree,
                self.level_document,
                self.state.document,
                self.compressed_state.document,
                self.palette_state.document,
                self.mapping_state.document,
                self.animation_state.document,
                record,
            )
        except (ContentError, OSError, ValueError) as error:
            self.messagebox.showerror("Object gallery", str(error))
            return

        self.gallery_canvas.delete("all")
        pixels = preview["pixels"]
        if not pixels or not pixels[0]:
            self.gallery_photo = None
            self.gallery_status.configure(
                text=(
                    "%s: %s. Attribute %s (%s)."
                    % (
                        preview["handler"],
                        preview["reason"],
                        "unknown" if preview["attribute"] is None else "$%04X" % preview["attribute"],
                        preview["attribute_evidence"],
                    )
                )
            )
            return

        height, width = len(pixels), len(pixels[0])
        photo = self.tk.PhotoImage(width=width, height=height)
        photo.put(self._photo_rows(pixels))
        scale = max(1, min(4, 480 // width, 320 // height))
        if scale > 1:
            photo = photo.zoom(scale, scale)
        self.gallery_photo = photo
        self.gallery_canvas.create_image(260, 180, image=photo, anchor="center")
        self.gallery_status.configure(
            text=(
                "%s -> %s; attribute $%04X (%s); %dx%d pixels at %dx."
                % (
                    preview["handler"],
                    preview["mapping_symbol"],
                    preview["attribute"],
                    preview["attribute_evidence"],
                    width,
                    height,
                    scale,
                )
            )
        )

    def refresh(self):
        self.chooser.current(self.state.payload_index)
        self.compressed_chooser.current(self.compressed_state.payload_index)
        self.palette_chooser.current(self.palette_state.command_index)
        self.mapping_chooser.current(self.mapping_state.mapping_index)
        self.animation_chooser.current(self.animation_state.script_index)
        self.tile_label.configure(text="tile %d / %d" % (self.state.tile_index + 1, self.state.tile_count))
        self.refresh_tile()
        self.refresh_compressed_tile()
        self.refresh_palette()
        self.refresh_palette_command()
        self.refresh_mapping()
        self.refresh_animation()
        self.refresh_gallery()
        self._title()

    def refresh_tile(self):
        self.canvas.delete("all")
        pixels = self.state.pixels()
        for y in range(TILE_SIDE):
            for x in range(TILE_SIDE):
                value = pixels[y * TILE_SIDE + x]
                left, top = x * PIXEL_SIZE, y * PIXEL_SIZE
                self.canvas.create_rectangle(
                    left, top, left + PIXEL_SIZE, top + PIXEL_SIZE, fill=index_colour(value), outline="#303030"
                )
                if PIXEL_SIZE >= 32:
                    self.canvas.create_text(
                        left + PIXEL_SIZE // 2,
                        top + PIXEL_SIZE // 2,
                        text="%X" % value,
                        fill="#ffffff" if value < 8 else "#000000",
                    )

    def refresh_compressed_tile(self):
        state = self.compressed_state
        self.compressed_chooser.current(state.payload_index)
        self.compressed_tile_label.configure(text="tile %d / %d" % (state.tile_index + 1, state.tile_count))
        self.compressed_canvas.delete("all")
        pixels = state.pixels()
        for y in range(TILE_SIDE):
            for x in range(TILE_SIDE):
                value = pixels[y * TILE_SIDE + x]
                left, top = x * PIXEL_SIZE, y * PIXEL_SIZE
                self.compressed_canvas.create_rectangle(
                    left, top, left + PIXEL_SIZE, top + PIXEL_SIZE, fill=index_colour(value), outline="#303030"
                )
                if PIXEL_SIZE >= 32:
                    self.compressed_canvas.create_text(
                        left + PIXEL_SIZE // 2,
                        top + PIXEL_SIZE // 2,
                        text="%X" % value,
                        fill="#ffffff" if value < 8 else "#000000",
                    )
        self.refresh_compressed_palette()

    def refresh_compressed_palette(self):
        state = self.compressed_state
        self.compressed_palette.delete("all")
        for index in range(16):
            x, y = (index % 4) * PALETTE_SIZE, (index // 4) * PALETTE_SIZE
            self.compressed_palette.create_rectangle(
                x,
                y,
                x + PALETTE_SIZE,
                y + PALETTE_SIZE,
                fill=index_colour(index),
                outline="#ff40ff" if index == state.colour else "#303030",
                width=3 if index == state.colour else 1,
            )
        self.compressed_colour_label.configure(text="Selected index: %X" % state.colour)

    def refresh_palette(self):
        self.palette.delete("all")
        for index in range(16):
            x, y = (index % 4) * PALETTE_SIZE, (index // 4) * PALETTE_SIZE
            self.palette.create_rectangle(
                x,
                y,
                x + PALETTE_SIZE,
                y + PALETTE_SIZE,
                fill=index_colour(index),
                outline="#ff40ff" if index == self.state.colour else "#303030",
                width=3 if index == self.state.colour else 1,
            )
        self.colour_label.configure(text="Selected index: %X" % self.state.colour)

    def refresh_palette_command(self):
        state = self.palette_state
        record = state.command
        self.palette_chooser.current(state.command_index)
        self.command_info.configure(
            text=(
                "%d colours at CRAM byte $%02X; %s in %s"
                % (record["colour_count"], record["destination"], record["storage"], record["source_path"])
            )
        )
        self.command_canvas.delete("all")
        rows = max(1, (len(state.colours) + COMMAND_COLUMNS - 1) // COMMAND_COLUMNS)
        self.command_canvas.configure(height=rows * COMMAND_SWATCH)
        for index, word in enumerate(state.colours):
            x = (index % COMMAND_COLUMNS) * COMMAND_SWATCH
            y = (index // COMMAND_COLUMNS) * COMMAND_SWATCH
            self.command_canvas.create_rectangle(
                x,
                y,
                x + COMMAND_SWATCH,
                y + COMMAND_SWATCH,
                fill=rgb_colour(word),
                outline="#ff40ff" if index == state.colour_index else "#303030",
                width=3 if index == state.colour_index else 1,
            )
            self.command_canvas.create_text(
                x + COMMAND_SWATCH // 2,
                y + COMMAND_SWATCH // 2,
                text="%X" % index,
                fill="#ffffff" if sum(cram_to_rgb(word)) < 330 else "#000000",
            )
        red, green, blue = state.channels
        self.red.set(red)
        self.green.set(green)
        self.blue.set(blue)
        self.raw_word.set("%04X" % state.word)
        self.palette_colour_label.configure(text="Colour %d / %d" % (state.colour_index + 1, len(state.colours)))

    def refresh_mapping(self):
        state = self.mapping_state
        block = state.block
        mapping = state.mapping
        self.mapping_chooser.current(state.mapping_index)
        self.mapping_info.configure(
            text=(
                "%d fixed pieces; %s; %s in %s"
                % (
                    len(state.pieces),
                    "dynamic" if mapping["dynamic"] else "static",
                    block["storage"],
                    block["payload_path"] or block["source_path"],
                )
            )
        )
        self.mapping_piece_label.configure(text="piece %d / %d" % (state.piece_index + 1, len(state.pieces)))
        piece = state.piece
        self.mapping_fields["x"].set(str(piece["x"]))
        self.mapping_fields["y"].set(str(piece["y"]))
        self.mapping_fields["attributes"].set("$%04X" % piece["attributes"])
        self.mapping_fields["size"].set("$%02X" % piece["size"])
        self.mapping_fields["link"].set("$%02X" % piece["link"])

        canvas = self.mapping_canvas
        canvas.delete("all")
        geometry = state.geometry()
        left = min([0] + [x for x, _y, _w, _h in geometry])
        top = min([0] + [y for _x, y, _w, _h in geometry])
        right = max([0] + [x + width for x, _y, width, _h in geometry])
        bottom = max([0] + [y + height for _x, y, _w, height in geometry])
        scale = min(
            3.0,
            (MAPPING_CANVAS_WIDTH - 40) / max(1, right - left),
            (MAPPING_CANVAS_HEIGHT - 40) / max(1, bottom - top),
        )
        origin_x = (MAPPING_CANVAS_WIDTH - (left + right) * scale) / 2
        origin_y = (MAPPING_CANVAS_HEIGHT - (top + bottom) * scale) / 2
        canvas.create_line(0, origin_y, MAPPING_CANVAS_WIDTH, origin_y, fill="#505050")
        canvas.create_line(origin_x, 0, origin_x, MAPPING_CANVAS_HEIGHT, fill="#505050")
        self.mapping_rects = []
        for index, (x, y, width, height) in enumerate(geometry):
            x0, y0 = origin_x + x * scale, origin_y + y * scale
            x1, y1 = x0 + width * scale, y0 + height * scale
            selected = index == state.piece_index
            canvas.create_rectangle(
                x0,
                y0,
                x1,
                y1,
                fill="#4b6f8f" if not selected else "#8f4b80",
                outline="#d0d0d0" if not selected else "#ff60e0",
                width=1 if not selected else 3,
            )
            canvas.create_text(
                (x0 + x1) / 2,
                (y0 + y1) / 2,
                text=str(index),
                fill="#ffffff",
            )
            self.mapping_rects.append((x0, y0, x1, y1, index))

    def refresh_animation(self):
        state = self.animation_state
        frame = state.frame
        self.animation_chooser.current(state.script_index)
        self.animation_info.configure(
            text=(
                "%d fixed slots in %s; current role: %s"
                % (
                    len(state.frames),
                    state.script["source_path"],
                    "zero-duration jump" if frame["jump"] else "timed frame",
                )
            )
        )
        self.animation_frame_label.configure(text="frame %d / %d" % (state.frame_index + 1, len(state.frames)))
        self.animation_target_chooser.configure(values=state.target_options)
        self.animation_target.set(frame["target"])
        self.animation_duration.set(str(frame["duration"]))

    def save(self):
        try:
            validate_tile_document(self.state.document, self.project, self.profile)
            validate_compressed_document(self.compressed_state.document, self.project, self.profile)
            validate_palette_document(self.palette_state.document, self.project, self.profile)
            validate_mapping_document(self.mapping_state.document, self.project, self.profile)
            validate_animation_document(self.animation_state.document, self.project, self.profile)
            write_tile_document(self.tile_path, self.state.document)
            write_compressed_document(self.compressed_path, self.compressed_state.document)
            write_palette_document(self.palette_path, self.palette_state.document)
            write_mapping_document(self.mapping_path, self.mapping_state.document)
            write_animation_document(self.animation_path, self.animation_state.document)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Graphics Studio", str(error))
            return False
        self.state.dirty = False
        self.compressed_state.dirty = False
        self.palette_state.dirty = False
        self.mapping_state.dirty = False
        self.animation_state.dirty = False
        detail = "Saved all graphics documents with atomic replacement."
        self.status.configure(text=detail)
        self.compressed_status.configure(text=detail)
        self.palette_status.configure(text=detail)
        self.mapping_status.configure(text=detail)
        self.animation_status.configure(text=detail)
        self._title()
        return True

    def reload(self):
        if (
            self.state.dirty
            or self.compressed_state.dirty
            or self.palette_state.dirty
            or self.mapping_state.dirty
            or self.animation_state.dirty
        ) and not self.messagebox.askyesno("Graphics Studio", "Discard unsaved workspace edits?"):
            return
        self._invalidate_animation_playback()
        try:
            tile_document = load_tile_document(self.tile_path)
            compressed_document = load_compressed_document(self.compressed_path, self.project, self.profile)
            palette_document = load_palette_document(self.palette_path)
            mapping_document = load_mapping_document(self.mapping_path)
            animation_document = load_animation_document(self.animation_path)
            level_document = load_level_document(self.level_path)
            validate_tile_document(tile_document, self.project, self.profile)
            validate_compressed_document(compressed_document, self.project, self.profile)
            validate_palette_document(palette_document, self.project, self.profile)
            validate_mapping_document(mapping_document, self.project, self.profile)
            validate_animation_document(animation_document, self.project, self.profile)
            validate_level_document(level_document, self.project, self.profile)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Graphics Studio", str(error))
            return
        payload = self.state.payload_index
        compressed_payload = self.compressed_state.payload_index
        command = self.palette_state.command_index
        mapping = self.mapping_state.mapping_index
        animation = self.animation_state.script_index
        gallery = self.gallery_index
        self.state = Workspace(tile_document, payload_index=payload)
        self.compressed_state = Workspace(compressed_document, payload_index=compressed_payload)
        self.palette_state = PaletteWorkspace(palette_document, command_index=command)
        self.mapping_state = MappingWorkspace(mapping_document, mapping_index=mapping)
        self.animation_state = AnimationWorkspace(animation_document, script_index=animation)
        self.level_document = level_document
        self.gallery_records = catalogue(level_document, mapping_document, animation_document)
        self.gallery_index = min(gallery, len(self.gallery_records) - 1)
        self.gallery_chooser.configure(values=gallery_choices(self.gallery_records))
        self.gallery_photo = None
        self.refresh()
        self.status.configure(text="Workspace reloaded.")
        self.compressed_status.configure(text="Workspace reloaded.")
        self.palette_status.configure(text="Workspace reloaded.")
        self.mapping_status.configure(text="Workspace reloaded.")
        self.animation_status.configure(text="Workspace reloaded.")

    def build_rom(self):
        if not self.save():
            return
        try:
            result = subprocess.run(
                ["make", "--no-print-directory", "build-content", "CONTENT_PROFILE=%s" % self.profile],
                cwd=self.project,
                text=True,
                capture_output=True,
                check=False,
            )
        except OSError as error:
            self.messagebox.showerror("Content build failed", "Cannot launch content build: " + str(error))
            self.status.configure(text="Content build could not be launched.")
            return
        detail = (result.stdout + result.stderr).strip()
        if result.returncode:
            self.messagebox.showerror("Content build failed", detail)
        else:
            self.messagebox.showinfo("Content build complete", detail)

    def _title(self):
        self.window.title(
            "%sAlien Soldier - Graphics Studio (%s)"
            % (
                "*"
                if (
                    self.state.dirty
                    or self.compressed_state.dirty
                    or self.palette_state.dirty
                    or self.mapping_state.dirty
                    or self.animation_state.dirty
                )
                else "",
                self.profile.upper(),
            )
        )

    def close(self):
        if (
            self.state.dirty
            or self.compressed_state.dirty
            or self.palette_state.dirty
            or self.mapping_state.dirty
            or self.animation_state.dirty
        ):
            answer = self.messagebox.askyesnocancel("Graphics Studio", "Save workspace edits before closing?")
            if answer is None:
                return
            if answer and not self.save():
                return
        self._cancel_animation_timer()
        self.window.destroy()

    def run(self):
        self.window.mainloop()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--payload", type=int, default=0)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    project = Path(args.root).resolve()
    try:
        (
            tile_path,
            tile_document,
            compressed_path,
            compressed_document,
            palette_path,
            palette_document,
            mapping_path,
            mapping_document,
            animation_path,
            animation_document,
            level_path,
            level_document,
        ) = load_context(project, args.profile)
        state = Workspace(tile_document)
        compressed_state = Workspace(compressed_document)
        palette_state = PaletteWorkspace(palette_document)
        mapping_state = MappingWorkspace(mapping_document)
        animation_state = AnimationWorkspace(animation_document)
        gallery_records = catalogue(level_document, mapping_document, animation_document)
        state.select_payload(args.payload)
        if args.check:
            validate_tile_document(state.document, project, args.profile)
            validate_compressed_document(compressed_state.document, project, args.profile)
            validate_palette_document(palette_state.document, project, args.profile)
            validate_mapping_document(mapping_state.document, project, args.profile)
            validate_animation_document(animation_state.document, project, args.profile)
            validate_level_document(level_document, project, args.profile)
            gallery_summary = survey(gallery_records)
            print(
                "[OK] %s Graphics Studio: %d tile payloads; "
                "%d compressed tile payloads; "
                "%d palette commands; %d sprite mappings; %d animations; "
                "%d gallery placements"
                % (
                    args.profile,
                    len(state.payloads),
                    len(compressed_state.payloads),
                    len(palette_state.commands),
                    len(mapping_state.entries),
                    len(animation_state.scripts),
                    gallery_summary["placements"],
                )
            )
            return 0
        import tkinter as tk
        from tkinter import messagebox, ttk

        Window(
            project,
            args.profile,
            tile_path,
            tile_document,
            compressed_path,
            compressed_document,
            palette_path,
            palette_document,
            mapping_path,
            mapping_document,
            animation_path,
            animation_document,
            level_path,
            level_document,
            args.payload,
            tk,
            ttk,
            messagebox,
        ).run()
        return 0
    except (ContentError, ImportError, OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
