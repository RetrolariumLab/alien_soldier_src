"""The European boot check, on synthetic traces: no ROM or emulator."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from scripts.runtime import region_smoke as smoke  # noqa: E402


class RegionRuntimeSmokeTests(unittest.TestCase):
    def setUp(self):
        self.config = smoke.read_config(ROOT)

    def rows(self):
        expected = self.config["expectations"]
        rows = []
        for frame in range(1, 226):
            row = {name: 0 for name, _width in smoke.OBSERVATIONS}
            row.update(frame=frame, DifficultyMode=2, ConsoleVersionFlags=192,
                       GameModeIndex=4, VBlankFrameCounter=frame)
            if 25 <= frame < 125:
                row.update(expected["title"])
            elif frame >= 125:
                row.update(expected["attract_demo"])
                row.update(DemoFramesRemaining=4200 - frame, StageTableIndex=2, DemoStageTableIndex=2)
            rows.append(row)
        return rows

    def result(self, **changes):
        return {"status": "complete", "frame": 225, "story_start_frame": 0, **changes}

    def test_boot_title_and_running_demo_pass(self):
        summary = smoke.check_trace(self.config, self.rows(), self.result())
        self.assertEqual((1, 25, 125, 225), (summary["booted"], summary["title"], summary["demo"], summary["final"]))

    def test_wrong_region_missing_title_or_demo_fail(self):
        for name, value, first in (("ConsoleVersionFlags", 0, 0), ("GameModeIndex", 4, 24),
                                   ("DemoPlaybackState", 0, 124), ("DemoFramesRemaining", 4096 + 1, 124),
                                   ("DemoStageTableIndex", 4, 124), ("PlayerObjectType", 0, 124)):
            rows = self.rows()
            for row in rows[first:]:
                row[name] = value
            with self.subTest(name=name), self.assertRaises(ValueError):
                smoke.check_trace(self.config, rows, self.result())

    def test_timeout_short_demo_or_frozen_countdown_fail(self):
        rows = self.rows()
        with self.assertRaisesRegex(ValueError, "within"):
            smoke.check_trace(self.config, rows, self.result(status="timeout"))
        short = rows[:200]
        with self.assertRaisesRegex(ValueError, "in a row"):
            smoke.check_trace(self.config, short, self.result(frame=200))
        for row in rows[124:]:
            row["DemoFramesRemaining"] = 1000
        with self.assertRaisesRegex(ValueError, "countdown"):
            smoke.check_trace(self.config, rows, self.result())

    def test_start_only_at_the_story_skip(self):
        with self.assertRaisesRegex(ValueError, "story skip"):
            smoke.check_trace(self.config, self.rows(), self.result(story_start_frame=2))
        rows = self.rows()
        rows[1].update(GameModeIndex=40, PaletteFadeMaskStatus=1)
        self.assertEqual(2, smoke.check_trace(self.config, rows, self.result(story_start_frame=2))["story_start"])

    def test_trace_rows_must_be_contiguous_and_complete(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "trace.csv"
            valid = [1] + [0] * len(smoke.OBSERVATIONS)
            for values in ([2] + valid[1:], [1, -1] + valid[2:], valid[:-1]):
                path.write_text(",".join(map(str, values)) + "\n", encoding="ascii")
                with self.subTest(values=values[:2]), self.assertRaises(ValueError):
                    smoke.read_trace(path)
            path.write_text(",".join(map(str, valid)) + "\n", encoding="ascii")
            self.assertEqual(1, smoke.read_trace(path)[0]["frame"])

    def test_lua_contract_names_every_observed_cell(self):
        ram = {name: 0xFF0000 + 2 * index for index, (name, _width) in enumerate(smoke.OBSERVATIONS)}
        text = smoke.lua_contract(ram, self.config)
        self.assertTrue(text.startswith("return {ram={GameModeIndex=16711680,"))
        self.assertEqual(len(smoke.OBSERVATIONS), text.count("{1671"))


if __name__ == "__main__":
    unittest.main()
