Password_CharacterCursorSpriteMapping:  dc.w    $C101, $600, $F4F8  ; was: word_A394
Password_ConfirmCursorSpriteMapping:    dc.w    $C101, $E00, $F4F0  ; was: word_A39A
; Starts the title-menu password editor and its fade-out setup
PasswordMenu_Initialize:                                ; was: sub_A3A0
                tst.w   (GameSubstateIndex).w
                bne.s   PasswordMenu_Activate
                jsr     (Sys_InitGameMode).l
                movea.l #Options_AssetLoadDescriptors,a0
                jsr     (LoadObjData).l
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
; Loads the password editor display, cursor, text buffers, and palette overrides
PasswordMenu_Activate:                                  ; was: loc_A3EA
                move.w  #$48,(GameModeIndex).w          ; 'H'
                clr.w   (GameSubstateIndex).w
                move.w  #$400,d0
                moveq   #0,d1
                jsr     (Tilemap_DirectTransferWithPrimaryDescriptor).l
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                move.w  #$600,d0
                move.w  #0,d1
                move.w  d0,(SecondaryCameraXPos).w
                move.w  d1,(SecondaryCameraYPos).w
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                lea     (FrontendPaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     PasswordMenu_PaletteOverrides(pc),a0
                nop
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a1
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                jsr     (Gfx_FadePaletteTransition).l
                move.b  #0,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                clr.w   (PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                move.w  #$F4,d0
                move.w  #$DA,d1
                move.l  #Password_CharacterCursorSpriteMapping,d2
                bsr.w   FrontendCursor_Initialize
                clr.w   (PasswordCursorFlash).w
                clr.w   (PasswordCursorOffset).w
                move.b  #$F,(PasswordHeldNibble).w
                move.w  #$18,(PasswordRepeatTimer).w
                clr.w   (PasswordCursorMoveFlag).w
                lea     (Text_PressStartToExit).l,a0
                move.w  #$A300,d0
                move.w  #$4A14,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                rts
; End of function PasswordMenu_Initialize
; ---------------------------------------------------------------------------
PasswordMenu_PaletteOverrides:  dc.w    $20, $AEC, $8CA, $6A8, $486  ; was: word_A4AC

; Updates the title-menu password editor
PasswordMenu_Update:                                    ; was: sub_A4B6
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   PasswordMenu_CheckExitRequest
                move.w  #$14,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                jmp     UI_ResetPaletteAndMessageMode_Clear
; ---------------------------------------------------------------------------
PasswordMenu_CheckExitRequest:                          ; was: loc_A4CE
                tst.w   (PaletteFadeMode).w
                bne.s   PasswordMenu_UpdateFrame
                btst    #7,(ControllerPressedState).w
                beq.s   PasswordMenu_UpdateFrame
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
PasswordMenu_UpdateFrame:                               ; was: loc_A4EC
                                        ; PasswordMenu_Update+24   j
                jsr     (FrontendCursor_UpdateFlash).l
                jsr     (Frontend_AnimateMenuPalette).l
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                bsr.w   PasswordMenu_HandleInput
                movea.w #(PasswordPrimaryBuffer-M68K_RAM),a0
                move.w  #$8300,d0
                move.w  #$4714,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                movea.w #(PasswordSecondaryBuffer-M68K_RAM),a0
                move.w  #$8300,d0
                move.w  #$4814,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                jsr     (Sys_ProcessVisibleObjects).l
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function PasswordMenu_Update
; Handles field navigation, digit editing, and password validation
PasswordMenu_HandleInput:                               ; was: sub_A550
                tst.w   (PasswordCursorMoveFlag).w
                bne.w   PasswordCursor_AnimateToSelection
                move.w  (PasswordCursorOffset).w,d0
                moveq   #0,d1
                btst    #2,(ControllerPressedState).w
                beq.s   PasswordInput_CheckMoveRight
                moveq   #2,d1
                move.w  #$10,(PasswordCursorFlash).w
                subq.w  #2,d0
                bpl.s   PasswordInput_PlayMoveSound
                moveq   #0,d0
                bra.s   PasswordInput_StoreSelection
; ---------------------------------------------------------------------------
PasswordInput_CheckMoveRight:                           ; was: loc_A576
                btst    #3,(ControllerPressedState).w
                beq.s   PasswordInput_StoreSelection
                moveq   #2,d1
                move.w  #$10,(PasswordCursorFlash).w
                addq.w  #2,d0
                cmpi.w  #$A,d0
                bmi.s   PasswordInput_PlayMoveSound
                moveq   #8,d0
                bra.s   PasswordInput_StoreSelection
; ---------------------------------------------------------------------------
PasswordInput_PlayMoveSound:                            ; was: loc_A592
                                        ; PasswordMenu_HandleInput+3C   j
                movem.l d0-d1,-(sp)
                move.b  #$DB,d0
                jsr     (Sound_QueueRequest).l
                movem.l (sp)+,d0-d1
PasswordInput_StoreSelection:                           ; was: loc_A5A4
                                        ; PasswordMenu_HandleInput+2C   j
                move.w  d0,(PasswordCursorOffset).w
                move.w  d1,(PasswordCursorMoveFlag).w
                move.l  #Password_CharacterCursorSpriteMapping,(PrimaryEntityMapping).w
                cmpi.w  #8,d0
                beq.w   PasswordInput_HandleConfirmField
                lea     PasswordText_InputPrompt(pc),a0
                nop
                bsr.w   PasswordText_CopyToPrimaryBuffer
                bsr.w   PasswordText_CopyToSecondaryBuffer
                move.b  (ControllerHeldState).w,d0
                andi.b  #$F,d0
                cmp.b   (PasswordHeldNibble).w,d0
                bne.s   PasswordInput_ResetRepeatDelay
                subq.w  #1,(PasswordRepeatTimer).w
                bra.s   PasswordInput_SelectRepeatSource
; ---------------------------------------------------------------------------
PasswordInput_ResetRepeatDelay:                         ; was: loc_A5DE
                move.b  d0,(PasswordHeldNibble).w
                move.w  #$18,(PasswordRepeatTimer).w
PasswordInput_SelectRepeatSource:                       ; was: loc_A5E8
                moveq   #0,d0
                movea.w #(ControllerPressedState-M68K_RAM),a1
                tst.w   (PasswordRepeatTimer).w
                bpl.s   PasswordInput_CheckDecrease
                move.w  #$FFFF,(PasswordRepeatTimer).w
                movea.w #(ControllerHeldState-M68K_RAM),a1
                btst    #0,(VBlankFrameCounter+1).w
                beq.s   PasswordInput_ApplyDigitDelta
PasswordInput_CheckDecrease:                            ; was: loc_A606
                btst    #0,(a1)
                beq.s   PasswordInput_CheckIncrease
                moveq   #$FFFFFFFF,d0
                cmpa.w  #$F708,a1
                bne.s   PasswordInput_ApplyDigitDelta
                move.w  #$A,(PasswordCursorFlash).w
                bra.s   PasswordInput_ApplyDigitDelta
; ---------------------------------------------------------------------------
PasswordInput_CheckIncrease:                            ; was: loc_A61C
                btst    #1,(a1)
                beq.s   PasswordInput_ApplyDigitDelta
                moveq   #1,d0
                cmpa.w  #$F708,a1
                bne.s   PasswordInput_ApplyDigitDelta
                move.w  #$A,(PasswordCursorFlash).w
PasswordInput_ApplyDigitDelta:                          ; was: loc_A630
                                        ; PasswordMenu_HandleInput+C2   j
                move.w  (PasswordCursorOffset).w,d4
                movea.w #(SoundDisableFlags+1-M68K_RAM),a0
PasswordInput_SelectDigitAddress:                       ; was: loc_A638
                addq.w  #1,a0
                subq.w  #2,d4
                bpl.s   PasswordInput_SelectDigitAddress
                move.b  (a0),d1
                add.w   d0,d1
                move.b  d1,(a0)
                movea.w #(PasswordDigits-M68K_RAM),a0
                move.b  (a0),d0
                bne.s   PasswordInput_ClampFirstDigitMaximum
                moveq   #1,d0
PasswordInput_ClampFirstDigitMaximum:                   ; was: loc_A64E
                cmpi.b  #$A,d0
                bmi.s   PasswordInput_StoreFirstDigit
                moveq   #$A,d0
PasswordInput_StoreFirstDigit:                          ; was: loc_A656
                move.b  d0,(a0)+
                move.b  (a0),d1
                bne.s   PasswordInput_ClampSecondDigitMaximum
                moveq   #1,d1
PasswordInput_ClampSecondDigitMaximum:                  ; was: loc_A65E
                cmpi.b  #$A,d1
                bmi.s   PasswordInput_StoreSecondDigit
                moveq   #$A,d1
PasswordInput_StoreSecondDigit:                         ; was: loc_A666
                move.b  d1,(a0)+
                move.b  (a0),d2
                bne.s   PasswordInput_ClampThirdDigitMaximum
                moveq   #1,d2
PasswordInput_ClampThirdDigitMaximum:                   ; was: loc_A66E
                cmpi.b  #$A,d2
                bmi.s   PasswordInput_StoreThirdDigit
                moveq   #$A,d2
PasswordInput_StoreThirdDigit:                          ; was: loc_A676
                move.b  d2,(a0)+
                move.b  (a0),d3
                bne.s   PasswordInput_ClampFourthDigitMaximum
                moveq   #1,d3
PasswordInput_ClampFourthDigitMaximum:                  ; was: loc_A67E
                cmpi.b  #$A,d3
                bmi.s   PasswordInput_RenderDigits
                moveq   #$A,d3
PasswordInput_RenderDigits:                             ; was: loc_A686
                move.b  d3,(a0)+
                movea.w #(PasswordDigitTextBuffer-M68K_RAM),a0
                move.b  d0,(a0)+
                move.b  #0,(a0)+
                move.b  d1,(a0)+
                move.b  #0,(a0)+
                move.b  d2,(a0)+
                move.b  #0,(a0)+
                move.b  d3,(a0)+
                move.b  #0,(a0)+
                move.b  #$2E,(a0)+                      ; '.'
                move.b  #0,(a0)+
                move.b  #$1D,(a0)+
                move.b  #$F,(a0)+
                move.b  #$1E,(a0)+
                move.b  #$FF,(a0)+
                movea.w #(PasswordDigitTextBuffer-M68K_RAM),a0
                move.w  #$A300,d0
                move.w  #$451C,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; ---------------------------------------------------------------------------
PasswordCursor_AnimateToSelection:                      ; was: loc_A6CE
                movea.l #PasswordCursor_TargetXPositions,a0
                movea.w #(Entity_ObjectPool-M68K_RAM),a1
                move.w  (PasswordCursorOffset).w,d0
                clr.w   d2
                move.w  (a0,d0.w),d1
                sub.w   $10(a1),d1
                bmi.s   PasswordCursor_MoveLeftOrSnap
                cmpi.w  #4,d1
                bmi.s   PasswordCursor_SnapToTarget
                addq.w  #4,$10(a1)
                rts
; ---------------------------------------------------------------------------
PasswordCursor_MoveLeftOrSnap:                          ; was: loc_A6F4
                cmpi.w  #$FFFC,d1
                bmi.s   PasswordCursor_MoveLeftFourPixels
PasswordCursor_SnapToTarget:                            ; was: loc_A6FA
                move.w  (a0,d0.w),$10(a1)
                clr.w   (PasswordCursorMoveFlag).w
                rts
; ---------------------------------------------------------------------------
PasswordCursor_MoveLeftFourPixels:                      ; was: loc_A706
                subq.w  #4,$10(a1)
PasswordInput_Return:                                   ; was: locret_A70A
                rts
; ---------------------------------------------------------------------------
PasswordCursor_TargetXPositions:    dc.w    $F4, $104, $114, $124, $14C  ; was: word_A70C
; ---------------------------------------------------------------------------
PasswordInput_HandleConfirmField:                       ; was: loc_A716
                move.l  #Password_ConfirmCursorSpriteMapping,(PrimaryEntityMapping).w
                move.b  #$F,(PasswordHeldNibble).w
                move.w  #$18,(PasswordRepeatTimer).w
                tst.w   (PasswordCursorMoveFlag).w
                bne.s   PasswordInput_Return
                move.l  (PasswordDigits).w,d0
                moveq   #0,d4
                moveq   #1,d5
                lea     Password_StageCodeTable(pc),a0
                nop
PasswordValidation_CheckNextStage:                      ; was: loc_A73E
                addq.b  #1,d4
                cmpi.w  #$FFFF,(a0)
                beq.w   PasswordValidation_RenderError
                moveq   #0,d3
                cmp.l   (a0)+,d0
                beq.s   PasswordValidation_HandleMatch
                moveq   #2,d3
                cmp.l   (a0)+,d0
                beq.s   PasswordValidation_HandleMatch
                bne.s   PasswordValidation_CheckNextStage
PasswordValidation_HandleMatch:                         ; was: loc_A756
                                        ; PasswordMenu_HandleInput+202   j
                move.w  d3,(PasswordDifficulty).w
                move.w  d4,(PasswordStageNumber).w
                lea     PasswordText_EasyStage(pc),a0
                nop
                move.w  (PasswordDifficulty).w,d0
                beq.s   PasswordValidation_RenderMatch
                lea     PasswordText_HardStage(pc),a0
                nop
PasswordValidation_RenderMatch:                         ; was: loc_A770
                bsr.w   PasswordText_CopyToPrimaryBuffer
                lea     PasswordText_ConfirmPrompt(pc),a0
                nop
                bsr.w   PasswordText_CopyToSecondaryBuffer
                move.w  (PasswordStageNumber).w,d0
                lea     (Math_PackedBCDLookup).l,a0
                asl.w   #1,d0
                move.w  (a0,d0.w),d0
                move.b  d0,d1
                asr.b   #4,d1
                addq.w  #1,d0
                addq.w  #1,d1
                andi.w  #$F,d0
                andi.w  #$F,d1
                move.b  d0,(PasswordStageOnesGlyph).w
                move.b  d1,(PasswordStageTensGlyph).w
                btst    #5,(ControllerPressedState).w
                beq.s   PasswordInput_WaitForConfirm
                move.w  (PasswordStageNumber).w,d0
                subq.w  #1,d0
                asl.w   #1,d0
                move.w  d0,(StageTableIndex).w
                move.w  (PasswordDifficulty).w,(DifficultyMode).w
                move.b  #$AD,d0
                jsr     (Sound_QueueRequest).l
                move.w  #$70,(GameModeIndex).w          ; 'p'
                clr.w   (GameSubstateIndex).w
                jmp     Password_InitializeSelectedStage
; ---------------------------------------------------------------------------
PasswordInput_WaitForConfirm:                           ; was: locret_A7DA
                                        ; PasswordMenu_HandleInput+2A0   j
                rts
; ---------------------------------------------------------------------------
PasswordValidation_RenderError:                         ; was: loc_A7DC
                lea     PasswordText_Error(pc),a0
                nop
                bsr.w   PasswordText_CopyToPrimaryBuffer
                bsr.w   PasswordText_CopyToSecondaryBuffer
                btst    #5,(ControllerPressedState).w
                beq.s   PasswordInput_WaitForConfirm
                move.b  #$BB,d0
                jmp     (Sound_QueueRequest).l
; End of function PasswordMenu_HandleInput
; Copies the next terminated text record to the primary password row
PasswordText_CopyToPrimaryBuffer:                       ; was: sub_A7FC
                                        ; PasswordMenu_HandleInput:PasswordValidation_RenderMatch   p
                movea.w #(PasswordPrimaryBuffer-M68K_RAM),a1
                bra.s   PasswordText_ClearBuffer
; End of function PasswordText_CopyToPrimaryBuffer
; Copies the next terminated text record to the secondary password row
PasswordText_CopyToSecondaryBuffer:                     ; was: sub_A802
                                        ; PasswordMenu_HandleInput+22A   p
                movea.w #(PasswordSecondaryBuffer-M68K_RAM),a1
PasswordText_ClearBuffer:                               ; was: loc_A806
                movea.w a1,a2
                moveq   #0,d0
                moveq   #$17,d7
PasswordText_ClearNextByte:                             ; was: loc_A80C
                move.b  d0,(a2)+
                dbf     d7,PasswordText_ClearNextByte
                move.b  #$FF,(a2)
                moveq   #0,d0
                move.b  (a0)+,d0
                adda.w  d0,a1
; Copies one password-message character at a time until terminator $FF
PasswordText_CopyNextCharacter:                         ; was: loc_A81C
                move.b  (a0)+,d0
                cmpi.b  #$FF,d0
                beq.s   PasswordText_CopyComplete
                move.b  d0,(a1)+
                bra.s   PasswordText_CopyNextCharacter
; ---------------------------------------------------------------------------
PasswordText_CopyComplete:                              ; was: locret_A828
                rts
; End of function PasswordText_CopyToSecondaryBuffer
; ---------------------------------------------------------------------------
Password_StageCodeTable:    dc.w    $20A, $906, $20A, $906, $407, $A09, $407, $A09, $103, $608  ; was: word_A82A
                                        ; Continue_RenderPassword+1A   o
                dc.w    $103, $608, $408, $506, $408, $506, $806, $602, $806, $602
                dc.w    $908, $A01, $908, $A01, $602, $A07, $602, $A07, $506, $70A
                dc.w    $506, $70A, $901, $A02, $901, $A02, $904, $207, $904, $207
                dc.w    $705, $103, $705, $103, $A09, $805, $A09, $805, $20A, $401
                dc.w    $20A, $401, $307, $304, $307, $304, $704, $906, $704, $906
                dc.w    $808, $50A, $808, $50A, $403, $809, $403, $809, $201, $40A
                dc.w    $201, $40A, $A01, $103, $A01, $103, $309, $809, $309, $809
                dc.w    $409, $A05, $409, $A05, $50A, $204, $50A, $204, $309, $603
                dc.w    $309, $603, $805, $107, $805, $107, $603, $90A, $603, $90A
                dc.w    $FFFF, $FFFF
PasswordText_InputPrompt:   dc.b    3, $13, $18, $1A, $1F, $1E, 0, $1A, $B  ; was: byte_A8F6
                dc.b    $1D, $1D, $21, $19, $1C, $E, $FF, 3, 0
                dc.b    $FF
PasswordText_Error: dc.b    3, $1A, $B, $1D, $1D, $21, $19, $1C, $E  ; was: byte_A909
                dc.b    0, $F, $1C, $1C, $19, $1C, $FF, 0, 0
                dc.b    $FF
PasswordText_EasyStage: dc.b    0, $1D, $1E, $B, $11, $F, $2E, 0, 0  ; was: byte_A91C
                dc.b    0, 0, $16, $F, $20, $F, $16, $2E, $F
                dc.b    $B, $1D, $23, $FF
PasswordText_ConfirmPrompt: dc.b    3, $1A, $1C, $F, $1D, $1D, 0, $D, 0, $C  ; was: byte_A932
                dc.b    $1F, $1E, $1E, $19, $18, $FF
PasswordText_NormalStage:   dc.b    0, $1D, $1E, $B     ; was: unlabeled_A942
                dc.b    $11, $F, $2E, 0, 0, 0, 0, $16, $F, $20
                dc.b    $F, $16, $2E, $18, $19, $1C, $17, $B, $16, $FF
PasswordText_HardStage: dc.b    0, $1D, $1E, $B, $11, $F, $2E, 0, 0  ; was: byte_A95A
                dc.b    0, 0, $16, $F, $20, $F, $16, $2E, $12
                dc.b    $B, $1C, $E, $FF

; Player behavior state dispatcher
