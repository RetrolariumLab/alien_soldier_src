#!/usr/bin/env python3
"""Launch an editable Alien Soldier ROM through its real password path."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.build_content import (  # noqa: E402
    CHECKSUM_HEADER,
    update_boot_checksum,
    validate_reference,
)
from authoring.content_workspace import checked_path  # noqa: E402
from authoring.atomic_output import atomic_write_bytes, atomic_write_json  # noqa: E402
from rom_profiles import select_profile  # noqa: E402
from runtime_environment import digest as file_sha256, environment_identity  # noqa: E402
from runtime_isolation import isolated_config, validate_isolation, validate_private_config  # noqa: E402


SCRIPT = Path(__file__).with_suffix(".lua")
PASSWORD_SOURCE = Path("src/ui/password_screen.s")
PASSWORD_TABLE = "Password_StageCodeTable"
PASSWORD_END = "PasswordText_InputPrompt"
STAGE_COUNT = 25
MAX_PLAYTEST_FRAMES = 4200
MAX_CHECK_SECONDS = 90
PASSWORD_RECORDS_PER_STAGE = 2
DIFFICULTIES = {"easy": 0}
DIRECTIVE = re.compile(r"\bdc\.w\s+([^;\r\n]+)")


def validate_playtest_rom(root: Path, rom: Path, profile: str) -> str:
    """Bind the selected header and boot checksum to a known regional dump."""
    record = select_profile(root / "config/rom_profiles.json", profile,
                            require_supported=True)
    reference = record["reference_rom"]
    if rom.stat().st_size != reference["size"]:
        raise ValueError("content ROM length differs from the %s profile" % profile)
    original = validate_reference(checked_path(root, reference["filename"]), reference)
    image = bytearray(rom.read_bytes())
    if len(image) != len(original):
        raise ValueError("content ROM length changed while reading")
    # Studios edit content, not the cartridge header. Its checksum alone changes.
    if (image[0x100:CHECKSUM_HEADER] != original[0x100:CHECKSUM_HEADER]
            or image[CHECKSUM_HEADER + 2:0x200] != original[CHECKSUM_HEADER + 2:0x200]):
        raise ValueError("content ROM header does not match the %s profile" % profile)
    digest = hashlib.sha256(image).hexdigest()
    stored = int.from_bytes(image[CHECKSUM_HEADER:CHECKSUM_HEADER + 2], "big")
    if stored != update_boot_checksum(image, profile):
        raise ValueError("content ROM boot checksum is invalid for %s; rebuild content" % profile)
    return digest


def source_range(text: str, start: str, end: str) -> str:
    begin = text.find(start + ":")
    finish = text.find(end + ":", begin + len(start) + 1)
    if begin < 0 or finish < 0:
        raise ValueError("cannot find %s..%s" % (start, end))
    return text[begin:finish]


def parse_word(token: str) -> int:
    token = token.strip()
    value = int(token[1:], 16) if token.startswith("$") else int(token)
    if not 0 <= value <= 0xFFFF:
        raise ValueError("password word is outside 0..$FFFF: %s" % token)
    return value


def password_codes(root: Path) -> list[dict[str, int]]:
    """Decode the two four-byte password records for every selectable stage."""
    text = (root / PASSWORD_SOURCE).read_text(encoding="utf-8")
    block = source_range(text, PASSWORD_TABLE, PASSWORD_END)
    words = [
        parse_word(token)
        for match in DIRECTIVE.finditer(block)
        for token in match.group(1).split(",")
    ]
    if words[-2:] != [0xFFFF, 0xFFFF]:
        raise ValueError("password table does not end in its two-word sentinel")
    words = words[:-2]
    expected = STAGE_COUNT * PASSWORD_RECORDS_PER_STAGE * 2
    if len(words) != expected:
        raise ValueError("password table has %d words, expected %d" % (len(words), expected))
    codes = []
    cursor = 0
    for stage in range(1, STAGE_COUNT + 1):
        record = {"stage": stage}
        for field in ("easy", "shadowed_secondary"):
            record[field] = words[cursor] << 16 | words[cursor + 1]
            cursor += 2
        codes.append(record)
    return codes


def password_code(root: Path, stage: int, difficulty: str) -> int:
    if not 1 <= stage <= STAGE_COUNT:
        raise ValueError("stage must be from 1 through %d" % STAGE_COUNT)
    if difficulty not in DIFFICULTIES:
        raise ValueError("only the reachable easy password path is supported")
    return password_codes(root)[stage - 1][difficulty]


def playtest_environment(
    root: Path,
    profile: str,
    stage: int,
    difficulty: str,
    result: Path | None = None,
    *,
    exit_when_ready: bool = False,
) -> dict[str, str]:
    code = password_code(root, stage, difficulty)
    environment = os.environ.copy()
    environment.update({
        "ALIEN_PLAYTEST_PROFILE": profile,
        "ALIEN_PLAYTEST_STAGE": str(stage),
        "ALIEN_PLAYTEST_DIFFICULTY": str(DIFFICULTIES[difficulty]),
        "ALIEN_PLAYTEST_PASSWORD": "%08X" % code,
    })
    if result is None:
        environment.pop("ALIEN_PLAYTEST_RESULT", None)
    else:
        environment["ALIEN_PLAYTEST_RESULT"] = str(result.resolve())
    if exit_when_ready:
        environment["ALIEN_PLAYTEST_EXIT"] = "1"
    else:
        environment.pop("ALIEN_PLAYTEST_EXIT", None)
    return environment


def playtest_command(gens: Path, rom: Path, *, automated: bool = False,
                     config: Path | None = None) -> list[str]:
    command = [
        str(gens.resolve()),
        "-rom", str(rom.resolve()),
        "-lua", str(SCRIPT.resolve()),
    ]
    if config is not None:
        command.extend(["-cfg", str(config.resolve())])
    if automated:
        command.extend([
            "-max-frames", str(MAX_PLAYTEST_FRAMES),
            "-turbo", "-frameskip", "8", "-nosound",
        ])
    return command


def parse_result(
    path: Path, profile: str, stage: int, difficulty: str
) -> dict[str, str]:
    try:
        lines = path.read_text(encoding="utf-8").strip().splitlines()
        if len(lines) != 1:
            raise ValueError("expected one result line")
        line = lines[0]
        pairs = [item.split("=", 1) for item in line.split()]
        fields = dict(pairs)
        if len(fields) != len(pairs):
            raise ValueError("duplicate result field")
    except (OSError, ValueError) as error:
        raise RuntimeError("cannot read playtest result %s: %s" % (path, error)) from error
    expected = {
        "status": "ready",
        "profile": profile,
        "stage": str(stage),
        "stage_index": "%04X" % ((stage - 1) * 2),
        "difficulty": str(DIFFICULTIES[difficulty]),
        "mode": "0010",
        "player_type": "0008",
    }
    if (set(fields) != set(expected) | {"route", "frame"}
            or any(fields.get(key) != value for key, value in expected.items())
            or not re.fullmatch(r"[0-9A-F]{2}", fields["route"])
            or not fields["frame"].isdecimal()
            or not 1 <= int(fields["frame"]) <= MAX_PLAYTEST_FRAMES):
        raise RuntimeError("selected-stage playtest failed: %s" % line)
    return fields


def stop(process: subprocess.Popen) -> None:
    if process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)


def check_startup_info(automated: bool):
    """Hide only automated Windows runs; interactive playtests remain visible."""
    if automated and os.name == "nt":
        information = subprocess.STARTUPINFO()
        information.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        information.wShowWindow = 0
        return information
    return None


def checked_result_path(root: Path, result: Path, rom: Path, gens: Path) -> Path:
    """Reports may replace prior outputs, never source or launcher inputs."""
    path = result if result.is_absolute() else root / result
    try:
        relative = path.relative_to(root)
    except ValueError as error:
        raise ValueError("playtest report must be a .txt inside build/") from error
    path = checked_path(root, relative, Path("build"))
    if path.suffix != ".txt":
        raise ValueError("playtest report must be a .txt output, not an input file")
    inputs = {rom.resolve(), gens.resolve(), SCRIPT.resolve()}
    for suffix in ("", ".diagnostic.json", ".tmp", ".diagnostic.json.tmp", ".runtime.json"):
        output = checked_path(root, Path(str(relative) + suffix), Path("build"))
        if output.resolve() in inputs:
            raise ValueError("playtest report or diagnostic cannot replace an input file")
    return path


def diagnostic_summary(result: Path) -> str:
    """Return bounded failure context, never silently substitute new evidence."""
    path = Path(str(result) + ".diagnostic.json")
    if not path.is_file():
        return "no runtime diagnostic was written"
    try:
        if path.stat().st_size > 16384:
            raise ValueError("diagnostic exceeds its size bound")
        record = json.loads(path.read_text(encoding="utf-8"))
        if (not isinstance(record, dict)
                or record.get("phase") not in {"title", "password", "release", "gameplay"}
                or any(type(record.get(key)) is not int or record[key] < 0
                       for key in ("frame", "mode", "substate"))):
            raise ValueError("malformed diagnostic")
        return "phase=%s frame=%d mode=$%04X substate=$%04X; diagnostic %s" % (
            record["phase"], record["frame"], record["mode"], record["substate"], path)
    except (OSError, ValueError, OverflowError):
        return "unreadable runtime diagnostic %s" % path


def run_stage(
    root: Path, gens: Path, rom: Path, profile: str, stage: int, difficulty: str,
    result: Path, *, automated: bool,
) -> dict[str, str] | None:
    """Own one emulator and reap it on every automated terminal path."""
    if automated:
        result = checked_result_path(root, result, rom, gens)
    native = environment_identity(root, gens)
    validated = validate_playtest_rom(root, rom, profile)
    image = rom.read_bytes()
    if hashlib.sha256(image).hexdigest() != validated:
        raise ValueError("content ROM changed before private playtest snapshot")
    parent = checked_path(root, "build/content/%s/level-runtime" % profile)
    parent.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix="stage-%02d-" % stage, dir=parent))
    snapshot, config = directory / "playtest.bin", directory / "gens.cfg"
    config_bytes, isolation = isolated_config(directory, sound=not automated)
    atomic_write_bytes(snapshot, image)
    atomic_write_bytes(config, config_bytes)
    contract = {"schema_version": 1, "profile": profile, "stage": stage,
                "difficulty": difficulty, "rom_sha256": validated,
                "runtime_environment": native, "native_isolation": isolation,
                "runner_sha256": file_sha256(Path(__file__)), "lua_sha256": file_sha256(SCRIPT),
                "scope": "private_launch_not_renderer_or_audio_fidelity"}
    atomic_write_json(directory / "launch_contract.json", contract)
    validate_isolation(isolation, startup="runtime")
    validate_private_config(isolation, config)
    if automated:
        result.parent.mkdir(parents=True, exist_ok=True)
        for previous in (result, Path(str(result) + ".diagnostic.json")):
            if previous.exists():
                previous.unlink()
        atomic_write_json(Path(str(result) + ".runtime.json"), {
            "schema_version": 1, "status": "running", "contract": contract,
        })
    def failed_receipt(error):
        if automated:
            atomic_write_json(Path(str(result) + ".runtime.json"), {
                "schema_version": 1, "status": "failed", "contract": contract, "error": str(error),
            })

    try:
        process = subprocess.Popen(
            playtest_command(gens, snapshot, automated=automated, config=config),
            cwd=Path(isolation["startup_directories"]["runtime"]),
            env=playtest_environment(root, profile, stage, difficulty,
                                     result if automated else None, exit_when_ready=automated),
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            startupinfo=check_startup_info(automated),
        )
    except (OSError, ValueError, KeyboardInterrupt) as error:
        failed_receipt(error)
        raise
    if not automated:
        return None
    fields = None
    try:
        deadline = time.monotonic() + MAX_CHECK_SECONDS
        while time.monotonic() < deadline:
            if result.is_file() and result.stat().st_size:
                # Lua publishes a complete report by rename. A rejected
                # report is a failure, not a partially written success.
                fields = parse_result(result, profile, stage, difficulty)
                break
            return_code = process.poll()
            if return_code is not None:
                raise RuntimeError(
                    "Gens playtest exited with code %d before reporting" % return_code)
            time.sleep(0.05)
        if fields is None:
            raise RuntimeError("playtest did not report readiness within %d seconds" %
                               MAX_CHECK_SECONDS)
    except (OSError, RuntimeError, ValueError, KeyboardInterrupt) as error:
        failed_receipt(error)
        if isinstance(error, KeyboardInterrupt):
            raise
        raise RuntimeError("%s; %s" % (error, diagnostic_summary(result))) from error
    finally:
        stop(process)
    try:
        if (environment_identity(root, gens) != native or file_sha256(snapshot) != validated
                or file_sha256(Path(__file__)) != contract["runner_sha256"]
                or file_sha256(SCRIPT) != contract["lua_sha256"]):
            raise RuntimeError("playtest native environment, private ROM, or harness changed")
        validate_isolation(isolation, startup="runtime", finished=True)
        validate_private_config(isolation, config)
    except (OSError, ValueError, RuntimeError, KeyboardInterrupt) as error:
        failed_receipt(error)
        raise
    atomic_write_json(Path(str(result) + ".runtime.json"), {
        "schema_version": 1, "status": "stage_ram_ready", "contract": contract,
        "launch_contract": (directory / "launch_contract.json").relative_to(root).as_posix(),
        "launch_contract_sha256": file_sha256(directory / "launch_contract.json"),
        "fields": fields, "report_sha256": file_sha256(result),
    })
    return fields


def reachable_stages(root: Path) -> list[int]:
    records = password_codes(root)
    stages = [record.get("stage") for record in records]
    if (any(type(stage) is not int for stage in stages)
            or stages != list(range(1, STAGE_COUNT + 1))):
        raise ValueError("password inventory must identify all 25 stages exactly once in ROM order")
    return stages


def batch_runtime_identity(root: Path, gens: Path) -> dict:
    """Bind every stage in one batch to the same native and harness inputs."""
    return {
        "runtime_environment": environment_identity(root, gens),
        "toolchain_manifest_sha256": file_sha256(root / "config/toolchain.json"),
        "runner_sha256": file_sha256(Path(__file__)),
        "lua_sha256": file_sha256(SCRIPT),
    }


def run_all_stages(
    root: Path, gens: Path, rom: Path, profile: str, difficulty: str,
    result: Path, digest: str,
) -> Path:
    """Cold boot every password entry sequentially; publish no partial pass."""
    stages = reachable_stages(root)
    result = checked_result_path(root, result, rom, gens)
    outputs = [checked_result_path(
        root, result.with_name("%s_stage_%02d.txt" % (result.stem, stage)), rom, gens)
        for stage in stages]
    receipt_path = result.with_name(result.stem + "_all.json")
    receipt_path = checked_path(root, receipt_path.relative_to(root), Path("build"))
    if receipt_path.resolve() in {rom.resolve(), gens.resolve()}:
        raise ValueError("batch receipt cannot replace an input")
    payload = rom.read_bytes()
    if hashlib.sha256(payload).hexdigest() != digest:
        raise ValueError("content ROM changed before the batch snapshot")
    identity = batch_runtime_identity(root, gens)
    result.parent.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []
    receipt = {
        "schema_version": 1, "status": "running", "profile": profile,
        "difficulty": difficulty, "rom_sha256": digest,
        "gens_sha256": hashlib.sha256(gens.read_bytes()).hexdigest(),
        "lua_sha256": hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),
        "runner_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "batch_runtime_identity": identity,
        "expected_stages": stages, "completed_count": 0, "stages": records,
        "scope": "cold_boot_selected_stage_ram_readiness_not_renderer_or_audio_fidelity",
    }
    # Invalidate previous pass evidence before a new run can fail halfway.
    atomic_write_json(receipt_path, receipt)
    try:
        with tempfile.TemporaryDirectory(prefix="level-rom-", dir=result.parent) as directory:
            snapshot = Path(directory) / "content.bin"
            atomic_write_bytes(snapshot, payload)
            for stage, destination in zip(stages, outputs, strict=True):
                if batch_runtime_identity(root, gens) != identity:
                    raise RuntimeError("native or harness inputs changed during the stage batch")
                run_stage(root, gens, snapshot, profile, stage, difficulty,
                          destination, automated=True)
                fields = parse_result(destination, profile, stage, difficulty)
                diagnostic = Path(str(destination) + ".diagnostic.json")
                if diagnostic.stat().st_size > 16384:
                    raise RuntimeError("stage diagnostic exceeds its size bound")
                observed = json.loads(diagnostic.read_text(encoding="utf-8"))
                expected = {"status": "ready", "profile": profile, "stage": stage,
                            "frame": int(fields["frame"]), "difficulty": DIFFICULTIES[difficulty],
                            "mode": 0x10, "stage_index": (stage - 1) * 2, "player_type": 8,
                            "route": int(fields["route"], 16)}
                if (not isinstance(observed, dict)
                        or any(type(observed.get(key)) is not type(value)
                               or observed[key] != value for key, value in expected.items())):
                    raise RuntimeError("stage diagnostic disagrees with its readiness report")
                native_report = Path(str(destination) + ".runtime.json")
                proof = json.loads(native_report.read_text(encoding="utf-8"))
                if proof.get("status") != "stage_ram_ready" or proof.get("fields") != fields:
                    raise RuntimeError("stage native isolation receipt disagrees with readiness")
                contract = proof.get("contract", {})
                if any(contract.get(key) != identity[key] for key in (
                        "runtime_environment", "runner_sha256", "lua_sha256")):
                    raise RuntimeError("stage native isolation receipt disagrees with batch inputs")
                records.append({
                    "stage": stage, "fields": fields,
                    "result": destination.relative_to(root).as_posix(),
                    "result_sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                    "diagnostic": diagnostic.relative_to(root).as_posix(),
                    "diagnostic_sha256": hashlib.sha256(diagnostic.read_bytes()).hexdigest(),
                    "native_receipt": native_report.relative_to(root).as_posix(),
                    "native_receipt_sha256": file_sha256(native_report),
                })
                receipt["completed_count"] = len(records)
                if batch_runtime_identity(root, gens) != identity:
                    raise RuntimeError("native or harness inputs changed during the stage batch")
                atomic_write_json(receipt_path, receipt)
                print("[OK] %s stage %d reached gameplay at frame %s" % (
                    profile, stage, fields["frame"]), flush=True)
        if [record["stage"] for record in records] != stages:
            raise RuntimeError("batch did not cover the complete password inventory")
        if batch_runtime_identity(root, gens) != identity:
            raise RuntimeError("native or harness inputs changed during the stage batch")
        for name, key, source in (("Gens executable", "gens_sha256", gens),
                                  ("Lua script", "lua_sha256", SCRIPT),
                                  ("Python runner", "runner_sha256", Path(__file__))):
            if hashlib.sha256(source.read_bytes()).hexdigest() != receipt[key]:
                raise RuntimeError("%s changed during the stage batch" % name)
        receipt["status"] = "passed"
        atomic_write_json(receipt_path, receipt)
        return receipt_path
    except (OSError, RuntimeError, ValueError, KeyboardInterrupt) as error:
        receipt["status"] = "failed"
        receipt["error"] = str(error)
        atomic_write_json(receipt_path, receipt)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--gens", default="../gens_automation/Output/Gens.exe")
    parser.add_argument("--rom", required=True)
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument("--stage", type=int, default=1)
    selection.add_argument("--check-all", action="store_true")
    parser.add_argument("--difficulty", choices=tuple(DIFFICULTIES), default="easy")
    parser.add_argument("--result", default="build/level_playtest.txt")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    gens = Path(args.gens)
    rom = Path(args.rom)
    result = Path(args.result)
    try:
        password_code(root, args.stage, args.difficulty)
        if not gens.is_file():
            raise ValueError("Gens not found: %s" % gens)
        if not rom.is_file():
            raise ValueError("content ROM not found: %s" % rom)
        digest = validate_playtest_rom(root, rom, args.profile)
        if args.check_all:
            receipt = run_all_stages(root, gens, rom, args.profile,
                                     args.difficulty, result, digest)
            print("[OK] %s all 25 password stages passed; ROM SHA256 %s; receipt %s" % (
                args.profile, digest, receipt))
            return 0
        fields = run_stage(root, gens, rom, args.profile, args.stage, args.difficulty,
                           result, automated=args.check)
        if not args.check:
            print("[OK] launched %s stage %d (%s) playtest in Gens; ROM SHA256 %s" % (
                args.profile, args.stage, args.difficulty, digest))
            return 0
        print("[OK] %s stage %d reached gameplay at frame %s; ROM SHA256 %s" % (
            args.profile, args.stage, fields["frame"], digest))
        return 0
    except (OSError, RuntimeError, ValueError) as error:
        print("[ERROR] %s" % error)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
