; Madam Barbar debris motion states and shared-effect handoff
Projectile_MadamBarbarDebris:                           ; was: sub_3AE36
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_MadamBarbarDebrisConvertToType160
                tst.w   $24(a5)
                bpl.s   Projectile_MadamBarbarDebrisUpdateActive
Projectile_MadamBarbarDebrisConvertToType160:           ; was: loc_3AE42
                clr.l   $18(a5)
                move.l  #$FFFEE000,$1C(a5)
                btst    #4,$E(a5)
                beq.s   Projectile_MadamBarbarDebrisInitializeType160
                neg.l   $1C(a5)
Projectile_MadamBarbarDebrisInitializeType160:          ; was: loc_3AE5A
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #2,(PlaneAShakeLevel).w
                move.l  #Effect_SpriteAnimation00,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisUpdateActive:               ; was: loc_3AE78
                bclr    #3,$E(a5)
                btst    #2,(FrameCounter+1).w
                bne.s   Projectile_MadamBarbarDebrisDispatchMotionState
                bset    #3,$E(a5)
Projectile_MadamBarbarDebrisDispatchMotionState:        ; was: loc_3AE8C
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$5E(a5)
                move.w  4(a5),d0
                bne.w   Projectile_MadamBarbarDebrisUpdateMotionStateOne
                tst.w   $4A(a5)
                beq.s   Projectile_MadamBarbarDebrisUpdateInitialVerticalMotion
                subq.w  #1,$48(a5)
                bmi.s   Projectile_MadamBarbarDebrisUpdateHorizontalMotionTimer
                cmpi.w  #$600,$5E(a5)
                bpl.s   Projectile_MadamBarbarDebrisReverseHorizontalMotion
                cmpi.w  #$4A0,$5E(a5)
                bpl.s   Projectile_MadamBarbarDebrisMotionReturn
Projectile_MadamBarbarDebrisReverseHorizontalMotion:    ; was: loc_3AEBC
                addq.w  #1,4(a5)
                move.l  $4C(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                neg.l   $4C(a5)
                bclr    #4,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisUpdateHorizontalMotionTimer:  ; was: loc_3AED6
                                        ; Projectile_MadamBarbarDebris+18C   j
                clr.l   $18(a5)
                cmpi.w  #$FFD0,$48(a5)
                bmi.s   Projectile_MadamBarbarDebrisRestartHorizontalMotion
                cmpi.w  #$FFE0,$48(a5)
                bpl.s   Projectile_MadamBarbarDebrisHorizontalTimerReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Projectile_MadamBarbarDebrisHorizontalTimerReturn
Projectile_MadamBarbarDebrisRestartHorizontalMotion:    ; was: loc_3AEF4
                move.l  $4C(a5),$18(a5)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                addq.w  #8,d0
                move.w  d0,$48(a5)
Projectile_MadamBarbarDebrisHorizontalTimerReturn:      ; was: locret_3AF08
                                        ; Projectile_MadamBarbarDebris+BC   j
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisUpdateInitialVerticalMotion:  ; was: loc_3AF0A
                subi.l  #$3000,$1C(a5)
                bpl.s   Projectile_MadamBarbarDebrisMotionReturn
                cmpi.w  #$B8,$14(a5)
                bpl.s   Projectile_MadamBarbarDebrisMotionReturn
                move.w  #$B8,$14(a5)
                clr.l   $1C(a5)
                move.l  $4C(a5),$18(a5)
                addq.w  #1,$4A(a5)
Projectile_MadamBarbarDebrisMotionReturn:               ; was: locret_3AF30
                                        ; Projectile_MadamBarbarDebris+DC   j
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisUpdateMotionStateOne:       ; was: loc_3AF32
                cmpi.w  #1,d0
                bne.s   Projectile_MadamBarbarDebrisCheckMotionStateThree
                cmpi.w  #7,$1C(a5)
                bpl.s   Projectile_MadamBarbarDebrisProbeStateOneCollision
                addi.l  #$3000,$1C(a5)
                bmi.s   Projectile_MadamBarbarDebrisMotionReturn
Projectile_MadamBarbarDebrisProbeStateOneCollision:     ; was: loc_3AF4A
                bsr.w   Projectile_MadamBarbarProbeVerticalOffset
                beq.s   Projectile_MadamBarbarDebrisMotionReturn
                addq.w  #1,4(a5)
                move.b  #$82,$21(a5)
                clr.w   $48(a5)
                jmp     Physics_AlignToTerrain
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisCheckMotionStateThree:      ; was: loc_3AF64
                cmpi.w  #3,d0
                bne.s   Projectile_MadamBarbarDebrisCheckSharedEffectTrigger
Projectile_MadamBarbarDebrisEnterSharedEffectState:     ; was: loc_3AF6A
                move.w  #3,4(a5)
                clr.l   $18(a5)
                bclr    #1,(ForcedPositionFlags).w
                bne.s   Projectile_MadamBarbarDebrisPublishSharedEffectPosition
                subq.w  #1,4(a5)
                clr.w   $48(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisPublishSharedEffectPosition:  ; was: loc_3AF86
                move.w  #7,(ForcedPositionTimer).w
                bset    #0,(ForcedPositionFlags).w
                move.w  $10(a5),d0
                move.w  d0,(ForcedPositionX).w
                move.w  $14(a5),d0
                addi.w  #-$14,d0
                move.w  d0,(ForcedPositionY).w
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisCheckSharedEffectTrigger:   ; was: loc_3AFA8
                bclr    #1,$22(a5)
                beq.s   Projectile_MadamBarbarDebrisUpdateMotionStateTwo
                bset    #1,(ForcedPositionFlags).w
                bra.s   Projectile_MadamBarbarDebrisEnterSharedEffectState
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisUpdateMotionStateTwo:       ; was: loc_3AFB8
                move.b  #$82,$21(a5)
                subq.w  #1,$48(a5)
                bmi.w   Projectile_MadamBarbarDebrisUpdateHorizontalMotionTimer
                cmpi.w  #$650,$5E(a5)
                bpl.s   Projectile_MadamBarbarDebrisMarkForRemovalOutsideHorizontalRange
                cmpi.w  #$450,$5E(a5)
                bpl.s   Projectile_MadamBarbarDebrisProbeStateTwoCollision
Projectile_MadamBarbarDebrisMarkForRemovalOutsideHorizontalRange:  ; was: loc_3AFD6
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDebrisProbeStateTwoCollision:     ; was: loc_3AFDE
                bsr.s   Projectile_MadamBarbarProbeVerticalOffset
                beq.s   Projectile_MadamBarbarDebrisReturnToStateOne
                moveq   #8,d0
                tst.w   $18(a5)
                bpl.s   Projectile_MadamBarbarDebrisProbeHorizontalOffset
                moveq   #$FFFFFFF8,d0
Projectile_MadamBarbarDebrisProbeHorizontalOffset:      ; was: loc_3AFEC
                moveq   #0,d1
                jsr     (Physics_AddEntityOffset).l
                beq.s   Projectile_MadamBarbarDebrisReturn
                move.b  #$80,$21(a5)
                move.l  #$FFFC0000,$1C(a5)
Projectile_MadamBarbarDebrisReturnToStateOne:           ; was: loc_3B004
                subq.w  #1,4(a5)
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
Projectile_MadamBarbarDebrisReturn:                     ; was: locret_3B012
                rts
; End of function Projectile_MadamBarbarDebris
; Probes the collision helper at vertical offset $0C
Projectile_MadamBarbarProbeVerticalOffset:              ; was: sub_3B014
                                        ; Projectile_MadamBarbarDebris:Projectile_MadamBarbarDebrisProbeStateTwoCollision   p
                moveq   #0,d0
                moveq   #$C,d1
                jmp     Physics_AddEntityOffset
; End of function Projectile_MadamBarbarProbeVerticalOffset
; Spawns a type-$38 animation effect at a randomized nearby position
Boss_MadamBarbarSpawnAnimationEffect:                   ; was: sub_3B01E
                                        ; Boss_MadamBarbarIdleProgressState+1A   p
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_MadamBarbarSpawnObjectReturn
                movea.l #Boss_MadamBarbarAnimationEffectFrames,a1
                jsr     (Sprite_InitFromTable).l
                move.w  #$8100,2(a0)
                move.b  #$20,$20(a0)                    ; ' '
Boss_MadamBarbarPositionSpawnedObject:                  ; was: loc_3B03E
                move.b  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                addi.w  #8,d0
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
Boss_MadamBarbarSpawnObjectReturn:                      ; was: locret_3B066
                                        ; Boss_MadamBarbarSpawnDropProjectile+8   j
                rts
; End of function Boss_MadamBarbarSpawnAnimationEffect
; Spawn falling projectile from Madam Barbar boss
Boss_MadamBarbarSpawnDropProjectile:                    ; was: sub_3B068
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_MadamBarbarSpawnObjectReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_MadamBarbarSpawnObjectReturn
                move.w  #$11C,(a0)
                clr.w   4(a0)
                move.w  #$8D00,2(a0)
                move.w  #$C3C3,$E(a0)
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
                move.w  #$B3,$26(a0)
                move.b  #4,$20(a0)
                move.w  #$F,$48(a0)
                move.w  #2,$4A(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                move.l  d0,$18(a0)
                bra.w   Boss_MadamBarbarPositionSpawnedObject
; End of function Boss_MadamBarbarSpawnDropProjectile
; Updates the Madam Barbar drop projectile startup and terrain contacts
Projectile_MadamBarbarDropUpdate:                       ; was: sub_3B0C0
                tst.w   (StageSpawnCountdown).w
                bmi.s   Projectile_MadamBarbarDropUpdateActive
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDropUpdateActive:                 ; was: loc_3B0CE
                tst.w   4(a5)
                bne.s   Projectile_MadamBarbarDropUpdateFallingMotion
                subq.w  #1,$48(a5)
                bpl.s   Projectile_MadamBarbarDropStartupReturn
                move.w  #$F,$48(a5)
                addq.w  #1,$E(a5)
                cmpi.b  #$C5,$F(a5)
                bne.s   Projectile_MadamBarbarDropStartupReturn
                addq.w  #2,4(a5)
                move.l  $18(a5),d0
                asl.l   #3,d0
                move.l  d0,$18(a5)
Projectile_MadamBarbarDropStartupReturn:                ; was: locret_3B0FA
                                        ; Projectile_MadamBarbarDropUpdate+2A   j
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDropUpdateFallingMotion:          ; was: loc_3B0FC
                move.w  #$C3C5,$E(a5)
                cmpi.w  #7,$1C(a5)
                bpl.s   Projectile_MadamBarbarDropProbeTerrainContact
                addi.l  #$6000,$1C(a5)
                bmi.s   Projectile_MadamBarbarDropMotionReturn
Projectile_MadamBarbarDropProbeTerrainContact:          ; was: loc_3B114
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Physics_AddEntityOffset).l
                beq.s   Projectile_MadamBarbarDropMotionReturn
                subq.w  #1,$4A(a5)
                bmi.s   Projectile_MadamBarbarDropHandleFinalTerrainContact
                move.l  #$FFFC4000,$1C(a5)
                move.w  #$C3D2,$E(a5)
Projectile_MadamBarbarDropMotionReturn:                 ; was: locret_3B134
                                        ; Projectile_MadamBarbarDropUpdate+5E   j
                rts
; ---------------------------------------------------------------------------
Projectile_MadamBarbarDropHandleFinalTerrainContact:    ; was: loc_3B136
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                bne.s   Projectile_MadamBarbarDropConvertToExplosion
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_MadamBarbarDropConvertToExplosion
                jsr     (Pickup_SpawnLarge).l
                bset    #2,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #Stage3ResampleBuffer,$1C(a0)
Projectile_MadamBarbarDropConvertToExplosion:           ; was: loc_3B168
                                        ; Projectile_MadamBarbarDropUpdate+86   j
                clr.l   $18(a5)
                move.w  #$FFFE,$1C(a5)
                jmp     Effect_InitSharedExplosionFromCurrent
; End of function Projectile_MadamBarbarDropUpdate
; ---------------------------------------------------------------------------
Boss_MadamBarbarAnimationEffectFrames:  dc.l    $163BC, $FCFC, $163BD, $FCFC, $163BE, $FCFC, $263BF  ; was: dword_3B178
                dc.l    $500F8F8, $163BE, $FCFC, $163BD, $FCFC, $163BC, $FCFC
                dc.w    $FFFF
Boss_MadamBarbarIntroIdlePoses: dc.l    $100000, $10000C  ; was: dword_3B1B2
                                        ; Boss_MadamBarbarIdleProgressState+1E   o
                dc.w    $FFFF
Boss_MadamBarbarDropProjectilePoses:    dc.l    $70000, $7000C  ; was: dword_3B1BC
                dc.w    $FFFF
Boss_MadamBarbarBulletBarragePoses: dc.l    $40018, $4000C  ; was: dword_3B1C6
                dc.w    $FFFF
Boss_MadamBarbarCenterSpinPoses:    dc.l    $F70D0018, $220018, $E3200024, $FE0E0024, $180024, $F0200018  ; was: dword_3B1D0
                dc.w    $FFFE
Boss_MadamBarbarPlayerLeftPoses:    dc.l    $100030, $10003C, $100048, $100054  ; was: dword_3B1EA
                dc.w    $FFFF
Boss_MadamBarbarPlayerRightPoses:   dc.l    $100060, $10006C, $100078, $100084  ; was: dword_3B1FC
                dc.w    $FFFF
Boss_MadamBarbarPoseTable:  dc.w    $D828, $A8D8, $8818, $D820, $A8E0, $F8E8, $E028, $A0D8  ; was: word_3B20E
                                        ; Boss_MadamBarbarUpdatePose+5A   o
                dc.w    $9020, $D020, $B0E0, $F0E0, $A028, $E0D8, $8010, $E028
                dc.w    $A0D8, $F0, $4408, $3CF8, $B404, $CC04, $B4FC, $CCFC
                dc.w    $C030, $A0D0, $9020, $D020, $B0E0, $F0E0, $E030, $C0D0
                dc.w    $C018, $8870, $C0E8, $F890, $C030, $A0D0, $D020, $9020
                dc.w    $F0E0, $B0E0, $E030, $C0D0, $8870, $C018, $F890, $C0E8
                dc.w    $E030, $C0D0, $9020, $D020, $B0E0, $F0E0, $C030, $A0D0
                dc.w    $8870, $C018, $F890, $C0E8, $E030, $C0D0, $D020, $9020
                dc.w    $F0E0, $B0E0, $C030, $A0D0, $C018, $8870, $C0E8, $F890

; Main Joker boss update handler with state dispatching and fade
