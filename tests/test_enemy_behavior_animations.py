from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "src/data/weapon_select_and_enemy_sprite_mappings.s"
REVIEWS = ROOT / "config/duplicate_basis_reviews.json"
AUDIT = ROOT / "config/name_audit.json"


class EnemyBehaviorAnimationTests(unittest.TestCase):
    def test_exact_mapping_members_and_frame_timers(self) -> None:
        source = DATA.read_text(encoding="utf-8")
        reviews = {review["basis"]: review for review in json.loads(REVIEWS.read_text(encoding="utf-8"))["reviews"]}
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cases = (
            (
                "Movement",
                "Wait",
                ("05", "06", "07", "08"),
                ("4", "4", "4", "4", "0"),
                ("0x0E9CE8", "0x0E9D06", "0x0E9D24"),
                True,
            ),
            (
                "AttackCooldown",
                "Defeat",
                ("00", "09", "10", "11", "10", "09"),
                ("3", "6", "8", "$10", "8", "$FF"),
                ("0x0E9D42", "0x0E9D60", "0x0E9D7E"),
                False,
            ),
            (
                "Defeat",
                None,
                ("12", "14", "13", "14"),
                ("3", "2", "3", "2", "0"),
                ("0x0E9DA8", "0x0E9DCC", "0x0E9DF0"),
                True,
            ),
        )
        for kind, next_kind, frames, timers, addresses, loops in cases:
            with self.subTest(kind=kind):
                label = f"Enemy_Behavior{kind}SpriteAnimation"
                section = source.split(label + ":", 1)[1]
                next_label = (
                    f"Enemy_Behavior{next_kind}SpriteAnimation"
                    if next_kind is not None
                    else "PeriodicShotEnemySpriteMapping00"
                )
                section = section.split(next_label + ":", 1)[0]
                self.assertEqual(
                    frames,
                    tuple(
                        re.findall(
                            r"\bdc\.w\s+Enemy_BehaviorSpriteMapping(\d\d)-\*",
                            section,
                        )
                    ),
                )
                self.assertEqual(
                    timers,
                    tuple(re.findall(r"\bdc\.w\s+(\$[0-9A-F]+|\d+)\b", section)),
                )
                self.assertEqual(
                    loops,
                    f"dc.w    {label}-*" in section,
                )
                basis = f"{label} references this address-ordered composite sprite mapping."
                self.assertEqual(
                    addresses,
                    tuple(member["address"] for member in reviews[basis]["members"]),
                )
                for address in addresses:
                    self.assertIn(basis, records[address]["basis"])

    def test_final_attack_timer_holds_without_advancing(self) -> None:
        resolver = (ROOT / "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
        routine = resolver.split("Anim_ResolveTimedMappingFrame:", 1)[1].split(
            "; End of function Anim_ResolveTimedMappingFrame", 1
        )[0]
        self.assertIn("tst.b   d0", routine)
        self.assertIn("bmi.s   Anim_ResolveTimedMappingFrame_ResolveMappingPointer", routine)
        self.assertIn("addq.w  #4,a4", routine)
        enemy = (ROOT / "src/enemies/jetsripper_stage_actors.s").read_text(encoding="utf-8")
        self.assertIn("move.w  #$10,$5C(a5)", enemy)
        spawn = (ROOT / "src/enemies/spawn_and_movement.s").read_text(encoding="utf-8")
        self.assertIn("move.l  #Enemy_BehaviorDefeatSpriteAnimation,8(a5)", spawn)


if __name__ == "__main__":
    unittest.main()
