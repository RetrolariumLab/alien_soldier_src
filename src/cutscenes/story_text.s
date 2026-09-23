; Dispatches story-screen text rendering states
StoryText_Dispatch:                                     ; CODE XREF: StoryScreen_MainLoop+3C   p  ; was: sub_588C
                cmpi.w  #$18,(GameSubstateIndex).w
                beq.w   Cutscene_Return
                move.w  (StoryTextState).l,d0
                lea     StoryText_States(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function StoryText_Dispatch
; ---------------------------------------------------------------------------
StoryText_States:   dc.w    StoryText_Initialize-*      ; DATA XREF: StoryText_Dispatch+10   o  ; was: off_58A4
                dc.w    StoryText_UpdateScroll-*

; Seeds the two 34-byte row streams, tilemap destination, and update cadence
StoryText_Initialize:                                   ; DATA XREF: ROM:StoryText_States   o  ; was: sub_58A8
                move.w  #$200,(PaletteActiveColor33).w
                move.w  #2,(PaletteActiveColor49).w
                move.w  #$EEE,(PaletteActiveColor34).w
                move.w  #$EE,(PaletteActiveColor50).w
                move.w  #$200,(PaletteShadowPair33).w
                move.w  #2,(PaletteShadowColor49).w
                move.w  #$EEE,(PaletteShadowPair33+2).w
                move.w  #$EE,(PaletteShadowColor50).w
                move.l  #StoryText_PrimaryRows,(SharedSequenceCursor).l
                move.l  #StoryText_AccentRows,(StoryTextAccentCursor).l
                move.w  #$4C88,(StoryTextVRAMAddress).l
                move.w  #1,(SharedSequenceTimer).l
                addq.w  #2,(StoryTextState).l
                rts
; End of function StoryText_Initialize
; Alternates the accent-layer palette words on successive frames
StoryText_AnimateAccentColors:                          ; CODE XREF: StoryText_UpdateScroll   p  ; was: sub_5904
                move.w  #$200,(PaletteActiveColor33).w
                move.w  #2,(PaletteActiveColor49).w
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #1,d0
                bne.s   StoryText_UseAlternateAccentColors
                move.w  #$EEE,(PaletteActiveColor34).w
                move.w  #$EE,(PaletteActiveColor50).w
                rts
; ---------------------------------------------------------------------------
StoryText_UseAlternateAccentColors:                     ; CODE XREF: StoryText_AnimateAccentColors+14   j  ; was: loc_5928
                move.w  #$EEA,(PaletteActiveColor34).w
                move.w  #$EA,(PaletteActiveColor50).w
                rts
; End of function StoryText_AnimateAccentColors
; Scrolls every fourth frame and streams a row pair every twenty-four ticks
StoryText_UpdateScroll:                                 ; DATA XREF: ROM:000058A6   o  ; was: sub_5936
                bsr.w   StoryText_AnimateAccentColors
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Cutscene_Return
                subq.w  #1,(PrimaryCameraYPosition).w
                subq.w  #1,(SharedSequenceTimer).l
                bne.w   Cutscene_Return
                move.w  #$18,(SharedSequenceTimer).l
                move.w  #$C300,d0
                move.w  (StoryTextVRAMAddress).l,d4
                movea.l (SharedSequenceCursor).l,a0
                cmpi.b  #$FE,(a0)
                bne.s   StoryText_RenderAccentRow
                movea.l #StoryText_BlankRow,a0
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                if      BuildProfileEU
                bra.w   StoryText_PrepareTrailingBlankRow
                else
                bra.s   StoryText_PrepareTrailingBlankRow
                endif
; ---------------------------------------------------------------------------
StoryText_RenderAccentRow:                              ; CODE XREF: StoryText_UpdateScroll+3A   j  ; was: loc_5980
                move.w  #$E300,d0
                move.w  (StoryTextVRAMAddress).l,d4
                movea.l (StoryTextAccentCursor).l,a0
                move.w  #$1F,d1
StoryText_SkipAccentLeadingBlanks:                      ; CODE XREF: StoryText_UpdateScroll+66   j  ; was: loc_5994
                tst.b   (a0)
                bne.s   StoryText_QueueAccentRow
                addq.w  #1,a0
                addq.w  #2,d4
                dbf     d1,StoryText_SkipAccentLeadingBlanks
                if      BuildProfileEU
                bra.s   StoryText_ScanSecondAccentRun
                else
                bra.s   StoryText_AdvanceRowPointers
                endif
; ---------------------------------------------------------------------------
StoryText_QueueAccentRow:                               ; CODE XREF: StoryText_UpdateScroll+60   j  ; was: loc_59A2
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                if      BuildProfileEU
StoryText_ScanSecondAccentRun:
                move.w  #$E300,d0
                move.w  (StoryTextVRAMAddress).l,d4
                movea.l (StoryTextAccentCursor).l,a0
                move.w  #$1F,d1
StoryText_SkipSecondAccentLeadingBlanks:
                tst.b   (a0)
                bne.s   StoryText_SkipFirstAccentRun
                addq.w  #1,a0
                addq.w  #2,d4
                dbf     d1,StoryText_SkipSecondAccentLeadingBlanks
                bra.s   StoryText_AdvanceRowPointers
StoryText_SkipFirstAccentRun:
                tst.b   (a0)
                beq.s   StoryText_SkipSecondAccentGap
                addq.w  #1,a0
                addq.w  #2,d4
                dbf     d1,StoryText_SkipFirstAccentRun
                bra.s   StoryText_AdvanceRowPointers
StoryText_SkipSecondAccentGap:
                tst.b   (a0)
                bne.s   StoryText_QueueSecondAccentRun
                addq.w  #1,a0
                addq.w  #2,d4
                dbf     d1,StoryText_SkipSecondAccentGap
                bra.s   StoryText_AdvanceRowPointers
StoryText_QueueSecondAccentRun:
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                endif
StoryText_AdvanceRowPointers:                           ; CODE XREF: StoryText_UpdateScroll+6A   j  ; was: loc_59A8
                addi.l  #$22,(StoryTextAccentCursor).l  ; '"'
                move.w  #$C300,d0
                move.w  (StoryTextVRAMAddress).l,d4
                movea.l (SharedSequenceCursor).l,a0
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                addi.l  #$22,(SharedSequenceCursor).l   ; '"'
StoryText_PrepareTrailingBlankRow:                      ; CODE XREF: StoryText_UpdateScroll+48   j  ; was: loc_59D2
                move.w  #$C300,d0
                move.w  (StoryTextVRAMAddress).l,d4
                addi.w  #$80,d4
                cmpi.w  #$5000,d4
                bcs.s   StoryText_QueueTrailingBlankRow
                subi.w  #$1000,d4
; Queues a blank row and advances the circular plane-A tilemap destination
StoryText_QueueTrailingBlankRow:                        ; CODE XREF: StoryText_UpdateScroll+AE   j  ; was: loc_59EA
                movea.l #StoryText_BlankRow,a0
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                addi.w  #$180,(StoryTextVRAMAddress).l
                cmpi.w  #$5000,(StoryTextVRAMAddress).l
                bcs.w   Cutscene_Return
                subi.w  #$1000,(StoryTextVRAMAddress).l
                rts
; End of function StoryText_UpdateScroll
; ---------------------------------------------------------------------------
StoryText_BlankRow: dc.w    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0  ; was: word_5A14
                                        ; DATA XREF: StoryText_UpdateScroll+3C   o
                                        ; sub_5936:loc_59EA   o
                dc.w    $FF
StoryText_PrimaryRows:
                if      BuildProfileEU
                binclude "data/profiles/eu/other/story_text_primary_rows.bin"
                else
                binclude "data/other/story_text_primary_rows.bin"  ; was: byte_5A36
                endif
StoryText_PrimaryRows_End:                              ; was: byte_5A36_End
StoryText_AccentRows:
                if      BuildProfileEU
                binclude "data/profiles/eu/other/story_text_accent_rows.bin"
                else
                binclude "data/other/story_text_accent_rows.bin"  ; was: byte_675D
                endif
StoryText_AccentRows_End:                               ; was: byte_675D_End

; Advances the Japanese-font scroll coordinate and dispatches its stream state
StoryFont_UpdateAndDispatch:                            ; CODE XREF: StoryScreen_MainLoop+40   p  ; was: sub_7484
                subq.w  #1,(StoryFontScrollY).l
                btst    #0,(FrameCounter+1).w
                bne.s   StoryFont_Dispatch
                subq.w  #1,(StoryFontScrollY).l
; Dispatches the current Japanese-font streaming state
StoryFont_Dispatch:                                     ; CODE XREF: StoryFont_UpdateAndDispatch+C   j  ; was: loc_7498
                move.w  (StoryFontState).l,d0
                lea     StoryFont_States(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function StoryFont_UpdateAndDispatch
; ---------------------------------------------------------------------------
StoryFont_States:   dc.w    StoryFont_Initialize-*      ; DATA XREF: StoryFont_UpdateAndDispatch+1A   o  ; was: off_74A6
                dc.w    StoryFont_StreamNextGlyph-*
                dc.w    StoryFont_SequenceComplete-*

; Queues the 64-entry font index rows and initializes the glyph stream
StoryFont_Initialize:                                   ; DATA XREF: ROM:StoryFont_States   o  ; was: sub_74AC
                move.w  #$C580,d0
                move.w  #$6C80,d4
                lea     StoryFont_IndexRowTiles(pc),a0
                nop
                jsr     StoryFont_QueueIndexRows(pc)    ; (pc)
                nop
                move.l  #JapaneseFontMappingData,(StoryFontGlyphCursor).l
                move.w  #$7C00,(StoryFontVRAMAddress).l
                clr.w   (StoryFontScrollY).l
                clr.w   (StoryFontNextGlyphY).l
                addq.w  #2,(StoryFontState).l
                rts
; End of function StoryFont_Initialize
; Queues the next 128-byte Japanese glyph when its scroll threshold is reached
StoryFont_StreamNextGlyph:                              ; DATA XREF: ROM:000074A8   o  ; was: sub_74E6
                move.w  (StoryFontNextGlyphY).l,d0
                sub.w   (StoryFontScrollY).l,d0
                cmpi.w  #$10,d0
                bcs.w   Cutscene_Return
                subi.w  #$10,(StoryFontNextGlyphY).l
                movea.l (StoryFontGlyphCursor).l,a0
                move.w  (a0),d0
                subi.w  #$20,d0                         ; ' '
                ext.l   d0
                lsl.l   #7,d0
                addi.l  #JapaneseFontTileArt,d0
                move.w  (StoryFontVRAMAddress).l,d4
                jsr     StoryFont_QueueGlyphDMA(pc)     ; (pc)
                nop
                move.w  (StoryFontVRAMAddress).l,d0
                addi.w  #$80,d0
                cmpi.w  #$8000,d0
                bne.s   StoryFont_StoreNextVRAMAddress
                move.w  #$7000,d0
; Stores the next circular glyph destination and advances the source cursor
StoryFont_StoreNextVRAMAddress:                         ; CODE XREF: StoryFont_StreamNextGlyph+4C   j  ; was: loc_7538
                move.w  d0,(StoryFontVRAMAddress).l
                addq.l  #2,(StoryFontGlyphCursor).l
                movea.l (StoryFontGlyphCursor).l,a0
                tst.w   (a0)
                bpl.w   Cutscene_Return
                addq.w  #2,(StoryFontState).l
                rts
; End of function StoryFont_StreamNextGlyph
StoryFont_SequenceComplete:                             ; DATA XREF: ROM:000074AA   o  ; was: nullsub_18
                rts
; End of function StoryFont_SequenceComplete

; Prepends one 64-word ROM-to-VRAM DMA record for a Japanese glyph
StoryFont_QueueGlyphDMA:                                ; CODE XREF: StoryFont_StreamNextGlyph+38   p  ; was: sub_755A
                                        ; DATA XREF: StoryFont_StreamNextGlyph+38   o
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$82,-(a1)
                move.w  d4,-(a1)
                lsr.l   #1,d0
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                lsr.l   #8,d0
                move.b  d0,-(a1)
                move.b  #$96,-(a1)
                lsr.l   #8,d0
                move.b  d0,-(a1)
                move.b  #$97,-(a1)
                move.w  #$8F02,-(a1)
                move.l  #$94009340,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function StoryFont_QueueGlyphDMA
; Stages the top tile-index row and a bottom row whose indices are one greater
StoryFont_QueueIndexRows:                               ; CODE XREF: StoryFont_Initialize+E   p  ; was: sub_758C
                                        ; DATA XREF: StoryFont_Initialize+E   o
                movea.w (VDPStagingDataCursor).w,a1
                moveq   #0,d7
StoryFont_WriteNextTopTile:                             ; CODE XREF: StoryFont_QueueIndexRows+18   j  ; was: loc_7592
                moveq   #0,d2
                move.b  (a0)+,d2
                cmpi.b  #$FF,d2
                beq.s   StoryFont_PrepareBottomRow
                asl.w   #1,d2
                add.w   d0,d2
                move.w  d2,(a1)+
                addq.w  #1,d7
                bra.s   StoryFont_WriteNextTopTile
; ---------------------------------------------------------------------------
StoryFont_PrepareBottomRow:                             ; CODE XREF: StoryFont_QueueIndexRows+E   j  ; was: loc_75A6
                move.w  d7,d3
                subq.w  #1,d3
                movea.w (VDPStagingDataCursor).w,a0
StoryFont_WriteNextBottomTile:                          ; CODE XREF: StoryFont_QueueIndexRows+28   j  ; was: loc_75AE
                move.w  (a0)+,d0
                addq.w  #1,d0
                move.w  d0,(a1)+
                dbf     d3,StoryFont_WriteNextBottomTile
                move.w  d7,d3
                bsr.w   StoryFont_QueueStagedRowDMA
                addi.w  #$80,d4
                move.w  d7,d3
; End of function StoryFont_QueueIndexRows
; Prepends one staged tile-row DMA record and advances the staging cursor
StoryFont_QueueStagedRowDMA:                            ; CODE XREF: StoryFont_QueueIndexRows+2E   p  ; was: sub_75C4
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$82,-(a1)
                move.w  d4,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009300,-(a1)
                move.b  d3,3(a1)
                move.w  a1,(VDPCommandQueueHead).w
                asl.w   #1,d3
                add.w   d3,(VDPStagingDataCursor).w
                rts
; End of function StoryFont_QueueStagedRowDMA
; ---------------------------------------------------------------------------
StoryFont_IndexRowTiles:    dc.b    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $A, $B, $C, $D, $E, $F  ; was: byte_7602
                                        ; DATA XREF: StoryFont_Initialize+8   o
                dc.b    $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
                dc.b    $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F
                dc.b    $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F
                dc.b    $FF, $FF
