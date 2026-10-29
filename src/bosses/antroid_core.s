; Main Antroid boss handler dispatching to state routines
Boss_AntroidMainHandler:                                ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_374C6
                tst.w   4(a5)
                beq.w   Boss_AntroidStateDispatch
                tst.w   8(a5)
                beq.s   Boss_AntroidStateDispatch
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_AntroidMainUpdateActive
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_AntroidMainUpdateActive
                tst.w   (BossHealth).w
                beq.w   Boss_AntroidBeginRamAttack
Boss_AntroidMainUpdateActive:                           ; CODE XREF: Boss_AntroidMainHandler+14   j  ; was: loc_374EC
                                        ; Boss_AntroidMainHandler+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
; State dispatcher for Antroid boss using jump table
Boss_AntroidStateDispatch:                              ; CODE XREF: Boss_AntroidMainHandler+4   j  ; was: loc_374FE
                                        ; Boss_AntroidMainHandler+C   j
                move.w  4(a5),d0
                movea.w Boss_AntroidStateHandlers(pc,d0.w),a0
                adda.l  #Boss_AntroidClearOtherObjectsState,a0
                jmp     (a0)
; End of function Boss_AntroidMainHandler
; ---------------------------------------------------------------------------
Boss_AntroidStateHandlers:  dc.w    Boss_AntroidClearOtherObjectsState-Boss_AntroidClearOtherObjectsState  ; was: off_3750E
                                        ; DATA XREF: Boss_AntroidMainHandler+3C   r
                dc.w    Boss_AntroidInitializeBattleState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidNeutralState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidBattleDecision-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidPrepareLeapAttackA-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidLeapAttackA-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidPrepareLeapAttackB-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidLeapAttackB-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidPrepareJumpAttack-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpAttackApplyGravity-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpAttackLandingState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidWaitState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidWaitCountdown-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidPhaseGateState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidWaitForStageReady-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidRamAttack-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidDefeatFadeState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidDefeatDelayState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidIdleState-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpSlamAttack-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpSlamApplyGravity-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpSlamDecelerateHorizontal-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpSlamApplySecondArcGravity-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpSlamImpactDelay-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidJumpSlamRetryWait-Boss_AntroidClearOtherObjectsState
                dc.w    Boss_AntroidHealthRecoveryState-Boss_AntroidClearOtherObjectsState

; Advances initialization after clearing every object type below Antroid's type
Boss_AntroidClearOtherObjectsState:                     ; DATA XREF: Boss_AntroidMainHandler+40   o  ; was: sub_37542
                                        ; ROM:Boss_AntroidStateHandlers   o
                addq.w  #2,4(a5)
                clr.w   8(a5)
                move.w  #$30,d0                         ; '0'
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                rts
; End of function Boss_AntroidClearOtherObjectsState
; Builds Antroid's linked parts and enters the first battle preparation state
Boss_AntroidInitializeBattleState:                      ; DATA XREF: ROM:00037510   o  ; was: sub_37558
                addq.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$8300,(MetaspriteBaseTileWord).w
                moveq   #$E,d7
                movea.l #Boss_AntroidPrimaryMetaspriteDescriptors,a0
                movea.l #Boss_AntroidPrimaryPartRadii,a1
                movea.l #Boss_AntroidPrimaryPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                moveq   #$A,d7
                movea.l #Boss_AntroidSecondaryMetaspriteDescriptors,a0
                movea.l #Boss_AntroidSecondaryPartRadii,a1
                movea.l #Boss_AntroidSecondaryPartLinks,a2
                jsr     (Sprite_InitializeAdditionalLinkedMetaspriteParts).l
                move.w  #$30,(a5)                       ; '0'
                move.w  #$8D00,2(a5)
                move.w  #$C100,$962(a5)
                move.w  #$C100,$542(a5)
                move.w  #$2C8,$550(a5)
                clr.w   6(a5)
                movea.l #Boss_AntroidObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                move.w  #2,$1DE(a5)
                move.w  #$100,$54(a5)
                bsr.w   Boss_AntroidApplyFacingToParts
                bra.w   Boss_AntroidEnterLeapAttackAPreparation
; ---------------------------------------------------------------------------
Boss_AntroidBeginPhaseGate:                             ; CODE XREF: Boss_AntroidReturnToNeutral+62   j  ; was: loc_375D8
                move.w  #$1A,4(a5)
                move.w  #$30,$11C(a5)                   ; '0'
; Advance the phase gate and start the boss-message sequence
Boss_AntroidPhaseGateState:                             ; DATA XREF: ROM:00037528   o  ; was: loc_375E4
                subq.w  #1,$11C(a5)
                bmi.s   Boss_AntroidPhaseGateAdvance
                addq.w  #2,4(a5)
                moveq   #1,d0
                jsr     (BossMessage_Start).l
                bra.w   Boss_AntroidUpdateDecisionAnimation
; ---------------------------------------------------------------------------
Boss_AntroidPhaseGateAdvance:                           ; CODE XREF: Boss_AntroidInitializeBattleState+90   j  ; was: loc_375FA
                addq.w  #2,4(a5)
; Waits for the stage-ready flag before restoring battle state
Boss_AntroidWaitForStageReady:                          ; DATA XREF: ROM:0003752A   o  ; was: loc_375FE
                tst.w   (MessageSequenceState).w
                bne.s   Boss_AntroidWaitForStageReadyAnimate
                clr.b   (BossColorEffectFlags).w
                subi.w  #$40,(CameraXLowerBound).w      ; '@'
                clr.w   $1DE(a5)
                move.w  #6,4(a5)
                move.w  #$30,$11C(a5)                   ; '0'
                bra.w   Boss_AntroidBattleDecision
; ---------------------------------------------------------------------------
Boss_AntroidWaitForStageReadyAnimate:                   ; CODE XREF: Boss_AntroidInitializeBattleState+AA   j  ; was: loc_37622
                bra.w   Boss_AntroidUpdateDecisionAnimation
; End of function Boss_AntroidInitializeBattleState
; Orphaned entry that initializes an idle pose and falls through to state $24
UnreferencedInitializeAntroidIdleState:                 ; was: sub_37626
                move.w  #$24,4(a5)                      ; '$'
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$120,$10(a5)
                move.w  #$F0,$14(a5)
                clr.w   $54(a5)
                bsr.w   Boss_AntroidApplyFacingToParts
; Falls through to the ordinary state-$24 updater
; Updates Antroid's idle pose and linked sprites without advancing state
Boss_AntroidIdleState:                                  ; DATA XREF: ROM:00037532   o  ; was: sub_37648
                lea     Boss_AntroidIdlePoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderBlinkingPose
; End of function Boss_AntroidIdleState
; Restores Antroid's neutral pose and resumes attack selection
Boss_AntroidReturnToNeutral:                            ; CODE XREF: Boss_AntroidPrepareJumpAttack+CA   j  ; was: sub_37656
                move.w  $58(a5),(AntroidPoseOffsetTemp).w
                move.w  $C(a5),(AntroidPoseTimerTemp).w
                moveq   #4,d0
                bsr.w   Boss_AntroidEnterStateWithFirstPartSlot
                move.w  (AntroidPoseOffsetTemp).w,$58(a5)
                move.w  (AntroidPoseTimerTemp).w,$C(a5)
                bra.s   Boss_AntroidReturnToNeutralClearPhase
; ---------------------------------------------------------------------------
Boss_AntroidReturnToNeutralLoadAnimation:               ; CODE XREF: Boss_AntroidHealthRecoveryState+4   j  ; was: loc_37676
                                        ; Boss_AntroidLeapAttackA+54   j
                moveq   #4,d0
                bsr.w   Boss_AntroidEnterStateWithFirstPartSlot
Boss_AntroidReturnToNeutralClearPhase:                  ; CODE XREF: Boss_AntroidReturnToNeutral+1E   j  ; was: loc_3767C
                clr.w   $23C(a5)
; Updates Antroid's neutral pose, linked sprite, and facing direction
Boss_AntroidNeutralState:                               ; CODE XREF: Boss_AntroidWaitState+5E   j  ; was: loc_37680
                                        ; DATA XREF: ROM:00037512   o
                tst.w   $58(a5)
                bmi.s   Boss_AntroidFinishNeutralAnimation
                lea     Boss_AntroidReturnPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderBlinkingPose
                movea.w $11E(a5),a0
                move.l  #Boss_AntroidSecondaryRotationFrame00,8(a0)
                rts
; ---------------------------------------------------------------------------
Boss_AntroidFinishNeutralAnimation:                     ; CODE XREF: Boss_AntroidReturnToNeutral+2E   j  ; was: loc_376A2
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $29C(a5)
                move.w  a5,$48(a5)
                tst.w   $1DE(a5)
                bne.w   Boss_AntroidBeginPhaseGate
                addq.w  #2,4(a5)
                move.w  #$1E0,d0
                sub.w   (BossCombatCounter).w,d0
                asr.w   #5,d0
                addq.w  #2,d0
                move.w  d0,$11C(a5)
; Battle decision logic choosing attack based on distance and random
Boss_AntroidBattleDecision:                             ; CODE XREF: Boss_AntroidInitializeBattleState+C6   j  ; was: loc_376D0
                                        ; DATA XREF: ROM:00037514   o
                subq.w  #1,$11C(a5)
                bpl.s   Boss_AntroidUpdateDecisionAnimation
                tst.w   $23E(a5)
                beq.s   Boss_AntroidUpdateDecisionAnimation
                tst.w   (BossCombatCounter).w
                beq.w   Boss_AntroidBeginHealthRecovery
                move.w  (RandomNumberState).w,d7
                move.w  d7,d0
                andi.w  #$C800,d0
                beq.w   Boss_AntroidEnterWaitState
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$A8,d0
                bpl.s   Boss_AntroidChooseDistantAttack
                cmpi.w  #$3600,(BossHealth).w
                bmi.w   Boss_AntroidEnterJumpSlamPreparation
                btst    #0,d7
                bne.w   Boss_AntroidEnterJumpSlamPreparation
                move.w  d7,d0
                andi.w  #$14,d0
                beq.w   Boss_AntroidEnterJumpAttackPreparation
                bra.w   Boss_AntroidEnterWaitState
; ---------------------------------------------------------------------------
Boss_AntroidChooseDistantAttack:                        ; CODE XREF: Boss_AntroidReturnToNeutral+A6   j  ; was: loc_3771E
                cmpi.w  #$F8,d0
                bpl.s   Boss_AntroidScheduleLeapAttackB
                move.w  d7,d0
                andi.w  #$70,d0                         ; 'p'
                beq.w   Boss_AntroidEnterJumpAttackPreparation
Boss_AntroidScheduleLeapAttackB:                        ; CODE XREF: Boss_AntroidReturnToNeutral+CC   j  ; was: loc_3772E
                move.w  d7,d0
                andi.w  #7,d0
                addq.w  #1,d0
                move.w  d0,$11C(a5)
                bra.w   Boss_AntroidEnterLeapAttackBPreparation
; ---------------------------------------------------------------------------
Boss_AntroidUpdateDecisionAnimation:                    ; CODE XREF: Boss_AntroidInitializeBattleState+9E   j  ; was: loc_3773E
                                        ; sub_37558:Boss_AntroidWaitForStageReadyAnimate   j
                lea     Boss_AntroidDecisionAPoses(pc),a1
                nop
                move.w  (FrameCounter).w,d0
                andi.w  #$FF,d0
                cmpi.w  #$E0,d0
                bmi.s   Boss_AntroidUpdateDecisionPose
                lea     Boss_AntroidDecisionBPoses(pc),a1
                nop
Boss_AntroidUpdateDecisionPose:                         ; CODE XREF: Boss_AntroidReturnToNeutral+FA   j  ; was: loc_37758
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderBlinkingPose
                movea.w $11E(a5),a0
                move.w  #$14E,$14(a0)
                bra.w   Boss_AntroidFacePlayer
; ---------------------------------------------------------------------------
Boss_AntroidBeginHealthRecovery:                        ; CODE XREF: Boss_AntroidReturnToNeutral+8A   j  ; was: loc_3776E
                move.w  #$32,4(a5)                      ; '2'
                move.w  #$B4,$11C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
; End of function Boss_AntroidReturnToNeutral
; Restores Antroid's boss-health value over a timed recovery pose
Boss_AntroidHealthRecoveryState:                        ; DATA XREF: ROM:00037540   o  ; was: sub_37788
                subq.w  #1,$11C(a5)
                bmi.w   Boss_AntroidReturnToNeutralLoadAnimation
                addi.w  #3,(BossCombatCounter).w
                lea     Boss_AntroidHealthRecoveryPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderPose
                move.l  #Boss_AntroidSecondaryRotationFrame00,$548(a5)
                move.w  #$14E,$554(a5)
                move.l  #Boss_AntroidSecondaryRotationFrame00,$968(a5)
                move.w  #$14E,$974(a5)
                bra.w   Boss_AntroidSelectBlinkMetasprite
; End of function Boss_AntroidHealthRecoveryState
; Selects the first attack preparation state and falls through to its handler
Boss_AntroidEnterLeapAttackAPreparation:                ; CODE XREF: Boss_AntroidInitializeBattleState+7C   j  ; was: sub_377C4
                                        ; Boss_AntroidLeapAttackB+3C   j
                moveq   #8,d0
                bsr.w   Boss_AntroidEnterStateWithFirstPartSlot
; First attack preparation state waits for animation phase 2
Boss_AntroidPrepareLeapAttackA:                         ; DATA XREF: ROM:00037516   o  ; was: sub_377CA
                cmpi.w  #2,$29C(a5)
                bne.s   Boss_AntroidPrepareLeapAttackAAnimate
                bra.s   Boss_AntroidLaunchLeapAttackA
; ---------------------------------------------------------------------------
Boss_AntroidPrepareLeapAttackAAnimate:                  ; CODE XREF: Boss_AntroidPrepareLeapAttackA+6   j  ; was: loc_377D4
                lea     Boss_AntroidLeapAttackAPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderBlinkingPose
                movea.w $48(a5),a0
                move.l  #Boss_AntroidSecondaryRotationFrame00,8(a0)
                rts
; ---------------------------------------------------------------------------
; Launches leap variant A after selecting state $0A
Boss_AntroidLaunchLeapAttackA:                          ; CODE XREF: Boss_AntroidPrepareLeapAttackA+8   j  ; was: loc_377F0
                moveq   #$A,d0
                bsr.w   Boss_AntroidLaunchAttackMotion
; Leap-attack variant A with gravity and proximity checks
Boss_AntroidLeapAttackA:                                ; DATA XREF: ROM:00037518   o  ; was: sub_377F6
                addi.l  #$5000,$1C(a5)
                bmi.s   Boss_AntroidLeapAttackAAnimate
                movea.w #(FifteenthEntityType-M68K_RAM),a1
                movea.w #(TwentySixthEntityType-M68K_RAM),a0
                tst.w   6(a5)
                beq.s   Boss_AntroidLeapAttackACheckContact
                exg     a0,a1
Boss_AntroidLeapAttackACheckContact:                    ; CODE XREF: Boss_AntroidLeapAttackA+16   j  ; was: loc_37810
                cmpi.w  #$14E,$14(a0)
                bmi.s   Boss_AntroidLeapAttackAAnimate
                bsr.w   Boss_AntroidApplyAttackImpact
                bmi.s   Boss_AntroidLeapAttackAFinish
                tst.w   $1DE(a5)
                beq.s   Boss_AntroidLeapAttackACheckScreenRange
                cmpi.w  #$D60,$BC(a5)
                bmi.s   Boss_AntroidLeapAttackAFinish
                bra.w   Boss_AntroidEnterLeapAttackBPreparation
; ---------------------------------------------------------------------------
Boss_AntroidLeapAttackACheckScreenRange:                ; CODE XREF: Boss_AntroidLeapAttackA+2C   j  ; was: loc_37830
                cmpi.w  #$C70,$BC(a5)
                bmi.s   Boss_AntroidLeapAttackAFinish
                cmpi.w  #$D10,$BC(a5)
                bpl.s   Boss_AntroidLeapAttackAFinish
                subq.w  #1,$11C(a5)
                bpl.s   Boss_AntroidLeapAttackAChooseFollowup
Boss_AntroidLeapAttackAFinish:                          ; CODE XREF: Boss_AntroidLeapAttackA+26   j  ; was: loc_37846
                                        ; Boss_AntroidLeapAttackA+34   j
                bsr.w   Boss_AntroidSwapPoseSides
                bra.w   Boss_AntroidReturnToNeutralLoadAnimation
; ---------------------------------------------------------------------------
Boss_AntroidLeapAttackAChooseFollowup:                  ; CODE XREF: Boss_AntroidLeapAttackA+4E   j  ; was: loc_3784E
                move.w  #2,$23C(a5)
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$70,d0                         ; 'p'
                bpl.s   Boss_AntroidEnterLeapAttackBPreparation
                move.w  (RandomNumberState).w,d0
                andi.w  #$1E,d0
                beq.s   Boss_AntroidEnterLeapAttackBPreparation
                bsr.w   Boss_AntroidSwapPoseSides
                move.b  (RandomNumberState).w,d0
                andi.w  #6,d0
                beq.w   Boss_AntroidEnterJumpSlamPreparation
                bra.w   Boss_AntroidEnterJumpAttackPreparation
; ---------------------------------------------------------------------------
Boss_AntroidLeapAttackAAnimate:                         ; CODE XREF: Boss_AntroidLeapAttackA+8   j  ; was: loc_3787E
                                        ; Boss_AntroidLeapAttackA+20   j
                lea     Boss_AntroidLeapAttackAPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderBlinkingPose
; ---------------------------------------------------------------------------
; Selects the second attack preparation state and falls through to its handler
Boss_AntroidEnterLeapAttackBPreparation:                ; CODE XREF: Boss_AntroidReturnToNeutral+E4   j  ; was: loc_3788C
                                        ; Boss_AntroidLeapAttackA+36   j
                moveq   #$C,d0
                bsr.w   Boss_AntroidEnterStateWithSecondPartSlot
; Second attack preparation state waits for animation phase 2
Boss_AntroidPrepareLeapAttackB:                         ; DATA XREF: ROM:0003751A   o  ; was: sub_37892
                cmpi.w  #2,$29C(a5)
                bne.s   Boss_AntroidPrepareLeapAttackBAnimate
                bra.s   Boss_AntroidLaunchLeapAttackB
; ---------------------------------------------------------------------------
Boss_AntroidPrepareLeapAttackBAnimate:                  ; CODE XREF: Boss_AntroidPrepareLeapAttackB+6   j  ; was: loc_3789C
                lea     Boss_AntroidLeapAttackBPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bsr.w   Boss_AntroidRenderBlinkingPose
                movea.w $48(a5),a0
                move.l  #Boss_AntroidSecondaryRotationFrame00,8(a0)
                rts
; ---------------------------------------------------------------------------
; Launches leap variant B after selecting state $0E
Boss_AntroidLaunchLeapAttackB:                          ; CODE XREF: Boss_AntroidPrepareLeapAttackB+8   j  ; was: loc_378B8
                moveq   #$E,d0
                bsr.w   Boss_AntroidLaunchAttackMotion
; Leap-attack variant B with gravity and proximity checks
Boss_AntroidLeapAttackB:                                ; DATA XREF: ROM:0003751C   o  ; was: sub_378BE
                addi.l  #$5000,$1C(a5)
                bmi.w   Boss_AntroidLeapAttackBAnimate
                movea.w #(FifteenthEntityType-M68K_RAM),a0
                movea.w #(TwentySixthEntityType-M68K_RAM),a1
                tst.w   6(a5)
                beq.s   Boss_AntroidLeapAttackBCheckContact
                exg     a0,a1
Boss_AntroidLeapAttackBCheckContact:                    ; CODE XREF: Boss_AntroidLeapAttackB+18   j  ; was: loc_378DA
                cmpi.w  #$14E,$14(a0)
                bmi.s   Boss_AntroidLeapAttackBAnimate
                bsr.w   Boss_AntroidApplyAttackImpact
                bmi.w   Boss_AntroidReturnToNeutralLoadAnimation
                tst.w   $1DE(a5)
                beq.s   Boss_AntroidLeapAttackBCheckScreenRange
                cmpi.w  #$D60,$BC(a5)
                bmi.w   Boss_AntroidReturnToNeutralLoadAnimation
                bra.w   Boss_AntroidEnterLeapAttackAPreparation
; ---------------------------------------------------------------------------
Boss_AntroidLeapAttackBCheckScreenRange:                ; CODE XREF: Boss_AntroidLeapAttackB+30   j  ; was: loc_378FE
                cmpi.w  #$C70,$BC(a5)
                bmi.w   Boss_AntroidReturnToNeutralLoadAnimation
                cmpi.w  #$D10,$BC(a5)
                bpl.w   Boss_AntroidReturnToNeutralLoadAnimation
                subq.w  #1,$11C(a5)
                bpl.s   Boss_AntroidLeapAttackBChooseFollowup
                bra.w   Boss_AntroidReturnToNeutralLoadAnimation
; ---------------------------------------------------------------------------
Boss_AntroidLeapAttackBChooseFollowup:                  ; CODE XREF: Boss_AntroidLeapAttackB+58   j  ; was: loc_3791C
                move.w  #2,$23C(a5)
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$70,d0                         ; 'p'
                bpl.w   Boss_AntroidEnterLeapAttackAPreparation
                move.w  (RandomNumberState).w,d0
                andi.w  #$7800,d0
                beq.w   Boss_AntroidEnterLeapAttackAPreparation
                move.b  (RandomNumberState).w,d0
                andi.w  #6,d0
                beq.w   Boss_AntroidEnterJumpSlamPreparation
                bra.w   Boss_AntroidEnterJumpAttackPreparation
; ---------------------------------------------------------------------------
Boss_AntroidLeapAttackBAnimate:                         ; CODE XREF: Boss_AntroidLeapAttackB+8   j  ; was: loc_3794C
                                        ; Boss_AntroidLeapAttackB+22   j
                lea     Boss_AntroidLeapAttackBPoses(pc),a1
                nop
                bsr.w   Boss_AntroidUpdatePoseAnimation
                bra.w   Boss_AntroidRenderBlinkingPose
; End of function Boss_AntroidLeapAttackB
; Stores the requested attack state and applies its initial launch velocity
Boss_AntroidLaunchAttackMotion:                         ; CODE XREF: Boss_AntroidPrepareLeapAttackA+28   p  ; was: sub_3795A
                                        ; Boss_AntroidPrepareLeapAttackB+28   p
                move.w  d0,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFFE4000,$1C(a5)
                move.l  #$40000,$18(a5)
                tst.w   $54(a5)
                beq.s   Boss_AntroidLaunchAttackMotionReturn
                neg.l   $18(a5)
Boss_AntroidLaunchAttackMotionReturn:                   ; CODE XREF: Boss_AntroidLaunchAttackMotion+20   j  ; was: locret_37980
                rts
; End of function Boss_AntroidLaunchAttackMotion
; Plays the attack-impact sound, requests shake, and reduces boss health
Boss_AntroidApplyAttackImpact:                          ; CODE XREF: Boss_AntroidLeapAttackA+22   p  ; was: sub_37982
                                        ; Boss_AntroidLeapAttackB+24   p
                move.b  #$AF,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #2,(PlaneAShakeLevel).w
                tst.w   $1DE(a5)
                bne.s   Boss_AntroidApplyAttackImpactReturn
                subi.w  #$A,(BossCombatCounter).w
Boss_AntroidApplyAttackImpactReturn:                    ; CODE XREF: Boss_AntroidApplyAttackImpact+14   j  ; was: locret_3799E
                rts
; End of function Boss_AntroidApplyAttackImpact
