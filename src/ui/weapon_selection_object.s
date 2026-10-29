; Retires a committed weapon-selection object after freezing play and requesting SFX $1C
Pickup_WeaponCapsuleCommitFeedback:                     ; was: sub_2BB70
                move.w  #$30,(FrameFreezeTimer).w       ; '0'
                bset    #4,2(a5)
                move.b  #$1C,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Pickup_WeaponCapsuleCommitFeedback
Pickup_InitWeaponCapsule:                               ; was: sub_2BB86
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
; End of function Pickup_InitWeaponCapsule
; Updates weapon-selection animation, input, and selected-weapon state
Pickup_UpdateWeaponCapsule:                             ; was: sub_2BBC0
                move.b  #$7C,$20(a5)                    ; '|'
                btst    #0,(FrameCounter+1).w
                bne.s   Pickup_UpdateWeaponCapsule_UpdateAnimationHoldTimer
                clr.b   $20(a5)
Pickup_UpdateWeaponCapsule_UpdateAnimationHoldTimer:    ; was: loc_2BBD2
                tst.w   $4C(a5)
                bmi.s   Pickup_UpdateWeaponCapsule_AdvanceAnimationPhase
                subq.w  #1,$4C(a5)
                btst    #0,$4D(a5)
                bne.s   Pickup_UpdateWeaponCapsule_SelectAnimatedMapping
                btst    #7,$22(a5)
                beq.s   Pickup_UpdateWeaponCapsule_UseIdleMapping
                btst    #4,$22(a5)
                beq.s   Pickup_UpdateWeaponCapsule_SelectAnimatedMapping
Pickup_UpdateWeaponCapsule_UseIdleMapping:              ; was: loc_2BBF4
                move.l  #Pickup_WeaponCapsuleIdleSpriteMapping,8(a5)
                bra.s   Pickup_UpdateWeaponCapsule_RefreshPreviewFromActiveSlot
; ---------------------------------------------------------------------------
Pickup_UpdateWeaponCapsule_AdvanceAnimationPhase:       ; was: loc_2BBFE
                addq.w  #1,$48(a5)
Pickup_UpdateWeaponCapsule_SelectAnimatedMapping:       ; was: loc_2BC02
                                        ; Pickup_UpdateWeaponCapsule+32   j
                move.w  $48(a5),d1
                asr.w   #4,d1
                andi.w  #$1C,d1
                cmpi.w  #$18,d1
                bmi.s   Pickup_UpdateWeaponCapsule_LoadSelectedAnimatedMapping
                moveq   #0,d1
                move.w  d1,$48(a5)
Pickup_UpdateWeaponCapsule_LoadSelectedAnimatedMapping:  ; was: loc_2BC18
                lea     (WeaponSelect_SpriteFramePointers).l,a0
                move.l  (a0,d1.w),8(a5)
Pickup_UpdateWeaponCapsule_RefreshPreviewFromActiveSlot:  ; was: loc_2BC24
                bclr    #3,$22(a5)
                beq.s   Pickup_UpdateWeaponCapsule_HandleCommitFlag
                btst    #4,$22(a5)
                bne.w   Pickup_UpdateWeaponCapsule_HandleCommitFlag
                jsr     (Weapon_GetStateDisplayIndex).l
                beq.s   Pickup_UpdateWeaponCapsule_HandleCommitFlag
                movea.w (WeaponSlotOffset).w,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  (a0),d0
                asl.w   #5,d0
                move.w  d0,$48(a5)
                move.w  #$18,$4C(a5)
Pickup_UpdateWeaponCapsule_HandleCommitFlag:            ; was: loc_2BC54
                                        ; Pickup_UpdateWeaponCapsule+72   j
                bclr    #7,$22(a5)
                beq.w   Pickup_UpdateWeaponCapsule_ClearInteractionFlags
                bclr    #4,$22(a5)
                bne.w   Pickup_UpdateWeaponCapsule_ClearInteractionFlags
                move.b  #$A7,d0
                jsr     (Sound_QueueSFXRequest).l
                jsr     (Weapon_GetStateDisplayIndex).l
                beq.s   Pickup_UpdateWeaponCapsule_RetireWhenStateHasNoDisplay
                movea.w (WeaponSlotOffset).w,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  $48(a5),d1
                asr.w   #5,d1
                andi.w  #$E,d1
                cmpi.w  #$C,d1
                bmi.s   Pickup_UpdateWeaponCapsule_ApplyWeaponTypeOrIncreaseAmmoCapacity
                moveq   #0,d1
Pickup_UpdateWeaponCapsule_ApplyWeaponTypeOrIncreaseAmmoCapacity:  ; was: loc_2BC94
                cmp.w   (a0),d1
                beq.s   Pickup_UpdateWeaponCapsule_IncreaseSelectedAmmoCapacity
                move.w  d1,(a0)
                clr.w   8(a0)
                addq.w  #2,d1
                move.w  d1,(WeaponStateIndex).w
                asl.w   #1,d1
                move.w  d1,(WeaponIconTransferState).w
                jsr     (Weapon_ClearRuntimeParameters).l
                jsr     (Sys_ClearObjectBlocks16).l
                jsr     (UI_QueueSelectedWeaponIconTransfer).l
                bra.s   Pickup_UpdateWeaponCapsule_RefillSelectedAmmoAndCommit
; ---------------------------------------------------------------------------
Pickup_UpdateWeaponCapsule_IncreaseSelectedAmmoCapacity:  ; was: loc_2BCBE
                addi.w  #$FA,$18(a0)
                cmpi.w  #$7D0,$18(a0)
                bmi.s   Pickup_UpdateWeaponCapsule_RefillSelectedAmmoAndCommit
                move.w  #$7D0,$18(a0)
Pickup_UpdateWeaponCapsule_RefillSelectedAmmoAndCommit:  ; was: loc_2BCD2
                                        ; Pickup_UpdateWeaponCapsule+10A   j
                move.w  $18(a0),$10(a0)
                move.w  #$330,(a5)
                clr.b   $21(a5)
Pickup_UpdateWeaponCapsule_ClearInteractionFlags:       ; was: loc_2BCE0
                                        ; Pickup_UpdateWeaponCapsule+A4   j
                clr.b   $22(a5)
                rts
; ---------------------------------------------------------------------------
Pickup_UpdateWeaponCapsule_RetireWhenStateHasNoDisplay:  ; was: loc_2BCE6
                bset    #4,2(a5)
                rts
; End of function Pickup_UpdateWeaponCapsule
; Initializes the weapon-selection object on first update
Pickup_WeaponCapsule:                                   ; was: sub_2BCEE
                tst.w   4(a5)
                bne.s   Pickup_WeaponCapsule_Update
                bsr.w   Pickup_InitWeaponCapsule
; Runs the weapon-selection object update
Pickup_WeaponCapsule_Update:                            ; was: loc_2BCF8
                bra.w   Pickup_UpdateWeaponCapsule
; End of function Pickup_WeaponCapsule
