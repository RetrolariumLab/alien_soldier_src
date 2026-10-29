; Spawn an orbit-centered star particle while the orb charges
Boss_WolfGaropaSpawnOrbitStar:                          ; was: sub_50B7E
                                        ; Boss_WolfGaropaUpdateBattleStartWait+118   j
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_WolfGaropaOrbitStarReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_WolfGaropaOrbitStarReturn
                lea     (Effect_StarParticleSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.b  #4,$20(a0)
                move.w  #$8C40,2(a0)
                bsr.w   Boss_WolfGaropaCalculateOrbEmitterPosition
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a2,d0.w),d1
                move.w  (a2,d0.w),d2
                ext.l   d1
                ext.l   d2
                move.l  d1,d5
                move.l  d2,d6
                asl.l   #6,d1
                asl.l   #6,d2
                swap    d1
                swap    d2
                add.w   d1,d3
                add.w   d2,d4
                move.w  d3,$14(a0)
                move.w  d4,$10(a0)
                neg.l   d5
                neg.l   d6
                asl.l   #2,d5
                asl.l   #2,d6
                move.l  d5,$1C(a0)
                move.l  d6,$18(a0)
Boss_WolfGaropaOrbitStarReturn:                         ; was: locret_50BEA
                                        ; Boss_WolfGaropaSpawnOrbitStar+10   j
                rts
; End of function Boss_WolfGaropaSpawnOrbitStar
; Spawn a smaller randomized spark at the orbit emitter
Boss_WolfGaropaSpawnOrbitSpark:                         ; was: sub_50BEC
                tst.w   $5FC(a5)
                bmi.w   Boss_WolfGaropaOrbitSparkReturn
                subq.w  #1,$5FC(a5)
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_WolfGaropaOrbitSparkReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_WolfGaropaOrbitSparkReturn
                lea     (Boss_ViblackAndWolfGaropaShotSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.b  #4,$20(a0)
                move.w  #$8C00,2(a0)
                bsr.w   Boss_WolfGaropaCalculateOrbEmitterPosition
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                subq.w  #4,d0
                add.w   d0,d3
                move.b  (RandomNumberState+1).w,d0
                andi.w  #7,d0
                subq.w  #4,d0
                add.w   d0,d4
                move.w  d3,$14(a0)
                move.w  d4,$10(a0)
                asl.l   #2,d5
                asl.l   #2,d6
                move.l  d5,$1C(a0)
                subi.l  #$30000,d6
                move.l  d6,$18(a0)
Boss_WolfGaropaOrbitSparkReturn:                        ; was: locret_50C5A
                                        ; Boss_WolfGaropaSpawnOrbitSpark+12   j
                rts
; End of function Boss_WolfGaropaSpawnOrbitSpark
; Calculate the current orbit-emitter position and radial vector
Boss_WolfGaropaCalculateOrbEmitterPosition:             ; was: sub_50C5C
                                        ; Boss_WolfGaropaSpawnOrbitSpark+38   p
                lea     (Math_SineTable).l,a2
                move.w  $A76(a5),d0
                move.w  -$80(a2,d0.w),d3
                move.w  (a2,d0.w),d4
                ext.l   d3
                ext.l   d4
                move.l  d3,d5
                move.l  d4,d6
                asl.l   #7,d3
                asl.l   #7,d4
                swap    d3
                swap    d4
                add.w   $A34(a5),d3
                add.w   $A30(a5),d4
                rts
; End of function Boss_WolfGaropaCalculateOrbEmitterPosition
; Spawn a type-$188 explosion effect at the auxiliary orb position
Boss_WolfGaropaSpawnOrbExplosion:                       ; was: sub_50C88
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_WolfGaropaOrbExplosionReturn
                move.l  #Effect_SpriteAnimation07,8(a0)
                jsr     (Effect_SpawnExplosionType188).l
                move.b  #4,$20(a0)
                move.w  #$EC00,2(a0)
                move.w  #$FFFE,$18(a0)
                move.w  #$FFFE,$1C(a0)
                move.w  #$10,$48(a0)
                move.w  $A30(a5),d0
                move.w  $A34(a5),d1
                subq.w  #8,d0
                addq.w  #8,d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_WolfGaropaOrbExplosionReturn:                      ; was: locret_50CD2
                rts
; End of function Boss_WolfGaropaSpawnOrbExplosion
; Initializes pair of screen objects for Valkirie boss with different parameters based on direction flag
