from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class ProjectileSemanticsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.records = {
            record["address"]: record
            for record in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.battle = (ROOT / "src/bosses/valkirie_battle.s").read_text(encoding="utf-8")
        cls.projectiles = (ROOT / "src/projectiles/shared_boss_projectiles.s").read_text(encoding="utf-8")

    def test_valkirie_spawn_uses_frame_parity_not_global_gate(self) -> None:
        spawn = self.battle.split("Projectile_SpawnValkirieBullet:", 1)[1].split(
            "; End of function Projectile_SpawnValkirieBullet", 1
        )[0]
        entry, rest = spawn.split("Projectile_SpawnValkirieBulletReturn:", 1)
        exit_code, init = rest.split("Projectile_InitValkirieBullet:", 1)
        self.assertIn("btst    #0,(FrameCounter+1).w", entry)
        self.assertIn("bne.s   Projectile_SpawnValkirieBulletReturn", entry)
        self.assertIn("jsr     (Projectile_FindFreeSlotReverse).l", entry)
        self.assertIn("beq.s   Projectile_InitValkirieBullet", entry)
        self.assertIn("rts", exit_code)
        self.assertIn("moveq   #0,d4", init)
        self.assertIn("jmp     Projectile_InitValkirieBulletFromSource", init)
        self.assertIn("FrameCounter bit zero", self.records["0x055CA2"]["basis"][0])
        self.assertNotIn("global projectile gate", self.battle)

    def test_valkirie_blink_entry_branch_and_return(self) -> None:
        update = self.projectiles.split("Projectile_UpdateValkirieBullet:", 1)[1].split(
            "; End of function Projectile_UpdateValkirieBullet", 1
        )[0]
        entry, rest = update.split("Projectile_UpdateValkirieBulletVisibility:", 1)
        blink, exit_code = rest.split("Projectile_UpdateValkirieBulletReturn:", 1)
        self.assertIn("subq.w  #1,$48(a5)", entry)
        self.assertIn("bset    #4,2(a5)", entry)
        self.assertIn("bset    #7,2(a5)", blink)
        self.assertIn("andi.w  #1,d0", blink)
        self.assertIn("move.w  $4A(a5),d1", blink)
        self.assertIn("eor.w   d0,d1", blink)
        self.assertIn("bclr    #7,2(a5)", blink)
        self.assertIn("rts", exit_code)
        bases = [self.records[address]["basis"][0] for address in ("0x02A092", "0x02A0A0", "0x02A0BC")]
        self.assertEqual(3, len(set(bases)))

    def test_horizontal_drag_is_signed_step_without_zero_clamp(self) -> None:
        update = self.projectiles.split("Projectile_UpdateGravityAndHorizontalDrag:", 1)[1].split(
            "; End of function Projectile_UpdateGravityAndHorizontalDrag", 1
        )[0]
        entry, rest = update.split("Projectile_UpdateGravityAndHorizontalDragActive:", 1)
        active, negative = rest.split("Projectile_DragNegativeHorizontalVelocity:", 1)
        self.assertIn("subq.w  #1,$48(a5)", entry)
        self.assertIn("bset    #4,2(a5)", entry)
        self.assertIn("addi.l  #$4000,$1C(a5)", active)
        self.assertIn("tst.w   $18(a5)", active)
        self.assertIn("bmi.s   Projectile_DragNegativeHorizontalVelocity", active)
        self.assertIn("subi.l  #$2000,$18(a5)", active)
        self.assertIn("addi.l  #$2000,$18(a5)", negative)
        self.assertNotIn("clr.l   $18(a5)", update)
        bases = [self.records[address]["basis"][0] for address in ("0x02A272", "0x02A280", "0x02A298")]
        self.assertEqual(3, len(set(bases)))
        self.assertIn("no zero clamp", bases[1])


if __name__ == "__main__":
    unittest.main()
