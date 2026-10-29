; Valkirie bullets and shared Z-Leo, Wolf Garopa, spawner, and explosion helpers

; Copy the source object's display, position, mapping, lifetime, and phase fields
Projectile_InitValkirieBulletFromSource:                ; was: sub_2A03C
                move.b  $20(a1),d2
                move.w  #$100,d0
                move.w  #$480,(a0)
                move.w  2(a1),d1
                andi.w  #$C080,d1
                or.w    d0,d1
                move.w  d1,2(a0)
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),$14(a0)
                move.w  $E(a1),$E(a0)
                move.b  d2,$20(a0)
                move.w  d3,$48(a0)
                move.w  d4,$4A(a0)
                btst    #6,2(a0)
                bne.s   Projectile_CopyValkiriePackedSizeFields
                move.w  8(a1),8(a0)
                move.w  $A(a1),$A(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_CopyValkiriePackedSizeFields:                ; was: loc_2A08A
                move.l  8(a1),8(a0)
                rts
; End of function Projectile_InitValkirieBulletFromSource
; Expire the Valkirie bullet or blink it against its stored phase
Projectile_UpdateValkirieBullet:                        ; was: sub_2A092
                subq.w  #1,$48(a5)
                bpl.s   Projectile_UpdateValkirieBulletVisibility
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateValkirieBulletVisibility:              ; was: loc_2A0A0
                bset    #7,2(a5)
                move.w  (FrameCounter).w,d0
                andi.w  #1,d0
                move.w  $4A(a5),d1
                eor.w   d0,d1
                bne.s   Projectile_UpdateValkirieBulletReturn
                bclr    #7,2(a5)
Projectile_UpdateValkirieBulletReturn:                  ; was: locret_2A0BC
                rts
; End of function Projectile_UpdateValkirieBullet
; Install the fixed tile, size, and mapping fields used by Z-Leo's falling shot
Projectile_InitZLeoDropGraphics:                        ; was: sub_2A0BE
                move.w  #$C6B4,$E(a0)
                move.w  #$900,8(a0)
                move.w  #$F4F8,$A(a0)
                clr.b   $20(a0)
                rts
; End of function Projectile_InitZLeoDropGraphics
; Allocate and initialize Wolf Garopa's timed type-$424 effect
Projectile_SpawnWolfGaropaType424:                      ; was: sub_2A0D6
                                        ; Boss_WolfGaropaBeginLowerType424Sequence+6   p
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_SpawnWolfGaropaType424Return
                move.w  #$424,(a0)
                move.w  #$C6B4,$E(a0)
                move.w  #$900,8(a0)
                move.w  #$F4F8,$A(a0)
                clr.b   $20(a0)
                move.w  #$40,$48(a0)                    ; '@'
                moveq   #0,d0
Projectile_SpawnWolfGaropaType424Return:                ; was: locret_2A100
                rts
; End of function Projectile_SpawnWolfGaropaType424
; Count down a type-$424 effect and blink from timer bit two
Projectile_UpdateType424Visibility:                     ; was: sub_2A102
                subq.w  #1,$48(a5)
                bpl.s   Projectile_UpdateType424Blink
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateType424Blink:                          ; was: loc_2A110
                bset    #7,2(a5)
                btst    #2,$49(a5)
                beq.s   Projectile_UpdateType424VisibilityReturn
                bclr    #7,2(a5)
Projectile_UpdateType424VisibilityReturn:               ; was: locret_2A124
                rts
; End of function Projectile_UpdateType424Visibility
; Select the Wolf Garopa orb tile and mapping from the global animation phase
Gfx_AnimateWolfGaropaOrb:                               ; was: sub_2A126
                movea.w a5,a0
Gfx_AnimateWolfGaropaOrbAtA0:                           ; was: loc_2A128
                move.w  (FrameCounter).w,d0
                asl.w   #2,d0
                andi.w  #$C,d0
                move.w  WolfGaropa_OrbAnimationFrames(pc,d0.w),$E(a0)
                move.w  WolfGaropa_OrbAnimationFrames+2(pc,d0.w),$A(a0)
                rts
; End of function Gfx_AnimateWolfGaropaOrb
; ---------------------------------------------------------------------------
WolfGaropa_OrbAnimationFrames:  dc.w    $C6FC, $F0F0, $CEFC, $F0, $D6FC, $F000, $DEFC, 0  ; was: word_2A140
                                        ; Gfx_AnimateWolfGaropaOrb+12   r
                dc.w    $30BC, $5C                      ; trailing words not reached by the four-frame index

; Initialize the two-phase directional particle spawner
Projectile_InitDirectionalSpawner:                      ; was: sub_2A154
                move.w  #$10,$48(a0)
                move.w  #$18,$4A(a0)
                move.w  #$8F00,2(a0)
                add.w   $10(a5),d1
                move.w  d1,$10(a0)
                add.w   $14(a5),d2
                move.w  d2,$14(a0)
                ori.w   #$451F,d0
                move.w  d0,$E(a0)
                move.w  #$400,8(a0)
                move.w  #$F8FC,$A(a0)
                btst    #$B,d0
                beq.s   Projectile_SetDirectionalSpawnerNegativeXAcceleration
                move.w  #$6000,$4C(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_SetDirectionalSpawnerNegativeXAcceleration:  ; was: loc_2A198
                move.w  #$A000,$4C(a0)
                rts
; End of function Projectile_InitDirectionalSpawner
; Emit radial particles during the delay, then accelerate and emit a trail
Projectile_UpdateDirectionalSpawner:                    ; was: sub_2A1A0
                tst.b   $48(a5)
                bmi.s   Projectile_UpdateDirectionalSpawnerMotion
                subq.w  #1,$48(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_UpdateDirectionalSpawnerDelayReturn
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Projectile_UpdateDirectionalSpawnerDelayReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_UpdateDirectionalSpawnerDelayReturn
                movea.l #Projectile_SpawnSpriteFrames,a1
                bsr.w   Sprite_InitFromTable
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                movea.l #Math_SineTable,a1
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   #2,d1
                asl.l   #2,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
Projectile_UpdateDirectionalSpawnerDelayReturn:         ; was: locret_2A200
                                        ; Projectile_UpdateDirectionalSpawner+1A   j
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateDirectionalSpawnerMotion:              ; was: loc_2A202
                subq.w  #1,$4A(a5)
                bmi.s   Projectile_SpawnDirectionalSpawnerTrail
                move.w  $4C(a5),d0
                ext.l   d0
                add.l   d0,$18(a5)
                tst.w   (PlayerObjectType).w
                beq.s   Projectile_SpawnDirectionalSpawnerTrail
                move.w  (PlayerYPosition).w,d0
                cmp.w   $14(a5),d0
                bmi.s   Projectile_AccelerateDirectionalSpawnerUpward
                addi.l  #$2000,$1C(a5)
                bra.s   Projectile_SpawnDirectionalSpawnerTrail
; ---------------------------------------------------------------------------
Projectile_AccelerateDirectionalSpawnerUpward:          ; was: loc_2A22C
                subi.l  #$2000,$1C(a5)
Projectile_SpawnDirectionalSpawnerTrail:                ; was: loc_2A234
                                        ; Projectile_UpdateDirectionalSpawner+76   j
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_UpdateDirectionalSpawnerReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_UpdateDirectionalSpawnerReturn
                movea.l #Projectile_SpawnSpriteFrames,a1
                bsr.w   Sprite_InitFromTable
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                btst    #3,$E(a5)
                beq.s   Projectile_SetDirectionalSpawnerTrailRight
                move.w  #$FFFF,$18(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_SetDirectionalSpawnerTrailRight:             ; was: loc_2A26A
                move.w  #1,$18(a0)
Projectile_UpdateDirectionalSpawnerReturn:              ; was: locret_2A270
                                        ; Projectile_UpdateDirectionalSpawner+A2   j
                rts
; End of function Projectile_UpdateDirectionalSpawner
; Apply gravity and fixed-step horizontal drag without clamping at zero
Projectile_UpdateGravityAndHorizontalDrag:              ; was: sub_2A272
                subq.w  #1,$48(a5)
                bpl.s   Projectile_UpdateGravityAndHorizontalDragActive
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateGravityAndHorizontalDragActive:        ; was: loc_2A280
                addi.l  #$4000,$1C(a5)
                tst.w   $18(a5)
                bmi.s   Projectile_DragNegativeHorizontalVelocity
                subi.l  #$2000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_DragNegativeHorizontalVelocity:              ; was: loc_2A298
                addi.l  #$2000,$18(a5)
                rts
; End of function Projectile_UpdateGravityAndHorizontalDrag
; Select the current object as the target of the shared explosion initializer
Effect_InitSharedExplosionFromCurrent:                  ; was: sub_2A2A2
                                        ; Projectile_UpdateTopFallingHazardType108+36   j
                movea.w a5,a0
; Set the target's type, initial velocity, and directional tile attribute
Effect_InitSharedExplosion:                             ; was: loc_2A2A4
                                        ; Boss_LovePenguinUpdateScatteredBodyPart+30   p
                move.w  #$C4,(a0)
                move.l  #$FFFDC000,$1C(a0)
                move.w  #$480,d0
                add.w   (GlobalSpritePriorityBit).w,d0
                btst    #4,$E(a0)
                beq.s   Effect_ConfigureSharedExplosion
                bset    #$C,d0
                neg.l   $1C(a0)
; Finish a prepared target's sprite, counters, shake, and sound
Effect_ConfigureSharedExplosion:                        ; was: loc_2A2C8
                move.w  d0,$E(a0)
                move.w  #$E500,2(a0)
                move.l  #SharedCombatSpriteAnimation01,8(a0)
                clr.w   $C(a0)
                move.b  #$10,$20(a0)
                move.w  #3,$48(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$F010F010,$2C(a0)
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                move.b  #$BC,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Effect_InitSharedExplosionFromCurrent
