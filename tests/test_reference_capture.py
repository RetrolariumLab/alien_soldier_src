"""Test exact-frame reference inventory and non-overwriting archive ownership."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from io import BytesIO, StringIO
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import capture_reference as capture  # noqa: E402
from PIL import Image  # noqa: E402


def full_state(frame: int) -> bytes:
    data = bytearray(capture.STATE_LENGTH)
    data[:8] = b"GENSTATE"
    struct.pack_into("<IIQI", data, 8, 1, frame, 0, 0x55555558)
    offset = capture.STATE_TABLE_END
    for index, (kind, size) in enumerate(capture.STATE_LAYOUT):
        struct.pack_into("<IIII", data, 64 + 16 * index, kind, offset, size, 0)
        offset += size
    return bytes(data)


def png() -> bytes:
    with BytesIO() as output:
        Image.new("RGB", (320, 224)).save(output, format="PNG")
        return output.getvalue()


class ReferenceCaptureTests(unittest.TestCase):
    def inputs(self, root: Path) -> argparse.Namespace:
        (root / "config").mkdir()
        (root / "movies").mkdir()
        (root / "gens/Output").mkdir(parents=True)
        (root / "gens/Output/Gens.exe").write_bytes(b"pinned fixture executable")
        image = bytearray(2048)
        image[0x100:0x110] = b"SEGA MEGA DRIVE "
        struct.pack_into(">II", image, 0x1A0, 0, len(image) - 1)
        image[0x1F0:0x200] = b"B               "
        (root / "rom.bin").write_bytes(image)
        profiles = {"profiles": [{"id": "jp", "reference_rom": {
            "size": len(image), "sha256": hashlib.sha256(image).hexdigest()}}]}
        (root / "config/rom_profiles.json").write_text(json.dumps(profiles), encoding="utf-8")
        header = bytearray(64)
        header[:16] = b"Gens Movie TESTA"
        header[20:22] = b"36"
        movie = bytes(header) + b"\xff\xff\xff" * 12
        config = {"rom_checksum": "0x55555558", "movies": {}}
        for name in capture.MOVIES:
            (root / "movies" / (name + ".gmv")).write_bytes(movie)
            config["movies"][name] = {"path": "movies/" + name + ".gmv",
                                      "sha256": hashlib.sha256(movie).hexdigest()}
        (root / "config/runtime_scenarios.json").write_text(json.dumps(config), encoding="utf-8")
        (root / "config/toolchain.json").write_text("{}", encoding="utf-8")
        (root / "scripts").mkdir()
        (root / "scripts/run_runtime_scenarios.py").write_bytes(b"immutable runner fixture")
        return argparse.Namespace(movie="tas", rom=Path("rom.bin"), gens=Path("gens/Output/Gens.exe"),
                                  interval=1, max_frames=4, output_dir=Path("reference/tas"), timeout=5)

    def fake_replay(self, command: list[str], cwd: Path, timeout: int,
                    environment: dict[str, str]) -> subprocess.CompletedProcess:
        self.assertEqual([], list(cwd.iterdir()))
        self.assertNotIn("-turbo", command)
        self.assertNotIn("-save-state-dumps", command)
        self.assertEqual("0", command[command.index("-frameskip") + 1])
        self.assertEqual(str(capture.CAPTURE_SCRIPT), command[command.index("-lua") + 1])
        last = int(command[command.index("-dump-state-end") + 1])
        interval = int(command[command.index("-screenshot-interval") + 1])
        self.assertEqual(str(last + 1), command[command.index("-max-frames") + 1])
        self.assertEqual(str(last + 1), environment["ALIEN_RUNTIME_CAPTURE_STOP_FRAME"])
        self.assertEqual(str(interval), command[command.index("-dump-state-interval") + 1])
        self.assertEqual("1", command[command.index("-dump-state-start") + 1])
        frames = Path(command[command.index("-screenshot-dir") + 1])
        self.assertEqual(str(frames), command[command.index("-dump-state-dir") + 1])
        for frame in range(interval, last + 1, interval):
            (frames / ("%d.genstate" % frame)).write_bytes(full_state(frame))
            (frames / ("%06d.png" % frame)).write_bytes(png())
        return subprocess.CompletedProcess(command, 0)

    def run_capture(self, root: Path, args: argparse.Namespace, replay: object | None = None) -> Path:
        with mock.patch.object(capture.runtime_environment, "environment_identity", return_value={"source_commit": "a" * 40}), \
                mock.patch.object(capture, "native_capture_contract", return_value={"native": "fixture"}), \
                mock.patch.object(capture, "run_hidden", side_effect=replay or self.fake_replay), \
                redirect_stdout(StringIO()):
            return capture.capture(root, args)

    def receipt(self, session: Path) -> dict:
        return json.loads((session / "receipt.json").read_text(encoding="utf-8"))

    def test_every_requested_frame_has_actual_header_and_hashed_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            args = self.inputs(root)
            args.max_frames = 7
            args.interval = 2
            session = self.run_capture(root, args)
            receipt = self.receipt(session)
            self.assertEqual("captured", receipt["status"])
            self.assertEqual("complete_chunk_crc_structure_and_pillow_verify_load", receipt["png_integrity"])
            self.assertEqual(3, receipt["verified_frames"])
            records = [json.loads(line) for line in (session / "frame_inventory.jsonl").read_text().splitlines()]
            self.assertEqual([2, 4, 6], [item["frame"] for item in records])
            for row in records:
                self.assertEqual(row["frame"], row["native_header_frame"])
                self.assertEqual(capture.STATE_LENGTH, row["state_bytes"])
                self.assertEqual(capture.sha256(session / row["state"]), row["state_sha256"])
                self.assertEqual(capture.sha256(session / row["png"]), row["png_sha256"])
            self.assertEqual(capture.sha256(session / "frame_inventory.jsonl"), receipt["inventory_sha256"])
            self.assertEqual([], list(session.glob(".inputs-*")))

    def test_new_session_never_replaces_old_archives_or_manual_states(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            args = self.inputs(root)
            old = root / "reference/tas"
            old.mkdir(parents=True)
            (old / "000001.genstate").write_bytes(b"old manual state")
            (old / "000001.png").write_bytes(b"old screenshot")
            first = self.run_capture(root, args)
            marker = first / "manual.txt"
            marker.write_bytes(b"do not alter completed archive")
            first_receipt = (first / "receipt.json").read_bytes()
            second = self.run_capture(root, args)
            self.assertNotEqual(first, second)
            self.assertEqual(first_receipt, (first / "receipt.json").read_bytes())
            self.assertEqual(b"old manual state", (old / "000001.genstate").read_bytes())
            self.assertEqual(b"old screenshot", (old / "000001.png").read_bytes())
            self.assertEqual(b"do not alter completed archive", marker.read_bytes())

    def test_invalid_bounds_or_longplay_default_create_no_output(self) -> None:
        for maximum, interval, movie in ((0, 1, "tas"), (100001, 1, "tas"), (True, 1, "tas"),
                                         (4, 0, "tas"), (4, 5, "tas"), (None, 1, "longplay")):
            with self.subTest(maximum=maximum, interval=interval, movie=movie), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)
                args.max_frames, args.interval, args.movie = maximum, interval, movie
                with self.assertRaises(ValueError):
                    self.run_capture(root, args)
                self.assertFalse((root / "reference").exists())

    def test_unsafe_output_roots_and_links_are_rejected(self) -> None:
        for output in (Path("."), Path("docs"), Path("../build"), Path("rom.bin")):
            with self.subTest(output=output), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)
                args.output_dir = output
                with self.assertRaises(ValueError):
                    self.run_capture(root, args)
                self.assertFalse((root / "reference").exists())
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            args = self.inputs(root)
            linked = root / "reference"
            with mock.patch.object(Path, "is_symlink", autospec=True, side_effect=lambda path: path == linked):
                with self.assertRaisesRegex(ValueError, "crosses a link"):
                    self.run_capture(root, args)

    def test_wrong_movie_hash_or_rom_identity_is_rejected_before_outputs(self) -> None:
        for input_name in ("rom.bin", "movies/tas.gmv"):
            with self.subTest(input=input_name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)
                (root / input_name).write_bytes(b"wrong input")
                with self.assertRaises(ValueError):
                    self.run_capture(root, args)
                self.assertFalse((root / "reference").exists())

    def test_missing_corrupt_or_extra_capture_fails_with_nonpassing_receipt(self) -> None:
        for failure in ("missing", "zero_frame", "section", "extra", "png"):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)

                def fake(command: list[str], cwd: Path, timeout: int, env: dict[str, str]) -> subprocess.CompletedProcess:
                    result = self.fake_replay(command, cwd, timeout, env)
                    frames = Path(command[command.index("-screenshot-dir") + 1])
                    if failure == "missing":
                        (frames / "000002.png").unlink()
                    elif failure == "zero_frame":
                        (frames / "2.genstate").write_bytes(full_state(0))
                    elif failure == "section":
                        data = bytearray(full_state(2))
                        struct.pack_into("<I", data, 64, 99)
                        (frames / "2.genstate").write_bytes(data)
                    elif failure == "extra":
                        (frames / "unrequested.png").write_bytes(png())
                    else:
                        (frames / "000002.png").write_bytes(b"not a screenshot")
                    return result

                with self.assertRaises(ValueError):
                    self.run_capture(root, args, fake)
                sessions = list((root / "reference/tas").glob("capture-*"))
                self.assertEqual(1, len(sessions))
                self.assertEqual("failed", self.receipt(sessions[0])["status"])
                self.assertFalse((sessions[0] / "frame_inventory.jsonl").exists())

    def test_original_or_private_input_mutation_is_not_silently_adopted(self) -> None:
        for name in ("rom.bin", "movies/tas.gmv", "config/runtime_scenarios.json", "private_rom", "private_movie", "private_cfg"):
            with self.subTest(input=name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)

                def fake(command: list[str], cwd: Path, timeout: int, env: dict[str, str]) -> subprocess.CompletedProcess:
                    result = self.fake_replay(command, cwd, timeout, env)
                    flag = {"private_rom": "-rom", "private_movie": "-play", "private_cfg": "-cfg"}.get(name)
                    path = Path(command[command.index(flag) + 1]) if flag else root / name
                    path.write_bytes(b"mutation after authentication")
                    return result

                with self.assertRaises(ValueError):
                    self.run_capture(root, args, fake)
                session = next((root / "reference/tas").glob("capture-*"))
                self.assertEqual("failed", self.receipt(session)["status"])

    def test_native_sidecars_or_wall_timeout_leave_only_failed_new_session(self) -> None:
        for failure in ("sidecar", "timeout"):
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)

                def fake(command: list[str], cwd: Path, timeout: int, env: dict[str, str]) -> subprocess.CompletedProcess:
                    if failure == "timeout":
                        raise subprocess.TimeoutExpired(command, timeout)
                    result = self.fake_replay(command, cwd, timeout, env)
                    (cwd / "reference.ips").write_bytes(b"unexpected patch")
                    return result

                with self.assertRaises((ValueError, subprocess.TimeoutExpired)):
                    self.run_capture(root, args, fake)
                session = next((root / "reference/tas").glob("capture-*"))
                self.assertEqual("failed", self.receipt(session)["status"])
                self.assertEqual([], list(session.glob(".inputs-*")))

    def test_harness_native_identity_and_capture_proof_are_rechecked(self) -> None:
        for changed in ("script", "native", "proof"):
            with self.subTest(changed=changed), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                args = self.inputs(root)
                script = root / "capture_fixture.py"
                script.write_bytes(capture.SCRIPT.read_bytes())

                def fake(command: list[str], cwd: Path, timeout: int, env: dict[str, str]) -> subprocess.CompletedProcess:
                    result = self.fake_replay(command, cwd, timeout, env)
                    if changed == "script":
                        script.write_bytes(b"changed harness")
                    elif changed == "native":
                        capture.runtime_environment.environment_identity.return_value = {"source_commit": "different"}
                    else:
                        capture.native_capture_contract.return_value = {"native": "changed"}
                    return result

                with mock.patch.object(capture, "SCRIPT", script):
                    with self.assertRaises(ValueError):
                        self.run_capture(root, args, fake)
                session = next((root / "reference/tas").glob("capture-*"))
                self.assertEqual("failed", self.receipt(session)["status"])
                self.assertFalse((session / "frame_inventory.jsonl").exists())

    def test_actual_pinned_movie_metadata_and_default_bounds(self) -> None:
        config = json.loads((ROOT / "config/runtime_scenarios.json").read_text(encoding="utf-8"))
        for name, expected_frames in (("tas", 66736), ("menus", 90860), ("longplay", 206611)):
            movie = config["movies"][name]
            info = capture.known_movie_info((ROOT / movie["path"]).read_bytes(), movie["sha256"])
            self.assertEqual(expected_frames, info["frames"])
            self.assertFalse(info["state_required"])
            self.assertFalse(info["pal"])
        self.assertEqual({"tas": 90000, "menus": 90860}, capture.DEFAULT_BOUNDS)
        self.assertEqual(ROOT / "scripts/runtime_capture_frames.lua", capture.CAPTURE_SCRIPT)

    def test_complete_genstate_dimensions_are_source_bound(self) -> None:
        checkout = ROOT / "build/runtime-emulator/pinned-e14b925"
        if not (checkout / "src/state_dump.cpp").exists():
            self.skipTest("optional native source checkout is not installed")
        proof = capture.native_capture_contract(checkout)
        self.assertEqual(210768, proof["genstate_bytes"])
        self.assertEqual([list(item) for item in capture.STATE_LAYOUT], proof["section_layout"])
        self.assertEqual(set(capture.NATIVE_FILES), set(proof["source_sha256"]))

    def test_png_full_crc_chunk_structure_and_decoded_payload_are_required(self) -> None:
        def chunk(kind: bytes, data: bytes) -> bytes:
            import zlib
            return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

        valid = png()
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 320, 224, 8, 2, 0, 0, 0))
        iend = chunk(b"IEND", b"")
        cases = (valid[:24], valid[:-1], valid + b"trailing", valid[:40] + bytes([valid[40] ^ 1]) + valid[41:],
                 valid[:8] + ihdr + iend, valid[:8] + ihdr + chunk(b"IDAT", b"not zlib pixels") + iend,
                 valid[:8] + ihdr + ihdr + chunk(b"IDAT", b"bad") + iend)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "capture.png"
            path.write_bytes(valid)
            capture.png_header(path, 1)
            for index, data in enumerate(cases):
                with self.subTest(index=index):
                    path.write_bytes(data)
                    with self.assertRaisesRegex(ValueError, "PNG integrity/decode"):
                        capture.png_header(path, 1)


if __name__ == "__main__":
    unittest.main()
