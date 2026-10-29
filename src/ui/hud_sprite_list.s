; Builds the shared HUD sprite list and optional diagnostic markers
UI_BuildHUDSpriteList:                                  ; was: sub_13278
                                        ; sub_1E8F6   p
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                movea.w #(SharedSpriteScratch-M68K_RAM),a1
UI_AppendHUDSpriteList:                                 ; was: loc_13280
                tst.b   (GameplayControlFlags).w
                bpl.w   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                btst    #0,(GameplayControlFlags).w
                beq.w   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                btst    #4,(ControllerHeldState).w
                bne.w   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                tst.w   (DifficultyMode).w
                bne.s   UI_AppendHUDSpriteList_SelectDiagnosticPhase
                btst    #2,(ControllerPressedState).w
                beq.s   UI_AppendHUDSpriteList_CheckFrameSkipIncrease
                subq.w  #1,(FrameSkipLevel).w
                bpl.s   UI_AppendHUDSpriteList_SelectDiagnosticPhase
                clr.w   (FrameSkipLevel).w
UI_AppendHUDSpriteList_CheckFrameSkipIncrease:          ; was: loc_132B4
                btst    #3,(ControllerPressedState).w
                beq.s   UI_AppendHUDSpriteList_SelectDiagnosticPhase
                addq.w  #1,(FrameSkipLevel).w
                cmpi.w  #4,(FrameSkipLevel).w
                bmi.s   UI_AppendHUDSpriteList_SelectDiagnosticPhase
                move.w  #3,(FrameSkipLevel).w
; Alternates the fixed diagnostic pair with the frame-skip-level markers
UI_AppendHUDSpriteList_SelectDiagnosticPhase:           ; was: loc_132CE
                                        ; UI_BuildHUDSpriteList+36   j
                btst    #1,(VBlankFrameCounter+1).w
                bne.w   UI_AppendHUDSpriteList_AppendFrameSkipLevelMarkers
                move.w  #$A2,(a1)+
                move.w  #$C00,(a1)+
                move.w  #$C7F9,(a1)+
                move.w  #$194,(a1)+
                move.w  #$A2,(a1)+
                move.w  #0,(a1)+
                move.w  #$C7FD,(a1)+
                move.w  #$1B4,(a1)+
                bra.s   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
; ---------------------------------------------------------------------------
UI_AppendHUDSpriteList_AppendFrameSkipLevelMarkers:     ; was: loc_132FA
                tst.w   (DifficultyMode).w
                bne.s   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                move.w  #$150,d0
                move.w  d0,(a1)+
                move.w  #$C00,(a1)+
                move.w  #$C7D8,(a1)+
                move.w  #$10C,(a1)+
                move.w  (FrameSkipLevel).w,d1
                andi.w  #3,d1
                subq.w  #1,d1
                bmi.s   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                move.w  d0,(a1)+
                move.w  #0,(a1)+
                move.w  #$C7DB,(a1)+
                move.w  #$12C,(a1)+
                subq.w  #1,d1
                bmi.s   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                move.w  d0,(a1)+
                move.w  #0,(a1)+
                move.w  #$C7DB,(a1)+
                move.w  #$134,(a1)+
                subq.w  #1,d1
                bmi.s   UI_AppendHUDSpriteList_AppendWeaponSlotIndicator
                move.w  d0,(a1)+
                move.w  #0,(a1)+
                move.w  #$C7DB,(a1)+
                move.w  #$13C,(a1)+
; Appends the active weapon-slot indicator, blinking it off-screen when hidden
UI_AppendHUDSpriteList_AppendWeaponSlotIndicator:       ; was: loc_13350
                                        ; UI_BuildHUDSpriteList+16   j
                move.w  #$80,(a1)+
                move.w  #$B00,(a1)+
                move.w  #$C6F0,(a1)+
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   UI_AppendHUDSpriteList_UseHiddenWeaponIndicatorX
                tst.b   (MessageDisplayFlags).w
                beq.s   UI_AppendHUDSpriteList_UseSelectedWeaponIndicatorX
UI_AppendHUDSpriteList_UseHiddenWeaponIndicatorX:       ; was: loc_1336A
                move.w  #1,(a1)+
                bra.s   UI_AppendHUDSpriteList_AppendCallerTileAtLeftEdge
; ---------------------------------------------------------------------------
UI_AppendHUDSpriteList_UseSelectedWeaponIndicatorX:     ; was: loc_13370
                lea     UI_WeaponIndicatorXTable(pc),a2
                nop
                move.w  (WeaponSlotOffset).w,d1
                move.w  (a2,d1.w),(a1)+
; Preserves the incoming D0 tile word in a left-edge sprite entry
UI_AppendHUDSpriteList_AppendCallerTileAtLeftEdge:      ; was: loc_1337E
                move.w  #$80,(a1)+
                move.w  #$300,(a1)+
                move.w  d0,(a1)+
                clr.w   (a1)+
                move.w  (HUDDynamicStripTileAttr).w,d2
                beq.s   UI_SubmitHUDSpriteList
                tst.w   (HUDDynamicStripXOffset).w
                bpl.s   UI_AppendHUDSpriteList_AppendDynamicStrip
                clr.w   (HUDDynamicStripTileAttr).w
                clr.w   (HUDDynamicStripXOffset).w
                bra.s   UI_SubmitHUDSpriteList
; ---------------------------------------------------------------------------
; Appends six vertically spaced sprites at X=$60 plus the signed strip offset
UI_AppendHUDSpriteList_AppendDynamicStrip:              ; was: loc_133A0
                move.w  #$A0,d0
                move.w  #$700,d1
                move.w  #$60,d3                         ; '`'
                add.w   (HUDDynamicStripXOffset).w,d3
                moveq   #5,d7
UI_AppendHUDSpriteList_DynamicStripLoop:                ; was: loc_133B2
                move.w  d0,(a1)+
                move.w  d1,(a1)+
                move.w  d2,(a1)+
                move.w  d3,(a1)+
                addi.w  #$20,d0                         ; ' '
                dbf     d7,UI_AppendHUDSpriteList_DynamicStripLoop
; Terminates and submits the HUD sprite list
UI_SubmitHUDSpriteList:                                 ; was: loc_133C2
                                        ; UI_BuildHUDSpriteList+126   j
                move.w  #$FFFF,(a1)
                jmp     (Sprite_AppendOAMEntries).l
; End of function UI_BuildHUDSpriteList
; ---------------------------------------------------------------------------
UI_WeaponIndicatorXTable:   dc.w    $160, $178, $190, $1A8  ; was: word_133CC
