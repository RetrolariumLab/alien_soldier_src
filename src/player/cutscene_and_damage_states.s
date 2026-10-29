; Handles the airborne recovery phase after the special attack
Player_SpecialMoveRecoveryState:                        ; was: sub_1609A
                bset    #0,(PlayerActionStateFlags).w
                bset    #6,(PlayerActionStateFlags).w
                jsr     Physics_ExtendedWallCheckWrapper(pc)  ; (pc)
                nop
                clr.b   6(a5)
                bsr.w   Physics_DescendingTerrainCheckWrapper
                btst    #0,6(a5)
                bne.w   Player_InitLandingState
                clr.b   6(a5)
                bsr.w   Physics_RisingTerrainCheckWrapper
                btst    #1,6(a5)
                bne.w   Player_InitCeilingLandingState
                bsr.w   Player_CheckRecoveryWeaponSelectInput
                bne.w   Player_SpecialMoveRecoveryState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartAirCounterForce
                btst    #5,$6A(a5)
                beq.s   Player_RenderSpecialMoveRecovery
                tst.b   (PlayerAirDashUsedFlag).w
                bne.s   Player_SpecialMoveRecoveryState_SetFastVerticalVelocity
                btst    #1,$69(a5)
                bne.w   Player_InitiateDashAttack_UseGroundState
Player_SpecialMoveRecoveryState_SetFastVerticalVelocity:  ; was: loc_160FA
                move.l  #$FFF80000,$1C(a5)
                bra.s   Player_EnterAirRecoveryFall
; End of function Player_SpecialMoveRecoveryState
; Unreachable entry that only sets the slower air-recovery rise velocity
Orphaned_PlayerSetAirRecoveryRiseVelocity:
                move.l  #$FFFD8000,$1C(a5)              ; was: sub_16104
Player_EnterAirRecoveryFall:                            ; was: loc_1610C
                move.w  #$FFE0,$52(a5)
                bra.w   Player_InitFallState_Finish
; End of function Orphaned_PlayerSetAirRecoveryRiseVelocity
; Renders the recovery pose with or without the weapon overlay
Player_RenderSpecialMoveRecovery:                       ; was: sub_16116
                movea.l #Player_SpecialAttackSecondarySpriteMappingA,a2
                btst    #0,(FrameCounter+1).w
                bne.s   Player_RenderSpecialMoveRecovery_SelectVariant
                movea.l #Player_SpecialAttackSecondarySpriteMappingB,a2
Player_RenderSpecialMoveRecovery_SelectVariant:         ; was: loc_1612A
                btst    #4,$69(a5)
                bne.w   Player_RenderSpecialMoveRecovery_WithWeapon
                bsr.w   Player_UpdateHorizontalFacing
                movea.l #Player_CommonPrimarySpriteMapping,a1
                moveq   #$FFFFFFFF,d5
                moveq   #$FFFFFFFE,d6
                bra.w   Player_BuildSpritePieces
; ---------------------------------------------------------------------------
Player_RenderSpecialMoveRecovery_WithWeapon:            ; was: loc_16146
                lea     (Player_AlternateLayoutMuzzleOffsets0).l,a4
                moveq   #0,d5
                moveq   #$FFFFFFFF,d6
                lea     Player_AlternateAnimationLayoutTable(pc),a0
                nop
                bra.w   Player_PrepareSpriteRendering_WithTables
; End of function Player_RenderSpecialMoveRecovery
Player_SpecialMoveRecoveryState_Return:                 ; was: nullsub_40
                rts
; End of function Player_SpecialMoveRecoveryState_Return

; Checks A-button input for weapon selection during special-attack recovery
Player_CheckRecoveryWeaponSelectInput:                  ; was: sub_1615C
                btst    #6,$6A(a5)
                beq.s   Player_CheckRecoveryWeaponSelectInput_NotActivated
                btst    #1,$69(a5)
                beq.s   Player_CheckRecoveryWeaponSelectInput_CheckAvailable
                bsr.w   Player_ToggleShootingModeWithInputMask
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
Player_CheckRecoveryWeaponSelectInput_CheckAvailable:   ; was: loc_16174
                tst.w   (WeaponStateCooldown).w
                bmi.s   Player_StartRecoveryWeaponSelect
Player_CheckRecoveryWeaponSelectInput_NotActivated:     ; was: loc_1617A
                moveq   #0,d0
                rts
; End of function Player_CheckRecoveryWeaponSelectInput
; ---------------------------------------------------------------------------
; Starts the recovery-specific weapon-select state
Player_StartRecoveryWeaponSelect:                       ; was: loc_1617E
                move.w  (WeaponSlotOffset).w,(WeaponSavedSlotOffset).w
                move.w  #$12,(WeaponStateIndex).w
                move.b  #$7F,(PlayerInputMask).w
                move.w  #0,(WeaponMenuSpawnXOffset).w
                move.w  #$FFEE,(WeaponMenuSpawnYOffset).w
                move.w  #$54,4(a5)                      ; 'T'
                moveq   #1,d0
                rts
; End of function Player_StartRecoveryWeaponSelect
; Holds recovery state 0x54 while the weapon selector is active
Player_RecoveryWeaponSelectState:                       ; was: sub_161A6
                bset    #0,(PlayerActionStateFlags).w
                bset    #6,(PlayerActionStateFlags).w
                jsr     Physics_ExtendedWallCheckWrapper(pc)  ; (pc)
                nop
                clr.b   6(a5)
                bsr.w   Physics_DescendingTerrainCheckWrapper
                btst    #0,6(a5)
                bne.w   Player_InitLandingState
                clr.b   6(a5)
                bsr.w   Physics_RisingTerrainCheckWrapper
                btst    #1,6(a5)
                bne.w   Player_InitCeilingLandingState
                cmpi.w  #$12,(WeaponStateIndex).w
                bpl.s   Player_RecoveryWeaponSelectState_Render
                move.w  #$46,4(a5)                      ; 'F'
                bsr.w   Player_AutoFlipDirection
Player_RecoveryWeaponSelectState_Render:                ; was: loc_161EE
                movea.l #Player_SpecialAttackSecondarySpriteMappingA,a2
                btst    #0,(FrameCounter+1).w
                bne.s   Player_RecoveryWeaponSelectState_SelectFrame
                movea.l #Player_SpecialAttackSecondarySpriteMappingB,a2
Player_RecoveryWeaponSelectState_SelectFrame:           ; was: loc_16202
                movea.l #Player_CommonPrimarySpriteMapping,a1
                moveq   #$FFFFFFFF,d5
                moveq   #$FFFFFFFE,d6
                bra.w   Player_BuildSpritePieces
; End of function Player_RecoveryWeaponSelectState
; Enters the forced-position state and clears player motion
Player_InitForcedPositionState:                         ; was: sub_16210
                move.b  #$7F,(PlayerInputMask).w
                move.w  #$8000,(PlayerDefeatPhase).w
                move.w  #$32,4(a5)                      ; '2'
                move.b  #$80,$21(a5)
                move.w  #4,$5C(a5)
                clr.w   $48(a5)
                clr.w   $4A(a5)
                clr.w   $52(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                bset    #1,(ForcedPositionFlags).w
                rts
; End of function Player_InitForcedPositionState
; Applies a published forced position until its request or timer expires
Player_HandleForcedPositionState:                       ; was: sub_1624A
                                        ; ROM:00015096   o
                bset    #3,(PlayerActionStateFlags).w
                bclr    #0,(ForcedPositionFlags).w
                bne.s   Player_HandleForcedPosition_ProcessActive
                bra.w   Player_HandleForcedPosition_Finish
; ---------------------------------------------------------------------------
Player_HandleForcedPosition_ProcessActive:              ; was: loc_1625C
                bclr    #2,(ForcedPositionFlags).w
                bne.s   Player_HandleForcedPosition_ApplyPosition
                move.b  $6A(a5),d0
                andi.b  #$2C,d0                         ; ','
                beq.s   Player_HandleForcedPosition_CheckTimer
                addq.w  #1,$4A(a5)
Player_HandleForcedPosition_CheckTimer:                 ; was: loc_16272
                move.w  (ForcedPositionTimer).w,d0
                cmp.w   $4A(a5),d0
                bpl.s   Player_HandleForcedPosition_ApplyPosition
                bclr    #1,(ForcedPositionFlags).w
                bra.w   Player_HandleForcedPosition_Finish
; ---------------------------------------------------------------------------
Player_HandleForcedPosition_ApplyPosition:              ; was: loc_16286
                                        ; Player_HandleForcedPositionState+30   j
                bset    #1,(ForcedPositionFlags).w
                move.w  (ForcedPositionX).w,$10(a5)
                move.w  (ForcedPositionY).w,$14(a5)
                moveq   #$FFFFFFFE,d1
                bra.w   Player_AdvanceAnimationFrame
; ---------------------------------------------------------------------------
Player_HandleForcedPosition_Finish:                     ; was: loc_1629E
                                        ; Player_HandleForcedPositionState+38   j
                move.b  #$30,(ContactDamageCooldown).w  ; '0'
                bra.w   *+4
; End of function Player_HandleForcedPositionState
; Initializes player knockback/damaged state with sound and velocity
Player_InitKnockbackState:                              ; was: sub_162A8
                                        ; Player_HandleForcedPositionState+5A   j
                move.b  #$7F,(PlayerInputMask).w
                bclr    #4,$E(a5)
                move.w  #$8000,(PlayerDefeatPhase).w
                jsr     (Sys_ClearObjectBlocks17).l
                move.w  #$2A,4(a5)                      ; '*'
                move.w  #$C,$48(a5)
                tst.w   $5E(a5)
                bpl.s   Player_InitKnockbackState_SetAlternateVerticalVelocity
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Player_InitKnockbackState_SetDefaultVelocity
                move.b  #$19,d0
                jsr     (Sound_QueueSFXRequest).l
Player_InitKnockbackState_SetDefaultVelocity:           ; was: loc_162E6
                move.l  #$FFFEA000,$1C(a5)
                tst.l   (PlayerKnockbackXVel).w
                beq.s   Player_InitKnockbackState_SetFacingVelocity
Player_InitKnockbackState_UseStoredHorizontalVelocity:  ; was: loc_162F4
                move.l  (PlayerKnockbackXVel).w,$18(a5)
                rts
; ---------------------------------------------------------------------------
Player_InitKnockbackState_SetFacingVelocity:            ; was: loc_162FC
                move.l  #$FFFF7000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_InitKnockbackState_Return
                neg.l   $18(a5)
Player_InitKnockbackState_Return:                       ; was: locret_16310
                rts
; ---------------------------------------------------------------------------
Player_InitKnockbackState_SetAlternateVerticalVelocity:  ; was: loc_16312
                move.b  #$19,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #$FFFE8000,$1C(a5)
                tst.w   (PlayerKnockbackXVel).w
                bne.w   Player_InitKnockbackState_UseStoredHorizontalVelocity
                bra.s   Player_SetKnockbackVelocity
; End of function Player_InitKnockbackState
; Unreachable: picks a signed knockback velocity from the caller's condition codes
Orphaned_PlayerSetHorizontalKnockbackFromFlags:
                bmi.s   Orphaned_PlayerSetHorizontalKnockbackNegative  ; was: sub_1632E
                move.l  #$38000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Orphaned_PlayerSetHorizontalKnockbackNegative:          ; was: loc_1633A
                move.l  #$FFFC8000,$18(a5)
                rts
; End of function Orphaned_PlayerSetHorizontalKnockbackFromFlags
; Sets player horizontal knockback velocity based on facing direction
Player_SetKnockbackVelocity:                            ; was: sub_16344
                move.l  #$FFFC8000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_SetKnockbackVelocity_Return
                neg.l   $18(a5)
Player_SetKnockbackVelocity_Return:                     ; was: locret_16358
                rts
; End of function Player_SetKnockbackVelocity
; Handles player knockback gravity and terrain contacts
Player_KnockbackState:                                  ; was: sub_1635A
                movea.l #Player_KnockbackPrimarySpriteMapping,a1
                movea.l #Player_CommonMovementSecondarySpriteMapping,a2
                moveq   #$FFFFFFFF,d5
                moveq   #$FFFFFFFF,d6
                bsr.w   Player_BuildSpritePieces
                subq.w  #1,$48(a5)
                bpl.s   Player_KnockbackState_ApplyPhysics
                bsr.w   Player_ClearKnockbackState
                bsr.w   Player_InitFallState
                move.b  #1,(PlayerAirDashUsedFlag).w
                move.b  #1,(PlayerAirShotUsedFlag).w
                bra.w   Player_HandleFallingState
; ---------------------------------------------------------------------------
Player_KnockbackState_ApplyPhysics:                     ; was: loc_1638C
                addi.l  #$6000,$1C(a5)
                bsr.w   Physics_ExtendedWallCheckWrapper
                tst.w   $1C(a5)
                bmi.s   Player_KnockbackState_CheckUpperTerrain
                bsr.w   Physics_DescendingTerrainCheckWrapper
                btst    #0,6(a5)
                beq.s   Player_KnockbackStateReturn
                bsr.w   Player_ClearKnockbackState
                bra.w   Player_InitLandingState
; ---------------------------------------------------------------------------
Player_KnockbackState_CheckUpperTerrain:                ; was: loc_163B2
                clr.b   6(a5)
                jmp     Physics_RisingTerrainCheckWrapper(pc)  ; (pc)
; End of function Player_KnockbackState
; Unreachable single nop ahead of the live shared knockback return
Orphaned_PlayerNoOpEntry:
                nop                                     ; was: sub_163BA
Player_KnockbackStateReturn:                            ; was: locret_163BC
                rts
; End of function Orphaned_PlayerNoOpEntry
; Clears player knockback flag and resets sprite state after hit
Player_ClearKnockbackState:                             ; was: sub_163BE
                                        ; Player_KnockbackState+50   p
                clr.w   (PlayerDefeatPhase).w
                move.w  #$CD00,2(a5)
                move.b  #$81,$21(a5)
                rts
; End of function Player_ClearKnockbackState
Orphaned_PlayerUnusedStateReturn:                       ; was: nullsub_41
                rts
; End of function Orphaned_PlayerUnusedStateReturn

; Initializes the idle state used while attached to upper terrain
Player_InitCeilingIdleState:                            ; was: sub_163D2
                                        ; Player_CeilingDashState+66   j
                move.b  #$7F,(PlayerInputMask).w
                bclr    #0,(CounterForceTriggerFlag).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #$18,4(a5)
                clr.l   $18(a5)
                clr.w   $48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$5C(a5)
                bra.w   Player_AutoFlipDirection
; End of function Player_InitCeilingIdleState
Player_CeilingIdleState_Return:                         ; was: nullsub_42
                                        ; Player_CeilingIdleState+24   j
                rts
; End of function Player_CeilingIdleState_Return

; Handles idle input while the player remains attached to upper terrain
Player_CeilingIdleState:                                ; was: sub_16402
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bsr.w   Effect_SpawnParticle
                bsr.w   Player_CheckCeilingWeaponSelectInput
                bne.s   Player_CeilingIdleState_Return
                bsr.w   Player_CheckDashInput
                bne.s   Player_CeilingIdleState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartCeilingCounterForce
                btst    #4,$69(a5)
                beq.s   Player_CeilingIdleState_CheckDashInput
                tst.w   (ShootingMode).w
                bne.s   Player_CeilingIdleState_Render
Player_CeilingIdleState_CheckDashInput:                 ; was: loc_16440
                btst    #0,$69(a5)
                bne.w   Player_InitDashState
                btst    #2,$69(a5)
                bne.w   Player_InitCeilingMovementState
                btst    #3,$69(a5)
                bne.w   Player_InitCeilingMovementState
Player_CeilingIdleState_Render:                         ; was: loc_1645E
                btst    #4,$69(a5)
                beq.w   Player_RenderIdleFrame
                bra.w   Player_RenderCeilingArmedIdle
; ---------------------------------------------------------------------------
; Starts ceiling Counter Force recoil, effect, and animation timing
Player_StartCeilingCounterForce:                        ; was: loc_1646C
                                        ; Player_CeilingDashState+3E   j
                bsr.w   Player_SpawnCounterForceEffect
                move.b  #$7F,(PlayerInputMask).w
                jsr     (Sys_ClearObjectBlocks16).l
                move.w  #$3E,4(a5)                      ; '>'
                move.w  #$FFFC,$48(a5)
                move.w  #$A,$4A(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$5C(a5)
                move.l  #$FFFE0000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_StartCeilingCounterForce_Return
                neg.l   $18(a5)
Player_StartCeilingCounterForce_Return:                 ; was: locret_164AE
                rts
; End of function Player_StartCeilingCounterForce
; Updates the ceiling Counter Force recoil and animation
Player_CeilingCounterForceState:                        ; was: sub_164B0
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_SetAirCounterForceState
                subq.w  #1,$4A(a5)
                bmi.w   Player_InitCeilingIdleState
                move.l  #$2000,d1
                bsr.w   Player_DecelerateHorizontalVelocity
                bra.w   Player_UpdateCounterForceAnimation
; End of function Player_CeilingCounterForceState
