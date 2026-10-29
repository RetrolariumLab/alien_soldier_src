; Initializes the STAGE-number entry banner and its stage time limit
StageIntro_InitializeBanner:                            ; was: sub_AE9A
                addq.w  #2,(MessageSequenceState).w
                jsr     (Stage_LoadTimeLimit).l
                bclr    #0,(StageTimerPauseFlag).w
                move.l  #StageIntro_GlyphSourceList,(MessageGlyphSourcePtr).w
                move.w  #$5400,(MessageGlyphVRAMCursor).w
; Streams the glyph set used by the stage-number banner
StageIntro_LoadStageNumberGlyph:                        ; was: loc_AEB8
                bsr.w   Message_LoadNextGlyphTile
                cmpi.w  #$52,(MessageSequenceState).w   ; 'R'
                beq.s   StageIntro_LoadStageNumberGlyphReturn
                move.w  #$EC,(StageIntroBannerX).w
                move.w  #$80,(StageIntroBannerTimer).w
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$E0,(PaletteRGBChannelMask).w
                move.b  #2,(PaletteRGBAdjustStep).w
StageIntro_LoadStageNumberGlyphReturn:                  ; was: locret_AEE2
                rts
; End of function StageIntro_InitializeBanner
; Slides in the STAGE label and its two packed-BCD number digits
StageIntro_UpdateStageNumberBanner:                     ; was: sub_AEE4
                addq.w  #1,(StageIntroBannerX).w
                cmpi.w  #$FC,(StageIntroBannerX).w
                bmi.s   StageIntro_CheckStageNumberSound
                move.w  #$FC,(StageIntroBannerX).w
StageIntro_CheckStageNumberSound:                       ; was: loc_AEF6
                cmpi.w  #$40,(StageIntroBannerTimer).w  ; '@'
                bne.s   StageIntro_UpdateStageNumberDelay
                move.b  (StageIntroSoundRequest).w,d0
                beq.s   StageIntro_UpdateStageNumberDelay
                clr.b   (StageIntroSoundRequest).w
                jsr     (Sound_QueueSFXRequest).l
StageIntro_UpdateStageNumberDelay:                      ; was: loc_AF0E
                                        ; StageIntro_UpdateStageNumberBanner+1E   j
                subq.w  #1,(StageIntroBannerTimer).w
                bpl.s   StageIntro_RenderStageNumberBanner
                clr.w   (MessageSequenceState).w
StageIntro_RenderStageNumberBanner:                     ; was: loc_AF18
                lea     StageIntro_StageNumberSpriteTileLayout(pc),a0
                nop
                bsr.w   Message_LoadSpriteTileIndices
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                move.w  #$EC,d0
                move.b  (StageNumberBCD).w,d2
                move.w  d2,d3
                asr.w   #4,d3
                andi.w  #$F,d2
                andi.w  #$F,d3
                asl.w   #1,d2
                asl.w   #1,d3
                addi.w  #-$3960,d2
                addi.w  #-$3960,d3
                move.w  (StageIntroBannerX).w,d1
                moveq   #4,d7
; Writes the five fixed STAGE-label sprite entries before the two number digits
StageIntro_WriteStageLabelSprites:                      ; was: loc_AF4C
                move.w  d0,(a0)
                move.w  d1,6(a0)
                addi.w  #$C,d1
                addq.w  #8,a0
                dbf     d7,StageIntro_WriteStageLabelSprites
                addq.w  #6,d1
                move.w  d0,(a0)
                move.w  d1,6(a0)
                move.w  d3,4(a0)
                addi.w  #$C,d1
                addq.w  #8,a0
                move.w  d0,(a0)
                move.w  d1,6(a0)
                move.w  d2,4(a0)
                lea     (SharedSpriteScratch).w,a0
                jmp     (Sprite_AppendOAMEntries).l
; End of function StageIntro_UpdateStageNumberBanner
; Initializes the flashing EMERGENCY banner
StageIntro_InitializeEmergencyBanner:                   ; was: sub_AF82
                addq.w  #2,(MessageSequenceState).w
                move.l  #StageIntro_EmergencyGlyphSourceList,(MessageGlyphSourcePtr).w
                move.w  #$5400,(MessageGlyphVRAMCursor).w
; Streams the unique glyphs used by the EMERGENCY banner
StageIntro_LoadEmergencyGlyph:                          ; was: loc_AF94
                bsr.w   Message_LoadNextGlyphTile
                cmpi.w  #$58,(MessageSequenceState).w   ; 'X'
                beq.s   StageIntro_EmergencyGlyphReturn
                move.w  #$F0,(StageIntroBannerX).w
                move.w  #$100,(StageIntroBannerTimer).w
                move.b  #$D2,d0
                jsr     (Sound_QueueSFXRequest).l
StageIntro_EmergencyGlyphReturn:                        ; was: locret_AFB6
                                        ; StageIntro_UpdateEmergencyFlash+22   j
                rts
; End of function StageIntro_InitializeEmergencyBanner
; Updates the flashing EMERGENCY banner and its delay
StageIntro_UpdateEmergencyFlash:                        ; was: sub_AFB8
                cmpi.w  #$5C,(StageIntroBannerTimer).w  ; '\'
                bne.s   StageIntro_UpdateEmergencyDelay
                move.b  #$15,d0
                jsr     (Sound_QueueSFXRequest).l
StageIntro_UpdateEmergencyDelay:                        ; was: loc_AFCA
                subq.w  #1,(StageIntroBannerTimer).w
                bpl.s   StageIntro_CheckEmergencyFlashFrame
                clr.w   (MessageSequenceState).w
StageIntro_CheckEmergencyFlashFrame:                    ; was: loc_AFD4
                btst    #4,(StageIntroBannerTimer+1).w
                bne.s   StageIntro_EmergencyGlyphReturn
                lea     StageIntro_EmergencySpriteTileLayout(pc),a0
                nop
                bsr.w   Message_LoadSpriteTileIndices
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                move.w  #$EC,d0
                move.w  (StageIntroBannerX).w,d1
                moveq   #8,d7
; Writes the nine EMERGENCY sprite entries with horizontal spacing
StageIntro_WriteEmergencySprites:                       ; was: loc_AFF4
                move.w  d0,(a0)
                move.w  d1,6(a0)
                addi.w  #$C,d1
                addq.w  #8,a0
                dbf     d7,StageIntro_WriteEmergencySprites
                lea     (SharedSpriteScratch).w,a0
                jmp     (Sprite_AppendOAMEntries).l
; End of function StageIntro_UpdateEmergencyFlash
; Initializes pause timer before text exit
StageIntro_InitializePostBannerDelay:                   ; was: sub_B00E
                addq.w  #2,(MessageSequenceState).w
                move.w  #$50,(StageIntroPostDelay).w    ; 'P'
; Decrements pause timer each frame before text transition
StageIntro_UpdatePostBannerDelay:                       ; was: loc_B018
                subq.w  #1,(StageIntroPostDelay).w
                bpl.s   StageIntro_PostBannerDelayReturn
                move.w  #$2E,(MessageSequenceState).w   ; '.'
StageIntro_PostBannerDelayReturn:                       ; was: locret_B024
                rts
; End of function StageIntro_InitializePostBannerDelay
; Initializes the post-boss remaining-time bonus sequence
Results_InitializeTimeBonus:                            ; was: sub_B026
                addq.w  #2,(MessageSequenceState).w
                move.l  #Results_TimeBonusGlyphSourceList,(MessageGlyphSourcePtr).w
                move.w  #$5400,(MessageGlyphVRAMCursor).w
                rts
; End of function Results_InitializeTimeBonus
; Streams the unique glyphs used by the time-bonus display
Results_LoadTimeBonusGlyphs:                            ; was: sub_B03A
                bsr.w   Message_LoadNextGlyphTile
                cmpi.w  #$30,(MessageSequenceState).w   ; '0'
                beq.s   Results_LoadTimeBonusGlyphsReturn
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$E0,(PaletteRGBChannelMask).w
                move.b  #2,(PaletteRGBAdjustStep).w
                move.w  #$80,(ResultsTimeBonusAngle).w
                move.w  #$40,(ResultsTimeBonusRadius).w  ; '@'
                move.w  #$E8,(ResultsTimeBonusRadialY).w
                move.w  #$200,(MessageSpriteY).w
                move.w  #$108,(ResultsTimeBonusX0).w
                move.w  #$200,(ResultsTimeBonusX1).w
                move.b  #$BE,d0
                jsr     (Sound_QueueSFXRequest).l
Results_LoadTimeBonusGlyphsReturn:                      ; was: locret_B086
                rts
; End of function Results_LoadTimeBonusGlyphs
; Spins the time-bonus sprites inward while reducing their radial distance
Results_SpinInTimeBonus:                                ; was: sub_B088
                bsr.w   Results_RenderRadialTimeBonus
                move.w  (ResultsTimeBonusAngle).w,d0
                addq.w  #8,d0
                andi.w  #$1FE,d0
                move.w  d0,(ResultsTimeBonusAngle).w
                subq.w  #4,(ResultsTimeBonusRadius).w
                bpl.s   Results_SpinInTimeBonusReturn
                cmpi.w  #4,(ResultsTimeBonusRadius).w
                bpl.s   Results_SpinInTimeBonusReturn
                addq.w  #2,(MessageSequenceState).w
                clr.w   (ResultsTimeBonusAngle).w
                clr.w   (ResultsTimeBonusRadius).w
Results_SpinInTimeBonusReturn:                          ; was: locret_B0B4
                                        ; Results_SpinInTimeBonus+1E   j
                rts
; End of function Results_SpinInTimeBonus
; Contracts the time-bonus radius at a fixed angle before the hold state
Results_ContractTimeBonusRadius:                        ; was: sub_B0B6
                bsr.w   Results_RenderRadialTimeBonus
                subq.w  #1,(ResultsTimeBonusRadius).w
                cmpi.w  #$FFF4,(ResultsTimeBonusRadius).w
                bne.s   Results_ContractTimeBonusRadiusReturn
                addq.w  #2,(MessageSequenceState).w
                move.w  #$FFF4,(ResultsTimeBonusRadius).w
                move.w  #$20,(ResultsTimeBonusTimer).w  ; ' '
Results_ContractTimeBonusRadiusReturn:                  ; was: locret_B0D6
                rts
; Holds the radial bonus, then stores stage time and selects the zero/nonzero path
Results_WaitThenStoreTimeBonus:                         ; was: sub_B0D8
                bsr.w   Results_RenderRadialTimeBonus
                subq.w  #1,(ResultsTimeBonusTimer).w
                bpl.s   Results_WaitThenStoreTimeBonusReturn
                tst.b   (AlternateTimeBonusSound).w
                beq.s   Results_RequestTimeBonusSound
                move.b  #$83,d0
                jsr     (Sound_QueueBGMRequest).l
                bra.s   Results_StoreTimeBonus
; ---------------------------------------------------------------------------
Results_RequestTimeBonusSound:                          ; was: loc_B0F4
                move.b  #$C4,d0
                jsr     (Sound_QueueSFXRequest).l
Results_StoreTimeBonus:                                 ; was: loc_B0FE
                jsr     (Results_StoreStageCompletionTime).l
                tst.w   (StageTimeRemaining).w
                beq.s   Results_SkipZeroTimeBonus
                addq.w  #2,(MessageSequenceState).w
                move.w  #$F0,(MessageSpriteY).w
                move.w  (StageTimeRemaining).w,(ResultsTimeBonusBCD).w
                andi.w  #$FFF0,(ResultsTimeBonusBCD).w
                rts
; ---------------------------------------------------------------------------
Results_SkipZeroTimeBonus:                              ; was: loc_B122
                move.w  #$46,(MessageSequenceState).w   ; 'F'
                move.w  #$F0,(MessageSpriteY).w
                move.w  #$11A,(ResultsTimeBonusX0).w
Results_WaitThenStoreTimeBonusReturn:                   ; was: locret_B134
                rts
; End of function Results_WaitThenStoreTimeBonus
; Moves the linear time-bonus display into its held position
Results_AnimateTimeBonusEntry:                          ; was: sub_B136
                bsr.w   Results_RenderLinearTimeBonus
                subq.w  #1,(ResultsTimeBonusRadialY).w
                addq.w  #1,(MessageSpriteY).w
                cmpi.w  #$E0,(ResultsTimeBonusRadialY).w
                bne.s   Results_AnimateTimeBonusEntryReturn
                addq.w  #2,(MessageSequenceState).w
                move.w  #4,(ResultsTimeBonusTimer).w
Results_AnimateTimeBonusEntryReturn:                    ; was: locret_B154
                rts
; End of function Results_AnimateTimeBonusEntry
; Holds the linear time-bonus display before its exit
Results_HoldTimeBonus:                                  ; was: sub_B156
                bsr.w   Results_RenderLinearTimeBonus
                subq.w  #1,(ResultsTimeBonusTimer).w
                bpl.s   Results_HoldTimeBonusReturn
                addq.w  #2,(MessageSequenceState).w
                move.w  #$114,(ResultsTimeBonusX1).w
Results_HoldTimeBonusReturn:                            ; was: locret_B16A
                rts
; End of function Results_HoldTimeBonus
; Moves the linear time-bonus display out and advances the sequence
Results_AnimateTimeBonusExit:                           ; was: sub_B16C
                bsr.w   Results_RenderLinearTimeBonus
                subq.w  #2,(ResultsTimeBonusX0).w
                addq.w  #2,(ResultsTimeBonusX1).w
                cmpi.w  #$EC,(ResultsTimeBonusX0).w
                bne.s   Results_AnimateTimeBonusExitReturn
                addq.w  #4,(MessageSequenceState).w
                move.w  #$40,(ResultsTimeBonusTimer).w  ; '@'
Results_AnimateTimeBonusExitReturn:                     ; was: locret_B18A
                rts
; End of function Results_AnimateTimeBonusExit
; Adds the packed-BCD remaining stage time to the score and ends the sequence
Results_ApplyRemainingTimeBonus:                        ; was: sub_B18C
                                        ; ROM:0000A9E2   o
                bsr.w   Results_RenderLinearTimeBonus
                subq.w  #1,(ResultsTimeBonusTimer).w
                bpl.s   Results_ApplyRemainingTimeBonusReturn
                clr.w   (MessageSequenceState).w
                moveq   #0,d0
                move.w  (StageTimeRemaining).w,d0
                jsr     (Score_AddPackedBCD).l
Results_ApplyRemainingTimeBonusReturn:                  ; was: locret_B1A6
                rts
; End of function Results_ApplyRemainingTimeBonus
; Moves radial text sprites into their fixed display position
Message_MoveRadialTextIntoPlace:                        ; was: sub_B1A8
                                        ; ROM:0000A9E6   o
                bsr.w   Message_RenderRadialText
                addq.w  #1,(MessageSpriteY).w
                cmpi.w  #$FC,(MessageSpriteY).w
                bne.s   Message_MoveRadialTextIntoPlaceReturn
                addq.w  #2,(MessageSequenceState).w
                move.w  #$80,(MessageHoldTimer).w
Message_MoveRadialTextIntoPlaceReturn:                  ; was: locret_B1C2
                rts
; End of function Message_MoveRadialTextIntoPlace
; Holds radial text sprites until the sequence timer expires
Message_HoldRadialText:                                 ; was: sub_B1C4
                bsr.w   Message_RenderRadialText
                subq.w  #1,(MessageHoldTimer).w
                bpl.s   Message_HoldRadialTextReturn
                clr.w   (MessageSequenceState).w
Message_HoldRadialTextReturn:                           ; was: locret_B1D2
                rts
; End of function Message_HoldRadialText
; Waits for frame timer countdown before clearing state
Message_UpdateWaitTimer:                                ; was: sub_B1D4
                subq.w  #1,(MessageWaitTimer).w
                bpl.s   Message_UpdateWaitTimerReturn
                clr.w   (MessageSequenceState).w
Message_UpdateWaitTimerReturn:                          ; was: locret_B1DE
                rts
; End of function Message_UpdateWaitTimer
; Renders the radial form of the remaining-time bonus
Results_RenderRadialTimeBonus:                          ; was: sub_B1E0
                                        ; Results_ContractTimeBonusRadius   p
                                        ; Results_WaitThenStoreTimeBonus   p
                lea     Results_TimeBonusSpriteTileLayout(pc),a0
                nop
                bsr.w   Message_LoadSpriteTileIndices
                bsr.w   Results_PositionTimeBonusSprites
                lea     (SharedSpriteScratch).w,a0
                jmp     (Sprite_AppendOAMEntries).l
; End of function Results_RenderRadialTimeBonus
; Renders the linear form of the remaining-time bonus
Results_RenderLinearTimeBonus:                          ; was: sub_B1F8
                                        ; sub_B156   p
                lea     Results_TimeBonusSpriteTileLayout(pc),a0
                nop
                bsr.w   Message_LoadSpriteTileIndices
                bsr.w   Results_ApplyTimeDigitTileOffsets
                bsr.w   Results_PositionTimeBonusSprites
                lea     (SharedSpriteScratch).w,a0
                jmp     (Sprite_AppendOAMEntries).l
; End of function Results_RenderLinearTimeBonus
; Renders the generic radial-text sprite arrangement
Message_RenderRadialText:                               ; was: sub_B214
                                        ; Message_HoldRadialText   p
                lea     Message_RadialTextSpriteTileLayout(pc),a0
                nop
                bsr.w   Message_LoadSpriteTileIndices
                bsr.w   Message_PositionRadialTextSprites
                lea     (SharedSpriteScratch).w,a0
                jmp     (Sprite_AppendOAMEntries).l
; End of function Message_RenderRadialText
; Writes the remaining-time bonus sprite positions
Results_PositionTimeBonusSprites:                       ; was: sub_B22C
                                        ; Results_RenderLinearTimeBonus+E   p
                bsr.w   Message_CalculateRadialSpriteCoords
                move.w  (ResultsTimeBonusX1).w,d1
                moveq   #3,d7
Results_WriteTimeBonusSpritePositions:                  ; was: loc_B236
                move.w  (MessageSpriteY).w,(a0)
                move.w  d1,(a1)
                addq.w  #8,a0
                addq.w  #8,a1
                addi.w  #$C,d1
                dbf     d7,Results_WriteTimeBonusSpritePositions
                rts
; End of function Results_PositionTimeBonusSprites
; Writes the two central radial-text sprite positions
Message_PositionRadialTextSprites:                      ; was: sub_B24A
                bsr.w   Message_CalculateRadialSpriteCoords
                subi.w  #$60,d1                         ; '`'
                moveq   #1,d7
Message_WriteRadialTextSpritePositions:                 ; was: loc_B254
                move.w  (MessageSpriteY).w,(a0)
                move.w  d1,(a1)
                addq.w  #8,a0
                addq.w  #8,a1
                addi.w  #$C,d1
                dbf     d7,Message_WriteRadialTextSpritePositions
                rts
; End of function Message_PositionRadialTextSprites
; Calculates symmetric sine/cosine coordinates and the linear sprite row
Message_CalculateRadialSpriteCoords:                    ; was: sub_B268
                                        ; sub_B24A   p
                movea.w #(RadialSpriteYBackward-M68K_RAM),a0
                movea.w #(RadialSpriteXBackward-M68K_RAM),a1
                movea.w #(RadialSpriteYForward-M68K_RAM),a2
                movea.w #(RadialSpriteXForward-M68K_RAM),a3
                movea.l #Math_SineTable,a4
                move.w  (RadialTextAngle).w,d0
                move.w  (RadialTextRadius).w,d1
                move.w  d1,d4
                move.w  (RadialTextCenterY).w,d6
                moveq   #4,d7
Message_CalculateRadialSpritePairLoop:                  ; was: loc_B28E
                move.w  -$80(a4,d0.w),d2
                move.w  (a4,d0.w),d3
                muls.w  d4,d2
                muls.w  d4,d3
                asl.l   #2,d2
                asl.l   #2,d3
                swap    d2
                swap    d3
                move.w  d2,(a0)
                move.w  d3,(a1)
                add.w   d6,(a0)
                addi.w  #$120,(a1)
                neg.w   d2
                neg.w   d3
                add.w   d6,d2
                addi.w  #$120,d3
                move.w  d2,(a2)
                move.w  d3,(a3)
                subq.w  #8,a0
                subq.w  #8,a1
                addq.w  #8,a2
                addq.w  #8,a3
                add.w   d1,d4
                dbf     d7,Message_CalculateRadialSpritePairLoop
                movea.w #(LinearSpriteYStart-M68K_RAM),a0
                movea.w #(LinearSpriteXStart-M68K_RAM),a1
                move.w  (LinearSpriteX).w,d1
                moveq   #4,d7
Message_WriteLinearSpritePositions:                     ; was: loc_B2D6
                move.w  (MessageSpriteY).w,(a0)
                move.w  d1,(a1)
                addq.w  #8,a0
                addq.w  #8,a1
                addi.w  #$C,d1
                dbf     d7,Message_WriteLinearSpritePositions
                rts
; End of function Message_CalculateRadialSpriteCoords
; Applies four packed-BCD timer digits to the bonus sprite tile words
Results_ApplyTimeDigitTileOffsets:                      ; was: sub_B2EA
                movea.w #(TimeDigitTileWordStart-M68K_RAM),a0
                move.b  (ResultsTimeBonusBCD).w,d0
                move.b  d0,d1
                asr.w   #4,d1
                andi.w  #$F,d0
                andi.w  #$F,d1
                add.w   d0,d0
                add.w   d1,d1
                add.w   d1,(a0)
                add.w   d0,8(a0)
                move.b  (ResultsTimeBonusBCD+1).w,d0
                move.b  d0,d1
                asr.w   #4,d1
                andi.w  #$F,d0
                andi.w  #$F,d1
                add.w   d0,d0
                add.w   d1,d1
                add.w   d1,$10(a0)
                add.w   d0,$18(a0)
                rts
; End of function Results_ApplyTimeDigitTileOffsets
; Expands byte tile indices into sprite tile words
Message_LoadSpriteTileIndices:                          ; was: sub_B326
                                        ; StageIntro_UpdateEmergencyFlash+2A   p
                movea.w #(SpriteScratchTileWord0-M68K_RAM),a1
                move.w  #$100,d1
Message_LoadNextSpriteTileIndex:                        ; was: loc_B32E
                moveq   #0,d0
                move.b  (a0)+,d0
                bmi.s   Message_TerminateSpriteTileList
                addi.w  #-$1960,d0
                bclr    #0,d0
                bne.s   Message_StoreSpriteTileIndex
                subi.w  #$2000,d0
Message_StoreSpriteTileIndex:                           ; was: loc_B342
                move.w  d0,(a1)
                move.w  d1,-2(a1)
                addq.w  #8,a1
                bra.s   Message_LoadNextSpriteTileIndex
; ---------------------------------------------------------------------------
; Writes the terminator after the expanded sprite tile list
Message_TerminateSpriteTileList:                        ; was: loc_B34C
                move.w  #$FFFF,-4(a1)
                rts
; End of function Message_LoadSpriteTileIndices
; ---------------------------------------------------------------------------
Results_TimeBonusSpriteTileLayout:  dc.w    $1416, $181A, $1C1E, $201C, $1822, $2426, $282A, $1400, 0, $FF  ; was: word_B354
                                        ; sub_B1F8   o
Message_RadialTextSpriteTileLayout:     dc.w    $1416, $181A, $1C1E, $201C, $1822, $2426, $282A, $1428, $26FF  ; was: word_B368
StageIntro_StageNumberSpriteTileLayout: dc.w    $1416, $181A, $1C00, $FF  ; was: word_B37A
StageIntro_EmergencySpriteTileLayout:   dc.w    2, 4, $600, $80A, $CFF  ; was: word_B382

; Copies one unique font glyph and queues its VRAM transfer
Message_LoadNextGlyphTile:                              ; was: sub_B38C
                                        ; StageIntro_LoadStageNumberGlyph   p
                                        ; StageIntro_LoadEmergencyGlyph   p
                                        ; Results_LoadTimeBonusGlyphs   p
                                        ; MessageSequence_AdvanceState   p
                movea.l (MessageGlyphSourcePtr).w,a0
                moveq   #0,d0
                move.b  (a0)+,d0
                cmpi.b  #$FF,d0
                bne.s   Message_CopyGlyphTile
                addq.w  #2,(MessageSequenceState).w
                rts
; ---------------------------------------------------------------------------
Message_CopyGlyphTile:                                  ; was: loc_B3A0
                move.l  a0,(MessageGlyphSourcePtr).w
                asl.w   #6,d0
                addi.l  #SharedFontTileArt,d0
                movea.l d0,a0
                movea.w #(MessageGlyphTileBuffer-M68K_RAM),a1
                moveq   #$F,d7
Message_CopyGlyphTileLoop:                              ; was: loc_B3B4
                move.l  (a0)+,(a1)+
                dbf     d7,Message_CopyGlyphTileLoop
                movea.w (VDPCommandQueueHead).w,a5
                move.w  #$83,-(a5)
                move.w  (MessageGlyphVRAMCursor).w,-(a5)
                move.w  #$9580,-(a5)
                move.w  #$96D1,-(a5)
                move.l  #$8F02977F,-(a5)
                move.l  #$94009320,-(a5)
                move.w  a5,(VDPCommandQueueHead).w
                addi.w  #$40,(MessageGlyphVRAMCursor).w  ; '@'
                rts
; End of function Message_LoadNextGlyphTile
; Renders a message sprite line with caller-provided position offsets
Message_RenderLineWithOffsets:                          ; was: sub_B3E6
                move.w  (BattleBannerVelocity).w,d5
                move.w  (BattleBannerOffset).w,d6
                bra.s   Message_RenderLineWithCurrentOffsets
; End of function Message_RenderLineWithOffsets
; Renders a message sprite line without position offsets
Message_RenderLine:                                     ; was: sub_B3F0
                                        ; BattleBanner_StartFightLine+6   p
                btst    #3,(FrameCounter+1).w
                bne.s   Message_RenderLineReturn
                moveq   #0,d5
                moveq   #0,d6
Message_RenderLineWithCurrentOffsets:                   ; was: loc_B3FC
                bsr.s   Message_WriteSpriteLine
                lea     (SharedSpriteScratch).w,a0
                jsr     (Sprite_AppendOAMEntries).l
Message_RenderLineReturn:                               ; was: locret_B408
                rts
; End of function Message_RenderLine
; Expands one compact message-line descriptor into sprite entries
Message_WriteSpriteLine:                                ; was: sub_B40A
                move.w  (a0)+,d0
                move.w  (a0)+,d1
                moveq   #0,d2
                move.b  (a0)+,d2
                addi.w  #$80,d2
                add.w   d6,d2
                moveq   #0,d3
                move.b  (a0)+,d3
                add.w   d5,d3
                move.w  #$100,d4
                movea.w #(SharedSpriteScratch-M68K_RAM),a1
                move.w  (a0)+,d7
; Writes each sprite entry in the compact message line
Message_WriteSpriteLineLoop:                            ; was: loc_B428
                move.w  d2,(a1)+
                move.w  d4,(a1)+
                move.w  d0,(a1)+
                move.w  d1,(a1)+
                addq.w  #2,d0
                add.w   d3,d1
                dbf     d7,Message_WriteSpriteLineLoop
                move.w  #$FFFF,(a1)
                rts
; End of function Message_WriteSpriteLine
