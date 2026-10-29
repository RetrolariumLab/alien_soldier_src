; Dispatches the generic falling shot's initialization and active states
Projectile_FallingShotController:                       ; was: sub_2DF7E
                move.w  4(a5),d0
                lea     Projectile_FallingShotStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_FallingShotController
; ---------------------------------------------------------------------------
Projectile_FallingShotStateOffsets: dc.w    Projectile_FallingShotInit-*  ; was: off_2DF8A
                dc.w    Projectile_FallingShotUpdate-*

; Initializes a falling shot's display, collision, and lifetime fields
Projectile_FallingShotInit:                             ; was: sub_2DF8E
                move.w  #$8F00,2(a5)
                move.w  #$44C8,$E(a5)
                move.w  #$500,8(a5)
                move.w  #$F8F8,$A(a5)
                move.b  #$80,$21(a5)
                move.b  #$80,$23(a5)
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F808F808,$28(a5)
                addq.w  #2,4(a5)
                cmpi.w  #$1B8,(Entity57Type).w
                bne.s   Projectile_FallingShotUpdate
                ori.w   #$8000,$E(a5)
; Applies gravity and stops the shot on terrain, collision flags, or special-stage bounds
Projectile_FallingShotUpdate:                           ; was: loc_2DFD4
                addi.l  #$2000,$1C(a5)
                bclr    #6,$22(a5)
                bne.s   Projectile_FallingShotUpdate_StopOnImpact
                bclr    #7,$22(a5)
                bne.s   Projectile_FallingShotUpdate_StopOnImpact
                cmpi.w  #$1B8,(Entity57Type).w
                bne.s   Projectile_FallingShotUpdate_CheckTerrain
                move.w  (Entity57YPos).w,d0
                subq.w  #8,d0
                cmp.w   $14(a5),d0
                bhi.s   Projectile_FallingShotUpdate_CheckSpecialBounds
                move.w  (Entity57XPos).w,d0
                cmp.w   $10(a5),d0
                bhi.s   Projectile_FallingShotUpdate_CheckSpecialBounds
                move.w  (Entity57XPos).w,d0
                addi.w  #$100,d0
                cmp.w   $10(a5),d0
                bcc.s   Projectile_FallingShotUpdate_StopOnImpact
Projectile_FallingShotUpdate_CheckSpecialBounds:        ; was: loc_2E018
                                        ; Projectile_FallingShotInit+7A   j
                cmpi.w  #$150,$14(a5)
                blt.s   Projectile_FallingShotUpdate_Return
                bra.w   Enemy_ConvertStage12FallingObjectToEffect
; ---------------------------------------------------------------------------
Projectile_FallingShotUpdate_CheckTerrain:              ; was: loc_2E024
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Collision_InitBufferPointers).l
                move.w  d2,d2
                beq.s   Projectile_FallingShotUpdate_Return
Projectile_FallingShotUpdate_StopOnImpact:              ; was: loc_2E032
                                        ; Projectile_FallingShotInit+5C   j
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #$C8,$26(a5)
                jmp     Effect_InitSharedExplosionFromCurrent
; ---------------------------------------------------------------------------
Projectile_FallingShotUpdate_Return:                    ; was: locret_2E046
                                        ; Projectile_FallingShotInit+A2   j
                rts
; End of function Projectile_FallingShotUpdate
; Initializes beak walker enemy sprite
Enemy_BeakWalkerInit:                                   ; was: sub_2E048
                move.w  #$EF00,2(a5)
                move.w  (BeakWalkerTileAttr).w,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.l  #$FC04FC04,$2C(a5)
                move.l  #$F010F010,$28(a5)
                lea     Enemy_BeakWalkerSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_BeakWalkerInit
; ---------------------------------------------------------------------------
Enemy_BeakWalkerSpriteParameters:   dc.w    $1806, $1100  ; was: word_2E096

; Selects the beak walker animation mapping for the current state
Enemy_UpdateBeakWalkerAnimation:                        ; was: sub_2E09A
                move.w  $5C(a5),d0
                beq.s   Enemy_UpdateBeakWalkerAnimation_Return
                subq.w  #4,d0
                move.l  Enemy_BeakWalkerAnimationMappings(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_UpdateBeakWalkerAnimation_Return:                 ; was: locret_2E0AC
                rts
; End of function Enemy_UpdateBeakWalkerAnimation
; ---------------------------------------------------------------------------
Enemy_BeakWalkerAnimationMappings:  dc.l    Enemy_BeakWalkerSelector04Animation  ; was: off_2E0AE
                dc.l    Enemy_BeakWalkerSelector08Animation
                dc.l    Enemy_BeakWalkerSelector0CAnimation
                dc.l    Enemy_BeakWalkerSelector10Animation

; Updates the beak walker state machine or converts it to defeat debris
Enemy_BeakWalkerController:                             ; was: sub_2E0BE
                tst.w   4(a5)
                beq.s   Enemy_BeakWalkerController_DispatchAndRender
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertBeakWalkerToDefeatDebris
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertBeakWalkerToDefeatDebris
                bclr    #7,$22(a5)
                beq.s   Enemy_BeakWalkerController_UpdateState
                btst    #4,$22(a5)
                bne.w   Enemy_ConvertBeakWalkerToDefeatDebris
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #Effect_SpriteAnimation00,8(a5)
                clr.w   $C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Enemy_BeakWalkerController_UpdateState:                 ; was: loc_2E10A
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Dispatches the beak walker state, animation, and horizontal facing
Enemy_BeakWalkerController_DispatchAndRender:           ; was: loc_2E114
                bsr.s   Enemy_DispatchBeakWalkerState
                bsr.w   Enemy_UpdateBeakWalkerAnimation
                bra.w   Enemy_UpdateHorizontalFlipFromVelocity
; End of function Enemy_BeakWalkerController
; Dispatches the beak walker's current state
Enemy_DispatchBeakWalkerState:                          ; was: sub_2E11E
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_BeakWalkerStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchBeakWalkerState
; ---------------------------------------------------------------------------
Enemy_BeakWalkerStateOffsets:   dc.w    Enemy_BeakWalkerInitState-*  ; was: off_2E12E
                dc.w    Enemy_BeakWalkerFlightState-*
                dc.w    Enemy_BeakWalkerWaitState-*
                dc.w    Enemy_BeakWalkerPrepareAttackState-*
                dc.w    Enemy_BeakWalkerDiveAttackState-*
                dc.w    Enemy_BeakWalkerCooldownState-*

; Initializes the beak walker at the configured screen edge
Enemy_BeakWalkerInitState:                              ; was: sub_2E13A
                moveq   #0,d0
                bsr.w   Enemy_BeakWalkerInit
                move.w  #$C,$5C(a5)
                addq.w  #2,4(a5)
                move.w  #3,$4A(a5)
                move.w  #3,$4C(a5)
                btst    #0,$5F(a5)
                bne.s   Enemy_BeakWalkerInitState_PlaceAtLeftEdge
                move.w  #$1E0,$10(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_BeakWalkerInitState_PlaceAtLeftEdge:              ; was: loc_2E166
                move.w  #$70,$10(a5)                    ; 'p'
                rts
; End of function Enemy_BeakWalkerInitState
; Updates terrain-aware beak walker flight and gravity
Enemy_BeakWalkerFlightState:                            ; was: sub_2E16E
                jsr     (Physics_EntityWallCheck).l
                btst    #7,$1C(a5)
                bne.s   Enemy_BeakWalkerFlightState_ApplyGravity
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                bne.s   Enemy_BeakWalkerFlightState_BeginWait
Enemy_BeakWalkerFlightState_ApplyGravity:               ; was: loc_2E18A
                jsr     (Physics_CheckUpperTerrainWhenRising).l
                addi.l  #$4000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
; Transitions beak walker to waiting state with hover configuration
Enemy_BeakWalkerFlightState_BeginWait:                  ; was: loc_2E19A
                clr.l   $18(a5)
                move.w  #$10,$5C(a5)
                move.w  #$A,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_BeakWalkerFlightState
; Waits between flight and attack phases
Enemy_BeakWalkerWaitState:                              ; was: sub_2E1B0
                subq.w  #1,$48(a5)
                bne.s   Enemy_BeakWalkerWaitState_Return
                tst.w   $4C(a5)
                beq.s   Enemy_BeakWalkerWaitState_Advance
                subq.w  #1,$4A(a5)
                beq.s   Enemy_BeakWalkerWaitState_BeginCooldown
Enemy_BeakWalkerWaitState_Advance:                      ; was: loc_2E1C2
                addq.w  #2,4(a5)
Enemy_BeakWalkerWaitState_Return:                       ; was: locret_2E1C6
                rts
; ---------------------------------------------------------------------------
Enemy_BeakWalkerWaitState_BeginCooldown:                ; was: loc_2E1C8
                move.w  #4,$5C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #6,4(a5)
                rts
; End of function Enemy_BeakWalkerWaitState
; Selects the attack animation and starts its delay
Enemy_BeakWalkerPrepareAttackState:                     ; was: sub_2E1DA
                move.w  #8,$5C(a5)
                move.w  #$A,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_BeakWalkerPrepareAttackState
; Launches a dive toward the player's horizontal side
Enemy_BeakWalkerDiveAttackState:                        ; was: sub_2E1EC
                subq.w  #1,$48(a5)
                bne.s   Enemy_BeakWalkerDiveAttackState_Return
                subq.w  #6,4(a5)
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Enemy_BeakWalkerDiveAttackState_MoveRight
                move.l  #$FFFE0000,$18(a5)
                bra.s   Enemy_BeakWalkerDiveAttackState_Launch
; ---------------------------------------------------------------------------
Enemy_BeakWalkerDiveAttackState_MoveRight:              ; was: loc_2E20A
                move.l  #$20000,$18(a5)
Enemy_BeakWalkerDiveAttackState_Launch:                 ; was: loc_2E212
                move.w  #$C,$5C(a5)
                move.l  #$FFFA0000,$1C(a5)
                tst.w   $4C(a5)
                bne.s   Enemy_BeakWalkerDiveAttackState_Return
                neg.l   $18(a5)
Enemy_BeakWalkerDiveAttackState_Return:                 ; was: locret_2E22A
                                        ; Enemy_BeakWalkerDiveAttackState+38   j
                rts
; End of function Enemy_BeakWalkerDiveAttackState
; Spends one outer attack loop, rearms the inner counter, and re-enters the attack
Enemy_BeakWalkerCooldownState:                          ; was: sub_2E22C
                subq.w  #1,$48(a5)
                bpl.s   Enemy_BeakWalkerCooldownState_Return
                subq.w  #1,$4C(a5)
                move.w  #3,$4A(a5)
                subq.w  #4,4(a5)
Enemy_BeakWalkerCooldownState_Return:                   ; was: locret_2E240
                rts
; End of function Enemy_BeakWalkerCooldownState
; Converts the defeated beak walker to its type-$2C4 falling debris object
Enemy_ConvertBeakWalkerToDefeatDebris:                  ; was: sub_2E242
                                        ; Enemy_BeakWalkerController+12   j
                move.w  #$2C4,(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.l  #Enemy_BeakWalkerSelector0CAnimation,8(a5)
                clr.w   $C(a5)
                move.w  #$10,$48(a5)
                move.l  #$FFFB2000,$1C(a5)
                move.l  #$FFFEA000,$18(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_ConvertBeakWalkerToDefeatDebris_Return
                neg.l   $18(a5)
Enemy_ConvertBeakWalkerToDefeatDebris_Return:           ; was: locret_2E280
                rts
; End of function Enemy_ConvertBeakWalkerToDefeatDebris
; Updates falling beak walker debris, then creates an explosion and pickup
Enemy_UpdateBeakWalkerDefeatDebris:                     ; was: sub_2E282
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateBeakWalkerDefeatDebris_Blink
                jsr     (Effect_SpawnExplosionA).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateBeakWalkerDefeatDebris_Blink:               ; was: loc_2E2A8
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_UpdateBeakWalkerDefeatDebris_Return
                bclr    #7,2(a5)
Enemy_UpdateBeakWalkerDefeatDebris_Return:              ; was: locret_2E2BC
                rts
; End of function Enemy_UpdateBeakWalkerDefeatDebris
