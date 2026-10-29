; Packed-BCD score accumulation and the shared pseudo-random number generator

; Adds the packed-BCD value in d0 to the eight-digit score and saturates at 99999999
Score_AddPackedBCD:                                     ; was: sub_3954
                                        ; Collision_CheckWeaponProjectilesAgainstEnemies+E2   p
                tst.w   (StageTimeRemaining).w
                beq.s   Score_AddPackedBCD_Return
                lea     (ScoreValueBCD+4).w,a0
                clr.b   (ScoreAddendPrefixByte).w
                move.l  d0,(ScoreAddendBCD).w
                lea     (ScoreAddendBCD+4).w,a1
                sub.w   d0,d0
                abcd    -(a1),-(a0)
                abcd    -(a1),-(a0)
                abcd    -(a1),-(a0)
                abcd    -(a1),-(a0)
                bcc.s   Score_AddPackedBCD_Return
                move.l  #$99999999,(a0)
Score_AddPackedBCD_Return:                              ; was: locret_397C
                                        ; Score_AddPackedBCD+20   j
                rts
; End of function Score_AddPackedBCD
; Unreferenced one-instruction entry retained between the two numeric routines
Numeric_NoOp:                                           ; was: nullsub_14
                rts
; End of function Numeric_NoOp

; Advances the shared pseudo-random state and returns a mixed result in d0
RandomNumber:
                                        ; EndingStarfield_Initialize:EndingStarfield_InitializeNextParticle   p
                move.l  d1,-(sp)
                move.l  (RandomNumberState).w,d1
                bne.s   RandomNumber_AdvanceState
                move.l  #'*m6Z',d1
RandomNumber_AdvanceState:                              ; was: loc_398E
                move.l  d1,d0
                asl.l   #2,d1
                add.l   d0,d1
                asl.l   #3,d1
                add.l   d0,d1
                move.w  d1,d0
                swap    d1
                add.w   d1,d0
                move.w  d0,d1
                swap    d1
                move.l  d1,(RandomNumberState).w
                move.l  (sp)+,d1
                rts
; End of function RandomNumber
