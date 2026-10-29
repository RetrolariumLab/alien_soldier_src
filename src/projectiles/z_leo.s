; Spawn orb projectile
Boss_ZLeoSpawnOrb:                                      ; was: sub_52F32
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Boss_ZLeoSpawnOrbReturn
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #1,(PlaneBShakeLevel).w
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_ZLeoSpawnOrbReturn
                move.w  #$C000,$59E(a5)
                btst    #0,(RandomNumberState).w
                bne.s   Boss_ZLeoFinishOrbVelocitySelection
                move.w  #$8000,$59E(a5)
Boss_ZLeoFinishOrbVelocitySelection:                    ; was: loc_52F68
                move.w  #3,$59C(a5)
                movea.l #Weapon_SharedShotInitialSpriteFrame,a1
                jsr     (Sprite_InitFromTable).l
                move.b  #4,$20(a0)
                move.w  #$8040,2(a0)
                movea.w a0,a3
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_ZLeoSpawnOrbReturn
                move.b  #$36,d0                         ; '6'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$468,(a0)
                move.w  #$8C80,2(a0)
                move.b  #$42,$21(a0)                    ; 'B'
                move.l  #$FE02FE02,$2C(a0)
                move.w  #$A,$26(a0)
                move.b  #8,$20(a0)
                move.w  $296(a5),d0
                move.w  d0,d2
                lea     (Math_SineTable).l,a2
                move.w  Math_QuarterSineTable-Math_SineTable(a2,d0.w),d3
                move.w  (a2,d0.w),d4
                muls.w  #$28,d3                         ; '('
                muls.w  #$28,d4                         ; '('
                move.l  d3,$1C(a0)
                move.l  d4,$18(a0)
                addi.w  #$20,d0                         ; ' '
                asr.w   #4,d0
                andi.w  #$1C,d0
                move.w  Boss_ZLeoOrbSpawnOffsetTable(pc,d0.w),d5
                move.w  Boss_ZLeoOrbSpawnOffsetTable+2(pc,d0.w),d6
                add.w   $254(a5),d5
                add.w   $250(a5),d6
                move.w  d5,$14(a0)
                move.w  d6,$10(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   d0,d5
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   d0,d6
                move.w  d5,$14(a3)
                move.w  d6,$10(a3)
                move.w  #$C489,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
Boss_ZLeoSpawnOrbReturn:                                ; was: locret_53038
                                        ; Boss_ZLeoSpawnOrb+1E   j
                rts
; End of function Boss_ZLeoSpawnOrb
; ---------------------------------------------------------------------------
Boss_ZLeoOrbSpawnOffsetTable:   dc.w    0, $20, $18, $18, $20, 0, $18, $FFE8, 0, $FFE0, $FFE8, $FFE8, $FFE0, 0, $FFE8, $18  ; was: word_5303A
                                        ; Boss_ZLeoSpawnOrb+C0   r

; Orb projectile main
Projectile_ZLeoOrbMain:                                 ; was: sub_5305A
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ZLeoOrbTrySpawnRemovalPickup
                btst    #7,$22(a5)
                beq.s   Projectile_ZLeoOrbCheckBounds
                btst    #4,$22(a5)
                beq.s   Projectile_ZLeoOrbReflectVelocity
Projectile_ZLeoOrbTrySpawnRemovalPickup:                ; was: loc_53070
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                bne.s   Projectile_ZLeoOrbRemove
                jmp     Pickup_SpawnSmallFromCurrentObject
; ---------------------------------------------------------------------------
Projectile_ZLeoOrbReflectVelocity:                      ; was: loc_53080
                neg.l   $18(a5)
                neg.l   $1C(a5)
                move.l  #Effect_SpriteAnimation05,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_ZLeoOrbCheckBounds:                          ; was: loc_53096
                cmpi.w  #$1C0,$10(a5)
                bpl.s   Projectile_ZLeoOrbRemove
                cmpi.w  #$80,$10(a5)
                bmi.s   Projectile_ZLeoOrbRemove
                cmpi.w  #$70,$14(a5)                    ; 'p'
                bpl.s   Projectile_ZLeoOrbBounceAtStageBoundary
Projectile_ZLeoOrbRemove:                               ; was: loc_530AE
                                        ; Projectile_ZLeoOrbMain+42   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ZLeoOrbBounceAtStageBoundary:                ; was: loc_530B6
                move.w  (Entity57YPos).w,d0
                cmp.w   $14(a5),d0
                bpl.s   Projectile_ZLeoOrbSelectFlashFrame
                tst.w   $1C(a5)
                bmi.s   Projectile_ZLeoOrbSelectFlashFrame
                move.b  #$37,d0                         ; '7'
                jsr     (Sound_QueueSFXRequest).l
                neg.l   $1C(a5)
Projectile_ZLeoOrbSelectFlashFrame:                     ; was: loc_530D4
                                        ; Projectile_ZLeoOrbMain+6A   j
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_ZLeoOrbUseAlternateFlashFrame
                move.w  #$E489,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ZLeoOrbUseAlternateFlashFrame:               ; was: loc_530E4
                move.w  #$C489,$E(a5)
                rts
; End of function Projectile_ZLeoOrbMain
Projectile_ZLeoOrbNoOpState:                            ; was: nullsub_122
                rts
; End of function Projectile_ZLeoOrbNoOpState

; Spawn the expanding-orbit laser projectile
Boss_ZLeoSpawnExpandingOrbitLaser:                      ; was: sub_530EE
                move.w  (RandomNumberState).w,d7
                andi.w  #$100,d7
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_ZLeoSpawnExpandingOrbitLaserReturn
                move.w  #8,$4DC(a5)
                move.w  #$8000,$4DE(a5)
                move.w  #$C,$53C(a5)
                move.w  #$8000,$53E(a5)
                move.w  #$E,$59C(a5)
                move.w  #$8000,$59E(a5)
                move.b  #$CB,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$46C,(a0)
                move.w  #$8000,2(a0)
                move.w  #$F00,8(a0)
                move.w  #$F0F0,$A(a0)
                move.b  #4,$20(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                addi.w  #0,$14(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FA06FA06,$2C(a0)
                move.w  #$F3,$26(a0)
                move.w  #$10,$48(a0)
                move.w  #4,$50(a0)
                move.w  d7,$56(a0)
Boss_ZLeoSpawnExpandingOrbitLaserReturn:                ; was: locret_53180
                rts
; End of function Boss_ZLeoSpawnExpandingOrbitLaser
; Expand the laser's orbit and resolve its collision-driven state change
Projectile_ZLeoExpandingOrbitLaserMain:                 ; was: sub_53182
                cmpi.w  #$180,$14(a5)
                bpl.s   Projectile_ZLeoLaserRemoveOutsideVerticalBounds
                cmpi.w  #$80,$14(a5)
                bpl.s   Projectile_ZLeoLaserResolveOrbitState
Projectile_ZLeoLaserRemoveOutsideVerticalBounds:        ; was: loc_53192
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ZLeoLaserResolveOrbitState:                  ; was: loc_5319A
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ZLeoLaserConvertToParticle
                bclr    #7,$22(a5)
                beq.s   Projectile_ZLeoLaserUpdateExpandingOrbit
                bclr    #4,$22(a5)
                bne.w   Projectile_ZLeoLaserLaunchHorizontal
Projectile_ZLeoLaserConvertToParticle:                  ; was: loc_531B2
                move.w  #3,(PlaneAShakeLevel).w
                move.l  #Effect_SpriteAnimation00,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_ZLeoLaserUpdateExpandingOrbit:               ; was: loc_531C6
                addi.w  #6,$56(a5)
                addq.w  #5,$50(a5)
                lea     (Math_SineTable).l,a0
                move.w  $56(a5),d0
                andi.w  #$1FE,d0
                move.w  -$80(a0,d0.w),d1
                move.w  (a0,d0.w),d2
                addi.w  #$80,d0
                andi.w  #$1FE,d0
                move.w  -$80(a0,d0.w),d3
                move.w  (a0,d0.w),d4
                ext.l   d3
                ext.l   d4
                asl.l   #5,d3
                asl.l   #4,d4
                move.l  d3,$1C(a5)
                move.l  d4,$18(a5)
                move.w  $50(a5),d0
                muls.w  d0,d1
                muls.w  d0,d2
                add.l   (PrimaryEntityYPos).w,d1
                add.l   (PrimaryEntityXPos).w,d2
                move.l  d1,$14(a5)
                move.l  d2,$10(a5)
                move.w  (FrameCounter).w,d0
                asl.w   #1,d0
                andi.w  #6,d0
                move.w  Projectile_ZLeoLaserOrbitSpriteAttributes(pc,d0.w),$E(a5)
                btst    #0,(FrameCounter+1).w
                bne.w   Projectile_ZLeoLaserSpawnTrailParticle
                rts
; ---------------------------------------------------------------------------
Projectile_ZLeoLaserOrbitSpriteAttributes:  dc.w    $C56C, $C50B, $C54B, $C51B  ; was: word_5323A
; ---------------------------------------------------------------------------
Projectile_ZLeoLaserLaunchHorizontal:                   ; was: loc_53242
                move.b  #$7C,d0                         ; '|'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$498,(a5)
                move.w  #$8E00,2(a5)
                move.b  #1,$21(a5)
                clr.b   $22(a5)
                clr.b   $23(a5)
                move.w  #$154,$26(a5)
                clr.l   $1C(a5)
                move.l  #$100000,$18(a5)
                btst    #3,(PlayerSpriteAttributes).w
                bne.s   Projectile_ZLeoHorizontalLaserMain
                neg.l   $18(a5)
; Update the launched horizontal laser, converting impacts and emitting its trail
Projectile_ZLeoHorizontalLaserMain:                     ; was: loc_53282
                bclr    #7,$22(a5)
                beq.s   Projectile_ZLeoHorizontalLaserTrySpawnTrail
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #3,(PlaneAShakeLevel).w
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #Effect_SpriteAnimation32,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_ZLeoHorizontalLaserTrySpawnTrail:            ; was: loc_532B0
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Projectile_ZLeoLaserReturn
Projectile_ZLeoLaserSpawnTrailParticle:                 ; was: loc_532BA
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_ZLeoLaserReturn
                move.l  #Effect_SpriteAnimation00,8(a0)
                jsr     (Projectile_InitType88).l
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
                addq.b  #4,$20(a0)
                move.l  $18(a5),d0
                neg.l   d0
                move.l  d0,$18(a0)
                move.l  $1C(a5),d0
                neg.l   d0
                move.l  d0,$1C(a0)
Projectile_ZLeoLaserReturn:                             ; was: locret_53316
                                        ; Projectile_ZLeoExpandingOrbitLaserMain+13E   j
                rts
; End of function Projectile_ZLeoExpandingOrbitLaserMain
; Spawn the two scrolling-attack laser objects from the selected anchor
Boss_ZLeoCreateScrollingLaserPair:                      ; was: sub_53318
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_ZLeoCreateScrollingLaserPairReturn
                move.w  #$188,(a0)
                move.w  #$C480,2(a0)
                move.w  #$C380,$E(a0)
                move.l  #Projectile_ZLeoScrollingLaserMapping,8(a0)
                move.b  #0,$20(a0)
                move.l  #$FFFE8000,$1C(a0)
                move.w  $10(a4),$10(a0)
                move.w  $14(a4),$14(a0)
                addi.w  #-$40,$14(a0)
                move.w  #2,$48(a0)
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_ZLeoCreateScrollingLaserPairReturn
                move.w  #$470,(a0)
                move.w  #$C480,2(a0)
                move.w  #$C380,$E(a0)
                move.l  #Projectile_ZLeoVerticalBeamMapping,8(a0)
                move.b  #$60,$20(a0)                    ; '`'
                move.l  #$FFF00000,$1C(a0)
                move.w  $10(a4),$10(a0)
                move.w  $14(a4),$14(a0)
                addi.w  #-$68,$14(a0)
                move.w  #$10,$48(a0)
                move.w  #$4000,$59E(a5)
                move.w  #7,$59C(a5)
                move.b  #$EA,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_ZLeoCreateScrollingLaserPairReturn:                ; was: locret_533BC
                                        ; Boss_ZLeoCreateScrollingLaserPair+4E   j
                rts
; End of function Boss_ZLeoCreateScrollingLaserPair
; Count down the beam lifetime while accelerating it upward
Projectile_ZLeoVerticalBeamMain:                        ; was: sub_533BE
                subq.w  #1,$48(a5)
                bpl.s   Projectile_ZLeoVerticalBeamApplyUpwardAcceleration
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ZLeoVerticalBeamApplyUpwardAcceleration:     ; was: loc_533CC
                subi.l  #$80000,$1C(a5)
                rts
; End of function Projectile_ZLeoVerticalBeamMain
; Spawn the paired drop-attack objects and select horizontal velocity by position
Boss_ZLeoSpawnDropAttackPair:                           ; was: sub_533D6
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_ZLeoSpawnDropAttackPairReturn
                move.w  #$6000,$4DE(a5)
                move.w  #3,$4DC(a5)
                move.w  #$6000,$53E(a5)
                move.w  #3,$53C(a5)
                move.b  #$59,d0                         ; 'Y'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$478,(a0)
                move.w  #$C080,2(a0)
                move.w  #$6380,$E(a0)
                move.l  #Projectile_ZLeoVerticalBeamMapping,8(a0)
                move.b  #8,$20(a0)
                clr.b   $21(a0)
                move.w  #$C8,$26(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$9070F808,$2C(a0)
                move.w  #$4E0,$14(a0)
                movea.w a0,a3
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_ZLeoSpawnDropAttackPairReturn
                move.w  #$424,(a0)
                move.w  #$8080,2(a0)
                move.b  #4,$20(a0)
                jsr     (Projectile_InitZLeoDropGraphics).l
                move.w  #$20,$48(a0)                    ; ' '
                move.w  (RandomNumberState).w,d0
                andi.w  #$E000,d0
                ext.l   d0
                move.l  d0,$56(a3)
                move.w  #$14C,$14(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$70,d0                         ; 'p'
                subi.w  #$38,d0                         ; '8'
                add.w   (PlayerXPosition).w,d0
                move.w  d0,$10(a0)
                move.w  d0,$10(a3)
                cmpi.w  #$120,d0
                bpl.s   Boss_ZLeoUseNegativeDropAttackBeamVelocity
                move.l  #$60000,$18(a3)
                rts
; ---------------------------------------------------------------------------
Boss_ZLeoUseNegativeDropAttackBeamVelocity:             ; was: loc_534A2
                move.l  #$FFFA0000,$18(a3)
Boss_ZLeoSpawnDropAttackPairReturn:                     ; was: locret_534AA
                                        ; Boss_ZLeoSpawnDropAttackPair+70   j
                rts
; End of function Boss_ZLeoSpawnDropAttackPair
; Move upward to Y=$F0, pause, then continue upward until leaving the screen
Projectile_ZLeoDropAttackBeamMain:                      ; was: sub_534AC
                move.w  #1,(ZLeoDropProjectileFlag).w
                move.l  $56(a5),d0
                add.l   d0,$10(a5)
                move.w  4(a5),d0
                bne.s   Projectile_ZLeoDropAttackBeamCheckPause
                subi.w  #$20,$14(a5)                    ; ' '
                cmpi.w  #$F0,$14(a5)
                bpl.s   Projectile_ZLeoDropAttackBeamReturn
                move.w  #$F0,$14(a5)
                addq.w  #2,4(a5)
                move.w  #$10,$4A(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ZLeoDropAttackBeamCheckPause:                ; was: loc_534E0
                cmpi.w  #4,d0
                beq.s   Projectile_ZLeoDropAttackBeamAdvanceFinalRise
                subq.w  #1,$4A(a5)
                bpl.s   Projectile_ZLeoDropAttackBeamReturn
                addq.w  #2,4(a5)
Projectile_ZLeoDropAttackBeamAdvanceFinalRise:          ; was: loc_534F0
                subi.w  #$20,$14(a5)                    ; ' '
                bpl.s   Projectile_ZLeoDropAttackBeamReturn
                bset    #4,2(a5)
Projectile_ZLeoDropAttackBeamReturn:                    ; was: locret_534FE
                                        ; Projectile_ZLeoDropAttackBeamMain+3E   j
                rts
; End of function Projectile_ZLeoDropAttackBeamMain
