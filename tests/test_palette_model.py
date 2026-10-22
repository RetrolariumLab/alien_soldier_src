from __future__ import annotations

import json
import struct
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring.palette_model import (  # noqa: E402
    ACTIVE_BUFFER,
    DESTINATION_BIAS,
    PALETTE_COLOURS,
    PRELUDE_COMMAND,
    SHADOW_BUFFER,
    PaletteCommand,
    apply_commands,
    command_index,
    named_sets,
    read_commands,
    read_source,
    resolve,
    round_trip_errors,
    survey,
)
from authoring.tile_graphics import GRAPHICS_CONFIG  # noqa: E402


class CommandFormatTests(unittest.TestCase):
    def test_a_command_is_two_header_bytes_and_that_many_words(self) -> None:
        data = bytes((0x62, 0x02)) + struct.pack(">3H", 0x0EEE, 0x00E0, 0x000E)
        (command,) = read_commands(data, "fixture")
        self.assertEqual(0x62, command.destination)
        self.assertEqual(3, command.count)
        self.assertEqual(8, command.size)
        self.assertEqual((0x0EEE, 0x00E0, 0x000E), command.colours)
        self.assertEqual(data, command.encode())

    def test_the_count_byte_is_one_less_than_the_colours(self) -> None:
        """dbf runs d7 + 1 times, so $3F is a full sixty-four."""
        full = bytes((0x00, 0x3F)) + bytes(2 * PALETTE_COLOURS)
        (command,) = read_commands(full, "fixture")
        self.assertEqual(PALETTE_COLOURS, command.count)
        self.assertEqual(0x82, command.size)
        self.assertTrue(command.full_palette)

    def test_the_destination_is_a_byte_offset_into_the_palette_buffer(self) -> None:
        # movea.w sign-extends dest - $1D00, and that is PaletteActiveBuffer.
        self.assertEqual(ACTIVE_BUFFER, 0xFFFF0000 | ((0 - DESTINATION_BIAS) & 0xFFFF))
        self.assertEqual(SHADOW_BUFFER, ACTIVE_BUFFER + 0x80)
        command = PaletteCommand("fixture", 0, 0x62, (0,))
        self.assertEqual(0x31, command.first_colour)
        self.assertEqual(3, command.line)
        self.assertEqual(ACTIVE_BUFFER + 0x62, command.active_address)

    def test_a_chain_that_does_not_fit_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            read_commands(bytes((0x00, 0x3F, 0x00)), "short")  # runs past
        with self.assertRaises(ValueError):
            read_commands(bytes((0x7F, 0x00, 0x00, 0x00)), "odd")  # odd destination
        with self.assertRaises(ValueError):
            read_commands(bytes((0x7E, 0x01)) + bytes(4), "over")  # leaves the buffer

    def test_later_commands_win_where_they_overlap(self) -> None:
        first = PaletteCommand("a", 0, 0x00, (0x0111, 0x0222))
        second = PaletteCommand("b", 0, 0x02, (0x0333,))
        buffer = apply_commands([first, second])
        self.assertEqual([0x0111, 0x0333], buffer[:2])
        self.assertEqual(PALETTE_COLOURS, len(buffer))


class CartridgePaletteTests(unittest.TestCase):
    """Read the real source, not a fixture that agrees with the code."""

    def test_every_block_in_the_palette_source_is_a_chain_of_commands(self) -> None:
        found = survey(ROOT)
        self.assertEqual({}, found["not_command_chains"])
        self.assertEqual(found["blocks"], found["command_blocks"])

    def test_every_command_re_encodes_and_every_offset_lands_on_one(self) -> None:
        self.assertEqual([], round_trip_errors(ROOT))

    def test_the_counts_match_what_config_declares(self) -> None:
        config = json.loads((ROOT / GRAPHICS_CONFIG).read_text(encoding="utf-8"))
        declared = config["palettes"]
        found = survey(ROOT)
        for field in ("blocks", "commands", "full_palettes", "offset_lists"):
            self.assertEqual(declared[field], found[field], field)
        self.assertTrue(declared["format_why"].strip())

    def test_a_full_palette_is_eighty_two_bytes(self) -> None:
        blocks, _ = read_source(ROOT)
        commands, _ = command_index(blocks)
        full = [command for command in commands.values() if command.full_palette]
        self.assertTrue(full)
        for command in full:
            self.assertEqual(0x82, command.size)
        # The offset lists step by exactly that much through the bank.
        self.assertIn(("FrontendPaletteCommands", 0x82), commands)

    def test_the_stage_ready_bank_is_five_six_byte_commands(self) -> None:
        blocks, _ = read_source(ROOT)
        commands, _ = command_index(blocks)
        bank = sorted(key[1] for key in commands if key[0] == "StageReadyPaletteCommand")
        self.assertEqual([0x00, 0x06, 0x0C, 0x12, 0x18], bank)

    def test_a_named_set_is_sixty_four_colours_with_the_prelude_played(self) -> None:
        blocks, lists = read_source(ROOT)
        commands, _ = command_index(blocks)
        prelude = commands[(PRELUDE_COMMAND, 0)]
        match = next(item for item in named_sets(ROOT) if item["name"] == "StageStartPaletteOffsetList")
        self.assertEqual(PALETTE_COLOURS, len(match["words"]))
        self.assertEqual(PALETTE_COLOURS, len(match["rgb"]))
        # Gfx_LoadMultiplePalettes plays CommonPaletteCommand before the list,
        # and nothing in this list writes over line two.
        self.assertEqual(
            list(prelude.colours), match["words"][prelude.first_colour : prelude.first_colour + prelude.count]
        )

    def test_an_offset_that_misses_a_command_boundary_is_refused(self) -> None:
        blocks, lists = read_source(ROOT)
        commands, _ = command_index(blocks)
        broken = lists[0].__class__(lists[0].name, 0, (("StageReadyPaletteCommand", 0x01),))
        with self.assertRaises(ValueError):
            resolve(broken, commands)

    def test_every_list_names_a_block_that_exists(self) -> None:
        blocks, lists = read_source(ROOT)
        self.assertTrue(lists)
        for offset_list in lists:
            self.assertTrue(offset_list.entries, offset_list.label)
            for symbol, _ in offset_list.entries:
                self.assertIn(symbol, blocks, offset_list.label)


if __name__ == "__main__":
    unittest.main()
