from __future__ import annotations

import copy
import json
import re
import shutil
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.screen_map_model import export_document  # noqa: E402
from authoring import screen_studio  # noqa: E402
from authoring.screen_studio import parse_value  # noqa: E402
from authoring.stage_map_model import export_document as export_stage_maps  # noqa: E402
from authoring.screen_studio_model import build_scene, load_config, render, screen_view_y  # noqa: E402
from authoring.screen_studio_state import (  # noqa: E402
    Workspace,
    locate_screen_map_cell,
    read_ram_sources,
    replay_screen_maps,
    validate_screen_map_references,
    visible_reference_errors,
)
from authoring.stage_tilemap_model import COARSE_COLUMNS, RAM_BASE  # noqa: E402


def _source_blocks(relative: str, names: tuple[str, ...]) -> str:
    """Copy actual labelled bytes/commands, not hand-authored model results."""
    lines = (ROOT / relative).read_text(encoding="utf-8").splitlines()
    starts = {}
    for index, line in enumerate(lines):
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):", line)
        if match:
            starts[match.group(1)] = index
    boundaries = sorted(starts.values()) + [len(lines)]
    blocks = []
    for name in names:
        start = starts[name]
        end = next(index for index in boundaries if index > start)
        blocks.append("\n".join(lines[start:end]))
    return "\n".join(blocks) + "\n"


def _screen_fixture(root: Path) -> None:
    """A physical subset of the real three-screen corpus, not a cached scene.

    All eight RAM streams, art, palettes, source view guards and viewport sizes
    are original. Only unrelated source/assets and the exhaustive stage census
    are absent. One genuine parsed Level consumer preserves shared-map edits.
    Every export, recompression, reference check, render and stage still uses
    the production algorithms against these actual files.
    """
    for relative in (
        "config/authoring/screens.json",
        "src/ui/title_screen.s",
        "src/rendering/scroll_plane_buffers.s",
        "src/rendering/palettes.s",
        "data/artcomp/tiles_1814D4.bin",
        "data/artcomp/tiles_18530A.bin",
        "data/other/byte_182F24.bin",
        "data/other/byte_184378.bin",
        "data/mappings/byte_182CE2.bin",
        "data/mappings/byte_184688.bin",
        "data/mappings/byte_1885A4.bin",
        "data/mappings/byte_1889B0.bin",
        "data/mappings/byte_BB72.bin",
        "data/other/byte_BE1E.bin",
        "data/other/byte_C05C.bin",
    ):
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / relative, target)

    fragments = (
        _source_blocks(
            "src/data/frontend_scene_assets.s",
            (
                "FrontendTitleMappingData4000",
                "FrontendTitleMappingData6000",
                "SharedFrontendAndTransitionMappingData7000",
                "SharedFrontendAndTransitionMappingDataA",
                "SharedFrontendAndTransitionMappingDataB",
                "StoryScreenMappingData4000",
                "StoryScreenMappingData6000",
                "FrontendTitleTileArt3000",
                "StoryScreenTileArt0000",
                "SharedTitleAndOptionsType3DataA",
                "SharedTitleAndOptionsType3DataB",
            ),
        ),
        _source_blocks("src/data/stage_object_assets.s", ("SharedMappingData7000",)),
        _source_blocks(
            "src/ui/options_shared_helpers_and_assets.s",
            ("Frontend_TitleAssetLoadDescriptors", "Options_AssetLoadDescriptors", "Options_OnLabelTiles"),
        ),
        _source_blocks("src/cutscenes/story_screen_and_title_transition.s", ("StoryScreenAssetCommands",)),
        _source_blocks(
            "src/rendering/boss_asset_sets.s",
            (
                "Gfx_DefaultVRAMTransferParameters",
                "Gfx_TitleAndZLeoVRAMTransferParameters",
                "Gfx_FrontendAlternateVRAMTransferParameters",
                "Gfx_ScrollVRAMTransferParameters",
            ),
        ),
    )
    (root / "src/screen_fixture.s").write_text("\n".join(fragments), encoding="utf-8")

    # This is a small, actual stage format/loader, not a forged Stage-map JSON.
    # Mode zero needs no stage plane image; the real shared stream is exported
    # from its RAM transfer and is also loaded by the original story command.
    stages = root / "src/stages"
    stages.mkdir(parents=True)
    (stages / "configuration_records.s").write_text(
        "FixtureConfigRecord: dc.w 0\n"
        " dc.l 0\n dc.w 0\n dc.b 0\n dc.b 0\n dc.w 0\n"
        " dc.w 0\n dc.w 0\n dc.w 0\n dc.w 0\n dc.w 0\n dc.w 0\n"
        " dc.b 0\n dc.b 0\n dc.l 0\n",
        encoding="utf-8",
    )
    (stages / "configuration.s").write_text(
        "Stage_InitializerOffsets: dc.w Fixture_Initialize-Weapon_ClearAmmoRegenTimers\n"
        "Fixture_Initialize:\n lea FixtureConfigRecord(pc),a0\n rts\n",
        encoding="utf-8",
    )
    (stages / "object_loading.s").write_text(
        "Stage_AssetLoaderOffsets: dc.w Fixture_LoadMaps-Stage_LoadSharedMappings\n"
        "Stage_LoadSharedMappings:\n lea Fixture_SharedMaps(pc),a0\n rts\n"
        "Fixture_LoadMaps:\n rts\n"
        "Fixture_SharedMaps: dc.w 6\n dc.l SharedMappingData7000\n"
        " dc.w $7000\n dc.w $FFFF\n",
        encoding="utf-8",
    )
    (stages / "gameplay_entry_states.s").write_text(
        "Stage_EntryPrimaryPlaneVRAMParameterPointers:\n"
        " dc.l Gfx_DefaultVRAMTransferParameters\n"
        "Stage_EntrySecondaryPlaneVRAMParameterPointers:\n"
        " dc.l Gfx_DefaultVRAMTransferParameters\n",
        encoding="utf-8",
    )
    (root / "config/authoring/graphics.json").write_text(
        json.dumps(
            {
                "stage_rendering": {"two_planes": {"planes_not_reproduced": []}},
            }
        ),
        encoding="utf-8",
    )


class PhysicalScreenCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        directory = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls._clear_fixture)
        cls.addClassCleanup(directory.cleanup)
        cls.root = Path(directory.name)
        _screen_fixture(cls.root)
        cls.fixture_bytes = sum(path.stat().st_size for path in cls.root.rglob("*") if path.is_file())

    @classmethod
    def _clear_fixture(cls) -> None:
        # unittest's all-tier runner can execute a class again in one process.
        # No scene/document/root from the removed physical corpus may survive.
        for name in ("root", "document", "config", "documents"):
            if name in cls.__dict__:
                setattr(cls, name, None)


class WorkspaceTests(PhysicalScreenCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls.document = export_document(cls.root, "jp")

    def setUp(self) -> None:
        self.state = Workspace(copy.deepcopy(self.document))

    def test_pattern_location_is_reported_in_four_by_four_units(self) -> None:
        self.assertEqual("patterns", self.state.payload["role"])
        self.state.select_value(17)
        self.assertEqual({"unit": 1, "x": 1, "y": 0}, self.state.location())

    def test_payload_selection_resets_the_value_and_checks_bounds(self) -> None:
        self.state.select_value(3)
        self.state.select_payload(1)
        self.assertEqual(0, self.state.value_index)
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.select_payload(len(self.state.payloads))
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.select_value(len(self.state.payload["values"]))

    def test_edit_sets_dirty_and_enforces_the_declared_width(self) -> None:
        original = self.state.value
        self.state.set_value(original ^ 1)
        self.assertTrue(self.state.dirty)
        with self.assertRaisesRegex(ValueError, "16-bit"):
            self.state.set_value(0x10000)

    def test_value_parser_accepts_editor_hex_forms(self) -> None:
        self.assertEqual(0x1234, parse_value("$1234", 16))
        self.assertEqual(0x1234, parse_value("0x1234", 16))
        self.assertEqual(42, parse_value("42", 8))
        with self.assertRaisesRegex(ValueError, "outside"):
            parse_value("$100", 8)

    def test_unit_grid_maps_cells_to_values_and_masks_partial_tail(self) -> None:
        self.assertEqual(40, self.state.unit_count)
        self.state.select_cell(1, 1, 0)
        self.assertEqual(17, self.state.value_index)
        self.assertEqual(self.state.payload["values"][16:32], self.state.unit_values(1))
        self.assertEqual(4, sum(value is not None for value in self.state.unit_values(39)))
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.select_cell(39, 0, 1)
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.select_cell(0, 4, 0)
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.unit_values(40)

    def test_canvas_hit_testing_covers_each_map_shape(self) -> None:
        self.state.select_pixel(0, 255, 255)
        self.assertEqual(15, self.state.value_index)
        self.state.select_payload(1)
        self.state.select_pixel(0, 255, 255)
        self.assertEqual(63, self.state.value_index)
        self.state.select_payload(2)
        self.state.select_pixel(0, 255, 255)
        self.assertEqual(1023, self.state.value_index)
        with self.assertRaisesRegex(ValueError, "outside"):
            self.state.select_pixel(0, 256, 0)

    def test_paint_uses_validator_and_rolls_back_rejected_value(self) -> None:
        original = self.state.value

        def reject(_document):
            raise ValueError("compressed capacity exceeded")

        with self.assertRaisesRegex(ValueError, "compressed capacity"):
            self.state.paint_pixel(0, 0, 0, original ^ 1, reject)
        self.assertEqual(original, self.state.value)
        self.assertFalse(self.state.dirty)

        self.state.paint_pixel(0, 0, 0, original ^ 1, lambda _document: None)
        self.assertEqual(original ^ 1, self.state.value)
        self.assertTrue(self.state.dirty)


class ScreenCoordinateTests(PhysicalScreenCase):
    @classmethod
    def setUpClass(cls) -> None:
        super().setUpClass()
        cls.config = load_config(cls.root)
        cls.documents = {profile: export_document(cls.root, profile) for profile in ("jp", "eu")}

    def test_supported_planes_resolve_real_screen_pixels_to_source_maps(self) -> None:
        for profile in ("jp", "eu"):
            document = self.documents[profile]
            for record in self.config["supported"]:
                scene = build_scene(self.root, profile, record)
                for plane_name, plane in (("plane_a", scene.tilemap), ("plane_b", scene.plane_b)):
                    if plane is None:
                        continue
                    found = None
                    for y in range(0, record["height"], 16):
                        for x in range(0, record["width"], 16):
                            try:
                                found = locate_screen_map_cell(
                                    scene, record, profile, document, x, y, plane_name, "chunks"
                                )
                            except ValueError:
                                continue
                            break
                        if found is not None:
                            break
                    self.assertIsNotNone(found, (profile, record["id"], plane_name))
                    value = document["payloads"][found.cell.payload_index]["values"][found.cell.value_index]
                    self.assertEqual(value, plane.chunk_index(found.cell.world_x, found.cell.world_y))
                    self.assertLessEqual(found.screen_left, x)
                    self.assertLess(x, found.screen_left + found.pixel_size)
                    self.assertLessEqual(found.screen_top, y)
                    self.assertLess(y, found.screen_top + found.pixel_size)

    def test_absent_plane_and_screen_bounds_fail_closed(self) -> None:
        record = next(item for item in self.config["supported"] if item["id"] == "options_background")
        scene = build_scene(self.root, "jp", record)
        document = self.documents["jp"]
        with self.assertRaisesRegex(ValueError, "selected screen plane is absent"):
            locate_screen_map_cell(scene, record, "jp", document, 0, 0, "plane_a", "chunks")
        with self.assertRaisesRegex(ValueError, "outside the static-screen"):
            locate_screen_map_cell(scene, record, "jp", document, record["width"], 0, "plane_b", "chunks")

    def test_eu_title_pick_uses_independent_upload_coordinates_for_each_plane(self):
        record = next(item for item in self.config["supported"] if item["id"] == "title_background")
        scene = build_scene(self.root, "eu", record)
        document = self.documents["eu"]
        for plane_name, plane, origin_x, origin_y in (
            ("plane_a", scene.tilemap, 0, 16),
            ("plane_b", scene.plane_b, 0x600, 0),
        ):
            for screen_x, screen_y in ((16, 0), (24, 8), (72, 48)):
                with self.subTest(plane=plane_name, x=screen_x, y=screen_y):
                    hit = locate_screen_map_cell(
                        scene, record, "eu", document, screen_x, screen_y, plane_name, "patterns"
                    )
                    # Derive the expected RAM address independently from the
                    # source map's coarse/chunk/pattern read widths and origins.
                    x, y = origin_x + screen_x, origin_y + screen_y
                    descriptor, ram = plane.descriptor, plane.ram
                    coarse = ram[descriptor.coarse - RAM_BASE + ((y >> 8) & 31) * 32 + ((x >> 8) & 31)]
                    chunk = ram[descriptor.chunks - RAM_BASE + coarse * 64 + ((y >> 5) & 7) * 8 + ((x >> 5) & 7)]
                    address = descriptor.patterns + chunk * 32 + ((y >> 3) & 3) * 8 + ((x >> 3) & 3) * 2
                    self.assertEqual(address, hit.cell.ram_address)
                    self.assertEqual(x, hit.cell.world_x)
                    self.assertEqual(y, hit.cell.world_y + plane.y_offset)
                    self.assertEqual(screen_x // 8 * 8, hit.screen_left)
                    self.assertEqual(screen_y // 8 * 8, hit.screen_top)
            chunk_hit = locate_screen_map_cell(scene, record, "eu", document, 16, 0, plane_name, "chunks")
            self.assertEqual(-16 if plane_name == "plane_a" else 0, chunk_hit.screen_top)

    def test_eu_title_visible_guard_uses_lookup_y_not_semantic_camera(self):
        record = next(item for item in self.config["supported"] if item["id"] == "title_background")
        baseline = build_scene(self.root, "eu", record)
        document = self.documents["eu"]
        changed = copy.deepcopy(document)
        loaded = {source for _list, source, _offset, _length in baseline.tilemap.written}
        item = next(item for item in changed["payloads"] if item["name"] in loaded)
        item["values"][0] ^= 1
        stage = export_stage_maps(self.root, "eu")
        with (
            mock.patch("authoring.screen_studio_state.replay_screen_maps", return_value=(None, baseline)),
            mock.patch("authoring.screen_studio_state.visible_reference_errors", return_value=[]) as visible,
            mock.patch("authoring.screen_studio_state.periodic_reference_error", return_value=None),
        ):
            validate_screen_map_references(self.root, "eu", changed, document, stage, stage, ((record, baseline, {}),))
        visible.assert_called_once_with(baseline, baseline, record, "eu", viewport_y=16)

    def test_story_uses_source_selected_physical_plane_b_and_auto_selection(self):
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        for profile in ("jp", "eu"):
            scene = build_scene(self.root, profile, record)
            self.assertIsNone(scene.tilemap)
            self.assertEqual("Gfx_ScrollVRAMTransferParameters", scene.plane_b.descriptor.name)
            self.assertEqual(0x6000, scene.plane_b.descriptor.plane_base)
            window = object.__new__(screen_studio.Window)
            window.preview_plane = mock.Mock()
            window.preview_plane.get.return_value = "plane_a"
            window._select_available_plane(scene)
            window.preview_plane.set.assert_called_once_with("plane_b")
            with self.assertRaisesRegex(ValueError, "selected screen plane is absent"):
                locate_screen_map_cell(scene, record, profile, self.documents[profile], 16, 16, "plane_a", "chunks")
            hit = locate_screen_map_cell(scene, record, profile, self.documents[profile], 16, 16, "plane_b", "chunks")
            self.assertEqual("StoryScreenMappingData6000", hit.cell.source)

    def test_available_title_plane_selection_is_not_arbitrarily_changed(self):
        record = next(item for item in self.config["supported"] if item["id"] == "title_background")
        window = object.__new__(screen_studio.Window)
        window.preview_plane = mock.Mock()
        window.preview_plane.get.return_value = "plane_b"
        window._select_available_plane(build_scene(self.root, "jp", record))
        window.preview_plane.set.assert_not_called()

    def test_visible_reference_guard_preserves_canonical_maps_but_rejects_new_holes(self):
        title = next(item for item in self.config["supported"] if item["id"] == "title_background")
        story = next(item for item in self.config["supported"] if item["id"] == "story_background")
        for profile in ("jp", "eu"):
            baseline_title = build_scene(self.root, profile, title)
            self.assertEqual([], visible_reference_errors(baseline_title, baseline_title, title, profile))
            screen = self.documents[profile]
            stage = export_stage_maps(self.root, profile)
            baseline_story = build_scene(self.root, profile, story)
            sources = read_ram_sources(self.root, baseline_story)
            safe = copy.deepcopy(screen)
            chunk = next(item for item in safe["payloads"] if item["name"] == "StoryScreenMappingData6000")
            chunk["values"][0] = 1
            self.assertIsNone(
                replay_screen_maps(
                    baseline_story, story, profile, sources, safe, screen, stage, stage, draw_image=False
                )[0]
            )
            validate_screen_map_references(self.root, profile, safe, screen, stage, stage)
            chunk["values"][0] = 0xFF
            with self.assertRaisesRegex(ValueError, "story_background plane_b.*chunk index \\$FF"):
                validate_screen_map_references(self.root, profile, safe, screen, stage, stage)

    def test_periodic_guard_rejects_a_new_coarse_hole_below_the_screen(self):
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        baseline = build_scene(self.root, "jp", record)
        plane = baseline.plane_b
        address = plane.descriptor.coarse - RAM_BASE + 2 * COARSE_COLUMNS
        self.assertEqual(0, plane.ram[address])
        altered = bytearray(plane.ram)
        altered[address] = 0xFF
        candidate = replace(baseline, plane_b=replace(plane, ram=bytes(altered)))
        self.assertEqual([], visible_reference_errors(baseline, candidate, record, "jp"))
        screen = self.documents["jp"]
        changed = copy.deepcopy(screen)
        payload = next(item for item in changed["payloads"] if item["name"] == "SharedMappingData7000")
        payload["values"][2 * COARSE_COLUMNS] = 0xFF
        stage = export_stage_maps(self.root, "jp")
        context = ((record, baseline, {}),)
        with mock.patch("authoring.screen_studio_state.replay_screen_maps", return_value=(None, candidate)):
            with self.assertRaisesRegex(
                ValueError, "periodic screen map reference: story_background plane_b.*coarse index \\$FF"
            ):
                validate_screen_map_references(self.root, "jp", changed, screen, stage, stage, context)

    def test_map_guard_skips_a_screen_that_does_not_load_the_changed_stream(self):
        title = next(item for item in self.config["supported"] if item["id"] == "title_background")
        baseline = build_scene(self.root, "jp", title)
        screen = self.documents["jp"]
        changed = copy.deepcopy(screen)
        payload = next(item for item in changed["payloads"] if item["name"] == "StoryScreenMappingData6000")
        payload["values"][0] = 1
        stage = export_stage_maps(self.root, "jp")
        with mock.patch("authoring.screen_studio_state.replay_screen_maps") as replay:
            validate_screen_map_references(self.root, "jp", changed, screen, stage, stage, ((title, baseline, {}),))
        replay.assert_not_called()

    def test_visible_reference_guard_rejects_unloaded_coarse_target(self):
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        baseline = build_scene(self.root, "jp", record)
        plane = baseline.plane_b
        x, y = record["camera_b_x"], record["camera_b_y"]
        offset = plane.descriptor.coarse - RAM_BASE + ((y >> 8) & 0x1F) * COARSE_COLUMNS + ((x >> 8) & 0x1F)
        ram = bytearray(plane.ram)
        ram[offset] = 0xFF
        changed = replace(baseline, plane_b=replace(plane, ram=bytes(ram)))
        errors = visible_reference_errors(baseline, changed, record, "jp")
        self.assertRegex(errors[0], "story_background plane_b.*coarse index \\$FF")

    def test_visible_reference_guard_rejects_a_split_pattern_writer(self):
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        baseline = build_scene(self.root, "jp", record)
        hit = locate_screen_map_cell(baseline, record, "jp", self.documents["jp"], 0, 0, "plane_b", "patterns")
        later = ("later", "HalfPatternWord", hit.cell.ram_address - RAM_BASE, 1)
        changed = replace(baseline, plane_b=replace(baseline.plane_b, written=baseline.plane_b.written + (later,)))
        errors = visible_reference_errors(baseline, changed, record, "jp")
        self.assertRegex(errors[0], "story_background plane_b.*pattern RAM")

    def test_viewport_click_paints_the_selected_screen_map_value(self) -> None:
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        window = object.__new__(screen_studio.Window)
        window.project = self.root
        window.profile = "jp"
        window.state = Workspace(copy.deepcopy(self.documents["jp"]))
        window.map_baseline = self.documents["jp"]
        window.stage_baseline = export_stage_maps(self.root, "jp")
        window.stage_maps = window.stage_baseline
        window.stage_map_path = self.root / "unused-stage-map-path.json"
        window.preview_scene = build_scene(self.root, "jp", record)
        window.preview_record = record
        window.screen_hit = None
        window.preview_pick = mock.Mock()
        window.preview_pick.get.return_value = True
        window.preview_plane = mock.Mock()
        window.preview_plane.get.return_value = "plane_b"
        window.preview_role = mock.Mock()
        window.preview_role.get.return_value = "chunks"
        window.paint_mode = mock.Mock()
        window.paint_mode.get.return_value = True
        window.value_text = mock.Mock()
        window.value_text.get.return_value = "$01"
        window.index_text = mock.Mock()
        window.messagebox = mock.Mock()
        window.select_payload = mock.Mock(side_effect=lambda index: window.state.select_payload(index))
        window.show_value = mock.Mock()
        window.show_preview_highlight = mock.Mock()
        window.refresh_map_preview_fast = mock.Mock(return_value=True)
        with mock.patch.object(screen_studio, "load_stage_maps", return_value=window.stage_baseline):
            window.click_preview(SimpleNamespace(x=32, y=32))
        self.assertEqual("StoryScreenMappingData6000", window.screen_hit.cell.source)
        self.assertEqual(1, window.state.value)
        self.assertTrue(window.state.dirty)
        window.refresh_map_preview_fast.assert_called_once()
        window.messagebox.showerror.assert_not_called()

    def test_viewport_edit_validator_rejects_competing_level_map_bytes(self) -> None:
        window = object.__new__(screen_studio.Window)
        window.project = self.root
        window.profile = "jp"
        window.map_baseline = self.documents["jp"]
        window.stage_baseline = export_stage_maps(self.root, "jp")
        window.stage_map_path = self.root / "unused-stage-map-path.json"
        stage = copy.deepcopy(window.stage_baseline)
        peer = next(item for item in stage["payloads"] if item["name"] == "SharedMappingData7000")
        peer["values"] = [0] * peer["value_count"]
        screen = copy.deepcopy(window.map_baseline)
        edited = next(item for item in screen["payloads"] if item["name"] == "SharedMappingData7000")
        edited["values"] = [1] * edited["value_count"]
        with mock.patch.object(screen_studio, "load_stage_maps", return_value=stage):
            with self.assertRaisesRegex(ValueError, "conflicting map workspace edits"):
                window._validate_map_edit(screen)

    def test_window_validator_rejects_a_new_visible_pattern_hole(self) -> None:
        window = object.__new__(screen_studio.Window)
        window.project = self.root
        window.profile = "jp"
        window.map_baseline = self.documents["jp"]
        window.stage_baseline = export_stage_maps(self.root, "jp")
        window.stage_map_path = self.root / "unused-stage-map-path.json"
        changed = copy.deepcopy(window.map_baseline)
        chunk = next(item for item in changed["payloads"] if item["name"] == "StoryScreenMappingData6000")
        chunk["values"][0] = 0xFF
        with mock.patch.object(screen_studio, "load_stage_maps", return_value=window.stage_baseline):
            with self.assertRaisesRegex(ValueError, "new undefined visible map"):
                window._validate_map_edit(changed)

    def test_clicked_story_chunk_survives_staging_and_changes_the_screen(self) -> None:
        document = copy.deepcopy(self.documents["jp"])
        record = next(item for item in document["payloads"] if item["name"] == "StoryScreenMappingData6000")
        record["values"][0] = 1
        original = render(self.root, "jp", "story_background")
        baseline_scene = build_scene(
            self.root, "jp", next(item for item in self.config["supported"] if item["id"] == "story_background")
        )
        baseline_sources = read_ram_sources(self.root, baseline_scene)
        stage_baseline = export_stage_maps(self.root, "jp")
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            for name in ("src", "data"):
                shutil.copytree(self.root / name, staged / name)
            with (
                mock.patch.object(screen_studio, "stage_tree"),
                mock.patch.object(screen_studio, "apply_compressed"),
                mock.patch.object(screen_studio, "apply_palettes"),
            ):
                image, scene, screen = screen_studio.stage_preview(
                    self.root, "jp", staged, document, {}, {}, "story_background", with_scene=True
                )
            staged_sources = read_ram_sources(staged, scene)
        self.assertEqual("story_background", screen["id"])
        self.assertIsNone(scene.tilemap)
        self.assertEqual("Gfx_ScrollVRAMTransferParameters", scene.plane_b.descriptor.name)
        self.assertEqual(1, scene.plane_b.chunk_index(16, 16))
        self.assertNotEqual(original, image)
        fast_image, fast_scene = replay_screen_maps(
            baseline_scene,
            screen,
            "jp",
            baseline_sources,
            document,
            self.documents["jp"],
            stage_baseline,
            stage_baseline,
        )
        self.assertEqual(image, fast_image)
        self.assertEqual(scene.plane_b.ram, fast_scene.plane_b.ram)
        reverted, restored_scene = replay_screen_maps(
            scene,
            screen,
            "jp",
            staged_sources,
            self.documents["jp"],
            self.documents["jp"],
            stage_baseline,
            stage_baseline,
        )
        self.assertEqual(original, reverted)
        self.assertEqual(baseline_scene.plane_b.ram, restored_scene.plane_b.ram)

    def test_fast_plane_b_replay_matches_staged_options_for_both_profiles(self) -> None:
        record = next(item for item in self.config["supported"] if item["id"] == "options_background")
        for profile in ("jp", "eu"):
            baseline = build_scene(self.root, profile, record)
            original = render(self.root, profile, record["id"])
            sources = read_ram_sources(self.root, baseline)
            document = copy.deepcopy(self.documents[profile])
            hit = locate_screen_map_cell(baseline, record, profile, document, 16, 16, "plane_b", "chunks")
            item = document["payloads"][hit.cell.payload_index]
            item["values"][hit.cell.value_index] ^= 1
            stage_baseline = export_stage_maps(self.root, profile)
            fast, fast_scene = replay_screen_maps(
                baseline, record, profile, sources, document, self.documents[profile], stage_baseline, stage_baseline
            )
            with tempfile.TemporaryDirectory() as directory:
                staged = Path(directory)
                for name in ("src", "data"):
                    shutil.copytree(self.root / name, staged / name)
                with (
                    mock.patch.object(screen_studio, "stage_tree"),
                    mock.patch.object(screen_studio, "apply_compressed"),
                    mock.patch.object(screen_studio, "apply_palettes"),
                ):
                    full, scene, _record = screen_studio.stage_preview(
                        self.root, profile, staged, document, {}, {}, record["id"], with_scene=True
                    )
            self.assertNotEqual(original, full)
            self.assertEqual(full, fast)
            self.assertEqual(scene.plane_b.ram, fast_scene.plane_b.ram)

    def test_title_fast_replay_preserves_postload_transforms(self) -> None:
        record = next(item for item in self.config["supported"] if item["id"] == "title_background")
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                baseline = build_scene(self.root, profile, record)
                sources = read_ram_sources(self.root, baseline)
                stage = export_stage_maps(self.root, profile)
                image, replayed = replay_screen_maps(
                    baseline,
                    record,
                    profile,
                    sources,
                    self.documents[profile],
                    self.documents[profile],
                    stage,
                    stage,
                )
                self.assertEqual(render(self.root, profile, record["id"]), image)
                self.assertEqual(baseline.tilemap.ram, replayed.tilemap.ram)
                self.assertEqual(baseline.plane_b.ram, replayed.plane_b.ram)
                self.assertEqual(-screen_view_y(record, profile)[0], replayed.plane_b.y_offset)

    def test_fast_replay_composes_saved_level_map_into_story_screen(self) -> None:
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        baseline = build_scene(self.root, "jp", record)
        sources = read_ram_sources(self.root, baseline)
        stage_baseline = export_stage_maps(self.root, "jp")
        stage = copy.deepcopy(stage_baseline)
        item = next(item for item in stage["payloads"] if item["name"] == "SharedMappingData7000")
        item["values"] = [0] * item["value_count"]
        fast, fast_scene = replay_screen_maps(
            baseline, record, "jp", sources, self.documents["jp"], self.documents["jp"], stage, stage_baseline
        )
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            for name in ("src", "data"):
                shutil.copytree(self.root / name, staged / name)
            with (
                mock.patch.object(screen_studio, "stage_tree"),
                mock.patch.object(screen_studio, "apply_compressed"),
                mock.patch.object(screen_studio, "apply_palettes"),
            ):
                full, scene, _record = screen_studio.stage_preview(
                    self.root, "jp", staged, self.documents["jp"], {}, {}, record["id"], stage, with_scene=True
                )
        self.assertEqual(full, fast)
        self.assertEqual(scene.plane_b.ram, fast_scene.plane_b.ram)

    def test_window_map_refresh_uses_cached_ram_without_restaging(self) -> None:
        record = next(item for item in self.config["supported"] if item["id"] == "story_background")
        baseline = build_scene(self.root, "jp", record)
        document = copy.deepcopy(self.documents["jp"])
        item = next(item for item in document["payloads"] if item["name"] == "StoryScreenMappingData6000")
        item["values"][0] = 1
        window = object.__new__(screen_studio.Window)
        window.profile = "jp"
        window.state = Workspace(document)
        window.map_baseline = self.documents["jp"]
        window.stage_baseline = export_stage_maps(self.root, "jp")
        window.stage_maps = window.stage_baseline
        window.preview_scene = baseline
        window.preview_record = record
        window.preview_ram_sources = read_ram_sources(self.root, baseline)
        window.screen_choice = mock.Mock()
        window.screen_choice.get.return_value = record["id"]
        window._validate_map_edit = mock.Mock()
        window._install_preview = mock.Mock()
        window.messagebox = mock.Mock()
        with mock.patch.object(screen_studio, "stage_preview", side_effect=AssertionError("restaged")):
            self.assertTrue(window.refresh_map_preview_fast())
        window._install_preview.assert_called_once()
        self.assertNotEqual(render(self.root, "jp", record["id"]), window._install_preview.call_args.args[0])
        window.messagebox.showerror.assert_not_called()


class CanonicalScreenFixtureTests(unittest.TestCase):
    def test_subset_fixture_matches_both_region_canonical_screen_corpus(self) -> None:
        """Qualification bridge; the small fixture is not the full stage corpus."""
        screen_lists = {
            "Frontend_TitleAssetLoadDescriptors",
            "Options_AssetLoadDescriptors",
            "StoryScreenAssetCommands",
        }
        inline_owners = {
            "FrontendTitleMappingData6000": "src/data/frontend_scene_assets.s",
            "SharedFrontendAndTransitionMappingData7000": "src/data/frontend_scene_assets.s",
            "SharedFrontendAndTransitionMappingDataA": "src/data/frontend_scene_assets.s",
            "SharedMappingData7000": "src/data/stage_object_assets.s",
        }
        payload_names = set(inline_owners) | {
            "FrontendTitleMappingData4000",
            "SharedFrontendAndTransitionMappingDataB",
            "StoryScreenMappingData4000",
            "StoryScreenMappingData6000",
        }
        with tempfile.TemporaryDirectory() as directory:
            subset = Path(directory)
            _screen_fixture(subset)
            self.fixture_bytes = sum(path.stat().st_size for path in subset.rglob("*") if path.is_file())
            original_config = load_config(ROOT)
            self.assertEqual(original_config, load_config(subset))
            self.assertEqual(3, len(original_config["supported"]))
            self.assertEqual(11, len(original_config["unsupported"]))
            for profile in ("jp", "eu"):
                with self.subTest(profile=profile):
                    canonical = export_document(ROOT, profile)
                    copied = export_document(subset, profile)
                    self.assertEqual(payload_names, {item["name"] for item in canonical["payloads"]})
                    self.assertEqual(payload_names, {item["name"] for item in copied["payloads"]})
                    self.assertEqual(
                        set(inline_owners),
                        {item["name"] for item in canonical["payloads"] if item["storage"] == "source"},
                    )
                    self.assertEqual(
                        set(inline_owners), {item["name"] for item in copied["payloads"] if item["storage"] == "source"}
                    )

                    # These are the ONLY permitted model-document differences:
                    # four original inline blocks share one relocated .s owner;
                    # consumers outside the three original screen lists are not
                    # this fixture's stage/transition census. Keep all other
                    # fields (including future/unknown fields) in the comparison.
                    for document in (canonical, copied):
                        for item in document["payloads"]:
                            if item["name"] in inline_owners:
                                expected_owner = (
                                    inline_owners[item["name"]] if document is canonical else "src/screen_fixture.s"
                                )
                                self.assertEqual(expected_owner, item["path"])
                                item["path"] = inline_owners[item["name"]]
                            item["consuming_asset_lists"] = [
                                name for name in item["consuming_asset_lists"] if name in screen_lists
                            ]
                            self.assertTrue(item["consuming_asset_lists"])
                    self.assertEqual(canonical, copied)

                    for record in original_config["supported"]:
                        with self.subTest(screen=record["id"]):
                            self.assertEqual((320, 224), (record["width"], record["height"]))
                            actual_scene = build_scene(ROOT, profile, record)
                            copied_scene = build_scene(subset, profile, record)
                            # Whole dataclasses retain full A/B RAM, descriptors,
                            # written tuples, offsets, VRAM, colours/backdrop and
                            # every other Scene field, without normalization.
                            self.assertEqual(actual_scene, copied_scene)
                            actual_image = render(ROOT, profile, record["id"])
                            copied_image = render(subset, profile, record["id"])
                            self.assertEqual(224, len(actual_image))
                            self.assertTrue(all(len(row) == 320 for row in actual_image))
                            self.assertEqual(actual_image, copied_image)


if __name__ == "__main__":
    unittest.main()
