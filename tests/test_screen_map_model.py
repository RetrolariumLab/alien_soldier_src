from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.lzss_codec import decompress  # noqa: E402
from authoring.stage_tilemap_model import parsed_operation  # noqa: E402
from authoring.screen_map_model import (  # noqa: E402
    apply_document,
    document_errors,
    encode_values,
    encoded_slot,
    export_document,
    round_trip_errors,
)


class ScreenMapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.enterClassContext(parsed_operation(ROOT))
        cls.document = export_document(ROOT, "jp")
        cls.records = {record["name"]: record for record in cls.document["payloads"]}

    def test_inventory_and_roles_are_fixed(self) -> None:
        self.assertEqual(8, self.document["payload_count"])
        self.assertEqual(8744, self.document["value_count"])
        self.assertEqual(14544, self.document["decoded_byte_count"])
        self.assertEqual(4836, self.document["compressed_capacity"])
        self.assertEqual(
            {"patterns": 3, "chunks": 3, "coarse": 2},
            {
                role: sum(record["role"] == role for record in self.document["payloads"])
                for role in ("patterns", "chunks", "coarse")
            },
        )
        self.assertEqual(
            {"payload": 4, "source": 4},
            {
                storage: sum(record["storage"] == storage for record in self.document["payloads"])
                for storage in ("payload", "source")
            },
        )

    def test_both_profiles_have_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT, "jp"))
        self.assertEqual([], round_trip_errors(ROOT, "eu"))

    def test_one_value_recompresses_inside_the_original_slot(self) -> None:
        record = copy.deepcopy(self.records["StoryScreenMappingData6000"])
        record["values"][0] ^= 1
        slot = encoded_slot(record)
        self.assertEqual(record["compressed_capacity"], len(slot))
        self.assertEqual(encode_values(record), decompress(slot))

        document = copy.deepcopy(self.document)
        edited = next(item for item in document["payloads"] if item["name"] == record["name"])
        edited["values"] = record["values"]
        self.assertEqual([record["path"]], apply_document(document, ROOT, "jp", write=False))

    def test_inline_value_targets_its_assembly_owner(self) -> None:
        document = copy.deepcopy(self.document)
        record = next(item for item in document["payloads"] if item["name"] == "FrontendTitleMappingData6000")
        record["values"][0] ^= 1
        self.assertEqual([record["path"]], apply_document(document, ROOT, "jp", write=False))

    def test_incompressible_edit_is_rejected_by_fixed_capacity(self) -> None:
        record = copy.deepcopy(self.records["FrontendTitleMappingData6000"])
        maximum = (1 << record["value_bits"]) - 1
        record["values"] = [((index * 1103515245 + 12345) >> 8) & maximum for index in range(len(record["values"]))]
        with self.assertRaisesRegex(ValueError, "exceeds fixed capacity"):
            encoded_slot(record)

    def test_metadata_count_and_value_width_cannot_be_changed(self) -> None:
        document = copy.deepcopy(self.document)
        record = document["payloads"][0]
        record["role"] = "chunks"
        record["values"].pop()
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("role differs" in error for error in errors))
        self.assertTrue(any("value count differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["payloads"][0]["values"][0] = -1
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("unsigned 16-bit integer" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
