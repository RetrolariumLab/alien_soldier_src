; RAM object pointers for Missiray's eight linked segments
Boss_MissiraySegmentObjectPointers: dc.w    $C680, $C6E0, $C740, $C7A0, $C800, $C860, $C8C0, $C920  ; was: word_537A8
                                        ; Boss_MissirayArmRandomSegment+A   o

; Main boss handler
Boss_MissirayMain:                                      ; was: sub_537B8
                tst.w   4(a5)
                beq.w   Boss_MissirayDispatchState
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$4C(a5)
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_MissirayUpdateLinkedSegmentPositions
                btst    #1,(BossColorEffectFlags).w
                bne.w   Boss_MissirayUpdateVScrollBuffer
                tst.w   (BossHealth).w
                bne.s   Boss_MissirayUpdateLinkedSegmentPositions
                move.b  #2,(BossColorEffectFlags).w
                move.w  #$1A,4(a5)
                bset    #0,(StageTimerPauseFlag).w
Boss_MissirayUpdateLinkedSegmentPositions:              ; was: loc_537FC
                                        ; Boss_MissirayMain+30   j
                move.w  #7,d7
                lea     $60(a5),a0
                move.w  $4E(a5),d0
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_MissirayUseNegativeSegmentSpacing
                addq.w  #8,d0
                bra.s   Boss_MissirayApplySegmentSpacingLoop
; ---------------------------------------------------------------------------
Boss_MissirayUseNegativeSegmentSpacing:                 ; was: loc_53812
                subq.w  #8,d0
Boss_MissirayApplySegmentSpacingLoop:                   ; was: loc_53814
                                        ; Boss_MissirayMain+6A   j
                move.w  $4C(a0),$14(a0)
                add.w   d0,$14(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayApplySegmentSpacingLoop
Boss_MissirayUpdateVScrollBuffer:                       ; was: loc_53826
                movea.l #VScrollPlaneBColumn0,a1
                move.w  $14(a5),d1
                move.w  #3,d7
                lea     $60(a5),a0
Boss_MissirayUpdateFirstOffsetGroupLoop:                ; was: loc_53838
                move.w  (SharedScratchLong2).w,d0
                sub.w   $14(a0),d0
                cmpi.w  #$FF40,d0
                blt.s   Boss_MissirayAdvanceFirstOffsetGroup
                cmpi.w  #$30,d0                         ; '0'
                bgt.s   Boss_MissirayAdvanceFirstOffsetGroup
                move.w  d0,(a1)
                move.w  d0,4(a1)
Boss_MissirayAdvanceFirstOffsetGroup:                   ; was: loc_53852
                                        ; Boss_MissirayMain+92   j
                lea     8(a1),a1
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayUpdateFirstOffsetGroupLoop
                move.w  (SharedScratchLong1+2).w,d0
                sub.w   $14(a5),d0
                cmpi.w  #$FF20,d0
                blt.s   Boss_MissirayBeginSecondOffsetGroup
                cmpi.w  #$30,d0                         ; '0'
                bgt.s   Boss_MissirayBeginSecondOffsetGroup
                move.w  d0,(a1)
                move.w  d0,4(a1)
                move.w  d0,8(a1)
                move.w  d0,$C(a1)
Boss_MissirayBeginSecondOffsetGroup:                    ; was: loc_53880
                                        ; Boss_MissirayMain+B8   j
                lea     $10(a1),a1
                move.w  #3,d7
Boss_MissirayUpdateSecondOffsetGroupLoop:               ; was: loc_53888
                move.w  (SharedScratchLong2).w,d0
                sub.w   $14(a0),d0
                cmpi.w  #$FF40,d0
                blt.s   Boss_MissirayAdvanceSecondOffsetGroup
                cmpi.w  #$30,d0                         ; '0'
                bgt.s   Boss_MissirayAdvanceSecondOffsetGroup
                move.w  d0,(a1)
                move.w  d0,4(a1)
Boss_MissirayAdvanceSecondOffsetGroup:                  ; was: loc_538A2
                                        ; Boss_MissirayMain+E2   j
                lea     8(a1),a1
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayUpdateSecondOffsetGroupLoop
Boss_MissirayDispatchState:                             ; was: loc_538AE
                move.w  4(a5),d0
                lea     Boss_MissirayStateTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayMain
; ---------------------------------------------------------------------------
Boss_MissirayStateTable:    dc.w    Boss_MissirayInitialize-*  ; was: off_538BA
                dc.w    Boss_MissirayWaitForTransferAndQueueIndexedRowSet00-*
                dc.w    Boss_MissirayWaitForTransferAndQueueIndexedRowSet03-*
                dc.w    Boss_MissirayWaitForTransferAndLoadTileSet03-*
                dc.w    Boss_MissirayRaiseAndQueueIndexedRowSet06-*
                dc.w    Boss_MissirayFinishRiseAndInitializeCounters-*
                dc.w    Boss_MissirayActivateLinkedSegments-*
                dc.w    Boss_MissirayWaitForSegmentsReady-*
                dc.w    Boss_MissirayStartBossMessage-*
                dc.w    Boss_MissirayWaitForBossMessage-*
                dc.w    Boss_MissirayInitializeAttackCycle-*
                dc.w    Boss_MissirayRunSelectedAttack-*
                dc.w    Boss_MissirayAdvanceAttackSequence-*
                dc.w    Boss_MissirayBeginDefeat-*
                dc.w    Boss_MissiraySpawnDefeatDebrisAndWait-*
                dc.w    Boss_MissirayAccelerateDefeatMotion-*
                dc.w    Boss_MissirayAdvanceDefeatPaletteFade-*
                dc.w    Boss_MissirayWaitAndLoadDefeatTileSet00-*
                dc.w    Boss_MissirayWaitAndLoadDefeatTileSet01-*
                dc.w    Boss_MissirayWaitAndLoadDefeatTileSet02-*
                dc.w    Boss_MissirayFinishDefeatPaletteFade-*
                dc.w    Boss_MissirayRemoveAfterDefeat-*

; Initializes the boss, eight linked segment objects, and their shared V-scroll data
Boss_MissirayInitialize:                                ; was: sub_538E6
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_MissirayInitializeReturn
                addq.w  #2,4(a5)
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #$3D0,d0
                move.w  #$3E0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.b  #2,(PlaneBScrollModeFlags).w
                clr.w   (SharedScratchLong1).w
                move.w  #$A0,(SharedScratchLong1+2).w
                move.w  #$B8,(SharedScratchLong2).w
                move.w  #$80,(SharedScratchLong3).w
                move.w  #$13,d7
                lea     (VScrollPlaneBColumn0).w,a0
                move.w  #$FF40,d0
                move.w  d0,(a0)
                move.w  d0,4(a0)
                move.w  d0,8(a0)
                move.w  d0,$C(a0)
                move.w  d0,$10(a0)
                move.w  d0,$14(a0)
                move.w  d0,$18(a0)
                move.w  d0,$1C(a0)
                move.w  d0,$20(a0)
                move.w  d0,$24(a0)
                move.w  d0,$28(a0)
                move.w  d0,$2C(a0)
                move.w  d0,$30(a0)
                move.w  d0,$34(a0)
                move.w  d0,$38(a0)
                move.w  d0,$3C(a0)
                move.w  d0,$40(a0)
                move.w  d0,$44(a0)
                move.w  d0,$48(a0)
                move.w  d0,$4C(a0)
                move.w  #$120,$10(a5)
                move.w  #$170,$14(a5)
                move.w  $14(a5),$4E(a5)
                move.w  #$C80,2(a5)
                move.b  #$D0,$21(a5)
                move.b  #$88,$23(a5)
                move.w  #$C8,$26(a5)
                move.l  #$F40CE41C,$2C(a5)
                move.l  #$F010E41C,$28(a5)
                move.w  #$14,$24(a5)
                move.w  #7,d7
                moveq   #0,d6
                lea     $60(a5),a0
                lea     (VScrollPlaneBColumn0).w,a1
Boss_MissirayInitializeSegmentsLoop:                    ; was: loc_539CA
                move.w  #$3D4,(a0)
                move.w  #$C80,2(a0)
                move.b  #$80,$21(a0)
                move.b  #$10,$23(a0)
                move.l  #$FE02F40C,$2C(a0)
                move.l  #$E818E818,$28(a0)
                move.w  #$64,$26(a0)                    ; 'd'
                move.w  $14(a5),$14(a0)
                move.w  $10(a5),d0
                add.w   Boss_MissirayInitialSegmentXOffsets(pc,d6.w),d0
                move.w  d0,$10(a0)
                move.w  Boss_MissirayInitialSegmentYOffsets(pc,d6.w),$4C(a0)
                addq.w  #2,d6
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayInitializeSegmentsLoop
Boss_MissirayInitializeReturn:                          ; was: locret_53A18
                rts
; End of function Boss_MissirayInitialize
; ---------------------------------------------------------------------------
Boss_MissirayInitialSegmentXOffsets:    dc.w    $FF70, $FF90, $FFB0, $FFD0, $30, $50, $70, $90  ; was: word_53A1A
Boss_MissirayInitialSegmentYOffsets:    dc.w    $40, $30, $20, $10, $10, $20, $30, $40  ; was: word_53A2A

; Starts direct tile transfer set 00
Boss_MissirayLoadTileTransferSet00:                     ; was: sub_53A3A
                lea     Boss_MissirayTileTransferSet00Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Boss_MissirayLoadTileTransferSet00
; ---------------------------------------------------------------------------
Boss_MissirayTileTransferSet00Descriptor:   dc.w    $6020, $2000, $102, $6162, $6566, $696A  ; was: word_53A46

; Starts direct tile transfer set 01
Boss_MissirayLoadTileTransferSet01:                     ; was: sub_53A52
                lea     Boss_MissirayTileTransferSet01Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Boss_MissirayLoadTileTransferSet01
; ---------------------------------------------------------------------------
Boss_MissirayTileTransferSet01Descriptor:   dc.w    $6020, $2000, $102, $6D6E, $7172, $7576  ; was: word_53A5E

; Starts direct tile transfer set 02
Boss_MissirayLoadTileTransferSet02:                     ; was: sub_53A6A
                lea     Boss_MissirayTileTransferSet02Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Boss_MissirayLoadTileTransferSet02
; ---------------------------------------------------------------------------
Boss_MissirayTileTransferSet02Descriptor:   dc.w    $6020, $2000, $102, 0, 0, 0  ; was: word_53A76

; Waits for the previous transfer, then queues indexed-row set 00
Boss_MissirayWaitForTransferAndQueueIndexedRowSet00:    ; was: sub_53A82
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayIndexedRowSet00WaitReturn
                addq.w  #2,4(a5)
                bsr.s   Boss_MissirayQueueIndexedRowSet00
Boss_MissirayIndexedRowSet00WaitReturn:                 ; was: locret_53A8E
                rts
; End of function Boss_MissirayWaitForTransferAndQueueIndexedRowSet00
; Queues indexed-row transfer set 00
Boss_MissirayQueueIndexedRowSet00:                      ; was: sub_53A90
                                        ; Boss_MissirayWaitThenQueuePrimaryIndexedRowSet+E   j
                lea     Boss_MissirayIndexedRowSet00Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_MissirayQueueIndexedRowSet00
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet00Descriptor: dc.w    $6200, $2000, $301, $6060, $6060, $6464, $6464  ; was: word_53A9C

; Queues indexed-row transfer set 01
Boss_MissirayQueueIndexedRowSet01:                      ; was: sub_53AAA
                lea     Boss_MissirayIndexedRowSet01Descriptor(pc),a0
                nop
; End of function Boss_MissirayQueueIndexedRowSet01
; Shared fall-through tail for indexed-row set 01
Boss_MissirayJumpToIndexedRowQueue:
                jmp     Tilemap_QueueIndexedRows        ; was: sub_53AB0
; End of function Boss_MissirayJumpToIndexedRowQueue
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet01Descriptor: dc.w    $6200, $2000, $301, $6868, $6868, $6C6C, $6C6C  ; was: word_53AB6

; Queues indexed-row transfer set 02
Boss_MissirayQueueIndexedRowSet02:                      ; was: sub_53AC4
                lea     Boss_MissirayIndexedRowSet02Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_MissirayQueueIndexedRowSet02
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet02Descriptor: dc.w    $6200, $2000, $301, 0, 0, 0, 0  ; was: word_53AD0

; Waits for the previous transfer, then queues indexed-row set 03
Boss_MissirayWaitForTransferAndQueueIndexedRowSet03:    ; was: sub_53ADE
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayIndexedRowSet03WaitReturn
                addq.w  #2,4(a5)
                bsr.s   Boss_MissirayQueueIndexedRowSet03
Boss_MissirayIndexedRowSet03WaitReturn:                 ; was: locret_53AEA
                rts
; End of function Boss_MissirayWaitForTransferAndQueueIndexedRowSet03
; Queues indexed-row transfer set 03
Boss_MissirayQueueIndexedRowSet03:                      ; was: sub_53AEC
                                        ; Boss_MissirayWaitThenQueuePrimaryFinalIndexedRowSet+E   p
                lea     Boss_MissirayIndexedRowSet03Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_MissirayQueueIndexedRowSet03
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet03Descriptor: dc.w    $6230, $2000, $301, $6363, $6363, $6767, $6767  ; was: word_53AF8

; Queues indexed-row transfer set 04
Boss_MissirayQueueIndexedRowSet04:                      ; was: sub_53B06
                lea     Boss_MissirayIndexedRowSet04Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_MissirayQueueIndexedRowSet04
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet04Descriptor: dc.w    $6230, $2000, $301, $6B6B, $6B6B, $6F6F, $6F6F  ; was: word_53B12

; Queues indexed-row transfer set 05
Boss_MissirayQueueIndexedRowSet05:                      ; was: sub_53B20
                lea     Boss_MissirayIndexedRowSet05Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_MissirayQueueIndexedRowSet05
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet05Descriptor: dc.w    $6230, $2000, $301, 0, 0, 0, 0  ; was: word_53B2C

; Waits for the previous transfer, then loads direct tile set 03
Boss_MissirayWaitForTransferAndLoadTileSet03:           ; was: sub_53B3A
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayWaitForTileSet03Return
                addq.w  #2,4(a5)
                lea     Boss_MissirayTileTransferSet03Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; ---------------------------------------------------------------------------
Boss_MissirayTileTransferSet03Descriptor:   dc.w    $6020, $2000, $101, $6162, $6566  ; was: word_53B50
; ---------------------------------------------------------------------------
Boss_MissirayWaitForTileSet03Return:                    ; was: locret_53B5A
                rts
; End of function Boss_MissirayWaitForTransferAndLoadTileSet03
; Raises the boss and queues indexed-row set 06 at the first Y threshold
Boss_MissirayRaiseAndQueueIndexedRowSet06:              ; was: sub_53B5C
                subq.w  #1,$14(a5)
                move.w  $14(a5),$4E(a5)
                cmpi.w  #$178,$14(a5)
                bgt.s   Boss_MissirayRaiseAndQueueIndexedRowSet06Return
                addq.w  #2,4(a5)
                lea     Boss_MissirayIndexedRowSet06Descriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; ---------------------------------------------------------------------------
Boss_MissirayIndexedRowSet06Descriptor: dc.w    $6420, $2000, $100, $696A  ; was: word_53B7E
; ---------------------------------------------------------------------------
Boss_MissirayRaiseAndQueueIndexedRowSet06Return:        ; was: locret_53B86
                rts
; End of function Boss_MissirayRaiseAndQueueIndexedRowSet06
; Finishes the rise at Y=$0150 and initializes the next-state counters
Boss_MissirayFinishRiseAndInitializeCounters:           ; was: sub_53B88
                subq.w  #1,$14(a5)
                move.w  $14(a5),$4E(a5)
                cmpi.w  #$150,$14(a5)
                bhi.s   Boss_MissirayFinishRiseReturn
                move.w  #$150,$14(a5)
                move.w  #4,$4A(a5)
                move.w  #1,$48(a5)
                addq.w  #2,4(a5)
Boss_MissirayFinishRiseReturn:                          ; was: locret_53BB0
                rts
; End of function Boss_MissirayFinishRiseAndInitializeCounters
; Activates all eight linked segment objects
Boss_MissirayActivateLinkedSegments:                    ; was: sub_53BB2
                move.w  #7,d7
                lea     $60(a5),a0
Boss_MissirayActivateLinkedSegmentsLoop:                ; was: loc_53BBA
                clr.w   $4E(a0)
                move.b  #1,$50(a0)
                addq.w  #2,4(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayActivateLinkedSegmentsLoop
                addq.w  #2,4(a5)
                rts
; End of function Boss_MissirayActivateLinkedSegments
; Applies timed separation to symmetric segment pairs; no live static caller is known
Boss_MissirayUpdateTimedSegmentPairSeparation:
                subq.w  #1,$48(a5)                      ; was: sub_53BD6
                bne.s   Boss_MissirayTimedSegmentSeparationReturn
                subq.w  #1,$4A(a5)
                bmi.s   Boss_MissirayFinishTimedSegmentSeparation
                move.w  $4A(a5),d5
                lsl.w   #2,d5
                move.w  Boss_MissiraySegmentPairOrder(pc,d5.w),d0
                move.w  Boss_MissiraySegmentPairOrder+2(pc,d5.w),d1
                lea     Boss_MissiraySegmentObjectPointers(pc),a1
                movea.w (a1,d0.w),a2
                movea.w (a1,d1.w),a3
                move.w  $14(a5),d0
                move.w  $4E(a5),d1
                sub.w   d1,d0
                move.w  d0,$4E(a2)
                move.b  #1,$50(a2)
                addq.w  #2,4(a2)
                move.w  d0,$4E(a3)
                move.b  #1,$50(a3)
                addq.w  #2,4(a3)
                move.w  #8,$48(a5)
                rts
; ---------------------------------------------------------------------------
Boss_MissirayFinishTimedSegmentSeparation:              ; was: loc_53C2A
                addq.w  #2,4(a5)
Boss_MissirayTimedSegmentSeparationReturn:              ; was: locret_53C2E
                rts
; End of function Boss_MissirayUpdateTimedSegmentPairSeparation
; ---------------------------------------------------------------------------
Boss_MissiraySegmentPairOrder:  dc.w    0, $E, 2, $C, 4, $A, 6, 8  ; was: word_53C30
                                        ; Boss_MissirayUpdateTimedSegmentPairSeparation+16   r

; Waits until all linked segment ready flags clear
Boss_MissirayWaitForSegmentsReady:                      ; was: sub_53C40
                move.w  #7,d7
                lea     $60(a5),a0
Boss_MissirayScanSegmentReadyFlagsLoop:                 ; was: loc_53C48
                tst.b   $52(a0)
                bne.s   Boss_MissirayWaitForSegmentsReadyReturn
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayScanSegmentReadyFlagsLoop
                move.w  #7,d7
                lea     $60(a5),a0
Boss_MissirayClearSegmentOffsetsLoop:                   ; was: loc_53C5E
                clr.w   $4C(a0)
                clr.w   $4E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayClearSegmentOffsetsLoop
                move.w  $14(a5),$4E(a5)
                addq.w  #2,4(a5)
Boss_MissirayWaitForSegmentsReadyReturn:                ; was: locret_53C78
                rts
; End of function Boss_MissirayWaitForSegmentsReady
; Start the boss-message sequence
Boss_MissirayStartBossMessage:                          ; was: sub_53C7A
                move.w  #3,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
                rts
; End of function Boss_MissirayStartBossMessage
; Wait for the boss-message gate before advancing to attack setup
Boss_MissirayWaitForBossMessage:                        ; was: sub_53C8A
                tst.w   (MessageSequenceState).w
                bne.s   Boss_MissirayWaitForBossMessageReturn
                clr.b   (BossColorEffectFlags).w
                addq.w  #2,4(a5)
Boss_MissirayWaitForBossMessageReturn:                  ; was: locret_53C98
                rts
; End of function Boss_MissirayWaitForBossMessage
; Initializes the attack substate and attack-sequence selector
Boss_MissirayInitializeAttackCycle:                     ; was: sub_53C9A
                clr.w   (SharedScratchLong0).w
                addq.w  #2,4(a5)
                move.w  #0,(SharedScratchLong0+2).w
                rts
; End of function Boss_MissirayInitializeAttackCycle
; Runs the proximity check and the selected attack-sequence entry
Boss_MissirayRunSelectedAttack:                         ; was: sub_53CAA
                bsr.w   Boss_MissirayTrySpawnProximityShotPair
                move.w  (SharedScratchLong0+2).w,d0
                lea     Boss_MissirayAttackSequenceTable(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayRunSelectedAttack
; ---------------------------------------------------------------------------
Boss_MissirayAttackSequenceTable:   dc.w    Boss_MissirayRunAttackAndCyclePalette-*  ; was: off_53CBA
                dc.w    Boss_MissiraySegmentPairAttackDispatcher-*
                dc.w    Boss_MissirayAllSegmentAttackDispatcher-*
                dc.w    Boss_MissiraySequentialSegmentAttackDispatcher-*
                dc.w    Boss_MissirayAlternateModeTransitionDispatcher-*
                dc.w    Boss_MissirayRunAttackAndCyclePalette-*
                dc.w    Boss_MissirayRunAttackAndCyclePalette-*
                dc.w    Boss_MissiraySequentialSegmentAttackDispatcher-*
                dc.w    Boss_MissirayPrimaryModeTransitionDispatcher-*

; Advances and wraps the attack-sequence selector
Boss_MissirayAdvanceAttackSequence:                     ; was: sub_53CCC
                subq.w  #2,4(a5)
                addq.w  #2,(SharedScratchLong0+2).w
                cmpi.w  #$12,(SharedScratchLong0+2).w
                bne.s   Boss_MissirayAdvanceAttackSequenceReturn
                clr.w   (SharedScratchLong0+2).w
Boss_MissirayAdvanceAttackSequenceReturn:               ; was: locret_53CE0
                rts
; End of function Boss_MissirayAdvanceAttackSequence
; Begins the boss and linked-segment defeat sequence
Boss_MissirayBeginDefeat:                               ; was: sub_53CE2
                clr.b   $21(a5)
                move.w  #7,d7
                moveq   #0,d6
                lea     $60(a5),a0
Boss_MissirayBeginSegmentDefeatLoop:                    ; was: loc_53CF0
                clr.b   $21(a0)
                clr.w   4(a0)
                move.b  #2,$50(a0)
                move.w  Boss_MissiraySegmentDefeatTimers(pc,d6.w),$48(a0)
                addq.w  #2,d6
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayBeginSegmentDefeatLoop
                addq.w  #2,4(a5)
                move.w  #$50,$48(a5)                    ; 'P'
                rts
; End of function Boss_MissirayBeginDefeat
; ---------------------------------------------------------------------------
Boss_MissiraySegmentDefeatTimers:   dc.w    $40, $30, $20, $10, $10, $20, $30, $40  ; was: word_53D1A

; Spawns defeat debris and waits before starting vertical motion
Boss_MissiraySpawnDefeatDebrisAndWait:                  ; was: sub_53D2A
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                subq.w  #1,$48(a5)
                bne.s   Boss_MissirayDefeatDebrisWaitReturn
                addq.w  #2,4(a5)
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_MissirayDefeatDebrisWaitReturn
                tst.w   (SharedScratchLong2+2).w
                bne.s   Boss_MissirayDefeatDebrisWaitReturn
                move.l  #$FFFE0000,$1C(a5)
Boss_MissirayDefeatDebrisWaitReturn:                    ; was: locret_53D4E
                                        ; Boss_MissiraySpawnDefeatDebrisAndWait+14   j
                rts
; End of function Boss_MissiraySpawnDefeatDebrisAndWait
; Accelerates the defeat motion until its threshold
Boss_MissirayAccelerateDefeatMotion:                    ; was: sub_53D50
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                addi.l  #$800,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Boss_MissirayAccelerateDefeatMotionReturn
                cmpi.l  #$10000,$1C(a5)
                blt.s   Boss_MissirayAccelerateDefeatMotionReturn
                clr.w   $48(a5)
                addq.w  #2,4(a5)
Boss_MissirayAccelerateDefeatMotionReturn:              ; was: locret_53D78
                                        ; Boss_MissirayAccelerateDefeatMotion+1E   j
                rts
; End of function Boss_MissirayAccelerateDefeatMotion
; Advances the frame-gated defeat palette fade
Boss_MissirayAdvanceDefeatPaletteFade:                  ; was: sub_53D7A
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                bsr.s   Boss_MissirayApplyDefeatPaletteFade
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_MissirayAdvanceDefeatPaletteFadeReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_MissirayAdvanceDefeatPaletteFadeReturn
                addq.w  #1,$48(a5)
                cmpi.w  #$F,$48(a5)
                bne.s   Boss_MissirayAdvanceDefeatPaletteFadeReturn
                move.w  #$3D0,d0
                move.w  #$3E0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #4,$4A(a5)
                addq.w  #2,4(a5)
Boss_MissirayAdvanceDefeatPaletteFadeReturn:            ; was: locret_53DB6
                                        ; Boss_MissirayAdvanceDefeatPaletteFade+16   j
                rts
; End of function Boss_MissirayAdvanceDefeatPaletteFade
; Applies the current defeat fade step to the active palette
Boss_MissirayApplyDefeatPaletteFade:                    ; was: sub_53DB8
                                        ; sub_53DD4   p
                move.w  $48(a5),d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                rts
; End of function Boss_MissirayApplyDefeatPaletteFade
; Waits, then starts the first defeat tile replacement
Boss_MissirayWaitAndLoadDefeatTileSet00:                ; was: sub_53DD4
                bsr.w   Boss_MissirayApplyDefeatPaletteFade
                subq.w  #1,$4A(a5)
                bne.s   Boss_MissirayWaitAndLoadDefeatTileSet00Return
                bsr.w   Boss_MissirayLoadTileTransferSet02
                addq.w  #2,4(a5)
Boss_MissirayWaitAndLoadDefeatTileSet00Return:          ; was: locret_53DE6
                rts
; End of function Boss_MissirayWaitAndLoadDefeatTileSet00
; Waits for transfer completion, then starts the second defeat tile replacement
Boss_MissirayWaitAndLoadDefeatTileSet01:                ; was: sub_53DE8
                bsr.w   Boss_MissirayApplyDefeatPaletteFade
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayWaitAndLoadDefeatTileSet01Return
                bsr.w   Boss_MissirayQueueIndexedRowSet02
                addq.w  #2,4(a5)
Boss_MissirayWaitAndLoadDefeatTileSet01Return:          ; was: locret_53DFA
                rts
; End of function Boss_MissirayWaitAndLoadDefeatTileSet01
; Waits for transfer completion, then starts the third defeat tile replacement
Boss_MissirayWaitAndLoadDefeatTileSet02:                ; was: sub_53DFC
                bsr.w   Boss_MissirayApplyDefeatPaletteFade
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayWaitAndLoadDefeatTileSet02Return
                bsr.w   Boss_MissirayQueueIndexedRowSet05
                addq.w  #2,4(a5)
Boss_MissirayWaitAndLoadDefeatTileSet02Return:          ; was: locret_53E0E
                rts
; End of function Boss_MissirayWaitAndLoadDefeatTileSet02
; Finishes the frame-gated defeat palette fade
Boss_MissirayFinishDefeatPaletteFade:                   ; was: sub_53E10
                bsr.s   Boss_MissirayApplyDefeatPaletteFade
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_MissirayFinishDefeatPaletteFadeReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_MissirayFinishDefeatPaletteFadeReturn
                subq.w  #1,$48(a5)
                tst.w   $48(a5)
                bne.s   Boss_MissirayFinishDefeatPaletteFadeReturn
                addq.w  #2,4(a5)
Boss_MissirayFinishDefeatPaletteFadeReturn:             ; was: locret_53E30
                                        ; Boss_MissirayFinishDefeatPaletteFade+10   j
                rts
; End of function Boss_MissirayFinishDefeatPaletteFade
; Removes the boss object after defeat
Boss_MissirayRemoveAfterDefeat:                         ; was: sub_53E32
                move.w  #$1000,2(a5)
                clr.w   (a5)
                rts
; End of function Boss_MissirayRemoveAfterDefeat
; Completes an attack and returns control to sequence selection
Boss_MissirayFinishAttack:                              ; was: sub_53E3C
                                        ; Boss_MissirayFinishPairAttackAfterAllocationFailure   j
                clr.w   (SharedScratchLong0).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_MissirayFinishAttack
; Runs the selected attack substate and conditionally cycles one palette color
Boss_MissirayRunAttackAndCyclePalette:                  ; was: sub_53E46
                                        ; ROM:00053CC4   o
                bsr.s   Boss_MissirayRandomSegmentAttackDispatcher
                tst.w   (SharedScratchLong1).w
                beq.s   Boss_MissirayRunAttackAndCyclePaletteReturn
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                add.w   d0,d0
                move.w  Boss_MissirayAttackPaletteCycleColors(pc,d0.w),(PaletteActiveColor63).w
Boss_MissirayRunAttackAndCyclePaletteReturn:            ; was: locret_53E5E
                rts
; End of function Boss_MissirayRunAttackAndCyclePalette
; ---------------------------------------------------------------------------
Boss_MissirayAttackPaletteCycleColors:  binclude "data/palettes/053E60.bin"  ; was: word_53E60
