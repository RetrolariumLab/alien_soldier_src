StoryScreen_Initialize:                                 ; DATA XREF: Sys_DispatchGameState+7A   o  ; was: sub_4840
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$40000001,(VDP_CTRL).l
                move.w  #$7FF,d0
                move.w  #0,d1
StoryScreen_ClearPlaneA:                                ; CODE XREF: StoryScreen_Initialize+28   j  ; was: loc_4866
                move.w  d1,(a0)
                dbf     d0,StoryScreen_ClearPlaneA
                move    (sp)+,sr
                move    sr,-(sp)
                move    #$2700,sr
                lea     (VDP_DATA).l,a0
                move.w  #$8F02,(VDP_CTRL).l
                move.l  #$60000002,(VDP_CTRL).l
                move.w  #$7FF,d0
                move.w  #0,d1
; Clears scroll plane B and initializes game state variables
StoryScreen_ClearPlaneB:                                ; CODE XREF: StoryScreen_Initialize+56   j  ; was: loc_4894
                move.w  d1,(a0)
                dbf     d0,StoryScreen_ClearPlaneB
                move    (sp)+,sr
                clr.w   (SharedSequenceState).l
                clr.w   (StoryTextState).l
                move.b  #4,(VDPReg18Shadow+1).w
                move.w  #$44,(RasterEffectIndex).w      ; 'D'
                clr.w   (RasterEffectInitState).w
                clr.w   (ScenePaletteFadeOffset).l
                clr.w   (PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (SecondaryCameraYPos).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                addq.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                rts
; End of function StoryScreen_Initialize
; ---------------------------------------------------------------------------
StoryScreenAssetCommands:   dc.w    7                   ; field_0  ; was: stru_48DA
                                        ; DATA XREF: StoryScreen_FadeOutAndLoadTitleAssets+36   o
                dc.l    StoryScreenTileArt0000          ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    StoryScreenMappingData4000      ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    StoryScreenMappingData6000      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    $FFFF

; Runs one story-screen frame and dispatches the current sequence state
StoryScreen_MainLoop:                                   ; DATA XREF: Sys_DispatchGameState+7E   o  ; was: sub_48FC
                btst    #0,(PaletteFadeMaskStatus).w
                beq.s   StoryScreen_RunFrame
                tst.w   (ScenePaletteFadeOffset).l
                bne.s   StoryScreen_RunFrame
                tst.w   (DataLoaderControl).w
                bmi.s   StoryScreen_RunFrame
                btst    #7,(ControllerPressedState).w
                bne.w   StoryScreen_StartExitFade
StoryScreen_RunFrame:                                   ; CODE XREF: StoryScreen_MainLoop+6   j  ; was: loc_491C
                                        ; StoryScreen_MainLoop+E   j
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                jsr     (Sys_ProcessVisibleObjects).l
                bsr.w   StoryScreen_DispatchState
                bsr.w   StoryText_Dispatch
                if      BuildProfileJP
                bsr.w   StoryFont_UpdateAndDispatch
                endif
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                addq.w  #1,(FrameCounter).w
                rts
; End of function StoryScreen_MainLoop
; Advances the shared cutscene timer and dispatches the story-screen state
StoryScreen_DispatchState:                              ; CODE XREF: StoryScreen_MainLoop+38   p  ; was: sub_495E
                subq.w  #1,(CutsceneTimer).l
                move.w  (GameSubstateIndex).w,d0
                lea     StoryScreen_StateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function StoryScreen_DispatchState
; ---------------------------------------------------------------------------
StoryScreen_StateOffsets:   dc.w    StoryScreen_StartLongTimer-*  ; DATA XREF: StoryScreen_DispatchState+A   o  ; was: off_4970
                dc.w    StoryScreen_WaitForCueTime-*
                dc.w    StoryScreen_WaitToBeginFade-*
                dc.w    StoryScreen_FadeOutAndLoadTitleAssets-*
                dc.w    StoryScreen_FadeInAndStartScroll-*
                dc.w    StoryScreen_WaitForScrollAndLoadPalette-*
                dc.w    StoryScreen_FadeInTitleScene-*
                dc.w    StoryScreen_WaitBeforeLogoTransition-*
                dc.w    StoryTitle_SetupLogoReveal-*
                dc.w    StoryTitle_RevealLogoCharacters-*
                dc.w    StoryTitle_ExpandCompletedLogo-*
                dc.w    StoryScreen_WaitThenStartExitFade-*
                dc.w    StoryScreen_ExitToTitleScreen-*

; Starts the story sequence's initial long timer
StoryScreen_StartLongTimer:                             ; DATA XREF: ROM:StoryScreen_StateOffsets   o  ; was: sub_498A
                move.w  #StoryInitialTimer,(CutsceneTimer).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_StartLongTimer
; Plays the first timed story-screen sound cue
StoryScreen_WaitForCueTime:                             ; DATA XREF: ROM:00004972   o  ; was: sub_4998
                cmpi.w  #StoryFirstCueTimer,(CutsceneTimer).l
                bne.w   Cutscene_Return
                move.b  #1,d0
                jsr     (Sound_QueueRequest).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_WaitForCueTime
; Resets the story fade accumulator at the second timed cue
StoryScreen_WaitToBeginFade:                            ; DATA XREF: ROM:00004974   o  ; was: sub_49B4
                cmpi.w  #StoryFadeCueTimer,(CutsceneTimer).l
                bne.w   Cutscene_Return
                move.w  #0,(ScenePaletteFadeOffset).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_WaitToBeginFade
; Fades out palette to dark then loads new graphics data
StoryScreen_FadeOutAndLoadTitleAssets:                  ; DATA XREF: ROM:00004976   o  ; was: sub_49CE
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Cutscene_Return
                subq.w  #2,(ScenePaletteFadeOffset).l
                move.w  (ScenePaletteFadeOffset).l,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                cmpi.w  #$FFF2,(ScenePaletteFadeOffset).l
                bne.w   Cutscene_Return
                movea.l #StoryScreenAssetCommands,a0
                jsr     (Data_ProcessPointer).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_FadeOutAndLoadTitleAssets
; Fades to target palette and sets up scrolling data
StoryScreen_FadeInAndStartScroll:                       ; DATA XREF: ROM:00004978   o  ; was: sub_4A16
                move.w  #$FFF2,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                tst.w   (DataLoaderControl).w
                bmi.w   Cutscene_Return
                move.l  #Gfx_ScrollVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                clr.w   (SecondaryCameraXPos).w
                clr.w   (SecondaryCameraYPos).w
                move.w  #0,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_FadeInAndStartScroll
; Waits for fade completion then loads tile data via DMA
StoryScreen_WaitForScrollAndLoadPalette:                ; DATA XREF: ROM:0000497A   o  ; was: sub_4A5C
                move.w  #$FFF2,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.w   Cutscene_Return
                lea     (StoryScreenPaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                move.w  #$FFF2,(ScenePaletteFadeOffset).l
                move.w  (ScenePaletteFadeOffset).l,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                move.b  #$88,d0
                jsr     (Sound_QueueRequest).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_WaitForScrollAndLoadPalette
; Fades in palette from dark to normal brightness
StoryScreen_FadeInTitleScene:                           ; DATA XREF: ROM:0000497C   o  ; was: sub_4ACE
                move.w  (VBlankFrameCounter).w,d0
                andi.w  #3,d0
                bne.w   Cutscene_Return
                addq.w  #2,(ScenePaletteFadeOffset).l
                move.w  (ScenePaletteFadeOffset).l,d0
                lea     (PaletteActiveColor01).w,a0
                move.w  #$3E,d5                         ; '>'
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                tst.w   (ScenePaletteFadeOffset).l
                bne.w   Cutscene_Return
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_FadeInTitleScene
; Plays the timed cue immediately before the logo reveal
StoryScreen_WaitBeforeLogoTransition:                   ; DATA XREF: ROM:0000497E   o  ; was: sub_4B08
                cmpi.w  #$80,(CutsceneTimer).l
                bne.w   Cutscene_Return
                move.b  #1,d0
                jsr     (Sound_QueueRequest).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryScreen_WaitBeforeLogoTransition
; Clears the planes, stages the first logo glyph, and starts its reveal effect
StoryTitle_SetupLogoReveal:                             ; DATA XREF: ROM:00004980   o  ; was: sub_4B24
                tst.w   (CutsceneTimer).l
                bne.w   Cutscene_Return
                move.b  #4,d0
                jsr     (Sound_QueueRequest).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                move.b  #0,(VDPReg18Shadow+1).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.b  #0,(VDPReg11Shadow+1).w
                move.w  #$4000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                lea     (VDP_CTRL).l,a0
                lea     (VDP_DATA).l,a1
                move.w  #$8F02,(a0)
                move.l  #$40000000,(a0)
                clr.w   d0
                move.w  #$1F,d1
StoryTitle_ClearPlaneATail:                             ; was: loc_4B96
                move.w  d0,(a1)
                dbf     d1,StoryTitle_ClearPlaneATail
                movea.l #FrontendPaletteCommands,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #$8300,d0
                move.w  #$4680,d4
                movea.l #StoryTitle_FontGlyphSequence,a0
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                move.w  #$3C,(RasterEffectIndex).w      ; '<'
                clr.w   (RasterEffectInitState).w
                move.w  #$21,(StoryTitleExpandSpan).l   ; '!'
                clr.w   (CutscenePaletteStep).l
                bsr.w   StoryTitle_UpdateRevealPalette
                move.w  #$10,(RasterLayoutOffset).w
                move.w  #$C,(StoryTitleGlyphsLeft).l
                lea     (CutsceneWorkBuffer).l,a0
                moveq   #0,d1
                move.w  #$77F,d0
StoryTitle_ClearPatternWorkspace:                       ; was: loc_4BF2
                move.l  d1,(a0)+
                dbf     d0,StoryTitle_ClearPatternWorkspace
                move.l  #StoryTitle_LogoRevealCharacters,(StoryTitleGlyphCursor).l
                movea.l (StoryTitleGlyphCursor).l,a0
                moveq   #0,d0
                move.b  (a0)+,d0
                move.l  a0,(StoryTitleGlyphCursor).l
                lsl.w   #6,d0
                addi.l  #SharedFontTileArt,d0
                movea.l d0,a0
                lea     (StoryTitleMirroredGlyph).l,a1
                move.w  #$3F,d0                         ; '?'
StoryTitle_MirrorInitialGlyphNibbles:                   ; was: loc_4C26
                move.b  (a0),d1
                andi.b  #$F0,d1
                move.b  d1,d2
                lsr.b   #4,d1
                or.b    d2,d1
                move.b  d1,(a1)+
                move.b  (a0)+,d1
                andi.b  #$F,d1
                move.b  d1,d2
                lsl.b   #4,d1
                or.b    d2,d1
                move.b  d1,(a1)+
                dbf     d0,StoryTitle_MirrorInitialGlyphNibbles
                lea     (PaletteShadowColor01).w,a0
                move.w  #2,(a0)+
                move.w  #$A,d1
                move.w  d1,(a0)+
                move.w  d1,(a0)+
                move.w  d1,(a0)+
                move.w  d1,(a0)+
                move    sr,-(sp)
                move    #$2700,sr
StoryTitle_WaitForInitialDMABus:                        ; was: loc_4C60
                bset    #0,(IO_Z80BUS).l
                bne.s   StoryTitle_WaitForInitialDMABus
                lea     (VDP_CTRL).l,a0
                move.w  (VDPReg1Shadow).w,d0
                bset    #4,d0
                move.w  d0,(a0)
                move.w  #$8F02,(a0)
                move.l  #$93009405,(a0)
                move.w  #$9500,(a0)
                move.w  #$9688,(a0)
                move.w  #$977F,(a0)
                move.l  #$60000081,(VDPCommand).w       ; DO_WRITE_TO_VRAM_AT_$6000_ADDR
                                        ; DO_OPERATION_USING_DMA
                move.w  (VDPCommand).w,(a0)
                move.w  (VDPCommand+2).w,(a0)
                move.w  (VDPReg1Shadow).w,d0
                bclr    #4,d0
                move.w  d0,(a0)
StoryTitle_FinishInitialPatternDMA:                     ; was: loc_4CAA
                bclr    #0,(IO_Z80BUS).l
                beq.s   StoryTitle_FinishInitialPatternDMA
                move    (sp)+,sr
                move    #$2300,sr
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryTitle_SetupLogoReveal
; ---------------------------------------------------------------------------
StoryTitle_FontGlyphSequence:   dc.b    0, 1, 2, 3, 4, 5, 6, 7, 8, 9  ; was: byte_4CCC
                dc.b    $A, $B, $C, $D, $E, $F, $10, $11, $12, $13
                dc.b    $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D
                dc.b    $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27
                dc.b    $FF
StoryTitle_LogoRevealCharacters:    dc.b    $B, $16, $13, $F, $18, $1D, $19, $16, $E, $13  ; was: byte_4CF5
                dc.b    $F, $1C, $FF

; Applies the current logo-reveal palette step to five active colors
StoryTitle_UpdateRevealPalette:                         ; was: sub_4D02
                lea     (PaletteActiveColor01).w,a0
                move.w  (CutscenePaletteStep).l,d0
                move.w  StoryTitle_FirstPaletteColorRamp(pc,d0.w),(a0)+
                move.w  StoryTitle_RepeatedPaletteColorRamp(pc,d0.w),d1
                move.w  d1,(a0)+
                move.w  d1,(a0)+
                move.w  d1,(a0)+
                move.w  d1,(a0)+
                rts
; End of function StoryTitle_UpdateRevealPalette
; ---------------------------------------------------------------------------
StoryTitle_RepeatedPaletteColorRamp:    dc.w    $EEE, $CCE, $AAE, $88C, $66C, $44C, $22A, $A, $A  ; was: word_4D1E
StoryTitle_FirstPaletteColorRamp:       dc.w    $666, $666, $666, $444, $444, $224, $222, 2, 2  ; was: word_4D30

; Expands each logo character, then stages the completed spaced logo
StoryTitle_RevealLogoCharacters:                        ; DATA XREF: ROM:00004982   o  ; was: sub_4D42
                cmpi.w  #1,(StoryTitleExpandSpan).l
                beq.w   StoryTitle_AdvanceRevealCharacter
                addq.w  #2,(CutscenePaletteStep).l
                bsr.w   StoryTitle_UpdateRevealPalette
                subq.w  #4,(StoryTitleExpandSpan).l
                lea     (CutsceneWorkBuffer).l,a0
                moveq   #0,d1
                move.w  #$27F,d0
StoryTitle_ClearCharacterWorkspace:                     ; was: loc_4D6A
                move.l  d1,(a0)+
                dbf     d0,StoryTitle_ClearCharacterWorkspace
                lea     (StoryTitleGlyphReadBase).l,a0
                lea     (StoryTitleLeftOrigin).l,a1
                lea     (StoryTitleLeftOrigin).l,a2
                move.w  (StoryTitleExpandSpan).l,d4
                addq.w  #1,d4
                lsr.w   #1,d4
                subq.w  #1,d4
                move.w  #$F,d6
StoryTitle_CharacterLeftNextRow:                        ; was: loc_4D92
                move.w  #3,d5
StoryTitle_CharacterLeftNextSourceByte:                 ; was: loc_4D96
                move.b  -(a0),d1
                move.w  d4,d3
StoryTitle_CharacterLeftRepeatPixel:                    ; was: loc_4D9A
                move.b  d1,(a1)
                move.w  a1,d7
                andi.w  #3,d7
                bne.s   StoryTitle_CharacterLeftAdvanceDestination
                suba.l  #$3C,a1                         ; '<'
                cmpa.l  #CutsceneWorkBuffer,a1
                bcs.s   StoryTitle_CharacterLeftAdvanceRow
StoryTitle_CharacterLeftAdvanceDestination:             ; was: loc_4DB2
                subq.l  #1,a1
                dbf     d3,StoryTitle_CharacterLeftRepeatPixel
                dbf     d5,StoryTitle_CharacterLeftNextSourceByte
StoryTitle_CharacterLeftAdvanceRow:                     ; was: loc_4DBC
                adda.l  #$C,a0
                addq.l  #4,a2
                movea.l a2,a1
                dbf     d6,StoryTitle_CharacterLeftNextRow
                lea     (StoryTitleGlyphReadBase).l,a0
                lea     (StoryTitleRightOrigin).l,a1
                lea     (StoryTitleRightOrigin).l,a2
                move.w  (StoryTitleExpandSpan).l,d4
                addq.w  #1,d4
                lsr.w   #1,d4
                subq.w  #1,d4
                move.w  #$F,d6
StoryTitle_CharacterRightNextRow:                       ; was: loc_4DEC
                move.w  #3,d5
StoryTitle_CharacterRightNextSourceByte:                ; was: loc_4DF0
                move.b  (a0)+,d1
                move.b  d1,d2
                move.w  d4,d3
StoryTitle_CharacterRightRepeatPixel:                   ; was: loc_4DF6
                move.b  d1,(a1)+
                move.w  a1,d7
                andi.w  #3,d7
                bne.s   StoryTitle_CharacterRightContinuePixel
                adda.l  #$3C,a1                         ; '<'
                cmpa.l  #(CutsceneWorkBuffer+$A00),a1
                bcc.s   StoryTitle_CharacterRightAdvanceRow
StoryTitle_CharacterRightContinuePixel:                 ; was: loc_4E0E
                dbf     d3,StoryTitle_CharacterRightRepeatPixel
                dbf     d5,StoryTitle_CharacterRightNextSourceByte
StoryTitle_CharacterRightAdvanceRow:                    ; was: loc_4E16
                addq.l  #4,a0
                addq.l  #4,a2
                movea.l a2,a1
                dbf     d6,StoryTitle_CharacterRightNextRow
StoryTitle_BuildCenteredScrollOffsets:                  ; was: loc_4E20
                lea     (StoryTitleScrollOffsets).w,a0
                move.w  #$70,d0                         ; 'p'
                move.w  #$70,d1                         ; 'p'
StoryTitle_BuildRightScrollRun:                         ; was: loc_4E2C
                move.w  (StoryTitleExpandSpan).l,d3
StoryTitle_WriteRightScrollOffset:                      ; was: loc_4E32
                move.w  d0,d4
                sub.w   d1,d4
                move.w  d4,(a0)+
                addq.w  #1,d1
                cmpi.w  #$E0,d1
                beq.s   StoryTitle_BuildLeftScrollOffsets
                dbf     d3,StoryTitle_WriteRightScrollOffset
                addq.w  #1,d0
                bra.w   StoryTitle_BuildRightScrollRun
; ---------------------------------------------------------------------------
StoryTitle_BuildLeftScrollOffsets:                      ; was: loc_4E4A
                lea     (StoryTitleScrollOffsets).w,a0
                move.w  #$6F,d0                         ; 'o'
                move.w  #$6F,d1                         ; 'o'
StoryTitle_BuildLeftScrollRun:                          ; was: loc_4E56
                move.w  (StoryTitleExpandSpan).l,d3
StoryTitle_WriteLeftScrollOffset:                       ; was: loc_4E5C
                move.w  d0,d4
                sub.w   d1,d4
                move.w  d4,-(a0)
                subq.w  #1,d1
                bmi.s   StoryTitle_QueueExpansionDMA
                dbf     d3,StoryTitle_WriteLeftScrollOffset
                subq.w  #1,d0
                bra.w   StoryTitle_BuildLeftScrollRun
; ---------------------------------------------------------------------------
StoryTitle_QueueExpansionDMA:                           ; was: loc_4E70
                movea.w (VDPCommandQueueHead).w,a0
                suba.w  #$10,a0
                move.w  a0,(VDPCommandQueueHead).w
                move.l  #$94059300,(a0)+
                move.l  #$8F02977F,(a0)+
                move.l  #$96889500,(a0)+
                move.l  #$60000081,(a0)+
                rts
; ---------------------------------------------------------------------------
StoryTitle_AdvanceRevealCharacter:                      ; was: loc_4E96
                move.b  #$12,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$21,(StoryTitleExpandSpan).l   ; '!'
                clr.w   (CutscenePaletteStep).l
                lea     (CutsceneWorkBuffer).l,a0
                moveq   #0,d1
                move.w  #$27F,d0
StoryTitle_ClearNextCharacterWorkspace:                 ; was: loc_4EBA
                move.l  d1,(a0)+
                dbf     d0,StoryTitle_ClearNextCharacterWorkspace
                subq.w  #1,(StoryTitleGlyphsLeft).l
                beq.w   StoryTitle_BuildCompletedLogo
                movea.l (StoryTitleGlyphCursor).l,a0
                moveq   #0,d0
                move.b  (a0)+,d0
                move.l  a0,(StoryTitleGlyphCursor).l
                lsl.w   #6,d0
                addi.l  #SharedFontTileArt,d0
                movea.l d0,a0
                lea     (StoryTitleMirroredGlyph).l,a1
                move.w  #$3F,d0                         ; '?'
StoryTitle_MirrorNextGlyphNibbles:                      ; was: loc_4EEE
                move.b  (a0),d1
                andi.b  #$F0,d1
                move.b  d1,d2
                lsr.b   #4,d1
                or.b    d2,d1
                move.b  d1,(a1)+
                move.b  (a0)+,d1
                andi.b  #$F,d1
                move.b  d1,d2
                lsl.b   #4,d1
                or.b    d2,d1
                move.b  d1,(a1)+
                dbf     d0,StoryTitle_MirrorNextGlyphNibbles
                rts
; ---------------------------------------------------------------------------
StoryTitle_BuildCompletedLogo:                          ; was: loc_4F10
                lea     (StoryTitleLogoPixels).l,a1
                movea.l #StoryTitle_CompletedLogoCharacters,a2
                move.w  #$C,d3
StoryTitle_CompletedLogoNextCharacter:                  ; was: loc_4F20
                moveq   #0,d0
                move.b  (a2)+,d0
                lsl.w   #6,d0
                addi.l  #SharedFontTileArt,d0
                movea.l d0,a0
                move.w  #$3F,d0                         ; '?'
StoryTitle_MirrorCompletedGlyphNibbles:                 ; was: loc_4F32
                move.b  (a0),d1
                andi.b  #$F0,d1
                move.b  d1,d2
                lsr.b   #4,d1
                or.b    d2,d1
                move.b  d1,(a1)+
                move.b  (a0)+,d1
                andi.b  #$F,d1
                move.b  d1,d2
                lsl.b   #4,d1
                or.b    d2,d1
                move.b  d1,(a1)+
                dbf     d0,StoryTitle_MirrorCompletedGlyphNibbles
                dbf     d3,StoryTitle_CompletedLogoNextCharacter
                move    sr,-(sp)
                move    #$2700,sr
StoryTitle_WaitForCompletedLogoDMABus:                  ; was: loc_4F5C
                bset    #0,(IO_Z80BUS).l
                bne.s   StoryTitle_WaitForCompletedLogoDMABus
                lea     (VDP_CTRL).l,a0
                move.w  (VDPReg1Shadow).w,d0
                bset    #4,d0
                move.w  d0,(a0)
                move.w  #$8F02,(a0)
                move.l  #$93009405,(a0)
                move.w  #$9500,(a0)
                move.w  #$9688,(a0)
                move.w  #$977F,(a0)
                move.l  #$60000081,(VDPCommand).w       ; DO_WRITE_TO_VRAM_AT_$6000_ADDR
                                        ; DO_OPERATION_USING_DMA
                move.w  (VDPCommand).w,(a0)
                move.w  (VDPCommand+2).w,(a0)
                move.w  (VDPReg1Shadow).w,d0
                bclr    #4,d0
                move.w  d0,(a0)
StoryTitle_FinishCompletedLogoDMA:                      ; was: loc_4FA6
                bclr    #0,(IO_Z80BUS).l
                beq.s   StoryTitle_FinishCompletedLogoDMA
                move    (sp)+,sr
                move    #$2300,sr
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryTitle_RevealLogoCharacters
; ---------------------------------------------------------------------------
StoryTitle_CompletedLogoCharacters: dc.b    $B, $16, $13, $F, $18, 0, $1D, $19, $16, $E, $13, $F, $1C, $FF  ; was: byte_4FC8

; Expands the complete spaced logo and reuses the centered scroll/DMA tail
StoryTitle_ExpandCompletedLogo:                         ; DATA XREF: ROM:00004984   o  ; was: sub_4FD6
                cmpi.w  #1,(StoryTitleExpandSpan).l
                beq.w   StoryTitle_FinishCompletedLogoExpansion
                addq.w  #2,(CutscenePaletteStep).l
                bsr.w   StoryTitle_UpdateRevealPalette
                subq.w  #4,(StoryTitleExpandSpan).l
                lea     (CutsceneWorkBuffer).l,a0
                moveq   #0,d1
                move.w  #$27F,d0
StoryTitle_ClearCompletedLogoWorkspace:                 ; was: loc_4FFE
                move.l  d1,(a0)+
                dbf     d0,StoryTitle_ClearCompletedLogoWorkspace
                lea     (StoryTitleGlyphReadBase).l,a0
                movea.l a0,a2
                lea     (StoryTitleLeftOrigin).l,a1
                movea.l a1,a3
                move.w  (StoryTitleExpandSpan).l,d4
                addq.w  #1,d4
                lsr.w   #1,d4
                subq.w  #1,d4
                move.w  #$F,d6
StoryTitle_CompletedLogoLeftNextRow:                    ; was: loc_5024
                move.w  #$33,d5                         ; '3'
StoryTitle_CompletedLogoLeftNextSourceByte:             ; was: loc_5028
                move.b  -(a0),d1
                move.w  d4,d3
StoryTitle_CompletedLogoLeftRepeatPixel:                ; was: loc_502C
                move.b  d1,(a1)
                move.w  a1,d7
                andi.w  #3,d7
                bne.s   StoryTitle_CompletedLogoLeftAdvanceDestination
                suba.l  #$3C,a1                         ; '<'
                cmpa.l  #CutsceneWorkBuffer,a1
                bcs.s   StoryTitle_CompletedLogoLeftAdvanceRow
StoryTitle_CompletedLogoLeftAdvanceDestination:         ; was: loc_5044
                subq.l  #1,a1
                dbf     d3,StoryTitle_CompletedLogoLeftRepeatPixel
                move.w  a0,d7
                andi.w  #7,d7
                bne.s   StoryTitle_CompletedLogoLeftContinueSource
                suba.l  #$78,a0                         ; 'x'
                cmpa.l  #(CutsceneWorkBuffer+$A00),a0
                bcs.s   StoryTitle_CompletedLogoLeftAdvanceRow
StoryTitle_CompletedLogoLeftContinueSource:             ; was: loc_5060
                dbf     d5,StoryTitle_CompletedLogoLeftNextSourceByte
StoryTitle_CompletedLogoLeftAdvanceRow:                 ; was: loc_5064
                addq.l  #8,a2
                movea.l a2,a0
                addq.l  #4,a3
                movea.l a3,a1
                dbf     d6,StoryTitle_CompletedLogoLeftNextRow
                lea     (StoryTitleGlyphReadBase).l,a0
                movea.l a0,a2
                lea     (StoryTitleRightOrigin).l,a1
                movea.l a1,a3
                move.w  (StoryTitleExpandSpan).l,d4
                addq.w  #1,d4
                lsr.w   #1,d4
                subq.w  #1,d4
                move.w  #$F,d6
StoryTitle_CompletedLogoRightNextRow:                   ; was: loc_5090
                move.w  #$33,d5                         ; '3'
StoryTitle_CompletedLogoRightNextSourceByte:            ; was: loc_5094
                move.b  (a0)+,d1
                move.b  d1,d2
                move.w  d4,d3
StoryTitle_CompletedLogoRightRepeatPixel:               ; was: loc_509A
                move.b  d1,(a1)+
                move.w  a1,d7
                andi.w  #3,d7
                bne.s   StoryTitle_CompletedLogoRightContinuePixel
                adda.l  #$3C,a1                         ; '<'
                cmpa.l  #(CutsceneWorkBuffer+$A00),a1
                bcc.s   StoryTitle_CompletedLogoRightAdvanceRow
StoryTitle_CompletedLogoRightContinuePixel:             ; was: loc_50B2
                dbf     d3,StoryTitle_CompletedLogoRightRepeatPixel
                move.w  a0,d7
                andi.w  #7,d7
                bne.s   StoryTitle_CompletedLogoRightContinueSource
                adda.l  #$78,a0                         ; 'x'
                cmpa.l  #(CutsceneWorkBuffer+$1E00),a0
                bcc.s   StoryTitle_CompletedLogoRightAdvanceRow
StoryTitle_CompletedLogoRightContinueSource:            ; was: loc_50CC
                dbf     d5,StoryTitle_CompletedLogoRightNextSourceByte
StoryTitle_CompletedLogoRightAdvanceRow:                ; was: loc_50D0
                addq.l  #8,a2
                movea.l a2,a0
                addq.l  #4,a3
                movea.l a3,a1
                dbf     d6,StoryTitle_CompletedLogoRightNextRow
                bra.w   StoryTitle_BuildCenteredScrollOffsets
; ---------------------------------------------------------------------------
StoryTitle_FinishCompletedLogoExpansion:                ; was: loc_50E0
                move.b  #$38,d0                         ; '8'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #StoryLogoExpansionWait,(CutsceneTimer).l
                addq.w  #2,(GameSubstateIndex).w
                rts
; End of function StoryTitle_ExpandCompletedLogo
; Waits after the logo expansion, then starts the common exit fade
StoryScreen_WaitThenStartExitFade:                      ; DATA XREF: ROM:00004986   o  ; was: sub_50F8
                subq.w  #1,(CutsceneTimer).l
                bne.w   Cutscene_Return
StoryScreen_StartExitFade:                              ; was: loc_5102
                                        ; Frontend_RevealFinalOpeningPattern+44   j
                bclr    #0,(PaletteFadeMaskStatus).w
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                move.b  #1,d0
                jsr     (Sound_QueueRequest).l
                move.w  #$18,(GameSubstateIndex).w
                rts
; End of function StoryScreen_WaitThenStartExitFade
; Switches to the title initializer after the exit fade signals completion
StoryScreen_ExitToTitleScreen:                          ; DATA XREF: ROM:00004988   o  ; was: sub_5130
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.w   Cutscene_Return
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
Cutscene_Return:                                        ; was: locret_514E
                rts
; End of function StoryScreen_ExitToTitleScreen
