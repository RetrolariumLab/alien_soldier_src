; Sniper Honeyviper destruction debris, line-scroll shaping, and angled effect spawning

; Spawns random debris particle sprites during boss destruction
Boss_SniperHoneyviperSpawnDebris:                       ; was: sub_36FEE
                move.w  #3,(PlaneAShakeLevel).w
                jsr     (Projectile_PrepareImpactSpawn).l
                bne.s   Boss_SniperHoneyviperSpawnDebrisReturn
                jsr     (Sprite_InitType58FromTable).l
                clr.b   $20(a0)
                move.w  #$FFFA,$1C(a0)
                move.w  (RandomNumberState+2).w,$1E(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$1F,d1
                subi.w  #$24,d0                         ; '$'
                subi.w  #$24,d1                         ; '$'
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
Boss_SniperHoneyviperSpawnDebrisReturn:                 ; was: locret_37046
                rts
; End of function Boss_SniperHoneyviperSpawnDebris
; Rebuilds Sniper Honeyviper's line-scroll spans and derives its screen position
Boss_SniperHoneyviperUpdatePositionAndLineScroll:       ; was: sub_37048
                                        ; Boss_SniperHoneyviperUpdateMotionPipeline   p
                movea.w #(HScrollPlaneBRow32-M68K_RAM),a0
                moveq   #$FFFFFF80,d0
                move.w  #$BF,d7
Boss_SniperHoneyviperScrollInitializeLineOffsets:       ; was: loc_37052
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Boss_SniperHoneyviperScrollInitializeLineOffsets
                move.w  $50(a5),d0
                bmi.s   Boss_SniperHoneyviperScrollUpdateCoordinates
                moveq   #0,d0
Boss_SniperHoneyviperScrollUpdateCoordinates:           ; was: loc_37062
                add.w   $74(a5),d0
                subi.w  #$3A,d0                         ; ':'
                move.w  d0,$14(a5)
                move.w  $70(a5),d0
                add.w   $4C(a5),d0
                move.w  d0,$10(a5)
                moveq   #$17,d0
                sub.w   $74(a5),d0
                move.w  d0,(SniperHoneyviperRasterControl).w
                moveq   #0,d6
                move.w  $70(a5),d6
                subi.w  #$A8,d6
                move.w  $74(a5),d2
                subi.w  #$80,d2
                asl.w   #2,d2
                addi.w  #-$1BFE,d2
                movea.w d2,a1
                moveq   #$32,d7                         ; '2'
Boss_SniperHoneyviperScrollFillUpperSpan:               ; was: loc_370A0
                move.w  d6,(a1)
                subq.w  #4,a1
                dbf     d7,Boss_SniperHoneyviperScrollFillUpperSpan
                move.w  $74(a5),d7
                sub.w   $14(a5),d7
                subi.w  #$38,d7                         ; '8'
                moveq   #0,d1
                move.w  $10(a5),d1
                sub.w   $70(a5),d1
                ext.l   d1
                asl.l   #4,d1
                divs.w  d7,d1
                swap    d1
                move.w  #0,d1
                asr.l   #4,d1
                subq.w  #1,d7
Boss_SniperHoneyviperScrollInterpolateSpan:             ; was: loc_370CE
                move.w  d6,(a1)
                subq.w  #4,a1
                swap    d6
                add.l   d1,d6
                swap    d6
                dbf     d7,Boss_SniperHoneyviperScrollInterpolateSpan
                moveq   #$FFFFFFD0,d1
                move.w  $14(a5),d0
                sub.w   d0,d1
                move.w  d1,(VScrollPlaneBColumn0).w
                subi.w  #$80,d0
                move.w  d0,$4A(a5)
                move.w  $10(a5),d6
                subi.w  #$A8,d6
                moveq   #$45,d7                         ; 'E'
Boss_SniperHoneyviperScrollFillLowerSpan:               ; was: loc_370FA
                move.w  d6,(a1)
                subq.w  #4,a1
                dbf     d7,Boss_SniperHoneyviperScrollFillLowerSpan
                rts
; End of function Boss_SniperHoneyviperUpdatePositionAndLineScroll
; Unreferenced helper that spawns a type-$94 object at a random table angle
Orphaned_SpawnType94RandomAngle:                        ; was: sub_37104
                btst    #0,(FrameCounter+1).w
                bne.s   Orphaned_SpawnType94RandomAngleReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Orphaned_SpawnType94RandomAngleReturn
                movea.l #Projectile_SpawnSpriteFrames,a1
                jsr     (Sprite_InitType94FromTable).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$7E,d0                         ; '~'
                addi.w  #$C0,d0
                movea.l #Math_SineTable,a1
                move.w  -$80(a1,d0.w),d1
                move.w  (a1,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   #3,d1
                asl.l   #4,d2
                move.l  d1,$1C(a0)
                move.l  d2,$18(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$F808F808,$2C(a0)
                move.w  #$14,$26(a0)
Orphaned_SpawnType94RandomAngleReturn:                  ; was: locret_3715E
                                        ; Orphaned_SpawnType94RandomAngle+E   j
                rts
; End of function Orphaned_SpawnType94RandomAngle
