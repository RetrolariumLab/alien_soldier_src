; Deep Strider controller, attack states, and linked-part rendering
Boss_DeepStriderMain:                                   ; was: sub_3E582
                tst.w   4(a5)
                beq.w   Boss_DeepStriderStateDispatch
                tst.w   8(a5)
                beq.s   Boss_DeepStriderStateDispatch
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_DeepStriderUpdateStageRelativeX
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_DeepStriderUpdateStageRelativeX
                tst.w   (BossHealth).w
                beq.w   Boss_DeepStriderBeginDefeat
Boss_DeepStriderUpdateStageRelativeX:                   ; was: loc_3E5A8
                                        ; Boss_DeepStriderMain+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
; State machine dispatcher for Deep Strider boss
Boss_DeepStriderStateDispatch:                          ; was: loc_3E5BA
                                        ; Boss_DeepStriderMain+C   j
                move.w  4(a5),d0
                movea.w Boss_DeepStriderStateOffsets(pc,d0.w),a0
                adda.l  #Boss_DeepStriderInit,a0
                jmp     (a0)
; End of function Boss_DeepStriderMain
; ---------------------------------------------------------------------------
Boss_DeepStriderStateOffsets:   dc.w    Boss_DeepStriderInit-Boss_DeepStriderInit  ; was: off_3E5CA
                dc.w    Boss_DeepStriderIntroRise-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderIntroRisingState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderIntroRiseDelayState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderIntroDiveState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderIntroLaunchSetupState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderIntroArcLandingState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderIntroPoseAlignmentState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderBattleEntryPoseState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderBattleEntryDelayState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderBattleDescendState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderBattleDescentDelayState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderBattleAscendState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderBattleDecisionState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderDiveAttackState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderDefeatFallState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderDefeatRiseState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderDefeatBurstState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderDefeatCompletionDelayState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderHoverAndShootState-Boss_DeepStriderInit
                dc.w    Boss_DeepStriderHoverExitRiseState-Boss_DeepStriderInit

; Initializes Deep Strider boss state
Boss_DeepStriderInit:                                   ; was: sub_3E5F4
                                        ; ROM:Boss_DeepStriderStateOffsets   o
                addq.w  #2,4(a5)
                clr.w   8(a5)
; End of function Boss_DeepStriderInit
; Clears sprites except boss
Boss_DeepStriderClearStageObjects:                      ; was: sub_3E5FC
                move.w  #$19C,d0
                move.w  #$208,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; End of function Boss_DeepStriderClearStageObjects
; Boss intro rise sequence
Boss_DeepStriderIntroRise:                              ; was: sub_3E60A
                addq.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$D,d7
                movea.l #Boss_DeepStriderMetaspriteDescriptors,a0
                movea.l #Boss_DeepStriderPartRadii,a1
                movea.l #Boss_DeepStriderPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$19C,(a5)
                bset    #0,$2A2(a5)
                move.w  #$D00,$4E2(a5)
                lea     (Boss_DeepStriderObjectInitTable).l,a1
                jsr     (Object_InitGroupFromTable).l
                move.w  #4,4(a5)
                move.w  #$180,$536(a5)
                move.w  #$B8,$4F0(a5)
                move.w  #$60,$4F4(a5)                   ; '`'
                move.w  #$CB00,$48(a5)
                move.w  #$CB00,$4A(a5)
                move.w  #$100,$54(a5)
                move.w  #$80,$56(a5)
                move.w  #$1E2,$1DC(a5)
                move.w  #$1E0,$23C(a5)
                move.w  #$20,$1DE(a5)                   ; ' '
                move.w  #$1E0,$23E(a5)
                move.l  #$12000,$4FC(a5)
                clr.w   $11C(a5)
; Deep Strider intro rising with projectiles
Boss_DeepStriderIntroRisingState:                       ; was: loc_3E6A0
                tst.w   $11C(a5)
                bne.s   Boss_DeepStriderAdvanceIntroRise
                cmpi.w  #$110,$4F4(a5)
                bmi.s   Boss_DeepStriderAdvanceIntroRise
                addq.w  #1,$11C(a5)
                move.b  #$4D,d0                         ; 'M'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_DeepStriderSpawnQuadVolley
Boss_DeepStriderAdvanceIntroRise:                       ; was: loc_3E6C0
                                        ; Boss_DeepStriderIntroRise+A2   j
                addq.w  #1,$1DC(a5)
                addi.l  #$3C00,$4FC(a5)
                cmpi.w  #$1E0,$4F4(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                clr.l   $4FC(a5)
                move.w  #$34,$11C(a5)                   ; '4'
; Waits during intro rise before next state
Boss_DeepStriderIntroRiseDelayState:                    ; was: loc_3E6E4
                subq.w  #1,$11C(a5)
                bpl.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                move.w  #2,$29C(a5)
                move.w  #$100,$54(a5)
                bsr.w   Boss_DeepStriderSetupDivePositionAndVelocity
; End of function Boss_DeepStriderIntroRise
; Boss intro dive sequence
Boss_DeepStriderIntroDiveState:                         ; was: sub_3E700
                bsr.w   Boss_DeepStriderDiveSequence
                bmi.w   Boss_DeepStriderMotionStateReturn
                addq.w  #2,4(a5)
                clr.l   $4F8(a5)
                clr.l   $4FC(a5)
                move.w  #$38,$11C(a5)                   ; '8'
; Sets up dive parameters and velocities
Boss_DeepStriderIntroLaunchSetupState:                  ; was: loc_3E71A
                subq.w  #1,$11C(a5)
                bpl.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                move.w  #$198,$4F0(a5)
                move.w  #$160,$4F4(a5)
                clr.w   $54(a5)
                move.w  #$1A0,$56(a5)
                move.w  #$28,$1DC(a5)                   ; '('
                move.w  #$1E0,$23C(a5)
                move.w  #$20,$1DE(a5)                   ; ' '
                move.w  #0,$23E(a5)
                move.l  #$FFFF0000,$4F8(a5)
                move.l  #$FFF80000,$4FC(a5)
                clr.w   $11C(a5)
                move.b  #$4C,d0                         ; 'L'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_DeepStriderSpawnQuadVolley
; End of function Boss_DeepStriderIntroDiveState
; Lands the introductory launch arc before aligning the battle-entry pose
Boss_DeepStriderIntroArcLandingState:                   ; was: sub_3E776
                subq.w  #1,$1DE(a5)
                subq.w  #1,$1DC(a5)
                subq.w  #1,$56(a5)
                addi.l  #$3800,$4FC(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                cmpi.w  #$120,$2B4(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                move.w  #$120,$2B4(a5)
                move.w  #$C8C0,$48(a5)
                move.w  #$C8C0,$4A(a5)
                clr.l   $4F8(a5)
                clr.l   $4FC(a5)
; Aligns the linked-part pose before the battle-entry sequence
Boss_DeepStriderIntroPoseAlignmentState:                ; was: loc_3E7B6
                subq.w  #6,$56(a5)
                subq.w  #2,$1DC(a5)
                andi.w  #$1FE,$1DC(a5)
                cmpi.w  #$1E0,$1DC(a5)
                bne.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
                clr.w   $11E(a5)
                clr.w   $17C(a5)
                moveq   #0,d0
                jsr     (BossMessage_Start).l
                bra.s   Boss_DeepStriderBattleEntryPoseState
; End of function Boss_DeepStriderIntroArcLandingState
; Holds the battle-entry pose before starting the repeating attack cycle
Boss_DeepStriderBattleEntryDelayState:                  ; was: sub_3E7E8
                subq.w  #1,$17E(a5)
                bpl.s   Boss_DeepStriderUpdateBattleEntryPose
                bra.w   Boss_DeepStriderBeginBattleCycle
; End of function Boss_DeepStriderBattleEntryDelayState
; Oscillates the linked-part pose while waiting for the battle-entry sequence
Boss_DeepStriderBattleEntryPoseState:                   ; was: sub_3E7F2
                tst.w   (MessageSequenceState).w
                bne.s   Boss_DeepStriderUpdateBattleEntryPose
                addq.w  #2,4(a5)
                move.w  #$40,$17E(a5)                   ; '@'
                clr.b   (BossColorEffectFlags).w
                subi.w  #$A0,(CameraXLowerBound).w
Boss_DeepStriderUpdateBattleEntryPose:                  ; was: loc_3E80C
                                        ; Boss_DeepStriderBattleEntryPoseState+4   j
                andi.w  #$1FC,$1DE(a5)
                tst.w   $11E(a5)
                bpl.s   Boss_DeepStriderCountDownBattleEntryPause
                tst.w   $17C(a5)
                bne.s   Boss_DeepStriderAdjustNegativeBattleEntryPose
                cmpi.w  #$1E0,$1DE(a5)
                beq.s   Boss_DeepStriderRotatePositiveBattleEntryPose
                addq.w  #4,$1DE(a5)
Boss_DeepStriderRotatePositiveBattleEntryPose:          ; was: loc_3E82A
                addq.w  #3,$56(a5)
                addq.w  #2,$1DC(a5)
                cmpi.w  #$1FA,$1DC(a5)
                bpl.s   Boss_DeepStriderRandomizeNextBattleEntryPose
                subq.w  #1,$11C(a5)
                bmi.s   Boss_DeepStriderRandomizeNextBattleEntryPose
                bra.w   Boss_DeepStriderUpdateParts
; ---------------------------------------------------------------------------
Boss_DeepStriderAdjustNegativeBattleEntryPose:          ; was: loc_3E844
                cmpi.w  #$1C0,$1DE(a5)
                beq.s   Boss_DeepStriderRotateNegativeBattleEntryPose
                subq.w  #4,$1DE(a5)
Boss_DeepStriderRotateNegativeBattleEntryPose:          ; was: loc_3E850
                subq.w  #3,$56(a5)
                subq.w  #2,$1DC(a5)
                cmpi.w  #$1D8,$1DC(a5)
                bmi.s   Boss_DeepStriderRandomizeNextBattleEntryPose
                subq.w  #1,$11C(a5)
                bmi.s   Boss_DeepStriderRandomizeNextBattleEntryPose
                bra.w   Boss_DeepStriderUpdateParts
; ---------------------------------------------------------------------------
Boss_DeepStriderCountDownBattleEntryPause:              ; was: loc_3E86A
                subq.w  #1,$11E(a5)
                bra.w   Boss_DeepStriderUpdateParts
; ---------------------------------------------------------------------------
Boss_DeepStriderRandomizeNextBattleEntryPose:           ; was: loc_3E872
                                        ; Boss_DeepStriderBattleEntryPoseState+4C   j
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                addq.w  #6,d0
                move.w  d0,$11C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                move.w  d0,$11E(a5)
                eori.w  #1,$17C(a5)
                bra.w   Boss_DeepStriderUpdateParts
; End of function Boss_DeepStriderBattleEntryPoseState
; Main battle logic with attack patterns and phase transitions
Boss_DeepStriderBeginBattleCycle:                       ; was: sub_3E896
                addq.w  #2,4(a5)
                move.w  #2,$11C(a5)
                move.w  #$80,$536(a5)
; Deep Strider battle descend with rotation
Boss_DeepStriderBattleDescendState:                     ; was: loc_3E8A6
                andi.w  #$1FC,$1DE(a5)
                cmpi.w  #$1C0,$1DE(a5)
                beq.s   Boss_DeepStriderContinueBattleDescent
                subq.w  #4,$1DE(a5)
Boss_DeepStriderContinueBattleDescent:                  ; was: loc_3E8B8
                subq.w  #3,$56(a5)
                subq.w  #2,$1DC(a5)
                cmpi.w  #$1CC,$1DC(a5)
                bpl.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
; Deep Strider battle wait timer
Boss_DeepStriderBattleDescentDelayState:                ; was: loc_3E8CE
                subq.w  #1,$11C(a5)
                bpl.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                clr.w   $11E(a5)
                addq.w  #2,$29C(a5)
                move.w  #$CB00,$48(a5)
                move.w  #$CB00,$4A(a5)
                move.l  #$1E000,$4F8(a5)
                move.l  #$FFFB0000,$4FC(a5)
                bclr    #0,$2A2(a5)
; Deep Strider battle ascend with projectiles
Boss_DeepStriderBattleAscendState:                      ; was: loc_3E90A
                tst.w   $11E(a5)
                bne.s   Boss_DeepStriderAdvanceBattleAscent
                cmpi.w  #$150,$4F4(a5)
                bmi.s   Boss_DeepStriderAdvanceBattleAscent
                addq.w  #1,$11E(a5)
                move.b  #$4D,d0                         ; 'M'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_DeepStriderSpawnQuadVolley
Boss_DeepStriderAdvanceBattleAscent:                    ; was: loc_3E92A
                                        ; Boss_DeepStriderBeginBattleCycle+80   j
                addq.w  #6,$56(a5)
                addq.w  #1,$1DC(a5)
                subi.l  #$C00,$4F8(a5)
                addi.l  #$3C00,$4FC(a5)
                cmpi.w  #$1E0,$4F4(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                move.w  #$B,$17C(a5)
Boss_DeepStriderBeginBattleDecisionState:               ; was: loc_3E952
                                        ; Boss_DeepStriderDiveAttackState+10   j
                move.w  #$1A,4(a5)
                bclr    #0,(ForcedPositionFlags).w
                move.b  #$10,$141(a5)
                move.w  #$18,$534(a5)
                move.w  #$CB00,$48(a5)
                move.w  #$CB00,$4A(a5)
                clr.l   $4F8(a5)
                clr.l   $4FC(a5)
                tst.w   (DifficultyMode).w
                bne.s   Boss_DeepStriderRandomizeBattleDecisionDelay
                move.w  #$10,$11C(a5)
                bra.s   Boss_DeepStriderBattleDecisionState
; ---------------------------------------------------------------------------
Boss_DeepStriderRandomizeBattleDecisionDelay:           ; was: loc_3E98C
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addq.w  #4,d0
                move.w  d0,$11C(a5)
; Idle timer before attack selection
Boss_DeepStriderBattleDecisionState:                    ; was: loc_3E99A
                subq.w  #1,$11C(a5)
                bpl.w   Boss_DeepStriderUpdateParts
                subq.w  #1,$17C(a5)
                cmpi.w  #$A,$17C(a5)
                bpl.w   Boss_DeepStriderBeginDiveAttack
                tst.w   $17C(a5)
                bmi.w   Boss_DeepStriderBeginHoverAndShoot
                btst    #0,(PlayerActionStateFlags).w
                beq.w   Boss_DeepStriderBeginDiveAttack
                moveq   #7,d0
                btst    #6,(PlayerActionStateFlags).w
                beq.w   Boss_DeepStriderTestDiveRandomSelection
                moveq   #1,d0
Boss_DeepStriderTestDiveRandomSelection:                ; was: loc_3E9D0
                move.w  (RandomNumberState).w,d1
                and.w   d0,d1
                beq.s   Boss_DeepStriderBeginHoverAndShoot
                bra.w   Boss_DeepStriderBeginDiveAttack
; ---------------------------------------------------------------------------
Boss_DeepStriderBeginHoverAndShoot:                     ; was: loc_3E9DC
                                        ; Boss_DeepStriderBeginBattleCycle+140   j
                move.w  #$26,4(a5)                      ; '&'
                move.w  #1,$534(a5)
                clr.w   $11C(a5)
                clr.w   $11E(a5)
                move.w  #$BF,$17C(a5)
                move.w  #$180,$56(a5)
                move.w  #$180,$536(a5)
                move.w  #$1F4,$1DC(a5)
                clr.w   $23C(a5)
                move.w  #$1E0,$1DE(a5)
                bsr.w   Boss_DeepStriderCalculatePhaseDiveX
                move.w  d0,$4F0(a5)
                move.w  #$1B0,$4F4(a5)
; Deep Strider hovering with angle firing
Boss_DeepStriderHoverAndShootState:                     ; was: loc_3EA20
                jsr     (Physics_GetPlayerDelta).l
                move.w  #$100,$54(a5)
                tst.w   d1
                bpl.s   Boss_DeepStriderApplyHoverFacing
                clr.w   $54(a5)
Boss_DeepStriderApplyHoverFacing:                       ; was: loc_3EA34
                tst.w   $11E(a5)
                bne.s   Boss_DeepStriderDecreaseHoverJointAngle
                addq.w  #1,$56(a5)
                cmpi.w  #$190,$56(a5)
                beq.s   Boss_DeepStriderReverseHoverJointMotion
                bra.s   Boss_DeepStriderUpdateHoverVerticalMotion
; ---------------------------------------------------------------------------
Boss_DeepStriderDecreaseHoverJointAngle:                ; was: loc_3EA48
                subq.w  #1,$56(a5)
                cmpi.w  #$178,$56(a5)
                bne.s   Boss_DeepStriderUpdateHoverVerticalMotion
Boss_DeepStriderReverseHoverJointMotion:                ; was: loc_3EA54
                eori.w  #1,$11E(a5)
Boss_DeepStriderUpdateHoverVerticalMotion:              ; was: loc_3EA5A
                                        ; Boss_DeepStriderBeginBattleCycle+1BC   j
                tst.w   $11C(a5)
                beq.s   Boss_DeepStriderAccelerateHoverUpward
                addi.l  #$C00,$4FC(a5)
                bmi.s   Boss_DeepStriderCheckHoverDownwardHeight
                cmpi.l  #$10000,$4FC(a5)
                bmi.s   Boss_DeepStriderCheckHoverDownwardHeight
                move.l  #$10000,$4FC(a5)
Boss_DeepStriderCheckHoverDownwardHeight:               ; was: loc_3EA7C
                                        ; Boss_DeepStriderBeginBattleCycle+1DC   j
                cmpi.w  #$160,$4F4(a5)
                bmi.s   Boss_DeepStriderUpdateHoverAttack
                tst.w   $17C(a5)
                bmi.w   Boss_DeepStriderBeginHoverExitRise
                bra.s   Boss_DeepStriderReverseHoverVerticalMotion
; ---------------------------------------------------------------------------
Boss_DeepStriderAccelerateHoverUpward:                  ; was: loc_3EA8E
                subi.l  #$1000,$4FC(a5)
                bpl.s   Boss_DeepStriderCheckHoverUpwardHeight
                cmpi.l  #$FFFF0000,$4FC(a5)
                bpl.s   Boss_DeepStriderCheckHoverUpwardHeight
                move.l  #$FFFF0000,$4FC(a5)
Boss_DeepStriderCheckHoverUpwardHeight:                 ; was: loc_3EAAA
                                        ; Boss_DeepStriderBeginBattleCycle+20A   j
                cmpi.w  #$170,$4F4(a5)
                bpl.s   Boss_DeepStriderUpdateHoverAttack
Boss_DeepStriderReverseHoverVerticalMotion:             ; was: loc_3EAB2
                eori.w  #1,$11C(a5)
Boss_DeepStriderUpdateHoverAttack:                      ; was: loc_3EAB8
                                        ; Boss_DeepStriderBeginBattleCycle+21A   j
                subq.w  #1,$17C(a5)
                cmpi.w  #$9F,$17C(a5)
                bpl.w   Boss_DeepStriderUpdateParts
                bsr.w   Boss_DeepStriderFireAngleProjectile
                bra.w   Boss_DeepStriderUpdateParts
; ---------------------------------------------------------------------------
Boss_DeepStriderBeginHoverExitRise:                     ; was: loc_3EACE
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
                move.l  #$FFFB0000,$4FC(a5)
                move.b  #$4C,d0                         ; 'L'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_DeepStriderSpawnQuadVolley
                move.w  #$B,$17C(a5)
; Deep Strider post-dive rising with scroll
Boss_DeepStriderHoverExitRiseState:                     ; was: loc_3EAF2
                addq.w  #1,$11C(a5)
                addi.l  #$3A00,$4FC(a5)
                subq.w  #8,$56(a5)
                subq.w  #1,$1DC(a5)
                cmpi.w  #$18,$11C(a5)
                bmi.s   Boss_DeepStriderCheckHoverExitHeight
                addq.w  #2,$1DC(a5)
                addq.w  #4,$56(a5)
Boss_DeepStriderCheckHoverExitHeight:                   ; was: loc_3EB16
                cmpi.w  #$1C0,$4F4(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                bra.w   Boss_DeepStriderBeginBattleDecisionState
; ---------------------------------------------------------------------------
Boss_DeepStriderBeginDiveAttack:                        ; was: loc_3EB24
                                        ; Boss_DeepStriderBeginBattleCycle+128   j
                move.b  #$12,$141(a5)
                clr.w   $17E(a5)
                move.w  #$1C,4(a5)
                move.w  $29C(a5),d0
                beq.s   Boss_DeepStriderSetNonzeroDiveFacing
                cmpi.w  #4,d0
                bpl.s   Boss_DeepStriderSetZeroDiveFacing
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Boss_DeepStriderSetNonzeroDiveFacing
Boss_DeepStriderSetZeroDiveFacing:                      ; was: loc_3EB4A
                clr.w   $54(a5)
                bra.s   Boss_DeepStriderInitializeDiveMotion
; ---------------------------------------------------------------------------
Boss_DeepStriderSetNonzeroDiveFacing:                   ; was: loc_3EB50
                                        ; Boss_DeepStriderBeginBattleCycle+2B2   j
                move.w  #$100,$54(a5)
Boss_DeepStriderInitializeDiveMotion:                   ; was: loc_3EB56
                bsr.w   Boss_DeepStriderSetupDivePositionAndVelocity
; End of function Boss_DeepStriderBeginBattleCycle
; Checks dive completion and damage state
Boss_DeepStriderDiveAttackState:                        ; was: sub_3EB5A
                bsr.w   Boss_DeepStriderDiveSequence
                bmi.s   Boss_DeepStriderUpdateDiveImpactSignal
                tst.w   $54(a5)
                bne.s   Boss_DeepStriderAdvanceDivePhaseIndex
                subq.w  #2,$29C(a5)
                bra.w   Boss_DeepStriderBeginBattleDecisionState
; ---------------------------------------------------------------------------
Boss_DeepStriderAdvanceDivePhaseIndex:                  ; was: loc_3EB6E
                addq.w  #2,$29C(a5)
                bra.w   Boss_DeepStriderBeginBattleDecisionState
; ---------------------------------------------------------------------------
Boss_DeepStriderUpdateDiveImpactSignal:                 ; was: loc_3EB76
                tst.w   $17E(a5)
                bne.s   Boss_DeepStriderPollDiveImpactSignal
                bclr    #1,$142(a5)
                beq.s   Boss_DeepStriderDiveAttackStateReturn
                bset    #1,(ForcedPositionFlags).w
                move.w  #2,$17E(a5)
Boss_DeepStriderPollDiveImpactSignal:                   ; was: loc_3EB90
                bclr    #1,(ForcedPositionFlags).w
                bne.s   Boss_DeepStriderPublishDiveImpactPosition
                clr.w   $17E(a5)
                rts
; ---------------------------------------------------------------------------
Boss_DeepStriderPublishDiveImpactPosition:              ; was: loc_3EB9E
                move.w  #$64,(ForcedPositionTimer).w    ; 'd'
                bset    #0,(ForcedPositionFlags).w
                bset    #2,(ForcedPositionFlags).w
                move.w  $130(a5),d0
                addi.w  #0,d0
                move.w  d0,(ForcedPositionX).w
                move.w  $134(a5),d0
                addi.w  #0,d0
                move.w  d0,(ForcedPositionY).w
Boss_DeepStriderDiveAttackStateReturn:                  ; was: locret_3EBC8
                rts
; End of function Boss_DeepStriderDiveAttackState
