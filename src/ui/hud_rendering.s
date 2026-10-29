UI_RenderWeaponStatusHUD:                               ; was: sub_12E50
                movea.w #(WeaponDebugTileBuffer-M68K_RAM),a0
                movea.w a0,a3
                move.w  (WeaponSlotOffset).w,d0
                addi.w  #-$5DA0,d0
                movea.w d0,a2
                btst    #5,(ControlLayoutFlags).w
                beq.s   UI_RenderWeaponStatusHUD_SelectLayout
                move.w  #$C7E2,d0
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                bra.w   UI_RenderWeaponStatusHUD_PadRow
; ---------------------------------------------------------------------------
UI_RenderWeaponStatusHUD_SelectLayout:                  ; was: loc_12E7A
                btst    #1,(ControlLayoutFlags).w
                beq.s   UI_RenderWeaponStatusHUD_RenderSegmentedEnergy
                move.w  #$C7B4,d5
                move.w  (a2),d0
                asl.w   #1,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                move.w  #$C7E0,(a0)+
                move.w  8(a2),d0
                asl.w   #1,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                bra.s   UI_RenderWeaponStatusHUD_UpdateCombatPercentTimer
; ---------------------------------------------------------------------------
UI_RenderWeaponStatusHUD_RenderSegmentedEnergy:         ; was: loc_12EB6
                move.w  #$FA,d1
                move.w  8(a2),d0
                lea     WeaponEnergyMaximumSegmentTiles(pc),a1
                nop
UI_RenderWeaponStatusHUD_FillMaximumEnergySegments:     ; was: loc_12EC4
                sub.w   d1,d0
                bmi.s   UI_RenderWeaponStatusHUD_RenderCurrentEnergy
                move.w  (a1)+,(a0)+
                bra.s   UI_RenderWeaponStatusHUD_FillMaximumEnergySegments
; ---------------------------------------------------------------------------
UI_RenderWeaponStatusHUD_RenderCurrentEnergy:           ; was: loc_12ECC
                move.w  (a2),d0
                beq.s   UI_RenderWeaponStatusHUD_UpdateCombatPercentTimer
                addi.w  #$7C,d0                         ; '|'
                lea     WeaponEnergySegmentTiles(pc),a1
                nop
UI_RenderWeaponStatusHUD_FillCurrentEnergySegments:     ; was: loc_12EDA
                sub.w   d1,d0
                bmi.s   UI_RenderWeaponStatusHUD_WritePartialEnergySegment
                move.w  (a1)+,(a3)+
                bra.s   UI_RenderWeaponStatusHUD_FillCurrentEnergySegments
; ---------------------------------------------------------------------------
UI_RenderWeaponStatusHUD_WritePartialEnergySegment:     ; was: loc_12EE2
                cmpi.w  #$FF83,d0
                bmi.s   UI_RenderWeaponStatusHUD_UpdateCombatPercentTimer
                move.w  (a1)+,d1
                addq.w  #1,d1
                move.w  d1,(a3)+
UI_RenderWeaponStatusHUD_UpdateCombatPercentTimer:      ; was: loc_12EEE
                                        ; UI_RenderWeaponStatusHUD+7E   j
                subq.w  #1,(CombatPercentTimer).w
                bpl.s   UI_RenderWeaponStatusHUD_WriteCombatPercent
                move.w  #$FFFF,(CombatPercentTimer).w
                bra.s   UI_RenderWeaponStatusHUD_PadRow
; ---------------------------------------------------------------------------
UI_RenderWeaponStatusHUD_WriteCombatPercent:            ; was: loc_12EFC
                move.w  (CombatPercentIndex).w,d0
                move.w  #$C7BF,(a0)+
                asr.w   #1,d0
                lea     CombatPercentDisplayTable(pc),a3
                nop
                move.b  (a3,d0.w),d0
                move.w  d0,d2
                lsr.w   #4,d0
                andi.w  #$F,d0
                addi.w  #-$384C,d0
                move.w  d0,(a0)+
                andi.w  #$F,d2
                addi.w  #-$384C,d2
                move.w  d2,(a0)+
                move.w  #$C7C0,(a0)+
UI_RenderWeaponStatusHUD_PadRow:                        ; was: loc_12F2C
                                        ; UI_RenderWeaponStatusHUD+AA   j
                move.w  #$8538,d7
                sub.w   a0,d7
                lsr.w   #1,d7
                subq.w  #1,d7
                bmi.s   UI_QueueWeaponStatusTransfer
                move.w  #$C7F8,d0
UI_RenderWeaponStatusHUD_FillRowPadding:                ; was: loc_12F3C
                move.w  d0,(a0)+
                dbf     d7,UI_RenderWeaponStatusHUD_FillRowPadding
UI_QueueWeaponStatusTransfer:                           ; was: loc_12F42
                movea.w #(WeaponDebugTileBuffer-M68K_RAM),a5
                move.w  #$83,-(a5)
                move.w  #$510C,-(a5)
                move.w  #$9588,-(a5)
                move.w  #$96C2,-(a5)
                move.w  #$977F,-(a5)
                move.w  #$8F02,-(a5)
                move.l  #$94009314,-(a5)
                rts
; End of function UI_RenderWeaponStatusHUD
; ---------------------------------------------------------------------------
WeaponEnergySegmentTiles:   dc.w    $C7D4, $C7D4, $C7D4, $C7D4, $C7D6, $C7D6, $C7D6, $C7D6  ; was: word_12F66
                dc.w    $C7D6, $C7D6, $C7D6, $C7D6, $C7D6, $C7D6, $C7D6, $C7D6
WeaponEnergyMaximumSegmentTiles:    dc.w    $C7C2, $C7C2, $C7C2, $C7C2, $C7C2, $C7C2, $C7C2, $C7C2  ; was: word_12F86
                dc.w    $C7C2, $C7C2, $C7C2, $C7C2, $C7C2, $C7C2, $C7C2, $C7C2
CombatPercentDisplayTable:  dc.w    5, $1015, $2025, $3035, $4045, $5055, $6065, $7075, $8085, $9095, $9900  ; was: word_12FA6

UI_RenderStageTimerAndBossHealth:                       ; was: sub_12FBC
                movea.w #(StageTimerTileBuffer-M68K_RAM),a0
                bra.s   UI_RenderStageTimerAndBossHealth_CheckTimerAlert
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_BlankTimer:            ; was: loc_12FC2
                move.w  #$C7F8,d0
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                bra.s   UI_RenderStageTimerAndBossHealth_RenderBossHealth
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_CheckTimerAlert:       ; was: loc_12FD2
                tst.b   (StageTimeRemaining).w
                bne.s   UI_RenderStageTimerAndBossHealth_WriteTimer
                cmpi.b  #$30,(StageTimeRemaining+1).w   ; '0'
                bpl.s   UI_RenderStageTimerAndBossHealth_WriteTimer
                btst    #0,(StageTimerPauseFlag).w
                bne.s   UI_RenderStageTimerAndBossHealth_WriteTimer
                subq.w  #1,(LowTimeWarningTimer).w
                bpl.s   UI_RenderStageTimerAndBossHealth_WriteTimer
                move.w  #$26,(LowTimeWarningTimer).w    ; '&'
                move.b  #$40,d0                         ; '@'
                jsr     (Sound_QueueSFXRequest).l
                bra.s   UI_RenderStageTimerAndBossHealth_BlankTimer
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_WriteTimer:            ; was: loc_13000
                                        ; UI_RenderStageTimerAndBossHealth+22   j
                move.w  #$C7F8,(a0)+
                move.b  (StageTimeRemaining).w,d0
                andi.w  #$F,d0
                addi.w  #-$384C,d0
                move.w  d0,(a0)+
                move.w  #$C7C1,(a0)+
                move.b  (StageTimeRemaining+1).w,d0
                move.b  d0,d1
                lsr.b   #4,d0
                andi.w  #$F,d0
                addi.w  #-$384C,d0
                move.w  d0,(a0)+
                andi.w  #$F,d1
                addi.w  #-$384C,d1
                move.w  d1,(a0)+
UI_RenderStageTimerAndBossHealth_RenderBossHealth:      ; was: loc_13032
                movea.w #(BossDebugTileBuffer-M68K_RAM),a0
                btst    #3,(ControlLayoutFlags).w
                beq.s   UI_RenderStageTimerAndBossHealth_UpdateDisplayedBossHealth
                move.w  #$C7E2,d0
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  #$C7F8,d0
                moveq   #$16,d7
                bra.w   UI_RenderStageTimerAndBossHealth_FillBossHealthPadding
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_UpdateDisplayedBossHealth:  ; was: loc_13056
                tst.b   (GameplayControlFlags).w
                bmi.s   UI_RenderStageTimerAndBossHealth_SelectBossHealthPresentation
                move.w  (DisplayedBossHealth).w,d0
                sub.w   (BossHealth).w,d0
                bpl.s   UI_RenderStageTimerAndBossHealth_ApproachLowerBossHealth
                cmpi.w  #$FF00,d0
                bpl.s   UI_RenderStageTimerAndBossHealth_SnapDisplayedBossHealth
                addi.w  #$100,(DisplayedBossHealth).w
                bra.s   UI_RenderStageTimerAndBossHealth_SelectBossHealthPresentation
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_ApproachLowerBossHealth:  ; was: loc_13074
                cmpi.w  #$100,d0
                bpl.s   UI_RenderStageTimerAndBossHealth_DecreaseDisplayedBossHealth
UI_RenderStageTimerAndBossHealth_SnapDisplayedBossHealth:  ; was: loc_1307A
                move.w  (BossHealth).w,(DisplayedBossHealth).w
                bra.s   UI_RenderStageTimerAndBossHealth_SelectBossHealthPresentation
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_DecreaseDisplayedBossHealth:  ; was: loc_13082
                subi.w  #$100,(DisplayedBossHealth).w
UI_RenderStageTimerAndBossHealth_SelectBossHealthPresentation:  ; was: loc_13088
                                        ; UI_RenderStageTimerAndBossHealth+B6   j
                tst.w   (SpecialTargetCount).w
                bne.w   UI_RenderSpecialBossStatus
                btst    #2,(ControlLayoutFlags).w
                beq.s   UI_RenderStageTimerAndBossHealth_RenderSegmentedBossHealth
                move.w  #$C7B4,d5
                move.w  (DisplayedBossHealth).w,d0
                asr.w   #2,d0
                andi.w  #$FFFE,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                move.w  #$C7E0,(a0)+
                move.w  (BossMaxHealth).w,d0
                asr.w   #2,d0
                andi.w  #$FFFE,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                moveq   #$12,d7
                move.w  #$C7F8,d0
UI_RenderStageTimerAndBossHealth_FillAlternatePadding:  ; was: loc_130DA
                move.w  d0,(a0)+
                dbf     d7,UI_RenderStageTimerAndBossHealth_FillAlternatePadding
                bra.s   UI_RenderStageTimerAndBossHealth_QueueBossHealthTransfer
; ---------------------------------------------------------------------------
UI_RenderStageTimerAndBossHealth_RenderSegmentedBossHealth:  ; was: loc_130E2
                moveq   #$1C,d7
                move.w  (DisplayedBossHealth).w,d0
                subq.w  #1,d0
                bmi.s   UI_RenderStageTimerAndBossHealth_FillRemainingBossHealthSegments
                move.w  d0,d1
                asr.w   #8,d0
                asr.w   #2,d0
                sub.w   d0,d7
                asr.w   #7,d1
                andi.w  #7,d1
                addi.w  #-$381C,d1
                subq.w  #1,d0
                bmi.s   UI_RenderStageTimerAndBossHealth_WritePartialBossHealthSegment
                move.w  #$C7EB,d2
UI_RenderStageTimerAndBossHealth_FillFullBossHealthSegments:  ; was: loc_13106
                move.w  d2,(a0)+
                dbf     d0,UI_RenderStageTimerAndBossHealth_FillFullBossHealthSegments
UI_RenderStageTimerAndBossHealth_WritePartialBossHealthSegment:  ; was: loc_1310C
                move.w  d1,(a0)+
                subq.w  #1,d7
UI_RenderStageTimerAndBossHealth_FillRemainingBossHealthSegments:  ; was: loc_13110
                subq.w  #1,d7
                bmi.s   UI_RenderStageTimerAndBossHealth_QueueBossHealthTransfer
                move.w  #$C7C3,d0
UI_RenderStageTimerAndBossHealth_FillBossHealthPadding:  ; was: loc_13118
                                        ; UI_RenderStageTimerAndBossHealth+15E   j
                move.w  d0,(a0)+
                dbf     d7,UI_RenderStageTimerAndBossHealth_FillBossHealthPadding
UI_RenderStageTimerAndBossHealth_QueueBossHealthTransfer:  ; was: loc_1311E
                                        ; UI_RenderStageTimerAndBossHealth+156   j
                movea.w #(BossDebugTileBuffer-M68K_RAM),a5
                move.w  #$83,-(a5)
                move.w  #$518C,-(a5)
                move.w  #$95B8,-(a5)
                move.w  #$96C2,-(a5)
                move.w  #$977F,-(a5)
                move.w  #$8F02,-(a5)
                move.l  #$94009321,-(a5)
                rts
; End of function UI_RenderStageTimerAndBossHealth
UI_RenderSpecialBossStatus:                             ; was: sub_13142
                moveq   #$1A,d7
                btst    #1,(VBlankFrameCounter+1).w
                bne.s   UI_RenderSpecialBossStatus_PreparePadding
                move.w  #$C7F8,(a0)+
                move.w  #$C7B4,d5
                move.w  (SpecialTargetCount).w,d0
                asl.w   #1,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                moveq   #$16,d7
UI_RenderSpecialBossStatus_PreparePadding:              ; was: loc_1316C
                move.w  #$C7F8,d0
UI_RenderSpecialBossStatus_FillPadding:                 ; was: loc_13170
                move.w  d0,(a0)+
                dbf     d7,UI_RenderSpecialBossStatus_FillPadding
                bra.s   UI_RenderStageTimerAndBossHealth_QueueBossHealthTransfer
; End of function UI_RenderSpecialBossStatus
UI_QueueAllWeaponIconTransfers:                         ; was: sub_13178
                                        ; Stage_InitializeXiTigerState+34   p
                move.w  (WeaponSlotOffset).w,(HUDGlyphWordScratch).w
                clr.w   (WeaponSlotOffset).w
                moveq   #3,d7
UI_QueueAllWeaponIconTransfers_NextSlot:                ; was: loc_13184
                bsr.s   UI_QueueSelectedWeaponIconTransfer
                addq.w  #2,(WeaponSlotOffset).w
                dbf     d7,UI_QueueAllWeaponIconTransfers_NextSlot
                move.w  (HUDGlyphWordScratch).w,(WeaponSlotOffset).w
                rts
; End of function UI_QueueAllWeaponIconTransfers
; ---------------------------------------------------------------------------
WeaponIconVRAMDestinationTable: dc.w    $50B8, $50BE, $50C4, $50CA  ; was: word_13196

UI_QueueSelectedWeaponIconTransfer:                     ; was: sub_1319E
                                        ; WeaponSetup_InitializeScreen+EC   p
                move.w  (WeaponSlotOffset).w,d0
                move.w  WeaponIconVRAMDestinationTable(pc,d0.w),d3
                movea.w d0,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  (a0),d0
; Fall through to UI_QueueWeaponIconTileTransfer
UI_QueueWeaponIconTileTransfer:                         ; was: sub_131AE
                asl.w   #1,d0
                addi.w  #-$3A7C,d0
                movea.w (VDPStagingDataCursor).w,a1
                move.w  d0,(a1)+
                addq.w  #1,d0
                move.w  d0,(a1)+
                addq.w  #1,d0
                move.w  d0,(a1)+
                addq.w  #1,d0
                move.w  d0,(a1)+
                movea.w (VDPCommandQueueHead).w,a1
                bsr.s   UI_QueueWeaponIconDMAHalf
                addq.w  #2,d3
                bsr.s   UI_QueueWeaponIconDMAHalf
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function UI_QueueWeaponIconTileTransfer
UI_QueueWeaponIconDMAHalf:                              ; was: sub_131D6
                                        ; UI_QueueWeaponIconTileTransfer+20   p
                move.w  #$83,-(a1)
                move.w  d3,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F80977F,-(a1)
                move.l  #$94009302,-(a1)
                addq.w  #4,(VDPStagingDataCursor).w
                rts
; End of function UI_QueueWeaponIconDMAHalf
; Dormant alternate entry: no reconstructed static caller reaches it
UnreferencedRenderIndexedLookupDigits:
                asl.w   #1,d0                           ; was: sub_13206
                move.w  (a4,d0.w),(a1)
; Fall through to UI_RenderPackedBCDDigits
UI_RenderPackedBCDDigits:                               ; was: sub_1320C
                                        ; UI_UpdateGameplayHUD+202   p
                moveq   #0,d1
UI_RenderPackedBCDDigits_NextByte:                      ; was: loc_1320E
                move.b  (a1),d0
                lsr.b   #4,d0
                andi.w  #$F,d0
                bne.s   UI_RenderPackedBCDDigits_WriteHighNibble
                tst.w   d1
                bne.s   UI_RenderPackedBCDDigits_WriteHighNibble
                move.w  #$C7BE,d0
                bra.s   UI_RenderPackedBCDDigits_ReadLowNibble
; ---------------------------------------------------------------------------
UI_RenderPackedBCDDigits_WriteHighNibble:               ; was: loc_13222
                                        ; UI_RenderPackedBCDDigits+E   j
                addq.w  #1,d1
                add.w   d5,d0
UI_RenderPackedBCDDigits_ReadLowNibble:                 ; was: loc_13226
                move.w  d0,(a0)+
                move.b  (a1)+,d0
                andi.w  #$F,d0
                bne.s   UI_RenderPackedBCDDigits_WriteLowNibble
                tst.w   d1
                bne.s   UI_RenderPackedBCDDigits_WriteLowNibble
                move.w  #$C7BE,d0
                bra.s   UI_RenderPackedBCDDigits_Advance
; ---------------------------------------------------------------------------
UI_RenderPackedBCDDigits_WriteLowNibble:                ; was: loc_1323A
                                        ; UI_RenderPackedBCDDigits+26   j
                addq.w  #1,d1
                add.w   d5,d0
UI_RenderPackedBCDDigits_Advance:                       ; was: loc_1323E
                move.w  d0,(a0)+
                dbf     d7,UI_RenderPackedBCDDigits_NextByte
                rts
; End of function UI_RenderPackedBCDDigits
UI_RenderScoreDisplay:                                  ; was: sub_13246
                movea.w #(PrimaryHUDTileBuffer-M68K_RAM),a0
                move.w  #$C7F4,(a0)+
                move.w  #$C7F5,(a0)+
                move.w  #$C7F6,(a0)+
                move.w  #$C7F7,(a0)+
                move.w  #$C7BF,(a0)+
                move.w  #$C7B4,d5
                movea.w #(ScoreValueBCD-M68K_RAM),a1
                moveq   #3,d7
                bsr.w   UI_RenderPackedBCDDigits
                move.w  #$C7D2,(a0)+
                move.w  #$C7D3,(a0)+
                bra.w   UI_UpdateGameplayHUD_PadPrimaryStatusRow
; End of function UI_RenderScoreDisplay
; Applies friction to velocity reducing speed
