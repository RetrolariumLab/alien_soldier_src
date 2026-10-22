"""Authenticate exact-frame receipts without running an emulator."""

from __future__ import annotations

import hashlib
import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import runtime_isolation  # noqa: E402
import validate_runtime_scenarios as validator  # noqa: E402


NATIVE_CONTRACT = {"schema_version": 1, "source_sha256": {"fixture": "1" * 64}}


def state_bytes(frame: int, version: int = 1, checksum: int = 0x55555558) -> bytes:
    header = bytearray(96)
    header[:8] = b"GENSTATE"
    struct.pack_into("<IIQI", header, 8, version, frame, 0, checksum)
    struct.pack_into("<IIII", header, 64, 1, 96, 65536, 0)
    return bytes(header) + bytes(65536)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class RuntimeCaptureReceiptTests(unittest.TestCase):
    def make_fixture(self, root: Path) -> None:
        for directory in ("scripts", "config", "movies", "gens/Output", "captures/first"):
            (root / directory).mkdir(parents=True)
        for name in ("run_runtime_scenarios.py", "runtime_capture_frames.lua", "runtime_isolation.py"):
            (root / "scripts" / name).write_bytes((ROOT / "scripts" / name).read_bytes())
        rom = b"canonical Japanese fixture"
        gens = b"source-built fixture executable"
        movie = b"authenticated recorded controller stream"
        (root / "rom.bin").write_bytes(rom)
        (root / "gens/Output/Gens.exe").write_bytes(gens)
        (root / "movies/tas.gmv").write_bytes(movie)
        inventory = [{"id": "first", "movie": "tas", "frame": 20}]
        config = {
            "rom_checksum": "0x55555558",
            "movies": {"tas": {"path": "movies/tas.gmv", "sha256": sha(movie)}},
            "scenarios": [
                {
                    **inventory[0],
                    "expectations": [
                        {"symbol": "Mode", "address": "0xFF0000", "type": "u16", "equals": "0"},
                        {"symbol": "Mode", "address": "0xFF0000", "type": "u16", "equals": "0"},
                    ],
                }
            ],
        }
        config_bytes = (json.dumps(config) + "\n").encode("utf-8")
        (root / "config/scenarios.json").write_bytes(config_bytes)
        (root / "config/rom_profiles.json").write_text(
            json.dumps({"profiles": [{"id": "jp", "reference_rom": {"size": len(rom), "sha256": sha(rom)}}]}),
            encoding="utf-8",
        )
        (root / "config/toolchain.json").write_text(
            json.dumps(
                {
                    "components": [
                        {
                            "id": "emulator",
                            "source_commit": "a" * 40,
                            "files": {"any": [{"path": "../gens/Output/Gens.exe"}]},
                        }
                    ]
                }
            ),
            encoding="utf-8",
        )
        state = state_bytes(20)
        png = b"diagnostic screenshot fixture"
        (root / "captures/first/000020.genstate").write_bytes(state)
        (root / "captures/first/000020.png").write_bytes(png)
        with tempfile.TemporaryDirectory(prefix=".runtime-inputs-", dir=root / "captures") as private:
            session = Path(private) / "first"
            session.mkdir()
            config_seed, isolation = runtime_isolation.isolated_config(session, sound=False)
        receipt = {
            "schema_version": 1,
            "status": "captured",
            "requested_frames": 20,
            "scope": "named_ram_scenario_replay_not_renderer_or_audio_fidelity",
            "rom_sha256": sha(rom),
            "gens_sha256": sha(gens),
            "capture_runner_sha256": sha((root / "scripts/run_runtime_scenarios.py").read_bytes()),
            "capture_lua_sha256": sha((root / "scripts/runtime_capture_frames.lua").read_bytes()),
            "runtime_isolation_sha256": sha((root / "scripts/runtime_isolation.py").read_bytes()),
            "scenario_config_sha256": sha(config_bytes),
            "movies": {"tas": sha(movie)},
            "native_config_contract": NATIVE_CONTRACT,
            "expected_scenarios": inventory,
            "scenarios": [
                {
                    **inventory[0],
                    "native_header_frame": 20,
                    "isolated_config_sha256": sha(config_seed),
                    "isolation": isolation,
                    "state_sha256": sha(state),
                    "screenshot_sha256": sha(png),
                }
            ],
        }
        (root / "captures/capture_receipt.json").write_text(json.dumps(receipt), encoding="utf-8")

    def change_receipt(self, root: Path, change: object) -> None:
        path = root / "captures/capture_receipt.json"
        receipt = json.loads(path.read_text(encoding="utf-8"))
        change(receipt)
        path.write_text(json.dumps(receipt), encoding="utf-8")

    def validate(self, root: Path, native_error: str | None = None) -> list[str]:
        def check_pin(component: dict, errors: list[str], notes: list[str], checkout: Path) -> None:
            self.assertEqual("a" * 40, component["source_commit"])
            self.assertEqual(root / "gens", checkout)
            if native_error:
                errors.append(native_error)

        with (
            mock.patch.object(validator, "check_emulator_commit", side_effect=check_pin),
            mock.patch.object(validator.runtime_isolation, "native_config_contract", return_value=NATIVE_CONTRACT),
        ):
            return validator.validate_receipt(
                root / "config/scenarios.json", root / "captures", root / "gens/Output/Gens.exe", root / "rom.bin", root
            )

    def test_complete_receipt_authenticates_current_inputs_and_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_fixture(root)
            self.assertEqual([], self.validate(root))

    def test_missing_running_failed_or_unknown_receipt_cannot_pass(self) -> None:
        for status in (None, "running", "failed", "passed"):
            with self.subTest(status=status), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_fixture(root)
                if status is None:
                    (root / "captures/capture_receipt.json").unlink()
                else:
                    self.change_receipt(root, lambda receipt: receipt.update(status=status))
                self.assertTrue(self.validate(root))

    def test_schema_scope_inventory_and_total_are_fail_closed(self) -> None:
        changes = (
            lambda receipt: receipt.update(schema_version=True),
            lambda receipt: receipt.update(scope="renderer_fidelity"),
            lambda receipt: receipt.update(expected_scenarios=[]),
            lambda receipt: receipt.update(scenarios=[]),
            lambda receipt: receipt["scenarios"].append(receipt["scenarios"][0]),
            lambda receipt: receipt.update(requested_frames=21),
            lambda receipt: receipt["scenarios"][0].update(native_header_frame=0),
            lambda receipt: receipt["scenarios"][0]["isolation"].update(schema_version=True),
        )
        for index, change in enumerate(changes):
            with self.subTest(index=index), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_fixture(root)
                self.change_receipt(root, change)
                self.assertTrue(self.validate(root))

    def test_every_mutable_input_is_bound_to_its_actual_hash(self) -> None:
        for name in (
            "rom.bin",
            "gens/Output/Gens.exe",
            "movies/tas.gmv",
            "config/scenarios.json",
            "scripts/run_runtime_scenarios.py",
            "scripts/runtime_capture_frames.lua",
            "scripts/runtime_isolation.py",
        ):
            with self.subTest(input=name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_fixture(root)
                path = root / name
                path.write_bytes(path.read_bytes() + b"\n")
                self.assertTrue(self.validate(root))

    def test_artifact_mutation_or_unsafe_link_is_rejected(self) -> None:
        for name in ("000020.genstate", "000020.png"):
            with self.subTest(artifact=name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_fixture(root)
                path = root / "captures/first" / name
                with mock.patch.object(Path, "is_symlink", autospec=True, side_effect=lambda target: target == path):
                    self.assertTrue(self.validate(root))
                path.write_bytes(path.read_bytes() + b"changed")
                self.assertIn("artifact hash differs", " ".join(self.validate(root)))

    def test_native_header_is_checked_even_if_receipt_artifact_hash_was_replaced(self) -> None:
        for frame, version, checksum in ((0, 1, 0x55555558), (20, 2, 0x55555558), (20, 1, 0)):
            with (
                self.subTest(frame=frame, version=version, checksum=checksum),
                tempfile.TemporaryDirectory() as directory,
            ):
                root = Path(directory)
                self.make_fixture(root)
                data = state_bytes(frame, version, checksum)
                (root / "captures/first/000020.genstate").write_bytes(data)
                self.change_receipt(root, lambda receipt: receipt["scenarios"][0].update(state_sha256=sha(data)))
                self.assertIn("actual native state header/RAM differs", " ".join(self.validate(root)))

    def test_source_pin_and_native_contract_are_independently_required(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_fixture(root)
            self.assertIn("wrong source commit", " ".join(self.validate(root, "wrong source commit")))
            self.change_receipt(root, lambda receipt: receipt.update(native_config_contract={}))
            self.assertIn("native config source contract differs", " ".join(self.validate(root)))

    def test_canonical_japanese_profile_is_required_beyond_weak_checksum(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_fixture(root)
            (root / "rom.bin").write_bytes(b"different region fixture")
            self.change_receipt(root, lambda receipt: receipt.update(rom_sha256=sha((root / "rom.bin").read_bytes())))
            self.assertIn("canonical Japanese ROM", " ".join(self.validate(root)))

    def test_private_isolation_evidence_cannot_redirect_native_inputs(self) -> None:
        for field in ("general_paths", "startup_directories", "config_sha256", "session_directory"):
            with self.subTest(field=field), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                self.make_fixture(root)
                value = {} if field in {"general_paths", "startup_directories"} else "not-a-private-session"
                self.change_receipt(root, lambda receipt: receipt["scenarios"][0]["isolation"].update({field: value}))
                self.assertIn("private native isolation contract differs", " ".join(self.validate(root)))

    def test_legacy_named_ram_validation_still_accepts_zero_header_frame(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_fixture(root)
            (root / "captures/first/000020.genstate").write_bytes(state_bytes(0))
            (root / "captures/capture_receipt.json").unlink()
            config = json.loads((root / "config/scenarios.json").read_text(encoding="utf-8"))
            self.assertEqual([], validator.validate(config, root / "captures", {"Mode": 0xFF0000}))


if __name__ == "__main__":
    unittest.main()
