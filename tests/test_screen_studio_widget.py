"""Real Tk wiring smoke for profile-bound Screen Studio controls."""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import screen_studio  # noqa: E402


class ScreenStudioWidgetTests(unittest.TestCase):
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
            if os.environ.get("SCREEN_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("Screen Studio GUI is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable") from error
        for profile in ("jp", "eu"):
            if not (ROOT / "content/workspace" / profile / "screens/maps.json").is_file():
                if os.environ.get("SCREEN_WIDGET_REQUIRE_GUI") == "1":
                    raise AssertionError("initialize both content workspaces first")
                raise unittest.SkipTest("content workspaces are not initialized")

    def test_both_profiles_wire_screen_map_controls_without_staging(self) -> None:
        records = {item["id"]: item for item in screen_studio.load_config(ROOT)["supported"]}
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                context = screen_studio.load_context(ROOT, profile)
                messages = mock.Mock()
                messages.askyesno.return_value = True
                actual_tk = self.tk.Tk
                actual_photo = self.tk.PhotoImage

                def hidden_tk():
                    root = actual_tk()
                    root.withdraw()
                    return root

                def tiny_photo(*_args, **_kwargs):
                    return actual_photo(width=1, height=1)

                def tiny_preview(*args, **_kwargs):
                    record = records[args[6]]
                    scene = SimpleNamespace(
                        tilemap=object() if record["plane_a"] else None, plane_b=object() if record["plane_b"] else None
                    )
                    return [[(0, 0, 0)]], scene, record

                window = None
                with (
                    mock.patch.object(self.tk, "Tk", new=hidden_tk),
                    mock.patch.object(self.tk, "PhotoImage", new=tiny_photo),
                    mock.patch.object(screen_studio, "stage_preview", side_effect=tiny_preview) as preview,
                    mock.patch.object(screen_studio, "read_ram_sources", return_value={}),
                    mock.patch.object(screen_studio, "write_png") as write_png,
                    mock.patch.object(screen_studio.Window, "_validate_map_edit"),
                ):
                    try:
                        window = screen_studio.Window(
                            ROOT, profile, *context[1:], "title_background", self.tk, self.ttk, messages
                        )
                        self.assertEqual("title_background", window.preview_record["id"])
                        self.assertEqual(1, len(window.canvas.find_all()))
                        self.assertEqual(8, len(window.state.payloads))
                        write_png.assert_called_once()

                        window.screen_box.current(window.screen_ids.index("story_background"))
                        window.screen_box.event_generate("<<ComboboxSelected>>")
                        window.window.update()
                        self.assertEqual("story_background", window.preview_record["id"])
                        self.assertEqual("plane_b", window.preview_plane.get())
                        self.assertEqual(2, preview.call_count)

                        window.payload_box.current(1)
                        window.payload_box.event_generate("<<ComboboxSelected>>")
                        window.window.update()
                        self.assertEqual(1, window.state.payload_index)
                        self.assertTrue(window.details.cget("text"))

                        byte_index = next(
                            index for index, payload in enumerate(window.state.payloads) if payload["value_bits"] == 8
                        )
                        window.select_payload(byte_index)
                        before = window.state.value
                        window.value_text.set("$100")
                        window.apply_value()
                        self.assertEqual(before, window.state.value)
                        messages.showerror.assert_called_once()
                        messages.showerror.reset_mock()

                        replacement = 0 if before else 1
                        window.value_text.set("$%02X" % replacement)
                        with mock.patch.object(window, "refresh_map_preview_fast", return_value=True) as replay:
                            window.apply_value()
                        self.assertEqual(replacement, window.state.value)
                        self.assertTrue(window.state.dirty)
                        replay.assert_called_once_with()

                        with mock.patch.object(window.window, "destroy") as destroy:
                            messages.askyesno.return_value = False
                            window.close()
                            destroy.assert_not_called()
                            messages.askyesno.return_value = True
                            window.close()
                            destroy.assert_called_once_with()
                        messages.showerror.assert_not_called()
                    finally:
                        if window is not None:
                            window.window.destroy()


if __name__ == "__main__":
    os.environ["SCREEN_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
