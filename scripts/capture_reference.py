#!/usr/bin/env python3
"""Capture authenticated JP movie frames into a fresh, non-overwriting archive."""

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
import zlib
from pathlib import Path

from PIL import Image, ImageFile

import runtime_environment
import runtime_isolation
from run_runtime_scenarios import CAPTURE_SCRIPT, atomic_bytes, receipt_write, run_hidden, safe_output, sha256


SCRIPT = Path(__file__).resolve()
MOVIES = {"tas", "longplay", "menus"}
FRAME_LIMIT = 100000  # Immutable neutral Lua permits stop_frame up to 100001.
DEFAULT_BOUNDS = {"tas": 90000, "menus": 90860}
NATIVE_FILES = (
    "src/movie.cpp",
    "src/state_dump.cpp",
    "src/state_dump.h",
    "src/automation.cpp",
    "src/luascript.cpp",
    "src/G_ddraw.cpp",
    "src/scrshot.cpp",
    "src/psg.h",
)
STATE_LAYOUT = (
    (0x01, 65536),
    (0x02, 72),
    (0x10, 65536),
    (0x11, 128),
    (0x12, 80),
    (0x13, 24),
    (0x20, 8192),
    (0x30, 5328),
    (0x31, 96),
    (0x40, 65536),
)
STATE_TABLE_END = 64 + 16 * (len(STATE_LAYOUT) + 1)
STATE_LENGTH = STATE_TABLE_END + sum(size for _kind, size in STATE_LAYOUT)
MAX_PNG_BYTES = 4 * 1024 * 1024
PNG_SIZES = {(width, height) for width in (256, 320) for height in (224, 240)}


def native_capture_contract(checkout: Path) -> dict:
    """Pin source evidence for known regular GMV streams and every-frame hooks."""
    sources = {name: (checkout / name).read_text(encoding="utf-8", errors="replace") for name in NATIVE_FILES}
    requirements = {
        "src/movie.cpp": (
            "aMovie->LastFrame=(ftell(test)-64)/3;",
            "fseek(MainMovie.File,64+FrameCount*3,SEEK_SET);",
            "aMovie->StateRequired=((t&64)>>6);",
            "aMovie->TriplePlayerHack=((t&32)>>5);",
        ),
        "src/luascript.cpp": ("case SPEEDMODE_NOTHROTTLE:", "if(!TurboMode)gens_emulateframefastnoskipping(L);"),
        "src/G_ddraw.cpp": ("if(TurboMode)Temp_Frame_Skip=8;", "Automation_OnFrame(FrameCount,"),
        "src/automation.cpp": (
            "StateDump_OnFrame(frameCount);",
            "if(frameCount%ScreenshotInterval!=0)return;",
            "%06d.png",
        ),
        "src/state_dump.cpp": (
            "const int NUM_SECTIONS = 10;",
            "Write_LE_U32(f, frameNumber);",
            "StateDump_DumpState(frameCount);",
        ),
    }
    for name, fragments in requirements.items():
        compact = re.sub(r"\s+", "", sources[name])
        if any(re.sub(r"\s+", "", fragment) not in compact for fragment in fragments):
            raise ValueError("native exact-frame capture proof changed: %s" % name)
    block = sources["src/state_dump.cpp"].split("int StateDump_DumpState(int frameNumber)", 1)[1]
    block = block.split("int StateDump_DumpStateToFile", 1)[0]
    sections = re.findall(
        r"sections\[(\d+)\]\.section_id\s*=\s*(\w+);.*?"
        r"sections\[\1\]\.size\s*=\s*([^;]+);",
        block,
        re.DOTALL,
    )
    constants = dict(
        (name, int(value, 16))
        for name, value in re.findall(r"#define\s+(SECTION_\w+)\s+0x([0-9A-Fa-f]+)", sources["src/state_dump.h"])
    )
    psg = sources["src/psg.h"].split("struct _psg", 1)[1].split("{", 1)[1].split("}", 1)[0]
    fields = [line.strip() for line in psg.splitlines() if line.strip()]
    psg_words = 0
    for field in fields:
        declaration = re.fullmatch(r"(?:unsigned\s+)?int\s+\w+(?:\[(\d+)\])?;", field)
        if declaration is None:
            raise ValueError("native PSG ABI has an unsupported field")
        psg_words += int(declaration[1] or 1)
    if psg_words != 24:
        raise ValueError("native PSG Win32 integer-word inventory changed")
    actual = []
    for index, name, expression in sections:
        if re.sub(r"\s+", "", expression) == "sizeof(struct_psg)":
            # The pinned Win32 build uses four-byte int/unsigned int; the actual
            # native section table must independently confirm these 96 bytes.
            expression = str(psg_words * 4)
        factors = expression.strip().split("*")
        if any(not re.fullmatch(r"\s*(?:\d+|0[xX][0-9a-fA-F]+)\s*", factor) for factor in factors):
            raise ValueError("native GENSTATE section size is not a literal product")
        size = 1
        for factor in factors:
            size *= int(factor, 0)
        if int(index) != len(actual):
            raise ValueError("native GENSTATE section order changed")
        actual.append((constants[name], size))
    if tuple(actual) != STATE_LAYOUT:
        raise ValueError("native complete GENSTATE layout changed")
    return {
        "regular_gmv_header_bytes": 64,
        "regular_gmv_bytes_per_frame": 3,
        "genstate_version": 1,
        "genstate_bytes": STATE_LENGTH,
        "section_layout": [list(item) for item in STATE_LAYOUT],
        "source_sha256": {name: sha256(checkout / name) for name in NATIVE_FILES},
    }


def authenticate_rom(payload: bytes, profiles: dict) -> dict:
    jp = [item for item in profiles["profiles"] if item["id"] == "jp"]
    digest = hashlib.sha256(payload).hexdigest()
    if len(jp) != 1 or len(payload) != jp[0]["reference_rom"]["size"] or digest != jp[0]["reference_rom"]["sha256"]:
        raise ValueError("reference capture requires the exact canonical Japanese ROM")
    if (
        len(payload) < 0x200
        or payload[0x100:0x110] != b"SEGA MEGA DRIVE "
        or struct.unpack_from(">II", payload, 0x1A0) != (0, len(payload) - 1)
    ):
        raise ValueError("canonical Japanese cartridge header has an unsupported layout")
    return {
        "profile": "jp",
        "sha256": digest,
        "size": len(payload),
        "cartridge_header_sha256": hashlib.sha256(payload[0x100:0x200]).hexdigest(),
        "region_header_hex": payload[0x1F0:0x200].hex(),
        "stored_checksum": struct.unpack_from(">H", payload, 0x18E)[0],
    }


def known_movie_info(payload: bytes, expected: str) -> dict:
    """Not a generic GMV parser: only the three hash-pinned Source 1 JP movies."""
    if hashlib.sha256(payload).hexdigest() != expected:
        raise ValueError("selected Japanese movie SHA-256 differs from its contract")
    if (
        len(payload) < 64
        or (len(payload) - 64) % 3
        or payload[:16] != b"Gens Movie TESTA"
        or payload[22] & 0xE0
        or any(value not in b"36" for value in payload[20:22])
    ):
        raise ValueError("known JP movie is not a regular NTSC cold-boot GMV stream")
    return {
        "sha256": expected,
        "frames": (len(payload) - 64) // 3,
        "header_hex": payload[:64].hex(),
        "state_required": False,
        "triple_player_hack": False,
        "pal": False,
    }


def archive_parent(root: Path, requested: Path, protected: set[Path]) -> Path:
    path = safe_output(root, requested, protected)
    relative = path.relative_to(root.resolve())
    if not relative.parts or relative.parts[0] not in {"reference", "build"}:
        raise ValueError("reference archives must be under reference/ or build/ inside this project")
    if path.exists() and not path.is_dir():
        raise ValueError("reference output parent is not a directory")
    return path


def full_state_header(path: Path, frame: int, checksum: int) -> None:
    with path.open("rb") as stream:
        table = stream.read(STATE_TABLE_END)
    if (
        len(table) != STATE_TABLE_END
        or table[:8] != b"GENSTATE"
        or path.stat().st_size != STATE_LENGTH
        or struct.unpack_from("<II", table, 8) != (1, frame)
        or struct.unpack_from("<I", table, 24)[0] != checksum
    ):
        raise ValueError("frame %d: native GENSTATE header/length differs" % frame)
    offset = STATE_TABLE_END
    for index, (kind, size) in enumerate(STATE_LAYOUT):
        if struct.unpack_from("<IIII", table, 64 + 16 * index) != (kind, offset, size, 0):
            raise ValueError("frame %d: native GENSTATE section inventory differs" % frame)
        offset += size
    if table[-16:] != bytes(16):
        raise ValueError("frame %d: native GENSTATE table sentinel differs" % frame)


def png_header(path: Path, frame: int) -> None:
    """Validate complete chunks and decode one bounded native image at a time."""
    try:
        if not 45 <= path.stat().st_size <= MAX_PNG_BYTES:
            raise ValueError("native PNG size exceeds its fixed bound")
        with path.open("rb") as stream:
            if stream.read(8) != b"\x89PNG\r\n\x1a\n":
                raise ValueError("native PNG signature differs")
            idat_bytes, seen_idat, ended_idat, complete = 0, False, False, False
            for index in range(4096):
                prefix = stream.read(8)
                if len(prefix) != 8:
                    raise ValueError("native PNG chunk header is truncated")
                length, kind = struct.unpack(">I4s", prefix)
                if length > MAX_PNG_BYTES or not re.fullmatch(rb"[A-Za-z]{4}", kind):
                    raise ValueError("native PNG chunk type/size is invalid")
                data, crc = stream.read(length), stream.read(4)
                if len(data) != length or len(crc) != 4:
                    raise ValueError("native PNG chunk is truncated")
                if struct.unpack(">I", crc)[0] != zlib.crc32(kind + data) & 0xFFFFFFFF:
                    raise ValueError("native PNG chunk CRC differs")
                if index == 0:
                    if kind != b"IHDR" or length != 13 or struct.unpack_from(">II", data) not in PNG_SIZES:
                        raise ValueError("native PNG IHDR/dimensions differ")
                elif kind == b"IHDR":
                    raise ValueError("native PNG has a duplicate IHDR")
                if kind[0] & 0x20 == 0 and kind not in {b"IHDR", b"PLTE", b"IDAT", b"IEND"}:
                    raise ValueError("native PNG has an unknown critical chunk")
                if kind == b"IDAT":
                    if ended_idat:
                        raise ValueError("native PNG IDAT chunks are not consecutive")
                    seen_idat = True
                    idat_bytes += length
                elif seen_idat:
                    ended_idat = True
                if kind == b"IEND":
                    if length != 0 or idat_bytes == 0 or stream.read(1):
                        raise ValueError("native PNG has no complete IDAT/IEND sequence or trailing bytes")
                    complete = True
                    break
            if not complete:
                raise ValueError("native PNG chunk inventory is incomplete or exceeds its bound")
        allow_truncated = ImageFile.LOAD_TRUNCATED_IMAGES
        try:
            ImageFile.LOAD_TRUNCATED_IMAGES = False
            with Image.open(path) as image:
                if image.format != "PNG" or image.size not in PNG_SIZES:
                    raise ValueError("decoded native PNG dimensions/format differ")
                image.verify()
            with Image.open(path) as image:
                image.load()
        finally:
            ImageFile.LOAD_TRUNCATED_IMAGES = allow_truncated
    except (OSError, ValueError, SyntaxError, Image.DecompressionBombError) as error:
        raise ValueError("frame %d: native PNG integrity/decode failed: %s" % (frame, error)) from error


def verify_inventory(
    root: Path, session: Path, maximum: int, interval: int, checksum: int, protected: set[Path], receipt: dict
) -> Path:
    frames = session / "frames"
    temporary = session / ".frame_inventory.tmp"
    inventory = session / "frame_inventory.jsonl"
    with temporary.open("x", encoding="utf-8", newline="\n") as manifest:
        for frame in range(interval, maximum + 1, interval):
            native = safe_output(root, frames / ("%d.genstate" % frame), protected)
            state = safe_output(root, frames / ("%06d.genstate" % frame), protected)
            png = safe_output(root, frames / ("%06d.png" % frame), protected)
            if not native.is_file() or not png.is_file():
                raise ValueError("frame %d: requested native PNG/state capture is missing" % frame)
            if state != native and state.exists():
                raise ValueError("frame %d: padded state path already exists in new archive" % frame)
            full_state_header(native, frame, checksum)
            png_header(png, frame)
            if state != native:
                # Rename only the just-produced native file inside this fresh
                # session. No prior archive or manual file is a target.
                native.rename(state)
            manifest.write(
                json.dumps(
                    {
                        "frame": frame,
                        "native_header_frame": frame,
                        "state": "frames/" + state.name,
                        "png": "frames/" + png.name,
                        "state_sha256": sha256(state),
                        "png_sha256": sha256(png),
                        "state_bytes": state.stat().st_size,
                        "png_bytes": png.stat().st_size,
                    },
                    separators=(",", ":"),
                )
                + "\n"
            )
            receipt["verified_frames"] += 1
    count = 0
    for entry in frames.iterdir():
        safe_output(root, entry, protected)
        match = re.fullmatch(r"(\d{6})\.(png|genstate)", entry.name)
        if not entry.is_file() or not match or not interval <= int(match[1]) <= maximum or int(match[1]) % interval:
            raise ValueError("new archive contains an unexpected frame artifact: %s" % entry.name)
        count += 1
    if count != 2 * (maximum // interval) or receipt["verified_frames"] != maximum // interval:
        raise ValueError("new archive's exact frame inventory is incomplete")
    temporary.rename(inventory)
    return inventory


def capture(root: Path, args: argparse.Namespace) -> Path:
    root = root.resolve()
    maximum = args.max_frames if args.max_frames is not None else DEFAULT_BOUNDS.get(args.movie)
    if maximum is None:
        raise ValueError("longplay contains 206611 frames; request an explicit --max-frames<=100000 prefix/clip")
    if (
        args.movie not in MOVIES
        or type(maximum) is not int
        or not 1 <= maximum <= FRAME_LIMIT
        or type(args.interval) is not int
        or not 1 <= args.interval <= maximum
    ):
        raise ValueError("reference maximum must be in 1..100000 and interval in 1..maximum")
    timeout = args.timeout if args.timeout is not None else max(60, maximum * 20 // 1000)
    if type(timeout) is not int or timeout < 1:
        raise ValueError("reference wall-clock timeout must be a positive integer")
    config_path, profiles_path = root / "config/runtime_scenarios.json", root / "config/rom_profiles.json"
    config_bytes, profiles_bytes = config_path.read_bytes(), profiles_path.read_bytes()
    config, profiles = json.loads(config_bytes.decode("utf-8")), json.loads(profiles_bytes.decode("utf-8"))
    if set(config["movies"]) != MOVIES:
        raise ValueError("reference capture's supported Japanese movie inventory changed")
    movie = (root / config["movies"][args.movie]["path"]).resolve()
    rom, gens = (root / args.rom).resolve(), (root / args.gens).resolve()
    payload, movie_payload = rom.read_bytes(), movie.read_bytes()
    rom_auth = authenticate_rom(payload, profiles)
    movie_auth = known_movie_info(movie_payload, config["movies"][args.movie]["sha256"])
    if args.movie == "menus" and args.max_frames is None and movie_auth["frames"] != DEFAULT_BOUNDS["menus"]:
        raise ValueError("the pinned menus movie duration changed; choose an explicit frame bound")
    native = runtime_environment.environment_identity(root, gens)
    proof = native_capture_contract(gens.parent.parent)
    paths = (
        rom,
        movie,
        gens,
        SCRIPT,
        CAPTURE_SCRIPT,
        root / "scripts/run_runtime_scenarios.py",
        Path(runtime_environment.__file__).resolve(),
        Path(runtime_isolation.__file__).resolve(),
        config_path,
        profiles_path,
        root / "config/toolchain.json",
    )
    pins = {path: sha256(path) for path in paths}
    pins[rom], pins[movie] = rom_auth["sha256"], movie_auth["sha256"]
    pins[config_path] = hashlib.sha256(config_bytes).hexdigest()
    pins[profiles_path] = hashlib.sha256(profiles_bytes).hexdigest()
    parent = archive_parent(root, args.output_dir or Path("reference") / args.movie, set(pins))
    parent.mkdir(parents=True, exist_ok=True)
    session = Path(tempfile.mkdtemp(prefix="capture-", dir=parent))
    frames = session / "frames"
    frames.mkdir()
    receipt_path = session / "receipt.json"
    receipt = {
        "schema_version": 1,
        "status": "running",
        "profile": "jp",
        "movie_id": args.movie,
        "movie": movie_auth,
        "rom": rom_auth,
        "native_runtime": native,
        "native_capture_proof": proof,
        "input_sha256": {str(path): value for path, value in pins.items()},
        "max_frame_inclusive": maximum,
        "interval": args.interval,
        "expected_frames": maximum // args.interval,
        "verified_frames": 0,
        "first_frame": args.interval,
        "last_frame": maximum // args.interval * args.interval,
        "png_integrity": "complete_chunk_crc_structure_and_pillow_verify_load",
        "png_max_bytes": MAX_PNG_BYTES,
        "scope": "exact_frame_native_capture_not_renderer_or_game_semantic_fidelity",
    }
    receipt_write(receipt_path, receipt)

    def recheck() -> None:
        if any(sha256(path) != value for path, value in pins.items()):
            raise ValueError("reference input/harness changed after authentication")
        if (
            runtime_environment.environment_identity(root, gens) != native
            or native_capture_contract(gens.parent.parent) != proof
        ):
            raise ValueError("reference native runtime/proof changed after authentication")

    try:
        recheck()
        with tempfile.TemporaryDirectory(prefix=".inputs-", dir=session) as private_directory:
            private = Path(private_directory)
            rom_snapshot, movie_snapshot = private / "reference.bin", private / "movie.gmv"
            atomic_bytes(rom_snapshot, payload)
            atomic_bytes(movie_snapshot, movie_payload)
            config_seed, isolation = runtime_isolation.isolated_config(private, sound=False)
            private_config = private / "gens.cfg"
            atomic_bytes(private_config, config_seed)
            runtime_isolation.validate_isolation(isolation, startup="runtime")
            runtime_isolation.validate_private_config(isolation, private_config)
            if sha256(rom_snapshot) != pins[rom] or sha256(movie_snapshot) != pins[movie]:
                raise ValueError("reference snapshot differs from authenticated input")
            command = [
                str(gens),
                "-cfg",
                str(private_config),
                "-rom",
                str(rom_snapshot),
                "-play",
                str(movie_snapshot),
                "-lua",
                str(CAPTURE_SCRIPT),
                "-screenshot-interval",
                str(args.interval),
                "-screenshot-dir",
                str(frames),
                "-dump-state-dir",
                str(frames),
                "-dump-state-interval",
                str(args.interval),
                "-dump-state-start",
                "1",
                "-dump-state-end",
                str(maximum),
                "-max-frames",
                str(maximum + 1),
                "-frameskip",
                "0",
                "-nosound",
            ]
            receipt.update(
                {
                    "isolation": isolation,
                    "private_config_sha256": hashlib.sha256(config_seed).hexdigest(),
                    "command": command,
                    "native_stop_frame": maximum + 1,
                }
            )
            receipt_write(receipt_path, receipt)
            environment = os.environ.copy()
            environment["ALIEN_RUNTIME_CAPTURE_STOP_FRAME"] = str(maximum + 1)
            print(
                "[RUN] %s: interval %d, inclusive frame %d, expected %d frame pairs"
                % (args.movie, args.interval, maximum, receipt["expected_frames"]),
                flush=True,
            )
            result = run_hidden(command, Path(isolation["startup_directories"]["runtime"]), timeout, environment)
            runtime_isolation.validate_isolation(isolation, startup="runtime", finished=True)
            runtime_isolation.validate_private_config(isolation, private_config)
            if result.returncode != 0:
                raise RuntimeError("reference emulator exited with code %d" % result.returncode)
            if sha256(rom_snapshot) != pins[rom] or sha256(movie_snapshot) != pins[movie]:
                raise ValueError("reference private ROM/movie snapshot changed during replay")
            recheck()
            inventory = verify_inventory(
                root, session, maximum, args.interval, int(config["rom_checksum"], 0), set(pins), receipt
            )
        recheck()
        receipt.update({"status": "captured", "inventory": inventory.name, "inventory_sha256": sha256(inventory)})
        receipt_write(receipt_path, receipt)
    except (
        OSError,
        ValueError,
        RuntimeError,
        KeyError,
        TypeError,
        subprocess.SubprocessError,
        KeyboardInterrupt,
    ) as error:
        receipt.update({"status": "failed", "error": str(error)})
        receipt_write(receipt_path, receipt)
        raise
    print("[OK] authenticated %d exact native frame pairs: %s" % (receipt["verified_frames"], receipt_path))
    return session


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--movie", required=True, choices=sorted(MOVIES))
    parser.add_argument("--rom", type=Path, default=Path("asbuilt.bin"))
    parser.add_argument("--gens", type=Path, required=True)
    parser.add_argument("--interval", type=int, default=1)
    parser.add_argument(
        "--max-frames", type=int, help="inclusive last replay frame (<=100000); required for longplay prefixes"
    )
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--timeout", type=int)
    args = parser.parse_args()
    try:
        capture(Path(__file__).resolve().parents[1], args)
    except (OSError, ValueError, RuntimeError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
