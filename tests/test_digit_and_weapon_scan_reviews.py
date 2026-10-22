"""Pin exact members and instructions for digit emission and weapon scans."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DigitAndWeaponScanReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
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

    def assert_review(self, basis: str, members: tuple[tuple[str, str], ...]) -> None:
        self.assertEqual(
            list(members),
            [(member["address"], member["current_name"]) for member in self.reviews[basis]["members"]],
        )
        for address, name in members:
            self.assertEqual(name, self.audit[address]["current_name"])
            self.assertIn(basis, self.audit[address]["basis"])

    def test_decimal_and_hex_digit_emitters_share_tile_encoding(self) -> None:
        self.assert_review(
            "The quotient is translated to the contiguous digit-tile range beginning at 0xB5 and appended to the staging buffer.",
            (("0x001E98", "Gfx_QueueDecimalDigitsDMA_EmitDigit"), ("0x001F3A", "Gfx_QueueHexDigitsDMA_EmitDigit")),
        )
        source = (ROOT / "src/rendering/dma_queue.s").read_text(encoding="utf-8")
        for radix, divisor in (
            ("Decimal", "DecimalDigitDivisors"),
            ("Hex", "Gfx_HexDigitDivisors"),
        ):
            with self.subTest(radix=radix):
                routine = f"Gfx_Queue{radix}DigitsDMA"
                body = source.split(routine + ":", 1)[1].split("; End of function " + routine, 1)[0]
                emitter = body.split(routine + "_EmitDigit:", 1)[1]
                self.assertIn(f"divu.w  {divisor}(pc,d2.w),d1", body)
                self.assertIn("addi.b  #-$4B,d1", emitter)
                self.assertIn("move.b  d1,d0", emitter)
                self.assertIn("move.w  d0,(a2)+", emitter)
                self.assertIn("swap    d1", emitter)
        self.assertIn("dc.w    1, 10, 100, 1000, 10000", source)
        self.assertIn("dc.w    1, $10, $100, $1000", source)

    def test_bullet_and_beam_scan_eight_effect_slots(self) -> None:
        self.assert_review(
            "The same eight-slot forward scan.",
            (("0x018352", "Weapon_FireBulletHandler_FindSlot"), ("0x018436", "Weapon_FireBeamWeapon_FindSlot")),
        )
        source = (ROOT / "src/weapons/firing.s").read_text(encoding="utf-8")
        for owner in ("Weapon_FireBulletHandler", "Weapon_FireBeamWeapon"):
            with self.subTest(owner=owner):
                body = source.split(owner + ":", 1)[1].split("; End of function " + owner, 1)[0]
                loop = body.split(owner + "_FindSlot:", 1)[1]
                self.assertIn("movea.w #(SharedEffectObjectPool-M68K_RAM),a0", body)
                self.assertIn("moveq   #7,d7", body)
                self.assertIn("move.w  (a0),d0", loop)
                self.assertIn(f"beq.s   {owner}_Initialize", loop)
                self.assertIn("lea     $60(a0),a0", loop)
                self.assertIn(f"dbf     d7,{owner}_FindSlot", loop)

    def test_weapon_state_index_selects_distinct_handler_and_display_tables(self) -> None:
        self.assert_review(
            "WeaponStateIndex directly indexes this ROM table; the entries select the state handler or its display index.",
            (("0x017984", "Weapon_StateHandlerOffsets"), ("0x0179AC", "Weapon_StateDisplayIndexTable")),
        )
        source = (ROOT / "src/ui/weapon_state_and_selection.s").read_text(encoding="utf-8")
        dispatch = source.split("Weapon_DispatchCurrentState:", 1)[1].split("Weapon_StateHandlerOffsets:", 1)[0]
        display = source.split("Weapon_GetStateDisplayIndex:", 1)[1].split("Weapon_StateDisplayIndexTable:", 1)[0]
        self.assertIn("move.w  (WeaponStateIndex).w,d0", dispatch)
        self.assertIn("movea.w Weapon_StateHandlerOffsets(pc,d0.w),a0", dispatch)
        self.assertIn("adda.l  #Weapon_GetStateDisplayIndex,a0", dispatch)
        self.assertIn("jmp     (a0)", dispatch)
        self.assertIn("move.w  (WeaponStateIndex).w,d0", display)
        self.assertIn("move.w  Weapon_StateDisplayIndexTable(pc,d0.w),d0", display)
        self.assertIn("rts", display)
        self.assertIn("dc.w    Weapon_ConfigureState2Lifetime-Weapon_GetStateDisplayIndex", source)
        self.assertIn("dc.w    0, 2, 4, 6, 8, $A, $C, $E, $10, 0, 0", source)


if __name__ == "__main__":
    unittest.main()
