from __future__ import annotations

import copy
from contextlib import contextmanager
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import screen_map_model as model  # noqa: E402
from authoring import guarded_inventory as inventory  # noqa: E402
from authoring.stage_tilemap_model import parsed_operation  # noqa: E402
from authoring.screen_studio_model import build_scene, load_config, screen_record  # noqa: E402


def legacy_document(current):
    document = copy.deepcopy(current)
    for record in document["payloads"]:
        for use in record["uses"]:
            if use["screen"] == "story_background":
                use["plane"] = "plane_a"
                use["descriptor"] = "Gfx_DefaultVRAMTransferParameters"
    return document


class StoryMigrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Retain genuine original bytes/census BEFORE either regional model
        # expansion. These are fixture inputs, never a persisted PASS result.
        cls.original_inputs = {name: inventory.capture(ROOT / name,
            max_file=128 * 1024 * 1024, max_total=512 * 1024 * 1024,
            max_entries=32768) for name in ("src", "data", "config")}
        cls.addClassCleanup(cls.close_original_inputs)
        cls.enterClassContext(parsed_operation(ROOT))
        cls.current = {profile: model.export_document(ROOT, profile)
                       for profile in ("jp", "eu")}
        cls.close_original_inputs()

    @classmethod
    def close_original_inputs(cls):
        for name, original in cls.original_inputs.items():
            inventory.close(ROOT / name, original, max_file=128 * 1024 * 1024,
                            max_entries=32768)

    def setUp(self):
        if self._testMethodName == "test_other_metadata_mutations_and_extra_fields_are_rejected":
            self.enterContext(self.metadata_fixture())

    @contextmanager
    def metadata_fixture(self):
        """Only eight metadata negatives reuse genuine class-qualified models.

        The other six original methods retain fresh public model expansion.
        Every reused document is independent and bound to original raw inputs;
        close those same originals even when the test or producer raises.
        """
        def export(root, profile):
            if (Path(root).resolve() != ROOT.resolve() or type(profile) is not str
                    or profile not in ("jp", "eu")):
                raise ValueError("Story metadata fixture root/profile differs")
            self.close_original_inputs()
            return copy.deepcopy(self.current[profile])

        self.close_original_inputs()
        try:
            with mock.patch.object(model, "export_document", side_effect=export):
                yield
        finally:
            self.close_original_inputs()

    def test_both_original_documents_migrate_exactly_three_uses_and_no_values(self):
        for profile, current in self.current.items():
            with self.subTest(profile=profile):
                old = legacy_document(current)
                before = copy.deepcopy(old)
                migrated = model.migrate_story_plane(old, ROOT, profile)
                self.assertEqual(before, old)
                self.assertEqual(current, migrated)
                changed = [record["name"] for record, original in
                           zip(migrated["payloads"], old["payloads"], strict=True)
                           if record["uses"] != original["uses"]]
                self.assertEqual(["SharedMappingData7000", "StoryScreenMappingData4000",
                                  "StoryScreenMappingData6000"], changed)
                for record, original in zip(migrated["payloads"], old["payloads"], strict=True):
                    self.assertEqual(record["values"], original["values"])
                    self.assertEqual(record["compressed_capacity"], original["compressed_capacity"])
                self.assertEqual((8, 8744, 14544, 4836), tuple(migrated[field] for field in
                    ("payload_count", "value_count", "decoded_byte_count", "compressed_capacity")))

    def test_current_document_is_an_explicit_idempotent_copy(self):
        current = self.current["jp"]
        migrated = model.migrate_story_plane(current, ROOT, "jp")
        self.assertEqual(current, migrated)
        self.assertIsNot(current, migrated)
        self.assertIsNot(current["payloads"][0]["values"], migrated["payloads"][0]["values"])

    def test_valid_existing_user_map_edit_is_preserved_for_both_profiles(self):
        for profile, current in self.current.items():
            with self.subTest(profile=profile):
                old = legacy_document(current)
                record = next(item for item in old["payloads"]
                              if item["name"] == "StoryScreenMappingData6000")
                record["values"][0] = 1
                before = copy.deepcopy(old)
                migrated = model.migrate_story_plane(old, ROOT, profile)
                self.assertEqual(before, old)
                wanted = next(item for item in migrated["payloads"] if item["name"] == record["name"])
                self.assertEqual(record["values"], wanted["values"])
                model.validate_document(migrated, ROOT, profile)
                scene = build_scene(ROOT, profile, screen_record(load_config(ROOT), "story_background"))
                self.assertIsNone(scene.tilemap)
                self.assertEqual(0x6000, scene.plane_b.descriptor.plane_base)

    def test_new_invalid_reference_is_not_blessed_by_metadata_migration(self):
        old = legacy_document(self.current["jp"])
        record = next(item for item in old["payloads"] if item["name"] == "StoryScreenMappingData6000")
        record["values"][0] = 0xFF
        before = copy.deepcopy(old)
        with self.assertRaisesRegex(ValueError, "new undefined visible map reference"):
            model.migrate_story_plane(old, ROOT, "jp")
        self.assertEqual(before, old)

    def test_other_metadata_mutations_and_extra_fields_are_rejected(self):
        mutations = (
            lambda doc: doc.update(profile="eu"),
            lambda doc: doc.update(schema_version=True),
            lambda doc: doc.update(extra="not source-owned"),
            lambda doc: doc["payloads"][0].update(path="another/file.bin"),
            lambda doc: doc["payloads"][0].update(extra=42),
            lambda doc: doc["payloads"][0].update(compressed_capacity=9999),
            lambda doc: doc["payloads"][0]["uses"][0].update(base_value_index=True),
            lambda doc: doc["payloads"].pop(),
        )
        for mutation in mutations:
            old = legacy_document(self.current["jp"])
            mutation(old)
            before = copy.deepcopy(old)
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                model.migrate_story_plane(old, ROOT, "jp")
            self.assertEqual(before, old)

    def test_partial_or_arbitrary_story_use_remapping_is_rejected(self):
        for plane, descriptor in (("plane_b", "Gfx_DefaultVRAMTransferParameters"),
                                  ("plane_a", "Gfx_FrontendAlternateVRAMTransferParameters"),
                                  ("plane_b", "Gfx_ScrollVRAMTransferParameters")):
            old = legacy_document(self.current["jp"])
            record = next(item for item in old["payloads"] if item["name"] == "StoryScreenMappingData6000")
            record["uses"][0].update(plane=plane, descriptor=descriptor)
            with self.subTest(plane=plane, descriptor=descriptor), self.assertRaisesRegex(ValueError, "metadata"):
                model.migrate_story_plane(old, ROOT, "jp")

    def test_value_width_count_and_fixed_compressed_capacity_still_apply(self):
        for wrong in (True, -1, 256):
            old = legacy_document(self.current["jp"])
            record = next(item for item in old["payloads"] if item["name"] == "StoryScreenMappingData6000")
            record["values"][0] = wrong
            with self.subTest(wrong=wrong), self.assertRaisesRegex(ValueError, "unsigned 8-bit integer"):
                model.migrate_story_plane(old, ROOT, "jp")
        old = legacy_document(self.current["jp"])
        old["payloads"][0]["values"].pop()
        with self.assertRaisesRegex(ValueError, "value count"):
            model.migrate_story_plane(old, ROOT, "jp")


class MigrationCliTests(unittest.TestCase):
    def test_cli_writes_only_a_new_generated_copy_and_preserves_input(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "content/workspace/jp/screens/maps.json"
            source.parent.mkdir(parents=True)
            original = b'{"profile":"jp","payloads":[]}\n'
            source.write_bytes(original)
            output = root / "build/content/jp/story-migrated.json"
            args = ["screen_map_model.py", "migrate-story-plane", "--root", str(root),
                    "--profile", "jp", "--document", str(source), "--output", str(output)]
            migrated = {"profile": "jp", "payloads": [{"values": [7]}]}
            with mock.patch.object(sys, "argv", args), mock.patch.object(model, "migrate_story_plane", return_value=migrated):
                self.assertEqual(0, model.main())
            self.assertEqual(original, source.read_bytes())
            self.assertEqual(migrated, json.loads(output.read_text(encoding="utf-8")))
            previous = output.read_bytes()
            with mock.patch.object(sys, "argv", args), mock.patch.object(model, "migrate_story_plane") as migrate:
                self.assertEqual(1, model.main())
                migrate.assert_not_called()
            self.assertEqual(previous, output.read_bytes())

    def test_cli_refuses_other_region_or_workspace_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "maps.json"
            source.write_text("{}", encoding="utf-8")
            for destination in ("content/workspace/jp/screens/maps.json", "build/content/eu/migrated.json"):
                args = ["screen_map_model.py", "migrate-story-plane", "--root", str(root),
                        "--profile", "jp", "--document", str(source), "--output", destination]
                with self.subTest(destination=destination), mock.patch.object(sys, "argv", args):
                    self.assertEqual(1, model.main())
                self.assertEqual("{}", source.read_text(encoding="utf-8"))


class MetadataFixtureControls(unittest.TestCase):
    def test_metadata_fixture_binds_original_raw_inputs_and_independent_models_and_restores(self):
        # Tiny synthetic owners exercise the real inventory closer, without a
        # second genuine ROM/model expansion or writes to the project source.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ("src", "data", "config"):
                (root / name).mkdir()
                (root / name / "original.bin").write_bytes(b"original fixture bytes")
            originals = {name: inventory.capture(root / name, max_file=128,
                max_total=512, max_entries=16) for name in ("src", "data", "config")}

            def close():
                for name, original in originals.items():
                    inventory.close(root / name, original, max_file=128, max_entries=16)

            fixture = SimpleNamespace(current={profile: {"profile": profile, "nested": [[1]]}
                for profile in ("jp", "eu")}, close_original_inputs=close)
            producer = model.export_document
            with StoryMigrationTests.metadata_fixture(fixture):
                first = model.export_document(ROOT, "jp")
                first["nested"][0].append(2)
                self.assertEqual([[1]], model.export_document(ROOT, "jp")["nested"])
                self.assertEqual("eu", model.export_document(ROOT, "eu")["profile"])
                for owner, profile in ((ROOT / "foreign", "jp"), (ROOT, True), (ROOT, "foreign")):
                    with self.subTest(owner=owner, profile=profile), self.assertRaisesRegex(ValueError, "root/profile"):
                        model.export_document(owner, profile)
            self.assertIs(producer, model.export_document)
            for name in originals:
                path = root / name / "original.bin"
                try:
                    with self.subTest(late_owner=name), self.assertRaisesRegex(ValueError, "raw file changed"):
                        with StoryMigrationTests.metadata_fixture(fixture):
                            path.write_bytes(b"changed fixture bytes")
                            # Entry to any subsequent reused model must reject
                            # drift; context exit must reject the same original.
                            with self.assertRaisesRegex(ValueError, "raw file changed"):
                                model.export_document(ROOT, "jp")
                finally:
                    path.write_bytes(b"original fixture bytes")
                self.assertIs(producer, model.export_document)
                close()
            with self.assertRaisesRegex(RuntimeError, "synthetic method failure"):
                with StoryMigrationTests.metadata_fixture(fixture):
                    raise RuntimeError("synthetic method failure")
            self.assertIs(producer, model.export_document)
            close()


if __name__ == "__main__":
    unittest.main()
