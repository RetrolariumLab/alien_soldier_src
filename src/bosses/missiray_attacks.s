; Dispatches the repeated single-projectile attack through a random segment
Boss_MissirayRandomSegmentAttackDispatcher:             ; was: sub_53E68
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_MissirayRandomSegmentAttackStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayRandomSegmentAttackDispatcher
; ---------------------------------------------------------------------------
Boss_MissirayRandomSegmentAttackStates: dc.w    Boss_MissirayPrepareRandomSegmentAttack-*  ; was: off_53E74
                dc.w    Boss_MissirayAllocateRandomSegmentProjectile-*
                dc.w    Boss_MissirayArmRandomSegment-*
                dc.w    Boss_MissirayWaitAndRepeatRandomSegmentAttack-*

; Waits until all eight linked segments are idle and selects the repeat count
Boss_MissirayPrepareRandomSegmentAttack:                ; was: sub_53E7C
                move.w  #7,d7
                lea     $60(a5),a0
                movea.w #(SharedScratchLong5-M68K_RAM),a1
Boss_MissirayCheckNextReadySegment:                     ; was: loc_53E88
                tst.b   $52(a0)
                bne.s   Boss_MissirayPrepareRandomSegmentAttackReturn
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayCheckNextReadySegment
                addq.w  #2,(SharedScratchLong0).w
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_MissiraySetAlternateShotRepeatCount
                move.w  #8,$4A(a5)
                rts
; ---------------------------------------------------------------------------
Boss_MissiraySetAlternateShotRepeatCount:               ; was: loc_53EA8
                tst.w   (DifficultyMode).w
                bne.s   Boss_MissiraySetExtendedShotRepeatCount
                move.w  #4,$4A(a5)
                rts
; ---------------------------------------------------------------------------
Boss_MissiraySetExtendedShotRepeatCount:                ; was: loc_53EB6
                move.w  #8,$4A(a5)
Boss_MissirayPrepareRandomSegmentAttackReturn:          ; was: locret_53EBC
                rts
; End of function Boss_MissirayPrepareRandomSegmentAttack
; Allocates the projectile record used by the next randomly selected segment
Boss_MissirayAllocateRandomSegmentProjectile:           ; was: sub_53EBE
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_MissiraySkipFailedRandomSegmentShot
                move.w  #$10,(a0)
                move.w  a0,(SharedScratchLong5).w
                addq.w  #2,(SharedScratchLong0).w
                rts
; ---------------------------------------------------------------------------
Boss_MissiraySkipFailedRandomSegmentShot:               ; was: loc_53ED4
                addq.w  #4,(SharedScratchLong0).w
                move.w  #8,$48(a5)
                rts
; End of function Boss_MissirayAllocateRandomSegmentProjectile
; Selects an idle segment and arms it with the allocated projectile
Boss_MissirayArmRandomSegment:                          ; was: sub_53EE0
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                add.w   d0,d0
                lea     Boss_MissiraySegmentObjectPointers(pc),a2
                movea.w (a2,d0.w),a0
                tst.b   $52(a0)
                bne.s   Boss_MissirayArmRandomSegmentReturn
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_MissirayConfigureAlternateSegmentShot
                move.b  #0,$51(a0)
                clr.w   $48(a0)
                move.w  #$20,$48(a5)                    ; ' '
                bra.s   Boss_MissirayCommitRandomSegmentShot
; ---------------------------------------------------------------------------
Boss_MissirayConfigureAlternateSegmentShot:             ; was: loc_53F10
                move.b  #1,$51(a0)
                clr.w   $48(a0)
                tst.w   (DifficultyMode).w
                bne.s   Boss_MissirayUseShortAlternateShotDelay
                move.w  #$60,$48(a5)                    ; '`'
                bra.s   Boss_MissirayCommitRandomSegmentShot
; ---------------------------------------------------------------------------
Boss_MissirayUseShortAlternateShotDelay:                ; was: loc_53F28
                move.w  #$30,$48(a5)                    ; '0'
Boss_MissirayCommitRandomSegmentShot:                   ; was: loc_53F2E
                                        ; Boss_MissirayArmRandomSegment+46   j
                move.b  #0,$50(a0)
                move.w  (SharedScratchLong5).w,$54(a0)
                addq.w  #2,4(a0)
                addq.w  #2,(SharedScratchLong0).w
Boss_MissirayArmRandomSegmentReturn:                    ; was: locret_53F42
                rts
; End of function Boss_MissirayArmRandomSegment
; Waits between random-segment shots and repeats until the counter expires
Boss_MissirayWaitAndRepeatRandomSegmentAttack:          ; was: sub_53F44
                subq.w  #1,$48(a5)
                bne.s   Boss_MissirayRandomSegmentAttackDelayReturn
                subq.w  #1,$4A(a5)
                beq.w   Boss_MissirayFinishRandomSegmentAttack
                subq.w  #4,(SharedScratchLong0).w
Boss_MissirayRandomSegmentAttackDelayReturn:            ; was: locret_53F56
                rts
; ---------------------------------------------------------------------------
Boss_MissirayFinishRandomSegmentAttack:                 ; was: loc_53F58
                bra.w   Boss_MissirayFinishAttack
; End of function Boss_MissirayWaitAndRepeatRandomSegmentAttack
; Dispatches the attack that activates four ordered pairs of segments
Boss_MissiraySegmentPairAttackDispatcher:               ; was: sub_53F5C
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_MissiraySegmentPairAttackStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissiraySegmentPairAttackDispatcher
; ---------------------------------------------------------------------------
Boss_MissiraySegmentPairAttackStates:   dc.w    Boss_MissirayInitializeSegmentPairAttack-*  ; was: off_53F68
                dc.w    Boss_MissirayAllocatePairAttackProjectiles-*
                dc.w    Boss_MissirayActivateNextSegmentPair-*
                dc.w    Boss_MissirayWaitAndRepeatSegmentPairAttack-*

; Initializes the four-pair countdown
Boss_MissirayInitializeSegmentPairAttack:               ; was: sub_53F70
                move.w  #3,$4A(a5)
                addq.w  #2,(SharedScratchLong0).w
; Allocates the eight projectile records consumed by the four segment pairs
Boss_MissirayAllocatePairAttackProjectiles:             ; was: loc_53F7A
                bsr.w   Boss_MissirayAllocateSegmentProjectileSet
                bne.s   Boss_MissirayFinishPairAttackAfterAllocationFailure
                addq.w  #2,(SharedScratchLong0).w
                rts
; ---------------------------------------------------------------------------
Boss_MissirayFinishPairAttackAfterAllocationFailure:    ; was: loc_53F86
                bra.w   Boss_MissirayFinishAttack
; End of function Boss_MissirayInitializeSegmentPairAttack
Boss_MissirayUnusedNoOp00:                              ; was: nullsub_123
                rts
; End of function Boss_MissirayUnusedNoOp00

; Activates the next pair when both selected segments are idle
Boss_MissirayActivateNextSegmentPair:                   ; was: sub_53F8C
                move.w  $4A(a5),d5
                lsl.w   #2,d5
                move.w  Boss_MissirayPairAttackActivationOrder(pc,d5.w),d0
                move.w  Boss_MissirayPairAttackActivationOrder+2(pc,d5.w),d1
                lea     Boss_MissiraySegmentObjectPointers(pc),a1
                movea.w (a1,d0.w),a2
                tst.b   $52(a2)
                bne.s   Boss_MissirayActivateSegmentPairReturn
                movea.w (a1,d1.w),a3
                tst.b   $52(a3)
                bne.s   Boss_MissirayActivateSegmentPairReturn
                lea     (SharedScratchLong5).w,a0
                move.b  #0,$50(a2)
                move.b  #0,$51(a2)
                clr.w   $48(a2)
                move.w  (a0,d5.w),$54(a2)
                addq.w  #2,4(a2)
                move.b  #0,$50(a3)
                move.b  #0,$51(a3)
                clr.w   $48(a3)
                move.w  2(a0,d5.w),$54(a3)
                addq.w  #2,4(a3)
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,(SharedScratchLong0).w
Boss_MissirayActivateSegmentPairReturn:                 ; was: locret_53FF4
                                        ; Boss_MissirayActivateNextSegmentPair+24   j
                rts
; End of function Boss_MissirayActivateNextSegmentPair
; ---------------------------------------------------------------------------
Boss_MissirayPairAttackActivationOrder: dc.w    0, 4, $A, $E, 2, 6, 8, $C  ; was: word_53FF6
                                        ; Boss_MissirayActivateNextSegmentPair+A   r

; Waits between pairs and repeats until all four pairs have been activated
Boss_MissirayWaitAndRepeatSegmentPairAttack:            ; was: sub_54006
                subq.w  #1,$48(a5)
                bne.s   Boss_MissiraySegmentPairDelayReturn
                subq.w  #1,$4A(a5)
                bmi.s   Boss_MissirayFinishSegmentPairAttack
                subq.w  #2,(SharedScratchLong0).w
Boss_MissiraySegmentPairDelayReturn:                    ; was: locret_54016
                rts
; ---------------------------------------------------------------------------
Boss_MissirayFinishSegmentPairAttack:                   ; was: loc_54018
                bra.w   Boss_MissirayFinishAttack
; End of function Boss_MissirayWaitAndRepeatSegmentPairAttack
Boss_MissirayUnusedNoOp01:                              ; was: nullsub_124
                rts
; End of function Boss_MissirayUnusedNoOp01

; Dispatches the attack that arms all eight segments with staggered delays
Boss_MissirayAllSegmentAttackDispatcher:                ; was: sub_5401E
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_MissirayAllSegmentAttackStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayAllSegmentAttackDispatcher
; ---------------------------------------------------------------------------
Boss_MissirayAllSegmentAttackStates:    dc.w    Boss_MissirayInitializeAllSegmentAttack-*  ; was: off_5402A
                dc.w    Boss_MissirayAllocateAllSegmentProjectiles-*
                dc.w    Boss_MissirayWaitForAllSegmentsReady-*
                dc.w    Boss_MissirayAssignAllSegmentActivationDelays-*
                dc.w    Boss_MissirayBeginAllSegmentAttackHold-*
                dc.w    Boss_MissirayWaitAllSegmentAttackHold-*
                dc.w    Boss_MissirayFinishOrRepeatAllSegmentAttack-*

; Initializes the all-segment attack
Boss_MissirayInitializeAllSegmentAttack:                ; was: sub_54038
                move.w  #1,$4A(a5)
                addq.w  #2,(SharedScratchLong0).w
; Allocates one projectile record for each linked segment
Boss_MissirayAllocateAllSegmentProjectiles:             ; was: loc_54042
                bsr.w   Boss_MissirayAllocateSegmentProjectileSet
                bne.s   Boss_MissiraySkipFailedAllSegmentAttack
                addq.w  #2,(SharedScratchLong0).w
                rts
; ---------------------------------------------------------------------------
Boss_MissiraySkipFailedAllSegmentAttack:                ; was: loc_5404E
                addi.w  #$A,(SharedScratchLong0).w
                rts
; End of function Boss_MissirayInitializeAllSegmentAttack
; Waits for all eight linked segments to become idle before proceeding
Boss_MissirayWaitForAllSegmentsReady:                   ; was: sub_54056
                move.w  #7,d7
                lea     $60(a5),a0
                movea.w #(SharedScratchLong5-M68K_RAM),a1
Boss_MissirayCheckNextAllSegmentReady:                  ; was: loc_54062
                tst.b   $52(a0)
                bne.s   Boss_MissirayWaitForAllSegmentsReadyReturn
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayCheckNextAllSegmentReady
                addq.w  #2,(SharedScratchLong0).w
Boss_MissirayWaitForAllSegmentsReadyReturn:             ; was: locret_54074
                rts
; End of function Boss_MissirayWaitForAllSegmentsReady
; Selects one of four delay patterns and arms all eight segments
Boss_MissirayAssignAllSegmentActivationDelays:          ; was: sub_54076
                movea.w #(SharedScratchLong5-M68K_RAM),a1
                lea     Boss_MissirayAllSegmentActivationDelayPatterns(pc),a2
                nop
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                lsl.w   #4,d0
                lea     (a2,d0.w),a2
                move.w  #7,d7
                moveq   #0,d6
                lea     $60(a5),a0
Boss_MissirayAssignNextSegmentActivationDelay:          ; was: loc_54098
                move.b  #0,$50(a0)
                move.b  #0,$51(a0)
                move.w  (a2,d6.w),$48(a0)
                move.w  (a1)+,$54(a0)
                addq.w  #2,4(a0)
                addq.w  #2,d6
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayAssignNextSegmentActivationDelay
                addq.w  #2,(SharedScratchLong0).w
                rts
; End of function Boss_MissirayAssignAllSegmentActivationDelays
; ---------------------------------------------------------------------------
Boss_MissirayAllSegmentActivationDelayPatterns: dc.w    0, $10, $20, $30, $40, $50, $60, $70, $70, $60, $50, $40, $30, $20, $10, 0  ; was: word_540C2
                dc.w    0, $20, $40, $60, $60, $40, $20, 0, $60, $40, $20, 0, 0, $20, $40, $60

; Starts the $80-frame hold after all segments have been armed
Boss_MissirayBeginAllSegmentAttackHold:                 ; was: sub_54102
                move.w  #$80,$48(a5)
                addq.w  #2,(SharedScratchLong0).w
                rts
; End of function Boss_MissirayBeginAllSegmentAttackHold
; Waits for the all-segment hold to expire
Boss_MissirayWaitAllSegmentAttackHold:                  ; was: sub_5410E
                subq.w  #1,$48(a5)
                bne.s   Boss_MissirayAllSegmentAttackHoldReturn
                addq.w  #2,(SharedScratchLong0).w
Boss_MissirayAllSegmentAttackHoldReturn:                ; was: locret_54118
                rts
; End of function Boss_MissirayWaitAllSegmentAttackHold
; Repeats from allocation while the repetition counter remains nonzero
Boss_MissirayFinishOrRepeatAllSegmentAttack:            ; was: sub_5411A
                subq.w  #1,$4A(a5)
                beq.w   Boss_MissirayFinishAttack
                move.w  #2,(SharedScratchLong0).w
                rts
; End of function Boss_MissirayFinishOrRepeatAllSegmentAttack
; Dispatches the shuffled-segment attack and its vertical boss movement
Boss_MissiraySequentialSegmentAttackDispatcher:         ; was: sub_5412A
                                        ; ROM:00053CC8   o
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_MissiraySequentialSegmentAttackStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissiraySequentialSegmentAttackDispatcher
; ---------------------------------------------------------------------------
Boss_MissiraySequentialSegmentAttackStates: dc.w    Boss_MissirayInitializeSequentialSegmentAttack-*  ; was: off_54136
                dc.w    Boss_MissirayFadeAndInitializeSegmentOrder-*
                dc.w    Boss_MissirayShuffleSegmentActivationOrder-*
                dc.w    Boss_MissirayActivateNextShuffledSegment-*
                dc.w    Boss_MissirayWaitBeforeNextShuffledSegment-*
                dc.w    Boss_MissirayMoveVerticallyAndResetSegmentOffsets-*
                dc.w    Boss_MissirayFinishSequentialSegmentAttack-*

; Enables the segment render flag and initializes the palette-fade direction
Boss_MissirayInitializeSequentialSegmentAttack:         ; was: sub_54144
                bset    #4,$23(a5)
                clr.w   (SharedScratchLong3+2).w
                move.w  #$8000,(SharedScratchLong4+2).w
                addq.w  #2,(SharedScratchLong0).w
; Advances the palette fade and then records all eight segment pointers
Boss_MissirayFadeAndInitializeSegmentOrder:             ; was: loc_54158
                bsr.w   Boss_MissirayApplyPaletteFadeStep
                addq.w  #1,(SharedScratchLong3+2).w
                cmpi.w  #$E,(SharedScratchLong3+2).w
                bne.w   Boss_MissiraySequentialSegmentFadeReturn
                lea     (SharedScratchLong5).w,a1
                move.w  #$C680,(a1)+
                move.w  #$C6E0,(a1)+
                move.w  #$C740,(a1)+
                move.w  #$C7A0,(a1)+
                move.w  #$C800,(a1)+
                move.w  #$C860,(a1)+
                move.w  #$C8C0,(a1)+
                move.w  #$C920,(a1)+
                addq.w  #2,(SharedScratchLong0).w
Boss_MissiraySequentialSegmentFadeReturn:               ; was: locret_54192
                rts
; End of function Boss_MissirayInitializeSequentialSegmentAttack
; Randomizes the order in which the eight linked segments are activated
Boss_MissirayShuffleSegmentActivationOrder:             ; was: sub_54194
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                lea     (SharedScratchLong5).w,a1
                move.w  #7,d6
Boss_MissirayShuffleSegmentActivationOuterLoop:         ; was: loc_541A0
                move.w  #7,d7
Boss_MissirayShuffleSegmentActivationInnerLoop:         ; was: loc_541A4
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #7,d0
                add.w   d0,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #7,d1
                add.w   d1,d1
                move.w  (a1,d0.w),d2
                move.w  (a1,d1.w),(a1,d0.w)
                move.w  d2,(a1,d1.w)
                dbf     d7,Boss_MissirayShuffleSegmentActivationInnerLoop
                dbf     d6,Boss_MissirayShuffleSegmentActivationOuterLoop
                addq.w  #2,(SharedScratchLong0).w
                clr.w   $4A(a5)
                tst.w   (SharedScratchLong1).w
                beq.s   Boss_MissirayConfigureModeZeroSequentialMotion
                move.w  #$B8,(SharedScratchLong2).w
                addi.w  #-$10,$4E(a5)
                move.w  #$B8,$50(a5)
                rts
; ---------------------------------------------------------------------------
Boss_MissirayConfigureModeZeroSequentialMotion:         ; was: loc_541F6
                move.w  #$C8,(SharedScratchLong2).w
                addi.w  #$10,$4E(a5)
                move.w  #$FF48,$50(a5)
                rts
; End of function Boss_MissirayShuffleSegmentActivationOrder
; Activates the next idle segment from the shuffled pointer array
Boss_MissirayActivateNextShuffledSegment:               ; was: sub_5420A
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                lea     (SharedScratchLong5).w,a1
                move.w  $4A(a5),d0
                movea.w (a1,d0.w),a0
                tst.b   $52(a0)
                bne.s   Boss_MissirayActivateShuffledSegmentReturn
                addq.w  #2,4(a0)
                move.b  #1,$50(a0)
                move.w  $50(a5),$4E(a0)
                move.w  #$18,$48(a5)
                addq.w  #2,(SharedScratchLong0).w
Boss_MissirayActivateShuffledSegmentReturn:             ; was: locret_5423A
                rts
; End of function Boss_MissirayActivateNextShuffledSegment
; Waits between activations and starts vertical movement after the eighth
Boss_MissirayWaitBeforeNextShuffledSegment:             ; was: sub_5423C
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                subq.w  #1,$48(a5)
                bne.s   Boss_MissiraySequentialSegmentDelayReturn
                addq.w  #2,$4A(a5)
                cmpi.w  #$10,$4A(a5)
                beq.s   Boss_MissirayBeginSequentialVerticalMotion
                subq.w  #2,(SharedScratchLong0).w
Boss_MissiraySequentialSegmentDelayReturn:              ; was: locret_54256
                rts
; ---------------------------------------------------------------------------
Boss_MissirayBeginSequentialVerticalMotion:             ; was: loc_54258
                move.w  #$50,$48(a5)                    ; 'P'
                addq.w  #2,(SharedScratchLong0).w
                move.b  #$57,d0                         ; 'W'
                jsr     (Sound_QueueSFXRequest).l
                btst    #7,$50(a5)
                bne.s   Boss_MissirayUseUpwardSequentialVelocity
                move.w  #2,(SharedScratchLong2+2).w
                rts
; ---------------------------------------------------------------------------
Boss_MissirayUseUpwardSequentialVelocity:               ; was: loc_5427C
                move.w  #$FFFE,(SharedScratchLong2+2).w
                rts
; End of function Boss_MissirayWaitBeforeNextShuffledSegment
; Moves the boss vertically, then clears every segment motion offset
Boss_MissirayMoveVerticallyAndResetSegmentOffsets:      ; was: sub_54284
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                move.w  (SharedScratchLong2+2).w,d0
                add.w   d0,$14(a5)
                subq.w  #1,$48(a5)
                bne.s   Boss_MissirayVerticalMotionReturn
                clr.w   (SharedScratchLong2+2).w
                addq.w  #2,(SharedScratchLong0).w
                move.w  $14(a5),$4E(a5)
                moveq   #0,d0
                move.w  #7,d7
                lea     $60(a5),a0
Boss_MissirayClearNextSegmentMotionOffset:              ; was: loc_542AE
                move.w  d0,$4C(a0)
                move.w  d0,$4E(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_MissirayClearNextSegmentMotionOffset
Boss_MissirayVerticalMotionReturn:                      ; was: locret_542BE
                rts
; End of function Boss_MissirayMoveVerticallyAndResetSegmentOffsets
; Clears the segment render flag and completes the sequential attack
Boss_MissirayFinishSequentialSegmentAttack:             ; was: sub_542C0
                bclr    #4,$23(a5)
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                bra.w   Boss_MissirayFinishAttack
; End of function Boss_MissirayFinishSequentialSegmentAttack
; Dispatches the graphics transition that restores mode zero
Boss_MissirayPrimaryModeTransitionDispatcher:           ; was: sub_542CE
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_MissirayPrimaryModeTransitionStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayPrimaryModeTransitionDispatcher
; ---------------------------------------------------------------------------
Boss_MissirayPrimaryModeTransitionStates:   dc.w    Boss_MissirayInitializePrimaryModeTransition-*  ; was: off_542DA
                dc.w    Boss_MissirayWaitThenLoadPrimaryTransferSet-*
                dc.w    Boss_MissirayWaitThenQueuePrimaryIndexedRowSet-*
                dc.w    Boss_MissirayWaitThenQueuePrimaryFinalIndexedRowSet-*
                dc.w    Boss_MissirayFadePrimaryModePalette-*

; Selects mode zero, its vertical target, and shared render fields
Boss_MissirayInitializePrimaryModeTransition:           ; was: sub_542E4
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                move.w  #0,(SharedScratchLong1).w
                move.w  #$A0,(SharedScratchLong1+2).w
                move.l  #$F40CE41C,$2C(a5)
                move.l  #$F010E41C,$28(a5)
                addq.w  #2,(SharedScratchLong0).w
                rts
; End of function Boss_MissirayInitializePrimaryModeTransition
; Waits for the previous transfer before starting direct tile set 00
Boss_MissirayWaitThenLoadPrimaryTransferSet:            ; was: sub_5430A
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayPrimaryTransferSetWaitReturn
                addq.w  #2,(SharedScratchLong0).w
                bra.w   Boss_MissirayLoadTileTransferSet00
; ---------------------------------------------------------------------------
Boss_MissirayPrimaryTransferSetWaitReturn:              ; was: locret_5431C
                rts
; End of function Boss_MissirayWaitThenLoadPrimaryTransferSet
; Waits for the direct transfer before queuing indexed-row set 00
Boss_MissirayWaitThenQueuePrimaryIndexedRowSet:         ; was: sub_5431E
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayPrimaryIndexedRowSetWaitReturn
                addq.w  #2,(SharedScratchLong0).w
                bra.w   Boss_MissirayQueueIndexedRowSet00
; ---------------------------------------------------------------------------
Boss_MissirayPrimaryIndexedRowSetWaitReturn:            ; was: locret_54330
                rts
; End of function Boss_MissirayWaitThenQueuePrimaryIndexedRowSet
; Waits for that transfer before queuing final indexed-row set 03
Boss_MissirayWaitThenQueuePrimaryFinalIndexedRowSet:    ; was: sub_54332
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayPrimaryFinalIndexedRowSetWaitReturn
                addq.w  #2,(SharedScratchLong0).w
                bsr.w   Boss_MissirayQueueIndexedRowSet03
                move.w  #$E,(SharedScratchLong3+2).w
Boss_MissirayPrimaryFinalIndexedRowSetWaitReturn:       ; was: locret_5434A
                rts
; End of function Boss_MissirayWaitThenQueuePrimaryFinalIndexedRowSet
; Applies the fourteen-step mode-zero palette fade and completes the transition
Boss_MissirayFadePrimaryModePalette:                    ; was: sub_5434C
                bsr.w   Boss_MissirayApplyPaletteFadeStep
                subq.w  #1,(SharedScratchLong3+2).w
                bpl.s   Boss_MissirayPrimaryModePaletteFadeReturn
                bra.w   Boss_MissirayFinishAttack
; ---------------------------------------------------------------------------
Boss_MissirayPrimaryModePaletteFadeReturn:              ; was: locret_5435A
                rts
; End of function Boss_MissirayFadePrimaryModePalette
; Dispatches the graphics transition that selects mode one
Boss_MissirayAlternateModeTransitionDispatcher:         ; was: sub_5435C
                move.w  (SharedScratchLong0).w,d0
                lea     Boss_MissirayAlternateModeTransitionStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayAlternateModeTransitionDispatcher
; ---------------------------------------------------------------------------
Boss_MissirayAlternateModeTransitionStates: dc.w    Boss_MissirayInitializeAlternateModeTransition-*  ; was: off_54368
                dc.w    Boss_MissirayWaitThenLoadAlternateTransferSet-*
                dc.w    Boss_MissirayWaitThenQueueAlternateIndexedRowSet-*
                dc.w    Boss_MissirayWaitThenQueueAlternateFinalIndexedRowSet-*
                dc.w    Boss_MissirayFadeAlternateModePalette-*

; Selects mode one, its vertical target, and shared render fields
Boss_MissirayInitializeAlternateModeTransition:         ; was: sub_54372
                move.w  #1,(SharedScratchLong1).w
                move.l  #$F40CE41C,$2C(a5)
                move.l  #$F010E41C,$28(a5)
                move.w  #$C0,(SharedScratchLong1+2).w
                addq.w  #2,(SharedScratchLong0).w
                rts
; End of function Boss_MissirayInitializeAlternateModeTransition
; Waits for the previous transfer before starting direct tile set 01
Boss_MissirayWaitThenLoadAlternateTransferSet:          ; was: sub_54394
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayAlternateTransferSetWaitReturn
                addq.w  #2,(SharedScratchLong0).w
                bra.w   Boss_MissirayLoadTileTransferSet01
; ---------------------------------------------------------------------------
Boss_MissirayAlternateTransferSetWaitReturn:            ; was: locret_543A6
                rts
; End of function Boss_MissirayWaitThenLoadAlternateTransferSet
; Waits for the direct transfer before queuing indexed-row set 01
Boss_MissirayWaitThenQueueAlternateIndexedRowSet:       ; was: sub_543A8
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayAlternateIndexedRowSetWaitReturn
                addq.w  #2,(SharedScratchLong0).w
                bra.w   Boss_MissirayQueueIndexedRowSet01
; ---------------------------------------------------------------------------
Boss_MissirayAlternateIndexedRowSetWaitReturn:          ; was: locret_543BA
                rts
; End of function Boss_MissirayWaitThenQueueAlternateIndexedRowSet
; Waits for that transfer before queuing final indexed-row set 04
Boss_MissirayWaitThenQueueAlternateFinalIndexedRowSet:  ; was: sub_543BC
                bsr.w   Boss_MissirayAdvancePaletteWaveIndex
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_MissirayAlternateFinalIndexedRowSetWaitReturn
                addq.w  #2,(SharedScratchLong0).w
                bsr.w   Boss_MissirayQueueIndexedRowSet04
                move.w  #$E,(SharedScratchLong3+2).w
Boss_MissirayAlternateFinalIndexedRowSetWaitReturn:     ; was: locret_543D4
                rts
; End of function Boss_MissirayWaitThenQueueAlternateFinalIndexedRowSet
; Applies the fourteen-step mode-one palette fade and completes the transition
Boss_MissirayFadeAlternateModePalette:                  ; was: sub_543D6
                bsr.w   Boss_MissirayApplyPaletteFadeStep
                subq.w  #1,(SharedScratchLong3+2).w
                bpl.s   Boss_MissirayAlternateModePaletteFadeReturn
                bra.w   Boss_MissirayFinishAttack
; ---------------------------------------------------------------------------
Boss_MissirayAlternateModePaletteFadeReturn:            ; was: locret_543E4
                rts
; End of function Boss_MissirayFadeAlternateModePalette
; Dispatches the fixed delay used between selected attacks
Boss_MissirayInterAttackDelayDispatcher:
                move.w  (SharedScratchLong0).w,d0       ; was: sub_543E6
                lea     Boss_MissirayInterAttackDelayStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_MissirayInterAttackDelayDispatcher
; ---------------------------------------------------------------------------
Boss_MissirayInterAttackDelayStates:    dc.w    Boss_MissirayBeginInterAttackDelay-*  ; was: off_543F2
                dc.w    Boss_MissirayTickInterAttackDelay-*

; Starts the fixed inter-attack delay
Boss_MissirayBeginInterAttackDelay:                     ; was: sub_543F6
                move.w  #$80,$48(a5)
                addq.w  #2,(SharedScratchLong0).w
; Counts down the delay and returns to attack selection
Boss_MissirayTickInterAttackDelay:                      ; was: loc_54400
                subq.w  #1,$48(a5)
                bne.s   Boss_MissirayInterAttackDelayReturn
                bra.w   Boss_MissirayFinishAttack
; ---------------------------------------------------------------------------
Boss_MissirayInterAttackDelayReturn:                    ; was: locret_5440A
                rts
; End of function Boss_MissirayBeginInterAttackDelay
; Allocates eight projectile records or retires a partially allocated set
Boss_MissirayAllocateSegmentProjectileSet:              ; was: sub_5440C
                                        ; Boss_MissirayAllocateAllSegmentProjectiles   p
                move.w  #7,d7
                lea     (SharedScratchLong5).w,a3
                moveq   #0,d0
Boss_MissirayClearNextProjectilePointer:                ; was: loc_54416
                move.w  d0,(a3)+
                dbf     d7,Boss_MissirayClearNextProjectilePointer
                move.w  #7,d7
                lea     (SharedScratchLong5).w,a3
Boss_MissirayAllocateNextSegmentProjectile:             ; was: loc_54424
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_MissirayCleanUpFailedProjectileSet
                move.w  #$10,(a0)
                move.w  a0,(a3)+
                dbf     d7,Boss_MissirayAllocateNextSegmentProjectile
                move.w  #0,d0
                rts
; ---------------------------------------------------------------------------
Boss_MissirayCleanUpFailedProjectileSet:                ; was: loc_5443C
                move.w  #7,d7
                lea     (SharedScratchLong5).w,a3
Boss_MissirayRetireNextAllocatedProjectile:             ; was: loc_54444
                movea.w (a3)+,a0
                beq.s   Boss_MissirayAllocateProjectileSetReturn
                move.w  #$1000,2(a0)
                dbf     d7,Boss_MissirayRetireNextAllocatedProjectile
                move.w  #1,d0
Boss_MissirayAllocateProjectileSetReturn:               ; was: locret_54456
                rts
; End of function Boss_MissirayAllocateSegmentProjectileSet
; Segment part main handler
