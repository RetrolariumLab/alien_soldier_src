#!/usr/bin/env python3
"""Open the profile-bound Alien Soldier Screen Studio workstation."""

from __future__ import annotations

import argparse
import subprocess
import sys
from contextlib import ExitStack
from copy import deepcopy
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.compressed_graphics_model import (  # noqa: E402
    apply_document as apply_compressed,
    load_document as load_compressed,
    validate_document as validate_compressed,
)
from authoring.content_workspace import (  # noqa: E402
    ContentError,
    artifact_path,
    checked_path,
    load_manifest,
    stage_tree,
)
from authoring.palette_studio_model import (  # noqa: E402
    apply_document as apply_palettes,
    load_document as load_palettes,
    validate_document as validate_palettes,
)
from authoring.screen_map_model import (  # noqa: E402
    apply_document as apply_maps,
    atomic_write_json,
    export_document as export_maps,
    load_document as load_maps,
    validate_document as validate_maps,
)
from authoring.screen_studio_model import load_config, render  # noqa: E402
from authoring.screen_studio_state import (  # noqa: E402
    Workspace, canonical_map_contexts, locate_screen_map_cell, read_ram_sources,
    replay_screen_maps, validate_screen_map_references)
from authoring.ram_map_workspace import merged_edit_streams  # noqa: E402
from authoring.ram_map_state import parse_value  # noqa: E402
from authoring.stage_map_model import (  # noqa: E402
    apply_document as apply_stage_maps,
    export_document as export_stage_maps,
    load_document as load_stage_maps,
    validate_document as validate_stage_maps,
)
from authoring.tile_graphics import write_png  # noqa: E402
from authoring.stage_tilemap_model import parsed_operation, parsed_read_phase  # noqa: E402
from authoring import guarded_inventory  # noqa: E402


MANIFEST = "config/authoring/content_studios.json"
PREVIEW_WIDTH = 640
PREVIEW_HEIGHT = 448


def named_artifact(manifest: dict, identifier: str) -> dict:
    return next(item for item in manifest["artifacts"] if item["id"] == identifier)


def load_context(project: Path, profile: str):
    with parsed_operation(project):
        return _load_context(project, profile)


def _load_context(project: Path, profile: str):
    manifest = load_manifest(checked_path(project, MANIFEST), project)
    map_path = artifact_path(
        project, manifest, profile, named_artifact(manifest, "screen_maps"))
    stage_map_path = artifact_path(
        project, manifest, profile, named_artifact(manifest, "stage_maps"))
    compressed_path = artifact_path(
        project, manifest, profile, named_artifact(manifest, "compressed_tile_art"))
    palette_path = artifact_path(
        project, manifest, profile, named_artifact(manifest, "palette_commands"))
    map_document = load_maps(map_path)
    stage_map_document = load_stage_maps(stage_map_path)
    compressed_document = load_compressed(compressed_path, project, profile)
    palette_document = load_palettes(palette_path)
    validate_maps(map_document, project, profile)
    validate_stage_maps(stage_map_document, project, profile)
    validate_compressed(compressed_document, project, profile)
    validate_palettes(palette_document, project, profile)
    return (
        manifest, map_path, map_document, compressed_document, palette_document,
        stage_map_path, stage_map_document)


def stage_preview(
    project: Path,
    profile: str,
    destination: Path,
    map_document: dict,
    compressed_document: dict,
    palette_document: dict,
    screen: str,
    stage_map_document: dict | None = None,
    with_scene: bool = False,
):
    _prepare_preview(project, profile, destination, map_document,
                     compressed_document, palette_document, stage_map_document)
    return _render_prepared_preview(project, profile, destination, screen, with_scene)


def _prepare_preview(project, profile, destination, map_document,
                     compressed_document, palette_document, stage_map_document):
    """Prepare screen-independent files; never retain a model or PASS."""
    stage_tree(project, destination)
    apply_compressed(compressed_document, destination, profile)
    apply_palettes(palette_document, destination, profile)
    with parsed_read_phase(project):
        if stage_map_document is not None:
            apply_stage_maps(
                stage_map_document, destination, profile, validation_root=project)
        apply_maps(
            map_document, destination, profile, validation_root=project)


def _render_prepared_preview(project, profile, destination, screen, with_scene=False):
    """Render afresh and close the prepared tree's original bytes each time."""
    with parsed_read_phase(destination):
        if with_scene:
            return render(destination, profile, screen, config_root=project,
                          with_scene=True)
        return render(destination, profile, screen, config_root=project)


class Window:
    """Tk widgets only; the tested Workspace owns all editable state."""

    def __init__(
        self, project, profile, path, document, compressed, palettes,
        stage_map_path, stage_maps, screen, tk, ttk, messagebox,
    ):
        self.project = project
        self.profile = profile
        self.path = path
        self.compressed = compressed
        self.palettes = palettes
        self.stage_map_path = stage_map_path
        self.stage_maps = stage_maps
        self.tk = tk
        self.ttk = ttk
        self.messagebox = messagebox
        self.state = Workspace(document)
        self.map_baseline = export_maps(project, profile)
        self.stage_baseline = export_stage_maps(project, profile)
        self.photo = None
        self.preview_scene = None
        self.preview_record = None
        self.preview_ram_sources = None
        self.map_reference_contexts = None
        self.screen_hit = None
        self.window = tk.Tk()
        self.window.title("Alien Soldier Screen Studio (%s)" % profile.upper())
        self.window.geometry("1080x720")
        self.window.protocol("WM_DELETE_WINDOW", self.close)
        self._build_toolbar(screen)
        self._build_preview()
        self._build_editor()
        self.select_payload(0)
        self.refresh_preview()

    def _build_toolbar(self, screen):
        bar = self.ttk.Frame(self.window, padding=(8, 6))
        bar.pack(side="top", fill="x")
        self.screen_ids = [record["id"] for record in load_config(self.project)["supported"]]
        self.screen_choice = self.tk.StringVar(value=screen)
        self.screen_box = self.ttk.Combobox(
            bar, textvariable=self.screen_choice, values=self.screen_ids,
            state="readonly", width=28)
        self.screen_box.pack(side="left", padx=4)
        self.screen_box.bind("<<ComboboxSelected>>", lambda _: self.refresh_preview())
        self.ttk.Button(bar, text="Refresh preview", command=self.refresh_preview).pack(
            side="left", padx=3)
        self.ttk.Button(bar, text="Save", command=self.save).pack(side="left", padx=3)
        self.ttk.Button(bar, text="Reload", command=self.reload).pack(side="left", padx=3)
        self.ttk.Button(bar, text="Build ROM", command=self.build_rom).pack(
            side="left", padx=3)
        self.status = self.ttk.Label(bar, text="")
        self.status.pack(side="left", padx=10)

    def _build_preview(self):
        holder = self.ttk.Frame(self.window, padding=(8, 8))
        holder.pack(side="left", fill="both", expand=True)
        self.canvas = self.tk.Canvas(
            holder, width=PREVIEW_WIDTH, height=PREVIEW_HEIGHT,
            background="#101014", highlightthickness=0)
        self.canvas.pack(fill="both", expand=True)
        self.canvas.bind("<Button-1>", self.click_preview)

    def _build_editor(self):
        panel = self.ttk.Frame(self.window, padding=(8, 8))
        panel.pack(side="right", fill="y")
        self.payload_choice = self.tk.StringVar()
        self.payload_box = self.ttk.Combobox(
            panel, textvariable=self.payload_choice,
            values=[record["name"] for record in self.state.payloads],
            state="readonly", width=42)
        self.payload_box.pack(fill="x")
        self.payload_box.bind(
            "<<ComboboxSelected>>",
            lambda _: self.select_payload(self.payload_box.current()))
        self.details = self.ttk.Label(
            panel, text="", justify="left", wraplength=330)
        self.details.pack(fill="x", pady=(10, 14))
        self.ttk.Label(panel, text="Value index").pack(anchor="w")
        self.index_text = self.tk.StringVar(value="0")
        index = self.ttk.Entry(panel, textvariable=self.index_text, width=18)
        index.pack(anchor="w")
        index.bind("<Return>", lambda _: self.select_value())
        self.ttk.Button(panel, text="Go", command=self.select_value).pack(
            anchor="w", pady=(3, 10))
        self.location = self.ttk.Label(panel, text="", justify="left")
        self.location.pack(anchor="w")
        self.ttk.Label(panel, text="Value ($hex or 0xhex)").pack(
            anchor="w", pady=(12, 0))
        self.value_text = self.tk.StringVar()
        value = self.ttk.Entry(panel, textvariable=self.value_text, width=18)
        value.pack(anchor="w")
        value.bind("<Return>", lambda _: self.apply_value())
        self.ttk.Button(panel, text="Apply value", command=self.apply_value).pack(
            anchor="w", pady=(3, 10))
        navigation = self.ttk.Frame(panel)
        navigation.pack(fill="x", pady=(4, 4))
        self.ttk.Button(navigation, text="Previous unit", command=lambda: self.step_unit(-1)).pack(
            side="left")
        self.ttk.Button(navigation, text="Next unit", command=lambda: self.step_unit(1)).pack(
            side="left", padx=4)
        self.paint_mode = self.tk.BooleanVar(value=False)
        self.ttk.Checkbutton(
            panel, text="Paint with value above (both views)",
            variable=self.paint_mode).pack(anchor="w")
        self.preview_pick = self.tk.BooleanVar(value=False)
        self.ttk.Checkbutton(
            panel, text="Pick map from static-screen preview",
            variable=self.preview_pick).pack(anchor="w")
        self.preview_plane = self.tk.StringVar(value="plane_a")
        self.ttk.Combobox(
            panel, textvariable=self.preview_plane, state="readonly",
            values=("plane_a", "plane_b"), width=12).pack(anchor="w")
        self.preview_role = self.tk.StringVar(value="chunks")
        self.ttk.Combobox(
            panel, textvariable=self.preview_role, state="readonly",
            values=("patterns", "chunks", "coarse"), width=12).pack(anchor="w")
        self.ttk.Label(panel, text="Raw map values; not game colors").pack(anchor="w")
        self.unit_canvas = self.tk.Canvas(
            panel, width=256, height=256, background="#101014", highlightthickness=0)
        self.unit_canvas.pack(anchor="w", pady=(4, 0))
        self.unit_canvas.bind("<Button-1>", self.click_cell)

    def select_payload(self, index):
        try:
            self.state.select_payload(index)
        except ValueError as error:
            self.messagebox.showerror("Screen Studio", str(error))
            return
        self.payload_box.current(index)
        record = self.state.payload
        consumers = ", ".join(record["consuming_asset_lists"])
        self.details.configure(text=(
            "%s; %d-bit values; %d entries\n%d decoded bytes; %d compressed bytes\n"
            "Consumers: %s"
            % (record["role"], record["value_bits"], record["value_count"],
               record["decoded_byte_count"], record["compressed_capacity"], consumers)
        ))
        self.index_text.set("0")
        self.show_value()

    def select_value(self):
        try:
            self.state.select_value(int(self.index_text.get(), 0))
        except ValueError as error:
            self.messagebox.showerror("Screen Studio", str(error))
            return
        self.show_value()

    def show_value(self):
        place = self.state.location()
        digits = self.state.payload["value_bits"] // 4
        self.value_text.set("$%0*X" % (digits, self.state.value))
        self.location.configure(text="Unit {unit}; x {x}; y {y}".format(**place))
        self.draw_unit()

    def draw_unit(self):
        self.unit_canvas.delete("all")
        payload = self.state.payload
        width = payload["unit_width"]
        height = payload["unit_height"]
        cell_width = 256 // width
        cell_height = 256 // height
        place = self.state.location()
        for index, value in enumerate(self.state.unit_values(place["unit"])):
            x, y = index % width, index // width
            if value is None:
                color = "#101014"
            else:
                shade = 32 + (value & 0xFF) * 3 // 4
                color = "#%02x%02x%02x" % (shade, shade, shade)
            self.unit_canvas.create_rectangle(
                x * cell_width, y * cell_height,
                (x + 1) * cell_width, (y + 1) * cell_height,
                fill=color,
                outline="#ffdf64" if (x, y) == (place["x"], place["y"]) else "#505058",
                width=2 if (x, y) == (place["x"], place["y"]) else 1)
            if value is not None and width <= 8:
                self.unit_canvas.create_text(
                    x * cell_width + cell_width // 2,
                    y * cell_height + cell_height // 2,
                    text="%0*X" % (payload["value_bits"] // 4, value),
                    fill="#ffffff" if shade < 128 else "#101014")

    def step_unit(self, delta):
        unit = max(0, min(self.state.unit_count - 1,
                          self.state.location()["unit"] + delta))
        self.state.select_cell(unit, 0, 0)
        self.index_text.set(str(self.state.value_index))
        self.show_value()

    def _validate_map_edit(self, document):
        validate_maps(document, self.project, self.profile)
        peer = load_stage_maps(self.stage_map_path)
        validate_stage_maps(peer, self.project, self.profile)
        merged_edit_streams(
            (peer, self.stage_baseline), (document, self.map_baseline))
        if (document != self.map_baseline or peer != self.stage_baseline):
            contexts = getattr(self, "map_reference_contexts", None)
            if contexts is None:
                contexts = canonical_map_contexts(self.project, self.profile)
                self.map_reference_contexts = contexts
        else:
            contexts = None
        validate_screen_map_references(
            self.project, self.profile, document, self.map_baseline,
            peer, self.stage_baseline, contexts)
        self.stage_maps = peer

    def show_preview_highlight(self):
        self.canvas.delete("screen-map-hit")
        if self.screen_hit is None:
            return
        hit = self.screen_hit
        self.canvas.create_rectangle(
            hit.screen_left * 2, hit.screen_top * 2,
            (hit.screen_left + hit.pixel_size) * 2,
            (hit.screen_top + hit.pixel_size) * 2,
            outline="#ffdf64", width=2, tags="screen-map-hit")

    def click_preview(self, event):
        if not self.preview_pick.get():
            return
        brush = self.value_text.get()
        previous = self.screen_hit
        selection = (self.state.payload_index, self.state.value_index)
        try:
            if self.preview_scene is None or self.preview_record is None:
                raise ValueError("screen preview is not ready")
            if (not 0 <= int(event.x) < self.preview_record["width"] * 2
                    or not 0 <= int(event.y) < self.preview_record["height"] * 2):
                raise ValueError("point is outside the static-screen preview")
            hit = locate_screen_map_cell(
                self.preview_scene, self.preview_record, self.profile,
                self.state.document, int(event.x) // 2, int(event.y) // 2,
                self.preview_plane.get(), self.preview_role.get())
            self.select_payload(hit.cell.payload_index)
            self.state.select_value(hit.cell.value_index)
            self.screen_hit = hit
            if self.paint_mode.get():
                value = parse_value(brush, self.state.payload["value_bits"])
                self.state.replace_value(value, self._validate_map_edit)
                if not self.refresh_map_preview_fast():
                    self.status.configure(
                        text="Map edit accepted; preview still shows the prior scene")
        except Exception as error:
            self.screen_hit = previous
            self.select_payload(selection[0])
            self.state.select_value(selection[1])
            if not isinstance(error, (OSError, ValueError, RuntimeError, TypeError, KeyError)):
                raise
            self.messagebox.showerror("Screen Studio", str(error))
        self.index_text.set(str(self.state.value_index))
        self.show_value()
        self.show_preview_highlight()
        if self.paint_mode.get():
            self.value_text.set(brush)

    def click_cell(self, event):
        payload = self.state.payload
        unit = self.state.location()["unit"]
        try:
            brush = (parse_value(self.value_text.get(), payload["value_bits"])
                     if self.paint_mode.get() else None)
            if brush is not None:
                self.state.paint_pixel(
                    unit, event.x, event.y, brush,
                    self._validate_map_edit)
                if not self.refresh_map_preview_fast():
                    self.status.configure(
                        text="Map edit accepted; preview still shows the prior scene")
            else:
                self.state.select_pixel(unit, event.x, event.y)
        except (OSError, ValueError, RuntimeError, TypeError, KeyError) as error:
            self.messagebox.showerror("Screen Studio", str(error))
        self.index_text.set(str(self.state.value_index))
        self.show_value()

    def apply_value(self):
        try:
            value = parse_value(self.value_text.get(), self.state.payload["value_bits"])
            self.state.replace_value(
                value, self._validate_map_edit)
        except (OSError, ValueError, RuntimeError, TypeError, KeyError) as error:
            self.messagebox.showerror("Screen Studio", str(error))
            self.show_value()
            return
        self.show_value()
        if not self.refresh_map_preview_fast():
            self.status.configure(
                text="Map edit accepted; preview still shows the prior scene")

    def _install_preview(self, image, scene, record, status):
        path = (self.project / "build/content/screen-preview" /
                self.profile / "preview.png")
        write_png(path, image, compression=1)
        photo = self.tk.PhotoImage(file=str(path)).zoom(2, 2)
        previous = self.screen_hit
        if (self.preview_record is None or
                self.preview_record["id"] != record["id"]):
            self.screen_hit = None
        elif previous is not None:
            try:
                current = locate_screen_map_cell(
                    scene, record, self.profile, self.state.document,
                    previous.screen_x, previous.screen_y,
                    previous.plane, previous.cell.role)
                self.screen_hit = (
                    current if (current.cell.source, current.cell.value_index)
                    == (previous.cell.source, previous.cell.value_index) else None)
            except ValueError:
                self.screen_hit = None
        self.photo = photo
        self.preview_scene = scene
        self.preview_record = record
        self._select_available_plane(scene)
        self.canvas.delete("all")
        self.canvas.create_image(0, 0, image=self.photo, anchor="nw")
        self.show_preview_highlight()
        self.status.configure(text=status)

    def _select_available_plane(self, scene):
        """Keep an explicit selection only while that physical plane exists."""
        available = [name for name, plane in (("plane_a", scene.tilemap),
                                             ("plane_b", scene.plane_b))
                     if plane is not None]
        if not available:
            raise ValueError("static screen has no selectable map plane")
        if self.preview_plane.get() not in available:
            self.preview_plane.set(available[0])

    def refresh_preview(self):
        try:
            self._validate_map_edit(self.state.document)
            destination = self.project / "build/content/screen-preview" / self.profile / "tree"
            image, scene, record = stage_preview(
                self.project, self.profile, destination, self.state.document,
                self.compressed, self.palettes, self.screen_choice.get(),
                self.stage_maps, with_scene=True)
            sources = read_ram_sources(destination, scene)
            self._install_preview(image, scene, record, "Preview rebuilt")
            self.preview_ram_sources = sources
            return True
        except (OSError, ValueError, ContentError) as error:
            self.messagebox.showerror("Screen Studio", str(error))
            return False

    def refresh_map_preview_fast(self):
        """Replay RAM maps for a brush stroke without recopying staged files."""
        if (self.preview_scene is None or self.preview_record is None or
                self.preview_ram_sources is None or
                self.preview_record["id"] != self.screen_choice.get()):
            return self.refresh_preview()
        try:
            self._validate_map_edit(self.state.document)
            image, scene = replay_screen_maps(
                self.preview_scene, self.preview_record, self.profile,
                self.preview_ram_sources, self.state.document, self.map_baseline,
                self.stage_maps, self.stage_baseline)
            self._install_preview(
                image, scene, self.preview_record, "RAM-map preview rebuilt")
            return True
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Screen Studio", str(error))
            return False

    def save(self):
        try:
            self._validate_map_edit(self.state.document)
            atomic_write_json(self.path, self.state.document)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Screen Studio", str(error))
            return
        self.state.dirty = False
        self.status.configure(text="Saved")

    def reload(self):
        if self.state.dirty and not self.messagebox.askyesno(
                "Screen Studio", "Discard unsaved map edits?"):
            return
        try:
            document = load_maps(self.path)
            self._validate_map_edit(document)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Screen Studio", str(error))
            return
        self.state = Workspace(document)
        self.screen_hit = None
        self.select_payload(0)
        self.refresh_preview()

    def build_rom(self):
        if self.state.dirty:
            self.messagebox.showerror("Screen Studio", "Save map edits before building.")
            return
        command = [
            "make", "--no-print-directory", "build-content",
            "CONTENT_PROFILE=%s" % self.profile,
        ]
        try:
            result = subprocess.run(command, cwd=self.project, check=False)
        except OSError as error:
            self.messagebox.showerror("Screen Studio", "Cannot launch content build: " + str(error))
            self.status.configure(text="Content build could not be launched.")
            return
        if result.returncode:
            self.messagebox.showerror(
                "Screen Studio", "Content build failed with code %d." % result.returncode)

    def close(self):
        if self.state.dirty and not self.messagebox.askyesno(
                "Screen Studio", "Close with unsaved map edits?"):
            return
        self.window.destroy()


def check(project: Path, profile: str) -> None:
    with ExitStack() as guards:
        _check(project, profile, guards)


def _close_prepared_tree(destination, frozen):
    guarded_inventory.close(destination, {name: dict(fields) for name, fields in frozen},
                            max_file=128 << 20, max_entries=32768)


def _check(project: Path, profile: str, guards: ExitStack) -> None:
    (_manifest, _path, maps, compressed, palettes,
     _stage_path, stage_maps) = load_context(project, profile)
    state = Workspace(maps)
    original = state.value
    state.set_value(original ^ 1)
    state.set_value(original)
    validate_maps(state.document, project, profile)
    destination = project / "build/content/screen-smoke" / profile / "tree"
    prepared = False
    for record in load_config(project)["supported"]:
        if not prepared:
            _prepare_preview(
                project, profile, destination, maps, compressed, palettes,
                stage_maps)
            rows = guarded_inventory.capture(destination, max_file=128 << 20,
                max_total=512 << 20, max_entries=32768)
            frozen = tuple((name, tuple(row.items())) for name, row in rows.items())
            guards.callback(_close_prepared_tree, destination, frozen)
            prepared = True
        image, scene, source_record = _render_prepared_preview(
            project, profile, destination, record["id"], with_scene=True)
        if len(image) != record["height"] or len(image[0]) != record["width"]:
            raise ValueError("screen preview dimensions differ: %s" % record["id"])
        for plane_name, plane in (("plane_a", scene.tilemap),
                                  ("plane_b", scene.plane_b)):
            if plane is None:
                continue
            found = False
            for y in range(0, record["height"], 16):
                for x in range(0, record["width"], 16):
                    try:
                        locate_screen_map_cell(
                            scene, source_record, profile, maps,
                            x, y, plane_name, "chunks")
                    except ValueError:
                        continue
                    found = True
                    break
                if found:
                    break
            if not found:
                raise ValueError("screen plane has no editable map cell: %s %s"
                                 % (record["id"], plane_name))
        if record["id"] == "story_background":
            sources = read_ram_sources(destination, scene)
            hit = locate_screen_map_cell(
                scene, source_record, profile, maps, 16, 16,
                "plane_b", "chunks")
            edited = Workspace(deepcopy(maps))
            edited.select_payload(hit.cell.payload_index)
            edited.select_value(hit.cell.value_index)
            edited.replace_value(
                edited.value ^ 1,
                lambda candidate: validate_maps(candidate, project, profile))
            fast, fast_scene = replay_screen_maps(
                scene, source_record, profile, sources,
                edited.document, export_maps(project, profile),
                stage_maps, export_stage_maps(project, profile))
            changed, changed_scene, _changed_record = stage_preview(
                project, profile, destination.parent / "edited/tree", edited.document,
                compressed, palettes, record["id"], stage_maps,
                with_scene=True)
            if changed == image:
                raise ValueError("screen-space map edit did not affect story preview")
            if changed != fast or changed_scene.plane_b.ram != fast_scene.plane_b.ram:
                raise ValueError("in-memory map replay differs from staged story preview")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--screen", default="title_background")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    project = Path(args.root).resolve()
    try:
        if args.screen not in {
                record["id"] for record in load_config(project)["supported"]}:
            raise ValueError("unknown static screen: %s" % args.screen)
        if args.check:
            check(project, args.profile)
            print("[OK] %s Screen Studio workstation smoke" % args.profile)
            return 0
        context = load_context(project, args.profile)
        import tkinter as tk
        from tkinter import messagebox, ttk

        (_manifest, path, maps, compressed, palettes,
         stage_map_path, stage_maps) = context
        window = Window(
            project, args.profile, path, maps, compressed, palettes,
            stage_map_path, stage_maps, args.screen, tk, ttk, messagebox)
        window.window.mainloop()
        return 0
    except (OSError, ValueError, ContentError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
