from __future__ import annotations

import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.lzss_codec import decompress  # noqa: E402
from authoring.ram_map_workspace import encoded_slot  # noqa: E402
from authoring.screen_map_model import (  # noqa: E402
    apply_document as apply_screen_document,
    export_document as export_screen_document,
)
from authoring.stage_renderer import draw, scene  # noqa: E402
from authoring import screen_studio  # noqa: E402
from authoring.stage_map_model import (  # noqa: E402
    apply_document, document_errors, export_document, migrate_document,
    round_trip_errors, validate_document,
)
from authoring.stage_tilemap_model import labelled_blocks, parsed_operation  # noqa: E402


class StageMapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        with parsed_operation(ROOT):
            cls.document = export_document(ROOT, "jp")
        cls.records = {record["name"]: record for record in cls.document["payloads"]}

    def setUp(self) -> None:
        # These methods only read ROOT. Foreign write/render methods must keep
        # their own standalone post-write scopes rather than inherit this one.
        if self._testMethodName in {
            "test_inventory_and_shared_screen_source_are_explicit",
            "test_plane_b_pattern_inventory_is_proved_by_final_visible_writer",
            "test_schema_one_migration_keeps_existing_edits_and_adds_plane_b",
            "test_jp_and_eu_zero_edit_round_trip",
            "test_changed_map_uses_its_original_fixed_slot",
            "test_metadata_and_capacity_cannot_be_redefined",
            "test_an_incompressible_map_edit_cannot_expand_its_slot",
        }:
            self.enterContext(parsed_operation(ROOT))

    def test_inventory_and_shared_screen_source_are_explicit(self) -> None:
        self.assertEqual(2, self.document["schema_version"])
        self.assertEqual(42, self.document["payload_count"])
        self.assertEqual(51596, self.document["value_count"])
        self.assertEqual(86808, self.document["decoded_byte_count"])
        self.assertEqual(42420, self.document["compressed_capacity"])
        self.assertEqual(
            {"patterns": 17, "chunks": 22, "coarse": 3},
            {role: sum(record["role"] == role
                       for record in self.document["payloads"])
             for role in ("patterns", "chunks", "coarse")},
        )
        self.assertEqual(
            {"payload": 25, "source": 17},
            {storage: sum(record["storage"] == storage
                          for record in self.document["payloads"])
             for storage in ("payload", "source")},
        )
        screen_names = {
            record["name"] for record in export_screen_document(ROOT, "jp")["payloads"]
        }
        self.assertEqual({"SharedMappingData7000"}, set(self.records) & screen_names)
        self.assertEqual(
            0, self.records["SharedMappingData7000"]["uses"][0]["stage_table_index"])

    def test_plane_b_pattern_inventory_is_proved_by_final_visible_writer(self):
        expected = {
            "Stage1BaseMappingData2000": {0, 1, 2},
            "Stage1Phase1AndShellshogunMappingData2000": {3},
            "Stage10AndTeleportMappingData2020": {9, 10, 11, 12},
            "Stage20MappingData2020": {19},
            "Stage3Phase6AndZLeoEntryMappingData2020": {24},
        }
        for name, indices in expected.items():
            record = self.records[name]
            self.assertEqual("patterns", record["role"])
            self.assertEqual(indices, {
                use["stage_table_index"] for use in record["uses"]
                if use.get("plane") == "plane_b"})
            self.assertTrue(all(
                use["descriptor"] == "Gfx_FrontendAlternateVRAMTransferParameters"
                for use in record["uses"] if use.get("plane") == "plane_b"))
        self.assertNotIn("Stage1Phase3MappingData2020", self.records)
        self.assertNotIn("Stage18MappingData2020", self.records)

    def test_schema_one_migration_keeps_existing_edits_and_adds_plane_b(self):
        legacy = export_document(ROOT, "jp", include_plane_b=False)
        self.assertEqual(1, legacy["schema_version"])
        self.assertEqual(37, legacy["payload_count"])
        changed = copy.deepcopy(legacy)
        record = next(item for item in changed["payloads"]
                      if item["name"] == "Stage1BaseMappingData6000")
        record["values"] = [0] * record["value_count"]
        migrated = migrate_document(changed, ROOT, "jp")
        validate_document(migrated, ROOT, "jp")
        kept = next(item for item in migrated["payloads"]
                    if item["name"] == record["name"])
        self.assertEqual(record["values"], kept["values"])
        self.assertEqual(42, migrated["payload_count"])
        changed["payloads"][0]["role"] = (
            "patterns" if changed["payloads"][0]["role"] != "patterns"
            else "chunks")
        with self.assertRaisesRegex(ValueError, "cannot migrate"):
            migrate_document(changed, ROOT, "jp")

    def test_jp_and_eu_zero_edit_round_trip(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT, "jp"))
        self.assertEqual([], round_trip_errors(ROOT, "eu"))

    def test_changed_map_uses_its_original_fixed_slot(self) -> None:
        document = copy.deepcopy(self.document)
        record = next(item for item in document["payloads"]
                      if item["name"] == "Stage1BaseMappingData6000")
        record["values"] = [0] * record["value_count"]
        slot = encoded_slot(record)
        self.assertEqual(record["compressed_capacity"], len(slot))
        self.assertEqual(bytes(record["values"]), decompress(slot))
        self.assertEqual([record["path"]],
                         apply_document(document, ROOT, "jp", write=False))

    def test_metadata_and_capacity_cannot_be_redefined(self) -> None:
        document = copy.deepcopy(self.document)
        document["payloads"][0]["role"] = (
            "patterns" if document["payloads"][0]["role"] != "patterns" else "chunks")
        document["payloads"][0]["values"].pop()
        errors = document_errors(document, ROOT, "jp")
        self.assertTrue(any("role differs" in error for error in errors))
        self.assertTrue(any("value count differs" in error for error in errors))

        document = copy.deepcopy(self.document)
        document["payloads"][0]["values"][0] = -1
        self.assertTrue(any("unsigned" in error
                            for error in document_errors(document, ROOT, "jp")))

        document = copy.deepcopy(self.document)
        document["payloads"][0]["name"] = ["not a symbol"]
        self.assertTrue(any("payload names" in error
                            for error in document_errors(document, ROOT, "jp")))

    def test_an_incompressible_map_edit_cannot_expand_its_slot(self) -> None:
        record = copy.deepcopy(self.records["Stage3Phase3MappingData6000"])
        record["values"] = [
            ((index * 1103515245 + 12345) >> 8) & 0xFF
            for index in range(record["value_count"])
        ]
        with self.assertRaisesRegex(ValueError, "exceeds fixed capacity"):
            encoded_slot(record)

    def test_shared_source_preserves_one_edit_and_rejects_two_different_edits(self) -> None:
        name = "SharedMappingData7000"
        stage = copy.deepcopy(self.document)
        stage_record = next(item for item in stage["payloads"] if item["name"] == name)
        stage_record["values"] = [0] * stage_record["value_count"]
        screen = export_screen_document(ROOT, "jp")
        screen_same = copy.deepcopy(screen)
        same_record = next(
            item for item in screen_same["payloads"] if item["name"] == name)
        same_record["values"] = stage_record["values"][:]
        screen_conflict = copy.deepcopy(screen)
        screen_record = next(
            item for item in screen_conflict["payloads"] if item["name"] == name)
        screen_record["values"] = [1] * screen_record["value_count"]

        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            for name_of_tree in ("src", "data"):
                shutil.copytree(ROOT / name_of_tree, staged / name_of_tree)
            shutil.copytree(ROOT / "config/authoring", staged / "config/authoring")
            original = (ROOT / stage_record["path"]).read_bytes()
            self.assertEqual(
                [stage_record["path"]],
                apply_document(stage, staged, "jp", validation_root=ROOT),
            )
            self.assertEqual(
                bytes(stage_record["values"]),
                decompress(labelled_blocks(staged)[0][name]),
            )
            self.assertNotEqual(
                draw(scene(ROOT, 0), x=355, y=0, width=64, height=64),
                draw(scene(staged, 0), x=355, y=0, width=64, height=64),
            )
            self.assertEqual(
                [], apply_screen_document(screen, staged, "jp",
                                          validation_root=ROOT),
            )
            self.assertEqual(
                [], apply_screen_document(screen_same, staged, "jp",
                                          validation_root=ROOT),
            )
            with self.assertRaisesRegex(ValueError, "conflicting staged RAM-map edits"):
                apply_screen_document(screen_conflict, staged, "jp",
                                      validation_root=ROOT)
            self.assertEqual(bytes(stage_record["values"]),
                             decompress(labelled_blocks(staged)[0][name]))
            self.assertEqual(original, (ROOT / stage_record["path"]).read_bytes())

    def test_screen_preview_stages_saved_level_maps_before_screen_maps(self) -> None:
        name = "SharedMappingData7000"
        stage = copy.deepcopy(self.document)
        stage_record = next(item for item in stage["payloads"]
                            if item["name"] == name)
        stage_record["values"] = [0] * stage_record["value_count"]
        screen = export_screen_document(ROOT, "jp")
        conflicting = copy.deepcopy(screen)
        screen_record = next(item for item in conflicting["payloads"]
                             if item["name"] == name)
        screen_record["values"] = [1] * screen_record["value_count"]
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            for name_of_tree in ("src", "data"):
                shutil.copytree(ROOT / name_of_tree, staged / name_of_tree)
            with (mock.patch.object(screen_studio, "stage_tree"),
                  mock.patch.object(screen_studio, "apply_compressed"),
                  mock.patch.object(screen_studio, "apply_palettes"),
                  mock.patch.object(screen_studio, "render", return_value=[]) as render):
                screen_studio.stage_preview(
                    ROOT, "jp", staged, screen, {}, {}, "story_background", stage)
                self.assertEqual(bytes(1024),
                                 decompress(labelled_blocks(staged)[0][name]))
                render.assert_called_once()
                with self.assertRaisesRegex(ValueError, "conflicting staged RAM-map edits"):
                    screen_studio.stage_preview(
                        ROOT, "jp", staged, conflicting, {}, {},
                        "story_background", stage)


if __name__ == "__main__":
    unittest.main()
