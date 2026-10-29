; RasterEffectIndex is a byte offset into the 23 longword handler addresses below
VBlank_DispatchRasterEffect:                            ; was: sub_1356
                move.w  (RasterEffectIndex).w,d0
                movea.l VBlankRasterEffectHandlerTable(pc,d0.w),a0
                jmp     (a0)
; ---------------------------------------------------------------------------
VBlankRasterEffectHandlerTable: dc.l    VBlank_DisableHBlankEffect  ; was: off_1360
                dc.l    VBlank_InitAlternateTransitionVScroll2Effect
                dc.l    VBlank_InitXiTigerEffect
                dc.l    VBlank_InitVScroll2Effect
                dc.l    VBlank_InitTransitionVScroll2Effect
                dc.l    VBlank_DisableHBlankEffect
                dc.l    VBlank_InitCRAMWriteEffect
                dc.l    VBlank_DisableHBlankEffect
                dc.l    VBlank_InitStage2DemoVScrollEffect
                dc.l    VBlank_InitSplitVScrollEffect
                dc.l    VBlank_InitFlyingNeoVScroll2Effect
                dc.l    VBlank_InitStage9FlyCorridorVScroll0Effect
                dc.l    VBlank_InitStage10Effect
                dc.l    VBlank_InitSunsetStingVScroll0Effect
                dc.l    VBlank_InitStage10Effect
                dc.l    VBlank_InitLettersVScrollEffect
                dc.l    VBlank_Epsilon1ScrollEffect
                dc.l    VBlank_InitStoryDisplayEffect
                dc.l    VBlank_InitBufferedVDPControlEffect
                dc.l    VBlank_InitGameOverVScrollPairEffect
                dc.l    VBlank_InitDestroyerProtoVScrollEffect
                dc.l    VBlank_InitZLeoRasterEffect
                dc.l    VBlank_InitSevenForceWindowEffect
; End of function VBlank_DispatchRasterEffect
; Disables the installed HBlank effect and replaces its RAM entry with RTE
VBlank_DisableHBlankEffect:                             ; was: sub_13BC
                                        ; VBlank_DispatchRasterEffect+1E   o
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_DisableHBlankEffect_Return
                addq.w  #4,(RasterEffectInitState).w
                andi.b  #$EF,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
                move.w  #$4E73,(HBlankRAMCode).w
VBlank_DisableHBlankEffect_Return:                      ; was: locret_13DC
                rts
; End of function VBlank_DisableHBlankEffect
; Installs the letters-screen HBlank VScroll writer and selects its per-line data buffer
VBlank_InitLettersVScrollEffect:                        ; was: sub_13DE
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitLettersVScrollEffect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #0,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll0_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
; Branch target that loads buffer address for letters effect after initialization
VBlank_InitLettersVScrollEffect_SelectBuffer:           ; was: loc_1412
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitLettersVScrollEffect
; ---------------------------------------------------------------------------
HBlank_WriteVScroll0_InstallList:   dc.w    0           ; field_0  ; was: stru_1418
                                        ; VBlank_InitStage2DemoVScrollEffect+1A   o
                dc.l    HBlank_WriteVScroll0_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_WriteVScroll0_CopyLength:    dc.w    $20         ; was: word_1422

; Writes the next buffered word to VSRAM address zero during HBlank
HBlank_WriteVScroll0:                                   ; was: sub_1424
                move.l  #$40000010,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                rte
; End of function HBlank_WriteVScroll0
; Installs the Stage 2 demo VScroll writer and selects its per-line data buffer
VBlank_InitStage2DemoVScrollEffect:                     ; was: sub_1436
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitStage2DemoVScrollEffect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #1,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll0_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
; Applies the Stage 2 raster registers and selects the per-line data buffer
VBlank_InitStage2DemoVScrollEffect_SelectBuffer:        ; was: loc_1468
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitStage2DemoVScrollEffect
; Installs the Stage 9 fly-corridor HBlank VScroll0 writer
VBlank_InitStage9FlyCorridorVScroll0Effect:             ; was: sub_147E
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitStage9FlyCorridorVScroll0Effect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #7,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll0_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitStage9FlyCorridorVScroll0Effect_SelectBuffer:  ; was: loc_14B0
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitStage9FlyCorridorVScroll0Effect
; Initializes VBlank effect for Xi-Tiger cutscene
VBlank_InitXiTigerEffect:                               ; was: sub_14B6
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitXiTigerEffect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #7,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll0_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitXiTigerEffect_SelectBuffer:                  ; was: loc_14E8
                lea     (XiTigerVScrollBuffer).w,a6
                rts
; End of function VBlank_InitXiTigerEffect
; Installs a buffered HBlank writer for VSRAM address two
VBlank_InitVScroll2Effect:                              ; was: sub_14EE
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitVScroll2Effect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #0,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll2_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitVScroll2Effect_SelectBuffer:                 ; was: loc_1522
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitVScroll2Effect
; ---------------------------------------------------------------------------
HBlank_WriteVScroll2_InstallList:   dc.w    0           ; field_0  ; was: stru_1528
                                        ; VBlank_InitTransitionVScroll2Effect+1A   o
                dc.l    HBlank_WriteVScroll2_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_WriteVScroll2_CopyLength:    dc.w    $20         ; was: word_1532

; Writes the next buffered word to VSRAM address two during HBlank
HBlank_WriteVScroll2:                                   ; was: sub_1534
                move.l  #$40020010,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                rte
; End of function HBlank_WriteVScroll2
; Installs a one-shot split VScroll writer and updates its split position
VBlank_InitSplitVScrollEffect:                          ; was: sub_1546
                move.w  (RasterEffectInitState).w,d0
                bne.s   VBlank_InitSplitVScrollEffect_Update
                addq.w  #4,(RasterEffectInitState).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteSplitVScroll2AndStop_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitSplitVScrollEffect_Update:                   ; was: loc_1572
                move.l  #$40020010,(VDP_CTRL).l
                move.w  (VScrollPlaneAColumn1).w,(VDP_DATA).l
                move.b  (PrimaryEntityWork4B).w,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                rts
; End of function VBlank_InitSplitVScrollEffect
; ---------------------------------------------------------------------------
HBlank_WriteSplitVScroll2AndStop_InstallList:   dc.w    0  ; field_0  ; was: stru_1594
                dc.l    HBlank_WriteSplitVScroll2AndStop_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_WriteSplitVScroll2AndStop_CopyLength:    dc.w    $20  ; was: word_159E

; Writes the split value to VSRAM address two and postpones the next H interrupt
HBlank_WriteSplitVScroll2AndStop:                       ; was: sub_15A0
                move.l  #$40020010,(VDP_CTRL).l
                move.w  (ActiveRasterBuffer).w,(VDP_DATA).l
                move.w  #$8AFF,(VDP_CTRL).l
                rte
; End of function HBlank_WriteSplitVScroll2AndStop
; Installs the standard-transition HBlank VScroll2 writer
VBlank_InitTransitionVScroll2Effect:                    ; was: sub_15BC
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitTransitionVScroll2Effect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #1,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll2_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitTransitionVScroll2Effect_SelectBuffer:       ; was: loc_15EE
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitTransitionVScroll2Effect
; Installs the alternate-transition HBlank VScroll2 writer
VBlank_InitAlternateTransitionVScroll2Effect:           ; was: sub_15F4
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitAlternateTransitionVScroll2Effect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #3,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll2_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitAlternateTransitionVScroll2Effect_SelectBuffer:  ; was: loc_1626
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitAlternateTransitionVScroll2Effect
; Installs the Flying Neo HBlank VScroll2 writer
VBlank_InitFlyingNeoVScroll2Effect:                     ; was: sub_162C
                move.w  (RasterEffectInitState).w,d0
                bne.s   VBlank_InitFlyingNeoVScroll2Effect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #7,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll2_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
; Loads buffer address for Flying Neo stage VBlank effect after initialization
VBlank_InitFlyingNeoVScroll2Effect_SelectBuffer:        ; was: loc_165C
                lea     (ActiveRasterBuffer).w,a6
                rts
; End of function VBlank_InitFlyingNeoVScroll2Effect
; Installs the Sunset Sting HBlank VScroll0 writer
VBlank_InitSunsetStingVScroll0Effect:                   ; was: sub_1662
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitSunsetStingVScroll0Effect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #1,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScroll0_InstallList(pc),a0
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitSunsetStingVScroll0Effect_SelectBuffer:      ; was: loc_1694
                lea     (RasterStagingBuffer).w,a6
                rts
; End of function VBlank_InitSunsetStingVScroll0Effect
; Installs the story-screen HBlank plane/scroll updater
VBlank_InitStoryDisplayEffect:                          ; was: sub_169A
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitStoryDisplayEffect_PrepareHBlankPort
                addq.w  #4,(RasterEffectInitState).w
                move.b  #$C0,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_UpdateStoryDisplay_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg18Shadow).w,(VDP_CTRL).l
; Branch target that sets VDP control register for story screen effect after initialization
VBlank_InitStoryDisplayEffect_PrepareHBlankPort:        ; was: loc_16D6
                move.w  (VDPReg2Shadow).w,(VDP_CTRL).l
                lea     (VDP_CTRL).l,a6
                rts
; End of function VBlank_InitStoryDisplayEffect
; ---------------------------------------------------------------------------
HBlank_UpdateStoryDisplay_InstallList:  dc.w    0       ; field_0  ; was: stru_16E6
                dc.l    HBlank_UpdateStoryDisplay_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_UpdateStoryDisplay_CopyLength:   dc.w    $40     ; was: word_16F0

; Changes the story-screen plane A base and scroll values at a timed scanline
HBlank_UpdateStoryDisplay:                              ; was: sub_16F2
                move.w  #$8210,(a6)
                move.l  #$40000010,(a6)
                move.w  #0,(VDP_DATA).l
                move.l  #$70000003,(a6)
                move.w  (StoryFontScrollY).l,(VDP_DATA).l
                move.w  #$10,(StoryHBlankDelayCounter).l
HBlank_UpdateStoryDisplay_DelayLoop:                    ; was: loc_171C
                subq.w  #1,(StoryHBlankDelayCounter).l
                bne.s   HBlank_UpdateStoryDisplay_DelayLoop
                move.w  #$8228,(a6)
                rte
; End of function HBlank_UpdateStoryDisplay
; Installs the Game Over HBlank two-word VScroll writer
VBlank_InitGameOverVScrollPairEffect:                   ; was: sub_172A
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitGameOverVScrollPairEffect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #1,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_WriteVScrollPair_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
VBlank_InitGameOverVScrollPairEffect_SelectBuffer:      ; was: loc_175E
                movea.w #(RasterVScrollPairBuffer-M68K_RAM),a6
                rts
; End of function VBlank_InitGameOverVScrollPairEffect
; ---------------------------------------------------------------------------
HBlank_WriteVScrollPair_InstallList:    dc.w    0       ; field_0  ; was: stru_1764
                dc.l    HBlank_WriteVScrollPair_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_WriteVScrollPair_CopyLength: dc.w    $40         ; was: word_176E

; Writes the next buffered two-word vertical-scroll pair during HBlank
HBlank_WriteVScrollPair:                                ; was: sub_1770
                move.l  #$40000010,(VDP_CTRL).l
                move.l  (a6)+,(VDP_DATA).l
                rte
; End of function HBlank_WriteVScrollPair
; Initializes VBlank effect for Stage 10
VBlank_InitStage10Effect:                               ; was: sub_1782
                                        ; VBlank_DispatchRasterEffect+42   o
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitStage10Effect_RefreshScrollAndBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #$C8,(VDPReg10Shadow+1).w
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                lea     HBlank_UpdateStage10Display_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
; Recurring VBlank path updates display state and seeds the HBlank scroll buffer
VBlank_InitStage10Effect_RefreshScrollAndBuffer:        ; was: loc_17B6
                move.w  (VDPReg2Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg4Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg7Shadow).w,(VDP_CTRL).l
                move.l  #$70020003,(VDP_CTRL).l
                move.w  (HScrollPlaneBRow0).w,(VDP_DATA).l
                move.l  #$70000003,(VDP_CTRL).l
                move.w  (HScrollBuffer).w,(VDP_DATA).l
                move.l  #$40020010,(VDP_CTRL).l
                move.w  (VScrollPlaneBColumn0).w,(VDP_DATA).l
                move.l  #$40000010,(VDP_CTRL).l
                move.w  (VScrollBuffer).w,(VDP_DATA).l
                movea.w #(Stage10HBlankScrollData-M68K_RAM),a0
                move.w  (VScrollBuffer).w,(a0)+
                move.w  (VScrollPlaneBColumn0).w,(a0)+
                move.w  (PreviousCameraXPosition).w,d0
                neg.w   d0
                cmpi.w  #$30,(RasterEffectIndex).w      ; '0'
                beq.s   VBlank_InitStage10Effect_StoreHBlankData
                move.w  (HScrollBuffer).w,d0
; Branch target that sets scroll value for Stage 10 effect and prepares sprite buffer
VBlank_InitStage10Effect_StoreHBlankData:               ; was: loc_1834
                move.w  d0,(a0)+
                movea.w #(Stage10HBlankScrollData-M68K_RAM),a6
                rts
; End of function VBlank_InitStage10Effect
; ---------------------------------------------------------------------------
HBlank_UpdateStage10Display_InstallList:    dc.w    0   ; field_0  ; was: stru_183C
                dc.l    HBlank_UpdateStage10Display_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_UpdateStage10Display_CopyLength: dc.w    $200    ; was: word_1846

; Applies Stage 10 scroll values and delayed plane/backdrop changes during HBlank
HBlank_UpdateStage10Display:                            ; was: sub_1848
                move.l  #$40020010,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                move.l  #$40000010,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                move.l  #$70020003,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                move.l  #$70000003,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                nop
                move.w  #$8238,(VDP_CTRL).l
                move.w  #$8406,(VDP_CTRL).l
                move.w  #$8718,(VDP_CTRL).l
                rte
; End of function HBlank_UpdateStage10Display
; Installs a buffered HBlank writer for CRAM color index five
VBlank_InitCRAMWriteEffect:                             ; was: sub_1904
                move.w  (RasterEffectInitState).w,d0
                bne.w   VBlank_InitCRAMWriteEffect_SelectBuffer
                addq.w  #4,(RasterEffectInitState).w
                move.b  #3,(VDPReg10Shadow+1).w
                lea     HBlank_WriteCRAMColor5_InstallList(pc),a0
                nop
                jsr     (LoadObjData).l
                ori.b   #$10,(VDPReg0Shadow+1).w
VBlank_InitCRAMWriteEffect_SelectBuffer:                ; was: loc_1928
                move.w  (VDPReg10Shadow).w,(VDP_CTRL).l
                move.w  (VDPReg0Shadow).w,(VDP_CTRL).l
                lea     (CRAMWriteEffectBuffer).w,a6
                rts
; End of function VBlank_InitCRAMWriteEffect
; ---------------------------------------------------------------------------
HBlank_WriteCRAMColor5_InstallList: dc.w    0           ; field_0  ; was: stru_193E
                dc.l    HBlank_WriteCRAMColor5_CopyLength  ; field_2
                dc.w    $EE00                           ; field_6
                dc.w    $FFFF
HBlank_WriteCRAMColor5_CopyLength:  dc.w    $20         ; was: word_1948

; Writes the next buffered word to CRAM color index five during HBlank
HBlank_WriteCRAMColor5:                                 ; was: sub_194A
                move.l  #$C00A0000,(VDP_CTRL).l
                move.w  (a6)+,(VDP_DATA).l
                rte
; End of function HBlank_WriteCRAMColor5
; VBlank effect handler for scroll
