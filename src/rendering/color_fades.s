; List-driven palette fades, per-entry target fades, and RGB adjustment effects
; Color-channel names follow Mega Drive CRAM order: red $00E, green $0E0, blue $E00

; Loads the default entry list and falls through to clear the color-fade state
Gfx_ResetDefaultColorFadeState:                         ; CODE XREF: Boss_LoadAssetSet+72   j  ; was: sub_3C08
                                        ; Boss_LovePenguinLoadGraphics+1A   p
                lea     PaletteFade_DefaultEntryOffsets(pc),a2
                nop
; End of function Gfx_ResetDefaultColorFadeState
; Clears color fade state variables and status flags
Gfx_ClearColorFadeState:                                ; CODE XREF: Boss_FlyingNeoSetup+E2   p  ; was: sub_3C0E
                                        ; Boss_ViblackInit+AC   p
                clr.w   (ColorFadePhase).w
                bclr    #0,(BossColorEffectFlags).w
                bclr    #3,(BossColorEffectFlags).w
                rts
; End of function Gfx_ClearColorFadeState
; Loads the default entry list and falls through to process one color-fade step
Gfx_ProcessDefaultColorFade:                            ; CODE XREF: Boss_DestroyerProtoMain   p  ; was: sub_3C20
                                        ; sub_323FA   p
                lea     PaletteFade_DefaultEntryOffsets(pc),a2
                nop
; End of function Gfx_ProcessDefaultColorFade
; Updates the requested boss palette-entry fade from shadow colors and a shared phase
Gfx_UpdateBossPaletteColorFade:                         ; CODE XREF: Boss_FlyingNeoMain+1C   p  ; was: sub_3C26
                                        ; Boss_ViblackMain+12   p
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d3
                tst.w   (ColorFadePhase).w
                bne.s   Gfx_UpdateBossPaletteColorFade_AdvanceStep
                bclr    #0,(BossColorEffectFlags).w
                beq.w   Gfx_UpdateBossPaletteColorFade_Return
                move.w  #$A,(ColorFadePhase).w
                bclr    #3,(BossColorEffectFlags).w
                beq.w   Gfx_UpdateBossPaletteColorFade_AdvanceStep
                move.w  #$19,(ColorFadePhase).w
Gfx_UpdateBossPaletteColorFade_AdvanceStep:             ; CODE XREF: Gfx_UpdateBossPaletteColorFade+A   j  ; was: loc_3C52
                                        ; Gfx_UpdateBossPaletteColorFade+22   j
                moveq   #0,d2
                subq.w  #5,(ColorFadePhase).w
                beq.s   Gfx_UpdateBossPaletteColorFade_PrepareChannelDeltas
                move.w  (ColorFadePhase).w,d2
Gfx_UpdateBossPaletteColorFade_PrepareChannelDeltas:    ; CODE XREF: Gfx_UpdateBossPaletteColorFade+32   j  ; was: loc_3C5E
                move.w  d2,d3
                asl.w   #4,d3
                andi.w  #$FFE0,d3
                move.w  d3,d4
                asl.w   #4,d4
                andi.w  #$FE00,d4
                move.w  (a2)+,d7
Gfx_UpdateBossPaletteColorFade_ColorLoop:               ; CODE XREF: Gfx_UpdateBossPaletteColorFade+9C   j  ; was: loc_3C70
                movea.w (a2)+,a1
                move.w  $80(a1),d0
                move.w  d0,d5
                andi.w  #$E,d5
                add.w   d2,d5
                bpl.s   Gfx_UpdateBossPaletteColorFade_ClampRedMaximum
                moveq   #0,d5
                bra.s   Gfx_UpdateBossPaletteColorFade_MergeRed
; ---------------------------------------------------------------------------
Gfx_UpdateBossPaletteColorFade_ClampRedMaximum:         ; CODE XREF: Gfx_UpdateBossPaletteColorFade+58   j  ; was: loc_3C84
                cmpi.w  #$F,d5
                bmi.s   Gfx_UpdateBossPaletteColorFade_MergeRed
                moveq   #$E,d5
Gfx_UpdateBossPaletteColorFade_MergeRed:                ; CODE XREF: Gfx_UpdateBossPaletteColorFade+5C   j  ; was: loc_3C8C
                                        ; Gfx_UpdateBossPaletteColorFade+62   j
                move.w  d0,d1
                andi.w  #$E0,d1
                add.w   d3,d1
                bpl.s   Gfx_UpdateBossPaletteColorFade_ClampGreenMaximum
                moveq   #0,d1
                bra.s   Gfx_UpdateBossPaletteColorFade_MergeGreen
; ---------------------------------------------------------------------------
Gfx_UpdateBossPaletteColorFade_ClampGreenMaximum:       ; CODE XREF: Gfx_UpdateBossPaletteColorFade+6E   j  ; was: loc_3C9A
                cmpi.w  #$E1,d1
                bmi.s   Gfx_UpdateBossPaletteColorFade_MergeGreen
                move.w  #$E0,d1
Gfx_UpdateBossPaletteColorFade_MergeGreen:              ; CODE XREF: Gfx_UpdateBossPaletteColorFade+72   j  ; was: loc_3CA4
                                        ; Gfx_UpdateBossPaletteColorFade+78   j
                or.w    d1,d5
                move.w  d0,d1
                andi.w  #$E00,d1
                add.w   d4,d1
                bpl.s   Gfx_UpdateBossPaletteColorFade_ClampBlueMaximum
                moveq   #0,d1
                bra.s   Gfx_UpdateBossPaletteColorFade_StoreColor
; ---------------------------------------------------------------------------
Gfx_UpdateBossPaletteColorFade_ClampBlueMaximum:        ; CODE XREF: Gfx_UpdateBossPaletteColorFade+88   j  ; was: loc_3CB4
                cmpi.w  #$E01,d1
                bmi.s   Gfx_UpdateBossPaletteColorFade_StoreColor
                move.w  #$E00,d1
Gfx_UpdateBossPaletteColorFade_StoreColor:              ; CODE XREF: Gfx_UpdateBossPaletteColorFade+8C   j  ; was: loc_3CBE
                                        ; Gfx_UpdateBossPaletteColorFade+92   j
                or.w    d1,d5
                move.w  d5,(a1)
                dbf     d7,Gfx_UpdateBossPaletteColorFade_ColorLoop
                bclr    #0,(BossColorEffectFlags).w
Gfx_UpdateBossPaletteColorFade_Return:                  ; CODE XREF: Gfx_UpdateBossPaletteColorFade+12   j  ; was: locret_3CCC
                rts
; End of function Gfx_UpdateBossPaletteColorFade
; Initializes color fade state by loading palette table and clearing fade variables
Gfx_InitColorFadeState:
                lea     PaletteFade_DefaultEntryOffsets(pc),a2  ; was: sub_3CCE
                nop
                clr.w   (ColorFadeTriggerState).w
                clr.w   (ColorFadePhase).w
                bclr    #0,(BossColorEffectFlags).w
                rts
; End of function Gfx_InitColorFadeState
; Processes complex color fade effects with RGB component clamping
Gfx_ProcessColorFadeEffect:
                lea     PaletteFade_DefaultEntryOffsets(pc),a2  ; was: sub_3CE4
                nop
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d3
                tst.w   (ColorFadeTriggerState).w
                beq.w   Gfx_ProcessColorFadeEffect_AdvanceOscillation
                bpl.s   Gfx_ProcessColorFadeEffect_StartRandomChannelFade
                clr.w   (ColorFadeTriggerState).w
                bra.w   Gfx_ApplyRGBDeltaToPaletteEntries_LoadEntryCount
; ---------------------------------------------------------------------------
Gfx_ProcessColorFadeEffect_StartRandomChannelFade:      ; CODE XREF: Gfx_ProcessColorFadeEffect+14   j  ; was: loc_3D02
                move.w  #$FFFF,(ColorFadeTriggerState).w
                clr.w   (ColorFadePhase).w
                btst    #1,(BossColorEffectFlags).w
                bne.w   Gfx_ProcessColorFadeEffect_Return
                move.w  (FrameCounter).w,d0
                move.w  d0,d4
                asr.w   #4,d4
                andi.w  #$E,d4
                move.w  Gfx_RandomFadeChannelMaskTable(pc,d4.w),d4
                neg.w   d0
                andi.w  #$E,d0
                addq.w  #4,d0
                btst    #0,d4
                beq.s   Gfx_ProcessColorFadeEffect_SelectGreenDelta
                move.w  d0,d1
Gfx_ProcessColorFadeEffect_SelectGreenDelta:            ; CODE XREF: Gfx_ProcessColorFadeEffect+4E   j  ; was: loc_3D36
                btst    #1,d4
                beq.s   Gfx_ProcessColorFadeEffect_SelectBlueDelta
                move.w  d0,d2
Gfx_ProcessColorFadeEffect_SelectBlueDelta:             ; CODE XREF: Gfx_ProcessColorFadeEffect+56   j  ; was: loc_3D3E
                btst    #2,d4
                beq.s   Gfx_ProcessColorFadeEffect_PrepareRandomDeltas
                move.w  d0,d3
Gfx_ProcessColorFadeEffect_PrepareRandomDeltas:         ; CODE XREF: Gfx_ProcessColorFadeEffect+5E   j  ; was: loc_3D46
                asl.w   #4,d2
                asl.w   #8,d3
                bra.w   Gfx_ApplyRGBDeltaToPaletteEntries_LoadEntryCount
; ---------------------------------------------------------------------------
Gfx_RandomFadeChannelMaskTable: dc.w    1, 2, 4, 3, 6, 5, 3, 5  ; was: word_3D4E
; ---------------------------------------------------------------------------
Gfx_ProcessColorFadeEffect_AdvanceOscillation:          ; CODE XREF: Gfx_ProcessColorFadeEffect+10   j  ; was: loc_3D5E
                tst.w   (ColorFadePhase).w
                bne.s   Gfx_ProcessColorFadeEffect_PrepareOscillationDeltas
                bclr    #0,(BossColorEffectFlags).w
                beq.w   Gfx_ProcessColorFadeEffect_Return
Gfx_ProcessColorFadeEffect_PrepareOscillationDeltas:    ; CODE XREF: Gfx_ProcessColorFadeEffect+7E   j  ; was: loc_3D6E
                move.w  (ColorFadePhase).w,d2
                addq.w  #2,d2
                andi.w  #$E,d2
                move.w  d2,(ColorFadePhase).w
                beq.s   Gfx_ProcessColorFadeEffect_LoadOscillationTargets
                subq.w  #6,d2
Gfx_ProcessColorFadeEffect_LoadOscillationTargets:      ; CODE XREF: Gfx_ProcessColorFadeEffect+98   j  ; was: loc_3D80
                andi.w  #$FFFE,d2
                move.w  d2,d3
                asl.w   #4,d3
                andi.w  #$FFE0,d3
                move.w  d3,d4
                asl.w   #4,d4
                andi.w  #$FE00,d4
                move.w  (a2)+,d7
Gfx_ProcessColorFadeEffect_ColorLoop:                   ; CODE XREF: Gfx_ProcessColorFadeEffect+104   j  ; was: loc_3D96
                movea.w (a2)+,a1
                move.w  $80(a1),d0
                move.w  d0,d5
                andi.w  #$E,d5
                add.w   d2,d5
                bpl.s   Gfx_ProcessColorFadeEffect_ClampRedMaximum
                moveq   #0,d5
                bra.s   Gfx_ProcessColorFadeEffect_MergeRed
; ---------------------------------------------------------------------------
Gfx_ProcessColorFadeEffect_ClampRedMaximum:             ; CODE XREF: Gfx_ProcessColorFadeEffect+C0   j  ; was: loc_3DAA
                cmpi.w  #$F,d5
                bmi.s   Gfx_ProcessColorFadeEffect_MergeRed
                moveq   #$E,d5
Gfx_ProcessColorFadeEffect_MergeRed:                    ; CODE XREF: Gfx_ProcessColorFadeEffect+C4   j  ; was: loc_3DB2
                                        ; Gfx_ProcessColorFadeEffect+CA   j
                move.w  d0,d1
                andi.w  #$E0,d1
                add.w   d3,d1
                bpl.s   Gfx_ProcessColorFadeEffect_ClampGreenMaximum
                moveq   #0,d1
                bra.s   Gfx_ProcessColorFadeEffect_MergeGreen
; ---------------------------------------------------------------------------
Gfx_ProcessColorFadeEffect_ClampGreenMaximum:           ; CODE XREF: Gfx_ProcessColorFadeEffect+D6   j  ; was: loc_3DC0
                cmpi.w  #$E1,d1
                bmi.s   Gfx_ProcessColorFadeEffect_MergeGreen
                move.w  #$E0,d1
Gfx_ProcessColorFadeEffect_MergeGreen:                  ; CODE XREF: Gfx_ProcessColorFadeEffect+DA   j  ; was: loc_3DCA
                                        ; Gfx_ProcessColorFadeEffect+E0   j
                or.w    d1,d5
                move.w  d0,d1
                andi.w  #$E00,d1
                add.w   d4,d1
                bpl.s   Gfx_ProcessColorFadeEffect_ClampBlueMaximum
                moveq   #0,d1
                bra.s   Gfx_ProcessColorFadeEffect_StoreColor
; ---------------------------------------------------------------------------
Gfx_ProcessColorFadeEffect_ClampBlueMaximum:            ; CODE XREF: Gfx_ProcessColorFadeEffect+F0   j  ; was: loc_3DDA
                cmpi.w  #$E01,d1
                bmi.s   Gfx_ProcessColorFadeEffect_StoreColor
                move.w  #$E00,d1
Gfx_ProcessColorFadeEffect_StoreColor:                  ; CODE XREF: Gfx_ProcessColorFadeEffect+F4   j  ; was: loc_3DE4
                                        ; Gfx_ProcessColorFadeEffect+FA   j
                or.w    d1,d5
                move.w  d5,(a1)
                dbf     d7,Gfx_ProcessColorFadeEffect_ColorLoop
                bclr    #0,(BossColorEffectFlags).w
Gfx_ProcessColorFadeEffect_Return:                      ; CODE XREF: Gfx_ProcessColorFadeEffect+2E   j  ; was: locret_3DF2
                                        ; Gfx_ProcessColorFadeEffect+86   j
                rts
; End of function Gfx_ProcessColorFadeEffect
; ---------------------------------------------------------------------------
PaletteFade_DefaultEntryOffsets:    dc.w    $D          ; DATA XREF: Gfx_ResetDefaultColorFadeState   o  ; was: word_3DF4
                                        ; sub_3C20   o
                dc.w    $E362, $E364, $E366, $E368, $E36A, $E36E, $E370, $E372
                dc.w    $E374, $E376, $E378, $E37A, $E37C, $E37E
PaletteFade_FlyingNeoEntryOffsets:  dc.w    $C          ; DATA XREF: Boss_FlyingNeoMain:Boss_FlyingNeoProcessMainColorFade   o  ; was: word_3E12
                                        ; Boss_FlyingNeoMain+4E   o
                dc.w    $E362, $E364, $E366, $E368, $E36A, $E370, $E372, $E374
                dc.w    $E376, $E378, $E37A, $E37C, $E37E
PaletteFade_BugmaxWaveEntryOffsets: dc.w    5           ; DATA XREF: Gfx_BugmaxApplyWavePaletteOffset+30   o  ; was: word_3E2E
                dc.w    $E366, $E368, $E36A, $E36E, $E370, $E378
PaletteFade_BugmaxEntryOffsets: dc.w    6               ; DATA XREF: Boss_BugmaxMain+8   o  ; was: word_3E3C
                dc.w    $E362, $E372, $E374, $E376, $E37A, $E37C, $E37E
PaletteFade_SevenForceEntryOffsets: dc.w    5           ; DATA XREF: Entity_UpdateValkirieBattle:Entity_UpdateValkirieBattleActive   o  ; was: word_3E4C
                                        ; Boss_UpdateMedusa:Boss_UpdateMedusaBattleEffects   o
                dc.w    $E362, $E36A, $E372, $E374, $E376, $E378

; Applies a packed signed RGB delta to a counted palette-entry list
Gfx_ApplyRGBDeltaToPaletteEntries:                      ; CODE XREF: Palette_UpdatePairedEntryLists+8   p  ; was: sub_3E5A
                                        ; Palette_UpdatePairedEntryLists+12   p
                bsr.w   Gfx_ExpandColorAdjustmentToRGBChannels
Gfx_ApplyRGBDeltaToPaletteEntries_LoadEntryCount:       ; CODE XREF: Gfx_ProcessColorFadeEffect+1A   j  ; was: loc_3E5E
                                        ; Gfx_ProcessColorFadeEffect+66   j
                move.w  (a2)+,d5
Gfx_ApplyRGBDeltaToPaletteEntries_ColorLoop:            ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+66   j  ; was: loc_3E60
                movea.w (a2)+,a1
                move.w  $80(a1),d6
                move.w  d6,d7
                andi.w  #$E,d7
                add.w   d1,d7
                bpl.s   Gfx_ApplyRGBDeltaToPaletteEntries_ClampRedMaximum
                clr.w   d7
                bra.s   Gfx_ApplyRGBDeltaToPaletteEntries_MergeRed
; ---------------------------------------------------------------------------
Gfx_ApplyRGBDeltaToPaletteEntries_ClampRedMaximum:      ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+14   j  ; was: loc_3E74
                cmpi.w  #$F,d7
                bmi.s   Gfx_ApplyRGBDeltaToPaletteEntries_MergeRed
                moveq   #$E,d7
Gfx_ApplyRGBDeltaToPaletteEntries_MergeRed:             ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+18   j  ; was: loc_3E7C
                                        ; Gfx_ApplyRGBDeltaToPaletteEntries+1E   j
                andi.w  #$FFF0,d6
                or.w    d7,d6
                move.w  d6,d7
                andi.w  #$E0,d7
                add.w   d2,d7
                bpl.s   Gfx_ApplyRGBDeltaToPaletteEntries_ClampGreenMaximum
                clr.w   d7
                bra.s   Gfx_ApplyRGBDeltaToPaletteEntries_MergeGreen
; ---------------------------------------------------------------------------
Gfx_ApplyRGBDeltaToPaletteEntries_ClampGreenMaximum:    ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+30   j  ; was: loc_3E90
                cmpi.w  #$E1,d7
                bmi.s   Gfx_ApplyRGBDeltaToPaletteEntries_MergeGreen
                move.w  #$E0,d7
Gfx_ApplyRGBDeltaToPaletteEntries_MergeGreen:           ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+34   j  ; was: loc_3E9A
                                        ; Gfx_ApplyRGBDeltaToPaletteEntries+3A   j
                andi.w  #$FF0F,d6
                or.w    d7,d6
                move.w  d6,d7
                andi.w  #$E00,d7
                add.w   d3,d7
                bpl.s   Gfx_ApplyRGBDeltaToPaletteEntries_ClampBlueMaximum
                clr.w   d7
                bra.s   Gfx_ApplyRGBDeltaToPaletteEntries_StoreColor
; ---------------------------------------------------------------------------
Gfx_ApplyRGBDeltaToPaletteEntries_ClampBlueMaximum:     ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+4E   j  ; was: loc_3EAE
                cmpi.w  #$E01,d7
                bmi.s   Gfx_ApplyRGBDeltaToPaletteEntries_StoreColor
                move.w  #$E00,d7
; Merges the adjusted blue channel, stores the color, and advances the entry loop
Gfx_ApplyRGBDeltaToPaletteEntries_StoreColor:           ; CODE XREF: Gfx_ApplyRGBDeltaToPaletteEntries+52   j  ; was: loc_3EB8
                                        ; Gfx_ApplyRGBDeltaToPaletteEntries+58   j
                andi.w  #$F0FF,d6
                or.w    d7,d6
                move.w  d6,(a1)
                dbf     d5,Gfx_ApplyRGBDeltaToPaletteEntries_ColorLoop
                rts
; End of function Gfx_ApplyRGBDeltaToPaletteEntries
; ---------------------------------------------------------------------------
PaletteFade_StageScrollEntryOffsets:    dc.w    $3A, $E302, $E304, $E306, $E308, $E30A, $E30C, $E30E, $E310, $E312  ; was: word_3EC6
                                        ; DATA XREF: Stage_UpdateScrollOffset+18   o
                dc.w    $E314, $E316, $E318, $E31A, $E31C, $E31E, $E322, $E324, $E326, $E328
                dc.w    $E32A, $E32C, $E32E, $E330, $E332, $E334, $E336, $E338, $E33A, $E33C
                dc.w    $E33E, $E342, $E344, $E346, $E348, $E34A, $E34C, $E34E, $E350, $E352
                dc.w    $E354, $E356, $E358, $E35A, $E35C, $E35E, $E362, $E364, $E366, $E368
                dc.w    $E36A, $E36E, $E370, $E372, $E374, $E376, $E378, $E37A, $E37C, $E37E

; Steps a counted palette-entry list toward one RGB target color
Gfx_StepPaletteEntriesToColor:                          ; CODE XREF: Boss_FlyingNeoMain+54   p  ; was: sub_3F3E
                move.w  d0,d1
                move.w  d1,d2
                andi.w  #$E,d0
                andi.w  #$E0,d1
                andi.w  #$E00,d2
                moveq   #0,d4
                move.w  (a2)+,d5
Gfx_StepPaletteEntriesToColor_ColorLoop:                ; CODE XREF: Gfx_StepPaletteEntriesToColor+70   j  ; was: loc_3F52
                movea.w (a2)+,a1
                move.w  $80(a1),d6
                move.w  d6,d7
                andi.w  #$E,d7
                cmp.w   d0,d7
                beq.s   Gfx_StepPaletteEntriesToColor_MergeRed
                bset    #0,d4
                bpl.s   Gfx_StepPaletteEntriesToColor_DecreaseRed
                addq.w  #2,d7
                bra.s   Gfx_StepPaletteEntriesToColor_MergeRed
; ---------------------------------------------------------------------------
Gfx_StepPaletteEntriesToColor_DecreaseRed:              ; CODE XREF: Gfx_StepPaletteEntriesToColor+28   j  ; was: loc_3F6C
                subq.w  #2,d7
Gfx_StepPaletteEntriesToColor_MergeRed:                 ; CODE XREF: Gfx_StepPaletteEntriesToColor+22   j  ; was: loc_3F6E
                                        ; Gfx_StepPaletteEntriesToColor+2C   j
                move.w  d7,d3
                move.w  d6,d7
                andi.w  #$E0,d7
                cmp.w   d1,d7
                beq.s   Gfx_StepPaletteEntriesToColor_MergeGreen
                bset    #0,d4
                bpl.s   Gfx_StepPaletteEntriesToColor_DecreaseGreen
                addi.w  #$20,d7                         ; ' '
                bra.s   Gfx_StepPaletteEntriesToColor_MergeGreen
; ---------------------------------------------------------------------------
Gfx_StepPaletteEntriesToColor_DecreaseGreen:            ; CODE XREF: Gfx_StepPaletteEntriesToColor+40   j  ; was: loc_3F86
                subi.w  #$20,d7                         ; ' '
Gfx_StepPaletteEntriesToColor_MergeGreen:               ; CODE XREF: Gfx_StepPaletteEntriesToColor+3A   j  ; was: loc_3F8A
                                        ; Gfx_StepPaletteEntriesToColor+46   j
                or.w    d7,d3
                move.w  d6,d7
                andi.w  #$E00,d7
                cmp.w   d2,d7
                beq.s   Gfx_StepPaletteEntriesToColor_StoreColor
                bset    #0,d4
                bpl.s   Gfx_StepPaletteEntriesToColor_DecreaseBlue
                addi.w  #$200,d7
                bra.s   Gfx_StepPaletteEntriesToColor_StoreColor
; ---------------------------------------------------------------------------
Gfx_StepPaletteEntriesToColor_DecreaseBlue:             ; CODE XREF: Gfx_StepPaletteEntriesToColor+5C   j  ; was: loc_3FA2
                subi.w  #$200,d7
Gfx_StepPaletteEntriesToColor_StoreColor:               ; CODE XREF: Gfx_StepPaletteEntriesToColor+56   j  ; was: loc_3FA6
                                        ; Gfx_StepPaletteEntriesToColor+62   j
                or.w    d7,d3
                move.w  d3,(a1)
                move.w  d3,$80(a1)
                dbf     d5,Gfx_StepPaletteEntriesToColor_ColorLoop
                move.w  d4,d4
                rts
; End of function Gfx_StepPaletteEntriesToColor
; Steps each counted palette entry toward its corresponding target color
Gfx_StepPaletteEntriesToTargetList:                     ; CODE XREF: Boss_FlyingNeoUpdatePaletteFade+16   j  ; was: sub_3FB6
                moveq   #0,d4
                move.w  (a2)+,d5
Gfx_StepPaletteEntriesToTargetList_ColorLoop:           ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+72   j  ; was: loc_3FBA
                movea.w (a2)+,a1
                move.w  $80(a1),d6
                move.w  (a3)+,d0
                move.w  d0,d1
                move.w  d1,d2
                andi.w  #$E,d0
                andi.w  #$E0,d1
                andi.w  #$E00,d2
                move.w  d6,d7
                andi.w  #$E,d7
                cmp.w   d0,d7
                beq.s   Gfx_StepPaletteEntriesToTargetList_MergeRed
                bset    #0,d4
                bpl.s   Gfx_StepPaletteEntriesToTargetList_DecreaseRed
                addq.w  #2,d7
                bra.s   Gfx_StepPaletteEntriesToTargetList_MergeRed
; ---------------------------------------------------------------------------
Gfx_StepPaletteEntriesToTargetList_DecreaseRed:         ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+2A   j  ; was: loc_3FE6
                subq.w  #2,d7
Gfx_StepPaletteEntriesToTargetList_MergeRed:            ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+24   j  ; was: loc_3FE8
                                        ; Gfx_StepPaletteEntriesToTargetList+2E   j
                move.w  d7,d3
                move.w  d6,d7
                andi.w  #$E0,d7
                cmp.w   d1,d7
                beq.s   Gfx_StepPaletteEntriesToTargetList_MergeGreen
                bset    #0,d4
                bpl.s   Gfx_StepPaletteEntriesToTargetList_DecreaseGreen
                addi.w  #$20,d7                         ; ' '
                bra.s   Gfx_StepPaletteEntriesToTargetList_MergeGreen
; ---------------------------------------------------------------------------
Gfx_StepPaletteEntriesToTargetList_DecreaseGreen:       ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+42   j  ; was: loc_4000
                subi.w  #$20,d7                         ; ' '
Gfx_StepPaletteEntriesToTargetList_MergeGreen:          ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+3C   j  ; was: loc_4004
                                        ; Gfx_StepPaletteEntriesToTargetList+48   j
                or.w    d7,d3
                move.w  d6,d7
                andi.w  #$E00,d7
                cmp.w   d2,d7
                beq.s   Gfx_StepPaletteEntriesToTargetList_StoreColor
                bset    #0,d4
                bpl.s   Gfx_StepPaletteEntriesToTargetList_DecreaseBlue
                addi.w  #$200,d7
                bra.s   Gfx_StepPaletteEntriesToTargetList_StoreColor
; ---------------------------------------------------------------------------
Gfx_StepPaletteEntriesToTargetList_DecreaseBlue:        ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+5E   j  ; was: loc_401C
                subi.w  #$200,d7
Gfx_StepPaletteEntriesToTargetList_StoreColor:          ; CODE XREF: Gfx_StepPaletteEntriesToTargetList+58   j  ; was: loc_4020
                                        ; Gfx_StepPaletteEntriesToTargetList+64   j
                or.w    d7,d3
                move.w  d3,(a1)
                move.w  d3,$80(a1)
                dbf     d5,Gfx_StepPaletteEntriesToTargetList_ColorLoop
                move.w  d4,d4
                rts
; End of function Gfx_StepPaletteEntriesToTargetList
; Updates a selected-channel RGB adjustment across the full active palette
Gfx_UpdateFullPaletteRGBAdjustment:                     ; CODE XREF: Palette_UpdateMidgameAdjustedColors   p  ; was: sub_4030
                move.w  (PaletteRGBAdjustLevel).w,d0
                asr.w   #4,d0
                addi.w  #-$E,d0
                moveq   #$FFFFFFF2,d1
                move.w  #$FF20,d2
                move.w  #$F200,d3
                btst    #5,(PaletteRGBChannelMask).w
                beq.s   Gfx_UpdateFullPaletteRGBAdjustment_SelectGreenDelta
                move.w  d0,d1
Gfx_UpdateFullPaletteRGBAdjustment_SelectGreenDelta:    ; CODE XREF: Gfx_UpdateFullPaletteRGBAdjustment+1A   j  ; was: loc_404E
                btst    #6,(PaletteRGBChannelMask).w
                beq.s   Gfx_UpdateFullPaletteRGBAdjustment_SelectBlueDelta
                move.w  d0,d2
                asl.w   #4,d2
Gfx_UpdateFullPaletteRGBAdjustment_SelectBlueDelta:     ; CODE XREF: Gfx_UpdateFullPaletteRGBAdjustment+24   j  ; was: loc_405A
                btst    #7,(PaletteRGBChannelMask).w
                beq.s   Gfx_UpdateFullPaletteRGBAdjustment_ApplyPalette
                move.w  d0,d3
                asl.w   #8,d3
Gfx_UpdateFullPaletteRGBAdjustment_ApplyPalette:        ; CODE XREF: Gfx_UpdateFullPaletteRGBAdjustment+30   j  ; was: loc_4066
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                movea.w #(PaletteShadowBuffer-M68K_RAM),a1
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d0
Gfx_UpdateFullPaletteRGBAdjustment_ColorLoop:           ; CODE XREF: Gfx_UpdateFullPaletteRGBAdjustment+4E   j  ; was: loc_4076
                move.w  (a1)+,d6
                jsr     Gfx_AdjustSelectedColorChannels(pc)  ; (pc)
                move.w  d6,(a0)+
                dbf     d5,Gfx_UpdateFullPaletteRGBAdjustment_ColorLoop
                moveq   #0,d0
                move.b  (PaletteRGBAdjustStep).w,d0
                sub.w   d0,(PaletteRGBAdjustLevel).w
                bpl.s   Gfx_UpdateFullPaletteRGBAdjustment_Return
                clr.w   (PaletteRGBAdjustLevel).w
Gfx_UpdateFullPaletteRGBAdjustment_Return:              ; CODE XREF: Gfx_UpdateFullPaletteRGBAdjustment+5C   j  ; was: locret_4092
                rts
; End of function Gfx_UpdateFullPaletteRGBAdjustment
