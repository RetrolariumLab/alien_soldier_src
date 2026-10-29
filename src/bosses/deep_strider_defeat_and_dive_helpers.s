; Starts the final defeat sequence after the boss counter reaches zero
Boss_DeepStriderBeginDefeat:                            ; was: sub_3EBCA
                move.w  #4,(StageSpawnCountdown).w
                move.b  #2,(BossColorEffectFlags).w
                bset    #0,(StageTimerPauseFlag).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #$1E,4(a5)
                move.w  #$CB00,$48(a5)
                move.w  #$CB00,$4A(a5)
                move.w  #$80,$536(a5)
                move.w  #$30,$1DC(a5)                   ; '0'
                move.w  #$1E0,$23C(a5)
                move.w  #$20,$1DE(a5)                   ; ' '
                move.w  #$1E0,$23E(a5)
                move.l  #$FFFBE000,$4FC(a5)
                move.l  #$FFFEE000,$4F8(a5)
                cmpi.w  #$880,$BC(a5)
                bpl.s   Boss_DeepStriderDefeatFallState
                neg.l   $4F8(a5)
; Fades the palette and emits debris while the defeated boss falls
Boss_DeepStriderDefeatFallState:                        ; was: loc_3EC2E
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                bsr.w   Boss_DeepStriderSpawnDefeatDebris
                addi.w  #$10,$56(a5)
                addi.l  #$2000,$4FC(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                cmpi.w  #$150,$4F4(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                move.l  #$FFFEE000,$4FC(a5)
                move.b  #$4D,d0                         ; 'M'
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_DeepStriderSpawnQuadVolley
; End of function Boss_DeepStriderBeginDefeat
; Raises the defeated boss before clearing the remaining stage objects
Boss_DeepStriderDefeatRiseState:                        ; was: sub_3EC7A
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                addi.w  #$10,$56(a5)
                addi.l  #$2000,$4FC(a5)
                cmpi.w  #$180,$4F4(a5)
                bmi.w   Boss_DeepStriderUpdateParts
                addq.w  #2,4(a5)
                move.w  $4F0(a5),$10(a5)
                move.w  #$30,$48(a5)                    ; '0'
                move.w  #$100,2(a5)
                clr.w   8(a5)
                bsr.w   Boss_DeepStriderClearStageObjects
; End of function Boss_DeepStriderDefeatRiseState
; Emits the final vertical burst after the defeat hold timer
Boss_DeepStriderDefeatBurstState:                       ; was: sub_3ECB6
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$48(a5)
                bpl.w   Boss_DeepStriderMotionStateReturn
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #8,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                movea.w a5,a0
                move.l  #$FFF80000,d4
                move.w  $10(a5),d5
Boss_DeepStriderSpawnNextDefeatBurst:                   ; was: loc_3ECE6
                lea     $60(a0),a0
                move.b  #$30,d0                         ; '0'
                jsr     (Sound_QueueSFXRequest).l
                jsr     (Projectile_InitType1A8).l
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                move.l  d4,$1C(a0)
                move.w  #$150,$14(a0)
                move.w  d5,$10(a0)
                addi.l  #$8000,d4
                bmi.s   Boss_DeepStriderSpawnNextDefeatBurst
; End of function Boss_DeepStriderDefeatBurstState
; Waits before hiding the defeated boss object
Boss_DeepStriderDefeatCompletionDelayState:             ; was: sub_3ED18
                subq.w  #1,$48(a5)
                bpl.s   Boss_DeepStriderDefeatCompletionDelayReturn
                bset    #4,2(a5)
Boss_DeepStriderDefeatCompletionDelayReturn:            ; was: locret_3ED24
                rts
; End of function Boss_DeepStriderDefeatCompletionDelayState
; Spawns randomized debris during the final defeat fall
Boss_DeepStriderSpawnDefeatDebris:                      ; was: sub_3ED26
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #1,(PlaneBShakeLevel).w
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_DeepStriderSpawnDefeatDebrisReturn
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   Boss_DeepStriderSpawnDefeatDebrisReturn
                jsr     (Sprite_InitType160).l
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                move.b  (RandomNumberState).w,d1
                andi.w  #3,d1
                bne.s   Boss_DeepStriderApplyDefeatDebrisMotion
                move.l  #SharedCombatSpriteAnimation05,8(a0)
Boss_DeepStriderApplyDefeatDebrisMotion:                ; was: loc_3ED62
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                move.w  $4F0(a5),$10(a0)
                add.w   d0,$10(a0)
                move.w  $4F4(a5),$14(a0)
                move.l  #$FFFC2000,$1C(a0)
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_DeepStriderSpawnDefeatDebrisReturn
                move.b  #$BC,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_DeepStriderSpawnDefeatDebrisReturn:                ; was: locret_3ED9A
                                        ; Boss_DeepStriderSpawnDefeatDebris+1A   j
                rts
; End of function Boss_DeepStriderSpawnDefeatDebris
; Spawns quad projectile pattern
Boss_DeepStriderSpawnQuadVolley:                        ; was: sub_3ED9C
                                        ; Boss_DeepStriderIntroDiveState+72   p
                move.w  $D0(a5),d5
                move.w  #$150,d6
                jmp     Projectile_SpawnFourDirectionalShots
; End of function Boss_DeepStriderSpawnQuadVolley
; Selects the phase-dependent dive start position and velocity
Boss_DeepStriderSetupDivePositionAndVelocity:           ; was: sub_3EDAA
                                        ; Boss_DeepStriderBeginBattleCycle:Boss_DeepStriderInitializeDiveMotion   p
                move.w  #$180,$536(a5)
                clr.w   $11C(a5)
                bsr.w   Boss_DeepStriderCalculatePhaseDiveX
                move.w  d0,$4F0(a5)
                move.w  #$160,$4F4(a5)
                move.w  #$17C,$56(a5)
                move.w  #$1FC,$1DC(a5)
                move.w  #$1A0,$1DE(a5)
                move.w  #$20,$23C(a5)                   ; ' '
                move.w  #$1B0,$23E(a5)
                move.l  #$FFFC4800,$4F8(a5)
                move.l  #$FFFA0000,$4FC(a5)
                tst.w   $54(a5)
                beq.s   Boss_DeepStriderSetupDivePositionReturn
                neg.l   $4F8(a5)
Boss_DeepStriderSetupDivePositionReturn:                ; was: locret_3EDFA
                rts
; End of function Boss_DeepStriderSetupDivePositionAndVelocity
; Calculates the dive start X coordinate for the current phase index
Boss_DeepStriderCalculatePhaseDiveX:                    ; was: sub_3EDFC
                                        ; Boss_DeepStriderSetupDivePositionAndVelocity+A   p
                moveq   #0,d2
                move.w  $29C(a5),d0
                move.w  Boss_DeepStriderDiveXOffsets(pc,d0.w),d0
                move.w  (PrimaryCameraXPosition).w,d1
                subi.w  #$710,d1
                sub.w   d1,d0
                add.w   d2,d0
                rts
; End of function Boss_DeepStriderCalculatePhaseDiveX
; ---------------------------------------------------------------------------
Boss_DeepStriderDiveXOffsets:   dc.w    $90, $170, $250  ; was: word_3EE14

; Boss dive attack sequence
Boss_DeepStriderDiveSequence:                           ; was: sub_3EE1A
                                        ; sub_3EB5A   p
                addq.w  #1,$11C(a5)
                move.b  #$4C,d0                         ; 'L'
                cmpi.w  #3,$11C(a5)
                beq.s   Boss_DeepStriderEmitTimedDiveVolley
                move.b  #$4D,d0                         ; 'M'
                cmpi.w  #$32,$11C(a5)                   ; '2'
                bne.s   Boss_DeepStriderUpdateDiveRotation
Boss_DeepStriderEmitTimedDiveVolley:                    ; was: loc_3EE36
                jsr     (Sound_QueueSFXRequest).l
                bsr.w   Boss_DeepStriderSpawnQuadVolley
Boss_DeepStriderUpdateDiveRotation:                     ; was: loc_3EE40
                subq.w  #4,$56(a5)
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_DeepStriderAdjustDivePrimaryJoint
                addq.w  #1,$56(a5)
Boss_DeepStriderAdjustDivePrimaryJoint:                 ; was: loc_3EE52
                cmpi.w  #$11,$11C(a5)
                bmi.s   Boss_DeepStriderExpandDiveTailJoint
                cmpi.w  #$34,$11C(a5)                   ; '4'
                bpl.s   Boss_DeepStriderRestoreDivePrimaryJoint
                cmpi.w  #$1F4,$1DC(a5)
                beq.s   Boss_DeepStriderExpandDiveTailJoint
                subq.w  #1,$1DC(a5)
                bra.s   Boss_DeepStriderExpandDiveTailJoint
; ---------------------------------------------------------------------------
Boss_DeepStriderRestoreDivePrimaryJoint:                ; was: loc_3EE70
                cmpi.w  #$1FC,$1DC(a5)
                beq.s   Boss_DeepStriderExpandDiveTailJoint
                addq.w  #1,$1DC(a5)
Boss_DeepStriderExpandDiveTailJoint:                    ; was: loc_3EE7C
                                        ; Boss_DeepStriderDiveSequence+4E   j
                cmpi.w  #$1A,$11C(a5)
                bmi.s   Boss_DeepStriderExpandDiveSecondaryJoint
                cmpi.w  #$1F0,$23E(a5)
                beq.s   Boss_DeepStriderExpandDiveSecondaryJoint
                addq.w  #1,$23E(a5)
Boss_DeepStriderExpandDiveSecondaryJoint:               ; was: loc_3EE90
                                        ; Boss_DeepStriderDiveSequence+70   j
                cmpi.w  #$1F8,$1DE(a5)
                beq.s   Boss_DeepStriderDecelerateDiveHorizontal
                addq.w  #1,$1DE(a5)
Boss_DeepStriderDecelerateDiveHorizontal:               ; was: loc_3EE9C
                cmpi.w  #$30,$11C(a5)                   ; '0'
                bmi.s   Boss_DeepStriderAdvanceDiveMotion
                tst.w   $4F8(a5)
                bmi.s   Boss_DeepStriderDecelerateNegativeDiveHorizontal
                subi.l  #$3000,$4F8(a5)
                bra.s   Boss_DeepStriderAdvanceDiveMotion
; ---------------------------------------------------------------------------
Boss_DeepStriderDecelerateNegativeDiveHorizontal:       ; was: loc_3EEB4
                addi.l  #$3000,$4F8(a5)
Boss_DeepStriderAdvanceDiveMotion:                      ; was: loc_3EEBC
                                        ; Boss_DeepStriderDiveSequence+98   j
                bsr.w   Boss_DeepStriderUpdateParts
                addi.l  #$3200,$4FC(a5)
                bmi.w   Boss_DeepStriderMotionStateReturn
                cmpi.w  #$1E0,$14(a5)
                bmi.w   *+4
Boss_DeepStriderMotionStateReturn:                      ; was: locret_3EED6
                                        ; Boss_DeepStriderDefeatBurstState+A   j
                rts
; End of function Boss_DeepStriderDiveSequence
