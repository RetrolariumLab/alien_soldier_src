Boss_BackStringerUpdateRender:                          ; was: sub_44F50
                                        ; Boss_BackStringerBeginEntrance+30   j
                bsr.w   Boss_BackStringerUpdatePalette
                bsr.w   Boss_BackStringerUpdateArms
                moveq   #$14,d7
                jmp     Boss_BackStringerUpdateSegmentChainAndLoadCount
; End of function Boss_BackStringerUpdateRender
; Updates palette cycling
Boss_BackStringerUpdatePalette:                         ; was: sub_44F60
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #$E,d0
                movea.w #(PaletteActiveColor58Hi-M68K_RAM),a0
                move.w  Boss_BackStringerPaletteCycleColor0(pc,d0.w),$80(a0)
                move.w  Boss_BackStringerPaletteCycleColor0(pc,d0.w),(a0)+
                move.w  Boss_BackStringerPaletteCycleColor1(pc,d0.w),$80(a0)
                move.w  Boss_BackStringerPaletteCycleColor1(pc,d0.w),(a0)+
                move.w  Boss_BackStringerPaletteCycleColor2(pc,d0.w),$80(a0)
                move.w  Boss_BackStringerPaletteCycleColor2(pc,d0.w),(a0)+
                rts
; End of function Boss_BackStringerUpdatePalette
; ---------------------------------------------------------------------------
Boss_BackStringerPaletteCycleColor0:    binclude "data/palettes/044F8E.bin"  ; was: word_44F8E
                                        ; Boss_BackStringerUpdatePalette+14   r
Boss_BackStringerPaletteCycleColor1:    binclude "data/palettes/044F9E.bin"  ; was: word_44F9E
                                        ; Boss_BackStringerUpdatePalette+1E   r
Boss_BackStringerPaletteCycleColor2:    binclude "data/palettes/044FAE.bin"  ; was: word_44FAE
                                        ; Boss_BackStringerUpdatePalette+28   r

; Updates arm sprite orientation
Boss_BackStringerUpdateArms:                            ; was: sub_44FBE
                movea.w a5,a0
                lea     $60(a0),a0
                move.w  #$8300,$E(a0)
                moveq   #0,d1
                bsr.s   Boss_BackStringerUpdatePartFrameFromAngle
                lea     $60(a0),a0
                move.w  #$9B00,$E(a0)
                moveq   #$10,d1
; End of function Boss_BackStringerUpdateArms
; Selects a part frame from its local angle plus the boss body angle
Boss_BackStringerUpdatePartFrameFromAngle:              ; was: sub_44FDA
                move.w  $56(a0),d0
                add.w   $56(a5),d0
Boss_BackStringerSelectPartFrameFromAngle:              ; was: loc_44FE2
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1FE,d0
                cmpi.w  #$100,d0
                bmi.s   Boss_BackStringerApplyPartFacing
                eori.w  #$1800,$E(a0)
Boss_BackStringerApplyPartFacing:                       ; was: loc_44FF6
                tst.w   $54(a5)
                bne.s   Boss_BackStringerLoadPartAngleFrame
                eori.w  #$800,$E(a0)
Boss_BackStringerLoadPartAngleFrame:                    ; was: loc_45002
                asr.w   #4,d0
                andi.w  #$C,d0
                add.w   d1,d0
                move.l  Boss_BackStringerPartAngleFrameTable(pc,d0.w),8(a0)
                rts
; End of function Boss_BackStringerUpdatePartFrameFromAngle
; ---------------------------------------------------------------------------
Boss_BackStringerPartAngleFrameTable:   dc.l    Boss_BackStringerPartAngleMapping0  ; was: off_45012
                dc.l    Boss_BackStringerPartAngleMapping1
                dc.l    Boss_BackStringerPartAngleMapping2
                dc.l    Boss_BackStringerPartAngleMapping3
                dc.l    Boss_BackStringerPartAngleMapping4
                dc.l    Boss_BackStringerPartAngleMapping5
                dc.l    Boss_BackStringerPartAngleMapping6
                dc.l    Boss_BackStringerPartAngleMapping7

; Copies the base colors and applies the timed transformation highlights
Boss_BackStringerUpdateTransformationPalette:           ; was: sub_45032
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a0
                movea.w #(PaletteShadowPair16+2-M68K_RAM),a1
                moveq   #$B,d7
Boss_BackStringerCopyTransformationPaletteLoop:         ; was: loc_4503C
                move.w  (a1)+,(a0)+
                dbf     d7,Boss_BackStringerCopyTransformationPaletteLoop
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a0
                move.w  $4DC(a5),d0
                andi.w  #$FFFE,d0
                cmpi.w  #2,d0
                bmi.s   Boss_BackStringerCheckSecondTransformationHighlight
                move.w  #$ECC,(a0,d0.w)
Boss_BackStringerCheckSecondTransformationHighlight:    ; was: loc_4505A
                cmpi.w  #$16,d0
                bpl.s   Boss_BackStringerTransformationPaletteReturn
                cmpi.w  #$C,d0
                bmi.s   Boss_BackStringerTransformationPaletteReturn
                move.w  #$A40,2(a0,d0.w)
Boss_BackStringerTransformationPaletteReturn:           ; was: locret_4506C
                                        ; Boss_BackStringerUpdateTransformationPalette+32   j
                rts
; End of function Boss_BackStringerUpdateTransformationPalette
; Initializes the preallocated tail-segment display slots
Boss_BackStringerInitializeTailSegmentSlots:            ; was: sub_4506E
                movea.w #(FiftyThirdEntityType-M68K_RAM),a0
                moveq   #5,d7
Boss_BackStringerInitializeTailSegmentSlotsLoop:        ; was: loc_45074
                move.w  #$10,(a0)
                clr.w   2(a0)
                move.w  #$C3E7,$E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BackStringerInitializeTailSegmentSlotsLoop
                move.w  #$10,(a0)
                clr.w   2(a0)
                move.w  #$C3EB,$E(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                clr.b   $21(a0)
                move.l  #$818FA06,$2C(a0)
                rts
; End of function Boss_BackStringerInitializeTailSegmentSlots
; Resets the six tail segments and their contact endpoint
Boss_BackStringerResetTailSegments:                     ; was: sub_450B2
                                        ; Boss_BackStringerDivePreparationState+3EE   p
                clr.l   $2FC(a5)
                movea.w #(FiftyThirdEntityType-M68K_RAM),a0
                moveq   #5,d7
Boss_BackStringerResetTailSegmentsLoop:                 ; was: loc_450BC
                move.w  #$10,(a0)
                move.w  #$8080,2(a0)
                move.w  #$300,8(a0)
                move.w  #$FCF0,$A(a0)
                move.b  #$14,$20(a0)
                move.w  $D0(a5),$10(a0)
                move.w  $D4(a5),$14(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BackStringerResetTailSegmentsLoop
                tst.w   $29E(a5)
                bmi.s   Boss_BackStringerResetTailSegmentsReturn
                move.w  $D0(a5),$10(a0)
                move.w  $D4(a5),$14(a0)
                clr.w   $29E(a5)
                move.b  #2,$21(a0)
                clr.b   $22(a0)
Boss_BackStringerResetTailSegmentsReturn:               ; was: locret_4510C
                rts
; End of function Boss_BackStringerResetTailSegments
; Updates tail segment positions and publishes endpoint contact state
Boss_BackStringerUpdateTailSegmentPositions:            ; was: sub_4510E
                                        ; Boss_BackStringerDiveAttackState:Boss_BackStringerUpdateDiveTail   p
                move.l  $2FC(a5),d0
                move.l  d0,d1
                add.l   $D4(a5),d1
                moveq   #3,d3
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_BackStringerPrepareTailSegmentLoop
                moveq   #0,d3
Boss_BackStringerPrepareTailSegmentLoop:                ; was: loc_45124
                movea.w #(FiftyThirdEntityType-M68K_RAM),a0
                moveq   #5,d7
Boss_BackStringerUpdateTailSegmentLoop:                 ; was: loc_4512A
                andi.w  #$F7FF,$E(a0)
                bset    d3,$E(a0)
                move.l  d1,$14(a0)
                add.l   d0,d1
                lea     $60(a0),a0
                dbf     d7,Boss_BackStringerUpdateTailSegmentLoop
                move.w  -$4C(a0),d1
                subi.w  #$10,d1
                move.w  d1,$14(a0)
                tst.w   $29E(a5)
                bmi.s   Boss_BackStringerUpdateTailSegmentsReturn
                bne.s   Boss_BackStringerCheckTailContactRelease
                bclr    #1,$22(a0)
                beq.s   Boss_BackStringerUpdateTailSegmentsReturn
                move.w  #$8080,2(a0)
                bset    #1,(ForcedPositionFlags).w
                move.w  #2,$29E(a5)
                bset    #4,(PlayerSpriteAttributes).w
Boss_BackStringerCheckTailContactRelease:               ; was: loc_45176
                bclr    #1,(ForcedPositionFlags).w
                bne.s   Boss_BackStringerPublishTailContact
                clr.w   $29E(a5)
                bra.s   Boss_BackStringerUpdateTailSegmentsReturn
; ---------------------------------------------------------------------------
Boss_BackStringerPublishTailContact:                    ; was: loc_45184
                bset    #7,(PlayerSpriteAttributes).w
                move.w  #$C8,(ForcedPositionTimer).w
                bset    #0,(ForcedPositionFlags).w
                bset    #2,(ForcedPositionFlags).w
                move.w  $10(a0),(ForcedPositionX).w
                move.w  $14(a0),(ForcedPositionY).w
Boss_BackStringerUpdateTailSegmentsReturn:              ; was: locret_451A8
                                        ; Boss_BackStringerUpdateTailSegmentPositions+4E   j
                rts
; End of function Boss_BackStringerUpdateTailSegmentPositions
; Converts the six tail segments into staggered retracting objects
Boss_BackStringerRetractTailSegments:                   ; was: sub_451AA
                                        ; Boss_BackStringerDiveAttackState+7A   p
                move.w  #$324,d0
                moveq   #$FFFFFFFF,d1
                movea.w #(FiftyThirdEntityType-M68K_RAM),a0
                moveq   #5,d7
Boss_BackStringerRetractTailSegmentsLoop:               ; was: loc_451B6
                move.w  d0,(a0)
                move.w  #$8480,2(a0)
                move.w  #6,$48(a0)
                move.w  d1,$1C(a0)
                subq.w  #1,d1
                lea     $60(a0),a0
                dbf     d7,Boss_BackStringerRetractTailSegmentsLoop
                clr.w   $29E(a5)
                clr.w   2(a0)
                clr.b   $21(a0)
                bclr    #4,(PlayerSpriteAttributes).w
                rts
; End of function Boss_BackStringerRetractTailSegments
; Flashing effect for destroyed BackStringer segment
Effect_BackStringerSegmentFlash:                        ; was: sub_451E6
                subq.w  #1,$48(a5)
                bpl.s   Effect_BackStringerSegmentFlashUpdate
                move.w  #$10,(a5)
                clr.w   2(a5)
                rts
; ---------------------------------------------------------------------------
Effect_BackStringerSegmentFlashUpdate:                  ; was: loc_451F6
                bset    #3,$E(a5)
                btst    #0,(FrameCounter+1).w
                bne.s   Effect_BackStringerSegmentFlashSelectFrame
                bclr    #3,$E(a5)
Effect_BackStringerSegmentFlashSelectFrame:             ; was: loc_4520A
                move.w  $48(a5),d0
                andi.w  #6,d0
                move.w  Effect_BackStringerSegmentFlashFrameOffsets(pc,d0.w),8(a5)
                move.w  Effect_BackStringerSegmentFlashCoordinates(pc,d0.w),$A(a5)
                rts
; End of function Effect_BackStringerSegmentFlash
; ---------------------------------------------------------------------------
Effect_BackStringerSegmentFlashFrameOffsets:    dc.w    0, $100, $200  ; was: word_45220
Effect_BackStringerSegmentFlashCoordinates:     dc.w    $FCFC, $FCF8, $FCF4  ; was: word_45226

; Applies circular motion
Boss_BackStringerApplyCircularMotion:                   ; was: sub_4522C
                                        ; Boss_BackStringerRotateToHalfTurnState+DA   p
                tst.w   $23E(a5)
                beq.s   Boss_BackStringerApplyCircularMotionStep
                move.w  #$3C,$3BC(a5)                   ; '<'
Boss_BackStringerApplyCircularMotionStep:               ; was: loc_45238
                subi.w  #4,$3BC(a5)
                move.w  $56(a5),d0
                subi.w  #$80,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d0.w),d1
                move.w  (a0,d0.w),d2
                move.w  $3BC(a5),d0
                asr.w   #2,d0
                muls.w  d0,d1
                muls.w  d0,d2
                add.l   d1,$14(a5)
                add.l   d2,$10(a5)
                rts
; End of function Boss_BackStringerApplyCircularMotion
; Animates boss pose from script
Boss_BackStringerAnimatePose:                           ; was: sub_4526C
                                        ; Boss_BackStringerBeginEntrance+28   p
                clr.w   $23E(a5)
                tst.w   $C(a5)
                bpl.s   Boss_BackStringerApplyPoseInterpolation
Boss_BackStringerReadNextPoseCommand:                   ; was: loc_45276
                move.w  $58(a5),d0
                bmi.w   Boss_BackStringerPublishPoseAngles
                cmpi.b  #$80,(a1,d0.w)
                bne.s   Boss_BackStringerDecodePoseCommand
                move.b  1(a1,d0.w),d0
                jsr     (Sound_QueueSFXRequest).l
                addq.w  #2,$58(a5)
                move.w  $58(a5),d0
Boss_BackStringerDecodePoseCommand:                     ; was: loc_45298
                move.w  (a1,d0.w),d3
                cmpi.w  #$FFFE,d3
                bne.s   Boss_BackStringerCheckPoseLoopMarker
                move.w  d3,$58(a5)
                rts
; ---------------------------------------------------------------------------
Boss_BackStringerCheckPoseLoopMarker:                   ; was: loc_452A8
                cmpi.w  #$FFFF,d3
                bne.s   Boss_BackStringerStartPoseInterpolation
                clr.w   $58(a5)
                clr.w   $29C(a5)
                bra.s   Boss_BackStringerReadNextPoseCommand
; ---------------------------------------------------------------------------
Boss_BackStringerStartPoseInterpolation:                ; was: loc_452B8
                move.w  d3,(PoseCommandWord).w
                andi.w  #$FF,d3
                move.w  2(a1,d0.w),d0
                ext.l   d0
                addi.l  #Boss_BackStringerPoseTable,d0
                movea.l d0,a0
                bsr.w   Anim_BackStringerCalcInterpolation
                moveq   #0,d0
                move.b  (PoseDurationByte).w,d0
                move.w  d0,$C(a5)
                addq.w  #4,$58(a5)
                addq.w  #1,$29C(a5)
                addq.w  #1,$23E(a5)
                tst.w   $C(a5)
                bmi.s   Boss_BackStringerPublishPoseAngles
Boss_BackStringerApplyPoseInterpolation:                ; was: loc_452EE
                subq.w  #1,$C(a5)
                movea.w #(BackStringerPoseBuffer-M68K_RAM),a0
                moveq   #$13,d7
                jsr     (Anim_AdvancePoseChannelInterpolation).l
Boss_BackStringerPublishPoseAngles:                     ; was: loc_452FE
                                        ; Boss_BackStringerAnimatePose+80   j
                move.w  #$1FE,d7
                movea.w #(BackStringerPoseBuffer-M68K_RAM),a0
                move.b  (a0),d0
                asl.w   #1,d0
                and.w   d7,d0
                move.w  d0,$B6(a5)
                move.b  4(a0),d1
                asl.w   #1,d1
                and.w   d7,d1
                move.w  d1,$116(a5)
                movea.w #(BackStringerPoseGroup-M68K_RAM),a0
                move.b  (a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$176(a5)
                move.b  4(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$1D6(a5)
                move.b  8(a0),d2
                asl.w   #1,d2
                add.w   d3,d2
                and.w   d7,d2
                move.w  d2,$236(a5)
                move.b  $C(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$296(a5)
                move.b  $10(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$2F6(a5)
                move.b  $14(a0),d2
                asl.w   #1,d2
                add.w   d3,d2
                and.w   d7,d2
                move.w  d2,$356(a5)
                move.b  $18(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$3B6(a5)
                move.b  $1C(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$416(a5)
                move.b  $20(a0),d2
                asl.w   #1,d2
                add.w   d3,d2
                and.w   d7,d2
                move.w  d2,$476(a5)
                move.b  $24(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$4D6(a5)
                move.b  $28(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$536(a5)
                move.b  $2C(a0),d2
                asl.w   #1,d2
                add.w   d3,d2
                and.w   d7,d2
                move.w  d2,$596(a5)
                move.b  $30(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$5F6(a5)
                move.b  $34(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$656(a5)
                move.b  $38(a0),d2
                asl.w   #1,d2
                add.w   d3,d2
                and.w   d7,d2
                move.w  d2,$6B6(a5)
                move.b  $3C(a0),d2
                asl.w   #1,d2
                and.w   d7,d2
                move.w  d2,$716(a5)
                move.b  $40(a0),d3
                asl.w   #1,d3
                add.w   d2,d3
                and.w   d7,d3
                move.w  d3,$776(a5)
                move.b  $44(a0),d2
                asl.w   #1,d2
                add.w   d3,d2
                and.w   d7,d2
                move.w  d2,$7D6(a5)
                rts
; End of function Boss_BackStringerAnimatePose
; Calculates animation interpolation
Anim_BackStringerCalcInterpolation:                     ; was: sub_45410
                movea.l #Boss_BackStringerNeutralPose,a1
                movea.w #(BackStringerPoseBuffer-M68K_RAM),a2
                move.w  d3,$C(a5)
                moveq   #$13,d7
                jmp     Anim_CalculatePoseChannelDeltas
; End of function Anim_BackStringerCalcInterpolation
; Initializes Back Stringer's twenty fixed-point pose channels from bytes at a0
Boss_BackStringerInitializePoseChannels:
                movea.w #(BackStringerPoseBuffer-M68K_RAM),a1  ; was: sub_45426
                moveq   #$13,d7
                jmp     Anim_InitializePoseChannelsFromBytes
; End of function Boss_BackStringerInitializePoseChannels
; ---------------------------------------------------------------------------
Boss_BackStringerManualControlPoses:    dc.w    $2020, 0, $2020, $14, $FFFF  ; was: word_45432
Boss_BackStringerOpeningDelayPoses:     dc.w    $2828, $28, $607, 0, $2828, $14, $607, 0, $FFFF  ; was: word_4543C
Boss_BackStringerCircularMotionPoses:   dc.w    $708, $3C, $708, $50, $708, $64, $708, $78, $FFFF  ; was: word_4544E
                                        ; Boss_BackStringerTrackingAttackWarmupState+40   o
Boss_BackStringerIncreasingAnglePoses:  dc.w    $305, $8C, $305, $A0, $305, $B4, $305, $C8, $FFFF  ; was: word_45460
                                        ; Boss_BackStringerUpdateRotationAttack+1A   o
Boss_BackStringerDecreasingAnglePoses:  dc.w    $305, $DC, $305, $F0, $305, $104, $305, $118, $FFFF  ; was: word_45472
                                        ; Boss_BackStringerTrackingAttackState+122   o
Boss_BackStringerOpeningPoses:  dc.w    $306, $12C, $606, $12C, $418, $64, $306, $140, $606, $140, $418, $3C, $FFFF  ; was: word_45484
Boss_BackStringerIdlePoses:     dc.w    $808, 0, $418, $154, $FFFF  ; was: word_4549E
                                        ; Boss_BackStringerUseIdlePoseAndRender   o
Boss_BackStringerDivePreparationPoses:  dc.w    $404, 0, $20C, $154, $FFFF  ; was: word_454A8
Boss_BackStringerDiveAttackPoses:       dc.w    $408, $190, $408, $190, $C0E, $154, $3030, 0, $FFFE  ; was: word_454B2
Boss_BackStringerSweepPoses:            dc.w    $80C, $154, $C0C, $154, $80C, 0, $C0C, 0, $FFFF  ; was: word_454C4
Boss_BackStringerTransformationPoses:   dc.w    $1010, $154, $E10, $17C, $707, $17C, $80D9  ; was: word_454D6
                dc.w    $C0E, $190, $404, $190, $1010, $154, $FFFE
Boss_BackStringerPoseTable: binclude "data/other/word_454F2.bin"  ; was: word_454F2
Boss_BackStringerPoseTable_End:                         ; was: word_454F2_End

; Updates the detached rope segment and its shared surface reference
Projectile_BackStringerRopeSegment:                     ; was: sub_45696
                bclr    #0,$5E(a5)
                beq.s   Projectile_BackStringerRopeSegmentUpdateSurface
                move.w  #$1000,d0
                muls.w  $5C(a5),d0
                add.l   d0,$14(a5)
                clr.w   $5C(a5)
                move.w  #2,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
                cmpi.w  #$170,$14(a5)
                bmi.s   Projectile_BackStringerRopeSegmentUpdateSurface
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_BackStringerRopeSegmentUpdateSurface:        ; was: loc_456CA
                                        ; Projectile_BackStringerRopeSegment+2A   j
                move.w  #$168,d0
                add.w   $14(a5),d0
                move.w  d0,(SecondaryCameraYPos).w
                clr.l   $1C(a5)
                move.w  (PlayerYPosition).w,d0
                cmp.w   $14(a5),d0
                bpl.s   Projectile_BackStringerRopeSegmentReturn
                bclr    #7,(PlayerSpriteAttributes).w
Projectile_BackStringerRopeSegmentReturn:               ; was: locret_456EA
                rts
; End of function Projectile_BackStringerRopeSegment

; Spawns the falling-drop objects used throughout the regular attack loop
Projectile_BackStringerSpawnFallingDrops:               ; was: sub_456EC
                                        ; Boss_BackStringerSweepingAttackState   p
                tst.w   (SecondaryEntityType).w
                beq.w   Projectile_BackStringerSpawnFallingDropsReturn
                move.w  (FrameCounter).w,d0
                andi.w  #$1F,d0
                bne.s   Projectile_BackStringerSpawnFallingDropsReturn
                tst.w   $47C(a5)
                bpl.s   Projectile_BackStringerSpawnNextFallingDrop
                subq.w  #1,$47E(a5)
                bpl.s   Projectile_BackStringerSpawnFallingDropsReturn
                move.w  #7,$47C(a5)
                move.w  #$B,$47E(a5)
Projectile_BackStringerSpawnNextFallingDrop:            ; was: loc_45716
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Projectile_BackStringerSpawnFallingDropsReturn
                subq.w  #1,$47C(a5)
                move.w  #$318,(a0)
                move.w  #$CD00,2(a0)
                move.w  #$8300,$E(a0)
                move.l  #Projectile_BackStringerFallingDropMapping,8(a0)
                move.b  #4,$20(a0)
                move.b  #$80,$21(a0)
                move.l  #$F404FC04,$28(a0)
                move.w  #2,$24(a0)
                move.w  #$14F,$14(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                addi.w  #$120,d0
                move.w  d0,$10(a0)
                move.w  $10(a0),$5C(a0)
                move.w  $10(a0),$5E(a0)
Projectile_BackStringerSpawnFallingDropsReturn:         ; was: locret_4577A
                                        ; Projectile_BackStringerSpawnFallingDrops+10   j
                rts
; End of function Projectile_BackStringerSpawnFallingDrops
