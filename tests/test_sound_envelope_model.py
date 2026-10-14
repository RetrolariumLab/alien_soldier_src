from __future__ import annotations

import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_envelope_model import (  # noqa: E402
    SOURCE_PATH,
    _walk,
    apply_document,
    document_errors,
    export_document,
    validate_document,
)
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402


class SoundEnvelopeDocumentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")

    def family(self, document: dict, name: str) -> dict:
        return next(item for item in document["families"] if item["id"] == name)

    def test_project_envelopes_round_trip_without_writes(self) -> None:
        self.assertEqual(2, self.document["family_count"])
        self.assertEqual(18, self.document["envelope_count"])
        self.assertEqual(360, self.document["capacity"])
        self.assertEqual(343, self.document["value_count"])
        self.assertEqual(16, self.document["command_count"])
        self.assertEqual(1, self.document["protected_byte_count"])
        validate_document(self.document, ROOT, "jp")
        self.assertEqual([], apply_document(self.document, ROOT, "jp", write=False))

    def test_pointer_order_is_distinct_from_physical_label_order(self) -> None:
        for family_name in ("pitch", "psg_volume"):
            family = self.family(self.document, family_name)
            self.assertTrue(family["envelopes"][4]["entry_label"].endswith("_5"))
            self.assertTrue(family["envelopes"][5]["entry_label"].endswith("_6"))
            self.assertTrue(family["blocks"][4]["name"].endswith("_6"))
            self.assertTrue(family["blocks"][5]["name"].endswith("_5"))

    def test_envelope_six_falls_through_into_envelope_five(self) -> None:
        for family_name in ("pitch", "psg_volume"):
            family = self.family(self.document, family_name)
            envelope_six = family["envelopes"][5]
            block_five = family["blocks"][5]
            block_five_start = sum(block["capacity"] for block in family["blocks"][:5])
            self.assertEqual(family["blocks"][4]["capacity"] + block_five["capacity"],
                             len(envelope_six["reachable_offsets"]))
            self.assertIn(block_five_start, envelope_six["reachable_offsets"])

    def test_commands_and_unreachable_padding_are_immutable(self) -> None:
        document = copy.deepcopy(self.document)
        pitch = self.family(document, "pitch")
        pitch["blocks"][0]["commands"][0]["opcode"] ^= 1
        self.assertTrue(any("commands differs" in error
                            for error in document_errors(document, ROOT, "jp")))
        document = copy.deepcopy(self.document)
        psg = self.family(document, "psg_volume")
        psg["blocks"][-1]["protected_bytes"][0]["byte"] ^= 1
        self.assertTrue(any("protected_bytes differs" in error
                            for error in document_errors(document, ROOT, "jp")))

    def test_value_may_not_become_a_reader_command(self) -> None:
        document = copy.deepcopy(self.document)
        pitch = self.family(document, "pitch")
        pitch["blocks"][0]["values"][0]["value"] = -128
        self.assertTrue(any("becomes a control command" in error
                            for error in document_errors(document, ROOT, "jp")))

    def test_reader_control_flow_widths_are_explicit(self) -> None:
        values, commands, operands = _walk(
            bytes((0x84, 1, 2, 0x82, 6, 99, 0x83)), 0,
            frozenset(range(0x80, 0x85)), "pitch",
        )
        self.assertEqual({2}, values)
        self.assertEqual({0, 3, 6}, set(commands))
        self.assertEqual({1, 4}, operands)
        self.assertEqual(6, commands[3]["target"])

    def test_psg_value_allows_pitch_only_transpose_opcode(self) -> None:
        document = copy.deepcopy(self.document)
        psg = self.family(document, "psg_volume")
        psg["blocks"][0]["values"][0]["value"] = -124
        validate_document(document, ROOT, "jp")

    def test_bounded_values_write_only_to_a_staged_source(self) -> None:
        document = copy.deepcopy(self.document)
        pitch = self.family(document, "pitch")["blocks"][0]
        psg = self.family(document, "psg_volume")["blocks"][0]
        pitch["values"][0]["value"] = 1
        psg["values"][0]["value"] = 1
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            shutil.copytree(ROOT / "src", staged / "src")
            shutil.copytree(ROOT / "data", staged / "data")
            changed = apply_document(document, staged, "jp", validation_root=ROOT)
            self.assertEqual([SOURCE_PATH], changed)
            stored, _bodies = labelled_blocks(staged)
            self.assertEqual(1, stored[pitch["name"]][pitch["values"][0]["offset"]])
            self.assertEqual(1, stored[psg["name"]][psg["values"][0]["offset"]])

    def test_eu_document_has_the_same_envelope_contract(self) -> None:
        eu = export_document(ROOT, "eu")
        for field in (
            "family_count", "envelope_count", "capacity", "value_count",
            "command_count", "protected_byte_count",
        ):
            self.assertEqual(self.document[field], eu[field])


if __name__ == "__main__":
    unittest.main()
