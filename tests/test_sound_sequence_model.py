from __future__ import annotations

import copy
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_sequence_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
    validate_document,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_operation  # noqa: E402


class SoundSequenceDocumentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.enterClassContext(parsed_operation(ROOT))
        cls.document = export_document(ROOT, "jp")

    def test_project_inventory_round_trips_without_writes(self) -> None:
        self.assertEqual(182, self.document["payload_count"])
        self.assertEqual(33062, self.document["instruction_count"])
        self.assertEqual(51045, self.document["reachable_byte_count"])
        validate_document(self.document, ROOT, "jp")
        self.assertEqual([], apply_document(self.document, ROOT, "jp", write=False))

    def test_note_and_non_control_operand_edits_are_accepted(self) -> None:
        document = copy.deepcopy(self.document)
        payload = next(
            item for item in document["payloads"]
            if any(inst["kind"] == "note" for inst in item["instructions"])
        )
        note = next(inst for inst in payload["instructions"] if inst["kind"] == "note")
        note["data"][0] = 0x80 if note["data"][0] != 0x80 else 0x81
        validate_document(document, ROOT, "jp")
        self.assertEqual([payload["path"]], apply_document(document, ROOT, "jp", write=False))

    def test_opcode_and_relative_target_edits_are_rejected(self) -> None:
        document = copy.deepcopy(self.document)
        payload = next(
            item for item in document["payloads"]
            if any(inst.get("flow") == "jump" for inst in item["instructions"])
        )
        jump = next(inst for inst in payload["instructions"] if inst.get("flow") == "jump")
        jump["data"][-1] ^= 1
        self.assertTrue(document_errors(document, ROOT, "jp"))

        document = copy.deepcopy(self.document)
        payload = next(
            item for item in document["payloads"]
            if any(inst.get("opcode", 0xFF) != 0xFF
                   for inst in item["instructions"] if inst["kind"] == "command")
        )
        command = next(
            inst for inst in payload["instructions"]
            if inst["kind"] == "command" and inst.get("opcode", 0xFF) != 0xFF
        )
        command["data"][0] = 0xE1 if command["data"][0] != 0xE1 else 0xE0
        self.assertTrue(document_errors(document, ROOT, "jp"))

    def test_fixed_instruction_inventory_cannot_be_resized(self) -> None:
        document = copy.deepcopy(self.document)
        document["payloads"][0]["instructions"].pop()
        self.assertTrue(any("inventory differs" in error
                            for error in document_errors(document, ROOT, "jp")))

    def test_eu_document_has_the_same_fixed_capacity(self) -> None:
        eu = export_document(ROOT, "eu")
        for field in ("payload_count", "instruction_count", "reachable_byte_count"):
            self.assertEqual(self.document[field], eu[field])

    def test_manifest_registers_the_workspace_gate(self) -> None:
        manifest = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        studio = next(item for item in manifest["studios"] if item["id"] == "sound")
        self.assertEqual(
            [
                "sound_envelopes", "sound_instruments", "sound_pcm_samples",
                "sound_sequences",
            ],
            studio["artifacts"])
        self.assertEqual("check-sound-workspace", studio["workspace_gate"])

    def test_binary_and_inline_payloads_write_only_to_a_staged_tree(self) -> None:
        document = copy.deepcopy(self.document)
        edited = []
        for storage in ("binary", "source"):
            payload = next(
                item for item in document["payloads"]
                if item["storage"] == storage
                and any(inst["kind"] == "note" for inst in item["instructions"])
            )
            note = next(
                inst for inst in payload["instructions"] if inst["kind"] == "note"
            )
            note["data"][0] = 0x80 if note["data"][0] != 0x80 else 0x81
            edited.append((payload, note))

        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            shutil.copytree(ROOT / "src", staged / "src")
            shutil.copytree(ROOT / "data", staged / "data")
            changed = apply_document(
                document, staged, "jp", validation_root=ROOT)
            self.assertEqual(
                sorted(payload["path"] for payload, _note in edited), changed)
            stored, _bodies = labelled_blocks(staged)
            for payload, note in edited:
                self.assertEqual(
                    note["data"][0], stored[payload["name"]][note["offset"]])


if __name__ == "__main__":
    unittest.main()
