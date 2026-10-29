; Flashes the continue-credit display while an exit fade is active
Continue_UpdateCreditDisplayFlash:                      ; was: sub_1D94C
                btst    #1,(VBlankFrameCounter+1).w
                bne.s   Continue_RenderCreditCount
                move.w  #$2302,d1
                bra.s   Continue_RenderCreditCount_CheckDifficulty
; End of function Continue_UpdateCreditDisplayFlash

; Renders the remaining continue-credit count when required by the difficulty
Continue_RenderCreditCount:                             ; was: sub_1D95A
                move.w  #$4302,d1
Continue_RenderCreditCount_CheckDifficulty:             ; was: loc_1D95E
                tst.w   (DifficultyMode).w
                bne.s   Continue_RenderCreditCount_QueueDigits
                rts
; ---------------------------------------------------------------------------
Continue_RenderCreditCount_QueueDigits:                 ; was: loc_1D966
                moveq   #0,d0
                move.w  (ContinueCreditsBCD).w,d0
                move.w  #$6B42,d4
                moveq   #2,d7
                jmp     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Continue_RenderCreditCount

; Renders the CREDIT header and its two-digit placeholder
Continue_RenderCreditHeader:                            ; was: sub_1D978
                lea     (Text_CreditDash).l,a0
                move.w  #$2300,d0
                move.w  #$6B34,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_TwoDigitPlaceholder).l,a0
                move.w  #$300,d0
                move.w  #$6B42,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function Continue_RenderCreditHeader

Continue_RenderPrompt:                                  ; was: sub_1D9A0
                move.w  #$6300,d0
                movea.l #Text_Continue,a0
                move.w  #$669E,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function Continue_RenderPrompt

; Renders the integer digit of the fixed-point continue countdown
Continue_RenderCountdownDigit:                          ; was: sub_1D9B4
                moveq   #0,d0
                move.w  (ContinueCountdownValue).w,d0
                move.w  #$4302,d1
                move.w  #$66B0,d4
                moveq   #1,d7
                jsr     (Text_QueueTrimmedPackedBCDDigits).l
; End of function Continue_RenderCountdownDigit

; Renders the current stage number and difficulty on the continue screen
Continue_RenderStageAndDifficulty:                      ; was: sub_1D9CA
                lea     (Text_StageDash).l,a0
                move.w  #$2300,d0
                move.w  #$6B06,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                moveq   #0,d0
                move.w  (StageTableIndex).w,d0
                addq.w  #2,d0
                jsr     (Math_LookupPackedBCDWord).l
                move.w  #$4302,d1
                move.w  #$6B12,d4
                moveq   #2,d7
                jsr     (Text_QueueTrimmedPackedBCDDigits).l
                lea     (Text_TwoDigitPlaceholder).l,a0
                move.w  #$300,d0
                move.w  #$6B12,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_LevelDash).l,a0
                move.w  #$2300,d0
                move.w  #$6B1A,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_Easy).l,a0
                tst.w   (DifficultyMode).w
                beq.s   Continue_RenderStageAndDifficulty_RenderDifficulty
                lea     (Text_Hard).l,a0
Continue_RenderStageAndDifficulty_RenderDifficulty:     ; was: loc_1DA36
                move.w  #$4300,d0
                move.w  #$6B26,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function Continue_RenderStageAndDifficulty

; Renders the password associated with the current stage and difficulty
Continue_RenderPassword:                                ; was: sub_1DA44
                lea     (Text_PasswordDash).l,a0
                move.w  #$2300,d0
                move.w  #$6B32,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                move.w  (StageTableIndex).w,d0
                asl.w   #2,d0
                addi.l  #Password_StageCodeTable,d0
                moveq   #0,d1
                move.w  (DifficultyMode).w,d1
                asl.w   #1,d1
                add.l   d1,d0
                movea.l d0,a0
                movea.w #(PasswordSecondaryBuffer-M68K_RAM),a1
                move.l  (a0),(a1)+
                move.l  (a0),(PasswordDigits).w
                move.b  #$FF,(a1)
                movea.w #(PasswordSecondaryBuffer-M68K_RAM),a0
                move.w  #$4300,d0
                move.w  #$6B44,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function Continue_RenderPassword

Continue_InitializeScreen:                              ; was: sub_1DA90
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                clr.l   (PrimaryCameraXPosition).w
                clr.l   (PrimaryCameraYPosition).w
                clr.l   (SecondaryCameraXPos).w
                clr.l   (SecondaryCameraYPos).w
                tst.w   (ContinueCreditsBCD).w
                bne.s   Continue_InitializeScreen_BuildScreen
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
Continue_InitializeScreen_BuildScreen:                  ; was: loc_1DABC
                addq.w  #2,(GameSubstateIndex).w
                move.l  #$A0000,(ContinueCountdownValue).w
                subi.l  #$200,(ContinueCountdownValue).w
                lea     (ContinueScreenPaletteOffsetLists).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                bsr.w   Continue_RenderPrompt
                bsr.w   Continue_RenderStageAndDifficulty
                move.w  #$4000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                tst.w   (DifficultyMode).w
                beq.s   Continue_InitializeScreen_RenderPassword
                bra.w   Continue_RenderCreditHeader
; ---------------------------------------------------------------------------
Continue_InitializeScreen_RenderPassword:               ; was: loc_1DB24
                bra.w   Continue_RenderPassword
; End of function Continue_InitializeScreen

; Activates the continue screen after its fade-in completes
Continue_ActivateScreen:                                ; was: sub_1DB28
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                bsr.w   Continue_RenderCreditCount
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   Continue_ActivateScreen_Return
                addq.w  #2,(GameSubstateIndex).w
                move.b  #$94,d0
                jsr     (Sound_QueueBGMRequest).l
Continue_ActivateScreen_Return:                         ; was: locret_1DB5A
                rts
; End of function Continue_ActivateScreen

; Updates the countdown and handles timeout or confirmation input
Continue_UpdateCountdownAndInput:                       ; was: sub_1DB5C
                bsr.w   Continue_RenderCreditCount
                bsr.w   Continue_RenderCountdownDigit
                move.b  (ControllerPressedState).w,d0
                andi.b  #$70,d0                         ; 'p'
                beq.s   Continue_UpdateCountdownAndInput_AdvanceCountdown
                move.b  #$A2,d0
                jsr     (Sound_QueueRequest).l
                subq.w  #1,(ContinueCountdownValue).w
                bmi.s   Continue_UpdateCountdownAndInput_StartTimeoutFade
                bra.s   Continue_UpdateCountdownAndInput_CheckConfirm
; ---------------------------------------------------------------------------
Continue_UpdateCountdownAndInput_AdvanceCountdown:      ; was: loc_1DB80
                move.w  (ContinueCountdownValue).w,d0
                subi.l  #$200,(ContinueCountdownValue).w
                bpl.s   Continue_UpdateCountdownAndInput_CheckCountdownTick
Continue_UpdateCountdownAndInput_StartTimeoutFade:      ; was: loc_1DB8E
                addq.w  #4,(GameSubstateIndex).w
                move.b  #1,d0
                jsr     (Sound_QueueRequest).l
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                bra.w   Continue_UpdateFrame
; ---------------------------------------------------------------------------
Continue_UpdateCountdownAndInput_CheckCountdownTick:    ; was: loc_1DBB0
                cmp.w   (ContinueCountdownValue).w,d0
                beq.s   Continue_UpdateCountdownAndInput_CheckConfirm
                move.b  #$A2,d0
                jsr     (Sound_QueueRequest).l
Continue_UpdateCountdownAndInput_CheckConfirm:          ; was: loc_1DBC0
                btst    #7,(ControllerPressedState).w
                beq.s   Continue_UpdateFrame
                addq.w  #2,(GameSubstateIndex).w
                move.b  #1,d0
                jsr     (Sound_QueueRequest).l
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                tst.w   (DifficultyMode).w
                beq.s   Continue_UpdateFrame
                sub.w   d0,d0
                move.b  (ContinueCreditsBCD+1).w,d0
                moveq   #1,d1
                sbcd    d1,d0
                move.b  d0,(ContinueCreditsBCD+1).w
Continue_UpdateFrame:                                   ; was: loc_1DBFA
                jsr     (Gfx_FadePaletteTransition).l
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function Continue_UpdateCountdownAndInput

; Routes a confirmed continue after its fade according to difficulty
Continue_ApplyChoiceAfterFade:                          ; was: sub_1DC06
                bsr.w   Continue_UpdateCreditDisplayFlash
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   Continue_UpdateFrame
                tst.w   (DifficultyMode).w
                beq.s   Continue_ApplyChoiceAfterFade_ResumeGameplay
                move.w  #$3C,(GameModeIndex).w          ; '<'
                clr.w   (GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
Continue_ApplyChoiceAfterFade_ResumeGameplay:           ; was: loc_1DC24
                move.w  #$70,(GameModeIndex).w          ; 'p'
                clr.w   (GameSubstateIndex).w
                jmp     StageEntry_InitializeGameplayState
; End of function Continue_ApplyChoiceAfterFade

; Returns to the title screen after a timed-out continue fade
Continue_ReturnToTitleAfterFade:                        ; was: sub_1DC34
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   Continue_UpdateFrame
                addq.w  #2,(GameSubstateIndex).w
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                rts
; End of function Continue_ReturnToTitleAfterFade
