; Loads stage-entry assets and starts the READY delay
StageReady_Initialize:                                  ; was: sub_1DFB6
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                jsr     (Sys_InitGameMode).l
                jsr     (Gfx_QueueSmallFontDMACommand83).l
                jsr     (Stage_LoadAssetsForCurrentTableIndex).l
                movea.l #StageEntryAssetLoadList,a0
                jsr     (LoadObjData).l
                addq.w  #4,(GameModeIndex).w
                move.w  #$40,(GameSubstateIndex).w      ; '@'
                jsr     (Gfx_QueueSmallFontDMACommand83).l
                lea     (StageReadyPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.b  #0,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                jmp     Sound_QueueStageBGMOrStop
; End of function StageReady_Initialize
; ---------------------------------------------------------------------------
StageEntryAssetLoadList:    dc.w    3                   ; command: decompress tiles to VRAM  ; was: stru_1E012
                dc.l    SharedMenuType3DataF680         ; source
                dc.w    $F680                           ; destination: VRAM $F680
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    StageEntryAndWeaponSetupTileArtDE00  ; source
                dc.w    $DE00                           ; destination: VRAM $DE00
                dc.w    $FFFF

; Alternates READY during the stage-entry delay, then starts stage loading
StageReady_Update:                                      ; was: sub_1E024
                move.w  (GameSubstateIndex).w,d0
                subq.w  #1,d0
                bpl.s   StageReady_Update_DecrementDelay
                move.w  #$C,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                jmp     StageEntry_InitializeGameplayState
; ---------------------------------------------------------------------------
StageReady_Update_DecrementDelay:                       ; was: loc_1E03C
                move.w  d0,(GameSubstateIndex).w
                andi.w  #8,d0
                bne.s   StageReady_Update_RenderReady
                movea.l #Text_BlankStageReadyStatus,a0
                move.w  #$C6A0,d0
                move.w  #$46A0,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; ---------------------------------------------------------------------------
StageReady_Update_RenderReady:                          ; was: loc_1E05A
                movea.l #Text_SpacedReady,a0
                move.w  #$C6A0,d0
                move.w  #$46A0,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function StageReady_Update

; Initializes the otherwise unselected retry prompt
RetryPrompt_Initialize:                                 ; was: sub_1E06E
                tst.w   (GameSubstateIndex).w
                bne.s   RetryPrompt_Initialize_Activate
                addq.w  #2,(GameSubstateIndex).w
                jsr     (Sys_InitGameMode).l
                jsr     (Stage_LoadAssetsForCurrentTableIndex).l
                jsr     (Sys_ClearEntityObjectPool).l
                lea     (PostStageFullPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                move.b  #0,(VDPReg18Shadow+1).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
RetryPrompt_Initialize_Activate:                        ; was: loc_1E0C4
                addq.w  #4,(GameModeIndex).w
                jsr     (Gfx_FadePaletteTransition).l
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (PrimaryCameraYPosition).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                lea     (Text_YouLostThreeChances).l,a0
                move.w  #$C300,d0
                move.w  #$4198,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_TryAgain).l,a0
                move.w  #$C300,d0
                move.w  #$448A,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_PressStart).l,a0
                move.w  #$C300,d0
                move.w  #$4A9C,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function RetryPrompt_Initialize

; Handles retry-prompt confirmation and restores stage-entry assets
RetryPrompt_Update:                                     ; was: sub_1E124
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   RetryPrompt_Update_CheckConfirm
                move.w  #$C,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                jsr     (StageEntry_ClearTransientState).l
                lea     StageEntryAssetLoadList(pc),a0
                jsr     (LoadObjData).l
                jmp     Sound_QueueStageBGMOrStop
; ---------------------------------------------------------------------------
RetryPrompt_Update_CheckConfirm:                        ; was: loc_1E14C
                tst.w   (PaletteFadeMode).w
                bne.s   RetryPrompt_UpdateFrame
                btst    #7,(ControllerPressedState).w
                beq.s   RetryPrompt_UpdateFrame
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
RetryPrompt_UpdateFrame:                                ; was: loc_1E164
                jsr     (Gfx_FadePaletteTransition).l
                rts
; End of function RetryPrompt_Update
