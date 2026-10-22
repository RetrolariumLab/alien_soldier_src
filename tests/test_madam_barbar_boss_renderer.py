"""Bounded source-only Madam Barbar two-plane screenshot and state gate."""

from __future__ import annotations

import hashlib
import json
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.boss_palette_fade_model import (  # noqa: E402
    boss_faded_line_from_source,
)
from authoring.madam_barbar_boss_renderer import (  # noqa: E402
    MadamBarbarPose,
    draw_madam_barbar_background,
)
from authoring.stage5_6_boss_tilemap_model import (  # noqa: E402
    build_boss_secondary_table,
)
from authoring.stage_renderer import draw, read_once, scene  # noqa: E402
from authoring.stage_tilemap_model import decompress  # noqa: E402
from runtime_state import Genstate  # noqa: E402


FIXTURE = ROOT / "config/authoring/stage5_6_jp_fidelity.json"


def signed_word(word: int) -> int:
    return word - 0x10000 if word & 0x8000 else word


class MadamBarbarBossRendererTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.fixture = json.loads(FIXTURE.read_text(encoding="utf-8"))

    def test_source_background_matches_pinned_b_regions(self) -> None:
        captures = self.fixture["madam_barbar_captures"]
        self.assertEqual([7500, 7900, 8000, 8200, 8400], [item["displayed_frame"] for item in captures])
        ramp = dict(zip(self.fixture["preview_cram_levels"], self.fixture["gens_rgb_levels"]))
        self.assertEqual(8, len(ramp))
        table = build_boss_secondary_table(ROOT, "madam_barbar")
        data = read_once(ROOT)["data"]
        art = decompress(data["Boss_MadamBarbarTileArt"])
        total = contributed = 0
        for capture in captures:
            with self.subTest(frame=capture["displayed_frame"]):
                pose = MadamBarbarPose(**capture["pose"])
                image = draw_madam_barbar_background(ROOT, pose)
                without_b = draw(scene(ROOT, 4), x=-pose.primary_hscroll, y=pose.primary_vscroll, width=320, height=224)
                screenshot = ROOT / "reference/tas" / ("%06d.png" % capture["displayed_frame"])
                if screenshot.is_file():
                    self.assertEqual(capture["png_sha256"], hashlib.sha256(screenshot.read_bytes()).hexdigest())
                    from PIL import Image

                    reference = Image.open(screenshot).convert("RGB")
                else:
                    reference = None
                for region in capture["regions"]:
                    left, top, right, bottom = region["box"]
                    self.assertTrue(0 <= left < right <= 320 and 32 <= top < bottom <= 224)
                    rgb = bytes(
                        ramp[channel]
                        for row in image[top - 32 : bottom - 32]
                        for pixel in row[left:right]
                        for channel in pixel
                    )
                    self.assertEqual(region["rgb_sha256"], hashlib.sha256(rgb).hexdigest())
                    changed = sum(
                        image[y - 32][x] != without_b[y][x] for y in range(top, bottom) for x in range(left, right)
                    )
                    self.assertEqual(region["b_contributing_pixels"], changed)
                    total += (right - left) * (bottom - top)
                    contributed += changed
                    if reference is not None:
                        self.assertEqual(rgb, reference.crop((left, top, right, bottom)).tobytes())
                state_path = ROOT / "reference/tas" / ("%06d.genstate" % capture["state_frame"])
                if not state_path.is_file():
                    continue
                self.assertEqual(capture["genstate_sha256"], hashlib.sha256(state_path.read_bytes()).hexdigest())
                state = Genstate.read(state_path)
                self.assertEqual(capture["displayed_frame"], capture["state_frame"] + 1)
                self.assertEqual(4, state.m68k_u16(0xFFFFA204) // 2)
                self.assertEqual(0x34, state.m68k_u16(0xFFFFA950))
                self.assertEqual(0x118, state.m68k_u16(0xFFFFC620))
                self.assertEqual(0, state.m68k_u16(0xFFFFF74A))
                self.assertEqual(0, state.m68k_u16(0xFFFF8090))
                for field, address in (
                    ("primary_hscroll", 0xFFFFE400),
                    ("secondary_hscroll", 0xFFFFE402),
                    ("primary_vscroll", 0xFFFFEC00),
                    ("secondary_vscroll", 0xFFFFEC02),
                ):
                    self.assertEqual(getattr(pose, field), signed_word(state.m68k_u16(address)))
                self.assertEqual(pose.secondary_vscroll & 0xFFFF, int.from_bytes(state.sections[0x12][2:4], "little"))
                self.assertEqual(pose.fade_phase, state.m68k_u16(0xFFFF80EE))
                faded = boss_faded_line_from_source(data, "Boss_MadamBarbarPaletteCommand", pose.fade_phase)
                self.assertEqual(faded, tuple(state.m68k_u16(0xFFFFE300 + 2 * index) for index in range(49, 64)))
                vram = state.sections[0x10]
                self.assertEqual(
                    table.name_words(), b"".join(vram[index : index + 2][::-1] for index in range(0xE000, 0xF000, 2))
                )
                self.assertEqual(
                    art, b"".join(vram[index : index + 2][::-1] for index in range(0x6000, 0x6000 + len(art), 2))
                )
        self.assertEqual((3072, 3041), (total, contributed))

    def test_unsupported_viewport_and_fade_fail_closed(self) -> None:
        pose = MadamBarbarPose(**self.fixture["madam_barbar_captures"][0]["pose"])
        with self.assertRaisesRegex(ValueError, "rows 32..223"):
            draw_madam_barbar_background(ROOT, pose, top=31)
        with self.assertRaisesRegex(ValueError, "viewport width"):
            draw_madam_barbar_background(ROOT, pose, width=321)
        with self.assertRaisesRegex(ValueError, "fade phase"):
            draw_madam_barbar_background(ROOT, MadamBarbarPose(**{**pose.__dict__, "fade_phase": 7}))


if __name__ == "__main__":
    unittest.main()
