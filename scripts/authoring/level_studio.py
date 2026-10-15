#!/usr/bin/env python3
"""Open the profile-bound Alien Soldier Level Studio workstation."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from copy import deepcopy
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.content_workspace import (  # noqa: E402
    ContentError, artifact_path, checked_path, load_manifest)
from authoring.level_studio_model import (  # noqa: E402
    CONFIG_FIELDS, atomic_write_json, load_document, read_configurations,
    validate_document)
from authoring.level_studio_state import (  # noqa: E402
    EDITABLE_FIELDS, MAP_PAGE_STEP, MAP_VIEW_HEIGHT, MAP_VIEW_WIDTH,
    locate_stage_map_cell, open_stage, overlay_placements,
    sprite_library, stage_rows, validate_stage_scene_references)
from authoring.stage4_boss_renderer import (  # noqa: E402
    SniperHoneyviperPose, draw_sniper_honeyviper_background)
from authoring.joker_boss_renderer import (  # noqa: E402
    JokerRasterPose, draw_joker_raster_background)
from authoring.madam_barbar_boss_renderer import (  # noqa: E402
    MadamBarbarPose, draw_madam_barbar_background)
from authoring.ram_map_state import Workspace as MapWorkspace, parse_value  # noqa: E402
from authoring.screen_map_model import (  # noqa: E402
    export_document as export_screen_maps,
    load_document as load_screen_maps,
    validate_document as validate_screen_maps,
)
from authoring.stage_map_model import (  # noqa: E402
    export_document as export_maps,
    load_document as load_maps,
    validate_document as validate_maps,
)
from authoring.tile_graphics import write_png  # noqa: E402
from authoring.stage_tilemap_model import parsed_operation  # noqa: E402


MANIFEST = "config/authoring/content_studios.json"
BOSS_REFERENCES = {
    3: ("config/authoring/stage4_boss_jp_fidelity.json", "captures"),
    4: ("config/authoring/stage5_6_jp_fidelity.json", "madam_barbar_captures"),
    5: ("config/authoring/stage5_6_jp_fidelity.json", "joker_raster_captures"),
}
VIEW_WIDTH = MAP_VIEW_WIDTH
VIEW_HEIGHT = MAP_VIEW_HEIGHT
MAX_RENDER_WIDTH = 2048
PAGE_STEP = MAP_PAGE_STEP
MARKER_RADIUS = 5
SELECTED = "#ff40ff"
UNSELECTED = "#40e0ff"
LABEL_COLOUR = "#e8e8e8"


def level_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "level_layouts")


def map_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "stage_maps")


def screen_map_artifact(manifest):
    return next(item for item in manifest["artifacts"] if item["id"] == "screen_maps")


def load_context(project: Path, profile: str):
    with parsed_operation(project):
        return _load_context(project, profile)


def _load_context(project: Path, profile: str):
    manifest = load_manifest(checked_path(project, MANIFEST), project)
    path = artifact_path(project, manifest, profile, level_artifact(manifest))
    map_path = artifact_path(project, manifest, profile, map_artifact(manifest))
    screen_path = artifact_path(
        project, manifest, profile, screen_map_artifact(manifest))
    document = load_document(path)
    maps = load_maps(map_path)
    screen_maps = load_screen_maps(screen_path)
    validate_document(document, project, profile)
    validate_maps(maps, project, profile)
    validate_screen_maps(screen_maps, project, profile)
    return (manifest, path, document, map_path, maps, export_maps(project, profile),
            screen_path, screen_maps, export_screen_maps(project, profile))


def render_view(studio, directory: Path, start_x=0, width=VIEW_WIDTH, library=None):
    """Render one bounded viewport, never a whole multi-screen stage."""
    start_x = max(0, min(start_x, max(0, studio.width - 1)))
    width = min(width, studio.width - start_x)
    image = studio.image(start_x, 0, width, VIEW_HEIGHT)
    drawn = overlay_placements(studio, image, start_x, 0, library)
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / "viewport.png"
    write_png(path, image, compression=1)
    return path, set(drawn), width


def boss_reference_captures(project: Path, profile: str, stage_index: int) -> tuple:
    """List only the JP boss poses with pinned source/screenshot evidence."""
    if profile != "jp" or stage_index not in BOSS_REFERENCES:
        return ()
    fixture_path, key = BOSS_REFERENCES[stage_index]
    fixture = json.loads((project / fixture_path).read_text(encoding="utf-8"))
    return tuple(fixture[key])


def render_boss_reference(
        project: Path, profile: str, stage_index: int,
        displayed_frame: int,
) -> list[list[tuple[int, int, int]]]:
    """Render a pinned JP preservation pose; never read workspace edits."""
    captures = boss_reference_captures(project, profile, stage_index)
    capture = next(
        (item for item in captures
         if item["displayed_frame"] == displayed_frame), None)
    if capture is None:
        raise ValueError("no supported JP boss reference for this frame")
    if stage_index == 3:
        return draw_sniper_honeyviper_background(
            project, SniperHoneyviperPose(**capture["pose"]))
    if stage_index == 4:
        return draw_madam_barbar_background(
            project, MadamBarbarPose(**capture["pose"]))
    return draw_joker_raster_background(
        project, JokerRasterPose(**capture["pose"]))


def playtest_make_command(profile: str, stage_index: int) -> list[str]:
    if not 0 <= stage_index < 25:
        raise ValueError("only password-selectable stage slots 0..24 can be playtested")
    return [
        "make", "--no-print-directory", "playtest-level",
        "CONTENT_PROFILE=%s" % profile,
        "PLAYTEST_STAGE=%d" % (stage_index + 1),
    ]


class Window:
    """Thin Tk shell over the tested workspace and renderer models."""

    def __init__(self, project, profile, path, document, map_path, maps,
                 map_baseline, screen_path, screen_maps, screen_baseline,
                 stage, tk, ttk, messagebox):
        self.project = project
        self.profile = profile
        self.path = path
        self.document = document
        self.map_path = map_path
        self.map_state = MapWorkspace(maps)
        self.map_baseline = map_baseline
        self.screen_path = screen_path
        self.screen_maps = screen_maps
        self.screen_baseline = screen_baseline
        self.map_choices = []
        self.tk = tk
        self.ttk = ttk
        self.messagebox = messagebox
        self.studio = None
        self.photo = None
        self.markers = {}
        self.placement_fields = {}
        self.configuration_fields = {}
        self.route_names = [item["name"] for item in read_configurations(project)[0]]
        self.page_x = 0
        self.viewport_cell = None
        self.viewport_cell_plane = "plane_a"
        self.dirty = False
        self.library = sprite_library(project)

        self.window = tk.Tk()
        self.window.geometry("1280x650")
        self.window.protocol("WM_DELETE_WINDOW", self.close)
        self._build_toolbar()
        self._build_canvas()
        self._build_panel()
        self.load(stage, fold_current=False)

    def _build_toolbar(self):
        bar = self.ttk.Frame(self.window, padding=(8, 6))
        bar.pack(side="top", fill="x")
        self.ttk.Label(bar, text="Stage").pack(side="left")
        self.choice = self.tk.StringVar()
        self.chooser = self.ttk.Combobox(
            bar, textvariable=self.choice, state="readonly", width=70)
        self.chooser.pack(side="left", padx=8)
        self.chooser.bind("<<ComboboxSelected>>",
                          lambda _: self.load(self.chooser.current()))
        self.ttk.Button(bar, text="Save", command=self.save).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Reload", command=self.reload).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Refresh other maps",
                        command=self.refresh_peer_maps).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Build ROM", command=self.build_rom).pack(
            side="left", padx=2)
        self.ttk.Button(bar, text="Playtest", command=self.playtest).pack(
            side="left", padx=2)
        self.boss_reference_button = self.ttk.Button(
            bar, text="JP boss reference", command=self.show_boss_reference)
        self.boss_reference_button.pack(side="left", padx=2)
        self.status = self.ttk.Label(bar, text="")
        self.status.pack(side="left", padx=10)

    def _build_canvas(self):
        holder = self.ttk.Frame(self.window)
        holder.pack(side="left", fill="both", expand=True)
        pager = self.ttk.Frame(holder, padding=(8, 4))
        pager.pack(side="top", fill="x")
        self.ttk.Button(pager, text="Previous screen", command=lambda: self.page(-1)).pack(
            side="left")
        self.page_label = self.ttk.Label(pager, text="")
        self.page_label.pack(side="left", padx=12)
        self.ttk.Button(pager, text="Next screen", command=lambda: self.page(1)).pack(
            side="left")
        self.canvas = self.tk.Canvas(
            holder, width=VIEW_WIDTH, height=VIEW_HEIGHT, background="#101014",
            highlightthickness=0)
        self.canvas.pack(side="top", fill="both", expand=True)
        self.canvas.bind("<Button-1>", self.on_click)
        self.window.bind("<Left>", lambda _: self.nudge("x", -8))
        self.window.bind("<Right>", lambda _: self.nudge("x", 8))
        self.window.bind("<Up>", lambda _: self.nudge("y", -8))
        self.window.bind("<Down>", lambda _: self.nudge("y", 8))

    def _build_panel(self):
        panel = self.ttk.Frame(self.window, padding=(10, 10))
        panel.pack(side="right", fill="y")
        notebook = self.ttk.Notebook(panel)
        notebook.pack(fill="both", expand=True)
        placements = self.ttk.Frame(notebook, padding=8)
        configuration = self.ttk.Frame(notebook, padding=8)
        maps = self.ttk.Frame(notebook, padding=8)
        notebook.add(placements, text="Placement")
        notebook.add(configuration, text="Stage config")
        notebook.add(maps, text="Map values")

        self.handler = self.ttk.Label(placements, text="nothing selected", wraplength=260)
        self.handler.grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 8))
        for row, field in enumerate(EDITABLE_FIELDS, start=1):
            self.ttk.Label(placements, text=field).grid(row=row, column=0, sticky="w")
            entry = self.ttk.Entry(placements, width=18)
            entry.grid(row=row, column=1, sticky="w", pady=1)
            entry.bind("<Return>", lambda _, name=field: self.apply_placement(name))
            self.placement_fields[field] = entry
        self.ttk.Button(placements, text="Apply all", command=self.apply_all).grid(
            row=len(EDITABLE_FIELDS) + 1, column=0, columnspan=2,
            sticky="we", pady=(10, 0))

        for row, (field, size) in enumerate(CONFIG_FIELDS):
            self.ttk.Label(configuration, text="%s (dc.%s)" % (field, size)).grid(
                row=row, column=0, sticky="w")
            entry = self.ttk.Entry(configuration, width=28)
            entry.grid(row=row, column=1, sticky="w", pady=1)
            self.configuration_fields[field] = entry
        self.ttk.Button(
            configuration, text="Apply shared configuration",
            command=self.apply_configuration).grid(
                row=len(CONFIG_FIELDS), column=0, columnspan=2,
                sticky="we", pady=(10, 0))
        route_row = len(CONFIG_FIELDS) + 1
        self.ttk.Label(configuration, text="Plain stage route").grid(
            row=route_row, column=0, sticky="w", pady=(12, 0))
        self.route_box = self.ttk.Combobox(
            configuration, values=self.route_names, state="disabled", width=38)
        self.route_box.grid(row=route_row, column=1, sticky="w", pady=(12, 0))
        self.route_button = self.ttk.Button(
            configuration, text="Apply route", command=self.apply_stage_route)
        self.route_button.grid(
            row=route_row + 1, column=0, columnspan=2, sticky="we")
        self._build_map_panel(maps)
        self.note = self.ttk.Label(panel, wraplength=300, foreground="#806000", text="")
        self.note.pack(fill="x", pady=(8, 0))

    def _build_map_panel(self, panel):
        self.map_box = self.ttk.Combobox(panel, state="readonly", width=38)
        self.map_box.pack(fill="x")
        self.map_box.bind("<<ComboboxSelected>>",
                          lambda _: self.select_map(self.map_box.current()))
        self.map_details = self.ttk.Label(panel, text="", wraplength=275)
        self.map_details.pack(fill="x", pady=(5, 6))
        controls = self.ttk.Frame(panel)
        controls.pack(fill="x")
        self.ttk.Label(controls, text="Index").grid(row=0, column=0, sticky="w")
        self.map_index_text = self.tk.StringVar(value="0")
        index = self.ttk.Entry(controls, textvariable=self.map_index_text, width=10)
        index.grid(row=0, column=1, sticky="w")
        index.bind("<Return>", lambda _: self.select_map_value())
        self.ttk.Button(controls, text="Go", command=self.select_map_value).grid(
            row=0, column=2, padx=3)
        self.ttk.Label(controls, text="Value").grid(row=1, column=0, sticky="w")
        self.map_value_text = self.tk.StringVar()
        value = self.ttk.Entry(controls, textvariable=self.map_value_text, width=10)
        value.grid(row=1, column=1, sticky="w")
        value.bind("<Return>", lambda _: self.apply_map_value())
        self.ttk.Button(controls, text="Apply", command=self.apply_map_value).grid(
            row=1, column=2, padx=3)
        self.map_location = self.ttk.Label(panel, text="")
        self.map_location.pack(anchor="w", pady=(5, 0))
        navigation = self.ttk.Frame(panel)
        navigation.pack(fill="x", pady=(4, 0))
        self.ttk.Button(navigation, text="Previous unit",
                        command=lambda: self.step_map_unit(-1)).pack(side="left")
        self.ttk.Button(navigation, text="Next unit",
                        command=lambda: self.step_map_unit(1)).pack(side="left", padx=4)
        self.map_paint = self.tk.BooleanVar(value=False)
        self.ttk.Checkbutton(panel, text="Paint with value above (both views)",
                             variable=self.map_paint).pack(anchor="w")
        self.viewport_map_enabled = self.tk.BooleanVar(value=False)
        self.ttk.Checkbutton(panel, text="Pick selected plane map from stage preview",
                             variable=self.viewport_map_enabled).pack(anchor="w")
        self.viewport_map_plane = self.tk.StringVar(value="plane_a")
        self.ttk.Combobox(
            panel, textvariable=self.viewport_map_plane, state="readonly",
            values=("plane_a", "plane_b"), width=14).pack(anchor="w")
        self.viewport_map_role = self.tk.StringVar(value="chunks")
        self.ttk.Combobox(
            panel, textvariable=self.viewport_map_role, state="readonly",
            values=("patterns", "chunks", "coarse"), width=14).pack(anchor="w")
        self.ttk.Label(panel, text="Raw map values, not screen colours").pack(anchor="w")
        self.map_canvas = self.tk.Canvas(
            panel, width=256, height=256, background="#101014", highlightthickness=0)
        self.map_canvas.pack(anchor="w", pady=(4, 0))
        self.map_canvas.bind("<Button-1>", self.click_map_cell)

    def refresh_map_choices(self):
        self.map_choices = [
            index for index, record in enumerate(self.map_state.payloads)
            if any(use["stage_table_index"] == self.studio.index
                   for use in record["uses"])
        ]
        names = [self.map_state.payloads[index]["name"]
                 for index in self.map_choices]
        self.map_box.configure(values=names)
        if not names:
            self.map_box.set("")
            self.map_details.configure(text="No default-descriptor maps in this stage")
            self.map_canvas.delete("all")
            return
        selected = (self.map_choices.index(self.map_state.payload_index)
                    if self.map_state.payload_index in self.map_choices else 0)
        self.select_map(selected)

    def select_map(self, local_index):
        if not 0 <= local_index < len(self.map_choices):
            return
        self.map_state.select_payload(self.map_choices[local_index])
        self.map_box.current(local_index)
        record = self.map_state.payload
        self.map_details.configure(text=(
            "%s; %d-bit values; %d entries\n%d decoded / %d compressed bytes\n"
            "Shared by %d stage slot(s)"
            % (record["role"], record["value_bits"], record["value_count"],
               record["decoded_byte_count"], record["compressed_capacity"],
               len({use["stage_table_index"] for use in record["uses"]}))
        ))
        self.map_index_text.set("0")
        self.show_map_value()

    def select_map_value(self):
        if not self.map_choices:
            return
        try:
            self.map_state.select_value(int(self.map_index_text.get(), 0))
        except ValueError as error:
            self.messagebox.showerror("Level map", str(error))
            return
        self.show_map_value()

    def show_map_value(self):
        if not self.map_choices:
            return
        place = self.map_state.location()
        digits = self.map_state.payload["value_bits"] // 4
        self.map_value_text.set("$%0*X" % (digits, self.map_state.value))
        self.map_index_text.set(str(self.map_state.value_index))
        self.map_location.configure(
            text="Unit {unit}; x {x}; y {y}".format(**place))
        self.draw_map_unit()

    def draw_map_unit(self):
        self.map_canvas.delete("all")
        payload = self.map_state.payload
        width, height = payload["unit_width"], payload["unit_height"]
        cell_width, cell_height = 256 // width, 256 // height
        place = self.map_state.location()
        for index, value in enumerate(self.map_state.unit_values(place["unit"])):
            x, y = index % width, index // width
            shade = 32 + (value & 0xFF) * 3 // 4 if value is not None else 16
            self.map_canvas.create_rectangle(
                x * cell_width, y * cell_height,
                (x + 1) * cell_width, (y + 1) * cell_height,
                fill="#%02x%02x%02x" % (shade, shade, shade),
                outline="#ffdf64" if (x, y) == (place["x"], place["y"])
                else "#505058")
            if value is not None and width <= 8:
                self.map_canvas.create_text(
                    x * cell_width + cell_width // 2,
                    y * cell_height + cell_height // 2,
                    text="%0*X" % (payload["value_bits"] // 4, value),
                    fill="#ffffff" if shade < 128 else "#101014")

    def step_map_unit(self, delta):
        if not self.map_choices:
            return
        unit = max(0, min(self.map_state.unit_count - 1,
                          self.map_state.location()["unit"] + delta))
        self.map_state.select_cell(unit, 0, 0)
        self.show_map_value()

    def _commit_map_edit(self, value):
        previous = self.map_state.value

        def validate_and_preview(document):
            validate_maps(document, self.project, self.profile)
            prior_scene = self.studio.scene
            try:
                self.studio.refresh_map_preview(
                    document, self.map_baseline,
                    self.screen_maps, self.screen_baseline)
                validate_stage_scene_references(
                    self.studio.source_scene, self.studio.scene,
                    self.studio.width, self.studio.index, self.profile)
            except ValueError:
                self.studio.scene = prior_scene
                raise

        self.map_state.replace_value(
            value, validate_and_preview)
        if value != previous:
            self._changed("Map edit is not saved yet; preview uses workspace values.")
            self.render()
            self.show_selection()

    def apply_map_value(self):
        if not self.map_choices:
            return
        try:
            self.map_state.select_value(int(self.map_index_text.get(), 0))
            value = parse_value(self.map_value_text.get(),
                                self.map_state.payload["value_bits"])
            self._commit_map_edit(value)
        except ValueError as error:
            self.messagebox.showerror("Level map", str(error))
        self.show_map_value()

    def click_map_cell(self, event):
        if not self.map_choices:
            return
        brush = self.map_value_text.get()
        try:
            self.map_state.select_pixel(self.map_state.location()["unit"],
                                        event.x, event.y)
            if self.map_paint.get():
                value = parse_value(brush, self.map_state.payload["value_bits"])
                self._commit_map_edit(value)
        except ValueError as error:
            self.messagebox.showerror("Level map", str(error))
        self.show_map_value()
        if self.map_paint.get():
            self.map_value_text.set(brush)

    def _rows(self):
        return stage_rows(self.project, self.document)

    def _chooser_values(self):
        return ["%2d  %-22s %3d objects  %s" % (
            row["index"], row["record"], row["placements"], row["palette"])
                for row in self._rows()]

    def _fold_current(self):
        if self.studio is not None:
            self.document = self.studio.document()

    def load(self, index, fold_current=True):
        if fold_current:
            self._fold_current()
        values = self._chooser_values()
        self.chooser.configure(values=values)
        self.studio = open_stage(
            self.project, index, profile=self.profile, document=self.document,
            map_document=self.map_state.document, map_baseline=self.map_baseline,
            screen_document=self.screen_maps, screen_baseline=self.screen_baseline)
        self.viewport_cell = None
        self.choice.set(values[index])
        self.boss_reference_button.configure(
            state=("normal" if boss_reference_captures(
                self.project, self.profile, index) else "disabled"))
        self.page_x = min(self.page_x, max(0, self.studio.width - VIEW_WIDTH))
        self.refresh_map_choices()
        self.render()
        self.show_selection()
        self.show_configuration()
        self._title()

    def show_boss_reference(self):
        """Show a bounded preservation-source pose outside the edit viewport."""
        stage_index = self.studio.index
        captures = boss_reference_captures(
            self.project, self.profile, stage_index)
        if not captures:
            raise ValueError("no JP boss reference for this stage")
        popup = self.tk.Toplevel(self.window)
        popup.title("JP preservation boss reference (read-only)")
        self.ttk.Label(
            popup, text="Canonical JP source; workspace edits are not shown. "
                        "HUD and sprites are excluded."
        ).pack(padx=8, pady=8)
        selected = self.tk.StringVar(value=str(captures[0]["displayed_frame"]))
        chooser = self.ttk.Combobox(
            popup, textvariable=selected, state="readonly",
            values=[str(item["displayed_frame"]) for item in captures])
        chooser.pack(padx=8, pady=4)
        picture = self.ttk.Label(popup)
        picture.pack(padx=8, pady=8)

        def refresh(_event=None):
            try:
                frame = int(selected.get())
                image = render_boss_reference(
                    self.project, self.profile, stage_index, frame)
                output = (self.project / "build/studio" / self.profile
                          / "boss_reference.png")
                output.parent.mkdir(parents=True, exist_ok=True)
                write_png(output, image, compression=1)
                photo = self.tk.PhotoImage(file=str(output))
                picture.configure(image=photo)
                picture.image = photo
            except (OSError, ValueError) as error:
                self.messagebox.showerror("Boss reference", str(error))

        chooser.bind("<<ComboboxSelected>>", refresh)
        refresh()
        return popup

    def render(self):
        path, self.drawn, width = render_view(
            self.studio, self.project / "build/studio" / self.profile,
            self.page_x, VIEW_WIDTH, self.library)
        self.photo = self.tk.PhotoImage(file=str(path))
        self.canvas.delete("all")
        self.canvas.create_image(0, 0, anchor="nw", image=self.photo)
        self.canvas.configure(scrollregion=(0, 0, width, VIEW_HEIGHT))
        self.show_viewport_map_highlight()
        self.markers = {}
        for placement in self.studio.placements:
            if self.page_x - 24 <= placement.map_x < self.page_x + width + 24:
                self.draw_marker(placement)
        self.page_label.configure(
            text="$%X-$%X of $%X" % (
                self.page_x, self.page_x + width - 1, self.studio.width - 1))
        self.status.configure(text="%s: %d objects, %d px" % (
            self.studio.spawn_list_name or "no spawn list",
            len(self.studio.placements), self.studio.width))

    def page(self, direction):
        self.page_x = max(0, min(
            self.page_x + direction * PAGE_STEP,
            max(0, self.studio.width - VIEW_WIDTH)))
        self.render()
        self.show_selection()

    def draw_marker(self, placement):
        x, y = placement.map_x - self.page_x, placement.map_y
        radius = MARKER_RADIUS if placement.index in self.drawn else MARKER_RADIUS * 2
        oval = self.canvas.create_oval(
            x - radius, y - radius, x + radius, y + radius,
            outline=UNSELECTED, width=2)
        text = self.canvas.create_text(
            x + 8, y - 10, anchor="w", fill=LABEL_COLOUR,
            font=("TkFixedFont", 7),
            text=placement.handler or "type $%X" % placement.entry.object_type)
        self.markers[placement.index] = (oval, text)

    def on_click(self, event):
        if self.viewport_map_enabled.get():
            self.click_viewport_map(event)
            return
        self.studio.select_at(int(event.x) + self.page_x, int(event.y))
        self.show_selection()

    def show_viewport_map_highlight(self):
        self.canvas.delete("map-hit")
        if self.viewport_cell is None:
            return
        cell = self.viewport_cell
        plane_name = getattr(self, "viewport_cell_plane", "plane_a")
        plane = (self.studio.scene.tilemap if plane_name == "plane_a"
                 else self.studio.scene.plane_b)
        if plane is None:
            return
        camera_x = (self.page_x if plane_name == "plane_a"
                    else self.studio.scene.parallax_x(self.page_x))
        size = {"patterns": 8, "chunks": 32, "coarse": 256}[cell.role]
        x = cell.world_x // size * size - camera_x
        y = ((cell.world_y + plane.y_offset) // size * size
             - plane.y_offset)
        wrap = (self.studio.scene.plane_b_wrap_pixels
                if plane_name == "plane_b" else 0)
        if wrap:
            x %= wrap
            visible_width = min(VIEW_WIDTH, self.studio.width - self.page_x)
            positions = range(x - wrap, visible_width, wrap)
        else:
            positions = (x,)
        for left in positions:
            if wrap and left + size <= 0:
                continue
            self.canvas.create_rectangle(
                left, y, left + size, y + size, outline="#ffdf64", width=2,
                tags="map-hit")

    def click_viewport_map(self, event):
        brush = self.map_value_text.get()
        previous = self.viewport_cell
        previous_plane = getattr(self, "viewport_cell_plane", "plane_a")
        try:
            local_x, y = int(event.x), int(event.y)
            if (not 0 <= local_x < min(VIEW_WIDTH, self.studio.width - self.page_x)
                    or not 0 <= y < VIEW_HEIGHT):
                raise ValueError("point is outside the rendered stage viewport")
            plane_name = (self.viewport_map_plane.get()
                          if hasattr(self, "viewport_map_plane") else "plane_a")
            hit = locate_stage_map_cell(
                self.studio, self.map_state.document,
                local_x + self.page_x, y, self.viewport_map_role.get(),
                plane_name, self.page_x)
            if hit.payload_index not in self.map_choices:
                raise ValueError("source map is not offered for this stage")
            self.select_map(self.map_choices.index(hit.payload_index))
            self.map_state.select_value(hit.value_index)
            self.viewport_cell = hit
            self.viewport_cell_plane = plane_name
            if self.map_paint.get():
                value = parse_value(brush, self.map_state.payload["value_bits"])
                self._commit_map_edit(value)
        except ValueError as error:
            self.viewport_cell = previous
            self.viewport_cell_plane = previous_plane
            self.messagebox.showerror("Level map", str(error))
        self.show_map_value()
        self.show_viewport_map_highlight()
        if self.map_paint.get():
            self.map_value_text.set(brush)

    def show_selection(self):
        for index, (oval, _) in self.markers.items():
            selected = index == self.studio.selection
            self.canvas.itemconfigure(
                oval, outline=SELECTED if selected else UNSELECTED,
                width=3 if selected else 2)
        placement = self.studio.selected()
        description = "nothing selected"
        if placement:
            description = "#%d  %s" % (placement.index, placement.describe())
            trigger_x = self.studio.spawn_trigger_x(placement.index)
            if trigger_x != placement.entry.x:
                description += "  (spawn gate X=$%X)" % trigger_x
        self.handler.configure(
            text=description)
        for field, entry in self.placement_fields.items():
            entry.delete(0, "end")
            if placement:
                entry.insert(0, "$%X" % getattr(placement.entry, field))

    def show_configuration(self):
        configuration = self.studio.configuration
        for field, entry in self.configuration_fields.items():
            entry.delete(0, "end")
            if configuration is None:
                continue
            value = configuration.fields[field]
            entry.insert(0, value if isinstance(value, str) else "$%X" % value)
        self.route_box.set(configuration.name if configuration is not None else "")
        enabled = bool(configuration and self.studio.route_editable)
        self.route_box.configure(state="readonly" if enabled else "disabled")
        self.route_button.configure(state="normal" if enabled else "disabled")

    def _changed(self, message):
        self.dirty = True
        self.note.configure(text=message)
        self._title()

    def apply_placement(self, field, redraw=True):
        placement = self.studio.selected()
        if placement is None:
            return False
        try:
            self.studio.set_field(
                placement.index, field, self.placement_fields[field].get())
        except ValueError as error:
            self.status.configure(text=str(error))
            return False
        self._fold_current()
        self._changed("Workspace edit is not saved yet.")
        if redraw:
            self.render()
            self.show_selection()
        return True

    def apply_all(self):
        placement = self.studio.selected()
        if placement is None:
            return
        values = {field: self.placement_fields[field].get()
                  for field in EDITABLE_FIELDS}
        try:
            self.studio.set_fields(placement.index, values)
        except ValueError as error:
            self.status.configure(text=str(error))
            return
        self._fold_current()
        self._changed("Workspace edit is not saved yet.")
        self.render()
        self.show_selection()

    def nudge(self, field, amount):
        placement = self.studio.selected()
        if placement is None:
            return
        value = max(0, min(0xFFFF, getattr(placement.entry, field) + amount))
        self.placement_fields[field].delete(0, "end")
        self.placement_fields[field].insert(0, "$%X" % value)
        self.apply_placement(field)

    def apply_configuration(self):
        values = {field: entry.get()
                  for field, entry in self.configuration_fields.items()}
        try:
            self.studio.set_configuration_fields(values)
        except (ValueError, StopIteration) as error:
            self.status.configure(text=str(error))
            return
        index = self.studio.index
        self._fold_current()
        self._changed(
            "The shared configuration changed; every stage that names it will use it.")
        self.load(index, fold_current=False)

    def apply_stage_route(self):
        target = self.route_box.get()
        if target == self.studio.configuration.name:
            return
        try:
            self.studio.set_stage_configuration(target)
        except ValueError as error:
            self.status.configure(text=str(error))
            return
        index = self.studio.index
        self._fold_current()
        self._changed("Stage route changed in the workspace; ROM is not built yet.")
        self.load(index, fold_current=False)

    def save(self):
        self._fold_current()
        try:
            validate_document(self.document, self.project, self.profile)
            validate_maps(self.map_state.document, self.project, self.profile)
            atomic_write_json(self.path, self.document)
            atomic_write_json(self.map_path, self.map_state.document)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Level Studio", str(error))
            return False
        self.dirty = False
        self.map_state.dirty = False
        self.note.configure(text="Saved level and map documents with atomic replacement.")
        self._title()
        return True

    def reload(self):
        if self.dirty and not self.messagebox.askyesno(
                "Level Studio", "Discard unsaved workspace edits?"):
            return
        try:
            document = load_document(self.path)
            maps = load_maps(self.map_path)
            screen_maps = load_screen_maps(self.screen_path)
            validate_document(document, self.project, self.profile)
            validate_maps(maps, self.project, self.profile)
            validate_screen_maps(screen_maps, self.project, self.profile)
            open_stage(
                self.project, self.studio.index, profile=self.profile,
                document=document, map_document=maps,
                map_baseline=self.map_baseline,
                screen_document=screen_maps,
                screen_baseline=self.screen_baseline)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Level Studio", str(error))
            return
        index = self.studio.index
        self.document = document
        self.map_state = MapWorkspace(maps)
        self.screen_maps = screen_maps
        self.dirty = False
        self.load(index, fold_current=False)
        self.note.configure(text="Workspace reloaded.")

    def refresh_peer_maps(self):
        """Pick up saved Screen Studio edits without discarding local edits."""
        try:
            peer = load_screen_maps(self.screen_path)
            validate_screen_maps(peer, self.project, self.profile)
            self.studio.refresh_map_preview(
                self.map_state.document, self.map_baseline,
                peer, self.screen_baseline)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Level map", str(error))
            return
        self.screen_maps = peer
        self.render()
        self.show_selection()
        self.note.configure(text="Saved Screen Studio maps included in preview.")

    def build_rom(self):
        if not self.save():
            return
        try:
            result = subprocess.run(
                ["make", "--no-print-directory", "build-content",
                 "CONTENT_PROFILE=%s" % self.profile],
                cwd=self.project, text=True, capture_output=True, check=False)
        except OSError as error:
            self.messagebox.showerror(
                "Content build failed", "Cannot launch content build: " + str(error))
            self.note.configure(text="Content build could not be launched.")
            return
        detail = (result.stdout + result.stderr).strip()
        if result.returncode:
            self.messagebox.showerror("Content build failed", detail)
        else:
            self.messagebox.showinfo("Content build complete", detail)

    def playtest(self):
        if not self.save():
            return
        try:
            command = playtest_make_command(self.profile, self.studio.index)
        except ValueError as error:
            self.messagebox.showerror("Level playtest", str(error))
            return
        try:
            result = subprocess.run(
                command, cwd=self.project, text=True, capture_output=True, check=False)
        except OSError as error:
            self.messagebox.showerror(
                "Level playtest failed", "Cannot launch level playtest: " + str(error))
            self.note.configure(text="Level playtest could not be launched.")
            return
        detail = (result.stdout + result.stderr).strip()
        if result.returncode:
            self.messagebox.showerror("Level playtest failed", detail)
        else:
            self.note.configure(text=detail or "Playtest launched in Gens.")

    def _title(self):
        self.window.title("%sAlien Soldier - Level Studio (%s)" % (
            "*" if self.dirty else "", self.profile.upper()))

    def close(self):
        if self.dirty:
            answer = self.messagebox.askyesnocancel(
                "Level Studio", "Save workspace edits before closing?")
            if answer is None:
                return
            if answer and not self.save():
                return
        self.window.destroy()

    def run(self):
        self.window.mainloop()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--stage", type=int, default=0)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--render-only", action="store_true")
    parser.add_argument("--x", type=int, default=0)
    parser.add_argument("--width", type=int, default=VIEW_WIDTH)
    args = parser.parse_args()
    project = Path(args.root).resolve()
    try:
        (_manifest, path, document, map_path, maps, map_baseline,
         screen_path, screen_maps, screen_baseline) = load_context(project, args.profile)
        rows = stage_rows(project, document)
        if not 0 <= args.stage < len(rows):
            raise ValueError("stage table index %d is not one of 0..%d"
                             % (args.stage, len(rows) - 1))
        studio = open_stage(
            project, args.stage, profile=args.profile, document=document,
            map_document=maps, map_baseline=map_baseline,
            screen_document=screen_maps, screen_baseline=screen_baseline)
        if args.check:
            if studio.document() != document:
                raise ValueError("opening a stage changes the workspace document")
            if studio.placements:
                original = studio.placements[0].entry.x
                changed = original + 1 if original < 0xFFFF else original - 1
                studio.set_fields(0, {"x": changed})
                reopened = open_stage(
                    project, args.stage, profile=args.profile,
                    document=studio.document())
                if reopened.placements[0].entry.x != changed:
                    raise ValueError("placement edit did not survive stage reopening")
            if args.stage == 0:
                state = MapWorkspace(deepcopy(map_baseline))
                hit = locate_stage_map_cell(
                    studio, map_baseline, 355, 0, "chunks")
                state.select_payload(hit.payload_index)
                state.select_value(hit.value_index)
                state.replace_value(
                    state.value ^ 1,
                    lambda candidate: validate_maps(candidate, project, args.profile))
                reopened = open_stage(
                    project, args.stage, profile=args.profile, document=document,
                    map_document=state.document, map_baseline=map_baseline,
                    screen_document=screen_maps, screen_baseline=screen_baseline)
                original_map_scene = open_stage(
                    project, args.stage, profile=args.profile, document=document,
                    map_document=map_baseline, map_baseline=map_baseline,
                    screen_document=screen_maps, screen_baseline=screen_baseline)
                if reopened.scene.tilemap.ram == original_map_scene.scene.tilemap.ram:
                    raise ValueError("map edit did not reach the stage preview")
                if reopened.image(352, 0, 8, 8) == original_map_scene.image(
                        352, 0, 8, 8):
                    raise ValueError("screen-space map edit did not affect the clicked tile")
                secondary = MapWorkspace(deepcopy(map_baseline))
                secondary_hit = locate_stage_map_cell(
                    original_map_scene, map_baseline, 0, 32, "chunks",
                    "plane_b", 0)
                secondary.select_payload(secondary_hit.payload_index)
                secondary.select_value(secondary_hit.value_index)
                if secondary.value != 1:
                    raise ValueError("Stage 1 plane-B fixture chunk changed")
                secondary.replace_value(
                    0, lambda candidate: validate_maps(
                        candidate, project, args.profile))
                secondary_scene = open_stage(
                    project, args.stage, profile=args.profile,
                    document=document, map_document=secondary.document,
                    map_baseline=map_baseline, screen_document=screen_maps,
                    screen_baseline=screen_baseline)
                if secondary_scene.scene.plane_b.ram == original_map_scene.scene.plane_b.ram:
                    raise ValueError("plane-B map edit did not reach the stage preview")
                if secondary_scene.image(0, 32, 32, 32) == original_map_scene.image(
                        0, 32, 32, 32):
                    raise ValueError("plane-B map edit did not change its visible tile")
                pattern = MapWorkspace(deepcopy(map_baseline))
                pattern_hit = locate_stage_map_cell(
                    original_map_scene, map_baseline, 0, 32, "patterns",
                    "plane_b", 0)
                pattern.select_payload(pattern_hit.payload_index)
                pattern.select_value(pattern_hit.value_index)
                if pattern.value != 348:
                    raise ValueError("Stage 1 plane-B pattern fixture changed")
                pattern.replace_value(
                    0, lambda candidate: validate_maps(
                        candidate, project, args.profile))
                pattern_scene = open_stage(
                    project, args.stage, profile=args.profile,
                    document=document, map_document=pattern.document,
                    map_baseline=map_baseline, screen_document=screen_maps,
                    screen_baseline=screen_baseline)
                if pattern_scene.scene.plane_b.name_word(0, 32) != 0:
                    raise ValueError("plane-B pattern edit did not reach the map reader")
                if pattern_scene.image(0, 32, 8, 8) == original_map_scene.image(
                        0, 32, 8, 8):
                    raise ValueError("plane-B pattern edit did not change its visible tile")
            print("[OK] %s Level Studio: %d stages, %d objects in stage %d" % (
                args.profile, len(rows), len(studio.placements), args.stage))
            return 0
        if args.render_only:
            if not 1 <= args.width <= MAX_RENDER_WIDTH:
                raise ValueError("render width must be 1..%d" % MAX_RENDER_WIDTH)
            output, drawn, width = render_view(
                studio, project / "build/studio" / args.profile,
                args.x, args.width)
            print("[OK] rendered %d pixels and %d proved sprites to %s" % (
                width, len(drawn), output.relative_to(project)))
            return 0
        import tkinter as tk
        from tkinter import messagebox, ttk
        Window(project, args.profile, path, document, map_path, maps,
               map_baseline, screen_path, screen_maps, screen_baseline, args.stage,
               tk, ttk, messagebox).run()
        return 0
    except (ContentError, ImportError, OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
