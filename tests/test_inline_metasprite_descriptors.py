from __future__ import annotations

import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class InlineMetaspriteDescriptorTests(unittest.TestCase):
    def test_tagged_pointer_path_copies_three_words(self) -> None:
        source = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        routine = source.split("Sprite_InitializeLinkedMetaspriteParts:", 1)[1].split(
            "; End of function Sprite_InitializeLinkedMetaspriteParts", 1
        )[0]
        self.assertIn("bclr    #0,d4", routine)
        self.assertIn(
            "bne.s   Sprite_InitializeLinkedMetaspritePartsUseInlineDescriptor",
            routine,
        )
        inline = routine.split("Sprite_InitializeLinkedMetaspritePartsUseInlineDescriptor:", 1)[1].split(
            "Sprite_InitializeLinkedMetaspritePartsTransform:", 1
        )[0]
        for instruction in (
            "movea.l d4,a3",
            "move.w  (a3)+,$E(a4)",
            "move.w  (a3)+,8(a4)",
            "move.w  (a3),$A(a4)",
        ):
            self.assertIn(instruction, inline)

    def test_seven_descriptor_families_have_exact_members_and_words(self) -> None:
        reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        audit = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        families = (
            (
                "src/rendering/seven_forces_metasprites.s",
                "SevenForcesInlinePartDescriptor",
                "Low-bit-tagged metasprite entries point here; Sprite_InitializeLinkedMetaspriteParts reads its three words into child fields $E, $8, and $A.",
                (
                    ("0x059E82", "0", ("$42D", "$F00", "$F0F0")),
                    ("0x059E88", "1", ("$43D", "$A00", "$F4F4")),
                    ("0x059E8E", "2", ("$446", "$500", "$F8F8")),
                ),
            ),
            (
                "src/data/madam_barbar_flying_neo_joker_back_stringer_sharpssteel_metasprites.s",
                "Boss_MadamBarbarInlineSpriteDescriptor",
                "Boss_MadamBarbarMetaspriteDescriptors references this three-word record with a low-bit tag; Sprite_InitializeLinkedMetaspriteParts copies its words into child fields $E, $8, and $A.",
                (
                    ("0x034E36", "A", ("$6390", "$F00", "$F0F0")),
                    ("0x034E3C", "B", ("$63A0", "$A00", "$F4F4")),
                    ("0x034E42", "C", ("$43C4", "0", "$FCFC")),
                ),
            ),
            (
                "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s",
                "Boss_AntroidInlineSpriteDescriptor",
                "Antroid's primary descriptor array references this three-word inline sprite descriptor.",
                (
                    ("0x034992", "B", ("$325", "$A00", "$F4F4")),
                    ("0x034998", "C", ("$315", "$F00", "$F0F0")),
                ),
            ),
            (
                "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s",
                "Boss_ShellshogunInlineSpriteDescriptor",
                "Shellshogun's descriptor array references this three-word inline sprite descriptor.",
                (
                    ("0x034BA0", "A", ("$6457", "$A00", "$F4F4")),
                    ("0x034BA6", "B", ("$6460", "$500", "$F8F8")),
                ),
            ),
            (
                "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s",
                "Boss_XiTigerInlineSpriteDescriptor",
                "Xi-Tiger's descriptor array references this three-word inline sprite descriptor.",
                (
                    ("0x034CE4", "A", ("$62D4", "$500", "$F8F8")),
                    ("0x034CEA", "B", ("$62D8", "$A00", "$F4F4")),
                    ("0x034CF0", "C", ("$62E1", "$A00", "$F4F4")),
                ),
            ),
            (
                "src/data/madam_barbar_flying_neo_joker_back_stringer_sharpssteel_metasprites.s",
                "Boss_JokerInlineSpriteDescriptor",
                "Joker's descriptor array references this three-word inline sprite descriptor.",
                (
                    ("0x03504A", "A", ("$636E", "$500", "$F8F8")),
                    ("0x035050", "B", ("$6366", "$500", "$F8F8")),
                ),
            ),
            (
                "src/data/madam_barbar_flying_neo_joker_back_stringer_sharpssteel_metasprites.s",
                "Boss_SharpssteelInlineSpriteDescriptor",
                "Sharpssteel's descriptor array references this three-word inline sprite descriptor.",
                (
                    ("0x035214", "A", ("$63F9", "$A00", "$F4F4")),
                    ("0x03521A", "B", ("$6402", "$500", "$F8F8")),
                ),
            ),
        )
        for filename, prefix, basis, members in families:
            with self.subTest(family=prefix):
                source = (ROOT / filename).read_text(encoding="utf-8")
                self.assertEqual(
                    [address for address, _, _ in members],
                    [member["address"] for member in reviews[basis]["members"]],
                )
                for address, suffix, expected_words in members:
                    label = prefix + suffix
                    match = re.search(
                        rf"(?m)^{re.escape(label)}:\s+dc\.w\s+([^;\r\n]+)",
                        source,
                    )
                    self.assertIsNotNone(match, label)
                    words = tuple(word.strip() for word in match.group(1).split(","))
                    self.assertEqual(expected_words, words)
                    self.assertIn(f"{label}+1", source)
                    self.assertIn(basis, audit[address]["basis"])

        owners = (
            ("madam_barbar_core.s", "Boss_MadamBarbarMetaspriteDescriptors"),
            ("antroid_core.s", "Boss_AntroidPrimaryMetaspriteDescriptors"),
            ("shellshogun_core.s", "Boss_ShellshogunMetaspriteDescriptors"),
            ("xi_tiger_battle_states.s", "Boss_XiTigerMetaspriteDescriptors"),
            ("joker_core.s", "Boss_JokerMetaspriteDescriptors"),
            ("sharpssteel_core.s", "Boss_SharpssteelMetaspriteDescriptors"),
        )
        for filename, table in owners:
            with self.subTest(owner=filename):
                setup = (ROOT / "src/bosses" / filename).read_text(encoding="utf-8")
                self.assertIn(f"movea.l #{table},a0", setup)
                self.assertIn("jsr     (Sprite_InitializeLinkedMetaspriteParts).l", setup)


if __name__ == "__main__":
    unittest.main()
