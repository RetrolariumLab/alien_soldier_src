; Dispatches type $1C8 in the dormant type-$1C0-family code
; REVIEWED VIS-003: role-only name; this is not the live Sunset Sting; see docs/unknowns.md
Boss_LovePenguinMainDispatcher:                         ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_418FC
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_LovePenguinDispatchSecondFormState
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                beq.s   Boss_LovePenguinRefreshAimSample
                lea     (PlayerObjectType).w,a4
                jsr     (Physics_CalculateAngleToTarget).l
                move.b  d0,(LovePenguinAimAngle).w
                move.b  d0,(SecondaryEntityWork5C+1).w
                bra.s   Boss_LovePenguinDispatchSecondFormState
; ---------------------------------------------------------------------------
Boss_LovePenguinRefreshAimSample:                       ; CODE XREF: Boss_LovePenguinMainDispatcher+12   j  ; was: loc_41924
                lea     (PlayerObjectType).w,a4
                jsr     (Physics_CalculateAngleToTarget).l
                move.b  d0,(SecondaryEntityWork5C+1).w
Boss_LovePenguinDispatchSecondFormState:                ; CODE XREF: Boss_LovePenguinMainDispatcher+8   j  ; was: loc_41932
                                        ; Boss_LovePenguinMainDispatcher+26   j
                moveq   #4,d7
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  4(a5),d0
                lea     Boss_LovePenguinSecondFormStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_LovePenguinMainDispatcher
; ---------------------------------------------------------------------------
Boss_LovePenguinSecondFormStates:
                dc.w    Boss_LovePenguinSecondFormInitializeState-*  ; DATA XREF: Boss_LovePenguinMainDispatcher+42   o  ; was: off_41946
                dc.w    Boss_LovePenguinSecondFormLoadGraphicsState-*
                dc.w    Boss_LovePenguinQueueSecondFormIntroMessageState-*
                dc.w    Boss_LovePenguinWaitForSecondFormIntroMessageState-*
                dc.w    Boss_LovePenguinBeginMovementState-*
                dc.w    Boss_LovePenguinUpdateMovement-*
                dc.w    Boss_LovePenguinApplyPosePatternBState-*
                dc.w    Boss_LovePenguinApplyPosePatternCState-*
                dc.w    Boss_LovePenguinCheckHealthThreshold-*
                dc.w    Boss_LovePenguinApplyPosePatternAState-*
                dc.w    Boss_LovePenguinApplyPosePatternCState-*
                dc.w    Boss_LovePenguinCheckHealthThreshold-*
                dc.w    Boss_LovePenguinMoveAndShoot_AttackLoop-*
                dc.w    Boss_LovePenguinOscillateChainsState-*
                dc.w    Boss_LovePenguinRefillHealthState-*
                dc.w    Boss_LovePenguinDescendAndActivateChainsState-*
                dc.w    Boss_LovePenguinWaitThenActivateTrailState-*
                dc.w    Boss_LovePenguinContractTrailState-*
                dc.w    Boss_LovePenguinFinishTrailTransitionState-*
Boss_LovePenguinBodyPartSpriteDescriptorA:
                dc.w    $C82C, $D00, $F8F0              ; DATA XREF: ROM:Boss_LovePenguinSecondFormBodyPartInitTable   o  ; was: word_4196C
                                        ; ROM:0004259A   o
Boss_LovePenguinBodyPartSpriteDescriptorB:
                dc.w    $C834, $500, $F8F8              ; DATA XREF: ROM:000425FA   o  ; was: word_41972
                                        ; ROM:00042602   o
Boss_LovePenguinBodyPartSpriteDescriptorC:
                dc.w    $C851, 0, $FCFC                 ; DATA XREF: ROM:000425B6   o  ; was: word_41978
                                        ; ROM:000425C6   o
Boss_LovePenguinBodyPartSpriteDescriptorD:
                dc.w    $C852, 0, $FCFC                 ; DATA XREF: ROM:000425D6   o  ; was: word_4197E
                                        ; ROM:000425E6   o

; Initializes boss state, clears sprites, sets starting position
Boss_LovePenguinSecondFormInitializeState:              ; DATA XREF: ROM:Boss_LovePenguinSecondFormStates   o  ; was: sub_41984
                clr.b   (SecondaryEntityWork5C).w
                move.w  #$1C8,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                addq.w  #2,4(a5)
                move.b  #$80,$4B(a5)
                clr.w   (LovePenguinAnimationProgress).w
                clr.w   (LovePenguinChainRootOffset).w
                move.l  #$1C00000,$10(a5)
                move.l  #$2000000,$14(a5)
                rts
; End of function Boss_LovePenguinSecondFormInitializeState
; Loads boss graphics tiles, palettes, and body parts
Boss_LovePenguinSecondFormLoadGraphicsState:            ; DATA XREF: ROM:00041948   o  ; was: sub_419B8
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_LovePenguinSecondFormLoadGraphicsReturn
                addq.w  #2,4(a5)
                movea.l #Boss_LovePenguinSecondFormObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                moveq   #6,d7
                jsr     (Gfx_ResetDefaultColorFadeState).l
                move.w  (a5),-(sp)
                move.w  #$3300,$E(a5)
                lea     Boss_LovePenguinSecondFormBodyPartInitTable(pc),a1
                lea     (a5),a4
                jsr     (Boss_LovePenguinInitBodyParts).l
                jsr     Boss_LovePenguinInitTrail(pc)   ; (pc)
                nop
                move.w  (sp)+,(a5)
                ori.w   #$100,$482(a5)
                ori.w   #$100,$6C2(a5)
                ori.w   #$100,$902(a5)
                ori.w   #$100,$B42(a5)
                move.w  #$D00,2(a5)
                lea     (a5),a1
                move.w  (LovePenguinBodyPartCount).w,d3
                subq.w  #1,d3
Boss_LovePenguinInitializeSecondFormPartPositions:      ; CODE XREF: Boss_LovePenguinSecondFormLoadGraphicsState+76   j  ; was: loc_41A1A
                move.l  #$1C00000,$10(a1)
                move.l  #$1C00000,$14(a1)
                adda.w  #$60,a1                         ; '`'
                dbf     d3,Boss_LovePenguinInitializeSecondFormPartPositions
                move.l  #$FFFF0000,$18(a5)
                move.b  #$18,(LovePenguinChainPeriod).w
                move.b  (LovePenguinChainPeriod).w,(LovePenguinChainCycle+1).w
                move.b  #$FF,(LovePenguinTurnControl).w
                move.w  #$180,$56(a5)
                movea.l #Boss_LovePenguinSecondFormTileLoadCommands,a0
                jsr     (Tilemap_QueueIndexedRows).l
Boss_LovePenguinSecondFormLoadGraphicsReturn:           ; CODE XREF: Boss_LovePenguinSecondFormLoadGraphicsState+4   j  ; was: locret_41A5E
                rts
; End of function Boss_LovePenguinSecondFormLoadGraphicsState
; ---------------------------------------------------------------------------
Boss_LovePenguinSecondFormTileLoadCommands:
                dc.w    $6100, $2000, $202, $595A, $5B5D, $5E5F, $6162, $63FF, $6306, $2000, 0, $5CFF, $6306, $2000, 0, $60FF  ; was: word_41A60
                                        ; DATA XREF: Boss_LovePenguinSecondFormLoadGraphicsState+9A   o
                dc.w    $6306, $2000, 0, $64FF
Boss_LovePenguinSecondFormTileAnimationOffsets:
                dc.w    $1E, $FFE6, $FFEC, $FFF2, $FFE8, $FFDE, $FFE4, $FFEA, $FFE0, $FFD6, $FFD4, $FFD2, $FFD0, $FFCE, $FFCC, $FFCA  ; was: word_41A88
                                        ; DATA XREF: Boss_LovePenguinSecondFormUpdate+82   o
                dc.w    $FFC8

; Queues the second-form intro message after the preceding transition
Boss_LovePenguinQueueSecondFormIntroMessageState:       ; DATA XREF: ROM:0004194A   o  ; was: sub_41AAA
                tst.w   (MessageSequenceState).w
                bne.w   Boss_LovePenguinSecondFormIntroUpdate
                moveq   #5,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
                bra.w   Boss_LovePenguinSecondFormIntroUpdate
; End of function Boss_LovePenguinQueueSecondFormIntroMessageState
; Waits for the second-form intro message to complete before advancing
Boss_LovePenguinWaitForSecondFormIntroMessageState:     ; DATA XREF: ROM:0004194C   o  ; was: sub_41AC2
                tst.w   (MessageSequenceState).w
                bne.s   Boss_LovePenguinSecondFormIntroUpdate
                clr.b   (BossColorEffectFlags).w
                addq.w  #2,4(a5)
Boss_LovePenguinSecondFormIntroUpdate:                  ; CODE XREF: Boss_LovePenguinQueueSecondFormIntroMessageState+4   j  ; was: loc_41AD0
                                        ; Boss_LovePenguinQueueSecondFormIntroMessageState+14   j
                bra.w   Boss_LovePenguinMovementUpdatePartFacing
; End of function Boss_LovePenguinWaitForSecondFormIntroMessageState
; Sets boss to attack state mode and transitions to main loop
Boss_LovePenguinBeginMovementState:                     ; DATA XREF: ROM:0004194E   o  ; was: sub_41AD4
                                        ; ROM:00041E44   o
                move.b  #4,$4B(a5)
                bra.w   Boss_LovePenguinInitializeMovementState
; End of function Boss_LovePenguinBeginMovementState
; Sets boss to idle state and initializes attack timer
Boss_LovePenguinSetIdleState:                           ; CODE XREF: Boss_LovePenguinMoveAndShoot+2A   j  ; was: sub_41ADE
                                        ; Boss_LovePenguinCheckPhaseTransition+8   j
                move.b  #$10,(LovePenguinChainPeriod).w
                move.b  #0,$4B(a5)
Boss_LovePenguinInitializeMovementState:                ; CODE XREF: Boss_LovePenguinBeginMovementState+6   j  ; was: loc_41AEA
                move.w  #$A,4(a5)
                clr.w   (LovePenguinChainCycle).w
                move.b  (LovePenguinChainPeriod).w,(LovePenguinChainCycle+1).w
                bsr.w   Boss_LovePenguinCalculateTargetDirection
                bra.w   Boss_LovePenguinMovementUpdateSelectedChain
; End of function Boss_LovePenguinSetIdleState
; Updates boss vertical movement tracking player
Boss_LovePenguinUpdateMovement:                         ; DATA XREF: ROM:00041950   o  ; was: sub_41B02
                move.w  #$10,d2
                move.w  #$F0,d0
                sub.w   $14(a5),d0
                move.b  (LovePenguinTurnControl).w,d1
                asl.w   #8,d1
                eor.w   d0,d1
                bpl.s   Boss_LovePenguinMovementNormalizeVerticalDelta
                neg.w   d2
Boss_LovePenguinMovementNormalizeVerticalDelta:         ; CODE XREF: Boss_LovePenguinUpdateMovement+14   j  ; was: loc_41B1A
                tst.w   d0
                bpl.s   Boss_LovePenguinMovementAdjustBodyAngle
                neg.w   d0
Boss_LovePenguinMovementAdjustBodyAngle:                ; CODE XREF: Boss_LovePenguinUpdateMovement+1A   j  ; was: loc_41B20
                cmpi.w  #$A,d0
                bcs.s   Boss_LovePenguinMovementUpdatePartFacing
                addi.w  #$100,d2
                lsr.w   #1,d2
                move.w  #1,d0
                move.w  $56(a5),d1
                lsr.w   #1,d1
                sub.b   d1,d2
                beq.s   Boss_LovePenguinMovementUpdatePartFacing
                bpl.s   Boss_LovePenguinMovementApplyBodyAngleStep
                neg.w   d0
Boss_LovePenguinMovementApplyBodyAngleStep:             ; CODE XREF: Boss_LovePenguinUpdateMovement+38   j  ; was: loc_41B3E
                add.w   d0,$56(a5)
Boss_LovePenguinMovementUpdatePartFacing:               ; CODE XREF: Boss_LovePenguinWaitForSecondFormIntroMessageState:Boss_LovePenguinSecondFormIntroUpdate   j  ; was: loc_41B42
                                        ; Boss_LovePenguinUpdateMovement+22   j
                tst.b   (LovePenguinTurnControl).w
                bpl.s   Boss_LovePenguinMovementFacePositive
                ori.w   #$800,$4EE(a5)
                ori.w   #$800,$72E(a5)
                andi.w  #$F7FF,$2AE(a5)
                andi.w  #$F7FF,$96E(a5)
                bra.w   Boss_LovePenguinMovementUpdatePosePatterns
; ---------------------------------------------------------------------------
Boss_LovePenguinMovementFacePositive:                   ; CODE XREF: Boss_LovePenguinUpdateMovement+44   j  ; was: loc_41B64
                ori.w   #$800,$2AE(a5)
                ori.w   #$800,$96E(a5)
                andi.w  #$F7FF,$4EE(a5)
                andi.w  #$F7FF,$72E(a5)
Boss_LovePenguinMovementUpdatePosePatterns:             ; CODE XREF: Boss_LovePenguinUpdateMovement+5E   j  ; was: loc_41B7C
                moveq   #$FFFFFFFF,d6
                move.b  (LovePenguinChainCycle+1).w,d3
                move.b  (LovePenguinChainCycle).w,d0
                lea     Boss_LovePenguinPrimaryTrackingPoseOffsets(pc),a3
                bsr.w   Boss_LovePenguinUpdatePartRotation
                move.b  (LovePenguinChainCycle+1).w,d3
                move.b  (LovePenguinChainCycle).w,d0
                eori.b  #$14,d0
                lea     Boss_LovePenguinSecondaryTrackingPoseOffsets(pc),a3
                bsr.w   Boss_LovePenguinUpdatePartRotation
                subq.b  #1,(LovePenguinChainCycle+1).w
                bne.s   Boss_LovePenguinMovementUpdateActiveChain
                addq.b  #4,(LovePenguinChainCycle).w
                andi.b  #$E,(LovePenguinChainCycle).w
                move.b  (LovePenguinChainPeriod).w,(LovePenguinChainCycle+1).w
                bsr.w   Boss_LovePenguinCalculateTargetDirection
                cmpi.w  #$A0,d0
                bhi.s   Boss_LovePenguinMovementTrySpawnProjectile
                tst.b   $4B(a5)
                bne.w   Boss_LovePenguinMovementDecrementShotDelay
                move.w  (LovePenguinChainRootOffset).w,d0
                move.b  (LovePenguinTurnControl).w,d1
                andi.w  #4,d1
                eori.w  #4,d0
                eor.b   d0,d1
                andi.w  #4,d1
                bne.w   Boss_LovePenguinChooseMovementVariation
                move.b  #1,$4B(a5)
Boss_LovePenguinMovementDecrementShotDelay:             ; CODE XREF: Boss_LovePenguinUpdateMovement+C4   j  ; was: loc_41BEA
                subq.b  #1,$4B(a5)
Boss_LovePenguinMovementTrySpawnProjectile:             ; CODE XREF: Boss_LovePenguinUpdateMovement+BE   j  ; was: loc_41BEE
                move.w  d6,-(sp)
                bsr.w   Boss_LovePenguinSpawnRandomProjectile
                move.w  (sp)+,d6
Boss_LovePenguinMovementUpdateActiveChain:              ; CODE XREF: Boss_LovePenguinUpdateMovement+A4   j  ; was: loc_41BF6
                tst.w   d6
                bmi.s   Boss_LovePenguinMovementUpdateSelectedChain
                cmp.w   (LovePenguinChainRootOffset).w,d6
                beq.s   Boss_LovePenguinMovementUpdateSelectedChain
                lea     Boss_LovePenguinChainRootOffsets(pc),a2
                movea.w (a2,d6.w),a4
                adda.w  a5,a4
                move.l  #SharedVictorSunsetStingSegmentMappingB,$1E8(a4)
                move.w  (LovePenguinChainRootOffset).w,d0
                move.w  d6,(LovePenguinChainRootOffset).w
                movea.w (a2,d0.w),a4
                adda.w  a5,a4
                move.l  #SharedVictorSunsetStingSegmentMappingA,$1E8(a4)
Boss_LovePenguinMovementUpdateSelectedChain:            ; CODE XREF: Boss_LovePenguinSetIdleState+20   j  ; was: loc_41C28
                                        ; Boss_LovePenguinUpdateMovement+F6   j
                move.w  (LovePenguinChainRootOffset).w,d6
                lea     Boss_LovePenguinChainRootOffsets(pc),a4
                movea.w (a4,d6.w),a4
                adda.l  a5,a4
                bsr.w   Boss_LovePenguinCalculateChainPosition
                bra.w   Boss_LovePenguinSecondFormUpdateBody
; End of function Boss_LovePenguinUpdateMovement
; ---------------------------------------------------------------------------
Boss_LovePenguinPrimaryTrackingPoseOffsets:
                dc.w    $2C, 0, $32, 0                  ; DATA XREF: Boss_LovePenguinUpdateMovement+84   o  ; was: word_41C3E
Boss_LovePenguinSecondaryTrackingPoseOffsets:
                dc.w    $42, 0, $34, 0, 8, 0, $E, 0, $40, $FFC0, $FFC0, $FFC0, $FFC0, $FFE0, $FFE0, $FFE0  ; was: word_41C46
                                        ; DATA XREF: Boss_LovePenguinUpdateMovement+98   o
                dc.w    $FFE0, $FFE0, 0, $20, $20, $20, $20, $FF80, $80, $80, $80, $80, 0, $FFE0, $FFE0, $FFE0
                dc.w    $FFE0, $80, $FF80, $FF80, $FF80, $FF80, 0, $40, $40, $40, $40, $FFE0, $FFC0, $FFC0, $FFC0, $FFC0
Boss_LovePenguinPosePatternC:
                dc.w    $1A, 0, $FFCA, 0                ; DATA XREF: Boss_LovePenguinApplyPosePatternCState   o  ; was: word_41CA6
                                        ; Boss_LovePenguinRefillHealthState:Boss_LovePenguinRefillApplyPoseToChain   o
Boss_LovePenguinPosePatternB:
                dc.w    8, 0, $E, 0, $60, $20, $20, $20, $20, $FFA0, $FFE0, $FFE0, $FFE0, $FFE0  ; was: word_41CAE
                                        ; DATA XREF: Boss_LovePenguinApplyPosePatternBState   o
Boss_LovePenguinPosePatternA:
                dc.w    $12, 0, 4, 0, $40, $60, $80, $A0, $C0, 0, 0, 0, 0, 0  ; was: word_41CCA
                                        ; DATA XREF: Boss_LovePenguinApplyPosePatternAState   o

; Calculates target direction based on player position
Boss_LovePenguinCalculateTargetDirection:               ; CODE XREF: Boss_LovePenguinSetIdleState+1C   p  ; was: sub_41CE6
                                        ; Boss_LovePenguinUpdateMovement+B6   p
                jsr     (RandomNumber).l
                andi.w  #$1F,d0
                move.b  d0,(LovePenguinPoseRadius).w
                move.w  $14(a5),d0
                cmpi.w  #$120,d0
                bhi.s   Boss_LovePenguinTargetDirectionUseBodyAngle
                lea     (PlayerObjectType).w,a4
                move.w  PlayerXPosition-PlayerObjectType(a4),d0
                sub.w   $10(a5),d0
                ext.l   d0
                bpl.s   Boss_LovePenguinTargetDirectionStoreDelta
                neg.w   d0
Boss_LovePenguinTargetDirectionStoreDelta:              ; CODE XREF: Boss_LovePenguinCalculateTargetDirection+26   j  ; was: loc_41D10
                add.b   d0,(LovePenguinPoseRadius).w
                swap    d0
                move.b  d0,(LovePenguinTurnControl).w
                swap    d0
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinTargetDirectionUseBodyAngle:            ; CODE XREF: Boss_LovePenguinCalculateTargetDirection+16   j  ; was: loc_41D1E
                move.w  $56(a5),d0
                lsr.w   #1,d0
                ext.w   d0
                lsr.w   #8,d0
                move.b  d0,(LovePenguinTurnControl).w
                move.w  #$1FF,d0
                move.b  d0,(LovePenguinPoseRadius).w
                rts
; End of function Boss_LovePenguinCalculateTargetDirection
; Gets pointer to specific body part based on angle
Boss_LovePenguinGetBodyPartPointer:                     ; CODE XREF: Boss_LovePenguinUpdatePartRotation:Boss_LovePenguinUpdatePartRotationForTarget   p  ; was: sub_41D36
                                        ; Boss_LovePenguinFlipAndAnimate+1E   p
                tst.b   (LovePenguinTurnControl).w
                bmi.s   Boss_LovePenguinResolveBodyPartIndex
                eori.b  #$10,d0
Boss_LovePenguinResolveBodyPartIndex:                   ; CODE XREF: Boss_LovePenguinGetBodyPartPointer+4   j  ; was: loc_41D40
                move.w  d0,d1
                lsr.w   #2,d0
                andi.w  #6,d0
                lea     Boss_LovePenguinChainRootOffsets(pc),a0
                movea.w (a0,d0.w),a4
                adda.l  a5,a4
                rts
; End of function Boss_LovePenguinGetBodyPartPointer
; Updates body part rotation angles with target tracking
Boss_LovePenguinUpdatePartRotation:                     ; CODE XREF: Boss_LovePenguinUpdateMovement+88   p  ; was: sub_41D54
                                        ; Boss_LovePenguinUpdateMovement+9C   p
                move.w  #$20,d2                         ; ' '
Boss_LovePenguinUpdatePartRotationForTarget:            ; CODE XREF: Boss_LovePenguinApplyPosePatternCState+14   p  ; was: loc_41D58
                                        ; Boss_LovePenguinRefillHealthState+26   p
                bsr.s   Boss_LovePenguinGetBodyPartPointer
                move.w  d1,-(sp)
                asl.w   #5,d1
                sub.w   d3,d1
                andi.w  #$FF,d1
                addi.b  #$40,d1                         ; '@'
                btst    #7,d1
                beq.s   Boss_LovePenguinApplyPartPoseSequence
                move.w  d0,d6
Boss_LovePenguinApplyPartPoseSequence:                  ; CODE XREF: Boss_LovePenguinUpdatePartRotation+18   j  ; was: loc_41D70
                move.w  (sp)+,d1
                andi.w  #6,d1
                lea     (a3,d1.w),a0
                adda.w  (a0),a0
                bsr.w   Boss_LovePenguinAnimatePartSequence
                rts
; End of function Boss_LovePenguinUpdatePartRotation
; Animates sequence of connected body parts
Boss_LovePenguinAnimatePartSequence:                    ; CODE XREF: Boss_LovePenguinUpdatePartRotation+28   p  ; was: sub_41D82
                lea     $60(a4),a1
                move.w  #4,d4
Boss_LovePenguinAnimatePartSequenceLoop:                ; CODE XREF: Boss_LovePenguinAnimatePartSequence+36   j  ; was: loc_41D8A
                move.w  (a0)+,d0
                ; Original immediate is $B; memory BTST uses its low three bits
                dc.w    $082C, $000B, $000E             ; btst #$B,$E(a4)
                beq.s   Boss_LovePenguinInterpolatePartPose
                neg.w   d0
Boss_LovePenguinInterpolatePartPose:                    ; CODE XREF: Boss_LovePenguinAnimatePartSequence+10   j  ; was: loc_41D96
                sub.w   $56(a1),d0
                ext.l   d0
                divs.w  d3,d0
                add.w   d0,$56(a1)
                move.w  #1,d0
                cmp.w   $4C(a1),d2
                beq.s   Boss_LovePenguinAdvancePartPose
                bpl.s   Boss_LovePenguinIncreasePartRadius
                neg.w   d0
Boss_LovePenguinIncreasePartRadius:                     ; CODE XREF: Boss_LovePenguinAnimatePartSequence+2A   j  ; was: loc_41DB0
                add.w   d0,$4C(a1)
Boss_LovePenguinAdvancePartPose:                        ; CODE XREF: Boss_LovePenguinAnimatePartSequence+28   j  ; was: loc_41DB4
                adda.w  #$60,a1                         ; '`'
                dbf     d4,Boss_LovePenguinAnimatePartSequenceLoop
                rts
; End of function Boss_LovePenguinAnimatePartSequence
; Spawns projectiles at random positions using jump table
Boss_LovePenguinSpawnRandomProjectile:                  ; CODE XREF: Boss_LovePenguinUpdateMovement+EE   p  ; was: sub_41DBE
                tst.w   (DifficultyMode).w
                beq.w   Boss_LovePenguinSpawnRandomProjectileReturn
Boss_LovePenguinSpawnRandomProjectileFromPart:          ; CODE XREF: Boss_LovePenguinMoveAndShoot+26   p  ; was: loc_41DC6
                jsr     (RandomNumber).l
                andi.w  #6,d0
                movem.l a5,-(sp)
                lea     Boss_LovePenguinChainRootOffsets(pc),a2
                adda.w  d0,a2
                movea.w (a2)+,a5
                adda.l  (sp),a5
                adda.w  #$1E0,a5
                lea     (PlayerObjectType).w,a4
                jsr     (Physics_CalculateAngleToTarget).l
                movem.l d2/a2,-(sp)
                bsr.w   Boss_LovePenguinInitHomingProjectile
                movem.l (sp)+,d2/a2
                movem.l (sp)+,a5
Boss_LovePenguinSpawnRandomProjectileReturn:            ; CODE XREF: Boss_LovePenguinSpawnRandomProjectile+4   j  ; was: locret_41DFC
                rts
; End of function Boss_LovePenguinSpawnRandomProjectile
; Initializes homing projectile with angle offset
Boss_LovePenguinInitHomingProjectile:                   ; CODE XREF: Boss_LovePenguinSpawnRandomProjectile+32   p  ; was: sub_41DFE
                andi.w  #$FF,d0
                subi.b  #$40,d0                         ; '@'
                move.w  d0,-(sp)
                movea.w #(ThirtyFourthEntityType-M68K_RAM),a0
                jsr     (Projectile_FindFreeSlotForward20).l
                bne.s   Boss_LovePenguinInitHomingProjectileReturn
                move.w  (sp)+,d6
                add.w   d6,d6
                move.w  #0,d0
                move.w  #0,d1
                move.w  #$8000,d2
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
Boss_LovePenguinInitHomingProjectileReturn:             ; CODE XREF: Boss_LovePenguinInitHomingProjectile+14   j  ; was: locret_41E2A
                rts
; End of function Boss_LovePenguinInitHomingProjectile
; Jumps to random function for boss pattern variation
Boss_LovePenguinChooseMovementVariation:                ; CODE XREF: Boss_LovePenguinUpdateMovement+DE   j  ; was: sub_41E2C
                lea     Boss_LovePenguinMovementVariationChoices(pc),a0
                jmp     Math_JumpToWeightedChoice
; End of function Boss_LovePenguinChooseMovementVariation
; ---------------------------------------------------------------------------
Boss_LovePenguinMovementVariationChoices:
                dc.w    $2000                           ; DATA XREF: Boss_LovePenguinChooseMovementVariation   o  ; was: word_41E36
                dc.w    Boss_LovePenguinMoveAndShoot-*
                dc.w    $6000
                dc.w    Boss_LovePenguinFlipDirection-*
                dc.w    $6000
                dc.w    Boss_LovePenguinFlipAndAnimate-*
                dc.w    $6000
                dc.w    Boss_LovePenguinBeginMovementState-*

; Moves boss based on player position and spawns projectiles
Boss_LovePenguinMoveAndShoot:                           ; DATA XREF: ROM:00041E38   o  ; was: sub_41E46
                move.w  #$18,4(a5)
                move.b  #$40,$4B(a5)                    ; '@'
; Calculate direction and rotate while attacking
Boss_LovePenguinMoveAndShoot_AttackLoop:                ; DATA XREF: ROM:0004195E   o  ; was: loc_41E52
                bsr.w   Boss_LovePenguinCalculateTargetDirection
                move.b  (LovePenguinTurnControl).w,d0
                ext.w   d0
                add.w   d0,d0
                addq.w  #1,d0
                add.w   d0,$56(a5)
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinMovementUpdatePartFacing
                bsr.w   Boss_LovePenguinSpawnRandomProjectileFromPart
                bra.w   Boss_LovePenguinSetIdleState
; End of function Boss_LovePenguinMoveAndShoot
; Flips boss horizontal direction and updates animation
Boss_LovePenguinFlipDirection:                          ; DATA XREF: ROM:00041E3C   o  ; was: sub_41E74
                move.w  #$12,4(a5)
                andi.b  #8,(LovePenguinChainCycle).w
                move.b  #$20,(LovePenguinChainCycle+1).w  ; ' '
                not.b   (LovePenguinTurnControl).w
                bra.w   Boss_LovePenguinMovementUpdateSelectedChain
; End of function Boss_LovePenguinFlipDirection
; Applies pose pattern A with a randomized target radius
Boss_LovePenguinApplyPosePatternAState:                 ; DATA XREF: ROM:00041958   o  ; was: sub_41E8E
                lea     Boss_LovePenguinPosePatternA(pc),a3
                moveq   #0,d2
                move.b  (LovePenguinPoseRadius).w,d2
                bra.w   Boss_LovePenguinApplySelectedPosePattern
; End of function Boss_LovePenguinApplyPosePatternAState
; Flips direction, toggles sprite flip flag, updates animation
Boss_LovePenguinFlipAndAnimate:                         ; DATA XREF: ROM:00041E40   o  ; was: sub_41E9C
                move.w  #$C,4(a5)
                andi.b  #8,(LovePenguinChainCycle).w
                move.b  #$20,(LovePenguinChainCycle+1).w  ; ' '
                not.b   (LovePenguinTurnControl).w
                move.b  (LovePenguinChainCycle).w,d0
                eori.b  #$14,d0
                bsr.w   Boss_LovePenguinGetBodyPartPointer
                eori.w  #$800,$E(a4)
                bra.w   Boss_LovePenguinMovementUpdateSelectedChain
; End of function Boss_LovePenguinFlipAndAnimate
; Applies pose pattern B with a randomized target radius
Boss_LovePenguinApplyPosePatternBState:                 ; DATA XREF: ROM:00041952   o  ; was: sub_41EC8
                lea     Boss_LovePenguinPosePatternB(pc),a3
                moveq   #0,d2
                move.b  (LovePenguinPoseRadius).w,d2
                bra.w   Boss_LovePenguinApplySelectedPosePattern
; End of function Boss_LovePenguinApplyPosePatternBState
; Applies pose pattern C with a fixed target radius
Boss_LovePenguinApplyPosePatternCState:                 ; DATA XREF: ROM:00041954   o  ; was: sub_41ED6
                                        ; ROM:0004195A   o
                lea     Boss_LovePenguinPosePatternC(pc),a3
                move.w  #$20,d2                         ; ' '
Boss_LovePenguinApplySelectedPosePattern:               ; CODE XREF: Boss_LovePenguinApplyPosePatternAState+A   j  ; was: loc_41EDE
                                        ; Boss_LovePenguinApplyPosePatternBState+A   j
                move.b  (LovePenguinChainCycle+1).w,d3
                move.b  (LovePenguinChainCycle).w,d0
                eori.b  #$14,d0
                bsr.w   Boss_LovePenguinUpdatePartRotationForTarget
                ori.b   #$40,-$3F(a1)                   ; '@'
                subq.b  #1,(LovePenguinChainCycle+1).w
                bne.s   Boss_LovePenguinFinishPosePatternUpdate
                move.b  (LovePenguinChainCycle).w,d0
                addq.b  #4,(LovePenguinChainCycle).w
                move.b  (LovePenguinChainCycle).w,d1
                eor.b   d0,d1
                andi.b  #8,d1
                beq.s   Boss_LovePenguinNormalizePosePatternIndex
                eori.b  #8,(LovePenguinChainCycle).w
                addq.w  #2,4(a5)
                subi.w  #$80,(BossCombatCounter).w
Boss_LovePenguinNormalizePosePatternIndex:              ; CODE XREF: Boss_LovePenguinApplyPosePatternCState+36   j  ; was: loc_41F1E
                andi.b  #$E,(LovePenguinChainCycle).w
                move.b  #$20,(LovePenguinChainCycle+1).w  ; ' '
Boss_LovePenguinFinishPosePatternUpdate:                ; CODE XREF: Boss_LovePenguinApplyPosePatternCState+22   j  ; was: loc_41F2A
                bra.w   Boss_LovePenguinMovementUpdateSelectedChain
; End of function Boss_LovePenguinApplyPosePatternCState
; Checks boss health threshold for behavior branch
Boss_LovePenguinCheckHealthThreshold:                   ; CODE XREF: Boss_LovePenguinFinishTrailTransitionState+C   j  ; was: sub_41F2E
                                        ; DATA XREF: ROM:00041956   o
                andi.b  #$BF,$4A1(a5)
                andi.b  #$BF,$6E1(a5)
                andi.b  #$BF,$921(a5)
                andi.b  #$BF,$B61(a5)
                cmpi.w  #$C0,(BossCombatCounter).w
                bgt.s   Boss_LovePenguinCheckPhaseTransition
                bra.w   Boss_LovePenguinBeginHealthRefillState
; End of function Boss_LovePenguinCheckHealthThreshold
; Checks if boss should transition to next phase
Boss_LovePenguinCheckPhaseTransition:                   ; CODE XREF: Boss_LovePenguinCheckHealthThreshold+1E   j  ; was: sub_41F52
                tst.b   (SecondaryEntityWork5C).w
                bne.w   Boss_LovePenguinBeginChainOscillationState
                bra.w   Boss_LovePenguinSetIdleState
; End of function Boss_LovePenguinCheckPhaseTransition
; Initializes boss recovery state with timer
Boss_LovePenguinBeginHealthRefillState:                 ; CODE XREF: Boss_LovePenguinCheckHealthThreshold+20   j  ; was: sub_41F5E
                move.b  #$C0,$4B(a5)
                move.w  #$1C,4(a5)
; End of function Boss_LovePenguinBeginHealthRefillState
; Refills shared health while applying pose pattern C to all four chains
Boss_LovePenguinRefillHealthState:                      ; DATA XREF: ROM:00041962   o  ; was: sub_41F6A
                addi.w  #2,(BossCombatCounter).w
                cmpi.w  #$1E0,(BossCombatCounter).w
                bge.w   Boss_LovePenguinSetIdleState
                move.w  #0,d0
                move.w  #3,d7
Boss_LovePenguinRefillApplyPoseToChain:                 ; CODE XREF: Boss_LovePenguinRefillHealthState+2E   j  ; was: loc_41F82
                lea     Boss_LovePenguinPosePatternC(pc),a3
                move.w  #$30,d2                         ; '0'
                move.b  (LovePenguinChainCycle+1).w,d3
                move.w  d0,-(sp)
                bsr.w   Boss_LovePenguinUpdatePartRotationForTarget
                move.w  (sp)+,d0
                addq.w  #8,d0
                dbf     d7,Boss_LovePenguinRefillApplyPoseToChain
                bra.w   Boss_LovePenguinMovementUpdateSelectedChain
; End of function Boss_LovePenguinRefillHealthState
; ---------------------------------------------------------------------------
Boss_LovePenguinChainRootOffsets:
                dc.w    $2A0, $4E0, $720, $960          ; was: word_41FA0
                                        ; DATA XREF: Boss_LovePenguinUpdateMovement+FE   o
                                        ; Boss_LovePenguinUpdateMovement+12A   o

; Calculates position using sine/cosine chain physics
Boss_LovePenguinCalculateChainPosition:                 ; CODE XREF: Boss_LovePenguinUpdateMovement+134   p  ; was: sub_41FA8
                move.w  #5,d7
                move.w  $56(a5),d6
                clr.l   d3
                clr.l   d4
                lea     (a4),a3
                movea.l #Math_SineTable,a2
Boss_LovePenguinAccumulateChainOffsets:                 ; CODE XREF: Boss_LovePenguinCalculateChainPosition+38   j  ; was: loc_41FBC
                add.w   $56(a3),d6
                move.w  d6,d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                muls.w  $4C(a3),d0
                muls.w  $4C(a3),d1
                sub.l   d1,d3
                sub.l   d0,d4
                lea     $60(a3),a3
                dbf     d7,Boss_LovePenguinAccumulateChainOffsets
                add.l   -$50(a3),d3
                add.l   -$4C(a3),d4
                move.l  d3,$10(a5)
                move.l  #$E00000,d0
                cmp.l   d0,d4
                bhi.s   Boss_LovePenguinClampChainAnchorY
                move.l  d0,d4
Boss_LovePenguinClampChainAnchorY:                      ; CODE XREF: Boss_LovePenguinCalculateChainPosition+50   j  ; was: loc_41FFC
                move.l  d4,$14(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                rts
; End of function Boss_LovePenguinCalculateChainPosition
