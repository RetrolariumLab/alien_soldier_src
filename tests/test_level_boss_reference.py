"""Level Studio routes only pinned JP boss poses to source-only renderers."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import level_studio  # noqa: E402


class LevelBossReferenceTests(unittest.TestCase):
    def test_supported_poses_are_explicitly_jp_only(self) -> None:
        sniper = level_studio.boss_reference_captures(ROOT, "jp", 3)
        madam = level_studio.boss_reference_captures(ROOT, "jp", 4)
        joker = level_studio.boss_reference_captures(ROOT, "jp", 5)
        self.assertEqual([5500, 5600, 5700, 5800, 5900], [item["displayed_frame"] for item in sniper])
        self.assertEqual([7500, 7900, 8000, 8200, 8400], [item["displayed_frame"] for item in madam])
        self.assertEqual([10000, 10001, 10101], [item["displayed_frame"] for item in joker])
        for profile, index in (("eu", 3), ("eu", 4), ("eu", 5), ("jp", 6)):
            self.assertEqual((), level_studio.boss_reference_captures(ROOT, profile, index))

    def test_render_routes_pose_without_workspace_documents(self) -> None:
        with mock.patch.object(level_studio, "draw_sniper_honeyviper_background", return_value=[[(7, 8, 9)]]) as sniper:
            self.assertEqual([[(7, 8, 9)]], level_studio.render_boss_reference(ROOT, "jp", 3, 5600))
            sniper.assert_called_once()
            self.assertEqual(1, sniper.call_args.args[1].primary_shake_offset)
            self.assertEqual(487, sniper.call_args.args[1].current_x)
        with mock.patch.object(level_studio, "draw_madam_barbar_background", return_value=[[(1, 2, 3)]]) as madam:
            self.assertEqual([[(1, 2, 3)]], level_studio.render_boss_reference(ROOT, "jp", 4, 8000))
            madam.assert_called_once()
            self.assertEqual(15, madam.call_args.args[1].fade_phase)
            self.assertEqual(-304, madam.call_args.args[1].secondary_vscroll)
        with mock.patch.object(level_studio, "draw_joker_raster_background", return_value=[[(4, 5, 6)]]) as joker:
            self.assertEqual([[(4, 5, 6)]], level_studio.render_boss_reference(ROOT, "jp", 5, 10001))
            joker.assert_called_once()
            self.assertEqual(0, joker.call_args.args[1].fade_phase)
            self.assertEqual(4, joker.call_args.args[1].secondary_frame_offset)
        with self.assertRaisesRegex(ValueError, "no supported JP boss reference"):
            level_studio.render_boss_reference(ROOT, "eu", 4, 8000)
        with self.assertRaisesRegex(ValueError, "no supported JP boss reference"):
            level_studio.render_boss_reference(ROOT, "jp", 4, 10000)


if __name__ == "__main__":
    unittest.main()
