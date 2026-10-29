; Palette transition stepping and selected-channel CRAM adjustments
; The selected-channel mask uses bits 15, 14, and 13 for red, green, and blue

Gfx_FadePaletteTransition:                              ; was: sub_39AA
                                        ; StoryScreen_WaitThenStartExitFade+20   p
                move.w  (PaletteFadeMode).w,d0
                beq.w   Gfx_FadePaletteTransition_Return
                moveq   #0,d5
                move.w  (VBlankFrameCounter).w,d1
                andi.w  #3,d1
                btst    #1,d0
                bne.s   Gfx_FadePaletteTransition_HandleSecondMode
                btst    #0,(PaletteFadeControlFlags).w
                bne.s   Gfx_FadePaletteTransition_FinishFirstMode
                tst.w   d0
                bpl.s   Gfx_FadePaletteTransition_CheckForwardCompletion
                tst.w   (PaletteFadeColorOffset).w
                beq.s   Gfx_FadePaletteTransition_FinishFirstMode
                moveq   #$FFFFFFFE,d5
                bra.s   Gfx_FadePaletteTransition_ApplyStep
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_CheckForwardCompletion:       ; was: loc_39D8
                tst.w   (PaletteFadeColorOffset).w
                bmi.s   Gfx_FadePaletteTransition_IncreaseFirstModeStep
Gfx_FadePaletteTransition_FinishFirstMode:              ; was: loc_39DE
                                        ; Gfx_FadePaletteTransition+28   j
                clr.w   (PaletteFadeColorOffset).w
                clr.w   (PaletteFadeMode).w
                bset    #0,(PaletteFadeMaskStatus).w
                rts
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_IncreaseFirstModeStep:        ; was: loc_39EE
                moveq   #2,d5
                bra.s   Gfx_FadePaletteTransition_ApplyStep
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_HandleSecondMode:             ; was: loc_39F2
                btst    #1,(PaletteFadeControlFlags).w
                bne.s   Gfx_FadePaletteTransition_FinishSecondMode
                tst.w   d0
                bpl.s   Gfx_FadePaletteTransition_CheckReverseLimit
                cmpi.w  #$10,(PaletteFadeColorOffset).w
                bpl.s   Gfx_FadePaletteTransition_FinishSecondMode
                btst    #2,(PaletteFadeControlFlags).w
                beq.s   Gfx_FadePaletteTransition_IncreaseSecondModeStep
                tst.w   d1
                bne.s   Gfx_FadePaletteTransition_ApplyStep
Gfx_FadePaletteTransition_IncreaseSecondModeStep:       ; was: loc_3A12
                moveq   #2,d5
                bra.s   Gfx_FadePaletteTransition_ApplyStep
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_CheckReverseLimit:            ; was: loc_3A16
                cmpi.w  #$FFF0,(PaletteFadeColorOffset).w
                bpl.s   Gfx_FadePaletteTransition_ChooseReverseStep
Gfx_FadePaletteTransition_FinishSecondMode:             ; was: loc_3A1E
                                        ; Gfx_FadePaletteTransition+5A   j
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                clr.w   (PaletteFadeMode).w
                bset    #1,(PaletteFadeMaskStatus).w
                rts
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_ChooseReverseStep:            ; was: loc_3A30
                btst    #2,(PaletteFadeControlFlags).w
                beq.s   Gfx_FadePaletteTransition_DecreaseSecondModeStep
                tst.w   d1
                bne.s   Gfx_FadePaletteTransition_ApplyStep
Gfx_FadePaletteTransition_DecreaseSecondModeStep:       ; was: loc_3A3C
                moveq   #$FFFFFFFE,d5
Gfx_FadePaletteTransition_ApplyStep:                    ; was: loc_3A3E
                                        ; Gfx_FadePaletteTransition+46   j
                movea.w #(PaletteShadowBuffer-M68K_RAM),a0
                movea.w #(PaletteActiveBuffer-M68K_RAM),a1
                move.w  (PaletteFadeColorOffset).w,d0
                move.w  d0,d1
                move.w  d0,d2
                move.w  d0,d3
                move.w  (PaletteFadeMaskStatus).w,d0
                cmpi.w  #$E000,d0
                bne.s   Gfx_FadePaletteTransition_SelectGreenAndBlueChannels
                move.w  #$8000,d0
                add.w   d5,d3
                bra.s   Gfx_FadePaletteTransition_ApplyPalette
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_SelectGreenAndBlueChannels:   ; was: loc_3A62
                cmpi.w  #$8000,d0
                bne.s   Gfx_FadePaletteTransition_SelectAllColorChannels
                move.w  #$C000,d0
                add.w   d5,d3
                add.w   d5,d2
                bra.s   Gfx_FadePaletteTransition_ApplyPalette
; ---------------------------------------------------------------------------
Gfx_FadePaletteTransition_SelectAllColorChannels:       ; was: loc_3A72
                move.w  #$E000,d0
                add.w   d5,d3
                add.w   d5,d2
                add.w   d5,d1
                add.w   d5,(PaletteFadeColorOffset).w
Gfx_FadePaletteTransition_ApplyPalette:                 ; was: loc_3A80
                                        ; Gfx_FadePaletteTransition+C6   j
                move.w  d0,(PaletteFadeMaskStatus).w
                asl.w   #4,d2
                asl.w   #8,d3
                move.w  #$E000,d0
                moveq   #$3F,d5                         ; '?'
Gfx_FadePaletteTransition_ColorLoop:                    ; was: loc_3A8E
                move.w  (a0)+,d6
                bsr.w   Gfx_AdjustSelectedColorChannels
                move.w  d6,(a1)+
                dbf     d5,Gfx_FadePaletteTransition_ColorLoop
Gfx_FadePaletteTransition_Return:                       ; was: locret_3A9A
                rts
; End of function Gfx_FadePaletteTransition
; Unreferenced helper that applies one adjustment and mirrors it to the paired range
UnreferencedAdjustAndMirrorPaletteRange:                ; was: sub_3A9C
                move.w  a0,d1
                addi.w  #$80,d1
                movea.w d1,a1
                bsr.w   Gfx_ExpandColorAdjustmentToRGBChannels
                move.w  d7,d0
UnreferencedAdjustAndMirrorPaletteRange_ColorLoop:      ; was: loc_3AAA
                move.w  (a0),d6
                bsr.w   Gfx_AdjustSelectedColorChannels
                move.w  d6,(a0)+
                move.w  d6,(a1)+
                dbf     d5,UnreferencedAdjustAndMirrorPaletteRange_ColorLoop
                rts
; End of function UnreferencedAdjustAndMirrorPaletteRange
; Applies a frame/RNG-selected color adjustment to active colors 49-63 except 54
Gfx_UpdateRandomizedPaletteRange:                       ; was: sub_3ABA
                                        ; Boss_JetsripperDeathFade   p
                bsr.s   Gfx_SelectRandomizedColorAdjustment
                move.w  (PaletteShadowColor54).w,(PaletteColorPair).w
                move.w  (PaletteActiveColor54).w,(PaletteColorPair+2).w
                movea.w #(PaletteActiveColor49-M68K_RAM),a0
                moveq   #$E,d5
                bsr.s   Gfx_ApplyPaletteFade
                move.w  (PaletteColorPair).w,(PaletteShadowColor54).w
                move.w  (PaletteColorPair+2).w,(PaletteActiveColor54).w
                rts
; End of function Gfx_UpdateRandomizedPaletteRange
; Computes randomized channel deltas, then applies them to a counted palette-entry list
Gfx_UpdateRandomizedPaletteEntryList:                   ; was: sub_3ADE
                                        ; Boss_ViblackUpdateDefeatEffectsAndParticles+6   p
                bsr.s   Gfx_SelectRandomizedColorAdjustment
                bra.w   Gfx_AdjustPaletteEntryList
; End of function Gfx_UpdateRandomizedPaletteEntryList
; Selects a signed color adjustment and channel mask from frame phase and RNG
Gfx_SelectRandomizedColorAdjustment:                    ; was: sub_3AE4
                                        ; Gfx_UpdateRandomizedPaletteEntryList   p
                moveq   #$E,d0
                move.w  #$E000,d7
                move.w  (FrameCounter).w,d1
                andi.w  #$7F,d1
                bne.s   Gfx_SelectRandomizedColorAdjustment_UseRandomizedValues
                btst    #2,(RandomNumberState+1).w
                beq.s   Gfx_SelectRandomizedColorAdjustment_Return
Gfx_SelectRandomizedColorAdjustment_UseRandomizedValues:  ; was: loc_3AFC
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                addq.w  #6,d0
                move.w  #$8000,d7
                move.w  (FrameCounter).w,d1
                andi.w  #$1F,d1
                beq.s   Gfx_SelectRandomizedColorAdjustment_Return
                move.b  (RandomNumberState).w,d1
                andi.w  #3,d1
                beq.s   Gfx_SelectRandomizedColorAdjustment_Return
                neg.w   d0
                subq.w  #2,d0
                move.w  #$6000,d7
Gfx_SelectRandomizedColorAdjustment_Return:             ; was: locret_3B26
                                        ; Gfx_SelectRandomizedColorAdjustment+2E   j
                rts
; End of function Gfx_SelectRandomizedColorAdjustment
; Applies a caller-provided adjustment to all 64 active-palette colors
Gfx_ApplyFullActivePaletteFade:                         ; was: sub_3B28
                                        ; Stage12To13_UpdateTeleportFadeIn:Stage12To13_ClampAndApplyTeleportFadeLevel   j
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                moveq   #$3F,d5                         ; '?'
                move.w  #$E000,d7
; Falls through to Gfx_ApplyPaletteFade
; Applies fade to palette colors with RGB adjustment
Gfx_ApplyPaletteFade:                                   ; was: sub_3B32
                                        ; StoryScreen_FadeOutAndLoadTitleAssets+24   p
                movea.w a0,a1
                lea     $80(a1),a1
                bsr.w   Gfx_ExpandColorAdjustmentToRGBChannels
                move.w  d7,d0
Gfx_ApplyPaletteFade_ColorLoop:                         ; was: loc_3B3E
                move.w  (a1)+,d6
                bsr.w   Gfx_AdjustSelectedColorChannels
                move.w  d6,(a0)+
                dbf     d5,Gfx_ApplyPaletteFade_ColorLoop
                rts
; End of function Gfx_ApplyPaletteFade
; Applies selected RGB deltas to a counted list of palette-entry addresses
Gfx_AdjustPaletteEntryList:                             ; was: sub_3B4C
                                        ; Gfx_BugmaxApplyWavePaletteOffset+36   j
                move.w  (a4)+,d5
                bsr.w   Gfx_ExpandColorAdjustmentToRGBChannels
                move.w  d7,d0
Gfx_AdjustPaletteEntryList_ColorLoop:                   ; was: loc_3B54
                movea.w (a4)+,a0
                move.w  $80(a0),d6
                bsr.w   Gfx_AdjustSelectedColorChannels
                move.w  d6,(a0)
                dbf     d5,Gfx_AdjustPaletteEntryList_ColorLoop
                rts
; End of function Gfx_AdjustPaletteEntryList
; Expands one color adjustment into red, green, and blue CRAM channel positions
Gfx_ExpandColorAdjustmentToRGBChannels:                 ; was: sub_3B66
                                        ; Gfx_ApplyPaletteFade+6   p
                move.w  d0,d1
                move.w  d0,d2
                move.w  d0,d3
                asl.w   #4,d2
                asl.w   #8,d3
                rts
; End of function Gfx_ExpandColorAdjustmentToRGBChannels
; Unreferenced helper that adds wrapping RGB channels and writes the paired entry
UnreferencedAddWrappingColorAdjustmentToPairedEntry:    ; was: sub_3B72
                move.w  d0,d1
                move.w  d0,d2
                move.w  d0,d3
                move.w  (a0),d4
                move.w  (a0),d5
                move.w  (a0),d6
                add.w   d1,d4
                add.w   d2,d5
                add.w   d3,d6
                andi.w  #$E,d4
                andi.w  #$E0,d5
                andi.w  #$E00,d6
                or.w    d4,d5
                or.w    d5,d6
                move.w  d6,-$80(a0)
                rts
; End of function UnreferencedAddWrappingColorAdjustmentToPairedEntry
; Adjusts the selected red, green, and blue channels of one CRAM color word
Gfx_AdjustSelectedColorChannels:                        ; was: sub_3B9A
                                        ; UnreferencedAdjustAndMirrorPaletteRange+10   p
                move.w  d6,d7
                btst    #$F,d0
                beq.s   Gfx_AdjustSelectedColorChannels_CheckGreen
                move.w  d6,d7
                andi.w  #$E,d7
                add.w   d1,d7
                bpl.s   Gfx_AdjustSelectedColorChannels_ClampRedMaximum
                clr.w   d7
                bra.s   Gfx_AdjustSelectedColorChannels_StoreRed
; ---------------------------------------------------------------------------
Gfx_AdjustSelectedColorChannels_ClampRedMaximum:        ; was: loc_3BB0
                cmpi.w  #$F,d7
                bmi.s   Gfx_AdjustSelectedColorChannels_StoreRed
                moveq   #$E,d7
Gfx_AdjustSelectedColorChannels_StoreRed:               ; was: loc_3BB8
                                        ; Gfx_AdjustSelectedColorChannels+1A   j
                andi.w  #$FFF0,d6
                or.w    d7,d6
Gfx_AdjustSelectedColorChannels_CheckGreen:             ; was: loc_3BBE
                btst    #$E,d0
                beq.s   Gfx_AdjustSelectedColorChannels_CheckBlue
                move.w  d6,d7
                andi.w  #$E0,d7
                add.w   d2,d7
                bpl.s   Gfx_AdjustSelectedColorChannels_ClampGreenMaximum
                clr.w   d7
                bra.s   Gfx_AdjustSelectedColorChannels_StoreGreen
; ---------------------------------------------------------------------------
Gfx_AdjustSelectedColorChannels_ClampGreenMaximum:      ; was: loc_3BD2
                cmpi.w  #$E1,d7
                bmi.s   Gfx_AdjustSelectedColorChannels_StoreGreen
                move.w  #$E0,d7
Gfx_AdjustSelectedColorChannels_StoreGreen:             ; was: loc_3BDC
                                        ; Gfx_AdjustSelectedColorChannels+3C   j
                andi.w  #$FF0F,d6
                or.w    d7,d6
Gfx_AdjustSelectedColorChannels_CheckBlue:              ; was: loc_3BE2
                btst    #$D,d0
                beq.s   Gfx_AdjustSelectedColorChannels_Return
                move.w  d6,d7
                andi.w  #$E00,d7
                add.w   d3,d7
                bpl.s   Gfx_AdjustSelectedColorChannels_ClampBlueMaximum
                clr.w   d7
                bra.s   Gfx_AdjustSelectedColorChannels_StoreBlue
; ---------------------------------------------------------------------------
Gfx_AdjustSelectedColorChannels_ClampBlueMaximum:       ; was: loc_3BF6
                cmpi.w  #$E01,d7
                bmi.s   Gfx_AdjustSelectedColorChannels_StoreBlue
                move.w  #$E00,d7
Gfx_AdjustSelectedColorChannels_StoreBlue:              ; was: loc_3C00
                                        ; Gfx_AdjustSelectedColorChannels+60   j
                andi.w  #$F0FF,d6
                or.w    d7,d6
Gfx_AdjustSelectedColorChannels_Return:                 ; was: locret_3C06
                rts
; End of function Gfx_AdjustSelectedColorChannels
