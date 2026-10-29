Stage11_FishWaveController:                             ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_2E9FC
                move.w  4(a5),d0
                lea     Stage11_FishWaveStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage11_FishWaveController
; ---------------------------------------------------------------------------
Stage11_FishWaveStateOffsets:   dc.w    Stage11_FishWaveInitState-*  ; DATA XREF: Stage11_FishWaveController+4   o  ; was: off_2EA08
                dc.w    Stage11_FishWaveSpawnState-*
                dc.w    Stage11_FishWaveMaintainPopulationState-*

; Initializes the Stage 11 fish-wave slots and spawn delay
Stage11_FishWaveInitState:                              ; DATA XREF: ROM:Stage11_FishWaveStateOffsets   o  ; was: sub_2EA0E
                clr.w   (SharedScratchLong0).w
                clr.w   (SharedScratchLong0+2).w
                move.w  #$FFFF,(SharedScratchLong1).w
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Stage11_FishWaveInitState
; Periodically spawns the initial Stage 11 fish
Stage11_FishWaveSpawnState:                             ; DATA XREF: ROM:0002EA0A   o  ; was: sub_2EA28
                subq.w  #1,$48(a5)
                bne.s   Stage11_FishWaveSpawnState_Return
                lea     (SharedScratchLong0).w,a4
                adda.w  $4C(a5),a4
                tst.w   (a4)
                bmi.s   Stage11_FishWaveSpawnState_Finish
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage11_FishWaveSpawnState_ResetDelay
                move.w  a0,(a4)
                bsr.s   Stage11_SpawnFish
Stage11_FishWaveSpawnState_ResetDelay:                  ; CODE XREF: Stage11_FishWaveSpawnState+18   j  ; was: loc_2EA46
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,$4C(a5)
Stage11_FishWaveSpawnState_Return:                      ; CODE XREF: Stage11_FishWaveSpawnState+4   j  ; was: locret_2EA50
                rts
; ---------------------------------------------------------------------------
Stage11_FishWaveSpawnState_Finish:                      ; CODE XREF: Stage11_FishWaveSpawnState+10   j  ; was: loc_2EA52
                addq.w  #2,4(a5)
                rts
; End of function Stage11_FishWaveSpawnState
; Initializes a Stage 11 fish in a newly allocated object slot
Stage11_SpawnFish:                                      ; CODE XREF: Stage11_FishWaveSpawnState+1C   p  ; was: sub_2EA58
                                        ; Stage11_FishWaveMaintainPopulationState+20   p
                bsr.w   Enemy_InitStage11Fish
                move.w  a5,$4E(a0)
                move.w  $4A(a5),d0
                move.w  Stage11_FishSpawnXPositions(pc,d0.w),$10(a0)
                move.w  #$180,$14(a0)
                addq.w  #2,$4A(a5)
                andi.w  #7,$4A(a5)
                cmpi.w  #$120,$10(a0)
                bcs.s   Stage11_SpawnFish_Return
                bset    #3,$E(a0)
Stage11_SpawnFish_Return:                               ; CODE XREF: Stage11_SpawnFish+28   j  ; was: locret_2EA88
                rts
; End of function Stage11_SpawnFish
; ---------------------------------------------------------------------------
Stage11_FishSpawnXPositions:    dc.w    $1A0, $A0, $1A0, $A0, $1A0, $A0, $1A0, $A0  ; was: word_2EA8A
                                        ; DATA XREF: Stage11_SpawnFish+C   r

; Replaces the first fish no longer using entity type $44C
Stage11_FishWaveMaintainPopulationState:                ; DATA XREF: ROM:0002EA0C   o  ; was: sub_2EA9A
                lea     (SharedScratchLong0).w,a4
Stage11_FishWaveMaintainPopulationState_NextSlot:       ; CODE XREF: Stage11_FishWaveMaintainPopulationState+12   j  ; was: loc_2EA9E
                movea.w (a4),a0
                cmpi.w  #$44C,(a0)
                bne.s   Stage11_FishWaveMaintainPopulationState_Spawn
                addq.w  #2,a4
                cmpi.w  #$FFFF,(a4)
                bne.s   Stage11_FishWaveMaintainPopulationState_NextSlot
Stage11_FishWaveMaintainPopulationState_Return:         ; CODE XREF: Stage11_FishWaveMaintainPopulationState+1C   j  ; was: locret_2EAAE
                rts
; ---------------------------------------------------------------------------
Stage11_FishWaveMaintainPopulationState_Spawn:          ; CODE XREF: Stage11_FishWaveMaintainPopulationState+A   j  ; was: loc_2EAB0
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage11_FishWaveMaintainPopulationState_Return
                move.w  a0,(a4)
                bsr.s   Stage11_SpawnFish
                rts
; End of function Stage11_FishWaveMaintainPopulationState
; Initializes the Stage 11 fish sprite, collision, motion, and parent link
Enemy_InitStage11Fish:                                  ; CODE XREF: Stage11_SpawnFish   p  ; was: sub_2EABE
                move.w  #$44C,(a0)
                move.w  #$400,$E(a0)
                move.l  #Enemy_Stage11FishSpriteMapping00,8(a0)
                move.w  #$CC00,2(a0)
                move.b  #$C0,$21(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #4,$24(a0)
                move.w  #$14,$26(a0)
                move.b  #$60,$20(a0)                    ; '`'
                rts
; End of function Enemy_InitStage11Fish
; Updates a Stage 11 fish, its attached emitter, and its movement state
Enemy_Stage11FishController:                            ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_2EB00
                tst.w   4(a5)
                beq.s   Enemy_Stage11FishController_DispatchState
                tst.w   $24(a5)
                bmi.w   Enemy_DestroyStage11FishAndEmitter
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_DestroyStage11FishAndEmitter
                cmpi.w  #$1C,4(a5)
                bcc.s   Enemy_Stage11FishController_PositionEmitter
                movea.w $4E(a5),a0
                cmpi.w  #$454,(a0)
                beq.s   Enemy_Stage11FishController_PositionEmitter
                move.w  #$1C,4(a5)
Enemy_Stage11FishController_PositionEmitter:            ; CODE XREF: Enemy_Stage11FishController+1C   j  ; was: loc_2EB2E
                                        ; Enemy_Stage11FishController+26   j
                jsr     (RandomNumber).l
                movea.w $5C(a5),a0
                move.w  $14(a5),$14(a0)
                addi.w  #$14,$14(a0)
                move.w  $10(a5),$10(a0)
                move.w  $48(a0),d0
                add.w   d0,$10(a0)
                btst    #3,$E(a5)
                bne.s   Enemy_Stage11FishController_PositionEmitterLeft
                addi.w  #$14,$10(a0)
                bra.s   Enemy_Stage11FishController_DispatchState
; ---------------------------------------------------------------------------
Enemy_Stage11FishController_PositionEmitterLeft:        ; CODE XREF: Enemy_Stage11FishController+58   j  ; was: loc_2EB62
                addi.w  #-$14,$10(a0)
Enemy_Stage11FishController_DispatchState:              ; CODE XREF: Enemy_Stage11FishController+4   j  ; was: loc_2EB68
                                        ; Enemy_Stage11FishController+60   j
                move.w  4(a5),d0
                lea     Enemy_Stage11FishStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_Stage11FishController
; ---------------------------------------------------------------------------
Enemy_Stage11FishStateOffsets:  dc.w    Enemy_Stage11FishInitEmitterState-*  ; DATA XREF: Enemy_Stage11FishController+6C   o  ; was: off_2EB74
                dc.w    Enemy_Stage11FishRiseToEntryHeightState-*
                dc.w    Enemy_Stage11FishRiseTowardPlayerState-*
                dc.w    Enemy_Stage11FishBrakeVerticalMotionState-*
                dc.w    Enemy_Stage11FishTrackPlayerHeightState-*
                dc.w    Enemy_Stage11FishChoosePassState-*
                dc.w    Enemy_Stage11FishPrepareVolleyState-*
                dc.w    Enemy_Stage11FishFireVolleyState-*
                dc.w    Enemy_Stage11FishBrakeOutwardMotionState-*
                dc.w    Enemy_Stage11FishAccelerateInwardState-*
                dc.w    Enemy_Stage11FishWaitForInnerEdgeState-*
                dc.w    Enemy_Stage11FishBrakeInwardMotionState-*
                dc.w    Enemy_Stage11FishAccelerateOutwardState-*
                dc.w    Enemy_Stage11FishWaitForOuterEdgeState-*
                dc.w    Enemy_Stage11FishBeginExitState-*
                dc.w    Enemy_Stage11FishAccelerateUpwardState-*

; Allocates and attaches the fish's inert projectile-origin sprite
Enemy_Stage11FishInitEmitterState:                      ; DATA XREF: ROM:Enemy_Stage11FishStateOffsets   o  ; was: sub_2EB94
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_Stage11FishInitEmitterState_Return
                move.w  #$10,(a0)
                move.w  #$CC00,2(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.l  #Enemy_Stage11FishSpriteMapping03,8(a0)
                move.w  $E(a5),$E(a0)
                clr.w   $C(a0)
                move.w  a0,$5C(a5)
                move.w  #$FFFC,$1C(a5)
                addq.w  #2,4(a5)
Enemy_Stage11FishInitEmitterState_Return:               ; CODE XREF: Enemy_Stage11FishInitEmitterState+6   j  ; was: locret_2EBD0
                rts
; End of function Enemy_Stage11FishInitEmitterState
; Continues rising until the fish enters the visible playfield
Enemy_Stage11FishRiseToEntryHeightState:                ; DATA XREF: ROM:0002EB76   o  ; was: sub_2EBD2
                cmpi.w  #$160,$14(a5)
                bgt.s   Enemy_Stage11FishRiseToEntryHeightState_Return
                addq.w  #2,4(a5)
Enemy_Stage11FishRiseToEntryHeightState_Return:         ; CODE XREF: Enemy_Stage11FishRiseToEntryHeightState+6   j  ; was: locret_2EBDE
                rts
; End of function Enemy_Stage11FishRiseToEntryHeightState
; Continues rising until reaching the player's vertical band
Enemy_Stage11FishRiseTowardPlayerState:                 ; DATA XREF: ROM:0002EB78   o  ; was: sub_2EBE0
                move.w  (PlayerCenterY).w,d0
                addi.w  #$40,d0                         ; '@'
                cmp.w   $14(a5),d0
                blt.s   Enemy_Stage11FishRiseTowardPlayerState_Return
                addq.w  #2,4(a5)
Enemy_Stage11FishRiseTowardPlayerState_Return:          ; CODE XREF: Enemy_Stage11FishRiseTowardPlayerState+C   j  ; was: locret_2EBF2
                rts
; End of function Enemy_Stage11FishRiseTowardPlayerState
; Brakes upward velocity to zero
Enemy_Stage11FishBrakeVerticalMotionState:              ; DATA XREF: ROM:0002EB7A   o  ; was: sub_2EBF4
                addi.l  #$4000,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Enemy_Stage11FishBrakeVerticalMotionState_Return
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
Enemy_Stage11FishBrakeVerticalMotionState_Return:       ; CODE XREF: Enemy_Stage11FishBrakeVerticalMotionState+E   j  ; was: locret_2EC12
                rts
; End of function Enemy_Stage11FishBrakeVerticalMotionState
; Tracks player height for 64 frames and snapshots the target height
Enemy_Stage11FishTrackPlayerHeightState:                ; DATA XREF: ROM:0002EB7C   o  ; was: sub_2EC14
                move.w  (PlayerCenterY).w,d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage11FishTrackPlayerHeightState_Return
                addq.w  #2,4(a5)
                move.w  (PlayerCenterY).w,$4C(a5)
                move.w  #$10,$48(a5)
Enemy_Stage11FishTrackPlayerHeightState_Return:         ; CODE XREF: Enemy_Stage11FishTrackPlayerHeightState+C   j  ; was: locret_2EC32
                rts
; End of function Enemy_Stage11FishTrackPlayerHeightState
; Selects either a direct pass or a homing-projectile volley
Enemy_Stage11FishChoosePassState:                       ; DATA XREF: ROM:0002EB7E   o  ; was: sub_2EC34
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage11FishChoosePassState_Return
                btst    #0,(RandomNumberState+1).w
                bne.s   Enemy_Stage11FishChoosePassState_PrepareVolley
                btst    #1,(RandomNumberState+1).w
                bne.s   Enemy_Stage11FishChoosePassState_PrepareVolley
                move.w  #$10,4(a5)
                move.l  #Enemy_Stage11FishSpriteMapping01,8(a5)
                clr.w   $C(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishChoosePassState_SetNegativeSpeed
                move.w  #4,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_Stage11FishChoosePassState_SetNegativeSpeed:      ; CODE XREF: Enemy_Stage11FishChoosePassState+36   j  ; was: loc_2EC74
                move.w  #$FFFC,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_Stage11FishChoosePassState_PrepareVolley:         ; CODE XREF: Enemy_Stage11FishChoosePassState+14   j  ; was: loc_2EC7C
                                        ; Enemy_Stage11FishChoosePassState+1C   j
                move.w  #$C,4(a5)
Enemy_Stage11FishChoosePassState_Return:                ; CODE XREF: Enemy_Stage11FishChoosePassState+C   j  ; was: locret_2EC82
                rts
; End of function Enemy_Stage11FishChoosePassState
; Prepares a sixteen-shot volley
Enemy_Stage11FishPrepareVolleyState:                    ; DATA XREF: ROM:0002EB80   o  ; was: sub_2EC84
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                move.w  #8,$48(a5)
                move.w  #$10,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage11FishPrepareVolleyState
; Fires a homing projectile every eight frames
Enemy_Stage11FishFireVolleyState:                       ; DATA XREF: ROM:0002EB82   o  ; was: sub_2EC9E
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                move.w  $48(a5),d0
                movea.w $5C(a5),a0
                bsr.w   Enemy_SetStage11FishEmitterXOffset
                subq.w  #1,$48(a5)
                bne.s   Enemy_Stage11FishFireVolleyState_Return
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_Stage11FishFireVolleyState_Finish
                movem.w a5,-(sp)
                movea.w $5C(a5),a5
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishFireVolleyState_UseUnflippedOrigin
                move.w  #$100,d6
                move.w  #$FFE8,d0
                bra.s   Enemy_Stage11FishFireVolleyState_SpawnShot
; ---------------------------------------------------------------------------
Enemy_Stage11FishFireVolleyState_UseUnflippedOrigin:    ; CODE XREF: Enemy_Stage11FishFireVolleyState+30   j  ; was: loc_2ECDA
                moveq   #0,d6
                move.w  #$18,d0
Enemy_Stage11FishFireVolleyState_SpawnShot:             ; CODE XREF: Enemy_Stage11FishFireVolleyState+3A   j  ; was: loc_2ECE0
                moveq   #0,d1
                move.w  #$8004,d2
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
                movem.w (sp)+,a5
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishFireVolleyState_SetPositiveShotSpeed
                move.w  #$FFFA,$50(a0)
                bra.s   Enemy_Stage11FishFireVolleyState_AdvanceBurst
; ---------------------------------------------------------------------------
Enemy_Stage11FishFireVolleyState_SetPositiveShotSpeed:  ; CODE XREF: Enemy_Stage11FishFireVolleyState+58   j  ; was: loc_2ED00
                move.w  #6,$50(a0)
Enemy_Stage11FishFireVolleyState_AdvanceBurst:          ; CODE XREF: Enemy_Stage11FishFireVolleyState+60   j  ; was: loc_2ED06
                subq.w  #1,$4A(a5)
                beq.s   Enemy_Stage11FishFireVolleyState_Finish
                move.w  #8,$48(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_Stage11FishFireVolleyState_Finish:                ; CODE XREF: Enemy_Stage11FishFireVolleyState+20   j  ; was: loc_2ED14
                                        ; Enemy_Stage11FishFireVolleyState+6C   j
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #8,4(a5)
Enemy_Stage11FishFireVolleyState_Return:                ; CODE XREF: Enemy_Stage11FishFireVolleyState+18   j  ; was: locret_2ED20
                rts
; End of function Enemy_Stage11FishFireVolleyState
; Offsets the attached emitter while the volley animates
Enemy_SetStage11FishEmitterXOffset:                     ; CODE XREF: Enemy_Stage11FishFireVolleyState+10   p  ; was: sub_2ED22
                btst    #3,$E(a5)
                beq.s   Enemy_SetStage11FishEmitterXOffset_UseNegativeOffsets
                lea     Enemy_Stage11FishPositiveEmitterOffsets(pc),a1
                nop
                bra.s   Enemy_SetStage11FishEmitterXOffset_Store
; ---------------------------------------------------------------------------
Enemy_SetStage11FishEmitterXOffset_UseNegativeOffsets:  ; CODE XREF: Enemy_SetStage11FishEmitterXOffset+6   j  ; was: loc_2ED32
                lea     Enemy_Stage11FishNegativeEmitterOffsets(pc),a1
                nop
Enemy_SetStage11FishEmitterXOffset_Store:               ; CODE XREF: Enemy_SetStage11FishEmitterXOffset+E   j  ; was: loc_2ED38
                add.w   d0,d0
                move.w  (a1,d0.w),$48(a0)
                rts
; End of function Enemy_SetStage11FishEmitterXOffset
; ---------------------------------------------------------------------------
Enemy_Stage11FishNegativeEmitterOffsets:    dc.w    0, $FFFF, $FFFE, $FFFD, $FFFC, $FFFD, $FFFE, $FFFF  ; was: word_2ED42
                                        ; DATA XREF: Enemy_SetStage11FishEmitterXOffset:Enemy_SetStage11FishEmitterXOffset_UseNegativeOffsets   o
Enemy_Stage11FishPositiveEmitterOffsets:    dc.w    0, 1, 2, 3, 4, 3, 2, 1  ; was: word_2ED52
                                        ; DATA XREF: Enemy_SetStage11FishEmitterXOffset+8   o

; Brakes horizontal motion after moving away from the playfield
Enemy_Stage11FishBrakeOutwardMotionState:               ; DATA XREF: ROM:0002EB84   o  ; was: sub_2ED62
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishBrakeOutwardMotionState_AddPositive
                addi.l  #-$4000,$18(a5)
                bra.s   Enemy_Stage11FishBrakeOutwardMotionState_CheckStopped
; ---------------------------------------------------------------------------
Enemy_Stage11FishBrakeOutwardMotionState_AddPositive:   ; CODE XREF: Enemy_Stage11FishBrakeOutwardMotionState+E   j  ; was: loc_2ED7C
                addi.l  #$4000,$18(a5)
Enemy_Stage11FishBrakeOutwardMotionState_CheckStopped:  ; CODE XREF: Enemy_Stage11FishBrakeOutwardMotionState+18   j  ; was: loc_2ED84
                tst.l   $18(a5)
                bne.s   Enemy_Stage11FishBrakeOutwardMotionState_Return
                move.l  #Enemy_Stage11FishSpriteMapping02,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Enemy_Stage11FishBrakeOutwardMotionState_Return:        ; CODE XREF: Enemy_Stage11FishBrakeOutwardMotionState+26   j  ; was: locret_2ED9A
                rts
; End of function Enemy_Stage11FishBrakeOutwardMotionState
; Accelerates toward the opposite side of the playfield
Enemy_Stage11FishAccelerateInwardState:                 ; DATA XREF: ROM:0002EB86   o  ; was: sub_2ED9C
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishAccelerateInwardState_AddPositive
                addi.l  #-$4000,$18(a5)
                cmpi.l  #$FFFA0000,$18(a5)
                bgt.s   Enemy_Stage11FishAccelerateInwardState_Return
                bra.s   Enemy_Stage11FishAccelerateInwardState_Finish
; ---------------------------------------------------------------------------
Enemy_Stage11FishAccelerateInwardState_AddPositive:     ; CODE XREF: Enemy_Stage11FishAccelerateInwardState+E   j  ; was: loc_2EDC0
                addi.l  #$4000,$18(a5)
                cmpi.l  #$60000,$18(a5)
                blt.s   Enemy_Stage11FishAccelerateInwardState_Return
Enemy_Stage11FishAccelerateInwardState_Finish:          ; CODE XREF: Enemy_Stage11FishAccelerateInwardState+22   j  ; was: loc_2EDD2
                addq.w  #2,4(a5)
Enemy_Stage11FishAccelerateInwardState_Return:          ; CODE XREF: Enemy_Stage11FishAccelerateInwardState+20   j  ; was: locret_2EDD6
                                        ; Enemy_Stage11FishAccelerateInwardState+34   j
                rts
; End of function Enemy_Stage11FishAccelerateInwardState
; Waits until the fish reaches its inner horizontal boundary
Enemy_Stage11FishWaitForInnerEdgeState:                 ; DATA XREF: ROM:0002EB88   o  ; was: sub_2EDD8
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishWaitForInnerEdgeState_CheckRightEdge
                cmpi.w  #$E0,$10(a5)
                bgt.s   Enemy_Stage11FishWaitForInnerEdgeState_Return
                bra.s   Enemy_Stage11FishWaitForInnerEdgeState_Finish
; ---------------------------------------------------------------------------
Enemy_Stage11FishWaitForInnerEdgeState_CheckRightEdge:  ; CODE XREF: Enemy_Stage11FishWaitForInnerEdgeState+E   j  ; was: loc_2EDF2
                cmpi.w  #$160,$10(a5)
                blt.s   Enemy_Stage11FishWaitForInnerEdgeState_Return
Enemy_Stage11FishWaitForInnerEdgeState_Finish:          ; CODE XREF: Enemy_Stage11FishWaitForInnerEdgeState+18   j  ; was: loc_2EDFA
                move.l  #Enemy_Stage11FishSpriteMapping00,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Enemy_Stage11FishWaitForInnerEdgeState_Return:          ; CODE XREF: Enemy_Stage11FishWaitForInnerEdgeState+16   j  ; was: locret_2EE0A
                                        ; Enemy_Stage11FishWaitForInnerEdgeState+20   j
                rts
; End of function Enemy_Stage11FishWaitForInnerEdgeState
; Brakes after crossing the playfield
Enemy_Stage11FishBrakeInwardMotionState:                ; DATA XREF: ROM:0002EB8A   o  ; was: sub_2EE0C
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishBrakeInwardMotionState_AddNegative
                addi.l  #$4000,$18(a5)
                bne.s   Enemy_Stage11FishBrakeInwardMotionState_Return
                bra.s   Enemy_Stage11FishBrakeInwardMotionState_Finish
; ---------------------------------------------------------------------------
Enemy_Stage11FishBrakeInwardMotionState_AddNegative:    ; CODE XREF: Enemy_Stage11FishBrakeInwardMotionState+E   j  ; was: loc_2EE28
                addi.l  #-$4000,$18(a5)
                bne.s   Enemy_Stage11FishBrakeInwardMotionState_Return
Enemy_Stage11FishBrakeInwardMotionState_Finish:         ; CODE XREF: Enemy_Stage11FishBrakeInwardMotionState+1A   j  ; was: loc_2EE32
                move.l  #Enemy_Stage11FishSpriteMapping01,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Enemy_Stage11FishBrakeInwardMotionState_Return:         ; CODE XREF: Enemy_Stage11FishBrakeInwardMotionState+18   j  ; was: locret_2EE42
                                        ; Enemy_Stage11FishBrakeInwardMotionState+24   j
                rts
; End of function Enemy_Stage11FishBrakeInwardMotionState
; Accelerates back toward the outer spawn edge
Enemy_Stage11FishAccelerateOutwardState:                ; DATA XREF: ROM:0002EB8C   o  ; was: sub_2EE44
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishAccelerateOutwardState_AddNegative
                addi.l  #$4000,$18(a5)
                cmpi.l  #$60000,$18(a5)
                blt.s   Enemy_Stage11FishAccelerateOutwardState_Return
                bra.s   Enemy_Stage11FishAccelerateOutwardState_Finish
; ---------------------------------------------------------------------------
Enemy_Stage11FishAccelerateOutwardState_AddNegative:    ; CODE XREF: Enemy_Stage11FishAccelerateOutwardState+E   j  ; was: loc_2EE68
                addi.l  #-$4000,$18(a5)
                cmpi.l  #$FFFA0000,$18(a5)
                bgt.s   Enemy_Stage11FishAccelerateOutwardState_Return
Enemy_Stage11FishAccelerateOutwardState_Finish:         ; CODE XREF: Enemy_Stage11FishAccelerateOutwardState+22   j  ; was: loc_2EE7A
                addq.w  #2,4(a5)
Enemy_Stage11FishAccelerateOutwardState_Return:         ; CODE XREF: Enemy_Stage11FishAccelerateOutwardState+20   j  ; was: locret_2EE7E
                                        ; Enemy_Stage11FishAccelerateOutwardState+34   j
                rts
; End of function Enemy_Stage11FishAccelerateOutwardState
; Waits until the fish reaches its outer spawn edge
Enemy_Stage11FishWaitForOuterEdgeState:                 ; DATA XREF: ROM:0002EB8E   o  ; was: sub_2EE80
                move.w  $4C(a5),d0
                bsr.w   Enemy_AdjustStage11FishVerticalVelocity
                btst    #3,$E(a5)
                beq.s   Enemy_Stage11FishWaitForOuterEdgeState_CheckLeftEdge
                cmpi.w  #$1A0,$10(a5)
                blt.s   Enemy_Stage11FishWaitForOuterEdgeState_Return
                bra.s   Enemy_Stage11FishWaitForOuterEdgeState_Finish
; ---------------------------------------------------------------------------
Enemy_Stage11FishWaitForOuterEdgeState_CheckLeftEdge:   ; CODE XREF: Enemy_Stage11FishWaitForOuterEdgeState+E   j  ; was: loc_2EE9A
                cmpi.w  #$A0,$10(a5)
                bgt.s   Enemy_Stage11FishWaitForOuterEdgeState_Return
Enemy_Stage11FishWaitForOuterEdgeState_Finish:          ; CODE XREF: Enemy_Stage11FishWaitForOuterEdgeState+18   j  ; was: loc_2EEA2
                clr.l   $18(a5)
                move.l  #Enemy_Stage11FishSpriteMapping00,8(a5)
                clr.w   $C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #8,4(a5)
Enemy_Stage11FishWaitForOuterEdgeState_Return:          ; CODE XREF: Enemy_Stage11FishWaitForOuterEdgeState+16   j  ; was: locret_2EEBE
                                        ; Enemy_Stage11FishWaitForOuterEdgeState+20   j
                rts
; End of function Enemy_Stage11FishWaitForOuterEdgeState
; Sets bit 9 of the sprite word before the fish accelerates off the top
Enemy_Stage11FishBeginExitState:                        ; DATA XREF: ROM:0002EB90   o  ; was: sub_2EEC0
                ori.w   #$200,2(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_Stage11FishBeginExitState
; Accelerates the fish upward until it is culled
Enemy_Stage11FishAccelerateUpwardState:                 ; DATA XREF: ROM:0002EB92   o  ; was: sub_2EECC
                addi.l  #-$4000,$1C(a5)
                rts
; End of function Enemy_Stage11FishAccelerateUpwardState
; Adjusts vertical velocity toward a target height
Enemy_AdjustStage11FishVerticalVelocity:                ; CODE XREF: Enemy_Stage11FishTrackPlayerHeightState+4   p  ; was: sub_2EED6
                                        ; Enemy_Stage11FishChoosePassState+4   p
                sub.w   $14(a5),d0
                beq.w   Enemy_AdjustStage11FishVerticalVelocity_Return
                tst.w   d0
                bpl.s   Enemy_AdjustStage11FishVerticalVelocity_AccelerateDownward
                addi.l  #-$1000,$1C(a5)
                cmpi.l  #$FFFE0000,$1C(a5)
                bgt.s   Enemy_AdjustStage11FishVerticalVelocity_Return
                move.l  #$FFFE0000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_AdjustStage11FishVerticalVelocity_AccelerateDownward:  ; CODE XREF: Enemy_AdjustStage11FishVerticalVelocity+A   j  ; was: loc_2EEFE
                addi.l  #$1000,$1C(a5)
                cmpi.l  #$20000,$1C(a5)
                blt.s   Enemy_AdjustStage11FishVerticalVelocity_Return
                move.l  #$20000,$1C(a5)
Enemy_AdjustStage11FishVerticalVelocity_Return:         ; CODE XREF: Enemy_AdjustStage11FishVerticalVelocity+4   j  ; was: locret_2EF18
                                        ; Enemy_AdjustStage11FishVerticalVelocity+1C   j
                rts
; End of function Enemy_AdjustStage11FishVerticalVelocity
; Explodes and disables the fish and its attached emitter
Enemy_DestroyStage11FishAndEmitter:                     ; CODE XREF: Enemy_Stage11FishController+A   j  ; was: sub_2EF1A
                                        ; Enemy_Stage11FishController+12   j
                jsr     (Effect_SpawnExplosionB).l
                move.w  #$1000,2(a5)
                movea.w $5C(a5),a0
                move.w  #$1000,2(a0)
                rts
; End of function Enemy_DestroyStage11FishAndEmitter
