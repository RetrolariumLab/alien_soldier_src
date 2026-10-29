; Victor main controller, initialization, and twelve-part ring attacks
; Dispatches Victor entities by the subtype stored at offset $48
Entity_VictorSubtypeDispatcher:                         ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_323E2
                move.w  $48(a5),d0
                lea     Entity_VictorSubtypeHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Entity_VictorSubtypeDispatcher
; ---------------------------------------------------------------------------
Entity_VictorSubtypeHandlers:   dc.w    Boss_VictorMain-*  ; DATA XREF: Entity_VictorSubtypeDispatcher+4   o  ; was: off_323EE
                dc.w    Boss_VictorOrbitingPartAimAtPlayer-*
                dc.w    Boss_VictorOrbitingPartTrackPlayer-*
                dc.w    Boss_VictorOrbitingPartRadialMain-*
                dc.w    Boss_VictorDetachedPartMain-*
                dc.w    Boss_VictorOrbitingPartCollisionMain-*

; Updates Victor's palette fade and dispatches the current main state
Boss_VictorMain:                                        ; DATA XREF: ROM:Entity_VictorSubtypeHandlers   o  ; was: sub_323FA
                jsr     (Gfx_ProcessDefaultColorFade).l
                cmpi.w  #$1E,4(a5)
                bcc.s   Boss_VictorDispatchState
                tst.w   (BossHealth).w
                bne.s   Boss_VictorDispatchState
                move.w  #1,(SharedScratchLong5+2).w
                bset    #0,(StageTimerPauseFlag).w
                move.w  #$1E,4(a5)
Boss_VictorDispatchState:                               ; CODE XREF: Boss_VictorMain+C   j  ; was: loc_32420
                                        ; Boss_VictorMain+12   j
                move.w  4(a5),d0
                lea     Boss_VictorStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_VictorMain
; ---------------------------------------------------------------------------
Boss_VictorStates:  dc.w    Boss_VictorInit-*           ; DATA XREF: Boss_VictorMain+2A   o  ; was: off_3242C
                dc.w    Boss_VictorFlyIn-*
                dc.w    Boss_VictorWaitForArenaReady-*
                dc.w    Boss_VictorChooseAttack-*
                dc.w    Boss_VictorDeployRing-*
                dc.w    Boss_VictorReverseRing-*
                dc.w    Boss_VictorRetractRing-*
                dc.w    Boss_VictorReturnToCenterline-*
                dc.w    Boss_VictorPreparePartLaunch-*
                dc.w    Boss_VictorContractPartFormation-*
                dc.w    Boss_VictorExpandPartFormation-*
                dc.w    Boss_VictorWaitAfterPartLaunch-*
                dc.w    Boss_VictorBeginSplitShotCountdown-*
                dc.w    Boss_VictorUpdateSplitShotCountdown-*
                dc.w    Boss_VictorWaitAfterSplitShots-*
                dc.w    Boss_VictorBeginDefeatDelay-*
                dc.w    Boss_VictorUpdateDefeatExplosion-*

; Initializes Victor, its two core parts, and eight orbiting parts
Boss_VictorInit:                                        ; DATA XREF: ROM:Boss_VictorStates   o  ; was: sub_3244E
                clr.w   (SharedScratchLong5+2).w
                move.w  #$100,$14(a5)
                move.w  #$200,$10(a5)
                bsr.w   Boss_VictorUpdateViewportOffset
                tst.w   (DataLoaderControl).w
                bmi.w   Entity_UpdateReturn
                move.l  #Boss_VictorAnimationTimingScript,(SharedScratchLong0).w
                move.w  #1,(SharedScratchLong1).w
                move.b  #4,(PlaneAScrollModeFlags).w
                move.b  #$50,$21(a5)                    ; 'P'
                move.b  #$98,$23(a5)
                move.w  #$18,$24(a5)
                move.w  #$8C00,2(a5)
                move.w  #$E00,8(a5)
                move.w  #$F0F8,$A(a5)
                move.w  #$632C,$E(a5)
                move.l  #$D828D828,$2C(a5)
                move.l  #$D030D030,$28(a5)
                move.b  #$54,$20(a5)                    ; 'T'
                move.w  #$64,$26(a5)                    ; 'd'
                movea.l #Boss_VictorInitialGraphicsLoadDescriptor,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$FFFE,$18(a5)
                move.l  #$80000,(SharedScratchLong3+2).w
                addq.w  #2,4(a5)
                movea.w a5,a4
                adda.w  #$60,a4                         ; '`'
                bsr.w   Boss_VictorInitPart
                move.w  #2,$48(a4)
                move.w  #0,8(a4)
                move.w  #$FCFC,$A(a4)
                move.w  #$6351,$E(a4)
                move.w  #$100,$40(a4)
                move.w  #$14,$42(a4)
                move.w  a5,$44(a4)
                adda.w  #$60,a4                         ; '`'
                bsr.w   Boss_VictorInitPart
                move.w  #2,$48(a4)
                move.w  #0,8(a4)
                move.w  #$FCFC,$A(a4)
                move.w  #$6352,$E(a4)
                move.w  #$100,$40(a4)
                move.w  #$10,$42(a4)
                move.w  a5,$44(a4)
                adda.w  #$60,a4                         ; '`'
                move.w  #7,d6
Boss_VictorInitNextOrbitingPart:                        ; CODE XREF: Boss_VictorInit+130   j  ; was: loc_3254C
                adda.w  #$60,a4                         ; '`'
                bsr.w   Boss_VictorInitPart
                move.w  #6,$48(a4)
                move.w  #$500,8(a4)
                move.w  #$F8F8,$A(a4)
                move.w  #$6334,$E(a4)
                move.w  d6,d0
                lsl.w   #6,d0
                move.w  d0,$40(a4)
                move.w  #$C0,$42(a4)
                move.w  a5,$44(a4)
                dbf     d6,Boss_VictorInitNextOrbitingPart
                rts
; End of function Boss_VictorInit
; Flying enemy main handler
Boss_VictorInitPart:                                    ; CODE XREF: Boss_VictorInit+9A   p  ; was: sub_32584
                                        ; Boss_VictorInit+CA   p
                move.w  #$8C00,2(a4)
                move.w  #$6300,$E(a4)
                move.b  #$50,$20(a4)                    ; 'P'
                move.b  #$40,$21(a4)                    ; '@'
                move.l  #$FC04FC04,$2C(a4)
                move.w  #$32,$26(a4)                    ; '2'
                move.w  #$3C0,(a4)
                clr.w   4(a4)
                move.w  $10(a5),$10(a4)
                move.w  $14(a5),$14(a4)
                rts
; End of function Boss_VictorInitPart
; Initializes flying enemy
Boss_VictorUpdateViewportOffset:                        ; CODE XREF: Boss_VictorInit+10   p  ; was: sub_325C0
                                        ; Boss_VictorFlyIn+4   p
                move.w  #$2A8,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                subi.w  #$A8,d0
                move.w  d0,(SecondaryCameraYPos).w
                rts
; End of function Boss_VictorUpdateViewportOffset
; Updates boss animation frames by loading compressed tile data on timer
Boss_VictorUpdateAnimation:                             ; CODE XREF: Boss_VictorFlyIn+8   p  ; was: sub_325DA
                                        ; Boss_VictorWaitForArenaReady+8   p
                subq.w  #1,(SharedScratchLong1).w
                bne.w   Entity_UpdateReturn
                movea.l (SharedScratchLong0).w,a0
                tst.w   (a0)
                bpl.s   Boss_VictorRestartAnimationScript
                movea.l #Boss_VictorAnimationTimingScript,a0
Boss_VictorRestartAnimationScript:                      ; CODE XREF: Boss_VictorUpdateAnimation+E   j  ; was: loc_325F0
                move.w  (a0)+,(SharedScratchLong1).w
                move.w  (a0)+,d0
                move.l  a0,(SharedScratchLong0).w
                movea.l Boss_VictorAnimationGraphicsTable(pc,d0.w),a0
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_VictorUpdateAnimation
; ---------------------------------------------------------------------------
Boss_VictorAnimationTimingScript:   dc.w    8, 8, 8, $C, 8, 8, $40, 4  ; was: word_32604
                                        ; DATA XREF: Boss_VictorInit+1C   o
                                        ; Boss_VictorUpdateAnimation+10   o
                dc.w    8, 8, 8, $C, 8, 8, 8, 4
                dc.w    8, 8, 8, $C, 8, 8, $40, 4
                dc.w    $FFFF
Boss_VictorAnimationGraphicsTable:  dc.l    Boss_VictorAnimationGraphicsFrame0  ; DATA XREF: Boss_VictorUpdateAnimation+20   r  ; was: off_32636
                dc.l    Boss_VictorAnimationGraphicsFrame1
                dc.l    Boss_VictorAnimationGraphicsFrame2
                dc.l    Boss_VictorAnimationGraphicsFrame3
Boss_VictorAnimationGraphicsFrame0: dc.w    $6206, $2000, 0, $5EFF  ; was: word_32646
                                        ; DATA XREF: ROM:Boss_VictorAnimationGraphicsTable   o
Boss_VictorAnimationGraphicsFrame1: dc.w    $6206, $2000, 0, $5CFF  ; was: word_3264E
                                        ; DATA XREF: ROM:0003263A   o
Boss_VictorAnimationGraphicsFrame2: dc.w    $6206, $2000, 0, $60FF  ; was: word_32656
                                        ; DATA XREF: ROM:0003263E   o
Boss_VictorAnimationGraphicsFrame3: dc.w    $6206, $2000, 0, $64FF  ; was: word_3265E
                                        ; DATA XREF: ROM:00032642   o
Boss_VictorInitialGraphicsLoadDescriptor:   dc.w    $6000, $2000, $202, $595A, $5B5D, $5E5F, $6162, $63FF  ; was: word_32666
                                        ; DATA XREF: Boss_VictorInit+76   o

; Handles boss flying in until X position reaches threshold
Boss_VictorFlyIn:                                       ; DATA XREF: ROM:0003242E   o  ; was: sub_32676
                bsr.w   Boss_VictorSetPaletteRGBAdjustment
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                cmpi.w  #$180,$10(a5)
                bhi.w   Entity_UpdateReturn
                clr.w   $18(a5)
                move.w  #3,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorFlyIn
; Holds Victor's entrance until the dark arena is ready
Boss_VictorWaitForArenaReady:                           ; DATA XREF: ROM:00032430   o  ; was: sub_326A0
                bsr.w   Boss_VictorSetPaletteRGBAdjustment
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                tst.w   (MessageSequenceState).w
                bne.w   Entity_UpdateReturn
                clr.b   (BossColorEffectFlags).w
                andi.b  #$EF,$23(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorWaitForArenaReady
; Configures Victor's entrance RGB palette adjustment
Boss_VictorSetPaletteRGBAdjustment:                     ; CODE XREF: Boss_VictorFlyIn   p  ; was: sub_326C4
                                        ; sub_326A0   p
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$20,(PaletteRGBChannelMask).w  ; ' '
                move.b  #8,(PaletteRGBAdjustStep).w
                rts
; End of function Boss_VictorSetPaletteRGBAdjustment
; Randomly selects the next ring, launched-part, or split-shot sequence
Boss_VictorChooseAttack:                                ; DATA XREF: ROM:00032432   o  ; was: sub_326D8
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                jsr     (RandomNumber).l
                andi.w  #3,d0
                beq.s   Boss_VictorSelectPartLaunchAttack
                cmpi.w  #2,d0
                beq.s   Boss_VictorSelectSplitShotAttack
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_VictorSelectPartLaunchAttack:                      ; CODE XREF: Boss_VictorChooseAttack+12   j  ; was: loc_326F8
                move.w  #$10,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_VictorSelectSplitShotAttack:                       ; CODE XREF: Boss_VictorChooseAttack+18   j  ; was: loc_32700
                move.w  #$18,4(a5)
                rts
; End of function Boss_VictorChooseAttack
; Builds a linked ring of twelve orbiting parts around Victor
Boss_VictorDeployRing:                                  ; DATA XREF: ROM:00032434   o  ; was: sub_32708
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                lea     (TwentiethEntityType).w,a4
                lea     (Entity_ObjectPool).w,a0
                bsr.w   Boss_VictorConfigureRingPattern
                move.w  #$B,d6
Boss_VictorInitNextRingSegment:                         ; CODE XREF: Boss_VictorDeployRing+5C   j  ; was: loc_32720
                adda.w  #$60,a4                         ; '`'
                bsr.w   Boss_VictorInitPart
                move.b  #$54,$20(a4)                    ; 'T'
                move.w  #8,$48(a4)
                move.w  #$500,8(a4)
                move.w  #$F8F8,$A(a4)
                move.w  #$6334,$E(a4)
                move.w  #$40,$4A(a4)                    ; '@'
                move.w  #1,$4C(a4)
                move.w  d5,$40(a4)
                add.w   (SharedScratchLong2+2).w,d5
                clr.w   $42(a4)
                move.w  a0,$44(a4)
                movea.w a4,a0
                dbf     d6,Boss_VictorInitNextRingSegment
                move.w  #$CC00,2(a4)
                move.l  #SharedVictorSunsetStingSegmentMappingA,8(a4)
                move.w  #$2300,$E(a4)
                tst.w   (SharedScratchLong2).w
                bpl.s   Boss_VictorFinishRingDeployment
                ori.w   #$1000,$E(a4)
Boss_VictorFinishRingDeployment:                        ; CODE XREF: Boss_VictorDeployRing+78   j  ; was: loc_32788
                move.w  #3,(TwentyFirstEntityWork4C).w
                move.b  #$4B,d0                         ; 'K'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$40,$4A(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorDeployRing
; Chooses the ring's angle origin, direction, and horizontal target
Boss_VictorConfigureRingPattern:                        ; CODE XREF: Boss_VictorDeployRing+10   p  ; was: sub_327A4
                jsr     (RandomNumber).l
                cmpi.w  #$120,$10(a5)
                bcc.s   Boss_VictorConfigureRightRing
                andi.w  #1,d0
                bne.s   Boss_VictorConfigureLeftClockwiseRing
                move.w  #$1FC,d5
                move.w  #$1FC,(SharedScratchLong1+2).w
                move.w  #$FFFE,(SharedScratchLong2+2).w
                move.w  #2,(SharedScratchLong2).w
                move.w  #$180,(SharedScratchLong3).w
                rts
; ---------------------------------------------------------------------------
Boss_VictorConfigureLeftClockwiseRing:                  ; CODE XREF: Boss_VictorConfigureRingPattern+12   j  ; was: loc_327D6
                move.w  #4,d5
                move.w  #4,(SharedScratchLong1+2).w
                move.w  #2,(SharedScratchLong2+2).w
                move.w  #$FFFE,(SharedScratchLong2).w
                move.w  #$180,(SharedScratchLong3).w
                rts
; ---------------------------------------------------------------------------
Boss_VictorConfigureRightRing:                          ; CODE XREF: Boss_VictorConfigureRingPattern+C   j  ; was: loc_327F4
                andi.w  #1,d0
                bne.s   Boss_VictorConfigureRightCounterclockwiseRing
                move.w  #$104,d5
                move.w  #$104,(SharedScratchLong1+2).w
                move.w  #2,(SharedScratchLong2+2).w
                move.w  #2,(SharedScratchLong2).w
                move.w  #$C0,(SharedScratchLong3).w
                rts
; ---------------------------------------------------------------------------
Boss_VictorConfigureRightCounterclockwiseRing:          ; CODE XREF: Boss_VictorConfigureRingPattern+54   j  ; was: loc_32818
                move.w  #$FC,d5
                move.w  #$FC,(SharedScratchLong1+2).w
                move.w  #$FFFE,(SharedScratchLong2+2).w
                move.w  #$FFFE,(SharedScratchLong2).w
                move.w  #$C0,(SharedScratchLong3).w
                rts
; End of function Boss_VictorConfigureRingPattern
; Reverses and relinks the twelve-part ring
Boss_VictorReverseRing:                                 ; DATA XREF: ROM:00032436   o  ; was: sub_32836
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$80,(PaletteRGBChannelMask).w
                move.b  #8,(PaletteRGBAdjustStep).w
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #3,(PlaneAShakeLevel).w
                move.b  #$53,d0                         ; 'S'
                jsr     (Sound_QueueSFXRequest).l
                lea     (TwentyFirstEntityType).w,a4
                move.w  #$B,d6
Boss_VictorLinkNextRingSegment:                         ; CODE XREF: Boss_VictorReverseRing+5E   j  ; was: loc_32870
                move.w  #$40,$42(a4)                    ; '@'
                movea.w a4,a3
                adda.w  #$60,a3                         ; '`'
                move.w  a3,$44(a4)
                move.w  $40(a3),d0
                eori.w  #$100,d0
                move.w  d0,$40(a4)
                addq.w  #2,4(a4)
                adda.w  #$60,a4                         ; '`'
                dbf     d6,Boss_VictorLinkNextRingSegment
                move.l  #SharedVictorSunsetStingSegmentMappingB,(VictorRingEndMapping).w
                move.w  (SharedScratchLong1+2).w,d0
                eori.w  #$100,d0
                move.w  d0,$40(a5)
                move.w  #$C0,$42(a5)
                lea     (TwentyFirstEntityType).w,a4
                move.w  a4,$44(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorReverseRing
; Pulls the ring inward and relinks it in reverse slot order
Boss_VictorRetractRing:                                 ; DATA XREF: ROM:00032438   o  ; was: sub_328C0
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$80,(PaletteRGBChannelMask).w
                move.b  #8,(PaletteRGBAdjustStep).w
                bsr.w   Entity_UpdatePolarPositionFromParent
                move.w  #$100,$14(a5)
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                subq.w  #3,$42(a5)
                cmpi.w  #$120,(SharedScratchLong3).w
                bcc.s   Boss_VictorClampRetractionFromRight
                cmpi.w  #$C0,$10(a5)
                bhi.w   Entity_UpdateReturn
                move.w  #$C0,$10(a5)
                bra.s   Boss_VictorLinkRingForRetraction
; ---------------------------------------------------------------------------
Boss_VictorClampRetractionFromRight:                    ; CODE XREF: Boss_VictorRetractRing+2E   j  ; was: loc_32902
                cmpi.w  #$180,$10(a5)
                bcs.w   Entity_UpdateReturn
                move.w  #$180,$10(a5)
Boss_VictorLinkRingForRetraction:                       ; CODE XREF: Boss_VictorRetractRing+40   j  ; was: loc_32912
                lea     (ThirtySecondEntityType).w,a4
                move.w  #$A,d6
Boss_VictorLinkPreviousRingSegment:                     ; CODE XREF: Boss_VictorRetractRing+84   j  ; was: loc_3291A
                movea.w a4,a3
                suba.w  #$60,a3                         ; '`'
                move.w  a3,$44(a4)
                move.w  $40(a3),d0
                eori.w  #$100,d0
                move.w  d0,$40(a4)
                move.w  $42(a3),$42(a4)
                move.w  #$10,$4A(a4)
                addq.w  #2,4(a4)
                suba.w  #$60,a4                         ; '`'
                dbf     d6,Boss_VictorLinkPreviousRingSegment
                lea     (Entity_ObjectPool).w,a3
                move.w  a3,$44(a4)
                move.w  (SharedScratchLong1+2).w,$40(a4)
                move.w  $42(a3),$42(a4)
                move.w  #$10,$4A(a4)
                addq.w  #2,4(a4)
                move.l  #SharedVictorSunsetStingSegmentMappingA,(VictorRingEndMapping).w
                move.w  #$20,$4A(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorRetractRing
; Returns Victor's Y coordinate to the arena centerline
Boss_VictorReturnToCenterline:                          ; DATA XREF: ROM:0003243A   o  ; was: sub_3297A
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                cmpi.w  #$100,$14(a5)
                beq.s   Boss_VictorWaitAfterRingRetraction
                bcs.s   Boss_VictorMoveDownToCenterline
                subq.w  #1,$14(a5)
                bra.s   Boss_VictorWaitAfterRingRetraction
; ---------------------------------------------------------------------------
Boss_VictorMoveDownToCenterline:                        ; CODE XREF: Boss_VictorReturnToCenterline+10   j  ; was: loc_32992
                addq.w  #1,$14(a5)
Boss_VictorWaitAfterRingRetraction:                     ; CODE XREF: Boss_VictorReturnToCenterline+E   j  ; was: loc_32996
                                        ; Boss_VictorReturnToCenterline+16   j
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #6,4(a5)
                rts
; End of function Boss_VictorReturnToCenterline
