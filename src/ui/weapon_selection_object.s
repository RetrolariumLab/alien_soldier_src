; Retires a committed weapon-selection object after freezing play and requesting SFX $1C
UI_WeaponSelectionCommitFeedback:                       ; was: sub_2BB70
                move.w  #$30,(FrameFreezeTimer).w       ; '0'
                bset    #4,2(a5)
                move.b  #$1C,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function UI_WeaponSelectionCommitFeedback
UI_InitWeaponSelectionObject:                           ; was: sub_2BB86
                addq.w  #2,4(a5)
                move.w  #$C700,2(a5)
                move.w  (GlobalSpritePriorityBit).w,$E(a5)
                move.b  #$C0,$21(a5)
                move.b  #$30,$23(a5)                    ; '0'
                move.l  #$F808F808,$2C(a5)
                move.l  #$FC04FC04,$28(a5)
                move.w  (FrameCounter).w,$48(a5)
                move.w  #$FFFF,$4C(a5)
                rts
; End of function UI_InitWeaponSelectionObject
; Updates weapon-selection animation, input, and selected-weapon state
UI_UpdateWeaponSelectionObject:                         ; was: sub_2BBC0
                move.b  #$7C,$20(a5)                    ; '|'
                btst    #0,(FrameCounter+1).w
                bne.s   UI_UpdateWeaponSelectionObject_UpdateAnimationHoldTimer
                clr.b   $20(a5)
UI_UpdateWeaponSelectionObject_UpdateAnimationHoldTimer:  ; was: loc_2BBD2
                tst.w   $4C(a5)
                bmi.s   UI_UpdateWeaponSelectionObject_AdvanceAnimationPhase
                subq.w  #1,$4C(a5)
                btst    #0,$4D(a5)
                bne.s   UI_UpdateWeaponSelectionObject_SelectAnimatedMapping
                btst    #7,$22(a5)
                beq.s   UI_UpdateWeaponSelectionObject_UseIdleMapping
                btst    #4,$22(a5)
                beq.s   UI_UpdateWeaponSelectionObject_SelectAnimatedMapping
UI_UpdateWeaponSelectionObject_UseIdleMapping:          ; was: loc_2BBF4
                move.l  #WeaponSelect_IdleSpriteMapping,8(a5)
                bra.s   UI_UpdateWeaponSelectionObject_RefreshPreviewFromActiveSlot
; ---------------------------------------------------------------------------
UI_UpdateWeaponSelectionObject_AdvanceAnimationPhase:   ; was: loc_2BBFE
                addq.w  #1,$48(a5)
UI_UpdateWeaponSelectionObject_SelectAnimatedMapping:   ; was: loc_2BC02
                                        ; UI_UpdateWeaponSelectionObject+32   j
                move.w  $48(a5),d1
                asr.w   #4,d1
                andi.w  #$1C,d1
                cmpi.w  #$18,d1
                bmi.s   UI_UpdateWeaponSelectionObject_LoadSelectedAnimatedMapping
                moveq   #0,d1
                move.w  d1,$48(a5)
UI_UpdateWeaponSelectionObject_LoadSelectedAnimatedMapping:  ; was: loc_2BC18
                lea     (WeaponSelect_SpriteFramePointers).l,a0
                move.l  (a0,d1.w),8(a5)
UI_UpdateWeaponSelectionObject_RefreshPreviewFromActiveSlot:  ; was: loc_2BC24
                bclr    #3,$22(a5)
                beq.s   UI_UpdateWeaponSelectionObject_HandleCommitFlag
                btst    #4,$22(a5)
                bne.w   UI_UpdateWeaponSelectionObject_HandleCommitFlag
                jsr     (Weapon_GetStateDisplayIndex).l
                beq.s   UI_UpdateWeaponSelectionObject_HandleCommitFlag
                movea.w (WeaponSlotOffset).w,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  (a0),d0
                asl.w   #5,d0
                move.w  d0,$48(a5)
                move.w  #$18,$4C(a5)
UI_UpdateWeaponSelectionObject_HandleCommitFlag:        ; was: loc_2BC54
                                        ; UI_UpdateWeaponSelectionObject+72   j
                bclr    #7,$22(a5)
                beq.w   UI_UpdateWeaponSelectionObject_ClearInteractionFlags
                bclr    #4,$22(a5)
                bne.w   UI_UpdateWeaponSelectionObject_ClearInteractionFlags
                move.b  #$A7,d0
                jsr     (Sound_QueueSFXRequest).l
                jsr     (Weapon_GetStateDisplayIndex).l
                beq.s   UI_UpdateWeaponSelectionObject_RetireWhenStateHasNoDisplay
                movea.w (WeaponSlotOffset).w,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  $48(a5),d1
                asr.w   #5,d1
                andi.w  #$E,d1
                cmpi.w  #$C,d1
                bmi.s   UI_UpdateWeaponSelectionObject_ApplyWeaponTypeOrIncreaseAmmoCapacity
                moveq   #0,d1
UI_UpdateWeaponSelectionObject_ApplyWeaponTypeOrIncreaseAmmoCapacity:  ; was: loc_2BC94
                cmp.w   (a0),d1
                beq.s   UI_UpdateWeaponSelectionObject_IncreaseSelectedAmmoCapacity
                move.w  d1,(a0)
                clr.w   8(a0)
                addq.w  #2,d1
                move.w  d1,(WeaponStateIndex).w
                asl.w   #1,d1
                move.w  d1,(WeaponIconTransferState).w
                jsr     (Weapon_ClearRuntimeParameters).l
                jsr     (Sys_ClearObjectBlocks16).l
                jsr     (UI_QueueSelectedWeaponIconTransfer).l
                bra.s   UI_UpdateWeaponSelectionObject_RefillSelectedAmmoAndCommit
; ---------------------------------------------------------------------------
UI_UpdateWeaponSelectionObject_IncreaseSelectedAmmoCapacity:  ; was: loc_2BCBE
                addi.w  #$FA,$18(a0)
                cmpi.w  #$7D0,$18(a0)
                bmi.s   UI_UpdateWeaponSelectionObject_RefillSelectedAmmoAndCommit
                move.w  #$7D0,$18(a0)
UI_UpdateWeaponSelectionObject_RefillSelectedAmmoAndCommit:  ; was: loc_2BCD2
                                        ; UI_UpdateWeaponSelectionObject+10A   j
                move.w  $18(a0),$10(a0)
                move.w  #$330,(a5)
                clr.b   $21(a5)
UI_UpdateWeaponSelectionObject_ClearInteractionFlags:   ; was: loc_2BCE0
                                        ; UI_UpdateWeaponSelectionObject+A4   j
                clr.b   $22(a5)
                rts
; ---------------------------------------------------------------------------
UI_UpdateWeaponSelectionObject_RetireWhenStateHasNoDisplay:  ; was: loc_2BCE6
                bset    #4,2(a5)
                rts
; End of function UI_UpdateWeaponSelectionObject
; Initializes the weapon-selection object on first update
UI_WeaponSelectionObject:                               ; was: sub_2BCEE
                tst.w   4(a5)
                bne.s   UI_WeaponSelectionObject_Update
                bsr.w   UI_InitWeaponSelectionObject
; Runs the weapon-selection object update
UI_WeaponSelectionObject_Update:                        ; was: loc_2BCF8
                bra.w   UI_UpdateWeaponSelectionObject
; End of function UI_WeaponSelectionObject
