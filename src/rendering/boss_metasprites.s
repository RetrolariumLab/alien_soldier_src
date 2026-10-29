; Prepares parent/child traversal registers and returns the actual part count
Sprite_BeginMetaspritePartTraversal:                    ; CODE XREF: Boss_AntroidRenderPose+2   j  ; was: sub_343CE
                                        ; Boss_TerobusterUpdateMetaspriteAndProjectile+2   p
                bsr.w   Sprite_SetMetaspriteTraversalPointers
                bra.w   Sprite_LoadMetaspritePartCount
; End of function Sprite_BeginMetaspritePartTraversal
; Applies the eight-frame rotation renderer, then reloads the actual part count
Sprite_UpdateMetaspriteEightFrameRotation:              ; CODE XREF: Boss_FlyingNeoUpdateSprites+2E   p  ; was: sub_343D6
                bsr.w   Sprite_ApplyMetaspriteEightFrameRotation
                bra.w   Sprite_LoadMetaspritePartCount
; End of function Sprite_UpdateMetaspriteEightFrameRotation
; Applies the four-frame rotation renderer, then reloads the actual part count
Sprite_UpdateMetaspriteFourFrameRotationAndLoadCount:   ; CODE XREF: Boss_DeepStriderUpdateParts+D0   j  ; was: sub_343DE
                bsr.w   Sprite_ApplyMetaspriteFourFrameRotation
                bra.w   Sprite_LoadMetaspritePartCount
; End of function Sprite_UpdateMetaspriteFourFrameRotationAndLoadCount
; Updates Back Stringer's segment chain, then reloads the actual part count
Boss_BackStringerUpdateSegmentChainAndLoadCount:        ; CODE XREF: Boss_BackStringerUpdateRender+A   j  ; was: sub_343E6
                bsr.w   Boss_BackStringerApplySegmentChain
                bra.w   Sprite_LoadMetaspritePartCount
; End of function Boss_BackStringerUpdateSegmentChainAndLoadCount
; Creates a contiguous child-object group from mapping, angle, and link tables
Sprite_InitializeLinkedMetaspriteParts:                 ; CODE XREF: Boss_AntroidInitializeBattleState+20   p  ; was: sub_343EE
                                        ; Boss_TerobusterSetup+28   p
                move.w  a5,(MetaspriteParentPtr).w
; Alternate entry for a second group that reuses the saved parent address
Sprite_InitializeAdditionalLinkedMetaspriteParts:       ; CODE XREF: Boss_AntroidInitializeBattleState+3A   p  ; was: loc_343F2
                moveq   #0,d0
                move.w  d0,d1
                move.w  d0,d2
                move.w  d0,d3
Sprite_InitializeLinkedMetaspritePartsNextPart:         ; CODE XREF: Sprite_InitializeLinkedMetaspriteParts+108   j  ; was: loc_343FA
                move.l  (a0,d1.w),d4
                beq.w   Sprite_InitializeLinkedMetaspritePartsTransform
                move.l  d4,d5
                move.l  d4,d6
                movea.l d4,a3
                andi.l  #$7FFFFFF,d4
                andi.l  #$F0000000,d5
                andi.l  #$8000000,d6
                bclr    #0,d4
                bne.s   Sprite_InitializeLinkedMetaspritePartsUseInlineDescriptor
                bclr    #$16,d4
                beq.s   Sprite_InitializeLinkedMetaspritePartsUseRotationFrames
                move.w  #$C000,2(a4)
                move.w  (MetaspriteBaseTileWord).w,$E(a4)
                move.l  d4,8(a4)
                clr.l   $4C(a4)
                bra.s   Sprite_InitializeLinkedMetaspritePartsTransform
; ---------------------------------------------------------------------------
Sprite_InitializeLinkedMetaspritePartsUseRotationFrames:  ; CODE XREF: Sprite_InitializeLinkedMetaspriteParts+36   j  ; was: loc_3443C
                move.w  #$C000,2(a4)
                move.w  (MetaspriteBaseTileWord).w,$E(a4)
                move.l  d4,$4C(a4)
                rol.l   #8,d5
                rol.w   #1,d5
                swap    d6
                or.w    d6,d5
                move.w  d5,$50(a4)
                bra.s   Sprite_InitializeLinkedMetaspritePartsTransform
; ---------------------------------------------------------------------------
Sprite_InitializeLinkedMetaspritePartsUseInlineDescriptor:  ; CODE XREF: Sprite_InitializeLinkedMetaspriteParts+30   j  ; was: loc_3445A
                move.w  #$8000,2(a4)
                movem.l a3,-(sp)
                movea.l d4,a3
                move.w  (a3)+,$E(a4)
                move.w  (a3)+,8(a4)
                move.w  (a3),$A(a4)
                movem.l (sp)+,a3
                clr.l   $4C(a4)
                move.w  (MetaspriteBaseTileWord).w,d4
                andi.w  #$8000,d4
                or.w    d4,$E(a4)
Sprite_InitializeLinkedMetaspritePartsTransform:        ; CODE XREF: Sprite_InitializeLinkedMetaspriteParts+10   j  ; was: loc_34486
                                        ; Sprite_InitializeLinkedMetaspriteParts+4C   j
                move.w  d0,d4
                move.b  (a1,d3.w),d4
                move.w  d4,d5
                andi.w  #$7F,d4
                move.w  d4,$52(a4)
                move.w  d4,$54(a4)
                move.w  d0,$56(a4)
                andi.w  #$80,d5
                beq.s   Sprite_InitializeLinkedMetaspritePartsPositionLink
                ori.w   #$8000,$E(a4)
Sprite_InitializeLinkedMetaspritePartsPositionLink:     ; CODE XREF: Sprite_InitializeLinkedMetaspriteParts+B4   j  ; was: loc_344AA
                move.w  (a2,d2.w),d4
                move.w  d4,d5
                andi.w  #$3FE0,d4
                add.w   (MetaspriteParentPtr).w,d4
                move.w  d4,$4A(a4)
                move.w  (MetaspriteParentPtr).w,$48(a4)
                move.w  d5,d4
                andi.w  #$C000,d4
                andi.w  #$1F,d5
                asl.w   #2,d5
                move.b  d5,$20(a4)
                move.l  a3,d5
                andi.l  #$3000000,d5
                swap    d5
                asl.w   #5,d5
                lsr.w   #1,d4
                or.w    d4,$E(a4)
                or.w    d5,$E(a4)
                move.w  #$10,(a4)
                addq.w  #4,d1
                addq.w  #2,d2
                addq.w  #1,d3
                lea     $60(a4),a4
                dbf     d7,Sprite_InitializeLinkedMetaspritePartsNextPart
                ori.w   #$C00,2(a5)
                rts
; End of function Sprite_InitializeLinkedMetaspriteParts
; Points a3 at the parent, a4 at its first child, and saves count-minus-one
Sprite_SetMetaspriteTraversalPointers:                  ; CODE XREF: Sprite_BeginMetaspritePartTraversal   p  ; was: sub_34502
                                        ; Boss_MadamBarbarUpdateParts+6   p
                movea.w a5,a4
                movea.w a4,a3
                lea     $60(a4),a4
                move.w  d7,(MetaspritePartCountM1).w
; End of function Sprite_SetMetaspriteTraversalPointers
; Selects one of eight directional frames and positions each child by sine/cosine
Sprite_ApplyMetaspriteEightFrameRotation:               ; CODE XREF: Sprite_UpdateMetaspriteEightFrameRotation   p  ; was: sub_3450E
                lea     (Math_SineTable).l,a2
                move.w  $54(a5),d3
                move.w  $56(a5),d4
                move.w  $50(a5),d5
                move.w  #$1FE,d6
Sprite_ApplyMetaspriteEightFrameRotationNextPart:       ; CODE XREF: Sprite_ApplyMetaspriteEightFrameRotation+9E   j  ; was: loc_34524
                move.w  $56(a4),d0
                add.w   d4,d0
                move.l  $4C(a4),d1
                beq.s   Sprite_ApplyMetaspriteEightFrameRotationPosition
                movea.l d1,a0
                move.w  $E(a4),d2
                move.w  d0,d1
                add.w   $50(a4),d1
                subi.w  #$10,d1
                and.w   d6,d1
                ori.w   #$1800,d2
                cmpi.w  #$100,d1
                bpl.s   Sprite_ApplyMetaspriteEightFrameRotationOrientFrame
                andi.w  #$E7FF,d2
Sprite_ApplyMetaspriteEightFrameRotationOrientFrame:    ; CODE XREF: Sprite_ApplyMetaspriteEightFrameRotation+3C   j  ; was: loc_34550
                cmpi.w  #$100,d3
                bmi.s   Sprite_ApplyMetaspriteEightFrameRotationSelectFrame
                eori.w  #$800,d2
Sprite_ApplyMetaspriteEightFrameRotationSelectFrame:    ; CODE XREF: Sprite_ApplyMetaspriteEightFrameRotation+46   j  ; was: loc_3455A
                asr.w   #3,d1
                andi.w  #$1C,d1
                move.l  (a0,d1.w),8(a4)
                move.w  $50(a4),d1
                andi.w  #$800,d1
                eor.w   d1,d2
                move.w  d2,$E(a4)
Sprite_ApplyMetaspriteEightFrameRotationPosition:       ; CODE XREF: Sprite_ApplyMetaspriteEightFrameRotation+20   j  ; was: loc_34574
                move.w  $54(a4),d2
                add.w   d5,d2
                bpl.s   Sprite_ApplyMetaspriteEightFrameRotationCalculatePosition
                moveq   #0,d2
Sprite_ApplyMetaspriteEightFrameRotationCalculatePosition:  ; CODE XREF: Sprite_ApplyMetaspriteEightFrameRotation+6C   j  ; was: loc_3457E
                move.w  d0,d1
                add.w   d3,d1
                and.w   d6,d0
                and.w   d6,d1
                move.w  -$80(a2,d0.w),d0
                move.w  (a2,d1.w),d1
                asl.w   #2,d2
                muls.w  d2,d0
                muls.w  d2,d1
                movea.w $4A(a4),a0
                add.l   $44(a0),d0
                move.l  d0,$44(a4)
                add.l   $40(a0),d1
                move.l  d1,$40(a4)
                lea     $60(a4),a4
                dbf     d7,Sprite_ApplyMetaspriteEightFrameRotationNextPart
                rts
; End of function Sprite_ApplyMetaspriteEightFrameRotation
; Rotates Valkirie's parts, then aligns the entire group between two anchors
Boss_ValkirieUpdateAnchoredMetasprite:                  ; CODE XREF: Entity_UpdateValkirieAuxiliaryAnchors+2   j  ; was: sub_345B2
                movea.w a5,a4
                move.w  d7,(MetaspritePartCountM1).w
                lea     $60(a4),a4
                lea     (Math_SineTable).l,a2
                move.w  $56(a5),d4
                move.w  $50(a5),d5
                move.w  #$1FE,d6
Boss_ValkirieUpdateAnchoredMetaspriteNextPart:          ; CODE XREF: Boss_ValkirieUpdateAnchoredMetasprite+A4   j  ; was: loc_345CE
                move.w  $56(a4),d0
                add.w   d4,d0
                move.l  $4C(a4),d1
                beq.s   Boss_ValkirieUpdateAnchoredMetaspritePosition
                movea.l d1,a0
                move.w  $E(a4),d2
                move.w  d0,d1
                add.w   $50(a4),d1
                subi.w  #$10,d1
                and.w   d6,d1
                ori.w   #$1800,d2
                cmpi.w  #$100,d1
                bpl.s   Boss_ValkirieUpdateAnchoredMetaspriteOrientFrame
                andi.w  #$E7FF,d2
Boss_ValkirieUpdateAnchoredMetaspriteOrientFrame:       ; CODE XREF: Boss_ValkirieUpdateAnchoredMetasprite+42   j  ; was: loc_345FA
                cmpi.w  #$100,d3
                bmi.s   Boss_ValkirieUpdateAnchoredMetaspriteSelectFrame
                eori.w  #$800,d2
Boss_ValkirieUpdateAnchoredMetaspriteSelectFrame:       ; CODE XREF: Boss_ValkirieUpdateAnchoredMetasprite+4C   j  ; was: loc_34604
                asr.w   #3,d1
                andi.w  #$1C,d1
                move.l  (a0,d1.w),8(a4)
                move.w  $50(a4),d1
                andi.w  #$800,d1
                eor.w   d1,d2
                move.w  d2,$E(a4)
Boss_ValkirieUpdateAnchoredMetaspritePosition:          ; CODE XREF: Boss_ValkirieUpdateAnchoredMetasprite+26   j  ; was: loc_3461E
                move.w  $54(a4),d2
                add.w   d5,d2
                bpl.s   Boss_ValkirieUpdateAnchoredMetaspriteCalculatePosition
                moveq   #0,d2
Boss_ValkirieUpdateAnchoredMetaspriteCalculatePosition:  ; CODE XREF: Boss_ValkirieUpdateAnchoredMetasprite+72   j  ; was: loc_34628
                move.w  d0,d1
                add.w   d3,d1
                and.w   d6,d0
                and.w   d6,d1
                move.w  -$80(a2,d0.w),d0
                move.w  (a2,d1.w),d1
                asl.w   #2,d2
                muls.w  d2,d0
                muls.w  d2,d1
                movea.w $4A(a4),a0
                add.l   $44(a0),d0
                move.l  d0,$44(a4)
                add.l   $40(a0),d1
                move.l  d1,$40(a4)
                lea     $60(a4),a4
                dbf     d7,Boss_ValkirieUpdateAnchoredMetaspriteNextPart
                movea.w a5,a4
                move.w  (MetaspritePartCountM1).w,d7
                addq.w  #1,d7
                movea.w $48(a5),a0
                movea.w $4A(a5),a1
                move.w  $10(a0),d0
                sub.w   $40(a0),d0
                move.w  $14(a1),d1
                sub.w   $44(a1),d1
Boss_ValkirieUpdateAnchoredMetaspriteApplyOffset:       ; CODE XREF: Boss_ValkirieUpdateAnchoredMetasprite+E0   j  ; was: loc_3467A
                move.w  d0,d2
                add.w   $40(a4),d2
                move.w  d2,$10(a4)
                move.w  d1,d2
                add.w   $44(a4),d2
                move.w  d2,$14(a4)
                lea     $60(a4),a4
                dbf     d7,Boss_ValkirieUpdateAnchoredMetaspriteApplyOffset
                rts
; End of function Boss_ValkirieUpdateAnchoredMetasprite
; Selects one of four directional frames and positions each child by sine/cosine
Sprite_ApplyMetaspriteFourFrameRotation:                ; CODE XREF: Sprite_UpdateMetaspriteFourFrameRotationAndLoadCount   p  ; was: sub_34698
                movea.w a5,a4
                movea.w a4,a3
                lea     $60(a4),a4
                move.w  d7,(MetaspritePartCountM1).w
                lea     (Math_SineTable).l,a2
                move.w  $54(a5),d3
                move.w  $56(a5),d4
                move.w  $50(a5),d5
                move.w  #$1FE,d6
Sprite_ApplyMetaspriteFourFrameRotationNextPart:        ; CODE XREF: Sprite_ApplyMetaspriteFourFrameRotation+AA   j  ; was: loc_346BA
                move.w  $56(a4),d0
                add.w   d4,d0
                move.l  $4C(a4),d1
                beq.s   Sprite_ApplyMetaspriteFourFrameRotationPosition
                movea.l d1,a0
                move.w  $E(a4),d2
                move.w  d0,d1
                add.w   $50(a4),d1
                subi.w  #$20,d1                         ; ' '
                and.w   d6,d1
                ori.w   #$1800,d2
                cmpi.w  #$100,d1
                bpl.s   Sprite_ApplyMetaspriteFourFrameRotationOrientFrame
                andi.w  #$E7FF,d2
Sprite_ApplyMetaspriteFourFrameRotationOrientFrame:     ; CODE XREF: Sprite_ApplyMetaspriteFourFrameRotation+48   j  ; was: loc_346E6
                cmpi.w  #$100,d3
                bmi.s   Sprite_ApplyMetaspriteFourFrameRotationSelectFrame
                eori.w  #$800,d2
Sprite_ApplyMetaspriteFourFrameRotationSelectFrame:     ; CODE XREF: Sprite_ApplyMetaspriteFourFrameRotation+52   j  ; was: loc_346F0
                asr.w   #4,d1
                andi.w  #$C,d1
                move.l  (a0,d1.w),8(a4)
                move.w  $50(a4),d1
                andi.w  #$800,d1
                eor.w   d1,d2
                move.w  d2,$E(a4)
Sprite_ApplyMetaspriteFourFrameRotationPosition:        ; CODE XREF: Sprite_ApplyMetaspriteFourFrameRotation+2C   j  ; was: loc_3470A
                move.w  $54(a4),d2
                add.w   d5,d2
                bpl.s   Sprite_ApplyMetaspriteFourFrameRotationCalculatePosition
                moveq   #0,d2
Sprite_ApplyMetaspriteFourFrameRotationCalculatePosition:  ; CODE XREF: Sprite_ApplyMetaspriteFourFrameRotation+78   j  ; was: loc_34714
                move.w  d0,d1
                add.w   d3,d1
                and.w   d6,d0
                and.w   d6,d1
                move.w  -$80(a2,d0.w),d0
                move.w  (a2,d1.w),d1
                asl.w   #2,d2
                muls.w  d2,d0
                muls.w  d2,d1
                movea.w $4A(a4),a0
                add.l   $44(a0),d0
                move.l  d0,$44(a4)
                add.l   $40(a0),d1
                move.l  d1,$40(a4)
                lea     $60(a4),a4
                dbf     d7,Sprite_ApplyMetaspriteFourFrameRotationNextPart
                rts
; End of function Sprite_ApplyMetaspriteFourFrameRotation
; Selects frames and calculates Back Stringer's primary and optional secondary chain positions
Boss_BackStringerApplySegmentChain:                     ; CODE XREF: Boss_BackStringerUpdateSegmentChainAndLoadCount   p  ; was: sub_34748
                movea.w a5,a4
                movea.w a4,a3
                lea     $60(a4),a4
                move.w  d7,(MetaspritePartCountM1).w
                lea     (Math_SineTable).l,a2
                move.w  $54(a5),d3
                move.w  $56(a5),d4
                move.w  $50(a5),d5
                move.w  #$1FE,d6
Boss_BackStringerApplySegmentChainNextPart:             ; CODE XREF: Boss_BackStringerApplySegmentChain+EA   j  ; was: loc_3476A
                move.w  $56(a4),d0
                add.w   d4,d0
                move.l  $4C(a4),d1
                beq.s   Boss_BackStringerApplySegmentChainPosition
                movea.l d1,a0
                move.w  $E(a4),d2
                move.w  d0,d1
                add.w   $50(a4),d1
                subi.w  #$10,d1
                and.w   d6,d1
                ori.w   #$1800,d2
                cmpi.w  #$100,d1
                bpl.s   Boss_BackStringerApplySegmentChainOrientFrame
                andi.w  #$E7FF,d2
Boss_BackStringerApplySegmentChainOrientFrame:          ; CODE XREF: Boss_BackStringerApplySegmentChain+48   j  ; was: loc_34796
                cmpi.w  #$100,d3
                bmi.s   Boss_BackStringerApplySegmentChainSelectFrame
                eori.w  #$800,d2
Boss_BackStringerApplySegmentChainSelectFrame:          ; CODE XREF: Boss_BackStringerApplySegmentChain+52   j  ; was: loc_347A0
                asr.w   #3,d1
                andi.w  #$1C,d1
                move.l  (a0,d1.w),8(a4)
                move.w  $50(a4),d1
                andi.w  #$800,d1
                eor.w   d1,d2
                move.w  d2,$E(a4)
Boss_BackStringerApplySegmentChainPosition:             ; CODE XREF: Boss_BackStringerApplySegmentChain+2C   j  ; was: loc_347BA
                move.w  $54(a4),d2
                add.w   d5,d2
                bpl.s   Boss_BackStringerApplySegmentChainSelectAnchor
                moveq   #0,d2
Boss_BackStringerApplySegmentChainSelectAnchor:         ; CODE XREF: Boss_BackStringerApplySegmentChain+78   j  ; was: loc_347C4
                move.w  d0,d1
                add.w   d3,d1
                and.w   d6,d0
                and.w   d6,d1
                movea.w $4A(a4),a0
                btst    #1,$20(a4)
                bne.s   Boss_BackStringerApplySegmentChainPrimaryPosition
                addq.w  #8,a0
Boss_BackStringerApplySegmentChainPrimaryPosition:      ; CODE XREF: Boss_BackStringerApplySegmentChain+8E   j  ; was: loc_347DA
                move.w  -$80(a2,d0.w),(MetaspriteSineScratch).w
                move.w  (a2,d1.w),(MetaspriteCosScratch).w
                move.w  (MetaspriteSineScratch).w,d0
                move.w  (MetaspriteCosScratch).w,d1
                asl.w   #2,d2
                muls.w  d2,d0
                muls.w  d2,d1
                add.l   $3C(a0),d0
                move.l  d0,$44(a4)
                add.l   $38(a0),d1
                move.l  d1,$40(a4)
                btst    #0,$20(a4)
                beq.s   Boss_BackStringerApplySegmentChainAdvance
                move.w  d2,d0
                asr.w   #1,d0
                add.w   d0,d2
                move.w  (MetaspriteSineScratch).w,d0
                move.w  (MetaspriteCosScratch).w,d1
                muls.w  d2,d0
                muls.w  d2,d1
                add.l   $3C(a0),d0
                move.l  d0,$3C(a4)
                add.l   $38(a0),d1
                move.l  d1,$38(a4)
Boss_BackStringerApplySegmentChainAdvance:              ; CODE XREF: Boss_BackStringerApplySegmentChain+C2   j  ; was: loc_3482E
                lea     $60(a4),a4
                dbf     d7,Boss_BackStringerApplySegmentChainNextPart
                rts
; End of function Boss_BackStringerApplySegmentChain
; Restores count-minus-one from scratch RAM and converts it to an actual count
Sprite_LoadMetaspritePartCount:                         ; CODE XREF: Sprite_BeginMetaspritePartTraversal+4   j  ; was: sub_34838
                                        ; Sprite_UpdateMetaspriteEightFrameRotation+4   j
                move.w  (MetaspritePartCountM1).w,d7
                addq.w  #1,d7
; End of function Sprite_LoadMetaspritePartCount
; Applies the offset between two anchor objects to each traversed child
Sprite_ApplyAnchorOffsetToLinkedParts:                  ; CODE XREF: Boss_JetsripperRotateState+42   p  ; was: sub_3483E
                                        ; Boss_JetsripperUpdateMovement+A0   p
                movea.w $48(a5),a0
                movea.w $4A(a5),a1
                move.w  $10(a0),d0
                sub.w   $40(a0),d0
                move.w  $14(a1),d1
                sub.w   $44(a1),d1
Sprite_ApplyAnchorOffsetToLinkedPartsNextPart:          ; CODE XREF: Sprite_ApplyAnchorOffsetToLinkedParts+30   j  ; was: loc_34856
                move.w  d0,d2
                add.w   $40(a3),d2
                move.w  d2,$10(a3)
                move.w  d1,d2
                add.w   $44(a3),d2
                move.w  d2,$14(a3)
                lea     $60(a3),a3
                dbf     d7,Sprite_ApplyAnchorOffsetToLinkedPartsNextPart
                rts
; End of function Sprite_ApplyAnchorOffsetToLinkedParts
; Selects one of four directional frames and flip flags from combined angles
Sprite_UpdateFourDirectionFrame:                        ; CODE XREF: Boss_SharpsteelUpdateCoreSpriteFrames+10   p  ; was: sub_34874
                                        ; Boss_SharpsteelUpdateCoreSpriteFrames+20   j
                move.w  $56(a0),d0
                add.w   $56(a5),d0
                addi.w  #$20,d0                         ; ' '
                andi.w  #$1FE,d0
                cmpi.w  #$100,d0
                bmi.s   Sprite_UpdateFourDirectionFrameParentFlip
                eori.w  #$1800,$E(a0)
Sprite_UpdateFourDirectionFrameParentFlip:              ; CODE XREF: Sprite_UpdateFourDirectionFrame+14   j  ; was: loc_34890
                tst.w   $54(a5)
                bne.s   Sprite_UpdateFourDirectionFrameSelect
                eori.w  #$800,$E(a0)
Sprite_UpdateFourDirectionFrameSelect:                  ; CODE XREF: Sprite_UpdateFourDirectionFrame+20   j  ; was: loc_3489C
                asr.w   #4,d0
                andi.w  #$C,d0
                move.l  (a1,d0.w),8(a0)
                rts
; End of function Sprite_UpdateFourDirectionFrame
; Calculates per-update deltas from current to target pose-channel bytes
Anim_CalculatePoseChannelDeltas:                        ; CODE XREF: Boss_AntroidBeginPoseInterpolation+10   j  ; was: sub_348AA
                                        ; Boss_TerobusterCalculateDeltas+10   j
                move.w  #$FF,d4
Anim_CalculatePoseChannelDeltasNextChannel:             ; CODE XREF: Anim_CalculatePoseChannelDeltas+1C   j  ; was: loc_348AE
                move.b  (a0)+,d0
                move.w  (a2)+,d1
                asr.w   #8,d1
                sub.b   (a1),d0
                sub.b   (a1)+,d1
                and.w   d4,d0
                and.w   d4,d1
                sub.w   d1,d0
                ext.l   d0
                lsl.w   #8,d0
                divs.w  d3,d0
                move.w  d0,(a2)+
                dbf     d7,Anim_CalculatePoseChannelDeltasNextChannel
                rts
; End of function Anim_CalculatePoseChannelDeltas
; Initializes fixed-point pose channels from source bytes and zero deltas
Anim_InitializePoseChannelsFromBytes:                   ; CODE XREF: Boss_AntroidInitializePoseChannels+6   j  ; was: sub_348CC
                                        ; Boss_TerobusterInitializePoseChannels+6   j
                moveq   #0,d1
Anim_InitializePoseChannelsFromBytesNextChannel:        ; CODE XREF: Anim_InitializePoseChannelsFromBytes+A   j  ; was: loc_348CE
                move.b  (a0)+,d0
                asl.w   #8,d0
                move.w  d0,(a1)+
                move.w  d1,(a1)+
                dbf     d7,Anim_InitializePoseChannelsFromBytesNextChannel
                rts
; End of function Anim_InitializePoseChannelsFromBytes
; Advances each fixed-point pose channel by its stored delta
Anim_AdvancePoseChannelInterpolation:                   ; CODE XREF: Boss_AntroidUpdatePoseAnimation+8C   p  ; was: sub_348DC
                                        ; Boss_TerobusterInterpolateAnimation+6C   p
                movea.l a0,a1
Anim_AdvancePoseChannelInterpolationNextChannel:        ; CODE XREF: Anim_AdvancePoseChannelInterpolation+A   j  ; was: loc_348DE
                move.w  (a0)+,d1
                add.w   (a0)+,d1
                move.w  d1,(a1)
                addq.w  #4,a1
                dbf     d7,Anim_AdvancePoseChannelInterpolationNextChannel
                rts
; End of function Anim_AdvancePoseChannelInterpolation
; Clears the seventeen-longword animation interpolation work buffer
Anim_ClearInterpolationBuffer:                          ; was: sub_348EC
                move.w  #$10,d7
                moveq   #0,d0
                movea.l #SharedScratchLong0,a0
Anim_ClearInterpolationBufferNextLongword:              ; CODE XREF: Anim_ClearInterpolationBuffer+E   j  ; was: loc_348F8
                move.l  d0,(a0)+
                dbf     d7,Anim_ClearInterpolationBufferNextLongword
                rts
; End of function Anim_ClearInterpolationBuffer
; Selects an eight-direction mapping frame and applies rotation-dependent flip flags
Sprite_SelectEightDirectionFrame:                       ; CODE XREF: Projectile_BackStringerChainFalling:Projectile_BackStringerUpdateFallingChainFrame   j  ; was: sub_34900
                movea.l $4C(a5),a0
                move.w  $E(a5),d2
                move.w  $56(a5),d1
                add.w   $50(a5),d1
                subi.w  #$10,d1
                andi.w  #$1FE,d1
                ori.w   #$1800,d2
                cmpi.w  #$100,d1
                bpl.s   Sprite_SelectEightDirectionFrameOrientFrame
                andi.w  #$E7FF,d2
Sprite_SelectEightDirectionFrameOrientFrame:            ; CODE XREF: Sprite_SelectEightDirectionFrame+20   j  ; was: loc_34926
                cmpi.w  #$100,d3
                bmi.s   Sprite_SelectEightDirectionFrameSelectFrame
                eori.w  #$800,d2
Sprite_SelectEightDirectionFrameSelectFrame:            ; CODE XREF: Sprite_SelectEightDirectionFrame+2A   j  ; was: loc_34930
                asr.w   #3,d1
                andi.w  #$1C,d1
                move.l  (a0,d1.w),8(a5)
                move.w  $50(a5),d1
                andi.w  #$800,d1
                eor.w   d1,d2
                move.w  d2,$E(a5)
                rts
; End of function Sprite_SelectEightDirectionFrame
; ---------------------------------------------------------------------------
