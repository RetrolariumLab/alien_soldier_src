#!/usr/bin/env python3
"""Synchronize machine-counted graphics format claims with the source tree."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


SCRIPT_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from authoring.palette_model import survey as palette_survey
from authoring.sprite_mapping_model import survey as mapping_survey


COUNT_FIELDS = (
    "blocks",
    "mappings",
    "pieces",
    "static_mappings",
    "dynamic_mappings",
    "payload_blocks",
    "blocks_holding_several",
)


def synchronized(document: dict, root: Path) -> dict:
    """Return the inventory with every derived claim replaced by observation."""
    result = json.loads(json.dumps(document))
    palettes = palette_survey(root)
    for field in ("blocks", "commands", "full_palettes", "offset_lists"):
        result["palettes"][field] = palettes[field]
    mappings = mapping_survey(root)
    for field in COUNT_FIELDS:
        result["sprite_mappings"][field] = mappings[field]
    result["sprite_mappings"]["excluded"] = mappings["skipped"]
    from authoring.level_studio_model import export_document
    from authoring.level_studio_state import (
        object_attribute,
        resting_mapping,
        sprite_library,
    )
    from authoring.object_gallery_model import spawn_stages
    from authoring.object_sprite_model import (
        WEAPON_SELECTION_HANDLER,
        expand_tile_commands,
        read_animation_scripts,
        weapon_selection_carried_art,
    )
    from authoring.stage_renderer import read_once

    scripts = read_animation_scripts(root)
    levels = export_document(root, "jp")
    handlers = {int(offset, 16): name for offset, name in levels["object_handlers"].items()}
    stages = spawn_stages(levels)
    library = sprite_library(root)
    read = read_once(root)
    lines, symbols = read["source_index"]
    stage_attributes = {}
    for stage_indices in stages.values():
        if not stage_indices:
            continue
        stage = stage_indices[0]
        if stage in stage_attributes:
            continue
        visual, _palette = read["visual_loaders"][stage]
        _commands, attributes = expand_tile_commands(read["data"], lines, symbols, visual) if visual else ([], {})
        stage_attributes[stage] = attributes
    placed = []
    for spawn in levels["spawn_lists"]:
        stage_indices = stages.get(spawn["name"], [])
        stage = stage_indices[0] if stage_indices else None
        attributes = stage_attributes.get(stage, {})
        configuration = read["configurations"][stage] if stage is not None else None
        priority = configuration.sprite_priority if configuration else 0
        default = (attributes.get(0, 0) | priority) & 0xFFFF
        for entry in spawn["entries"]:
            name = handlers.get(entry["object_type"] & ~3, "")
            placed.append((name, default, attributes, priority, entry["parameter"], stage))
    no_mapping = sorted(
        {
            name
            for name, _default, _attributes, _priority, _parameter, stage in placed
            if resting_mapping(library, name, _parameter, stage)[1] is None
        }
    )
    no_base = sorted(
        {
            name
            for name, default, attributes, priority, parameter, stage in placed
            if object_attribute(
                library,
                name,
                default,
                stage_attributes=attributes,
                priority=priority,
                parameter=parameter,
                stage_index=stage,
            )[0]
            is None
        }
    )
    objects = result["object_sprites"]
    objects["animation_scripts"] = len(scripts)
    objects["animation_frames"] = sum(len(frames) for frames in scripts.values())
    objects["placements"] = len(placed)
    carried_art = {}

    def has_required_art(name, stage):
        if name != WEAPON_SELECTION_HANDLER:
            return True
        if stage not in carried_art:
            carried_art[stage] = stage is not None and weapon_selection_carried_art(root, stage) is not None
        return carried_art[stage]

    objects["placements_drawn"] = sum(
        resting_mapping(library, name, parameter, stage)[1] is not None
        and object_attribute(
            library,
            name,
            default,
            stage_attributes=attributes,
            priority=priority,
            parameter=parameter,
            stage_index=stage,
        )[0]
        is not None
        and has_required_art(name, stage)
        for name, default, attributes, priority, parameter, stage in placed
    )
    objects["handlers_placed"] = len({name for name, *_rest in placed})
    objects["handlers_without_a_sprite"] = no_mapping
    objects["handlers_without_a_tile_base"] = no_base
    return result


def atomic_write(path: Path, document: dict) -> None:
    from authoring.atomic_output import atomic_write_json

    atomic_write_json(path, document, ensure_ascii=False)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--config", default="config/authoring/graphics.json")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    path = root / args.config
    document = json.loads(path.read_text(encoding="utf-8"))
    current = synchronized(document, root)
    if current != document:
        if not args.write:
            print(f"[ERROR] graphics inventory is stale: {args.config}", file=sys.stderr)
            return 1
        atomic_write(path, current)
        print(f"[OK] graphics inventory updated: {args.config}")
        return 0
    print(f"[OK] graphics inventory matches the source: {args.config}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
