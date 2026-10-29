; Enters the chain-oscillation state after the low-health transition
Boss_LovePenguinBeginChainOscillationState:             ; CODE XREF: Boss_LovePenguinCheckPhaseTransition+4   j  ; was: sub_4200A
                move.w  #$1A,4(a5)
                move.b  #0,$4B(a5)
                move.w  #4,(LovePenguinOscillationPhase).w
                bra.w   Boss_LovePenguinSecondFormUpdate
; End of function Boss_LovePenguinBeginChainOscillationState
; Moves five link radii one unit toward the requested radius
Boss_LovePenguinApproachChainLinkRadius:                ; CODE XREF: Boss_LovePenguinUpdateAllChainRadii+4   p  ; was: sub_42020
                                        ; Boss_LovePenguinUpdateAllChainRadii+A   p
                lea     $60(a4),a3
                move.w  #4,d4
Boss_LovePenguinApproachChainLinkRadiusLoop:            ; CODE XREF: Boss_LovePenguinApproachChainLinkRadius+1E   j  ; was: loc_42028
                move.w  #1,d0
                cmp.w   $4C(a3),d2
                beq.s   Boss_LovePenguinApproachChainLinkRadiusAdvance
                bpl.s   Boss_LovePenguinApproachChainLinkRadiusApplyStep
                neg.w   d0
Boss_LovePenguinApproachChainLinkRadiusApplyStep:       ; CODE XREF: Boss_LovePenguinApproachChainLinkRadius+12   j  ; was: loc_42036
                add.w   d0,$4C(a3)
Boss_LovePenguinApproachChainLinkRadiusAdvance:         ; CODE XREF: Boss_LovePenguinApproachChainLinkRadius+10   j  ; was: loc_4203A
                adda.w  #$60,a3                         ; '`'
                dbf     d4,Boss_LovePenguinApproachChainLinkRadiusLoop
                rts
; End of function Boss_LovePenguinApproachChainLinkRadius
; Updates the link radii of all four chains
Boss_LovePenguinUpdateAllChainRadii:                    ; CODE XREF: Boss_LovePenguinOscillateChainsState+96   p  ; was: sub_42044
                lea     $2A0(a5),a4
                bsr.s   Boss_LovePenguinApproachChainLinkRadius
                lea     $4E0(a5),a4
                bsr.s   Boss_LovePenguinApproachChainLinkRadius
                lea     $720(a5),a4
                bsr.s   Boss_LovePenguinApproachChainLinkRadius
                lea     $960(a5),a4
                bsr.s   Boss_LovePenguinApproachChainLinkRadius
                rts
; End of function Boss_LovePenguinUpdateAllChainRadii
; Oscillates the chain angles while moving between vertical bounds
Boss_LovePenguinOscillateChainsState:                   ; DATA XREF: ROM:00041960   o  ; was: sub_4205E
                move.w  #1,d1
                btst    #0,(FrameCounter).w
                bne.s   Boss_LovePenguinAdvanceChainOscillationPhase
                neg.w   d1
Boss_LovePenguinAdvanceChainOscillationPhase:           ; CODE XREF: Boss_LovePenguinOscillateChainsState+A   j  ; was: loc_4206C
                add.w   d1,(LovePenguinOscillationPhase).w
                move.w  #$70,d1                         ; 'p'
                move.w  d1,d2
                move.w  (LovePenguinOscillationPhase).w,d0
                bpl.s   Boss_LovePenguinClampChainOscillationPhase
                neg.w   d0
                neg.w   d1
Boss_LovePenguinClampChainOscillationPhase:             ; CODE XREF: Boss_LovePenguinOscillateChainsState+1C   j  ; was: loc_42080
                cmp.w   d2,d0
                bcs.s   Boss_LovePenguinUpdateOscillationVelocity
                move.w  d1,(LovePenguinOscillationPhase).w
Boss_LovePenguinUpdateOscillationVelocity:              ; CODE XREF: Boss_LovePenguinOscillateChainsState+24   j  ; was: loc_42088
                movea.l #Math_SineTable,a2
                move.b  (SecondaryEntityWork5C+1).w,d1
                add.w   d1,d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                move.w  #2,d2
                ext.l   d1
                asl.l   d2,d1
                move.l  d1,$18(a5)
                move.w  $14(a5),d1
                tst.l   $1C(a5)
                beq.s   Boss_LovePenguinSetUpwardVelocity
                bpl.s   Boss_LovePenguinCheckLowerVerticalBound
                cmpi.w  #$C0,d1
                bhi.s   Boss_LovePenguinUpdateOscillatingChains
                move.l  #$10000,$1C(a5)
                bra.w   Boss_LovePenguinUpdateOscillatingChains
; ---------------------------------------------------------------------------
Boss_LovePenguinCheckLowerVerticalBound:                ; CODE XREF: Boss_LovePenguinOscillateChainsState+5A   j  ; was: loc_420CC
                cmpi.w  #$160,d1
                bcs.s   Boss_LovePenguinUpdateOscillatingChains
Boss_LovePenguinSetUpwardVelocity:                      ; CODE XREF: Boss_LovePenguinOscillateChainsState+58   j  ; was: loc_420D2
                move.l  #$FFFF0000,$1C(a5)
                bra.w   *+4
; ---------------------------------------------------------------------------
Boss_LovePenguinUpdateOscillatingChains:                ; CODE XREF: Boss_LovePenguinOscillateChainsState+60   j  ; was: loc_420DE
                                        ; Boss_LovePenguinOscillateChainsState+6A   j
                move.w  (LovePenguinOscillationPhase).w,d0
                bsr.w   Boss_LovePenguinUpdateChainRootAngles
                move.w  (LovePenguinOscillationPhase).w,d2
                bpl.s   Boss_LovePenguinUseOscillationMagnitude
                neg.w   d2
Boss_LovePenguinUseOscillationMagnitude:                ; CODE XREF: Boss_LovePenguinOscillateChainsState+8C   j  ; was: loc_420EE
                lsr.w   #2,d2
                addi.w  #$20,d2                         ; ' '
                bsr.w   Boss_LovePenguinUpdateAllChainRadii
                move.w  (LovePenguinOscillationPhase).w,d1
                asr.w   #3,d1
                add.w   d1,$56(a5)
                bra.w   Boss_LovePenguinSecondFormUpdate
; End of function Boss_LovePenguinOscillateChainsState
; Supplies a common target angle to all four chain roots
Boss_LovePenguinUpdateChainRootAngles:                  ; CODE XREF: Boss_LovePenguinOscillateChainsState+84   p  ; was: sub_42106
                move.w  d0,-(sp)
                move.w  d0,-(sp)
                move.w  d0,-(sp)
                move.w  d0,-(sp)
                lea     (sp),a3
                bsr.w   Boss_LovePenguinInterpolateChainRootAngles
                addq.w  #8,sp
                rts
; End of function Boss_LovePenguinUpdateChainRootAngles
; Smoothly approaches the target angle of each chain root
Boss_LovePenguinInterpolateChainRootAngles:             ; CODE XREF: Boss_LovePenguinUpdateChainRootAngles+A   p  ; was: sub_42118
                lea     Boss_LovePenguinChainRootOffsets(pc),a2
                move.w  #3,d4
Boss_LovePenguinInterpolateChainRootAnglesLoop:         ; CODE XREF: Boss_LovePenguinInterpolateChainRootAngles+1C   j  ; was: loc_42120
                movea.w (a2)+,a4
                adda.w  a5,a4
                move.w  (LovePenguinPartYReference).w,d2
                add.w   (a3)+,d2
                sub.w   $58(a4),d2
                asr.w   #3,d2
                add.w   d2,$58(a4)
                dbf     d4,Boss_LovePenguinInterpolateChainRootAnglesLoop
                rts
; End of function Boss_LovePenguinInterpolateChainRootAngles
; Calculates horizontal direction to player
Boss_LovePenguinGetDirectionToPlayer:
                move.w  #1,d1                           ; was: sub_4213A
                lea     (PlayerObjectType).w,a0
                move.w  PlayerXPosition-PlayerObjectType(a0),d0
                sub.w   $10(a5),d0
                bhi.s   Boss_LovePenguinGetDirectionToPlayerReturn
                neg.w   d1
Boss_LovePenguinGetDirectionToPlayerReturn:             ; CODE XREF: Boss_LovePenguinGetDirectionToPlayer+10   j  ; was: locret_4214E
                rts
; End of function Boss_LovePenguinGetDirectionToPlayer
; Descends while firing, then enables collision on all four chains
Boss_LovePenguinDescendAndActivateChainsState:          ; DATA XREF: ROM:00041964   o  ; was: sub_42150
                addi.l  #$400,$1C(a5)
                move.l  #$200020,d1
                jsr     (Boss_LovePenguinSpawnRandomOffsetProjectile).l
                cmpi.w  #$1C0,$14(a5)
                bcs.w   Boss_LovePenguinSecondFormUpdateBody
                addq.w  #2,4(a5)
                move.b  #$20,$4B(a5)                    ; ' '
                clr.l   $1C(a5)
                ori.b   #$40,$4A1(a5)                   ; '@'
                ori.b   #$10,$4A3(a5)
                ori.b   #$40,$6E1(a5)                   ; '@'
                ori.b   #$10,$6E3(a5)
                ori.b   #$40,$921(a5)                   ; '@'
                ori.b   #$10,$923(a5)
                ori.b   #$40,$B61(a5)                   ; '@'
                ori.b   #$10,$B63(a5)
                bra.w   Boss_LovePenguinSecondFormUpdateBody
; End of function Boss_LovePenguinDescendAndActivateChainsState
; Waits while firing, then activates the eight trail objects
Boss_LovePenguinWaitThenActivateTrailState:             ; DATA XREF: ROM:00041966   o  ; was: sub_421B0
                move.l  #$400040,d1
                jsr     (Boss_LovePenguinSpawnRandomOffsetProjectile).l
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinSecondFormUpdateBody
                addq.w  #2,4(a5)
                move.w  $14(a5),(LovePenguinTrailSpan).w
                clr.w   (LovePenguinTrailStep).w
                lea     $BA0(a5),a4
                move.w  #7,d4
Boss_LovePenguinActivateTrailObjectsLoop:               ; CODE XREF: Boss_LovePenguinWaitThenActivateTrailState+3A   j  ; was: loc_421DA
                move.w  $14(a5),$14(a4)
                ori.w   #$8000,2(a4)
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinActivateTrailObjectsLoop
                bra.w   Boss_LovePenguinSecondFormUpdateBody
; End of function Boss_LovePenguinWaitThenActivateTrailState
; Contracts the vertical trail span until it reaches $80
Boss_LovePenguinContractTrailState:                     ; DATA XREF: ROM:00041968   o  ; was: sub_421F2
                move.l  #$400040,d1
                jsr     (Boss_LovePenguinSpawnRandomOffsetProjectile).l
                addq.w  #1,(LovePenguinTrailStep).w
                move.w  (LovePenguinTrailStep).w,d0
                lsr.w   #2,d0
                sub.w   d0,(LovePenguinTrailSpan).w
                cmpi.w  #$80,(LovePenguinTrailSpan).w
                bhi.w   Boss_LovePenguinSecondFormUpdateBody
                addq.w  #2,4(a5)
                move.b  #$20,$4B(a5)                    ; ' '
                bra.w   Boss_LovePenguinSecondFormUpdateBody
; End of function Boss_LovePenguinContractTrailState
; Finishes the trail transition and returns to health-state selection
Boss_LovePenguinFinishTrailTransitionState:             ; DATA XREF: ROM:0004196A   o  ; was: sub_42224
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinSecondFormUpdateBody
                clr.b   (BossColorEffectFlags).w
                bra.w   Boss_LovePenguinCheckHealthThreshold
; End of function Boss_LovePenguinFinishTrailTransitionState
; Calculates a direction-dependent horizontal screen offset
Boss_LovePenguinCalculateDirectionalScreenOffset:
                move.w  (PrimaryCameraXPosition).w,d0   ; was: sub_42234
                add.w   $10(a5),d0
                tst.w   $18(a5)
                bpl.s   Boss_LovePenguinCalculateRightwardScreenOffset
                subi.w  #$12C0,d0
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinCalculateRightwardScreenOffset:         ; CODE XREF: Boss_LovePenguinCalculateDirectionalScreenOffset+C   j  ; was: loc_42248
                move.w  #$1400,d1
                sub.w   d0,d1
                rts
; End of function Boss_LovePenguinCalculateDirectionalScreenOffset
; Faces the player and adds the caller-provided angle offset
Boss_LovePenguinFacePlayerWithAngleOffset:
                andi.w  #$F7FF,$E(a5)                   ; was: sub_42250
                movem.l d3,-(sp)
                lea     (PlayerObjectType).w,a4
                jsr     (Physics_CalculateAngleToTarget).l
                movem.l (sp)+,d3
                move.b  d0,d2
                bpl.s   Boss_LovePenguinStoreFacingAngle
                ori.w   #$800,$E(a5)
                neg.b   d2
Boss_LovePenguinStoreFacingAngle:                       ; CODE XREF: Boss_LovePenguinFacePlayerWithAngleOffset+1A   j  ; was: loc_42274
                move.w  d3,$5A(a5)
                add.w   $5A(a5),d2
                move.w  d2,6(a5)
                rts
; End of function Boss_LovePenguinFacePlayerWithAngleOffset
; Moves the body angle one quarter of the way toward the facing angle
Boss_LovePenguinInterpolateBodyAngle:
                move.w  $56(a5),d1                      ; was: sub_42282
                lsr.w   #1,d1
                move.w  6(a5),d0
                sub.b   d1,d0
                asr.b   #2,d0
                ext.w   d0
                add.w   d0,$56(a5)
                rts
; End of function Boss_LovePenguinInterpolateBodyAngle
; Shared update for the later segmented form
Boss_LovePenguinSecondFormUpdate:                       ; CODE XREF: Boss_LovePenguinBeginChainOscillationState+12   j  ; was: sub_42298
                                        ; Boss_LovePenguinOscillateChainsState+A4   j
                lea     $960(a5),a4
                jsr     Boss_LovePenguinUpdateChainEndpointMotion(pc)  ; (pc)
                nop
                lea     $2A0(a5),a4
                jsr     Boss_LovePenguinUpdateChainEndpointMotion(pc)  ; (pc)
                nop
                lea     $4E0(a5),a4
                jsr     Boss_LovePenguinUpdateChainEndpointMotion(pc)  ; (pc)
                nop
                lea     $720(a5),a4
                jsr     Boss_LovePenguinUpdateChainEndpointMotion(pc)  ; (pc)
                nop
Boss_LovePenguinSecondFormUpdateBody:                   ; CODE XREF: Boss_LovePenguinUpdateMovement+138   j  ; was: loc_422C0
                                        ; Boss_LovePenguinDescendAndActivateChainsState+1A   j
                move.b  (LovePenguinAimAngle).w,d0
                add.w   d0,d0
                sub.w   $56(a5),d0
                move.w  d0,$B6(a5)
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_LovePenguinSecondFormRender
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_LovePenguinSecondFormRender
                move.w  (BossHealth).w,d0
                beq.w   Boss_LovePenguinResetAfterPrimaryHealthDepletion
                tst.b   (SecondaryEntityWork5C).w
                bne.s   Boss_LovePenguinSecondFormRender
                cmpi.w  #$3000,d0
                bhi.s   Boss_LovePenguinSecondFormRender
                move.b  #1,(SecondaryEntityWork5C).w
                move.w  #$1E,4(a5)
                move.b  #6,(BossColorEffectFlags).w
                clr.l   $18(a5)
                clr.l   $1C(a5)
Boss_LovePenguinSecondFormRender:                       ; CODE XREF: Boss_LovePenguinSecondFormUpdate+3C   j  ; was: loc_4230C
                                        ; Boss_LovePenguinSecondFormUpdate+44   j
                lea     Boss_LovePenguinSecondFormBodyPartInitTable(pc),a1
                jsr     (Boss_LovePenguinUpdateBodyPartPositions).l
                bsr.w   Boss_LovePenguinUpdateScreenBounds
                lea     Boss_LovePenguinSecondFormTileAnimationOffsets(pc),a0
                move.w  (LovePenguinAnimationProgress).w,d0
                lsr.w   #2,d0
                bsr.w   Gfx_LoadIndexedAnimationTiles
                addq.w  #1,(LovePenguinAnimationProgress).w
                ori.w   #$1800,$48E(a5)
                andi.w  #$E7FF,$6CE(a5)
                andi.w  #$E7FF,$90E(a5)
                ori.w   #$1800,$B4E(a5)
                bsr.w   Boss_LovePenguinUpdateTrail
                rts
; End of function Boss_LovePenguinSecondFormUpdate
; Propagates chain angles and derives endpoint motion
Boss_LovePenguinUpdateChainEndpointMotion:              ; CODE XREF: Boss_LovePenguinSecondFormUpdate+4   p  ; was: sub_4234A
                                        ; Boss_LovePenguinSecondFormUpdate+E   p
                move.w  $58(a4),d2
                tst.b   d2
                bpl.s   Boss_LovePenguinNormalizeChainRootAngle
                neg.b   d2
                subq.b  #1,d2
Boss_LovePenguinNormalizeChainRootAngle:                ; CODE XREF: Boss_LovePenguinUpdateChainEndpointMotion+6   j  ; was: loc_42356
                andi.w  #$7F,d2
                subi.w  #$40,d2                         ; '@'
                lea     $60(a4),a3
                move.w  d2,$56(a3)
                move.w  #4,d4
Boss_LovePenguinCopyChainLinkAnglesLoop:                ; CODE XREF: Boss_LovePenguinUpdateChainEndpointMotion+2A   j  ; was: loc_4236A
                move.w  $B6(a4),$56(a3)
                adda.w  #$60,a3                         ; '`'
                dbf     d4,Boss_LovePenguinCopyChainLinkAnglesLoop
                movea.l #Math_SineTable,a2
                move.w  $56(a5),d1
                add.w   $56(a4),d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                muls.w  $4C(a4),d0
                muls.w  $4C(a4),d1
                add.l   -$4C(a3),d0
                sub.l   $14(a4),d0
                move.l  -4(a3),d2
                move.l  d0,-4(a3)
                sub.l   d2,d0
                neg.l   d0
                move.l  d0,-$44(a3)
                add.l   -$50(a3),d1
                sub.l   $10(a4),d1
                move.l  -8(a3),d0
                move.l  d1,-8(a3)
                sub.l   d0,d1
                neg.l   d1
                move.l  d1,-$48(a3)
                rts
; End of function Boss_LovePenguinUpdateChainEndpointMotion
; Resolves an indexed animation entry and loads its compressed tiles
Gfx_LoadIndexedAnimationTiles:                          ; CODE XREF: Boss_LovePenguinSecondFormUpdate+8C   p  ; was: sub_423CE
                and.w   (a0)+,d0
                adda.w  d0,a0
                adda.w  (a0),a0
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadIndexedAnimationTiles
; Resets the form controller after primary boss health reaches zero
Boss_LovePenguinResetAfterPrimaryHealthDepletion:       ; CODE XREF: Boss_LovePenguinSecondFormUpdate+4A   j  ; was: sub_423DA
                bset    #0,(StageTimerPauseFlag).w
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.w  #$7FFF,(BossHealth).w
                clr.b   (SecondaryEntityWork5C).w
                clr.w   4(a5)
                clr.l   $18(a5)
                move.l  #$FFFF0000,$1C(a5)
                bra.w   Boss_LovePenguinSecondFormUpdate
; End of function Boss_LovePenguinResetAfterPrimaryHealthDepletion
; Waits, then scatters the body parts with randomized motion
Boss_LovePenguinScatterSecondFormBodyPartsState:
                subq.b  #1,$4B(a5)                      ; was: sub_4240A
                bne.w   Boss_LovePenguinSecondFormUpdate
                addq.w  #2,4(a5)
                clr.b   $21(a5)
                move.w  (LovePenguinBodyPartCount).w,d4
                subq.w  #2,d4
                lea     $60(a5),a4
                lea     (Math_SineTable).l,a2
Boss_LovePenguinInitializeScatteredBodyPartsLoop:       ; CODE XREF: Boss_LovePenguinScatterSecondFormBodyPartsState+6A   j  ; was: loc_4242A
                move.w  #$CD40,2(a4)
                jsr     (RandomNumber).l
                rol.l   #8,d0
                move.w  d0,d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                muls.w  #4,d1
                muls.w  #4,d0
                move.l  d1,$18(a4)
                move.l  d0,$1C(a4)
                clr.b   $4B(a4)
                jsr     (RandomNumber).l
                rol.l   #8,d0
                ext.w   d0
                asr.w   #3,d0
                move.w  d0,$5C(a4)
                clr.b   $21(a4)
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinInitializeScatteredBodyPartsLoop
                addi.l  #$800,$1C(a5)
                cmpi.w  #$1C0,$14(a5)
                bhi.s   Boss_LovePenguinBeginStaggeredBodyPartRemoval
                move.l  #$200020,d1
                bsr.w   Boss_LovePenguinSpawnDefeatImpact
                bsr.w   Boss_LovePenguinUpdateScreenBounds
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinBeginStaggeredBodyPartRemoval:          ; CODE XREF: Boss_LovePenguinScatterSecondFormBodyPartsState+7C   j  ; was: loc_42498
                move.b  #$40,$4B(a5)                    ; '@'
                addq.w  #2,4(a5)
                move.w  #1,d5
                move.w  (LovePenguinBodyPartCount).w,d4
                subq.w  #2,d4
                lea     $60(a5),a4
Boss_LovePenguinAssignBodyPartRemovalDelayLoop:         ; CODE XREF: Boss_LovePenguinScatterSecondFormBodyPartsState+B0   j  ; was: loc_424B0
                move.b  d5,$4B(a4)
                addq.w  #1,d5
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinAssignBodyPartRemovalDelayLoop
                rts
; End of function Boss_LovePenguinScatterSecondFormBodyPartsState
; Holds the scroll mode, then removes the form controller
Boss_LovePenguinRemoveAfterBodyPartFadeState:
                move.w  #4,(PlaneAShakeLevel).w         ; was: sub_424C0
                move.w  #4,(PlaneBShakeLevel).w
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinRemoveAfterBodyPartFadeReturn
                clr.w   (a5)
Boss_LovePenguinRemoveAfterBodyPartFadeReturn:          ; CODE XREF: Boss_LovePenguinRemoveAfterBodyPartFadeState+10   j  ; was: locret_424D6
                rts
; End of function Boss_LovePenguinRemoveAfterBodyPartFadeState
; Animates a scattered body part until its staggered removal delay expires
Boss_LovePenguinUpdateScatteredBodyPart:
                tst.b   $4B(a5)                         ; was: sub_424D8
                beq.s   Boss_LovePenguinAnimateScatteredBodyPart
                subq.b  #1,$4B(a5)
                beq.s   Boss_LovePenguinConvertBodyPartToExplosion
Boss_LovePenguinAnimateScatteredBodyPart:               ; CODE XREF: Boss_LovePenguinUpdateScatteredBodyPart+4   j  ; was: loc_424E4
                move.w  $5C(a5),d0
                add.w   d0,$56(a5)
                move.l  $50(a5),d0
                beq.s   Boss_LovePenguinUpdateScatteredBodyPartReturn
                movea.l d0,a1
                move.w  $56(a5),d0
                lsr.w   #3,d0
                andi.w  #$1C,d0
                move.l  (a1,d0.w),8(a5)
Boss_LovePenguinUpdateScatteredBodyPartReturn:          ; CODE XREF: Boss_LovePenguinUpdateScatteredBodyPart+18   j  ; was: locret_42504
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinConvertBodyPartToExplosion:             ; CODE XREF: Boss_LovePenguinUpdateScatteredBodyPart+A   j  ; was: loc_42506
                lea     (a5),a0
                jsr     (Effect_InitSharedExplosion).l
                clr.b   $21(a5)
                rts
; End of function Boss_LovePenguinUpdateScatteredBodyPart
; Spawns a shared impact sprite at a random offset with mirrored velocity
Boss_LovePenguinSpawnDefeatImpact:                      ; CODE XREF: Boss_LovePenguinScatterSecondFormBodyPartsState+84   p  ; was: sub_42514
                move.l  d1,-(sp)
                jsr     (Projectile_PrepareImpactSpawn).l
                bne.s   Boss_LovePenguinSpawnDefeatImpactReturn
                jsr     (Sprite_InitFromTable).l
                clr.b   $20(a0)
                move.l  $18(a5),$18(a0)
                move.l  $1C(a5),$1C(a0)
                neg.l   $18(a0)
                neg.l   $1C(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                move.w  (sp),d2
                add.w   d2,d2
                subq.w  #1,d2
                and.w   d2,d0
                sub.w   (sp),d0
                move.w  2(sp),d2
                add.w   d2,d2
                subq.w  #1,d2
                and.w   d2,d1
                sub.w   2(sp),d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_LovePenguinSpawnDefeatImpactReturn:                ; CODE XREF: Boss_LovePenguinSpawnDefeatImpact+8   j  ; was: loc_4256C
                move.l  (sp)+,d1
                rts
; End of function Boss_LovePenguinSpawnDefeatImpact
; Updates boss screen boundary values
Boss_LovePenguinUpdateScreenBounds:                     ; CODE XREF: Boss_LovePenguinSecondFormUpdate+7E   p  ; was: sub_42570
                                        ; Boss_LovePenguinScatterSecondFormBodyPartsState+88   p
                move.w  #$A8,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$48,d0                         ; 'H'
                move.w  d0,(SecondaryCameraYPos).w
                jmp     Boss_ClampSharedScreenPosition
; End of function Boss_LovePenguinUpdateScreenBounds
; ---------------------------------------------------------------------------
Boss_LovePenguinSecondFormBodyPartInitTable:
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorA  ; DATA XREF: Boss_LovePenguinSecondFormLoadGraphicsState+28   o  ; was: off_4258E
                                        ; Boss_LovePenguinSecondFormUpdate:Boss_LovePenguinSecondFormRender   o
                dc.l    0
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorA
                dc.l    $100140
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinSecondFormSpriteMapping
                dc.l    $A10000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorC
                dc.l    $200190
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorC
                dc.l    $200070
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorD
                dc.l    $3001D0
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorD
                dc.l    $300030
                dc.l    $80000000
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $A10040
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    SharedVictorSunsetStingSegmentMappingA
                dc.l    $210000
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $A100C0
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    SharedVictorSunsetStingSegmentMappingA
                dc.l    $210000
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $A10140
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    SharedVictorSunsetStingSegmentMappingA
                dc.l    $210000
                dc.l    $80000000
                dc.l    $80000001
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $A101C0
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    Boss_LovePenguinBodyPartSpriteDescriptorB
                dc.l    $210000
                dc.l    SharedVictorSunsetStingSegmentMappingA
                dc.l    $210000
                dc.l    $80000000
                dc.l    $80000000
Boss_LovePenguinSecondFormObjectInitTable:
                dc.w    $C620, $1408, $E41C, $E41C, $10, $C6E0, $1078, $F010, $F010, $10, $CAA0, $1008, $F010, $F010, $10, $C980  ; was: word_426DA
                                        ; DATA XREF: Boss_LovePenguinSecondFormLoadGraphicsState+C   o
                dc.w    $1008, $F010, $F010, $10, $CCE0, $1008, $F010, $F010, $10, $CBC0, $1008, $F010, $F010, $10, $CF20, $1008
                dc.w    $F010, $F010, $10, $CE00, $1008, $F010, $F010, $10, $D160, $1008, $F010, $F010, $10, $D040, $1008, $F010
                dc.w    $F010, $10, $FFFE

; Initializes eight trail objects with graphics pointer and properties
Boss_LovePenguinInitTrail:                              ; CODE XREF: Boss_LovePenguinSecondFormLoadGraphicsState+34   p  ; was: sub_42740
                lea     $BA0(a5),a4
                move.w  #7,d4
Boss_LovePenguinInitTrailLoop:                          ; CODE XREF: Boss_LovePenguinInitTrail+2A   j  ; was: loc_42748
                move.w  #$4000,2(a4)
                move.l  #Boss_LovePenguinBodyPartSpriteDescriptorB,8(a4)
                move.w  #$10,(a4)
                move.w  $E(a5),$E(a4)
                move.b  #$C8,$20(a4)
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinInitTrailLoop
                rts
; End of function Boss_LovePenguinInitTrail
; Updates trail-object positions following boss movement
Boss_LovePenguinUpdateTrail:                            ; CODE XREF: Boss_LovePenguinSecondFormUpdate+AC   p  ; was: sub_42770
                lea     $BA0(a5),a4
                btst    #7,2(a4)
                beq.s   Boss_LovePenguinUpdateTrailReturn
                move.w  $10(a5),d1
                move.l  $14(a5),d2
                subi.l  #$200000,d2
                move.l  d2,d3
                moveq   #0,d0
                move.w  (LovePenguinTrailSpan).w,d0
                swap    d0
                sub.l   d0,d3
                asr.l   #3,d3
                move.w  #7,d4
Boss_LovePenguinPositionTrailObjectsLoop:               ; CODE XREF: Boss_LovePenguinUpdateTrail+3A   j  ; was: loc_4279C
                move.w  d1,$10(a4)
                move.l  d2,$14(a4)
                sub.l   d3,d2
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinPositionTrailObjectsLoop
Boss_LovePenguinUpdateTrailReturn:                      ; CODE XREF: Boss_LovePenguinUpdateTrail+A   j  ; was: locret_427AE
                rts
; End of function Boss_LovePenguinUpdateTrail
