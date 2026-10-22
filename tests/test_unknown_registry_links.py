"""Keep open name-evidence records linked to exact source definitions."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VISUAL_UNKNOWN_IDS = {
    "VIS-001": (
        (
            "0x0310E6",
            "EntityType390_ControllerMain",
            "src/enemies/entity_type_390_linked_chain.s",
        ),
    ),
    "VIS-002": (
        ("0x04079E", "Boss_SnakeMain", "src/bosses/snake.s"),
        ("0x040AF6", "Boss_SnakeSegmentMain", "src/bosses/snake.s"),
    ),
    "VIS-003": (
        ("0x040CEE", "EntityType1C0_InitDispatcher", "src/bosses/entity_type_1c0_core.s"),
        ("0x0418FC", "EntityType1C0_MainDispatcher", "src/bosses/entity_type_1c0_attacks.s"),
        ("0x042A10", "Boss_SunsetStingMain", "src/bosses/sunset_sting_main.s"),
        (
            "0x04309E",
            "Boss_SunsetStingRefillCounterAndOscillateState",
            "src/bosses/sunset_sting_main.s",
        ),
    ),
}
REVIEWED_VISUAL_ADDRESSES = {
    "0x04079E",
    "0x040AF6",
    "0x042A10",
}
UNKNOWN_EVIDENCE_IDS = {
    "CODE-001": ("0x040CEC", "Boss_SnakeUnreferencedReturn", "src/bosses/snake.s"),
    "DATA-001": (
        "0x040D2E",
        "EntityType1C0_EarlyFormPartMapping",
        "src/bosses/entity_type_1c0_core.s",
    ),
    "CODE-002": (
        "0x0586F2",
        "Boss_ArtemisPoseScriptUnreferencedReturn",
        "src/bosses/artemis_rendering.s",
    ),
    "CODE-003": (
        "0x058BA0",
        "Projectile_ArtemisEmitterUnreferencedReturn",
        "src/projectiles/artemis.s",
    ),
    "CODE-004": (
        "0x059BAA",
        "Boss_SylpheedPoseScriptUnreferencedReturn",
        "src/bosses/sylpheed_pose.s",
    ),
    "CODE-005": (
        "0x08277C",
        "Sound_PitchEnvelopeUnreferencedSkipReturn",
        "src/sound/driver_core.s",
    ),
    "DATA-002": (
        "0x011356",
        "Gfx_UnidentifiedVRAMTransferParameters",
        "src/rendering/boss_asset_sets.s",
    ),
}


def registry_section(registry: str, unknown_id: str) -> str:
    match = re.search(
        rf"(?ms)^### {re.escape(unknown_id)}\b(.*?)(?=^#{{2,3}} |\Z)",
        registry,
    )
    if match is None:
        raise AssertionError(f"missing registry section for {unknown_id}")
    return match.group(1)


class UnknownRegistryLinkTests(unittest.TestCase):
    def test_visual_registry_and_source_tags_link_in_both_directions(self) -> None:
        registry = (ROOT / "docs/unknowns.md").read_text(encoding="utf-8")
        headings = re.findall(r"(?m)^### (VIS-\d{3})\b", registry)
        self.assertEqual(set(VISUAL_UNKNOWN_IDS), set(headings))
        self.assertEqual(len(headings), len(set(headings)))

        referenced_tags: list[str] = []
        for path in (ROOT / "src").rglob("*.s"):
            source = path.read_text(encoding="utf-8")
            referenced_tags.extend(re.findall(r"(?m)^; (?:UNKNOWN|REVIEWED) (VIS-\d{3}):", source))
        self.assertEqual(set(VISUAL_UNKNOWN_IDS), set(referenced_tags))
        self.assertEqual(7, len(referenced_tags))

        audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        expected_addresses: set[str] = set()
        for unknown_id, members in VISUAL_UNKNOWN_IDS.items():
            section = registry_section(registry, unknown_id)
            self.assertIn("- **Status:**", section)
            self.assertIn("- **Confidence:**", section)
            self.assertIn("- **Experiment:**", section)
            for address, name, relative in members:
                with self.subTest(id=unknown_id, address=address):
                    expected_addresses.add(address)
                    self.assertEqual(name, audit[address]["current_name"])
                    reviewed = address in REVIEWED_VISUAL_ADDRESSES
                    self.assertEqual(
                        "runtime" if reviewed else "static",
                        audit[address]["evidence"],
                    )
                    self.assertIn(f"`{relative}`", section)
                    source = (ROOT / relative).read_text(encoding="utf-8")
                    self.assertRegex(
                        source,
                        rf"(?m)^; REVIEWED {unknown_id}:[^\n]*\n^{re.escape(name)}:",
                    )
        self.assertEqual(
            set(),
            {address for address, record in audit.items() if record.get("evidence") == "hypothesis"},
        )

    def test_unknown_evidence_records_have_bidirectional_links(self) -> None:
        registry = (ROOT / "docs/unknowns.md").read_text(encoding="utf-8")
        headings = re.findall(r"(?m)^### ((?:CODE|DATA)-\d{3})\b", registry)
        self.assertEqual(set(UNKNOWN_EVIDENCE_IDS), set(headings))
        self.assertEqual(len(headings), len(set(headings)))

        referenced_tags: list[str] = []
        for path in (ROOT / "src").rglob("*.s"):
            source = path.read_text(encoding="utf-8")
            referenced_tags.extend(re.findall(r"(?m)^; (?:UNKNOWN|REVIEWED) ((?:CODE|DATA)-\d{3}):", source))
        self.assertEqual(set(UNKNOWN_EVIDENCE_IDS), set(referenced_tags))
        self.assertEqual(7, len(referenced_tags))

        audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        for unknown_id, (address, name, relative) in UNKNOWN_EVIDENCE_IDS.items():
            with self.subTest(id=unknown_id, address=address):
                section = registry_section(registry, unknown_id)
                reviewed = unknown_id == "DATA-001"
                self.assertIn(f"- **Status:** {'resolved' if reviewed else 'open'}", section)
                self.assertIn(f"- **Confidence:** {'high' if reviewed else 'low'}", section)
                self.assertIn("- **Experiment:**", section)
                self.assertIn(f"`{relative}`", section)
                self.assertEqual(name, audit[address]["current_name"])
                self.assertEqual("static" if reviewed else "unknown", audit[address]["evidence"])
                source = (ROOT / relative).read_text(encoding="utf-8")
                self.assertRegex(
                    source,
                    rf"(?m)^; {'REVIEWED' if reviewed else 'UNKNOWN'} {unknown_id}:[^\n]*\n^{re.escape(name)}:",
                )
        self.assertEqual(
            {address for key, (address, _, _) in UNKNOWN_EVIDENCE_IDS.items() if key != "DATA-001"},
            {address for address, record in audit.items() if record.get("evidence") == "unknown"},
        )


if __name__ == "__main__":
    unittest.main()
