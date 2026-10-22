from __future__ import annotations

import copy
import hashlib
import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import verify_toolchain  # noqa: E402


class EmulatorToolchainTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.default = self.root / "default emulator"
        self.checkout = self.root / "selected emulator"
        self.checkout.mkdir()
        self.git("init", "--quiet")
        self.git("config", "user.name", "Toolchain test")
        self.git("config", "user.email", "toolchain-test@example.invalid")
        self.git("config", "core.autocrlf", "false")
        self.source = self.checkout / "driver.c"
        self.source.write_text("const int source_version = 1;\n", encoding="utf-8")
        (self.checkout / ".gitignore").write_text("Output/\nbuild/\n", encoding="utf-8")
        self.git("add", "driver.c", ".gitignore")
        self.git("commit", "--quiet", "-m", "Pin fixture driver")
        self.pin = self.git("rev-parse", "HEAD").stdout.strip()
        self.executable = self.checkout / "Output/Gens.exe"
        self.executable.parent.mkdir()
        self.executable.write_bytes(b"observed local executable")
        self.component = {
            "id": "emulator",
            "source_commit": self.pin,
            "files": {
                "any": [
                    {
                        "path": str(self.default / "Output/Gens.exe"),
                        "size": 3,
                        "sha256": hashlib.sha256(b"old").hexdigest(),
                        "observed_only": True,
                    }
                ]
            },
        }
        self.config = self.root / "toolchain.json"
        self.write_config()

    def git(self, *arguments: str, checkout: Path | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", "-C", str(checkout or self.checkout), *arguments],
            capture_output=True,
            text=True,
            check=True,
        )

    def write_config(self) -> None:
        self.config.write_text(json.dumps({"components": [self.component]}), encoding="utf-8")

    def run_check(self, *arguments: str) -> tuple[int, str, str]:
        stdout, stderr = io.StringIO(), io.StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            result = verify_toolchain.main(["--config", str(self.config), *arguments])
        return result, stdout.getvalue(), stderr.getvalue()

    def test_override_checks_selected_checkout_and_records_nonuniversal_executable(self) -> None:
        original = copy.deepcopy(self.component)
        result, stdout, stderr = self.run_check("--emulator-dir", str(self.checkout))
        self.assertEqual(0, result, stderr)
        self.assertIn(f"emulator source is clean at {self.checkout}", stdout)
        self.assertIn(self.pin, stdout)
        self.assertIn(str(self.executable), stdout)
        self.assertIn(hashlib.sha256(self.executable.read_bytes()).hexdigest(), stdout)
        self.assertIn("differs from the observed pinned runtime build", stdout)
        self.assertEqual(original, self.component)

    def test_optional_default_absence_does_not_require_a_runtime(self) -> None:
        result, stdout, stderr = self.run_check()
        self.assertEqual(0, result, stderr)
        self.assertIn("required only by runtime targets", stdout)
        result, _, stderr = self.run_check("--require-emulator")
        self.assertEqual(1, result)
        self.assertIn(str(self.default), stderr)

    def test_explicit_override_cannot_silently_fall_back_to_default(self) -> None:
        self.default.joinpath("Output").mkdir(parents=True)
        self.default.joinpath("Output/Gens.exe").write_bytes(b"default executable")
        result, stdout, stderr = self.run_check("--emulator-dir", str(self.root / "absent"))
        self.assertEqual(1, result)
        self.assertIn("emulator is not built", stderr)
        self.assertNotIn("observed runtime", stdout)

    def test_executable_without_git_source_fails_closed(self) -> None:
        self.default.joinpath("Output").mkdir(parents=True)
        self.default.joinpath("Output/Gens.exe").write_bytes(b"default executable")
        result, _, stderr = self.run_check()
        self.assertEqual(1, result)
        self.assertIn("Git checkout is absent", stderr)

    def test_changed_commit_is_rejected_even_with_a_clean_tree(self) -> None:
        self.source.write_text("const int source_version = 2;\n", encoding="utf-8")
        self.git("add", "driver.c")
        self.git("commit", "--quiet", "-m", "Unpinned source")
        actual = self.git("rev-parse", "HEAD").stdout.strip()
        result, _, stderr = self.run_check("--emulator-dir", str(self.checkout))
        self.assertEqual(1, result)
        self.assertIn(f"emulator is at {actual}, expected pinned commit {self.pin}", stderr)

    def test_tracked_changes_are_rejected_in_worktree_and_index(self) -> None:
        self.source.write_text("const int source_version = 2;\n", encoding="utf-8")
        for staged in (False, True):
            with self.subTest(staged=staged):
                if staged:
                    self.git("add", "driver.c")
                result, stdout, stderr = self.run_check("--emulator-dir", str(self.checkout))
                self.assertEqual(1, result)
                self.assertIn("tracked changes", stderr)
                self.assertIn("driver.c", stderr)
                self.assertNotIn("emulator source is clean", stdout)

    def test_ignored_generated_outputs_do_not_make_the_source_dirty(self) -> None:
        generated = self.checkout / "build/compiler-cache.obj"
        generated.parent.mkdir()
        generated.write_bytes(b"generated output")
        result, stdout, stderr = self.run_check("--emulator-dir", str(self.checkout))
        self.assertEqual(0, result, stderr)
        self.assertIn("emulator source is clean", stdout)

    def test_linked_worktree_with_git_file_is_supported(self) -> None:
        linked = self.root / "linked runtime"
        self.git("worktree", "add", "--quiet", "--detach", str(linked), self.pin)
        self.assertTrue((linked / ".git").is_file())
        executable = linked / "Output/Gens.exe"
        executable.parent.mkdir()
        executable.write_bytes(b"linked executable")
        result, stdout, stderr = self.run_check("--emulator-dir", str(linked))
        self.assertEqual(0, result, stderr)
        self.assertIn(str(executable), stdout)

    def test_repository_root_mismatch_is_rejected(self) -> None:
        errors: list[str] = []
        response = subprocess.CompletedProcess([], 0, str(self.root), "")
        with mock.patch.object(verify_toolchain.subprocess, "run", return_value=response):
            verify_toolchain.check_emulator_commit(self.component, errors, [], self.checkout)
        self.assertTrue(any("not the checkout root" in error for error in errors), errors)

    def test_unavailable_git_or_status_failure_cannot_report_success(self) -> None:
        with mock.patch.object(verify_toolchain.subprocess, "run", side_effect=OSError("git unavailable")):
            result, _, stderr = self.run_check("--emulator-dir", str(self.checkout))
        self.assertEqual(1, result)
        self.assertIn("could not inspect emulator checkout", stderr)
        responses = [
            subprocess.CompletedProcess([], 0, str(self.checkout), ""),
            subprocess.CompletedProcess([], 0, self.pin, ""),
            subprocess.CompletedProcess([], 1, "", "status failed"),
        ]
        with mock.patch.object(verify_toolchain.subprocess, "run", side_effect=responses):
            result, stdout, stderr = self.run_check("--emulator-dir", str(self.checkout))
        self.assertEqual(1, result)
        self.assertIn("status failed", stderr)
        self.assertNotIn("emulator source is clean", stdout)

    def test_missing_declaration_and_escaping_file_are_rejected(self) -> None:
        errors: list[str] = []
        checkout, files = verify_toolchain.emulator_paths([], self.checkout, errors)
        self.assertIsNone(checkout)
        self.assertEqual([], files)
        self.assertIn("no declared executable", errors[0])
        entries = self.component["files"]["any"] + [{"path": str(self.root / "outside.dll")}]
        errors = []
        _, remapped = verify_toolchain.emulator_paths(entries, self.checkout, errors)
        self.assertEqual(1, len(remapped))
        self.assertTrue(any("escapes its checkout" in error for error in errors), errors)

    def test_explicit_runtime_requirement_needs_an_emulator_component(self) -> None:
        self.config.write_text(json.dumps({"components": []}), encoding="utf-8")
        for arguments in (("--require-emulator",), ("--emulator-dir", str(self.checkout))):
            with self.subTest(arguments=arguments):
                result, _, stderr = self.run_check(*arguments)
                self.assertEqual(1, result)
                self.assertIn("does not declare the required emulator", stderr)


if __name__ == "__main__":
    unittest.main()
