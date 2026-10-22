"""Bounded source-only Japanese Sniper Honeyviper background screenshot gate."""

from __future__ import annotations

import hashlib
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.stage4_boss_renderer import (  # noqa: E402
    SniperHoneyviperPose,
    draw_sniper_honeyviper_background,
)
from runtime_state import Genstate  # noqa: E402


FIXTURE = ROOT / "config/authoring/stage4_boss_jp_fidelity.json"


class SniperHoneyviperBackgroundFidelityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))
        cls.pose = SniperHoneyviperPose(**cls.fixture["captures"][0]["pose"])

    def test_source_only_background_matches_pinned_clean_regions(self) -> None:
        item = self.fixture
        self.assertEqual(2, item["schema_version"])
        self.assertEqual("jp", item["profile"])
        runtime = json.loads((ROOT / "config/runtime_scenarios.json").read_text(encoding="utf-8"))
        self.assertEqual(runtime["movies"]["tas"]["path"], item["tas_movie"])
        self.assertEqual(runtime["movies"]["tas"]["sha256"], item["tas_movie_sha256"])
        captures = item["captures"]
        self.assertEqual([5500, 5600, 5700, 5800, 5900], [capture["displayed_frame"] for capture in captures])
        ramp = dict(zip(item["preview_cram_levels"], item["gens_rgb_levels"]))
        self.assertEqual(8, len(ramp))
        total = 0
        for capture in captures:
            with self.subTest(frame=capture["displayed_frame"]):
                pose = SniperHoneyviperPose(**capture["pose"])
                preview = draw_sniper_honeyviper_background(ROOT, pose)
                screenshot = ROOT / "reference/tas" / ("%06d.png" % capture["displayed_frame"])
                if screenshot.is_file():
                    self.assertEqual(capture["png_sha256"], hashlib.sha256(screenshot.read_bytes()).hexdigest())
                    from PIL import Image

                    reference = Image.open(screenshot).convert("RGB")
                else:
                    reference = None
                for region in capture["reference_regions"]:
                    x0, y0, x1, y1 = region["box"]
                    self.assertTrue(0 <= x0 < x1 <= 320)
                    self.assertTrue(32 <= y0 < y1 <= 224)
                    rgb = bytes(
                        ramp[channel] for y in range(y0, y1) for pixel in preview[y - 32][x0:x1] for channel in pixel
                    )
                    self.assertEqual(region["rgb_sha256"], hashlib.sha256(rgb).hexdigest())
                    total += (x1 - x0) * (y1 - y0)
                    if reference is not None:
                        self.assertEqual(rgb, reference.crop((x0, y0, x1, y1)).tobytes())
        self.assertEqual(93120, total)

    def test_local_pose_and_vertical_scroll_match_source_writer(self) -> None:
        path = ROOT / "reference/tas/005499.genstate"
        if not path.is_file():
            self.skipTest("private Stage 4 boss genstate is unavailable")
        for capture in self.fixture["captures"]:
            with self.subTest(frame=capture["displayed_frame"]):
                state_path = ROOT / "reference/tas" / ("%06d.genstate" % (capture["displayed_frame"] - 1))
                self.assertEqual(
                    capture["preceding_genstate_sha256"], hashlib.sha256(state_path.read_bytes()).hexdigest()
                )
                state = Genstate.read(state_path)
                self.assertEqual(3, state.m68k_u16(0xFFFFA204) // 2)
                self.assertEqual(0x28, state.m68k_u16(0xFFFFA950))
                boss = 0xFFFFC620
                pose = SniperHoneyviperPose(**capture["pose"])
                self.assertEqual(
                    pose,
                    SniperHoneyviperPose(
                        state.m68k_u16(0xFFFFA900),
                        state.m68k_u16(0xFFFFA904),
                        state.m68k_u16(0xFFFFA012),
                        *(state.m68k_u16(boss + offset) for offset in (0x10, 0x14, 0x70, 0x74)),
                    ),
                )
                self.assertEqual(capture["vscroll_a"], state.m68k_u16(0xFFFFEC00))
                self.assertEqual(pose.primary_shake_offset, capture["vscroll_a"])
                self.assertEqual((-0x30 - pose.current_y) & 0xFFFF, state.m68k_u16(0xFFFFEC02))

    def test_unsupported_camera_and_hud_rows_fail_closed(self) -> None:
        wrong = SniperHoneyviperPose(
            0x1AF7,
            0,
            self.pose.primary_shake_offset,
            self.pose.current_x,
            self.pose.current_y,
            self.pose.anchor_x,
            self.pose.anchor_y,
        )
        with self.assertRaisesRegex(ValueError, "camera must be locked"):
            draw_sniper_honeyviper_background(ROOT, wrong)
        with self.assertRaisesRegex(ValueError, "camera Y must be zero"):
            draw_sniper_honeyviper_background(
                ROOT,
                SniperHoneyviperPose(
                    self.pose.primary_camera_x,
                    1,
                    self.pose.primary_shake_offset,
                    self.pose.current_x,
                    self.pose.current_y,
                    self.pose.anchor_x,
                    self.pose.anchor_y,
                ),
            )
        with self.assertRaisesRegex(ValueError, "rows 32..223"):
            draw_sniper_honeyviper_background(ROOT, self.pose, top=0)


if __name__ == "__main__":
    unittest.main()
