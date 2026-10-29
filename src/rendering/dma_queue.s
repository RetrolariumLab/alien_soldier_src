; Queues zero-filled DMA records using the headered $FE/$FF byte-stream format
Gfx_QueueHeaderedZeroStreamDMA:                         ; was: sub_1D32
                clr.b   d3
                bra.s   Gfx_QueueHeaderedByteStreamDMA_InitializeQueue
; End of function Gfx_QueueHeaderedZeroStreamDMA
; Expands headered source bytes to words and queues one DMA command per record
Gfx_QueueHeaderedByteStreamDMA:                         ; was: sub_1D36
                move.b  #1,d3
Gfx_QueueHeaderedByteStreamDMA_InitializeQueue:         ; was: loc_1D3A
                movea.w (VDPCommandQueueHead).w,a1
                movea.w (VDPStagingDataCursor).w,a2
Gfx_QueueHeaderedByteStreamDMA_BeginRecord:             ; was: loc_1D42
                                        ; Gfx_QueueHeaderedByteStreamDMA+6A   j
                move.w  (a0)+,d0
                move.l  (a0)+,-(a1)
                move.l  a2,d1
                andi.l  #$FFFFFF,d1
                lsr.l   #1,d1
                move.w  #$9500,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                lsr.l   #8,d1
                move.w  #$9600,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                lsr.l   #8,d1
                move.w  #$9700,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                move.w  #$8F02,-(a1)
                move.l  #$94009300,d1
Gfx_QueueHeaderedByteStreamDMA_ReadByte:                ; was: loc_1D76
                                        ; Gfx_QueueHeaderedByteStreamDMA+5C   j
                move.b  (a0)+,d0
                cmpi.b  #$FE,d0
                beq.s   Gfx_QueueHeaderedByteStreamDMA_FinishRecord
                cmpi.b  #$FF,d0
                beq.s   Gfx_QueueHeaderedByteStreamDMA_FinishStream
                tst.b   d3
                beq.s   Gfx_QueueHeaderedByteStreamDMA_StageZero
                move.w  d0,(a2)+
                addq.b  #1,d1
                bra.s   Gfx_QueueHeaderedByteStreamDMA_ReadByte
; ---------------------------------------------------------------------------
Gfx_QueueHeaderedByteStreamDMA_StageZero:               ; was: loc_1D8E
                clr.w   (a2)+
                addq.b  #1,d1
                bra.s   Gfx_QueueHeaderedByteStreamDMA_ReadByte
; ---------------------------------------------------------------------------
Gfx_QueueHeaderedByteStreamDMA_FinishRecord:            ; was: loc_1D94
                move.l  d1,-(a1)
                move.w  a0,d2
                btst    #0,d2
                beq.s   Gfx_QueueHeaderedByteStreamDMA_BeginRecord
                addq.l  #1,a0
                bra.s   Gfx_QueueHeaderedByteStreamDMA_BeginRecord
; ---------------------------------------------------------------------------
Gfx_QueueHeaderedByteStreamDMA_FinishStream:            ; was: loc_1DA2
                move.l  d1,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                move.w  a2,(VDPStagingDataCursor).w
                rts
; End of function Gfx_QueueHeaderedByteStreamDMA
; Queues zero-filled DMA records using the headerless $FE/$FF byte-stream format
Gfx_QueueZeroStreamDMA:                                 ; was: sub_1DAE
                clr.b   d3
                bra.s   Gfx_QueueByteStreamDMA_InitializeQueue
; End of function Gfx_QueueZeroStreamDMA
; Expands source bytes to words and queues one DMA command per record
Gfx_QueueByteStreamDMA:
                move.b  #1,d3
Gfx_QueueByteStreamDMA_InitializeQueue:                 ; was: loc_1DB6
                movea.w (VDPCommandQueueHead).w,a1
                movea.w (VDPStagingDataCursor).w,a2
Gfx_QueueByteStreamDMA_BeginRecord:                     ; was: loc_1DBE
                                        ; Gfx_QueueZeroStreamDMA+6C   j
                move.l  (a0)+,-(a1)
                move.l  a2,d1
                andi.l  #$FFFFFF,d1
                lsr.l   #1,d1
                move.w  #$9500,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                lsr.l   #8,d1
                move.w  #$9600,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                lsr.l   #8,d1
                move.w  #$9700,d2
                move.b  d1,d2
                move.w  d2,-(a1)
                move.w  #$8F02,-(a1)
                move.l  #$94009300,d1
Gfx_QueueByteStreamDMA_ReadByte:                        ; was: loc_1DF0
                                        ; Gfx_QueueZeroStreamDMA+5E   j
                move.b  (a0)+,d0
                cmpi.b  #$FE,d0
                beq.s   Gfx_QueueByteStreamDMA_FinishRecord
                cmpi.b  #$FF,d0
                beq.s   Gfx_QueueByteStreamDMA_FinishStream
                tst.b   d3
                beq.s   Gfx_QueueByteStreamDMA_StageZero
                move.w  d0,(a2)+
                addq.b  #1,d1
                bra.s   Gfx_QueueByteStreamDMA_ReadByte
; ---------------------------------------------------------------------------
Gfx_QueueByteStreamDMA_StageZero:                       ; was: loc_1E08
                clr.w   (a2)+
                addq.b  #1,d1
                bra.s   Gfx_QueueByteStreamDMA_ReadByte
; ---------------------------------------------------------------------------
Gfx_QueueByteStreamDMA_FinishRecord:                    ; was: loc_1E0E
                move.l  d1,-(a1)
                move.w  a0,d2
                btst    #0,d2
                beq.s   Gfx_QueueByteStreamDMA_BeginRecord
                addq.l  #1,a0
                bra.s   Gfx_QueueByteStreamDMA_BeginRecord
; ---------------------------------------------------------------------------
Gfx_QueueByteStreamDMA_FinishStream:                    ; was: loc_1E1C
                move.l  d1,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                move.w  a2,(VDPStagingDataCursor).w
                rts
; End of function Gfx_QueueByteStreamDMA
; Converts a value to decimal digit tile indices and queues their DMA transfer
Gfx_QueueDecimalDigitsDMA:                              ; was: sub_1E28
                movea.w (VDPCommandQueueHead).w,a1
                movea.w (VDPStagingDataCursor).w,a2
                move.l  d2,-(a1)
                move.l  a2,d4
                andi.l  #$FFFFFF,d4
                lsr.l   #1,d4
                move.w  #$9500,d2
                move.b  d4,d2
                move.w  d2,-(a1)
                lsr.l   #8,d4
                move.w  #$9600,d2
                move.b  d4,d2
                move.w  d2,-(a1)
                lsr.l   #8,d4
                move.w  #$9700,d2
                move.b  d4,d2
                move.w  d2,-(a1)
                move.w  d3,d2
                bne.w   Gfx_QueueDecimalDigitsDMA_UseRequestedWidth
                moveq   #5,d3
                move.w  #8,d2
                andi.l  #$FFFF,d1
                bra.w   Gfx_QueueDecimalDigitsDMA_WriteLeadingBlankOrDigit
; ---------------------------------------------------------------------------
Gfx_QueueDecimalDigitsDMA_UseRequestedWidth:            ; was: loc_1E6E
                subq.w  #1,d2
                asl.w   #1,d2
                andi.l  #$FFFF,d1
                bra.w   Gfx_QueueDecimalDigitsDMA_WriteDigit
; ---------------------------------------------------------------------------
Gfx_QueueDecimalDigitsDMA_WriteLeadingBlankOrDigit:     ; was: loc_1E7C
                                        ; Gfx_QueueDecimalDigitsDMA+66   j
                divu.w  DecimalDigitDivisors(pc,d2.w),d1
                bne.w   Gfx_QueueDecimalDigitsDMA_EmitDigit
                move.b  #$B4,d0
                move.w  d0,(a2)+
                swap    d1
                subq.w  #2,d2
                bpl.s   Gfx_QueueDecimalDigitsDMA_WriteLeadingBlankOrDigit
                bra.w   Gfx_QueueDecimalDigitsDMA_FinalizeQueue
; ---------------------------------------------------------------------------
Gfx_QueueDecimalDigitsDMA_WriteDigit:                   ; was: loc_1E94
                                        ; Gfx_QueueDecimalDigitsDMA+7E   j
                divu.w  DecimalDigitDivisors(pc,d2.w),d1
Gfx_QueueDecimalDigitsDMA_EmitDigit:                    ; was: loc_1E98
                addi.b  #-$4B,d1
                move.b  d1,d0
                move.w  d0,(a2)+
                clr.w   d1
                swap    d1
                subq.w  #2,d2
                bpl.s   Gfx_QueueDecimalDigitsDMA_WriteDigit
Gfx_QueueDecimalDigitsDMA_FinalizeQueue:                ; was: loc_1EA8
                move.w  #$8F02,-(a1)
                move.l  #$94009300,d2
                add.b   d3,d2
                move.l  d2,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                move.w  a2,(VDPStagingDataCursor).w
                rts
; End of function Gfx_QueueDecimalDigitsDMA
; Powers of ten indexed from the least-significant decimal digit
DecimalDigitDivisors:   dc.w    1, 10, 100, 1000, 10000  ; was: sub_1EC0

; Converts a value to hexadecimal digit tile indices and queues their DMA transfer
Gfx_QueueHexDigitsDMA:
                movea.w (VDPCommandQueueHead).w,a1
                movea.w (VDPStagingDataCursor).w,a2
                move.l  d2,-(a1)
                move.l  a2,d4
                andi.l  #$FFFFFF,d4
                lsr.l   #1,d4
                move.w  #$9500,d2
                move.b  d4,d2
                move.w  d2,-(a1)
                lsr.l   #8,d4
                move.w  #$9600,d2
                move.b  d4,d2
                move.w  d2,-(a1)
                lsr.l   #8,d4
                move.w  #$9700,d2
                move.b  d4,d2
                move.w  d2,-(a1)
                move.w  d3,d2
                bne.w   Gfx_QueueHexDigitsDMA_UseRequestedWidth
                moveq   #5,d3
                move.w  #8,d2
                andi.l  #$FFFF,d1
                bra.w   Gfx_QueueHexDigitsDMA_WriteLeadingBlankOrDigit
; ---------------------------------------------------------------------------
Gfx_QueueHexDigitsDMA_UseRequestedWidth:                ; was: loc_1F10
                subq.w  #1,d2
                asl.w   #1,d2
                andi.l  #$FFFF,d1
                bra.w   Gfx_QueueHexDigitsDMA_WriteDigit
; ---------------------------------------------------------------------------
Gfx_QueueHexDigitsDMA_WriteLeadingBlankOrDigit:         ; was: loc_1F1E
                                        ; Gfx_QueueHexDigitsDMA+66   j
                divu.w  Gfx_HexDigitDivisors(pc,d2.w),d1
                bne.w   Gfx_QueueHexDigitsDMA_EmitDigit
                move.b  #$B4,d0
                move.w  d0,(a2)+
                swap    d1
                subq.w  #2,d2
                bpl.s   Gfx_QueueHexDigitsDMA_WriteLeadingBlankOrDigit
                bra.w   Gfx_QueueHexDigitsDMA_FinalizeQueue
; ---------------------------------------------------------------------------
Gfx_QueueHexDigitsDMA_WriteDigit:                       ; was: loc_1F36
                                        ; Gfx_QueueHexDigitsDMA+7E   j
                divu.w  Gfx_HexDigitDivisors(pc,d2.w),d1
Gfx_QueueHexDigitsDMA_EmitDigit:                        ; was: loc_1F3A
                addi.b  #-$4B,d1
                move.b  d1,d0
                move.w  d0,(a2)+
                clr.w   d1
                swap    d1
                subq.w  #2,d2
                bpl.s   Gfx_QueueHexDigitsDMA_WriteDigit
Gfx_QueueHexDigitsDMA_FinalizeQueue:                    ; was: loc_1F4A
                move.w  #$8F02,-(a1)
                move.l  #$94009300,d2
                add.b   d3,d2
                move.l  d2,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                move.w  a2,(VDPStagingDataCursor).w
                rts
; End of function Gfx_QueueHexDigitsDMA
; ---------------------------------------------------------------------------
Gfx_HexDigitDivisors:   dc.w    1, $10, $100, $1000     ; was: word_1F62

; Prepends a 16-byte VDP DMA command for the length-prefixed source at a1
Gfx_PrependDMATransferCommand:                          ; was: sub_1F6A
                                        ; Sprite_RenderDynamicObjectWithEntryAttributes+62   p
                move.w  (a1)+,d1
                move.w  d0,d7
                rol.w   #2,d7
                andi.w  #3,d7
                ori.w   #$80,d7
                move.w  d7,-(a0)
                move.w  d0,d7
                andi.w  #$3FFF,d7
                ori.w   #$4000,d7
                move.w  d7,-(a0)
                add.w   d1,d0
                lsr.w   #1,d1
                move.w  #$9300,d7
                move.b  d1,d7
                move.w  d7,-(a0)
                lsr.w   #8,d1
                move.w  #$9400,d7
                move.b  d1,d7
                move.w  d7,-(a0)
                move.w  #$8F02,-(a0)
                move.l  a1,d1
                andi.l  #$FFFFFF,d1
                lsr.l   #1,d1
                move.w  #$9500,d7
                move.b  d1,d7
                move.w  d7,-(a0)
                lsr.l   #8,d1
                move.w  #$9600,d7
                move.b  d1,d7
                move.w  d7,-(a0)
                lsr.l   #8,d1
                move.w  #$9700,d7
                move.b  d1,d7
                move.w  d7,-(a0)
                rts
; End of function Gfx_PrependDMATransferCommand
; Loads four optional palette blocks into matching active and shadow slots
Palette_LoadFourOptionalBlocks:                         ; was: sub_1FC8
                lea     (PaletteActiveBuffer).w,a2
                lea     (PaletteShadowBuffer).w,a3
                bsr.w   Palette_CopyOptionalBlock
                bsr.w   Palette_CopyOptionalBlock
                bsr.w   Palette_CopyOptionalBlock
                bsr.w   Palette_CopyOptionalBlock
                rts
; End of function Palette_LoadFourOptionalBlocks
; Copies one optional 32-byte palette block into active and shadow buffers
Palette_CopyOptionalBlock:                              ; was: sub_1FE2
                                        ; Palette_LoadFourOptionalBlocks+C   p
                move.l  (a0)+,d0
                beq.w   Palette_CopyOptionalBlock_SkipNull
                movea.l d0,a1
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                move.l  (a1),(a2)+
                move.l  (a1)+,(a3)+
                rts
; ---------------------------------------------------------------------------
Palette_CopyOptionalBlock_SkipNull:                     ; was: loc_200C
                lea     $20(a2),a2
                lea     $20(a3),a3
                rts
; End of function Palette_CopyOptionalBlock
; Main object processing loop - iterates through active objects
