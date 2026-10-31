; Renders the shared score-summary panel
Results_RenderSummaryPanel:                             ; was: sub_1DC4C
                bsr.w   Results_RenderScoreSummary
                rts
; End of function Results_RenderSummaryPanel

; Activates the post-stage summary and installs its completion graphics
Results_ActivatePostStageSummary:                       ; was: sub_1DC52
                move.w  #$50,(SecondaryCameraYPos).w    ; 'P'
                addq.w  #1,(FrameCounter).w
                bsr.w   Results_RenderHighScore
                bsr.w   Results_RenderScore
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   Results_ActivatePostStageSummary_Return
                addq.w  #2,(GameSubstateIndex).w
                jsr     (Results_IncrementStageVisitCount).l
                lea     ResultsPostStageCompletionAssetLoadList(pc),a0
                nop
                jsr     (LoadObjData).l
                movea.l #SharedTilemapWorkspace,a0
                move.w  #$4000,d0
                moveq   #$F,d7
                jsr     (Gfx_AdjustTileIndexRows).l
                movea.l #ResultsPostStageCompletionTilemapRows,a0
                jsr     (Tilemap_QueueIndexedRows).l
                clr.w   (SecondaryCameraXPos).w
Results_ActivatePostStageSummary_Return:                ; was: locret_1DCB0
                rts
; End of function Results_ActivatePostStageSummary
; ---------------------------------------------------------------------------
ResultsPostStageCompletionAssetLoadList:    dc.w    7   ; was: stru_1DCB2
                dc.l    ResultsPostStageCompletionTileArt2000  ; field_2
                dc.w    $2000                           ; field_6
                dc.w    6                               ; command: LZSS to RAM
                dc.l    ResultsPostStageCompletionMappingData2020  ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
ResultsPostStageCompletionTilemapRows:  dc.b    $69, 0, $20, 0, $F, 0, 1, 2, 3, 4  ; was: byte_1DCC4
                dc.b    5, 6, 7, 8, 9, $A, $B, $C, $D, $E
                dc.b    $F, $10

; Waits for post-stage confirmation and starts the exit fade
Results_WaitForPostStageConfirmation:                   ; was: sub_1DCDA
                addq.w  #1,(FrameCounter).w
                jsr     (Results_UpdateHistoryDisplayAndHandleExtendedExit).l
                bsr.w   Results_RenderHighScore
                bsr.w   Results_RenderScore
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                jsr     (Gfx_FadePaletteTransition).l
                btst    #7,(ControllerPressedState).w
                beq.s   Results_WaitForPostStageConfirmation_Return
                addq.w  #2,(GameSubstateIndex).w
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
Results_WaitForPostStageConfirmation_Return:            ; was: locret_1DD14
                rts
; End of function Results_WaitForPostStageConfirmation

; Fades the post-stage summary out before the continue decision
Results_FadeOutToContinue:                              ; was: sub_1DD16
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   Results_FadeOutToContinue_Return
                addq.w  #2,(GameSubstateIndex).w
                clr.b   (VDPReg18Shadow+1).w
Results_FadeOutToContinue_Return:                       ; was: locret_1DD2C
                rts
; End of function Results_FadeOutToContinue

; Initializes the final score summary shown after the credits
Results_InitializeFinalSummary:                         ; was: sub_1DD2E
                tst.w   (GameSubstateIndex).w
                bne.s   Results_InitializeFinalSummary_Activate
                addq.w  #2,(GameSubstateIndex).w
                jsr     (Sys_InitGameMode).l
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                lea     ResultsFinalSummaryDataLoadRequest(pc),a0
                nop
                jsr     (Data_ProcessPointer).l
                clr.w   (PrimaryHUDDMABuffer).w
                clr.w   (WeaponDebugDMABuffer).w
                clr.w   (BossDebugDMABuffer).w
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
Results_InitializeFinalSummary_Return:                  ; was: locret_1DD88
                rts
; ---------------------------------------------------------------------------
Results_InitializeFinalSummary_Activate:                ; was: loc_1DD8A
                tst.w   (DataLoaderControl).w
                bmi.s   Results_InitializeFinalSummary_Return
                addq.w  #4,(GameModeIndex).w
                move.w  #2,(GameSubstateIndex).w
                lea     (ResultsScreenPaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                bsr.w   Results_RenderScoreSummary
                move.b  #$12,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                jmp     (Gfx_FadePaletteTransition).l
; End of function Results_InitializeFinalSummary
; ---------------------------------------------------------------------------
ResultsFinalSummaryDataLoadRequest: dc.w    7           ; was: stru_1DDC2
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $D000                           ; field_6
                dc.w    $FFFF

; Updates the high score and renders every score-summary field and label
Results_RenderScoreSummary:                             ; was: sub_1DDCC
                move.l  (ScoreValueBCD).w,d0
                cmp.l   (HighScoreBCD).w,d0
                bmi.s   Results_RenderScoreSummary_Fields
                move.l  d0,(HighScoreBCD).w
                move.w  #$FFFF,(StageTimeRemaining).w
Results_RenderScoreSummary_Fields:                      ; was: loc_1DDE0
                bsr.w   Results_RenderHighScore
                bsr.w   Results_RenderScore
                bsr.w   Results_RenderDestroyedEnemyCount
                bsr.w   Results_RenderPlayerDamage
                lea     (Text_Results).l,a0
                move.w  #$E300,d0
                move.w  #$5120,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_HighScore).l,a0
                move.w  #$8300,d0
                move.w  #$528A,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_EightDigitPointsPlaceholder).l,a0
                move.w  #$A300,d0
                move.w  #$52AA,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_Score).l,a0
                move.w  #$8300,d0
                move.w  #$538A,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_EightDigitPointsPlaceholder).l,a0
                move.w  #$A300,d0
                move.w  #$53AA,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_DestroyedEnemies).l,a0
                move.w  #$8300,d0
                move.w  #$558A,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_FourDigitPlaceholder).l,a0
                move.w  #$A300,d0
                move.w  #$55B8,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_PlayerDamage).l,a0
                move.w  #$8300,d0
                move.w  #$568A,d4
                jsr     (Text_QueueDoubleHeightString).l
                lea     (Text_FourDigitPlaceholder).l,a0
                move.w  #$A300,d0
                move.w  #$56B8,d4
                jmp     (Text_QueueDoubleHeightString).l
; End of function Results_RenderScoreSummary

; Renders the eight-digit packed-BCD high score
Results_RenderHighScore:                                ; was: sub_1DEA4
                move.l  (HighScoreBCD).w,d0
                move.w  #$C302,d1
                move.w  #$52AA,d4
                moveq   #8,d7
                cmpi.w  #$FFFF,(StageTimeRemaining).w
                bne.s   Results_RenderHighScore_QueueDigits
                btst    #1,(FrameCounter+1).w
                bne.s   Results_RenderHighScore_QueueDigits
                move.w  #$8302,d1
Results_RenderHighScore_QueueDigits:                    ; was: loc_1DEC6
                jmp     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Results_RenderHighScore

; Renders the eight-digit packed-BCD current score
Results_RenderScore:                                    ; was: sub_1DECC
                move.l  (ScoreValueBCD).w,d0
                move.w  #$C302,d1
                move.w  #$53AA,d4
                moveq   #8,d7
                cmpi.w  #$FFFF,(StageTimeRemaining).w
                bne.s   Results_RenderScore_QueueDigits
                btst    #1,(FrameCounter+1).w
                bne.s   Results_RenderScore_QueueDigits
                move.w  #$8302,d1
                move.l  (HighScoreBCD).w,d0
Results_RenderScore_QueueDigits:                        ; was: loc_1DEF2
                jmp     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Results_RenderScore

; Renders the otherwise unreferenced post-stage-entry count field
Results_RenderUnreferencedPostStageEntryCount:          ; was: sub_1DEF8
                moveq   #0,d0
                move.w  (PostStageEntryCountBCD).w,d0
                move.w  #$C302,d1
                move.w  #$5538,d4
                moveq   #4,d7
                jmp     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Results_RenderUnreferencedPostStageEntryCount

; Renders the four-digit packed-BCD destroyed-enemy count
Results_RenderDestroyedEnemyCount:                      ; was: sub_1DF0E
                moveq   #0,d0
                move.w  (DestroyedEnemyCountBCD).w,d0
                move.w  #$C302,d1
                move.w  #$55B8,d4
                moveq   #4,d7
                jmp     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Results_RenderDestroyedEnemyCount

; Renders the four-digit packed-BCD player-damage count
Results_RenderPlayerDamage:                             ; was: sub_1DF24
                moveq   #0,d0
                move.w  (PlayerDamageBCD).w,d0
                move.w  #$C302,d1
                move.w  #$56B8,d4
                moveq   #4,d7
                jmp     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Results_RenderPlayerDamage

; Updates the final score summary and returns to the title after its exit fade
Results_UpdateFinalSummary:                             ; was: sub_1DF3A
                addq.w  #1,(FrameCounter).w
                tst.w   (GameSubstateIndex).w
                bne.s   Results_UpdateFinalSummary_Frame
                jsr     (Results_UpdateHistoryDisplayAndHandleExtendedExit).l
                bsr.w   Results_RenderHighScore
                bsr.w   Results_RenderScore
Results_UpdateFinalSummary_Frame:                       ; was: loc_1DF52
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                jsr     (Gfx_FadePaletteTransition).l
                cmpi.w  #2,(GameSubstateIndex).w
                bne.s   Results_UpdateFinalSummary_CheckInput
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   Results_UpdateFinalSummary_Return
                clr.w   (GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
Results_UpdateFinalSummary_CheckInput:                  ; was: loc_1DF74
                cmpi.w  #4,(GameSubstateIndex).w
                beq.s   Results_UpdateFinalSummary_FinishFadeOut
                btst    #7,(ControllerPressedState).w
                beq.s   Results_UpdateFinalSummary_Return
                tst.w   (GameSubstateIndex).w
                beq.s   Results_UpdateFinalSummary_StartFadeOut
                move.w  #4,(GameSubstateIndex).w
Results_UpdateFinalSummary_StartFadeOut:                ; was: loc_1DF90
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                rts
; ---------------------------------------------------------------------------
Results_UpdateFinalSummary_FinishFadeOut:               ; was: loc_1DFA2
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   Results_UpdateFinalSummary_Return
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
Results_UpdateFinalSummary_Return:                      ; was: locret_1DFB4
                rts
; End of function Results_UpdateFinalSummary
