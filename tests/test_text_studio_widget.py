"""Real Tk widget smoke for the eight profile-bound Text Studio artifacts."""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.text_studio import Window, load_context  # noqa: E402
from authoring.text_glyph_picker import CELL_WIDTH  # noqa: E402


class TextStudioWidgetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        from tk_test_lifetime import tk_main_thread_lifetime
        cls.enterClassContext(tk_main_thread_lifetime())
        try:
            import tkinter as tk
            from tkinter import ttk

            probe = tk.Tk()
            probe.withdraw()
            probe.destroy()
            cls.tk, cls.ttk = tk, ttk
        except Exception as error:
            if os.environ.get("TEXT_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("Text Studio GUI is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable") from error
        for profile in ("jp", "eu"):
            if not (ROOT / "content/workspace" / profile / "text/story_rows.json").is_file():
                if os.environ.get("TEXT_WIDGET_REQUIRE_GUI") == "1":
                    raise AssertionError("initialize both content workspaces first")
                raise unittest.SkipTest("content workspaces are not initialized")

    def _window(self, profile):
        context = load_context(ROOT, profile)
        messages = mock.Mock()
        messages.askyesno.return_value = True
        actual_tk = self.tk.Tk

        def hidden_tk():
            root = actual_tk()
            root.withdraw()
            return root

        with mock.patch.object(self.tk, "Tk", new=hidden_tk):
            window = Window(ROOT, profile, context, self.tk, self.ttk, messages)
        return window, messages

    def test_both_profiles_wire_all_artifacts_and_guard_dirty_close(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                window, messages = self._window(profile)
                try:
                    self.assertEqual(8, len(window.state.artifact_ids))
                    for identifier in window.state.artifact_ids:
                        position = window.state.artifact_ids.index(identifier)
                        window.artifact_box.current(position)
                        window.artifact_box.event_generate("<<ComboboxSelected>>")
                        window.window.update()
                        self.assertEqual(identifier, window.state.artifact_id)
                        self.assertTrue(window.field_box["values"])
                        if identifier == "japanese_glyph_sequence":
                            self.assertEqual(256, len(window.glyph_preview.find_all()))
                        elif identifier == "story_text_rows":
                            self.assertEqual(128, len(window.glyph_preview.find_all()))
                            self.assertEqual("grid", window.story_strip.winfo_manager())
                            self.assertEqual((528, 80),
                                             (window.story_photo.width(),
                                              window.story_photo.height()))
                            self.assertTrue(window.story_strip.bind("<Button-1>"))
                            row = next(item for item in
                                       window.state.documents[identifier]["rows"]
                                       if 0xFF in item["accent"][:-1])
                            window.select_field(row["index"] * 2)
                            boundary = row["accent"].index(0xFF)
                            window._select_story_strip_pixel(
                                SimpleNamespace(x=boundary * 16 + 8, y=56))
                            self.assertEqual("accent", window.state.field.key)
                            self.assertEqual(boundary, window.state.value_index)
                            self.assertEqual(str(boundary), window.index_text.get())
                            self.assertIn("Protected story accent",
                                          window.glyph_caption.cget("text"))
                            window._select_story_strip_pixel(
                                SimpleNamespace(x=8, y=40))
                            self.assertEqual(boundary, window.state.value_index)
                            window.value_text.set("$01")
                            window.apply_value()
                            self.assertEqual(0xFF, window.state.value)
                            messages.showerror.assert_called_once()
                            messages.showerror.reset_mock()
                        elif identifier in (
                                "boss_and_ship_message_scripts", "glyph_source_lists",
                                "results_detail_text", "frontend_text_strings",
                                "stage_message_sequences"):
                            self.assertEqual(128, len(window.glyph_preview.find_all()))
                            if identifier == "results_detail_text":
                                window.select_field(31)
                                self.assertIn("Results_TotalTimeLabel",
                                              window.state.field.label)
                                self.assertEqual(128,
                                                 len(window.glyph_preview.find_all()))
                        elif identifier == "credits_text_sequence":
                            window.select_field(1)
                            self.assertIn("Credits glyph", window.glyph_caption.cget("text"))
                        else:
                            self.assertEqual("", window.glyph_caption.cget("text"))
                        if identifier != "story_text_rows":
                            self.assertEqual("", window.story_strip.winfo_manager())

                    window.select_artifact(
                        window.state.artifact_ids.index("glyph_source_lists"))
                    before = window.state.value
                    replacement = 0 if before else 1
                    window.value_text.set("$%02X" % replacement)
                    window.apply_value()
                    self.assertEqual(replacement, window.state.value)
                    self.assertIn("glyph_source_lists", window.state.dirty)
                    with mock.patch.object(window.window, "destroy") as destroy:
                        messages.askyesno.return_value = False
                        window.close()
                        destroy.assert_not_called()
                        messages.askyesno.return_value = True
                        window.close()
                        destroy.assert_called_once_with()
                    messages.showerror.assert_not_called()
                finally:
                    window.window.destroy()

    def test_hidden_glyph_picker_tracks_slots_and_applies_one_validated_click(self) -> None:
        window, messages = self._window("jp")
        actual_toplevel = self.tk.Toplevel

        def hidden_toplevel(*args, **kwargs):
            popup = actual_toplevel(*args, **kwargs)
            popup.withdraw()
            return popup

        try:
            window.select_artifact(window.state.artifact_ids.index("frontend_text_strings"))
            before = window.state.values()
            replacement = 0 if before[0] else 1
            with mock.patch.object(self.tk, "Toplevel", new=hidden_toplevel):
                window.choose_button.invoke()
            picker = window.picker
            self.assertIsNotNone(picker)
            self.assertTrue(picker.canvas.bind("<Button-1>"))
            while picker.page:
                picker.previous.invoke()
            window.window.update_idletasks()
            # Tk suppresses pointer events on withdrawn windows. The canvas
            # binding above is present; exercise its callback without showing UI.
            picker.choose(SimpleNamespace(x=replacement * CELL_WIDTH + 1, y=1))
            window.window.update()
            self.assertEqual([replacement] + before[1:], window.state.values())
            self.assertEqual({"frontend_text_strings"}, window.state.dirty)

            window.select_artifact(window.state.artifact_ids.index("japanese_glyph_sequence"))
            window.index_text.set(str(window.state.field.length - 1))
            window.go_to_value()
            self.assertEqual(window.state.glyph_range.page_for(window.state.value), picker.page)
            self.assertLessEqual(len(window.sequence.cget("text").splitlines()), 3)
            self.assertEqual((640, 224), (picker.photo.width(), picker.photo.height()))

            window.select_artifact(window.state.artifact_ids.index("credits_text_sequence"))
            self.assertEqual("disabled", str(window.choose_button["state"]))
            self.assertIsNone(picker.font_range)
            self.assertIsNone(picker.photo)
            window.select_field(1)
            self.assertEqual("credits", picker.font_range.family)
            self.assertEqual("normal", str(window.choose_button["state"]))

            window.select_artifact(window.state.artifact_ids.index("story_text_rows"))
            row = next(item for item in window.state.documents["story_text_rows"]["rows"]
                       if 0xFF in item["accent"][:-1])
            window.select_field(row["index"] * 2 + 1)
            window.index_text.set(str(row["accent"].index(0xFF)))
            window.go_to_value()
            self.assertEqual("disabled", str(window.choose_button["state"]))
            self.assertIsNone(picker.font_range)
            picker.close()
            self.assertIsNone(window.picker)
            messages.showerror.assert_not_called()
        finally:
            window.window.destroy()


if __name__ == "__main__":
    os.environ["TEXT_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
