; Per-frame palette animation dispatchers and their stage/boss color handlers

; Runs the primary palette-effect slot while normal frame processing is active
Palette_UpdatePrimaryEffect:                            ; was: sub_4094
                tst.b   (FrameControlFlags).w
                bpl.s   Palette_UpdatePrimaryEffect_Dispatch
                rts
; ---------------------------------------------------------------------------
Palette_UpdatePrimaryEffect_Dispatch:                   ; was: loc_409C
                move.w  (PalettePrimaryIndex).w,d0
                movea.w Palette_PrimaryEffectOffsets(pc,d0.w),a0
                adda.l  #Palette_UpdateSharedAnimatedColors,a0
                jmp     (a0)
; End of function Palette_UpdatePrimaryEffect
; ---------------------------------------------------------------------------
Palette_PrimaryEffectOffsets:   dc.w    Palette_EffectReturn-Palette_UpdateSharedAnimatedColors  ; was: off_40AC
                dc.w    Palette_UpdateSharedAnimatedColors-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_SelectSharedAccentColor-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_UpdateStage2BlinkColor-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_UpdateLightningFlash-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_UpdateEpsilon1Colors-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_UpdateMidgameColors-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_UpdateShieldViperColors-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_ToggleThreeHighlightColors-Palette_UpdateSharedAnimatedColors
                dc.w    Palette_UpdateWolfGaropaColors-Palette_UpdateSharedAnimatedColors

; Alternates two shared colors, then advances the eight-step accent-color cycle
Palette_UpdateSharedAnimatedColors:                     ; was: sub_40C0
                                        ; ROM:Palette_PrimaryEffectOffsets   o
                move.w  #$8CE,d0
                move.w  #$6AE,d1
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_UpdateSharedAnimatedColors_WritePair
                move.w  #$8E,d0
                move.w  #$4E,d1                         ; 'N'
Palette_UpdateSharedAnimatedColors_WritePair:           ; was: loc_40D8
                movea.w #(PaletteActiveBuffer+$1C-M68K_RAM),a0
                move.w  d0,$80(a0)
                move.w  d0,(a0)+
                move.w  d1,$80(a0)
                move.w  d1,(a0)+
; Selects the shared accent color from frame-counter bits
Palette_SelectSharedAccentColor:                        ; was: loc_40E8
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #$E,d0
                move.w  Palette_SharedAccentColorCycle(pc,d0.w),d0
                btst    #1,(FrameCounter+1).w
                bne.s   Palette_StoreSharedAccentColor
                subq.w  #2,d0
; Stores the selected accent in both active and shadow palette buffers
Palette_StoreSharedAccentColor:                         ; was: loc_4100
                movea.w #(PaletteActiveBuffer+$3E-M68K_RAM),a0
                move.w  d0,(a0)
                move.w  d0,$80(a0)
Palette_EffectReturn:                                   ; was: locret_410A
                                        ; ROM:Palette_SecondaryEffectOffsets   o
                rts
; End of function Palette_UpdateSharedAnimatedColors
; ---------------------------------------------------------------------------
Palette_SharedAccentColorCycle: dc.w    2, 4, 6, 8, $A, $C, $2E, $26E  ; was: word_410C

; Alternates stage 2 palette color 6 between two blue-green values
Palette_UpdateStage2BlinkColor:                         ; was: sub_411C
                move.w  #$480,d0
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_UpdateStage2BlinkColor_Store
                move.w  #$4C0,d0
Palette_UpdateStage2BlinkColor_Store:                   ; was: loc_412C
                move.w  d0,(PaletteActiveBuffer+$C).w
                rts
; End of function Palette_UpdateStage2BlinkColor
; Alternates two lightning-flash colors until the shared effect timer expires
Palette_UpdateLightningFlash:                           ; was: sub_4132
                move.w  (FrameCounter).w,d0
                asl.w   #2,d0
                andi.w  #4,d0
                subq.w  #1,(PaletteEffectControl).w
                bpl.s   Palette_UpdateLightningFlash_StoreColors
                clr.w   (PalettePrimaryIndex).w
                moveq   #0,d0
Palette_UpdateLightningFlash_StoreColors:               ; was: loc_4148
                move.w  Palette_LightningFlashColorPairs(pc,d0.w),(PaletteActiveBuffer+$14).w
                move.w  Palette_LightningFlashColorPairs+2(pc,d0.w),(PaletteActiveBuffer+$16).w
                rts
; End of function Palette_UpdateLightningFlash
; ---------------------------------------------------------------------------
Palette_LightningFlashColorPairs:   binclude "data/palettes/004156.bin"  ; was: word_4156

; Alternates six Epsilon-1 palette entries between the two frame sets
Palette_UpdateEpsilon1Colors:                           ; was: sub_415E
                lea     Palette_Epsilon1OddFrameColors(pc),a0
                nop
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_UpdateEpsilon1Colors_Copy
                lea     Palette_Epsilon1EvenFrameColors(pc),a0
                nop
Palette_UpdateEpsilon1Colors_Copy:                      ; was: loc_4172
                movea.w #(PaletteActiveBuffer+$20-M68K_RAM),a1
                move.w  (a0)+,$A(a1)
                move.w  (a0)+,$C(a1)
                move.w  (a0)+,$E(a1)
                move.w  (a0)+,$10(a1)
                move.w  (a0)+,$14(a1)
                move.w  (a0)+,$16(a1)
                rts
; End of function Palette_UpdateEpsilon1Colors
; ---------------------------------------------------------------------------
Palette_Epsilon1OddFrameColors:     binclude "data/palettes/004190.bin"  ; was: word_4190
Palette_Epsilon1EvenFrameColors:    binclude "data/palettes/00419C.bin"  ; was: word_419C

; Updates the shared stage 13-16 color cycles in active and shadow palettes
Palette_UpdateMidgameColors:                            ; was: sub_41A8
                                        ; Palette_UpdateMidgameFadeAndColors+1A   j
                move.w  (FrameCounter).w,d0
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                movea.w #(PaletteShadowBuffer-M68K_RAM),a1
                move.w  (PaletteEffectControl).w,d3
                move.w  d0,d1
                asr.w   #1,d1
                andi.w  #$E,d1
                move.w  d0,d2
                asr.w   #2,d2
                andi.w  #$E,d2
                btst    #2,d3
                bne.s   Palette_UpdateMidgameColors_UpdateAlternatingSlot
                move.w  Palette_MidgameColor3CCycle(pc,d2.w),$3C(a0)
                move.w  Palette_MidgameColor3CCycle(pc,d2.w),$3C(a1)
                asl.w   #1,d0
                andi.w  #2,d0
                move.w  Palette_MidgameColor28Pairs(pc,d0.w),$28(a0)
                move.w  Palette_MidgameColor28Pairs(pc,d0.w),$28(a1)
                move.w  Palette_MidgameColor2APairs(pc,d0.w),$2A(a0)
                move.w  Palette_MidgameColor2APairs(pc,d0.w),$2A(a1)
                move.w  Palette_MidgameColor2CPairs(pc,d0.w),$2C(a0)
                move.w  Palette_MidgameColor2CPairs(pc,d0.w),$2C(a1)
Palette_UpdateMidgameColors_UpdateAlternatingSlot:      ; was: loc_4204
                btst    #1,d3
                bne.s   Palette_UpdateMidgameColors_Return
                btst    #0,d3
                beq.s   Palette_UpdateMidgameColors_StoreColor1A
                move.w  Palette_MidgameColor1ACycle(pc,d1.w),$1C(a0)
                move.w  Palette_MidgameColor1ACycle(pc,d1.w),$1C(a1)
                rts
; ---------------------------------------------------------------------------
Palette_UpdateMidgameColors_StoreColor1A:               ; was: loc_421E
                move.w  Palette_MidgameColor1ACycle(pc,d1.w),$1A(a0)
                move.w  Palette_MidgameColor1ACycle(pc,d1.w),$1A(a1)
Palette_UpdateMidgameColors_Return:                     ; was: locret_422A
                rts
; End of function Palette_UpdateMidgameColors
; ---------------------------------------------------------------------------
Palette_MidgameColor1ACycle:    dc.w    0, 4, 8, $C, $A, 8, 6, 2  ; was: word_422C
Palette_MidgameColor3CCycle:    dc.w    $28E, $4A, 6, 2, 4, 8, $C, $E  ; was: word_423C
Palette_MidgameColor28Pairs:    dc.w    $600, $C00      ; was: word_424C
Palette_MidgameColor2APairs:    dc.w    $ECA, $EEC      ; was: word_4250
Palette_MidgameColor2CPairs:    dc.w    $202, $200      ; was: word_4254

; Alternates Shield Viper's fixed highlights with their shadow-palette colors
Palette_UpdateShieldViperColors:                        ; was: sub_4258
                movea.w #(PaletteActiveBuffer+2-M68K_RAM),a0
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_UpdateShieldViperColors_RestoreShadow
                move.w  #$200,(a0)+
                addq.w  #8,a0
                move.w  #$CEE,(a0)+
                move.w  #$CCA,(a0)+
                move.w  #$C88,(a0)+
                move.w  #$A62,(a0)+
                move.w  #$820,(a0)+
                move.w  #$600,(a0)+
                rts
; ---------------------------------------------------------------------------
Palette_UpdateShieldViperColors_RestoreShadow:          ; was: loc_4284
                move.w  $80(a0),(a0)+
                addq.w  #8,a0
                move.w  $80(a0),(a0)+
                move.w  $80(a0),(a0)+
                move.w  $80(a0),(a0)+
                move.w  $80(a0),(a0)+
                move.w  $80(a0),(a0)+
                move.w  $80(a0),(a0)+
                rts
; End of function Palette_UpdateShieldViperColors
; Advances Wolf Garopa's accent channels and its 16-step color cycle
Palette_UpdateWolfGaropaColors:                         ; was: sub_42A4
                addi.w  #$10,(PaletteActiveBuffer+$3E).w
                andi.w  #$F0,(PaletteActiveBuffer+$3E).w
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #$1E,d0
                move.w  Palette_WolfGaropaColorCycle(pc,d0.w),(PaletteActiveBuffer+$3C).w
                rts
; End of function Palette_UpdateWolfGaropaColors
; ---------------------------------------------------------------------------
Palette_WolfGaropaColorCycle:   dc.w    0, 2, $24, $46, $68, $8A, $AC, $CE  ; was: word_42C2
                dc.w    $EC, $CA, $A8, $86, $64, $42, $20, 0

; Alternates three fixed highlight colors with their shadow-palette values
Palette_ToggleThreeHighlightColors:                     ; was: sub_42E2
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_ToggleThreeHighlightColors_RestoreShadow
                move.w  #$EEE,4(a0)
                move.w  #$800,$1C(a0)
                move.w  #$E64,$1E(a0)
                rts
; ---------------------------------------------------------------------------
Palette_ToggleThreeHighlightColors_RestoreShadow:       ; was: loc_4302
                move.w  $84(a0),4(a0)
                move.w  $9C(a0),$1C(a0)
                move.w  $9E(a0),$1E(a0)
                rts
; End of function Palette_ToggleThreeHighlightColors
; Runs the secondary palette-effect slot while normal frame processing is active
Palette_UpdateSecondaryEffect:                          ; was: sub_4316
                tst.b   (FrameControlFlags).w
                bpl.s   Palette_UpdateSecondaryEffect_Dispatch
                rts
; ---------------------------------------------------------------------------
Palette_UpdateSecondaryEffect_Dispatch:                 ; was: loc_431E
                move.w  (PaletteSecondaryIndex).w,d0
                movea.w Palette_SecondaryEffectOffsets(pc,d0.w),a0
                adda.l  #Palette_UpdatePairedEntryLists,a0
                jmp     (a0)
; End of function Palette_UpdateSecondaryEffect
; ---------------------------------------------------------------------------
Palette_SecondaryEffectOffsets: dc.w    Palette_EffectReturn-Palette_UpdatePairedEntryLists  ; was: off_432E
                dc.w    Palette_UpdatePairedEntryLists-Palette_UpdatePairedEntryLists
                dc.w    Palette_UpdateMidgameAdjustedColors-Palette_UpdatePairedEntryLists
                dc.w    Palette_UpdateMidgameFadeAndColors-Palette_UpdatePairedEntryLists

; Applies opposite RGB deltas to two consecutive counted palette-entry lists
Palette_UpdatePairedEntryLists:                         ; was: sub_4336
                                        ; ROM:Palette_SecondaryEffectOffsets   o
                movea.l (PaletteEntryLists).w,a2
                move.w  (PaletteEffectControl).w,d0
                bsr.w   Gfx_ApplyRGBDeltaToPaletteEntries
                move.w  (PaletteEffectControl).w,d0
                neg.w   d0
                bsr.w   Gfx_ApplyRGBDeltaToPaletteEntries
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_UpdatePairedEntryLists_Return
                subq.w  #1,(PaletteEffectControl).w
                bpl.s   Palette_UpdatePairedEntryLists_Return
                clr.w   (PaletteSecondaryIndex).w
Palette_UpdatePairedEntryLists_Return:                  ; was: locret_435E
                                        ; Palette_UpdatePairedEntryLists+22   j
                rts
; End of function Palette_UpdatePairedEntryLists
; Applies the shared full-palette RGB adjustment before the midgame color cycles
Palette_UpdateMidgameAdjustedColors:                    ; was: sub_4360
                bsr.w   Gfx_UpdateFullPaletteRGBAdjustment
                bra.w   Palette_UpdateMidgameColors
; End of function Palette_UpdateMidgameAdjustedColors
; Advances the full-palette fade parameter, then updates the midgame color cycles
Palette_UpdateMidgameFadeAndColors:                     ; was: sub_4368
                btst    #0,(FrameCounter+1).w
                bne.s   Palette_UpdateMidgameFadeAndColors_Apply
                addq.w  #1,(MidgameFadeLevel).w
                bne.s   Palette_UpdateMidgameFadeAndColors_Apply
                clr.w   (PaletteSecondaryIndex).w
Palette_UpdateMidgameFadeAndColors_Apply:               ; was: loc_437A
                                        ; Palette_UpdateMidgameFadeAndColors+C   j
                move.w  (MidgameFadeLevel).w,d0
                jsr     Gfx_ApplyFullActivePaletteFade(pc)  ; (pc)
                bra.w   Palette_UpdateMidgameColors
; End of function Palette_UpdateMidgameFadeAndColors
