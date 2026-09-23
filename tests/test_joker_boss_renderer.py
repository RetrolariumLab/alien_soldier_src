"""Bounded source-only Joker plane-B raster/background screenshot gate."""

from __future__ import annotations

import hashlib
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.joker_boss_renderer import (  # noqa: E402
    JokerRasterPose, draw_joker_raster_background)
from authoring.stage_renderer import draw, scene  # noqa: E402
from runtime_state import Genstate  # noqa: E402


FIXTURE = ROOT / "config/authoring/stage5_6_jp_fidelity.json"


def signed_word(word: int) -> int:
    return word - 0x10000 if word & 0x8000 else word


class JokerBossRendererTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))

    def test_source_raster_matches_pinned_b_contributing_regions(self) -> None:
        captures = self.fixture["joker_raster_captures"]
        self.assertEqual([10000, 10001, 10101],
                         [item["displayed_frame"] for item in captures])
        ramp = dict(zip(self.fixture["preview_cram_levels"],
                        self.fixture["gens_rgb_levels"]))
        self.assertEqual(8, len(ramp))
        total = contributed = 0
        for capture in captures:
            with self.subTest(frame=capture["displayed_frame"]):
                pose = JokerRasterPose(**capture["pose"])
                image = draw_joker_raster_background(ROOT, pose)
                without_b = draw(
                    scene(ROOT, 5), x=-pose.primary_hscroll,
                    y=0, width=320, height=224)
                screenshot = ROOT / "reference/tas" / (
                    "%06d.png" % capture["displayed_frame"])
                if screenshot.is_file():
                    self.assertEqual(
                        capture["png_sha256"],
                        hashlib.sha256(screenshot.read_bytes()).hexdigest())
                    from PIL import Image

                    reference = Image.open(screenshot).convert("RGB")
                else:
                    reference = None
                for region in capture["regions"]:
                    left, top, right, bottom = region["box"]
                    self.assertTrue(
                        0 <= left < right <= 320
                        and 32 <= top < bottom <= 224)
                    rgb = bytes(
                        ramp[channel]
                        for row in image[top - 32:bottom - 32]
                        for pixel in row[left:right]
                        for channel in pixel)
                    self.assertEqual(
                        region["rgb_sha256"],
                        hashlib.sha256(rgb).hexdigest())
                    changed = sum(
                        image[y - 32][x] != without_b[y][x]
                        for y in range(top, bottom)
                        for x in range(left, right))
                    self.assertEqual(region["b_contributing_pixels"], changed)
                    total += (right - left) * (bottom - top)
                    contributed += changed
                    if reference is not None:
                        self.assertEqual(
                            rgb, reference.crop(
                                (left, top, right, bottom)).tobytes())
                state_path = ROOT / "reference/tas" / (
                    "%06d.genstate" % capture["state_frame"])
                if not state_path.is_file():
                    continue
                self.assertEqual(
                    capture["genstate_sha256"],
                    hashlib.sha256(state_path.read_bytes()).hexdigest())
                state = Genstate.read(state_path)
                self.assertEqual(
                    capture["displayed_frame"], capture["state_frame"] + 1)
                self.assertEqual(5, state.m68k_u16(0xFFFFA204) // 2)
                self.assertEqual(
                    pose.primary_hscroll,
                    signed_word(state.m68k_u16(0xFFFFE400)))
                self.assertEqual(
                    pose.secondary_hscroll,
                    signed_word(state.m68k_u16(0xFFFFE402)))
                self.assertEqual(
                    pose.frame_counter, state.m68k_u16(0xFFFFA000))
                self.assertEqual(
                    pose.secondary_frame_offset,
                    state.m68k_u16(0xFFFFC620 + 0x29C))
                self.assertEqual(
                    pose.body_y, state.m68k_u16(0xFFFFC620 + 0x14))
                self.assertEqual(
                    pose.body_height,
                    state.m68k_u16(0xFFFFC620 + 0x1DC))
                self.assertEqual(
                    pose.fade_phase, state.m68k_u16(0xFFFF80EE))
                self.assertEqual(0x10, state.m68k_u16(0xFFFFF74A))
                self.assertEqual(0x0E, state.m68k_u16(0xFFFF8090))
                self.assertEqual(0x8A01, state.m68k_u16(0xFFFFF7E4))
                self.assertEqual(
                    (0,) * 15,
                    tuple(state.m68k_u16(0xFFFF9E00 + 2 * index)
                          for index in range(15)))
        self.assertEqual((3584, 3558), (total, contributed))

    def test_unsupported_pose_and_viewport_fail_closed(self) -> None:
        pose = JokerRasterPose(
            **self.fixture["joker_raster_captures"][0]["pose"])
        with self.assertRaisesRegex(ValueError, "rows 32..223"):
            draw_joker_raster_background(ROOT, pose, top=0)
        with self.assertRaisesRegex(ValueError, "viewport width"):
            draw_joker_raster_background(ROOT, pose, width=321)
        with self.assertRaisesRegex(ValueError, "zero initial VScroll"):
            draw_joker_raster_background(
                ROOT, JokerRasterPose(
                    **{**pose.__dict__, "initial_secondary_vscroll": 1}))
        with self.assertRaisesRegex(ValueError, "fade phase"):
            draw_joker_raster_background(
                ROOT, JokerRasterPose(
                    **{**pose.__dict__, "fade_phase": 7}))


if __name__ == "__main__":
    unittest.main()
