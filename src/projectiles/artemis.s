; Create the type-$488 Artemis radial-emitter entity
Boss_SpawnArtemisRadialEmitter:                         ; was: sub_589E8
                tst.w   $54(a5)
                beq.s   Boss_InitArtemisRadialEmitter
                move.w  #$100,d1
                sub.w   d7,d1
                move.w  d1,d7
                andi.w  #$1FE,d7
                neg.l   d5
Boss_InitArtemisRadialEmitter:                          ; was: loc_589FC
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_SpawnArtemisRadialEmitterReturn
                move.w  #$488,(a0)
                move.w  #$C100,2(a0)
                move.w  #$480,$E(a0)
                move.l  #Effect_SpriteFrame06,8(a0)
                move.b  $B00(a5),$20(a0)
                subq.b  #4,$20(a0)
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d7.w),d0
                move.w  (a1,d7.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #5,d0
                asl.l   #5,d1
                move.l  d0,$1C(a0)
                move.l  d1,$18(a0)
                move.w  d6,$48(a0)
                tst.w   (DifficultyMode).w
                bne.s   Boss_StoreArtemisEmitterAcceleration
                moveq   #0,d4
                moveq   #0,d5
Boss_StoreArtemisEmitterAcceleration:                   ; was: loc_58A54
                move.l  d5,$4C(a0)
                move.l  d4,$50(a0)
Boss_SpawnArtemisRadialEmitterReturn:                   ; was: locret_58A5C
                rts
; End of function Boss_SpawnArtemisRadialEmitter
; Update the type-$488 Artemis radial-emitter lifecycle
Projectile_UpdateArtemisRadialEmitter:                  ; was: sub_58A5E
                tst.w   $48(a5)
                bmi.s   Projectile_UpdateArtemisEmitterFlight
                subq.w  #1,$48(a5)
                bpl.s   Projectile_UpdateArtemisEmitterAnchorJitter
                move.b  #$CB,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$8D00,2(a5)
                move.w  #$A00,8(a5)
                move.w  #$F4F4,$A(a5)
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #$FA06FA06,$2C(a5)
                move.w  #$C7,$26(a5)
                bra.s   Projectile_UpdateArtemisEmitterFlight
; ---------------------------------------------------------------------------
Projectile_UpdateArtemisEmitterAnchorJitter:            ; was: loc_58A9C
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   (ThirtiethEntityXPos).w,d0
                move.w  d0,$10(a5)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   (ThirtiethEntityYPos).w,d0
                move.w  d0,$14(a5)
                bset    #7,2(a5)
                btst    #0,(FrameCounter+1).w
                bne.w   Projectile_SpawnArtemisRadialShot
                bclr    #7,2(a5)
                bra.w   Projectile_SpawnArtemisRadialShot
; ---------------------------------------------------------------------------
Projectile_UpdateArtemisEmitterFlight:                  ; was: loc_58ADA
                                        ; Projectile_UpdateArtemisRadialEmitter+3C   j
                move.w  (PrimaryCameraYPosition).w,d0
                subi.w  #$E200,d0
                addi.w  #$12A,d0
                cmp.w   $14(a5),d0
                bpl.s   Projectile_CheckArtemisEmitterHorizontalBounds
                clr.l   $18(a5)
                move.l  #$FFFC0000,$1C(a5)
                bra.w   Projectile_InitArtemisEmitterEffect
; ---------------------------------------------------------------------------
Projectile_CheckArtemisEmitterHorizontalBounds:         ; was: loc_58AFC
                cmpi.w  #$80,$14(a5)
                bmi.s   Projectile_RemoveArtemisEmitterOutsideBounds
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$26C,d0
                bpl.s   Projectile_RemoveArtemisEmitterOutsideBounds
                cmpi.w  #$94,d0
                bpl.s   Projectile_HandleArtemisEmitterCollision
Projectile_RemoveArtemisEmitterOutsideBounds:           ; was: loc_58B18
                                        ; Projectile_UpdateArtemisRadialEmitter+B2   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_HandleArtemisEmitterCollision:               ; was: loc_58B20
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ConvertArtemisEmitterToEffect
                bclr    #7,$22(a5)
                beq.s   Projectile_ReflectArtemisEmitter
                bclr    #4,$22(a5)
                beq.s   Projectile_ConvertArtemisEmitterToEffect
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_ConvertArtemisEmitterToEffect
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                jsr     (Pickup_SelectLargeSize).l
Projectile_ConvertArtemisEmitterToEffect:               ; was: loc_58B50
                                        ; Projectile_UpdateArtemisRadialEmitter+D6   j
                move.l  $18(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$18(a5)
                move.l  $1C(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
Projectile_InitArtemisEmitterEffect:                    ; was: loc_58B68
                move.w  #3,(PlaneAShakeLevel).w
                move.l  #Effect_SpriteAnimation00,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_ReflectArtemisEmitter:                       ; was: loc_58B7C
                move.w  (FrameCounter).w,d0
                asl.w   #1,d0
                andi.w  #6,d0
                move.w  Projectile_ArtemisEmitterSpriteAttributes(pc,d0.w),$E(a5)
                move.l  $4C(a5),d0
                add.l   d0,$18(a5)
                move.l  $50(a5),d0
                add.l   d0,$1C(a5)
                bra.w   Projectile_SpawnArtemisReflectedShot
; End of function Projectile_UpdateArtemisRadialEmitter
; UNKNOWN CODE-003: no static entry path; see docs/unknowns.md
Projectile_ArtemisEmitterUnreferencedReturn:            ; was: nullsub_132
                rts
; End of function Projectile_ArtemisEmitterUnreferencedReturn
; ---------------------------------------------------------------------------
Projectile_ArtemisEmitterSpriteAttributes:  dc.w    $4489, $4492, $449B, $4492  ; was: word_58BA2

; Spawn a projectile in a phase-selected radial direction from the emitter
Projectile_SpawnArtemisRadialShot:                      ; was: sub_58BAA
                                        ; Projectile_UpdateArtemisRadialEmitter+78   j
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Projectile_SpawnArtemisRadialShotReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_SpawnArtemisRadialShotReturn
                lea     (Projectile_BombAndRadialSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $20(a5),$20(a0)
                move.w  (RandomNumberState).w,d5
                andi.w  #$1FE,d5
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d5.w),d0
                move.w  (a1,d5.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #5,d0
                asl.l   #5,d1
                move.l  d0,$1C(a0)
                move.l  d1,$18(a0)
Projectile_SpawnArtemisRadialShotReturn:                ; was: locret_58C00
                                        ; Projectile_SpawnArtemisRadialShot+10   j
                rts
; Spawn a projectile with the emitter's velocity reversed
Projectile_SpawnArtemisReflectedShot:                   ; was: sub_58C02
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_SpawnArtemisReflectedShotReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_SpawnArtemisReflectedShotReturn
                lea     (Projectile_ArtemisReflectedShotSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subi.w  #8,d0
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                subi.w  #8,d0
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
                move.b  $20(a5),$20(a0)
                move.l  $18(a5),d0
                neg.l   d0
                move.l  d0,$18(a0)
                move.l  $1C(a5),d0
                neg.l   d0
                move.l  d0,$1C(a0)
Projectile_SpawnArtemisReflectedShotReturn:             ; was: locret_58C60
                                        ; Projectile_SpawnArtemisReflectedShot+E   j
                rts
; End of function Projectile_SpawnArtemisReflectedShot
; End of Artemis projectile subsystem
