"""Pin four repeat-basis reviews with direct source evidence."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "config/name_audit.json"
REVIEWS = ROOT / "config/duplicate_basis_reviews.json"
SHARED = ROOT / "src/data/shared_stage_object_sprite_mappings.s"
LIGHTNING = ROOT / "src/data/indexed_object_and_stage_effect_mappings.s"

ROW_BASIS = "Stage and weapon-setup paths fill this complete 64-word row."
LIGHTNING_BASIS = "Midgame_LightningSpriteAnimation02 references this address-ordered composite sprite mapping."
TEDDY_MAPPING_BASIS = "Stage12_TeddyBearRescueAnimation and SharedTeddyHazardLoopAnimation reference this mapping."
TEDDY_OWNER_BASIS = (
    "The shared loop is installed by the Teddy Bear initializer and by both Stage 15 hazard-wave initializers."
)


def section(source: str, start: str, end: str) -> str:
    return source.split(start, 1)[1].split(end, 1)[0]


def word_lines(source: str, label: str, next_label: str) -> list[list[str]]:
    return [
        [item.strip() for item in line.split(",")]
        for line in re.findall(r"\bdc\.w\s+([^;\r\n]+)", section(source, f"{label}:", f"{next_label}:"))
    ]


class StaticRepeatBasisFamilyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cls.reviews = {review["basis"]: review for review in json.loads(REVIEWS.read_text(encoding="utf-8"))["reviews"]}

    def test_exact_review_members_and_sources(self) -> None:
        teddy_members = [
            (f"0x{0x1A0D54 + 0x18 * index:06X}", f"SharedTeddyHazardSpriteMapping{suffix}")
            for index, suffix in enumerate("ABC")
        ]
        cases = (
            (
                ROW_BASIS,
                [(f"0x{0xFFFF0D00 + 0x80 * i:08X}", f"PlaneTilemapRow{26 + i}") for i in range(3)],
                "src/ram_addrs.inc",
            ),
            (
                LIGHTNING_BASIS,
                [
                    (address, f"Midgame_LightningSpriteMapping{number}")
                    for address, number in zip(("0x19C63A", "0x19C658", "0x19C670"), ("08", "09", "10"))
                ],
                "src/data/indexed_object_and_stage_effect_mappings.s",
            ),
            (TEDDY_MAPPING_BASIS, teddy_members, "src/data/shared_stage_object_sprite_mappings.s"),
            (TEDDY_OWNER_BASIS, teddy_members, "src/data/shared_stage_object_sprite_mappings.s"),
        )
        for basis, expected, filename in cases:
            with self.subTest(basis=basis):
                members = self.reviews[basis]["members"]
                self.assertEqual(
                    expected,
                    [(member["address"], member["current_name"]) for member in members],
                )
                self.assertEqual({filename}, {member["file"] for member in members})
                for address, _ in expected:
                    self.assertIn(basis, self.audit[address]["basis"])

    def test_three_shared_ram_rows_are_filled_for_64_words(self) -> None:
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        for index, address in enumerate(("$FFFF0D00", "$FFFF0D80", "$FFFF0E00")):
            self.assertRegex(ram, rf"(?m)^PlaneTilemapRow{26 + index}\s+equ\s+\{address}\b")
        weapon = (ROOT / "src/stages/gameplay_initialization.s").read_text(encoding="utf-8")
        weapon = section(
            weapon,
            "WeaponSetup_InitializeColorTables:",
            "; End of function WeaponSetup_InitializeColorTables",
        )
        stage = (ROOT / "src/stages/configuration.s").read_text(encoding="utf-8")
        stage = section(
            stage,
            "Stage_PrepareFourWordRangesWithD:",
            "; End of function Stage_InitializeStage9",
        )
        for body, registers in ((weapon, "a0a1a2"), (stage, "a1a2a3")):
            self.assertIn("moveq   #$3F,d7", body)
            for row in range(26, 29):
                self.assertIn(f"(PlaneTilemapRow{row}).l", body)
            for register in (registers[i : i + 2] for i in range(0, len(registers), 2)):
                self.assertIn(f"move.w  d1,({register})+", body)
            self.assertIn("dbf     d7,", body)

    def test_lightning_animation_selects_three_distinct_mappings(self) -> None:
        source = LIGHTNING.read_text(encoding="utf-8")
        stream = word_lines(
            source,
            "Midgame_LightningSpriteAnimation02",
            "Midgame_LightningSpriteAnimation03",
        )
        for number in ("08", "09", "10"):
            self.assertIn([f"Midgame_LightningSpriteMapping{number}-*"], stream)
            index = stream.index([f"Midgame_LightningSpriteMapping{number}-*"])
            self.assertEqual(["3"], stream[index + 1])
        for number, following in (("08", "09"), ("09", "10"), ("10", "11")):
            mapping = word_lines(
                source,
                f"Midgame_LightningSpriteMapping{number}",
                f"Midgame_LightningSpriteMapping{following}",
            )
            self.assertGreaterEqual(len(mapping), 4)
            self.assertTrue(int(mapping[-1][0].removeprefix("$"), 16) & 0x8000)

    def test_teddy_streams_share_mappings_but_not_durations(self) -> None:
        source = SHARED.read_text(encoding="utf-8")
        for suffix, following in (("A", "B"), ("B", "C"), ("C", "J")):
            next_label = (
                "Stage12_TeddyBearSpriteMappingJ" if following == "J" else f"SharedTeddyHazardSpriteMapping{following}"
            )
            mapping = word_lines(source, f"SharedTeddyHazardSpriteMapping{suffix}", next_label)
            self.assertEqual(4, len(mapping))
            self.assertTrue(int(mapping[-1][0].removeprefix("$"), 16) & 0x8000)
        for stream_name, after, durations in (
            ("Stage12_TeddyBearRescueAnimation", "SharedTeddyHazardLoopAnimation", (5, 4, 5, 4)),
            ("SharedTeddyHazardLoopAnimation", "Stage12_TeddyBearPreBoardingAnimation", (2, 1, 2, 1)),
        ):
            words = word_lines(source, stream_name, after)
            expected = [
                [value]
                for suffix, duration in zip("ABCB", durations)
                for value in (f"SharedTeddyHazardSpriteMapping{suffix}-*", str(duration))
            ]
            self.assertEqual(expected, words[:8])
        stage12 = (ROOT / "src/stages/stage_12_yacht.s").read_text(encoding="utf-8")
        stage15 = (ROOT / "src/stages/stage_15_fragment_hazards.s").read_text(encoding="utf-8")
        self.assertEqual(1, stage12.count("#SharedTeddyHazardLoopAnimation,8(a5)"))
        self.assertEqual(1, stage12.count("#Stage12_TeddyBearRescueAnimation,8(a5)"))
        self.assertEqual(2, stage15.count("#SharedTeddyHazardLoopAnimation,8(a5)"))


if __name__ == "__main__":
    unittest.main()
