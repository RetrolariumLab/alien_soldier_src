; Update the four paired rows of the Snake-stage background
Scroll_UpdateSnakeBackground:                           ; was: sub_E34E
                                        ; Stage13_UpdateSnakeEncounterTransition   p
                movea.w #(SnakeScrollAccumulators-M68K_RAM),a0
                lea     SnakeBackgroundScrollVelocityDeltas(pc),a1
                nop
                lea     SnakeBackgroundTileIndexNibbles(pc),a2
                nop
                movea.w (VDPStagingDataCursor).w,a4
                moveq   #3,d7
Scroll_UpdateSnakeBackground_RowPairLoop:               ; was: loc_E364
                bsr.w   Scroll_AccumulateSnakeBackgroundOffset
Scroll_UpdateSnakeBackground_WriteHighNibbles:          ; was: loc_E368
                andi.w  #7,d0
                move.b  (a2,d0.w),(a4)
                addq.w  #1,d0
                addq.w  #4,a4
                dbf     d6,Scroll_UpdateSnakeBackground_WriteHighNibbles
                adda.l  #8,a2
                suba.w  #$20,a4                         ; ' '
                bsr.w   Scroll_AccumulateSnakeBackgroundOffset
Scroll_UpdateSnakeBackground_MergeLowNibbles:           ; was: loc_E386
                andi.w  #7,d0
                move.b  (a4),d1
                or.b    (a2,d0.w),d1
                move.b  d1,(a4)
                addq.w  #1,d0
                addq.w  #4,a4
                dbf     d6,Scroll_UpdateSnakeBackground_MergeLowNibbles
                adda.l  #8,a2
                suba.w  #$1F,a4
                dbf     d7,Scroll_UpdateSnakeBackground_RowPairLoop
                move.w  #$1BC0,d0
                move.l  #$94009310,d4
                jsr     (VDP_QueueCommand).l
                addi.w  #$20,(VDPStagingDataCursor).w   ; ' '
                rts
; End of function Scroll_UpdateSnakeBackground

; Accumulate one Snake-background offset and return its integer index
Scroll_AccumulateSnakeBackgroundOffset:                 ; was: sub_E3C0
                                        ; Scroll_UpdateSnakeBackground+34   p
                move.l  (a0),d0
                add.l   (a1)+,d0
                move.l  d0,(a0)+
                swap    d0
                moveq   #7,d6
                rts
; End of function Scroll_AccumulateSnakeBackgroundOffset
; ---------------------------------------------------------------------------
SnakeBackgroundScrollVelocityDeltas:    dc.l    $FFFF8000  ; was: dword_E3CC
                dc.l    $FFFF4000
                dc.l    $FFFF0000
                dc.l    $FFFF6000
                dc.l    $FFFEE000
                dc.l    $FFFFA000
                dc.l    $FFFF0000
                dc.l    $FFFFC000
SnakeBackgroundTileIndexNibbles:    dc.w    $C0D0, $D0D0, $E0E0, $E0E0, $C0D, $E0E, $D0D, $E0E  ; was: word_E3EC
                dc.w    $C0D0, $D0E0, $C0E0, $E0E0, $C0D, $E0E, $E0E, $E0E
                dc.w    $D0E0, $E0D0, $D0E0, $E0E0, $E0E, $C0D, $D0E, $C0E
                dc.w    $E0E0, $E0E0, $E0E0, $E0E0, $D0D, $D0D, $C0E, $E0E
