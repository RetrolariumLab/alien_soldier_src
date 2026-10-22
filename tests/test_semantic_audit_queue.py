from __future__ import annotations

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "config/name_audit.json"
sys.path.insert(0, str(ROOT / "scripts"))

import semantic_audit_queue  # noqa: E402


class SemanticAuditQueueTests(unittest.TestCase):
    def test_medusa_and_sirene_roots_dispatchers_and_tables_have_separate_evidence(self) -> None:
        records = {item["address"]: item for item in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cases = (
            ("Medusa", "src/bosses/medusa.s", ("0x05699C", "0x0569E0", "0x0569F0")),
            ("Sirene", "src/bosses/sirene.s", ("0x057498", "0x0574E8", "0x0574F8")),
        )
        all_bases = []
        for owner, path, addresses in cases:
            with self.subTest(owner=owner):
                root_name = f"Boss_Update{owner}"
                dispatch_name = f"Boss_Dispatch{owner}State"
                table_name = f"Boss_{owner}StateOffsets"
                entries = [records[address] for address in addresses]
                self.assertEqual(
                    [root_name, dispatch_name, table_name],
                    [entry["current_name"] for entry in entries],
                )
                self.assertTrue(all(len(entry["basis"]) == 1 for entry in entries))
                all_bases.extend(entry["basis"][0] for entry in entries)

                source = (ROOT / path).read_text(encoding="utf-8")
                root = source.split(root_name + ":", 1)[1].split(dispatch_name + ":", 1)[0]
                dispatch = source.split(dispatch_name + ":", 1)[1].split("; End of function " + root_name, 1)[0]
                table = source.split(table_name + ":", 1)[1].split(f"Boss_Init{owner}State0:", 1)[0]
                self.assertIn(f"beq.w   {dispatch_name}", root)
                self.assertIn(f"beq.s   {dispatch_name}", root)
                self.assertIn("tst.w   (BossHealth).w", root)
                self.assertIn("jmp     Boss_QueueSevenForcesPostBattleTransition", root)
                self.assertIn("jsr     (Gfx_UpdateBossPaletteColorFade).l", root)
                self.assertNotIn("BossHealth", dispatch)
                self.assertNotIn("Gfx_UpdateBossPaletteColorFade", dispatch)
                self.assertIn("move.w  4(a5),d0", dispatch)
                self.assertIn(f"movea.w {table_name}(pc,d0.w),a0", dispatch)
                self.assertIn(f"adda.l  #Boss_Init{owner}State0,a0", dispatch)
                self.assertIn("jmp     (a0)", dispatch)
                targets = re.findall(
                    rf"\bdc\.w\s+(Boss_(?:Init|Update){owner}State[0-9A-F]+)"
                    rf"-Boss_Init{owner}State0",
                    table,
                )
                self.assertEqual(
                    list(range(0, 0x16, 2)),
                    [int(re.search(r"State([0-9A-F]+)$", target).group(1), 16) for target in targets],
                )
                if owner == "Medusa":
                    self.assertIn("bsr.w   Entity_UpdateMedusaScriptedSpawnSequence", root)
                else:
                    self.assertIn("move.b  #$C1,d0", root)
                    self.assertIn("bclr    #7,(PlayerRestrictionFlags).w", root)
        self.assertEqual(6, len(set(all_bases)))

    def test_stage_configuration_reviews_pin_record_layout_and_dispatch(self) -> None:
        reviews = {
            item["basis"]: item
            for item in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        normal = reviews[
            "A stage-specific initializer or graphics path selects this exact "
            "30-byte record address before Stage_ApplyConfigurationRecord consumes "
            "its fixed fields and palette-list pointer."
        ]
        variants = reviews["Only the adjacent unreferenced Stage 20 variant wrapper selects this 30-byte record."]
        normal_cases = (
            ("0x0127A8", "Stage1ConfigRecord", "Stage_ApplyStage1Configuration", 0),
            ("0x0127C6", "Stage2ConfigRecord", "Stage_ApplyStage2Configuration", 1),
            ("0x01287A", "Stage8ConfigRecord", "Stage_InitializeStage8", 7),
        )
        variant_cases = tuple(
            (
                f"0x{address:06X}",
                f"UnreferencedStage20Variant{index}ConfigRecord",
                f"UnreferencedApplyStage20Variant{index}Configuration",
                offset,
            )
            for index, (address, offset) in enumerate(
                zip((0x129E2, 0x12A00, 0x12A1E, 0x12A3C), ("$28", "$30", "$38", "$40")),
                start=1,
            )
        )
        for review, cases in ((normal, normal_cases), (variants, variant_cases)):
            self.assertEqual(
                [(address, name, "src/stages/configuration_records.s") for address, name, _, _ in cases],
                [(item["address"], item["current_name"], item["file"]) for item in review["members"]],
            )

        source = (ROOT / "src/stages/configuration.s").read_text(encoding="utf-8")
        records = (ROOT / "src/stages/configuration_records.s").read_text(encoding="utf-8")
        dispatch = source.split("Stage_InitializerOffsets:", 1)[1].split("; Clears the four per-slot", 1)[0]
        slots = re.findall(r"\bdc\.w\s+(\w+)-Weapon_ClearAmmoRegenTimers", dispatch)
        self.assertEqual(26, len(slots))
        self.assertEqual("Stage_InitializeStage20", slots[19])
        self.assertIn("move.w  (StageTableIndex).w,d0", source)
        self.assertIn("movea.w Stage_InitializerOffsets(pc,d0.w),a0", source)
        self.assertIn("jmp     Gfx_LoadMultiplePalettes", records)
        for _, name, wrapper, slot in normal_cases:
            with self.subTest(name=name):
                self.assertEqual(wrapper, slots[slot])
                body = source.split(wrapper + ":", 1)[1].split("; End of function " + wrapper, 1)[0]
                self.assertIn(f"lea     {name}(pc),a0", body)
                self.assertRegex(body, r"(?:bsr|bra)\.w\s+Stage_ApplyConfigurationRecord")
        for _, name, wrapper, offset in variant_cases:
            with self.subTest(name=name):
                self.assertNotIn(wrapper, slots)
                body = source.split(wrapper + ":", 1)[1].split("; End of function " + wrapper, 1)[0]
                self.assertIn(f"lea     {name}(pc),a0", body)
                self.assertNotIn("Stage20ConfigRecord(pc)", body)
                if wrapper.endswith("Variant2Configuration"):
                    self.assertIn("bsr.w   Stage_ApplyConfigurationRecord", body)
                    self.assertIn("move.w  d1,(a3)+", body)
                else:
                    self.assertRegex(
                        body,
                        r"bra\.[sw]\s+UnreferencedApplyStage20VariantAndFillWordRanges",
                    )

        source_code = "\n".join(
            re.sub(r";[^\n]*", "", path.read_text(encoding="utf-8")) for path in (ROOT / "src").rglob("*.s")
        )
        for _, name, wrapper, _ in variant_cases:
            self.assertEqual(2, len(re.findall(rf"\b{re.escape(name)}\b", source_code)))
            self.assertEqual(1, len(re.findall(rf"\b{re.escape(wrapper)}\b", source_code)))

        for _, name, _, expected_offset in (*normal_cases, *variant_cases):
            with self.subTest(record=name):
                block = re.search(rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_]\w*:|\Z)", records)
                self.assertIsNotNone(block)
                declarations = re.findall(r"(?m)^\s*dc\.(b|w|l)\s+([^;\r\n]+)", block.group(1))
                size = sum({"b": 1, "w": 2, "l": 4}[kind] * len(operands.split(",")) for kind, operands in declarations)
                self.assertEqual(30, size)
                if isinstance(expected_offset, str):
                    self.assertRegex(
                        block.group(1),
                        rf"^\s*dc\.w\s+{re.escape(expected_offset)}\b",
                    )
                    self.assertIn(
                        "dc.l    UnreferencedStage20VariantPaletteOffsetList",
                        block.group(1),
                    )
        self.assertIn("lea     Stage20ConfigRecord(pc),a0", source)

    def test_ui_palette_reset_entries_do_not_share_one_routine_claim(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        names = (
            "UI_ResetPaletteAndMessageMode",
            "UI_ResetPaletteAndMessageMode_Clear",
            "UI_ClearPaletteBuffers_Loop",
        )
        entries = [records[address] for address in ("0x01CDB4", "0x01CDB8", "0x01CDC0")]
        self.assertEqual(list(names), [entry["current_name"] for entry in entries])
        self.assertEqual(3, len({entry["basis"][0] for entry in entries}))
        self.assertTrue(all(len(entry["basis"]) == 1 for entry in entries))

        source = (ROOT / "src/system/game_variables.s").read_text(encoding="utf-8")
        root = source.split(names[0] + ":", 1)[1].split(names[1] + ":", 1)[0]
        clear = source.split(names[1] + ":", 1)[1].split(names[2] + ":", 1)[0]
        loop = source.split(names[2] + ":", 1)[1].split("; End of function UI_ResetPaletteAndMessageMode", 1)[0]
        self.assertIn("bsr.w   Stage_LoadTimeLimit", root)
        self.assertNotIn("Stage_LoadTimeLimit", clear)
        for instruction in (
            "movea.w #(PaletteActiveBuffer-M68K_RAM),a0",
            "moveq   #0,d0",
            "moveq   #$3F,d7",
        ):
            self.assertIn(instruction, clear)
            self.assertNotIn(instruction, loop)
        self.assertIn("move.l  d0,(a0)+", loop)
        self.assertIn("dbf     d7,UI_ClearPaletteBuffers_Loop", loop)
        self.assertIn("move.w  #4,(MessageMode).w", loop)
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        self.assertRegex(ram, r"PaletteActiveBuffer\s+equ\s+\$FFFFE300")
        self.assertRegex(ram, r"PaletteShadowBuffer\s+equ\s+\$FFFFE380")

    def test_tilemap_transfer_descriptors_cover_direct_and_queued_consumers(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        descriptors = (ROOT / "src/rendering/boss_asset_sets.s").read_text(encoding="utf-8")
        entry = (ROOT / "src/stages/gameplay_entry_states.s").read_text(encoding="utf-8")
        cases = (
            (
                "0x011316",
                "Gfx_TitleAndZLeoVRAMTransferParameters",
                ("$FFFF7000", "$FFFF6000", "$FFFF4000", "$14000"),
                "src/ui/title_screen.s",
            ),
            (
                "0x011326",
                "Gfx_DefaultVRAMTransferParameters",
                ("$FFFF7000", "$FFFF6000", "$FFFF4000", "$4000"),
                "src/cutscenes/ending_sequence_credits.s",
            ),
            (
                "0x011336",
                "Gfx_FrontendAlternateVRAMTransferParameters",
                ("$FFFF7000", "$FFFF6800", "$FFFF2000", "$6000"),
                "src/ui/options_menu_controllers.s",
            ),
            (
                "0x011346",
                "Gfx_ScrollVRAMTransferParameters",
                ("$FFFF7000", "$FFFF6000", "$FFFF4000", "$6000"),
                "src/credits/main.s",
            ),
        )
        bases = []
        for address, name, values, direct_path in cases:
            with self.subTest(address=address):
                record = records[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                declaration = re.search(rf"(?m)^{name}:\s+dc\.l\s+([^;\n]+)", descriptors)
                self.assertIsNotNone(declaration)
                self.assertEqual(values, tuple(word.strip() for word in declaration.group(1).split(",")))
                direct = (ROOT / direct_path).read_text(encoding="utf-8")
                self.assertRegex(
                    direct,
                    rf"{name}[\s\S]{{0,500}}"
                    r"jsr\s+\(Tilemap_TransferFullMapDirectToVRAM\)\.l",
                )
                self.assertIn(f"dc.l    {name}", entry)
        self.assertEqual(4, len(set(bases)))
        primary_column = (ROOT / "src/rendering/tilemap_column_streaming.s").read_text(encoding="utf-8")
        secondary_row = (ROOT / "src/rendering/tilemap_row_streaming.s").read_text(encoding="utf-8")
        scroll = (ROOT / "src/rendering/camera_tracking_and_stage_scroll.s").read_text(encoding="utf-8")
        self.assertIn("lea     Gfx_TitleAndZLeoVRAMTransferParameters(pc),a0", primary_column)
        self.assertIn("lea     Gfx_FrontendAlternateVRAMTransferParameters(pc),a0", secondary_row)
        self.assertIn("lea     Gfx_ScrollVRAMTransferParameters(pc),a0", scroll)
        self.assertIn("jmp     Tilemap_QueueRowFromDescriptor(pc)", scroll)
        self.assertIn("jmp     Tilemap_QueueColumnFromDescriptor(pc)", scroll)

    def test_scroll_dma_pointer_fields_are_not_scroll_buffers(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        reset = (ROOT / "src/system/game_initialization.s").read_text(encoding="utf-8")
        clear = (ROOT / "src/system/memory_initialization.s").read_text(encoding="utf-8")
        writers = (ROOT / "src/rendering/scroll_plane_buffers.s").read_text(encoding="utf-8")
        dma = (ROOT / "src/rendering/palette_fades.s").read_text(encoding="utf-8")
        cases = (
            (
                "HScrollBuffer",
                0xFFE400,
                "HScrollDMASource",
                0xFFF710,
                "Gfx_QueueHorizontalScrollDMA",
                "#$70000083",
                1,
                "#$940193C0",
            ),
            (
                "VScrollBuffer",
                0xFFEC00,
                "VScrollDMASource",
                0xFFF714,
                "Gfx_QueueVerticalScrollDMA",
                "#$40000090",
                2,
                "#$94009328",
            ),
        )
        bases = []
        for buffer, buffer_addr, pointer, pointer_addr, routine, destination, bit, long_length in cases:
            with self.subTest(buffer=buffer):
                for address, name in ((buffer_addr, buffer), (pointer_addr, pointer)):
                    record = records[f"0x{address:06X}"]
                    self.assertEqual(name, record["current_name"])
                    self.assertEqual(2, len(record["basis"]))
                    bases.extend(record["basis"])
                    self.assertRegex(
                        ram,
                        rf"(?m)^{name}\s+equ\s+\$FFFF{address & 0xFFFF:04X}\b",
                    )
                self.assertIn(f"move.l  #{buffer},({pointer}).w", reset)
                self.assertIn(f"lea     ({buffer}).w,a0", clear)
                self.assertIn(f"movea.w #({buffer}-M68K_RAM),a0", writers)
                body = dma.split(routine + ":", 1)[1].split("; End of function " + routine, 1)[0]
                self.assertIn(f"move.l  ({pointer}).w,d0", body)
                self.assertIn(f"move.l  {destination},-(a0)", body)
                self.assertIn(f"btst    #{bit},(VDPReg11Shadow+1).w", body)
                self.assertIn("move.l  #$94009302,-(a0)", body)
                self.assertIn(f"move.l  {long_length},-(a0)", body)
        self.assertEqual(8, len(set(bases)))

    def test_options_choice_labels_stop_at_the_first_terminator(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("Direct references from the options/frontend renderer")
        )
        path = "src/ui/options_shared_helpers_and_assets.s"
        expected = (
            (0x00A220, "Options_OnLabelTiles", 4),
            (0x00A22A, "Options_OffLabelTiles", 3),
            (0x00A232, "Options_SuperEasyLabelTiles", 10),
            (0x00A248, "Options_SuperHardLabelTiles", 9),
        )
        self.assertEqual(
            [(f"0x{address:06X}", name, path) for address, name, _ in expected],
            [(member["address"], member["current_name"], member["file"]) for member in review["members"]],
        )
        source = (ROOT / path).read_text(encoding="utf-8")
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        for address, name, glyph_count in expected:
            with self.subTest(label=name):
                line = next(line for line in source.splitlines() if line.startswith(name + ":"))
                words = [word.strip() for word in re.search(r"\bdc\.w\s+([^;]+)", line).group(1).split(",")]
                self.assertEqual(["$FFFF"], words[glyph_count:])
                self.assertEqual(name, records[f"0x{address:06X}"]["current_name"])
                self.assertEqual(2, len(records[f"0x{address:06X}"]["basis"]))
        hard_run = source.split("Options_SuperHardLabelTiles:", 1)[1].split("Options_VoiceTestRequestIDs:", 1)[0]
        rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", hard_run)
        words = [word.strip() for row in rows for word in row.split(",")]
        self.assertEqual(30, len(words))
        self.assertEqual([9, 17, 29], [i for i, word in enumerate(words) if word == "$FFFF"])
        ui = (ROOT / "src/ui/options_menu_controllers.s").read_text(encoding="utf-8")
        for handler in ("UI_UpdateMessageOption", "UI_UpdateBGMOption", "UI_UpdateSFXOption"):
            body = ui.split(handler + ":", 1)[1].split("; End of function " + handler, 1)[0]
            self.assertIn("lea     Options_OnLabelTiles(pc),a1", body)
            self.assertIn("lea     Options_OffLabelTiles(pc),a2", body)
        difficulty = ui.split("UI_UpdateDifficultyOption:", 1)[1].split(
            "; End of function UI_UpdateDifficultyOption", 1
        )[0]
        self.assertIn("lea     Options_SuperEasyLabelTiles(pc),a1", difficulty)
        self.assertIn("lea     Options_SuperHardLabelTiles(pc),a2", difficulty)
        toggle = source.split("Options_ApplyToggleAndQueueLabels:", 1)[1].split(
            "; End of function Options_UpdateBit2Toggle", 1
        )[0]
        for instruction in (
            "move.w  (a1)+,d0",
            "beq.s   Options_CopySecondToggleLabel",
            "move.w  (a2)+,d0",
            "beq.s   Options_BeginToggleBottomRow",
        ):
            self.assertIn(instruction, toggle)

    def test_valkirie_velocity_and_seven_forces_palette_evidence_is_local(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        expected = {
            "0x0568AC": "Entity_AdjustValkirieAuxiliaryNegativeVerticalVelocity",
            "0x0568BC": "Entity_AdjustValkirieAuxiliaryHorizontalVelocity",
            "0x0568D2": "Entity_AdjustValkirieAuxiliaryNegativeHorizontalVelocity",
            "0x056942": "Gfx_UpdateSevenForcesBattlePalette",
            "0x05695E": "Gfx_ApplySevenForcesBattleFlashPalette",
            "0x056972": "SevenForces_BattleFlashPaletteColors",
        }
        self.assertEqual(
            expected,
            {address: records[address]["current_name"] for address in expected},
        )
        self.assertEqual(6, len({tuple(records[address]["basis"]) for address in expected}))
        source = (ROOT / "src/bosses/valkirie_rendering.s").read_text(encoding="utf-8")
        velocity_cases = (
            (
                expected["0x0568AC"],
                expected["0x0568BC"],
                (
                    "add.l   d0,$1FC(a5)",
                    "bpl.s   Entity_AdjustValkirieAuxiliaryHorizontalVelocity",
                    "cmp.l   $1FC(a5),d2",
                    "move.l  d2,$1FC(a5)",
                ),
            ),
            (
                expected["0x0568BC"],
                expected["0x0568D2"],
                (
                    "tst.l   d3",
                    "bmi.s   Entity_AdjustValkirieAuxiliaryNegativeHorizontalVelocity",
                    "add.l   d1,$1F8(a5)",
                    "cmp.l   $1F8(a5),d3",
                    "move.l  d3,$1F8(a5)",
                ),
            ),
            (
                expected["0x0568D2"],
                "Entity_UpdateValkirieAuxiliaryGroupReturn",
                ("add.l   d1,$1F8(a5)", "cmp.l   $1F8(a5),d3", "move.l  d3,$1F8(a5)"),
            ),
        )
        for name, next_name, instructions in velocity_cases:
            block = source.split(name + ":", 1)[1].split(next_name + ":", 1)[0]
            for instruction in instructions:
                self.assertIn(instruction, block)
        palette = source.split("Gfx_UpdateSevenForcesBattlePalette:", 1)[1].split(
            "SevenForces_BattleFlashPaletteColors:", 1
        )[0]
        self.assertIn("btst    #0,(FrameCounter+1).w", palette)
        self.assertIn("bne.s   Gfx_ApplySevenForcesBattleFlashPalette", palette)
        for index in (61, 62, 63):
            self.assertIn(
                f"(PaletteShadowColor{index}).w,(PaletteActiveColor{index}).w",
                palette,
            )
        for offset in ("", "+2", "+4"):
            self.assertIn(f"SevenForces_BattleFlashPaletteColors{offset}(pc,d0.w)", palette)
        table = source.split("SevenForces_BattleFlashPaletteColors:", 1)[1]
        words = [value.strip() for row in re.findall(r"\bdc\.w\s+([^;\r\n]+)", table) for value in row.split(",")]
        self.assertEqual(21, len(words))
        callers = (
            ("valkirie_battle.s", "0"),
            ("medusa.s", "6"),
            ("sirene.s", "$C"),
            ("artemis_core.s", "$12"),
            ("unidentified_seven_force.s", "$18"),
            ("valkirie_alternate.s", "$1E"),
            ("sylpheed_core.s", "$24"),
        )
        for filename, offset in callers:
            with self.subTest(caller=filename):
                caller = (ROOT / "src/bosses" / filename).read_text(encoding="utf-8")
                call = caller.index("Gfx_UpdateSevenForcesBattlePalette")
                preceding = caller[max(0, call - 150) : call]
                self.assertRegex(preceding, rf"moveq\s+#{re.escape(offset)},d0\b")
        self.assertIn("d0 is not computed from the frame count", records["0x05695E"]["basis"][0])

    def test_hblank_copy_lengths_are_windows_not_handler_extents(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        cases = (
            (
                "vblank_effects.s",
                0x001422,
                "WriteVScroll0",
                0x001424,
                "VBlank_InitStage2DemoVScrollEffect",
                0x001436,
                14,
            ),
            ("vblank_effects.s", 0x001532, "WriteVScroll2", 0x001534, "VBlank_InitSplitVScrollEffect", 0x001546, 14),
            (
                "vblank_effects.s",
                0x00159E,
                "WriteSplitVScroll2AndStop",
                0x0015A0,
                "VBlank_InitTransitionVScroll2Effect",
                0x0015BC,
                4,
            ),
            ("vblank_effects.s", 0x001948, "WriteCRAMColor5", 0x00194A, "VBlank_Epsilon1ScrollEffect", 0x00195C, 14),
            (
                "hblank_effects.s",
                0x001AD2,
                "WriteVDPControl",
                0x001AD4,
                "VBlank_InitDestroyerProtoVScrollEffect",
                0x001ADC,
                24,
            ),
        )
        for filename, length_addr, suffix, handler_addr, next_name, next_addr, spill in cases:
            with self.subTest(handler=suffix):
                source = (ROOT / "src/rendering" / filename).read_text(encoding="utf-8")
                prefix = "HBlank_" + suffix
                length_name = prefix + "_CopyLength"
                install_name = prefix + "_InstallList"
                self.assertEqual(length_name, records[f"0x{length_addr:06X}"]["current_name"])
                self.assertEqual(prefix, records[f"0x{handler_addr:06X}"]["current_name"])
                self.assertEqual(next_name, records[f"0x{next_addr:06X}"]["current_name"])
                self.assertIn(f"dc.l    {length_name}", source)
                self.assertRegex(source, re.escape(length_name) + r":\s+dc\.w\s+\$20")
                handler = source.split(prefix + ":", 1)[1].split(next_name + ":", 1)[0]
                self.assertIn("rte", handler)
                self.assertEqual(spill, 0x20 - (next_addr - handler_addr))
                self.assertIn("following ROM bytes are included", records[f"0x{length_addr:06X}"]["basis"][0])
                self.assertLess(
                    source.index(install_name + ":"),
                    source.index(length_name + ":"),
                )
        loader = (ROOT / "src/gameplay/object_data.s").read_text(encoding="utf-8")
        function = loader.split("LoadFuncToRAM:", 1)[1].split("; End of function LoadFuncToRAM", 1)[0]
        for instruction in (
            "movea.l (a0)+,a1",
            "move.w  (a1)+,d1",
            "lsr.w   #2,d1",
            "subq.w  #1,d1",
            "move.l  (a1)+,(a2)+",
            "dbf     d1,Data_CopyFunctionLoop",
        ):
            self.assertIn(instruction, function)

    def test_missiray_indexed_transfer_reviews_pin_distinct_entry_paths(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        source_path = "src/bosses/missiray_core.s"
        source = (ROOT / source_path).read_text(encoding="utf-8")
        cases = (
            (
                "The routine loads its adjacent descriptor into a0",
                [
                    (0x053A3A, "Boss_MissirayLoadTileTransferSet00"),
                    (0x053A52, "Boss_MissirayLoadTileTransferSet01"),
                    (0x053A6A, "Boss_MissirayLoadTileTransferSet02"),
                ],
            ),
            (
                "The adjacent Missiray loader passes this word record",
                [
                    (0x053A46, "Boss_MissirayTileTransferSet00Descriptor"),
                    (0x053A5E, "Boss_MissirayTileTransferSet01Descriptor"),
                    (0x053A76, "Boss_MissirayTileTransferSet02Descriptor"),
                    (0x053B50, "Boss_MissirayTileTransferSet03Descriptor"),
                ],
            ),
            (
                "The routine passes its adjacent indexed-row descriptor directly",
                [
                    (0x053A90, "Boss_MissirayQueueIndexedRowSet00"),
                    (0x053AC4, "Boss_MissirayQueueIndexedRowSet02"),
                    (0x053AEC, "Boss_MissirayQueueIndexedRowSet03"),
                    (0x053B06, "Boss_MissirayQueueIndexedRowSet04"),
                    (0x053B20, "Boss_MissirayQueueIndexedRowSet05"),
                ],
            ),
        )
        for basis_start, expected in cases:
            review = next(item for item in reviews if item["basis"].startswith(basis_start))
            self.assertEqual(
                [(f"0x{address:06X}", name, source_path) for address, name in expected],
                [(member["address"], member["current_name"], member["file"]) for member in review["members"]],
            )

        for index in range(3):
            loader = f"Boss_MissirayLoadTileTransferSet{index:02d}"
            descriptor = f"Boss_MissirayTileTransferSet{index:02d}Descriptor"
            body = source.split(loader + ":", 1)[1].split(descriptor + ":", 1)[0]
            self.assertIn(f"lea     {descriptor}(pc),a0", body)
            self.assertIn("jmp     Tilemap_QueueIndexedColumns", body)
        for index, expected_words in enumerate((6, 6, 6, 5)):
            descriptor = f"Boss_MissirayTileTransferSet{index:02d}Descriptor"
            body = source.split(descriptor + ":", 1)[1].split("\n\n", 1)[0]
            words = re.search(r"\bdc\.w\s+([^;\r\n]+)", body)
            self.assertIsNotNone(words)
            values = [word.strip() for word in words.group(1).split(",")]
            self.assertEqual(expected_words, len(values))
            self.assertEqual(["$6020", "$2000"], values[:2])
            self.assertEqual("$102" if index < 3 else "$101", values[2])

        for index in (0, 2, 3, 4, 5):
            wrapper = f"Boss_MissirayQueueIndexedRowSet{index:02d}"
            descriptor = f"Boss_MissirayIndexedRowSet{index:02d}Descriptor"
            body = source.split(wrapper + ":", 1)[1].split(descriptor + ":", 1)[0]
            self.assertIn(f"lea     {descriptor}(pc),a0", body)
            self.assertIn("jmp     Tilemap_QueueIndexedRows", body)
        set01 = source.split("Boss_MissirayQueueIndexedRowSet01:", 1)[1].split(
            "Boss_MissirayJumpToIndexedRowQueue:", 1
        )[0]
        self.assertNotIn("jmp     Tilemap_QueueIndexedRows", set01)
        self.assertIn(
            "jmp     Tilemap_QueueIndexedRows",
            source.split("Boss_MissirayJumpToIndexedRowQueue:", 1)[1].split(
                "Boss_MissirayIndexedRowSet01Descriptor:", 1
            )[0],
        )
        set03 = source.split("Boss_MissirayWaitForTransferAndLoadTileSet03:", 1)[1].split(
            "Boss_MissirayTileTransferSet03Descriptor:", 1
        )[0]
        for instruction in (
            "tst.b   (DataLoaderControl).w",
            "bmi.s   Boss_MissirayWaitForTileSet03Return",
            "addq.w  #2,4(a5)",
            "lea     Boss_MissirayTileTransferSet03Descriptor(pc),a0",
            "jmp     Tilemap_QueueIndexedColumns",
        ):
            self.assertIn(instruction, set03)
        record = next(
            item for item in json.loads(AUDIT.read_text(encoding="utf-8"))["records"] if item["address"] == "0x053B3A"
        )
        self.assertIn("tail-jumps directly", record["basis"][0])
        self.assertNotIn("named Missiray tile-set loader", record["basis"][0])

    def test_player_layout_reviews_distinguish_table_index_from_rom_order(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        data_path = "src/data/player_state_animation_sprite_mappings.s"
        data = (ROOT / data_path).read_text(encoding="utf-8")
        rendering = (ROOT / "src/player/rendering_and_defeat.s").read_text(encoding="utf-8")
        cases = (
            (
                "Player_WeaponAnimationFrames selects",
                "Player_WeaponAnimationFrames",
                "Player_RenderCeilingArmedIdle",
                "Player_WeaponAnimationSpriteMapping",
                [0, 1, 2, 3, 4],
                [0x0E8CC2, 0x0E8CDA, 0x0E8CEA, 0x0E8D12, 0x0E8D2A],
                [3, 2, 5, 3, 5],
                [f"Player_WeaponAnimationSpriteMapping{index:02d}" for index in range(5)]
                + ["Player_DashSecondarySpriteMapping"],
            ),
            (
                "Player_PrimaryAnimationLayoutTable contains",
                "Player_PrimaryAnimationLayoutTable",
                "Player_AlternateAnimationLayoutTable",
                "Player_PrimaryLayoutSpriteMapping",
                [4, 3, 0, 2, 1],
                [0x0E8D52, 0x0E8D72, 0x0E8D92, 0x0E8DAA, 0x0E8DC2],
                [4, 4, 3, 3, 3],
                [f"Player_PrimaryLayoutSpriteMapping{index:02d}" for index in range(5)],
            ),
            (
                "Player_AlternateAnimationLayoutTable contains",
                "Player_AlternateAnimationLayoutTable",
                "Player_UpdateCounterForceAnimation",
                "Player_AlternateLayoutSpriteMapping",
                [4, 3, 0, 2, 1],
                [0x0E8DDA, 0x0E8DF2, 0x0E8E12, 0x0E8E32, 0x0E8E4A],
                [3, 4, 4, 3, 4],
                [f"Player_AlternateLayoutSpriteMapping{index:02d}" for index in range(5)],
            ),
        )
        for basis_start, table, next_label, prefix, order, addresses, counts, slots in cases:
            with self.subTest(table=table):
                review = next(item for item in reviews if item["basis"].startswith(basis_start))
                names = [f"{prefix}{index:02d}" for index in order]
                self.assertEqual(
                    [(f"0x{address:06X}", name, data_path) for address, name in zip(addresses, names)],
                    [(member["address"], member["current_name"], member["file"]) for member in review["members"]],
                )
                table_body = rendering.split(table + ":", 1)[1].split(next_label + ":", 1)[0]
                self.assertEqual(slots, re.findall(r"\bdc\.l\s+([A-Za-z_]\w*)", table_body))
                for name, count in zip(names, counts):
                    block = re.search(
                        r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_]\w*:|\Z)",
                        data,
                    )
                    self.assertIsNotNone(block)
                    self.assertEqual(count, len(re.findall(r"\bdc\.l\b", block.group(1))))

        self.assertIn("movea.l Player_WeaponAnimationFrames(pc,d1.w),a2", rendering)
        self.assertIn("cmpi.w  #$18,$48(a5)", rendering)
        self.assertIn("lea     Player_PrimaryAnimationLayoutTable(pc),a0", rendering)
        self.assertIn("lea     Player_AlternateAnimationLayoutTable(pc),a0", rendering)
        self.assertIn("movea.l (a0,d0.w),a1", rendering)
        terrain = (ROOT / "src/player/projectiles_and_effects.s").read_text(encoding="utf-8")
        self.assertIn(
            "Player_LowerTerrainAnimationIndices:    dc.w    0, 8, 4, 8, 0, $C, $10, $C",
            terrain,
        )
        self.assertIn(
            "Player_UpperTerrainAnimationIndices:    dc.w    0, $C, $10, $C, 0, 8, 4, 8",
            terrain,
        )

    def test_enemy_behavior_and_circling_mapping_reviews_pin_stream_membership(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        cases = (
            (
                "Enemy behavior animation streams reference",
                "src/data/weapon_select_and_enemy_sprite_mappings.s",
                "Enemy_BehaviorSpriteMapping",
                ["00", "01", "02", "03", "04"],
                [0x0E9C2E, 0x0E9C4C, 0x0E9C64, 0x0E9C7C, 0x0E9CA0],
                [5, 4, 4, 6, 6],
            ),
            (
                "Enemy_CirclingLoopAnimation stores",
                "src/data/circling_enemy_sprite_mappings.s",
                "Enemy_CirclingAnimationSpriteMapping",
                list("ABCDE"),
                [0x0EB2E4, 0x0EB2EA, 0x0EB2F0, 0x0EB2F6, 0x0EB2FC],
                [1, 1, 1, 1, 1],
            ),
        )
        for basis_start, path, prefix, suffixes, addresses, piece_counts in cases:
            with self.subTest(group=basis_start):
                review = next(item for item in reviews if item["basis"].startswith(basis_start))
                names = [prefix + suffix for suffix in suffixes]
                self.assertEqual(
                    [(f"0x{address:06X}", name, path) for address, name in zip(addresses, names)],
                    [(item["address"], item["current_name"], item["file"]) for item in review["members"]],
                )
                source = (ROOT / path).read_text(encoding="utf-8")
                for name, count in zip(names, piece_counts):
                    block = re.search(
                        r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                        source,
                    )
                    self.assertIsNotNone(block)
                    words = re.findall(r"\bdc\.w\s+([^;\r\n]+)", block.group(1))
                    self.assertEqual(count, len(words), name)
                    self.assertTrue(all(len(word.split(",")) == 3 for word in words))
                    first = [int(word.split(",", 1)[0].strip()[1:], 16) for word in words]
                    self.assertTrue(all(value < 0x8000 for value in first[:-1]))
                    self.assertNotEqual(0, first[-1] & 0x8000)

        behavior = (ROOT / "src/data/weapon_select_and_enemy_sprite_mappings.s").read_text(encoding="utf-8")
        for stream, end, expected in (
            (
                "Enemy_BehaviorWaitSpriteAnimation",
                "Enemy_BehaviorGroundedSpriteAnimation",
                [0, 1, 2, 3, 4, 3, 2, 1],
            ),
            (
                "Enemy_BehaviorGroundedSpriteAnimation",
                "Enemy_BehaviorAttackCooldownSpriteAnimation",
                [0, 1, 2, 3, 4, 4, 3, 2, 1, 0],
            ),
        ):
            block = behavior.split(stream + ":", 1)[1].split(end + ":", 1)[0]
            self.assertEqual(
                expected,
                [int(index) for index in re.findall(r"Enemy_BehaviorSpriteMapping(\d\d)-\*", block)],
            )
        circling = (ROOT / "src/data/circling_enemy_sprite_mappings.s").read_text(encoding="utf-8")
        loop = circling.split("Enemy_CirclingLoopAnimation:", 1)[1]
        self.assertEqual(
            list("ABCDE"),
            re.findall(r"Enemy_CirclingAnimationSpriteMapping([A-E])-\*", loop),
        )
        self.assertEqual(5, len(re.findall(r"\bdc\.w\s+2\s*(?:;|$)", loop, re.M)))
        self.assertIn("dc.w    Enemy_CirclingLoopAnimation-*", loop)
        self.assertIn(
            "dc.l    Enemy_CirclingLoopAnimation", (ROOT / "src/enemies/circling_enemies.s").read_text(encoding="utf-8")
        )

    def test_wolf_garopa_orb_frame_index_excludes_trailing_words(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        selected = {
            record["address"]: record for record in records if record["address"] in {"0x02A126", "0x02A128", "0x02A140"}
        }
        self.assertEqual(
            {
                "0x02A126": "Gfx_AnimateWolfGaropaOrb",
                "0x02A128": "Gfx_AnimateWolfGaropaOrbAtA0",
                "0x02A140": "WolfGaropa_OrbAnimationFrames",
            },
            {address: record["current_name"] for address, record in selected.items()},
        )
        self.assertEqual(3, len({tuple(record["basis"]) for record in selected.values()}))
        self.assertIn("role remains unresolved", selected["0x02A140"]["basis"][0])
        source = (ROOT / "src/projectiles/shared_boss_projectiles.s").read_text(encoding="utf-8")
        entry = source.split("Gfx_AnimateWolfGaropaOrb:", 1)[1].split("WolfGaropa_OrbAnimationFrames:", 1)[0]
        for instruction in (
            "movea.w a5,a0",
            "move.w  (FrameCounter).w,d0",
            "asl.w   #2,d0",
            "andi.w  #$C,d0",
            "WolfGaropa_OrbAnimationFrames(pc,d0.w),$E(a0)",
            "WolfGaropa_OrbAnimationFrames+2(pc,d0.w),$A(a0)",
        ):
            self.assertIn(instruction, entry)
        data = source.split("WolfGaropa_OrbAnimationFrames:", 1)[1].split("Projectile_InitDirectionalSpawner:", 1)[0]
        rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", data)
        self.assertEqual(2, len(rows))
        self.assertEqual(8, len(rows[0].split(",")))
        self.assertEqual(["$30BC", "$5C"], [word.strip() for word in rows[1].split(",")])
        caller = (ROOT / "src/projectiles/wolf_garopa.s").read_text(encoding="utf-8")
        self.assertIn("movea.w #(ThirtyFirstEntityType-M68K_RAM),a0", caller)
        self.assertIn("jsr     (Gfx_AnimateWolfGaropaOrbAtA0).l", caller)

    def test_wolf_garopa_type424_evidence_separates_spawn_and_update(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        addresses = {
            "0x02A0D6": "Projectile_SpawnWolfGaropaType424",
            "0x02A100": "Projectile_SpawnWolfGaropaType424Return",
            "0x02A102": "Projectile_UpdateType424Visibility",
            "0x02A110": "Projectile_UpdateType424Blink",
            "0x02A124": "Projectile_UpdateType424VisibilityReturn",
        }
        selected = {record["address"]: record for record in records if record["address"] in addresses}
        self.assertEqual(addresses, {key: value["current_name"] for key, value in selected.items()})
        self.assertEqual(5, len({tuple(record["basis"]) for record in selected.values()}))
        source = (ROOT / "src/projectiles/shared_boss_projectiles.s").read_text(encoding="utf-8")
        spawn = source.split("Projectile_SpawnWolfGaropaType424:", 1)[1].split(
            "; End of function Projectile_SpawnWolfGaropaType424", 1
        )[0]
        update = source.split("Projectile_UpdateType424Visibility:", 1)[1].split(
            "; End of function Projectile_UpdateType424Visibility", 1
        )[0]
        for instruction in (
            "jsr     (Projectile_FindFreeSlotReverse).l",
            "bne.s   Projectile_SpawnWolfGaropaType424Return",
            "move.w  #$424,(a0)",
            "move.w  #$40,$48(a0)",
            "moveq   #0,d0",
        ):
            self.assertIn(instruction, spawn)
        for instruction in (
            "subq.w  #1,$48(a5)",
            "bpl.s   Projectile_UpdateType424Blink",
            "bset    #4,2(a5)",
            "bset    #7,2(a5)",
            "btst    #2,$49(a5)",
            "beq.s   Projectile_UpdateType424VisibilityReturn",
            "bclr    #7,2(a5)",
        ):
            self.assertIn(instruction, update)
        dispatch = (ROOT / "src/gameplay/object_dispatch_table.s").read_text(encoding="utf-8")
        self.assertIn("dc.l    Projectile_UpdateType424Visibility", dispatch)
        wolf = (ROOT / "src/bosses/wolf_garopa_core.s").read_text(encoding="utf-8")
        self.assertEqual(2, wolf.count("jsr     (Projectile_SpawnWolfGaropaType424).l"))

    def test_zleo_valkirie_shared_mapping_review_pins_descriptor_roles(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("Boss_ZLeoValkirieForceSharedMetaspriteData")
        )
        expected = [
            ("0x0ED3AC", "Boss_ZLeoValkirieForceSharedMappingE", 2),
            ("0x0ED3C4", "Boss_ZLeoValkirieForceSharedMappingA", 4),
            ("0x0ED3DC", "Boss_ZLeoValkirieForceSharedMappingB", 2),
            ("0x0ED3E8", "Boss_ZLeoValkirieForceSharedMappingD", 1),
            ("0x0ED3EE", "Boss_ZLeoValkirieForceSharedMappingC", 1),
        ]
        self.assertEqual(
            [(address, name) for address, name, _ in expected],
            [(item["address"], item["current_name"]) for item in review["members"]],
        )
        self.assertEqual(
            {"src/data/wolf_garopa_and_z_leo_mappings.s"},
            {item["file"] for item in review["members"]},
        )
        mappings = (ROOT / "src/data/wolf_garopa_and_z_leo_mappings.s").read_text(encoding="utf-8")
        for _, name, piece_count in expected:
            with self.subTest(mapping=name):
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    mappings,
                )
                self.assertIsNotNone(block)
                rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", block.group(1))
                self.assertEqual(piece_count, len(rows))
                self.assertTrue(all(len(row.split(",")) == 3 for row in rows))
                first_words = [int(row.split(",", 1)[0].strip()[1:], 16) for row in rows]
                self.assertTrue(all(word < 0x8000 for word in first_words[:-1]))
                self.assertNotEqual(0, first_words[-1] & 0x8000)
        descriptor_source = (ROOT / "src/data/wolf_garopa_valkirie_z_leo_metasprites.s").read_text(encoding="utf-8")
        descriptor_run = descriptor_source.split("Boss_ZLeoValkirieForceSharedMetaspriteData:", 1)[1].split(
            "Boss_ZLeoPartRadii:", 1
        )[0]
        entries = [row.strip() for row in re.findall(r"\bdc\.l\s+([^;\r\n]+)", descriptor_run)]
        base = "Boss_ZLeoValkirieForceSharedMapping"
        self.assertEqual(
            ["0", "0", "0"]
            + [base + letter + "+$400000" for letter in "ABA"]
            + ["Boss_ZLeoBladeDirectionMapping2+$400000"]
            + [base + letter + "+$400000" for letter in "ABCBCDCDE"],
            entries,
        )
        zleo = (ROOT / "src/bosses/z_leo_core.s").read_text(encoding="utf-8")
        valkirie = (ROOT / "src/bosses/valkirie_force.s").read_text(encoding="utf-8")
        shared = "Boss_ZLeoValkirieForceSharedMetaspriteData"
        self.assertIn(f"movea.l #{shared},a0", zleo)
        self.assertIn("movea.l #Boss_ZLeoPartRadii,a1", zleo)
        self.assertIn("movea.l #Boss_ZLeoPartLinks,a2", zleo)
        for register in ("a0", "a1", "a2"):
            self.assertIn(f"movea.l #{shared},{register}", valkirie)
        initializer = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        self.assertIn("move.l  (a0,d1.w),d4", initializer)
        self.assertIn("move.b  (a1,d3.w),d4", initializer)
        self.assertIn("move.w  (a2,d2.w),d4", initializer)

    def test_joker_and_shellshogun_rotation_review_pins_eight_pointer_slots(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        joker_frames = {
            "A": [f"Boss_JokerRotationMappingA{index}" for index in range(8)],
            "B": [f"Boss_JokerRotationMappingA{index}" for index in range(7, -1, -1)],
            "C": [f"Boss_JokerRotationMappingC{index}" for index in range(8)],
            "D": [f"Boss_JokerRotationMappingC{index}" for index in range(7, -1, -1)],
            "E": [f"Boss_JokerRotationMappingE{index}" for index in range(8)],
            "F": [f"Boss_JokerRotationMappingE{index}" for index in range(7, -1, -1)],
        }
        shellshogun_frames = {
            "A": [f"Boss_ShellshogunSpriteMapping{index:02d}" for index in range(26, 18, -1)],
            "B": [f"Boss_ShellshogunSpriteMapping{index:02d}" for index in range(10, 2, -1)],
            "C": [f"Boss_ShellshogunSpriteMapping{index:02d}" for index in range(18, 10, -1)],
            "D": [f"Boss_ShellshogunSpriteMapping{index:02d}" for index in range(19, 27)],
            "E": [f"Boss_ShellshogunSpriteMapping{index:02d}" for index in range(3, 11)],
            "F": [f"Boss_ShellshogunSpriteMapping{index:02d}" for index in range(11, 19)],
        }
        cases = (
            (
                "Joker's descriptors reference",
                "src/data/madam_barbar_flying_neo_joker_back_stringer_sharpssteel_metasprites.s",
                "Boss_JokerRotationFrames",
                0x034F8A,
                joker_frames,
                "Boss_JokerMetaspriteDescriptors",
            ),
            (
                "Shellshogun's descriptors reference",
                "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s",
                "Boss_ShellshogunRotationFrames",
                0x034AE0,
                shellshogun_frames,
                "Boss_ShellshogunMetaspriteDescriptors",
            ),
        )
        for basis_start, path, prefix, first_address, expected_frames, descriptor in cases:
            with self.subTest(owner=prefix):
                review = next(item for item in reviews if item["basis"].startswith(basis_start))
                names = [prefix + letter for letter in "ABCDEF"]
                self.assertEqual(
                    [(f"0x{first_address + index * 0x20:06X}", name) for index, name in enumerate(names)],
                    [(item["address"], item["current_name"]) for item in review["members"]],
                )
                self.assertEqual({path}, {item["file"] for item in review["members"]})
                source = (ROOT / path).read_text(encoding="utf-8")
                descriptors = source.split(descriptor + ":", 1)[1].split(
                    "\n" + descriptor.replace("MetaspriteDescriptors", "PartRadii") + ":", 1
                )[0]
                for letter, name in zip("ABCDEF", names):
                    table = re.search(
                        r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                        source,
                    )
                    self.assertIsNotNone(table)
                    self.assertEqual(
                        expected_frames[letter],
                        re.findall(r"\bdc\.l\s+(Boss_\w+)", table.group(1)),
                    )
                    self.assertRegex(descriptors, r"\bdc\.l\s+" + re.escape(name) + r"\b")
        shellshogun_rendering = (ROOT / "src/bosses/shellshogun_rendering.s").read_text(encoding="utf-8")
        flip = shellshogun_rendering.split("Boss_ShellshogunUpdateSpriteFlip:", 1)[1]
        self.assertIn("lea     (Boss_ShellshogunRotationFramesF).l,a0", flip)
        self.assertIn("andi.w  #$1C,d0", flip)
        self.assertIn("move.l  (a0,d0.w),$248(a5)", flip)

    def test_periodic_shot_mapping_review_pins_three_streams_and_nine_pieces(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("Periodic-shot enemy animation streams"))
        addresses = [
            0x0E9E94,
            0x0E9ECA,
            0x0E9F00,
            0x0E9F36,
            0x0E9F6C,
            0x0E9FA2,
            0x0E9FD8,
        ]
        names = [f"PeriodicShotEnemySpriteMapping{index:02d}" for index in range(7)]
        self.assertEqual(
            [(f"0x{address:06X}", name) for address, name in zip(addresses, names)],
            [(member["address"], member["current_name"]) for member in review["members"]],
        )
        self.assertEqual(
            {"src/data/weapon_select_and_enemy_sprite_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/weapon_select_and_enemy_sprite_mappings.s").read_text(encoding="utf-8")
        expected_streams = {
            "Wait": [3, 0, 1, 2, 4, 2, 1, 0, 3],
            "Attack": [0, 5, 6, 5],
            "Transition": [0, 5, 3],
        }
        for stream, expected in expected_streams.items():
            block = re.search(
                r"(?ms)^PeriodicShotEnemy" + stream + r"SpriteAnimation:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                data,
            )
            self.assertIsNotNone(block)
            self.assertEqual(
                expected,
                [
                    int(index)
                    for index in re.findall(
                        r"\bdc\.w\s+PeriodicShotEnemySpriteMapping([0-9]{2})-\*",
                        block.group(1),
                    )
                ],
            )
        self.assertEqual(set(range(7)), set(sum(expected_streams.values(), [])))
        for name in names:
            with self.subTest(name=name):
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    data,
                )
                self.assertIsNotNone(block)
                rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", block.group(1))
                self.assertTrue(all(len(row.split(",")) == 3 for row in rows))
                first_words = [int(word, 16) for word in re.findall(r"\bdc\.w\s+\$([0-9A-F]+)", block.group(1))]
                self.assertEqual(9, len(first_words))
                self.assertTrue(all(word < 0x8000 for word in first_words[:-1]))
                self.assertNotEqual(0, first_words[-1] & 0x8000)
        owner = (ROOT / "src/enemies/jetsripper_stage_actors.s").read_text(encoding="utf-8")
        pointer_table = owner.split("PeriodicShotEnemySpriteAnimationPointers:", 1)[1]
        self.assertEqual(
            ["Wait", "Transition", "Attack"],
            re.findall(
                r"\bdc\.l\s+PeriodicShotEnemy(Wait|Transition|Attack)SpriteAnimation",
                pointer_table,
            )[:3],
        )

    def test_midgame_lightning_mapping_review_excludes_one_piece_assumption(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("At least one of Midgame_LightningSpriteAnimation00")
        )
        addresses = [
            0x19C59E,
            0x19C5B6,
            0x19C5D4,
            0x19C5EC,
            0x19C5FE,
            0x19C610,
            0x19C61C,
        ]
        names = [f"Midgame_LightningSpriteMapping{index:02d}" for index in range(7)]
        self.assertEqual(
            [(f"0x{address:06X}", name) for address, name in zip(addresses, names)],
            [(member["address"], member["current_name"]) for member in review["members"]],
        )
        self.assertEqual(
            {"src/data/indexed_object_and_stage_effect_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/indexed_object_and_stage_effect_mappings.s").read_text(encoding="utf-8")
        expected_streams = {
            "00": [0, 1, 2, 3, 4, 5, 6],
            "01": [0, 1, 0, 1, 2, 3, 2, 3, 4, 5, 4, 5, 6],
            "03": [0, 4, 5, 4, 5, 6],
        }
        for stream, expected in expected_streams.items():
            block = re.search(
                r"(?ms)^Midgame_LightningSpriteAnimation" + stream + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                data,
            )
            self.assertIsNotNone(block)
            self.assertEqual(
                expected,
                [
                    int(index)
                    for index in re.findall(
                        r"\bdc\.w\s+Midgame_LightningSpriteMapping([0-9]{2})-\*",
                        block.group(1),
                    )
                ],
            )
        self.assertEqual(set(range(7)), set(sum(expected_streams.values(), [])))
        other_stream = data.split("Midgame_LightningSpriteAnimation02:", 1)[1].split(
            "Midgame_LightningSpriteAnimation03:", 1
        )[0]
        self.assertEqual(
            list(range(7, 13)),
            [
                int(index)
                for index in re.findall(
                    r"\bdc\.w\s+Midgame_LightningSpriteMapping([0-9]{2})-\*",
                    other_stream,
                )
            ],
        )
        for name, piece_count in zip(names, (4, 5, 4, 3, 3, 2, 1)):
            with self.subTest(name=name):
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    data,
                )
                self.assertIsNotNone(block)
                rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", block.group(1))
                self.assertTrue(all(len(row.split(",")) == 3 for row in rows))
                first_words = [int(word, 16) for word in re.findall(r"\bdc\.w\s+\$([0-9A-F]+)", block.group(1))]
                self.assertEqual(piece_count, len(first_words))
                self.assertTrue(all(word < 0x8000 for word in first_words[:-1]))
                self.assertNotEqual(0, first_words[-1] & 0x8000)
        owner = (ROOT / "src/stages/flying_neo_effects.s").read_text(encoding="utf-8")
        self.assertIn("andi.w  #$C,d0", owner)
        self.assertIn("move.l  Midgame_RandomLightningMappingPointers(pc,d0.w),8(a0)", owner)
        pointer_table = owner.split("Midgame_RandomLightningMappingPointers:", 1)[1]
        self.assertEqual(
            ["00", "01", "02", "03"],
            re.findall(
                r"\bdc\.l\s+Midgame_LightningSpriteAnimation([0-9]{2})",
                pointer_table,
            )[:4],
        )

    def test_jampan_orbit_tables_have_distinct_consumers_and_sixteen_slots(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        source = (ROOT / "src/bosses/jampan_core.s").read_text(encoding="utf-8")
        geometry = (ROOT / "src/bosses/jampan_geometry_and_input.s").read_text(encoding="utf-8")
        loop = source.split("Boss_JampanInitializeOrbitingPartLoop:", 1)[1].split(
            "Boss_JampanInitializeShieldSlotLoop:", 1
        )[0]
        cases = {
            "0x04945E": ("Boss_JampanOrbitingPartTypes", "move.w  (a1,d0.w),(a0)"),
            "0x04947E": (
                "Boss_JampanOrbitingPartSpriteAttributes",
                "move.w  (a1,d0.w),d2",
            ),
            "0x04949E": ("Boss_JampanOrbitingPartRadii", "move.w  (a1,d0.w),$48(a0)"),
            "0x0494BE": (
                "Boss_JampanOrbitingPartPrimaryAngles",
                "move.w  (a1,d0.w),$4A(a0)",
            ),
            "0x0494DE": (
                "Boss_JampanOrbitingPartSecondaryAngles",
                "move.w  (a1,d0.w),$4C(a0)",
            ),
            "0x0494FE": (
                "Boss_JampanOrbitingPartMappingPointers",
                "move.l  (a1,d0.w),8(a0)",
            ),
        }
        bases = []
        tables = {}
        for address, (name, load) in cases.items():
            with self.subTest(address=address):
                record = by_address[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                self.assertRegex(
                    loop,
                    re.escape("lea     " + name + "(pc),a1") + r"\s+nop\s+" + re.escape(load),
                )
                table = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(table)
                tables[name] = table.group(1)
        self.assertEqual(6, len(set(bases)))
        self.assertEqual(
            "Boss_JampanOrbitingPartSpriteFrames",
            by_address["0x0494FE"]["previous_name"],
        )
        self.assertEqual("off_494FE", by_address["0x0494FE"]["legacy_name"])
        for name, table in tables.items():
            directive = "dc.l" if name.endswith("MappingPointers") else "dc.w"
            operands = [
                operand.strip()
                for row in re.findall(r"\b" + directive + r"\s+([^;\r\n]+)", table)
                for operand in row.split(",")
            ]
            self.assertEqual(16, len(operands), name)
        pointers = [
            row.strip()
            for row in re.findall(
                r"\bdc\.l\s+([^;\r\n]+)",
                tables["Boss_JampanOrbitingPartMappingPointers"],
            )
        ]
        self.assertEqual(
            ["Boss_JampanShieldAndOrbitingPartMapping"]
            + ["Boss_JampanOrbitingPartMappingA"] * 2
            + ["Boss_JampanOrbitingPartMappingB"] * 13,
            pointers,
        )
        for field in ("$48(a0)", "$4A(a0)", "$4C(a0)"):
            self.assertIn("move.w  " + field, geometry)
        self.assertIn("add.w   d0,d0", loop)
        self.assertIn("or.w    d2,$E(a0)", loop)

    def test_pcm_bank_review_pins_eight_full_banks_and_partial_ninth(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("The DAC descriptor tables encode this 0x8000-byte")
        )
        self.assertEqual(
            {f"Sound_PCMBank{index}" for index in range(1, 9)},
            {member["current_name"] for member in review["members"]},
        )
        self.assertEqual(
            {"src/sound/pcm_samples.s"},
            {member["file"] for member in review["members"]},
        )
        assets = json.loads((ROOT / "assets/manifest.json").read_text(encoding="utf-8"))["assets"]
        by_path = {asset["path"]: asset for asset in assets}
        source = (ROOT / "src/sound/pcm_samples.s").read_text(encoding="utf-8")
        descriptors = (ROOT / "src/sound/driver_core.s").read_text(encoding="utf-8") + (
            ROOT / "src/sound/command_dispatch_and_dac.s"
        ).read_text(encoding="utf-8")
        for index, member in enumerate(review["members"], start=1):
            with self.subTest(bank=index):
                start = 0x98000 + (index - 1) * 0x8000
                asset = by_path[f"sound/PCMPart{index}.bin"]
                self.assertEqual(start, int(member["address"], 16))
                self.assertEqual(start, int(asset["address"], 16))
                self.assertEqual(start + 0x8000, int(asset["end"], 16))
                self.assertEqual(0x8000, asset["size"])
                self.assertIn(
                    f'Sound_PCMBank{index}: binclude "data/sound/PCMPart{index}.bin"',
                    source,
                )
                self.assertRegex(
                    descriptors,
                    rf"\bdc\.w\s+\(Sound_PCMBank{index} >> \$8\)[^\n]*\n\s*dc\.w\s+",
                )
        ninth = by_path["sound/PCMPart9.bin"]
        self.assertEqual(0xD8000, int(ninth["address"], 16))
        self.assertEqual(0x1A5E, ninth["size"])
        self.assertNotIn("Sound_PCMBank9", {member["current_name"] for member in review["members"]})

    def test_sirene_direct_and_indirect_pose_scripts_exclude_frame_data(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        direct = next(item for item in reviews if item["basis"].startswith("A named Sirene state loads this word"))
        indirect = next(
            item for item in reviews if item["basis"].startswith("Boss_EnterSireneState14 selects this word")
        )
        self.assertEqual(
            {"Sirene_State2PoseScript", "Sirene_ActivePoseScript", "Sirene_State4And6PoseScript"},
            {member["current_name"] for member in direct["members"]},
        )
        self.assertEqual(
            {f"Sirene_State14PoseScript{index}" for index in range(3)},
            {member["current_name"] for member in indirect["members"]},
        )
        self.assertEqual(
            {"src/bosses/sirene.s"},
            {member["file"] for item in (direct, indirect) for member in item["members"]},
        )
        source = (ROOT / "src/bosses/sirene.s").read_text(encoding="utf-8")
        self.assertEqual(
            {member["current_name"] for member in direct["members"]},
            set(re.findall(r"\blea\s+(Sirene_\w+PoseScript)\(pc\),a1", source)),
        )
        self.assertIn("bsr.w   Boss_UpdateSirenePoseScript", source)
        for name, end in (
            ("Sirene_State2PoseScript", "$FFFF"),
            ("Sirene_ActivePoseScript", "$FFFF"),
            ("Sirene_State4And6PoseScript", "$FFFE"),
        ):
            with self.subTest(script=name):
                body = re.search(
                    r"(?ms)^" + name + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(body)
                rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", body.group(1))
                self.assertEqual(end, rows[-1].split(",")[-1].strip())
        set0 = source.split("Sirene_State14PoseScriptSet0:", 1)[1].split("Sirene_State14PoseScriptSet1:", 1)[0]
        set1 = source.split("Sirene_State14PoseScriptSet1:", 1)[1].split(
            "Boss_UpdateSireneBattlePositionsAndDistortion:", 1
        )[0]
        for block, expected in ((set0, ["0", "0", "2", "2"]), (set1, ["0", "0", "1", "1"])):
            self.assertEqual(
                expected,
                re.findall(r"\bdc\.l\s+Sirene_State14PoseScript([012])\b", block),
            )
        self.assertIn("andi.w  #$C,d0", source)
        self.assertIn("move.l  (a0,d0.w),$71C(a5)", source)
        self.assertIn("movea.l $71C(a5),a1", source)
        script2 = source.split("Sirene_State14PoseScript2:", 1)[1].split("Sirene_PoseFrameData:", 1)[0]
        words = [
            int(token.strip()[1:], 16)
            for row in re.findall(r"\bdc\.w\s+([^;\r\n]+)", script2)
            for token in row.split(",")
        ]
        self.assertEqual([0xFFFE, 0x820, 0x50, 0x1414, 0x50, 0xFFFE], words[-6:])
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        frame = next(record for record in records if record["address"] == "0x057D18")
        self.assertEqual("Sirene_PoseFrameData", frame["current_name"])
        self.assertNotIn(frame["basis"][0], (direct["basis"], indirect["basis"]))
        self.assertIn("move.l  #Sirene_PoseFrameData,$35C(a5)", source)
        self.assertIn("add.l   $35C(a5),d0", source)

    def test_medusa_pose_scripts_exclude_frame_data_and_initial_values(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("The named Medusa state loads this word stream")
        )
        expected = {member["current_name"] for member in review["members"]}
        self.assertEqual(7, len(expected))
        self.assertEqual(
            {"src/bosses/medusa.s"},
            {member["file"] for member in review["members"]},
        )
        source = (ROOT / "src/bosses/medusa.s").read_text(encoding="utf-8")
        self.assertEqual(
            expected,
            set(re.findall(r"\blea\s+(Medusa_\w+PoseScript)\(pc\),a1", source)),
        )
        self.assertIn("bsr.w   Boss_UpdateMedusaPoseScript", source)
        self.assertIn("cmpi.w  #$FFFE,d3", source)
        self.assertIn("cmpi.w  #$FFFF,d3", source)
        for name in expected:
            with self.subTest(name=name):
                match = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(match)
                rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", match.group(1))
                self.assertIn(rows[-1].split(",")[-1].strip(), ("$FFFE", "$FFFF"))
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        frame = by_address["0x057132"]
        self.assertEqual("Medusa_PoseFrameData", frame["current_name"])
        self.assertNotEqual(review["basis"], frame["basis"][0])
        self.assertIn("$35C(a5)", frame["basis"][0])
        self.assertIn("move.l  #Medusa_PoseFrameData,$35C(a5)", source)
        self.assertIn("add.l   $35C(a5),d0", source)
        self.assertIn("bsr.w   Boss_CalculateMedusaPoseDeltas", source)
        initial = by_address["0x057172"]
        self.assertEqual("Medusa_InitialPoseChannelValues", initial["current_name"])
        self.assertIn("initial fixed-point pose values", " ".join(initial["basis"]))

    def test_sniper_honeyviper_tentacle_mappings_follow_one_indexed_direction_table(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("Boss_SniperHoneyviperTentacleDirectionFrames selects")
        )
        expected = {f"Boss_SniperHoneyviperTentacleSpriteMapping{index:02}" for index in range(8)}
        self.assertEqual(expected, {member["current_name"] for member in review["members"]})
        self.assertEqual(
            {"src/data/sniper_honeyviper_tentacle_sprite_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        for record in records:
            if record["current_name"] in expected:
                self.assertEqual(review["basis"], record["basis"][0])
        movement = (ROOT / "src/bosses/sniper_honeyviper_movement.s").read_text(encoding="utf-8")
        table = movement.split("Boss_SniperHoneyviperTentacleDirectionFrames:", 1)[1]
        self.assertEqual(
            ["04", "03", "02", "01", "00", "07", "06", "05"],
            re.findall(r"\bdc\.l\s+Boss_SniperHoneyviperTentacleSpriteMapping(\d\d)", table),
        )
        self.assertIn("movea.l #Boss_SniperHoneyviperTentacleDirectionFrames,a1", movement)
        self.assertEqual(2, movement.count("andi.w  #$E0,d2"))
        self.assertEqual(2, movement.count("asr.w   #3,d2"))
        for field in ("$1E8", "$2A8"):
            self.assertIn(f"move.l  (a1,d2.w),{field}(a5)", movement)
        mappings = (ROOT / "src/data/sniper_honeyviper_tentacle_sprite_mappings.s").read_text(encoding="utf-8")
        for name in expected:
            with self.subTest(name=name):
                match = re.search(rf"(?m)^{name}:\s+dc\.w\s+\$([0-9A-F]+)", mappings)
                self.assertIsNotNone(match)
                self.assertTrue(int(match.group(1), 16) & 0x8000)

    def test_bird_mapping_review_pins_four_streams_and_mapping_ends(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("Named Enemy_Bird animation streams select"))
        expected = {f"Enemy_BirdSpriteMapping{index:02}" for index in range(11)}
        self.assertEqual(expected, {member["current_name"] for member in review["members"]})
        self.assertEqual(
            {"src/data/bird_animation_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/bird_animation_mappings.s").read_text(encoding="utf-8")
        streams = [
            data.split(f"Enemy_BirdAnimation{index:02}:", 1)[1].split(f"Enemy_BirdAnimation{index + 1:02}:", 1)[0]
            if index < 3
            else data.split("Enemy_BirdAnimation03:", 1)[1]
            for index in range(4)
        ]
        targets = [re.findall(r"\bdc\.w\s+Enemy_BirdSpriteMapping(\d\d)-\*", stream) for stream in streams]
        self.assertEqual(
            ["00", "01", "02", "03", "04", "05", "06", "05", "04", "03", "02", "01"],
            targets[0],
        )
        self.assertEqual(targets[0], targets[1])
        self.assertEqual(["07", "08", "09", "08"], targets[2])
        self.assertEqual(["09", "08", "07", "10"], targets[3])
        self.assertEqual(
            expected,
            {f"Enemy_BirdSpriteMapping{index}" for stream in targets for index in stream},
        )
        for index, stream in enumerate(streams[:3]):
            with self.subTest(stream=index):
                self.assertIn(f"Enemy_BirdAnimation{index:02}-*", stream)
                self.assertRegex(stream, r"(?m)^\s*dc\.w\s+0\s*$")
        self.assertRegex(streams[3], r"(?m)^\s*dc\.w\s+\$FF\s*$")
        for name in expected:
            with self.subTest(mapping=name):
                body = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    data,
                )
                self.assertIsNotNone(body)
                rows = re.findall(r"\bdc\.w\s+([^;\r\n]+)", body.group(1))
                self.assertTrue(int(rows[-1].split(",")[0].strip()[1:], 16) & 0x8000)
        bird = (ROOT / "src/enemies/bird_enemy.s").read_text(encoding="utf-8")
        self.assertEqual(
            [f"{index:02}" for index in range(4)],
            re.findall(r"\bdc\.l\s+Enemy_BirdAnimation(\d\d)\b", bird),
        )
        self.assertIn("Enemy_BirdAnimationMappings(pc,d0.w),8(a5)", bird)

    def test_missiray_bullet_mapping_review_pins_three_animation_streams(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("Missiray bullet animation streams select"))
        expected = {f"Projectile_MissirayBulletSpriteFrame{index:02}" for index in range(11)}
        self.assertEqual(expected, {member["current_name"] for member in review["members"]})
        self.assertEqual(
            {"src/data/shield_viper_and_missiray_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/shield_viper_and_missiray_mappings.s").read_text(encoding="utf-8")
        loop = data.split("Projectile_MissirayBulletLoopSpriteAnimation:", 1)[1].split(
            "Projectile_MissirayBulletInitialSpriteAnimation:", 1
        )[0]
        initial = data.split("Projectile_MissirayBulletInitialSpriteAnimation:", 1)[1].split(
            "Projectile_MissirayBulletTransformSpriteAnimation:", 1
        )[0]
        transform = data.split("Projectile_MissirayBulletTransformSpriteAnimation:", 1)[1]

        def targets(block: str) -> list[str]:
            return re.findall(r"\bdc\.w\s+Projectile_MissirayBulletSpriteFrame(\d\d)-\*", block)

        self.assertEqual(["01", "02", "04", "03"], targets(loop))
        self.assertEqual(["00"], targets(initial))
        self.assertEqual(["00", "10", "05", "06", "07", "08", "09"], targets(transform))
        self.assertEqual(
            expected,
            {
                f"Projectile_MissirayBulletSpriteFrame{index}"
                for index in targets(loop) + targets(initial) + targets(transform)
            },
        )
        self.assertIn("dc.w    Projectile_MissirayBulletLoopSpriteAnimation-*", loop)
        self.assertRegex(loop, r"(?m)^\s*dc\.w\s+0\s*$")
        for block in (initial, transform):
            self.assertRegex(block, r"(?m)^\s*dc\.w\s+\$FF\s*$")
        projectile = (ROOT / "src/projectiles/missiray_and_rising_shots.s").read_text(encoding="utf-8")
        for stream in ("Initial", "Transform", "Loop"):
            self.assertIn(
                f"#Projectile_MissirayBullet{stream}SpriteAnimation,8(a",
                projectile,
            )

    def test_shared_pattern_middle_longwords_have_two_eight_element_rows(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("The structural name records exact width"))
        expected = {
            (0xFFFF9400 + 0x20 * row + 4 * index, f"SharedPatternRow{row}Long{index}")
            for row in range(2)
            for index in range(1, 7)
        }
        self.assertEqual(
            expected,
            {(int(member["address"], 16), member["current_name"]) for member in review["members"]},
        )
        self.assertEqual(
            {"src/ram_addrs.inc"},
            {member["file"] for member in review["members"]},
        )
        ram = (ROOT / "src/ram_addrs.inc").read_text(encoding="utf-8")
        for address, name in expected:
            with self.subTest(name=name):
                self.assertRegex(
                    ram,
                    rf"(?m)^{name}\s+equ\s+\${address:08X}\b",
                )
        for row in range(2):
            self.assertRegex(
                ram,
                rf"(?m)^TransitionPatternRow{row}\s+equ\s+SharedPatternRow{row}Long0$",
            )
            self.assertIn(f"SharedPatternRow{row}Long7", ram)
        source = (ROOT / "src/effects/transition_scroll.s").read_text(encoding="utf-8")
        loop = source.split("Effect_ApplyTransitionMask:", 1)[1].split("Effect_TransitionMaskPatternsA:", 1)[0]
        self.assertIn("moveq   #3,d7", loop)
        self.assertIn("dbf     d7,Effect_ApplyTransitionMask_Loop", loop)
        for row, register in enumerate(("a0", "a1")):
            with self.subTest(register=register):
                self.assertIn(f"#(TransitionPatternRow{row}-M68K_RAM)", loop)
                self.assertEqual(2, loop.count(f"({register})+"))

    def test_valkirie_pose_script_review_excludes_indirect_airborne_variants(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("The named battle-state path loads this word stream")
        )
        self.assertEqual(9, len(review["members"]))
        self.assertEqual(
            {"src/bosses/valkirie_rendering.s"},
            {member["file"] for member in review["members"]},
        )
        expected = {member["current_name"] for member in review["members"]}
        battle = (ROOT / "src/bosses/valkirie_battle.s").read_text(encoding="utf-8")
        rendering = (ROOT / "src/bosses/valkirie_rendering.s").read_text(encoding="utf-8")
        self.assertEqual(
            expected,
            set(re.findall(r"\blea\s+(Valkirie_\w+PoseScript)\(pc\),a1", battle)),
        )
        self.assertIn("bsr.w   Anim_UpdateValkiriePoseScript", battle)
        self.assertIn("move.b  1(a1,d0.w),$23E(a5)", rendering)
        self.assertIn("cmpi.w  #$FFFE,d3", rendering)
        for name in expected:
            with self.subTest(name=name):
                match = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    rendering,
                )
                self.assertIsNotNone(match)
                words = [
                    int(token.strip()[1:], 16) if token.strip().startswith("$") else int(token.strip())
                    for row in re.findall(r"\bdc\.w\s+([^;\r\n]+)", match.group(1))
                    for token in row.split(",")
                ]
                self.assertIn(words[-1], (0xFFFE, 0xFFFF))

    def test_valkirie_airborne_variants_are_neutral_and_indirect(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        battle = (ROOT / "src/bosses/valkirie_battle.s").read_text(encoding="utf-8")
        rendering = (ROOT / "src/bosses/valkirie_rendering.s").read_text(encoding="utf-8")
        for index, branch_address, script_address, old_role in (
            (0, "0x055B62", "0x056330", "High"),
            (1, "0x055B82", "0x056350", "Mid"),
            (2, "0x055B96", "0x056370", "Low"),
        ):
            with self.subTest(index=index):
                branch = f"Entity_ValkirieBattleStateEUsePattern{index:02}"
                script = f"Valkirie_AirbornePattern{index:02}PoseScript"
                self.assertEqual(branch, by_address[branch_address]["current_name"])
                self.assertEqual(script, by_address[script_address]["current_name"])
                self.assertEqual(
                    f"Entity_ValkirieBattleStateEUse{old_role}Pattern",
                    by_address[branch_address]["previous_name"],
                )
                self.assertEqual(
                    f"Valkirie_Airborne{old_role}PoseScript",
                    by_address[script_address]["previous_name"],
                )
                self.assertIn(f"{branch}:", battle)
                self.assertIn(f"move.l  #{script},$41C(a5)", battle)
                self.assertIn(f"{script}:", rendering)
                self.assertNotIn(f"Valkirie_Airborne{old_role}PoseScript:", rendering)
        fallback_basis = by_address["0x055B8C"]["basis"][0]
        self.assertIn("Valkirie_AirbornePattern00PoseScript", fallback_basis)
        self.assertIn("Valkirie_AirbornePattern02PoseScript", fallback_basis)
        self.assertGreaterEqual(battle.count("movea.l $41C(a5),a1"), 2)

    def test_palette_offset_list_review_excludes_two_list_continue_record(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("Gfx_LoadMultiplePalettes consumes these signed words")
        )
        owners = {
            "StoryScreenPaletteOffsetList": "src/cutscenes/story_screen_and_title_transition.s",
            "OptionsScreenPaletteOffsetList": "src/ui/options_menu_controllers.s",
            "StageStartPaletteOffsetList": "src/stages/gameplay_initialization.s",
            "ResultsScreenPaletteOffsetList": "src/ui/results_screen.s",
            "CreditsAndPlanetPaletteOffsetList": "src/cutscenes/ending_sequence_credits.s",
            "EarlyStagePaletteOffsetList": "src/stages/configuration_records.s",
            "ShellshogunStagePaletteOffsetList": "src/stages/early_stage_process_states.s",
            "Stage8InitialPaletteOffsetList": "src/stages/configuration_records.s",
            "XiTigerCutscenePaletteOffsetList": "src/cutscenes/xi_tiger.s",
            "Stage17PaletteOffsetList": "src/stages/configuration_records.s",
            "SevenForcesCutscenePaletteOffsetList": "src/stages/seven_forces_transition_graphics.s",
        }
        self.assertEqual(set(owners), {member["current_name"] for member in review["members"]})
        self.assertEqual(
            {"src/rendering/palettes.s"},
            {member["file"] for member in review["members"]},
        )
        palette_source = (ROOT / "src/rendering/palettes.s").read_text(encoding="utf-8")
        for name, owner_path in owners.items():
            with self.subTest(name=name):
                record = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    palette_source,
                )
                self.assertIsNotNone(record)
                operands = [row.strip() for row in re.findall(r"\bdc\.w\s+([^;\r\n]+)", record.group(1))]
                self.assertEqual("0", operands[-1])
                self.assertEqual(1, operands.count("0"))
                self.assertTrue(all(row.endswith("-Gfx_LoadPalettePreservingSharedColor") for row in operands[:-1]))
                owner = (ROOT / owner_path).read_text(encoding="utf-8")
                self.assertRegex(
                    owner,
                    r"(?m)^\s*(?:lea|movea\.l|dc\.l)\s+[^;\r\n]*\b" + re.escape(name) + r"\b",
                )
        continue_record = palette_source.split("ContinueScreenPaletteOffsetLists:", 1)[1].split(
            "ResultsScreenPaletteOffsetList:", 1
        )[0]
        self.assertEqual(2, len(re.findall(r"\bdc\.w\s+0\b", continue_record)))
        self.assertIn("move.w  (a4)+,d0", palette_source)
        self.assertIn("addi.l  #Gfx_LoadPalettePreservingSharedColor,d0", palette_source)

    def test_sharpssteel_pose_stream_review_pins_interpreter_inputs(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("The named Sharpssteel state or controller"))
        self.assertEqual(13, len(review["members"]))
        self.assertEqual(
            {"src/bosses/sharpssteel_blades.s"},
            {member["file"] for member in review["members"]},
        )
        expected = {member["current_name"] for member in review["members"]}
        core = (ROOT / "src/bosses/sharpssteel_core.s").read_text(encoding="utf-8")
        blades = (ROOT / "src/bosses/sharpssteel_blades.s").read_text(encoding="utf-8")
        loaded = set(
            re.findall(
                r"\blea\s+(Boss_Sharpssteel\w+PoseCommands)\(pc\),a1",
                core + blades,
            )
        )
        self.assertEqual(expected, loaded)
        for name in expected:
            with self.subTest(name=name):
                stream = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    blades,
                )
                self.assertIsNotNone(stream)
                operands = re.findall(r"\bdc\.b\s+([^;\r\n]+)", stream.group(1))
                values = [
                    int(token.strip()[1:], 16) if token.strip().startswith("$") else int(token.strip())
                    for row in operands
                    for token in row.split(",")
                ]
                self.assertIn(values[-2:], ([0xFF, 0xFF], [0xFF, 0xFE]))
        assembly = blades.split("Boss_SharpssteelUpdateBladeAssembly:", 1)[1].split(
            "Boss_SharpssteelUpdateBladePresentation:", 1
        )[0]
        self.assertIn("bsr.w   Boss_SharpssteelRunBladePoseCommands", assembly)
        self.assertRegex(
            core,
            r"lea\s+Boss_SharpssteelManualControlPoseCommands\(pc\),a1"
            r"[\s\S]*?bsr\.w\s+Boss_SharpssteelRunBladePoseCommands",
        )

    def test_sharpssteel_pose_control_points_have_distinct_local_evidence(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        source = (ROOT / "src/bosses/sharpssteel_blades.s").read_text(encoding="utf-8")
        cases = {
            "0x0489FA": (
                "Boss_SharpssteelParseBladePoseCommandLoop",
                ("cmpi.b  #$80,(a1,d0.w)", "move.b  1(a1,d0.w),$23E(a5)"),
            ),
            "0x048A16": (
                "Boss_SharpssteelReadBladePoseCommand",
                ("move.w  (a1,d0.w),d3", "cmpi.w  #$FFFE,d3"),
            ),
            "0x048A26": (
                "Boss_SharpssteelHandleBladePoseLoopCommand",
                ("cmpi.w  #$FFFF,d3", "clr.w   $29C(a5)"),
            ),
            "0x048A36": (
                "Boss_SharpssteelBeginBladePoseInterpolation",
                (
                    "ext.l   d0",
                    "bsr.w   Boss_SharpssteelInitializeBladePoseInterpolation",
                ),
            ),
            "0x048A68": (
                "Boss_SharpssteelApplyBladePoseInterpolationStep",
                (
                    "subq.w  #1,$C(a5)",
                    "jsr     (Anim_AdvancePoseChannelInterpolation).l",
                ),
            ),
            "0x048A78": (
                "Boss_SharpssteelUpdateBladeAnglesFromPose",
                (
                    "move.b  (a0),d0",
                    "move.w  d3,$6B6(a5)",
                    "moveq   #0,d4",
                    "asr.w   #2,d4",
                ),
            ),
            "0x048B50": (
                "Boss_SharpssteelApplyBladePoseOffsets",
                ("move.w  $B2(a5),d3", "sub.w   d4,d3", "move.w  d3,$234(a5)"),
            ),
        }
        bases = []
        for address, (name, instructions) in cases.items():
            with self.subTest(address=address):
                record = by_address[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                for instruction in instructions:
                    self.assertIn(instruction, block.group(1))
        self.assertEqual(len(cases), len(set(bases)))
        self.assertNotIn(
            "Pose-buffer accesses and direct calls to the interpolation helpers "
            "establish this stage of blade pose processing.",
            bases,
        )

    def test_sharpssteel_collision_paths_distinguish_flags_from_values(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        source = (ROOT / "src/bosses/sharpssteel_blades.s").read_text(encoding="utf-8")
        cases = {
            "0x048734": (
                "Boss_SharpssteelEnableOuterBladeHitboxes",
                (
                    "bset    #6,$5C1(a5)",
                    "move.w  d1,$686(a5)",
                    "movea.w #(EleventhEntityType-M68K_RAM),a0",
                ),
            ),
            "0x04874E": (
                "Boss_SharpssteelEnableInnerBladeHitboxes",
                (
                    "bset    #6,$561(a5)",
                    "move.w  d1,$626(a5)",
                    "movea.w #(SeventhEntityType-M68K_RAM),a0",
                ),
            ),
            "0x048766": (
                "Boss_SharpssteelEnableLinkedBladeHitboxes",
                ("bset    d0,$21(a0)", "move.w  d1,$146(a0)"),
            ),
            "0x04878A": (
                "Boss_SharpssteelDisableOuterBladeHitboxes",
                (
                    "bclr    #6,$5C1(a5)",
                    "bra.s   Boss_SharpssteelDisableLinkedBladeHitboxes",
                ),
            ),
            "0x0487AC": (
                "Boss_SharpssteelDisableLinkedBladeHitboxes",
                ("bclr    d0,$21(a0)", "bclr    d0,$141(a0)"),
            ),
            "0x0487E4": (
                "Boss_SharpssteelEnableCoreSegmentCollision",
                ("move.w  #$50,d0", "or.b    d0,$201(a5)"),
            ),
        }
        bases = []
        blocks = {}
        for address, (name, instructions) in cases.items():
            with self.subTest(address=address):
                record = by_address[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                blocks[name] = block.group(1)
                for instruction in instructions:
                    self.assertIn(instruction, block.group(1))
        self.assertEqual(len(cases), len(set(bases)))
        for name in (
            "Boss_SharpssteelDisableOuterBladeHitboxes",
            "Boss_SharpssteelDisableLinkedBladeHitboxes",
            "Boss_SharpssteelEnableCoreSegmentCollision",
        ):
            self.assertNotRegex(
                blocks[name],
                r"(?m)^\s*move\.w\s+[^,;\r\n]+,\$[0-9A-F]*6\(a[05]\)",
                name,
            )
        self.assertEqual(
            6,
            len(
                re.findall(
                    r"(?m)^\s*or\.b\s+d0,\$[0-9A-F]+\(a5\)",
                    blocks["Boss_SharpssteelEnableCoreSegmentCollision"],
                )
            ),
        )

    def test_sharpssteel_blade_graphics_selectors_are_not_the_writer(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        source = (ROOT / "src/bosses/sharpssteel_blades.s").read_text(encoding="utf-8")
        cases = {
            "0x048898": (
                "Boss_SharpssteelSelectBladeGraphicsTableA",
                (
                    "lea     Boss_SharpssteelBladeGraphicsMappingsA(pc),a0",
                    "bra.s   Boss_SharpssteelApplyBladeGraphicsSet",
                ),
            ),
            "0x0488EA": (
                "Boss_SharpssteelSelectBladeGraphicsTableB",
                ("lea     Boss_SharpssteelBladeGraphicsMappingsB(pc),a0",),
            ),
            "0x0488F0": (
                "Boss_SharpssteelApplyBladeGraphicsSet",
                ("movea.w a5,a1", "moveq   #5,d7"),
            ),
            "0x0488F4": (
                "Boss_SharpssteelApplyBladeGraphicsSetLoop",
                (
                    "and.w   d2,$E(a1)",
                    "or.w    d1,$E(a1)",
                    "move.l  (a0)+,8(a1)",
                    "lea     $60(a1),a1",
                    "dbf     d7,Boss_SharpssteelApplyBladeGraphicsSetLoop",
                ),
            ),
        }
        bases = []
        for address, (name, instructions) in cases.items():
            with self.subTest(address=address):
                record = records[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = source.split(name + ":", 1)[1].split("\n;", 1)[0]
                for instruction in instructions:
                    self.assertIn(instruction, block)
        self.assertEqual(4, len(set(bases)))
        self.assertIn("bpl.s   Boss_SharpssteelSelectBladeGraphicsTableA", source)
        self.assertIn("bmi.s   Boss_SharpssteelSelectBladeGraphicsTableB", source)
        self.assertIn("bpl.s   Boss_SharpssteelSelectBladeGraphicsTableB", source)
        for suffix in ("A", "B"):
            table = source.split("Boss_SharpssteelBladeGraphicsMappings" + suffix + ":", 1)[1].split("\n\n", 1)[0]
            self.assertEqual(
                6,
                len(
                    re.findall(
                        rf"\bdc\.l\s+Boss_SharpssteelBladeGraphics{suffix}Mapping\d+",
                        table,
                    )
                ),
            )

    def test_medusa_falling_part_and_spawn_paths_have_local_evidence(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        source = (ROOT / "src/bosses/medusa.s").read_text(encoding="utf-8")
        cases = {
            "0x05717A": (
                "Entity_UpdateMedusaFallingPart",
                ("move.w  (PrimaryEntityXPos).w,$10(a5)", "jmp     (a0)"),
            ),
            "0x05719A": (
                "Entity_InitMedusaFallingPartState0",
                ("addq.w  #2,4(a5)", "move.w  #$128,$14(a5)"),
            ),
            "0x0571BC": (
                "Entity_ResetMedusaFallingPartState2",
                ("move.w  #2,4(a5)", "clr.l   $1C(a5)"),
            ),
            "0x0571CE": (
                "Entity_UpdateMedusaFallingPartState2",
                ("jsr     (Physics_CheckLowerTerrain).l", "btst    #0,6(a5)"),
            ),
            "0x0571DE": (
                "Entity_AdvanceMedusaFallingPartState4",
                ("move.w  #4,4(a5)", "clr.b   $56(a5)"),
            ),
            "0x0571EA": (
                "Entity_UpdateMedusaFallingPartState4",
                ("cmpi.w  #7,$1C(a5)", "addi.l  #$4000,$1C(a5)"),
            ),
            "0x0571FA": (
                "Entity_CheckMedusaFallingPartTerrain",
                (
                    "jsr     (Physics_CheckLowerTerrainWhenDescending).l",
                    "bne.w   Entity_ResetMedusaFallingPartState2",
                ),
            ),
            "0x05720C": (
                "Entity_UpdateMedusaScriptedSpawnSequence",
                (
                    "tst.w   (MedusaSpawnSequenceFlag).w",
                    "move.l  #Medusa_ScriptedSpawnSequenceData,$59C(a5)",
                ),
            ),
            "0x05723C": (
                "Entity_AdvanceMedusaSpawnSequenceSegment",
                ("addq.w  #2,d1", "move.l  a4,$59C(a5)"),
            ),
            "0x057244": (
                "Entity_CheckMedusaSpawnSequenceTrigger",
                ("cmp.w   d2,d4", "bpl.s   Entity_UpdateMedusaSpawnSequenceReturn"),
            ),
            "0x05724E": (
                "Entity_ProcessMedusaSpawnSequenceEntry",
                (
                    "addq.w  #8,(MedusaSequenceOffset).w",
                    "beq.w   Entity_ApplyMedusaSpawnSequenceCommand",
                ),
            ),
            "0x057264": (
                "Entity_SpawnMedusaSequenceObject",
                ("jsr     (Projectile_FindFreeSlotReverse).l", "jmp     Pickup_SpawnSmall"),
            ),
            "0x05729A": (
                "Entity_SpawnMedusaSequenceLargePickup",
                ("jmp     Pickup_SpawnLarge",),
            ),
            "0x0572A0": (
                "Entity_UpdateMedusaSpawnSequenceReturn",
                ("rts",),
            ),
            "0x0572A2": (
                "Entity_ApplyMedusaSpawnSequenceCommand",
                ("move.w  6(a4,d1.w),$47E(a5)", "move.w  4(a4,d1.w),$5E(a5)"),
            ),
            "0x0572B0": (
                "Medusa_ScriptedSpawnSequenceData",
                ('binclude "data/other/word_572B0.bin"',),
            ),
        }
        bases = []
        for address, (name, instructions) in cases.items():
            with self.subTest(address=address):
                record = by_address[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                for instruction in instructions:
                    self.assertIn(instruction, block.group(1))
        self.assertEqual(len(cases), len(set(bases)))

        table = source.split("Entity_MedusaFallingPartStateOffsets:", 1)[1].split(
            "Entity_InitMedusaFallingPartState0:", 1
        )[0]
        self.assertEqual(3, len(re.findall(r"\bdc\.w\s+", table)))
        for state_name in (
            "Entity_InitMedusaFallingPartState0",
            "Entity_UpdateMedusaFallingPartState2",
            "Entity_UpdateMedusaFallingPartState4",
        ):
            self.assertIn(state_name + "-Entity_InitMedusaFallingPartState0", table)
        assets = json.loads((ROOT / "assets/manifest.json").read_text(encoding="utf-8"))["assets"]
        asset = next(item for item in assets if item["path"] == "other/word_572B0.bin")
        self.assertEqual("0x572B0", asset["address"])
        self.assertEqual("0x573E6", asset["end"])

    def test_sirene_type490_steers_toward_entity57_not_player(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        source = (ROOT / "src/bosses/sirene.s").read_text(encoding="utf-8")
        cases = {
            "0x057DF4": (
                "Projectile_UpdateSireneHoming",
                ("cmpi.w  #$88,$14(a5)", "cmpi.w  #$26C,d0"),
            ),
            "0x057E18": (
                "Projectile_RemoveSireneHomingOutsideBounds",
                ("bset    #4,2(a5)", "rts"),
            ),
            "0x057E20": (
                "Projectile_ProcessSireneHomingInBounds",
                ("tst.w   (StageSpawnCountdown).w", "bclr    #7,$22(a5)"),
            ),
            "0x057E54": (
                "Projectile_InitSireneHomingPickupDrop",
                ("move.w  $10(a5),$10(a0)", "jsr     (Pickup_SelectRandomSize).l"),
            ),
            "0x057E66": (
                "Projectile_ConvertSireneHomingToParticle",
                ("move.b  #$2F,d0", "jmp     Sprite_InitType160FromCurrent"),
            ),
            "0x057E7E": (
                "Projectile_SteerSireneHomingTowardEntity57",
                ("move.w  (Entity57XPos).w,d0", "jsr     (Math_Arctan2Lookup).l"),
            ),
        }
        bases = []
        for address, (name, instructions) in cases.items():
            with self.subTest(address=address):
                record = by_address[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                for instruction in instructions:
                    self.assertIn(instruction, block.group(1))
        self.assertEqual(len(cases), len(set(bases)))
        self.assertEqual(
            "Projectile_HomeSireneProjectileTowardPlayer",
            by_address["0x057E7E"]["previous_name"],
        )
        self.assertEqual("loc_57E7E", by_address["0x057E7E"]["legacy_name"])
        self.assertNotIn("Projectile_HomeSireneProjectileTowardPlayer", source)
        effect_init = source.split("Gfx_InitSireneBattleEffect:", 1)[1].split(
            "Gfx_UpdateSireneBattleEffectPattern:", 1
        )[0]
        self.assertIn("movea.w #(Entity57Type-M68K_RAM),a0", effect_init)
        self.assertIn("move.w  #$48C,(a0)", effect_init)
        steering = source.split("Projectile_SteerSireneHomingTowardEntity57:", 1)[1]
        self.assertIn("move.w  (Entity57YPos).w,d1", steering)
        self.assertIn("add.l   d0,$14(a5)", steering)
        self.assertIn("add.l   d1,$10(a5)", steering)
        self.assertNotIn("PlayerXPosition", steering)
        self.assertNotIn("PlayerYPosition", steering)

    def test_sirene_effect_entries_have_separate_instruction_evidence(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        source = (ROOT / "src/bosses/sirene.s").read_text(encoding="utf-8")
        cases = {
            "0x0579B2": (
                "Gfx_InitSireneBattleEffect",
                ("move.w  #$48C,(a0)", "move.b  #6,(VDPReg11Shadow+1).w", "move.w  #$400,(PaletteActiveColor29).w"),
            ),
            "0x0579F4": (
                "Gfx_UpdateSireneBattleEffectPattern",
                (
                    "movea.w #(SirenePatternBuffer-M68K_RAM),a0",
                    "move.l  #$D0D0D0D0,d0",
                    "move.l  #$DDDDDDDD,d1",
                    "exg     d0,d1",
                ),
            ),
            "0x057A0E": (
                "Gfx_WriteSireneBattlePattern",
                (
                    "move.l  d0,(a0)+",
                    "move.l  d1,(a0)+",
                    "move.l  #$94009310,d4",
                    "jsr     (VDP_QueueCommand_Build).l",
                    "move.w  #$820,(PaletteActiveColor30).w",
                ),
            ),
            "0x057A58": (
                "Gfx_SetSireneAlternatePatternAndPalette",
                (
                    "move.w  #$E0,(SirenePatternAltA).w",
                    "move.w  #$F0,(SirenePatternAltB).w",
                    "move.w  #$E00,(PaletteActiveColor30).w",
                    "move.w  #$A00,(PaletteActiveColor31).w",
                ),
            ),
        }
        bases = []
        blocks = {}
        for address, (name, instructions) in cases.items():
            with self.subTest(address=address):
                record = records[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = re.search(
                    rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                blocks[name] = block.group(1)
                for instruction in instructions:
                    self.assertIn(instruction, block.group(1))
        self.assertEqual(4, len(set(bases)))
        self.assertNotIn("SirenePatternBuffer", blocks["Gfx_InitSireneBattleEffect"])
        self.assertNotIn(
            "VDP_QueueCommand_Build",
            blocks["Gfx_SetSireneAlternatePatternAndPalette"],
        )
        self.assertIn(
            "bne.s   Gfx_SetSireneAlternatePatternAndPalette",
            blocks["Gfx_WriteSireneBattlePattern"],
        )
        self.assertEqual("loc_57A58", records["0x057A58"]["legacy_name"])
        self.assertNotIn("Gfx_UseSireneAlternateBattlePattern", source)

    def test_weapon_setup_highlight_palette_roles_are_not_background(self) -> None:
        records = json.loads(AUDIT.read_text(encoding="utf-8"))["records"]
        by_address = {record["address"]: record for record in records}
        source = (ROOT / "src/ui/weapon_setup_screen.s").read_text(encoding="utf-8")
        cases = {
            "0x01F7BE": ("WeaponSetup_UpdateHighlightPalette", "WeaponSetupHighlight"),
            "0x01F7D0": (
                "WeaponSetup_AdvanceHighlightPaletteCycle",
                "subq.w  #2,(WeaponSetupHighlight).w",
            ),
            "0x01F7D4": (
                "WeaponSetup_WriteHighlightPaletteColors",
                "andi.w  #$E,d0",
            ),
            "0x01F7E6": (
                "WeaponSetup_HighlightPaletteColor1Cycle",
                "dc.w    $400, $400",
            ),
            "0x01F7F6": (
                "WeaponSetup_HighlightPaletteColor2Cycle",
                "dc.w    $EEE, $EEC",
            ),
        }
        bases = []
        for address, (name, instruction) in cases.items():
            with self.subTest(address=address):
                record = by_address[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                bases.extend(record["basis"])
                block = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                self.assertIn(instruction, block.group(1))
        self.assertEqual(len(cases), len(set(bases)))
        writer = source.split("WeaponSetup_WriteHighlightPaletteColors:", 1)[1].split(
            "WeaponSetup_HighlightPaletteColor1Cycle:", 1
        )[0]
        self.assertIn("(PaletteActiveColor49).w", writer)
        self.assertIn("(PaletteActiveColor50).w", writer)
        for name in (
            "WeaponSetup_HighlightPaletteColor1Cycle",
            "WeaponSetup_HighlightPaletteColor2Cycle",
        ):
            table = source.split(name + ":", 1)[1].splitlines()[0]
            self.assertEqual(8, len(table.split(";", 1)[0].split(",")))

    def test_stage10_wasp_review_pins_streams_and_mapping_ends(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("One or more of the four streams selected"))
        expected = [f"Enemy_Stage10WaspSpriteMapping{chr(letter)}" for letter in range(ord("A"), ord("M") + 1)]
        self.assertEqual(expected, [member["current_name"] for member in review["members"]])
        self.assertEqual(
            {"src/data/stage10_wasp_sprite_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/stage10_wasp_sprite_mappings.s").read_text(encoding="utf-8")
        stream_start = data.index("Enemy_Stage10WaspSelector04Animation:")
        targets = re.findall(
            r"\bdc\.w\s+(Enemy_Stage10WaspSpriteMapping[A-M])-\*",
            data[stream_start:],
        )
        self.assertEqual(set(expected), set(targets))
        for name in expected:
            with self.subTest(name=name):
                mapping = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    data,
                )
                self.assertIsNotNone(mapping)
                command_words = re.findall(r"\bdc\.w\s+\$([0-9A-F]+)", mapping.group(1))
                self.assertTrue(command_words)
                self.assertNotEqual(0, int(command_words[-1], 16) & 0x8000)
        wasp = (ROOT / "src/enemies/stage_10_wasp_and_falling_shot.s").read_text(encoding="utf-8")
        selector_table = wasp.split("Enemy_Stage10WaspAnimationMappings:", 1)[1].split("\n\n", 1)[0]
        self.assertEqual(
            ["04", "08", "0C", "10"],
            re.findall(
                r"\bdc\.l\s+Enemy_Stage10WaspSelector([0-9A-F]{2})Animation",
                selector_table,
            ),
        )
        self.assertIn("move.l  Enemy_Stage10WaspAnimationMappings(pc,d0.w),8(a5)", wasp)
        self.assertIn("move.l  #Enemy_Stage10WaspSelector0CAnimation,8(a5)", wasp)

    def test_phase_pattern_return_review_pins_four_countdowns(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"] == "The frames before that timer expires return here.")
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        source = (ROOT / "src/enemies/phase_and_debris_states.s").read_text(encoding="utf-8")
        cases = (
            ("0x02D136", "WaitBeforeAttack", ("move.w  #$14,$5C(a5)", "addq.w  #2,4(a5)")),
            ("0x02D154", "BeginHorizontalMotion", ("move.w  #$1C,$5C(a5)", "move.w  #$FFFF,$18(a5)")),
            ("0x02D170", "StopHorizontalMotion", ("clr.w   $18(a5)", "move.w  #$18,$5C(a5)")),
            ("0x02D18A", "Restart", ("move.w  #$100,$48(a5)", "move.w  #2,4(a5)")),
        )
        expected_members = []
        for address, suffix, expiry_instructions in cases:
            with self.subTest(address=address):
                state = f"Enemy_PhasePattern_{suffix}"
                return_label = state + "_Return"
                expected_members.append((address, return_label))
                self.assertEqual(return_label, records[address]["current_name"])
                self.assertEqual([review["basis"]], records[address]["basis"])
                body = source.split(state + ":", 1)[1].split("; End of function " + state, 1)[0]
                self.assertIn("subq.w  #1,$48(a5)", body)
                self.assertIn(f"bne.s   {return_label}", body)
                self.assertIn(return_label + ":", body)
                self.assertRegex(body, rf"(?s){return_label}:.*?\n\s+rts")
                self.assertIn(f"dc.w    {state}-*", source)
                for instruction in expiry_instructions:
                    self.assertIn(instruction, body)
        self.assertEqual(
            expected_members,
            [(item["address"], item["current_name"]) for item in review["members"]],
        )

    def test_phase_pattern_review_pins_seven_streams_and_mapping_ends(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("One or more entries in the seven-stream"))
        expected = [f"Enemy_PhasePatternSpriteMapping{chr(letter)}" for letter in range(ord("A"), ord("Q") + 1)]
        self.assertEqual(expected, [member["current_name"] for member in review["members"]])
        self.assertEqual(
            {"src/data/phase_pattern_sprite_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/phase_pattern_sprite_mappings.s").read_text(encoding="utf-8")
        stream_start = data.index("Enemy_PhasePatternSelector08Animation:")
        targets = re.findall(
            r"\bdc\.w\s+(Enemy_PhasePatternSpriteMapping[A-Q])-\*",
            data[stream_start:],
        )
        self.assertEqual(set(expected), set(targets))
        for name in expected:
            with self.subTest(name=name):
                mapping = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    data,
                )
                self.assertIsNotNone(mapping)
                command_words = re.findall(r"\bdc\.w\s+\$([0-9A-F]+)", mapping.group(1))
                self.assertTrue(command_words)
                self.assertNotEqual(0, int(command_words[-1], 16) & 0x8000)
        helpers = (ROOT / "src/enemies/shared_enemy_helpers.s").read_text(encoding="utf-8")
        selector_table = helpers.split("Enemy_PhasePatternAnimationBySelector:", 1)[1].split("\n\n", 1)[0]
        self.assertEqual(
            ["04", "08", "0C", "10", "14", "18", "1C"],
            re.findall(
                r"\bdc\.l\s+Enemy_PhasePatternSelector([0-9A-F]{2})Animation",
                selector_table,
            ),
        )
        self.assertIn(
            "move.l  Enemy_PhasePatternAnimationBySelector(pc,d0.w),8(a5)",
            helpers,
        )

    def test_boss_metasprite_descriptor_reviews_pin_member_tables(self) -> None:
        reviews = {
            review["basis"]: review
            for review in json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))[
                "reviews"
            ]
        }
        antroid = (ROOT / "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s").read_text(encoding="utf-8")
        antroid_review = reviews[
            "Antroid's secondary descriptor array references this three-word inline sprite descriptor."
        ]
        self.assertEqual(
            [
                (f"0x{address:06X}", f"Boss_AntroidInlineSpriteDescriptor{suffix}")
                for address, suffix in zip((0x3499E, 0x349A4, 0x349AA, 0x349B0), "DEFG")
            ],
            [(item["address"], item["current_name"]) for item in antroid_review["members"]],
        )
        secondary = antroid.split("Boss_AntroidSecondaryMetaspriteDescriptors:", 1)[1].split(
            "Boss_AntroidPrimaryPartRadii:", 1
        )[0]
        secondary_slots = re.findall(r"\bdc\.l\s+([^\s;]+)", secondary)
        for suffix, index in (("D", 0), ("F", 2), ("E", 7), ("G", 9)):
            name = f"Boss_AntroidInlineSpriteDescriptor{suffix}"
            self.assertEqual(name + "+1", secondary_slots[index])
            descriptor = antroid.split(name + ":", 1)[1].split("\n", 1)[0]
            words = descriptor.split("dc.w", 1)[1].split(";", 1)[0].split(",")
            self.assertEqual(3, len(words))
        antroid_core = (ROOT / "src/bosses/antroid_core.s").read_text(encoding="utf-8")
        self.assertIn("movea.l #Boss_AntroidSecondaryMetaspriteDescriptors,a0", antroid_core)
        self.assertIn(
            "jsr     (Sprite_InitializeAdditionalLinkedMetaspriteParts).l",
            antroid_core,
        )

        metasprites = (
            ROOT / "src/data/madam_barbar_flying_neo_joker_back_stringer_sharpssteel_metasprites.s"
        ).read_text(encoding="utf-8")
        cases = (
            (
                "BackStringer",
                "Back Stringer",
                (0x350E6, 0x35106, 0x35126, 0x35146),
                "src/bosses/back_stringer_core.s",
            ),
            (
                "MadamBarbar",
                "Madam Barbar",
                (0x34DB6, 0x34DD6, 0x34DF6, 0x34E16),
                "src/bosses/madam_barbar_core.s",
            ),
        )
        for owner, display_name, addresses, core_path in cases:
            with self.subTest(owner=owner):
                basis = f"{display_name}'s descriptors reference this directional mapping-pointer table."
                review = reviews[basis]
                names = [f"Boss_{owner}RotationFrames{suffix}" for suffix in "ABCD"]
                self.assertEqual(
                    [(f"0x{address:06X}", name) for address, name in zip(addresses, names)],
                    [(item["address"], item["current_name"]) for item in review["members"]],
                )
                tables = []
                for name in names:
                    block = re.search(
                        rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                        metasprites,
                    )
                    self.assertIsNotNone(block)
                    pointers = re.findall(r"\bdc\.l\s+([A-Za-z_]\w+)", block.group(1))
                    self.assertEqual(8, len(pointers))
                    self.assertTrue(all(pointer.startswith(f"Boss_{owner}Rotation") for pointer in pointers))
                    tables.append(pointers)
                self.assertEqual(tables[0], list(reversed(tables[1])))
                self.assertEqual(tables[2], list(reversed(tables[3])))
                descriptors = metasprites.split(f"Boss_{owner}MetaspriteDescriptors:", 1)[1].split(
                    f"Boss_{owner}PartRadii:", 1
                )[0]
                for name in names:
                    self.assertRegex(descriptors, rf"\bdc\.l\s+{name}(?:\+\$[0-9A-F]+)?\b")
                core = (ROOT / core_path).read_text(encoding="utf-8")
                self.assertIn(f"movea.l #Boss_{owner}MetaspriteDescriptors,a0", core)
                self.assertIn("jsr     (Sprite_InitializeLinkedMetaspriteParts).l", core)
        helper = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        self.assertIn(
            "bne.s   Sprite_InitializeLinkedMetaspritePartsUseInlineDescriptor",
            helper,
        )
        self.assertIn(
            "beq.s   Sprite_InitializeLinkedMetaspritePartsUseRotationFrames",
            helper,
        )

    def test_xi_tiger_rotation_review_pins_both_reversed_frame_sets(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item
            for item in reviews
            if item["basis"] == ("Xi-Tiger's descriptors reference this directional mapping-pointer table.")
        )
        names = [f"Boss_XiTigerRotationFrames{suffix}" for suffix in "ABCD"]
        self.assertEqual(
            [
                (f"0x{address:06X}", name, "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s")
                for address, name in zip((0x34C64, 0x34C84, 0x34CA4, 0x34CC4), names)
            ],
            [(item["address"], item["current_name"], item["file"]) for item in review["members"]],
        )
        source = (ROOT / "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s").read_text(encoding="utf-8")
        tables = []
        for name in names:
            block = re.search(
                rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                source,
            )
            self.assertIsNotNone(block)
            pointers = re.findall(r"\bdc\.l\s+([A-Za-z_]\w+)", block.group(1))
            self.assertEqual(8, len(pointers))
            tables.append(pointers)
        self.assertEqual(tables[0], list(reversed(tables[2])))
        self.assertEqual(tables[1], list(reversed(tables[3])))
        for table, set_name in zip(tables, "ABAB"):
            self.assertTrue(all(pointer.startswith(f"Boss_XiTigerRotationSet{set_name}Frame") for pointer in table))
        descriptors = source.split("Boss_XiTigerMetaspriteDescriptors:", 1)[1].split("Boss_XiTigerPartRadii:", 1)[0]
        for name in names:
            self.assertRegex(descriptors, rf"\bdc\.l\s+{name}(?:\+\$[0-9A-F]+)?\b")
        core = (ROOT / "src/bosses/xi_tiger_battle_states.s").read_text(encoding="utf-8")
        self.assertIn("movea.l #Boss_XiTigerMetaspriteDescriptors,a0", core)
        self.assertIn("jsr     (Sprite_InitializeLinkedMetaspriteParts).l", core)
        helper = (ROOT / "src/rendering/boss_metasprites.s").read_text(encoding="utf-8")
        self.assertIn("move.l  d4,$4C(a4)", helper)

    def test_pose_channel_review_pins_nineteen_channel_wrappers(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item
            for item in reviews
            if item["basis"]
            == (
                "The wrapper supplies D7 value eighteen and the shared "
                "interpolation workspace to Anim_InitializePoseChannelsFromBytes."
            )
        )
        expected = (
            ("0x0507DC", "Boss_WolfGaropaInitializePoseChannels", "src/projectiles/wolf_garopa.s"),
            (
                "0x051808",
                "Debug_ValkirieSecondaryViewerInitializePoseChannels",
                "src/debug/valkirie_secondary_composite_viewer.s",
            ),
            (
                "0x051A9C",
                "Debug_ValkirieTertiaryViewerInitializePoseChannels",
                "src/debug/valkirie_tertiary_composite_viewer.s",
            ),
            ("0x056238", "Boss_ValkirieInitializePoseChannels", "src/bosses/valkirie_rendering.s"),
        )
        self.assertEqual(
            list(expected),
            [(item["address"], item["current_name"], item["file"]) for item in review["members"]],
        )
        for _, name, path in expected:
            with self.subTest(name=name):
                source = (ROOT / path).read_text(encoding="utf-8")
                wrapper = source.split(name + ":", 1)[1].split("; End of function " + name, 1)[0]
                self.assertRegex(
                    wrapper,
                    r"(?s)moveq\s+#\$12,d7.*?"
                    r"movea\.w #\(SharedPatternRow0Long0-M68K_RAM\),a1.*?"
                    r"jmp\s+Anim_InitializePoseChannelsFromBytes",
                )
        helper = (
            (ROOT / "src/rendering/boss_metasprites.s")
            .read_text(encoding="utf-8")
            .split("Anim_InitializePoseChannelsFromBytes:", 1)[1]
            .split("; End of function Anim_InitializePoseChannelsFromBytes", 1)[0]
        )
        for instruction in (
            "moveq   #0,d1",
            "move.b  (a0)+,d0",
            "asl.w   #8,d0",
            "move.w  d0,(a1)+",
            "move.w  d1,(a1)+",
            "dbf     d7,Anim_InitializePoseChannelsFromBytesNextChannel",
        ):
            self.assertIn(instruction, helper)
        original_viewer = (
            (ROOT / "src/debug/valkirie_composite_viewer.s")
            .read_text(encoding="utf-8")
            .split("Debug_ValkirieViewerInitializePoseChannels:", 1)[1]
            .split("; End of function Debug_ValkirieViewerInitializePoseChannels", 1)[0]
        )
        self.assertIn("moveq   #$10,d7", original_viewer)

    def test_shared_projectile_mapping_review_pins_three_timing_streams(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("The three shared projectile streams"))
        expected = [f"SharedProjectileSpriteMapping{suffix}" for suffix in "ABCD"]
        self.assertEqual(
            [(f"0x{address:06X}", name) for address, name in zip((0x1A0CA6, 0x1A0CAC, 0x1A0CB2, 0x1A0CB8), expected)],
            [(item["address"], item["current_name"]) for item in review["members"]],
        )
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        for member in review["members"]:
            self.assertEqual([review["basis"]], records[member["address"]]["basis"])
        source = (ROOT / "src/data/shared_stage_object_sprite_mappings.s").read_text(encoding="utf-8")
        for name in expected:
            mapping = re.search(
                rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                source,
            )
            self.assertIsNotNone(mapping)
            command = re.search(
                r"\bdc\.w\s+\$([0-9A-F]+),\s*([^,]+),\s*([^\s;]+)",
                mapping.group(1),
            )
            self.assertIsNotNone(command)
            self.assertNotEqual(0, int(command.group(1), 16) & 0x8000)
            self.assertEqual(1, len(re.findall(r"\bdc\.w\b", mapping.group(1))))
        for duration in (2, 4, 8):
            with self.subTest(duration=duration):
                name = f"SharedProjectileDuration{duration}Animation"
                stream = re.search(
                    rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(stream)
                words = re.findall(
                    r"\bdc\.w\s+([A-Za-z_]\w*-\*|\$[0-9A-F]+|\d+)",
                    stream.group(1),
                )
                self.assertEqual(
                    [word for mapping in expected[:3] for word in (mapping + "-*", str(duration))]
                    + [expected[3] + "-*", "$FF"],
                    words,
                )
        snake = (ROOT / "src/bosses/snake.s").read_text(encoding="utf-8")
        choices = snake.split("Boss_SnakeShotMappingChoices:", 1)[1].split("; Turns toward the target", 1)[0]
        self.assertEqual(
            [4, 2, 4, 8],
            [int(number) for number in re.findall(r"\bdc\.l\s+SharedProjectileDuration(\d+)Animation", choices)],
        )
        for path in (
            "src/enemies/stage_12_enemies.s",
            "src/bosses/gusthead_tentacles.s",
            "src/projectiles/shared_directional_volley_helpers.s",
            "src/enemies/bouncing_object.s",
        ):
            with self.subTest(path=path):
                self.assertIn(
                    "#SharedProjectileDuration4Animation",
                    (ROOT / path).read_text(encoding="utf-8"),
                )

    def test_teddy_bear_mapping_review_pins_stream_targets_and_terminators(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("A Stage 12 Teddy Bear animation stream"))
        expected = [f"Stage12_TeddyBearSpriteMapping{chr(letter)}" for letter in range(ord("A"), ord("R") + 1)]
        self.assertEqual(expected, [member["current_name"] for member in review["members"]])
        self.assertEqual(
            {"src/data/shared_stage_object_sprite_mappings.s"},
            {member["file"] for member in review["members"]},
        )
        data = (ROOT / "src/data/shared_stage_object_sprite_mappings.s").read_text(encoding="utf-8")
        streams = data.split("; Animation streams", 1)[1]
        targets = re.findall(r"\bdc\.w\s+(Stage12_TeddyBearSpriteMapping[A-R])-\*", streams)
        self.assertEqual(set(expected), set(targets))
        for name in expected:
            with self.subTest(name=name):
                mapping = re.search(
                    r"(?ms)^" + re.escape(name) + r":(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    data,
                )
                self.assertIsNotNone(mapping)
                command_words = re.findall(r"\bdc\.w\s+\$([0-9A-F]+)", mapping.group(1))
                self.assertTrue(command_words)
                self.assertNotEqual(0, int(command_words[-1], 16) & 0x8000)
        resolver = (ROOT / "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
        self.assertIn("adda.w  (a4),a4", resolver)

    def test_teddy_bear_variant_streams_name_content_not_reachability(self) -> None:
        records = {record["address"]: record for record in json.loads(AUDIT.read_text(encoding="utf-8"))["records"]}
        source = (ROOT / "src/data/shared_stage_object_sprite_mappings.s").read_text(encoding="utf-8")
        variants = {
            "A": ("0x1A0EEA", "E G H G", "4 1 3 1"),
            "B": ("0x1A0EFE", "G H E F E H", "4 2 2 4 2 2"),
            "C": ("0x1A0F56", "O A", "9 9"),
            "D": ("0x1A0FBE", "P Q R Q", "7 6 7 6"),
        }
        bases = []
        for suffix, (address, frames, durations) in variants.items():
            with self.subTest(suffix=suffix):
                name = f"Stage12_TeddyBearAnimationVariant{suffix}"
                record = records[address]
                self.assertEqual(name, record["current_name"])
                self.assertEqual("static", record["evidence"])
                self.assertEqual(1, len(record["basis"]))
                self.assertIn("indirect reachability is untested", record["basis"][0])
                bases.extend(record["basis"])
                block = re.search(
                    rf"(?ms)^{name}:(.*?)(?=^[A-Za-z_][A-Za-z0-9_]*:|\Z)",
                    source,
                )
                self.assertIsNotNone(block)
                words = re.findall(r"\bdc\.w\s+([A-Za-z_]\w*-\*|\d+)", block.group(1))
                expected = []
                for frame, duration in zip(frames.split(), durations.split()):
                    expected.extend((f"Stage12_TeddyBearSpriteMapping{frame}-*", duration))
                expected.extend((f"{name}-*", "0"))
                self.assertEqual(expected, words)
        self.assertEqual(4, len(set(bases)))
        self.assertNotIn("UnreferencedTeddyGroupAnimation", source)

    def test_weapon_setup_text_review_decodes_labels_and_has_render_refs(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("The encoded glyph bytes decode"))
        expected = {
            "WeaponSetup_HeadingText": "SETUP YOUR WEAPONS",
            "WeaponSetup_BusterForceText": "BUSTER FORCE",
            "WeaponSetup_RangerForceText": "RANGER FORCE",
            "WeaponSetup_FlameForceText": "FLAME FORCE",
            "WeaponSetup_HomingForceText": "HOMING FORCE",
            "WeaponSetup_SwordForceText": "SWORD FORCE",
            "WeaponSetup_LancerForceText": "LANCER FORCE",
            "WeaponSetup_ShootingModeText": "SHOOTING MODE",
            "WeaponSetup_MovingModeText": "MOVING",
            "WeaponSetup_FixedModeText": "FIX",
            "WeaponSetup_StatusWindowText": "STATUS WINDOW",
            "WeaponSetup_ExitText": "EXIT",
            "WeaponSetup_ControlTestText": "CONTROL TEST",
            "WeaponSetup_WeaponSelectControlText": "WEAPON SELECT",
            "WeaponSetup_ShotControlText": "SHOT",
            "WeaponSetup_JumpControlText": "JUMP",
            "WeaponSetup_ShootingModeChangeControlText": "SHOOT MODE CHANGE",
            "WeaponSetup_ZeroTeleportControlText": "ZERO TELEPORT",
            "WeaponSetup_CounterForceControlText": "COUNTER FORCE",
            "WeaponSetup_HoveringControlText": "HOVERING",
        }
        self.assertEqual(set(expected), {member["current_name"] for member in review["members"]})
        data = (ROOT / "src/ui/weapon_setup_background_and_text.s").read_text(encoding="utf-8")
        screen = (ROOT / "src/ui/weapon_setup_screen.s").read_text(encoding="utf-8")
        for name, decoded in expected.items():
            with self.subTest(name=name):
                definition = re.search(r"(?m)^" + re.escape(name) + r":\s+dc\.b\b", data)
                self.assertIsNotNone(definition)
                tail = data[definition.start() :]
                next_line = tail.index("\n") + 1
                next_label = re.search(r"(?m)^[A-Za-z_][A-Za-z0-9_]*:", tail[next_line:])
                body = tail[: next_line + next_label.start()] if next_label else tail
                operands = re.findall(r"\bdc\.b\s+([^;\r\n]+)", body)
                values = [
                    int(token.strip()[1:], 16) if token.strip().startswith("$") else int(token.strip())
                    for row in operands
                    for token in row.split(",")
                ]
                letters = []
                for value in values:
                    if value == 0:
                        letters.append(" ")
                    elif 0xB <= value <= 0x24:
                        letters.append(chr(ord("A") + value - 0xB))
                    else:
                        break
                self.assertEqual(decoded, "".join(letters).strip())
                self.assertRegex(screen, r"\b(?:lea|dc\.l)\s+" + re.escape(name) + r"\b")

    def test_control_type_text_review_matches_table_slots_and_decimal_bytes(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("WeaponSetup_ControlTypeTextPointers selects")
        )
        data = (ROOT / "src/ui/weapon_setup_background_and_text.s").read_text(encoding="utf-8")
        encoded = re.findall(
            r"(?m)^WeaponSetup_ControlType(\d\d)Text:\s+dc\.b\s+([^;\r\n]+)",
            data,
        )
        self.assertEqual(26, len(encoded))
        self.assertEqual(
            [member["current_name"] for member in review["members"]],
            [f"WeaponSetup_ControlType{suffix}Text" for suffix, _ in encoded],
        )
        for index, (suffix, operands) in enumerate(encoded, 1):
            with self.subTest(control_type=index):
                self.assertEqual(f"{index:02}", suffix)
                values = [
                    int(token.strip()[1:], 16) if token.strip().startswith("$") else int(token.strip())
                    for token in operands.split(",")
                ]
                digits = [index + 1, 0] if index < 10 else [index // 10 + 1, index % 10 + 1]
                self.assertEqual([0x1E, 0x23, 0x1A, 0x0F, 0x2E, *digits, 0xFF], values)
        source = (ROOT / "src/ui/weapon_setup_screen.s").read_text(encoding="utf-8")
        table = source.split("WeaponSetup_ControlTypeTextPointers:", 1)[1].split("WeaponSetup_ControlTypeValues:", 1)[0]
        pointers = re.findall(r"\bdc\.l\s+(WeaponSetup_ControlType\d\dText)\b", table)
        self.assertEqual([member["current_name"] for member in review["members"]], pointers)
        renderer = source.split("WeaponSetup_RenderSelectedControlType:", 1)[1].split(
            "; End of function WeaponSetup_RenderSelectedControlType", 1
        )[0]
        self.assertRegex(renderer, r"move\.w\s+\(WeaponSetupControlIndex\)\.w,d1")
        self.assertRegex(renderer, r"asl\.w\s+#2,d1")
        self.assertRegex(renderer, r"movea\.l\s+\(a0,d1\.w\),a0")

    def test_shellshogun_mapping_review_matches_all_pointer_owners(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("Boss_Shellshogun pointer tables"))
        data = (ROOT / "src/data/antroid_terobuster_shellshogun_xi_tiger_metasprites.s").read_text(encoding="utf-8")
        renderer = (ROOT / "src/bosses/shellshogun_rendering.s").read_text(encoding="utf-8")
        core = (ROOT / "src/bosses/shellshogun_core.s").read_text(encoding="utf-8")
        owners = set(
            re.findall(
                r"\b(?:dc\.l|move\.l)\s+#?(Boss_ShellshogunSpriteMapping\d\d)\b",
                data + renderer + core,
            )
        )
        self.assertEqual({member["current_name"] for member in review["members"]}, owners)
        tables = data[
            data.index("Boss_ShellshogunRotationFramesA:") : data.index("Boss_ShellshogunInlineSpriteDescriptorA:")
        ]
        starts = list(re.finditer(r"(?m)^Boss_ShellshogunRotationFrames[A-F]:", tables))
        self.assertEqual(6, len(starts))
        for index, start in enumerate(starts):
            segment = (
                tables[start.start() : starts[index + 1].start()]
                if index + 1 < len(starts)
                else tables[start.start() :]
            )
            self.assertEqual(
                8,
                len(re.findall(r"\bdc\.l\s+Boss_ShellshogunSpriteMapping\d\d", segment)),
            )
        rotating = renderer.split("Boss_ShellshogunRotatingPartFrameTable:", 1)[1]
        self.assertEqual(
            ["29", "28", "27", "28"],
            re.findall(r"\bdc\.l\s+Boss_ShellshogunSpriteMapping(\d\d)", rotating),
        )

    def test_enemy_projectile_mapping_review_matches_animation_targets(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("Named Enemy_Projectile animation streams"))
        source = (ROOT / "src/data/enemy_projectile_animation_mappings.s").read_text(encoding="utf-8")
        targets = set(re.findall(r"\bdc\.w\s+(Enemy_ProjectileSpriteMapping\d\d)-\*", source))
        self.assertEqual({member["current_name"] for member in review["members"]}, targets)
        headers = set(re.findall(r"(?m)^(Enemy_ProjectileAnimation\d\d):", source))
        controller = (ROOT / "src/enemies/jetsripper_stage_actors.s").read_text(encoding="utf-8")
        pointer_table = controller.split("Enemy_ProjectileAnimationPointers:", 1)[1].split(
            "Physics_SetHorizontalVelocityByFlip:", 1
        )[0]
        pointers = re.findall(r"\bdc\.l\s+(Enemy_ProjectileAnimation\d\d)\b", pointer_table)
        self.assertEqual(10, len(pointers))
        self.assertEqual(headers, set(pointers))
        self.assertRegex(
            controller,
            r"move\.l\s+Enemy_ProjectileAnimationPointers\(pc,d0\.w\),8\(a5\)",
        )

    def test_seven_forces_rotation_review_matches_tables_and_eight_slot_mask(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(
            item for item in reviews if item["basis"].startswith("The eight-direction SevenForcesRotationFrameTable0")
        )
        source = (ROOT / "src/rendering/seven_forces_metasprites.s").read_text(encoding="utf-8")
        tables = source[
            source.index("SevenForcesRotationFrameTable0:") : source.index("SevenForcesInlinePartDescriptor0:")
        ]
        starts = list(re.finditer(r"(?m)^SevenForcesRotationFrameTable[0-8]:", tables))
        self.assertEqual(9, len(starts))
        segments = [
            tables[start.start() : starts[index + 1].start()] if index + 1 < len(starts) else tables[start.start() :]
            for index, start in enumerate(starts)
        ]
        pointers = [re.findall(r"\bdc\.l\s+(SevenForcesRotationSpriteFrame\d\d)\b", segment) for segment in segments]
        self.assertEqual([8, 16, 8, 8, 8, 8, 8, 8, 8], list(map(len, pointers)))
        self.assertEqual(
            {member["current_name"] for member in review["members"]},
            {target for segment in pointers for target in segment},
        )
        renderer = (
            (ROOT / "src/rendering/boss_metasprites.s")
            .read_text(encoding="utf-8")
            .split("Sprite_ApplyMetaspriteEightFrameRotation:", 1)[1]
            .split("; End of function Sprite_ApplyMetaspriteEightFrameRotation", 1)[0]
        )
        self.assertRegex(renderer, r"andi\.w\s+#\$1C,d1")
        self.assertRegex(renderer, r"move\.l\s+\(a0,d1\.w\),8\(a4\)")

    def test_shared_combat_reviews_match_relative_streams_and_renderer(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        frames_review = next(
            review for review in reviews if review["basis"].startswith("A SharedCombatSpriteAnimation stream names")
        )
        animations_review = next(
            review for review in reviews if review["basis"].startswith("Anim_ResolveTimedMappingFrame reads")
        )
        streams = (ROOT / "src/data/shared_combat_sprite_animations.s").read_text(encoding="utf-8")
        frame_targets = set(re.findall(r"\bdc\.w\s+(SharedCombatSpriteFrame\d\d)-\*", streams))
        self.assertIn("SharedCombatSpriteFrame06", frame_targets)
        frame_targets.remove("SharedCombatSpriteFrame06")
        self.assertEqual(
            {member["current_name"] for member in frames_review["members"]},
            frame_targets,
        )
        stream_headers = set(
            re.findall(
                r"(?m)^(SharedCombatSpriteAnimation\d\d):\s+dc\.w\s+SharedCombatSpriteFrame\d\d-\*",
                streams,
            )
        )
        self.assertEqual(
            {member["current_name"] for member in animations_review["members"]},
            stream_headers,
        )
        renderer = (ROOT / "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
        self.assertRegex(renderer, r"bsr\.w\s+Anim_ResolveTimedMappingFrame")
        self.assertRegex(renderer, r"bsr\.w\s+Sprite_RenderMapping")
        resolver = renderer.split("Anim_ResolveTimedMappingFrame:", 1)[1].split(
            "; End of function Anim_ResolveTimedMappingFrame", 1
        )[0]
        self.assertRegex(resolver, r"addq\.w\s+#4,a4")
        self.assertRegex(resolver, r"adda\.w\s+\(a4\),a4")
        self.assertRegex(resolver, r"move\.w\s+2\(a4\),d0")

    def test_fragment_frames_are_direct_stage15_table_entries(self) -> None:
        stage = (ROOT / "src/stages/stage_15_fragment_hazards.s").read_text(encoding="utf-8")
        table = stage.split("Projectile_FragmentSpriteFrames:", 1)[1].split(
            "Projectile_FragmentOrientationAttributes:", 1
        )[0]
        slots = re.findall(r"\bdc\.l\s+(Projectile_FragmentSpriteFrame\d\d)\b", table)
        self.assertEqual(
            [
                "Projectile_FragmentSpriteFrame01",
                "Projectile_FragmentSpriteFrame02",
                "Projectile_FragmentSpriteFrame00",
                "Projectile_FragmentSpriteFrame02",
                "Projectile_FragmentSpriteFrame01",
                "Projectile_FragmentSpriteFrame02",
                "Projectile_FragmentSpriteFrame00",
                "Projectile_FragmentSpriteFrame02",
            ],
            slots,
        )
        self.assertRegex(stage, r"move\.l\s+Projectile_FragmentSpriteFrames\(pc,d0\.w\),8\(a0\)")
        self.assertRegex(stage, r"move\.l\s+\(a1,d0\.w\),8\(a0\)")

    def test_reviewed_player_mapping_group_still_matches_its_consumer(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        player_review = next(
            review for review in reviews if review["basis"].startswith("Player_AnimationFrameTable selects")
        )
        source = (ROOT / "src/player/rendering_and_defeat.s").read_text(encoding="utf-8")
        consumer = source.split("Player_AdvanceAnimationFrame:", 1)[1].split(
            "; End of function Player_AdvanceAnimationFrame", 1
        )[0]
        self.assertRegex(consumer, r"andi\.w\s+#\$1C,d0")
        self.assertRegex(consumer, r"move\.l\s+Player_AnimationFrameTable\(pc,d0\.w\),8\(a5\)")
        table = source.split("Player_AnimationFrameTable:", 1)[1].split("\n\n", 1)[0]
        slots = re.findall(r"\bdc\.l\s+(Player_StateAnimationSpriteMapping\d\d)\b", table)
        self.assertEqual([member["current_name"] for member in player_review["members"]], slots)
        self.assertEqual(8, len(slots))

    def test_stage24_scene_animation_review_pins_all_five_later_frames(self) -> None:
        reviews = json.loads((ROOT / "config/duplicate_basis_reviews.json").read_text(encoding="utf-8"))["reviews"]
        review = next(item for item in reviews if item["basis"].startswith("The type-$410 Stage 24 object's"))
        mappings = (ROOT / "src/data/seven_forces_valkirie_and_stage24_mappings.s").read_text(encoding="utf-8")
        animation = mappings.split("Stage24SceneObject_SpriteAnimation:", 1)[1].split(
            "Stage24SceneObject_CompositeSpriteFrame:", 1
        )[0]
        slots = re.findall(
            r"dc\.w\s+(Stage24SceneObject_SpriteFrame\d\d)-\*\s*"
            r"(?:;[^\n]*\n\s*)?dc\.w\s+(\d+)",
            animation,
        )
        self.assertRegex(
            animation,
            r"(?s)^\s+dc\.w\s+Stage24SceneObject_SpriteFrame00-\*.*?"
            r"\n\s+dc\.w\s+9\b",
        )
        self.assertEqual(
            [
                (f"Stage24SceneObject_SpriteFrame{index:02d}", str(duration))
                for index, duration in enumerate((8, 8, 9, 8, 8), start=1)
            ],
            slots,
        )
        self.assertEqual(
            [name for name, _ in slots],
            [member["current_name"] for member in review["members"]],
        )
        self.assertIn("dc.w    Stage24SceneObject_SpriteAnimation-*", animation)
        stage = (ROOT / "src/stages/stage_24_scene_object.s").read_text(encoding="utf-8")
        transition = (ROOT / "src/stages/missiray_stage24_z_leo_transitions.s").read_text(encoding="utf-8")
        self.assertIn("move.w  #$410,(a0)", transition)
        self.assertIn("move.l  #Stage24SceneObject_SpriteAnimation,8(a5)", stage)
        dispatch_table = (
            (ROOT / "src/gameplay/object_dispatch_table.s")
            .read_text(encoding="utf-8")
            .split("; Fourth no-op entity update handler", 1)[0]
        )
        dispatch_slots = re.findall(r"\bdc\.l\s+([A-Za-z_]\w+)", dispatch_table)
        self.assertEqual("Stage24SceneObject_DispatchState", dispatch_slots[0x410 // 4])
        renderer = (ROOT / "src/rendering/sprite_object_pipeline.s").read_text(encoding="utf-8")
        self.assertIn("bsr.w   Anim_ResolveTimedMappingFrame", renderer)
        self.assertIn("adda.w  (a4),a4", renderer)

    def test_duplicate_bases_join_addresses_to_modules_once_per_record(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            (source / "first.s").write_text("First: ; was: sub_10\n", encoding="utf-8")
            (source / "second.s").write_text("Second:\n", encoding="utf-8")
            audit = root / "audit.json"
            audit.write_text(
                json.dumps(
                    {
                        "records": [
                            {
                                "address": "0x000010",
                                "current_name": "First",
                                "basis": ["shared explanation", "shared explanation", "solo"],
                            },
                            {
                                "address": "0x000020",
                                "current_name": "Second",
                                "basis": ["shared explanation"],
                            },
                        ]
                    }
                ),
                encoding="utf-8",
            )
            groups = semantic_audit_queue.duplicate_basis_groups(audit, source)

            self.assertEqual(["shared explanation"], [group.basis for group in groups])
            self.assertEqual(
                [
                    ("0x000010", "First", (source / "first.s").as_posix()),
                    ("0x000020", "Second", (source / "second.s").as_posix()),
                ],
                [(item.address, item.current_name, item.file) for item in groups[0].references],
            )

            reviews = root / "reviews.json"
            reviews.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "reviews": [
                            {
                                "basis": "shared explanation",
                                "reason": "Both entries occupy the same fixed-format table.",
                                "members": [
                                    {"address": "0x000010", "current_name": "First", "file": "src/first.s"},
                                    {"address": "0x000020", "current_name": "Second", "file": "src/second.s"},
                                ],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            unreviewed, errors = semantic_audit_queue.unreviewed_duplicate_bases(groups, reviews, root)
            self.assertEqual([], errors)
            self.assertEqual([], unreviewed)

            (source / "second.s").write_text("Renamed:\n", encoding="utf-8")
            audit_data = json.loads(audit.read_text(encoding="utf-8"))
            audit_data["records"][1]["current_name"] = "Renamed"
            audit.write_text(json.dumps(audit_data), encoding="utf-8")
            groups = semantic_audit_queue.duplicate_basis_groups(audit, source)
            _, errors = semantic_audit_queue.unreviewed_duplicate_bases(groups, reviews, root)
            self.assertTrue(any("reviewed members drifted" in error for error in errors))

    def test_queue_scans_modules_and_excludes_audited_current_names(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "src"
            source.mkdir()
            (source / "first.s").write_text(
                "Reviewed:\n                rts ; was: sub_10\nPending:\n                rts ; was: sub_12\n",
                encoding="utf-8",
            )
            (source / "second.inc").write_text(
                'Asset: binclude "asset.bin" ; was: byte_10\n'
                "                ; continued evidence comment\n"
                "Asset_End: ; was: byte_20\n",
                encoding="utf-8",
            )
            audit = root / "audit.json"
            audit.write_text(
                json.dumps({"records": [{"current_name": "Reviewed", "aliases": ["Asset_End"]}]}),
                encoding="utf-8",
            )

            provenance, pending = semantic_audit_queue.pending_records(source, audit)

            self.assertEqual(4, len(provenance))
            self.assertEqual(["Pending", "Asset"], [item.current_name for item in pending])
            self.assertFalse(pending[0].binary_backed_end)
            self.assertFalse(pending[1].binary_backed_end)
            self.assertEqual(
                ["first.s", "second.inc"],
                [Path(item.file).name for item in pending],
            )


if __name__ == "__main__":
    unittest.main()
