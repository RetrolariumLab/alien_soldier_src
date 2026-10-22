from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "scripts")]

from authoring.sound_studio_model import (  # noqa: E402
    BGM_REQUEST_IDS,
    SFX_REQUEST_IDS,
    bgm_label,
    decode_bgm_header,
    decode_instruction,
    decode_reachable_sequence,
    decode_sfx_header,
    export_inventory,
)


class SoundHeaderTests(unittest.TestCase):
    def test_bgm_reader_fields_and_aliases_are_explicit(self) -> None:
        data = bytes.fromhex("0014 0101 0304 0010 1234 0012 5678 090a f200 f200")
        record = decode_bgm_header("Example", data)
        self.assertEqual(0x14, record["instrument_offset"])
        self.assertEqual(0x10, record["channels"][0]["sequence_offset"])
        self.assertEqual(0x12, record["channels"][1]["sequence_offset"])
        self.assertEqual("psg", record["channels"][1]["family"])
        self.assertEqual("Sound_BGM_81", bgm_label(0x99))
        self.assertEqual("Sound_BGM_81", bgm_label(0x9E))
        self.assertEqual("Sound_BGM_9F", bgm_label(0x9F))

    def test_sfx_reader_uses_six_byte_channel_records(self) -> None:
        data = bytes.fromhex("0014 2302 8004 0010 1234 80c0 0012 5678 f200 f200")
        record = decode_sfx_header("Example", data)
        self.assertEqual(0x23, record["priority"])
        self.assertEqual(2, record["channel_count"])
        self.assertEqual(0x04, record["channels"][0]["runtime_channel_type"])
        self.assertEqual(0xC0, record["channels"][1]["runtime_channel_type"])

    def test_variable_and_extended_commands_follow_the_runtime_readers(self) -> None:
        self.assertEqual(2, decode_instruction("x", bytes.fromhex("e400"), 0)["size"])
        self.assertEqual(6, decode_instruction("x", bytes.fromhex("e40102030405"), 0)["size"])
        self.assertEqual(6, decode_instruction("x", bytes.fromhex("ff0001020304"), 0)["size"])
        with self.assertRaisesRegex(ValueError, "unknown extended"):
            decode_instruction("x", bytes.fromhex("ff05"), 0)

    def test_reachable_decoder_checks_branch_targets_and_boundaries(self) -> None:
        # F7 slot 0, count 2, displacement -4: target is the F7 itself;
        # fallthrough reaches F2.
        data = bytes.fromhex("f70002fffcf2")
        summary = decode_reachable_sequence("loop", data, [0], len(data))
        self.assertEqual(2, summary["instruction_count"])
        self.assertEqual({"repeat": 1, "stop": 1}, summary["command_counts"])
        with self.assertRaisesRegex(ValueError, "middle of instruction"):
            decode_reachable_sequence("bad", bytes.fromhex("e001f2"), [0, 1], 3)
        with self.assertRaisesRegex(ValueError, "enters its header"):
            decode_reachable_sequence("bad", bytes.fromhex("0000f6fffc"), [2], 5, minimum_offset=2)

    def test_out_of_range_relative_pointer_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "outside"):
            decode_sfx_header("Broken", bytes.fromhex("0010 0101 8004 ffff 0000"))


class ProjectSoundInventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_inventory(ROOT, "jp")

    def test_all_request_ranges_and_payloads_are_present(self) -> None:
        self.assertEqual(31, len(BGM_REQUEST_IDS))
        self.assertEqual(157, len(SFX_REQUEST_IDS))
        self.assertEqual(31, self.document["bgm_request_count"])
        self.assertEqual(25, self.document["bgm_payload_count"])
        self.assertEqual(157, self.document["sfx_request_count"])
        self.assertEqual(435, self.document["sequence_entry_count"])
        self.assertEqual(33062, self.document["sequence_instruction_count"])
        self.assertEqual(26878, self.document["sequence_event_count"])
        self.assertEqual(6184, self.document["sequence_command_count"])
        self.assertEqual(51045, self.document["sequence_reachable_byte_count"])
        self.assertEqual(22, len(self.document["sequence_command_kinds"]))

    def test_pcm_bank_boundaries_match_the_preservation_layout(self) -> None:
        self.assertEqual(9, self.document["pcm_bank_count"])
        self.assertEqual(0x41A5E, self.document["pcm_byte_count"])
        self.assertEqual(
            [0x8000] * 8 + [0x1A5E],
            [item["byte_count"] for item in self.document["pcm_banks"]],
        )

    def test_european_profile_has_the_same_sound_payload_contract(self) -> None:
        eu = export_inventory(ROOT, "eu")
        for field in (
            "bgm_request_count",
            "bgm_payload_count",
            "sfx_request_count",
            "pcm_bank_count",
            "pcm_byte_count",
        ):
            self.assertEqual(self.document[field], eu[field])
        self.assertEqual(self.document["bgm_payloads"], eu["bgm_payloads"])
        self.assertEqual(self.document["sfx_payloads"], eu["sfx_payloads"])


if __name__ == "__main__":
    unittest.main()
