; Clears the 128-byte word-per-pixel workspace used by one decoded tile
TileCodec_ClearDecodeBuffer:                            ; was: sub_2A58
                                        ; Gfx_LoadCompressedGfx+1A   p
                lea     (GraphicsStagingBuffer).w,a5
                moveq   #0,d6
                moveq   #$1F,d7
TileCodec_ClearDecodeBuffer_Loop:                       ; was: loc_2A60
                move.l  d6,(a5)+
                dbf     d7,TileCodec_ClearDecodeBuffer_Loop
                rts
; End of function TileCodec_ClearDecodeBuffer
; Decodes one compressed 8x8 tile into 64 word-sized palette indices
TileCodec_DecodeTile:                                   ; was: sub_2A68
                                        ; sub_2700:loc_271E   p
                movem.l d2-d7/a4-a5,-(sp)
                move.w  (DataLoaderCodecState).w,d2
                move.w  (DataLoaderCodecState+2).w,d3
                lea     (GraphicsStagingBuffer).w,a5
                lea     TileDecodeBufferEnd-GraphicsStagingBuffer(a5),a4
TileCodec_DecodeTile_ReadToken:                         ; was: loc_2A7C
                subq.w  #5,d2
                bgt.w   TileCodec_DecodeTile_UseBufferedToken
                beq.w   TileCodec_DecodeTile_ReloadTokenAtWordBoundary
                move.w  d2,d7
                addq.w  #5,d2
                lsl.l   d2,d3
                move.w  (a1)+,d3
                neg.w   d7
                lsl.l   d7,d3
                addi.w  #$B,d2
                move.l  d3,d7
                swap    d7
                bra.w   TileCodec_DecodeTile_InterpretToken
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_ReloadTokenAtWordBoundary:         ; was: loc_2A9E
                moveq   #$10,d2
                rol.w   #5,d3
                move.w  d3,d7
                move.w  (a1)+,d3
                bra.w   TileCodec_DecodeTile_InterpretToken
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_UseBufferedToken:                  ; was: loc_2AAA
                rol.w   #5,d3
                move.w  d3,d7
TileCodec_DecodeTile_InterpretToken:                    ; was: loc_2AAE
                                        ; TileCodec_DecodeTile+3E   j
                andi.w  #$1F,d7
                lsr.w   #1,d7
                bcs.w   TileCodec_DecodeTile_BeginMarkerSequence
                move.w  d7,d4
                move.w  d4,(a5)+
                move.w  d4,d5
                ori.w   #$8000,d5
                bra.w   TileCodec_DecodeTile_BeginRunLength
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_BeginMarkerSequence:               ; was: loc_2AC6
                move.w  d7,d4
                move.w  d4,(a5)+
                move.w  d4,d5
                bset    #$F,d5
                moveq   #0,d6
TileCodec_DecodeTile_ReadMarkerOffset:                  ; was: loc_2AD2
                                        ; TileCodec_DecodeTile+D8   j
                subq.w  #2,d2
                bgt.w   TileCodec_DecodeTile_UseBufferedOffset
                beq.w   TileCodec_DecodeTile_ReloadOffsetAtWordBoundary
                moveq   #$F,d2
                add.w   d3,d3
                move.w  (a1)+,d3
                addx.w  d3,d3
                move.w  d3,d7
                addx.w  d7,d7
                bra.w   TileCodec_DecodeTile_InterpretMarkerOffset
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_ReloadOffsetAtWordBoundary:        ; was: loc_2AEC
                moveq   #$10,d2
                rol.w   #2,d3
                move.w  d3,d7
                move.w  (a1)+,d3
                bra.w   TileCodec_DecodeTile_InterpretMarkerOffset
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_UseBufferedOffset:                 ; was: loc_2AF8
                rol.w   #2,d3
                move.w  d3,d7
TileCodec_DecodeTile_InterpretMarkerOffset:             ; was: loc_2AFC
                                        ; TileCodec_DecodeTile+8C   j
                andi.w  #3,d7
                beq.w   TileCodec_DecodeTile_ReadExtendedMarkerOffset
                addq.w  #6,d7
                add.w   d7,d7
                add.w   d7,d6
                move.w  d5,-2(a5,d6.w)
                bra.s   TileCodec_DecodeTile_ReadMarkerOffset
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_ReadExtendedMarkerOffset:          ; was: loc_2B10
                subq.w  #1,d2
                bne.w   TileCodec_DecodeTile_ReadExtendedMarkerBit
                moveq   #$10,d2
                add.w   d3,d3
                move.w  (a1)+,d3
                roxr.w  #1,d3
TileCodec_DecodeTile_ReadExtendedMarkerBit:             ; was: loc_2B1E
                addx.w  d3,d3
                bcc.w   TileCodec_DecodeTile_BeginRunLength
                subq.w  #1,d2
                bne.w   TileCodec_DecodeTile_SelectExtendedMarkerOffset
                moveq   #$10,d2
                add.w   d3,d3
                move.w  (a1)+,d3
                roxr.w  #1,d3
TileCodec_DecodeTile_SelectExtendedMarkerOffset:        ; was: loc_2B32
                addx.w  d3,d3
                bcs.w   TileCodec_DecodeTile_StoreOffset20Marker
                addi.w  #$C,d6
                move.w  d5,-2(a5,d6.w)
                bra.s   TileCodec_DecodeTile_ReadMarkerOffset
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_StoreOffset20Marker:               ; was: loc_2B42
                addi.w  #$14,d6
                move.w  d5,-2(a5,d6.w)
                bra.s   TileCodec_DecodeTile_ReadMarkerOffset
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_BeginRunLength:                    ; was: loc_2B4C
                                        ; TileCodec_DecodeTile+B8   j
                moveq   #0,d7
                moveq   #1,d6
TileCodec_DecodeTile_ReadRunLengthPrefix:               ; was: loc_2B50
                                        ; TileCodec_DecodeTile+106   j
                addq.w  #1,d7
                add.w   d6,d6
                subq.w  #1,d2
                bne.w   TileCodec_DecodeTile_ReadBufferedPrefix
                moveq   #$10,d2
                add.w   d3,d3
                bcc.w   TileCodec_DecodeTile_ReloadPrefixAtWordBoundary
                move.w  (a1)+,d3
                bra.s   TileCodec_DecodeTile_ReadRunLengthPrefix
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_ReloadPrefixAtWordBoundary:        ; was: loc_2B66
                move.w  (a1)+,d3
                bra.w   TileCodec_DecodeTile_ReadRunLengthPayload
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_ReadBufferedPrefix:                ; was: loc_2B6C
                add.w   d3,d3
                bcs.s   TileCodec_DecodeTile_ReadRunLengthPrefix
TileCodec_DecodeTile_ReadRunLengthPayload:              ; was: loc_2B70
                sub.w   d7,d2
                bgt.w   TileCodec_DecodeTile_UseBufferedPayload
                beq.w   TileCodec_DecodeTile_ReloadPayloadAtWordBoundary
                swap    d3
                clr.w   d3
                swap    d3
                add.w   d7,d2
                lsl.l   d2,d3
                move.w  (a1)+,d3
                sub.w   d2,d7
                lsl.l   d7,d3
                moveq   #$10,d2
                sub.w   d7,d2
                move.l  d3,d7
                swap    d7
                bra.w   TileCodec_DecodeTile_EmitRun
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_ReloadPayloadAtWordBoundary:       ; was: loc_2B96
                moveq   #$10,d2
                swap    d3
                clr.w   d3
                rol.l   d7,d3
                move.w  d3,d7
                move.w  (a1)+,d3
                bra.w   TileCodec_DecodeTile_EmitRun
; ---------------------------------------------------------------------------
TileCodec_DecodeTile_UseBufferedPayload:                ; was: loc_2BA6
                swap    d3
                clr.w   d3
                rol.l   d7,d3
                move.w  d3,d7
                swap    d3
TileCodec_DecodeTile_EmitRun:                           ; was: loc_2BB0
                                        ; TileCodec_DecodeTile+13A   j
                add.w   d7,d6
                subq.w  #3,d6
                bcs.w   TileCodec_DecodeTile_CheckComplete
TileCodec_DecodeTile_EmitPixel:                         ; was: loc_2BB8
                move.w  (a5),d7
                bpl.w   TileCodec_DecodeTile_StorePixel
                move.w  d7,d5
                move.b  d5,d4
TileCodec_DecodeTile_StorePixel:                        ; was: loc_2BC2
                move.w  d4,(a5)+
                dbf     d6,TileCodec_DecodeTile_EmitPixel
TileCodec_DecodeTile_CheckComplete:                     ; was: loc_2BC8
                cmpa.l  a4,a5
                bcs.w   TileCodec_DecodeTile_ReadToken
                move.w  d2,(DataLoaderCodecState).w
                move.w  d3,(DataLoaderCodecState+2).w
                movem.l (sp)+,d2-d7/a4-a5
                rts
; End of function TileCodec_DecodeTile
; Packs 64 decoded palette-index words into one 32-byte 4bpp tile
TileCodec_PackDecodedTile:                              ; was: sub_2BDC
                                        ; Gfx_DecompTilesToRAM+12   p
                lea     (GraphicsStagingBuffer).w,a5
                moveq   #7,d6
TileCodec_PackDecodedTile_RowLoop:                      ; was: loc_2BE2
                move.w  (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                swap    d7
                move.w  (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                move.l  d7,(a2)+
                dbf     d6,TileCodec_PackDecodedTile_RowLoop
                rts
; End of function TileCodec_PackDecodedTile
; Packs one decoded tile and writes its eight rows directly to the VDP data port
TileCodec_WriteDecodedTileToVRAM:                       ; was: sub_2C08
                lea     (VDP_CTRL).l,a4
                move    sr,-(sp)
                move    #$2700,sr
                move.w  #$8F02,(a4)
                moveq   #0,d7
                move.l  a3,d6
                move.w  d6,d7
                lsl.l   #2,d7
                lsr.w   #2,d7
                ori.w   #$4000,d7
                swap    d7
                move.l  d7,(a4)
                lea     $20(a3),a3
                lea     (VDP_DATA).l,a4
                lea     (GraphicsStagingBuffer).w,a5
                moveq   #7,d6
TileCodec_WriteDecodedTileToVRAM_RowLoop:               ; was: loc_2C3A
                move.w  (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                swap    d7
                move.w  (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                lsl.w   #4,d7
                add.w   (a5)+,d7
                move.l  d7,(a4)
                dbf     d6,TileCodec_WriteDecodedTileToVRAM_RowLoop
                move    (sp)+,sr
                rts
; End of function TileCodec_WriteDecodedTileToVRAM
; Queues one DMA command, advances source/destination pointers, and marks it pending
Gfx_QueueDMATransferAndAdvance:                         ; was: sub_2C62
                                        ; Gfx_DecompTilesToVRAMBatched+3A   p
                move    sr,-(sp)
                move    #$2700,sr
                movea.w (VDPCommandQueueHead).w,a5
                move.w  a3,d7
                rol.w   #2,d7
                andi.w  #3,d7
                ori.w   #$80,d7
                move.w  d7,-(a5)
                move.w  a3,d7
                andi.w  #$3FFF,d7
                ori.w   #$4000,d7
                move.w  d7,-(a5)
                move.l  a2,d7
                andi.l  #$FFFFFF,d7
                lsr.l   #1,d7
                move.w  #$9500,d6
                move.b  d7,d6
                move.w  d6,-(a5)
                lsr.l   #8,d7
                move.w  #$9600,d6
                move.b  d7,d6
                move.w  d6,-(a5)
                lsr.l   #8,d7
                move.w  #$9700,d6
                move.b  d7,d6
                move.w  d6,-(a5)
                move.w  #$8F02,-(a5)
                move.w  d1,d7
                lsr.w   #1,d7
                move.w  #$9300,d6
                move.b  d7,d6
                move.w  d6,-(a5)
                lsr.w   #8,d7
                move.w  #$9400,d6
                move.b  d7,d6
                move.w  d6,-(a5)
                adda.w  d1,a2
                adda.w  d1,a3
                move.b  #1,(VDPTransferPending).w
                move.w  a5,(VDPCommandQueueHead).w
                move    (sp)+,sr
                rts
; End of function Gfx_QueueDMATransferAndAdvance
; Queues one DMA command from a length-prefixed ROM block and returns its next VRAM destination
Gfx_QueueLengthPrefixedROMDMA:                          ; was: sub_2CD8
                movea.w (VDPCommandQueueHead).w,a1
                move.w  d0,-(sp)
                move.w  d0,d2
                rol.w   #2,d2
                andi.w  #3,d2
                ori.w   #$80,d2
                move.w  d2,-(a1)
                andi.w  #$3FFF,d0
                ori.w   #$4000,d0
                move.w  d0,-(a1)
                move.w  (a0)+,d1
                add.w   d1,(sp)
                move.l  a0,d0
                andi.l  #$FFFFFF,d0
                lsr.l   #1,d0
                move.w  #$9500,d2
                move.b  d0,d2
                move.w  d2,-(a1)
                lsr.l   #8,d0
                move.w  #$9600,d2
                move.b  d0,d2
                move.w  d2,-(a1)
                lsr.l   #8,d0
                move.w  #$9700,d2
                move.b  d0,d2
                move.w  d2,-(a1)
                move.w  #$8F02,-(a1)
                lsr.w   #1,d1
                move.w  #$9300,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                lsr.w   #8,d1
                move.w  #$9400,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                move.w  (sp)+,d0
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function Gfx_QueueLengthPrefixedROMDMA
; Full game initialization with all subsystems
