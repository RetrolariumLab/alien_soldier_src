from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import derive_profile_assets  # noqa: E402


class DeriveProfileAssetsTests(unittest.TestCase):
    def test_unique_payload_moves_and_shared_tail_stays_fixed(self) -> None:
        base = b"HEADalpha--TAILshared"
        target = b"PREFIXalphaTAILshared"
        manifest = {
            "assets": [
                {
                    "name": "moving",
                    "path": "other/moving.bin",
                    "region": "other",
                    "address": "0x4",
                    "end": "0x9",
                },
                {
                    "name": "shared",
                    "path": "other/shared.bin",
                    "region": "other",
                    "address": "0xF",
                    "end": "0x15",
                },
            ]
        }
        assets = derive_profile_assets.derive_assets(
            manifest, base, target, {}, shared_start=0xF
        )
        self.assertEqual("0x6", assets[0]["address"])
        self.assertEqual("0xF", assets[1]["address"])

    def test_changed_and_ambiguous_payloads_require_overrides(self) -> None:
        manifest = {
            "assets": [
                {
                    "name": "text",
                    "path": "other/text.bin",
                    "region": "other",
                    "address": "0x0",
                    "end": "0x2",
                }
            ]
        }
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            derive_profile_assets.derive_assets(
                manifest, b"AA", b"AAAA", {}, shared_start=99
            )
        override = {
            "text": {
                "address": "0x1",
                "end": "0x3",
                "path": "profiles/eu/other/text.bin",
                "region": "profiles/eu/other",
                "reason": "fixture",
            }
        }
        assets = derive_profile_assets.derive_assets(
            manifest, b"AA", b"ABBA", override, shared_start=99
        )
        self.assertEqual("profiles/eu/other/text.bin", assets[0]["path"])
        self.assertEqual("0x1", assets[0]["address"])
        self.assertEqual(2, assets[0]["size"])

    def test_unused_override_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "unused asset overrides"):
            derive_profile_assets.derive_assets(
                {"assets": []}, b"", b"", {"missing": {}}, shared_start=0
            )


if __name__ == "__main__":
    unittest.main()
