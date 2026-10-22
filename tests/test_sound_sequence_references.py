"""Bounded sequence-reference regressions using one 18-byte synthetic payload."""

from __future__ import annotations

import copy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_envelope_model import envelope_selector_limits  # noqa: E402
from authoring.sound_sequence_model import (  # noqa: E402
    FORMAT,
    apply_document,
    document_errors,
    validate_document,
)
from authoring.sound_studio import Window  # noqa: E402
from authoring.sound_studio_model import decode_sfx_header  # noqa: E402
from authoring.sound_studio_state import Workspace  # noqa: E402


NAME = "Sound_SFX_EnvelopeFixture"
BODY = bytes.fromhex("0012 8001 80A0 000A 0000 F10102 F403 F504 F2")


def fixture(profile: str = "jp") -> dict:
    decoded = decode_sfx_header(NAME, BODY)
    sequence = decoded["sequence"]
    return {
        "schema_version": 1,
        "profile": profile,
        "format": FORMAT,
        "payload_count": 1,
        "instruction_count": sequence["instruction_count"],
        "reachable_byte_count": sequence["reachable_byte_count"],
        "payloads": [
            {
                "name": NAME,
                "family": "sfx",
                "path": "fixture.bin",
                "storage": "binary",
                "capacity": len(BODY),
                "header_byte_count": decoded["header_byte_count"],
                "instrument_offset": decoded["instrument_offset"],
                "entry_offsets": sequence["entry_offsets"],
                "instruction_count": sequence["instruction_count"],
                "reachable_byte_count": sequence["reachable_byte_count"],
                "instructions": [
                    {
                        **instruction,
                        "data": list(BODY[instruction["offset"] : instruction["offset"] + instruction["size"]]),
                    }
                    for instruction in sequence["instructions"]
                ],
            }
        ],
    }


class SoundSequenceReferenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.baseline = fixture()
        module = "authoring.sound_sequence_model."
        for name, result in (
            ("export_document", self.baseline),
            ("labelled_blocks", ({NAME: BODY}, {})),
            ("envelope_selector_limits", {"pitch": 8, "psg_volume": 10}),
            ("music_sample_ids", frozenset(range(0x81, 0x97))),
            (
                "period_contract",
                {
                    "table": "Sound_PSGNotePeriodTable",
                    "word_count": 70,
                    "table_sha256": "fixture-table",
                    "reader_sha256": "fixture-readers",
                },
            ),
        ):
            patcher = mock.patch(module + name, return_value=result)
            patcher.start()
            self.addCleanup(patcher.stop)

    def edited(self, opcode: int, operand: int, value: int) -> dict:
        document = copy.deepcopy(self.baseline)
        instruction = next(item for item in document["payloads"][0]["instructions"] if item.get("opcode") == opcode)
        instruction["data"][operand] = value
        return document

    def test_both_f1_operands_and_f4_mask_the_pitch_flag(self) -> None:
        for opcode, operand in ((0xF1, 1), (0xF1, 2), (0xF4, 1)):
            for value in (0, 8, 0x80, 0x88):
                with self.subTest(opcode=opcode, operand=operand, value=value):
                    validate_document(self.edited(opcode, operand, value), ROOT, "jp")
            for value in (9, 0x89, 0x7F, 0xFF):
                with self.subTest(opcode=opcode, operand=operand, value=value):
                    errors = document_errors(self.edited(opcode, operand, value), ROOT, "jp")
                    self.assertTrue(any("pitch envelope" in error for error in errors))
                    self.assertTrue(any("operand %d" % operand in error for error in errors))

    def test_psg_volume_does_not_mask_the_high_bit(self) -> None:
        for value in (0, 1, 10):
            validate_document(self.edited(0xF5, 1, value), ROOT, "jp")
        for value in (11, 0x80, 0x8A, 0xFF):
            with self.subTest(value=value):
                with self.assertRaisesRegex(ValueError, "psg_volume envelope"):
                    validate_document(self.edited(0xF5, 1, value), ROOT, "jp")

    def test_region_documents_reject_the_same_invalid_reference(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                self.baseline["profile"] = profile
                with self.assertRaisesRegex(ValueError, "pitch envelope 9"):
                    validate_document(self.edited(0xF4, 1, 9), ROOT, profile)

    def test_invalid_reference_fails_before_any_staged_write(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            path = staged / "fixture.bin"
            path.write_bytes(BODY)
            with self.assertRaisesRegex(ValueError, "psg_volume envelope"):
                apply_document(self.edited(0xF5, 1, 11), staged, "jp")
            self.assertEqual(BODY, path.read_bytes())

    def test_workstation_rolls_back_value_and_prior_dirty_state(self) -> None:
        document = copy.deepcopy(self.baseline)
        window = Window.__new__(Window)
        window.project, window.profile = ROOT, "jp"
        window.context = {
            "sound_sequences": {
                "document": document,
                "validate": validate_document,
            }
        }
        window.state = Workspace({"sound_sequences": document})
        selected = next(
            index for index, value in enumerate(window.state.field.values) if value.container.get("opcode") == 0xF4
        )
        window.state.select_value(selected)
        window.value_text = mock.Mock()
        window.value_text.get.return_value = "$89"
        window.messagebox, window.status = mock.Mock(), mock.Mock()
        window.show_value = mock.Mock()
        for dirty in (set(), {"sound_sequences"}):
            with self.subTest(dirty=dirty):
                window.state.dirty = dirty.copy()
                window.apply_value()
                self.assertEqual(3, window.state.value)
                self.assertEqual(dirty, window.state.dirty)
        self.assertEqual(2, window.messagebox.showerror.call_count)
        window.status.configure.assert_not_called()


class SoundEnvelopeTableLimitTests(unittest.TestCase):
    def test_limits_follow_symbol_pointer_counts(self) -> None:
        bodies = {
            "Sound_PitchEnvelopePointerTable": (" dc.l PitchA,PitchB ; ignored comment", " dc.l PitchC"),
            "Sound_PSGVolumeEnvelopePointerTable": (" dc.l VolumeA,VolumeB",),
        }
        with mock.patch("authoring.sound_envelope_model.labelled_blocks", return_value=({}, bodies)):
            self.assertEqual({"pitch": 3, "psg_volume": 2}, envelope_selector_limits(ROOT))

    def test_literal_table_cannot_supply_a_claimed_selector_limit(self) -> None:
        bodies = {
            "Sound_PitchEnvelopePointerTable": (" dc.l $00123456",),
            "Sound_PSGVolumeEnvelopePointerTable": (" dc.l VolumeA",),
        }
        with mock.patch("authoring.sound_envelope_model.labelled_blocks", return_value=({}, bodies)):
            with self.assertRaisesRegex(ValueError, "symbol-only pointer table"):
                envelope_selector_limits(ROOT)


if __name__ == "__main__":
    unittest.main()
