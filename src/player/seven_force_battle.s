; Update the player through the Seven Forces battle state machine
Player_UpdateSevenForceBattle:                         ; CODE XREF: Player_Update+46   j  ; was: sub_19DAE
                                        ; Player_UpdateSevenForcesBattleVisible   p
                jsr     (Gfx_LoadPlayerPaletteData).l
                jsr     (Input_ProcessDirectionInput).l
                bclr    #6,$22(a5)
                beq.s   Player_UpdateSevenForceBattleDispatchState
                bsr.w   Player_EnterSevenForceDefeatStateA
                bra.s   Player_UpdateSevenForceBattleClampFallVelocity
; ---------------------------------------------------------------------------
Player_UpdateSevenForceBattleDispatchState:            ; CODE XREF: Player_UpdateSevenForcesBattle+12   j  ; was: loc_19DC8
                jsr     (Player_UpdateCounterForceInput).l
                bsr.w   Player_DispatchSevenForceBattleState
Player_UpdateSevenForceBattleClampFallVelocity:        ; CODE XREF: Player_UpdateSevenForcesBattle+18   j  ; was: loc_19DD2
                tst.w   $1C(a5)
                bmi.s   Player_UpdateSevenForceBattleFinalizeFrame
                cmpi.w  #$158,$14(a5)
                bmi.s   Player_UpdateSevenForceBattleFinalizeFrame
                clr.l   $1C(a5)
Player_UpdateSevenForceBattleFinalizeFrame:            ; CODE XREF: Player_UpdateSevenForcesBattle+28   j  ; was: loc_19DE4
                                        ; Player_UpdateSevenForcesBattle+30   j
                jsr     (Player_UpdateSpritePriorityBit).l
                move.b  $69(a5),$6B(a5)
                jsr     (Player_UpdateInvulnerabilityTimer).l
                jsr     (Player_SetHitbox).l
                clr.b   (PlayerDashStopFlag).w
                jmp     Player_CalculateCenterPosition
; End of function Player_UpdateSevenForcesBattle
; Dispatch the Seven Forces player battle state
Player_DispatchSevenForceBattleState:                  ; CODE XREF: Player_UpdateSevenForcesBattle+20   p  ; was: sub_19E06
                move.w  4(a5),d0
                movea.w Player_SevenForceBattleStateOffsets(pc,d0.w),a0
                adda.l  #Player_ResetSevenForceBattleState,a0
                jmp     (a0)
; End of function Player_DispatchSevenForcesBattleState
; ---------------------------------------------------------------------------
Player_SevenForceBattleStateOffsets:   dc.w    Player_SevenForceState0-Player_ResetSevenForceBattleState  ; was: off_19E16
                                        ; DATA XREF: Player_DispatchSevenForcesBattleState+4   r
                dc.w    Player_SevenForceState2-Player_ResetSevenForceBattleState
                dc.w    Player_SevenForceWeaponSelectState-Player_ResetSevenForceBattleState
                dc.w    Player_SevenForceDashState6-Player_ResetSevenForceBattleState
                dc.w    Player_SevenForceCounterForceState-Player_ResetSevenForceBattleState
                dc.w    Player_SevenForceDefeatStateA-Player_ResetSevenForceBattleState
                dc.w    Player_ResetSevenForceBattleState-Player_ResetSevenForceBattleState

; Restore the base Seven Forces player state
Player_ResetSevenForceBattleState:                     ; CODE XREF: Player_SevenForcesWeaponSelectState+6   j  ; was: sub_19E24
                                        ; Player_SevenForcesState2+22   j
                move.b  #$7F,(PlayerInputMask).w
                bclr    #0,(CounterForceTriggerFlag).w
                clr.w   (PlayerAirMoveUsedFlags).w
                move.w  #0,4(a5)
                clr.l   $18(a5)
                clr.w   $48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$1C,$5C(a5)
                jmp     Player_AutoFlipDirection
; End of function Player_ResetSevenForcesBattleState
Player_SevenForceState0Return:                         ; CODE XREF: Player_SevenForcesState0+14   j  ; was: nullsub_51
                                        ; Player_SevenForcesState0+1A   j
                rts
; End of function Player_SevenForcesState0Return

; Base Seven Forces player movement and action state
Player_SevenForceState0:                               ; DATA XREF: ROM:Player_SevenForcesBattleStateOffsets   o  ; was: sub_19E56
                move.w  #$1C,$5C(a5)
                bsr.w   Player_DampenSevenForceVelocity
                jsr     (Effect_SpawnParticle).l
                bsr.w   Player_CheckSevenForceWeaponSelectInput
                bne.s   Player_SevenForceState0Return
                bsr.w   Player_TryStartSevenForceDash
                bne.s   Player_SevenForceState0Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartSevenForceCounterForce
                btst    #4,$69(a5)
                beq.s   Player_SevenForceState0CheckDirectionalInput
                tst.w   (ShootingMode).w
                bne.s   Player_SevenForceState0Render
Player_SevenForceState0CheckDirectionalInput:          ; CODE XREF: Player_SevenForcesState0+2C   j  ; was: loc_19E8A
                move.b  $69(a5),d0
                andi.b  #$F,d0
                bne.w   Player_EnterSevenForceState2
Player_SevenForceState0Render:                         ; CODE XREF: Player_SevenForcesState0+32   j  ; was: loc_19E96
                bra.w   Player_RenderSevenForceBattleFrame
; End of function Player_SevenForcesState0
; Opens Seven Forces weapon selection with A, or toggles shooting mode with down+A
Player_CheckSevenForceWeaponSelectInput:               ; CODE XREF: Player_SevenForcesState0+10   p  ; was: sub_19E9A
                                        ; Player_SevenForcesState2   p
                btst    #6,$6A(a5)
                beq.s   Player_CheckSevenForceWeaponSelectInput_NotActivated
                btst    #1,$69(a5)
                bne.w   Player_ToggleSevenForceShootingMode
                tst.w   (WeaponStateCooldown).w
                bmi.s   Player_StartSevenForceWeaponSelect
Player_CheckSevenForceWeaponSelectInput_NotActivated:  ; CODE XREF: Player_CheckSevenForcesWeaponSelectInput+6   j  ; was: loc_19EB2
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
Player_StartSevenForceWeaponSelect:                    ; CODE XREF: Player_CheckSevenForcesWeaponSelectInput+16   j  ; was: loc_19EB6
                move.w  (WeaponSlotOffset).w,(WeaponSavedSlotOffset).w
                move.w  #$12,(WeaponStateIndex).w
                move.b  #$7F,(PlayerInputMask).w
                move.w  #0,(WeaponMenuSpawnXOffset).w
                move.w  #$FFEE,(WeaponMenuSpawnYOffset).w
                move.w  #4,4(a5)
                move.w  #$1C,$5C(a5)
                moveq   #1,d0
                rts
; End of function Player_CheckSevenForcesWeaponSelectInput
; State 4: damp movement until weapon selection closes
Player_SevenForceWeaponSelectState:                    ; DATA XREF: ROM:00019E1A   o  ; was: sub_19EE4
                cmpi.w  #$12,(WeaponStateIndex).w
                bmi.w   Player_ResetSevenForceBattleState
                bsr.w   Player_DampenSevenForceVelocity
                bra.w   Player_RenderSevenForceWeaponSelectFrame
; End of function Player_SevenForcesWeaponSelectState
; Toggle moving/fixed shooting mode and play its feedback sound
Player_ToggleSevenForceShootingMode:                   ; CODE XREF: Player_CheckSevenForcesWeaponSelectInput+E   j  ; was: sub_19EF6
                move.b  #$7F,(PlayerInputMask).w
                eori.w  #2,(ShootingMode).w
                move.b  #$A3,d0
                jsr     (Sound_QueueSFXRequest).l
                moveq   #0,d0
                rts
; End of function Player_ToggleSevenForcesShootingMode
; Enter directional-movement state 2
Player_EnterSevenForceState2:                          ; CODE XREF: Player_SevenForcesState0+3C   j  ; was: sub_19F10
                move.b  #$7F,(PlayerInputMask).w
                move.w  #2,4(a5)
                move.w  #4,$48(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$1C,$5C(a5)
                jmp     Player_AutoFlipDirection
; End of function Player_EnterSevenForcesState2
Player_SevenForceState2Return:                         ; CODE XREF: Player_SevenForcesState2+4   j  ; was: nullsub_52
                                        ; Player_SevenForcesState2+A   j
                rts
; End of function Player_SevenForcesState2Return

; Directional Seven Forces player movement state
Player_SevenForceState2:                               ; DATA XREF: ROM:00019E18   o  ; was: sub_19F36
                bsr.w   Player_CheckSevenForceWeaponSelectInput
                bne.s   Player_SevenForceState2Return
                bsr.w   Player_TryStartSevenForceDash
                bne.s   Player_SevenForceState2Return
                btst    #0,(CounterForceTriggerFlag).w
                bne.w   Player_StartSevenForceCounterForce
                btst    #4,$69(a5)
                beq.s   Player_SevenForceState2CheckDirectionalInput
                tst.w   (ShootingMode).w
                bne.w   Player_ResetSevenForceBattleState
Player_SevenForceState2CheckDirectionalInput:          ; CODE XREF: Player_SevenForcesState2+1C   j  ; was: loc_19F5C
                move.b  $69(a5),d0
                andi.b  #$F,d0
                beq.w   Player_ResetSevenForceBattleState
                bsr.w   Player_AdjustSevenForceDirectionalVelocity
                bra.w   Player_RenderSevenForceBattleFrame
; End of function Player_SevenForcesState2
; Try to start the Seven Forces player dash
Player_TryStartSevenForceDash:                         ; CODE XREF: Player_SevenForcesState0+16   p  ; was: sub_19F70
                                        ; Player_SevenForcesState2+6   p
                btst    #5,$6A(a5)
                beq.w   Player_TryStartSevenForceDashReturn
                move.w  #6,4(a5)
                move.b  #$73,(PlayerInputMask).w        ; 's'
                jsr     (Sys_ClearObjectBlocks16).l
                move.b  #$A6,d0
                jsr     (Sound_QueueSFXRequest).l
                move.b  #1,(PlayerAirDashUsedFlag).w
                move.w  #$C,$50(a5)
                clr.w   $12(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                btst    #2,$69(a5)
                bne.s   Player_StartSevenForceDashLeft
                btst    #3,$69(a5)
                bne.s   Player_StartSevenForceDashRight
                btst    #3,$E(a5)
                bne.s   Player_StartSevenForceDashRight
Player_StartSevenForceDashLeft:                        ; CODE XREF: Player_TryStartSevenForcesDash+44   j  ; was: loc_19FC6
                move.l  #$FFF88000,$48(a5)
                bclr    #3,$E(a5)
                bra.s   Player_StartSevenForceDashProjectile
; ---------------------------------------------------------------------------
Player_StartSevenForceDashRight:                       ; CODE XREF: Player_TryStartSevenForcesDash+4C   j  ; was: loc_19FD6
                                        ; Player_TryStartSevenForcesDash+54   j
                move.l  #$78000,$48(a5)
                bset    #3,$E(a5)
Player_StartSevenForceDashProjectile:                  ; CODE XREF: Player_TryStartSevenForcesDash+64   j  ; was: loc_19FE4
                tst.w   (PhoenixAttackStatus).w
                bne.s   Player_StartSevenForceDashAlternateProjectile
                btst    #7,(PlayerRestrictionFlags).w
                bne.s   Player_StartSevenForceDashAlternateProjectile
                jsr     (Player_SpawnProjectile).l
                move.l  #Player_PhoenixAndTeleportDashSpriteMapping,8(a5)
                move.w  #$78,(PhoenixAttackStatus).w    ; 'x'
                moveq   #1,d0
                rts
; ---------------------------------------------------------------------------
Player_StartSevenForceDashAlternateProjectile:         ; CODE XREF: Player_TryStartSevenForcesDash+78   j  ; was: loc_1A00A
                                        ; Player_TryStartSevenForcesDash+80   j
                move.l  #Player_PhoenixDashAttackSpriteMapping,8(a5)
                move.w  #$78,(PhoenixAttackStatus).w    ; 'x'
                moveq   #1,d0
Player_TryStartSevenForceDashReturn:                   ; CODE XREF: Player_TryStartSevenForcesDash+6   j  ; was: locret_1A01A
                rts
; End of function Player_TryStartSevenForcesDash
; State 6: update or finish the active dash
Player_SevenForceDashState6:                           ; DATA XREF: ROM:00019E1C   o  ; was: sub_1A01C
                tst.b   (PlayerDashStopFlag).w
                bne.s   Player_EndSevenForceDash
                subq.w  #1,$50(a5)
                bpl.s   Player_UpdateSevenForceDash
Player_EndSevenForceDash:                              ; CODE XREF: Player_SevenForcesDashState6+4   j  ; was: loc_1A028
                clr.w   (PlayerSpecialObjectSlot).w
                bclr    #0,(CounterForceTriggerFlag).w
                bclr    #6,$21(a5)
                bclr    #4,$23(a5)
                clr.w   (PlayerAirMoveUsedFlags).w
                bra.w   Player_ResetSevenForceBattleState
; ---------------------------------------------------------------------------
Player_UpdateSevenForceDash:                           ; CODE XREF: Player_SevenForcesDashState6+A   j  ; was: loc_1A046
                move.w  #1,(DashActiveWriteOnly).w
                bset    #6,$21(a5)
                bset    #4,$23(a5)
                bsr.s   Player_ApplySevenForceDashVelocity
                bsr.s   Player_ApplySevenForceDashVelocity
                bsr.s   Player_ApplySevenForceDashVelocity
                bset    #4,(PlayerActionStateFlags).w
                jmp     Effect_CreateDashTrail
; End of function Player_SevenForcesDashState6
; Apply one horizontal dash-velocity step
Player_ApplySevenForceDashVelocity:                    ; CODE XREF: Player_SevenForcesDashState6+3C   p  ; was: sub_1A06A
                                        ; Player_SevenForcesDashState6+3E   p
                move.l  $48(a5),d0
                add.l   d0,$10(a5)
                rts
; End of function Player_ApplySevenForcesDashVelocity
; Start Seven Forces Counter Force recoil with facing-dependent velocity
Player_StartSevenForceCounterForce:                    ; CODE XREF: Player_SevenForcesState0+22   j  ; was: sub_1A074
                                        ; Player_SevenForcesState2+12   j
                jsr     (Player_SpawnCounterForceEffect).l
                move.b  #$7F,(PlayerInputMask).w
                jsr     (Sys_ClearObjectBlocks16).l
                move.w  #8,4(a5)
                move.w  #$FFFC,$48(a5)
                move.w  #$A,$4A(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$1C,$5C(a5)
                move.l  #$FFFE0000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_StartSevenForceCounterForce_Return
                neg.l   $18(a5)
Player_StartSevenForceCounterForce_Return:             ; CODE XREF: Player_StartSevenForcesCounterForce+3E   j  ; was: locret_1A0B8
                rts
; End of function Player_StartSevenForcesCounterForce
; State 8: animate Counter Force until its timer expires
Player_SevenForceCounterForceState:                    ; DATA XREF: ROM:00019E1E   o  ; was: sub_1A0BA
                subq.w  #1,$4A(a5)
                bmi.w   Player_ResetSevenForceBattleState
                jmp     Player_UpdateCounterForceAnimation
; End of function Player_SevenForcesCounterForceState
; Enter the player defeat state with encounter-dependent knockback
Player_EnterSevenForceDefeatStateA:                    ; CODE XREF: Player_UpdateSevenForcesBattle+14   p  ; was: sub_1A0C8
                move.b  #$19,d0
                jsr     (Sound_QueueSFXRequest).l
                move.b  #$7F,(PlayerInputMask).w
                move.w  #$8000,(PlayerDefeatPhase).w
                jsr     (Sys_ClearObjectBlocks17).l
                move.w  #$A,4(a5)
                move.w  #$10,$48(a5)
                tst.w   (PlayerKnockbackXVel).w
                beq.s   Player_SetSevenForceDefeatVelocityByFacing
                bmi.s   Player_SetSevenForceDefeatVelocityLeft
                move.l  #$38000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Player_SetSevenForceDefeatVelocityLeft:                ; CODE XREF: Player_EnterSevenForcesDefeatStateA+2E   j  ; was: loc_1A102
                move.l  #$FFFC8000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Player_SetSevenForceDefeatVelocityByFacing:            ; CODE XREF: Player_EnterSevenForcesDefeatStateA+2C   j  ; was: loc_1A10C
                move.l  #$FFFC8000,$18(a5)
                btst    #3,$E(a5)
                bne.s   Player_SevenForceDefeatStateReturn
                neg.l   $18(a5)
Player_SevenForceDefeatStateReturn:                    ; CODE XREF: Player_EnterSevenForcesDefeatStateA+52   j  ; was: locret_1A120
                                        ; Player_SevenForcesDefeatStateA+1A   j
                rts
; End of function Player_EnterSevenForcesDefeatStateA
; State A: render and time the player defeat animation
Player_SevenForceDefeatStateA:                         ; DATA XREF: ROM:00019E20   o  ; was: sub_1A122
                movea.l #Player_KnockbackPrimarySpriteMapping,a1
                movea.l #Player_CommonMovementSecondarySpriteMapping,a2
                moveq   #$FFFFFFFF,d5
                moveq   #$FFFFFFFF,d6
                jsr     (Player_BuildSpritePieces).l
                subq.w  #1,$48(a5)
                bpl.s   Player_SevenForceDefeatStateReturn
                clr.w   (PlayerDefeatPhase).w
                move.w  #$CC00,2(a5)
                move.b  #$80,$21(a5)
                bra.w   Player_ResetSevenForceBattleState
; End of function Player_SevenForcesDefeatStateA
; Accelerate the player toward the current directional velocity target
Player_AdjustSevenForceDirectionalVelocity:            ; CODE XREF: Player_SevenForcesState2+32   p  ; was: sub_1A152
                lea     Player_SevenForceDirectionalVelocityAngles(pc),a0
                nop
                move.b  $69(a5),d0
                andi.w  #$F,d0
                move.b  (a0,d0.w),d0
                asl.w   #1,d0
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d0.w),d1
                move.w  (a0,d0.w),d2
                move.w  d1,d3
                move.w  d2,d4
                muls.w  #$E,d3
                muls.w  #$12,d4
                ext.l   d1
                ext.l   d2
                asl.l   #1,d1
                asl.l   #1,d2
                add.l   $1C(a5),d1
                bpl.s   Player_AdjustSevenForcePositiveVerticalVelocity
                tst.l   d3
                beq.s   Player_ClampSevenForceVerticalVelocity
                bpl.s   Player_DampenSevenForceVerticalVelocity
                cmp.l   d1,d3
                bpl.s   Player_ClampSevenForceVerticalVelocity
                bra.s   Player_StoreSevenForceVerticalVelocity
; ---------------------------------------------------------------------------
Player_DampenSevenForceVerticalVelocity:               ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+40   j  ; was: loc_1A19A
                                        ; Player_AdjustSevenForcesDirectionalVelocity+56   j
                move.l  $1C(a5),d0
                asr.l   #1,d0
                move.l  d0,$1C(a5)
                bra.s   Player_AdjustSevenForceHorizontalVelocity
; ---------------------------------------------------------------------------
Player_AdjustSevenForcePositiveVerticalVelocity:       ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+3A   j  ; was: loc_1A1A6
                tst.l   d3
                bmi.s   Player_DampenSevenForceVerticalVelocity
                cmp.l   d1,d3
                bpl.s   Player_StoreSevenForceVerticalVelocity
Player_ClampSevenForceVerticalVelocity:                ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+3E   j  ; was: loc_1A1AE
                                        ; Player_AdjustSevenForcesDirectionalVelocity+44   j
                move.l  d3,d1
Player_StoreSevenForceVerticalVelocity:                ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+46   j  ; was: loc_1A1B0
                                        ; Player_AdjustSevenForcesDirectionalVelocity+5A   j
                move.l  d1,$1C(a5)
Player_AdjustSevenForceHorizontalVelocity:             ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+52   j  ; was: loc_1A1B4
                add.l   $18(a5),d2
                bpl.s   Player_AdjustSevenForcePositiveHorizontalVelocity
                tst.l   d4
                beq.s   Player_ClampSevenForceHorizontalVelocity
                bpl.s   Player_DampenSevenForceHorizontalVelocity
                cmp.l   d2,d4
                bpl.s   Player_ClampSevenForceHorizontalVelocity
                bra.s   Player_StoreSevenForceHorizontalVelocity
; ---------------------------------------------------------------------------
Player_DampenSevenForceHorizontalVelocity:             ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+6C   j  ; was: loc_1A1C6
                                        ; Player_AdjustSevenForcesDirectionalVelocity+82   j
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Player_AdjustSevenForcePositiveHorizontalVelocity:     ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+66   j  ; was: loc_1A1D2
                tst.l   d4
                bmi.s   Player_DampenSevenForceHorizontalVelocity
                cmp.l   d2,d4
                bpl.s   Player_StoreSevenForceHorizontalVelocity
Player_ClampSevenForceHorizontalVelocity:              ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+6A   j  ; was: loc_1A1DA
                                        ; Player_AdjustSevenForcesDirectionalVelocity+70   j
                move.l  d4,d2
Player_StoreSevenForceHorizontalVelocity:              ; CODE XREF: Player_AdjustSevenForcesDirectionalVelocity+72   j  ; was: loc_1A1DC
                                        ; Player_AdjustSevenForcesDirectionalVelocity+86   j
                move.l  d2,$18(a5)
                rts
; End of function Player_AdjustSevenForcesDirectionalVelocity
; ---------------------------------------------------------------------------
Player_SevenForceDirectionalVelocityAngles:    dc.w    $C0, $4000, $80A0, $6000, $E0, $2000, 0, 0  ; was: word_1A1E2
                                        ; DATA XREF: Player_AdjustSevenForcesDirectionalVelocity   o

; Halve both player velocity components
Player_DampenSevenForceVelocity:                       ; CODE XREF: Player_SevenForcesState0+6   p  ; was: sub_1A1F2
                                        ; Player_SevenForcesWeaponSelectState+A   p
                move.l  $18(a5),d0
                asr.l   #1,d0
                move.l  d0,$18(a5)
                move.l  $1C(a5),d0
                asr.l   #1,d0
                move.l  d0,$1C(a5)
                rts
; End of function Player_DampenSevenForcesVelocity
; Render the ordinary Seven Forces battle frame with an optional weapon overlay
Player_RenderSevenForceBattleFrame:                    ; CODE XREF: Player_SevenForcesState0Render   j  ; was: sub_1A208
                                        ; Player_SevenForcesState2+36   j
                movea.l #Player_SpecialAttackSecondarySpriteMappingA,a2
                btst    #0,(FrameCounter+1).w
                bne.s   Player_RenderSevenForceBattleSelectOverlay
                movea.l #Player_SpecialAttackSecondarySpriteMappingB,a2
Player_RenderSevenForceBattleSelectOverlay:            ; CODE XREF: Player_RenderSevenForcesBattleFrame+C   j  ; was: loc_1A21C
                btst    #4,$69(a5)
                bne.s   Player_RenderSevenForceBattleWithWeapon
                jsr     (Player_UpdateHorizontalFacing).l
                movea.l #Player_CommonPrimarySpriteMapping,a1
                moveq   #$FFFFFFFF,d5
                moveq   #$FFFFFFFE,d6
                jmp     Player_BuildSpritePieces
; ---------------------------------------------------------------------------
Player_RenderSevenForceBattleWithWeapon:               ; CODE XREF: Player_RenderSevenForcesBattleFrame+1A   j  ; was: loc_1A23A
                lea     (Player_AlternateLayoutMuzzleOffsets0).l,a4
                moveq   #0,d5
                moveq   #$FFFFFFFF,d6
                lea     (Player_AlternateAnimationLayoutTable).l,a0
                jmp     Player_PrepareSpriteRendering_WithTables
; End of function Player_RenderSevenForcesBattleFrame
; Render the fixed player frame used during Seven Forces weapon selection
Player_RenderSevenForceWeaponSelectFrame:              ; CODE XREF: Player_SevenForcesWeaponSelectState+E   j  ; was: sub_1A250
                movea.l #Player_SpecialAttackSecondarySpriteMappingA,a2
                btst    #0,(FrameCounter+1).w
                bne.s   Player_RenderSevenForceWeaponSelectFrame_SelectSecondary
                movea.l #Player_SpecialAttackSecondarySpriteMappingB,a2
Player_RenderSevenForceWeaponSelectFrame_SelectSecondary:  ; CODE XREF: Player_RenderSevenForcesWeaponSelectFrame+C   j  ; was: loc_1A264
                movea.l #Player_CommonPrimarySpriteMapping,a1
                moveq   #$FFFFFFFF,d5
                moveq   #$FFFFFFFE,d6
                jmp     Player_BuildSpritePieces
; End of function Player_RenderSevenForcesWeaponSelectFrame
; Update the Seven Forces battle mode and force the display flag
Player_UpdateSevenForceBattleVisible:                  ; CODE XREF: Player_Update+50   j  ; was: sub_1A274
                bsr.w   Player_UpdateSevenForceBattle
                bset    #0,2(a5)
                rts
; End of function Player_UpdateSevenForcesBattleVisible
