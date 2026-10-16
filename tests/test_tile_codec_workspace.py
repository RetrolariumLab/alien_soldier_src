"""Fixed-slot tile-codec writes and edit-preserving graphics migration."""

from __future__ import annotations

from contextlib import ExitStack
from copy import deepcopy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import compressed_graphics_model as model  # noqa: E402
from authoring.content_workspace import initialize, stage_tree  # noqa: E402
from authoring.screen_studio_model import render  # noqa: E402
from authoring.lzss_codec import compress as encode_lzss  # noqa: E402
from authoring.tile_codec import decompress as decode_tiles, pack_tile  # noqa: E402
from tests.test_tile_codec_edit import marker_fixture  # noqa: E402


class TileWorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.paths = {"FixtureLZSS": "lzss.bin", "FixtureTile": "tile.bin",
                      "Credits_SegaMappingData": "mapping.bin"}
        originals = {"FixtureLZSS": encode_lzss(bytes(32)),
                     "FixtureTile": marker_fixture(),
                     "Credits_SegaMappingData": encode_lzss(bytes(408))}
        for name, path in self.paths.items():
            (self.root / path).write_bytes(originals[name])
        stack = ExitStack()
        self.addCleanup(stack.close)
        stack.enter_context(mock.patch.object(model, "source_paths", return_value=self.paths))
        stack.enter_context(mock.patch.object(model, "source_owners", return_value={}))
        stack.enter_context(mock.patch.object(model, "vram_sources", side_effect=
            lambda _root, command_ids=(7,): {"FixtureTile"} if command_ids == (2, 3)
            else {"FixtureLZSS", "Credits_SegaMappingData"}))
        stack.enter_context(mock.patch.object(model, "labelled_blocks", side_effect=
            lambda root: ({name: (root / path).read_bytes()
                           for name, path in self.paths.items()}, {})))

    def legacy(self, profile):
        baseline = model.export_document(self.root, profile)
        records = [deepcopy(record) for record in baseline["payloads"] if record["codec"] == "lzss"]
        for record in records:
            del record["codec"]
        result = {**baseline, "schema_version": 1, "format": model.LEGACY_FORMAT,
                  "payloads": records, "payload_count": len(records)}
        for field in ("tile_count", "decoded_byte_count", "compressed_capacity"):
            result[field] = sum(record[field] for record in records)
        return result

    def test_zero_edit_changes_no_staged_file_for_either_profile(self):
        before = {path: (self.root / path).read_bytes() for path in self.paths.values()}
        for profile in ("jp", "eu"):
            document = model.export_document(self.root, profile)
            self.assertEqual([], model.apply_document(document, self.root, profile))
        self.assertEqual(before, {path: (self.root / path).read_bytes() for path in before})

    def test_tile_edit_changes_only_its_owned_fixed_slot_and_reopens(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                (self.root / "tile.bin").write_bytes(marker_fixture())
                baseline = model.export_document(self.root, profile)
                document = deepcopy(baseline)
                record = next(item for item in document["payloads"] if item["codec"] == "tile-codec")
                record["blocks"][0]["tiles"][0] = "7" + "4" * 7 + "7" * 56
                before_lzss = (self.root / "lzss.bin").read_bytes()
                self.assertEqual(["tile.bin"], model.apply_document(document, self.root, profile))
                body = (self.root / "tile.bin").read_bytes()
                self.assertEqual(record["compressed_capacity"], len(body))
                self.assertEqual(pack_tile([7] + [4] * 7 + [7] * 56), decode_tiles(body))
                self.assertEqual(before_lzss, (self.root / "lzss.bin").read_bytes())
                reopened = model.export_document(self.root, profile)
                self.assertEqual(record["blocks"], next(item for item in reopened["payloads"]
                                                       if item["codec"] == "tile-codec")["blocks"])

    def test_unfitting_edit_is_rejected_before_any_slot_is_written(self):
        document = model.export_document(self.root, "jp")
        record = next(item for item in document["payloads"] if item["codec"] == "tile-codec")
        record["blocks"][0]["tiles"][0] = "0123456789ABCDEF" * 4
        before = (self.root / "tile.bin").read_bytes()
        with self.assertRaisesRegex(ValueError, "exceeds fixed capacity"):
            model.apply_document(document, self.root, "jp")
        self.assertEqual(before, (self.root / "tile.bin").read_bytes())

    def test_legacy_migration_retains_lzss_edits_and_adds_source_tiles(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = self.legacy(profile)
                document["payloads"][0]["blocks"][0]["tiles"][0] = "1" * 64
                before = deepcopy(document)
                migrated = model.upgrade_legacy_document(document, self.root, profile)
                self.assertEqual(before, document)
                self.assertEqual(2, migrated["schema_version"])
                self.assertEqual(2, migrated["payload_count"])
                self.assertEqual("1" * 64, next(record for record in migrated["payloads"]
                                               if record["codec"] == "lzss")["blocks"][0]["tiles"][0])
                model.validate_document(migrated, self.root, profile)
                path = self.root / "legacy.json"
                path.write_text(json.dumps(document), encoding="utf-8")
                self.assertEqual(migrated, model.load_document(path, self.root, profile))
                self.assertEqual(document, json.loads(path.read_text(encoding="utf-8")))

    def test_bad_legacy_metadata_and_inventory_never_migrate(self):
        baseline = self.legacy("jp")
        variants = []
        for field in ("schema_version", "payload_count", "tile_count", "compressed_capacity"):
            document = deepcopy(baseline)
            document[field] = float(document[field])
            variants.append(document)
        document = deepcopy(baseline)
        document["payloads"].append(deepcopy(document["payloads"][0]))
        variants.append(document)
        document = deepcopy(baseline)
        document["payloads"][0]["path"] = "some_other_file.bin"
        variants.append(document)
        for document in variants:
            with self.subTest(document=document):
                with self.assertRaises(ValueError):
                    model.upgrade_legacy_document(document, self.root, "jp")

    def test_nonforcing_initialization_persists_migration_without_losing_edits(self):
        manifest = {"workspace": "content/workspace", "workspace_document": "workspace.json",
                    "profile_records": {"jp": {"status": "supported", "reference_rom": {
                        "size": 8, "sha1": "1" * 40, "sha256": "2" * 64}}},
                    "artifacts": [{"id": "compressed_tile_art", "kind": "compressed_tile_document",
                                   "profiles": ["jp"], "workspace": "graphics/compressed.json"}]}
        path = self.root / "content/workspace/jp/graphics/compressed.json"
        path.parent.mkdir(parents=True)
        document = self.legacy("jp")
        document["payloads"][0]["blocks"][0]["tiles"][0] = "1" * 64
        path.write_text(json.dumps(document), encoding="utf-8")
        self.assertTrue(initialize(self.root, manifest, "jp"))
        migrated = model.load_document(path)
        self.assertEqual(2, migrated["schema_version"])
        self.assertEqual("1" * 64, next(record for record in migrated["payloads"]
                                       if record["codec"] == "lzss")["blocks"][0]["tiles"][0])
        previous = path.read_bytes()
        self.assertFalse(initialize(self.root, manifest, "jp"))
        self.assertEqual(previous, path.read_bytes())


class CartridgeStagingTests(unittest.TestCase):
    def test_source_tile_edit_reaches_the_title_preview_for_jp_and_eu(self):
        # One staged tree and one 320x224 composition at a time; no periodic
        # map traversal, assembler, emulator or user workspace writes.
        base = ROOT / "build/content"
        base.mkdir(parents=True, exist_ok=True)
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = model.export_document(ROOT, profile)
                record = next(item for item in document["payloads"]
                              if item["name"] == "SharedTitleAndOptionsType3DataA")
                canonical = ROOT / record["path"]
                original = canonical.read_bytes()
                original_image = render(ROOT, profile, "title_background")
                record["blocks"][0]["tiles"] = [
                    "".join("%X" % (int(pixel, 16) ^ 1) for pixel in tile)
                    for tile in record["blocks"][0]["tiles"]]
                with tempfile.TemporaryDirectory(prefix="tilecodec-smoke-", dir=base) as directory:
                    tree = Path(directory) / profile / "tree"
                    stage_tree(ROOT, tree)
                    self.assertEqual([record["path"]], model.apply_document(document, tree, profile))
                    staged = (tree / record["path"]).read_bytes()
                    self.assertEqual(len(original), len(staged))
                    self.assertEqual(model.payload_plain(record), decode_tiles(staged))
                    edited_image = render(tree, profile, "title_background", config_root=ROOT)
                    changed = sum(a != b for row_a, row_b in zip(original_image, edited_image)
                                  for a, b in zip(row_a, row_b))
                    self.assertGreater(changed, 0)
                    print("[OK] %s tile-codec staged title: %d changed RGB pixels" % (profile, changed))
                self.assertEqual(original, canonical.read_bytes())


if __name__ == "__main__":
    unittest.main()
