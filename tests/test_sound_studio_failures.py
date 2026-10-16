"""Headless Sound Studio failure paths: no Tk creation, builds or emulator."""

from __future__ import annotations

from pathlib import Path
import subprocess
import sys
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import sound_studio  # noqa: E402


def window():
    document = {"payloads": [{"family": "sfx", "name": "Sound_SFX_A5",
                              "instructions": [{"kind": "duration", "data": [1]}]}]}
    item = sound_studio.Window.__new__(sound_studio.Window)
    item.project, item.profile = ROOT, "jp"
    item.state = sound_studio.Workspace({"sound_sequences": document})
    item.context = {"sound_sequences": {"document": document, "validate": mock.Mock()}}
    item.value_text = mock.Mock()
    item.value_text.get.return_value = "2"
    item.messagebox, item.show_value = mock.Mock(), mock.Mock()
    item.status, item.stop_button, item.window = mock.Mock(), mock.Mock(), mock.Mock()
    item.audition, item.audition_timer = None, None
    return item


def session(*, live=False, error=None):
    item = mock.Mock()
    item.process.poll.return_value = None if live else 0
    item.stop.side_effect = error
    item.ready = None
    return item


class RawRollbackTests(unittest.TestCase):
    def test_all_expected_validation_failures_restore_value_and_all_dirty_flags(self):
        for error in (OSError("source unavailable"), RuntimeError("source reader failed"), ValueError("invalid event"),
                      TypeError("damaged source inventory"), KeyError("missing source label")):
            with self.subTest(error=error):
                item = window()
                item.state.dirty = {"sound_instruments", "sound_envelopes"}
                item.context["sound_sequences"]["validate"].side_effect = error
                item.apply_value()
                self.assertEqual(1, item.state.value)
                self.assertEqual({"sound_instruments", "sound_envelopes"}, item.state.dirty)
                item.messagebox.showerror.assert_called_once_with("Sound Studio", str(error))
                item.status.configure.assert_not_called()

    def test_success_preserves_other_dirty_flags_and_records_selected_artifact(self):
        item = window()
        item.state.dirty = {"sound_instruments"}
        item.apply_value()
        self.assertEqual(2, item.state.value)
        self.assertEqual({"sound_instruments", "sound_sequences"}, item.state.dirty)
        item.messagebox.showerror.assert_not_called()

    def test_keyboard_interrupt_and_system_exit_are_not_swallowed(self):
        for error in (KeyboardInterrupt(), SystemExit(2)):
            with self.subTest(error=error):
                item = window()
                item.context["sound_sequences"]["validate"].side_effect = error
                with self.assertRaises(type(error)):
                    item.apply_value()
                item.messagebox.showerror.assert_not_called()


class OwnedStopTests(unittest.TestCase):
    def test_normal_stop_cancels_timer_releases_owner_and_disables_button(self):
        item = window()
        item.audition, item.audition_timer = session(), "timer-owned"
        owned = item.audition
        self.assertIsNone(item.stop_audition())
        owned.stop.assert_called_once()
        item.window.after_cancel.assert_called_once_with("timer-owned")
        self.assertIsNone(item.audition)
        self.assertIsNone(item.audition_timer)
        item.stop_button.configure.assert_called_once_with(state="disabled")
        item.messagebox.showerror.assert_not_called()

    def test_reaped_validation_failure_warns_once_and_releases_stale_owner(self):
        item = window()
        error = RuntimeError("native identity changed")
        item.audition = session(error=error)
        self.assertIs(error, item.stop_audition())
        self.assertIsNone(item.audition)
        item.messagebox.showerror.assert_called_once_with("Sound Studio", str(error))
        item.stop_button.configure.assert_called_once_with(state="disabled")

    def test_live_or_unknown_process_is_never_discarded_after_stop_failure(self):
        for unknown in (False, True):
            with self.subTest(unknown=unknown):
                item = window()
                owned = session(live=True, error=OSError("termination denied"))
                if unknown:
                    owned.process.poll.side_effect = OSError("handle unreadable")
                item.audition = owned
                self.assertIsInstance(item.stop_audition(), OSError)
                self.assertIs(owned, item.audition)
                item.stop_button.configure.assert_called_once_with(state="normal")
                item.messagebox.showerror.assert_called_once()

    def test_stop_returning_success_with_live_process_is_refused(self):
        item = window()
        owned = session(live=True)
        item.audition = owned
        self.assertIsInstance(item.stop_audition(), RuntimeError)
        self.assertIs(owned, item.audition)

    def test_timeout_and_base_exceptions_do_not_hide_owner(self):
        item = window()
        owned = session(live=True, error=subprocess.TimeoutExpired("owned Gens", 5))
        item.audition = owned
        self.assertIsInstance(item.stop_audition(), subprocess.TimeoutExpired)
        self.assertIs(owned, item.audition)
        for error in (KeyboardInterrupt(), SystemExit(2)):
            owned.stop.side_effect = error
            with self.assertRaises(type(error)):
                item.stop_audition()
            self.assertIs(owned, item.audition)

    def test_close_after_reaped_validation_failure_warns_and_destroys(self):
        item = window()
        item.audition = session(error=RuntimeError("native identity changed"))
        item.close()
        self.assertIsNone(item.audition)
        item.messagebox.showerror.assert_called_once()
        item.window.destroy.assert_called_once()

    def test_close_with_live_child_does_not_destroy_its_owner_window(self):
        item = window()
        owned = session(live=True, error=OSError("termination denied"))
        item.audition = owned
        item.close()
        self.assertIs(owned, item.audition)
        item.window.destroy.assert_not_called()
        item.messagebox.showerror.assert_called_once()

    def test_poll_error_and_cleanup_error_use_one_combined_dialog(self):
        item = window()
        owned = session(error=RuntimeError("cleanup validation changed"))
        owned.poll.side_effect = RuntimeError("bad loader state")
        item.audition = owned
        item._poll_audition()
        self.assertIsNone(item.audition)
        item.messagebox.showerror.assert_called_once_with(
            "Sound Studio", "bad loader state\nStop also failed: cleanup validation changed")

    def test_poll_equal_error_does_not_duplicate_message_or_lose_live_owner(self):
        item = window()
        owned = session(live=True, error=RuntimeError("native identity changed"))
        owned.poll.side_effect = RuntimeError("native identity changed")
        item.audition = owned
        item._poll_audition()
        self.assertIs(owned, item.audition)
        item.messagebox.showerror.assert_called_once_with("Sound Studio", "native identity changed")

    def test_play_aborts_new_build_after_any_stop_error_even_if_reaped(self):
        item = window()
        item.audition_choice = mock.Mock()
        item.audition_choice.get.return_value = "Sound_SFX_A5"
        item.audition = session(error=RuntimeError("native identity changed"))
        with mock.patch.object(sound_studio.subprocess, "run") as build:
            item.play_audition()
            build.assert_not_called()
        self.assertIsNone(item.audition)
        item.messagebox.showerror.assert_called_once()

    def test_real_session_reaps_before_environment_error_reaches_gui(self):
        # Actual Session.stop, not a fictional finally-already-reaped contract.
        from authoring.sound_audition import Session
        process = mock.Mock()
        process.poll.side_effect = [None, 0]
        process.wait.return_value = 0
        owned = Session(process=process, contract={}, result=Path("unused.json"),
                        stop_file=Path("unused-stop.txt"), directory=ROOT)
        error = RuntimeError("native identity changed")
        item = window()
        item.audition = owned
        with (mock.patch("authoring.sound_audition.atomic_write_bytes"),
              mock.patch.object(owned, "validate_environment", side_effect=error) as validate):
            self.assertIs(error, item.stop_audition())
        process.wait.assert_called_once_with(timeout=1)
        validate.assert_called_once()
        self.assertIsNone(item.audition)


if __name__ == "__main__":
    unittest.main()
