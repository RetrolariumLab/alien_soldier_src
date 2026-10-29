; Initializes a password-selected session while preserving stage and difficulty
Password_InitializeSelectedStage:                       ; was: sub_1CCEC
                bset    #0,(StageRouteFlags).w
                bra.s   Game_InitializeSessionState
; End of function Password_InitializeSelectedStage
; Initializes a fresh stage-zero game session
Game_InitializeNewSession:                              ; was: sub_1CCF4
                                        ; TitleScreen_Update+BA   j
                clr.w   (StageTableIndex).w
                move.w  #2,(ShootingMode).w
                clr.b   (StageRouteFlags).w
; Resets session-wide health, score, counters, history, and palette state
Game_InitializeSessionState:                            ; was: loc_1CD02
                move.w  #$200,(PlayerHealth).w
                move.w  #$200,(PlayerMaxHealth).w
                clr.l   (ScoreValueBCD).w
                clr.w   (DebugResourceRefill).w
                move.w  #3,(ContinueCreditsBCD).w
                clr.w   (PostStageEntryCountBCD).w
                clr.w   (DestroyedEnemyCountBCD).w
                clr.w   (PlayerDamageBCD).w
                clr.w   (FrameSkipLevel).w
                clr.w   (RasterLayoutOffset).w
                clr.b   (MessageDisplayFlags).w
                bsr.w   Results_InitializeStageHistory
                bra.s   UI_ResetPaletteAndMessageMode_Clear
; End of function Game_InitializeNewSession
; Initializes gameplay state for a selected stage and restores weapon ammo
StageEntry_InitializeGameplayState:                     ; was: sub_1CD3A
                move.w  (PlayerMaxHealth).w,(PlayerHealth).w
                tst.w   (DifficultyMode).w
                beq.s   StageEntry_InitializeGameplayState_CopyAmmo
                move.w  #$3E8,d0
                move.w  d0,(WeaponSlotAmmoMax0).w
                move.w  d0,(WeaponSlotAmmoMax1).w
                move.w  d0,(WeaponSlotAmmoMax2).w
                move.w  d0,(WeaponSlotAmmoMax3).w
StageEntry_InitializeGameplayState_CopyAmmo:            ; was: loc_1CD5A
                move.w  (WeaponSlotAmmoMax0).w,(WeaponSlotAmmo0).w
                move.w  (WeaponSlotAmmoMax1).w,(WeaponSlotAmmo1).w
                move.w  (WeaponSlotAmmoMax2).w,(WeaponSlotAmmo2).w
                move.w  (WeaponSlotAmmoMax3).w,(WeaponSlotAmmo3).w
                clr.l   (ScoreValueBCD).w
                clr.w   (DebugResourceRefill).w
                clr.w   (DestroyedEnemyCountBCD).w
                clr.w   (PlayerDamageBCD).w
                clr.w   (FrameSkipLevel).w
                clr.w   (WeaponStateIndex).w
                clr.w   (RasterLayoutOffset).w
                clr.b   (MessageDisplayFlags).w
                bsr.s   UI_ResetPaletteAndMessageMode
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                move.w  (StageTableIndex).w,d0
                asr.b   #1,d0
                move.b  StageEntrySoundRequestByStage(pc,d0.w),(StageIntroSoundRequest).w
                rts
; End of function StageEntry_InitializeGameplayState

; Clears transient weapon and stage-entry state before reloading gameplay
StageEntry_ClearTransientState:                         ; was: sub_1CDA8
                clr.w   (DebugResourceRefill).w
                clr.w   (WeaponStateIndex).w
                clr.w   (RasterLayoutOffset).w
; End of function StageEntry_ClearTransientState
; Loads the stage time limit, clears both palette buffers, and resets message mode
UI_ResetPaletteAndMessageMode:                          ; was: sub_1CDB4
                bsr.w   Stage_LoadTimeLimit
; Direct entry skips the time-limit load but performs the same palette reset
UI_ResetPaletteAndMessageMode_Clear:                    ; was: loc_1CDB8
                                        ; UI_UpdateSecondaryOptionsMenu+12   j
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                moveq   #0,d0
                moveq   #$3F,d7                         ; '?'
; Writes one longword per iteration using the registers set above
UI_ClearPaletteBuffers_Loop:                            ; was: loc_1CDC0
                move.l  d0,(a0)+
                dbf     d7,UI_ClearPaletteBuffers_Loop
                move.w  #4,(MessageMode).w
                rts
; End of function UI_ResetPaletteAndMessageMode
; Per-stage SFX request consumed when the STAGE-number banner reaches its cue
StageEntrySoundRequestByStage:  dc.b    $18, $18, $18, $18, $18, $18, $18, $18, $18, $18  ; was: byte_1CDCE
                dc.b    $18, $18, $18, $18, $18, $18, $18, $18, $18, 0
                dc.b    $18, $18, $18, $18, $18, $18, $18, $18, $18, $18
                dc.b    $18, $18, $18, $18, $18, $18, $18, $18

; Stores the remaining packed-BCD timer at the intermediate phase boundary
Results_StorePhaseSplitTime:                            ; was: sub_1CDF4
                movea.w #(StagePhaseSplitTimes-M68K_RAM),a0
                move.w  (StageTableIndex).w,d0
                move.w  (StageTimeRemaining).w,(a0,d0.w)
                rts
; End of function Results_StorePhaseSplitTime
; Stores the remaining packed-BCD timer when the stage result is finalized
Results_StoreStageCompletionTime:                       ; was: sub_1CE04
                                        ; Boss_ZLeoRunPostDefeatDelay+2E   j
                movea.w #(StageCompletionTimes-M68K_RAM),a0
                move.w  (StageTableIndex).w,d0
                move.w  (StageTimeRemaining).w,(a0,d0.w)
                rts
; End of function Results_StoreStageCompletionTime
; Increments the current stage's result-visit count, saturating at 999
Results_IncrementStageVisitCount:                       ; was: sub_1CE14
                movea.w #(StageResultVisits-M68K_RAM),a0
                adda.w  (StageTableIndex).w,a0
                cmpi.w  #$3E7,(a0)
                bpl.s   Results_IncrementStageVisitCountReturn
                addq.w  #1,(a0)
Results_IncrementStageVisitCountReturn:                 ; was: locret_1CE24
                rts
; End of function Results_IncrementStageVisitCount
; Initializes the contiguous per-stage results history to missing values
Results_InitializeStageHistory:                         ; was: sub_1CE26
                movea.w #(StagePhaseSplitTimes-M68K_RAM),a0
                move.w  #$FFFF,d0
                move.w  #$BF,d7
; Fills the stage-history storage with the missing-value sentinel
Results_InitializeStageHistoryLoop:                     ; was: loc_1CE32
                move.w  d0,(a0)+
                dbf     d7,Results_InitializeStageHistoryLoop
                rts
; End of function Results_InitializeStageHistory
; Loads the current stage's packed-BCD time limit into the live timer
Stage_LoadTimeLimit:                                    ; was: sub_1CE3A
                                        ; sub_1CDB4   p
                lea     StageTimeLimitTable(pc),a0
                nop
                move.w  (StageTableIndex).w,d0
                move.w  (a0,d0.w),(StageTimeRemaining).w
                rts
; End of function Stage_LoadTimeLimit
; ---------------------------------------------------------------------------
StageTimeLimitTable:    dc.w    $200, $240, $300, $330, $330  ; was: word_1CE4C
                                        ; Results_InitializeHistoryDisplay+4E   o
                dc.w    $210, $220, $300, $340, $300
                dc.w    $320, $410, $200, $200, $240
                dc.w    $340, $300, $400, $220, $950
                dc.w    $200, $200, $410, $220, $555

; Sets up results screen graphics and memory state
