; Xi-Tiger controller, combat states, and movement helpers

Boss_XiTigerMain:                                       ; was: sub_3D814
                tst.w   4(a5)
                beq.w   Boss_XiTigerDispatchState
                tst.w   8(a5)
                beq.s   Boss_XiTigerDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_XiTigerUpdateStageRelativeCoordinates
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_XiTigerUpdateStageRelativeCoordinates
                tst.w   (BossHealth).w
                bne.s   Boss_XiTigerUpdateStageRelativeCoordinates
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.b  #1,(SoundFadeOutDelay).w
                move.w  #$FFFF,(MidgameLightningMode).w
                bra.w   Boss_XiTigerBeginDefeatLeap
; ---------------------------------------------------------------------------
Boss_XiTigerUpdateStageRelativeCoordinates:             ; was: loc_3D85A
                                        ; Boss_XiTigerMain+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$BC(a5)
                move.w  #$13E,d0
                add.w   (PrimaryCameraYPosition).w,d0
                move.w  d0,$23C(a5)
Boss_XiTigerDispatchState:                              ; was: loc_3D878
                                        ; Boss_XiTigerMain+C   j
                move.w  4(a5),d0
                movea.w Boss_XiTigerStateOffsets(pc,d0.w),a0
                adda.l  #Boss_XiTigerInit,a0
                jmp     (a0)
; End of function Boss_XiTigerMain
; ---------------------------------------------------------------------------
Boss_XiTigerStateOffsets:   dc.w    Boss_XiTigerInit-Boss_XiTigerInit  ; was: off_3D888
                dc.w    Boss_XiTigerSetup-Boss_XiTigerInit
                dc.w    Boss_XiTigerFallingLanding-Boss_XiTigerInit
                dc.w    Boss_XiTigerBattleStart-Boss_XiTigerInit
                dc.w    Boss_XiTigerStartBossMessage-Boss_XiTigerInit
                dc.w    Boss_XiTigerWaitForSequenceState-Boss_XiTigerInit
                dc.w    Boss_XiTigerIdleAttackDecisionState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDashRecoveryPoseState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDashPrep-Boss_XiTigerInit
                dc.w    Boss_XiTigerDashDecelerate-Boss_XiTigerInit
                dc.w    Boss_XiTigerCloseRangeJumpPreparationState-Boss_XiTigerInit
                dc.w    Boss_XiTigerJumpRise-Boss_XiTigerInit
                dc.w    Boss_XiTigerJumpDescendAndLand-Boss_XiTigerInit
                dc.w    Boss_XiTigerLandedState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDefeatLeapState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDefeatLandingDelayState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDefeatFadeState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDefeatSpawnDelayState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDefeatCounterDrainState-Boss_XiTigerInit
                dc.w    Boss_XiTigerDefeatHideDelayState-Boss_XiTigerInit
                dc.w    Boss_XiTigerCloseRangeAttackState-Boss_XiTigerInit

; Initializes Xi-Tiger boss clearing sprites
Boss_XiTigerInit:                                       ; was: sub_3D8B2
                                        ; ROM:Boss_XiTigerStateOffsets   o
                addq.w  #2,4(a5)
                move.w  #2,(MidgameLightningMode).w
                move.w  #$114,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                addq.w  #1,8(a5)
Boss_XiTigerInitReturn:                                 ; was: locret_3D8CC
                rts
; End of function Boss_XiTigerInit
; Builds the 25 linked metasprite parts, darkens the palette, and queues tiles
Boss_XiTigerSetup:                                      ; was: sub_3D8CE
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_XiTigerInitReturn
                movea.w a5,a4
                move.w  #$8280,(MetaspriteBaseTileWord).w
                moveq   #$18,d7
                movea.l #Boss_XiTigerMetaspriteDescriptors,a0
                movea.l #Boss_XiTigerPartRadii,a1
                movea.l #Boss_XiTigerPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                bset    #0,2(a5)
                bset    #0,$6C2(a5)
                bset    #0,$902(a5)
                bset    #0,$482(a5)
                bset    #3,$482(a5)
                addq.w  #4,4(a5)
                move.w  #$114,(a5)
                move.w  #$D00,2(a5)
                clr.w   $54(a5)
                clr.w   $56(a5)
                movea.l #Boss_XiTigerObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                move.w  #$C000,$242(a5)
                move.w  #$C000,$422(a5)
                move.l  #Boss_XiTigerClawMappingA,$248(a5)
                move.l  #Boss_XiTigerClawMappingA,$428(a5)
                move.w  #$2C,$266(a5)                   ; ','
                bclr    #7,$48E(a5)
                movea.l #(SharedGraphicsOverlay+$240),a0
                move.w  #$80,d0
                moveq   #9,d7
Boss_XiTigerAdjustNextPaletteBlock:                     ; was: loc_3D96A
                moveq   #$F,d6
Boss_XiTigerAdjustNextPaletteWord:                      ; was: loc_3D96C
                move.w  (a0)+,d1
                beq.s   Boss_XiTigerAdvancePaletteAdjustment
                sub.w   d0,d1
                move.w  d1,-2(a0)
Boss_XiTigerAdvancePaletteAdjustment:                   ; was: loc_3D976
                dbf     d6,Boss_XiTigerAdjustNextPaletteWord
                dbf     d7,Boss_XiTigerAdjustNextPaletteBlock
                movea.l #Boss_XiTigerTileLoadCommand,a0
                jsr     (Tilemap_QueueIndexedRows).l
                bsr.w   Boss_XiTigerApplyFacingGraphics
                move.w  #$CAA0,$48(a5)
                move.w  #$CF20,$4A(a5)
                move.w  #$E0,$490(a5)
                move.w  $23C(a5),$914(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                lea     Boss_XiTigerInitialPoseChannels(pc),a0
                nop
                bsr.w   Boss_XiTigerInitializePoseChannels
                bra.w   Boss_XiTigerUpdateBattleStartPose
; End of function Boss_XiTigerSetup
; ---------------------------------------------------------------------------
Boss_XiTigerTileLoadCommand:    dc.w    $6100, $2000, $302, $1816, $1719, $1C1A, $1B1D, $1E, $1F00  ; was: word_3D9BE

; Xi-Tiger falling state with ground landing detection
Boss_XiTigerFallingLanding:                             ; was: sub_3D9D0
                clr.w   $1DC(a5)
                clr.w   $1DE(a5)
                addi.l  #$4000,$1C(a5)
                bmi.s   Boss_XiTigerUpdateFallingPose
                move.w  $914(a5),d0
                cmp.w   $23C(a5),d0
                bmi.s   Boss_XiTigerUpdateFallingPose
                addq.w  #2,4(a5)
                move.w  #6,(PlaneAShakeLevel).w
                move.w  #6,(PlaneBShakeLevel).w
                move.l  #$C000,(StageCameraYVelocity).w
                move.w  #$FFFF,(MidgameVerticalPhase).w
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  $23C(a5),$914(a5)
                move.w  #$CF20,$4A(a5)
                clr.l   $1C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bra.s   Boss_XiTigerUpdateBattleStartPose
; ---------------------------------------------------------------------------
Boss_XiTigerUpdateFallingPose:                          ; was: loc_3DA30
                                        ; Boss_XiTigerFallingLanding+1A   j
                lea     Boss_XiTigerAirbornePoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerFallingLanding
; Starts battle activating boss movement
Boss_XiTigerBattleStart:                                ; was: sub_3DA3E
                tst.w   $58(a5)
                bpl.s   Boss_XiTigerUpdateBattleStartPose
                addq.w  #2,4(a5)
                clr.l   $498(a5)
                clr.w   $17E(a5)
                addq.w  #1,$1DC(a5)
                addq.w  #1,$1DE(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bra.s   Boss_XiTigerUpdateActiveBattlePose
; ---------------------------------------------------------------------------
Boss_XiTigerUpdateBattleStartPose:                      ; was: loc_3DA64
                                        ; Boss_XiTigerFallingLanding+5E   j
                lea     Boss_XiTigerBattleStartPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerBattleStart
; Holds the idle pose until the pose counter cues the boss message
Boss_XiTigerStartBossMessage:                           ; was: sub_3DA72
                cmpi.w  #$FFFC,$17E(a5)
                bne.s   Boss_XiTigerUpdateActiveBattlePose
                addq.w  #2,4(a5)
                moveq   #5,d0
                jsr     (BossMessage_Start).l
Boss_XiTigerUpdateActiveBattlePose:                     ; was: loc_3DA86
                                        ; Boss_XiTigerStartBossMessage+6   j
                lea     Boss_XiTigerIdlePoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerStartBossMessage
; Waits for the player sequence to finish before entering the idle decision loop
Boss_XiTigerWaitForSequenceState:                       ; was: sub_3DA94
                tst.w   (MessageSequenceState).w
                bne.s   Boss_XiTigerUpdateActiveBattlePose
                clr.b   (BossColorEffectFlags).w
                addi.w  #$40,(CameraXUpperBound).w      ; '@'
                bra.w   Boss_XiTigerSetIdleState
; End of function Boss_XiTigerWaitForSequenceState
; Unreachable: holds a recovery pose at a fixed position, then advances one state
Orphaned_XiTigerHoldRecoveryPoseAtFixedPosition:
                tst.w   $58(a5)                         ; was: sub_3DAA8
                bpl.s   Orphaned_XiTigerUpdateFixedPositionRecoveryPose
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                rts
; ---------------------------------------------------------------------------
Orphaned_XiTigerUpdateFixedPositionRecoveryPose:        ; was: loc_3DABE
                move.w  a5,$48(a5)
                move.w  #$CF20,$4A(a5)
                move.w  #$120,$10(a5)
                move.w  #$148,$914(a5)
                lea     Boss_XiTigerLandingRecoveryPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Orphaned_XiTigerHoldRecoveryPoseAtFixedPosition
; Unreachable: steps the state word back while controller bit 6 is pressed
Orphaned_XiTigerStepStateBackOnButtonPress:
                btst    #6,(ControllerPressedState).w   ; was: sub_3DAE2
                beq.s   Orphaned_XiTigerUpdateButtonRewindPose
                subq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFE,$C(a5)
Orphaned_XiTigerUpdateButtonRewindPose:                 ; was: loc_3DAF8
                lea     Boss_XiTigerLoopingAirbornePoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Orphaned_XiTigerStepStateBackOnButtonPress
; Enters the idle decision loop with a fresh pose-command cursor
Boss_XiTigerEnterIdleState:                             ; was: sub_3DB06
                                        ; Boss_XiTigerCloseRangeAttackState+E   j
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_XiTigerSetIdleState:                               ; was: loc_3DB10
                move.w  #$C,4(a5)
                move.w  #$C,$17E(a5)
                move.l  #Boss_XiTigerGroundedBodyMapping,$68(a5)
                bclr    #6,$261(a5)
                move.w  #$CAA0,$48(a5)
                move.w  #$CF20,$4A(a5)
                move.w  $23C(a5),$914(a5)
                move.w  #1,$1DC(a5)
                move.w  #1,$1DE(a5)
; Xi-Tiger idle state with attack decision
Boss_XiTigerIdleAttackDecisionState:                    ; was: loc_3DB48
                move.w  #2,(ColorFadeTriggerState).w
                addi.w  #$10,(BossCombatCounter).w
                tst.w   $17E(a5)
                bpl.s   Boss_XiTigerUpdateIdlePose
                move.w  #$C,$17E(a5)
                cmpi.w  #$1E0,(BossCombatCounter).w
                bmi.s   Boss_XiTigerUpdateIdlePose
                move.w  #$1E0,(BossCombatCounter).w
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$A0,d0
                bmi.w   Boss_XiTigerBeginDashRecoveryPose
                btst    #0,(RandomNumberState).w
                bne.w   Boss_XiTigerBeginDashPreparation
                bra.w   Boss_XiTigerBeginCloseRangeJumpPreparation
; ---------------------------------------------------------------------------
Boss_XiTigerUpdateIdlePose:                             ; was: loc_3DB8A
                                        ; Boss_XiTigerEnterIdleState+60   j
                lea     Boss_XiTigerIdlePoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bsr.w   Boss_XiTigerUpdateSprites
                move.w  (FrameCounter).w,d5
                andi.w  #$F,d5
                beq.w   Boss_XiTigerSetFacingDirection
                rts
; ---------------------------------------------------------------------------
Boss_XiTigerBeginDashPreparation:                       ; was: loc_3DBA6
                                        ; Boss_XiTigerDashDecelerate+44   j
                move.w  #$10,4(a5)
                move.l  #Boss_XiTigerGroundedBodyMapping,$68(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CAA0,$48(a5)
                move.w  #$CCE0,$4A(a5)
                move.w  $23C(a5),$6D4(a5)
                move.w  #0,$1DC(a5)
                move.w  #1,$1DE(a5)
                move.w  #3,$17E(a5)
                bsr.w   Boss_XiTigerSetFacingDirection
; End of function Boss_XiTigerEnterIdleState
; Xi-Tiger dash preparation with sound and rotation setup
Boss_XiTigerDashPrep:                                   ; was: sub_3DBE6
                tst.w   $17E(a5)
                bpl.s   Boss_XiTigerUpdateDashPreparationPose
                subi.w  #$A0,(BossCombatCounter).w
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                bset    #6,$261(a5)
                move.l  #$80000,$498(a5)
                tst.w   $54(a5)
                beq.s   Boss_XiTigerUpdateDashPreparationPose
                neg.l   $498(a5)
Boss_XiTigerUpdateDashPreparationPose:                  ; was: loc_3DC24
                                        ; Boss_XiTigerDashPrep+38   j
                lea     Boss_XiTigerDashPreparationPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerDashPrep
; Xi-Tiger dash deceleration and attack decision logic
Boss_XiTigerDashDecelerate:                             ; was: sub_3DC32
                tst.l   $498(a5)
                beq.s   Boss_XiTigerUpdatePostDashDecision
                bmi.s   Boss_XiTigerDecelerateNegativeDashVelocity
                subi.l  #$4000,$498(a5)
                bra.s   Boss_XiTigerUpdatePostDashDecision
; ---------------------------------------------------------------------------
Boss_XiTigerDecelerateNegativeDashVelocity:             ; was: loc_3DC44
                addi.l  #$4000,$498(a5)
Boss_XiTigerUpdatePostDashDecision:                     ; was: loc_3DC4C
                                        ; Boss_XiTigerDashDecelerate+10   j
                tst.w   $58(a5)
                bpl.s   Boss_XiTigerUpdateDashPreparationPose
                tst.w   (BossCombatCounter).w
                bmi.w   Boss_XiTigerEnterIdleState
                clr.l   $498(a5)
                bsr.w   Boss_XiTigerSetFacingDirection
                move.w  (RandomNumberState).w,d5
                cmpi.w  #$98,d0
                bmi.w   Boss_XiTigerBeginDashRecoveryPose
                andi.w  #2,d5
                beq.w   Boss_XiTigerBeginCloseRangeJumpPreparation
                bra.w   Boss_XiTigerBeginDashPreparation
; ---------------------------------------------------------------------------
Boss_XiTigerBeginDashRecoveryPose:                      ; was: loc_3DC7A
                                        ; Boss_XiTigerDashDecelerate+38   j
                move.w  #$E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CAA0,$48(a5)
                move.w  #$CCE0,$4A(a5)
                move.w  $23C(a5),$6D4(a5)
                move.w  #1,$1DC(a5)
                move.w  #0,$1DE(a5)
; Holds the recovery pose before entering close-range decision logic
Boss_XiTigerDashRecoveryPoseState:                      ; was: loc_3DCA8
                tst.w   $58(a5)
                bmi.s   Boss_XiTigerBeginCloseRangeDecisionState
                lea     Boss_XiTigerDashRecoveryPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; ---------------------------------------------------------------------------
Boss_XiTigerBeginCloseRangeDecisionState:               ; was: loc_3DCBC
                                        ; Boss_XiTigerCloseRangeAttackState+24   j
                move.w  #$28,4(a5)                      ; '('
                move.w  (RandomNumberState).w,d0
                andi.w  #$C,d0
                addq.w  #4,d0
                move.w  d0,$17E(a5)
                bset    #6,$261(a5)
                move.w  #4,$58(a5)
                move.w  #$FFFF,$C(a5)
                bsr.w   Boss_XiTigerSetFacingDirection
; End of function Boss_XiTigerDashDecelerate
; Runs the close-range attack pose, then selects the next attack by distance
Boss_XiTigerCloseRangeAttackState:                      ; was: sub_3DCE6
                tst.w   $17E(a5)
                bpl.s   Boss_XiTigerUpdateCloseRangeAttackPose
                bsr.w   Boss_XiTigerSetFacingDirection
                tst.w   (BossCombatCounter).w
                bmi.w   Boss_XiTigerEnterIdleState
                move.w  (RandomNumberState).w,d5
                cmpi.w  #$98,d0
                bpl.s   Boss_XiTigerChooseDistantCloseRangeAttack
                andi.w  #3,d5
                beq.w   Boss_XiTigerBeginCloseRangeJumpPreparation
                bra.w   Boss_XiTigerBeginCloseRangeDecisionState
; ---------------------------------------------------------------------------
Boss_XiTigerChooseDistantCloseRangeAttack:              ; was: loc_3DD0E
                andi.w  #1,d5
                beq.w   Boss_XiTigerBeginCloseRangeJumpPreparation
                bra.w   Boss_XiTigerBeginDashPreparation
; ---------------------------------------------------------------------------
Boss_XiTigerUpdateCloseRangeAttackPose:                 ; was: loc_3DD1A
                lea     Boss_XiTigerCloseRangeAttackPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                move.w  $58(a5),d0
                subq.w  #4,d0
                andi.w  #$C,d0
                cmpi.w  #8,d0
                bne.w   Boss_XiTigerUpdateSprites
                tst.w   $C(a5)
                bne.w   Boss_XiTigerUpdateSprites
                subi.w  #$30,(BossCombatCounter).w      ; '0'
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_XiTigerSelectBodyMapping
                bra.w   Boss_XiTigerUpdateSprites
; ---------------------------------------------------------------------------
Boss_XiTigerBeginCloseRangeJumpPreparation:             ; was: loc_3DD56
                                        ; Boss_XiTigerDashDecelerate+40   j
                move.w  #$14,4(a5)
                clr.w   $17E(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #Boss_XiTigerGroundedBodyMapping,$68(a5)
                move.w  #$CAA0,$48(a5)
                move.w  #$CF20,$4A(a5)
                move.w  $23C(a5),$914(a5)
                clr.w   $1DC(a5)
                clr.w   $1DE(a5)
; Waits for the close-range jump pose before launching
Boss_XiTigerCloseRangeJumpPreparationState:             ; was: loc_3DD8C
                cmpi.w  #$FFFD,$17E(a5)
                bne.s   Boss_XiTigerUpdateCloseRangeJumpPreparationPose
                addq.w  #2,4(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFFA0000,$1C(a5)
                move.l  #$20000,$498(a5)
                tst.w   $54(a5)
                beq.s   Boss_XiTigerUpdateCloseRangeJumpPreparationPose
                neg.l   $498(a5)
Boss_XiTigerUpdateCloseRangeJumpPreparationPose:        ; was: loc_3DDB6
                                        ; Boss_XiTigerCloseRangeAttackState+CA   j
                lea     Boss_XiTigerCloseRangeJumpPreparationPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerCloseRangeJumpPreparationState
; Xi-Tiger jump rising phase with gravity
Boss_XiTigerJumpRise:                                   ; was: sub_3DDC4
                addi.l  #$4000,$1C(a5)
                bmi.s   Boss_XiTigerUpdateCloseRangeJumpPreparationPose
                move.l  #Boss_XiTigerAirborneBodyMapping,$68(a5)
                addq.w  #2,4(a5)
                bset    #6,$261(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                subi.w  #$E0,(BossCombatCounter).w
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_XiTigerUpdateJumpAirbornePose:                     ; was: loc_3DDFA
                lea     Boss_XiTigerAirbornePoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerJumpRise
; Falls from the jump apex and performs the landing impact
Boss_XiTigerJumpDescendAndLand:                         ; was: sub_3DE08
                addi.l  #$4000,$1C(a5)
                move.w  $914(a5),d0
                cmp.w   $23C(a5),d0
                bmi.s   Boss_XiTigerUpdateJumpAirbornePose
                addq.w  #2,4(a5)
                move.w  #6,(PlaneAShakeLevel).w
                move.w  #6,(PlaneBShakeLevel).w
                move.l  #$C000,(StageCameraYVelocity).w
                move.w  #$FFFF,(MidgameVerticalPhase).w
                move.b  #$A4,d0
                jsr     (Sound_QueueSFXRequest).l
                bclr    #6,$261(a5)
                move.w  $23C(a5),$914(a5)
                move.w  #$CF20,$4A(a5)
                clr.l   $1C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
Boss_XiTigerUpdateLandingRecoveryPose:                  ; was: loc_3DE62
                lea     Boss_XiTigerLandingRecoveryPoses(pc),a1
                nop
                bsr.w   Boss_XiTigerUpdatePoseAnimation
                bra.w   Boss_XiTigerUpdateSprites
; End of function Boss_XiTigerJumpDescendAndLand
; Xi-Tiger landed state with AI decision logic
Boss_XiTigerLandedState:                                ; was: sub_3DE70
                tst.w   $58(a5)
                bpl.s   Boss_XiTigerDecelerateLandingVelocity
                clr.l   $498(a5)
                bsr.w   Boss_XiTigerSetFacingDirection
                tst.w   (BossCombatCounter).w
                bmi.w   Boss_XiTigerEnterIdleState
                move.w  (RandomNumberState).w,d5
                cmpi.w  #$A0,d0
                bpl.w   Boss_XiTigerBeginDashPreparation
                andi.w  #4,d5
                beq.w   Boss_XiTigerBeginDashRecoveryPose
                bra.w   Boss_XiTigerBeginCloseRangeJumpPreparation
; ---------------------------------------------------------------------------
Boss_XiTigerDecelerateLandingVelocity:                  ; was: loc_3DE9E
                move.l  $498(a5),d0
                beq.s   Boss_XiTigerApplyLandingVelocity
                bmi.s   Boss_XiTigerDecelerateNegativeLandingVelocity
                subi.l  #$2000,d0
                bra.s   Boss_XiTigerApplyLandingVelocity
; ---------------------------------------------------------------------------
Boss_XiTigerDecelerateNegativeLandingVelocity:          ; was: loc_3DEAE
                addi.l  #$2000,d0
Boss_XiTigerApplyLandingVelocity:                       ; was: loc_3DEB4
                                        ; Boss_XiTigerLandedState+3C   j
                move.l  d0,$498(a5)
                bra.s   Boss_XiTigerUpdateLandingRecoveryPose
; End of function Boss_XiTigerLandedState
