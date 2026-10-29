; Updates the stage-history display and lets the extended layout restart the frontend
Results_UpdateHistoryDisplayAndHandleExtendedExit:      ; was: sub_1FBEC
                                        ; Results_UpdateFinalSummary+A   p
                bsr.s   Results_DispatchHistoryDisplayState
                move.w  (PrimaryCameraXPosition).w,(SecondaryCameraXPos).w
                tst.w   (ResultsLayoutModeCopy).w
                beq.s   Results_UpdateHistoryDisplayAndHandleExtendedExitReturn
                btst    #7,(ControllerPressedState).w
                beq.s   Results_UpdateHistoryDisplayAndHandleExtendedExitReturn
                move.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
Results_UpdateHistoryDisplayAndHandleExtendedExitReturn:  ; was: locret_1FC0C
                                        ; Results_UpdateHistoryDisplayAndHandleExtendedExit+14   j
                rts
; End of function Results_UpdateHistoryDisplayAndHandleExtendedExit
; Dispatches the stage-history display state stored at ResultsDisplayState
Results_DispatchHistoryDisplayState:                    ; was: sub_1FC0E
                move.w  (ResultsDisplayState).w,d0
                lea     Results_HistoryDisplayStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Results_DispatchHistoryDisplayState
; ---------------------------------------------------------------------------
Results_HistoryDisplayStateOffsets: dc.w    Results_InitializeHistoryDisplay-*  ; was: off_1FC1A
                dc.w    Results_RenderInitialHistoryRow-*
                dc.w    Results_ScrollHistoryIntoView-*
                dc.w    Results_RenderAdditionalHistoryRowAndScroll-*
                dc.w    Results_UpdateAutomaticHistoryScroll-*
                dc.w    Results_UpdateBrowsingState-*

; Builds 25 per-stage history rows, summary rows, and the initial viewport state
Results_InitializeHistoryDisplay:                       ; was: sub_1FC26
                addq.w  #2,(ResultsDisplayState).w
                move.w  #1,d0
                move.w  (ResultsExtendedLayout).w,(ResultsLayoutModeCopy).w
                clr.w   (ResultsExtendedLayout).w
                tst.w   (ResultsLayoutModeCopy).w
                bne.s   Results_SetHistoryScrollBounds
                tst.w   d0
                bne.s   Results_SetHistoryScrollBounds
                move.w  #$13,(ResultsLastScrollRow).w
                move.w  #$FF40,(ResultsLowerScrollBound).w
                bra.s   Results_ConfigureInitialViewport
; ---------------------------------------------------------------------------
Results_SetHistoryScrollBounds:                         ; was: loc_1FC50
                                        ; Results_InitializeHistoryDisplay+1A   j
                move.w  #$17,(ResultsLastScrollRow).w
                move.w  #$FEF0,(ResultsLowerScrollBound).w
Results_ConfigureInitialViewport:                       ; was: loc_1FC5C
                move.w  #$50,(SecondaryCameraYPos).w
                move.w  #$F0,(PrimaryCameraYPosition).w
                clr.w   (PrimaryCameraXPosition).w
                move.w  #$18,d7
                lea     (ResultsStageRowBuffer).w,a0
                lea     (StageTimeLimitTable).l,a1
                lea     (StagePhaseSplitTimes).w,a2
                lea     (StageCompletionTimes).w,a3
                lea     (StageResultVisits).w,a4
                moveq   #1,d5
                moveq   #0,d6
Results_BuildStageRowsLoop:                             ; was: loc_1FC8A
                sub.w   d4,d4
                abcd    d5,d6
                move.w  d6,d0
                bsr.w   Results_WritePackedBCDByteDigits
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowPaddingByte
                move.w  (ResultsRenderedRowCount).w,d0
                addq.w  #2,(ResultsRenderedRowCount).w
                cmp.w   (StageTableIndex).w,d0
                bhi.s   Results_WriteMissingStageTimeLimit
                tst.w   (a2)
                bpl.s   Results_WriteStageTimeLimit
                cmp.w   (StageTableIndex).w,d0
                bne.s   Results_WriteMissingStageTimeLimit
Results_WriteStageTimeLimit:                            ; was: loc_1FCB4
                move.w  (a1),(ResultsStageTimeScratch).w
                move.b  (a1),d0
                bsr.w   Results_WritePackedBCDByteDigits
                bsr.w   Results_WriteTimeSeparator
                move.b  1(a1),d0
                bsr.w   Results_WritePackedBCDByteDigits
                bra.s   Results_AdvanceToFirstInterval
; ---------------------------------------------------------------------------
Results_WriteMissingStageTimeLimit:                     ; was: loc_1FCCC
                                        ; Results_InitializeHistoryDisplay+8C   j
                bsr.w   Results_WriteMissingGlyph
                bsr.w   Results_WriteMissingGlyph
                bsr.w   Results_WriteTimeSeparator
                bsr.w   Results_WriteMissingGlyph
                bsr.w   Results_WriteMissingGlyph
Results_AdvanceToFirstInterval:                         ; was: loc_1FCE0
                addq.w  #2,a1
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowPaddingByte
                move.w  (a2)+,(ResultsPhaseTimeScratch).w
                bmi.s   Results_WriteMissingFirstInterval
                move.w  (ResultsStageTimeScratch).w,(ResultsBCDStartTime).w
                move.w  (ResultsPhaseTimeScratch).w,(ResultsBCDEndTime).w
                bsr.w   Results_FormatBCDTimeDifference
                bra.s   Results_AdvanceToSecondInterval
; ---------------------------------------------------------------------------
Results_WriteMissingFirstInterval:                      ; was: loc_1FD02
                move.b  #$FF,d0
                bsr.w   Results_WritePackedBCDByteDigits
                bsr.w   Results_WriteTimeSeparator
                move.b  #$FF,d0
                bsr.w   Results_WritePackedBCDByteDigits
Results_AdvanceToSecondInterval:                        ; was: loc_1FD16
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowPaddingByte
                move.w  (a3)+,(ResultsEndTimeScratch).w
                bmi.s   Results_WriteMissingSecondInterval
                move.w  (ResultsPhaseTimeScratch).w,(ResultsBCDStartTime).w
                move.w  (ResultsEndTimeScratch).w,(ResultsBCDEndTime).w
                bsr.w   Results_FormatBCDTimeDifference
                bra.s   Results_AdvanceToTotalInterval
; ---------------------------------------------------------------------------
Results_WriteMissingSecondInterval:                     ; was: loc_1FD36
                move.b  #$FF,d0
                bsr.w   Results_WritePackedBCDByteDigits
                bsr.w   Results_WriteTimeSeparator
                move.b  #$FF,d0
                bsr.w   Results_WritePackedBCDByteDigits
Results_AdvanceToTotalInterval:                         ; was: loc_1FD4A
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowPaddingByte
                tst.w   (ResultsEndTimeScratch).w
                bmi.s   Results_WriteMissingTotalInterval
                move.w  (ResultsStageTimeScratch).w,(ResultsBCDStartTime).w
                move.w  (ResultsEndTimeScratch).w,(ResultsBCDEndTime).w
                bsr.w   Results_FormatBCDTimeDifference
                bra.s   Results_PrepareStageVisitCount
; ---------------------------------------------------------------------------
Results_WriteMissingTotalInterval:                      ; was: loc_1FD6A
                move.b  #$FF,d0
                bsr.w   Results_WritePackedBCDByteDigits
                bsr.w   Results_WriteTimeSeparator
                move.b  #$FF,d0
                bsr.w   Results_WritePackedBCDByteDigits
Results_PrepareStageVisitCount:                         ; was: loc_1FD7E
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowPaddingByte
                move.w  (a4)+,d0
                bpl.s   Results_ConvertStageVisitCountToBCD
                tst.w   -2(a3)
                bmi.s   Results_WriteStageVisitCount
Results_ConvertStageVisitCountToBCD:                    ; was: loc_1FD90
                addq.w  #1,d0
                movem.w a0,-(sp)
                lea     (Math_PackedBCDLookup).l,a0
                add.w   d0,d0
                move.w  (a0,d0.w),d0
                movem.w (sp)+,a0
Results_WriteStageVisitCount:                           ; was: loc_1FDA6
                bsr.w   Results_WritePackedBCDThreeDigits
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowPaddingByte
                bsr.w   Results_WriteRowEndMarker
                dbf     d7,Results_BuildStageRowsLoop
                move.w  #5,d6
Results_AppendBlankRowsLoop:                            ; was: loc_1FDBE
                move.w  #$24,d7
Results_ClearBlankRowLoop:                              ; was: loc_1FDC2
                bsr.w   Results_WriteRowPaddingByte
                dbf     d7,Results_ClearBlankRowLoop
                bsr.w   Results_WriteRowEndMarker
                dbf     d6,Results_AppendBlankRowsLoop
                bsr.w   Results_ComputeSummaryData
                clr.w   (ResultsRenderedRowCount).w
                clr.w   (ResultsRowTileOffset).w
                clr.w   (ResultsRowBufferOffset).w
                clr.w   (ResultsScrollTargetY).w
                clr.w   (ResultsMusicQueuedFlag).w
                rts
; End of function Results_InitializeHistoryDisplay
; Renders one of the first ten stage-history rows before the viewport enters
Results_RenderInitialHistoryRow:                        ; was: sub_1FDEC
                lea     (ResultsStageRowBuffer).w,a0
                adda.w  (ResultsRowBufferOffset).w,a0
                move.w  a0,(ResultsCurrentRowPtr).w
                move.w  #$4006,d4
                add.w   (ResultsRowTileOffset).w,d4
                move.w  (StageTableIndex).w,d3
                lsr.w   #1,d3
                cmp.w   (ResultsRenderedRowCount).w,d3
                beq.s   Results_SelectCurrentStageRow
                cmpi.b  #$2A,4(a0)                      ; missing-field glyph
                bne.s   Results_SelectAvailableRowPalette
                move.w  #$2300,d0
                bra.s   Results_CheckInitialRowCursor
; ---------------------------------------------------------------------------
Results_SelectAvailableRowPalette:                      ; was: loc_1FE1A
                move.w  #$4300,d0
Results_CheckInitialRowCursor:                          ; was: loc_1FE1E
                cmp.w   (ResultsSelectedRowTile).w,d4
                bne.s   Results_RenderInitialPrimaryLine
                move.w  #$FFFF,(ResultsSelectedRowTile).w
                bra.s   Results_RenderInitialPrimaryLine
; ---------------------------------------------------------------------------
Results_SelectCurrentStageRow:                          ; was: loc_1FE2C
                move.w  #$6300,d0
                move.w  (ResultsRowBufferOffset).w,(ResultsSelectedRowData).w
                move.w  (ResultsDetailTextOffset).w,(ResultsSelectedTextPos).w
                move.w  d4,(ResultsSelectedRowTile).w
Results_RenderInitialPrimaryLine:                       ; was: loc_1FE40
                                        ; Results_RenderInitialHistoryRow+3E   j
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                movea.w (ResultsCurrentRowPtr).w,a0
                move.b  $B(a0),d0
                cmpi.b  #$22,d0                         ; missing-BCD glyph
                bne.s   Results_SelectInitialDetailText
                cmpi.b  #$2A,4(a0)                      ; missing-field glyph
                bne.s   Results_SelectMissingDetailPalette
                move.w  #$2300,d0
                bra.s   Results_SelectMissingDetailText
; ---------------------------------------------------------------------------
Results_SelectMissingDetailPalette:                     ; was: loc_1FE62
                move.w  #$4300,d0
Results_SelectMissingDetailText:                        ; was: loc_1FE66
                lea     Results_MissingDetailText(pc),a0
                nop
                bra.s   Results_RenderInitialDetailLine
; ---------------------------------------------------------------------------
Results_SelectInitialDetailText:                        ; was: loc_1FE6E
                move.w  #$6300,d0
                lea     Results_StageDetailTextTable(pc),a0
                nop
                adda.w  (ResultsDetailTextOffset).w,a0
Results_RenderInitialDetailLine:                        ; was: loc_1FE7C
                move.w  #$4050,d4
                add.w   (ResultsRowTileOffset).w,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                addi.w  #$100,(ResultsRowTileOffset).w
                addi.w  #$26,(ResultsRowBufferOffset).w
                addi.w  #$16,(ResultsDetailTextOffset).w
                addq.w  #1,(ResultsRenderedRowCount).w
                cmpi.w  #$A,(ResultsRenderedRowCount).w
                bcs.s   Results_RenderInitialRowReturn
                addq.w  #2,(ResultsDisplayState).w
Results_RenderInitialRowReturn:                         ; was: locret_1FEAC
                rts
; End of function Results_RenderInitialHistoryRow
; Scrolls the first ten rendered history rows into view and selects the final target
Results_ScrollHistoryIntoView:                          ; was: sub_1FEAE
                subq.w  #2,(SecondaryCameraYPos).w
                subq.w  #2,(PrimaryCameraYPosition).w
                cmpi.w  #$90,(PrimaryCameraYPosition).w
                bne.s   Results_InitialScrollReturn
                addq.w  #2,(ResultsDisplayState).w
                tst.w   (ResultsLayoutModeCopy).w
                bne.s   Results_SetExtendedScrollTarget
                move.w  (StageTableIndex).w,d0
                lsl.w   #3,d0
                neg.w   d0
                addi.w  #$90,d0
                move.w  d0,(ResultsScrollTargetY).w
                rts
; ---------------------------------------------------------------------------
Results_SetExtendedScrollTarget:                        ; was: loc_1FEDA
                move.w  #$FEF0,(ResultsScrollTargetY).w
Results_InitialScrollReturn:                            ; was: locret_1FEE0
                rts
; End of function Results_ScrollHistoryIntoView
; Renders one additional history row while moving toward the automatic scroll target
Results_RenderAdditionalHistoryRowAndScroll:            ; was: sub_1FEE2
                bsr.w   Results_QueueCompletionMusicAtScrollThreshold
                move.w  (ResultsScrollTargetY).w,d0
                cmp.w   (PrimaryCameraYPosition).w,d0
                beq.s   Results_RenderScrolledRow
                subq.w  #2,(PrimaryCameraYPosition).w
Results_RenderScrolledRow:                              ; was: loc_1FEF4
                lea     (ResultsStageRowBuffer).w,a0
                adda.w  (ResultsRowBufferOffset).w,a0
                move.w  a0,(ResultsCurrentRowPtr).w
                move.w  #$4006,d4
                add.w   (ResultsRowTileOffset).w,d4
                move.w  (StageTableIndex).w,d3
                lsr.w   #1,d3
                cmp.w   (ResultsRenderedRowCount).w,d3
                beq.s   Results_SelectScrolledCurrentStageRow
                cmpi.b  #$2A,4(a0)                      ; missing-field glyph
                bne.s   Results_SelectScrolledAvailablePalette
                move.w  #$2300,d0
                bra.s   Results_RenderScrolledPrimaryLine
; ---------------------------------------------------------------------------
Results_SelectScrolledAvailablePalette:                 ; was: loc_1FF22
                move.w  #$4300,d0
                bra.s   Results_RenderScrolledPrimaryLine
; ---------------------------------------------------------------------------
Results_SelectScrolledCurrentStageRow:                  ; was: loc_1FF28
                move.w  #$6300,d0
                move.w  (ResultsRowBufferOffset).w,(ResultsSelectedRowData).w
                move.w  (ResultsDetailTextOffset).w,(ResultsSelectedTextPos).w
                move.w  d4,(ResultsSelectedRowTile).w
Results_RenderScrolledPrimaryLine:                      ; was: loc_1FF3C
                                        ; Results_RenderAdditionalHistoryRowAndScroll+44   j
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                movea.w (ResultsCurrentRowPtr).w,a0
                move.b  $B(a0),d0
                cmpi.b  #$22,d0                         ; missing-BCD glyph
                bne.s   Results_SelectScrolledDetailText
                cmpi.b  #$2A,4(a0)                      ; missing-field glyph
                bne.s   Results_SelectScrolledMissingDetailPalette
                move.w  #$2300,d0
                bra.s   Results_SelectScrolledMissingDetailText
; ---------------------------------------------------------------------------
Results_SelectScrolledMissingDetailPalette:             ; was: loc_1FF5E
                move.w  #$4300,d0
Results_SelectScrolledMissingDetailText:                ; was: loc_1FF62
                lea     Results_MissingDetailText(pc),a0
                nop
                bra.s   Results_RenderScrolledDetailLine
; ---------------------------------------------------------------------------
Results_SelectScrolledDetailText:                       ; was: loc_1FF6A
                move.w  #$6300,d0
                lea     Results_StageDetailTextTable(pc),a0
                nop
                adda.w  (ResultsDetailTextOffset).w,a0
Results_RenderScrolledDetailLine:                       ; was: loc_1FF78
                move.w  #$4050,d4
                add.w   (ResultsRowTileOffset).w,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                addi.w  #$16,(ResultsDetailTextOffset).w
                addi.w  #$100,(ResultsRowTileOffset).w
                addi.w  #$26,(ResultsRowBufferOffset).w
                addq.w  #1,(ResultsRenderedRowCount).w
                cmpi.w  #$10,(ResultsRenderedRowCount).w
                bcs.s   Results_RenderScrolledRowReturn
                addq.w  #2,(ResultsDisplayState).w
Results_RenderScrolledRowReturn:                        ; was: locret_1FFA8
                rts
; End of function Results_RenderAdditionalHistoryRowAndScroll
; Advances the automatic viewport twice per frame, then enters browsing state
Results_UpdateAutomaticHistoryScroll:                   ; was: sub_1FFAA
                bsr.w   Results_QueueCompletionMusicAtScrollThreshold
                bsr.s   Results_AdvanceAutomaticHistoryViewport
                tst.w   (ResultsVerticalStep).w
                beq.s   Results_AdvanceToBrowsingState
                bsr.s   Results_AdvanceAutomaticHistoryViewport
                tst.w   (ResultsVerticalStep).w
                beq.s   Results_AdvanceToBrowsingState
                bsr.w   Results_RenderSelectedRowHighlight
                rts
; ---------------------------------------------------------------------------
Results_AdvanceToBrowsingState:                         ; was: loc_1FFC4
                                        ; Results_UpdateAutomaticHistoryScroll+12   j
                addq.w  #2,(ResultsDisplayState).w
                rts
; End of function Results_UpdateAutomaticHistoryScroll
; Advances one automatic upward viewport step while target and lower bound allow it
Results_AdvanceAutomaticHistoryViewport:                ; was: sub_1FFCA
                                        ; Results_UpdateAutomaticHistoryScroll+C   p
                move.w  (ResultsScrollTargetY).w,d0
                cmp.w   (PrimaryCameraYPosition).w,d0
                beq.s   Results_ClearAutomaticVerticalStep
                move.w  (PrimaryCameraYPosition).w,d0
                cmp.w   (ResultsLowerScrollBound).w,d0
                ble.s   Results_ClearAutomaticVerticalStep
                move.w  #$FFFF,(ResultsVerticalStep).w
                bsr.w   Results_UpdateViewport
                rts
; ---------------------------------------------------------------------------
Results_ClearAutomaticVerticalStep:                     ; was: loc_1FFEA
                                        ; Results_AdvanceAutomaticHistoryViewport+12   j
                clr.w   (ResultsVerticalStep).w
                rts
; End of function Results_AdvanceAutomaticHistoryViewport
; Queues the completion music once the scrolling rows reach the trigger point
Results_QueueCompletionMusicAtScrollThreshold:          ; was: sub_1FFF0
                                        ; sub_1FFAA   p
                tst.w   (ResultsMusicQueuedFlag).w
                bne.s   Results_CompletionMusicReturn
                move.w  (ResultsScrollTargetY).w,d0
                addi.w  #$48,d0
                cmp.w   (PrimaryCameraYPosition).w,d0
                blt.s   Results_CompletionMusicReturn
                move.w  #1,(ResultsMusicQueuedFlag).w
                move.b  #$85,d0
                jsr     (Sound_QueueSFXRequest).l
Results_CompletionMusicReturn:                          ; was: locret_20014
                                        ; Results_QueueCompletionMusicAtScrollThreshold+12   j
                rts
; End of function Results_QueueCompletionMusicAtScrollThreshold
; Updates the interactive results view and draws its flashing row cursor
Results_UpdateBrowsingState:                            ; was: sub_20016
                bsr.w   Results_HandleNavigation
                bsr.w   Results_HandleNavigation
                bsr.w   Results_RenderSelectedRowHighlight
                rts
; End of function Results_UpdateBrowsingState
; Handles D-pad scrolling and column snapping for results screen browsing
Results_HandleNavigation:                               ; was: sub_20024
                                        ; Results_UpdateBrowsingState+4   p
                btst    #2,(ControllerHeldState).w
                beq.s   Results_CheckRightNavigation
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #-1,d0
                cmpi.w  #0,d0
                blt.s   Results_StopHorizontalNavigation
                move.w  #1,(ResultsHorizontalActive).w
                move.w  #$FFFF,(ResultsHorizontalStep).w
                addi.w  #-1,(PrimaryCameraXPosition).w
Results_CheckRightNavigation:                           ; was: loc_2004C
                btst    #3,(ControllerHeldState).w
                beq.s   Results_CheckUpNavigation
                move.w  (PrimaryCameraXPosition).w,d0
                addq.w  #1,d0
                cmpi.w  #$D0,d0
                bgt.s   Results_StopHorizontalNavigation
                move.w  #1,(ResultsHorizontalActive).w
                move.w  #1,(ResultsHorizontalStep).w
                addi.w  #1,(PrimaryCameraXPosition).w
                bra.s   Results_CheckUpNavigation
; ---------------------------------------------------------------------------
Results_StopHorizontalNavigation:                       ; was: loc_20074
                                        ; Results_HandleNavigation+3A   j
                tst.w   (ResultsHorizontalActive).w
                beq.s   Results_ClearHorizontalStep
                clr.w   (ResultsHorizontalActive).w
                move.b  #$DB,d0
                jsr     (Sound_QueueSFXRequest).l
Results_ClearHorizontalStep:                            ; was: loc_20088
                clr.w   (ResultsHorizontalStep).w
Results_CheckUpNavigation:                              ; was: loc_2008C
                                        ; Results_HandleNavigation+4E   j
                btst    #0,(ControllerHeldState).w
                beq.s   Results_CheckDownNavigation
                move.w  (PrimaryCameraYPosition).w,d0
                addq.w  #1,d0
                cmpi.w  #$90,d0
                bgt.s   Results_StopVerticalNavigation
                move.w  #1,(ResultsVerticalStep).w
                bra.s   Results_UpdateVerticalViewport
; ---------------------------------------------------------------------------
Results_CheckDownNavigation:                            ; was: loc_200A8
                btst    #1,(ControllerHeldState).w
                beq.w   Results_ContinueHorizontalStep
                move.w  (PrimaryCameraYPosition).w,d0
                subq.w  #1,d0
                cmp.w   (ResultsLowerScrollBound).w,d0
                blt.s   Results_StopVerticalNavigation
                move.w  #$FFFF,(ResultsVerticalStep).w
Results_UpdateVerticalViewport:                         ; was: loc_200C4
                bsr.w   Results_UpdateViewport
                rts
; ---------------------------------------------------------------------------
Results_StopVerticalNavigation:                         ; was: loc_200CA
                                        ; Results_HandleNavigation+98   j
                clr.w   (ResultsVerticalStep).w
                rts
; ---------------------------------------------------------------------------
Results_ContinueHorizontalStep:                         ; was: loc_200D0
                tst.w   (ResultsHorizontalStep).w
                beq.s   Results_ClampHorizontalMaximum
                move.w  (ResultsHorizontalStep).w,d0
                add.w   d0,(PrimaryCameraXPosition).w
                move.w  (PrimaryCameraXPosition).w,d0
                andi.w  #$F,d0
                bne.s   Results_ClampHorizontalMaximum
                tst.w   (PrimaryCameraXPosition).w
                beq.s   Results_HandleHorizontalSnapPoint
                cmpi.w  #$30,(PrimaryCameraXPosition).w
                beq.s   Results_HandleHorizontalSnapPoint
                cmpi.w  #$60,(PrimaryCameraXPosition).w
                beq.s   Results_HandleHorizontalSnapPoint
                cmpi.w  #$A0,(PrimaryCameraXPosition).w
                beq.s   Results_HandleHorizontalSnapPoint
                cmpi.w  #$D0,(PrimaryCameraXPosition).w
                bne.s   Results_ClampHorizontalMaximum
Results_HandleHorizontalSnapPoint:                      ; was: loc_2010E
                                        ; Results_HandleNavigation+D0   j
                tst.b   (ControllerHeldState).w
                bne.s   Results_ClearHorizontalStepAtSnap
                tst.w   (ResultsHorizontalActive).w
                beq.s   Results_ClearHorizontalStepAtSnap
                clr.w   (ResultsHorizontalActive).w
                move.b  #$DB,d0
                jsr     (Sound_QueueSFXRequest).l
Results_ClearHorizontalStepAtSnap:                      ; was: loc_20128
                                        ; Results_HandleNavigation+F4   j
                clr.w   (ResultsHorizontalStep).w
Results_ClampHorizontalMaximum:                         ; was: loc_2012C
                                        ; Results_HandleNavigation+C2   j
                cmpi.w  #$D0,(PrimaryCameraXPosition).w
                blt.s   Results_ClampHorizontalMinimum
                move.w  #$D0,(PrimaryCameraXPosition).w
                clr.w   (ResultsHorizontalStep).w
Results_ClampHorizontalMinimum:                         ; was: loc_2013E
                cmpi.w  #0,(PrimaryCameraXPosition).w
                bgt.s   Results_ContinueVerticalStep
                move.w  #0,(PrimaryCameraXPosition).w
                clr.w   (ResultsHorizontalStep).w
Results_ContinueVerticalStep:                           ; was: loc_20150
                tst.w   (ResultsVerticalStep).w
                beq.s   Results_ClampVerticalUpperBound
                bsr.w   Results_UpdateViewport
                move.w  (PrimaryCameraYPosition).w,d0
                andi.w  #$F,d0
                bne.s   Results_ClampVerticalUpperBound
                clr.w   (ResultsVerticalStep).w
Results_ClampVerticalUpperBound:                        ; was: loc_20168
                                        ; Results_HandleNavigation+13E   j
                cmpi.w  #$90,(PrimaryCameraYPosition).w
                blt.s   Results_ClampVerticalLowerBound
                move.w  #$90,(PrimaryCameraYPosition).w
                clr.w   (ResultsVerticalStep).w
Results_ClampVerticalLowerBound:                        ; was: loc_2017A
                move.w  (PrimaryCameraYPosition).w,d0
                cmp.w   (ResultsLowerScrollBound).w,d0
                bgt.s   Results_NavigationReturn
                move.w  (ResultsLowerScrollBound).w,(PrimaryCameraYPosition).w
                clr.w   (ResultsVerticalStep).w
Results_NavigationReturn:                               ; was: locret_2018E
                rts
; End of function Results_HandleNavigation
; Appends the $FF terminator to a results row
Results_WriteRowEndMarker:                              ; was: sub_20190
                                        ; Results_InitializeHistoryDisplay+1A4   p
                move.b  #$FF,(a0)+
                rts
; End of function Results_WriteRowEndMarker
; Appends one zero padding byte to a results row
Results_WriteRowPaddingByte:                            ; was: sub_20196
                                        ; Results_InitializeHistoryDisplay+72   p
                move.b  #0,(a0)+
                rts
; End of function Results_WriteRowPaddingByte
; Writes the custom-font separator between packed-BCD time fields
Results_WriteTimeSeparator:                             ; was: sub_2019C
                                        ; Results_InitializeHistoryDisplay+AE   p
                move.b  #$25,(a0)+
                rts
; End of function Results_WriteTimeSeparator
; Writes one custom-font glyph used to mark a missing result field
Results_WriteMissingGlyph:                              ; was: sub_201A2
                                        ; Results_InitializeHistoryDisplay+AA   p
                move.b  #$2A,(a0)+
                rts
; End of function Results_WriteMissingGlyph
; Writes two results-font glyph indices from one packed-BCD byte
Results_WritePackedBCDByteDigits:                       ; was: sub_201A8
                                        ; Results_InitializeHistoryDisplay+94   p
                tst.b   d0
                bmi.s   Results_WriteMissingBCDByte
                move.b  d0,d1
                lsr.b   #4,d1
                addq.b  #1,d1
                move.b  d1,(a0)+
                andi.b  #$F,d0
                addq.b  #1,d0
                move.b  d0,(a0)+
                rts
; ---------------------------------------------------------------------------
Results_WriteMissingBCDByte:                            ; was: loc_201BE
                move.b  #$22,(a0)+                      ; missing-BCD glyph
                move.b  #$22,(a0)+                      ; missing-BCD glyph
                rts
; End of function Results_WritePackedBCDByteDigits
; Writes three results-font glyph indices from the low three packed-BCD nibbles
Results_WritePackedBCDThreeDigits:                      ; was: sub_201C8
                tst.w   d0
                bmi.s   Results_WriteMissingBCDWord
                move.w  d0,d1
                lsr.w   #8,d1
                addq.b  #1,d1
                move.b  d1,(a0)+
                move.w  d0,d1
                lsr.w   #4,d1
                addq.b  #1,d1
                move.b  d1,(a0)+
                andi.b  #$F,d0
                addq.b  #1,d0
                move.b  d0,(a0)+
                rts
; ---------------------------------------------------------------------------
Results_WriteMissingBCDWord:                            ; was: loc_201E6
                move.b  #$22,(a0)+                      ; missing-BCD glyph
                move.b  #$22,(a0)+                      ; missing-BCD glyph
                move.b  #$22,(a0)+                      ; missing-BCD glyph
                rts
; End of function Results_WritePackedBCDThreeDigits
; Formats the difference between two packed-BCD times with a field separator
Results_FormatBCDTimeDifference:                        ; was: sub_201F4
                                        ; Results_InitializeHistoryDisplay+10A   p
                bsr.s   Results_CalculatePackedBCDTimeDifference
                move.b  d2,d0
                bsr.w   Results_WritePackedBCDByteDigits
                bsr.w   Results_WriteTimeSeparator
                move.b  d3,d0
                bsr.w   Results_WritePackedBCDByteDigits
                rts
; End of function Results_FormatBCDTimeDifference
; Subtracts ResultsBCDEndTime from ResultsBCDStartTime with a 60-second borrow
Results_CalculatePackedBCDTimeDifference:               ; was: sub_20208
                                        ; Results_ComputeSummaryData+5C   p
                move.b  (ResultsBCDStartTime).w,d0
                move.b  (ResultsBCDEndTime).w,d1
                sub.w   d4,d4
                sbcd    d1,d0
                move.b  d0,d2
                move.b  (ResultsBCDStartTime+1).w,d0
                move.b  (ResultsBCDEndTime+1).w,d1
                cmp.b   d1,d0
                bcc.s   Results_SubtractBCDLowByte
                moveq   #1,d3
                sub.w   d4,d4
                sbcd    d3,d2
                moveq   #$60,d3
                sub.w   d4,d4
                abcd    d3,d0
Results_SubtractBCDLowByte:                             ; was: loc_2022E
                sub.w   d4,d4
                sbcd    d1,d0
                move.b  d0,d3
                rts
; End of function Results_CalculatePackedBCDTimeDifference
; Clears all 25 packed-BCD entries in StageCompletionTimes
Results_ClearStageCompletionTimes:                      ; was: sub_20236
                move.w  #$18,d7
                move.w  #0,d0
                lea     (StageCompletionTimes).w,a0
Results_ClearStageCompletionTimesLoop:                  ; was: loc_20242
                move.w  d0,(a0)+
                dbf     d7,Results_ClearStageCompletionTimesLoop
                rts
; End of function Results_ClearStageCompletionTimes
