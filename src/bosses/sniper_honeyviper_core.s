; Runs Sniper Honeyviper's encounter state machine and shared visual state
Boss_SniperHoneyviperMainHandler:                       ; was: sub_3641A
                move.w  (VScrollPlaneBColumn0).w,(VScrollPlaneAColumn1).w
                tst.w   4(a5)
                beq.s   Boss_SniperHoneyviperDispatchState
                tst.w   6(a5)
                beq.s   Boss_SniperHoneyviperDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_SniperHoneyviperUpdateActiveState
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_SniperHoneyviperUpdateActiveState
                tst.w   (BossHealth).w
                bne.s   Boss_SniperHoneyviperUpdateActiveState
                bset    #0,(StageTimerPauseFlag).w
                bra.w   Boss_SniperHoneyviperBeginDefeat
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperUpdateActiveState:                 ; was: loc_3644C
                                        ; Boss_SniperHoneyviperMainHandler+20   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                clr.b   $49(a5)
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$58(a5)
                addi.l  #$6000,$7C(a5)
                bmi.s   Boss_SniperHoneyviperDispatchState
                cmpi.w  #$150,$74(a5)
                bmi.s   Boss_SniperHoneyviperDispatchState
                clr.l   $7C(a5)
                move.w  #$150,$74(a5)
                tst.w   (PlaneAShakeLevel).w
                bne.s   Boss_SniperHoneyviperDispatchState
                move.w  #1,(PlaneAShakeLevel).w
Boss_SniperHoneyviperDispatchState:                     ; was: loc_3648A
                                        ; Boss_SniperHoneyviperMainHandler+10   j
                move.w  4(a5),d0
                movea.w Boss_SniperHoneyviperStates(pc,d0.w),a0
                adda.l  #Boss_SniperHoneyviperBeginEncounter,a0
                jmp     (a0)
; End of function Boss_SniperHoneyviperMainHandler
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperStates:    dc.w    Boss_SniperHoneyviperBeginEncounter-Boss_SniperHoneyviperBeginEncounter  ; was: off_3649A
                dc.w    Boss_SniperHoneyviperLoadInitialAssetsAfterBackgroundRows-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperQueueIndexedTileColumnsAfterAssets-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperInitializeEncounterEntities-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperSelectRotationPattern-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperUpdateAttackAndSpawnProjectile-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocity-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperUpdateNegativeTravelCycle-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperBrakePositiveSecondaryXVelocity-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperUpdatePositiveTravelCycle-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocity-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperUpdateNegativeTravelCycle-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperWaitForMotionThreshold-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperBossMessageDelayState-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperWaitForBossMessageState-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperWaitForDefeatMotionState-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperDefeatSequence-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperDefeatFadeOut-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperWaitForCounterRefillMotionThreshold-Boss_SniperHoneyviperBeginEncounter
                dc.w    Boss_SniperHoneyviperUpdateCombatCounterRefill-Boss_SniperHoneyviperBeginEncounter

; Starts the encounter's background transition and removes unrelated objects
Boss_SniperHoneyviperBeginEncounter:                    ; was: sub_364C2
                addq.w  #2,4(a5)
                addq.w  #1,6(a5)
                move.l  #Boss_SniperHoneyviperBackgroundConfig,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                move.w  #0,(TilemapRowYPosition).w
                move.w  #$13,(TilemapRowCountdown).w
                move.w  #$24,d0                         ; '$'
                move.w  #$134,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; End of function Boss_SniperHoneyviperBeginEncounter
Boss_SniperHoneyviperNoOp:
                rts                                     ; was: nullsub_77
; End of function Boss_SniperHoneyviperNoOp
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperBackgroundConfig:  dc.w    $FFFF, $7000, $FFFF, $6800, $FFFF, $2000, 0, $4000  ; was: word_364F4

; Waits for the background-row stream, loads the initial asset descriptors, and
; builds the shared sine/cosine displacement tables
Boss_SniperHoneyviperLoadInitialAssetsAfterBackgroundRows:  ; was: sub_36504
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.s   Boss_SniperHoneyviperLoadInitialAssetsAfterBackgroundRowsReturn
                addq.w  #2,4(a5)
                movem.l a5,-(sp)
                movea.l #Boss_SniperHoneyviperInitialAssetDescriptors,a0
                jsr     (Data_ProcessPointer).l
                movem.l (sp)+,a5
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                moveq   #$10,d0
                jmp     Math_CalculateSineCosineTable
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperLoadInitialAssetsAfterBackgroundRowsReturn:  ; was: locret_36530
                rts
; End of function Boss_SniperHoneyviperLoadInitialAssetsAfterBackgroundRows
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperInitialAssetDescriptors:   dc.w    7  ; field_0  ; was: stru_36532
                dc.l    Boss_SniperHoneyviperTileArt    ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF

; Waits for the asset loader, queues the indexed tile columns, and seeds the
; secondary camera X position
Boss_SniperHoneyviperQueueIndexedTileColumnsAfterAssets:  ; was: sub_36544
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_SniperHoneyviperQueueIndexedTileColumnsAfterAssetsReturn
                addq.w  #2,4(a5)
                movea.l #Boss_SniperHoneyviperTileDmaDescriptor,a0
                jsr     (Tilemap_QueueIndexedColumns).l
                move.w  #$80,(SecondaryCameraXPos).w
Boss_SniperHoneyviperQueueIndexedTileColumnsAfterAssetsReturn:  ; was: locret_36560
                rts
; End of function Boss_SniperHoneyviperQueueIndexedTileColumnsAfterAssets
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperTileDmaDescriptor: dc.w    $6100, $2000, $204, $708, $90A, $B0C, $D0E, $150F, $1011, $1213, $1400  ; was: word_36562

; Configures the encounter raster state and initializes Sniper Honeyviper's root,
; auxiliary, chain-part, and table-driven entity records
Boss_SniperHoneyviperInitializeEncounterEntities:       ; was: sub_36578
                move.w  #$14,4(a5)
                move.w  #4,$174(a5)
                addq.w  #2,(StageStateOffset).w
                move.w  #$24,(RasterEffectIndex).w      ; '$'
                clr.w   (RasterEffectInitState).w
                move.w  #$A,(RasterLayoutOffset).w
                move.b  #3,(PlaneBScrollModeFlags).w
                move.w  #8,$5A(a5)
                move.w  #2,$5C(a5)
                bset    #1,$5E(a5)
                move.w  #$258,$10(a5)
                move.w  #$258,$70(a5)
                move.w  #$150,$14(a5)
                move.w  #$150,$74(a5)
                move.w  #$C180,2(a5)
                move.w  #$CB00,$E(a5)
                move.l  #Boss_SniperHoneyviperPrimarySpriteDescriptor,8(a5)
                move.b  #$30,$20(a5)                    ; '0'
                move.w  #$10,$60(a5)
                move.w  #$CD80,$62(a5)
                move.w  #$CB00,$6E(a5)
                move.l  #Boss_SniperHoneyviperSecondarySpriteDescriptor,$68(a5)
                move.b  #$30,$80(a5)                    ; '0'
                movea.l #Boss_SniperHoneyviperAuxiliaryPartDescriptors,a0
                moveq   #4,d7
Boss_SniperHoneyviperInitializeNextAuxiliaryPart:       ; was: loc_3660A
                movea.w (a0)+,a1
                move.w  #$10,(a1)
                move.w  #$8080,2(a1)
                move.b  #$80,$20(a1)
                move.w  (a0)+,$E(a1)
                move.w  (a0)+,8(a1)
                move.w  (a0)+,$A(a1)
                dbf     d7,Boss_SniperHoneyviperInitializeNextAuxiliaryPart
                move.b  #$20,$260(a5)                   ; ' '
                move.b  #$20,$320(a5)                   ; ' '
                move.w  #$10,$1E0(a5)
                move.w  #$C080,$1E2(a5)
                move.b  #$28,$200(a5)                   ; '('
                move.w  #$10,$2A0(a5)
                move.w  #$C080,$2A2(a5)
                move.b  #$24,$2C0(a5)                   ; '$'
                movea.w #(TenthEntityType-M68K_RAM),a0
                moveq   #$30,d0                         ; '0'
                moveq   #5,d7
Boss_SniperHoneyviperInitializeNextChainPart:           ; was: loc_36664
                move.w  #$10,(a0)
                move.w  #$8080,2(a0)
                move.b  d0,$20(a0)
                move.w  #$639E,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                lea     $60(a0),a0
                subq.w  #4,d0
                dbf     d7,Boss_SniperHoneyviperInitializeNextChainPart
                move.w  #$63A7,$54E(a5)
                move.w  #$F00,$548(a5)
                move.w  #$F0F0,$54A(a5)
                movea.w #(SixteenthEntityType-M68K_RAM),a0
                move.w  #$10,(a0)
                movea.l #Boss_SniperHoneyviperObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                bsr.w   Boss_SniperHoneyviperUpdateTentaclesAndChainParts
                bra.w   Boss_SniperHoneyviperUpdatePositionAndLineScroll
; End of function Boss_SniperHoneyviperInitializeEncounterEntities
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperAuxiliaryPartDescriptors:  dc.w    $C6E0, $63B7, $500, $F8F8, $C7A0, $63BB, $900, $F4F8, $C740, $63C1  ; was: word_366BC
                dc.w    $400, $F8FC, $C860, $E3E7, 0, $FCFC, $C920, $E3E3, $500, $F6FA
Boss_SniperHoneyviperPrimarySpriteDescriptor:   dc.w    $2892, $500, $E8, $A88A, $D00, $F8  ; was: word_366E4
Boss_SniperHoneyviperSecondarySpriteDescriptor: dc.w    $2898, $900, $C1E2, $A896, $400, $C900  ; was: word_366F0

; Selects rotation state $E when BossCombatCounter is at least $13C, otherwise
; selects state zero, then clears the secondary entity's X velocity
Boss_SniperHoneyviperSelectRotationPattern:             ; was: sub_366FC
                cmpi.w  #6,$16C(a5)
                bpl.s   Boss_SniperHoneyviperUpdateAttackAndSpawnProjectile
                addq.w  #2,4(a5)
                move.w  #$E,$174(a5)
                cmpi.w  #$13C,(BossCombatCounter).w
                bpl.s   Boss_SniperHoneyviperSelectRotationPatternClearSecondaryXVelocity
                clr.w   $174(a5)
Boss_SniperHoneyviperSelectRotationPatternClearSecondaryXVelocity:  ; was: loc_3671A
                clr.l   $78(a5)
; Runs Sniper Honeyviper's motion pipeline and oscillating-shot attempt until the rotation,
; delay, and bounce gates allow selection of the next travel direction
Boss_SniperHoneyviperUpdateAttackAndSpawnProjectile:    ; was: loc_3671E
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                bsr.w   Boss_SniperHoneyviperSpawnOscillatingShot
                cmpi.w  #2,$174(a5)
                bne.s   Boss_SniperHoneyviperAttackUpdateReturn
                subq.w  #1,$5A(a5)
                bpl.s   Boss_SniperHoneyviperAttackUpdateReturn
                btst    #0,$5E(a5)
                beq.s   Boss_SniperHoneyviperAttackUpdateReturn
Boss_SniperHoneyviperSelectTravelDirection:             ; was: loc_3673C
                jsr     (Physics_GetPlayerDelta).l
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                addq.w  #1,d0
                move.w  d0,$5A(a5)
                move.w  #4,$174(a5)
                tst.w   d1
                bpl.s   Boss_SniperHoneyviperSelectPositiveTravelMotion
                cmpi.w  #$1C08,$58(a5)
                bmi.s   Boss_SniperHoneyviperSelectPositiveTravelMotion
                move.w  #$C,4(a5)
                move.w  #2,$5C(a5)
                move.l  #$FFFE4000,$78(a5)
                bset    #1,$5E(a5)
Boss_SniperHoneyviperAttackUpdateReturn:                ; was: locret_3677C
                                        ; Boss_SniperHoneyviperSelectRotationPattern+36   j
                rts
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperSelectPositiveTravelMotion:        ; was: loc_3677E
                                        ; Boss_SniperHoneyviperSelectRotationPattern+64   j
                move.w  #$10,4(a5)
                move.w  #4,$5C(a5)
                move.l  #$18000,$78(a5)
                bclr    #1,$5E(a5)
                rts
; End of function Boss_SniperHoneyviperSelectRotationPattern
; Returns to attack-selection state eight and derives the next delay from
; $1E0 minus BossCombatCounter
Boss_SniperHoneyviperPrepareNextAttackCycle:            ; was: sub_3679A
                                        ; Boss_SniperHoneyviperUpdateNegativeTravelCycle+3C   j
                move.w  #8,4(a5)
                clr.w   $5C(a5)
                move.w  #$1E0,d0
                sub.w   (BossCombatCounter).w,d0
                asr.w   #4,d0
                addq.w  #1,d0
                move.w  d0,$5A(a5)
                rts
; End of function Boss_SniperHoneyviperPrepareNextAttackCycle
; Waits for motion phase $16C to fall below six, then starts the counter-refill
; rotation and clears the secondary entity's X velocity
Boss_SniperHoneyviperWaitForCounterRefillMotionThreshold:  ; was: sub_367B6
                cmpi.w  #6,$16C(a5)
                bpl.s   Boss_SniperHoneyviperUpdateCombatCounterRefill
                addq.w  #2,4(a5)
                move.w  #$A,$174(a5)
                clr.l   $78(a5)
; Refills BossCombatCounter toward $1E0 while updating motion, then waits for
; the configured delay and a bounce before selecting another travel direction
Boss_SniperHoneyviperUpdateCombatCounterRefill:         ; was: loc_367CC
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                addi.w  #4,(BossCombatCounter).w
                cmpi.w  #$1E0,(BossCombatCounter).w
                bmi.s   Boss_SniperHoneyviperCombatCounterRefillReturn
                subq.w  #1,$5A(a5)
                bpl.s   Boss_SniperHoneyviperCombatCounterRefillReturn
                btst    #0,$5E(a5)
                bne.w   Boss_SniperHoneyviperSelectTravelDirection
Boss_SniperHoneyviperCombatCounterRefillReturn:         ; was: locret_367EE
                                        ; Boss_SniperHoneyviperWaitForCounterRefillMotionThreshold+2C   j
                rts
; End of function Boss_SniperHoneyviperWaitForCounterRefillMotionThreshold
; Enters main state $24 with horizontal mode eight and a $40-frame refill delay
Boss_SniperHoneyviperEnterCombatCounterRefill:          ; was: sub_367F0
                                        ; Boss_SniperHoneyviperUpdatePositiveTravelCycle+12   j
                move.w  #$24,4(a5)                      ; '$'
                move.w  #8,$5C(a5)
                move.w  #$40,$5A(a5)                    ; '@'
                rts
; End of function Boss_SniperHoneyviperEnterCombatCounterRefill
; Brakes a negative secondary-entity X velocity toward zero, then waits for the
; bounce velocity $54 to become nonnegative before advancing state
Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocity:   ; was: sub_36804
                                        ; ROM:000364AE   o
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                addi.l  #$1E00,$78(a5)
                bmi.s   Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocityCheckBounce
                clr.l   $78(a5)
Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocityCheckBounce:  ; was: loc_36816
                tst.w   $54(a5)
                bmi.s   Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocityReturn
                addq.w  #2,4(a5)
                clr.l   $78(a5)
Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocityReturn:  ; was: locret_36824
                rts
; End of function Boss_SniperHoneyviperBrakeNegativeSecondaryXVelocity
; On each bounce in the negative-travel branch, consumes combat counter and
; checks the lower screen-X bound and travel delay before repeating or exiting
Boss_SniperHoneyviperUpdateNegativeTravelCycle:         ; was: sub_36826
                                        ; ROM:000364B0   o
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                btst    #0,$5E(a5)
                beq.s   Boss_SniperHoneyviperNegativeTravelCycleReturn
                cmpi.w  #$E,4(a5)
                beq.s   Boss_SniperHoneyviperUpdateNegativeTravelCycleCheckLimits
                subq.w  #1,$5A(a5)
                bpl.s   Boss_SniperHoneyviperResumeTravelBrakingState
                addq.w  #2,4(a5)
                clr.w   $5C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperUpdateNegativeTravelCycleCheckLimits:  ; was: loc_3684A
                subi.w  #$28,(BossCombatCounter).w      ; '('
                bmi.w   Boss_SniperHoneyviperEnterCombatCounterRefill
                cmpi.w  #$1BC8,$58(a5)
                bmi.w   Boss_SniperHoneyviperPrepareNextAttackCycle
                subq.w  #1,$5A(a5)
                bmi.w   Boss_SniperHoneyviperPrepareNextAttackCycle
Boss_SniperHoneyviperResumeTravelBrakingState:          ; was: loc_36866
                subq.w  #2,4(a5)
                move.l  #$FFFDA000,$78(a5)
Boss_SniperHoneyviperNegativeTravelCycleReturn:         ; was: locret_36872
                rts
; End of function Boss_SniperHoneyviperUpdateNegativeTravelCycle
; Brakes a positive secondary-entity X velocity toward zero, then waits for the
; bounce velocity $54 to become nonnegative before advancing state
Boss_SniperHoneyviperBrakePositiveSecondaryXVelocity:   ; was: sub_36874
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                subi.l  #$2000,$78(a5)
                bpl.s   Boss_SniperHoneyviperBrakePositiveSecondaryXVelocityCheckBounce
                clr.l   $78(a5)
Boss_SniperHoneyviperBrakePositiveSecondaryXVelocityCheckBounce:  ; was: loc_36886
                tst.w   $54(a5)
                bmi.s   Boss_SniperHoneyviperBrakePositiveSecondaryXVelocityReturn
                addq.w  #2,4(a5)
                clr.l   $78(a5)
Boss_SniperHoneyviperBrakePositiveSecondaryXVelocityReturn:  ; was: locret_36894
                rts
; End of function Boss_SniperHoneyviperBrakePositiveSecondaryXVelocity
; On each bounce in the positive-travel branch, consumes combat counter and
; checks the upper screen-X bound and travel delay before repeating or exiting
Boss_SniperHoneyviperUpdatePositiveTravelCycle:         ; was: sub_36896
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                btst    #0,$5E(a5)
                beq.s   Boss_SniperHoneyviperPositiveTravelCycleReturn
                subi.w  #$28,(BossCombatCounter).w      ; '('
                bmi.w   Boss_SniperHoneyviperEnterCombatCounterRefill
                cmpi.w  #$1C98,$58(a5)
                bpl.w   Boss_SniperHoneyviperPrepareNextAttackCycle
                subq.w  #1,$5A(a5)
                bmi.w   Boss_SniperHoneyviperPrepareNextAttackCycle
                subq.w  #2,4(a5)
                move.l  #$24000,$78(a5)
Boss_SniperHoneyviperPositiveTravelCycleReturn:         ; was: locret_368CA
                rts
; End of function Boss_SniperHoneyviperUpdatePositiveTravelCycle
; Waits until the accumulated motion coordinate drops below six
Boss_SniperHoneyviperWaitForMotionThreshold:            ; was: sub_368CC
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                cmpi.w  #6,$16C(a5)
                bpl.s   Boss_SniperHoneyviperWaitForMotionThresholdReturn
                addq.w  #2,4(a5)
                clr.w   $174(a5)
                move.w  #$30,$5A(a5)                    ; '0'
Boss_SniperHoneyviperWaitForMotionThresholdReturn:      ; was: locret_368E6
                rts
; End of function Boss_SniperHoneyviperWaitForMotionThreshold
; Count down to the shared boss-message gate while updating Sniper Honeyviper
Boss_SniperHoneyviperBossMessageDelayState:             ; was: sub_368E8
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                subq.w  #1,$5A(a5)
                bpl.s   Boss_SniperHoneyviperBossMessageDelayReturn
                addq.w  #2,4(a5)
                moveq   #2,d0
                jmp     BossMessage_Start
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperBossMessageDelayReturn:            ; was: locret_368FE
                rts
; End of function Boss_SniperHoneyviperBossMessageDelayState
; Wait for the boss message and motion flags before returning to retreat
Boss_SniperHoneyviperWaitForBossMessageState:           ; was: sub_36900
                bsr.w   Boss_SniperHoneyviperUpdateMotionPipeline
                tst.w   (MessageSequenceState).w
                bne.s   Boss_SniperHoneyviperWaitForBossMessageReturn
                btst    #0,$5E(a5)
                bne.s   Boss_SniperHoneyviperWaitForBossMessageReturn
                cmpi.w  #2,$174(a5)
                bne.s   Boss_SniperHoneyviperWaitForBossMessageReturn
                subi.w  #$A0,(CameraXLowerBound).w
                clr.b   (BossColorEffectFlags).w
                move.w  #$104,(Entity57Type).w
                bra.w   Boss_SniperHoneyviperPrepareNextAttackCycle
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperWaitForBossMessageReturn:          ; was: locret_3692E
                                        ; Boss_SniperHoneyviperWaitForBossMessageState+10   j
                rts
; End of function Boss_SniperHoneyviperWaitForBossMessageState
; Starts defeat state $1E, clears sprite flags and secondary X velocity, and
; seeds the shared stage-spawn countdown to four
Boss_SniperHoneyviperBeginDefeat:                       ; was: sub_36930
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #$1E,4(a5)
                clr.l   $78(a5)
                move.w  #4,(StageSpawnCountdown).w
; End of function Boss_SniperHoneyviperBeginDefeat
; Waits for rotation state $C and the bounce gate, then selects horizontal mode
; six and starts the $C0-frame defeat countdown
Boss_SniperHoneyviperWaitForDefeatMotionState:          ; was: sub_3694C
                cmpi.w  #$C,$174(a5)
                beq.s   Boss_SniperHoneyviperWaitForDefeatMotionStateCheckBounce
                cmpi.w  #6,$16C(a5)
                bpl.s   Boss_SniperHoneyviperUpdateDefeatEffectsAndMotion
                move.w  #$A,$174(a5)
Boss_SniperHoneyviperWaitForDefeatMotionStateCheckBounce:  ; was: loc_36962
                btst    #0,$5E(a5)
                beq.s   Boss_SniperHoneyviperUpdateDefeatEffectsAndMotion
                cmpi.w  #$C,$174(a5)
                bne.s   Boss_SniperHoneyviperUpdateDefeatEffectsAndMotion
                move.w  #6,$5C(a5)
                addq.w  #2,4(a5)
                move.w  #$C0,$5A(a5)
; End of function Boss_SniperHoneyviperWaitForDefeatMotionState
; Applies the randomized defeat palette, attempts debris, and runs the motion
; pipeline shared by the defeat states
Boss_SniperHoneyviperUpdateDefeatEffectsAndMotion:      ; was: sub_36982
                                        ; Boss_SniperHoneyviperWaitForDefeatMotionState+1C   j
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                bsr.w   Boss_SniperHoneyviperSpawnDebris
                bra.w   Boss_SniperHoneyviperUpdateMotionPipeline
; End of function Boss_SniperHoneyviperUpdateDefeatEffectsAndMotion
; Handles boss defeat sequence with sprite cleanup and screen effects
Boss_SniperHoneyviperDefeatSequence:                    ; was: sub_36990
                bsr.w   Boss_SniperHoneyviperUpdateDefeatEffectsAndMotion
                subq.w  #1,$5A(a5)
                bmi.s   Boss_SniperHoneyviperDefeatSequenceBeginCleanup
                cmpi.w  #$1C,$5A(a5)
                bpl.w   Boss_SniperHoneyviperDefeatFlowReturn
                moveq   #$1C,d0
                sub.w   $5A(a5),d0
                jmp     (Gfx_ApplyFullActivePaletteFade).l
; ---------------------------------------------------------------------------
Boss_SniperHoneyviperDefeatSequenceBeginCleanup:        ; was: loc_369B0
                addq.w  #2,4(a5)
                clr.w   2(a5)
                move.w  #$40,$5A(a5)                    ; '@'
                clr.w   6(a5)
                move.w  #$30,$4A(a5)                    ; '0'
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                clr.w   (RasterLayoutOffset).w
                move.b  #4,(PlaneBScrollModeFlags).w
                move.w  #$24,d0                         ; '$'
                move.w  #$134,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                jsr     (AlternateTransition_SpawnAtOwner).l
                moveq   #$1C,d0
                jmp     (Gfx_ApplyFullActivePaletteFade).l
; End of function Boss_SniperHoneyviperDefeatSequence
; Handles boss defeat fade out countdown before final transition
Boss_SniperHoneyviperDefeatFadeOut:                     ; was: sub_369F6
                move.w  $5A(a5),d0
                subi.w  #$30,d0                         ; '0'
                bmi.s   Boss_SniperHoneyviperDefeatFadeOutTick
                jsr     (Gfx_ApplyFullActivePaletteFade).l
Boss_SniperHoneyviperDefeatFadeOutTick:                 ; was: loc_36A06
                subq.w  #1,$5A(a5)
                bpl.s   Boss_SniperHoneyviperDefeatFlowReturn
                subq.w  #1,$4A(a5)
                bpl.s   Boss_SniperHoneyviperDefeatFlowReturn
                bset    #4,2(a5)
Boss_SniperHoneyviperDefeatFlowReturn:                  ; was: locret_36A18
                                        ; Boss_SniperHoneyviperDefeatFadeOut+14   j
                rts
; End of function Boss_SniperHoneyviperDefeatFadeOut
