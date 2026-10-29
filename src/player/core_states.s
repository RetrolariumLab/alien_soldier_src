Player_InitializeStats:                                 ; CODE XREF: Stage_InitializeXiTigerState+3A   j  ; was: sub_14F06
                                        ; Sys_InitStageState+3A   j
                lea     (PlayerObjectType).w,a5
                move.b  #$7F,(PlayerInputMask).w
                move.w  (PrimaryCameraXPosition).w,(PreviousCameraXPosition).w
                move.w  (PrimaryCameraYPosition).w,(PreviousCameraYPosition).w
                move.w  #8,(a5)
                move.w  #$4D00,2(a5)
                clr.w   4(a5)
                move.w  #$4DC0,$E(a5)
                move.w  #$B800,$DA(a5)
                move.b  #8,$20(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.b  #$81,$21(a5)
                move.b  #$10,$23(a5)
                move.l  #$EC24F60A,$28(a5)
                move.w  #$78,(PhoenixAttackStatus).w    ; 'x'
                clr.b   $6B(a5)
                clr.w   $9E(a5)
                move.w  #$40,$5E(a5)                    ; '@'
                move.l  #$74000,(PhysicsXVelocityLimit).w
                move.l  #$74000,(PhysicsYVelocityLimit).w
                jmp     Weapon_AdvanceCurrentState
; End of function Player_InitializeStats
; Clears the player's object identifier and display flags
Player_ClearObjectHeader:                               ; CODE XREF: Player_Update+A   j  ; was: sub_14F82
                clr.w   (a5)
                clr.w   2(a5)
                rts
; End of function Player_ClearObjectHeader
; Sets the player's display-enable bit when gameplay permits rendering
Player_SetDisplayFlag:                                  ; CODE XREF: Player_Update+12   j  ; was: sub_14F8A
                tst.w   (FrameFreezeTimer).w
                bmi.s   Player_Update_Return
                bset    #7,2(a5)
; Shared no-op player state and update return
Player_Update_Return:                                   ; CODE XREF: Player_SetDisplayFlag+4   j  ; was: locret_14F96
                                        ; DATA XREF: ROM:0001508E   o
                rts
; End of function Player_SetDisplayFlag
; Main player update routine
Player_Update:                                          ; CODE XREF: Sys_GameplayMainLoop:Sys_GameplayMainLoop_UpdatePlayer   p  ; was: sub_14F98
                                        ; sub_1EE3C   p
                movea.w #(PlayerObjectType-M68K_RAM),a5
                btst    #1,(PlayerModeFlags).w
                bne.w   Player_ClearObjectHeader
                tst.b   (FrameControlFlags).w
                bmi.s   Player_SetDisplayFlag
                jsr     (Player_UpdateScriptedInput).l
                bsr.w   Input_ReadPlayerInput
                clr.b   (PlayerActionStateFlags).w
                clr.w   6(a5)
                tst.w   (PlayerDefeatPhase).w
                beq.s   Player_Update_CheckGameplayReady
                bpl.w   Player_UpdateDefeatExitState
Player_Update_CheckGameplayReady:                       ; CODE XREF: Player_Update+2A   j  ; was: loc_14FC8
                tst.w   (StageTimeRemaining).w
                beq.w   Player_InitDefeatExitState
                tst.w   (PlayerHealth).w
                beq.w   Player_InitDefeatExitState
                btst    #0,(PlayerModeFlags).w
                bne.w   Player_UpdateSevenForceBattle
                btst    #2,(PlayerModeFlags).w
                bne.w   Player_UpdateSevenForceBattleVisible
                bsr.w   Gfx_LoadPlayerPaletteData
                bsr.w   Input_ProcessDirectionInput
                bclr    #6,$22(a5)
                beq.s   Player_Update_CheckCutsceneTrigger
                bsr.w   Player_InitKnockbackState
                bra.s   Player_UpdateCoreAttributes
; ---------------------------------------------------------------------------
Player_Update_CheckCutsceneTrigger:                     ; CODE XREF: Player_Update+62   j  ; was: loc_15002
                bclr    #1,$22(a5)
                beq.s   Player_Update_CheckFallBoundary
                bsr.w   Player_InitForcedPositionState
                bra.s   Player_UpdateCoreAttributes
; ---------------------------------------------------------------------------
Player_Update_CheckFallBoundary:                        ; CODE XREF: Player_Update+70   j  ; was: loc_15010
                cmpi.w  #$36,4(a5)                      ; '6'
                beq.s   Player_Update_RunState
                tst.w   $1C(a5)
                bmi.s   Player_Update_RunState
                btst    #0,(PlayerRestrictionFlags).w
                bne.s   Player_Update_RunState
                cmpi.w  #$171,$14(a5)
                bpl.w   Player_HandleDeathSequence
Player_Update_RunState:                                 ; CODE XREF: Player_Update+7E   j  ; was: loc_15030
                                        ; Player_Update+84   j
                bsr.w   Player_UpdateCounterForceInput
                bsr.w   Player_UpdateState
; Updates core player attributes including direction invulnerability hitbox and center position
Player_UpdateCoreAttributes:                            ; CODE XREF: Player_Update+68   j  ; was: loc_15038
                                        ; Player_Update+76   j
                bsr.w   Player_UpdateSpritePriorityBit
                move.b  $69(a5),$6B(a5)
                bsr.w   Player_UpdateInvulnerabilityTimer
                bsr.w   Player_SetHitbox
                clr.b   (PlayerDashStopFlag).w
                bra.w   Player_CalculateCenterPosition
; End of function Player_Update
; Updates player state machine
Player_UpdateState:                                     ; CODE XREF: Player_Update+9C   p  ; was: sub_15052
                move.w  4(a5),d0
                movea.w Player_StateHandlerOffsets(pc,d0.w),a0
                adda.l  #Player_HandleDeathSequence,a0
                jmp     (a0)
; End of function Player_UpdateState
; ---------------------------------------------------------------------------
Player_StateHandlerOffsets: dc.w    Player_GroundIdleState-Player_HandleDeathSequence  ; was: off_15062
                                        ; DATA XREF: Player_UpdateState+4   r
                dc.w    Player_GroundedMovementState-Player_HandleDeathSequence
                dc.w    Player_GroundWeaponState-Player_HandleDeathSequence
                dc.w    Player_HandleFallingState-Player_HandleDeathSequence
                dc.w    Player_HandleFallingState-Player_HandleDeathSequence
                dc.w    Player_GroundDecelerateState-Player_HandleDeathSequence
                dc.w    Player_GroundWeaponSelectState-Player_HandleDeathSequence
                dc.w    Player_GroundCrouchState-Player_HandleDeathSequence
                dc.w    Player_DashAttackState-Player_HandleDeathSequence
                dc.w    Player_UpwardTerrainLaunchState-Player_HandleDeathSequence
                dc.w    Player_HandleFallingState-Player_HandleDeathSequence
                dc.w    Player_HandleLandingState-Player_HandleDeathSequence
                dc.w    Player_CeilingIdleState-Player_HandleDeathSequence
                dc.w    Player_CeilingMovementState-Player_HandleDeathSequence
                dc.w    Player_CeilingAirControlState-Player_HandleDeathSequence
                dc.w    Player_CeilingDecelerateState-Player_HandleDeathSequence
                dc.w    Player_CeilingWeaponSelectState-Player_HandleDeathSequence
                dc.w    Player_CeilingDashState-Player_HandleDeathSequence
                dc.w    Player_DashAttackState-Player_HandleDeathSequence
                dc.w    Player_CeilingLandingState-Player_HandleDeathSequence
                dc.w    Player_HandleFallingState-Player_HandleDeathSequence
                dc.w    Player_KnockbackState-Player_HandleDeathSequence
                dc.w    Player_Update_Return-Player_HandleDeathSequence
                dc.w    Player_Update_Return-Player_HandleDeathSequence
                dc.w    Player_Update_Return-Player_HandleDeathSequence
                dc.w    Player_HandleForcedPositionState-Player_HandleDeathSequence
                dc.w    Player_HandleForcedPositionState-Player_HandleDeathSequence
                dc.w    Player_HandleDeathSequence_SetFlags-Player_HandleDeathSequence
                dc.w    Player_HandleRespawnGravity-Player_HandleDeathSequence
                dc.w    Player_GroundCounterForceState-Player_HandleDeathSequence
                dc.w    Player_AirCounterForceState-Player_HandleDeathSequence
                dc.w    Player_CeilingCounterForceState-Player_HandleDeathSequence
                dc.w    Player_HandleSlideState-Player_HandleDeathSequence
                dc.w    Player_HandleSlideState-Player_HandleDeathSequence
                dc.w    Player_DashKickState-Player_HandleDeathSequence
                dc.w    Player_SpecialMoveRecoveryState-Player_HandleDeathSequence
                dc.w    Player_UpdateAimDirection-Player_HandleDeathSequence
                dc.w    Player_ReturnToCeilingIdleState-Player_HandleDeathSequence
                dc.w    Player_JumpApexState-Player_HandleDeathSequence
                dc.w    Player_HandleSpecialAttack-Player_HandleDeathSequence
                dc.w    Player_TeleportDash-Player_HandleDeathSequence
                dc.w    Player_TeleportDash_ApplyVelocity-Player_HandleDeathSequence
                dc.w    Player_RecoveryWeaponSelectState-Player_HandleDeathSequence
                dc.w    Player_PhoenixAttackUpdate-Player_HandleDeathSequence
                dc.w    Player_UpdateAnimStatePlus4-Player_HandleDeathSequence
                dc.w    Player_UpdateAnimStateMinus4-Player_HandleDeathSequence
                dc.w    Player_InitTeleportDashReturnState-Player_HandleDeathSequence
                dc.w    Player_TeleportDashReturnState-Player_HandleDeathSequence

; Handles player death sequence with knockback and respawn countdown
Player_HandleDeathSequence:                             ; CODE XREF: Player_Update+94   j  ; was: sub_150C2
                                        ; DATA XREF: Player_UpdateState+8   o
                move.b  #$2B,d0                         ; '+'
                jsr     (Sound_QueueSFXRequest).l
                move.b  #$73,(PlayerInputMask).w        ; 's'
                move.w  #$8000,(PlayerDefeatPhase).w
                jsr     (Sys_ClearObjectBlocks17).l
                move.b  #1,(PlayerAirDashUsedFlag).w
                move.b  #1,(PlayerAirShotUsedFlag).w
                move.w  #$36,4(a5)                      ; '6'
                move.w  #$C100,2(a5)
                bclr    #4,$E(a5)
                move.b  $E(a5),$4C(a5)
                move.b  $20(a5),$4D(a5)
                bset    #3,$E(a5)
                bset    #7,$E(a5)
                move.b  #$81,$21(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$120,$14(a5)
                move.w  #3,$48(a5)
                move.w  #$A0,$4A(a5)
; Sets player death animation flags and counters
Player_HandleDeathSequence_SetFlags:                    ; DATA XREF: ROM:00015098   o  ; was: loc_15134
                bset    #5,(PlayerActionStateFlags).w
                bset    #0,(PlayerActionStateFlags).w
                move.b  #8,$20(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   Player_HandleDeathSequence_ClampEnergy
                subq.w  #1,(PlayerHealth).w
Player_HandleDeathSequence_ClampEnergy:                 ; CODE XREF: Player_HandleDeathSequence+8A   j  ; was: loc_15152
                subq.w  #1,(PlayerHealth).w
                bpl.s   Player_HandleDeathSequence_UpdateTimer
                clr.w   (PlayerHealth).w
Player_HandleDeathSequence_UpdateTimer:                 ; CODE XREF: Player_HandleDeathSequence+94   j  ; was: loc_1515C
                move.w  #$10,$5E(a5)
                subq.w  #1,$4A(a5)
                bmi.s   Player_HandleDeathSequence_BeginRespawn
                move.b  $6A(a5),d0
                andi.w  #$70,d0                         ; 'p'
                beq.s   Player_HandleDeathSequence_RenderParticles
                move.b  #$BD,d0
                jsr     (Sound_QueueSFXRequest).l
                subq.w  #1,$48(a5)
                bmi.s   Player_HandleDeathSequence_BeginRespawn
Player_HandleDeathSequence_RenderParticles:             ; CODE XREF: Player_HandleDeathSequence+AE   j  ; was: loc_15182
                bra.w   Player_RenderDeathParticles
; ---------------------------------------------------------------------------
Player_HandleDeathSequence_BeginRespawn:                ; CODE XREF: Player_HandleDeathSequence+A4   j  ; was: loc_15186
                                        ; Player_HandleDeathSequence+BE   j
                clr.w   (PlayerDefeatPhase).w
                move.b  #$7F,(PlayerInputMask).w
                move.w  #$38,4(a5)                      ; '8'
                move.w  #$CD00,2(a5)
                move.w  #$C,$5C(a5)
                move.l  #$FFF70000,$1C(a5)
                move.w  #$50,$5E(a5)                    ; 'P'
                clr.w   $48(a5)
                clr.w   $4A(a5)
                move.b  $4C(a5),$E(a5)
                move.b  $4D(a5),$20(a5)
                move.w  #$170,$14(a5)
                move.w  #$FF80,$52(a5)
; Handles respawn gravity accumulation until landing
Player_HandleRespawnGravity:                            ; DATA XREF: ROM:0001509A   o  ; was: loc_151D0
                bclr    #0,(CounterForceTriggerFlag).w
                addi.l  #$3000,$1C(a5)
                bmi.w   Player_HandleFallingState_UpdateTerrain
                clr.b   (PlayerAirDashUsedFlag).w
                clr.b   (PlayerAirShotUsedFlag).w
                bra.w   Player_HandleFallingState_UpdateTerrain
; End of function Player_HandleDeathSequence
; Enters state $00, the grounded standing state
Player_InitGroundIdleState:                             ; CODE XREF: Player_GroundCounterForceState+18   j  ; was: sub_151EE
                                        ; Player_UnreferencedCounterForceTerrainPath+10   j
                move.b  #$7F,(PlayerInputMask).w
                bclr    #0,(CounterForceTriggerFlag).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #0,4(a5)
                clr.l   $18(a5)
                clr.w   $48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #4,$5C(a5)
                bra.w   Player_AutoFlipDirection
; End of function Player_InitGroundIdleState
Player_GroundIdleState_Return:                          ; CODE XREF: Player_GroundIdleState+1C   j  ; was: nullsub_36
                                        ; Player_GroundIdleState+22   j
                rts
; End of function Player_GroundIdleState_Return

; State $00: standing on the ground, falling out the moment contact is lost
Player_GroundIdleState:                                 ; DATA XREF: ROM:Player_StateHandlerOffsets   o  ; was: sub_1521E
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                bsr.w   Effect_SpawnParticle
                bsr.w   Player_CheckWeaponSelectInput
                bne.s   Player_GroundIdleState_Return
                bsr.w   Player_CheckJumpOrDashInput
                bne.s   Player_GroundIdleState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartGroundCounterForce
                btst    #4,$69(a5)
                beq.s   Player_GroundIdleState_CheckMovementInput
                tst.w   (ShootingMode).w
                bne.s   Player_GroundIdleState_Render
Player_GroundIdleState_CheckMovementInput:              ; CODE XREF: Player_GroundIdleState+34   j  ; was: loc_1525A
                btst    #1,$69(a5)
                bne.w   Player_InitGroundCrouchState
                btst    #2,$69(a5)
                bne.w   Player_SelectGroundDirectionState
                btst    #3,$69(a5)
                bne.w   Player_SelectGroundDirectionState
Player_GroundIdleState_Render:                          ; CODE XREF: Player_GroundIdleState+3A   j  ; was: loc_15278
                btst    #4,$69(a5)
                beq.w   Player_RenderIdleFrame
                bra.w   Player_RenderGroundArmedIdle
; ---------------------------------------------------------------------------
; Starts grounded Counter Force recoil, effect, and animation timing
Player_StartGroundCounterForce:                         ; CODE XREF: Player_GroundIdleState+2A   j  ; was: loc_15286
                                        ; Player_GroundCrouchState+2C   j
                bsr.w   Player_SpawnCounterForceEffect
                move.b  #$7F,(PlayerInputMask).w
                jsr     (Sys_ClearObjectBlocks16).l
                move.w  #$3A,4(a5)                      ; ':'
                move.w  #$FFFC,$48(a5)
                move.w  #$A,$4A(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #4,$5C(a5)
                move.l  #$FFFE0000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_StartGroundCounterForce_Return
                neg.l   $18(a5)
Player_StartGroundCounterForce_Return:                  ; CODE XREF: Player_GroundIdleState+A4   j  ; was: locret_152C8
                rts
; End of function Player_GroundIdleState
; Updates the grounded Counter Force recoil and animation
Player_GroundCounterForceState:                         ; DATA XREF: ROM:0001509C   o  ; was: sub_152CA
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_SetAirCounterForceState
                subq.w  #1,$4A(a5)
                bmi.w   Player_InitGroundIdleState
                bsr.w   Player_CheckCounterForceDashInput
                bne.w   Player_InitiateDashAttack_UseGroundState
                move.l  #$2000,d1
                bsr.w   Player_DecelerateHorizontalVelocity
                bra.w   Player_UpdateCounterForceAnimation
; End of function Player_GroundCounterForceState
; Starts airborne Counter Force recoil, effect, and animation timing
Player_StartAirCounterForce:                            ; CODE XREF: Player_HandleFallingState+82   j  ; was: sub_152FC
                                        ; Player_HandleSpecialAttack+64   j
                bsr.w   Player_SpawnCounterForceEffect
                move.b  #$7F,(PlayerInputMask).w
                jsr     (Sys_ClearObjectBlocks16).l
                move.w  #$FFFC,$48(a5)
                move.w  #$A,$4A(a5)
                move.w  #$FFFF,$C(a5)
                move.l  #$FFFE0000,$1C(a5)
                move.l  #$FFFC0000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_SetAirCounterForceState
                neg.l   $18(a5)
; Selects the airborne Counter Force state
Player_SetAirCounterForceState:                         ; CODE XREF: Player_GroundCounterForceState+10   j  ; was: loc_1533A
                                        ; Player_StartAirCounterForce+38   j
                move.w  #$3C,4(a5)                      ; '<'
                rts
; End of function Player_StartAirCounterForce
; Applies gravity and terrain collision during airborne Counter Force
Player_AirCounterForceState:                            ; DATA XREF: ROM:0001509E   o  ; was: sub_15342
                addi.l  #$5000,$1C(a5)
                jsr     Physics_ExtendedWallCheckWrapper(pc)  ; (pc)
                nop
                tst.w   $1C(a5)
                bmi.s   Player_AirCounterForceState_CheckUpperTerrain
                bsr.w   Physics_DescendingTerrainCheckWrapper
                btst    #0,6(a5)
                bne.w   Player_InitLandingState
                bra.s   Player_UpdateCounterForceStateTimer
; ---------------------------------------------------------------------------
Player_AirCounterForceState_CheckUpperTerrain:          ; CODE XREF: Player_AirCounterForceState+12   j  ; was: loc_15366
                clr.b   6(a5)
                jsr     Physics_RisingTerrainCheckWrapper(pc)  ; (pc)
                nop
                bra.s   Player_UpdateCounterForceStateTimer
; End of function Player_AirCounterForceState
; Unreferenced Counter Force terrain/timer path preserved from the original ROM
Player_UnreferencedCounterForceTerrainPath:             ; was: sub_15372
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                bne.w   Player_InitGroundIdleState
Player_UpdateCounterForceStateTimer:                    ; CODE XREF: Player_AirCounterForceState+22   j  ; was: loc_15386
                                        ; Player_AirCounterForceState+2E   j
                subq.w  #1,$4A(a5)
                bmi.w   Player_InitFallState_Finish
                move.l  #$1800,d1
                bsr.w   Player_DecelerateHorizontalVelocity
                bra.w   Player_UpdateCounterForceAnimation
; End of function Player_UnreferencedCounterForceTerrainPath
; Detects the C-plus-down chord that turns grounded Counter Force into a dash
Player_CheckCounterForceDashInput:                      ; CODE XREF: Player_GroundCounterForceState+1C   p  ; was: sub_1539C
                btst    #5,$6A(a5)
                beq.s   Player_CheckCounterForceDashInput_Return
                btst    #1,$69(a5)
                beq.s   Player_CheckCounterForceDashInput_Return
                move.w  (PlayerHealth).w,d0
                sub.w   (PlayerMaxHealth).w,d0
                move.w  d0,(PhoenixAttackStatus).w
                moveq   #1,d0
Player_CheckCounterForceDashInput_Return:               ; CODE XREF: Player_CheckCounterForceDashInput+6   j  ; was: locret_153BA
                                        ; Player_CheckCounterForceDashInput+E   j
                rts
; End of function Player_CheckCounterForceDashInput
; Supplies facing-dependent position and velocity for the Counter Force effect
Player_SpawnCounterForceEffect:                         ; CODE XREF: Player_GroundIdleState:Player_StartGroundCounterForce   p  ; was: sub_153BC
                                        ; sub_152FC   p
                moveq   #$FFFFFFFC,d0
                move.l  #$FFFC0000,d2
                moveq   #$FFFFFFF6,d1
                btst    #4,$E(a5)
                beq.s   Player_SpawnCounterForceEffect_Create
                moveq   #$A,d1
Player_SpawnCounterForceEffect_Create:                  ; CODE XREF: Player_SpawnCounterForceEffect+10   j  ; was: loc_153D0
                bra.w   Player_CreateCounterForceEffect
; End of function Player_SpawnCounterForceEffect
; Enters state $0E, the grounded crouch
Player_InitGroundCrouchState:                           ; CODE XREF: Player_GroundIdleState+42   j  ; was: sub_153D4
                                        ; Player_GroundDecelerateState+30   j
                move.w  #2,$48(a5)
; Shared tail that installs the crouch state, timers and animation
Player_InitGroundCrouchStateCleanup:                    ; CODE XREF: Player_DashAttackState+84   j  ; was: loc_153DA
                                        ; Player_HandleSlideState+34   j
                bclr    #0,(CounterForceTriggerFlag).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #$E,4(a5)
                move.w  #$A,$4A(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #8,$5C(a5)
                move.b  #$7F,(PlayerInputMask).w
                bra.w   Player_AutoFlipDirection
; End of function Player_InitGroundCrouchState
Player_GroundCrouchState_Return:                        ; CODE XREF: Player_GroundCrouchState+1E   j  ; was: nullsub_37
                                        ; Player_GroundCrouchState+24   j
                rts
; End of function Player_GroundCrouchState_Return

; State $0E: crouched on the ground, returning to standing when down is released
Player_GroundCrouchState:                               ; DATA XREF: ROM:00015070   o  ; was: sub_15408
                bset    #1,(PlayerActionStateFlags).w
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                bsr.w   Player_CheckWeaponSelectInput
                bne.s   Player_GroundCrouchState_Return
                bsr.w   Player_CheckJumpOrDashInput
                bne.s   Player_GroundCrouchState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartGroundCounterForce
                bsr.w   Player_DecelerateHorizontalVelocityFast
                subq.w  #1,$48(a5)
                bpl.s   Player_GroundCrouchState_Render
                move.w  #$FFFF,$48(a5)
                btst    #4,$69(a5)
                beq.s   Player_GroundCrouchState_CheckReleaseInput
                tst.w   (ShootingMode).w
                bne.s   Player_GroundCrouchState_Render
Player_GroundCrouchState_CheckReleaseInput:             ; CODE XREF: Player_GroundCrouchState+46   j  ; was: loc_15456
                btst    #1,$69(a5)
                beq.w   Player_InitGroundIdleState
; Selects the armed or unarmed crouch rendering path
Player_GroundCrouchState_Render:                        ; CODE XREF: Player_GroundCrouchState+38   j  ; was: loc_15460
                                        ; Player_GroundCrouchState+4C   j
                btst    #4,$69(a5)
                beq.w   Player_RenderMotionPose
                bra.w   Player_RenderGroundMotionWithWeapon
; End of function Player_GroundCrouchState
; Enters state $0A, the grounded deceleration
Player_InitGroundDecelerateState:                       ; CODE XREF: Player_HandleLandingState+6C   j  ; was: sub_1546E
                                        ; Player_SelectGroundDirectionState+3A   j
                move.b  #$7F,(PlayerInputMask).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #$A,4(a5)
                clr.w   $48(a5)
                move.w  #4,$5C(a5)
                bra.w   Player_AutoFlipDirection
; End of function Player_InitGroundDecelerateState
; State $0A: decelerating on the ground after a landing or a released direction
Player_GroundDecelerateState:                           ; DATA XREF: ROM:0001506C   o  ; was: sub_1548C
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                bsr.w   Player_CheckWeaponSelectInput
                bne.s   Player_GroundDecelerateState_Return
                bsr.w   Player_CheckJumpOrDashInput
                bne.s   Player_GroundDecelerateState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartGroundCounterForce
                btst    #1,$69(a5)
                bne.w   Player_InitGroundCrouchState
                bsr.w   Player_DecelerateHorizontalVelocityFast
                move.l  $18(a5),d0
                bne.s   Player_GroundDecelerateState_Render
                btst    #2,$69(a5)
                bne.w   Player_SelectGroundDirectionFromDeceleration
                btst    #3,$69(a5)
                bne.w   Player_SelectGroundDirectionFromDeceleration
                bra.w   Player_InitGroundIdleState
; ---------------------------------------------------------------------------
; Renders the grounded deceleration while the player is still sliding
Player_GroundDecelerateState_Render:                    ; CODE XREF: Player_GroundDecelerateState+3C   j  ; was: loc_154E2
                btst    #4,$69(a5)
                bne.w   Player_RenderGroundMotionFrame
                movea.l #Player_CommonPrimarySpriteMapping,a1
                movea.l #Player_CommonMovementSecondarySpriteMapping,a2
                moveq   #0,d5
                moveq   #6,d6
                bra.w   Player_BuildSpritePieces
; ---------------------------------------------------------------------------
Player_GroundDecelerateState_Return:                    ; CODE XREF: Player_GroundDecelerateState+18   j  ; was: locret_15500
                                        ; Player_GroundDecelerateState+1E   j
                rts
; End of function Player_GroundDecelerateState
; Initializes player landing state
Player_InitLandingState:                                ; CODE XREF: Player_AirCounterForceState+1E   j  ; was: sub_15502
                                        ; Player_HandleFallingState+50   j
                move.b  #$7F,(PlayerInputMask).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #$16,4(a5)
                move.w  #2,$48(a5)
                move.w  #6,$4A(a5)
                move.w  #8,$5C(a5)
                move.b  #$B1,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Player_AutoFlipDirection
; End of function Player_InitLandingState
; Handles player landing state logic
Player_HandleLandingState:                              ; DATA XREF: ROM:00015078   o  ; was: sub_15532
                bset    #1,(PlayerActionStateFlags).w
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                bsr.w   Player_CheckWeaponSelectInput
                bne.s   Player_GroundDecelerateState_Return
                bsr.w   Player_CheckJumpOrDashInput
                bne.s   Player_GroundDecelerateState_Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartGroundCounterForce
                move.l  #$4000,d1
                bsr.w   Player_DecelerateHorizontalVelocity
                subq.w  #1,$4A(a5)
                subq.w  #1,$48(a5)
                bpl.s   Player_HandleLandingState_Render
                btst    #1,$69(a5)
                beq.s   Player_HandleLandingState_CheckMovementInput
                bsr.w   Player_InitGroundCrouchState
                move.w  #$FFFF,$48(a5)
                bra.s   Player_HandleLandingState_Render
; ---------------------------------------------------------------------------
Player_HandleLandingState_CheckMovementInput:           ; CODE XREF: Player_HandleLandingState+4A   j  ; was: loc_1558A
                btst    #2,$69(a5)
                bne.w   Player_SelectGroundDirectionFromDeceleration
                btst    #3,$69(a5)
                bne.w   Player_SelectGroundDirectionFromDeceleration
                bra.w   Player_InitGroundDecelerateState
; ---------------------------------------------------------------------------
Player_HandleLandingState_Render:                       ; CODE XREF: Player_HandleLandingState+42   j  ; was: loc_155A2
                                        ; Player_HandleLandingState+56   j
                btst    #4,$69(a5)
                beq.w   Player_RenderMotionPose
                bra.w   Player_RenderGroundMotionWithWeapon
; End of function Player_HandleLandingState
; Opens weapon selection with A, or toggles shooting mode with down+A
Player_CheckWeaponSelectInput:                          ; CODE XREF: Player_GroundIdleState+18   p  ; was: sub_155B0
                                        ; Player_GroundCrouchState+1A   p
                btst    #6,$6A(a5)
                beq.s   Player_CheckWeaponSelectInput_NotActivated
                btst    #1,$69(a5)
                bne.w   Player_ToggleShootingModeWithInputMask
                tst.w   (WeaponStateCooldown).w
                bmi.s   Player_CheckWeaponSelectInput_Start
Player_CheckWeaponSelectInput_NotActivated:             ; CODE XREF: Player_CheckWeaponSelectInput+6   j  ; was: loc_155C8
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
Player_CheckWeaponSelectInput_Start:                    ; CODE XREF: Player_CheckWeaponSelectInput+16   j  ; was: loc_155CC
                move.w  (WeaponSlotOffset).w,(WeaponSavedSlotOffset).w
                move.w  #$12,(WeaponStateIndex).w
                move.b  #$7F,(PlayerInputMask).w
                move.w  #0,(WeaponMenuSpawnXOffset).w
                move.w  #$FFEE,(WeaponMenuSpawnYOffset).w
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$C,4(a5)
                move.w  #4,$5C(a5)
                ; The normal entry already excluded down+A; preserve this test
                btst    #1,$69(a5)
                beq.s   Player_CheckWeaponSelectInput_ReturnActivated
                move.w  #8,$5C(a5)
; Reports successful weapon-select activation
Player_CheckWeaponSelectInput_ReturnActivated:          ; CODE XREF: Player_CheckWeaponSelectInput+54   j  ; was: loc_1560C
                moveq   #1,d0
                rts
; End of function Player_CheckWeaponSelectInput
; Holds the grounded player state while the weapon selector is active
Player_GroundWeaponSelectState:                         ; DATA XREF: ROM:0001506E   o  ; was: sub_15610
                jsr     Physics_WallCheckWrapper(pc)    ; (pc)
                nop
                bsr.w   Physics_LowerTerrainCheckWrapper
                btst    #0,6(a5)
                beq.w   Player_InitFallState
                cmpi.w  #$12,(WeaponStateIndex).w
                bmi.w   Player_InitGroundIdleState
                bra.w   Player_RenderIdleFrame
; End of function Player_GroundWeaponSelectState
; Masks input, toggles moving/fixed shooting mode, and plays its sound
Player_ToggleShootingModeWithInputMask:                 ; CODE XREF: Player_CheckWeaponSelectInput+E   j  ; was: sub_15632
                                        ; Player_CheckRecoveryWeaponSelectInput+10   p
                move.b  #$7F,(PlayerInputMask).w
                eori.w  #2,(ShootingMode).w
                move.b  #$A3,d0
                jsr     (Sound_QueueSFXRequest).l
                moveq   #0,d0
                rts
; End of function Player_ToggleShootingModeWithInputMask
; Routes a held direction to the armed ground move or to a turn
Player_SelectGroundDirectionState:                      ; CODE XREF: Player_GroundIdleState+4C   j  ; was: sub_1564C
                                        ; Player_GroundIdleState+56   j
                btst    #4,$69(a5)
                beq.s   Player_InitGroundedMovementState
                tst.w   (ShootingMode).w
                beq.s   Player_SelectGroundDirectionCheckFacing
                rts
; ---------------------------------------------------------------------------
Player_SelectGroundDirectionFromDeceleration:           ; CODE XREF: Player_GroundDecelerateState+44   j  ; was: loc_1565C
                                        ; Player_GroundDecelerateState+4E   j
                btst    #4,$69(a5)
                beq.s   Player_InitGroundedMovementState
                tst.w   (ShootingMode).w
                bne.w   Player_InitGroundIdleState
Player_SelectGroundDirectionCheckFacing:                ; CODE XREF: Player_SelectGroundDirectionState+C   j  ; was: loc_1566C
                btst    #3,$69(a5)
                beq.s   Player_SelectGroundDirectionCheckLeft
                btst    #3,$E(a5)
                bne.w   Player_InitGroundWeaponState
                bra.s   Player_InitGroundedMovementState
; ---------------------------------------------------------------------------
Player_SelectGroundDirectionCheckLeft:                  ; CODE XREF: Player_SelectGroundDirectionState+26   j  ; was: loc_15680
                btst    #2,$69(a5)
                beq.w   Player_InitGroundDecelerateState
                btst    #3,$E(a5)
                beq.w   Player_InitGroundWeaponState
; Enters state $02, grounded movement, turning the player to face the input
Player_InitGroundedMovementState:                       ; CODE XREF: Player_SelectGroundDirectionState+6   j  ; was: loc_15694
                                        ; Player_SelectGroundDirectionState+16   j
                move.b  #$7F,(PlayerInputMask).w
                move.w  #2,4(a5)
                move.w  #4,$48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #4,$5C(a5)
                bra.w   Player_AutoFlipDirection
; End of function Player_SelectGroundDirectionState
Player_GroundedMovementState_Return:                    ; CODE XREF: Player_GroundedMovementState+18   j  ; was: nullsub_38
                                        ; Player_GroundedMovementState+1E   j
                rts
; End of function Player_GroundedMovementState_Return
