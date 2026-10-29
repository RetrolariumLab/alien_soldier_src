Player_SpawnCircleAttack:                               ; was: sub_18530
                tst.w   $10(a4)
                beq.w   Effect_SpawnRandomDebris
                tst.w   (WeaponFireCooldown).w
                bpl.w   Weapon_FireNoOp
                move.w  #$38,(WeaponFireCooldown).w     ; '8'
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #7,d7
Weapon_CircleAttack_CheckSlots:                         ; was: loc_1854C
                move.w  (a0),d0
                bne.w   Weapon_CircleAttack_Return
                lea     $60(a0),a0
                dbf     d7,Weapon_CircleAttack_CheckSlots
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$C0,(PaletteRGBChannelMask).w
                move.b  #4,(PaletteRGBAdjustStep).w
                tst.w   (ShootingMode).w
                bne.s   Weapon_CircleAttack_SelectAmmoCost
                subi.w  #$A,$10(a4)
Weapon_CircleAttack_SelectAmmoCost:                     ; was: loc_18578
                move.w  #$8C,d0
                tst.b   (DifficultyMode).w
                bne.s   Weapon_CircleAttack_SubtractAmmo
                move.w  #$8C,d0
Weapon_CircleAttack_SubtractAmmo:                       ; was: loc_18586
                sub.w   d0,$10(a4)
                bpl.s   Weapon_CircleAttack_SetupProjectiles
                clr.w   $10(a4)
Weapon_CircleAttack_SetupProjectiles:                   ; was: loc_18590
                moveq   #0,d5
                movea.l #Weapon_DirectionTableOffsets,a0
                move.b  (a0,d6.w),d5
                move.w  d5,d7
                asl.w   #2,d5
                movea.l #Math_SineTable,a0
                move.w  -$80(a0,d5.w),d3
                move.w  (a0,d5.w),d4
                muls.w  #$27,d3                         ; '''
                muls.w  #$27,d4                         ; '''
                move.l  d3,(CircleAttackOffsetX).w
                move.l  d4,(CircleAttackOffsetY).w
                move.w  d1,d3
                move.w  d2,d4
                sub.w   $10(a5),d3
                sub.w   $14(a5),d4
                move.w  d3,(CircleAttackTargetDX).w
                move.w  d4,(CircleAttackTargetDY).w
                movea.l #Weapon_DirectionVectorsSpeed10,a0
                move.l  (a0,d7.w),d3
                move.l  $20(a0,d7.w),d4
                move.w  d7,d6
                addq.w  #8,d6
                andi.w  #$70,d6                         ; 'p'
                asr.w   #3,d6
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #7,d7
                movea.l #Weapon_CircleAttackSpriteData,a2
                moveq   #1,d5
                move.w  (GlobalSpritePriorityBit).w,d0
                andi.w  #$8000,d0
Weapon_CircleAttack_SpawnLoop:                          ; was: loc_18600
                move.w  #$60,(a0)                       ; '`'
                move.w  #$8E80,2(a0)
                move.w  d1,$10(a0)
                move.w  d2,$14(a0)
                move.w  (CircleAttackTargetDX).w,$58(a0)
                move.w  (CircleAttackTargetDY).w,$5A(a0)
                move.l  d3,$1C(a0)
                move.l  d4,$18(a0)
                move.l  (CircleAttackOffsetX).w,$48(a0)
                move.l  (CircleAttackOffsetY).w,$4C(a0)
                clr.l   $50(a0)
                clr.l   $54(a0)
                move.w  (a2,d6.w),$E(a0)
                move.w  $10(a2,d6.w),8(a0)
                move.w  $20(a2,d6.w),$A(a0)
                or.w    d0,$E(a0)
                clr.b   $21(a0)
                move.b  #4,$23(a0)
                move.w  #$D,$26(a0)
                tst.w   (DifficultyMode).w
                bne.s   Weapon_SetCircleAttackProperties
                move.w  #$E,$26(a0)
; Sets sprite properties for circular attack pattern projectiles
Weapon_SetCircleAttackProperties:                       ; was: loc_1866C
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                move.w  d5,$5E(a0)
                addq.w  #3,d5
                lea     $60(a0),a0
                dbf     d7,Weapon_CircleAttack_SpawnLoop
                andi.w  #6,d6
                asl.w   #1,d6
                move.l  Weapon_CircleAttackAnimationPointers(pc,d6.w),(WeaponAnimationDataPtr).w
                clr.w   (WeaponTargetOrFrame).w
                move.b  #$B4,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Weapon_CircleAttack_Return:                             ; was: locret_1869E
                rts
; End of function Player_SpawnCircleAttack
; ---------------------------------------------------------------------------
Weapon_CircleAttackAnimationPointers:   dc.l    Weapon_CircleAttackDirectionalFrames0  ; was: off_186A0
                dc.l    Weapon_CircleAttackDirectionalFrames2
                dc.l    Weapon_CircleAttackDirectionalFrames1
                dc.l    Weapon_CircleAttackDirectionalFrames2
Weapon_CircleAttackSpriteData:  dc.w    $65A0, $75A0, $75A0, $7DA0, $6DA0, $6DA0, $65A0, $65A0  ; was: word_186B0
                dc.w    $C00, $500, $300, $500, $C00, $500, $300, $500
                dc.w    $F0FC, $F8F8, $FCF0, $F8F8, $F0FC, $F8F8, $FCF0, $F8F8

Orphaned_WeaponReturnAfterCircleAttack:                 ; was: nullsub_49
                rts
; End of function Orphaned_WeaponReturnAfterCircleAttack

; Fires homing projectile that tracks player position
Weapon_FireHomingShot:                                  ; was: sub_186E2
                tst.w   $10(a4)
                beq.w   Effect_SpawnRandomDebris
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$80,(PaletteRGBChannelMask).w
                move.b  #8,(PaletteRGBAdjustStep).w
                btst    #0,(FrameCounter+1).w
                bne.s   Weapon_FireHomingShot_Return
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #7,d7
Weapon_FireHomingShot_FindSlot:                         ; was: loc_1870A
                move.w  (a0),d0
                beq.s   Weapon_FireHomingShot_Initialize
                lea     $60(a0),a0
                dbf     d7,Weapon_FireHomingShot_FindSlot
Weapon_FireHomingShot_Return:                           ; was: locret_18716
                rts
; ---------------------------------------------------------------------------
Weapon_FireHomingShot_Initialize:                       ; was: loc_18718
                tst.w   (ShootingMode).w
                bne.s   Weapon_FireHomingShot_SelectAmmoCost
                subq.w  #2,$10(a4)
Weapon_FireHomingShot_SelectAmmoCost:                   ; was: loc_18722
                move.w  #3,d0
                tst.b   (DifficultyMode).w
                bne.s   Weapon_FireHomingShot_SubtractAmmo
                move.w  #2,d0
Weapon_FireHomingShot_SubtractAmmo:                     ; was: loc_18730
                sub.w   d0,$10(a4)
                bpl.s   Weapon_FireHomingShot_SetupObject
                clr.w   $10(a4)
Weapon_FireHomingShot_SetupObject:                      ; was: loc_1873A
                move.w  d1,$10(a0)
                move.w  d2,$14(a0)
                sub.w   $10(a5),d1
                sub.w   $14(a5),d2
                move.w  d1,$58(a0)
                move.w  d2,$5A(a0)
                clr.l   $50(a5)
                clr.l   $54(a5)
                move.w  #$74,(a0)                       ; 't'
                move.b  #$40,$21(a0)                    ; '@'
                move.b  #4,$23(a0)
                move.w  #3,$26(a0)
                tst.w   (DifficultyMode).w
                bne.s   Weapon_SetHomingProjectileData
                move.w  #4,$26(a0)
; Sets homing projectile velocity and sprite animation data
Weapon_SetHomingProjectileData:                         ; was: loc_1877C
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                move.w  #$12,$5E(a0)
                lea     Weapon_DirectionTableOffsets(pc),a1
                moveq   #0,d5
                move.b  (a1,d6.w),d5
                movea.l #Weapon_DirectionTableOffsets,a1
                move.b  (a1,d6.w),d6
                movea.l (WeaponModeParameter).w,a1
                move.l  (a1,d6.w),d0
                move.l  $20(a1,d6.w),d1
                move.l  d0,$1C(a0)
                move.l  d1,$18(a0)
                andi.w  #$70,d6                         ; 'p'
                asr.w   #3,d6
                movea.l #Weapon_HomingShotSpriteData,a1
                move.w  (a1,d6.w),d0
                or.w    (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a0)
                move.w  $10(a1,d6.w),8(a0)
                move.w  $20(a1,d6.w),$A(a0)
                btst    #1,(FrameCounter+1).w
                bne.s   Weapon_FireHomingShot_SoundReturn
                move.b  #$B3,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Weapon_FireHomingShot_SoundReturn:                      ; was: locret_187EA
                rts
; End of function Weapon_FireHomingShot
; ---------------------------------------------------------------------------
Weapon_HomingShotSpriteData:    dc.w    $65A3, $75A6, $75A0, $7DA6, $6DA3, $6DA6, $65A0, $65A6  ; was: word_187EC
                dc.w    $800, $A00, $200, $A00, $800, $A00, $200, $A00
                dc.w    $F4FC, $F4F4, $FCF4, $F4F4, $F4FC, $F4F4, $FCF4, $F4F4

Orphaned_WeaponReturnAfterHomingShot:                   ; was: nullsub_50
                rts
; End of function Orphaned_WeaponReturnAfterHomingShot

; Unreachable: would place a projectile from a facing-mirrored table offset
Orphaned_WeaponCalculateOffsetPosition:
                move.b  (a4,d6.w),d0                    ; was: sub_1881E
                move.b  8(a4,d6.w),d1
                ext.w   d0
                ext.w   d1
                btst    #3,$E(a5)
                beq.s   Orphaned_WeaponCalculateOffsetPositionApplyFacing
                neg.w   d0
Orphaned_WeaponCalculateOffsetPositionApplyFacing:      ; was: loc_18834
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                rts
; End of function Orphaned_WeaponCalculateOffsetPosition
; Spawns random debris particle with velocity
Effect_SpawnRandomDebris:                               ; was: sub_18846
                                        ; Weapon_FireMultipleShots+4   j
                btst    #0,(FrameCounter+1).w
                bne.s   Effect_SpawnRandomDebris_Return
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #7,d7
Effect_SpawnRandomDebris_FindSlot:                      ; was: loc_18854
                tst.w   (a0)
                beq.s   Effect_CreateDebrisParticle
                lea     $60(a0),a0
                dbf     d7,Effect_SpawnRandomDebris_FindSlot
Effect_SpawnRandomDebris_Return:                        ; was: locret_18860
                rts
; ---------------------------------------------------------------------------
; Creates random debris particle effect with velocity
Effect_CreateDebrisParticle:                            ; was: loc_18862
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   d0,d1
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   d0,d2
                move.w  d1,$10(a0)
                move.w  d2,$14(a0)
                jsr     (Sprite_InitType160).l
                move.w  #$334,(a0)
                move.l  #SharedCombatSpriteAnimation21,8(a0)
                move.b  #$40,$21(a0)                    ; '@'
                clr.b   $23(a0)
                move.w  #1,$26(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                movea.l #Weapon_DirectionTableOffsets,a1
                move.b  (a1,d6.w),d6
                andi.w  #$7C,d6                         ; '|'
                movea.l #Weapon_DirectionVectorsSpeed6,a1
                move.l  (a1,d6.w),d0
                move.l  $20(a1,d6.w),d1
                asr.l   #1,d0
                asr.l   #1,d1
                move.l  d0,$1C(a0)
                add.l   (StageMotionXDelta).w,d1
                move.l  d1,$18(a0)
                btst    #1,(FrameCounter+1).w
                bne.s   Effect_CreateDebrisParticle_Return
                move.b  #$D3,d0
                jsr     (Sound_QueueSFXRequest).l
Effect_CreateDebrisParticle_Return:                     ; was: locret_188EC
                rts
; End of function Effect_SpawnRandomDebris
; Removes the object when its state flag or animation lifetime has ended
Object_RemoveOnFlagOrAnimationEnd:                      ; was: sub_188EE
                bclr    #7,$22(a5)
                bne.s   Object_RemoveOnFlagOrAnimationEnd_Deactivate
                cmpi.w  #$80,$C(a5)
                bmi.s   Object_RemoveOnFlagOrAnimationEnd_Return
Object_RemoveOnFlagOrAnimationEnd_Deactivate:           ; was: loc_188FE
                bset    #4,2(a5)
Object_RemoveOnFlagOrAnimationEnd_Return:               ; was: locret_18904
                rts
; End of function Object_RemoveOnFlagOrAnimationEnd
; Updates target sight position
Player_UpdateTargetSight:                               ; was: sub_18906
                movea.w #(PlayerObjectType-M68K_RAM),a0
                clr.w   $56(a5)
                move.w  $10(a0),d5
                move.w  $14(a0),d6
                add.w   (WeaponMenuSpawnXOffset).w,d5
                add.w   (WeaponMenuSpawnYOffset).w,d6
                move.w  (WeaponMenuRadius).w,d0
                move.w  (WeaponMenuAngle).w,d7
                add.w   $50(a5),d7
                andi.w  #$1FE,d7
                movea.l #Math_SineTable,a2
                move.w  -$80(a2,d7.w),d1
                move.w  (a2,d7.w),d2
                muls.w  d0,d1
                muls.w  d0,d2
                asl.l   #2,d1
                asl.l   #2,d2
                swap    d1
                swap    d2
                add.w   d6,d1
                add.w   d5,d2
                move.w  d1,$14(a5)
                move.w  d2,$10(a5)
                move.w  (WeaponMenuSlotOffset).w,d0
                cmp.w   $48(a5),d0
                bne.s   Player_UpdateTargetSight_Return
                movea.w #(PlayerEffectObjectPool-M68K_RAM),a0
                btst    #0,(FrameCounter+1).w
                bne.s   Player_UpdateTargetSight_ShowMarker
                bclr    #7,2(a0)
                rts
; ---------------------------------------------------------------------------
Player_UpdateTargetSight_ShowMarker:                    ; was: loc_18972
                bset    #7,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
Player_UpdateTargetSight_Return:                        ; was: locret_18984
                rts
; End of function Player_UpdateTargetSight
; Marks sprite object for removal by setting deactivation flag
Object_MarkInactive:                                    ; was: sub_18986
                                        ; Weapon_UpdateRotatingProjectile+3A   j
                bset    #4,2(a5)
                rts
; End of function Object_MarkInactive
; Updates the knockback particle across motion, lifetime, and impact states
Effect_UpdateKnockbackParticle:                         ; was: sub_1898E
                bclr    #7,$22(a5)
                bne.s   Effect_UpdateKnockbackParticle_BeginMotion
                bclr    #6,$23(a5)
                beq.s   Effect_UpdateKnockbackParticle_TickLifetime
                bclr    #4,$23(a5)
                bne.s   Effect_UpdateKnockbackParticle_InitImpact
Effect_UpdateKnockbackParticle_BeginMotion:             ; was: loc_189A6
                movea.l #Math_SineTable,a1
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   #4,d1
                asl.l   #4,d2
                move.l  d1,$1C(a5)
                move.l  d2,$18(a5)
                lea     (Effect_KnockbackParticleSpriteFrames).l,a1
                jsr     (Sprite_InitTypeA4FromCurrentTable).l
                move.w  #$8C80,2(a5)
                rts
; ---------------------------------------------------------------------------
Effect_UpdateKnockbackParticle_TickLifetime:            ; was: loc_189E0
                subq.w  #1,$5E(a5)
                bpl.s   Effect_UpdateKnockbackParticle_Return
                clr.b   $21(a5)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                move.l  $1C(a5),d0
                asr.l   #1,d0
                move.l  d0,$1C(a5)
                lea     (Effect_KnockbackImpactSpriteFrames).l,a1
                jmp     Sprite_InitTypeA4FromCurrentTable
; ---------------------------------------------------------------------------
Effect_UpdateKnockbackParticle_Return:                  ; was: locret_18A0A
                rts
; ---------------------------------------------------------------------------
Effect_UpdateKnockbackParticle_InitImpact:              ; was: loc_18A0C
                move.l  #Weapon_ProjectileSpriteTiles,$4A(a5)
                move.w  #$456C,d0
                add.w   (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a5)
                move.w  #$F00,8(a5)
                move.w  #$F0F0,$A(a5)
Effect_InitSharedImpactMotion:                          ; was: loc_18A2C
                                        ; Weapon_HandleExplosiveImpact+9E   j
                move.w  #$18C,(a5)
                move.w  #$8C80,2(a5)
                clr.b   $21(a5)
                lea     Weapon_DirectionVectorsSpeed10(pc),a1
                nop
                move.w  (RandomNumberState).w,d6
                andi.w  #$7C,d6                         ; '|'
                move.l  (a1,d6.w),d0
                move.l  $20(a1,d6.w),d1
                asr.l   #1,d0
                asr.l   #1,d1
                move.l  d0,$1C(a5)
                move.l  d1,$18(a5)
                move.b  #$C8,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Effect_UpdateKnockbackParticle
