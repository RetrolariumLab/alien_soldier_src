; Sniper Honeyviper projectile spawning and update handlers

; Spawns Sniper Honeyviper's oscillating shot at a frame-counter interval
Boss_SniperHoneyviperSpawnOscillatingShot:              ; was: sub_371E8
                move.w  (FrameCounter).w,d0
                andi.w  #$1F,d0
                bne.w   Boss_SniperHoneyviperSpawnOscillatingShotReturn
                movea.w #(FortySixthEntityType-M68K_RAM),a0
                tst.w   (DifficultyMode).w
                bne.s   Boss_SniperHoneyviperSpawnOscillatingShotUseEnemySlots
                jsr     (Projectile_FindFreeSlotForward4).l
                beq.s   Boss_SniperHoneyviperSpawnOscillatingShotInitialize
                rts
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperSpawnOscillatingShotUseEnemySlots:  ; was: loc_37208
                jsr     (Projectile_FindFreeSlotForward8).l
                bne.s   Boss_SniperHoneyviperSpawnOscillatingShotReturn
Boss_SniperHoneyviperSpawnOscillatingShotInitialize:    ; was: loc_37210
                move.w  #$98,(a0)
                move.w  #$8D80,2(a0)
                clr.w   $24(a0)
                move.w  #$E3E8,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.b  #8,$20(a0)
                move.b  #$84,$21(a0)
                move.l  #$F808F808,$28(a0)
                movea.w #(Entity_ObjectPool-M68K_RAM),a1
                move.w  $10(a1),$10(a0)
                addi.w  #-8,$10(a0)
                move.w  $14(a1),$14(a0)
                addi.w  #-$24,$14(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                addi.w  #$60,d0                         ; '`'
                move.w  d0,$48(a0)
                move.w  d0,$4A(a0)
Boss_SniperHoneyviperSpawnOscillatingShotReturn:        ; was: locret_37274
                                        ; Boss_SniperHoneyviperSpawnOscillatingShot+26   j
                rts
; End of function Boss_SniperHoneyviperSpawnOscillatingShot
; Updates Sniper Honeyviper's oscillating shot, then emits its terminal projectile burst
Projectile_SniperHoneyviperOscillatingShot:             ; was: sub_37276
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$1AD8,d0
                bpl.s   Projectile_SniperHoneyviperOscillatingShotUpdate
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_SniperHoneyviperOscillatingShotUpdate:       ; was: loc_3728C
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_SniperHoneyviperOscillatingShotBurst
                tst.w   $24(a5)
                bpl.s   Projectile_SniperHoneyviperOscillatingShotSteer
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_SniperHoneyviperOscillatingShotBurst
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$8004,d2
                jsr     (Projectile_InitializeAimedDelayedCollisionShot).l
Projectile_SniperHoneyviperOscillatingShotBurst:        ; was: loc_372B6
                                        ; Projectile_SniperHoneyviperOscillatingShot+28   j
                clr.l   $18(a5)
                clr.l   $1C(a5)
                jmp     Enemy_SpawnQuadProjectiles
; ---------------------------------------------------------------------------
Projectile_SniperHoneyviperOscillatingShotSteer:        ; was: loc_372C4
                addq.w  #1,$4A(a5)
                move.w  #$E3E8,$E(a5)
                move.w  #$A00,8(a5)
                move.w  #$F4F4,$A(a5)
                btst    #1,$4B(a5)
                bne.s   Projectile_SniperHoneyviperOscillatingShotChooseVelocity
                move.w  #$E3F1,$E(a5)
                move.w  #$900,8(a5)
                move.w  #$F4FA,$A(a5)
Projectile_SniperHoneyviperOscillatingShotChooseVelocity:  ; was: loc_372F4
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d1
                andi.w  #$1FFF,d1
                addi.w  #$1000,d1
                ext.l   d1
                move.w  $4A(a5),d3
                andi.w  #$7F,d3
                move.w  (RandomNumberState).w,d2
                andi.w  #$3F,d2                         ; '?'
                add.w   d3,d2
                add.w   (PrimaryEntityYPos).w,d2
                subi.w  #$90,d2
                move.l  #$20000,$1C(a5)
                cmp.w   $14(a5),d2
                bpl.s   Projectile_SniperHoneyviperOscillatingShotSteerHorizontal
                neg.l   $1C(a5)
Projectile_SniperHoneyviperOscillatingShotSteerHorizontal:  ; was: loc_37334
                tst.w   $48(a5)
                bmi.s   Projectile_SniperHoneyviperOscillatingShotAccelerateLeft
                subq.w  #1,$48(a5)
                move.w  (PrimaryEntityXPos).w,d0
                cmp.w   $10(a5),d0
                bpl.s   Projectile_SniperHoneyviperOscillatingShotAccelerateRight
Projectile_SniperHoneyviperOscillatingShotAccelerateLeft:  ; was: loc_37348
                tst.w   $18(a5)
                bpl.s   Projectile_SniperHoneyviperOscillatingShotApplyLeftAcceleration
                cmpi.w  #$FFFE,$18(a5)
                bmi.s   Projectile_SniperHoneyviperOscillatingShotReturn
Projectile_SniperHoneyviperOscillatingShotApplyLeftAcceleration:  ; was: loc_37356
                sub.l   d1,$18(a5)
Projectile_SniperHoneyviperOscillatingShotReturn:       ; was: locret_3735A
                                        ; Projectile_SniperHoneyviperOscillatingShot+F2   j
                rts
; ---------------------------------------------------------------------------
Projectile_SniperHoneyviperOscillatingShotAccelerateRight:  ; was: loc_3735C
                tst.w   $18(a5)
                bmi.s   Projectile_SniperHoneyviperOscillatingShotApplyRightAcceleration
                cmpi.w  #4,$18(a5)
                bpl.s   Projectile_SniperHoneyviperOscillatingShotReturn
Projectile_SniperHoneyviperOscillatingShotApplyRightAcceleration:  ; was: loc_3736A
                add.l   d1,$18(a5)
                rts
; End of function Projectile_SniperHoneyviperOscillatingShot
; Spawns four projectiles in circular pattern with angle calculation
Boss_SniperHoneyviperSpawnCircleShot:                   ; was: sub_37370
                moveq   #0,d5
                moveq   #$FFFFFFE0,d6
                moveq   #3,d7
Boss_SniperHoneyviperSpawnCircleShotNext:               ; was: loc_37376
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_SniperHoneyviperSpawnCircleShotReturn
                move.w  #$35C,(a0)
                move.w  #$8D00,2(a0)
                move.w  d6,d0
                addi.w  #$20,d6                         ; ' '
                add.w   $430(a5),d0
                move.w  d0,$10(a0)
                move.w  $434(a5),$14(a0)
                move.b  #$C0,$21(a0)
                move.b  #$10,$23(a0)
                move.l  #$F808F808,$2C(a0)
                move.l  #$F010F010,$28(a0)
                move.w  Boss_SniperHoneyviperCircleShotObjectParameters(pc,d5.w),$E(a0)
                move.w  Boss_SniperHoneyviperCircleShotObjectParameters+2(pc,d5.w),8(a0)
                move.w  Boss_SniperHoneyviperCircleShotObjectParameters+4(pc,d5.w),$A(a0)
                move.w  Boss_SniperHoneyviperCircleShotObjectParameters+6(pc,d5.w),$26(a0)
                addq.w  #8,d5
                lea     (Math_SineTable).l,a1
                move.w  (RandomNumberState).w,d0
                andi.w  #$3E,d0                         ; '>'
                subi.w  #$20,d0                         ; ' '
                addi.w  #$160,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   #4,d1
                asl.l   #4,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                movem.l d5-d7,-(sp)
                jsr     (RandomNumber).l
                movem.l (sp)+,d5-d7
                dbf     d7,Boss_SniperHoneyviperSpawnCircleShotNext
Boss_SniperHoneyviperSpawnCircleShotReturn:             ; was: locret_37414
                rts
; End of function Boss_SniperHoneyviperSpawnCircleShot
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperCircleShotObjectParameters:    dc.w    $A3F7, $A00, $F4F4, $7A, $A410, $500, $F8F8, $3D, $A400, $F00, $F0F0, $F4, $A410, $500, $F8F8, $3D  ; was: word_37416
                                        ; Boss_SniperHoneyviperSpawnCircleShot+50   r

; Updates Sniper Honeyviper's rotating bouncing shot and converts it to debris on impact
Projectile_SniperHoneyviperBouncingShot:                ; was: sub_37436
                tst.w   (StageSpawnCountdown).w
                bpl.w   Projectile_SniperHoneyviperBouncingShotConvertToDebris
                moveq   #1,d1
                tst.w   $18(a5)
                bmi.s   Projectile_SniperHoneyviperBouncingShotUpdateRotation
                moveq   #$FFFFFFFF,d1
Projectile_SniperHoneyviperBouncingShotUpdateRotation:  ; was: loc_37448
                add.w   d1,$48(a5)
                move.w  $48(a5),d0
                asr.w   #1,d0
                andi.w  #6,d0
                andi.w  #$E7FF,$E(a5)
                lea     (SpriteFlipBitsTable).l,a0
                move.w  (a0,d0.w),d0
                or.w    d0,$E(a5)
                bclr    #7,$22(a5)
                beq.s   Projectile_SniperHoneyviperBouncingShotApplyGravity
                bclr    #4,$22(a5)
                beq.s   Projectile_SniperHoneyviperBouncingShotConvertToDebris
                clr.b   $21(a5)
                move.l  $18(a5),d0
                neg.l   d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                move.w  #$FFFD,$1C(a5)
Projectile_SniperHoneyviperBouncingShotApplyGravity:    ; was: loc_37490
                addi.l  #$1000,$1C(a5)
                bmi.s   Projectile_SniperHoneyviperBouncingShotReturn
                moveq   #0,d0
                moveq   #7,d1
                jsr     (Physics_AddEntityOffset).l
                beq.s   Projectile_SniperHoneyviperBouncingShotReturn
Projectile_SniperHoneyviperBouncingShotConvertToDebris:  ; was: loc_374A6
                                        ; Projectile_SniperHoneyviperBouncingShot+42   j
                move.w  #$FFFD,$1C(a5)
                move.l  $18(a5),d0
                asr.l   #2,d0
                move.l  d0,$18(a5)
                move.l  #Effect_SpriteAnimation00,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_SniperHoneyviperBouncingShotReturn:          ; was: locret_374C4
                                        ; Projectile_SniperHoneyviperBouncingShot+6E   j
                rts
; End of function Projectile_SniperHoneyviperBouncingShot
