; Accumulates target-time, clear-time, and visit totals for the results summary
Results_ComputeSummaryData:                             ; CODE XREF: Results_InitializeHistoryDisplay+1AC   p  ; was: sub_2024A
                lea     (StageTimeLimitTable).l,a1
                lea     (StagePhaseSplitTimes).w,a2
                lea     (StageCompletionTimes).w,a3
                lea     (StageResultVisits).w,a4
                move.w  #$18,d7
                clr.w   (ResultsLimitTimeSeconds).w
                clr.w   (ResultsTotalVisitCount).w
                clr.w   (ResultsClearTimeSeconds).w
Results_AccumulateStageSummaryLoop:                     ; CODE XREF: Results_ComputeSummaryData+82   j  ; was: loc_2026C
                tst.w   (a2)
                bpl.s   Results_AccumulateAvailableStage
                tst.w   (a4)
                bmi.w   Results_AdvanceStageSummaryInput
Results_AccumulateAvailableStage:                       ; CODE XREF: Results_ComputeSummaryData+24   j  ; was: loc_20276
                move.b  (a1),d0
                bsr.w   Math_PackedBCDByteToBinary
                move.w  d0,d2
                move.b  1(a1),d0
                bsr.w   Math_PackedBCDByteToBinary
                move.w  d0,d3
                mulu.w  #$3C,d2
                add.w   d2,d3
                add.w   d3,(ResultsLimitTimeSeconds).w
                move.w  (a4),d0
                addq.w  #1,d0
                add.w   d0,(ResultsTotalVisitCount).w
                move.w  (a1),(ResultsBCDStartTime).w
                move.w  (a3),(ResultsBCDEndTime).w
                bmi.w   Results_AdvanceStageSummaryInput
                bsr.w   Results_CalculatePackedBCDTimeDifference
                move.w  d2,d0
                bsr.w   Math_PackedBCDByteToBinary
                move.w  d0,d2
                move.w  d3,d0
                bsr.w   Math_PackedBCDByteToBinary
                move.w  d0,d3
                mulu.w  #$3C,d2
                add.w   d2,d3
                add.w   d3,(ResultsClearTimeSeconds).w
Results_AdvanceStageSummaryInput:                       ; CODE XREF: Results_ComputeSummaryData+28   j  ; was: loc_202C4
                                        ; Results_ComputeSummaryData+58   j
                addq.w  #2,a1
                addq.w  #2,a2
                addq.w  #2,a3
                addq.w  #2,a4
                dbf     d7,Results_AccumulateStageSummaryLoop
                lea     (Math_PackedBCDLookup).l,a1
                lea     (ResultsTotalTimeBCD).w,a0
                move.w  (ResultsLimitTimeSeconds).w,d6
                bsr.w   Results_WriteSecondsAsPackedBCDTime
                lea     (ResultsTotalVisitsBCD).w,a0
                move.w  (ResultsTotalVisitCount).w,d5
                divu.w  #$A,d5
                move.w  d5,d0
                add.w   d0,d0
                move.w  (a1,d0.w),(a0)+
                swap    d5
                add.w   d5,d5
                move.w  (a1,d5.w),d0
                andi.w  #$F,d0
                lsl.w   #4,d0
                move.b  d0,(a0)
                lea     (ResultsTotalClearBCD).w,a0
                move.w  (ResultsClearTimeSeconds).w,d6
                bsr.w   Results_WriteSecondsAsPackedBCDTime
                bsr.w   Results_BuildSummaryRows
                rts
; End of function Results_ComputeSummaryData
; Builds the three total rows appended after the per-stage result rows
Results_BuildSummaryRows:                               ; CODE XREF: Results_ComputeSummaryData+C8   p  ; was: sub_20318
                lea     (ResultsStageRowBuffer).w,a0
                adda.w  #(ResultsSummaryRowBuffer-ResultsStageRowBuffer),a0
                lea     Results_TotalLimitTimeLabel(pc),a1
                nop
                move.w  #$15,d7
Results_CopyTotalTimeLabelLoop:                         ; CODE XREF: Results_BuildSummaryRows+14   j  ; was: loc_2032A
                move.b  (a1)+,(a0)+
                dbf     d7,Results_CopyTotalTimeLabelLoop
                lea     (ResultsTotalTimeBCD).w,a1
                move.b  (a1)+,d0
                bsr.w   Results_WritePackedBCDByteDigits
                move.b  (a1)+,d0
                move.b  #$25,(a0)+
                bsr.w   Results_WritePackedBCDByteDigits
                move.b  #$25,(a0)+
                move.b  (a1)+,d0
                bsr.w   Results_WritePackedBCDByteDigits
                move.w  #6,d7
                move.b  #0,d0
Results_PadTotalTimeRowLoop:                            ; CODE XREF: Results_BuildSummaryRows+40   j  ; was: loc_20356
                move.b  d0,(a0)+
                dbf     d7,Results_PadTotalTimeRowLoop
                bsr.w   Results_WriteRowEndMarker
                lea     Results_TotalClearTimeLabel(pc),a1
                nop
                move.w  #$15,d7
Results_CopyTotalClearTimeLabelLoop:                    ; CODE XREF: Results_BuildSummaryRows+54   j  ; was: loc_2036A
                move.b  (a1)+,(a0)+
                dbf     d7,Results_CopyTotalClearTimeLabelLoop
                lea     (ResultsTotalClearBCD).w,a1
                move.b  (a1)+,d0
                bsr.w   Results_WritePackedBCDByteDigits
                move.b  (a1)+,d0
                move.b  #$25,(a0)+
                bsr.w   Results_WritePackedBCDByteDigits
                move.b  #$25,(a0)+
                move.b  (a1)+,d0
                bsr.w   Results_WritePackedBCDByteDigits
                move.w  #6,d7
                move.b  #0,d0
Results_PadTotalClearTimeRowLoop:                       ; CODE XREF: Results_BuildSummaryRows+80   j  ; was: loc_20396
                move.b  d0,(a0)+
                dbf     d7,Results_PadTotalClearTimeRowLoop
                bsr.w   Results_WriteRowEndMarker
                lea     Results_TotalContinueLabel(pc),a1
                nop
                move.w  #$15,d7
Results_CopyTotalContinueLabelLoop:                     ; CODE XREF: Results_BuildSummaryRows+94   j  ; was: loc_203AA
                move.b  (a1)+,(a0)+
                dbf     d7,Results_CopyTotalContinueLabelLoop
                lea     (ResultsTotalVisitsBCD).w,a1
                move.b  #0,(a0)+
                move.b  #0,(a0)+
                move.b  #0,(a0)+
                move.b  (a1)+,d0
                bsr.w   Results_WritePackedBCDByteDigits
                move.b  (a1)+,d0
                bsr.w   Results_WritePackedBCDByteDigits
                move.b  (a1),d0
                lsr.b   #4,d0
                addq.b  #1,d0
                move.b  d0,(a0)+
                move.w  #6,d7
                move.b  #0,d0
Results_PadTotalContinueRowLoop:                        ; CODE XREF: Results_BuildSummaryRows+C6   j  ; was: loc_203DC
                move.b  d0,(a0)+
                dbf     d7,Results_PadTotalContinueRowLoop
                bsr.w   Results_WriteRowEndMarker
                rts
; End of function Results_BuildSummaryRows
; Writes a binary seconds total as three packed-BCD hour/minute/second bytes
Results_WriteSecondsAsPackedBCDTime:                    ; CODE XREF: Results_ComputeSummaryData+94   p  ; was: sub_203E8
                                        ; Results_ComputeSummaryData+C4   p
                divu.w  #$E10,d6
                move.w  d6,d0
                bsr.w   Results_WritePackedBCDByteFromLookup
                clr.w   d6
                swap    d6
                divu.w  #$3C,d6
                move.w  d6,d0
                bsr.w   Results_WritePackedBCDByteFromLookup
                clr.w   d6
                swap    d6
                move.w  d6,d0
                bsr.w   Results_WritePackedBCDByteFromLookup
                rts
; End of function Results_WriteSecondsAsPackedBCDTime
; Converts one packed-BCD byte to its binary integer value
Math_PackedBCDByteToBinary:                             ; CODE XREF: Results_ComputeSummaryData+2E   p  ; was: sub_2040C
                                        ; Results_ComputeSummaryData+38   p
                move.w  d0,d1
                lsr.w   #4,d1
                andi.w  #$F,d0
                andi.w  #$F,d1
                muls.w  #$A,d1
                add.w   d1,d0
                rts
; End of function Math_PackedBCDByteToBinary
; Writes the low packed-BCD byte for a binary component through the lookup table
Results_WritePackedBCDByteFromLookup:                   ; CODE XREF: Results_WriteSecondsAsPackedBCDTime+6   p  ; was: sub_20420
                                        ; Results_WriteSecondsAsPackedBCDTime+14   p
                add.w   d0,d0
                move.w  (a1,d0.w),d0
                andi.w  #$FF,d0
                move.b  d0,(a0)+
                rts
; End of function Results_WritePackedBCDByteFromLookup
; Advances the results viewport and redraws the row entering the visible area
Results_UpdateViewport:                                 ; CODE XREF: Results_AdvanceAutomaticHistoryViewport+1A   p  ; was: sub_2042E
                                        ; sub_20024:Results_UpdateVerticalViewport   p
                move.w  #$90,d1
                sub.w   (PrimaryCameraYPosition).w,d1
                andi.w  #$FFF0,d1
                lsr.w   #4,d1
                move.w  d1,d4
                cmpi.w  #9,d1
                bcs.w   Results_AdvanceViewportWithoutRedraw
                cmp.w   (ResultsLastScrollRow).w,d1
                bhi.w   Results_AdvanceViewportWithoutRedraw
                bra.s   Results_SelectEnteringRow
; ---------------------------------------------------------------------------
Results_AdvanceViewportWithoutRedraw:                   ; CODE XREF: Results_UpdateViewport+14   j  ; was: loc_20450
                                        ; Results_UpdateViewport+1C   j
                move.w  d1,(ResultsViewportRow).w
                bra.w   Results_ApplyVerticalScrollStep
; ---------------------------------------------------------------------------
Results_SelectEnteringRow:                              ; CODE XREF: Results_UpdateViewport+20   j  ; was: loc_20458
                tst.w   (ResultsVerticalStep).w
                bmi.s   Results_AdjustEnteringRowForNegativeStep
                subi.w  #9,d1
                bra.s   Results_PrepareEnteringRow
; ---------------------------------------------------------------------------
Results_AdjustEnteringRowForNegativeStep:               ; CODE XREF: Results_UpdateViewport+2E   j  ; was: loc_20464
                addq.w  #7,d1
Results_PrepareEnteringRow:                             ; CODE XREF: Results_UpdateViewport+34   j  ; was: loc_20466
                move.w  d1,(ResultsViewportRow).w
                move.w  d1,d0
                mulu.w  #$16,d0
                move.w  d0,(ResultsDetailTextOffset).w
                move.w  d1,d0
                mulu.w  #$26,d1
                lea     (ResultsStageRowBuffer).w,a0
                adda.w  d1,a0
                move.w  a0,(ResultsCurrentRowPtr).w
                subi.w  #9,d4
                andi.w  #$F,d4
                mulu.w  #$100,d4
                move.w  d4,(ResultsRowTileOffset).w
                addi.w  #$4006,d4
                move.w  (StageTableIndex).w,d3
                lsr.w   #1,d3
                cmp.w   d0,d3
                beq.s   Results_SelectCurrentStageEnteringRow
                cmpi.b  #$2A,4(a0)                      ; missing-field glyph
                bne.s   Results_SelectAvailableEnteringRowPalette
                move.w  #$2300,d0
                bra.s   Results_CheckEnteringRowHighlight
; ---------------------------------------------------------------------------
Results_SelectAvailableEnteringRowPalette:              ; CODE XREF: Results_UpdateViewport+7A   j  ; was: loc_204B0
                move.w  #$4300,d0
Results_CheckEnteringRowHighlight:                      ; CODE XREF: Results_UpdateViewport+80   j  ; was: loc_204B4
                cmp.w   (ResultsSelectedRowTile).w,d4
                bne.s   Results_AdjustEnteringSummaryRow
                move.w  #$FFFF,(ResultsSelectedRowTile).w
                bra.s   Results_AdjustEnteringSummaryRow
; ---------------------------------------------------------------------------
Results_SelectCurrentStageEnteringRow:                  ; CODE XREF: Results_UpdateViewport+72   j  ; was: loc_204C2
                move.w  #$6300,d0
                move.w  d1,(ResultsSelectedRowData).w
                move.w  d4,(ResultsSelectedRowTile).w
                move.w  (ResultsDetailTextOffset).w,(ResultsSelectedTextPos).w
Results_AdjustEnteringSummaryRow:                       ; CODE XREF: Results_UpdateViewport+8A   j  ; was: loc_204D4
                                        ; Results_UpdateViewport+92   j
                move.w  (ResultsViewportRow).w,d7
                cmpi.w  #$1B,d7
                bcs.w   Results_RenderEnteringPrimaryLine
                cmpi.w  #$1D,d7
                bhi.w   Results_RenderEnteringPrimaryLine
                adda.w  #$16,a0
                addi.w  #$2A,d4
Results_RenderEnteringPrimaryLine:                      ; CODE XREF: Results_UpdateViewport+AE   j  ; was: loc_204F0
                                        ; Results_UpdateViewport+B6   j
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                move.w  (ResultsViewportRow).w,d0
                cmpi.w  #$1B,d0
                bne.s   Results_CheckTotalClearTimeRow
                lea     Results_TotalLimitTimeLabel(pc),a0
                nop
                bra.s   Results_RenderEnteringSummaryLabel
; ---------------------------------------------------------------------------
Results_CheckTotalClearTimeRow:                         ; CODE XREF: Results_UpdateViewport+D0   j  ; was: loc_20508
                cmpi.w  #$1C,d0
                bne.s   Results_CheckTotalContinueRow
                lea     Results_TotalClearTimeLabel(pc),a0
                nop
                bra.s   Results_RenderEnteringSummaryLabel
; ---------------------------------------------------------------------------
Results_CheckTotalContinueRow:                          ; CODE XREF: Results_UpdateViewport+DE   j  ; was: loc_20516
                cmpi.w  #$1D,d0
                bne.s   Results_SelectEnteringDetailLine
                lea     Results_TotalContinueLabel(pc),a0
                nop
Results_RenderEnteringSummaryLabel:                     ; CODE XREF: Results_UpdateViewport+D8   j  ; was: loc_20522
                                        ; Results_UpdateViewport+E6   j
                move.w  #$300,d0
                move.w  (ResultsRowTileOffset).w,d4
                addi.w  #$4006,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
Results_SelectEnteringDetailLine:                       ; CODE XREF: Results_UpdateViewport+EC   j  ; was: loc_20534
                movea.w (ResultsCurrentRowPtr).w,a0
                move.b  $B(a0),d0
                cmpi.b  #$22,d0                         ; missing-BCD glyph
                bne.s   Results_SelectAvailableEnteringDetailText
                cmpi.b  #$2A,4(a0)                      ; missing-field glyph
                bne.s   Results_SelectMissingEnteringDetailPalette
                move.w  #$2300,d0
                bra.s   Results_SelectMissingEnteringDetailText
; ---------------------------------------------------------------------------
Results_SelectMissingEnteringDetailPalette:             ; CODE XREF: Results_UpdateViewport+11A   j  ; was: loc_20550
                move.w  #$4300,d0
Results_SelectMissingEnteringDetailText:                ; CODE XREF: Results_UpdateViewport+120   j  ; was: loc_20554
                lea     Results_MissingDetailText(pc),a0
                nop
                bra.s   Results_RenderEnteringDetailLine
; ---------------------------------------------------------------------------
Results_SelectAvailableEnteringDetailText:              ; CODE XREF: Results_UpdateViewport+112   j  ; was: loc_2055C
                move.w  #$6300,d0
                lea     Results_StageDetailTextTable(pc),a0
                nop
                adda.w  (ResultsDetailTextOffset).w,a0
Results_RenderEnteringDetailLine:                       ; CODE XREF: Results_UpdateViewport+12C   j  ; was: loc_2056A
                move.w  (ResultsRowTileOffset).w,d4
                addi.w  #$4050,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
Results_ApplyVerticalScrollStep:                        ; CODE XREF: Results_UpdateViewport+26   j  ; was: loc_20578
                move.w  (ResultsVerticalStep).w,d0
                add.w   d0,(PrimaryCameraYPosition).w
                move.w  (PrimaryCameraYPosition).w,d0
                cmpi.w  #$A,(ResultsDisplayState).w
                bne.s   Results_UpdateViewportReturn
                bsr.w   Results_QueuePeriodicScrollSound
Results_UpdateViewportReturn:                           ; CODE XREF: Results_UpdateViewport+15C   j  ; was: locret_20590
                rts
; End of function Results_UpdateViewport
; Queues request $EF once per four-frame interval during interactive scrolling
Results_QueuePeriodicScrollSound:                       ; CODE XREF: Results_UpdateViewport+15E   p  ; was: sub_20592
                btst    #0,(FrameCounter+1).w
                bne.s   Results_PeriodicScrollSoundReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Results_PeriodicScrollSoundReturn
                move.b  #$EF,d0
                jsr     (Sound_QueueSFXRequest).l
Results_PeriodicScrollSoundReturn:                      ; CODE XREF: Results_QueuePeriodicScrollSound+6   j  ; was: locret_205AC
                                        ; Results_QueuePeriodicScrollSound+E   j
                rts
; End of function Results_QueuePeriodicScrollSound
; Redraws the selected row with its alternating highlight attributes
Results_RenderSelectedRowHighlight:                     ; CODE XREF: Results_UpdateAutomaticHistoryScroll+14   p  ; was: sub_205AE
                                        ; Results_UpdateBrowsingState+8   p
                tst.b   (ResultsSelectedRowTile).w
                bmi.s   Results_RenderSelectedRowHighlightReturn
                btst    #1,(VBlankFrameCounter+1).w
                beq.s   Results_SelectAlternateHighlightPalette
                move.w  #$300,d0
                move.w  d0,(ResultsHighlightPalette).w
                bra.s   Results_PrepareSelectedRowHighlight
; ---------------------------------------------------------------------------
Results_SelectAlternateHighlightPalette:                ; CODE XREF: Results_RenderSelectedRowHighlight+C   j  ; was: loc_205C6
                move.w  #$6300,d0
                move.w  d0,(ResultsHighlightPalette).w
Results_PrepareSelectedRowHighlight:                    ; CODE XREF: Results_RenderSelectedRowHighlight+16   j  ; was: loc_205CE
                lea     (ResultsStageRowBuffer).w,a0
                adda.w  (ResultsSelectedRowData).w,a0
                move.w  a0,(ResultsCurrentRowPtr).w
                move.w  (ResultsSelectedRowTile).w,d4
                btst    #$E,d4
                beq.s   Results_SelectSelectedDetailText
                jsr     (Text_QueueDoubleHeightStringWrapped).l
Results_SelectSelectedDetailText:                       ; CODE XREF: Results_RenderSelectedRowHighlight+34   j  ; was: loc_205EA
                movea.w (ResultsCurrentRowPtr).w,a0
                move.b  $B(a0),d0
                cmpi.b  #$22,d0                         ; missing-BCD glyph
                bne.s   Results_SelectAvailableSelectedDetailText
                lea     Results_MissingDetailText(pc),a0
                nop
                bra.s   Results_RenderSelectedDetailHighlight
; ---------------------------------------------------------------------------
Results_SelectAvailableSelectedDetailText:              ; CODE XREF: Results_RenderSelectedRowHighlight+48   j  ; was: loc_20600
                lea     Results_StageDetailTextTable(pc),a0
                nop
                adda.w  (ResultsSelectedTextPos).w,a0
Results_RenderSelectedDetailHighlight:                  ; CODE XREF: Results_RenderSelectedRowHighlight+50   j  ; was: loc_2060A
                move.w  (ResultsHighlightPalette).w,d0
                move.w  (ResultsSelectedRowTile).w,d4
                addi.w  #$4A,d4
                btst    #$E,d4
                beq.s   Results_RenderSelectedRowHighlightReturn
                jsr     (Text_QueueDoubleHeightStringWrapped).l
Results_RenderSelectedRowHighlightReturn:               ; CODE XREF: Results_RenderSelectedRowHighlight+4   j  ; was: locret_20622
                                        ; Results_RenderSelectedRowHighlight+6C   j
                rts
; End of function Results_RenderSelectedRowHighlight
; Direct two-pixel vertical-scroll helper; no static caller is currently known
Results_HandleDirectVerticalScroll:                     ; was: sub_20624
                btst    #0,(ControllerHeldState).w
                beq.s   Results_CheckDirectScrollDown
                cmpi.w  #$90,(PrimaryCameraYPosition).w
                bge.s   Results_CheckDirectScrollDown
                addq.w  #2,(PrimaryCameraYPosition).w
Results_CheckDirectScrollDown:                          ; CODE XREF: Results_HandleDirectVerticalScroll+6   j  ; was: loc_20638
                                        ; Results_HandleDirectVerticalScroll+E   j
                btst    #1,(ControllerHeldState).w
                beq.s   Results_DirectVerticalScrollReturn
                move.w  (PrimaryCameraYPosition).w,d0
                cmp.w   (ResultsLowerScrollBound).w,d0
                ble.s   Results_DirectVerticalScrollReturn
                subq.w  #2,(PrimaryCameraYPosition).w
Results_DirectVerticalScrollReturn:                     ; CODE XREF: Results_HandleDirectVerticalScroll+1A   j  ; was: locret_2064E
                                        ; Results_HandleDirectVerticalScroll+24   j
                rts
; End of function Results_HandleDirectVerticalScroll
; ---------------------------------------------------------------------------
Results_MissingDetailText:  dc.w    $2A2A, $2A2A, $2A2A, $2A2A, 0, 0, 0, 0, 0, 0, $FF  ; was: word_20650
                                        ; DATA XREF: Results_RenderInitialHistoryRow:Results_SelectMissingDetailText   o
                                        ; sub_1FEE2:Results_SelectScrolledMissingDetailText   o
Results_StageDetailTextTable:   binclude "data/other/results_stage_detail_text.bin"  ; was: word_20666
Results_StageDetailTextTableEnd:                        ; was: word_20666_End
Results_TotalLimitTimeLabel:    dc.w    0, $1E19, $1E0B, $1600, $1613, $1713, $1E00, $1E13, $170F, 0, 0  ; was: word_20910
                                        ; DATA XREF: Results_BuildSummaryRows+8   o
                                        ; Results_UpdateViewport+D2   o
                dc.b    $FF
Results_TotalClearTimeLabel:    dc.w    0, $1E19, $1E0B, $1600, $D16, $F0B, $1C00, $1E13, $170F, 0, 0  ; was: word_20927
                                        ; DATA XREF: Results_BuildSummaryRows+48   o
                                        ; Results_UpdateViewport+E0   o
                dc.b    $FF
Results_TotalContinueLabel: dc.w    0, $1E19, $1E0B, $1600, $D19, $181E, $1318, $1F0F, 0, 0, 0  ; was: word_2093E
                                        ; DATA XREF: Results_BuildSummaryRows+88   o
                                        ; Results_UpdateViewport+EE   o
                dc.w    $FFFF

; Initializes Xi Tiger credits sequence with graphics and palettes
