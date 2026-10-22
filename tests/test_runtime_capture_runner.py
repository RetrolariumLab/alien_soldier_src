"""Pin neutral full-frame replay, authentication, and owned-output behavior."""

from __future__ import annotations

import hashlib
import json
import struct
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import run_runtime_scenarios  # noqa: E402


def native_state(frame: int, checksum: int = 0x55555558) -> bytes:
    header = bytearray(96)
    header[:8] = b"GENSTATE"
    struct.pack_into("<IIQI", header, 8, 1, frame, 0, checksum)
    struct.pack_into("<IIII", header, 64, 1, 96, 65536, 0)
    return bytes(header) + bytes(65536)


class RuntimeCaptureRunnerTests(unittest.TestCase):
    def make_inputs(self, root: Path, movie_hash: str | None = None) -> None:
        movie = root / "movies" / "run.gmv"
        movie.parent.mkdir()
        movie.write_bytes(b"pinned movie")
        (root / "gens.exe").write_bytes(b"emulator placeholder")
        (root / "rom.bin").write_bytes(b"rom placeholder")
        config = {
            "rom_checksum": "0x55555558",
            "movies": {
                "tas": {
                    "path": "movies/run.gmv",
                    "sha256": movie_hash or hashlib.sha256(movie.read_bytes()).hexdigest(),
                }
            },
            "scenarios": [
                {"id": "first", "movie": "tas", "frame": 100},
                {"id": "second", "movie": "tas", "frame": 200},
            ],
        }
        (root / "scenarios.json").write_text(json.dumps(config), encoding="utf-8")

    def alter_config(self, root: Path, change: object) -> None:
        path = root / "scenarios.json"
        config = json.loads(path.read_text(encoding="utf-8"))
        change(config)
        path.write_text(json.dumps(config), encoding="utf-8")

    def run_capture(self, root: Path, fake_run: object) -> int:
        argv = [
            "run_runtime_scenarios.py",
            "--scenarios",
            "scenarios.json",
            "--gens",
            "gens.exe",
            "--rom",
            "rom.bin",
            "--output-dir",
            "captures",
            "--minimum-timeout",
            "1",
            "--seconds-per-1000-frames",
            "20",
        ]
        with mock.patch.object(run_runtime_scenarios.Path, "cwd", return_value=root):
            with mock.patch.object(run_runtime_scenarios.sys, "argv", argv):
                with (
                    mock.patch.object(
                        run_runtime_scenarios.runtime_isolation,
                        "native_config_contract",
                        return_value={"native": "fixture"},
                    ),
                    mock.patch.object(run_runtime_scenarios, "run_hidden", side_effect=fake_run),
                ):
                    stdout = StringIO()
                    stderr = StringIO()
                    with redirect_stdout(stdout), redirect_stderr(stderr):
                        result = run_runtime_scenarios.main()
        self.capture_stdout = stdout.getvalue()
        self.capture_stderr = stderr.getvalue()
        return result

    def fake_success(
        self, command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
    ) -> subprocess.CompletedProcess:
        frame = int(command[command.index("-screenshot-interval") + 1])
        states = Path(command[command.index("-dump-state-dir") + 1])
        shots = Path(command[command.index("-screenshot-dir") + 1])
        (states / f"{frame}.genstate").write_bytes(native_state(frame))
        (shots / f"{frame:06d}.png").write_bytes(b"new image")
        return subprocess.CompletedProcess(command, 0)

    def test_each_capture_replaces_only_owned_outputs_at_actual_native_frame(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)
            for scenario, frame in (("first", 100), ("second", 200)):
                capture = root / "captures" / scenario
                capture.mkdir(parents=True)
                (capture / f"{frame:06d}.genstate").write_bytes(b"old state")
                (capture / f"{frame:06d}.png").write_bytes(b"old image")
                (capture / f"{frame}.genstate").write_bytes(b"manual native state")
                (capture / "manual.genstate").write_bytes(b"manual state")
                (capture / "manual.png").write_bytes(b"manual image")
            calls = []

            def fake_run(
                command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
            ) -> subprocess.CompletedProcess:
                calls.append((command, timeout, environment))
                self.assertTrue(cwd.is_relative_to(root / "captures"))
                self.assertEqual([], list(cwd.iterdir()))
                frame = int(command[command.index("-screenshot-interval") + 1])
                scenario = "first" if frame == 100 else "second"
                public = root / "captures" / scenario
                self.assertFalse((public / f"{frame:06d}.genstate").exists())
                self.assertFalse((public / f"{frame:06d}.png").exists())
                self.assertEqual(b"pinned movie", Path(command[command.index("-play") + 1]).read_bytes())
                self.assertEqual(b"rom placeholder", Path(command[command.index("-rom") + 1]).read_bytes())
                return self.fake_success(command, cwd, timeout, environment)

            self.assertEqual(0, self.run_capture(root, fake_run))
            self.assertIn("captured 2 runtime scenarios", self.capture_stdout)
            self.assertEqual(2, len(calls))
            for (command, timeout, environment), frame in zip(calls, (100, 200)):
                with self.subTest(frame=frame):
                    self.assertNotEqual(str(root / "rom.bin"), command[command.index("-rom") + 1])
                    self.assertEqual(str(run_runtime_scenarios.CAPTURE_SCRIPT), command[command.index("-lua") + 1])
                    self.assertEqual(str(frame + 1), command[command.index("-max-frames") + 1])
                    self.assertEqual(str(frame), command[command.index("-dump-state-start") + 1])
                    self.assertEqual(str(frame), command[command.index("-dump-state-end") + 1])
                    self.assertEqual("1", command[command.index("-dump-state-interval") + 1])
                    self.assertEqual("0", command[command.index("-frameskip") + 1])
                    self.assertEqual(str(frame + 1), environment["ALIEN_RUNTIME_CAPTURE_STOP_FRAME"])
                    self.assertNotIn("-turbo", command)
                    self.assertNotIn("-save-state-dumps", command)
                    self.assertEqual(frame * 20 // 1000, timeout)
                    self.assertFalse(Path(command[command.index("-rom") + 1]).exists())
            for scenario, frame in (("first", 100), ("second", 200)):
                capture = root / "captures" / scenario
                self.assertEqual(native_state(frame), (capture / f"{frame:06d}.genstate").read_bytes())
                self.assertEqual(b"new image", (capture / f"{frame:06d}.png").read_bytes())
                self.assertEqual(b"manual native state", (capture / f"{frame}.genstate").read_bytes())
                self.assertEqual(b"manual state", (capture / "manual.genstate").read_bytes())
                self.assertEqual(b"manual image", (capture / "manual.png").read_bytes())
            receipt = json.loads((root / "captures" / "capture_receipt.json").read_text())
            self.assertEqual("captured", receipt["status"])
            self.assertEqual(300, receipt["requested_frames"])
            self.assertEqual([100, 200], [item["native_header_frame"] for item in receipt["scenarios"]])
            self.assertEqual(["first", "second"], [item["id"] for item in receipt["expected_scenarios"]])
            self.assertEqual(
                run_runtime_scenarios.sha256(run_runtime_scenarios.CAPTURE_SCRIPT), receipt["capture_lua_sha256"]
            )
            self.assertEqual(
                run_runtime_scenarios.sha256(run_runtime_scenarios.RUNNER_SCRIPT), receipt["capture_runner_sha256"]
            )
            self.assertEqual(run_runtime_scenarios.sha256(root / "rom.bin"), receipt["rom_sha256"])
            self.assertEqual([], list((root / "captures").glob(".runtime-inputs-*")))

    def test_bad_movie_hash_stops_before_capture_or_cleanup(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root, movie_hash="0" * 64)
            capture = root / "captures" / "first"
            capture.mkdir(parents=True)
            old = capture / "000100.genstate"
            old.write_bytes(b"old state")
            fake_run = mock.Mock()
            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("movie tas SHA-256", self.capture_stderr)
            fake_run.assert_not_called()
            self.assertEqual(b"old state", old.read_bytes())

    def test_all_inventory_is_validated_before_any_cleanup(self) -> None:
        for field, value in (
            ("id", "../user"),
            ("id", "first"),
            ("frame", True),
            ("frame", 100001),
            ("movie", "missing"),
        ):
            with self.subTest(field=field, value=value), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_inputs(root)
                self.alter_config(root, lambda config: config["scenarios"][1].update({field: value}))
                capture = root / "captures" / "first"
                capture.mkdir(parents=True)
                old = capture / "000100.genstate"
                old.write_bytes(b"user state")
                fake_run = mock.Mock()
                self.assertEqual(1, self.run_capture(root, fake_run))
                fake_run.assert_not_called()
                self.assertEqual(b"user state", old.read_bytes())

    def test_unsafe_movie_id_cannot_escape_private_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)
            self.alter_config(root, lambda config: config["movies"].update({"../user": config["movies"].pop("tas")}))
            fake_run = mock.Mock()
            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("unsafe runtime movie id", self.capture_stderr)
            fake_run.assert_not_called()
            self.assertFalse((root / "captures").exists())

    def test_nonfile_target_is_not_removed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)
            capture = root / "captures" / "first"
            capture.mkdir(parents=True)
            blocked = capture / "000100.png"
            blocked.mkdir()
            fake_run = mock.Mock()
            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("unsafe capture output path", self.capture_stderr)
            fake_run.assert_not_called()
            self.assertTrue(blocked.is_dir())

    def test_linked_scenario_directory_is_not_followed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)
            capture = root / "captures" / "first"
            capture.mkdir(parents=True)
            old = capture / "000100.genstate"
            old.write_bytes(b"user state")
            fake_run = mock.Mock()
            with mock.patch.object(
                run_runtime_scenarios.Path, "is_symlink", autospec=True, side_effect=lambda path: path == capture
            ):
                self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("unsafe runtime capture directory", self.capture_stderr)
            fake_run.assert_not_called()
            self.assertEqual(b"user state", old.read_bytes())

    def test_output_root_cannot_alias_runtime_input(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)
            arguments = mock.Mock(
                scenarios="scenarios.json",
                gens="gens.exe",
                rom="rom.bin",
                output_dir="rom.bin",
                minimum_timeout=1,
                seconds_per_1000_frames=20,
            )
            with mock.patch.object(
                run_runtime_scenarios.runtime_isolation, "native_config_contract", return_value={"native": "fixture"}
            ):
                with self.assertRaisesRegex(ValueError, "aliases a runtime input"):
                    run_runtime_scenarios.replay(root, arguments)
            self.assertEqual(b"rom placeholder", (root / "rom.bin").read_bytes())

    def test_missing_screenshot_fails_without_advancing_to_next_scenario(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)
            calls = 0

            def fake_run(
                command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
            ) -> subprocess.CompletedProcess:
                nonlocal calls
                calls += 1
                states = Path(command[command.index("-dump-state-dir") + 1])
                (states / "100.genstate").write_bytes(native_state(100))
                return subprocess.CompletedProcess(command, 0)

            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("first: capture failed", self.capture_stderr)
            self.assertEqual(1, calls)
            self.assertFalse((root / "captures" / "second").exists())
            self.assertEqual("failed", json.loads((root / "captures" / "capture_receipt.json").read_text())["status"])

    def test_native_frame_and_checksum_must_match_before_publication(self) -> None:
        for frame, checksum, diagnostic in ((0, 0x55555558, "frame/RAM"), (100, 0, "ROM checksum")):
            with self.subTest(frame=frame, checksum=checksum), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_inputs(root)

                def fake_run(
                    command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
                ) -> subprocess.CompletedProcess:
                    self.fake_success(command, cwd, timeout, environment)
                    states = Path(command[command.index("-dump-state-dir") + 1])
                    (states / "100.genstate").write_bytes(native_state(frame, checksum))
                    return subprocess.CompletedProcess(command, 0)

                self.assertEqual(1, self.run_capture(root, fake_run))
                self.assertIn(diagnostic, self.capture_stderr)
                self.assertFalse((root / "captures" / "first" / "000100.genstate").exists())
                self.assertFalse((root / "captures" / "second").exists())

    def test_mutable_inputs_cannot_be_silently_bound_to_old_hashes(self) -> None:
        for input_name in ("rom.bin", "gens.exe", "movies/run.gmv", "scenarios.json", "capture.lua"):
            with self.subTest(input_name=input_name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_inputs(root)
                lua = root / "capture.lua"
                lua.write_bytes(run_runtime_scenarios.CAPTURE_SCRIPT.read_bytes())

                def fake_run(
                    command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
                ) -> subprocess.CompletedProcess:
                    result = self.fake_success(command, cwd, timeout, environment)
                    (root / input_name).write_bytes(b"mutated after authentication")
                    return result

                with mock.patch.object(run_runtime_scenarios, "CAPTURE_SCRIPT", lua):
                    self.assertEqual(1, self.run_capture(root, fake_run))
                self.assertIn("runtime input changed during replay", self.capture_stderr)
                self.assertFalse((root / "captures" / "first" / "000100.genstate").exists())
                self.assertEqual(
                    "failed", json.loads((root / "captures" / "capture_receipt.json").read_text())["status"]
                )

    def test_private_snapshot_mutation_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)

            def fake_run(
                command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
            ) -> subprocess.CompletedProcess:
                result = self.fake_success(command, cwd, timeout, environment)
                Path(command[command.index("-play") + 1]).write_bytes(b"snapshot mutation")
                return result

            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("private runtime snapshot changed", self.capture_stderr)
            self.assertFalse((root / "captures" / "first" / "000100.genstate").exists())

    def test_native_contract_changes_fail_before_publication(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)

            def fake_run(
                command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
            ) -> subprocess.CompletedProcess:
                result = self.fake_success(command, cwd, timeout, environment)
                run_runtime_scenarios.runtime_isolation.native_config_contract.return_value = {"native": "changed"}
                return result

            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("native runtime config contract changed", self.capture_stderr)
            self.assertFalse((root / "captures" / "first" / "000100.genstate").exists())

    def test_session_sidecars_fail_before_publication(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)

            def fake_run(
                command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
            ) -> subprocess.CompletedProcess:
                result = self.fake_success(command, cwd, timeout, environment)
                (cwd / "preservation.ips").write_bytes(b"unrequested patch")
                return result

            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertFalse((root / "captures" / "first" / "000100.genstate").exists())
            self.assertFalse((root / "captures" / "second").exists())

    def test_config_seed_mutation_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_inputs(root)

            def fake_run(
                command: list[str], cwd: Path, timeout: int, environment: dict[str, str]
            ) -> subprocess.CompletedProcess:
                result = self.fake_success(command, cwd, timeout, environment)
                Path(command[command.index("-cfg") + 1]).write_bytes(b"unexpected config edit")
                return result

            self.assertEqual(1, self.run_capture(root, fake_run))
            self.assertIn("private native config changed", self.capture_stderr)
            self.assertFalse((root / "captures" / "first" / "000100.genstate").exists())

    def test_repository_bound_lua_is_neutral_and_frame_bounded(self) -> None:
        self.assertEqual(ROOT / "scripts" / "runtime_capture_frames.lua", run_runtime_scenarios.CAPTURE_SCRIPT)
        lua = run_runtime_scenarios.CAPTURE_SCRIPT.read_text(encoding="utf-8")
        self.assertIn('gens.speedmode("nothrottle")', lua)
        self.assertIn("gens.frameadvance()", lua)
        self.assertIn("stop_frame > 100001", lua)
        self.assertIn("os.exit(0)", lua)
        for forbidden in ("joypad.", "memory.", "savestate.", "gens.register", "vdp."):
            self.assertNotIn(forbidden, lua)

    def test_owned_process_is_reaped_on_wall_timeout(self) -> None:
        process = mock.Mock()
        process.wait.side_effect = [subprocess.TimeoutExpired("gens", 1), 0]
        process.poll.return_value = None
        with mock.patch.object(run_runtime_scenarios.subprocess, "Popen", return_value=process) as launch:
            with self.assertRaises(subprocess.TimeoutExpired):
                run_runtime_scenarios.run_hidden(["gens"], ROOT, 1, {"OWNED": "yes"})
        self.assertEqual({"OWNED": "yes"}, launch.call_args.kwargs["env"])
        process.terminate.assert_called_once()
        process.kill.assert_not_called()
        self.assertEqual([mock.call(timeout=1), mock.call(timeout=5)], process.wait.call_args_list)

    def test_owned_process_kill_fallback_on_interrupt(self) -> None:
        process = mock.Mock()
        process.wait.side_effect = [KeyboardInterrupt(), subprocess.TimeoutExpired("gens", 5), 0]
        process.poll.return_value = None
        with mock.patch.object(run_runtime_scenarios.subprocess, "Popen", return_value=process):
            with self.assertRaises(KeyboardInterrupt):
                run_runtime_scenarios.run_hidden(["gens"], ROOT, 1, {})
        process.terminate.assert_called_once()
        process.kill.assert_called_once()
        self.assertEqual(
            [mock.call(timeout=1), mock.call(timeout=5), mock.call(timeout=5)], process.wait.call_args_list
        )


if __name__ == "__main__":
    unittest.main()
