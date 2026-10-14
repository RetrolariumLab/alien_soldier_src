#!/usr/bin/env python3
"""Inventory the sound payloads through the cartridge's proven header readers."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.stage_tilemap_model import labelled_blocks  # noqa: E402


PROFILES = ("jp", "eu")
BGM_REQUEST_IDS = tuple(range(0x81, 0xA0))
LOW_SFX_IDS = tuple(range(0x40, 0x80))
HIGH_SFX_IDS = tuple(range(0xA0, 0xF9))
SPECIAL_SFX_IDS = tuple(range(0xF9, 0xFD))
SFX_REQUEST_IDS = LOW_SFX_IDS + HIGH_SFX_IDS + SPECIAL_SFX_IDS
BGM_FM_CHANNEL_TYPES = (0x06, 0x00, 0x01, 0x02, 0x04, 0x05, 0x06)
BGM_PSG_CHANNEL_TYPES = (0x80, 0xA0, 0xC0)
PCM_BANK_LENGTHS = (0x8000,) * 8 + (0x1A5E,)
FM_INSTRUMENT_BYTES = 25


@dataclass(frozen=True)
class Command:
    name: str
    operands: int
    flow: str = "next"


COMMANDS = {
    0xE0: Command("panning", 1),
    0xE1: Command("detune", 1),
    0xE2: Command("communication", 1),
    0xE3: Command("silence_and_stop", 0, "stop"),
    0xE4: Command("pan_animation", -1),
    0xE5: Command("channel_type_volume", 2),
    0xE6: Command("fm_volume", 1),
    0xE7: Command("hold", 0),
    0xE8: Command("note_timeout", 1),
    0xE9: Command("fm_lfo_and_am", 2),
    0xEA: Command("tempo", 1),
    0xEB: Command("queue_sound", 1),
    0xEC: Command("psg_volume", 1),
    0xED: Command("fm_register", 2),
    0xEE: Command("ym2612_port_zero_register", 2),
    0xEF: Command("fm_instrument", 1),
    0xF0: Command("vibrato_parameters", 4),
    0xF1: Command("channel_type_pitch_envelope", 2),
    0xF2: Command("stop", 0, "stop"),
    0xF3: Command("psg_noise", 1),
    0xF4: Command("pitch_envelope", 1),
    0xF5: Command("psg_volume_envelope", 1),
    0xF6: Command("jump", 2, "jump"),
    0xF7: Command("repeat", 4, "branch"),
    0xF8: Command("call", 2, "call"),
    0xF9: Command("return", 0, "return"),
    0xFA: Command("tick_multiplier", 1),
    0xFB: Command("transpose", 1),
    0xFC: Command("enable_vibrato", 0),
    0xFD: Command("disable_vibrato", 0),
    0xFE: Command("fm3_special_mode", 4),
}


EXTENDED_COMMANDS = {
    0x00: Command("ssg_eg", 4),
    0x01: Command("pause", 1),
    0x02: Command("all_tick_multipliers", 1),
    0x03: Command("attenuate", 2),
    0x04: Command("restore_volume", 0),
}


def _word(data: bytes, offset: int) -> int:
    return int.from_bytes(data[offset:offset + 2], "big")


def _signed_word(data: bytes, offset: int) -> int:
    return int.from_bytes(data[offset:offset + 2], "big", signed=True)


def decode_instruction(label: str, data: bytes, offset: int) -> dict[str, Any]:
    """Decode one event or command exactly as the three channel readers do."""
    if not 0 <= offset < len(data):
        raise ValueError("%s sequence cursor $%04X is outside its payload" % (label, offset))
    opcode = data[offset]
    if opcode < 0x80:
        return {"offset": offset, "size": 1, "kind": "duration", "value": opcode}
    if opcode < 0xE0:
        size = 2 if offset + 1 < len(data) and data[offset + 1] < 0x80 else 1
        return {"offset": offset, "size": size, "kind": "note", "value": opcode}
    if opcode == 0xFF:
        if offset + 1 >= len(data):
            raise ValueError("%s has a truncated extended command at $%04X" % (label, offset))
        extension = data[offset + 1]
        command = EXTENDED_COMMANDS.get(extension)
        if command is None:
            raise ValueError(
                "%s uses unknown extended command $FF $%02X at $%04X"
                % (label, extension, offset)
            )
        size = 2 + command.operands
        if offset + size > len(data):
            raise ValueError("%s has truncated %s at $%04X" % (label, command.name, offset))
        return {
            "offset": offset,
            "size": size,
            "kind": "command",
            "opcode": opcode,
            "extension": extension,
            "name": command.name,
            "flow": command.flow,
            "operands": list(data[offset + 2:offset + size]),
        }

    command = COMMANDS[opcode]
    operand_count = command.operands
    if opcode == 0xE4:
        if offset + 1 >= len(data):
            raise ValueError("%s has a truncated pan-animation command at $%04X" % (label, offset))
        operand_count = 1 if data[offset + 1] == 0 else 5
    size = 1 + operand_count
    if offset + size > len(data):
        raise ValueError("%s has truncated %s at $%04X" % (label, command.name, offset))
    instruction = {
        "offset": offset,
        "size": size,
        "kind": "command",
        "opcode": opcode,
        "name": command.name,
        "flow": command.flow,
        "operands": list(data[offset + 1:offset + size]),
    }
    if opcode in (0xF6, 0xF8):
        instruction["target"] = offset + 2 + _signed_word(data, offset + 1)
    elif opcode == 0xF7:
        instruction["target"] = offset + 4 + _signed_word(data, offset + 3)
    return instruction


def decode_reachable_sequence(
    label: str, data: bytes, starts: list[int], instrument_offset: int,
    minimum_offset: int = 0,
) -> dict[str, Any]:
    """Walk reachable events, branches, calls, and returns without simulating time."""
    pending = deque(starts)
    instructions: dict[int, dict[str, Any]] = {}
    occupied: dict[int, int] = {}
    command_counts: Counter[str] = Counter()
    event_count = 0
    instrument_ids: set[int] = set()
    while pending:
        cursor = pending.popleft()
        while cursor not in instructions:
            if cursor < minimum_offset:
                raise ValueError(
                    "%s control flow enters its header at $%04X" % (label, cursor)
                )
            if cursor in occupied:
                raise ValueError(
                    "%s control flow enters the middle of instruction $%04X at $%04X"
                    % (label, occupied[cursor], cursor)
                )
            instruction = decode_instruction(label, data, cursor)
            for position in range(cursor, cursor + instruction["size"]):
                owner = occupied.get(position)
                if owner is not None and owner != cursor:
                    raise ValueError(
                        "%s instruction $%04X overlaps instruction $%04X"
                        % (label, cursor, owner)
                    )
                occupied[position] = cursor
            instructions[cursor] = instruction
            if instruction["kind"] == "command":
                command_counts[instruction["name"]] += 1
                if instruction["opcode"] == 0xEF:
                    instrument_id = instruction["operands"][0]
                    end = instrument_offset + (instrument_id + 1) * FM_INSTRUMENT_BYTES
                    if end > len(data):
                        raise ValueError(
                            "%s instrument %d ends at $%04X outside its payload"
                            % (label, instrument_id, end)
                        )
                    instrument_ids.add(instrument_id)
            else:
                event_count += 1

            flow = instruction.get("flow", "next")
            next_offset = cursor + instruction["size"]
            if flow in ("stop", "return"):
                break
            if flow == "jump":
                pending.append(instruction["target"])
                break
            if flow in ("branch", "call"):
                pending.append(instruction["target"])
            cursor = next_offset
    return {
        "entry_offsets": starts,
        "instruction_count": len(instructions),
        "event_count": event_count,
        "command_count": sum(command_counts.values()),
        "reachable_byte_count": len(occupied),
        "command_counts": dict(sorted(command_counts.items())),
        "instrument_ids": sorted(instrument_ids),
        "instructions": [instructions[offset] for offset in sorted(instructions)],
    }


def bgm_label(request_id: int) -> str:
    """Resolve the exact aliasing performed by Sound_BGMPointerTable."""
    if request_id not in BGM_REQUEST_IDS:
        raise ValueError("BGM request is outside $81-$9F: $%02X" % request_id)
    payload_id = 0x81 if 0x99 <= request_id <= 0x9E else request_id
    return "Sound_BGM_%02X" % payload_id


def sfx_label(request_id: int) -> str:
    if request_id not in SFX_REQUEST_IDS:
        raise ValueError("SFX request is outside the three sequence ranges: $%02X" % request_id)
    return "Sound_SFX_%02X" % request_id


def _checked_offset(
    label: str, role: str, value: int, size: int, *, allow_end: bool = False,
) -> None:
    maximum = size if allow_end else size - 1
    if not 0 <= value <= maximum:
        raise ValueError(
            "%s %s offset $%04X is outside its $%04X-byte payload"
            % (label, role, value, size)
        )


def decode_bgm_header(label: str, data: bytes) -> dict[str, Any]:
    """Decode only fields consumed by Sound_LoadBGMRequest."""
    if len(data) < 6:
        raise ValueError("%s is shorter than the six-byte BGM header" % label)
    fm_count = data[2]
    psg_count = data[3]
    if fm_count > len(BGM_FM_CHANNEL_TYPES):
        raise ValueError("%s declares too many BGM FM/DAC channels: %d" % (label, fm_count))
    if psg_count > len(BGM_PSG_CHANNEL_TYPES):
        raise ValueError("%s declares too many BGM PSG channels: %d" % (label, psg_count))
    header_size = 6 + fm_count * 4 + psg_count * 6
    if header_size > len(data):
        raise ValueError(
            "%s header needs $%X bytes but payload has $%X" % (label, header_size, len(data))
        )

    instrument_offset = _word(data, 0)
    # The pointer is stored for a later $EF command. PSG-only payloads may
    # legally point one byte past the payload because they never dereference it.
    _checked_offset(
        label, "instrument", instrument_offset, len(data), allow_end=True)
    channels = []
    cursor = 6
    for index in range(fm_count):
        sequence_offset = _word(data, cursor)
        _checked_offset(label, "FM/DAC sequence", sequence_offset, len(data))
        channels.append({
            "family": "fm_or_dac",
            "index": index,
            "runtime_channel_type": BGM_FM_CHANNEL_TYPES[index],
            "sequence_offset": sequence_offset,
            "initial_word": _word(data, cursor + 2),
        })
        cursor += 4
    for index in range(psg_count):
        sequence_offset = _word(data, cursor)
        _checked_offset(label, "PSG sequence", sequence_offset, len(data))
        channels.append({
            "family": "psg",
            "index": index,
            "runtime_channel_type": BGM_PSG_CHANNEL_TYPES[index],
            "sequence_offset": sequence_offset,
            "initial_word": _word(data, cursor + 2),
            "initial_envelope": data[cursor + 4],
            "initial_modulation": data[cursor + 5],
        })
        cursor += 6
    starts = [channel["sequence_offset"] for channel in channels]
    if any(value < header_size for value in starts):
        raise ValueError("%s has a sequence pointer inside its header" % label)
    sequence = decode_reachable_sequence(
        label, data, starts, instrument_offset, minimum_offset=header_size)
    return {
        "label": label,
        "byte_count": len(data),
        "header_byte_count": header_size,
        "instrument_offset": instrument_offset,
        "fm_or_dac_channel_count": fm_count,
        "psg_channel_count": psg_count,
        "initial_tick_multiplier": data[4],
        "tempo": data[5],
        "channels": channels,
        "sequence": sequence,
    }


def decode_sfx_header(label: str, data: bytes) -> dict[str, Any]:
    """Decode only fields consumed by ordinary/special SFX loaders."""
    if len(data) < 4:
        raise ValueError("%s is shorter than the four-byte SFX header" % label)
    channel_count = data[3]
    if not 1 <= channel_count <= 6:
        raise ValueError("%s declares an invalid SFX channel count: %d" % (label, channel_count))
    header_size = 4 + channel_count * 6
    if header_size > len(data):
        raise ValueError(
            "%s header needs $%X bytes but payload has $%X" % (label, header_size, len(data))
        )
    instrument_offset = _word(data, 0)
    _checked_offset(
        label, "instrument", instrument_offset, len(data), allow_end=True)
    channels = []
    cursor = 4
    for index in range(channel_count):
        sequence_offset = _word(data, cursor + 2)
        _checked_offset(label, "sequence", sequence_offset, len(data))
        channels.append({
            "index": index,
            "status_and_channel_word": _word(data, cursor),
            "runtime_channel_type": data[cursor + 1],
            "sequence_offset": sequence_offset,
            "initial_word": _word(data, cursor + 4),
        })
        cursor += 6
    starts = [channel["sequence_offset"] for channel in channels]
    if any(value < header_size for value in starts):
        raise ValueError("%s has a sequence pointer inside its header" % label)
    sequence = decode_reachable_sequence(
        label, data, starts, instrument_offset, minimum_offset=header_size)
    return {
        "label": label,
        "byte_count": len(data),
        "header_byte_count": header_size,
        "instrument_offset": instrument_offset,
        "priority": data[2],
        "channel_count": channel_count,
        "channels": channels,
        "sequence": sequence,
    }


def export_inventory(root: Path, profile: str) -> dict[str, Any]:
    if profile not in PROFILES:
        raise ValueError("unknown sound profile: %s" % profile)
    data, _bodies = labelled_blocks(root)
    unique_bgm_labels = tuple(dict.fromkeys(bgm_label(value) for value in BGM_REQUEST_IDS))
    bgm = []
    for label in unique_bgm_labels:
        payload = data.get(label)
        if not isinstance(payload, bytes):
            raise ValueError("BGM payload is missing: %s" % label)
        bgm.append(decode_bgm_header(label, payload))
    sfx = []
    for request_id in SFX_REQUEST_IDS:
        label = sfx_label(request_id)
        payload = data.get(label)
        if not isinstance(payload, bytes):
            raise ValueError("SFX payload is missing: %s" % label)
        record = decode_sfx_header(label, payload)
        record["request_id"] = request_id
        record["request_class"] = (
            "low" if request_id < 0x80 else
            "ordinary" if request_id < 0xF9 else "special"
        )
        sfx.append(record)
    banks = []
    for index, expected_size in enumerate(PCM_BANK_LENGTHS, 1):
        label = "Sound_PCMBank%d" % index
        payload = data.get(label)
        if not isinstance(payload, bytes):
            raise ValueError("PCM bank is missing: %s" % label)
        if len(payload) != expected_size:
            raise ValueError(
                "%s has $%X bytes instead of $%X" % (label, len(payload), expected_size)
            )
        banks.append({"label": label, "byte_count": len(payload)})
    sequence_records = [
        item["sequence"] for item in [*bgm, *sfx]
    ]
    aggregate_commands: Counter[str] = Counter()
    for sequence in sequence_records:
        aggregate_commands.update(sequence["command_counts"])
    return {
        "schema_version": 1,
        "profile": profile,
        "format": "treasure-smps-68k-type-2-header-inventory",
        "bgm_request_count": len(BGM_REQUEST_IDS),
        "bgm_payload_count": len(bgm),
        "sfx_request_count": len(sfx),
        "pcm_bank_count": len(banks),
        "pcm_byte_count": sum(item["byte_count"] for item in banks),
        "sequence_entry_count": sum(
            len(item["entry_offsets"]) for item in sequence_records),
        "sequence_instruction_count": sum(
            item["instruction_count"] for item in sequence_records),
        "sequence_event_count": sum(item["event_count"] for item in sequence_records),
        "sequence_command_count": sum(
            item["command_count"] for item in sequence_records),
        "sequence_reachable_byte_count": sum(
            item["reachable_byte_count"] for item in sequence_records),
        "sequence_command_kinds": dict(sorted(aggregate_commands.items())),
        "bgm_requests": [
            {"request_id": value, "payload": bgm_label(value)}
            for value in BGM_REQUEST_IDS
        ],
        "bgm_payloads": bgm,
        "sfx_payloads": sfx,
        "pcm_banks": banks,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "export"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=PROFILES, default="jp")
    parser.add_argument("--output")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        document = export_inventory(root, args.profile)
        if args.command == "export":
            if not args.output:
                raise ValueError("export requires --output")
            output = Path(args.output)
            from authoring.atomic_output import atomic_write_json

            atomic_write_json(output, document, ensure_ascii=True)
            print("[OK] Sound inventory exported: %s" % output)
        else:
            print(
                "[OK] %s sound inventory: %d BGM requests / %d payloads, "
                "%d SFX, %d PCM banks ($%X bytes); %d reachable instructions"
                % (
                    args.profile,
                    document["bgm_request_count"],
                    document["bgm_payload_count"],
                    document["sfx_request_count"],
                    document["pcm_bank_count"],
                    document["pcm_byte_count"],
                    document["sequence_instruction_count"],
                )
            )
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
