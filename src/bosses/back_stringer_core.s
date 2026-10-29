Boss_BackStringerMain:                                  ; was: sub_446AE
                tst.w   4(a5)
                beq.w   Boss_BackStringerDispatchState
                tst.w   8(a5)
                beq.s   Boss_BackStringerDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_BackStringerUpdateActiveFrame
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_BackStringerUpdateActiveFrame
                tst.w   (BossHealth).w
                beq.w   Boss_BackStringerDefeatInit
Boss_BackStringerUpdateActiveFrame:                     ; was: loc_446D4
                                        ; Boss_BackStringerMain+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
                btst    #7,2(a5)
                beq.s   Boss_BackStringerDispatchState
                move.w  #$F4F4,$A(a5)
                cmpi.w  #$100,$56(a5)
                bne.s   Boss_BackStringerDispatchState
                move.w  #$F6F4,$A(a5)
Boss_BackStringerDispatchState:                         ; was: loc_44702
                                        ; Boss_BackStringerMain+C   j
                move.w  4(a5),d0
                movea.w Boss_BackStringerStates(pc,d0.w),a0
                adda.l  #Boss_BackStringerWaitForActivationState,a0
                jmp     (a0)
; End of function Boss_BackStringerMain
; ---------------------------------------------------------------------------
Boss_BackStringerStates:    dc.w    Boss_BackStringerWaitForActivationState-Boss_BackStringerWaitForActivationState  ; was: off_44712
                dc.w    Boss_BackStringerInitializeState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerManualControlState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerEntranceState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerOpeningPoseState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerOpeningDelayState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerRotateToHalfTurnState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerWaitForVerticalThresholdState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerRotateToFullTurnState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerPostEntranceDelayState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerWaitForBattleStartState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerAttackDelayState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerSweepingAttackState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerTransformationState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerDivePreparationState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerDiveAttackState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerRetractFromDiveState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerDiveRecoveryDelayState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerRotateToHalfTurnAttackState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerRotateToZeroAttackState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerDefeatFadeOutState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerTrackingAttackWarmupState-Boss_BackStringerWaitForActivationState
                dc.w    Boss_BackStringerTrackingAttackState-Boss_BackStringerWaitForActivationState

; Waits for the encounter activation flag before initializing the boss
Boss_BackStringerWaitForActivationState:                ; was: sub_44740
                                        ; ROM:Boss_BackStringerStates   o
                clr.w   8(a5)
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_BackStringerWaitForActivationReturn
                addq.w  #2,4(a5)
                move.b  #$8C,d0
                jsr     (Sound_QueueBGMOrStop).l
Boss_BackStringerWaitForActivationReturn:               ; was: locret_44758
                rts
; End of function Boss_BackStringerWaitForActivationState
; Initializes the Back Stringer metasprite, auxiliary slots, and entrance
Boss_BackStringerInitializeState:                       ; was: sub_4475A
                addq.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$8300,(MetaspriteBaseTileWord).w
                moveq   #$14,d7
                movea.l #Boss_BackStringerMetaspriteDescriptors,a0
                movea.l #Boss_BackStringerPartRadii,a1
                movea.l #Boss_BackStringerPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$314,(a5)
                move.w  #$8D00,2(a5)
                clr.w   6(a5)
                move.w  #$C000,$62(a5)
                move.w  #$C000,$C2(a5)
                move.b  #1,d0
                move.b  #3,d1
                move.b  #2,d2
                movea.w a5,a0
                moveq   #5,d7
Boss_BackStringerInitializePartFlagsLoop:               ; was: loc_447AA
                or.b    d0,$140(a0)
                or.b    d1,$1A0(a0)
                or.b    d2,$200(a0)
                lea     $120(a0),a0
                dbf     d7,Boss_BackStringerInitializePartFlagsLoop
                bsr.w   Boss_BackStringerInitializeTailSegmentSlots
                movea.l #Boss_BackStringerObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                move.w  #2,$1DE(a5)
                bra.w   Boss_BackStringerBeginEntrance
; End of function Boss_BackStringerInitializeState
; Restores the position and tail used by the manual-control state
Boss_BackStringerResetManualControlState:               ; was: sub_447D8
                move.w  #4,4(a5)
                move.w  #$120,$10(a5)
                move.w  #$110,$14(a5)
                clr.b   (BossColorEffectFlags).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                bra.w   Boss_BackStringerResetTailSegments
; End of function Boss_BackStringerResetManualControlState
; Provides an otherwise unreachable controller-driven Back Stringer test state
Boss_BackStringerManualControlState:                    ; was: sub_447FA
                btst    #6,(ControllerPressedState).w
                beq.s   Boss_BackStringerCheckRetractInput
                bra.w   Boss_BackStringerResetManualControlState
; ---------------------------------------------------------------------------
Boss_BackStringerCheckRetractInput:                     ; was: loc_44806
                btst    #5,(ControllerPressedState).w
                beq.s   Boss_BackStringerCheckRaiseTailInput
                bsr.w   Boss_BackStringerRetractTailSegments
Boss_BackStringerCheckRaiseTailInput:                   ; was: loc_44812
                btst    #0,(ControllerHeldState).w
                beq.s   Boss_BackStringerCheckLowerTailInput
                subi.l  #$10000,$2FC(a5)
Boss_BackStringerCheckLowerTailInput:                   ; was: loc_44822
                btst    #1,(ControllerHeldState).w
                beq.s   Boss_BackStringerUpdateManualControlPose
                addi.l  #$10000,$2FC(a5)
Boss_BackStringerUpdateManualControlPose:               ; was: loc_44832
                bsr.w   Boss_BackStringerUpdateTailSegmentPositions
                lea     Boss_BackStringerManualControlPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                move.w  #0,$56(a5)
                bra.w   Boss_BackStringerUpdateRender
; End of function Boss_BackStringerManualControlState
; Seeds the position and state used by the scripted entrance
Boss_BackStringerBeginEntrance:                         ; was: sub_4484A
                move.w  #6,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$120,$10(a5)
                move.w  #$1C0,$14(a5)
; Moves through the opening arc until Back Stringer crosses Y $EA
Boss_BackStringerEntranceState:                         ; was: loc_44864
                cmpi.w  #$EA,$14(a5)
                bmi.s   Boss_BackStringerStartOpeningPose
Boss_BackStringerUpdateCircularMotionAndRender:         ; was: loc_4486C
                lea     Boss_BackStringerCircularMotionPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bsr.w   Boss_BackStringerApplyCircularMotion
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartOpeningPose:                      ; was: loc_4487E
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$140,$11C(a5)
                move.b  #$E5,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$1E,(PrimaryEntityState).w
; Plays the timed opening pose while changing the first part radius
Boss_BackStringerOpeningPoseState:                      ; was: loc_448A2
                move.w  #2,(PlaneAShakeLevel).w
                subq.w  #1,$11C(a5)
                bmi.s   Boss_BackStringerStartOpeningDelay
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                addi.w  #8,d0
                move.w  d0,$B4(a5)
                lea     Boss_BackStringerOpeningPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartOpeningDelay:                     ; was: loc_448CC
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$18,$B4(a5)
                move.w  #$30,$11C(a5)                   ; '0'
; Holds the neutral pose for the second opening delay
Boss_BackStringerOpeningDelayState:                     ; was: loc_448E6
                subq.w  #1,$11C(a5)
                bmi.s   Boss_BackStringerStartHalfTurn
                lea     Boss_BackStringerIdlePoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartHalfTurn:                         ; was: loc_448FA
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Rotates the body to angle $100 during the entrance
Boss_BackStringerRotateToHalfTurnState:                 ; was: loc_44908
                addq.w  #8,$56(a5)
                andi.w  #$1F8,$56(a5)
                cmpi.w  #$100,$56(a5)
                beq.s   Boss_BackStringerAdvanceToVerticalThreshold
Boss_BackStringerUseIncreasingAnglePose:                ; was: loc_4491A
                lea     Boss_BackStringerIncreasingAnglePoses(pc),a1
                nop
Boss_BackStringerAnimateCircularMotionAndRender:        ; was: loc_44920
                bsr.w   Boss_BackStringerAnimatePose
                bsr.w   Boss_BackStringerApplyCircularMotion
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerAdvanceToVerticalThreshold:            ; was: loc_4492C
                addq.w  #2,4(a5)
; Continues circular motion until Back Stringer crosses Y $140
Boss_BackStringerWaitForVerticalThresholdState:         ; was: loc_44930
                cmpi.w  #$140,$14(a5)
                bmi.w   Boss_BackStringerUpdateCircularMotionAndRender
                addq.w  #2,4(a5)
; Completes the remaining half-turn and advances at angle zero
Boss_BackStringerRotateToFullTurnState:                 ; was: loc_4493E
                addq.w  #8,$56(a5)
                andi.w  #$1F8,$56(a5)
                bne.w   Boss_BackStringerUseIncreasingAnglePose
                addq.w  #2,4(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; Holds the opening pose before enabling the regular battle loop
Boss_BackStringerPostEntranceDelayState:                ; was: loc_44956
                subq.w  #1,$11C(a5)
                bpl.w   Boss_BackStringerUseOpeningDelayPoseAndRender
                addq.w  #2,4(a5)
                moveq   #1,d0
                jsr     (BossMessage_Start).l
; Waits for the shared battle-start gate, then seeds attack selection
Boss_BackStringerWaitForBattleStartState:               ; was: loc_4496A
                tst.w   (MessageSequenceState).w
                bne.w   Boss_BackStringerUseOpeningDelayPoseAndRender
                clr.b   (BossColorEffectFlags).w
                move.w  #7,$41C(a5)
                move.w  #$FFFF,$47C(a5)
                move.w  #4,$47E(a5)
Boss_BackStringerSelectRotationOrAttack:                ; was: loc_44988
                                        ; Boss_BackStringerDiveRecoveryDelayState+4   j
                subq.w  #1,$41C(a5)
                bpl.s   Boss_BackStringerStartAttackDelay
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                addq.w  #2,d0
                move.w  d0,$41C(a5)
                tst.w   $56(a5)
                bne.w   Boss_BackStringerStartReturnToZeroRotation
                bra.w   Boss_BackStringerStartHalfTurnRotation
; ---------------------------------------------------------------------------
Boss_BackStringerStartAttackDelay:                      ; was: loc_449A8
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                addi.w  #$C,d0
                move.w  d0,$11C(a5)
                move.w  #$16,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Emits falling drops while waiting to choose the next attack family
Boss_BackStringerAttackDelayState:                      ; was: loc_449D0
                bsr.w   Projectile_BackStringerSpawnFallingDrops
                subq.w  #1,$11C(a5)
                bpl.s   Boss_BackStringerUseIdlePoseAndRender
                cmpi.w  #$140,(SecondaryEntityYPos).w
                bpl.w   Boss_BackStringerStartTrackingAttack
                cmpi.w  #$1600,(BossHealth).w
                bmi.w   Boss_BackStringerStartTrackingAttack
                bra.s   Boss_BackStringerStartSweepingAttack
; ---------------------------------------------------------------------------
Boss_BackStringerUseIdlePoseAndRender:                  ; was: loc_449F0
                                        ; Boss_BackStringerDiveRecoveryDelayState+8   j
                lea     Boss_BackStringerIdlePoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerUseOpeningDelayPoseAndRender:          ; was: loc_449FE
                                        ; Boss_BackStringerWaitForBattleStartState+124   j
                lea     Boss_BackStringerOpeningDelayPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartSweepingAttack:                   ; was: loc_44A0C
                move.w  #$18,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $23E(a5)
                clr.w   $58(a5)
                clr.w   $29C(a5)
                move.w  #$FFFF,$C(a5)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #7,d0
                addq.w  #1,d0
                move.w  d0,$17C(a5)
                cmpi.w  #$90,$10(a5)
                bmi.s   Boss_BackStringerAimSweepTowardPlayerX
                cmpi.w  #$1B0,$10(a5)
                bpl.s   Boss_BackStringerAimSweepTowardPlayerX
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Boss_BackStringerChooseRandomSweepDirection
Boss_BackStringerAimSweepTowardPlayerX:                 ; was: loc_44A54
                                        ; Boss_BackStringerStartSweepingAttack+1FE   j
                move.w  (PlayerCenterX).w,d1
                sub.w   $10(a5),d1
                beq.s   Boss_BackStringerChooseRandomSweepDirection
                move.w  d1,$17E(a5)
                bra.s   Boss_BackStringerOrientSweepDirection
; ---------------------------------------------------------------------------
Boss_BackStringerChooseRandomSweepDirection:            ; was: loc_44A64
                                        ; Boss_BackStringerStartSweepingAttack+212   j
                move.w  (RandomNumberState).w,d0
                andi.w  #$8000,d0
                move.w  d0,$17E(a5)
                move.w  #0,$17C(a5)
Boss_BackStringerOrientSweepDirection:                  ; was: loc_44A76
                tst.w   $56(a5)
                beq.s   Boss_BackStringerSweepingAttackState
                neg.w   $17E(a5)
; Drives the pose-script sweep and chooses its exit phase
Boss_BackStringerSweepingAttackState:                   ; was: loc_44A80
                bsr.w   Projectile_BackStringerSpawnFallingDrops
                tst.w   $23E(a5)
                beq.w   Boss_BackStringerAnimateSweepAndRender
                move.w  #$C9E0,d0
                move.w  #$C8C0,d1
                move.w  $29C(a5),d7
                move.w  (PlayerCenterX).w,d2
                sub.w   $10(a5),d2
                tst.w   $56(a5)
                beq.s   Boss_BackStringerCompareSweepDirection
                neg.w   d2
Boss_BackStringerCompareSweepDirection:                 ; was: loc_44AA8
                tst.w   $17E(a5)
                bmi.s   Boss_BackStringerCheckNegativeSweepDirection
                tst.w   d2
                bpl.s   Boss_BackStringerSelectSweepPose
Boss_BackStringerReverseSweepDirection:                 ; was: loc_44AB2
                neg.w   $17E(a5)
                bra.s   Boss_BackStringerSelectSweepPose
; ---------------------------------------------------------------------------
Boss_BackStringerCheckNegativeSweepDirection:           ; was: loc_44AB8
                tst.w   d2
                bpl.s   Boss_BackStringerReverseSweepDirection
Boss_BackStringerSelectSweepPose:                       ; was: loc_44ABC
                                        ; Boss_BackStringerSweepingAttackState+26C   j
                cmpi.w  #1,d7
                bne.s   Boss_BackStringerCheckThirdSweepPose
                tst.w   $17E(a5)
                bpl.s   Boss_BackStringerStoreFirstSweepPose
                exg     d0,d1
Boss_BackStringerStoreFirstSweepPose:                   ; was: loc_44ACA
                move.w  d0,$48(a5)
                bra.s   Boss_BackStringerCheckSweepCompletion
; ---------------------------------------------------------------------------
Boss_BackStringerCheckThirdSweepPose:                   ; was: loc_44AD0
                cmpi.w  #3,d7
                bne.s   Boss_BackStringerCheckSweepCompletion
                tst.w   $17E(a5)
                bpl.s   Boss_BackStringerStoreThirdSweepPose
                exg     d0,d1
Boss_BackStringerStoreThirdSweepPose:                   ; was: loc_44ADE
                move.w  d1,$48(a5)
Boss_BackStringerCheckSweepCompletion:                  ; was: loc_44AE2
                                        ; Boss_BackStringerSweepingAttackState+28A   j
                cmpi.w  #1,d7
                bne.s   Boss_BackStringerAnimateSweepAndRender
                move.w  (PlayerCenterX).w,d0
                sub.w   $10(a5),d0
                bpl.s   Boss_BackStringerNormalizeSweepTargetDistance
                neg.w   d0
Boss_BackStringerNormalizeSweepTargetDistance:          ; was: loc_44AF4
                tst.w   $56(a5)
                bne.s   Boss_BackStringerCheckReverseSweepCompletion
                subq.w  #1,$17C(a5)
                bmi.s   Boss_BackStringerStartTransformation
                cmpi.w  #$30,d0                         ; '0'
                bpl.s   Boss_BackStringerAnimateSweepAndRender
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                beq.s   Boss_BackStringerAnimateSweepAndRender
                bra.s   Boss_BackStringerStartTransformation
; ---------------------------------------------------------------------------
Boss_BackStringerCheckReverseSweepCompletion:           ; was: loc_44B12
                subq.w  #2,$17C(a5)
                bmi.w   Boss_BackStringerStartDivePreparation
                cmpi.w  #$20,d0                         ; ' '
                bmi.w   Boss_BackStringerStartDivePreparation
Boss_BackStringerAnimateSweepAndRender:                 ; was: loc_44B22
                                        ; Boss_BackStringerSweepingAttackState+29C   j
                lea     Boss_BackStringerSweepPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartTransformation:                   ; was: loc_44B30
                                        ; Boss_BackStringerSweepingAttackState+2C6   j
                move.w  #$1A,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CD40,$4A(a5)
                clr.w   $58(a5)
                clr.w   $29C(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$18,$4DC(a5)
; Plays the transformation pose, palette sweep, and paired shot event
Boss_BackStringerTransformationState:                   ; was: loc_44B54
                bsr.w   Boss_BackStringerUpdateTransformationPalette
                tst.w   $4DC(a5)
                bmi.s   Boss_BackStringerUpdateTransformationPose
                subq.w  #1,$4DC(a5)
Boss_BackStringerUpdateTransformationPose:              ; was: loc_44B62
                tst.w   $58(a5)
                bpl.s   Boss_BackStringerUpdateTransformationParts
                move.w  #$13E,$14(a5)
                bra.w   Boss_BackStringerSelectRotationOrAttack
; ---------------------------------------------------------------------------
Boss_BackStringerUpdateTransformationParts:             ; was: loc_44B72
                cmpi.w  #4,$29C(a5)
                bne.s   Boss_BackStringerCheckTransformationContraction
                cmpi.w  #$18,$B4(a5)
                bpl.s   Boss_BackStringerGrowFirstTransformationRadius
                addq.w  #1,$B4(a5)
Boss_BackStringerGrowFirstTransformationRadius:         ; was: loc_44B86
                cmpi.w  #$1F,$114(a5)
                bpl.s   Boss_BackStringerEmitTransformationShots
                addq.w  #1,$114(a5)
Boss_BackStringerEmitTransformationShots:               ; was: loc_44B92
                tst.w   $23E(a5)
                beq.s   Boss_BackStringerCheckTransformationContraction
                bsr.w   Boss_BackStringerSpawnDualAngledShots
                bra.s   Boss_BackStringerAnimateTransformationAndRender
; ---------------------------------------------------------------------------
Boss_BackStringerCheckTransformationContraction:        ; was: loc_44B9E
                                        ; Boss_BackStringerTransformationState+34C   j
                cmpi.w  #2,$29C(a5)
                bne.s   Boss_BackStringerAnimateTransformationAndRender
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_BackStringerAnimateTransformationAndRender
                subq.w  #1,$B4(a5)
                subq.w  #1,$114(a5)
Boss_BackStringerAnimateTransformationAndRender:        ; was: loc_44BB6
                                        ; Boss_BackStringerTransformationState+35A   j
                lea     Boss_BackStringerTransformationPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartDivePreparation:                  ; was: loc_44BC4
                                        ; Boss_BackStringerSweepingAttackState+2D4   j
                move.w  #$1C,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                clr.w   $29C(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$17C(a5)
; Counts down while pulsing the part radii before the tail dive
Boss_BackStringerDivePreparationState:                  ; was: loc_44BE6
                bsr.w   Projectile_BackStringerSpawnFallingDrops
                subq.w  #1,$17C(a5)
                bmi.s   Boss_BackStringerStartDiveAttack
                move.w  #$18,$B4(a5)
                move.w  #$1F,$114(a5)
                btst    #1,$17D(a5)
                beq.s   Boss_BackStringerAnimateDivePreparation
                subq.w  #2,$B4(a5)
                subq.w  #4,$114(a5)
Boss_BackStringerAnimateDivePreparation:                ; was: loc_44C0C
                lea     Boss_BackStringerDivePreparationPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartDiveAttack:                       ; was: loc_44C1A
                addq.w  #2,4(a5)
                move.w  #$CD40,$4A(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$B7,d0
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_BackStringerResetTailSegments
; End of function Boss_BackStringerBeginEntrance
; Extends the tail until it reaches its lower limit or contact state
Boss_BackStringerDiveAttackState:                       ; was: sub_44C3C
                bsr.w   Projectile_BackStringerSpawnFallingDrops
                subi.l  #$16000,$2FC(a5)
                cmpi.w  #$FFE0,$2FC(a5)
                bpl.s   Boss_BackStringerUpdateDiveTail
                tst.w   $29E(a5)
                bne.s   Boss_BackStringerStartDiveRetraction
                bra.w   Boss_BackStringerStartDiveRecoveryDelay
; ---------------------------------------------------------------------------
Boss_BackStringerUpdateDiveTail:                        ; was: loc_44C5A
                                        ; Boss_BackStringerRetractFromDiveState+50   j
                bsr.w   Boss_BackStringerUpdateTailSegmentPositions
                lea     Boss_BackStringerDiveAttackPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartDiveRetraction:                   ; was: loc_44C6C
                addq.w  #2,4(a5)
                move.w  #$13E,$14(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Retracts the extended tail before returning to the attack loop
Boss_BackStringerRetractFromDiveState:                  ; was: loc_44C84
                addi.l  #$10000,$2FC(a5)
                bmi.s   Boss_BackStringerUpdateDiveTail
                cmpi.w  #$12,$2FC(a5)
                bmi.s   Boss_BackStringerUpdateDiveTail
Boss_BackStringerStartDiveRecoveryDelay:                ; was: loc_44C96
                move.w  #$22,4(a5)                      ; '"'
                move.w  #$13E,$14(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #2,$17C(a5)
                bsr.w   Boss_BackStringerRetractTailSegments
; End of function Boss_BackStringerDiveAttackState
; Holds the idle pose briefly after the tail retracts
Boss_BackStringerDiveRecoveryDelayState:                ; was: sub_44CBA
                subq.w  #1,$17C(a5)
                bmi.w   Boss_BackStringerSelectRotationOrAttack
                bra.w   Boss_BackStringerUseIdlePoseAndRender
; End of function Boss_BackStringerDiveRecoveryDelayState
; Starts the attack that returns a nonzero body angle to zero
Boss_BackStringerStartReturnToZeroRotation:             ; was: sub_44CC6
                move.w  #$26,4(a5)                      ; '&'
                bsr.s   Boss_BackStringerInitializeRotationDirection
                bra.s   Boss_BackStringerRotateToZeroAttackState
; End of function Boss_BackStringerStartReturnToZeroRotation
; Starts the attack that rotates an angle-zero body to $100
Boss_BackStringerStartHalfTurnRotation:                 ; was: sub_44CD0
                move.w  #$24,4(a5)                      ; '$'
                bsr.s   Boss_BackStringerInitializeRotationDirection
                bra.s   Boss_BackStringerRotateToHalfTurnAttackState
; End of function Boss_BackStringerStartHalfTurnRotation
; Selects rotation sign from the boss's current horizontal position
Boss_BackStringerInitializeRotationDirection:           ; was: sub_44CDA
                                        ; Boss_BackStringerStartHalfTurnRotation+6   p
                moveq   #8,d0
                cmpi.w  #$120,$10(a5)
                bpl.s   Boss_BackStringerStoreRotationDirection
                moveq   #$FFFFFFF8,d0
Boss_BackStringerStoreRotationDirection:                ; was: loc_44CE6
                move.w  d0,$11C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                rts
; End of function Boss_BackStringerInitializeRotationDirection
; Rotates until the body angle reaches $100
Boss_BackStringerRotateToHalfTurnAttackState:           ; was: sub_44CFE
                cmpi.w  #$100,$56(a5)
                beq.w   Boss_BackStringerSelectRotationOrAttack
                bra.s   Boss_BackStringerUpdateRotationAttack
; End of function Boss_BackStringerRotateToHalfTurnAttackState
; Rotates until the body angle returns to zero
Boss_BackStringerRotateToZeroAttackState:               ; was: sub_44D0A
                tst.w   $56(a5)
                beq.w   Boss_BackStringerSelectRotationOrAttack
Boss_BackStringerUpdateRotationAttack:                  ; was: loc_44D12
                bsr.w   Projectile_BackStringerSpawnFallingDrops
                move.w  $11C(a5),d1
                add.w   d1,$56(a5)
                andi.w  #$1F8,$56(a5)
                lea     Boss_BackStringerIncreasingAnglePoses(pc),a1
                nop
                tst.w   d1
                bpl.s   Boss_BackStringerAnimateRotationAttack
                lea     Boss_BackStringerDecreasingAnglePoses(pc),a1
                nop
Boss_BackStringerAnimateRotationAttack:                 ; was: loc_44D34
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; End of function Boss_BackStringerRotateToZeroAttackState
; Initializes the angle-targeting attack and its warmup
Boss_BackStringerStartTrackingAttack:                   ; was: sub_44D3C
                                        ; Boss_BackStringerAttackDelayState+1A0   j
                move.w  #$2A,4(a5)                      ; '*'
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.w   $58(a5)
                clr.w   $29C(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$180,$11C(a5)
                move.w  #$10,$11E(a5)
                move.w  #$40,$17C(a5)                   ; '@'
; Holds the circular pose before enabling angle tracking
Boss_BackStringerTrackingAttackWarmupState:             ; was: loc_44D6A
                subq.w  #1,$17C(a5)
                bmi.s   Boss_BackStringerStartTrackingMotion
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                lea     Boss_BackStringerCircularMotionPoses(pc),a1
                nop
                bsr.w   Boss_BackStringerAnimatePose
                bra.w   Boss_BackStringerUpdateRender
; ---------------------------------------------------------------------------
Boss_BackStringerStartTrackingMotion:                   ; was: loc_44D8A
                addq.w  #2,4(a5)
                move.b  #$50,$81(a5)                    ; 'P'
                move.b  #$50,$E1(a5)                    ; 'P'
; Chooses a target angle and turns toward it while circling
Boss_BackStringerTrackingAttackState:                   ; was: loc_44D9A
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                move.w  $11C(a5),d2
                sub.w   $56(a5),d2
                bmi.w   Boss_BackStringerCheckNegativeTargetAngleDelta
                bne.w   Boss_BackStringerTurnTowardPositiveTargetAngle
                lea     Boss_BackStringerCircularMotionPoses(pc),a1
                nop
                move.w  #$180,d1
                cmpi.w  #$1A0,$10(a5)
                bpl.s   Boss_BackStringerStoreBoundaryTargetAngle
                move.w  #$80,d1
                cmpi.w  #$A0,$10(a5)
                bmi.s   Boss_BackStringerStoreBoundaryTargetAngle
                move.w  #0,d1
                cmpi.w  #$140,$14(a5)
                bpl.s   Boss_BackStringerStoreBoundaryTargetAngle
                move.w  #$100,d1
                cmpi.w  #$B0,$14(a5)
                bpl.s   Boss_BackStringerUpdateTargetAngleTimer
Boss_BackStringerStoreBoundaryTargetAngle:              ; was: loc_44DEC
                                        ; Boss_BackStringerTrackingAttackState+96   j
                move.w  #$FFFF,$11E(a5)
                move.w  d1,$11C(a5)
                bra.s   Boss_BackStringerApplyTrackingAngle
; ---------------------------------------------------------------------------
Boss_BackStringerUpdateTargetAngleTimer:                ; was: loc_44DF8
                subq.w  #1,$11E(a5)
                bpl.w   Boss_BackStringerApplyTrackingAngle
                btst    #0,(RandomNumberState+1).w
                beq.s   Boss_BackStringerChooseRandomTargetAngle
                jsr     (Math_CalculateAngleToPlayer).l
                addi.w  #$80,d2
                andi.w  #$1F8,d2
                move.w  d2,$11C(a5)
                move.w  #$80,$11E(a5)
                bra.s   Boss_BackStringerApplyTrackingAngle
; ---------------------------------------------------------------------------
Boss_BackStringerChooseRandomTargetAngle:               ; was: loc_44E22
                move.b  (RandomNumberState).w,d0
                andi.w  #$1F8,d0
                move.w  d0,$11C(a5)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                addq.w  #8,d0
                move.w  d0,$11E(a5)
                bra.s   Boss_BackStringerApplyTrackingAngle
; ---------------------------------------------------------------------------
Boss_BackStringerTurnTowardPositiveTargetAngle:         ; was: loc_44E3E
                cmpi.w  #$100,d2
                bpl.w   Boss_BackStringerDecreaseTrackingAngle
Boss_BackStringerIncreaseTrackingAngle:                 ; was: loc_44E46
                addq.w  #8,$56(a5)
                lea     Boss_BackStringerIncreasingAnglePoses(pc),a1
                nop
                bra.s   Boss_BackStringerApplyTrackingAngle
; ---------------------------------------------------------------------------
Boss_BackStringerCheckNegativeTargetAngleDelta:         ; was: loc_44E52
                cmpi.w  #$FF00,d2
                bmi.w   Boss_BackStringerIncreaseTrackingAngle
Boss_BackStringerDecreaseTrackingAngle:                 ; was: loc_44E5A
                subq.w  #8,$56(a5)
                lea     Boss_BackStringerDecreasingAnglePoses(pc),a1
                nop
Boss_BackStringerApplyTrackingAngle:                    ; was: loc_44E64
                                        ; Boss_BackStringerTrackingAttackState+C0   j
                andi.w  #$1F8,$56(a5)
                bra.w   Boss_BackStringerAnimateCircularMotionAndRender
; End of function Boss_BackStringerTrackingAttackState
; Initializes defeat flags and emits the detached chain objects
Boss_BackStringerDefeatInit:                            ; was: sub_44E6E
                move.b  #1,(SoundFadeOutDelay).w
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                move.w  #8,(StageSpawnCountdown).w
                clr.w   8(a5)
                move.w  #6,(PlaneAShakeLevel).w
                move.w  #6,(PlaneBShakeLevel).w
                move.w  #$28,4(a5)                      ; '('
                clr.w   2(a5)
                clr.b   $21(a5)
                move.w  #$280,$48(a5)
                move.w  #0,$AA(a5)
                move.w  #$10,$10A(a5)
                movea.w #(QuaternaryEntityType-M68K_RAM),a0
                lea     (Math_SineTable).l,a1
                moveq   #$20,d4                         ; ' '
                moveq   #0,d0
                moveq   #1,d7
                bsr.s   Boss_BackStringerInitializeDefeatChainObjects
                moveq   #2,d0
                moveq   #$11,d7
; End of function Boss_BackStringerDefeatInit
; Initializes groups of detached chain objects with sine-derived velocity
Boss_BackStringerInitializeDefeatChainObjects:          ; was: sub_44ECC
                                        ; Boss_BackStringerInitializeDefeatChainObjects+40   j
                move.w  #$358,(a0)
                move.w  #$CC00,2(a0)
                clr.b   $21(a0)
                move.w  d0,$48(a0)
                move.w  $56(a0),d1
                move.w  -$80(a1,d1.w),d2
                move.w  (a1,d1.w),d3
                ext.l   d2
                ext.l   d3
                asl.l   #3,d2
                asl.l   #4,d3
                move.l  d2,$1C(a0)
                move.l  d3,$18(a0)
                addi.l  #-$30000,$1C(a0)
                neg.w   d4
                move.w  d4,$5C(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BackStringerInitializeDefeatChainObjects
                rts
; End of function Boss_BackStringerInitializeDefeatChainObjects
; Runs the timed defeat sound, palette fade, and encounter completion
Boss_BackStringerDefeatFadeOutState:                    ; was: sub_44F12
                subq.w  #1,$48(a5)
                cmpi.w  #$100,$48(a5)
                bmi.s   Boss_BackStringerCompleteDefeat
                cmpi.w  #$27E,$48(a5)
                bne.s   Boss_BackStringerCheckDefeatPhaseThreshold
                move.b  #$B8,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_BackStringerCheckDefeatPhaseThreshold:             ; was: loc_44F30
                cmpi.w  #$1E0,$48(a5)
                bne.s   Boss_BackStringerUpdateDefeatFade
                move.w  #$2E,(MessageSequenceState).w   ; '.'
Boss_BackStringerUpdateDefeatFade:                      ; was: loc_44F3E
                jmp     (Gfx_UpdateRandomizedPaletteRange).l
; ---------------------------------------------------------------------------
Boss_BackStringerCompleteDefeat:                        ; was: loc_44F44
                bset    #4,2(a5)
                addq.w  #2,(StageStateOffset).w
                rts
; End of function Boss_BackStringerDefeatFadeOutState
; Updates boss rendering
