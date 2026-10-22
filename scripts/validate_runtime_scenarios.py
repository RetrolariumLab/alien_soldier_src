#!/usr/bin/env python3
"""Validate named RAM expectations in captured runtime scenarios."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import sys
from pathlib import Path

from runtime_state import Genstate, M68K_RAM
import runtime_isolation
from run_runtime_scenarios import safe_output
from verify_toolchain import check_emulator_commit, sha256_of


EQUATE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s+equ\s+\$([0-9A-F]+)", re.IGNORECASE)


def number(value: str | int) -> int:
    return value if isinstance(value, int) else int(value, 0)


def ram_symbols(path: Path) -> dict[str, int]:
    symbols = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = EQUATE.match(line)
        if match:
            symbols[match.group(1)] = int(match.group(2), 16) & 0xFFFFFF
    return symbols


def validate(config: dict, capture_root: Path, symbols: dict[str, int]) -> list[str]:
    errors: list[str] = []
    readers = {"u8": Genstate.m68k_u8, "u16": Genstate.m68k_u16, "u32": Genstate.m68k_u32}
    minimum = int(config.get("minimum_expectations_per_scenario", 2))
    for scenario in config["scenarios"]:
        frame = int(scenario["frame"])
        path = capture_root / scenario["id"] / f"{frame:06d}.genstate"
        try:
            state = Genstate.read(path)
        except (OSError, ValueError, KeyError) as error:
            errors.append(f"{scenario['id']}: cannot read capture: {error}")
            continue
        if state.rom_checksum != number(config["rom_checksum"]):
            errors.append(f"{scenario['id']}: ROM checksum is 0x{state.rom_checksum:08X}")
        if len(state.sections.get(M68K_RAM, b"")) != 65536:
            errors.append(f"{scenario['id']}: M68K RAM section is not 64 KiB")
            continue
        if len(scenario.get("expectations", [])) < minimum:
            errors.append(f"{scenario['id']}: fewer than {minimum} named expectations")
        for expectation in scenario.get("expectations", []):
            symbol = expectation["symbol"]
            if symbol not in symbols:
                errors.append(f"{scenario['id']}: unknown RAM symbol {symbol}")
                continue
            address = number(expectation["address"])
            offset = number(expectation.get("offset", 0))
            if (symbols[symbol] + offset) & 0xFFFFFF != address:
                errors.append(f"{scenario['id']}: {symbol}+0x{offset:X} does not equal 0x{address:06X}")
                continue
            value_type = expectation["type"]
            if value_type not in readers:
                errors.append(f"{scenario['id']}: unsupported type {value_type}")
                continue
            actual = readers[value_type](state, address)
            expected = number(expectation["equals"])
            if actual != expected:
                field = expectation.get("field", symbol)
                errors.append(f"{scenario['id']}: {field} at 0x{address:06X} is 0x{actual:X}, expected 0x{expected:X}")
    return errors


def validate_receipt(
    config_path: Path, capture_root: Path, gens: Path, rom: Path, project_root: Path | None = None
) -> list[str]:
    """Independently authenticate exact-frame JP captures, not screenshot fidelity.

    Legacy captures need not have a receipt. This opt-in gate requires the new
    neutral replay harness, canonical JP bytes, and clean pinned native source.
    Private startup/config directories are historical evidence: the runner has
    removed them after verifying that their auto-loader directories were empty.
    """
    root = (project_root or Path(__file__).resolve().parents[1]).resolve()
    config_path, gens, rom = config_path.resolve(), gens.resolve(), rom.resolve()
    errors: list[str] = []
    try:
        config_bytes = config_path.read_bytes()
        config = json.loads(config_bytes.decode("utf-8"))
        inputs = {
            "scenario_config_sha256": config_path,
            "rom_sha256": rom,
            "gens_sha256": gens,
            "capture_runner_sha256": root / "scripts/run_runtime_scenarios.py",
            "capture_lua_sha256": root / "scripts/runtime_capture_frames.lua",
            "runtime_isolation_sha256": root / "scripts/runtime_isolation.py",
        }
        movies = {key: (root / item["path"]).resolve() for key, item in config["movies"].items()}
        protected = {path.resolve() for path in (*inputs.values(), *movies.values())}
        capture_root = safe_output(root, capture_root, protected)
        receipt_path = safe_output(root, capture_root / "capture_receipt.json", protected)
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        if type(receipt.get("schema_version")) is not int or receipt["schema_version"] != 1:
            raise ValueError("runtime receipt schema version differs")
        if receipt.get("status") != "captured":
            raise ValueError("runtime receipt is not a completed capture")
        if receipt.get("scope") != "named_ram_scenario_replay_not_renderer_or_audio_fidelity":
            raise ValueError("runtime receipt scope differs")
        for key, path in inputs.items():
            expected = hashlib.sha256(config_bytes).hexdigest() if path == config_path else sha256_of(path)
            if receipt.get(key) != expected:
                raise ValueError("runtime receipt %s differs from current input" % key)
        expected_movies = {key: entry["sha256"] for key, entry in config["movies"].items()}
        if receipt.get("movies") != expected_movies or any(
            sha256_of(path) != expected_movies[key] for key, path in movies.items()
        ):
            raise ValueError("runtime receipt movie inventory/hash differs")
        profiles = json.loads((root / "config/rom_profiles.json").read_text(encoding="utf-8"))
        jp = [profile for profile in profiles["profiles"] if profile["id"] == "jp"]
        if len(jp) != 1 or (
            rom.stat().st_size != jp[0]["reference_rom"]["size"]
            or receipt["rom_sha256"] != jp[0]["reference_rom"]["sha256"]
        ):
            raise ValueError("runtime receipt is not bound to the canonical Japanese ROM")
        toolchain = json.loads((root / "config/toolchain.json").read_text(encoding="utf-8"))
        emulator = [component for component in toolchain["components"] if component["id"] == "emulator"]
        if len(emulator) != 1 or not re.fullmatch(r"[0-9a-f]{40}", emulator[0]["source_commit"]):
            raise ValueError("runtime toolchain has no unique pinned emulator source")
        checkout = gens.parent.parent
        declared = Path(emulator[0]["files"]["any"][0]["path"])
        if gens != checkout / declared.relative_to(declared.parent.parent):
            raise ValueError("selected runtime executable is not the declared checkout-relative file")
        check_emulator_commit(emulator[0], errors, [], checkout)
        if errors:
            return ["runtime receipt: " + error for error in errors]
        if receipt.get("native_config_contract") != runtime_isolation.native_config_contract(checkout):
            raise ValueError("runtime receipt native config source contract differs")
        inventory = [
            {"id": scenario["id"], "movie": scenario["movie"], "frame": scenario["frame"]}
            for scenario in config["scenarios"]
        ]
        if (
            not inventory
            or len({item["id"] for item in inventory}) != len(inventory)
            or any(
                not re.fullmatch(r"[a-z][a-z0-9_]*", item["id"])
                or type(item["frame"]) is not int
                or not 1 <= item["frame"] <= 100000
                or item["movie"] not in movies
                for item in inventory
            )
        ):
            raise ValueError("runtime receipt scenario contract has an unsafe inventory")
        if (
            receipt.get("expected_scenarios") != inventory
            or not isinstance(receipt["expected_scenarios"], list)
            or any(type(item["frame"]) is not int for item in receipt["expected_scenarios"])
        ):
            raise ValueError("runtime receipt expected scenario inventory differs")
        cases = receipt["scenarios"]
        if [{key: case[key] for key in ("id", "movie", "frame")} for case in cases] != inventory:
            raise ValueError("runtime receipt completed scenario inventory differs")
        if type(receipt.get("requested_frames")) is not int or receipt["requested_frames"] != sum(
            item["frame"] for item in inventory
        ):
            raise ValueError("runtime receipt total checkpoint frames differ")
        for case in cases:
            frame = case["frame"]
            if (
                type(frame) is not int
                or type(case["native_header_frame"]) is not int
                or case["native_header_frame"] != frame
            ):
                raise ValueError("%s: receipt native frame differs" % case["id"])
            isolation = case["isolation"]
            session = Path(isolation["session_directory"])
            sidecars = session / "native-sidecars"
            if (
                type(isolation.get("schema_version")) is not int
                or isolation["schema_version"] != runtime_isolation.SCHEMA_VERSION
                or not session.is_absolute()
                or session.parent.parent != capture_root.resolve()
                or session.name != case["id"]
                or not re.fullmatch(r"\.runtime-inputs-[a-z0-9_]+", session.parent.name)
                or isolation["sidecar_directory"] != str(sidecars)
                or isolation["general_paths"] != {key: str(sidecars) + os.sep for key in runtime_isolation.PATH_KEYS}
                or isolation["startup_directories"] != {"runtime": str(session / "native-startup-runtime")}
                or isolation["config_sha256"] != case["isolated_config_sha256"]
                or not re.fullmatch(r"[0-9a-f]{64}", case["isolated_config_sha256"])
            ):
                raise ValueError("%s: receipt private native isolation contract differs" % case["id"])
            directory = safe_output(root, capture_root / case["id"], protected)
            state_path = safe_output(root, directory / ("%06d.genstate" % frame), protected)
            png_path = safe_output(root, directory / ("%06d.png" % frame), protected)
            if sha256_of(state_path) != case["state_sha256"] or sha256_of(png_path) != case["screenshot_sha256"]:
                raise ValueError("%s: runtime receipt capture artifact hash differs" % case["id"])
            state = Genstate.read(state_path)
            if (
                struct.unpack_from("<I", state_path.read_bytes(), 8)[0] != 1
                or state.frame != frame
                or state.rom_checksum != number(config["rom_checksum"])
                or len(state.sections.get(M68K_RAM, b"")) != 65536
            ):
                raise ValueError("%s: actual native state header/RAM differs" % case["id"])
    except (OSError, ValueError, KeyError, TypeError, AttributeError, struct.error) as error:
        errors.append("runtime receipt: " + str(error))
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scenarios", default="config/runtime_scenarios.json")
    parser.add_argument("--capture-dir", default="runtime/captures")
    parser.add_argument("--ram-map", default="src/ram_addrs.inc")
    parser.add_argument(
        "--require-receipt",
        action="store_true",
        help="authenticate the exact-frame capture receipt and clean pinned native source",
    )
    parser.add_argument(
        "--gens", type=Path, help="the selected checkout's Output/Gens.exe; required with --require-receipt"
    )
    parser.add_argument("--rom", type=Path, default=Path("asbuilt.bin"))
    args = parser.parse_args()
    config = json.loads(Path(args.scenarios).read_text(encoding="utf-8"))
    errors = validate(config, Path(args.capture_dir), ram_symbols(Path(args.ram_map)))
    if args.require_receipt:
        if args.gens is None:
            errors.append("--gens is required with --require-receipt")
        else:
            errors.extend(validate_receipt(Path(args.scenarios), Path(args.capture_dir), args.gens, args.rom))
    if errors:
        for error in errors:
            print(f"[ERROR] {error}", file=sys.stderr)
        return 1
    expectations = sum(len(item["expectations"]) for item in config["scenarios"])
    movies = len({item["movie"] for item in config["scenarios"]})
    print(
        f"[OK] runtime: {len(config['scenarios'])} scenarios from {movies} movies, "
        f"{expectations} named RAM assertions"
        + (
            ", authenticated exact-frame receipt"
            if args.require_receipt
            else ", legacy receipt authentication disabled"
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
