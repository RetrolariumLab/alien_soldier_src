from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.animation_studio_model import export_document as animations  # noqa: E402
from authoring.level_studio_model import export_document as levels  # noqa: E402
from authoring.mapping_studio_model import export_document as mappings  # noqa: E402
from authoring.object_gallery_model import (  # noqa: E402
    catalogue,
    render_preview,
    stage_preview,
    survey,
)
from authoring import stage_renderer  # noqa: E402


class GalleryRefreshTests(unittest.TestCase):
    def test_repeated_staging_reads_new_palette_and_required_graphics_policy(self):
        """Exercise the real stage-tree/cache boundary with a tiny source tree."""
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            (project / "src").mkdir()
            (project / "src/main.s").write_text("; gallery fixture\n", encoding="utf-8")
            (project / "data").mkdir()
            config = project / "config/authoring/graphics.json"
            config.parent.mkdir(parents=True)
            config.write_text(json.dumps({"stage_rendering": {"two_planes": {
                "planes_not_reproduced": [{"index": 17, "why": "runtime scroll"}]
            }}}), encoding="utf-8")
            destination = project / "build/content/gallery/jp/tree"
            other_root = project / "other"
            other_cache = object()
            stage_renderer._READ[str(other_root.resolve())] = other_cache
            self.addCleanup(stage_renderer.forget, other_root)
            self.addCleanup(stage_renderer.forget, destination)

            def apply_palette(document, root, _profile):
                (root / "src/palette.json").write_text(
                    json.dumps(document), encoding="utf-8")

            def read_palette(root):
                return [json.loads((root / "src/palette.json").read_text(
                    encoding="utf-8"))]

            def render(root, _profile, _record):
                snapshot = stage_renderer.read_once(root)
                return (snapshot["palettes"]["edited"]["rgb"],
                        snapshot["not_reproduced"])

            with (
                mock.patch("authoring.level_studio_model.apply_document"),
                mock.patch("authoring.graphics_studio_model.apply_document"),
                mock.patch("authoring.compressed_graphics_model.apply_document"),
                mock.patch("authoring.palette_studio_model.apply_document",
                           side_effect=apply_palette),
                mock.patch("authoring.mapping_studio_model.apply_document"),
                mock.patch("authoring.animation_studio_model.apply_document"),
                mock.patch("authoring.object_gallery_model.render_preview",
                           side_effect=render),
                mock.patch.multiple(
                    stage_renderer,
                    labelled_blocks=mock.Mock(return_value=({}, {})),
                    read_asset_lists=mock.Mock(return_value={}),
                    stage_loaders=mock.Mock(return_value=[]),
                    stage_tilemaps=mock.Mock(return_value=[]),
                    stage_configurations=mock.Mock(return_value=[]),
                    named_sets=mock.Mock(side_effect=read_palette),
                    read_descriptors=mock.Mock(return_value={}),
                    read_plane_tables=mock.Mock(return_value={}),
                    read_visual_loaders=mock.Mock(return_value=[]),
                    source_index=mock.Mock(return_value=({}, {})),
                ),
            ):
                for rgb in ([[16, 32, 48]], [[64, 80, 96]]):
                    with self.subTest(rgb=rgb):
                        palette = {"name": "edited", "rgb": rgb}
                        result = stage_preview(
                            project, "jp", destination,
                            {}, {}, {}, palette, {}, {}, {})
                        self.assertEqual((rgb, {17: "runtime scroll"}), result)
                        self.assertEqual(config.read_bytes(),
                                         (destination / "config/authoring/graphics.json")
                                         .read_bytes())
                        self.assertIs(other_cache,
                                      stage_renderer._READ[str(other_root.resolve())])


class ObjectGalleryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = catalogue(
            levels(ROOT, "jp"), mappings(ROOT, "jp"), animations(ROOT, "jp")
        )

    def test_every_fixed_placement_has_one_stable_gallery_record(self) -> None:
        self.assertEqual(
            {
                "placements": 314,
                "previewable_candidates": 314,
                "without_stage": 0,
                "without_handler": 0,
            },
            survey(self.records),
        )
        self.assertEqual(314, len({record["id"] for record in self.records}))
        self.assertTrue(all(record["stage_indices"] for record in self.records))

    def test_preview_decodes_only_the_selected_stage_and_object(self) -> None:
        preview = render_preview(ROOT, "jp", self.records[0])
        self.assertEqual("Enemy_BehaviorController", preview["handler"])
        self.assertEqual("Enemy_BehaviorWaitSpriteAnimation", preview["mapping_symbol"])
        self.assertEqual("the stage default", preview["attribute_evidence"])
        self.assertTrue(preview["pixels"] and preview["pixels"][0])

    def test_weapon_selection_preview_uses_stage_entry_carried_art(self) -> None:
        for profile, stage in (("jp", 0), ("eu", 9)):
            record = next(item for item in self.records
                          if item["sample_stage"] == stage
                          and item["handler"] == "UI_WeaponSelectionObject")
            preview = render_preview(ROOT, profile, record)
            self.assertEqual("WeaponSelect_IdleSpriteMapping",
                             preview["mapping_symbol"])
            self.assertEqual("initial stage configuration priority; runtime can change",
                             preview["attribute_evidence"])
            self.assertEqual("", preview["reason"])
            self.assertEqual(552, sum(pixel is not None
                                      for row in preview["pixels"] for pixel in row))

    def test_family_previews_use_their_own_stage_loaded_tile_bases(self) -> None:
        for profile in ("jp", "eu"):
            for stage, handler, evidence in (
                    (1, "Enemy_CirclingController", "stage CirclingEnemyTileAttr"),
                    (4, "Enemy_BirdController", "stage BirdEnemyTileAttr")):
                record = next(item for item in self.records
                              if item["sample_stage"] == stage
                              and item["handler"] == handler)
                preview = render_preview(ROOT, profile, record)
                self.assertEqual(evidence, preview["attribute_evidence"])
                self.assertEqual("", preview["reason"])
                self.assertTrue(any(pixel is not None
                                    for row in preview["pixels"] for pixel in row))

    def test_proximity_previews_follow_both_spawn_parameter_variants(self) -> None:
        document = levels(ROOT, "jp")
        spawn = next(item for item in document["spawn_lists"]
                     if item["name"] == "Stage4_ObjectSpawnList")
        choices = {}
        for index, entry in enumerate(spawn["entries"]):
            record = next(item for item in self.records
                          if item["spawn_list"] == spawn["name"]
                          and item["placement_index"] == index)
            if record["handler"] == "Object_UpdateProximityPickupEmitterType48":
                choices.setdefault(entry["parameter"], record)
        self.assertEqual({0, 2}, set(choices))
        for profile in ("jp", "eu"):
            variants = {}
            for parameter, attribute in ((0, 0x0C80), (2, 0x1C80)):
                preview = render_preview(ROOT, profile, choices[parameter])
                self.assertEqual(attribute, preview["attribute"])
                self.assertEqual("spawn parameter bit 1",
                                 preview["attribute_evidence"])
                self.assertTrue(any(pixel is not None
                                    for row in preview["pixels"] for pixel in row))
                variants[parameter] = preview["pixels"]
            self.assertNotEqual(variants[0], variants[2])

    def test_indexed_gallery_previews_follow_every_selector_in_both_profiles(self) -> None:
        expected = {8: "IndexedObjectSpriteAnimation01",
                    0x8000: "IndexedObjectSpriteAnimation00",
                    0x8008: "IndexedObjectSpriteAnimation01",
                    24: "IndexedObjectSpriteAnimation03",
                    16: "IndexedObjectSpriteAnimation02",
                    0x8020: "IndexedObjectSpriteAnimation04"}
        source = levels(ROOT, "jp")
        parameters = {
            (spawn["name"], index): entry["parameter"]
            for spawn in source["spawn_lists"]
            for index, entry in enumerate(spawn["entries"])
        }
        records = [item for item in self.records if item["handler"] ==
                   "Object_InitIndexedSpriteGraphics"]
        self.assertEqual(7, len(records))
        for profile in ("jp", "eu"):
            for record in records:
                parameter = parameters[(record["spawn_list"],
                                        record["placement_index"])]
                preview = render_preview(ROOT, profile, record)
                self.assertEqual(expected[parameter], preview["mapping_symbol"])
                self.assertEqual(0x02DF, preview["attribute"])
                self.assertEqual("indexed sprite table", preview["attribute_evidence"])
                self.assertTrue(any(pixel is not None
                                    for row in preview["pixels"] for pixel in row))

    def test_three_more_family_routes_render_in_both_profile_galleries(self) -> None:
        cases = (
            (0, "Enemy_HomingAttackController", "stage EnemyProjectileTileAttr"),
            (2, "Enemy_PhasePatternController", "stage PhaseEnemyTileAttr"),
            (9, "Enemy_Stage10WaspController", "stage Stage10WaspTileAttr"),
        )
        for profile in ("jp", "eu"):
            for stage, handler, evidence in cases:
                record = next(item for item in self.records
                              if item["sample_stage"] == stage
                              and item["handler"] == handler)
                preview = render_preview(ROOT, profile, record)
                self.assertEqual(evidence, preview["attribute_evidence"])
                self.assertTrue(any(pixel is not None
                                    for row in preview["pixels"] for pixel in row))

    def test_stage_12_floater_gallery_uses_its_constructed_attribute(self) -> None:
        record = next(item for item in self.records
                      if item["sample_stage"] == 11
                      and item["handler"] == "Enemy_Stage12FloaterController")
        for profile in ("jp", "eu"):
            preview = render_preview(ROOT, profile, record)
            self.assertEqual(0x8000, preview["attribute"])
            self.assertEqual("stage 12 floater initializer",
                             preview["attribute_evidence"])
            self.assertEqual("", preview["reason"])
            self.assertTrue(any(pixel is not None
                                for row in preview["pixels"] for pixel in row))

    def test_stage_12_teddy_gallery_uses_its_state_zero_sprite(self) -> None:
        record = next(item for item in self.records
                      if item["sample_stage"] == 11
                      and item["handler"] == "Stage12_TeddyBearMain")
        for profile in ("jp", "eu"):
            preview = render_preview(ROOT, profile, record)
            self.assertEqual("SharedTeddyHazardLoopAnimation",
                             preview["mapping_symbol"])
            self.assertEqual(0x8000, preview["attribute"])
            self.assertEqual("immediate", preview["attribute_evidence"])
            self.assertEqual("", preview["reason"])
            self.assertTrue(any(pixel is not None
                                for row in preview["pixels"] for pixel in row))

    def test_platform_gallery_selects_its_stage_guarded_mapping(self) -> None:
        record = next(item for item in self.records
                      if item["sample_stage"] == 9
                      and item["handler"] == "Stage18_MovingPlatform")
        for profile in ("jp", "eu"):
            preview = render_preview(ROOT, profile, record)
            self.assertEqual("Stage18_MovingPlatformSpriteMapping",
                             preview["mapping_symbol"])
            self.assertEqual(0x4000, preview["attribute"])
            self.assertEqual("stage-index platform branch",
                             preview["attribute_evidence"])
            self.assertTrue(any(pixel is not None
                                for row in preview["pixels"] for pixel in row))

    def test_staged_preview_applies_every_workspace_document_before_rendering(self):
        documents = [{"number": index} for index in range(6)]
        record = self.records[0]
        result = {"pixels": [[(0, 0, 0)]]}
        with tempfile.TemporaryDirectory(dir=ROOT / "build") as directory:
            destination = Path(directory) / "tree"
            with (
                mock.patch("authoring.content_workspace.stage_tree") as stage,
                mock.patch("authoring.level_studio_model.apply_document") as level,
                mock.patch("authoring.graphics_studio_model.apply_document") as tile,
                mock.patch(
                    "authoring.compressed_graphics_model.apply_document"
                ) as compressed,
                mock.patch("authoring.palette_studio_model.apply_document") as palette,
                mock.patch("authoring.mapping_studio_model.apply_document") as mapping,
                mock.patch("authoring.animation_studio_model.apply_document") as animation,
                mock.patch(
                    "authoring.object_gallery_model.render_preview",
                    return_value=result,
                ) as render,
            ):
                self.assertIs(
                    result,
                    stage_preview(
                        ROOT, "jp", destination, *documents, record
                    ),
                )
        stage.assert_called_once_with(ROOT, destination)
        for applied, document in zip(
            (level, tile, compressed, palette, mapping), documents
        ):
            applied.assert_called_once_with(document, destination, "jp")
        animation.assert_called_once_with(documents[-1], destination, "jp", validation_root=ROOT)
        render.assert_called_once_with(destination, "jp", record)


if __name__ == "__main__":
    unittest.main()
