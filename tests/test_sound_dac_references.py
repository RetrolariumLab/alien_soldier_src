"""Tiny BGM/SFX fixtures prove DAC notes cannot leave the descriptor table."""

from __future__ import annotations

import copy
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_pcm_model import music_sample_ids  # noqa: E402
from authoring.sound_sequence_model import (  # noqa: E402
    FORMAT,
    apply_document,
    document_errors,
)
from authoring.sound_studio_model import decode_bgm_header, decode_sfx_header  # noqa: E402


NAME = "Sound_DACFixture"
TABLE = "Sound_PCMSampleDescriptors"
DESCRIPTOR = " dc.w (Sound_PCMBank1 >> $8), $80, $500, 0"


def fixture(body: bytes, family: str, profile: str) -> dict:
    decoder = decode_bgm_header if family == "bgm" else decode_sfx_header
    decoded = decoder(NAME, body)
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
                "family": family,
                "path": "fixture.bin",
                "storage": "binary",
                "capacity": len(body),
                "header_byte_count": decoded["header_byte_count"],
                "instrument_offset": decoded["instrument_offset"],
                "entry_offsets": sequence["entry_offsets"],
                "instruction_count": sequence["instruction_count"],
                "reachable_byte_count": sequence["reachable_byte_count"],
                "instructions": [
                    {
                        **instruction,
                        "data": list(body[instruction["offset"] : instruction["offset"] + instruction["size"]]),
                    }
                    for instruction in sequence["instructions"]
                ],
            }
        ],
    }


class SoundDACReferenceTests(unittest.TestCase):
    def setup_document(self, body: bytes, family: str = "bgm", profile: str = "jp") -> dict:
        baseline = fixture(body, family, profile)
        module = "authoring.sound_sequence_model."
        for name, result in (
            ("export_document", baseline),
            ("labelled_blocks", ({NAME: body}, {TABLE: (DESCRIPTOR,) * 22})),
            ("envelope_selector_limits", {"pitch": 8, "psg_volume": 10}),
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
        return copy.deepcopy(baseline)

    def set_note(self, document: dict, offset: int, value: int) -> None:
        instruction = next(item for item in document["payloads"][0]["instructions"] if item["offset"] == offset)
        self.assertEqual("note", instruction["kind"])
        instruction["data"][0] = value

    def test_dac_accepts_rest_and_table_end_but_rejects_next_id(self) -> None:
        body = bytes.fromhex("000D 0100 0101 000A 0000 8101F2")
        document = self.setup_document(body)
        for value in (0x80, 0x81, 0x96):
            with self.subTest(value=value):
                self.set_note(document, 10, value)
                self.assertEqual([], document_errors(document, ROOT, "jp"))
        for value in (0x97, 0xDF):
            with self.subTest(value=value):
                self.set_note(document, 10, value)
                errors = document_errors(document, ROOT, "jp")
                self.assertTrue(any("DAC instruction $000A" in error for error in errors))

    def test_shared_dac_fm_subroutine_keeps_dac_sample_bounds(self) -> None:
        # Header: DAC -> $0E, FM1 -> $12. Both call the note at $16 then stop.
        body = bytes.fromhex("0019 0200 0101 000E 0000 0012 0000 F80006F2 F80002F2 8101F9")
        document = self.setup_document(body)
        self.set_note(document, 22, 0xDF)
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("DAC instruction $0016" in error for error in errors))

    def test_regular_fm_note_range_is_not_narrowed(self) -> None:
        body = bytes.fromhex("0012 0200 0101 000E 0000 000F 0000 F2 8101F2")
        document = self.setup_document(body)
        self.set_note(document, 15, 0xDF)
        self.assertEqual([], document_errors(document, ROOT, "jp"))

    def test_psg_only_bgm_has_no_dac_entry(self) -> None:
        body = bytes.fromhex("000F 0001 0101 000C 0000 0000 8101F2")
        document = self.setup_document(body)
        # Above every DAC descriptor ID, but inside the actual PSG table.
        self.set_note(document, 12, 0xC6)
        self.assertEqual([], document_errors(document, ROOT, "jp"))

    def test_sfx_channel_type_six_is_not_a_dac_slot(self) -> None:
        body = bytes.fromhex("000D 8001 8006 000A 0000 8101F2")
        document = self.setup_document(body, "sfx")
        self.set_note(document, 10, 0xDF)
        self.assertEqual([], document_errors(document, ROOT, "jp"))

    def test_eu_rejects_invalid_note_before_staged_write(self) -> None:
        body = bytes.fromhex("000D 0100 0101 000A 0000 8101F2")
        document = self.setup_document(body, profile="eu")
        self.set_note(document, 10, 0xDF)
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            path = staged / "fixture.bin"
            path.write_bytes(body)
            with self.assertRaisesRegex(ValueError, "selects sample .DF outside"):
                apply_document(document, staged, "eu")
            self.assertEqual(body, path.read_bytes())


class MusicSampleTableTests(unittest.TestCase):
    def test_ids_follow_four_word_source_descriptors(self) -> None:
        self.assertEqual(
            frozenset((0x81, 0x82)),
            music_sample_ids(
                {
                    TABLE: (DESCRIPTOR, DESCRIPTOR),
                }
            ),
        )

    def test_partial_descriptor_table_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "four-word descriptors"):
            music_sample_ids({TABLE: (" dc.w $80, $500, 0",)})


if __name__ == "__main__":
    unittest.main()
