; Replaces an out-of-range shared boss position with the offscreen fallback X
Boss_ClampSharedScreenPosition:                         ; was: sub_35614
                                        ; Boss_ShellshogunPublishScreenPosition+18   j
                tst.w   (SecondaryCameraXPos).w
                bmi.s   Boss_ClampSharedScreenPositionCheckNegativeX
                cmpi.w  #$80,(SecondaryCameraXPos).w
                bpl.s   Boss_ClampSharedScreenPositionFallback
                bra.s   Boss_ClampSharedScreenPositionCheckY
; ---------------------------------------------------------------------------
Boss_ClampSharedScreenPositionCheckNegativeX:           ; was: loc_35624
                cmpi.w  #$FEB0,(SecondaryCameraXPos).w
                bmi.s   Boss_ClampSharedScreenPositionFallback
Boss_ClampSharedScreenPositionCheckY:                   ; was: loc_3562C
                tst.w   (SecondaryCameraYPos).w
                bmi.s   Boss_ClampSharedScreenPositionCheckNegativeY
                cmpi.w  #$E0,(SecondaryCameraYPos).w
                bmi.s   Boss_ClampSharedScreenPositionFallback
                cmpi.w  #$1D0,(SecondaryCameraYPos).w
                bpl.s   Boss_ClampSharedScreenPositionFallback
                rts
; ---------------------------------------------------------------------------
Boss_ClampSharedScreenPositionCheckNegativeY:           ; was: loc_35644
                cmpi.w  #$FFD0,(SecondaryCameraYPos).w
                bmi.s   Boss_ClampSharedScreenPositionFallback
                rts
; ---------------------------------------------------------------------------
Boss_ClampSharedScreenPositionFallback:                 ; was: loc_3564E
                                        ; Boss_ClampSharedScreenPosition+16   j
                move.w  #$FEB0,(SecondaryCameraXPos).w
                rts
; End of function Boss_ClampSharedScreenPosition
; Runs the state machine and raises the shared palette-flash intensity when needed
Boss_JetsripperMainHandler:                             ; was: sub_35656
                clr.w   $52(a5)
                bsr.s   Boss_JetsripperUpdateState
                tst.w   (a5)
                beq.s   Boss_JetsripperMainReturn
                movea.w $48(a5),a0
                bset    #0,2(a0)
                move.w  $52(a5),d0
                beq.s   Boss_JetsripperMainReturn
                cmp.w   (PlaneAShakeLevel).w,d0
                bmi.s   Boss_JetsripperMainReturn
                move.w  d0,(PlaneAShakeLevel).w
                asr.w   #1,d0
                move.w  d0,(PlaneBShakeLevel).w
Boss_JetsripperMainReturn:                              ; was: locret_35680
                                        ; Boss_JetsripperMainHandler+18   j
                rts
; End of function Boss_JetsripperMainHandler
; Updates Jetsripper state machine and transition logic
Boss_JetsripperUpdateState:                             ; was: sub_35682
                tst.w   4(a5)
                beq.w   Boss_JetsripperStateDispatch
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_JetsripperUpdateActiveState
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_JetsripperUpdateActiveState
                tst.w   (BossHealth).w
                bne.s   Boss_JetsripperUpdateActiveState
                move.b  #2,(BossColorEffectFlags).w
                move.w  #$1E,4(a5)
                bset    #0,(StageTimerPauseFlag).w
Boss_JetsripperUpdateActiveState:                       ; was: loc_356B2
                                        ; Boss_JetsripperUpdateState+16   j
                bsr.w   Boss_JetsripperUpdatePalette
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$5E(a5)
; Dispatches Jetsripper's state-offset jump table
Boss_JetsripperStateDispatch:                           ; was: loc_356C8
                move.w  4(a5),d0
                movea.w Boss_JetsripperStates(pc,d0.w),a0
                adda.l  #Boss_JetsripperInitState,a0
                jmp     (a0)
; End of function Boss_JetsripperUpdateState
; ---------------------------------------------------------------------------
Boss_JetsripperStates:  dc.w    Boss_JetsripperInitState-Boss_JetsripperInitState  ; was: off_356D8
                dc.w    Boss_JetsripperInitBody-Boss_JetsripperInitState
                dc.w    Boss_JetsripperAlignToCenter-Boss_JetsripperInitState
                dc.w    Boss_JetsripperUpdateMovement-Boss_JetsripperInitState
                dc.w    Boss_JetsripperRotateState-Boss_JetsripperInitState
                dc.w    Boss_JetsripperIdleState-Boss_JetsripperInitState
                dc.w    Boss_JetsripperAlignState-Boss_JetsripperInitState
                dc.w    Boss_JetsripperPatrolState-Boss_JetsripperInitState
                dc.w    Boss_JetsripperEnterScreen-Boss_JetsripperInitState
                dc.w    Boss_JetsripperAlignToCenterThunk-Boss_JetsripperInitState
                dc.w    Boss_JetsripperAttackTimer-Boss_JetsripperInitState
                dc.w    Boss_JetsripperEndAttack-Boss_JetsripperInitState
                dc.w    Boss_JetsripperDivePrep-Boss_JetsripperInitState
                dc.w    Boss_JetsripperDiveExecute-Boss_JetsripperInitState
                dc.w    Boss_JetsripperSwingAttack-Boss_JetsripperInitState
                dc.w    Boss_JetsripperDeathInit-Boss_JetsripperInitState
                dc.w    Boss_JetsripperDeathFade-Boss_JetsripperInitState

; Advances to body setup and clears unrelated objects
Boss_JetsripperInitState:                               ; was: sub_356FA
                                        ; ROM:Boss_JetsripperStates   o
                addq.w  #2,4(a5)
                move.w  a5,$48(a5)
                move.w  #$E4,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; End of function Boss_JetsripperInitState
; Initializes 18 body segments with physics parameters
Boss_JetsripperInitBody:                                ; was: sub_3570E
                move.w  #$10,4(a5)
                movea.w a5,a0
                moveq   #0,d0
                moveq   #0,d1
                moveq   #$11,d7
Boss_JetsripperInitNextSegment:                         ; was: loc_3571C
                move.w  #$E8,(a0)
                move.w  #$C000,2(a0)
                move.w  #$8300,$E(a0)
                move.l  #Boss_JetsripperSharedSegmentBaseFrame,8(a0)
                move.b  #$20,$20(a0)                    ; ' '
                move.w  d1,$48(a0)
                move.b  #$50,$21(a0)                    ; 'P'
                btst    #0,d0
                beq.s   Boss_JetsripperInitBodyParts
                move.b  #$10,$21(a0)
; Initializes Jetsripper segment collision and position fields
Boss_JetsripperInitBodyParts:                           ; was: loc_35750
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F20EF20E,$28(a0)
                move.w  #$C,$24(a0)
                move.w  #$50,$26(a0)                    ; 'P'
                move.b  #4,$23(a0)
                lea     $60(a0),a0
                addq.w  #1,d0
                addq.w  #6,d1
                dbf     d7,Boss_JetsripperInitNextSegment
                move.w  #$E4,(a5)
                move.w  #$CC00,2(a5)
                move.w  #$320,$10(a5)
                move.w  #$320,$130(a5)
                move.b  #$80,$23(a5)
                move.w  #$20,$24(a5)                    ; ' '
                move.w  a5,$48(a5)
                clr.w   $4C(a5)
                clr.w   $4E(a5)
                move.w  #$E0,$54(a5)
                move.w  #$70,$56(a5)                    ; 'p'
                clr.w   $5A(a5)
                clr.w   $BE(a5)
                move.w  #0,d0
                bra.w   Boss_JetsripperFillAngleHistory
; End of function Boss_JetsripperInitBody
; Handles boss entering screen until position threshold
Boss_JetsripperEnterScreen:                             ; was: sub_357C8
                bsr.w   Boss_JetsripperOscillate
                cmpi.w  #$810,$5E(a5)
                bpl.w   Boss_JetsripperUpdateSegmentDisplay
                addq.w  #2,4(a5)
                clr.w   $4C(a5)
                move.w  #$40,$4E(a5)                    ; '@'
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; End of function Boss_JetsripperEnterScreen
; Attributes: thunk
; State entry $12 that only re-enters the centre-alignment state
Boss_JetsripperAlignToCenterThunk:                      ; was: sub_357E8
                bra.w   Boss_JetsripperAlignToCenter
; End of function Boss_JetsripperAlignToCenterThunk
; Handles attack timer countdown and sound trigger
Boss_JetsripperAttackTimer:                             ; was: sub_357EC
                subq.w  #1,$5C(a5)
                bpl.w   Boss_JetsripperUpdateMovement
                addq.w  #2,4(a5)
                move.b  #$48,d0                         ; 'H'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #8,$52(a5)
                moveq   #3,d0
                jsr     (BossMessage_Start).l
                bra.w   Boss_JetsripperUpdateMovement
; End of function Boss_JetsripperAttackTimer
; Ends attack phase and resets state parameters
Boss_JetsripperEndAttack:                               ; was: sub_35814
                tst.w   (MessageSequenceState).w
                bne.w   Boss_JetsripperUpdateMovement
                move.w  #6,4(a5)
                move.w  #8,$5C(a5)
                move.w  #$60,$11E(a5)                   ; '`'
                clr.b   (BossColorEffectFlags).w
                subi.w  #$A0,(CameraXLowerBound).w
                bra.w   Boss_JetsripperUpdateMovement
; End of function Boss_JetsripperEndAttack
; Handles Jetsripper rotation state with angle check
Boss_JetsripperRotateState:                             ; was: sub_3583C
                bsr.w   Boss_JetsripperAdjustRadius
                move.w  $56(a5),d0
                addi.w  #8,d0
                andi.w  #$1F8,d0
                subq.w  #1,$4C(a5)
                bpl.s   Boss_JetsripperRotateStateStoreAngle
                cmpi.w  #$70,d0                         ; 'p'
                bne.s   Boss_JetsripperRotateStateStoreAngle
                addq.w  #2,4(a5)
                clr.w   $4C(a5)
                clr.w   $4E(a5)
Boss_JetsripperRotateStateStoreAngle:                   ; was: loc_35864
                                        ; Boss_JetsripperRotateState+1A   j
                move.w  d0,$56(a5)
Boss_JetsripperUpdateSegmentDisplay:                    ; was: loc_35868
                                        ; Boss_JetsripperEnterScreen+1C   j
                bsr.w   Boss_JetsripperAssignSegmentRadii
                bsr.w   Boss_JetsripperUpdateSegmentsFromAngleHistory
                bsr.w   Boss_JetsripperSelectLowestMiddleSegment
                move.w  #$C740,$48(a5)
                movea.w a5,a3
                moveq   #$11,d7
                jsr     (Sprite_ApplyAnchorOffsetToLinkedParts).l
                bsr.w   Boss_JetsripperUpdateAllSegmentSprites
                cmpi.w  #$144,$14(a5)
                bmi.s   Boss_JetsripperSegmentDisplayReturn
                move.w  #$144,$14(a5)
Boss_JetsripperSegmentDisplayReturn:                    ; was: locret_35896
                rts
; End of function Boss_JetsripperRotateState
; Idle state with oscillation and attack condition checks
Boss_JetsripperIdleState:                               ; was: sub_35898
                bsr.w   Boss_JetsripperOscillate
                subi.w  #1,(BossCombatCounter).w
                bmi.w   Boss_JetsripperSetIncreasingAngle
                cmpi.w  #0,$56(a5)
                bne.s   Boss_JetsripperIdleCheckAlternateTransition
                tst.w   $4C(a5)
                beq.s   Boss_JetsripperIdleCheckAlternateTransition
                cmpi.w  #$710,$5E(a5)
                bpl.s   Boss_JetsripperIdleCheckAlternateTransition
                move.w  #$C,4(a5)
                clr.w   $4C(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; ---------------------------------------------------------------------------
Boss_JetsripperIdleCheckAlternateTransition:            ; was: loc_358CA
                                        ; Boss_JetsripperIdleState+1A   j
                cmpi.w  #$12,(BossCombatCounter).w
                bmi.w   Boss_JetsripperUpdateSegmentDisplay
                btst    #0,(RandomNumberState+1).w
                beq.w   Boss_JetsripperUpdateSegmentDisplay
                cmpi.w  #0,$56(a5)
                bne.w   Boss_JetsripperUpdateSegmentDisplay
                tst.w   $4C(a5)
                bne.w   Boss_JetsripperUpdateSegmentDisplay
                move.w  #$18,4(a5)
                move.w  #0,$4C(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; ---------------------------------------------------------------------------
Boss_JetsripperSetDecreasingAngle:                      ; was: loc_35900
                move.w  #1,$4C(a5)
                bra.s   Boss_JetsripperBeginRotateState
; ---------------------------------------------------------------------------
Boss_JetsripperSetIncreasingAngle:                      ; was: loc_35908
                clr.w   $4C(a5)
Boss_JetsripperBeginRotateState:                        ; was: loc_3590C
                move.w  #4,4(a5)
                move.w  #$40,$4E(a5)                    ; '@'
                move.w  #$100,$5C(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; End of function Boss_JetsripperIdleState
; Alignment state adjusting radius until reaching target angle
Boss_JetsripperAlignState:                              ; was: sub_35922
                bsr.w   Boss_JetsripperAdjustRadius
                move.w  $56(a5),d0
                subi.w  #8,d0
                andi.w  #$1F8,d0
                subq.w  #1,$4C(a5)
                bpl.s   Boss_JetsripperAlignStateStoreAngle
                cmpi.w  #$90,d0
                bne.s   Boss_JetsripperAlignStateStoreAngle
                addq.w  #2,4(a5)
                move.w  #1,$4C(a5)
                clr.w   $4E(a5)
Boss_JetsripperAlignStateStoreAngle:                    ; was: loc_3594C
                                        ; Boss_JetsripperAlignState+1A   j
                move.w  d0,$56(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; End of function Boss_JetsripperAlignState
; Patrol state with oscillation and position threshold checks
Boss_JetsripperPatrolState:                             ; was: sub_35954
                bsr.w   Boss_JetsripperOscillate
                subi.w  #1,(BossCombatCounter).w
                bmi.w   Boss_JetsripperSetDecreasingAngle
                cmpi.w  #$100,$56(a5)
                bne.s   Boss_JetsripperPatrolCheckAlternateTransition
                tst.w   $4C(a5)
                bne.s   Boss_JetsripperPatrolCheckAlternateTransition
                cmpi.w  #$870,$5E(a5)
                bmi.s   Boss_JetsripperPatrolCheckAlternateTransition
                move.w  #8,4(a5)
                clr.w   $4C(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; ---------------------------------------------------------------------------
Boss_JetsripperPatrolCheckAlternateTransition:          ; was: loc_35986
                                        ; Boss_JetsripperPatrolState+1A   j
                cmpi.w  #$12,(BossCombatCounter).w
                bmi.w   Boss_JetsripperUpdateSegmentDisplay
                btst    #0,(RandomNumberState+1).w
                bne.w   Boss_JetsripperUpdateSegmentDisplay
                cmpi.w  #$100,$56(a5)
                bne.w   Boss_JetsripperUpdateSegmentDisplay
                tst.w   $4C(a5)
                beq.w   Boss_JetsripperUpdateSegmentDisplay
                move.w  #$18,4(a5)
                move.w  #2,$4C(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; End of function Boss_JetsripperPatrolState
; Updates vertical oscillation movement pattern
Boss_JetsripperOscillate:                               ; was: sub_359BC
                                        ; sub_35898   p
                move.w  #1,$52(a5)
                bsr.w   Boss_JetsripperAdjustRadius
                move.w  $56(a5),d0
                tst.w   $4C(a5)
                bne.s   Boss_JetsripperOscillateDecreaseAngle
                addq.w  #8,d0
                subq.w  #1,$4E(a5)
                bpl.s   Boss_JetsripperUpdateAngle
                addq.w  #1,$4C(a5)
                bra.s   Boss_JetsripperOscillateReloadTimer
; ---------------------------------------------------------------------------
Boss_JetsripperOscillateDecreaseAngle:                  ; was: loc_359DE
                subq.w  #8,d0
                subq.w  #1,$4E(a5)
                bpl.s   Boss_JetsripperUpdateAngle
                clr.w   $4C(a5)
Boss_JetsripperOscillateReloadTimer:                    ; was: loc_359EA
                move.w  #$18,$4E(a5)
; Updates boss angle and calculates velocity for movement
Boss_JetsripperUpdateAngle:                             ; was: loc_359F0
                                        ; Boss_JetsripperOscillate+28   j
                andi.w  #$1F8,d0
                move.w  d0,$56(a5)
                bsr.w   Boss_JetsripperCalculateAngleVelocity
                add.l   d2,$130(a5)
                rts
; End of function Boss_JetsripperOscillate
; Moves boss toward center alignment position
Boss_JetsripperAlignToCenter:                           ; was: sub_35A02
                move.w  #2,$52(a5)
                bsr.w   Boss_JetsripperAdjustRadius
                move.w  $56(a5),d0
                subi.w  #$10,d0
                tst.w   $4C(a5)
                bne.s   Boss_JetsripperAlignToCenterNormalizeAngle
                addi.w  #$20,d0                         ; ' '
Boss_JetsripperAlignToCenterNormalizeAngle:             ; was: loc_35A1E
                andi.w  #$1F0,d0
                subq.w  #1,$4E(a5)
                bpl.s   Boss_JetsripperAlignToCenterStoreAngle
                cmpi.w  #$80,d0
                bne.s   Boss_JetsripperAlignToCenterStoreAngle
                addq.w  #2,4(a5)
                move.w  #4,$52(a5)
                clr.w   $4C(a5)
                clr.w   $4E(a5)
                move.w  #$A0,$11E(a5)
Boss_JetsripperAlignToCenterStoreAngle:                 ; was: loc_35A46
                                        ; Boss_JetsripperAlignToCenter+2A   j
                move.w  d0,$56(a5)
                bra.w   Boss_JetsripperMovementUpdateSegmentDisplay
; End of function Boss_JetsripperAlignToCenter
; Main movement update with direction oscillation
Boss_JetsripperUpdateMovement:                          ; was: sub_35A4E
                                        ; Boss_JetsripperAttackTimer+24   j
                addi.w  #2,(BossCombatCounter).w
                move.w  $56(a5),d0
                move.b  (RandomNumberState).w,d1
                andi.w  #$F,d1
                addi.w  #$18,d1
                tst.w   $4C(a5)
                bne.s   Boss_JetsripperMovementDecreaseAngle
                cmpi.w  #$180,d0
                bpl.s   Boss_JetsripperMovementIncreaseAngle
                cmpi.w  #$100,d0
                bpl.s   Boss_JetsripperMovementSwitchToDecreasingAngle
Boss_JetsripperMovementIncreaseAngle:                   ; was: loc_35A76
                addq.w  #8,d0
                subq.w  #1,$4E(a5)
                bpl.s   Boss_JetsripperMovementApplyAngle
Boss_JetsripperMovementSwitchToDecreasingAngle:         ; was: loc_35A7E
                addq.w  #1,$4C(a5)
                bra.s   Boss_JetsripperMovementReloadAngleTimer
; ---------------------------------------------------------------------------
Boss_JetsripperMovementDecreaseAngle:                   ; was: loc_35A84
                cmpi.w  #$180,d0
                bpl.s   Boss_JetsripperMovementSwitchToIncreasingAngle
                subq.w  #8,d0
                subq.w  #1,$4E(a5)
                bpl.s   Boss_JetsripperMovementApplyAngle
Boss_JetsripperMovementSwitchToIncreasingAngle:         ; was: loc_35A92
                clr.w   $4C(a5)
Boss_JetsripperMovementReloadAngleTimer:                ; was: loc_35A96
                move.w  d1,$4E(a5)
Boss_JetsripperMovementApplyAngle:                      ; was: loc_35A9A
                                        ; Boss_JetsripperUpdateMovement+42   j
                andi.w  #$1F8,d0
                move.w  d0,$56(a5)
                cmpi.w  #$14,4(a5)
                beq.s   Boss_JetsripperMovementUpdateSegmentDisplay
                cmpi.w  #$16,4(a5)
                beq.s   Boss_JetsripperMovementUpdateSegmentDisplay
                subq.w  #1,$5C(a5)
                bpl.s   Boss_JetsripperMovementUpdateSegmentDisplay
                bsr.w   Boss_JetsripperSpawnProjectile
                move.w  #$30,$4C(a5)                    ; '0'
                cmpi.w  #$7C0,$5E(a5)
                bmi.s   Boss_JetsripperMovementSelectAlignState
                move.w  #8,4(a5)
                bra.s   Boss_JetsripperMovementUpdateSegmentDisplay
; ---------------------------------------------------------------------------
Boss_JetsripperMovementSelectAlignState:                ; was: loc_35AD2
                move.w  #$C,4(a5)
Boss_JetsripperMovementUpdateSegmentDisplay:            ; was: loc_35AD8
                                        ; Boss_JetsripperUpdateMovement+5A   j
                bsr.w   Boss_JetsripperAssignSegmentRadii
                bsr.w   Boss_JetsripperUpdateSegmentsFromAngleHistory
                bsr.w   Boss_JetsripperSelectLowestMiddleSegment
                move.w  #$C980,$48(a5)
                movea.w a5,a3
                moveq   #$11,d7
                jsr     (Sprite_ApplyAnchorOffsetToLinkedParts).l
                bsr.w   Boss_JetsripperUpdateAllSegmentSprites
                cmpi.w  #$144,$14(a5)
                bmi.s   Boss_JetsripperSelectSprite
                move.w  #$144,$14(a5)
; Selects sprite frame based on animation timer
Boss_JetsripperSelectSprite:                            ; was: loc_35B06
                move.w  (FrameCounter).w,d0
                andi.w  #4,d0
                move.l  Boss_JetsripperBodyFrames(pc,d0.w),8(a5)
                bclr    #4,$E(a5)
                rts
; End of function Boss_JetsripperUpdateMovement
; ---------------------------------------------------------------------------
Boss_JetsripperBodyFrames:  dc.l    Boss_JetsripperMovementFrame00  ; was: off_35B1C
                dc.l    Boss_JetsripperMovementFrame01

; Prepares dive attack with velocity calculation and sound
Boss_JetsripperDivePrep:                                ; was: sub_35B24
                subi.w  #1,(BossCombatCounter).w
                move.w  #1,$52(a5)
                bsr.w   Boss_JetsripperCalculateAngleVelocity
                add.l   d2,$130(a5)
                move.w  $56(a5),d0
                cmpi.w  #$180,d0
                bne.s   Boss_JetsripperDivePrepRotate
                cmpi.w  #$142,$14(a5)
                bmi.w   Boss_JetsripperUpdateSegmentDisplay
                move.b  #$DA,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                move.w  #$144,$14(a5)
                move.w  #8,$52(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; ---------------------------------------------------------------------------
Boss_JetsripperDivePrepRotate:                          ; was: loc_35B6A
                tst.w   $4C(a5)
                bne.s   Boss_JetsripperDivePrepDecreaseAngle
                addq.w  #8,d0
                bra.s   Boss_JetsripperDivePrepStoreAngle
; ---------------------------------------------------------------------------
Boss_JetsripperDivePrepDecreaseAngle:                   ; was: loc_35B74
                subq.w  #8,d0
                move.w  #$18,$4E(a5)
Boss_JetsripperDivePrepStoreAngle:                      ; was: loc_35B7C
                andi.w  #$1F8,d0
                move.w  d0,$56(a5)
                bra.w   Boss_JetsripperUpdateSegmentDisplay
; End of function Boss_JetsripperDivePrep
; Executes dive attack with angle rotation and bounce
Boss_JetsripperDiveExecute:                             ; was: sub_35B88
                clr.l   $18(a5)
                move.w  $56(a5),d0
                move.w  $5A(a5),d2
                tst.w   $4C(a5)
                beq.s   Boss_JetsripperDiveRotateForward
                subq.w  #8,d2
                subi.w  #$20,d0                         ; ' '
                andi.w  #$1E0,d0
                cmpi.w  #$80,d0
                bne.s   Boss_JetsripperDiveStoreAngles
                clr.w   $4C(a5)
                bra.s   Boss_JetsripperDiveStoreAngles
; ---------------------------------------------------------------------------
Boss_JetsripperDiveRotateForward:                       ; was: loc_35BB0
                addq.w  #8,d2
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1E0,d0
                cmpi.w  #$80,d0
                bne.s   Boss_JetsripperDiveStoreAngles
                addq.w  #1,$4C(a5)
Boss_JetsripperDiveStoreAngles:                         ; was: loc_35BC4
                                        ; Boss_JetsripperDiveExecute+26   j
                move.w  d0,$56(a5)
                andi.w  #$1FE,d2
                move.w  d2,$5A(a5)
                addq.w  #4,$54(a5)
                cmpi.w  #$1A0,$54(a5)
                bmi.s   Boss_JetsripperDiveUpdateWindupSegments
                move.b  #$D7,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,4(a5)
                move.w  #8,$52(a5)
                move.w  #$1A0,$54(a5)
                move.w  #$80,d0
                move.w  d0,$56(a5)
                bsr.w   Boss_JetsripperFillAngleHistory
                clr.w   $BE(a5)
                clr.w   $5A(a5)
                bsr.w   Boss_JetsripperProcessSegmentChain
                move.l  #$28000,$18(a5)
                move.l  #$FFFA8000,$1C(a5)
                subi.w  #$34,(BossCombatCounter).w      ; '4'
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Boss_JetsripperDiveLaunchReturn
                move.l  #$FFFD8000,$18(a5)
Boss_JetsripperDiveLaunchReturn:                        ; was: locret_35C36
                rts
; ---------------------------------------------------------------------------
Boss_JetsripperDiveUpdateWindupSegments:                ; was: loc_35C38
                bsr.w   Boss_JetsripperAssignSegmentRadii
                bsr.w   Boss_JetsripperUpdateSegmentsFromAngleHistory
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                movea.w a5,a3
                moveq   #$11,d7
                jsr     (Sprite_ApplyAnchorOffsetToLinkedParts).l
                bsr.w   Boss_JetsripperUpdateAllSegmentSprites
                move.l  #Boss_JetsripperDiveWindupFrame,8(a5)
                move.w  $E(a5),d0
                andi.w  #$E7FF,d0
                move.w  d0,$E(a5)
                rts
; End of function Boss_JetsripperDiveExecute
; Swing attack with oscillating angle and velocity changes
Boss_JetsripperSwingAttack:                             ; was: sub_35C6C
                move.w  $56(a5),d0
                move.w  $5A(a5),d1
                move.w  $BE(a5),d2
                tst.w   $4E(a5)
                beq.s   Boss_JetsripperSwingReverseMotion
                addq.w  #2,d1
                addi.w  #$10,d0
                subq.w  #2,d2
                cmpi.w  #$FFE4,d2
                bne.s   Boss_JetsripperSwingApplyAngles
                clr.w   $4E(a5)
                bra.s   Boss_JetsripperSwingApplyAngles
; ---------------------------------------------------------------------------
Boss_JetsripperSwingReverseMotion:                      ; was: loc_35C92
                subq.w  #2,d1
                subi.w  #$10,d0
                addq.w  #2,d2
                cmpi.w  #$1C,d2
                bne.s   Boss_JetsripperSwingApplyAngles
                addq.w  #1,$4E(a5)
Boss_JetsripperSwingApplyAngles:                        ; was: loc_35CA4
                                        ; Boss_JetsripperSwingAttack+24   j
                andi.w  #$1FE,d0
                move.w  d0,$56(a5)
                move.w  d2,$BE(a5)
                andi.w  #$1FE,d1
                move.w  d1,$5A(a5)
                bsr.w   Boss_JetsripperFillAngleHistory
                subq.w  #8,$54(a5)
                cmpi.w  #$120,$54(a5)
                bpl.s   Boss_JetsripperSwingUpdateVerticalMotion
                move.w  #$120,$54(a5)
Boss_JetsripperSwingUpdateVerticalMotion:               ; was: loc_35CCE
                addi.l  #$2400,$1C(a5)
                bmi.s   Boss_JetsripperProcessSegmentChain
                cmpi.w  #$138,$14(a5)
                bmi.s   Boss_JetsripperProcessSegmentChain
                move.b  #$48,d0                         ; 'H'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #8,$52(a5)
                move.w  #$138,$14(a5)
                clr.l   $1C(a5)
                move.w  #$180,$56(a5)
                clr.w   $BE(a5)
                clr.w   $5A(a5)
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Boss_JetsripperSwingSelectAlignState
                move.w  #8,4(a5)
                clr.w   $4C(a5)
                moveq   #$A,d1
                bsr.w   Boss_JetsripperFillAngleHistoryGradient
                bra.s   Boss_JetsripperProcessSegmentChain
; ---------------------------------------------------------------------------
Boss_JetsripperSwingSelectAlignState:                   ; was: loc_35D24
                move.w  #$C,4(a5)
                move.w  #1,$4C(a5)
                moveq   #$FFFFFFF6,d1
                bsr.w   Boss_JetsripperFillAngleHistoryGradient
; End of function Boss_JetsripperSwingAttack
; Updates all body segments and linked sprite positions
Boss_JetsripperProcessSegmentChain:                     ; was: sub_35D36
                                        ; Boss_JetsripperSwingAttack+6A   j
                bsr.w   Boss_JetsripperAssignSegmentRadii
                bsr.w   Boss_JetsripperUpdateSegmentsFromAngleHistory
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                movea.w a5,a3
                moveq   #$11,d7
                jsr     (Sprite_ApplyAnchorOffsetToLinkedParts).l
                bra.w   Boss_JetsripperUpdateAllSegmentSprites
; End of function Boss_JetsripperProcessSegmentChain
; Initializes Jetsripper death sequence with particles
Boss_JetsripperDeathInit:                               ; was: sub_35D54
                addq.w  #2,4(a5)
                move.w  #3,(StageSpawnCountdown).w
                jsr     (Sprite_ClearObjectFlags).l
                clr.w   2(a5)
                move.w  #$C0,$4C(a5)
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   Boss_JetsripperDeathInitSegmentEffects
                move.w  #$EC,(a0)
                clr.w   4(a0)
                move.w  #$CD00,2(a0)
                move.w  #$8300,$E(a0)
                move.l  #Boss_JetsripperSharedSegmentBaseFrame,8(a0)
                move.l  #Boss_JetsripperHeadFrames,$4C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                clr.w   $48(a0)
Boss_JetsripperDeathInitSegmentEffects:                 ; was: loc_35DAA
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                moveq   #$10,d7
Boss_JetsripperDeathInitNextSegment:                    ; was: loc_35DB0
                move.w  #$EC,(a0)
                move.w  #$CD00,2(a0)
                move.l  #Boss_JetsripperBodyDirectionFrames,$4C(a0)
                clr.w   4(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_JetsripperDeathInitNextSegment
                suba.w  #$60,a0                         ; '`'
                move.l  #Boss_JetsripperTailFrames,$4C(a0)
Boss_JetsripperDeathStateReturn:                        ; was: locret_35DDA
                rts
; End of function Boss_JetsripperDeathInit
; Handles Jetsripper death fade animation
Boss_JetsripperDeathFade:                               ; was: sub_35DDC
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$4C(a5)
                bpl.s   Boss_JetsripperDeathStateReturn
                moveq   #0,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; End of function Boss_JetsripperDeathFade
; Adjusts radius parameter toward target value 0xC0
Boss_JetsripperAdjustRadius:                            ; was: sub_35DF2
                                        ; sub_35922   p
                move.w  $54(a5),d0
                cmpi.w  #$C0,d0
                bpl.s   Boss_JetsripperAdjustRadiusDecrease
                addi.w  #$A,d0
                cmpi.w  #$B5,d0
                bmi.s   Boss_JetsripperAdjustRadiusStore
Boss_JetsripperAdjustRadiusClamp:                       ; was: loc_35E06
                move.w  #$C0,$54(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JetsripperAdjustRadiusDecrease:                    ; was: loc_35E0E
                subi.w  #$A,d0
                cmpi.w  #$CB,d0
                bmi.s   Boss_JetsripperAdjustRadiusClamp
Boss_JetsripperAdjustRadiusStore:                       ; was: loc_35E18
                move.w  d0,$54(a5)
                rts
; End of function Boss_JetsripperAdjustRadius
