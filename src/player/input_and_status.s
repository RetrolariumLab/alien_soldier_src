Input_ReadPlayerInput:                                  ; CODE XREF: Player_Update+1A   p  ; was: sub_16B04
                tst.w   (PlayerScriptStateOffset).w
                bne.s   Input_ReadPlayerInput_Return
                move.b  (ControllerHeldState).w,$69(a5)
                move.b  (ControllerPressedState).w,$6A(a5)
                move.b  (PlayerInputMask).w,d0
                and.b   d0,$69(a5)
                and.b   d0,$6A(a5)
Input_ReadPlayerInput_Return:                           ; CODE XREF: Input_ReadPlayerInput+4   j  ; was: locret_16B22
                rts
; End of function Input_ReadPlayerInput
; Detects a second B-button press within the Counter Force input window
Player_UpdateCounterForceInput:                         ; CODE XREF: Player_Update:Player_Update_RunState   p  ; was: sub_16B24
                                        ; sub_19DAE:Player_UpdateSevenForceBattleDispatchState   p
                subq.w  #1,(CounterForceInputTimer).w
                bmi.s   Player_UpdateCounterForceInput_CheckFirstPress
                btst    #4,$6A(a5)
                beq.s   Player_UpdateCounterForceInput_StoreHealthDelta
                bset    #0,(CounterForceTriggerFlag).w
                bra.s   Player_UpdateCounterForceInput_StoreHealthDelta
; ---------------------------------------------------------------------------
Player_UpdateCounterForceInput_CheckFirstPress:         ; CODE XREF: Player_UpdateCounterForceInput+4   j  ; was: loc_16B3A
                move.w  #$FFFF,(CounterForceInputTimer).w
                btst    #4,$6A(a5)
                beq.s   Player_UpdateCounterForceInput_StoreHealthDelta
                move.w  #$10,(CounterForceInputTimer).w
; Every input path reaches this health-delta store, even without a B press
Player_UpdateCounterForceInput_StoreHealthDelta:        ; CODE XREF: Player_UpdateCounterForceInput+C   j  ; was: loc_16B4E
                                        ; Player_UpdateCounterForceInput+14   j
                move.w  (PlayerHealth).w,d0
                sub.w   (PlayerMaxHealth).w,d0
                move.w  d0,(PhoenixAttackStatus).w
                rts
; End of function Player_UpdateCounterForceInput
; Refreshes the player sprite priority bit from the global priority setting
Player_UpdateSpritePriorityBit:                         ; CODE XREF: Player_Update:Player_UpdateCoreAttributes   p  ; was: sub_16B5C
                                        ; sub_19DAE:Player_UpdateSevenForceBattleFinalizeFrame   p
                btst    #5,(PlayerActionStateFlags).w
                bne.s   Player_UpdateSpritePriorityBit_Return
                bclr    #7,$E(a5)
                move.w  (GlobalSpritePriorityBit).w,d0
                or.w    d0,$E(a5)
Player_UpdateSpritePriorityBit_Return:                  ; CODE XREF: Player_UpdateSpritePriorityBit+6   j  ; was: locret_16B72
                rts
; End of function Player_UpdateSpritePriorityBit
; Selects hitbox bounds and mirrors the vertical pair when the sprite is flipped
Player_SetHitbox:                                       ; CODE XREF: Player_Update+AE   p  ; was: sub_16B74
                                        ; Player_UpdateSevenForceBattle+48   p
                move.w  $5C(a5),d0
                beq.s   Player_SetHitbox_Return
                clr.w   $5C(a5)
                subq.w  #4,d0
                move.l  Player_HitboxBoundsTable(pc,d0.w),d0
                btst    #4,$E(a5)
                beq.s   Player_SetHitbox_StoreBounds
                move.l  d0,(HitboxMirrorScratchA).w
                move.l  d0,(HitboxMirrorScratchB).w
                move.b  (HitboxMirrorScratchB).w,d1
                neg.b   d1
                move.b  d1,(HitboxMirrorScratchA+1).w
                move.b  (HitboxMirrorScratchB+1).w,d1
                neg.b   d1
                move.b  d1,(HitboxMirrorScratchA).w
                move.l  (HitboxMirrorScratchA).w,d0
; Stores the selected or mirrored hitbox boundary bytes
Player_SetHitbox_StoreBounds:                           ; CODE XREF: Player_SetHitbox+16   j  ; was: loc_16BAC
                move.l  d0,$28(a5)
Player_SetHitbox_Return:                                ; CODE XREF: Player_SetHitbox+4   j  ; was: locret_16BB0
                rts
; End of function Player_SetHitbox
; ---------------------------------------------------------------------------
Player_HitboxBoundsTable:   dc.l    $E01EF808, $FC1EF808, $E018F808, $E01CF808, $FC1CF808, $E016F808, $E012F808  ; was: dword_16BB2
                                        ; DATA XREF: Player_SetHitbox+C   r

; Calculates player center position from hitbox bounds
Player_CalculateCenterPosition:                         ; CODE XREF: Player_Update+B6   j  ; was: sub_16BCE
                                        ; Player_UpdateSevenForceBattle+52   j
                move.b  $2A(a5),d0
                ext.w   d0
                move.b  $2B(a5),d1
                ext.w   d1
                add.w   d1,d0
                asr.w   #1,d0
                add.w   $10(a5),d0
                move.w  d0,(PlayerCenterX).w
                move.b  $28(a5),d0
                ext.w   d0
                move.b  $29(a5),d1
                ext.w   d1
                add.w   d1,d0
                asr.w   #1,d0
                add.w   $14(a5),d0
                move.w  d0,(PlayerCenterY).w
                rts
; End of function Player_CalculateCenterPosition
; Manages player invulnerability and flash timer
Player_UpdateInvulnerabilityTimer:                      ; CODE XREF: Player_Update+AA   p  ; was: sub_16C00
                                        ; Player_UpdateSevenForceBattle+42   p
                bset    #7,2(a5)
                subq.w  #1,$5E(a5)
                bpl.s   Player_UpdateInvulnerabilityTimer_Active
                move.w  #$FFFF,$5E(a5)
                btst    #6,$21(a5)
                bne.s   Player_UpdateInvulnerabilityTimer_Return
                bclr    #4,$23(a5)
                rts
; ---------------------------------------------------------------------------
Player_UpdateInvulnerabilityTimer_Active:               ; CODE XREF: Player_UpdateInvulnerabilityTimer+A   j  ; was: loc_16C22
                bset    #4,$23(a5)
                btst    #5,(PlayerActionStateFlags).w
                bne.s   Player_UpdateInvulnerabilityTimer_Return
                btst    #0,(FrameCounter+1).w
                beq.s   Player_UpdateInvulnerabilityTimer_Return
                bclr    #7,2(a5)
Player_UpdateInvulnerabilityTimer_Return:               ; CODE XREF: Player_UpdateInvulnerabilityTimer+18   j  ; was: locret_16C3E
                                        ; Player_UpdateInvulnerabilityTimer+2E   j
                rts
; End of function Player_UpdateInvulnerabilityTimer
; Updates player horizontal facing bit from input
Player_UpdateHorizontalFacing:                          ; CODE XREF: Player_HandleSpecialAttack+B0   p  ; was: sub_16C40
                                        ; Player_RenderSpecialMoveRecovery+1E   p
                btst    #2,$69(a5)
                beq.s   Player_UpdateHorizontalFacing_CheckRight
                bclr    #3,$E(a5)
                rts
; ---------------------------------------------------------------------------
Player_UpdateHorizontalFacing_CheckRight:               ; CODE XREF: Player_UpdateHorizontalFacing+6   j  ; was: loc_16C50
                btst    #3,$69(a5)
                beq.w   Player_UpdateHorizontalFacing_Return
                bset    #3,$E(a5)
Player_UpdateHorizontalFacing_Return:                   ; CODE XREF: Player_UpdateHorizontalFacing+16   j  ; was: locret_16C60
                rts
; End of function Player_UpdateHorizontalFacing
; Finds free object slot for dash trail effect
Effect_FindDashTrailSlot:                               ; CODE XREF: Effect_CreateDashTrail:Effect_CreateDashTrail_AllocateObjects   p  ; was: sub_16C62
                                        ; Effect_CreateDashTrail+7A   p
                movea.w #(SharedEffectObjectPool-M68K_RAM),a0
                moveq   #$B,d7
                jmp     Sys_FindFreeObjectSlot
; End of function Effect_FindDashTrailSlot
; Loads player sprite palette based on state
Gfx_LoadPlayerPaletteData:                              ; CODE XREF: Player_Update+54   p  ; was: sub_16C6E
                                        ; sub_19DAE   p
                tst.w   (PhoenixAttackStatus).w
                bne.s   Gfx_LoadPlayerPaletteData_SelectVariantA
                move.w  (FrameCounter).w,d0
                btst    #4,d0
                bne.s   Gfx_LoadPlayerPaletteData_SelectVariantA
                andi.w  #3,d0
                bne.s   Gfx_LoadPlayerPaletteData_SelectVariantA
                lea     Player_PaletteVariantC(pc),a0
                nop
                bra.s   Gfx_CopyPlayerPaletteWords
; ---------------------------------------------------------------------------
Gfx_LoadPlayerPaletteData_SelectVariantA:               ; CODE XREF: Gfx_LoadPlayerPaletteData+4   j  ; was: loc_16C8C
                                        ; Gfx_LoadPlayerPaletteData+E   j
                lea     Player_PaletteVariantA(pc),a0
                nop
                tst.w   (ShootingMode).w
                beq.s   Gfx_CopyPlayerPaletteWords
                lea     Player_PaletteVariantB(pc),a0
                nop
; Copies 8 bytes of player palette data to two RAM locations
Gfx_CopyPlayerPaletteWords:                             ; CODE XREF: Gfx_LoadPlayerPaletteData+1C   j  ; was: loc_16C9E
                                        ; Gfx_LoadPlayerPaletteData+28   j
                movea.w #(PaletteActiveColor41Hi-M68K_RAM),a1
                movea.w #(PaletteShadowPair41-M68K_RAM),a2
                move.l  (a0),(a1)+
                move.l  (a0)+,(a2)+
                move.l  (a0),(a1)+
                move.l  (a0)+,(a2)+
                rts
; End of function Gfx_LoadPlayerPaletteData
; ---------------------------------------------------------------------------
; The conditions selecting these palettes are known; their gameplay meanings are not
Player_PaletteVariantA: dc.w    $22, $46, $488, $8CC    ; was: word_16CB0
                                        ; DATA XREF: Gfx_LoadPlayerPaletteData:Gfx_LoadPlayerPaletteData_SelectVariantA   o
Player_PaletteVariantB: dc.w    $220, $442, $888, $CCC  ; was: word_16CB8
                                        ; DATA XREF: Gfx_LoadPlayerPaletteData+2A   o
Player_PaletteVariantC: dc.w    $C88, $EAA, $ECC, $EEE  ; was: word_16CC0
                                        ; DATA XREF: Gfx_LoadPlayerPaletteData+16   o
