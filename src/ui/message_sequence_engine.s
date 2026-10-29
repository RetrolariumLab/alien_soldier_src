MessageSequence_Dispatch:                               ; was: sub_A970
                tst.b   (FrameControlFlags).w
                bpl.s   MessageSequence_CheckActiveState
MessageSequence_DispatchReturn:                         ; was: locret_A976
                rts
; ---------------------------------------------------------------------------
MessageSequence_CheckActiveState:                       ; was: loc_A978
                tst.w   (MessageSequenceState).w
                beq.s   MessageSequence_DispatchReturn
                btst    #0,(MessageSequenceFlags).w
                bne.s   MessageSequence_DispatchActiveState
                move.b  (ControllerPressedState).w,d0
                andi.b  #$70,d0                         ; 'p'
                move.b  d0,(MessageAdvanceButtons).w
MessageSequence_DispatchActiveState:                    ; was: loc_A992
                move.w  (MessageSequenceState).w,d0
                movea.w MessageSequence_HandlerTable(pc,d0.w),a0
                adda.l  #MessageSequence_AdvanceState,a0
                jmp     (a0)
; End of function MessageSequence_Dispatch
; ---------------------------------------------------------------------------
MessageSequence_HandlerTable:   dc.w    MessageSequence_Idle-MessageSequence_AdvanceState  ; was: off_A9A2
                dc.w    MessageSequence_AdvanceToScriptSetup-MessageSequence_AdvanceState
                dc.w    MessageScript_Begin-MessageSequence_AdvanceState
                dc.w    MessageScript_DispatchCommand-MessageSequence_AdvanceState
                dc.w    MessageScript_RenderGlyph-MessageSequence_AdvanceState
                dc.w    MessageScript_WaitAndRefreshGlyph-MessageSequence_AdvanceState
                dc.w    MessageScript_RenderTilemapChunk-MessageSequence_AdvanceState
                dc.w    MessageSequence_FinishScript-MessageSequence_AdvanceState
                dc.w    MessageSequence_AdvanceToScriptSetup-MessageSequence_AdvanceState
                dc.w    MessageScript_Begin-MessageSequence_AdvanceState
                dc.w    MessageScript_DispatchCommand-MessageSequence_AdvanceState
                dc.w    MessageScript_RenderGlyph-MessageSequence_AdvanceState
                dc.w    MessageScript_WaitAndRefreshGlyph-MessageSequence_AdvanceState
                dc.w    MessageScript_RenderTilemapChunk-MessageSequence_AdvanceState
                dc.w    BattleBanner_PrepareGlyphs-MessageSequence_AdvanceState
                dc.w    BattleBanner_LoadGlyphs-MessageSequence_AdvanceState
                dc.w    BattleBanner_HoldReadyLine-MessageSequence_AdvanceState
                dc.w    BattleBanner_StartFightLine-MessageSequence_AdvanceState
                dc.w    BattleBanner_AnimateFightLine-MessageSequence_AdvanceState
                dc.w    MessageSequence_AdvanceState-MessageSequence_AdvanceState
                dc.w    MessageScript_DispatchCommand-MessageSequence_AdvanceState
                dc.w    MessageScript_RenderGlyph-MessageSequence_AdvanceState
                dc.w    MessageSequence_End-MessageSequence_AdvanceState
                dc.w    Results_InitializeTimeBonus-MessageSequence_AdvanceState
                dc.w    Results_LoadTimeBonusGlyphs-MessageSequence_AdvanceState
                dc.w    Results_SpinInTimeBonus-MessageSequence_AdvanceState
                dc.w    Results_ContractTimeBonusRadius-MessageSequence_AdvanceState
                dc.w    Results_WaitThenStoreTimeBonus-MessageSequence_AdvanceState
                dc.w    Results_AnimateTimeBonusEntry-MessageSequence_AdvanceState
                dc.w    Results_HoldTimeBonus-MessageSequence_AdvanceState
                dc.w    Results_AnimateTimeBonusExit-MessageSequence_AdvanceState
                dc.w    Results_ApplyRemainingTimeBonus-MessageSequence_AdvanceState
                dc.w    Results_ApplyRemainingTimeBonus-MessageSequence_AdvanceState
                dc.w    Message_MoveRadialTextIntoPlace-MessageSequence_AdvanceState
                dc.w    Message_MoveRadialTextIntoPlace-MessageSequence_AdvanceState
                dc.w    Message_MoveRadialTextIntoPlace-MessageSequence_AdvanceState
                dc.w    Message_HoldRadialText-MessageSequence_AdvanceState
                dc.w    Message_UpdateWaitTimer-MessageSequence_AdvanceState
                dc.w    MessageSequence_Idle-MessageSequence_AdvanceState
                dc.w    MessageSequence_Idle-MessageSequence_AdvanceState
                dc.w    StageIntro_InitializeBanner-MessageSequence_AdvanceState
                dc.w    StageIntro_LoadStageNumberGlyph-MessageSequence_AdvanceState
                dc.w    StageIntro_UpdateStageNumberBanner-MessageSequence_AdvanceState
                dc.w    StageIntro_InitializeEmergencyBanner-MessageSequence_AdvanceState
                dc.w    StageIntro_LoadEmergencyGlyph-MessageSequence_AdvanceState
                dc.w    StageIntro_UpdateEmergencyFlash-MessageSequence_AdvanceState
                dc.w    StageIntro_InitializePostBannerDelay-MessageSequence_AdvanceState
                dc.w    StageIntro_UpdatePostBannerDelay-MessageSequence_AdvanceState

; Advances the shared message sequence by one state-table entry
MessageSequence_AdvanceState:                           ; was: sub_AA02
                                        ; ROM:MessageSequence_HandlerTable   o
                addq.w  #2,(MessageSequenceState).w
                rts
; End of function MessageSequence_AdvanceState
; Ends the shared message sequence
MessageSequence_End:                                    ; was: sub_AA08
                clr.w   (MessageSequenceState).w
                rts
; End of function MessageSequence_End
; Advances either script-entry path to its setup state
MessageSequence_AdvanceToScriptSetup:                   ; was: sub_AA0E
                                        ; ROM:0000A9B2   o
                addq.w  #2,(MessageSequenceState).w
                rts
; End of function MessageSequence_AdvanceToScriptSetup
; Ends an encoded message script and restores its graphics state
MessageSequence_FinishScript:                           ; was: sub_AA14
                clr.w   (MessageSequenceState).w
MessageSequence_FinalizeScriptGraphics:                 ; was: loc_AA18
                bclr    #7,(MessageDisplayFlags).w
                bsr.s   Message_QueueFontBasePatternDMAs
                jmp     UI_QueueAllWeaponIconTransfers
; End of function MessageSequence_FinishScript
; Queues the three fixed six-word font-base pattern transfers
Message_QueueFontBasePatternDMAs:                       ; was: sub_AA26
                movea.w (VDPCommandQueueHead).w,a1
                move.l  #MessageDisplay_FontBasePattern0,d0
                move.w  #$5080,d7
                bsr.s   Message_QueueFontBasePatternDMA
                move.l  #MessageDisplay_FontBasePattern1,d0
                move.w  #$5100,d7
                bsr.s   Message_QueueFontBasePatternDMA
                move.l  #MessageDisplay_FontBasePattern2,d0
                move.w  #$5180,d7
                bsr.s   Message_QueueFontBasePatternDMA
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function Message_QueueFontBasePatternDMAs
; Queues one six-word font-base pattern transfer to the supplied VDP destination
Message_QueueFontBasePatternDMA:                        ; was: sub_AA54
                                        ; Message_QueueFontBasePatternDMAs+1A   p
                move.w  #$83,-(a1)
                move.w  d7,-(a1)
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d1
                move.b  (DMASourceEncoding+1).w,d2
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.b  d2,-(a1)
                move.b  #$97,-(a1)
                move.w  #$8F02,-(a1)
                move.l  #$94009306,-(a1)
                rts
; End of function Message_QueueFontBasePatternDMA
; Finalizes prior script graphics, then prepares the READY/FIGHT glyph list
BattleBanner_PrepareGlyphs:                             ; was: sub_AA86
                bsr.s   MessageSequence_FinalizeScriptGraphics
                subq.w  #1,(BattleBannerDelay).w
                bpl.s   BattleBanner_PrepareGlyphsReturn
                addq.w  #2,(MessageSequenceState).w
                move.l  #BattleBanner_GlyphSourceList,(MessageGlyphSourcePtr).w
                move.w  #$5400,(MessageGlyphVRAMCursor).w
BattleBanner_PrepareGlyphsReturn:                       ; was: locret_AAA0
                rts
; End of function BattleBanner_PrepareGlyphs
; Streams the unique READY/FIGHT glyphs and initializes the banner delay
BattleBanner_LoadGlyphs:                                ; was: sub_AAA2
                bsr.w   Message_LoadNextGlyphTile
                cmpi.w  #$1E,(MessageSequenceState).w
                beq.s   BattleBanner_LoadGlyphsReturn
                move.b  #$16,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$60,(BattleBannerTimer).w      ; '`'
                move.w  #$64,(MessageWorkLong1).w       ; shared slot; value is not read before the next state overwrites it
BattleBanner_LoadGlyphsReturn:                          ; was: locret_AAC4
                rts
; End of function BattleBanner_LoadGlyphs
; Holds the READY sprite line until its countdown expires
BattleBanner_HoldReadyLine:                             ; was: sub_AAC6
                movea.l #BattleBanner_StaticSpriteLine,a0
                bsr.w   Message_RenderLine
                subq.w  #1,(BattleBannerTimer).w
                bpl.s   BattleBanner_HoldReadyLineReturn
                addq.w  #2,(MessageSequenceState).w
BattleBanner_HoldReadyLineReturn:                       ; was: locret_AADA
                rts
; End of function BattleBanner_HoldReadyLine
; Starts the moving FIGHT line and stores the current phase split time
BattleBanner_StartFightLine:                            ; was: sub_AADC
                movea.l #BattleBanner_StaticSpriteLine,a0
                bsr.w   Message_RenderLine
                move.b  #$17,d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,(MessageSequenceState).w
                move.w  #$34,(BattleBannerTimer).w      ; '4'
                clr.l   (BattleBannerOffset).w
                move.l  #$20000,(BattleBannerVelocity).w
                bclr    #0,(StageTimerPauseFlag).w
                jsr     (Results_StorePhaseSplitTime).l
                rts
; End of function BattleBanner_StartFightLine
; Animates the FIGHT line with a decreasing fixed-point velocity
BattleBanner_AnimateFightLine:                          ; was: sub_AB14
                subq.w  #1,(BattleBannerTimer).w
                bpl.s   BattleBanner_UpdateFightLineMotion
                clr.w   (MessageSequenceState).w
                rts
; ---------------------------------------------------------------------------
BattleBanner_UpdateFightLineMotion:                     ; was: loc_AB20
                move.l  (BattleBannerVelocity).w,d0
                add.l   d0,(BattleBannerOffset).w
                subi.l  #$2000,d0
                movem.l d0,-(sp)
                movea.l #BattleBanner_MovingSpriteLine,a0
                clr.l   (BattleBannerVelocity).w
                bsr.w   Message_RenderLineWithOffsets
                movem.l (sp)+,d0
                move.l  d0,(BattleBannerVelocity).w
                rts
; End of function BattleBanner_AnimateFightLine
; Starts either encoded message-script entry path and queues its font tiles
MessageScript_Begin:                                    ; was: sub_AB4A
                                        ; ROM:0000A9B4   o
                addq.w  #2,(MessageSequenceState).w
                bset    #7,(MessageDisplayFlags).w
                bsr.w   Message_QueueFontPatternFillDMAs
; End of function MessageScript_Begin
; Dispatches an encoded message command, terminator, or glyph record
MessageScript_DispatchCommand:                          ; was: sub_AB58
                                        ; ROM:0000A9B6   o
                movea.l (MessageScriptCursor).w,a0
                move.w  (a0),d0
                cmpi.w  #$FFFE,d0
                beq.w   MessageScript_QueueTileArtDMA
                cmpi.w  #$FFFF,d0
                bne.w   MessageScript_SetupGlyph
                addq.w  #8,(MessageSequenceState).w
                move.w  #$40,(MessageScriptEndTimer).w  ; '@'
                rts
; End of function MessageScript_DispatchCommand
; Decodes one message glyph record and initializes its render attributes
MessageScript_SetupGlyph:                               ; was: sub_AB7A
                addq.w  #2,(MessageSequenceState).w
                move.w  #$D0,(MessageGlyphDelay).w
                addq.l  #2,(MessageScriptCursor).w
                ext.l   d0
                adda.l  d0,a0
                moveq   #0,d4
                moveq   #0,d3
                move.b  (a0)+,d4
                move.b  (a0)+,d3
                asl.w   #8,d4
                add.w   d3,d4
                move.w  d4,d3
                andi.w  #$7FFE,d4
                move.l  a0,(MessageGlyphSourcePtr).w
                move.w  d4,(MessageTilemapVRAMPos).w
                move.w  #$C,(MessageWorkWord5).w        ; write-only in this path; results later reuse the slot as an X coordinate
                move.w  #$5400,(MessageGlyphVRAMCursor).w
                move.w  #$86A0,(MessageGlyphTileWord).w
                moveq   #0,d2
                btst    #0,d3
                beq.s   MessageScript_CheckGlyphPriority
                addi.w  #$2000,d2
MessageScript_CheckGlyphPriority:                       ; was: loc_ABC4
                tst.w   d3
                bpl.s   MessageScript_StoreGlyphAttributes
                addi.w  #$4000,d2
MessageScript_StoreGlyphAttributes:                     ; was: loc_ABCC
                add.w   d2,(MessageGlyphTileWord).w
; End of function MessageScript_SetupGlyph
; Idle message-sequence state
MessageSequence_Idle:                                   ; was: nullsub_22
                                        ; ROM:0000A9EE   o
                rts
; End of function MessageSequence_Idle
; Queues two fixed 32-word pattern-fill transfers
Message_QueueTwoPatternFillDMAs:                        ; was: sub_ABD2
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$5290,d0
                bsr.s   Message_QueuePatternFillDMA
                move.w  #$5310,d0
                bsr.s   Message_QueuePatternFillDMA
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function Message_QueueTwoPatternFillDMAs
; Queues one 32-word pattern-fill transfer to the supplied VDP destination
Message_QueuePatternFillDMA:                            ; was: sub_ABE8
                                        ; Message_QueueTwoPatternFillDMAs+E   p
                move.w  #$83,-(a1)
                move.w  d0,-(a1)
                move.l  #MessageDisplay_FontPatternFillSource,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d1
                move.b  (DMASourceEncoding+1).w,d2
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.b  d2,-(a1)
                move.b  #$97,-(a1)
                move.w  #$8F02,-(a1)
                move.l  #$94009320,-(a1)
                rts
; End of function Message_QueuePatternFillDMA
; Queues the three fixed 40-word font-pattern fill transfers used by message scripts
Message_QueueFontPatternFillDMAs:                       ; was: sub_AC20
                                        ; MessageScript_WaitAndRefreshGlyph+10   p
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$5080,d0
                bsr.s   Message_QueueFontPatternFillDMA
                move.w  #$5100,d0
                bsr.s   Message_QueueFontPatternFillDMA
                move.w  #$5180,d0
                bsr.s   Message_QueueFontPatternFillDMA
                move.w  a1,(VDPCommandQueueHead).w
                rts
; End of function Message_QueueFontPatternFillDMAs
; Queues one 40-word font-pattern fill transfer to the supplied VDP destination
Message_QueueFontPatternFillDMA:                        ; was: sub_AC3C
                                        ; Message_QueueFontPatternFillDMAs+E   p
                move.w  #$83,-(a1)
                move.w  d0,-(a1)
                move.l  #MessageDisplay_FontPatternFillSource,d0
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d1
                move.b  (DMASourceEncoding+1).w,d2
                move.b  d0,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.b  d2,-(a1)
                move.b  #$97,-(a1)
                move.w  #$8F02,-(a1)
                move.l  #$94009328,-(a1)
                rts
; End of function Message_QueueFontPatternFillDMA
; Copies one glyph tile, substitutes zero pixel nibbles, and queues tile and tilemap DMA
MessageScript_RenderGlyph:                              ; was: sub_AC74
                                        ; ROM:0000A9B8   o
                movea.l (MessageGlyphSourcePtr).w,a0
                moveq   #0,d0
                move.b  (a0),d0
                cmpi.b  #$FF,d0
                bne.s   MessageScript_DrawGlyph
                addq.w  #2,(MessageSequenceState).w
                rts
; ---------------------------------------------------------------------------
MessageScript_DrawGlyph:                                ; was: loc_AC88
                asl.w   #6,d0
                addi.l  #SharedFontTileArt,d0
                movea.l d0,a0
                movea.w #(MessageGlyphTileBuffer-M68K_RAM),a1
                moveq   #$F,d7
MessageScript_CopyGlyphRowLoop:                         ; was: loc_AC98
                move.l  (a0)+,d2
                move.l  d2,(MessageGlyphHiNibbleScratch).w
                move.l  d2,(MessageGlyphLoNibbleScratch).w
                andi.b  #$F0,(MessageGlyphHiNibbleScratch).w
                bne.s   MessageScript_CheckGlyphNibble2
                bset    #$1C,d2
MessageScript_CheckGlyphNibble2:                        ; was: loc_ACAE
                andi.b  #$F,(MessageGlyphLoNibbleScratch).w
                bne.s   MessageScript_CheckGlyphNibble3
                bset    #$18,d2
MessageScript_CheckGlyphNibble3:                        ; was: loc_ACBA
                andi.b  #$F0,(MessageGlyphHiNibbleScratch+1).w
                bne.s   MessageScript_CheckGlyphNibble4
                bset    #$14,d2
MessageScript_CheckGlyphNibble4:                        ; was: loc_ACC6
                andi.b  #$F,(MessageGlyphLoNibbleScratch+1).w
                bne.s   MessageScript_CheckGlyphNibble5
                bset    #$10,d2
MessageScript_CheckGlyphNibble5:                        ; was: loc_ACD2
                andi.b  #$F0,(MessageGlyphHiNibbleScratch+2).w
                bne.s   MessageScript_CheckGlyphNibble6
                bset    #$C,d2
MessageScript_CheckGlyphNibble6:                        ; was: loc_ACDE
                andi.b  #$F,(MessageGlyphLoNibbleScratch+2).w
                bne.s   MessageScript_CheckGlyphNibble7
                bset    #8,d2
MessageScript_CheckGlyphNibble7:                        ; was: loc_ACEA
                andi.b  #$F0,(MessageGlyphHiNibbleScratch+3).w
                bne.s   MessageScript_CheckGlyphNibble8
                bset    #4,d2
MessageScript_CheckGlyphNibble8:                        ; was: loc_ACF6
                andi.b  #$F,(MessageGlyphLoNibbleScratch+3).w
                bne.s   MessageScript_StoreGlyphRow
                bset    #0,d2
MessageScript_StoreGlyphRow:                            ; was: loc_AD02
                move.l  d2,(a1)+
                dbf     d7,MessageScript_CopyGlyphRowLoop
                movea.w (VDPCommandQueueHead).w,a5
                move.w  #$83,-(a5)
                move.w  (MessageGlyphVRAMCursor).w,-(a5)
                move.w  #$9580,-(a5)
                move.w  #$96D1,-(a5)
                move.l  #$8F02977F,-(a5)
                move.l  #$94009320,-(a5)
                movea.w (VDPStagingDataCursor).w,a0
                move.w  (MessageGlyphTileWord).w,d0
                move.w  d0,(a0)+
                addq.w  #1,d0
                move.w  d0,(a0)+
                move.w  #$83,-(a5)
                move.w  (MessageTilemapVRAMPos).w,-(a5)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a5)
                move.b  #$95,-(a5)
                move.b  d1,-(a5)
                move.b  #$96,-(a5)
                move.l  #$8F80977F,-(a5)
                move.l  #$94009302,-(a5)
                move.w  a5,(VDPCommandQueueHead).w
                addq.w  #4,(VDPStagingDataCursor).w
                addi.w  #$40,(MessageGlyphVRAMCursor).w  ; '@'
                addq.l  #1,(MessageGlyphSourcePtr).w
                addq.w  #2,(MessageTilemapVRAMPos).w
                addq.w  #2,(MessageGlyphTileWord).w
                subq.w  #1,(MessageGlyphDelay).w
                move.b  (MessageGlyphSourcePtr+3).w,d0
                andi.b  #3,d0
                bne.s   MessageScript_RenderGlyphReturn
                move.b  #$AD,d0
                jsr     (Sound_QueueSFXRequest).l
MessageScript_RenderGlyphReturn:                        ; was: locret_AD94
                rts
; End of function MessageScript_RenderGlyph
; Waits for the glyph delay or input, then refreshes the font-tile transfers
MessageScript_WaitAndRefreshGlyph:                      ; was: sub_AD96
                                        ; ROM:0000A9BA   o
                tst.b   (MessageAdvanceButtons).w
                bne.s   MessageScript_RefreshGlyphTiles
                subq.w  #1,(MessageGlyphDelay).w
                bpl.s   MessageScript_WaitAndRefreshGlyphReturn
MessageScript_RefreshGlyphTiles:                        ; was: loc_ADA2
                subq.w  #4,(MessageSequenceState).w
                bsr.w   Message_QueueFontPatternFillDMAs
MessageScript_WaitAndRefreshGlyphReturn:                ; was: locret_ADAA
                rts
; End of function MessageScript_WaitAndRefreshGlyph
; Decodes a script DMA command and queues 256 words of tile art to VRAM $5E00
MessageScript_QueueTileArtDMA:                          ; was: sub_ADAC
                addq.w  #6,(MessageSequenceState).w
                clr.w   (MessageTileChunkIndex).w
                addq.l  #6,(MessageScriptCursor).w
                movea.l (MessageScriptCursor).w,a0
                move.l  -4(a0),d0
                andi.l  #$3FFFFF,d0
                move.w  -4(a0),d1
                andi.w  #$E000,d1
                move.w  d1,(MessageTilemapAttrs).w
                movea.w (VDPCommandQueueHead).w,a5
                move.w  #$83,-(a5)
                move.w  #$5E00,-(a5)
                lsr.l   #1,d0
                move.l  d0,(DMASourceEncoding).w
                move.b  (DMASourceEncoding+2).w,d1
                move.b  (DMASourceEncoding+1).w,d2
                move.b  d0,-(a5)
                move.b  #$95,-(a5)
                move.b  d1,-(a5)
                move.b  #$96,-(a5)
                move.b  d2,-(a5)
                move.b  #$97,-(a5)
                move.w  #$8F02,-(a5)
                move.l  #$94019300,-(a5)
                move.w  a5,(VDPCommandQueueHead).w
                rts
; End of function MessageScript_QueueTileArtDMA
; Writes one four-word chunk of the script-provided tilemap
MessageScript_RenderTilemapChunk:                       ; was: sub_AE0E
                                        ; ROM:0000A9BC   o
                move.w  (MessageTileChunkIndex).w,d0
                move.w  d0,d3
                addq.w  #2,(MessageTileChunkIndex).w
                cmpi.w  #8,(MessageTileChunkIndex).w
                bmi.s   MessageScript_SelectTilemapHalf
                subq.w  #6,(MessageSequenceState).w
MessageScript_SelectTilemapHalf:                        ; was: loc_AE24
                move.w  (MessageTilemapAttrs).w,d2
                bclr    #$F,d2
                beq.s   MessageScript_WriteTilemapChunk
                addq.w  #8,d0
MessageScript_WriteTilemapChunk:                        ; was: loc_AE30
                movea.w (VDPStagingDataCursor).w,a1
                move.w  MessageScript_TileIndexGroups(pc,d0.w),d1
                add.w   d2,d1
                move.w  d1,(a1)+
                addq.w  #1,d1
                move.w  d1,(a1)+
                addq.w  #1,d1
                move.w  d1,(a1)+
                addq.w  #1,d1
                move.w  d1,(a1)+
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                move.w  MessageScript_TilemapVRAMDestinations(pc,d3.w),-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F80977F,-(a1)
                move.l  #$94009304,-(a1)
                move.w  a1,(VDPCommandQueueHead).w
                addq.w  #8,(VDPStagingDataCursor).w
                rts
; End of function MessageScript_RenderTilemapChunk
; ---------------------------------------------------------------------------
MessageScript_TilemapVRAMDestinations:  dc.w    $5004, $5006, $5008, $500A  ; was: word_AE82
MessageScript_TileIndexGroups:          dc.w    $6F0, $6F4, $6F8, $6FC, $6F0, $6F4, $EF4, $EF0  ; was: word_AE8A
