from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.compressed_graphics_model import (  # noqa: E402
    apply_document,
    encoded_slot,
    export_document,
    payload_plain,
    rebuild_source,
    round_trip_errors,
)
from authoring.lzss_codec import decompress_as_vram  # noqa: E402
from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402


class CompressedGraphicsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.document = export_document(ROOT, "jp")
        cls.records = {record["name"]: record for record in cls.document["payloads"]}

    def test_both_compressed_tile_inventories_have_fixed_slots(self) -> None:
        self.assertEqual(153, self.document["payload_count"])
        self.assertEqual(29405, self.document["tile_count"])
        self.assertEqual(598058, self.document["compressed_capacity"])
        self.assertEqual(7, sum(record["codec"] == "tile-codec" for record in self.document["payloads"]))
        self.assertEqual(
            {"payload": 147, "source": 6},
            {
                storage: sum(record["storage"] == storage for record in self.document["payloads"])
                for storage in ("payload", "source")
            },
        )
        self.assertEqual(
            ["Credits_SegaMappingData"],
            sorted(self.document["excluded"]),
        )

    def test_zero_edit_preserves_original_compressed_streams(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT, "jp"))

    def test_edit_recompresses_and_pads_to_the_original_capacity(self) -> None:
        record = copy.deepcopy(self.records["Boss_AntroidTileArt"])
        tile = record["blocks"][0]["tiles"][0]
        record["blocks"][0]["tiles"][0] = ("1" if tile[0] != "1" else "2") + tile[1:]
        slot = encoded_slot(record)
        self.assertEqual(record["compressed_capacity"], len(slot))
        self.assertEqual(payload_plain(record), decompress_as_vram(slot))

        document = copy.deepcopy(self.document)
        edited = next(item for item in document["payloads"] if item["name"] == "Boss_AntroidTileArt")
        edited["blocks"][0]["tiles"] = record["blocks"][0]["tiles"]
        self.assertEqual([record["path"]], apply_document(document, ROOT, "jp", write=False))

    def test_edit_that_does_not_fit_is_rejected(self) -> None:
        record = copy.deepcopy(self.records["Stage16TileArt5F00"])
        tile = record["blocks"][0]["tiles"][0]
        record["blocks"][0]["tiles"][0] = ("1" if tile[0] != "1" else "2") + tile[1:]
        with self.assertRaisesRegex(ValueError, "exceeds fixed capacity"):
            encoded_slot(record)

    def test_inline_streams_rebuild_without_reformatting_at_zero_edit(self) -> None:
        record = self.records["CreditsAndTransitionTileArtE000"]
        stored, _bodies = labelled_blocks(ROOT)
        path = ROOT / record["path"]
        self.assertEqual(
            path.read_text(encoding="utf-8"),
            rebuild_source(ROOT, record["path"], {record["name"]: stored[record["name"]]}),
        )

    def test_inline_edit_targets_its_source_owner_without_writing(self) -> None:
        document = copy.deepcopy(self.document)
        record = next(item for item in document["payloads"] if item["name"] == "CreditsAndTransitionTileArtE000")
        tile = record["blocks"][0]["tiles"][0]
        record["blocks"][0]["tiles"][0] = ("1" if tile[0] != "1" else "2") + tile[1:]
        self.assertEqual([record["path"]], apply_document(document, ROOT, "jp", write=False))


if __name__ == "__main__":
    unittest.main()
