; Main handler for Bugmax boss
Boss_BugmaxMain:                                        ; was: sub_4BEBC
                tst.w   4(a5)
                beq.w   Boss_BugmaxDispatchMainState
                lea     (PaletteFade_BugmaxEntryOffsets).l,a2
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$58(a5)
                move.w  $5E(a5),d0
                lea     Boss_BugmaxGeometryModeHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_BugmaxMain
; ---------------------------------------------------------------------------
Boss_BugmaxGeometryModeHandlers:    dc.w    Boss_BugmaxUpdateLinkedChainGeometry-*  ; was: off_4BEE8
                dc.w    Boss_BugmaxUpdateReverseLinkedChainGeometry-*
                dc.w    Boss_BugmaxUpdateForwardLinkedChainGeometry-*
                dc.w    Boss_BugmaxUpdatePerspectiveAndLinkedGeometry-*

; Update controller anchors, linked-chain positions, and smoothed joint angles
Boss_BugmaxUpdateLinkedChainGeometry:                   ; was: sub_4BEF0
                move.w  #$168,d0
                sub.w   $5C(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$128,d0
                move.w  d0,(SecondaryCameraYPos).w
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.l  $10(a5),d3
                move.l  $14(a5),d4
                bsr.w   Math_CalculatePolarPosition
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                move.w  #4,d7
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                movea.w a5,a1
Boss_BugmaxProjectForwardLinkedChainLoop:               ; was: loc_4BF2E
                move.l  $10(a1),d3
                move.l  $14(a1),d4
                bsr.w   Math_CalculatePolarPosition
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w a0,a1
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxProjectForwardLinkedChainLoop
                move.w  $10(a5),d0
                lea     (BugmaxPositionHistory).w,a0
                move.w  #7,d7
Boss_BugmaxShiftPrimaryPositionHistoryLoop:             ; was: loc_4BF58
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d7,Boss_BugmaxShiftPrimaryPositionHistoryLoop
                move.w  -$C(a0),d4
                move.w  -2(a0),d5
                move.w  d4,d0
                move.w  (SecondaryEntityYPos).w,d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                cmpi.w  #$1C0,d2
                bcs.s   Boss_BugmaxClampFirstJointAngleMinimum
                move.w  #$1C0,d2
                bra.s   Boss_BugmaxStoreFirstJointAngle
; ---------------------------------------------------------------------------
Boss_BugmaxClampFirstJointAngleMinimum:                 ; was: loc_4BF8A
                cmpi.w  #$140,d2
                bhi.s   Boss_BugmaxStoreFirstJointAngle
                move.w  #$140,d2
Boss_BugmaxStoreFirstJointAngle:                        ; was: loc_4BF94
                                        ; Boss_BugmaxUpdateLinkedChainGeometry+9E   j
                move.w  d2,(SecondaryEntityWork4C).w
                move.w  d5,d0
                move.w  (TertiaryEntityYPos).w,d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                cmpi.w  #$C0,d2
                bcs.s   Boss_BugmaxClampSecondJointAngleMinimum
                move.w  #$C0,d2
                bra.s   Boss_BugmaxStoreSecondJointAngle
; ---------------------------------------------------------------------------
Boss_BugmaxClampSecondJointAngleMinimum:                ; was: loc_4BFB8
                cmpi.w  #$40,d2                         ; '@'
                bhi.s   Boss_BugmaxStoreSecondJointAngle
                move.w  #$40,d2                         ; '@'
Boss_BugmaxStoreSecondJointAngle:                       ; was: loc_4BFC2
                                        ; Boss_BugmaxUpdateLinkedChainGeometry+CC   j
                move.w  d2,(TertiaryEntityWork4C).w
                move.w  d2,d0
                lea     (BugmaxAngleHistoryRows).w,a0
                move.w  #7,d7
Boss_BugmaxShiftJointAngleHistoryRowsLoop:              ; was: loc_4BFD0
                move.w  #3,d6
Boss_BugmaxShiftJointAngleHistoryRowLoop:               ; was: loc_4BFD4
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d6,Boss_BugmaxShiftJointAngleHistoryRowLoop
                dbf     d7,Boss_BugmaxShiftJointAngleHistoryRowsLoop
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                lea     (BugmaxAngleHistoryRows).w,a1
                move.w  #$10,d6
                move.w  #3,d7
; Copy smoothed joint angles into four linked-part records
Boss_BugmaxCopySmoothedAnglesToLinkedPartsLoop:         ; was: loc_4BFF2
                lea     $60(a0),a0
                lea     (a1,d6.w),a1
                move.w  -2(a1),$4C(a0)
                dbf     d7,Boss_BugmaxCopySmoothedAnglesToLinkedPartsLoop
                bra.w   Boss_BugmaxCheckForcedFinalState
; End of function Boss_BugmaxUpdateLinkedChainGeometry
; Project the linked chain in reverse record order
Boss_BugmaxUpdateReverseLinkedChainGeometry:            ; was: sub_4C008
                move.w  #$168,d0
                sub.w   $5C(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  #$1F0,(SecondaryCameraYPos).w
                movea.w #(SeventhEntityType-M68K_RAM),a1
                movea.w #(SixthEntityType-M68K_RAM),a0
                move.w  #3,d7
; Project each reverse-chain segment from the preceding record
Boss_BugmaxProjectReverseLinkedChainLoop:               ; was: loc_4C02A
                move.l  $10(a1),d3
                move.l  $14(a1),d4
                move.w  $50(a1),d2
                move.w  $4C(a0),d0
                add.w   $4E(a0),d0
                addi.w  #$100,d0
                bsr.w   Math_BugmaxCalculatePolarOffset
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w a0,a1
                lea     -$60(a0),a0
                dbf     d7,Boss_BugmaxProjectReverseLinkedChainLoop
                movea.w a5,a0
                move.l  (TertiaryEntityXPos).w,d3
                move.l  (TertiaryEntityYPos).w,d4
                move.w  (TertiaryEntityWork50).w,d2
                move.w  $4C(a0),d0
                add.w   $4E(a0),d0
                addi.w  #$100,d0
                bsr.w   Math_BugmaxCalculatePolarOffset
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.l  $10(a5),d3
                move.l  $14(a5),d4
                bsr.w   Math_CalculatePolarPosition
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                bra.w   Boss_BugmaxCheckForcedFinalState
; End of function Boss_BugmaxUpdateReverseLinkedChainGeometry
; Project the linked chain in forward record order
Boss_BugmaxUpdateForwardLinkedChainGeometry:            ; was: sub_4C09A
                move.w  #$168,d0
                sub.w   $5C(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  #$1F0,(SecondaryCameraYPos).w
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.l  $10(a5),d3
                move.l  $14(a5),d4
                bsr.w   Math_CalculatePolarPosition
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                move.w  #4,d7
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                movea.w a5,a1
Boss_BugmaxProjectForwardChainFromPreviousPartLoop:     ; was: loc_4C0D2
                move.l  $10(a1),d3
                move.l  $14(a1),d4
                move.w  $50(a0),d2
                move.w  $4C(a0),d0
                bsr.w   Math_BugmaxCalculatePolarOffset
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w a0,a1
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxProjectForwardChainFromPreviousPartLoop
                bra.w   Boss_BugmaxUpdatePositionAndAngleHistories
; End of function Boss_BugmaxUpdateForwardLinkedChainGeometry
; Update perspective rows, position histories, and both linked chains
Boss_BugmaxUpdatePerspectiveAndLinkedGeometry:          ; was: sub_4C0FC
                move.w  #$190,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  #$60,d0                         ; '`'
                move.w  #$5F,d7                         ; '_'
                movea.w #(BossPerspectiveRows-M68K_RAM),a0
Boss_BugmaxInitializePerspectiveRowsLoop:               ; was: loc_4C114
                move.w  d0,(a0)+
                subq.w  #2,d0
                dbf     d7,Boss_BugmaxInitializePerspectiveRowsLoop
                tst.w   (SharedScratchLong0).w
                beq.w   Boss_BugmaxUpdatePerspectiveParametersAndGeometry
                tst.w   (SharedScratchLong0).w
                bmi.w   Boss_BugmaxInitializeNegativePerspectiveSlope
                move.w  #$204,d0
                sub.w   $14(a5),d0
                move.w  d0,(SecondaryCameraYPos).w
                moveq   #0,d2
                move.w  #$400,d2
                move.w  (SharedScratchLong0).w,d0
                divu.w  d0,d2
                swap    d2
                clr.w   d2
                lsr.l   #4,d2
                subi.l  #$10000,d2
                movea.w #(BossPerspectiveRows-M68K_RAM),a0
                movea.w a0,a1
                move.w  $14(a5),d0
                subi.w  #8,d0
                subi.w  #$A0,d0
                andi.w  #$1FE,d0
                adda.w  d0,a0
                move.l  (SecondaryCameraYPos).w,d1
                move.w  (SharedScratchLong0).w,d7
Boss_BugmaxFillPerspectiveRowsBackwardLoop:             ; was: loc_4C170
                cmpa.w  a1,a0
                beq.w   Boss_BugmaxUpdatePerspectiveParametersAndGeometry
                sub.l   d2,d1
                move.l  d1,d4
                swap    d4
                move.w  d4,-(a0)
                dbf     d7,Boss_BugmaxFillPerspectiveRowsBackwardLoop
                bra.s   Boss_BugmaxUpdatePerspectiveParametersAndGeometry
; ---------------------------------------------------------------------------
Boss_BugmaxInitializeNegativePerspectiveSlope:          ; was: loc_4C184
                move.w  #$22C,d0
                sub.w   $14(a5),d0
                move.w  d0,(SecondaryCameraYPos).w
                moveq   #0,d2
                move.w  #$400,d2
                move.w  (SharedScratchLong0).w,d0
                neg.w   d0
                divu.w  d0,d2
                swap    d2
                clr.w   d2
                lsr.l   #4,d2
                subi.l  #$10000,d2
                movea.w #(BossPerspectiveRows-M68K_RAM),a0
                movea.w a0,a1
                adda.w  #$C0,a1
                move.w  $14(a5),d0
                subi.w  #8,d0
                subi.w  #$A0,d0
                andi.w  #$1FE,d0
                adda.w  d0,a0
                move.l  (SecondaryCameraYPos).w,d1
                move.w  (SharedScratchLong0).w,d7
                neg.w   d7
Boss_BugmaxFillPerspectiveRowsForwardLoop:              ; was: loc_4C1D0
                cmpa.w  a1,a0
                beq.s   Boss_BugmaxUpdatePerspectiveParametersAndGeometry
                add.l   d2,d1
                move.l  d1,d4
                swap    d4
                move.w  d4,(a0)+
                dbf     d7,Boss_BugmaxFillPerspectiveRowsForwardLoop
Boss_BugmaxUpdatePerspectiveParametersAndGeometry:      ; was: loc_4C1E0
                                        ; Boss_BugmaxUpdatePerspectiveAndLinkedGeometry+76   j
                bsr.w   Gfx_BugmaxApplyWavePaletteOffset
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                cmpi.w  #$10,(a0)
                bne.w   Boss_BugmaxCheckForcedFinalState
                move.l  $10(a5),d3
                move.l  $14(a5),d4
                bsr.w   Math_CalculatePolarPosition
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                move.w  #4,d7
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                movea.w a5,a1
Boss_BugmaxProjectPrimaryLinkedChainLoop:               ; was: loc_4C20E
                move.l  $10(a1),d3
                move.l  $14(a1),d4
                bsr.w   Math_CalculatePolarPosition
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w a0,a1
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxProjectPrimaryLinkedChainLoop
Boss_BugmaxUpdatePositionAndAngleHistories:             ; was: loc_4C22C
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                swap    d0
                move.w  $14(a5),d0
                lea     (BugmaxPositionHistory).w,a0
                move.w  #7,d7
Boss_BugmaxShiftPositionHistoryLoop:                    ; was: loc_4C242
                move.l  (a0),d1
                move.l  d0,(a0)+
                move.l  d1,d0
                dbf     d7,Boss_BugmaxShiftPositionHistoryLoop
                move.l  -$18(a0),d5
                move.l  -4(a0),d6
                moveq   #0,d3
                moveq   #0,d4
                move.w  d5,d4
                swap    d5
                move.w  d5,d3
                sub.w   (PrimaryCameraXPosition).w,d3
                swap    d3
                swap    d4
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  (SharedScratchLong5+2).w,d0
                addi.w  #$80,d0
                move.w  $50(a0),d2
                bsr.w   Math_BugmaxCalculatePolarOffset
                swap    d0
                swap    d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                move.w  d2,(SecondaryEntityWork4C).w
                moveq   #0,d3
                moveq   #0,d4
                move.w  d6,d4
                swap    d6
                move.w  d6,d3
                sub.w   (PrimaryCameraXPosition).w,d3
                swap    d3
                swap    d4
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                move.w  (SharedScratchLong5+2).w,d0
                subi.w  #$80,d0
                move.w  $50(a0),d2
                bsr.w   Math_BugmaxCalculatePolarOffset
                swap    d0
                swap    d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                move.w  d2,(TertiaryEntityWork4C).w
                move.w  d2,d0
                lea     (BugmaxAngleHistoryRows).w,a0
                move.w  #7,d7
Boss_BugmaxShiftPrimaryAngleHistoryRowsLoop:            ; was: loc_4C2D6
                move.w  #3,d6
Boss_BugmaxShiftPrimaryAngleHistoryRowLoop:             ; was: loc_4C2DA
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d6,Boss_BugmaxShiftPrimaryAngleHistoryRowLoop
                dbf     d7,Boss_BugmaxShiftPrimaryAngleHistoryRowsLoop
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                lea     (BugmaxAngleHistoryRows).w,a1
                move.w  #$10,d6
                move.w  #3,d7
Boss_BugmaxCopyPrimaryAnglesToLinkedPartsLoop:          ; was: loc_4C2F8
                lea     $60(a0),a0
                lea     (a1,d6.w),a1
                move.w  -2(a1),$4C(a0)
                dbf     d7,Boss_BugmaxCopyPrimaryAnglesToLinkedPartsLoop
                move.w  (SecondaryEntityWork4C).w,d0
                add.w   d0,d0
                lea     (BugmaxAuxAngleHistory).w,a0
                move.w  #7,d7
Boss_BugmaxShiftSecondaryAngleHistoryRowsLoop:          ; was: loc_4C318
                move.w  #7,d6
Boss_BugmaxShiftSecondaryAngleHistoryRowLoop:           ; was: loc_4C31C
                move.w  (a0),d1
                move.w  d0,(a0)+
                move.w  d1,d0
                dbf     d6,Boss_BugmaxShiftSecondaryAngleHistoryRowLoop
                dbf     d7,Boss_BugmaxShiftSecondaryAngleHistoryRowsLoop
                movea.w #(EighthEntityType-M68K_RAM),a0
                lea     (BugmaxAuxAngleHistory).w,a1
                move.w  #$10,d6
                move.w  #7,d7
Boss_BugmaxCopySecondaryAnglesToLinkedPartsLoop:        ; was: loc_4C33A
                lea     (a1,d6.w),a1
                move.w  -2(a1),$4C(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxCopySecondaryAnglesToLinkedPartsLoop
                move.w  #7,d7
                movea.w #(EighthEntityType-M68K_RAM),a0
                move.w  (SharedScratchLong4+2).w,d2
                movea.w #(SecondaryEntityType-M68K_RAM),a1
Boss_BugmaxProjectSecondaryLinkedChainLoop:             ; was: loc_4C35C
                tst.b   (SharedScratchLong6+2).w
                bne.s   Boss_BugmaxUseSharedSecondaryChainAngle
                move.w  $4C(a0),d0
                bra.s   Boss_BugmaxProjectSecondaryChainPart
; ---------------------------------------------------------------------------
Boss_BugmaxUseSharedSecondaryChainAngle:                ; was: loc_4C368
                move.w  (SharedScratchLong5).w,d0
Boss_BugmaxProjectSecondaryChainPart:                   ; was: loc_4C36C
                add.w   $4E(a0),d0
                move.l  $10(a1),d3
                move.l  $14(a1),d4
                bsr.w   Math_BugmaxCalculatePolarOffset
                move.l  d0,$10(a0)
                move.l  d1,$14(a0)
                movea.w a0,a1
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxProjectSecondaryLinkedChainLoop
                bsr.w   Boss_BugmaxToggleCentralPartMapping
Boss_BugmaxCheckForcedFinalState:                       ; was: loc_4C392
                                        ; Boss_BugmaxUpdateReverseLinkedChainGeometry+8E   j
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_BugmaxDispatchMainState
                btst    #1,(BossColorEffectFlags).w
                bne.w   Boss_BugmaxDispatchMainState
                tst.w   (BossHealth).w
                bne.s   Boss_BugmaxDispatchMainState
                move.b  #2,(BossColorEffectFlags).w
Boss_BugmaxEnterForcedFinalState:                       ; was: loc_4C3B0
                bset    #0,$5A(a5)
                move.w  #$56,4(a5)                      ; 'V'
                move.w  #1,(SharedScratchLong10+2).w
                bset    #0,(StageTimerPauseFlag).w
                bra.w   *+4
; ---------------------------------------------------------------------------
; Main state dispatcher for Bugmax boss
Boss_BugmaxDispatchMainState:                           ; was: loc_4C3CC
                                        ; Boss_BugmaxUpdatePerspectiveAndLinkedGeometry+29C   j
                move.w  4(a5),d0
                lea     Boss_BugmaxMainStateHandlers(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_BugmaxUpdatePerspectiveAndLinkedGeometry
; ---------------------------------------------------------------------------
