"""Real Tk wiring smoke with tiny Sound Studio documents and no audio output."""

from __future__ import annotations

import os
import sys
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_studio import Window  # noqa: E402
from authoring import sound_studio  # noqa: E402


def tiny_context() -> dict:
    """One reader-shaped editable field per Sound Studio artifact."""
    registers = {
        "algorithm_feedback": 0,
        "detune_multiplier": [0] * 4,
        "rate_scale_attack": [0] * 4,
        "am_decay": [0] * 4,
        "sustain_rate": [0] * 4,
        "sustain_level_release": [0] * 4,
        "total_level": [0] * 4,
        "index": 0,
    }
    documents = {
        "sound_sequences": {"payloads": [{
            "family": "BGM", "name": "fixture",
            "instructions": [{"kind": "duration", "data": [1]}],
        }]},
        "sound_instruments": {"payloads": [{
            "name": "fixture", "instruments": [registers],
        }]},
        "sound_envelopes": {"families": [{
            "id": "pitch", "blocks": [{
                "name": "fixture", "values": [{"value": 0}],
            }],
        }]},
        "sound_pcm_samples": {"banks": [{
            "name": "fixture", "samples": [{
                "index": 0, "byte_count": 2, "data": "0000",
            }],
        }]},
    }
    return {
        identifier: {
            "document": document, "validate": mock.Mock(),
            "write": mock.Mock(), "path": ROOT / "build/unused-widget-fixture.json",
        }
        for identifier, document in documents.items()
    }


class SoundStudioWidgetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        from tk_test_lifetime import tk_main_thread_lifetime
        cls.enterClassContext(tk_main_thread_lifetime())
        try:
            import tkinter as tk
            from tkinter import ttk

            probe = tk.Tk()
            probe.withdraw()
            probe.destroy()
            cls.tk, cls.ttk = tk, ttk
        except Exception as error:
            if os.environ.get("SOUND_WIDGET_REQUIRE_GUI") == "1":
                raise AssertionError("Sound Studio GUI is unavailable") from error
            raise unittest.SkipTest("Tk display is unavailable") from error

    def test_both_profiles_wire_four_formats_and_cancel_pcm_export(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                context = tiny_context()
                messages, dialogs, files = mock.Mock(), mock.Mock(), mock.Mock()
                messages.askyesno.return_value = True
                dialogs.askinteger.return_value = None
                actual_tk = self.tk.Tk

                def hidden_tk():
                    root = actual_tk()
                    root.withdraw()
                    return root

                with mock.patch.object(self.tk, "Tk", new=hidden_tk):
                    window = Window(
                        ROOT, profile, context, self.tk, self.ttk,
                        messages, dialogs, files)
                try:
                    self.assertEqual(4, len(window.state.artifact_ids))
                    for identifier in window.state.artifact_ids:
                        index = window.state.artifact_ids.index(identifier)
                        window.artifact_box.current(index)
                        window.artifact_box.event_generate("<<ComboboxSelected>>")
                        window.window.update()
                        self.assertEqual(identifier, window.state.artifact_id)
                        self.assertTrue(window.field_box["values"])
                        self.assertTrue(window.sequence.cget("text"))
                        if identifier == "sound_pcm_samples":
                            self.assertEqual("normal", str(window.preview_button.cget("state")))
                            self.assertIn("Decoded DPCM levels", window.decoded.cget("text"))
                            self.assertIn("80 at +0, 80 at +191 Z80 T-states",
                                          window.decoded.cget("text"))
                            window.step_value(1)
                            self.assertEqual(1, window.state.value_index)
                            self.assertIn("80 at +387, 80 at +578 Z80 T-states",
                                          window.decoded.cget("text"))
                        else:
                            self.assertEqual("disabled", str(window.preview_button.cget("state")))

                    window.select_artifact(
                        window.state.artifact_ids.index("sound_pcm_samples"))
                    window.export_pcm_preview()
                    dialogs.askinteger.assert_called_once()
                    files.asksaveasfilename.assert_not_called()

                    window.select_artifact(
                        window.state.artifact_ids.index("sound_envelopes"))
                    window.value_text.set("128")
                    window.apply_value()
                    self.assertEqual(0, window.state.value)
                    messages.showerror.assert_called_once()
                    messages.showerror.reset_mock()
                    window.value_text.set("-1")
                    window.apply_value()
                    self.assertEqual(-1, window.state.value)
                    self.assertEqual({"sound_envelopes"}, window.state.dirty)
                    context["sound_envelopes"]["validate"].assert_called()

                    with mock.patch.object(window.window, "destroy") as destroy:
                        messages.askyesno.return_value = False
                        window.close()
                        destroy.assert_not_called()
                        messages.askyesno.return_value = True
                        window.close()
                        destroy.assert_called_once_with()
                    messages.showerror.assert_not_called()
                    for record in context.values():
                        record["write"].assert_not_called()
                finally:
                    window.window.destroy()

    def test_audition_saves_before_build_and_stops_its_owned_session(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                context = tiny_context()
                context["sound_sequences"]["document"]["payloads"][0]["name"] = "Sound_BGM_81"
                context["sound_sequences"]["document"]["payloads"][0]["family"] = "bgm"
                messages, dialogs, files = mock.Mock(), mock.Mock(), mock.Mock()
                messages.askyesno.return_value = True
                actual_tk = self.tk.Tk

                def hidden_tk():
                    root = actual_tk()
                    root.withdraw()
                    return root

                with mock.patch.object(self.tk, "Tk", new=hidden_tk):
                    window = Window(ROOT, profile, context, self.tk, self.ttk,
                                    messages, dialogs, files)
                try:
                    self.assertEqual("Sound_BGM_81", window.audition_choice.get())
                    self.assertEqual("normal", str(window.play_button.cget("state")))
                    window.state.set_value(2)
                    calls = []
                    context["sound_sequences"]["write"].side_effect = lambda *_: calls.append("save")
                    session = mock.Mock()
                    session.ready = None
                    session.poll.return_value = True
                    session.process.poll.return_value = None
                    session.stop.side_effect = lambda: setattr(session.process.poll, "return_value", 0)
                    with (mock.patch.object(sound_studio.subprocess, "run",
                                            side_effect=lambda *_args, **_kwargs:
                                            (calls.append("build") or mock.Mock(returncode=0))) as build,
                          mock.patch.object(sound_studio, "launch_audition",
                                            side_effect=lambda *_args, **_kwargs:
                                            (calls.append("launch") or session)) as launch,
                          mock.patch.object(sound_studio.tempfile, "mkdtemp",
                                            return_value=str(ROOT / "build/content" / profile / "audition/mock-build")),
                          mock.patch.object(Path, "mkdir")):
                        window.play_button.invoke()
                    self.assertEqual(["save", "build", "launch"], calls)
                    self.assertFalse(window.state.dirty)
                    command = build.call_args.args[0]
                    self.assertIn("CONTENT_PROFILE=" + profile, command)
                    self.assertTrue(any(item.startswith("CONTENT_LISTING=") for item in command))
                    self.assertIn("GENS_DIR=" + str(window.gens.resolve().parent.parent), command)
                    self.assertEqual((ROOT, profile, 0x81), launch.call_args.args[:3])
                    self.assertEqual("normal", str(window.stop_button.cget("state")))
                    window.window.after_cancel(window.audition_timer)
                    window.audition_timer = None
                    window._poll_audition()
                    window.stop_button.invoke()
                    session.stop.assert_called_once_with()
                    self.assertEqual(0, session.process.poll())
                    self.assertIsNone(window.audition)
                    self.assertIsNone(window.audition_timer)
                    self.assertEqual("disabled", str(window.stop_button.cget("state")))
                    messages.showerror.assert_not_called()
                finally:
                    window.stop_audition()
                    window.window.destroy()

    def test_save_failure_blocks_audition_build_and_preserves_dirty_edits(self) -> None:
        context = tiny_context()
        context["sound_sequences"]["document"]["payloads"][0]["name"] = "Sound_BGM_81"
        messages, dialogs, files = mock.Mock(), mock.Mock(), mock.Mock()
        actual_tk = self.tk.Tk

        def hidden_tk():
            root = actual_tk()
            root.withdraw()
            return root

        with mock.patch.object(self.tk, "Tk", new=hidden_tk):
            window = Window(ROOT, "jp", context, self.tk, self.ttk, messages, dialogs, files)
        try:
            window.state.set_value(2)
            context["sound_sequences"]["write"].side_effect = OSError("cannot save")
            with (mock.patch.object(sound_studio.subprocess, "run") as build,
                  mock.patch.object(sound_studio, "launch_audition") as launch):
                window.play_button.invoke()
                build.assert_not_called()
                launch.assert_not_called()
            self.assertEqual({"sound_sequences"}, window.state.dirty)
            self.assertEqual(2, window.state.value)
            messages.showerror.assert_called_once()
        finally:
            window.window.destroy()


if __name__ == "__main__":
    os.environ["SOUND_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
