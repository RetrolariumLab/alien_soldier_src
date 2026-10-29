; Gusthead root mappings alternate every eight frames
Boss_GustheadRootMappings:  dc.l    Boss_GustheadRootMappingA  ; DATA XREF: Boss_GustheadUpdateAndDispatchState+20   o  ; was: off_3F198
                dc.l    Boss_GustheadRootMappingB

; Entity-table entry for the Gusthead root controller
Boss_GustheadUpdateEntry:                               ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_3F1A0
                bsr.s   Boss_GustheadUpdateAndDispatchState
                rts
; End of function Boss_GustheadUpdateEntry
; Updates the Gusthead root and dispatches its current state
Boss_GustheadUpdateAndDispatchState:                    ; CODE XREF: Boss_GustheadUpdateEntry   p  ; was: sub_3F1A4
                tst.w   4(a5)
                beq.w   Boss_GustheadDispatchState
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_GustheadAfterRootMappingToggle
                addq.w  #4,$58(a5)
                andi.w  #4,$58(a5)
                move.w  $58(a5),d0
                lea     Boss_GustheadRootMappings(pc),a1
                move.l  (a1,d0.w),8(a5)
                clr.w   $C(a5)
Boss_GustheadAfterRootMappingToggle:                    ; CODE XREF: Boss_GustheadUpdateAndDispatchState+10   j  ; was: loc_3F1D2
                tst.w   (GustheadFinalPhaseFlag).w
                beq.s   Boss_GustheadSelectDebrisDrift
                move.l  (GustheadArenaVelocity).w,d0
                add.l   d0,$10(a5)
Boss_GustheadSelectDebrisDrift:                         ; CODE XREF: Boss_GustheadUpdateAndDispatchState+32   j  ; was: loc_3F1E0
                cmpi.w  #$50,4(a5)                      ; 'P'
                bcc.s   Boss_GustheadUseArenaMotionDebrisDrift
                move.l  (StageMotionXDelta).w,(SharedScratchLong10).w
                bra.s   Boss_GustheadCheckDefeatTrigger
; ---------------------------------------------------------------------------
Boss_GustheadUseArenaMotionDebrisDrift:                 ; CODE XREF: Boss_GustheadUpdateAndDispatchState+42   j  ; was: loc_3F1F0
                move.l  (GustheadArenaVelocity).w,d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,(SharedScratchLong10).w
Boss_GustheadCheckDefeatTrigger:                        ; CODE XREF: Boss_GustheadUpdateAndDispatchState+4A   j  ; was: loc_3F1FC
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_GustheadUpdatePaletteAndScreenX
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_GustheadUpdatePaletteAndScreenX
                tst.w   (BossHealth).w
                bne.s   Boss_GustheadUpdatePaletteAndScreenX
                move.b  #2,(BossColorEffectFlags).w
                bset    #7,$4A(a5)
                clr.l   (StageMotionXDelta).w
                move.w  #$5C,4(a5)                      ; '\'
                bset    #0,(StageTimerPauseFlag).w
Boss_GustheadUpdatePaletteAndScreenX:                   ; CODE XREF: Boss_GustheadUpdateAndDispatchState+5E   j  ; was: loc_3F22E
                                        ; Boss_GustheadUpdateAndDispatchState+66   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$5C(a5)
Boss_GustheadDispatchState:                             ; CODE XREF: Boss_GustheadUpdateAndDispatchState+4   j  ; was: loc_3F240
                move.w  4(a5),d0
                lea     Boss_GustheadStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_GustheadUpdateAndDispatchState
; ---------------------------------------------------------------------------
Boss_GustheadStates:    dc.w    Boss_GustheadWaitForAssetsAndClearArena-*  ; DATA XREF: Boss_GustheadUpdateAndDispatchState+A0   o  ; was: off_3F24C
                dc.w    Boss_GustheadInitializeRootAndParts-*
                dc.w    Boss_GustheadBeginIntroFlicker-*
                dc.w    Boss_GustheadUpdateSlowIntroFlicker-*
                dc.w    Boss_GustheadUpdateFastIntroFlickerAndStartMotion-*
                dc.w    Boss_GustheadRetractSegmentsForBattleState-*
                dc.w    Boss_GustheadStopBattleEntrySpinState-*
                dc.w    Boss_GustheadWaitForBattleBannerState-*
                dc.w    Boss_GustheadChoosePatternState-*
                dc.w    Boss_GustheadBeginOscillationPattern-*
                dc.w    Boss_GustheadAlignMiddleJointState-*
                dc.w    Boss_GustheadSweepOuterJointState-*
                dc.w    Boss_GustheadWaitForMiddleJointZeroState-*
                dc.w    Boss_GustheadCountMiddleJointCyclesState-*
                dc.w    Boss_GustheadBrakeOuterJointState-*
                dc.w    Boss_GustheadReturnToPatternChoiceState-*
                dc.w    Boss_GustheadBeginBouncePattern-*
                dc.w    Boss_GustheadAlignJointsForBounceState-*
                dc.w    Boss_GustheadBouncePatternState-*
                dc.w    Boss_GustheadBeginPatternDescentState-*
                dc.w    Boss_GustheadAlignJointsAfterDescentState-*
                dc.w    Boss_GustheadBeginFragmentPattern-*
                dc.w    Boss_GustheadAccelerateFragmentPatternSpinState-*
                dc.w    Boss_GustheadFragmentPatternFlashState-*
                dc.w    Boss_GustheadFragmentPatternRepositionState-*
                dc.w    Boss_GustheadDecelerateFragmentPatternRotationState-*
                dc.w    Boss_GustheadFragmentPatternRevealState-*
                dc.w    Boss_GustheadReturnToPatternChoiceAfterFragmentsState-*
                dc.w    Boss_GustheadBeginArenaTransitionState-*
                dc.w    Boss_GustheadWaitForArenaTransitionState-*
                dc.w    Boss_GustheadWaitForArenaTransitionState-*
                dc.w    Boss_GustheadWaitForArenaTransitionState-*
                dc.w    Boss_GustheadBeginFinalPhaseTransitionState-*
                dc.w    Boss_GustheadFinalPhaseRiseState-*
                dc.w    Boss_GustheadFinalPhaseFlashState-*
                dc.w    Boss_GustheadFinalPhasePositioningState-*
                dc.w    Boss_GustheadDecelerateFinalPhaseRotationState-*
                dc.w    Boss_GustheadFinalPhaseRevealState-*
                dc.w    Boss_GustheadActivateFinalPhaseState-*
                dc.w    Boss_GustheadBeginFinalBattle-*
                dc.w    Boss_GustheadInitializeFinalBattleMotion-*
                dc.w    Boss_GustheadAlignJointsForFinalBattleState-*
                dc.w    Boss_GustheadAccelerateFinalBattleRotationState-*
                dc.w    Boss_GustheadWaitForFinalBattleScrollState-*
                dc.w    Boss_GustheadFinalBattleAttackState-*
                dc.w    Boss_GustheadFinalBattleLoopState-*
                dc.w    Boss_GustheadBeginDefeatState-*
                dc.w    Boss_GustheadDecelerateArenaDuringDefeatState-*
                dc.w    Boss_GustheadFallAndExplodeDuringDefeatState-*
                dc.w    Boss_GustheadAdvanceDefeatPaletteFadeState-*
                dc.w    Boss_GustheadHoldDefeatPaletteState-*
                dc.w    Boss_GustheadReverseDefeatPaletteAndClearObjectsState-*
                dc.w    Boss_GustheadStopArenaAtAlignedBoundaryState-*
                dc.w    Boss_GustheadRemoveAfterDefeatDelayState-*

; Waits for asset loading, then clears the arena for Gusthead setup
Boss_GustheadWaitForAssetsAndClearArena:                ; DATA XREF: ROM:Boss_GustheadStates   o  ; was: sub_3F2B8
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_GustheadUpdateSegmentPositionsReturn
                addq.w  #2,4(a5)
                move.w  #$1B0,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; End of function Boss_GustheadWaitForAssetsAndClearArena
; Initializes the Gusthead root, four four-segment arms, and trailing effect object
Boss_GustheadInitializeRootAndParts:                    ; DATA XREF: ROM:0003F24E   o  ; was: sub_3F2D0
                addq.w  #2,4(a5)
                clr.l   (SharedScratchLong0).w
                clr.l   (SharedScratchLong1).w
                clr.l   (SharedScratchLong2).w
                clr.l   (SharedScratchLong3).w
                clr.l   (SharedScratchLong4).w
                clr.l   (SharedScratchLong5).w
                clr.l   (SharedScratchLong6).w
                clr.l   (SharedScratchLong7).w
                clr.l   (SharedScratchLong8).w
                clr.w   (SharedScratchLong9).w
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #$120,$10(a5)
                move.w  #$F0,$14(a5)
                move.b  #$40,$20(a5)                    ; '@'
                move.w  #$4C00,2(a5)
                move.b  #$10,$21(a5)
                move.b  #$88,$23(a5)
                move.l  #$F808F808,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$16,$24(a5)
                move.w  #$50,$26(a5)                    ; 'P'
                move.w  #$300,$E(a5)
                move.l  #Boss_GustheadRootMappingB,8(a5)
                move.w  #3,d7
                movea.w a5,a0
                lea     $60(a0),a0
                clr.b   d5
Boss_GustheadSetupArmLoop:                              ; CODE XREF: Boss_GustheadInitializeRootAndParts+DA   j  ; was: loc_3F35C
                move.w  #3,d6
                clr.b   d0
Boss_GustheadSetupSegmentLoop:                          ; CODE XREF: Boss_GustheadInitializeRootAndParts+D2   j  ; was: loc_3F362
                move.w  #$1BC,(a0)
                move.w  #$4C00,2(a0)
                move.w  #$B00,$E(a0)
                move.l  #Boss_GustheadSegmentMappingD,8(a0)
                tst.b   d0
                bne.s   Boss_GustheadUseInnerSegmentRadius
                move.w  #$28,$48(a0)                    ; '('
                bra.s   Boss_GustheadFinalizeSegmentSetup
; ---------------------------------------------------------------------------
Boss_GustheadUseInnerSegmentRadius:                     ; CODE XREF: Boss_GustheadInitializeRootAndParts+AC   j  ; was: loc_3F386
                move.w  #$18,$48(a0)
Boss_GustheadFinalizeSegmentSetup:                      ; CODE XREF: Boss_GustheadInitializeRootAndParts+B4   j  ; was: loc_3F38C
                move.w  #$80,d1
                add.w   d1,$48(a0)
                move.b  d5,$4B(a0)
                move.b  d0,$4A(a0)
                lea     $60(a0),a0
                addq.b  #1,d0
                dbf     d6,Boss_GustheadSetupSegmentLoop
                addi.b  #$40,d5                         ; '@'
                dbf     d7,Boss_GustheadSetupArmLoop
                move.w  #$10,(a0)
                move.w  #$6100,2(a0)
                move.l  #SharedCombatSpriteAnimation12,8(a0)
                move.w  #$480,$E(a0)
                rts
; End of function Boss_GustheadInitializeRootAndParts
; Starts the 32-tick slow intro flicker
Boss_GustheadBeginIntroFlicker:                         ; DATA XREF: ROM:0003F250   o  ; was: sub_3F3C8
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
                rts
; End of function Boss_GustheadBeginIntroFlicker
; Toggles visibility every four frames during the slow intro flicker
Boss_GustheadUpdateSlowIntroFlicker:                    ; DATA XREF: ROM:0003F252   o  ; was: sub_3F3D4
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_GustheadSlowIntroFlickerCountDown
                eori.w  #$8000,2(a5)
Boss_GustheadSlowIntroFlickerCountDown:                 ; CODE XREF: Boss_GustheadUpdateSlowIntroFlicker+8   j  ; was: loc_3F3E4
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadSlowIntroFlickerReturn
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
Boss_GustheadSlowIntroFlickerReturn:                    ; CODE XREF: Boss_GustheadUpdateSlowIntroFlicker+14   j  ; was: locret_3F3F4
                rts
; End of function Boss_GustheadUpdateSlowIntroFlicker
; Toggles visibility every two frames, then starts joint and vertical motion
Boss_GustheadUpdateFastIntroFlickerAndStartMotion:      ; DATA XREF: ROM:0003F254   o  ; was: sub_3F3F6
                move.w  (FrameCounter).w,d0
                andi.w  #1,d0
                bne.s   Boss_GustheadFastIntroFlickerCountDown
                eori.w  #$8000,2(a5)
Boss_GustheadFastIntroFlickerCountDown:                 ; CODE XREF: Boss_GustheadUpdateFastIntroFlickerAndStartMotion+8   j  ; was: loc_3F406
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFastIntroFlickerReturn
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #$10,(SharedScratchLong3).w
                move.w  #$40,(SharedScratchLong0).w     ; '@'
                move.w  #$80,(SharedScratchLong1).w
                move.w  #$180,(SharedScratchLong2).w
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$4C(a5)
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateVerticalBounce
Boss_GustheadFastIntroFlickerReturn:                    ; CODE XREF: Boss_GustheadUpdateFastIntroFlickerAndStartMotion+14   j  ; was: locret_3F44A
                rts
; End of function Boss_GustheadUpdateFastIntroFlickerAndStartMotion
; Retracts all segment radii before the battle-entry banner
Boss_GustheadRetractSegmentsForBattleState:             ; DATA XREF: ROM:0003F256   o  ; was: sub_3F44C
                move.w  #3,d7
                movea.w a5,a0
                lea     $60(a0),a0
Boss_GustheadBattleEntryArmLoop:                        ; CODE XREF: Boss_GustheadRetractSegmentsForBattleState+1C   j  ; was: loc_3F456
                move.w  #3,d6
Boss_GustheadBattleEntrySegmentLoop:                    ; CODE XREF: Boss_GustheadRetractSegmentsForBattleState+18   j  ; was: loc_3F45A
                subi.w  #2,$48(a0)
                lea     $60(a0),a0
                dbf     d6,Boss_GustheadBattleEntrySegmentLoop
                dbf     d7,Boss_GustheadBattleEntryArmLoop
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateVerticalBounce
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadRetractSegmentsForBattleReturn
                addq.w  #2,4(a5)
Boss_GustheadRetractSegmentsForBattleReturn:            ; CODE XREF: Boss_GustheadRetractSegmentsForBattleState+36   j  ; was: locret_3F488
                rts
; End of function Boss_GustheadRetractSegmentsForBattleState
; Brakes the introductory outer-joint spin before showing the battle banner
Boss_GustheadStopBattleEntrySpinState:                  ; DATA XREF: ROM:0003F258   o  ; was: sub_3F48A
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateVerticalBounce
                eori.w  #$8000,2(a5)
                subi.l  #$2000,(SharedScratchLong3).w
                bne.s   Boss_GustheadStopBattleEntrySpinReturn
                ori.w   #$8000,2(a5)
                move.b  #$50,$21(a5)                    ; 'P'
                addq.w  #2,4(a5)
                move.w  #3,d0
                jsr     (BossMessage_Start).l
Boss_GustheadStopBattleEntrySpinReturn:                 ; CODE XREF: Boss_GustheadStopBattleEntrySpinState+1A   j  ; was: locret_3F4C0
                rts
; End of function Boss_GustheadStopBattleEntrySpinState
; Waits for the battle-entry banner to finish before enabling pattern selection
Boss_GustheadWaitForBattleBannerState:                  ; DATA XREF: ROM:0003F25A   o  ; was: sub_3F4C2
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateVerticalBounce
                tst.w   (MessageSequenceState).w
                bne.s   Boss_GustheadWaitForBattleBannerReturn
                clr.b   (BossColorEffectFlags).w
                ori.w   #$100,2(a5)
                subi.w  #$A0,(CameraXLowerBound).w
                addq.w  #2,4(a5)
Boss_GustheadWaitForBattleBannerReturn:                 ; CODE XREF: Boss_GustheadWaitForBattleBannerState+10   j  ; was: locret_3F4E8
                rts
; End of function Boss_GustheadWaitForBattleBannerState
; Chooses one of the three regular Gusthead movement patterns
Boss_GustheadChoosePatternState:                        ; DATA XREF: ROM:0003F25C   o  ; was: sub_3F4EA
                cmpi.w  #$3200,(BossHealth).w
                bcs.s   Boss_GustheadTriggerFinalPhaseTransition
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                tst.w   d0
                beq.s   Boss_GustheadChooseOscillationPattern
                cmpi.w  #1,d0
                beq.s   Boss_GustheadChooseBouncePattern
                cmpi.w  #2,d0
                beq.s   Boss_GustheadChooseFragmentPattern
Boss_GustheadChooseOscillationPattern:                  ; CODE XREF: Boss_GustheadChoosePatternState+12   j  ; was: loc_3F50A
                move.w  #1,$5A(a5)
                move.w  #$12,4(a5)
                bra.w   Boss_GustheadBeginOscillationPattern
; ---------------------------------------------------------------------------
Boss_GustheadChooseBouncePattern:                       ; CODE XREF: Boss_GustheadChoosePatternState+18   j  ; was: loc_3F51A
                move.w  #3,$5A(a5)
                move.w  #$20,4(a5)                      ; ' '
                bra.w   Boss_GustheadBeginBouncePattern
; ---------------------------------------------------------------------------
Boss_GustheadChooseFragmentPattern:                     ; CODE XREF: Boss_GustheadChoosePatternState+1E   j  ; was: loc_3F52A
                move.w  #2,$5A(a5)
                move.w  #$2A,4(a5)                      ; '*'
                bra.w   Boss_GustheadBeginFragmentPattern
; End of function Boss_GustheadChoosePatternState
; Begins the arena-boundary transition back to pattern selection
Boss_GustheadTriggerArenaTransition:                    ; was: sub_3F53A
                bset    #6,$4A(a5)
                move.w  #$38,4(a5)                      ; '8'
                bra.w   Boss_GustheadBeginArenaTransitionState
; End of function Boss_GustheadTriggerArenaTransition
; Begins the scripted transition into Gusthead's final battle phase
Boss_GustheadTriggerFinalPhaseTransition:               ; CODE XREF: Boss_GustheadChoosePatternState+6   j  ; was: sub_3F54A
                bset    #6,$4A(a5)
                move.w  #1,(GustheadFinalPhaseFlag).w
                clr.l   (GustheadArenaVelocity).w
                move.w  #$40,4(a5)                      ; '@'
                bra.w   Boss_GustheadBeginFinalPhaseTransitionState
; End of function Boss_GustheadTriggerFinalPhaseTransition
; Initializes the regular joint-oscillation pattern
Boss_GustheadBeginOscillationPattern:                   ; CODE XREF: Boss_GustheadChoosePatternState+2C   j  ; was: sub_3F564
                                        ; DATA XREF: ROM:0003F25E   o
                addq.w  #2,4(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$4C(a5)
                clr.l   (SharedScratchLong3).w
                clr.l   (SharedScratchLong4).w
                clr.l   (SharedScratchLong5).w
                andi.l  #$1F80000,(SharedScratchLong0).w
                andi.l  #$1F80000,(SharedScratchLong1).w
                andi.l  #$1F80000,(SharedScratchLong2).w
                move.w  #$F0,$52(a5)
; Aligns the middle joint before the oscillation cycle
Boss_GustheadAlignMiddleJointState:                     ; DATA XREF: ROM:0003F260   o  ; was: loc_3F5A2
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadMoveTowardPatternTarget
                subi.w  #8,(SharedScratchLong1).w
                andi.w  #$1F8,(SharedScratchLong1).w
                bne.w   Boss_GustheadUpdateSegmentPositionsReturn
                addq.w  #2,4(a5)
                move.l  #$FFFE0000,(SharedScratchLong4).w
                move.l  #$1000,(SharedScratchLong7).w
                cmpi.w  #$120,(PlayerXPosition).w
                bcc.s   Boss_GustheadAccelerateOuterJointPositive
                move.l  #$FFFFF000,(SharedScratchLong6).w
                bra.s   Boss_GustheadBeginOscillationPatternReturn
; ---------------------------------------------------------------------------
Boss_GustheadAccelerateOuterJointPositive:              ; CODE XREF: Boss_GustheadBeginOscillationPattern+74   j  ; was: loc_3F5E4
                move.l  #$1000,(SharedScratchLong6).w
Boss_GustheadBeginOscillationPatternReturn:             ; CODE XREF: Boss_GustheadBeginOscillationPattern+7E   j  ; was: locret_3F5EC
                rts
; End of function Boss_GustheadBeginOscillationPattern
; Sweeps the outer joint until its signed angular-speed boundary
Boss_GustheadSweepOuterJointState:                      ; DATA XREF: ROM:0003F262   o  ; was: sub_3F5EE
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadOscillateMiddleJointSpeed
                bsr.s   Boss_GustheadMoveTowardPatternTarget
                move.l  (SharedScratchLong6).w,d0
                add.l   d0,(SharedScratchLong3).w
                cmpi.l  #$C0000,(SharedScratchLong3).w
                beq.s   Boss_GustheadFinishOuterJointSweep
                cmpi.l  #$FFF40000,(SharedScratchLong3).w
                bne.s   Boss_GustheadSweepOuterJointReturn
Boss_GustheadFinishOuterJointSweep:                     ; CODE XREF: Boss_GustheadSweepOuterJointState+26   j  ; was: loc_3F620
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
Boss_GustheadSweepOuterJointReturn:                     ; CODE XREF: Boss_GustheadSweepOuterJointState+30   j  ; was: locret_3F62A
                rts
; End of function Boss_GustheadSweepOuterJointState
; Moves the boss body toward the horizontal and vertical pattern targets
Boss_GustheadMoveTowardPatternTarget:                   ; CODE XREF: Boss_GustheadBeginOscillationPattern+46   p  ; was: sub_3F62C
                                        ; Boss_GustheadSweepOuterJointState+14   p
                move.w  $10(a5),d0
                sub.w   (PlayerXPosition).w,d0
                bpl.s   Boss_GustheadCheckHorizontalTargetDistance
                neg.w   d0
Boss_GustheadCheckHorizontalTargetDistance:             ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+8   j  ; was: loc_3F638
                cmpi.w  #$10,d0
                bhi.s   Boss_GustheadSelectHorizontalPatternTarget
                clr.w   $50(a5)
                bra.s   Boss_GustheadMoveTowardHorizontalTarget
; ---------------------------------------------------------------------------
Boss_GustheadSelectHorizontalPatternTarget:             ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+10   j  ; was: loc_3F644
                cmpi.w  #$120,(PlayerXPosition).w
                bcc.s   Boss_GustheadUseLeftPatternTarget
                move.w  #$160,$50(a5)
                bra.s   Boss_GustheadMoveTowardHorizontalTarget
; ---------------------------------------------------------------------------
Boss_GustheadUseLeftPatternTarget:                      ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+1E   j  ; was: loc_3F654
                move.w  #$E0,$50(a5)
Boss_GustheadMoveTowardHorizontalTarget:                ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+16   j  ; was: loc_3F65A
                                        ; Boss_GustheadMoveTowardPatternTarget+26   j
                tst.w   $50(a5)
                beq.s   Boss_GustheadMoveTowardVerticalTarget
                move.w  $50(a5),d0
                sub.w   $10(a5),d0
                bne.s   Boss_GustheadMoveTowardRightTarget
                clr.w   $50(a5)
                bra.s   Boss_GustheadMoveTowardVerticalTarget
; ---------------------------------------------------------------------------
Boss_GustheadMoveTowardRightTarget:                     ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+3C   j  ; was: loc_3F670
                tst.w   d0
                bmi.s   Boss_GustheadMoveTowardLeftTarget
                addi.l  #$8000,$10(a5)
                bra.s   Boss_GustheadMoveTowardVerticalTarget
; ---------------------------------------------------------------------------
Boss_GustheadMoveTowardLeftTarget:                      ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+46   j  ; was: loc_3F67E
                subi.l  #$8000,$10(a5)
Boss_GustheadMoveTowardVerticalTarget:                  ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+32   j  ; was: loc_3F686
                                        ; Boss_GustheadMoveTowardPatternTarget+42   j
                tst.w   $52(a5)
                beq.s   Boss_GustheadUpdateVerticalBounce
                move.w  $52(a5),d0
                sub.w   $14(a5),d0
                bne.s   Boss_GustheadMoveTowardLowerTarget
                clr.w   $52(a5)
                bra.s   Boss_GustheadUpdateVerticalBounce
; ---------------------------------------------------------------------------
Boss_GustheadMoveTowardLowerTarget:                     ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+68   j  ; was: loc_3F69C
                tst.w   d0
                bmi.s   Boss_GustheadMoveTowardUpperTarget
                addi.w  #1,$14(a5)
                bra.s   Boss_GustheadUpdateVerticalBounce
; ---------------------------------------------------------------------------
Boss_GustheadMoveTowardUpperTarget:                     ; CODE XREF: Boss_GustheadMoveTowardPatternTarget+72   j  ; was: loc_3F6A8
                subi.w  #1,$14(a5)
; End of function Boss_GustheadMoveTowardPatternTarget
; Updates boss vertical bounce
Boss_GustheadUpdateVerticalBounce:                      ; CODE XREF: Boss_GustheadUpdateFastIntroFlickerAndStartMotion+50   p  ; was: sub_3F6AE
                                        ; Boss_GustheadRetractSegmentsForBattleState+28   p
                tst.l   $4C(a5)
                beq.s   Boss_GustheadUpdateVerticalBounceReturn
                move.l  $4C(a5),d0
                add.l   d0,$1C(a5)
                move.l  $1C(a5),d0
                bpl.s   Boss_GustheadCompareBounceSpeed
                neg.l   d0
Boss_GustheadCompareBounceSpeed:                        ; CODE XREF: Boss_GustheadUpdateVerticalBounce+12   j  ; was: loc_3F6C4
                cmpi.l  #$10000,d0
                bne.s   Boss_GustheadUpdateVerticalBounceReturn
                neg.l   $4C(a5)
Boss_GustheadUpdateVerticalBounceReturn:                ; CODE XREF: Boss_GustheadUpdateVerticalBounce+4   j  ; was: locret_3F6D0
                                        ; Boss_GustheadUpdateVerticalBounce+1C   j
                rts
; End of function Boss_GustheadUpdateVerticalBounce
; Oscillates the middle-joint angular speed between signed limits
Boss_GustheadOscillateMiddleJointSpeed:                 ; CODE XREF: Boss_GustheadSweepOuterJointState+10   p  ; was: sub_3F6D2
                                        ; Boss_GustheadWaitForMiddleJointZeroState+10   p
                move.l  (SharedScratchLong7).w,d0
                add.l   d0,(SharedScratchLong4).w
                move.l  (SharedScratchLong4).w,d0
                bpl.s   Boss_GustheadCompareMiddleJointSpeed
                neg.l   d0
Boss_GustheadCompareMiddleJointSpeed:                   ; CODE XREF: Boss_GustheadOscillateMiddleJointSpeed+C   j  ; was: loc_3F6E2
                cmpi.l  #$20000,d0
                bne.s   Boss_GustheadOscillateMiddleJointSpeedReturn
                neg.l   (SharedScratchLong7).w
Boss_GustheadOscillateMiddleJointSpeedReturn:           ; CODE XREF: Boss_GustheadOscillateMiddleJointSpeed+16   j  ; was: locret_3F6EE
                rts
; End of function Boss_GustheadOscillateMiddleJointSpeed
; Waits for the middle joint to cross angle zero during the oscillation pattern
Boss_GustheadWaitForMiddleJointZeroState:               ; DATA XREF: ROM:0003F264   o  ; was: sub_3F6F0
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadOscillateMiddleJointSpeed
                bsr.w   Boss_GustheadMoveTowardPatternTarget
                bsr.w   Boss_GustheadSpawnEdgeDebris
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_GustheadWaitForMiddleJointZeroReturn
                addq.w  #2,4(a5)
Boss_GustheadWaitForMiddleJointZeroReturn:              ; CODE XREF: Boss_GustheadWaitForMiddleJointZeroState+20   j  ; was: locret_3F716
                rts
; End of function Boss_GustheadWaitForMiddleJointZeroState
; Counts completed middle-joint oscillation cycles
Boss_GustheadCountMiddleJointCyclesState:               ; DATA XREF: ROM:0003F266   o  ; was: sub_3F718
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadOscillateMiddleJointSpeed
                bsr.w   Boss_GustheadMoveTowardPatternTarget
                tst.w   (SharedScratchLong1).w
                beq.s   Boss_GustheadCountMiddleJointCyclesReturn
                subq.w  #1,$48(a5)
                beq.s   Boss_GustheadFinishMiddleJointCycles
                subq.w  #2,4(a5)
Boss_GustheadCountMiddleJointCyclesReturn:              ; CODE XREF: Boss_GustheadCountMiddleJointCyclesState+1C   j  ; was: locret_3F740
                rts
; ---------------------------------------------------------------------------
Boss_GustheadFinishMiddleJointCycles:                   ; CODE XREF: Boss_GustheadCountMiddleJointCyclesState+22   j  ; was: loc_3F742
                addq.w  #2,4(a5)
                rts
; End of function Boss_GustheadCountMiddleJointCyclesState
; Brakes the outer-joint angular speed to zero
Boss_GustheadBrakeOuterJointState:                      ; DATA XREF: ROM:0003F268   o  ; was: sub_3F748
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadOscillateMiddleJointSpeed
                bsr.w   Boss_GustheadMoveTowardPatternTarget
                move.l  (SharedScratchLong6).w,d0
                sub.l   d0,(SharedScratchLong3).w
                bne.s   Boss_GustheadBrakeOuterJointReturn
                addq.w  #2,4(a5)
                move.b  (RandomNumberState).w,d0
                andi.w  #1,d0
                beq.s   Boss_GustheadBrakeOuterJointReturn
                neg.l   (SharedScratchLong6).w
Boss_GustheadBrakeOuterJointReturn:                     ; CODE XREF: Boss_GustheadBrakeOuterJointState+20   j  ; was: locret_3F77C
                                        ; Boss_GustheadBrakeOuterJointState+2E   j
                rts
; End of function Boss_GustheadBrakeOuterJointState
; Returns from the oscillation sequence to regular pattern selection
Boss_GustheadReturnToPatternChoiceState:                ; DATA XREF: ROM:0003F26A   o  ; was: sub_3F77E
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadMoveTowardPatternTarget
                move.w  #$10,4(a5)
                rts
; End of function Boss_GustheadReturnToPatternChoiceState
; Initializes bouncing movement parameters for Gusthead boss
Boss_GustheadBeginBouncePattern:                        ; CODE XREF: Boss_GustheadChoosePatternState+3C   j  ; was: sub_3F79A
                                        ; DATA XREF: ROM:0003F26C   o
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$4C(a5)
                clr.l   (StageMotionXDelta).w
                andi.l  #$1F80000,(SharedScratchLong0).w
                andi.l  #$1F80000,(SharedScratchLong1).w
                andi.l  #$1F80000,(SharedScratchLong2).w
                move.l  #$80000,(SharedScratchLong3).w
                move.l  #$80000,(SharedScratchLong4).w
                move.l  #$80000,(SharedScratchLong5).w
                addq.w  #2,4(a5)
; Update tentacles and scroll during bounce initialization
Boss_GustheadAlignJointsForBounceState:                 ; DATA XREF: ROM:0003F26E   o  ; was: loc_3F7E2
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                cmpi.w  #$40,(SharedScratchLong0).w     ; '@'
                bne.s   Boss_GustheadCheckBounceMiddleJoint
                clr.l   (SharedScratchLong3).w
Boss_GustheadCheckBounceMiddleJoint:                    ; CODE XREF: Boss_GustheadBeginBouncePattern+62   j  ; was: loc_3F802
                cmpi.w  #0,(SharedScratchLong1).w
                bne.s   Boss_GustheadCheckBounceInnerJoint
                clr.l   (SharedScratchLong4).w
Boss_GustheadCheckBounceInnerJoint:                     ; CODE XREF: Boss_GustheadBeginBouncePattern+6E   j  ; was: loc_3F80E
                cmpi.w  #$180,(SharedScratchLong2).w
                bne.s   Boss_GustheadAlignJointsForBounceReturn
                clr.l   (SharedScratchLong5).w
                tst.l   (SharedScratchLong4).w
                bne.s   Boss_GustheadAlignJointsForBounceReturn
                tst.l   (SharedScratchLong3).w
                bne.s   Boss_GustheadAlignJointsForBounceReturn
                addq.w  #2,4(a5)
                clr.l   $1C(a5)
                clr.l   $4C(a5)
                move.l  #0,(SharedScratchLong3).w
                move.l  #$100000,(SharedScratchLong4).w
                move.l  #$40000,(SharedScratchLong5).w
                clr.w   $56(a5)
                bsr.w   Boss_GustheadSelectNextBounceTurnAngle
Boss_GustheadAlignJointsForBounceReturn:                ; CODE XREF: Boss_GustheadBeginBouncePattern+7A   j  ; was: locret_3F852
                                        ; Boss_GustheadBeginBouncePattern+84   j
                rts
; End of function Boss_GustheadBeginBouncePattern
; Main logic for Gusthead boss bouncing attack pattern
Boss_GustheadBouncePatternState:                        ; DATA XREF: ROM:0003F270   o  ; was: sub_3F854
                ori.b   #3,$4B(a5)
                bsr.w   Boss_GustheadSetVelocityFromInnerJointAngle
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                cmpi.w  #$100,(SharedScratchLong2).w
                bne.s   Boss_GustheadCheckBounceTurnAngle
                cmpi.w  #$120,$14(a5)
                blt.s   Boss_GustheadCheckBounceTurnAngle
                bsr.w   Boss_GustheadSpawnFourWayDebris
                bsr.w   Boss_GustheadSpawnFourWayArcVolley
Boss_GustheadCheckBounceTurnAngle:                      ; CODE XREF: Boss_GustheadBouncePatternState+20   j  ; was: loc_3F886
                                        ; Boss_GustheadBouncePatternState+28   j
                move.w  $54(a5),d0
                cmp.w   (SharedScratchLong2).w,d0
                bne.s   Boss_GustheadBouncePatternReturn
                neg.l   (SharedScratchLong5).w
                bsr.s   Boss_GustheadSelectNextBounceTurnAngle
Boss_GustheadBouncePatternReturn:                       ; CODE XREF: Boss_GustheadBouncePatternState+3A   j  ; was: locret_3F896
                rts
; End of function Boss_GustheadBouncePatternState
; Updates target angle sequence for Gusthead boss movement
Boss_GustheadSelectNextBounceTurnAngle:                 ; CODE XREF: Boss_GustheadBeginBouncePattern+B4   p  ; was: sub_3F898
                                        ; Boss_GustheadBouncePatternState+40   p
                move.w  $56(a5),d0
                move.w  Boss_GustheadBounceTurnAngles(pc,d0.w),$54(a5)
                addq.w  #2,$56(a5)
                cmpi.w  #6,$56(a5)
                bls.s   Boss_GustheadSelectNextBounceTurnAngleReturn
                addq.w  #2,4(a5)
Boss_GustheadSelectNextBounceTurnAngleReturn:           ; CODE XREF: Boss_GustheadSelectNextBounceTurnAngle+14   j  ; was: locret_3F8B2
                rts
; End of function Boss_GustheadSelectNextBounceTurnAngle
; ---------------------------------------------------------------------------
Boss_GustheadBounceTurnAngles:  dc.w    $180, $80, $80, $180  ; was: word_3F8B4
                                        ; DATA XREF: Boss_GustheadSelectNextBounceTurnAngle+4   r

; Fires radial projectile pattern from Gusthead boss
Boss_GustheadSpawnFourWayArcVolley:                     ; CODE XREF: Boss_GustheadBouncePatternState+2E   p  ; was: sub_3F8BC
                move.w  #3,d7
                move.w  #$150,d6
Boss_GustheadFourWayArcVolleyLoop:                      ; CODE XREF: Boss_GustheadSpawnFourWayArcVolley+66   j  ; was: loc_3F8C4
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_GustheadFourWayArcVolleyReturn
                move.w  #$10,(a0)
                jsr     (Projectile_InitType88).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                addi.w  #$10,$14(a0)
                move.l  #SharedProjectileDuration4Animation,8(a0)
                move.w  #$4000,$E(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                lea     (Math_SineTable).l,a1
                move.w  (a1,d6.w),d0
                move.w  -$80(a1,d6.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #3,d0
                asl.l   #4,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                addi.w  #$20,d6                         ; ' '
                dbf     d7,Boss_GustheadFourWayArcVolleyLoop
                move.b  #$4C,d0                         ; 'L'
                jsr     (Sound_QueueSFXRequest).l
Boss_GustheadFourWayArcVolleyReturn:                    ; CODE XREF: Boss_GustheadSpawnFourWayArcVolley+E   j  ; was: locret_3F930
                rts
; End of function Boss_GustheadSpawnFourWayArcVolley
; Selects the outer-joint angle for root X/Y velocity calculation
Boss_GustheadSetVelocityFromOuterJointAngle:            ; was: sub_3F932
                move.w  (SharedScratchLong0).w,d0
                bra.s   Boss_GustheadSetVelocityFromSelectedJointAngle
; End of function Boss_GustheadSetVelocityFromOuterJointAngle
; Selects the middle-joint angle for root X/Y velocity calculation
Boss_GustheadSetVelocityFromMiddleJointAngle:           ; was: sub_3F938
                move.w  (SharedScratchLong1).w,d0
                bra.s   Boss_GustheadSetVelocityFromSelectedJointAngle
; End of function Boss_GustheadSetVelocityFromMiddleJointAngle
; Selects the inner-joint angle and calculates root X/Y velocity components
Boss_GustheadSetVelocityFromInnerJointAngle:            ; CODE XREF: Boss_GustheadBouncePatternState+6   p  ; was: sub_3F93E
                move.w  (SharedScratchLong2).w,d0
Boss_GustheadSetVelocityFromSelectedJointAngle:         ; CODE XREF: Boss_GustheadSetVelocityFromOuterJointAngle+4   j  ; was: loc_3F942
                                        ; Boss_GustheadSetVelocityFromMiddleJointAngle+4   j
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a1
                moveq   #0,d1
                btst    #0,$4B(a5)
                beq.s   Boss_GustheadCalculateVerticalVelocityFromAngle
                move.w  (a1,d0.w),d1
                ext.l   d1
                add.l   d1,d1
Boss_GustheadCalculateVerticalVelocityFromAngle:        ; CODE XREF: Boss_GustheadSetVelocityFromInnerJointAngle+16   j  ; was: loc_3F95E
                moveq   #0,d2
                btst    #1,$4B(a5)
                beq.s   Boss_GustheadStoreAngleDerivedVelocities
                move.w  -$80(a1,d0.w),d2
                ext.l   d2
                asl.l   #4,d2
Boss_GustheadStoreAngleDerivedVelocities:               ; CODE XREF: Boss_GustheadSetVelocityFromInnerJointAngle+28   j  ; was: loc_3F970
                move.l  d1,$18(a5)
                move.l  d2,$1C(a5)
                rts
; End of function Boss_GustheadSetVelocityFromInnerJointAngle
; Initializes falling movement parameters for Gusthead boss
Boss_GustheadBeginPatternDescentState:                  ; DATA XREF: ROM:0003F272   o  ; was: sub_3F97A
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                cmpi.w  #$F0,$14(a5)
                bcs.s   Boss_GustheadBeginPatternDescentReturn
                move.l  #$F00000,$14(a5)
                clr.l   $18(a5)
                move.l  #$10000,$1C(a5)
                move.l  #$FFFFE000,$4C(a5)
                andi.l  #$1F80000,(SharedScratchLong0).w
                andi.l  #$1F80000,(SharedScratchLong1).w
                andi.l  #$1F80000,(SharedScratchLong2).w
                move.w  #8,(SharedScratchLong3).w
                move.w  #8,(SharedScratchLong4).w
                move.w  #8,(SharedScratchLong5).w
                addq.w  #2,4(a5)
Boss_GustheadBeginPatternDescentReturn:                 ; CODE XREF: Boss_GustheadBeginPatternDescentState+16   j  ; was: locret_3F9DC
                rts
; End of function Boss_GustheadBeginPatternDescentState
; Handles Gusthead boss falling and bouncing behavior
Boss_GustheadAlignJointsAfterDescentState:              ; DATA XREF: ROM:0003F274   o  ; was: sub_3F9DE
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                cmpi.w  #$40,(SharedScratchLong0).w     ; '@'
                bne.s   Boss_GustheadCheckDescentMiddleJoint
                clr.l   (SharedScratchLong3).w
Boss_GustheadCheckDescentMiddleJoint:                   ; CODE XREF: Boss_GustheadAlignJointsAfterDescentState+1A   j  ; was: loc_3F9FE
                cmpi.w  #$80,(SharedScratchLong1).w
                bne.s   Boss_GustheadCheckDescentInnerJoint
                clr.l   (SharedScratchLong4).w
Boss_GustheadCheckDescentInnerJoint:                    ; CODE XREF: Boss_GustheadAlignJointsAfterDescentState+26   j  ; was: loc_3FA0A
                cmpi.w  #$180,(SharedScratchLong2).w
                bne.s   Boss_GustheadAlignJointsAfterDescentReturn
                clr.w   (SharedScratchLong5).w
                tst.l   (SharedScratchLong3).w
                bne.s   Boss_GustheadAlignJointsAfterDescentReturn
                tst.l   (SharedScratchLong4).w
                bne.s   Boss_GustheadAlignJointsAfterDescentReturn
                move.w  #$10,4(a5)
Boss_GustheadAlignJointsAfterDescentReturn:             ; CODE XREF: Boss_GustheadAlignJointsAfterDescentState+32   j  ; was: locret_3FA28
                                        ; Boss_GustheadAlignJointsAfterDescentState+3C   j
                rts
; End of function Boss_GustheadAlignJointsAfterDescentState
; Begins the fragment-cluster pattern with a vertical bounce
Boss_GustheadBeginFragmentPattern:                      ; CODE XREF: Boss_GustheadChoosePatternState+4C   j  ; was: sub_3FA2A
                                        ; DATA XREF: ROM:0003F276   o
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$4C(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
; Accelerates the outer-joint spin before the fragment-cluster pattern
Boss_GustheadAccelerateFragmentPatternSpinState:        ; DATA XREF: ROM:0003F278   o  ; was: loc_3FA42
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                eori.w  #$8000,2(a5)
                addi.l  #$2000,(SharedScratchLong3).w
                cmpi.l  #$100000,(SharedScratchLong3).w
                bne.s   Boss_GustheadAccelerateFragmentPatternSpinReturn
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
                bra.s   Boss_GustheadSpawnFragmentCluster
; ---------------------------------------------------------------------------
Boss_GustheadAccelerateFragmentPatternSpinReturn:       ; CODE XREF: Boss_GustheadBeginFragmentPattern+42   j  ; was: locret_3FA7A
                rts
; End of function Boss_GustheadBeginFragmentPattern
; Fires Gusthead's fragment cluster based on its horizontal position
