Frontend_InitializeSegaSequence:                        ; was: sub_1CE7E
                tst.w   (GameSubstateIndex).w
                bne.s   Frontend_ActivateSegaSequence
                jsr     (Sys_InitGameMode).l
                movea.l #FrontendSegaSequenceAssetLoadList,a0
                jsr     (LoadObjData).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                clr.b   (VDPReg18Shadow+1).w
                clr.w   (SharedSequenceState).l
                clr.w   (StoryTextState).l
                rts
; ---------------------------------------------------------------------------
; Loads palette and data tables for results screen
Frontend_ActivateSegaSequence:                          ; was: loc_1CEB6
                move.w  #8,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                move.w  #$F0,(FrontendHoldTimer).w
                move.w  #0,d0
                move.w  #0,d1
                jsr     (Tilemap_DirectTransferWithAlternateDescriptor).l
                move.w  #0,d0
                move.w  #0,d1
                jsr     (Tilemap_DirectTransferWithPrimaryDescriptor).l
                movea.l #EarlyStagePaletteOffsetList,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                rts
; End of function Frontend_InitializeSegaSequence
; ---------------------------------------------------------------------------
FrontendSegaSequenceAssetLoadList:  dc.w    7           ; field_0  ; was: stru_1CEFC
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $C000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $D000                           ; field_6
                dc.w    $FFFF

; Main game loop update with object processing
Frontend_UpdateOpeningSequence:                         ; was: sub_1CF16
                tst.w   (DataLoaderControl).w
                bmi.s   Frontend_UpdateOpeningSequence_RunFrame
                cmpi.w  #4,(GameSubstateIndex).w
                bcs.s   Frontend_UpdateOpeningSequence_RunFrame
                btst    #7,(ControllerPressedState).w
                bne.w   Frontend_HandleOpeningSkip
Frontend_UpdateOpeningSequence_RunFrame:                ; was: loc_1CF2E
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                jsr     (Sys_ProcessVisibleObjects).l
                bsr.w   Frontend_DispatchOpeningState
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                addq.w  #1,(FrameCounter).w
                rts
; End of function Frontend_UpdateOpeningSequence
Frontend_DispatchOpeningState:                          ; was: sub_1CF62
                move.w  (GameSubstateIndex).w,d0
                movea.w FrontendOpeningStateOffsets(pc,d0.w),a0
                adda.l  #Frontend_InitializeSegaScreen,a0
                jmp     (a0)
; End of function Frontend_DispatchOpeningState
; ---------------------------------------------------------------------------
FrontendOpeningStateOffsets:    dc.w    Frontend_InitializeSegaScreen-Frontend_InitializeSegaScreen  ; was: off_1CF72
                dc.w    Frontend_DispatchSegaScreenTransition-Frontend_InitializeSegaScreen
                dc.w    Frontend_InitializeTitleTransition-Frontend_InitializeSegaScreen
                dc.w    Frontend_DispatchTitleTransition-Frontend_InitializeSegaScreen
                dc.w    Frontend_InitializeTransitionScene-Frontend_InitializeSegaScreen
                dc.w    Frontend_PrepareTransitionScrollPlanes-Frontend_InitializeSegaScreen
                dc.w    Cutscene_InitializeScene-Frontend_InitializeSegaScreen
                dc.w    Cutscene_UpdateFrameSelectionFromInput-Frontend_InitializeSegaScreen

; Initializes SEGA logo screen with graphics and palettes
Frontend_InitializeSegaScreen:                          ; was: sub_1CF82
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                jsr     (Gfx_QueueLargeFontDMACommand81).l
                lea     (FrontendPaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                movea.l #Frontend_TitleAssetLoadDescriptors,a0
                jsr     (LoadObjData).l
                movea.l #SharedTilemapWorkspace,a0
                move.w  #$8000,d0
                move.w  #$FF00,d1
                move.w  #$BF,d7
                jsr     (Gfx_UpdateTilemapIndices).l
                bsr.w   Frontend_CopyPaletteLines
                lea     (LargeTilemapBuffer).l,a0
                move.w  #$7FF,d0
Frontend_InitializeSegaScreen_SetHighPriorityTiles:     ; was: loc_1CFD0
                move.l  (a0),d1
                ori.l   #$E000E000,d1
                move.l  d1,(a0)+
                dbf     d0,Frontend_InitializeSegaScreen_SetHighPriorityTiles
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                move.w  #$600,d0
                move.w  #0,d1
                move.w  d0,(SecondaryCameraXPos).w
                move.w  d1,(SecondaryCameraYPos).w
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                lea     (M68K_RAM).l,a0
                moveq   #$FFFFFFFF,d0
                move.w  #$F,d1
Frontend_InitializeSegaScreen_ClearSpriteGridScratch:   ; was: loc_1D006
                move.l  d0,(a0)+
                dbf     d1,Frontend_InitializeSegaScreen_ClearSpriteGridScratch
                move.w  #$400,(SpriteGridFirstTile).l
                move.w  #$E8,(SpriteGridCenterY).l
                move.w  #$120,(SpriteGridCenterX).l
                move.w  #0,(SpriteGridRowLimit).l
                move.w  #2,(SpriteGridColumnLimit).l
                move.l  #$40000002,(PatternVDPCommand).l
                move.w  #$F,(PlanetPatternWriteOnly).l
                move.w  #0,(PatternFrameMask).l
                clr.w   (PatternDissolveStep).l
                jsr     (Cutscene_FillPlanetPattern).l
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                clr.w   (SharedSequenceState).l
                clr.w   (StoryTextState).l
                move.b  #$87,d0
                jsr     (Sound_QueueRequest).l
                addq.w  #2,(GameSubstateIndex).w
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                movea.l #SegaScreenPalette,a0
                movea.w #(PaletteShadowColor32Hi-M68K_RAM),a1
                moveq   #7,d7
Frontend_InitializeSegaScreen_CopyPalette:              ; was: loc_1D09E
                move.l  (a0)+,(a1)+
                dbf     d7,Frontend_InitializeSegaScreen_CopyPalette
                movea.w (VDPCommandQueueHead).w,a0
                move.w  #$82,-(a0)
                move.w  #$6000,-(a0)
                move.l  #SegaScreenTileArt,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+3).w,-(a0)
                move.b  #$95,-(a0)
                move.b  (DMASourceEncoding+2).w,-(a0)
                move.b  #$96,-(a0)
                move.b  (DMASourceEncoding+1).w,-(a0)
                move.b  #$97,-(a0)
                move.w  #$8F02,-(a0)
                move.l  #$94039300,-(a0)
                move.w  a0,(VDPCommandQueueHead).w
                move    #$2300,sr
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                move.w  #$10,(a0)
                move.w  #$C000,2(a0)
                move.w  #$C200,$E(a0)
                clr.b   $20(a0)
                move.l  #FrontendSegaScreenSpriteMapping,8(a0)
                move.w  #$120,$10(a0)
                move.w  #$E8,$14(a0)
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                rts
; End of function Frontend_InitializeSegaScreen
Frontend_CopyPaletteLines:                              ; was: sub_1D120
                lea     (PaletteActiveColor49).w,a0
                lea     (PaletteActiveColor01).w,a1
                lea     (PaletteShadowColor49).w,a2
                lea     (PaletteShadowColor01).w,a3
                move.w  #$E,d0
Frontend_CopyPaletteLines_NextColor:                    ; was: loc_1D134
                move.w  (a0)+,(a1)+
                move.w  (a2)+,(a3)+
                dbf     d0,Frontend_CopyPaletteLines_NextColor
                rts
; End of function Frontend_CopyPaletteLines
; Dispatches cutscene state based on frame counter
