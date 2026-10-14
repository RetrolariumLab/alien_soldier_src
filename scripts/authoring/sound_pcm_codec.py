#!/usr/bin/env python3
"""Decode and exactly re-encode the Z80 driver's two-nibble DPCM stream."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))


DRIVER_PATH = "data/sound/z80_data.bin"
LOW_NIBBLE_TABLE_OFFSET = 0xA00
HIGH_NIBBLE_TABLE_OFFSET = 0xB00
INITIAL_LEVEL = 0x80
DELTA_BYTES = (0, 1, 2, 4, 8, 16, 32, 64, 128, 255, 254, 252, 248, 240, 224, 192)
CODE_SIGNATURES = {
    0x110: bytes.fromhex("21 00 0C 22 E2 1F 3E 80 08"),
    0x12A: bytes.fromhex("6E 25 D9 72 D9 86"),
    0x13C: bytes.fromhex("D9 25 86"),
}
TIMING_SIGNATURES = {
    0x107: bytes.fromhex("3A E0 1F 4F"),  # LD A,($1FE0); LD C,A
    0x139: bytes.fromhex("41 10 FE"),     # LD B,C; DJNZ -2
    0x177: bytes.fromhex("41 10 FE"),     # second nibble's delay
}
# Complete byte spans from the first YM2612 DAC write through the second and
# back to the first on an uninterrupted ordinary PCM request. The branch
# targets are checked as bytes, not inferred from nearby data.
DAC_TIMING_SIGNATURES = {
    0x120: bytes.fromhex(
        "2A E2 1F 54 7D 3C 32 E2 1F 08 6E 25 D9 72 D9 86 D9 EB 73 EB"),
    0x134: bytes.fromhex("32 01 40 73 00 41 10 FE D9 25 86 08 BB"),
    0x141: bytes.fromhex("28 13 FA 5F 01"),
    0x146: bytes.fromhex("FD 7E 00 FD 23 00 00 FD 23 FD 23 FD 23 C3 6B 01"),
    0x156: bytes.fromhex("3A FF 1F B7 28 09 C3 56 01"),
    0x15F: bytes.fromhex("3A FF 1F B7 20 E6"),
    0x165: bytes.fromhex("E1 ED A0 ED A0 E5"),
    0x16B: bytes.fromhex("D9 72 D9 08 D9 EB 73 EB"),
    0x173: bytes.fromhex(
        "32 01 40 73 41 10 FE D9 08 78 B7 FA 8F 01 "
        "B1 CA 92 01 3A FE 1F B7 CA 20 01"),
}
MUSIC_REQUEST_SOURCE = "move.b  #1,(Z80DACRequestState).l"


def expected_low_table() -> bytes:
    return bytes(DELTA_BYTES[index & 0x0F] for index in range(0x100))


def expected_high_table() -> bytes:
    return bytes(DELTA_BYTES[index >> 4] for index in range(0x100))


def load_tables(root: Path) -> tuple[bytes, bytes]:
    path = root / DRIVER_PATH
    driver = path.read_bytes()
    if len(driver) != 0xC00:
        raise ValueError("Z80 sound driver is not $C00 bytes: %s" % path)
    for offset, signature in CODE_SIGNATURES.items():
        if driver[offset:offset + len(signature)] != signature:
            raise ValueError("Z80 DPCM decoder signature differs at $%03X" % offset)
    low = driver[LOW_NIBBLE_TABLE_OFFSET:LOW_NIBBLE_TABLE_OFFSET + 0x100]
    high = driver[HIGH_NIBBLE_TABLE_OFFSET:HIGH_NIBBLE_TABLE_OFFSET + 0x100]
    if low != expected_low_table():
        raise ValueError("Z80 low-nibble DPCM table differs")
    if high != expected_high_table():
        raise ValueError("Z80 high-nibble DPCM table differs")
    return high, low


def codec_contract(root: Path) -> dict:
    load_tables(root)
    return {
        "driver_path": DRIVER_PATH,
        "high_nibble_table_offset": HIGH_NIBBLE_TABLE_OFFSET,
        "low_nibble_table_offset": LOW_NIBBLE_TABLE_OFFSET,
        "initial_level": INITIAL_LEVEL,
        "samples_per_byte": 2,
        "nibble_order": ["high", "low"],
        "delta_bytes": list(DELTA_BYTES),
        "decoder_signature_offsets": sorted(CODE_SIGNATURES),
    }


def ordinary_delay_t_states(count: int) -> int:
    """CPU-only timing of LD B,C followed by DJNZ -2, not a DAC sample rate.

    Zilog UM0080 gives 13 T-states for each taken DJNZ and 8 for its final
    fall-through. A zero byte runs 256 iterations after B wraps.
    """
    if isinstance(count, bool) or not isinstance(count, int) or not 0 <= count <= 0xFF:
        raise ValueError("Z80 delay count must be an unsigned byte")
    iterations = count or 0x100
    return 4 + 13 * (iterations - 1) + 8  # LD B,C costs four T-states.


def ordinary_delay_contract(root: Path) -> dict:
    """Pin both delay sites and the music request path without claiming rate."""
    driver = (root / DRIVER_PATH).read_bytes()
    if len(driver) != 0xC00:
        raise ValueError("Z80 sound driver is not $C00 bytes")
    for offset, signature in TIMING_SIGNATURES.items():
        if driver[offset:offset + len(signature)] != signature:
            raise ValueError("Z80 PCM delay signature differs at $%03X" % offset)
    music = (root / "src/sound/driver_core.s").read_text(encoding="utf-8")
    if not any(line.lstrip().startswith(MUSIC_REQUEST_SOURCE)
               for line in music.splitlines()):
        raise ValueError("68000 music request no longer sets the Z80 delay byte to 1")
    return {
        "request_state_load": 0x107,
        "delay_sites": [0x139, 0x177],
        "music_request_count": 1,
        "music_delay_t_states_per_site": ordinary_delay_t_states(1),
    }


def ordinary_dac_timing_contract(root: Path) -> dict:
    """CPU-only write-to-write timing for an uninterrupted ordinary request.

    The four first-to-second routes at $0141 have equal 94-T-state branch
    bodies. Only the equality route can wait at $0156: each nonzero poll of
    $1FFF adds 34 T-states. From the second write, the normal route requires
    a live BC byte count and zero new-request flag at $1FFE. This does not
    account for bus stalls or establish the actual sample playback rate.
    """
    driver = (root / DRIVER_PATH).read_bytes()
    if len(driver) != 0xC00:
        raise ValueError("Z80 sound driver is not $C00 bytes")
    for offset, signature in DAC_TIMING_SIGNATURES.items():
        if driver[offset:offset + len(signature)] != signature:
            raise ValueError("Z80 DAC timing path differs at $%03X" % offset)
    ordinary_delay_contract(root)

    # T-states per instruction from Zilog UM0080. The four branch bodies are:
    # equal/ready, negative/clear, negative/set, and positive at CP E ($0140).
    branch_cycles = {
        "equal_ready": 12 + (13 + 4 + 12) + (10 + 16 + 16 + 11),
        "negative_clear": (7 + 10) + (13 + 4 + 7) + (10 + 16 + 16 + 11),
        "negative_set": (7 + 10) + (13 + 4 + 12) + (4 + 4 + 10 + 10 + 10 + 10),
        "positive": (7 + 10) + (19 + 10 + 4 + 4 + 10 + 10 + 10 + 10),
    }
    if set(branch_cycles.values()) != {94}:
        raise ValueError("Z80 DAC branch timing is no longer balanced")
    delay = ordinary_delay_t_states(1)
    # $0134 write, $0137-$0140, branch, $016B-$0172.
    first_to_second = (
        (13 + 7 + 4) + delay + (4 + 4 + 7 + 4 + 4)
        + 94 + (4 + 7 + 4 + 4 + 4 + 4 + 7 + 4))
    # $0173 write through the live-sample / no-request route to $0120,
    # then $0120-$0133. Conditional JP instructions cost ten either way.
    second_to_first = (
        (13 + 7 + delay + 4 + 4 + 4 + 4 + 10 + 4 + 10 + 13 + 4 + 10)
        + (16 + 4 + 4 + 4 + 13 + 4 + 7 + 4 + 4 + 7 + 4 + 7 + 4 + 4 + 7 + 4))
    return {
        "first_write": 0x134,
        "second_write": 0x173,
        "branch_t_states": branch_cycles,
        "first_to_second_t_states": first_to_second,
        "second_to_next_first_t_states": second_to_first,
        "encoded_byte_t_states": first_to_second + second_to_first,
        "equal_busy_poll_extra_t_states": 13 + 4 + 7 + 10,
    }


def ordinary_dac_event_offsets(timing: dict, byte_index: int) -> tuple[int, int]:
    """CPU-only offsets of one encoded byte's two DAC writes.

    Zero is the first write of byte zero. These offsets assume the ordinary
    uninterrupted request path pinned by ``ordinary_dac_timing_contract``;
    they are not wall-clock times or a verified recording cadence.
    """
    if isinstance(byte_index, bool) or not isinstance(byte_index, int) or byte_index < 0:
        raise ValueError("DAC byte index must be a nonnegative integer")
    first = byte_index * timing["encoded_byte_t_states"]
    return first, first + timing["first_to_second_t_states"]


def decode_dpcm(encoded: bytes, high: bytes, low: bytes) -> bytes:
    if len(high) != 0x100 or len(low) != 0x100:
        raise ValueError("DPCM lookup tables must each contain 256 bytes")
    level = INITIAL_LEVEL
    decoded = bytearray()
    for value in encoded:
        level = (level + high[value]) & 0xFF
        decoded.append(level)
        level = (level + low[value]) & 0xFF
        decoded.append(level)
    return bytes(decoded)


def encode_dpcm(decoded: bytes) -> bytes:
    if len(decoded) % 2:
        raise ValueError("decoded DPCM stream must contain sample pairs")
    nibbles = {delta: index for index, delta in enumerate(DELTA_BYTES)}
    level = INITIAL_LEVEL
    encoded = bytearray()
    for offset in range(0, len(decoded), 2):
        high_delta = (decoded[offset] - level) & 0xFF
        try:
            high = nibbles[high_delta]
        except KeyError as error:
            raise ValueError("sample %d has an unrepresentable high-nibble delta" % offset) from error
        level = decoded[offset]
        low_delta = (decoded[offset + 1] - level) & 0xFF
        try:
            low = nibbles[low_delta]
        except KeyError as error:
            raise ValueError("sample %d has an unrepresentable low-nibble delta" % (offset + 1)) from error
        level = decoded[offset + 1]
        encoded.append((high << 4) | low)
    return bytes(encoded)


def check_project(root: Path, profile: str) -> tuple[int, int]:
    from authoring.sound_pcm_model import export_document

    high, low = load_tables(root)
    ordinary_dac_timing_contract(root)
    document = export_document(root, profile)
    sample_count = 0
    decoded_count = 0
    for bank in document["banks"]:
        for sample in bank["samples"]:
            encoded = bytes.fromhex(sample["data"])
            decoded = decode_dpcm(encoded, high, low)
            if encode_dpcm(decoded) != encoded:
                raise ValueError("%s sample %d fails exact DPCM round trip" % (
                    bank["name"], sample["index"]))
            sample_count += 1
            decoded_count += len(decoded)
    return sample_count, decoded_count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check",))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=("jp", "eu"), default="jp")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        sample_count, decoded_count = check_project(root, args.profile)
        print("[OK] %s DPCM codec: %d samples, %d decoded values" % (
            args.profile, sample_count, decoded_count))
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
