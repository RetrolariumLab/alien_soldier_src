; Reorders and horizontally resamples Stage 3 phase-2 packed-nibble tile data
Gfx_ResampleStage21And22Tiles:                          ; CODE XREF: Gfx_PrepareStage21And22ResampledTiles+40   p  ; was: sub_12648
                movea.l (Stage3ScaleTablePtr).w,a4
                movea.l (Stage3PackedTilePtr).w,a0
                movea.l #Stage3ResampleBuffer,a2
                moveq   #0,d6
                move.w  (Stage3ResampleGroupsM1).w,d7
Gfx_Stage3ResampleNextSourceGroup:                      ; CODE XREF: Gfx_ResampleStage21And22Tiles+5E   j  ; was: loc_1265C
                move.w  (Stage3ResamplePassesM1).w,d5
                move.w  d5,d4
                addq.w  #1,d4
                asl.w   #5,d4
Gfx_Stage3GatherSourceColumns:                          ; CODE XREF: Gfx_ResampleStage21And22Tiles+26   j  ; was: loc_12666
                move.l  (a0,d6.w),(a2)+
                addi.w  #$20,d6                         ; ' '
                dbf     d5,Gfx_Stage3GatherSourceColumns
                movea.l a2,a3
                move.w  (Stage3ResamplePassesM1).w,d5
                addq.w  #1,d5
                asl.w   #2,d5
                subq.w  #1,d5
Gfx_Stage3ReversePackedNibbles:                         ; CODE XREF: Gfx_ResampleStage21And22Tiles+44   j  ; was: loc_1267E
                moveq   #0,d0
                move.b  -(a3),d0
                move.b  d0,d1
                asr.w   #4,d0
                asl.w   #4,d1
                add.b   d1,d0
                move.b  d0,(a2)+
                dbf     d5,Gfx_Stage3ReversePackedNibbles
                sub.w   d4,d6
                addq.w  #4,d6
                move.w  d6,d0
                andi.w  #$1C,d0
                bne.s   Gfx_Stage3AdvanceSourceGroup
                add.w   d4,d6
                subi.w  #$20,d6                         ; ' '
Gfx_Stage3AdvanceSourceGroup:                           ; CODE XREF: Gfx_ResampleStage21And22Tiles+52   j  ; was: loc_126A2
                move.w  (Stage3ResamplePassesM1).w,d5
                dbf     d7,Gfx_Stage3ResampleNextSourceGroup
                movea.l #Stage3ResampleBuffer,a2
                movea.l #M68K_RAM,a0
                move.w  (Stage3ResampleGroupsM1).w,d7
                asr.w   #3,d7
                moveq   #0,d5
                move.w  (Stage3ResamplePassesM1).w,d5
                addq.w  #1,d5
                asl.w   #3,d5
                swap    d5
Gfx_Stage3ResampleNextOutputBlock:                      ; CODE XREF: Gfx_ResampleStage21And22Tiles+E6   j  ; was: loc_126C8
                moveq   #7,d1
Gfx_Stage3ResampleNextOutputSlice:                      ; CODE XREF: Gfx_ResampleStage21And22Tiles+DE   j  ; was: loc_126CA
                move.l  (a4)+,d3
                move.w  #$17,d2
                moveq   #0,d4
Gfx_Stage3ResampleNextOutputRow:                        ; CODE XREF: Gfx_ResampleStage21And22Tiles+D0   j  ; was: loc_126D2
                moveq   #3,d6
Gfx_Stage3ResampleNextOutputByte:                       ; CODE XREF: Gfx_ResampleStage21And22Tiles+C8   j  ; was: loc_126D4
                move.b  (a2,d4.w),d0
                btst    #$1F,d4
                beq.s   Gfx_Stage3NormalizeHighNibble
                asl.b   #4,d0
Gfx_Stage3NormalizeHighNibble:                          ; CODE XREF: Gfx_ResampleStage21And22Tiles+94   j  ; was: loc_126E0
                andi.b  #$F0,d0
                swap    d4
                add.l   d3,d4
                cmp.l   d5,d4
                bmi.s   Gfx_Stage3WriteHighNibble
                sub.l   d5,d4
Gfx_Stage3WriteHighNibble:                              ; CODE XREF: Gfx_ResampleStage21And22Tiles+A2   j  ; was: loc_126EE
                move.b  d0,(a0)
                swap    d4
                move.b  (a2,d4.w),d0
                btst    #$1F,d4
                bne.s   Gfx_Stage3NormalizeLowNibble
                asr.b   #4,d0
Gfx_Stage3NormalizeLowNibble:                           ; CODE XREF: Gfx_ResampleStage21And22Tiles+B2   j  ; was: loc_126FE
                andi.b  #$F,d0
                swap    d4
                add.l   d3,d4
                cmp.l   d5,d4
                bmi.s   Gfx_Stage3WriteLowNibble
                sub.l   d5,d4
Gfx_Stage3WriteLowNibble:                               ; CODE XREF: Gfx_ResampleStage21And22Tiles+C0   j  ; was: loc_1270C
                or.b    d0,(a0)+
                swap    d4
                dbf     d6,Gfx_Stage3ResampleNextOutputByte
                adda.w  #$1C,a0
                dbf     d2,Gfx_Stage3ResampleNextOutputRow
                adda.w  #$FD04,a0
                swap    d5
                adda.w  d5,a2
                swap    d5
                dbf     d1,Gfx_Stage3ResampleNextOutputSlice
                adda.w  #$2E0,a0
                dbf     d7,Gfx_Stage3ResampleNextOutputBlock
                rts
; End of function Gfx_ResampleStage21And22Tiles
