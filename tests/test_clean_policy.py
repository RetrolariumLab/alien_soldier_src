"""Selective cleanup controls operate only on fresh private fixture roots."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import clean_project


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="clean-policy-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.write("config/runtime_scenarios.json", b'{"scenarios": [{"id": "boot", "frame": 20}]}')

    def write(self, relative, body=b"test"):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(body)
        return path

    def snapshot(self):
        return {
            path.relative_to(self.root).as_posix(): ("directory",) if path.is_dir() else ("file", path.read_bytes())
            for path in self.root.rglob("*")
        }

    def clean(self):
        with redirect_stdout(io.StringIO()):
            return clean_project.clean(self.root)


class RetainedPublicRegressions(Fixture):
    def test_clean_only_targets_reproducible_outputs(self):
        expected = {
            "build/main.p",
            "build/main.lst",
            "build/source_inventory.json",
            "alien_soldier_j.p",
            "alien_soldier_j.lst",
            "asbuilt.bin",
            "build/eu/main.p",
            "build/eu/main.lst",
            "asbuilt_eu.bin",
        }
        expected.update(
            f"build/content/{mode}/alien_soldier.{suffix}"
            for mode in ("jp", "eu", "zero-edit/jp", "zero-edit/eu")
            for suffix in ("bin", "p")
        )
        expected.update(f"build/content/zero-edit/{profile}/screen_runtime.lst" for profile in ("jp", "eu"))
        self.assertEqual(expected, set(clean_project.ROOT_TARGETS))
        self.assertEqual(len(expected), len(clean_project.ROOT_TARGETS))
        self.assertEqual(
            [f"build/content/{mode}/tree" for mode in ("jp", "eu", "zero-edit/jp", "zero-edit/eu")],
            clean_project.DIRECTORY_TARGETS,
        )
        self.assertEqual(["__pycache__"], clean_project.RECURSIVE_PATTERNS)

    def test_clean_never_targets_preservation_inputs_or_work(self):
        rendered = "\n".join(
            clean_project.ROOT_TARGETS + clean_project.DIRECTORY_TARGETS + clean_project.RECURSIVE_PATTERNS
        )
        for protected in ("data", "assets", "movies", "logs", "workflow", "backup"):
            self.assertNotIn(protected, rendered.lower())
        self.assertNotIn("build/content", clean_project.DIRECTORY_TARGETS)

    def test_checked_target_rejects_escape_and_links(self):
        self.assertEqual(self.root / "build", clean_project.checked_target(self.root, "build"))
        for unsafe in (".", "..", "build/../data", self.root):
            with self.subTest(unsafe=str(unsafe)), self.assertRaises(ValueError):
                clean_project.checked_target(self.root, unsafe)
        outside = self.root / "private"
        outside.mkdir()
        link = self.root / "runtime"
        try:
            link.symlink_to(outside, target_is_directory=True)
        except (OSError, NotImplementedError):
            return  # Retained public platform-optional symlink seam.
        with self.assertRaises(ValueError):
            clean_project.checked_target(self.root, "runtime/captures")

    def test_clean_preserves_inputs_and_unrelated_work(self):
        removed = (
            "build/main.p",
            "build/main.lst",
            "build/source_inventory.json",
            "build/content/jp/alien_soldier.bin",
            "runtime/captures/boot/000020.genstate",
            "runtime/captures/boot/000020.png",
            "scripts/__pycache__/test.pyc",
        )
        retained = (
            "build/their_config.json",
            "content/workspace/jp/workspace.json",
            "runtime/captures/boot.genstate",
            "runtime/captures/boot/private.png",
            "data/other/asset.bin",
            "reference/__pycache__/private.pyc",
        )
        for relative in (*removed, *retained):
            self.write(relative)
        self.clean()
        for relative in removed:
            self.assertFalse((self.root / relative).exists(), relative)
        self.assertTrue((self.root / "build/content").is_dir())
        for relative in retained:
            self.assertEqual(b"test", (self.root / relative).read_bytes())


class RetentionAndGuards(Fixture):
    def test_all_fixed_outputs_removed_but_every_retained_owner_and_empty_directory_survives(self):
        retained = []
        for profile in ("jp", "eu"):
            for name in (
                "live-native/session-live",
                "source-format/session-source",
                "historical-native/session-old",
                "failed-native/session-failed",
                "sound-mix-runtime/session-old",
                "static-six-authoring-runtime/session-live",
            ):
                base = Path("build/content") / profile / name
                for suffix in ("receipt.json", "tree/src/main.s", "capture/frames.json", "states/1123.genstate"):
                    retained.append(str(base / suffix))
                    self.write(base / suffix, b"retained immutable evidence")
                (self.root / base / "empty-evidence-directory").mkdir()
            for suffix in ("ordinary20.json", "mapping_authoring_witness.json", "custom.lst", "sound_audition.lst"):
                path = Path("build/content") / profile / suffix
                retained.append(str(path))
                self.write(path, b"retained private research")
            (self.root / "build/content" / profile / "empty-private-directory").mkdir()
        for relative in (
            "build/authoring-proposals/ordinary20/batch.json",
            "build/runtime-emulator/native-proof.json",
            "data/asset.bin",
            "assets/manifest.json",
            "content/workspace/jp/workspace.json",
            "content/workspace/eu/workspace.json",
            "Alien Soldier (J) [!].bin",
            "Alien Soldier (E) [!].bin",
        ):
            retained.append(relative)
            self.write(relative, b"preservation or evidence")
        retained_before = self.snapshot()
        for target in clean_project.ROOT_TARGETS:
            self.write(target, b"reproducible")
        for target in clean_project.DIRECTORY_TARGETS:
            self.write(Path(target) / "src/main.s", b"generated source")
            self.write(Path(target) / "data/asset.bin", b"generated data")
        self.write("tests/deep/__pycache__/test.pyc")
        self.write("__pycache__/root.pyc")
        self.clean()
        for relative in retained:
            self.assertEqual(retained_before[Path(relative).as_posix()][1], (self.root / relative).read_bytes())
        for relative, value in retained_before.items():
            if value == ("directory",):
                self.assertTrue((self.root / relative).is_dir(), relative)
        for target in (*clean_project.ROOT_TARGETS, *clean_project.DIRECTORY_TARGETS):
            self.assertFalse((self.root / target).exists(), target)
        self.assertFalse((self.root / "tests/deep/__pycache__").exists())
        self.assertFalse((self.root / "__pycache__").exists())

    def test_malicious_content_manifest_cannot_register_arbitrary_cleanup_targets(self):
        private = self.write("build/content/jp/custom-history/receipt.json", b"unchangeable")
        self.write(
            "config/authoring/content_studios.json",
            json.dumps(
                {
                    "profile_outputs": {"jp": "build/content/jp/custom-history/receipt.json", "eu": "../outside"},
                    "zero_edit_outputs": {"jp": "data", "eu": "build/content"},
                }
            ).encode(),
        )
        self.write("build/content/jp/alien_soldier.bin")
        self.clean()
        self.assertEqual(b"unchangeable", private.read_bytes())

    def test_unapproved_directories_and_wrong_target_types_are_refused_before_deletion(self):
        for target in ("build/content", "build/content/jp", "data", "reference/__pycache__"):
            with self.subTest(target=target), self.assertRaisesRegex(ValueError, "exact generated"):
                clean_project.remove_path(self.root, target, allow_directory=True)
        self.write("build/main.p")
        tree = self.write("build/content/jp/tree", b"not a directory")
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, "found file"):
            self.clean()
        self.assertEqual(before, self.snapshot())
        self.assertEqual(b"not a directory", tree.read_bytes())

    def test_top_level_hard_link_preflight_preserves_every_file(self):
        original = self.write("data/original.bin", b"protected bytes")
        selected = self.root / "build/main.p"
        selected.parent.mkdir()
        os.link(original, selected)
        self.write("asbuilt.bin", b"other output still preserved on refusal")
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, "hard-linked"):
            self.clean()
        self.assertEqual(before, self.snapshot())

    def test_recursive_tree_or_cache_hard_link_preflight_preserves_every_file(self):
        for target in ("build/content/jp/tree/src/alias.bin", "scripts/deep/__pycache__/alias.pyc"):
            original = self.write("data/original.bin", b"protected bytes")
            selected = self.root / target
            selected.parent.mkdir(parents=True, exist_ok=True)
            os.link(original, selected)
            self.write("build/main.p", b"must not delete first")
            before = self.snapshot()
            with self.subTest(target=target), self.assertRaisesRegex(ValueError, "hard-linked"):
                self.clean()
            self.assertEqual(before, self.snapshot())
            selected.unlink()  # Remove only this test-owned temporary hard link.

    @unittest.skipUnless(os.name == "nt", "Windows junction guard")
    def test_recursive_tree_and_cache_junctions_refuse_without_touching_target(self):
        import _winapi

        for target in ("build/content/eu/tree/src/foreign", "scripts/deep/__pycache__/foreign"):
            protected = self.write("private/protected.txt", b"outside generated target")
            link = self.root / target
            link.parent.mkdir(parents=True, exist_ok=True)
            _winapi.CreateJunction(str(protected.parent), str(link))
            self.write("build/main.p", b"must remain")
            with self.subTest(target=target), self.assertRaisesRegex(ValueError, "crosses a link"):
                self.clean()
            self.assertEqual(b"must remain", (self.root / "build/main.p").read_bytes())
            self.assertEqual(b"outside generated target", protected.read_bytes())
            self.assertTrue(link.is_junction())
            link.rmdir()  # Only this fixture's junction, not its destination.

    @unittest.skipUnless(os.name == "nt", "Windows junction guard")
    def test_ancestor_and_fixture_root_junctions_are_refused(self):
        import _winapi

        outside = self.root / "private"
        outside.mkdir()
        link = self.root / "build"
        _winapi.CreateJunction(str(outside), str(link))
        with self.assertRaisesRegex(ValueError, "crosses a link"):
            clean_project.checked_target(self.root, "build/main.p")
        with self.assertRaisesRegex(ValueError, "root crosses a link"):
            clean_project.checked_target(link, "main.p")
        self.assertTrue(link.is_junction())
        self.assertTrue(outside.is_dir())
        link.rmdir()

    def test_invalid_runtime_contract_fails_before_any_delete(self):
        self.write("build/main.p", b"must remain")
        for scenario in ({"id": "../escape", "frame": 20}, {"id": "boot", "frame": True}, {"id": "boot", "frame": -1}):
            self.write("config/runtime_scenarios.json", json.dumps({"scenarios": [scenario]}).encode())
            before = self.snapshot()
            with self.subTest(scenario=scenario), self.assertRaises(ValueError):
                self.clean()
            self.assertEqual(before, self.snapshot())

    def test_public_default_is_checkout_and_main_uses_it_without_cleanup_in_this_test(self):
        self.assertEqual(ROOT, clean_project.PROJECT_ROOT)
        with mock.patch.object(clean_project, "clean") as clean:
            clean_project.main()
            clean.assert_called_once_with()
        with mock.patch.object(clean_project.shutil, "rmtree") as recursive:
            self.assertEqual(ROOT, clean_project.checked_root(ROOT))
            recursive.assert_not_called()

    def test_each_recursive_delete_is_exact_fixed_tree_or_code_cache_and_resolved(self):
        self.write("build/content/zero-edit/eu/tree/src/main.s")
        self.write("scripts/deep/__pycache__/one.pyc")
        original, calls = clean_project.shutil.rmtree, []

        def checked(path, *args, **kwargs):
            path = Path(path)
            self.assertTrue(path.is_absolute())
            self.assertTrue(path.is_relative_to(self.root))
            self.assertTrue(clean_project.directory_owned(path.relative_to(self.root)))
            self.assertNotEqual(self.root / "build/content", path)
            calls.append(path)
            return original(path, *args, **kwargs)

        with mock.patch.object(clean_project.shutil, "rmtree", side_effect=checked):
            self.clean()
        self.assertEqual(2, len(calls))


if __name__ == "__main__":
    unittest.main()
