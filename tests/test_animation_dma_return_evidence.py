"""Check exact branch, animation-stream, and DMA-terminal evidence."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def block(source: str, start: str, end: str) -> str:
    return source.split(start, 1)[1].split(end, 1)[0]


class AnimationDMAReturnEvidenceTests(unittest.TestCase):
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

    def test_missiray_streams_have_distinct_installers_and_frames(self) -> None:
        data = (ROOT / "src/data/shield_viper_and_missiray_mappings.s").read_text(encoding="utf-8")
        states = (ROOT / "src/projectiles/missiray_and_rising_shots.s").read_text(encoding="utf-8")
        resolver = (ROOT / "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
        streams = (
            (
                "0x0ED13E",
                "Projectile_MissirayBulletLoopSpriteAnimation",
                "Projectile_MissirayBulletWaitForTransformFrame",
                ("Frame01", "Frame02", "Frame04", "Frame03"),
            ),
            (
                "0x0ED152",
                "Projectile_MissirayBulletInitialSpriteAnimation",
                "Projectile_InitMissirayBullet",
                ("Frame00",),
            ),
            (
                "0x0ED156",
                "Projectile_MissirayBulletTransformSpriteAnimation",
                "Projectile_MissirayBulletTransform",
                ("Frame00", "Frame10", "Frame05", "Frame06", "Frame07", "Frame08", "Frame09"),
            ),
        )
        bases = []
        for index, (address, stream, installer, frame_suffixes) in enumerate(streams):
            with self.subTest(stream=stream):
                row = self.audit[address]
                self.assertEqual(stream, row["current_name"])
                bases.append(row["basis"][0])
                self.assertIn(f"#{stream},8(a", states)
                self.assertIn(installer + ":", states)
                next_stream = streams[index + 1][1] if index < 2 else ""
                stream_data = (
                    block(data, stream + ":", next_stream + ":") if next_stream else data.split(stream + ":", 1)[1]
                )
                for suffix in frame_suffixes:
                    self.assertIn("Projectile_MissirayBulletSprite" + suffix + "-*", stream_data)
        self.assertEqual(3, len(set(bases)))
        self.assertIn("dc.w    Projectile_MissirayBulletLoopSpriteAnimation-*", data)
        self.assertIn("cmpi.w  #$80,$C(a5)", states)
        self.assertIn("tst.b   d0", resolver)
        self.assertIn("bmi.s   Anim_ResolveTimedMappingFrame_ResolveMappingPointer", resolver)

    def test_dma_finish_blocks_are_identical_but_parsers_differ(self) -> None:
        source = (ROOT / "src/rendering/dma_queue.s").read_text(encoding="utf-8")
        basis = (
            "A 0xFF marker flushes the final DMA length and publishes the "
            "updated command-queue head and staging-data cursor."
        )
        review = self.reviews[basis]
        expected = (
            ("0x001DA2", "Gfx_QueueHeaderedByteStreamDMA_FinishStream"),
            ("0x001E1C", "Gfx_QueueByteStreamDMA_FinishStream"),
        )
        self.assertEqual([address for address, _ in expected], [member["address"] for member in review["members"]])
        operations = []
        for address, name in expected:
            with self.subTest(name=name):
                self.assertEqual([basis], self.audit[address]["basis"])
                self.assertEqual(name, self.audit[address]["current_name"])
                finish = block(source, name + ":", "; End of function ")
                operations.append(
                    [line.strip() for line in finish.splitlines() if line.strip().startswith(("move.", "rts"))]
                )
                self.assertIn(f"beq.s   {name}", source)
        self.assertEqual(operations[0], operations[1])
        self.assertEqual(
            [
                "move.l  d1,-(a1)",
                "move.w  a1,(VDPCommandQueueHead).w",
                "move.w  a2,(VDPStagingDataCursor).w",
                "rts",
            ],
            operations[0],
        )
        self.assertIn("move.w  (a0)+,d0", source)
        self.assertIn("Gfx_QueueByteStreamDMA_BeginRecord:", source)

    def test_gravity_returns_state_exact_gate_and_context(self) -> None:
        source = (ROOT / "src/actors/shared_object_helpers.s").read_text(encoding="utf-8")
        entries = (
            ("0x02A7F4", "Physics_ApplyGravity", "$2000"),
            ("0x02A822", "Projectile_FallWithGravity", "$3000"),
            ("0x02A8B8", "Projectile_FallingDebris", "$4000"),
        )
        bases = []
        for address, routine, increment in entries:
            with self.subTest(routine=routine):
                section = block(source, routine + ":", "; End of function " + routine)
                return_name = self.audit[address]["current_name"]
                self.assertIn(return_name + ":", section)
                self.assertIn("addi.l  #" + increment + ",$1C(a5)", section)
                self.assertIn("cmpi.w  #$80,$C(a5)", section)
                self.assertIn("bmi.s   " + return_name, section)
                self.assertIn("move.w  #$1000,2(a5)", section)
                bases.append(self.audit[address]["basis"][0])
        self.assertEqual(3, len(set(bases)))

    def test_bird_and_fish_acceleration_returns_are_not_one_role(self) -> None:
        bird = (ROOT / "src/enemies/bird_enemy.s").read_text(encoding="utf-8")
        fish = (ROOT / "src/enemies/stage_11_fish.s").read_text(encoding="utf-8")
        bird_state = block(
            bird,
            "Enemy_BirdAccelerateDownwardState:",
            "; End of function Enemy_BirdAccelerateDownwardState",
        )
        self.assertIn("addi.l  #$4000,$1C(a5)", bird_state)
        self.assertIn("cmpi.l  #$28000,$1C(a5)", bird_state)
        self.assertIn("blt.s   Enemy_BirdAccelerateDownwardState_Return", bird_state)
        for routine in (
            "Enemy_Stage11FishAccelerateInwardState",
            "Enemy_Stage11FishAccelerateOutwardState",
        ):
            section = block(fish, routine + ":", "; End of function " + routine)
            self.assertIn("btst    #3,$E(a5)", section)
            self.assertIn("cmpi.l  #$60000,$18(a5)", section)
            self.assertIn("cmpi.l  #$FFFA0000,$18(a5)", section)
            self.assertIn("addq.w  #2,4(a5)", section)
            self.assertIn(routine + "_Return:", section)
        bases = [self.audit[address]["basis"][0] for address in ("0x02DD2C", "0x02EDD6", "0x02EE7E")]
        self.assertEqual(3, len(set(bases)))

    def test_digit_queue_tails_share_cursor_publishing(self) -> None:
        basis = (
            "The tail prepends the VDP auto-increment and DMA-length words, then publishes both updated queue cursors."
        )
        self.assertEqual(
            ["0x001EA8", "0x001F4A"],
            [member["address"] for member in self.reviews[basis]["members"]],
        )
        source = (ROOT / "src/rendering/dma_queue.s").read_text(encoding="utf-8")
        for radix in ("Decimal", "Hex"):
            with self.subTest(radix=radix):
                owner = f"Gfx_Queue{radix}DigitsDMA"
                tail = block(
                    source,
                    owner + "_FinalizeQueue:",
                    "; End of function " + owner,
                )
                for instruction in (
                    "move.w  #$8F02,-(a1)",
                    "move.l  #$94009300,d2",
                    "add.b   d3,d2",
                    "move.l  d2,-(a1)",
                    "move.w  a1,(VDPCommandQueueHead).w",
                    "move.w  a2,(VDPStagingDataCursor).w",
                ):
                    self.assertIn(instruction, tail)

    def test_zero_stream_variants_check_markers_before_staging_zero(self) -> None:
        basis = (
            "The zero-fill entry reaches this path for every non-marker byte "
            "and appends a zero word while incrementing the DMA word count."
        )
        self.assertEqual(
            ["0x001D8E", "0x001E08"],
            [member["address"] for member in self.reviews[basis]["members"]],
        )
        source = (ROOT / "src/rendering/dma_queue.s").read_text(encoding="utf-8")
        for prefix, zero_entry in (
            ("Gfx_QueueHeaderedByteStreamDMA", "Gfx_QueueHeaderedZeroStreamDMA"),
            ("Gfx_QueueByteStreamDMA", "Gfx_QueueZeroStreamDMA"),
        ):
            with self.subTest(prefix=prefix):
                wrapper = block(source, zero_entry + ":", "; End of function " + zero_entry)
                read = block(source, prefix + "_ReadByte:", prefix + "_StageZero:")
                stage = block(source, prefix + "_StageZero:", prefix + "_FinishRecord:")
                self.assertIn("clr.b   d3", wrapper)
                self.assertIn("cmpi.b  #$FE,d0", read)
                self.assertIn("cmpi.b  #$FF,d0", read)
                self.assertIn("tst.b   d3", read)
                self.assertIn(f"beq.s   {prefix}_StageZero", read)
                self.assertIn("clr.w   (a2)+", stage)
                self.assertIn("addq.b  #1,d1", stage)
                self.assertIn(f"bra.s   {prefix}_ReadByte", stage)

    def test_headered_and_headerless_byte_streams_share_marker_dispatch(self) -> None:
        basis = (
            "This loop reads one source byte, dispatches 0xFE and 0xFF markers, "
            "and otherwise stages either the byte or a zero word according to "
            "the entry mode."
        )
        self.assertEqual(
            ["0x001D76", "0x001DF0"],
            [member["address"] for member in self.reviews[basis]["members"]],
        )
        source = (ROOT / "src/rendering/dma_queue.s").read_text(encoding="utf-8")
        for prefix in ("Gfx_QueueHeaderedByteStreamDMA", "Gfx_QueueByteStreamDMA"):
            with self.subTest(prefix=prefix):
                reader = block(source, prefix + "_ReadByte:", prefix + "_StageZero:")
                self.assertIn("move.b  (a0)+,d0", reader)
                self.assertIn("cmpi.b  #$FE,d0", reader)
                self.assertIn(f"beq.s   {prefix}_FinishRecord", reader)
                self.assertIn("cmpi.b  #$FF,d0", reader)
                self.assertIn(f"beq.s   {prefix}_FinishStream", reader)
                self.assertIn("tst.b   d3", reader)
                self.assertIn(f"beq.s   {prefix}_StageZero", reader)
                self.assertIn("move.w  d0,(a2)+", reader)
        headered = block(
            source,
            "Gfx_QueueHeaderedByteStreamDMA_BeginRecord:",
            "Gfx_QueueHeaderedByteStreamDMA_ReadByte:",
        )
        headerless = block(
            source,
            "Gfx_QueueByteStreamDMA_BeginRecord:",
            "Gfx_QueueByteStreamDMA_ReadByte:",
        )
        self.assertIn("move.w  (a0)+,d0", headered)
        self.assertNotIn("move.w  (a0)+,d0", headerless)


if __name__ == "__main__":
    unittest.main()
