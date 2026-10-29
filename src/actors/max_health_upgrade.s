; Initializes the max-health upgrade pickup's sprite and collision fields
Pickup_InitializeMaxHealthUpgrade:                      ; was: sub_2BAB4
                addq.w  #2,4(a5)
                move.w  #$E700,2(a5)
                move.l  #SharedCombatSpriteAnimation26,8(a5)
                clr.w   $C(a5)
                move.w  #$480,$E(a5)
                clr.b   $20(a5)
                move.b  #$C0,$21(a5)
                move.b  #$30,$23(a5)                    ; '0'
                move.l  #$F808F808,$2C(a5)
                move.l  #$FC04FC04,$28(a5)
                rts
; End of function Pickup_InitializeMaxHealthUpgrade
; Collects the pickup, raises the health maximum, and starts its feedback object
Pickup_UpdateMaxHealthUpgrade:                          ; was: sub_2BAF2
                bclr    #7,$22(a5)
                beq.s   Pickup_ApplyMaxHealthUpgradeSpritePriority
                bclr    #4,$22(a5)
                bne.s   Pickup_ApplyMaxHealthUpgradeSpritePriority
                move.b  #$A7,d0
                jsr     (Sound_QueueSFXRequest).l
                tst.w   (PlayerHealth).w
                beq.w   Pickup_ConvertMaxHealthUpgradeToCollectedFeedback
                bmi.w   Pickup_ConvertMaxHealthUpgradeToCollectedFeedback
                addi.w  #$20,(PlayerMaxHealth).w        ; ' '
                cmpi.w  #$400,(PlayerMaxHealth).w
                bmi.s   Pickup_RefillHealthFromUpgradedMaximum
                move.w  #$400,(PlayerMaxHealth).w
Pickup_RefillHealthFromUpgradedMaximum:                 ; was: loc_2BB2C
                move.w  (PlayerMaxHealth).w,(PlayerHealth).w
Pickup_ConvertMaxHealthUpgradeToCollectedFeedback:      ; was: loc_2BB32
                                        ; Pickup_UpdateMaxHealthUpgrade+22   j
                move.w  #$32C,(a5)
                clr.b   $21(a5)
                rts
; ---------------------------------------------------------------------------
; Applies the global sprite-priority direction while the pickup remains active
Pickup_ApplyMaxHealthUpgradeSpritePriority:             ; was: loc_2BB3C
                                        ; Pickup_UpdateMaxHealthUpgrade+E   j
                bclr    #7,$E(a5)
                move.w  (GlobalSpritePriorityBit).w,d0
                or.w    d0,$E(a5)
                rts
; End of function Pickup_UpdateMaxHealthUpgrade
; Initializes or updates the max-health upgrade pickup
Pickup_MaxHealthUpgradeMain:                            ; was: sub_2BB4C
                tst.w   4(a5)
                bne.s   Pickup_MaxHealthUpgradeMain_Update
                bsr.w   Pickup_InitializeMaxHealthUpgrade
Pickup_MaxHealthUpgradeMain_Update:                     ; was: loc_2BB56
                bra.w   Pickup_UpdateMaxHealthUpgrade
; End of function Pickup_MaxHealthUpgradeMain
; Retires a collected max-health upgrade after freezing play and requesting SFX $1B
Pickup_MaxHealthUpgradeCollectedFeedback:               ; was: sub_2BB5A
                move.w  #$30,(FrameFreezeTimer).w       ; '0'
                bset    #4,2(a5)
                move.b  #$1B,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Pickup_MaxHealthUpgradeCollectedFeedback
