; Rising-shot wave controller shared by post-Destroyer Proto and Stage 24 sequences
Effect_RisingShotWaveControllerMain:                    ; was: sub_33664
                move.w  4(a5),d0
                lea     Effect_RisingShotWaveControllerStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Effect_RisingShotWaveControllerMain
; ---------------------------------------------------------------------------
Effect_RisingShotWaveControllerStates:  dc.w    Effect_RisingShotWaveInit-*  ; was: off_33670
                dc.w    Effect_RisingShotWaveWait-*
                dc.w    Effect_RisingShotWaveAllocateMembers-*
                dc.w    Effect_RisingShotWaveLaunchPattern-*
                dc.w    Effect_RisingShotWaveWaitForNextPattern-*

; Initializes the controller and its optional Stage 11 fish-wave companion
Effect_RisingShotWaveInit:                              ; was: sub_3367A
                clr.w   $4A(a5)
                cmpi.w  #$3E0,(Entity57Type).w
                beq.s   Effect_RisingShotWaveSkipFishController
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Effect_RisingShotWaveBeginDelay
                move.w  #$454,(a0)
                move.w  a0,$40(a5)
Effect_RisingShotWaveBeginDelay:                        ; was: loc_33696
                addq.w  #2,4(a5)
                move.w  #$200,$48(a5)
                rts
; ---------------------------------------------------------------------------
Effect_RisingShotWaveSkipFishController:                ; was: loc_336A2
                addq.w  #4,4(a5)
                rts
; End of function Effect_RisingShotWaveInit
; Waits before allocating the first rising-shot wave
Effect_RisingShotWaveWait:                              ; was: sub_336A8
                subq.w  #1,$48(a5)
                bne.s   Effect_RisingShotWaveWaitReturn
                addq.w  #2,4(a5)
Effect_RisingShotWaveWaitReturn:                        ; was: locret_336B2
                rts
; End of function Effect_RisingShotWaveWait
; Allocates ten object slots for the next rising-shot wave
Effect_RisingShotWaveAllocateMembers:                   ; was: sub_336B4
                moveq   #0,d0
                move.l  d0,$4C(a5)
                move.l  d0,$50(a5)
                move.l  d0,$54(a5)
                move.l  d0,$58(a5)
                move.l  d0,$5C(a5)
                move.w  #9,d7
                lea     $4C(a5),a1
Effect_RisingShotWaveAllocateNextMember:                ; was: loc_336D2
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Effect_RisingShotWaveFinishAllocation
                move.w  #$10,(a0)
                move.w  a0,(a1)+
                dbf     d7,Effect_RisingShotWaveAllocateNextMember
Effect_RisingShotWaveFinishAllocation:                  ; was: loc_336E4
                addq.w  #2,4(a5)
                rts
; End of function Effect_RisingShotWaveAllocateMembers
; Initializes one delayed rising shot at each scripted position
Effect_RisingShotWaveLaunchPattern:                     ; was: sub_336EA
                cmpi.w  #$3E0,(Entity57Type).w
                beq.s   Effect_RisingShotWaveSelectStage24Pattern
                lea     Effect_RisingShotWavePositionScript(pc),a1
                nop
                bra.s   Effect_RisingShotWavePositionMembers
; ---------------------------------------------------------------------------
Effect_RisingShotWaveSelectStage24Pattern:              ; was: loc_336FA
                lea     Effect_RisingShotWaveStage24PositionScript(pc),a1
                nop
Effect_RisingShotWavePositionMembers:                   ; was: loc_33700
                move.w  $4A(a5),d0
                lea     (a1,d0.w),a1
                lea     $4C(a5),a2
                lea     Effect_RisingShotWaveMemberDelays(pc),a3
                nop
                move.w  #9,d7
Effect_RisingShotWaveInitNextMember:                    ; was: loc_33716
                move.w  (a1)+,d4
                tst.w   (a2)
                beq.s   Effect_RisingShotWaveAdvanceMember
                movea.w (a2)+,a0
                move.w  (a3)+,d0
                move.w  #$180,d1
                move.l  #$FFFF0000,d2
                move.l  #$FFFFF000,d3
                bsr.w   Projectile_InitRisingShotWaveMember
Effect_RisingShotWaveAdvanceMember:                     ; was: loc_33734
                dbf     d7,Effect_RisingShotWaveInitNextMember
                move.w  (a1)+,$48(a5)
                tst.w   (a1)
                bmi.s   Effect_RisingShotWaveFinish
                addi.w  #$16,$4A(a5)
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Effect_RisingShotWaveFinish:                            ; was: loc_3374C
                move.w  #$1000,2(a5)
                cmpi.w  #$3E0,(Entity57Type).w
                beq.s   Effect_RisingShotWaveFinishReturn
                movea.w $40(a5),a0
                move.w  #$1000,2(a0)
Effect_RisingShotWaveFinishReturn:                      ; was: locret_33764
                rts
; End of function Effect_RisingShotWaveLaunchPattern
; ---------------------------------------------------------------------------
Effect_RisingShotWaveMemberDelays:      dc.w    $90, $B0, $D0, $F0, $110, $130, $150, $170, $190, $1B0  ; was: word_33766
Effect_RisingShotWavePositionScript:    dc.w    $200, $1C0, $130, $220, $90, 0, $110, $190  ; was: word_3377A
                dc.w    $A0, $30, $200, $1E0, $1B8, $128, $210, $78
                dc.w    0, $F0, $170, $A0, $40, $200, $FFFF
Effect_RisingShotWaveStage24PositionScript: dc.w    0, $10, $20, $30, $40, $80, $90, $A0  ; was: word_337A8
                dc.w    $B0, $C0, $100, $C0, $B0, $A0, $90, $80
                dc.w    $40, $30, $20, $10, 0, $100, $FFFF

; Waits before advancing to the next position pattern
Effect_RisingShotWaveWaitForNextPattern:                ; was: sub_337D6
                subq.w  #1,$48(a5)
                bne.s   Effect_RisingShotWavePatternWaitReturn
                move.w  #4,4(a5)
Effect_RisingShotWavePatternWaitReturn:                 ; was: locret_337E2
                rts
; End of function Effect_RisingShotWaveWaitForNextPattern
