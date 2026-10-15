"""Real Tk wiring smoke for Level Studio without rendering or map traversal."""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import level_studio  # noqa: E402


def tiny_maps() -> dict:
    return {"payloads": [{
        "name": "fixture_map", "role": "chunks", "value_bits": 8,
        "values": [0] * 64, "value_count": 64,
        "unit_width": 8, "unit_height": 8,
        "decoded_byte_count": 64, "compressed_capacity": 64,
        "uses": [{"stage_table_index": 0}],
    }]}


class TinyStudio:
    def __init__(self, index=0):
        self.index = index
        self.width = level_studio.VIEW_WIDTH
        self.spawn_list_name = "FixtureSpawnList"
        self.scene = object()
        self.source_scene = object()
        self.selection = 0
        entry = SimpleNamespace(
            x=100, y=100, object_type=1, parameter=0,
            slot_first=0, slot_limit=0)
        self.placements = [SimpleNamespace(
            index=0, map_x=100, map_y=100, handler="FixtureHandler",
            entry=entry, describe=lambda: "FixtureHandler fixture placement")]
        self.configuration = SimpleNamespace(name="Stage1ConfigRecord", fields={
            field: 0 for field, _size in level_studio.CONFIG_FIELDS
        })

    @property
    def route_editable(self):
        return self.index in (0, 1, 2, 3, 4, 5)

    def selected(self):
        return self.placements[self.selection]

    def spawn_trigger_x(self, index):
        return max(placement.entry.x for placement in self.placements[:index + 1])

    def select_at(self, _x, _y):
        self.selection = 0

    def set_field(self, index, field, value):
        setattr(self.placements[index].entry, field, int(value[1:], 16))

    def set_configuration_fields(self, values):
        self.configuration.fields.update(values)

    def set_stage_configuration(self, name):
        self.configuration.name = name

    def document(self):
        return {"fixture": "in-memory"}

    def refresh_map_preview(self, *_args):
        self.scene = object()


class LevelStudioWidgetTests(unittest.TestCase):
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
            if os.environ.get("LEVEL_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("Level Studio GUI is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable") from error

    def test_both_profiles_wire_placement_configuration_and_map_controls(self) -> None:
        rows = [{
            "index": index, "record": "fixture", "placements": 1,
            "palette": "fixture",
        } for index in range(8)]
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                messages = mock.Mock()
                messages.askyesnocancel.return_value = None
                actual_tk = self.tk.Tk
                actual_photo = self.tk.PhotoImage

                def hidden_tk():
                    root = actual_tk()
                    root.withdraw()
                    return root

                def tiny_photo(*_args, **_kwargs):
                    return actual_photo(width=1, height=1)

                with (mock.patch.object(self.tk, "Tk", new=hidden_tk),
                      mock.patch.object(self.tk, "PhotoImage", new=tiny_photo),
                      mock.patch.object(level_studio, "sprite_library", return_value={}),
                      mock.patch.object(level_studio, "stage_rows", return_value=rows),
                      mock.patch.object(level_studio, "open_stage",
                                        side_effect=lambda _root, index, **_k:
                                        TinyStudio(index)),
                      mock.patch.object(level_studio, "render_view",
                                        return_value=(ROOT / "build/unused.png", {0},
                                                      level_studio.VIEW_WIDTH)) as renderer,
                      mock.patch.object(level_studio, "validate_maps"),
                      mock.patch.object(
                          level_studio, "validate_stage_scene_references") as guard):
                    window = level_studio.Window(
                        ROOT, profile, ROOT / "build/unused_levels.json", {},
                        ROOT / "build/unused_maps.json", tiny_maps(), tiny_maps(),
                        ROOT / "build/unused_screen_maps.json", {}, {}, 0,
                        self.tk, self.ttk, messages)
                    try:
                        self.assertEqual(3, len(window.canvas.find_withtag("all")))
                        self.assertEqual(1, len(window.map_choices))
                        self.assertTrue(
                            window.boss_reference_button.instate(["disabled"]))
                        self.assertTrue(window.route_button.instate(["!disabled"]))
                        self.assertIn("FixtureHandler", window.handler.cget("text"))
                        previous = window.studio.selected()
                        window.studio.placements.append(SimpleNamespace(
                            index=1, map_x=80, map_y=100, handler="LaterHandler",
                            entry=SimpleNamespace(x=80, y=100, object_type=1,
                                                  parameter=0, slot_first=0,
                                                  slot_limit=0),
                            describe=lambda: "LaterHandler fixture placement"))
                        window.studio.selection = 1
                        window.show_selection()
                        self.assertIn("spawn gate X=$64",
                                      window.handler.cget("text"))
                        window.studio.placements.pop()
                        window.studio.selection = previous.index
                        window.show_selection()
                        self.assertTrue(window.map_details.cget("text"))
                        self.assertEqual(level_studio.VIEW_WIDTH, window.studio.width)
                        window.chooser.current(0)
                        window.chooser.event_generate("<<ComboboxSelected>>")
                        window.map_box.current(0)
                        window.map_box.event_generate("<<ComboboxSelected>>")
                        window.window.update()
                        self.assertEqual(0, window.studio.index)
                        self.assertEqual(0, window.map_state.payload_index)
                        window.load(3)
                        self.assertEqual(
                            profile == "jp",
                            window.boss_reference_button.instate(["!disabled"]))
                        window.load(4)
                        self.assertEqual(
                            profile == "jp",
                            window.boss_reference_button.instate(["!disabled"]))
                        self.assertTrue(window.route_button.instate(["!disabled"]))
                        window.load(7)
                        self.assertTrue(window.route_button.instate(["disabled"]))
                        window.load(0)

                        window.placement_fields["x"].delete(0, "end")
                        window.placement_fields["x"].insert(0, "$68")
                        self.assertTrue(window.apply_placement("x"))
                        self.assertEqual(104, window.studio.selected().entry.x)
                        self.assertTrue(window.dirty)

                        config_field = level_studio.CONFIG_FIELDS[0][0]
                        window.configuration_fields[config_field].delete(0, "end")
                        window.configuration_fields[config_field].insert(0, "$1")
                        with mock.patch.object(window, "load") as load:
                            window.apply_configuration()
                            load.assert_called_once_with(0, fold_current=False)

                        window.route_box.set("Stage2ConfigRecord")
                        with mock.patch.object(window, "load") as load:
                            window.apply_stage_route()
                            load.assert_called_once_with(0, fold_current=False)
                        self.assertEqual(
                            "Stage2ConfigRecord", window.studio.configuration.name)

                        window.map_value_text.set("$100")
                        window.apply_map_value()
                        self.assertEqual(0, window.map_state.value)
                        messages.showerror.assert_called_once()
                        messages.showerror.reset_mock()
                        window.map_value_text.set("$01")
                        window.apply_map_value()
                        self.assertEqual(1, window.map_state.value)
                        self.assertTrue(window.map_state.dirty)
                        guard.assert_called_once()
                        self.assertGreater(renderer.call_count, 1)

                        if profile == "jp":
                            window.studio.index = 4
                            with (mock.patch.object(
                                    level_studio, "render_boss_reference",
                                    return_value=[[(0, 0, 0)]]) as boss_render,
                                  mock.patch.object(level_studio, "write_png"),
                                  mock.patch.object(Path, "mkdir")):
                                popup = window.show_boss_reference()
                                try:
                                    self.assertIn(
                                        "read-only", popup.title())
                                    boss_render.assert_called_once_with(
                                        ROOT, "jp", 4, 7500)
                                    window.studio.index = 0
                                    chooser = next(
                                        child for child in popup.winfo_children()
                                        if isinstance(child, self.ttk.Combobox))
                                    chooser.current(1)
                                    chooser.event_generate("<<ComboboxSelected>>")
                                    window.window.update()
                                    boss_render.assert_called_with(
                                        ROOT, "jp", 4, int(chooser.get()))
                                finally:
                                    popup.destroy()
                            window.studio.index = 0
                        else:
                            with self.assertRaisesRegex(
                                    ValueError, "no JP boss reference"):
                                window.show_boss_reference()

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
    os.environ["LEVEL_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
