"""Pin rotation-frame descriptor tables without assigning visual poses."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "src/data/wolf_garopa_valkirie_z_leo_metasprites.s"
SOURCE_PATH = "src/data/wolf_garopa_valkirie_z_leo_metasprites.s"


def longwords(source: str, label: str, next_label: str) -> list[str]:
    block = source.split(f"{label}:", 1)[1].split(f"{next_label}:", 1)[0]
    return re.findall(r"\bdc\.l\s+([^;\r\n]+)", block)


class RotationMetaspriteDescriptorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = DATA.read_text(encoding="utf-8")
        cls.audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }

    def test_exact_eight_pointer_tables_and_review_members(self) -> None:
        families = (
            (
                "Wolf Garopa's descriptors reference this directional mapping-pointer table.",
                "Boss_WolfGaropaRotationFrames",
                0x352A6,
                "Boss_WolfGaropaInlineSpriteDescriptor",
            ),
            (
                "Valkirie's primary descriptor array references this directional mapping-pointer table.",
                "Boss_ValkirieRotationFrames",
                0x353BC,
                "Boss_ValkirieMetaspriteDescriptors",
            ),
        )
        for basis, prefix, start, after in families:
            with self.subTest(family=prefix):
                expected = [
                    (f"0x{start + 0x20 * index:06X}", f"{prefix}{suffix}") for index, suffix in enumerate("ABC")
                ]
                self.assertEqual(
                    expected,
                    [(member["address"], member["current_name"]) for member in self.reviews[basis]["members"]],
                )
                self.assertEqual(
                    {SOURCE_PATH},
                    {member["file"] for member in self.reviews[basis]["members"]},
                )
                for index, (address, label) in enumerate(expected):
                    following = expected[index + 1][1] if index < 2 else after
                    pointers = longwords(self.source, label, following)
                    self.assertEqual(8, len(pointers), label)
                    self.assertTrue(
                        all(pointer.startswith(prefix.removesuffix("RotationFrames")) for pointer in pointers),
                        label,
                    )
                    self.assertIn(basis, self.audit[address]["basis"])

        valkirie_c = longwords(
            self.source,
            "Boss_ValkirieRotationFramesC",
            "Boss_ValkirieMetaspriteDescriptors",
        )
        self.assertLess(len(set(valkirie_c)), len(valkirie_c))

    def test_descriptor_flags_and_initializer_paths(self) -> None:
        cases = (
            (
                "Boss_WolfGaropaMetaspriteDescriptors",
                "Boss_WolfGaropaPartRadii",
                "Boss_WolfGaropaRotationFrames",
                "src/bosses/wolf_garopa_core.s",
                True,
            ),
            (
                "Boss_ValkirieMetaspriteDescriptors",
                "Boss_ValkiriePartRadii",
                "Boss_ValkirieRotationFrames",
                "src/debug/valkirie_composite_viewer.s",
                False,
            ),
        )
        for table, after, prefix, setup_path, c_flagged in cases:
            with self.subTest(table=table):
                entries = longwords(self.source, table, after)
                for suffix in "AB":
                    self.assertIn(f"{prefix}{suffix}+$18000000", entries)
                c_entry = f"{prefix}C"
                self.assertIn(f"{c_entry}+$18000000" if c_flagged else c_entry, entries)
                setup = (ROOT / setup_path).read_text(encoding="utf-8")
                self.assertIn(f"movea.l #{table},a0", setup)
                self.assertIn("jsr     (Sprite_InitializeLinkedMetaspriteParts).l", setup)

        initializer = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        self.assertIn("bclr    #0,d4", initializer)
        self.assertIn("bclr    #$16,d4", initializer)
        self.assertIn(
            "beq.s   Sprite_InitializeLinkedMetaspritePartsUseRotationFrames",
            initializer,
        )


if __name__ == "__main__":
    unittest.main()
