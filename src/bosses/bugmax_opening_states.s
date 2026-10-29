; Opening-state dispatch, setup, scroll thresholds, and linked-part spin
Boss_BugmaxMainStateHandlers:   dc.w    Boss_BugmaxInitializeEncounterState-*  ; DATA XREF: Boss_BugmaxUpdatePerspectiveAndLinkedGeometry+2D4   o  ; was: off_4C3D8
                dc.w    Boss_BugmaxInitializeHorizontalJitterState-*
                dc.w    Boss_BugmaxUpdateHorizontalJitterState-*
                dc.w    Boss_BugmaxWaitAfterJitterAndStartBossMessage-*
                dc.w    Boss_BugmaxWaitForOpeningTransition-*
                dc.w    Boss_BugmaxWaitForFirstOpeningScrollThreshold-*
                dc.w    Boss_BugmaxWaitForSecondOpeningScrollThreshold-*
                dc.w    Boss_BugmaxInitializeLinkedPartSpin-*
                dc.w    Boss_BugmaxAccelerateLinkedPartSpin-*
                dc.w    Boss_BugmaxReverseLinkedPartSpin-*
                dc.w    Boss_BugmaxSlowLinkedPartSpin-*
                dc.w    Boss_BugmaxPrepareJumpState-*
                dc.w    Boss_BugmaxInitializeBattleObjectChains-*
                dc.w    Boss_BugmaxRotateLinkedAssemblyToward140-*
                dc.w    Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle-*
                dc.w    Gfx_BugmaxLoadTimedBattleTileSet-*
                dc.w    Gfx_BugmaxLoadQueuedBattleTileSet-*
                dc.w    Boss_BugmaxSettleChainBendAtBattleBaseline-*
                dc.w    Boss_BugmaxSelectBattlePattern-*
                dc.w    Boss_BugmaxBeginSpreadVolleyStance-*
                dc.w    Boss_BugmaxIncreaseWaveStepForSpreadVolley-*
                dc.w    Boss_BugmaxApproachSpreadVolleyTarget-*
                dc.w    Boss_BugmaxSpawnSpreadProjectile-*
                dc.w    Boss_BugmaxRepeatSpreadProjectileVolley-*
                dc.w    Boss_BugmaxReduceWaveStepAfterSpreadVolley-*
                dc.w    Boss_BugmaxSetChainStrikeApproachTarget-*
                dc.w    Boss_BugmaxApproachChainStrikeTarget-*
                dc.w    Boss_BugmaxBeginAimedChainStrike-*
                dc.w    Boss_BugmaxAnimateAndAimChainStrike-*
                dc.w    Boss_BugmaxExtendAimedChainStrike-*
                dc.w    Boss_BugmaxHoldExtendedChainStrike-*
                dc.w    Boss_BugmaxRetractAimedChainStrike-*
                dc.w    Boss_BugmaxResetChainStrikeBend-*
                dc.w    Boss_BugmaxSettleChainAfterStrike-*
                dc.w    Boss_BugmaxBeginSineProjectileVolleyStance-*
                dc.w    Boss_BugmaxIncreaseWaveStepForSineVolley-*
                dc.w    Boss_BugmaxChooseSineVolleySideTarget-*
                dc.w    Boss_BugmaxApproachSineVolleyTarget-*
                dc.w    Boss_BugmaxPrepareSineProjectileVolley-*
                dc.w    Boss_BugmaxSpawnSineProjectile-*
                dc.w    Boss_BugmaxRepeatSineProjectileVolley-*
                dc.w    Boss_BugmaxReduceWaveStepAfterSineVolley-*
                dc.w    Boss_BugmaxReturnToBattlePatternSelection-*
                dc.w    Boss_BugmaxWaitForFinalWaveBand-*
                dc.w    Boss_BugmaxRunFinalPalettePulse-*
                dc.w    Boss_BugmaxScatterLinkedParts-*
                dc.w    Boss_BugmaxRiseWithFinalParticles-*
                dc.w    Boss_BugmaxWaitBeforeFinalDescent-*
                dc.w    Boss_BugmaxAccelerateFinalDescent-*
                dc.w    Boss_BugmaxUpdateFinalWaveDescentAndCompleteEncounter-*

; Initialize the controller, six linked parts, and smoothing buffers
Boss_BugmaxInitializeEncounterState:                    ; DATA XREF: ROM:Boss_BugmaxMainStateHandlers   o  ; was: sub_4C43C
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_BugmaxInitializeEncounterReturn
                addq.w  #2,4(a5)
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #$300,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                clr.w   $5E(a5)
                move.w  #$604,d0
                move.w  d0,$5C(a5)
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  #$C8,$14(a5)
                move.b  #$40,$20(a5)                    ; '@'
                move.l  #Boss_BugmaxOpeningControllerFrame,8(a5)
                move.w  #$300,$E(a5)
                eori.w  #$800,$E(a5)
                move.w  #$CD80,2(a5)
                move.w  #$80,$26(a5)
                move.l  #$F808F808,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.b  #$D0,$21(a5)
                move.w  #4,$24(a5)
                move.w  #$40,$50(a5)                    ; '@'
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                move.l  #Boss_BugmaxCentralPartUpperAngleFrame,8(a0)
                move.w  $E(a5),$E(a0)
                move.w  2(a5),2(a0)
                move.l  #$F010F808,$28(a0)
                move.b  #$D0,$21(a0)
                move.b  #$80,$23(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                move.w  #$180,$4C(a0)
                move.w  #$50,$50(a0)                    ; 'P'
                move.w  #4,$24(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                moveq   #0,d6
                move.w  #4,d7
                movea.w #(TertiaryEntityType-M68K_RAM),a0
Boss_BugmaxInitializeLinkedPartLoop:                    ; CODE XREF: Boss_BugmaxInitializeEncounterState+144   j  ; was: loc_4C51E
                move.w  #$10,(a0)
                move.w  $E(a5),$E(a0)
                move.w  2(a5),2(a0)
                move.w  #4,$24(a0)
                move.b  $20(a5),$20(a0)
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F808F010,$28(a0)
                move.b  #$D0,$21(a0)
                move.w  #$80,$26(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$80,$4C(a0)
                lea     Boss_BugmaxLinkedPartDescriptors(pc),a1
                nop
                move.w  (a1,d6.w),$50(a0)
                move.l  4(a1,d6.w),8(a0)
                addq.w  #8,d6
                lea     $60(a0),a0
                dbf     d7,Boss_BugmaxInitializeLinkedPartLoop
                bsr.w   Gfx_BugmaxLoadInitialTiles
                move.w  #$168,d0
                sub.w   $5C(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$128,d0
                move.w  d0,(SecondaryCameraYPos).w
                lea     (BugmaxAngleHistoryRows).w,a0
                move.w  #7,d7
Boss_BugmaxClearAngleHistoryRowsLoop:                   ; CODE XREF: Boss_BugmaxInitializeEncounterState+17C   j  ; was: loc_4C5AC
                move.w  #3,d6
; Fill one four-word angle-history row with $80
Boss_BugmaxClearAngleHistoryRowLoop:                    ; CODE XREF: Boss_BugmaxInitializeEncounterState+178   j  ; was: loc_4C5B0
                move.w  #$80,(a0)+
                dbf     d6,Boss_BugmaxClearAngleHistoryRowLoop
                dbf     d7,Boss_BugmaxClearAngleHistoryRowsLoop
Boss_BugmaxInitializeEncounterReturn:                   ; CODE XREF: Boss_BugmaxInitializeEncounterState+4   j  ; was: locret_4C5BC
                rts
; End of function Boss_BugmaxInitializeEncounterState
; ---------------------------------------------------------------------------
Boss_BugmaxLinkedPartDescriptors:   dc.w    $5C         ; field_0  ; was: stru_4C5BE
                                        ; DATA XREF: Boss_BugmaxInitializeEncounterState+12C   o
                dc.w    $FF                             ; field_2
                dc.l    Boss_BugmaxOpeningLinkFrame00   ; field_4
                dc.w    $40                             ; field_0
                dc.w    $FF                             ; field_2
                dc.l    Boss_BugmaxOpeningLinkFrame01   ; field_4
                dc.w    $30                             ; field_0
                dc.w    $FF                             ; field_2
                dc.l    Boss_BugmaxOpeningLinkFrame01   ; field_4
                dc.w    $2C                             ; field_0
                dc.w    $FF                             ; field_2
                dc.l    Boss_BugmaxOpeningLinkFrame02   ; field_4
                dc.w    $28                             ; field_0
                dc.w    $FF                             ; field_2
                dc.l    Boss_BugmaxOpeningLinkFrame02   ; field_4

; Load the initial Bugmax tile set
Gfx_BugmaxLoadInitialTiles:                             ; CODE XREF: Boss_BugmaxInitializeEncounterState+148   p  ; was: sub_4C5E6
                lea     Gfx_BugmaxInitialTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Gfx_BugmaxLoadInitialTiles
; ---------------------------------------------------------------------------
Gfx_BugmaxInitialTileLoadDescriptor:    dc.w    $6330, $2000, $104, $BEBF, $C2C3, $C6C7, $CACB, $CF  ; was: word_4C5F2
                                        ; DATA XREF: Gfx_BugmaxLoadInitialTiles   o

; Save the body anchor and initialize the horizontal-jitter timer
Boss_BugmaxInitializeHorizontalJitterState:             ; DATA XREF: ROM:0004C3DA   o  ; was: sub_4C602
                move.w  $5C(a5),$4A(a5)
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxInitializeHorizontalJitterState
; Alternate the body anchor by $60 while the jitter timer runs
Boss_BugmaxUpdateHorizontalJitterState:                 ; DATA XREF: ROM:0004C3DC   o  ; was: sub_4C614
                subq.w  #1,$48(a5)
                beq.s   Boss_BugmaxFinishHorizontalJitterState
                move.w  $4A(a5),d0
                move.w  (FrameCounter).w,d7
                andi.w  #2,d7
                beq.s   Boss_BugmaxStoreJitteredBodyAnchor
                addi.w  #$60,d0                         ; '`'
Boss_BugmaxStoreJitteredBodyAnchor:                     ; CODE XREF: Boss_BugmaxUpdateHorizontalJitterState+12   j  ; was: loc_4C62C
                move.w  d0,$5C(a5)
                rts
; ---------------------------------------------------------------------------
; Restore the saved body anchor and finish the jitter state
Boss_BugmaxFinishHorizontalJitterState:                 ; CODE XREF: Boss_BugmaxUpdateHorizontalJitterState+4   j  ; was: loc_4C632
                move.w  $4A(a5),$5C(a5)
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxUpdateHorizontalJitterState
; Wait after the jitter, clamp linked positions, and start the boss message
Boss_BugmaxWaitAfterJitterAndStartBossMessage:          ; DATA XREF: ROM:0004C3DE   o  ; was: sub_4C644
                bsr.w   Boss_BugmaxClampOpeningObjectHorizontalPositions
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxPostJitterWaitReturn
                move.w  #3,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
Boss_BugmaxPostJitterWaitReturn:                        ; CODE XREF: Boss_BugmaxWaitAfterJitterAndStartBossMessage+8   j  ; was: locret_4C65C
                rts
; End of function Boss_BugmaxWaitAfterJitterAndStartBossMessage
; Wait for the opening transition gate and enable controller collision
Boss_BugmaxWaitForOpeningTransition:                    ; DATA XREF: ROM:0004C3E0   o  ; was: sub_4C65E
                bsr.w   Boss_BugmaxClampOpeningObjectHorizontalPositions
                tst.w   (MessageSequenceState).w
                bne.s   Boss_BugmaxOpeningTransitionWaitReturn
                move.b  #$D0,$21(a5)
                clr.b   (BossColorEffectFlags).w
                clr.w   (SharedScratchLong10+2).w
                subi.w  #$A0,(CameraXLowerBound).w
                addq.w  #2,4(a5)
Boss_BugmaxOpeningTransitionWaitReturn:                 ; CODE XREF: Boss_BugmaxWaitForOpeningTransition+8   j  ; was: locret_4C680
                rts
; End of function Boss_BugmaxWaitForOpeningTransition
; Wait for the first opening scroll threshold, then replace tiles and emit debris
Boss_BugmaxWaitForFirstOpeningScrollThreshold:          ; DATA XREF: ROM:0004C3E2   o  ; was: sub_4C682
                bsr.w   Boss_BugmaxEmitOpeningHitFragmentsAndSteer
                bsr.w   Boss_BugmaxClampOpeningObjectHorizontalPositions
                cmpi.w  #$6800,(BossHealth).w
                bhi.s   Boss_BugmaxFirstOpeningThresholdReturn
                addq.w  #2,4(a5)
                move.w  #3,d0
                bsr.w   Boss_BugmaxSpawnTransitionDebris
                bra.s   Gfx_BugmaxLoadFirstOpeningTiles
; ---------------------------------------------------------------------------
Boss_BugmaxFirstOpeningThresholdReturn:                 ; CODE XREF: Boss_BugmaxWaitForFirstOpeningScrollThreshold+E   j  ; was: locret_4C6A0
                rts
; ---------------------------------------------------------------------------
; Load the first opening-transition tile set
Gfx_BugmaxLoadFirstOpeningTiles:                        ; CODE XREF: Boss_BugmaxWaitForFirstOpeningScrollThreshold+1C   j  ; was: loc_4C6A2
                lea     Gfx_BugmaxFirstOpeningTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Boss_BugmaxWaitForFirstOpeningScrollThreshold
; ---------------------------------------------------------------------------
Gfx_BugmaxFirstOpeningTileLoadDescriptor:   dc.w    $6330, $2000, $104, $BEBF, $C0C3, $C4C7, $C8CB, $CF  ; was: word_4C6AE
                                        ; DATA XREF: Boss_BugmaxWaitForFirstOpeningScrollThreshold:Gfx_BugmaxLoadFirstOpeningTiles   o

; Spawn Bugmax transition debris from selected linked records
Boss_BugmaxSpawnTransitionDebris:                       ; CODE XREF: Boss_BugmaxWaitForFirstOpeningScrollThreshold+18   p  ; was: sub_4C6BE
                                        ; Boss_BugmaxWaitForSecondOpeningScrollThreshold+20   p
                move.w  d0,d7
                subq.w  #1,d7
                clr.w   d6
; Initialize the requested number of transition-debris projectiles
Boss_BugmaxSpawnTransitionDebrisLoop:                   ; CODE XREF: Boss_BugmaxSpawnTransitionDebris+38   j  ; was: loc_4C6C4
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_BugmaxTransitionDebrisSpawnReturn
                lea     Boss_BugmaxDebrisParameterTable(pc),a2
                nop
                move.w  (a2,d6.w),d0
                move.w  $E(a2,d6.w),d1
                move.w  $1C(a2,d6.w),d2
                movea.w Boss_BugmaxDebrisSourceObjectTable(pc,d6.w),a1
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),$14(a0)
                jsr     (Projectile_InitBugmaxDebrisSpawner).l
                addq.w  #2,d6
                dbf     d7,Boss_BugmaxSpawnTransitionDebrisLoop
Boss_BugmaxTransitionDebrisSpawnReturn:                 ; CODE XREF: Boss_BugmaxSpawnTransitionDebris+C   j  ; was: locret_4C6FA
                rts
; End of function Boss_BugmaxSpawnTransitionDebris
; ---------------------------------------------------------------------------
Boss_BugmaxDebrisSourceObjectTable: dc.w    $C620, $C6E0, $C740, $C7A0, $C680, $C800, $C860  ; was: word_4C6FC
                                        ; DATA XREF: Boss_BugmaxSpawnTransitionDebris+20   r
Boss_BugmaxDebrisParameterTable:    dc.w    $40, $40, $40, $40, $28, $28, $18  ; was: word_4C70A
                                        ; DATA XREF: Boss_BugmaxSpawnTransitionDebris+E   o
                dc.w    $20, $20, $20, $10, 8, 8, 4
                dc.w    $10, $10, $10, $10, 8, 8, 8

; Wait for the second opening scroll threshold, then replace tiles and emit debris
Boss_BugmaxWaitForSecondOpeningScrollThreshold:         ; DATA XREF: ROM:0004C3E4   o  ; was: sub_4C734
                bsr.w   Boss_BugmaxEmitOpeningHitFragmentsAndSteer
                bsr.w   Boss_BugmaxClampOpeningObjectHorizontalPositions
                cmpi.w  #$6000,(BossHealth).w
                bhi.s   Boss_BugmaxSecondOpeningThresholdReturn
                clr.l   $18(a5)
                addq.w  #2,$5E(a5)
                addq.w  #2,4(a5)
                move.w  #7,d0
                bsr.w   Boss_BugmaxSpawnTransitionDebris
                bra.s   Gfx_BugmaxLoadSecondOpeningTiles
; ---------------------------------------------------------------------------
Boss_BugmaxSecondOpeningThresholdReturn:                ; CODE XREF: Boss_BugmaxWaitForSecondOpeningScrollThreshold+E   j  ; was: locret_4C75A
                rts
; ---------------------------------------------------------------------------
; Load the second opening-transition tile set
Gfx_BugmaxLoadSecondOpeningTiles:                       ; CODE XREF: Boss_BugmaxWaitForSecondOpeningScrollThreshold+24   j  ; was: loc_4C75C
                lea     Gfx_BugmaxSecondOpeningTileLoadDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedColumns
; End of function Boss_BugmaxWaitForSecondOpeningScrollThreshold
; ---------------------------------------------------------------------------
Gfx_BugmaxSecondOpeningTileLoadDescriptor:  dc.w    $6330, $2000, $104, $BCBD, $C1, $C5, $C9, $CD  ; was: word_4C768
                                        ; DATA XREF: Boss_BugmaxWaitForSecondOpeningScrollThreshold:Gfx_BugmaxLoadSecondOpeningTiles   o

; Initialize synchronized linked-part rotation
Boss_BugmaxInitializeLinkedPartSpin:                    ; DATA XREF: ROM:0004C3E6   o  ; was: sub_4C778
                move.w  (TertiaryEntityWork4C).w,$4C(a5)
                move.w  #$118,$4A(a5)
                move.w  #$80,(SeventhEntityWork4C).w
                bsr.w   Boss_BugmaxSynchronizeLinkedPartAngles
                addq.w  #2,4(a5)
                rts
; End of function Boss_BugmaxInitializeLinkedPartSpin
; Accelerate linked-part angular offsets over eight timed steps
Boss_BugmaxAccelerateLinkedPartSpin:                    ; DATA XREF: ROM:0004C3E8   o  ; was: sub_4C794
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                bsr.w   Boss_BugmaxSelectCentralPartFrameByAngle
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                subq.w  #2,d0
                add.w   $4A(a5),d0
                move.w  d0,(SeventhEntityYPos).w
                move.w  (FrameCounter).w,d7
                andi.w  #7,d7
                bne.s   Boss_BugmaxLinkedPartSpinAccelerationReturn
                addq.w  #1,$48(a5)
                cmpi.w  #8,$48(a5)
                bcc.s   Boss_BugmaxFinishLinkedPartSpinAcceleration
                move.w  $48(a5),d0
                neg.w   d0
                bsr.w   Boss_BugmaxSetLinkedPartAngleOffsets
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxFinishLinkedPartSpinAcceleration:            ; CODE XREF: Boss_BugmaxAccelerateLinkedPartSpin+2E   j  ; was: loc_4C7D0
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_BugmaxLinkedPartSpinAccelerationReturn:            ; CODE XREF: Boss_BugmaxAccelerateLinkedPartSpin+22   j  ; was: locret_4C7DA
                rts
; End of function Boss_BugmaxAccelerateLinkedPartSpin
; Apply a cumulative angle offset across the linked-part address table
Boss_BugmaxSetLinkedPartAngleOffsets:                   ; CODE XREF: Boss_BugmaxAccelerateLinkedPartSpin+36   p  ; was: sub_4C7DC
                                        ; Boss_BugmaxReverseLinkedPartSpin+2A   p
                move.w  #6,d7
                moveq   #0,d6
                lea     Boss_BugmaxLinkedPartAddressTable(pc),a1
                nop
; Store one linked-part angle offset and advance the accumulator
Boss_BugmaxSetLinkedPartAngleOffsetLoop:                ; CODE XREF: Boss_BugmaxSetLinkedPartAngleOffsets+16   j  ; was: loc_4C7E8
                movea.w (a1)+,a0
                move.w  d6,$4E(a0)
                add.w   d0,d6
                add.w   d0,d6
                dbf     d7,Boss_BugmaxSetLinkedPartAngleOffsetLoop
                rts
; End of function Boss_BugmaxSetLinkedPartAngleOffsets
; ---------------------------------------------------------------------------
Boss_BugmaxLinkedPartAddressTable:  dc.w    $C860, $C800, $C7A0, $C740, $C6E0, $C620, $C680  ; was: word_4C7F8
                                        ; DATA XREF: Boss_BugmaxSetLinkedPartAngleOffsets+6   o
                                        ; sub_4C806   o

; Copy the first linked-part angle to the remaining linked records
Boss_BugmaxSynchronizeLinkedPartAngles:                 ; CODE XREF: Boss_BugmaxInitializeLinkedPartSpin+12   p  ; was: sub_4C806
                lea     Boss_BugmaxLinkedPartAddressTable(pc),a1
                movea.w (a1)+,a0
                move.w  $4C(a0),d0
                move.w  #5,d7
Boss_BugmaxSynchronizeLinkedPartAngleLoop:              ; CODE XREF: Boss_BugmaxSynchronizeLinkedPartAngles+14   j  ; was: loc_4C814
                movea.w (a1)+,a0
                move.w  d0,$4C(a0)
                dbf     d7,Boss_BugmaxSynchronizeLinkedPartAngleLoop
                subi.w  #$100,(SecondaryEntityWork4C).w
                andi.w  #$1FF,(SecondaryEntityWork4C).w
                rts
; End of function Boss_BugmaxSynchronizeLinkedPartAngles
; Select the central linked-part mapping from its normalized angle
Boss_BugmaxSelectCentralPartFrameByAngle:               ; CODE XREF: Boss_BugmaxAccelerateLinkedPartSpin+4   p  ; was: sub_4C82C
                                        ; Boss_BugmaxReverseLinkedPartSpin+4   p
                move.w  $4C(a0),d0
                add.w   $4E(a0),d0
                addi.w  #$10,d0
                andi.w  #$1E0,d0
                andi.w  #$F7FF,$E(a0)
                andi.w  #$EFFF,$E(a0)
                cmpi.w  #$160,d0
                bcs.s   Boss_BugmaxSelectLowerAngleCentralPartFrame
                cmpi.w  #$170,d0
                bhi.s   Boss_BugmaxSelectUpperAngleCentralPartFrame
                ori.w   #$800,$E(a0)
                move.l  #Boss_BugmaxCentralPartMiddleAngleFrame,8(a0)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxSelectUpperAngleCentralPartFrame:            ; CODE XREF: Boss_BugmaxSelectCentralPartFrameByAngle+26   j  ; was: loc_4C864
                ori.w   #$800,$E(a0)
                move.l  #Boss_BugmaxCentralPartUpperAngleFrame,8(a0)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxSelectLowerAngleCentralPartFrame:            ; CODE XREF: Boss_BugmaxSelectCentralPartFrameByAngle+20   j  ; was: loc_4C874
                ori.w   #$800,$E(a0)
                move.l  #Boss_BugmaxCentralPartLowerAngleFrame,8(a0)
                rts
; End of function Boss_BugmaxSelectCentralPartFrameByAngle
; Reverse and randomize linked-part angular offsets during the timed state
Boss_BugmaxReverseLinkedPartSpin:                       ; DATA XREF: ROM:0004C3EA   o  ; was: sub_4C884
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                bsr.w   Boss_BugmaxSelectCentralPartFrameByAngle
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                subq.w  #2,d0
                add.w   $4A(a5),d0
                move.w  d0,(SeventhEntityYPos).w
                move.b  (RandomNumberState).w,d0
                andi.w  #1,d0
                subq.w  #1,d0
                addi.w  #8,d0
                neg.w   d0
                bsr.w   Boss_BugmaxSetLinkedPartAngleOffsets
                subq.w  #1,$48(a5)
                bne.s   Boss_BugmaxReverseLinkedPartSpinReturn
                move.w  #$FFF8,$48(a5)
                addq.w  #2,4(a5)
Boss_BugmaxReverseLinkedPartSpinReturn:                 ; CODE XREF: Boss_BugmaxReverseLinkedPartSpin+32   j  ; was: locret_4C8C2
                rts
; End of function Boss_BugmaxReverseLinkedPartSpin
; Reduce the shared linked-part angle increment until the terminal value
Boss_BugmaxSlowLinkedPartSpin:                          ; DATA XREF: ROM:0004C3EC   o  ; was: sub_4C8C4
                move.w  $48(a5),d0
                bsr.w   Boss_BugmaxSetLinkedPartAngleOffsets
                subq.w  #1,$48(a5)
                cmpi.w  #$FFEC,$48(a5)
                bne.s   Boss_BugmaxLinkedPartSpinSlowdownReturn
                addq.w  #2,4(a5)
Boss_BugmaxLinkedPartSpinSlowdownReturn:                ; CODE XREF: Boss_BugmaxSlowLinkedPartSpin+12   j  ; was: locret_4C8DC
                rts
; End of function Boss_BugmaxSlowLinkedPartSpin
; Finish angle restoration, seed jump velocities, and play sound $E4
Boss_BugmaxPrepareJumpState:                            ; DATA XREF: ROM:0004C3EE   o  ; was: sub_4C8DE
                move.w  $48(a5),d0
                bsr.w   Boss_BugmaxSetLinkedPartAngleOffsets
                addq.w  #1,$48(a5)
                bne.s   Boss_BugmaxPrepareJumpReturn
                move.l  #$FFFA0000,(SeventhEntityYVel).w
                move.l  #$FFFD0000,(SeventhEntityXVel).w
                addq.w  #2,4(a5)
                move.b  #$E4,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_BugmaxPrepareJumpReturn:                           ; CODE XREF: Boss_BugmaxPrepareJumpState+C   j  ; was: locret_4C90A
                rts
; End of function Boss_BugmaxPrepareJumpState
; Update the body anchor from the saved value and current scroll side
Boss_BugmaxUpdateBodyAnchorFromScrollPhase:             ; CODE XREF: Boss_BugmaxRotateLinkedAssemblyToward180AndStartBattle+8   p  ; was: sub_4C90C
                move.w  $4A(a5),d0
                move.w  (FrameCounter).w,d7
                btst    #0,d7
                bne.s   Boss_BugmaxAdjustBodyAnchorForScrollSide
                move.w  d0,$5C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxAdjustBodyAnchorForScrollSide:               ; CODE XREF: Boss_BugmaxUpdateBodyAnchorFromScrollPhase+C   j  ; was: loc_4C920
                cmpi.w  #$410,(PrimaryCameraXPosition).w
                bcc.s   Boss_BugmaxStorePositiveBodyAnchorOffset
                subi.w  #$80,d0
                rts
; ---------------------------------------------------------------------------
Boss_BugmaxStorePositiveBodyAnchorOffset:               ; CODE XREF: Boss_BugmaxUpdateBodyAnchorFromScrollPhase+1A   j  ; was: loc_4C92E
                addi.w  #$80,d0
                move.w  d0,$5C(a5)
                rts
; End of function Boss_BugmaxUpdateBodyAnchorFromScrollPhase
