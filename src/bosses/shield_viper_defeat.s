; Dispatch the three states of a type-$37C Shield Viper defeat object
Boss_ShieldViperDefeatObjectMain:                       ; was: sub_4F1A6
                move.w  4(a5),d0
                lea     Boss_ShieldViperDefeatObjectStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_ShieldViperDefeatObjectMain
; ---------------------------------------------------------------------------
Boss_ShieldViperDefeatObjectStateOffsets:   dc.w    Boss_ShieldViperActivateDefeatObject-*  ; was: off_4F1B2
                dc.w    Boss_ShieldViperAccelerateDefeatObject-*
                dc.w    Boss_ShieldViperDefeatObjectIdle-*

; Wait for the per-record stagger, create a burst, and seed radial acceleration
Boss_ShieldViperActivateDefeatObject:                   ; was: sub_4F1B8
                subq.w  #1,$48(a5)
                bpl.s   Boss_ShieldViperDefeatObjectActivationWaitReturn
                move.w  #$CE80,2(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
                bsr.w   Boss_ShieldViperSpawnDefeatBurst
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                ext.l   d0
                ext.l   d1
                asr.l   #3,d0
                asr.l   #3,d1
                move.l  d0,$58(a5)
                move.l  d1,$5C(a5)
Boss_ShieldViperDefeatObjectActivationWaitReturn:       ; was: locret_4F1FA
                rts
; End of function Boss_ShieldViperActivateDefeatObject
; Add the seeded radial acceleration and rotate the mapping when one is present
Boss_ShieldViperAccelerateDefeatObject:                 ; was: sub_4F1FC
                move.l  $58(a5),d0
                add.l   d0,$18(a5)
                move.l  $5C(a5),d0
                add.l   d0,$1C(a5)
                tst.l   $4C(a5)
                beq.s   Boss_ShieldViperDefeatObjectAccelerationReturn
                movea.l $4C(a5),a1
                movea.w a5,a0
                addi.w  #$10,$56(a5)
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                bsr.w   Gfx_ShieldViperSelectMappingFromQuantizedAngle
Boss_ShieldViperDefeatObjectAccelerationReturn:         ; was: locret_4F22A
                rts
; End of function Boss_ShieldViperAccelerateDefeatObject
; Create a falling type-$88 burst and optionally play its sound
Boss_ShieldViperSpawnDefeatBurst:                       ; was: sub_4F22C
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperDefeatBurstReturn
                move.l  #SharedCombatSpriteAnimation01,8(a0)
                jsr     (Projectile_InitType88).l
                clr.b   $20(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #$FFFE0000,$1C(a0)
                tst.w   $2C(a5)
                beq.s   Boss_ShieldViperDefeatBurstReturn
                move.b  #$C1,d0
                jmp     (Sound_QueueSFXRequest).l
; Signed offsets added to base radial step $10 over a 32-frame cycle
Boss_ShieldViperDefeatBurstReturn:                      ; was: locret_4F26A
                                        ; Boss_ShieldViperSpawnDefeatBurst+32   j
                rts
; End of function Boss_ShieldViperSpawnDefeatBurst
Boss_ShieldViperDefeatObjectIdle:                       ; was: nullsub_117
                rts
; End of function Boss_ShieldViperDefeatObjectIdle

; Cycle the radial movement step through a signed 32-frame triangle wave
Boss_ShieldViperUpdateRadialMovementStep:               ; was: sub_4F26E
                move.w  (SharedScratchLong7+2).w,d0
                add.w   d0,d0
                move.w  Boss_ShieldViperRadialStepTriangleWave(pc,d0.w),d0
                addi.w  #$10,d0
                move.w  d0,(SharedScratchLong7).w
                addq.w  #1,(SharedScratchLong7+2).w
                andi.w  #$1F,(SharedScratchLong7+2).w
                rts
; End of function Boss_ShieldViperUpdateRadialMovementStep
; ---------------------------------------------------------------------------
Boss_ShieldViperRadialStepTriangleWave: dc.w    0, 1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2, 1  ; was: word_4F28C
                dc.w    0, $FFFF, $FFFE, $FFFD, $FFFC, $FFFB, $FFFA, $FFF9, $FFF8, $FFF9, $FFFA, $FFFB, $FFFC, $FFFD, $FFFE, $FFFF

; Disable linked geometry and seed four trail samples between adjacent records
Boss_ShieldViperEnableTrailGeometry:                    ; was: sub_4F2CC
                bclr    #0,(SharedScratchLong5+1).w
                move.w  #$18,d7
                lea     (a5),a0
                lea     (ShieldViperTrailAngles).w,a1
                lea     (ShieldViperPoseHistory).w,a2
Boss_ShieldViperSeedNextTrailInterval:                  ; was: loc_4F2E0
                move.w  $56(a0),d0
                add.w   $52(a0),d0
                move.w  d0,$56(a0)
                clr.w   $52(a0)
                clr.w   $54(a0)
                move.w  $70(a0),d1
                sub.w   $10(a0),d1
                asr.w   #3,d1
                move.w  $74(a0),d2
                sub.w   $14(a0),d2
                asr.w   #3,d2
                move.w  $10(a0),d3
                move.w  $14(a0),d4
                move.w  #3,d6
Boss_ShieldViperStoreTrailIntervalSamples:              ; was: loc_4F314
                move.w  d0,(a1)+
                move.w  d3,(a2)+
                move.w  d4,(a2)+
                add.w   d1,d3
                add.w   d2,d4
                dbf     d6,Boss_ShieldViperStoreTrailIntervalSamples
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperSeedNextTrailInterval
                rts
; End of function Boss_ShieldViperEnableTrailGeometry
; Preserve effective body angles while switching from trail to linked geometry
Boss_ShieldViperEnableLinkedBodyGeometry:               ; was: sub_4F32C
                bset    #0,(SharedScratchLong5+1).w
                move.w  #$10,d7
                move.w  $4D6(a5),d0
                lea     (a5),a0
Boss_ShieldViperRebaseNextLinkedBodyAngle:              ; was: loc_4F33C
                move.w  $56(a0),d1
                sub.w   d0,d1
                move.w  d1,$52(a0)
                move.w  d1,$54(a0)
                move.w  d0,$56(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperRebaseNextLinkedBodyAngle
                lea     $660(a5),a0
                lea     (ShieldViperAngleDelay).w,a1
                move.w  #7,d7
Boss_ShieldViperSeedNextTrailingAngleGroup:             ; was: loc_4F362
                move.w  $56(a0),d0
                move.w  #7,d6
Boss_ShieldViperStoreTrailingAngleSample:               ; was: loc_4F36A
                move.w  d0,(a1)+
                dbf     d6,Boss_ShieldViperStoreTrailingAngleSample
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperSeedNextTrailingAngleGroup
                move.w  d0,(a1)
                rts
; End of function Boss_ShieldViperEnableLinkedBodyGeometry
; Advance the controller angle, then move radially at the resulting angle
Boss_ShieldViperRotateAndMoveRadially:                  ; was: sub_4F37C
                                        ; Boss_ShieldViperRotateToEntryAngle+6   p
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,$56(a5)
                bsr.w   Boss_ShieldViperMoveRadially
                rts
; End of function Boss_ShieldViperRotateAndMoveRadially
; Choose angular step $FFFC or 4 to rotate toward a supplied target point
Boss_ShieldViperChooseRotationTowardTarget:             ; was: sub_4F38A
                                        ; Boss_ShieldViperChooseRandomVerticalTarget+1E   p
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                addi.w  #$100,d2
                sub.w   $56(a5),d2
                andi.w  #$1FF,d2
                cmpi.w  #$100,d2
                bcs.s   Boss_ShieldViperSelectPositiveTargetRotation
                move.w  #$FFFC,(SharedScratchLong0).w
                bra.s   Boss_ShieldViperTargetRotationSelectionReturn
; ---------------------------------------------------------------------------
Boss_ShieldViperSelectPositiveTargetRotation:           ; was: loc_4F3B2
                move.w  #4,(SharedScratchLong0).w
Boss_ShieldViperTargetRotationSelectionReturn:          ; was: locret_4F3B8
                rts
; End of function Boss_ShieldViperChooseRotationTowardTarget
; Every eight frames, choose rotation toward the player position
Boss_ShieldViperChooseRotationTowardPlayerEveryEightFrames:  ; was: sub_4F3BA
                move.w  (FrameCounter).w,d7
                andi.w  #7,d7
                bne.s   Boss_ShieldViperPlayerTargetRotationReturn
                move.w  (PlayerCenterX).w,d0
                move.w  (PlayerCenterY).w,d1
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
Boss_ShieldViperPlayerTargetRotationReturn:             ; was: locret_4F3D0
                rts
; End of function Boss_ShieldViperChooseRotationTowardPlayerEveryEightFrames
; Every eight frames, choose rotation toward arena point ($120,$F0)
Boss_ShieldViperChooseRotationTowardArenaCenterEveryEightFrames:  ; was: sub_4F3D2
                move.w  (FrameCounter).w,d7
                andi.w  #7,d7
                bne.s   Boss_ShieldViperCenterTargetRotationReturn
                move.w  #$120,d0
                move.w  #$F0,d1
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
Boss_ShieldViperCenterTargetRotationReturn:             ; was: locret_4F3E8
                rts
; End of function Boss_ShieldViperChooseRotationTowardArenaCenterEveryEightFrames
; Write four wrapped-angle samples between each of sixteen adjacent body records
Boss_ShieldViperInterpolateTrailAnglesBetweenBodyRecords:  ; was: sub_4F3EA
                lea     (ShieldViperTrailAngles).w,a1
                move.w  #$F,d7
                lea     $60(a5),a0
Boss_ShieldViperInterpolateNextBodyAnglePair:           ; was: loc_4F3F6
                move.w  $56(a0),d0
                move.w  $B6(a0),d1
                sub.w   d0,d1
                andi.w  #$1FF,d1
                cmpi.w  #$100,d1
                bcc.s   Boss_ShieldViperNormalizeNegativeBodyAngleDelta
                bra.s   Boss_ShieldViperScaleBodyAngleDelta
; ---------------------------------------------------------------------------
Boss_ShieldViperNormalizeNegativeBodyAngleDelta:        ; was: loc_4F40C
                move.w  #$200,d2
                sub.w   d1,d2
                andi.w  #$1FF,d2
                move.w  d2,d1
                neg.w   d1
Boss_ShieldViperScaleBodyAngleDelta:                    ; was: loc_4F41A
                asr.w   #3,d1
                move.w  #3,d6
Boss_ShieldViperStoreInterpolatedTrailAngles:           ; was: loc_4F420
                move.w  d0,(a1)+
                add.w   d1,d0
                dbf     d6,Boss_ShieldViperStoreInterpolatedTrailAngles
                lea     $60(a0),a0
                dbf     d7,Boss_ShieldViperInterpolateNextBodyAnglePair
                clr.w   (SharedScratchLong1).w
                rts
; End of function Boss_ShieldViperInterpolateTrailAnglesBetweenBodyRecords
; Keep record Y strictly inside the boundary values $A0 and $150
Boss_ShieldViperClampRecordYInsideVerticalBand:         ; was: sub_4F436
                cmpi.w  #$A0,$14(a0)
                bgt.s   Boss_ShieldViperCheckRecordUpperYBound
                move.w  #$A2,$14(a0)
Boss_ShieldViperCheckRecordUpperYBound:                 ; was: loc_4F444
                cmpi.w  #$150,$14(a0)
                blt.s   Boss_ShieldViperVerticalBandClampReturn
                move.w  #$14E,$14(a0)
Boss_ShieldViperVerticalBandClampReturn:                ; was: locret_4F452
                rts
; End of function Boss_ShieldViperClampRecordYInsideVerticalBand
; Store the magnitude and sign of input d0 minus the shared body-bend step
Boss_ShieldViperStoreBendStepDeltaMagnitudeAndSign:     ; was: sub_4F454
                clr.w   $48(a5)
                sub.w   (SharedScratchLong1).w,d0
                beq.w   Boss_ShieldViperBendStepDeltaReturn
                tst.w   d0
                bpl.s   Boss_ShieldViperStorePositiveBendStepDeltaSign
                move.w  #$FFFF,$4C(a5)
                neg.w   d0
                bra.s   Boss_ShieldViperStoreBendStepDeltaMagnitude
; ---------------------------------------------------------------------------
Boss_ShieldViperStorePositiveBendStepDeltaSign:         ; was: loc_4F46E
                move.w  #1,$4C(a5)
Boss_ShieldViperStoreBendStepDeltaMagnitude:            ; was: loc_4F474
                move.w  d0,$48(a5)
Boss_ShieldViperBendStepDeltaReturn:                    ; was: locret_4F478
                rts
; End of function Boss_ShieldViperStoreBendStepDeltaMagnitudeAndSign
; Write symmetric target angular offsets across the linked body records
Boss_ShieldViperSetBodyTargetAngularOffsets:            ; was: sub_4F47A
                                        ; sub_4E3FE:Boss_ShieldViperApplyBodyBendPhase   p
                move.w  (SharedScratchLong1).w,d5
                move.w  #2,d7
                lea     $480(a5),a0
                movea.w a0,a1
                moveq   #0,d0
                moveq   #0,d1
Boss_ShieldViperSetSymmetricCenterBodyOffsets:          ; was: loc_4F48C
                lea     -$60(a0),a0
                lea     $60(a1),a1
                add.w   d5,d0
                sub.w   d5,d1
                move.w  d0,$54(a0)
                move.w  d1,$54(a1)
                dbf     d7,Boss_ShieldViperSetSymmetricCenterBodyOffsets
                lea     -$60(a0),a0
                lea     $60(a1),a1
                sub.w   d5,d0
                sub.w   d5,d1
                move.w  d0,$54(a0)
                move.w  d1,$54(a1)
                move.w  #7,d7
Boss_ShieldViperSetRemainingLeadingBodyOffsets:         ; was: loc_4F4BC
                lea     -$60(a0),a0
                sub.w   d5,d0
                move.w  d0,$54(a0)
                dbf     d7,Boss_ShieldViperSetRemainingLeadingBodyOffsets
                rts
; End of function Boss_ShieldViperSetBodyTargetAngularOffsets
; Move the controller radially using the current angle and shared step
Boss_ShieldViperMoveRadially:                           ; was: sub_4F4CC
                                        ; Boss_ShieldViperMoveToEntryYThreshold+6   p
                move.w  $56(a5),d0
                addi.w  #$100,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d0.w),d1
Boss_ShieldViperApplyRadialDisplacement:                ; was: loc_4F4E2
                move.w  (a3,d0.w),d0
                move.w  (SharedScratchLong7).w,d2
                muls.w  d2,d0
                muls.w  d2,d1
                add.l   d0,$10(a5)
                add.l   d1,$14(a5)
                rts
; End of function Boss_ShieldViperMoveRadially
; Select controller and body mappings from their quantized effective angles
Gfx_ShieldViperUpdateBodyMappings:                      ; was: sub_4F4F8
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                lea     Boss_ShieldViperControllerAngularMappingRecords(pc),a1
                nop
                movea.w a5,a0
                bsr.w   Gfx_ShieldViperSelectMappingFromQuantizedAngle
                move.w  #$11,d7
                lea     $60(a5),a0
                lea     Boss_ShieldViperBodyAngularMappingRecords(pc),a1
                nop
Gfx_ShieldViperUpdateNextBodyMapping:                   ; was: loc_4F51A
                move.w  $56(a0),d0
                add.w   $52(a0),d0
                bsr.w   Gfx_ShieldViperSelectMappingFromQuantizedAngle
                lea     $60(a0),a0
                dbf     d7,Gfx_ShieldViperUpdateNextBodyMapping
                rts
; End of function Gfx_ShieldViperUpdateBodyMappings
; Select sprite mapping and orientation bits from a quantized nine-bit angle
Gfx_ShieldViperSelectMappingFromQuantizedAngle:         ; was: sub_4F530
                                        ; Boss_ShieldViperPositionLinkedPartFromBodyRecord+4E   p
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1C0,d0
                lsr.w   #3,d0
                lea     (a1,d0.w),a2
                move.w  (a2),d0
                andi.w  #$F7FF,$E(a0)
                andi.w  #$EFFF,$E(a0)
                or.w    d0,$E(a0)
                move.l  4(a2),8(a0)
                rts
; End of function Gfx_ShieldViperSelectMappingFromQuantizedAngle
; ---------------------------------------------------------------------------
; Eight controller mapping records indexed by quantized angle
Boss_ShieldViperControllerAngularMappingRecords:    dc.w    0  ; field_0  ; was: stru_4F558
                                        ; Gfx_ShieldViperUpdateBodyMappings+8   o
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame00  ; field_4
                dc.w    $1000                           ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame01  ; field_4
                dc.w    $1000                           ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame02  ; field_4
                dc.w    $1000                           ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame03  ; field_4
                dc.w    $800                            ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame00  ; field_4
                dc.w    $800                            ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame01  ; field_4
                dc.w    0                               ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame02  ; field_4
                dc.w    $800                            ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperControllerAngleFrame03  ; field_4
; Eight body mapping records indexed by quantized angle
Boss_ShieldViperBodyAngularMappingRecords:  dc.w    0   ; field_0  ; was: stru_4F598
                                        ; Boss_ShieldViperBeginLinkedPartEjection+48   o
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $1000                           ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame01  ; field_4
                dc.w    $1000                           ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame02  ; field_4
                dc.w    $1000                           ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame03  ; field_4
                dc.w    $800                            ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame00  ; field_4
                dc.w    $800                            ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame01  ; field_4
                dc.w    0                               ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame02  ; field_4
                dc.w    $800                            ; field_0
                dc.w    $FFFF                           ; field_2
                dc.l    Boss_ShieldViperBodyAngleFrame03  ; field_4

; Debug routine that updates shield viper debugging features
