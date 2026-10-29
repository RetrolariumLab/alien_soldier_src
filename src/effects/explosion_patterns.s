; Spawns eight radial explosion particles with the common mapping
Effect_SpawnEightWayExplosionParticles:                 ; was: sub_2BE56
                                        ; Boss_Stage3OrbitingFormationCheckDefeat+86   p
                move.w  #3,d0
                movea.l #Effect_SpriteAnimation00,a1
; End of function Effect_SpawnEightWayExplosionParticles
; Spawns a power-of-two radial particle pattern
Effect_SpawnRadialParticlePattern:                      ; was: sub_2BE60
                                        ; Effect_ExplosionB_SpawnThreeRings+3C   p
                move.w  #1,d7
                lsl.w   d0,d7
                subq.w  #1,d7
                move.w  #$1FF,d6
                lsr.w   d0,d6
                andi.w  #$1FE,d6
Effect_SpawnRadialParticlePattern_Loop:                 ; was: loc_2BE72
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Effect_SpawnRadialParticlePattern_Next
                andi.w  #$1FE,d2
                lea     (Math_SineTable).l,a2
                move.w  (a2,d2.w),d4
                move.w  -$80(a2,d2.w),d5
                ext.l   d4
                ext.l   d5
                asl.l   d1,d4
                asl.l   d1,d5
                move.l  d4,$18(a0)
                move.l  d5,$1C(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.l  a1,8(a0)
                jsr     (Sprite_InitType160).l
                add.w   d6,d2
Effect_SpawnRadialParticlePattern_Next:                 ; was: loc_2BEB6
                dbf     d7,Effect_SpawnRadialParticlePattern_Loop
                rts
; End of function Effect_SpawnRadialParticlePattern
; Creates explosion variant A and plays its sound
Effect_SpawnExplosionA:                                 ; was: sub_2BEBC
                                        ; Enemy_UpdateAlternateDefeatProjectile+E   p
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Effect_ExplosionUpdateReturn
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.w  #$1A0,(a0)
                move.w  #6,$4A(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                move.w  d0,$4C(a0)
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.s   Effect_InitializeExplosion
; End of function Effect_SpawnExplosionA
; Creates explosion variant B and plays its sound
Effect_SpawnExplosionB:                                 ; was: sub_2BEF0
                                        ; Enemy_UpdateBouncingDebrisSpawner+9A   p
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Effect_ExplosionUpdateReturn
                move.w  #8,$4A(a0)
                move.w  #$1A4,(a0)
                move.l  #Effect_SpriteAnimation01,8(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                move.w  d0,$4C(a0)
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
; Initializes an explosion at the current object's position
Effect_InitializeExplosion:                             ; was: loc_2BF22
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                move.w  #$ED40,2(a0)
                move.w  #$480,$E(a0)
                clr.w   $C(a0)
                move.w  (GlobalSpritePriorityBit).w,d0
                or.w    d0,$E(a0)
                clr.b   $21(a0)
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                rts
; End of function Effect_SpawnExplosionB
; Updates explosion variant A, including lifetime and motion pattern
Effect_UpdateExplosionA:                                ; was: sub_2BF58
                cmpi.w  #$80,$C(a5)
                bcc.w   Effect_RemoveExplosionObject
                cmpi.w  #$80,$10(a5)
                bcs.w   Effect_RemoveExplosionObject
                cmpi.w  #$1C0,$10(a5)
                bhi.w   Effect_RemoveExplosionObject
                cmpi.w  #$80,$14(a5)
                bcs.w   Effect_RemoveExplosionObject
                cmpi.w  #$160,$14(a5)
                bhi.w   Effect_RemoveExplosionObject
                bsr.w   Effect_ExplosionA_LifetimeDispatcher
                move.w  $4C(a5),d0
                add.w   d0,d0
                move.w  d0,d0
                lea     Effect_ExplosionAVariantHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_UpdateExplosionA
; ---------------------------------------------------------------------------
Effect_ExplosionAVariantHandlers:   dc.w    Effect_ExplosionA_UpdateVerticalMotion-*  ; was: off_2BF9E
                dc.w    Effect_ExplosionA_ArcDispatcher-*
                dc.w    Effect_ExplosionA_SpiralDispatcher-*
                dc.w    Effect_ExplosionA_SpiralDispatcher-*

; Applies the vertical-motion variant selected for explosion A
Effect_ExplosionA_UpdateVerticalMotion:                 ; was: sub_2BFA6
                tst.w   $4E(a5)
                bne.s   Effect_ExplosionA_ApplyUpwardAcceleration
                move.l  #$FFFC0000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Effect_ExplosionA_ApplyUpwardAcceleration:              ; was: loc_2BFB6
                subi.l  #$4000,$1C(a5)
                rts
; End of function Effect_ExplosionA_UpdateVerticalMotion
; Dispatches the two-state arc motion used by explosion A
Effect_ExplosionA_ArcDispatcher:                        ; was: sub_2BFC0
                move.w  $4E(a5),d0
                lea     Effect_ExplosionAArcHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_ExplosionA_ArcDispatcher
; ---------------------------------------------------------------------------
Effect_ExplosionAArcHandlers:   dc.w    Effect_ExplosionA_InitAwayFromPlayer-*  ; was: off_2BFCC
                dc.w    Effect_ExplosionA_ApplyGravity-*

; Initializes horizontal motion away from the player and upward velocity
Effect_ExplosionA_InitAwayFromPlayer:                   ; was: sub_2BFD0
                jsr     (Math_CalculateAngleToPlayer).l
                addi.w  #$100,d2
                andi.w  #$1FE,d2
                lea     (Math_SineTable).l,a1
                move.w  (a1,d2.w),d0
                ext.l   d0
                asl.l   #4,d0
                move.l  d0,$18(a5)
                move.l  #$FFFE0000,$1C(a5)
                addq.w  #2,$4E(a5)
                rts
; End of function Effect_ExplosionA_InitAwayFromPlayer
; Applies positive gravity acceleration to vertical velocity
Effect_ExplosionA_ApplyGravity:                         ; was: sub_2BFFE
                addi.l  #$4000,$1C(a5)
                rts
; End of function Effect_ExplosionA_ApplyGravity
; Dispatches the three-state spiral motion used by explosion A
Effect_ExplosionA_SpiralDispatcher:                     ; was: sub_2C008
                                        ; ROM:0002BFA4   o
                move.w  $4E(a5),d0
                lea     Effect_ExplosionASpiralHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_ExplosionA_SpiralDispatcher
; ---------------------------------------------------------------------------
Effect_ExplosionASpiralHandlers:    dc.w    Effect_ExplosionA_InitRandomSpiral-*  ; was: off_2C014
                dc.w    Effect_ExplosionA_SetSpiralVelocity-*
                dc.w    Effect_ExplosionA_UpdateSpiral-*

; Seeds the spiral angle from the random state
Effect_ExplosionA_InitRandomSpiral:                     ; was: sub_2C01A
                move.w  (RandomNumberState).w,$5E(a5)
                addq.w  #2,$4E(a5)
; Converts the current spiral angle into velocity
Effect_ExplosionA_SetSpiralVelocity:                    ; was: loc_2C024
                andi.w  #$1FE,$5E(a5)
                move.w  $5E(a5),d2
                lea     (Math_SineTable).l,a1
                move.w  (a1,d2.w),d0
                move.w  -$80(a1,d2.w),d1
                ext.l   d0
                asl.l   #4,d0
                ext.l   d1
                asl.l   #4,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                move.w  #4,$5A(a5)
                addq.w  #2,$4E(a5)
                rts
; End of function Effect_ExplosionA_InitRandomSpiral
; Advances the explosion particle's spiral motion
Effect_ExplosionA_UpdateSpiral:                         ; was: sub_2C058
                subq.w  #1,$5A(a5)
                bne.w   Effect_ExplosionUpdateReturn
                cmpi.w  #3,$4C(a5)
                beq.s   Effect_ExplosionA_RestartSpiral
                addi.w  #-$40,$5E(a5)
                subq.w  #2,$4E(a5)
                rts
; ---------------------------------------------------------------------------
; Restarts the spiral state sequence
Effect_ExplosionA_RestartSpiral:                        ; was: loc_2C074
                clr.w   $4E(a5)
                rts
; End of function Effect_ExplosionA_UpdateSpiral
; Dispatches explosion A's particle-spawn lifetime states
Effect_ExplosionA_LifetimeDispatcher:                   ; was: sub_2C07A
                move.w  4(a5),d0
                lea     Effect_ExplosionALifetimeHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_ExplosionA_LifetimeDispatcher
; ---------------------------------------------------------------------------
Effect_ExplosionALifetimeHandlers:  dc.w    Effect_ExplosionA_SpawnParticle-*  ; was: off_2C086
                dc.w    Effect_ExplosionA_UpdateParticleTimer-*
                dc.w    Effect_RemoveExplosionObject-*

; Spawns one explosion particle at the parent position
Effect_ExplosionA_SpawnParticle:                        ; was: sub_2C08C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Effect_ExplosionUpdateReturn
                move.l  #Effect_SpriteAnimation01,8(a0)
                jsr     (Sprite_InitType160).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #4,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionA_SpawnParticle
; Counts particles and repeats or finishes the spawn loop
Effect_ExplosionA_UpdateParticleTimer:                  ; was: sub_2C0BC
                subq.w  #1,$48(a5)
                bne.w   Effect_ExplosionUpdateReturn
                subq.w  #1,$4A(a5)
                beq.s   Effect_ExplosionA_FinishParticleLoop
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Effect_ExplosionA_FinishParticleLoop:                   ; was: loc_2C0D0
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionA_UpdateParticleTimer
; Marks an explosion controller inactive
Effect_RemoveExplosionObject:                           ; was: sub_2C0D6
                                        ; Effect_UpdateExplosionA+10   j
                bset    #4,2(a5)
                rts
; End of function Effect_RemoveExplosionObject
; Updates explosion variant B using its randomly selected pattern
Effect_UpdateExplosionB:                                ; was: sub_2C0DE
                cmpi.w  #$80,$C(a5)
                bcc.w   Effect_RemoveExplosionObject
                move.w  $4C(a5),d0
                add.w   d0,d0
                move.w  d0,d0
                lea     Effect_ExplosionBVariantHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_UpdateExplosionB
; ---------------------------------------------------------------------------
Effect_ExplosionBVariantHandlers:   dc.w    Effect_ExplosionB_ParticleLoopDispatcher-*  ; was: off_2C0F8
                dc.w    Effect_ExplosionB_SpawnThreeRings-*
                dc.w    Effect_ExplosionB_SpawnTwoRings-*
                dc.w    Effect_ExplosionB_SpawnSingleRing-*

; Dispatches the repeating particle loop for explosion variant B
Effect_ExplosionB_ParticleLoopDispatcher:               ; was: sub_2C100
                move.w  4(a5),d0
                lea     Effect_ExplosionBParticleLoopHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_ExplosionB_ParticleLoopDispatcher
; ---------------------------------------------------------------------------
Effect_ExplosionBParticleLoopHandlers:
                dc.w    Effect_ExplosionB_SpawnRandomParticle-*  ; was: off_2C10C
                dc.w    Effect_ExplosionB_UpdateParticleTimer-*
                dc.w    Effect_RemoveExplosionObject-*

; Spawns one particle at a random offset from the explosion center
Effect_ExplosionB_SpawnRandomParticle:                  ; was: sub_2C112
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Effect_ExplosionUpdateReturn
                move.l  #Effect_SpriteAnimation00,8(a0)
                jsr     (Sprite_InitType160).l
                move.b  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                subi.w  #$20,d0                         ; ' '
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$20,d1                         ; ' '
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  #2,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionB_SpawnRandomParticle
; Counts particles and repeats or finishes the particle loop
Effect_ExplosionB_UpdateParticleTimer:                  ; was: sub_2C15E
                subq.w  #1,$48(a5)
                bne.w   Effect_ExplosionUpdateReturn
                subq.w  #1,$4A(a5)
                bmi.w   Effect_ExplosionB_FinishParticleLoop
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Effect_ExplosionB_FinishParticleLoop:                   ; was: loc_2C174
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionB_UpdateParticleTimer
; Spawns three concentric two-particle rings
Effect_ExplosionB_SpawnThreeRings:                      ; was: sub_2C17A
                tst.w   4(a5)
                bne.w   Effect_ExplosionUpdateReturn
                move.w  (RandomNumberState).w,d2
                andi.w  #$1FE,d2
                move.w  d2,$58(a5)
                move.w  #1,d0
                move.w  #1,d1
                move.w  $58(a5),d2
                movea.l #Effect_SpriteAnimation00,a1
                bsr.w   Effect_SpawnRadialParticlePattern
                move.w  #1,d0
                move.w  #3,d1
                move.w  $58(a5),d2
                movea.l #Effect_SpriteAnimation00,a1
                bsr.w   Effect_SpawnRadialParticlePattern
                move.w  #1,d0
                move.w  #5,d1
                move.w  $58(a5),d2
                movea.l #Effect_SpriteAnimation00,a1
                bsr.w   Effect_SpawnRadialParticlePattern
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionB_SpawnThreeRings
; Spawns two concentric four-particle rings
Effect_ExplosionB_SpawnTwoRings:                        ; was: sub_2C1D6
                tst.w   4(a5)
                bne.w   Effect_ExplosionUpdateReturn
                move.w  (RandomNumberState).w,d2
                andi.w  #$1FE,d2
                move.w  d2,$58(a5)
                move.w  #2,d0
                move.w  #3,d1
                move.w  $58(a5),d2
                movea.l #Effect_SpriteAnimation00,a1
                bsr.w   Effect_SpawnRadialParticlePattern
                move.w  #2,d0
                move.w  #5,d1
                move.w  $58(a5),d2
                addi.w  #$40,d2                         ; '@'
                andi.w  #$1FE,d2
                movea.l #Effect_SpriteAnimation00,a1
                bsr.w   Effect_SpawnRadialParticlePattern
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionB_SpawnTwoRings
; Spawns one eight-particle ring
Effect_ExplosionB_SpawnSingleRing:                      ; was: sub_2C224
                tst.w   4(a5)
                bne.w   Effect_ExplosionUpdateReturn
                move.w  (RandomNumberState).w,d2
                andi.w  #$1FE,d2
                move.w  d2,$58(a5)
                move.w  #3,d0
                move.w  #4,d1
                move.w  $58(a5),d2
                movea.l #Effect_SpriteAnimation00,a1
                bsr.w   Effect_SpawnRadialParticlePattern
                addq.w  #2,4(a5)
                rts
; End of function Effect_ExplosionB_SpawnSingleRing
