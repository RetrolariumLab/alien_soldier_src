; Updates enemy facing direction to track player
Enemy_FacePlayer:                                       ; was: sub_2CF18
                                        ; Enemy_MainStateMachine+1C0   j
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Enemy_FacePlayer_FaceRight
                bset    #3,$E(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_FacePlayer_FaceRight:                             ; was: loc_2CF2A
                bclr    #3,$E(a5)
                rts
; End of function Enemy_FacePlayer
; Keeps an initialized leftward velocity when facing left, or negates it for right
Enemy_OrientLeftwardVelocityByFacing:                   ; was: sub_2CF32
                btst    #3,$E(a5)
                bne.s   Enemy_OrientLeftwardVelocityByFacing_Return
                neg.l   $18(a5)
Enemy_OrientLeftwardVelocityByFacing_Return:            ; was: locret_2CF3E
                rts
; End of function Enemy_OrientLeftwardVelocityByFacing
; Clamps an existing fall speed at $7C000, otherwise adds $6000 acceleration
Enemy_ApplyGravityTowardFallSpeedLimit:                 ; was: sub_2CF40
                tst.l   $1C(a5)
                bmi.s   Enemy_ApplyGravityTowardFallSpeedLimit_AddAcceleration
                cmpi.l  #$7C000,$1C(a5)
                bmi.s   Enemy_ApplyGravityTowardFallSpeedLimit_AddAcceleration
                move.l  #$7C000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_ApplyGravityTowardFallSpeedLimit_AddAcceleration:  ; was: loc_2CF5A
                                        ; Enemy_ApplyGravityTowardFallSpeedLimit+E   j
                addi.l  #$6000,$1C(a5)
                rts
; End of function Enemy_ApplyGravityTowardFallSpeedLimit
; Updates wall and lower-terrain collision for the current enemy
Enemy_UpdateGroundCollision:                            ; was: sub_2CF64
                                        ; sub_2C71E:Enemy_MainStateMachine_UpdateMovement   p
                jsr     (Physics_EntityWallCheck).l
                jmp     Physics_CheckLowerTerrain
; End of function Enemy_UpdateGroundCollision
; Shows the object on even frames and hides it on odd frames for a steady blink
Enemy_UpdateBlinkVisibility:                            ; was: sub_2CF70
                                        ; sub_2DEFE   p
                move.w  (FrameCounter).w,d0
                andi.w  #1,d0
                beq.s   Enemy_UpdateBlinkVisibility_Show
                andi.w  #$7FFF,2(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_UpdateBlinkVisibility_Show:                       ; was: loc_2CF82
                ori.w   #$8000,2(a5)
                rts
; End of function Enemy_UpdateBlinkVisibility
; Initializes display, collision, and phase-control fields for the phase enemy
Enemy_SetupPhasePatternSprite:                          ; was: sub_2CF8A
                move.w  #$EF00,2(a5)
                move.w  (PhaseEnemyTileAttr).w,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                btst    #7,$5F(a5)
                beq.s   Enemy_SetupPhasePatternSprite_StoreCommonFields
                bclr    #4,$E(a5)
Enemy_SetupPhasePatternSprite_StoreCommonFields:        ; was: loc_2CFAA
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.b  #5,$23(a5)
                move.l  #$E020E818,$2C(a5)
                move.l  #$E020E818,$28(a5)
                lea     Enemy_PhasePatternSetupFieldBytes(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_SetupPhasePatternSprite
; ---------------------------------------------------------------------------
Enemy_PhasePatternSetupFieldBytes:  dc.w    $1864, $1100  ; was: word_2CFEC

; Applies a nonzero field-$5C animation selector and resets its frame counter
Enemy_ApplyPhasePatternAnimationSelector:               ; was: sub_2CFF0
                move.w  $5C(a5),d0
                beq.s   Enemy_ApplyPhasePatternAnimationSelector_Return
                subq.w  #4,d0
                move.l  Enemy_PhasePatternAnimationBySelector(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_ApplyPhasePatternAnimationSelector_Return:        ; was: locret_2D002
                rts
; End of function Enemy_ApplyPhasePatternAnimationSelector
; ---------------------------------------------------------------------------
Enemy_PhasePatternAnimationBySelector:  dc.l    Enemy_PhasePatternSelector04Animation  ; was: off_2D004
                dc.l    Enemy_PhasePatternSelector08Animation
                dc.l    Enemy_PhasePatternSelector0CAnimation
                dc.l    Enemy_PhasePatternSelector10Animation
                dc.l    Enemy_PhasePatternSelector14Animation
                dc.l    Enemy_PhasePatternSelector18Animation
                dc.l    Enemy_PhasePatternSelector1CAnimation
