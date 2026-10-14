from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_pcm_codec import (  # noqa: E402
    CODE_SIGNATURES,
    DAC_TIMING_SIGNATURES,
    DELTA_BYTES,
    check_project,
    codec_contract,
    decode_dpcm,
    encode_dpcm,
    ordinary_dac_event_offsets,
    ordinary_delay_t_states,
    load_tables,
    ordinary_delay_contract,
    ordinary_dac_timing_contract,
)
from authoring.sound_pcm_model import export_document  # noqa: E402


class SoundPCMCodecTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.high, cls.low = load_tables(ROOT)

    def test_driver_tables_prove_the_nibble_delta_contract(self) -> None:
        contract = codec_contract(ROOT)
        self.assertEqual(list(DELTA_BYTES), contract["delta_bytes"])
        self.assertEqual(["high", "low"], contract["nibble_order"])
        self.assertEqual(0x80, contract["initial_level"])
        self.assertEqual(sorted(CODE_SIGNATURES), contract["decoder_signature_offsets"])
        for value in range(0x100):
            self.assertEqual(DELTA_BYTES[value >> 4], self.high[value])
            self.assertEqual(DELTA_BYTES[value & 0x0F], self.low[value])

    def test_decode_applies_high_nibble_before_low_nibble(self) -> None:
        self.assertEqual(
            bytes((0x81, 0x83, 0x82, 0x42)),
            decode_dpcm(bytes((0x12, 0x9F)), self.high, self.low),
        )

    def test_encoder_rejects_a_delta_outside_the_driver_table(self) -> None:
        with self.assertRaisesRegex(ValueError, "unrepresentable high-nibble delta"):
            encode_dpcm(bytes((0x83, 0x83)))

    def test_every_cartridge_sample_decodes_and_reencodes_exactly(self) -> None:
        self.assertEqual((90, 507004), check_project(ROOT, "jp"))

    def test_pcm_document_records_the_fixed_decoded_capacity(self) -> None:
        document = export_document(ROOT, "jp")
        self.assertEqual(507004, document["decoded_value_count"])
        self.assertEqual(codec_contract(ROOT), document["codec"])

    def test_music_delay_uses_request_state_instead_of_descriptor_byte(self) -> None:
        driver = (ROOT / "data/sound/z80_data.bin").read_bytes()
        self.assertEqual(bytes.fromhex("3A FE 1F B7 CA 5D 00"), driver[0x5D:0x64])
        self.assertEqual(bytes.fromhex("B7 FA F0 01 32 E0 1F"), driver[0x67:0x6E])
        self.assertEqual(bytes.fromhex("3A E0 1F 4F"), driver[0x107:0x10B])
        self.assertEqual(bytes.fromhex("41 10 FE"), driver[0x139:0x13C])
        self.assertEqual(bytes.fromhex("41 10 FE"), driver[0x177:0x17A])

        music = (ROOT / "src/sound/driver_core.s").read_text(encoding="utf-8")
        voice = (ROOT / "src/sound/command_dispatch_and_dac.s").read_text(
            encoding="utf-8")
        self.assertIn("move.b  #1,(Z80DACRequestState).l", music)
        self.assertIn("move.b  #$80,(Z80DACRequestState).l", voice)
        self.assertIn("move.b  (a3)+,(Z80DACCommandByte4).l", music)

    def test_music_delay_pair_is_twelve_cpu_t_states_at_both_sites(self) -> None:
        self.assertEqual({
            "request_state_load": 0x107,
            "delay_sites": [0x139, 0x177],
            "music_request_count": 1,
            "music_delay_t_states_per_site": 12,
        }, ordinary_delay_contract(ROOT))
        self.assertEqual(25, ordinary_delay_t_states(2))
        self.assertEqual(4 + 255 * 13 + 8, ordinary_delay_t_states(0))
        for invalid in (-1, 256, True, 1.0):
            with self.assertRaisesRegex(ValueError, "unsigned byte"):
                ordinary_delay_t_states(invalid)

    def test_uninterrupted_pcm_dac_write_intervals_are_cpu_cycle_pinned(self) -> None:
        contract = ordinary_dac_timing_contract(ROOT)
        self.assertEqual(0x134, contract["first_write"])
        self.assertEqual(0x173, contract["second_write"])
        self.assertEqual({
            "equal_ready": 94,
            "negative_clear": 94,
            "negative_set": 94,
            "positive": 94,
        }, contract["branch_t_states"])
        self.assertEqual(191, contract["first_to_second_t_states"])
        self.assertEqual(196, contract["second_to_next_first_t_states"])
        self.assertEqual(387, contract["encoded_byte_t_states"])
        self.assertEqual(34, contract["equal_busy_poll_extra_t_states"])
        self.assertEqual((0, 191), ordinary_dac_event_offsets(contract, 0))
        self.assertEqual((387, 578), ordinary_dac_event_offsets(contract, 1))
        self.assertEqual((3870, 4061), ordinary_dac_event_offsets(contract, 10))
        for invalid in (-1, True, 1.5):
            with self.assertRaisesRegex(ValueError, "nonnegative integer"):
                ordinary_dac_event_offsets(contract, invalid)

    def test_dac_timing_contract_rejects_a_changed_branch_instruction(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            driver_path = root / "data/sound/z80_data.bin"
            driver_path.parent.mkdir(parents=True)
            driver = bytearray((ROOT / "data/sound/z80_data.bin").read_bytes())
            self.assertEqual(DAC_TIMING_SIGNATURES[0x141], driver[0x141:0x146])
            driver[0x141] ^= 1
            driver_path.write_bytes(driver)
            with self.assertRaisesRegex(ValueError, "DAC timing path differs at \\$141"):
                ordinary_dac_timing_contract(root)


if __name__ == "__main__":
    unittest.main()
