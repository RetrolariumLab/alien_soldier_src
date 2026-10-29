Projectile_TerobusterHomingMissileUpdate:               ; was: sub_38EA2
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   Projectile_TerobusterHomingMissileConvertToImpact
                btst    #7,$22(a5)
                bne.s   Projectile_TerobusterHomingMissileConvertToImpact
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_TerobusterHomingMissileConvertToImpact
                tst.w   $24(a5)
                bpl.s   Projectile_TerobusterHomingMissileUpdateFlight
Projectile_TerobusterHomingMissileConvertToImpact:      ; was: loc_38EC2
                                        ; Projectile_TerobusterHomingMissileUpdate+12   j
                neg.l   $18(a5)
                neg.l   $1C(a5)
                move.l  #Effect_SpriteAnimation02,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileUpdateFlight:         ; was: loc_38ED8
                lea     Projectile_TerobusterHomingMissileDirectionFrames(pc),a0
                nop
                move.w  $56(a5),d1
                subi.w  #$10,d1
                move.w  d1,d0
                asr.w   #2,d0
                andi.w  #$38,d0                         ; '8'
                move.w  (a0,d0.w),$E(a5)
                move.w  2(a0,d0.w),8(a5)
                move.w  4(a0,d0.w),$A(a5)
                andi.w  #$1FE,d1
                cmpi.w  #$100,d1
                bmi.s   Projectile_TerobusterHomingMissileTrySpawnTrail
                eori.w  #$1800,$E(a5)
Projectile_TerobusterHomingMissileTrySpawnTrail:        ; was: loc_38F10
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Projectile_TerobusterHomingMissileUpdateVelocity
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_TerobusterHomingMissileUpdateVelocity
                movea.l #Projectile_HomingAndRockSpriteFrames,a1
                jsr     (Sprite_InitTypeA4FromTable).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $18(a5),d0
                asl.l   #2,d0
                neg.l   d0
                add.l   d0,$10(a0)
                asr.l   #2,d0
                move.l  d0,$18(a0)
                move.l  $1C(a5),d0
                asl.l   #2,d0
                neg.l   d0
                add.l   d0,$14(a0)
                asr.l   #3,d0
                move.l  d0,$1C(a0)
Projectile_TerobusterHomingMissileUpdateVelocity:       ; was: loc_38F5E
                                        ; Projectile_TerobusterHomingMissileUpdate+7E   j
                lea     (Math_SineTable).l,a1
                move.w  d1,d0
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                move.l  d1,d3
                move.l  d2,d4
                asr.l   #1,d3
                asr.l   #1,d4
                asl.l   #4,d1
                asl.l   #4,d2
                tst.l   d1
                bpl.s   Projectile_TerobusterHomingMissileCheckVerticalVelocity
                cmp.l   $1C(a5),d1
                bpl.s   Projectile_TerobusterHomingMissileClampVerticalVelocity
                bra.s   Projectile_TerobusterHomingMissileAdjustVerticalVelocity
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileCheckVerticalVelocity:  ; was: loc_38F8A
                cmp.l   $1C(a5),d1
                bmi.s   Projectile_TerobusterHomingMissileClampVerticalVelocity
Projectile_TerobusterHomingMissileAdjustVerticalVelocity:  ; was: loc_38F90
                add.l   d3,$1C(a5)
                bra.s   Projectile_TerobusterHomingMissileUpdateHorizontalVelocity
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileClampVerticalVelocity:  ; was: loc_38F96
                                        ; Projectile_TerobusterHomingMissileUpdate+EC   j
                move.l  d1,$1C(a5)
Projectile_TerobusterHomingMissileUpdateHorizontalVelocity:  ; was: loc_38F9A
                tst.l   d2
                bpl.s   Projectile_TerobusterHomingMissileCheckHorizontalVelocity
                cmp.l   $18(a5),d2
                bpl.s   Projectile_TerobusterHomingMissileClampHorizontalVelocity
                bra.s   Projectile_TerobusterHomingMissileAdjustHorizontalVelocity
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileCheckHorizontalVelocity:  ; was: loc_38FA6
                cmp.l   $18(a5),d2
                bcs.s   Projectile_TerobusterHomingMissileClampHorizontalVelocity
Projectile_TerobusterHomingMissileAdjustHorizontalVelocity:  ; was: loc_38FAC
                add.l   d4,$18(a5)
                bra.s   Projectile_TerobusterHomingMissileSteerTowardPlayer
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileClampHorizontalVelocity:  ; was: loc_38FB2
                                        ; Projectile_TerobusterHomingMissileUpdate+108   j
                move.l  d2,$18(a5)
Projectile_TerobusterHomingMissileSteerTowardPlayer:    ; was: loc_38FB6
                jsr     (Math_CalculateAngleToPlayer).l
                sub.w   $56(a5),d2
                bmi.w   Projectile_TerobusterHomingMissileCheckWrappedHeadingDelta
                cmpi.w  #$100,d2
                bpl.w   Projectile_TerobusterHomingMissileDecreaseHeading
Projectile_TerobusterHomingMissileIncreaseHeading:      ; was: loc_38FCC
                addq.w  #4,$56(a5)
                andi.w  #$1FE,$56(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileCheckWrappedHeadingDelta:  ; was: loc_38FD8
                cmpi.w  #$FF00,d2
                bmi.w   Projectile_TerobusterHomingMissileIncreaseHeading
Projectile_TerobusterHomingMissileDecreaseHeading:      ; was: loc_38FE0
                subq.w  #4,$56(a5)
                andi.w  #$1FE,$56(a5)
                rts
; End of function Projectile_TerobusterHomingMissileUpdate
; ---------------------------------------------------------------------------
Projectile_TerobusterHomingMissileDirectionFrames:  dc.w    $D478, $400, $F8FC, 0  ; was: word_38FEC
                dc.w    $D474, $500, $F8F8, 0
                dc.w    $D470, $500, $F8F8, 0
                dc.w    $D46C, $500, $F8F8, 0
                dc.w    $D46A, $100, $FCF8, 0
                dc.w    $DC6C, $500, $F8F8, 0
                dc.w    $DC70, $500, $F8F8, 0
                dc.w    $DC74, $500, $F8F8, 0

; Spawns 8-way directional projectiles with animated effects from table data
Boss_TerobusterSpawnMultiDirectional:                   ; was: sub_3902C
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_TerobusterSpawnMultiDirectionalReturn
                move.w  #$14,$23C(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_TerobusterSpawnMultiDirectionalReturn
                move.w  (a4)+,d0
                move.w  (a4)+,d1
                move.w  (a4)+,d2
                jsr     (Projectile_InitializeEightDirectionShot).l
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_TerobusterSpawnMultiDirectionalReturn
                move.w  #1,$1C(a0)
                moveq   #0,d0
                move.w  (RandomNumberState).w,d0
                asl.l   #1,d0
                addi.l  #$28000,d0
                move.l  d0,$18(a0)
                move.w  (a4)+,d1
                move.w  (a4)+,d2
                jsr     (Projectile_InitializeTerobusterGravityShot).l
Boss_TerobusterSpawnMultiDirectionalReturn:             ; was: locret_39084
                                        ; Boss_TerobusterSpawnMultiDirectional+16   j
                rts
; End of function Boss_TerobusterSpawnMultiDirectional
; ---------------------------------------------------------------------------
Boss_TerobusterFallingRockParametersA:  dc.w    $40, $FFB2, $FFD6, $FFCC, $FFD8  ; was: word_39086
Boss_TerobusterFallingRockParametersB:  dc.w    $30, $FFC4, $10, $FFD0, $C  ; was: word_39090

; Spawns falling rocks with randomized position offsets and downward velocity
Boss_TerobusterSpawnFallingRock:                        ; was: sub_3909A
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_TerobusterSpawnFallingRockReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_TerobusterSpawnFallingRockReturn
                move.b  (RandomNumberState).w,d1
                andi.w  #7,d1
                subi.w  #4,d1
                move.b  (RandomNumberState+1).w,d2
                andi.w  #7,d2
                subi.w  #4,d2
                add.w   2(a4),d1
                add.w   4(a4),d2
                add.w   $10(a5),d1
                add.w   $14(a5),d2
                move.w  d1,$10(a0)
                move.w  d2,$14(a0)
                movea.l #Projectile_HomingAndRockSpriteFrames,a1
                jsr     (Sprite_InitTypeA4FromTable).l
                move.l  #$FFFFC000,$1C(a0)
Boss_TerobusterSpawnFallingRockReturn:                  ; was: locret_390EE
                                        ; Boss_TerobusterSpawnFallingRock+E   j
                rts
; End of function Boss_TerobusterSpawnFallingRock
; Interpolates animation frames with delay loading
