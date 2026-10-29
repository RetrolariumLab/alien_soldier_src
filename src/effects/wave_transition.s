; Builds and uploads one wave-distorted tilemap frame; no source caller is known
UnreferencedWave_RenderTilemapToVRAM:                   ; was: sub_261D8
                tst.w   (DataLoaderControl).w
                bne.w   UnreferencedWave_RenderTilemapToVRAM_Return
                bsr.w   Gfx_InitializeWaveParameters
UnreferencedWave_RenderTilemapToVRAM_BuildTileLoop:     ; was: loc_261E4
                bsr.w   Gfx_CalculateTileCoordinates
                bsr.w   Gfx_PrepareTilePointers
                bsr.w   Gfx_PixelBlendDispatcher
                lea     1(a4),a4
                move.w  a4,d0
                move.w  d0,d1
                andi.w  #3,d0
                asl.w   #3,d1
                andi.w  #$FFE0,d1
                or.w    d1,d0
                andi.l  #$FFFF,d0
                addi.l  #-$10000,d0
                movea.l d0,a2
                dbf     d7,UnreferencedWave_RenderTilemapToVRAM_BuildTileLoop
                movea.l #Gfx_WaveParameterTableD,a0
                move.w  (WaveParameterIndex).w,d0
                move.w  (a0,d0.w),d0
                move.w  #$1400,d1
                move.w  d0,d2
                rol.w   #2,d2
                andi.w  #3,d2
                swap    d0
                andi.l  #$3FFF0000,d0
                ori.l   #$40000000,d0
                move.w  d2,d0
                move    #$2700,sr
                lea     (VDP_DATA).l,a1
                lea     (VDP_CTRL).l,a2
                move.w  #$8F02,(a2)
                movea.l #M68K_RAM,a0
                move.l  d0,(a2)
UnreferencedWave_RenderTilemapToVRAM_TransferLongwordLoop:  ; was: loc_2625C
                move.l  (a0)+,(a1)
                dbf     d1,UnreferencedWave_RenderTilemapToVRAM_TransferLongwordLoop
                move    #$2300,sr
                addq.w  #2,(WaveParameterIndex).w
UnreferencedWave_RenderTilemapToVRAM_Return:            ; was: locret_2626A
                rts
; End of function UnreferencedWave_RenderTilemapToVRAM

; Initializes the wave-scroll state, control word, and Plane B offset
Effect_InitWaveScroll:                                  ; was: sub_2626C
                move.w  #2,(WaveControlWord).w
                move.w  #0,(WaveParameterIndex).w
                move.w  #0,(WaveStateOffset).w
                move.w  #$70,(VScrollPlaneBColumn0).w   ; 'p'
                rts
; End of function Effect_InitWaveScroll
; Stops scrolling effect by resetting state variables and counters
Stage_StopScrollEffect:                                 ; was: sub_26286
                move.b  #4,(VDPReg0Shadow+1).w
                move.b  #$30,(VDPReg2Shadow+1).w        ; '0'
                move.w  #0,(WaveControlWord).w
                move.w  #0,(VScrollPlaneBColumn0).w
                rts
; End of function Stage_StopScrollEffect
; Unreachable: would clear the output buffer and dispatch the six wave states
Orphaned_WaveController:
                bsr.w   Effect_ClearWaveOutputBuffer    ; was: sub_262A0
                movea.w (WaveStateOffset).w,a0
                movea.l Effect_WaveStateHandlers(pc,a0.w),a0
                jmp     (a0)
; End of function Orphaned_WaveController
; ---------------------------------------------------------------------------
Effect_WaveStateHandlers:   dc.l    Effect_WaveInitialize  ; was: off_262AE
                dc.l    Effect_WaveHoldState
                dc.l    Effect_WaveFadeOut
                dc.l    Effect_WaveLoopOrEnd
                dc.l    Effect_WaveWindDown
                dc.l    Gfx_ScrollEffectEmptyState

; Initializes wave effect by setting up buffer and incrementing counter
Effect_WaveInitialize:                                  ; was: sub_262C6
                movea.l #RasterSecondaryBuffer,a6
                bsr.w   Gfx_GenerateWaveDeformation
                bsr.w   Effect_WavePostUpdateNoOp
                addq.w  #2,(WaveParameterIndex).w
                cmpi.w  #$1C,(WaveParameterIndex).w
                bne.w   Effect_WaveInitialize_Return
                addq.w  #4,(WaveStateOffset).w
                move.w  #$78,(WaveStateTimer).w         ; 'x'
Effect_WaveInitialize_Return:                           ; was: locret_262EC
                rts
; End of function Effect_WaveInitialize
; Holds wave effect active state while waiting for timer countdown
Effect_WaveHoldState:                                   ; was: sub_262EE
                movea.l #RasterSecondaryBuffer,a6
                bsr.w   Gfx_GenerateWaveDeformation
                subq.w  #1,(WaveStateTimer).w
                bne.w   Effect_WaveHoldState_Return
                addq.w  #4,(WaveStateOffset).w
                move.w  #1,(WaveStateTimer).w
Effect_WaveHoldState_Return:                            ; was: locret_2630A
                rts
; End of function Effect_WaveHoldState
; Fades out wave effect by decrementing counter back to minimum value
Effect_WaveFadeOut:                                     ; was: sub_2630C
                movea.l #(RasterSecondaryBuffer+$40),a6
                bsr.w   Gfx_GenerateWaveDeformation
                subq.w  #2,(WaveParameterIndex).w
                cmpi.w  #6,(WaveParameterIndex).w
                bne.w   Effect_WaveFadeOut_Return
                addq.w  #4,(WaveStateOffset).w
Effect_WaveFadeOut_Return:                              ; was: locret_26328
                rts
; End of function Effect_WaveFadeOut
; Loops wave effect or ends it based on remaining iteration counter
Effect_WaveLoopOrEnd:                                   ; was: sub_2632A
                movea.l #ActiveRasterBuffer,a6
                bsr.w   Gfx_GenerateWaveDeformation
                addq.w  #2,(WaveParameterIndex).w
                cmpi.w  #$1C,(WaveParameterIndex).w
                bne.w   Effect_WaveLoopOrEnd_Return
                subq.w  #1,(WaveStateTimer).w
                bpl.w   Effect_WaveLoopOrEnd_Repeat
                addq.w  #4,(WaveStateOffset).w
                rts
; ---------------------------------------------------------------------------
Effect_WaveLoopOrEnd_Repeat:                            ; was: loc_26350
                subq.w  #4,(WaveStateOffset).w
Effect_WaveLoopOrEnd_Return:                            ; was: locret_26354
                rts
; End of function Effect_WaveLoopOrEnd
; Winds the wave parameter index down to zero and ends the effect
Effect_WaveWindDown:                                    ; was: sub_26356
                movea.l #ActiveRasterBuffer,a6
                bsr.w   Gfx_GenerateWaveDeformation
                bsr.w   Effect_WavePostUpdateNoOp
                subq.w  #2,(WaveParameterIndex).w
                bne.w   Effect_WaveWindDown_Return
                addq.w  #4,(WaveStateOffset).w
Effect_WaveWindDown_Return:                             ; was: locret_26370
                rts
; End of function Effect_WaveWindDown
; Empty scroll effect graphics state
Gfx_ScrollEffectEmptyState:                             ; was: nullsub_58
                rts
; End of function Gfx_ScrollEffectEmptyState
; Unreachable: a bare return with no reference of any kind
Orphaned_WaveNoOp:                                      ; was: nullsub_59
                rts
; End of function Orphaned_WaveNoOp

; Clears 81 longwords in the wave output buffer at $FFFF9800
Effect_ClearWaveOutputBuffer:                           ; was: sub_26376
                movea.l #WaveOutputBuffer,a0
                moveq   #0,d0
                move.w  #$50,d7                         ; 'P'
Effect_ClearWaveOutputBuffer_Loop:                      ; was: loc_26382
                move.l  d0,(a0)+
                dbf     d7,Effect_ClearWaveOutputBuffer_Loop
                rts
; End of function Effect_ClearWaveOutputBuffer
; Generates sine wave deformation tables for screen warping effect
Gfx_GenerateWaveDeformation:                            ; was: sub_2638A
                                        ; Effect_WaveHoldState+6   p
                move.b  #$14,(VDPReg0Shadow+1).w
                move.b  #0,(VDPReg10Shadow+1).w
                move.b  #$38,(VDPReg2Shadow+1).w        ; '8'
                move.w  (WaveParameterIndex).w,d0
                movea.l #Effect_WaveStepTable,a0
                move.w  (a0,d0.w),d0
                moveq   #0,d1
                moveq   #0,d2
                movea.l #WaveSineTableCenter,a0
                movea.l #WaveSineTableCenter,a1
                move.w  #$7F,d7
Gfx_GenerateWaveDeformation_FillSineLoop:               ; was: loc_263BE
                suba.w  #2,a0
                add.w   d0,d1
                move.w  d1,d6
                lsr.w   #8,d6
                move.w  d6,(a0)
                adda.w  #2,a1
                sub.w   d0,d2
                move.w  d2,d6
                lsr.w   #8,d6
                move.w  d6,(a1)
                dbf     d7,Gfx_GenerateWaveDeformation_FillSineLoop
                move.w  (WaveParameterIndex).w,d0
                movea.l #Effect_WaveStartOffsetTable,a0
                move.w  (a0,d0.w),d7
                movea.l #WaveOutputBuffer,a0
                adda.w  d0,a0
                movea.l a0,a1
                move.w  #$1C,d1
                sub.w   d0,d1
                addi.w  #$B,d1
                move.w  #3,d3
Gfx_GenerateWaveDeformation_FillColumns:                ; was: loc_26400
                move.w  d1,d2
Gfx_GenerateWaveDeformation_FillColumnLoop:             ; was: loc_26402
                move.w  d7,(a0)+
                addq.w  #1,d7
                dbf     d2,Gfx_GenerateWaveDeformation_FillColumnLoop
                adda.w  #$50,a1                         ; 'P'
                movea.l a1,a0
                dbf     d3,Gfx_GenerateWaveDeformation_FillColumns
                rts
; End of function Gfx_GenerateWaveDeformation
; ---------------------------------------------------------------------------
Effect_WaveStartOffsetTable:    dc.w    $85B8, $8520, $8490, $8408, $8388, $8310, $82A0, $8238, $81D8, $8180, $8130, $80E8, $80A8, $8070, $8040  ; was: word_26416
Effect_WaveStepTable:           dc.w    $E0, $D0, $C0, $B0, $A0, $90, $80, $70, $60, $50, $40, $30, $20, $10, 0  ; was: word_26434

; Calculates two tile coordinate pairs from wave deformation data
Gfx_CalculateTileCoordinates:                           ; was: sub_26452
                bsr.w   Math_WaveToTileIndex
                move.w  d0,d2
                bsr.w   Math_WaveToTileIndex
                move.w  d0,d3
                rts
; End of function Gfx_CalculateTileCoordinates
; Converts wave accumulator value to tile index with masking
Math_WaveToTileIndex:                                   ; was: sub_26460
                                        ; Gfx_CalculateTileCoordinates+6   p
                add.w   d6,d5
                move.w  d5,d0
                move.w  d5,d1
                asr.w   #8,d0
                andi.w  #7,d0
                asr.w   #8,d1
                andi.w  #$FFF8,d1
                or.w    d1,d0
                rts
; End of function Math_WaveToTileIndex
; Calculates tile buffer addresses and pixel offset from coordinates
Gfx_PrepareTilePointers:                                ; was: sub_26476
                asr.w   #1,d2
                bcs.w   Gfx_PrepareTilePointers_SelectFirstNibble
                moveq   #0,d0
                bra.w   Gfx_PrepareTilePointers_ComputeFirstPointer
; ---------------------------------------------------------------------------
Gfx_PrepareTilePointers_SelectFirstNibble:              ; was: loc_26482
                moveq   #4,d0
Gfx_PrepareTilePointers_ComputeFirstPointer:            ; was: loc_26484
                move.w  d2,d1
                andi.l  #3,d2
                asl.w   #3,d1
                andi.w  #$FFE0,d1
                or.w    d1,d2
                addi.l  #SegaScreenTileArt,d2
                movea.l d2,a0
                asr.w   #1,d3
                bcs.w   Gfx_PrepareTilePointers_ComputeSecondPointer
                addq.w  #8,d0
Gfx_PrepareTilePointers_ComputeSecondPointer:           ; was: loc_264A4
                move.w  d3,d1
                andi.l  #3,d3
                asl.w   #3,d1
                andi.w  #$FFE0,d1
                or.w    d1,d3
                addi.l  #SegaScreenTileArt,d3
                movea.l d3,a1
                rts
; End of function Gfx_PrepareTilePointers
; Dispatches to pixel blending routine based on alignment offset
Gfx_PixelBlendDispatcher:                               ; was: sub_264BE
                move.w  #3,d2
                movea.w d0,a3
                movea.l Gfx_PixelBlendHandlers(pc,a3.w),a3
                jmp     (a3)
; End of function Gfx_PixelBlendDispatcher
; ---------------------------------------------------------------------------
Gfx_PixelBlendHandlers: dc.l    Gfx_BlendPixelsHighNibble  ; was: off_264CA
                dc.l    Gfx_BlendPixelsShiftedHigh
                dc.l    Gfx_BlendPixelsHighAndShifted
                dc.l    Gfx_BlendPixelsFullyShifted

; Blends pixels preserving high nibble from first source
Gfx_BlendPixelsHighNibble:                              ; was: sub_264DA
                move.w  #7,d3
Gfx_BlendPixelsHighNibble_Loop:                         ; was: loc_264DE
                move.b  (a0),d0
                andi.w  #$F0,d0
                move.b  (a1),d1
                andi.w  #$F,d1
                or.w    d1,d0
                move.b  d0,(a2)
                lea     4(a0),a0
                lea     4(a1),a1
                lea     4(a2),a2
                dbf     d3,Gfx_BlendPixelsHighNibble_Loop
                adda.l  #$160,a0
                adda.l  #$160,a1
                adda.w  d4,a2
                dbf     d2,Gfx_BlendPixelsHighNibble
                rts
; End of function Gfx_BlendPixelsHighNibble
; Blends pixels with first source shifted to high nibble
Gfx_BlendPixelsShiftedHigh:                             ; was: sub_26512
                move.w  #7,d3
Gfx_BlendPixelsShiftedHigh_Loop:                        ; was: loc_26516
                move.b  (a0),d0
                asl.w   #4,d0
                move.b  (a1),d1
                andi.w  #$F,d1
                or.w    d1,d0
                move.b  d0,(a2)
                lea     4(a0),a0
                lea     4(a1),a1
                lea     4(a2),a2
                dbf     d3,Gfx_BlendPixelsShiftedHigh_Loop
                adda.l  #$160,a0
                adda.l  #$160,a1
                adda.w  d4,a2
                dbf     d2,Gfx_BlendPixelsShiftedHigh
                rts
; End of function Gfx_BlendPixelsShiftedHigh
; Blends pixels with high nibble and shifted low nibble
Gfx_BlendPixelsHighAndShifted:                          ; was: sub_26548
                move.w  #7,d3
Gfx_BlendPixelsHighAndShifted_Loop:                     ; was: loc_2654C
                move.b  (a0),d0
                andi.w  #$F0,d0
                move.b  (a1),d1
                lsr.w   #4,d1
                andi.w  #$F,d1
                or.w    d1,d0
                move.b  d0,(a2)
                lea     4(a0),a0
                lea     4(a1),a1
                lea     4(a2),a2
                dbf     d3,Gfx_BlendPixelsHighAndShifted_Loop
                adda.l  #$160,a0
                adda.l  #$160,a1
                adda.w  d4,a2
                dbf     d2,Gfx_BlendPixelsHighAndShifted
                rts
; End of function Gfx_BlendPixelsHighAndShifted
; Blends pixels with both sources shifted and combined
Gfx_BlendPixelsFullyShifted:                            ; was: sub_26582
                move.w  #7,d3
Gfx_BlendPixelsFullyShifted_Loop:                       ; was: loc_26586
                move.b  (a0),d0
                asl.w   #4,d0
                move.b  (a1),d1
                lsr.w   #4,d1
                andi.w  #$F,d1
                or.w    d1,d0
                move.b  d0,(a2)
                lea     4(a0),a0
                lea     4(a1),a1
                lea     4(a2),a2
                dbf     d3,Gfx_BlendPixelsFullyShifted_Loop
                adda.l  #$160,a0
                adda.l  #$160,a1
                adda.w  d4,a2
                dbf     d2,Gfx_BlendPixelsFullyShifted
                rts
; End of function Gfx_BlendPixelsFullyShifted
; Initializes wave deformation parameters from lookup tables
Gfx_InitializeWaveParameters:                           ; was: sub_265BA
                move.w  (WaveParameterIndex).w,d0
                moveq   #0,d5
                movea.l #M68K_RAM,a2
                movea.w #0,a4
                movea.l #Gfx_WaveParameterTableA,a0
                move.w  (a0,d0.w),d6
                sub.w   d6,d5
                movea.l #Gfx_WaveParameterTableB,a0
                move.w  (a0,d0.w),d4
                movea.l #Gfx_WaveParameterTableC,a0
                move.w  (a0,d0.w),d7
                rts
; End of function Gfx_InitializeWaveParameters
; ---------------------------------------------------------------------------
Gfx_WaveParameterTableA:    dc.w    $DB, $C0, $AA, $99, $8B, $80, $76, $6D, $66, $60, $5A, $55, $50, $4C  ; was: word_265EC
Gfx_WaveParameterTableB:    dc.w    $1A0, $1E0, $220, $260, $2A0, $2E0, $320, $360, $3A0, $3E0, $420, $460, $4A0, $4E0  ; was: word_26608
Gfx_WaveParameterTableC:    dc.w    $37, $3F, $47, $4F, $57, $5F, $67, $6F, $77, $7F, $87, $8F, $97, $9F  ; was: word_26624
Gfx_WaveParameterTableD:    dc.w    $E00, $1500, $1D00, $2600, $3000, $3B00, $4700, $5400, $6200, $7100, $8100, $9200, $A400, $B700  ; was: word_26640

Effect_WavePostUpdateNoOp:                              ; was: nullsub_57
                                        ; Effect_WaveWindDown+A   p
                rts
; End of function Effect_WavePostUpdateNoOp
; ---------------------------------------------------------------------------
Gfx_UnusedWaveTileData: binclude "data/other/unused_6.bin"  ; was: unused_6

; Main loop for loading tiles to VRAM
Gfx_LoadTilesLoop:                                      ; was: sub_2667C
                                        ; Stage_LoadStage13Assets+2C   j
                move.w  #1,(a0)
                move.w  #$20,(TileInterpSpan).w         ; ' '
Gfx_LoadTilesLoop_NextStep:                             ; was: loc_26686
                movea.w #(TileInterpolationBlockA-M68K_RAM),a5
                move.l  #$8000,d0
                divs.w  (TileInterpSpan).w,d0
                andi.l  #$FFFF,d0
                asl.l   #5,d0
                move.l  d0,d1
                asl.l   #3,d1
                clr.l   d2
                bsr.w   Gfx_ClearInterpolationTileBuffer
Gfx_LoadTilesLoop_Interpolate:                          ; was: loc_266A6
                bsr.w   Gfx_InterpolateCompressedTiles
                cmpi.l  #$100000,d2
                bmi.w   Gfx_LoadTilesLoop_Interpolate
                bsr.w   Gfx_TileLoadDispatcher
                move.w  (TileInterpSpanStep).w,d7
                sub.w   d7,(TileInterpSpan).w
                subq.w  #1,(TileInterpStepsLeft).w
                bpl.w   Gfx_LoadTilesLoop_NextStep
                rts
; End of function Gfx_LoadTilesLoop
; Decompresses and loads tiles with interpolation into tile buffer
Gfx_DecompressTilesInterpolated:
                move.w  #1,(a0)                         ; was: sub_266CA
                movea.w #(TileInterpolationBlockA-M68K_RAM),a5
                move.l  #$8000,d0
                divs.w  (TileInterpSpan).w,d0
                andi.l  #$FFFF,d0
                asl.l   #5,d0
                move.l  d0,d1
                asl.l   #3,d1
                clr.l   d2
                bsr.w   Gfx_ClearInterpolationTileBuffer
Gfx_DecompressTilesInterpolated_Loop:                   ; was: loc_266EE
                bsr.w   Gfx_InterpolateCompressedTiles
                cmpi.l  #$100000,d2
                bmi.w   Gfx_DecompressTilesInterpolated_Loop
                bra.w   Gfx_TileLoadDispatcher
; End of function Gfx_DecompressTilesInterpolated
; Interpolates between two compressed tile patterns for morphing effects
Gfx_InterpolateCompressedTiles:                         ; was: sub_26700
                                        ; sub_266CA:Gfx_DecompressTilesInterpolated_Loop   p
                movea.w a1,a2
                movea.w a1,a3
                movea.w a5,a4
                addq.w  #2,a4
                clr.l   d5
                clr.w   d7
                cmpi.w  #$8000,d2
                bmi.w   Gfx_InterpolateCompressedTiles_SelectFirstSource
                addq.w  #1,d7
Gfx_InterpolateCompressedTiles_SelectFirstSource:       ; was: loc_26716
                move.l  d2,d6
                swap    d6
                andi.w  #$FFFC,d6
                asl.w   #5,d6
                adda.w  d6,a2
                move.w  a2,(TileInterpReadBaseA).w
                move.l  d2,d3
                swap    d3
                andi.w  #3,d3
                add.l   d0,d2
                cmpi.l  #$100000,d2
                bmi.w   Gfx_InterpolateCompressedTiles_ClampPosition
                move.l  #$FFFFF,d2
Gfx_InterpolateCompressedTiles_ClampPosition:           ; was: loc_26740
                cmpi.w  #$8000,d2
                bpl.w   Gfx_InterpolateCompressedTiles_SelectSecondSource
                addq.w  #2,d7
Gfx_InterpolateCompressedTiles_SelectSecondSource:      ; was: loc_2674A
                move.l  d2,d6
                swap    d6
                andi.w  #$FFFC,d6
                asl.w   #5,d6
                adda.w  d6,a3
                move.w  a3,(TileInterpReadBaseB).w
                move.l  d2,d4
                swap    d4
                andi.w  #3,d4
                add.l   d0,d2
                movem.l d0-d2,-(sp)
Gfx_InterpolateCompressedTiles_PixelLoop:               ; was: loc_26768
                move.b  (a2,d3.w),d0
                btst    #0,d7
                beq.w   Gfx_InterpolateCompressedTiles_AlignFirstNibble
                asl.b   #4,d0
Gfx_InterpolateCompressedTiles_AlignFirstNibble:        ; was: loc_26776
                andi.b  #$F0,d0
                move.b  (a3,d4.w),d2
                btst    #1,d7
                beq.w   Gfx_InterpolateCompressedTiles_AlignSecondNibble
                asr.b   #4,d2
Gfx_InterpolateCompressedTiles_AlignSecondNibble:       ; was: loc_26788
                andi.b  #$F,d2
                or.b    d0,d2
                move.b  d2,(a4)
                add.l   d1,d5
                move.l  d5,d0
                swap    d0
                andi.w  #$FFFC,d0
                movea.w d0,a2
                movea.w d0,a3
                adda.w  (TileInterpReadBaseA).w,a2
                adda.w  (TileInterpReadBaseB).w,a3
                addq.w  #4,a4
                cmpi.l  #$800000,d5
                bmi.w   Gfx_InterpolateCompressedTiles_PixelLoop
                addq.w  #1,a5
                move.w  a5,d7
                andi.w  #3,d7
                bne.w   Gfx_InterpolateCompressedTiles_RestoreState
                subq.w  #4,a5
                adda.w  #$80,a5
Gfx_InterpolateCompressedTiles_RestoreState:            ; was: loc_267C4
                movem.l (sp)+,d0-d2
                rts
; End of function Gfx_InterpolateCompressedTiles
; Dispatches tile loading based on count
Gfx_TileLoadDispatcher:                                 ; was: sub_267CA
                                        ; Gfx_DecompressTilesInterpolated+32   j
                cmpi.w  #$19,(TileInterpSpan).w
                bpl.w   Gfx_TileLoadDispatcher_LargeBlock
                cmpi.w  #$11,(TileInterpSpan).w
                bpl.w   Gfx_TileLoadDispatcher_ThreeBlocks
                cmpi.w  #9,(TileInterpSpan).w
                bpl.w   Gfx_TileLoadDispatcher_TwoBlocks
                move.w  #$20,(TileInterpolationBlockA).w  ; ' '
                move.w  #$FFFF,2(a0)
                move.w  #$9800,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                move.w  #$FFFF,8(a0)
                addi.w  #$20,(TileInterpVRAM).w         ; ' '
                bra.w   Gfx_LoadObjectData
; ---------------------------------------------------------------------------
Gfx_TileLoadDispatcher_TwoBlocks:                       ; was: loc_26810
                move.w  #$40,(TileInterpolationBlockA).w  ; '@'
                move.w  #$FFFF,2(a0)
                move.w  #$9800,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                move.w  #$FFFF,8(a0)
                addi.w  #$40,(TileInterpVRAM).w         ; '@'
                bsr.w   Gfx_LoadObjectData
                move.w  #$40,(TileInterpolationBlockB).w  ; '@'
                move.w  #$9880,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                addi.w  #$40,(TileInterpVRAM).w         ; '@'
                bra.w   Gfx_LoadObjectData
; ---------------------------------------------------------------------------
Gfx_TileLoadDispatcher_ThreeBlocks:                     ; was: loc_26854
                move.w  #$60,(TileInterpolationBlockA).w  ; '`'
                move.w  #$FFFF,2(a0)
                move.w  #$9800,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                move.w  #$FFFF,8(a0)
                addi.w  #$60,(TileInterpVRAM).w         ; '`'
                bsr.w   Gfx_LoadObjectData
                move.w  #$60,(TileInterpolationBlockB).w  ; '`'
                move.w  #$9880,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                addi.w  #$60,(TileInterpVRAM).w         ; '`'
                bsr.w   Gfx_LoadObjectData
                move.w  #$60,(TileInterpolationBlockC).w  ; '`'
                move.w  #$9900,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                addi.w  #$60,(TileInterpVRAM).w         ; '`'
                bra.w   Gfx_LoadObjectData
; ---------------------------------------------------------------------------
Gfx_TileLoadDispatcher_LargeBlock:                      ; was: loc_268B4
                move.w  #$200,(TileInterpolationBlockA).w
                move.w  #$FFFF,2(a0)
                move.w  #$9800,4(a0)
                move.w  (TileInterpVRAM).w,6(a0)
                move.w  #$FFFF,8(a0)
                addi.w  #$200,(TileInterpVRAM).w
; End of function Gfx_TileLoadDispatcher
; Loads object data wrapper
Gfx_LoadObjectData:                                     ; was: sub_268D8
                                        ; Gfx_TileLoadDispatcher+6A   p
                movem.l d0-d2/a0-a5,-(sp)
                jsr     (LoadObjData).l
                movem.l (sp)+,d0-d2/a0-a5
                rts
; End of function Gfx_LoadObjectData
; Clears 128 longwords in the interpolation tile buffer
Gfx_ClearInterpolationTileBuffer:                       ; was: sub_268E8
                                        ; Gfx_DecompressTilesInterpolated+20   p
                movea.w #(TileInterpolationBlockA-M68K_RAM),a3
                moveq   #0,d6
                move.w  #$7F,d7
Gfx_ClearInterpolationTileBuffer_Loop:                  ; was: loc_268F2
                move.l  d6,(a3)+
                dbf     d7,Gfx_ClearInterpolationTileBuffer_Loop
                rts
; End of function Gfx_ClearInterpolationTileBuffer
