UI_DebugSpriteEditor:                                   ; was: sub_2AA08
                btst    #7,(ControllerHeldState).w
                beq.w   UI_DebugSpriteEditor_Setup
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
UI_DebugSpriteEditor_Setup:                             ; was: loc_2AA1A
                move.w  #$8000,2(a5)
                move.w  #$120,$10(a5)
                move.w  #$100,$14(a5)
                move.w  $E(a5),d0
                btst    #6,(ControllerHeldState).w
                beq.w   UI_DebugSpriteEditor_CheckPressedTileControls
                btst    #0,(ControllerHeldState).w
                beq.w   UI_DebugSpriteEditor_DecrementTileHeld
                addq.w  #1,d0
                bra.w   UI_DebugSpriteEditor_ApplyTile
; ---------------------------------------------------------------------------
UI_DebugSpriteEditor_DecrementTileHeld:                 ; was: loc_2AA4A
                btst    #1,(ControllerHeldState).w
                beq.w   UI_DebugSpriteEditor_ApplyTile
                subq.w  #1,d0
                bra.w   UI_DebugSpriteEditor_ApplyTile
; ---------------------------------------------------------------------------
UI_DebugSpriteEditor_CheckPressedTileControls:          ; was: loc_2AA5A
                btst    #4,(ControllerHeldState).w
                bne.w   UI_DebugSpriteEditor_ApplyTile
                btst    #5,(ControllerHeldState).w
                bne.w   UI_DebugSpriteEditor_ApplyTile
                btst    #0,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_DecrementTilePressed
                addq.w  #1,d0
                bra.w   UI_DebugSpriteEditor_ApplyTile
; ---------------------------------------------------------------------------
UI_DebugSpriteEditor_DecrementTilePressed:              ; was: loc_2AA7E
                btst    #1,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_ApplyTile
                subq.w  #1,d0
UI_DebugSpriteEditor_ApplyTile:                         ; was: loc_2AA8A
                                        ; UI_DebugSpriteEditor+48   j
                andi.w  #$7FF,d0
                andi.w  #$9800,$E(a5)
                or.w    d0,$E(a5)
                btst    #4,(ControllerHeldState).w
                beq.w   UI_DebugSpriteEditor_CheckSizeControls
                btst    #0,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_ApplyPaletteLine
                addi.w  #$2000,$48(a5)
UI_DebugSpriteEditor_ApplyPaletteLine:                  ; was: loc_2AAB2
                andi.w  #$6000,$48(a5)
                move.w  $48(a5),d0
                or.w    d0,$E(a5)
                move.w  (GlobalSpritePriorityBit).w,d0
                or.w    d0,$E(a5)
                btst    #1,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_CheckHorizontalFlipToggle
                eori.w  #$1000,$E(a5)
UI_DebugSpriteEditor_CheckHorizontalFlipToggle:         ; was: loc_2AAD8
                btst    #3,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_CheckSizeControls
                eori.w  #$800,$E(a5)
UI_DebugSpriteEditor_CheckSizeControls:                 ; was: loc_2AAE8
                                        ; UI_DebugSpriteEditor+D6   j
                btst    #5,(ControllerHeldState).w
                beq.w   UI_DebugSpriteEditor_Return
                btst    #0,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_ApplySizeAndCheckOffsetX
                addi.w  #$100,8(a5)
UI_DebugSpriteEditor_ApplySizeAndCheckOffsetX:          ; was: loc_2AB02
                andi.w  #$F00,8(a5)
                btst    #1,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_CheckOffsetY
                move.w  $A(a5),d0
                andi.w  #$FF,$A(a5)
                addi.w  #$100,d0
                andi.w  #$FF00,d0
                or.w    d0,$A(a5)
UI_DebugSpriteEditor_CheckOffsetY:                      ; was: loc_2AB28
                btst    #3,(ControllerPressedState).w
                beq.w   UI_DebugSpriteEditor_Return
                move.w  $A(a5),d0
                andi.w  #$FF00,$A(a5)
                addi.w  #1,d0
                andi.w  #$FF,d0
                or.w    d0,$A(a5)
UI_DebugSpriteEditor_Return:                            ; was: locret_2AB48
                                        ; UI_DebugSpriteEditor+126   j
                rts
; End of function UI_DebugSpriteEditor
; Debug object that walks itself two pixels per frame against terrain collision
UI_DebugSpritePositionEditor:                           ; was: sub_2AB4A
                tst.w   4(a5)
                bne.w   UI_DebugSpritePositionEditor_Update
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$120,$10(a5)
                move.w  #$100,$14(a5)
UI_DebugSpritePositionEditor_Update:                    ; was: loc_2AB66
                ori.w   #$8000,2(a5)
                move.w  #$500,8(a5)
                move.w  #$F8F8,$A(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   UI_DebugSpritePositionEditor_UseAlternateTile
                move.w  #$C4AC,$E(a5)
                bra.s   UI_DebugSpritePositionEditor_CheckUp
; ---------------------------------------------------------------------------
UI_DebugSpritePositionEditor_UseAlternateTile:          ; was: loc_2AB88
                move.w  #$C4B4,$E(a5)
UI_DebugSpritePositionEditor_CheckUp:                   ; was: loc_2AB8E
                btst    #0,(ControllerHeldState).w
                beq.s   UI_DebugSpritePositionEditor_CheckDown
                moveq   #0,d0
                moveq   #$FFFFFFFC,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   UI_DebugSpritePositionEditor_CheckDown
                subq.w  #2,$14(a5)
UI_DebugSpritePositionEditor_CheckDown:                 ; was: loc_2ABA6
                                        ; UI_DebugSpritePositionEditor+56   j
                btst    #1,(ControllerHeldState).w
                beq.s   UI_DebugSpritePositionEditor_CheckLeft
                moveq   #0,d0
                moveq   #4,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   UI_DebugSpritePositionEditor_CheckLeft
                addq.w  #2,$14(a5)
UI_DebugSpritePositionEditor_CheckLeft:                 ; was: loc_2ABBE
                                        ; UI_DebugSpritePositionEditor+6E   j
                btst    #2,(ControllerHeldState).w
                beq.s   UI_DebugSpritePositionEditor_CheckRight
                moveq   #$FFFFFFFC,d0
                moveq   #0,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   UI_DebugSpritePositionEditor_CheckRight
                subq.w  #2,$10(a5)
UI_DebugSpritePositionEditor_CheckRight:                ; was: loc_2ABD6
                                        ; UI_DebugSpritePositionEditor+86   j
                btst    #3,(ControllerHeldState).w
                beq.s   UI_DebugSpritePositionEditor_Return
                moveq   #4,d0
                moveq   #0,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   UI_DebugSpritePositionEditor_Return
                addq.w  #2,$10(a5)
UI_DebugSpritePositionEditor_Return:                    ; was: locret_2ABEE
                                        ; UI_DebugSpritePositionEditor+9E   j
                rts
; End of function UI_DebugSpritePositionEditor
; ---------------------------------------------------------------------------
