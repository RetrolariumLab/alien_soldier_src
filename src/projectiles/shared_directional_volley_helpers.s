; Spawn four type-$1A8 projectiles using the shared velocity table and subtype 8
Projectile_SpawnFourDirectionalShots:
                moveq   #8,d3                           ; was: sub_E288
; Alternate entry accepting the projectile subtype in D3
Projectile_SpawnFourDirectionalShotsWithSubtypeInD3:    ; was: loc_E28A
                moveq   #0,d4
                moveq   #3,d7
                lea     Projectile_FourDirectionalShotVelocities(pc),a4
                nop
Projectile_SpawnFourDirectionalShots_Loop:              ; was: loc_E294
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   Projectile_SpawnFourDirectionalShots_Return
                jsr     (Projectile_InitType1A8).l
                move.l  #SharedProjectileDuration4Animation,8(a0)
                move.w  (GlobalSpritePriorityBit).w,d0
                addi.w  #$4000,d0
                move.w  d0,$E(a0)
                move.w  d5,$10(a0)
                move.w  d6,$14(a0)
                move.b  d3,$20(a0)
                move.l  (a4,d4.w),$18(a0)
                move.l  $10(a4,d4.w),$1C(a0)
                addq.w  #4,d4
                dbf     d7,Projectile_SpawnFourDirectionalShots_Loop
Projectile_SpawnFourDirectionalShots_Return:            ; was: locret_E2D4
                rts
; End of function Projectile_SpawnFourDirectionalShots
; ---------------------------------------------------------------------------
Projectile_FourDirectionalShotVelocities:   dc.l    $FFFDC000, $FFFF4000  ; was: dword_E2D6
                dc.l    $C000, $24000
                dc.l    $FFFD8000, $FFFC8000
                dc.l    $FFFC8000, $FFFD8000

; Spawn one type-$1A8 projectile with velocity selected from the sine table
Projectile_SpawnType1A8AtAngle:                         ; was: sub_E2F6
                                        ; EntityType390_BeginAttackCycle+34   j
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_SpawnType1A8AtAngle_Return
                jsr     (Projectile_InitType1A8).l
                clr.b   $21(a0)
                move.l  #SharedProjectileDuration4Animation,8(a0)
                move.w  (GlobalSpritePriorityBit).w,d0
                addi.w  #$4000,d0
                move.w  d0,$E(a0)
                move.w  d5,$10(a0)
                move.w  d6,$14(a0)
                move.b  #8,$20(a0)
                lea     (Math_SineTable).l,a4
                move.w  Math_QuarterSineTable-Math_SineTable(a4,d4.w),d0
                move.w  (a4,d4.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #3,d0
                asl.l   #3,d1
                move.l  d0,$1C(a0)
                move.l  d1,$18(a0)
                moveq   #0,d0
Projectile_SpawnType1A8AtAngle_Return:                  ; was: locret_E34A
                rts
; End of function Projectile_SpawnType1A8AtAngle

UnreferencedReturnE34C:                                 ; was: nullsub_25
                rts
; End of function UnreferencedReturnE34C
