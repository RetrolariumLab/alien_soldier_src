; Initializes the ending sequence's credits assets, palette, music, and scroll state
EndingSequence_Initialize:                              ; was: sub_7B30
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                jsr     (Sys_InitGameMode).l
                move.w  #1,(EndingInitWriteOnlyFlag).l
                movea.l #EndingSequence_AssetLoads,a0
                jsr     (LoadObjData).l
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                movea.w #(TileInterpSourceB-M68K_RAM),a1
                move.w  #$20,(TileInterpVRAM).w         ; ' '
                move.w  #$1F,(TileInterpStepsLeft).w
                move.w  #1,(TileInterpSpanStep).w
                jsr     (Gfx_LoadTilesLoop).l
                jsr     (Sys_ClearEntityObjectPool).l
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                move.w  #$600,d0
                move.w  #0,d1
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                lea     (CreditsAndPlanetPaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                move.w  #$FFF2,(CutscenePaletteStep).l
                move.w  (CutscenePaletteStep).l,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.b  #0,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                move.b  #$88,d0
                jsr     (Sound_QueueBGMRequest).l
                clr.w   (PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (SecondaryCameraYPos).w
                clr.w   (SecondaryCameraXPos).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                clr.w   (EndingSequenceState).w
                rts
; End of function EndingSequence_Initialize
; ---------------------------------------------------------------------------
EndingSequence_AssetLoads:  dc.w    7                   ; command: LZSS to VRAM  ; was: stru_7BF2
                dc.l    EndingSequenceTileArt2000       ; source
                dc.w    $2000                           ; destination: VRAM $2000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    CreditsAndEndingTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedCreditsResultsMappingData4020  ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedCreditsResultsMappingData6000  ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    EndingSequenceMappingData9600   ; source
                dc.w    $9600                           ; destination: RAM $FF9600
                dc.w    $FFFF

; Runs the palette effect and dispatches the complete credits-to-planet sequence
EndingSequence_Dispatch:                                ; was: sub_7C24
                jsr     (TransitionEffect_UpdateBuffers).l
                move.w  (EndingSequenceState).w,d0
                lea     EndingSequence_States(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function EndingSequence_Dispatch
; ---------------------------------------------------------------------------
EndingSequence_States:  dc.w    EndingSequence_FadeInCredits-*  ; was: off_7C36
                dc.w    EndingSequence_HoldCredits-*
                dc.w    EndingSequence_FadeOutCredits-*
                dc.w    EndingSequence_WaitStarfieldDelay-*
                dc.w    EndingStarfield_Initialize-*
                dc.w    EndingStarfield_UpdateAndHold-*
                dc.w    EndingStarfield_FadeOutAndPreparePlanet-*
                dc.w    EndingPlanet_Initialize-*
                dc.w    EndingPlanet_ShowAndDissolve-*
                dc.w    EndingPlanet_HoldDissolved-*
                dc.w    EndingPlanet_RevealPattern-*
                dc.w    EndingPlanet_RunZoom-*
                dc.w    EndingPlanet_FadeOutZoom-*

; Advances the credits palette fade every eighth frame until step zero
EndingSequence_FadeInCredits:                           ; was: sub_7C50
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Cutscene_Return
                addq.w  #2,(CutscenePaletteStep).l
                move.w  (CutscenePaletteStep).l,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                tst.w   (CutscenePaletteStep).l
                bne.w   Cutscene_Return
                move.w  #$80,(CutsceneTimer).l
                addq.w  #2,(EndingSequenceState).w
                rts
; End of function EndingSequence_FadeInCredits
; Holds the credits screen for $80 frames while animating its accent colors
EndingSequence_HoldCredits:                             ; was: sub_7C92
                bsr.w   EndingSequence_AnimateAccentColors
                subq.w  #1,(CutsceneTimer).l
                bne.w   Cutscene_Return
                clr.w   (CutscenePaletteStep).l
                addq.w  #2,(EndingSequenceState).w
                rts
; End of function EndingSequence_HoldCredits
; Alternates three accent palette words used throughout the ending sequence
EndingSequence_AnimateAccentColors:                     ; was: sub_7CAC
                                        ; EndingStarfield_Initialize:EndingStarfield_UpdateAndHold   p
                lea     (PaletteActiveColor51).w,a1
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #1,d0
                bne.s   EndingSequence_UseOddAccentColors
                lea     EndingSequence_EvenAccentColors(pc),a0
                nop
                move.w  (a0)+,(a1)+
                move.l  (a0),(a1)
                rts
; ---------------------------------------------------------------------------
EndingSequence_UseOddAccentColors:                      ; was: loc_7CC6
                lea     EndingSequence_OddAccentColors(pc),a0
                nop
                move.w  (a0)+,(a1)+
                move.l  (a0),(a1)
                rts
; End of function EndingSequence_AnimateAccentColors
; ---------------------------------------------------------------------------
EndingSequence_EvenAccentColors:    dc.w    $EA8, $E86, $E64  ; was: word_7CD2
EndingSequence_OddAccentColors:     dc.w    $A2A, $828, $626  ; was: word_7CD8

; Fades out the credits, loads starfield tiles, and seeds its first object
EndingSequence_FadeOutCredits:                          ; was: sub_7CDE
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Cutscene_Return
                addq.w  #2,(CutscenePaletteStep).l
                move.w  (CutscenePaletteStep).l,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                cmpi.w  #$E,(CutscenePaletteStep).l
                bne.w   Cutscene_Return
                movea.l #EndingSequence_StarfieldTileLoad,a0
                jsr     (Tilemap_QueueIndexedRows).l
                lea     (Entity_ObjectPool).w,a5
                move.w  #$128,PrimaryEntityXPos-Entity_ObjectPool(a5)
                move.w  #$E8,$14(a5)
                jsr     (TransitionEffect_ReplaceOwnerAndClearObjects).l
                move.w  #$2C8,(a5)
                move.w  #$10,(CutsceneTimer).l
                addq.w  #2,(EndingSequenceState).w
                rts
; End of function EndingSequence_FadeOutCredits
; ---------------------------------------------------------------------------
EndingSequence_StarfieldTileLoad:   dc.b    $44, $20, $40, 0, 2, 2, $80, $84, $88, $84, $88, $80, $84, $80, $88, $FF  ; was: byte_7D48

; Waits sixteen frames before advancing into starfield initialization
EndingSequence_WaitStarfieldDelay:                      ; was: sub_7D58
                subq.w  #1,(CutsceneTimer).l
                bne.w   Cutscene_Return
                addq.w  #2,(EndingSequenceState).w
                rts
; End of function EndingSequence_WaitStarfieldDelay
