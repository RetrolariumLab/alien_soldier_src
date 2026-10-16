#!/usr/bin/env python3
"""Audition a supported BGM/SFX request through the original cartridge driver."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.atomic_output import atomic_write_bytes, atomic_write_json  # noqa: E402
from authoring.build_content import validate_reference  # noqa: E402
from authoring.content_workspace import checked_path  # noqa: E402
from authoring.level_playtest import stop as stop_process, validate_playtest_rom  # noqa: E402
from authoring.sound_audition_model import (  # noqa: E402
    build_contract, digest_file, payload_for_request,
)
from authoring import sound_startup  # noqa: E402
from rom_profiles import select_profile  # noqa: E402
from runtime_environment import environment_identity  # noqa: E402
from runtime_isolation import isolated_config, validate_isolation, validate_private_config  # noqa: E402


SCRIPT = Path(__file__).with_suffix(".lua")
MAX_BOOT_FRAMES = 1800
DEFAULT_AUDITION_FRAMES = 1800
MAX_AUDITION_FRAMES = 3600


def lua_contract(contract: dict) -> bytes:
    """Generate only numeric reader fields; paths and strings stay in environment."""
    lines = ["return {", "  hook = %d," % contract["hook_address"],
             "  dispatch_hook = %d," % contract["dispatch_hook_address"], "  ram = {"]
    lines.extend("    %s = %d," % (name, value) for name, value in contract["ram"].items())
    lines.extend(["  },", "  checks = {"])
    lines.extend("    {%d, %d, %d}," % (item["address"], item["size"], item["value"])
                 for item in contract["checks"])
    lines.extend(["  },", "}", ""])
    return "\n".join(lines).encode("ascii")


def audition_command(gens: Path, rom: Path, config: Path, frames: int,
                     *, check: bool = False) -> list[str]:
    command = [str(gens.resolve()), "-cfg", str(config.resolve()),
               "-rom", str(rom.resolve()), "-lua", str(SCRIPT.resolve()),
               "-max-frames", str(MAX_BOOT_FRAMES + frames + 4)]
    if check:
        command.extend(["-turbo", "-frameskip", "8"])
    return command


def parse_result(path: Path, contract: dict) -> dict:
    try:
        result = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise RuntimeError("cannot read sound audition report: %s" % error) from error
    keys = {"status", "profile", "request_id", "rom_sha256", "frame", "observations"}
    if not isinstance(result, dict) or set(result) != keys:
        raise RuntimeError("sound audition report has an invalid field inventory")
    observations = result["observations"]
    if (result["status"] != "loaded" or result["profile"] != contract["profile"]
            or type(result["request_id"]) is not int
            or result["request_id"] != contract["request_id"]
            or result["rom_sha256"] != contract["rom_sha256"]
            or type(result["frame"]) is not int
            or not 1 <= result["frame"] <= MAX_BOOT_FRAMES
            or not isinstance(observations, list)
            or any(type(value) is not int for value in observations)
            or observations != [item["value"] for item in contract["checks"]]):
        raise RuntimeError("selected sound request did not match its loader-state expectations")
    return result


@dataclass
class Session:
    process: subprocess.Popen
    contract: dict
    result: Path
    stop_file: Path
    directory: Path
    ready: dict | None = None
    deadline: float = field(default_factory=lambda: time.monotonic() + 180)
    root: Path | None = None

    def validate_environment(self) -> None:
        if self.root is None:
            return  # Lightweight synthetic sessions do not claim native evidence.
        identity = self.contract["runtime_environment"]
        if environment_identity(self.root, Path(identity["executable_path"])) != identity:
            raise RuntimeError("sound native runtime environment changed during audition")
        validate_isolation(self.contract["native_isolation"], startup="runtime", finished=True)
        validate_private_config(self.contract["native_isolation"], self.directory / "gens.cfg")
        if "sound_startup" in self.contract:
            sound_startup.validate(self.contract["sound_startup"], self.contract["native_isolation"],
                                   self.directory / "gens.cfg", launched=True)
            if (sound_startup.native_contract(Path(identity["executable_path"]).resolve().parent.parent)
                    != self.contract["sound_startup_source"]
                    or digest_file(Path(sound_startup.__file__)) != self.contract["sound_startup_module_sha256"]):
                raise RuntimeError("sound startup native source or helper changed")
        if digest_file(self.directory / "audition.bin") != self.contract["rom_sha256"]:
            raise RuntimeError("sound private ROM changed during audition")
        if (digest_file(Path(__file__)) != self.contract["runner_sha256"]
                or digest_file(SCRIPT) != self.contract["lua_sha256"]
                or digest_file(self.directory / "contract.lua") != self.contract["generated_contract_sha256"]):
            raise RuntimeError("sound audition harness or generated contract changed")

    def poll(self) -> bool:
        """Return whether the process is live, checking its exact named report."""
        if self.ready is None and self.result.is_file():
            try:
                self.ready = parse_result(self.result, self.contract)
            except RuntimeError as error:
                diagnostic = self.result.with_name(self.result.name + ".diagnostic.json")
                if diagnostic.is_file():
                    raise RuntimeError("%s; diagnostic: %s" % (error, diagnostic)) from error
                raise
        code = self.process.poll()
        if code is not None and self.ready is None:
            raise RuntimeError("sound audition exited with code %d before confirming the request" % code)
        if code not in (None, 0):
            raise RuntimeError("sound audition exited with code %d" % code)
        if code is None and time.monotonic() >= self.deadline:
            raise RuntimeError("sound audition exceeded its bounded wall-clock deadline")
        if code is not None:
            self.validate_environment()
        return code is None

    def stop(self) -> None:
        """Ask Lua to queue stop-all, then reap only the owned emulator process."""
        if self.process.poll() is None:
            try:
                atomic_write_bytes(self.stop_file, b"stop\n")
                self.process.wait(timeout=1)
            except (OSError, subprocess.TimeoutExpired):
                stop_process(self.process)
        self.validate_environment()


def launch(root: Path, profile: str, request: int, rom: Path, listing: Path,
           gens: Path, *, frames: int = DEFAULT_AUDITION_FRAMES,
           check: bool = False) -> Session:
    if type(frames) is not int or not 1 <= frames <= MAX_AUDITION_FRAMES:
        raise ValueError("audition frames must be 1..%d" % MAX_AUDITION_FRAMES)
    payload_for_request(request)
    root = root.resolve()
    if not gens.is_file():
        raise ValueError("Gens not found: %s" % gens)
    validated_digest = validate_playtest_rom(root, rom, profile)
    reference = select_profile(root / "config/rom_profiles.json", profile,
                               require_supported=True)["reference_rom"]
    original = validate_reference(checked_path(root, reference["filename"]), reference)
    # A listing alone is insufficient: bind its pointer tables and selected bytes
    # to the exact staged source tree and to the actual checksum-validated image.
    tree = checked_path(root, "build/content/%s/tree" % profile)
    image = rom.read_bytes()
    if hashlib.sha256(image).hexdigest() != validated_digest:
        raise ValueError("content ROM changed after its regional validation")
    contract = build_contract(root, tree, profile, request, image, original, listing)
    native = environment_identity(root, gens)
    startup_source = sound_startup.native_contract(gens.resolve().parent.parent)
    contract["gens_sha256"] = digest_file(gens)
    parent = checked_path(root, "build/content/%s/audition" % profile)
    parent.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix="session-", dir=parent))
    config, source = directory / "gens.cfg", directory / "contract.lua"
    result, stop_file = directory / "result.json", directory / "stop.txt"
    audition_rom = directory / "audition.bin"
    # Run the validated image, even if another studio replaces CONTENT_ROM.
    atomic_write_bytes(audition_rom, image)
    # The pin initializes a default sound device before parsing CLI options.
    # Seed State0 in its owned startup cwd, then enable through the explicit
    # config. No native sound toggle or user's configuration is modified.
    config_bytes, isolation = isolated_config(directory, sound=True, extra_sections={
        "Sound": {"Rate": "44100", "Stereo": "1", "Z80 State": "1",
                  "YM2612 State": "1", "PSG State": "1", "DAC State": "1",
                  "YM2612 Improvement": "0", "DAC Improvement": "0"},
    })
    if check:
        # Loader checks remain silent while keeping native generation enabled.
        config_bytes = config_bytes.replace(b"[Sound]\nState=1\n",
            b"[Sound]\nState=1\nMaster Volume=0\n", 1)
        isolation["config_sha256"] = hashlib.sha256(config_bytes).hexdigest()
    atomic_write_bytes(config, config_bytes)
    contract["sound_startup"] = sound_startup.prepare(isolation, config)
    contract["sound_startup_source"] = startup_source
    contract["sound_startup_module_sha256"] = digest_file(Path(sound_startup.__file__))
    contract["runtime_environment"] = native
    contract["native_isolation"] = isolation
    atomic_write_bytes(source, lua_contract(contract))
    contract["runner_sha256"] = digest_file(Path(__file__))
    contract["lua_sha256"] = digest_file(SCRIPT)
    contract["generated_contract_sha256"] = digest_file(source)
    atomic_write_json(directory / "contract.json", contract)
    sound_startup.validate(contract["sound_startup"], isolation, config, launched=False)
    environment = os.environ.copy()
    environment.update({
        "ALIEN_SOUND_PROFILE": profile, "ALIEN_SOUND_REQUEST": str(request),
        "ALIEN_SOUND_ROM_SHA256": contract["rom_sha256"],
        "ALIEN_SOUND_CONTRACT": str(source), "ALIEN_SOUND_RESULT": str(result),
        "ALIEN_SOUND_STOP": str(stop_file), "ALIEN_SOUND_FRAMES": str(frames),
        "ALIEN_SOUND_CHECK": "1" if check else "0",
    })
    startupinfo = None
    if check and os.name == "nt":
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = 0
    process = subprocess.Popen(
        audition_command(gens, audition_rom, config, frames, check=check),
        cwd=Path(isolation["startup_directories"]["runtime"]), env=environment,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        startupinfo=startupinfo,
    )
    return Session(process, contract, result, stop_file, directory, root=root)


def parse_request(value: str) -> int:
    return int(value[1:], 16) if value.startswith("$") else int(value, 0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    parser.add_argument("--request", required=True, type=parse_request)
    parser.add_argument("--rom", required=True)
    parser.add_argument("--listing", required=True)
    parser.add_argument("--gens", default="../gens_automation/Output/Gens.exe")
    parser.add_argument("--frames", type=int, default=DEFAULT_AUDITION_FRAMES)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    session = None
    try:
        session = launch(Path(args.root), args.profile, args.request, Path(args.rom),
                         Path(args.listing), Path(args.gens), frames=args.frames, check=args.check)
        reported = False
        deadline = time.monotonic() + (90 if args.check else 180)
        while session.poll():
            if session.ready is not None and not reported:
                print("[OK] %s request $%02X loaded with %d named RAM expectations; ROM SHA256 %s" % (
                    args.profile, args.request, len(session.contract["checks"]),
                    session.contract["rom_sha256"]))
                reported = True
            if time.monotonic() >= deadline:
                raise RuntimeError("sound audition exceeded its bounded wall-clock deadline")
            time.sleep(0.1)
        print("[OK] audition report: %s; audible fidelity is not established" % session.result)
        return 0
    except (OSError, ValueError, RuntimeError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130
    finally:
        if session is not None:
            session.stop()


if __name__ == "__main__":
    raise SystemExit(main())
