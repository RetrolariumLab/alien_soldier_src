; Spawns one ship piece when the timeline reaches its next script record
ShipSequence_SpawnScheduledPiece:                       ; was: sub_8F90
                movea.l (ShipPieceScriptCursor).l,a0
                move.w  (ShipSequenceFrame).l,d0
                cmp.w   (a0)+,d0
                bne.w   Cutscene_Return
                movea.l #Entity_ObjectPool,a4
                adda.w  (a0)+,a4
                move.w  #$CC00,2(a4)
                move.w  #$30C,(a4)
                move.w  #$4300,$E(a4)
                move.b  #$78,$20(a4)                    ; 'x'
                clr.l   $18(a4)
                move.w  (a0)+,d0
                move.l  ShipPiece_SpriteFrameTable(pc,d0.w),8(a4)
                move.l  ShipPiece_InitialYVelocities(pc,d0.w),$1C(a4)
                move.w  (a0)+,$10(a4)
                move.w  (a0)+,$14(a4)
                move.w  (a0)+,$40(a4)
                move.w  (a0)+,d0
                ext.l   d0
                move.l  d0,$18(a4)
                move.l  a0,(ShipPieceScriptCursor).l
                rts
; End of function ShipSequence_SpawnScheduledPiece
; ---------------------------------------------------------------------------
ShipPiece_SpriteFrameTable: dc.l    ShipPiece_SpriteFrame0  ; was: off_8FEE
                dc.l    ShipPiece_SpriteFrame1
                dc.l    ShipPiece_SpriteFrame2
                dc.l    ShipPiece_SpriteFrame3
ShipPiece_InitialYVelocities:   dc.w    $FFFF, $E800, $FFFF, $E000, $FFFF, $D000, $FFFF, $D800  ; was: word_8FFE
ShipPiece_SpawnScript:          dc.w    1, $11A0, 0, $100, $148, $490, 0, $28  ; was: word_900E
                dc.w    $1140, 0, $F8, $148, $490, $FE00, $29, $10E0
                dc.w    0, $108, $148, $4D0, $200, $68, $1080, 0
                dc.w    $F0, $148, $490, $FC80, $B0, $1020, 0, $E8
                dc.w    $148, $410, $FB80, $140, $BA0, 4, $148, $150
                dc.w    $3A0, $FE00, $158, $B40, 4, $150, $150, $3B0
                dc.w    0, $170, $AE0, 4, $158, $150, $380, $200
                dc.w    $190, $A80, 4, $160, $150, $350, $400, $1A0
                dc.w    $5A0, 8, $100, $158, $378, 0, $1B0, $540
                dc.w    $C, $160, $158, $378, 0, 0

; Spawns one debris object when the timeline reaches its next script record
ShipSequence_SpawnScheduledDebris:                      ; was: sub_90AA
                movea.l (ShipDebrisCursor).l,a0
                move.w  (ShipSequenceFrame).l,d0
                cmp.w   (a0)+,d0
                bne.w   Cutscene_Return
                movea.l #Entity_ObjectPool,a4
                adda.w  (a0)+,a4
                move.w  #$CC00,2(a4)
                clr.w   4(a4)
                move.w  #$310,(a4)
                move.w  #$4300,$E(a4)
                move.b  #$70,$20(a4)                    ; 'p'
                move.w  #$50,$14(a4)                    ; 'P'
                move.w  (a0)+,d0
                move.l  ShipDebris_SpriteFrameTable(pc,d0.w),8(a4)
                move.l  ShipDebris_InitialXVelocities(pc,d0.w),$18(a4)
                move.l  ShipDebris_InitialYVelocities(pc,d0.w),$1C(a4)
                move.w  (a0)+,$10(a4)
                tst.l   $18(a4)
                bpl.s   ShipDebris_StoreScriptCursor
                ori.w   #$800,$E(a4)
ShipDebris_StoreScriptCursor:                           ; was: loc_9108
                move.l  a0,(ShipDebrisCursor).l
                move.b  #$59,d0                         ; 'Y'
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function ShipSequence_SpawnScheduledDebris
; ---------------------------------------------------------------------------
ShipDebris_SpriteFrameTable:    dc.l    ShipDebris_SpriteFrame0  ; was: off_911A
                dc.l    ShipDebris_SpriteFrame1
                dc.l    ShipDebris_SpriteFrame1
                dc.l    ShipDebris_SpriteFrame2
                dc.l    ShipDebris_SpriteFrame3
                dc.l    ShipDebris_SpriteFrame3
                dc.l    ShipDebris_SpriteFrame4
                dc.l    ShipDebris_SpriteFrame5
ShipDebris_InitialXVelocities:  dc.l    0, $FFFF8000, $8000  ; was: dword_913A
                dc.l    0, $FFFE0000, $20000
                dc.l    0, 0
ShipDebris_InitialYVelocities:  dc.w    4, 0, 4, 0, 4, 0, $10, 0  ; was: word_915A
                dc.w    $10, 0, $10, 0, $20, 0, $20, 0
ShipDebris_SpawnScript: dc.w    $480, $FC0, 0, $120, $488, $F60, 4, $110  ; was: word_917A
                dc.w    $490, $F00, 8, $D0, $498, $EA0, 0, $F0
                dc.w    $4A0, $E40, 8, $150, $4A8, $DE0, 4, $E0
                dc.w    $4B0, $D80, 0, $170, $4B8, $D20, 8, $130
                dc.w    $4C0, $CC0, 0, $160, $4C8, $C60, 4, $100
                dc.w    $4D0, $C00, 8, $140, $4D8, $A20, $14, $130
                dc.w    $4DE, $9C0, $10, $170, $4E4, $960, $14, $150
                dc.w    $4EA, $900, $C, $100, $4F0, $8A0, $10, $F0
                dc.w    $4F6, $840, $10, $140, $4FC, $7E0, $C, $110
                dc.w    $502, $780, $14, $D0, $508, $720, $C, $160
                dc.w    $50E, $6C0, $14, $100, $514, $660, $10, $E0
                dc.w    $51A, $600, $14, $120, $520, $360, $18, $100
                dc.w    $528, $300, $18, $160, $530, $2A0, $18, $D0
                dc.w    $538, $240, $18, $178, $53C, $1E0, $18, $110
                dc.w    $540, $180, $18, $148, $544, $120, $18, $F0
                dc.w    $548, $C0, $1C, $128, 0

; Counts down a ship piece, removing it above Y `$60` or converting it to an explosion
ShipPiece_UpdateCountdown:                              ; was: sub_9274
                subq.w  #1,$40(a5)
                beq.s   ShipPiece_ConvertToExplosion
                cmpi.w  #$60,$14(a5)                    ; '`'
                bcc.w   Cutscene_Return
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
ShipPiece_ConvertToExplosion:                           ; was: loc_928C
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #Effect_SpriteAnimation00,8(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function ShipPiece_UpdateCountdown
; Dispatches the four-state falling-debris lifecycle
ShipDebris_Dispatch:                                    ; was: sub_92AE
                move.w  4(a5),d0
                lea     ShipDebris_States(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function ShipDebris_Dispatch
; ---------------------------------------------------------------------------
ShipDebris_States:  dc.w    ShipDebris_PauseAtLowerBoundary-*  ; was: off_92BA
                dc.w    ShipDebris_ResumeAfterDelay-*
                dc.w    ShipDebris_RemoveBelowScreen-*
                dc.w    ShipDebris_Complete-*

; Saves velocity and pauses debris for `$60` frames at Y `$F0`
ShipDebris_PauseAtLowerBoundary:                        ; was: sub_92C2
                cmpi.w  #$F0,$14(a5)
                bcs.w   Cutscene_Return
                move.w  #$60,$48(a5)                    ; '`'
                move.l  $1C(a5),$40(a5)
                move.l  $18(a5),$44(a5)
                clr.l   $1C(a5)
                clr.l   $18(a5)
                addq.w  #2,4(a5)
                cmpa.w  #$C6E0,a5
                bne.w   Cutscene_Return
                addq.w  #4,4(a5)
                rts
; End of function ShipDebris_PauseAtLowerBoundary
; Restores the saved X/Y velocities after the `$60`-frame pause
ShipDebris_ResumeAfterDelay:                            ; was: sub_92F8
                subq.w  #1,$48(a5)
                bne.w   Cutscene_Return
                move.l  $40(a5),$1C(a5)
                move.l  $44(a5),$18(a5)
                rts
; End of function ShipDebris_ResumeAfterDelay
; Removes debris after it falls below Y `$190`
ShipDebris_RemoveBelowScreen:                           ; was: sub_930E
                cmpi.w  #$190,$14(a5)
                bcs.w   Cutscene_Return
                move.w  #$1000,2(a5)
                rts
; End of function ShipDebris_RemoveBelowScreen
ShipDebris_Complete:                                    ; was: nullsub_21
                rts
; End of function ShipDebris_Complete
