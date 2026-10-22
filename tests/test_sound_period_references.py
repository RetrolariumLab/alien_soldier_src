from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import sound_period_references as periods  # noqa: E402
from authoring.sound_sequence_model import FORMAT, document_errors  # noqa: E402
from authoring.sound_studio_model import decode_bgm_header, decode_sfx_header  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402


def sfx(events: bytes, *, transpose=0, kind=0x80, label="Sound_SFX_Fixture"):
    size = 10 + len(events)
    body = size.to_bytes(2, "big") + bytes((0x80, 1, 0x80, kind, 0, 10, transpose, 0)) + events
    return decode_sfx_header(label, body), body


def check(original, edited, limit=70):
    source, original_body = original
    candidate, edited_body = edited
    return periods.validate_period_references("sfx", source, original_body, candidate, edited_body, limit)


class PSGReferenceTests(unittest.TestCase):
    def test_direct_table_end_is_allowed_but_next_period_is_rejected(self):
        original = sfx(bytes.fromhex("C601 F2"))
        check(original, original)
        with self.assertRaisesRegex(ValueError, "period 70 outside 0..69"):
            check(original, sfx(bytes.fromhex("C701 F2")))

    def test_rest_does_not_lookup_a_table_even_with_negative_transpose(self):
        original = sfx(bytes.fromhex("8001 F2"), transpose=0xFF)
        self.assertEqual(frozenset(), check(original, original)[0]["reads"])

    def test_initial_transpose_is_the_high_byte_and_index_masks_after_byte_add(self):
        for transpose, note, index in ((0xFC, 0x85, 0), (0x7F, 0x82, 0), (0x80, 0x85, 4)):
            with self.subTest(transpose=transpose):
                original = sfx(bytes((note, 1, 0xF2)), transpose=transpose)
                reads = check(original, original)[0]["reads"]
                self.assertEqual({index}, {item.index for item in reads})
        with self.assertRaisesRegex(ValueError, "period 124"):
            check(sfx(bytes.fromhex("8501 F2"), transpose=0xFC), sfx(bytes.fromhex("8101 F2"), transpose=0xFC))

    def test_repeat_executes_the_source_count_instead_of_an_infinite_branch_overapproximation(self):
        original = sfx(bytes.fromhex("FB01 C301 F70002 FFF8 F2"))
        analysis = check(original, original)[0]
        self.assertEqual("proved", analysis["status"])
        self.assertEqual({67, 68}, {item.index for item in analysis["reads"]})
        with self.assertRaisesRegex(ValueError, "period 70"):
            check(original, sfx(bytes.fromhex("FB02 C301 F70002 FFF8 F2")))

    def test_call_transpose_flows_back_to_the_caller(self):
        original = sfx(bytes.fromhex("FB01 F80004 C301 F2 FB01 F9"))
        analysis = check(original, original)[0]
        self.assertEqual(1, analysis["max_call_depth"])
        self.assertEqual({68}, {item.index for item in analysis["reads"]})
        with self.assertRaisesRegex(ValueError, "period 70"):
            check(original, sfx(bytes.fromhex("FB01 F80004 C301 F2 FB03 F9")))

    def test_special_sfx_noise_changes_parser_after_the_next_event_not_mid_parse(self):
        original = sfx(bytes.fromhex("F3E7 DF01 8001 F2"), kind=2, label="Sound_SFX_F9")
        self.assertEqual(frozenset(), check(original, original)[0]["reads"])
        edited = sfx(bytes.fromhex("F3E7 DF01 DF01 F2"), kind=2, label="Sound_SFX_F9")
        with self.assertRaisesRegex(ValueError, "at \\$000E channel 0 type \\$E0.*period 94"):
            check(original, edited)

    def test_ordinary_fm_record_does_not_become_a_psg_reader_after_noise_command(self):
        original = sfx(bytes.fromhex("F3E7 DF01 DF01 F2"), kind=2, label="Sound_SFX_A0")
        self.assertEqual(frozenset(), check(original, original)[0]["reads"])

    def test_psg_noise_still_reads_the_period_table(self):
        original = sfx(bytes.fromhex("F3E7 C601 F2"), kind=0xC0)
        self.assertEqual({69}, {item.index for item in check(original, original)[0]["reads"]})
        with self.assertRaisesRegex(ValueError, "period 70"):
            check(original, sfx(bytes.fromhex("F3E7 C701 F2"), kind=0xC0))

    def test_same_sequence_shared_by_fm_and_psg_is_checked_for_both_roots(self):
        body = bytes.fromhex("0013 8002 8002 0010 0000 8080 0010 0000 C601 F2")
        original = (decode_sfx_header("Sound_SFX_A0", body), body)
        self.assertEqual([0, 1], [len(item["reads"]) for item in check(original, original)])
        changed = body[:16] + bytes.fromhex("C701 F2")
        with self.assertRaisesRegex(ValueError, "channel 1.*period 70"):
            check(original, (decode_sfx_header("Sound_SFX_A0", changed), changed))

    def test_exact_canonical_outside_read_is_preserved_but_not_a_blanket_exception(self):
        original = sfx(bytes.fromhex("E601 C701 F2"))
        self.assertEqual({70}, {item.index for item in check(original, original)[0]["outside"]})
        check(original, sfx(bytes.fromhex("E602 C701 F2")))  # Independent volume does not affect its reference.
        with self.assertRaisesRegex(ValueError, "period 71"):
            check(original, sfx(bytes.fromhex("E601 C801 F2")))
        # Retaining the same effective index with a different transpose path
        # cannot reuse an exact source exception.
        original = sfx(bytes.fromhex("FB01 C701 F2"))
        with self.assertRaisesRegex(ValueError, "period 71"):
            check(original, sfx(bytes.fromhex("FB02 C601 F2")))

    def test_unanalysed_source_path_is_preserved_but_all_edits_are_locked(self):
        original = sfx(bytes.fromhex("C601 F70802 FFFA F2"))
        self.assertEqual("unanalysed", check(original, original)[0]["status"])
        with self.assertRaisesRegex(ValueError, "sequence edits are locked"):
            check(original, sfx(bytes.fromhex("C501 F70802 FFFA F2")))

    def test_extended_global_state_dependent_cursor_is_explicitly_unanalysed(self):
        original = sfx(bytes.fromhex("FF030101 C601 F2"))
        analysis = check(original, original)[0]
        self.assertEqual("unanalysed", analysis["status"])
        self.assertIn("global volume state", analysis["why"])
        with self.assertRaisesRegex(ValueError, "sequence edits are locked"):
            check(original, sfx(bytes.fromhex("FF030102 C601 F2")))

    def test_call_pointer_alias_is_locked_instead_of_inventing_absolute_address_bytes(self):
        original = sfx(bytes.fromhex("F80004 C601 F2 F70402 FFFC F9"))
        analysis = check(original, original)[0]
        self.assertEqual("unanalysed", analysis["status"])
        self.assertIn("aliases a call return pointer", analysis["why"])
        with self.assertRaisesRegex(ValueError, "sequence edits are locked"):
            check(original, sfx(bytes.fromhex("F80004 C501 F2 F70402 FFFC F9")))

    def test_bgm_first_type_six_is_pcm_but_later_type_six_is_fm_not_psg(self):
        body = bytes.fromhex("0011 0200 0101 000E 0000 000E 0000 C701 F2")
        header = decode_bgm_header("Sound_BGM_81", body)
        # The actual second header slot uses FM type zero. Type six is also
        # legal in the final ordinary FM slot; slot position, not six, is DAC.
        header["channels"][1]["runtime_channel_type"] = 6
        analyses = periods.analyse_payload("bgm", header, body, 70)
        self.assertEqual(["proved", "proved"], [item["status"] for item in analyses])
        self.assertEqual([frozenset(), frozenset()], [item["reads"] for item in analyses])

    def test_finite_state_limit_is_explicit_not_a_successful_skip(self):
        original = sfx(bytes.fromhex("C601 F2"))
        with mock.patch.object(periods, "MAX_STATES", 1):
            self.assertEqual("unanalysed", check(original, original)[0]["status"])
            with self.assertRaisesRegex(ValueError, "exceeds 1 states"):
                check(original, sfx(bytes.fromhex("C501 F2")))

    def test_instruction_source_contract_and_table_are_real_not_an_assumed_128_words(self):
        stored, bodies = labelled_blocks(ROOT)
        contract = periods.period_contract(ROOT, stored, bodies)
        self.assertEqual(70, contract["word_count"])
        self.assertEqual(64, len(contract["table_sha256"]))
        different_table = dict(stored)
        different_table[periods.TABLE] = (*stored[periods.TABLE][:-1], 1)
        self.assertNotEqual(
            contract["table_sha256"], periods.period_contract(ROOT, different_table, bodies)["table_sha256"]
        )
        altered = dict(bodies)
        altered["Sound_DecodePSGSequenceNote"] = (*altered["Sound_DecodePSGSequenceNote"], " move.b #0,8(a5)")
        with self.assertRaisesRegex(ValueError, "proved instructions"):
            periods.period_contract(ROOT, stored, altered)
        with self.assertRaisesRegex(ValueError, "word tuple"):
            periods.period_contract(ROOT, {periods.TABLE: bytes(140)}, bodies)
        altered = dict(bodies)
        altered["Sound_ResolveSFXHeader"] = tuple(
            line.replace("#$30,d6", "#$2C,d6") for line in bodies["Sound_ResolveSFXHeader"]
        )
        with self.assertRaisesRegex(ValueError, "Sound_ResolveSFXHeader"):
            periods.period_contract(ROOT, stored, altered)

    def test_outside_context_is_bound_to_actual_source_contract_not_only_its_offset(self):
        header, body = sfx(bytes.fromhex("C701 F2"))
        first = periods.analyse_payload("sfx", header, body, 70, (periods.TABLE, 70, "table-a", "reader-a"))[0][
            "outside"
        ]
        other = periods.analyse_payload("sfx", header, body, 70, (periods.TABLE, 70, "table-b", "reader-a"))[0][
            "outside"
        ]
        self.assertTrue(first)
        self.assertFalse(first & other)


class SequencePeriodIntegrationTests(unittest.TestCase):
    def document(self, header, body):
        instructions = [
            {**item, "data": list(body[item["offset"] : item["offset"] + item["size"]])}
            for item in header["sequence"]["instructions"]
        ]
        sequence = header["sequence"]
        record = {
            "name": header["label"],
            "family": "sfx",
            "path": "fixture.bin",
            "storage": "binary",
            "capacity": len(body),
            "header_byte_count": header["header_byte_count"],
            "instrument_offset": header["instrument_offset"],
            "entry_offsets": sequence["entry_offsets"],
            "instruction_count": sequence["instruction_count"],
            "reachable_byte_count": sequence["reachable_byte_count"],
            "instructions": instructions,
        }
        return {
            "schema_version": 1,
            "profile": "jp",
            "format": FORMAT,
            "payload_count": 1,
            "instruction_count": sequence["instruction_count"],
            "reachable_byte_count": sequence["reachable_byte_count"],
            "payloads": [record],
        }

    def setup_source(self, original):
        header, body = original
        document = self.document(header, body)
        for name, result in (
            ("export_document", document),
            ("labelled_blocks", ({header["label"]: body}, {})),
            ("envelope_selector_limits", {"pitch": 8, "psg_volume": 10}),
            ("music_sample_ids", frozenset(range(0x81, 0x97))),
            (
                "period_contract",
                {
                    "table": periods.TABLE,
                    "word_count": 70,
                    "table_sha256": "fixture-table",
                    "reader_sha256": "fixture-readers",
                },
            ),
        ):
            patcher = mock.patch("authoring.sound_sequence_model." + name, return_value=result)
            patcher.start()
            self.addCleanup(patcher.stop)
        return copy.deepcopy(document)

    def test_headless_document_validator_rejects_a_new_effective_period(self):
        document = self.setup_source(sfx(bytes.fromhex("C601 F2")))
        note = next(item for item in document["payloads"][0]["instructions"] if item["kind"] == "note")
        note["data"][0] = 0xC7
        self.assertTrue(any("period 70" in error for error in document_errors(document, ROOT, "jp")))

    def test_loop_operands_remain_source_owned_even_when_target_is_unchanged(self):
        document = self.setup_source(sfx(bytes.fromhex("C601 F70002 FFFA F2")))
        loop = next(item for item in document["payloads"][0]["instructions"] if item.get("opcode") == 0xF7)
        loop["data"][1] = 8
        self.assertTrue(any("loop control operand" in error for error in document_errors(document, ROOT, "jp")))


if __name__ == "__main__":
    unittest.main()
