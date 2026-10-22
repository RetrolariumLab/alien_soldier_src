"""Semantic Sound Studio controls, source proofs and tiny hidden widgets."""

from __future__ import annotations

import os
import sys
import unittest
from copy import deepcopy
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import sound_semantic_model as semantic  # noqa: E402
from authoring.sound_studio_state import Workspace  # noqa: E402
from authoring.sound_studio import Window  # noqa: E402
from authoring.sound_instrument_model import decode_instrument, encode_instrument  # noqa: E402
from authoring.sound_studio_model import decode_bgm_header  # noqa: E402
from tests.test_sound_studio_widget import tiny_context  # noqa: E402


def shared_payload():
    return {
        "family": "bgm",
        "name": "fixture",
        "entry_offsets": [0, 4],
        "instructions": [
            {
                "offset": 0,
                "size": 3,
                "kind": "command",
                "opcode": 0xF8,
                "name": "call",
                "flow": "call",
                "target": 10,
                "data": [0xF8, 0, 8],
            },
            {"offset": 3, "size": 1, "kind": "command", "opcode": 0xF2, "name": "stop", "flow": "stop", "data": [0xF2]},
            {
                "offset": 4,
                "size": 3,
                "kind": "command",
                "opcode": 0xF8,
                "name": "call",
                "flow": "call",
                "target": 10,
                "data": [0xF8, 0, 4],
            },
            {"offset": 7, "size": 1, "kind": "command", "opcode": 0xF2, "name": "stop", "flow": "stop", "data": [0xF2]},
            {"offset": 10, "size": 2, "kind": "note", "data": [0x81, 5]},
            {
                "offset": 12,
                "size": 1,
                "kind": "command",
                "opcode": 0xF9,
                "name": "return",
                "flow": "return",
                "data": [0xF9],
            },
        ],
    }


class OwnershipTests(unittest.TestCase):
    def test_shared_subroutine_retains_dac_and_fm_owners_without_choosing_one(self):
        channels = (semantic.Channel(0, "dac", 0, 6), semantic.Channel(1, "fm", 4, 0))
        payload = shared_payload()
        owners = semantic.channel_owners(payload, channels)
        self.assertEqual(channels, owners[10])
        self.assertEqual((channels[0],), owners[3])
        self.assertEqual((channels[1],), owners[7])
        description = semantic.describe_event(payload["instructions"][4], owners[10])
        self.assertIn("DAC sample descriptor ID $81", description)
        self.assertIn("FM pitch ordinal 1", description)
        self.assertNotIn("C4", description)
        control = semantic.event_controls(payload["instructions"][4], 0, owners[10], {0x81, 0x82})[0]
        self.assertEqual(0x82, control.replace(0x81, 0x82))
        self.assertEqual(0x80, control.replace(0x81, 0x80))
        with self.assertRaises(ValueError):
            control.replace(0x81, 0x83)

    def test_loops_and_duplicate_roots_are_bounded_and_all_owners_remain_visible(self):
        payload = {
            "instructions": [
                {"offset": 10, "size": 3, "kind": "command", "flow": "jump", "target": 10, "data": [0xF6, 0xFF, 0xFE]}
            ]
        }
        channels = (semantic.Channel(0, "fm", 10, 0), semantic.Channel(1, "psg", 10, 0x80))
        self.assertEqual({10: channels}, semantic.channel_owners(payload, channels))
        payload["instructions"][0]["target"] = 11
        with self.assertRaisesRegex(ValueError, "absent instruction"):
            semantic.channel_owners(payload, channels)

    def test_source_header_distinguishes_dac_slot_from_regular_fm_type_six(self):
        # Six ordinary FM channels follow the leading dedicated DAC slot.
        header_size = 6 + 7 * 4
        raw = (
            (header_size + 3).to_bytes(2, "big")
            + bytes((7, 0, 1, 0))
            + (header_size.to_bytes(2, "big") + bytes(2)) * 7
            + bytes((0x81, 1, 0xF2))
        )
        payload = {"name": "fixture", "family": "bgm", "entry_offsets": [header_size] * 7}
        channels = semantic.source_channels(payload, raw)
        self.assertEqual("dac", channels[0].family)
        self.assertEqual(("fm", 6), (channels[-1].family, channels[-1].runtime_type))
        payload["entry_offsets"][0] += 1
        with self.assertRaisesRegex(ValueError, "roots differ"):
            semantic.source_channels(payload, raw)

    def test_note_and_duration_roles_do_not_infer_rate_or_channel(self):
        note = {"offset": 4, "size": 2, "kind": "note", "data": [0x80, 5]}
        self.assertEqual((), semantic.event_controls(note, 0, ()))
        duration = semantic.event_controls(note, 1, ())[0]
        self.assertEqual((0, 127), (duration.minimum, duration.maximum))
        self.assertIn("rest $80; duration 5 encoded units", semantic.describe_event(note, ()))
        psg = (semantic.Channel(0, "psg", 4, 0x80),)
        note["data"][0] = 0x81
        self.assertIn("PSG period-table index 0", semantic.describe_event(note, psg))
        self.assertEqual((), semantic.event_controls(note, 0, (semantic.Channel(0, "dac", 4, 6),)))


class FMParameterTests(unittest.TestCase):
    def test_every_subfield_preserves_all_other_raw_bits(self):
        for key in semantic.FM_PARAMETERS:
            for control in semantic.fm_controls(key):
                for raw in range(256):
                    for value in (control.minimum, control.maximum):
                        with self.subTest(key=key, control=control.name, raw=raw, value=value):
                            edited = control.replace(raw, value)
                            self.assertEqual(raw & ~control.mask, edited & ~control.mask)
                            self.assertEqual(value, control.read(edited))
                for value in (True, 1.0, -1, control.maximum + 1):
                    with self.assertRaises(ValueError):
                        control.replace(0xFF, value)

    def test_known_masks_and_register_order_are_explicit(self):
        self.assertEqual((0x07, 0x38), tuple(item.mask for item in semantic.fm_controls("algorithm_feedback")))
        self.assertEqual((0xC0, 0x1F), tuple(item.mask for item in semantic.fm_controls("rate_scale_attack")))
        self.assertEqual((0, 8, 4, 12), semantic.OPERATOR_REGISTER_OFFSETS)
        instrument = decode_instrument(0, bytes(range(25)))
        state = Workspace({"sound_instruments": {"payloads": [{"name": "fixture", "instruments": [instrument]}]}})
        state.select_value(2)
        description, controls = state.semantic_context()
        self.assertIn("relative YM2612 register $38", description)
        state.set_semantic(controls[0], 7)
        self.assertEqual(25, len(encode_instrument(instrument)))
        self.assertEqual(0x72, instrument["detune_multiplier"][1])

    def test_full_validator_failure_restores_raw_byte_and_existing_dirty_flags(self):
        record = decode_instrument(0, bytes([0xC0]) * 25)
        state = Workspace({"sound_instruments": {"payloads": [{"name": "fixture", "instruments": [record]}]}})
        before = deepcopy(state.documents)
        state.dirty.add("sound_sequences")
        control = state.semantic_context()[1][0]
        validate = mock.Mock(side_effect=ValueError("fixture rejected parameter"))
        with self.assertRaisesRegex(ValueError, "fixture rejected"):
            state.set_semantic(control, 7, validate)
        self.assertEqual(before, state.documents)
        self.assertEqual({"sound_sequences"}, state.dirty)
        with self.assertRaisesRegex(ValueError, "does not belong"):
            state.set_semantic(semantic.Control("fake", "fake", 0xFF, 0, 0, 255), 0)

    def test_dac_selection_uses_semantic_and_complete_document_guards(self):
        payload = shared_payload()
        state = Workspace({"sound_sequences": {"payloads": [payload]}})
        owners = (semantic.Channel(0, "dac", 0, 6), semantic.Channel(1, "fm", 4, 0))
        control = state.semantic_context(owners, {0x81, 0x82})[1][0]
        state.set_semantic(control, 0x82, owners=owners, sample_ids={0x81, 0x82})
        self.assertEqual([0x82, 5], payload["instructions"][4]["data"])
        with self.assertRaises(ValueError):
            state.set_semantic(control, 0xDF, owners=owners, sample_ids={0x81, 0x82})
        state.select_value(1)
        duration = state.semantic_context(owners, {0x81, 0x82})[1][0]
        state.set_semantic(duration, 127, owners=owners, sample_ids={0x81, 0x82})
        self.assertEqual([0x82, 127], payload["instructions"][4]["data"])


class SourceProofTests(unittest.TestCase):
    def test_reader_anchors_and_operator_register_order_match_the_controls(self):
        source = (ROOT / "src/sound/sequence_dispatch_and_instrument_commands.s").read_text(encoding="utf-8")
        self.assertIn("move.w  #$19,d1", source)
        self.assertIn("move.b  #$B0,d0", source)
        self.assertIn("andi.w  #7,d4", source)
        self.assertIn("$30, $38, $34, $3C, $50, $58, $54, $5C", source)
        self.assertIn("$40, $48, $44, $4C", source)
        core = (ROOT / "src/sound/driver_core.s").read_text(encoding="utf-8")
        self.assertIn("subi.b  #$80,d5", core)
        self.assertIn("subi.b  #$81,d0", core)
        self.assertIn("divu.w  #$C,d5", core)
        psg = (ROOT / "src/sound/psg_playback_and_envelopes.s").read_text(encoding="utf-8")
        self.assertIn("subi.b  #$81,d5", psg)
        self.assertIn("Sound_PSGNotePeriodTable(pc),a0", psg)


class SoundSemanticWidgetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
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
                raise AssertionError("Sound semantic GUI is unavailable") from error
            raise unittest.SkipTest("Tk display unavailable: " + str(error))

    def test_hidden_semantic_controls_apply_fm_bits_duration_and_restore_failed_changes(self):
        actual_tk = self.tk.Tk

        def hidden_tk():
            root = actual_tk()
            root.withdraw()
            return root

        for profile in ("jp", "eu"):
            context = tiny_context()
            messages = mock.Mock()
            with mock.patch.object(self.tk, "Tk", new=hidden_tk):
                window = Window(ROOT, profile, context, self.tk, self.ttk, messages, mock.Mock(), mock.Mock())
            try:
                window.select_artifact(window.state.artifact_ids.index("sound_instruments"))
                self.assertIn("relative YM2612 register $B0", window.semantic_description.cget("text"))
                window.semantic_box.current(1)  # Feedback, not algorithm.
                window.show_semantic_value()
                window.semantic_text.set("7")
                window.semantic_button.invoke()
                self.assertEqual(0x38, window.state.value)
                self.assertEqual(1, window.semantic_box.current())
                context["sound_instruments"]["validate"].assert_called_once()
                window.semantic_text.set("8")
                window.semantic_button.invoke()
                self.assertEqual(0x38, window.state.value)
                window.select_artifact(window.state.artifact_ids.index("sound_sequences"))
                self.assertIn("duration", window.semantic_box["values"][0])
                window.semantic_text.set("5")
                window.semantic_button.invoke()
                self.assertEqual(5, window.state.value)
                context["sound_sequences"]["validate"].side_effect = ValueError("fixture rejection")
                dirty = set(window.state.dirty)
                window.semantic_text.set("6")
                window.semantic_button.invoke()
                self.assertEqual(5, window.state.value)
                self.assertEqual(dirty, window.state.dirty)
                window.select_artifact(window.state.artifact_ids.index("sound_pcm_samples"))
                self.assertEqual("disabled", str(window.semantic_button["state"]))
            finally:
                window.window.destroy()


if __name__ == "__main__":
    os.environ["SOUND_WIDGET_REQUIRE_GUI"] = "1"
    unittest.main()
