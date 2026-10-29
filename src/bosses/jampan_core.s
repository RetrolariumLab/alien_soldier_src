; Jampan main controller, encounter setup, opening sequence, and attack selection

; Updates the Jampan controller and publishes its screen-relative position
Boss_JampanMain:                                        ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4912E
                bsr.w   Boss_JampanUpdateAndDispatch
                bsr.w   Boss_JampanPublishStageCoordinates
                rts
; End of function Boss_JampanMain
; Handles defeat entry and shared motion before dispatching the active state
Boss_JampanUpdateAndDispatch:                           ; CODE XREF: Boss_JampanMain   p  ; was: sub_49138
                tst.w   4(a5)
                beq.w   Boss_JampanDispatchState
                btst    #1,$4C(a5)
                bne.s   Boss_JampanCheckDefeatTrigger
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_JampanCheckDefeatTrigger
                move.w  $4E(a5),d0
                beq.s   Boss_JampanCheckDefeatTrigger
                sub.w   d0,(BossCombatCounter).w
Boss_JampanCheckDefeatTrigger:                          ; CODE XREF: Boss_JampanUpdateAndDispatch+E   j
                                        ; Boss_JampanUpdateAndDispatch+18   j
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_JampanUpdateScreenPositionAndMotion
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_JampanUpdateScreenPositionAndMotion
                tst.w   (BossHealth).w
                bne.s   Boss_JampanUpdateScreenPositionAndMotion
                move.b  #2,(BossColorEffectFlags).w
                bset    #0,$4C(a5)
                clr.l   (StageMotionXDelta).w
                move.w  #$52,4(a5)                      ; 'R'
                bset    #0,(StageTimerPauseFlag).w
Boss_JampanUpdateScreenPositionAndMotion:               ; CODE XREF: Boss_JampanUpdateAndDispatch+2A   j
                                        ; Boss_JampanUpdateAndDispatch+32   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$58(a5)
                btst    #2,$4C(a5)
                beq.s   Boss_JampanDispatchState
                tst.l   $54(a5)
                beq.s   Boss_JampanDispatchState
                move.l  $54(a5),d0
                add.l   d0,$1C(a5)
                move.l  $1C(a5),d0
                bpl.s   Boss_JampanUseAbsoluteVerticalVelocity
                neg.l   d0
Boss_JampanUseAbsoluteVerticalVelocity:                 ; CODE XREF: Boss_JampanUpdateAndDispatch+82   j
                cmpi.l  #$10000,d0
                bne.s   Boss_JampanDispatchState
                neg.l   $54(a5)
Boss_JampanDispatchState:                               ; CODE XREF: Boss_JampanUpdateAndDispatch+4   j
                                        ; Boss_JampanUpdateAndDispatch+6E   j
                move.w  4(a5),d0
                lea     Boss_JampanStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanUpdateAndDispatch
; ---------------------------------------------------------------------------
Boss_JampanStateHandlers:   dc.w    Boss_JampanWaitForEncounterActivationState-*  ; DATA XREF: Boss_JampanUpdateAndDispatch+96   o
                dc.w    Boss_JampanInitializeEncounterState-*
                dc.w    Boss_JampanWaitForOpeningDelayState-*
                dc.w    Boss_JampanOpeningFallState-*
                dc.w    Boss_JampanOpeningBounceApexState-*
                dc.w    Boss_JampanNormalizeOpeningAnglesState-*
                dc.w    Boss_JampanWaitForOpeningSidePartState-*
                dc.w    Boss_JampanNormalizeOpeningOffsetState-*
                dc.w    Boss_JampanWaitForOpeningMessageCompletionState-*
                dc.w    Boss_JampanWaitForOpeningSidePartsState-*
                dc.w    Boss_JampanSelectAttackState-*
                dc.w    Boss_JampanDampOrbitOffsetsState-*
                dc.w    Boss_JampanBounceUntilSettledState-*
                dc.w    Boss_JampanMoveToScreenThresholdState-*
                dc.w    Boss_JampanWaitForBossCounterMaxFlagState-*
                dc.w    Boss_JampanBalanceHorizontalAngleState-*
                dc.w    Boss_JampanRiseToAttackHeightState-*
                dc.w    Boss_JampanInitializeOffsetAttackState-*
                dc.w    Boss_JampanChooseOffsetAttackDirectionState-*
                dc.w    Boss_JampanSpawnOffsetAttackObjectState-*
                dc.w    Boss_JampanMoveOffsetAttackAcrossScreenState-*
                dc.w    Boss_JampanNoOpState2A-*
                dc.w    Boss_JampanNoOpState2C-*
                dc.w    Boss_JampanNormalizeShieldCycleVerticalOffsetState-*
                dc.w    Boss_JampanShieldCycleDelayState-*
                dc.w    Boss_JampanExpandShieldRadiusState-*
                dc.w    Boss_JampanShieldCyclePauseState-*
                dc.w    Boss_JampanRotateShieldPatternForwardState-*
                dc.w    Boss_JampanRotateShieldPatternBackwardState-*
                dc.w    Boss_JampanCollapseShieldRadiusState-*
                dc.w    Boss_JampanShieldCycleRecoveryDelayState-*
                dc.w    Boss_JampanInitializeAlternatePatternState-*
                dc.w    Boss_JampanWaitForAlternatePatternAngleState-*
                dc.w    Boss_JampanExpandAlternatePatternState-*
                dc.w    Boss_JampanBeginAlternatePatternHoldState-*
                dc.w    Boss_JampanTrackPlayerDuringAlternatePatternState-*
                dc.w    Boss_JampanCenterAlternatePatternVerticallyState-*
                dc.w    Boss_JampanWaitForAlternatePrimaryAngleState-*
                dc.w    Boss_JampanCollapseAlternatePatternState-*
                dc.w    Boss_JampanRestoreAttackSelectionAngleState-*
                dc.w    Boss_JampanNoOpState50-*
                dc.w    Boss_JampanBeginDefeatState-*
                dc.w    Boss_JampanDefeatFallState-*
                dc.w    Boss_JampanDefeatExplosionHoldState-*
                dc.w    Boss_JampanWaitForDefeatShieldYBelow60State-*
                dc.w    Boss_JampanFadeDefeatPaletteOutState-*
                dc.w    Boss_JampanResetAfterDefeatFadeState-*
                dc.w    Boss_JampanFadeDefeatPaletteInState-*
                dc.w    Boss_JampanPreparePostDefeatControllerState-*
                dc.w    Boss_JampanReinitializePostDefeatObjectsState-*
                dc.w    Boss_JampanInitializePostDefeatMovementState-*
                dc.w    Boss_JampanUpdatePostDefeatMovementState-*
                dc.w    Boss_JampanPostDefeatNoOpState68-*

; Waits for the stage controller to activate the encounter
Boss_JampanWaitForEncounterActivationState:             ; DATA XREF: ROM:Boss_JampanStateHandlers   o  ; was: sub_49240
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_JampanWaitForEncounterActivationReturn
                addq.w  #2,4(a5)
                move.w  #$218,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; ---------------------------------------------------------------------------
Boss_JampanWaitForEncounterActivationReturn:            ; CODE XREF: Boss_JampanWaitForEncounterActivationState+4   j
                rts
; End of function Boss_JampanWaitForEncounterActivationState
; Loads encounter resources and initializes the controller and linked objects
Boss_JampanInitializeEncounterState:                    ; DATA XREF: ROM:000491D8   o  ; was: sub_49258
                move.b  #1,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
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
                clr.w   (SharedScratchLong9+2).w
                clr.w   (SharedScratchLong10).w
                clr.w   (SharedScratchLong10+2).w
                clr.w   (SharedScratchLong11).w
                bsr.w   Boss_JampanLoadEncounterTiles
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #$1E8,$10(a5)
                move.w  #$F0,$14(a5)
                move.w  #$100,(SharedScratchLong1).w
                move.w  #$100,(SharedScratchLong2).w
                move.b  #$40,$20(a5)                    ; '@'
                move.w  #$D00,2(a5)
                move.b  #$10,$21(a5)
                move.b  #$80,$23(a5)
                move.l  #$F010F010,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$20,$24(a5)                    ; ' '
Boss_JampanInitializeLinkedObjectGraph:                 ; CODE XREF: Boss_JampanReinitializePostDefeatObjectsState+12   p
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                lea     $60(a0),a0
                move.w  #$224,(a0)
                move.w  #$4D00,2(a0)
                move.l  #Boss_JampanLinkedPartMappingB,8(a0)
                move.w  #$6B00,$E(a0)
                move.b  #4,$20(a0)
                move.w  #$C8C0,$50(a0)
                lea     $60(a0),a0
                move.w  #$220,(a0)
                move.w  #$CD00,2(a0)
                move.l  #Boss_JampanLinkedPartMappingA,8(a0)
                move.w  #$6B00,$E(a0)
                move.b  #4,$20(a0)
                move.w  #$C8C0,$50(a0)
                lea     $60(a0),a0
                move.w  #$224,(a0)
                move.w  #$4D00,2(a0)
                move.l  #Boss_JampanLinkedPartMappingB,8(a0)
                move.w  #$6B00,$E(a0)
                move.b  #4,$20(a0)
                move.w  #$C920,$50(a0)
                lea     $60(a0),a0
                move.w  #$220,(a0)
                move.w  #$CD00,2(a0)
                move.l  #Boss_JampanLinkedPartMappingA,8(a0)
                move.w  #$6B00,$E(a0)
                move.b  #4,$20(a0)
                move.w  #$C920,$50(a0)
                lea     $60(a0),a0
                move.w  #$228,(a0)
                move.w  #$100,2(a0)
                lea     $60(a0),a0
                move.w  #$F,d7
                clr.w   d1
Boss_JampanInitializeOrbitingPartLoop:                  ; CODE XREF: Boss_JampanInitializeEncounterState+1B8   j
                move.w  #$CD00,2(a0)
                move.w  #$6B00,$E(a0)
                move.w  d1,d0
                add.w   d0,d0
                lea     Boss_JampanOrbitingPartTypes(pc),a1
                nop
                move.w  (a1,d0.w),(a0)
                lea     Boss_JampanOrbitingPartRadii(pc),a1
                nop
                move.w  (a1,d0.w),$48(a0)
                lea     Boss_JampanOrbitingPartSpriteAttributes(pc),a1
                nop
                move.w  (a1,d0.w),d2
                or.w    d2,$E(a0)
                lea     Boss_JampanOrbitingPartPrimaryAngles(pc),a1
                nop
                move.w  (a1,d0.w),$4A(a0)
                lea     Boss_JampanOrbitingPartSecondaryAngles(pc),a1
                nop
                move.w  (a1,d0.w),$4C(a0)
                add.w   d0,d0
                lea     Boss_JampanOrbitingPartMappingPointers(pc),a1
                nop
                move.l  (a1,d0.w),8(a0)
                addq.w  #1,d1
                lea     $60(a0),a0
                dbf     d7,Boss_JampanInitializeOrbitingPartLoop
                move.w  #5,d7
                clr.w   d1
Boss_JampanInitializeShieldSlotLoop:                    ; CODE XREF: Boss_JampanInitializeEncounterState+1DE   j
                move.w  #$10,(a0)
                move.w  #$4D00,2(a0)
                move.w  #$6B00,$E(a0)
                move.l  #Boss_JampanShieldAndOrbitingPartMapping,8(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JampanInitializeShieldSlotLoop
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                rts
; End of function Boss_JampanInitializeEncounterState
; Loads the compressed tile block used by the encounter
Boss_JampanLoadEncounterTiles:                          ; CODE XREF: Boss_JampanInitializeEncounterState+4C   p  ; was: sub_49440
                lea     Boss_JampanEncounterTileLoadDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                rts
; End of function Boss_JampanLoadEncounterTiles
; ---------------------------------------------------------------------------
Boss_JampanEncounterTileLoadDescriptor: dc.w    $6100, $2000, $202, $7879, $7A7C, $7D7E, $8081, 0
                                        ; DATA XREF: Boss_JampanLoadEncounterTiles   o
Boss_JampanOrbitingPartTypes:   dc.w    $234, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10, $10
                                        ; DATA XREF: Boss_JampanInitializeEncounterState+168   o
Boss_JampanOrbitingPartSpriteAttributes:    dc.w    0, 0, 0, $1000, $1000, $1000, $1000, $1000, $1000, $1000, 0, 0, 0, 0, 0, 0
                                        ; DATA XREF: Boss_JampanInitializeEncounterState+17E   o
Boss_JampanOrbitingPartRadii:   dc.w    $24, $30, $30, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
                                        ; DATA XREF: Boss_JampanInitializeEncounterState+172   o
Boss_JampanOrbitingPartPrimaryAngles:   dc.w    $80, $A8, $58, $20, $40, $60, $80, $A0, $C0, $E0, $30, $50, $70, $90, $B0, $D0
                                        ; DATA XREF: Boss_JampanInitializeEncounterState+18C   o
Boss_JampanOrbitingPartSecondaryAngles: dc.w    $FFE0, $FF80, $FF80, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40
                                        ; DATA XREF: Boss_JampanInitializeEncounterState+198   o
Boss_JampanOrbitingPartMappingPointers: dc.l    Boss_JampanShieldAndOrbitingPartMapping  ; DATA XREF: Boss_JampanInitializeEncounterState+1A6   o
                dc.l    Boss_JampanOrbitingPartMappingA
                dc.l    Boss_JampanOrbitingPartMappingA
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB
                dc.l    Boss_JampanOrbitingPartMappingB

; Waits before activating the opening-sequence linked parts
Boss_JampanWaitForOpeningDelayState:                    ; DATA XREF: ROM:000491DA   o  ; was: sub_4953E
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanWaitForOpeningDelayReturn
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                move.w  #1,(TertiaryEntityWork52).w
                move.w  #1,(FifthEntityWork52).w
                move.w  #4,(SharedScratchLong4).w
                move.w  #4,(SharedScratchLong5).w
                move.w  #3,$48(a5)
                addq.w  #2,4(a5)
Boss_JampanWaitForOpeningDelayReturn:                   ; CODE XREF: Boss_JampanWaitForOpeningDelayState+8   j
                rts
; End of function Boss_JampanWaitForOpeningDelayState
; Moves left under gravity until reaching the opening-sequence floor
Boss_JampanOpeningFallState:                            ; DATA XREF: ROM:000491DC   o  ; was: sub_49570
                addi.l  #$2000,$1C(a5)
                addi.l  #-$10000,$10(a5)
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                cmpi.w  #$110,$14(a5)
                bcs.s   Boss_JampanOpeningFallReturn
                move.w  #$110,$14(a5)
                andi.l  #$FFFF0000,$14(a5)
                move.l  $1C(a5),d0
                neg.l   d0
                addi.l  #$2000,d0
                move.l  d0,$1C(a5)
                addq.w  #2,4(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.w  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_JampanOpeningFallReturn:                           ; CODE XREF: Boss_JampanOpeningFallState+1A   j
                rts
; End of function Boss_JampanOpeningFallState
; Continues the opening bounces and detects each zero-velocity apex
Boss_JampanOpeningBounceApexState:                      ; DATA XREF: ROM:000491DE   o  ; was: sub_495C6
                addi.l  #$2000,$1C(a5)
                addi.l  #-$10000,$10(a5)
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.l   $1C(a5)
                bne.s   Boss_JampanOpeningBounceApexReturn
                subq.w  #1,$48(a5)
                beq.s   Boss_JampanFinishOpeningBounces
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishOpeningBounces:                        ; CODE XREF: Boss_JampanOpeningBounceApexState+1E   j
                bset    #2,$4C(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$54(a5)
                clr.w   (SharedScratchLong4).w
                clr.w   (SharedScratchLong5).w
                addq.w  #2,4(a5)
Boss_JampanOpeningBounceApexReturn:                     ; CODE XREF: Boss_JampanOpeningBounceApexState+18   j
                rts
; End of function Boss_JampanOpeningBounceApexState
; Converges two opening-sequence angle accumulators on $100
Boss_JampanNormalizeOpeningAnglesState:                 ; DATA XREF: ROM:000491E0   o  ; was: sub_49610
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                cmpi.w  #$100,(SharedScratchLong1).w
                beq.s   Boss_JampanFinishOpeningAngleNormalization
                cmpi.w  #$100,(SharedScratchLong1).w
                bcs.s   Boss_JampanIncreaseOpeningAngles
                subq.w  #4,(SharedScratchLong1).w
                subq.w  #4,(SharedScratchLong2).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanIncreaseOpeningAngles:                       ; CODE XREF: Boss_JampanNormalizeOpeningAnglesState+12   j
                addq.w  #4,(SharedScratchLong1).w
                addq.w  #4,(SharedScratchLong2).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishOpeningAngleNormalization:             ; CODE XREF: Boss_JampanNormalizeOpeningAnglesState+A   j
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,(QuaternaryEntityWork52).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanNormalizeOpeningAnglesState
; Waits for the first linked side part to complete its opening state
Boss_JampanWaitForOpeningSidePartState:                 ; DATA XREF: ROM:000491E2   o  ; was: sub_4964A
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (SecondaryEntityWork52).w
                bne.s   Boss_JampanWaitForOpeningSidePartReturn
                clr.w   (TertiaryEntityWork52).w
                clr.w   (FifthEntityWork52).w
                addq.w  #2,4(a5)
Boss_JampanWaitForOpeningSidePartReturn:                ; CODE XREF: Boss_JampanWaitForOpeningSidePartState+C   j
                rts
; End of function Boss_JampanWaitForOpeningSidePartState
; Converges the signed opening offset on zero
Boss_JampanNormalizeOpeningOffsetState:                 ; DATA XREF: ROM:000491E4   o  ; was: sub_49666
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                move.w  (SharedScratchLong9+2).w,d0
                beq.s   Boss_JampanFinishOpeningOffsetNormalization
                tst.w   d0
                bmi.s   Boss_JampanIncreaseOpeningOffset
                subq.w  #1,(SharedScratchLong9+2).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanIncreaseOpeningOffset:                       ; CODE XREF: Boss_JampanNormalizeOpeningOffsetState+10   j
                addq.w  #1,(SharedScratchLong9+2).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishOpeningOffsetNormalization:            ; CODE XREF: Boss_JampanNormalizeOpeningOffsetState+C   j
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,(QuaternaryEntityWork52).w
                addq.w  #2,4(a5)
                move.w  #3,d0
                jsr     (BossMessage_Start).l
                move.b  #$8A,d0
                jsr     (Sound_QueueBGMOrStop).l
                rts
; End of function Boss_JampanNormalizeOpeningOffsetState
; Waits for the opening message sequence to complete
Boss_JampanWaitForOpeningMessageCompletionState:        ; DATA XREF: ROM:000491E6   o  ; was: sub_496AA
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (MessageSequenceState).w
                bne.s   Boss_JampanWaitForOpeningMessageCompletionReturn
                clr.b   (BossColorEffectFlags).w
                move.w  #1,(TertiaryEntityWork52).w
                move.w  #1,(FifthEntityWork52).w
                addq.w  #2,4(a5)
Boss_JampanWaitForOpeningMessageCompletionReturn:       ; CODE XREF: Boss_JampanWaitForOpeningMessageCompletionState+C   j
                rts
; End of function Boss_JampanWaitForOpeningMessageCompletionState
; Waits for the linked side parts before enabling the next pair
Boss_JampanWaitForOpeningSidePartsState:                ; DATA XREF: ROM:000491E8   o  ; was: sub_496CE
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (SecondaryEntityWork52).w
                bne.s   Boss_JampanWaitForOpeningSidePartsReturn
                move.w  #1,(SixthEntityWork52).w
                move.w  #1,(SeventhEntityWork52).w
                addq.w  #2,4(a5)
Boss_JampanWaitForOpeningSidePartsReturn:               ; CODE XREF: Boss_JampanWaitForOpeningSidePartsState+C   j
                rts
; End of function Boss_JampanWaitForOpeningSidePartsState
; Periodically chooses a live attack according to targets and random input
Boss_JampanSelectAttackState:                           ; DATA XREF: ROM:000491EA   o  ; was: sub_496EE
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanAttackSelectionNoOpHook
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (BossCombatCounter).w
                ble.w   Boss_JampanSelectNoTargetsRecovery
                move.w  (FrameCounter).w,d0
                tst.w   (DifficultyMode).w
                bne.s   Boss_JampanUseFastAttackSelectionPeriod
                andi.w  #$3F,d0                         ; '?'
                bne.w   Boss_JampanSelectAttackReturn
                bra.s   Boss_JampanChooseRandomAttack
; ---------------------------------------------------------------------------
Boss_JampanUseFastAttackSelectionPeriod:                ; CODE XREF: Boss_JampanSelectAttackState+24   j
                andi.w  #$1F,d0
                bne.w   Boss_JampanSelectAttackReturn
Boss_JampanChooseRandomAttack:                          ; CODE XREF: Boss_JampanSelectAttackState+2E   j
                move.b  (RandomNumberState).w,d0
                andi.b  #7,d0
                beq.s   Boss_JampanSelectShieldCycle
                cmpi.w  #1,d0
                beq.s   Boss_JampanSelectOffsetAttack
                cmpi.w  #2,d0
                beq.s   Boss_JampanSelectAlternateAttack
                bset    #1,$4C(a5)
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,(QuaternaryEntityWork52).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanSelectOffsetAttack:                          ; CODE XREF: Boss_JampanSelectAttackState+46   j
                move.w  #2,$4E(a5)
                move.w  #$22,4(a5)                      ; '"'
                rts
; ---------------------------------------------------------------------------
Boss_JampanSelectShieldCycle:                           ; CODE XREF: Boss_JampanSelectAttackState+40   j
                clr.w   (SeventhEntityWork52).w
                move.w  #$FFFF,(SecondaryEntityWork52).w
                move.w  #$FFFF,(QuaternaryEntityWork52).w
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #8,$4E(a5)
                move.w  #$2E,4(a5)                      ; '.'
                rts
; ---------------------------------------------------------------------------
Boss_JampanSelectAlternateAttack:                       ; CODE XREF: Boss_JampanSelectAttackState+4C   j
                move.w  #$A,$4E(a5)
                move.w  #$3E,4(a5)                      ; '>'
                rts
; ---------------------------------------------------------------------------
Boss_JampanSelectNoTargetsRecovery:                     ; CODE XREF: Boss_JampanSelectAttackState+18   j
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,(QuaternaryEntityWork52).w
                bset    #1,$4C(a5)
                move.w  #$16,4(a5)
Boss_JampanSelectAttackReturn:                          ; CODE XREF: Boss_JampanSelectAttackState+2A   j
                                        ; Boss_JampanSelectAttackState+34   j
                rts
; End of function Boss_JampanSelectAttackState
; Converges both signed orbit offsets on zero before recovery movement
Boss_JampanDampOrbitOffsetsState:                       ; DATA XREF: ROM:000491EC   o  ; was: sub_497AA
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (SharedScratchLong9+2).w
                beq.s   Boss_JampanUpdateSecondaryOrbitOffset
                tst.w   (SharedScratchLong9+2).w
                bpl.s   Boss_JampanDecreasePrimaryOrbitOffset
                addq.w  #1,(SharedScratchLong9+2).w
                bra.s   Boss_JampanUpdateSecondaryOrbitOffset
; ---------------------------------------------------------------------------
Boss_JampanDecreasePrimaryOrbitOffset:                  ; CODE XREF: Boss_JampanDampOrbitOffsetsState+E   j
                subq.w  #1,(SharedScratchLong9+2).w
Boss_JampanUpdateSecondaryOrbitOffset:                  ; CODE XREF: Boss_JampanDampOrbitOffsetsState+8   j
                                        ; Boss_JampanDampOrbitOffsetsState+14   j
                tst.w   (SharedScratchLong10).w
                beq.s   Boss_JampanCheckOrbitOffsetsSettled
                tst.w   (SharedScratchLong10).w
                bpl.s   Boss_JampanDecreaseSecondaryOrbitOffset
                addq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanDecreaseSecondaryOrbitOffset:                ; CODE XREF: Boss_JampanDampOrbitOffsetsState+24   j
                subq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanCheckOrbitOffsetsSettled:                    ; CODE XREF: Boss_JampanDampOrbitOffsetsState+1E   j
                tst.w   (SharedScratchLong9+2).w
                bne.s   Boss_JampanDampOrbitOffsetsReturn
                bclr    #2,$4C(a5)
                clr.l   $54(a5)
                move.w  #1,$1C(a5)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
Boss_JampanDampOrbitOffsetsReturn:                      ; CODE XREF: Boss_JampanDampOrbitOffsetsState+36   j
                rts
; End of function Boss_JampanDampOrbitOffsetsState
; Repeats damped floor bounces until the recovery counter expires
Boss_JampanBounceUntilSettledState:                     ; DATA XREF: ROM:000491EE   o  ; was: sub_497FE
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                addi.l  #$2000,$1C(a5)
                cmpi.w  #$110,$14(a5)
                bcs.s   Boss_JampanBounceUntilSettledReturn
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.w  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$110,$14(a5)
                move.l  $1C(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                tst.w   $1C(a5)
                beq.s   Boss_JampanFinishRecoveryBounce
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanBounceUntilSettledReturn
Boss_JampanFinishRecoveryBounce:                        ; CODE XREF: Boss_JampanBounceUntilSettledState+40   j
                clr.l   $1C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #$FFFE,(SecondaryEntityWork52).w
                move.w  #$FFFE,(QuaternaryEntityWork52).w
                addq.w  #2,4(a5)
Boss_JampanBounceUntilSettledReturn:                    ; CODE XREF: Boss_JampanBounceUntilSettledState+12   j
                                        ; Boss_JampanBounceUntilSettledState+46   j
                rts
; End of function Boss_JampanBounceUntilSettledState
; Moves horizontally toward screen-coordinate threshold $13A0
Boss_JampanMoveToScreenThresholdState:                  ; DATA XREF: ROM:000491F0   o  ; was: sub_49862
                cmpi.w  #$13A0,$58(a5)
                bcs.s   Boss_JampanMoveRightTowardScreenThreshold
                subq.w  #2,(SharedScratchLong2).w
                subi.l  #$8000,$10(a5)
                bra.s   Boss_JampanUpdateScreenThresholdMovement
; ---------------------------------------------------------------------------
Boss_JampanMoveRightTowardScreenThreshold:              ; CODE XREF: Boss_JampanMoveToScreenThresholdState+6   j
                addq.w  #2,(SharedScratchLong2).w
                addi.l  #$8000,$10(a5)
Boss_JampanUpdateScreenThresholdMovement:               ; CODE XREF: Boss_JampanMoveToScreenThresholdState+14   j
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                addq.w  #8,(BossCombatCounter).w
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanMoveToScreenThresholdReturn
                addq.w  #2,4(a5)
Boss_JampanMoveToScreenThresholdReturn:                 ; CODE XREF: Boss_JampanMoveToScreenThresholdState+2E   j
                rts
; End of function Boss_JampanMoveToScreenThresholdState
; Waits for bit zero of the boss-counter maximum flag before advancing
Boss_JampanWaitForBossCounterMaxFlagState:              ; DATA XREF: ROM:000491F2   o  ; was: sub_49898
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                addq.w  #8,(BossCombatCounter).w
                btst    #0,(BossCounterMaxFlag).w
                beq.s   Boss_JampanWaitForBossCounterMaxFlagReturn
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,(QuaternaryEntityWork52).w
                addq.w  #2,4(a5)
Boss_JampanWaitForBossCounterMaxFlagReturn:             ; CODE XREF: Boss_JampanWaitForBossCounterMaxFlagState+E   j
                rts
; End of function Boss_JampanWaitForBossCounterMaxFlagState
; Converges the horizontal-angle accumulator on $100 while moving
Boss_JampanBalanceHorizontalAngleState:                 ; DATA XREF: ROM:000491F4   o  ; was: sub_498C0
                cmpi.w  #$100,(SharedScratchLong2).w
                bcc.s   Boss_JampanDecreaseHorizontalAngle
                addq.w  #2,(SharedScratchLong2).w
                addi.l  #$8000,$10(a5)
                bra.s   Boss_JampanUpdateHorizontalAngleMovement
; ---------------------------------------------------------------------------
Boss_JampanDecreaseHorizontalAngle:                     ; CODE XREF: Boss_JampanBalanceHorizontalAngleState+6   j
                subq.w  #2,(SharedScratchLong2).w
                subi.l  #$8000,$10(a5)
Boss_JampanUpdateHorizontalAngleMovement:               ; CODE XREF: Boss_JampanBalanceHorizontalAngleState+14   j
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanBalanceHorizontalAngleReturn
                addq.w  #2,4(a5)
Boss_JampanBalanceHorizontalAngleReturn:                ; CODE XREF: Boss_JampanBalanceHorizontalAngleState+2A   j
                rts
; End of function Boss_JampanBalanceHorizontalAngleState
; Raises the boss to screen Y $F0 and returns to attack selection
Boss_JampanRiseToAttackHeightState:                     ; DATA XREF: ROM:000491F6   o  ; was: sub_498F2
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                subq.w  #1,$14(a5)
                cmpi.w  #$F0,$14(a5)
                bhi.s   Boss_JampanRiseToAttackHeightReturn
                move.w  #$F0,$14(a5)
                bset    #2,$4C(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$54(a5)
                bclr    #1,$4C(a5)
                move.w  #$12,4(a5)
Boss_JampanRiseToAttackHeightReturn:                    ; CODE XREF: Boss_JampanRiseToAttackHeightState+12   j
                rts
; End of function Boss_JampanRiseToAttackHeightState
; Initializes the live offset-attack branch selected by the combat selector
Boss_JampanInitializeOffsetAttackState:                 ; DATA XREF: ROM:000491F8   o  ; was: sub_49930
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                clr.w   (TertiaryEntityWork52).w
                clr.w   (FifthEntityWork52).w
                clr.w   (SixthEntityWork52).w
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanInitializeOffsetAttackState
; Chooses the offset-attack direction from the player's horizontal side
Boss_JampanChooseOffsetAttackDirectionState:            ; DATA XREF: ROM:000491FA   o  ; was: sub_49950
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanChooseOffsetAttackDirectionReturn
                addq.w  #2,4(a5)
                bclr    #1,$4C(a5)
                clr.w   (SeventhEntityWork52).w
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                bpl.s   Boss_JampanChooseRightOffsetAttack
                move.w  #2,(QuaternaryEntityWork52).w
                move.w  #$FFFE,$5A(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanChooseRightOffsetAttack:                     ; CODE XREF: Boss_JampanChooseOffsetAttackDirectionState+24   j
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,$5A(a5)
Boss_JampanChooseOffsetAttackDirectionReturn:           ; CODE XREF: Boss_JampanChooseOffsetAttackDirectionState+C   j
                rts
; End of function Boss_JampanChooseOffsetAttackDirectionState
; Waits for linked parts, then creates the type-$238 offset-attack object
Boss_JampanSpawnOffsetAttackObjectState:                ; DATA XREF: ROM:000491FC   o  ; was: sub_49992
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (SecondaryEntityWork52).w
                bne.s   Boss_JampanSpawnOffsetAttackObjectReturn
                tst.w   (QuaternaryEntityWork52).w
                bne.s   Boss_JampanSpawnOffsetAttackObjectReturn
                move.w  #1,(TertiaryEntityWork52).w
                move.w  #1,(FifthEntityWork52).w
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_JampanSpawnOffsetAttackObjectReturn
                andi.w  #$7FFF,(SeventhEntityFlags).w
                move.w  #$238,(a0)
                move.w  #$CD00,2(a0)
                move.l  #Boss_JampanShieldAndOrbitingPartMapping,8(a0)
                move.w  #$EB00,$E(a0)
                move.l  (SeventhEntityXPos).w,$10(a0)
                move.l  (SeventhEntityYPos).w,$14(a0)
                move.b  #4,$20(a0)
                move.w  #$80,$26(a0)
                andi.w  #$7FFF,(SeventhEntityFlags).w
                addq.w  #2,4(a5)
                tst.w   (DifficultyMode).w
                bne.s   Boss_JampanUseShortOffsetAttackDelay
                move.w  #$40,$48(a5)                    ; '@'
                rts
; ---------------------------------------------------------------------------
Boss_JampanUseShortOffsetAttackDelay:                   ; CODE XREF: Boss_JampanSpawnOffsetAttackObjectState+70   j
                move.w  #$10,$48(a5)
Boss_JampanSpawnOffsetAttackObjectReturn:               ; CODE XREF: Boss_JampanSpawnOffsetAttackObjectState+10   j
                                        ; Boss_JampanSpawnOffsetAttackObjectState+16   j
                rts
; End of function Boss_JampanSpawnOffsetAttackObjectState
