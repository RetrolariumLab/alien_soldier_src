Enemy_ConvertToAlternateDefeatProjectile:               ; was: sub_2CB86
                move.w  #$1D8,(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.l  #Enemy_ProjectileAnimation08,8(a5)
                clr.w   $C(a5)
                move.w  #$10,$48(a5)
                move.l  #$FFFB2000,$1C(a5)
                move.l  #$FFFEA000,$18(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_ConvertToAlternateDefeatProjectile_Return
                neg.l   $18(a5)
Enemy_ConvertToAlternateDefeatProjectile_Return:        ; was: locret_2CBC4
                rts
; End of function Enemy_ConvertToAlternateDefeatProjectile
; Falling projectile handler
Enemy_UpdateAlternateDefeatProjectile:                  ; was: sub_2CBC6
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateAlternateDefeatProjectile_ApplyBlink
                jsr     (Effect_SpawnExplosionA).l
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateAlternateDefeatProjectile_ApplyBlink:       ; was: loc_2CBE2
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_UpdateAlternateDefeatProjectile_Return
                bclr    #7,2(a5)
Enemy_UpdateAlternateDefeatProjectile_Return:           ; was: locret_2CBF6
                rts
; End of function Enemy_UpdateAlternateDefeatProjectile
; Updates the enemy family that alternates movement and projectile attacks
Enemy_ProjectileAttackController:                       ; was: sub_2CBF8
                tst.w   4(a5)
                beq.s   Enemy_ProjectileAttackController_UpdateState
                clr.w   6(a5)
                tst.w   $24(a5)
                bpl.s   Enemy_ProjectileAttackController_UpdateState
                bsr.w   Enemy_BeginDefeatFall
; Dispatches the current attack state and updates its animation
Enemy_ProjectileAttackController_UpdateState:           ; was: loc_2CC0C
                                        ; Enemy_ProjectileAttackController+E   j
                bsr.s   Enemy_DispatchProjectileAttackState
                bra.w   Anim_UpdateProjectileAnimation
; End of function Enemy_ProjectileAttackController
; Dispatches projectile to state handler
Enemy_DispatchProjectileAttackState:                    ; was: sub_2CC12
                clr.w   $5C(a5)
                move.w  4(a5),d0
                movea.w Enemy_ProjectileAttackStateOffsets(pc,d0.w),a0
                adda.l  #Enemy_ProjectileAttackInit,a0
                jmp     (a0)
; End of function Enemy_DispatchProjectileAttackState
; ---------------------------------------------------------------------------
Enemy_ProjectileAttackStateOffsets: dc.w    Enemy_ProjectileAttackInit-Enemy_ProjectileAttackInit  ; was: off_2CC26
                dc.w    Enemy_ProjectileAttackIdleState-Enemy_ProjectileAttackInit
                dc.w    Enemy_ProjectileAttackApproachState-Enemy_ProjectileAttackInit
                dc.w    Enemy_ProjectileAttackAirborneState-Enemy_ProjectileAttackInit
                dc.w    Enemy_ProjectileAttackAirborneState-Enemy_ProjectileAttackInit
                dc.w    Enemy_DefeatFallState-Enemy_ProjectileAttackInit
                dc.w    Enemy_ProjectileAttackGroundState-Enemy_ProjectileAttackInit

; Installs the sprite and health, then falls into the idle entry
Enemy_ProjectileAttackInit:                             ; was: sub_2CC34
                                        ; ROM:Enemy_ProjectileAttackStateOffsets   o
                move.w  #$1E,$24(a5)
                bsr.w   Sprite_InitializeProjectileSprite
Enemy_ProjectileAttack_BeginIdle:                       ; was: loc_2CC3E
                                        ; Enemy_ProjectileAttackAirborneState+30   j
                move.w  #2,4(a5)
                move.w  #4,$5C(a5)
                move.w  #$60,$48(a5)                    ; '`'
                clr.l   $18(a5)
; Holds position until the timer expires, then attacks nearby or approaches
Enemy_ProjectileAttackIdleState:                        ; was: loc_2CC54
                jsr     (Physics_EntityWallCheck).l
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                beq.w   Enemy_ProjectileAttack_BeginAirborne
                subq.w  #1,$48(a5)
                bpl.s   Enemy_ProjectileAttack_ApplyFriction
                move.w  #$FFFF,$48(a5)
                bsr.w   Enemy_FacePlayer
                cmpi.w  #$60,d0                         ; '`'
                bpl.s   Enemy_ProjectileAttack_CheckMoveTimer
                bra.w   Enemy_ProjectileAttack_BeginGroundAttack
; ---------------------------------------------------------------------------
Enemy_ProjectileAttack_CheckMoveTimer:                  ; was: loc_2CC84
                tst.w   $48(a5)
                bmi.w   Enemy_ProjectileAttack_BeginApproach
Enemy_ProjectileAttack_ApplyFriction:                   ; was: loc_2CC8C
                bra.w   Physics_ApplyHorizontalFriction
; ---------------------------------------------------------------------------
Enemy_ProjectileAttack_BeginApproach:                   ; was: loc_2CC90
                move.w  #4,4(a5)
                move.w  #8,$5C(a5)
; Tracks player position and adjusts projectile direction
Enemy_ProjectileAttackApproachState:                    ; was: loc_2CC9C
                jsr     (Physics_EntityWallCheck).l
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                beq.w   Enemy_ProjectileAttack_BeginAirborne
                bsr.w   Enemy_FacePlayer
                cmpi.w  #$50,d0                         ; 'P'
                bmi.w   Enemy_ProjectileAttack_BeginIdle
                btst    #1,7(a5)
                bne.w   Enemy_ProjectileAttack_BeginLeap
                btst    #0,7(a5)
                bne.w   Enemy_ProjectileAttack_BeginLeap
                bra.w   Physics_SetHorizontalVelocityByFlip
; ---------------------------------------------------------------------------
Enemy_ProjectileAttack_BeginLeap:                       ; was: loc_2CCD6
                                        ; Enemy_ProjectileAttackInit+9A   j
                move.w  #8,4(a5)
                move.w  #$24,$5C(a5)                    ; '$'
                move.l  #$FFFA4000,$1C(a5)
                bsr.w   Physics_SetHorizontalVelocityByFlip
; End of function Enemy_ProjectileAttackInit
; Applies gravity with max falling speed $7C000, checks terrain and player collision
Enemy_ProjectileAttackAirborneState:                    ; was: sub_2CCEE
                jsr     (Physics_EntityExtendedWallCheck).l
                cmpi.l  #$7C000,$1C(a5)
                bmi.s   Enemy_ProjectileAttack_ApplyGravity
                move.l  #$7C000,$1C(a5)
                bra.s   Enemy_ProjectileAttack_CheckGround
; ---------------------------------------------------------------------------
Enemy_ProjectileAttack_ApplyGravity:                    ; was: loc_2CD08
                addi.l  #$6000,$1C(a5)
                bmi.s   Enemy_ProjectileAttack_CheckCeiling
Enemy_ProjectileAttack_CheckGround:                     ; was: loc_2CD12
                jsr     (Physics_CheckLowerTerrainWhenDescending).l
                btst    #0,6(a5)
                bne.w   Enemy_ProjectileAttack_BeginIdle
Enemy_ProjectileAttack_CheckCeiling:                    ; was: loc_2CD22
                jmp     Physics_CheckUpperTerrainWhenRising
; End of function Enemy_ProjectileAttackAirborneState
; Sets state 6, halves horizontal velocity, branches to gravity/collision routine
Enemy_ProjectileAttack_BeginAirborne:                   ; was: sub_2CD28
                                        ; Enemy_ProjectileAttackInit+7A   j
                move.w  #6,4(a5)
                move.w  #$28,$5C(a5)                    ; '('
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                bra.w   Enemy_ProjectileAttackAirborneState
; End of function Enemy_ProjectileAttack_BeginAirborne
; Enters state $C, the ground attack, with a $36-frame window
Enemy_ProjectileAttack_BeginGroundAttack:               ; was: sub_2CD42
                move.w  #$C,4(a5)
                move.w  #$10,$5C(a5)
                move.w  #$36,$48(a5)                    ; '6'
; End of function Enemy_ProjectileAttack_BeginGroundAttack
; Ground-based enemy movement with projectile spawning at specific timing
Enemy_ProjectileAttackGroundState:                      ; was: sub_2CD54
                jsr     (Physics_EntityWallCheck).l
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                beq.w   Enemy_ProjectileAttack_BeginAirborne
                subq.w  #1,$48(a5)
                bmi.w   Enemy_ProjectileAttack_BeginIdle
                cmpi.w  #$1E,$48(a5)
                bne.s   Enemy_ProjectileAttackGroundState_UpdateMovement
                moveq   #$18,d5
                moveq   #$FFFFFFFA,d6
                move.l  #$38000,d7
                btst    #3,$E(a5)
                beq.s   Enemy_ProjectileAttackGroundState_SpawnProjectile
                neg.w   d5
                neg.l   d7
Enemy_ProjectileAttackGroundState_SpawnProjectile:      ; was: loc_2CD90
                jsr     (Projectile_SpawnTrailingArcHazardType1D0).l
Enemy_ProjectileAttackGroundState_UpdateMovement:       ; was: loc_2CD96
                bsr.w   Physics_ApplyHorizontalFriction
                cmpi.w  #$10,$48(a5)
                bmi.s   Enemy_ProjectileAttackGroundState_Return
                bsr.w   Enemy_FacePlayer
Enemy_ProjectileAttackGroundState_Return:               ; was: locret_2CDA6
                rts
; End of function Enemy_ProjectileAttackGroundState
; Converts the current enemy to its falling defeat state
Enemy_BeginDefeatFall:                                  ; was: sub_2CDA8
                move.w  #$A,4(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.w  #$24,$5C(a5)                    ; '$'
                move.w  #$10,$48(a5)
                move.l  #$FFFB2000,$1C(a5)
                move.l  #$FFFEA000,$18(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_DefeatFallState
                neg.l   $18(a5)
; Updates the falling defeat state, then creates an explosion and pickup
Enemy_DefeatFallState:                                  ; was: loc_2CDE2
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_DefeatFallState_ApplyBlink
                jsr     (Effect_SpawnExplosionA).l
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_DefeatFallState_ApplyBlink:                       ; was: loc_2CDFE
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_DefeatFallState_Return
                bclr    #7,2(a5)
Enemy_DefeatFallState_Return:                           ; was: locret_2CE12
                rts
; End of function Enemy_BeginDefeatFall
; ---------------------------------------------------------------------------
Enemy_HomingAttackInitialDelays:    dc.w    $98, $60    ; was: word_2CE14
Enemy_HomingAttackShotCounts:       dc.w    1, 4        ; was: word_2CE18

; Updates the enemy family that emits bursts of homing projectiles
Enemy_HomingAttackController:                           ; was: sub_2CE1C
                tst.w   4(a5)
                beq.s   Enemy_HomingAttackController_UpdateState
                clr.w   6(a5)
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertToAlternateDefeatProjectile
; Dispatches the current homing-attack state and updates its animation
Enemy_HomingAttackController_UpdateState:               ; was: loc_2CE2E
                bsr.s   Enemy_DispatchHomingAttackState
                bra.w   Anim_UpdateProjectileAnimation
; End of function Enemy_HomingAttackController
; Dispatches the homing-attack state
Enemy_DispatchHomingAttackState:                        ; was: sub_2CE34
                clr.w   $5C(a5)
                move.w  4(a5),d0
                movea.w Enemy_HomingAttackStateOffsets(pc,d0.w),a0
                adda.l  #Enemy_HomingAttackInit,a0
                jmp     (a0)
; End of function Enemy_DispatchHomingAttackState
; ---------------------------------------------------------------------------
Enemy_HomingAttackStateOffsets: dc.w    Enemy_HomingAttackInit-Enemy_HomingAttackInit  ; was: off_2CE48
                dc.w    Enemy_HomingAttackWaitState-Enemy_HomingAttackInit
                dc.w    Enemy_HomingAttackBurstState-Enemy_HomingAttackInit

; Initializes the difficulty-scaled homing attack
Enemy_HomingAttackInit:                                 ; was: sub_2CE4E
                                        ; ROM:Enemy_HomingAttackStateOffsets   o
                move.w  #$A,$24(a5)
                bsr.w   Sprite_InitializeProjectileSprite
Enemy_HomingAttack_BeginWait:                           ; was: loc_2CE58
                move.w  #2,4(a5)
                move.w  #4,$5C(a5)
                lea     Enemy_HomingAttackInitialDelays(pc),a0
                move.w  (DifficultyMode).w,d0
                move.w  (a0,d0.w),$48(a5)
; Waits for timer countdown before transitioning
Enemy_HomingAttackWaitState:                            ; was: loc_2CE72
                subq.w  #1,$48(a5)
                bmi.s   Enemy_HomingAttack_BeginBurst
                rts
; ---------------------------------------------------------------------------
Enemy_HomingAttack_BeginBurst:                          ; was: loc_2CE7A
                addq.w  #2,4(a5)
                move.w  #$80,$C(a5)
                clr.w   $48(a5)
                lea     Enemy_HomingAttackShotCounts(pc),a0
                move.w  (DifficultyMode).w,d0
                move.w  (a0,d0.w),$4A(a5)
; Main loop for homing projectile with angle updates and spawning
Enemy_HomingAttackBurstState:                           ; was: loc_2CE96
                cmpi.w  #$80,$C(a5)
                bmi.s   Enemy_HomingAttack_Return
                subq.w  #1,$4A(a5)
                bmi.w   Enemy_HomingAttack_BeginWait
                bsr.w   Enemy_CalculateDirectionalSprite
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_HomingAttack_Return
                move.w  d3,d0
                move.w  d4,d1
                move.w  d2,d6
                move.w  (GlobalSpritePriorityBit).w,d2
                addi.w  #$40,d2                         ; '@'
                moveq   #$A,d7
                jmp     Projectile_InitializeTwoSpeedShot
; ---------------------------------------------------------------------------
Enemy_HomingAttack_Return:                              ; was: locret_2CEC8
                                        ; Enemy_HomingAttackInit+62   j
                rts
; End of function Enemy_HomingAttackInit

; Updates the ship-patrol enemy and converts it to the shared defeat object
Enemy_ShipPatrolController:                             ; was: sub_2CECA
                tst.w   4(a5)
                beq.s   Enemy_ShipPatrolController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertToDefeatProjectile
Enemy_ShipPatrolController_UpdateState:                 ; was: loc_2CED8
                bsr.s   Enemy_DispatchShipPatrolState
                bra.w   Enemy_UpdateBehaviorAnimation
; End of function Enemy_ShipPatrolController
; Dispatches the ship-patrol enemy's state
Enemy_DispatchShipPatrolState:                          ; was: sub_2CEDE
                clr.w   $5C(a5)
                move.w  4(a5),d0
                movea.w Enemy_ShipPatrolStateOffsets(pc,d0.w),a0
                adda.l  #Enemy_ShipPatrolInit,a0
                jmp     (a0)
; End of function Enemy_DispatchShipPatrolState
; ---------------------------------------------------------------------------
Enemy_ShipPatrolStateOffsets:
                dc.w    Enemy_ShipPatrolInit-Enemy_ShipPatrolInit  ; was: off_2CEF2
                dc.w    Enemy_ShipPatrolIdleState-Enemy_ShipPatrolInit

; Initializes the ship-patrol enemy's shared sprite state
Enemy_ShipPatrolInit:                                   ; was: sub_2CEF6
                                        ; ROM:Enemy_ShipPatrolStateOffsets   o
                moveq   #0,d0
                bsr.w   Enemy_SetupBehaviorSprite
                addq.w  #2,4(a5)
                clr.w   $48(a5)
; Repeats the ship-patrol idle animation timer
Enemy_ShipPatrolIdleState:                              ; was: loc_2CF04
                subq.w  #1,$48(a5)
                bpl.s   Enemy_ShipPatrolIdleState_Return
                move.w  #$38,$48(a5)                    ; '8'
                move.w  #$10,$5C(a5)
Enemy_ShipPatrolIdleState_Return:                       ; was: locret_2CF16
                rts
; End of function Enemy_ShipPatrolInit
