Orphaned_PlayerUpdateWeaponCharge:
                btst    #5,$6A(a5)                      ; was: sub_164DC
                beq.s   Orphaned_PlayerUpdateWeaponChargeReturn
                btst    #0,$69(a5)
                beq.s   Orphaned_PlayerUpdateWeaponChargeReturn
                move.w  (PlayerHealth).w,d0
                sub.w   (PlayerMaxHealth).w,d0
                move.w  d0,(PhoenixAttackStatus).w
                moveq   #1,d0
Orphaned_PlayerUpdateWeaponChargeReturn:                ; was: locret_164FA
                                        ; Orphaned_PlayerUpdateWeaponCharge+E   j
                rts
; End of function Orphaned_PlayerUpdateWeaponCharge
; Initializes player dash state with animation and counter setup
Player_InitDashState:                                   ; was: sub_164FC
                                        ; Player_CeilingDecelerateState+32   j
                move.w  #2,$48(a5)
; Initializes dash animation with timer and direction flip
Player_InitDashAnimation:                               ; was: loc_16502
                                        ; Player_HandleSlideState+38   j
                move.w  #$22,4(a5)                      ; '"'
                bset    #4,$E(a5)
                move.w  #$A,$4A(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$14,$5C(a5)
                move.b  #$7F,(PlayerInputMask).w
                bra.w   Player_AutoFlipDirection
; End of function Player_InitDashState
Player_CeilingDashState_Return:                         ; was: nullsub_43
                rts
; End of function Player_CeilingDashState_Return

; Handles dash movement while the player remains attached to upper terrain
Player_CeilingDashState:                                ; was: sub_1652C
                bset    #1,(PlayerActionStateFlags).w
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bsr.w   Player_CheckCeilingWeaponSelectInput
                bne.s   Player_CeilingDashState_Return
                btst    #5,$6A(a5)
                beq.s   Player_CeilingDashState_UpdateMovement
                btst    #0,$69(a5)
                beq.w   Player_InitCeilingDetachFall
                bra.w   Player_InitiateDashAttack
; ---------------------------------------------------------------------------
Player_CeilingDashState_UpdateMovement:                 ; was: loc_16564
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartCeilingCounterForce
                bsr.w   Player_DecelerateHorizontalVelocityFast
                subq.w  #1,$48(a5)
                bpl.s   Player_CeilingDashState_Render
                move.w  #$FFFF,$48(a5)
                btst    #4,$69(a5)
                beq.s   Player_CeilingDashState_CheckDashInput
                tst.w   (ShootingMode).w
                bne.s   Player_CeilingDashState_Render
Player_CeilingDashState_CheckDashInput:                 ; was: loc_1658C
                btst    #0,$69(a5)
                beq.w   Player_InitCeilingIdleState
; Selects the armed or unarmed ceiling-dash rendering path
Player_CeilingDashState_Render:                         ; was: loc_16596
                                        ; Player_CeilingDashState+5E   j
                btst    #4,$69(a5)
                beq.w   Player_RenderMotionPose
                bra.w   Player_RenderCeilingMotionWithWeapon
; End of function Player_CeilingDashState
; Enters state $1E, which brakes the player to a stop while held to the ceiling
Player_InitCeilingDecelerateState:                      ; was: sub_165A4
                                        ; Player_InitCeilingMovementState+3A   j
                move.b  #$7F,(PlayerInputMask).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #$1E,4(a5)
                clr.w   $48(a5)
                move.w  #$10,$5C(a5)
                bra.w   Player_AutoFlipDirection
; End of function Player_InitCeilingDecelerateState
; Brakes to a stop on the ceiling, then resumes movement or goes idle
Player_CeilingDecelerateState:                          ; was: sub_165C2
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bsr.w   Player_CheckCeilingWeaponSelectInput
                bne.s   Player_CeilingState_Return
                bsr.w   Player_CheckDashInput
                bne.s   Player_CeilingState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartCeilingCounterForce
                btst    #0,$69(a5)
                bne.w   Player_InitDashState
                bsr.w   Player_DecelerateHorizontalVelocityFast
                move.l  $18(a5),d0
                bne.s   Player_CeilingDecelerateState_Render
                btst    #2,$69(a5)
                bne.w   Player_InitCeilingMovementFromDirection
                btst    #3,$69(a5)
                bne.w   Player_InitCeilingMovementFromDirection
                bra.w   Player_InitCeilingIdleState
; ---------------------------------------------------------------------------
; Selects the rendering path while still sliding along the ceiling
Player_CeilingDecelerateState_Render:                   ; was: loc_1661A
                btst    #4,$69(a5)
                bne.w   Player_RenderCeilingMotionFrame
                movea.l #Player_CommonPrimarySpriteMapping,a1
                movea.l #Player_CommonMovementSecondarySpriteMapping,a2
                moveq   #0,d5
                moveq   #6,d6
                bra.w   Player_BuildSpritePieces
; ---------------------------------------------------------------------------
Player_CeilingState_Return:                             ; was: locret_16638
                                        ; Player_CeilingDecelerateState+20   j
                rts
; End of function Player_CeilingDecelerateState
; Initializes the landing state for contact with upper terrain
Player_InitCeilingLandingState:                         ; was: sub_1663A
                                        ; Player_UpwardTerrainLaunchState+3A   j
                move.b  #$7F,(PlayerInputMask).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #$26,4(a5)                      ; '&'
                bset    #4,$E(a5)
                move.w  #2,$48(a5)
                move.w  #6,$4A(a5)
                move.w  #$14,$5C(a5)
                move.b  #$B1,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Player_AutoFlipDirection
; End of function Player_InitCeilingLandingState
; Handles the landing timer while attached to upper terrain
Player_CeilingLandingState:                             ; was: sub_16670
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bsr.w   Player_CheckCeilingWeaponSelectInput
                bne.s   Player_CeilingState_Return
                bsr.w   Player_CheckDashInput
                bne.s   Player_CeilingState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartCeilingCounterForce
                move.l  #$4000,d1
                bsr.w   Player_DecelerateHorizontalVelocity
                subq.w  #1,$4A(a5)
                subq.w  #1,$48(a5)
                bpl.s   Player_CeilingLandingState_Render
                btst    #0,$69(a5)
                beq.s   Player_CeilingLandingState_CheckMovementInput
                bsr.w   Player_InitDashState
                move.w  #$FFFF,$48(a5)
                bra.s   Player_CeilingLandingState_Render
; ---------------------------------------------------------------------------
Player_CeilingLandingState_CheckMovementInput:          ; was: loc_166C4
                btst    #2,$69(a5)
                bne.w   Player_InitCeilingMovementFromDirection
                btst    #3,$69(a5)
                bne.w   Player_InitCeilingMovementFromDirection
                bra.w   Player_InitCeilingDecelerateState
; ---------------------------------------------------------------------------
Player_CeilingLandingState_Render:                      ; was: loc_166DC
                                        ; Player_CeilingLandingState+52   j
                btst    #4,$69(a5)
                beq.w   Player_RenderMotionPose
                bra.w   Player_RenderCeilingMotionWithWeapon
; End of function Player_CeilingLandingState
; Opens ceiling weapon selection with A, or toggles shooting mode with up+A
Player_CheckCeilingWeaponSelectInput:                   ; was: sub_166EA
                                        ; Player_CeilingDashState+1C   p
                btst    #6,$6A(a5)
                beq.s   Player_CheckCeilingWeaponSelectInput_NotActivated
                btst    #0,$69(a5)
                bne.w   Player_ToggleShootingMode
                tst.w   (WeaponStateCooldown).w
                bmi.s   Player_CheckCeilingWeaponSelectInput_Start
Player_CheckCeilingWeaponSelectInput_NotActivated:      ; was: loc_16702
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
Player_CheckCeilingWeaponSelectInput_Start:             ; was: loc_16706
                move.w  (WeaponSlotOffset).w,(WeaponSavedSlotOffset).w
                move.w  #$12,(WeaponStateIndex).w
                move.b  #$7F,(PlayerInputMask).w
                move.w  #0,(WeaponMenuSpawnXOffset).w
                move.w  #0,(WeaponMenuSpawnYOffset).w
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$20,4(a5)                      ; ' '
                move.w  #$10,$5C(a5)
                ; The normal entry already excluded up+A; preserve this test
                btst    #0,$69(a5)
                beq.s   Player_CheckCeilingWeaponSelectInput_ReturnActivated
                move.w  #$14,$5C(a5)
Player_CheckCeilingWeaponSelectInput_ReturnActivated:   ; was: loc_16746
                moveq   #1,d0
                rts
; End of function Player_CheckCeilingWeaponSelectInput
; Holds the ceiling player state while the weapon selector is active
Player_CeilingWeaponSelectState:                        ; was: sub_1674A
                cmpi.w  #$12,(WeaponStateIndex).w
                bmi.w   Player_InitCeilingIdleState
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bra.w   Player_RenderIdleFrame
; End of function Player_CeilingWeaponSelectState
; Toggles moving/fixed shooting mode and plays its sound
Player_ToggleShootingMode:                              ; was: sub_1676E
                eori.w  #2,(ShootingMode).w
                move.b  #$A3,d0
                jsr     (Sound_QueueSFXRequest).l
                moveq   #0,d0
                rts
; End of function Player_ToggleShootingMode
; Enters state $1A, ceiling movement, from a held direction
Player_InitCeilingMovementState:                        ; was: sub_16782
                                        ; Player_CeilingIdleState+58   j
                btst    #4,$69(a5)
                beq.s   Player_InitCeilingMovementAnimation
                tst.w   (ShootingMode).w
                beq.s   Player_InitCeilingMovementCheckFacing
                rts
; ---------------------------------------------------------------------------
Player_InitCeilingMovementFromDirection:                ; was: loc_16792
                                        ; Player_CeilingDecelerateState+50   j
                btst    #4,$69(a5)
                beq.s   Player_InitCeilingMovementAnimation
                tst.w   (ShootingMode).w
                bne.w   Player_InitCeilingIdleState
Player_InitCeilingMovementCheckFacing:                  ; was: loc_167A2
                btst    #3,$69(a5)
                beq.s   Player_InitCeilingMovementCheckLeft
                btst    #3,$E(a5)
                bne.w   Player_InitCeilingAirControlState
                bra.s   Player_InitCeilingMovementAnimation
; ---------------------------------------------------------------------------
Player_InitCeilingMovementCheckLeft:                    ; was: loc_167B6
                btst    #2,$69(a5)
                beq.w   Player_InitCeilingDecelerateState
                btst    #3,$E(a5)
                beq.w   Player_InitCeilingAirControlState
; Installs the ceiling-movement animation and enters state $1A
Player_InitCeilingMovementAnimation:                    ; was: loc_167CA
                                        ; Player_InitCeilingMovementState+16   j
                move.b  #$7F,(PlayerInputMask).w
                move.w  #$1A,4(a5)
                move.w  #4,$48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$5C(a5)
                bra.w   Player_AutoFlipDirection
; End of function Player_InitCeilingMovementState
Player_CeilingMovementState_Return:                     ; was: nullsub_44
                                        ; Player_CeilingMovementState+20   j
                rts
; End of function Player_CeilingMovementState_Return

; Handles directional movement while the player is attached to upper terrain
Player_CeilingMovementState:                            ; was: sub_167EE
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bsr.w   Player_CheckCeilingWeaponSelectInput
                bne.s   Player_CeilingMovementState_Return
                bsr.w   Player_CheckDashInput
                bne.s   Player_CeilingMovementState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartCeilingCounterForce
                btst    #0,$69(a5)
                bne.w   Player_InitDashState
                btst    #4,$69(a5)
                beq.s   Player_CeilingMovementState_CheckHorizontalInput
                tst.w   (ShootingMode).w
                bne.w   Player_InitCeilingDecelerateState
Player_CeilingMovementState_CheckHorizontalInput:       ; was: loc_16834
                btst    #2,$69(a5)
                bne.s   Player_CeilingMovementState_Accelerate
                btst    #3,$69(a5)
                beq.w   Player_InitCeilingDecelerateState
Player_CeilingMovementState_Accelerate:                 ; was: loc_16846
                bsr.w   Physics_AccelerateHorizontalByFacing
                btst    #4,$69(a5)
                beq.w   Player_RenderDirectionalMovement
                btst    #3,$69(a5)
                beq.s   Player_CeilingMovementState_CheckRightFacing
                btst    #3,$E(a5)
                beq.w   Player_InitCeilingAirControlState
                bra.w   Player_RenderCeilingDashPose
; ---------------------------------------------------------------------------
Player_CeilingMovementState_CheckRightFacing:           ; was: loc_1686A
                btst    #3,$E(a5)
                bne.w   Player_InitCeilingAirControlState
                bra.w   Player_RenderCeilingDashPose
; ---------------------------------------------------------------------------
Player_InitCeilingAirControlState:                      ; was: loc_16878
                                        ; Player_InitCeilingMovementState+44   j
                move.w  #$1C,4(a5)
                clr.w   $48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$5C(a5)
Player_CeilingAirControlState_Return:                   ; was: locret_1688E
                                        ; Player_CeilingAirControlState+20   j
                rts
; End of function Player_CeilingMovementState
; Handles armed movement while the player remains attached to upper terrain
Player_CeilingAirControlState:                          ; was: sub_16890
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                jsr     Physics_UpperTerrainCheckWrapper(pc)  ; (pc)
                nop
                btst    #1,6(a5)
                beq.w   Player_InitCeilingDetachFall
                bsr.w   Player_CheckCeilingWeaponSelectInput
                bne.s   Player_CeilingAirControlState_Return
                bsr.w   Player_CheckDashInput
                bne.s   Player_CeilingAirControlState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartCeilingCounterForce
                btst    #0,$69(a5)
                bne.w   Player_InitDashState
                btst    #4,$69(a5)
                beq.w   Player_InitCeilingMovementAnimation
                bsr.w   Player_RenderCeilingWeaponPose
                btst    #2,$69(a5)
                beq.s   Player_CeilingAirControlState_CheckRightFacing
                btst    #3,$E(a5)
                beq.w   Player_InitCeilingMovementAnimation
                bra.w   Physics_AccelerateHorizontalNegative
; ---------------------------------------------------------------------------
Player_CeilingAirControlState_CheckRightFacing:         ; was: loc_168EA
                btst    #3,$69(a5)
                beq.w   Player_InitCeilingDecelerateState
                btst    #3,$E(a5)
                bne.w   Player_InitCeilingMovementAnimation
                bra.w   Physics_AccelerateHorizontalPositive
; End of function Player_CeilingAirControlState
; Updates aim direction from D-pad
Player_UpdateAimDirection:                              ; was: sub_16902
                bset    #4,$E(a5)
                btst    #2,(ControllerHeldState).w
                beq.s   Player_UpdateAimDirection_CheckRight
                bclr    #3,$E(a5)
                rts
; ---------------------------------------------------------------------------
Player_UpdateAimDirection_CheckRight:                   ; was: loc_16918
                btst    #3,(ControllerHeldState).w
                beq.s   Player_UpdateAimDirection_Return
                bset    #3,$E(a5)
Player_UpdateAimDirection_Return:                       ; was: locret_16926
                rts
; End of function Player_UpdateAimDirection
; Attributes: thunk
; State-table thunk returning the player to upper-terrain idle
Player_ReturnToCeilingIdleState:                        ; was: sub_16928
                bra.w   Player_InitCeilingIdleState
; End of function Player_ReturnToCeilingIdleState
; Handles jump apex for fall transition
Player_JumpApexState:                                   ; was: sub_1692C
                addi.l  #$8800,$1C(a5)
                bpl.w   Player_InitFallState
                bclr    #4,$E(a5)
                bra.w   Player_RenderMotionPose_UseAnimatedOffsets
; End of function Player_JumpApexState
; Player dash effect during teleport
Player_TeleportDash:                                    ; was: sub_16942
                clr.w   (PlayerDefeatPhase).w
                move.b  #$70,(PlayerInputMask).w        ; 'p'
                bset    #0,(PlayerRestrictionFlags).w
                move.w  #$CD00,2(a5)
                addq.w  #2,4(a5)
                clr.w   $48(a5)
                jsr     (Sys_ClearObjectBlocks17).l
                move.w  #$78,$10(a5)                    ; 'x'
                move.w  #$100,$14(a5)
                move.l  #$41000,$18(a5)
                move.l  #$18000,$1C(a5)
                bset    #3,$E(a5)
                bclr    #4,$E(a5)
                movea.w #(PlayerSpecialObjectSlot-M68K_RAM),a0
                move.w  #$230,(a0)
                move.b  #$54,$21(a0)                    ; 'T'
                move.w  #$4000,2(a0)
                move.l  #Player_TeleportDashProjectileSpriteMapping,8(a0)
                move.w  $E(a5),d0
                andi.w  #$FFFF,d0
                move.w  d0,$E(a0)
                eori.w  #$1000,$E(a0)
                move.b  $20(a5),$20(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  #$E0,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #Player_PhoenixAndTeleportDashSpriteMapping,8(a5)
; Applies velocity during player teleport dash
Player_TeleportDash_ApplyVelocity:                      ; was: loc_169E0
                tst.w   $48(a5)
                bne.w   Player_TeleportDash_Finish
                subi.l  #$620,$1C(a5)
                subi.l  #$C00,$18(a5)
                bset    #6,$21(a5)
                bset    #4,$23(a5)
                bset    #4,(PlayerActionStateFlags).w
                bra.w   Effect_CreateDashTrail
; ---------------------------------------------------------------------------
Player_TeleportDash_Finish:                             ; was: loc_16A0E
                bclr    #6,$21(a5)
                bclr    #4,$23(a5)
                jsr     (Sys_ClearObjectBlocks17).l
                bclr    #0,(PlayerRestrictionFlags).w
                move.w  #$FFE0,$52(a5)
                move.l  #$68000,$18(a5)
                move.w  #$FFFF,$1C(a5)
                bra.w   Player_InitFallState_Finish
; End of function Player_TeleportDash
; Advances the common player animation state by four
Player_UpdateAnimStatePlus4:                            ; was: sub_16A3E
                moveq   #4,d1
                bra.w   Player_UpdateAnimationState
; End of function Player_UpdateAnimStatePlus4
; Updates animation state with -4 offset
Player_UpdateAnimStateMinus4:                           ; was: sub_16A44
                moveq   #$FFFFFFFC,d1
                bra.w   Player_UpdateAnimationState
; End of function Player_UpdateAnimStateMinus4
; Initializes the return half of the teleport-dash sequence
Player_InitTeleportDashReturnState:                     ; was: sub_16A4A
                addq.w  #2,4(a5)
                move.b  #$70,(PlayerInputMask).w        ; 'p'
                bset    #0,(PlayerRestrictionFlags).w
                move.w  #$CD00,2(a5)
                jsr     (Sys_ClearObjectBlocks17).l
                move.w  #$120,$10(a5)
                move.w  #$100,$14(a5)
                bset    #3,$E(a5)
                bclr    #4,$E(a5)
                move.l  #Player_PhoenixAndTeleportDashSpriteMapping,8(a5)
; Alternates sprite frames during the teleport-dash return state
Player_TeleportDashReturnState:                         ; was: loc_16A86
                bset    #4,$23(a5)
                move.l  #Player_TeleportDashTrailSpriteMapping,8(a5)
                btst    #0,(FrameCounter+1).w
                bne.w   Player_TeleportDashReturnState_Return
                move.l  #Player_PhoenixAndTeleportDashSpriteMapping,8(a5)
Player_TeleportDashReturnState_Return:                  ; was: locret_16AA6
                rts
; End of function Player_InitTeleportDashReturnState
; Starts the timed defeat exit after health or stage time reaches zero
Player_InitDefeatExitState:                             ; was: sub_16AA8
                                        ; Player_Update+3C   j
                move.w  #2,(PlayerDefeatPhase).w
                move.w  #$100,2(a5)
                clr.b   $21(a5)
                move.b  #$10,$23(a5)
                move.w  #$30,$48(a5)                    ; '0'
                move.b  #$1F,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Player_InitDefeatExitState
; Counts down the defeat exit and requests its gameplay fade when expired
Player_UpdateDefeatExitState:                           ; was: sub_16ACE
                bclr    #7,2(a5)
                tst.w   $48(a5)
                bmi.s   Player_UpdateDefeatExitState_Return
                subq.w  #1,$48(a5)
                bne.s   Player_UpdateDefeatExitState_SpawnSpark
                move.w  #1,(GameplayExitMode).w
                move.w  #$8002,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                move.b  #$80,(GameplayControlFlags).w
Player_UpdateDefeatExitState_SpawnSpark:                ; was: loc_16AFC
                jmp     Effect_SpawnPlayerDeathSpark
; ---------------------------------------------------------------------------
Player_UpdateDefeatExitState_Return:                    ; was: locret_16B02
                rts
; End of function Player_UpdateDefeatExitState
