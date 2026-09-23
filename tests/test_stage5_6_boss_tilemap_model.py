"""Source-indexed Madam Barbar and Joker plane-B name-table probes."""

from __future__ import annotations

import hashlib
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.indexed_row_transfer import (  # noqa: E402
    apply_indexed_rows, descriptor_bytes)
from authoring.boss_palette_fade_model import (  # noqa: E402
    boss_faded_line_from_source)
from authoring.joker_raster_model import (  # noqa: E402
    copy_boss_transition_window, joker_perspective_rows)
from authoring.stage5_6_boss_tilemap_model import (  # noqa: E402
    BOSSES, build_boss_secondary_table)
from authoring.stage_renderer import read_once  # noqa: E402
from authoring.stage_tilemap_model import decompress  # noqa: E402
from runtime_state import Genstate  # noqa: E402


FIXTURE = ROOT / "config/authoring/stage5_6_jp_fidelity.json"


def runtime_plane_b_bytes(state: Genstate) -> bytes:
    vram = state.sections[0x10]
    return b"".join(
        int.from_bytes(vram[0xE000 + index * 2:
                            0xE002 + index * 2], "little").to_bytes(2, "big")
        for index in range(2048))


class StageFiveAndSixBossTableTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))

    def test_setup_tables_match_source_and_saved_vdp(self) -> None:
        tables = {}
        for capture in self.fixture["captures"]:
            with self.subTest(frame=capture["frame"]):
                boss = capture["boss_plane_b"]
                animation = {}
                if boss == "joker":
                    animation = {
                        "frame_counter": capture["joker_frame_counter"],
                        "secondary_frame_offset": capture[
                            "joker_secondary_frame_offset"],
                    }
                if boss not in tables:
                    tables[boss] = build_boss_secondary_table(
                        ROOT, boss, **animation)
                table = tables[boss]
                self.assertEqual(
                    self.fixture["shared_boss_mapping_sha256"],
                    hashlib.sha256(table.mapping).hexdigest())
                self.assertEqual(
                    capture["plane_b_descriptor_sha256"],
                    hashlib.sha256(table.descriptor).hexdigest())
                self.assertEqual(
                    capture["plane_b_source_sha256"],
                    hashlib.sha256(table.name_words()).hexdigest())
                state_path = ROOT / "reference/tas" / (
                    "%06d.genstate" % (capture["frame"] - 1))
                if not state_path.is_file():
                    continue
                self.assertEqual(
                    capture["preceding_genstate_sha256"],
                    hashlib.sha256(state_path.read_bytes()).hexdigest())
                state = Genstate.read(state_path)
                if boss == "joker":
                    self.assertEqual(
                        animation["frame_counter"],
                        state.m68k_u16(0xFFFFA000))
                    self.assertEqual(
                        animation["secondary_frame_offset"],
                        state.m68k_u16(0xFFFFC620 + 0x29C))
                runtime_bytes = runtime_plane_b_bytes(state)
                self.assertEqual(
                    capture["plane_b_runtime_sha256"],
                    hashlib.sha256(runtime_bytes).hexdigest())
                source_bytes = table.name_words()
                differences = [
                    index for index in range(2048)
                    if source_bytes[2 * index:2 * index + 2] !=
                    runtime_bytes[2 * index:2 * index + 2]
                ]
                self.assertEqual(capture["plane_b_difference_indices"], differences)
        self.assertEqual({"madam_barbar", "joker"}, set(tables))

    def test_joker_animated_rows_and_raster_match_saved_states(self) -> None:
        for capture in self.fixture["joker_animation_states"]:
            with self.subTest(state_frame=capture["state_frame"]):
                table = build_boss_secondary_table(
                    ROOT, "joker",
                    frame_counter=capture["frame_counter"],
                    secondary_frame_offset=capture["secondary_frame_offset"])
                self.assertEqual(
                    capture["plane_b_sha256"],
                    hashlib.sha256(table.name_words()).hexdigest())
                perspective = joker_perspective_rows(
                    capture["joker_body_y"], capture["joker_body_height"])
                self.assertEqual(
                    capture["perspective_rows_sha256"],
                    hashlib.sha256(b"".join(
                        word.to_bytes(2, "big")
                        for word in perspective)).hexdigest())
                path = ROOT / "reference/tas" / (
                    "%06d.genstate" % capture["state_frame"])
                if not path.is_file():
                    continue
                self.assertEqual(
                    capture["genstate_sha256"],
                    hashlib.sha256(path.read_bytes()).hexdigest())
                state = Genstate.read(path)
                self.assertEqual(
                    capture["frame_counter"], state.m68k_u16(0xFFFFA000))
                self.assertEqual(
                    capture["secondary_frame_offset"],
                    state.m68k_u16(0xFFFFC620 + 0x29C))
                self.assertEqual(
                    capture["joker_body_y"],
                    state.m68k_u16(0xFFFFC620 + 0x14))
                self.assertEqual(
                    capture["joker_body_height"],
                    state.m68k_u16(0xFFFFC620 + 0x1DC))
                self.assertEqual(0x10, state.m68k_u16(0xFFFFF74A))
                self.assertEqual(0x0E, state.m68k_u16(0xFFFF8090))
                self.assertEqual(0x8A01, state.m68k_u16(0xFFFFF7E4))
                self.assertEqual(table.name_words(), runtime_plane_b_bytes(state))
                self.assertEqual(
                    perspective,
                    tuple(state.m68k_u16(0xFFFF9520 + 2 * index)
                          for index in range(96)))
                prefix = tuple(state.m68k_u16(0xFFFF9E00 + 2 * index)
                               for index in range(15))
                self.assertEqual((0,) * 15, prefix)
                active = copy_boss_transition_window(prefix, perspective)
                self.assertEqual(
                    active,
                    tuple(state.m68k_u16(0xFFFF9E00 + 2 * index)
                          for index in range(111)))
                self.assertEqual(
                    capture["active_raster_sha256"],
                    hashlib.sha256(b"".join(
                        word.to_bytes(2, "big")
                        for word in active)).hexdigest())
                if "fade_phase" in capture:
                    self.assertEqual(
                        capture["fade_phase"],
                        state.m68k_u16(0xFFFF80EE))
                    faded = boss_faded_line_from_source(
                        read_once(ROOT)["data"],
                        "Boss_JokerPaletteCommand",
                        capture["fade_phase"])
                    faded_bytes = b"".join(
                        word.to_bytes(2, "big") for word in faded)
                    self.assertEqual(
                        capture["palette_line3_sha256"],
                        hashlib.sha256(faded_bytes).hexdigest())
                    self.assertEqual(
                        faded,
                        tuple(state.m68k_u16(0xFFFFE300 + 2 * index)
                              for index in range(49, 64)))
                    self.assertEqual(
                        faded,
                        tuple(int.from_bytes(
                            state.sections[0x11][2 * index:2 * index + 2],
                            "little") for index in range(49, 64)))

    def test_active_boss_tile_art_matches_source_and_saved_vram(self) -> None:
        read = read_once(ROOT)
        for capture in self.fixture["captures"]:
            if "active_boss_entity_type" not in capture:
                continue
            with self.subTest(frame=capture["frame"]):
                boss = capture["boss_plane_b"]
                label = ("Boss_MadamBarbarTileArt" if boss == "madam_barbar"
                         else "Boss_JokerTileArt")
                graphics_list = read["lists"][BOSSES[boss][0]]
                self.assertTrue(any(
                    command.command == 7
                    and command.source == label
                    and command.destination == 0x6000
                    for command in graphics_list))
                source = read["data"][label]
                self.assertEqual(
                    capture["boss_tile_art_source_sha256"],
                    hashlib.sha256(source).hexdigest())
                art = decompress(source)
                self.assertEqual(
                    capture["boss_tile_art_decoded_bytes"], len(art))
                self.assertEqual(
                    capture["boss_tile_art_decoded_sha256"],
                    hashlib.sha256(art).hexdigest())
                state_path = ROOT / "reference/tas" / (
                    "%06d.genstate" % (capture["frame"] - 1))
                if not state_path.is_file():
                    continue
                state = Genstate.read(state_path)
                self.assertEqual(
                    capture["active_boss_entity_type"],
                    state.m68k_u16(0xFFFFC620))
                vram = state.sections[0x10]
                live_art = b"".join(
                    vram[index:index + 2][::-1]
                    for index in range(0x6000, 0x6000 + len(art), 2))
                self.assertEqual(art, live_art)
                self.assertEqual(
                    capture["preceding_boss_fade_phase"],
                    state.m68k_u16(0xFFFF80EE))
                palette_label = (
                    "Boss_MadamBarbarPaletteCommand"
                    if boss == "madam_barbar"
                    else "Boss_JokerPaletteCommand")
                faded = boss_faded_line_from_source(
                    read["data"], palette_label,
                    capture["preceding_boss_fade_phase"])
                self.assertEqual(
                    capture["preceding_boss_palette_line3_sha256"],
                    hashlib.sha256(b"".join(
                        word.to_bytes(2, "big")
                        for word in faded)).hexdigest())
                self.assertEqual(
                    faded,
                    tuple(state.m68k_u16(0xFFFFE300 + 2 * index)
                          for index in range(49, 64)))

    def test_pre_boss_plane_b_is_cleared_in_local_state(self) -> None:
        path = ROOT / "reference/tas/006999.genstate"
        if not path.is_file():
            self.skipTest("private pre-Madam-Barbar state is unavailable")
        state = Genstate.read(path)
        self.assertEqual(bytes(0x1000), state.sections[0x10][0xE000:0xF000])

    def test_invalid_indexed_layouts_fail_closed(self) -> None:
        with self.assertRaisesRegex(ValueError, "unsupported Stage 5/6 boss"):
            build_boss_secondary_table(ROOT, "unknown")
        with self.assertRaisesRegex(ValueError, "descriptor exceeds"):
            descriptor_bytes({"Bad": bytes.fromhex("61002000ff02")}, "Bad")
        with self.assertRaisesRegex(ValueError, "32 by 64"):
            apply_indexed_rows([[0]], bytes(0x4000),
                               bytes.fromhex("610020000302") + bytes(12))
        with self.assertRaisesRegex(ValueError, "both frame inputs"):
            build_boss_secondary_table(ROOT, "joker", frame_counter=0)
        with self.assertRaisesRegex(ValueError, "unsupported"):
            build_boss_secondary_table(
                ROOT, "joker", frame_counter=0,
                secondary_frame_offset=2)
        with self.assertRaisesRegex(ValueError, "height"):
            joker_perspective_rows(0x100, 0)
        with self.assertRaisesRegex(ValueError, "15 words"):
            copy_boss_transition_window((), (0,) * 96)


if __name__ == "__main__":
    unittest.main()
