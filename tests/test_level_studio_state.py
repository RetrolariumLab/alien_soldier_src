from __future__ import annotations

import sys
import tempfile
import unittest
from copy import deepcopy
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import level_studio, level_studio_model, level_studio_state  # noqa: E402
from authoring.stage_map_model import (  # noqa: E402
    export_document as export_maps,
    validate_document as validate_maps,
)
from authoring.screen_map_model import (  # noqa: E402
    export_document as export_screen_maps,
    validate_document as validate_screen_maps,
)
from authoring.ram_map_state import Workspace as MapWorkspace  # noqa: E402
from authoring.stage_tilemap_model import RAM_BASE  # noqa: E402


class WorkspaceStateTests(unittest.TestCase):
    def setUp(self) -> None:
        self.document = level_studio_model.export_document(ROOT, "jp")

    def test_open_stage_reads_the_workspace_instead_of_the_canonical_list(self) -> None:
        name = self.document["configurations"][0]["fields"]["spawn_list"]
        record = next(item for item in self.document["spawn_lists"] if item["name"] == name)
        record["entries"][0]["x"] += 3
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        self.assertEqual(record["entries"][0]["x"], studio.placements[0].entry.x)

    def test_edits_survive_switching_to_another_stage_document(self) -> None:
        first = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        changed = first.placements[0].entry.x + 1
        first.set_field(0, "x", changed)
        carried = first.document()
        level_studio_state.open_stage(ROOT, 1, profile="jp", document=carried)
        reopened = level_studio_state.open_stage(ROOT, 0, profile="jp", document=carried)
        self.assertEqual(changed, reopened.placements[0].entry.x)

    def test_placement_edits_validate_dispatch_and_pool_before_commit(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        original = studio.placements[0].entry
        with self.assertRaisesRegex(ValueError, "object_type has no dispatch handler"):
            studio.set_field(0, "object_type", 0xFFFF)
        self.assertEqual(original, studio.placements[0].entry)
        self.assertFalse(studio.edited)

        with self.assertRaisesRegex(ValueError, "x must precede the \\$7FFF stop word"):
            studio.set_field(0, "x", 0x7FFF)
        self.assertEqual(original, studio.placements[0].entry)
        self.assertFalse(studio.edited)

        with self.assertRaisesRegex(ValueError, "object-pool boundary"):
            studio.set_field(0, "slot_first", 0xFFFF)
        self.assertEqual(original, studio.placements[0].entry)
        self.assertFalse(studio.edited)

    def test_spawn_gate_follows_source_list_order_and_updates_after_edit(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 4, profile="jp", document=self.document)
        self.assertEqual("Stage5_ObjectSpawnList", studio.spawn_list_name)
        self.assertEqual((0x400, 0x3E0), (studio.placements[12].entry.x, studio.placements[13].entry.x))
        self.assertEqual(0x400, studio.spawn_trigger_x(13))
        studio.set_field(12, "x", 0x420)
        self.assertEqual(0x420, studio.spawn_trigger_x(13))
        with self.assertRaisesRegex(ValueError, "no placement"):
            studio.spawn_trigger_x(len(studio.placements))

    def test_multi_field_placement_edit_is_atomic(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        original = studio.placements[0].entry
        with self.assertRaisesRegex(ValueError, "object_type has no dispatch handler"):
            studio.set_fields(0, {"x": original.x + 1, "object_type": 0xFFFF})
        self.assertEqual(original, studio.placements[0].entry)
        self.assertFalse(studio.edited)
        record = next(item for item in studio.document()["spawn_lists"] if item["name"] == studio.spawn_list.name)
        self.assertEqual(original.x, record["entries"][0]["x"])

        studio.set_fields(0, {"x": original.x + 1, "y": original.y + 1})
        self.assertEqual(original.x + 1, studio.placements[0].entry.x)
        self.assertEqual(original.y + 1, studio.placements[0].entry.y)

    def test_configuration_change_is_all_or_nothing_and_validated(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        original = dict(studio.configuration.fields)
        invalid = dict(original)
        invalid["player_x"] = "$100"
        with self.assertRaisesRegex(ValueError, "player_x must fit dc.b"):
            studio.set_configuration_fields(invalid)
        self.assertEqual(original, studio.configuration.fields)

        valid = dict(original)
        valid["camera_x"] = "$%X" % (int(original["camera_x"]) + 1)
        changed = studio.set_configuration_fields(valid)
        self.assertEqual(int(original["camera_x"]) + 1, changed.camera_x)
        self.assertEqual(changed.camera_x, studio.scene.parallax_origin)
        self.assertEqual(changed.camera_x, studio.source_scene.parallax_origin)
        document = studio.document()
        record = next(item for item in document["configurations"] if item["name"] == changed.name)
        self.assertEqual(changed.camera_x, record["fields"]["camera_x"])

        reopened = level_studio_state.open_stage(ROOT, 0, profile="jp", document=document)
        self.assertEqual(changed.camera_x, reopened.scene.configuration.camera_x)
        self.assertEqual(changed.camera_x, reopened.scene.parallax_origin)

    def test_configuration_spawn_pointer_refreshes_live_placements(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        original_name = studio.spawn_list.name
        destination = next(
            item
            for item in self.document["spawn_lists"]
            if item["name"] != original_name and 0 < len(item["entries"]) < len(studio.placements)
        )
        studio.selection = len(studio.placements) - 1
        values = dict(studio.configuration.fields)
        values["spawn_list"] = destination["name"]
        studio.set_configuration_fields(values)
        self.assertEqual(destination["name"], studio.spawn_list_name)
        self.assertEqual(len(destination["entries"]), len(studio.placements))
        self.assertEqual(-1, studio.selection)
        self.assertEqual(destination["entries"][0]["x"], studio.placements[0].entry.x)

        invalid = dict(studio.configuration.fields)
        invalid["spawn_list"] = "NoSuchObjectSpawnList"
        with self.assertRaisesRegex(ValueError, "not a known spawn list"):
            studio.set_configuration_fields(invalid)
        self.assertEqual(destination["name"], studio.spawn_list_name)
        self.assertEqual(len(destination["entries"]), len(studio.placements))

    def test_configuration_scene_build_failure_keeps_live_state(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        original_scene = studio.scene
        original_spawn = studio.spawn_list
        original_document = studio.document()
        values = dict(studio.configuration.fields)
        values["camera_x"] = int(values["camera_x"]) + 1
        with mock.patch.object(level_studio_state, "open_stage", side_effect=ValueError("scene cannot be built")):
            with self.assertRaisesRegex(ValueError, "scene cannot be built"):
                studio.set_configuration_fields(values)
        self.assertIs(original_scene, studio.scene)
        self.assertIs(original_spawn, studio.spawn_list)
        self.assertEqual(original_document, studio.document())
        self.assertFalse(studio.edited)

    def test_configuration_table_guard_rolls_back_state_and_gui_before_scene_build(self) -> None:
        for profile in ("jp", "eu"):
            document = level_studio_model.export_document(ROOT, profile)
            studio = level_studio_state.open_stage(ROOT, 0, profile=profile, document=document)
            original = studio.document()
            scene = studio.scene
            selection = studio.selection
            values = dict(studio.configuration.fields)
            values["camera_x"] = int(values["camera_x"]) + 8
            values["plane_b_mode"] = "$8004"
            with self.subTest(profile=profile), mock.patch.object(level_studio_state, "open_stage") as reopened:
                with self.assertRaisesRegex(ValueError, "plane_b_mode.*aligned table offset"):
                    studio.set_configuration_fields(values)
                window = object.__new__(level_studio.Window)
                window.studio = studio
                window.configuration_fields = {}
                for field, value in values.items():
                    widget = mock.Mock()
                    widget.get.return_value = value
                    window.configuration_fields[field] = widget
                window.status = mock.Mock()
                window._fold_current = mock.Mock()
                window._changed = mock.Mock()
                window.load = mock.Mock()
                window.apply_configuration()
                self.assertIn("plane_b_mode", window.status.configure.call_args.kwargs["text"])
                reopened.assert_not_called()
                window._fold_current.assert_not_called()
                window._changed.assert_not_called()
                window.load.assert_not_called()
            self.assertEqual(original, studio.document())
            self.assertIs(scene, studio.scene)
            self.assertEqual(selection, studio.selection)
            self.assertFalse(studio.edited)

    def test_plain_stage_route_switches_configuration_and_rejects_special(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.document)
        self.assertTrue(studio.route_editable)
        self.assertEqual("Stage2ConfigRecord", studio.set_stage_configuration("Stage2ConfigRecord").name)
        self.assertEqual("Stage2ConfigRecord", studio.configuration.name)
        self.assertEqual("Stage2ConfigRecord", studio.document()["stage_slots"][0]["configuration"])
        self.assertEqual("Stage2ConfigRecord", level_studio_state.stage_rows(ROOT, studio.document())[0]["record"])
        with self.assertRaisesRegex(ValueError, "no known configuration"):
            studio.set_stage_configuration("InventedConfigRecord")
        self.assertEqual("Stage2ConfigRecord", studio.configuration.name)

        special = level_studio_state.open_stage(ROOT, 7, profile="jp", document=self.document)
        self.assertFalse(special.route_editable)
        with self.assertRaisesRegex(ValueError, "fixed special initializer route"):
            special.set_stage_configuration("Stage1ConfigRecord")

    def test_workspace_rows_follow_an_edited_spawn_pointer(self) -> None:
        records = self.document["configurations"]
        destination = next(item for item in self.document["spawn_lists"] if len(item["entries"]) != 20)
        records[0]["fields"]["spawn_list"] = destination["name"]
        rows = level_studio_state.stage_rows(ROOT, self.document)
        self.assertEqual(len(destination["entries"]), rows[0]["placements"])


class BoundedRenderingTests(unittest.TestCase):
    def test_viewport_render_never_expands_to_the_whole_stage(self) -> None:
        document = level_studio_model.export_document(ROOT, "jp")
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", document=document)
        self.assertGreater(studio.width, 8000)
        with tempfile.TemporaryDirectory() as directory:
            path, _, width = level_studio.render_view(studio, Path(directory), start_x=128, width=64)
            self.assertEqual(64, width)
            self.assertTrue(path.is_file())
            self.assertLess(path.stat().st_size, 100000)

    def test_playtest_command_maps_stage_slot_to_one_based_password_stage(self) -> None:
        self.assertEqual(
            ["make", "--no-print-directory", "playtest-level", "CONTENT_PROFILE=eu", "PLAYTEST_STAGE=13"],
            level_studio.playtest_make_command("eu", 12),
        )
        with self.assertRaisesRegex(ValueError, "slots 0..24"):
            level_studio.playtest_make_command("jp", 25)


class StageMapPreviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.levels = level_studio_model.export_document(ROOT, "jp")
        cls.maps = export_maps(ROOT, "jp")
        cls.screen_maps = export_screen_maps(ROOT, "jp")

    def test_unedited_document_and_reverted_cell_use_original_ram(self) -> None:
        base = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        original_ram = base.scene.tilemap.ram
        changed = deepcopy(self.maps)
        record = next(item for item in changed["payloads"] if item["name"] == "Stage1BaseMappingData6000")
        record["values"][0] ^= 1
        validate_maps(changed, ROOT, "jp")

        edited = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=changed, map_baseline=self.maps
        )
        self.assertNotEqual(original_ram, edited.scene.tilemap.ram)
        self.assertEqual(edited.source_scene.tilemap.ram, original_ram)

        edited.refresh_map_preview(self.maps, self.maps)
        self.assertEqual(original_ram, edited.scene.tilemap.ram)

    def test_configuration_refresh_retains_staged_map_preview(self) -> None:
        changed = deepcopy(self.maps)
        record = next(item for item in changed["payloads"] if item["name"] == "Stage1BaseMappingData6000")
        record["values"][0] ^= 1
        studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=changed, map_baseline=self.maps
        )
        original_ram = studio.source_scene.tilemap.ram
        edited_ram = studio.scene.tilemap.ram
        self.assertNotEqual(original_ram, edited_ram)

        values = dict(studio.configuration.fields)
        values["camera_x"] = int(values["camera_x"]) + 1
        studio.set_configuration_fields(values)
        self.assertEqual(edited_ram, studio.scene.tilemap.ram)
        self.assertEqual(original_ram, studio.source_scene.tilemap.ram)
        self.assertEqual(values["camera_x"], studio.scene.parallax_origin)

    def test_preview_rejects_missing_source_owned_baseline(self) -> None:
        with self.assertRaisesRegex(ValueError, "baseline is required"):
            level_studio_state.open_stage(ROOT, 0, profile="jp", document=self.levels, map_document=self.maps)

    def test_saved_screen_map_edit_is_composed_and_conflicts_fail_closed(self) -> None:
        shared = "SharedMappingData7000"
        peer = deepcopy(self.screen_maps)
        screen_record = next(record for record in peer["payloads"] if record["name"] == shared)
        screen_record["values"] = [0] * screen_record["value_count"]
        validate_screen_maps(peer, ROOT, "jp")
        original = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        composed = level_studio_state.open_stage(
            ROOT,
            0,
            profile="jp",
            document=self.levels,
            map_document=self.maps,
            map_baseline=self.maps,
            screen_document=peer,
            screen_baseline=self.screen_maps,
        )
        self.assertNotEqual(original.scene.tilemap.ram, composed.scene.tilemap.ram)

        same = deepcopy(self.maps)
        same_record = next(record for record in same["payloads"] if record["name"] == shared)
        same_record["values"] = screen_record["values"][:]
        level_studio_state.open_stage(
            ROOT,
            0,
            profile="jp",
            document=self.levels,
            map_document=same,
            map_baseline=self.maps,
            screen_document=peer,
            screen_baseline=self.screen_maps,
        )

        same_record["values"] = [1] * same_record["value_count"]
        with self.assertRaisesRegex(ValueError, "conflicting map workspace edits"):
            level_studio_state.open_stage(
                ROOT,
                0,
                profile="jp",
                document=self.levels,
                map_document=same,
                map_baseline=self.maps,
                screen_document=peer,
                screen_baseline=self.screen_maps,
            )

    def test_preview_pixel_resolves_each_plane_a_map_layer_to_its_source(self) -> None:
        studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        x, y = 355, 0
        plane = studio.scene.tilemap
        self.assertTrue(plane.defined(x, y))
        for role, actual in (
            ("coarse", plane.coarse_index(x, y)),
            ("chunks", plane.chunk_index(x, y)),
            ("patterns", plane.name_word(x, y)),
        ):
            hit = level_studio_state.locate_stage_map_cell(studio, self.maps, x, y, role)
            self.assertEqual(actual, self.maps["payloads"][hit.payload_index]["values"][hit.value_index])
            self.assertEqual(role, hit.role)
            self.assertEqual((x, y), (hit.world_x, hit.world_y))
            neighbour = level_studio_state.locate_stage_map_cell(studio, self.maps, x + 1, y, role)
            self.assertEqual(
                (hit.payload_index, hit.value_index, hit.ram_address),
                (neighbour.payload_index, neighbour.value_index, neighbour.ram_address),
            )

        with self.assertRaisesRegex(ValueError, "outside the stage map preview"):
            level_studio_state.locate_stage_map_cell(studio, self.maps, studio.width, y, "chunks")
        with self.assertRaisesRegex(ValueError, "unsupported stage-map role"):
            level_studio_state.locate_stage_map_cell(studio, self.maps, x, y, "tiles")

    def test_plane_b_hit_uses_viewport_parallax_and_source_owned_streams(self) -> None:
        for profile in ("jp", "eu"):
            maps = export_maps(ROOT, profile)
            studio = level_studio_state.open_stage(ROOT, 0, profile=profile, map_document=maps, map_baseline=maps)
            plane = studio.scene.plane_b
            self.assertIsNotNone(plane)
            for role in ("coarse", "chunks", "patterns"):
                hit = level_studio_state.locate_stage_map_cell(studio, maps, 355, 0, role, "plane_b", 352)
                self.assertEqual(91, hit.world_x)
                actual = {"coarse": plane.coarse_index, "chunks": plane.chunk_index, "patterns": plane.name_word}[role](
                    91, 0
                )
                self.assertEqual(actual, maps["payloads"][hit.payload_index]["values"][hit.value_index])
            with self.assertRaisesRegex(ValueError, "invalid plane A camera"):
                level_studio_state.locate_stage_map_cell(studio, maps, 355, 0, "chunks", "plane_b", 356)
            studio.scene = replace(studio.scene, plane_b=None)
            with self.assertRaisesRegex(ValueError, "plane B has no supported map"):
                level_studio_state.locate_stage_map_cell(studio, maps, 355, 0, "chunks", "plane_b", 352)

    def test_plane_b_brush_changes_a_bounded_stage_preview(self) -> None:
        window = object.__new__(level_studio.Window)
        window.studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        window.project = ROOT
        window.profile = "jp"
        window.map_baseline = self.maps
        window.screen_maps = self.screen_maps
        window.screen_baseline = self.screen_maps
        window.map_state = MapWorkspace(deepcopy(self.maps))
        window.map_choices = list(range(len(self.maps["payloads"])))
        window.page_x = 0
        window.viewport_cell = None
        window.viewport_cell_plane = "plane_a"
        window.viewport_map_plane = mock.Mock()
        window.viewport_map_plane.get.return_value = "plane_b"
        window.viewport_map_role = mock.Mock()
        window.viewport_map_role.get.return_value = "chunks"
        window.map_value_text = mock.Mock()
        window.map_value_text.get.return_value = "$00"
        window.map_paint = mock.Mock()
        window.map_paint.get.return_value = True
        window.messagebox = mock.Mock()
        window.canvas = mock.Mock()
        window.select_map = mock.Mock(side_effect=lambda index: window.map_state.select_payload(index))
        window.show_map_value = mock.Mock()
        window._changed = mock.Mock()
        window.render = mock.Mock()
        window.show_selection = mock.Mock()
        before = window.studio.image(0, 32, 32, 32)
        window.click_viewport_map(SimpleNamespace(x=0, y=32))
        self.assertEqual("plane_b", window.viewport_cell_plane)
        self.assertEqual("Stage1BaseMappingData6800", window.viewport_cell.source)
        self.assertEqual(0, window.map_state.value)
        self.assertNotEqual(before, window.studio.image(0, 32, 32, 32))
        self.assertTrue(window.map_state.dirty)
        window.messagebox.showerror.assert_not_called()

    def test_plane_b_highlight_uses_secondary_camera_origin(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 0, profile="jp", map_document=self.maps, map_baseline=self.maps)
        window = object.__new__(level_studio.Window)
        window.studio = studio
        window.page_x = 352
        window.viewport_cell_plane = "plane_b"
        window.viewport_cell = level_studio_state.locate_stage_map_cell(
            studio, self.maps, 355, 0, "chunks", "plane_b", 352
        )
        window.canvas = mock.Mock()
        window.show_viewport_map_highlight()
        self.assertEqual(
            [
                mock.call(-24, 0, 8, 32, outline="#ffdf64", width=2, tags="map-hit"),
                mock.call(488, 0, 520, 32, outline="#ffdf64", width=2, tags="map-hit"),
            ],
            window.canvas.create_rectangle.call_args_list,
        )

    def test_stage_two_plane_b_brush_crosses_the_static_vram_ring(self) -> None:
        studio = level_studio_state.open_stage(ROOT, 1, profile="jp", map_document=self.maps, map_baseline=self.maps)
        self.assertEqual(448, studio.scene.parallax_x(1792))
        hit = level_studio_state.locate_stage_map_cell(studio, self.maps, 1856, 96, "patterns", "plane_b", 1792)
        self.assertEqual(0, hit.world_x)
        self.assertEqual(
            studio.scene.plane_b.name_word(0, 96), self.maps["payloads"][hit.payload_index]["values"][hit.value_index]
        )

        window = object.__new__(level_studio.Window)
        window.studio = studio
        window.page_x = 1792
        window.viewport_cell_plane = "plane_b"
        window.viewport_cell = hit
        window.canvas = mock.Mock()
        window.show_viewport_map_highlight()
        self.assertEqual(
            [
                mock.call(64, 96, 72, 104, outline="#ffdf64", width=2, tags="map-hit"),
                mock.call(576, 96, 584, 104, outline="#ffdf64", width=2, tags="map-hit"),
            ],
            window.canvas.create_rectangle.call_args_list,
        )

    def test_plane_b_pattern_stream_round_trips_into_visible_tile(self) -> None:
        baseline = level_studio_state.open_stage(ROOT, 0, profile="jp", map_document=self.maps, map_baseline=self.maps)
        hit = level_studio_state.locate_stage_map_cell(baseline, self.maps, 0, 32, "patterns", "plane_b", 0)
        self.assertEqual("Stage1BaseMappingData2000", hit.source)
        self.assertEqual(348, baseline.scene.plane_b.name_word(0, 32))
        edited = deepcopy(self.maps)
        edited["payloads"][hit.payload_index]["values"][hit.value_index] = 0
        validate_maps(edited, ROOT, "jp")
        changed = level_studio_state.open_stage(ROOT, 0, profile="jp", map_document=edited, map_baseline=self.maps)
        self.assertEqual(0, changed.scene.plane_b.name_word(0, 32))
        self.assertNotEqual(baseline.image(0, 32, 8, 8), changed.image(0, 32, 8, 8))

    def test_stage_reference_guard_rejects_new_unwritten_plane_b_pattern(self):
        baseline = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        hit = level_studio_state.locate_stage_map_cell(baseline, self.maps, 0, 32, "chunks", "plane_b", 0)
        safe = deepcopy(self.maps)
        safe["payloads"][hit.payload_index]["values"][hit.value_index] = 0
        validate_maps(safe, ROOT, "jp")
        level_studio_state.validate_stage_map_references(
            ROOT, "jp", self.levels, safe, self.maps, self.screen_maps, self.screen_maps
        )
        unsafe = deepcopy(self.maps)
        unsafe["payloads"][hit.payload_index]["values"][hit.value_index] = 255
        validate_maps(unsafe, ROOT, "jp")  # The fixed slot alone accepts it.
        with self.assertRaisesRegex(ValueError, "pattern RAM \\$FFFF3FE0 has no asset-list writer"):
            level_studio_state.validate_stage_map_references(
                ROOT, "jp", self.levels, unsafe, self.maps, self.screen_maps, self.screen_maps
            )

    def test_window_rolls_back_a_rejected_stage_map_brush(self) -> None:
        window = object.__new__(level_studio.Window)
        window.studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        window.project = ROOT
        window.profile = "jp"
        window.map_baseline = self.maps
        window.screen_maps = self.screen_maps
        window.screen_baseline = self.screen_maps
        window.map_state = MapWorkspace(deepcopy(self.maps))
        hit = level_studio_state.locate_stage_map_cell(window.studio, self.maps, 0, 32, "chunks", "plane_b", 0)
        window.map_state.select_payload(hit.payload_index)
        window.map_state.select_value(hit.value_index)
        previous = window.map_state.value
        original_ram = window.studio.scene.plane_b.ram
        window._changed = mock.Mock()
        window.render = mock.Mock()
        window.show_selection = mock.Mock()
        with self.assertRaisesRegex(ValueError, "no asset-list writer"):
            window._commit_map_edit(255)
        self.assertEqual(previous, window.map_state.value)
        self.assertEqual(original_ram, window.studio.scene.plane_b.ram)
        self.assertFalse(window.map_state.dirty)
        window._changed.assert_not_called()

    def test_stage_reference_guard_covers_distant_editor_pages(self) -> None:
        studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        hit = level_studio_state.locate_stage_map_cell(studio, self.maps, 5000, 32, "chunks")
        ram = bytearray(studio.scene.tilemap.ram)
        ram[hit.ram_address - RAM_BASE] = 0xFF
        altered = bytes(ram)
        scene = replace(
            studio.scene,
            tilemap=replace(studio.scene.tilemap, ram=altered),
            plane_b=replace(studio.scene.plane_b, ram=altered),
        )
        with self.assertRaisesRegex(ValueError, "stage 0 page \\$1180"):
            level_studio_state.validate_stage_scene_references(studio.source_scene, scene, studio.width, 0, "jp")

    def test_periodic_guard_covers_vertical_map_cells_beyond_editor_view(self) -> None:
        studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        plane = studio.scene.tilemap
        address = plane.descriptor.coarse - RAM_BASE + 2 * 32
        self.assertEqual(0, plane.ram[address])
        altered = bytearray(plane.ram)
        altered[address] = 0xFF
        ram = bytes(altered)
        scene = replace(
            studio.scene, tilemap=replace(studio.scene.tilemap, ram=ram), plane_b=replace(studio.scene.plane_b, ram=ram)
        )
        with self.assertRaisesRegex(ValueError, "periodic stage map reference.*coarse index \\$FF"):
            level_studio_state.validate_stage_scene_references(studio.source_scene, scene, studio.width, 0, "jp")

    def test_preview_map_hit_rejects_a_non_map_final_ram_writer(self) -> None:
        studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        hit = level_studio_state.locate_stage_map_cell(studio, self.maps, 355, 0, "chunks")
        plane = studio.scene.tilemap
        overlaid = replace(
            plane, written=plane.written + (("later", "NotAnEditableMap", hit.ram_address - RAM_BASE, 1),)
        )
        studio.scene = replace(studio.scene, tilemap=overlaid)
        with self.assertRaisesRegex(ValueError, "final RAM writer is not an editable"):
            level_studio_state.locate_stage_map_cell(studio, self.maps, 355, 0, "chunks")

    def test_viewport_map_brush_rejects_missing_or_alternate_plane_a(self) -> None:
        studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        original = studio.scene
        studio.scene = replace(original, tilemap=None)
        with self.assertRaisesRegex(ValueError, "no supported default map"):
            level_studio_state.locate_stage_map_cell(studio, self.maps, 355, 0, "chunks")
        plane = original.tilemap
        alternate = replace(plane, descriptor=replace(plane.descriptor, chunks=plane.descriptor.chunks + 0x800))
        studio.scene = replace(original, tilemap=alternate)
        with self.assertRaisesRegex(ValueError, "no supported default map"):
            level_studio_state.locate_stage_map_cell(studio, self.maps, 355, 0, "chunks")
        ram = bytearray(plane.ram)
        ram[plane.descriptor.coarse - RAM_BASE + 1] = 0xFF
        studio.scene = replace(original, tilemap=replace(plane, ram=bytes(ram)))
        with self.assertRaisesRegex(ValueError, "no defined map cell"):
            level_studio_state.locate_stage_map_cell(studio, self.maps, 355, 0, "chunks")

    def test_viewport_click_selects_source_cell_and_dispatches_raw_brush(self) -> None:
        window = object.__new__(level_studio.Window)
        window.studio = level_studio_state.open_stage(
            ROOT, 0, profile="jp", document=self.levels, map_document=self.maps, map_baseline=self.maps
        )
        window.map_state = MapWorkspace(deepcopy(self.maps))
        window.map_choices = list(range(len(self.maps["payloads"])))
        window.page_x = 0
        window.viewport_cell = None
        window.viewport_map_role = mock.Mock()
        window.viewport_map_role.get.return_value = "chunks"
        window.map_value_text = mock.Mock()
        window.map_value_text.get.return_value = "$00"
        window.map_paint = mock.Mock()
        window.map_paint.get.return_value = False
        window.messagebox = mock.Mock()
        window.select_map = mock.Mock(side_effect=lambda index: window.map_state.select_payload(index))
        window.show_map_value = mock.Mock()
        window.show_viewport_map_highlight = mock.Mock()
        window._commit_map_edit = mock.Mock()

        window.click_viewport_map(SimpleNamespace(x=355, y=0))
        hit = window.viewport_cell
        self.assertIsNotNone(hit)
        self.assertEqual(
            (hit.payload_index, hit.value_index), (window.map_state.payload_index, window.map_state.value_index)
        )
        window.messagebox.showerror.assert_not_called()
        window._commit_map_edit.assert_not_called()

        window.map_paint.get.return_value = True
        window.click_viewport_map(SimpleNamespace(x=355, y=0))
        window._commit_map_edit.assert_called_once_with(0)

        window.project = ROOT
        window.profile = "jp"
        window.map_baseline = self.maps
        window.screen_maps = self.screen_maps
        window.screen_baseline = self.screen_maps
        window._changed = mock.Mock()
        window.render = mock.Mock()
        window.show_selection = mock.Mock()
        window._commit_map_edit = level_studio.Window._commit_map_edit.__get__(window)
        window.map_value_text.get.return_value = "$01"
        before = window.studio.scene.tilemap.ram
        pixels_before = window.studio.image(352, 0, 8, 8)
        window.click_viewport_map(SimpleNamespace(x=355, y=0))
        self.assertEqual(1, window.map_state.value)
        self.assertNotEqual(before, window.studio.scene.tilemap.ram)
        self.assertNotEqual(pixels_before, window.studio.image(352, 0, 8, 8))
        self.assertTrue(window.map_state.dirty)
        window.messagebox.showerror.assert_not_called()

    def test_map_value_callback_updates_preview_and_both_documents_save(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            window = object.__new__(level_studio.Window)
            window.project = ROOT
            window.profile = "jp"
            window.path = Path(directory) / "levels.json"
            window.map_path = Path(directory) / "stage_maps.json"
            window.document = deepcopy(self.levels)
            window.map_state = MapWorkspace(deepcopy(self.maps))
            window.map_baseline = self.maps
            window.screen_maps = self.screen_maps
            window.screen_baseline = self.screen_maps
            window.studio = level_studio_state.open_stage(
                ROOT,
                0,
                profile="jp",
                document=window.document,
                map_document=window.map_state.document,
                map_baseline=self.maps,
            )
            original_ram = window.studio.scene.tilemap.ram
            index = next(
                index
                for index, record in enumerate(window.map_state.payloads)
                if record["name"] == "Stage1BaseMappingData6000"
            )
            window.map_choices = [index]
            window.map_state.select_payload(index)
            window.map_index_text = mock.Mock()
            window.map_index_text.get.return_value = "0"
            window.map_value_text = mock.Mock()
            changed = window.map_state.value ^ 1
            window.map_value_text.get.return_value = "$%X" % changed
            window.messagebox = mock.Mock()
            window.note = mock.Mock()
            window.window = mock.Mock()
            window.render = mock.Mock()
            window.show_selection = mock.Mock()
            window.show_map_value = mock.Mock()
            window.dirty = False

            window.apply_map_value()
            self.assertEqual(changed, window.map_state.value)
            self.assertNotEqual(original_ram, window.studio.scene.tilemap.ram)
            self.assertTrue(window.dirty)
            window.messagebox.showerror.assert_not_called()
            self.assertTrue(window.save())
            self.assertTrue(window.path.is_file())
            self.assertTrue(window.map_path.is_file())
            self.assertIn('"values"', window.map_path.read_text(encoding="utf-8"))
            self.assertFalse(window.dirty)

            shared = next(
                index
                for index, record in enumerate(window.map_state.payloads)
                if record["name"] == "SharedMappingData7000"
            )
            window.map_choices = [shared]
            window.map_state.select_payload(shared)
            window.map_value_text.get.return_value = "$1"
            ram_before_rejection = window.studio.scene.tilemap.ram
            window.apply_map_value()
            self.assertEqual(0, window.map_state.value)
            self.assertEqual(ram_before_rejection, window.studio.scene.tilemap.ram)
            self.assertFalse(window.dirty)
            window.messagebox.showerror.assert_called_once()


if __name__ == "__main__":
    unittest.main()
