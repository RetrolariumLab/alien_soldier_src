; Spawns chain of connected projectiles
Boss_ViblackSpawnChain:                                 ; was: sub_443A4
                cmpi.w  #$CE,$14(a5)
                bmi.w   Boss_ViblackSpawnChainReturn
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                tst.w   (a0)
                beq.s   Boss_ViblackAllocateChainObjects
                movea.w #(QuaternaryEntityType-M68K_RAM),a0
                tst.w   (a0)
                bne.w   Boss_ViblackSpawnChainReturn
Boss_ViblackAllocateChainObjects:                       ; was: loc_443C0
                move.b  #$CE,d0
                jsr     (Sound_QueueSFXRequest).l
                movea.w #(SharedSpriteScratch-M68K_RAM),a1
                move.w  a0,(a1)+
                moveq   #9,d6
Boss_ViblackAllocateChainObjectLoop:                    ; was: loc_443D2
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.w   Boss_ViblackSpawnChainReturn
                move.w  #$10,(a0)
                bset    #4,2(a0)
                move.w  a0,(a1)+
                dbf     d6,Boss_ViblackAllocateChainObjectLoop
                movea.w #(SharedSpriteScratch-M68K_RAM),a3
                movea.w (a3)+,a0
                move.w  #$2EC,(a0)
                move.w  #$8D00,2(a0)
                move.w  #$2E,$24(a0)                    ; '.'
                move.w  #$80,$40(a0)
                move.w  #$10,$44(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #2,d0
                move.w  d0,$42(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$7E,d0                         ; '~'
                addi.w  #$140,d0
                move.w  d0,6(a0)
                bsr.w   Boss_ViblackInitChainSegment
                movea.w a0,a1
                movea.w a0,a2
                adda.w  #$48,a1                         ; 'H'
                move.w  (PrimaryCameraXPosition).w,d4
                add.w   $10(a5),d4
                move.w  $14(a5),d5
                moveq   #9,d6
Boss_ViblackInitializeChainSegmentLoop:                 ; was: loc_44444
                movea.w (a3)+,a0
                move.w  #$2F0,(a0)
                move.w  #$8000,2(a0)
                move.w  a0,(a1)+
                move.w  a2,6(a0)
                move.w  d4,$48(a0)
                move.w  d4,$4A(a0)
                move.w  d4,$4C(a0)
                move.w  d4,$4E(a0)
                move.w  d5,$50(a0)
                move.w  d5,$52(a0)
                move.w  d5,$54(a0)
                move.w  d5,$56(a0)
                bsr.s   Boss_ViblackInitChainSegment
                move.w  #$7000,$24(a0)
                dbf     d6,Boss_ViblackInitializeChainSegmentLoop
Boss_ViblackSpawnChainReturn:                           ; was: locret_44482
                                        ; Boss_ViblackSpawnChain+18   j
                rts
; End of function Boss_ViblackSpawnChain
; Initializes chain segment object properties
Boss_ViblackInitChainSegment:                           ; was: sub_44484
                                        ; Boss_ViblackSpawnChain+D2   p
                clr.w   4(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.b  #$7C,$20(a0)                    ; '|'
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                clr.b   $21(a0)
                move.l  #$FF01FF01,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #$4E,$26(a0)                    ; 'N'
                rts
; End of function Boss_ViblackInitChainSegment
; Chain projectile main handler
Projectile_ViblackChainMain:                            ; was: sub_444C2
                tst.w   (StageSpawnCountdown).w
                bpl.s   Projectile_ViblackChainReleaseSegments
                tst.w   $24(a5)
                bpl.s   Projectile_ViblackChainUpdateLaunchedController
Projectile_ViblackChainReleaseSegments:                 ; was: loc_444CE
                movea.w a5,a1
                adda.w  #$48,a1                         ; 'H'
                moveq   #2,d6
                moveq   #9,d7
Projectile_ViblackChainReleaseSegmentLoop:              ; was: loc_444D8
                movea.w (a1)+,a0
                clr.b   $21(a0)
                move.w  d6,6(a0)
                move.w  #4,4(a0)
                addq.w  #2,d6
                dbf     d7,Projectile_ViblackChainReleaseSegmentLoop
                clr.l   $18(a5)
                clr.l   $1C(a5)
Projectile_ViblackChainLaunch:                          ; was: loc_444F6
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  #$42000,$1C(a5)
                lea     (Projectile_SpawnSpriteFrames).l,a1  ; make offsets?
                jmp     Sprite_InitCurrentFromTable
; ---------------------------------------------------------------------------
Projectile_ViblackChainUpdateLaunchedController:        ; was: loc_44514
                cmpi.w  #$200,$14(a5)
                bmi.s   Projectile_ViblackChainUpdateAttachedSegments
                bset    #4,2(a5)
                movea.w a5,a1
                adda.w  #$48,a1                         ; 'H'
                moveq   #9,d7
Projectile_ViblackChainRetireSegmentLoop:               ; was: loc_4452A
                movea.w (a1)+,a0
                move.w  #2,4(a0)
                dbf     d7,Projectile_ViblackChainRetireSegmentLoop
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackChainUpdateAttachedSegments:          ; was: loc_44538
                andi.w  #$1F8,6(a5)
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  $14(a5),d1
                move.w  6(a5),d3
                addi.w  #$20,d3                         ; ' '
                asr.w   #5,d3
                andi.w  #$E,d3
                moveq   #0,d7
                tst.w   $44(a5)
                bpl.s   Projectile_ViblackChainSelectMapping
                move.w  #$8000,d7
                move.b  #$10,$20(a5)
                move.b  #$C0,$21(a5)
Projectile_ViblackChainSelectMapping:                   ; was: loc_44570
                lea     Projectile_ViblackChainMappingWords(pc),a0
                nop
                move.w  (a0,d3.w),$E(a5)
                or.w    d7,$E(a5)
                or.w    d7,d3
                movea.w a5,a3
                adda.w  #$48,a3                         ; 'H'
                moveq   #9,d7
Projectile_ViblackChainShiftSegmentHistoryLoop:         ; was: loc_4458A
                movea.w (a3)+,a0
                movea.w a0,a1
                movea.w a0,a2
                adda.w  #$48,a0                         ; 'H'
                adda.w  #$50,a1                         ; 'P'
                adda.w  #$58,a2                         ; 'X'
                moveq   #3,d6
Projectile_ViblackChainShiftHistorySamplesLoop:         ; was: loc_4459E
                move.w  (a0),d2
                move.w  d0,(a0)+
                move.w  d2,d0
                move.w  (a1),d2
                move.w  d1,(a1)+
                move.w  d2,d1
                move.w  (a2),d2
                move.w  d3,(a2)+
                move.w  d2,d3
                dbf     d6,Projectile_ViblackChainShiftHistorySamplesLoop
                dbf     d7,Projectile_ViblackChainShiftSegmentHistoryLoop
                move.w  6(a5),d2
                moveq   #$14,d3
                tst.w   $44(a5)
                bpl.s   Projectile_ViblackChainApplyMotion
                moveq   #$F,d3
Projectile_ViblackChainApplyMotion:                     ; was: loc_445C6
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d2.w),d0
                move.w  (a0,d2.w),d1
                ext.l   d1
                muls.w  d3,d0
                asl.l   #3,d1
                move.l  d0,$1C(a5)
                move.l  d1,$18(a5)
                subq.w  #1,$44(a5)
                bpl.s   Projectile_ViblackChainMainReturn
                move.w  $40(a5),d2
                sub.w   6(a5),d2
                bmi.w   Projectile_ViblackChainCheckNegativeAngleDistance
                bne.s   Projectile_ViblackChainCheckPositiveAngleDistance
                eori.w  #2,$42(a5)
                move.w  $42(a5),d0
                move.w  Projectile_ViblackChainTargetAngles(pc,d0.w),$40(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackChainCheckPositiveAngleDistance:      ; was: loc_44608
                cmpi.w  #$100,d2
                bpl.w   Projectile_ViblackChainDecreaseAngle
Projectile_ViblackChainIncreaseAngle:                   ; was: loc_44610
                addq.w  #8,6(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackChainCheckNegativeAngleDistance:      ; was: loc_44616
                cmpi.w  #$FF00,d2
                bmi.w   Projectile_ViblackChainIncreaseAngle
; Decreases the chain angle toward its target
Projectile_ViblackChainDecreaseAngle:                   ; was: loc_4461E
                subq.w  #8,6(a5)
Projectile_ViblackChainMainReturn:                      ; was: locret_44622
                rts
; End of function Projectile_ViblackChainMain
; ---------------------------------------------------------------------------
Projectile_ViblackChainTargetAngles:    dc.w    $10, $F0  ; was: word_44624

; Chain segment handler
Projectile_ViblackChainSegment:                         ; was: sub_44628
                tst.w   4(a5)
                beq.s   Projectile_ViblackChainSegmentFollowHistory
                cmpi.w  #4,4(a5)
                beq.s   Projectile_ViblackChainSegmentLaunchDelay
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackChainSegmentLaunchDelay:              ; was: loc_4463E
                subq.w  #1,6(a5)
                bmi.w   Projectile_ViblackChainLaunch
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackChainSegmentFollowHistory:            ; was: loc_44648
                movea.w 6(a5),a0
                move.w  $4E(a5),d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  $56(a5),$14(a5)
                move.w  $5E(a5),d3
                moveq   #0,d0
                bclr    #$F,d3
                beq.s   Projectile_ViblackChainSetGraphics
                move.b  #$10,$20(a5)
                move.w  #$8000,d0
                move.b  #$C0,$21(a5)
; Sets graphics tile and priority for chain
Projectile_ViblackChainSetGraphics:                     ; was: loc_4467A
                lea     Projectile_ViblackChainMappingWords(pc),a1
                nop
                move.w  (a1,d3.w),$E(a5)
                or.w    d0,$E(a5)
                move.w  #$7000,d0
                sub.w   $24(a5),d0
                sub.w   d0,$24(a0)
                move.w  #$7000,$24(a5)
                rts
; End of function Projectile_ViblackChainSegment
; ---------------------------------------------------------------------------
Projectile_ViblackChainMappingWords:    dc.w    $6389, $7380, $7392, $7B80, $6B89, $6B80, $6392, $6380  ; was: word_4469E
                                        ; Projectile_ViblackChainSegment:Projectile_ViblackChainSetGraphics   o
