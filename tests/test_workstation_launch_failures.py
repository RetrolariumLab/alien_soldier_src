"""Actual workstation callbacks report launcher OSError without Tk exceptions."""

import os
import unittest
from unittest import mock

import test_workstation_actions as actions


class LaunchErrors(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        actions.WorkstationActions.setUpClass()

    def check_launch_error(self, studio, profile, action):
        with actions.WorkstationActions().fixture(studio, profile) as f:
            before = f.disk()
            with mock.patch.object(
                f.module.subprocess, "run", side_effect=OSError("fixture make executable unavailable")
            ) as process:
                f.invoke(action)
            process.assert_called_once()
            f.callback_errors.assert_not_called()
            f.messages.showerror.assert_called_once()
            f.messages.showinfo.assert_not_called()
            self.assertIn("Cannot launch", f.messages.showerror.call_args.args[1])
            self.assertEqual(before, f.disk())
            self.assertFalse(f.dirty())
            self.assertTrue(f.alive())

    def test_level_build_and_playtest_launch_errors(self):
        for profile in ("jp", "eu"):
            for action in ("Build ROM", "Playtest"):
                with self.subTest(profile=profile, action=action):
                    self.check_launch_error("level", profile, action)

    def test_sound_build_launch_errors(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                self.check_launch_error("sound", profile, "Build ROM")


if __name__ == "__main__":
    os.environ["WORKSTATION_REQUIRE_GUI"] = "1"
    unittest.main()
