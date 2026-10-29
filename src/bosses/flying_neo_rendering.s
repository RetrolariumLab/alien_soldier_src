Boss_FlyingNeoHoverDecisionState:                       ; DATA XREF: ROM:0003C0C6   o  ; was: sub_3C7B2
                subq.w  #1,$1DE(a5)
                bpl.s   Boss_FlyingNeoUpdateHoverDecisionPose
                move.w  (RandomNumberState).w,d0
                andi.w  #1,d0
                beq.w   Boss_FlyingNeoBeginPartAnchorState
                bra.w   Boss_FlyingNeoBeginPursuitState
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateHoverDecisionPose:                  ; CODE XREF: Boss_FlyingNeoHoverDecisionState+4   j  ; was: loc_3C7C8
                lea     Boss_FlyingNeoNeutralPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bra.w   Boss_FlyingNeoUpdateSprites
; ---------------------------------------------------------------------------
Boss_FlyingNeoBeginRisingRetreatState:                  ; CODE XREF: Boss_FlyingNeoSelectCloseRangeManeuver+14   j  ; was: loc_3C7D6
                move.w  #$20,4(a5)                      ; ' '
                move.l  #$FFFD0000,$1C(a5)
                clr.w   6(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Rises while moving opposite the pursuit direction
Boss_FlyingNeoRisingRetreatState:                       ; DATA XREF: ROM:0003C0C8   o  ; was: loc_3C7F2
                cmpi.w  #$A0,$14(a5)
                bmi.s   Boss_FlyingNeoBeginDivingArcState
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoSetRisingRetreatRightVelocity
                cmpi.l  #$FFFDE000,$18(a5)
                bmi.s   Boss_FlyingNeoStoreRisingRetreatLeftVelocity
                addi.l  #-$2200,$18(a5)
Boss_FlyingNeoStoreRisingRetreatLeftVelocity:           ; CODE XREF: Boss_FlyingNeoRisingRetreatState+E   j  ; was: loc_3C812
                move.l  #$FFFDE000,$18(a5)
                bra.s   Boss_FlyingNeoRenderRisingRetreat
; ---------------------------------------------------------------------------
Boss_FlyingNeoSetRisingRetreatRightVelocity:            ; CODE XREF: Boss_FlyingNeoRisingRetreatState+8   j  ; was: loc_3C81C
                cmpi.l  #$22000,$18(a5)
                bpl.s   Boss_FlyingNeoStoreRisingRetreatRightVelocity
                addi.l  #$2200,$18(a5)
Boss_FlyingNeoStoreRisingRetreatRightVelocity:          ; CODE XREF: Boss_FlyingNeoSetRisingRetreatRightVelocity+6   j  ; was: loc_3C82E
                move.l  #$22000,$18(a5)
Boss_FlyingNeoRenderRisingRetreat:                      ; CODE XREF: Boss_FlyingNeoRisingRetreatState+18   j  ; was: loc_3C836
                lea     Boss_FlyingNeoRisingRetreatPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bsr.w   Boss_FlyingNeoUpdateSprites
                move.l  #Boss_FlyingNeoAuxiliaryPartMappingB,$3C8(a5)
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoBeginDivingArcState:                      ; CODE XREF: Boss_FlyingNeoRisingRetreatState+6   j  ; was: loc_3C84E
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                move.w  #$E000,$11C(a5)
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoDivingArcState
                neg.w   $11C(a5)
; Accelerates down and across the arena along the first half of the arc
Boss_FlyingNeoDivingArcState:                           ; CODE XREF: Boss_FlyingNeoRisingRetreatState:Boss_FlyingNeoBeginDivingArcState   j  ; was: loc_3C870
                                        ; DATA XREF: ROM:0003C0CA   o
                cmpi.w  #$D8,$14(a5)
                bpl.s   Boss_FlyingNeoBeginRisingArcState
                move.w  $11C(a5),d0
                ext.l   d0
                add.l   d0,$18(a5)
                cmpi.l  #$40000,$1C(a5)
                bpl.s   Boss_FlyingNeoUpdateDivingArcSound
                addi.l  #$4800,$1C(a5)
Boss_FlyingNeoUpdateDivingArcSound:                     ; CODE XREF: Boss_FlyingNeoDivingArcState+12   j  ; was: loc_3C894
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_FlyingNeoSelectDivingArcPose
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_FlyingNeoSelectDivingArcPose:                      ; CODE XREF: Boss_FlyingNeoDivingArcState+20   j  ; was: loc_3C8A8
                lea     Boss_FlyingNeoDivingArcPoses(pc),a1
                nop
Boss_FlyingNeoRenderArc:                                ; CODE XREF: Boss_FlyingNeoRisingArcState+38   j  ; was: loc_3C8AE
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bsr.w   Boss_FlyingNeoUpdateSprites
                move.l  #Boss_FlyingNeoAuxiliaryPartMappingA,$3C8(a5)
                move.l  #Boss_FlyingNeoAnchorPartMappingA,d0
                move.l  #Boss_FlyingNeoAnchorPartMappingB,d1
                cmpi.w  #2,6(a5)
                bpl.s   Boss_FlyingNeoStoreArcPartMappings
                exg     d0,d1
Boss_FlyingNeoStoreArcPartMappings:                     ; CODE XREF: Boss_FlyingNeoRenderArc+16   j  ; was: loc_3C8D4
                move.l  d0,$1E8(a5)
                move.l  d1,$368(a5)
                rts
; ---------------------------------------------------------------------------
Boss_FlyingNeoBeginRisingArcState:                      ; CODE XREF: Boss_FlyingNeoDivingArcState+6   j  ; was: loc_3C8DE
                addq.w  #2,4(a5)
                move.w  $11C(a5),d0
                asl.w   #1,d0
                move.w  d0,$11C(a5)
; Reverses vertical acceleration and completes the second half of the arc
Boss_FlyingNeoRisingArcState:                           ; DATA XREF: ROM:0003C0CC   o  ; was: loc_3C8EC
                cmpi.w  #$B8,$14(a5)
                bpl.s   Boss_FlyingNeoUpdateRisingArcMotion
                move.w  #$1A,4(a5)
                move.w  #2,$17E(a5)
                clr.w   $1DC(a5)
                bra.w   Boss_FlyingNeoSetNeutralPartAnchors
; ---------------------------------------------------------------------------
Boss_FlyingNeoUpdateRisingArcMotion:                    ; CODE XREF: Boss_FlyingNeoRisingArcState+6   j  ; was: loc_3C908
                move.w  $11C(a5),d0
                ext.l   d0
                sub.l   d0,$18(a5)
                cmpi.l  #$FFFD8000,$1C(a5)
                bmi.s   Boss_FlyingNeoSelectRisingArcPose
                subi.l  #$4800,$1C(a5)
Boss_FlyingNeoSelectRisingArcPose:                      ; CODE XREF: Boss_FlyingNeoUpdateRisingArcMotion+12   j  ; was: loc_3C924
                lea     Boss_FlyingNeoRisingArcPoseCommands(pc),a1
                nop
                bra.w   Boss_FlyingNeoRenderArc
; ---------------------------------------------------------------------------
Boss_FlyingNeoBeginPartAnchorState:                     ; CODE XREF: Boss_FlyingNeoHoverDecisionState+E   j  ; was: loc_3C92E
                move.w  #$26,4(a5)                      ; '&'
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   6(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
; Binds the body to one of two linked part records until its launch boundary
Boss_FlyingNeoPartAnchorState:                          ; DATA XREF: ROM:0003C0CE   o  ; was: loc_3C94A
                tst.w   $54(a5)
                bne.s   Boss_FlyingNeoCheckAlternatePartAnchorBoundary
                cmpi.w  #$FA0,$BC(a5)
                bpl.s   Boss_FlyingNeoSelectPartAnchorRecord
Boss_FlyingNeoLaunchFromPartAnchor:                     ; CODE XREF: Boss_FlyingNeoPartAnchorState+2E   j  ; was: loc_3C958
                move.l  #$12000,$1C(a5)
                move.l  #$12000,$18(a5)
                tst.w   $54(a5)
                beq.w   Boss_FlyingNeoBeginHorizontalSwoopState
                neg.l   $18(a5)
                bra.w   Boss_FlyingNeoBeginHorizontalSwoopState
; ---------------------------------------------------------------------------
Boss_FlyingNeoCheckAlternatePartAnchorBoundary:         ; CODE XREF: Boss_FlyingNeoPartAnchorState+4   j  ; was: loc_3C978
                cmpi.w  #$1000,$BC(a5)
                bpl.w   Boss_FlyingNeoLaunchFromPartAnchor
Boss_FlyingNeoSelectPartAnchorRecord:                   ; CODE XREF: Boss_FlyingNeoPartAnchorState+C   j  ; was: loc_3C982
                movea.w #(SixthEntityType-M68K_RAM),a0
                movea.w #(TenthEntityType-M68K_RAM),a1
                cmpi.w  #5,6(a5)
                bmi.s   Boss_FlyingNeoBindPartAnchorRecord
                exg     a0,a1
Boss_FlyingNeoBindPartAnchorRecord:                     ; CODE XREF: Boss_FlyingNeoSelectPartAnchorRecord+C   j  ; was: loc_3C994
                move.w  a0,$48(a5)
                move.w  a0,$4A(a5)
                move.w  (PrimaryCameraYPosition).w,d0
                addi.w  #$BC,d0
                move.w  d0,$14(a0)
                lea     Boss_FlyingNeoPartAnchorPoses(pc),a1
                nop
                bsr.w   Boss_FlyingNeoUpdatePoseAnimation
                bsr.w   Boss_FlyingNeoUpdateSprites
                movea.w #(SixthEntityType-M68K_RAM),a0
                bsr.s   Boss_FlyingNeoUpdatePartAnchorMapping
                movea.w #(TenthEntityType-M68K_RAM),a0
; End of function Boss_FlyingNeoHoverDecisionState
; Selects one of two mappings for a linked anchor part from its Y position
Boss_FlyingNeoUpdatePartAnchorMapping:                  ; CODE XREF: Boss_FlyingNeoHoverDecisionState+208   p  ; was: sub_3C9C0
                move.l  #Boss_FlyingNeoAnchorPartMappingA,8(a0)
                move.w  (PrimaryCameraYPosition).w,d0
                addi.w  #$B2,d0
                cmp.w   $14(a0),d0
                bmi.s   Boss_FlyingNeoUpdatePartAnchorMappingReturn
                move.l  #Boss_FlyingNeoAnchorPartMappingB,8(a0)
Boss_FlyingNeoUpdatePartAnchorMappingReturn:            ; CODE XREF: Boss_FlyingNeoUpdatePartAnchorMapping+14   j  ; was: locret_3C9DE
                rts
; End of function Boss_FlyingNeoUpdatePartAnchorMapping
; Returns the player's deltas from the tracked part, then restores the boss pointer
Boss_FlyingNeoGetTrackedPartPlayerDelta:                ; CODE XREF: Boss_FlyingNeoPursuitState+C   p  ; was: sub_3C9E0
                movea.w #(TwelfthEntityType-M68K_RAM),a5
                jsr     (Physics_GetPlayerDelta).l
                movea.w #(Entity_ObjectPool-M68K_RAM),a5
                rts
; End of function Boss_FlyingNeoGetTrackedPartPlayerDelta
; Updates boss sprite positions and rendering
Boss_FlyingNeoUpdateSprites:                            ; CODE XREF: Boss_FlyingNeoIntroDelayState+14   j  ; was: sub_3C9F0
                                        ; Boss_FlyingNeoPlayerControlled+76   j
                move.w  #$E,$A0(a5)
                move.w  #$1C,$A4(a5)
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoUpdateMetasprite
                move.w  #$10,$A0(a5)
; Updates metasprite angles and linked positions
Boss_FlyingNeoUpdateMetasprite:                         ; CODE XREF: Boss_FlyingNeoUpdateSprites+10   j  ; was: loc_3CA08
                clr.w   $40(a5)
                clr.w   $44(a5)
                movea.w #(TertiaryEntityType-M68K_RAM),a4
                movea.w a5,a3
                moveq   #7,d7
                move.w  #8,(MetaspritePartCountM1).w
                jsr     (Sprite_UpdateMetaspriteEightFrameRotation).l
                bsr.w   Boss_FlyingNeoBuildLineScrollTables
                bsr.w   Boss_FlyingNeoUpdateOrbitAngularImpulse
                bsr.w   Boss_FlyingNeoUpdateLinkedPartOrbits
                bra.w   Boss_FlyingNeoQueueAnimatedTileRowTransfer
; End of function Boss_FlyingNeoUpdateSprites
; ---------------------------------------------------------------------------
Boss_FlyingNeoPartPositionOffsetCycle:  dc.b    4, $FE, 3, $FF, 2, 0, 3, 0  ; was: byte_3CA34
                                        ; DATA XREF: Boss_FlyingNeoUpdateLinkedPartOrbits:Boss_FlyingNeoPositionAuxiliaryParts   o

; Updates auxiliary positions, angle history, and eight linked-part orbits
Boss_FlyingNeoUpdateLinkedPartOrbits:                   ; CODE XREF: Boss_FlyingNeoUpdateSprites+3C   p  ; was: sub_3CA3C
                move.l  #Boss_FlyingNeoAuxiliaryPartMappingA,$3C8(a5)
                move.w  (FrameCounter).w,d0
                btst    #7,d0
                beq.s   Boss_FlyingNeoPositionAuxiliaryParts
                btst    #3,d0
                beq.s   Boss_FlyingNeoPositionAuxiliaryParts
                move.l  #Boss_FlyingNeoAuxiliaryPartMappingB,$3C8(a5)
Boss_FlyingNeoPositionAuxiliaryParts:                   ; CODE XREF: Boss_FlyingNeoUpdateLinkedPartOrbits+10   j  ; was: loc_3CA5C
                                        ; Boss_FlyingNeoUpdateLinkedPartOrbits+16   j
                lea     Boss_FlyingNeoPartPositionOffsetCycle(pc),a0
                move.w  (FrameCounter).w,d0
                andi.w  #6,d0
                move.b  (a0,d0.w),d4
                move.b  1(a0,d0.w),d5
                ext.w   d4
                ext.w   d5
                movea.w #(EleventhEntityType-M68K_RAM),a0
                moveq   #$FFFFFFD2,d0
                moveq   #$16,d1
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoStoreFirstAuxiliaryPartPosition
                moveq   #$4C,d0                         ; 'L'
                neg.w   d4
Boss_FlyingNeoStoreFirstAuxiliaryPartPosition:          ; CODE XREF: Boss_FlyingNeoUpdateLinkedPartOrbits+44   j  ; was: loc_3CA86
                add.w   d4,d0
                add.w   d5,d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                movea.w #(TwelfthEntityType-M68K_RAM),a0
                moveq   #$32,d0                         ; '2'
                moveq   #$A,d1
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoStoreTrackedPartPosition
                moveq   #$FFFFFFEE,d0
Boss_FlyingNeoStoreTrackedPartPosition:                 ; CODE XREF: Boss_FlyingNeoUpdateLinkedPartOrbits+6A   j  ; was: loc_3CAAA
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                movea.w #(FlyingNeoAngleHistory-M68K_RAM),a0
                movea.w #(FlyingNeoAngleHistory-M68K_RAM),a1
                moveq   #$23,d7                         ; '#'
                move.w  $23E(a5),d0
Boss_FlyingNeoShiftAngleHistory:                        ; CODE XREF: Boss_FlyingNeoUpdateLinkedPartOrbits+92   j  ; was: loc_3CAC8
                move.w  (a1),d1
                move.w  d0,(a1)+
                move.w  d1,d0
                dbf     d7,Boss_FlyingNeoShiftAngleHistory
                movea.w #(TwelfthEntityType-M68K_RAM),a0
                movea.w #(ThirteenthEntityType-M68K_RAM),a1
                movea.w #(FlyingNeoAngleTapBase-M68K_RAM),a2
                movea.w #(FlyingNeoSineTable-M68K_RAM),a3
                movea.w #(FlyingNeoCosineTable-M68K_RAM),a4
                move.w  $54(a5),d4
                asl.w   #1,d4
                move.w  #$3FC,d5
                moveq   #$1C,d6
                moveq   #7,d7
Boss_FlyingNeoUpdateNextLinkedPartOrbit:                ; CODE XREF: Boss_FlyingNeoAdvanceLinkedPartOrbitPointers+C   j  ; was: loc_3CAF4
                move.w  (a2),d0
                beq.s   Boss_FlyingNeoApplyLinkedPartAngularStep
                bpl.s   Boss_FlyingNeoReducePositiveAngularStep
                add.w   d6,d0
                bra.s   Boss_FlyingNeoApplyLinkedPartAngularStep
; ---------------------------------------------------------------------------
Boss_FlyingNeoReducePositiveAngularStep:                ; CODE XREF: Boss_FlyingNeoUpdateNextLinkedPartOrbit+4   j  ; was: loc_3CAFE
                sub.w   d6,d0
Boss_FlyingNeoApplyLinkedPartAngularStep:               ; CODE XREF: Boss_FlyingNeoUpdateNextLinkedPartOrbit+2   j  ; was: loc_3CB00
                                        ; Boss_FlyingNeoUpdateNextLinkedPartOrbit+8   j
                add.w   d0,$56(a1)
                move.w  $56(a1),d0
                move.w  d0,d1
                add.w   d4,d0
                and.w   d5,d0
                and.w   d5,d1
                move.l  (a3,d1.w),d3
                move.l  (a4,d0.w),d2
                add.l   $10(a0),d2
                add.l   $14(a0),d3
                move.l  d2,$10(a1)
                move.l  d3,$14(a1)
                tst.w   d6
                beq.s   Boss_FlyingNeoAdvanceLinkedPartOrbitPointers
                subq.w  #4,d6
; Advances the source, destination, and per-part angular-step pointers
Boss_FlyingNeoAdvanceLinkedPartOrbitPointers:           ; CODE XREF: Boss_FlyingNeoUpdateLinkedPartOrbits+EE   j  ; was: loc_3CB2E
                lea     $60(a0),a0
                lea     $60(a1),a1
                adda.w  #8,a2
                dbf     d7,Boss_FlyingNeoUpdateNextLinkedPartOrbit
Boss_FlyingNeoUpdateLinkedPartOrbitsReturn:             ; CODE XREF: Boss_FlyingNeoUpdatePaletteFade+8   j  ; was: locret_3CB3E
                rts
; End of function Boss_FlyingNeoUpdateLinkedPartOrbits
; Updates palette fade effect for boss
Boss_FlyingNeoUpdatePaletteFade:                        ; CODE XREF: Boss_FlyingNeoDefeatConvertForwardSlotRangeState   p  ; was: sub_3CB40
                                        ; sub_3C3AE   p
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_FlyingNeoUpdateLinkedPartOrbitsReturn
                lea     (PaletteFade_FlyingNeoEntryOffsets).l,a2
                lea     Boss_FlyingNeoDefeatPaletteFadeParameters(pc),a3
                nop
                jmp     (Gfx_StepPaletteEntriesToTargetList).l
; End of function Boss_FlyingNeoUpdatePaletteFade
; ---------------------------------------------------------------------------
Boss_FlyingNeoDefeatPaletteFadeParameters:  dc.w    2, $CEE, 0, 0, $866, $200, $422, 6, $2A, $26E  ; was: word_3CB5C
                                        ; DATA XREF: Boss_FlyingNeoUpdatePaletteFade+10   o
                dc.w    $24, $268, $6AC

; Fills eight linked-part angles from d0 and clears their 36-word history
Boss_FlyingNeoFillPartAnglesAndClearHistory:
                movea.w #(ThirteenthEntityType-M68K_RAM),a0  ; was: sub_3CB76
                moveq   #7,d7
Boss_FlyingNeoFillNextPartAngle:                        ; CODE XREF: Boss_FlyingNeoFillPartAnglesAndClearHistory+E   j  ; was: loc_3CB7C
                move.w  d0,$56(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_FlyingNeoFillNextPartAngle
                movea.w #(FlyingNeoAngleHistory-M68K_RAM),a0
                moveq   #$23,d7                         ; '#'
                moveq   #0,d1
Boss_FlyingNeoClearNextAngleHistoryWord:                ; CODE XREF: Boss_FlyingNeoFillPartAnglesAndClearHistory+1C   j  ; was: loc_3CB90
                move.w  d1,(a0)+
                dbf     d7,Boss_FlyingNeoClearNextAngleHistoryWord
                rts
; End of function Boss_FlyingNeoFillPartAnglesAndClearHistory
; Builds the vertical and horizontal line-scroll tables around Flying Neo
Boss_FlyingNeoBuildLineScrollTables:                    ; CODE XREF: Boss_FlyingNeoDefeatConvertForwardSlotRangeState+8   p  ; was: sub_3CB98
                                        ; Boss_FlyingNeoDefeatConvertReverseSlotRangeState+8   p
                cmpi.w  #$FE,$14(a5)
                bmi.s   Boss_FlyingNeoBuildVerticalScrollRamp
                move.w  #$FE,$14(a5)
Boss_FlyingNeoBuildVerticalScrollRamp:                  ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+6   j  ; was: loc_3CBA6
                movea.w #(FlyingNeoVScrollRamp-M68K_RAM),a0
                moveq   #0,d0
                move.w  (PrimaryCameraYPosition).w,d7
                subi.w  #$60,d7                         ; '`'
                asr.w   #3,d7
                moveq   #7,d6
                sub.w   d7,d6
                addi.w  #$F,d7
Boss_FlyingNeoWriteVerticalScrollRamp:                  ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+2A   j  ; was: loc_3CBBE
                move.w  d0,(a0)+
                subq.w  #8,d0
                dbf     d7,Boss_FlyingNeoWriteVerticalScrollRamp
                move.w  (PrimaryCameraYPosition).w,d0
                neg.w   d0
Boss_FlyingNeoFillVerticalScrollRampTail:               ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+36   j  ; was: loc_3CBCC
                move.w  d0,(a0)+
                dbf     d6,Boss_FlyingNeoFillVerticalScrollRampTail
                moveq   #8,d7
                move.w  $14(a5),d0
                subi.w  #$C0,d0
                andi.w  #$FFF8,d0
                asr.w   #2,d0
                bpl.s   Boss_FlyingNeoOffsetVerticalScrollBandStart
                asr.w   #1,d0
                add.w   d0,d7
                bmi.s   Boss_FlyingNeoBuildHorizontalScrollTable
                move.w  #$9506,d0
                bra.s   Boss_FlyingNeoWriteBossVerticalScrollBand
; ---------------------------------------------------------------------------
Boss_FlyingNeoOffsetVerticalScrollBandStart:            ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+4A   j  ; was: loc_3CBF0
                addi.w  #-$6AFA,d0
Boss_FlyingNeoWriteBossVerticalScrollBand:              ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+56   j  ; was: loc_3CBF4
                movea.w d0,a0
                moveq   #$58,d0                         ; 'X'
                sub.w   $14(a5),d0
Boss_FlyingNeoWriteNextBossVerticalScrollValue:         ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+66   j  ; was: loc_3CBFC
                move.w  d0,(a0)+
                dbf     d7,Boss_FlyingNeoWriteNextBossVerticalScrollValue
Boss_FlyingNeoBuildHorizontalScrollTable:               ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+50   j  ; was: loc_3CC02
                movea.w #(HScrollPlaneBRow2-M68K_RAM),a0
                move.w  (PrimaryCameraYPosition).w,d7
                subi.w  #$60,d7                         ; '`'
                bpl.s   Boss_FlyingNeoSelectBossHorizontalScrollValue
                moveq   #0,d7
Boss_FlyingNeoSelectBossHorizontalScrollValue:          ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+76   j  ; was: loc_3CC12
                addi.w  #$9C,d7
                move.w  #$120,d0
                add.w   $10(a5),d0
                cmpi.w  #$200,$10(a5)
                bpl.s   Boss_FlyingNeoSelectEdgeHorizontalScrollValue
                cmpi.w  #$28,$10(a5)                    ; '('
                bpl.s   Boss_FlyingNeoFillBossHorizontalScrollRegion
Boss_FlyingNeoSelectEdgeHorizontalScrollValue:          ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+8C   j  ; was: loc_3CC2E
                move.w  #$148,d0
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoFillBossHorizontalScrollRegion
                move.w  #$118,d0
Boss_FlyingNeoFillBossHorizontalScrollRegion:           ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+94   j  ; was: loc_3CC3C
                                        ; Boss_FlyingNeoBuildLineScrollTables+9E   j
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Boss_FlyingNeoFillBossHorizontalScrollRegion
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
Boss_FlyingNeoFillPlaneHorizontalScrollRegion:          ; CODE XREF: Boss_FlyingNeoBuildLineScrollTables+BA   j  ; was: loc_3CC4A
                move.w  d0,(a0)
                addq.w  #4,a0
                cmpa.w  #$E78A,a0
                bmi.s   Boss_FlyingNeoFillPlaneHorizontalScrollRegion
                rts
; End of function Boss_FlyingNeoBuildLineScrollTables
; Fills a 28-word row with tile $193 and queues its transfer
Boss_FlyingNeoQueueFixedTileRowTransfer:                ; CODE XREF: Boss_FlyingNeoDefeatLaunchType88PartState+1C   p  ; was: sub_3CC56
                movea.w (VDPStagingDataCursor).w,a0
                moveq   #$1B,d7
Boss_FlyingNeoFillFixedTileRow:                         ; CODE XREF: Boss_FlyingNeoQueueFixedTileRowTransfer+A   j  ; was: loc_3CC5C
                move.w  #$193,(a0)+
                dbf     d7,Boss_FlyingNeoFillFixedTileRow
                bra.s   Boss_FlyingNeoQueueTileRowTransfer
; ---------------------------------------------------------------------------
Boss_FlyingNeoQueueAnimatedTileRowTransfer:             ; CODE XREF: Boss_FlyingNeoUpdateSprites+40   j  ; was: loc_3CC66
                movea.w (VDPStagingDataCursor).w,a0
                moveq   #$1B,d7
                lea     Boss_FlyingNeoTileRowPatternA(pc),a1
                nop
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_FlyingNeoSelectTileRowFacingHalf
                lea     Boss_FlyingNeoTileRowPatternB(pc),a1
                nop
Boss_FlyingNeoSelectTileRowFacingHalf:                  ; CODE XREF: Boss_FlyingNeoQueueAnimatedTileRowTransfer+22   j  ; was: loc_3CC80
                tst.w   $54(a5)
                beq.s   Boss_FlyingNeoCopyTileRowPattern
                adda.l  #$38,a1                         ; '8'
Boss_FlyingNeoCopyTileRowPattern:                       ; CODE XREF: Boss_FlyingNeoQueueAnimatedTileRowTransfer+2E   j  ; was: loc_3CC8C
                                        ; Boss_FlyingNeoQueueAnimatedTileRowTransfer+38   j
                move.w  (a1)+,(a0)+
                dbf     d7,Boss_FlyingNeoCopyTileRowPattern
; Queues a 56-byte transfer from the row buffer to VRAM $6B80
Boss_FlyingNeoQueueTileRowTransfer:                     ; CODE XREF: Boss_FlyingNeoQueueFixedTileRowTransfer+E   j  ; was: loc_3CC92
                movea.w (VDPCommandQueueHead).w,a4
                move.w  #$83,-(a4)
                move.w  #$6B80,-(a4)
                move.b  (VDPStagingDataCursor).w,d2
                move.b  (VDPStagingDataCursor+1).w,d3
                asr.b   #1,d2
                roxr.b  #1,d3
                move.b  d3,-(a4)
                move.b  #$95,-(a4)
                move.b  d2,-(a4)
                move.b  #$96,-(a4)
                move.l  #$8F02977F,-(a4)
                move.l  #$9400931C,-(a4)
                move.w  a4,(VDPCommandQueueHead).w
                addi.w  #$38,(VDPStagingDataCursor).w   ; '8'
                rts
; End of function Boss_FlyingNeoQueueFixedTileRowTransfer
; ---------------------------------------------------------------------------
Boss_FlyingNeoTileRowPatternA:  dc.w    $6343, $6344, $6345, $6346, $6347, $6348, $6349, $634A  ; was: word_3CCCE
                                        ; DATA XREF: Boss_FlyingNeoQueueAnimatedTileRowTransfer+16   o
                dc.w    $634B, $634C, $634D, $634E, $634F, $6350, $6351, $6352
                dc.w    $6353, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD
                dc.w    $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD
                dc.w    $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $6B53
                dc.w    $6B52, $6B51, $6B50, $6B4F, $6B4E, $6B4D, $6B4C, $6B4B
                dc.w    $6B4A, $6B49, $6B48, $6B47, $6B46, $6B45, $6B44, $6B43
Boss_FlyingNeoTileRowPatternB:  dc.w    $63CD, $63CD, $63CD, $63CD, $63CD, $6B53, $6B52, $6354  ; was: word_3CD3E
                                        ; DATA XREF: Boss_FlyingNeoQueueAnimatedTileRowTransfer+24   o
                dc.w    $6355, $6356, $6357, $6358, $6359, $635A, $635B, $6B49
                dc.w    $6B48, $6B47, $6B46, $6B45, $6B44, $6B43, $63CD, $63CD
                dc.w    $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD, $63CD
                dc.w    $63CD, $63CD, $6343, $6344, $6345, $6346, $6347, $6348
                dc.w    $6349, $635B, $6B5A, $6B59, $6B58, $6B57, $6B56, $6B55
                dc.w    $6B54, $6352, $6353, $63CD, $63CD, $63CD, $63CD, $63CD

; Checks collision between boss and player attacks
