Math_CalculateAngleToPlayer:                            ; was: sub_354A
                                        ; sub_2BFD0   p
                move.w  (PlayerCenterX).w,d0
                move.w  (PlayerCenterY).w,d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
Math_CalculateDirectionIndex:                           ; was: loc_355A
                                        ; Boss_SnakeSteerTowardTarget+1E   p
                bsr.s   Math_Arctan2Lookup
                asr.w   #7,d2
                andi.w  #$1FE,d2
                rts
; End of function Math_CalculateAngleToPlayer
; Calculates angle between two entities using arctan lookup
Math_CalculateAngleBetween:                             ; was: sub_3564
                movea.w a5,a4
                movea.w a0,a5
                bsr.s   Math_CalculateAngleToPlayer
                movea.w a5,a0
                movea.w a4,a5
                rts
; End of function Math_CalculateAngleBetween
; Unreachable wrapper that would preserve d0, d1 and a0 across the arctan lookup
Orphaned_MathArctan2WithPreserve:
                movem.l d0-d1/a0,-(sp)                  ; was: sub_3570
                jsr     Math_Arctan2Lookup(pc)          ; (pc)
                nop
                movem.l (sp)+,d0-d1/a0
                rts
; End of function Orphaned_MathArctan2WithPreserve
; Arctangent2 function using lookup table
Math_Arctan2Lookup:                                     ; was: sub_3580
                                        ; Orphaned_MathArctan2WithPreserve+4   p
                lea     Math_ArctangentTable(pc),a0
                nop
                tst.w   d0
                bmi.w   Math_Arctan2Lookup_NegativeX
                bne.w   Math_Arctan2Lookup_PositiveX
                tst.w   d1
                bmi.w   Math_Arctan2Lookup_ReturnThreeQuarterTurn
                bne.w   Math_Arctan2Lookup_ReturnQuarterTurn
Math_Arctan2Lookup_ReturnZero:                          ; was: loc_359A
                clr.w   d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_ReturnQuarterTurn:                   ; was: loc_359E
                move.w  #$4000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_ReturnThreeQuarterTurn:              ; was: loc_35A4
                move.w  #$C000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_ReturnHalfTurn:                      ; was: loc_35AA
                move.w  #$8000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_PositiveX:                           ; was: loc_35B0
                tst.w   d1
                beq.s   Math_Arctan2Lookup_ReturnZero
                bmi.w   Math_Arctan2Lookup_Quadrant4
                cmp.w   d0,d1
                bcs.w   Math_Arctan2Lookup_Quadrant1LowSlope
                bne.w   Math_Arctan2Lookup_Quadrant1HighSlope
                move.w  #$2000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant1LowSlope:                   ; was: loc_35C8
                clr.w   d2
                swap    d1
                clr.w   d1
                divu.w  d0,d1
                lsr.w   #8,d1
                add.w   d1,d1
                add.w   (a0,d1.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant1HighSlope:                  ; was: loc_35DA
                move.w  #$4000,d2
                swap    d0
                clr.w   d0
                divu.w  d1,d0
                lsr.w   #8,d0
                add.w   d0,d0
                sub.w   (a0,d0.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant4:                           ; was: loc_35EE
                neg.w   d1
                cmp.w   d0,d1
                bcs.w   Math_Arctan2Lookup_Quadrant4LowSlope
                bne.w   Math_Arctan2Lookup_Quadrant4HighSlope
                move.w  #$E000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant4LowSlope:                   ; was: loc_3600
                clr.w   d2
                swap    d1
                clr.w   d1
                divu.w  d0,d1
                lsr.w   #8,d1
                add.w   d1,d1
                sub.w   (a0,d1.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant4HighSlope:                  ; was: loc_3612
                move.w  #$C000,d2
                swap    d0
                clr.w   d0
                divu.w  d1,d0
                lsr.w   #8,d0
                add.w   d0,d0
                add.w   (a0,d0.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_NegativeX:                           ; was: loc_3626
                neg.w   d0
                tst.w   d1
                beq.w   Math_Arctan2Lookup_ReturnHalfTurn
                bmi.w   Math_Arctan2Lookup_Quadrant3
                cmp.w   d0,d1
                bcs.w   Math_Arctan2Lookup_Quadrant2LowSlope
                bne.w   Math_Arctan2Lookup_Quadrant2HighSlope
                move.w  #$6000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant2LowSlope:                   ; was: loc_3642
                move.w  #$8000,d2
                swap    d1
                clr.w   d1
                divu.w  d0,d1
                lsr.w   #8,d1
                add.w   d1,d1
                sub.w   (a0,d1.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant2HighSlope:                  ; was: loc_3656
                move.w  #$4000,d2
                swap    d0
                clr.w   d0
                divu.w  d1,d0
                lsr.w   #8,d0
                add.w   d0,d0
                add.w   (a0,d0.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant3:                           ; was: loc_366A
                neg.w   d1
                cmp.w   d0,d1
                bcs.w   Math_Arctan2Lookup_Quadrant3LowSlope
                bne.w   Math_Arctan2Lookup_Quadrant3HighSlope
                move.w  #$A000,d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant3LowSlope:                   ; was: loc_367C
                move.w  #$8000,d2
                swap    d1
                clr.w   d1
                divu.w  d0,d1
                lsr.w   #8,d1
                add.w   d1,d1
                add.w   (a0,d1.w),d2
                rts
; ---------------------------------------------------------------------------
Math_Arctan2Lookup_Quadrant3HighSlope:                  ; was: loc_3690
                move.w  #$C000,d2
                swap    d0
                clr.w   d0
                divu.w  d1,d0
                lsr.w   #8,d0
                add.w   d0,d0
                sub.w   (a0,d0.w),d2
                rts
; End of function Math_Arctan2Lookup
; ---------------------------------------------------------------------------
Math_ArctangentTable:   binclude "data/other/word_36A4.bin"  ; was: word_36A4
Math_ArctangentTable_End:                               ; was: word_36A4_End

; Unreachable: integer square root of d0 by a restoring bit-pair algorithm
Orphaned_MathSquareRoot:
                tst.l   d0                              ; was: sub_38A4
                beq.s   Orphaned_MathSquareRootReturn
                cmpi.l  #$10000,d0
                bcc.s   Orphaned_MathSquareRootComputeWordResult
                cmpi.w  #$271,d0
                bhi.s   Orphaned_MathSquareRootComputeByteResult
                move.w  d1,-(sp)
                move.w  #$FFFF,d1
Orphaned_MathSquareRootSmallValueLoop:                  ; was: loc_38BC
                addq.w  #2,d1
                sub.w   d1,d0
                bpl.s   Orphaned_MathSquareRootSmallValueLoop
                asr.w   #1,d1
                move.w  d1,d0
                move.w  (sp)+,d1
Orphaned_MathSquareRootReturn:                          ; was: locret_38C8
                rts
; ---------------------------------------------------------------------------
Orphaned_MathSquareRootComputeByteResult:               ; was: loc_38CA
                movem.w d1-d4,-(sp)
                move.w  #7,d4
                clr.w   d1
                clr.w   d2
Orphaned_MathSquareRootByteResultLoop:                  ; was: loc_38D6
                add.w   d0,d0
                addx.w  d1,d1
                add.w   d0,d0
                addx.w  d1,d1
                add.w   d2,d2
                move.w  d2,d3
                add.w   d3,d3
                cmp.w   d3,d1
                bls.s   Orphaned_MathSquareRootByteResultNextBit
                addq.w  #1,d2
                addq.w  #1,d3
                sub.w   d3,d1
Orphaned_MathSquareRootByteResultNextBit:               ; was: loc_38EE
                dbf     d4,Orphaned_MathSquareRootByteResultLoop
                move.w  d2,d0
                movem.w (sp)+,d1-d4
                rts
; ---------------------------------------------------------------------------
Orphaned_MathSquareRootComputeWordResult:               ; was: loc_38FA
                movem.l d1-d4,-(sp)
                moveq   #$D,d4
                moveq   #0,d1
                moveq   #0,d2
Orphaned_MathSquareRootWordResultLoop:                  ; was: loc_3904
                add.l   d0,d0
                addx.w  d1,d1
                add.l   d0,d0
                addx.w  d1,d1
                add.w   d2,d2
                move.w  d2,d3
                add.w   d3,d3
                cmp.w   d3,d1
                bls.s   Orphaned_MathSquareRootWordResultBit15
                addq.w  #1,d2
                addq.w  #1,d3
                sub.w   d3,d1
Orphaned_MathSquareRootWordResultBit15:                 ; was: loc_391C
                dbf     d4,Orphaned_MathSquareRootWordResultLoop
                add.l   d0,d0
                addx.w  d1,d1
                add.l   d0,d0
                addx.l  d1,d1
                add.w   d2,d2
                move.l  d2,d3
                add.w   d3,d3
                cmp.l   d3,d1
                bls.s   Orphaned_MathSquareRootWordResultBit16
                addq.w  #1,d2
                addq.w  #1,d3
                sub.l   d3,d1
Orphaned_MathSquareRootWordResultBit16:                 ; was: loc_3938
                add.l   d0,d0
                addx.l  d1,d1
                add.l   d0,d0
                addx.l  d1,d1
                add.w   d2,d2
                move.l  d2,d3
                add.l   d3,d3
                cmp.l   d3,d1
                bls.s   Orphaned_MathSquareRootFinishWordResult
                addq.w  #1,d2
Orphaned_MathSquareRootFinishWordResult:                ; was: loc_394C
                move.w  d2,d0
                movem.l (sp)+,d1-d4
                rts
; End of function Orphaned_MathSquareRoot
; Adds BCD value to score with overflow check and clamping
