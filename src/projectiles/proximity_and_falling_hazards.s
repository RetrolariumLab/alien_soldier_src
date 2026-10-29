; Update the type-$48 proximity object and convert it to a temporary burst
Object_UpdateProximityPickupEmitterType48:              ; was: sub_2B6D4
                tst.w   4(a5)
                bne.w   Object_UpdateProximityPickupEmitterType48_UpdateVerticalOscillation
                move.w  $14(a5),$48(a5)
                addq.w  #2,4(a5)
                move.w  #$E300,2(a5)
                move.l  #SharedCombatSpriteAnimation22,8(a5)
                move.w  #$C80,d0
                btst    #1,$5F(a5)
                beq.s   Object_UpdateProximityPickupEmitterType48_StoreSpriteAttributes
                bset    #$C,d0
Object_UpdateProximityPickupEmitterType48_StoreSpriteAttributes:  ; was: loc_2B704
                move.w  d0,$E(a5)
                move.b  #$10,$20(a5)
Object_UpdateProximityPickupEmitterType48_UpdateVerticalOscillation:  ; was: loc_2B70E
                btst    #0,$5F(a5)
                beq.s   Object_UpdateProximityPickupEmitterType48_CheckPlayerProximity
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #3,d0
                move.b  Object_ProximityPickupEmitterVerticalOffsets(pc,d0.w),d0
                ext.w   d0
                add.w   $48(a5),d0
                move.w  d0,$14(a5)
Object_UpdateProximityPickupEmitterType48_CheckPlayerProximity:  ; was: loc_2B72E
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$10,d0
                bpl.s   Object_UpdateProximityPickupEmitterType48_Return
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                bne.s   Object_ConvertProximityPickupEmitterToBurst
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Object_ConvertProximityPickupEmitterToBurst
                jsr     (Pickup_SpawnLarge).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
; Convert the proximity object to its temporary type-$C4 burst
Object_ConvertProximityPickupEmitterToBurst:            ; was: loc_2B75E
                                        ; Object_UpdateProximityPickupEmitterType48+76   j
                move.w  #$9C,$26(a5)
                jsr     (Effect_ConvertCurrentToTypeC4Burst).l
                btst    #0,$5F(a5)
                beq.s   Object_UpdateProximityPickupEmitterType48_Return
                clr.l   $1C(a5)
Object_UpdateProximityPickupEmitterType48_Return:       ; was: locret_2B776
                                        ; Object_UpdateProximityPickupEmitterType48+9C   j
                rts
; End of function Object_UpdateProximityPickupEmitterType48
; ---------------------------------------------------------------------------
Object_ProximityPickupEmitterVerticalOffsets:   dc.b    $FF, 0, 1, 0  ; was: byte_2B778

; Update the type-$2B4 oscillating contact hazard and its impact conversion
Projectile_UpdateOscillatingContactHazardType2B4:       ; was: sub_2B77C
                tst.w   4(a5)
                bne.w   Projectile_UpdateOscillatingContactHazardType2B4_UpdateVerticalOscillation
                move.w  $14(a5),$48(a5)
                addq.w  #2,4(a5)
                move.w  #$8F00,2(a5)
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #$FC04FC04,$2C(a5)
                move.w  #$C4C8,$E(a5)
                move.w  #$500,8(a5)
                move.w  #$F8F8,$A(a5)
                move.b  #$10,$20(a5)
Projectile_UpdateOscillatingContactHazardType2B4_UpdateVerticalOscillation:  ; was: loc_2B7BA
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #3,d0
                move.b  Projectile_OscillatingContactHazardVerticalOffsets(pc,d0.w),d0
                ext.w   d0
                add.w   $48(a5),d0
                move.w  d0,$14(a5)
                btst    #7,$22(a5)
                beq.s   Projectile_UpdateOscillatingContactHazardType2B4_CheckPlayerProximity
                btst    #4,$22(a5)
                beq.w   Projectile_UpdateOscillatingContactHazardType2B4_Detonate
                jmp     Projectile_FragmentBeginDeflectedFall
; ---------------------------------------------------------------------------
Projectile_UpdateOscillatingContactHazardType2B4_CheckPlayerProximity:  ; was: loc_2B7EA
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$C,d0
                bpl.s   Projectile_UpdateOscillatingContactHazardType2B4_Return
Projectile_UpdateOscillatingContactHazardType2B4_Detonate:  ; was: loc_2B7F6
                move.w  #$64,$26(a5)                    ; 'd'
                jsr     (Effect_InitSharedExplosionFromCurrent).l
                clr.l   $1C(a5)
Projectile_UpdateOscillatingContactHazardType2B4_Return:  ; was: locret_2B806
                rts
; End of function Projectile_UpdateOscillatingContactHazardType2B4
; ---------------------------------------------------------------------------
Projectile_OscillatingContactHazardVerticalOffsets: dc.b    $FF, 0, 1, 0  ; was: byte_2B808

; Spawn a type-$84 arc projectile aimed horizontally toward the player
Projectile_SpawnAimedArcFromEnemy:                      ; was: sub_2B80C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_SpawnAimedArcFromEnemy_Return
                add.w   $10(a5),d5
                add.w   $14(a5),d6
                move.w  d5,$10(a0)
                move.w  d6,$14(a0)
                move.w  #$84,(a0)
                move.w  #$8F00,2(a0)
                move.w  #$C4C8,$E(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                move.b  #$20,$20(a0)                    ; ' '
                move.w  #$64,$26(a0)                    ; 'd'
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FC04FC04,$2C(a0)
                movea.w a0,a1
                jsr     (Physics_GetPlayerDelta).l
                moveq   #0,d0
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                subq.w  #8,d0
                swap    d0
                asr.l   #1,d0
                tst.w   d1
                bmi.s   Projectile_StoreAimedArcVelocity
                neg.l   d0
; Store the selected horizontal direction and randomized arc velocity
Projectile_StoreAimedArcVelocity:                       ; was: loc_2B878
                move.l  d0,$18(a1)
                move.w  #$FFFA,$1C(a1)
                move.w  (RandomNumberState).w,$1E(a1)
Projectile_SpawnAimedArcFromEnemy_Return:               ; was: locret_2B888
                rts
; End of function Projectile_SpawnAimedArcFromEnemy
; Apply gravity to type $84 and bounce or deflect it on impact
Projectile_UpdateGravityBounceType84:                   ; was: sub_2B88A
                addi.l  #$3000,$1C(a5)
                btst    #7,$22(a5)
                beq.s   Projectile_UpdateGravityBounceType84_CheckTerrain
                btst    #4,$22(a5)
                beq.w   Projectile_UpdateGravityBounceType84_BounceAndConvertToType88
                jmp     Projectile_FragmentBeginDeflectedFall
; ---------------------------------------------------------------------------
Projectile_UpdateGravityBounceType84_CheckTerrain:      ; was: loc_2B8AA
                jsr     (Collision_GetEntityPosition).l
                beq.s   Projectile_UpdateGravityBounceType84_Return
                cmpi.w  #2,d2
                bne.s   Projectile_UpdateGravityBounceType84_BounceAndConvertToType88
                tst.l   $1C(a5)
                bpl.s   Projectile_UpdateGravityBounceType84_BounceAndConvertToType88
Projectile_UpdateGravityBounceType84_Return:            ; was: locret_2B8BE
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateGravityBounceType84_BounceAndConvertToType88:  ; was: loc_2B8C0
                                        ; Projectile_UpdateGravityBounceType84+2C   j
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                move.l  #$FFFEC000,$1C(a5)
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                jmp     Projectile_InitType88FromCurrent
; End of function Projectile_UpdateGravityBounceType84
; Spawn a type-$1D0 arc hazard with the caller's horizontal velocity
Projectile_SpawnTrailingArcHazardType1D0:               ; was: sub_2B8E0
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_SpawnTrailingArcHazardType1D0_Return
                add.w   $10(a5),d5
                add.w   $14(a5),d6
                move.w  d5,$10(a0)
                move.w  d6,$14(a0)
                move.w  #$1D0,(a0)
                move.w  #$EF00,2(a0)
                move.w  #$C80,$E(a0)
                move.l  #SharedCombatSpriteAnimation22,8(a0)
                move.b  #$3C,$20(a0)                    ; '<'
                move.w  #$18,$26(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.b  #$80,$23(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.l  d7,$18(a0)
                move.l  #$FFFFA000,$1C(a0)
Projectile_SpawnTrailingArcHazardType1D0_Return:        ; was: locret_2B93C
                rts
; End of function Projectile_SpawnTrailingArcHazardType1D0
; Update type $1D0, emitting a trail until impact converts it to type $88
Projectile_UpdateTrailingArcHazardType1D0:              ; was: sub_2B93E
                addq.w  #1,$48(a5)
                move.w  $48(a5),d0
                andi.w  #3,d0
                bne.s   Projectile_UpdateTrailingArcHazardType1D0_ApplyGravityAndCheckImpact
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_UpdateTrailingArcHazardType1D0_ApplyGravityAndCheckImpact
                move.l  #SharedCombatSpriteAnimation08,8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  (RandomNumberState).w,d0
                andi.b  #7,d0
                subq.w  #4,d0
                add.w   d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.b  #7,d0
                subq.w  #4,d0
                add.w   d0,$14(a0)
                move.w  #7,$48(a0)
                jsr     (Effect_SpawnExplosionType188).l
Projectile_UpdateTrailingArcHazardType1D0_ApplyGravityAndCheckImpact:  ; was: loc_2B990
                                        ; Projectile_UpdateTrailingArcHazardType1D0+14   j
                addi.l  #$3800,$1C(a5)
                btst    #7,$22(a5)
                bne.s   Projectile_UpdateTrailingArcHazardType1D0_ConvertToType88
                jsr     (Collision_GetEntityPosition).l
                bne.s   Projectile_UpdateTrailingArcHazardType1D0_ConvertToType88
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateTrailingArcHazardType1D0_ConvertToType88:  ; was: loc_2B9AA
                                        ; Projectile_UpdateTrailingArcHazardType1D0+68   j
                clr.l   $18(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.l  #SharedCombatSpriteAnimation05,8(a5)
                jmp     Projectile_InitType88FromCurrent
; End of function Projectile_UpdateTrailingArcHazardType1D0
; Update type-$104 controller and emit type-$108 hazards from above the screen
Hazard_UpdateTopFallingSpawnerType104:                  ; was: sub_2B9C4
                tst.w   (StageSpawnCountdown).w
                bmi.s   Hazard_UpdateTopFallingSpawnerType104_Tick
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Hazard_UpdateTopFallingSpawnerType104_Tick:             ; was: loc_2B9D2
                subq.w  #1,$48(a5)
                bpl.s   Hazard_UpdateTopFallingSpawnerType104_Return
                lea     Hazard_TopFallingSpawnerDifficultyBaseDelays(pc),a0
                nop
                move.w  (DifficultyMode).w,d1
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                add.w   (a0,d1.w),d0
                move.w  d0,$48(a5)
                jsr     (Sprite_FindFreeEffectSlot).l
                bne.s   Hazard_UpdateTopFallingSpawnerType104_Return
                move.w  #$108,(a0)
                move.w  #$8F80,2(a0)
                move.w  #$C4C8,$E(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                move.b  #$10,$20(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FC04FC04,$28(a0)
                move.w  #$64,$26(a0)                    ; 'd'
                move.l  #Stage3ResampleBuffer,$18(a0)
                move.w  #3,$1C(a0)
                move.w  #$A0,$14(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addi.w  #$120,d0
                move.w  d0,$10(a0)
                moveq   #0,d0
Hazard_UpdateTopFallingSpawnerType104_Return:           ; was: locret_2BA56
                                        ; Hazard_UpdateTopFallingSpawnerType104+34   j
                rts
; End of function Hazard_UpdateTopFallingSpawnerType104
; ---------------------------------------------------------------------------
Hazard_TopFallingSpawnerDifficultyBaseDelays:   dc.w    $40, $28, $10  ; was: word_2BA58

; Update a type-$108 falling hazard and resolve terrain or deflection impact
Projectile_UpdateTopFallingHazardType108:               ; was: sub_2BA5E
                tst.w   (StageSpawnCountdown).w
                bmi.s   Projectile_UpdateTopFallingHazardType108_CheckTerrain
Projectile_UpdateTopFallingHazardType108_ConvertToType88:  ; was: loc_2BA64
                move.l  #SharedCombatSpriteAnimation02,8(a5)
                move.l  #$FFFF0000,$1C(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_UpdateTopFallingHazardType108_CheckTerrain:  ; was: loc_2BA7A
                jsr     (Collision_GetEntityPosition).l
                beq.s   Projectile_UpdateTopFallingHazardType108_CheckDeflection
                clr.l   $18(a5)
                move.l  #$FFFF0000,$1C(a5)
                move.w  #$62,$26(a5)                    ; 'b'
                jmp     Effect_InitSharedExplosionFromCurrent
; ---------------------------------------------------------------------------
Projectile_UpdateTopFallingHazardType108_CheckDeflection:  ; was: loc_2BA9A
                btst    #7,$22(a5)
                beq.s   Projectile_UpdateTopFallingHazardType108_Return
                btst    #4,$22(a5)
                beq.w   Projectile_UpdateTopFallingHazardType108_ConvertToType88
                jmp     Projectile_FragmentBeginDeflectedFall
; ---------------------------------------------------------------------------
Projectile_UpdateTopFallingHazardType108_Return:        ; was: locret_2BAB2
                rts
; End of function Projectile_UpdateTopFallingHazardType108
