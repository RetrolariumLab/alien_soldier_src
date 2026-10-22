"""Display-free map state and screen-coordinate selection for Screen Studio."""

from __future__ import annotations

from dataclasses import dataclass, replace
from pathlib import Path

from authoring.lzss_codec import decompress
from authoring.map_reference_guard import periodic_reference_error, visible_reference_errors
from authoring.ram_map_workspace import MapHit, encode_values, merged_edit_streams, resolve_map_cell

from authoring.ram_map_state import Workspace
from authoring.screen_studio_model import apply_postload_transforms, screen_view_y
from authoring.stage_renderer import draw
from authoring.stage_tilemap_model import RAM_SIZE, labelled_blocks


@dataclass(frozen=True)
class ScreenMapHit:
    plane: str
    cell: MapHit
    screen_x: int
    screen_y: int
    screen_left: int
    screen_top: int
    pixel_size: int


def locate_screen_map_cell(scene, record, profile, document, screen_x, screen_y, plane_name, role):
    """Resolve a static-screen pixel against one explicitly selected plane."""
    if (
        type(screen_x) is not int
        or type(screen_y) is not int
        or not 0 <= screen_x < record["width"]
        or not 0 <= screen_y < record["height"]
    ):
        raise ValueError("point is outside the static-screen preview")
    if plane_name == "plane_a":
        plane = scene.tilemap
        camera_x = record["camera_a_x"]
    elif plane_name == "plane_b":
        plane = scene.plane_b
        camera_x = scene.parallax_x(record["camera_a_x"])
    else:
        raise ValueError("screen plane must be plane_a or plane_b")
    if plane is None:
        raise ValueError("selected screen plane is absent")
    camera_y = screen_view_y(record, profile)[0]
    world_x, world_y = camera_x + screen_x, camera_y + screen_y
    cell = resolve_map_cell(plane, document, world_x, world_y, role)
    size = {"patterns": 8, "chunks": 32, "coarse": 256}[role]
    left = world_x // size * size - camera_x
    top = (world_y + plane.y_offset) // size * size - plane.y_offset - camera_y
    return ScreenMapHit(plane_name, cell, screen_x, screen_y, left, top, size)


def read_ram_sources(root: Path, scene) -> dict[str, bytes]:
    """Cache decoded RAM writes from one fully staged static-screen tree."""
    plane = scene.tilemap or scene.plane_b
    if plane is None:
        raise ValueError("static screen has no RAM-backed plane")
    data, _bodies = labelled_blocks(root)
    lengths = {source: length for _list, source, _offset, length in plane.written}
    decoded = {}
    for source, length in lengths.items():
        raw = data.get(source)
        if not isinstance(raw, bytes):
            raise ValueError("staged RAM source is missing: %s" % source)
        body = decompress(raw)
        if len(body) != length:
            raise ValueError("staged RAM source changed length: %s" % source)
        decoded[source] = body
    return decoded


def replay_screen_maps(
    scene,
    record,
    profile,
    ram_sources,
    screen_document,
    screen_baseline,
    stage_document,
    stage_baseline,
    draw_image=True,
):
    """Rebuild RAM and a static image without restaging ROM source files.

    Caller validates both documents. Canonical map bytes are restored first,
    so reverting an edit really restores the scene even when the supplied
    cache came from a tree staged with an older edit. Changed peer and local
    streams then compose with the same shared-source conflict rule as build.
    """
    plane = scene.tilemap or scene.plane_b
    if plane is None:
        raise ValueError("static screen has no RAM-backed plane")
    loaded = {source for _list, source, _offset, _length in plane.written}
    sources = dict(ram_sources)
    canonical = {}
    for baseline in (stage_baseline, screen_baseline):
        for item in baseline["payloads"]:
            name = item["name"]
            if name not in loaded:
                continue
            plain = encode_values(item)
            if name in ram_sources and len(plain) != len(ram_sources[name]):
                raise ValueError("source-owned RAM-map length changed: %s" % name)
            if name in canonical and canonical[name] != plain:
                raise ValueError("source-owned RAM-map baselines disagree: %s" % name)
            canonical[name] = plain
    sources.update(canonical)
    edited = merged_edit_streams(
        (stage_document, stage_baseline), (screen_document, screen_baseline), only_names=loaded
    )
    sources.update({name: decompress(slot) for name, slot in edited.items()})
    ram = bytearray(RAM_SIZE)
    for _list, source, offset, length in plane.written:
        body = sources.get(source)
        if body is None or len(body) != length:
            raise ValueError("screen RAM transfer has no fixed-size body: %s" % source)
        ram[offset : offset + length] = body
    snapshot = apply_postload_transforms(record, ram)
    updated = replace(
        scene,
        tilemap=replace(scene.tilemap, ram=snapshot) if scene.tilemap else None,
        plane_b=replace(scene.plane_b, ram=snapshot) if scene.plane_b else None,
    )
    image = (
        draw(updated, record["camera_a_x"], screen_view_y(record, profile)[0], record["width"], record["height"])
        if draw_image
        else None
    )
    return image, updated


def canonical_map_contexts(root, profile):
    """Cache immutable canonical scenes and their RAM sources for brush edits."""
    from authoring.screen_studio_model import build_scene, load_config

    contexts = []
    for record in load_config(root)["supported"]:
        baseline = build_scene(root, profile, record)
        sources = read_ram_sources(root, baseline)
        contexts.append((record, baseline, sources))
    return tuple(contexts)


def validate_screen_map_references(
    root, profile, screen_document, screen_baseline, stage_document, stage_baseline, contexts=None
):
    """Check supported viewports and full periodic map reads without drawing."""
    if screen_document == screen_baseline and stage_document == stage_baseline:
        return
    changed_sources = set()
    for document, baseline in ((screen_document, screen_baseline), (stage_document, stage_baseline)):
        original = {item["name"]: item["values"] for item in baseline["payloads"]}
        changed_sources.update(
            item["name"] for item in document["payloads"] if item["values"] != original[item["name"]]
        )
    if not changed_sources:
        return
    if contexts is None:
        contexts = canonical_map_contexts(root, profile)
    for record, baseline, sources in contexts:
        if not any(
            source in changed_sources
            for plane in (baseline.tilemap, baseline.plane_b)
            if plane is not None
            for _list, source, _offset, _length in plane.written
        ):
            continue
        _image, candidate = replay_screen_maps(
            baseline,
            record,
            profile,
            sources,
            screen_document,
            screen_baseline,
            stage_document,
            stage_baseline,
            draw_image=False,
        )
        errors = visible_reference_errors(
            baseline, candidate, record, profile, viewport_y=screen_view_y(record, profile)[0]
        )
        if errors:
            raise ValueError("new undefined visible map reference: " + errors[0])
        error = periodic_reference_error(baseline, candidate, record["id"])
        if error is not None:
            raise ValueError("new undefined periodic screen map reference: " + error)
