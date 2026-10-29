; Find a free record in the enemy projectile-pool range
Projectile_FindFreeEnemyPoolSlot:                       ; was: sub_2AFBE
                movea.w #(EighteenthEntityType-M68K_RAM),a0
                jmp     Projectile_FindFreeSlotForward8
; End of function Projectile_FindFreeEnemyPoolSlot
; Allocate a record and dispatch one of the two type-$148 initializers by d1
; No static caller of this selector is currently known
Projectile_AllocateSelectedTwoSpeedShot:                ; was: sub_2AFC8
                bsr.w   Projectile_FindFreeEnemyPoolSlot
                bne.s   Projectile_AllocateSelectedTwoSpeedShotReturn
                movea.l Projectile_TwoSpeedShotInitializerTable(pc,d1.w),a1
                jmp     (a1)
; ---------------------------------------------------------------------------
Projectile_AllocateSelectedTwoSpeedShotReturn:          ; was: locret_2AFD4
                rts
; End of function Projectile_AllocateSelectedTwoSpeedShot
; ---------------------------------------------------------------------------
Projectile_TwoSpeedShotInitializerTable:    dc.l    Projectile_InitializeDifficultyScaledTwoSpeedShot  ; was: off_2AFD6
                dc.l    Projectile_InitializeJetsripperTwoSpeedShot

; Initialize a type-$50 shot with a quantized direction and owner-relative origin
Projectile_InitializeEightDirectionShot:                ; was: sub_2AFDE
                move.w  #$50,(a0)                       ; 'P'
                move.w  d0,$48(a0)
                move.w  #1,$4A(a0)
                move.w  #$8100,2(a0)
                add.w   $10(a5),d1
                move.w  d1,$10(a0)
                add.w   $14(a5),d2
                move.w  d2,$14(a0)
                addq.w  #8,d0
                andi.w  #$70,d0                         ; 'p'
                asr.w   #3,d0
                move.w  Projectile_EightDirectionInitialFrameTable(pc,d0.w),$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.w  (GlobalSpritePriorityBit).w,d0
                andi.w  #$8000,d0
                or.w    d0,$E(a0)
                rts
; End of function Projectile_InitializeEightDirectionShot
; ---------------------------------------------------------------------------
Projectile_EightDirectionInitialFrameTable: dc.w    $4CD6, $5CDF, $54E8, $54DF, $44D6, $44DF, $44E8, $4CDF  ; was: word_2B02A

; After the one-tick staging delay, assign velocity and convert type $50 to $4C
Projectile_ActivateEightDirectionShot:                  ; was: sub_2B03A
                subq.w  #1,$4A(a5)
                bpl.s   Projectile_ActivateEightDirectionShotReturn
                move.w  #$4C,(a5)                       ; 'L'
                move.w  #$8D00,2(a5)
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #$F808F808,$2C(a5)
                move.w  #$50,$26(a5)                    ; 'P'
                move.w  $48(a5),d0
                movea.l #Projectile_DirectionalVelocityWaveTable,a0
                move.l  (a0,d0.w),$1C(a5)
                move.l  $20(a0,d0.w),$18(a5)
                addq.w  #4,d0
                andi.w  #$78,d0                         ; 'x'
                asr.w   #2,d0
                move.w  Projectile_EightDirectionActiveFrameTable(pc,d0.w),$E(a5)
                move.w  #0,8(a5)
                move.w  #$FCFC,$A(a5)
                move.w  (GlobalSpritePriorityBit).w,d0
                andi.w  #$8000,d0
                or.w    d0,$E(a5)
Projectile_ActivateEightDirectionShotReturn:            ; was: locret_2B09A
                rts
; End of function Projectile_ActivateEightDirectionShot
; ---------------------------------------------------------------------------
Projectile_EightDirectionActiveFrameTable:  dc.w    $4CF1, $5CF2, $5CF3, $5CF4, $54F5, $54F4, $54F3, $54F2  ; was: word_2B09C
                dc.w    $44F1, $44F2, $44F3, $44F4, $44F5, $4CF4, $4CF3, $4CF2

; Retire a type-$4C shot at its bounds or resolve terrain/contact impact
Projectile_UpdateEightDirectionShotCollision:           ; was: sub_2B0BC
                cmpi.w  #$88,$10(a5)
                bmi.s   Projectile_RetireEightDirectionShot
                cmpi.w  #$1B8,$10(a5)
                bpl.s   Projectile_RetireEightDirectionShot
                cmpi.w  #$A8,$14(a5)
                bmi.s   Projectile_RetireEightDirectionShot
                cmpi.w  #$158,$14(a5)
                bmi.s   Projectile_CheckEightDirectionShotImpact
Projectile_RetireEightDirectionShot:                    ; was: loc_2B0DC
                                        ; Projectile_UpdateEightDirectionShotCollision+E   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_CheckEightDirectionShotImpact:               ; was: loc_2B0E4
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ConvertEightDirectionShotToPickup
                btst    #7,$22(a5)
                beq.s   Projectile_CheckEightDirectionShotTerrain
                btst    #4,$22(a5)
                beq.s   Projectile_DeactivateEightDirectionShot
Projectile_ConvertEightDirectionShotToPickup:           ; was: loc_2B0FA
                jsr     (Pickup_SpawnSmallFromCurrentObject).l
                bra.s   Projectile_SpawnEightDirectionShotImpact
; ---------------------------------------------------------------------------
Projectile_CheckEightDirectionShotTerrain:              ; was: loc_2B102
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                jsr     (Collision_CheckTerrainTile).l
                bne.s   Projectile_DeactivateEightDirectionShot
Projectile_EightDirectionShotReturn:                    ; was: locret_2B112
                rts
; ---------------------------------------------------------------------------
Projectile_DeactivateEightDirectionShot:                ; was: loc_2B114
                                        ; Projectile_UpdateEightDirectionShotCollision+54   j
                bset    #4,2(a5)
Projectile_SpawnEightDirectionShotImpact:               ; was: loc_2B11A
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_EightDirectionShotReturn
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3C,d0                         ; '<'
                add.w   $48(a5),d0
                subi.w  #$5C,d0                         ; '\'
                andi.w  #$7C,d0                         ; '|'
                movea.l #Projectile_DirectionalVelocityWaveTable,a1
                move.l  (a1,d0.w),d1
                move.l  $20(a1,d0.w),d2
                asr.l   #2,d1
                asr.l   #2,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                movea.l #Effect_KnockbackImpactSpriteFrames,a1
                bra.w   Sprite_InitFromTable
; End of function Projectile_UpdateEightDirectionShotCollision
; ---------------------------------------------------------------------------
; Signed velocity wave; the second component is read eight longwords ahead
Projectile_DirectionalVelocityWaveTable:    dc.l    0, $1C170  ; was: dword_2B166
                                        ; Projectile_UpdateEightDirectionShotCollision+86   o
                dc.l    $37194, $4FFF8
                dc.l    $65D24, $77B98
                dc.l    $85080, $8D3B4
                dc.l    $90000, $8D3B4
                dc.l    $85080, $77B98
                dc.l    $65D24, $4FFF8
                dc.l    $37194, $1C170
                dc.l    $FFFFFFDC, $FFFE3E90
                dc.l    $FFFC8E6C, $FFFB0008
                dc.l    $FFF9A2DC, $FFF88468
                dc.l    $FFF7AF80, $FFF72C4C
                dc.l    $FFF70000, $FFF72C4C
                dc.l    $FFF7AF80, $FFF88468
                dc.l    $FFF9A2DC, $FFFB0008
                dc.l    $FFFC8E6C, $FFFE3E90
                dc.l    0, $1C170
                dc.l    $37194, $4FFF8
                dc.l    $65D24, $77B98
                dc.l    $85080, $8D3B4

; Select normal/hard speed, then initialize a type-$148 two-speed shot
Projectile_InitializeDifficultyScaledTwoSpeedShot:      ; was: sub_2B206
                                        ; Enemy_Stage11FishFireVolleyState+48   p
                moveq   #$A,d7
                tst.w   (DifficultyMode).w
                beq.s   Projectile_InitializeTwoSpeedShot
                moveq   #$B,d7
; Initialize a type-$148 shot at quarter speed for three ticks, then full speed
Projectile_InitializeTwoSpeedShot:                      ; was: loc_2B210
                                        ; Enemy_SpawnTrackedProjectile+32   j
                move.w  #$148,(a0)
                move.w  #$ED00,2(a0)
                clr.w   4(a0)
                move.w  #$32,$26(a0)                    ; '2'
                move.w  d2,d3
                andi.w  #$8000,d2
                andi.w  #$FF,d3
                addi.w  #$480,d2
                move.w  d2,$E(a0)
                move.b  d3,$20(a0)
                move.l  #SharedCombatSpriteAnimation12,8(a0)
                clr.w   $C(a0)
                clr.b   $21(a0)
                clr.b   $23(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                add.w   d0,$10(a0)
                add.w   d1,$14(a0)
                move.w  #3,$48(a0)
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d6.w),d1
                move.w  (a1,d6.w),d2
                muls.w  d7,d1
                muls.w  d7,d2
                move.l  d1,$54(a0)
                move.l  d2,$50(a0)
                asr.l   #2,d1
                asr.l   #2,d2
                move.l  d2,$18(a0)
                move.l  d1,$1C(a0)
                rts
; End of function Projectile_InitializeDifficultyScaledTwoSpeedShot
; Advance a type-$148 shot to full speed, then resolve bounds and impact
Projectile_UpdateTwoSpeedShotCollision:                 ; was: sub_2B298
                cmpi.w  #$70,$10(a5)                    ; 'p'
                bmi.s   Projectile_RetireTwoSpeedShot
                cmpi.w  #$1D0,$10(a5)
                bpl.s   Projectile_RetireTwoSpeedShot
                cmpi.w  #$A8,$14(a5)
                bmi.s   Projectile_RetireTwoSpeedShot
                cmpi.w  #$158,$14(a5)
                bmi.s   Projectile_UpdateTwoSpeedShotPhase
Projectile_RetireTwoSpeedShot:                          ; was: loc_2B2B8
                                        ; Projectile_UpdateTwoSpeedShotCollision+E   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateTwoSpeedShotPhase:                     ; was: loc_2B2C0
                tst.w   4(a5)
                bne.s   Projectile_CheckTwoSpeedShotImpact
                subq.w  #1,$48(a5)
                bpl.s   Projectile_TwoSpeedShotReturn
                addq.w  #2,4(a5)
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #SharedCombatSpriteAnimation24,8(a5)
                clr.w   $C(a5)
                move.l  $50(a5),$18(a5)
                move.l  $54(a5),$1C(a5)
Projectile_TwoSpeedShotReturn:                          ; was: locret_2B2EE
                                        ; Projectile_UpdateTwoSpeedShotCollision+7C   j
                rts
; ---------------------------------------------------------------------------
Projectile_CheckTwoSpeedShotImpact:                     ; was: loc_2B2F0
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ConvertTwoSpeedShotToPickup
                btst    #7,$22(a5)
                beq.s   Projectile_CheckTwoSpeedShotTerrain
                btst    #4,$22(a5)
                beq.s   Projectile_DeactivateTwoSpeedShot
Projectile_ConvertTwoSpeedShotToPickup:                 ; was: loc_2B306
                jsr     (Pickup_SpawnSmallFromCurrentObject).l
                bra.s   Projectile_SpawnTwoSpeedShotImpact
; ---------------------------------------------------------------------------
Projectile_CheckTwoSpeedShotTerrain:                    ; was: loc_2B30E
                jsr     (Collision_CheckProjectileTile).l
                beq.s   Projectile_TwoSpeedShotReturn
Projectile_DeactivateTwoSpeedShot:                      ; was: loc_2B316
                bset    #4,2(a5)
Projectile_SpawnTwoSpeedShotImpact:                     ; was: loc_2B31C
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_TwoSpeedShotReturn
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $1C(a5),d1
                move.l  $18(a5),d2
                asr.l   #1,d1
                asr.l   #1,d2
                neg.l   d1
                neg.l   d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                movea.l #Weapon_ImpactSpriteFrames,a1
                bra.w   Sprite_InitFromTable
; End of function Projectile_UpdateTwoSpeedShotCollision
; Initialize the Jetsripper type-$148 variant with its lower speed pair
Projectile_InitializeJetsripperTwoSpeedShot:            ; was: sub_2B352
                moveq   #9,d7
                tst.w   (DifficultyMode).w
                beq.s   Projectile_ApplyJetsripperTwoSpeedShotParameters
                moveq   #$A,d7
Projectile_ApplyJetsripperTwoSpeedShotParameters:       ; was: loc_2B35C
                move.w  #$148,(a0)
                move.w  #$ED00,2(a0)
                clr.w   4(a0)
                move.w  #$32,$26(a0)                    ; '2'
                move.w  d2,d3
                andi.w  #$8000,d2
                andi.w  #$FF,d3
                addi.w  #$480,d2
                move.w  d2,$E(a0)
                move.b  d3,$20(a0)
                move.l  #SharedCombatSpriteAnimation12,8(a0)
                clr.w   $C(a0)
                clr.b   $21(a0)
                clr.b   $23(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                add.w   d0,$10(a0)
                add.w   d1,$14(a0)
                move.w  #3,$48(a0)
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d6.w),d1
                move.w  (a1,d6.w),d2
                muls.w  d7,d1
                muls.w  d7,d2
                move.l  d1,$54(a0)
                move.l  d2,$50(a0)
                asr.l   #2,d1
                asr.l   #2,d2
                move.l  d2,$18(a0)
                move.l  d1,$1C(a0)
                rts
; End of function Projectile_InitializeJetsripperTwoSpeedShot
; Type-$254 object-table handler; no static producer currently identifies its owner
; Its body duplicates the type-$148 two-speed collision lifecycle above
Projectile_UpdateType254TwoSpeedShotCollision:          ; was: sub_2B3E4
                cmpi.w  #$70,$10(a5)                    ; 'p'
                bmi.s   Projectile_RetireType254TwoSpeedShot
                cmpi.w  #$1D0,$10(a5)
                bpl.s   Projectile_RetireType254TwoSpeedShot
                cmpi.w  #$A8,$14(a5)
                bmi.s   Projectile_RetireType254TwoSpeedShot
                cmpi.w  #$158,$14(a5)
                bmi.s   Projectile_UpdateType254TwoSpeedShotPhase
Projectile_RetireType254TwoSpeedShot:                   ; was: loc_2B404
                                        ; Projectile_UpdateType254TwoSpeedShotCollision+E   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateType254TwoSpeedShotPhase:              ; was: loc_2B40C
                tst.w   4(a5)
                bne.s   Projectile_CheckType254TwoSpeedShotImpact
                subq.w  #1,$48(a5)
                bpl.s   Projectile_Type254TwoSpeedShotReturn
                addq.w  #2,4(a5)
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #SharedCombatSpriteAnimation24,8(a5)
                clr.w   $C(a5)
                move.l  $50(a5),$18(a5)
                move.l  $54(a5),$1C(a5)
Projectile_Type254TwoSpeedShotReturn:                   ; was: locret_2B43A
                                        ; Projectile_UpdateType254TwoSpeedShotCollision+7C   j
                rts
; ---------------------------------------------------------------------------
Projectile_CheckType254TwoSpeedShotImpact:              ; was: loc_2B43C
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ConvertType254TwoSpeedShotToPickup
                btst    #7,$22(a5)
                beq.s   Projectile_CheckType254TwoSpeedShotTerrain
                btst    #4,$22(a5)
                beq.s   Projectile_DeactivateType254TwoSpeedShot
Projectile_ConvertType254TwoSpeedShotToPickup:          ; was: loc_2B452
                jsr     (Pickup_SpawnSmallFromCurrentObject).l
                bra.s   Projectile_SpawnType254TwoSpeedShotImpact
; ---------------------------------------------------------------------------
Projectile_CheckType254TwoSpeedShotTerrain:             ; was: loc_2B45A
                jsr     (Collision_CheckProjectileTile).l
                beq.s   Projectile_Type254TwoSpeedShotReturn
Projectile_DeactivateType254TwoSpeedShot:               ; was: loc_2B462
                bset    #4,2(a5)
Projectile_SpawnType254TwoSpeedShotImpact:              ; was: loc_2B468
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_Type254TwoSpeedShotReturn
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $1C(a5),d1
                move.l  $18(a5),d2
                asr.l   #1,d1
                asr.l   #1,d2
                neg.l   d1
                neg.l   d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                movea.l #Weapon_ImpactSpriteFrames,a1
                bra.w   Sprite_InitFromTable
; End of function Projectile_UpdateType254TwoSpeedShotCollision
; Allocate one Destroyer-Mk2 projected shot at (d3,d4)
Boss_DestroyerMk2SpawnProjectedShot:                    ; was: sub_2B49E
                                        ; Boss_DestroyerMk2EmitFourProjectedEffects+46   p
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_DestroyerMk2ProjectedShotSpawnReturn
                move.w  d3,$10(a0)
                move.w  d4,$14(a0)
                movea.l Projectile_DelayedCollisionShotDescriptorTable(pc,d1.w),a4
                bra.s   Projectile_InitializeDelayedCollisionShotFromDescriptor
; ---------------------------------------------------------------------------
Boss_DestroyerMk2ProjectedShotSpawnReturn:              ; was: locret_2B4B4
                rts
; End of function Boss_DestroyerMk2SpawnProjectedShot
; ---------------------------------------------------------------------------
Projectile_DelayedCollisionShotDescriptorTable: dc.l    Projectile_AimedDelayedCollisionShotDescriptor  ; was: off_2B4B6
                dc.l    Projectile_FixedAngleDelayedCollisionShotDescriptor

; Initialize the aimed delayed-collision-shot descriptor
Projectile_InitializeAimedDelayedCollisionShot:         ; was: sub_2B4BE
                                        ; Projectile_SniperHoneyviperOscillatingShot+3A   p
                lea     Projectile_AimedDelayedCollisionShotDescriptor(pc),a4
                nop
Projectile_InitializeDelayedCollisionShotFromDescriptor:  ; was: loc_2B4C4
                move.w  (a4)+,$26(a0)
                move.w  (a4)+,d7
                move.l  (a4)+,8(a0)
                move.l  (a4)+,$50(a0)
                move.w  #$17C,(a0)
                move.w  #$E180,2(a0)
                move.w  d2,d3
                andi.w  #$8000,d2
                andi.w  #$FF,d3
                addi.w  #$480,d2
                move.w  d2,$E(a0)
                move.b  d3,$20(a0)
                clr.w   $C(a0)
                clr.b   $21(a0)
                clr.b   $23(a0)
                tst.w   (a4)+
                bne.s   Projectile_InitializeDelayedCollisionShotVelocity
                jsr     (Math_CalculateAngleBetween).l
                move.w  d2,d6
Projectile_InitializeDelayedCollisionShotVelocity:      ; was: loc_2B50A
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d6.w),d0
                move.w  (a1,d6.w),d1
                muls.w  d7,d0
                muls.w  d7,d1
                move.l  d0,$1C(a0)
                move.l  d1,$18(a0)
                rts
; End of function Projectile_InitializeAimedDelayedCollisionShot
; ---------------------------------------------------------------------------
; Record: collision field, speed, initial animation, armed animation, angle mode
Projectile_AimedDelayedCollisionShotDescriptor: dc.w    $37  ; field_0  ; was: stru_2B526
                                        ; sub_2B4BE   o
                dc.w    9                               ; field_2
                dc.l    SharedCombatSpriteAnimation06   ; field_4
                dc.l    SharedCombatSpriteAnimation16   ; field_8
                dc.w    0                               ; field_C
Projectile_FixedAngleDelayedCollisionShotDescriptor:    dc.w    $38  ; field_0  ; was: stru_2B534
                dc.w    $A                              ; field_2
                dc.l    SharedCombatSpriteAnimation06   ; field_4
                dc.l    SharedCombatSpriteAnimation16   ; field_8
                dc.w    1                               ; field_C

; Arm a type-$17C shot when its initial animation completes, then test impact
Projectile_UpdateDelayedCollisionShot:                  ; was: sub_2B542
                tst.w   4(a5)
                bne.s   Projectile_UpdateArmedDelayedCollisionShot
                cmpi.w  #$80,$C(a5)
                bmi.s   Projectile_DelayedCollisionShotReturn
                addq.w  #2,4(a5)
                move.w  #$ED80,2(a5)
                move.l  $50(a5),8(a5)
                clr.w   $C(a5)
                move.b  #$40,$21(a5)                    ; '@'
Projectile_DelayedCollisionShotReturn:                  ; was: locret_2B56A
                                        ; Projectile_UpdateDelayedCollisionShot+88   j
                rts
; ---------------------------------------------------------------------------
Projectile_UpdateArmedDelayedCollisionShot:             ; was: loc_2B56C
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,d1
                subi.w  #$80,d0
                cmp.w   (CameraXLowerBound).w,d0
                bmi.s   Projectile_RetireDelayedCollisionShot
                subi.w  #$1C0,d1
                cmp.w   (CameraXUpperBound).w,d1
                bpl.s   Projectile_RetireDelayedCollisionShot
                cmpi.w  #$A0,$14(a5)
                bmi.s   Projectile_RetireDelayedCollisionShot
                cmpi.w  #$158,$14(a5)
                bmi.s   Projectile_CheckDelayedCollisionShotImpact
Projectile_RetireDelayedCollisionShot:                  ; was: loc_2B59A
                                        ; Projectile_UpdateDelayedCollisionShot+46   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_CheckDelayedCollisionShotImpact:             ; was: loc_2B5A2
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ConvertDelayedCollisionShotToPickup
                btst    #7,$22(a5)
                beq.s   Projectile_CheckDelayedCollisionShotTerrainDepth
                btst    #4,$22(a5)
                beq.s   Projectile_DeactivateDelayedCollisionShot
Projectile_ConvertDelayedCollisionShotToPickup:         ; was: loc_2B5B8
                jsr     (Pickup_SpawnSmallFromCurrentObject).l
                bra.s   Projectile_SpawnDelayedCollisionShotImpact
; ---------------------------------------------------------------------------
Projectile_CheckDelayedCollisionShotTerrainDepth:       ; was: loc_2B5C0
                jsr     (Collision_GetEntityPosition).l
                cmpi.w  #4,d2
                bmi.s   Projectile_DelayedCollisionShotReturn
Projectile_DeactivateDelayedCollisionShot:              ; was: loc_2B5CC
                bset    #4,2(a5)
Projectile_SpawnDelayedCollisionShotImpact:             ; was: loc_2B5D2
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_RetireDelayedCollisionShot
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $18(a5),d0
                move.l  $1C(a5),d1
                neg.l   d0
                neg.l   d1
                asr.l   #2,d0
                asr.l   #2,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                move.l  #SharedCombatSpriteAnimation01,8(a0)
                jmp     Sprite_InitType160
; End of function Projectile_UpdateDelayedCollisionShot
; Initialize Terobuster's type-$54 gravity shot with a randomized animation phase
Projectile_InitializeTerobusterGravityShot:             ; was: sub_2B60C
                move.w  #$54,(a0)                       ; 'T'
                move.w  #$8D40,2(a0)
                move.l  #Projectile_TerobusterGravityShotSpriteFrames,$48(a0)
                move.w  #1,$4C(a0)
                moveq   #0,d0
                move.w  (RandomNumberState).w,d0
                andi.w  #$18,d0
                add.l   d0,$48(a0)
                moveq   #0,d0
                move.w  d0,4(a0)
                move.b  d0,$21(a0)
                move.w  d0,$5E(a0)
                add.w   $10(a5),d1
                move.w  d1,$10(a0)
                add.w   $14(a5),d2
                move.w  d2,$14(a0)
                rts
; End of function Projectile_InitializeTerobusterGravityShot
; Update Terobuster's gravity shot and apply one horizontal terrain deflection
Projectile_UpdateTerobusterGravityShot:                 ; was: sub_2B652
                cmpi.w  #$80,$14(a5)
                bmi.s   Projectile_RetireTerobusterGravityShot
                cmpi.w  #$15C,$14(a5)
                bmi.s   Projectile_CheckTerobusterGravityShotTerrain
Projectile_RetireTerobusterGravityShot:                 ; was: loc_2B662
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_CheckTerobusterGravityShotTerrain:           ; was: loc_2B66A
                tst.w   $5E(a5)
                bne.s   Projectile_AnimateAndAccelerateTerobusterGravityShot
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                jsr     (Collision_CheckTerrainTile).l
                beq.s   Projectile_AnimateAndAccelerateTerobusterGravityShot
                addq.w  #1,$5E(a5)
                clr.l   $1C(a5)
                moveq   #0,d0
                move.w  (RandomNumberState).w,d0
                andi.w  #$FFFC,d0
                subi.w  #$6000,d0
                asl.l   #2,d0
                tst.w   $18(a5)
                bpl.s   Projectile_SetTerobusterGravityShotDeflection
                neg.l   d0
Projectile_SetTerobusterGravityShotDeflection:          ; was: loc_2B6A0
                move.l  d0,$18(a5)
Projectile_AnimateAndAccelerateTerobusterGravityShot:   ; was: loc_2B6A4
                                        ; Projectile_UpdateTerobusterGravityShot+2C   j
                bsr.w   Anim_UpdateLoopingScript
                addi.l  #$8000,$1C(a5)
                rts
; End of function Projectile_UpdateTerobusterGravityShot

; Select one of four projectile mappings from the quantized launch angle
Projectile_SelectWolfGaropaDirectionMapping:            ; was: sub_2B6B2
                addi.w  #$20,d2                         ; ' '
                andi.w  #$C0,d2
                asr.w   #4,d2
                move.l  Projectile_WolfGaropaDirectionMappings(pc,d2.w),8(a0)
                rts
; End of function Projectile_SelectWolfGaropaDirectionMapping
; ---------------------------------------------------------------------------
Projectile_WolfGaropaDirectionMappings: dc.l    SharedCombatSpriteFrame10  ; was: off_2B6C4
                dc.l    SharedCombatSpriteFrame11
                dc.l    SharedCombatSpriteFrame09
                dc.l    SharedCombatSpriteFrame12
