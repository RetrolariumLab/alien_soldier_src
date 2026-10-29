; Calculates angle from X/Y velocity components
Physics_CalculateAngleFromVelocity:
                pea     Physics_AddAngleOffset(pc)      ; was: sub_427B0
                lea     Physics_AngleOctantBaseTable(pc),a0
                ext.l   d0
                beq.s   Physics_ReturnVerticalAxisAngle
                bpl.s   Physics_NormalizeVelocityX
                neg.l   d0
                addq.l  #4,a0
Physics_NormalizeVelocityX:                             ; CODE XREF: Physics_CalculateAngleFromVelocity+C   j  ; was: loc_427C2
                ext.l   d1
                beq.s   Physics_ReturnHorizontalAxisAngle
                bpl.s   Physics_NormalizeVelocityY
                neg.l   d1
                addq.l  #2,a0
Physics_NormalizeVelocityY:                             ; CODE XREF: Physics_CalculateAngleFromVelocity+16   j  ; was: loc_427CC
                bra.s   Physics_OrderAngleRatioComponents
; End of function Physics_CalculateAngleFromVelocity
; Computes a vertical-axis angle from the target position
Physics_CalculateVerticalTargetAngle:                   ; CODE XREF: Physics_CalculateAngleToTarget+1C   j  ; was: sub_427CE
                move.w  $14(a4),d1
                sub.w   $14(a5),d1
Physics_ReturnVerticalAxisAngle:                        ; CODE XREF: Physics_CalculateAngleFromVelocity+A   j  ; was: loc_427D6
                move.w  d1,d0
                lsr.w   #8,d0
                andi.w  #$80,d0
                addi.w  #$40,d0                         ; '@'
                rts
; End of function Physics_CalculateVerticalTargetAngle
; Returns the horizontal-axis angle selected by the current octant
Physics_ReturnHorizontalAxisAngle:                      ; CODE XREF: Physics_CalculateAngleFromVelocity+14   j  ; was: sub_427E4
                                        ; Physics_CalculateAngleToTarget+2C   j
                move.b  (a0),d0
                andi.w  #$80,d0
                rts
; ---------------------------------------------------------------------------
; Calculates the angle from the source object to a target object
Physics_CalculateAngleToTarget:                         ; CODE XREF: Boss_LovePenguinCalculateAngleAndFlip+E   p  ; was: loc_427EC
                                        ; Boss_LovePenguinMainDispatcher+18   p
                pea     Physics_AddAngleOffset(pc)
                lea     Physics_AngleOctantBaseTable(pc),a0
                moveq   #0,d0
                moveq   #0,d1
                move.w  $10(a4),d0
                sub.w   $10(a5),d0
                beq.s   Physics_CalculateVerticalTargetAngle
                bgt.s   Physics_NormalizeTargetDeltaX
                neg.w   d0
                addq.l  #4,a0
Physics_NormalizeTargetDeltaX:                          ; CODE XREF: Physics_CalculateAngleToTarget+1E   j  ; was: loc_42808
                move.w  $14(a4),d1
                sub.w   $14(a5),d1
                beq.s   Physics_ReturnHorizontalAxisAngle
                bgt.s   Physics_OrderAngleRatioComponents
                neg.w   d1
                addq.l  #2,a0
Physics_OrderAngleRatioComponents:                      ; CODE XREF: Physics_CalculateAngleFromVelocity:Physics_NormalizeVelocityY   j  ; was: loc_42818
                                        ; Physics_CalculateAngleToTarget+2E   j
                cmp.w   d0,d1
                bcs.s   Physics_CalculateAngleRatio
                exg     d0,d1
                addq.l  #1,a0
Physics_CalculateAngleRatio:                            ; CODE XREF: Physics_CalculateAngleToTarget+36   j  ; was: loc_42820
                asl.l   #2,d0
                divu.w  d1,d0
                cmpi.w  #$23,d0                         ; '#'
                bcs.s   Physics_LookupArctangent
                moveq   #$23,d0                         ; '#'
Physics_LookupArctangent:                               ; CODE XREF: Physics_CalculateAngleToTarget+44   j  ; was: loc_4282C
                move.b  Physics_ApplyArctangentRatio(pc,d0.w),d0
                move.b  (a0),d1
                add.b   d1,d1
                bcc.s   Physics_ApplyArctangentRatio
                neg.b   d0
Physics_ApplyArctangentRatio:                           ; CODE XREF: Physics_CalculateAngleToTarget+50   j  ; was: loc_42838
                                        ; DATA XREF: Physics_CalculateAngleToTarget:Physics_LookupArctangent   r
                add.b   d1,d0
                rts
; End of function Physics_CalculateAngleToTarget
; ---------------------------------------------------------------------------
Physics_ArctangentRatioTableTail:
                binclude "data/other/arctangent_ratio_table_tail.bin"  ; was: unused_9
Physics_AngleOctantBaseTable:
                dc.b    0, $A0, $80, $60, $C0, $20, $40, $E0  ; was: byte_4285C
                                        ; DATA XREF: Physics_CalculateAngleFromVelocity+4   o
                                        ; Physics_CalculateAngleToTarget+C   o

; Adds 90 degrees offset to angle value
Physics_AddAngleOffset:                                 ; DATA XREF: Physics_CalculateAngleFromVelocity   o  ; was: sub_42864
                                        ; Physics_CalculateAngleToTarget   o
                addi.b  #$40,d0                         ; '@'
                rts
; End of function Physics_AddAngleOffset
; Selects an entry from a table of weight-and-value pairs
Math_SelectWeightedChoice:                              ; CODE XREF: Math_JumpToWeightedChoice   p  ; was: sub_4286A
                jsr     (RandomNumber).l
Math_SelectWeightedChoiceLoop:                          ; CODE XREF: Math_SelectWeightedChoice+C   j  ; was: loc_42870
                sub.w   (a0)+,d0
                bls.s   Math_SelectWeightedChoiceReturn
                addq.w  #2,a0
                bra.s   Math_SelectWeightedChoiceLoop
; ---------------------------------------------------------------------------
Math_SelectWeightedChoiceReturn:                        ; CODE XREF: Math_SelectWeightedChoice+8   j  ; was: loc_42878
                move.w  (a0),d0
                rts
; End of function Math_SelectWeightedChoice
; Selects and jumps to a weighted relative target
Math_JumpToWeightedChoice:                              ; CODE XREF: Boss_LovePenguinIdleState+40   j  ; was: sub_4287C
                                        ; Boss_LovePenguinCloseRangeAttack+4   j
                bsr.s   Math_SelectWeightedChoice
                adda.w  (a0),a0
                jmp     (a0)
; End of function Math_JumpToWeightedChoice

; Gets sine and cosine values
Math_GetSinCos:                                         ; CODE XREF: Math_GetScaledSinCos   p  ; was: sub_42882
                lsr.w   #1,d0
                andi.w  #$1FE,d0
                lea     (Math_QuarterSineTable).l,a0
                move.w  (a0,d0.w),d1
                addi.w  #$80,d0
                andi.w  #$1FE,d0
                move.w  (a0,d0.w),d0
                rts
; End of function Math_GetSinCos
; Gets scaled sine and cosine
Math_GetScaledSinCos:                                   ; CODE XREF: Boss_SunsetStingSegmentOrbitState:Boss_SunsetStingSegmentOrbitUpdatePosition   p  ; was: sub_428A0
                                        ; Boss_SunsetStingSegmentOrbitState+68   p
                bsr.s   Math_GetSinCos
                muls.w  d2,d0
                muls.w  d2,d1
                rts
; End of function Math_GetScaledSinCos
; Clears X and Y velocity values
Physics_ClearVelocity:                                  ; CODE XREF: Boss_SunsetStingBattleActive   p  ; was: sub_428A8
                                        ; sub_43048   p
                moveq   #0,d0
                move.l  d0,$18(a5)
                move.l  d0,$1C(a5)
                rts
; End of function Physics_ClearVelocity
