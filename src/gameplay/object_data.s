LoadObjData:
                                        ; VBlank_InitStage2DemoVScrollEffect+1E   p
                move.w  (a0)+,d0
                bmi.w   LoadObjData_Return
                lsl.w   #2,d0
                movea.l LoadObjDataHandlers(pc,d0.w),a1
                jsr     (a1)
                bra.s   LoadObjData
; ---------------------------------------------------------------------------
LoadObjData_Return:                                     ; was: locret_264E
                rts
; End of function LoadObjData
; ---------------------------------------------------------------------------
LoadObjDataHandlers:    dc.l    LoadFuncToRAM           ; was: off_2650
                dc.l    Gfx_LoadDataToVRAM
                dc.l    Gfx_LoadAndDecompTiles
                dc.l    Gfx_LoadCompressedGfx
                dc.l    LoadFuncToRAM
                dc.l    Gfx_LoadDataToVRAM
                dc.l    LoadCompressedToRAM
                dc.l    LoadCompressedToVRAM

; The source word supplies a fixed byte count, not the extent through RTE
; Some HBlank descriptors therefore copy adjacent ROM bytes after the handler
LoadFuncToRAM:
                                        ; ROM:00002660   o
                movea.l (a0)+,a1
                moveq   #$FFFFFFFF,d2
                move.w  (a0)+,d2
                movea.l d2,a2
                move.w  (a1)+,d1
                lsr.w   #2,d1
                subq.w  #1,d1
; Loop that copies function code from ROM to RAM 4 bytes at a time for dynamic code execution
Data_CopyFunctionLoop:                                  ; was: loc_267E
                move.l  (a1)+,(a2)+
                dbf     d1,Data_CopyFunctionLoop
                rts
; End of function LoadFuncToRAM

; Loads graphics data to VRAM
Gfx_LoadDataToVRAM:                                     ; was: sub_2686
                                        ; ROM:00002664   o
                movea.l (a0)+,a1
                moveq   #0,d1
                move.w  (a0)+,d1
                movea.l d1,a3
                move.w  (a1)+,d0
Gfx_LoadDataToVRAM_BatchLoop:                           ; was: loc_2690
                move.w  #$200,d1
                cmp.w   d1,d0
                bge.w   Gfx_LoadDataToVRAM_TransferBatch
                move.w  d0,d1
Gfx_LoadDataToVRAM_TransferBatch:                       ; was: loc_269C
                sub.w   d1,d0
                lsr.w   #2,d1
                subq.w  #1,d1
                lea     (VDP_CTRL).l,a5
                move    sr,-(sp)
                move    #$2700,sr
                move.w  #$8F02,(a5)
                move.l  a3,d7
                lsl.l   #2,d7
                lsr.w   #2,d7
                ori.w   #$4000,d7
                swap    d7
                move.l  d7,(a5)
                lea     (VDP_DATA).l,a5
Gfx_LoadDataToVRAM_WriteLoop:                           ; was: loc_26C6
                move.l  (a1)+,(a5)
                dbf     d1,Gfx_LoadDataToVRAM_WriteLoop
                move    (sp)+,sr
                tst.w   d0
                bne.s   Gfx_LoadDataToVRAM_BatchLoop
                rts
; End of function Gfx_LoadDataToVRAM
; Loads and decompresses tile data to destination buffer
Gfx_LoadAndDecompTiles:                                 ; was: sub_26D4
                movea.l (a0)+,a1
                moveq   #$FFFFFFFF,d1
                move.w  (a0)+,d1
                movea.l d1,a2
                moveq   #0,d1
                move.b  (a1),d1
                move.w  (a1)+,d3
                moveq   #8,d2
                ror.w   d2,d3
                move.w  d2,(DataLoaderCodecState).w
                move.w  d3,(DataLoaderCodecState+2).w
                bsr.w   TileCodec_ClearDecodeBuffer
Gfx_LoadAndDecompTiles_Loop:                            ; was: loc_26F2
                bsr.w   TileCodec_DecodeTile
                bsr.w   TileCodec_PackDecodedTile
                dbf     d1,Gfx_LoadAndDecompTiles_Loop
                rts
; End of function Gfx_LoadAndDecompTiles
; Loads and decompresses graphics data by processing header info and calling decompression subroutines
Gfx_LoadCompressedGfx:                                  ; was: sub_2700
                movea.l (a0)+,a1
                moveq   #$FFFFFFFF,d1
                move.w  (a0)+,d1
                movea.l d1,a3
                moveq   #0,d1
                move.b  (a1),d1
                move.w  (a1)+,d3
                moveq   #8,d2
                ror.w   d2,d3
                move.w  d2,(DataLoaderCodecState).w
                move.w  d3,(DataLoaderCodecState+2).w
                bsr.w   TileCodec_ClearDecodeBuffer
; Loop that repeatedly calls decompression functions to process graphics data tiles
Gfx_DecompLoop:                                         ; was: loc_271E
                bsr.w   TileCodec_DecodeTile
                bsr.w   TileCodec_WriteDecodedTileToVRAM
                dbf     d1,Gfx_DecompLoop
                rts
; End of function Gfx_LoadCompressedGfx
; Decompresses LZSS blocks straight into a RAM destination
LoadCompressedToRAM:                                    ; was: LoadCompressedTiles
                movea.l (a0)+,a1
                moveq   #0,d0
                move.w  (a1)+,d0
                movea.l a1,a4
                adda.l  d0,a4
                moveq   #$FFFFFFFF,d0
                move.w  (a0)+,d0
                movea.l d0,a2
; Loop that decompresses multiple LZSS-compressed data blocks sequentially until reaching end address
LoadCompressedToRAM_BlockLoop:                          ; was: loc_273C
                bsr.w   Data_LZSSDecomp
                cmpa.l  a4,a1
                bcs.s   LoadCompressedToRAM_BlockLoop
                rts
; End of function LoadCompressedToRAM

; Decompresses LZSS through the staging buffer and writes $400-byte blocks to VRAM
LoadCompressedToVRAM:                                   ; was: LoadCompressedMappings
                movea.l (a0)+,a1
                moveq   #0,d0
                move.w  (a1)+,d0
                movea.l a1,a4
                adda.l  d0,a4
                moveq   #0,d0
                move.w  (a0)+,d0
                movea.l d0,a3
LoadCompressedToVRAM_BlockLoop:                         ; was: loc_2756
                lea     (GraphicsStagingBuffer).w,a2
                bsr.w   Data_LZSSDecomp
                cmpa.l  a4,a1
                bcc.w   LoadCompressedToVRAM_FinalBlock
                move.w  #$FF,d1
                lea     (GraphicsStagingBuffer).w,a2
                lea     (VDP_CTRL).l,a5
                move    sr,-(sp)
                move    #$2700,sr
                move.w  #$8F02,(a5)
                move.l  a3,d2
                lsl.l   #2,d2
                lsr.w   #2,d2
                ori.w   #$4000,d2
                swap    d2
                move.l  d2,(a5)
                lea     (VDP_DATA).l,a5
LoadCompressedToVRAM_WriteFullBlock:                    ; was: loc_2790
                move.l  (a2)+,(a5)
                dbf     d1,LoadCompressedToVRAM_WriteFullBlock
                move    (sp)+,sr
                lea     $400(a3),a3
                bra.s   LoadCompressedToVRAM_BlockLoop
; ---------------------------------------------------------------------------
LoadCompressedToVRAM_FinalBlock:                        ; was: loc_279E
                move.w  a2,d1
                subi.w  #$B400,d1
                lsr.w   #1,d1
                lea     (GraphicsStagingBuffer).w,a2
                lea     (VDP_CTRL).l,a5
                move    sr,-(sp)
                move    #$2700,sr
                move.w  #$8F02,(a5)
                move.l  a3,d2
                lsl.l   #2,d2
                lsr.w   #2,d2
                ori.w   #$4000,d2
                swap    d2
                move.l  d2,(a5)
                lea     (VDP_DATA).l,a5
LoadCompressedToVRAM_WriteFinalBlock:                   ; was: loc_27CE
                move.w  (a2)+,(a5)
                dbf     d1,LoadCompressedToVRAM_WriteFinalBlock
                move    (sp)+,sr
                rts
; End of function LoadCompressedToVRAM

; Processes data pointers with state bits
Data_ProcessPointer:                                    ; was: sub_27D8
                                        ; StoryScreen_FadeOutAndLoadTitleAssets+3C   p
                move.w  (a0)+,d0
                bmi.w   Data_ProcessPointer_Return
                bset    #$F,d0
                move.w  d0,(DataLoaderControl).w
                movea.l (a0)+,a1
                btst    #0,d0
                bne.w   Data_ProcessPointer_ReadWordLength
                moveq   #$FFFFFFFF,d1
                move.w  (a0)+,d1
                move.l  d1,(DataLoaderDestination).w
                move.l  a0,(DataLoaderRecordPtr).w
                btst    #1,d0
                beq.w   Data_ProcessPointer_StoreRawLength
                btst    #2,d0
                bne.w   Data_ProcessPointer_StoreEndPointer
Data_ProcessPointer_ReadCompressedHeader:               ; was: loc_280C
                moveq   #0,d1
                move.b  (a1),d1
                addq.w  #1,d1
                move.w  d1,(DataLoaderLength).w
                move.w  #8,d2
                move.w  d2,(DataLoaderCodecState).w
                move.w  (a1)+,d3
                ror.w   d2,d3
                move.w  d3,(DataLoaderCodecState+2).w
                move.l  a1,(DataLoaderSourcePtr).w
                bra.w   TileCodec_ClearDecodeBuffer
; ---------------------------------------------------------------------------
Data_ProcessPointer_ReadWordLength:                     ; was: loc_282E
                moveq   #0,d1
                move.w  (a0)+,d1
                move.l  d1,(DataLoaderDestination).w
                move.l  a0,(DataLoaderRecordPtr).w
                btst    #1,d0
                beq.w   Data_ProcessPointer_StoreRawLength
                btst    #2,d0
                beq.s   Data_ProcessPointer_ReadCompressedHeader
                bra.w   Data_ProcessPointer_StoreEndPointer
; ---------------------------------------------------------------------------
Data_ProcessPointer_StoreRawLength:                     ; was: loc_284C
                                        ; Data_ProcessPointer+66   j
                move.w  (a1)+,(DataLoaderLength).w
                move.l  a1,(DataLoaderSourcePtr).w
                rts
; ---------------------------------------------------------------------------
Data_ProcessPointer_StoreEndPointer:                    ; was: loc_2856
                                        ; Data_ProcessPointer+70   j
                moveq   #0,d1
                move.w  (a1)+,d1
                move.l  a1,(DataLoaderSourcePtr).w
                adda.l  d1,a1
                move.l  a1,(DataLoaderCodecState).w
Data_ProcessPointer_Return:                             ; was: locret_2864
                rts
; End of function Data_ProcessPointer
; Dispatches data loading operations by calling function pointers from jump table until $FFFF terminator
Sys_DispatchDataLoader:                                 ; was: sub_2866
                move.w  (DataLoaderControl).w,d0
                beq.w   Sys_DispatchDataLoader_Return
                movea.l (DataLoaderRecordPtr).w,a0
Sys_DispatchDataLoader_Loop:                            ; was: loc_2872
                add.w   d0,d0
                add.w   d0,d0
                movea.l Sys_DataLoaderHandlers(pc,d0.w),a3
                jsr     (a3)
                bsr.w   Data_ProcessPointer
                cmpi.w  #$FFFF,d0
                bne.s   Sys_DispatchDataLoader_Loop
                clr.w   (DataLoaderControl).w
Sys_DispatchDataLoader_Return:                          ; was: locret_288A
                rts
; End of function Sys_DispatchDataLoader
; ---------------------------------------------------------------------------
Sys_DataLoaderHandlers: dc.l    Data_CopyToRAM          ; was: off_288C
                dc.l    Gfx_DMATransferWithWait
                dc.l    Gfx_DecompTilesToRAM
                dc.l    Gfx_DecompTilesToVRAMBatched
                dc.l    Data_CopyToRAM
                dc.l    Gfx_DMATransferWithWait
                dc.l    Data_DecompressLZSSDirect
                dc.l    Gfx_DecompressLZSSToVRAMBatched

; Copies data from source to destination in RAM
Data_CopyToRAM:                                         ; was: sub_28AC
                                        ; ROM:0000289C   o
                movea.l (DataLoaderSourcePtr).w,a1
                movea.l (DataLoaderDestination).w,a2
                move.w  (DataLoaderLength).w,d1
Data_CopyToRAM_Loop:                                    ; was: loc_28B8
                move.l  (a1)+,(a2)+
                move.l  (a1)+,(a2)+
                subq.w  #8,d1
                bhi.s   Data_CopyToRAM_Loop
                rts
; End of function Data_CopyToRAM
; Performs DMA transfer with VBlank wait loop
Gfx_DMATransferWithWait:                                ; was: sub_28C2
                                        ; ROM:000028A0   o
                movea.l (DataLoaderSourcePtr).w,a2
                movea.w (DataLoaderDestination).w,a3
                move.w  (DataLoaderLength).w,d0
Gfx_DMATransferWithWait_BatchLoop:                      ; was: loc_28CE
                move.w  #$200,d1
                cmp.w   d1,d0
                bge.w   Gfx_DMATransferWithWait_ExecuteBatch
                move.w  d0,d1
Gfx_DMATransferWithWait_ExecuteBatch:                   ; was: loc_28DA
                bsr.w   Gfx_QueueDMATransferAndAdvance
Gfx_DMATransferWithWait_Wait:                           ; was: loc_28DE
                tst.b   (VDPTransferPending).w
                bne.s   Gfx_DMATransferWithWait_Wait
                sub.w   d1,d0
                bne.s   Gfx_DMATransferWithWait_BatchLoop
                rts
; End of function Gfx_DMATransferWithWait
; Decompresses tiles to RAM buffer
Gfx_DecompTilesToRAM:                                   ; was: sub_28EA
                movea.l (DataLoaderSourcePtr).w,a1
                movea.l (DataLoaderDestination).w,a2
                move.w  (DataLoaderLength).w,d0
                subq.w  #1,d0
Gfx_DecompTilesToRAM_Loop:                              ; was: loc_28F8
                bsr.w   TileCodec_DecodeTile
                bsr.w   TileCodec_PackDecodedTile
                dbf     d0,Gfx_DecompTilesToRAM_Loop
                rts
; End of function Gfx_DecompTilesToRAM
; Decompresses tiles to VRAM in batched DMA transfers
Gfx_DecompTilesToVRAMBatched:                           ; was: sub_2906
                movea.l (DataLoaderSourcePtr).w,a1
                movea.l (DataLoaderDestination).w,a3
                move.w  (DataLoaderLength).w,d0
Gfx_DecompTilesToVRAMBatched_BatchLoop:                 ; was: loc_2912
                lea     (TileDMABatchBuffer).w,a2
                move.w  #$10,d2
                cmp.w   d2,d0
                bge.w   Gfx_DecompTilesToVRAMBatched_PrepareBatch
                move.w  d0,d2
Gfx_DecompTilesToVRAMBatched_PrepareBatch:              ; was: loc_2922
                move.w  d2,d1
                asl.w   #5,d1
                sub.w   d2,d0
                subq.w  #1,d2
Gfx_DecompTilesToVRAMBatched_DecodeLoop:                ; was: loc_292A
                bsr.w   TileCodec_DecodeTile
                bsr.w   TileCodec_PackDecodedTile
                dbf     d2,Gfx_DecompTilesToVRAMBatched_DecodeLoop
                tst.w   d0
                beq.w   Gfx_DecompTilesToVRAMBatched_FinalBatch
                lea     (TileDMABatchBuffer).w,a2
                bsr.w   Gfx_QueueDMATransferAndAdvance
Gfx_DecompTilesToVRAMBatched_WaitBatch:                 ; was: loc_2944
                tst.b   (VDPTransferPending).w
                bne.s   Gfx_DecompTilesToVRAMBatched_WaitBatch
                bra.s   Gfx_DecompTilesToVRAMBatched_BatchLoop
; ---------------------------------------------------------------------------
Gfx_DecompTilesToVRAMBatched_FinalBatch:                ; was: loc_294C
                lea     (TileDMABatchBuffer).w,a2
                bsr.w   Gfx_QueueDMATransferAndAdvance
Gfx_DecompTilesToVRAMBatched_WaitFinal:                 ; was: loc_2954
                tst.b   (VDPTransferPending).w
                bne.s   Gfx_DecompTilesToVRAMBatched_WaitFinal
                rts
; End of function Gfx_DecompTilesToVRAMBatched
; Decompresses LZSS blocks directly to the configured memory destination
Data_DecompressLZSSDirect:                              ; was: sub_295C
                movea.l (DataLoaderSourcePtr).w,a1
                movea.l (DataLoaderDestination).w,a2
                movea.l (DataLoaderCodecState).w,a4
; Repeats direct LZSS decompression until the source end is reached
Data_DecompressLZSSDirect_BlockLoop:                    ; was: loc_2968
                bsr.w   Data_LZSSDecomp
                cmpa.l  a4,a1
                bcs.s   Data_DecompressLZSSDirect_BlockLoop
                rts
; End of function Data_DecompressLZSSDirect
; Decompresses LZSS through a RAM staging buffer and DMA-transfers it to VRAM
Gfx_DecompressLZSSToVRAMBatched:                        ; was: sub_2972
                movea.l (DataLoaderSourcePtr).w,a1
                movea.l (DataLoaderDestination).w,a3
                movea.l (DataLoaderCodecState).w,a4
Gfx_DecompressLZSSToVRAMBatched_BlockLoop:              ; was: loc_297E
                lea     (GraphicsStagingBuffer).w,a2
                bsr.w   Data_LZSSDecomp
                cmpa.l  a4,a1
                bcc.w   Gfx_DecompressLZSSToVRAMBatched_FinalBlock
                move.w  #$400,d1
                lea     (GraphicsStagingBuffer).w,a2
                bsr.w   Gfx_QueueDMATransferAndAdvance
Gfx_DecompressLZSSToVRAMBatched_WaitBlock:              ; was: loc_2998
                tst.b   (VDPTransferPending).w
                bne.s   Gfx_DecompressLZSSToVRAMBatched_WaitBlock
                bra.s   Gfx_DecompressLZSSToVRAMBatched_BlockLoop
; ---------------------------------------------------------------------------
Gfx_DecompressLZSSToVRAMBatched_FinalBlock:             ; was: loc_29A0
                move.w  a2,d1
                subi.w  #$B400,d1
                lea     (GraphicsStagingBuffer).w,a2
                bsr.w   Gfx_QueueDMATransferAndAdvance
Gfx_DecompressLZSSToVRAMBatched_WaitFinal:              ; was: loc_29AE
                tst.b   (VDPTransferPending).w
                bne.s   Gfx_DecompressLZSSToVRAMBatched_WaitFinal
                rts
; End of function Gfx_DecompressLZSSToVRAMBatched
Data_LZSSDecomp:
                                        ; LoadCompressedToVRAM+14   p
                movem.l d4-d7/a5,-(sp)
                move.w  a2,d4
                addi.w  #$400,d4
Data_LZSSDecomp_BlockLoop:                              ; was: loc_29C0
                bsr.w   Data_LZSSDecodeBlock
                cmpa.l  a4,a1
                bcc.w   Data_LZSSDecomp_Return
                cmp.w   a2,d4
                bhi.s   Data_LZSSDecomp_BlockLoop
Data_LZSSDecomp_Return:                                 ; was: loc_29CE
                movem.l (sp)+,d4-d7/a5
                rts
; End of function Data_LZSSDecomp

; LZSS decoder that handles various compression block types including literal runs RLE and backreferences
Data_LZSSDecodeBlock:                                   ; was: sub_29D4
                move.b  (a1)+,d5
                bmi.w   Data_LZSSDecodeBlock_CopyBackReference
                btst    #5,d5
                bne.w   Data_LZSSDecodeBlock_FillByte
                btst    #6,d5
                beq.w   Data_LZSSDecodeBlock_CopyLiteral
                bra.w   Data_LZSSDecodeBlock_FillPair
; ---------------------------------------------------------------------------
Data_LZSSDecodeBlock_FillByte:                          ; was: loc_29EE
                btst    #6,d5
                bne.w   Data_LZSSDecodeBlock_FillMixedPair
                andi.w  #$1F,d5
                addq.w  #1,d5
                move.b  (a1)+,d6
Data_LZSSDecodeBlock_FillByteLoop:                      ; was: loc_29FE
                move.b  d6,(a2)+
                dbf     d5,Data_LZSSDecodeBlock_FillByteLoop
                rts
; ---------------------------------------------------------------------------
Data_LZSSDecodeBlock_FillPair:                          ; was: loc_2A06
                andi.w  #$1F,d5
                addq.w  #1,d5
                move.b  (a1)+,d6
                move.b  (a1)+,d7
Data_LZSSDecodeBlock_FillPairLoop:                      ; was: loc_2A10
                move.b  d6,(a2)+
                move.b  d7,(a2)+
                dbf     d5,Data_LZSSDecodeBlock_FillPairLoop
                rts
; ---------------------------------------------------------------------------
Data_LZSSDecodeBlock_FillMixedPair:                     ; was: loc_2A1A
                andi.w  #$1F,d5
                addq.w  #1,d5
                move.b  (a1)+,d6
Data_LZSSDecodeBlock_FillMixedPairLoop:                 ; was: loc_2A22
                move.b  d6,(a2)+
                move.b  (a1)+,(a2)+
                dbf     d5,Data_LZSSDecodeBlock_FillMixedPairLoop
                rts
; ---------------------------------------------------------------------------
Data_LZSSDecodeBlock_CopyBackReference:                 ; was: loc_2A2C
                move.b  d5,d6
                lsr.b   #2,d5
                andi.w  #$1F,d5
                addq.w  #1,d5
                lsl.w   #8,d6
                move.b  (a1)+,d6
                andi.w  #$3FF,d6
                addq.w  #1,d6
                movea.l a2,a5
                suba.w  d6,a5
Data_LZSSDecodeBlock_CopyBackReferenceLoop:             ; was: loc_2A44
                move.b  (a5)+,(a2)+
                dbf     d5,Data_LZSSDecodeBlock_CopyBackReferenceLoop
                rts
; ---------------------------------------------------------------------------
Data_LZSSDecodeBlock_CopyLiteral:                       ; was: loc_2A4C
                andi.w  #$1F,d5
Data_LZSSDecodeBlock_CopyLiteralLoop:                   ; was: loc_2A50
                move.b  (a1)+,(a2)+
                dbf     d5,Data_LZSSDecodeBlock_CopyLiteralLoop
                rts
; End of function Data_LZSSDecodeBlock
