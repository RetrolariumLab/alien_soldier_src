from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.graphics_inventory import synchronized  # noqa: E402
from authoring.object_sprite_model import WEAPON_SELECTION_HANDLER  # noqa: E402


class GraphicsInventoryTests(unittest.TestCase):
    def test_drawn_count_excludes_rejected_carried_art_once_per_stage(self):
        levels = {
            "object_handlers": {"0000": WEAPON_SELECTION_HANDLER, "0004": "Other"},
            "stage_slots": [{"index": 0, "configuration": "A"}, {"index": 1, "configuration": "B"}],
            "configurations": [
                {"name": "A", "fields": {"spawn_list": "SpawnA"}},
                {"name": "B", "fields": {"spawn_list": "SpawnB"}},
            ],
            "spawn_lists": [
                {
                    "name": "SpawnA",
                    "entries": [
                        {"object_type": 0, "parameter": 0},
                        {"object_type": 0, "parameter": 0},
                        {"object_type": 4, "parameter": 0},
                    ],
                },
                {"name": "SpawnB", "entries": [{"object_type": 0, "parameter": 0}]},
            ],
        }
        read = {
            "source_index": ({}, {}),
            "visual_loaders": [("", "")] * 2,
            "configurations": [SimpleNamespace(sprite_priority=0)] * 2,
        }
        palettes = dict.fromkeys(("blocks", "commands", "full_palettes", "offset_lists"), 0)
        mappings = dict.fromkeys(
            (
                "blocks",
                "mappings",
                "pieces",
                "static_mappings",
                "dynamic_mappings",
                "payload_blocks",
                "blocks_holding_several",
            ),
            0,
        )
        mappings["skipped"] = []
        with (
            mock.patch("authoring.graphics_inventory.palette_survey", return_value=palettes),
            mock.patch("authoring.graphics_inventory.mapping_survey", return_value=mappings),
            mock.patch("authoring.level_studio_model.export_document", return_value=levels),
            mock.patch("authoring.level_studio_state.sprite_library", return_value={}),
            mock.patch("authoring.level_studio_state.resting_mapping", return_value=("Mapping", object())),
            mock.patch("authoring.level_studio_state.object_attribute", return_value=(0, "fixture")),
            mock.patch("authoring.object_sprite_model.read_animation_scripts", return_value={}),
            mock.patch("authoring.stage_renderer.read_once", return_value=read),
            mock.patch(
                "authoring.object_sprite_model.weapon_selection_carried_art",
                side_effect=lambda _root, stage: None if stage == 0 else b"art",
            ) as carried,
        ):
            result = synchronized({"palettes": {}, "sprite_mappings": {}, "object_sprites": {}}, ROOT)
        self.assertEqual(4, result["object_sprites"]["placements"])
        self.assertEqual(2, result["object_sprites"]["placements_drawn"])
        self.assertEqual([mock.call(ROOT, 0), mock.call(ROOT, 1)], carried.call_args_list)

    def test_tracked_inventory_is_derived_from_the_current_source(self) -> None:
        path = ROOT / "config/authoring/graphics.json"
        document = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(document, synchronized(document, ROOT))


if __name__ == "__main__":
    unittest.main()
