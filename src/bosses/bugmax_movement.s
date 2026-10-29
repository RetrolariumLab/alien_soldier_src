; Steer the opening controller horizontally toward its stage-relative target
Boss_BugmaxSteerOpeningControllerToHorizontalTarget:    ; CODE XREF: Boss_BugmaxEmitOpeningHitFragmentsAndSteer+20   j  ; was: sub_4DA22
                move.w  #$168,d0
                sub.w   (SecondaryCameraXPos).w,d0
                sub.w   $10(a5),d0
                beq.s   Boss_BugmaxOpeningHorizontalSteeringReturn
                tst.w   d0
                bmi.s   Boss_BugmaxHandleNegativeOpeningTargetDelta
                addi.l  #$4000,$18(a5)
                btst    #7,$18(a5)
                beq.s   Boss_BugmaxClampOpeningVelocityAfterPositiveTarget
                addi.l  #$4000,$18(a5)
Boss_BugmaxClampOpeningVelocityAfterPositiveTarget:     ; CODE XREF: Boss_BugmaxSteerOpeningControllerToHorizontalTarget+20   j  ; was: loc_4DA4C
                cmpi.l  #$FFFD8000,$18(a5)
                bgt.s   Boss_BugmaxOpeningHorizontalSteeringReturn
                move.l  #$FFFD8000,$18(a5)
                bra.s   Boss_BugmaxOpeningHorizontalSteeringReturn
; ---------------------------------------------------------------------------
Boss_BugmaxHandleNegativeOpeningTargetDelta:            ; CODE XREF: Boss_BugmaxSteerOpeningControllerToHorizontalTarget+10   j  ; was: loc_4DA60
                addi.l  #-$4000,$18(a5)
                btst    #7,$18(a5)
                bne.s   Boss_BugmaxClampOpeningNegativeVelocity
                addi.l  #-$4000,$18(a5)
Boss_BugmaxClampOpeningNegativeVelocity:                ; CODE XREF: Boss_BugmaxSteerOpeningControllerToHorizontalTarget+4C   j  ; was: loc_4DA78
                cmpi.l  #$FFFD8000,$18(a5)
                bgt.s   Boss_BugmaxOpeningHorizontalSteeringReturn
                move.l  #$FFFD8000,$18(a5)
Boss_BugmaxOpeningHorizontalSteeringReturn:             ; CODE XREF: Boss_BugmaxSteerOpeningControllerToHorizontalTarget+C   j  ; was: locret_4DA8A
                                        ; Boss_BugmaxSteerOpeningControllerToHorizontalTarget+32   j
                rts
; End of function Boss_BugmaxSteerOpeningControllerToHorizontalTarget
; Clamp eight opening object records to their per-record horizontal bounds
Boss_BugmaxClampOpeningObjectHorizontalPositions:       ; CODE XREF: Boss_BugmaxWaitAfterJitterAndStartBossMessage   p  ; was: sub_4DA8C
                                        ; Boss_BugmaxWaitForOpeningTransition   p
                move.w  #$168,d2
                sub.w   (SecondaryCameraXPos).w,d2
                lea     Boss_BugmaxOpeningObjectHorizontalBounds(pc),a2
                nop
                moveq   #0,d6
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
                move.w  #7,d7
Boss_BugmaxClampOpeningObjectPositionLoop:              ; CODE XREF: Boss_BugmaxClampOpeningObjectHorizontalPositions+40   j  ; was: loc_4DAA4
                move.w  d2,d0
                move.w  d2,d1
                sub.w   (a2,d6.w),d0
                add.w   2(a2,d6.w),d1
                cmp.w   $10(a0),d0
                bcs.s   Boss_BugmaxCheckOpeningObjectMaximumX
                move.w  d0,$10(a0)
                bra.s   Boss_BugmaxAdvanceOpeningObjectClampLoop
; ---------------------------------------------------------------------------
Boss_BugmaxCheckOpeningObjectMaximumX:                  ; CODE XREF: Boss_BugmaxClampOpeningObjectHorizontalPositions+28   j  ; was: loc_4DABC
                cmp.w   $10(a0),d1
                bhi.s   Boss_BugmaxAdvanceOpeningObjectClampLoop
                move.w  d1,$10(a0)
; Advance to the next opening object and pair of horizontal bounds
Boss_BugmaxAdvanceOpeningObjectClampLoop:               ; CODE XREF: Boss_BugmaxClampOpeningObjectHorizontalPositions+2E   j  ; was: loc_4DAC6
                                        ; Boss_BugmaxClampOpeningObjectHorizontalPositions+34   j
                lea     $60(a0),a0
                addq.w  #4,d6
                dbf     d7,Boss_BugmaxClampOpeningObjectPositionLoop
                rts
; End of function Boss_BugmaxClampOpeningObjectHorizontalPositions
; ---------------------------------------------------------------------------
Boss_BugmaxOpeningObjectHorizontalBounds:   dc.w    8, 8, $C, 8, $C, $C, $10, $10, $C, $10, $C, $C, 8, 8  ; was: word_4DAD2
                                        ; DATA XREF: Boss_BugmaxClampOpeningObjectHorizontalPositions+8   o

; Convert signed wave displacement into a palette offset for color word 3E2E
Gfx_BugmaxApplyWavePaletteOffset:                       ; CODE XREF: Boss_BugmaxUpdatePerspectiveAndLinkedGeometry:Boss_BugmaxUpdatePerspectiveParametersAndGeometry   p  ; was: sub_4DAEE
                move.w  (SharedScratchLong0).w,d0
                beq.s   Gfx_BugmaxWavePaletteOffsetReturn
                tst.w   d0
                bpl.s   Gfx_BugmaxSelectPositiveWavePaletteOffsets
                neg.w   d0
                lea     Gfx_BugmaxNegativeWavePaletteOffsets(pc),a0
                nop
                bra.s   Gfx_BugmaxClampWavePaletteMagnitude
; ---------------------------------------------------------------------------
Gfx_BugmaxSelectPositiveWavePaletteOffsets:             ; CODE XREF: Gfx_BugmaxApplyWavePaletteOffset+8   j  ; was: loc_4DB02
                lea     Gfx_BugmaxPositiveWavePaletteOffsets(pc),a0
                nop
Gfx_BugmaxClampWavePaletteMagnitude:                    ; CODE XREF: Gfx_BugmaxApplyWavePaletteOffset+12   j  ; was: loc_4DB08
                cmpi.w  #$40,d0                         ; '@'
                bcs.s   Gfx_BugmaxApplyIndexedWavePaletteOffset
                move.w  #$40,d0                         ; '@'
Gfx_BugmaxApplyIndexedWavePaletteOffset:                ; CODE XREF: Gfx_BugmaxApplyWavePaletteOffset+1E   j  ; was: loc_4DB12
                lsr.w   #3,d0
                add.w   d0,d0
                move.w  (a0,d0.w),d0
                move.w  #$E000,d7
                lea     (PaletteFade_BugmaxWaveEntryOffsets).l,a4
                jmp     (Gfx_AdjustPaletteEntryList).l
; ---------------------------------------------------------------------------
Gfx_BugmaxWavePaletteOffsetReturn:                      ; CODE XREF: Gfx_BugmaxApplyWavePaletteOffset+4   j  ; was: locret_4DB2A
                rts
; End of function Gfx_BugmaxApplyWavePaletteOffset
; ---------------------------------------------------------------------------
Gfx_BugmaxPositiveWavePaletteOffsets:   dc.w    $FFF8, $FFFA, $FFFA, $FFFC, $FFFC, $FFFE, $FFFE, 0, 0  ; was: word_4DB2C
                                        ; DATA XREF: Gfx_BugmaxApplyWavePaletteOffset:Gfx_BugmaxSelectPositiveWavePaletteOffsets   o
Gfx_BugmaxNegativeWavePaletteOffsets:   dc.w    8, 6, 6, 4, 4, 2, 2, 0, 0  ; was: word_4DB3E
                                        ; DATA XREF: Gfx_BugmaxApplyWavePaletteOffset+C   o

; Alternate the central linked part between two mapping records every four frames
Boss_BugmaxToggleCentralPartMapping:                    ; CODE XREF: Boss_BugmaxUpdatePerspectiveAndLinkedGeometry+292   p  ; was: sub_4DB50
                move.w  (FrameCounter).w,d7
                andi.w  #3,d7
                bne.s   Boss_BugmaxCentralPartMappingToggleReturn
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                cmpi.l  #Boss_BugmaxCentralPartToggleFrame00,8(a0)
                beq.s   Boss_BugmaxSelectAlternateCentralPartMapping
                move.l  #Boss_BugmaxCentralPartToggleFrame00,8(a0)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxSelectAlternateCentralPartMapping:           ; CODE XREF: Boss_BugmaxToggleCentralPartMapping+16   j  ; was: loc_4DB72
                move.l  #Boss_BugmaxCentralPartToggleFrame01,8(a0)
Boss_BugmaxCentralPartMappingToggleReturn:              ; CODE XREF: Boss_BugmaxToggleCentralPartMapping+8   j  ; was: locret_4DB7A
                rts
; End of function Boss_BugmaxToggleCentralPartMapping
; Project one linked record's radius and angle from an anchor position
Math_CalculatePolarPosition:                            ; CODE XREF: Boss_BugmaxUpdateLinkedChainGeometry+28   p  ; was: sub_4DB7C
                                        ; Boss_BugmaxUpdateLinkedChainGeometry+46   p
                move.w  $50(a0),d2
                move.w  $4C(a0),d0
                add.w   $4E(a0),d0
Math_BugmaxCalculatePolarOffset:                        ; CODE XREF: Boss_BugmaxUpdateReverseLinkedChainGeometry+3A   p  ; was: loc_4DB88
                                        ; Boss_BugmaxUpdateReverseLinkedChainGeometry+6A   p
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a2
                move.w  Math_QuarterSineTable-Math_SineTable(a2,d0.w),d1
                move.w  (a2,d0.w),d0
                muls.w  d2,d0
                muls.w  d2,d1
                add.l   d3,d0
                add.l   d4,d1
                rts
; End of function Math_CalculatePolarPosition
; Update battle wave displacement and horizontal/vertical steering
Boss_BugmaxUpdateBattleMovement:                        ; CODE XREF: Boss_BugmaxSettleChainBendAtBattleBaseline   p  ; was: sub_4DBA4
                                        ; Boss_BugmaxSelectBattlePattern+8   p
                bsr.s   Boss_BugmaxUpdateWaveDisplacement
                bsr.w   Boss_BugmaxUpdateHorizontalSteering
                bsr.w   Boss_BugmaxUpdateVerticalBandSteering
                rts
; End of function Boss_BugmaxUpdateBattleMovement
; Integrate the wave phase and scale its displacement by the signed amplitude
Boss_BugmaxUpdateWaveDisplacement:                      ; CODE XREF: Boss_BugmaxUpdateFinalWaveDescentAndCompleteEncounter   p  ; was: sub_4DBB0
                                        ; Boss_BugmaxUpdateBattleMovement   p
                move.l  (SharedScratchLong2).w,d0
                add.l   d0,(SharedScratchLong1).w
                move.w  (SharedScratchLong1).w,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d0.w),d0
                tst.w   d0
                bmi.s   Boss_BugmaxScaleWaveByNegativeAmplitude
                muls.w  (SharedScratchLong3).w,d0
                bra.s   Boss_BugmaxStoreWaveDisplacement
; ---------------------------------------------------------------------------
Boss_BugmaxScaleWaveByNegativeAmplitude:                ; CODE XREF: Boss_BugmaxUpdateWaveDisplacement+1C   j  ; was: loc_4DBD4
                muls.w  (SharedScratchLong3+2).w,d0
Boss_BugmaxStoreWaveDisplacement:                       ; CODE XREF: Boss_BugmaxUpdateWaveDisplacement+22   j  ; was: loc_4DBD8
                move.l  d0,(SharedScratchLong0).w
                rts
; End of function Boss_BugmaxUpdateWaveDisplacement
; Update bounded horizontal steering toward the explicit target or player X
Boss_BugmaxUpdateHorizontalSteering:                    ; CODE XREF: Boss_BugmaxApproachSpreadVolleyTarget+4   p  ; was: sub_4DBDE
                                        ; Boss_BugmaxSpawnSpreadProjectile+4   p
                move.w  (FrameCounter).w,d0
                andi.w  #$1FE,d0
                move.l  (a0,d0.w),d6
                ext.l   d6
                bpl.s   Boss_BugmaxCalculateHorizontalSteeringStep
                neg.l   d6
Boss_BugmaxCalculateHorizontalSteeringStep:             ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+E   j  ; was: loc_4DBF0
                asr.l   #2,d6
                move.w  (PrimaryCameraXPosition).w,d0
                cmpi.w  #$410,d0
                bcc.s   Boss_BugmaxSelectRightScrollHorizontalBounds
                cmpi.w  #$5E0,$58(a5)
                bgt.s   Boss_BugmaxSteerLeftFromUpperHorizontalBound
                cmpi.w  #$440,$58(a5)
                blt.s   Boss_BugmaxSteerRightFromLowerHorizontalBound
                bra.s   Boss_BugmaxHandleInBoundsHorizontalMode
; ---------------------------------------------------------------------------
Boss_BugmaxSelectRightScrollHorizontalBounds:           ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+1C   j  ; was: loc_4DC0E
                cmpi.w  #$620,$58(a5)
                bgt.s   Boss_BugmaxSteerLeftFromUpperHorizontalBound
                cmpi.w  #$480,$58(a5)
                blt.s   Boss_BugmaxSteerRightFromLowerHorizontalBound
                bra.s   Boss_BugmaxHandleInBoundsHorizontalMode
; ---------------------------------------------------------------------------
Boss_BugmaxSteerLeftFromUpperHorizontalBound:           ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+24   j  ; was: loc_4DC20
                                        ; Boss_BugmaxUpdateHorizontalSteering+36   j
                move.l  #$2000,d6
                bra.w   Boss_BugmaxSelectNegativeHorizontalAcceleration
; ---------------------------------------------------------------------------
Boss_BugmaxSteerRightFromLowerHorizontalBound:          ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+2C   j  ; was: loc_4DC2A
                                        ; Boss_BugmaxUpdateHorizontalSteering+3E   j
                move.l  #$2000,d6
                bra.w   Boss_BugmaxSelectPositiveHorizontalAcceleration
; ---------------------------------------------------------------------------
Boss_BugmaxHandleInBoundsHorizontalMode:                ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+2E   j  ; was: loc_4DC34
                                        ; Boss_BugmaxUpdateHorizontalSteering+40   j
                btst    #0,(SharedScratchLong6+1).w
                bne.s   Boss_BugmaxSelectHorizontalSteeringTarget
                btst    #1,(SharedScratchLong6+1).w
                beq.s   Boss_BugmaxGateHorizontalTargetUpdate
                tst.l   $18(a5)
                beq.w   Boss_BugmaxHorizontalSteeringReturn
                move.l  #$1000,d6
                btst    #7,$18(a5)
                bne.w   Boss_BugmaxSelectPositiveHorizontalAcceleration
                bra.w   Boss_BugmaxSelectNegativeHorizontalAcceleration
; ---------------------------------------------------------------------------
Boss_BugmaxGateHorizontalTargetUpdate:                  ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+64   j  ; was: loc_4DC60
                move.w  (FrameCounter).w,d7
                andi.w  #$7F,d7
                bne.s   Boss_BugmaxApplyHorizontalAcceleration
Boss_BugmaxSelectHorizontalSteeringTarget:              ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+5C   j  ; was: loc_4DC6A
                move.w  (SharedScratchLong9).w,d0
                beq.s   Boss_BugmaxUsePlayerHorizontalTarget
                sub.w   (PrimaryCameraXPosition).w,d0
                bra.s   Boss_BugmaxMeasureHorizontalTargetDelta
; ---------------------------------------------------------------------------
Boss_BugmaxUsePlayerHorizontalTarget:                   ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+90   j  ; was: loc_4DC76
                move.w  (PlayerCenterX).w,d0
Boss_BugmaxMeasureHorizontalTargetDelta:                ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+96   j  ; was: loc_4DC7A
                sub.w   $10(a5),d0
                move.w  d0,d1
                bpl.s   Boss_BugmaxUseAbsoluteHorizontalTargetDelta
                neg.w   d1
Boss_BugmaxUseAbsoluteHorizontalTargetDelta:            ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+A2   j  ; was: loc_4DC84
                cmpi.w  #$10,d1
                bcc.s   Boss_BugmaxSelectHorizontalAccelerationDirection
                bset    #0,(SharedScratchLong7).w
Boss_BugmaxSelectHorizontalAccelerationDirection:       ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+AA   j  ; was: loc_4DC90
                tst.w   d0
                beq.s   Boss_BugmaxHorizontalSteeringReturn
                tst.w   d0
                bmi.s   Boss_BugmaxSelectNegativeHorizontalAcceleration
Boss_BugmaxSelectPositiveHorizontalAcceleration:        ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+52   j  ; was: loc_4DC98
                                        ; Boss_BugmaxUpdateHorizontalSteering+7A   j
                clr.b   (SharedScratchLong6).w
                bra.s   Boss_BugmaxApplyHorizontalAcceleration
; ---------------------------------------------------------------------------
Boss_BugmaxSelectNegativeHorizontalAcceleration:        ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+48   j  ; was: loc_4DC9E
                                        ; Boss_BugmaxUpdateHorizontalSteering+7E   j
                move.b  #1,(SharedScratchLong6).w
Boss_BugmaxApplyHorizontalAcceleration:                 ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+8A   j  ; was: loc_4DCA4
                                        ; Boss_BugmaxUpdateHorizontalSteering+BE   j
                tst.b   (SharedScratchLong6).w
                bne.s   Boss_BugmaxApplyNegativeHorizontalAcceleration
                add.l   d6,$18(a5)
                bra.s   Boss_BugmaxClampPositiveHorizontalVelocity
; ---------------------------------------------------------------------------
Boss_BugmaxApplyNegativeHorizontalAcceleration:         ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+CA   j  ; was: loc_4DCB0
                sub.l   d6,$18(a5)
Boss_BugmaxClampPositiveHorizontalVelocity:             ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+D0   j  ; was: loc_4DCB4
                cmpi.l  #$20000,$18(a5)
                blt.s   Boss_BugmaxClampNegativeHorizontalVelocity
                move.l  #$20000,$18(a5)
                bra.s   Boss_BugmaxHorizontalSteeringReturn
; ---------------------------------------------------------------------------
Boss_BugmaxClampNegativeHorizontalVelocity:             ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+DE   j  ; was: loc_4DCC8
                cmpi.l  #$FFFE0000,$18(a5)
                bgt.s   Boss_BugmaxHorizontalSteeringReturn
                move.l  #$FFFE0000,$18(a5)
Boss_BugmaxHorizontalSteeringReturn:                    ; CODE XREF: Boss_BugmaxUpdateHorizontalSteering+6A   j  ; was: locret_4DCDA
                                        ; Boss_BugmaxUpdateHorizontalSteering+B4   j
                rts
; End of function Boss_BugmaxUpdateHorizontalSteering
; Steer vertically toward the configured band and oscillate while inside it
Boss_BugmaxUpdateVerticalBandSteering:                  ; CODE XREF: Boss_BugmaxSpawnSineProjectile+4   p  ; was: sub_4DCDC
                                        ; Boss_BugmaxUpdateBattleMovement+6   p
                move.l  #$2000,d7
                move.w  (SharedScratchLong8).w,d0
                move.w  $14(a5),d1
                cmp.w   d0,d1
                blt.s   Boss_BugmaxAccelerateDownTowardVerticalBand
                add.w   (SharedScratchLong8+2).w,d0
                cmp.w   d0,d1
                bgt.s   Boss_BugmaxAccelerateUpTowardVerticalBand
                move.w  (SharedScratchLong1).w,d0
                subi.w  #$80,d0
                andi.w  #$1FF,d0
                cmpi.w  #$100,d0
                bcc.s   Boss_BugmaxAccelerateDownWithinVerticalBand
                sub.l   d7,$1C(a5)
                bra.s   Boss_BugmaxClampVerticalVelocity
; ---------------------------------------------------------------------------
Boss_BugmaxAccelerateDownWithinVerticalBand:            ; CODE XREF: Boss_BugmaxUpdateVerticalBandSteering+2A   j  ; was: loc_4DD0E
                add.l   d7,$1C(a5)
                bra.s   Boss_BugmaxClampVerticalVelocity
; ---------------------------------------------------------------------------
Boss_BugmaxAccelerateDownTowardVerticalBand:            ; CODE XREF: Boss_BugmaxUpdateVerticalBandSteering+10   j  ; was: loc_4DD14
                asr.l   #1,d7
                add.l   d7,$1C(a5)
                bra.s   Boss_BugmaxClampVerticalVelocity
; ---------------------------------------------------------------------------
Boss_BugmaxAccelerateUpTowardVerticalBand:              ; CODE XREF: Boss_BugmaxUpdateVerticalBandSteering+18   j  ; was: loc_4DD1C
                asr.l   #1,d7
                sub.l   d7,$1C(a5)
Boss_BugmaxClampVerticalVelocity:                       ; CODE XREF: Boss_BugmaxUpdateVerticalBandSteering+30   j  ; was: loc_4DD22
                                        ; Boss_BugmaxUpdateVerticalBandSteering+36   j
                cmpi.l  #$20000,$1C(a5)
                blt.s   Boss_BugmaxClampNegativeVerticalVelocity
                move.l  #$20000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxClampNegativeVerticalVelocity:               ; CODE XREF: Boss_BugmaxUpdateVerticalBandSteering+4E   j  ; was: loc_4DD36
                cmpi.l  #$FFFE0000,$1C(a5)
                bgt.s   Boss_BugmaxVerticalBandSteeringReturn
                move.l  #$FFFE0000,$1C(a5)
Boss_BugmaxVerticalBandSteeringReturn:                  ; CODE XREF: Boss_BugmaxUpdateVerticalBandSteering+62   j  ; was: locret_4DD48
                rts
; End of function Boss_BugmaxUpdateVerticalBandSteering
; Unreferenced input helper for adjusting and wrapping the current part angle
Boss_BugmaxAdjustCurrentPartAngleFromInput:             ; was: sub_4DD4A
                movea.w a5,a0
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_BugmaxCheckPartAngleIncreaseInput
                addi.w  #-8,$4C(a0)
Boss_BugmaxCheckPartAngleIncreaseInput:                 ; CODE XREF: Boss_BugmaxAdjustCurrentPartAngleFromInput+8   j  ; was: loc_4DD5A
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_BugmaxWrapInputAdjustedPartAngle
                addi.w  #8,$4C(a0)
Boss_BugmaxWrapInputAdjustedPartAngle:                  ; CODE XREF: Boss_BugmaxAdjustCurrentPartAngleFromInput+16   j  ; was: loc_4DD68
                andi.w  #$1FF,$4C(a0)
                rts
; End of function Boss_BugmaxAdjustCurrentPartAngleFromInput
; Unreferenced input helper for adjusting position or the shared wave accumulator
Boss_BugmaxAdjustPositionOrWaveFromInput:               ; was: sub_4DD70
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_BugmaxCheckPositionXIncreaseInput
                addi.w  #-2,$10(a5)
Boss_BugmaxCheckPositionXIncreaseInput:                 ; CODE XREF: Boss_BugmaxAdjustPositionOrWaveFromInput+6   j  ; was: loc_4DD7E
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_BugmaxCheckPositionUpOrWaveIncreaseInput
                addi.w  #2,$10(a5)
Boss_BugmaxCheckPositionUpOrWaveIncreaseInput:          ; CODE XREF: Boss_BugmaxAdjustPositionOrWaveFromInput+14   j  ; was: loc_4DD8C
                btst    #0,(ControllerHeldState).w
                beq.s   Boss_BugmaxCheckPositionDownOrWaveDecreaseInput
                btst    #5,(ControllerHeldState).w
                bne.s   Boss_BugmaxIncreaseWaveFromModifiedUpInput
                addi.w  #-2,$14(a5)
                bra.s   Boss_BugmaxCheckPositionDownOrWaveDecreaseInput
; ---------------------------------------------------------------------------
Boss_BugmaxIncreaseWaveFromModifiedUpInput:             ; CODE XREF: Boss_BugmaxAdjustPositionOrWaveFromInput+2A   j  ; was: loc_4DDA4
                addi.l  #$A0000,(SharedScratchLong0).w
Boss_BugmaxCheckPositionDownOrWaveDecreaseInput:        ; CODE XREF: Boss_BugmaxAdjustPositionOrWaveFromInput+22   j  ; was: loc_4DDAC
                                        ; Boss_BugmaxAdjustPositionOrWaveFromInput+32   j
                btst    #1,(ControllerHeldState).w
                beq.s   Boss_BugmaxInputAdjustmentReturn
                btst    #5,(ControllerHeldState).w
                bne.s   Boss_BugmaxDecreaseWaveFromModifiedDownInput
                addi.w  #2,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxDecreaseWaveFromModifiedDownInput:           ; CODE XREF: Boss_BugmaxAdjustPositionOrWaveFromInput+4A   j  ; was: loc_4DDC4
                addi.l  #-$A0000,(SharedScratchLong0).w
                tst.l   (SharedScratchLong0).w
Boss_BugmaxInputAdjustmentReturn:                       ; CODE XREF: Boss_BugmaxAdjustPositionOrWaveFromInput+42   j  ; was: locret_4DDD0
                rts
; End of function Boss_BugmaxAdjustPositionOrWaveFromInput
