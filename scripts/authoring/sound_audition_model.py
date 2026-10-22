"""Source-bound request and loader-state contracts for original-driver audition."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path

from authoring.content_workspace import checked_path
from authoring.sound_studio_model import (
    BGM_REQUEST_IDS,
    SFX_REQUEST_IDS,
    bgm_label,
    decode_bgm_header,
    decode_sfx_header,
    sfx_label,
)
from extract_symbols import EQU, LABEL, LISTING_ROW, SOURCE_COLUMN


PAYLOAD_OWNERS = (
    "src/sound/music_tracks.s",
    "src/sound/sfx_tracks_a0_to_ef.s",
    "src/sound/sfx_tracks_40_to_7f_and_f0_to_fc.s",
)
LOADER_SOURCE = "src/sound/playback_and_loading.s"
RAM_NAMES = (
    "GameModeIndex",
    "GameSubstateIndex",
    "SoundRequestQueue",
    "SoundSelectedRequest",
    "SoundCurrentPriority",
    "SoundTempoReload",
    "SoundBGMDataPtr",
    "SoundPCMChannelRecord",
    "SoundBGMPSGChannels",
    "SoundSpecialSFXDataPtr",
    "SoundSpecialSFXFM",
    "SoundSpecialSFXPSG",
    "PaletteFadeMaskStatus",
    "ScenePaletteFadeOffset",
    "DataLoaderControl",
)
ROM_NAMES = (
    "Sound_LoadBGMRequest",
    "Sound_StopSFXAndRestoreBGMChannels",
    "Sound_FinishBGMInitialization",
    "Sound_LoadSFXReturn",
    "Sound_LoadSpecialSFXReturn",
    "Sound_SFXChannelRecordPointers",
    "Sound_BGMPointerTable",
    "Sound_OrdinarySFXPointerTableBase",
    "Sound_SpecialSFXPointerTable",
    "Sound_SelectPendingRequest",
    "Sound_ValidateVoiceDACRequest",
    "Sound_DispatchPendingRequest",
)


def request_for_payload(label: str) -> int:
    """Resolve canonical payload names; BGM aliases share their lowest request."""
    if not isinstance(label, str):
        raise ValueError("audition payload name must be a string")
    for request in BGM_REQUEST_IDS:
        if bgm_label(request) == label:
            return request
    for request in SFX_REQUEST_IDS:
        if sfx_label(request) == label:
            return request
    raise ValueError("payload has no supported BGM/SFX request: %s" % label)


def payload_for_request(request: int) -> str:
    if not isinstance(request, int) or isinstance(request, bool):
        raise ValueError("sound request must be an integer")
    if request in BGM_REQUEST_IDS:
        return bgm_label(request)
    return sfx_label(request)


def listing_symbols(path: Path, wanted: set[str]) -> dict[str, int]:
    """Stream the AS listing instead of retaining its multi-megabyte text."""
    found = {}
    with path.open(encoding="latin-1") as stream:
        for line in stream:
            row = LISTING_ROW.match(line)
            if not row or len(line) <= SOURCE_COLUMN:
                continue
            source = line[SOURCE_COLUMN:].lstrip()
            label, equ = LABEL.match(source), EQU.match(source)
            if label:
                name, address = label[1], int(row[1], 16)
            elif equ:
                name, address = equ[1], int(equ[2], 16) & 0xFFFFFF
            else:
                continue
            if name in wanted:
                if name in found and found[name] != address:
                    raise ValueError("listing has conflicting symbol: %s" % name)
                found[name] = address
    missing = wanted - set(found)
    if missing:
        raise ValueError("audition listing is missing: %s" % ", ".join(sorted(missing)))
    return found


def payload_body(root: Path, label: str) -> bytes:
    """Read only the selected sound record, from its three explicit owners."""
    body = None
    for relative in PAYLOAD_OWNERS:
        active = False
        values = []
        for line in (root / relative).read_text(encoding="utf-8").splitlines():
            source = line.split(";", 1)[0].strip()
            head = LABEL.match(source)
            if head:
                if active:
                    break
                active = head[1] == label
                source = source[head.end() :].strip()
            if not active or not source:
                continue
            include = re.fullmatch(r'binclude\s+"([^"]+)"', source)
            if include:
                values.extend(checked_path(root, include[1]).read_bytes())
            elif source.startswith("dc.b"):
                for token in source[4:].strip().split(","):
                    token = token.strip()
                    value = int(token[1:], 16) if token.startswith("$") else int(token)
                    if not 0 <= value <= 255:
                        raise ValueError("sound source contains a non-byte value")
                    values.append(value)
            elif source.startswith("align"):
                break  # Final SFX owner has bank-alignment padding after its record.
            else:
                raise ValueError("unsupported sound record directive: %s" % source)
        if active:
            if body is not None:
                raise ValueError("multiple source owners for %s" % label)
            body = bytes(values)
    if not body:
        raise ValueError("sound payload has no source bytes: %s" % label)
    return body


def source_contract(root: Path) -> None:
    loader = (root / LOADER_SOURCE).read_text(encoding="utf-8")
    signatures = (
        "lea     (SoundPCMChannelRecord).w,a1",
        "moveq   #$30,d6",
        "move.b  d3,(a1)",
        "move.b  (a2)+,1(a1)",
        "move.b  d4,2(a1)",
        "move.l  d0,4(a1)",
        "move.w  (a4)+,8(a1)",
        "move.b  d5,$E(a1)",
        "move.b  (a4)+,$A(a1)",
        "move.b  (a4)+,$B(a1)",
        "move.w  (a1)+,(a5)",
        "move.b  d5,2(a5)",
        "move.l  d0,4(a5)",
        "move.w  (a1)+,8(a5)",
        "move.b  #1,$E(a5)",
        "move.b  d6,$D(a5)",
        "move.l  d1,$20(a5)",
        "move.l  d0,(SoundSpecialSFXDataPtr).w",
    )
    for signature in signatures:
        if signature not in loader:
            raise ValueError("sound audition loader contract changed: %s" % signature)
    title = (root / "src/ui/title_screen.s").read_text(encoding="utf-8")
    options = (root / "src/ui/options_menu_controllers.s").read_text(encoding="utf-8")
    if "move.w  #$1C,(GameModeIndex).w" not in title or "move.w  #$20,(GameModeIndex).w" not in options:
        raise ValueError("sound audition options route changed")
    story = (root / "src/cutscenes/story_screen_and_title_transition.s").read_text(encoding="utf-8")
    if "StoryScreen_MainLoop:" not in story or "StoryScreen_RunFrame:" not in story:
        raise ValueError("sound audition story Start reader is missing")
    reader = story.split("StoryScreen_MainLoop:", 1)[1].split("StoryScreen_RunFrame:", 1)[0]
    for signature in (
        "btst    #0,(PaletteFadeMaskStatus).w",
        "tst.w   (ScenePaletteFadeOffset).l",
        "tst.w   (DataLoaderControl).w",
        "btst    #7,(ControllerPressedState).w",
        "bne.w   StoryScreen_StartExitFade",
    ):
        if signature not in reader:
            raise ValueError("sound audition story Start gate changed: %s" % signature)
    table = (root / "src/system/vblank.s").read_text(encoding="utf-8").split("Sys_GameStateHandlers:", 1)
    if len(table) != 2:
        raise ValueError("sound audition mode dispatch table is missing")
    handlers = re.findall(r"\bdc\.l\s+([A-Za-z_][A-Za-z_0-9]*)", table[1])
    for name, mode in (
        ("TitleScreen_Update", 0x18),
        ("UI_InitOptionsScreen", 0x1C),
        ("UI_UpdateOptionsScreen", 0x20),
        ("StoryScreen_MainLoop", 0x28),
    ):
        if name not in handlers or handlers.index(name) * 4 != mode:
            raise ValueError("sound audition dispatch mode changed: %s" % name)


def loader_expectations(
    request: int, body: bytes, base: int, symbols: dict[str, int], sfx_pointers: list[int]
) -> tuple[str, list[dict]]:
    """Capture exact initialization before any sequence event advances its cursor."""
    label = payload_for_request(request)
    music = request in BGM_REQUEST_IDS
    header = decode_bgm_header(label, body) if music else decode_sfx_header(label, body)
    checks = []

    def add(name, address, size, value):
        checks.append({"name": name, "address": address & 0xFFFFFF, "size": size, "value": value})

    add("options_mode", symbols["GameModeIndex"], 2, 0x20)

    if music:
        if not header["fm_or_dac_channel_count"]:
            # The source's FM-count-zero branch skips register initialization.
            raise ValueError("FM-count-zero BGM requires a separate loader-state proof")
        hook = "Sound_FinishBGMInitialization"
        add("bgm_instrument_pointer", symbols["SoundBGMDataPtr"], 4, base + header["instrument_offset"])
        add("bgm_tempo", symbols["SoundTempoReload"], 1, header["tempo"])
    else:
        hook = "Sound_LoadSpecialSFXReturn" if request >= 0xF9 else "Sound_LoadSFXReturn"
        if request >= 0xF9:
            add("special_instrument_pointer", symbols["SoundSpecialSFXDataPtr"], 4, base + header["instrument_offset"])
    occupied = set()
    for index, channel in enumerate(header["channels"]):
        kind = channel["runtime_channel_type"]
        if music:
            start = (
                symbols["SoundPCMChannelRecord"] if channel["family"] == "fm_or_dac" else symbols["SoundBGMPSGChannels"]
            )
            at = start + channel["index"] * 0x30
            flags = 0x80
            multiplier = header["initial_tick_multiplier"]
        else:
            if request >= 0xF9:
                at = symbols["SoundSpecialSFXPSG" if kind & 0x80 else "SoundSpecialSFXFM"]
            else:
                slot = kind >> 5 if kind & 0x80 else kind - 2
                if not 0 <= slot < len(sfx_pointers) or not sfx_pointers[slot]:
                    raise ValueError("SFX channel has no runtime record: $%02X" % kind)
                at = sfx_pointers[slot] & 0xFFFFFF
            flags = channel["status_and_channel_word"] >> 8
            multiplier = header["priority"]  # Header byte 2 is loaded into field 2.
        if at in occupied:
            raise ValueError("selected sound header overwrites the same channel twice")
        occupied.add(at)
        prefix = "channel_%d_" % index
        for name, offset, size, value in (
            ("status", 0, 1, flags),
            ("type", 1, 1, kind),
            ("tick_multiplier", 2, 1, multiplier),
            ("sequence_pointer", 4, 4, base + channel["sequence_offset"]),
            ("initial_word", 8, 2, channel["initial_word"]),
            ("record_stride", 0xD, 1, 0x30),
            ("event_counter", 0xE, 1, 1),
        ):
            add(prefix + name, at + offset, size, value)
        if music and channel["family"] == "psg":
            add(prefix + "pitch_selector", at + 0xA, 1, channel["initial_envelope"])
            add(prefix + "volume_selector", at + 0xB, 1, channel["initial_modulation"])
        if not music and request < 0xF9:
            add(prefix + "instrument_pointer", at + 0x20, 4, base + header["instrument_offset"])
    return hook, checks


def build_contract(
    root: Path, tree: Path, profile: str, request: int, image: bytes, original: bytes, listing: Path
) -> dict:
    """Bind selected staged payload, pointer tables and unchanged loaders to ROM."""
    if profile not in ("jp", "eu"):
        raise ValueError("sound audition profile must be jp or eu")
    source_contract(root)
    label = payload_for_request(request)
    symbols = listing_symbols(listing, set(RAM_NAMES + ROM_NAMES) | {label})
    for name in RAM_NAMES:
        if not 0xFF0000 <= symbols[name] <= 0xFFFFFF:
            raise ValueError("audition RAM symbol is outside work RAM: %s" % name)
    for name in ROM_NAMES + (label,):
        if not 0 <= symbols[name] < len(image):
            raise ValueError("audition ROM symbol is outside the image: %s" % name)
    body = payload_body(tree, label)
    base = symbols[label]
    if image[base : base + len(body)] != body:
        raise ValueError("listing/ROM do not identify the selected staged sound payload")
    for first, last in (
        ("Sound_LoadBGMRequest", "Sound_StopSFXAndRestoreBGMChannels"),
        ("Sound_SelectPendingRequest", "Sound_ValidateVoiceDACRequest"),
    ):
        begin, end = symbols[first], symbols[last]
        if not begin < end or image[begin:end] != original[begin:end]:
            raise ValueError("sound loader/dispatcher differs from preservation ROM")
    if request in BGM_REQUEST_IDS:
        table = symbols["Sound_BGMPointerTable"] + (request - 0x81) * 4
    elif request >= 0xF9:
        table = symbols["Sound_SpecialSFXPointerTable"] + (request - 0xF9) * 4
    else:
        slot = request + 0x1D if request < 0x80 else request - 0xA0
        table = symbols["Sound_OrdinarySFXPointerTableBase"] + slot * 4
    if int.from_bytes(image[table : table + 4], "big") != base:
        raise ValueError("selected request pointer does not address its listed payload")
    pointer_base = symbols["Sound_SFXChannelRecordPointers"]
    pointers = [
        int.from_bytes(image[pointer_base + offset : pointer_base + offset + 4], "big") for offset in range(0, 32, 4)
    ]
    hook, checks = loader_expectations(request, body, base, symbols, pointers)
    opcode = b"\x58\x4f\x4e\x75" if request in BGM_REQUEST_IDS else b"\x4e\x75"
    if image[symbols[hook] : symbols[hook] + len(opcode)] != opcode:
        raise ValueError("audition loader return opcode does not match its symbol")
    dispatch = symbols["Sound_DispatchPendingRequest"]
    if image[dispatch : dispatch + 2] != b"\x7e\x00":
        raise ValueError("audition dispatcher opcode does not match its symbol")
    return {
        "schema_version": 1,
        "profile": profile,
        "request_id": request,
        "payload": label,
        "rom_sha256": hashlib.sha256(image).hexdigest(),
        "listing_sha256": digest_file(listing),
        "hook_address": symbols[hook],
        "dispatch_hook_address": symbols["Sound_DispatchPendingRequest"],
        "hook_symbol": hook,
        "ram": {name: symbols[name] for name in RAM_NAMES},
        "checks": checks,
    }


def digest_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()
