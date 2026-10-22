"""Check only the shared SFX/Voice input gates, not their different bodies."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def between(source: str, start: str, end: str) -> str:
    return source.split(start + ":", 1)[1].split(end + ":", 1)[0]


class OptionsSoundVoiceInputEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = (ROOT / "src/ui/options_menu_controllers.s").read_text(encoding="utf-8")
        cls.audit = {
            row["address"]: row
            for row in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            row["basis"]: row
            for row in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        }

    def test_pressed_input_gates_have_exact_two_member_reviews(self) -> None:
        for first, second in (
            ("0x009C86", "0x009D36"),
            ("0x009CB4", "0x009D52"),
        ):
            with self.subTest(first=first, second=second):
                common = set(self.audit[first]["basis"]) & set(self.audit[second]["basis"])
                self.assertEqual(1, len(common))
                review = self.reviews[common.pop()]
                self.assertEqual([first, second], [member["address"] for member in review["members"]])
                self.assertEqual(
                    ["src/ui/options_menu_controllers.s"] * 2,
                    [member["file"] for member in review["members"]],
                )

    def test_sfx_and_voice_repeat_gates_share_only_input_logic(self) -> None:
        basis = (
            "This path sets D1 to one, uses OptionsRepeatTimer and VBlankFrameCounter "
            "bit zero to gate held-input repetition, then tests held bits two and "
            "three before the pressed-input path."
        )
        self.assertEqual(
            ["0x009C64", "0x009D14"],
            [member["address"] for member in self.reviews[basis]["members"]],
        )
        for family, index, table in (
            ("SFX", "OptionsSFXIndex", "Options_SFXTestLowRequestIDs"),
            ("Voice", "OptionsVoiceIndex", "Options_VoiceTestRequestIDs"),
        ):
            with self.subTest(family=family):
                body = between(
                    self.source,
                    f"UI_Update{family}TestSelection",
                    f"UI_Check{family}TestPrimaryInput",
                )
                self.assertIn("moveq   #1,d1", body)
                self.assertIn("tst.w   (OptionsRepeatTimer).w", body)
                self.assertIn("btst    #0,(VBlankFrameCounter+1).w", body)
                self.assertIn("btst    #2,(OptionsHeldCopy).w", body)
                self.assertIn("btst    #3,(OptionsHeldCopy).w", body)
                self.assertIn(f"move.b  ({index}).w,d0", self.source)
                self.assertIn(f"lea     {table}(pc),a0", self.source)

    def test_previous_and_next_gates_match_but_selection_bodies_do_not(self) -> None:
        for family in ("SFX", "Voice"):
            with self.subTest(family=family):
                primary = between(
                    self.source,
                    f"UI_Check{family}TestPrimaryInput",
                    f"UI_SelectPrevious{family}TestIndex",
                )
                self.assertIn("btst    #2,(OptionsPressedCopy).w", primary)
                self.assertIn(f"beq.s   UI_CheckNext{family}TestInput", primary)
                self.assertIn("move.w  #6,(OptionsCursorFlashTimer).w", primary)
                next_gate = between(
                    self.source,
                    f"UI_CheckNext{family}TestInput",
                    f"UI_SelectNext{family}TestIndex",
                )
                self.assertIn("btst    #3,(OptionsPressedCopy).w", next_gate)
                self.assertIn(f"beq.s   UI_StoreAndRender{family}TestSelection", next_gate)
                self.assertIn("move.w  #6,(OptionsCursorFlashTimer).w", next_gate)

        sfx_body = between(
            self.source,
            "UI_SelectPreviousSFXTestIndex",
            "UI_StoreAndRenderSFXTestSelection",
        )
        voice_body = between(
            self.source,
            "UI_SelectPreviousVoiceTestIndex",
            "UI_StoreAndRenderVoiceTestSelection",
        )
        self.assertIn("jsr     (Sound_QueueRequest).l", sfx_body)
        self.assertNotIn("jsr     (Sound_QueueRequest).l", voice_body)
        self.assertIn("#$98,d0", sfx_body)
        self.assertIn("#$25,d0", voice_body)


if __name__ == "__main__":
    unittest.main()
