from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import rom_profiles  # noqa: E402


class RomProfileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.path = ROOT / "config/rom_profiles.json"
        self.document = rom_profiles.load_profiles(self.path)

    def test_jp_remains_the_supported_default(self) -> None:
        self.assertEqual("jp", self.document["default_profile"])
        profile = rom_profiles.select_profile(self.path, "jp", require_supported=True)
        self.assertEqual("Alien Soldier (J) [!].bin", profile["reference_rom"]["filename"])
        self.assertEqual("assets/manifest.json", profile["asset_manifest"])
        self.assertEqual("asbuilt.bin", profile["output"])

    def test_eu_reference_is_supported_by_the_exact_profile(self) -> None:
        profile = rom_profiles.select_profile(self.path, "eu", require_supported=True)
        self.assertEqual("supported", profile["status"])
        self.assertEqual(
            "afd4642f78ee1ae3004d630b1228e54a6e51e5dc7a991e1c192d91a41f366f71",
            profile["reference_rom"]["sha256"],
        )
    def test_profiles_use_distinct_outputs_and_reference_inputs(self) -> None:
        profiles = list(self.document["profiles_by_id"].values())
        self.assertEqual(len(profiles), len({item["output"] for item in profiles}))
        self.assertEqual(
            len(profiles),
            len({item["reference_rom"]["filename"] for item in profiles}),
        )
        self.assertEqual(
            len(profiles),
            len({item["reference_rom"]["sha256"] for item in profiles}),
        )

    def test_shared_tail_and_asset_reuse_are_bounded(self) -> None:
        shared = self.document["shared_image_region"]
        self.assertEqual(0x05D2F2, int(shared["start"], 16))
        self.assertEqual(0x200000, int(shared["end"], 16))
        self.assertEqual(int(shared["end"], 16) - int(shared["start"], 16), shared["size"])
        reuse = self.document["asset_reuse"]
        self.assertEqual(
            reuse["total_jp_assets"],
            reuse["shared_exact_assets"] + reuse["eu_specific_assets"],
        )

    def test_unknown_and_duplicate_profiles_are_rejected(self) -> None:
        with self.assertRaisesRegex(rom_profiles.ProfileError, "unknown ROM profile"):
            rom_profiles.select_profile(self.path, "usa")
        broken = json.loads(self.path.read_text(encoding="utf-8"))
        broken["profiles"].append(broken["profiles"][0])
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "profiles.json"
            path.write_text(json.dumps(broken), encoding="utf-8")
            with self.assertRaisesRegex(rom_profiles.ProfileError, "duplicate profile"):
                rom_profiles.load_profiles(path)


if __name__ == "__main__":
    unittest.main()
