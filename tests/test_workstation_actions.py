"""Mandatory withdrawn-Tk action boundaries; not game/render/audio fidelity."""

from __future__ import annotations

from contextlib import ExitStack
from copy import deepcopy
import json
import os
from pathlib import Path
import unittest
from unittest import mock

from workstation_fixtures import Fixture, MODULES, ROOT


class WorkstationActions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        from tk_test_lifetime import tk_main_thread_lifetime

        cls.enterClassContext(tk_main_thread_lifetime())
        # The dedicated gate (and this Windows host) must run real Tk.
        # Ordinary headless test discovery may skip only on other hosts.
        try:
            import tkinter as tk
            from tkinter import ttk

            probe = tk.Tk()
            probe.withdraw()
            probe.destroy()
        except Exception as error:
            if os.name == "nt" or os.environ.get("WORKSTATION_REQUIRE_GUI") == "1":
                raise AssertionError("mandatory workstation Tk is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable") from error
        cls.tk, cls.ttk = tk, ttk
        manifest = json.loads((ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8"))
        expected_actions = {"save", "reload", "build", "dirty-close"}
        for studio in manifest["studios"]:
            actions = set(studio["workstation_actions"])
            required = expected_actions | (
                {"plain-stage-route-edit", "raw-map-edit", "bounded-map-preview"} if studio["id"] == "level" else set()
            )
            if actions != required or len(actions) != len(studio["workstation_actions"]):
                raise AssertionError("declared action inventory changed; extend the real Tk matrix: " + studio["id"])
        cls.parent = ROOT / "build/content/workstation-smoke"
        cls.parent.mkdir(parents=True, exist_ok=True)

    def fixture(self, studio, profile):
        return Fixture(studio, profile, self.tk, self.ttk, self.parent)

    def assert_saved(self, fixture, expected):
        actual = fixture.disk()
        for identifier, document in expected.items():
            self.assertEqual(document, actual[identifier], identifier)
            self.assertEqual(fixture.profile, actual[identifier]["profile"])
            self.assertTrue(fixture.paths[identifier].resolve().is_relative_to(fixture.project))

    def check_save_reload(self, studio, profile):
        with self.fixture(studio, profile) as f:
            f.edit()
            self.assertTrue(f.dirty())
            expected = deepcopy(f.documents())
            paths = dict(f.paths)
            f.invoke("Save")
            self.assertFalse(f.dirty())
            self.assert_saved(f, expected)
            f.edit()
            self.assertNotEqual(expected, f.documents())
            f.messages.askyesno.return_value = True
            f.invoke("Reload")
            self.assertEqual(expected, f.documents())
            self.assertFalse(f.dirty())
            self.assertEqual(paths, f.paths)
            self.assertEqual((f.project, profile), (f.window.project, f.window.profile))
            f.messages.showerror.assert_not_called()
            f.callback_errors.assert_not_called()
            self.assertTrue(f.validators)
            self.assertTrue(any(item.called for item in f.validators))

    def check_cancel_reload_close(self, studio, profile):
        with self.fixture(studio, profile) as f:
            disk = f.disk()
            f.edit()
            expected = deepcopy(f.documents())
            selected = f.selection()
            f.messages.askyesno.return_value = False
            f.invoke("Reload")
            self.assertEqual(expected, f.documents())
            self.assertEqual(disk, f.disk())
            self.assertTrue(f.dirty())
            self.assertEqual(selected, f.selection())
            f.messages.askyesnocancel.return_value = None
            f.close_callback()
            self.assertTrue(f.window.window.winfo_exists())
            self.assertTrue(f.dirty())
            self.assertEqual(expected, f.documents())
            self.assertEqual(selected, f.selection())
            f.callback_errors.assert_not_called()

    def check_failed_save_blocks_build(self, studio, profile):
        with self.fixture(studio, profile) as f:
            disk = f.disk()
            f.edit()
            expected = deepcopy(f.documents())
            selected = f.selection()
            for phase in ("source", "write"):
                with self.subTest(phase=phase), ExitStack() as faults:
                    f.failure = OSError("fixture source temporarily unavailable") if phase == "source" else None
                    if phase == "write":
                        writer = f.fail_writer(faults)
                    f.messages.showerror.reset_mock()
                    f.invoke("Save")
                    self.assertTrue(f.dirty())
                    self.assertEqual(expected, f.documents())
                    self.assertEqual(selected, f.selection())
                    self.assertEqual(disk, f.disk())
                    f.messages.showerror.assert_called_once()
                    if phase == "write":
                        writer.assert_called_once()
                    with mock.patch.object(f.module.subprocess, "run") as process:
                        f.invoke("Build ROM")
                        process.assert_not_called()
                    self.assertTrue(f.dirty())
                    self.assertEqual(disk, f.disk())
                    f.callback_errors.assert_not_called()

    def check_build_boundary(self, studio, profile):
        with self.fixture(studio, profile) as f:
            f.edit()
            expected = deepcopy(f.documents())
            with mock.patch.object(
                f.module.subprocess, "run", return_value=mock.Mock(returncode=0, stdout="built", stderr="")
            ) as process:
                f.invoke("Build ROM")
                if studio in ("level", "graphics"):
                    process.assert_called_once()
                    self.assertFalse(f.dirty())
                    self.assert_saved(f, expected)
                else:
                    process.assert_not_called()
                    self.assertTrue(f.dirty())
                    f.messages.showerror.assert_called_once()
                    f.messages.showerror.reset_mock()
                    f.invoke("Save")
                    f.invoke("Build ROM")
                    process.assert_called_once()
                command = process.call_args.args[0]
                self.assertEqual(["make", "--no-print-directory", "build-content"], command[:3])
                self.assertIn("CONTENT_PROFILE=" + profile, command)
                self.assertEqual(f.project, process.call_args.kwargs["cwd"])
                self.assertFalse(process.call_args.kwargs["check"])
            with mock.patch.object(
                f.module.subprocess,
                "run",
                return_value=mock.Mock(returncode=3, stdout="", stderr="fixture compiler failed"),
            ):
                f.invoke("Build ROM")
            f.messages.showerror.assert_called_once()
            f.callback_errors.assert_not_called()

    def check_confirm_dirty_close(self, studio, profile):
        with self.fixture(studio, profile) as f:
            disk = f.disk()
            f.edit()
            expected = deepcopy(f.documents())
            f.messages.askyesnocancel.return_value = True
            f.messages.askyesno.return_value = True
            f.close_callback()
            self.assertFalse(f.alive())
            if studio in ("level", "graphics"):
                self.assert_saved(f, expected)
                self.assertFalse(f.dirty())
            else:
                # These three current UIs explicitly confirm discard, not save.
                self.assertEqual(disk, f.disk())
                self.assertTrue(f.dirty())
            f.messages.showerror.assert_not_called()
            f.callback_errors.assert_not_called()

    def check_level_route_map_selection(self, profile):
        with self.fixture("level", profile) as f:
            w = f.window
            w.route_box.set("Stage2ConfigRecord")
            w.route_button.invoke()
            self.assertEqual("Stage2ConfigRecord", w.studio.configuration.name)
            w.map_value_text.set("$01")
            f.invoke("Apply")
            self.assertEqual(1, w.map_state.value)
            self.assertTrue(w.map_state.dirty)
            f.invoke("Save")
            self.assertEqual("Stage2ConfigRecord", f.disk()["level_layouts"]["stages"][0]["configuration"])
            self.assertEqual(1, f.disk()["stage_maps"]["payloads"][0]["values"][0])
            w.chooser.current(1)
            w.chooser.event_generate("<<ComboboxSelected>>")
            w.window.update()
            self.assertEqual(1, w.studio.index)
            f.invoke("Refresh other maps")
            f.messages.showerror.assert_not_called()
            f.callback_errors.assert_not_called()

    def check_level_playtest_boundary(self, profile):
        with self.fixture("level", profile) as f:
            f.window.chooser.current(1)
            f.window.chooser.event_generate("<<ComboboxSelected>>")
            f.window.window.update()
            f.edit()
            expected = deepcopy(f.documents())

            def after_save(*_args, **_kwargs):
                self.assert_saved(f, expected)
                return mock.Mock(returncode=0, stdout="owned adapter launched", stderr="")

            with mock.patch.object(f.module.subprocess, "run", side_effect=after_save) as process:
                f.invoke("Playtest")
            command = process.call_args.args[0]
            self.assertEqual(
                ["make", "--no-print-directory", "playtest-level", "CONTENT_PROFILE=" + profile, "PLAYTEST_STAGE=2"],
                command,
            )
            self.assertEqual(f.project, process.call_args.kwargs["cwd"])
            self.assertFalse(f.dirty())
            self.assertFalse(any(button.cget("text") == "Stop" for button in f.buttons()))
            f.messages.showerror.assert_not_called()
            f.callback_errors.assert_not_called()

    def check_sound_play_stop_boundary(self, profile):
        with self.fixture("sound", profile) as f:
            f.edit()
            expected = deepcopy(f.documents())
            session = mock.Mock()
            session.ready = None
            session.process.poll.return_value = None
            session.stop.side_effect = lambda: setattr(session.process.poll, "return_value", 0)

            def after_save(*_a, **_k):
                self.assert_saved(f, expected)
                return mock.Mock(returncode=0)

            with (
                mock.patch.object(f.module.subprocess, "run", side_effect=after_save) as build,
                mock.patch.object(f.module, "launch_audition", return_value=session) as launch,
            ):
                f.invoke("Play")
            self.assertIn("CONTENT_PROFILE=" + profile, build.call_args.args[0])
            self.assertEqual(f.project, build.call_args.kwargs["cwd"])
            self.assertEqual((f.project, profile, 0x81), launch.call_args.args[:3])
            self.assertTrue(launch.call_args.args[3].is_relative_to(f.project))
            self.assertTrue(launch.call_args.args[4].is_relative_to(f.project))
            self.assertIs(session, f.window.audition)
            self.assertFalse(f.dirty())
            f.invoke("Stop")
            session.stop.assert_called_once_with()
            self.assertIsNone(f.window.audition)
            self.assertIsNone(f.window.audition_timer)
            self.assertEqual("disabled", str(f.window.stop_button.cget("state")))
            f.messages.showerror.assert_not_called()
            f.callback_errors.assert_not_called()

    def check_sound_pcm_export_cancellation(self, profile):
        with self.fixture("sound", profile) as f:
            f.window.artifact_box.current(f.window.state.artifact_ids.index("sound_pcm_samples"))
            f.window.artifact_box.event_generate("<<ComboboxSelected>>")
            f.window.window.update()
            self.assertEqual("sound_pcm_samples", f.window.state.artifact_id)
            disk = f.disk()
            f.invoke("Export PCM WAV")
            f.dialogs.askinteger.assert_called_once()
            f.files.asksaveasfilename.assert_not_called()
            f.dialogs.askinteger.return_value = 8000
            f.invoke("Export PCM WAV")
            f.files.asksaveasfilename.assert_called_once()
            self.assertEqual(disk, f.disk())
            self.assertFalse(list(f.project.rglob("*.wav")))
            f.messages.showerror.assert_not_called()
            f.callback_errors.assert_not_called()


def install_matrix():
    cases = ("save_reload", "cancel_reload_close", "failed_save_blocks_build", "build_boundary", "confirm_dirty_close")
    for studio in MODULES:
        for profile in ("jp", "eu"):
            for case in cases:

                def test(self, studio=studio, profile=profile, case=case):
                    getattr(self, "check_" + case)(studio, profile)

                setattr(WorkstationActions, "test_%s_%s_%s" % (studio, profile, case), test)
    for case in (
        "level_route_map_selection",
        "level_playtest_boundary",
        "sound_play_stop_boundary",
        "sound_pcm_export_cancellation",
    ):
        for profile in ("jp", "eu"):

            def test(self, case=case, profile=profile):
                getattr(self, "check_" + case)(profile)

            setattr(WorkstationActions, "test_%s_%s" % (case, profile), test)


install_matrix()

if __name__ == "__main__":
    os.environ["WORKSTATION_REQUIRE_GUI"] = "1"
    unittest.main()
