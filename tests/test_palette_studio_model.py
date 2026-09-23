from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import palette_studio_model as model  # noqa: E402
from authoring.palette_model import read_source  # noqa: E402


def palette_tree() -> Path:
    destination = Path(tempfile.mkdtemp())
    source = destination / model.PALETTE_SOURCE
    source.parent.mkdir(parents=True)
    shutil.copy2(ROOT / model.PALETTE_SOURCE, source)
    blocks, _ = read_source(ROOT)
    for block in blocks.values():
        if block.storage != "payload":
            continue
        payload = destination / block.payload
        payload.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / block.payload, payload)
    return destination


class BaselineTests(unittest.TestCase):
    def test_both_profiles_have_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], model.round_trip_errors(ROOT, "jp"))
        self.assertEqual([], model.round_trip_errors(ROOT, "eu"))

    def test_inventory_exposes_all_fixed_commands_and_offset_lists(self) -> None:
        document = model.export_document(ROOT, "jp")
        self.assertEqual(55, document["block_count"])
        self.assertEqual(95, document["command_count"])
        self.assertEqual(29, document["offset_list_count"])
        self.assertEqual(95, len(document["commands"]))
        self.assertEqual(29, len(document["offset_lists"]))
        self.assertEqual(
            {"payload", "source"},
            {record["storage"] for record in document["commands"]},
        )

    def test_original_raw_cram_bus_words_are_preserved(self) -> None:
        document = model.export_document(ROOT, "jp")
        words = [word for record in document["commands"] for word in record["colours"]]
        self.assertIn(0xFFFF, words)
        model.validate_document(document, ROOT, "jp")

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

    def test_profile_and_fixed_command_shape_cannot_be_relabelled(self) -> None:
        record = self.document["commands"][0]
        self.document["profile"] = "eu"
        record["destination"] += 2
        record["colours"].append(0)
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertIn("profile differs from the source-owned value", errors)
        self.assertTrue(any("destination differs" in error for error in errors))
        self.assertTrue(any("fixed capacity" in error for error in errors))

    def test_colours_must_remain_unsigned_words(self) -> None:
        record = self.document["commands"][0]
        record["colours"][0] = 0x10000
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("not an unsigned word" in error for error in errors))

    def test_offset_lists_remain_source_owned(self) -> None:
        self.document["offset_lists"][0]["entries"].pop()
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertIn("offset_lists differs from the source-owned value", errors)


class StagedApplicationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tree = palette_tree()

    def tearDown(self) -> None:
        shutil.rmtree(self.tree, ignore_errors=True)

    def change_first_colour(self, record: dict) -> int:
        replacement = (record["colours"][0] + 2) & 0xFFFF
        record["colours"][0] = replacement
        return replacement

    def test_source_command_edit_changes_only_the_palette_source(self) -> None:
        document = model.export_document(self.tree, "jp")
        record = next(item for item in document["commands"] if item["storage"] == "source")
        replacement = self.change_first_colour(record)
        before_size = (self.tree / model.PALETTE_SOURCE).stat().st_size
        self.assertEqual(
            [model.PALETTE_SOURCE.as_posix()],
            model.apply_document(document, self.tree, "jp"),
        )
        self.assertEqual(before_size, (self.tree / model.PALETTE_SOURCE).stat().st_size)
        reread = model.export_document(self.tree, "jp")
        changed = next(item for item in reread["commands"] if item["label"] == record["label"])
        self.assertEqual(replacement, changed["colours"][0])
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))

    def test_payload_command_edit_keeps_its_binary_capacity(self) -> None:
        document = model.export_document(self.tree, "jp")
        record = next(item for item in document["commands"] if item["storage"] == "payload")
        replacement = self.change_first_colour(record)
        path = self.tree / record["source_path"]
        before_size = path.stat().st_size
        self.assertEqual(
            [record["source_path"]], model.apply_document(document, self.tree, "jp")
        )
        self.assertEqual(before_size, path.stat().st_size)
        reread = model.export_document(self.tree, "jp")
        changed = next(item for item in reread["commands"] if item["label"] == record["label"])
        self.assertEqual(replacement, changed["colours"][0])
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))


if __name__ == "__main__":
    unittest.main()
