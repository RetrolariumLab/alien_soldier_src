#!/usr/bin/env python3
"""Index and render proved placed-object previews for Graphics Studio."""

from __future__ import annotations

import shutil
import sys
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.level_studio_state import (  # noqa: E402
    object_attribute,
    open_stage,
    placement_sprite,
    resting_mapping,
    sprite_library,
)


def configuration_slots(level_document: dict) -> dict[str, list[int]]:
    slots: dict[str, list[int]] = {}
    for slot in level_document["stage_slots"]:
        name = slot["configuration"]
        if name:
            slots.setdefault(name, []).append(slot["index"])
    return slots


def spawn_stages(level_document: dict) -> dict[str, list[int]]:
    slots = configuration_slots(level_document)
    stages: dict[str, list[int]] = {}
    for record in level_document["configurations"]:
        spawn = record["fields"]["spawn_list"]
        if isinstance(spawn, str):
            stages.setdefault(spawn, []).extend(slots.get(record["name"], []))
    return {name: sorted(set(indices)) for name, indices in stages.items()}


def resting_targets(animation_document: dict) -> dict[str, str]:
    targets = {}
    for script in animation_document["scripts"]:
        frame = next((item for item in script["frames"] if not item["jump"]), None)
        if frame is not None:
            targets[script["name"]] = frame["target"]
    return targets


def mapping_names(mapping_document: dict) -> set[str]:
    return {mapping["label"] for block in mapping_document["blocks"] for mapping in block["mappings"]}


def catalogue(
    level_document: dict,
    mapping_document: dict,
    animation_document: dict,
) -> list[dict]:
    """Return every fixed placement with its statically proved preview status."""
    handlers = {int(offset, 16): name for offset, name in level_document["object_handlers"].items()}
    stages = spawn_stages(level_document)
    mappings = mapping_names(mapping_document)
    animation_targets = resting_targets(animation_document)
    records = []
    for spawn in level_document["spawn_lists"]:
        stage_indices = stages.get(spawn["name"], [])
        for index, entry in enumerate(spawn["entries"]):
            handler = handlers.get(entry["object_type"] & ~3, "")
            # The exact handler-to-resting-symbol chain remains code-owned.
            # These fields are filled by render_preview from the staged tree;
            # the document inventories here only prove the available targets.
            records.append(
                {
                    "id": "%s:%d" % (spawn["name"], index),
                    "spawn_list": spawn["name"],
                    "placement_index": index,
                    "stage_indices": stage_indices,
                    "sample_stage": stage_indices[0] if stage_indices else None,
                    "handler": handler,
                    "object_type": entry["object_type"],
                    "known_mapping_count": len(mappings),
                    "known_animation_count": len(animation_targets),
                    "status": "previewable"
                    if handler and stage_indices
                    else ("no-stage-binding" if not stage_indices else "no-handler"),
                }
            )
    return records


def render_preview(root: Path, profile: str, record: dict):
    """Render one placement from an already staged content tree."""
    stage_index = record["sample_stage"]
    if stage_index is None:
        raise ValueError("gallery record has no stage binding")
    studio = open_stage(root, stage_index, profile=profile)
    index = record["placement_index"]
    if not 0 <= index < len(studio.placements):
        raise ValueError("gallery placement is outside its staged spawn list")
    placement = studio.placements[index]
    library = sprite_library(root)
    symbol, mapping = resting_mapping(library, placement.handler, placement.entry.parameter, stage_index)
    sprite = placement_sprite(studio, library, placement)
    if sprite is None:
        attribute, how = object_attribute(
            library,
            placement.handler,
            studio.scene.object_attribute,
            stage_attributes=studio.scene.object_attributes,
            priority=studio.scene.configuration.sprite_priority,
            parameter=placement.entry.parameter,
            stage_index=stage_index,
        )
        reason = "no proved resting mapping" if mapping is None else "no proved tile base"
        return {
            "pixels": None,
            "handler": placement.handler,
            "mapping_symbol": symbol,
            "attribute": attribute,
            "attribute_evidence": how,
            "reason": reason,
        }
    pixels, _left, _top = sprite
    attribute, how = object_attribute(
        library,
        placement.handler,
        studio.scene.object_attribute,
        stage_attributes=studio.scene.object_attributes,
        priority=studio.scene.configuration.sprite_priority,
        parameter=placement.entry.parameter,
        stage_index=stage_index,
    )
    return {
        "pixels": pixels,
        "handler": placement.handler,
        "mapping_symbol": symbol,
        "attribute": attribute,
        "attribute_evidence": how,
        "reason": "",
    }


def stage_preview(
    project: Path,
    profile: str,
    destination: Path,
    level_document: dict,
    tile_document: dict,
    compressed_document: dict,
    palette_document: dict,
    mapping_document: dict,
    animation_document: dict,
    record: dict,
):
    """Apply one complete workspace snapshot and render one selected object."""
    from authoring.animation_studio_model import apply_document as apply_animation
    from authoring.content_workspace import stage_tree
    from authoring.compressed_graphics_model import apply_document as apply_compressed
    from authoring.graphics_studio_model import apply_document as apply_tiles
    from authoring.level_studio_model import apply_document as apply_levels
    from authoring.mapping_studio_model import apply_document as apply_mappings
    from authoring.palette_studio_model import apply_document as apply_palettes
    from authoring.stage_renderer import forget
    from authoring.tile_graphics import GRAPHICS_CONFIG

    forget(destination)
    stage_tree(project, destination)
    # Scene reconstruction reads the explicit unsupported-plane inventory.
    # A content tree contains src/data only, so supply that required policy.
    graphics_config = destination / GRAPHICS_CONFIG
    graphics_config.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(project / GRAPHICS_CONFIG, graphics_config)
    apply_levels(level_document, destination, profile)
    apply_tiles(tile_document, destination, profile)
    apply_compressed(compressed_document, destination, profile)
    apply_palettes(palette_document, destination, profile)
    apply_mappings(mapping_document, destination, profile)
    apply_animation(animation_document, destination, profile, validation_root=project)
    return render_preview(destination, profile, record)


def survey(records: list[dict]) -> dict[str, int]:
    return {
        "placements": len(records),
        "previewable_candidates": sum(record["status"] == "previewable" for record in records),
        "without_stage": sum(record["status"] == "no-stage-binding" for record in records),
        "without_handler": sum(record["status"] == "no-handler" for record in records),
    }
