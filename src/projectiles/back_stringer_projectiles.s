Projectile_BackStringerFallingDropMain:                 ; was: sub_4577C
                tst.w   (SecondaryEntityType).w
                beq.s   Projectile_BackStringerRetireFallingDrop
                cmpi.w  #$17C,$14(a5)
                bmi.s   Projectile_BackStringerUpdateFallingDrop
Projectile_BackStringerRetireFallingDrop:               ; was: loc_4578A
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateFallingDrop:               ; was: loc_45792
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_BackStringerBounceFallingDrop
                tst.w   $24(a5)
                bpl.s   Projectile_BackStringerUpdateFallingDropMotion
Projectile_BackStringerBounceFallingDrop:               ; was: loc_4579E
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.b   $21(a5)
                clr.w   $24(a5)
                eori.w  #$1000,$E(a5)
                move.l  #$FFFD0000,$1C(a5)
                bsr.w   Projectile_BackStringerChooseFallingDropVelocity
Projectile_BackStringerUpdateFallingDropMotion:         ; was: loc_457C2
                bset    #3,$E(a5)
                addq.w  #1,$48(a5)
                btst    #2,$49(a5)
                bne.s   Projectile_BackStringerUpdateActiveFallingDrop
                bclr    #3,$E(a5)
Projectile_BackStringerUpdateActiveFallingDrop:         ; was: loc_457DA
                tst.b   $21(a5)
                beq.w   Projectile_BackStringerUpdateReleasedFallingDrop
                movea.w #(SecondaryEntityType-M68K_RAM),a4
                move.w  4(a5),d0
                bne.w   Projectile_BackStringerAttachDropToCompanion
                move.w  $48(a5),d0
                andi.w  #7,d0
                bne.s   Projectile_BackStringerSteerFallingDrop
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   $5C(a5),d0
                move.w  d0,$5E(a5)
Projectile_BackStringerSteerFallingDrop:                ; was: loc_4580A
                move.w  $5E(a5),d0
                cmp.w   $10(a5),d0
                bpl.s   Projectile_BackStringerCheckRightwardDropSteering
                tst.w   $18(a5)
                bpl.s   Projectile_BackStringerAccelerateDropLeft
                cmpi.w  #$FFFE,$18(a5)
                bmi.s   Projectile_BackStringerApplyFallingDropGravity
Projectile_BackStringerAccelerateDropLeft:              ; was: loc_45822
                subi.l  #$1000,$18(a5)
                bra.s   Projectile_BackStringerApplyFallingDropGravity
; ---------------------------------------------------------------------------
Projectile_BackStringerCheckRightwardDropSteering:      ; was: loc_4582C
                tst.w   $18(a5)
                bmi.s   Projectile_BackStringerAccelerateDropRight
                cmpi.w  #2,$18(a5)
                bpl.s   Projectile_BackStringerApplyFallingDropGravity
Projectile_BackStringerAccelerateDropRight:             ; was: loc_4583A
                addi.l  #$1000,$18(a5)
Projectile_BackStringerApplyFallingDropGravity:         ; was: loc_45842
                                        ; Projectile_BackStringerFallingDropMain+AE   j
                addi.l  #$1800,$1C(a5)
                cmpi.w  #$FFFF,$1C(a5)
                bmi.s   Projectile_BackStringerCheckFallingDropContact
                move.l  #$FFFDC000,$1C(a5)
Projectile_BackStringerCheckFallingDropContact:         ; was: loc_4585A
                move.w  $14(a5),d0
                subi.w  #$A,d0
                cmp.w   $14(a4),d0
                bpl.s   Projectile_BackStringerFallingDropReturn
                addq.w  #2,4(a5)
                clr.l   $18(a5)
                move.l  #$4000,$1C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$20,d0                         ; ' '
                move.w  d0,$48(a5)
Projectile_BackStringerFallingDropReturn:               ; was: locret_45888
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerAttachDropToCompanion:           ; was: loc_4588A
                bset    #0,$5E(a4)
                addq.w  #1,$5C(a4)
                move.w  $14(a4),d0
                addi.w  #$A,d0
                move.w  d0,$14(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateReleasedFallingDrop:       ; was: loc_458A2
                addi.l  #$4000,$1C(a5)
                bset    #7,2(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_BackStringerReleasedFallingDropReturn
                bclr    #7,2(a5)
Projectile_BackStringerReleasedFallingDropReturn:       ; was: locret_458BE
                rts
; End of function Projectile_BackStringerFallingDropMain
; Chooses alternating random horizontal velocity for a bouncing drop
Projectile_BackStringerChooseFallingDropVelocity:       ; was: sub_458C0
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                btst    #1,(FrameCounter+1).w
                bne.s   Projectile_BackStringerStoreFallingDropVelocity
                neg.l   d0
Projectile_BackStringerStoreFallingDropVelocity:        ; was: loc_458D2
                move.l  d0,$18(a5)
                rts
; End of function Projectile_BackStringerChooseFallingDropVelocity
; Spawns the mirrored angled shots used during transformation
Boss_BackStringerSpawnDualAngledShots:                  ; was: sub_458D8
                move.w  $70(a5),d5
                move.w  $74(a5),d6
                subi.w  #$10,d6
                moveq   #2,d3
                move.w  #$180,d4
                moveq   #8,d7
                bsr.s   Projectile_SpawnBackStringerAngledShot
                moveq   #$FFFFFFFE,d3
                move.w  #$80,d4
                moveq   #$FFFFFFF8,d7
; End of function Boss_BackStringerSpawnDualAngledShots
; Creates one transformation shot with caller-provided angle parameters
Projectile_SpawnBackStringerAngledShot:                 ; was: sub_458F6
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_SpawnBackStringerAngledShotReturn
                move.w  #$328,(a0)
                move.w  #$CC80,2(a0)
                move.l  #Projectile_BackStringerAngledShotMappingA,8(a0)
                move.w  #$A300,$E(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FE02FE02,$2C(a0)
                move.w  #$88,$26(a0)
                move.w  #1,$1C(a0)
                move.w  d5,$10(a0)
                move.w  d6,$14(a0)
                move.w  d7,$48(a0)
                move.w  d3,$4E(a0)
                move.w  d4,$56(a0)
Projectile_SpawnBackStringerAngledShotReturn:           ; was: locret_45944
                rts
; End of function Projectile_SpawnBackStringerAngledShot
; Updates an angled shot, its collision conversion, and its rebound copy
Projectile_BackStringerAngledShotMain:                  ; was: sub_45946
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_BackStringerConvertAngledShotToImpact
                bclr    #7,$22(a5)
                beq.s   Projectile_BackStringerUpdateAngledShotFlight
                bclr    #4,$22(a5)
                beq.s   Projectile_BackStringerConvertAngledShotToImpact
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_BackStringerConvertAngledShotToImpact
                jsr     (Pickup_SpawnLarge).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
Projectile_BackStringerConvertAngledShotToImpact:       ; was: loc_45976
                                        ; Projectile_BackStringerAngledShotMain+14   j
                move.l  $18(a5),d0
                asr.l   #3,d0
                neg.l   d0
                move.l  d0,$18(a5)
                move.l  $1C(a5),d0
                asr.l   #3,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                move.l  #SharedCombatSpriteAnimation02,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateAngledShotFlight:          ; was: loc_4599C
                subi.l  #$1000,$1C(a5)
                cmpi.w  #$90,$14(a5)
                bpl.s   Projectile_BackStringerUpdateAngledShotSpin
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateAngledShotSpin:            ; was: loc_459B4
                move.w  $4C(a5),d0
                add.w   $4E(a5),d0
                andi.w  #6,d0
                move.w  d0,$4C(a5)
                andi.w  #$E7FF,$E(a5)
                lea     (SpriteFlipBitsTable).l,a0
                move.w  (a0,d0.w),d0
                or.w    d0,$E(a5)
                move.w  $56(a5),d0
                add.w   $48(a5),d0
                andi.w  #$1FE,d0
                move.w  d0,$56(a5)
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d0.w),d0
                ext.l   d0
                asl.l   #4,d0
                move.l  d0,$18(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   Projectile_BackStringerAngledShotReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_BackStringerAngledShotReturn
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $18(a5),d0
                move.l  $1C(a5),d1
                neg.l   d0
                neg.l   d1
                asl.l   #1,d0
                asl.l   #1,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                add.l   d0,$10(a0)
                add.l   d1,$14(a0)
                move.w  #$360,(a0)
                move.w  #$EC80,2(a0)
                move.w  #$A300,$E(a0)
                move.l  #Projectile_BackStringerReboundShotAnimation,8(a0)
                move.w  $4E(a5),$4A(a0)
                clr.b   $20(a0)
Projectile_BackStringerAngledShotReturn:                ; was: locret_45A58
                                        ; Projectile_BackStringerAngledShotMain+C2   j
                rts
; End of function Projectile_BackStringerAngledShotMain
; Animates the rebound shot until its lifetime counter expires
Projectile_BackStringerReboundShotMain:                 ; was: sub_45A5A
                cmpi.w  #$80,$C(a5)
                bmi.s   Projectile_BackStringerUpdateReboundShotFrame
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateReboundShotFrame:          ; was: loc_45A6A
                move.w  $48(a5),d0
                add.w   $4A(a5),d0
                andi.w  #6,d0
                move.w  d0,$48(a5)
                andi.w  #$E7FF,$E(a5)
                lea     (SpriteFlipBitsTable).l,a0
                move.w  (a0,d0.w),d0
                or.w    d0,$E(a5)
                rts
; End of function Projectile_BackStringerReboundShotMain
; Chain segment falling state
Projectile_BackStringerChainFalling:                    ; was: sub_45A90
                cmpi.w  #$170,$14(a5)
                bmi.s   Projectile_BackStringerUpdateFallingChain
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateFallingChain:              ; was: loc_45AA0
                addi.l  #$2000,$1C(a5)
                move.w  $5C(a5),d0
                add.w   d0,$56(a5)
                tst.w   $48(a5)
                bne.s   Projectile_BackStringerUpdateFallingChainFrame
                movea.w a5,a0
                move.w  $56(a5),d0
                move.w  #$8300,$E(a5)
                move.w  $4A(a5),d1
                bra.w   Boss_BackStringerSelectPartFrameFromAngle
; ---------------------------------------------------------------------------
Projectile_BackStringerUpdateFallingChainFrame:         ; was: loc_45ACA
                jmp     Sprite_SelectEightDirectionFrame
; End of function Projectile_BackStringerChainFalling
