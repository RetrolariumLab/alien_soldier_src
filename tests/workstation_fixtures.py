"""Private tiny fixtures: real Tk, production JSON readers/writers, no ROM assets."""

from __future__ import annotations

from contextlib import ExitStack
from copy import deepcopy
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "tests"))
from authoring import graphics_studio as graphics, level_studio as level
from authoring import screen_studio as screen, sound_studio as sound, text_studio as text
from authoring import text_character_map
from authoring.atomic_output import atomic_write_json
from test_graphics_studio_widget import tiny_documents
from test_level_studio_widget import TinyStudio, tiny_maps
from test_sound_studio_widget import tiny_context

MODULES = {"level": level, "graphics": graphics, "screen": screen, "text": text, "sound": sound}


def text_documents():
    return {
        "boss_and_ship_message_scripts": {
            "font_glyph_count": 228,
            "scripts": [{"name": "Fixture", "records": [{"glyphs": [1, 2]}]}],
        },
        "credits_text_sequence": {
            "max_glyph_id": 127,
            "records": [
                {
                    "upper_count": 2,
                    "upper_delay": 1,
                    "upper_glyphs": [1, 2],
                    "lower_count": 2,
                    "lower_delay": 1,
                    "lower_glyphs": [1, 2],
                }
            ],
        },
        "frontend_text_strings": {"strings": [{"name": "Fixture", "glyphs": [1, 2]}]},
        "glyph_source_lists": {"font_glyph_count": 228, "lists": [{"name": "Fixture", "glyphs": [1, 2]}]},
        "japanese_glyph_sequence": {"first_code": 1, "art_glyph_count": 2, "codes": [1, 2]},
        "results_detail_text": {
            "max_glyph_id": 227,
            "rows": [{"index": 0, "glyphs": [1, 2]}],
            "summary_labels": [{"name": "Fixture", "glyphs": [1, 2]}],
        },
        "stage_message_sequences": {"streams": [{"name": "Fixture", "sequences": [[{"row": 0, "glyphs": [1, 2]}]]}]},
        "story_text_rows": {"rows": [{"index": 0, "primary": [1, 2, 255], "accent": [1, 2, 255]}]},
    }


class SerialTinyStage(TinyStudio):
    """Reuse bounded placement/configuration fixture with real JSON ownership."""

    def __init__(self, document, index):
        super().__init__(index)
        self._document = document
        row = document["stages"][index]
        self.placements[0].entry.x = row["player_x"]
        self.configuration.name = row["configuration"]

    def document(self):
        row = self._document["stages"][self.index]
        row["player_x"] = self.placements[0].entry.x
        row["configuration"] = self.configuration.name
        return self._document

    def set_fields(self, index, values):
        for name, value in values.items():
            self.set_field(index, name, value)


class Fixture:
    def __init__(self, studio, profile, tk, ttk, parent):
        self.studio, self.profile, self.module = studio, profile, MODULES[studio]
        self.stack = ExitStack()
        self.temporary = tempfile.TemporaryDirectory(prefix=studio + "-" + profile + "-", dir=parent)
        self.stack.callback(self.temporary.cleanup)
        self.project = Path(self.temporary.name).resolve()
        self.manifest = json.loads((ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8"))
        atomic_write_json(self.project / "config/authoring/content_studios.json", self.manifest)
        atomic_write_json(
            self.project / "config/rom_profiles.json",
            json.loads((ROOT / "config/rom_profiles.json").read_text(encoding="utf-8")),
        )
        self.paths, self.validators = {}, []
        self.failure = None
        self.messages, self.dialogs, self.files = mock.Mock(), mock.Mock(), mock.Mock()
        self.messages.askyesno.return_value = False
        self.messages.askyesnocancel.return_value = None
        self.files.asksaveasfilename.return_value = ""
        self.dialogs.askinteger.return_value = None
        actual_tk, actual_photo = tk.Tk, tk.PhotoImage

        def withdrawn():
            item = actual_tk()
            item.withdraw()
            return item

        self.patch(tk, "Tk", withdrawn)
        # Loading/rendering large cartridge-derived pictures is outside this UI gate.
        self.patch(tk, "PhotoImage", lambda *_a, **_k: actual_photo(width=1, height=1))
        try:
            getattr(self, "_" + studio)(tk, ttk)
        except BaseException:
            self.stack.close()
            raise
        self.callback_errors = mock.Mock()
        self.window.window.report_callback_exception = self.callback_errors
        self.stack.callback(self.destroy)

    def destroy(self):
        try:
            if self.window.window.winfo_exists():
                self.window.window.destroy()
        except Exception:
            pass

    def alive(self):
        try:
            return bool(self.window.window.winfo_exists())
        except self.window.tk.TclError:
            return False

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return self.stack.__exit__(*args)

    def patch(self, item, name, value):
        return self.stack.enter_context(mock.patch.object(item, name, new=value))

    def validator(self):
        def checked(document, project, profile):
            if project.resolve() != self.project or profile != self.profile or document.get("profile") != profile:
                raise ValueError("private fixture profile/path mismatch")
            if self.failure is not None:
                raise self.failure

        item = mock.Mock(side_effect=checked)
        self.validators.append(item)
        return item

    def write(self, identifier, document):
        artifact = next(item for item in self.manifest["artifacts"] if item["id"] == identifier)
        path = self.project / self.manifest["workspace"] / self.profile / artifact["workspace"]
        document = dict(deepcopy(document), profile=self.profile, schema_version=2)
        atomic_write_json(path, document)
        self.paths[identifier] = path
        return path, document

    def _level(self, tk, ttk):
        path, doc = self.write(
            "level_layouts",
            {
                "stages": [
                    {"player_x": 100, "configuration": "Stage1ConfigRecord"},
                    {"player_x": 104, "configuration": "Stage2ConfigRecord"},
                ]
            },
        )
        map_path, maps = self.write("stage_maps", tiny_maps())
        screen_path, screens = self.write("screen_maps", tiny_maps())
        self.patch(
            level,
            "read_configurations",
            lambda _root: ([{"name": "Stage1ConfigRecord"}, {"name": "Stage2ConfigRecord"}], {}),
        )
        self.patch(level, "sprite_library", lambda _root: {})
        self.patch(
            level,
            "stage_rows",
            lambda _root, _doc: [
                {"index": index, "record": "fixture", "placements": 1, "palette": "fixture"} for index in range(2)
            ],
        )
        self.patch(level, "open_stage", lambda _root, index, **kw: SerialTinyStage(kw["document"], index))
        self.patch(level, "render_view", lambda *_a, **_k: (self.project / "unused.png", {0}, level.VIEW_WIDTH))
        self.patch(level, "boss_reference_captures", lambda *_a: ())
        for name in ("validate_document", "validate_maps", "validate_screen_maps"):
            self.patch(level, name, self.validator())
        self.patch(level, "validate_stage_scene_references", lambda *_a: None)
        self.window = level.Window(
            self.project,
            self.profile,
            path,
            doc,
            map_path,
            maps,
            deepcopy(maps),
            screen_path,
            screens,
            deepcopy(screens),
            0,
            tk,
            ttk,
            self.messages,
        )

    def _graphics(self, tk, ttk):
        ids = ("tile_art", "compressed_tile_art", "palette_commands", "sprite_mappings", "sprite_animations")
        arguments = []
        for identifier, doc in zip(ids, tiny_documents()):
            arguments.extend(self.write(identifier, doc))
        arguments.extend(self.write("level_layouts", {"fixture": True}))
        for name in (
            "validate_tile_document",
            "validate_compressed_document",
            "validate_palette_document",
            "validate_mapping_document",
            "validate_animation_document",
            "validate_level_document",
        ):
            self.patch(graphics, name, self.validator())
        self.patch(
            graphics,
            "catalogue",
            lambda *_a: [
                {
                    "handler": "FixtureHandler",
                    "spawn_list": "FixtureSpawn",
                    "placement_index": 0,
                    "stage_indices": [0],
                    "object_type": 1,
                }
            ],
        )
        self.window = graphics.Window(self.project, self.profile, *arguments, 0, tk, ttk, self.messages)

    def _screen(self, tk, ttk):
        maps = tiny_maps()
        maps["payloads"][0]["consuming_asset_lists"] = []
        path, maps = self.write("screen_maps", maps)
        stage_path, stage_maps = self.write("stage_maps", deepcopy(maps))
        _, compressed = self.write("compressed_tile_art", tiny_documents()[1])
        _, palettes = self.write("palette_commands", tiny_documents()[2])
        self.patch(screen, "export_maps", lambda *_a: deepcopy(maps))
        self.patch(screen, "export_stage_maps", lambda *_a: deepcopy(stage_maps))
        records = [
            {"id": "title_background", "plane_a": True, "plane_b": False},
            {"id": "story_background", "plane_a": False, "plane_b": True},
        ]
        self.patch(screen, "load_config", lambda *_a: {"supported": records})

        def preview(*args, **_kwargs):
            record = next(item for item in records if item["id"] == args[6])
            return (
                [[(0, 0, 0)]],
                SimpleNamespace(
                    tilemap=object() if record["plane_a"] else None, plane_b=object() if record["plane_b"] else None
                ),
                record,
            )

        self.patch(screen, "stage_preview", preview)
        self.patch(screen, "read_ram_sources", lambda *_a: {})
        self.patch(screen, "write_png", lambda *_a, **_k: None)
        validator = self.validator()
        self.patch(
            screen.Window, "_validate_map_edit", lambda _self, document: validator(document, self.project, self.profile)
        )
        self.window = screen.Window(
            self.project,
            self.profile,
            path,
            maps,
            compressed,
            palettes,
            stage_path,
            stage_maps,
            "title_background",
            tk,
            ttk,
            self.messages,
        )
        self.patch(self.window, "refresh_map_preview_fast", lambda: True)

    def context(self, module, documents):
        context = {}
        handlers = dict(module.HANDLERS)
        for identifier, document in documents.items():
            path, _doc = self.write(identifier, document)
            artifact = next(item for item in self.manifest["artifacts"] if item["id"] == identifier)
            loader, _validator, writer, apply = handlers[artifact["kind"]]
            validator = self.validator()
            handlers[artifact["kind"]] = loader, validator, writer, apply
            context[identifier] = {
                "artifact": artifact,
                "path": path,
                "document": loader(path),
                "load": loader,
                "validate": validator,
                "write": writer,
                "apply": apply,
            }
        self.patch(module, "HANDLERS", handlers)
        return context

    def _text(self, tk, ttk):
        context = self.context(text, text_documents())
        fonts = {name: {"first": 0, "count": 228, "sha256": "0" * 64} for name in ("shared", "japanese", "credits")}
        self.patch(text_character_map, "source_fonts", lambda _root: fonts)
        atomic_write_json(
            self.project / "content/workspace" / self.profile / "text/character_map.json",
            {"schema_version": 1, "profile": self.profile, "source_fonts": fonts, "answers": []},
        )
        self.patch(text, "shared_glyph_tiles", lambda *_a: [[[0] * 8 for _y in range(8)]] * 2)
        self.patch(text, "glyph_pixels", lambda *_a: [[0] * 16 for _y in range(16)])
        self.patch(text, "credits_glyph_art", lambda *_a: object())
        self.patch(text, "credits_glyph_tiles", lambda *_a: [[[0] * 8 for _y in range(8)]] * 2)
        self.patch(text.Window, "_draw_story_strip", lambda *_a: None)
        self.window = text.Window(self.project, self.profile, context, tk, ttk, self.messages, self.files)
        self.window.select_artifact(self.window.state.artifact_ids.index("frontend_text_strings"))

    def _sound(self, tk, ttk):
        docs = {name: item["document"] for name, item in tiny_context().items()}
        docs["sound_sequences"]["payloads"][0].update(name="Sound_BGM_81", family="bgm")
        context = self.context(sound, docs)
        self.patch(sound, "load_tables", lambda *_a: (bytes(256), bytes(256)))
        self.patch(
            sound,
            "ordinary_dac_timing_contract",
            lambda *_a: {"encoded_byte_t_states": 1, "first_to_second_t_states": 1},
        )
        self.window = sound.Window(
            self.project,
            self.profile,
            context,
            tk,
            ttk,
            self.messages,
            self.dialogs,
            self.files,
            gens=self.project / "runtime/Output/Gens.exe",
        )

    def buttons(self):
        def walk(item):
            for child in item.winfo_children():
                yield child
                yield from walk(child)

        return [item for item in walk(self.window.window) if item.winfo_class() == "TButton"]

    def invoke(self, label):
        buttons = [item for item in self.buttons() if item.cget("text") == label]
        if len(buttons) != 1:
            raise AssertionError("expected one actual button " + label)
        buttons[0].invoke()
        self.window.window.update_idletasks()

    def close_callback(self):
        # Invoke the actual Tcl WM_DELETE_WINDOW command, not Window.close directly.
        command = self.window.window.protocol("WM_DELETE_WINDOW")
        self.window.window.tk.call(command)

    def edit(self):
        w = self.window
        if self.studio == "level":
            field = w.placement_fields["x"]
            field.delete(0, "end")
            field.insert(0, "$69" if w.studio.selected().entry.x != 105 else "$6A")
            self.invoke("Apply all")
        elif self.studio == "graphics":
            w.raw_word.set("$000E" if w.palette_state.word != 14 else "$000C")
            self.invoke("Apply raw")
        else:
            w.value_text.set("$02" if w.state.value != 2 else "$03")
            self.invoke("Apply value")

    def dirty(self):
        if self.studio == "level":
            return self.window.dirty or self.window.map_state.dirty
        if self.studio == "graphics":
            return any(
                state.dirty
                for state in (
                    self.window.state,
                    self.window.compressed_state,
                    self.window.palette_state,
                    self.window.mapping_state,
                    self.window.animation_state,
                )
            )
        return bool(self.window.state.dirty)

    def selection(self):
        w = self.window
        if self.studio == "level":
            return w.studio.index, w.studio.selection, w.map_state.payload_index, w.map_state.value_index, w.page_x
        if self.studio == "graphics":
            return (
                w.state.payload_index,
                w.state.tile_index,
                w.compressed_state.payload_index,
                w.palette_state.command_index,
                w.mapping_state.mapping_index,
                w.animation_state.script_index,
                w.gallery_index,
            )
        if self.studio == "screen":
            return w.state.payload_index, w.state.value_index, w.screen_choice.get(), w.preview_record["id"]
        return w.state.artifact_index, w.state.field_index, w.state.value_index

    def fail_writer(self, stack):
        name = {"level": "atomic_write_json", "graphics": "write_tile_document", "screen": "atomic_write_json"}.get(
            self.studio
        )
        failed = mock.Mock(side_effect=OSError("fixture destination temporarily unavailable"))
        if name is not None:
            stack.enter_context(mock.patch.object(self.module, name, new=failed))
        else:
            identifier = self.window.state.artifact_id
            stack.enter_context(mock.patch.dict(self.window.context[identifier], write=failed))
        return failed

    def documents(self):
        w = self.window
        if self.studio == "level":
            return {"level_layouts": w.studio.document(), "stage_maps": w.map_state.document}
        if self.studio == "graphics":
            return dict(
                zip(
                    ("tile_art", "compressed_tile_art", "palette_commands", "sprite_mappings", "sprite_animations"),
                    (
                        w.state.document,
                        w.compressed_state.document,
                        w.palette_state.document,
                        w.mapping_state.document,
                        w.animation_state.document,
                    ),
                )
            )
        if self.studio == "screen":
            return {"screen_maps": w.state.document}
        return w.state.documents

    def disk(self):
        return {identifier: json.loads(path.read_text(encoding="utf-8")) for identifier, path in self.paths.items()}
