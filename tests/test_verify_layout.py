from __future__ import annotations

import json
import hashlib
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import verify_layout  # noqa: E402


class VerifyLayoutTests(unittest.TestCase):
    def test_assembled_z80_binding_retains_the_asset_census_and_hash_check(self):
        from build_z80 import ENTRY, OUTPUT
        layout = {"dma_alignment": {"block_size": "0x20000", "transferred_regions": ["artunc"], "maximum_crossings": 0}}
        expected = b"\xf3\xf3\xf3"
        manifest = {"assets": [{"name": "z80_data", "path": "sound/z80_data.bin",
                                "region": "sound", "size": len(expected),
                                "sha1": hashlib.sha1(expected).hexdigest()}]}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "assets/manifest.json"
            path.parent.mkdir()
            path.write_text(json.dumps(manifest))
            source, output = root / ENTRY, root / OUTPUT
            source.parent.mkdir(parents=True)
            source.write_text("cpu z80\n")
            output.parent.mkdir(parents=True)
            for body, extra, accepted in ((expected, [], True), (b"\0\0\0", [], False),
                    (expected, ['(1) 2/ 83E70 : binclude "data/sound/z80_data.bin"'], False)):
                output.write_bytes(body)
                errors = []
                lines = ['(1) 1/ 83E70 : binclude "build/z80/driver.bin"', *extra]
                verify_layout.check_dma_alignment(layout, lines, path, errors)
                self.assertEqual(accepted, not errors, errors)

    def test_numbers_accept_manifest_forms(self) -> None:
        self.assertEqual(0x82324, verify_layout.number("0x082324"))
        self.assertEqual(2097152, verify_layout.number(2097152))

    def test_listing_parsers(self) -> None:
        lines = [
            '      13/       0 : include "src/system/example.s"',
            '(1)    7/     200 :                     Reset: rts',
        ]
        self.assertEqual([(0, "src/system/example.s")], verify_layout.listing_includes(lines))
        self.assertEqual({"Reset": 0x200}, verify_layout.listing_symbols(lines))

    def test_payload_parser_ignores_inactive_profile_alternatives(self) -> None:
        lines = [
            '(1)    1/    5A36 :                     binclude "data/profiles/eu/story.bin"',
            '(1)    2/    5A36 :                     binclude "data/other/story.bin"',
        ]
        self.assertEqual(
            {"data/other/story.bin": 0x5A36},
            verify_layout.listing_payloads(lines, {"data/other/story.bin"}),
        )


    def test_dma_boundary_crossing_is_rejected(self) -> None:
        layout = {
            "dma_alignment": {
                "block_size": "0x20000",
                "transferred_regions": ["artunc"],
                "maximum_crossings": 0,
            }
        }
        manifest = {"assets": [
            {"name": "inside", "path": "artunc/inside.bin", "region": "artunc", "size": 0x100},
            {"name": "straddles", "path": "artunc/straddles.bin", "region": "artunc", "size": 0x100},
            {"name": "compressed", "path": "artcomp/packed.bin", "region": "artcomp", "size": 0x100},
        ]}
        lines = [
            '(1)    1/   1FFF00 :                     binclude "data/artcomp/packed.bin"',
            '(1)    2/    10000 :                     binclude "data/artunc/inside.bin"',
            '(1)    3/    1FFF80 :                     binclude "data/artunc/straddles.bin"',
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "manifest.json"
            path.write_text(json.dumps(manifest), encoding="utf-8")
            errors: list[str] = []
            checked = verify_layout.check_dma_alignment(layout, lines, path, errors)
        self.assertEqual(2, checked)
        self.assertEqual(1, sum("straddles" in error for error in errors))
        self.assertEqual(0, sum("compressed" in error for error in errors))
        self.assertEqual(0, sum("inside" in error for error in errors))

    def test_a_layout_without_the_dma_rule_is_rejected(self) -> None:
        errors: list[str] = []
        verify_layout.check_dma_alignment({}, [], Path("nowhere.json"), errors)
        self.assertEqual(["ROM layout declares no DMA alignment rule"], errors)


if __name__ == "__main__":
    unittest.main()
