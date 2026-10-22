from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.level_studio_model import (  # noqa: E402
    CONFIG_FIELDS,
    PLAYER_POSITION_BIAS,
    read_configuration_records,
    stage_configurations,
    stage_initializers,
)
from authoring.stage_renderer import (  # noqa: E402
    COPY_TO_VRAM,
    DECODE_TO_VRAM,
    DECOMPRESS_TO_VRAM,
    HFLIP,
    PALETTE_SHIFT,
    PARALLAX_SHIFT,
    PRIORITY,
    Scene,
    TILE_MASK,
    VFLIP,
    build_vram,
    compose,
    draw,
    not_reproduced,
    scene,
)
from authoring import map_reference_guard  # noqa: E402
from authoring.stage_tilemap_model import (  # noqa: E402
    PLANE_A_TABLE,
    PLANE_B_TABLE,
    plane_descriptor,
    read_plane_tables,
)
from authoring.stage_tilemap_model import AssetCommand  # noqa: E402
from authoring.tile_graphics import GRAPHICS_CONFIG  # noqa: E402


class VramTests(unittest.TestCase):
    def test_a_raw_transfer_lands_at_its_destination(self) -> None:
        lists = {"fixture": (AssetCommand(COPY_TO_VRAM, "art", 0x0100),)}
        vram, missing = build_vram(ROOT, ["fixture"], lists, {"art": b"\x11\x22\x33"})
        self.assertEqual(b"\x11\x22\x33", vram[0x100:0x103])
        self.assertEqual((), missing)

    def test_the_bit_codec_lands_decoded_tiles_at_its_destination(self) -> None:
        from authoring.tile_codec import compress

        pixels = bytes(range(16)) * 2
        lists = {"fixture": (AssetCommand(DECODE_TO_VRAM, "art", 0x0100),)}
        vram, missing = build_vram(ROOT, ["fixture"], lists, {"art": compress(pixels)})
        self.assertEqual(pixels, vram[0x100:0x120])
        self.assertEqual((), missing)

    def test_the_command_numbers_are_the_handlers_they_name(self) -> None:
        from authoring.stage_tilemap_model import LOAD_HANDLERS

        self.assertEqual("Gfx_LoadDataToVRAM", LOAD_HANDLERS[COPY_TO_VRAM])
        self.assertEqual("Gfx_LoadCompressedGfx", LOAD_HANDLERS[DECODE_TO_VRAM])
        self.assertEqual("LoadCompressedToVRAM", LOAD_HANDLERS[DECOMPRESS_TO_VRAM])


class NameWordTests(unittest.TestCase):
    def test_a_name_word_is_read_as_the_vdp_reads_it(self) -> None:
        """Absolute, unlike a sprite piece: nothing exclusive-ors these."""
        word = PRIORITY | (2 << PALETTE_SHIFT) | VFLIP | HFLIP | 0x123
        self.assertEqual(0x123, word & TILE_MASK)
        self.assertTrue(word & HFLIP)
        self.assertTrue(word & VFLIP)
        self.assertEqual(2, (word >> PALETTE_SHIFT) & 3)
        self.assertTrue(word & PRIORITY)


class ConfigurationRecordTests(unittest.TestCase):
    def test_every_record_reads_as_the_thirty_bytes_the_loader_reads(self) -> None:
        records = read_configuration_records(ROOT)
        self.assertEqual(30, len(records))
        for record in records.values():
            self.assertEqual(len(CONFIG_FIELDS), len(record.fields))

    def test_a_record_names_its_spawn_list_and_its_palette(self) -> None:
        record = read_configuration_records(ROOT)["Stage1ConfigRecord"]
        self.assertEqual("Stage1_ObjectSpawnList", record.spawn_list)
        self.assertEqual("EarlyStagePaletteOffsetList", record.palette_list)
        self.assertEqual((0x40 + PLAYER_POSITION_BIAS, 0xB0 + PLAYER_POSITION_BIAS), record.player_start)

    def test_a_spawn_cursor_that_is_a_sentinel_stays_a_number(self) -> None:
        # Stage20ConfigRecord has dc.l $80000000 where the others have a label.
        record = read_configuration_records(ROOT)["Stage20ConfigRecord"]
        self.assertEqual(0x80000000, record.spawn_list)

    def test_every_stage_table_index_reaches_a_record(self) -> None:
        initializers = stage_initializers(ROOT)
        configurations = stage_configurations(ROOT)
        self.assertEqual(len(initializers), len(configurations))
        self.assertTrue(initializers)
        for index, configuration in enumerate(configurations):
            self.assertIsNotNone(configuration, index)
            self.assertTrue(configuration.palette_list, index)


class SceneTests(unittest.TestCase):
    """Draw the real stages, not a fixture that agrees with the code."""

    def test_a_stage_takes_the_palette_its_record_names(self) -> None:
        built = scene(ROOT, 0)
        self.assertEqual("EarlyStagePaletteOffsetList", built.palette_name)
        self.assertEqual(64, len(built.palette))

    def test_an_index_outside_the_table_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            scene(ROOT, 999)

    def test_the_first_stage_draws_something_other_than_one_colour(self) -> None:
        image = draw(scene(ROOT, 0), 0, 0, 256, 224)
        self.assertEqual(224, len(image))
        self.assertEqual(256, len(image[0]))
        self.assertGreater(len({pixel for row in image for pixel in row}), 8)

    def test_the_stages_that_draw_and_the_ones_that_do_not_are_declared(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        declared = config["stage_rendering"]
        blank = []
        needs_codec = set()
        for index in range(len(stage_configurations(ROOT))):
            built = scene(ROOT, index)
            needs_codec |= set(built.missing_codecs)
            if len({pixel for row in draw(built, 0, 0, 256, 224) for pixel in row}) < 4:
                blank.append(index)
        self.assertEqual(declared["indices_that_draw_nothing"], blank)
        self.assertEqual(declared["payloads_needing_the_bit_codec"], sorted(needs_codec))
        self.assertTrue(declared["why"].strip())


class TwoPlaneTests(unittest.TestCase):
    def test_parallax_changes_camera_not_horizontal_pixel_scale(self) -> None:
        class AlternatingPlane:
            def defined(self, _x, _y):
                return True

            def name_word(self, x, _y):
                return 1 + (x // 8) % 2

        built = Scene(
            index=0,
            tilemap=None,
            plane_b=AlternatingPlane(),
            vram=bytes(32) + bytes([0x11]) * 32 + bytes([0x22]) * 32,
            palette=[(value, value, value) for value in range(64)],
            palette_name="fixture",
            configuration=None,
            missing_codecs=(),
        )
        self.assertEqual(
            [(1, 1, 1)] * 8 + [(2, 2, 2)] * 8,
            draw(built, x=0, y=0, width=16, height=1)[0],
        )
        self.assertEqual(
            [(1, 1, 1)] * 7 + [(2, 2, 2)],
            draw(built, x=4, y=0, width=8, height=1)[0],
        )

    def test_unaligned_primary_camera_samples_partial_tiles(self) -> None:
        class AlternatingPlane:
            def defined(self, _x, _y):
                return True

            def name_word(self, x, _y):
                return 1 + (x // 8) % 2

        built = Scene(
            index=0,
            tilemap=AlternatingPlane(),
            plane_b=None,
            vram=bytes(32) + bytes([0x11]) * 32 + bytes([0x22]) * 32,
            palette=[(value, value, value) for value in range(64)],
            palette_name="fixture",
            configuration=None,
            missing_codecs=(),
        )
        self.assertEqual(
            [(1, 1, 1)] * 5 + [(2, 2, 2)] * 5,
            draw(built, x=3, y=0, width=10, height=1)[0],
        )

    def test_early_stage_back_plane_wraps_at_the_512_pixel_vram_seam(self) -> None:
        class RingPlane:
            def defined(self, x, _y):
                return 0 <= x < 512

            def name_word(self, x, _y):
                return 1 if x < 256 else 2

        built = Scene(
            index=1,
            tilemap=None,
            plane_b=RingPlane(),
            vram=bytes(32) + bytes([0x11]) * 32 + bytes([0x22]) * 32,
            palette=[(value, value, value) for value in range(64)],
            palette_name="fixture",
            configuration=None,
            missing_codecs=(),
            absolute_quarter_scroll=True,
            plane_b_wrap_pixels=512,
        )
        self.assertEqual(511, built.parallax_x(2044))
        self.assertEqual(0, built.plane_b_source_x(512))
        self.assertEqual(
            [(2, 2, 2)] + [(1, 1, 1)] * 3,
            draw(built, x=2044, y=0, width=4, height=1)[0],
        )

    def test_stage_two_uses_absolute_quarter_scroll_without_losing_config(self) -> None:
        built = scene(ROOT, 1)
        self.assertEqual(0x700, built.parallax_origin)
        self.assertTrue(built.absolute_quarter_scroll)
        self.assertEqual(0x1C0, built.parallax_x(0x700))
        self.assertEqual(512, built.plane_b_wrap_pixels)
        self.assertEqual(0, built.plane_b_source_x(512))

    def test_stage_three_initial_scene_keeps_the_early_back_plane_ring(self) -> None:
        built = scene(ROOT, 2)
        self.assertEqual(0xBC0, built.parallax_origin)
        self.assertTrue(built.absolute_quarter_scroll)
        self.assertEqual(0x2F0, built.parallax_x(0xBC0))
        self.assertEqual(512, built.plane_b_wrap_pixels)

    def test_visible_map_guard_checks_wrapped_secondary_cells(self) -> None:
        built = scene(ROOT, 1)
        record = {
            "id": "stage2_ring",
            "camera_a_x": 0x700,
            "camera_a_y": {"jp": 96},
            "width": 80,
            "height": 8,
        }
        with mock.patch.object(map_reference_guard, "reference_issue", return_value=None) as checked:
            self.assertEqual([], map_reference_guard.visible_reference_errors(built, built, record, "jp"))
        back_x = [call.args[1] for call in checked.call_args_list if call.args[0] is built.plane_b]
        self.assertIn(0, back_x)
        self.assertNotIn(512, back_x)

    def test_visible_map_guard_explicit_lookup_preserves_default_level_camera(self):
        built = scene(ROOT, 1)
        record = {"id": "stage2_ring", "camera_a_x": 0x700, "camera_a_y": {"jp": 96}, "width": 16, "height": 8}
        for override, expected in ((None, 96), (16, 16), (-16, -16)):
            with (
                self.subTest(viewport_y=override),
                mock.patch.object(map_reference_guard, "reference_issue", return_value=None) as checked,
            ):
                self.assertEqual(
                    [], map_reference_guard.visible_reference_errors(built, built, record, "jp", viewport_y=override)
                )
                self.assertTrue(checked.call_args_list)
                self.assertEqual({expected}, {call.args[2] for call in checked.call_args_list})
        self.assertEqual(96, record["camera_a_y"]["jp"])
        for invalid in (True, "16", 16.0):
            with self.subTest(invalid=invalid), self.assertRaisesRegex(ValueError, "integer"):
                map_reference_guard.visible_reference_errors(built, built, record, "jp", viewport_y=invalid)

    def test_an_entry_mode_is_a_biased_offset_into_its_table(self) -> None:
        """-4(a0,d0.w), so mode 4 is the first entry and mode 8 the second."""
        table = ["First", "Second"]
        self.assertEqual(("First", 0), plane_descriptor(4, table))
        self.assertEqual(("Second", 0), plane_descriptor(8, table))
        self.assertEqual((None, 0), plane_descriptor(0, table))
        with self.assertRaises(ValueError):
            plane_descriptor(12, table)

    def test_bit_fifteen_reads_the_maps_further_down_rather_than_mirroring(self) -> None:
        # Tilemap_MirrorOffsetRowAndQueueScrollingRow does subi.w #$1000,d1.
        self.assertEqual(("First", 0x1000), plane_descriptor(0x8004, ["First"]))

    def test_plane_descriptor_rejects_unaligned_and_secondary_signed_offsets(self) -> None:
        for mode in (False, 4.0, -4, 0x10000, 1, 2, 5, 6, 9, 0x8000, 0x8005):
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                plane_descriptor(mode, ["First", "Second"])
        for mode in (0x8004, 0x8008):
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                plane_descriptor(mode, ["First", "Second"], offset_variant=False)
        self.assertEqual(("Second", 0), plane_descriptor(8, ["First", "Second"], offset_variant=False))

    def test_renderer_does_not_mask_a_secondary_mode_when_validator_is_bypassed(self) -> None:
        record = read_configuration_records(ROOT)["Stage1ConfigRecord"]
        record.fields["plane_b_mode"] = 0x8004
        with self.assertRaisesRegex(ValueError, "plane entry mode \\$8004"):
            scene(ROOT, 0, configuration_override=record)

    def test_the_tables_name_the_descriptors_the_source_names(self) -> None:
        tables = read_plane_tables(ROOT)
        self.assertEqual(
            ["Gfx_TitleAndZLeoVRAMTransferParameters", "Gfx_DefaultVRAMTransferParameters"], tables[PLANE_A_TABLE]
        )
        self.assertEqual(
            ["Gfx_FrontendAlternateVRAMTransferParameters", "Gfx_ScrollVRAMTransferParameters"], tables[PLANE_B_TABLE]
        )

    def test_every_stage_resolves_both_of_its_planes(self) -> None:
        for index in range(len(stage_configurations(ROOT))):
            built = scene(ROOT, index)
            self.assertEqual(2, len(built.planes), index)
            for name in built.planes:
                self.assertTrue(name, index)

    def test_the_backdrop_is_register_seven_not_the_first_colour(self) -> None:
        built = scene(ROOT, 0)
        # Gfx_GameVDPRegisterValues sets register 7 to $10: line one, colour zero.
        self.assertEqual(built.palette[16], built.backdrop)

    def test_plane_b_is_drawn_at_a_quarter_of_plane_a(self) -> None:
        built = scene(ROOT, 0)
        self.assertEqual(2, PARALLAX_SHIFT)
        self.assertEqual(0, built.parallax_x(0))
        self.assertEqual(64, built.parallax_x(256))
        self.assertTrue(built.absolute_quarter_scroll)
        self.assertEqual(512, built.plane_b_wrap_pixels)

    def test_the_planes_are_layered_the_way_the_vdp_layers_them(self) -> None:
        white, black = (255, 255, 255), (0, 0, 0)
        backdrop = (9, 9, 9)
        low_front = ([[white] * 8], [[1] * 8], False)
        high_front = ([[white] * 8], [[1] * 8], True)
        clear_front = ([[white] * 8], [[0] * 8], False)
        high_back = ([[black] * 8], [[2] * 8], True)
        low_back = ([[black] * 8], [[2] * 8], False)

        self.assertEqual([white] * 8, compose(low_front, low_back, 0, 8, backdrop))
        self.assertEqual([black] * 8, compose(low_front, high_back, 0, 8, backdrop))
        self.assertEqual([white] * 8, compose(high_front, high_back, 0, 8, backdrop))
        self.assertEqual([black] * 8, compose(clear_front, low_back, 0, 8, backdrop))
        self.assertEqual([backdrop] * 8, compose(clear_front, None, 0, 8, backdrop))
        self.assertEqual([backdrop] * 8, compose(None, None, 0, 8, backdrop))

    def test_what_cannot_be_replayed_is_declared_with_a_reason(self) -> None:
        declared = not_reproduced(ROOT)
        self.assertEqual({17, 18}, set(declared))
        for why in declared.values():
            self.assertTrue(why.strip())
        for index in declared:
            self.assertIn("not reproduced", scene(ROOT, index).planes[1])


if __name__ == "__main__":
    unittest.main()
