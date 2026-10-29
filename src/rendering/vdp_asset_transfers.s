Gfx_AdjustSelectedTileBlocks:                           ; was: sub_11170
                                        ; Boss_ViblackInit+BC   p
                moveq   #$FFFFFFFF,d1
                move.w  (a0)+,d1
                movea.l d1,a1
                moveq   #5,d3
                bra.s   Gfx_AdjustSelectedTileBlocks_ReadBlockIndex
; ---------------------------------------------------------------------------
Gfx_AdjustSelectedTileBlocks_ProcessBlock:              ; was: loc_1117A
                asl.w   d3,d1
                moveq   #$F,d7
Gfx_AdjustSelectedTileBlocks_WordLoop:                  ; was: loc_1117E
                move.w  (a1,d1.w),d2
                andi.w  #$1FFF,d2
                add.w   d0,d2
                move.w  d2,(a1,d1.w)
                addq.w  #2,d1
                dbf     d7,Gfx_AdjustSelectedTileBlocks_WordLoop
Gfx_AdjustSelectedTileBlocks_ReadBlockIndex:            ; was: loc_11192
                moveq   #0,d1
                move.b  (a0)+,d1
                cmpi.w  #$FF,d1
                bne.s   Gfx_AdjustSelectedTileBlocks_ProcessBlock
                rts
; End of function Gfx_AdjustSelectedTileBlocks
; Adjusts tile pattern indices
Gfx_AdjustTileIndexRows:                                ; was: sub_1119E
                                        ; Gfx_AdjustTransitionTileIndexRows+8   j
                moveq   #$F,d6
Gfx_AdjustTileIndexRows_WordLoop:                       ; was: loc_111A0
                move.w  (a0),d2
                andi.w  #$1FFF,d2
                add.w   d0,d2
                move.w  d2,(a0)+
                dbf     d6,Gfx_AdjustTileIndexRows_WordLoop
                dbf     d7,Gfx_AdjustTileIndexRows
                rts
; End of function Gfx_AdjustTileIndexRows
; Updates tilemap tile indices and palette bits with offset
Gfx_UpdateTilemapIndices:                               ; was: sub_111B4
                                        ; Stage_SevenForceInitializeVictoryTransition+2C   p
                moveq   #$F,d6
Gfx_UpdateTilemapIndices_WordLoop:                      ; was: loc_111B6
                move.w  (a0),d2
                move.w  d2,d3
                andi.w  #$1800,d3
                andi.w  #$7FF,d2
                beq.s   Gfx_UpdateTilemapIndices_StoreWord
                add.w   d1,d2
                andi.w  #$7FF,d2
Gfx_UpdateTilemapIndices_StoreWord:                     ; was: loc_111CA
                or.w    d3,d2
                add.w   d0,d2
                move.w  d2,(a0)+
                dbf     d6,Gfx_UpdateTilemapIndices_WordLoop
                dbf     d7,Gfx_UpdateTilemapIndices
                rts
; End of function Gfx_UpdateTilemapIndices
; Transfers a single font tile to VRAM
Gfx_QueueNextFontTileDMA:                               ; was: sub_111DA
                tst.w   (FontTileDMACounter).w
                bmi.w   Gfx_QueueNextFontTileDMA_Return
                movea.w (VDPCommandQueueHead).w,a1
                move.w  (FontTileDMAVRAMAddress).w,d0
                move.w  d0,d1
                andi.w  #$3FFE,d0
                addi.w  #$4000,d0
                andi.w  #$C000,d1
                moveq   #$E,d2
                lsr.w   d2,d1
                addi.w  #$80,d1
                move.w  d1,-(a1)
                move.w  d0,-(a1)
                move.l  #$94029300,d4
                moveq   #0,d0
                move.w  (FontTileDMASourceOffset).w,d0
                addi.l  #SharedFontTileArt,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d2
                move.b  (DMASourceEncoding+1).w,d3
                andi.w  #$7F,d3
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                move.b  d2,-(a1)
                move.b  #$96,-(a1)
                move.b  d3,-(a1)
                move.b  #$97,-(a1)
                move.w  #$8F02,-(a1)
                move.l  d4,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                addi.w  #$400,(FontTileDMAVRAMAddress).w
                addi.w  #$400,(FontTileDMASourceOffset).w
                subq.w  #1,(FontTileDMACounter).w
Gfx_QueueNextFontTileDMA_Return:                        ; was: locret_11254
                rts
; End of function Gfx_QueueNextFontTileDMA
; Writes VDP command registers
Gfx_QueueLargeFontDMA:                                  ; was: sub_11256
                                        ; WeaponSetup_InitializeScreen+46   j
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$80,-(a1)
                move.w  #$6000,-(a1)
                move.l  #$94209000,d4
                bra.s   Gfx_BuildQueuedFontDMA
; End of function Gfx_QueueLargeFontDMA
; Sets up VDP command to transfer to palette RAM
Gfx_QueueSmallFontDMA:                                  ; was: sub_1126A
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$80,-(a1)
                move.w  #$6000,-(a1)
                move.l  #$94069300,d4
                bra.s   Gfx_BuildQueuedFontDMA
; End of function Gfx_QueueSmallFontDMA
; Queues VRAM write command for plane A at address 0x6000
Gfx_QueueLargeFontDMACommand81:                         ; was: sub_1127E
                                        ; TitleScreen_Initialize+44   j
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$81,-(a1)
                move.w  #$6000,-(a1)
                move.l  #$94209000,d4
                bra.s   Gfx_BuildQueuedFontDMA
; End of function Gfx_QueueLargeFontDMACommand81
; Queues DMA transfer for font tiles to VRAM with Z80 sync
Gfx_QueueSmallFontDMACommand83:                         ; was: sub_11292
                                        ; StageReady_Initialize+32   p
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                move.w  #$5400,-(a1)
                move.l  #$94059300,d4
Gfx_BuildQueuedFontDMA:                                 ; was: loc_112A4
                                        ; Gfx_QueueSmallFontDMA+12   j
                move.l  #SharedFontTileArt,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d2
                move.b  (DMASourceEncoding+1).w,d3
                andi.w  #$7F,d3
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                move.b  d2,-(a1)
                move.b  #$96,-(a1)
                move.b  d3,-(a1)
                move.b  #$97,-(a1)
                move.w  #$8F02,-(a1)
                move.l  d4,-(a1)
                move    sr,-(sp)
                move    #$2700,sr
Gfx_BuildQueuedFontDMA_AcquireZ80Bus:                   ; was: loc_112DA
                bset    #0,(IO_Z80BUS).l
                bne.s   Gfx_BuildQueuedFontDMA_AcquireZ80Bus
                lea     (VDP_CTRL).l,a0
                move.w  (VDPReg1Shadow).w,d0
                bset    #4,d0
                move.w  d0,(a0)
                move.l  (a1)+,(a0)
                move.l  (a1)+,(a0)
                move.l  (a1)+,(a0)
                move.w  (a1)+,(a0)
                move.w  (a1)+,(a0)
                move.w  (VDPReg1Shadow).w,d0
                bclr    #4,d0
                move.w  d0,(a0)
; Releases Z80 bus control and restores status register
Gfx_ReleaseZ80Bus:                                      ; was: loc_11308
                bclr    #0,(IO_Z80BUS).l
                beq.s   Gfx_ReleaseZ80Bus
                move    (sp)+,sr
                rts
; End of function Gfx_QueueSmallFontDMACommand83
; ---------------------------------------------------------------------------
