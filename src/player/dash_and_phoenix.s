; Handles directional movement while the player is attached to lower terrain
Player_GroundedMovementState:                           ; was: sub_156B8
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                bsr.w   Player_CheckWeaponSelectInput
                bne.s   Player_GroundedMovementState_Return
                bsr.w   Player_CheckJumpOrDashInput
                bne.s   Player_GroundedMovementState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartGroundCounterForce
                btst    #1,$69(a5)
                bne.w   Player_InitGroundCrouchState
                btst    #4,$69(a5)
                beq.s   Player_GroundedMovementState_CheckHorizontalInput
                tst.w   (ShootingMode).w
                bne.w   Player_InitGroundDecelerateState
Player_GroundedMovementState_CheckHorizontalInput:      ; was: loc_156FC
                btst    #2,$69(a5)
                bne.s   Player_GroundedMovementState_Accelerate
                btst    #3,$69(a5)
                beq.w   Player_InitGroundDecelerateState
Player_GroundedMovementState_Accelerate:                ; was: loc_1570E
                bsr.w   Physics_AccelerateHorizontalByFacing
                btst    #4,$69(a5)
                beq.w   Player_RenderDirectionalMovement
                btst    #3,$69(a5)
                beq.s   Player_GroundedMovementState_CheckRightFacing
                btst    #3,$E(a5)
                beq.w   Player_InitGroundWeaponState
                bra.w   Player_RenderGroundDashPose
; ---------------------------------------------------------------------------
Player_GroundedMovementState_CheckRightFacing:          ; was: loc_15732
                btst    #3,$E(a5)
                bne.w   Player_InitGroundWeaponState
                bra.w   Player_RenderGroundDashPose
; ---------------------------------------------------------------------------
; Initializes state 0x04 for weapon movement on lower terrain
Player_InitGroundWeaponState:                           ; was: loc_15740
                                        ; Player_SelectGroundDirectionState+44   j
                move.w  #4,4(a5)
                clr.w   $48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #4,$5C(a5)
Player_GroundWeaponState_Return:                        ; was: locret_15756
                                        ; Player_GroundWeaponState+1E   j
                rts
; End of function Player_GroundedMovementState
; Handles armed movement while the player remains attached to lower terrain
Player_GroundWeaponState:                               ; was: sub_15758
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                bsr.w   Player_CheckWeaponSelectInput
                bne.s   Player_GroundWeaponState_Return
                bsr.w   Player_CheckJumpOrDashInput
                bne.s   Player_GroundWeaponState_Return
                btst    #1,$69(a5)
                bne.w   Player_InitGroundCrouchState
                btst    #4,$69(a5)
                beq.w   Player_InitGroundedMovementState
                bsr.w   Player_RenderGroundWeaponPose
                btst    #2,$69(a5)
                beq.s   Player_GroundWeaponState_CheckRightFacing
                btst    #3,$E(a5)
                beq.w   Player_InitGroundedMovementState
                bra.w   Physics_AccelerateHorizontalNegative
; ---------------------------------------------------------------------------
Player_GroundWeaponState_CheckRightFacing:              ; was: loc_157A6
                btst    #3,$69(a5)
                beq.w   Player_InitGroundDecelerateState
                btst    #3,$E(a5)
                bne.w   Player_InitGroundedMovementState
                bra.w   Physics_AccelerateHorizontalPositive
; End of function Player_GroundWeaponState
; Initializes Phoenix weapon attack
Player_InitPhoenixAttack:
                move.w  #$56,4(a5)                      ; 'V'  ; was: sub_157BE
                move.w  #8,$4E(a5)
                move.b  #$73,(PlayerInputMask).w        ; 's'
                jsr     (Sys_ClearObjectBlocks16).l
                move.b  #1,(PlayerAirDashUsedFlag).w
                move.b  #1,(PlayerAirShotUsedFlag).w
                move.w  #$C,$50(a5)
                clr.w   $12(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                btst    #2,$69(a5)
                bne.s   Player_InitPhoenixAttack_FaceLeft
                btst    #3,$69(a5)
                bne.s   Player_InitPhoenixAttack_FaceRight
                btst    #3,$E(a5)
                bne.s   Player_InitPhoenixAttack_FaceRight
Player_InitPhoenixAttack_FaceLeft:                      ; was: loc_1580C
                move.l  #$FFF88000,$48(a5)
                bclr    #3,$E(a5)
                bra.s   Player_InitPhoenixAttack_Finish
; ---------------------------------------------------------------------------
Player_InitPhoenixAttack_FaceRight:                     ; was: loc_1581C
                                        ; Player_InitPhoenixAttack+4C   j
                move.l  #$78000,$48(a5)
                bset    #3,$E(a5)
Player_InitPhoenixAttack_Finish:                        ; was: loc_1582A
                move.l  #Player_PhoenixDashAttackSpriteMapping,8(a5)
                bsr.w   Player_SpawnPhoenixTrails
                moveq   #1,d0
                rts
; End of function Player_InitPhoenixAttack
; Updates Phoenix attack state
Player_PhoenixAttackUpdate:                             ; was: sub_1583A
                btst    #5,$6A(a5)
                beq.s   Player_PhoenixAttackUpdate_UpdateTimer
                move.w  #7,$50(a5)
Player_PhoenixAttackUpdate_UpdateTimer:                 ; was: loc_15848
                subq.w  #1,$4E(a5)
                bpl.w   Player_PhoenixAttackUpdate_UpdateCollision
                jsr     (Sys_ClearObjectBlocks16).l
                clr.w   $4E(a5)
                cmpi.w  #7,$50(a5)
                beq.s   Player_PhoenixAttackUpdate_SelectState
                addq.w  #2,$4E(a5)
Player_PhoenixAttackUpdate_SelectState:                 ; was: loc_15866
                move.w  #$10,4(a5)
                btst    #4,$E(a5)
                beq.s   Player_PhoenixAttackUpdate_TryProjectile
                move.w  #$24,4(a5)                      ; '$'
Player_PhoenixAttackUpdate_TryProjectile:               ; was: loc_1587A
                tst.w   (PhoenixAttackStatus).w
                bne.s   Player_PhoenixAttackUpdate_PlayBlockedSound
                btst    #7,(PlayerRestrictionFlags).w
                bne.s   Player_PhoenixAttackUpdate_PlayBlockedSound
                move.l  #Player_PhoenixAndTeleportDashSpriteMapping,8(a5)
                bsr.w   Player_SpawnProjectile
                bra.s   Player_PhoenixAttackUpdate_UpdateCollision
; ---------------------------------------------------------------------------
Player_PhoenixAttackUpdate_PlayBlockedSound:            ; was: loc_15896
                                        ; Player_PhoenixAttackUpdate+4C   j
                move.b  #$A6,d0
                jsr     (Sound_QueueSFXRequest).l
Player_PhoenixAttackUpdate_UpdateCollision:             ; was: loc_158A0
                                        ; Player_PhoenixAttackUpdate+5A   j
                move.w  #1,(DashActiveWriteOnly).w
                bset    #6,$21(a5)
                bset    #4,$23(a5)
                bset    #4,(PlayerActionStateFlags).w
                clr.w   6(a5)
                bsr.w   Physics_FacingExtendedWallCheckWrapper
                bsr.w   Physics_FacingTerrainCheckWrapper
                rts
; End of function Player_PhoenixAttackUpdate
; Spawns two Phoenix trail objects
Player_SpawnPhoenixTrails:                              ; was: sub_158C6
                movea.w #(PlayerEffectObjectPool-M68K_RAM),a0
                moveq   #0,d7
                bsr.s   Player_InitPhoenixTrail
                lea     $60(a0),a0
                addq.w  #2,d7
; End of function Player_SpawnPhoenixTrails
; Initializes single Phoenix trail
Player_InitPhoenixTrail:                                ; was: sub_158D4
                move.w  #$10,(a0)
                clr.b   $21(a0)
                move.w  #$C800,2(a0)
                move.l  #Player_DashTrailInitialSpriteMapping,8(a0)
                move.w  $E(a5),d0
                andi.w  #$FFFF,d0
                move.w  d0,$E(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                bpl.s   Player_InitPhoenixTrail_SetPosition
                clr.b   $20(a0)
Player_InitPhoenixTrail_SetPosition:                    ; was: loc_15906
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                clr.w   $1A(a0)
                move.w  Player_PhoenixTrailOffsetsAndVelocities(pc,d7.w),d0
                add.w   d0,$10(a0)
                move.w  Player_PhoenixTrailOffsetsAndVelocities+4(pc,d7.w),$18(a0)
                rts
; End of function Player_InitPhoenixTrail
; ---------------------------------------------------------------------------
Player_PhoenixTrailOffsetsAndVelocities:    dc.w    $20, $FFE0, $FFF8, 8  ; was: word_15926
                                        ; Player_InitPhoenixTrail+4A   r

; Initializes player dash attack with direction and projectile
Player_InitiateDashAttack:                              ; was: sub_1592E
                                        ; Player_CeilingDashState+34   j
                move.w  #$24,4(a5)                      ; '$'
                bra.s   Player_InitiateDashAttack_Initialize
; ---------------------------------------------------------------------------
Player_InitiateDashAttack_UseGroundState:               ; was: loc_15936
                                        ; Player_CheckJumpOrDashInput+1A   j
                move.w  #$10,4(a5)
Player_InitiateDashAttack_Initialize:                   ; was: loc_1593C
                move.b  #$73,(PlayerInputMask).w        ; 's'
                jsr     (Sys_ClearObjectBlocks16).l
                move.b  #1,(PlayerAirDashUsedFlag).w
                move.b  #1,(PlayerAirShotUsedFlag).w
                clr.w   $4E(a5)
                move.w  #$C,$50(a5)
                clr.w   $12(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                btst    #2,$69(a5)
                bne.s   Player_InitiateDashAttack_FaceLeft
                btst    #3,$69(a5)
                bne.s   Player_InitiateDashAttack_FaceRight
                btst    #3,$E(a5)
                bne.s   Player_InitiateDashAttack_FaceRight
Player_InitiateDashAttack_FaceLeft:                     ; was: loc_15982
                move.l  #$FFF88000,$48(a5)
                bclr    #3,$E(a5)
                bra.s   Player_InitiateDashAttack_TryProjectile
; ---------------------------------------------------------------------------
Player_InitiateDashAttack_FaceRight:                    ; was: loc_15992
                                        ; Player_InitiateDashAttack+52   j
                move.l  #$78000,$48(a5)
                bset    #3,$E(a5)
Player_InitiateDashAttack_TryProjectile:                ; was: loc_159A0
                tst.w   (PhoenixAttackStatus).w
                bne.s   Player_InitiateDashAttack_PlayBlockedSound
                btst    #7,(PlayerRestrictionFlags).w
                bne.s   Player_InitiateDashAttack_PlayBlockedSound
                bsr.w   Player_SpawnProjectile
                move.l  #Player_PhoenixAndTeleportDashSpriteMapping,8(a5)
                move.w  #$78,(PhoenixAttackStatus).w    ; 'x'
                moveq   #1,d0
                rts
; ---------------------------------------------------------------------------
; The blocked branch: no projectile, SFX $A6 and the plain dash mapping
Player_InitiateDashAttack_PlayBlockedSound:             ; was: loc_159C4
                                        ; Player_InitiateDashAttack+7E   j
                move.b  #$A6,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #Player_PhoenixDashAttackSpriteMapping,8(a5)
                move.w  #$78,(PhoenixAttackStatus).w    ; 'x'
                moveq   #1,d0
                rts
; End of function Player_InitiateDashAttack
; Updates the active dash attack, terrain contact, and exit transitions
Player_DashAttackState:                                 ; was: sub_159E0
                                        ; ROM:00015086   o
                tst.b   (PlayerDashStopFlag).w
                bne.s   Player_DashAttackState_Finish
                subq.w  #1,$50(a5)
                bmi.s   Player_DashAttackState_Finish
                bra.w   Player_DashAttackState_UpdateMovement
; ---------------------------------------------------------------------------
Player_DashAttackState_Finish:                          ; was: loc_159F0
                                        ; Player_DashAttackState+A   j
                bsr.w   Physics_FacingTerrainCheckWrapper
Player_DashAttackState_Cleanup:                         ; was: loc_159F4
                clr.w   (PlayerSpecialObjectSlot).w
                bclr    #0,(CounterForceTriggerFlag).w
                bclr    #6,$21(a5)
                bclr    #4,$23(a5)
                moveq   #0,d0
                btst    #4,$E(a5)
                beq.s   Player_DashAttackState_CheckTerrainContact
                moveq   #1,d0
Player_DashAttackState_CheckTerrainContact:             ; was: loc_15A16
                btst    d0,6(a5)
                bne.s   Player_DashAttackState_HandleTerrainContact
                move.w  #$FFE0,$52(a5)
                move.l  $48(a5),$18(a5)
                tst.w   $4E(a5)
                beq.s   Player_DashAttackState_ExitToFall
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
Player_DashAttackState_ExitToFall:                      ; was: loc_15A38
                btst    #4,$E(a5)
                beq.w   Player_InitFallState_Finish
                bra.w   Player_InitCeilingDetachFall_Finish
; ---------------------------------------------------------------------------
Player_DashAttackState_HandleTerrainContact:            ; was: loc_15A46
                clr.w   (PlayerAirMoveUsedFlags).w
                tst.w   $4E(a5)
                bne.s   Player_DashAttackState_ResumeAttachedState
                btst    #4,$E(a5)
                beq.w   Player_InitSlideState
                bra.w   Player_InitSlideState
; ---------------------------------------------------------------------------
Player_DashAttackState_ResumeAttachedState:             ; was: loc_15A5E
                btst    #4,$E(a5)
                beq.w   Player_InitGroundCrouchStateCleanup
                bra.w   Player_InitDashAnimation
; ---------------------------------------------------------------------------
Player_DashAttackState_CleanupAfterMovement:            ; was: loc_15A6C
                                        ; Player_DashAttackState+AA   j
                bra.s   Player_DashAttackState_Cleanup
; ---------------------------------------------------------------------------
Player_DashAttackState_UpdateMovement:                  ; was: loc_15A6E
                move.w  #1,(DashActiveWriteOnly).w
                bset    #6,$21(a5)
                bset    #4,$23(a5)
                bsr.w   Player_ApplyHorizontalMovement
                bne.s   Player_DashAttackState_CleanupAfterMovement
                bsr.w   Player_ApplyHorizontalMovement
                bne.s   Player_DashAttackState_CleanupAfterMovement
                bsr.w   Player_ApplyHorizontalMovement
                bne.s   Player_DashAttackState_CleanupAfterMovement
                bset    #4,(PlayerActionStateFlags).w
                bra.w   Effect_CreateDashTrail
; End of function Player_DashAttackState
; Applies horizontal movement with boundary checking
Player_ApplyHorizontalMovement:                         ; was: sub_15A9C
                                        ; Player_DashAttackState+A6   p
                clr.w   6(a5)
                bsr.w   Physics_FacingExtendedWallCheckWrapper
                bsr.w   Physics_FacingTerrainCheckWrapper
                tst.w   $48(a5)
                bmi.s   Player_ApplyHorizontalMovement_CheckLeftCollision
                btst    #1,7(a5)
                beq.s   Player_ApplyHorizontalMovement_Apply
                rts
; ---------------------------------------------------------------------------
Player_ApplyHorizontalMovement_CheckLeftCollision:      ; was: loc_15AB8
                btst    #0,7(a5)
                bne.s   Player_ApplyHorizontalMovement_Return
Player_ApplyHorizontalMovement_Apply:                   ; was: loc_15AC0
                move.l  $48(a5),d0
                add.l   d0,$10(a5)
                btst    #1,(PlayerRestrictionFlags).w
                bne.s   Player_ApplyHorizontalMovement_ReturnNoCollision
                cmpi.w  #$1AF,$10(a5)
                bmi.s   Player_ApplyHorizontalMovement_ClampLeft
                move.w  #$1AF,$10(a5)
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
Player_ApplyHorizontalMovement_ClampLeft:               ; was: loc_15AE2
                cmpi.w  #$90,$10(a5)
                bpl.s   Player_ApplyHorizontalMovement_ReturnNoCollision
                move.w  #$90,$10(a5)
Player_ApplyHorizontalMovement_ReturnNoCollision:       ; was: loc_15AF0
                                        ; Player_ApplyHorizontalMovement+4C   j
                moveq   #0,d0
Player_ApplyHorizontalMovement_Return:                  ; was: locret_15AF2
                rts
; End of function Player_ApplyHorizontalMovement
; Initializes player slide knockback state
Player_InitSlideState:                                  ; was: sub_15AF4
                                        ; Player_DashAttackState+7A   j
                move.b  #$7F,(PlayerInputMask).w
                move.w  #$40,4(a5)                      ; '@'
                move.w  #4,$5C(a5)
                move.l  #$FFFE0000,$18(a5)
                tst.w   $48(a5)
                bmi.s   Player_InitSlideState_Finish
                neg.l   $18(a5)
Player_InitSlideState_Finish:                           ; was: loc_15B18
                move.w  #2,$48(a5)
                rts
; End of function Player_InitSlideState
; Handles player slide knockback state
Player_HandleSlideState:                                ; was: sub_15B20
                                        ; ROM:000150A4   o
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_FacingTerrainCheckWrapper
                moveq   #0,d0
                btst    #4,$E(a5)
                beq.s   Player_HandleSlideState_CheckTerrainContact
                moveq   #1,d0
Player_HandleSlideState_CheckTerrainContact:            ; was: loc_15B36
                btst    d0,6(a5)
                beq.w   Player_InitFallState
                move.l  #$4000,d1
                bsr.w   Player_DecelerateHorizontalVelocity
                tst.l   $18(a5)
                bne.s   Player_HandleSlideState_UpdateAnimation
                btst    #4,$E(a5)
                beq.w   Player_InitGroundCrouchStateCleanup
                bra.w   Player_InitDashAnimation
; ---------------------------------------------------------------------------
Player_HandleSlideState_UpdateAnimation:                ; was: loc_15B5C
                subq.w  #1,$48(a5)
                bra.w   Player_RenderMotionPose
; End of function Player_HandleSlideState
; Unreachable: a bare return with no reference of any kind
Orphaned_PlayerDashStateReturn:                         ; was: nullsub_39
                rts
; End of function Orphaned_PlayerDashStateReturn

; Initializes dash kick with velocity
Player_InitDashKick:
                move.w  #$44,4(a5)                      ; 'D'  ; was: sub_15B66
                move.w  #4,$5C(a5)
                bclr    #4,$E(a5)
                move.l  #$FFFCE000,$18(a5)
                tst.w   $48(a5)
                bmi.s   Player_InitDashKick_Return
                neg.l   $18(a5)
Player_InitDashKick_Return:                             ; was: locret_15B8A
                rts
; End of function Player_InitDashKick
; Handles dash kick with gravity
Player_DashKickState:                                   ; was: sub_15B8C
                jsr     Physics_ExtendedWallCheckWrapper(pc)  ; (pc)
                nop
                addi.l  #$8800,$1C(a5)
                bsr.w   Physics_DescendingTerrainCheckWrapper
                btst    #0,6(a5)
                beq.s   Player_DashKickState_Return
                bsr.w   Player_InitSlideState
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Player_DashKickState_Return:                            ; was: locret_15BB6
                rts
; End of function Player_DashKickState
; Handles the C button from a grounded state: jump, dash attack or drop-through
Player_CheckJumpOrDashInput:                            ; was: sub_15BB8
                                        ; Player_GroundCrouchState+20   p
                btst    #5,$6A(a5)
                beq.s   Player_CheckJumpOrDashInput_Return
                btst    #1,$69(a5)
                beq.w   Player_CheckJumpOrDashInput_InitJump
                move.b  $69(a5),d0
                andi.b  #$C,d0
                bne.w   Player_InitiateDashAttack_UseGroundState
                btst    #6,(PlayerRestrictionFlags).w
                bne.w   Player_InitiateDashAttack_UseGroundState
                btst    #2,6(a5)
                beq.w   Player_InitiateDashAttack_UseGroundState
                bsr.w   Player_InitFallingTransition
                moveq   #1,d0
                rts
; ---------------------------------------------------------------------------
Player_CheckJumpOrDashInput_InitJump:                   ; was: loc_15BF2
                move.w  #8,4(a5)
                move.l  #$FFFA8000,$1C(a5)
                move.w  #$C,$5C(a5)
                move.w  #5,$48(a5)
                clr.w   $4A(a5)
                clr.w   (PlayerAirMoveUsedFlags).w
                clr.w   $52(a5)
                move.b  #$7F,(PlayerInputMask).w
Player_CheckJumpOrDashInput_Return:                     ; was: locret_15C1E
                                        ; Player_CheckDashInput+6   j
                rts
; End of function Player_CheckJumpOrDashInput
; Checks controller input for dash attack activation
Player_CheckDashInput:                                  ; was: sub_15C20
                                        ; Player_CeilingDecelerateState+1C   p
                btst    #5,$6A(a5)
                beq.s   Player_CheckJumpOrDashInput_Return
                btst    #0,$69(a5)
                bne.w   Player_InitiateDashAttack
                bra.s   Player_DropFromCeiling
; End of function Player_CheckDashInput
; Initializes player falling state with parameters
Player_InitFallState:                                   ; was: sub_15C34
                                        ; Player_GroundCrouchState+16   j
                clr.w   (PlayerAirMoveUsedFlags).w
                clr.w   $52(a5)
Player_InitFallState_Finish:                            ; was: loc_15C3C
                                        ; Player_DashAttackState+5E   j
                bclr    #0,(CounterForceTriggerFlag).w
                move.w  #6,4(a5)
                bclr    #4,$E(a5)
                move.w  #$C,$5C(a5)
                move.w  #$FFFF,$48(a5)
                clr.w   $4A(a5)
                move.b  #$7F,(PlayerInputMask).w
                rts
; End of function Player_InitFallState
