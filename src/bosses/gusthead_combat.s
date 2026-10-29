Boss_GustheadSpawnFragmentCluster:                      ; was: sub_3FA7C
                                        ; Boss_GustheadBeginFinalPhaseTransitionState+4E   p
                tst.w   (DifficultyMode).w
                beq.s   Boss_GustheadSpawnFragmentClusterReturn
                move.w  #2,d3
                move.w  $674(a5),d6
                move.w  $10(a5),d0
                sub.w   (PlayerCenterX).w,d0
                bmi.s   Boss_GustheadAimFragmentClusterRight
                move.w  #$10,d4
                move.w  $670(a5),d5
                subi.w  #$34,d5                         ; '4'
                bra.s   Boss_GustheadEmitFragmentCluster
; ---------------------------------------------------------------------------
Boss_GustheadAimFragmentClusterRight:
                move.w  #0,d4
                move.w  $670(a5),d5
Boss_GustheadEmitFragmentCluster:
                jsr     (Projectile_SpawnFragmentCluster).l
Boss_GustheadSpawnFragmentClusterReturn:                ; was: locret_3FAB0
                rts
; End of function Boss_GustheadSpawnFragmentCluster
; Flashes the root sprite before fragment-pattern repositioning
Boss_GustheadFragmentPatternFlashState:                 ; was: sub_3FAB2
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_GustheadFragmentPatternFlashCountDown
                eori.w  #$8000,2(a5)
Boss_GustheadFragmentPatternFlashCountDown:             ; was: loc_3FAD6
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFragmentPatternFlashReturn
                move.w  #$20,$48(a5)                    ; ' '
                move.w  #$200,$14(a5)
                addq.w  #2,4(a5)
Boss_GustheadFragmentPatternFlashReturn:                ; was: locret_3FAEC
                rts
; End of function Boss_GustheadFragmentPatternFlashState
; Repositions the boss from a random world-space offset during the fragment pattern
Boss_GustheadFragmentPatternRepositionState:            ; was: sub_3FAEE
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFragmentPatternRepositionReturn
                addq.w  #2,4(a5)
                move.w  #$1190,d0
                move.w  (RandomNumberState).w,d1
                andi.w  #$FF,d1
                subi.w  #$80,d1
                add.w   d1,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  #$F0,$14(a5)
Boss_GustheadFragmentPatternRepositionReturn:           ; was: locret_3FB2C
                rts
; End of function Boss_GustheadFragmentPatternRepositionState
; Decelerates the outer-joint spin before the fragment-pattern reveal
Boss_GustheadDecelerateFragmentPatternRotationState:    ; was: sub_3FB2E
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_GustheadReduceFragmentPatternRotationSpeed
                eori.w  #$8000,2(a5)
Boss_GustheadReduceFragmentPatternRotationSpeed:        ; was: loc_3FB52
                subi.l  #$2000,(SharedScratchLong3).w
                cmpi.l  #$80000,(SharedScratchLong3).w
                bne.s   Boss_GustheadFragmentPatternRotationReturn
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Boss_GustheadFragmentPatternRotationReturn:             ; was: locret_3FB6E
                rts
; End of function Boss_GustheadDecelerateFragmentPatternRotationState
; Flashes the root sprite before returning to regular pattern selection
Boss_GustheadFragmentPatternRevealState:                ; was: sub_3FB70
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFragmentPatternRevealReturn
                ori.w   #$8000,2(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Boss_GustheadFragmentPatternRevealReturn:               ; was: locret_3FBA0
                rts
; End of function Boss_GustheadFragmentPatternRevealState
; Returns from the fragment pattern to regular pattern selection
Boss_GustheadReturnToPatternChoiceAfterFragmentsState:  ; was: sub_3FBA2
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadReturnAfterFragmentsReturn
                move.b  #$50,$21(a5)                    ; 'P'
                move.w  #$10,4(a5)
Boss_GustheadReturnAfterFragmentsReturn:                ; was: locret_3FBC8
                rts
; End of function Boss_GustheadReturnToPatternChoiceAfterFragmentsState
; Begins an arena-boundary transition by damping all three joint speeds
Boss_GustheadBeginArenaTransitionState:                 ; was: sub_3FBCA
                move.l  (SharedScratchLong3).w,d0
                asr.l   #2,d0
                move.l  d0,(SharedScratchLong3).w
                move.l  (SharedScratchLong4).w,d0
                asr.l   #2,d0
                move.l  d0,(SharedScratchLong4).w
                move.l  (SharedScratchLong5).w,d0
                asr.l   #2,d0
                move.l  d0,(SharedScratchLong5).w
                addq.w  #2,4(a5)
; Waits for the arena transition signal before returning to pattern selection
Boss_GustheadWaitForArenaTransitionState:               ; was: loc_3FBEC
                                        ; ROM:0003F288   o
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                addq.w  #2,(BossCombatCounter).w
                btst    #0,(BossCounterMaxFlag).w
                beq.s   Boss_GustheadArenaTransitionReturn
                bclr    #6,$4A(a5)
                move.w  #$10,4(a5)
Boss_GustheadArenaTransitionReturn:                     ; was: locret_3FC18
                rts
; End of function Boss_GustheadBeginArenaTransitionState
; Begins the scripted rise into the final phase
Boss_GustheadBeginFinalPhaseTransitionState:            ; was: sub_3FC1A
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$4C(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
; Accelerates the outer-joint spin during the final-phase rise
Boss_GustheadFinalPhaseRiseState:                       ; was: loc_3FC32
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                eori.w  #$8000,2(a5)
                addi.l  #$2000,(SharedScratchLong3).w
                cmpi.l  #$100000,(SharedScratchLong3).w
                bne.s   Boss_GustheadFinalPhaseRiseReturn
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                jsr     Boss_GustheadSpawnFragmentCluster(pc)  ; (pc)
Boss_GustheadFinalPhaseRiseReturn:                      ; was: locret_3FC6C
                rts
; End of function Boss_GustheadBeginFinalPhaseTransitionState
; Flashes the root sprite before final-phase positioning
Boss_GustheadFinalPhaseFlashState:                      ; was: sub_3FC6E
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_GustheadFinalPhaseFlashCountDown
                eori.w  #$8000,2(a5)
Boss_GustheadFinalPhaseFlashCountDown:                  ; was: loc_3FC92
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFinalPhaseFlashReturn
                move.w  #$80,$48(a5)
                move.w  #$200,$14(a5)
                addq.w  #2,4(a5)
Boss_GustheadFinalPhaseFlashReturn:                     ; was: locret_3FCA8
                rts
; End of function Boss_GustheadFinalPhaseFlashState
; Moves the boss to the fixed final-phase screen position
Boss_GustheadFinalPhasePositioningState:                ; was: sub_3FCAA
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFinalPhasePositioningReturn
                move.w  #$198,$10(a5)
                move.w  #$F0,$14(a5)
                addq.w  #2,4(a5)
Boss_GustheadFinalPhasePositioningReturn:               ; was: locret_3FCD4
                rts
; End of function Boss_GustheadFinalPhasePositioningState
; Decelerates outer-joint rotation before the final-phase reveal
Boss_GustheadDecelerateFinalPhaseRotationState:         ; was: sub_3FCD6
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_GustheadReduceFinalPhaseRotationSpeed
                eori.w  #$8000,2(a5)
Boss_GustheadReduceFinalPhaseRotationSpeed:             ; was: loc_3FCFA
                subi.l  #$2000,(SharedScratchLong3).w
                cmpi.l  #$80000,(SharedScratchLong3).w
                bne.s   Boss_GustheadFinalPhaseRotationReturn
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_GustheadFinalPhaseRotationReturn:                  ; was: locret_3FD16
                rts
; End of function Boss_GustheadDecelerateFinalPhaseRotationState
; Flashes the root sprite during the final-phase reveal
Boss_GustheadFinalPhaseRevealState:                     ; was: sub_3FD18
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadFinalPhaseRevealReturn
                ori.w   #$8000,2(a5)
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_GustheadFinalPhaseRevealReturn:                    ; was: locret_3FD48
                rts
; End of function Boss_GustheadFinalPhaseRevealState
; Activates the final battle phase by restoring hit points and collision mode
Boss_GustheadActivateFinalPhaseState:                   ; was: sub_3FD4A
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadUpdateArenaScrollVelocity
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadUpdateVerticalBounce
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadActivateFinalPhaseReturn
                move.b  #$50,$21(a5)                    ; 'P'
                move.b  #$10,$23(a5)
                addq.w  #2,4(a5)
Boss_GustheadActivateFinalPhaseReturn:                  ; was: locret_3FD74
                rts
; End of function Boss_GustheadActivateFinalPhaseState
; Selects the final battle pattern and enters its motion initializer
Boss_GustheadBeginFinalBattle:                          ; was: sub_3FD76
                move.w  #6,$5A(a5)
                move.w  #$50,4(a5)                      ; 'P'
                bra.w   *+4
; ---------------------------------------------------------------------------
; Initializes joint, body, and arena motion for the final battle
Boss_GustheadInitializeFinalBattleMotion:               ; was: loc_3FD86
                addq.w  #2,4(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$4C(a5)
                clr.l   (StageMotionXDelta).w
                clr.l   (SharedScratchLong3).w
                clr.l   (SharedScratchLong4).w
                clr.l   (SharedScratchLong5).w
                andi.l  #$1F80000,(SharedScratchLong0).w
                andi.l  #$1F80000,(SharedScratchLong1).w
                andi.l  #$1F80000,(SharedScratchLong2).w
                move.w  #$F0,$14(a5)
                move.w  #$E,$24(a5)
; Aligns the middle joint before the final battle rotation
Boss_GustheadAlignJointsForFinalBattleState:            ; was: loc_3FDCE
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadMoveTowardVerticalTarget
                subi.w  #8,(SharedScratchLong1).w
                andi.w  #$1F8,(SharedScratchLong1).w
                cmpi.w  #$1E0,(SharedScratchLong1).w
                bne.s   Boss_GustheadAlignJointsForFinalBattleReturn
                addq.w  #2,4(a5)
Boss_GustheadAlignJointsForFinalBattleReturn:           ; was: locret_3FDF2
                rts
; End of function Boss_GustheadBeginFinalBattle
; Accelerates final-battle arena rotation to its signed speed limit
Boss_GustheadAccelerateFinalBattleRotationState:        ; was: sub_3FDF4
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadMoveTowardVerticalTarget
                cmpi.l  #$1D000,(GustheadArenaVelocity).w
                beq.s   Boss_GustheadAccelerateFinalBattleSpin
                addi.l  #$200,(GustheadArenaVelocity).w
Boss_GustheadAccelerateFinalBattleSpin:                 ; was: loc_3FE16
                move.b  #$88,$23(a5)
                subi.l  #$800,(SharedScratchLong3).w
                cmpi.l  #$FFF00000,(SharedScratchLong3).w
                bcs.s   Boss_GustheadAccelerateFinalBattleRotationReturn
                move.l  #$FFF00000,(SharedScratchLong3).w
                addq.w  #2,4(a5)
Boss_GustheadAccelerateFinalBattleRotationReturn:       ; was: locret_3FE3A
                rts
; End of function Boss_GustheadAccelerateFinalBattleRotationState
; Waits for final-battle arena motion to reach its attack threshold
Boss_GustheadWaitForFinalBattleScrollState:             ; was: sub_3FE3C
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadMoveTowardVerticalTarget
                cmpi.l  #$1D000,(GustheadArenaVelocity).w
                beq.s   Boss_GustheadBeginFinalBattleAttackDelay
                addi.l  #$200,(GustheadArenaVelocity).w
                rts
; ---------------------------------------------------------------------------
Boss_GustheadBeginFinalBattleAttackDelay:               ; was: loc_3FE60
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_GustheadWaitForFinalBattleScrollState
; Fires fragment clusters at selected arena angles during the final battle
Boss_GustheadFinalBattleAttackState:                    ; was: sub_3FE6C
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadMoveTowardVerticalTarget
                move.w  (PrimaryCameraXPosition).w,d1
                tst.w   (DifficultyMode).w
                bne.s   Boss_GustheadUseNonzeroDifficultyAngleOffset
                addi.w  #$40,d1                         ; '@'
                bra.s   Boss_GustheadCheckFinalBattleAttackAngle
; ---------------------------------------------------------------------------
Boss_GustheadUseNonzeroDifficultyAngleOffset:           ; was: loc_3FE8C
                subi.w  #$10,d1
Boss_GustheadCheckFinalBattleAttackAngle:               ; was: loc_3FE90
                move.w  d1,d0
                andi.w  #$7E,d0                         ; '~'
                bne.s   Boss_GustheadFinalBattleAttackReturn
                addq.w  #2,4(a5)
                move.w  d1,d0
                andi.w  #$1FE,d0
                cmpi.w  #$100,d0
                beq.s   Boss_GustheadFinalBattleAttackReturn
                bra.s   Boss_GustheadFireFinalBattleFragmentCluster
; ---------------------------------------------------------------------------
Boss_GustheadFinalBattleAttackReturn:                   ; was: locret_3FEAA
                                        ; Boss_GustheadFinalBattleAttackState+3A   j
                rts
; ---------------------------------------------------------------------------
Boss_GustheadFireFinalBattleFragmentCluster:            ; was: loc_3FEAC
                move.w  #2,d3
                move.w  #$10,d4
                move.w  $670(a5),d5
                subi.w  #$34,d5                         ; '4'
                move.w  $674(a5),d6
                jsr     (Projectile_SpawnFragmentCluster).l
                andi.w  #$FEFF,2(a0)
                rts
; End of function Boss_GustheadFinalBattleAttackState
; Loops the final battle attack until the arena reaches its hold angle
Boss_GustheadFinalBattleLoopState:                      ; was: sub_3FECE
                bsr.w   Boss_GustheadAdvanceJointAngles
                bsr.w   Boss_GustheadUpdateSegmentPositions
                bsr.w   Boss_GustheadSpawnScrollingDebris
                bsr.w   Boss_GustheadMoveTowardVerticalTarget
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$10,d0
                andi.w  #$7E,d0                         ; '~'
                beq.s   Boss_GustheadFinalBattleLoopReturn
                subq.w  #2,4(a5)
Boss_GustheadFinalBattleLoopReturn:                     ; was: locret_3FEF0
                rts
; End of function Boss_GustheadFinalBattleLoopState
; Hide Gusthead, clear vertical velocity, and enter the defeat sequence
Boss_GustheadBeginDefeatState:                          ; was: sub_3FEF2
                clr.b   $21(a5)
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_GustheadBeginDefeatState
; Emit defeat effects while decelerating the rotating arena
Boss_GustheadDecelerateArenaDuringDefeatState:          ; was: sub_3FF00
                bsr.w   Boss_UpdateDefeatExplosionAndSpawnDebris
                cmpi.l  #$E800,(GustheadArenaVelocity).w
                bmi.s   Boss_GustheadFinishDefeatArenaDeceleration
                subi.l  #$200,(GustheadArenaVelocity).w
                rts
; ---------------------------------------------------------------------------
Boss_GustheadFinishDefeatArenaDeceleration:             ; was: loc_3FF18
                addq.w  #2,4(a5)
                rts
; End of function Boss_GustheadDecelerateArenaDuringDefeatState
; Accelerate Gusthead downward while emitting defeat explosions
Boss_GustheadFallAndExplodeDuringDefeatState:           ; was: sub_3FF1E
                addi.l  #$1000,$1C(a5)
                bsr.w   Boss_UpdateDefeatExplosionAndSpawnDebris
                eori.w  #$8000,2(a5)
                cmpi.w  #$180,$14(a5)
                blt.s   Boss_GustheadFallAndExplodeDuringDefeatReturn
                addq.w  #2,4(a5)
                clr.l   $1C(a5)
                clr.w   $48(a5)
Boss_GustheadFallAndExplodeDuringDefeatReturn:          ; was: locret_3FF44
                rts
; End of function Boss_GustheadFallAndExplodeDuringDefeatState
; Update the shared boss defeat explosion and spawn one randomized debris object
Boss_UpdateDefeatExplosionAndSpawnDebris:               ; was: sub_3FF46
                                        ; Boss_GustheadDecelerateArenaDuringDefeatState   p
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                jsr     (Projectile_PrepareImpactSpawnOrPlaySound).l
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_UpdateDefeatExplosionAndSpawnDebrisReturn
                jsr     (Projectile_InitType88).l
                clr.b   $20(a0)
                move.w  #$FFFA,$1C(a0)
                move.w  (RandomNumberState+2).w,$1E(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$1F,d1
                subi.w  #$24,d0                         ; '$'
                subi.w  #$24,d1                         ; '$'
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
                move.b  (RandomNumberState+2).w,d0
                andi.w  #7,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Boss_DefeatExplosionDebrisAnimations(pc,d0.w),8(a0)
Boss_UpdateDefeatExplosionAndSpawnDebrisReturn:         ; was: locret_3FFC2
                rts
; End of function Boss_UpdateDefeatExplosionAndSpawnDebris
; ---------------------------------------------------------------------------
Boss_DefeatExplosionDebrisAnimations:   dc.l    SharedCombatSpriteAnimation00  ; was: off_3FFC4
                dc.l    SharedCombatSpriteAnimation03
                dc.l    SharedCombatSpriteAnimation01
                dc.l    SharedCombatSpriteAnimation04
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation05
                dc.l    SharedCombatSpriteAnimation02
                dc.l    SharedCombatSpriteAnimation06

; Advance Gusthead's defeat palette step and start its four-frame hold
Boss_GustheadAdvanceDefeatPaletteFadeState:             ; was: sub_3FFE4
                bsr.s   Boss_GustheadApplyDefeatPaletteStep
                addq.w  #1,(SharedScratchLong9).w
                cmpi.w  #$F,(SharedScratchLong9).w
                bne.s   Boss_GustheadAdvanceDefeatPaletteFadeReturn
                move.w  #4,(SharedScratchLong9+2).w
                addq.w  #2,4(a5)
Boss_GustheadAdvanceDefeatPaletteFadeReturn:            ; was: locret_3FFFC
                rts
; End of function Boss_GustheadAdvanceDefeatPaletteFadeState
; Apply the current Gusthead defeat step to the complete active palette
Boss_GustheadApplyDefeatPaletteStep:                    ; was: sub_3FFFE
                                        ; Boss_GustheadHoldDefeatPaletteState   p
                move.w  (SharedScratchLong9).w,d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_GustheadApplyDefeatPaletteStep
; Hold the terminal defeat palette for four frames
Boss_GustheadHoldDefeatPaletteState:                    ; was: sub_40018
                bsr.s   Boss_GustheadApplyDefeatPaletteStep
                subq.w  #1,(SharedScratchLong9+2).w
                bne.s   Boss_GustheadDefeatPaletteHoldReturn
                addq.w  #2,4(a5)
Boss_GustheadDefeatPaletteHoldReturn:                   ; was: locret_40024
                rts
; End of function Boss_GustheadHoldDefeatPaletteState
; Reverse the defeat palette step, then clear non-preserved objects
Boss_GustheadReverseDefeatPaletteAndClearObjectsState:  ; was: sub_40026
                bsr.s   Boss_GustheadApplyDefeatPaletteStep
                subq.w  #1,(SharedScratchLong9).w
                bpl.s   Boss_GustheadDefeatPaletteReverseReturn
                addq.w  #2,4(a5)
                move.w  #$1B0,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; ---------------------------------------------------------------------------
Boss_GustheadDefeatPaletteReverseReturn:                ; was: locret_4003E
                rts
; End of function Boss_GustheadReverseDefeatPaletteAndClearObjectsState
; Stop the arena only at an aligned camera boundary, then start removal delay
Boss_GustheadStopArenaAtAlignedBoundaryState:           ; was: sub_40040
                tst.l   (GustheadArenaVelocity).w
                beq.s   Boss_GustheadBeginPostDefeatRemovalDelay
                move.w  (PrimaryCameraXPosition).w,d0
                andi.w  #$7F,d0
                bne.s   Boss_GustheadStopArenaAtAlignedBoundaryReturn
                clr.l   (GustheadArenaVelocity).w
Boss_GustheadBeginPostDefeatRemovalDelay:               ; was: loc_40054
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_GustheadStopArenaAtAlignedBoundaryReturn:          ; was: locret_4005E
                rts
; End of function Boss_GustheadStopArenaAtAlignedBoundaryState
; Remove Gusthead after the post-defeat delay
Boss_GustheadRemoveAfterDefeatDelayState:               ; was: sub_40060
                subq.w  #1,$48(a5)
                bne.s   Boss_GustheadRemoveAfterDefeatDelayReturn
                clr.w   (a5)
                bset    #4,2(a5)
Boss_GustheadRemoveAfterDefeatDelayReturn:              ; was: locret_4006E
                rts
; End of function Boss_GustheadRemoveAfterDefeatDelayState
; Updates attached Gusthead segments or dispatches detached-segment motion
Boss_GustheadSegmentMain:                               ; was: sub_40070
                btst    #7,(PrimaryEntityWork4A).w
                bne.w   Boss_GustheadDispatchDetachedSegmentState
                clr.w   d1
                clr.w   d2
                clr.w   d3
                move.w  (PrimaryEntityFlags).w,d0
                andi.w  #$8000,d0
                andi.w  #$7FFF,2(a5)
                or.w    d0,2(a5)
                tst.b   $4A(a5)
                bne.s   Boss_GustheadSegmentReadPreviousAngles
                move.b  $4B(a5),d1
                add.w   d1,d1
                add.w   (SharedScratchLong0).w,d1
                andi.w  #$1FF,d1
                move.w  d1,$4E(a5)
                asr.w   #1,d1
                move.w  (SharedScratchLong1).w,d2
                move.w  d2,$50(a5)
                asr.w   #1,d2
                move.w  (SharedScratchLong2).w,d3
                move.w  d3,$52(a5)
                asr.w   #1,d3
                bra.s   Boss_GustheadSegmentShiftJointAngles
; ---------------------------------------------------------------------------
Boss_GustheadSegmentReadPreviousAngles:                 ; was: loc_400C2
                movea.w a5,a0
                lea     -$60(a0),a0
                move.b  $57(a0),d1
                move.w  d1,$4E(a5)
                move.b  $5B(a0),d2
                move.w  d2,$50(a5)
                move.b  $5F(a0),d3
                move.w  d3,$52(a5)
                add.w   d1,$4E(a5)
                add.w   d2,$50(a5)
                add.w   d3,$52(a5)
Boss_GustheadSegmentShiftJointAngles:                   ; was: loc_400EC
                lea     $54(a5),a1
                lea     $58(a5),a2
                lea     $5C(a5),a3
                move.w  #3,d7
Boss_GustheadSegmentShiftAngleLoop:                     ; was: loc_400FC
                move.b  (a1),d4
                move.b  d1,(a1)+
                move.b  d4,d1
                move.b  (a2),d5
                move.b  d2,(a2)+
                move.b  d5,d2
                move.b  (a3),d6
                move.b  d3,(a3)+
                move.b  d6,d3
                dbf     d7,Boss_GustheadSegmentShiftAngleLoop
                bsr.w   Boss_GustheadUpdateSegmentMapping
                rts
; ---------------------------------------------------------------------------
Boss_GustheadDispatchDetachedSegmentState:              ; was: loc_40118
                move.l  (GustheadArenaVelocity).w,d0
                add.l   d0,$10(a5)
                move.w  4(a5),d0
                lea     Boss_GustheadDetachedSegmentStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_GustheadSegmentMain
; ---------------------------------------------------------------------------
Boss_GustheadDetachedSegmentStates: dc.w    Boss_GustheadDetachedSegmentInit-*  ; was: off_4012C
                dc.w    Boss_GustheadDetachedSegmentFallState-*
                dc.w    Boss_GustheadDetachedSegmentInactiveState-*

; Initializes a detached Gusthead segment from its stored joint angle
