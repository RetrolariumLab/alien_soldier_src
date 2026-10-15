from __future__ import annotations

import os
import hashlib
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import level_playtest  # noqa: E402


class PlaytestRomTests(unittest.TestCase):
    def fixture(self, root: Path, profile: str) -> tuple[Path, dict]:
        image = bytearray(0x200000)
        image[0x180:0x182] = profile.encode("ascii")
        image[0x1F0] = ord("B" if profile == "jp" else "A")
        original = root / "original.bin"
        original.write_bytes(image)
        reference = {"filename": original.name, "name": profile, "size": len(image),
                     "sha1": hashlib.sha1(image).hexdigest()}
        rom = root / "content.bin"
        # An edited payload is legitimate after recomputing its regional checksum.
        image[0x200:0x202] = b"\x12\x34"
        level_playtest.update_boot_checksum(image, profile)
        rom.write_bytes(image)
        return rom, {"reference_rom": reference}

    def test_edited_content_accepts_each_profile_and_reports_exact_digest(self) -> None:
        for profile in ("jp", "eu"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                rom, record = self.fixture(root, profile)
                with mock.patch.object(level_playtest, "select_profile", return_value=record):
                    digest = level_playtest.validate_playtest_rom(root, rom, profile)
                self.assertEqual(hashlib.sha256(rom.read_bytes()).hexdigest(), digest)

    def test_wrong_region_size_and_stale_checksum_are_rejected(self) -> None:
        for profile in ("jp", "eu"):
            for mutation, message in (("region", "header"), ("size", "length"),
                                      ("checksum", "boot checksum")):
                with self.subTest(profile=profile, mutation=mutation):
                    with tempfile.TemporaryDirectory() as directory:
                        root = Path(directory)
                        rom, record = self.fixture(root, profile)
                        image = bytearray(rom.read_bytes())
                        if mutation == "region":
                            image[0x1F0] ^= 1
                        elif mutation == "size":
                            image.pop()
                        else:
                            image[0x200] ^= 1
                        rom.write_bytes(image)
                        with mock.patch.object(level_playtest, "select_profile",
                                               return_value=record):
                            with self.assertRaisesRegex(ValueError, message):
                                level_playtest.validate_playtest_rom(root, rom, profile)

    def test_untrusted_reference_is_rejected_even_when_header_matches(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            rom, record = self.fixture(root, "jp")
            record["reference_rom"]["sha1"] = "f" * 40
            with mock.patch.object(level_playtest, "select_profile", return_value=record):
                with self.assertRaisesRegex(ValueError, "reference ROM differs"):
                    level_playtest.validate_playtest_rom(root, rom, "jp")


class LaunchLifecycleTests(unittest.TestCase):
    def run_case(self, root: Path, *, automated: bool, valid: bool = True,
                 interrupted: bool = False, report: str | None = None, sidecar: bool = False
                 ) -> tuple[int, mock.Mock, mock.Mock, Path]:
        gens = root / "Gens.exe"
        rom = root / "content.bin"
        result = root / "build/result.txt"
        result.parent.mkdir()
        gens.touch()
        rom.touch()
        result.write_text("previous evidence", encoding="utf-8")
        args = ["level_playtest.py", "--root", str(root), "--gens", str(gens),
                "--rom", str(rom), "--result", str(result)]
        if automated:
            args.append("--check")
        with (
            mock.patch.object(sys, "argv", args),
            mock.patch.object(level_playtest, "password_code", return_value=0x020A0906),
            mock.patch.object(level_playtest, "validate_playtest_rom", return_value=hashlib.sha256(b"").hexdigest(),
                              side_effect=None if valid else ValueError("wrong ROM")),
            mock.patch.object(level_playtest, "environment_identity", return_value={"fixture": "native"}),
            mock.patch.object(level_playtest.subprocess, "Popen") as launch,
            mock.patch.object(level_playtest, "stop") as stop,
            mock.patch.object(level_playtest.time, "sleep",
                              side_effect=OSError("wait failed") if interrupted else None),
            mock.patch("builtins.print"),
        ):
            launch.return_value.poll.return_value = None
            if report is not None:
                def publish_report(*_args, **_kwargs):
                    result.write_text(report, encoding="utf-8")
                    if sidecar:
                        command = _args[0]
                        config = Path(command[command.index("-cfg") + 1])
                        (config.parent / "native-sidecars/playtest.pat").write_bytes(b"patch")
                    return launch.return_value
                launch.side_effect = publish_report
            status = level_playtest.main()
        return status, launch, stop, result

    def test_invalid_rom_never_launches_or_removes_previous_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            status, launch, stop, result = self.run_case(
                Path(directory), automated=True, valid=False)
            self.assertEqual(1, status)
            launch.assert_not_called()
            stop.assert_not_called()
            self.assertEqual("previous evidence", result.read_text(encoding="utf-8"))

    def test_interactive_launch_preserves_evidence_and_leaves_window_running(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            status, launch, stop, result = self.run_case(Path(directory), automated=False)
            self.assertEqual(0, status)
            launch.assert_called_once()
            stop.assert_not_called()
            self.assertEqual("previous evidence", result.read_text(encoding="utf-8"))

    def test_automated_wait_failure_always_reaps_its_process(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            status, launch, stop, _result = self.run_case(
                Path(directory), automated=True, interrupted=True)
            self.assertEqual(1, status)
            stop.assert_called_once_with(launch.return_value)

    def test_rejected_atomic_report_is_not_retried_and_reaps_the_process(self) -> None:
        with tempfile.TemporaryDirectory() as directory, mock.patch.object(
                level_playtest, "parse_result", wraps=level_playtest.parse_result) as parse:
            status, launch, stop, _result = self.run_case(
                Path(directory), automated=True, report=(
                    "status=timeout profile=jp stage=1 stage_index=0000 "
                    "difficulty=2 mode=0048 player_type=0000 route=00 frame=4200\n"))
            self.assertEqual(1, status)
            parse.assert_called_once()
            stop.assert_called_once_with(launch.return_value)

    def test_keyboard_interrupt_during_a_stage_reaps_the_owned_process(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with mock.patch.object(level_playtest.subprocess, "Popen") as launch, \
                    mock.patch.object(level_playtest, "playtest_environment", return_value={}), \
                    mock.patch.object(level_playtest, "environment_identity", return_value={"fixture": "native"}), \
                    mock.patch.object(level_playtest, "validate_playtest_rom", return_value=hashlib.sha256(b"").hexdigest()), \
                    mock.patch.object(level_playtest.time, "sleep", side_effect=KeyboardInterrupt), \
                    mock.patch.object(level_playtest, "stop") as stop:
                launch.return_value.poll.return_value = None
                (root / "content.bin").touch()
                with self.assertRaises(KeyboardInterrupt):
                    level_playtest.run_stage(root, root / "Gens.exe", root / "content.bin",
                                            "jp", 1, "easy", root / "build/result.txt",
                                            automated=True)
                stop.assert_called_once_with(launch.return_value)

    def test_ready_stage_binds_private_cwd_config_snapshot_and_final_receipt(self) -> None:
        report = ("status=ready profile=jp stage=1 stage_index=0000 difficulty=0 "
                  "mode=0010 player_type=0008 route=00 frame=1004\n")
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            status, launch, stop, result = self.run_case(root, automated=True, report=report)
            self.assertEqual(0, status)
            stop.assert_called_once_with(launch.return_value)
            command = launch.call_args.args[0]
            config = Path(command[command.index("-cfg") + 1])
            snapshot = Path(command[command.index("-rom") + 1])
            self.assertNotEqual(root / "content.bin", snapshot)
            self.assertEqual(b"", snapshot.read_bytes())
            self.assertNotEqual(root, launch.call_args.kwargs["cwd"])
            receipt = json.loads(Path(str(result) + ".runtime.json").read_text(encoding="utf-8"))
            self.assertEqual("stage_ram_ready", receipt["status"])
            self.assertEqual(config.parent, Path(receipt["contract"]["native_isolation"]["session_directory"]))
            self.assertEqual("1004", receipt["fields"]["frame"])

    def test_ready_ram_cannot_bless_an_automatic_patch_sidecar(self) -> None:
        report = ("status=ready profile=jp stage=1 stage_index=0000 difficulty=0 "
                  "mode=0010 player_type=0008 route=00 frame=1004\n")
        with tempfile.TemporaryDirectory() as directory:
            status, _launch, stop, result = self.run_case(Path(directory), automated=True, report=report, sidecar=True)
            self.assertEqual(1, status)
            stop.assert_called_once()
            receipt = json.loads(Path(str(result) + ".runtime.json").read_text(encoding="utf-8"))
            self.assertEqual("failed", receipt["status"])


class DiagnosticTests(unittest.TestCase):
    def test_only_build_reports_are_replaceable_and_inputs_remain_protected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            rom, gens = root / "build/content.txt", root / "Gens.exe"
            accepted = root / "build/review output/result.txt"
            self.assertEqual(accepted, level_playtest.checked_result_path(
                root, accepted, rom, gens))
            for path in (root / "src/source.txt", root.parent / "outside.txt",
                         root / "build/../source.txt", rom, root / "build/report.bin"):
                with self.subTest(path=path), self.assertRaises(ValueError):
                    level_playtest.checked_result_path(root, path, rom, gens)

            for suffix in (".diagnostic.json", ".tmp", ".diagnostic.json.tmp"):
                with self.subTest(suffix=suffix), self.assertRaisesRegex(ValueError, "input file"):
                    level_playtest.checked_result_path(
                        root, accepted, Path(str(accepted) + suffix), gens)

    def test_missing_malformed_and_oversize_diagnostics_are_safe(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "report.txt"
            diagnostic = Path(str(result) + ".diagnostic.json")
            self.assertIn("no runtime diagnostic", level_playtest.diagnostic_summary(result))
            for contents in ("[]", "{", '{"phase":"gameplay","frame":true}', " " * 16385):
                diagnostic.write_text(contents, encoding="utf-8")
                self.assertIn("unreadable runtime diagnostic",
                              level_playtest.diagnostic_summary(result))

    def test_failure_summary_names_the_observed_state_and_retained_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "report.txt"
            diagnostic = Path(str(result) + ".diagnostic.json")
            diagnostic.write_text(json.dumps({
                "phase": "gameplay", "frame": 4200, "mode": 116, "substate": 2,
            }), encoding="utf-8")
            summary = level_playtest.diagnostic_summary(result)
            self.assertIn("phase=gameplay frame=4200 mode=$0074 substate=$0002", summary)
            self.assertIn(str(diagnostic), summary)

    def test_automated_windows_startup_is_hidden(self) -> None:
        information = mock.Mock(dwFlags=0, wShowWindow=1)
        with mock.patch.object(level_playtest.os, "name", "nt"), mock.patch.object(
                level_playtest.subprocess, "STARTUPINFO", return_value=information,
                create=True), mock.patch.object(
                    level_playtest.subprocess, "STARTF_USESHOWWINDOW", 1, create=True):
            self.assertIs(information, level_playtest.check_startup_info(True))
        self.assertEqual(1, information.dwFlags)
        self.assertEqual(0, information.wShowWindow)

    def test_interactive_and_nonwindows_startup_are_unchanged(self) -> None:
        with mock.patch.object(level_playtest.os, "name", "nt"):
            self.assertIsNone(level_playtest.check_startup_info(False))
        with mock.patch.object(level_playtest.os, "name", "posix"):
            self.assertIsNone(level_playtest.check_startup_info(True))


class AllStageBatchTests(unittest.TestCase):
    def setUp(self) -> None:
        output = mock.patch("builtins.print")
        output.start()
        self.addCleanup(output.stop)
        self.native = mock.patch.object(level_playtest, "environment_identity", return_value={"fixture": "native"})
        self.native.start()
        self.addCleanup(self.native.stop)

    def fixture(self, root: Path) -> tuple[Path, Path, Path, str]:
        rom = root / "content.bin"
        gens = root / "Gens.exe"
        rom.write_bytes(b"synthetic ROM snapshot")
        gens.write_bytes(b"synthetic emulator")
        (root / "config").mkdir()
        (root / "config/toolchain.json").write_bytes(b"synthetic pinned manifest")
        result = root / "build/coldboot.txt"
        return gens, rom, result, hashlib.sha256(rom.read_bytes()).hexdigest()

    def inventory(self) -> list[dict]:
        return [{"stage": stage} for stage in range(1, 26)]

    def fake_stage(self, _root, _gens, _rom, profile, stage, _difficulty, result, *, automated):
        self.assertTrue(automated)
        result.parent.mkdir(parents=True, exist_ok=True)
        result.write_text(
            "status=ready profile=%s stage=%d stage_index=%04X "
            "difficulty=0 mode=0010 player_type=0008 route=%02X frame=%d\n" % (
                profile, stage, (stage - 1) * 2, 0 if stage == 1 else 1, 1000 + stage),
            encoding="utf-8")
        Path(str(result) + ".diagnostic.json").write_text(json.dumps({
            "status": "ready", "profile": profile, "stage": stage, "difficulty": 0,
            "route": 0 if stage == 1 else 1, "frame": 1000 + stage, "mode": 0x10,
            "stage_index": (stage - 1) * 2, "player_type": 8,
        }), encoding="utf-8")
        Path(str(result) + ".runtime.json").write_text(json.dumps({
            "status": "stage_ram_ready", "fields": level_playtest.parse_result(result, profile, stage, "easy"),
            "contract": {
                "runtime_environment": level_playtest.environment_identity(_root, _gens),
                "runner_sha256": level_playtest.file_sha256(Path(level_playtest.__file__)),
                "lua_sha256": level_playtest.file_sha256(level_playtest.SCRIPT),
            },
        }), encoding="utf-8")

    def test_incomplete_duplicate_boolean_and_reordered_inventory_fail_closed(self) -> None:
        valid = self.inventory()
        for inventory in (valid[:-1], valid + [valid[0]],
                          [{"stage": True}, *valid[1:]], list(reversed(valid))):
            with self.subTest(inventory=inventory), mock.patch.object(
                    level_playtest, "password_codes", return_value=inventory):
                with self.assertRaisesRegex(ValueError, "all 25 stages exactly once"):
                    level_playtest.reachable_stages(ROOT)

    def test_full_receipt_covers_exactly_twenty_five_sequential_snapshot_runs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            gens, rom, result, digest = self.fixture(root)
            with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                    mock.patch.object(level_playtest, "run_stage", side_effect=self.fake_stage) as run:
                path = level_playtest.run_all_stages(
                    root, gens, rom, "jp", "easy", result, digest)
            receipt = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual("passed", receipt["status"])
            self.assertEqual(25, receipt["completed_count"])
            self.assertEqual(list(range(1, 26)), [record["stage"] for record in receipt["stages"]])
            self.assertEqual(digest, receipt["rom_sha256"])
            self.assertEqual(hashlib.sha256(rom.read_bytes()).hexdigest(), digest)
            snapshots = [call.args[2] for call in run.call_args_list]
            self.assertEqual(25, len(snapshots))
            self.assertEqual(1, len(set(snapshots)))
            self.assertNotEqual(rom, snapshots[0])
            self.assertFalse(snapshots[0].exists())
            for record in receipt["stages"]:
                for field in ("result", "diagnostic", "native_receipt"):
                    output = root / record[field]
                    self.assertEqual(hashlib.sha256(output.read_bytes()).hexdigest(),
                                     record[field + "_sha256"])

    def test_failure_replaces_old_success_with_partial_failed_receipt_and_cleans_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            gens, rom, result, digest = self.fixture(root)
            result.parent.mkdir()
            receipt_path = result.with_name("coldboot_all.json")
            receipt_path.write_text('{"status":"passed","completed_count":25}', encoding="utf-8")

            def fail_third(*args, **kwargs):
                if args[4] == 3:
                    raise RuntimeError("synthetic stage failed")
                self.fake_stage(*args, **kwargs)

            with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                    mock.patch.object(level_playtest, "run_stage", side_effect=fail_third) as run:
                with self.assertRaisesRegex(RuntimeError, "synthetic stage failed"):
                    level_playtest.run_all_stages(root, gens, rom, "eu", "easy", result, digest)
            receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
            self.assertEqual("failed", receipt["status"])
            self.assertEqual(2, receipt["completed_count"])
            self.assertEqual([1, 2], [record["stage"] for record in receipt["stages"]])
            self.assertEqual(3, run.call_count)
            self.assertFalse(run.call_args.args[2].exists())

    def test_diagnostic_disagreement_cannot_become_a_pass(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            gens, rom, result, digest = self.fixture(root)

            def disagree(*args, **kwargs):
                self.fake_stage(*args, **kwargs)
                path = Path(str(args[6]) + ".diagnostic.json")
                observed = json.loads(path.read_text(encoding="utf-8"))
                observed["player_type"] = 0
                path.write_text(json.dumps(observed), encoding="utf-8")

            with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                    mock.patch.object(level_playtest, "run_stage", side_effect=disagree):
                with self.assertRaisesRegex(RuntimeError, "diagnostic disagrees"):
                    level_playtest.run_all_stages(root, gens, rom, "jp", "easy", result, digest)
            receipt = json.loads(result.with_name("coldboot_all.json").read_text(encoding="utf-8"))
            self.assertEqual("failed", receipt["status"])
            self.assertEqual(0, receipt["completed_count"])

    def test_interrupted_batch_has_no_success_receipt_and_cleans_its_snapshot(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            gens, rom, result, digest = self.fixture(root)
            with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                    mock.patch.object(level_playtest, "run_stage", side_effect=KeyboardInterrupt) as run:
                with self.assertRaises(KeyboardInterrupt):
                    level_playtest.run_all_stages(root, gens, rom, "jp", "easy", result, digest)
            receipt = json.loads(result.with_name("coldboot_all.json").read_text(encoding="utf-8"))
            self.assertEqual("failed", receipt["status"])
            self.assertEqual(0, receipt["completed_count"])
            self.assertFalse(run.call_args.args[2].exists())

    def test_changed_rom_is_rejected_before_prior_receipt_is_invalidated(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            gens, rom, result, _digest = self.fixture(root)
            result.parent.mkdir()
            receipt = result.with_name("coldboot_all.json")
            receipt.write_text("prior evidence", encoding="utf-8")
            with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                    mock.patch.object(level_playtest, "run_stage") as run:
                with self.assertRaisesRegex(ValueError, "changed before the batch snapshot"):
                    level_playtest.run_all_stages(root, gens, rom, "jp", "easy", result, "f" * 64)
            run.assert_not_called()
            self.assertEqual("prior evidence", receipt.read_text(encoding="utf-8"))

    def test_runtime_or_lua_changes_during_the_batch_invalidate_the_final_receipt(self) -> None:
        for mutation in ("gens", "lua"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory).resolve()
                gens, rom, result, digest = self.fixture(root)
                lua = root / "runtime.lua"
                lua.write_bytes(b"synthetic stable Lua")

                def mutate_final(*args, **kwargs):
                    self.fake_stage(*args, **kwargs)
                    if args[4] == 25:
                        (gens if mutation == "gens" else lua).write_bytes(b"modified runtime")

                with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                        mock.patch.object(level_playtest, "SCRIPT", lua), \
                        mock.patch.object(level_playtest, "run_stage", side_effect=mutate_final):
                    with self.assertRaisesRegex(RuntimeError, "changed during the stage batch"):
                        level_playtest.run_all_stages(root, gens, rom, "jp", "easy", result, digest)
                receipt = json.loads(result.with_name("coldboot_all.json").read_text(encoding="utf-8"))
                self.assertEqual("failed", receipt["status"])
                self.assertEqual(25, receipt["completed_count"])

    def test_all_stage_selection_cannot_silently_ignore_an_explicit_stage(self) -> None:
        with mock.patch.object(sys, "argv", ["level_playtest.py", "--rom", "content.bin",
                                             "--check-all", "--stage", "13"]), \
                mock.patch.object(level_playtest.subprocess, "Popen") as launch, \
                mock.patch.object(sys, "stderr"):
            with self.assertRaises(SystemExit) as exit_status:
                level_playtest.main()
        self.assertEqual(2, exit_status.exception.code)
        launch.assert_not_called()

    def test_native_or_manifest_drift_between_stages_cannot_publish_pass(self) -> None:
        for mutation in ("environment", "manifest", "stage_contract"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as directory:
                root = Path(directory).resolve()
                gens, rom, result, digest = self.fixture(root)
                identity = {"fixture": "native"}

                def drift(*args, **kwargs):
                    self.fake_stage(*args, **kwargs)
                    if args[4] != 2:
                        return
                    if mutation == "environment":
                        identity["fixture"] = "different compiler output"
                    elif mutation == "manifest":
                        (root / "config/toolchain.json").write_bytes(b"different pin")
                    else:
                        path = Path(str(args[6]) + ".runtime.json")
                        proof = json.loads(path.read_text(encoding="utf-8"))
                        proof["contract"]["lua_sha256"] = "0" * 64
                        path.write_text(json.dumps(proof), encoding="utf-8")

                with mock.patch.object(level_playtest, "password_codes", return_value=self.inventory()), \
                        mock.patch.object(level_playtest, "environment_identity", side_effect=lambda *_: dict(identity)), \
                        mock.patch.object(level_playtest, "run_stage", side_effect=drift) as run:
                    with self.assertRaisesRegex(RuntimeError, "batch"):
                        level_playtest.run_all_stages(root, gens, rom, "jp", "easy", result, digest)
                receipt = json.loads(result.with_name("coldboot_all.json").read_text(encoding="utf-8"))
                self.assertEqual("failed", receipt["status"])
                self.assertEqual(2, run.call_count)


class PasswordTableTests(unittest.TestCase):
    def test_all_twenty_five_stage_passwords_are_decoded(self) -> None:
        records = level_playtest.password_codes(ROOT)
        self.assertEqual(25, len(records))
        self.assertEqual(0x020A0906, records[0]["easy"])
        self.assertEqual(0x020A0401, records[12]["easy"])
        self.assertEqual(0x0603090A, records[-1]["easy"])

    def test_secondary_records_are_identical_and_therefore_shadowed(self) -> None:
        records = level_playtest.password_codes(ROOT)
        self.assertTrue(all(
            item["easy"] == item["shadowed_secondary"] for item in records))

    def test_only_password_reachable_stages_and_difficulty_are_accepted(self) -> None:
        with self.assertRaisesRegex(ValueError, "stage must be"):
            level_playtest.password_code(ROOT, 0, "easy")
        with self.assertRaisesRegex(ValueError, "reachable easy"):
            level_playtest.password_code(ROOT, 1, "hard")


class LaunchContractTests(unittest.TestCase):
    def test_environment_binds_profile_stage_difficulty_and_real_password(self) -> None:
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(
                os.environ, {"ALIEN_PLAYTEST_EXIT": "stale"}, clear=False):
            result = Path(directory) / "result.txt"
            environment = level_playtest.playtest_environment(
                ROOT, "eu", 13, "easy", result, exit_when_ready=True)
        self.assertEqual("eu", environment["ALIEN_PLAYTEST_PROFILE"])
        self.assertEqual("13", environment["ALIEN_PLAYTEST_STAGE"])
        self.assertEqual("0", environment["ALIEN_PLAYTEST_DIFFICULTY"])
        self.assertEqual("020A0401", environment["ALIEN_PLAYTEST_PASSWORD"])
        self.assertEqual("1", environment["ALIEN_PLAYTEST_EXIT"])
        self.assertEqual(str(result.resolve()), environment["ALIEN_PLAYTEST_RESULT"])

    def test_automated_command_is_bounded_and_uses_the_reviewed_lua(self) -> None:
        command = level_playtest.playtest_command(
            Path("gens.exe"), Path("content.bin"), automated=True)
        self.assertEqual(str(level_playtest.SCRIPT.resolve()), command[4])
        self.assertIn("-max-frames", command)
        self.assertEqual(
            str(level_playtest.MAX_PLAYTEST_FRAMES),
            command[command.index("-max-frames") + 1])
        self.assertIn("-nosound", command)

    def test_result_requires_the_selected_stage_and_live_player(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "result.txt"
            result.write_text(
                "status=ready profile=jp stage=13 stage_index=0018 "
                "difficulty=0 mode=0010 player_type=0008 route=01 frame=731\n",
                encoding="utf-8")
            fields = level_playtest.parse_result(result, "jp", 13, "easy")
            self.assertEqual("731", fields["frame"])
            result.write_text(
                result.read_text(encoding="utf-8").replace(
                    "stage_index=0018", "stage_index=0016"),
                encoding="utf-8")
            with self.assertRaisesRegex(RuntimeError, "playtest failed"):
                level_playtest.parse_result(result, "jp", 13, "easy")

    def test_result_rejects_ambiguous_or_out_of_bounds_reports(self) -> None:
        valid = (
            "status=ready profile=jp stage=13 stage_index=0018 "
            "difficulty=0 mode=0010 player_type=0008 route=01 frame=731\n")
        with tempfile.TemporaryDirectory() as directory:
            result = Path(directory) / "result.txt"
            for report in (
                    valid.replace("frame=731", "frame=4201"),
                    valid.replace("route=01", "route=invalid"),
                    valid.replace("frame=731", "frame=731 frame=731"),
                    valid + valid):
                with self.subTest(report=report):
                    result.write_text(report, encoding="utf-8")
                    with self.assertRaises(RuntimeError):
                        level_playtest.parse_result(result, "jp", 13, "easy")

    def test_lua_enters_the_real_password_handler(self) -> None:
        script = level_playtest.SCRIPT.read_text(encoding="utf-8")
        self.assertIn("memory.writeword(ram.game_mode, 0x0044)", script)
        self.assertIn("memory.writelong(ram.password_digits, password)", script)
        self.assertNotIn("memory.writeword(ram.stage_index", script)
        self.assertNotIn("memory.writeword(ram.difficulty", script)
        self.assertIn(
            "for frame = 1, %d do" % level_playtest.MAX_PLAYTEST_FRAMES,
            script)


class SourceRouteTests(unittest.TestCase):
    def test_every_lua_ram_address_matches_its_source_symbol(self) -> None:
        symbols = dict(re.findall(
            r"(?m)^(\w+)\s+equ\s+([^;\r\n]+)",
            (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")))

        def resolve(expression: str) -> int:
            total = 0
            for term in expression.strip().split("+"):
                term = term.strip()
                if term.startswith("$"):
                    total += int(term[1:], 16)
                elif term.isdecimal():
                    total += int(term)
                else:
                    total += resolve(symbols[term])
            return total

        names = {
            "game_mode": "GameModeIndex", "game_substate": "GameSubstateIndex",
            "stage_index": "StageTableIndex", "stage_route": "StageRouteFlags",
            "difficulty": "DifficultyMode", "password_digits": "PasswordDigits",
            "password_cursor": "PasswordCursorOffset",
            "password_cursor_move": "PasswordCursorMoveFlag",
            "player_type": "PlayerObjectType", "palette_fade_status": "PaletteFadeMaskStatus",
            "scene_palette_offset": "ScenePaletteFadeOffset",
            "data_loader_control": "DataLoaderControl",
            "palette_fade_color_offset": "PaletteFadeColorOffset",
            "palette_fade_mode": "PaletteFadeMode", "controller_pressed": "ControllerPressedState",
            "controller_held": "ControllerHeldState", "setup_index": "SetupTransitionIndex",
            "setup_scroll_target": "WeaponSetupVScrollTarget",
            "secondary_camera_y": "SecondaryCameraYPos", "weapon_slot": "WeaponSlotOffset",
        }
        block = level_playtest.SCRIPT.read_text(encoding="utf-8").split("local ram = {", 1)[1]
        actual = {name: int(value, 16) for name, value in re.findall(
            r"(\w+)\s*=\s*(0x[0-9A-F]+)", block.split("}", 1)[0])}
        self.assertEqual(set(names), set(actual))
        for name, symbol in names.items():
            self.assertEqual(resolve(symbols[symbol]) & 0xFFFFFF, actual[name], symbol)

    def test_observed_modes_resolve_to_real_dispatcher_handlers(self) -> None:
        table = (ROOT / "src/system/vblank.s").read_text(encoding="utf-8").split(
            "Sys_GameStateHandlers:", 1)[1].split("; End of function", 1)[0]
        handlers = re.findall(r"\bdc\.l\s+(\w+)", table)
        for mode, handler in {
            0x10: "Sys_GameplayMainLoop", 0x18: "TitleScreen_Update",
            0x28: "StoryScreen_MainLoop", 0x3C: "StageReady_Initialize",
            0x44: "PasswordMenu_Initialize", 0x48: "PasswordMenu_Update",
            0x70: "WeaponSetup_InitializeScreen", 0x74: "WeaponSetup_UpdateScreen",
        }.items():
            self.assertEqual(handler, handlers[mode // 4])

    def test_intro_and_setup_inputs_are_bound_to_their_source_readers(self) -> None:
        story = (ROOT / "src/cutscenes/story_screen_and_title_transition.s").read_text(
            encoding="utf-8")
        reader = level_playtest.source_range(story, "StoryScreen_MainLoop", "StoryScreen_RunFrame")
        self.assertRegex(reader, r"btst\s+#0,\(PaletteFadeMaskStatus\)\.w")
        self.assertRegex(reader, r"tst\.w\s+\(ScenePaletteFadeOffset\)\.l")
        self.assertRegex(reader, r"tst\.w\s+\(DataLoaderControl\)\.w")
        self.assertRegex(reader, r"btst\s+#7,\(ControllerPressedState\)\.w")
        self.assertRegex(reader, r"bne\.w\s+StoryScreen_StartExitFade")
        password = (ROOT / level_playtest.PASSWORD_SOURCE).read_text(encoding="utf-8")
        confirmation = level_playtest.source_range(
            password, "PasswordValidation_RenderMatch", "PasswordInput_WaitForConfirm")
        self.assertRegex(confirmation, r"btst\s+#5,\(ControllerPressedState\)\.w")
        self.assertIn("jmp     Password_InitializeSelectedStage", confirmation)
        setup = (ROOT / "src/ui/weapon_setup_screen.s").read_text(encoding="utf-8")
        reader = level_playtest.source_range(
            setup, "WeaponSetup_WaitForConfirmInput", "WeaponSetup_ConfirmAndBeginFade")
        self.assertRegex(reader, r"btst\s+#7,\(ControllerPressedState\)\.w")
        script = level_playtest.SCRIPT.read_text(encoding="utf-8")
        self.assertIn("joypad.set(1, {start=true})", script)
        self.assertIn("joypad.set(1, {C=true})", script)
        self.assertNotIn("{B=true}", script)
        self.assertIn("memory.readbyte(ram.palette_fade_status) % 2 == 1", script)
        self.assertIn("memory.readword(ram.scene_palette_offset) == 0", script)
        self.assertIn("memory.readword(ram.data_loader_control) < 0x8000", script)
        self.assertEqual({"game_mode", "game_substate", "password_digits", "password_cursor",
                          "password_cursor_move"}, set(re.findall(
                              r"memory\.write(?:word|long|byte)\(ram\.(\w+)", script)))

    def test_native_gens_button_names_and_raw_c_bit_when_source_is_available(self) -> None:
        candidates = (ROOT / "build/runtime-emulator/pinned-e14b925/src",
                      ROOT.parent / "gens_automation/src")
        native = next((path for path in candidates if (path / "luascript.cpp").is_file()), None)
        if native is None:
            self.skipTest("Gens source checkout is optional for the lightweight unit suite")
        api = (native / "luascript.cpp").read_text(encoding="utf-8", errors="replace")
        self.assertIn('{1, 6, "C"}', api)
        self.assertIn('{1, 7, "start"}', api)
        port = (native / "io.asm").read_text(encoding="utf-8", errors="replace")
        high = port.split(".Third_High", 2)[-1].split(".First_Low", 1)[0]
        self.assertIn("mov eax, [Controller_1_C]", high)
        self.assertIn("mov ebx, [Controller_1_B]", high)
        self.assertIn("lea eax, [eax * 2 + ebx + 0x40]", high)


if __name__ == "__main__":
    unittest.main()
