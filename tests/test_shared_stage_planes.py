"""Shared map provenance is not a reason to discard a bounded VDP plane."""

from __future__ import annotations

from dataclasses import replace
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import level_studio_state as state  # noqa: E402
from authoring import stage_map_model as maps  # noqa: E402
from authoring import stage_renderer as renderer  # noqa: E402
from authoring.stage_tilemap_model import (  # noqa: E402
    Descriptor, PLANE_A_TABLE, PLANE_B_TABLE, Tilemap,
)


class SharedStagePlaneTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.read = renderer.read_once(ROOT)

    def synthetic_read(self):
        primary = Descriptor("primary", 0xFFFF7000, 0xFFFF6000,
                             0xFFFF4000, False, 0x4000)
        secondary = replace(primary, name="secondary", plane_base=0x6000)
        ram = bytearray(0x10000)
        ram[0x4000:0x4020] = b"\x00\x01" * 16
        ram[0x4020:0x4040] = b"\x00\x02" * 16
        ram[0x6001] = 1
        base = Tilemap("fixture", (), bytes(ram), primary,
                       (("fixture", "patterns", 0x4000, 64),
                        ("fixture", "chunks", 0x6000, 64),
                        ("fixture", "coarse", 0x7000, 1024)))
        return {"tilemaps": [base],
                "configurations": [SimpleNamespace(plane_a_mode=4, plane_b_mode=4)],
                "descriptors": {"primary": primary, "secondary": secondary},
                "plane_tables": {PLANE_A_TABLE: ["primary"],
                                 PLANE_B_TABLE: ["secondary"]},
                "not_reproduced": {}}

    def test_shared_map_planes_keep_independent_destinations(self):
        planes = renderer.planes_for(self.synthetic_read(), 0)
        self.assertIsNotNone(planes[0][0])
        self.assertIsNotNone(planes[1][0])
        self.assertEqual((0x4000, 0x6000),
                         tuple(plane.descriptor.plane_base for plane, _ in planes))
        self.assertEqual(("primary", "secondary"),
                         tuple(name for _, name in planes))

    def test_equal_chunks_and_patterns_do_not_hide_a_different_coarse_map(self):
        read = self.synthetic_read()
        read["descriptors"]["secondary"] = replace(
            read["descriptors"]["secondary"], coarse=0xFFFF7400)
        secondary = renderer.planes_for(read, 0)[1][0]
        self.assertIsNotNone(secondary)
        self.assertEqual(0xFFFF7400, secondary.descriptor.coarse)

    def test_shared_sources_still_render_different_camera_samples(self):
        primary, secondary = [plane for plane, _ in
                              renderer.planes_for(self.synthetic_read(), 0)]
        vram = bytearray(0x10000)
        vram[32:64] = b"\x11" * 32
        # Pattern1 references transparent tile2; the same maps sampled at
        # camera A=32 and camera B=0 must reveal B, not the backdrop.
        palette = [(index, index, index) for index in range(64)]
        scene = renderer.Scene(0, primary, secondary, bytes(vram), palette,
                               "fixture", None, (), backdrop=(0, 0, 0),
                               parallax_origin=32, parallax_offset=0)
        self.assertEqual(0, scene.parallax_x(32))
        self.assertEqual([[(1, 1, 1)] * 8] * 8,
                         renderer.draw(scene, x=32, width=8, height=8))
        self.assertEqual([[(0, 0, 0)] * 8] * 8,
                         renderer.draw(replace(scene, plane_b=None),
                                       x=32, width=8, height=8))

    def test_mode_zero_secondary_remains_an_explicit_constant_fill(self):
        read = self.synthetic_read()
        read["configurations"][0].plane_b_mode = 0
        self.assertEqual((None, "constant fill"),
                         renderer.planes_for(read, 0)[1])

    def test_unloaded_secondary_map_stays_excluded(self):
        read = self.synthetic_read()
        read["descriptors"]["secondary"] = replace(
            read["descriptors"]["secondary"], chunks=0xFFFF6800,
            patterns=0xFFFF2000)
        plane, description = renderer.planes_for(read, 0)[1]
        self.assertIsNone(plane)
        self.assertIn("does not load", description)

    def test_declared_procedural_exclusion_is_not_removed(self):
        read = self.synthetic_read()
        read["not_reproduced"][0] = "fixture procedural scroll"
        plane, description = renderer.planes_for(read, 0)[1]
        self.assertIsNone(plane)
        self.assertEqual("not reproduced: fixture procedural scroll", description)

    def test_real_shared_map_slots_keep_source_owned_camera_offsets(self):
        for index, camera_a, camera_b, y_offset in (
                (7, 0xC00, 0x730, 0x900),
                (8, 0x800, 0xC00, 0)):
            with self.subTest(index=index):
                scene = renderer.scene(ROOT, index)
                self.assertIsNotNone(scene.tilemap)
                self.assertIsNotNone(scene.plane_b)
                self.assertEqual((0x4000, 0x6000),
                                 (scene.tilemap.descriptor.plane_base,
                                  scene.plane_b.descriptor.plane_base))
                self.assertEqual(camera_a, scene.configuration.camera_x)
                self.assertEqual(camera_b, scene.parallax_x(camera_a))
                self.assertEqual(y_offset, scene.plane_b.y_offset)
                self.assertEqual(scene.tilemap.ram, scene.plane_b.ram)

    def test_schema_two_payloads_and_shared_source_use_metadata_stay_stable(self):
        primary = maps.map_uses(ROOT, include_plane_b=False)
        current = maps.map_uses(ROOT)
        for source, uses in primary.items():
            if any(use["stage_table_index"] in (7, 8) for use in uses):
                self.assertEqual(uses, current[source], source)
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = maps.export_document(ROOT, profile)
                self.assertEqual((2, 42, 51596, 86808, 42420),
                                 tuple(document[key] for key in (
                                     "schema_version", "payload_count", "value_count",
                                     "decoded_byte_count", "compressed_capacity")))
                maps.validate_document(document, ROOT, profile)

    def test_real_secondary_brush_resolves_existing_shared_payload_in_both_regions(self):
        for profile in ("jp", "eu"):
            document = maps.export_document(ROOT, profile)
            for index, world_x, value_index in ((7, 1072, 1378), (8, 2560, 640)):
                with self.subTest(profile=profile, index=index):
                    studio = state.open_stage(ROOT, index, profile=profile)
                    hit = state.locate_stage_map_cell(
                        studio, document, 0, 0, "patterns",
                        plane_name="plane_b", camera_a_x=0)
                    self.assertEqual("Stage1Phase3AndStage8MappingData4000", hit.source)
                    self.assertEqual((world_x, value_index),
                                     (hit.world_x, hit.value_index))
                    self.assertEqual(hit.source,
                                     document["payloads"][hit.payload_index]["name"])

    def test_constant_fill_primary_does_not_remove_existing_secondary_provenance(self):
        scene = renderer.scene(ROOT, 16)
        self.assertIsNone(scene.tilemap)
        self.assertIsNotNone(scene.plane_b)
        self.assertEqual("Gfx_ScrollVRAMTransferParameters", scene.plane_b.descriptor.name)
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = maps.export_document(ROOT, profile)
                record = next(item for item in document["payloads"]
                              if item["name"] == "Stage2Phase1MappingData4000")
                uses = [use for use in record["uses"]
                        if use.get("plane") == "plane_b" and use["stage_table_index"] == 16]
                self.assertEqual(1, len(uses))
                self.assertEqual("Gfx_ScrollVRAMTransferParameters", uses[0]["descriptor"])


if __name__ == "__main__":
    unittest.main()
