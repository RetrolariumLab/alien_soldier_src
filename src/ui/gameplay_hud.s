UI_UpdateGameplayHUD:                                   ; was: sub_12B6A
                                        ; XiTigerCutscene_Update+6   p
                clr.l   (PrimaryHUDDMABuffer).w
                clr.l   (WeaponDebugDMABuffer).w
                clr.l   (BossDebugDMABuffer).w
                bra.s   UI_UpdateGameplayHUD_UpdateStageTimer
; Dormant input entry skipped by UI_UpdateGameplayHUD and without a static caller
; It conditionally queues three sound requests, then may enter the debug menu
Debug_HandleDormantSoundAndMenuInput:                   ; was: sub_12B78
                tst.w   (DebugSoundRequestId).w
                beq.s   Debug_HandleDormantSoundAndMenuInput_CheckMenuToggle
                btst    #6,(ControllerPressedState+1).w
                beq.s   Debug_HandleDormantSoundAndMenuInput_CheckBit4
                move.b  (DebugSoundRequestId).w,d0
                jsr     (Sound_QueueRequest).l
                bra.s   Debug_HandleDormantSoundAndMenuInput_CheckMenuToggle
; ---------------------------------------------------------------------------
Debug_HandleDormantSoundAndMenuInput_CheckBit4:         ; was: loc_12B92
                btst    #4,(ControllerPressedState+1).w
                beq.s   Debug_HandleDormantSoundAndMenuInput_CheckBit5
                move.b  #1,d0
                jsr     (Sound_QueueRequest).l
                bra.s   Debug_HandleDormantSoundAndMenuInput_CheckMenuToggle
; ---------------------------------------------------------------------------
Debug_HandleDormantSoundAndMenuInput_CheckBit5:         ; was: loc_12BA6
                btst    #5,(ControllerPressedState+1).w
                beq.s   Debug_HandleDormantSoundAndMenuInput_CheckMenuToggle
                move.b  #4,d0
                jsr     (Sound_QueueRequest).l
Debug_HandleDormantSoundAndMenuInput_CheckMenuToggle:   ; was: loc_12BB8
                                        ; Debug_HandleDormantSoundAndMenuInput+26   j
                tst.w   (DebugMenuStateOffset).w
                bne.w   DebugMenu_UpdateAndDispatch
                tst.b   (GameplayControlFlags).w
                bpl.s   UI_UpdateGameplayHUD_UpdateStageTimer
                btst    #0,(GameplayControlFlags).w
                beq.s   UI_UpdateGameplayHUD_UpdateStageTimer
                btst    #6,(ControllerPressedState).w
                beq.s   UI_UpdateGameplayHUD_UpdateStageTimer
                addq.w  #2,(DebugMenuStateOffset).w
UI_UpdateGameplayHUD_UpdateStageTimer:                  ; was: loc_12BDA
                                        ; Debug_HandleDormantSoundAndMenuInput+5A   j
                tst.b   (GameplayControlFlags).w
                bmi.s   UI_UpdateGameplayHUD_UpdateBossHealthClamp
                btst    #0,(StageTimerPauseFlag).w
                bne.s   UI_UpdateGameplayHUD_UpdateBossHealthClamp
                tst.w   (StageTimeRemaining).w
                beq.s   UI_UpdateGameplayHUD_UpdateBossHealthClamp
                tst.w   (FrameFreezeTimer).w
                bpl.s   UI_UpdateGameplayHUD_UpdateBossHealthClamp
                subq.b  #1,(StageTimerFrameCounter).w
                bpl.s   UI_UpdateGameplayHUD_UpdateBossHealthClamp
                move.b  #$3B,(StageTimerFrameCounter).w  ; ';'
                moveq   #1,d0
                move.b  (StageTimeRemaining+1).w,d2
                sub.w   d4,d4
                sbcd    d0,d2
                cmpi.b  #$99,d2
                bne.s   UI_UpdateGameplayHUD_StoreStageTimerSeconds
                move.b  (StageTimeRemaining).w,d2
                sub.w   d4,d4
                sbcd    d0,d2
                cmpi.b  #$99,d2
                bne.s   UI_UpdateGameplayHUD_StoreStageTimerMinutes
                clr.w   (StageTimeRemaining).w
                bra.s   UI_UpdateGameplayHUD_UpdateBossHealthClamp
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_StoreStageTimerMinutes:            ; was: loc_12C24
                move.b  d2,(StageTimeRemaining).w
                move.b  #$59,d2                         ; 'Y'
UI_UpdateGameplayHUD_StoreStageTimerSeconds:            ; was: loc_12C2C
                move.b  d2,(StageTimeRemaining+1).w
UI_UpdateGameplayHUD_UpdateBossHealthClamp:             ; was: loc_12C30
                                        ; UI_UpdateGameplayHUD+7C   j
                bclr    #0,(BossCounterMaxFlag).w
                move.w  (BossCombatCounter).w,d0
                beq.s   UI_UpdateGameplayHUD_PrepareAlternatingSection
                bpl.s   UI_UpdateGameplayHUD_CheckBossHealthMaximum
                clr.w   (BossCombatCounter).w
                bra.s   UI_UpdateGameplayHUD_PrepareAlternatingSection
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_CheckBossHealthMaximum:            ; was: loc_12C44
                cmp.w   (BossCombatCounterMax).w,d0
                bmi.s   UI_UpdateGameplayHUD_PrepareAlternatingSection
                move.w  (BossCombatCounterMax).w,(BossCombatCounter).w
                bset    #0,(BossCounterMaxFlag).w
UI_UpdateGameplayHUD_PrepareAlternatingSection:         ; was: loc_12C56
                                        ; UI_UpdateGameplayHUD+D8   j
                bsr.w   UI_QueuePendingWeaponStateIconTransfer
                tst.b   (MessageDisplayFlags).w
                bpl.s   UI_UpdateGameplayHUD_SelectAlternatingSection
                rts
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_SelectAlternatingSection:          ; was: loc_12C62
                lea     (Math_PackedBCDLookup).l,a4
                btst    #0,(VBlankFrameCounter+1).w
                bne.w   UI_RenderStageTimerAndBossHealth
                bsr.w   UI_RenderWeaponStatusHUD
                tst.b   (GameplayControlFlags).w
                bpl.s   UI_UpdateGameplayHUD_RenderPlayerHealth
                btst    #0,(GameplayControlFlags).w
                beq.s   UI_UpdateGameplayHUD_RenderPlayerHealth
                btst    #4,(ControllerHeldState).w
                bne.s   UI_UpdateGameplayHUD_RenderPlayerHealth
                bra.w   UI_RenderScoreDisplay
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_RenderPlayerHealth:                ; was: loc_12C90
                                        ; UI_UpdateGameplayHUD+118   j
                movea.w #(PrimaryHUDTileBuffer-M68K_RAM),a0
                btst    #4,(ControlLayoutFlags).w
                beq.s   UI_UpdateGameplayHUD_UpdateDisplayedPlayerHealth
                move.w  #$C7E2,d0
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                move.w  d0,(a0)+
                bra.w   UI_UpdateGameplayHUD_PadPrimaryStatusRow
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_UpdateDisplayedPlayerHealth:       ; was: loc_12CAE
                subq.w  #1,(HealthDeltaDisplayTimer).w
                bpl.s   UI_UpdateGameplayHUD_ApproachCurrentPlayerHealth
                move.w  #$FFFF,(HealthDeltaDisplayTimer).w
UI_UpdateGameplayHUD_ApproachCurrentPlayerHealth:       ; was: loc_12CBA
                move.w  (DisplayedPlayerHealth).w,d0
                move.w  d0,d1
                sub.w   (PlayerHealth).w,d0
                bpl.s   UI_UpdateGameplayHUD_ApproachLowerPlayerHealth
                cmpi.w  #$FFF0,d0
                bpl.s   UI_UpdateGameplayHUD_SnapDisplayedPlayerHealth
                addi.w  #$10,(DisplayedPlayerHealth).w
                bra.s   UI_UpdateGameplayHUD_SelectPlayerHealthPresentation
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_ApproachLowerPlayerHealth:         ; was: loc_12CD4
                cmpi.w  #8,d0
                bpl.s   UI_UpdateGameplayHUD_DecreaseDisplayedPlayerHealth
UI_UpdateGameplayHUD_SnapDisplayedPlayerHealth:         ; was: loc_12CDA
                move.w  (PlayerHealth).w,(DisplayedPlayerHealth).w
                bra.s   UI_UpdateGameplayHUD_SelectPlayerHealthPresentation
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_DecreaseDisplayedPlayerHealth:     ; was: loc_12CE2
                subi.w  #8,(DisplayedPlayerHealth).w
UI_UpdateGameplayHUD_SelectPlayerHealthPresentation:    ; was: loc_12CE8
                                        ; UI_UpdateGameplayHUD+176   j
                moveq   #$13,d7
                cmpi.w  #2,(PlayerHealth).w
                bpl.s   UI_UpdateGameplayHUD_CheckPlayerHealthFlash
                move.w  (VBlankFrameCounter).w,d1
                btst    #4,d1
                bne.s   UI_UpdateGameplayHUD_CheckPlayerHealthFlash
                andi.w  #3,d1
                bne.s   UI_UpdateGameplayHUD_CheckPlayerHealthFlash
                move.w  #$C7D1,d0
UI_UpdateGameplayHUD_FillCriticalHealthRow:             ; was: loc_12D06
                move.w  d0,(a0)+
                dbf     d7,UI_UpdateGameplayHUD_FillCriticalHealthRow
                bra.w   UI_UpdateGameplayHUD_QueuePrimaryStatusTransfer
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_CheckPlayerHealthFlash:            ; was: loc_12D10
                                        ; UI_UpdateGameplayHUD+190   j
                tst.w   (PhoenixAttackStatus).w
                bne.s   UI_UpdateGameplayHUD_RenderPlayerHealthBar
                btst    #1,(VBlankFrameCounter+1).w
                bne.s   UI_UpdateGameplayHUD_RenderPlayerHealthBar
                move.w  #$C551,d0
UI_UpdateGameplayHUD_FillFlashingHealthRow:             ; was: loc_12D22
                move.w  d0,(a0)+
                dbf     d7,UI_UpdateGameplayHUD_FillFlashingHealthRow
                bra.w   UI_UpdateGameplayHUD_QueuePrimaryStatusTransfer
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_RenderPlayerHealthBar:             ; was: loc_12D2C
                                        ; UI_UpdateGameplayHUD+1B2   j
                btst    #0,(ControlLayoutFlags).w
                beq.s   UI_UpdateGameplayHUD_RenderSegmentedPlayerHealthBar
                move.w  #$C7B4,d5
                move.w  (DisplayedPlayerHealth).w,d0
                asl.w   #1,d0
                andi.w  #$FFFE,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                move.w  #$C7E0,(a0)+
                move.w  (PlayerMaxHealth).w,d0
                asl.w   #1,d0
                andi.w  #$FFFE,d0
                move.w  (a4,d0.w),(HUDGlyphWordScratch).w
                movea.w #(HUDGlyphWordScratch-M68K_RAM),a1
                moveq   #1,d7
                bsr.w   UI_RenderPackedBCDDigits
                move.w  #$C7F8,(a0)+
                bra.s   UI_UpdateGameplayHUD_RenderHealthChange
; ---------------------------------------------------------------------------
UI_UpdateGameplayHUD_RenderSegmentedPlayerHealthBar:    ; was: loc_12D76
                move.w  (PlayerMaxHealth).w,d7
                asr.w   #6,d7
                move.w  (DisplayedPlayerHealth).w,d0
                subq.w  #1,d0
                bmi.s   UI_UpdateGameplayHUD_FillRemainingHealthSegments
                move.w  d0,d1
                asr.w   #6,d0
                sub.w   d0,d7
                asr.w   #3,d1
                andi.w  #7,d1
                addi.w  #-$383C,d1
                subq.w  #1,d0
                bmi.s   UI_UpdateGameplayHUD_WritePartialHealthSegment
                move.w  #$C7CB,d2
UI_UpdateGameplayHUD_FillFullHealthSegments:            ; was: loc_12D9C
                move.w  d2,(a0)+
                dbf     d0,UI_UpdateGameplayHUD_FillFullHealthSegments
UI_UpdateGameplayHUD_WritePartialHealthSegment:         ; was: loc_12DA2
                move.w  d1,(a0)+
                subq.w  #1,d7
UI_UpdateGameplayHUD_FillRemainingHealthSegments:       ; was: loc_12DA6
                subq.w  #1,d7
                bmi.s   UI_UpdateGameplayHUD_RenderHealthChange
                move.w  #$C7C3,d0
UI_UpdateGameplayHUD_FillEmptyHealthSegments:           ; was: loc_12DAE
                move.w  d0,(a0)+
                dbf     d7,UI_UpdateGameplayHUD_FillEmptyHealthSegments
UI_UpdateGameplayHUD_RenderHealthChange:                ; was: loc_12DB4
                                        ; UI_UpdateGameplayHUD+23E   j
                tst.w   (HealthDeltaDisplayTimer).w
                bmi.s   UI_UpdateGameplayHUD_PadPrimaryStatusRow
                move.w  (HealthDeltaDisplayTimer).w,d0
                cmpi.w  #$12,d0
                bmi.s   UI_UpdateGameplayHUD_WriteHealthChange
                btst    #2,(VBlankFrameCounter+1).w
                bne.s   UI_UpdateGameplayHUD_PadPrimaryStatusRow
UI_UpdateGameplayHUD_WriteHealthChange:                 ; was: loc_12DCC
                move.w  #$C7BF,d2
                move.w  (HealthDeltaDisplayValue).w,d0
                bclr    #$F,d0
                bne.s   UI_UpdateGameplayHUD_WriteHealthChangeSign
                move.w  #$C7E1,d2
UI_UpdateGameplayHUD_WriteHealthChangeSign:             ; was: loc_12DDE
                move.w  d2,(a0)+
                move.w  #$C7B4,d2
                asl.w   #1,d0
                move.b  (a4,d0.w),d1
                andi.w  #$F,d1
                beq.s   UI_UpdateGameplayHUD_CheckHealthChangeTens
                add.w   d2,d1
                move.w  d1,(a0)+
UI_UpdateGameplayHUD_CheckHealthChangeTens:             ; was: loc_12DF4
                move.w  (a4,d0.w),d3
                lsr.w   #4,d3
                andi.w  #$F,d3
                tst.w   d1
                bne.s   UI_UpdateGameplayHUD_WriteHealthChangeTens
                tst.w   d3
                beq.s   UI_UpdateGameplayHUD_WriteHealthChangeOnes
UI_UpdateGameplayHUD_WriteHealthChangeTens:             ; was: loc_12E06
                add.w   d2,d3
                move.w  d3,(a0)+
UI_UpdateGameplayHUD_WriteHealthChangeOnes:             ; was: loc_12E0A
                move.w  (a4,d0.w),d1
                andi.w  #$F,d1
                add.w   d2,d1
                move.w  d1,(a0)+
UI_UpdateGameplayHUD_PadPrimaryStatusRow:               ; was: loc_12E16
                                        ; UI_UpdateGameplayHUD+24E   j
                move.w  #$84D8,d7
                sub.w   a0,d7
                lsr.w   #1,d7
                subq.w  #1,d7
                bmi.s   UI_UpdateGameplayHUD_QueuePrimaryStatusTransfer
                move.w  #$C7F8,d0
UI_UpdateGameplayHUD_FillPrimaryStatusRowPadding:       ; was: loc_12E26
                move.w  d0,(a0)+
                dbf     d7,UI_UpdateGameplayHUD_FillPrimaryStatusRowPadding
UI_UpdateGameplayHUD_QueuePrimaryStatusTransfer:        ; was: loc_12E2C
                                        ; UI_UpdateGameplayHUD+1BE   j
                movea.w #(PrimaryHUDTileBuffer-M68K_RAM),a5
                move.w  #$83,-(a5)
                move.w  #$508C,-(a5)
                move.w  #$9558,-(a5)
                move.w  #$96C2,-(a5)
                move.w  #$977F,-(a5)
                move.w  #$8F02,-(a5)
                move.l  #$94009314,-(a5)
                rts
; End of function UI_UpdateGameplayHUD
