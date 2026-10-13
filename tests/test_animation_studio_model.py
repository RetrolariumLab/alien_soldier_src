from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import animation_studio_model as model  # noqa: E402


def animation_tree() -> Path:
    destination = Path(tempfile.mkdtemp())
    document = model.export_document(ROOT, "jp")
    for relative in sorted({record["source_path"] for record in document["scripts"]}):
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, target)
    return destination


class BaselineTests(unittest.TestCase):
    def test_both_profiles_have_a_zero_edit_round_trip(self) -> None:
        self.assertEqual([], model.round_trip_errors(ROOT, "jp"))
        self.assertEqual([], model.round_trip_errors(ROOT, "eu"))

    def test_inventory_is_fixed_and_source_derived(self) -> None:
        document = model.export_document(ROOT, "jp")
        self.assertEqual(112, document["script_count"])
        self.assertEqual(670, document["frame_count"])
        self.assertEqual(63, document["jump_count"])
        self.assertEqual(272, len(document["frame_targets"]))
        self.assertEqual(17, len({record["source_path"] for record in document["scripts"]}))

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

    def test_script_capacity_and_jump_roles_are_source_owned(self) -> None:
        record = self.document["scripts"][0]
        record["frames"].append(dict(record["frames"][0]))
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("fixed capacity" in error for error in errors))
        self.document = model.export_document(ROOT, "jp")
        jump = next(
            frame for record in self.document["scripts"] for frame in record["frames"]
            if frame["jump"]
        )
        jump["duration"] = 1
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("zero-duration jump role" in error for error in errors))

    def test_targets_must_keep_their_proved_runtime_role(self) -> None:
        frame = next(
            frame for record in self.document["scripts"] for frame in record["frames"]
            if not frame["jump"]
        )
        frame["target"] = "InventedMapping"
        errors = model.document_errors(self.document, ROOT, "jp")
        self.assertTrue(any("proved frame mapping" in error for error in errors))


class StagedApplicationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tree = animation_tree()

    def tearDown(self) -> None:
        shutil.rmtree(self.tree, ignore_errors=True)

    def test_duration_edit_changes_only_the_owning_source(self) -> None:
        document = model.export_document(self.tree, "jp")
        record = next(
            item for item in document["scripts"]
            if any(not frame["jump"] and frame["duration"] < 0xFFFF
                   for frame in item["frames"])
        )
        frame = next(
            frame for frame in record["frames"]
            if not frame["jump"] and frame["duration"] < 0xFFFF
        )
        frame["duration"] += 1
        self.assertEqual(
            [record["source_path"]], model.apply_document(document, self.tree, "jp")
        )
        reread = model.export_document(self.tree, "jp")
        changed = next(item for item in reread["scripts"] if item["name"] == record["name"])
        self.assertEqual(frame["duration"], changed["frames"][frame["index"]]["duration"])
        self.assertEqual([], model.round_trip_errors(self.tree, "jp"))


if __name__ == "__main__":
    unittest.main()
