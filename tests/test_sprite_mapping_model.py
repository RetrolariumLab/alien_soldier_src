from __future__ import annotations

import json
import struct
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.sprite_mapping_model import (  # noqa: E402
    DYNAMIC_ENTRY_BYTES,
    LAST_PIECE,
    STATIC_ENTRY_BYTES,
    SpritePiece,
    art_payloads,
    compose_image,
    mapping_tiles,
    read_blocks,
    read_dynamic,
    read_static,
    round_trip_errors,
    survey,
)
from authoring.tile_graphics import GRAPHICS_CONFIG  # noqa: E402


def static_piece(attributes, size=0x00, link=0x00, y=0, x=0):
    return struct.pack(">HBBbb", attributes, size, link, y, x)


class PieceFormatTests(unittest.TestCase):
    def test_a_static_piece_is_six_bytes_in_the_order_the_renderer_reads(self) -> None:
        data = static_piece(0x8806, size=0x0E, link=0x42, y=-16, x=13)
        self.assertEqual(STATIC_ENTRY_BYTES, len(data))
        (mapping,) = read_static(data, "fixture")
        (piece,) = mapping.pieces
        self.assertEqual(0x006, piece.tile)
        self.assertTrue(piece.hflip_relative)
        self.assertFalse(piece.vflip_relative)
        self.assertEqual(-16, piece.y)
        self.assertEqual(13, piece.x)
        self.assertEqual(data, piece.encode())

    def test_the_size_byte_is_an_oam_size_field(self) -> None:
        """Bits 2-3 one less than the width, bits 0-1 one less than the height."""
        self.assertEqual((4, 3), (SpritePiece(0, 0x0E, 0, 0, 0).tiles_wide, SpritePiece(0, 0x0E, 0, 0, 0).tiles_high))
        self.assertEqual((1, 1), (SpritePiece(0, 0x00, 0, 0, 0).tiles_wide, SpritePiece(0, 0x00, 0, 0, 0).tiles_high))
        self.assertEqual((4, 4), (SpritePiece(0, 0x0F, 0, 0, 0).tiles_wide, SpritePiece(0, 0x0F, 0, 0, 0).tiles_high))
        self.assertEqual(12, SpritePiece(0, 0x0E, 0, 0, 0).tile_count)
        self.assertEqual((32, 24), (SpritePiece(0, 0x0E, 0, 0, 0).width, SpritePiece(0, 0x0E, 0, 0, 0).height))

    def test_bit_fifteen_ends_the_mapping_rather_than_setting_priority(self) -> None:
        data = static_piece(0x0001) + static_piece(0x0002) + static_piece(0x8003) + static_piece(0x8004)
        first, second = read_static(data, "fixture")
        self.assertEqual([0x001, 0x002, 0x003], [p.tile for p in first.pieces])
        self.assertEqual([0x004], [p.tile for p in second.pieces])
        self.assertEqual(0, first.offset)
        self.assertEqual(3 * STATIC_ENTRY_BYTES, second.offset)
        self.assertTrue(first.pieces[-1].last)
        self.assertFalse(first.pieces[0].last)

    def test_a_run_that_never_terminates_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            read_static(static_piece(0x0001), "unterminated")
        with self.assertRaises(ValueError):
            read_static(b"\x00" * (STATIC_ENTRY_BYTES + 1), "ragged")

    def test_a_dynamic_piece_carries_its_size_above_its_art_pointer(self) -> None:
        tokens = [("dc.w", "$8800"), ("dc.l", "ArtPiece+$E000000"), ("dc.w", "$F00D")]
        (mapping,) = read_dynamic(tokens, "fixture")
        (piece,) = mapping.pieces
        self.assertEqual(DYNAMIC_ENTRY_BYTES, 8)
        self.assertEqual("ArtPiece", piece.art)
        self.assertEqual(0x0E, piece.size)
        self.assertEqual(0, piece.art_addend)
        self.assertEqual(-16, piece.y)
        self.assertEqual(13, piece.x)
        self.assertTrue(piece.last)
        self.assertTrue(piece.dynamic)
        with self.assertRaises(ValueError):
            piece.encode()

    def test_a_dynamic_piece_without_an_art_symbol_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            read_dynamic([("dc.w", "$8800"), ("dc.l", "$1234"), ("dc.w", "0")], "bad")
        with self.assertRaises(ValueError):
            read_dynamic([("dc.w", "$8800"), ("dc.w", "0"), ("dc.w", "0")], "order")

    def test_bounds_cover_every_piece(self) -> None:
        data = static_piece(0x0000, size=0x00, y=0, x=0) + static_piece(0x8001, size=0x0F, y=-8, x=16)
        (mapping,) = read_static(data, "fixture")
        self.assertEqual((0, -8, 48, 32), mapping.bounds())


class CartridgeMappingTests(unittest.TestCase):
    """Read the real source, not a fixture that agrees with the code."""

    def test_every_static_mapping_re_encodes_to_the_tree(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT))

    def test_the_counts_match_what_config_declares(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        declared = config["sprite_mappings"]
        found = survey(ROOT)
        for field in ("blocks", "mappings", "pieces", "static_mappings", "dynamic_mappings", "payload_blocks"):
            self.assertEqual(declared[field], found[field], field)
        self.assertTrue(declared["format_why"].strip())

    def test_what_is_left_out_is_named_with_a_reason(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        _, skipped = read_blocks(ROOT)
        self.assertEqual(config["sprite_mappings"]["excluded"], skipped)
        for reason in skipped.values():
            self.assertTrue(reason.strip())
        # The plural spelling is the tell: ...SpriteFrames are tables and
        # scripts, ...SpriteFrameNN are mappings.
        self.assertIn("Pickup_SpriteMappings", skipped)
        self.assertIn("Terrain_StampObjectSpriteMapping", skipped)

    def test_every_dynamic_piece_lines_up_with_the_art_it_points_at(self) -> None:
        """Two numbers from two places: the tile field and the DMA length word."""
        payloads = art_payloads(ROOT)
        blocks, _ = read_blocks(ROOT)
        checked = 0
        for block in blocks:
            for mapping in block.mappings:
                if not mapping.dynamic:
                    continue
                tiles = mapping_tiles(ROOT, mapping, payloads)
                self.assertEqual(sum(piece.tile_count for piece in mapping.pieces), len(tiles), mapping.label)
                checked += 1
        self.assertEqual(survey(ROOT)["dynamic_mappings"], checked)

    def test_a_static_mapping_cannot_be_drawn_on_its_own(self) -> None:
        blocks, _ = read_blocks(ROOT)
        static = next(mapping for block in blocks for mapping in block.mappings if not mapping.dynamic)
        with self.assertRaises(ValueError):
            mapping_tiles(ROOT, static)

    def test_a_known_mapping_composes_to_the_size_its_pieces_imply(self) -> None:
        blocks, _ = read_blocks(ROOT)
        mapping = next(
            mapping
            for block in blocks
            if block.name == "Player_FallingSecondarySpriteMapping"
            for mapping in block.mappings
        )
        self.assertEqual([0x000, 0x008, 0x00E], [piece.tile for piece in mapping.pieces])
        left, top, width, height = mapping.bounds()
        palette = [(index, index, index) for index in range(64)]
        image = compose_image(mapping, mapping_tiles(ROOT, mapping), palette, 0)
        self.assertEqual(height, len(image))
        self.assertEqual(width, len(image[0]))

    def test_the_last_piece_of_every_mapping_is_the_only_terminator(self) -> None:
        blocks, _ = read_blocks(ROOT)
        for block in blocks:
            for mapping in block.mappings:
                flags = [bool(piece.attributes & LAST_PIECE) for piece in mapping.pieces]
                self.assertEqual([False] * (len(flags) - 1) + [True], flags, mapping.label)


if __name__ == "__main__":
    unittest.main()
