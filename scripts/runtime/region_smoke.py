"""Boot the European cartridge in Gens and watch it reach the attract demo.

    python -B -m scripts.runtime.region_smoke --gens <Gens.exe>

A cold boot with both controllers released, one Start press at the story
skip, then the cartridge's own demo. A Lua script records named RAM every
frame; the run passes when the console flags say Europe, the title screen
idles, and the demo then runs for config["demo_stable_frames"] frames with its
countdown going down. It is a smoke test of the European build, not a
playthrough.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from scripts import runtime_isolation
from scripts.extract_symbols import load_resolved_symbols
from scripts.rom_profiles import select_profile

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = "config/runtime_region_smoke.json"
OBSERVATIONS = (
    ("GameModeIndex", 2),
    ("GameSubstateIndex", 2),
    ("DifficultyMode", 2),
    ("ConsoleVersionFlags", 1),
    ("PaletteFadeMode", 2),
    ("PaletteFadeColorOffset", 2),
    ("TitleMenuSelection", 2),
    ("DemoPlaybackActive", 2),
    ("DemoPlaybackState", 2),
    ("DemoRecordingMode", 2),
    ("DemoFramesRemaining", 2),
    ("StageTableIndex", 2),
    ("DemoStageTableIndex", 2),
    ("PlayerObjectType", 2),
    ("VBlankFrameCounter", 2),
    ("PaletteFadeMaskStatus", 1),
    ("ScenePaletteFadeOffset", 2),
    ("DataLoaderControl", 2),
)


def read_config(root: Path) -> dict:
    return json.loads((root / MANIFEST).read_text(encoding="utf-8"))


def ram_addresses(listing: Path) -> dict[str, int]:
    """The RAM cells the Lua script reads, from the EU build's own listing."""
    symbols = load_resolved_symbols(listing)
    if (symbols.get("BUILDPROFILEJP"), symbols.get("BUILDPROFILEEU")) != (0, 1):
        raise ValueError("the listing is not an EU build")
    try:
        return {name: symbols[name.upper()] & 0xFFFFFF for name, _width in OBSERVATIONS}
    except KeyError as error:
        raise ValueError("RAM symbol is missing from the listing: %s" % error.args[0]) from None


def lua_contract(ram: dict[str, int], config: dict) -> str:
    cells = ",".join("%s=%d" % item for item in ram.items())
    observations = ",".join("{%d,%d}" % (ram[name], width) for name, width in OBSERVATIONS)
    return "return {ram={%s},observations={%s},max_frames=%d,demo_stable_frames=%d}\n" % (
        cells,
        observations,
        config["max_frames"],
        config["demo_stable_frames"],
    )


def read_trace(path: Path) -> list[dict]:
    rows = []
    with path.open(encoding="ascii", newline="") as stream:
        for line in csv.reader(stream):
            if len(line) != len(OBSERVATIONS) + 1 or any(not re.fullmatch(r"[0-9]+", item) for item in line):
                raise ValueError("trace row %d is malformed" % (len(rows) + 1))
            numbers = list(map(int, line))
            if numbers[0] != len(rows) + 1:
                raise ValueError("trace frames are not contiguous from the cold boot")
            row = {"frame": numbers[0]}
            row.update(zip((name for name, _width in OBSERVATIONS), numbers[1:]))
            rows.append(row)
    if not rows:
        raise ValueError("the trace is empty")
    return rows


def matches(row: dict, expected: dict) -> bool:
    return all(row.get(name) == value for name, value in expected.items())


def check_trace(config: dict, rows: list[dict], result: dict) -> dict:
    """Boot in European mode, then the idle title, then the running demo."""
    if result.get("status") != "complete" or result.get("frame") != rows[-1]["frame"]:
        raise ValueError("the run did not reach the attract demo within %d frames" % config["max_frames"])
    expected = config["expectations"]
    flags = expected["console_flags"]
    booted = [
        row
        for row in rows
        if matches(row, expected["boot"])
        and row["GameModeIndex"] > 0
        and row["ConsoleVersionFlags"] & flags["mask"] == flags["equals"]
    ]
    if not booted:
        raise ValueError("the console flags never said Europe")
    title = [row for row in booted if matches(row, expected["title"])]
    demo = [
        row
        for row in booted
        if matches(row, expected["attract_demo"])
        and row["StageTableIndex"] == row["DemoStageTableIndex"]
        and 0 < row["DemoFramesRemaining"] <= 4096
    ]
    if not title or not demo:
        raise ValueError("the title screen or the attract demo never appeared")
    if not title[-1]["frame"] < demo[0]["frame"]:
        raise ValueError("the title screen came back after the demo started")
    window = demo[-config["demo_stable_frames"] :]
    if (
        len(window) < config["demo_stable_frames"]
        or window[-1]["frame"] != rows[-1]["frame"]
        or any(b["frame"] != a["frame"] + 1 for a, b in zip(window, window[1:]))
    ):
        raise ValueError("the demo did not run for %d frames in a row" % config["demo_stable_frames"])
    if not window[-1]["DemoFramesRemaining"] < window[0]["DemoFramesRemaining"]:
        raise ValueError("the demo countdown did not go down")
    skip = result.get("story_start_frame", 0)
    if skip:
        row = rows[skip - 1]
        if (
            row["GameModeIndex"] != 40
            or not row["PaletteFadeMaskStatus"] & 1
            or row["ScenePaletteFadeOffset"]
            or row["DataLoaderControl"] >= 0x8000
        ):
            raise ValueError("Start was pressed outside the story skip")
    return {
        "booted": booted[0]["frame"],
        "title": title[0]["frame"],
        "demo": demo[0]["frame"],
        "final": rows[-1]["frame"],
        "story_start": skip,
    }


def run(root: Path, gens: Path) -> dict:
    root, gens = root.resolve(), gens.resolve()
    config = read_config(root)
    profile = select_profile(root / "config/rom_profiles.json", "eu", require_supported=True)
    image = (root / profile["output"]).read_bytes()
    if image != (root / profile["reference_rom"]["filename"]).read_bytes():
        raise ValueError("build the EU cartridge first (make verify PROFILE=eu)")
    ram = ram_addresses(root / profile["listing"])
    parent = root / "build/runtime"
    parent.mkdir(parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix="eu-region-smoke-", dir=parent))
    (directory / "contract.lua").write_text(lua_contract(ram, config), encoding="ascii")
    (directory / "cartridge.bin").write_bytes(image)
    config_bytes, isolation = runtime_isolation.isolated_config(directory, sound=False)
    (directory / "gens.cfg").write_bytes(config_bytes)
    environment = os.environ.copy()
    environment["ALIEN_REGION_SMOKE_CONTRACT"] = str(directory / "contract.lua")
    environment["ALIEN_REGION_SMOKE_TRACE"] = str(directory / "trace.csv")
    command = [
        str(gens),
        "-cfg",
        str(directory / "gens.cfg"),
        "-rom",
        str(directory / "cartridge.bin"),
        "-lua",
        str(root / config["capture_script"]),
        "-frameskip",
        "0",
        "-nosound",
    ]
    startup = None
    if os.name == "nt":
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    with (directory / "gens.log").open("wb") as output:
        process = subprocess.Popen(
            command,
            cwd=isolation["startup_directories"]["runtime"],
            env=environment,
            stdout=output,
            stderr=output,
            startupinfo=startup,
        )
        try:
            process.wait(timeout=config["timeout_seconds"])
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=10)
    result = json.loads((directory / "trace.csv.result.json").read_text(encoding="utf-8"))
    return check_trace(config, read_trace(directory / "trace.csv"), result)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--gens", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        summary = run(args.root, args.gens)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print("[ERROR] EU boot: %s" % error, file=sys.stderr)
        return 1
    print("[OK] EU boot: Europe at frame %(booted)d, title at %(title)d, demo at %(demo)d to %(final)d" % summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
