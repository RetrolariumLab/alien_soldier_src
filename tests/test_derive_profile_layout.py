from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import derive_profile_layout  # noqa: E402


class DeriveProfileLayoutTests(unittest.TestCase):
    def test_listing_owns_module_landmark_and_gap_addresses(self) -> None:
        base = {
            "rom_image": {
                "size": 0x1000,
                "landmarks": [{"symbol": "Reset", "address": "0x000000"}],
                "gaps": [
                    {"start": "0x10", "end": "0x1F", "size": 0x10},
                    {"start": "0x30", "end": "0x3F", "size": 0x10},
                    {"start": "0x50", "end": "0x5F", "size": 0x10},
                ],
            },
            "modules": [
                {"file": "src/a.s", "start": "0x0", "end": "0x7"},
                {"file": "src/b.s", "start": "0x8", "end": "0xFFF"},
            ],
        }
        lines = [
            '      1/     100 : include "src/a.s"',
            '      2/     180 : include "src/b.s"',
            "(1)    1/     120 :                     Reset: rts",
            "(1)    2/      12 :                     Math_PackedBCDLookup_End:",
            "(1)    3/      32 :                     Sound_PCMBank9_End:",
            "(1)    4/      52 :                     Credits_SegaMappingData_End:",
        ]

        result = derive_profile_layout.derive_layout(base, lines, "fixture")

        self.assertEqual("fixture", result["profile"])
        self.assertEqual("0x000100", result["modules"][0]["start"])
        self.assertEqual("0x00017F", result["modules"][0]["end"])
        self.assertEqual("0x000120", result["rom_image"]["landmarks"][0]["address"])
        self.assertEqual("0x000012", result["rom_image"]["gaps"][0]["start"])
        self.assertEqual(14, result["rom_image"]["gaps"][0]["size"])

    def test_module_order_mismatch_is_rejected(self) -> None:
        base = {"rom_image": {"size": 16}, "modules": [{"file": "src/a.s"}]}
        lines = ['      1/       0 : include "src/b.s"']
        with self.assertRaisesRegex(ValueError, "module order"):
            derive_profile_layout.derive_layout(base, lines, "fixture")


if __name__ == "__main__":
    unittest.main()
