from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.level_studio_state import (  # noqa: E402
    object_attribute, open_stage, overlay_placements, placement_sprite, resting_mapping,
    sprite_library)
from authoring.object_sprite_model import (  # noqa: E402
    Frame, OBJECT_ATTRIBUTE_MASK, OBJECT_TILE_MASK, TILE_ATTRIBUTE_BIT, TILE_SHIFT,
    WEAPON_SELECTION_ART_START, WEAPON_SELECTION_HANDLER,
    compose_static, expand_tile_commands, read_animation_scripts, read_pointer_table,
    read_offset_table, read_visual_loaders, resolve_mapping, resting_symbol,
    resting_attribute, routine, selected_indexed_sprite_entry, source_index,
    stage18_platform_variant, tile_attribute_slots, weapon_selection_carried_art)
from authoring.graphics_inventory import synchronized  # noqa: E402
from authoring.stage_renderer import read_once, scene  # noqa: E402
from authoring.sprite_mapping_model import SpriteMapping, SpritePiece  # noqa: E402
from authoring.stage_tilemap_model import (  # noqa: E402
    AssetCommand, SHARED_LOADER, decompress, labelled_blocks, loader_lists)
from authoring.tile_graphics import GRAPHICS_CONFIG  # noqa: E402


LIBRARY = None


def library():
    global LIBRARY
    if LIBRARY is None:
        LIBRARY = sprite_library(ROOT)
    return LIBRARY


class AnimationFormatTests(unittest.TestCase):
    def test_a_duration_of_zero_makes_the_word_a_jump(self) -> None:
        """Anim_ResolveTimedMappingFrame: bne on 2(a4), else adda.w (a4),a4."""
        self.assertFalse(Frame("Mapping", 3).is_jump)
        self.assertTrue(Frame("Mapping", 0).is_jump)

    def test_every_script_in_the_tree_reads_as_whole_entries(self) -> None:
        scripts = read_animation_scripts(ROOT)
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        declared = config["object_sprites"]
        self.assertEqual(declared["animation_scripts"], len(scripts))
        self.assertEqual(declared["animation_frames"],
                         sum(len(frames) for frames in scripts.values()))
        self.assertEqual(4, declared["entry_bytes"])
        for name, frames in scripts.items():
            self.assertTrue(frames, name)
            for frame in frames:
                self.assertTrue(frame.mapping, name)

    def test_a_script_resolves_to_its_first_real_frame(self) -> None:
        scripts = read_animation_scripts(ROOT)
        mappings = library()["mappings"]
        first = scripts["SharedCombatSpriteAnimation00"][0]
        self.assertEqual("SharedCombatSpriteFrame06", first.mapping)
        self.assertIs(mappings[first.mapping],
                      resolve_mapping("SharedCombatSpriteAnimation00", scripts, mappings))

    def test_a_symbol_that_is_already_a_mapping_is_used_as_one(self) -> None:
        scripts = read_animation_scripts(ROOT)
        mappings = library()["mappings"]
        self.assertIs(mappings["WeaponSelect_IdleSpriteMapping"],
                      resolve_mapping("WeaponSelect_IdleSpriteMapping", scripts, mappings))
        self.assertIsNone(resolve_mapping("NotAThing", scripts, mappings))


class HandlerTests(unittest.TestCase):
    def test_a_state_table_beats_an_unconditional_write(self) -> None:
        """Enemy_BehaviorController reaches its defeat frame first; state 0 wins."""
        lines, index = source_index(ROOT)
        self.assertEqual("Enemy_BehaviorWaitSpriteAnimation",
                         resting_symbol(lines, index, "Enemy_BehaviorController"))
        self.assertEqual("Enemy_BehaviorWaitSpriteAnimation",
                         read_pointer_table(lines, index,
                                            "Enemy_BehaviorSpriteAnimationPointers")[0])

    def test_a_handler_with_nothing_reachable_says_so(self) -> None:
        lines, index = source_index(ROOT)
        self.assertEqual("", resting_symbol(lines, index, "Stage10_BeetleWaveController"))

    def test_platform_variant_requires_the_source_stage_branch(self) -> None:
        lines, index = source_index(ROOT)
        self.assertEqual(("Stage18_MovingPlatformSpriteMapping", 0x4000),
                         stage18_platform_variant(lines, index, 9))
        self.assertEqual(("Stage18MovingPlatformSpriteMapping", 0x4470),
                         stage18_platform_variant(lines, index, 24))
        self.assertIsNone(stage18_platform_variant(lines, index, None))
        path, at = index["Stage18_MovingPlatform"]
        changed = dict(lines)
        changed[path] = list(lines[path])
        for row in range(at, at + 20):
            if "cmpi.w  #$18,(StageTableIndex).w" in changed[path][row]:
                changed[path][row] = changed[path][row].replace("#$18", "#$17")
                break
        else:
            self.fail("platform stage threshold is missing")
        self.assertIsNone(stage18_platform_variant(changed, index, 9))

    def test_family_state_zero_tables_point_to_initializers(self) -> None:
        lines, index = source_index(ROOT)
        spawner = "\n".join(routine(lines, index, "Sys_SpawnObject"))
        clear = "\n".join(routine(lines, index, "Sys_Clear96ByteBlock"))
        self.assertIn("bsr.w   Sys_ClearObjectSlot", spawner)
        self.assertIn("moveq   #0,d0", clear)
        self.assertEqual(24, clear.count("move.l  d0,(a0)+"))
        self.assertEqual("Enemy_BirdInit", read_offset_table(
            lines, index, "Enemy_BirdStateOffsets")[0])
        self.assertEqual("Enemy_CirclingApproachState", read_offset_table(
            lines, index, "Enemy_CirclingStateOffsets")[0])
        self.assertEqual("Enemy_HomingAttackInit", read_offset_table(
            lines, index, "Enemy_HomingAttackStateOffsets")[0])
        self.assertEqual("Enemy_PhasePatternInit", read_offset_table(
            lines, index, "Enemy_PhasePatternStateOffsets")[0])
        self.assertEqual("Enemy_Stage10WaspInitState", read_offset_table(
            lines, index, "Enemy_Stage10WaspStateOffsets")[0])
        self.assertEqual("Enemy_Stage12FloaterInitState", read_offset_table(
            lines, index, "Enemy_Stage12FloaterStateOffsets")[0])


class TileAttributeTests(unittest.TestCase):
    def test_indexed_sprite_table_selects_animation_and_attribute_together(self) -> None:
        entries = library()["indexed_sprites"]
        self.assertEqual(5, len(entries))
        self.assertEqual(("IndexedObjectSpriteAnimation03", 0x02DF),
                         selected_indexed_sprite_entry(entries, 24))
        self.assertEqual(("IndexedObjectSpriteAnimation04", 0x02DF),
                         selected_indexed_sprite_entry(entries, 0x8020))
        for invalid in (None, -1, 5, 40, 0x8040):
            self.assertIsNone(selected_indexed_sprite_entry(entries, invalid))
        stage = scene(ROOT, 5)
        self.assertEqual(("", None), resting_mapping(
            library(), "Object_InitIndexedSpriteGraphics", None))
        self.assertEqual((None, ""), object_attribute(
            library(), "Object_InitIndexedSpriteGraphics",
            stage.object_attribute, parameter=5))

    def test_proximity_object_attribute_uses_spawn_parameter_bit_one(self) -> None:
        built = scene(ROOT, 3)
        handler = "Object_UpdateProximityPickupEmitterType48"
        kwargs = {
            "stage_attributes": built.object_attributes,
            "priority": built.configuration.sprite_priority,
        }
        self.assertEqual((0x0C80, "spawn parameter bit 1"), object_attribute(
            library(), handler, built.object_attribute, parameter=0, **kwargs))
        self.assertEqual((0x1C80, "spawn parameter bit 1"), object_attribute(
            library(), handler, built.object_attribute, parameter=2, **kwargs))
        self.assertEqual((None, ""), object_attribute(
            library(), handler, built.object_attribute, **kwargs))

    def test_stage_12_floater_attribute_is_proved_by_its_initializer(self) -> None:
        stage = scene(ROOT, 11)
        handler = "Enemy_Stage12FloaterController"
        self.assertEqual((0x8000, "stage 12 floater initializer"), object_attribute(
            library(), handler, stage.object_attribute,
            stage_attributes=stage.object_attributes,
            priority=stage.configuration.sprite_priority))
        self.assertEqual("SharedFloaterDebrisProjectileAlternating5And4Animation",
                         resting_mapping(library(), handler)[0])
        lines, index = source_index(ROOT)
        path, at = index["Enemy_InitStage12FloatingSprite"]
        changed = dict(lines)
        changed[path] = list(lines[path])
        changed[path][at + 4] = changed[path][at + 4].replace("#$8000", "#$4000")
        self.assertEqual((None, ""), resting_attribute(
            changed, index, handler, stage.object_attribute,
            stage_attributes=stage.object_attributes,
            priority=stage.configuration.sprite_priority,
            slots=library()["tile_slots"]))

    def test_stage_12_teddy_state_zero_selects_a_real_mapping_and_base(self) -> None:
        stage = scene(ROOT, 11)
        handler = "Stage12_TeddyBearMain"
        symbol, mapping = resting_mapping(library(), handler)
        self.assertEqual("SharedTeddyHazardLoopAnimation", symbol)
        self.assertEqual("SharedTeddyHazardSpriteMappingA", mapping.label)
        self.assertEqual((0x8000, "immediate"), object_attribute(
            library(), handler, stage.object_attribute,
            stage_attributes=stage.object_attributes,
            priority=stage.configuration.sprite_priority))
        lines, index = source_index(ROOT)
        path, at = index["Stage12_TeddyBearInit"]
        changed = dict(lines)
        changed[path] = list(lines[path])
        line = next(i for i in range(at, at + 20)
                    if "move.w  #$8000,$E(a5)" in changed[path][i])
        changed[path][line] = changed[path][line].replace("#$8000", "#$4000")
        self.assertEqual("", resting_symbol(changed, index, handler))


    def test_family_tile_slots_follow_ram_symbols_and_stage_commands(self) -> None:
        self.assertEqual({
            "EnemyProjectileTileAttr": 4,
            "BirdEnemyTileAttr": 6,
            "PhaseEnemyTileAttr": 8,
            "Stage10WaspTileAttr": 10,
            "CirclingEnemyTileAttr": 12,
        },
                         tile_attribute_slots(ROOT))
        for stage_index, handler, slot, expected in (
                (1, "Enemy_CirclingController", 12, 0x8C00),
                (4, "Enemy_BirdController", 6, 0x0C00),
                (17, "Enemy_CirclingController", 12, 0x0B00)):
            built = scene(ROOT, stage_index)
            self.assertIn(slot, built.object_attributes)
            self.assertEqual(expected, object_attribute(
                library(), handler, built.object_attribute,
                stage_attributes=built.object_attributes,
                priority=built.configuration.sprite_priority)[0])
        first = scene(ROOT, 0)
        self.assertNotIn(6, first.object_attributes)
        self.assertEqual((None, ""), object_attribute(
            library(), "Enemy_BirdController", first.object_attribute,
            stage_attributes=first.object_attributes,
            priority=first.configuration.sprite_priority))
        phase = scene(ROOT, 2)
        self.assertEqual((None, ""), object_attribute(
            library(), "Enemy_PhasePatternController", phase.object_attribute,
            stage_attributes=phase.object_attributes,
            priority=phase.configuration.sprite_priority, parameter=0x80))

    def test_a_compact_command_is_an_index_and_a_destination(self) -> None:
        blocks, _ = labelled_blocks(ROOT)
        lines, index = source_index(ROOT)
        commands, attributes = expand_tile_commands(blocks, lines, index,
                                                    "Stage1TileAssetCommands")
        self.assertEqual(["StageSharedTileArtSource00", "StageSharedTileArtSource02",
                          "StageSharedTileArtSource04"],
                         [command.source for command in commands])
        self.assertEqual([0x6000, 0x7000, 0x8000],
                         [command.destination for command in commands])
        # lsr.w #5 then ori.w #$800.
        self.assertEqual((0x6000 >> TILE_SHIFT) | TILE_ATTRIBUTE_BIT, attributes[0])

    def test_full_visual_commands_keep_their_source_longwords(self) -> None:
        blocks, _ = labelled_blocks(ROOT)
        lines, index = source_index(ROOT)
        records = (
            ("Stage7TileAssetCommands", "Stage15TileArt2", 0x8000),
            ("Stage8TrainTileAssetCommands", "Stage9XiTigerEntranceTileArt", 0x8000),
            ("Stage15VisualAssetLoadList", "Stage15TileArt", 0x6000),
            ("Stage16TileAssetCommands", "Boss_BackStringerTileArt2", 0x7000),
            ("Stage18TileAssetCommands", "Stage22And24TileArt2", 0x7000),
            ("Stage20VisualAssetLoadList", "Stage20TileArt", 0x6000),
            ("Stage21VisualAssetLoadList", "Stage21TileArt8000", 0x8000),
            ("Stage22VisualAssetLoadList", "Stage22And24TileArt", 0x8000),
            ("Stage24VisualAssetLoadList", "Stage22And24TileArt", 0x8000),
        )
        for name, source, destination in records:
            with self.subTest(name=name):
                commands, _attributes = expand_tile_commands(blocks, lines, index, name)
                self.assertIn((7, source, destination), [
                    (command.command, command.source, command.destination)
                    for command in commands])

        built = scene(ROOT, 6)
        body = decompress(blocks["Stage15TileArt2"])
        self.assertEqual(body, built.vram[0x8000:0x8000 + len(body)])

    def test_every_stage_reaches_a_visual_loader(self) -> None:
        loaders = read_visual_loaders(ROOT)
        self.assertEqual(26, len(loaders))
        self.assertEqual(("Stage1TileAssetCommands", "SharedStagePaletteCommand"),
                         loaders[0])

    def test_the_object_attribute_is_the_one_the_spawner_builds(self) -> None:
        built = scene(ROOT, 0)
        # SpawnedEnemyTileAttr[0] or GlobalSpritePriorityBit.
        self.assertEqual(0x8B00, built.object_attribute)
        self.assertEqual(0x300, built.object_attribute & OBJECT_TILE_MASK)
        self.assertEqual(0x8800, built.object_attribute & OBJECT_ATTRIBUTE_MASK)

    def test_the_visual_loader_palette_fills_the_object_line(self) -> None:
        """Without it an enemy is a correctly shaped black silhouette."""
        built = scene(ROOT, 0)
        self.assertNotEqual([(0, 0, 0)] * 15, built.palette[49:64])


class CarriedArtGuardTests(unittest.TestCase):
    def carried_art_with(self, command, raw):
        """A tiny loader fixture; no project source scan or stage decode."""
        path = Path("fixture.s")
        source = [
            "StageReady_Initialize:",
            "    movea.l #StageEntryAssetLoadList,a0",
            "    jsr (LoadObjData).l",
            "; End of function StageReady_Initialize",
            "Gfx_ClearStagingAndFirst48KiBVRAM:",
            "    bsr.w Gfx_ClearVRAMFirst48KiB",
            "; End of function Gfx_ClearStagingAndFirst48KiBVRAM",
        ]
        read = {
            "source_index": ({path: source}, {
                "StageReady_Initialize": (path, 0),
                "Gfx_ClearStagingAndFirst48KiBVRAM": (path, 4),
            }),
            "data": {"SharedMenuType3DataF680": b"fixture", "LaterArt": raw},
            "lists": {"StageEntryAssetLoadList": (
                AssetCommand(3, "SharedMenuType3DataF680", 0xF680), command)},
            "loaders": ["EmptyLoader"],
            "bodies": {},
            "visual_loaders": [("", "")],
        }
        art = b"\x11" * (0x10000 - 0xF680)
        with (mock.patch("authoring.stage_renderer.read_once", return_value=read),
              mock.patch("authoring.tile_codec.decompress", return_value=art)):
            return weapon_selection_carried_art(ROOT, 0)

    def test_both_raw_vram_aliases_reject_overlapping_copies(self):
        for kind in (1, 5):
            with self.subTest(command=kind):
                self.assertIsNone(self.carried_art_with(
                    AssetCommand(kind, "LaterArt", 0xF680), b"\x00\x04abcd"))

    def test_raw_copy_span_excludes_header_and_unused_trailing_bytes(self):
        for kind in (1, 5):
            with self.subTest(command=kind):
                art = self.carried_art_with(
                    AssetCommand(kind, "LaterArt", 0xF67C),
                    b"\x00\x04abcdtrailing bytes")
                self.assertEqual(b"\x11" * 2432, art)

    def test_incomplete_or_unsafe_raw_copy_cannot_prove_survival(self):
        for raw in (b"\x00", b"\x00\x00", b"\x00\x03abc", b"\x00\x08abcd",
                    b"\x80\x00" + bytes(0x8000)):
            with self.subTest(header=raw[:2]):
                self.assertIsNone(self.carried_art_with(
                    AssetCommand(5, "LaterArt", 0), raw))

    def test_unknown_handler_is_rejected_but_ram_handlers_do_not_touch_vram(self):
        self.assertIsNone(self.carried_art_with(AssetCommand(9, "LaterArt", 0), b""))
        for kind in (0, 2, 4, 6):
            with self.subTest(command=kind):
                self.assertIsNotNone(self.carried_art_with(
                    AssetCommand(kind, "LaterArt", 0xF680), None))


class DrawingTests(unittest.TestCase):
    def test_weapon_selection_art_rejects_later_overlapping_entry_transfer(self):
        read = read_once(ROOT)
        lists = dict(read["lists"])
        lists["StageEntryAssetLoadList"] = (
            *lists["StageEntryAssetLoadList"],
            AssetCommand(1, "SharedMenuType3DataF680", 0xF680))
        altered = {**read, "lists": lists}
        with mock.patch("authoring.stage_renderer.read_once", return_value=altered):
            self.assertIsNone(weapon_selection_carried_art(ROOT, 0))

    def test_first_oam_piece_wins_when_mapping_pieces_overlap(self) -> None:
        mapping = SpriteMapping("test", 0, (
            SpritePiece(0, 0, 0, 0, 0),
            SpritePiece(0x8001, 0, 0, 0, 0),
        ))
        vram = bytes([0x11] * 32 + [0x22] * 32)
        palette = [(index, 0, 0) for index in range(64)]
        pixels, left, top = compose_static(mapping, vram, palette, 0)
        self.assertEqual((0, 0), (left, top))
        self.assertEqual({palette[1]}, {pixel for row in pixels for pixel in row})

    def test_all_15_platforms_follow_the_low_stage_index_variant(self) -> None:
        handler = "Stage18_MovingPlatform"
        self.assertEqual(("", None), resting_mapping(library(), handler))
        self.assertEqual((None, ""), object_attribute(
            library(), handler, scene(ROOT, 9).object_attribute))
        total = 0
        for stage_index, expected in ((9, 2), (11, 2), (17, 3), (18, 8)):
            studio = open_stage(ROOT, stage_index)
            self.assertEqual(("Stage18_MovingPlatformSpriteMapping",
                              library()["mappings"]["Stage18_MovingPlatformSpriteMapping"]),
                             resting_mapping(library(), handler,
                                             stage_index=stage_index))
            self.assertEqual((0x4000, "stage-index platform branch"),
                             object_attribute(
                                 library(), handler, studio.scene.object_attribute,
                                 stage_index=stage_index))
            family = [item for item in studio.placements if item.handler == handler]
            self.assertEqual(expected, len(family))
            for placement in family:
                self.assertIsNotNone(placement_sprite(studio, library(), placement))
            total += len(family)
        self.assertEqual(15, total)

    def test_every_previewable_piece_has_nonblank_staged_tile_art(self) -> None:
        count = 0
        for stage_index in range(26):
            studio = open_stage(ROOT, stage_index)
            for placement in studio.placements:
                attribute, _how = object_attribute(
                    library(), placement.handler, studio.scene.object_attribute,
                    stage_attributes=studio.scene.object_attributes,
                    priority=studio.scene.configuration.sprite_priority,
                    parameter=placement.entry.parameter, stage_index=stage_index)
                _symbol, mapping = resting_mapping(
                    library(), placement.handler, placement.entry.parameter,
                    stage_index)
                if attribute is None or mapping is None:
                    continue
                count += 1
                vram = studio.scene.vram
                if placement.handler == WEAPON_SELECTION_HANDLER:
                    carried = weapon_selection_carried_art(ROOT, stage_index)
                    self.assertIsNotNone(carried)
                    vram = vram[:WEAPON_SELECTION_ART_START] + carried
                for piece in mapping.pieces:
                    start = ((attribute & OBJECT_TILE_MASK) + piece.tile) & 0x7FF
                    self.assertTrue(any(
                        any(vram[((start + offset) & 0x7FF) * 32:
                                 (((start + offset) & 0x7FF) + 1) * 32])
                        for offset in range(piece.tile_count)),
                        (stage_index, placement.handler, placement.index, piece))
        self.assertEqual(275, count)

    def test_all_three_stage_12_floaters_use_visible_source_tiles(self) -> None:
        read = read_once(ROOT)
        names = (loader_lists(ROOT, read["bodies"], read["lists"], SHARED_LOADER)
                 + loader_lists(ROOT, read["bodies"], read["lists"],
                                read["loaders"][11]))
        self.assertIn("Stage10EnemyAssetLoadList", names)
        art = next(command for command in read["lists"]["Stage10EnemyAssetLoadList"]
                   if command.source == "Stage10AndTeleportTileArt0000")
        self.assertEqual(0, art.destination)
        decoded = decompress(read["data"][art.source])
        _, mapping = resting_mapping(library(), "Enemy_Stage12FloaterController")
        staged_vram = scene(ROOT, 11).vram
        for piece in mapping.pieces:
            start = piece.tile * 32
            stop = start + piece.tile_count * 32
            self.assertLessEqual(stop, len(decoded))
            self.assertEqual(decoded[start:stop], staged_vram[start:stop])
        for profile in ("jp", "eu"):
            studio = open_stage(ROOT, 11, profile=profile)
            family = [item for item in studio.placements if item.handler ==
                      "Enemy_Stage12FloaterController"]
            self.assertEqual(3, len(family))
            for placement in family:
                sprite = placement_sprite(studio, library(), placement)
                self.assertIsNotNone(sprite)
                self.assertTrue(any(pixel is not None
                                    for row in sprite[0] for pixel in row))

    def test_homing_phase_and_wasp_placements_use_loaded_family_slots(self) -> None:
        total = 0
        for stage_index, handler, slot, expected in (
                (0, "Enemy_HomingAttackController", 4, 2),
                (2, "Enemy_PhasePatternController", 8, 1),
                (3, "Enemy_PhasePatternController", 8, 1),
                (9, "Enemy_Stage10WaspController", 10, 2),
                (11, "Enemy_Stage10WaspController", 10, 1)):
            studio = open_stage(ROOT, stage_index)
            self.assertIn(slot, studio.scene.object_attributes)
            family = [item for item in studio.placements if item.handler == handler]
            self.assertEqual(expected, len(family))
            for placement in family:
                sprite = placement_sprite(studio, library(), placement)
                self.assertIsNotNone(sprite)
                self.assertTrue(any(pixel is not None
                                    for row in sprite[0] for pixel in row))
            total += len(family)
        self.assertEqual(7, total)

    def test_all_seven_indexed_placements_select_visible_source_frames(self) -> None:
        expected = ((4, ((8, 1), (0x8000, 0), (0x8008, 1))),
                    (5, ((8, 1), (24, 3), (16, 2))),
                    (6, ((0x8020, 4),)))
        count = 0
        for stage_index, expected_entries in expected:
            studio = open_stage(ROOT, stage_index)
            family = [item for item in studio.placements if item.handler ==
                      "Object_InitIndexedSpriteGraphics"]
            self.assertEqual([parameter for parameter, _ in expected_entries],
                             [item.entry.parameter for item in family])
            for placement, (_parameter, selector) in zip(family, expected_entries):
                symbol, mapping = resting_mapping(
                    library(), placement.handler, placement.entry.parameter)
                self.assertEqual("IndexedObjectSpriteAnimation%02d" % selector,
                                 symbol)
                self.assertIsNotNone(mapping)
                sprite = placement_sprite(studio, library(), placement)
                self.assertIsNotNone(sprite)
                self.assertTrue(any(pixel is not None
                                    for row in sprite[0] for pixel in row))
                count += 1
        self.assertEqual(7, count)

    def test_all_35_parameterized_proximity_placements_have_visible_tiles(self) -> None:
        total = 0
        variants = set()
        for stage_index, expected in ((0, 4), (1, 8), (3, 13),
                                      (10, 3), (11, 5), (17, 2)):
            studio = open_stage(ROOT, stage_index)
            family = [item for item in studio.placements if item.handler ==
                      "Object_UpdateProximityPickupEmitterType48"]
            self.assertEqual(expected, len(family))
            for placement in family:
                variants.add(placement.entry.parameter)
                sprite = placement_sprite(studio, library(), placement)
                self.assertIsNotNone(sprite)
                self.assertTrue(any(pixel is not None
                                    for row in sprite[0] for pixel in row))
            total += len(family)
        self.assertEqual(35, total)
        self.assertEqual({0, 2}, variants)

    def test_all_107_family_placements_have_visible_source_tiles(self) -> None:
        total = 0
        for stage_index, handler, expected in (
                (1, "Enemy_CirclingController", 22),
                (4, "Enemy_BirdController", 10),
                (9, "Enemy_BirdController", 11),
                (10, "Enemy_BirdController", 5),
                (11, "Enemy_BirdController", 1),
                (17, "Enemy_CirclingController", 42),
                (18, "Enemy_CirclingController", 10),
                (18, "Enemy_BirdController", 6)):
            studio = open_stage(ROOT, stage_index)
            family = [item for item in studio.placements if item.handler == handler]
            self.assertEqual(expected, len(family))
            for placement in family:
                sprite = placement_sprite(studio, library(), placement)
                self.assertIsNotNone(sprite)
                self.assertTrue(any(pixel is not None
                                    for row in sprite[0] for pixel in row))
            total += len(family)
        self.assertEqual(107, total)

    def test_a_placement_draws_as_a_picture_at_its_own_position(self) -> None:
        studio = open_stage(ROOT, 0)
        first = studio.placements[0]
        pixels, left, top = placement_sprite(studio, library(), first)
        self.assertTrue(pixels and pixels[0])
        self.assertLessEqual(left, first.map_x)
        self.assertLessEqual(top, first.map_y)
        self.assertTrue(any(pixel is not None for row in pixels for pixel in row))

    def test_a_mapping_is_coloured_through_the_object_attribute(self) -> None:
        studio = open_stage(ROOT, 0)
        _, mapping = resting_mapping(library(), studio.placements[0].handler)
        palette = [(index, 0, 0) for index in range(64)]
        lit, _, _ = compose_static(mapping, studio.scene.vram, palette, 0x8B00)
        used = {pixel for row in lit for pixel in row if pixel is not None}
        self.assertTrue(used)
        self.assertTrue(all(0 <= red < 64 for red, _, _ in used))

    def test_what_is_drawn_and_what_is_not_matches_the_declaration(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        declared = config["object_sprites"]
        self.assertEqual(declared, synchronized(config, ROOT)["object_sprites"])
        self.assertEqual(314, declared["placements"])
        self.assertEqual(275, declared["placements_drawn"])
        self.assertNotIn("Enemy_Stage12FloaterController",
                         declared["handlers_without_a_tile_base"])
        self.assertNotIn("Enemy_BirdController",
                         declared["handlers_without_a_tile_base"])
        self.assertNotIn("Enemy_CirclingController",
                         declared["handlers_without_a_tile_base"])
        self.assertNotIn("Object_UpdateProximityPickupEmitterType48",
                         declared["handlers_without_a_tile_base"])
        self.assertNotIn("Object_InitIndexedSpriteGraphics",
                         declared["handlers_without_a_tile_base"])
        for handler in ("Enemy_HomingAttackController",
                        "Enemy_PhasePatternController",
                        "Enemy_Stage10WaspController"):
            self.assertNotIn(handler, declared["handlers_without_a_tile_base"])
        self.assertTrue(declared["handlers_without_a_sprite_why"].strip())
        self.assertTrue(declared["handlers_without_a_tile_base_why"].strip())

    def test_a_handler_is_not_drawn_through_another_object_base(self) -> None:
        """The wrong base gives the right shape in the wrong enemy's art."""
        default = scene(ROOT, 0).object_attribute
        base, how = object_attribute(library(), "Enemy_BehaviorController", default)
        self.assertEqual(default, base)
        self.assertEqual("the stage default", how)
        self.assertEqual((0x480, "immediate"),
                         object_attribute(library(), "Enemy_PeriodicShotController", default))
        self.assertEqual((None, ""),
                         object_attribute(library(), "Enemy_CirclingController", default))

    def test_the_overlay_reports_exactly_the_placements_it_drew(self) -> None:
        studio = open_stage(ROOT, 0)
        image = studio.image(0, 0, 64, 64)
        drawn = overlay_placements(studio, image, 0, 0, library())
        self.assertEqual(sorted(drawn), drawn)
        self.assertEqual(len(studio.placements), len(drawn))
        for index in drawn:
            self.assertIsNotNone(
                placement_sprite(studio, library(), studio.placements[index]))

    def test_every_stage_opens_even_without_a_plane(self) -> None:
        """Index 16 has plane A entry mode zero, so it has no plane A at all."""
        for index in range(26):
            studio = open_stage(ROOT, index)
            self.assertGreaterEqual(studio.width, 256, index)
            self.assertTrue(studio.image(0, 0, 32, 32))


if __name__ == "__main__":
    unittest.main()
