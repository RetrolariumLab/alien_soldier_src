; Dispatches the three-state Sega-screen pattern transition
Frontend_DispatchSegaScreenTransition:                  ; was: sub_1D13E
                move.w  (SharedSequenceState).l,d0
                lea     SegaScreenTransitionStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Frontend_DispatchSegaScreenTransition
; ---------------------------------------------------------------------------
SegaScreenTransitionStateOffsets:   dc.w    Frontend_EraseSegaScreenPattern-*  ; was: off_1D14C
                dc.w    Frontend_WaitAfterSegaPatternErase-*
                dc.w    Frontend_RevealSegaScreenPattern-*

; Erases the Sega-screen sprite-grid pattern and starts its hold timer
Frontend_EraseSegaScreenPattern:                        ; was: sub_1D152
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                jsr     (Cutscene_ErasePlanetPatternStep).l
                cmpi.w  #$40,(PatternDissolveStep).l    ; '@'
                bne.w   FrontendTransition_Return
                move.w  #$40,(FrontendHoldTimer).w      ; '@'
                addq.w  #2,(SharedSequenceState).l
                rts
; End of function Frontend_EraseSegaScreenPattern
; Waits for the Sega-screen erase hold timer
Frontend_WaitAfterSegaPatternErase:                     ; was: sub_1D178
                subq.w  #1,(FrontendHoldTimer).w
                bne.w   FrontendTransition_Return
                addq.w  #2,(SharedSequenceState).l
                rts
; End of function Frontend_WaitAfterSegaPatternErase
; Reveals the Sega-screen sprite-grid pattern and advances to the title transition
Frontend_RevealSegaScreenPattern:                       ; was: sub_1D188
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                jsr     (Cutscene_RevealPlanetPatternStep).l
                tst.w   (PatternDissolveStep).l
                bpl.w   FrontendTransition_Return
                move.w  #$80,(FrontendHoldTimer).w
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function Frontend_RevealSegaScreenPattern
; Loads the palette, graphics, mapping, and sprite-grid state for the title transition
Frontend_InitializeTitleTransition:                     ; was: sub_1D1AA
                addq.w  #2,(GameSubstateIndex).w
                movea.l #FrontendTitleTransitionPalette,a0
                movea.w #(PaletteActiveColor32-M68K_RAM),a1
                moveq   #7,d7
Frontend_InitializeTitleTransition_CopyPalette:         ; was: loc_1D1BA
                move.l  (a0)+,(a1)+
                dbf     d7,Frontend_InitializeTitleTransition_CopyPalette
                movea.l #FrontendTitleTransitionAssetLoadList,a0
                jsr     (Data_ProcessPointer).l
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                move.w  #$10,(a0)
                move.w  #$C000,2(a0)
                move.w  #$C200,$E(a0)
                clr.b   $20(a0)
                move.l  #FrontendTitleTransitionSpriteMapping,8(a0)
                move.w  #$120,$10(a0)
                move.w  #$E4,$14(a0)
                move.w  #$400,(SpriteGridFirstTile).l
                move.w  #$E8,(SpriteGridCenterY).l
                move.w  #$120,(SpriteGridCenterX).l
                move.w  #2,(SpriteGridRowLimit).l
                move.w  #1,(SpriteGridColumnLimit).l
                move.l  #$40000002,(PatternVDPCommand).l
                move.w  #$F,(PlanetPatternWriteOnly).l
                move.w  #0,(PatternFrameMask).l
                clr.w   (PatternDissolveStep).l
                jsr     (Cutscene_FillPlanetPattern).l
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                clr.w   (SharedSequenceState).l
                rts
; End of function Frontend_InitializeTitleTransition
; ---------------------------------------------------------------------------
FrontendTitleTransitionAssetLoadList:   dc.w    7       ; command: LZSS to VRAM  ; was: stru_1D254
                dc.l    FrontendTitleTransitionTileArtA000  ; source
                dc.w    $A000                           ; destination: VRAM $A000
                dc.w    $FFFF
FrontendTitleTransitionPalette: dc.l    0, $EEE0F00     ; was: dword_1D25E
                dc.l    2, $E240602
                dc.l    $AE0000, 0
                dc.l    0, 0

; Dispatches the seven-state transition from the title patterns into the story screen
Frontend_DispatchTitleTransition:                       ; was: sub_1D27E
                move.w  (SharedSequenceState).l,d0
                lea     FrontendTitleTransitionStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Frontend_DispatchTitleTransition
; ---------------------------------------------------------------------------
FrontendTitleTransitionStateOffsets:    dc.w    Frontend_EraseTitleTransitionPattern-*  ; was: off_1D28C
                dc.w    Frontend_WaitAfterFirstTitlePatternErase-*
                dc.w    Frontend_RevealTitlePatternAndSetupNextGrid-*
                dc.w    Frontend_EraseTitleTransitionPattern-*
                dc.w    Frontend_WaitAfterSecondTitlePatternErase-*
                dc.w    Frontend_RevealFinalOpeningPattern-*
                dc.w    Frontend_EnterStoryScreen-*

; Erases the current title-transition sprite-grid pattern
Frontend_EraseTitleTransitionPattern:                   ; was: sub_1D29A
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                jsr     (Cutscene_ErasePlanetPatternStep).l
                cmpi.w  #$40,(PatternDissolveStep).l    ; '@'
                bne.w   FrontendTransition_Return
                move.w  #$40,(FrontendHoldTimer).w      ; '@'
                addq.w  #2,(SharedSequenceState).l
                rts
; End of function Frontend_EraseTitleTransitionPattern
; Waits after erasing the first title-transition pattern
Frontend_WaitAfterFirstTitlePatternErase:               ; was: sub_1D2C0
                subq.w  #1,(FrontendHoldTimer).w
                bne.w   FrontendTransition_Return
                addq.w  #2,(SharedSequenceState).l
                rts
; End of function Frontend_WaitAfterFirstTitlePatternErase
; Reveals the current title pattern, then configures the next sprite grid
Frontend_RevealTitlePatternAndSetupNextGrid:            ; was: sub_1D2D0
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                jsr     (Cutscene_RevealPlanetPatternStep).l
                tst.w   (PatternDissolveStep).l
                bpl.w   FrontendTransition_Return
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                move.w  #$10,(a0)
                move.w  #$C000,2(a0)
                move.w  #$A000,$E(a0)
                clr.b   $20(a0)
                move.l  #FrontendFinalOpeningSpriteGridMapping,8(a0)
                move.w  #$120,$10(a0)
                move.w  #$E8,$14(a0)
                move.w  #$400,(SpriteGridFirstTile).l
                move.w  #$E8,(SpriteGridCenterY).l
                move.w  #$120,(SpriteGridCenterX).l
                move.w  #1,(SpriteGridRowLimit).l
                move.w  #5,(SpriteGridColumnLimit).l
                move.l  #$40000002,(PatternVDPCommand).l
                move.w  #$F,(PlanetPatternWriteOnly).l
                move.w  #0,(PatternFrameMask).l
                clr.w   (PatternDissolveStep).l
                jsr     (Cutscene_FillPlanetPattern).l
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                addq.w  #2,(SharedSequenceState).l
                rts
; End of function Frontend_RevealTitlePatternAndSetupNextGrid
; Waits after erasing the second title-transition pattern
Frontend_WaitAfterSecondTitlePatternErase:              ; was: sub_1D36E
                subq.w  #1,(FrontendHoldTimer).w
                bne.w   FrontendTransition_Return
                addq.w  #2,(SharedSequenceState).l
                rts
; End of function Frontend_WaitAfterSecondTitlePatternErase
; Reveals the final opening pattern and selects the terminal story-transition state
Frontend_RevealFinalOpeningPattern:                     ; was: sub_1D37E
                jsr     (Cutscene_RenderPlanetSpriteGrid).l
                jsr     (Cutscene_RevealPlanetPatternStep).l
                tst.w   (PatternDissolveStep).l
                bpl.w   FrontendTransition_Return
                clr.w   (PrimaryEntityFlags).w
                move.w  #6,(GameSubstateIndex).w
                move.w  #$C,(SharedSequenceState).l
                rts
; End of function Frontend_RevealFinalOpeningPattern
; ---------------------------------------------------------------------------
; Handles a request to skip the active opening sequence
Frontend_HandleOpeningSkip:                             ; was: loc_1D3A8
                cmpi.w  #6,(GameSubstateIndex).w
                bne.s   Frontend_StartStoryExitForOpeningSkip
                cmpi.w  #$C,(SharedSequenceState).l
                beq.w   FrontendTransition_Return
Frontend_StartStoryExitForOpeningSkip:                  ; was: loc_1D3BC
                move.w  #$28,(GameModeIndex).w          ; '('
                jmp     (StoryScreen_StartExitFade).l
; End of function Frontend_HandleOpeningSkip
