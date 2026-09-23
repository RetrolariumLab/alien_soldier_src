from __future__ import annotations

import collections
import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import mapping_studio_model as model  # noqa: E402
from authoring.sprite_mapping_model import (  # noqa: E402
    EXCLUDED_MARKER,
    LAST_PIECE,
    NAME_MARKERS,
    labelled_blocks,
    read_blocks,
)


def mapping_tree() -> Path:
    destination = Path(tempfile.mkdtemp())
    blocks, _ = read_blocks(ROOT)
    for relative in sorted({block.source for block in blocks}):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    payloads = {block.payload for block in blocks if block.payload}
    for name, _source, tokens in labelled_blocks(ROOT):
        if not any(marker in name for marker in NAME_MARKERS):
            continue
        if EXCLUDED_MARKER in name and "Mapping" not in name:
            continue
        if {kind for kind, _ in tokens} == {"binclude"}:
            payloads.add(tokens[0][1].strip('"'))
    for relative in sorted(payloads):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    return destination


def first_piece(block: dict) -> dict:
    return block["mappings"][0]["pieces"][0]


def move_coordinate(piece: dict) -> int:
    replacement = piece["x"] - 1 if piece["x"] > -128 else piece["x"] + 1
    piece["x"] = replacement
    return replacement


class BaselineTests(unittest.TestCase):
    def test_both_profiles_have_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], model.round_trip_errors(ROOT, "jp"))
        self.assertEqual([], model.round_trip_errors(ROOT, "eu"))

    def test_inventory_covers_every_proved_storage_form(self) -> None:
        document = model.export_document(ROOT, "jp")
        self.assertEqual(764, document["block_count"])
        self.assertEqual(1169, document["mapping_count"])
        self.assertEqual(3566, document["piece_count"])
        self.assertEqual(1101, document["static_mapping_count"])
        self.assertEqual(68, document["dynamic_mapping_count"])
        self.assertEqual(
            {"bytes": 5, "dynamic": 68, "payload": 9, "words": 682},
            dict(collections.Counter(block["storage"] for block in document["blocks"])),
        )

    def test_serialized_document_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "first.json"
            second = Path(directory) / "second.json"
            model.atomic_write_json(first, model.export_document(ROOT, "jp"))
            model.atomic_write_json(second, model.export_document(ROOT, "jp"))
            self.assertEqual(first.read_bytes(), second.read_bytes())


class ValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.document = model.export_document(ROOT, "jp")

    def test_fixed_inventory_and_terminators_cannot_be_changed(self) -> None:
        block = self.document["blocks"][0]
        mapping = block["mappings"][0]
        mapping["pieces"].append(dict(mapping["pieces"][0]))
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("fixed capacity" in error for error in errors))
        self.document = model.export_document(ROOT, "jp")
        mapping = self.document["blocks"][0]["mappings"][0]
        mapping["pieces"][0]["attributes"] ^= LAST_PIECE
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("terminator bit" in error for error in errors))

    def test_piece_fields_are_bounded_by_the_encoded_widths(self) -> None:
        piece = first_piece(self.document["blocks"][0])
        piece["size"] = 0x100
        piece["x"] = -129
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("raw size" in error for error in errors))
        self.assertTrue(any("signed-byte bounds" in error for error in errors))

    def test_dynamic_art_shape_and_upload_offset_are_source_owned(self) -> None:
        block = next(item for item in self.document["blocks"] if item["storage"] == "dynamic")
        piece = first_piece(block)
        piece["size"] ^= 1
        piece["attributes"] ^= 1
        piece["art"] = "InventedArt"
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("dynamic art size" in error for error in errors))
        self.assertTrue(any("dynamic tile offset" in error for error in errors))
        self.assertTrue(any("art differs" in error for error in errors))

    def test_actual_packed_animation_targets_keep_their_exact_source_record_order(self) -> None:
        targets = {
            "SharedCombatSpriteFrame34": [0, 6],
            "SharedCombatSpriteFrame48": [0, 12, 36, 60],
            "SharedCombatSpriteFrame68": [0, 12],
            "SharedCombatSpriteFrame69": [0, 12],
            "Projectile_MissirayBulletSpriteFrame10": [0, 18],
        }
        for profile in ("jp", "eu"):
            document = model.export_document(ROOT, profile)
            model.validate_document(document, ROOT, profile)
            for name, offsets in targets.items():
                with self.subTest(profile=profile, target=name):
                    edited = copy.deepcopy(document)
                    block = next(item for item in edited["blocks"] if item["name"] == name)
                    self.assertEqual(offsets, [item["offset"] for item in block["mappings"]])
                    original_bytes = model._static_bytes(block)
                    block["mappings"].reverse()
                    self.assertNotEqual(original_bytes, model._static_bytes(block))
                    with self.assertRaisesRegex(ValueError, "packed record order"):
                        model.validate_document(edited, ROOT, profile)

    def test_independent_block_order_and_ordered_piece_edits_remain_valid(self) -> None:
        self.document["blocks"].reverse()
        block = next(item for item in self.document["blocks"]
                     if item["name"] == "SharedCombatSpriteFrame34")
        original_bytes = model._static_bytes(block)
        first_piece(block)["x"] = -3
        model.validate_document(self.document, ROOT, "jp")
        rebuilt = model._static_bytes(block)
        self.assertNotEqual(original_bytes[:6], rebuilt[:6])
        self.assertEqual(original_bytes[6:], rebuilt[6:])

    def test_equal_valued_numeric_metadata_aliases_are_rejected(self) -> None:
        original = copy.deepcopy(self.document)
        top_fields = ("schema_version", "block_count", "mapping_count", "piece_count",
                      "static_mapping_count", "dynamic_mapping_count", "payload_block_count", "excluded_count")
        changes = [(field, lambda doc, field=field: doc.update({field: float(doc[field])}))
                   for field in top_fields]
        changes.extend((
            ("boolean schema", lambda doc: doc.update(schema_version=True)),
            ("block count", lambda doc: doc["blocks"][0].update(
                mapping_count=float(doc["blocks"][0]["mapping_count"]))),
            ("block pieces", lambda doc: doc["blocks"][0].update(
                piece_count=float(doc["blocks"][0]["piece_count"]))),
            ("mapping offset", lambda doc: doc["blocks"][0]["mappings"][0].update(offset=False)),
            ("mapping count", lambda doc: doc["blocks"][0]["mappings"][0].update(
                piece_count=float(doc["blocks"][0]["mappings"][0]["piece_count"]))),
            ("dynamic role", lambda doc: doc["blocks"][0]["mappings"][0].update(dynamic=0)),
            ("piece index", lambda doc: first_piece(doc["blocks"][0]).update(index=False)),
            ("art addend", lambda doc: first_piece(doc["blocks"][0]).update(art_addend=False)),
        ))
        for description, change in changes:
            with self.subTest(field=description):
                edited = copy.deepcopy(original)
                change(edited)
                with self.assertRaises(ValueError):
                    model.validate_document(edited, ROOT, "jp")

    def test_malformed_unhashable_inventory_and_fields_raise_value_error(self) -> None:
        changes = (
            lambda doc: doc["blocks"][0].update(name=[]),
            lambda doc: doc["blocks"][0].update(name={}),
            lambda doc: doc["blocks"].__setitem__(0, None),
            lambda doc: doc["blocks"][0]["mappings"][0].update(offset=[]),
            lambda doc: doc["blocks"][0]["mappings"][0].update(offset={}),
            lambda doc: doc["blocks"][0]["mappings"].__setitem__(0, None),
            lambda doc: doc["blocks"][0]["mappings"][0].update(label=[]),
            lambda doc: doc["blocks"][0]["mappings"][0]["pieces"].__setitem__(0, None),
            lambda doc: first_piece(doc["blocks"][0]).update(art={}),
            lambda doc: first_piece(doc["blocks"][0]).update(art_addend=[]),
            lambda doc: first_piece(doc["blocks"][0]).update(x=[]),
        )
        for index, change in enumerate(changes):
            with self.subTest(mutant=index):
                edited = copy.deepcopy(self.document)
                change(edited)
                with self.assertRaises(ValueError):
                    model.validate_document(edited, ROOT, "jp")
        for document in (None, [], "not a mapping document"):
            with self.subTest(document=document), self.assertRaises(ValueError):
                model.validate_document(document, ROOT, "jp")


class StagedApplicationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tree = mapping_tree()

    def tearDown(self) -> None:
        shutil.rmtree(self.tree, ignore_errors=True)

    def assert_one_edit_round_trips(self, storage: str, expected_path: str) -> None:
        document = model.export_document(self.tree, "jp")
        block = next(item for item in document["blocks"] if item["storage"] == storage)
        piece = first_piece(block)
        replacement = move_coordinate(piece)
        self.assertEqual([expected_path], model.apply_document(document, self.tree, "jp"))
        reread = model.export_document(self.tree, "jp")
        changed = next(item for item in reread["blocks"] if item["name"] == block["name"])
        self.assertEqual(replacement, first_piece(changed)["x"])
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))

    def test_word_directive_edit_changes_only_its_source(self) -> None:
        document = model.export_document(self.tree, "jp")
        block = next(item for item in document["blocks"] if item["storage"] == "words")
        self.assert_one_edit_round_trips("words", block["source_path"])

    def test_dynamic_edit_preserves_its_symbolic_art_operand(self) -> None:
        document = model.export_document(self.tree, "jp")
        block = next(item for item in document["blocks"] if item["storage"] == "dynamic")
        self.assert_one_edit_round_trips("dynamic", block["source_path"])

    def test_payload_edit_keeps_the_binary_capacity(self) -> None:
        document = model.export_document(self.tree, "jp")
        block = next(item for item in document["blocks"] if item["storage"] == "payload")
        path = self.tree / block["payload_path"]
        size = path.stat().st_size
        self.assert_one_edit_round_trips("payload", block["payload_path"])
        self.assertEqual(size, path.stat().st_size)


if __name__ == "__main__":
    unittest.main()
