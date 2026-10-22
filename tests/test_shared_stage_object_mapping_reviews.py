"""Pin the exact members and readers of three shared mapping reviews."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "src/data/shared_stage_object_sprite_mappings.s"
AUDIT = ROOT / "config/name_audit.json"
REVIEWS = ROOT / "config/duplicate_basis_reviews.json"

FLOATER_BASES = (
    "Both alternating shared streams reference this high-bit-terminated sprite mapping.",
    "The streams are selected by the Stage 12 floating-object table and Gusthead debris table; the 5/4 stream is also assigned to a Sharpssteel projectile.",
)
BEETLE_BASIS = (
    "Enemy_Stage10BeetleLoopAnimation references this high-bit-terminated sprite mapping, "
    "and both the beetle initializer and controller install that stream."
)


def stream_words(source: str, label: str) -> list[str]:
    match = re.search(rf"(?ms)^{re.escape(label)}:(.*?)(?=^[A-Za-z_]\w*:|\Z)", source)
    if match is None:
        raise AssertionError(f"missing stream {label}")
    return [word.strip() for word in re.findall(r"\bdc\.w\s+([^;\r\n]+)", match.group(1))]


class SharedStageObjectMappingReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = DATA.read_text(encoding="utf-8")
        cls.records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cls.reviews = {review["basis"]: review for review in json.loads(REVIEWS.read_text(encoding="utf-8"))["reviews"]}

    def test_floater_and_beetle_reviews_pin_exact_mapping_members(self) -> None:
        cases = (
            (FLOATER_BASES[0], 0x1A0CBE, "SharedFloaterDebrisProjectile"),
            (FLOATER_BASES[1], 0x1A0CBE, "SharedFloaterDebrisProjectile"),
            (BEETLE_BASIS, 0x1A0CDC, "Enemy_Stage10Beetle"),
        )
        for basis, first_address, prefix in cases:
            with self.subTest(basis=basis):
                expected = [
                    (f"0x{first_address + 6 * index:06X}", f"{prefix}SpriteMapping{suffix}")
                    for index, suffix in enumerate("ABC")
                ]
                members = self.reviews[basis]["members"]
                self.assertEqual(
                    expected,
                    [(member["address"], member["current_name"]) for member in members],
                )
                self.assertEqual(
                    {"src/data/shared_stage_object_sprite_mappings.s"},
                    {member["file"] for member in members},
                )
                for address, name in expected:
                    self.assertIn(basis, self.records[address]["basis"])
                    match = re.search(
                        rf"(?m)^{name}:\s+dc\.w\s+\$([0-9A-F]+),",
                        self.source,
                    )
                    self.assertIsNotNone(match)
                    self.assertTrue(int(match.group(1), 16) & 0x8000)

    def test_stream_orders_durations_and_consumers(self) -> None:
        for label, prefix, durations in (
            ("SharedFloaterDebrisProjectileAlternating5And4Animation", "SharedFloaterDebrisProjectile", (5, 4, 5, 4)),
            ("SharedFloaterDebrisProjectileAlternating3And2Animation", "SharedFloaterDebrisProjectile", (3, 2, 3, 2)),
            ("Enemy_Stage10BeetleLoopAnimation", "Enemy_Stage10Beetle", (2, 3, 2, 3)),
        ):
            with self.subTest(stream=label):
                expected = [
                    word
                    for suffix, duration in zip("ABAC", durations)
                    for word in (f"{prefix}SpriteMapping{suffix}-*", str(duration))
                ] + [f"{label}-*", "0"]
                self.assertEqual(expected, stream_words(self.source, label))

        for path in ("src/enemies/stage_12_enemies.s", "src/bosses/gusthead_tentacles.s"):
            body = (ROOT / path).read_text(encoding="utf-8")
            for suffix in ("5And4", "3And2"):
                self.assertIn(
                    f"dc.l    SharedFloaterDebrisProjectileAlternating{suffix}Animation",
                    body,
                )
        sharpssteel = (ROOT / "src/projectiles/sharpssteel.s").read_text(encoding="utf-8")
        self.assertIn(
            "#SharedFloaterDebrisProjectileAlternating5And4Animation,8(a0)",
            sharpssteel,
        )
        beetles = (ROOT / "src/enemies/stage_10_beetles.s").read_text(encoding="utf-8")
        self.assertEqual(2, beetles.count("#Enemy_Stage10BeetleLoopAnimation,8(a5)"))

    def test_duration_stream_consumer_evidence_is_specific(self) -> None:
        addresses = ("0x1A0E86", "0x1A0E96", "0x1A0EA6")
        evidence = [self.records[address]["basis"][1] for address in addresses]
        self.assertEqual(3, len(set(evidence)))
        for claim, slot in zip(evidence, ("slot 1", "slots 0 and 2", "slot 3")):
            self.assertIn(slot, claim)
        self.assertNotIn("enemy, projectile, and boss paths", evidence[0])
        self.assertNotIn("enemy, projectile, and boss paths", evidence[2])

    def test_teddy_pose_streams_have_distinct_static_consumers(self) -> None:
        basis = (
            "The named Stage 12 Teddy Bear state or initializer assigns this "
            "mapping/duration stream directly to the object mapping field."
        )
        self.assertEqual(
            ["0x1A0FD2", "0x1A0FD6"],
            [member["address"] for member in self.reviews[basis]["members"]],
        )
        stage = (ROOT / "src/stages/stage_12_yacht.s").read_text(encoding="utf-8")
        for address, stream, mapping, owner in (
            (
                "0x1A0FD2",
                "Stage12_TeddyBearInitialPoseAnimation",
                "Stage12_TeddyBearSpriteMappingP",
                "Stage12_TeddyBearDisableCollision",
            ),
            (
                "0x1A0FD6",
                "Stage12_TeddyBearPilotReleasePoseAnimation",
                "Stage12_TeddyBearSpriteMappingI",
                "Stage12_TeddyBearPilotRelease",
            ),
        ):
            with self.subTest(stream=stream):
                self.assertIn(basis, self.records[address]["basis"])
                self.assertEqual([f"{mapping}-*", "$FF"], stream_words(self.source, stream))
                block = stage.split(owner + ":", 1)[1].split("rts", 1)[0]
                self.assertIn(f"move.l  #{stream},8(a5)", block)


if __name__ == "__main__":
    unittest.main()
