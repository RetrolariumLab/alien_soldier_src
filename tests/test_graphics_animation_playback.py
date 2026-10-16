"""Bounded animation playback and real withdrawn-Tk callback ownership."""

from __future__ import annotations

from contextlib import ExitStack
from copy import deepcopy
import os
from pathlib import Path
import sys
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import animation_playback_state as playback
from authoring import animation_preview_model as reader
from authoring import graphics_studio as graphics
from authoring import mapping_studio_model
from tk_test_lifetime import tk_main_thread_lifetime
from authoring.sprite_mapping_model import SpritePiece
from tests.test_graphics_studio_widget import tiny_documents


def documents():
    tile, compressed, palette, mapping, animation = tiny_documents()
    first = mapping["blocks"][0]["mappings"][0]
    first["label"] = "A"
    first["pieces"][0].update(x=-4, y=-8, size=5)
    second = deepcopy(first)
    second["label"] = "B"
    second["pieces"][0].update(x=12, y=6, size=0)
    dynamic = deepcopy(first)
    dynamic.update(label="DynamicFrame", dynamic=True)
    dynamic["pieces"][0]["art"] = "DynamicArt"
    dynamic["pieces"][0]["art_addend"] = 0
    mapping["blocks"][0]["mappings"] += [second, dynamic]
    animation["frame_targets"] = ["A", "B", "DynamicFrame"]
    animation["scripts"] = [
        {"name": "Loop", "source_path": "fixture.s", "frames": [
            {"jump": False, "target": "A", "duration": 2},
            {"jump": False, "target": "B", "duration": 1},
            {"jump": True, "target": "Loop", "duration": 0}]},
        {"name": "Hold", "source_path": "fixture.s", "frames": [
            {"jump": False, "target": "B", "duration": 0xFF}]},
        {"name": "Dynamic", "source_path": "fixture.s", "frames": [
            {"jump": False, "target": "DynamicFrame", "duration": 1}]},
        {"name": "Fallthrough", "source_path": "fixture.s", "frames": [
            {"jump": False, "target": "A", "duration": 1}]},
    ]
    return tile, compressed, palette, mapping, animation


def fixture_catalog(_project, profile, animation_document, *, mapping_document):
    """Real temporal engine on tiny documents; not source/native certification."""
    scripts = {record["name"]: tuple(reader.Entry(frame["target"], frame["duration"])
                                    for frame in record["frames"])
               for record in animation_document["scripts"]}
    mappings = {}
    for block in mapping_document["blocks"]:
        for mapping in block["mappings"]:
            pieces = tuple(SpritePiece(
                piece["attributes"], piece["size"], piece["link"], piece["y"], piece["x"],
                piece.get("art", ""), piece.get("art_addend", 0)) for piece in mapping["pieces"])
            mappings[mapping["label"]] = reader.FrameGeometry(mapping["label"], pieces, "fixture.s")
    return reader.Catalog(scripts, mappings, {"profile": profile, "test_fixture": True})


class PlaybackControllerTests(unittest.TestCase):
    def prepared(self, script="Loop", profile="jp"):
        docs = documents()
        controller = playback.PlaybackController(ROOT, profile)
        with mock.patch.object(reader, "build_catalog", side_effect=fixture_catalog) as builder:
            controller.prepare(script, docs[4], docs[3])
        return controller, docs, builder

    def test_lazy_snapshot_is_explicit_profile_and_unsaved_documents(self):
        for profile in ("jp", "eu"):
            controller, docs, builder = self.prepared(profile=profile)
            builder.assert_called_once_with(ROOT, profile, docs[4], mapping_document=docs[3])
            self.assertEqual(reader.CallerState(0xE0, 0), controller.caller)
            self.assertEqual(0, controller.invocations)
            self.assertIn("no reader invocation", controller.details())
            self.assertEqual((-4, -8, 16, 16), controller.geometry.bounds)

    def test_timed_geometry_and_relative_loop_are_not_first_frame_preview(self):
        controller, _docs, _builder = self.prepared()
        output = [controller.advance() for _index in range(4)]
        self.assertEqual(["A", "A", "B", "A"], [item.geometry.symbol for item in output])
        self.assertEqual([2, 1, 1, 2], [item.after.timer for item in output])
        self.assertEqual(reader.Cursor("Loop", 2), controller.last.jump_entry)
        self.assertIn("jump via Loop[2]", controller.details())
        self.assertFalse(controller.last.document()["runtime_fidelity_verified"])

    def test_budget_is_4096_invocations_and_cannot_be_bypassed_by_play(self):
        controller, _docs, _builder = self.prepared()
        controller.playing = True
        for _index in range(reader.MAX_STEPS):
            controller.advance()
        self.assertFalse(controller.playing)
        before = controller.state
        with self.assertRaisesRegex(reader.UnsupportedPlayback, "budget exhausted"):
            controller.advance()
        self.assertEqual(before, controller.state)
        self.assertEqual(reader.MAX_STEPS, controller.invocations)

    def test_source_hold_stops_viewer_without_255_call_duration_guess(self):
        controller, _docs, _builder = self.prepared("Hold")
        controller.playing = True
        controller.advance()
        self.assertTrue(controller.playing)
        held = controller.advance()
        self.assertFalse(controller.playing)
        self.assertEqual("hold-negative-low-byte", held.event)
        self.assertEqual(0xFF, controller.state.timer)
        self.assertEqual(held.before, held.after)

    def test_dynamic_mapping_and_unsupported_caller_are_explicit_errors(self):
        docs = documents()
        for profile in ("jp", "eu"):
            controller = playback.PlaybackController(ROOT, profile)
            with mock.patch.object(reader, "build_catalog", side_effect=fixture_catalog):
                with self.assertRaisesRegex(reader.UnsupportedPlayback, "eight-byte dynamic"):
                    controller.prepare("Dynamic", docs[4], docs[3])
                self.assertIsNone(controller.catalog)
                controller.caller = reader.CallerState(0xC0)
                with self.assertRaisesRegex(reader.UnsupportedPlayback, "do not select"):
                    controller.prepare("Loop", docs[4], docs[3])

    def test_invalidate_discards_snapshot_and_unprepared_step_never_advances(self):
        controller, _docs, _builder = self.prepared()
        controller.advance()
        controller.invalidate()
        self.assertIsNone(controller.catalog)
        self.assertIsNone(controller.geometry)
        self.assertEqual(0, controller.invocations)
        with self.assertRaisesRegex(ValueError, "not been prepared"):
            controller.advance()


class CanonicalPlaybackControllerTests(unittest.TestCase):
    def test_both_real_profiles_use_unsaved_duration_and_mapping_geometry(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                animation_document = reader.workspace.export_document(ROOT, profile)
                mapping_document = mapping_studio_model.export_document(ROOT, profile)
                animation = next(record for record in animation_document["scripts"]
                                 if record["name"] == "Enemy_BirdAnimation00")
                animation["frames"][0]["duration"] = 5
                block = next(record for record in mapping_document["blocks"]
                             if record["name"] == "Enemy_BirdSpriteMapping00")
                first = next(record for record in block["mappings"] if record["offset"] == 0)
                edited_x = first["pieces"][0]["x"] + 1
                first["pieces"][0]["x"] = edited_x
                controller = playback.PlaybackController(ROOT, profile)
                controller.prepare("Enemy_BirdAnimation00", animation_document, mapping_document)
                self.assertEqual(profile, controller.catalog.proof["profile"])
                self.assertTrue(controller.catalog.proof["source_reader_verified"])
                self.assertTrue(controller.catalog.proof["source_caller_verified"])
                self.assertTrue(controller.catalog.proof["unsaved_mapping_document_supplied"])
                self.assertEqual(270, controller.catalog.proof["mapping_editor_targets_applied"])
                self.assertFalse(controller.catalog.proof["native_run"])
                self.assertFalse(controller.catalog.proof["runtime_fidelity_verified"])
                observed = [controller.advance() for _index in range(6)]
                self.assertEqual(["Enemy_BirdSpriteMapping00"] * 5 + ["Enemy_BirdSpriteMapping01"],
                                 [item.geometry.symbol for item in observed])
                self.assertEqual([5, 4, 3, 2, 1, 3], [item.after.timer for item in observed])
                self.assertEqual(edited_x, observed[0].geometry.pieces[0].x)
                self.assertEqual(6, len(observed[0].geometry.pieces))
                # Catalog snapshots must not follow later mutations of editor dictionaries.
                first["pieces"][0]["x"] += 1
                animation["frames"][0]["duration"] = 6
                self.assertEqual(edited_x, observed[0].geometry.pieces[0].x)
                self.assertEqual(5, controller.catalog.scripts["Enemy_BirdAnimation00"][0].duration)


class GraphicsAnimationWidgetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.enterClassContext(tk_main_thread_lifetime())
        try:
            import tkinter as tk
            from tkinter import ttk
            probe = tk.Tk()
            probe.withdraw()
            probe.destroy()
            cls.tk, cls.ttk = tk, ttk
        except Exception as error:
            if os.name == "nt" or os.environ.get("GRAPHICS_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("mandatory animation Tk tests require a display") from error
            raise unittest.SkipTest("Tk display unavailable") from error

    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.builder = self.stack.enter_context(mock.patch.object(
            reader, "build_catalog", side_effect=fixture_catalog))
        self.stack.enter_context(mock.patch.object(graphics, "ANIMATION_VIEW_INTERVAL_MS", 100000))
        gallery = [{"handler": "Fixture", "spawn_list": "List", "placement_index": 0,
                    "stage_indices": [0], "object_type": 1}]
        self.stack.enter_context(mock.patch.object(graphics, "catalogue", return_value=gallery))
        self.writers = [self.stack.enter_context(mock.patch.object(graphics, name)) for name in (
            "write_tile_document", "write_compressed_document", "write_palette_document",
            "write_mapping_document", "write_animation_document")]
        self.docs = documents()
        self.messages = mock.Mock()
        self.messages.askyesnocancel.return_value = None
        self.messages.askyesno.return_value = False
        actual_tk = self.tk.Tk

        def hidden_tk():
            window = actual_tk()
            window.withdraw()
            return window

        self.stack.enter_context(mock.patch.object(self.tk, "Tk", new=hidden_tk))
        self.windows = []
        self.addCleanup(self.destroy_windows)

    def destroy_windows(self):
        for window in self.windows:
            try:
                window._cancel_animation_timer()
                window.window.destroy()
            except self.tk.TclError:
                pass

    def window(self, profile="jp"):
        arguments = []
        for index, document in enumerate(deepcopy(self.docs)):
            arguments += [ROOT / ("build/unused_animation_gui_%d.json" % index), document]
        arguments += [ROOT / "build/unused_animation_gui_level.json", {}]
        window = graphics.Window(ROOT, profile, *arguments, 0,
                                 self.tk, self.ttk, self.messages)
        self.windows.append(window)
        return window

    def tick(self, window):
        """Invoke the owned callback now, removing its actual Tcl timer first."""
        epoch = window.animation_epoch
        if window.animation_after is not None:
            window.window.after_cancel(window.animation_after)
        window._animation_tick(epoch)

    def test_both_profiles_initialize_lazily_and_buttons_draw_timed_geometry(self):
        for profile in ("jp", "eu"):
            window = self.window(profile)
            self.builder.assert_not_called()
            self.assertEqual([], list(window.animation_canvas.find_all()))
            self.assertEqual({"Play", "Pause", "Step", "Reset"}, set(window.animation_playback_buttons))
            window.animation_playback_buttons["Reset"].invoke()
            self.assertEqual(0, window.animation_playback.invocations)
            self.assertEqual(4, len(window.animation_canvas.find_all()))
            rectangle = next(item for item in window.animation_canvas.find_all()
                             if window.animation_canvas.type(item) == "rectangle")
            x0, y0, x1, y1 = window.animation_canvas.coords(rectangle)
            self.assertEqual((48.0, 48.0), (x1 - x0, y1 - y0))
            window.animation_playback_buttons["Step"].invoke()
            self.assertIn("timer $0002", window.animation_playback_details.cget("text"))
            window.step_animation()
            window.step_animation()
            self.assertEqual("B", window.animation_playback.geometry.symbol)
            self.assertEqual((12, 6, 8, 8), window.animation_playback.geometry.bounds)
            self.assertIn("-> B", window.animation_playback_details.cget("text"))
            rectangle = next(item for item in window.animation_canvas.find_all()
                             if window.animation_canvas.type(item) == "rectangle")
            x0, y0, x1, y1 = window.animation_canvas.coords(rectangle)
            self.assertEqual((24.0, 24.0), (x1 - x0, y1 - y0))
            self.builder.assert_called_once()
            self.builder.reset_mock()
            for writer in self.writers:
                writer.assert_not_called()

    def test_real_timer_pause_and_resume_do_not_mutate_modeled_caller(self):
        window = self.window()
        window.animation_playback_buttons["Play"].invoke()
        token = window.animation_after
        self.assertIn(token, window.window.tk.call("after", "info"))
        self.assertEqual(1, window.animation_playback.invocations)
        state = window.animation_playback.state
        window.animation_playback_buttons["Pause"].invoke()
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        self.assertIsNone(window.animation_after)
        self.assertEqual(state, window.animation_playback.state)
        self.assertEqual(reader.CallerState(0xE0, 0), window.animation_playback.caller)
        window.play_animation()
        self.assertEqual(2, window.animation_playback.invocations)
        self.assertEqual(1, window.animation_playback.state.timer)

    def test_replaced_and_stale_callback_cannot_drop_new_timer_ownership(self):
        window = self.window()
        window.play_animation()
        old_token, old_epoch = window.animation_after, window.animation_epoch
        window.play_animation()
        token = window.animation_after
        self.assertNotEqual(token, old_token)
        self.assertNotIn(old_token, window.window.tk.call("after", "info"))
        before = window.animation_playback.invocations
        window._animation_tick(old_epoch)
        self.assertEqual(before, window.animation_playback.invocations)
        self.assertEqual(token, window.animation_after)

    def test_unsaved_animation_and_mapping_edits_invalidate_and_requalify(self):
        window = self.window()
        window.play_animation()
        token = window.animation_after
        window.animation_duration.set("3")
        window.apply_animation_frame()
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        self.assertIsNone(window.animation_playback.catalog)
        window.mapping_fields["x"].set("7")
        window.apply_mapping_piece()
        window.step_animation()
        self.assertEqual(3, window.animation_playback.state.timer)
        self.assertEqual(7, window.animation_playback.geometry.pieces[0].x)
        args, kwargs = self.builder.call_args
        self.assertIs(window.animation_state.document, args[2])
        self.assertIs(window.mapping_state.document, kwargs["mapping_document"])
        self.assertTrue(window.animation_state.dirty)
        self.assertTrue(window.mapping_state.dirty)
        for writer in self.writers:
            writer.assert_not_called()

    def test_selection_reset_and_manual_step_cancel_pending_callback(self):
        window = self.window()
        for action in (window.step_animation, window.reset_animation):
            window.play_animation()
            token = window.animation_after
            action()
            self.assertNotIn(token, window.window.tk.call("after", "info"))
            self.assertIsNone(window.animation_after)
            self.assertFalse(window.animation_playback.playing)
        window.play_animation()
        token = window.animation_after
        window.animation_chooser.current(1)
        window.select_animation()
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        self.assertIsNone(window.animation_playback.catalog)
        window.step_animation()
        self.assertEqual("Hold", window.animation_playback.state.cursor.script)

    def test_rejected_apply_cancels_timer_without_replacing_valid_snapshot(self):
        window = self.window()
        for variable, action in (
                (window.animation_duration, window.apply_animation_frame),
                (window.mapping_fields["x"], window.apply_mapping_piece)):
            window.play_animation()
            token, catalog = window.animation_after, window.animation_playback.catalog
            variable.set("not-an-integer")
            action()
            self.assertNotIn(token, window.window.tk.call("after", "info"))
            self.assertFalse(window.animation_playback.playing)
            self.assertIs(catalog, window.animation_playback.catalog)
            self.messages.showerror.assert_called_once()
            self.messages.showerror.reset_mock()
        self.assertFalse(window.animation_state.dirty)
        self.assertFalse(window.mapping_state.dirty)

    def test_source_hold_and_budget_stop_without_hidden_callbacks(self):
        window = self.window()
        window.animation_chooser.current(1)
        window.select_animation()
        window.play_animation()
        self.tick(window)
        self.assertIsNone(window.animation_after)
        self.assertFalse(window.animation_playback.playing)
        self.assertIn("Source timer holds", window.animation_status.cget("text"))
        window.animation_chooser.current(0)
        window.select_animation()
        window.reset_animation()
        window.animation_playback.invocations = reader.MAX_STEPS - 1
        window.play_animation()
        self.assertEqual(reader.MAX_STEPS, window.animation_playback.invocations)
        self.assertIsNone(window.animation_after)
        self.assertIn("budget reached", window.animation_status.cget("text"))
        window.play_animation()
        self.assertIsNone(window.animation_after)
        self.messages.showerror.assert_called_once()
        self.assertIn("budget exhausted", self.messages.showerror.call_args.args[1])

    def test_live_tcl_after_dispatches_hold_and_stops_after_two_invocations(self):
        window = self.window()
        window.animation_chooser.current(1)
        window.select_animation()
        callback_errors = mock.Mock()
        window.window.report_callback_exception = callback_errors
        with (mock.patch.object(graphics, "ANIMATION_VIEW_INTERVAL_MS", 0),
              mock.patch.object(reader, "step", wraps=reader.step) as source_step):
            window.play_animation()
            token = window.animation_after
            self.assertIsNotNone(token)
            self.assertEqual(1, window.animation_playback.invocations)
            # Dispatch Tcl's registered callback, not the manual tick helper.
            window.window.update()
            self.assertEqual(2, source_step.call_count)
        self.assertEqual(2, window.animation_playback.invocations)
        self.assertEqual("hold-negative-low-byte", window.animation_playback.last.event)
        self.assertEqual(0xFF, window.animation_playback.state.timer)
        self.assertFalse(window.animation_playback.playing)
        self.assertIsNone(window.animation_after)
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        callback_errors.assert_not_called()
        self.messages.showerror.assert_not_called()

    def test_live_tcl_after_reports_fallthrough_without_hidden_exception(self):
        window = self.window()
        window.animation_chooser.current(3)
        window.select_animation()
        callback_errors = mock.Mock()
        window.window.report_callback_exception = callback_errors
        with (mock.patch.object(graphics, "ANIMATION_VIEW_INTERVAL_MS", 0),
              mock.patch.object(reader, "step", wraps=reader.step) as source_step):
            window.play_animation()
            token = window.animation_after
            self.assertIsNotNone(token)
            self.assertEqual(1, window.animation_playback.invocations)
            window.window.update()
            # The second reader attempt fails; it must not count as a completed call.
            self.assertEqual(2, source_step.call_count)
        self.assertEqual(1, window.animation_playback.invocations)
        self.assertFalse(window.animation_playback.playing)
        self.assertIsNone(window.animation_after)
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        callback_errors.assert_not_called()
        self.messages.showerror.assert_called_once()
        self.assertIn("fall-through", self.messages.showerror.call_args.args[1])
        self.assertIn("Playback stopped", window.animation_status.cget("text"))

    def test_pause_cancels_due_tcl_timer_before_actual_eventloop_dispatch(self):
        window = self.window()
        window.animation_chooser.current(1)
        window.select_animation()
        callback_errors = mock.Mock()
        window.window.report_callback_exception = callback_errors
        with mock.patch.object(graphics, "ANIMATION_VIEW_INTERVAL_MS", 0):
            window.play_animation()
            token = window.animation_after
            self.assertIsNotNone(token)
            window.pause_animation()
            window.window.update()
        self.assertEqual(1, window.animation_playback.invocations)
        self.assertEqual(0xFF, window.animation_playback.state.timer)
        self.assertFalse(window.animation_playback.playing)
        self.assertIsNone(window.animation_after)
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        callback_errors.assert_not_called()
        self.messages.showerror.assert_not_called()

    def test_unsupported_dynamic_and_fallthrough_errors_are_visible_and_stopped(self):
        window = self.window()
        window.animation_chooser.current(2)
        window.select_animation()
        window.play_animation()
        self.assertIsNone(window.animation_after)
        self.assertFalse(window.animation_playback.playing)
        self.messages.showerror.assert_called_once()
        self.assertIn("dynamic mapping", self.messages.showerror.call_args.args[1])
        self.messages.showerror.reset_mock()
        window.animation_chooser.current(3)
        window.select_animation()
        window.play_animation()
        self.tick(window)
        self.assertIsNone(window.animation_after)
        self.assertEqual(1, window.animation_playback.invocations)
        self.messages.showerror.assert_called_once()
        self.assertIn("fall-through", self.messages.showerror.call_args.args[1])

    def test_catalog_error_reports_without_staging_or_saving(self):
        for error in (ValueError("unproved reader"), OSError("missing source")):
            window = self.window()
            self.builder.side_effect = error
            window.play_animation()
            self.assertIsNone(window.animation_after)
            self.assertFalse(window.animation_playback.playing)
            self.assertIn(str(error), window.animation_status.cget("text"))
            self.messages.showerror.assert_called_once_with("Animation playback", str(error))
            self.messages.showerror.reset_mock()
        for writer in self.writers:
            writer.assert_not_called()

    def test_declined_dirty_close_and_reload_preserve_live_timer(self):
        window = self.window()
        window.animation_state.dirty = True
        window.play_animation()
        token, epoch = window.animation_after, window.animation_epoch
        window.close()
        window.reload()
        self.assertEqual(token, window.animation_after)
        self.assertEqual(epoch, window.animation_epoch)
        self.assertTrue(window.animation_playback.playing)
        self.assertIn(token, window.window.tk.call("after", "info"))
        with mock.patch.object(window, "save", return_value=False):
            self.messages.askyesnocancel.return_value = True
            window.close()
        self.assertEqual(token, window.animation_after)
        self.assertTrue(window.animation_playback.playing)
        self.assertTrue(window.window.winfo_exists())

    def test_approved_close_cancels_owned_timer_before_destroy(self):
        window = self.window()
        window.animation_state.dirty = True
        self.messages.askyesnocancel.return_value = False
        window.play_animation()
        token = window.animation_after
        with mock.patch.object(window.window, "destroy") as destroy:
            window.close()
            destroy.assert_called_once_with()
        self.assertIsNone(window.animation_after)
        self.assertFalse(window.animation_playback.playing)
        self.assertNotIn(token, window.window.tk.call("after", "info"))

    def test_accepted_reload_cancels_and_replaces_snapshot_without_catalog_build(self):
        window = self.window()
        window.play_animation()
        token = window.animation_after
        new_docs = deepcopy(self.docs)
        new_docs[4]["scripts"][0]["frames"][0]["duration"] = 4
        loaders = ("load_tile_document", "load_compressed_document", "load_palette_document",
                   "load_mapping_document", "load_animation_document", "load_level_document")
        validators = ("validate_tile_document", "validate_compressed_document", "validate_palette_document",
                      "validate_mapping_document", "validate_animation_document", "validate_level_document")
        with ExitStack() as stack:
            for name, document in zip(loaders, new_docs + ({},)):
                stack.enter_context(mock.patch.object(graphics, name, return_value=document))
            for name in validators:
                stack.enter_context(mock.patch.object(graphics, name))
            window.reload()
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        self.assertIsNone(window.animation_playback.catalog)
        self.assertEqual(1, self.builder.call_count)
        window.step_animation()
        self.assertEqual(4, window.animation_playback.state.timer)

    def test_failed_accepted_reload_stops_timer_and_preserves_edit_documents(self):
        window = self.window()
        window.play_animation()
        token = window.animation_after
        before = window.animation_state.document
        with mock.patch.object(graphics, "load_tile_document", side_effect=OSError("unreadable workspace")):
            window.reload()
        self.assertNotIn(token, window.window.tk.call("after", "info"))
        self.assertIsNone(window.animation_playback.catalog)
        self.assertIs(before, window.animation_state.document)
        self.messages.showerror.assert_called_once_with("Graphics Studio", "unreadable workspace")


if __name__ == "__main__":
    os.environ["GRAPHICS_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
