; Queues a pending stage BGM request, then continues to stage loading
StageTransition_QueuePendingBGMAndLoadStage:            ; was: sub_1E254
                move.b  (PendingStageBGMRequest).w,d0
                beq.s   StageTransition_LoadStageAfterOptionalBGM
                jsr     (Sound_QueueBGMOrStop).l
StageTransition_LoadStageAfterOptionalBGM:              ; was: loc_1E260
                bra.w   StageTransition_LoadStage
; End of function StageTransition_QueuePendingBGMAndLoadStage

; Initializes the interstage route or resumes its message-screen setup
StageTransition_Initialize:                             ; was: sub_1E264
                tst.w   (GameSubstateIndex).w
                bne.s   StageTransition_ResumeSetup
                jsr     (Sys_InitGameMode).l
                jsr     (Sys_ClearEntityObjectPool).l
                bra.w   StageTransition_QueuePendingBGMAndLoadStage
; End of function StageTransition_Initialize
; Prepares the otherwise unreferenced interstage message graphics
UnreferencedStageTransition_PrepareGraphics:            ; was: sub_1E27A
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                move.w  #$6000,(FontTileDMAVRAMAddress).w
                move.w  #$F,(FontTileDMACounter).w
                move.w  #0,(FontTileDMASourceOffset).w
                lea     (StageEntryAssetLoadList).l,a0
                jmp     (Data_ProcessPointer).l
; End of function UnreferencedStageTransition_PrepareGraphics
; Resumes pending font transfer and activates the interstage message screen
StageTransition_ResumeSetup:                            ; was: sub_1E2A6
                cmpi.w  #4,(GameSubstateIndex).w
                beq.s   StageTransition_ResumeSetup_ActivateMessageScreen
                tst.b   (DataLoaderControl).w
                bmi.w   StageTransition_LoadOrSetupReturn
                jsr     (Gfx_QueueNextFontTileDMA).l
                bpl.w   StageTransition_LoadOrSetupReturn
                addq.w  #2,(GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
StageTransition_ResumeSetup_ActivateMessageScreen:      ; was: loc_1E2C6
                move.w  #$38,(GameModeIndex).w          ; '8'
                clr.w   (GameSubstateIndex).w
                move.b  (PendingStageBGMRequest).w,d0
                beq.s   StageTransition_ResumeSetup_LoadPaletteAndText
                jsr     (Sound_QueueBGMOrStop).l
StageTransition_ResumeSetup_LoadPaletteAndText:         ; was: loc_1E2DC
                lea     StageTransitionPaletteBlockPointers(pc),a0
                nop
                jsr     (Palette_LoadFourOptionalBlocks).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                move.b  #0,(VDPReg18Shadow+1).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                bsr.w   StageTransition_RenderPressStart
                clr.w   (PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (SecondaryCameraYPos).w
                clr.w   (SecondaryCameraXPos).w
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function StageTransition_ResumeSetup
; ---------------------------------------------------------------------------
StageTransitionPaletteBlockPointers:    dc.l    StageTransitionPaletteBlock  ; was: off_1E334
                dc.l    StageTransitionPaletteBlock
                dc.l    StageTransitionPaletteBlock
                dc.l    StageTransitionPaletteBlock
StageTransitionPaletteBlock:    dc.l    0, $CAA0A88, $8660644, 0  ; was: dword_1E344
                                        ; ROM:0001E338   o
                dc.l    0, $8660644, $4220000, 0

; Advances interstage message text, confirmation, and palette fades
StageTransition_UpdateMessageScreen:                    ; was: sub_1E364
                tst.b   (DataLoaderControl).w
                bmi.w   StageTransition_UpdateMessageScreen_Return
                tst.w   (GameSubstateIndex).w
                beq.s   StageTransition_UpdateMessageScreen_RenderText
                btst    #7,(ControllerPressedState).w
                beq.s   StageTransition_UpdateMessageScreen_RenderText
                clr.w   (GameSubstateIndex).w
                move.w  #2,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
StageTransition_UpdateMessageScreen_RenderText:         ; was: loc_1E38E
                                        ; StageTransition_UpdateMessageScreen+14   j
                move.l  (StageMessageCursor).w,d0
                beq.s   StageTransition_UpdateMessageScreen_UpdateFade
                movea.l d0,a0
                moveq   #0,d4
                move.b  (a0)+,d4
                asl.w   #7,d4
                addi.w  #$400C,d4
                move.w  #$C300,d0
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                asr.w   #1,d3
                addq.w  #2,d3
                ext.l   d3
                add.l   d3,(StageMessageCursor).w
                movea.l (StageMessageCursor).w,a0
                cmpi.b  #$FD,(a0)
                bne.s   StageTransition_UpdateMessageScreen_UpdateFade
                clr.l   (StageMessageCursor).w
StageTransition_UpdateMessageScreen_UpdateFade:         ; was: loc_1E3C2
                                        ; StageTransition_UpdateMessageScreen+58   j
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   StageTransition_UpdateMessageScreen_FinishFadeOut
                addq.w  #2,(GameSubstateIndex).w
StageTransition_UpdateMessageScreen_Return:             ; was: locret_1E3D4
                                        ; StageTransition_UpdateMessageScreen+78   j
                rts
; ---------------------------------------------------------------------------
StageTransition_UpdateMessageScreen_FinishFadeOut:      ; was: loc_1E3D6
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   StageTransition_UpdateMessageScreen_Return
; Commits the interstage transition and starts loading the selected stage
StageTransition_LoadStage:                              ; was: loc_1E3DE
                                        ; EndingSequence_UpdateFromTransition+32   j
                move.w  #$C,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                jsr     (Weapon_CommitStateTransition).l
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                move.w  (StageTableIndex).w,d0
                asr.b   #1,d0
                move.b  StageIntroSoundRequestByStage(pc,d0.w),(StageIntroSoundRequest).w
                clr.b   (StageTimerPauseFlag).w
                jsr     (Stage_LoadAssetsForCurrentTableIndex).l
StageTransition_LoadOrSetupReturn:                      ; was: locret_1E40A
                                        ; StageTransition_ResumeSetup+16   j
                rts
; End of function StageTransition_UpdateMessageScreen
; Per-stage SFX request consumed when the STAGE-number banner reaches its cue
StageIntroSoundRequestByStage:  dc.b    $18, 0, 0       ; was: byte_1E40C
                dc.b    0, $18, 0
                dc.b    0, $18, 0
                dc.b    $18, 0, 0
                dc.b    0, $18, 0
                dc.b    0, 0, $18
                dc.b    0, 0, 0
                dc.b    0, 0, 0
                dc.b    0, 0, 0
                dc.b    0, 0, 0
                dc.b    0, 0, 0
                dc.b    0, 0, 0

; Renders the static PRESS START prompt
StageTransition_RenderPressStart:                       ; was: sub_1E430
                lea     (Text_PressStart).l,a0
                move.w  #$C100,d0
                move.w  #$4B9E,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function StageTransition_RenderPressStart
; ---------------------------------------------------------------------------
StageTransitionMessageSequence_StageZero:   dc.b    3, $DA, 0, $58, $79, $42, $36, $3F, $34, $43, $39, 0, $3E, $3B, $42, $D8  ; was: byte_1E444
                dc.b    $D8, $D8, 0, $DA, $FF, 6, $31, $4E, $D8, $30, $31, $3C, $6F, $36, 0, $9E  ; text?
                dc.b    $84, $AB, $3D, $31, $63, $5C, $3F, $40, $5D, $30, $6E, $44, $31, $DB, $DB, $FF
                dc.b    8, $61, $37, $30, $37, $4A, $6B, $32, $48, $91, $A6, $A3, $8B, $92, $AE, $A4
                dc.b    $DA, $C2, $D8, $FF, $A, $DE, $7F, $94, $9D, $A4, $AD, $C5, $AB, $AE, $DF, $48
                dc.b    0, $67, $31, $3B, $5C, $54, $76, $37, $45, $FF, $C, $36, $78, $32, $4B, $43
                dc.b    $35, $44, $3B, $4F, $5D, 0, $39, $67, $4E, $3C, $55, $D8, $D8, $D8, $FF, $F
                dc.b    $36, $76, $41, $53, $48, $3E, $5C, $62, $31, $E2, 0, $59, $55, $3B, $42, $49
                dc.b    $34, $38, $44, $31, $DB, $DB, $FF, $11, $3A, $30, $82, $80, $A3, $7F, $AB, $8D
                dc.b    $A4, $B2, $C5, $DA, $DB, $DB, 0, $30, $6C, $56, $42, $39, $31, $DB, $DB, $FF
                dc.b    $FD
StageTransitionMessageSequence_Shared:  dc.b    3, $DA, 0, $3B, $48, $6D, $5A, $55, $6D, $78, $32, $4E, 0, $58, $5D, $42  ; was: byte_1E4E5
                                        ; Stage9_UpdatePostXiTigerTransition+16   o
                dc.b    $D8, $D8, $D8, 0, $DA, $FF, 6, $3F, $3F, $35, $31, $49, $D8, $9E, $84, $AB
                dc.b    $39, $37, $3A, $31, $37, $32, $39, $32, $4C, $43, $FF, 8, $3E, $48, $BD, $8E
                dc.b    $80, $E2, 0, $32, $41, $3C, $D9, $FF, $A, $82, $80, $A3, $7F, $AB, $8D, $A4
                dc.b    $B2, $C5, $DA, $5D, $D8, $40, $35, $64, $31, $42, $31, $55, $3F, $51, $FF, $C
                dc.b    $42, $36, $48, 0, $3F, $31, $3B, $78, $32, $DE, $AA, $AB, $B6, $BB, $DF, $5D
                dc.b    $D8, $4A, $39, $32, $36, $6A, $FF, $E, $B3, $A2, $35, $57, $32, $79, $42, 0
                dc.b    $98, $A2, $53, $3B, $31, $D9, $FF, $11, $DE, $A7, $A6, $81, $D8, $3E, $32, $49
                dc.b    $31, $35, $47, $33, $DB, $DB, $DF, $FF, $13, $3E, $48, $43, $36, $D8, $84, $A5
                dc.b    $48, $3D, $44, $35, $45, 0, $94, $BD, $31, $80, $8E, $9E, $5D, $D8, $D8, $D8
                dc.b    $FF, $FD
StageTransitionMessageSequence_TrainAndBugmax:  binclude "data/other/stage_transition_message_sequence_train_and_bugmax.bin"  ; was: byte_1E587
StageTransitionMessageSequence_TrainAndBugmax_End:      ; was: byte_1E587_End
StageTransitionMessageSequence_PostFlyingNeo:   dc.b    3, $DA, 0, $39, $32, $6B, $31, $40, $4E, $5C, $A0, $DA, $92, $A4, $48, 0  ; was: byte_1E6C6
                dc.b    $A7, $BF, $81, 0, $DA, $FF, 6, $3A, $7A, $D8, $48, $39, $55, $49, 0, $7F
                dc.b    $94, $9D, $A4, $AD, $C5, $AB, $AE, $48, $BA, $AB, $D8, $FF, 8, $AA, $AB, $B6
                dc.b    $BB, $E2, 0, $3F, $34, $3C, $67, $38, $DB, $DB, $FF, $B, $63, $6B, $32, $3E
                dc.b    $32, $63, $77, $32, $48, 0, $4A, $39, $32, $36, $48, 0, $32, $33, $49, $FF
                dc.b    $D, $3A, $50, $31, $5D, $D8, $AA, $AB, $B6, $BB, $43, $82, $80, $A3, $7F, $AB
                dc.b    $8D, $A4, $B2, $C5, $DA, $48, $FF, $F, $45, $53, $4F, $30, $31, $49, 0, $47
                dc.b    $79, $36, $9F, $AB, $9F, $AB, $67, $DB, $DB, $FF, $12, $3B, $35, $3B, $D8, $3E
                dc.b    $48, $32, $3B, $57, $35, $53, 0, $63, $76, $30, $37, $6A, $36, $78, $67, $31
                dc.b    $44, $FF, $14, $84, $AF, $5D, $D8, $40, $35, $64, $36, $41, $41, $30, $79, $3F
                dc.b    $D8, $D8, $D8, $FF, $FD, $FF
