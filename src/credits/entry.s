; Initializes credits screen
Credits_InitializeScreen:                               ; was: sub_1E16C
                tst.w   (GameSubstateIndex).w
                bne.s   Credits_ActivateScreen
                addq.w  #2,(GameSubstateIndex).w
                jsr     (Sys_InitGameMode).l
                lea     Credits_IntroAssetLoadList(pc),a0
                nop
                jsr     (LoadObjData).l
                lea     (CreditsAndEarlyStagePaletteCommandBank).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                move.b  #0,(VDPReg18Shadow+1).w
                rts
; ---------------------------------------------------------------------------
; Activates the loaded credits screen and configures its raster transition
Credits_ActivateScreen:                                 ; was: loc_1E1BE
                addq.w  #4,(GameModeIndex).w
                jsr     (Gfx_FadePaletteTransition).l
                movea.l #Credits_IntroVRAMTransferParameters,a0
                move.w  #$800,d0
                move.w  #$FF00,d1
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (PrimaryCameraYPosition).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                move.w  #0,(TransitionModeOffset).w
                jsr     (TransitionEffect_ConfigureRasterMode).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                rts
; End of function Credits_InitializeScreen
; ---------------------------------------------------------------------------
Credits_IntroAssetLoadList: dc.w    7                   ; field_0  ; was: stru_1E204
                dc.l    CreditsAndEndingTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    CreditsAndTransitionTileArtE000  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedCreditsResultsMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedCreditsResultsMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    $FFFF
Credits_IntroVRAMTransferParameters:    dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $4000  ; was: dword_1E236

; Updates the credits fade and transition raster buffers
Credits_UpdateFadeAndTransitionBuffers:                 ; was: sub_1E246
                jsr     (Gfx_FadePaletteTransition).l
                jsr     (TransitionEffect_UpdateBuffers).l
                rts
; End of function Credits_UpdateFadeAndTransitionBuffers
