from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import graphics_studio, mapping_studio_model  # noqa: E402
from authoring.mapping_studio_state import (  # noqa: E402
    LAST_PIECE,
    MappingWorkspace,
    piece_dimensions,
)


class MappingWorkspaceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.document = mapping_studio_model.export_document(ROOT, "jp")
        self.state = MappingWorkspace(self.document)

    def test_all_mappings_are_navigable_and_piece_selection_resets(self) -> None:
        self.assertEqual(1169, len(self.state.entries))
        multi = next(index for index, (_block, mapping) in enumerate(self.state.entries) if len(mapping["pieces"]) > 1)
        self.state.select_mapping(multi)
        self.state.select_piece(1)
        self.state.select_mapping(0)
        self.assertEqual(0, self.state.piece_index)
        with self.assertRaisesRegex(ValueError, "mapping index"):
            self.state.select_mapping(len(self.state.entries))

    def test_static_piece_fields_are_edited_with_encoded_bounds(self) -> None:
        static = next(index for index, (_block, mapping) in enumerate(self.state.entries) if not mapping["dynamic"])
        self.state.select_mapping(static)
        piece = self.state.piece
        x = piece["x"] - 1 if piece["x"] > -128 else piece["x"] + 1
        self.state.set_piece(
            x=x,
            y=piece["y"],
            attributes=piece["attributes"],
            size=piece["size"],
            link=piece["link"],
        )
        self.assertEqual(x, self.state.piece["x"])
        self.assertTrue(self.state.dirty)
        mapping_studio_model.validate_document(self.document, ROOT, "jp")
        with self.assertRaisesRegex(ValueError, "signed bytes"):
            self.state.set_piece(
                x=128,
                y=0,
                attributes=piece["attributes"],
                size=piece["size"],
                link=piece["link"],
            )

    def test_dynamic_art_shape_and_mapping_boundary_are_protected(self) -> None:
        dynamic = next(index for index, (_block, mapping) in enumerate(self.state.entries) if mapping["dynamic"])
        self.state.select_mapping(dynamic)
        piece = self.state.piece
        with self.assertRaisesRegex(ValueError, "art size"):
            self.state.set_piece(
                x=piece["x"],
                y=piece["y"],
                attributes=piece["attributes"],
                size=piece["size"] ^ 1,
                link=piece["link"],
            )
        with self.assertRaisesRegex(ValueError, "terminator"):
            self.state.set_piece(
                x=piece["x"],
                y=piece["y"],
                attributes=piece["attributes"] ^ LAST_PIECE,
                size=piece["size"],
                link=piece["link"],
            )

    def test_geometry_uses_only_the_low_oam_size_bits(self) -> None:
        self.assertEqual((32, 24), piece_dimensions({"size": 0xFE}))
        self.assertEqual((8, 8), piece_dimensions({"size": 0xF0}))
        self.assertEqual(len(self.state.pieces), len(self.state.geometry()))

    def test_workstation_accepts_explicit_hex_and_signed_decimal_fields(self) -> None:
        self.assertEqual(0x8E, graphics_studio.Window.parse_mapping_field("$8E"))
        self.assertEqual(0x8E, graphics_studio.Window.parse_mapping_field("0x8e"))
        self.assertEqual(-16, graphics_studio.Window.parse_mapping_field("-16"))


if __name__ == "__main__":
    unittest.main()
