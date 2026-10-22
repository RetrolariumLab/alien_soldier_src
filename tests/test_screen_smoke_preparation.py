"""Real private staging/read guards with explicit screen/model-render seams."""

from contextlib import ExitStack, contextmanager
import os
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from authoring import screen_studio as studio
from authoring import stage_tilemap_model as parsed


def image(value):
    return [[(value, 0, 0)] * 32 for _ in range(32)]


class ScreenSmokePreparationTests(unittest.TestCase):
    @contextmanager
    def fixture(self, fault=None):
        with tempfile.TemporaryDirectory(prefix="screen-smoke-preparation-") as temporary, ExitStack() as stack:
            root = Path(temporary).resolve()
            (root / "src").mkdir()
            (root / "data").mkdir()
            (root / "src/main.s").write_bytes(b'Blob: binclude "data/blob.bin"\n')
            (root / "data/blob.bin").write_bytes(b"\x01")
            maps = {"payloads": [{"values": [0], "value_bits": 8}]}
            records = [
                {"id": name, "width": 32, "height": 32}
                for name in ("title_background", "story_background", "options_background")
            ]
            copies, renders, operations, validations, writes = [], [], [], [], []
            actual_stage = studio.stage_tree

            def stage(project, destination):
                self.assertEqual(root, project)
                copies.append(destination)
                return actual_stage(project, destination)

            def write(destination, value, role):
                self.assertTrue(destination.is_relative_to(root / "build/content/screen-smoke"))
                (destination / "data/blob.bin").write_bytes(bytes([value]))
                writes.append((destination, role, value))

            def apply_map(document, destination, profile, *, validation_root):
                self.assertEqual((root, "jp"), (validation_root, profile))
                self.assertEqual(b"\x01", parsed.labelled_blocks(root)[0]["Blob"])
                write(destination, 5 + document["payloads"][0]["values"][0], "map")

            def validate(document, authority, profile):
                self.assertEqual((root, "jp"), (authority, profile))
                validations.append(document["payloads"][0]["values"][0])

            def render(destination, profile, identifier, **kwargs):
                self.assertEqual(("jp", {"config_root": root, "with_scene": True}), (profile, kwargs))
                operation = parsed._PARSED_OPERATION.get()
                self.assertIsNotNone(operation)
                self.assertEqual(destination, operation.requested_root)
                operations.append(operation)
                value = parsed.labelled_blocks(destination)[0]["Blob"][0]
                renders.append((destination, identifier, value))
                record = next(row for row in records if row["id"] == identifier)
                scene = SimpleNamespace(tilemap=None, plane_b=SimpleNamespace(ram=bytes([value])))
                if fault == "late" and len(renders) == 2:
                    path = destination / "data/blob.bin"
                    before = path.stat()
                    path.write_bytes(b"\x09")
                    os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
                if fault == "dimensions" and len(renders) == 1:
                    return image(value)[:-1], scene, record
                if fault == "unchanged" and value == 6:
                    return image(5), scene, record
                return image(value), scene, record

            def sources(destination, scene):
                self.assertEqual(b"\x05", parsed.labelled_blocks(destination)[0]["Blob"])
                self.assertEqual(b"\x05", scene.plane_b.ram)
                return {"Blob": b"\x05"}

            def replay(*args):
                self.assertEqual(1, args[4]["payloads"][0]["values"][0])
                value = 7 if fault == "replay" else 6
                return image(value), SimpleNamespace(plane_b=SimpleNamespace(ram=bytes([value])))

            def locate(scene, record, *args):
                if fault == "after_last" and record["id"] == "options_background":
                    baseline = copies[0] / "data/blob.bin"
                    before = baseline.stat()
                    baseline.write_bytes(b"\x09")
                    os.utime(baseline, ns=(before.st_atime_ns, before.st_mtime_ns))
                if fault == "after_last_empty" and record["id"] == "options_background":
                    (copies[0] / "data/new_empty_directory").mkdir()
                return SimpleNamespace(cell=SimpleNamespace(payload_index=0, value_index=0))

            stack.enter_context(
                mock.patch.object(studio, "load_context", return_value=({}, None, maps, {}, {}, None, {}))
            )
            stack.enter_context(mock.patch.object(studio, "load_config", return_value={"supported": records}))
            stack.enter_context(mock.patch.object(studio, "stage_tree", side_effect=stage))
            stack.enter_context(
                mock.patch.object(
                    studio,
                    "apply_compressed",
                    side_effect=lambda document, destination, profile: write(destination, 2, "art"),
                )
            )
            stack.enter_context(
                mock.patch.object(
                    studio,
                    "apply_palettes",
                    side_effect=lambda document, destination, profile: write(destination, 3, "palette"),
                )
            )
            stack.enter_context(
                mock.patch.object(
                    studio,
                    "apply_stage_maps",
                    side_effect=lambda document, destination, profile, **kwargs: write(destination, 4, "stage"),
                )
            )
            stack.enter_context(mock.patch.object(studio, "apply_maps", side_effect=apply_map))
            stack.enter_context(mock.patch.object(studio, "validate_maps", side_effect=validate))
            stack.enter_context(mock.patch.object(studio, "render", side_effect=render))
            stack.enter_context(mock.patch.object(studio, "locate_screen_map_cell", side_effect=locate))
            stack.enter_context(mock.patch.object(studio, "read_ram_sources", side_effect=sources))
            stack.enter_context(mock.patch.object(studio, "replay_screen_maps", side_effect=replay))
            stack.enter_context(mock.patch.object(studio, "export_maps", return_value=maps))
            stack.enter_context(mock.patch.object(studio, "export_stage_maps", return_value={}))
            yield SimpleNamespace(
                root=root, copies=copies, renders=renders, operations=operations, validations=validations, writes=writes
            )

    def test_two_preparations_keep_every_fresh_render_and_an_unmodified_later_screen(self):
        with self.fixture() as f:
            studio.check(f.root, "jp")
            baseline = f.root / "build/content/screen-smoke/jp/tree"
            edited = f.root / "build/content/screen-smoke/jp/edited/tree"
            self.assertEqual([baseline, edited], f.copies)
            self.assertEqual(
                [
                    (baseline, "title_background", 5),
                    (baseline, "story_background", 5),
                    (edited, "story_background", 6),
                    (baseline, "options_background", 5),
                ],
                f.renders,
            )
            self.assertEqual(["art", "palette", "stage", "map"] * 2, [role for _, role, _ in f.writes])
            self.assertEqual([0, 1], f.validations)
            self.assertEqual(4, len({id(operation) for operation in f.operations}))
            self.assertTrue(all(operation.closed for operation in f.operations))
            self.assertEqual(b"\x01", (f.root / "data/blob.bin").read_bytes())
            self.assertEqual(b"\x05", (baseline / "data/blob.bin").read_bytes())
            self.assertEqual(b"\x06", (edited / "data/blob.bin").read_bytes())
            self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_original_prepared_bytes_and_census_close_during_and_after_all_renders(self):
        for fault, preparations, renders, message in (
            ("late", 1, 2, "raw file changed"),
            ("after_last", 2, 4, "raw file changed"),
            ("after_last_empty", 2, 4, "directory inventory changed"),
        ):
            with self.subTest(fault=fault), self.fixture(fault) as f:
                with self.assertRaisesRegex(ValueError, message):
                    studio.check(f.root, "jp")
                self.assertEqual((preparations, renders), (len(f.copies), len(f.renders)))
                self.assertTrue(all(operation.closed for operation in f.operations))
                self.assertEqual(b"\x01", (f.root / "data/blob.bin").read_bytes())
                self.assertIsNone(parsed._PARSED_OPERATION.get())

    def test_original_dimension_edit_and_replay_failures_still_stop_the_check(self):
        for fault, message, preparations, renders in (
            ("dimensions", "screen preview dimensions differ", 1, 1),
            ("unchanged", "screen-space map edit did not affect story preview", 2, 3),
            ("replay", "in-memory map replay differs from staged story preview", 2, 3),
        ):
            with self.subTest(fault=fault), self.fixture(fault) as f:
                with self.assertRaisesRegex(ValueError, message):
                    studio.check(f.root, "jp")
                self.assertEqual((preparations, renders), (len(f.copies), len(f.renders)))
                self.assertTrue(all(operation.closed for operation in f.operations))
                self.assertEqual(b"\x01", (f.root / "data/blob.bin").read_bytes())
                self.assertIsNone(parsed._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
