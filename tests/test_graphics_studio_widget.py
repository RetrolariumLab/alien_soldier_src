"""Real Tk wiring smoke for Graphics Studio with bounded in-memory fixtures."""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import graphics_studio  # noqa: E402


def tiny_documents() -> tuple[dict, dict, dict, dict, dict]:
    tile = {
        "payloads": [
            {
                "name": "fixture_tile",
                "blocks": [{"tiles": ["0" * 64]}],
            }
        ]
    }
    compressed = {
        "payloads": [
            {
                "name": "fixture_compressed",
                "tile_count": 1,
                "compressed_capacity": 64,
                "blocks": [{"tiles": ["0" * 64]}],
            }
        ]
    }
    palettes = {
        "commands": [
            {
                "label": "fixture_palette",
                "colour_count": 1,
                "destination": 0,
                "storage": "fixture",
                "source_path": "fixture",
                "colours": [0],
            }
        ]
    }
    mappings = {
        "blocks": [
            {
                "storage": "fixture",
                "payload_path": "",
                "source_path": "fixture",
                "mappings": [
                    {
                        "label": "fixture_mapping",
                        "dynamic": False,
                        "pieces": [
                            {
                                "x": 0,
                                "y": 0,
                                "attributes": 0x8000,
                                "size": 0,
                                "link": 0,
                            }
                        ],
                    }
                ],
            }
        ]
    }
    animations = {
        "frame_targets": ["fixture_mapping"],
        "scripts": [
            {
                "name": "fixture_animation",
                "source_path": "fixture",
                "frames": [
                    {
                        "jump": False,
                        "target": "fixture_mapping",
                        "duration": 1,
                    }
                ],
            }
        ],
    }
    return tile, compressed, palettes, mappings, animations


class GraphicsStudioWidgetTests(unittest.TestCase):
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
            if os.environ.get("GRAPHICS_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("Graphics Studio GUI is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable") from error

    def test_both_profiles_wire_five_editors_and_gallery_without_staging(self) -> None:
        gallery = [
            {
                "handler": "FixtureHandler",
                "spawn_list": "FixtureSpawnList",
                "placement_index": 0,
                "stage_indices": [0],
                "object_type": 1,
            }
        ]
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                tile, compressed, palettes, mappings, animations = tiny_documents()
                messages = mock.Mock()
                messages.askyesnocancel.return_value = None
                actual_tk = self.tk.Tk

                def hidden_tk():
                    root = actual_tk()
                    root.withdraw()
                    return root

                with (
                    mock.patch.object(self.tk, "Tk", new=hidden_tk),
                    mock.patch.object(graphics_studio, "catalogue", return_value=gallery),
                ):
                    window = graphics_studio.Window(
                        ROOT,
                        profile,
                        ROOT / "build/unused_tile.json",
                        tile,
                        ROOT / "build/unused_compressed.json",
                        compressed,
                        ROOT / "build/unused_palette.json",
                        palettes,
                        ROOT / "build/unused_mapping.json",
                        mappings,
                        ROOT / "build/unused_animation.json",
                        animations,
                        ROOT / "build/unused_level.json",
                        {},
                        0,
                        self.tk,
                        self.ttk,
                        messages,
                    )
                try:
                    notebook = next(
                        child for child in window.window.winfo_children() if isinstance(child, self.ttk.Notebook)
                    )
                    self.assertEqual(6, len(notebook.tabs()))
                    self.assertEqual(128, len(window.canvas.find_all()))
                    self.assertEqual(128, len(window.compressed_canvas.find_all()))
                    self.assertIn("FixtureHandler", window.gallery_info.cget("text"))
                    for chooser in (
                        window.chooser,
                        window.compressed_chooser,
                        window.palette_chooser,
                        window.mapping_chooser,
                        window.animation_chooser,
                        window.gallery_chooser,
                    ):
                        chooser.current(0)
                        chooser.event_generate("<<ComboboxSelected>>")
                        window.window.update()

                    click = SimpleNamespace(x=1, y=1)
                    window.paint(click)
                    window.paint_compressed(click)
                    self.assertTrue(window.state.dirty)
                    self.assertTrue(window.compressed_state.dirty)

                    window.raw_word.set("$000E")
                    window.apply_palette_word()
                    self.assertEqual(0x000E, window.palette_state.word)
                    window.mapping_fields["x"].set("128")
                    window.apply_mapping_piece()
                    self.assertEqual(0, window.mapping_state.piece["x"])
                    messages.showerror.assert_called_once()
                    messages.showerror.reset_mock()
                    window.mapping_fields["x"].set("1")
                    window.apply_mapping_piece()
                    self.assertEqual(1, window.mapping_state.piece["x"])
                    window.animation_duration.set("2")
                    window.apply_animation_frame()
                    self.assertEqual(2, window.animation_state.frame["duration"])
                    self.assertTrue(window.palette_state.dirty)
                    self.assertTrue(window.mapping_state.dirty)
                    self.assertTrue(window.animation_state.dirty)

                    with mock.patch.object(window.window, "destroy") as destroy:
                        window.close()
                        destroy.assert_not_called()
                        messages.askyesnocancel.return_value = False
                        window.close()
                        destroy.assert_called_once_with()
                    messages.showerror.assert_not_called()
                finally:
                    window.window.destroy()


if __name__ == "__main__":
    os.environ["GRAPHICS_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
