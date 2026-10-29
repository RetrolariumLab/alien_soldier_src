; Caterpillar wave controller, linked segments, and stage ship states

Boss_CaterpillarMain:                                   ; was: sub_3D0AE
                move.w  4(a5),d0
                movea.w Boss_CaterpillarStateOffsets(pc,d0.w),a0
                adda.l  #Boss_CaterpillarInit,a0
                jmp     (a0)
; End of function Boss_CaterpillarMain
; ---------------------------------------------------------------------------
Boss_CaterpillarStateOffsets:   dc.w    Boss_CaterpillarInit-Boss_CaterpillarInit  ; was: off_3D0BE
                dc.w    Boss_CaterpillarAnimateWave-Boss_CaterpillarInit

; Initializes caterpillar boss entity
Boss_CaterpillarInit:                                   ; was: sub_3D0C2
                                        ; ROM:Boss_CaterpillarStateOffsets   o
                addq.w  #2,4(a5)
                bra.w   Boss_CaterpillarInitSegments
; End of function Boss_CaterpillarInit
; Animates wave pattern for caterpillar movement
Boss_CaterpillarAnimateWave:                            ; was: sub_3D0CA
                addq.w  #4,$56(a5)
                andi.w  #$1FE,$56(a5)
                move.w  $56(a5),d0
                movea.w #(CaterpillarPhaseTable-M68K_RAM),a0
                move.w  #$FFDA,d1
                moveq   #$A,d7
Boss_CaterpillarWriteLeadingPhaseRamp:                  ; was: loc_3D0E2
                move.w  d0,(a0)+
                subq.w  #6,d0
                dbf     d7,Boss_CaterpillarWriteLeadingPhaseRamp
                subi.w  #$10,d0
                moveq   #3,d7
Boss_CaterpillarWritePhasePlateau:                      ; was: loc_3D0F0
                move.w  d0,(a0)+
                dbf     d7,Boss_CaterpillarWritePhasePlateau
                add.w   d1,d0
                moveq   #$17,d7
Boss_CaterpillarWriteMiddlePhasePattern:                ; was: loc_3D0FA
                move.w  d0,(a0)+
                subq.w  #6,d0
                move.w  d0,(a0)+
                subq.w  #6,d0
                move.w  d0,(a0)+
                add.w   d1,d0
                move.w  d0,(a0)+
                add.w   d1,d0
                dbf     d7,Boss_CaterpillarWriteMiddlePhasePattern
                moveq   #9,d7
Boss_CaterpillarWriteTrailingPhaseRamp:                 ; was: loc_3D110
                move.w  d0,(a0)+
                addq.w  #6,d0
                dbf     d7,Boss_CaterpillarWriteTrailingPhaseRamp
                move.w  (SecondaryCameraXPos).w,d0
                subi.w  #$200,d0
                subq.w  #1,d0
                andi.w  #$FFF0,d0
                asr.w   #3,d0
                addi.w  #-$6800,d0
                movea.w d0,a0
                movea.w #(VerticalScrollProfile-M68K_RAM),a1
                lea     (Math_SineTable).l,a2
                move.w  #$1FE,d2
                move.w  #$10,d3
                moveq   #$13,d7
Boss_CaterpillarWriteVisibleWaveOffsets:                ; was: loc_3D142
                move.w  (a0)+,d0
                and.w   d2,d0
                move.w  (a2,d0.w),d1
                ext.l   d1
                asl.l   #6,d1
                swap    d1
                sub.w   d3,d1
                move.w  d1,(a1)+
                dbf     d7,Boss_CaterpillarWriteVisibleWaveOffsets
                rts
; End of function Boss_CaterpillarAnimateWave
; Initializes caterpillar body segments from table
Boss_CaterpillarInitSegments:                           ; was: sub_3D15A
                movea.w a5,a0
                lea     Boss_CaterpillarSegmentDescriptors(pc),a1
                nop
                moveq   #0,d7
                bsr.s   Boss_CaterpillarInitializeSegmentBatch
                lea     $2A0(a0),a0
                moveq   #$D,d7
; End of function Boss_CaterpillarInitSegments
; Initializes a caller-sized batch of consecutive segment records
Boss_CaterpillarInitializeSegmentBatch:                 ; was: sub_3D16C
                                        ; Boss_CaterpillarInitializeSegmentBatch+28   j
                lea     $60(a0),a0
                move.w  #$C300,$E(a0)
                clr.w   4(a0)
                move.w  #$4080,2(a0)
                clr.b   $21(a0)
                move.b  #$20,$20(a0)                    ; ' '
                move.w  (a1)+,(a0)
                move.w  (a1)+,$58(a0)
                move.w  (a1)+,$5A(a0)
                dbf     d7,Boss_CaterpillarInitializeSegmentBatch
                rts
; End of function Boss_CaterpillarInitializeSegmentBatch
; ---------------------------------------------------------------------------
Boss_CaterpillarSegmentDescriptors: dc.w    $288, $3D8, $28  ; was: word_3D19A
                dc.w    $13C, $4D8, $48
                dc.w    $144, $518, $50
                dc.w    $13C, $558, $58
                dc.w    $13C, $5D8, $68
                dc.w    $13C, $658, $78
                dc.w    $144, $6D8, $88
                dc.w    $13C, $758, $98
                dc.w    $140, $7D8, $A8
                dc.w    $144, $818, $B0
                dc.w    $13C, $858, $B8
                dc.w    $144, $898, $C0
                dc.w    $140, $8D8, $C8
                dc.w    $144, $918, $D0
                dc.w    $140, $958, $D8

; Damageable body segment that periodically launches homing projectiles
Boss_CaterpillarHomingProjectileSegment:                ; was: sub_3D1F4
                tst.w   4(a5)
                bne.s   Boss_CaterpillarUpdateHomingProjectileSegment
                addq.w  #2,4(a5)
                move.b  #$80,$4E(a5)
                move.l  #$F010F010,$28(a5)
                move.l  #Boss_CaterpillarHomingProjectileSegmentMapping,8(a5)
                move.w  #$43,$24(a5)                    ; 'C'
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                move.w  d0,$48(a5)
                move.w  #3,$4A(a5)
                clr.w   $4C(a5)
                clr.w   $54(a5)
Boss_CaterpillarUpdateHomingProjectileSegment:          ; was: loc_3D23A
                tst.w   $24(a5)
                bpl.s   Boss_CaterpillarPositionHomingProjectileSegment
                jmp     Boss_CaterpillarSpawnExplosion
; ---------------------------------------------------------------------------
Boss_CaterpillarPositionHomingProjectileSegment:        ; was: loc_3D246
                bsr.w   Boss_CaterpillarPositionSegmentOnWave
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$70,d0                         ; 'p'
                bpl.s   Boss_CaterpillarTryHomingProjectileVolley
                bset    #4,2(a5)
Boss_CaterpillarHomingProjectileSegmentReturn:          ; was: locret_3D25E
                                        ; Boss_CaterpillarHomingProjectileSegment+76   j
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarTryHomingProjectileVolley:              ; was: loc_3D260
                tst.b   $21(a5)
                beq.s   Boss_CaterpillarHomingProjectileSegmentReturn
                subq.w  #1,$48(a5)
                bpl.s   Boss_CaterpillarHomingProjectileSegmentReturn
                subq.w  #1,$4C(a5)
                bpl.s   Boss_CaterpillarHomingProjectileSegmentReturn
                move.w  #4,$4C(a5)
                subq.w  #1,$4A(a5)
                bpl.s   Boss_CaterpillarSpawnHomingProjectile
                move.w  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,$48(a5)
                move.w  #3,$4A(a5)
                move.w  #$FFF8,$54(a5)
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarSpawnHomingProjectile:                  ; was: loc_3D29C
                bsr.w   Boss_CaterpillarFindFreeHomingProjectileSlot
                bne.s   Boss_CaterpillarHomingProjectileSegmentReturn
                move.w  $54(a5),d7
                addq.w  #8,d7
                andi.w  #$18,d7
                cmpi.w  #$18,d7
                bne.s   Boss_CaterpillarInitializeHomingProjectile
                moveq   #8,d7
Boss_CaterpillarInitializeHomingProjectile:             ; was: loc_3D2B4
                move.w  d7,$54(a5)
                move.w  Boss_CaterpillarHomingProjectileParameters(pc,d7.w),d6
                move.w  Boss_CaterpillarHomingProjectileParameters+2(pc,d7.w),d0
                move.w  Boss_CaterpillarHomingProjectileParameters+4(pc,d7.w),d1
                move.w  #$8000,d2
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
                move.l  #$FFFEE000,$18(a0)
                subi.l  #$12000,$50(a0)
                rts
; End of function Boss_CaterpillarHomingProjectileSegment
; ---------------------------------------------------------------------------
Boss_CaterpillarHomingProjectileParameters: dc.w    $C0, $FFF0, $E, 0, $80, 0, $10, 0, $40, $10, $E, 0  ; was: word_3D2E0
                                        ; Boss_CaterpillarHomingProjectileSegment+C8   r

; Damageable body segment with a four-phase mapping cycle
Boss_CaterpillarFourPhaseSegment:                       ; was: sub_3D2F8
                tst.w   4(a5)
                bne.s   Boss_CaterpillarUpdateFourPhaseSegment
                addq.w  #2,4(a5)
                move.b  #$80,$4E(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$58,$24(a5)                    ; 'X'
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                move.w  d0,$48(a5)
                move.w  #8,$4A(a5)
                clr.w   $4C(a5)
Boss_CaterpillarUpdateFourPhaseSegment:                 ; was: loc_3D332
                tst.w   $24(a5)
                bpl.s   Boss_CaterpillarPositionFourPhaseSegment
                jmp     Boss_CaterpillarSpawnExplosion
; ---------------------------------------------------------------------------
Boss_CaterpillarPositionFourPhaseSegment:               ; was: loc_3D33E
                bsr.w   Boss_CaterpillarPositionSegmentOnWave
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$70,d0                         ; 'p'
                bpl.s   Boss_CaterpillarUpdateFourPhaseMapping
                bset    #4,2(a5)
Boss_CaterpillarFourPhaseSegmentReturn:                 ; was: locret_3D356
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarUpdateFourPhaseMapping:                 ; was: loc_3D358
                tst.b   $21(a5)
                beq.s   Boss_CaterpillarFourPhaseSegmentReturn
                subq.w  #1,$48(a5)
                bpl.s   Boss_CaterpillarSelectFourPhaseMapping
                move.w  #$80,$48(a5)
Boss_CaterpillarSelectFourPhaseMapping:                 ; was: loc_3D36A
                move.w  (FrameCounter).w,d0
                andi.w  #$C,d0
                move.l  Boss_CaterpillarFourPhaseSegmentMappings(pc,d0.w),8(a5)
                rts
; End of function Boss_CaterpillarFourPhaseSegment
; ---------------------------------------------------------------------------
Boss_CaterpillarFourPhaseSegmentMappings:   dc.l    Boss_CaterpillarFourPhaseSegmentMappingA  ; was: off_3D37A
                dc.l    Boss_CaterpillarFourPhaseSegmentMappingB
                dc.l    Boss_CaterpillarFourPhaseSegmentMappingC
                dc.l    Boss_CaterpillarFourPhaseSegmentMappingB

; Damageable body segment with a two-phase mapping cycle
Boss_CaterpillarTwoPhaseSegment:                        ; was: sub_3D38A
                tst.w   4(a5)
                bne.s   Boss_CaterpillarUpdateTwoPhaseSegment
                addq.w  #2,4(a5)
                move.b  #$80,$4E(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$6E,$24(a5)                    ; 'n'
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d0
                andi.w  #$F,d0
                move.w  d0,$48(a5)
                move.w  #8,$4A(a5)
                clr.w   $4C(a5)
Boss_CaterpillarUpdateTwoPhaseSegment:                  ; was: loc_3D3C4
                tst.w   $24(a5)
                bpl.s   Boss_CaterpillarPositionTwoPhaseSegment
                jmp     Boss_CaterpillarSpawnExplosion
; ---------------------------------------------------------------------------
Boss_CaterpillarPositionTwoPhaseSegment:                ; was: loc_3D3D0
                bsr.w   Boss_CaterpillarPositionSegmentOnWave
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                cmpi.w  #$70,d0                         ; 'p'
                bpl.s   Boss_CaterpillarUpdateTwoPhaseMapping
                bset    #4,2(a5)
Boss_CaterpillarTwoPhaseSegmentReturn:                  ; was: locret_3D3E8
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarUpdateTwoPhaseMapping:                  ; was: loc_3D3EA
                tst.b   $21(a5)
                beq.s   Boss_CaterpillarTwoPhaseSegmentReturn
                subq.w  #1,$48(a5)
                bpl.s   Boss_CaterpillarSelectTwoPhaseMapping
                nop
Boss_CaterpillarSelectTwoPhaseMapping:                  ; was: loc_3D3F8
                move.w  (FrameCounter).w,d0
                asr.w   #1,d0
                andi.w  #4,d0
                move.l  Boss_CaterpillarTwoPhaseSegmentMappings(pc,d0.w),8(a5)
                rts
; End of function Boss_CaterpillarTwoPhaseSegment
; ---------------------------------------------------------------------------
Boss_CaterpillarTwoPhaseSegmentMappings:    dc.l    Boss_CaterpillarTwoPhaseSegmentMappingA  ; was: off_3D40A
                dc.l    Boss_CaterpillarTwoPhaseSegmentMappingB

; Timed wave segment that becomes the stage ship controller
Boss_CaterpillarShipTransitionSegment:                  ; was: sub_3D412
                tst.w   4(a5)
                bne.s   Boss_CaterpillarUpdateShipTransitionSegment
                addq.w  #2,4(a5)
                move.b  #$80,$4E(a5)
                move.b  #$10,$23(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$1FF,$5C(a5)
                move.l  #Boss_CaterpillarShipTransitionSegmentMapping,8(a5)
Boss_CaterpillarUpdateShipTransitionSegment:            ; was: loc_3D43E
                subq.w  #1,$5C(a5)
                bpl.w   Boss_CaterpillarPositionSegmentOnWave
                move.w  #$294,(a5)
                clr.w   4(a5)
                rts
; End of function Boss_CaterpillarShipTransitionSegment
; Positions a segment from its world-X anchor and phase-buffer offset
Boss_CaterpillarPositionSegmentOnWave:                  ; was: sub_3D450
                                        ; Boss_CaterpillarFourPhaseSegment:Boss_CaterpillarPositionFourPhaseSegment   p
                move.w  $58(a5),d0
                sub.w   (SecondaryCameraXPos).w,d0
                move.w  d0,$10(a5)
                bset    #7,2(a5)
                move.b  $4E(a5),$21(a5)
                cmpi.w  #$70,$10(a5)                    ; 'p'
                bmi.s   Boss_CaterpillarHideSegmentOutsideHorizontalRange
                cmpi.w  #$1E0,$10(a5)
                bmi.s   Boss_CaterpillarApplySegmentWaveHeight
Boss_CaterpillarHideSegmentOutsideHorizontalRange:      ; was: loc_3D478
                bclr    #7,2(a5)
                clr.b   $21(a5)
Boss_CaterpillarApplySegmentWaveHeight:                 ; was: loc_3D482
                movea.w #(CaterpillarPhaseTable-M68K_RAM),a0
                adda.w  $5A(a5),a0
                move.w  (a0)+,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a2
                move.w  (a2,d0.w),d1
                ext.l   d1
                asl.l   #6,d1
                swap    d1
                move.w  #$A8,d2
                sub.w   d1,d2
                move.w  d2,$14(a5)
                rts
; End of function Boss_CaterpillarPositionSegmentOnWave
; Searches primary and extended ranges for a free homing-projectile slot
Boss_CaterpillarFindFreeHomingProjectileSlot:           ; was: sub_3D4AC
                movea.w #(ThirtyFourthEntityType-M68K_RAM),a0
                jmp     Projectile_FindFreeSlotForward20
; End of function Boss_CaterpillarFindFreeHomingProjectileSlot
; Stage ship controller with position-history trail and state dispatch
Boss_CaterpillarShipController:                         ; was: sub_3D4B6
                tst.w   4(a5)
                beq.w   Boss_CaterpillarDispatchShipState
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$4E(a5)
                btst    #1,$4C(a5)
                bne.s   Boss_CaterpillarUpdateShipTrailHistory
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_CaterpillarUpdateShipTrailHistory
                tst.w   (BossHealth).w
                bne.s   Boss_CaterpillarUpdateShipTrailHistory
                move.b  #2,(BossColorEffectFlags).w
                move.w  #$A,4(a5)
Boss_CaterpillarUpdateShipTrailHistory:                 ; was: loc_3D4EC
                                        ; Boss_CaterpillarShipController+22   j
                lea     (SharedScratchLong8).w,a0
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                swap    d0
                move.w  $14(a5),d0
                move.w  #6,d7
Boss_CaterpillarShiftNextShipTrailBlock:                ; was: loc_3D502
                move.w  (SharedScratchLong3+2).w,d6
                subq.w  #1,d6
Boss_CaterpillarShiftShipTrailHistory:                  ; was: loc_3D508
                move.l  (a0),d1
                move.l  d0,(a0)+
                move.l  d1,d0
                dbf     d6,Boss_CaterpillarShiftShipTrailHistory
                dbf     d7,Boss_CaterpillarShiftNextShipTrailBlock
                move.w  #6,d7
                lea     (SharedScratchLong8).w,a1
                lea     $60(a5),a0
                move.w  (SharedScratchLong3+2).w,d6
                add.w   d6,d6
                add.w   d6,d6
Boss_CaterpillarPositionShipTrailParts:                 ; was: loc_3D52A
                lea     (a1,d6.w),a1
                move.w  (a1),d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a0)
                move.w  2(a1),$14(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_CaterpillarPositionShipTrailParts
Boss_CaterpillarDispatchShipState:                      ; was: loc_3D546
                move.w  4(a5),d0
                lea     Boss_CaterpillarShipStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_CaterpillarShipController
; ---------------------------------------------------------------------------
Boss_CaterpillarShipStateOffsets:   dc.w    Boss_CaterpillarShipInit-*  ; was: off_3D552
                dc.w    Boss_CaterpillarShipBeginOscillationState-*
                dc.w    Boss_CaterpillarShipOscillationState-*
                dc.w    Boss_CaterpillarShipCenteringDelayState-*
                dc.w    Boss_CaterpillarShipRotationState-*
                dc.w    Boss_CaterpillarShipBeginDefeatState-*
                dc.w    Boss_CaterpillarShipDismantlePartsState-*
                dc.w    Boss_CaterpillarShipDefeatCompleteState-*

; Initializes caterpillar ship with body parts
Boss_CaterpillarShipInit:                               ; was: sub_3D562
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_CaterpillarShipInitReturn
                addq.w  #2,4(a5)
                move.w  #6,(SharedScratchLong3+2).w
                move.w  #$C,(SharedScratchLong3).w
                move.w  #$170,(SharedScratchLong2).w
                move.w  #$100,(SharedScratchLong2+2).w
                move.w  #$4000,(BossMaxHealth).w
                move.w  #$4000,(BossHealth).w
                move.w  #$CD00,2(a5)
                move.b  #$10,$20(a5)
                move.b  #$50,$21(a5)                    ; 'P'
                move.b  #$10,$23(a5)
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$28,$24(a5)                    ; '('
                move.w  #$80,$26(a5)
                move.b  #6,(BossColorEffectFlags).w
                move.w  #6,d7
                lea     $60(a5),a0
Boss_CaterpillarInitializeShipTrailPart:                ; was: loc_3D5D4
                move.w  #$10,(a0)
                move.l  #Boss_CaterpillarShipTrailMappingA,8(a0)
                move.w  #$E45A,$E(a0)
                move.w  #$8D00,2(a0)
                move.w  #$80,$26(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.b  #$10,$20(a0)
                move.w  #$14,$24(a0)
                btst    #0,d7
                bne.s   Boss_CaterpillarAdvanceShipTrailPart
                move.b  #$50,$21(a0)                    ; 'P'
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F010F010,$28(a0)
Boss_CaterpillarAdvanceShipTrailPart:                   ; was: loc_3D626
                lea     $60(a0),a0
                dbf     d7,Boss_CaterpillarInitializeShipTrailPart
Boss_CaterpillarShipInitReturn:                         ; was: locret_3D62E
                rts
; End of function Boss_CaterpillarShipInit
; Enables the ship root and prepares its alternating horizontal targets
Boss_CaterpillarShipBeginOscillationState:              ; was: sub_3D630
                bsr.w   Boss_CaterpillarUpdateShipSteering
                move.b  #$80,$23(a5)
                clr.b   (BossColorEffectFlags).w
                clr.w   $4A(a5)
                move.w  #$220,(SharedScratchLong2).w
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; Alternates horizontal steering targets until the stage-scroll threshold
; is reached
Boss_CaterpillarShipOscillationState:                   ; was: sub_3D654
                bsr.w   Boss_CaterpillarUpdateShipSteering
                cmpi.w  #$880,(SecondaryCameraXPos).w
                bcc.s   Boss_CaterpillarBeginShipCenteringDelay
                subq.w  #1,$48(a5)
                bne.s   Boss_CaterpillarShipOscillationReturn
                eori.w  #1,$4A(a5)
                beq.s   Boss_CaterpillarSelectRightOscillationTarget
                move.w  #$100,$48(a5)
                move.w  #$C0,(SharedScratchLong2).w
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarSelectRightOscillationTarget:           ; was: loc_3D67C
                move.w  #$100,$48(a5)
                move.w  #$220,(SharedScratchLong2).w
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarBeginShipCenteringDelay:                ; was: loc_3D68A
                clr.w   (BossHealth).w
                clr.w   (BossMaxHealth).w
                clr.b   $21(a5)
                move.w  #$120,(SharedScratchLong2).w
                move.w  #$F0,(SharedScratchLong2+2).w
                bset    #1,$4C(a5)
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_CaterpillarShipOscillationReturn:                  ; was: locret_3D6B2
                rts
; Steers toward the center target until the transition delay expires
Boss_CaterpillarShipCenteringDelayState:                ; was: sub_3D6B4
                bsr.w   Boss_CaterpillarUpdateShipSteering
                subq.w  #1,$48(a5)
                bne.s   Boss_CaterpillarShipCenteringDelayReturn
                move.w  #$40,(SharedScratchLong2).w     ; '@'
                move.w  #$80,(SharedScratchLong2+2).w
                addq.w  #2,4(a5)
                addq.w  #3,(SharedScratchLong3).w
Boss_CaterpillarShipCenteringDelayReturn:               ; was: locret_3D6D2
                rts
; End of function Boss_CaterpillarShipCenteringDelayState
; Applies steering without an internal state transition
Boss_CaterpillarShipRotationState:                      ; was: sub_3D6D4
                bsr.w   Boss_CaterpillarUpdateShipSteering
                rts
; End of function Boss_CaterpillarShipRotationState
; Starts the defeat sequence and optionally drops a pickup at the ship root
Boss_CaterpillarShipBeginDefeatState:                   ; was: sub_3D6DA
                bsr.w   Boss_CaterpillarUpdateShipSteering
                jsr     (Effect_SpawnExplosionB).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                andi.w  #$7FFF,2(a5)
                move.w  #$10,$48(a5)
                move.w  a5,$4A(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_CaterpillarShipBeginDefeatReturn
                move.w  #3,d0
                jsr     (Pickup_SelectRandomSize).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
Boss_CaterpillarShipBeginDefeatReturn:                  ; was: locret_3D724
                rts
; End of function Boss_CaterpillarShipBeginDefeatState
; Converts one linked trail part at a time into an explosion and reward drop
Boss_CaterpillarShipDismantlePartsState:                ; was: sub_3D726
                bsr.w   Boss_CaterpillarUpdateShipSteering
                subq.w  #1,$48(a5)
                bne.s   Boss_CaterpillarShipDismantlePartsReturn
                movea.w $4A(a5),a0
                lea     $60(a0),a0
                move.l  #Effect_SpriteAnimation00,8(a0)
                jsr     (Projectile_InitType88).l
                lea     $2A0(a5),a1
                cmpa.w  a1,a0
                bhi.s   Boss_CaterpillarCompleteShipDefeat
                move.w  a0,$4A(a5)
                move.w  #$A,$48(a5)
                movea.w a0,a4
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_CaterpillarShipDismantlePartsReturn
                move.w  #3,d0
                jsr     (Pickup_SelectRandomSize).l
                move.w  $10(a4),$10(a0)
                move.w  $14(a4),$14(a0)
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_CaterpillarShipDismantlePartsReturn:               ; was: locret_3D782
                                        ; Boss_CaterpillarShipDismantlePartsState+3A   j
                rts
; ---------------------------------------------------------------------------
Boss_CaterpillarCompleteShipDefeat:                     ; was: loc_3D784
                addq.w  #2,4(a5)
                rts
; End of function Boss_CaterpillarShipDismantlePartsState
Boss_CaterpillarShipDefeatCompleteState:                ; was: nullsub_79
                rts
; End of function Boss_CaterpillarShipDefeatCompleteState

; Steers the ship angle toward its target and derives polar velocity
Boss_CaterpillarUpdateShipSteering:                     ; was: sub_3D78C
                                        ; Boss_CaterpillarShipOscillationState   p
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_CaterpillarApplyShipPolarVelocity
                move.w  (SharedScratchLong2).w,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  (SharedScratchLong2+2).w,d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                move.w  (SharedScratchLong0).w,d1
                addi.w  #$100,d1
                sub.w   d2,d1
                andi.w  #$1FF,d1
                cmpi.w  #$100,d1
                beq.s   Boss_CaterpillarApplyShipPolarVelocity
                cmpi.w  #$100,d1
                bcs.s   Boss_CaterpillarSetNegativeShipAngularStep
                move.w  #8,(SharedScratchLong0+2).w
                bra.s   Boss_CaterpillarApplyShipPolarVelocity
; ---------------------------------------------------------------------------
Boss_CaterpillarSetNegativeShipAngularStep:             ; was: loc_3D7D2
                move.w  #$FFF8,(SharedScratchLong0+2).w
Boss_CaterpillarApplyShipPolarVelocity:                 ; was: loc_3D7D8
                                        ; Boss_CaterpillarUpdateShipSteering+36   j
                move.w  (SharedScratchLong0+2).w,d0
                add.w   d0,(SharedScratchLong0).w
                andi.w  #$1FF,(SharedScratchLong0).w
                move.w  (SharedScratchLong0).w,d0
                addi.w  #$100,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d0.w),d1
                move.w  (a1,d0.w),d0
                move.w  (SharedScratchLong3).w,d2
                muls.w  d2,d0
                muls.w  d2,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                rts
; End of function Boss_CaterpillarUpdateShipSteering
Boss_CaterpillarUnusedNoOp:                             ; was: nullsub_80
                rts
; End of function Boss_CaterpillarUnusedNoOp
