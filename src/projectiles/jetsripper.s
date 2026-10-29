; Creates Jetsripper projectile with trajectory
Boss_JetsripperSpawnProjectile:                         ; was: sub_362CE
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Boss_JetsripperSpawnProjectileReturn
                move.w  #$1FC,(a0)
                move.w  #$8D00,2(a0)
                move.w  #$C400,$E(a0)
                move.w  #$F00,8(a0)
                move.w  #$F0F0,$A(a0)
                move.b  #$C0,$21(a0)
                move.b  #$10,$23(a0)
                move.l  #$F20EF20E,$2C(a0)
                move.l  #$F010F010,$28(a0)
                move.w  #$32,$26(a0)                    ; '2'
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #$20000,$4C(a0)
                move.l  #$40000,$54(a0)
                move.l  #$1000,$48(a0)
                move.l  #$2000,$50(a0)
                move.w  #9,$58(a0)
                move.w  (PlayerXPosition).w,d0
                cmp.w   $10(a5),d0
                bpl.s   Boss_JetsripperSetProjectileVelocity
                neg.l   $48(a0)
                neg.l   $4C(a0)
; Sets projectile velocity based on boss position
Boss_JetsripperSetProjectileVelocity:                   ; was: loc_3635A
                move.l  $4C(a0),$18(a0)
                move.l  $54(a0),$1C(a0)
Boss_JetsripperSpawnProjectileReturn:                   ; was: locret_36366
                rts
; End of function Boss_JetsripperSpawnProjectile
; Updates projectile with bouncing logic
Projectile_JetsripperMain:                              ; was: sub_36368
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$8B0,d0
                bpl.s   Boss_JetsripperProjectileDeactivate
                cmpi.w  #$6D0,d0
                bmi.s   Boss_JetsripperProjectileDeactivate
                tst.w   (StageSpawnCountdown).w
                bmi.s   Boss_JetsripperProjectileHandleImpact
Boss_JetsripperProjectileDeactivate:                    ; was: loc_36382
                                        ; Projectile_JetsripperMain+12   j
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Boss_JetsripperProjectileHandleImpact:                  ; was: loc_3638A
                bclr    #7,$22(a5)
                beq.s   Boss_JetsripperProjectileCheckBounce
                bclr    #4,$22(a5)
                beq.s   Boss_JetsripperProjectileBurst
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_JetsripperProjectileBurst
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                jsr     (Pickup_SpawnLarge).l
Boss_JetsripperProjectileBurst:                         ; was: loc_363B4
                                        ; Projectile_JetsripperMain+38   j
                clr.l   $18(a5)
                clr.l   $1C(a5)
                jmp     Enemy_SpawnQuadProjectiles
; ---------------------------------------------------------------------------
Boss_JetsripperProjectileCheckBounce:                   ; was: loc_363C2
                tst.w   $50(a5)
                bmi.s   Boss_JetsripperProjectileCheckUpperBounce
                cmpi.w  #$144,$14(a5)
                bmi.s   Boss_JetsripperProjectileUpdateTrajectory
Boss_JetsripperProjectileReverseBounce:                 ; was: loc_363D0
                move.l  $4C(a5),$18(a5)
                neg.l   $54(a5)
                neg.l   $50(a5)
                move.l  $54(a5),$1C(a5)
                move.w  #9,$58(a5)
                bra.s   Boss_JetsripperProjectileUpdateTrajectory
; ---------------------------------------------------------------------------
Boss_JetsripperProjectileCheckUpperBounce:              ; was: loc_363EC
                cmpi.w  #$CC,$14(a5)
                bmi.s   Boss_JetsripperProjectileReverseBounce
Boss_JetsripperProjectileUpdateTrajectory:              ; was: loc_363F4
                                        ; Projectile_JetsripperMain+82   j
                subq.w  #1,$58(a5)
                bmi.s   Boss_JetsripperProjectileApplyPalette
                move.l  $48(a5),d0
                sub.l   d0,$18(a5)
                move.l  $50(a5),d0
                sub.l   d0,$1C(a5)
; Applies the current global palette bits to the projectile
Boss_JetsripperProjectileApplyPalette:                  ; was: loc_3640A
                andi.w  #$E7FF,$E(a5)
                move.w  (GlobalSpriteFlipBits).w,d0
                or.w    d0,$E(a5)
                rts
; End of function Projectile_JetsripperMain
