; Apply the three unreferenced manual geometry controls in sequence
Debug_ShieldViperApplyManualGeometryControls:           ; was: sub_4F5D8
                bsr.w   Debug_ShieldViperAdjustControllerAngleWithDPad
                bsr.w   Debug_ShieldViperAdjustBodyBendStepWithDPad
                bsr.w   Debug_ShieldViperMoveSelectedRecordAxesWithDPad
                rts
; End of function Debug_ShieldViperApplyManualGeometryControls
; Emit through fall-through while button bit 6 is set; otherwise hide the orbit record
Debug_ShieldViperSelectOrbitShotAction:                 ; was: sub_4F5E6
                btst    #6,(ControllerHeldState).w
                beq.w   Boss_ShieldViperHideOrbitingRecordAndForceFlip
; Fall through to Boss_ShieldViperEmitOrbitShotOnFrameGate
; On eligible frames, emit one orbit shot from the auxiliary record
Boss_ShieldViperEmitOrbitShotOnFrameGate:               ; CODE XREF: Boss_ShieldViperEmitTimedOrbitShotStream+8   p  ; was: sub_4F5F0
                bsr.w   Boss_ShieldViperUpdateOrbitingRecord
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_ShieldViperOrbitShotFrameGateReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperOrbitShotFrameGateReturn
                jsr     Projectile_InitShieldViperOrbitShot(pc)  ; (pc)
                move.b  $20(a5),$20(a0)
                move.w  $970(a5),$10(a0)
                move.w  $974(a5),$14(a0)
                lea     (Math_SineTable).l,a3
                move.w  $56(a5),d0
                add.w   $52(a5),d0
                addi.w  #$100,d0
                andi.w  #$1FE,d0
                move.w  -$80(a3,d0.w),d1
                move.w  (a3,d0.w),d0
                ext.l   d0
                ext.l   d1
                asl.l   #5,d0
                asl.l   #5,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
Boss_ShieldViperOrbitShotFrameGateReturn:               ; CODE XREF: Boss_ShieldViperEmitOrbitShotOnFrameGate+E   j  ; was: locret_4F64C
                                        ; Boss_ShieldViperEmitOrbitShotOnFrameGate+16   j
                rts
; End of function Boss_ShieldViperEmitOrbitShotOnFrameGate
; Hide the orbiting record and force horizontal flip across the body
Boss_ShieldViperHideOrbitingRecordAndForceFlip:         ; CODE XREF: Boss_ShieldViperEmitTimedOrbitShotStream+12   p  ; was: sub_4F64E
                                        ; Debug_ShieldViperSelectOrbitShotAction+6   j
                bsr.w   Boss_ShieldViperHideOrbitingRecord
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                rts
; End of function Boss_ShieldViperHideOrbitingRecordAndForceFlip
; With modifier bit 5 held, adjust one selected record's X and another's Y
Debug_ShieldViperMoveSelectedRecordAxesWithDPad:        ; CODE XREF: Debug_ShieldViperApplyManualGeometryControls+8   p  ; was: sub_4F658
                btst    #5,(ControllerHeldState).w
                beq.w   Debug_ShieldViperSelectedRecordMoveReturn
                movea.w (SharedScratchLong2).w,a0
                movea.w (SharedScratchLong2+2).w,a1
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_ShieldViperCheckSelectedRecordMoveRight
                subi.w  #4,$10(a0)
Debug_ShieldViperCheckSelectedRecordMoveRight:          ; CODE XREF: Debug_ShieldViperMoveSelectedRecordAxesWithDPad+18   j  ; was: loc_4F678
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_ShieldViperCheckSelectedRecordMoveUp
                addi.w  #4,$10(a0)
Debug_ShieldViperCheckSelectedRecordMoveUp:             ; CODE XREF: Debug_ShieldViperMoveSelectedRecordAxesWithDPad+26   j  ; was: loc_4F686
                btst    #0,(ControllerHeldState).w
                beq.s   Debug_ShieldViperCheckSelectedRecordMoveDown
                subi.w  #4,$14(a1)
Debug_ShieldViperCheckSelectedRecordMoveDown:           ; CODE XREF: Debug_ShieldViperMoveSelectedRecordAxesWithDPad+34   j  ; was: loc_4F694
                btst    #1,(ControllerHeldState).w
                beq.s   Debug_ShieldViperSelectedRecordMoveReturn
                addi.w  #4,$14(a1)
Debug_ShieldViperSelectedRecordMoveReturn:              ; CODE XREF: Debug_ShieldViperMoveSelectedRecordAxesWithDPad+6   j  ; was: locret_4F6A2
                                        ; Debug_ShieldViperMoveSelectedRecordAxesWithDPad+42   j
                rts
; End of function Debug_ShieldViperMoveSelectedRecordAxesWithDPad
; With modifier bit 4 held, adjust the controller angle by four from left/right
Debug_ShieldViperAdjustControllerAngleWithDPad:         ; CODE XREF: Debug_ShieldViperApplyManualGeometryControls   p  ; was: sub_4F6A4
                btst    #4,(ControllerHeldState).w
                beq.w   Debug_ShieldViperControllerAngleAdjustmentReturn
                movea.w (SharedScratchLong2).w,a0
                movea.w (SharedScratchLong2+2).w,a1
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_ShieldViperCheckControllerAngleIncrease
                subq.w  #4,$56(a5)
Debug_ShieldViperCheckControllerAngleIncrease:          ; CODE XREF: Debug_ShieldViperAdjustControllerAngleWithDPad+18   j  ; was: loc_4F6C2
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_ShieldViperControllerAngleAdjustmentReturn
                addq.w  #4,$56(a5)
Debug_ShieldViperControllerAngleAdjustmentReturn:       ; CODE XREF: Debug_ShieldViperAdjustControllerAngleWithDPad+6   j  ; was: locret_4F6CE
                                        ; Debug_ShieldViperAdjustControllerAngleWithDPad+24   j
                rts
; End of function Debug_ShieldViperAdjustControllerAngleWithDPad
; With modifier bit 4 held, adjust the shared body-bend step from up/down
Debug_ShieldViperAdjustBodyBendStepWithDPad:            ; CODE XREF: Debug_ShieldViperApplyManualGeometryControls+4   p  ; was: sub_4F6D0
                btst    #4,(ControllerHeldState).w
                beq.w   Debug_ShieldViperBodyBendStepAdjustmentReturn
                movea.w (SharedScratchLong2).w,a0
                movea.w (SharedScratchLong2+2).w,a1
                btst    #0,(ControllerHeldState).w
                beq.s   Debug_ShieldViperCheckBodyBendStepDecrease
                addq.w  #1,(SharedScratchLong1).w
Debug_ShieldViperCheckBodyBendStepDecrease:             ; CODE XREF: Debug_ShieldViperAdjustBodyBendStepWithDPad+18   j  ; was: loc_4F6EE
                btst    #1,(ControllerHeldState).w
                beq.s   Debug_ShieldViperBodyBendStepAdjustmentReturn
                subq.w  #1,(SharedScratchLong1).w
Debug_ShieldViperBodyBendStepAdjustmentReturn:          ; CODE XREF: Debug_ShieldViperAdjustBodyBendStepWithDPad+6   j  ; was: locret_4F6FA
                                        ; Debug_ShieldViperAdjustBodyBendStepWithDPad+24   j
                rts
; End of function Debug_ShieldViperAdjustBodyBendStepWithDPad
; Perform one radial movement update while input bit 4 is held
Debug_ShieldViperMoveRadiallyWhileButtonHeld:           ; was: sub_4F6FC
                btst    #4,(ControllerHeldState).w
                beq.w   Debug_ShieldViperManualRadialMoveReturn
                bsr.w   Boss_ShieldViperMoveRadially
Debug_ShieldViperManualRadialMoveReturn:                ; CODE XREF: Debug_ShieldViperMoveRadiallyWhileButtonHeld+6   j  ; was: locret_4F70A
                rts
; End of function Debug_ShieldViperMoveRadiallyWhileButtonHeld
; On even frames, rebuild and queue the type-$3A8 pattern-effect workspace
Gfx_ShieldViperPatternEffectMain:                       ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_4F70C
                btst    #0,(FrameCounter+1).w
                bne.w   Gfx_ShieldViperPatternEffectReturn
                bsr.w   Boss_ShieldViperClearPatternBuffer
                bsr.w   Boss_ShieldViperUpdatePatternPhaseA
                btst    #6,(PrimaryEntityStatus).w
                beq.s   Gfx_ShieldViperSelectRandomPatternColor
                move.w  (ShieldViperEffectPhaseA).w,d0
                add.w   d0,d0
                andi.w  #$EE0,d0
                addi.w  #$660,d0
                bra.s   Gfx_ShieldViperStorePatternPaletteColor
; ---------------------------------------------------------------------------
Gfx_ShieldViperSelectRandomPatternColor:                ; CODE XREF: Gfx_ShieldViperPatternEffectMain+18   j  ; was: loc_4F736
                move.w  (RandomNumberState).w,d0
                andi.w  #$EEE,d0
Gfx_ShieldViperStorePatternPaletteColor:                ; CODE XREF: Gfx_ShieldViperPatternEffectMain+28   j  ; was: loc_4F73E
                move.w  d0,(PaletteActiveColor08).w
                bsr.s   Gfx_ShieldViperDispatchPatternEffectState
                bsr.w   Boss_ShieldViperTransferPatternBuffer
Gfx_ShieldViperPatternEffectReturn:                     ; CODE XREF: Gfx_ShieldViperPatternEffectMain+6   j  ; was: locret_4F748
                rts
; End of function Gfx_ShieldViperPatternEffectMain
; Dispatch the type-$3A8 pattern-effect phase stored in state field 4
Gfx_ShieldViperDispatchPatternEffectState:              ; CODE XREF: Gfx_ShieldViperPatternEffectMain+36   p  ; was: sub_4F74A
                move.w  4(a5),d0
                lea     Gfx_ShieldViperPatternEffectStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Gfx_ShieldViperDispatchPatternEffectState
; ---------------------------------------------------------------------------
Gfx_ShieldViperPatternEffectStateOffsets:   dc.w    Gfx_ShieldViperBeginPatternEffectDelay-*  ; DATA XREF: Gfx_ShieldViperDispatchPatternEffectState+4   o  ; was: off_4F756
                dc.w    Gfx_ShieldViperWaitPatternEffectDelay-*
                dc.w    Gfx_ShieldViperUpdateSecondaryPatternForDuration-*
                dc.w    Gfx_ShieldViperUpdateSecondaryAndTertiaryPatterns-*

; Seed the first ten-frame pattern delay and fall through to its countdown
Gfx_ShieldViperBeginPatternEffectDelay:                 ; DATA XREF: ROM:Gfx_ShieldViperPatternEffectStateOffsets   o  ; was: sub_4F75E
                move.w  #$A,$48(a5)
                addq.w  #2,4(a5)
; Count down a ten-frame pattern delay, reseed it, and advance the local state
Gfx_ShieldViperWaitPatternEffectDelay:                  ; DATA XREF: ROM:0004F758   o  ; was: loc_4F768
                subq.w  #1,$48(a5)
                bne.s   Gfx_ShieldViperPatternEffectDelayReturn
                move.w  #$A,$48(a5)
                addq.w  #2,4(a5)
Gfx_ShieldViperPatternEffectDelayReturn:                ; CODE XREF: Gfx_ShieldViperBeginPatternEffectDelay+E   j  ; was: locret_4F778
                rts
; End of function Gfx_ShieldViperBeginPatternEffectDelay
; Update phase B until the current ten-frame state timer expires
Gfx_ShieldViperUpdateSecondaryPatternForDuration:       ; DATA XREF: ROM:0004F75A   o  ; was: sub_4F77A
                bsr.w   Boss_ShieldViperUpdatePatternPhaseB
                subq.w  #1,$48(a5)
                bne.s   Gfx_ShieldViperSecondaryPatternDurationReturn
                addq.w  #2,4(a5)
Gfx_ShieldViperSecondaryPatternDurationReturn:          ; CODE XREF: Gfx_ShieldViperUpdateSecondaryPatternForDuration+8   j  ; was: locret_4F788
                rts
; End of function Gfx_ShieldViperUpdateSecondaryPatternForDuration
; Update pattern phases B and C without another state transition
Gfx_ShieldViperUpdateSecondaryAndTertiaryPatterns:      ; DATA XREF: ROM:0004F75C   o  ; was: sub_4F78A
                bsr.w   Boss_ShieldViperUpdatePatternPhaseB
                bsr.w   Boss_ShieldViperUpdatePatternPhaseC
                rts
; End of function Gfx_ShieldViperUpdateSecondaryAndTertiaryPatterns
; Advances the first effect-pattern phase
Boss_ShieldViperUpdatePatternPhaseA:                    ; CODE XREF: Gfx_ShieldViperPatternEffectMain+E   p  ; was: sub_4F794
                addi.l  #$2000,(ShieldViperEffectStepA).w
                move.w  (ShieldViperEffectStepA).w,d0
                add.w   d0,(ShieldViperEffectPhaseA).w
                move.w  (ShieldViperEffectPhaseA).w,d0
                cmpi.w  #$30,d0                         ; '0'
                blt.s   Boss_ShieldViperFillPrimaryPatternRange
                moveq   #0,d0
                move.l  d0,(ShieldViperEffectStepA).w
                move.w  d0,(ShieldViperEffectPhaseA).w
Boss_ShieldViperFillPrimaryPatternRange:                ; CODE XREF: Boss_ShieldViperUpdatePatternPhaseA+18   j  ; was: loc_4F7B8
                move.w  d0,d1
                add.w   d0,d0
                bra.w   Boss_ShieldViperFillPatternRange
; End of function Boss_ShieldViperUpdatePatternPhaseA
; Advances the second effect-pattern phase while the boss remains active
Boss_ShieldViperUpdatePatternPhaseB:                    ; CODE XREF: Gfx_ShieldViperUpdateSecondaryPatternForDuration   p  ; was: sub_4F7C0
                                        ; sub_4F78A   p
                addi.l  #$2000,(ShieldViperEffectStepB).w
                move.w  (ShieldViperEffectStepB).w,d0
                add.w   d0,(ShieldViperEffectPhaseB).w
                move.w  (ShieldViperEffectPhaseB).w,d0
                cmpi.w  #$30,d0                         ; '0'
                blt.s   Boss_ShieldViperCheckSecondaryPatternEnabled
                moveq   #0,d0
                move.l  d0,(ShieldViperEffectStepB).w
                move.w  d0,(ShieldViperEffectPhaseB).w
Boss_ShieldViperCheckSecondaryPatternEnabled:           ; CODE XREF: Boss_ShieldViperUpdatePatternPhaseB+18   j  ; was: loc_4F7E4
                btst    #6,(PrimaryEntityStatus).w
                bne.s   Boss_ShieldViperSecondaryPatternReturn
                btst    #7,(PrimaryEntityFlags).w
                bne.s   Boss_ShieldViperSecondaryPatternReturn
                move.w  d0,d1
                add.w   d0,d0
                bra.w   Boss_ShieldViperFillPatternRange
; ---------------------------------------------------------------------------
Boss_ShieldViperSecondaryPatternReturn:                 ; CODE XREF: Boss_ShieldViperUpdatePatternPhaseB+2A   j  ; was: locret_4F7FC
                                        ; Boss_ShieldViperUpdatePatternPhaseB+32   j
                rts
; End of function Boss_ShieldViperUpdatePatternPhaseB
; Advances the third effect-pattern phase while the boss remains active
Boss_ShieldViperUpdatePatternPhaseC:                    ; CODE XREF: Gfx_ShieldViperUpdateSecondaryAndTertiaryPatterns+4   p  ; was: sub_4F7FE
                addi.l  #$2000,(ShieldViperEffectStepC).w
                move.w  (ShieldViperEffectStepC).w,d0
                add.w   d0,(ShieldViperEffectPhaseC).w
                move.w  (ShieldViperEffectPhaseC).w,d0
                cmpi.w  #$30,d0                         ; '0'
                blt.s   Boss_ShieldViperCheckTertiaryPatternEnabled
                moveq   #0,d0
                move.l  d0,(ShieldViperEffectStepC).w
                move.w  d0,(ShieldViperEffectPhaseC).w
Boss_ShieldViperCheckTertiaryPatternEnabled:            ; CODE XREF: Boss_ShieldViperUpdatePatternPhaseC+18   j  ; was: loc_4F822
                btst    #6,(PrimaryEntityStatus).w
                bne.s   Boss_ShieldViperTertiaryPatternReturn
                btst    #7,(PrimaryEntityFlags).w
                bne.s   Boss_ShieldViperTertiaryPatternReturn
                move.w  d0,d1
                add.w   d0,d0
                bra.w   Boss_ShieldViperFillPatternRange
; ---------------------------------------------------------------------------
Boss_ShieldViperTertiaryPatternReturn:                  ; CODE XREF: Boss_ShieldViperUpdatePatternPhaseC+2A   j  ; was: locret_4F83A
                                        ; Boss_ShieldViperUpdatePatternPhaseC+32   j
                rts
; End of function Boss_ShieldViperUpdatePatternPhaseC
; Clears the 96-entry effect-pattern buffer
Boss_ShieldViperClearPatternBuffer:                     ; CODE XREF: Gfx_ShieldViperPatternEffectMain+A   p  ; was: sub_4F83C
                movea.w #(ShieldViperEffectBuffer-M68K_RAM),a1
                move.w  #$5F,d7                         ; '_'
                moveq   #0,d0
Boss_ShieldViperClearNextPatternBufferEntry:            ; CODE XREF: Boss_ShieldViperClearPatternBuffer+C   j  ; was: loc_4F846
                move.l  d0,-(a1)
                dbf     d7,Boss_ShieldViperClearNextPatternBufferEntry
                rts
; End of function Boss_ShieldViperClearPatternBuffer
; Fills a selected range of the effect-pattern buffer
Boss_ShieldViperFillPatternRange:                       ; CODE XREF: Boss_ShieldViperUpdatePatternPhaseA+28   j  ; was: sub_4F84E
                                        ; Boss_ShieldViperUpdatePatternPhaseB+38   j
                movea.w #(ShieldViperEffectBuffer-M68K_RAM),a1
                move.w  #$5F,d7                         ; '_'
                move.l  #$8080808,d3
                moveq   #0,d4
                move.l  #$88888888,d5
                move.w  d0,d2
                add.w   d1,d2
Boss_ShieldViperFillNextPatternBufferEntry:             ; CODE XREF: Boss_ShieldViperFillPatternRange+32   j  ; was: loc_4F868
                cmp.w   d0,d7
                bcs.s   Boss_ShieldViperAdvancePatternBufferEntry
                cmp.w   d2,d7
                bhi.s   Boss_ShieldViperAdvancePatternBufferEntry
                move.l  d3,(a1)
                move.l  d3,d5
                move.l  #$88888888,d3
                sub.l   d5,d3
Boss_ShieldViperAdvancePatternBufferEntry:              ; CODE XREF: Boss_ShieldViperFillPatternRange+1C   j  ; was: loc_4F87C
                                        ; Boss_ShieldViperFillPatternRange+20   j
                lea     -4(a1),a1
                dbf     d7,Boss_ShieldViperFillNextPatternBufferEntry
                rts
; End of function Boss_ShieldViperFillPatternRange
; Transfers the effect-pattern buffer to the rendering workspace
Boss_ShieldViperTransferPatternBuffer:                  ; CODE XREF: Gfx_ShieldViperPatternEffectMain+38   p  ; was: sub_4F886
                lea     (ShieldViperXferBuffer).w,a0
                move.w  #$3A80,d0
                move.w  #$8F02,d3
                move.l  #$940093C0,d4
                jmp     VDP_QueueCommand_Build
; End of function Boss_ShieldViperTransferPatternBuffer
; Add progressively more-negative deltas to 96 longwords, then copy their high words
Effect_AccumulateIndexedNegativeOffsets:                ; was: sub_4F89E
                lea     (ShieldViperOffsetTable).w,a0
                move.w  #$5F,d7                         ; '_'
                moveq   #0,d0
Effect_AccumulateNextIndexedNegativeOffset:             ; CODE XREF: Effect_AccumulateIndexedNegativeOffsets+12   j  ; was: loc_4F8A8
                subi.l  #$3E8,d0
                add.l   d0,(a0)+
                dbf     d7,Effect_AccumulateNextIndexedNegativeOffset
                lea     (ShieldViperOffsetTable).w,a0
                movea.w #(HScrollPlaneBRow128-M68K_RAM),a1
                move.w  #$5F,d7                         ; '_'
Effect_CopyNextIndexedOffsetHighWord:                   ; CODE XREF: Effect_AccumulateIndexedNegativeOffsets+2C   j  ; was: loc_4F8C0
                move.w  (a0),(a1)
                lea     4(a0),a0
                lea     4(a1),a1
                dbf     d7,Effect_CopyNextIndexedOffsetHighWord
                rts
; End of function Effect_AccumulateIndexedNegativeOffsets
; Increment or decrement four consecutive counters according to frame parity
Effect_OscillateFourCountersByFrameParity:              ; was: sub_4F8D0
                movea.w #(PaletteActiveColor56Hi-M68K_RAM),a0
                btst    #0,(FrameCounter+1).w
                bne.s   Effect_DecrementFourOscillatingCounters
                addq.w  #1,(a0)+
                addq.w  #1,(a0)+
                addq.w  #1,(a0)+
                addq.w  #1,(a0)
                rts
; ---------------------------------------------------------------------------
Effect_DecrementFourOscillatingCounters:                ; CODE XREF: Effect_OscillateFourCountersByFrameParity+A   j  ; was: loc_4F8E6
                subq.w  #1,(a0)+
                subq.w  #1,(a0)+
                subq.w  #1,(a0)+
                subq.w  #1,(a0)
                rts
; End of function Effect_OscillateFourCountersByFrameParity
