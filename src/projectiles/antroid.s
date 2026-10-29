; Antroid randomized wait-state projectile

; Spawns a type $158 shot with randomized launch velocity
Boss_AntroidSpawnWaitProjectile:                        ; was: sub_37FEC
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_AntroidSpawnWaitProjectileReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_AntroidSpawnWaitProjectileReturn
                move.w  #$158,(a0)
                move.w  #$8D00,2(a0)
                move.w  #$C3C3,$E(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                move.b  #8,$20(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FA06FA06,$2C(a0)
                move.w  #$3A,$26(a0)                    ; ':'
                move.w  $D0(a5),$10(a0)
                move.w  $D4(a5),$14(a0)
                addq.w  #8,$10(a0)
                addq.w  #8,$14(a0)
                move.w  #5,$48(a0)
                clr.w   $4A(a0)
                move.l  #$1200,$4C(a0)
                moveq   #0,d0
                move.w  #$20,d1                         ; ' '
                sub.w   $11C(a5),d1
                addq.w  #2,d1
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                add.w   d1,d0
                swap    d0
                asr.l   #2,d0
                move.l  d0,$18(a0)
                moveq   #0,d0
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                swap    d0
                neg.l   d0
                asr.l   #2,d0
                move.l  d0,$1C(a0)
                tst.w   $54(a5)
                beq.s   Boss_AntroidSpawnWaitProjectileReturn
                neg.l   $18(a0)
                neg.l   $4C(a0)
                subi.w  #$10,$10(a0)
Boss_AntroidSpawnWaitProjectileReturn:                  ; was: locret_380A2
                                        ; Boss_AntroidSpawnWaitProjectile+10   j
                rts
; End of function Boss_AntroidSpawnWaitProjectile

; Updates type $158 motion, rebound, palette steps, and removal
Projectile_AntroidUpdate:                               ; was: sub_380A4
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_AntroidDeactivate
                bclr    #7,$22(a5)
                beq.s   Projectile_AntroidApplyMotion
                bclr    #4,$22(a5)
                beq.s   Projectile_AntroidDeactivate
                move.w  #3,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
Projectile_AntroidApplyMotion:                          ; was: loc_380C4
                move.l  $4C(a5),d0
                sub.l   d0,$18(a5)
                addi.l  #$6000,$1C(a5)
                bmi.s   Projectile_AntroidAdvancePalette
                cmpi.w  #$144,$14(a5)
                bmi.s   Projectile_AntroidAdvancePalette
                move.l  #$FFFD8000,$1C(a5)
                clr.b   $21(a5)
Projectile_AntroidAdvancePalette:                       ; was: loc_380EA
                                        ; Projectile_AntroidUpdate+38   j
                subq.w  #1,$48(a5)
                bpl.s   Projectile_AntroidReturn
                move.w  $4A(a5),d0
                cmpi.w  #6,d0
                bmi.s   Projectile_AntroidApplyNextPalette
Projectile_AntroidDeactivate:                           ; was: loc_380FA
                                        ; Projectile_AntroidUpdate+14   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
; Advances through the three palette attributes after each delay
Projectile_AntroidApplyNextPalette:                     ; was: loc_38102
                move.w  Projectile_AntroidPaletteStages(pc,d0.w),$E(a5)
                move.w  #6,$48(a5)
                addq.w  #2,$4A(a5)
Projectile_AntroidReturn:                               ; was: locret_38112
                rts
; End of function Projectile_AntroidUpdate
; ---------------------------------------------------------------------------
Projectile_AntroidPaletteStages:    dc.w    $C3C7, $C3CB, $C3CF  ; was: word_38114
