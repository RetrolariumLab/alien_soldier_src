; Applies a 64-color fade between the active and shadow palettes
; PaletteFillColor selects the black or white endpoint; the sign of
; PaletteFadeStep selects whether PaletteFadeProgress advances or retreats
; The high byte of PaletteFadeProgress supplies the per-channel delta
Palette_UpdateFullScreenFade:                           ; was: sub_EF4
                tst.b   (GameplayControlFlags).w
                bpl.w   Palette_UpdateFullScreenFade_SelectTarget
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_SelectTarget:              ; was: loc_EFE
                tst.w   (PaletteFillColor).w
                bne.w   Palette_UpdateFullScreenFade_SelectWhiteDirection
                move.w  (PaletteFadeStep).w,d0
                bmi.w   Palette_UpdateFullScreenFade_StepFromBlack
                bne.w   Palette_UpdateFullScreenFade_BeginToBlack
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_StepFromBlack:             ; was: loc_F14
                add.w   d0,(PaletteFadeProgress).w
                bpl.w   Palette_UpdateFullScreenFade_RenderFromBlack
                clr.w   (PaletteFadeProgress).w
Palette_UpdateFullScreenFade_RenderFromBlack:           ; was: loc_F20
                lea     (PaletteActiveBuffer).w,a0
                lea     (PaletteShadowBuffer).w,a1
                move.b  (PaletteFadeProgress).w,d5
                andi.w  #$FF,d5
                move.w  d5,d6
                lsl.w   #4,d6
                move.w  d6,d7
                lsl.w   #4,d7
                move.w  #$3F,d1                         ; '?'
Palette_UpdateFullScreenFade_FromBlackLoop:             ; was: loc_F3C
                move.w  (a1)+,d2
                move.w  d2,d3
                move.w  d2,d4
                andi.w  #$F,d2
                beq.w   Palette_UpdateFullScreenFade_FromBlackClampRed
                sub.w   d5,d2
                bpl.w   Palette_UpdateFullScreenFade_FromBlackClampRed
                clr.w   d2
Palette_UpdateFullScreenFade_FromBlackClampRed:         ; was: loc_F52
                                        ; Palette_UpdateFullScreenFade+58   j
                andi.w  #$F0,d3
                beq.w   Palette_UpdateFullScreenFade_FromBlackClampGreen
                sub.w   d6,d3
                bpl.w   Palette_UpdateFullScreenFade_FromBlackClampGreen
                clr.w   d3
Palette_UpdateFullScreenFade_FromBlackClampGreen:       ; was: loc_F62
                                        ; Palette_UpdateFullScreenFade+68   j
                andi.w  #$F00,d4
                beq.w   Palette_UpdateFullScreenFade_FromBlackStoreColor
                sub.w   d7,d4
                bpl.w   Palette_UpdateFullScreenFade_FromBlackStoreColor
                clr.w   d4
Palette_UpdateFullScreenFade_FromBlackStoreColor:       ; was: loc_F72
                                        ; Palette_UpdateFullScreenFade+78   j
                or.w    d3,d2
                or.w    d4,d2
                move.w  d2,(a0)+
                dbf     d1,Palette_UpdateFullScreenFade_FromBlackLoop
                tst.w   (PaletteFadeProgress).w
                bne.w   Palette_UpdateFullScreenFade_FromBlackReturn
                clr.w   (PaletteFadeStep).w
Palette_UpdateFullScreenFade_FromBlackReturn:           ; was: locret_F88
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_BeginToBlack:              ; was: loc_F8A
                tst.w   (PaletteFadeProgress).w
                bne.w   Palette_UpdateFullScreenFade_ContinueToBlack
                add.w   d0,(PaletteFadeProgress).w
                lea     (PaletteActiveBuffer).w,a0
                lea     (PaletteShadowBuffer).w,a1
                move.b  (PaletteFadeProgress).w,d5
                andi.w  #$FF,d5
                move.w  d5,d6
                lsl.w   #4,d6
                move.w  d6,d7
                lsl.w   #4,d7
                move.w  #$3F,d1                         ; '?'
Palette_UpdateFullScreenFade_BeginToBlackLoop:          ; was: loc_FB2
                move.w  (a0),d2
                move.w  d2,d3
                move.w  d2,d4
                andi.w  #$F,d2
                beq.w   Palette_UpdateFullScreenFade_BeginToBlackClampRed
                sub.w   d5,d2
                bpl.w   Palette_UpdateFullScreenFade_BeginToBlackClampRed
                clr.w   d2
Palette_UpdateFullScreenFade_BeginToBlackClampRed:      ; was: loc_FC8
                                        ; Palette_UpdateFullScreenFade+CE   j
                andi.w  #$F0,d3
                beq.w   Palette_UpdateFullScreenFade_BeginToBlackClampGreen
                sub.w   d6,d3
                bpl.w   Palette_UpdateFullScreenFade_BeginToBlackClampGreen
                clr.w   d3
Palette_UpdateFullScreenFade_BeginToBlackClampGreen:    ; was: loc_FD8
                                        ; Palette_UpdateFullScreenFade+DE   j
                andi.w  #$F00,d4
                beq.w   Palette_UpdateFullScreenFade_BeginToBlackStoreColor
                sub.w   d7,d4
                bpl.w   Palette_UpdateFullScreenFade_BeginToBlackStoreColor
                clr.w   d4
Palette_UpdateFullScreenFade_BeginToBlackStoreColor:    ; was: loc_FE8
                                        ; Palette_UpdateFullScreenFade+EE   j
                or.w    d3,d2
                or.w    d4,d2
                move.w  d2,(a0)+
                move.w  d2,(a1)+
                dbf     d1,Palette_UpdateFullScreenFade_BeginToBlackLoop
                cmpi.w  #$1000,(PaletteFadeProgress).w
                blt.w   Palette_UpdateFullScreenFade_BeginToBlackReturn
                move.w  #$1000,(PaletteFadeProgress).w
                clr.w   (PaletteFadeStep).w
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
Palette_UpdateFullScreenFade_BeginToBlackReturn:        ; was: locret_1012
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_ContinueToBlack:           ; was: loc_1014
                add.w   d0,(PaletteFadeProgress).w
                lea     (PaletteActiveBuffer).w,a0
                lea     (PaletteShadowBuffer).w,a1
                move.b  (PaletteFadeProgress).w,d5
                andi.w  #$FF,d5
                move.w  d5,d6
                lsl.w   #4,d6
                move.w  d6,d7
                lsl.w   #4,d7
                move.w  #$3F,d1                         ; '?'
Palette_UpdateFullScreenFade_ToBlackLoop:               ; was: loc_1034
                move.w  (a1)+,d2
                move.w  d2,d3
                move.w  d2,d4
                andi.w  #$F,d2
                beq.w   Palette_UpdateFullScreenFade_ToBlackClampRed
                sub.w   d5,d2
                bpl.w   Palette_UpdateFullScreenFade_ToBlackClampRed
                clr.w   d2
Palette_UpdateFullScreenFade_ToBlackClampRed:           ; was: loc_104A
                                        ; Palette_UpdateFullScreenFade+150   j
                andi.w  #$F0,d3
                beq.w   Palette_UpdateFullScreenFade_ToBlackClampGreen
                sub.w   d6,d3
                bpl.w   Palette_UpdateFullScreenFade_ToBlackClampGreen
                clr.w   d3
Palette_UpdateFullScreenFade_ToBlackClampGreen:         ; was: loc_105A
                                        ; Palette_UpdateFullScreenFade+160   j
                andi.w  #$F00,d4
                beq.w   Palette_UpdateFullScreenFade_ToBlackStoreColor
                sub.w   d7,d4
                bpl.w   Palette_UpdateFullScreenFade_ToBlackStoreColor
                clr.w   d4
Palette_UpdateFullScreenFade_ToBlackStoreColor:         ; was: loc_106A
                                        ; Palette_UpdateFullScreenFade+170   j
                or.w    d3,d2
                or.w    d4,d2
                move.w  d2,(a0)+
                dbf     d1,Palette_UpdateFullScreenFade_ToBlackLoop
                cmpi.w  #$1000,(PaletteFadeProgress).w
                blt.w   Palette_UpdateFullScreenFade_ToBlackReturn
                move.w  #$1000,(PaletteFadeProgress).w
                clr.w   (PaletteFadeStep).w
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
Palette_UpdateFullScreenFade_ToBlackReturn:             ; was: locret_1092
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_SelectWhiteDirection:      ; was: loc_1094
                move.w  (PaletteFadeStep).w,d0
                bmi.w   Palette_UpdateFullScreenFade_StepFromWhite
                bne.w   Palette_UpdateFullScreenFade_BeginToWhite
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_StepFromWhite:             ; was: loc_10A2
                add.w   d0,(PaletteFadeProgress).w
                bpl.w   Palette_UpdateFullScreenFade_RenderFromWhite
                clr.w   (PaletteFadeProgress).w
Palette_UpdateFullScreenFade_RenderFromWhite:           ; was: loc_10AE
                lea     (PaletteActiveBuffer).w,a0
                lea     (PaletteShadowBuffer).w,a1
                move.b  (PaletteFadeProgress).w,d5
                andi.w  #$FF,d5
                move.w  d5,d6
                lsl.w   #4,d6
                move.w  d6,d7
                lsl.w   #4,d7
                move.w  #$3F,d1                         ; '?'
Palette_UpdateFullScreenFade_FromWhiteLoop:             ; was: loc_10CA
                move.w  (a1)+,d2
                move.w  d2,d3
                move.w  d2,d4
                andi.w  #$F,d2
                andi.w  #$F0,d3
                andi.w  #$F00,d4
                add.w   d5,d2
                cmpi.w  #$F,d2
                bls.w   Palette_UpdateFullScreenFade_FromWhiteClampRed
                move.w  #$F,d2
Palette_UpdateFullScreenFade_FromWhiteClampRed:         ; was: loc_10EA
                add.w   d6,d3
                cmpi.w  #$F0,d3
                bls.w   Palette_UpdateFullScreenFade_FromWhiteClampGreen
                move.w  #$F0,d3
Palette_UpdateFullScreenFade_FromWhiteClampGreen:       ; was: loc_10F8
                add.w   d7,d4
                cmpi.w  #$F00,d4
                bls.w   Palette_UpdateFullScreenFade_FromWhiteStoreColor
                move.w  #$F00,d4
Palette_UpdateFullScreenFade_FromWhiteStoreColor:       ; was: loc_1106
                or.w    d3,d2
                or.w    d4,d2
                move.w  d2,(a0)+
                dbf     d1,Palette_UpdateFullScreenFade_FromWhiteLoop
                tst.w   (PaletteFadeProgress).w
                bne.w   Palette_UpdateFullScreenFade_FromWhiteReturn
                clr.w   (PaletteFadeStep).w
Palette_UpdateFullScreenFade_FromWhiteReturn:           ; was: locret_111C
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_BeginToWhite:              ; was: loc_111E
                tst.w   (PaletteFadeProgress).w
                bne.w   Palette_UpdateFullScreenFade_ContinueToWhite
                add.w   d0,(PaletteFadeProgress).w
                lea     (PaletteActiveBuffer).w,a0
                lea     (PaletteShadowBuffer).w,a1
                move.b  (PaletteFadeProgress).w,d5
                andi.w  #$FF,d5
                move.w  d5,d6
                lsl.w   #4,d6
                move.w  d6,d7
                lsl.w   #4,d7
                move.w  #$3F,d1                         ; '?'
Palette_UpdateFullScreenFade_BeginToWhiteLoop:          ; was: loc_1146
                move.w  (a0),d2
                move.w  d2,d3
                move.w  d2,d4
                andi.w  #$F,d2
                andi.w  #$F0,d3
                andi.w  #$F00,d4
                add.w   d5,d2
                cmpi.w  #$F,d2
                bls.w   Palette_UpdateFullScreenFade_BeginToWhiteClampRed
                move.w  #$F,d2
Palette_UpdateFullScreenFade_BeginToWhiteClampRed:      ; was: loc_1166
                add.w   d6,d3
                cmpi.w  #$F0,d3
                bls.w   Palette_UpdateFullScreenFade_BeginToWhiteClampGreen
                move.w  #$F0,d3
Palette_UpdateFullScreenFade_BeginToWhiteClampGreen:    ; was: loc_1174
                add.w   d7,d4
                cmpi.w  #$F00,d4
                bls.w   Palette_UpdateFullScreenFade_BeginToWhiteStoreColor
                move.w  #$F00,d4
Palette_UpdateFullScreenFade_BeginToWhiteStoreColor:    ; was: loc_1182
                or.w    d3,d2
                or.w    d4,d2
                move.w  d2,(a0)+
                move.w  d2,(a1)+
                dbf     d1,Palette_UpdateFullScreenFade_BeginToWhiteLoop
                cmpi.w  #$1000,(PaletteFadeProgress).w
                blt.w   Palette_UpdateFullScreenFade_BeginToWhiteReturn
                move.w  #$1000,(PaletteFadeProgress).w
                clr.w   (PaletteFadeStep).w
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
Palette_UpdateFullScreenFade_BeginToWhiteReturn:        ; was: locret_11AC
                rts
; ---------------------------------------------------------------------------
Palette_UpdateFullScreenFade_ContinueToWhite:           ; was: loc_11AE
                add.w   d0,(PaletteFadeProgress).w
                lea     (PaletteActiveBuffer).w,a0
                lea     (PaletteShadowBuffer).w,a1
                move.b  (PaletteFadeProgress).w,d5
                andi.w  #$FF,d5
                move.w  d5,d6
                lsl.w   #4,d6
                move.w  d6,d7
                lsl.w   #4,d7
                move.w  #$3F,d1                         ; '?'
Palette_UpdateFullScreenFade_ToWhiteLoop:               ; was: loc_11CE
                move.w  (a1)+,d2
                move.w  d2,d3
                move.w  d2,d4
                andi.w  #$F,d2
                andi.w  #$F0,d3
                andi.w  #$F00,d4
                add.w   d5,d2
                cmpi.w  #$F,d2
                bls.w   Palette_UpdateFullScreenFade_ToWhiteClampRed
                move.w  #$F,d2
Palette_UpdateFullScreenFade_ToWhiteClampRed:           ; was: loc_11EE
                add.w   d6,d3
                cmpi.w  #$F0,d3
                bls.w   Palette_UpdateFullScreenFade_ToWhiteClampGreen
                move.w  #$F0,d3
Palette_UpdateFullScreenFade_ToWhiteClampGreen:         ; was: loc_11FC
                add.w   d7,d4
                cmpi.w  #$F00,d4
                bls.w   Palette_UpdateFullScreenFade_ToWhiteStoreColor
                move.w  #$F00,d4
Palette_UpdateFullScreenFade_ToWhiteStoreColor:         ; was: loc_120A
                or.w    d3,d2
                or.w    d4,d2
                move.w  d2,(a0)+
                dbf     d1,Palette_UpdateFullScreenFade_ToWhiteLoop
                cmpi.w  #$1000,(PaletteFadeProgress).w
                blt.w   Palette_UpdateFullScreenFade_ToWhiteReturn
                move.w  #$1000,(PaletteFadeProgress).w
                clr.w   (PaletteFadeStep).w
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
Palette_UpdateFullScreenFade_ToWhiteReturn:             ; was: locret_1232
                rts
; End of function Palette_UpdateFullScreenFade
; Queues the horizontal-scroll table DMA to VRAM $F000. VDP register 11 bit 1
; selects the two-word full-screen value or the 448-word per-line table
Gfx_QueueHorizontalScrollDMA:                           ; was: sub_1234
                movea.w (VDPCommandQueueHead).w,a0
                move.l  #$70000083,-(a0)
                move.l  (HScrollDMASource).w,d0
                andi.l  #$FFFFFF,d0
                lsr.l   #1,d0
                move.w  #$9500,d1
                move.b  d0,d1
                move.w  d1,-(a0)
                lsr.l   #8,d0
                move.w  #$9600,d1
                move.b  d0,d1
                move.w  d1,-(a0)
                lsr.l   #8,d0
                move.w  #$9700,d1
                move.b  d0,d1
                move.w  d1,-(a0)
                move.w  #$8F02,-(a0)
                btst    #1,(VDPReg11Shadow+1).w
                bne.w   Gfx_QueueHorizontalScrollDMA_UsePerLineLength
                move.l  #$94009302,-(a0)
                bra.w   Gfx_QueueHorizontalScrollDMA_CommitCommand
; ---------------------------------------------------------------------------
Gfx_QueueHorizontalScrollDMA_UsePerLineLength:          ; was: loc_127E
                move.l  #$940193C0,-(a0)
Gfx_QueueHorizontalScrollDMA_CommitCommand:             ; was: loc_1284
                move.w  a0,(VDPCommandQueueHead).w
                rts
; End of function Gfx_QueueHorizontalScrollDMA
; Queues the vertical-scroll table DMA to VSRAM. VDP register 11 bit 2 selects
; the two-word full-screen value or the 40-word per-column table
Gfx_QueueVerticalScrollDMA:                             ; was: sub_128A
                movea.w (VDPCommandQueueHead).w,a0
                move.l  #$40000090,-(a0)
                move.l  (VScrollDMASource).w,d0
                andi.l  #$FFFFFF,d0
                lsr.l   #1,d0
                move.w  #$9500,d1
                move.b  d0,d1
                move.w  d1,-(a0)
                lsr.l   #8,d0
                move.w  #$9600,d1
                move.b  d0,d1
                move.w  d1,-(a0)
                lsr.l   #8,d0
                move.w  #$9700,d1
                move.b  d0,d1
                move.w  d1,-(a0)
                move.w  #$8F02,-(a0)
                btst    #2,(VDPReg11Shadow+1).w
                bne.w   Gfx_QueueVerticalScrollDMA_UsePerColumnLength
                move.l  #$94009302,-(a0)
                bra.w   Gfx_QueueVerticalScrollDMA_CommitCommand
; ---------------------------------------------------------------------------
Gfx_QueueVerticalScrollDMA_UsePerColumnLength:          ; was: loc_12D4
                move.l  #$94009328,-(a0)
Gfx_QueueVerticalScrollDMA_CommitCommand:               ; was: loc_12DA
                move.w  a0,(VDPCommandQueueHead).w
                rts
; End of function Gfx_QueueVerticalScrollDMA
; Closes a frame-timing debug pass by cycling backdrop color indices 15..0,
; then writing the display-enable and backdrop shadow values back to the VDP
Gfx_CycleBackdropColorIndices:                          ; was: sub_12E0
                tst.b   (FrameTimingDebugFlag).w
                bpl.w   Gfx_CycleBackdropColorIndices_Return
                move.w  (VDPReg1Shadow).w,d0
                bclr    #6,d0
                move.w  d0,(VDP_CTRL).l
                move.w  #$F,d0
Gfx_CycleBackdropColorIndices_Loop:                     ; was: loc_12FA
                move.w  d0,d1
                ori.w   #$8700,d1
                move.w  d1,(VDP_CTRL).l
                dbf     d0,Gfx_CycleBackdropColorIndices_Loop
                move.w  (VDPReg1Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg7Shadow).w,(VDP_CTRL).l
Gfx_CycleBackdropColorIndices_Return:                   ; was: locret_131A
                rts
; End of function Gfx_CycleBackdropColorIndices
; Blanks the display and selects backdrop color zero during timing diagnostics
Gfx_BlankDisplayAndBackdrop:                            ; was: sub_131C
                tst.b   (FrameTimingDebugFlag).w
                bpl.w   Gfx_BlankDisplayAndBackdrop_Return
                move.w  (VDPReg1Shadow).w,d0
                bclr    #6,d0
                move.w  d0,(VDP_CTRL).l
                move.w  #$8700,(VDP_CTRL).l
Gfx_BlankDisplayAndBackdrop_Return:                     ; was: locret_133A
                rts
; End of function Gfx_BlankDisplayAndBackdrop
; Restores display-enable and backdrop state after timing diagnostics
Gfx_RestoreDisplayAndBackdrop:                          ; was: sub_133C
                tst.b   (FrameTimingDebugFlag).w
                bpl.w   Gfx_RestoreDisplayAndBackdrop_Return
                move.w  (VDPReg1Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg7Shadow).w,(VDP_CTRL).l
Gfx_RestoreDisplayAndBackdrop_Return:                   ; was: locret_1354
                rts
; End of function Gfx_RestoreDisplayAndBackdrop
