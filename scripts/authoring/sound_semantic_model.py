"""Source channel/event attribution and masked YM2612 parameter controls.

This is not a sequencer or a pitch-name dictionary. Owners describe static
reachability, including shared subroutines, not simultaneous execution time.
"""

from __future__ import annotations

from dataclasses import dataclass

from authoring.sound_studio_model import decode_bgm_header, decode_sfx_header


@dataclass(frozen=True)
class Channel:
    slot: int
    family: str
    entry: int
    runtime_type: int

    @property
    def label(self):
        return "%s header slot %d (initial type $%02X, entry $%04X)" % (
            self.family.upper(),
            self.slot,
            self.runtime_type,
            self.entry,
        )


@dataclass(frozen=True)
class Control:
    name: str
    label: str
    mask: int
    shift: int
    minimum: int
    maximum: int
    allowed: frozenset[int] | None = None

    def read(self, raw: int) -> int:
        return (raw & self.mask) >> self.shift

    def replace(self, raw: int, value: int) -> int:
        if (
            type(value) is not int
            or not self.minimum <= value <= self.maximum
            or self.allowed is not None
            and value not in self.allowed
        ):
            raise ValueError(
                "%s must be %d..%d within its source-owned domain" % (self.label, self.minimum, self.maximum)
            )
        return (raw & (~self.mask & 0xFF)) | (value << self.shift)


def source_channels(payload: dict, body: bytes) -> tuple[Channel, ...]:
    if payload.get("family") not in {"bgm", "sfx"}:
        raise ValueError("source channel family is neither BGM nor SFX")
    decoded = (
        decode_bgm_header(payload["name"], body)
        if payload["family"] == "bgm"
        else decode_sfx_header(payload["name"], body)
    )
    if [item["sequence_offset"] for item in decoded["channels"]] != payload["entry_offsets"]:
        raise ValueError("sequence channel roots differ from the source header")
    channels = []
    for slot, record in enumerate(decoded["channels"]):
        if payload["family"] == "bgm" and record["family"] == "fm_or_dac" and record["index"] == 0:
            family = "dac"
        elif record["runtime_channel_type"] & 0x80:
            family = "psg"
        else:
            family = "fm"
        channels.append(Channel(slot, family, record["sequence_offset"], record["runtime_channel_type"]))
    return tuple(channels)


def channel_owners(payload: dict, channels: tuple[Channel, ...]) -> dict[int, tuple[Channel, ...]]:
    """Follow the same conservative graph as the reviewed sequence decoder."""
    instructions = {item["offset"]: item for item in payload["instructions"]}
    owners = {offset: [] for offset in instructions}
    for channel in channels:
        pending, seen = [channel.entry], set()
        while pending:
            offset = pending.pop()
            if offset in seen:
                continue
            item = instructions.get(offset)
            if item is None:
                raise ValueError("channel graph enters an absent instruction at $%04X" % offset)
            seen.add(offset)
            owners[offset].append(channel)
            flow = item.get("flow", "next")
            if flow in ("stop", "return"):
                continue
            if flow in ("jump", "call", "branch"):
                pending.append(item["target"])
            if flow != "jump":
                pending.append(offset + item["size"])
    return {offset: tuple(records) for offset, records in owners.items()}


FM_PARAMETERS = {
    "algorithm_feedback": (("algorithm", 0x07, 0), ("feedback", 0x38, 3)),
    "detune_multiplier": (("detune", 0x70, 4), ("multiplier", 0x0F, 0)),
    "rate_scale_attack": (("key_scale_rate", 0xC0, 6), ("attack_rate", 0x1F, 0)),
    "am_decay": (("am_enable", 0x80, 7), ("decay_rate", 0x1F, 0)),
    "sustain_rate": (("sustain_rate", 0x1F, 0),),
    "sustain_level_release": (("sustain_level", 0xF0, 4), ("release_rate", 0x0F, 0)),
    "total_level": (("total_level", 0x7F, 0),),
}
FM_REGISTERS = {
    "algorithm_feedback": 0xB0,
    "detune_multiplier": 0x30,
    "rate_scale_attack": 0x50,
    "am_decay": 0x60,
    "sustain_rate": 0x70,
    "sustain_level_release": 0x80,
    "total_level": 0x40,
}
OPERATOR_REGISTER_OFFSETS = (0, 8, 4, 12)


def fm_controls(key: str) -> tuple[Control, ...]:
    return tuple(
        Control(name, name.replace("_", " "), mask, shift, 0, mask >> shift)
        for name, mask, shift in FM_PARAMETERS.get(key, ())
    )


def event_controls(
    instruction: dict, operand: int, owners: tuple[Channel, ...], sample_ids=None
) -> tuple[Control, ...]:
    kind = instruction["kind"]
    if kind == "duration" or kind == "note" and operand == 1:
        return (Control("duration", "encoded duration units (not seconds)", 0xFF, 0, 0, 0x7F),)
    if kind != "note" or operand != 0 or not owners:
        return ()
    if any(channel.family == "dac" for channel in owners):
        if not sample_ids:
            return ()  # No source descriptor table, no fabricated selector range.
        allowed = frozenset({0x80, *sample_ids})
        return (
            Control(
                "event",
                "DAC sample/rest ID; shared owners remain applicable",
                0xFF,
                0,
                min(allowed),
                max(allowed),
                allowed,
            ),
        )
    return (Control("event", "encoded pitch/rest ID (no inferred note names)", 0xFF, 0, 0x80, 0xDF),)


def describe_event(instruction: dict, owners: tuple[Channel, ...]) -> str:
    data = instruction["data"]
    role = instruction["kind"]
    if role == "command":
        detail = "%s / flow %s" % (instruction.get("name", "command"), instruction.get("flow", "next"))
        if "target" in instruction:
            detail += " / target $%04X" % instruction["target"]
    elif role == "duration":
        detail = "duration %d encoded units; runtime tick multiplier/tempo may change" % data[0]
    elif data[0] == 0x80:
        detail = "rest $80"
    else:
        families = {owner.family for owner in owners}
        parts = []
        if "dac" in families:
            parts.append("DAC sample descriptor ID $%02X" % data[0])
        if "fm" in families:
            parts.append("FM pitch ordinal %d before transpose/effects" % (data[0] - 0x80))
        if "psg" in families:
            parts.append("PSG period-table index %d before transpose/effects" % (data[0] - 0x81))
        detail = "; ".join(parts) or "encoded event $%02X; channel binding unavailable" % data[0]
    if role == "note" and len(data) == 2:
        detail += "; duration %d encoded units" % data[1]
    location = "$%04X" % instruction["offset"] if "offset" in instruction else "unavailable"
    return "instruction %s: %s\nStatic header owners (not live processor state): %s" % (
        location,
        detail,
        "; ".join(channel.label for channel in owners) or "unavailable",
    )
