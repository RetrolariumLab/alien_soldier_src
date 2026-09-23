from __future__ import annotations

import json
import struct
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from runtime_state import Genstate, M68K_RAM  # noqa: E402
from validate_runtime_scenarios import number, ram_symbols  # noqa: E402


class RuntimeContractTests(unittest.TestCase):
    def test_named_scenarios_resolve_ram_symbols(self) -> None:
        config = json.loads((ROOT / "config/runtime_scenarios.json").read_text(encoding="utf-8"))
        symbols = ram_symbols(ROOT / "src/ram_addrs.inc")
        for scenario in config["scenarios"]:
            self.assertTrue(scenario["expectations"], scenario["id"])
            for expectation in scenario["expectations"]:
                self.assertIn(expectation["symbol"], symbols)
                self.assertEqual(
                    number(expectation["address"]),
                    (symbols[expectation["symbol"]] + number(expectation.get("offset", 0)))
                    & 0xFFFFFF,
                )

    def test_every_scenario_names_a_pinned_movie(self) -> None:
        config = json.loads((ROOT / "config/runtime_scenarios.json").read_text(encoding="utf-8"))
        for movie_id, movie in config["movies"].items():
            self.assertTrue((ROOT / movie["path"]).is_file(), movie_id)
            self.assertRegex(movie["sha256"], r"^[0-9a-f]{64}$")
        declared = set(config["movies"])
        used = {scenario["movie"] for scenario in config["scenarios"]}
        self.assertEqual(set(), used - declared)
        self.assertEqual(set(), declared - used)

    def test_genstate_reader_parses_header_sections_and_word_order(self) -> None:
        ram = bytearray(65536)
        ram[0:2] = b"\x34\x12"
        header = b"GENSTATE" + struct.pack("<IIQI", 1, 42, 0, 0x55555558) + bytes(36)
        table = struct.pack("<IIII", M68K_RAM, 96, len(ram), 0) + bytes(16)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.genstate"
            path.write_bytes(header + table + ram)
            state = Genstate.read(path)
        self.assertEqual(42, state.frame)
        self.assertEqual(0x55555558, state.rom_checksum)
        self.assertEqual(0x1234, state.m68k_u16(0xFF0000))

    def test_wrong_runtime_value_is_rejected(self) -> None:
        ram = bytearray(65536)
        header = b"GENSTATE" + struct.pack("<IIQI", 1, 1, 0, 0x55555558) + bytes(36)
        table = struct.pack("<IIII", M68K_RAM, 96, len(ram), 0) + bytes(16)
        config = {
            "rom_checksum": "0x55555558",
            "scenarios": [
                {
                    "id": "bad",
                    "frame": 1,
                    "expectations": [
                        {"symbol": "Mode", "address": "0xFF0000", "type": "u16", "equals": "1"},
                        {"symbol": "Mode", "address": "0xFF0000", "type": "u16", "equals": "1"},
                    ],
                }
            ],
        }
        with tempfile.TemporaryDirectory() as directory:
            capture = Path(directory) / "bad"
            capture.mkdir()
            (capture / "000001.genstate").write_bytes(header + table + ram)
            errors = __import__("validate_runtime_scenarios").validate(
                config, Path(directory), {"Mode": 0xFF0000}
            )
        self.assertEqual(2, sum("expected 0x1" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
