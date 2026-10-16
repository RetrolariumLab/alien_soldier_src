#!/usr/bin/env python3
"""Open the profile-bound Alien Soldier Text Studio workstation."""

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
    stage_tree,
)
from authoring.credits_text_model import (  # noqa: E402
    apply_document as apply_credits,
    atomic_write_json as write_credits,
    glyph_art as credits_glyph_art,
    glyph_tiles_from_art as credits_glyph_tiles,
    load_document as load_credits,
    validate_document as validate_credits,
)
from authoring.frontend_text_model import (  # noqa: E402
    apply_document as apply_frontend,
    atomic_write_json as write_frontend,
    load_document as load_frontend,
    validate_document as validate_frontend,
)
from authoring.glyph_source_list_model import (  # noqa: E402
    apply_document as apply_glyph_lists,
    atomic_write_json as write_glyph_lists,
    load_document as load_glyph_lists,
    validate_document as validate_glyph_lists,
)
from authoring.japanese_glyph_model import (  # noqa: E402
    apply_document as apply_japanese_glyphs,
    atomic_write_json as write_japanese_glyphs,
    glyph_pixels,
    load_document as load_japanese_glyphs,
    validate_document as validate_japanese_glyphs,
)
from authoring.results_text_model import (  # noqa: E402
    apply_document as apply_results,
    atomic_write_json as write_results,
    load_document as load_results,
    validate_document as validate_results,
)
from authoring.scripted_message_model import (  # noqa: E402
    apply_document as apply_scripts,
    atomic_write_json as write_scripts,
    load_document as load_scripts,
    validate_document as validate_scripts,
)
from authoring.shared_font_preview import glyph_tiles as shared_glyph_tiles  # noqa: E402
from authoring.story_text_preview import (  # noqa: E402
    ROW_CELLS as STORY_ROW_CELLS, paired_row_tiles)
from authoring.stage_message_model import (  # noqa: E402
    apply_document as apply_stage_messages,
    atomic_write_json as write_stage_messages,
    load_document as load_stage_messages,
    validate_document as validate_stage_messages,
)
from authoring.story_text_model import (  # noqa: E402
    apply_document as apply_story,
    atomic_write_json as write_story,
    load_document as load_story,
    validate_document as validate_story,
)
from authoring.text_studio_state import Workspace  # noqa: E402
from authoring.stage_tilemap_model import parsed_operation  # noqa: E402
from authoring.text_glyph_picker import GlyphPicker  # noqa: E402
from authoring.text_character_map import (  # noqa: E402
    CharacterMap, empty_document as empty_character_map,
    import_answers, load_document as load_character_map, map_path,
)


MANIFEST = "config/authoring/content_studios.json"
HANDLERS = {
    "credits_text_document": (load_credits, validate_credits, write_credits, apply_credits),
    "frontend_text_document": (
        load_frontend, validate_frontend, write_frontend, apply_frontend),
    "glyph_source_list_document": (
        load_glyph_lists, validate_glyph_lists, write_glyph_lists, apply_glyph_lists),
    "japanese_glyph_document": (
        load_japanese_glyphs, validate_japanese_glyphs,
        write_japanese_glyphs, apply_japanese_glyphs),
    "results_text_document": (
        load_results, validate_results, write_results, apply_results),
    "scripted_message_document": (
        load_scripts, validate_scripts, write_scripts, apply_scripts),
    "stage_message_document": (
        load_stage_messages, validate_stage_messages,
        write_stage_messages, apply_stage_messages),
    "story_text_document": (load_story, validate_story, write_story, apply_story),
}


def load_context(project: Path, profile: str) -> dict[str, dict]:
    with parsed_operation(project):
        return _load_context(project, profile)


def _load_context(project: Path, profile: str) -> dict[str, dict]:
    manifest = load_manifest(checked_path(project, MANIFEST), project)
    studio = next(item for item in manifest["studios"] if item["id"] == "text")
    artifacts = {item["id"]: item for item in manifest["artifacts"]}
    context = {}
    for identifier in studio["artifacts"]:
        artifact = artifacts[identifier]
        if artifact["kind"] not in HANDLERS:
            raise ValueError("Text Studio has no handler for %s" % artifact["kind"])
        loader, validator, writer, apply = HANDLERS[artifact["kind"]]
        path = artifact_path(project, manifest, profile, artifact)
        document = loader(path)
        validator(document, project, profile)
        context[identifier] = {
            "artifact": artifact,
            "path": path,
            "document": document,
            "load": loader,
            "validate": validator,
            "write": writer,
            "apply": apply,
        }
    return context


def parse_value(text: str) -> int:
    text = text.strip()
    return int(text[1:], 16) if text.startswith("$") else int(text, 0)


def replacement_for(field, value: int) -> int:
    return field.minimum if value != field.minimum else field.minimum + 1


class Window:
    """Tk widgets only; the tested Workspace owns editable values."""

    def __init__(self, project, profile, context, tk, ttk, messagebox, filedialog=None):
        self.project = project
        self.profile = profile
        self.context = context
        self.tk = tk
        self.ttk = ttk
        self.messagebox = messagebox
        self.filedialog = filedialog
        map_error = None
        try:
            self.character_map = CharacterMap(load_character_map(project, profile))
        except (OSError, ValueError) as error:
            map_error = str(error)
            self.character_map = CharacterMap(empty_character_map(project, profile))
        self.state = Workspace({
            identifier: record["document"] for identifier, record in context.items()
        })
        self._credits_art = None
        self.picker = None
        self.window = tk.Tk()
        self.window.title("Alien Soldier Text Studio (%s)" % profile.upper())
        self.window.geometry("980x680")
        self.window.protocol("WM_DELETE_WINDOW", self.close)
        self._build_toolbar()
        self._build_editor()
        self.select_artifact(0)
        if map_error:
            self.messagebox.showerror("Text character map", map_error)
            self.status.configure(text="Character map rejected; raw glyph IDs remain available")

    def _build_toolbar(self):
        bar = self.ttk.Frame(self.window, padding=(8, 6))
        bar.pack(side="top", fill="x")
        self.ttk.Label(bar, text="Artifact").pack(side="left")
        self.artifact_choice = self.tk.StringVar()
        self.artifact_box = self.ttk.Combobox(
            bar,
            values=self.state.artifact_ids,
            textvariable=self.artifact_choice,
            state="readonly",
            width=34,
        )
        self.artifact_box.pack(side="left", padx=8)
        self.artifact_box.bind(
            "<<ComboboxSelected>>",
            lambda _: self.select_artifact(self.artifact_box.current()),
        )
        self.ttk.Button(bar, text="Save", command=self.save).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Reload", command=self.reload).pack(side="left", padx=2)
        self.ttk.Button(bar, text="Build ROM", command=self.build_rom).pack(
            side="left", padx=2)
        self.ttk.Button(bar, text="Import glyph answers", command=self.import_character_map).pack(
            side="left", padx=2)
        self.status = self.ttk.Label(bar, text="")
        self.status.pack(side="left", padx=10)

    def _build_editor(self):
        panel = self.ttk.Frame(self.window, padding=(14, 12))
        panel.pack(fill="both", expand=True)
        self.ttk.Label(panel, text="Record / editable field").grid(
            row=0, column=0, sticky="w")
        self.field_choice = self.tk.StringVar()
        self.field_box = self.ttk.Combobox(
            panel, textvariable=self.field_choice, state="readonly", width=88)
        self.field_box.grid(row=1, column=0, columnspan=5, sticky="ew", pady=(2, 12))
        self.field_box.bind(
            "<<ComboboxSelected>>", lambda _: self.select_field(self.field_box.current()))

        self.ttk.Button(panel, text="Previous", command=lambda: self.step_value(-1)).grid(
            row=2, column=0, sticky="w")
        self.ttk.Button(panel, text="Next", command=lambda: self.step_value(1)).grid(
            row=2, column=1, sticky="w", padx=(4, 18))
        self.ttk.Label(panel, text="Index").grid(row=2, column=2, sticky="e")
        self.index_text = self.tk.StringVar(value="0")
        index = self.ttk.Entry(panel, textvariable=self.index_text, width=10)
        index.grid(row=2, column=3, sticky="w", padx=5)
        index.bind("<Return>", lambda _: self.go_to_value())
        self.ttk.Button(panel, text="Go", command=self.go_to_value).grid(
            row=2, column=4, sticky="w")

        self.position = self.ttk.Label(panel, text="")
        self.position.grid(row=3, column=0, columnspan=5, sticky="w", pady=(12, 2))
        self.sequence = self.ttk.Label(
            panel, text="", justify="left", wraplength=900, font=("TkFixedFont", 10))
        self.sequence.grid(row=4, column=0, columnspan=5, sticky="ew", pady=(0, 18))

        self.ttk.Label(panel, text="Numeric value ($hex, 0xhex, or decimal)").grid(
            row=5, column=0, columnspan=2, sticky="w")
        self.value_text = self.tk.StringVar()
        value = self.ttk.Entry(panel, textvariable=self.value_text, width=18)
        value.grid(row=6, column=0, sticky="w", pady=(2, 8))
        value.bind("<Return>", lambda _: self.apply_value())
        self.ttk.Button(panel, text="Apply value", command=self.apply_value).grid(
            row=6, column=1, sticky="w", padx=4)
        self.choose_button = self.ttk.Button(
            panel, text="Choose glyph...", command=self.choose_glyph)
        self.choose_button.grid(row=6, column=2, columnspan=3, sticky="w", padx=4)
        self.glyph_preview = self.tk.Canvas(
            panel, width=128, height=128, highlightthickness=0)
        self.glyph_preview.grid(row=7, column=0, sticky="w", pady=(8, 0))
        self.glyph_caption = self.ttk.Label(panel, text="")
        self.glyph_caption.grid(row=7, column=1, columnspan=4, sticky="w")
        self.story_strip = self.tk.Canvas(
            panel, width=STORY_ROW_CELLS * 16, height=80,
            highlightthickness=0)
        self.story_strip.grid(row=8, column=0, columnspan=5, sticky="w")
        self.story_strip.grid_remove()
        self.story_strip.bind("<Button-1>", self._select_story_strip_pixel)
        self.story_strip_caption = self.ttk.Label(
            panel, text="Story primary / accent: raw source tiles, not a game frame")
        self.story_strip_caption.grid(row=9, column=0, columnspan=5, sticky="w")
        self.story_strip_caption.grid_remove()
        self.story_photo = None
        self.ttk.Label(panel, text="Fixed-field text: reviewed characters or explicit [[$HHH]] IDs").grid(
            row=10, column=0, columnspan=5, sticky="w", pady=(12, 2))
        self.field_text = self.tk.StringVar()
        self.text_entry = self.ttk.Entry(panel, textvariable=self.field_text, width=80)
        self.text_entry.grid(row=11, column=0, columnspan=4, sticky="ew")
        self.text_entry.bind("<Return>", lambda _: self.apply_text())
        self.text_button = self.ttk.Button(panel, text="Apply field text", command=self.apply_text)
        self.text_button.grid(row=11, column=4, sticky="w", padx=4)
        self.help = self.ttk.Label(
            panel,
            text=("Values are source glyph indices and timing bytes. Text Studio does "
                  "not infer Unicode characters where no regional mapping is proved."),
            wraplength=900,
        )
        self.help.grid(row=12, column=0, columnspan=5, sticky="w", pady=(12, 0))
        panel.columnconfigure(0, weight=1)

    def select_artifact(self, index):
        try:
            self.state.select_artifact(index)
        except ValueError as error:
            self.messagebox.showerror("Text Studio", str(error))
            return
        self.artifact_box.current(index)
        self.field_box.configure(values=[field.label for field in self.state.artifact_fields])
        self.select_field(0)

    def select_field(self, index):
        try:
            self.state.select_field(index)
        except ValueError as error:
            self.messagebox.showerror("Text Studio", str(error))
            return
        self.field_box.current(index)
        self.index_text.set("0")
        self.show_value()

    def go_to_value(self):
        try:
            self.state.select_value(int(self.index_text.get(), 0))
        except ValueError as error:
            self.messagebox.showerror("Text Studio", str(error))
            return
        self.show_value()

    def step_value(self, delta):
        index = max(0, min(self.state.field.length - 1, self.state.value_index + delta))
        self.state.select_value(index)
        self.index_text.set(str(index))
        self.show_value()

    def _draw_source_tiles(self, tiles):
        """Show raw palette indices with a gap, without inferring layout."""
        for tile_index, tile in enumerate(tiles):
            for y, row in enumerate(tile):
                for x, pixel in enumerate(row):
                    shade = 32 + pixel * 14
                    color = "#%02x%02x%02x" % (shade, shade, shade)
                    left = (tile_index * 9 + x) * 7
                    top = y * 7
                    self.glyph_preview.create_rectangle(
                        left, top, left + 7, top + 7,
                        fill=color, outline=color)

    def _draw_story_strip(self, row, selected_layer, selected_index):
        primary, accent = paired_row_tiles(self.project, row)
        raster = self.tk.PhotoImage(width=STORY_ROW_CELLS * 8, height=40)
        raster.put("#202020", to=(0, 0, STORY_ROW_CELLS * 8, 40))
        for image, top in ((primary, 0), (accent, 24)):
            for y, pixels in enumerate(image):
                colours = ["#%02x%02x%02x" % ((32 + value * 14,) * 3)
                           for value in pixels]
                raster.put("{" + " ".join(colours) + "}", to=(0, top + y))
        self.story_photo = raster.zoom(2, 2)
        self.story_strip.delete("all")
        self.story_strip.create_image(0, 0, anchor="nw", image=self.story_photo)
        for layer, top in (("primary", 0), ("accent", 48)):
            for index, value in enumerate(row[layer][:-1]):
                if value == 0xFF:
                    x = index * 16
                    self.story_strip.create_line(
                        x, top, x, top + 32, fill="#ff6060", width=2)
            if layer == selected_layer:
                left = selected_index * 16
                self.story_strip.create_rectangle(
                    left, top, left + 16, top + 32,
                    outline="#ff40ff", width=2)

    def _select_story_strip_pixel(self, event):
        if self.state.artifact_id != "story_text_rows":
            return
        if not 0 <= event.x < STORY_ROW_CELLS * 16:
            return
        if 0 <= event.y < 32:
            layer = 0
        elif 48 <= event.y < 80:
            layer = 1
        else:
            return
        row_index = self.state.field.container["index"]
        self.select_field(row_index * 2 + layer)
        column = event.x // 16
        self.state.select_value(column)
        self.index_text.set(str(column))
        self.show_value()

    def show_value(self):
        field = self.state.field
        start, values = self.state.sequence_window()
        self.value_text.set("$%02X" % self.state.value)
        self.position.configure(text=(
            "%s — value %d of %d; allowed %d..%d"
            % (field.label, self.state.value_index + 1, field.length,
               field.minimum, field.maximum)
        ))
        tokens = [("[%02X]" if start + index == self.state.value_index else "%02X") % value
                  for index, value in enumerate(values)]
        self.sequence.configure(text="Slots %d..%d of %d\n%s" % (
            start, start + len(values) - 1, field.length,
            "\n".join(" ".join(tokens[index:index + 16])
                      for index in range(0, len(tokens), 16))))
        self.choose_button.configure(
            state="normal" if self.state.glyph_range is not None else "disabled")
        self.glyph_preview.delete("all")
        if self.state.artifact_id == "japanese_glyph_sequence":
            pixels = glyph_pixels(self.project, self.state.value)
            for y, row in enumerate(pixels):
                for x, pixel in enumerate(row):
                    shade = 32 + pixel * 14
                    color = "#%02x%02x%02x" % (shade, shade, shade)
                    self.glyph_preview.create_rectangle(
                        x * 8, y * 8, x * 8 + 8, y * 8 + 8,
                        fill=color, outline=color)
            self.glyph_caption.configure(text="ROM glyph $%03X (grayscale indices)" % self.state.value)
        elif self.state.artifact_id == "story_text_rows":
            if self.state.value_index in field.protected_indices:
                self.glyph_caption.configure(text="Protected story accent $FF boundary")
            else:
                self._draw_source_tiles(shared_glyph_tiles(self.project, self.state.value))
                self.glyph_caption.configure(text=(
                    "Story shared font $%02X: source tile 0 | tile 1; "
                    "not the separate Japanese glyph stream" % self.state.value))
        elif self.state.artifact_id in (
                "boss_and_ship_message_scripts", "glyph_source_lists",
                "results_detail_text", "frontend_text_strings",
                "stage_message_sequences"):
            self._draw_source_tiles(shared_glyph_tiles(self.project, self.state.value))
            self.glyph_caption.configure(text=(
                "Shared font $%02X: source tile 0 | tile 1; "
                "grayscale indices, not inferred text or layout" % self.state.value))
        elif (self.state.artifact_id == "credits_text_sequence"
              and field.key in ("upper_glyphs", "lower_glyphs")):
            if self._credits_art is None:
                self._credits_art = credits_glyph_art(self.project)
            tiles = credits_glyph_tiles(self._credits_art, self.state.value)
            if tiles is None:
                self.glyph_caption.configure(text="Credits glyph 0: blank slot; no sprite")
            else:
                self._draw_source_tiles(tiles)
                self.glyph_caption.configure(text=(
                    "Credits glyph $%02X (shared font): source tile 0 | tile 1; "
                    "grayscale indices, not inferred layout" % self.state.value))
        else:
            self.glyph_caption.configure(text="")
        if self.state.artifact_id == "story_text_rows":
            self.story_strip.grid()
            self.story_strip_caption.grid()
            self._draw_story_strip(field.container, field.key, self.state.value_index)
        else:
            self.story_strip.grid_remove()
            self.story_strip_caption.grid_remove()
            self.story_photo = None
        if self.picker is not None:
            self.picker.sync()
        editable_text = self.state.font_family is not None
        self.field_text.set(self.state.field_text(self.character_map) if editable_text
                            else "Timing field: numeric editing only")
        for widget in (self.text_entry, self.text_button):
            widget.configure(state="normal" if editable_text else "disabled")

    def choose_glyph(self):
        if self.state.glyph_range is None:
            return
        if self.picker is None:
            self.picker = GlyphPicker(self)
        else:
            self.picker.sync()
            self.picker.window.lift()

    def apply_value(self, glyph=None):
        artifact = self.state.artifact_id
        old_value = self.state.value
        dirty_before = set(self.state.dirty)
        try:
            if glyph is None:
                self.state.set_value(parse_value(self.value_text.get()))
            else:
                self.state.set_glyph(glyph)
            record = self.context[artifact]
            record["validate"](record["document"], self.project, self.profile)
        except Exception as error:
            if self.state.value != old_value:
                self.state.field.set_value(self.state.value_index, old_value)
            self.state.dirty = dirty_before
            if not isinstance(error, (OSError, ValueError, RuntimeError, TypeError, KeyError)):
                raise
            self.messagebox.showerror("Text Studio", str(error))
            self.show_value()
            return
        self.show_value()
        self.status.configure(text="Edited %s" % artifact)

    def apply_text(self):
        artifact = self.state.artifact_id
        record = self.context[artifact]
        try:
            self.state.set_text(self.field_text.get(), self.character_map, lambda document:
                                record["validate"](document, self.project, self.profile))
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Text Studio", str(error))
            self.show_value()
            return
        self.show_value()
        self.status.configure(text="Validated fixed-field text: " + artifact)

    def import_character_map(self):
        if self.filedialog is None:
            from tkinter import filedialog
            self.filedialog = filedialog
        selected = self.filedialog.askopenfilename(
            parent=self.window, title="Import reviewed ROM glyph answers",
            filetypes=[("Glyph answers JSON", "*.json")])
        if not selected:
            return
        try:
            exists = map_path(self.project, self.profile).exists()
            if exists and not self.messagebox.askyesno(
                    "Text character map", "Replace this profile's current character map?"):
                return
            document = import_answers(self.project, self.profile, Path(selected), replace=exists)
            self.character_map = CharacterMap(document)
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Text character map", str(error))
            return
        self.show_value()
        self.status.configure(text="Imported %d evidence-bound glyph records; no inferred characters" %
                              len(document["answers"]))

    def save(self):
        try:
            for record in self.context.values():
                record["validate"](record["document"], self.project, self.profile)
            for identifier in self.state.dirty:
                record = self.context[identifier]
                record["write"](record["path"], record["document"])
        except (OSError, ValueError) as error:
            self.messagebox.showerror("Text Studio", str(error))
            return
        self.state.dirty.clear()
        self.status.configure(text="Saved")

    def reload(self):
        if self.state.dirty and not self.messagebox.askyesno(
                "Text Studio", "Discard unsaved text edits?"):
            return
        try:
            context = load_context(self.project, self.profile)
            character_map = CharacterMap(load_character_map(self.project, self.profile))
            self.context = context
            self.character_map = character_map
            self.state = Workspace({
                identifier: record["document"]
                for identifier, record in self.context.items()
            })
            self._credits_art = None
            self.select_artifact(0)
        except (OSError, ValueError, ContentError) as error:
            self.messagebox.showerror("Text Studio", str(error))

    def build_rom(self):
        if self.state.dirty:
            self.messagebox.showerror("Text Studio", "Save text edits before building.")
            return
        command = [
            "make", "--no-print-directory", "build-content",
            "CONTENT_PROFILE=%s" % self.profile,
        ]
        try:
            result = subprocess.run(command, cwd=self.project, check=False)
        except OSError as error:
            self.messagebox.showerror("Text Studio", "Cannot launch content build: " + str(error))
            self.status.configure(text="Content build could not be launched.")
            return
        if result.returncode:
            self.messagebox.showerror(
                "Text Studio", "Content build failed with code %d." % result.returncode)

    def close(self):
        if self.state.dirty and not self.messagebox.askyesno(
                "Text Studio", "Close with unsaved text edits?"):
            return
        self.window.destroy()


def check(project: Path, profile: str) -> None:
    with parsed_operation(project):
        _check(project, profile)


def _check(project: Path, profile: str) -> None:
    context = load_context(project, profile)
    state = Workspace({
        identifier: record["document"] for identifier, record in context.items()
    })
    destination = project / "build/content/text-smoke" / profile / "tree"
    stage_tree(project, destination)
    for identifier in state.artifact_ids:
        state.select_artifact(identifier)
        field = state.field
        original = state.value
        state.set_value(replacement_for(field, original))
        record = context[identifier]
        record["validate"](record["document"], project, profile)
        changed = record["apply"](
            record["document"], destination, profile, validation_root=project)
        if not changed:
            raise ValueError("Text Studio smoke edit changed no source: %s" % identifier)
        field.set_value(0, original)
        record["validate"](record["document"], project, profile)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    project = Path(args.root).resolve()
    try:
        if args.check:
            check(project, args.profile)
            print("[OK] %s Text Studio workstation smoke" % args.profile)
            return 0
        context = load_context(project, args.profile)
        import tkinter as tk
        from tkinter import messagebox, ttk

        window = Window(project, args.profile, context, tk, ttk, messagebox)
        window.window.mainloop()
        return 0
    except (OSError, ValueError, ContentError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
