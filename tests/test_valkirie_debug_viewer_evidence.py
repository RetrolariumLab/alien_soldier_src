"""Pin the paired Valkirie debug viewers' exact counts and data bounds."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SECONDARY = ROOT / "src/debug/valkirie_secondary_composite_viewer.s"
TERTIARY = ROOT / "src/debug/valkirie_tertiary_composite_viewer.s"


def instructions(source: str, start: str, end: str) -> str:
    return source.split(start + ":", 1)[1].split(end, 1)[0]


def data_bytes(source: str, label: str, directive: str) -> bytes:
    result = []
    for line in source.split(label + ":", 1)[1].splitlines():
        code = line.split(";", 1)[0]
        if directive not in code:
            continue
        for token in code.split(directive, 1)[1].split(","):
            value = int(token.strip().removeprefix("$"), 16)
            if directive == "dc.w":
                result.extend((value >> 8, value & 0xFF))
            else:
                result.append(value)
    return bytes(result)


class ValkirieDebugViewerEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.audit = {
            row["address"]: row
            for row in json.loads((ROOT / "config/name_audit.json").read_text(encoding="utf-8"))["records"]
        }
        cls.reviews = {
            row["basis"]: row
            for row in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        }

    def test_ten_reviewed_pairs_have_exact_members(self) -> None:
        pairs = (
            ("0x051616", "0x0518AA"),
            ("0x051624", "0x0518B8"),
            ("0x051662", "0x0518F6"),
            ("0x0516D0", "0x051964"),
            ("0x05164C", "0x0518E0"),
            ("0x051814", "0x051AA8"),
            ("0x051622", "0x0518B6"),
            ("0x05168E", "0x051922"),
            ("0x05169E", "0x051932"),
            ("0x05163C", "0x0518D0"),
        )
        for first, second in pairs:
            with self.subTest(first=first, second=second):
                common = set(self.audit[first]["basis"]) & set(self.audit[second]["basis"])
                self.assertEqual(1, len(common))
                review = self.reviews[common.pop()]
                self.assertEqual([first, second], [member["address"] for member in review["members"]])
                self.assertEqual(
                    [self.audit[first]["current_name"], self.audit[second]["current_name"]],
                    [member["current_name"] for member in review["members"]],
                )

    def test_wait_and_input_paths_are_genuinely_parallel(self) -> None:
        for source_path, subtype, viewer in (
            (SECONDARY, "3F0", "Secondary"),
            (TERTIARY, "3F4", "Tertiary"),
        ):
            source = source_path.read_text(encoding="utf-8")
            with self.subTest(viewer=viewer):
                wait = instructions(
                    source,
                    f"Debug_ValkirieType{subtype}UpdateWaitFlag",
                    f"Debug_ValkirieType{subtype}WaitReturn:",
                )
                self.assertIn("tst.w   (MessageSequenceState).w", wait)
                self.assertIn(f"bne.s   Debug_ValkirieType{subtype}WaitReturn", wait)
                self.assertIn("move.b  #1,(SceneSequenceFlags).w", wait)
                update = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerUpdate",
                    f"Debug_Valkirie{viewer}ViewerAdvancePoseAndRender:",
                )
                self.assertIn("btst    #2,(ControllerHeldState).w", update)
                self.assertIn("btst    #3,(ControllerHeldState).w", update)
                self.assertIn("andi.w  #$1FE,$56(a5)", update)
                self.assertIn(f"lea     Debug_Valkirie{viewer}ViewerPoseScript(pc),a1", update)
                reader = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerReadNextPoseCommand",
                    f"Debug_Valkirie{viewer}ViewerTickPoseInterpolation:",
                )
                self.assertIn("cmpi.b  #$80,(a1,d0.w)", reader)
                self.assertIn("cmpi.w  #$FFFE,d3", reader)
                self.assertIn("cmpi.w  #$FFFF,d3", reader)

    def test_pose_loop_and_timed_command_paths_keep_distinct_bases(self) -> None:
        for source_path, viewer in (
            (SECONDARY, "Secondary"),
            (TERTIARY, "Tertiary"),
        ):
            source = source_path.read_text(encoding="utf-8")
            with self.subTest(viewer=viewer):
                prepare = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerPreparePoseUpdate",
                    f"Debug_Valkirie{viewer}ViewerAdvancePoseAndRender:",
                )
                self.assertIn("andi.w  #$1FE,$56(a5)", prepare)
                self.assertIn(
                    f"lea     Debug_Valkirie{viewer}ViewerPoseScript(pc),a1",
                    prepare,
                )
                loop = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerHandlePoseLoopCommand",
                    f"Debug_Valkirie{viewer}ViewerBeginPoseCommandInterpolation:",
                )
                self.assertIn("cmpi.w  #$FFFF,d3", loop)
                self.assertIn("clr.w   $58(a5)", loop)
                self.assertIn("clr.w   $29C(a5)", loop)
                self.assertIn(
                    f"bra.s   Debug_Valkirie{viewer}ViewerReadNextPoseCommand",
                    loop,
                )
                timed = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerBeginPoseCommandInterpolation",
                    f"Debug_Valkirie{viewer}ViewerTickPoseInterpolation:",
                )
                self.assertIn("move.w  d3,(PoseCommandWord).w", timed)
                self.assertIn("andi.w  #$FF,d3", timed)
                self.assertIn(
                    f"addi.l  #Debug_Valkirie{viewer}ViewerPoseTargets,d0",
                    timed,
                )
                self.assertIn("move.b  (PoseDurationByte).w,d0", timed)
                self.assertIn("addq.w  #4,$58(a5)", timed)
                self.assertIn("addq.w  #1,$29C(a5)", timed)

    def test_tick_uses_nineteen_channels_and_traversal_count_is_26(self) -> None:
        advance = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        self.assertIn("dbf     d7,Anim_AdvancePoseChannelInterpolationNextChannel", advance)
        self.assertIn("move.w  d7,(MetaspritePartCountM1).w", advance)
        self.assertIn("move.w  (MetaspritePartCountM1).w,d7", advance)
        self.assertIn("addq.w  #1,d7", advance)
        for source_path, viewer in (
            (SECONDARY, "Secondary"),
            (TERTIARY, "Tertiary"),
        ):
            source = source_path.read_text(encoding="utf-8")
            with self.subTest(viewer=viewer):
                tick = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerTickPoseInterpolation",
                    f"Debug_Valkirie{viewer}ViewerStorePoseComponents:",
                )
                self.assertIn("subq.w  #1,$C(a5)", tick)
                self.assertIn("moveq   #$12,d7", tick)
                self.assertIn("jsr     (Anim_AdvancePoseChannelInterpolation).l", tick)
                traversal = instructions(
                    source,
                    f"Debug_Valkirie{viewer}ViewerAdvancePoseAndRender",
                    f"; End of function Debug_Valkirie{viewer}ViewerUpdate",
                )
                self.assertIn("moveq   #$19,d7", traversal)
                self.assertIn("jmp     Sprite_BeginMetaspritePartTraversal", traversal)
                self.assertIn("nineteen channels for linked-part angles", source)

    def test_both_target_tables_are_two_18_byte_records(self) -> None:
        secondary = SECONDARY.read_text(encoding="utf-8")
        tertiary = TERTIARY.read_text(encoding="utf-8")
        first = data_bytes(secondary, "Debug_ValkirieSecondaryViewerPoseTargets", "dc.w")
        second = data_bytes(tertiary, "Debug_ValkirieTertiaryViewerPoseTargets", "dc.b")
        self.assertEqual(36, 0x051842 - 0x05181E)
        self.assertEqual(36, 0x051AD6 - 0x051AB2)
        self.assertEqual(36, len(first))
        self.assertEqual(first, second)
        self.assertEqual(first[:18], first[18:])
        for source, viewer in (
            (secondary, "Secondary"),
            (tertiary, "Tertiary"),
        ):
            script = source.split(f"Debug_Valkirie{viewer}ViewerPoseScript:", 1)[1].splitlines()[0]
            self.assertIn("$20, $20, 0, 0, $20, $20, 0, $12, $FF, $FF", script)
            target_basis = self.audit["0x05181E" if viewer == "Secondary" else "0x051AB2"]["basis"][0]
            self.assertIn("18-byte target records", target_basis)
            self.assertIn("nineteen-byte delta-reader", target_basis)
            self.assertIn(f"addi.l  #Debug_Valkirie{viewer}ViewerPoseTargets,d0", source)
            self.assertIn("movea.l d0,a0", source)
            self.assertIn("moveq   #$12,d7", source)
        delta = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        delta_reader = instructions(
            delta,
            "Anim_CalculatePoseChannelDeltas",
            "; End of function Anim_CalculatePoseChannelDeltas",
        )
        self.assertIn("move.b  (a0)+,d0", delta_reader)
        self.assertIn("dbf     d7,Anim_CalculatePoseChannelDeltasNextChannel", delta_reader)


if __name__ == "__main__":
    unittest.main()
