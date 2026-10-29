; Shared enemy and projectile state machines
Enemy_BehaviorController:                               ; was: sub_2C6A8
                tst.w   4(a5)
                beq.s   Enemy_DispatchBehaviorState
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertToDefeatProjectile
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertToDefeatProjectile
                btst    #7,$22(a5)
                beq.s   Enemy_BehaviorController_UpdateDelay
                btst    #4,$22(a5)
                bne.s   Enemy_BehaviorController_UpdateDelay
                bsr.w   Enemy_ConvertToDefeatProjectile
                addq.w  #1,$4A(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_BehaviorController_UpdateDelay:                   ; was: loc_2C6D8
                                        ; Enemy_BehaviorController+24   j
                cmpi.w  #$FF00,$5A(a5)
                bmi.w   Enemy_ConvertToDefeatProjectile
                subq.w  #1,$5A(a5)
                bpl.s   Enemy_BehaviorController_RefreshRandom
                move.w  #$13,$5E(a5)
Enemy_BehaviorController_RefreshRandom:                 ; was: loc_2C6EE
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Dispatches enemy to behavior state handler and updates animation
Enemy_DispatchBehaviorState:                            ; was: loc_2C6F8
                bsr.s   Enemy_StateDispatcher
                bra.w   Enemy_UpdateBehaviorAnimation
; End of function Enemy_BehaviorController
; Dispatches enemy to appropriate state handler
Enemy_StateDispatcher:                                  ; was: sub_2C6FE
                clr.w   $5C(a5)
                move.w  4(a5),d0
                movea.w Enemy_BehaviorStateOffsets(pc,d0.w),a0
                adda.l  #Enemy_MainStateMachine,a0
                jmp     (a0)
; End of function Enemy_StateDispatcher
; ---------------------------------------------------------------------------
Enemy_BehaviorStateOffsets: dc.w    Enemy_MainStateMachine-Enemy_MainStateMachine  ; was: off_2C712
                dc.w    Enemy_MainStateMachine_UpdateState-Enemy_MainStateMachine
                dc.w    Enemy_ExecuteMovementPattern-Enemy_MainStateMachine
                dc.w    Enemy_MainStateMachine_TerrainCheck-Enemy_MainStateMachine
                dc.w    Enemy_MainStateMachine_GroundedTimer-Enemy_MainStateMachine
                dc.w    Enemy_MainStateMachine_AttackCooldown-Enemy_MainStateMachine

; Main enemy state machine with movement and attack patterns
Enemy_MainStateMachine:                                 ; was: sub_2C71E
                                        ; ROM:Enemy_BehaviorStateOffsets   o
                moveq   #0,d0
                bsr.w   Enemy_SetupBehaviorSprite
Enemy_MainStateMachine_StartMove:                       ; was: loc_2C724
                                        ; Enemy_MainStateMachine+198   j
                btst    #0,$5F(a5)
                bne.w   Enemy_MainStateMachine_SelectMovement
                move.w  #2,4(a5)
                move.w  #4,$5C(a5)
                move.w  (RandomNumberState).w,d1
                andi.w  #$3F,d1                         ; '?'
                addi.w  #8,d1
                move.w  d1,$48(a5)
; Main enemy AI state machine update loop
Enemy_MainStateMachine_UpdateState:                     ; was: loc_2C74A
                subq.w  #1,$48(a5)
                bmi.w   Enemy_MainStateMachine_SelectMovement
                bsr.w   Enemy_UpdateGroundCollision
                btst    #0,6(a5)
                beq.w   Enemy_MainStateMachine_BeginAirborne
                bsr.w   Enemy_DecelerateHorizontal
Enemy_MainStateMachine_CheckPlayerDistance:             ; was: loc_2C764
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$78,d0                         ; 'x'
                bpl.s   Enemy_MainStateMachine_CheckCloseRange
                btst    #2,$5F(a5)
                bne.w   Enemy_MainStateMachine_BeginAttackCooldown
Enemy_MainStateMachine_CheckCloseRange:                 ; was: loc_2C77A
                cmpi.w  #$50,d0                         ; 'P'
                bpl.s   Enemy_MainStateMachine_Return
                btst    #3,$5F(a5)
                bne.w   Enemy_MainStateMachine_BeginLeap
Enemy_MainStateMachine_Return:                          ; was: locret_2C78A
                rts
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_SelectMovement:                  ; was: loc_2C78C
                                        ; Enemy_MainStateMachine+30   j
                btst    #4,$5F(a5)
                bne.w   Enemy_MainStateMachine_BeginMovement
                bsr.w   Enemy_FacePlayer
                bra.w   *+4
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_BeginMovement:                   ; was: loc_2C79E
                                        ; Enemy_MainStateMachine+7C   j
                move.w  #4,4(a5)
                move.w  #8,$5C(a5)
                move.w  (RandomNumberState).w,d1
                andi.w  #$7F,d1
                addi.w  #$80,d1
                move.w  d1,$48(a5)
                tst.w   $5A(a5)
                bpl.s   Enemy_ExecuteMovementPattern
                bset    #3,$E(a5)
; Executes enemy movement pattern with terrain collision checks
Enemy_ExecuteMovementPattern:                           ; was: loc_2C7C6
                btst    #0,$5F(a5)
                bne.w   Enemy_MainStateMachine_UpdateMovement
                subq.w  #1,$48(a5)
                bmi.w   Enemy_MainStateMachine_StartMove
Enemy_MainStateMachine_UpdateMovement:                  ; was: loc_2C7D8
                bsr.w   Enemy_UpdateGroundCollision
                btst    #0,6(a5)
                beq.w   Enemy_MainStateMachine_BeginAirborne
                btst    #3,$E(a5)
                bne.s   Enemy_MainStateMachine_CheckLeftWall
                btst    #1,7(a5)
                beq.s   Enemy_MainStateMachine_Accelerate
                bra.s   Enemy_MainStateMachine_ReverseAtWall
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_CheckLeftWall:                   ; was: loc_2C7F8
                btst    #0,7(a5)
                beq.s   Enemy_MainStateMachine_Accelerate
Enemy_MainStateMachine_ReverseAtWall:                   ; was: loc_2C800
                btst    #1,$5F(a5)
                bne.w   Enemy_MainStateMachine_BeginLeap
                eori.w  #$800,$E(a5)
                clr.l   $18(a5)
Enemy_MainStateMachine_Accelerate:                      ; was: loc_2C814
                                        ; Enemy_MainStateMachine+E0   j
                bsr.w   Enemy_AccelerateHorizontal
                bra.w   Enemy_MainStateMachine_CheckPlayerDistance
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_BeginAirborne:                   ; was: loc_2C81C
                                        ; Enemy_MainStateMachine+C4   j
                move.l  #$FFFEE000,$1C(a5)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                bra.s   Enemy_MainStateMachine_SetAirborneState
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_BeginLeap:                       ; was: loc_2C830
                                        ; Enemy_MainStateMachine+E8   j
                move.l  #$FFFA8000,$1C(a5)
                move.l  #$FFFE8000,$18(a5)
                bsr.w   Enemy_OrientLeftwardVelocityByFacing
Enemy_MainStateMachine_SetAirborneState:                ; was: loc_2C844
                move.w  #6,4(a5)
                move.w  #$14,$5C(a5)
; Performs terrain collision check in enemy state machine
Enemy_MainStateMachine_TerrainCheck:                    ; was: loc_2C850
                jsr     (Physics_EntityExtendedWallCheck).l
                bsr.w   Enemy_ApplyGravityTowardFallSpeedLimit
                bmi.s   Enemy_MainStateMachine_CheckRisingTerrain
                jsr     (Physics_CheckLowerTerrainWhenDescending).l
                btst    #0,6(a5)
                bne.w   Enemy_MainStateMachine_BeginGroundedState
                rts
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_CheckRisingTerrain:              ; was: loc_2C86E
                jmp     Physics_CheckUpperTerrainWhenRising
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_BeginGroundedState:              ; was: loc_2C874
                move.w  #8,4(a5)
                move.w  #$C,$5C(a5)
                move.w  #$14,$48(a5)
; Handles grounded state timer for enemy
Enemy_MainStateMachine_GroundedTimer:                   ; was: loc_2C886
                subq.w  #1,$48(a5)
                bmi.w   Enemy_MainStateMachine_SelectMovement
                bsr.w   Enemy_UpdateGroundCollision
                btst    #0,6(a5)
                beq.w   Enemy_MainStateMachine_BeginAirborne
                bra.w   Enemy_DecelerateHorizontal
; ---------------------------------------------------------------------------
Enemy_MainStateMachine_BeginAttackCooldown:             ; was: loc_2C8A0
                move.w  #$A,4(a5)
                move.w  #$10,$5C(a5)
                move.w  #$36,$48(a5)                    ; '6'
; Decrements attack timer and branches to attack init or face player timing
Enemy_MainStateMachine_AttackCooldown:                  ; was: loc_2C8B2
                subq.w  #1,$48(a5)
                bmi.w   Enemy_MainStateMachine_StartMove
                bsr.w   Enemy_UpdateGroundCollision
                btst    #0,6(a5)
                beq.w   Enemy_MainStateMachine_BeginAirborne
                bsr.w   Enemy_DecelerateHorizontal
                cmpi.w  #$1E,$48(a5)
                bne.s   Enemy_CheckFacePlayerTiming
                bra.w   Enemy_SpawnTrackedProjectile
; ---------------------------------------------------------------------------
; Checks if it's time to face player direction during movement
Enemy_CheckFacePlayerTiming:                            ; was: loc_2C8D8
                cmpi.w  #$10,$48(a5)
                bpl.w   Enemy_FacePlayer
                rts
; End of function Enemy_MainStateMachine
; Index $AC of the handler table: drives the two-state destruction delay
Enemy_DestructionDelayController:                       ; was: sub_2C8E4
                bsr.s   Enemy_DispatchVisibilityState
                bra.w   Enemy_UpdateBehaviorAnimation
; End of function Enemy_DestructionDelayController
; Dispatches the object's visibility/destruction substate
Enemy_DispatchVisibilityState:                          ; was: sub_2C8EA
                clr.w   $5C(a5)
                move.w  4(a5),d0
                movea.w Enemy_VisibilityStateOffsets(pc,d0.w),a0
                adda.l  #Enemy_BeginDestructionDelay,a0
                jmp     (a0)
; End of function Enemy_DispatchVisibilityState
; ---------------------------------------------------------------------------
Enemy_VisibilityStateOffsets:   dc.w    Enemy_BeginDestructionDelay-Enemy_BeginDestructionDelay  ; was: off_2C8FE
                dc.w    Enemy_UpdateDestructionDelay-Enemy_BeginDestructionDelay

; Initializes the delayed destruction state
Enemy_BeginDestructionDelay:                            ; was: sub_2C902
                                        ; ROM:Enemy_VisibilityStateOffsets   o
                addq.w  #2,4(a5)
                moveq   #0,d0
                bsr.w   Enemy_SetupBehaviorSprite
                move.w  #$24,$48(a5)                    ; '$'
                clr.b   $21(a5)
                move.b  #$7C,$20(a5)                    ; '|'
                move.w  #4,$5C(a5)
                bclr    #7,$E(a5)
; Counts down and converts the object to its terminal effect type
Enemy_UpdateDestructionDelay:                           ; was: loc_2C928
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateDestructionDelay_Return
                move.w  #$1C,(a5)
                moveq   #0,d0
                bsr.w   Enemy_SetupBehaviorSprite
Enemy_UpdateDestructionDelay_Return:                    ; was: locret_2C938
                rts
; End of function Enemy_BeginDestructionDelay
; Initializes sprite properties for enemy object
Sprite_InitializeEnemySprite:                           ; was: sub_2C93A
                move.w  #$E300,2(a5)
                move.w  (StandardEnemyTileAttr).w,d0
                or.w    (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a5)
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.w  #$2A,$26(a5)                    ; '*'
                move.l  #$E818F010,$2C(a5)
                move.l  #$E21EE818,$28(a5)
                rts
; End of function Sprite_InitializeEnemySprite
; Updates enemy animation frame based on state
Anim_UpdateEnemyAnimation:                              ; was: sub_2C970
                move.w  $5C(a5),d0
                beq.s   Anim_UpdateEnemyAnimation_Return
                subq.w  #4,d0
                move.l  PeriodicShotEnemySpriteAnimationPointers(pc,d0.w),8(a5)
                clr.w   $C(a5)
Anim_UpdateEnemyAnimation_Return:                       ; was: locret_2C982
                rts
; End of function Anim_UpdateEnemyAnimation
; ---------------------------------------------------------------------------
PeriodicShotEnemySpriteAnimationPointers:   dc.l    PeriodicShotEnemyWaitSpriteAnimation  ; was: off_2C984
                dc.l    PeriodicShotEnemyTransitionSpriteAnimation
                dc.l    PeriodicShotEnemyAttackSpriteAnimation

; Index $11 of the handler table: drives the periodic-shot enemy
Enemy_PeriodicShotController:                           ; was: sub_2C990
                tst.b   $21(a5)
                beq.s   Enemy_PeriodicShotController_RunState
                clr.w   6(a5)
                tst.w   $24(a5)
                bpl.s   Enemy_PeriodicShotController_RunState
                jsr     (Effect_SpawnExplosionB).l
                moveq   #3,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
; Runs the periodic-shot state and then its animation update
Enemy_PeriodicShotController_RunState:                  ; was: loc_2C9AE
                                        ; Enemy_PeriodicShotController+E   j
                bsr.s   Enemy_DispatchPeriodicShotState
                bra.w   Anim_UpdateEnemyAnimation
; End of function Enemy_PeriodicShotController
; Dispatches the four periodic-shot states by offset from the first
Enemy_DispatchPeriodicShotState:                        ; was: sub_2C9B4
                clr.w   $5C(a5)
                move.w  4(a5),d0
                movea.w Enemy_PeriodicShotStateOffsets(pc,d0.w),a0
                adda.l  #Enemy_InitializeWithHealth,a0
                jmp     (a0)
; End of function Enemy_DispatchPeriodicShotState
; ---------------------------------------------------------------------------
Enemy_PeriodicShotStateOffsets: dc.w    Enemy_InitializeWithHealth-Enemy_InitializeWithHealth  ; was: off_2C9C8
                dc.w    Enemy_InitializeWaitState-Enemy_InitializeWithHealth
                dc.w    Enemy_AdvanceTimedState-Enemy_InitializeWithHealth
                dc.w    Enemy_UpdatePeriodicShots-Enemy_InitializeWithHealth

; Initializes enemy with health value and sprite setup
Enemy_InitializeWithHealth:                             ; was: sub_2C9D0
                                        ; ROM:Enemy_PeriodicShotStateOffsets   o
                move.w  #$62,$24(a5)                    ; 'b'
                bsr.w   Sprite_InitializeEnemySprite
                clr.w   $48(a5)
Enemy_InitializeWithHealth_EnterWaitState:              ; was: loc_2C9DE
                move.w  #2,4(a5)
                move.w  #4,$5C(a5)
; Initializes enemy waiting state with timer values
Enemy_InitializeWaitState:                              ; was: loc_2C9EA
                subq.w  #1,$48(a5)
                bpl.s   Enemy_InitializeWaitState_Return
                addq.w  #2,4(a5)
                move.w  #$28,$48(a5)                    ; '('
                move.w  #8,$5C(a5)
Enemy_InitializeWaitState_Return:                       ; was: locret_2CA00
                rts
; End of function Enemy_InitializeWithHealth
; Advances to the next state after a fixed delay
Enemy_AdvanceTimedState:                                ; was: sub_2CA02
                subq.w  #1,$48(a5)
                bpl.s   Enemy_AdvanceTimedState_Return
                addq.w  #2,4(a5)
                move.w  #$180,$48(a5)
                move.w  #$C,$5C(a5)
Enemy_AdvanceTimedState_Return:                         ; was: locret_2CA18
                rts
; End of function Enemy_AdvanceTimedState
; Runs the periodic-shot state and returns to the wait state when it expires
Enemy_UpdatePeriodicShots:                              ; was: sub_2CA1A
                subq.w  #1,$48(a5)
                bpl.s   Enemy_TryPeriodicShot
                move.w  #$120,$48(a5)
                bra.w   Enemy_InitializeWithHealth_EnterWaitState
; ---------------------------------------------------------------------------
; Emits a targeted shot every 32 frames
Enemy_TryPeriodicShot:                                  ; was: loc_2CA2A
                move.w  $48(a5),d0
                andi.w  #$1F,d0
                bne.s   Enemy_TryPeriodicShot_Return
                moveq   #0,d5
                moveq   #$FFFFFFF0,d6
                jsr     (Projectile_SpawnAimedArcFromEnemy).l
Enemy_TryPeriodicShot_Return:                           ; was: locret_2CA3E
                rts
; End of function Enemy_UpdatePeriodicShots
; Initializes sprite properties for projectile object
Sprite_InitializeProjectileSprite:                      ; was: sub_2CA40
                                        ; Enemy_HomingAttackInit+6   p
                move.w  #$EF00,2(a5)
                move.w  (EnemyProjectileTileAttr).w,d0
                or.w    (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a5)
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.b  #8,$23(a5)
                move.w  #$F,$26(a5)
                move.l  #$F010F808,$2C(a5)
                move.l  #$E420F010,$28(a5)
                rts
; End of function Sprite_InitializeProjectileSprite
; Updates projectile animation frame
Anim_UpdateProjectileAnimation:                         ; was: sub_2CA7C
                                        ; Enemy_HomingAttackController+14   j
                move.w  $5C(a5),d0
                beq.s   Anim_UpdateProjectileAnimation_Return
                subq.w  #4,d0
                move.l  Enemy_ProjectileAnimationPointers(pc,d0.w),8(a5)
                clr.w   $C(a5)
Anim_UpdateProjectileAnimation_Return:                  ; was: locret_2CA8E
                rts
; End of function Anim_UpdateProjectileAnimation
; ---------------------------------------------------------------------------
Enemy_ProjectileAnimationPointers:  dc.l    Enemy_ProjectileAnimation00  ; was: off_2CA90
                dc.l    Enemy_ProjectileAnimation01
                dc.l    Enemy_ProjectileAnimation02
                dc.l    Enemy_ProjectileAnimation03
                dc.l    Enemy_ProjectileAnimation04
                dc.l    Enemy_ProjectileAnimation05
                dc.l    Enemy_ProjectileAnimation06
                dc.l    Enemy_ProjectileAnimation07
                dc.l    Enemy_ProjectileAnimation08
                dc.l    Enemy_ProjectileAnimation09

; Sets horizontal velocity based on entity flip direction
Physics_SetHorizontalVelocityByFlip:                    ; was: sub_2CAB8
                                        ; Enemy_ProjectileAttackInit+B6   p
                btst    #3,$E(a5)
                bne.s   Physics_SetHorizontalVelocityByFlip_SetLeft
                move.l  #$30000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Physics_SetHorizontalVelocityByFlip_SetLeft:            ; was: loc_2CACA
                move.l  #$FFFD0000,$18(a5)
                rts
; End of function Physics_SetHorizontalVelocityByFlip
; Applies friction to horizontal velocity by decrementing/incrementing by $4000 toward zero
Physics_ApplyHorizontalFriction:                        ; was: sub_2CAD4
                                        ; sub_2CD54:Enemy_ProjectileAttackGroundState_UpdateMovement   p
                move.l  $18(a5),d0
                beq.s   Physics_ApplyHorizontalFriction_Return
                bmi.s   Physics_ApplyHorizontalFriction_AdjustNegative
                cmpi.l  #$4000,d0
                bmi.s   Physics_ApplyHorizontalFriction_Stop
                subi.l  #$4000,d0
                move.l  d0,$18(a5)
Physics_ApplyHorizontalFriction_Return:                 ; was: locret_2CAEE
                rts
; ---------------------------------------------------------------------------
Physics_ApplyHorizontalFriction_AdjustNegative:         ; was: loc_2CAF0
                cmpi.l  #$FFFFC000,d0
                bpl.s   Physics_ApplyHorizontalFriction_Stop
                addi.l  #$4000,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Physics_ApplyHorizontalFriction_Stop:                   ; was: loc_2CB04
                                        ; Physics_ApplyHorizontalFriction+22   j
                clr.l   $18(a5)
                rts
; End of function Physics_ApplyHorizontalFriction
; Calculates appropriate sprite and offsets based on angle to player
Enemy_CalculateDirectionalSprite:                       ; was: sub_2CB0A
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d5
                addi.w  #$20,d5                         ; ' '
                lsr.w   #4,d5
                andi.w  #$1C,d5
                lea     Enemy_DirectionalAnimationPointers(pc),a0
                nop
                move.l  (a0,d5.w),d0
                bclr    #3,$E(a5)
                bclr    #0,d0
                beq.s   Sprite_SetDirectionalAnimation
                bset    #3,$E(a5)
; Sets directional animation sprite based on calculated angle
Sprite_SetDirectionalAnimation:                         ; was: loc_2CB38
                move.l  d0,8(a5)
                clr.w   $C(a5)
                lea     Enemy_DirectionalSpriteOffsets(pc),a1
                nop
                lsr.w   #1,d5
                move.b  (a1,d5.w),d3
                move.b  1(a1,d5.w),d4
                ext.w   d3
                ext.w   d4
                rts
; End of function Enemy_CalculateDirectionalSprite
; ---------------------------------------------------------------------------
Enemy_DirectionalAnimationPointers: dc.l    Enemy_ProjectileAnimation03  ; was: off_2CB56
                dc.l    Enemy_ProjectileAnimation06
                dc.l    Enemy_ProjectileAnimation04
                dc.l    Enemy_ProjectileAnimation06+1
                dc.l    Enemy_ProjectileAnimation03+1
                dc.l    Enemy_ProjectileAnimation04+1
                dc.l    Enemy_ProjectileAnimation05
                dc.l    Enemy_ProjectileAnimation04
Enemy_DirectionalSpriteOffsets: dc.w    $12F8, $C06, 0, $F406, $EEF8, $F4E8, $E4, $CE8  ; was: word_2CB76
