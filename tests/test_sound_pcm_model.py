from __future__ import annotations

import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_pcm_model import (  # noqa: E402
    _parse_bank,
    apply_document,
    document_errors,
    export_document,
    validate_document,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_operation  # noqa: E402


class SoundPCMDocumentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.enterClassContext(parsed_operation(ROOT))
        cls.document = export_document(ROOT, "jp")

    def test_project_banks_round_trip_without_writes(self) -> None:
        self.assertEqual(9, self.document["bank_count"])
        self.assertEqual(90, self.document["sample_count"])
        self.assertEqual(253502, self.document["sample_byte_count"])
        self.assertEqual(507004, self.document["decoded_value_count"])
        self.assertEqual(360, self.document["header_byte_count"])
        self.assertEqual(15032, self.document["padding_byte_count"])
        self.assertEqual(70, self.document["descriptor_record_count"])
        self.assertEqual(69, self.document["dispatchable_descriptor_count"])
        self.assertEqual(57, self.document["referenced_sample_count"])
        self.assertEqual(33, self.document["unreferenced_sample_count"])
        validate_document(self.document, ROOT, "jp")
        self.assertEqual([], apply_document(self.document, ROOT, "jp", write=False))

    def test_headers_samples_and_padding_cover_every_bank_byte(self) -> None:
        for bank in self.document["banks"]:
            self.assertEqual(
                bank["capacity"],
                bank["header_byte_count"] + bank["sample_byte_count"] + bank["padding_byte_count"],
            )
            cursor = bank["header_byte_count"]
            for index, sample in enumerate(bank["samples"]):
                self.assertEqual(index, sample["index"])
                self.assertEqual(index * 4, sample["header_offset"])
                self.assertEqual(cursor, sample["start_offset"])
                self.assertEqual(sample["byte_count"] * 2, len(sample["data"]))
                cursor += sample["byte_count"]

    def test_descriptor_reader_byte_order_and_rejected_tail_are_recorded(self) -> None:
        music, voice = self.document["descriptor_tables"]
        self.assertEqual(("music", 22, 22), (music["id"], music["record_count"], music["dispatchable_count"]))
        self.assertEqual(("voice", 48, 47), (voice["id"], voice["record_count"], voice["dispatchable_count"]))
        first = voice["records"][0]
        self.assertEqual("Sound_PCMBank3", first["bank"])
        self.assertEqual(0x08, first["header_offset"])
        self.assertEqual(2, first["sample_index"])
        self.assertEqual(0x3F, voice["records"][-1]["id"])
        self.assertFalse(voice["records"][-1]["dispatchable"])

    def test_header_identity_and_sample_capacity_are_immutable(self) -> None:
        document = copy.deepcopy(self.document)
        document["banks"][0]["samples"][0]["start_offset"] += 1
        self.assertTrue(any("changes start_offset" in error for error in document_errors(document, ROOT, "jp")))
        document = copy.deepcopy(self.document)
        document["banks"][0]["samples"][0]["data"] += "00"
        self.assertTrue(any("invalid encoded length" in error for error in document_errors(document, ROOT, "jp")))

    def test_bounded_sample_edit_writes_only_to_a_staged_bank(self) -> None:
        document = copy.deepcopy(self.document)
        bank = document["banks"][0]
        sample = bank["samples"][0]
        replacement = "00" if sample["data"][:2] != "00" else "01"
        sample["data"] = replacement + sample["data"][2:]
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            shutil.copytree(ROOT / "src", staged / "src")
            shutil.copytree(ROOT / "data", staged / "data")
            changed = apply_document(document, staged, "jp", validation_root=ROOT)
            self.assertEqual([bank["path"]], changed)
            stored, _bodies = labelled_blocks(staged)
            self.assertEqual(int(replacement, 16), stored[bank["name"]][sample["start_offset"]])

    def test_invalid_header_chain_is_rejected(self) -> None:
        body = bytearray((4, 0x80, 2, 0, 0xAA, 0xBB))
        body[0] = 5
        with self.assertRaisesRegex(ValueError, "invalid first-sample offset"):
            _parse_bank("Synthetic", "synthetic.bin", bytes(body))

    def test_eu_document_has_the_same_pcm_contract(self) -> None:
        eu = export_document(ROOT, "eu")
        for field in (
            "bank_count",
            "sample_count",
            "sample_byte_count",
            "decoded_value_count",
            "header_byte_count",
            "padding_byte_count",
            "descriptor_record_count",
            "dispatchable_descriptor_count",
            "referenced_sample_count",
            "unreferenced_sample_count",
        ):
            self.assertEqual(self.document[field], eu[field])


if __name__ == "__main__":
    unittest.main()
