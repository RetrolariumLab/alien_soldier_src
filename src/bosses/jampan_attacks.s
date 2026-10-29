; Jampan offset and shield attacks, defeat sequence, and post-defeat movement

Boss_JampanMoveOffsetAttackAcrossScreenState:           ; was: sub_49A14
                eori.w  #$8000,(SeventhEntityFlags).w
                bsr.w   Boss_JampanTrackVerticalOrbitOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                move.w  $5A(a5),d0
                move.w  d0,d1
                add.w   $58(a5),d0
                cmpi.w  #$1440,d0
                bhi.s   Boss_JampanFinishOffsetAttack
                cmpi.w  #$1300,d0
                bcs.s   Boss_JampanFinishOffsetAttack
                add.w   d1,$10(a5)
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanMoveOffsetAttackAcrossScreenReturn
                ori.w   #$8000,(SeventhEntityFlags).w
                move.w  #1,(SeventhEntityWork52).w
                move.w  #1,(TertiaryEntityWork52).w
                move.w  #1,(FifthEntityWork52).w
                tst.w   (BossCombatCounter).w
                ble.s   Boss_JampanFinishOffsetAttack
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishOffsetAttack:
                                        ; Boss_JampanMoveOffsetAttackAcrossScreenState+22   j
                ori.w   #$8000,(SeventhEntityFlags).w
                bset    #1,$4C(a5)
                move.w  #$12,4(a5)
Boss_JampanMoveOffsetAttackAcrossScreenReturn:
                rts
; End of function Boss_JampanMoveOffsetAttackAcrossScreenState
Boss_JampanNoOpState2A:
                rts
; End of function Boss_JampanNoOpState2A

Boss_JampanNoOpState2C:
                rts
; End of function Boss_JampanNoOpState2C

; Converges the shield-cycle vertical orbit offset on zero
Boss_JampanNormalizeShieldCycleVerticalOffsetState:     ; was: sub_49A7E
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (SharedScratchLong10).w
                beq.s   Boss_JampanBeginShieldCycleDelay
                tst.w   (SharedScratchLong10).w
                bmi.s   Boss_JampanIncreaseShieldCycleVerticalOffset
                subq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanIncreaseShieldCycleVerticalOffset:
                addq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanBeginShieldCycleDelay:
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanNormalizeShieldCycleVerticalOffsetState
; Delays before enabling and positioning the six shield objects
Boss_JampanShieldCycleDelayState:                       ; was: sub_49AAE
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanShieldCycleDelayReturn
                bsr.w   Boss_JampanEnableShields
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                addq.w  #2,4(a5)
Boss_JampanShieldCycleDelayReturn:
                rts
; End of function Boss_JampanShieldCycleDelayState
; Expands the shared shield-formation radius to $18
Boss_JampanExpandShieldRadiusState:                     ; was: sub_49ACE
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                addq.w  #1,(SharedScratchLong11).w
                cmpi.w  #$18,(SharedScratchLong11).w
                bne.s   Boss_JampanExpandShieldRadiusReturn
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_JampanExpandShieldRadiusReturn:
                rts
; End of function Boss_JampanExpandShieldRadiusState
; Holds the expanded shield formation before rotation
Boss_JampanShieldCyclePauseState:                       ; was: sub_49AF6
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                subq.w  #1,$48(a5)
                bne.w   Boss_JampanShieldCyclePauseReturn
                move.w  #$14,$48(a5)
                addq.w  #2,4(a5)
                bclr    #1,$4C(a5)
                move.w  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_JampanShieldCyclePauseReturn:
                rts
; End of function Boss_JampanShieldCyclePauseState
; Rotates the primary shield-pattern angle forward for $14 frames
Boss_JampanRotateShieldPatternForwardState:             ; was: sub_49B2A
                addq.w  #4,(SharedScratchLong1).w
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                subq.w  #1,$48(a5)
                bne.w   Boss_JampanRotateShieldPatternForwardReturn
                move.w  #$14,$48(a5)
                addq.w  #2,4(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.w  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_JampanRotateShieldPatternForwardReturn:
                rts
; End of function Boss_JampanRotateShieldPatternForwardState
; Rotates the primary shield-pattern angle backward and selects repeat/recovery
Boss_JampanRotateShieldPatternBackwardState:            ; was: sub_49B64
                subq.w  #4,(SharedScratchLong1).w
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                subq.w  #1,$48(a5)
                bne.w   Boss_JampanRotateShieldPatternBackwardReturn
                bset    #1,$4C(a5)
                tst.w   (BossCombatCounter).w
                ble.s   Boss_JampanFinishShieldRotationCycle
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                bpl.s   Boss_JampanUseAbsolutePlayerHorizontalDelta
                neg.w   d0
Boss_JampanUseAbsolutePlayerHorizontalDelta:
                cmpi.w  #$80,d0
                bcc.s   Boss_JampanFinishShieldRotationCycle
                move.w  #$10,$48(a5)
                subq.w  #4,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishShieldRotationCycle:
                                        ; Boss_JampanRotateShieldPatternBackwardState+34   j
                move.w  #2,(SecondaryEntityWork52).w
                move.w  #2,(QuaternaryEntityWork52).w
                clr.b   (TwentyThirdEntityStatus).w
                addq.w  #2,4(a5)
Boss_JampanRotateShieldPatternBackwardReturn:
                rts
; End of function Boss_JampanRotateShieldPatternBackwardState
; Collapses the shield-formation radius and disables the six shields
Boss_JampanCollapseShieldRadiusState:                   ; was: sub_49BBC
                bsr.w   Boss_JampanTrackPlayerAimOffset
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                subq.w  #1,(SharedScratchLong11).w
                bne.s   Boss_JampanCollapseShieldRadiusReturn
                clr.w   (TertiaryEntityWork52).w
                clr.w   (FifthEntityWork52).w
                bsr.w   Boss_JampanDisableShields
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_JampanCollapseShieldRadiusReturn:
                rts
; End of function Boss_JampanCollapseShieldRadiusState
; Waits before restoring linked-part states and returning to selection
Boss_JampanShieldCycleRecoveryDelayState:               ; was: sub_49BE6
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanShieldCycleRecoveryDelayReturn
                move.w  #1,(TertiaryEntityWork52).w
                move.w  #1,(FifthEntityWork52).w
                move.w  #$12,4(a5)
Boss_JampanShieldCycleRecoveryDelayReturn:
                rts
; End of function Boss_JampanShieldCycleRecoveryDelayState
; Converges shared offsets and initializes the alternate combat pattern
Boss_JampanInitializeAlternatePatternState:             ; was: sub_49C04
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                tst.w   (SharedScratchLong9+2).w
                beq.s   Boss_JampanUpdateAlternateSecondaryOffset
                tst.w   (SharedScratchLong9+2).w
                bmi.s   Boss_JampanIncreaseAlternatePrimaryOffset
                subq.w  #1,(SharedScratchLong9+2).w
                bra.s   Boss_JampanUpdateAlternateSecondaryOffset
; ---------------------------------------------------------------------------
Boss_JampanIncreaseAlternatePrimaryOffset:
                addq.w  #1,(SharedScratchLong9+2).w
Boss_JampanUpdateAlternateSecondaryOffset:
                                        ; Boss_JampanInitializeAlternatePatternState+14   j
                tst.w   (SharedScratchLong10).w
                beq.s   Boss_JampanFinishAlternatePatternInitialization
                tst.w   (SharedScratchLong10).w
                bmi.s   Boss_JampanIncreaseAlternateSecondaryOffset
                subq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanIncreaseAlternateSecondaryOffset:
                addq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanFinishAlternatePatternInitialization:
                tst.w   (SharedScratchLong9+2).w
                bne.s   Boss_JampanInitializeAlternatePatternReturn
                bclr    #2,$4C(a5)
                clr.l   $1C(a5)
                clr.l   $54(a5)
                clr.w   (SeventhEntityWork52).w
                move.w  #3,(SecondaryEntityWork52).w
                move.w  #3,(QuaternaryEntityWork52).w
                andi.w  #$1FC,(SharedScratchLong2).w
                move.w  #4,(SharedScratchLong5).w
                move.w  #4,(SharedScratchLong4).w
                addq.w  #2,4(a5)
Boss_JampanInitializeAlternatePatternReturn:
                rts
; End of function Boss_JampanInitializeAlternatePatternState
; Waits for the alternate pattern angle to reach $180
Boss_JampanWaitForAlternatePatternAngleState:           ; was: sub_49C72
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                cmpi.w  #$180,(SharedScratchLong2).w
                bne.s   Boss_JampanWaitForAlternatePatternAngleReturn
                clr.w   (SharedScratchLong5).w
                bsr.w   Boss_JampanEnableShields
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                addq.w  #2,4(a5)
Boss_JampanWaitForAlternatePatternAngleReturn:
                rts
; End of function Boss_JampanWaitForAlternatePatternAngleState
; Expands the alternate pattern radius while accelerating its angle
Boss_JampanExpandAlternatePatternState:                 ; was: sub_49C90
                cmpi.l  #$80000,(SharedScratchLong4).w
                beq.s   Boss_JampanUpdateExpandedAlternatePattern
                addi.l  #$4000,(SharedScratchLong4).w
Boss_JampanUpdateExpandedAlternatePattern:
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                addq.w  #1,(SharedScratchLong11).w
                cmpi.w  #$18,(SharedScratchLong11).w
                bcs.s   Boss_JampanExpandAlternatePatternReturn
                move.w  #$18,(SharedScratchLong11).w
                move.w  #$A0,(TwentyThirdEntityWork26).w
                addq.w  #2,4(a5)
Boss_JampanExpandAlternatePatternReturn:
                rts
; End of function Boss_JampanExpandAlternatePatternState
; Starts the alternate pattern's timed hold
Boss_JampanBeginAlternatePatternHoldState:              ; was: sub_49CC8
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
                bclr    #1,$4C(a5)
                rts
; End of function Boss_JampanBeginAlternatePatternHoldState
; Tracks the player during the alternate pattern hold
Boss_JampanTrackPlayerDuringAlternatePatternState:      ; was: sub_49CE2
                cmpi.w  #$C0,$48(a5)
                bcs.s   Boss_JampanUpdateAlternatePatternHold
                bsr.w   Boss_JampanTrackPlayerY
Boss_JampanUpdateAlternatePatternHold:
                bsr.w   Boss_JampanTrackPlayerX
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                tst.w   (BossCombatCounter).w
                ble.s   Boss_JampanFinishAlternatePatternHold
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanTrackPlayerDuringAlternatePatternReturn
Boss_JampanFinishAlternatePatternHold:
                bset    #1,$4C(a5)
                addq.w  #2,4(a5)
Boss_JampanTrackPlayerDuringAlternatePatternReturn:
                rts
; End of function Boss_JampanTrackPlayerDuringAlternatePatternState
; Moves vertically toward screen Y $F0 before enabling oscillation
Boss_JampanCenterAlternatePatternVerticallyState:       ; was: sub_49D12
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                move.w  $14(a5),d0
                subi.w  #$F0,d0
                beq.s   Boss_JampanBeginAlternatePatternOscillation
                tst.w   d0
                bpl.s   Boss_JampanMoveAlternatePatternUpward
                addq.w  #1,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanMoveAlternatePatternUpward:
                subq.w  #1,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JampanBeginAlternatePatternOscillation:
                bset    #2,$4C(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.l  #$2000,$54(a5)
                andi.w  #$1F8,(SharedScratchLong1).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanCenterAlternatePatternVerticallyState
; Waits for the alternate pattern's primary angle to reach $100
Boss_JampanWaitForAlternatePrimaryAngleState:           ; was: sub_49D56
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                cmpi.w  #$100,(SharedScratchLong1).w
                bne.s   Boss_JampanWaitForAlternatePrimaryAngleReturn
                clr.w   (SharedScratchLong4).w
                addq.w  #2,4(a5)
Boss_JampanWaitForAlternatePrimaryAngleReturn:
                rts
; End of function Boss_JampanWaitForAlternatePrimaryAngleState
; Collapses the alternate pattern radius and disables the shields
Boss_JampanCollapseAlternatePatternState:               ; was: sub_49D70
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                subq.w  #4,(SharedScratchLong11).w
                bhi.s   Boss_JampanCollapseAlternatePatternReturn
                clr.w   (SharedScratchLong11).w
                bsr.w   Boss_JampanDisableShields
                andi.w  #$1F8,(SharedScratchLong2).w
                addq.w  #2,4(a5)
Boss_JampanCollapseAlternatePatternReturn:
                rts
; End of function Boss_JampanCollapseAlternatePatternState
; Restores the secondary angle to $100 before attack selection
Boss_JampanRestoreAttackSelectionAngleState:            ; was: sub_49D92
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                addq.w  #8,(SharedScratchLong2).w
                andi.w  #$1F8,(SharedScratchLong2).w
                cmpi.w  #$100,(SharedScratchLong2).w
                bne.s   Boss_JampanRestoreAttackSelectionAngleReturn
                move.w  #$12,4(a5)
Boss_JampanRestoreAttackSelectionAngleReturn:
                rts
; End of function Boss_JampanRestoreAttackSelectionAngleState
Boss_JampanNoOpState50:
                rts
; End of function Boss_JampanNoOpState50

; Shrinks the shield radius, then gates defeat setup on the primary offset
Boss_JampanBeginDefeatState:                            ; was: sub_49DB2
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                tst.w   (SharedScratchLong11).w
                beq.s   Boss_JampanUpdateDefeatPrimaryOffset
                subq.w  #1,(SharedScratchLong11).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanUpdateDefeatPrimaryOffset:
                tst.w   (SharedScratchLong9+2).w
                beq.s   Boss_JampanUpdateDefeatSecondaryOffset
                tst.w   (SharedScratchLong9+2).w
                bmi.s   Boss_JampanIncreaseDefeatPrimaryOffset
                subq.w  #1,(SharedScratchLong9+2).w
                bra.s   Boss_JampanUpdateDefeatSecondaryOffset
; ---------------------------------------------------------------------------
Boss_JampanIncreaseDefeatPrimaryOffset:
                addq.w  #1,(SharedScratchLong9+2).w
Boss_JampanUpdateDefeatSecondaryOffset:
                                        ; Boss_JampanBeginDefeatState+24   j
                tst.w   (SharedScratchLong9+2).w
                beq.s   Boss_JampanCompleteDefeatAfterPrimaryOffsetZero
                tst.w   (SharedScratchLong10).w
                bmi.s   Boss_JampanIncreaseDefeatSecondaryOffset
                subq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanIncreaseDefeatSecondaryOffset:
                addq.w  #1,(SharedScratchLong10).w
                rts
; ---------------------------------------------------------------------------
Boss_JampanCompleteDefeatAfterPrimaryOffsetZero:
                tst.w   (SharedScratchLong9+2).w
                bne.s   Boss_JampanBeginDefeatReturn
                bclr    #2,$4C(a5)
                clr.l   $1C(a5)
                clr.l   $54(a5)
                clr.l   (SharedScratchLong4).w
                clr.l   (SharedScratchLong5).w
                ori.w   #$8000,(SeventhEntityFlags).w
                clr.b   $21(a5)
                move.b  #1,(SoundFadeOutDelay).w
                addq.w  #2,4(a5)
Boss_JampanBeginDefeatReturn:
                rts
; End of function Boss_JampanBeginDefeatState
; Falls with explosion debris until reaching screen Y $110
Boss_JampanDefeatFallState:                             ; was: sub_49E26
                addi.l  #$200,$1C(a5)
                bsr.w   Boss_JampanUpdateShieldFormationGeometry
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                cmpi.w  #$110,$14(a5)
                bcs.s   Boss_JampanDefeatFallReturn
                bsr.w   Boss_JampanDisableShields
                clr.l   $1C(a5)
                move.w  #$110,$14(a5)
                andi.w  #$1FE,(SharedScratchLong2).w
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_JampanDefeatFallReturn:
                rts
; End of function Boss_JampanDefeatFallState
; Holds the explosion sequence, then creates the type-$23C shield object
Boss_JampanDefeatExplosionHoldState:                    ; was: sub_49E64
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanDefeatExplosionHoldReturn
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                movea.w #(TwentyNinthEntityType-M68K_RAM),a0
                move.w  #$23C,(a0)
                move.w  #$D00,2(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
Boss_JampanDefeatExplosionHoldReturn:
                rts
; End of function Boss_JampanDefeatExplosionHoldState
; Waits for the shield object's Y to fall below $60
Boss_JampanWaitForDefeatShieldYBelow60State:            ; was: sub_49E9A
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                cmpi.w  #$60,(TwentyNinthEntityYPos).w  ; '`'
                bcc.s   Boss_JampanWaitForDefeatShieldYBelow60Return
                clr.l   (TwentyNinthEntityYVel).w
                addq.w  #2,4(a5)
Boss_JampanWaitForDefeatShieldYBelow60Return:
                rts
; End of function Boss_JampanWaitForDefeatShieldYBelow60State
; Advances the defeat palette-fade index to $0F
Boss_JampanFadeDefeatPaletteOutState:                   ; was: sub_49EB2
                bsr.s   Boss_JampanApplyDefeatPaletteFade
                addq.w  #1,$5C(a5)
                cmpi.w  #$F,$5C(a5)
                bne.s   Boss_JampanFadeDefeatPaletteOutReturn
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                clr.b   (VDPReg11Shadow+1).w
                addq.w  #2,4(a5)
Boss_JampanFadeDefeatPaletteOutReturn:
                rts
; End of function Boss_JampanFadeDefeatPaletteOutState
; Applies the current defeat palette-fade index
Boss_JampanApplyDefeatPaletteFade:                      ; was: sub_49ED2
                                        ; sub_49EEC   p
                move.w  $5C(a5),d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_JampanApplyDefeatPaletteFade
; Clears encounter objects and initializes the player-spawn transition
Boss_JampanResetAfterDefeatFadeState:                   ; was: sub_49EEC
                bsr.s   Boss_JampanApplyDefeatPaletteFade
                move.w  #$218,d0
                move.w  #$23C,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                jsr     (TransitionEffect_SpawnAtOwner).l
                move.b  #4,(PlaneAScrollModeFlags).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanResetAfterDefeatFadeState
; Reduces the defeat palette-fade index back to zero
Boss_JampanFadeDefeatPaletteInState:                    ; was: sub_49F0E
                bsr.s   Boss_JampanApplyDefeatPaletteFade
                subq.w  #1,$5C(a5)
                cmpi.w  #0,$5C(a5)
                bne.s   Boss_JampanFadeDefeatPaletteInReturn
                addq.w  #2,4(a5)
Boss_JampanFadeDefeatPaletteInReturn:
                rts
; End of function Boss_JampanFadeDefeatPaletteInState
; Adopts the type-$23C shield position and prepares the post-defeat controller
Boss_JampanPreparePostDefeatControllerState:            ; was: sub_49F22
                move.w  (TwentyNinthEntityXPos).w,$10(a5)
                move.w  (TwentyNinthEntityYPos).w,$14(a5)
                bset    #4,(TwentyNinthEntityFlags).w
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanPreparePostDefeatControllerState
; Restores encounter objects and starts the post-defeat sequence timer
Boss_JampanReinitializePostDefeatObjectsState:          ; was: sub_49F40
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanReinitializePostDefeatObjectsReturn
                lea     (Boss_JampanPaletteCommand).l,a0
                jsr     (Gfx_LoadPalettePreservingSharedColor).l
                bsr.w   Boss_JampanInitializeLinkedObjectGraph
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                move.w  #$FFF8,(SharedScratchLong9).w
                move.w  #$100,(SharedScratchLong1).w
                move.w  #$100,(SharedScratchLong2).w
                move.w  #1,(TertiaryEntityWork52).w
                move.w  #1,(FifthEntityWork52).w
                move.w  #1,(SixthEntityWork52).w
                addq.w  #2,4(a5)
                bsr.w   Boss_JampanInitializePostDefeatSequenceTimer
Boss_JampanReinitializePostDefeatObjectsReturn:
                rts
; End of function Boss_JampanReinitializePostDefeatObjectsState
; Initializes one directed post-defeat movement interval
Boss_JampanInitializePostDefeatMovementState:           ; was: sub_49F88
                bsr.w   Boss_JampanUpdatePostDefeatSequenceTimer
                move.w  #1,(SecondaryEntityWork52).w
                move.w  #1,(QuaternaryEntityWork52).w
                bsr.w   Boss_JampanAdjustOrbitParametersFromInput
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                addq.w  #2,4(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$40,d0                         ; '@'
                move.w  d0,$48(a5)
                jsr     (Math_CalculateAngleToPlayer).l
                lea     (Math_SineTable).l,a1
                move.w  (a1,d2.w),d0
                move.w  -$80(a1,d2.w),d1
                ext.l   d0
                ext.l   d1
                move.l  d0,d2
                move.l  d1,d3
                neg.l   d2
                neg.l   d3
                asr.l   #4,d2
                asr.l   #4,d3
                move.l  d2,$50(a5)
                move.l  d3,$54(a5)
                asl.l   #3,d0
                asl.l   #3,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                rts
; End of function Boss_JampanInitializePostDefeatMovementState
; Accelerates the post-defeat movement until its randomized timer expires
Boss_JampanUpdatePostDefeatMovementState:               ; was: sub_49FEE
                bsr.w   Boss_JampanUpdatePostDefeatSequenceTimer
                bsr.w   Boss_JampanAdjustOrbitParametersFromInput
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                move.l  $50(a5),d0
                add.l   d0,$18(a5)
                move.l  $54(a5),d0
                add.l   d0,$1C(a5)
                subq.w  #1,$48(a5)
                bne.s   Boss_JampanUpdatePostDefeatMovementReturn
                subq.w  #2,4(a5)
Boss_JampanUpdatePostDefeatMovementReturn:
                rts
; End of function Boss_JampanUpdatePostDefeatMovementState
Boss_JampanPostDefeatNoOpState68:
                rts
; End of function Boss_JampanPostDefeatNoOpState68

; Initializes the shared post-defeat timer and stage object count
Boss_JampanInitializePostDefeatSequenceTimer:           ; was: sub_4A018
                move.w  #$100,(SharedScratchLong11+2).w
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                rts
; End of function Boss_JampanInitializePostDefeatSequenceTimer
; Counts down the post-defeat timer and publishes its completion flag
Boss_JampanUpdatePostDefeatSequenceTimer:               ; was: sub_4A026
                                        ; sub_49FEE   p
                subq.w  #1,(SharedScratchLong11+2).w
                bne.s   Boss_JampanUpdatePostDefeatSequenceTimerReturn
                move.b  #1,(SceneSequenceFlags).w
Boss_JampanUpdatePostDefeatSequenceTimerReturn:
                rts
; End of function Boss_JampanUpdatePostDefeatSequenceTimer
; Dispatches the separate type-$240 post-defeat object
Boss_JampanPostDefeatObjectMain:                        ; was: sub_4A034
                move.w  4(a5),d0
                lea     Boss_JampanPostDefeatObjectStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_JampanPostDefeatObjectMain
; ---------------------------------------------------------------------------
Boss_JampanPostDefeatObjectStateHandlers:   dc.w    Boss_JampanInitializePostDefeatObjectState-*
                dc.w    Boss_JampanUpdatePostDefeatObjectState-*

; Initializes the type-$240 post-defeat object and linked-part state
Boss_JampanInitializePostDefeatObjectState:             ; was: sub_4A044
                move.b  #$40,$20(a5)                    ; '@'
                move.w  #1,(SecondaryEntityWork52).w
                move.w  #1,(QuaternaryEntityWork52).w
                clr.w   (TertiaryEntityWork52).w
                clr.w   (FifthEntityWork52).w
                clr.w   (SeventhEntityWork52).w
                clr.w   (SixthEntityWork52).w
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                move.l  #$FFFE0000,$1C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_JampanInitializePostDefeatObjectState
; Updates the type-$240 post-defeat object's orbiting-part geometry
Boss_JampanUpdatePostDefeatObjectState:                 ; was: sub_4A078
                bsr.w   Boss_JampanUpdateOrbitingPartGeometry
                rts
; End of function Boss_JampanUpdatePostDefeatObjectState
