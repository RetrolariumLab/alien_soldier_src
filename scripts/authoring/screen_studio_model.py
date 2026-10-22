#!/usr/bin/env python3
"""Render the explicitly bounded static compositions for Screen Studio."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from dataclasses import replace
from pathlib import Path
from typing import Any


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.palette_model import (  # noqa: E402
    apply_commands,
    command_index,
    named_sets,
    read_source,
)
from authoring.stage_renderer import Scene, build_vram, draw  # noqa: E402
from authoring.stage_tilemap_model import (  # noqa: E402
    DIRECTIVE,
    Tilemap,
    build_ram,
    labelled_blocks,
    read_asset_list,
    read_asset_lists,
    read_descriptors,
)
from authoring.tile_graphics import cram_to_rgb, write_png  # noqa: E402


CONFIG = Path("config/authoring/screens.json")
PROFILES = ("jp", "eu")
TITLE_SOURCE = Path("src/ui/title_screen.s")
SCROLL_SOURCE = Path("src/rendering/scroll_plane_buffers.s")


def load_config(root: Path) -> dict[str, Any]:
    path = root / CONFIG
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise ValueError("cannot load screen inventory %s: %s" % (path, error)) from error
    errors = config_errors(document)
    if errors:
        raise ValueError("; ".join(errors))
    return document


def config_errors(document: dict[str, Any]) -> list[str]:
    errors = []
    if document.get("schema_version") != 1:
        errors.append("screen inventory is not schema 1")
    if tuple(document.get("profiles", ())) != PROFILES:
        errors.append("screen profiles must be jp followed by eu")
    supported = document.get("supported")
    unsupported = document.get("unsupported")
    if not isinstance(supported, list) or not supported:
        errors.append("supported screens are missing")
        supported = []
    if not isinstance(unsupported, list) or not unsupported:
        errors.append("unsupported screen registry is missing")
        unsupported = []
    identifiers = [item.get("id") for item in [*supported, *unsupported] if isinstance(item, dict)]
    if len(identifiers) != len(supported) + len(unsupported):
        errors.append("screen records must be objects with identifiers")
    elif len(set(identifiers)) != len(identifiers):
        errors.append("screen identifiers are not unique")
    for record in supported:
        if not isinstance(record, dict):
            continue
        identifier = record.get("id", "<missing>")
        for field in ("name", "scope", "asset_list"):
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append("%s has no %s" % (identifier, field))
        if "asset_stop_label" in record and (
            not isinstance(record["asset_stop_label"], str) or not record["asset_stop_label"].strip()
        ):
            errors.append("%s has invalid asset stop label" % identifier)
        if "asset_stop_label" in record and (
            not isinstance(record["asset_stop_label"], str) or not record["asset_stop_label"].strip()
        ):
            errors.append("%s has invalid asset stop label" % identifier)
        if not record.get("plane_a") and not record.get("plane_b"):
            errors.append("%s has no plane" % identifier)
        if bool(record.get("palette_command")) == bool(record.get("palette_list")):
            errors.append("%s must name exactly one palette source" % identifier)
        for field in ("width", "height"):
            value = record.get(field)
            if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
                errors.append("%s has invalid %s" % (identifier, field))
        camera_y = record.get("camera_a_y")
        if not isinstance(camera_y, dict) or tuple(camera_y) != PROFILES:
            errors.append("%s has invalid profile camera Y" % identifier)
    for record in unsupported:
        if not isinstance(record, dict):
            continue
        if not isinstance(record.get("reason"), str) or not record["reason"].strip():
            errors.append("%s has no unsupported reason" % record.get("id", "<missing>"))
    return errors


def screen_record(config: dict[str, Any], identifier: str) -> dict[str, Any]:
    try:
        return next(item for item in config["supported"] if item["id"] == identifier)
    except StopIteration as error:
        raise ValueError("unsupported or unknown static screen: %s" % identifier) from error


def palette(root: Path, record: dict[str, Any]) -> tuple[str, list[tuple[int, int, int]]]:
    if "palette_list" in record:
        sets = {item["name"]: item for item in named_sets(root)}
        name = record["palette_list"]
        if name not in sets:
            raise ValueError("screen palette list is missing: %s" % name)
        return name, list(sets[name]["rgb"])
    blocks, _lists = read_source(root)
    commands, _other = command_index(blocks)
    name = record["palette_command"]
    command = commands.get((name, 0))
    if command is None:
        raise ValueError("screen palette command is missing: %s" % name)
    words = apply_commands([command])
    return name, [cram_to_rgb(word) for word in words]


def apply_postload_transforms(record: dict[str, Any], ram: bytes | bytearray) -> bytes:
    """Replay the title's two RAM tile-index passes before plane transfer.

    TitleScreen_FinalizeInitialization calls Gfx_AdjustTileIndexRows on
    $FFFF4020 for $27+1 groups of 16 words, then Gfx_UpdateTilemapIndices on
    $FFFF2020 for $BF+1 groups. Other supported screens do neither.
    """
    if record["id"] != "title_background":
        return bytes(ram)
    result = bytearray(ram)
    for index in range(0x28 * 16):
        at = 0x4020 + index * 2
        word = int.from_bytes(result[at : at + 2], "big")
        result[at : at + 2] = (((word & 0x1FFF) + 0xC180) & 0xFFFF).to_bytes(2, "big")
    for index in range(0xC0 * 16):
        at = 0x2020 + index * 2
        word = int.from_bytes(result[at : at + 2], "big")
        tile = word & 0x7FF
        if tile:
            tile = (tile + 0xFF00) & 0x7FF
        result[at : at + 2] = (((tile | (word & 0x1800)) + 0x6000) & 0xFFFF).to_bytes(2, "big")
    return bytes(result)


def screen_view_y(record: dict[str, Any], profile: str) -> tuple[int, int]:
    """Return map lookups, not the semantic camera words stored by the game.

    Title maps are uploaded at Y=0 before EU sets camera A=-16. Scroll negates
    that word, and VDP adds VSRAM to the raster line: the EU lookup is +16.
    Story's static B and options stay at zero; dynamic story text is excluded.
    """
    if profile not in PROFILES:
        raise ValueError("unknown screen profile: %s" % profile)
    identifier = record.get("id")
    if identifier not in ("title_background", "options_background", "story_background"):
        raise ValueError("screen has no source-owned static lookup route: %s" % identifier)
    cameras = record.get("camera_a_y")
    declared_a = cameras.get(profile) if isinstance(cameras, dict) else None
    declared_b = record.get("camera_b_y")
    expected_a = -16 if identifier == "title_background" and profile == "eu" else 0
    if type(declared_a) is not int or declared_a != expected_a or type(declared_b) is not int or declared_b != 0:
        raise ValueError("screen semantic camera Y differs from its source-owned route")
    return (-declared_a, -declared_b)


def _routine_lines(root: Path, owner: Path, first: str, following: str) -> tuple[str, ...]:
    """Read bounded assembly operations, ignoring comments, never addresses."""
    lines = tuple(
        " ".join(line.split(";", 1)[0].split()) for line in (root / owner).read_text(encoding="utf-8").splitlines()
    )
    ends = [index for index, line in enumerate(lines) if line == following + ":" or line.startswith(following + ": ")]
    if lines.count(first + ":") != 1 or len(ends) != 1:
        raise ValueError("screen view source has no unique bounded routine: %s" % first)
    start, end = lines.index(first + ":"), ends[0]
    if start >= end:
        raise ValueError("screen view source routine order differs: %s" % first)
    return tuple(line for line in lines[start + 1 : end] if line)


def prove_title_view_route(root: Path) -> None:
    """Fail closed if the zero-upload -> regional camera -> scroll route changes."""
    title = _routine_lines(root, TITLE_SOURCE, "TitleScreen_FinalizeInitialization", "TitleScreen_UnreferencedData")
    upload = (
        "lea (Gfx_TitleAndZLeoVRAMTransferParameters).l,a0",
        "moveq #0,d0",
        "moveq #0,d1",
        "move.w d0,(PrimaryCameraXPosition).w",
        "move.w d1,(PrimaryCameraYPosition).w",
        "jsr (Tilemap_TransferFullMapDirectToVRAM).l",
        "lea (Gfx_FrontendAlternateVRAMTransferParameters).l,a0",
        "move.w #$600,d0",
        "move.w #0,d1",
        "move.w d0,(SecondaryCameraXPos).w",
        "move.w d1,(SecondaryCameraYPos).w",
        "jsr (Tilemap_TransferFullMapDirectToVRAM).l",
        "if BuildProfileEU",
        "move.w #$FFF0,(PrimaryCameraYPosition).w",
        "endif",
    )
    text = "\n".join(title)
    block = "\n".join(upload)
    scroll_call = "jsr (Scroll_PreparePlaneBuffersAndRegisterShadows).l"
    # Unary writes such as CLR have no preceding comma. All camera references
    # in this bounded initializer must be the three reviewed assignments.
    camera_writes = tuple(
        line for line in title if "(PrimaryCameraYPosition).w" in line or "(SecondaryCameraYPos).w" in line
    )
    if (
        block not in text
        or title.count(scroll_call) != 1
        or text.index(scroll_call) < text.index(block) + len(block)
        or camera_writes != (upload[4], upload[10], upload[13])
    ):
        raise ValueError("title source view differs from zero upload then EU-only camera -16")
    scroll = "\n".join(
        _routine_lines(
            root, SCROLL_SOURCE, "Scroll_PreparePlaneBuffersAndRegisterShadows", "Scroll_WriteHorizontalPlaneBuffer"
        )
    )
    primary = (
        "move.w (PrimaryCameraYPosition).w,d0",
        "neg.w d0",
        "add.w (PlaneAShakeOffset).w,d0",
        "bsr.w Scroll_WriteVerticalPlaneBuffer",
    )
    secondary = (
        "move.w (SecondaryCameraYPos).w,d0",
        "neg.w d0",
        "add.w (PlaneBShakeOffset).w,d0",
        "bra.w Scroll_WriteVerticalPlaneBuffer",
    )
    vertical = _routine_lines(
        root, SCROLL_SOURCE, "Scroll_WriteVerticalPlaneBuffer", "Scroll_FillHorizontalPlaneBuffer"
    )
    writer = (
        "btst #3,d5",
        "bne.w Scroll_FillVerticalColumnEntries",
        "btst #5,d5",
        "bne.w Scroll_CopyVerticalColumnProfile",
        "btst #1,d5",
        "bne.s Scroll_VerticalPlaneWriteReturn",
        "move.w d0,(a0)",
        "Scroll_VerticalPlaneWriteReturn:",
        "rts",
    )
    if "\n".join(primary) not in scroll or "\n".join(secondary) not in scroll or vertical != writer:
        raise ValueError("title source vertical scroll no longer negates and writes the camera word")


def build_scene(root: Path, profile: str, record: dict[str, Any]) -> Scene:
    lookup_a_y, lookup_b_y = screen_view_y(record, profile)
    if record["id"] == "title_background":
        prove_title_view_route(root)
    data, bodies = labelled_blocks(root)
    lists = read_asset_lists(root, bodies)
    list_name = record["asset_list"]
    stop_label = record.get("asset_stop_label")
    if list_name not in lists and stop_label:
        if list_name not in bodies:
            raise ValueError("screen asset list is missing: %s" % list_name)
        if stop_label not in bodies:
            raise ValueError("screen asset stop label is missing: %s" % stop_label)
        stop_lines = tuple(line for line in bodies[stop_label] if line.strip() and not line.strip().startswith(";"))
        stop = DIRECTIVE.match(stop_lines[0]) if stop_lines else None
        if stop is None or stop.group("kind") != "dc.w":
            raise ValueError("screen asset stop label has no leading word: %s" % stop_label)
        stop_word = stop.group("body").split(",", 1)[0]
        commands = read_asset_list(list_name, (*bodies[list_name], " dc.w %s" % stop_word))
        if commands:
            lists[list_name] = tuple(commands)
    if list_name not in lists:
        raise ValueError("screen asset list is missing: %s" % list_name)
    ram, written = build_ram(root, [list_name], lists, data)
    ram = apply_postload_transforms(record, ram)
    vram, missing = build_vram(root, [list_name], lists, data)
    if missing:
        raise ValueError("screen has undecoded VRAM payloads: %r" % (missing,))
    descriptors = read_descriptors(root)

    def plane(name):
        if name is None:
            return None
        if name not in descriptors:
            raise ValueError("screen descriptor is missing: %s" % name)
        return Tilemap(record["id"], (list_name,), ram, descriptors[name], tuple(written))

    plane_a = plane(record.get("plane_a"))
    plane_b = plane(record.get("plane_b"))
    if plane_b is not None:
        plane_b = replace(plane_b, y_offset=lookup_b_y - lookup_a_y)
    palette_name, colours = palette(root, record)
    backdrop = colours[16]
    return Scene(
        -1,
        plane_a,
        plane_b,
        vram,
        colours,
        palette_name,
        None,
        (),
        backdrop,
        (record.get("plane_a") or "constant fill", record.get("plane_b") or "constant fill"),
        0,
        record["camera_a_x"],
        record["camera_b_x"],
        0,
    )


def render(
    root: Path,
    profile: str,
    identifier: str,
    config_root: Path | None = None,
    with_scene: bool = False,
) -> list[list[tuple[int, int, int]]] | tuple:
    from authoring.stage_tilemap_model import parsed_read_phase

    with parsed_read_phase(root):
        return _render(root, profile, identifier, config_root, with_scene)


def _render(
    root: Path,
    profile: str,
    identifier: str,
    config_root: Path | None = None,
    with_scene: bool = False,
) -> list[list[tuple[int, int, int]]] | tuple:
    config = load_config(config_root or root)
    record = screen_record(config, identifier)
    built = build_scene(root, profile, record)
    image = draw(
        built,
        record["camera_a_x"],
        screen_view_y(record, profile)[0],
        record["width"],
        record["height"],
    )
    return (image, built, record) if with_scene else image


def image_sha256(image: list[list[tuple[int, int, int]]]) -> str:
    digest = hashlib.sha256()
    for row in image:
        for pixel in row:
            digest.update(bytes(pixel))
    return digest.hexdigest()


def survey(root: Path, profile: str) -> dict[str, Any]:
    from authoring.stage_tilemap_model import parsed_read_phase

    with parsed_read_phase(root):
        return _survey(root, profile)


def _survey(root: Path, profile: str) -> dict[str, Any]:
    config = load_config(root)
    rendered = []
    for record in config["supported"]:
        image = render(root, profile, record["id"])
        rendered.append(
            {
                "id": record["id"],
                "width": len(image[0]) if image else 0,
                "height": len(image),
                "colours": len({pixel for row in image for pixel in row}),
                "sha256": image_sha256(image),
            }
        )
    return {
        "profile": profile,
        "supported": rendered,
        "unsupported": len(config["unsupported"]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "render"))
    parser.add_argument("--root", default=".")
    parser.add_argument("--profile", choices=PROFILES, default="jp")
    parser.add_argument("--screen", default="title_background")
    parser.add_argument("--output")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    try:
        if args.command == "check":
            report = survey(root, args.profile)
            for record in report["supported"]:
                if record["colours"] < 2:
                    raise ValueError("%s rendered as one colour" % record["id"])
            print(
                "[OK] %s Screen Studio model: %d static compositions; "
                "%d explicit unsupported screens" % (args.profile, len(report["supported"]), report["unsupported"])
            )
        else:
            if not args.output:
                raise ValueError("render requires --output")
            image = render(root, args.profile, args.screen)
            write_png(Path(args.output), image)
            print("[OK] rendered %s to %s" % (args.screen, args.output))
        return 0
    except (OSError, ValueError) as error:
        print("[ERROR] %s" % error, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
