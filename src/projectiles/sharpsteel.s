; Sharpsteel falling shots, defeat fragments, and blade shots
; Emits two groups totalling ten type-$364 falling shots
Boss_SharpsteelSpawnTenFallingShots:                    ; CODE XREF: Boss_SharpsteelPostDiveDelayState+76   p  ; was: sub_48DA0
                lea     (Math_SineTable).l,a4
                moveq   #0,d5
                moveq   #0,d6
                moveq   #$12,d4
                moveq   #5,d7
                bsr.s   Projectile_SharpsteelEmitFallingShotLoop
                moveq   #$10,d4
                moveq   #3,d7
; End of function Boss_SharpsteelSpawnTenFallingShots
; Emits one configured group using sine-derived velocities and fixed spawn offsets
Projectile_SharpsteelEmitFallingShotLoop:               ; CODE XREF: Boss_SharpsteelSpawnTenFallingShots+E   p  ; was: sub_48DB4
                                        ; Projectile_SharpsteelEmitFallingShotLoop+70   j
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_SharpsteelEmitFallingShotReturn
                move.w  #$364,(a0)
                move.w  #$EC00,2(a0)
                move.w  #0,$E(a0)
                move.l  #SharedFloaterDebrisProjectileAlternating5And4Animation,8(a0)
                move.b  #$20,$20(a0)                    ; ' '
                moveq   #0,d0
                move.b  Projectile_SharpsteelFallingShotAngleIndices(pc,d5.w),d0
                asl.w   #1,d0
                move.w  -$80(a4,d0.w),d1
                move.w  (a4,d0.w),d2
                ext.l   d1
                ext.l   d2
                muls.w  d4,d1
                muls.w  d4,d2
                move.l  d1,$1C(a0)
                asr.l   #1,d2
                move.l  d2,$18(a0)
                move.b  Projectile_SharpsteelFallingShotSpawnOffsets(pc,d6.w),d0
                ext.w   d0
                bpl.s   Projectile_SharpsteelSetFallingShotSpawnPosition
                ori.w   #$800,$E(a0)
Projectile_SharpsteelSetFallingShotSpawnPosition:       ; CODE XREF: Projectile_SharpsteelEmitFallingShotLoop+4E   j
                addi.w  #$120,d0
                move.w  d0,$10(a0)
                move.b  Projectile_SharpsteelFallingShotSpawnOffsets+1(pc,d6.w),d0
                ext.w   d0
                addi.w  #$160,d0
                move.w  d0,$14(a0)
                addq.w  #1,d5
                addq.w  #2,d6
                dbf     d7,Projectile_SharpsteelEmitFallingShotLoop
Projectile_SharpsteelEmitFallingShotReturn:             ; CODE XREF: Projectile_SharpsteelEmitFallingShotLoop+6   j
                rts
; End of function Projectile_SharpsteelEmitFallingShotLoop
; ---------------------------------------------------------------------------
Projectile_SharpsteelFallingShotAngleIndices:   dc.b    $B4, $B8, $BC, $C4, $C8, $CC, $B6, $BA, $C6, $CA
                                        ; DATA XREF: Projectile_SharpsteelEmitFallingShotLoop+28   r
Projectile_SharpsteelFallingShotSpawnOffsets:   dc.b    $D0, 0, $E0, $F8, $F0, $F0, $10, $F0, $20, $F8
                                        ; DATA XREF: Projectile_SharpsteelEmitFallingShotLoop+48   r
                                        ; Projectile_SharpsteelEmitFallingShotLoop+5E   r
                dc.b    $30, 0, $C0, $24, $D0, $20, $30, $20, $40, $24

; Type-$364 Sharpsteel shot: rises, arms while falling, and handles hits or bounds
Projectile_SharpsteelFallingShotMain:                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_48E48
                tst.w   (StageSpawnCountdown).w
                bpl.w   Projectile_SharpsteelConvertFallingShotToDebris
                addi.l  #$B00,$1C(a5)
                tst.w   4(a5)
                bne.s   Projectile_SharpsteelHandleFallingShotCollision
                tst.w   $1C(a5)
                bmi.s   Projectile_SharpsteelFallingShotReturn
                addq.w  #2,4(a5)
                bset    #4,$E(a5)
                bset    #7,$E(a5)
                move.b  #$C0,$21(a5)
                move.w  #1,$24(a5)
                move.w  #$64,$26(a5)                    ; 'd'
                move.l  #$F60AF60A,$28(a5)
                move.l  #$FC04FC04,$2C(a5)
Projectile_SharpsteelFallingShotReturn:                 ; CODE XREF: Projectile_SharpsteelFallingShotMain+1A   j
                                        ; Projectile_SharpsteelFallingShotMain+D4   j
                rts
; ---------------------------------------------------------------------------
Projectile_SharpsteelHandleFallingShotCollision:        ; CODE XREF: Projectile_SharpsteelFallingShotMain+14   j
                bclr    #7,$22(a5)
                beq.s   Projectile_SharpsteelCheckFallingShotDurability
                bclr    #4,$22(a5)
                beq.s   Projectile_SharpsteelConvertFallingShotToDebris
                bra.s   Projectile_SharpsteelSpawnPickupFromFallingShot
; ---------------------------------------------------------------------------
Projectile_SharpsteelCheckFallingShotDurability:        ; CODE XREF: Projectile_SharpsteelFallingShotMain+56   j
                tst.w   $24(a5)
                bpl.s   Projectile_SharpsteelHandleFallingShotLowerBoundary
Projectile_SharpsteelSpawnPickupFromFallingShot:        ; CODE XREF: Projectile_SharpsteelFallingShotMain+60   j
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_SharpsteelConvertFallingShotToDebris
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                moveq   #$15,d0
                jsr     (Pickup_SelectRandomSize).l
                move.w  #$E440,2(a0)
                move.l  #$2000,$1C(a0)
Projectile_SharpsteelConvertFallingShotToDebris:        ; CODE XREF: Projectile_SharpsteelFallingShotMain+4   j
                                        ; Projectile_SharpsteelFallingShotMain+5E   j
                clr.l   $1C(a5)
                move.l  #SharedCombatSpriteAnimation03,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_SharpsteelHandleFallingShotLowerBoundary:    ; CODE XREF: Projectile_SharpsteelFallingShotMain+66   j
                cmpi.w  #$150,$14(a5)
                bmi.s   Projectile_SharpsteelCheckFallingShotDeflectionRegion
                move.w  $E(a5),d0
                andi.w  #$8000,d0
                movem.l d0,-(sp)
                move.l  #$FFFC8000,$1C(a5)
                jsr     (Projectile_ConvertCurrentToSharedEffect).l
                movem.l (sp)+,d0
                or.w    d0,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_SharpsteelCheckFallingShotDeflectionRegion:  ; CODE XREF: Projectile_SharpsteelFallingShotMain+AA   j
                tst.w   $48(a5)
                bne.w   Projectile_SharpsteelFallingShotReturn
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  $10(a0),d0
                cmp.w   $10(a5),d0
                bpl.s   Projectile_SharpsteelCheckFallingShotDeflectionReturn
                addi.w  #$F0,d0
                cmp.w   $10(a5),d0
                bmi.s   Projectile_SharpsteelCheckFallingShotDeflectionReturn
                move.w  $14(a0),d0
                subi.w  #$A,d0
                cmp.w   $14(a5),d0
                bpl.s   Projectile_SharpsteelCheckFallingShotDeflectionReturn
                addi.w  #$10,d0
                cmp.w   $14(a5),d0
                bmi.s   Projectile_SharpsteelCheckFallingShotDeflectionReturn
                addq.w  #1,$48(a5)
                bclr    #4,$E(a5)
                move.w  #$FFFE,$1C(a5)
Projectile_SharpsteelCheckFallingShotDeflectionReturn:  ; CODE XREF: Projectile_SharpsteelFallingShotMain+E4   j
                                        ; Projectile_SharpsteelFallingShotMain+EE   j
                rts
; End of function Projectile_SharpsteelFallingShotMain
; Starts defeat presentation and initializes fourteen embedded type-$3BC fragments
Boss_SharpsteelBeginDefeatFragmentBurst:                ; CODE XREF: Boss_SharpsteelMain+22   j  ; was: sub_48F62
                move.b  #1,(SoundFadeOutDelay).w
                clr.w   8(a5)
                bset    #0,(StageTimerPauseFlag).w
                move.w  #8,(StageSpawnCountdown).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #$1E,4(a5)
                clr.w   2(a5)
                move.w  #$80,$48(a5)
                movea.w a5,a0
                moveq   #0,d5
                moveq   #0,d6
                moveq   #$D,d7
Boss_SharpsteelInitializeDefeatFragmentLoop:            ; CODE XREF: Boss_SharpsteelBeginDefeatFragmentBurst+98   j
                movem.l d6-d7/a0,-(sp)
                jsr     (RandomNumber).l
                movem.l (sp)+,d6-d7/a0
                lea     $60(a0),a0
                move.w  #$3BC,(a0)
                bset    #1,2(a0)
                bset    #3,2(a0)
                bset    #2,2(a0)
                move.w  d5,$48(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                swap    d0
                asr.l   #1,d0
                addi.l  #$12000,d0
                move.l  d0,$18(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                addq.w  #1,d6
                btst    #0,d6
                bne.s   Boss_SharpsteelApplyDefeatFragmentVerticalVelocity
                neg.w   d0
Boss_SharpsteelApplyDefeatFragmentVerticalVelocity:     ; CODE XREF: Boss_SharpsteelBeginDefeatFragmentBurst+8A   j
                swap    d0
                asr.l   #2,d0
                move.l  d0,$1C(a0)
                addq.w  #1,d5
                dbf     d7,Boss_SharpsteelInitializeDefeatFragmentLoop
                rts
; End of function Boss_SharpsteelBeginDefeatFragmentBurst
; Type-$3BC defeat fragment: flashes, emits debris, and curves as X velocity changes
Effect_SharpsteelDefeatFragmentMain:                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_49000
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #2,(PlaneBShakeLevel).w
                addq.w  #1,$48(a5)
                move.w  $48(a5),d0
                bset    #7,2(a5)
                btst    #0,d0
                beq.s   Effect_SharpsteelApplyDefeatFragmentFlashPhase
                bclr    #7,2(a5)
Effect_SharpsteelApplyDefeatFragmentFlashPhase:         ; CODE XREF: Effect_SharpsteelDefeatFragmentMain+1E   j
                andi.w  #7,d0
                bne.s   Effect_SharpsteelUpdateDefeatFragmentVelocity
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Effect_SharpsteelTryEmitDefeatFragmentDebris
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
Effect_SharpsteelTryEmitDefeatFragmentDebris:           ; CODE XREF: Effect_SharpsteelDefeatFragmentMain+34   j
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Effect_SharpsteelUpdateDefeatFragmentVelocity
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $18(a5),d0
                neg.l   d0
                asr.l   #3,d0
                move.l  d0,$18(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (Projectile_InitType88).l
Effect_SharpsteelUpdateDefeatFragmentVelocity:          ; CODE XREF: Effect_SharpsteelDefeatFragmentMain+2A   j
                                        ; Effect_SharpsteelDefeatFragmentMain+46   j
                subi.l  #$4000,$18(a5)
                tst.w   $18(a5)
                bpl.s   Effect_SharpsteelAccelerateDefeatFragmentUpward
                addi.l  #$1000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Effect_SharpsteelAccelerateDefeatFragmentUpward:        ; CODE XREF: Effect_SharpsteelDefeatFragmentMain+7A   j
                subi.l  #$1000,$1C(a5)
                rts
; End of function Effect_SharpsteelDefeatFragmentMain
; Emits six type-$414 shots from Sharpsteel's final blade part
Boss_SharpsteelSpawnSixBladeShots:                      ; CODE XREF: Boss_SharpsteelWaitForComplexAlignmentState+D2   p  ; was: sub_49090
                move.l  #$FFFA0000,d6
                moveq   #5,d7
Boss_SharpsteelSpawnSixBladeShotsLoop:                  ; CODE XREF: Boss_SharpsteelSpawnSixBladeShots+10   j
                bsr.s   Projectile_SharpsteelInitializeBladeShot
                addi.l  #$8000,d6
                dbf     d7,Boss_SharpsteelSpawnSixBladeShotsLoop
                rts
; End of function Boss_SharpsteelSpawnSixBladeShots
; Initializes one blade shot with the caller-provided vertical velocity
Projectile_SharpsteelInitializeBladeShot:               ; CODE XREF: Boss_SharpsteelSpawnSixBladeShots:Boss_SharpsteelSpawnSixBladeShotsLoop   p  ; was: sub_490A6
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_SharpsteelInitializeBladeShotReturn
                move.w  #$414,(a0)
                move.w  #$C480,2(a0)
                move.b  #0,$20(a0)
                move.w  $4F0(a5),$10(a0)
                move.w  $4F4(a5),$14(a0)
                move.l  $4E8(a5),8(a0)
                move.w  $4EE(a5),$E(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$F010FA06,$2C(a0)
                move.w  #$56,$26(a0)                    ; 'V'
                move.l  d6,$1C(a0)
                move.w  d7,$48(a0)
                andi.w  #1,$48(a0)
                move.w  #$F,$4A(a0)
Projectile_SharpsteelInitializeBladeShotReturn:         ; CODE XREF: Projectile_SharpsteelInitializeBladeShot+6   j
                rts
; End of function Projectile_SharpsteelInitializeBladeShot
; Type-$414 blade shot: flashes for its configured lifetime, then removes itself
Projectile_SharpsteelBladeShotMain:                     ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_49100
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_SharpsteelMarkBladeShotForRemoval
                bset    #7,2(a5)
                move.w  $4A(a5),d0
                andi.w  #1,d0
                cmp.w   $48(a5),d0
                beq.s   Projectile_SharpsteelTickBladeShotLifetime
                bclr    #7,2(a5)
Projectile_SharpsteelTickBladeShotLifetime:             ; CODE XREF: Projectile_SharpsteelBladeShotMain+18   j
                subq.w  #1,$4A(a5)
                bpl.s   Projectile_SharpsteelBladeShotReturn
Projectile_SharpsteelMarkBladeShotForRemoval:           ; CODE XREF: Projectile_SharpsteelBladeShotMain+4   j
                bset    #4,2(a5)
Projectile_SharpsteelBladeShotReturn:                   ; CODE XREF: Projectile_SharpsteelBladeShotMain+24   j
                rts
; End of function Projectile_SharpsteelBladeShotMain
