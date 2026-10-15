#!/usr/bin/env python3
"""Replay the pinned movies and capture one state for each runtime scenario."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

import runtime_isolation
from runtime_state import Genstate


CAPTURE_SCRIPT = Path(__file__).resolve().with_name("runtime_capture_frames.lua")
RUNNER_SCRIPT = Path(__file__).resolve()
MAX_SCENARIO_FRAME = 100000


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run_hidden(command: list[str], cwd: Path, timeout: int,
               environment: dict[str, str]) -> subprocess.CompletedProcess:
    startupinfo = None
    if os.name == "nt":
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = 0
    process = subprocess.Popen(command, cwd=cwd, env=environment, startupinfo=startupinfo)
    try:
        return subprocess.CompletedProcess(command, process.wait(timeout=timeout))
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)


def safe_output(root: Path, path: Path, inputs: set[Path]) -> Path:
    root = root.resolve()
    if not path.is_absolute():
        path = root / path
    try:
        relative = path.relative_to(root)
    except ValueError as error:
        raise ValueError("capture output escapes the project") from error
    if any(part in {".", ".."} for part in relative.parts):
        raise ValueError("capture output contains traversal")
    current = root
    for part in relative.parts:
        current /= part
        if current.is_symlink() or getattr(current, "is_junction", lambda: False)():
            raise ValueError("capture output crosses a link")
    if path.resolve() in inputs:
        raise ValueError("capture output aliases a runtime input")
    return path


def atomic_bytes(path: Path, data: bytes) -> None:
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(prefix="." + path.name + ".", suffix=".tmp",
                                         dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(data)
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def receipt_write(path: Path, receipt: dict) -> None:
    atomic_bytes(path, (json.dumps(receipt, indent=2) + "\n").encode("utf-8"))


def resolve_movies(root: Path, config: dict) -> dict[str, Path] | None:
    """Check every declared movie against its pinned hash before any replay."""
    movies: dict[str, Path] = {}
    for movie_id, entry in config["movies"].items():
        if not isinstance(movie_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", movie_id):
            raise ValueError("unsafe runtime movie id: %r" % movie_id)
        path = root / entry["path"]
        if not path.is_file():
            print(f"[ERROR] missing runtime movie {movie_id}: {path}", file=sys.stderr)
            return None
        actual = sha256(path)
        if actual != entry["sha256"]:
            print(f"[ERROR] movie {movie_id} SHA-256 is {actual}", file=sys.stderr)
            return None
        movies[movie_id] = path.resolve()
    return movies


def replay(root: Path, args: argparse.Namespace) -> int:
    config_path = (root / args.scenarios).resolve()
    config_bytes = config_path.read_bytes()
    config = json.loads(config_bytes.decode("utf-8"))
    gens = (root / args.gens).resolve()
    rom = (root / args.rom).resolve()
    if not gens.is_file() or not rom.is_file() or not CAPTURE_SCRIPT.is_file():
        raise ValueError("missing runtime input, including repository-owned capture Lua")
    if args.minimum_timeout <= 0 or args.seconds_per_1000_frames <= 0:
        raise ValueError("runtime wall-clock timeout coefficients must be positive")
    movies = resolve_movies(root, config)
    if movies is None:
        return 1
    bound_inputs = {path: sha256(path) for path in (
        gens, rom, RUNNER_SCRIPT, CAPTURE_SCRIPT, Path(runtime_isolation.__file__).resolve(),
        config_path, *movies.values())}
    # Bind the bytes actually parsed/authenticated, not a second disk read which
    # could silently adopt an edit between authentication and receipt creation.
    bound_inputs[config_path] = hashlib.sha256(config_bytes).hexdigest()
    for key, path in movies.items():
        bound_inputs[path] = config["movies"][key]["sha256"]
    native_contract = runtime_isolation.native_config_contract(gens.parent.parent)
    protected = set(bound_inputs)
    output_root = safe_output(root, root / args.output_dir, protected)
    receipt_path = safe_output(root, output_root / "capture_receipt.json", protected)
    destinations = []
    identifiers = set()
    for scenario in config["scenarios"]:
        identifier = scenario["id"]
        if (not isinstance(identifier, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", identifier)
                or identifier in identifiers):
            raise ValueError("unsafe runtime scenario id: %r" % identifier)
        identifiers.add(identifier)
        frame = scenario["frame"]
        if type(frame) is not int or not 1 <= frame <= MAX_SCENARIO_FRAME:
            raise ValueError("runtime scenario frame must be an integer in 1..100000")
        if scenario["movie"] not in movies:
            raise ValueError("%s: undeclared movie %s" % (identifier, scenario["movie"]))
        try:
            directory = safe_output(root, output_root / identifier, protected)
        except ValueError as error:
            raise ValueError("unsafe runtime capture directory: %s" % error) from error
        state, screenshot = directory / ("%06d.genstate" % frame), directory / ("%06d.png" % frame)
        for target in (state, screenshot):
            try:
                safe_output(root, target, protected)
            except ValueError as error:
                raise ValueError("unsafe capture output path: %s" % target) from error
            if target.exists() and not target.is_file():
                raise ValueError("unsafe capture output path: %s" % target)
        destinations.append((scenario, directory, state, screenshot))
    if not destinations:
        raise ValueError("runtime scenario inventory is empty")
    output_root.mkdir(parents=True, exist_ok=True)
    if receipt_path.exists() and not receipt_path.is_file():
        raise ValueError("unsafe runtime receipt path")
    receipt = {"schema_version": 1, "status": "running", "scenarios": [],
               "rom_sha256": bound_inputs[rom], "gens_sha256": bound_inputs[gens],
               "capture_lua_sha256": bound_inputs[CAPTURE_SCRIPT],
               "capture_runner_sha256": bound_inputs[RUNNER_SCRIPT],
               "runtime_isolation_sha256": bound_inputs[Path(runtime_isolation.__file__).resolve()],
               "native_config_contract": native_contract,
               "scenario_config_sha256": bound_inputs[config_path],
               "movies": {key: bound_inputs[path] for key, path in movies.items()},
               "expected_scenarios": [{"id": item[0]["id"], "movie": item[0]["movie"],
                                       "frame": item[0]["frame"]} for item in destinations],
               "scope": "named_ram_scenario_replay_not_renderer_or_audio_fidelity"}
    receipt_write(receipt_path, receipt)
    try:
        with tempfile.TemporaryDirectory(prefix=".runtime-inputs-", dir=output_root) as directory:
            private = Path(directory)
            rom_snapshot = private / "preservation.bin"
            atomic_bytes(rom_snapshot, rom.read_bytes())
            movie_snapshots = {}
            for key, movie in movies.items():
                destination = private / (key + ".gmv")
                atomic_bytes(destination, movie.read_bytes())
                if sha256(destination) != bound_inputs[movie]:
                    raise ValueError("runtime movie changed before its private snapshot: %s" % key)
                movie_snapshots[key] = destination
            if sha256(rom_snapshot) != bound_inputs[rom]:
                raise ValueError("runtime ROM changed before its private snapshot")
            total_frames = 0
            for scenario, scenario_dir, state, screenshot in destinations:
                for path, value in bound_inputs.items():
                    if sha256(path) != value:
                        raise ValueError("runtime input changed after authentication: %s" % path)
                scenario_dir.mkdir(parents=True, exist_ok=True)
                # Requested frame outputs alone are owned by this run. Native
                # unpadded dumps are staged privately to preserve manual files.
                for previous in (state, screenshot):
                    if previous.is_file():
                        previous.unlink()
                case = private / scenario["id"]
                shots, states = case / "shots", case / "states"
                shots.mkdir(parents=True)
                states.mkdir()
                config_bytes, isolation = runtime_isolation.isolated_config(case, sound=False)
                config_snapshot = case / "gens.cfg"
                atomic_bytes(config_snapshot, config_bytes)
                runtime_isolation.validate_isolation(isolation, startup="runtime")
                runtime_isolation.validate_private_config(isolation, config_snapshot)
                frame = scenario["frame"]
                timeout = max(args.minimum_timeout, frame * args.seconds_per_1000_frames // 1000)
                command = [str(gens), "-cfg", str(config_snapshot), "-rom", str(rom_snapshot),
                           "-play", str(movie_snapshots[scenario["movie"]]),
                           "-lua", str(CAPTURE_SCRIPT), "-screenshot-interval", str(frame),
                           "-screenshot-dir", str(shots), "-dump-state-dir", str(states),
                           "-dump-state-interval", "1", "-dump-state-start", str(frame),
                           "-dump-state-end", str(frame), "-max-frames", str(frame + 1),
                           "-frameskip", "0", "-nosound"]
                environment = os.environ.copy()
                environment["ALIEN_RUNTIME_CAPTURE_STOP_FRAME"] = str(frame + 1)
                print("[RUN] %s: %s frame %d" % (scenario["id"], scenario["movie"], frame), flush=True)
                result = run_hidden(command, Path(isolation["startup_directories"]["runtime"]),
                                    timeout, environment)
                runtime_isolation.validate_isolation(isolation, startup="runtime", finished=True)
                runtime_isolation.validate_private_config(isolation, config_snapshot)
                native_state, native_png = states / ("%d.genstate" % frame), shots / screenshot.name
                if result.returncode != 0 or not native_state.is_file() or not native_png.is_file():
                    raise RuntimeError("%s: capture failed (exit %d)" % (scenario["id"], result.returncode))
                captured = Genstate.read(native_state)
                if (struct.unpack_from("<I", native_state.read_bytes(), 8)[0] != 1
                        or captured.frame != frame or len(captured.sections.get(1, b"")) != 65536):
                    raise RuntimeError("%s: native capture frame/RAM dimensions differ" % scenario["id"])
                if "rom_checksum" in config and captured.rom_checksum != int(config["rom_checksum"], 0):
                    raise RuntimeError("%s: native capture ROM checksum differs" % scenario["id"])
                for path, value in bound_inputs.items():
                    if sha256(path) != value:
                        raise ValueError("runtime input changed during replay: %s" % path)
                if runtime_isolation.native_config_contract(gens.parent.parent) != native_contract:
                    raise ValueError("native runtime config contract changed during replay")
                if sha256(rom_snapshot) != bound_inputs[rom] or any(
                        sha256(path) != receipt["movies"][key] for key, path in movie_snapshots.items()):
                    raise ValueError("private runtime snapshot changed during replay")
                atomic_bytes(state, native_state.read_bytes())
                atomic_bytes(screenshot, native_png.read_bytes())
                receipt["scenarios"].append({"id": scenario["id"], "movie": scenario["movie"],
                    "frame": frame, "native_header_frame": captured.frame,
                    "isolated_config_sha256": hashlib.sha256(config_bytes).hexdigest(),
                    "isolation": isolation,
                    "state_sha256": sha256(state), "screenshot_sha256": sha256(screenshot)})
                total_frames += frame
                receipt["requested_frames"] = total_frames
                receipt_write(receipt_path, receipt)
        for path, value in bound_inputs.items():
            if sha256(path) != value:
                raise ValueError("runtime input changed before completion: %s" % path)
        if runtime_isolation.native_config_contract(gens.parent.parent) != native_contract:
            raise ValueError("native runtime config contract changed before completion")
        receipt["status"] = "captured"
        receipt_write(receipt_path, receipt)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError, KeyboardInterrupt) as error:
        receipt.update({"status": "failed", "error": str(error)})
        receipt_write(receipt_path, receipt)
        raise
    print("[OK] captured %d runtime scenarios from %d movies, %d requested checkpoint frames" % (
        len(destinations), len(movies), total_frames))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenarios", default="config/runtime_scenarios.json")
    parser.add_argument("--gens", default="../gens_automation/Output/Gens.exe")
    parser.add_argument("--rom", default="asbuilt.bin")
    parser.add_argument("--output-dir", default="runtime/captures")
    parser.add_argument("--minimum-timeout", type=int, default=60)
    parser.add_argument("--seconds-per-1000-frames", type=int, default=20)
    args = parser.parse_args()

    try:
        return replay(Path.cwd(), args)
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
