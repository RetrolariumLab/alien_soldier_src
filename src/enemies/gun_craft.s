Stage11_GunCraftWaveController:                         ; was: sub_2E9FC
                move.w  4(a5),d0
                lea     Stage11_GunCraftWaveStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage11_GunCraftWaveController
; ---------------------------------------------------------------------------
Stage11_GunCraftWaveStateOffsets:   dc.w    Stage11_GunCraftWaveInitState-*  ; was: off_2EA08
                dc.w    Stage11_GunCraftWaveSpawnState-*
                dc.w    Stage11_GunCraftWaveMaintainPopulationState-*

; Initializes the Stage 11 gun-craft wave slots and spawn delay
Stage11_GunCraftWaveInitState:                          ; was: sub_2EA0E
                clr.w   (SharedScratchLong0).w
                clr.w   (SharedScratchLong0+2).w
                move.w  #$FFFF,(SharedScratchLong1).w
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Stage11_GunCraftWaveInitState
; Periodically spawns the initial Stage 11 gun craft
Stage11_GunCraftWaveSpawnState:                         ; was: sub_2EA28
                subq.w  #1,$48(a5)
                bne.s   Stage11_GunCraftWaveSpawnState_Return
                lea     (SharedScratchLong0).w,a4
                adda.w  $4C(a5),a4
                tst.w   (a4)
                bmi.s   Stage11_GunCraftWaveSpawnState_Finish
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage11_GunCraftWaveSpawnState_ResetDelay
                move.w  a0,(a4)
                bsr.s   Stage11_SpawnGunCraft
Stage11_GunCraftWaveSpawnState_ResetDelay:              ; was: loc_2EA46
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,$4C(a5)
Stage11_GunCraftWaveSpawnState_Return:                  ; was: locret_2EA50
                rts
; ---------------------------------------------------------------------------
Stage11_GunCraftWaveSpawnState_Finish:                  ; was: loc_2EA52
                addq.w  #2,4(a5)
                rts
; End of function Stage11_GunCraftWaveSpawnState
; Initializes a Stage 11 gun craft in a newly allocated object slot
Stage11_SpawnGunCraft:                                  ; was: sub_2EA58
                                        ; Stage11_GunCraftWaveMaintainPopulationState+20   p
                bsr.w   Enemy_InitGunCraft
                move.w  a5,$4E(a0)
                move.w  $4A(a5),d0
                move.w  Stage11_GunCraftSpawnXPositions(pc,d0.w),$10(a0)
                move.w  #$180,$14(a0)
                addq.w  #2,$4A(a5)
                andi.w  #7,$4A(a5)
                cmpi.w  #$120,$10(a0)
                bcs.s   Stage11_SpawnGunCraft_Return
                bset    #3,$E(a0)
Stage11_SpawnGunCraft_Return:                           ; was: locret_2EA88
                rts
; End of function Stage11_SpawnGunCraft
; ---------------------------------------------------------------------------
Stage11_GunCraftSpawnXPositions:    dc.w    $1A0, $A0, $1A0, $A0, $1A0, $A0, $1A0, $A0  ; was: word_2EA8A

; Replaces the first gun craft no longer using entity type $44C
Stage11_GunCraftWaveMaintainPopulationState:            ; was: sub_2EA9A
                lea     (SharedScratchLong0).w,a4
Stage11_GunCraftWaveMaintainPopulationState_NextSlot:   ; was: loc_2EA9E
                movea.w (a4),a0
                cmpi.w  #$44C,(a0)
                bne.s   Stage11_GunCraftWaveMaintainPopulationState_Spawn
                addq.w  #2,a4
                cmpi.w  #$FFFF,(a4)
                bne.s   Stage11_GunCraftWaveMaintainPopulationState_NextSlot
Stage11_GunCraftWaveMaintainPopulationState_Return:     ; was: locret_2EAAE
                rts
; ---------------------------------------------------------------------------
Stage11_GunCraftWaveMaintainPopulationState_Spawn:      ; was: loc_2EAB0
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage11_GunCraftWaveMaintainPopulationState_Return
                move.w  a0,(a4)
                bsr.s   Stage11_SpawnGunCraft
                rts
; End of function Stage11_GunCraftWaveMaintainPopulationState
; Initializes the Stage 11 gun craft sprite, collision, motion, and parent link
Enemy_InitGunCraft:                                     ; was: sub_2EABE
                move.w  #$44C,(a0)
                move.w  #$400,$E(a0)
                move.l  #Enemy_GunCraftSpriteMapping00,8(a0)
                move.w  #$CC00,2(a0)
                move.b  #$C0,$21(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #4,$24(a0)
                move.w  #$14,$26(a0)
                move.b  #$60,$20(a0)                    ; '`'
                rts
; End of function Enemy_InitGunCraft
; Updates a Stage 11 gun craft, its attached emitter, and its movement state
Enemy_GunCraftController:                               ; was: sub_2EB00
                tst.w   4(a5)
                beq.s   Enemy_GunCraftController_DispatchState
                tst.w   $24(a5)
                bmi.w   Enemy_DestroyGunCraftAndEmitter
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_DestroyGunCraftAndEmitter
                cmpi.w  #$1C,4(a5)
                bcc.s   Enemy_GunCraftController_PositionEmitter
                movea.w $4E(a5),a0
                cmpi.w  #$454,(a0)
                beq.s   Enemy_GunCraftController_PositionEmitter
                move.w  #$1C,4(a5)
Enemy_GunCraftController_PositionEmitter:               ; was: loc_2EB2E
                                        ; Enemy_GunCraftController+26   j
                jsr     (RandomNumber).l
                movea.w $5C(a5),a0
                move.w  $14(a5),$14(a0)
                addi.w  #$14,$14(a0)
                move.w  $10(a5),$10(a0)
                move.w  $48(a0),d0
                add.w   d0,$10(a0)
                btst    #3,$E(a5)
                bne.s   Enemy_GunCraftController_PositionEmitterLeft
                addi.w  #$14,$10(a0)
                bra.s   Enemy_GunCraftController_DispatchState
; ---------------------------------------------------------------------------
Enemy_GunCraftController_PositionEmitterLeft:           ; was: loc_2EB62
                addi.w  #-$14,$10(a0)
Enemy_GunCraftController_DispatchState:                 ; was: loc_2EB68
                                        ; Enemy_GunCraftController+60   j
                move.w  4(a5),d0
                lea     Enemy_GunCraftStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_GunCraftController
; ---------------------------------------------------------------------------
Enemy_GunCraftStateOffsets: dc.w    Enemy_GunCraftInitEmitterState-*  ; was: off_2EB74
                dc.w    Enemy_GunCraftRiseToEntryHeightState-*
                dc.w    Enemy_GunCraftRiseTowardPlayerState-*
                dc.w    Enemy_GunCraftBrakeVerticalMotionState-*
                dc.w    Enemy_GunCraftTrackPlayerHeightState-*
                dc.w    Enemy_GunCraftChoosePassState-*
                dc.w    Enemy_GunCraftPrepareVolleyState-*
                dc.w    Enemy_GunCraftFireVolleyState-*
                dc.w    Enemy_GunCraftBrakeOutwardMotionState-*
                dc.w    Enemy_GunCraftAccelerateInwardState-*
                dc.w    Enemy_GunCraftWaitForInnerEdgeState-*
                dc.w    Enemy_GunCraftBrakeInwardMotionState-*
                dc.w    Enemy_GunCraftAccelerateOutwardState-*
                dc.w    Enemy_GunCraftWaitForOuterEdgeState-*
                dc.w    Enemy_GunCraftBeginExitState-*
                dc.w    Enemy_GunCraftAccelerateUpwardState-*

; Allocates and attaches the gun craft's inert projectile-origin sprite
Enemy_GunCraftInitEmitterState:                         ; was: sub_2EB94
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_GunCraftInitEmitterState_Return
                move.w  #$10,(a0)
                move.w  #$CC00,2(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.l  #Enemy_GunCraftSpriteMapping03,8(a0)
                move.w  $E(a5),$E(a0)
                clr.w   $C(a0)
                move.w  a0,$5C(a5)
                move.w  #$FFFC,$1C(a5)
                addq.w  #2,4(a5)
Enemy_GunCraftInitEmitterState_Return:                  ; was: locret_2EBD0
                rts
; End of function Enemy_GunCraftInitEmitterState
; Continues rising until the gun craft enters the visible playfield
Enemy_GunCraftRiseToEntryHeightState:                   ; was: sub_2EBD2
                cmpi.w  #$160,$14(a5)
                bgt.s   Enemy_GunCraftRiseToEntryHeightState_Return
                addq.w  #2,4(a5)
Enemy_GunCraftRiseToEntryHeightState_Return:            ; was: locret_2EBDE
                rts
; End of function Enemy_GunCraftRiseToEntryHeightState
; Continues rising until reaching the player's vertical band
Enemy_GunCraftRiseTowardPlayerState:                    ; was: sub_2EBE0
                move.w  (PlayerCenterY).w,d0
                addi.w  #$40,d0                         ; '@'
                cmp.w   $14(a5),d0
                blt.s   Enemy_GunCraftRiseTowardPlayerState_Return
                addq.w  #2,4(a5)
Enemy_GunCraftRiseTowardPlayerState_Return:             ; was: locret_2EBF2
                rts
; End of function Enemy_GunCraftRiseTowardPlayerState
; Brakes upward velocity to zero
Enemy_GunCraftBrakeVerticalMotionState:                 ; was: sub_2EBF4
                addi.l  #$4000,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Enemy_GunCraftBrakeVerticalMotionState_Return
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
Enemy_GunCraftBrakeVerticalMotionState_Return:          ; was: locret_2EC12
                rts
; End of function Enemy_GunCraftBrakeVerticalMotionState
; Tracks player height for 64 frames and snapshots the target height
Enemy_GunCraftTrackPlayerHeightState:                   ; was: sub_2EC14
                move.w  (PlayerCenterY).w,d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                subq.w  #1,$48(a5)
                bne.s   Enemy_GunCraftTrackPlayerHeightState_Return
                addq.w  #2,4(a5)
                move.w  (PlayerCenterY).w,$4C(a5)
                move.w  #$10,$48(a5)
Enemy_GunCraftTrackPlayerHeightState_Return:            ; was: locret_2EC32
                rts
; End of function Enemy_GunCraftTrackPlayerHeightState
; Selects either a direct pass or a homing-projectile volley
Enemy_GunCraftChoosePassState:                          ; was: sub_2EC34
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                subq.w  #1,$48(a5)
                bne.s   Enemy_GunCraftChoosePassState_Return
                btst    #0,(RandomNumberState+1).w
                bne.s   Enemy_GunCraftChoosePassState_PrepareVolley
                btst    #1,(RandomNumberState+1).w
                bne.s   Enemy_GunCraftChoosePassState_PrepareVolley
                move.w  #$10,4(a5)
                move.l  #Enemy_GunCraftSpriteMapping01,8(a5)
                clr.w   $C(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftChoosePassState_SetNegativeSpeed
                move.w  #4,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_GunCraftChoosePassState_SetNegativeSpeed:         ; was: loc_2EC74
                move.w  #$FFFC,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_GunCraftChoosePassState_PrepareVolley:            ; was: loc_2EC7C
                                        ; Enemy_GunCraftChoosePassState+1C   j
                move.w  #$C,4(a5)
Enemy_GunCraftChoosePassState_Return:                   ; was: locret_2EC82
                rts
; End of function Enemy_GunCraftChoosePassState
; Prepares a sixteen-shot volley
Enemy_GunCraftPrepareVolleyState:                       ; was: sub_2EC84
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                move.w  #8,$48(a5)
                move.w  #$10,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_GunCraftPrepareVolleyState
; Fires a homing projectile every eight frames
Enemy_GunCraftFireVolleyState:                          ; was: sub_2EC9E
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                move.w  $48(a5),d0
                movea.w $5C(a5),a0
                bsr.w   Enemy_SetGunCraftEmitterXOffset
                subq.w  #1,$48(a5)
                bne.s   Enemy_GunCraftFireVolleyState_Return
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_GunCraftFireVolleyState_Finish
                movem.w a5,-(sp)
                movea.w $5C(a5),a5
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftFireVolleyState_UseUnflippedOrigin
                move.w  #$100,d6
                move.w  #$FFE8,d0
                bra.s   Enemy_GunCraftFireVolleyState_SpawnShot
; ---------------------------------------------------------------------------
Enemy_GunCraftFireVolleyState_UseUnflippedOrigin:       ; was: loc_2ECDA
                moveq   #0,d6
                move.w  #$18,d0
Enemy_GunCraftFireVolleyState_SpawnShot:                ; was: loc_2ECE0
                moveq   #0,d1
                move.w  #$8004,d2
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
                movem.w (sp)+,a5
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftFireVolleyState_SetPositiveShotSpeed
                move.w  #$FFFA,$50(a0)
                bra.s   Enemy_GunCraftFireVolleyState_AdvanceBurst
; ---------------------------------------------------------------------------
Enemy_GunCraftFireVolleyState_SetPositiveShotSpeed:     ; was: loc_2ED00
                move.w  #6,$50(a0)
Enemy_GunCraftFireVolleyState_AdvanceBurst:             ; was: loc_2ED06
                subq.w  #1,$4A(a5)
                beq.s   Enemy_GunCraftFireVolleyState_Finish
                move.w  #8,$48(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_GunCraftFireVolleyState_Finish:                   ; was: loc_2ED14
                                        ; Enemy_GunCraftFireVolleyState+6C   j
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #8,4(a5)
Enemy_GunCraftFireVolleyState_Return:                   ; was: locret_2ED20
                rts
; End of function Enemy_GunCraftFireVolleyState
; Offsets the attached emitter while the volley animates
Enemy_SetGunCraftEmitterXOffset:                        ; was: sub_2ED22
                btst    #3,$E(a5)
                beq.s   Enemy_SetGunCraftEmitterXOffset_UseNegativeOffsets
                lea     Enemy_GunCraftPositiveEmitterOffsets(pc),a1
                nop
                bra.s   Enemy_SetGunCraftEmitterXOffset_Store
; ---------------------------------------------------------------------------
Enemy_SetGunCraftEmitterXOffset_UseNegativeOffsets:     ; was: loc_2ED32
                lea     Enemy_GunCraftNegativeEmitterOffsets(pc),a1
                nop
Enemy_SetGunCraftEmitterXOffset_Store:                  ; was: loc_2ED38
                add.w   d0,d0
                move.w  (a1,d0.w),$48(a0)
                rts
; End of function Enemy_SetGunCraftEmitterXOffset
; ---------------------------------------------------------------------------
Enemy_GunCraftNegativeEmitterOffsets:   dc.w    0, $FFFF, $FFFE, $FFFD, $FFFC, $FFFD, $FFFE, $FFFF  ; was: word_2ED42
Enemy_GunCraftPositiveEmitterOffsets:   dc.w    0, 1, 2, 3, 4, 3, 2, 1  ; was: word_2ED52

; Brakes horizontal motion after moving away from the playfield
Enemy_GunCraftBrakeOutwardMotionState:                  ; was: sub_2ED62
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftBrakeOutwardMotionState_AddPositive
                addi.l  #-$4000,$18(a5)
                bra.s   Enemy_GunCraftBrakeOutwardMotionState_CheckStopped
; ---------------------------------------------------------------------------
Enemy_GunCraftBrakeOutwardMotionState_AddPositive:      ; was: loc_2ED7C
                addi.l  #$4000,$18(a5)
Enemy_GunCraftBrakeOutwardMotionState_CheckStopped:     ; was: loc_2ED84
                tst.l   $18(a5)
                bne.s   Enemy_GunCraftBrakeOutwardMotionState_Return
                move.l  #Enemy_GunCraftSpriteMapping02,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Enemy_GunCraftBrakeOutwardMotionState_Return:           ; was: locret_2ED9A
                rts
; End of function Enemy_GunCraftBrakeOutwardMotionState
; Accelerates toward the opposite side of the playfield
Enemy_GunCraftAccelerateInwardState:                    ; was: sub_2ED9C
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftAccelerateInwardState_AddPositive
                addi.l  #-$4000,$18(a5)
                cmpi.l  #$FFFA0000,$18(a5)
                bgt.s   Enemy_GunCraftAccelerateInwardState_Return
                bra.s   Enemy_GunCraftAccelerateInwardState_Finish
; ---------------------------------------------------------------------------
Enemy_GunCraftAccelerateInwardState_AddPositive:        ; was: loc_2EDC0
                addi.l  #$4000,$18(a5)
                cmpi.l  #$60000,$18(a5)
                blt.s   Enemy_GunCraftAccelerateInwardState_Return
Enemy_GunCraftAccelerateInwardState_Finish:             ; was: loc_2EDD2
                addq.w  #2,4(a5)
Enemy_GunCraftAccelerateInwardState_Return:             ; was: locret_2EDD6
                                        ; Enemy_GunCraftAccelerateInwardState+34   j
                rts
; End of function Enemy_GunCraftAccelerateInwardState
; Waits until the gun craft reaches its inner horizontal boundary
Enemy_GunCraftWaitForInnerEdgeState:                    ; was: sub_2EDD8
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftWaitForInnerEdgeState_CheckRightEdge
                cmpi.w  #$E0,$10(a5)
                bgt.s   Enemy_GunCraftWaitForInnerEdgeState_Return
                bra.s   Enemy_GunCraftWaitForInnerEdgeState_Finish
; ---------------------------------------------------------------------------
Enemy_GunCraftWaitForInnerEdgeState_CheckRightEdge:     ; was: loc_2EDF2
                cmpi.w  #$160,$10(a5)
                blt.s   Enemy_GunCraftWaitForInnerEdgeState_Return
Enemy_GunCraftWaitForInnerEdgeState_Finish:             ; was: loc_2EDFA
                move.l  #Enemy_GunCraftSpriteMapping00,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Enemy_GunCraftWaitForInnerEdgeState_Return:             ; was: locret_2EE0A
                                        ; Enemy_GunCraftWaitForInnerEdgeState+20   j
                rts
; End of function Enemy_GunCraftWaitForInnerEdgeState
; Brakes after crossing the playfield
Enemy_GunCraftBrakeInwardMotionState:                   ; was: sub_2EE0C
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftBrakeInwardMotionState_AddNegative
                addi.l  #$4000,$18(a5)
                bne.s   Enemy_GunCraftBrakeInwardMotionState_Return
                bra.s   Enemy_GunCraftBrakeInwardMotionState_Finish
; ---------------------------------------------------------------------------
Enemy_GunCraftBrakeInwardMotionState_AddNegative:       ; was: loc_2EE28
                addi.l  #-$4000,$18(a5)
                bne.s   Enemy_GunCraftBrakeInwardMotionState_Return
Enemy_GunCraftBrakeInwardMotionState_Finish:            ; was: loc_2EE32
                move.l  #Enemy_GunCraftSpriteMapping01,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Enemy_GunCraftBrakeInwardMotionState_Return:            ; was: locret_2EE42
                                        ; Enemy_GunCraftBrakeInwardMotionState+24   j
                rts
; End of function Enemy_GunCraftBrakeInwardMotionState
; Accelerates back toward the outer spawn edge
Enemy_GunCraftAccelerateOutwardState:                   ; was: sub_2EE44
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftAccelerateOutwardState_AddNegative
                addi.l  #$4000,$18(a5)
                cmpi.l  #$60000,$18(a5)
                blt.s   Enemy_GunCraftAccelerateOutwardState_Return
                bra.s   Enemy_GunCraftAccelerateOutwardState_Finish
; ---------------------------------------------------------------------------
Enemy_GunCraftAccelerateOutwardState_AddNegative:       ; was: loc_2EE68
                addi.l  #-$4000,$18(a5)
                cmpi.l  #$FFFA0000,$18(a5)
                bgt.s   Enemy_GunCraftAccelerateOutwardState_Return
Enemy_GunCraftAccelerateOutwardState_Finish:            ; was: loc_2EE7A
                addq.w  #2,4(a5)
Enemy_GunCraftAccelerateOutwardState_Return:            ; was: locret_2EE7E
                                        ; Enemy_GunCraftAccelerateOutwardState+34   j
                rts
; End of function Enemy_GunCraftAccelerateOutwardState
; Waits until the gun craft reaches its outer spawn edge
Enemy_GunCraftWaitForOuterEdgeState:                    ; was: sub_2EE80
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustGunCraftVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_GunCraftWaitForOuterEdgeState_CheckLeftEdge
                cmpi.w  #$1A0,$10(a5)
                blt.s   Enemy_GunCraftWaitForOuterEdgeState_Return
                bra.s   Enemy_GunCraftWaitForOuterEdgeState_Finish
; ---------------------------------------------------------------------------
Enemy_GunCraftWaitForOuterEdgeState_CheckLeftEdge:      ; was: loc_2EE9A
                cmpi.w  #$A0,$10(a5)
                bgt.s   Enemy_GunCraftWaitForOuterEdgeState_Return
Enemy_GunCraftWaitForOuterEdgeState_Finish:             ; was: loc_2EEA2
                clr.l   $18(a5)
                move.l  #Enemy_GunCraftSpriteMapping00,8(a5)
                clr.w   $C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #8,4(a5)
Enemy_GunCraftWaitForOuterEdgeState_Return:             ; was: locret_2EEBE
                                        ; Enemy_GunCraftWaitForOuterEdgeState+20   j
                rts
; End of function Enemy_GunCraftWaitForOuterEdgeState
; Sets bit 9 of the sprite word before the gun craft accelerates off the top
Enemy_GunCraftBeginExitState:                           ; was: sub_2EEC0
                ori.w   #$200,2(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_GunCraftBeginExitState
; Accelerates the gun craft upward until it is culled
Enemy_GunCraftAccelerateUpwardState:                    ; was: sub_2EECC
                addi.l  #-$4000,$1C(a5)
                rts
; End of function Enemy_GunCraftAccelerateUpwardState
; Adjusts vertical velocity toward a target height
Enemy_AdjustGunCraftVerticalVelocity:                   ; was: sub_2EED6
                                        ; Enemy_GunCraftChoosePassState+4   p
                sub.w   $14(a5),d0
                beq.w   Enemy_AdjustGunCraftVerticalVelocity_Return
                tst.w   d0
                bpl.s   Enemy_AdjustGunCraftVerticalVelocity_AccelerateDownward
                addi.l  #-$1000,$1C(a5)
                cmpi.l  #$FFFE0000,$1C(a5)
                bgt.s   Enemy_AdjustGunCraftVerticalVelocity_Return
                move.l  #$FFFE0000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_AdjustGunCraftVerticalVelocity_AccelerateDownward:  ; was: loc_2EEFE
                addi.l  #$1000,$1C(a5)
                cmpi.l  #$20000,$1C(a5)
                blt.s   Enemy_AdjustGunCraftVerticalVelocity_Return
                move.l  #$20000,$1C(a5)
Enemy_AdjustGunCraftVerticalVelocity_Return:            ; was: locret_2EF18
                                        ; Enemy_AdjustGunCraftVerticalVelocity+1C   j
                rts
; End of function Enemy_AdjustGunCraftVerticalVelocity
; Explodes and disables the gun craft and its attached emitter
Enemy_DestroyGunCraftAndEmitter:                        ; was: sub_2EF1A
                                        ; Enemy_GunCraftController+12   j
                jsr     (Effect_SpawnExplosionB).l
                move.w  #$1000,2(a5)
                movea.w $5C(a5),a0
                move.w  #$1000,2(a0)
                rts
; End of function Enemy_DestroyGunCraftAndEmitter
