UI_InitOptionsScreen:                                   ; was: sub_95CA
                tst.w   (GameSubstateIndex).w
                bne.s   UI_InitOptionsScreenLoadDisplay
                jsr     (Sys_InitGameMode).l
                movea.l #Options_AssetLoadDescriptors,a0
                jsr     (LoadObjData).l
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                clr.b   (PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
UI_InitOptionsScreenLoadDisplay:                        ; was: loc_9612
                cmpi.w  #4,(GameSubstateIndex).w
                beq.w   UI_ActivateOptionsScreen
                addq.w  #2,(GameSubstateIndex).w
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                move.w  #$600,d0
                move.w  #0,d1
                move.w  d0,(SecondaryCameraXPos).w
                move.w  d1,(SecondaryCameraYPos).w
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                lea     (OptionsScreenPaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                jsr     (Gfx_FadePaletteTransition).l
                move.b  #0,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                clr.w   (PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                clr.w   (OptionsCursorFlashTimer).w
                clr.w   (OptionsHandlerOffset).w
                clr.b   (OptionsBGMIndex).w
                clr.b   (OptionsSFXIndex).w
                clr.b   (OptionsVoiceIndex).w
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                lea     (Text_Options).l,a0
                move.w  #$8300,d0
                move.w  #$4122,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_Level).l,a0
                move.w  #$8300,d0
                move.w  #$4290,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_BGMSwitch).l,a0
                move.w  #$8300,d0
                move.w  #$4490,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_SFXSwitch).l,a0
                move.w  #$8300,d0
                move.w  #$4590,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_BGMTest).l,a0
                move.w  #$8300,d0
                move.w  #$4710,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_SFXTest).l,a0
                move.w  #$8300,d0
                move.w  #$4810,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_VoiceTest).l,a0
                move.w  #$8300,d0
                move.w  #$4910,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_PressStartToExit).l,a0
                move.w  #$A300,d0
                move.w  #$4B14,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; ---------------------------------------------------------------------------
UI_ActivateOptionsScreen:                               ; was: loc_9728
                move.w  #$20,(GameModeIndex).w          ; ' '
                clr.w   (GameSubstateIndex).w
                move.w  #$118,d0
                move.w  #$B3,d1
                move.l  #FrontendCursor_SpriteMappings,d2
                jsr     (FrontendCursor_Initialize).l
                clr.b   (OptionsPressedCopy).w
                clr.b   (OptionsHeldCopy).w
                clr.b   d5
                bsr.w   UI_UpdateDifficultyOption
                clr.b   d5
                bsr.w   UI_UpdateBGMOption
                clr.b   d5
                bsr.w   UI_UpdateSFXOption
                clr.b   d5
                bsr.w   UI_UpdateBGMTest
                clr.b   d5
                bsr.w   UI_UpdateSFXTest
                clr.b   d5
                bsr.w   UI_UpdateVoiceTest
                rts
; End of function UI_InitOptionsScreen
; Updates options screen with input handling and object processing
UI_UpdateOptionsScreen:                                 ; was: sub_9774
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   UI_UpdateOptionsScreenActive
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                jmp     UI_ResetPaletteAndMessageMode_Clear
; ---------------------------------------------------------------------------
UI_UpdateOptionsScreenActive:                           ; was: loc_978C
                tst.w   (PaletteFadeMode).w
                bne.s   UI_UpdateOptionsScreenFrame
                btst    #7,(ControllerPressedState).w
                beq.s   UI_UpdateOptionsScreenFrame
                move.b  #2,(SoundFadeOutDelay).w
                move.b  #$C4,d0
                jsr     (Sound_QueueRequest).l
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
UI_UpdateOptionsScreenFrame:                            ; was: loc_97B4
                                        ; UI_UpdateOptionsScreen+24   j
                jsr     Frontend_AnimateMenuPalette(pc)  ; (pc)
                nop
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                jsr     (Sys_ProcessVisibleObjects).l
                bsr.w   UI_HandleOptionsInput
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function UI_UpdateOptionsScreen
; Processes directional input and button presses in options menu
UI_HandleOptionsInput:                                  ; was: sub_97EE
                bsr.w   FrontendCursor_UpdateFlash
                btst    #0,(OptionsCursorMoving).w
                bne.w   OptionsCursor_Animate
                btst    #0,(ControllerPressedState).w
                beq.s   UI_HandleOptionsInputCheckDown
                move.b  #$DB,d0
                jsr     (Sound_QueueRequest).l
                bset    #0,(OptionsCursorMoving).w
                move.w  #$10,(OptionsCursorFlashTimer).w
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                subq.w  #2,(OptionsHandlerOffset).w
                bpl.s   UI_HandleOptionsInputCheckDown
                move.w  #$A,(OptionsHandlerOffset).w
UI_HandleOptionsInputCheckDown:                         ; was: loc_982C
                                        ; UI_HandleOptionsInput+36   j
                btst    #1,(ControllerPressedState).w
                beq.w   UI_HandleOptionsInputUpdateCurrentRow
                move.b  #$DB,d0
                jsr     (Sound_QueueRequest).l
                bset    #0,(OptionsCursorMoving).w
                move.w  #$10,(OptionsCursorFlashTimer).w
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                addq.w  #2,(OptionsHandlerOffset).w
                cmpi.w  #$C,(OptionsHandlerOffset).w
                bmi.s   UI_HandleOptionsInputReturn
                clr.w   (OptionsHandlerOffset).w
UI_HandleOptionsInputReturn:                            ; was: locret_9862
                rts
; ---------------------------------------------------------------------------
UI_HandleOptionsInputUpdateCurrentRow:                  ; was: loc_9864
                move.b  (ControllerPressedState).w,(OptionsPressedCopy).w
                move.b  (ControllerHeldState).w,(OptionsHeldCopy).w
                move.b  (ControllerPressedState).w,d5
                btst    #4,d5
                beq.s   UI_HandleOptionsInputCheckHorizontal
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                move.b  #4,d0
                jmp     (Sound_QueueRequest).l
; ---------------------------------------------------------------------------
UI_HandleOptionsInputCheckHorizontal:                   ; was: loc_988A
                andi.b  #$60,d5                         ; '`'
UI_ProcessSelectedOptionInput:                          ; was: loc_988E
                move.b  (ControllerPressedState).w,d0
                andi.b  #$C,d0
                beq.s   UI_UpdateSelectedOptionRepeatDelay
                move.b  #$AD,d0
                jsr     (Sound_QueueRequest).l
UI_UpdateSelectedOptionRepeatDelay:                     ; was: loc_98A2
                btst    #2,(ControllerHeldState).w
                bne.s   UI_DecrementSelectedOptionRepeatDelay
                btst    #3,(ControllerHeldState).w
                bne.s   UI_DecrementSelectedOptionRepeatDelay
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                bra.s   UI_DispatchSelectedOption
; ---------------------------------------------------------------------------
UI_DecrementSelectedOptionRepeatDelay:                  ; was: loc_98BA
                                        ; UI_HandleOptionsInput+C2   j
                tst.w   (OptionsRepeatTimer).w
                beq.s   UI_DispatchSelectedOption
                subq.w  #1,(OptionsRepeatTimer).w
UI_DispatchSelectedOption:                              ; was: loc_98C4
                                        ; UI_HandleOptionsInput+D0   j
                move.w  (OptionsHandlerOffset).w,d0
                movea.w UI_OptionHandlerOffsets(pc,d0.w),a0
                adda.l  #UI_UpdateDifficultyOption,a0
                jmp     (a0)
; End of function UI_HandleOptionsInput
; ---------------------------------------------------------------------------
UI_OptionHandlerOffsets:    dc.w    UI_UpdateDifficultyOption-UI_UpdateDifficultyOption  ; was: off_98D4
                dc.w    UI_UpdateBGMOption-UI_UpdateDifficultyOption
                dc.w    UI_UpdateSFXOption-UI_UpdateDifficultyOption
                dc.w    UI_UpdateBGMTest-UI_UpdateDifficultyOption
                dc.w    UI_UpdateSFXTest-UI_UpdateDifficultyOption
                dc.w    UI_UpdateVoiceTest-UI_UpdateDifficultyOption

; Renders first row of options with tile graphics
UI_UpdateDifficultyOption:                              ; was: sub_98E0
                lea     Options_SuperEasyLabelTiles(pc),a1
                nop
                lea     Options_SuperHardLabelTiles(pc),a2
                nop
                movea.w #(DifficultyMode-M68K_RAM),a4
                move.w  #$429E,d6
                bra.w   Options_UpdateBit1Toggle
; End of function UI_UpdateDifficultyOption
; Update the BGM test entry, queue its request, and render its track label
UI_UpdateBGMTest:                                       ; was: sub_98F8
                movea.l #Options_BGMTestEntries,a1
                moveq   #0,d0
                move.b  (OptionsBGMIndex).w,d0
                asl.w   #5,d0
                adda.l  d0,a1
                tst.b   d5
                beq.s   UI_RenderBGMTestEntry
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                move.b  (a1),d0
                jmp     (Sound_QueueRequest).l
; ---------------------------------------------------------------------------
UI_RenderBGMTestEntry:                                  ; was: loc_991A
                movea.w (VDPStagingDataCursor).w,a0
                adda.l  #2,a1
                movea.l a1,a2
                moveq   #$E,d7
UI_CopyBGMTestEntryTopRow:                              ; was: loc_9928
                move.w  (a1)+,(a0)+
                dbf     d7,UI_CopyBGMTestEntryTopRow
                moveq   #$E,d7
UI_CopyBGMTestEntryBottomRow:                           ; was: loc_9930
                move.w  (a2)+,d0
                addq.w  #1,d0
                move.w  d0,(a0)+
                dbf     d7,UI_CopyBGMTestEntryBottomRow
                move.b  (OptionsBGMIndex).w,d0
                btst    #2,(OptionsPressedCopy).w
                beq.s   UI_CheckIncrementBGMTestSelection
                move.w  #$A,(OptionsCursorFlashTimer).w
                tst.b   d0
                bne.s   UI_DecrementBGMTestSelection
                move.b  #$14,d0
                bra.s   UI_StoreAndRenderBGMTestSelection
; ---------------------------------------------------------------------------
UI_DecrementBGMTestSelection:                           ; was: loc_9956
                subq.b  #1,d0
                bra.s   UI_StoreAndRenderBGMTestSelection
; ---------------------------------------------------------------------------
UI_CheckIncrementBGMTestSelection:                      ; was: loc_995A
                btst    #3,(OptionsPressedCopy).w
                beq.s   UI_StoreAndRenderBGMTestSelection
                move.w  #$A,(OptionsCursorFlashTimer).w
                cmpi.b  #$14,d0
                bne.s   UI_IncrementBGMTestSelection
                clr.b   d0
                bra.s   UI_StoreAndRenderBGMTestSelection
; ---------------------------------------------------------------------------
UI_IncrementBGMTestSelection:                           ; was: loc_9972
                addq.b  #1,d0
UI_StoreAndRenderBGMTestSelection:                      ; was: loc_9974
                                        ; UI_UpdateBGMTest+60   j
                move.b  d0,(OptionsBGMIndex).w
                move.w  #$4726,d0
                moveq   #$F,d3
                bsr.w   Options_QueueStagedTileDMA
                move.w  #$47A6,d0
                moveq   #$F,d3
                bra.w   Options_QueueStagedTileDMA
; End of function UI_UpdateBGMTest
; ---------------------------------------------------------------------------
; 22 records of 32 bytes; normal menu navigation selects indices 0..$14
; and leaves the final record preserved outside that selection range
Options_BGMTestEntries: binclude "data/other/options_bgm_test_entries.bin"  ; was: word_998C
Options_BGMTestEntries_End:                             ; was: word_998C_End

; Update the SFX test index and queue the selected low- or high-range SFX ID
UI_UpdateSFXTest:                                       ; was: sub_9C4C
                move.b  (OptionsSFXIndex).w,d0
                tst.b   d5
                beq.s   UI_UpdateSFXTestSelection
                lea     Options_SFXTestLowRequestIDs(pc),a0
                nop
                move.b  (a0,d0.w),d0
                jmp     (Sound_QueueRequest).l
; ---------------------------------------------------------------------------
UI_UpdateSFXTestSelection:                              ; was: loc_9C64
                moveq   #1,d1
                tst.w   (OptionsRepeatTimer).w
                bne.s   UI_CheckSFXTestPrimaryInput
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   UI_StoreAndRenderSFXTestSelection
                btst    #2,(OptionsHeldCopy).w
                bne.s   UI_SelectPreviousSFXTestIndex
                btst    #3,(OptionsHeldCopy).w
                bne.s   UI_SelectNextSFXTestIndex
                bra.s   UI_StoreAndRenderSFXTestSelection
; ---------------------------------------------------------------------------
UI_CheckSFXTestPrimaryInput:                            ; was: loc_9C86
                btst    #2,(OptionsPressedCopy).w
                beq.s   UI_CheckNextSFXTestInput
                move.w  #6,(OptionsCursorFlashTimer).w
UI_SelectPreviousSFXTestIndex:                          ; was: loc_9C94
                movem.l d0,-(sp)
                move.b  #4,d0
                jsr     (Sound_QueueRequest).l
                movem.l (sp)+,d0
                tst.b   d0
                bne.s   UI_DecrementSFXTestSelection
                move.b  #$98,d0
                bra.s   UI_StoreAndRenderSFXTestSelection
; ---------------------------------------------------------------------------
UI_DecrementSFXTestSelection:                           ; was: loc_9CB0
                subq.b  #1,d0
                bra.s   UI_StoreAndRenderSFXTestSelection
; ---------------------------------------------------------------------------
UI_CheckNextSFXTestInput:                               ; was: loc_9CB4
                btst    #3,(OptionsPressedCopy).w
                beq.s   UI_StoreAndRenderSFXTestSelection
                move.w  #6,(OptionsCursorFlashTimer).w
UI_SelectNextSFXTestIndex:                              ; was: loc_9CC2
                movem.l d0,-(sp)
                move.b  #4,d0
                jsr     (Sound_QueueRequest).l
                movem.l (sp)+,d0
                cmpi.b  #$98,d0
                bne.s   UI_IncrementSFXTestSelection
                clr.b   d0
                bra.s   UI_StoreAndRenderSFXTestSelection
; ---------------------------------------------------------------------------
UI_IncrementSFXTestSelection:                           ; was: loc_9CDE
                addq.b  #1,d0
UI_StoreAndRenderSFXTestSelection:                      ; was: loc_9CE0
                                        ; UI_UpdateSFXTest+38   j
                move.b  d0,(OptionsSFXIndex).w
                lea     (Math_PackedBCDLookup).l,a0
                asl.w   #1,d0
                andi.w  #$1FE,d0
                move.w  (a0,d0.w),d1
                move.w  #$483C,d0
                bra.w   Options_QueueThreeDigitBCD
; End of function UI_UpdateSFXTest
; Update the voice test index and queue the selected voice-DAC request ID
UI_UpdateVoiceTest:                                     ; was: sub_9CFC
                move.b  (OptionsVoiceIndex).w,d0
                tst.b   d5
                beq.s   UI_UpdateVoiceTestSelection
                lea     Options_VoiceTestRequestIDs(pc),a0
                nop
                move.b  (a0,d0.w),d0
                jmp     (Sound_QueueRequest).l
; ---------------------------------------------------------------------------
UI_UpdateVoiceTestSelection:                            ; was: loc_9D14
                moveq   #1,d1
                tst.w   (OptionsRepeatTimer).w
                bne.s   UI_CheckVoiceTestPrimaryInput
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   UI_StoreAndRenderVoiceTestSelection
                btst    #2,(OptionsHeldCopy).w
                bne.s   UI_SelectPreviousVoiceTestIndex
                btst    #3,(OptionsHeldCopy).w
                bne.s   UI_SelectNextVoiceTestIndex
                bra.s   UI_StoreAndRenderVoiceTestSelection
; ---------------------------------------------------------------------------
UI_CheckVoiceTestPrimaryInput:                          ; was: loc_9D36
                btst    #2,(OptionsPressedCopy).w
                beq.s   UI_CheckNextVoiceTestInput
                move.w  #6,(OptionsCursorFlashTimer).w
UI_SelectPreviousVoiceTestIndex:                        ; was: loc_9D44
                tst.b   d0
                bne.s   UI_DecrementVoiceTestSelection
                move.b  #$25,d0                         ; '%'
                bra.s   UI_StoreAndRenderVoiceTestSelection
; ---------------------------------------------------------------------------
UI_DecrementVoiceTestSelection:                         ; was: loc_9D4E
                subq.w  #1,d0
                bra.s   UI_StoreAndRenderVoiceTestSelection
; ---------------------------------------------------------------------------
UI_CheckNextVoiceTestInput:                             ; was: loc_9D52
                btst    #3,(OptionsPressedCopy).w
                beq.s   UI_StoreAndRenderVoiceTestSelection
                move.w  #6,(OptionsCursorFlashTimer).w
UI_SelectNextVoiceTestIndex:                            ; was: loc_9D60
                cmpi.b  #$25,d0                         ; '%'
                bne.s   UI_IncrementVoiceTestSelection
                clr.b   d0
                bra.s   UI_StoreAndRenderVoiceTestSelection
; ---------------------------------------------------------------------------
UI_IncrementVoiceTestSelection:                         ; was: loc_9D6A
                addq.w  #1,d0
UI_StoreAndRenderVoiceTestSelection:                    ; was: loc_9D6C
                                        ; UI_UpdateVoiceTest+38   j
                move.b  d0,(OptionsVoiceIndex).w
                lea     (Math_PackedBCDLookup).l,a0
                asl.w   #1,d0
                andi.w  #$1FE,d0
                move.w  (a0,d0.w),d1
                move.w  #$493E,d0
                bra.w   Options_QueueTwoDigitBCD
; End of function UI_UpdateVoiceTest
; Update the otherwise unreferenced message-mode toggle row
UI_UpdateMessageOption:
                lea     Options_OnLabelTiles(pc),a1     ; was: sub_9D88
                nop
                lea     Options_OffLabelTiles(pc),a2
                nop
                movea.w #(MessageMode-M68K_RAM),a4
                move.w  #$43B6,d6
                bra.w   Options_UpdateBit2Toggle
; End of function UI_UpdateMessageOption
; Update the BGM enable toggle in the shared sound-disable flags
UI_UpdateBGMOption:                                     ; was: sub_9DA0
                lea     Options_OnLabelTiles(pc),a1
                nop
                lea     Options_OffLabelTiles(pc),a2
                nop
                movea.w #(SoundDisableFlags-M68K_RAM),a4
                move.w  #$44B6,d6
                bra.w   Options_UpdateBit1Toggle
; End of function UI_UpdateBGMOption
; Update the SFX enable toggle in the shared sound-disable flags
UI_UpdateSFXOption:                                     ; was: sub_9DB8
                lea     Options_OnLabelTiles(pc),a1
                nop
                lea     Options_OffLabelTiles(pc),a2
                nop
                movea.w #(SoundDisableFlags-M68K_RAM),a4
                move.w  #$45B6,d6
                bra.w   Options_UpdateBit2Toggle
; End of function UI_UpdateSFXOption
; Initialize the secondary options path that reuses the three sound-test rows
UI_InitSecondaryOptionsMenu:                            ; was: sub_9DD0
                tst.w   (GameSubstateIndex).w
                bne.s   UI_ActivateSecondaryOptionsMenu
                jsr     (Sys_InitGameMode).l
                movea.l #Options_AssetLoadDescriptors,a0
                jsr     (LoadObjData).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                clr.b   (PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
UI_ActivateSecondaryOptionsMenu:                        ; was: loc_9E12
                addq.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                move.w  #$800,d0
                moveq   #0,d1
                jsr     (Tilemap_DirectTransferWithPrimaryDescriptor).l
                lea     (FrontendPaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                jsr     (Gfx_FadePaletteTransition).l
                move.b  #0,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                move.w  #$FFF0,(PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                clr.w   (OptionsCursorFlashTimer).w
                clr.w   (OptionsHandlerOffset).w
                clr.w   (OptionsSelection).w
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                move.w  #$118,d0
                move.w  #$CA,d1
                move.l  #FrontendCursor_SpriteMappings,d2
                jsr     (FrontendCursor_Initialize).l
                clr.b   (OptionsPressedCopy).w
                clr.b   (OptionsHeldCopy).w
; End of function UI_InitSecondaryOptionsMenu
; Update the secondary options path and its shared sound-test handlers
UI_UpdateSecondaryOptionsMenu:                          ; was: sub_9E88
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   UI_UpdateSecondaryOptionsMenuActive
                move.w  #$54,(GameModeIndex).w          ; 'T'
                clr.w   (GameSubstateIndex).w
                jmp     UI_ResetPaletteAndMessageMode_Clear
; ---------------------------------------------------------------------------
UI_UpdateSecondaryOptionsMenuActive:                    ; was: loc_9EA0
                tst.w   (PaletteFadeMode).w
                bne.s   UI_UpdateSecondaryOptionsMenuFrame
                btst    #7,(ControllerPressedState).w
                beq.s   UI_UpdateSecondaryOptionsMenuFrame
                move.b  #$C4,d0
                jsr     (Sound_QueueRequest).l
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
UI_UpdateSecondaryOptionsMenuFrame:                     ; was: loc_9EC2
                                        ; UI_UpdateSecondaryOptionsMenu+24   j
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                jsr     (Sys_ProcessVisibleObjects).l
                bsr.w   UI_HandleSecondaryOptionsInput
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function UI_UpdateSecondaryOptionsMenu
; Processes D-pad input for options menu cursor
UI_HandleSecondaryOptionsInput:                         ; was: sub_9EF6
                bsr.w   FrontendCursor_UpdateFlash
                btst    #0,(OptionsCursorMoving).w
                bne.w   SecondaryOptionsCursor_Animate
                move.w  (OptionsSelection).w,d0
                btst    #0,(ControllerPressedState).w
                beq.s   UI_HandleSecondaryOptionsInputCheckDown
                bset    #0,(OptionsCursorMoving).w
                move.w  #$10,(OptionsCursorFlashTimer).w
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                subq.w  #2,d0
                bpl.s   UI_PlaySecondaryOptionsMoveSound
                moveq   #0,d0
UI_HandleSecondaryOptionsInputCheckDown:                ; was: loc_9F28
                btst    #1,(ControllerPressedState).w
                beq.w   UI_StoreSecondaryOptionsSelection
                bset    #0,(OptionsCursorMoving).w
                move.w  #$10,(OptionsCursorFlashTimer).w
                move.w  #$20,(OptionsRepeatTimer).w     ; ' '
                addq.w  #2,d0
                cmpi.w  #6,d0
                bmi.s   UI_PlaySecondaryOptionsMoveSound
                moveq   #6,d0
                bra.s   UI_StoreSecondaryOptionsSelection
; ---------------------------------------------------------------------------
UI_PlaySecondaryOptionsMoveSound:                       ; was: loc_9F50
                                        ; UI_HandleSecondaryOptionsInput+54   j
                movem.l d0,-(sp)
                move.b  #$DB,d0
                jsr     (Sound_QueueRequest).l
                movem.l (sp)+,d0
UI_StoreSecondaryOptionsSelection:                      ; was: loc_9F62
                                        ; UI_HandleSecondaryOptionsInput+58   j
                move.w  d0,(OptionsSelection).w
                move.w  UI_SecondaryOptionsHandlerIndices(pc,d0.w),(OptionsHandlerOffset).w
                move.b  (ControllerPressedState).w,(OptionsPressedCopy).w
                move.b  (ControllerHeldState).w,(OptionsHeldCopy).w
                move.b  (ControllerPressedState).w,d5
                andi.b  #$60,d5                         ; '`'
                bra.w   UI_ProcessSelectedOptionInput
; End of function UI_HandleSecondaryOptionsInput
; ---------------------------------------------------------------------------
; Values 6, 8, and $A select the three sound-test entries above. Value $C
; reads opcode $43FA after that table and reaches ROM $DCDA; the purpose of
; this code/data overlay is unresolved. The $E entry is outside this clamp
UI_SecondaryOptionsHandlerIndices:  dc.w    6, 8, $A, $C, $E  ; was: word_9F84
