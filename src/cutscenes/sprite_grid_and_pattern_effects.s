; Updates the vertical positions of both star-object rows
Cutscene_UpdateStarRowPositions:                        ; was: sub_7644
                                        ; Cutscene_CollapseStarRows+6   p
                lea     (PrimaryEntityYPos).w,a5
                move.w  #$9C,d0
                sub.w   (StarRowSeparation).l,d0
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  #$C4,d0
                add.w   (StarRowSeparation).l,d0
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  d0,(a5)
                adda.w  #$60,a5                         ; '`'
                move.w  d0,(a5)
                rts
; End of function Cutscene_UpdateStarRowPositions
; Copies the planet object's Y/X coordinates into the generic grid center
Cutscene_CopyPlanetGridCenter:                          ; was: sub_768A
                                        ; sub_5244   p
                move.w  (EleventhEntityYPos).w,(SpriteGridCenterY).l
                move.w  (EleventhEntityXPos).w,(SpriteGridCenterX).l
; End of function Cutscene_CopyPlanetGridCenter
; Builds a centered planet sprite grid and appends it to the OAM buffer
Cutscene_RenderPlanetSpriteGrid:                        ; was: sub_769A
                                        ; EndingPlanet_RevealPattern+8   p
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                movea.w #(SharedSpriteScratch-M68K_RAM),a1
                clr.w   d5
                move.w  (SpriteGridRowLimit).l,d3
Cutscene_CalculatePlanetGridTop:                        ; was: loc_76AA
                subi.w  #$20,d5                         ; ' '
                dbf     d3,Cutscene_CalculatePlanetGridTop
                asr.w   #1,d5
                add.w   (SpriteGridCenterY).l,d5
                clr.w   d6
                move.w  (SpriteGridColumnLimit).l,d2
Cutscene_CalculatePlanetGridLeft:                       ; was: loc_76C2
                subi.w  #$20,d6                         ; ' '
                dbf     d2,Cutscene_CalculatePlanetGridLeft
                asr.w   #1,d6
                add.w   (SpriteGridCenterX).l,d6
                move.w  (SpriteGridFirstTile).l,d4
                move.w  (SpriteGridRowLimit).l,d3
                move.w  d5,d0
Cutscene_NextPlanetGridRow:                             ; was: loc_76E0
                move.w  (SpriteGridColumnLimit).l,d2
                move.w  d6,d1
Cutscene_WritePlanetGridCell:                           ; was: loc_76E8
                move.w  d0,(a1)+
                move.w  #$F00,(a1)+
                move.w  d4,(a1)+
                move.w  d1,(a1)+
                addi.w  #$20,d1                         ; ' '
                dbf     d2,Cutscene_WritePlanetGridCell
                addi.w  #$20,d0                         ; ' '
                dbf     d3,Cutscene_NextPlanetGridRow
                move.w  #$FFFF,(a1)
                jmp     (Sprite_AppendOAMEntries).l
; End of function Cutscene_RenderPlanetSpriteGrid
; Copies the ship center, builds its sprite grid, and appends it to OAM
Cutscene_RenderShipSpriteGrid:                          ; was: sub_770C
                                        ; sub_549C   p
                move.w  (TwelfthEntityYPos).w,(ShipGridCenterY).l
                move.w  (TwelfthEntityXPos).w,(ShipGridCenterX).l
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                movea.w #(SharedSpriteScratch-M68K_RAM),a1
                clr.w   d5
                move.w  (ShipGridRowLimit).l,d3
Cutscene_CalculateShipGridTop:                          ; was: loc_772C
                subi.w  #$20,d5                         ; ' '
                dbf     d3,Cutscene_CalculateShipGridTop
                asr.w   #1,d5
                add.w   (ShipGridCenterY).l,d5
                clr.w   d6
                move.w  (ShipGridColumnLimit).l,d2
Cutscene_CalculateShipGridLeft:                         ; was: loc_7744
                subi.w  #$20,d6                         ; ' '
                dbf     d2,Cutscene_CalculateShipGridLeft
                asr.w   #1,d6
                add.w   (ShipGridCenterX).l,d6
                move.w  (ShipGridFirstTile).l,d4
                move.w  (ShipGridRowLimit).l,d3
                move.w  d5,d0
Cutscene_NextShipGridRow:                               ; was: loc_7762
                move.w  (ShipGridColumnLimit).l,d2
                move.w  d6,d1
Cutscene_WriteShipGridCell:                             ; was: loc_776A
                move.w  d0,(a1)+
                move.w  #$F00,(a1)+
                move.w  d4,(a1)+
                move.w  d1,(a1)+
                addi.w  #$20,d1                         ; ' '
                dbf     d2,Cutscene_WriteShipGridCell
                addi.w  #$20,d0                         ; ' '
                dbf     d3,Cutscene_NextShipGridRow
                move.w  #$FFFF,(a1)
                jmp     (Sprite_AppendOAMEntries).l
; End of function Cutscene_RenderShipSpriteGrid
; Fills the ship pattern mask and its 512-byte VRAM target with one bits
Cutscene_FillShipPattern:                               ; was: sub_778E
                                        ; Cutscene_SetupSecondShipGrid+90   p
                lea     (ShipPatternMaskBuffer).l,a0
                moveq   #$FFFFFFFF,d0
                move.w  #7,d1
Cutscene_FillShipPatternRAM:                            ; was: loc_779A
                move.l  d0,(a0)+
                dbf     d1,Cutscene_FillShipPatternRAM
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(a0)
                move.l  (ShipPatternVDPCommand).l,(VDP_CTRL).l
                bra.s   Cutscene_PreparePatternVRAMFill
; End of function Cutscene_FillShipPattern
; Fills the planet pattern mask and its 512-byte VRAM target with one bits
Cutscene_FillPlanetPattern:                             ; was: sub_77BA
                                        ; Cutscene_SetupSecondPlanetGrid+90   p
                lea     (M68K_RAM).l,a0
                moveq   #$FFFFFFFF,d0
                move.w  #7,d1
Cutscene_FillPlanetPatternRAM:                          ; was: loc_77C6
                move.l  d0,(a0)+
                dbf     d1,Cutscene_FillPlanetPatternRAM
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(a0)
                move.l  (PatternVDPCommand).l,(VDP_CTRL).l
Cutscene_PreparePatternVRAMFill:                        ; was: loc_77E4
                move.w  #$FFFF,d0
                move.w  #$FF,d1
Cutscene_FillNextPatternVRAMWord:                       ; was: loc_77EC
                move.w  d0,(a0)
                dbf     d1,Cutscene_FillNextPatternVRAMWord
                move    #$2300,sr
                rts
; End of function Cutscene_FillPlanetPattern
; Restores one selected nibble in the ship pattern and queues its row DMA
Cutscene_RevealShipPatternStep:                         ; was: sub_77F8
                                        ; Cutscene_RevealSecondShipGrid+C   p
                move.w  (VBlankFrameCounter).w,d0
                and.w   (ShipPatternFrameMask).l,d0
                bne.w   Cutscene_Return
                move.w  (ShipPatternStep).l,d0
                bmi.w   Cutscene_Return
                subq.w  #1,(ShipPatternStep).l
                bsr.w   Cutscene_SelectShipDissolveWord
                eori.w  #$FFFF,d2
                move.w  (a2),d4
                or.w    d2,d4
                move.w  d4,(a2)
                lea     (ShipPatternFillBuffer).l,a2
                move.w  #$F,d7
Cutscene_FillShipRevealRow:                             ; was: loc_782E
                move.w  d4,(a2)+
                dbf     d7,Cutscene_FillShipRevealRow
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$10,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.l  #$94009310,(a0)+
                move.l  #$8F20977F,(a0)+
                move.l  #$96809530,(a0)+
                ori.l   #$80,d6
                move.l  d6,(a0)+
                rts
; End of function Cutscene_RevealShipPatternStep
; Erases one selected nibble in the ship pattern and queues its row DMA
Cutscene_EraseShipPatternStep:                          ; was: sub_785C
                                        ; Cutscene_EraseSecondShipGrid+12   p
                move.w  (VBlankFrameCounter).w,d0
                and.w   (ShipPatternFrameMask).l,d0
                bne.w   Cutscene_Return
                move.w  (ShipPatternStep).l,d0
                cmpi.w  #$40,d0                         ; '@'
                beq.w   Cutscene_Return
                addq.w  #1,(ShipPatternStep).l
                bsr.w   Cutscene_SelectShipDissolveWord
                move.w  (a2),d4
                and.w   d2,d4
                move.w  d4,(a2)
                lea     (ShipPatternFillBuffer).l,a2
                move.w  #$F,d7
Cutscene_FillShipEraseRow:                              ; was: loc_7892
                move.w  d4,(a2)+
                dbf     d7,Cutscene_FillShipEraseRow
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$10,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.l  #$94009310,(a0)+
                move.l  #$8F20977F,(a0)+
                move.l  #$96809530,(a0)+
                ori.l   #$80,d6
                move.l  d6,(a0)+
                rts
; End of function Cutscene_EraseShipPatternStep
; Restores one selected nibble in the planet pattern and queues its row DMA
Cutscene_RevealPlanetPatternStep:                       ; was: sub_78C0
                                        ; Cutscene_RevealSecondPlanetGrid+C   p
                move.w  (VBlankFrameCounter).w,d0
                and.w   (PatternFrameMask).l,d0
                bne.w   Cutscene_Return
                move.w  (PatternDissolveStep).l,d0
                bmi.w   Cutscene_Return
                subq.w  #1,(PatternDissolveStep).l
                bsr.w   Cutscene_SelectPlanetDissolveWord
                eori.w  #$FFFF,d2
                move.w  (a2),d4
                or.w    d2,d4
                move.w  d4,(a2)
                lea     (PlanetPatternFillBuffer).l,a2
                move.w  #$F,d7
Cutscene_FillPlanetRevealRow:                           ; was: loc_78F6
                move.w  d4,(a2)+
                dbf     d7,Cutscene_FillPlanetRevealRow
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$10,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.l  #$94009310,(a0)+
                move.l  #$8F20977F,(a0)+
                move.l  #$96809520,(a0)+
                ori.l   #$80,d6
                move.l  d6,(a0)+
                rts
; End of function Cutscene_RevealPlanetPatternStep
; Erases one selected nibble in the planet pattern and queues its row DMA
Cutscene_ErasePlanetPatternStep:                        ; was: sub_7924
                                        ; Cutscene_EraseSecondPlanetGrid+12   p
                move.w  (VBlankFrameCounter).w,d0
                and.w   (PatternFrameMask).l,d0
                bne.w   Cutscene_Return
                move.w  (PatternDissolveStep).l,d0
                cmpi.w  #$40,d0                         ; '@'
                beq.w   Cutscene_Return
                addq.w  #1,(PatternDissolveStep).l
                bsr.w   Cutscene_SelectPlanetDissolveWord
                move.w  (a2),d4
                and.w   d2,d4
                move.w  d4,(a2)
                lea     (PlanetPatternFillBuffer).l,a2
                move.w  #$F,d7
Cutscene_FillPlanetEraseRow:                            ; was: loc_795A
                move.w  d4,(a2)+
                dbf     d7,Cutscene_FillPlanetEraseRow
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$10,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.l  #$94009310,(a0)+
                move.l  #$8F20977F,(a0)+
                move.l  #$96809520,(a0)+
                ori.l   #$80,d6
                move.l  d6,(a0)+
                rts
; End of function Cutscene_ErasePlanetPatternStep
; Selects a planet pattern word, nibble mask, and matching VRAM command
Cutscene_SelectPlanetDissolveWord:                      ; was: sub_7988
                                        ; Cutscene_ErasePlanetPatternStep+22   p
                lea     (M68K_RAM).l,a2
                lea     PatternDissolveWordOrder(pc,d0.w),a3
                moveq   #0,d2
                move.b  (a3),d2
                andi.b  #3,d2
                lsl.b   #1,d2
                lea     PatternDissolveNibbleMasks(pc,d2.w),a4
                move.w  (a4),d2
                moveq   #0,d3
                move.b  (a3),d3
                andi.b  #$3C,d3                         ; '<'
                lsr.b   #1,d3
                adda.l  d3,a2
                swap    d3
                move.l  (PatternVDPCommand).l,d6
                add.l   d3,d6
                rts
; End of function Cutscene_SelectPlanetDissolveWord
; ---------------------------------------------------------------------------
PatternDissolveWordOrder:   dc.b    4, $2A, $24, 8, $18, $32, $27, $2D, $37, $13, $F, $1C, $36, 3, $12, $17  ; was: byte_79BA
                                        ; Cutscene_SelectShipDissolveWord+6   o
                dc.b    $C, $23, $20, $2E, $A, $3C, $21, $E, $1D, $38, 1, $19, $3A, $D, $2C, $35
                dc.b    $2F, $10, $29, 0, $15, $26, 6, $28, 5, $33, $30, 2, $11, $3F, $34, $1E
                dc.b    $3D, $1A, $14, $3E, 9, $31, $16, 7, $25, $B, $39, $1F, $2B, $1B, $3B, $22
PatternDissolveNibbleMasks: dc.w    $FFF, $F0FF, $FF0F, $FFF0  ; was: word_79FA

; Selects a ship pattern word, nibble mask, and matching VRAM command
Cutscene_SelectShipDissolveWord:                        ; was: sub_7A02
                                        ; Cutscene_EraseShipPatternStep+22   p
                lea     (ShipPatternMaskBuffer).l,a2
                lea     PatternDissolveWordOrder(pc,d0.w),a3
                moveq   #0,d2
                move.b  (a3),d2
                andi.b  #3,d2
                lsl.b   #1,d2
                lea     PatternDissolveNibbleMasks(pc,d2.w),a4
                move.w  (a4),d2
                moveq   #0,d3
                move.b  (a3),d3
                andi.b  #$3C,d3                         ; '<'
                lsr.b   #1,d3
                adda.l  d3,a2
                swap    d3
                move.l  (ShipPatternVDPCommand).l,d6
                add.l   d3,d6
                rts
; End of function Cutscene_SelectShipDissolveWord
; Composes sixteen planet pattern rows and queues sixteen DMA records
Cutscene_QueuePlanetPatternRows:                        ; was: sub_7A34
                                        ; Cutscene_HoldFirstPlanetGrid+4   p
                lea     (PlanetPatternRowBuffer).l,a1
                lea     (M68K_RAM).l,a2
                lea     Cutscene_AlternatingRowMasks(pc),a3
                nop
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #1,d0
                bne.s   Cutscene_SelectPlanetRowMasks
                adda.l  #4,a3
Cutscene_SelectPlanetRowMasks:                          ; was: loc_7A56
                move.w  #$F,d6
Cutscene_ComposeNextPlanetRow:                          ; was: loc_7A5A
                move.w  (a2)+,d0
                or.w    (a3)+,d0
                move.w  d0,(a1)+
                dbf     d6,Cutscene_ComposeNextPlanetRow
                move.l  (PatternVDPCommand).l,d6
                ori.l   #$80,d6
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$100,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.w  #$F,d0
Cutscene_QueueNextPlanetPatternRow:                     ; was: loc_7A80
                move.l  #$94009310,(a0)+
                move.l  #$8F02877F,(a0)+
                move.l  #$96809540,(a0)+
                move.l  d6,(a0)+
                addi.l  #$200000,d6
                dbf     d0,Cutscene_QueueNextPlanetPatternRow
                rts
; End of function Cutscene_QueuePlanetPatternRows
; Composes sixteen ship pattern rows and queues sixteen DMA records
Cutscene_QueueShipPatternRows:                          ; was: sub_7AA0
                                        ; Cutscene_HoldFirstShipGrid+4   p
                lea     (ShipPatternRowBuffer).l,a1
                lea     (ShipPatternMaskBuffer).l,a2
                lea     Cutscene_AlternatingRowMasks(pc),a3
                nop
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #1,d0
                bne.s   Cutscene_SelectShipRowMasks
                adda.l  #4,a3
Cutscene_SelectShipRowMasks:                            ; was: loc_7AC2
                move.w  #$F,d6
Cutscene_ComposeNextShipRow:                            ; was: loc_7AC6
                move.w  (a2)+,d0
                or.w    (a3)+,d0
                move.w  d0,(a1)+
                dbf     d6,Cutscene_ComposeNextShipRow
                move.l  (ShipPatternVDPCommand).l,d6
                ori.l   #$80,d6
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$100,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.w  #$F,d0
Cutscene_QueueNextShipPatternRow:                       ; was: loc_7AEC
                move.l  #$94009310,(a0)+
                move.l  #$8F02877F,(a0)+
                move.l  #$96809550,(a0)+
                move.l  d6,(a0)+
                addi.l  #$200000,d6
                dbf     d0,Cutscene_QueueNextShipPatternRow
                rts
; End of function Cutscene_QueueShipPatternRows
; ---------------------------------------------------------------------------
Cutscene_AlternatingRowMasks:   dc.w    $F0F, $F0F, $F0F0, $F0F0, $F0F, $F0F, $F0F0, $F0F0, $F0F  ; was: word_7B0C
                                        ; Cutscene_QueueShipPatternRows+C   o
                dc.w    $F0F, $F0F0, $F0F0, $F0F, $F0F, $F0F0, $F0F0, $F0F, $F0F
