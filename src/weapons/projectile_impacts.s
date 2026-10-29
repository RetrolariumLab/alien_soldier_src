Weapon_UpdateRotatingProjectile:                        ; was: sub_18A66
                move.w  $48(a5),d0
                addq.w  #2,d0
                andi.w  #$E,d0
                move.w  d0,$48(a5)
                movea.l $4A(a5),a0
                move.w  (a0,d0.w),d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                move.w  $10(a0,d0.w),8(a5)
                move.w  $20(a0,d0.w),$A(a5)
                cmpi.w  #$80,$10(a5)
                bmi.w   Object_MarkInactive
                cmpi.w  #$1C0,$10(a5)
                bpl.w   Object_MarkInactive
                cmpi.w  #$A0,$14(a5)
                bmi.w   Object_MarkInactive
                cmpi.w  #$160,$14(a5)
                bpl.w   Object_MarkInactive
                btst    #0,(PlayerModeFlags).w
                bne.s   Weapon_UpdateRotatingProjectile_Return
                addi.l  #$4000,$1C(a5)
Weapon_UpdateRotatingProjectile_Return:                 ; was: locret_18AC8
                rts
; End of function Weapon_UpdateRotatingProjectile
; Handles projectile collision
Weapon_HandleProjectileHit:                             ; was: sub_18ACA
                bclr    #7,$22(a5)
                bne.s   Weapon_HandleProjectileHit_InitImpact
                bclr    #6,$23(a5)
                beq.s   Weapon_TickLifetimeTimer
                bclr    #4,$23(a5)
                bne.s   Weapon_HandleProjectileHit_InitBurst
Weapon_HandleProjectileHit_InitImpact:                  ; was: loc_18AE2
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (Weapon_ImpactSpriteFrames).l,a1
                jmp     Sprite_InitTypeA4FromCurrentTable
; ---------------------------------------------------------------------------
Weapon_HandleProjectileHit_InitBurst:                   ; was: loc_18AF6
                move.w  #$44D6,d0
                add.w   (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a5)
                move.w  #$A00,8(a5)
                move.w  #$F4F4,$A(a5)
                move.l  #Weapon_HomingEffectSpriteData,$4A(a5)
                bra.w   Effect_InitSharedImpactMotion
; End of function Weapon_HandleProjectileHit
; Attributes: thunk
; Unreachable: a thunk to Sprite_InitTypeA4FromCurrentTable with no reference of any kind
Orphaned_EffectInitImpactObjectFromCurrent:
                jmp     Sprite_InitTypeA4FromCurrentTable  ; was: sub_18B1A
; End of function Orphaned_EffectInitImpactObjectFromCurrent
; Decrements projectile lifetime
Weapon_TickLifetimeTimer:                               ; was: sub_18B20
                subq.w  #1,$48(a5)
                bmi.w   Object_MarkInactive
                rts
; End of function Weapon_TickLifetimeTimer
; Handles explosive projectile impact with particle spawn
Weapon_HandleExplosiveImpact:                           ; was: sub_18B2A
                bclr    #7,$22(a5)
                bne.s   Weapon_HandleExplosiveImpact_InitExplosion
                bclr    #6,$23(a5)
                beq.w   Weapon_AnimateExplosionFade
                bclr    #4,$23(a5)
                bne.s   Weapon_HandleExplosiveImpact_InitBurst
Weapon_HandleExplosiveImpact_InitExplosion:             ; was: loc_18B44
                tst.w   (WeaponModeParameter).w
                beq.s   Weapon_HandleExplosiveImpact_InitImpact
                move.l  $18(a5),d0
                asr.l   #3,d0
                move.l  d0,$18(a5)
                move.l  $1C(a5),d0
                asr.l   #3,d0
                move.l  d0,$1C(a5)
                move.w  #$400,(a5)
                move.w  #$EC00,2(a5)
                move.w  #$480,d0
                or.w    (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a5)
                move.l  #Effect_SpriteAnimation01,8(a5)
                clr.w   $C(a5)
                move.w  #5,$26(a5)
                tst.w   (DifficultyMode).w
                bne.s   Weapon_HandleExplosiveImpact_Return
                move.w  #6,$26(a5)
Weapon_HandleExplosiveImpact_Return:                    ; was: locret_18B92
                rts
; ---------------------------------------------------------------------------
Weapon_HandleExplosiveImpact_InitImpact:                ; was: loc_18B94
                clr.l   $18(a5)
                clr.l   $1C(a5)
                lea     (Weapon_ImpactSpriteFrames).l,a1
                jmp     Sprite_InitTypeA4FromCurrentTable
; ---------------------------------------------------------------------------
Weapon_HandleExplosiveImpact_InitBurst:                 ; was: loc_18BA8
                move.w  #$44D6,d0
                add.w   (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a5)
                move.w  #$A00,8(a5)
                move.w  #$F4F4,$A(a5)
                move.l  #Weapon_HomingEffectSpriteData,$4A(a5)
                bra.w   Effect_InitSharedImpactMotion
; End of function Weapon_HandleExplosiveImpact
; Attributes: thunk
; Unreachable: a second thunk to the same routine, likewise unreferenced
Orphaned_EffectInitExplosiveImpactFromCurrent:
                jmp     Sprite_InitTypeA4FromCurrentTable  ; was: sub_18BCC
; End of function Orphaned_EffectInitExplosiveImpactFromCurrent
; Animates explosion sprite fading sequence
Weapon_AnimateExplosionFade:                            ; was: sub_18BD2
                subq.w  #2,$5E(a5)
                bmi.w   Object_MarkInactive
                move.w  $5E(a5),d0
                asr.w   #2,d0
                cmpi.w  #6,d0
                bmi.s   Weapon_GetExplosionFrameData
                moveq   #6,d0
; Gets explosion animation frame data based on timer
Weapon_GetExplosionFrameData:                           ; was: loc_18BE8
                andi.w  #6,d0
                move.w  Weapon_ExplosionFadeTiles(pc,d0.w),d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                move.w  Weapon_ExplosionFadeSizes(pc,d0.w),8(a5)
                move.w  Weapon_ExplosionFadeOffsets(pc,d0.w),$A(a5)
                rts
; End of function Weapon_AnimateExplosionFade
; ---------------------------------------------------------------------------
Weapon_ExplosionFadeTiles:      dc.w    $45A9, $45A5, $45A1, $45A0  ; was: word_18C06
Weapon_ExplosionFadeSizes:      dc.w    $A00, $500, $500, 0  ; was: word_18C0E
Weapon_ExplosionFadeOffsets:    dc.w    $F4F4, $F8F8, $F8F8, $FCFC  ; was: word_18C16

; Marks the current object inactive without additional cleanup
Object_MarkInactiveDirect:                              ; was: sub_18C1E
                bset    #4,2(a5)
                rts
; End of function Object_MarkInactiveDirect
; Processes projectile hit effects including screen shake and palette change
Weapon_ProcessProjectileHit:                            ; was: sub_18C26
                move.w  #$A0,(PaletteRGBAdjustLevel).w
                move.b  #$60,(PaletteRGBChannelMask).w  ; '`'
                move.b  #4,(PaletteRGBAdjustStep).w
                tst.w   $26(a5)
                bpl.s   Weapon_HideHitEffectWhenFinished
                clr.b   $21(a5)
; Hides the hit effect after its animation reaches the terminal frame
Weapon_HideHitEffectWhenFinished:                       ; was: loc_18C42
                cmpi.w  #$80,$C(a5)
                bmi.s   Weapon_ProcessProjectileHit_Return
                move.w  #$1000,2(a5)
Weapon_ProcessProjectileHit_Return:                     ; was: locret_18C50
                rts
; End of function Weapon_ProcessProjectileHit
; Updates an impact particle or spawns its child effect
Effect_UpdateImpactParticleSpawner:                     ; was: sub_18C52
                bclr    #6,$23(a5)
                bne.s   Effect_UpdateImpactParticleSpawner_SpawnChild
                bclr    #7,$22(a5)
                beq.w   Effect_UpdateImpactParticleAnimation
Effect_UpdateImpactParticleSpawner_SpawnChild:          ; was: loc_18C64
                move.w  a5,d0
                btst    #5,d0
                bne.w   Effect_UpdateImpactParticleSpawner_Deactivate
                jsr     (PlayerEffect_FindFreeSlot).l
                bne.w   Effect_UpdateImpactParticleSpawner_Deactivate
                lea     (Effect_ParticlePrimarySpriteFrames).l,a1
                btst    #7,(RandomNumberState).w
                bne.s   Effect_UpdateImpactParticleSpawner_InitChild
                lea     (Effect_ParticleSecondarySpriteFrames).l,a1
Effect_UpdateImpactParticleSpawner_InitChild:           ; was: loc_18C8C
                jsr     (Sprite_InitTypeA4FromTable).l
                move.w  #$8C80,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                bpl.s   Effect_UpdateImpactParticleSpawner_SetVelocity
                clr.b   $20(a0)
Effect_UpdateImpactParticleSpawner_SetVelocity:         ; was: loc_18CB4
                move.w  $56(a5),d5
                addi.w  #$20,d5                         ; ' '
                andi.w  #$7C,d5                         ; '|'
                lea     Weapon_DirectionVectorsSpeed12(pc),a1
                nop
                move.l  (a1,d5.w),d0
                move.l  $20(a1,d5.w),d1
                btst    #1,(FrameCounter+1).w
                bne.s   Effect_UpdateImpactParticleSpawner_ApplyDirection
                neg.l   d0
                neg.l   d1
Effect_UpdateImpactParticleSpawner_ApplyDirection:      ; was: loc_18CDA
                asr.l   #2,d0
                asr.l   #2,d1
                add.l   (WeaponYMotionParameter).w,d0
                add.l   (WeaponXMotionParameter).w,d1
                move.l  d1,$18(a0)
                move.l  d0,$1C(a0)
Effect_UpdateImpactParticleSpawner_Deactivate:          ; was: loc_18CEE
                                        ; Effect_UpdateImpactParticleSpawner+22   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
; Updates particle effect sprite animation with gravity and fading
Effect_UpdateImpactParticleAnimation:                   ; was: loc_18CF6
                move.l  (WeaponYMotionParameter).w,d0
                move.l  (WeaponXMotionParameter).w,d1
                add.l   d1,$18(a5)
                add.l   d0,$1C(a5)
                subq.w  #2,$48(a5)
                bmi.s   Effect_UpdateImpactParticleSpawner_Deactivate
                move.w  $48(a5),d0
                move.w  Effect_ImpactParticleTiles(pc,d0.w),d1
                or.w    (GlobalSpritePriorityBit).w,d1
                or.w    (GlobalSpriteFlipBits).w,d1
                move.w  d1,$E(a5)
                move.w  Effect_ImpactParticleSizes(pc,d0.w),8(a5)
                move.w  Effect_ImpactParticleOffsets(pc,d0.w),$A(a5)
                rts
; End of function Effect_UpdateImpactParticleSpawner
; ---------------------------------------------------------------------------
Effect_ImpactParticleTiles:     dc.w    $452B, $451B, $450B, $451B, $452B, $4492, $449B, $44A4  ; was: word_18D2E
Effect_ImpactParticleSizes:     dc.w    $F00, $F00, $F00, $F00, $F00, $A00, $A00, $500  ; was: word_18D3E
Effect_ImpactParticleOffsets:   dc.w    $F0F0, $F0F0, $F0F0, $F0F0, $F0F0, $F4F4, $F4F4, $F8F8  ; was: word_18D4E

; Updates seeking missile projectile with target tracking and rotation
Weapon_UpdateSeekingMissile:                            ; was: sub_18D5E
                bclr    #7,$22(a5)
                bne.s   Weapon_UpdateSeekingMissile_InitImpact
                bclr    #4,$23(a5)
                beq.s   Weapon_UpdateSeekingMissile_TickLifetime
Weapon_UpdateSeekingMissile_InitImpact:                 ; was: loc_18D6E
                move.w  #3,$48(a5)
                move.l  #Effect_SpriteAnimation12,8(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                jmp     Effect_InitType188FromCurrent
; ---------------------------------------------------------------------------
Weapon_UpdateSeekingMissile_TickLifetime:               ; was: loc_18D8A
                subq.w  #1,$48(a5)
                bpl.w   Weapon_UpdateSeekingMissile_ApplyVelocity
                cmpi.w  #$FFF1,$48(a5)
                bpl.s   Weapon_UpdateSeekingMissile_SelectTrackingSlot
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Weapon_UpdateSeekingMissile_SelectTrackingSlot:         ; was: loc_18DA2
                move.w  a5,d0
                btst    #0,(FrameCounter+1).w
                bne.w   Weapon_UpdateSeekingMissile_CheckAlternateSlot
                btst    #5,d0
                beq.s   Weapon_UpdateSeekingMissile_SelectTargetAngle
                bra.s   Weapon_UpdateSeekingMissile_ApplyVelocity
; ---------------------------------------------------------------------------
Weapon_UpdateSeekingMissile_CheckAlternateSlot:         ; was: loc_18DB6
                btst    #5,d0
                beq.s   Weapon_UpdateSeekingMissile_ApplyVelocity
Weapon_UpdateSeekingMissile_SelectTargetAngle:          ; was: loc_18DBC
                move.w  (WeaponTargetOrFrame).w,d0
                bne.s   Weapon_UpdateSeekingMissile_ComputeTargetAngle
                move.w  (RandomNumberState).w,d2
                bra.s   Weapon_UpdateSeekingMissile_AdjustHeading
; ---------------------------------------------------------------------------
Weapon_UpdateSeekingMissile_ComputeTargetAngle:         ; was: loc_18DC8
                bclr    #0,d0
                movea.w d0,a0
                move.w  $10(a0),d0
                move.w  $14(a0),d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_Arctan2Lookup).l
                asr.w   #1,d2
                move.w  d2,(SeekingAngleScratch).w
                move.b  (SeekingAngleScratch).w,d2
Weapon_UpdateSeekingMissile_AdjustHeading:              ; was: loc_18DEE
                andi.w  #$7C,d2                         ; '|'
                move.w  (RandomNumberState).w,d0
                andi.w  #6,d0
                addq.w  #6,d0
                sub.w   $56(a5),d2
                bmi.s   Weapon_UpdateSeekingMissile_CheckAngleWrap
                cmpi.w  #$40,d2                         ; '@'
                bpl.s   Weapon_UpdateSeekingMissile_DecreaseHeading
Weapon_UpdateSeekingMissile_IncreaseHeading:            ; was: loc_18E08
                add.w   d0,$56(a5)
                bra.s   Weapon_UpdateSeekingMissile_ApplyVelocity
; ---------------------------------------------------------------------------
Weapon_UpdateSeekingMissile_CheckAngleWrap:             ; was: loc_18E0E
                cmpi.w  #$FFC0,d2
                bmi.s   Weapon_UpdateSeekingMissile_IncreaseHeading
Weapon_UpdateSeekingMissile_DecreaseHeading:            ; was: loc_18E14
                sub.w   d0,$56(a5)
Weapon_UpdateSeekingMissile_ApplyVelocity:              ; was: loc_18E18
                                        ; Weapon_UpdateSeekingMissile+56   j
                move.w  $56(a5),d2
                andi.w  #$7E,d2                         ; '~'
                move.w  d2,$56(a5)
                andi.w  #$7C,d2                         ; '|'
                movea.l (WeaponModeParameter).w,a0
                move.l  (a0,d2.w),d1
                move.l  $20(a0,d2.w),d0
                move.w  (WeaponXMotionParameter+2).w,d2
                asr.l   d2,d1
                asr.l   d2,d0
                move.l  d1,$1C(a5)
                move.l  d0,$18(a5)
                move.w  $48(a5),d0
                bmi.s   Weapon_UpdateSeekingMissile_SelectFrame
                moveq   #4,d0
Weapon_UpdateSeekingMissile_SelectFrame:                ; was: loc_18E4C
                andi.w  #$E,d0
                move.w  Weapon_SeekingMissileTiles(pc,d0.w),d1
                or.w    (GlobalSpritePriorityBit).w,d1
                or.w    (GlobalSpriteFlipBits).w,d1
                move.w  d1,$E(a5)
                cmpi.w  #4,d0
                bmi.s   Weapon_SetMissileSize
                move.w  #$A00,8(a5)
                move.w  #$F4F4,$A(a5)
                rts
; ---------------------------------------------------------------------------
; Sets the smaller missile sprite for the first two frame indices
Weapon_SetMissileSize:                                  ; was: loc_18E74
                move.w  #$500,8(a5)
                move.w  #$F8F8,$A(a5)
                rts
; End of function Weapon_UpdateSeekingMissile
; ---------------------------------------------------------------------------
Weapon_SeekingMissileTiles: dc.w    $45A0, $45A0, $45A4, $45AD, $45AD, $45B6, $45B6, $45AD  ; was: word_18E82

; Matches sprite position and properties to parent sprite
Effect_UpdateCompanionFromParent:                       ; was: sub_18E92
                movea.w a5,a0
                btst    #0,(FrameCounter+1).w
                bne.s   Effect_UpdateCompanionFromAlternateParent
                suba.w  #$300,a0
                bra.s   Effect_UpdateCompanion_CheckParent
; ---------------------------------------------------------------------------
Effect_UpdateCompanionFromAlternateParent:              ; was: loc_18EA2
                suba.w  #$360,a0
Effect_UpdateCompanion_CheckParent:                     ; was: loc_18EA6
                move.w  $48(a5),d0
                cmp.w   (a0),d0
                beq.s   Effect_CopyParentTransform
                move.w  #$40,$10(a5)                    ; '@'
                rts
; ---------------------------------------------------------------------------
; Copies parent sprite transform data including position and tiles
Effect_CopyParentTransform:                             ; was: loc_18EB6
                move.w  $10(a0),d0
                sub.w   $18(a0),d0
                move.w  d0,$10(a5)
                move.w  $14(a0),d0
                sub.w   $1C(a0),d0
                move.w  d0,$14(a5)
                move.w  $E(a0),$E(a5)
                move.w  8(a0),8(a5)
                move.w  $A(a0),$A(a5)
                move.b  $20(a0),$20(a5)
                rts
; End of function Effect_UpdateCompanionFromParent
; Updates projectile seeking movement
Weapon_UpdateSeekingProjectile:                         ; was: sub_18EE8
                subq.w  #1,$5E(a5)
                bmi.s   Weapon_HandleSeekingProjectileCollision
                bne.s   Weapon_ApplySeekingProjectileMotion
                move.b  #$40,$21(a5)                    ; '@'
; Updates sprite seeking motion with velocity subtraction
Weapon_ApplySeekingProjectileMotion:                    ; was: loc_18EF6
                move.l  $48(a5),d0
                move.l  $4C(a5),d1
                sub.l   d0,$14(a5)
                sub.l   d1,$10(a5)
; End of function Weapon_UpdateSeekingProjectile
; Handles projectile collision and destruction
Weapon_HandleSeekingProjectileCollision:                ; was: sub_18F06
                btst    #6,$23(a5)
                bne.s   Weapon_HandleSeekingProjectileCollision_Explode
                tst.w   $26(a5)
                bpl.s   Weapon_HandleSeekingProjectileCollision_Return
                lea     (Projectile_CollisionSpriteFrames).l,a1
                jsr     (Sprite_InitCurrentFromTable).l
                move.w  #$8080,2(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
Weapon_HandleSeekingProjectileCollision_Return:         ; was: locret_18F2E
                rts
; ---------------------------------------------------------------------------
Weapon_HandleSeekingProjectileCollision_Explode:        ; was: loc_18F30
                btst    #4,$23(a5)
                beq.s   Weapon_HandleSeekingProjectileCollision_SpawnEffect
                move.b  #$C8,d0
                jsr     (Sound_QueueSFXRequest).l
Weapon_HandleSeekingProjectileCollision_SpawnEffect:    ; was: loc_18F42
                movea.w a5,a0
                bsr.s   Effect_SpawnExplosion
Weapon_InitProjectileCompanion:                         ; was: loc_18F46
                movea.w a5,a0
                adda.w  #$300,a0
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
; End of function Weapon_HandleSeekingProjectileCollision
; Spawns explosion effect with random velocity
Effect_SpawnExplosion:                                  ; was: sub_18F58
                lea     (Effect_StarParticleSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.w  #$8C80,2(a0)
                move.b  (RandomNumberState).w,d3
                move.b  (RandomNumberState+1).w,d4
                andi.w  #1,d3
                andi.w  #1,d4
                addq.w  #3,d3
                addq.w  #3,d4
                movea.l #Math_SineTable,a1
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   d3,d1
                asl.l   d4,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                rts
; End of function Effect_SpawnExplosion
; Updates bomb projectile with gravity and collision detection
Weapon_UpdateBombProjectile:                            ; was: sub_18FA6
                btst    #6,$23(a5)
                bne.w   Weapon_UpdateBombProjectile_Explode
                tst.w   $26(a5)
                bpl.s   Weapon_UpdateBombProjectile_TickLifetime
                lea     (Projectile_BombAndRadialSpriteFrames).l,a1
                jsr     (Sprite_InitCurrentFromTable).l
                move.w  #$8080,2(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                rts
; ---------------------------------------------------------------------------
Weapon_UpdateBombProjectile_TickLifetime:               ; was: loc_18FD2
                subq.w  #1,$5E(a5)
                bpl.s   Weapon_UpdateBombProjectile_ApplyMotion
                bset    #4,2(a5)
                clr.b   $21(a5)
                movea.w a5,a0
                adda.w  #$300,a0
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $18(a5),d0
                asr.l   #2,d0
                move.l  d0,$18(a0)
                move.l  $1C(a5),d0
                asr.l   #2,d0
                move.l  d0,$1C(a0)
                lea     (Effect_StarParticleSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.w  #$8C80,2(a0)
                rts
; ---------------------------------------------------------------------------
Weapon_UpdateBombProjectile_ApplyMotion:                ; was: loc_1901C
                move.w  #$8080,2(a5)
                move.w  $58(a5),d0
                add.w   (PlayerXPosition).w,d0
                move.l  $50(a5),d1
                add.l   $18(a5),d1
                move.l  d1,$50(a5)
                swap    d1
                add.w   d1,d0
                move.w  d0,$10(a5)
                move.w  $5A(a5),d0
                add.w   (PlayerYPosition).w,d0
                move.l  $54(a5),d1
                add.l   $1C(a5),d1
                move.l  d1,$54(a5)
                swap    d1
                add.w   d1,d0
                move.w  d0,$14(a5)
                rts
; ---------------------------------------------------------------------------
Weapon_UpdateBombProjectile_Explode:                    ; was: loc_1905C
                btst    #4,$23(a5)
                beq.s   Weapon_UpdateBombProjectile_SpawnDebris
                move.b  #$C8,d0
                jsr     (Sound_QueueSFXRequest).l
Weapon_UpdateBombProjectile_SpawnDebris:                ; was: loc_1906E
                movea.w a5,a0
                bsr.s   Effect_CreateExplosionDebris
                movea.w a5,a0
                adda.w  #$300,a0
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
; End of function Weapon_UpdateBombProjectile
; Creates explosion debris particles with random velocity
Effect_CreateExplosionDebris:                           ; was: sub_19084
                lea     (Effect_StarParticleSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.w  #$8C80,2(a0)
                move.b  (RandomNumberState).w,d3
                move.b  (RandomNumberState+1).w,d4
                andi.w  #1,d3
                andi.w  #1,d4
                addq.w  #2,d3
                addq.w  #2,d4
                movea.l #Math_SineTable,a1
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   d3,d1
                asl.l   d4,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                rts
; End of function Effect_CreateExplosionDebris
; Spawns spark particle during player death sequence
Effect_SpawnPlayerDeathSpark:                           ; was: sub_190D2
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #$F,d7
Effect_SpawnPlayerDeathSpark_FindSlot:                  ; was: loc_190D8
                tst.w   (a0)
                beq.s   Effect_SpawnPlayerDeathSpark_Initialize
                lea     $60(a0),a0
                dbf     d7,Effect_SpawnPlayerDeathSpark_FindSlot
                rts
; ---------------------------------------------------------------------------
Effect_SpawnPlayerDeathSpark_Initialize:                ; was: loc_190E6
                move.w  #$7C,(a0)                       ; '|'
                move.w  #$EC00,2(a0)
                clr.b   $21(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$480,$E(a0)
                move.w  (GlobalSpritePriorityBit).w,d0
                or.w    d0,$E(a0)
                move.l  #Effect_SpriteAnimation01,8(a0)
                clr.w   $C(a0)
                lea     (Math_SineTable).l,a1
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (FrameCounter).w,d0
                asl.w   #5,d0
                andi.w  #$1FE,d0
                move.w  (a1,d0.w),d2
                move.w  d1,$4E(a0)
                move.w  d2,$50(a0)
                ext.l   d1
                ext.l   d2
                asl.l   #5,d1
                asl.l   #5,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                rts
; End of function Effect_SpawnPlayerDeathSpark
; Updates death spark particle motion with deceleration
Effect_UpdateDeathSparkMotion:                          ; was: sub_19154
                cmpi.w  #$80,$C(a5)
                bmi.s   Effect_ApplySparkDeceleration
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
; Applies deceleration to spark particle velocity
Effect_ApplySparkDeceleration:                          ; was: loc_19164
                move.w  $4E(a5),d0
                move.w  $50(a5),d1
                ext.l   d0
                ext.l   d1
                sub.l   d0,$1C(a5)
                sub.l   d1,$18(a5)
                rts
; End of function Effect_UpdateDeathSparkMotion
; Destroys sprite when timer expires
Object_UpdateRemovalTimer:                              ; was: sub_1917A
                subq.w  #1,$48(a5)
                bpl.s   Object_UpdateRemovalTimer_Return
                bset    #4,2(a5)
Object_UpdateRemovalTimer_Return:                       ; was: locret_19186
                rts
; End of function Object_UpdateRemovalTimer
; Initializes projectile sprite with position and velocity
Effect_InitPlayerMotionProjectile:                      ; was: sub_19188
                bset    #7,2(a5)
                cmpi.l  #Player_TeleportDashTrailSpriteMapping,(PlayerSpriteMapping).w
                beq.s   Effect_InitPlayerMotionProjectile_CopyPosition
                bclr    #7,2(a5)
Effect_InitPlayerMotionProjectile_CopyPosition:         ; was: loc_1919E
                move.w  (PlayerXPosition).w,$10(a5)
                move.w  (PlayerYPosition).w,$14(a5)
                bclr    #7,$22(a5)
                beq.s   Effect_InitPlayerMotionProjectile_SpawnChild
                move.w  #4,(FrameFreezeTimer).w
Effect_InitPlayerMotionProjectile_SpawnChild:           ; was: loc_191B8
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #$B,d7
                jsr     (Sys_FindFreeObjectSlot).l
                bne.w   Effect_InitPlayerMotionProjectile_Return
                move.l  #Effect_SpriteAnimation02,8(a0)
                jsr     (Sprite_InitType160).l
                move.b  $20(a5),$20(a0)
                lea     (Math_SineTable).l,a1
                move.w  (FrameCounter).w,d0
                asl.w   #5,d0
                andi.w  #$1FE,d0
                move.w  -$80(a1,d0.w),d1
                ext.l   d1
                asl.l   #3,d1
                move.l  d1,$1C(a0)
                swap    d1
                btst    #0,(FrameCounter+1).w
                bne.s   Effect_InitPlayerMotionProjectile_ApplyFacing
                neg.w   d1
                neg.l   $1C(a0)
Effect_InitPlayerMotionProjectile_ApplyFacing:          ; was: loc_19208
                add.w   $14(a5),d1
                move.w  d1,$14(a0)
                move.w  $10(a5),$10(a0)
                tst.w   (PlayerStateWorkHighWord).w
                bmi.s   Effect_InitPlayerMotionProjectile_MoveRight
                move.l  #$FFF60000,$18(a0)
                rts
; ---------------------------------------------------------------------------
Effect_InitPlayerMotionProjectile_MoveRight:            ; was: loc_19226
                move.l  #$A0000,$18(a0)
                rts
; ---------------------------------------------------------------------------
Effect_InitPlayerMotionProjectile_Return:               ; was: locret_19230
                rts
; End of function Effect_InitPlayerMotionProjectile
; Increments frame and checks lifetime
Effect_AnimateAndExpire:                                ; was: sub_19232
                addq.w  #1,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Effect_AnimateAndExpire_Return
                bset    #4,2(a5)
Effect_AnimateAndExpire_Return:                         ; was: locret_19242
                rts
; End of function Effect_AnimateAndExpire
