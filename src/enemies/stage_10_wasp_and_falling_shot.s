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
; Initializes Stage 10 wasp enemy sprite
Enemy_Stage10WaspInit:                                  ; was: sub_2E048
                move.w  #$EF00,2(a5)
                move.w  (Stage10WaspTileAttr).w,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.l  #$FC04FC04,$2C(a5)
                move.l  #$F010F010,$28(a5)
                lea     Enemy_Stage10WaspSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_Stage10WaspInit
; ---------------------------------------------------------------------------
Enemy_Stage10WaspSpriteParameters:  dc.w    $1806, $1100  ; was: word_2E096

; Selects the Stage 10 wasp animation mapping for the current state
Enemy_UpdateStage10WaspAnimation:                       ; was: sub_2E09A
                move.w  $5C(a5),d0
                beq.s   Enemy_UpdateStage10WaspAnimation_Return
                subq.w  #4,d0
                move.l  Enemy_Stage10WaspAnimationMappings(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_UpdateStage10WaspAnimation_Return:                ; was: locret_2E0AC
                rts
; End of function Enemy_UpdateStage10WaspAnimation
; ---------------------------------------------------------------------------
Enemy_Stage10WaspAnimationMappings: dc.l    Enemy_Stage10WaspSelector04Animation  ; was: off_2E0AE
                dc.l    Enemy_Stage10WaspSelector08Animation
                dc.l    Enemy_Stage10WaspSelector0CAnimation
                dc.l    Enemy_Stage10WaspSelector10Animation

; Updates the Stage 10 wasp state machine or converts it to defeat debris
Enemy_Stage10WaspController:                            ; was: sub_2E0BE
                tst.w   4(a5)
                beq.s   Enemy_Stage10WaspController_DispatchAndRender
                tst.w   $24(a5)
                bmi.w   Enemy_ConvertStage10WaspToDefeatDebris
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ConvertStage10WaspToDefeatDebris
                bclr    #7,$22(a5)
                beq.s   Enemy_Stage10WaspController_UpdateState
                btst    #4,$22(a5)
                bne.w   Enemy_ConvertStage10WaspToDefeatDebris
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                clr.w   $C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Enemy_Stage10WaspController_UpdateState:                ; was: loc_2E10A
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Dispatches the wasp state, animation, and horizontal facing
Enemy_Stage10WaspController_DispatchAndRender:          ; was: loc_2E114
                bsr.s   Enemy_DispatchStage10WaspState
                bsr.w   Enemy_UpdateStage10WaspAnimation
                bra.w   Enemy_UpdateHorizontalFlipFromVelocity
; End of function Enemy_Stage10WaspController
; Dispatches the Stage 10 wasp's current state
Enemy_DispatchStage10WaspState:                         ; was: sub_2E11E
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_Stage10WaspStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchStage10WaspState
; ---------------------------------------------------------------------------
Enemy_Stage10WaspStateOffsets:  dc.w    Enemy_Stage10WaspInitState-*  ; was: off_2E12E
                dc.w    Enemy_Stage10WaspFlightState-*
                dc.w    Enemy_Stage10WaspWaitState-*
                dc.w    Enemy_Stage10WaspPrepareAttackState-*
                dc.w    Enemy_Stage10WaspDiveAttackState-*
                dc.w    Enemy_Stage10WaspCooldownState-*

; Initializes the wasp at the configured screen edge
Enemy_Stage10WaspInitState:                             ; was: sub_2E13A
                moveq   #0,d0
                bsr.w   Enemy_Stage10WaspInit
                move.w  #$C,$5C(a5)
                addq.w  #2,4(a5)
                move.w  #3,$4A(a5)
                move.w  #3,$4C(a5)
                btst    #0,$5F(a5)
                bne.s   Enemy_Stage10WaspInitState_PlaceAtLeftEdge
                move.w  #$1E0,$10(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_Stage10WaspInitState_PlaceAtLeftEdge:             ; was: loc_2E166
                move.w  #$70,$10(a5)                    ; 'p'
                rts
; End of function Enemy_Stage10WaspInitState
; Updates terrain-aware wasp flight and gravity
Enemy_Stage10WaspFlightState:                           ; was: sub_2E16E
                jsr     (Physics_EntityWallCheck).l
                btst    #7,$1C(a5)
                bne.s   Enemy_Stage10WaspFlightState_ApplyGravity
                jsr     (Physics_CheckLowerTerrain).l
                btst    #0,6(a5)
                bne.s   Enemy_Stage10WaspFlightState_BeginWait
Enemy_Stage10WaspFlightState_ApplyGravity:              ; was: loc_2E18A
                jsr     (Physics_CheckUpperTerrainWhenRising).l
                addi.l  #$4000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
; Transitions wasp to waiting state with hover configuration
Enemy_Stage10WaspFlightState_BeginWait:                 ; was: loc_2E19A
                clr.l   $18(a5)
                move.w  #$10,$5C(a5)
                move.w  #$A,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage10WaspFlightState
; Waits between flight and attack phases
Enemy_Stage10WaspWaitState:                             ; was: sub_2E1B0
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage10WaspWaitState_Return
                tst.w   $4C(a5)
                beq.s   Enemy_Stage10WaspWaitState_Advance
                subq.w  #1,$4A(a5)
                beq.s   Enemy_Stage10WaspWaitState_BeginCooldown
Enemy_Stage10WaspWaitState_Advance:                     ; was: loc_2E1C2
                addq.w  #2,4(a5)
Enemy_Stage10WaspWaitState_Return:                      ; was: locret_2E1C6
                rts
; ---------------------------------------------------------------------------
Enemy_Stage10WaspWaitState_BeginCooldown:               ; was: loc_2E1C8
                move.w  #4,$5C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #6,4(a5)
                rts
; End of function Enemy_Stage10WaspWaitState
; Selects the attack animation and starts its delay
Enemy_Stage10WaspPrepareAttackState:                    ; was: sub_2E1DA
                move.w  #8,$5C(a5)
                move.w  #$A,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage10WaspPrepareAttackState
; Launches a dive toward the player's horizontal side
Enemy_Stage10WaspDiveAttackState:                       ; was: sub_2E1EC
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage10WaspDiveAttackState_Return
                subq.w  #6,4(a5)
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Enemy_Stage10WaspDiveAttackState_MoveRight
                move.l  #$FFFE0000,$18(a5)
                bra.s   Enemy_Stage10WaspDiveAttackState_Launch
; ---------------------------------------------------------------------------
Enemy_Stage10WaspDiveAttackState_MoveRight:             ; was: loc_2E20A
                move.l  #$20000,$18(a5)
Enemy_Stage10WaspDiveAttackState_Launch:                ; was: loc_2E212
                move.w  #$C,$5C(a5)
                move.l  #$FFFA0000,$1C(a5)
                tst.w   $4C(a5)
                bne.s   Enemy_Stage10WaspDiveAttackState_Return
                neg.l   $18(a5)
Enemy_Stage10WaspDiveAttackState_Return:                ; was: locret_2E22A
                                        ; Enemy_Stage10WaspDiveAttackState+38   j
                rts
; End of function Enemy_Stage10WaspDiveAttackState
; Spends one outer attack loop, rearms the inner counter, and re-enters the attack
Enemy_Stage10WaspCooldownState:                         ; was: sub_2E22C
                subq.w  #1,$48(a5)
                bpl.s   Enemy_Stage10WaspCooldownState_Return
                subq.w  #1,$4C(a5)
                move.w  #3,$4A(a5)
                subq.w  #4,4(a5)
Enemy_Stage10WaspCooldownState_Return:                  ; was: locret_2E240
                rts
; End of function Enemy_Stage10WaspCooldownState
; Converts the defeated wasp to its type-$2C4 falling debris object
Enemy_ConvertStage10WaspToDefeatDebris:                 ; was: sub_2E242
                                        ; Enemy_Stage10WaspController+12   j
                move.w  #$2C4,(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.l  #Enemy_Stage10WaspSelector0CAnimation,8(a5)
                clr.w   $C(a5)
                move.w  #$10,$48(a5)
                move.l  #$FFFB2000,$1C(a5)
                move.l  #$FFFEA000,$18(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_ConvertStage10WaspToDefeatDebris_Return
                neg.l   $18(a5)
Enemy_ConvertStage10WaspToDefeatDebris_Return:          ; was: locret_2E280
                rts
; End of function Enemy_ConvertStage10WaspToDefeatDebris
; Updates falling wasp debris, then creates an explosion and pickup
Enemy_UpdateStage10WaspDefeatDebris:                    ; was: sub_2E282
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateStage10WaspDefeatDebris_Blink
                jsr     (Effect_SpawnExplosionA).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Enemy_UpdateStage10WaspDefeatDebris_Blink:              ; was: loc_2E2A8
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_UpdateStage10WaspDefeatDebris_Return
                bclr    #7,2(a5)
Enemy_UpdateStage10WaspDefeatDebris_Return:             ; was: locret_2E2BC
                rts
; End of function Enemy_UpdateStage10WaspDefeatDebris
