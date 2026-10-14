from __future__ import annotations

import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sound_instrument_model import (  # noqa: E402
    apply_document,
    document_errors,
    export_document,
    validate_document,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_operation  # noqa: E402


class SoundInstrumentDocumentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.enterClassContext(parsed_operation(ROOT))
        cls.document = export_document(ROOT, "jp")

    def test_project_instruments_round_trip_without_writes(self) -> None:
        self.assertEqual(182, self.document["payload_count"])
        self.assertEqual(901, self.document["instrument_count"])
        self.assertEqual(22525, self.document["parameter_byte_count"])
        self.assertEqual(101, self.document["padding_byte_count"])
        validate_document(self.document, ROOT, "jp")
        self.assertEqual([], apply_document(self.document, ROOT, "jp", write=False))

    def test_inventory_and_alignment_padding_are_immutable(self) -> None:
        document = copy.deepcopy(self.document)
        payload = next(item for item in document["payloads"] if item["instruments"])
        payload["instruments"].pop()
        self.assertTrue(any("inventory differs" in error
                            for error in document_errors(document, ROOT, "jp")))
        document = copy.deepcopy(self.document)
        padded = next(item for item in document["payloads"] if item["trailing_padding"])
        padded["trailing_padding"][0] ^= 1
        self.assertTrue(any("trailing_padding differs" in error
                            for error in document_errors(document, ROOT, "jp")))

    def test_binary_and_inline_instruments_write_only_to_a_staged_tree(self) -> None:
        document = copy.deepcopy(self.document)
        edited = []
        for storage in ("binary", "source"):
            payload = next(
                item for item in document["payloads"]
                if item["storage"] == storage and item["instruments"]
            )
            instrument = payload["instruments"][0]
            instrument["total_level"][0] ^= 1
            edited.append((payload, instrument))
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            shutil.copytree(ROOT / "src", staged / "src")
            shutil.copytree(ROOT / "data", staged / "data")
            changed = apply_document(
                document, staged, "jp", validation_root=ROOT)
            self.assertEqual(
                sorted(payload["path"] for payload, _instrument in edited), changed)
            stored, _bodies = labelled_blocks(staged)
            for payload, instrument in edited:
                offset = payload["instrument_offset"] + 21
                self.assertEqual(
                    instrument["total_level"][0], stored[payload["name"]][offset])

    def test_eu_document_has_the_same_instrument_contract(self) -> None:
        eu = export_document(ROOT, "eu")
        for field in (
            "payload_count", "instrument_count", "parameter_byte_count",
            "padding_byte_count",
        ):
            self.assertEqual(self.document[field], eu[field])


if __name__ == "__main__":
    unittest.main()
