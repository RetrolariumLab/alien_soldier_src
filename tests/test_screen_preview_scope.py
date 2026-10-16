"""Tiny physical preview phase controls; no game assets, Tk or native tools."""

from contextlib import ExitStack
from copy import deepcopy
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from authoring import screen_studio as studio  # noqa: E402
from authoring import screen_studio_model as screen_model  # noqa: E402
from authoring import stage_tilemap_model as source  # noqa: E402


class ScreenPreviewScopeTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="screen-preview-scope-")
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name).resolve()
        self.root = self.base / "project"
        self.make_tree(self.root)
        self.destination = self.root / "build/content/preview/jp/tree"
        self.events, self.render_calls = [], []
        self.map_document, self.stage_document = {"fixture": "screen"}, {"fixture": "stage"}
        self.compressed, self.palettes = {"fixture": "art"}, {"fixture": "palette"}

    @staticmethod
    def make_tree(root):
        (root / "src/empty").mkdir(parents=True)
        (root / "data/empty").mkdir(parents=True)
        (root / "src/main.s").write_bytes(b'Blob: binclude "data/blob.bin"\n')
        (root / "data/blob.bin").write_bytes(b"\x01")

    def same_size_change(self, path):
        before = path.stat()
        original = path.read_bytes()
        path.write_bytes(bytes([original[0] ^ 1]) + original[1:])
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))
        self.assertEqual((before.st_size, before.st_mtime_ns),
                         (path.stat().st_size, path.stat().st_mtime_ns))

    def run_preview(self, *, stage_maps=True, with_scene=False,
                    map_callback=None, render_callback=None):
        def stage(project, destination):
            self.events.append("stage")
            self.assertEqual((self.root, self.destination), (project, destination))
            for name in ("src", "data"):
                shutil.copytree(project / name, destination / name)

        def write(document, destination, profile, expected, value, event):
            self.events.append(event)
            self.assertIs(expected, document)
            self.assertEqual((self.destination, "jp"), (destination, profile))
            (destination / "data/blob.bin").write_bytes(bytes([value]))

        def apply_stage(document, destination, profile, *, validation_root):
            self.assertEqual(self.root, validation_root)
            self.assertEqual(b"\x01", source.labelled_blocks(validation_root)[0]["Blob"])
            self.assertEqual(b"\x03", source.labelled_blocks(destination)[0]["Blob"])
            write(document, destination, profile, self.stage_document, 4, "stage_maps")

        def apply_map(document, destination, profile, *, validation_root):
            self.assertEqual(self.root, validation_root)
            self.assertEqual(b"\x01", source.labelled_blocks(validation_root)[0]["Blob"])
            self.assertEqual(bytes([4 if stage_maps else 3]),
                             source.labelled_blocks(destination)[0]["Blob"])
            write(document, destination, profile, self.map_document, 5, "maps")
            if map_callback:
                map_callback()

        def render(destination, profile, screen, **kwargs):
            self.events.append("render")
            self.render_calls.append((destination, profile, screen, kwargs))
            first = source.labelled_blocks(destination)[0]["Blob"]
            self.assertEqual(b"\x05", first)
            if render_callback:
                return render_callback(destination, first)
            self.assertEqual(first, source.labelled_blocks(destination)[0]["Blob"])
            result = (first, {"scene": "fixture"}, {"id": screen})
            return result if with_scene else first

        with ExitStack() as stack:
            stack.enter_context(mock.patch.object(studio, "stage_tree", side_effect=stage))
            stack.enter_context(mock.patch.object(studio, "apply_compressed", side_effect=
                lambda document, destination, profile: write(
                    document, destination, profile, self.compressed, 2, "compressed")))
            stack.enter_context(mock.patch.object(studio, "apply_palettes", side_effect=
                lambda document, destination, profile: write(
                    document, destination, profile, self.palettes, 3, "palettes")))
            stack.enter_context(mock.patch.object(studio, "apply_stage_maps", side_effect=apply_stage))
            stack.enter_context(mock.patch.object(studio, "apply_maps", side_effect=apply_map))
            stack.enter_context(mock.patch.object(studio, "render", side_effect=render))
            return studio.stage_preview(self.root, "jp", self.destination,
                self.map_document, self.compressed, self.palettes, "fixture_screen",
                self.stage_document if stage_maps else None, with_scene=with_scene)

    def test_read_phases_preserve_writer_order_scene_wire_and_one_primary_parse(self):
        with mock.patch.object(source, "_parse_labelled_blocks", wraps=source._parse_labelled_blocks) as parse:
            result = self.run_preview(with_scene=True)
        self.assertEqual((b"\x05", {"scene": "fixture"}, {"id": "fixture_screen"}), result)
        self.assertEqual(["stage", "compressed", "palettes", "stage_maps", "maps", "render"], self.events)
        self.assertEqual(1, sum(call.args[0] == self.root for call in parse.call_args_list))
        self.assertEqual(3, sum(call.args[0] == self.destination for call in parse.call_args_list))
        self.assertEqual([(self.destination, "jp", "fixture_screen",
                           {"config_root": self.root, "with_scene": True})], self.render_calls)
        self.assertEqual(b"\x01", (self.root / "data/blob.bin").read_bytes())
        self.assertEqual(b"\x05", (self.destination / "data/blob.bin").read_bytes())
        self.assertIsNone(source._PARSED_OPERATION.get())

    def test_optional_stage_map_and_plain_image_keep_the_original_call_signature(self):
        self.assertEqual(b"\x05", self.run_preview(stage_maps=False))
        self.assertEqual(["stage", "compressed", "palettes", "maps", "render"], self.events)
        self.assertEqual([(self.destination, "jp", "fixture_screen", {"config_root": self.root})],
                         self.render_calls)
        self.assertIsNone(source._PARSED_OPERATION.get())

    def test_late_primary_bytes_fail_before_render_and_restore_context(self):
        with self.assertRaisesRegex(ValueError, "raw file changed"):
            self.run_preview(map_callback=lambda: self.same_size_change(self.root / "data/blob.bin"))
        self.assertEqual([], self.render_calls)
        self.assertEqual(b"\x05", (self.destination / "data/blob.bin").read_bytes())
        self.assertIsNone(source._PARSED_OPERATION.get())

    def test_postwrite_render_closes_original_bytes_and_empty_directory_census(self):
        for index, mode in enumerate(("bytes", "source", "empty_directory")):
            self.destination = self.root / "build/content" / ("preview-%d" % index) / "tree"
            def late(destination, first):
                if mode == "bytes":
                    self.same_size_change(destination / "data/blob.bin")
                elif mode == "source":
                    (destination / "src/late.s").write_bytes(b"Late: dc.b 7\n")
                else:
                    (destination / "data/empty/late").mkdir()
                return first
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                self.run_preview(render_callback=late)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_existing_primary_or_foreign_scope_keeps_destination_reads_fresh(self):
        other = self.base / "other"
        self.make_tree(other)
        for index, active_root in enumerate((self.root, other)):
            self.destination = self.root / "build/content" / ("nested-%d" % index) / "tree"
            with self.subTest(active_root=active_root), source.parsed_operation(active_root) as active:
                source.labelled_blocks(active_root)
                def fresh(destination, first):
                    self.assertIs(active, source._PARSED_OPERATION.get())
                    (destination / "data/blob.bin").write_bytes(b"\x06")
                    return first, source.labelled_blocks(destination)[0]["Blob"]
                self.assertEqual((b"\x05", b"\x06"), self.run_preview(render_callback=fresh))
                self.assertFalse(active.closed)
                self.assertIs(active, source._PARSED_OPERATION.get())
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_unchanged_map_or_render_body_error_propagates_and_closes_scope(self):
        for index, phase in enumerate(("map", "render")):
            self.destination = self.root / "build/content" / ("failure-%d" % index) / "tree"
            sentinel = RuntimeError("unchanged %s callback" % phase)
            def refuse(*_):
                raise sentinel
            with self.subTest(phase=phase), self.assertRaises(RuntimeError) as caught:
                self.run_preview(map_callback=refuse if phase == "map" else None,
                                 render_callback=refuse if phase == "render" else None)
            self.assertIs(sentinel, caught.exception)
            self.assertIsNone(source._PARSED_OPERATION.get())

    def test_public_survey_shares_one_parse_but_repeats_render_callbacks_and_scene_wire(self):
        # Config/build/draw are explicit synthetic seams. The public survey,
        # public render, original byte parser and final raw closers are genuine.
        identifiers = ("title_background", "options_background", "story_background")
        config = {"supported": [{"id": name, "camera_a_x": index,
            "camera_a_y": {"jp": 0, "eu": -16 if index == 0 else 0},
            "camera_b_y": 0, "width": 2, "height": 1}
            for index, name in enumerate(identifiers)], "unsupported": [{}, {}]}
        config_calls, scenes = [], []
        image = [[(1, 2, 3), (4, 5, 6)]]
        def load(root):
            config_calls.append(root)
            return deepcopy(config)
        def build(root, profile, record):
            self.assertEqual((self.root, "jp"), (root, profile))
            built = {"record": record, "body": source.labelled_blocks(root)[0]["Blob"]}
            scenes.append(built)
            return built
        def draw(built, x, y, width, height):
            self.assertEqual((built["record"]["camera_a_x"], 0, 2, 1), (x, y, width, height))
            self.assertEqual(built["body"], source.labelled_blocks(self.root)[0]["Blob"])
            return deepcopy(image)
        with (mock.patch.object(screen_model, "load_config", side_effect=load),
              mock.patch.object(screen_model, "build_scene", side_effect=build) as builder,
              mock.patch.object(screen_model, "draw", side_effect=draw) as drawer,
              mock.patch.object(screen_model, "render", wraps=screen_model.render) as renderer,
              mock.patch.object(source, "_parse_labelled_blocks", wraps=source._parse_labelled_blocks) as parse):
            report = screen_model.survey(self.root, "jp")
            self.assertEqual(1, parse.call_count)
            self.assertEqual([self.root] * 4, config_calls)
            self.assertEqual(3, builder.call_count)
            self.assertEqual(3, drawer.call_count)
            self.assertEqual([(self.root, "jp", name) for name in identifiers],
                             [call.args for call in renderer.call_args_list])
            self.assertEqual(list(identifiers), [row["id"] for row in report["supported"]])
            self.assertEqual(("jp", 2), (report["profile"], report["unsupported"]))
            self.assertTrue(all((row["width"], row["height"], row["colours"], row["sha256"])
                == (2, 1, 2, screen_model.image_sha256(image)) for row in report["supported"]))
            configuration_root = self.base / "separate-config-owner"
            returned_image, scene, record = screen_model.render(root=self.root, profile="jp",
                identifier="options_background", config_root=configuration_root, with_scene=True)
            self.assertEqual(image, returned_image)
            self.assertIs(scenes[-1], scene)
            self.assertIs(scene["record"], record)
            self.assertEqual(configuration_root, config_calls[-1])
            self.assertEqual((2, 4, 4, 4),
                             (parse.call_count, builder.call_count, drawer.call_count, renderer.call_count))
            self.assertEqual(4, len({id(item) for item in scenes}))
        self.assertIsNone(source._PARSED_OPERATION.get())

    def test_public_render_closes_late_bytes_and_keeps_active_foreign_reads_fresh(self):
        record = {"id": "options_background", "camera_a_x": 0,
            "camera_a_y": {"jp": 0, "eu": 0}, "camera_b_y": 0,
            "width": 2, "height": 1}
        def build(root, profile, selected):
            self.assertEqual((self.root, "jp", record), (root, profile, selected))
            return source.labelled_blocks(root)[0]["Blob"]
        def late(*_):
            self.same_size_change(self.root / "data/blob.bin")
            return [[(1, 0, 0), (1, 0, 0)]]
        with (mock.patch.object(screen_model, "load_config", side_effect=
                lambda _: {"supported": [deepcopy(record)]}) as loader,
              mock.patch.object(screen_model, "build_scene", side_effect=build) as builder,
              mock.patch.object(screen_model, "draw", side_effect=late) as drawer):
            with self.assertRaisesRegex(ValueError, "raw file changed"):
                screen_model.render(self.root, "jp", record["id"])
            self.assertIsNone(source._PARSED_OPERATION.get())
            (self.root / "data/blob.bin").write_bytes(b"\x01")
            other = self.base / "foreign-primary"
            self.make_tree(other)
            with source.parsed_operation(other) as active:
                source.labelled_blocks(other)
                def fresh(body, *_):
                    self.assertIs(active, source._PARSED_OPERATION.get())
                    self.assertEqual(body, source.labelled_blocks(self.root)[0]["Blob"])
                    return [[(body[0], 0, 0), (body[0], 0, 0)]]
                drawer.side_effect = fresh
                for value in (2, 3):
                    (self.root / "data/blob.bin").write_bytes(bytes([value]))
                    self.assertEqual([[(value, 0, 0), (value, 0, 0)]],
                                     screen_model.render(self.root, "jp", record["id"]))
                    self.assertIs(active, source._PARSED_OPERATION.get())
                    self.assertFalse(active.closed)
            self.assertEqual((3, 3, 3), (loader.call_count, builder.call_count, drawer.call_count))
        self.assertIsNone(source._PARSED_OPERATION.get())


if __name__ == "__main__":
    unittest.main()
