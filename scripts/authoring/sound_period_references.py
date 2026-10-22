"""Source-relative effective PSG tone-period reference safety."""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import Path

from authoring.sound_studio_model import decode_instruction


TABLE = "Sound_PSGNotePeriodTable"
MAX_STATES = 250000
MAX_STACK_DEPTH = 2


@dataclass(frozen=True)
class PSGRead:
    channel: int
    offset: int
    channel_type: int
    transpose: int
    note: int
    index: int
    instruction: tuple
    pitch_controls: tuple
    path_state: tuple
    source_contract: tuple


class Unanalysed(ValueError):
    """A source path requires more state than this proved bounded model."""


def _code(bodies, name):
    if name not in bodies:
        raise ValueError("PSG reader contract is missing %s" % name)
    return "\n".join(line.split(";", 1)[0].strip() for line in bodies[name] if line.split(";", 1)[0].strip())


def period_contract(root: Path, stored: dict, bodies: dict) -> dict:
    words = stored.get(TABLE)
    if (
        not isinstance(words, tuple)
        or not words
        or any(type(value) is not int or not 0 <= value <= 0xFFFF for value in words)
    ):
        raise ValueError("PSG period table must be a source-owned word tuple")
    requirements = {
        "Sound_DecodePSGSequenceNote": (
            "subi.b  #$81,d5",
            "bcs.s   Sound_MarkPSGChannelRest",
            "add.b   8(a5),d5",
            "andi.w  #$7F,d5",
            "lsl.w   #1,d5",
            "lea     Sound_PSGNotePeriodTable(pc),a0",
            "move.w  (a0,d5.w),$10(a5)",
            "bra.w Sound_SaveChannelState",
        ),
        "Sound_AddChannelTranspose": ("move.b (a4)+,d0", "add.b d0,8(a5)", "rts"),
        "Sound_SetPSGNoiseMode": (
            "move.b #$E0,1(a5)",
            "move.b (a4)+,$25(a5)",
            "btst #2,(a5)",
            "bne.s Sound_SetPSGNoiseModeReturn",
            "move.b -1(a4),(VDP_PSG).l",
        ),
        "Sound_SetPSGNoiseModeReturn": ("rts",),
        "Sound_RepeatSequenceBlock": (
            "moveq #0,d0",
            "move.b (a4)+,d0",
            "move.b (a4)+,d1",
            "tst.b $28(a5,d0.w)",
            "bne.s Sound_DecrementSequenceLoopCounter",
            "move.b d1,$28(a5,d0.w)",
        ),
        "Sound_DecrementSequenceLoopCounter": (
            "subq.b #1,$28(a5,d0.w)",
            "bne.s Sound_JumpSequenceRelative",
            "addq.w #2,a4",
            "rts",
        ),
        "Sound_CallRelativeSequenceSubroutine": (
            "moveq #0,d0",
            "move.b $D(a5),d0",
            "subq.b #4,d0",
            "move.l a4,(a5,d0.w)",
            "move.b d0,$D(a5)",
            "bra.s Sound_JumpSequenceRelative",
        ),
        "Sound_ReturnFromSequenceSubroutine": (
            "moveq #0,d0",
            "move.b $D(a5),d0",
            "movea.l (a5,d0.w),a4",
            "addq.w #2,a4",
            "addq.b #4,d0",
            "move.b d0,$D(a5)",
            "rts",
        ),
        "Sound_JumpSequenceRelative": (
            "move.b (a4)+,d0",
            "lsl.w #8,d0",
            "move.b (a4)+,d0",
            "adda.w d0,a4",
            "subq.w #1,a4",
            "rts",
        ),
        "Sound_InitializeBGM": (
            "jsr Sound_StopSFXAndRestoreBGMChannels(pc)",
            "jsr Sound_StopSpecialSFXAndRestoreBGMChannels(pc)",
            "jsr Sound_ResetPlaybackState(pc)",
            "lea Sound_BGMPointerTable(pc),a4",
            "subi.b #$81,d7",
            "lsl.w #2,d7",
            "movea.l (a4,d7.w),a4",
            "moveq #0,d0",
            "move.w (a4),d0",
            "add.l a4,d0",
            "move.l d0,(SoundBGMDataPtr).w",
            "move.b 5(a4),(SoundTempoReload).w",
            "move.b 5(a4),(SoundTempoCounter).w",
            "moveq #0,d1",
            "movea.l a4,a3",
            "addq.w #6,a4",
            "moveq #0,d7",
            "move.b 2(a3),d7",
            "beq.s Sound_InitializeBGMPSGChannels",
            "subq.b #1,d7",
            "move.b #$C0,d1",
            "move.b #$80,d3",
            "move.b 4(a3),d4",
            "moveq #$30,d6",
            "move.b #1,d5",
            "lea (SoundPCMChannelRecord).w,a1",
            "lea Sound_BGMFMChannelTypes(pc),a2",
        ),
        "Sound_InitializeNextBGMFMChannel": (
            "move.b d3,(a1)",
            "move.b (a2)+,1(a1)",
            "move.b d4,2(a1)",
            "move.b d6,$D(a1)",
            "move.b d1,$27(a1)",
            "move.b d5,$E(a1)",
            "moveq #0,d0",
            "move.w (a4)+,d0",
            "add.l a3,d0",
            "move.l d0,4(a1)",
            "move.w (a4)+,8(a1)",
            "adda.w d6,a1",
            "dbf d7,Sound_InitializeNextBGMFMChannel",
        ),
        "Sound_InitializeNextBGMPSGChannel": (
            "move.b d3,(a1)",
            "move.b (a2)+,1(a1)",
            "move.b d4,2(a1)",
            "move.b d6,$D(a1)",
            "move.b d5,$E(a1)",
            "moveq #0,d0",
            "move.w (a4)+,d0",
            "add.l a3,d0",
            "move.l d0,4(a1)",
            "move.w (a4)+,8(a1)",
            "move.b (a4)+,$A(a1)",
            "move.b (a4)+,$B(a1)",
            "adda.w d6,a1",
            "dbf d7,Sound_InitializeNextBGMPSGChannel",
        ),
        "Sound_ResetPlaybackState": (
            "moveq #$27,d0",
            "moveq #0,d1",
            "jsr Sound_WriteYM2612Port0Thunk(pc)",
            "move.b (SoundCurrentPriority).w,d0",
            "move.w d0,-(sp)",
            "lea (SoundCurrentPriority).w,a0",
            "move.w #$87,d0",
        ),
        "Sound_ClearPlaybackStateForBGM": (
            "clr.l (a0)+",
            "dbf d0,Sound_ClearPlaybackStateForBGM",
            "move.w (sp)+,d0",
            "move.b d0,(SoundCurrentPriority).w",
            "move.b #$FF,(SoundSelectedRequest).w",
            "rts",
        ),
        "Sound_ResolveSFXHeader": (
            "lsl.w #2,d7",
            "movea.l (a0,d7.w),a3",
            "movea.l a3,a1",
            "moveq #0,d1",
            "move.w (a1)+,d1",
            "add.l a3,d1",
            "move.b (a1)+,d5",
            "moveq #0,d7",
            "move.b (a1)+,d7",
            "subq.w #1,d7",
            "moveq #$30,d6",
        ),
        "Sound_ClearAndInitializeSFXChannel": (
            "movea.l Sound_SFXChannelRecordPointers(pc,d3.w),a5",
            "movea.l a5,a2",
            "moveq #$B,d0",
        ),
        "Sound_ClearSFXChannelRecordLoop": (
            "clr.l (a2)+",
            "dbf d0,Sound_ClearSFXChannelRecordLoop",
            "move.l d1,$20(a5)",
            "move.w (a1)+,(a5)",
            "move.b d5,2(a5)",
            "moveq #0,d0",
            "move.w (a1)+,d0",
            "add.l a3,d0",
            "move.l d0,4(a5)",
            "move.w (a1)+,8(a5)",
            "move.b #1,$E(a5)",
            "move.b d6,$D(a5)",
            "tst.b d4",
            "bmi.s Sound_ContinueSFXChannelInitialization",
            "move.b #$C0,$27(a5)",
        ),
        "Sound_ResolveSpecialSFXHeader": (
            "lea Sound_SpecialSFXPointerTable(pc),a0",
            "subi.b #$F9,d7",
            "lsl.w #2,d7",
            "movea.l (a0,d7.w),a3",
            "movea.l a3,a1",
            "moveq #0,d0",
            "move.w (a1)+,d0",
            "add.l a3,d0",
            "move.l d0,(SoundSpecialSFXDataPtr).w",
            "move.b (a1)+,d5",
            "moveq #0,d7",
            "move.b (a1)+,d7",
            "subq.w #1,d7",
            "moveq #$30,d6",
        ),
        "Sound_ClearAndInitializeSpecialSFXChannel": ("movea.l a5,a2", "moveq #$B,d0"),
        "Sound_ClearSpecialSFXChannelRecordLoop": (
            "clr.l (a2)+",
            "dbf d0,Sound_ClearSpecialSFXChannelRecordLoop",
            "move.w (a1)+,(a5)",
            "move.b d5,2(a5)",
            "moveq #0,d0",
            "move.w (a1)+,d0",
            "add.l a3,d0",
            "move.l d0,4(a5)",
            "move.w (a1)+,8(a5)",
            "move.b #1,$E(a5)",
            "move.b d6,$D(a5)",
            "tst.b d4",
            "bmi.s Sound_ContinueSpecialSFXChannelInitialization",
            "move.b #$C0,$27(a5)",
        ),
    }
    for name, expected in requirements.items():
        actual = re.sub(r"\s+", " ", _code(bodies, name))
        if re.sub(r"\s+", " ", " ".join(expected)) != actual:
            raise ValueError("PSG reference reader differs from the proved instructions: %s" % name)
    for name, instructions in {
        "Sound_ProcessNextBGMFMChannel": ("jsr Sound_ProcessChannel(pc)",),
        "Sound_ProcessBGMPSGChannels": ("jsr Sound_ProcessPSGChannel(pc)",),
        "Sound_ProcessSFXFMChannels": ("jsr Sound_ProcessChannel(pc)",),
        "Sound_ProcessSFXPSGChannels": ("jsr Sound_ProcessPSGChannel(pc)",),
        "Sound_ProcessSpecialSFXChannels": (
            "tst.b 1(a5)",
            "bmi.s Sound_ProcessSpecialSFXPSGChannel",
            "jsr Sound_ProcessChannel(pc)",
        ),
        "Sound_ProcessSpecialSFXPSGChannel": ("jsr Sound_ProcessPSGChannel(pc)",),
    }.items():
        actual = re.sub(r"\s+", " ", _code(bodies, name))
        if any(instruction not in actual for instruction in instructions):
            raise ValueError("PSG physical-record parser routing differs: %s" % name)
    dispatch = re.findall(r"bra\.w\s+(\w+)", _code(bodies, "Sound_SequenceCommandJumpTable"))
    for opcode, handler in (
        (0xF3, "Sound_SetPSGNoiseMode"),
        (0xF6, "Sound_JumpSequenceRelative"),
        (0xF7, "Sound_RepeatSequenceBlock"),
        (0xF8, "Sound_CallRelativeSequenceSubroutine"),
        (0xF9, "Sound_ReturnFromSequenceSubroutine"),
        (0xFB, "Sound_AddChannelTranspose"),
    ):
        if len(dispatch) != 31 or dispatch[opcode - 0xE0] != handler:
            raise ValueError("PSG reference command dispatch differs for $%02X" % opcode)
    ram_text = (root / "src/ram_addrs.inc").read_text(encoding="utf-8")
    for name, address in (
        ("SoundCurrentPriority", 0xFFFFF800),
        ("SoundPCMChannelRecord", 0xFFFFF840),
        ("SoundBGMFMChannels", 0xFFFFF870),
        ("SoundBGMPSGChannels", 0xFFFFF990),
    ):
        match = re.search(r"^%s\s+equ\s+\$([0-9A-F]+)\b" % name, ram_text, re.MULTILINE)
        if match is None or int(match.group(1), 16) != address:
            raise ValueError("PSG initial record clearing range differs for %s" % name)
    table_bytes = b"".join(word.to_bytes(2, "big") for word in words)
    contract_bytes = "\n".join("%s\n%s" % (name, _code(bodies, name)) for name in sorted(requirements)).encode("utf-8")
    return {
        "table": TABLE,
        "word_count": len(words),
        "index_mask": 0x7F,
        "table_sha256": hashlib.sha256(table_bytes).hexdigest(),
        "reader_sha256": hashlib.sha256(contract_bytes).hexdigest(),
    }


def _dispatch(family, header, channel):
    if family == "bgm":
        if channel.get("family") == "psg":
            return "psg"
        return "pcm" if channel["index"] == 0 else "fm"
    # Ordinary SFX choose a physical FM/PSG record at load time; special SFX
    # choose their parser from the current type sign at each driver update.
    match = re.fullmatch(r"Sound_SFX_([0-9A-F]{2})", header["label"])
    if match and 0xF9 <= int(match.group(1), 16) <= 0xFC:
        return "dynamic"
    return "psg" if channel["runtime_channel_type"] & 0x80 else "fm"


def _reader(dispatch, kind):
    return ("psg" if kind & 0x80 else "fm") if dispatch == "dynamic" else dispatch


def analyse_channel(
    family: str, header: dict, body: bytes, channel_number: int, limit: int, source_contract: tuple = ()
) -> dict:
    channel = header["channels"][channel_number]
    dispatch = _dispatch(family, header, channel)
    kind = channel["runtime_channel_type"]
    transpose = channel["initial_word"] >> 8
    # (cursor, kind, transpose, parser for the current event, return stack,
    #  eight loop/stack bytes). All byte arithmetic wraps exactly as add.b.
    state = (channel["sequence_offset"], kind, transpose, _reader(dispatch, kind), (), (0,) * 8, ())
    seen, reads, maximum_stack = set(), set(), 0
    try:
        while state not in seen:
            if len(seen) >= MAX_STATES:
                raise Unanalysed("abstract execution exceeds %d states" % MAX_STATES)
            seen.add(state)
            cursor, kind, transpose, reader, stack, loops, controls = state
            if cursor < header["header_byte_count"]:
                raise Unanalysed("execution enters the header at $%04X" % cursor)
            instruction = decode_instruction(header["label"], body, cursor)
            following = cursor + instruction["size"]
            opcode = instruction.get("opcode")
            if instruction["kind"] == "note":
                note = instruction["value"]
                if reader == "psg" and note != 0x80:
                    reads.add(
                        PSGRead(
                            channel_number,
                            cursor,
                            kind,
                            transpose,
                            note,
                            (note - 0x81 + transpose) & 0x7F,
                            tuple(body[cursor:following]),
                            controls,
                            (reader, stack, loops),
                            source_contract,
                        )
                    )
                reader = _reader(dispatch, kind)
            elif instruction["kind"] == "duration":
                reader = _reader(dispatch, kind)
            elif opcode == 0xFB:
                transpose = (transpose + instruction["operands"][0]) & 0xFF
                controls = tuple(sorted(set(controls) | {(cursor, *body[cursor:following])}))
            elif opcode == 0xF3:
                kind = 0xE0  # Current parser changes only after its event boundary.
                controls = tuple(sorted(set(controls) | {(cursor, *body[cursor:following])}))
            elif opcode == 0xF7:
                selector, count = instruction["operands"][:2]
                if selector >= len(loops):
                    raise Unanalysed(
                        "loop selector %d escapes the channel loop/stack bytes at $%04X" % (selector, cursor)
                    )
                value = loops[selector]
                if value is None:
                    raise Unanalysed("loop selector %d aliases a call return pointer at $%04X" % (selector, cursor))
                value = ((count if value == 0 else value) - 1) & 0xFF
                loops = (*loops[:selector], value, *loops[selector + 1 :])
                if value:
                    following = instruction["target"]
            elif opcode == 0xF8:
                if family == "bgm" and not header["fm_or_dac_channel_count"]:
                    raise Unanalysed("PSG-only BGM skips the source stack-cursor seed at $%04X" % cursor)
                if len(stack) >= MAX_STACK_DEPTH:
                    raise Unanalysed("call depth would exceed the proved loop/stack region at $%04X" % cursor)
                stack = (*stack, following)
                maximum_stack = max(maximum_stack, len(stack))
                # Return pointers remain in those RAM bytes after F9. Their
                # absolute ROM bytes are not invented from payload offsets.
                first = 8 - len(stack) * 4
                loops = (*loops[:first], *(None for _ in range(4)), *loops[first + 4 :])
                following = instruction["target"]
            elif opcode == 0xF9:
                if not stack:
                    raise Unanalysed("return has no source-proved caller at $%04X" % cursor)
                following, stack = stack[-1], stack[:-1]
            elif opcode == 0xF6:
                following = instruction["target"]
            elif opcode == 0xFF and instruction.get("extension") == 3:
                # Sound_StartBGMVolumeAttenuationRequest may consume neither
                # operand when global volume-step state is already active.
                # That cross-channel state is not guessed by this model.
                raise Unanalysed(
                    "extended attenuation consumes operands conditionally on global volume state at $%04X" % cursor
                )
            elif instruction.get("flow") == "stop":
                break
            state = (following, kind, transpose, reader, stack, loops, controls)
    except (Unanalysed, ValueError) as error:
        return {
            "status": "unanalysed",
            "why": str(error),
            "channel": channel_number,
            "state_count": len(seen),
            "max_call_depth": maximum_stack,
            "reads": frozenset(reads),
        }
    return {
        "status": "proved",
        "channel": channel_number,
        "state_count": len(seen),
        "max_call_depth": maximum_stack,
        "reads": frozenset(reads),
        "outside": frozenset(read for read in reads if read.index >= limit),
    }


def analyse_payload(family: str, header: dict, body: bytes, limit: int, source_contract: tuple = ()) -> list[dict]:
    return [
        analyse_channel(family, header, body, channel, limit, source_contract)
        for channel in range(len(header["channels"]))
    ]


def validate_period_references(
    family, original_header, original_body, edited_header, edited_body, limit, source_contract=()
):
    original = analyse_payload(family, original_header, original_body, limit, source_contract)
    edited = (
        analyse_payload(family, edited_header, edited_body, limit, source_contract)
        if edited_body != original_body
        else original
    )
    for source, candidate in zip(original, edited):
        if source["status"] != "proved" or candidate["status"] != "proved":
            if edited_body != original_body:
                unknown = source if source["status"] != "proved" else candidate
                raise ValueError(
                    "PSG pitch safety unanalysed in channel %d: %s; sequence edits are locked"
                    % (unknown["channel"], unknown["why"])
                )
            continue
        added = candidate["outside"] - source["outside"]
        if added:
            read = sorted(added, key=lambda item: (item.offset, item.transpose, item.index))[0]
            raise ValueError(
                "PSG note at $%04X channel %d type $%02X transpose $%02X selects period %d outside 0..%d"
                % (read.offset, read.channel, read.channel_type, read.transpose, read.index, limit - 1)
            )
    return original
