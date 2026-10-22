from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
import runtime_environment as environment  # noqa: E402


class NativeEnvironmentTests(unittest.TestCase):
    def fixture(self, directory):
        root = Path(directory)
        executable = root / "pinned/Output/Gens.exe"
        executable.parent.mkdir(parents=True)
        executable.write_bytes(b"observed build")
        (root / "config").mkdir()
        component = {
            "id": "emulator",
            "source_commit": "a" * 40,
            "files": {"any": [{"path": "../gens/Output/Gens.exe"}]},
        }
        (root / "config/toolchain.json").write_text(json.dumps({"components": [component]}), encoding="utf-8")
        return root, executable

    def test_clean_selected_checkout_and_actual_build_are_bound(self):
        with tempfile.TemporaryDirectory() as directory:
            root, executable = self.fixture(directory)
            with (
                mock.patch.object(environment, "check_emulator_commit") as pin,
                mock.patch.object(environment, "emulator_git", return_value="b" * 40),
                mock.patch.object(
                    environment.runtime_isolation, "native_config_contract", return_value={"proved": True}
                ),
            ):
                result = environment.environment_identity(root, executable)
            self.assertEqual("a" * 40, result["source_commit"])
            self.assertEqual("b" * 40, result["source_tree"])
            self.assertEqual(environment.digest(executable), result["executable_sha256"])
            self.assertEqual(executable.parent.parent, pin.call_args.args[3])
            self.assertTrue(result["config_loader"]["proved"])

    def test_dirty_or_wrong_commit_is_refused_before_config_proof(self):
        with tempfile.TemporaryDirectory() as directory:
            root, executable = self.fixture(directory)

            def refuse(_component, errors, _notes, _checkout):
                errors.append("dirty selected source")

            with (
                mock.patch.object(environment, "check_emulator_commit", side_effect=refuse),
                mock.patch.object(environment, "emulator_git", return_value="b" * 40),
                mock.patch.object(environment.runtime_isolation, "native_config_contract") as config,
            ):
                with self.assertRaisesRegex(ValueError, "dirty selected source"):
                    environment.environment_identity(root, executable)
                config.assert_not_called()

    def test_non_manifest_executable_location_is_refused_before_git(self):
        with tempfile.TemporaryDirectory() as directory:
            root, executable = self.fixture(directory)
            with mock.patch.object(environment, "check_emulator_commit") as pin:
                with self.assertRaisesRegex(ValueError, "declared runtime"):
                    environment.environment_identity(root, executable.with_name("Other.exe"))
                pin.assert_not_called()


if __name__ == "__main__":
    unittest.main()
