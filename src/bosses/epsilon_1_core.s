Boss_Epsilon1Main:                                      ; was: sub_45AD0
                cmpi.w  #6,4(a5)
                bls.w   Boss_Epsilon1DispatchAndPublishScroll
                btst    #6,(PlayerActionStateFlags).w
                bne.s   Boss_Epsilon1UpdateProximityTimer
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$C,d0
                bhi.s   Boss_Epsilon1UpdatePeriodicSharedOffset
Boss_Epsilon1UpdateProximityTimer:                      ; was: loc_45AEE
                tst.w   (Epsilon1ProximityFlag).w
                bne.s   Boss_Epsilon1UpdatePeriodicSharedOffset
                addq.w  #1,(Epsilon1ProximityTimer).w
                tst.w   (DifficultyMode).w
                bne.s   Boss_Epsilon1UseShortProximityLimit
                move.w  #$80,d0
                bra.s   Boss_Epsilon1CheckProximityLimit
; ---------------------------------------------------------------------------
Boss_Epsilon1UseShortProximityLimit:                    ; was: loc_45B04
                move.w  #$40,d0                         ; '@'
Boss_Epsilon1CheckProximityLimit:                       ; was: loc_45B08
                cmp.w   (Epsilon1ProximityTimer).w,d0
                bhi.s   Boss_Epsilon1UpdatePeriodicSharedOffset
                move.w  #1,(Epsilon1ProximityFlag).w
Boss_Epsilon1UpdatePeriodicSharedOffset:                ; was: loc_45B14
                                        ; Boss_Epsilon1Main+22   j
                btst    #1,$4C(a5)
                bne.s   Boss_Epsilon1UpdatePresentation
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_Epsilon1UpdatePresentation
                move.w  $50(a5),d0
                beq.s   Boss_Epsilon1UpdatePresentation
                sub.w   d0,(BossCombatCounter).w
Boss_Epsilon1UpdatePresentation:                        ; was: loc_45B30
                                        ; Boss_Epsilon1Main+54   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (SecondaryEntityXPos).w,d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$4E(a5)
                move.w  (SharedScratchLong5).w,d0
                lea     (Math_SineTable).l,a2
                andi.w  #$1FE,d0
                move.w  -$80(a2,d0.w),d0
                ext.l   d0
                asl.l   #5,d0
                swap    d0
                add.w   (SecondaryEntityYPos).w,d0
                move.w  d0,(SharedScratchLong3+2).w
                move.w  (SecondaryEntityXPos).w,(SharedScratchLong3).w
                move.w  #$180,d0
                sub.w   (SharedScratchLong3).w,d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  #$1C8,d0
                sub.w   (SharedScratchLong3+2).w,d0
                move.w  d0,(SecondaryCameraYPos).w
                bsr.w   Boss_Epsilon1BuildScrollProfile
                bsr.w   Boss_Epsilon1UpdateVisibleTileBands
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_Epsilon1UpdateBodyAndAngleHistory
                btst    #1,(BossColorEffectFlags).w
                bne.w   Boss_Epsilon1UpdateLinkedParts
                tst.w   (BossHealth).w
                bne.s   Boss_Epsilon1UpdateBodyAndAngleHistory
                move.b  #2,(BossColorEffectFlags).w
                bset    #0,$4C(a5)
                move.w  #$5C,4(a5)                      ; '\'
                clr.l   (SecondaryEntityXVel).w
                clr.l   (SecondaryEntityYVel).w
                bset    #0,(StageTimerPauseFlag).w
                bra.w   Boss_Epsilon1UpdateLinkedParts
; ---------------------------------------------------------------------------
Boss_Epsilon1UpdateBodyAndAngleHistory:                 ; was: loc_45BC4
                                        ; Boss_Epsilon1Main+CE   j
                move.w  (SharedScratchLong3).w,d2
                move.w  (SharedScratchLong3+2).w,d3
                move.w  d2,$10(a5)
                move.w  d3,$14(a5)
                move.w  $56(a5),d0
                lea     (Math_SineTable).l,a2
                move.w  Math_QuarterSineTable-Math_SineTable(a2,d0.w),d1
                muls.w  $54(a5),d1
                swap    d1
                move.w  (SecondaryEntityWork4C).w,d0
                add.w   d0,$10(a5)
                add.w   d1,$14(a5)
                bsr.w   Boss_Epsilon1UpdateBodyPose
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FE,d0
                lea     (Epsilon1AngleHistory).w,a0
                move.w  #$2F,d7                         ; '/'
Boss_Epsilon1ShiftAngleHistoryLoop:                     ; was: loc_45C08
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d7,Boss_Epsilon1ShiftAngleHistoryLoop
                lea     (Epsilon1AngleHistory).w,a0
                lea     (SharedScratchLong0).w,a1
                move.w  #5,d7
Boss_Epsilon1SampleAngleHistoryLoop:                    ; was: loc_45C1E
                move.w  (SharedScratchLong5+2).w,d6
Boss_Epsilon1AdvanceAngleHistorySample:                 ; was: loc_45C22
                move.w  (a0)+,d0
                dbf     d6,Boss_Epsilon1AdvanceAngleHistorySample
                move.w  d0,(a1)+
                dbf     d7,Boss_Epsilon1SampleAngleHistoryLoop
                move.w  (SharedScratchLong4).w,d0
                add.w   d0,(SharedScratchLong5).w
                cmpi.w  #$12,4(a5)
                bcs.s   Boss_Epsilon1CheckForcedStateSignal
                bsr.w   Boss_Epsilon1CyclePaletteColor
Boss_Epsilon1CheckForcedStateSignal:                    ; was: loc_45C42
                bclr    #2,(CombatHitFlags).w
                beq.s   Boss_Epsilon1UpdateLinkedParts
                btst    #2,$4C(a5)
                bne.s   Boss_Epsilon1UpdateLinkedParts
                bset    #2,$4C(a5)
                move.w  #$4E,4(a5)                      ; 'N'
Boss_Epsilon1UpdateLinkedParts:                         ; was: loc_45C5E
                                        ; Boss_Epsilon1Main+F0   j
                lea     (Math_SineTable).l,a2
                move.w  (SharedScratchLong3).w,d2
                move.w  (SharedScratchLong3+2).w,d3
                movea.w #(TertiaryEntityType-M68K_RAM),a1
                move.w  $52(a1),d0
                move.w  -$80(a2,d0.w),d1
                move.w  (a2,d0.w),d0
                muls.w  $50(a1),d0
                muls.w  $50(a1),d1
                swap    d0
                swap    d1
                add.w   d2,d0
                add.w   d3,d1
                add.w   $4C(a1),d0
                add.w   $4E(a1),d1
                move.w  d0,$10(a1)
                move.w  d1,$14(a1)
                bsr.w   Boss_Epsilon1UpdateLinkedPart
                movea.w #(QuaternaryEntityType-M68K_RAM),a1
                move.w  $52(a1),d0
                move.w  -$80(a2,d0.w),d1
                move.w  (a2,d0.w),d0
                muls.w  $50(a1),d0
                muls.w  $50(a1),d1
                swap    d0
                swap    d1
                add.w   d2,d0
                add.w   d3,d1
                add.w   $4C(a1),d0
                add.w   $4E(a1),d1
                move.w  d0,$10(a1)
                move.w  d1,$14(a1)
                bsr.w   Boss_Epsilon1UpdateLinkedPart
Boss_Epsilon1DispatchAndPublishScroll:                  ; was: loc_45CD4
                bsr.w   Boss_Epsilon1DispatchState
                move.w  (SecondaryCameraXPos).w,d0
                neg.w   d0
                move.w  d0,(HScrollBuffer).w
                rts
; End of function Boss_Epsilon1Main
; Dispatches the controller's ROM-ordered state table
Boss_Epsilon1DispatchState:                             ; was: sub_45CE4
                move.w  4(a5),d0
                lea     Boss_Epsilon1States(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1DispatchState
; ---------------------------------------------------------------------------
Boss_Epsilon1States:    dc.w    Boss_Epsilon1WaitForBattleStartState-*  ; was: off_45CF0
                dc.w    Boss_Epsilon1BattleStartDelayState-*
                dc.w    Boss_Epsilon1InitializeBattleObjectsState-*
                dc.w    Boss_Epsilon1InitialTileLoadState-*
                dc.w    Boss_Epsilon1StartOpeningFadeDelayState-*
                dc.w    Boss_Epsilon1OpeningFadeDelayState-*
                dc.w    Boss_Epsilon1FinishOpeningFadeState-*
                dc.w    Boss_Epsilon1RequestBattleMessageState-*
                dc.w    Boss_Epsilon1WaitForBattleMessageState-*
                dc.w    Boss_Epsilon1SelectAttackState-*
                dc.w    Boss_Epsilon1BeginSpreadRingAttackState-*
                dc.w    Boss_Epsilon1WaitForSpreadAttackAngleWrapState-*
                dc.w    Boss_Epsilon1PrepareSpreadRingCollapseState-*
                dc.w    Boss_Epsilon1CollapseSpreadRingState-*
                dc.w    Boss_Epsilon1ActivateSpreadRingState-*
                dc.w    Boss_Epsilon1WaitForSpreadRingReadyState-*
                dc.w    Boss_Epsilon1ReserveFirstSpreadSlotState-*
                dc.w    Boss_Epsilon1ReserveSecondSpreadSlotState-*
                dc.w    Boss_Epsilon1LaunchSpreadPairState-*
                dc.w    Boss_Epsilon1BeginRingCycleAttackState-*
                dc.w    Boss_Epsilon1WaitForRingCycleAngleWrapState-*
                dc.w    Boss_Epsilon1PrepareRingCycleCollapseState-*
                dc.w    Boss_Epsilon1CollapseRingCycleState-*
                dc.w    Boss_Epsilon1ActivateRingCycleState-*
                dc.w    Boss_Epsilon1WaitForRingCycleCompleteState-*
                dc.w    Boss_Epsilon1BeginVerticalSweepAttackState-*
                dc.w    Boss_Epsilon1WaitForVerticalSweepAngleWrapState-*
                dc.w    Boss_Epsilon1PrepareVerticalSweepCollapseState-*
                dc.w    Boss_Epsilon1CollapseVerticalSweepRingState-*
                dc.w    Boss_Epsilon1MoveToUpperSweepHeightState-*
                dc.w    Boss_Epsilon1ReserveSweepSpreadSlotsState-*
                dc.w    Boss_Epsilon1AttachRingProjectilesState-*
                dc.w    Boss_Epsilon1WaitForRingObjectsInactiveState-*
                dc.w    Boss_Epsilon1StartAlignedVerticalSweepState-*
                dc.w    Boss_Epsilon1DescendAndReleaseRingState-*
                dc.w    Boss_Epsilon1RiseAfterRingReleaseState-*
                dc.w    Boss_Epsilon1WaitForReleasedRingObjectsState-*
                dc.w    Boss_Epsilon1PrepareSweepRecoveryState-*
                dc.w    Boss_Epsilon1RecoverBattleCenterState-*
                dc.w    Boss_Epsilon1BeginForcedTransitionState-*
                dc.w    Boss_Epsilon1WaitForTransitionAngleAlignmentState-*
                dc.w    Boss_Epsilon1WaitForHorizontalExitState-*
                dc.w    Boss_Epsilon1DescendToLowerBoundaryState-*
                dc.w    Boss_Epsilon1LowerBoundaryDelayState-*
                dc.w    Boss_Epsilon1ReturnToUpperBoundaryState-*
                dc.w    Boss_Epsilon1FinishForcedTransitionState-*
                dc.w    Boss_Epsilon1BeginDefeatState-*
                dc.w    Boss_Epsilon1StartLinkedPartDestructionState-*
                dc.w    Boss_Epsilon1FallWithDefeatDebrisState-*
                dc.w    Boss_Epsilon1TriggerFinalExplosionState-*
                dc.w    Boss_Epsilon1RestorePostExplosionSpriteState-*
                dc.w    Boss_Epsilon1BeginRingDestructionState-*
                dc.w    Boss_Epsilon1WaitForRingPairReadyState-*
                dc.w    Boss_Epsilon1AdvanceRingDestructionPairState-*
                dc.w    Boss_Epsilon1WaitForRingDestructionCompleteState-*
                dc.w    Boss_Epsilon1DefeatDebrisDelayState-*
                dc.w    Boss_Epsilon1AdvanceDefeatFadeState-*
                dc.w    Boss_Epsilon1ClearObjectsAfterDefeatFadeState-*
                dc.w    Boss_Epsilon1FinalDefeatFadeCountdownState-*
                dc.w    Boss_Epsilon1WaitForFirstPostBattleGateState-*
                dc.w    Boss_Epsilon1WaitForSecondPostBattleGateState-*
                dc.w    Boss_Epsilon1StartPostBattleDelayState-*
                dc.w    Boss_Epsilon1PublishBattleCompletionState-*
                dc.w    Boss_Epsilon1FinalDespawnState-*

; Waits for the stage gate, then starts the battle-entry delay and sound
Boss_Epsilon1WaitForBattleStartState:                   ; was: sub_45D70
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_Epsilon1WaitForBattleStartReturn
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                move.b  #1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_Epsilon1WaitForBattleStartReturn:                  ; was: locret_45D8C
                rts
; End of function Boss_Epsilon1WaitForBattleStartState
; Counts down the battle-entry delay
Boss_Epsilon1BattleStartDelayState:                     ; was: sub_45D8E
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1BattleStartDelayReturn
                addq.w  #2,4(a5)
Boss_Epsilon1BattleStartDelayReturn:                    ; was: locret_45D98
                rts
; End of function Boss_Epsilon1BattleStartDelayState
; Clears encounter buffers and initializes the controller, linked parts, and twelve ring objects
Boss_Epsilon1InitializeBattleObjectsState:              ; was: sub_45D9A
                bsr.w   Boss_Epsilon1ApplyTimedPaletteFade
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_Epsilon1InitializeBattleObjectsReturn
                btst    #1,(FrameCounter+1).w
                bne.w   Boss_Epsilon1InitializeBattleObjectsReturn
                btst    #2,(FrameCounter+1).w
                bne.w   Boss_Epsilon1InitializeBattleObjectsReturn
                addq.w  #1,$48(a5)
                cmpi.w  #$F,$48(a5)
                bne.w   Boss_Epsilon1InitializeBattleObjectsReturn
                addq.w  #2,4(a5)
                clr.l   (SharedScratchLong0).w
                clr.l   (SharedScratchLong1).w
                clr.l   (SharedScratchLong2).w
                clr.l   (Epsilon1RingPhaseTable).w
                clr.l   (Epsilon1RingPhaseTable+4).w
                clr.l   (Epsilon1RingPhaseTable+8).w
                clr.l   (Epsilon1RowOffsetTable).w
                clr.l   (Epsilon1RowOffsetTable+4).w
                clr.l   (Epsilon1RowOffsetTable+8).w
                clr.l   (Epsilon1VerticalAccel).w
                moveq   #0,d0
                lea     (Epsilon1AngleHistory).w,a0
                move.w  #5,d7
Boss_Epsilon1ClearAngleHistoryRowsLoop:                 ; was: loc_45E00
                move.w  (SharedScratchLong5+2).w,d6
Boss_Epsilon1ClearAngleHistoryRowLoop:                  ; was: loc_45E04
                move.w  d0,(a0)+
                dbf     d6,Boss_Epsilon1ClearAngleHistoryRowLoop
                dbf     d7,Boss_Epsilon1ClearAngleHistoryRowsLoop
                clr.w   (SharedScratchLong6+2).w
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #$264,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$120,$10(a5)
                move.w  #$F0,$14(a5)
                move.w  $10(a5),(SharedScratchLong3).w
                move.w  $14(a5),(SharedScratchLong3+2).w
                move.w  #2,$48(a5)
                move.b  #$40,$20(a5)                    ; '@'
                move.l  #Boss_Epsilon1PrimaryBodyMapping,8(a5)
                move.w  #$4300,$E(a5)
                move.w  #$CC80,2(a5)
                move.b  #$90,$21(a5)
                move.b  #$88,$23(a5)
                move.w  #$C8,$26(a5)
                move.l  #$F808F808,$2C(a5)
                move.l  #$F808F808,$28(a5)
                move.w  #$16,$24(a5)
                move.w  #$18,$54(a5)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                move.b  $20(a5),$20(a0)
                move.w  #$C80,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                move.b  $20(a5),$20(a0)
                move.l  #Boss_Epsilon1LinkedSidePartMapping,8(a0)
                move.w  #$4B00,$E(a0)
                move.w  #$CC80,2(a0)
                move.l  #$F404F40A,$28(a0)
                move.b  #$80,$21(a0)
                move.b  #$10,$23(a0)
                move.w  #$FFE6,$4C(a0)
                move.w  #$36,$4E(a0)                    ; '6'
                move.w  #$1C0,$52(a0)
                move.w  #0,$50(a0)
                movea.w #(QuaternaryEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                move.b  $20(a5),$20(a0)
                move.l  #Boss_Epsilon1LinkedSidePartMapping,8(a0)
                move.w  #$4300,$E(a0)
                move.w  #$CC80,2(a0)
                move.l  #$F404F60C,$28(a0)
                move.b  #$80,$21(a0)
                move.b  #$10,$23(a0)
                move.w  #$1A,$4C(a0)
                move.w  #$36,$4E(a0)                    ; '6'
                move.w  #$140,$52(a0)
                move.w  #0,$50(a0)
                movea.w #(FifthEntityType-M68K_RAM),a0
                move.w  #$278,(a0)
                move.w  #$C3C0,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.w  #$C80,2(a0)
                movea.w #(SixthEntityType-M68K_RAM),a0
                movea.w #(TwelfthEntityType-M68K_RAM),a1
                clr.w   d6
                move.w  #$FFB0,d4
                move.w  #$50,d5                         ; 'P'
                move.w  #5,d7
Boss_Epsilon1InitializeRingObjectPairsLoop:             ; was: loc_45F7C
                move.w  #$284,(a0)
                move.w  #$C80,2(a0)
                move.w  #$4308,$E(a0)
                move.w  #$700,8(a0)
                move.w  #$F8F0,$A(a0)
                move.b  #$10,$23(a0)
                move.l  #$FC04F010,$2C(a0)
                move.w  #$C8,$26(a0)
                move.w  #4,$20(a0)
                move.w  d6,$4A(a0)
                move.w  d4,$4C(a0)
                move.w  #$284,(a1)
                move.w  #$C80,2(a1)
                move.w  #$4308,$E(a1)
                move.w  #$700,8(a1)
                move.w  #$F8F0,$A(a1)
                move.b  #$10,$23(a1)
                move.l  #$FC04F010,$2C(a1)
                move.w  #$C8,$26(a1)
                move.w  #4,$20(a1)
                move.w  d6,$4A(a1)
                addi.w  #6,$4A(a1)
                move.w  d5,$4C(a1)
                addi.w  #-$20,d4
                addi.w  #$20,d5                         ; ' '
                addq.w  #1,d6
                lea     $60(a0),a0
                lea     $60(a1),a1
                dbf     d7,Boss_Epsilon1InitializeRingObjectPairsLoop
Boss_Epsilon1InitializeBattleObjectsReturn:             ; was: locret_46014
                                        ; Boss_Epsilon1InitializeBattleObjectsState+14   j
                rts
; End of function Boss_Epsilon1InitializeBattleObjectsState
; Applies palette fade effect
Boss_Epsilon1ApplyPaletteFade:                          ; was: sub_46016
                                        ; sub_461A6   p
                move.w  #$E,d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                rts
; End of function Boss_Epsilon1ApplyPaletteFade
; Applies the opening fade while alternating initial tile-load groups
Boss_Epsilon1InitialTileLoadState:                      ; was: sub_46032
                bsr.w   Boss_Epsilon1ApplyPaletteFade
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_Epsilon1InitialTileLoadReturn
                subq.w  #1,$48(a5)
                bmi.s   Boss_Epsilon1AdvanceFromInitialTileLoad
                move.w  $48(a5),d0
                add.w   d0,d0
                move.w  d0,d0
                lea     Boss_Epsilon1InitialTileLoadGroups(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; ---------------------------------------------------------------------------
Boss_Epsilon1InitialTileLoadGroups: dc.w    Gfx_LoadEpsilon1FourTileBands-*  ; was: off_46052
                dc.w    Gfx_LoadEpsilon1WideTileBands-*
; ---------------------------------------------------------------------------
Boss_Epsilon1AdvanceFromInitialTileLoad:                ; was: loc_46056
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_Epsilon1InitialTileLoadReturn
                addq.w  #2,4(a5)
Boss_Epsilon1InitialTileLoadReturn:                     ; was: locret_46060
                                        ; Boss_Epsilon1InitialTileLoadState+28   j
                rts
; End of function Boss_Epsilon1InitialTileLoadState
; Loads all four tile sets for Epsilon1 graphics
Gfx_LoadEpsilon1FourTileBands:                          ; was: sub_46062
                bsr.w   Gfx_LoadEpsilon1TileBand4
                bsr.w   Gfx_LoadEpsilon1TileBand3
                bsr.w   Gfx_LoadEpsilon1TileBand2
                bsr.w   Gfx_LoadEpsilon1TileBand1
                rts
; End of function Gfx_LoadEpsilon1FourTileBands
; Loads the two wider Epsilon 1 tile bands
Gfx_LoadEpsilon1WideTileBands:                          ; was: sub_46074
                bsr.w   Gfx_LoadEpsilon1WideTileBand2
                bsr.w   Gfx_LoadEpsilon1WideTileBand1
                rts
; End of function Gfx_LoadEpsilon1WideTileBands
; Loads the first vertical tile band
Gfx_LoadEpsilon1TileBand1:                              ; was: sub_4607E
                                        ; Boss_Epsilon1UpdateVisibleTileBands+58   p
                lea     Gfx_Epsilon1TileBand1LoadCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadEpsilon1TileBand1
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand1LoadCommand:   dc.w    $4130, $2000, $300, $A1A2, $A3A8  ; was: word_4608A

; Clears the first vertical tile band
Gfx_ClearEpsilon1TileBand1:                             ; was: sub_46094
                                        ; Boss_Epsilon1UpdateVisibleTileBands:Boss_Epsilon1ClearAllTileBands   p
                lea     Gfx_Epsilon1TileBand1ClearCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_ClearEpsilon1TileBand1
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand1ClearCommand:  dc.w    $4130, $2000, $300, 0, 0  ; was: word_460A0

; Loads the second vertical tile band
Gfx_LoadEpsilon1TileBand2:                              ; was: sub_460AA
                                        ; Boss_Epsilon1UpdateVisibleTileBands+72   p
                lea     Gfx_Epsilon1TileBand2LoadCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadEpsilon1TileBand2
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand2LoadCommand:   dc.w    $4330, $2000, $300, $A5A6, $A7AC  ; was: word_460B6

; Clears the second vertical tile band
Gfx_ClearEpsilon1TileBand2:                             ; was: sub_460C0
                                        ; Boss_Epsilon1UpdateVisibleTileBands+B6   p
                lea     Gfx_Epsilon1TileBand2ClearCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_ClearEpsilon1TileBand2
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand2ClearCommand:  dc.w    $4330, $2000, $300, 0, 0  ; was: word_460CC

; Loads the third vertical tile band
Gfx_LoadEpsilon1TileBand3:                              ; was: sub_460D6
                                        ; Boss_Epsilon1UpdateVisibleTileBands+8C   p
                lea     Gfx_Epsilon1TileBand3LoadCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadEpsilon1TileBand3
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand3LoadCommand:   dc.w    $4530, $2000, $300, $A9AA, $ABAD  ; was: word_460E2

; Clears the third vertical tile band
Gfx_ClearEpsilon1TileBand3:                             ; was: sub_460EC
                                        ; Boss_Epsilon1UpdateVisibleTileBands+BA   p
                lea     Gfx_Epsilon1TileBand3ClearCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_ClearEpsilon1TileBand3
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand3ClearCommand:  dc.w    $4530, $2000, $300, 0, 0  ; was: word_460F8

; Loads the fourth vertical tile band
Gfx_LoadEpsilon1TileBand4:                              ; was: sub_46102
                                        ; Boss_Epsilon1UpdateVisibleTileBands+A6   p
                lea     Gfx_Epsilon1TileBand4LoadCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadEpsilon1TileBand4
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand4LoadCommand:   dc.w    $4730, $2000, $300, $AE, $AF00  ; was: word_4610E

; Clears the fourth vertical tile band
Gfx_ClearEpsilon1TileBand4:                             ; was: sub_46118
                                        ; Boss_Epsilon1UpdateVisibleTileBands+BE   p
                lea     Gfx_Epsilon1TileBand4ClearCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_ClearEpsilon1TileBand4
; ---------------------------------------------------------------------------
Gfx_Epsilon1TileBand4ClearCommand:  dc.w    $4730, $2000, $300, 0, 0  ; was: word_46124

; Loads the first wider tile band
Gfx_LoadEpsilon1WideTileBand1:                          ; was: sub_4612E
                lea     Gfx_Epsilon1WideTileBand1LoadCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadEpsilon1WideTileBand1
; ---------------------------------------------------------------------------
Gfx_Epsilon1WideTileBand1LoadCommand:   dc.w    $4180, $2000, $501, $9A9A, $9A9A, $9A9A, $9E9E, $9E9E, $9E9E  ; was: word_4613A

; Clears the first wider tile band
Gfx_ClearEpsilon1WideTileBand1:
                lea     Gfx_Epsilon1WideTileBand1ClearCommand(pc),a0  ; was: sub_4614C
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_ClearEpsilon1WideTileBand1
; ---------------------------------------------------------------------------
Gfx_Epsilon1WideTileBand1ClearCommand:  dc.w    $4180, $2000, $501, 0, 0, 0, 0, 0, 0  ; was: word_46158

; Loads the second wider tile band
Gfx_LoadEpsilon1WideTileBand2:                          ; was: sub_4616A
                lea     Gfx_Epsilon1WideTileBand2LoadCommand(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadEpsilon1WideTileBand2
; ---------------------------------------------------------------------------
Gfx_Epsilon1WideTileBand2LoadCommand:   dc.w    $41D0, $2000, $501, $9A9A, $9A9A, $9A9A, $9E9E, $9E9E, $9E9E  ; was: word_46176

; Clears the second wider tile band
Gfx_ClearEpsilon1WideTileBand2:
                lea     Gfx_Epsilon1WideTileBand2ClearCommand(pc),a0  ; was: sub_46188
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_ClearEpsilon1WideTileBand2
; ---------------------------------------------------------------------------
Gfx_Epsilon1WideTileBand2ClearCommand:  dc.w    $41D0, $2000, $501, 0, 0, 0, 0, 0, 0  ; was: word_46194

; Attack phase 1 initialization
