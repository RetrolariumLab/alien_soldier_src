"""Keep shared mapping and fade reviews tied to exact source instructions."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REVIEWS = ROOT / "config/duplicate_basis_reviews.json"
AUDIT = ROOT / "config/name_audit.json"
COMBAT = ROOT / "src/data/stage_combat_object_sprite_mappings.s"
INDEXED = ROOT / "src/data/indexed_object_and_stage_effect_mappings.s"
FADE = ROOT / "src/rendering/palette_fades.s"


def words_at(source: str, label: str) -> list[str]:
    match = re.search(rf"(?ms)^{re.escape(label)}:(.*?)(?=^[A-Za-z_]\w*:|\Z)", source)
    if match is None:
        raise AssertionError(f"missing label {label}")
    return [word.strip() for line in re.findall(r"\bdc\.w\s+([^;\r\n]+)", match.group(1)) for word in line.split(",")]


class MappingStreamReviewEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.reviews = {review["basis"]: review for review in json.loads(REVIEWS.read_text(encoding="utf-8"))["reviews"]}
        cls.audit = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cls.combat = COMBAT.read_text(encoding="utf-8")
        cls.indexed = INDEXED.read_text(encoding="utf-8")

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        review = self.reviews[basis]
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in review["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.audit[address]["current_name"])
            self.assertIn(basis, self.audit[address]["basis"])

    def test_formation_wave_frame_order_and_tile_words(self) -> None:
        prefix = "Enemy_FormationWaveSpriteMapping"
        stream = "Enemy_FormationWaveSpriteAnimation"
        self.assertEqual(
            [word for index in range(3) for word in (f"{prefix}{index:02d}-*", "3")] + [f"{stream}-*", "0"],
            words_at(self.combat, stream),
        )
        self.assertEqual(["$680C", "$D00", "$F0"], words_at(self.combat, f"{prefix}01")[:3])
        self.assertEqual(["$6814", "$D00", "$F0"], words_at(self.combat, f"{prefix}02")[:3])
        self.assert_review(
            "Enemy_FormationWaveSpriteAnimation references this address-ordered formation-member mapping.",
            (("0x0EB3A4", f"{prefix}01"), ("0x0EB3B6", f"{prefix}02")),
        )

    def test_indexed_animation_frame_positions_and_variants(self) -> None:
        prefix = "IndexedObjectSpriteMapping"
        for suffix, duration in (("00", "6"), ("01", "$13")):
            stream = f"IndexedObjectSpriteAnimation{suffix}"
            self.assertEqual(
                [word for index in (2, 0, 1, 0) for word in (f"{prefix}{index:02d}-*", duration)]
                + [f"{stream}-*", "0"],
                words_at(self.indexed, stream),
            )
        self.assertEqual("$8800", words_at(self.indexed, f"{prefix}00")[0])
        self.assertEqual("$8804", words_at(self.indexed, f"{prefix}01")[0])
        self.assert_review(
            "IndexedObjectSpriteAnimation00 and 01 reference this address-ordered sprite-mapping record; the specific object identity is not proven.",
            (("0x19C4A8", f"{prefix}00"), ("0x19C4AE", f"{prefix}01")),
        )

        stream = "IndexedObjectSpriteAnimation02"
        self.assertEqual(
            [f"{prefix}03-*", "$30"]
            + [word for index in (4, 7, 4, 8, 4, 7, 4, 8) for word in (f"{prefix}{index:02d}-*", "5")]
            + [f"{stream}-*", "0"],
            words_at(self.indexed, stream),
        )
        self.assertEqual("$F4F9", words_at(self.indexed, f"{prefix}07")[-1])
        self.assertEqual("$F4F7", words_at(self.indexed, f"{prefix}08")[-1])
        self.assert_review(
            "IndexedObjectSpriteAnimation02 references this address-ordered sprite-mapping variant; the specific object identity is not proven.",
            (("0x19C4D2", f"{prefix}07"), ("0x19C4D8", f"{prefix}08")),
        )

    def test_missiray_falling_shot_frame_order(self) -> None:
        prefix = "Projectile_MissirayVerticalShotSpriteMapping"
        stream = "Projectile_MissirayFallingShotSpriteAnimation"
        self.assertEqual(
            [word for index in (0, 1, 2, 3, 3) for word in (f"{prefix}{index:02d}-*", "1")][:-1] + ["$FF"],
            words_at(self.combat, stream),
        )
        self.assertEqual(["$6800", "$700", "$E3F8", "$E808", "$700", "$FCF8"], words_at(self.combat, f"{prefix}01"))
        self.assertEqual(["$6800", "$700", "$E1F8", "$E808", "$700", "$FEF8"], words_at(self.combat, f"{prefix}02"))
        self.assert_review(
            "Projectile_MissirayFallingShotSpriteAnimation references this address-ordered vertical-shot mapping.",
            (("0x0EB3E4", f"{prefix}01"), ("0x0EB3F0", f"{prefix}02")),
        )

    def test_fade_step_and_progress_are_different_ram_roles(self) -> None:
        fade = FADE.read_text(encoding="utf-8")
        self.assertIn("move.w  (PaletteFadeStep).w,d0", fade)
        self.assertIn("add.w   d0,(PaletteFadeProgress).w", fade)
        self.assertIn("move.b  (PaletteFadeProgress).w,d5", fade)
        self.assertIn("move.w  #$1000,(PaletteFadeProgress).w", fade)
        self.assertIn("clr.w   (PaletteFadeStep).w", fade)
        self.assert_review(
            "The full-screen fade engine adds the signed step to the progress word, uses the progress high byte as the RGB delta, and stops at zero or 0x1000.",
            (("0xFFF75C", "PaletteFadeStep"), ("0xFFF75E", "PaletteFadeProgress")),
        )


if __name__ == "__main__":
    unittest.main()
