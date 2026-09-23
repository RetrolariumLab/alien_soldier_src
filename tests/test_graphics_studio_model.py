from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "scripts")]

from authoring import graphics_studio_model as model  # noqa: E402


def graphics_tree() -> Path:
    destination = Path(tempfile.mkdtemp())
    shutil.copytree(ROOT / model.ART_DIRECTORY, destination / model.ART_DIRECTORY)
    return destination


class BaselineTests(unittest.TestCase):
    def test_both_profiles_have_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], model.round_trip_errors(ROOT, "jp"))
        self.assertEqual([], model.round_trip_errors(ROOT, "eu"))

    def test_current_inventory_is_derived_from_every_payload(self) -> None:
        document = model.export_document(ROOT, "jp")
        self.assertEqual(289, document["payload_count"])
        self.assertEqual(3230, document["tile_count"])
        self.assertEqual(289, len(document["payloads"]))
        self.assertEqual(
            {"bare": 31, "chain-1": 256, "chain-2": 2},
            {
                kind: sum(
                    1 for item in document["payloads"]
                    if (kind == "bare" and not item["blocks"][0]["declared_length"])
                    or (kind.startswith("chain-")
                        and item["blocks"][0]["declared_length"]
                        and len(item["blocks"]) == int(kind.split("-")[1]))
                )
                for kind in ("bare", "chain-1", "chain-2")
            },
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

    def test_profile_inventory_and_capacity_cannot_be_relabelled(self) -> None:
        self.document["profile"] = "eu"
        self.document["payloads"] = self.document["payloads"][1:]
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertIn("profile differs from the source-owned value", errors)
        self.assertIn("payload inventory differs from the source", errors)

    def test_tiles_are_exactly_sixty_four_uppercase_nibbles(self) -> None:
        tile = self.document["payloads"][0]["blocks"][0]["tiles"][0]
        self.document["payloads"][0]["blocks"][0]["tiles"][0] = tile[:-1] + "g"
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("64 uppercase nibbles" in error for error in errors))

    def test_block_shape_and_tile_count_are_fixed(self) -> None:
        block = self.document["payloads"][0]["blocks"][0]
        block["declared_length"] = not block["declared_length"]
        block["tiles"].append(block["tiles"][0])
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("declared_length differs" in error for error in errors))
        self.assertTrue(any("tile count differs" in error for error in errors))


class StagedApplicationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tree = graphics_tree()

    def tearDown(self) -> None:
        shutil.rmtree(self.tree, ignore_errors=True)

    def test_one_pixel_edit_changes_only_one_fixed_size_staged_payload(self) -> None:
        document = model.export_document(self.tree, "jp")
        record = document["payloads"][0]
        tile = record["blocks"][0]["tiles"][0]
        replacement = "%X" % ((int(tile[0], 16) + 1) & 0x0F)
        record["blocks"][0]["tiles"][0] = replacement + tile[1:]
        path = self.tree / record["path"]
        before_size = path.stat().st_size
        self.assertEqual([record["path"]], model.apply_document(document, self.tree, "jp"))
        self.assertEqual(before_size, path.stat().st_size)
        reread = model.export_document(self.tree, "jp")
        changed = next(item for item in reread["payloads"] if item["name"] == record["name"])
        self.assertEqual(replacement + tile[1:], changed["blocks"][0]["tiles"][0])
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))


if __name__ == "__main__":
    unittest.main()
