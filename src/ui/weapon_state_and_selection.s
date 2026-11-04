Weapon_UpdateStateAndAmmoRegen:                         ; was: sub_178FE
                                        ; WeaponSetup_UpdateScreen+2A   p
                tst.b   (FrameControlFlags).w
                bmi.w   Weapon_UpdateStateAndAmmoRegenReturn
                bsr.w   Weapon_UpdateCurrentState
                move.w  (WeaponSlotOffset).w,d0
                cmpi.w  #$12,(WeaponStateIndex).w
                bmi.s   Weapon_SelectAmmoRegenSkipSlot
                moveq   #8,d0
Weapon_SelectAmmoRegenSkipSlot:                         ; was: loc_17918
                movea.w #(WeaponSlotConfig0-M68K_RAM),a0
                lea     Weapon_AmmoRegenStepDelays(pc),a1
                moveq   #0,d1
                moveq   #3,d7
Weapon_UpdateSlotAmmoRegenLoop:                         ; was: loc_17924
                cmp.w   d0,d1
                beq.s   Weapon_AdvanceAmmoRegenSlot
                move.w  (a0),d2
                subq.w  #1,8(a0)
                bpl.s   Weapon_AdvanceAmmoRegenSlot
                move.w  (a1,d2.w),8(a0)
                addq.w  #2,$10(a0)
                move.w  $18(a0),d2
                cmp.w   $10(a0),d2
                bpl.s   Weapon_AdvanceAmmoRegenSlot
                move.w  d2,$10(a0)
; Advances to the next weapon slot in the ammunition-regeneration pass
Weapon_AdvanceAmmoRegenSlot:                            ; was: loc_17948
                                        ; Weapon_UpdateStateAndAmmoRegen+30   j
                addq.w  #2,a0
                addq.w  #2,d1
                dbf     d7,Weapon_UpdateSlotAmmoRegenLoop
; Return after updating weapon state and inactive-slot ammunition regeneration
Weapon_UpdateStateAndAmmoRegenReturn:                   ; was: locret_17950
                rts
; End of function Weapon_UpdateStateAndAmmoRegen
; Updates shared cooldowns and dispatches the current weapon state
Weapon_UpdateCurrentState:                              ; was: sub_17952
                movea.w (WeaponSlotOffset).w,a1
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a1
                lea     Weapon_DirectionVectorPointerBias(pc),a2
                nop
                tst.w   (WeaponFireCooldown).w
                bmi.s   Weapon_UpdateStateCooldown
                subq.w  #1,(WeaponFireCooldown).w
Weapon_UpdateStateCooldown:                             ; was: loc_1796A
                tst.w   (WeaponStateCooldown).w
                bmi.s   Weapon_DispatchCurrentState
                subq.w  #1,(WeaponStateCooldown).w
; Dispatches the handler selected by WeaponStateIndex
Weapon_DispatchCurrentState:                            ; was: loc_17974
                move.w  (WeaponStateIndex).w,d0
                movea.w Weapon_StateHandlerOffsets(pc,d0.w),a0
                adda.l  #Weapon_GetStateDisplayIndex,a0
                jmp     (a0)
; End of function Weapon_UpdateCurrentState
; ---------------------------------------------------------------------------
Weapon_StateHandlerOffsets: dc.w    Weapon_UpdateStateAndAmmoRegenReturn-Weapon_GetStateDisplayIndex  ; was: off_17984
                dc.w    Weapon_ConfigureState2Lifetime-Weapon_GetStateDisplayIndex
                dc.w    Weapon_ConfigureState4ProjectileCompanions-Weapon_GetStateDisplayIndex
                dc.w    Weapon_ConfigureState6Motion-Weapon_GetStateDisplayIndex
                dc.w    Weapon_ConfigureState8Targeting-Weapon_GetStateDisplayIndex
                dc.w    Weapon_ConfigureState10MotionAndPalette-Weapon_GetStateDisplayIndex
                dc.w    Weapon_UpdateState12Icon-Weapon_GetStateDisplayIndex
                dc.w    Weapon_UpdateStateAndAmmoRegenReturn-Weapon_GetStateDisplayIndex
                dc.w    Weapon_UpdateStateAndAmmoRegenReturn-Weapon_GetStateDisplayIndex
                dc.w    WeaponSelect_Initialize-Weapon_GetStateDisplayIndex
                dc.w    WeaponSelect_Update-Weapon_GetStateDisplayIndex

; Returns the display index associated with WeaponStateIndex
Weapon_GetStateDisplayIndex:                            ; was: sub_1799A
                                        ; Pickup_UpdateWeaponCapsule+B2   p
                movea.w (WeaponSlotOffset).w,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  (WeaponStateIndex).w,d0
                move.w  Weapon_StateDisplayIndexTable(pc,d0.w),d0
                rts
; End of function Weapon_GetStateDisplayIndex
; ---------------------------------------------------------------------------
Weapon_StateDisplayIndexTable:  dc.w    0, 2, 4, 6, 8, $A, $C, $E, $10, 0, 0  ; was: word_179AC

; Initializes the circular four-slot weapon-selection overlay
WeaponSelect_Initialize:                                ; was: sub_179C2
                movea.w #(WeaponAmmoRegenTimers-M68K_RAM),a0
                move.w  (WeaponSlotOffset).w,d0
                move.w  #$258,(a0,d0.w)
                move.w  (WeaponSlotOffset).w,d0
                move.w  d0,(WeaponMenuSlotOffset).w
                addq.w  #2,(WeaponStateIndex).w
                bsr.w   Weapon_ClearRuntimeParameters
                move.w  #$14,(WeaponIconTransferState).w
                lea     WeaponSelect_TargetAngles(pc),a0
                nop
                move.w  (WeaponMenuSlotOffset).w,d1
                move.w  (a0,d1.w),d1
                addi.w  #$100,d1
                andi.w  #$1FF,d1
                move.w  d1,(WeaponMenuAngle).w
                move.w  #$A0,(WeaponMenuRadius).w
                move.w  d0,(WeaponFireCooldown).w
                bsr.w   Sys_ClearObjectBlocks17
                movea.w #(PlayerEffectObjectPool-M68K_RAM),a0
                move.w  #$10,(a0)
                move.l  #Effect_SpriteAnimation13,8(a0)
                move.w  #$E080,2(a0)
                move.w  #$80,$10(a0)
                move.w  #$80,$14(a0)
                move.w  #$C80,$E(a0)
                move.w  (GlobalSpritePriorityBit).w,d6
                or.w    d6,$E(a0)
                movea.w #(PlayerEffectAllocStart-M68K_RAM),a0
                movea.w #(WeaponSlotConfig0-M68K_RAM),a1
                lea     WeaponSelect_SlotInitialAngles(pc),a3
                nop
                lea     WeaponSelect_SpriteFramePointers(pc),a4
                movea.w #(PlayerObjectType-M68K_RAM),a5
                move.w  (GlobalSpritePriorityBit).w,d3
                moveq   #0,d4
                moveq   #3,d7
; Initializes all four weapon-selection slot objects
WeaponSelect_InitializeSlotLoop:                        ; was: loc_17A5C
                move.w  #$3C,(a0)                       ; '<'
                move.w  #$C080,2(a0)
                move.w  $10(a2),$10(a0)
                move.w  $14(a2),$14(a0)
                move.w  d3,$E(a0)
                move.w  (a1)+,d0
                asl.w   #1,d0
                move.l  (a4,d0.w),8(a0)
                move.w  d4,$48(a0)
                move.w  (a3)+,$50(a0)
                addq.w  #2,d4
                lea     $60(a0),a0
                dbf     d7,WeaponSelect_InitializeSlotLoop
                move.b  #$C0,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function WeaponSelect_Initialize
; ---------------------------------------------------------------------------
WeaponSelect_SlotInitialAngles: dc.w    $180, 0, $80, $100  ; was: word_17A9C
WeaponSelect_TargetAngles:      dc.w    0, $180, $100, $80  ; was: word_17AA4
                                        ; WeaponSelect_UpdateRotationInput+8   r

; Rotates the overlay toward the currently selected slot
WeaponSelect_UpdateRotationInput:                       ; was: sub_17AAC
                move.w  (WeaponMenuAngle).w,d0
                move.w  (WeaponMenuSlotOffset).w,d1
                cmp.w   WeaponSelect_TargetAngles(pc,d1.w),d0
                beq.s   WeaponSelect_CheckInputBit3
                add.w   (WeaponMenuAngularStep).w,d0
                andi.w  #$1F0,d0
                move.w  d0,(WeaponMenuAngle).w
                rts
; ---------------------------------------------------------------------------
WeaponSelect_CheckInputBit3:                            ; was: loc_17AC8
                btst    #3,(PlayerPressedInput).w
                beq.s   WeaponSelect_CheckInputBit2
                move.w  #$FFF0,(WeaponMenuAngularStep).w
                addq.w  #2,(WeaponMenuSlotOffset).w
                andi.w  #6,(WeaponMenuSlotOffset).w
                move.b  #$A8,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
WeaponSelect_CheckInputBit2:                            ; was: loc_17AEA
                btst    #2,(PlayerPressedInput).w
                beq.s   WeaponSelect_RotationInputReturn
                move.w  #$10,(WeaponMenuAngularStep).w
                subq.w  #2,(WeaponMenuSlotOffset).w
                andi.w  #6,(WeaponMenuSlotOffset).w
                move.b  #$A8,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
WeaponSelect_RotationInputReturn:                       ; was: locret_17B0C
                rts
; End of function WeaponSelect_UpdateRotationInput
; Maps directional input bits to one of the four weapon slots
WeaponSelect_HandleDirectionalInput:                    ; was: sub_17B0E
                move.b  (PlayerPressedInput).w,d0
                andi.b  #$F,d0
                beq.s   WeaponSelect_DirectionalInputReturn
                move.b  #$A8,d0
                jsr     (Sound_QueueSFXRequest).l
                move.b  (PlayerPressedInput).w,d0
                btst    #0,d0
                beq.s   WeaponSelect_CheckInputBit1
                move.w  #0,(WeaponMenuSlotOffset).w
WeaponSelect_DirectionalInputReturn:                    ; was: locret_17B32
                                        ; WeaponSelect_HandleDirectionalInput+46   j
                rts
; ---------------------------------------------------------------------------
WeaponSelect_CheckInputBit1:                            ; was: loc_17B34
                btst    #1,d0
                beq.s   WeaponSelect_CheckDirectionalBit3
                move.w  #4,(WeaponMenuSlotOffset).w
                rts
; ---------------------------------------------------------------------------
WeaponSelect_CheckDirectionalBit3:                      ; was: loc_17B42
                btst    #3,d0
                beq.s   WeaponSelect_CheckDirectionalBit2
                move.w  #2,(WeaponMenuSlotOffset).w
                rts
; ---------------------------------------------------------------------------
WeaponSelect_CheckDirectionalBit2:                      ; was: loc_17B50
                btst    #2,d0
                beq.s   WeaponSelect_DirectionalInputReturn
                move.w  #6,(WeaponMenuSlotOffset).w
                rts
; End of function WeaponSelect_HandleDirectionalInput
; Clears shared weapon targeting, icon, animation, motion, and mode parameters
Weapon_ClearRuntimeParameters:                          ; was: sub_17B5E
                                        ; Weapon_AdvanceCurrentState+16   p
                moveq   #0,d0
                move.w  d0,(WeaponTargetOrFrame).w
                move.w  d0,(WeaponIconFrameTile).w
                move.w  d0,(WeaponAnimationDataPtr).w
                move.w  d0,(WeaponAnimationDataPtr+2).w
                move.w  d0,(WeaponYMotionParameter).w
                move.w  d0,(WeaponYMotionParameter+2).w
                move.w  d0,(WeaponXMotionParameter).w
                move.w  d0,(WeaponXMotionParameter+2).w
                move.w  d0,(WeaponModeParameter).w
                move.w  d0,(WeaponModeParameter+2).w
                rts
; End of function Weapon_ClearRuntimeParameters
; Updates the weapon-selection overlay and handles its close transition
WeaponSelect_Update:                                    ; was: sub_17B8A
                bsr.w   WeaponSelect_CommitSelectedSlot
                tst.w   (PlayerDefeatPhase).w
                bne.w   WeaponSelect_StartCloseAndAdvanceState
                btst    #6,(PlayerActionStateFlags).w
                bne.s   WeaponSelect_UpdateOpenState
                btst    #0,(PlayerActionStateFlags).w
                bne.w   Weapon_CommitStateTransition
WeaponSelect_UpdateOpenState:                           ; was: loc_17BA8
                tst.w   (PlayerScriptStateOffset).w
                bne.w   Weapon_CommitStateTransition
                subi.w  #8,(WeaponMenuRadius).w
                cmpi.w  #$20,(WeaponMenuRadius).w       ; ' '
                bmi.s   WeaponSelect_HandleOpenInput
                moveq   #$10,d0
                btst    #3,(PlayerSpriteAttributes).w
                bne.s   WeaponSelect_ApplyFacingRotationStep
                moveq   #$FFFFFFF0,d0
WeaponSelect_ApplyFacingRotationStep:                   ; was: loc_17BCA
                add.w   d0,(WeaponMenuAngle).w
                andi.w  #$1F8,(WeaponMenuAngle).w
                rts
; ---------------------------------------------------------------------------
WeaponSelect_HandleOpenInput:                           ; was: loc_17BD6
                bsr.w   WeaponSelect_UpdateRotationInput
                move.w  #$20,(WeaponMenuRadius).w       ; ' '
                move.b  (PlayerPressedInput).w,d0
                andi.b  #$70,d0                         ; 'p'
                bne.s   WeaponSelect_StartCloseAndAdvanceState
                rts
; ---------------------------------------------------------------------------
WeaponSelect_StartCloseAndAdvanceState:                 ; was: loc_17BEC
                                        ; WeaponSelect_Update+5E   j
                move.b  #$A7,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #8,(WeaponStateCooldown).w
; Fall through to advance the selected slot's weapon state
; End of function WeaponSelect_Update
; Advances the active slot's weapon state and clears transient state
Weapon_AdvanceCurrentState:                             ; was: sub_17BFC
                                        ; WeaponSetup_HandleLoadoutInput+7A   p
                movea.w (WeaponSlotOffset).w,a0
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  (a0),d0
                addq.w  #2,d0
                move.w  d0,(WeaponStateIndex).w
                asl.w   #1,d0
                move.w  d0,(WeaponIconTransferState).w
                bsr.w   Weapon_ClearRuntimeParameters
                bra.w   Sys_ClearObjectBlocks16
; End of function Weapon_AdvanceCurrentState
; Commits a state transition, restoring the saved slot when required
Weapon_CommitStateTransition:                           ; was: sub_17C1A
                                        ; WeaponSelect_Update+22   j
                move.w  (WeaponStateIndex).w,d0
                bne.s   Weapon_CheckRestoreSavedSlot
                clr.w   (WeaponSavedSlotOffset).w
                bra.s   Weapon_RestoreSavedSlot
; ---------------------------------------------------------------------------
Weapon_CheckRestoreSavedSlot:                           ; was: loc_17C26
                cmpi.w  #$12,d0
                bmi.s   Weapon_FinalizeStateTransition
Weapon_RestoreSavedSlot:                                ; was: loc_17C2C
                movea.w (WeaponSavedSlotOffset).w,a0
                move.w  a0,(WeaponSlotOffset).w
                adda.w  #(WeaponSlotConfig0-M68K_RAM),a0
                move.w  (a0),d0
                addq.w  #2,d0
                move.w  d0,(WeaponStateIndex).w
; Updates icon-transfer state, clears cooldown, and resets transient objects
Weapon_FinalizeStateTransition:                         ; was: loc_17C40
                asl.w   #1,d0
                move.w  d0,(WeaponIconTransferState).w
                clr.w   (WeaponStateCooldown).w
                bra.w   Sys_ClearObjectBlocks16
; End of function Weapon_CommitStateTransition
; Commits the menu slot offset as the active weapon slot
WeaponSelect_CommitSelectedSlot:                        ; was: sub_17C4E
                move.w  (WeaponMenuSlotOffset).w,(WeaponSlotOffset).w
                rts
; End of function WeaponSelect_CommitSelectedSlot
; Selects state-two projectile lifetime from the active slot's remaining ammo
Weapon_ConfigureState2Lifetime:                         ; was: sub_17C56
                moveq   #$E,d0
                move.w  $10(a1),d1
                cmpi.w  #$708,d1
                bpl.s   Weapon_StoreState2Lifetime
                subq.w  #2,d0
                cmpi.w  #$3E8,d1
                bpl.s   Weapon_StoreState2Lifetime
                subq.w  #2,d0
                cmpi.w  #$320,d1
                bpl.s   Weapon_StoreState2Lifetime
                subq.w  #2,d0
Weapon_StoreState2Lifetime:                             ; was: loc_17C74
                                        ; Weapon_ConfigureState2Lifetime+12   j
                move.w  d0,(WeaponModeParameter).w
                bra.w   Weapon_UpdateTargetingReticle
; End of function Weapon_ConfigureState2Lifetime
; Initializes four companions for type-$22C projectiles and their ammo flag
Weapon_ConfigureState4ProjectileCompanions:             ; was: sub_17C7C
                movea.w #(PlayerEffectObjectPool-M68K_RAM),a0
                moveq   #3,d7
Weapon_State4CompanionInitLoop:                         ; was: loc_17C82
                tst.w   (a0)
                bne.s   Weapon_State4NextCompanion
                move.w  #$A0,(a0)
                move.w  #$8080,2(a0)
                move.w  #$22C,$48(a0)
Weapon_State4NextCompanion:                             ; was: loc_17C96
                lea     $C0(a0),a0
                dbf     d7,Weapon_State4CompanionInitLoop
                clr.w   (WeaponModeParameter).w
                move.w  $10(a1),d0
                cmpi.w  #$320,d0
                bmi.s   Weapon_State4UpdateTargetingReticle
                addq.w  #1,(WeaponModeParameter).w
; Continues state-four processing through the targeting reticle update
Weapon_State4UpdateTargetingReticle:                    ; was: loc_17CB0
                bra.w   Weapon_UpdateTargetingReticle
; End of function Weapon_ConfigureState4ProjectileCompanions
; Configures state-six velocity and its ammo-indexed direction vectors
Weapon_ConfigureState6Motion:                           ; was: sub_17CB4
                move.w  (FrameCounter).w,d0
                btst    #7,d0
                bne.s   Weapon_State6SelectSpeedFromAmmo
                andi.w  #$7F,d0
                cmpi.w  #$40,d0                         ; '@'
                bmi.s   Weapon_State6SelectSpeedFromAmmo
                move.w  (RandomNumberState).w,d3
                andi.w  #1,d3
                addq.w  #3,d3
                bra.s   Weapon_State6CalculateVelocity
; ---------------------------------------------------------------------------
Weapon_State6SelectSpeedFromAmmo:                       ; was: loc_17CD4
                                        ; Weapon_ConfigureState6Motion+12   j
                move.w  $10(a1),d0
                moveq   #2,d3
                cmpi.w  #$3E8,d0
                bmi.s   Weapon_State6CalculateVelocity
                moveq   #3,d3
                cmpi.w  #$708,d0
                bmi.s   Weapon_State6CalculateVelocity
                moveq   #4,d3
Weapon_State6CalculateVelocity:                         ; was: loc_17CEA
                                        ; Weapon_ConfigureState6Motion+2A   j
                movea.l #Math_SineTable,a0
                move.w  (RandomNumberState).w,d0
                andi.w  #$1FE,d0
                move.w  -$80(a0,d0.w),d1
                move.w  (a0,d0.w),d2
                ext.l   d1
                ext.l   d2
                asl.l   d3,d1
                asl.l   d3,d2
                move.l  d1,(WeaponYMotionParameter).w
                move.l  (StageMotionXDelta).w,d0
                asl.l   #1,d0
                add.l   d0,d2
                move.l  d2,(WeaponXMotionParameter).w
                moveq   #0,d0
                move.w  $10(a1),d0
                cmpi.w  #$7D0,d0
                bmi.s   Weapon_State6ClampAmmoOffset
                move.l  #Weapon_DirectionVectorsSpeed13,(WeaponModeParameter).w
                rts
; ---------------------------------------------------------------------------
Weapon_State6ClampAmmoOffset:                           ; was: loc_17D2E
                subq.w  #8,d0
                bpl.s   Weapon_State6ScaleMotionIndex
                moveq   #0,d0
Weapon_State6ScaleMotionIndex:                          ; was: loc_17D34
                divs.w  #$FA,d0
                asl.w   #2,d0
                andi.w  #$1C,d0
                move.l  (a2,d0.w),(WeaponModeParameter).w
                rts
; End of function Weapon_ConfigureState6Motion
; Configures state-eight motion data and selects an eligible target
Weapon_ConfigureState8Targeting:                        ; was: sub_17D46
                move.w  #0,(WeaponXMotionParameter+2).w
                moveq   #0,d0
                move.w  $10(a1),d0
                bne.s   Weapon_State8SelectMotionTable
                move.w  #1,(WeaponXMotionParameter+2).w
Weapon_State8SelectMotionTable:                         ; was: loc_17D5A
                cmpi.w  #$3E8,d0
                bmi.s   Weapon_State8CalculateMotionIndex
                moveq   #$1C,d0
                bra.s   Weapon_State8StoreMotionTable
; ---------------------------------------------------------------------------
Weapon_State8CalculateMotionIndex:                      ; was: loc_17D64
                subq.w  #8,d0
                bpl.s   Weapon_State8ClampMotionIndex
                moveq   #0,d0
Weapon_State8ClampMotionIndex:                          ; was: loc_17D6A
                divs.w  #$7D,d0                         ; '}'
                asl.w   #2,d0
                andi.w  #$1C,d0
Weapon_State8StoreMotionTable:                          ; was: loc_17D74
                move.l  -$C(a2,d0.w),(WeaponModeParameter).w
                movea.w #(PlayerEffectObjectPool-M68K_RAM),a0
                moveq   #3,d7
Weapon_State8CompanionInitLoop:                         ; was: loc_17D80
                tst.w   (a0)
                bne.s   Weapon_State8NextCompanion
                move.w  #$A0,(a0)
                move.w  #$8080,2(a0)
                move.w  #$6C,$48(a0)                    ; 'l'
Weapon_State8NextCompanion:                             ; was: loc_17D94
                lea     $C0(a0),a0
                dbf     d7,Weapon_State8CompanionInitLoop
                clr.w   (WeaponTargetOrFrame).w
                move.w  (LockOnListCountMinus1).w,d7
                bmi.s   Weapon_State8SelectLowestValueTarget
                movea.w #(LockOnTargetList-M68K_RAM),a1
Weapon_State8FindFlaggedTarget:                         ; was: loc_17DAA
                movea.w (a1)+,a0
                btst    #7,$23(a0)
                bne.s   Weapon_State8UseFlaggedTarget
                dbf     d7,Weapon_State8FindFlaggedTarget
                rts
; ---------------------------------------------------------------------------
Weapon_State8UseFlaggedTarget:                          ; was: loc_17DBA
                move.w  a0,(WeaponTargetOrFrame).w
                btst    #4,(ControllerHeldState).w
                beq.w   Weapon_UpdateTargetingReticle_Scan
                moveq   #1,d6
                bra.w   Weapon_AppendTargetingReticleForObject
; ---------------------------------------------------------------------------
Weapon_State8SelectLowestValueTarget:                   ; was: loc_17DCE
                move.w  (TargetListCountMinus1).w,d7
                bmi.s   Weapon_State8TargetSelectionReturn
                movea.w #(CollisionTargetList-M68K_RAM),a0
                movea.w (a0)+,a1
                move.w  $24(a1),d0
Weapon_State8AdvanceOrFinishTargetScan:                 ; was: loc_17DDE
                                        ; Weapon_ConfigureState8Targeting+AA   j
                dbf     d7,Weapon_State8CompareNextTargetValue
                move.w  a1,(WeaponTargetOrFrame).w
Weapon_State8TargetSelectionReturn:                     ; was: locret_17DE6
                rts
; ---------------------------------------------------------------------------
Weapon_State8CompareNextTargetValue:                    ; was: loc_17DE8
                movea.w (a0)+,a2
                cmp.w   $24(a2),d0
                beq.s   Weapon_State8AdvanceOrFinishTargetScan
                bmi.s   Weapon_State8AdvanceOrFinishTargetScan
                movea.w a2,a1
                move.w  $24(a1),d0
                bra.s   Weapon_State8AdvanceOrFinishTargetScan
; End of function Weapon_ConfigureState8Targeting
; Configures state-ten direction vectors and cycles palette color 54
Weapon_ConfigureState10MotionAndPalette:                ; was: sub_17DFA
                moveq   #0,d0
                move.w  $10(a1),d0
                cmpi.w  #$3E8,d0
                bmi.s   Weapon_State10ClampAmmoOffset
                move.l  #Weapon_DirectionVectorsSpeed12,(WeaponModeParameter).w
                bra.s   Weapon_UpdateState10PaletteColor
; ---------------------------------------------------------------------------
Weapon_State10ClampAmmoOffset:                          ; was: loc_17E10
                subq.w  #8,d0
                bpl.s   Weapon_State10ScaleMotionIndex
                moveq   #0,d0
Weapon_State10ScaleMotionIndex:                         ; was: loc_17E16
                divs.w  #$80,d0
                asl.w   #2,d0
                andi.w  #$1C,d0
                move.l  -8(a2,d0.w),(WeaponModeParameter).w
; Writes the state-ten color cycle to both palette buffers
Weapon_UpdateState10PaletteColor:                       ; was: loc_17E26
                move.w  (FrameCounter).w,d0
                asl.w   #1,d0
                andi.w  #6,d0
                move.w  Weapon_State10PaletteColorCycle(pc,d0.w),(PaletteActiveColor54).w
                move.w  Weapon_State10PaletteColorCycle(pc,d0.w),(PaletteShadowColor54).w
                rts
; End of function Weapon_ConfigureState10MotionAndPalette
; ---------------------------------------------------------------------------
Weapon_State10PaletteColorCycle:    binclude "data/palettes/017E3E.bin"  ; was: word_17E3E
                                        ; Weapon_ConfigureState10MotionAndPalette+3C   r

; Advances the state-twelve icon animation and queues its DMA transfer
Weapon_UpdateState12Icon:                               ; was: sub_17E46
                tst.l   (WeaponAnimationDataPtr).w
                bne.s   Weapon_State12AdvanceIconFrame
Weapon_State12IconReturn:                               ; was: locret_17E4C
                rts
; ---------------------------------------------------------------------------
Weapon_State12AdvanceIconFrame:                         ; was: loc_17E4E
                move.w  (WeaponTargetOrFrame).w,d0
                cmpi.w  #$20,d0                         ; ' '
                bpl.s   Weapon_State12IconReturn
                addq.w  #2,(WeaponTargetOrFrame).w
                andi.w  #$1E,d0
                tst.w   (ShootingMode).w
                beq.s   Weapon_QueueState12IconFrameTransfer
                addi.w  #$20,d0                         ; ' '
; Selects the state-twelve palette/frame and queues its DMA transfer
Weapon_QueueState12IconFrameTransfer:                   ; was: loc_17E6A
                move.w  Weapon_State12IconColorRamps(pc,d0.w),(PaletteActiveColor54).w
                move.w  Weapon_State12IconColorRamps(pc,d0.w),(PaletteShadowColor54).w
                lsr.w   #1,d0
                andi.w  #$E,d0
                movea.l (WeaponAnimationDataPtr).w,a0
                move.w  $20(a0,d0.w),(WeaponIconFrameTile).w
                asl.w   #1,d0
                move.l  (a0,d0.w),d0
                move.l  #$94009340,d1
                jmp     UI_QueueWeaponStateIconTransferFromSource
; End of function Weapon_UpdateState12Icon
; ---------------------------------------------------------------------------
Weapon_State12IconColorRamps:   dc.w    $EEE, $CEE, $AEE, $8EC, $6EC, $4EA, $2EA, $2E8, $2E8, $E6, $E6, $E4, $E4, $E2, $E2, $C0  ; was: word_17E98
                                        ; Weapon_UpdateState12Icon+2A   r
                dc.w    $EEE, $EEC, $EEA, $8CE, $6CE, $4AE, $2AE, $28E, $28E, $6E, $6E, $4E, $4E, $2E, $2E, $C
