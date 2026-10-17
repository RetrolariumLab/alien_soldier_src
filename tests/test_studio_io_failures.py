"""Studio I/O regressions using actual fixed classes and private synthetic state."""
from __future__ import annotations

from contextlib import ExitStack
from copy import deepcopy
import json
import os
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import graphics_studio as graphics, screen_studio as screen, text_studio as text
from authoring import atomic_output, level_studio as level, sound_studio as sound
from authoring.ram_map_state import Workspace

ERRORS = (OSError("source unavailable"), ValueError("invalid field"), RuntimeError("reader failed"),
          TypeError("damaged reader inventory"), KeyError("missing source label"))


def text_window(project):
    documents = {"frontend_text_strings": {"strings": [{"name": "Fixture", "glyphs": [1, 2]}]},
                 "glyph_source_lists": {"font_glyph_count": 128, "lists": [{"name": "Peer", "glyphs": [3, 4]}]}}
    item = text.Window.__new__(text.Window)
    item.project, item.profile = project, "jp"
    item.state = text.Workspace(documents)
    item.state.select_value(1)
    item.state.dirty = {"glyph_source_lists"}
    item.context = {name: {"document": doc, "validate": mock.Mock()} for name, doc in documents.items()}
    item.value_text = mock.Mock()
    item.value_text.get.return_value = "5"
    item.messagebox, item.show_value, item.status, item.window = mock.Mock(), mock.Mock(), mock.Mock(), mock.Mock()
    return item


def map_state():
    metadata = {"value_bits": 8, "unit_width": 2, "unit_height": 2, "role": "patterns",
                "value_count": 4, "decoded_byte_count": 4, "compressed_capacity": 16, "consuming_asset_lists": []}
    item = Workspace({"payloads": [dict(metadata, values=[1, 2, 3, 4]), dict(metadata, values=[5, 6, 7, 8])]})
    item.select_value(1)
    return item


def screen_window(project):
    item = screen.Window.__new__(screen.Window)
    item.project, item.profile, item.state = project, "jp", map_state()
    item.value_text = mock.Mock()
    item.value_text.get.return_value = "9"
    item.messagebox, item.show_value, item.status, item.window = mock.Mock(), mock.Mock(), mock.Mock(), mock.Mock()
    item.index_text, item.payload_box, item.details = mock.Mock(), mock.Mock(), mock.Mock()
    item.preview_pick, item.paint_mode = mock.Mock(), mock.Mock()
    item.preview_pick.get.return_value = item.paint_mode.get.return_value = True
    item.preview_plane, item.preview_role = mock.Mock(), mock.Mock()
    item.preview_plane.get.return_value, item.preview_role.get.return_value = "plane_a", "patterns"
    item.preview_scene, item.preview_ram_sources, item.screen_hit = object(), object(), object()
    item.preview_record = {"id": "Fixture", "width": 2, "height": 2}
    item.refresh_map_preview_fast, item.show_preview_highlight, item._validate_map_edit = mock.Mock(), mock.Mock(), mock.Mock()
    return item


class FixtureTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.project = Path(self.temporary.name)


class ScalarRollbackTests(FixtureTest):
    def test_scalar_and_glyph_rollback_all_dirty_and_selection(self):
        for error in ERRORS:
            for glyph in (None, 5):
                with self.subTest(error=error, glyph=glyph):
                    item = text_window(self.project)
                    before = deepcopy(item.state.documents)
                    selected = (item.state.artifact_index, item.state.field_index, item.state.value_index)
                    item.context["frontend_text_strings"]["validate"].side_effect = error
                    item.apply_value(glyph)
                    self.assertEqual(before, item.state.documents)
                    self.assertEqual({"glyph_source_lists"}, item.state.dirty)
                    self.assertEqual(selected, (item.state.artifact_index, item.state.field_index, item.state.value_index))
                    item.messagebox.showerror.assert_called_once_with("Text Studio", str(error))
                    item.status.configure.assert_not_called()

    def test_success_and_dirty_close_retained(self):
        item = text_window(self.project)
        item.apply_value()
        self.assertEqual(5, item.state.value)
        self.assertEqual({"glyph_source_lists", "frontend_text_strings"}, item.state.dirty)
        item.messagebox.askyesno.return_value = False
        item.close()
        item.window.destroy.assert_not_called()

    def test_unknown_ordinary_validator_error_rolls_back_but_is_not_swallowed(self):
        class UnknownReaderError(Exception): pass
        item = text_window(self.project)
        item.context["frontend_text_strings"]["validate"].side_effect = UnknownReaderError("unexpected reader bug")
        with self.assertRaises(UnknownReaderError): item.apply_value()
        self.assertEqual(2, item.state.value)
        self.assertEqual({"glyph_source_lists"}, item.state.dirty)
        item.messagebox.showerror.assert_not_called()

    def test_baseexception_propagates_without_false_error_dialog(self):
        for error in (KeyboardInterrupt(), SystemExit(2)):
            item = text_window(self.project)
            item.context["frontend_text_strings"]["validate"].side_effect = error
            with self.subTest(error=error), self.assertRaises(type(error)): item.apply_value()
            item.messagebox.showerror.assert_not_called()


class ScreenRollbackTests(FixtureTest):
    def test_ram_ordinary_exception_rethrows_and_preserves_prior_dirty(self):
        for error in ERRORS:
            for dirty in (False, True):
                state = map_state()
                state.dirty = dirty
                before = deepcopy(state.document)
                with self.subTest(error=error, dirty=dirty), self.assertRaises(type(error)):
                    state.replace_value(9, mock.Mock(side_effect=error))
                self.assertEqual(before, state.document)
                self.assertIs(dirty, state.dirty)
                self.assertEqual((0, 1), (state.payload_index, state.value_index))

    def test_paint_owned_cell_selection_rollback_and_success(self):
        state = map_state()
        before = deepcopy(state.document)
        with self.assertRaises(OSError):
            state.paint_pixel(0, 128, 128, 9, mock.Mock(side_effect=OSError("missing source")))
        self.assertEqual(before, state.document)
        self.assertEqual((0, 1), (state.payload_index, state.value_index))
        self.assertFalse(state.dirty)
        state.paint_pixel(0, 128, 128, 9, lambda document: None)
        self.assertEqual((0, 3), (state.payload_index, state.value_index))
        self.assertEqual(9, state.value)

    def test_screen_apply_and_grid_failures_preserve_doc_scene_and_dirty(self):
        for error in ERRORS:
            for method in ("apply_value", "click_cell"):
                item = screen_window(self.project)
                item.state.dirty = True
                before, scene, sources = deepcopy(item.state.document), item.preview_scene, item.preview_ram_sources
                item._validate_map_edit.side_effect = error
                with self.subTest(error=error, method=method):
                    if method == "apply_value": item.apply_value()
                    else: item.click_cell(SimpleNamespace(x=128, y=128))
                    self.assertEqual(before, item.state.document)
                    self.assertEqual((0, 1), (item.state.payload_index, item.state.value_index))
                    self.assertTrue(item.state.dirty)
                    self.assertIs(scene, item.preview_scene)
                    self.assertIs(sources, item.preview_ram_sources)
                    item.messagebox.showerror.assert_called_once_with("Screen Studio", str(error))
                    item.refresh_map_preview_fast.assert_not_called()

    def test_failed_preview_brush_restores_owned_cursor_hit_scene_and_whole_doc(self):
        hit = SimpleNamespace(cell=SimpleNamespace(payload_index=1, value_index=2))
        for error in ERRORS:
            with mock.patch.object(screen, "locate_screen_map_cell", return_value=hit):
                item = screen_window(self.project)
                before, prior_hit, scene = deepcopy(item.state.document), item.screen_hit, item.preview_scene
                item._validate_map_edit.side_effect = error
                with self.subTest(error=error):
                    item.click_preview(SimpleNamespace(x=1, y=1))
                    self.assertEqual(before, item.state.document)
                    self.assertEqual((0, 1), (item.state.payload_index, item.state.value_index))
                    self.assertIs(prior_hit, item.screen_hit)
                    self.assertIs(scene, item.preview_scene)
                    self.assertFalse(item.state.dirty)
                    self.assertEqual(0, item.payload_box.current.call_args.args[0])
                    item.messagebox.showerror.assert_called_once()

    def test_ram_baseexception_is_not_swallowed_or_gui_converted(self):
        for error in (KeyboardInterrupt(), SystemExit(2)):
            state = map_state()
            with self.subTest(error=error), self.assertRaises(type(error)):
                state.replace_value(9, mock.Mock(side_effect=error))

    def test_unknown_preview_validator_error_restores_owned_selection_before_rethrow(self):
        class CustomReaderException(Exception): pass
        hit = SimpleNamespace(cell=SimpleNamespace(payload_index=1, value_index=2))
        with mock.patch.object(screen, "locate_screen_map_cell", return_value=hit):
            item = screen_window(self.project)
            before, previous = deepcopy(item.state.document), item.screen_hit
            item._validate_map_edit.side_effect = CustomReaderException("unexpected reader error")
            with self.assertRaises(CustomReaderException): item.click_preview(SimpleNamespace(x=1, y=1))
            self.assertEqual(before, item.state.document)
            self.assertEqual((0, 1), (item.state.payload_index, item.state.value_index))
            self.assertIs(previous, item.screen_hit)
            self.assertFalse(item.state.dirty)
            item.messagebox.showerror.assert_not_called()

    def test_valid_preview_edit_remains_accepted_when_only_refresh_fails(self):
        hit = SimpleNamespace(cell=SimpleNamespace(payload_index=1, value_index=2))
        with mock.patch.object(screen, "locate_screen_map_cell", return_value=hit):
            item = screen_window(self.project)
            item.refresh_map_preview_fast.return_value = False
            scene = item.preview_scene
            item.click_preview(SimpleNamespace(x=1, y=1))
            self.assertEqual((1, 2), (item.state.payload_index, item.state.value_index))
            self.assertEqual(9, item.state.value)
            self.assertTrue(item.state.dirty)
            self.assertIs(hit, item.screen_hit)
            self.assertIs(scene, item.preview_scene)
            item.messagebox.showerror.assert_not_called()
            item.status.configure.assert_called_once_with(text="Map edit accepted; preview still shows the prior scene")


class BuildLauncherTests(FixtureTest):
    def studios(self):
        graphic = graphics.Window.__new__(graphics.Window)
        graphic.project, graphic.profile = self.project, "jp"
        graphic.save, graphic.messagebox, graphic.status = mock.Mock(return_value=True), mock.Mock(), mock.Mock()
        selected_text = text_window(self.project)
        selected_text.state.dirty.clear()
        return ((graphics, graphic), (screen, screen_window(self.project)), (text, selected_text))

    def test_launcher_oserror_reports_once_no_false_success_no_real_process(self):
        for module, item in self.studios():
            with self.subTest(module=module.__name__), mock.patch.object(module.subprocess, "run", side_effect=FileNotFoundError("make unavailable")) as run:
                item.build_rom()
                run.assert_called_once()
                item.messagebox.showerror.assert_called_once()
                item.messagebox.showinfo.assert_not_called()
                item.status.configure.assert_called_once_with(text="Content build could not be launched.")

    def test_dirty_text_screen_and_failed_graphics_save_never_dispatch_build(self):
        for module, item in self.studios():
            if module is graphics: item.save.return_value = False
            elif module is screen: item.state.dirty = True
            else: item.state.dirty = {"frontend_text_strings"}
            with self.subTest(module=module.__name__), mock.patch.object(module.subprocess, "run") as run:
                item.build_rom()
                run.assert_not_called()

    def test_child_failure_existing_handling_and_baseexception_not_swallowed(self):
        for module, item in self.studios():
            with self.subTest(module=module.__name__), mock.patch.object(module.subprocess, "run", return_value=SimpleNamespace(returncode=2, stdout="bad", stderr="build")):
                item.build_rom()
                item.messagebox.showerror.assert_called_once()
                item.messagebox.showinfo.assert_not_called()
            item.messagebox.reset_mock()
            with mock.patch.object(module.subprocess, "run", side_effect=KeyboardInterrupt()), self.assertRaises(KeyboardInterrupt):
                item.build_rom()
            item.messagebox.showerror.assert_not_called()

    def test_existing_graphics_failed_save_keeps_all_dirty_flags_and_prevents_close(self):
        item = graphics.Window.__new__(graphics.Window)
        item.project, item.profile = self.project, "jp"
        state_names = ("state", "compressed_state", "palette_state", "mapping_state", "animation_state")
        flags = (True, False, True, False, True)
        for name, dirty in zip(state_names, flags): setattr(item, name, SimpleNamespace(document={}, dirty=dirty))
        for name in ("tile_path", "compressed_path", "palette_path", "mapping_path", "animation_path"):
            setattr(item, name, self.project / (name + ".json"))
        item.messagebox, item.window, item.status = mock.Mock(), mock.Mock(), mock.Mock()
        item.messagebox.askyesnocancel.return_value = True
        validators = ("validate_tile_document", "validate_compressed_document", "validate_palette_document", "validate_mapping_document", "validate_animation_document")
        writers = ("write_tile_document", "write_compressed_document", "write_palette_document", "write_mapping_document", "write_animation_document")
        from contextlib import ExitStack
        with ExitStack() as stack:
            for name in validators: stack.enter_context(mock.patch.object(graphics, name))
            write_mocks = [stack.enter_context(mock.patch.object(graphics, name)) for name in writers]
            write_mocks[1].side_effect = OSError("second atomic output unavailable")
            self.assertFalse(item.save())
            self.assertEqual(flags, tuple(getattr(item, name).dirty for name in state_names))
            item.messagebox.showerror.assert_called_once()
            item.status.configure.assert_not_called()
            item.messagebox.reset_mock()
            item.messagebox.askyesnocancel.return_value = True
            item.close()
            item.window.destroy.assert_not_called()
            self.assertEqual(flags, tuple(getattr(item, name).dirty for name in state_names))


class LateSaveBoundaryTests(FixtureTest):
    """Actual Save callbacks/writers, explicit tiny schemas, no Tk or ROM model."""

    def _late_writer_case(self, studio, profile, fail_at):
        module = {"level": level, "graphics": graphics, "text": text, "sound": sound}[studio]
        definitions = {
            "level": (("level_layouts", "atomic_write_json"), ("stage_maps", "atomic_write_json")),
            "graphics": (("tile_art", "write_tile_document"),
                         ("compressed_tile_art", "write_compressed_document"),
                         ("palette_commands", "write_palette_document"),
                         ("sprite_mappings", "write_mapping_document"),
                         ("sprite_animations", "write_animation_document")),
            "text": (("boss_and_ship_message_scripts", "scripted_message_document"),
                     ("credits_text_sequence", "credits_text_document"),
                     ("frontend_text_strings", "frontend_text_document"),
                     ("glyph_source_lists", "glyph_source_list_document"),
                     ("japanese_glyph_sequence", "japanese_glyph_document"),
                     ("results_detail_text", "results_text_document"),
                     ("stage_message_sequences", "stage_message_document"),
                     ("story_text_rows", "story_text_document")),
            "sound": (("sound_envelopes", "sound_envelope_document"),
                      ("sound_instruments", "sound_instrument_document"),
                      ("sound_pcm_samples", "sound_pcm_document"),
                      ("sound_sequences", "sound_sequence_document")),
        }[studio]
        project = self.project / ("%s-%s-%d" % (studio, profile, fail_at))
        paths = {name: project / (name + ".json") for name, _kind in definitions}
        documents = {name: {"fixture_only": True, "profile": profile,
                           "artifact": name, "values": [10, 20]} for name in paths}
        writers = {name: (getattr(module, kind) if studio in ("level", "graphics")
                          else module.HANDLERS[kind][2]) for name, kind in definitions}
        for name, writer in writers.items():
            writer(paths[name], {**documents[name], "values": [1, 2]})
        old_bytes = {name: path.read_bytes() for name, path in paths.items()}
        window = module.Window.__new__(module.Window)
        window.project, window.profile = project, profile
        window.messagebox, window.window = mock.Mock(), mock.Mock()
        window.status = mock.Mock()
        statuses, validations = [window.status], []

        def validate(document, selected_root, selected_profile):
            # This is a tiny explicit fixture schema, not a cartridge validator.
            self.assertEqual(project, selected_root)
            self.assertEqual(profile, selected_profile)
            self.assertEqual({"fixture_only", "profile", "artifact", "values"}, set(document))
            self.assertIs(document["fixture_only"], True)
            self.assertEqual(profile, document["profile"])
            self.assertEqual(documents[document["artifact"]], document)
            validations.append(document["artifact"])

        validators = ()
        if studio == "level":
            window.document = documents["level_layouts"]
            window.studio = SimpleNamespace(document=lambda: window.document)
            window.path, window.map_path = paths["level_layouts"], paths["stage_maps"]
            window.map_state = SimpleNamespace(document=documents["stage_maps"], dirty=True)
            window.dirty, window.note = True, mock.Mock()
            statuses = [window.note]
            states = {"level_layouts": window, "stage_maps": window.map_state}
            validators = ("validate_document", "validate_maps")
        elif studio == "graphics":
            state_names = ("state", "compressed_state", "palette_state", "mapping_state", "animation_state")
            path_names = ("tile_path", "compressed_path", "palette_path", "mapping_path", "animation_path")
            states = {}
            for (name, _kind), state_name, path_name in zip(definitions, state_names, path_names, strict=True):
                state = SimpleNamespace(document=documents[name], dirty=True)
                states[name] = state
                setattr(window, state_name, state)
                setattr(window, path_name, paths[name])
            for name in ("compressed_status", "palette_status", "mapping_status", "animation_status"):
                setattr(window, name, mock.Mock())
                statuses.append(getattr(window, name))
            validators = ("validate_tile_document", "validate_compressed_document", "validate_palette_document",
                          "validate_mapping_document", "validate_animation_document")
        else:
            window.context = {name: {"document": document, "path": paths[name],
                                    "write": writers[name], "validate": validate}
                              for name, document in documents.items()}
            window.state = SimpleNamespace(documents=documents, dirty=set(documents))
            states = None

        def current_documents():
            if states is not None:
                return {name: state.document for name, state in states.items()}
            return {name: record["document"] for name, record in window.context.items()}

        def dirty():
            return ({name: state.dirty for name, state in states.items()}
                    if states is not None else set(window.state.dirty))

        expected, flags = deepcopy(current_documents()), deepcopy(dirty())
        identities = {name: id(document) for name, document in current_documents().items()}
        attempted = []
        original_replace = atomic_output.os.replace
        failure = OSError("late per-file replacement refused")

        def replace(source, destination):
            destination = Path(destination)
            self.assertIn(destination, paths.values())
            self.assertEqual(project, Path(source).parent)
            self.assertEqual(".tmp", Path(source).suffix)
            attempted.append(destination)
            if len(attempted) == fail_at:
                # The actual atomic writer already wrote its complete sibling;
                # fail BEFORE its replacement and retain the real finally cleanup.
                raise failure
            return original_replace(source, destination)

        with ExitStack() as stack:
            for name in validators:
                stack.enter_context(mock.patch.object(module, name, side_effect=validate))
            with mock.patch.object(atomic_output.os, "replace", side_effect=replace):
                result = window.save()
            self.assertIs(None if studio == "text" else False, result)
            self.assertEqual(fail_at, len(attempted))
            self.assertEqual(len(attempted), len(set(attempted)))
            self.assertCountEqual(documents, validations)
            completed = set(attempted[:-1])
            self.assertEqual(fail_at - 1, len(completed))
            for name, path in paths.items():
                if path in completed:
                    self.assertEqual(expected[name], json.loads(path.read_text(encoding="utf-8")))
                    self.assertNotEqual(old_bytes[name], path.read_bytes())
                    self.assertTrue(path.read_bytes().endswith(b"\n"))
                else:
                    self.assertEqual(old_bytes[name], path.read_bytes())
            self.assertEqual(expected, current_documents())
            self.assertEqual(identities, {name: id(document) for name, document in current_documents().items()})
            self.assertEqual(flags, dirty())
            window.messagebox.showerror.assert_called_once_with(studio.title() + " Studio", str(failure))
            window.messagebox.showinfo.assert_not_called()
            window.window.title.assert_not_called()
            for status in statuses:
                status.configure.assert_not_called()
            self.assertEqual(set(paths.values()), set(project.iterdir()))

            # No failure seam remains: retry the actual callback and actual writers.
            validations.clear()
            result = window.save()
            self.assertIs(None if studio == "text" else True, result)
            self.assertCountEqual(documents, validations)
            for name, path in paths.items():
                self.assertEqual(expected[name], json.loads(path.read_text(encoding="utf-8")))
            self.assertEqual(expected, current_documents())
            self.assertEqual(identities, {name: id(document) for name, document in current_documents().items()})
            if states is not None:
                self.assertTrue(all(flag is False for flag in dirty().values()))
            else:
                self.assertEqual(set(), dirty())
            window.messagebox.showerror.assert_called_once()
            for status in statuses:
                status.configure.assert_called_once()
                self.assertIn("Saved", status.configure.call_args.kwargs["text"])
            self.assertEqual(set(paths.values()), set(project.iterdir()))

    def test_level_each_late_save_failure_keeps_partial_files_dirty_then_retry_saves_all(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile, fail_at=2):
                self._late_writer_case("level", profile, 2)

    def test_graphics_each_late_save_failure_keeps_partial_files_dirty_then_retry_saves_all(self):
        for profile in ("jp", "eu"):
            for fail_at in range(2, 6):
                with self.subTest(profile=profile, fail_at=fail_at):
                    self._late_writer_case("graphics", profile, fail_at)

    def test_text_each_late_save_failure_keeps_partial_files_dirty_then_retry_saves_all(self):
        for profile in ("jp", "eu"):
            for fail_at in range(2, 9):
                with self.subTest(profile=profile, fail_at=fail_at):
                    self._late_writer_case("text", profile, fail_at)

    def test_sound_each_late_save_failure_keeps_partial_files_dirty_then_retry_saves_all(self):
        for profile in ("jp", "eu"):
            for fail_at in range(2, 5):
                with self.subTest(profile=profile, fail_at=fail_at):
                    self._late_writer_case("sound", profile, fail_at)


class HiddenTkTests(FixtureTest):
    @classmethod
    def setUpClass(cls):
        from tk_test_lifetime import tk_main_thread_lifetime
        cls.enterClassContext(tk_main_thread_lifetime())

    def test_hidden_real_button_scalar_apply_and_failed_close_without_assets(self):
        try:
            import tkinter as tk
            root = tk.Tk()
            root.withdraw()
        except Exception as error:
            if os.name == "nt" or os.environ.get("GUI_RELIABILITY_REQUIRE_GUI") == "1":
                raise AssertionError("mandatory hidden Tk is unavailable") from error
            self.skipTest("Tk unavailable: " + str(error))
        try:
            item = text_window(self.project)
            item.window = root
            item.value_text = tk.StringVar(master=root, value="5")
            item.status = tk.Label(root, text="prior")
            item.context["frontend_text_strings"]["validate"].side_effect = OSError("source unavailable")
            button = tk.Button(root, command=item.apply_value)
            button.invoke()
            self.assertEqual(2, item.state.value)
            self.assertEqual({"glyph_source_lists"}, item.state.dirty)
            self.assertEqual("prior", item.status.cget("text"))
            item.messagebox.showerror.assert_called_once()
            item.messagebox.askyesno.return_value = False
            item.close()
            self.assertTrue(root.winfo_exists())
        finally:
            root.destroy()


if __name__ == "__main__":
    unittest.main()
