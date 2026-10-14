from __future__ import annotations

import contextlib
import io
import json
import os
import shlex
import struct
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import build_content, content_workspace  # noqa: E402


def profile_config() -> dict:
    records = []
    for profile, digest in (("jp", "1" * 40), ("eu", "2" * 40)):
        records.append(
            {
                "id": profile,
                "name": profile.upper(),
                "status": "supported",
                "source": "src/main.s",
                "object": f"build/{profile}/main.p",
                "listing": f"build/{profile}/main.lst",
                "output": f"build/{profile}.bin",
                "asset_manifest": f"assets/{profile}.json",
                "asset_ranges": f"data/{profile}.txt",
                "asset_directory": "data",
                "rom_layout": f"config/{profile}.json",
                "reference_rom": {
                    "name": profile.upper(),
                    "filename": f"{profile}.bin",
                    "size": 8,
                    "sha1": digest,
                    "sha256": ("3" if profile == "jp" else "4") * 64,
                    "md5": ("5" if profile == "jp" else "6") * 32,
                    "crc32": "1234ABCD",
                    "padding_byte": "0xFF",
                },
            }
        )
    return {"schema_version": 1, "default_profile": "jp", "profiles": records}


def content_manifest() -> dict:
    return {
        "schema_version": 1,
        "profile_manifest": "config/rom_profiles.json",
        "profiles": ["jp", "eu"],
        "workspace": "content/workspace",
        "workspace_document": "workspace.json",
        "profile_outputs": {
            "jp": "build/content/jp/alien_soldier.bin",
            "eu": "build/content/eu/alien_soldier.bin",
        },
        "zero_edit_outputs": {
            "jp": "build/content/zero-edit/jp/alien_soldier.bin",
            "eu": "build/content/zero-edit/eu/alien_soldier.bin",
        },
        "assembler_defines": {"jp": [], "eu": ["BuildProfileEU=1"]},
        "studios": [
            {"id": identifier, "name": identifier.title(), "status": "planned", "artifacts": []}
            for identifier in content_workspace.EXPECTED_STUDIOS
        ],
        "artifacts": [],
    }


class ManifestTests(unittest.TestCase):
    def test_project_manifest_is_valid_and_matches_profiles(self) -> None:
        manifest = content_workspace.load_manifest(
            ROOT / "config/authoring/content_studios.json", ROOT
        )
        self.assertEqual(("jp", "eu"), tuple(manifest["profile_records"]))
        self.assertEqual([], content_workspace.validate_manifest(manifest))

    def test_parent_paths_and_false_support_claims_are_rejected(self) -> None:
        document = content_manifest()
        document["workspace"] = "../src"
        self.assertIn("invalid workspace path", content_workspace.validate_manifest(document))
        document = content_manifest()
        document["studios"][0]["status"] = "supported"
        self.assertIn(
            "supported studio has no artifacts: level",
            content_workspace.validate_manifest(document),
        )

    def test_level_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        document["artifacts"][0]["configuration_count"] = 0
        self.assertIn(
            "invalid artifact configuration_count: level_layouts",
            content_workspace.validate_manifest(document),
        )

    def test_graphics_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        graphics = next(
            item for item in document["artifacts"] if item["id"] == "tile_art"
        )
        graphics["tile_count"] = 0
        self.assertIn(
            "invalid artifact tile_count: tile_art",
            content_workspace.validate_manifest(document),
        )

    def test_palette_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        palettes = next(
            item for item in document["artifacts"] if item["id"] == "palette_commands"
        )
        palettes["command_count"] = 0
        self.assertIn(
            "invalid artifact command_count: palette_commands",
            content_workspace.validate_manifest(document),
        )

    def test_compressed_graphics_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(
                encoding="utf-8"
            )
        )
        graphics = next(
            item for item in document["artifacts"]
            if item["id"] == "compressed_tile_art"
        )
        graphics["compressed_capacity"] = 0
        self.assertIn(
            "invalid artifact compressed_capacity: compressed_tile_art",
            content_workspace.validate_manifest(document),
        )

    def test_mapping_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        mappings = next(
            item for item in document["artifacts"] if item["id"] == "sprite_mappings"
        )
        mappings["piece_count"] = 0
        self.assertIn(
            "invalid artifact piece_count: sprite_mappings",
            content_workspace.validate_manifest(document),
        )

    def test_animation_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        animations = next(
            item for item in document["artifacts"] if item["id"] == "sprite_animations"
        )
        animations["frame_count"] = 0
        self.assertIn(
            "invalid artifact frame_count: sprite_animations",
            content_workspace.validate_manifest(document),
        )

    def test_screen_map_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        maps = next(
            item for item in document["artifacts"] if item["id"] == "screen_maps"
        )
        maps["value_count"] = 0
        self.assertIn(
            "invalid artifact value_count: screen_maps",
            content_workspace.validate_manifest(document),
        )

    def test_stage_map_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        stage_maps = next(item for item in document["artifacts"]
                          if item["id"] == "stage_maps")
        stage_maps["compressed_capacity"] = 0
        self.assertIn(
            "invalid artifact compressed_capacity: stage_maps",
            content_workspace.validate_manifest(document),
        )

    def test_story_text_row_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        story = next(
            item for item in document["artifacts"] if item["id"] == "story_text_rows"
        )
        story["row_counts"]["eu"] = 0
        self.assertIn(
            "invalid artifact row_counts: story_text_rows",
            content_workspace.validate_manifest(document),
        )

    def test_frontend_text_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        text = next(
            item for item in document["artifacts"]
            if item["id"] == "frontend_text_strings"
        )
        text["glyph_count"] = 0
        self.assertIn(
            "invalid artifact glyph_count: frontend_text_strings",
            content_workspace.validate_manifest(document),
        )

    def test_results_detail_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        results = next(item for item in document["artifacts"]
                       if item["id"] == "results_detail_text")
        results["row_bytes"] = 0
        self.assertIn(
            "invalid artifact row_bytes: results_detail_text",
            content_workspace.validate_manifest(document),
        )
        results["row_bytes"] = 22
        results["summary_glyph_count"] = 0
        self.assertIn(
            "invalid artifact summary_glyph_count: results_detail_text",
            content_workspace.validate_manifest(document),
        )

    def test_stage_message_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        messages = next(
            item for item in document["artifacts"]
            if item["id"] == "stage_message_sequences"
        )
        messages["sequence_count"] = 0
        self.assertIn(
            "invalid artifact sequence_count: stage_message_sequences",
            content_workspace.validate_manifest(document),
        )

    def test_scripted_message_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        messages = next(
            item for item in document["artifacts"]
            if item["id"] == "boss_and_ship_message_scripts"
        )
        messages["record_count"] = 0
        self.assertIn(
            "invalid artifact record_count: boss_and_ship_message_scripts",
            content_workspace.validate_manifest(document),
        )

    def test_credits_text_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        credits = next(
            item for item in document["artifacts"]
            if item["id"] == "credits_text_sequence"
        )
        credits["glyph_slot_count"] = 0
        self.assertIn(
            "invalid artifact glyph_slot_count: credits_text_sequence",
            content_workspace.validate_manifest(document),
        )

    def test_glyph_source_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        lists = next(
            item for item in document["artifacts"]
            if item["id"] == "glyph_source_lists"
        )
        lists["list_count"] = 0
        self.assertIn(
            "invalid artifact list_count: glyph_source_lists",
            content_workspace.validate_manifest(document),
        )

    def test_sound_sequence_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        sound = next(
            item for item in document["artifacts"] if item["id"] == "sound_sequences"
        )
        sound["instruction_count"] = 0
        self.assertIn(
            "invalid artifact instruction_count: sound_sequences",
            content_workspace.validate_manifest(document),
        )

    def test_sound_instrument_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        sound = next(
            item for item in document["artifacts"] if item["id"] == "sound_instruments"
        )
        sound["instrument_count"] = 0
        self.assertIn(
            "invalid artifact instrument_count: sound_instruments",
            content_workspace.validate_manifest(document),
        )

    def test_sound_envelope_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        sound = next(
            item for item in document["artifacts"] if item["id"] == "sound_envelopes"
        )
        sound["value_count"] = 0
        self.assertIn(
            "invalid artifact value_count: sound_envelopes",
            content_workspace.validate_manifest(document),
        )

    def test_sound_pcm_capacity_claim_is_machine_checked(self) -> None:
        document = json.loads(
            (ROOT / "config/authoring/content_studios.json").read_text(encoding="utf-8")
        )
        sound = next(
            item for item in document["artifacts"] if item["id"] == "sound_pcm_samples"
        )
        sound["sample_count"] = 0
        self.assertIn(
            "invalid artifact sample_count: sound_pcm_samples",
            content_workspace.validate_manifest(document),
        )


class WorkspaceLifecycleTests(unittest.TestCase):
    def load(self, root: Path) -> dict:
        path = root / "config/authoring/content_studios.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(content_manifest()), encoding="utf-8")
        profiles = root / "config/rom_profiles.json"
        profiles.write_text(json.dumps(profile_config()), encoding="utf-8")
        return content_workspace.load_manifest(path, root)

    def test_init_never_overwrites_an_edit_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.load(root)
            self.assertTrue(content_workspace.initialize(root, manifest, "jp"))
            workspace = content_workspace.workspace_path(root, manifest, "jp")
            document = json.loads(workspace.read_text(encoding="utf-8"))
            document["artifacts"]["future"] = "kept"
            workspace.write_text(json.dumps(document), encoding="utf-8")
            self.assertFalse(content_workspace.initialize(root, manifest, "jp"))
            self.assertIn("future", workspace.read_text(encoding="utf-8"))
            self.assertTrue(content_workspace.initialize(root, manifest, "jp", force=True))
            self.assertEqual({}, json.loads(workspace.read_text(encoding="utf-8"))["artifacts"])

    def test_workspace_is_bound_to_its_declared_base_rom(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.load(root)
            content_workspace.initialize(root, manifest, "eu")
            workspace = content_workspace.workspace_path(root, manifest, "eu")
            document = json.loads(workspace.read_text(encoding="utf-8"))
            document["base_rom"]["sha1"] = "0" * 40
            workspace.write_text(json.dumps(document), encoding="utf-8")
            with self.assertRaisesRegex(content_workspace.ContentError, "base profile differs"):
                content_workspace.validate_workspace(root, manifest, "eu")

    def test_staging_copies_inputs_and_never_changes_them(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            (root / "data").mkdir()
            (root / "src/main.s").write_text("source\n", encoding="utf-8")
            (root / "data/asset.bin").write_bytes(b"asset")
            destination = root / "build/content/jp/tree"
            main = content_workspace.stage_tree(root, destination)
            self.assertEqual("source\n", main.read_text(encoding="utf-8"))
            (destination / "src/main.s").write_text("edited\n", encoding="utf-8")
            self.assertEqual("source\n", (root / "src/main.s").read_text(encoding="utf-8"))
            self.assertEqual(b"asset", (destination / "data/asset.bin").read_bytes())

    def test_staging_refuses_a_destination_outside_generated_content(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(content_workspace.ContentError, "outside"):
                content_workspace.stage_tree(root, root / "src")

    def test_staging_refuses_broad_cleanup_and_preserves_existing_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            generated = root / "build/content"
            generated.mkdir(parents=True)
            marker = generated / "keep.txt"
            marker.write_text("kept", encoding="utf-8")
            with self.assertRaisesRegex(content_workspace.ContentError, "profile tree"):
                content_workspace.stage_tree(root, generated)
            self.assertEqual("kept", marker.read_text(encoding="utf-8"))

    def test_missing_input_does_not_remove_previous_staging_tree(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            (root / "src/main.s").write_text("source", encoding="utf-8")
            destination = root / "build/content/jp/tree"
            destination.mkdir(parents=True)
            marker = destination / "keep.txt"
            marker.write_text("kept", encoding="utf-8")
            with self.assertRaisesRegex(content_workspace.ContentError, "input is missing"):
                content_workspace.stage_tree(root, destination)
            self.assertEqual("kept", marker.read_text(encoding="utf-8"))

    def test_linked_input_is_rejected_before_previous_tree_is_removed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "src").mkdir()
            (root / "data").mkdir()
            (root / "src/main.s").write_text("source", encoding="utf-8")
            outside = root / "outside.bin"
            outside.write_bytes(b"private")
            try:
                os.symlink(outside, root / "data/linked.bin")
            except OSError as error:
                self.skipTest(f"file symlinks are unavailable: {error}")
            destination = root / "build/content/jp/tree"
            destination.mkdir(parents=True)
            marker = destination / "keep.txt"
            marker.write_text("kept", encoding="utf-8")
            with self.assertRaisesRegex(content_workspace.ContentError, "crosses a link"):
                content_workspace.stage_tree(root, destination)
            self.assertEqual("kept", marker.read_text(encoding="utf-8"))

    def test_linked_destination_cannot_redirect_generated_tree_cleanup(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "build/content/other/tree"
            target.mkdir(parents=True)
            marker = target / "keep.txt"
            marker.write_text("kept", encoding="utf-8")
            destination = root / "build/content/jp/tree"
            destination.parent.mkdir(parents=True)
            try:
                os.symlink(target, destination, target_is_directory=True)
            except OSError as error:
                self.skipTest(f"directory symlinks are unavailable: {error}")
            with self.assertRaisesRegex(content_workspace.ContentError, "crosses a link"):
                content_workspace.stage_tree(root, destination)
            self.assertEqual("kept", marker.read_text(encoding="utf-8"))

    def test_inspect_reports_an_edited_stage_map_instead_of_reusing_prior_state(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = self.load(root)
            manifest["artifacts"] = [{
                "id": "stage_maps", "kind": "stage_map_document",
                "workspace": "level/stage_maps.json", "profiles": ["jp", "eu"],
            }]
            workspace = content_workspace.workspace_path(root, manifest, "jp")
            content_workspace.atomic_write_json(
                workspace, content_workspace.workspace_document(manifest, "jp"))
            path = content_workspace.artifact_path(
                root, manifest, "jp", manifest["artifacts"][0])
            content_workspace.atomic_write_json(path, {"value": 1})
            with mock.patch("authoring.stage_map_model.load_document",
                            side_effect=lambda target: json.loads(
                                target.read_text(encoding="utf-8"))), \
                 mock.patch("authoring.stage_map_model.export_document",
                            return_value={"value": 0}):
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    content_workspace.inspect(root, manifest, "jp")
            self.assertIn("stage_maps: edited", output.getvalue())


class BuildArgumentTests(unittest.TestCase):
    def test_only_the_european_profile_receives_its_define(self) -> None:
        manifest = content_manifest()
        self.assertEqual("-maxerrors 2", build_content.assembler_args("-maxerrors 2", manifest, "jp"))
        self.assertEqual(
            "-maxerrors 2 -D BuildProfileEU=1",
            build_content.assembler_args("-maxerrors 2", manifest, "eu"),
        )


class ContentOutputTests(unittest.TestCase):
    def test_listing_is_confined_to_selected_profile_and_keeps_spaces(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            output = root / "build/content/jp/alien_soldier.bin"
            relative = Path("build/content/jp/private listing/source symbols.lst")
            self.assertEqual(root / relative,
                             build_content.checked_listing(root, output, relative))
            self.assertEqual(root / relative,
                             build_content.checked_listing(root, output, root / relative))
            for path in (Path("build/content/eu/source.lst"), Path("docs/source.lst"),
                         Path("build/content/jp/source.txt"), Path("../source.lst"),
                         root.parent / "outside.lst"):
                with self.subTest(path=path), self.assertRaises(content_workspace.ContentError):
                    build_content.checked_listing(root, output, path)

    def test_invalid_listing_fails_before_staging(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            manifest = content_manifest()
            manifest["profile_records"] = {
                item["id"]: item for item in profile_config()["profiles"]}
            with (mock.patch.object(build_content, "validate_reference", return_value=b"rom"),
                  mock.patch.object(build_content, "validate_workspace"),
                  mock.patch.object(build_content, "stage_tree") as stage,
                  self.assertRaisesRegex(content_workspace.ContentError, "selected profile")):
                build_content.build(root, manifest, "jp", root / "asw", root / "p2bin",
                                    "-q", False, Path("build/content/eu/source.lst"))
            stage.assert_not_called()

    def test_listing_argument_reaches_assembler_as_one_token(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            manifest = content_manifest()
            manifest["profile_records"] = {
                item["id"]: item for item in profile_config()["profiles"]}
            manifest["profile_records"]["jp"]["reference_rom"]["size"] = 0x200000
            listing = root / "build/content/jp/private listing/source symbols.lst"

            def assemble(_tree, _main, _object, candidate, _as, _converter, args, _padding):
                tokens = shlex.split(args)
                self.assertEqual(["-q", "-L", "-olist", str(listing)], tokens)
                candidate.write_bytes(bytes(0x200000))
                return 0

            with (mock.patch.object(build_content, "validate_reference", return_value=bytes(0x200000)),
                  mock.patch.object(build_content, "validate_workspace"),
                  mock.patch.object(build_content, "stage_tree", return_value=root / "src/main.s"),
                  mock.patch.object(build_content, "assemble_main_src", side_effect=assemble)):
                build_content.build(root, manifest, "jp", root / "asw", root / "p2bin",
                                    "-q", False, listing)

    def test_wrong_reference_fails_before_staging_or_assembly(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                manifest = content_manifest()
                manifest["profile_records"] = {
                    item["id"]: item for item in profile_config()["profiles"]}
                (root / f"{profile}.bin").write_bytes(b"wrongROM")
                output = root / manifest["profile_outputs"][profile]
                output.parent.mkdir(parents=True)
                output.write_bytes(b"previous successful ROM")
                with (
                    mock.patch.object(build_content, "validate_workspace") as workspace,
                    mock.patch.object(build_content, "stage_tree") as stage,
                    mock.patch.object(build_content, "assemble_main_src") as assemble,
                    self.assertRaisesRegex(content_workspace.ContentError,
                                           "reference ROM differs"),
                ):
                    build_content.build(root, manifest, profile, root / "asw",
                                        root / "p2bin", "-maxerrors 2", False)
                workspace.assert_not_called()
                stage.assert_not_called()
                assemble.assert_not_called()
                self.assertEqual(b"previous successful ROM", output.read_bytes())

    def build_case(self, root: Path, *, zero_edit: bool, payload: bytes,
                   result: int = 0, profile: str = "jp") -> Path:
        manifest = content_manifest()
        manifest["profile_records"] = {
            item["id"]: item for item in profile_config()["profiles"]}
        manifest["profile_records"][profile]["reference_rom"]["size"] = 0x200000
        key = "zero_edit_outputs" if zero_edit else "profile_outputs"
        output = root / manifest[key][profile]
        output.parent.mkdir(parents=True)
        output.write_bytes(b"previous successful ROM")

        def assemble(_tree, _main, _object, candidate, *_args):
            self.assertNotEqual(output, candidate)
            self.assertEqual(output.parent, candidate.parent.parent)
            candidate.write_bytes(payload)
            return result

        with mock.patch.object(build_content, "stage_tree", return_value=root / "src/main.s"), \
             mock.patch.object(build_content, "validate_workspace"), \
             mock.patch.object(build_content, "validate_reference",
                               return_value=bytes(0x200000)), \
             mock.patch.object(build_content, "assemble_main_src", side_effect=assemble):
            try:
                build_content.build(
                    root, manifest, profile, root / "asw", root / "p2bin",
                    "-maxerrors 2", zero_edit)
            finally:
                self.assertEqual([], list(output.parent.glob(".content-rom-*")))
        return output

    def test_success_publishes_only_the_complete_edited_rom(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            payload = bytearray(0x200000)
            struct.pack_into(">H", payload, 0x200, 0x1234)
            output = self.build_case(Path(directory), zero_edit=False,
                                     payload=bytes(payload))
            struct.pack_into(">H", payload, 0x18E, 0x1234)
            self.assertEqual(payload, output.read_bytes())

    def test_eu_edited_build_publishes_its_full_span_checksum(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            payload = bytearray(0x200000)
            struct.pack_into(">H", payload, 0x1FFFFE, 0x5678)
            output = self.build_case(Path(directory), zero_edit=False,
                                     payload=bytes(payload), profile="eu")
            struct.pack_into(">H", payload, 0x18E, 0x5678)
            self.assertEqual(payload, output.read_bytes())

    def test_assembler_failure_preserves_the_previous_rom(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(content_workspace.ContentError,
                                        "content assembly failed"):
                self.build_case(root, zero_edit=False,
                                payload=b"partial", result=1)
            self.assertEqual(
                b"previous successful ROM",
                (root / content_manifest()["profile_outputs"]["jp"]).read_bytes())

    def test_zero_edit_mismatch_preserves_the_previous_rom(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(content_workspace.ContentError,
                                        "zero-edit ROM differs"):
                self.build_case(root, zero_edit=True, payload=b"mismatch")
            self.assertEqual(
                b"previous successful ROM",
                (root / content_manifest()["zero_edit_outputs"]["jp"]).read_bytes())

    def test_short_edited_rom_preserves_the_previous_rom(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(content_workspace.ContentError,
                                        "edited content ROM has 5 bytes"):
                self.build_case(root, zero_edit=False, payload=b"short")
            self.assertEqual(
                b"previous successful ROM",
                (root / content_manifest()["profile_outputs"]["jp"]).read_bytes())


class ContentChecksumTests(unittest.TestCase):
    def test_private_reference_headers_match_both_boot_loops_when_available(self) -> None:
        profiles = json.loads((ROOT / "config/rom_profiles.json").read_text(
            encoding="utf-8"))["profiles"]
        for record in profiles:
            profile = record["id"]
            reference = record["reference_rom"]
            path = ROOT / reference["filename"]
            if not path.is_file():
                self.skipTest("private JP/EU reference ROMs are not installed")
            with self.subTest(profile=profile):
                original = build_content.validate_reference(path, reference)
                image = bytearray(original)
                stored = struct.unpack_from(">H", image, 0x18E)[0]
                self.assertEqual(stored,
                                 build_content.update_boot_checksum(image, profile))
                self.assertEqual(original, image)

    def test_jp_and_eu_use_their_distinct_boot_checksum_spans(self) -> None:
        image = bytearray(0x200000)
        for address, word in ((0x200, 1), (0x60000, 2),
                              (0x60002, 4), (0x1FFFFE, 8)):
            struct.pack_into(">H", image, address, word)
        jp = bytearray(image)
        eu = bytearray(image)
        self.assertEqual(3, build_content.update_boot_checksum(jp, "jp"))
        self.assertEqual(15, build_content.update_boot_checksum(eu, "eu"))
        self.assertEqual(3, struct.unpack_from(">H", jp, 0x18E)[0])
        self.assertEqual(15, struct.unpack_from(">H", eu, 0x18E)[0])
        jp[0x18E:0x190] = b"\0\0"
        eu[0x18E:0x190] = b"\0\0"
        self.assertEqual(image, jp)
        self.assertEqual(image, eu)

    def test_checksum_rejects_a_truncated_profile_span(self) -> None:
        with self.assertRaisesRegex(content_workspace.ContentError,
                                    "too short for its boot checksum span"):
            build_content.update_boot_checksum(bytearray(0x60000), "jp")


if __name__ == "__main__":
    unittest.main()
