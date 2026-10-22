"""Pin shared facing exits and directional frame-table evidence."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "config/name_audit.json"
REVIEWS = ROOT / "config/duplicate_basis_reviews.json"
ROTATION = ROOT / "src/rendering/seven_forces_metasprites.s"


def table_pointers(source: str, name: str) -> list[str]:
    match = re.search(rf"(?ms)^{re.escape(name)}:(.*?)(?=^[A-Za-z_]\w*:|\Z)", source)
    if match is None:
        raise AssertionError(f"missing table {name}")
    return re.findall(r"\bdc\.l\s+(SevenForcesRotationSpriteFrame\d+)", match.group(1))


class FacingAndRotationReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cls.reviews = {review["basis"]: review for review in json.loads(REVIEWS.read_text(encoding="utf-8"))["reviews"]}

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        review = self.reviews[basis]
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in review["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.audit[address]["current_name"])
            self.assertIn(basis, self.audit[address]["basis"])

    def test_neutral_facing_exits_keep_bit_three(self) -> None:
        aim = (ROOT / "src/player/air_and_ground_states.s").read_text(encoding="utf-8")
        facing = (ROOT / "src/player/input_and_status.s").read_text(encoding="utf-8")
        self.assertRegex(
            aim,
            r"(?s)Player_UpdateAimDirection:.*?bset\s+#4,\$E\(a5\).*?"
            r"btst\s+#2,\(ControllerHeldState\)\.w.*?"
            r"btst\s+#3,\(ControllerHeldState\)\.w.*?"
            r"beq\.s\s+Player_UpdateAimDirection_Return.*?"
            r"Player_UpdateAimDirection_Return:\s+;[^\n]*\n\s+rts",
        )
        self.assertRegex(
            facing,
            r"(?s)Player_UpdateHorizontalFacing:.*?btst\s+#2,\$69\(a5\).*?"
            r"btst\s+#3,\$69\(a5\).*?"
            r"beq\.w\s+Player_UpdateHorizontalFacing_Return.*?"
            r"Player_UpdateHorizontalFacing_Return:\s+;[^\n]*\n\s+rts",
        )
        self.assert_review(
            "Neither direction held leaves the facing unchanged.",
            (("0x016926", "Player_UpdateAimDirection_Return"), ("0x016C60", "Player_UpdateHorizontalFacing_Return")),
        )

    def test_eight_pointer_runs_and_descriptor_consumers(self) -> None:
        source = ROTATION.read_text(encoding="utf-8")
        cases = (
            ("SevenForcesRotationFrameTable3", 16, 23),
            ("SevenForcesRotationFrameTable5", 24, 31),
            ("SevenForcesRotationFrameTable4", 23, 16),
            ("SevenForcesRotationFrameTable6", 31, 24),
            ("SevenForcesRotationFrameTable2", 15, 8),
            ("SevenForcesRotationFrameTable8", 39, 32),
        )
        for name, first, last in cases:
            with self.subTest(name=name):
                stride = 1 if first < last else -1
                self.assertEqual(
                    [f"SevenForcesRotationSpriteFrame{index:02d}" for index in range(first, last + stride, stride)],
                    table_pointers(source, name),
                )
                self.assertRegex(source, rf"\bdc\.l\s+{name}(?:[+\-]|\s|$)")
        for basis, members in (
            (
                "Multiple Seven Forces form descriptors reference this eight-entry frame-pointer table for directional part rendering.",
                (("0x059DC2", "SevenForcesRotationFrameTable3"), ("0x059E02", "SevenForcesRotationFrameTable5")),
            ),
            (
                "Multiple Seven Forces form descriptors reference this reverse-ordered frame-pointer table for directional part rendering.",
                (("0x059DE2", "SevenForcesRotationFrameTable4"), ("0x059E22", "SevenForcesRotationFrameTable6")),
            ),
            (
                "Seven Forces form descriptors reference this reverse-ordered frame-pointer table for directional part rendering.",
                (("0x059DA2", "SevenForcesRotationFrameTable2"), ("0x059E62", "SevenForcesRotationFrameTable8")),
            ),
        ):
            with self.subTest(basis=basis):
                self.assert_review(basis, members)


if __name__ == "__main__":
    unittest.main()
