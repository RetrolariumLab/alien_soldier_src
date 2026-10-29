; Update body rendering, geometry mode, movement step, and the current state
Boss_ShieldViperUpdate:                                 ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4DDD2
                tst.w   4(a5)
                beq.w   Boss_ShieldViperDispatchState
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$5A(a5)
                bsr.w   Gfx_ShieldViperUpdateBodyMappings
                jsr     (Gfx_ProcessDefaultColorFade).l
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_ShieldViperUpdateGeometryUnlessTransitioning
                tst.w   (BossHealth).w
                bne.s   Boss_ShieldViperUpdateGeometryUnlessTransitioning
                move.b  #2,(BossColorEffectFlags).w
                move.w  #$70,4(a5)                      ; 'p'
                bset    #0,$58(a5)
                bset    #0,(StageTimerPauseFlag).w
Boss_ShieldViperUpdateGeometryUnlessTransitioning:      ; CODE XREF: Boss_ShieldViperUpdate+24   j  ; was: loc_4DE16
                                        ; Boss_ShieldViperUpdate+2A   j
                btst    #0,$58(a5)
                bne.w   Boss_ShieldViperDispatchState
                lea     (Math_SineTable).l,a3
                move.w  (SharedScratchLong4).w,d0
                andi.w  #$FF,d0
                add.w   d0,d0
                move.w  -$80(a3,d0.w),d0
                ext.l   d0
                asl.l   #4,d0
                swap    d0
                move.w  d0,(SharedScratchLong6+2).w
                move.w  (SharedScratchLong4+2).w,d0
                add.w   d0,(SharedScratchLong4).w
                movea.w a5,a0
                bsr.w   Boss_ShieldViperApproachAngularOffsetByTwoSteps
                btst    #0,(SharedScratchLong5+1).w
                beq.w   Boss_ShieldViperUpdateTrailGeometry
; Linked-body mode: accumulate sixteen polar offsets from the controller
                moveq   #0,d5
                moveq   #0,d6
                move.w  #$F,d7
                lea     $60(a5),a0
Boss_ShieldViperAccumulateLinkedBodyOffsetsLoop:        ; CODE XREF: Boss_ShieldViperUpdate+BC   j  ; was: loc_4DE62
                move.w  $56(a0),d0
                add.w   $52(a0),d0
                andi.w  #$1FE,d0
                move.w  -$80(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                muls.w  $50(a0),d0
                muls.w  $50(a0),d1
                add.l   d0,d5
                add.l   d1,d6
                move.l  d5,$48(a0)
                move.l  d6,$4C(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperAccumulateLinkedBodyOffsetsLoop
                movea.w (SharedScratchLong2).w,a0
                cmpa.w  a5,a0
                beq.s   Boss_ShieldViperAnchorLinkedBodyXToSelectedRecord
                move.l  $10(a0),d0
                sub.l   $48(a0),d0
                move.l  d0,$10(a5)
Boss_ShieldViperAnchorLinkedBodyXToSelectedRecord:      ; CODE XREF: Boss_ShieldViperUpdate+C6   j  ; was: loc_4DEA6
                movea.w (SharedScratchLong2+2).w,a0
                cmpa.w  a5,a0
                beq.s   Boss_ShieldViperApplyLinkedBodyPositions
                move.l  $14(a0),d0
                sub.l   $4C(a0),d0
                move.l  d0,$14(a5)
Boss_ShieldViperApplyLinkedBodyPositions:               ; CODE XREF: Boss_ShieldViperUpdate+DA   j  ; was: loc_4DEBA
                move.w  #$F,d7
                lea     $60(a5),a0
Boss_ShieldViperApplyLinkedBodyPositionsLoop:           ; CODE XREF: Boss_ShieldViperUpdate+10C   j  ; was: loc_4DEC2
                move.l  $48(a0),d0
                add.l   $10(a5),d0
                move.l  d0,$10(a0)
                move.l  $4C(a0),d0
                add.l   $14(a5),d0
                move.l  d0,$14(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperApplyLinkedBodyPositionsLoop
                move.w  $4D6(a5),d0
                move.w  #$10,d7
                lea     (a5),a0
Boss_ShieldViperCopyCenterAngleToLinkedBodyLoop:        ; CODE XREF: Boss_ShieldViperUpdate+122   j  ; was: loc_4DEEC
                move.w  d0,$56(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperCopyCenterAngleToLinkedBodyLoop
                move.w  #7,d7
                lea     $600(a5),a1
                lea     $660(a5),a0
Boss_ShieldViperProjectTrailingBodyRecordsLoop:         ; CODE XREF: Boss_ShieldViperUpdate+160   j  ; was: loc_4DF04
                move.w  $56(a0),d0
                andi.w  #$1FE,d0
                move.w  -$80(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                muls.w  $50(a0),d0
                muls.w  $50(a0),d1
                add.l   $10(a1),d0
                add.l   $14(a1),d1
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w a0,a1
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperProjectTrailingBodyRecordsLoop
                move.w  $656(a5),d0
                add.w   $652(a5),d0
; Delay the first trailing-record angle through a 65-word history buffer
                lea     (ShieldViperAngleDelay).w,a0
                move.w  #$40,d7                         ; '@'
Boss_ShieldViperShiftTrailingAngleHistoryLoop:          ; CODE XREF: Boss_ShieldViperUpdate+17A   j  ; was: loc_4DF46
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d7,Boss_ShieldViperShiftTrailingAngleHistoryLoop
                lea     (ShieldViperAngleDelay).w,a1
                lea     $660(a5),a0
                moveq   #0,d6
                move.w  #7,d7
Boss_ShieldViperApplyTrailingAngleHistoryLoop:          ; CODE XREF: Boss_ShieldViperUpdate+198   j  ; was: loc_4DF5E
                lea     $10(a1),a1
                move.w  (a1),$56(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperApplyTrailingAngleHistoryLoop
                bra.w   Boss_ShieldViperUpdateRadialStep
; ---------------------------------------------------------------------------
; Trail mode: delay the controller angle and packed position across 24 records
Boss_ShieldViperUpdateTrailGeometry:                    ; CODE XREF: Boss_ShieldViperUpdate+80   j  ; was: loc_4DF72
                lea     (ShieldViperTrailAngles).w,a1
                lea     (ShieldViperPoseHistory).w,a2
                move.w  $56(a5),d0
                move.w  $10(a5),d2
                swap    d2
                move.w  $14(a5),d2
                cmp.l   (SharedScratchLong3).w,d2
                beq.s   Boss_ShieldViperApplyTrailPoseHistory
                move.l  d2,(SharedScratchLong3).w
                move.w  #$60,d7                         ; '`'
Boss_ShieldViperShiftTrailPoseHistoryLoop:              ; CODE XREF: Boss_ShieldViperUpdate+1D0   j  ; was: loc_4DF96
                move.w  (a1),d1
                move.w  d0,(a1)+
                move.w  d1,d0
                move.l  (a2),d3
                move.l  d2,(a2)+
                move.l  d3,d2
                dbf     d7,Boss_ShieldViperShiftTrailPoseHistoryLoop
Boss_ShieldViperApplyTrailPoseHistory:                  ; CODE XREF: Boss_ShieldViperUpdate+1BA   j  ; was: loc_4DFA6
                lea     (ShieldViperTrailAngles).w,a1
                lea     (ShieldViperPoseHistory).w,a2
                lea     $60(a5),a0
                move.w  #$17,d7
Boss_ShieldViperApplyTrailPoseHistoryLoop:              ; CODE XREF: Boss_ShieldViperUpdate+200   j  ; was: loc_4DFB6
                lea     8(a1),a1
                move.w  (a1),$56(a0)
                lea     $10(a2),a2
                move.l  (a2),d0
                move.w  d0,$14(a0)
                swap    d0
                move.w  d0,$10(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperApplyTrailPoseHistoryLoop
Boss_ShieldViperUpdateRadialStep:                       ; CODE XREF: Boss_ShieldViperUpdate+19C   j  ; was: loc_4DFD6
                bsr.w   Boss_ShieldViperUpdateRadialMovementStep
Boss_ShieldViperDispatchState:                          ; CODE XREF: Boss_ShieldViperUpdate+4   j  ; was: loc_4DFDA
                                        ; Boss_ShieldViperUpdate+4A   j
                move.w  4(a5),d0
                lea     Boss_ShieldViperStateHandlerOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_ShieldViperUpdate
; ---------------------------------------------------------------------------
Boss_ShieldViperStateHandlerOffsets:    dc.w    Boss_ShieldViperInitialize-*  ; DATA XREF: Boss_ShieldViperUpdate+20C   o  ; was: off_4DFE6
                dc.w    Boss_ShieldViperPlaceForIntroDelay-*
                dc.w    Boss_ShieldViperWaitIntroDelay-*
                dc.w    Boss_ShieldViperMoveIntroToYThreshold-*
                dc.w    Boss_ShieldViperWaitForStageTransitionAndEnterAttackSequence-*
                dc.w    Boss_ShieldViperNoOpStateA-*
                dc.w    Boss_ShieldViperSharedNoOpState-*
                dc.w    Boss_ShieldViperSharedNoOpState-*
                dc.w    Boss_ShieldViperSharedNoOpState-*
                dc.w    Boss_ShieldViperSelectAlternatingEntrySide-*
                dc.w    Boss_ShieldViperMoveToEntryYThreshold-*
                dc.w    Boss_ShieldViperRotateToEntryAngle-*
                dc.w    Boss_ShieldViperWaitForCenterQuarterTurn-*
                dc.w    Boss_ShieldViperConfigureInitialBodyBend-*
                dc.w    Boss_ShieldViperWaitForInitialBodyBend-*
                dc.w    Boss_ShieldViperBeginThreePhaseBodyBend-*
                dc.w    Boss_ShieldViperConfigureBodyBendPhase-*
                dc.w    Boss_ShieldViperWaitForBodyBendPhaseAndLoop-*
                dc.w    Boss_ShieldViperConfigureFinalBodyBend-*
                dc.w    Boss_ShieldViperWaitForFinalBodyBend-*
                dc.w    Boss_ShieldViperBeginOrbitShotBurstDelay-*
                dc.w    Boss_ShieldViperWaitOrbitShotBurstDelay-*
                dc.w    Boss_ShieldViperEmitOrbitShotBurst-*
                dc.w    Boss_ShieldViperEnableTrailGeometryAndAdvance-*
                dc.w    Boss_ShieldViperAdvanceState-*
                dc.w    Boss_ShieldViperBeginTwoPassPlayerTrackingCycle-*
                dc.w    Boss_ShieldViperBeginPlayerTrackingPass-*
                dc.w    Boss_ShieldViperUpdatePlayerTrackingPass-*
                dc.w    Boss_ShieldViperChooseRandomVerticalTarget-*
                dc.w    Boss_ShieldViperRotateToSelectedVerticalTargetAngle-*
                dc.w    Boss_ShieldViperRouteAtSelectedVerticalBoundary-*
                dc.w    Boss_ShieldViperSelectAlternatingReentrySide-*
                dc.w    Boss_ShieldViperMoveToReentryYThreshold-*
                dc.w    Boss_ShieldViperDoubleAngularStepAtHalfTurns-*
                dc.w    Boss_ShieldViperWaitBeforeOrbitShotWindup-*
                dc.w    Boss_ShieldViperAnimateOrbitShotWindup-*
                dc.w    Boss_ShieldViperEmitTimedOrbitShotStream-*
                dc.w    Boss_ShieldViperRotateToHalfTurnAfterOrbitShots-*
                dc.w    Boss_ShieldViperMoveToLowerBoundaryAndRestartTracking-*
                dc.w    Boss_ShieldViperDoubleAngularStepAndBeginDelay-*
                dc.w    Boss_ShieldViperWaitAfterAngularStepDoubling-*
                dc.w    Boss_ShieldViperWaitWithHorizontalFlipBeforeLinkedRecords-*
                dc.w    Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords-*
                dc.w    Boss_ShieldViperWaitForLinkedRecordActivation-*
                dc.w    Boss_ShieldViperSpawnPatternProjectileSet-*
                dc.w    Boss_ShieldViperWaitForPatternProjectileSequence-*
                dc.w    Boss_ShieldViperAdvanceAfterPatternProjectileSequence-*
                dc.w    Boss_ShieldViperSteerTowardCenterAndDoubleStepAtQuarterTurn-*
                dc.w    Boss_ShieldViperAdvanceTwoStatesWhileMoving-*
                dc.w    Boss_ShieldViperAdvanceSecondStateWhileMoving-*
                dc.w    Boss_ShieldViperAdvanceOneStateWhileMoving-*
                dc.w    Boss_ShieldViperBeginLinkedRecordReleaseDelay-*
                dc.w    Boss_ShieldViperPrepareSequentialLinkedRecordRelease-*
                dc.w    Boss_ShieldViperReleaseLinkedBodyRecordsSequentially-*
                dc.w    Boss_ShieldViperWaitAfterLinkedRecordReleaseAndDoubleAngularStep-*
                dc.w    Boss_ShieldViperWaitThenHalveAngularStepAndRestartTracking-*
                dc.w    Boss_ShieldViperBeginStaggeredDefeat-*
                dc.w    Boss_ShieldViperWaitForStaggeredDefeat-*
                dc.w    Boss_ShieldViperRunPostDefeatPaletteCycle-*
                dc.w    Boss_ShieldViperRunFinalDefeatPaletteFade-*
                dc.w    Boss_ShieldViperHoldFinalDefeatPaletteAndRemove-*

; Initialize the controller, 24 body records, and two auxiliary records
Boss_ShieldViperInitialize:                             ; DATA XREF: ROM:Boss_ShieldViperStateHandlerOffsets   o  ; was: sub_4E060
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_ShieldViperInitializationReturn
                addq.w  #2,4(a5)
                move.w  #$34C,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                clr.w   (SharedScratchLong1).w
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #$50,(SharedScratchLong6).w     ; 'P'
                move.w  #$14,(SharedScratchLong7).w
                move.w  a5,(SharedScratchLong2).w
                move.w  a5,(SharedScratchLong2+2).w
                move.w  #$160,$10(a5)
                move.w  #$180,$14(a5)
                move.w  #$A300,$E(a5)
                move.w  #$4C00,2(a5)
                move.l  #Boss_ShieldViperControllerAngleFrame00,8(a5)
                clr.w   $C(a5)
                move.b  #$10,$20(a5)
                move.b  #$50,$21(a5)                    ; 'P'
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$14,$24(a5)
                move.w  #$80,$26(a5)
                move.b  #6,(BossColorEffectFlags).w
                move.b  #$80,$23(a5)
                moveq   #0,d6
                move.w  #$17,d7
                clr.w   d6
                lea     $60(a5),a0
                lea     Boss_ShieldViperBodyInitializationRecords(pc),a1
                nop
Boss_ShieldViperInitializeBodyRecordLoop:               ; CODE XREF: Boss_ShieldViperInitialize+116   j  ; was: loc_4E100
                move.w  #$A300,$E(a0)
                move.w  #$CC00,2(a0)
                move.w  #$80,$26(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.w  #$14,$24(a0)
                move.w  #$370,(a0)
                move.w  (a1),$50(a0)
                move.b  3(a1),$5E(a0)
                move.l  4(a1),8(a0)
                clr.w   $C(a0)
                lea     8(a1),a1
                cmpi.w  #6,d7
                bmi.s   Boss_ShieldViperAdvanceBodyInitializationLoop
                btst    #0,d7
                bne.s   Boss_ShieldViperClearAlternateBodyCollisionBounds
                move.b  #$D0,$21(a0)
                move.b  #4,$23(a0)
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #$10,$24(a0)
                bra.s   Boss_ShieldViperAdvanceBodyInitializationLoop
; ---------------------------------------------------------------------------
Boss_ShieldViperClearAlternateBodyCollisionBounds:      ; CODE XREF: Boss_ShieldViperInitialize+E8   j  ; was: loc_4E16E
                clr.l   $2C(a0)
Boss_ShieldViperAdvanceBodyInitializationLoop:          ; CODE XREF: Boss_ShieldViperInitialize+E2   j  ; was: loc_4E172
                                        ; Boss_ShieldViperInitialize+10C   j
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperInitializeBodyRecordLoop
                move.w  #$4C00,2(a0)
                move.w  #$10,(a0)
                move.l  #Projectile_ShieldViperOrbitShotFrame01,8(a0)
                move.w  #$8300,$E(a0)
                move.w  #$60,$50(a0)                    ; '`'
; End of function Boss_ShieldViperInitialize
; Initialize the second auxiliary record, all body angles, and both histories
Boss_ShieldViperInitializeAuxiliaryRecordsAndHistory:   ; was: sub_4E198
                lea     $60(a0),a0
                move.w  #$3A8,(a0)
                move.w  #$C00,2(a0)
                move.w  #$18,d7
                move.w  #$80,d0
                movea.w a5,a0
Boss_ShieldViperInitializeBodyAnglesLoop:               ; CODE XREF: Boss_ShieldViperInitializeAuxiliaryRecordsAndHistory+20   j  ; was: loc_4E1B0
                move.w  d0,$56(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperInitializeBodyAnglesLoop
                lea     (ShieldViperTrailAngles).w,a1
                move.w  #$1F,d7
                move.l  #$800080,d0
Boss_ShieldViperInitializeTrailAngleHistoryLoop:        ; CODE XREF: Boss_ShieldViperInitializeAuxiliaryRecordsAndHistory+34   j  ; was: loc_4E1CA
                move.l  d0,(a1)+
                dbf     d7,Boss_ShieldViperInitializeTrailAngleHistoryLoop
                lea     (ShieldViperAngleDelay).w,a1
                move.w  #$1F,d7
Boss_ShieldViperInitializeTrailingAngleHistoryLoop:     ; CODE XREF: Boss_ShieldViperInitializeAuxiliaryRecordsAndHistory+42   j  ; was: loc_4E1D8
                move.l  d0,(a1)+
                dbf     d7,Boss_ShieldViperInitializeTrailingAngleHistoryLoop
Boss_ShieldViperInitializationReturn:                   ; CODE XREF: Boss_ShieldViperInitialize+4   j  ; was: locret_4E1DE
                rts
; End of function Boss_ShieldViperInitializeAuxiliaryRecordsAndHistory
; ---------------------------------------------------------------------------
Boss_ShieldViperBodyInitializationRecords:  dc.w    $50  ; field_0  ; was: stru_4E1E0
                                        ; DATA XREF: Boss_ShieldViperInitialize+9A   o
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    0                               ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $50                             ; field_0
                dc.w    1                               ; field_2
                dc.l    Boss_ShieldViperBodyInitTailFrame00  ; field_4
                dc.w    $38                             ; field_0
                dc.w    1                               ; field_2
                dc.l    Boss_ShieldViperBodyInitTailFrame00  ; field_4
                dc.w    $30                             ; field_0
                dc.w    1                               ; field_2
                dc.l    Boss_ShieldViperBodyInitTailFrame01  ; field_4
                dc.w    $30                             ; field_0
                dc.w    1                               ; field_2
                dc.l    Boss_ShieldViperBodyInitTailFrame01  ; field_4
                dc.w    $28                             ; field_0
                dc.w    1                               ; field_2
                dc.l    Boss_ShieldViperBodyInitTailFrame02  ; field_4
                dc.w    $28                             ; field_0
                dc.w    1                               ; field_2
                dc.l    Boss_ShieldViperBodyInitTailFrame02  ; field_4

; Place the controller and seed the 128-frame intro delay
Boss_ShieldViperPlaceForIntroDelay:                     ; DATA XREF: ROM:0004DFE8   o  ; was: sub_4E2A0
                addq.w  #2,4(a5)
                move.w  #$180,$10(a5)
                move.w  #$1A0,$14(a5)
                move.w  #$80,$56(a5)
                move.w  #$80,$48(a5)
; Wait for the intro delay, then enable the high display flag and advance
Boss_ShieldViperWaitIntroDelay:                         ; DATA XREF: ROM:0004DFEA   o  ; was: loc_4E2BC
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperIntroDelayReturn
                bset    #7,2(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperIntroDelayReturn:                       ; CODE XREF: Boss_ShieldViperPlaceForIntroDelay+20   j  ; was: locret_4E2CC
                rts
; End of function Boss_ShieldViperPlaceForIntroDelay
; Move radially until controller Y reaches $E0
Boss_ShieldViperMoveIntroToYThreshold:                  ; DATA XREF: ROM:0004DFEC   o  ; was: sub_4E2CE
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$E0,$14(a5)
                bgt.s   Boss_ShieldViperIntroMovementReturn
                addq.w  #2,4(a5)
                move.w  #$FFF8,(SharedScratchLong0).w
                move.w  #3,d0
                jsr     (BossMessage_Start).l
Boss_ShieldViperIntroMovementReturn:                    ; CODE XREF: Boss_ShieldViperMoveIntroToYThreshold+A   j  ; was: locret_4E2EE
                rts
; End of function Boss_ShieldViperMoveIntroToYThreshold
; Keep rotating and moving until the stage-transition gate opens, then enter state $32
Boss_ShieldViperWaitForStageTransitionAndEnterAttackSequence:  ; DATA XREF: ROM:0004DFEE   o  ; was: sub_4E2F0
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                tst.w   (MessageSequenceState).w
                bne.s   Boss_ShieldViperStageTransitionWaitReturn
                clr.b   (BossColorEffectFlags).w
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperStageTransitionWaitReturn:              ; CODE XREF: Boss_ShieldViperWaitForStageTransitionAndEnterAttackSequence+8   j  ; was: locret_4E304
                rts
; End of function Boss_ShieldViperWaitForStageTransitionAndEnterAttackSequence
Boss_ShieldViperNoOpStateA:                             ; DATA XREF: ROM:0004DFF0   o  ; was: nullsub_113
                rts
; End of function Boss_ShieldViperNoOpStateA

Boss_ShieldViperSharedNoOpState:                        ; DATA XREF: ROM:0004DFF2   o  ; was: nullsub_114
                                        ; ROM:0004DFF4   o
                rts
; End of function Boss_ShieldViperSharedNoOpState

; Alternate the entry side, angular direction, and target angle
Boss_ShieldViperSelectAlternatingEntrySide:             ; DATA XREF: ROM:0004DFF8   o  ; was: sub_4E30A
                move.w  #$14,(SharedScratchLong7).w
                addq.w  #2,4(a5)
                move.w  #$180,$14(a5)
                move.w  #$80,$56(a5)
                addq.b  #1,(SharedScratchLong5+2).w
                btst    #0,(SharedScratchLong5+2).w
                beq.s   Boss_ShieldViperConfigureLeftEntry
                move.w  #$180,$10(a5)
                move.w  #$FFFC,(SharedScratchLong0).w
                move.w  #$100,$4A(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperConfigureLeftEntry:                     ; CODE XREF: Boss_ShieldViperSelectAlternatingEntrySide+20   j  ; was: loc_4E340
                move.w  #$C0,$10(a5)
                move.w  #4,(SharedScratchLong0).w
                move.w  #0,$4A(a5)
                rts
; End of function Boss_ShieldViperSelectAlternatingEntrySide
; Move radially until controller Y reaches $140
Boss_ShieldViperMoveToEntryYThreshold:                  ; DATA XREF: ROM:0004DFFA   o  ; was: sub_4E354
                move.w  #$14,(SharedScratchLong7).w
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$140,$14(a5)
                bgt.s   Boss_ShieldViperEntryApproachReturn
                addq.w  #2,4(a5)
Boss_ShieldViperEntryApproachReturn:                    ; CODE XREF: Boss_ShieldViperMoveToEntryYThreshold+10   j  ; was: locret_4E36A
                rts
; End of function Boss_ShieldViperMoveToEntryYThreshold
; Rotate and move radially until the controller reaches its entry angle
Boss_ShieldViperRotateToEntryAngle:                     ; DATA XREF: ROM:0004DFFC   o  ; was: sub_4E36C
                move.w  #$14,(SharedScratchLong7).w
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmp.w   $4A(a5),d0
                bne.s   Boss_ShieldViperEntryAngleWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperEntryAngleWaitReturn:                   ; CODE XREF: Boss_ShieldViperRotateToEntryAngle+16   j  ; was: locret_4E388
                rts
; End of function Boss_ShieldViperRotateToEntryAngle
; Wait for the center record's quarter turn, then switch to linked-body geometry
Boss_ShieldViperWaitForCenterQuarterTurn:               ; DATA XREF: ROM:0004DFFE   o  ; was: sub_4E38A
                move.w  #$14,(SharedScratchLong7).w
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $4D6(a5),d0
                andi.w  #$1FC,d0
                cmpi.w  #$80,d0
                bne.w   Boss_ShieldViperCenterQuarterTurnWaitReturn
                addq.w  #2,4(a5)
                move.w  d0,$4D6(a5)
                bsr.w   Boss_ShieldViperEnableLinkedBodyGeometry
                lea     $480(a5),a0
                lea     $480(a5),a1
                move.w  a0,(SharedScratchLong2).w
                move.w  a1,(SharedScratchLong2+2).w
Boss_ShieldViperCenterQuarterTurnWaitReturn:            ; CODE XREF: Boss_ShieldViperWaitForCenterQuarterTurn+16   j  ; was: locret_4E3C0
                rts
; End of function Boss_ShieldViperWaitForCenterQuarterTurn
; Configure the first signed body-bend step for the selected entry side
Boss_ShieldViperConfigureInitialBodyBend:               ; DATA XREF: ROM:0004E000   o  ; was: sub_4E3C2
                move.w  #$14,(SharedScratchLong7).w
                addq.w  #2,4(a5)
                move.w  #$18,(SharedScratchLong1).w
                btst    #0,(SharedScratchLong5+2).w
                bne.s   Boss_ShieldViperApplyInitialBodyBend
                neg.w   (SharedScratchLong1).w
Boss_ShieldViperApplyInitialBodyBend:                   ; CODE XREF: Boss_ShieldViperConfigureInitialBodyBend+16   j  ; was: loc_4E3DE
                bsr.w   Boss_ShieldViperSetBodyTargetAngularOffsets
                rts
; End of function Boss_ShieldViperConfigureInitialBodyBend
; Wait until the controller's current angular offset reaches its target
Boss_ShieldViperWaitForInitialBodyBend:                 ; DATA XREF: ROM:0004E002   o  ; was: sub_4E3E4
                move.w  #$14,(SharedScratchLong7).w
                move.w  $54(a5),d0
                sub.w   $52(a5),d0
                andi.w  #$1FF,d0
                bne.s   Boss_ShieldViperInitialBodyBendWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperInitialBodyBendWaitReturn:              ; CODE XREF: Boss_ShieldViperWaitForInitialBodyBend+12   j  ; was: locret_4E3FC
                rts
; End of function Boss_ShieldViperWaitForInitialBodyBend
; Seed a three-phase body-bend sequence
Boss_ShieldViperBeginThreePhaseBodyBend:                ; DATA XREF: ROM:0004E004   o  ; was: sub_4E3FE
                move.w  #$14,(SharedScratchLong7).w
                move.w  a5,(SharedScratchLong2).w
                addq.w  #2,4(a5)
                move.w  #$10,(SharedScratchLong4+2).w
                move.w  #$28,(SharedScratchLong1).w     ; '('
                move.w  #3,$4A(a5)
; Select and apply the current signed body-bend step
Boss_ShieldViperConfigureBodyBendPhase:                 ; DATA XREF: ROM:0004E006   o  ; was: loc_4E41E
                move.w  #$14,(SharedScratchLong7).w
                move.w  #3,d0
                sub.w   $4A(a5),d0
                add.w   d0,d0
                move.w  Boss_ShieldViperBodyBendStepTable(pc,d0.w),(SharedScratchLong1).w
                btst    #0,(SharedScratchLong5+2).w
                bne.s   Boss_ShieldViperApplyBodyBendPhase
                neg.w   (SharedScratchLong1).w
Boss_ShieldViperApplyBodyBendPhase:                     ; CODE XREF: Boss_ShieldViperBeginThreePhaseBodyBend+3C   j  ; was: loc_4E440
                bsr.w   Boss_ShieldViperSetBodyTargetAngularOffsets
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginThreePhaseBodyBend
; ---------------------------------------------------------------------------
Boss_ShieldViperBodyBendStepTable:  dc.w    $20, $3C, $20, $3C, $20  ; was: word_4E44A
                                        ; DATA XREF: Boss_ShieldViperBeginThreePhaseBodyBend+30   r

; Wait for a bend phase to settle, then repeat or advance
Boss_ShieldViperWaitForBodyBendPhaseAndLoop:            ; DATA XREF: ROM:0004E008   o  ; was: sub_4E454
                move.w  #$14,(SharedScratchLong7).w
                move.w  $54(a5),d0
                sub.w   $52(a5),d0
                andi.w  #$1FF,d0
                bne.s   Boss_ShieldViperBodyBendPhaseWaitReturn
                subq.w  #1,$4A(a5)
                beq.s   Boss_ShieldViperFinishBodyBendPhases
                subq.w  #2,4(a5)
Boss_ShieldViperBodyBendPhaseWaitReturn:                ; CODE XREF: Boss_ShieldViperWaitForBodyBendPhaseAndLoop+12   j  ; was: locret_4E472
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperFinishBodyBendPhases:                   ; CODE XREF: Boss_ShieldViperWaitForBodyBendPhaseAndLoop+18   j  ; was: loc_4E474
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperWaitForBodyBendPhaseAndLoop
; Configure and apply the final signed body-bend step
Boss_ShieldViperConfigureFinalBodyBend:                 ; DATA XREF: ROM:0004E00A   o  ; was: sub_4E47A
                move.w  #$14,(SharedScratchLong7).w
                move.w  #$20,(SharedScratchLong1).w     ; ' '
                btst    #0,(SharedScratchLong5+2).w
                bne.s   Boss_ShieldViperApplyFinalBodyBend
                neg.w   (SharedScratchLong1).w
Boss_ShieldViperApplyFinalBodyBend:                     ; CODE XREF: Boss_ShieldViperConfigureFinalBodyBend+12   j  ; was: loc_4E492
                bsr.w   Boss_ShieldViperSetBodyTargetAngularOffsets
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperConfigureFinalBodyBend
; Wait until the final controller angular offset reaches its target
Boss_ShieldViperWaitForFinalBodyBend:                   ; DATA XREF: ROM:0004E00C   o  ; was: sub_4E49C
                move.w  #$14,(SharedScratchLong7).w
                move.w  $54(a5),d0
                sub.w   $52(a5),d0
                andi.w  #$1FF,d0
                bne.s   Boss_ShieldViperFinalBodyBendWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperFinalBodyBendWaitReturn:                ; CODE XREF: Boss_ShieldViperWaitForFinalBodyBend+12   j  ; was: locret_4E4B4
                rts
; End of function Boss_ShieldViperWaitForFinalBodyBend
; Seed the 64-frame delay before the orbit-shot burst
Boss_ShieldViperBeginOrbitShotBurstDelay:               ; DATA XREF: ROM:0004E00E   o  ; was: sub_4E4B6
                move.w  #$14,(SharedScratchLong7).w
                move.w  #$40,$48(a5)                    ; '@'
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginOrbitShotBurstDelay
; Animate horizontal flip while waiting, then seed a sixteen-shot burst
Boss_ShieldViperWaitOrbitShotBurstDelay:                ; DATA XREF: ROM:0004E010   o  ; was: sub_4E4CC
                move.w  #$14,(SharedScratchLong7).w
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotBurstDelayReturn
                move.w  #$10,$4A(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotBurstDelayReturn:              ; CODE XREF: Boss_ShieldViperWaitOrbitShotBurstDelay+E   j  ; was: locret_4E4E6
                rts
; End of function Boss_ShieldViperWaitOrbitShotBurstDelay
; Toggle and position the auxiliary record at a quantized angle around the controller
Boss_ShieldViperUpdateOrbitingRecord:                   ; CODE XREF: Boss_ShieldViperEmitOrbitShotBurst+6   p  ; was: sub_4E4E8
                                        ; Boss_ShieldViperEmitOrbitShotOnFrameGate   p
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                addi.w  #$120,d0
                andi.w  #$1C0,d0
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                lea     $960(a5),a0
                eori.w  #$8000,2(a0)
                muls.w  $50(a0),d0
                muls.w  $50(a0),d1
                add.l   $10(a5),d0
                add.l   $14(a5),d1
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                rts
; End of function Boss_ShieldViperUpdateOrbitingRecord
; Clear the auxiliary record's high display flag
Boss_ShieldViperHideOrbitingRecord:                     ; CODE XREF: Boss_ShieldViperEmitOrbitShotBurst+80   p  ; was: sub_4E52A
                                        ; Boss_ShieldViperHideOrbitingRecordAndForceFlip   p
                andi.w  #$7FFF,$962(a5)
                rts
; End of function Boss_ShieldViperHideOrbitingRecord
; Emit sixteen timed shots from the orbiting record, then hide it and advance
Boss_ShieldViperEmitOrbitShotBurst:                     ; DATA XREF: ROM:0004E012   o  ; was: sub_4E532
                move.w  #$14,(SharedScratchLong7).w
                bsr.w   Boss_ShieldViperUpdateOrbitingRecord
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bpl.s   Boss_ShieldViperOrbitShotBurstReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperOrbitShotBurstReturn
                jsr     Projectile_InitShieldViperOrbitShot(pc)  ; (pc)
                nop
                move.b  $20(a5),$20(a0)
                move.w  $970(a5),$10(a0)
                move.w  $974(a5),$14(a0)
                lea     (Math_SineTable).l,a3
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                addi.w  #$120,d0
                andi.w  #$1C0,d0
                add.w   (SharedScratchLong6+2).w,d0
                add.w   (SharedScratchLong6+2).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                ext.l   d0
                ext.l   d1
                asl.l   #5,d0
                asl.l   #5,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                move.w  #2,$48(a5)
                addi.w  #4,$56(a5)
                subq.w  #1,$4A(a5)
                bne.s   Boss_ShieldViperOrbitShotBurstReturn
                bsr.w   Boss_ShieldViperHideOrbitingRecord
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotBurstReturn:                   ; CODE XREF: Boss_ShieldViperEmitOrbitShotBurst+12   j  ; was: locret_4E5BE
                                        ; Boss_ShieldViperEmitOrbitShotBurst+1A   j
                rts
; End of function Boss_ShieldViperEmitOrbitShotBurst
