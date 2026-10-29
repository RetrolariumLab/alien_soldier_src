; Expands a three-digit packed-BCD value into two tile rows and queues both DMAs
Options_QueueThreeDigitBCD:                             ; CODE XREF: UI_UpdateSFXTest+AC   j  ; was: sub_9F8E
                movea.w (VDPStagingDataCursor).w,a0
                move.b  d1,d2
                move.w  d1,d3
                asr.b   #4,d1
                asr.w   #8,d3
                andi.w  #$F,d1
                andi.w  #$F,d2
                andi.w  #1,d3
                asl.w   #1,d1
                asl.w   #1,d2
                asl.w   #1,d3
                addi.w  #-$5CFE,d1
                addi.w  #-$5CFE,d2
                addi.w  #-$5CFE,d3
                move.w  d3,(a0)+
                move.w  d1,(a0)+
                move.w  d2,(a0)+
                addq.w  #1,d1
                addq.w  #1,d2
                addq.w  #1,d3
                move.w  d3,(a0)+
                move.w  d1,(a0)+
                move.w  d2,(a0)+
                moveq   #3,d3
                bsr.w   Options_QueueStagedTileDMA
                addi.w  #$80,d0
                moveq   #3,d3
                bra.w   Options_QueueStagedTileDMA
; End of function Options_QueueThreeDigitBCD
; Expands a two-digit packed-BCD value into two tile rows and queues both DMAs
Options_QueueTwoDigitBCD:                               ; CODE XREF: UI_UpdateVoiceTest+88   j  ; was: sub_9FDA
                movea.w (VDPStagingDataCursor).w,a0
                move.b  d1,d2
                asr.b   #4,d1
                andi.w  #$F,d1
                andi.w  #$F,d2
                asl.w   #1,d1
                asl.w   #1,d2
                addi.w  #-$5CFE,d1
                addi.w  #-$5CFE,d2
                move.w  d1,(a0)+
                move.w  d2,(a0)+
                addq.w  #1,d1
                addq.w  #1,d2
                move.w  d1,(a0)+
                move.w  d2,(a0)+
                moveq   #2,d3
                bsr.w   Options_QueueStagedTileDMA
                addi.w  #$80,d0
                moveq   #2,d3
; End of function Options_QueueTwoDigitBCD
; Prepends one options-tile DMA command and advances the staging cursor
Options_QueueStagedTileDMA:                             ; CODE XREF: UI_UpdateBGMTest+86   p  ; was: sub_A00E
                                        ; UI_UpdateBGMTest+90   j
                movea.w (VDPCommandQueueHead).w,a1
                move.w  #$83,-(a1)
                move.w  d0,-(a1)
                move.b  (VDPStagingDataCursor).w,d1
                move.b  (VDPStagingDataCursor+1).w,d2
                asr.b   #1,d1
                roxr.b  #1,d2
                move.b  d2,-(a1)
                move.b  #$95,-(a1)
                move.b  d1,-(a1)
                move.b  #$96,-(a1)
                move.l  #$8F02977F,-(a1)
                move.l  #$94009300,-(a1)
                move.b  d3,3(a1)
                move.w  a1,(VDPCommandQueueHead).w
                asl.w   #1,d3
                add.w   d3,(VDPStagingDataCursor).w
                rts
; End of function Options_QueueStagedTileDMA
; Updates bit 2 of the selected option field, then queues both choice labels
Options_UpdateBit2Toggle:                               ; CODE XREF: UI_UpdateMessageOption+14   j  ; was: sub_A04C
                                        ; UI_UpdateSFXOption+14   j
                moveq   #2,d5
                bra.s   Options_ApplyToggleAndQueueLabels
; ---------------------------------------------------------------------------
Options_UpdateBit1Toggle:                               ; CODE XREF: UI_UpdateDifficultyOption+14   j  ; was: loc_A050
                                        ; UI_UpdateBGMOption+14   j
                moveq   #1,d5
Options_ApplyToggleAndQueueLabels:                      ; CODE XREF: Options_UpdateBit2Toggle+2   j  ; was: loc_A052
                btst    #2,(OptionsPressedCopy).w
                beq.s   Options_CheckToggleRight
                bclr    d5,1(a4)
                bra.s   Options_ResetToggleRepeatDelay
; ---------------------------------------------------------------------------
Options_CheckToggleRight:                               ; CODE XREF: Options_UpdateBit2Toggle+C   j  ; was: loc_A060
                btst    #3,(OptionsPressedCopy).w
                beq.s   Options_SelectToggleAttributes
                bset    d5,1(a4)
Options_ResetToggleRepeatDelay:                         ; CODE XREF: Options_UpdateBit2Toggle+12   j  ; was: loc_A06C
                move.w  #$A,(OptionsCursorFlashTimer).w
Options_SelectToggleAttributes:                         ; CODE XREF: Options_UpdateBit2Toggle+1A   j  ; was: loc_A072
                move.w  #$2000,d1
                move.w  #$4000,d2
                btst    d5,1(a4)
                beq.s   Options_BeginToggleLabelCopy
                move.w  #$2000,d2
                move.w  #$4000,d1
Options_BeginToggleLabelCopy:                           ; CODE XREF: Options_UpdateBit2Toggle+32   j  ; was: loc_A088
                movea.w (VDPStagingDataCursor).w,a0
                moveq   #0,d7
Options_CopyFirstToggleLabel:                           ; CODE XREF: Options_UpdateBit2Toggle+50   j  ; was: loc_A08E
                move.w  (a1)+,d0
                cmpi.w  #$FFFF,d0
                beq.s   Options_CopySecondToggleLabel
                add.w   d1,d0
                move.w  d0,(a0)+
                addq.w  #1,d7
                bra.s   Options_CopyFirstToggleLabel
; ---------------------------------------------------------------------------
Options_CopySecondToggleLabel:                          ; CODE XREF: Options_UpdateBit2Toggle+48   j  ; was: loc_A09E
                                        ; Options_UpdateBit2Toggle+60   j
                move.w  (a2)+,d0
                cmpi.w  #$FFFF,d0
                beq.s   Options_BeginToggleBottomRow
                add.w   d2,d0
                move.w  d0,(a0)+
                addq.w  #1,d7
                bra.s   Options_CopySecondToggleLabel
; ---------------------------------------------------------------------------
Options_BeginToggleBottomRow:                           ; CODE XREF: Options_UpdateBit2Toggle+58   j  ; was: loc_A0AE
                movea.w (VDPStagingDataCursor).w,a1
                move.w  d7,d3
Options_CopyToggleBottomRow:                            ; CODE XREF: Options_UpdateBit2Toggle+6E   j  ; was: loc_A0B4
                move.w  (a1)+,d0
                addq.w  #1,d0
                move.w  d0,(a0)+
                dbf     d3,Options_CopyToggleBottomRow
                move.w  d6,d0
                move.w  d7,d3
                bsr.w   Options_QueueStagedTileDMA
                addi.w  #$80,d6
                move.w  d6,d0
                move.w  d7,d3
                bra.w   Options_QueueStagedTileDMA
; End of function Options_UpdateBit2Toggle
; Moves the primary options cursor toward its selected row by two pixels
OptionsCursor_Animate:                                  ; CODE XREF: UI_HandleOptionsInput+A   j  ; was: sub_A0D2
                movea.l #Options_CursorYPositions,a0
                movea.w #(Entity_ObjectPool-M68K_RAM),a1
                move.w  (OptionsHandlerOffset).w,d0
                clr.w   d2
                move.w  (a0,d0.w),d1
                sub.w   $14(a1),d1
                bmi.s   OptionsCursor_CheckUpwardDelta
                cmpi.w  #2,d1
                bmi.s   OptionsCursor_SnapToTarget
                addq.w  #2,$14(a1)
                rts
; ---------------------------------------------------------------------------
OptionsCursor_CheckUpwardDelta:                         ; CODE XREF: OptionsCursor_Animate+18   j  ; was: loc_A0F8
                cmpi.w  #$FFFE,d1
                bmi.s   OptionsCursor_MoveUpTwoPixels
OptionsCursor_SnapToTarget:                             ; CODE XREF: OptionsCursor_Animate+1E   j  ; was: loc_A0FE
                move.w  (a0,d0.w),$14(a1)
                bclr    #0,(OptionsCursorMoving).w
                rts
; ---------------------------------------------------------------------------
; Decrements cursor Y position by 2 pixels for upward navigation
OptionsCursor_MoveUpTwoPixels:                          ; CODE XREF: OptionsCursor_Animate+2A   j  ; was: loc_A10C
                subq.w  #2,$14(a1)
                rts
; End of function OptionsCursor_Animate
; ---------------------------------------------------------------------------
Options_CursorYPositions:   dc.w    $B3, $D3, $E3, $FB, $10B, $11B  ; was: word_A112
                                        ; DATA XREF: OptionsCursor_Animate   o

; Moves the secondary options cursor toward its selected row by two pixels
SecondaryOptionsCursor_Animate:                         ; CODE XREF: UI_HandleSecondaryOptionsInput+A   j  ; was: sub_A11E
                lea     SecondaryOptions_CursorYPositions(pc),a0
                nop
                movea.w #(Entity_ObjectPool-M68K_RAM),a1
                move.w  (OptionsSelection).w,d0
                clr.w   d2
                move.w  (a0,d0.w),d1
                sub.w   $14(a1),d1
                bmi.s   SecondaryOptionsCursor_CheckUpwardDelta
                cmpi.w  #2,d1
                bmi.s   SecondaryOptionsCursor_SnapToTarget
                addq.w  #2,$14(a1)
                rts
; ---------------------------------------------------------------------------
SecondaryOptionsCursor_CheckUpwardDelta:                ; CODE XREF: SecondaryOptionsCursor_Animate+18   j  ; was: loc_A144
                cmpi.w  #$FFFE,d1
                bmi.s   SecondaryOptionsCursor_MoveUpTwoPixels
SecondaryOptionsCursor_SnapToTarget:                    ; CODE XREF: SecondaryOptionsCursor_Animate+1E   j  ; was: loc_A14A
                move.w  (a0,d0.w),$14(a1)
                bclr    #0,(OptionsCursorMoving).w
                rts
; ---------------------------------------------------------------------------
SecondaryOptionsCursor_MoveUpTwoPixels:                 ; CODE XREF: SecondaryOptionsCursor_Animate+2A   j  ; was: loc_A158
                subq.w  #2,$14(a1)
                rts
; End of function SecondaryOptionsCursor_Animate
; ---------------------------------------------------------------------------
SecondaryOptions_CursorYPositions:  dc.w    $CA, $DA, $EA, $FA, $10A  ; was: word_A15E
                                        ; DATA XREF: SecondaryOptionsCursor_Animate   o

; Advances the shared frontend cursor flash and writes its palette color
FrontendCursor_UpdateFlash:                             ; CODE XREF: UI_HandleOptionsInput   p  ; was: sub_A168
                                        ; sub_9EF6   p
                move.w  (OptionsCursorFlashTimer).w,d0
                beq.s   FrontendCursor_ApplyFlashColor
                subq.w  #2,d0
                move.w  d0,(OptionsCursorFlashTimer).w
FrontendCursor_ApplyFlashColor:                         ; CODE XREF: FrontendCursor_UpdateFlash+4   j  ; was: loc_A174
                andi.w  #$E,d0
                move.w  FrontendCursor_FlashColors(pc,d0.w),(PaletteActiveColor46).w
                rts
; End of function FrontendCursor_UpdateFlash
; ---------------------------------------------------------------------------
FrontendCursor_FlashColors: dc.w    $200, $400, $620, $840, $A60, $C82, $EA4, $EC6  ; was: word_A180

; Alternates two frontend palette colors from the VBlank frame counter
Frontend_AnimateMenuPalette:                            ; CODE XREF: TitleScreen_Update+110   p  ; was: sub_A190
                                        ; sub_9774:UI_UpdateOptionsScreenFrame   p
                move.w  (VBlankFrameCounter).w,d1
                asl.w   #1,d1
                andi.w  #2,d1
                move.w  Frontend_MenuPaletteCycleColors(pc,d1.w),d0
                move.w  d0,(PaletteActiveColor59).w
                addq.w  #4,d1
                move.w  Frontend_MenuPaletteCycleColors(pc,d1.w),d0
                move.w  d0,(PaletteActiveColor63).w
                rts
; End of function Frontend_AnimateMenuPalette
; ---------------------------------------------------------------------------
Frontend_MenuPaletteCycleColors:    dc.w    $E00, $E44, $4C4, $40  ; was: word_A1AE
Frontend_TitleAssetLoadDescriptors: dc.w    3           ; field_0  ; was: stru_A1B6
                                        ; DATA XREF: TitleScreen_Initialize+12   o
                                        ; Frontend_InitializeSegaScreen+1C   o
                dc.l    SharedTitleAndOptionsType3DataA  ; field_2
                dc.w    0                               ; field_6
                dc.w    3                               ; field_0
                dc.l    SharedTitleAndOptionsType3DataB  ; field_2
                dc.w    $2000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    FrontendTitleTileArt3000        ; field_2
                dc.w    $3000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    FrontendTitleMappingData6000    ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    FrontendTitleMappingData4000    ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingDataA  ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingDataB  ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    $FFFF
Options_AssetLoadDescriptors:   dc.w    3               ; field_0  ; was: stru_A1F8
                                        ; DATA XREF: UI_InitOptionsScreen+C   o
                                        ; UI_InitSecondaryOptionsMenu+C   o
                dc.l    SharedTitleAndOptionsType3DataA  ; field_2
                dc.w    $2000                           ; field_6
                dc.w    3                               ; field_0
                dc.l    SharedTitleAndOptionsType3DataB  ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingDataA  ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingDataB  ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
Options_OnLabelTiles:   dc.w    $8332, $8330, $8300, $8300, $FFFF  ; was: word_A220
                                        ; DATA XREF: UI_UpdateMessageOption   o
                                        ; sub_9DA0   o
Options_OffLabelTiles:  dc.w    $8332, $8320, $8320, $FFFF  ; was: word_A22A
                                        ; DATA XREF: UI_UpdateMessageOption+6   o
                                        ; UI_UpdateBGMOption+6   o
Options_SuperEasyLabelTiles:    dc.w    $833A, $833E, $8334, $831E, $8338, $831E, $8316, $833A, $8346, $8300, $FFFF  ; was: word_A232
                                        ; DATA XREF: UI_UpdateDifficultyOption   o
Options_SuperHardLabelTiles:    dc.w    $833A, $833E, $8334, $831E, $8338, $8324, $8316, $8338, $831C, $FFFF  ; was: word_A248
                                        ; DATA XREF: UI_UpdateDifficultyOption+6   o
; Two further terminated tile strings follow; the direct toggle reader stops above
                dc.w    $8330, $8332, $8338, $832E, $8316, $832C, $8300, $FFFF, $831C, $8326
                dc.w    $8338, $831E, $831A, $833C, $831E, $8338, $831A, $833E, $833C, $FFFF
; Normal voice-test navigation selects all 38 table bytes at indices 0..$25
Options_VoiceTestRequestIDs:    dc.w    $1011, $1213, $1415, $1617, $1819, $1A1B, $1C1D, $1E1F, $2023, $2425  ; was: word_A284
                                        ; DATA XREF: UI_UpdateVoiceTest+8   o
                dc.w    $2628, $2A2B, $2C2D, $2E2F, $3031, $3233, $3536, $3738, $393A
Options_SFXTestLowRequestIDs:   dc.b    $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F  ; was: byte_A2AA
                                        ; DATA XREF: UI_UpdateSFXTest+8   o
                dc.b    $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F
                dc.b    $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
                dc.b    $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E, $7F
; Normal SFX-test navigation selects combined-table indices 0..$98;
; the final $FB/$FC/$FF bytes lie beyond that menu bound
Options_SFXTestHighRequestIDs:  dc.b    $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF  ; was: byte_A2EA
                dc.b    $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF
                dc.b    $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF
                dc.b    $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
                dc.b    $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF
                dc.b    $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $FB, $FC, $FF

; Initializes the shared options/password cursor object from caller parameters
FrontendCursor_Initialize:                              ; CODE XREF: UI_InitOptionsScreen+176   p  ; was: sub_A346
                                        ; UI_InitSecondaryOptionsMenu+AA   p
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                move.w  #$F8,(a0)
                move.w  #$CC00,2(a0)
                move.w  #0,$E(a0)
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.l  d2,8(a0)
                rts
; End of function FrontendCursor_Initialize
; Type $F8 is the frontend cursor; its object update is intentionally a no-op
FrontendCursor_NoOpUpdate:                              ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: nullsub_5
                rts
; End of function FrontendCursor_NoOpUpdate
; ---------------------------------------------------------------------------
FrontendCursor_SpriteMappings:  dc.w    $4101, $E00, $F400  ; DATA XREF: UI_InitOptionsScreen+170   o  ; was: word_A36A
                                        ; UI_InitSecondaryOptionsMenu+A4   o
                dc.w    $4101, $E00, $F420
                dc.w    $4101, $E00, $F440
                dc.w    $4101, $E00, $F460
                dc.w    $4101, $E00, $F4E0
                dc.w    $4101, $E00, $F4C0
                dc.w    $C101, $E00, $F4A0
