"""Pin buffer-clear and boss-helper reviews to their actual instructions."""

from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "config/name_audit.json"
REVIEWS = ROOT / "config/duplicate_basis_reviews.json"


class ScrollAndBossHelperReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cls.reviews = {review["basis"]: review for review in json.loads(REVIEWS.read_text(encoding="utf-8"))["reviews"]}

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in self.reviews[basis]["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.audit[address]["current_name"])
            self.assertIn(basis, self.audit[address]["basis"])

    def test_scroll_clears_have_distinct_ranges_and_entry_loop_roles(self) -> None:
        source = (ROOT / "src/system/memory_initialization.s").read_text(encoding="utf-8")
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        for prefix, address, count, size, basis, members in (
            (
                "HScroll",
                "$FFFFE400",
                "$7F",
                2048,
                "The loop clears 128 groups of four longwords beginning at HScrollBuffer, exactly the 2,048-byte horizontal-scroll workspace.",
                (("0x0030EC", "Gfx_ClearHScrollBuffer"), ("0x0030F6", "Gfx_ClearHScrollBuffer_Loop")),
            ),
            (
                "VScroll",
                "$FFFFEC00",
                "9",
                160,
                "The loop clears ten groups of four longwords beginning at VScrollBuffer, exactly the 160-byte vertical-scroll workspace; it does not traverse entity slots.",
                (("0x003104", "Gfx_ClearVScrollBuffer"), ("0x00310E", "Gfx_ClearVScrollBuffer_Loop")),
            ),
        ):
            with self.subTest(buffer=prefix):
                name = f"Gfx_Clear{prefix}Buffer"
                body = re.search(rf"(?s)^{name}:.*?; End of function {name}", source, re.MULTILINE)
                self.assertIsNotNone(body)
                block = body.group()
                self.assertIn(f"lea     ({prefix}Buffer).w,a0", block)
                self.assertIn("moveq   #0,d0", block)
                self.assertIn(f"move.w  #{count},d1", block)
                self.assertIn(f"{name}_Loop:", block)
                self.assertEqual(4, block.count("move.l  d0,(a0)+"))
                self.assertIn(f"dbf     d1,{name}_Loop", block)
                self.assertIn(f"{prefix}Buffer", ram)
                self.assertIn(address, ram)
                self.assertEqual(size, (int(count.replace("$", "0x"), 0) + 1) * 16)
                self.assert_review(basis, members)

    def test_valkirie_wrapper_calls_pair_selection_then_places_y(self) -> None:
        source = (ROOT / "src/bosses/valkirie_battle.s").read_text(encoding="utf-8")
        self.assertRegex(
            source,
            r"(?s)Entity_SelectValkirieActivePartPairAtY140:.*?"
            r"move\.w\s+#\$140,d4\s+"
            r"bsr\.s\s+Entity_SelectValkirieActivePartPair\s+"
            r"move\.w\s+d4,\$14\(a0\)",
        )
        body = re.search(
            r"(?s)^Entity_SelectValkirieActivePartPair:.*?"
            r"; End of function Entity_SelectValkirieActivePartPair",
            source,
            re.MULTILINE,
        )
        self.assertIsNotNone(body)
        for instruction in (
            "movea.w $48(a5),a0",
            "movea.w $4A(a5),a0",
            "move.w  d0,$48(a5)",
            "move.w  d1,$4A(a5)",
            "movea.w d0,a0",
            "movea.w d1,a0",
        ):
            self.assertIn(instruction, body.group())
        self.assertEqual(2, body.group().count("bclr    d2,2(a0)"))
        self.assertEqual(2, body.group().count("bset    d2,2(a0)"))
        self.assert_review(
            "The helper disables the pair stored at offsets $48/$4A, stores d0/d1 as the new pair, and enables both selected part objects.",
            (
                ("0x055FE6", "Entity_SelectValkirieActivePartPairAtY140"),
                ("0x055FF2", "Entity_SelectValkirieActivePartPair"),
            ),
        )

    def test_bugmax_animations_have_distinct_frames_and_durations(self) -> None:
        data = (ROOT / "src/data/bugmax_sprite_mappings.s").read_text(encoding="utf-8")
        projectile = (ROOT / "src/projectiles/bugmax.s").read_text(encoding="utf-8")
        resolver = (ROOT / "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
        for variant, count, duration in (("Spread", 2, 2), ("Sine", 4, 6)):
            with self.subTest(variant=variant):
                label = f"Projectile_Bugmax{variant}SpriteAnimation"
                match = re.search(rf"(?ms)^{label}:(.*?)(?=^[A-Za-z_]\w*:|\Z)", data)
                self.assertIsNotNone(match)
                words = [word.strip() for word in re.findall(r"\bdc\.w\s+([^;\r\n]+)", match.group(1))]
                self.assertEqual(
                    [
                        word
                        for index in range(count)
                        for word in (f"Projectile_Bugmax{variant}Frame{index:02d}-*", str(duration))
                    ]
                    + [f"{label}-*", "0"],
                    words[: count * 2 + 2],
                )
                self.assertIn(f"move.l  #{label},8(a0)", projectile)
        self.assertIn("move.w  2(a4),d0", resolver)
        self.assertIn("adda.w  (a4),a4", resolver)
        self.assert_review(
            "The named Bugmax projectile initializer stores this relative-offset sprite animation in object field 8, and Anim_ResolveTimedMappingFrame consumes its frame-offset and duration pairs.",
            (
                ("0x0ECBD0", "Projectile_BugmaxSpreadSpriteAnimation"),
                ("0x0ECBDC", "Projectile_BugmaxSineSpriteAnimation"),
            ),
        )


if __name__ == "__main__":
    unittest.main()
