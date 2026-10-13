from __future__ import annotations

import copy
import hashlib
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "scripts")]

from authoring import screen_studio_model as model  # noqa: E402


class InventoryTests(unittest.TestCase):
    def test_inventory_has_three_bounded_views_and_eleven_exclusions(self) -> None:
        config = model.load_config(ROOT)
        self.assertEqual(
            ["title_background", "options_background", "story_background"],
            [record["id"] for record in config["supported"]],
        )
        self.assertEqual(11, len(config["unsupported"]))
        self.assertTrue(all(record["reason"] for record in config["unsupported"]))


    def test_duplicate_and_unexplained_records_are_rejected(self) -> None:
        config = model.load_config(ROOT)
        broken = copy.deepcopy(config)
        broken["unsupported"][0]["id"] = broken["supported"][0]["id"]
        broken["unsupported"][1]["reason"] = ""
        errors = model.config_errors(broken)
        self.assertIn("screen identifiers are not unique", errors)
        self.assertTrue(any("has no unsupported reason" in error for error in errors))


class RenderingTests(unittest.TestCase):
    EXPECTED = {
        "jp": {
            "title_background": "5d407981141141e8f3aae5b1661c2acb258280ca8bf5bf4b064aadd68dd0c802",
            "options_background": "5ac16abc1c2891e954ca12006891a6f875741b6ee4eb3c921cd4584ca5b4c850",
            "story_background": "a0fdec5ec62f3b489f6afd4541f1cef4445a6d35ba617b192dee08b5de182251",
        },
        "eu": {
            "title_background": "211a839ff7e89e05e86bc0eff7013771d81c84a3a1e7bf01de19a29480035e06",
            "options_background": "5ac16abc1c2891e954ca12006891a6f875741b6ee4eb3c921cd4584ca5b4c850",
            "story_background": "a0fdec5ec62f3b489f6afd4541f1cef4445a6d35ba617b192dee08b5de182251",
        },
    }

    def test_all_static_compositions_have_deterministic_pixels(self) -> None:
        for profile, expected in self.EXPECTED.items():
            with self.subTest(profile=profile):
                report = model.survey(ROOT, profile)
                self.assertEqual(11, report["unsupported"])
                self.assertEqual(expected, {
                    record["id"]: record["sha256"]
                    for record in report["supported"]
                })
                for record in report["supported"]:
                    self.assertEqual((320, 224), (record["width"], record["height"]))
                    self.assertGreater(record["colours"], 1)

    def test_title_uses_the_regional_vertical_origin(self) -> None:
        jp = model.render(ROOT, "jp", "title_background")
        eu = model.render(ROOT, "eu", "title_background")
        self.assertNotEqual(model.image_sha256(jp), model.image_sha256(eu))

    def test_semantic_cameras_and_source_upload_lookup_are_separate(self):
        config = model.load_config(ROOT)
        original = copy.deepcopy(config)
        for profile in model.PROFILES:
            for record in config["supported"]:
                with self.subTest(profile=profile, screen=record["id"]):
                    expected_a = 16 if profile == "eu" and record["id"] == "title_background" else 0
                    self.assertEqual((expected_a, 0), model.screen_view_y(record, profile))
                    built = model.build_scene(ROOT, profile, record)
                    self.assertEqual(-expected_a, built.plane_b.y_offset)
        self.assertEqual(original, config)
        self.assertEqual(-16, config["supported"][0]["camera_a_y"]["eu"])

    def test_unknown_or_changed_camera_route_does_not_infer_an_origin(self):
        title = model.screen_record(model.load_config(ROOT), "title_background")
        for profile, record in (("xx", title), ("jp", dict(title, id="unknown")),
                                ("eu", dict(title, camera_a_y={"jp": 0, "eu": 16})),
                                ("jp", dict(title, camera_a_y={"jp": False, "eu": -16})),
                                ("jp", dict(title, camera_b_y=1)),
                                ("jp", dict(title, camera_a_y=None))):
            with self.subTest(profile=profile, record=record), self.assertRaises(ValueError):
                model.screen_view_y(record, profile)

    def test_title_route_guard_rejects_wrong_upload_region_sign_and_writer(self):
        title = (ROOT / model.TITLE_SOURCE).read_text(encoding="utf-8")
        scroll = (ROOT / model.SCROLL_SOURCE).read_text(encoding="utf-8")
        mutations = (
            ("upload Y", title.replace("moveq   #0,d1", "moveq   #1,d1", 1), scroll),
            ("wrong region", title.replace("if      BuildProfileEU", "if      BuildProfileJP", 1), scroll),
            ("camera sign", title.replace("#$FFF0,(PrimaryCameraYPosition)", "#$0010,(PrimaryCameraYPosition)", 1), scroll),
            ("extra write", title.replace("jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l",
                                          "move.w #0,(PrimaryCameraYPosition).w\n"
                                          "jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l", 1), scroll),
            ("unary clear", title.replace("jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l",
                                          "clr.w (PrimaryCameraYPosition).w\n"
                                          "jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l", 1), scroll),
            ("negation", title, scroll.replace("(PrimaryCameraYPosition).w,d0\n                neg.w   d0",
                                               "(PrimaryCameraYPosition).w,d0\n                nop", 1)),
            ("writer", title, scroll.replace("bne.s   Scroll_VerticalPlaneWriteReturn\n                move.w  d0,(a0)",
                                             "bne.s   Scroll_VerticalPlaneWriteReturn\n                move.w  d1,(a0)", 1)),
            ("comment fake", ";" + title.replace("\n", "\n;"), scroll),
        )
        model.prove_title_view_route(ROOT)
        for name, altered_title, altered_scroll in mutations:
            with self.subTest(mutation=name), tempfile.TemporaryDirectory() as directory:
                staged = Path(directory)
                for path, body in ((model.TITLE_SOURCE, altered_title), (model.SCROLL_SOURCE, altered_scroll)):
                    target = staged / path
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(body, encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "source"):
                    model.prove_title_view_route(staged)

    def test_title_guard_runs_before_assets_are_read(self):
        record = model.screen_record(model.load_config(ROOT), "title_background")
        with (mock.patch.object(model, "prove_title_view_route", side_effect=ValueError("source changed")) as guard,
              mock.patch.object(model, "labelled_blocks") as assets,
              self.assertRaisesRegex(ValueError, "source changed")):
            model.build_scene(ROOT, "eu", record)
        guard.assert_called_once_with(ROOT)
        assets.assert_not_called()

    def test_title_postload_ram_and_back_plane_match_tas_frame_370(self) -> None:
        """Hashes were measured independently in reference/tas/000370.genstate."""
        config = model.load_config(ROOT)
        record = model.screen_record(config, "title_background")
        scene = model.build_scene(ROOT, "jp", record)
        for start, length, expected in (
            (0x2020, 6144,
             "80e96c37ee46da7be3edaed4c6151c2d66ba2f8039460268b22484e791fa3555"),
            (0x4020, 1248,
             "ac932730e215e3c585250ee9aef5ea3846123fb20a1edc2c021e136abc89c296"),
        ):
            with self.subTest(start=start):
                self.assertEqual(
                    expected,
                    hashlib.sha256(scene.tilemap.ram[start:start + length]).hexdigest(),
                )
        visible_back_plane = b"".join(
            scene.plane_b.name_word(1536 + x * 8, y * 8).to_bytes(2, "big")
            for y in range(28) for x in range(40)
        )
        self.assertEqual(
            "21f4b7c1fab7daf403537172943334896e4ace64b24b1af292ca41625aec7b4c",
            hashlib.sha256(visible_back_plane).hexdigest(),
        )

    def test_options_implicit_adjacent_stop_word_is_replayed(self) -> None:
        config = model.load_config(ROOT)
        record = model.screen_record(config, "options_background")
        scene = model.build_scene(ROOT, "jp", record)
        self.assertEqual((), scene.missing_codecs)
        self.assertEqual(("Options_AssetLoadDescriptors",), scene.plane_b.lists)
        self.assertGreater(scene.plane_b.patterns_defined, 0)


if __name__ == "__main__":
    unittest.main()
