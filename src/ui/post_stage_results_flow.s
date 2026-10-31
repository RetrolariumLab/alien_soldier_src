Results_InitializePostStageFlow:                        ; was: sub_1D628
                tst.w   (GameSubstateIndex).w
                bne.s   Results_InitializePostStageFlow_Activate
                tst.w   (DataLoaderControl).w
                bpl.s   Results_InitializePostStageFlow_LoadAssets
                rts
; ---------------------------------------------------------------------------
Results_InitializePostStageFlow_LoadAssets:             ; was: loc_1D636
                jsr     (Sys_InitGameMode).l
                movea.l #ResultsPostStageAssetLoadList,a0
                jsr     (LoadObjData).l
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bset    #1,(StageRouteFlags).w
                movea.w #(PostStageEntryCountBCD+2-M68K_RAM),a0
                movea.w #(BCDIncrementEnd-M68K_RAM),a1
                move.w  #1,(BCDIncrementScratch).w
                sub.w   d1,d1
                abcd    -(a1),-(a0)
                abcd    -(a1),-(a0)
                bcc.s   Results_InitializePostStageFlow_BeginFontTransfer
                move.w  #$9999,(PostStageEntryCountBCD).w
Results_InitializePostStageFlow_BeginFontTransfer:      ; was: loc_1D688
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
Results_InitializePostStageFlow_Activate:               ; was: loc_1D69C
                move.w  #$30,(GameModeIndex).w          ; '0'
                clr.w   (GameSubstateIndex).w
                lea     (PostStageFullPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                jsr     (Gfx_FadePaletteTransition).l
                clr.w   (ResultsFirstColorOffset).w
                move.w  #$FFF2,(ResultsOtherColorOffset).w
                bsr.w   Results_FadeSelectedPaletteRanges
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                move.w  #$FF00,(PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                move.w  #$FF00,(SecondaryCameraYPos).w
                move.w  #$10,(SecondaryCameraXPos).w
                move.b  #4,(PlaneBScrollModeFlags).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
; Finalizes post-stage display state and resets the frame counter
Results_FinalizePostStageSetup:                         ; was: loc_1D6F4
                move.b  #3,(VDPReg11Shadow+1).w
                move.b  #0,(VDPReg18Shadow+1).w
                bsr.w   Results_RenderSummaryPanel
                clr.w   (FrameCounter).w
                rts
; End of function Results_InitializePostStageFlow
; ---------------------------------------------------------------------------
ResultsPostStageAssetLoadList:  dc.w    3               ; command: decompress tiles to VRAM  ; was: stru_1D70A
                dc.l    ResultsPostStageType3Data0000   ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedCreditsResultsMappingData6000  ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedCreditsResultsMappingData4020  ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedFrontendAndTransitionMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedFrontendAndTransitionTileArt  ; source
                dc.w    $D000                           ; destination: VRAM $D000
                dc.w    $FFFF

; Re-enters the post-stage completion state after the secondary options path
Results_InitializeSecondaryOptionsReturn:               ; was: sub_1D734
                tst.w   (GameSubstateIndex).w
                bne.s   Results_InitializeSecondaryOptionsReturn_Activate
                jsr     (Sys_InitGameMode).l
                movea.l #ResultsPostStageAssetLoadList,a0
                jsr     (LoadObjData).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueSmallFontDMA
; ---------------------------------------------------------------------------
Results_InitializeSecondaryOptionsReturn_Activate:      ; was: loc_1D778
                move.w  #$30,(GameModeIndex).w          ; '0'
                move.w  #6,(GameSubstateIndex).w
                lea     (PostStageFullPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                jsr     (Gfx_FadePaletteTransition).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                move.w  #$FF00,(SecondaryCameraYPos).w
                move.w  #0,(SecondaryCameraXPos).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                move.w  #2,(TitleMenuSelection).w
                bra.w   Results_FinalizePostStageSetup
; End of function Results_InitializeSecondaryOptionsReturn

; Dispatches the results, continue, and game-over post-stage flow
Results_DispatchPostStageState:                         ; was: sub_1D7BE
                move.w  (GameSubstateIndex).w,d0
                movea.w ResultsPostStageStateOffsets(pc,d0.w),a0
                adda.l  #Results_UpdateEntranceScroll,a0
                jmp     (a0)
; End of function Results_DispatchPostStageState
; ---------------------------------------------------------------------------
ResultsPostStageStateOffsets:   dc.w    Results_UpdateEntranceScroll-Results_UpdateEntranceScroll  ; was: off_1D7CE
                dc.w    Results_UpdateEntranceFade-Results_UpdateEntranceScroll
                dc.w    Results_ActivatePostStageSummary-Results_UpdateEntranceScroll
                dc.w    Results_WaitForPostStageConfirmation-Results_UpdateEntranceScroll
                dc.w    Results_FadeOutToContinue-Results_UpdateEntranceScroll
                dc.w    Continue_InitializeScreen-Results_UpdateEntranceScroll
                dc.w    Continue_ActivateScreen-Results_UpdateEntranceScroll
                dc.w    Continue_UpdateCountdownAndInput-Results_UpdateEntranceScroll
                dc.w    Continue_ApplyChoiceAfterFade-Results_UpdateEntranceScroll
                dc.w    Continue_ReturnToTitleAfterFade-Results_UpdateEntranceScroll

; Advances the scrolling entrance to the post-stage results screen
Results_UpdateEntranceScroll:                           ; was: sub_1D7E2
                addq.w  #1,(FrameCounter).w
                cmpi.w  #$20,(FrameCounter).w           ; ' '
                beq.s   Results_UpdateEntranceScroll_PlayCue
                cmpi.w  #$24,(FrameCounter).w           ; '$'
                bne.s   Results_UpdateEntranceScroll_CheckComplete
Results_UpdateEntranceScroll_PlayCue:                   ; was: loc_1D7F6
                move.b  #$1D,d0
                jsr     (Sound_QueueRequest).l
Results_UpdateEntranceScroll_CheckComplete:             ; was: loc_1D800
                cmpi.w  #$3C0,(PrimaryCameraXPosition).w
                bmi.s   Results_UpdateEntranceFrame
                addq.w  #2,(GameSubstateIndex).w
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                bra.s   Results_UpdateEntranceFrame
; End of function Results_UpdateEntranceScroll

; Advances from the completed entrance fade into results rendering
Results_UpdateEntranceFade:                             ; was: sub_1D81E
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   Results_UpdateEntranceFrame
                addq.w  #2,(GameSubstateIndex).w
                clr.b   (VDPReg11Shadow+1).w
                move.b  #$12,(VDPReg18Shadow+1).w
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                move.w  #$4000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jmp     Tilemap_FillPlaneDirectToVRAM
; ---------------------------------------------------------------------------
Results_UpdateEntranceFrame:                            ; was: loc_1D86A
                jsr     (Gfx_FadePaletteTransition).l
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                move.l  #$FFFF0000,d0
                bsr.w   Results_BuildParallaxHScroll
                addq.w  #8,(PrimaryCameraXPosition).w
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$1C0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                jsr     (Tilemap_QueuePrimaryPlaneColumn).l
                addq.w  #4,(PrimaryCameraXPosition).w
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$1C0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                jmp     Tilemap_QueuePrimaryPlaneColumn
; End of function Results_UpdateEntranceFade

; Builds alternating post-stage horizontal-scroll words from two accumulators
Results_BuildParallaxHScroll:                           ; was: sub_1D8AC
                movea.w #(HScrollBuffer-M68K_RAM),a0
                move.l  (PrimaryCameraXPosition).w,d1
                neg.l   d1
                move.w  #$6F,d7                         ; 'o'
                move.l  d1,d2
                addi.l  #0,d2
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   Results_BuildParallaxHScroll_PrepareAccumulators
                exg     d1,d2
Results_BuildParallaxHScroll_PrepareAccumulators:       ; was: loc_1D8CC
                swap    d1
                swap    d2
Results_BuildParallaxHScroll_NextRowPair:               ; was: loc_1D8D0
                move.w  d1,(a0)
                addq.w  #4,a0
                swap    d1
                add.l   d0,d1
                swap    d1
                move.w  d2,(a0)
                addq.w  #4,a0
                swap    d2
                add.l   d0,d2
                swap    d2
                dbf     d7,Results_BuildParallaxHScroll_NextRowPair
                rts
; End of function Results_BuildParallaxHScroll

; Fades the four selected post-stage palette ranges
Results_FadeSelectedPaletteRanges:                      ; was: sub_1D8EA
                movea.w #(PaletteShadowColor03-M68K_RAM),a1
                movea.w #(PaletteActiveColor03-M68K_RAM),a2
                moveq   #3,d5
Results_FadeSelectedPaletteRanges_NextFirstColor:       ; was: loc_1D8F4
                move.w  (a1)+,d6
                move.w  (ResultsFirstColorOffset).w,d0
                jsr     (Gfx_ExpandColorAdjustmentToRGBChannels).l
                moveq   #$FFFFFFFF,d0
                jsr     (Gfx_AdjustSelectedColorChannels).l
                move.w  d6,(a2)+
                dbf     d5,Results_FadeSelectedPaletteRanges_NextFirstColor
                movea.w #(PaletteShadowPair16+2-M68K_RAM),a1
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a2
                moveq   #4,d5
                bsr.s   Results_FadePaletteRange
                movea.w #(PaletteShadowPair33-M68K_RAM),a1
                movea.w #(PaletteActiveColor33-M68K_RAM),a2
                moveq   #4,d5
                bsr.s   Results_FadePaletteRange
                movea.w #(PaletteShadowColor49-M68K_RAM),a1
                movea.w #(PaletteActiveColor49-M68K_RAM),a2
                moveq   #4,d5
; End of function Results_FadeSelectedPaletteRanges

; Fades one selected post-stage palette range
Results_FadePaletteRange:                               ; was: sub_1D930
                move.w  (a1)+,d6
                move.w  (ResultsOtherColorOffset).w,d0
                jsr     (Gfx_ExpandColorAdjustmentToRGBChannels).l
                moveq   #$FFFFFFFF,d0
                jsr     (Gfx_AdjustSelectedColorChannels).l
                move.w  d6,(a2)+
                dbf     d5,Results_FadePaletteRange
                rts
; End of function Results_FadePaletteRange
