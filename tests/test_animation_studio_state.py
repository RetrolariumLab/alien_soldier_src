from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from authoring import animation_studio_model  # noqa: E402
from authoring.animation_studio_state import AnimationWorkspace  # noqa: E402
from tests.test_animation_pointer_domains import fixture as pointer_fixture  # noqa: E402
import verify_symbols  # noqa: E402


def state_fixture(root: Path) -> None:
    """Small physical inputs; real readers/ROM/ledger, never native evidence.

    The state contract keeps 112 parsed script choices, not 112 copies of the
    game's full source tree. Actual canonical 112-script/670-frame census and
    round trips remain in test_animation_studio_model, unchanged.
    """
    addresses = pointer_fixture(root)
    source = root / "src/data/animations.s"
    # The unchanged test selects the first alternate name: keep that alternate
    # static. This mapping's dc.l art pointer still proves its dynamic shape.
    body = source.read_text(encoding="utf-8").replace("DynamicSpriteMapping", "ThirdSpriteMapping")
    for profile in ("jp", "eu"):
        addresses[profile]["ThirdSpriteMapping"] = addresses[profile].pop("DynamicSpriteMapping")
    for index in range(109):
        name = "FixtureAnimation%03d" % index
        body += "%s: dc.w FirstSpriteMapping-*, 1\n" % name + " dc.w %s-*, 0\n" % name
        addresses["jp"][name] = 0x1000 + index * 8
        addresses["eu"][name] = 0x2000 + index * 8
    source.write_text(body, encoding="utf-8")
    document = animation_studio_model.export_document(root, "jp")
    profiles_path = root / "config/rom_profiles.json"
    profiles = json.loads(profiles_path.read_text(encoding="utf-8"))
    identities = {}
    for record in profiles["profiles"]:
        profile = record["id"]
        selected = addresses[profile]
        reference = record["reference_rom"]
        rom = root / reference["filename"]
        image = bytearray(rom.read_bytes())
        for script in document["scripts"]:
            origin = selected[script["name"]]
            for frame in script["frames"]:
                at = origin + frame["index"] * 4
                delta = selected[frame["target"]] - at
                image[at : at + 4] = (delta & 0xFFFF).to_bytes(2, "big") + frame["duration"].to_bytes(2, "big")
        rom.write_bytes(image)
        reference["sha256"] = hashlib.sha256(image).hexdigest()
        identities[profile] = {key: reference[key] for key in ("size", "sha256")}
    audit = [
        {
            "current_name": name,
            "address": "0x%06X" % address,
            "previous_name": "old_" + name,
            "legacy_name": "legacy_" + name,
        }
        for name, address in sorted(addresses["jp"].items())
    ]
    rows = [
        {
            "current_name": name,
            "jp_address": "0x%06X" % address,
            "eu_address": "0x%06X" % addresses["eu"][name],
            "status": "assembled",
        }
        for name, address in sorted(addresses["jp"].items())
    ]
    ledger_path = root / "config/name_addresses_eu.json"
    ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
    ledger.update(
        origin_identity_sha256=verify_symbols.origin_identity(audit),
        original_roms=identities,
        record_count=len(audit),
        records=rows,
        records_sha256=verify_symbols.canonical_sha256(rows),
    )
    for profile, identity in identities.items():
        ledger["generation"]["profiles"][profile].update(
            build_rom_sha256=identity["sha256"], original_rom_sha256=identity["sha256"]
        )
    for path, value in (
        (profiles_path, profiles),
        (root / "config/name_audit.json", {"records": audit}),
        (ledger_path, ledger),
    ):
        path.write_text(json.dumps(value), encoding="utf-8")


class AnimationWorkspaceTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory(prefix="animation-state-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        state_fixture(self.root)
        self.document = animation_studio_model.export_document(self.root, "jp")
        self.fixture_bytes = sum(path.stat().st_size for path in self.root.rglob("*") if path.is_file())
        self.state = AnimationWorkspace(self.document)

    def test_script_and_frame_navigation_are_bounded(self) -> None:
        multi = next(index for index, record in enumerate(self.state.scripts) if len(record["frames"]) > 1)
        self.state.select_script(multi)
        self.state.select_frame(1)
        self.state.select_script(0)
        self.assertEqual(0, self.state.frame_index)
        with self.assertRaisesRegex(ValueError, "script index"):
            self.state.select_script(len(self.state.scripts))

    def test_normal_frame_uses_only_proved_mapping_targets(self) -> None:
        index = next(index for index, record in enumerate(self.state.scripts) if not record["frames"][0]["jump"])
        self.state.select_script(index)
        target = next(item for item in self.state.target_options if item != self.state.frame["target"])
        self.state.set_frame(target, max(1, self.state.frame["duration"]))
        self.assertEqual(target, self.state.frame["target"])
        self.assertTrue(self.state.dirty)
        animation_studio_model.validate_document(self.document, self.root, "jp")
        with self.assertRaisesRegex(ValueError, "not valid"):
            self.state.set_frame("InventedMapping", 1)

    def test_jump_role_cannot_be_changed_by_duration(self) -> None:
        script_index, frame_index = next(
            (script_index, frame["index"])
            for script_index, record in enumerate(self.state.scripts)
            for frame in record["frames"]
            if frame["jump"]
        )
        self.state.select_script(script_index)
        self.state.select_frame(frame_index)
        self.assertEqual(0, self.state.frame["duration"])
        self.assertEqual(112, len(self.state.target_options))
        with self.assertRaisesRegex(ValueError, "source-owned"):
            self.state.set_frame(self.state.frame["target"], 1)


if __name__ == "__main__":
    unittest.main()
