from __future__ import annotations

import copy
import hashlib
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import animation_preview_model as model
from authoring import mapping_studio_model as mappings
from tests.test_animation_pointer_domains import fixture, selected


class UnsavedMappingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        fixture(self.root)
        (self.root / model.SOURCE).write_text((ROOT / model.SOURCE).read_text(encoding="utf-8"), encoding="utf-8")
        self.animation = model.workspace.export_document(self.root, "jp")
        self.mapping = mappings.export_document(self.root, "jp")

    def build(self):
        return model.build_catalog(self.root, "jp", self.animation, mapping_document=self.mapping)

    def first(self):
        return next(block for block in self.mapping["blocks"]
                    if block["name"] == "FirstSpriteMapping")["mappings"][0]

    def test_duration_and_geometry_edits_share_one_immutable_unsaved_snapshot(self):
        piece = self.first()["pieces"][0]
        piece.update(x=-11, y=13, size=10, link=7, attributes=0xA004)
        selected(self.animation, "FirstAnimation")["frames"][0]["duration"] = 5
        catalog = self.build()
        observed = model.step(catalog, model.PlaybackState(model.Cursor("FirstAnimation")), model.CallerState(0xE0))
        self.assertEqual(5, observed.after.timer)
        self.assertEqual((-11, 13, 24, 24), observed.geometry.bounds)
        self.assertEqual((0xA004, 10, 7), tuple(getattr(observed.geometry.pieces[0], key)
                                            for key in ("attributes", "size", "link")))
        piece["x"] = 70
        selected(self.animation, "FirstAnimation")["frames"][0]["duration"] = 9
        self.assertEqual(-11, catalog.mappings["FirstSpriteMapping"].pieces[0].x)
        self.assertEqual(5, catalog.scripts["FirstAnimation"][0].duration)
        self.assertFalse(catalog.proof["runtime_fidelity_verified"])
        self.assertTrue(catalog.proof["unsaved_mapping_document_supplied"])

    def test_retarget_uses_edited_destination_not_stale_source_geometry(self):
        selected(self.animation, "FirstAnimation")["frames"][0]["target"] = "SecondSpriteMapping"
        block = next(block for block in self.mapping["blocks"] if block["name"] == "SecondSpriteMapping")
        block["mappings"][0]["pieces"][0]["x"] = 23
        observed = model.step(self.build(), model.PlaybackState(model.Cursor("FirstAnimation")), model.CallerState(0xE0))
        self.assertEqual("SecondSpriteMapping", observed.geometry.symbol)
        self.assertEqual(23, observed.geometry.pieces[0].x)

    def test_build_is_read_only_for_every_source_and_cartridge(self):
        paths = [path for path in self.root.rglob("*") if path.is_file()]
        before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
        self.first()["pieces"][0]["x"] = 17
        self.build()
        self.assertEqual(before, {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in paths})

    def test_wrong_profile_partial_and_duplicate_documents_are_rejected(self):
        original = copy.deepcopy(self.mapping)
        for change in (lambda doc: doc.update(profile="eu"),
                       lambda doc: doc["blocks"].pop(),
                       lambda doc: doc["blocks"].append(copy.deepcopy(doc["blocks"][0]))):
            self.mapping = copy.deepcopy(original)
            change(self.mapping)
            with self.assertRaises(ValueError):
                self.build()

    def test_bool_numeric_aliases_and_unhashable_inventory_are_not_accepted(self):
        original = copy.deepcopy(self.mapping)
        for change in (lambda doc: doc.update(schema_version=True),
                       lambda doc: doc["blocks"][0].update(name=[]),
                       lambda doc: doc["blocks"][0]["mappings"][0].update(offset=False),
                       lambda doc: doc["blocks"][0]["mappings"][0].update(dynamic=0),
                       lambda doc: doc["blocks"][0]["mappings"][0]["pieces"][0].update(index=False),
                       lambda doc: doc["blocks"][0]["mappings"][0]["pieces"][0].update(art_addend=False)):
            self.mapping = copy.deepcopy(original)
            change(self.mapping)
            with self.assertRaises(ValueError):
                self.build()

    def test_terminator_coordinates_and_source_art_ownership_remain_fixed(self):
        original = copy.deepcopy(self.mapping)
        for edit in ({"attributes": 0}, {"x": 128}, {"y": True}, {"art": "InventedArt"}, {"art_addend": 1}):
            self.mapping = copy.deepcopy(original)
            self.first()["pieces"][0].update(edit)
            with self.assertRaises(ValueError):
                self.build()

    def test_dynamic_geometry_is_validated_but_not_played_by_static_reader(self):
        catalog = self.build()
        with self.assertRaisesRegex(model.UnsupportedPlayback, "eight-byte dynamic"):
            model.step(catalog, model.PlaybackState(model.Cursor("DynamicAnimation")), model.CallerState(0xE0))


class CanonicalWorkspaceTests(unittest.TestCase):
    def test_packed_mapping_reorder_cannot_disagree_with_staged_first_record(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = mappings.export_document(ROOT, profile)
                packed = next(block for block in document["blocks"] if block["name"] == "SharedCombatSpriteFrame34")
                self.assertEqual([0, 6], [mapping["offset"] for mapping in packed["mappings"]])
                packed["mappings"].reverse()
                with self.assertRaisesRegex(ValueError, "packed record order"):
                    model.build_catalog(ROOT, profile, mapping_document=document)

    def test_both_profiles_keep_exact_non_editor_targets_and_edited_bird_geometry(self):
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile):
                document = mappings.export_document(ROOT, profile)
                bird = next(block for block in document["blocks"] if block["name"] == "Enemy_BirdSpriteMapping00")
                bird["mappings"][0]["pieces"][0]["y"] = 21
                catalog = model.build_catalog(ROOT, profile, mapping_document=document)
                self.assertEqual(272, len(catalog.mappings))
                self.assertEqual(270, catalog.proof["mapping_editor_targets_applied"])
                self.assertEqual(21, catalog.mappings["Enemy_BirdSpriteMapping00"].pieces[0].y)
                self.assertTrue(catalog.mappings["Projectile_BugmaxSpreadFrame00"].pieces)
                self.assertTrue(catalog.mappings["Projectile_BugmaxSpreadFrame01"].pieces)
                self.assertFalse(catalog.proof["compiled_reader_verified"])
                self.assertFalse(catalog.proof["native_run"])


if __name__ == "__main__":
    unittest.main()
