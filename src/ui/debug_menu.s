DebugMenu_DispatchSelectedPageAction:                   ; was: sub_1372A
                                        ; DebugMenu_UpdateActive+78   p
                bsr.w   UI_QueuePendingWeaponStateIconTransfer
                move.w  (DebugMenuPageOffset).w,d0
                movea.w DebugMenuPageHandlerOffsets(pc,d0.w),a0
                adda.l  #DebugMenu_UpdateHealthSelection,a0
                jmp     (a0)
; End of function DebugMenu_DispatchSelectedPageAction
; ---------------------------------------------------------------------------
DebugMenuPageHandlerOffsets:    dc.w    DebugMenu_UpdateHealthSelection-DebugMenu_UpdateHealthSelection  ; was: off_1373E
                dc.w    DebugMenu_UpdateSoundRequestSelection-DebugMenu_UpdateHealthSelection
                dc.w    DebugMenu_UpdateBossHealthClear-DebugMenu_UpdateHealthSelection
                dc.w    DebugMenu_UpdatePaletteLineSelection-DebugMenu_UpdateHealthSelection
                dc.w    DebugMenu_UpdatePaletteColorSelection-DebugMenu_UpdateHealthSelection

DebugMenu_UpdateHealthSelection:                        ; was: sub_13748
                clr.w   (DebugColorEditActive).w
                btst    #3,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_UpdateHealthSelection_ReadInput
                move.w  #$C7E5,(DebugHealthCursorTile).w
DebugMenu_UpdateHealthSelection_ReadInput:              ; was: loc_1375A
                move.b  (DebugHealthSelection).w,d0
                moveq   #1,d1
                movea.w #(ControllerHeldState-M68K_RAM),a0
                tst.w   (DebugMenuRepeatTimer).w
                beq.s   DebugMenu_UpdateHealthSelection_CheckDecrease
                movea.w #(ControllerPressedState-M68K_RAM),a0
DebugMenu_UpdateHealthSelection_CheckDecrease:          ; was: loc_1376E
                btst    #2,(a0)
                beq.s   DebugMenu_UpdateHealthSelection_CheckIncrease
                cmpi.b  #0,d0
                beq.s   DebugMenu_UpdateHealthSelection_WrapBelowZero
                cmpi.b  #$FF,d0
                beq.s   DebugMenu_UpdateHealthSelection_Commit
                sub.w   d2,d2
                sbcd    d1,d0
                bra.s   DebugMenu_UpdateHealthSelection_Commit
; ---------------------------------------------------------------------------
DebugMenu_UpdateHealthSelection_WrapBelowZero:          ; was: loc_13786
                move.b  #$FF,d0
                bra.s   DebugMenu_UpdateHealthSelection_Commit
; ---------------------------------------------------------------------------
DebugMenu_UpdateHealthSelection_CheckIncrease:          ; was: loc_1378C
                btst    #3,(a0)
                beq.s   DebugMenu_UpdateHealthSelection_Commit
                cmpi.b  #$FF,d0
                bne.s   DebugMenu_UpdateHealthSelection_IncrementBCD
                moveq   #0,d0
                bra.s   DebugMenu_UpdateHealthSelection_Commit
; ---------------------------------------------------------------------------
DebugMenu_UpdateHealthSelection_IncrementBCD:           ; was: loc_1379C
                sub.w   d2,d2
                abcd    d1,d0
                move.w  #$400,d1
                asr.w   #4,d1
                cmp.b   d1,d0
                bmi.s   DebugMenu_UpdateHealthSelection_Commit
                move.b  d1,d0
DebugMenu_UpdateHealthSelection_Commit:                 ; was: loc_137AC
                clr.w   (DebugResourceRefill).w
                move.b  d0,(DebugHealthSelection).w
                cmpi.b  #$FF,d0
                bne.s   DebugMenu_UpdateHealthSelection_Return
                addq.w  #2,(DebugResourceRefill).w
DebugMenu_UpdateHealthSelection_Return:                 ; was: locret_137BE
                rts
; End of function DebugMenu_UpdateHealthSelection
DebugMenu_UpdateSoundRequestSelection:                  ; was: sub_137C0
                btst    #3,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_UpdateSoundRequestSelection_ReadInput
                move.w  #$C7E5,(DebugSoundCursorTile).w
DebugMenu_UpdateSoundRequestSelection_ReadInput:        ; was: loc_137CE
                move.b  (DebugSoundRequestId).w,d0
                movea.w #(ControllerHeldState-M68K_RAM),a0
                tst.w   (DebugMenuRepeatTimer).w
                beq.s   DebugMenu_UpdateSoundRequestSelection_CheckDecrease
                movea.w #(ControllerPressedState-M68K_RAM),a0
DebugMenu_UpdateSoundRequestSelection_CheckDecrease:    ; was: loc_137E0
                btst    #2,(a0)
                beq.s   DebugMenu_UpdateSoundRequestSelection_CheckIncrease
                subq.b  #1,d0
                move.b  d0,(DebugSoundRequestId).w
                rts
; ---------------------------------------------------------------------------
DebugMenu_UpdateSoundRequestSelection_CheckIncrease:    ; was: loc_137EE
                btst    #3,(a0)
                beq.s   DebugMenu_UpdateSoundRequestSelection_Return
                addq.w  #1,d0
                move.b  d0,(DebugSoundRequestId).w
DebugMenu_UpdateSoundRequestSelection_Return:           ; was: locret_137FA
                rts
; End of function DebugMenu_UpdateSoundRequestSelection
DebugMenu_UpdateBossHealthClear:                        ; was: sub_137FC
                btst    #4,(ControllerPressedState).w
                beq.s   DebugMenu_UpdateBossHealthClear_UpdateCursor
                clr.w   (BossHealth).w
DebugMenu_UpdateBossHealthClear_UpdateCursor:           ; was: loc_13808
                btst    #3,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_UpdateBossHealthClear_Return
                move.w  #$C7E5,(BossClearCursorTile).w
DebugMenu_UpdateBossHealthClear_Return:                 ; was: locret_13816
                rts
; End of function DebugMenu_UpdateBossHealthClear
DebugMenu_UpdatePaletteLineSelection:                   ; was: sub_13818
                btst    #3,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_UpdatePaletteLineSelection_ReadInput
                move.w  #$C7E5,(PaletteLineCursorTile).w
DebugMenu_UpdatePaletteLineSelection_ReadInput:         ; was: loc_13826
                move.b  (ControllerPressedState).w,d0
                andi.b  #$C,d0
                beq.s   DebugMenu_UpdatePaletteLineSelection_Return
                addq.w  #2,(DebugPaletteLineOffset).w
                andi.w  #6,(DebugPaletteLineOffset).w
DebugMenu_UpdatePaletteLineSelection_Return:            ; was: locret_1383A
                rts
; End of function DebugMenu_UpdatePaletteLineSelection
DebugMenu_UpdatePaletteColorSelection:                  ; was: sub_1383C
                btst    #3,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_UpdatePaletteColorSelection_SelectMode
                tst.w   (DebugColorEditActive).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_DrawEntryCursor
                move.w  #$C7E5,(ColorEditCursorTile).w
                bra.s   DebugMenu_UpdatePaletteColorSelection_SelectMode
; ---------------------------------------------------------------------------
DebugMenu_UpdatePaletteColorSelection_DrawEntryCursor:  ; was: loc_13852
                move.w  #$C7E5,(PaletteEntryCursorTile).w
DebugMenu_UpdatePaletteColorSelection_SelectMode:       ; was: loc_13858
                tst.w   (DebugColorEditActive).w
                beq.w   DebugMenu_UpdatePaletteColorSelection_SelectEntry
                bsr.w   DebugMenu_UpdateSelectedPaletteColor
                btst    #4,(ControllerPressedState).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_CheckPreviousChannel
                clr.w   (DebugColorEditActive).w
                rts
; ---------------------------------------------------------------------------
DebugMenu_UpdatePaletteColorSelection_CheckPreviousChannel:  ; was: loc_13872
                btst    #2,(ControllerPressedState).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_CheckNextChannel
                subq.w  #2,(DebugColorChannelOffset).w
                bpl.s   DebugMenu_UpdatePaletteColorSelection_Return
                move.w  #4,(DebugColorChannelOffset).w
                rts
; ---------------------------------------------------------------------------
DebugMenu_UpdatePaletteColorSelection_CheckNextChannel:  ; was: loc_13888
                btst    #3,(ControllerPressedState).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_Return
                addq.w  #2,(DebugColorChannelOffset).w
                cmpi.w  #6,(DebugColorChannelOffset).w
                bmi.s   DebugMenu_UpdatePaletteColorSelection_Return
                clr.w   (DebugColorChannelOffset).w
DebugMenu_UpdatePaletteColorSelection_Return:           ; was: locret_138A0
                rts
; ---------------------------------------------------------------------------
DebugMenu_UpdatePaletteColorSelection_SelectEntry:      ; was: loc_138A2
                btst    #4,(ControllerPressedState).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_CheckPreviousEntry
                addq.w  #1,(DebugColorEditActive).w
                clr.w   (DebugColorChannelOffset).w
                rts
; ---------------------------------------------------------------------------
DebugMenu_UpdatePaletteColorSelection_CheckPreviousEntry:  ; was: loc_138B4
                btst    #2,(ControllerPressedState).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_CheckNextEntry
                subq.w  #2,(DebugPaletteEntryOffset).w
                bra.s   DebugMenu_UpdatePaletteColorSelection_WrapEntry
; ---------------------------------------------------------------------------
DebugMenu_UpdatePaletteColorSelection_CheckNextEntry:   ; was: loc_138C2
                btst    #3,(ControllerPressedState).w
                beq.s   DebugMenu_UpdatePaletteColorSelection_WrapEntry
                addq.w  #2,(DebugPaletteEntryOffset).w
DebugMenu_UpdatePaletteColorSelection_WrapEntry:        ; was: loc_138CE
                andi.w  #$1E,(DebugPaletteEntryOffset).w
                rts
; End of function DebugMenu_UpdatePaletteColorSelection
DebugMenu_RenderPaletteEntryCursor:                     ; was: sub_138D6
                btst    #2,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_RenderPaletteEntryCursor_Return
                move.w  (DebugPaletteEntryOffset).w,d0
                addi.w  #-$7A6C,d0
                movea.w d0,a0
                move.w  #$D7E4,(a0)
DebugMenu_RenderPaletteEntryCursor_Return:              ; was: locret_138EC
                rts
; End of function DebugMenu_RenderPaletteEntryCursor
DebugMenu_RenderColorChannelCursor:                     ; was: sub_138EE
                tst.w   (DebugColorEditActive).w
                beq.s   DebugMenu_RenderColorChannelCursor_Return
                btst    #2,(VBlankFrameCounter+1).w
                bne.s   DebugMenu_RenderColorChannelCursor_Return
                move.w  (DebugColorChannelOffset).w,d0
                addi.w  #-$7AAA,d0
                movea.w d0,a0
                move.w  #$C7E4,(a0)
DebugMenu_RenderColorChannelCursor_Return:              ; was: locret_1390A
                rts
; End of function DebugMenu_RenderColorChannelCursor
DebugMenu_RenderHealthSelection:                        ; was: sub_1390C
                move.b  (DebugHealthSelection).w,d0
                cmpi.b  #$FF,d0
                bne.s   DebugMenu_RenderHealthSelectionDigits
                move.w  #$C7E2,(DebugHealthHighTile).w
                move.w  #$C7DE,(DebugHealthLowTile).w
                rts
; ---------------------------------------------------------------------------
DebugMenu_RenderHealthSelectionDigits:                  ; was: loc_13924
                move.b  d0,d1
                andi.w  #$F,d0
                addi.w  #-$383C,d0
                move.w  d0,(DebugHealthLowTile).w
                asr.w   #4,d1
                andi.w  #$F,d1
                addi.w  #-$383C,d1
                move.w  d1,(DebugHealthHighTile).w
                rts
; End of function DebugMenu_RenderHealthSelection
DebugMenu_RenderSoundRequestNumber:                     ; was: sub_13942
                move.b  (DebugSoundRequestId).w,d0
                move.b  d0,d1
                andi.w  #$F,d0
                addi.w  #-$383C,d0
                move.w  d0,(DebugSoundLowTile).w
                asr.w   #4,d1
                andi.w  #$F,d1
                addi.w  #-$383C,d1
                move.w  d1,(DebugSoundHighTile).w
                rts
; End of function DebugMenu_RenderSoundRequestNumber
DebugMenu_CopySelectedPalettePreviewTiles:              ; was: sub_13964
                moveq   #0,d0
                move.w  (DebugPaletteLineOffset).w,d0
                asl.w   #4,d0
                addi.l  #DebugMenuPalettePreviewTiles,d0
                movea.l d0,a0
                movea.w #(PalettePreviewBuffer-M68K_RAM),a1
                moveq   #$F,d7
DebugMenu_CopySelectedPalettePreviewTiles_NextWord:     ; was: loc_1397A
                move.w  (a0)+,(a1)+
                dbf     d7,DebugMenu_CopySelectedPalettePreviewTiles_NextWord
                rts
; End of function DebugMenu_CopySelectedPalettePreviewTiles
DebugMenu_RenderPaletteLineNumber:                      ; was: sub_13982
                move.w  (DebugPaletteLineOffset).w,d0
                asr.w   #1,d0
                addi.w  #-$383C,d0
                move.w  d0,(PaletteLineNumberTile).w
                rts
; End of function DebugMenu_RenderPaletteLineNumber
; ---------------------------------------------------------------------------
DebugMenuPalettePreviewTiles:   dc.w    $87B4, $87B5, $87B6, $87B7, $87B8, $87B9, $87BA, $87BB  ; was: word_13992
                dc.w    $87BC, $87BD, $87BE, $87BF, $87C0, $87C1, $87C2, $87C3
                dc.w    $A7B4, $A7B5, $A7B6, $A7B7, $A7B8, $A7B9, $A7BA, $A7BB
                dc.w    $A7BC, $A7BD, $A7BE, $A7BF, $A7C0, $A7C1, $A7C2, $A7C3
                dc.w    $C7B4, $C7B5, $C7B6, $C7B7, $C7B8, $C7B9, $C7BA, $C7BB
                dc.w    $C7BC, $C7BD, $C7BE, $C7BF, $C7C0, $C7C1, $C7C2, $C7C3
                dc.w    $E7B4, $E7B5, $E7B6, $E7B7, $E7B8, $E7B9, $E7BA, $E7BB
                dc.w    $E7BC, $E7BD, $E7BE, $E7BF, $E7C0, $E7C1, $E7C2, $E7C3

DebugMenu_RenderSelectedColorValue:                     ; was: sub_13A12
                move.w  (DebugPaletteLineOffset).w,d0
                asl.w   #4,d0
                add.w   (DebugPaletteEntryOffset).w,d0
                addi.w  #-$1C80,d0
                movea.w d0,a0
                move.w  (a0),d0
                move.w  d0,d1
                move.w  d1,d2
                andi.w  #$E00,d0
                asr.w   #8,d0
                addi.w  #-$383C,d0
                move.w  d0,(DebugColorRedTile).w
                andi.w  #$E0,d1
                asr.w   #4,d1
                addi.w  #-$383C,d1
                move.w  d1,(DebugColorGreenTile).w
                andi.w  #$E,d2
                addi.w  #-$383C,d2
                move.w  d2,(DebugColorBlueTile).w
                rts
; End of function DebugMenu_RenderSelectedColorValue
DebugMenu_UpdateSelectedPaletteColor:                   ; was: sub_13A52
                move.w  (DebugPaletteLineOffset).w,d0
                asl.w   #4,d0
                add.w   (DebugPaletteEntryOffset).w,d0
                addi.w  #-$1C80,d0
                movea.w d0,a0
                move.b  (ControllerPressedState).w,d1
                move.w  (a0),d0
                move.w  d0,d2
                move.w  (DebugColorChannelOffset).w,d3
                beq.s   DebugMenu_UpdateSelectedPaletteColor_UpdateRed
                cmpi.w  #2,d3
                beq.s   DebugMenu_UpdateSelectedPaletteColor_UpdateGreen
                andi.w  #$EE0,d0
                btst    #0,d1
                beq.s   DebugMenu_UpdateSelectedPaletteColor_CheckIncreaseBlue
                subi.w  #2,d2
                bra.s   DebugMenu_UpdateSelectedPaletteColor_MaskBlue
; ---------------------------------------------------------------------------
DebugMenu_UpdateSelectedPaletteColor_CheckIncreaseBlue:  ; was: loc_13A86
                btst    #1,d1
                beq.s   DebugMenu_UpdateSelectedPaletteColor_MaskBlue
                addi.w  #2,d2
DebugMenu_UpdateSelectedPaletteColor_MaskBlue:          ; was: loc_13A90
                andi.w  #$E,d2
                bra.s   DebugMenu_UpdateSelectedPaletteColor_Store
; ---------------------------------------------------------------------------
DebugMenu_UpdateSelectedPaletteColor_UpdateGreen:       ; was: loc_13A96
                andi.w  #$E0E,d0
                btst    #0,d1
                beq.s   DebugMenu_UpdateSelectedPaletteColor_CheckIncreaseGreen
                subi.w  #$20,d2                         ; ' '
                bra.s   DebugMenu_UpdateSelectedPaletteColor_MaskGreen
; ---------------------------------------------------------------------------
DebugMenu_UpdateSelectedPaletteColor_CheckIncreaseGreen:  ; was: loc_13AA6
                btst    #1,d1
                beq.s   DebugMenu_UpdateSelectedPaletteColor_MaskGreen
                addi.w  #$20,d2                         ; ' '
DebugMenu_UpdateSelectedPaletteColor_MaskGreen:         ; was: loc_13AB0
                andi.w  #$E0,d2
                bra.s   DebugMenu_UpdateSelectedPaletteColor_Store
; ---------------------------------------------------------------------------
DebugMenu_UpdateSelectedPaletteColor_UpdateRed:         ; was: loc_13AB6
                andi.w  #$EE,d0
                btst    #0,d1
                beq.s   DebugMenu_UpdateSelectedPaletteColor_CheckIncreaseRed
                subi.w  #$200,d2
                bra.s   DebugMenu_UpdateSelectedPaletteColor_MaskRed
; ---------------------------------------------------------------------------
DebugMenu_UpdateSelectedPaletteColor_CheckIncreaseRed:  ; was: loc_13AC6
                btst    #1,d1
                beq.s   DebugMenu_UpdateSelectedPaletteColor_MaskRed
                addi.w  #$200,d2
DebugMenu_UpdateSelectedPaletteColor_MaskRed:           ; was: loc_13AD0
                andi.w  #$E00,d2
DebugMenu_UpdateSelectedPaletteColor_Store:             ; was: loc_13AD4
                add.w   d2,d0
                move.w  d0,-$80(a0)
                move.w  d0,(a0)
                rts
; End of function DebugMenu_UpdateSelectedPaletteColor
; Updates all boss collision detection systems including terrain and projectiles
