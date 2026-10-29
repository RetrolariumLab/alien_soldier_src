Boss_ShellshogunMainHandler:                            ; was: sub_394D8
                tst.w   4(a5)
                beq.w   Boss_ShellshogunDispatchState
                tst.w   $26(a5)
                beq.w   Boss_ShellshogunDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_ShellshogunUpdatePaletteAndScreenPosition
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_ShellshogunUpdatePaletteAndScreenPosition
                tst.w   (BossHealth).w
                beq.w   Boss_ShellshogunBeginDefeat
Boss_ShellshogunUpdatePaletteAndScreenPosition:         ; was: loc_39500
                                        ; Boss_ShellshogunMainHandler+1E   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$17E(a5)
Boss_ShellshogunDispatchState:                          ; was: loc_39512
                                        ; Boss_ShellshogunMainHandler+C   j
                move.w  4(a5),d0
                movea.w Boss_ShellshogunStateOffsets(pc,d0.w),a0
                adda.l  #Boss_ShellshogunInitState,a0
                jmp     (a0)
; End of function Boss_ShellshogunMainHandler
; ---------------------------------------------------------------------------
Boss_ShellshogunStateOffsets:   dc.w    Boss_ShellshogunInitState-Boss_ShellshogunInitState  ; was: off_39522
                dc.w    Boss_ShellshogunSetupPhase-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunEntrancePoseState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunPreBattleDelayState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunWaitForStageReadyState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDecisionState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunPoseGateState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunSlamPreparationState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunSlamFollowThroughState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDefeatLaunchState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDefeatPaletteState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDefeatDissolveState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDefeatCompletionDelayState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDirectionalAttackWindupState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunDirectionalAttackMotionState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunJumpAttackWindupState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunJumpAttackAirState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunLeapWindupState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunLeapFlightState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunLeapRecoveryState-Boss_ShellshogunInitState
                dc.w    Boss_ShellshogunTimedStageAdvanceState-Boss_ShellshogunInitState

; Initializes Shellshogun boss state and clears objects
Boss_ShellshogunInitState:                              ; was: sub_3954C
                                        ; ROM:Boss_ShellshogunStateOffsets   o
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #$F4,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                clr.w   8(a5)
                clr.w   $A(a5)
                move.b  #1,(SoundFadeOutDelay).w
Boss_ShellshogunInitializationWaitReturn:               ; was: locret_39570
                                        ; Boss_ShellshogunSetupPhase+C   j
                rts
; End of function Boss_ShellshogunInitState
; Sets up boss phase with metasprite initialization
Boss_ShellshogunSetupPhase:                             ; was: sub_39572
                subq.w  #1,$48(a5)
                bmi.w   Boss_ShellshogunInitializationWaitReturn
                tst.w   (DataLoaderControl).w
                bmi.s   Boss_ShellshogunInitializationWaitReturn
                clr.w   $48(a5)
                addq.w  #2,4(a5)
                move.w  #$20,$BC(a5)                    ; ' '
                clr.w   $1DC(a5)
                clr.w   $1DE(a5)
                clr.w   $23C(a5)
                clr.w   $29C(a5)
                addq.w  #1,$26(a5)
                movea.w a5,a4
                move.w  #$300,(MetaspriteBaseTileWord).w
                moveq   #$15,d7
                moveq   #$17,d7
                movea.l #Boss_ShellshogunMetaspriteDescriptors,a0
                movea.l #Boss_ShellshogunPartRadii,a1
                movea.l #Boss_ShellshogunPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                bset    #7,$6E(a5)
                bset    #7,$CE(a5)
                bset    #7,$4EE(a5)
                bsr.w   Boss_ShellshogunEnableLinkedPartFlag7
                bset    #0,2(a5)
                bset    #0,$482(a5)
                bset    #0,$8A2(a5)
                move.w  #$F4,(a5)
                move.w  #$100,$54(a5)
                clr.w   $56(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                movea.w #(TwentyFifthEntityType-M68K_RAM),a0
                move.w  #$6464,d0
                moveq   #2,d7
Boss_ShellshogunInitializeAuxiliaryParts:               ; was: loc_39610
                move.w  #$10,(a0)
                move.w  #$8000,2(a0)
                move.w  d0,$E(a0)
                move.b  #$80,$20(a0)
                move.w  #$500,8(a0)
                move.w  #$F8F8,$A(a0)
                addq.w  #4,d0
                lea     $60(a0),a0
                dbf     d7,Boss_ShellshogunInitializeAuxiliaryParts
                move.w  #0,$9C8(a5)
                move.w  #$FCFC,$9CA(a5)
                movea.w #(TwentyEighthEntityType-M68K_RAM),a0
                moveq   #2,d7
Boss_ShellshogunInitializeSecondaryObjects:             ; was: loc_3964C
                move.w  #$10,(a0)
                clr.w   2(a0)
                clr.w   $10(a0)
                clr.b   $21(a0)
                move.b  #$10,$23(a0)
                move.l  #$FA06FA06,$2C(a0)
                move.l  #$FA06FA06,$28(a0)
                move.w  #$63,$26(a0)                    ; 'c'
                lea     $60(a0),a0
                dbf     d7,Boss_ShellshogunInitializeSecondaryObjects
                move.w  #$8300,$A2E(a5)
                move.w  #$C000,$A22(a5)
                move.l  #Boss_ShellshogunSpriteMapping27,$A28(a5)
                move.b  #$C,$A40(a5)
                movea.l #Boss_ShellshogunObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                movea.l #Boss_ShellshogunIntroTileLoadCommand,a0
                jsr     (Tilemap_QueueIndexedRows).l
                bsr.w   Boss_ShellshogunInitializePartFlags
                move.w  #$2E0,$490(a5)
                move.w  #$2E0,$8B0(a5)
                bra.w   Boss_ShellshogunUpdateSharedPose
; End of function Boss_ShellshogunSetupPhase
; ---------------------------------------------------------------------------
Boss_ShellshogunIntroTileLoadCommand:   dc.b    $61, 0, $20, 0, 2, 1, 3, 1, 2, 4, 5, 6  ; was: byte_396C6

; Checks phase conditions and advances state
Boss_ShellshogunEntrancePoseState:                      ; was: sub_396D2
                bsr.w   Boss_ShellshogunUpdateSharedPose
                tst.w   $17C(a5)
                beq.s   Boss_ShellshogunEntrancePoseReturn
                cmpi.w  #$C,$58(a5)
                beq.s   Boss_ShellshogunTriggerEntranceEffect
                cmpi.w  #4,$58(a5)
                bne.s   Boss_ShellshogunEntrancePoseReturn
                cmpi.w  #$13A8,$17E(a5)
                bpl.s   Boss_ShellshogunTriggerEntranceEffect
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$40,$BE(a5)                    ; '@'
Boss_ShellshogunTriggerEntranceEffect:                  ; was: loc_39708
                                        ; Boss_ShellshogunEntrancePoseState+20   j
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.b  #$A1,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_ShellshogunEntrancePoseReturn:                     ; was: locret_3971E
                                        ; Boss_ShellshogunEntrancePoseState+18   j
                rts
; End of function Boss_ShellshogunEntrancePoseState
; Runs the common update during the timed pre-battle delay
Boss_ShellshogunPreBattleDelayState:                    ; was: sub_39720
                move.w  #$10,$BC(a5)
                move.w  a5,$48(a5)
                move.w  #$CEC0,$4A(a5)
                move.w  #$148,$8B4(a5)
                bsr.w   Boss_ShellshogunDecisionState
                subq.w  #1,$BE(a5)
                bpl.s   Boss_ShellshogunPreBattleDelayReturn
                addq.w  #2,4(a5)
                moveq   #4,d0
                jsr     (BossMessage_Start).l
                move.b  #$8A,d0
                jsr     (Sound_QueueBGMOrStop).l
Boss_ShellshogunPreBattleDelayReturn:                   ; was: locret_39756
                rts
; End of function Boss_ShellshogunPreBattleDelayState
; Waits for the shared stage gate before entering battle
Boss_ShellshogunWaitForStageReadyState:                 ; was: sub_39758
                move.w  #$10,$BC(a5)
                bsr.w   Boss_ShellshogunDecisionState
                tst.w   (MessageSequenceState).w
                bne.s   Boss_ShellshogunWaitForStageReadyReturn
                addq.w  #2,4(a5)
                clr.b   (BossColorEffectFlags).w
                subi.w  #$40,(CameraXLowerBound).w      ; '@'
Boss_ShellshogunWaitForStageReadyReturn:                ; was: locret_39776
                rts
; End of function Boss_ShellshogunWaitForStageReadyState
; Initializes the defeat launch when shared boss health reaches zero
Boss_ShellshogunBeginDefeat:                            ; was: sub_39778
                move.b  #1,(SoundFadeOutDelay).w
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #$48,(ExplosionSoundDelay).w    ; 'H'
                move.w  #$12,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.b  #$C,$A40(a5)
                clr.b   $A41(a5)
                move.w  #$13F,$BC(a5)
                clr.w   6(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bra.s   Boss_ShellshogunInitializeDefeatLaunch
; End of function Boss_ShellshogunBeginDefeat
; Updates the launched boss during the first defeat state
Boss_ShellshogunDefeatLaunchState:                      ; was: sub_397C4
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                tst.w   $BC(a5)
                bpl.s   Boss_ShellshogunUpdateDefeatLaunch
                jsr     (Boss_ApplyDefeatPaletteFade).l
                addq.w  #4,6(a5)
                cmpi.w  #$20,6(a5)                      ; ' '
                bmi.s   Boss_ShellshogunUpdateDefeatLaunch
                addq.w  #2,4(a5)
                move.w  #$60,$BC(a5)                    ; '`'
                clr.w   $26(a5)
                move.w  #$FEB0,(SecondaryCameraXPos).w
                move.w  #$F4,d0
                moveq   #0,d1
                jmp     Object_ClearEntityRecordsExceptTwoTypes
; ---------------------------------------------------------------------------
Boss_ShellshogunUpdateDefeatLaunch:                     ; was: loc_39802
                                        ; Boss_ShellshogunDefeatLaunchState+1C   j
                subq.w  #1,$BC(a5)
                addi.w  #$C,$56(a5)
                andi.w  #$1FE,$56(a5)
                addi.l  #$4000,$1C(a5)
                bmi.s   Boss_ShellshogunRenderDefeatLaunch
                cmpi.w  #$120,$14(a5)
                bmi.s   Boss_ShellshogunRenderDefeatLaunch
                move.w  #$120,$14(a5)
Boss_ShellshogunInitializeDefeatLaunch:                 ; was: loc_3982A
                move.l  #$FFFBA000,$1C(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.w  (RandomNumberState).w,$1A(a5)
                cmpi.w  #$12A8,$17E(a5)
                bmi.s   Boss_ShellshogunSetPositiveDefeatVelocity
                cmpi.w  #$1328,$17E(a5)
                bpl.s   Boss_ShellshogunSetNegativeDefeatVelocity
                btst    #3,(RandomNumberState+1).w
                bne.s   Boss_ShellshogunSetNegativeDefeatVelocity
Boss_ShellshogunSetPositiveDefeatVelocity:              ; was: loc_3985C
                move.w  #2,$18(a5)
                bra.s   Boss_ShellshogunRenderDefeatLaunch
; ---------------------------------------------------------------------------
Boss_ShellshogunSetNegativeDefeatVelocity:              ; was: loc_39864
                                        ; Boss_ShellshogunDefeatLaunchState+96   j
                move.w  #$FFFD,$18(a5)
Boss_ShellshogunRenderDefeatLaunch:                     ; was: loc_3986A
                                        ; Boss_ShellshogunDefeatLaunchState+5E   j
                bsr.w   Boss_ShellshogunSpawnDefeatDebris
                lea     Boss_ShellshogunDefeatLaunchPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bra.w   Boss_ShellshogunUpdatePhysicsAndRender
; End of function Boss_ShellshogunDefeatLaunchState
; Advances the palette phase and starts the post-boss player effect
Boss_ShellshogunDefeatPaletteState:                     ; was: sub_3987C
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$BC(a5)
                bpl.s   Boss_ShellshogunApplyDefeatPaletteFade
                addq.w  #2,4(a5)
                jsr     (TransitionEffect_SpawnAtOwner).l
                move.b  #4,(PlaneAScrollModeFlags).w
Boss_ShellshogunApplyDefeatPaletteFade:                 ; was: loc_39898
                jmp     Boss_ApplyDefeatPaletteFade
; End of function Boss_ShellshogunDefeatPaletteState
; Reduces the defeat-effect step before the final delay
Boss_ShellshogunDefeatDissolveState:                    ; was: sub_3989E
                subq.w  #2,6(a5)
                bne.s   Boss_ShellshogunApplyDefeatDissolvePaletteFade
                addq.w  #2,4(a5)
                move.w  #$E0,$BC(a5)
Boss_ShellshogunApplyDefeatDissolvePaletteFade:         ; was: loc_398AE
                jmp     Boss_ApplyDefeatPaletteFade
; End of function Boss_ShellshogunDefeatDissolveState
; Waits before marking the defeated boss object complete
Boss_ShellshogunDefeatCompletionDelayState:             ; was: sub_398B4
                subq.w  #1,$BC(a5)
                bpl.s   Boss_ShellshogunDefeatCompletionDelayReturn
                bset    #4,2(a5)
Boss_ShellshogunDefeatCompletionDelayReturn:            ; was: locret_398C0
                rts
; End of function Boss_ShellshogunDefeatCompletionDelayState
; Resets Shellshogun boss to idle state with cleared velocities and animations
Boss_ShellshogunReturnToDecisionState:                  ; was: sub_398C2
                                        ; Boss_ShellshogunSlamFollowThroughState+2E   j
                move.w  #$1E0,d0
                sub.w   (BossCombatCounter).w,d0
                asr.w   #4,d0
                addq.w  #2,d0
                move.w  d0,$BC(a5)
Boss_ShellshogunInitializeDecisionState:                ; was: loc_398D2
                                        ; Boss_ShellshogunPoseGateState+52   j
                move.w  #$A,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.w   $29C(a5)
                clr.b   $A41(a5)
                move.w  a5,$48(a5)
                move.w  #$CEC0,$4A(a5)
                move.w  #$148,$8B4(a5)
; End of function Boss_ShellshogunReturnToDecisionState
; Selects the next combat state after the active decision delay
Boss_ShellshogunDecisionState:                          ; was: sub_398FE
                                        ; Boss_ShellshogunWaitForStageReadyState+6   p
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_ShellshogunCheckDecisionTimer
                bsr.w   Boss_ShellshogunUpdateFacingPartFlags
Boss_ShellshogunCheckDecisionTimer:                     ; was: loc_3990C
                subq.w  #1,$BC(a5)
                bpl.s   Boss_ShellshogunUpdateDecisionPose
                move.w  (BossCombatCounter).w,d0
                beq.w   Boss_ShellshogunBeginTimedStageAdvance
                cmpi.w  #$6000,(BossHealth).w
                bpl.s   Boss_ShellshogunSelectAttackByDistance
                cmpi.w  #$1D8,d0
                bpl.w   Boss_ShellshogunInitJumpAttack
Boss_ShellshogunSelectAttackByDistance:                 ; was: loc_3992A
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$D0,d0
                bpl.s   Boss_ShellshogunSelectLongRangeAttack
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                beq.s   Boss_ShellshogunBeginPoseGateState
                btst    #1,d0
                beq.w   Boss_ShellshogunInitDirectionalAttack
                btst    #0,d0
                beq.w   Boss_ShellshogunSlamAttackInit
                bra.w   Boss_ShellshogunInitLeapAttack
; ---------------------------------------------------------------------------
Boss_ShellshogunSelectLongRangeAttack:                  ; was: loc_39954
                btst    #3,(RandomNumberState).w
                bne.w   Boss_ShellshogunInitDirectionalAttack
Boss_ShellshogunBeginPoseGateState:                     ; was: loc_3995E
                move.w  #$C,4(a5)
                move.w  #4,$58(a5)
                move.w  #$FFFF,$C(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunUpdateDecisionPose:                     ; was: loc_39972
                lea     Boss_ShellshogunDecisionPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunUpdatePhysicsAndRender
                move.w  #$148,$494(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunBeginTimedStageAdvance:                 ; was: loc_39988
                move.b  #$42,d0                         ; 'B'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$28,4(a5)                      ; '('
                move.w  #$BA,$BC(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; Shellshogun shell projectile attack with scroll
Boss_ShellshogunTimedStageAdvanceState:                 ; was: loc_399A8
                subq.w  #1,$BC(a5)
                bpl.s   Boss_ShellshogunUpdateTimedStageAdvance
                move.w  #$50,$BC(a5)                    ; 'P'
                bra.w   Boss_ShellshogunInitializeDecisionState
; ---------------------------------------------------------------------------
Boss_ShellshogunUpdateTimedStageAdvance:                ; was: loc_399B8
                addi.w  #3,(BossCombatCounter).w
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                lea     Boss_ShellshogunTimedStageAdvancePoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunUpdatePhysicsAndRender
                move.w  #$148,$494(a5)
                move.l  #Boss_ShellshogunSpriteMapping01,$68(a5)
                rts
; End of function Boss_ShellshogunDecisionState
; Evaluates pose events and position before returning or starting a slam
Boss_ShellshogunPoseGateState:                          ; was: sub_399E8
                bsr.w   Boss_ShellshogunUpdateSharedPose
                tst.w   $17C(a5)
                beq.s   Boss_ShellshogunPoseGateReturn
                cmpi.w  #$C,$58(a5)
                beq.s   Boss_ShellshogunTriggerPoseGateEffect
                cmpi.w  #4,$58(a5)
                bne.s   Boss_ShellshogunPoseGateReturn
                tst.w   (BossCombatCounter).w
                bne.s   Boss_ShellshogunEvaluatePoseGatePosition
                clr.w   $58(a5)
                move.w  #4,$BC(a5)
                bra.w   Boss_ShellshogunReturnToDecisionState
; ---------------------------------------------------------------------------
Boss_ShellshogunEvaluatePoseGatePosition:               ; was: loc_39A16
                move.w  $17E(a5),d0
                tst.w   $54(a5)
                beq.s   Boss_ShellshogunCheckLeftPoseGateThreshold
                cmpi.w  #$1288,d0
                bpl.s   Boss_ShellshogunCheckPoseGateSlamDistance
                bra.s   Boss_ShellshogunReturnFromPoseGate
; ---------------------------------------------------------------------------
Boss_ShellshogunCheckLeftPoseGateThreshold:             ; was: loc_39A28
                cmpi.w  #$1348,d0
                bmi.s   Boss_ShellshogunCheckPoseGateSlamDistance
Boss_ShellshogunReturnFromPoseGate:                     ; was: loc_39A2E
                move.w  #4,$58(a5)
                move.w  #$60,$BC(a5)                    ; '`'
                bra.w   Boss_ShellshogunInitializeDecisionState
; ---------------------------------------------------------------------------
Boss_ShellshogunTriggerPoseGateEffect:                  ; was: loc_39A3E
                                        ; Boss_ShellshogunPoseGateState+74   j
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.b  #$A1,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_ShellshogunPoseGateReturn:                         ; was: locret_39A54
                                        ; Boss_ShellshogunPoseGateState+18   j
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunCheckPoseGateSlamDistance:              ; was: loc_39A56
                                        ; Boss_ShellshogunPoseGateState+44   j
                jsr     (Physics_GetPlayerDelta).l
                beq.s   Boss_ShellshogunTriggerPoseGateEffect
                cmpi.w  #$88,d0
                bpl.s   Boss_ShellshogunTriggerPoseGateEffect
                bsr.w   Boss_ShellshogunSlamAttackInit
                bra.s   Boss_ShellshogunTriggerPoseGateEffect
; End of function Boss_ShellshogunPoseGateState
; Initiates Shellshogun slam attack sequence with physics and sound effects
Boss_ShellshogunSlamAttackInit:                         ; was: sub_39A6A
                                        ; Boss_ShellshogunPoseGateState+7C   p
                move.w  #$E,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  #$CEC0,$4A(a5)
                move.w  #$148,$8B4(a5)
; Shellshogun slam attack preparation
Boss_ShellshogunSlamPreparationState:                   ; was: loc_39A8A
                bsr.w   Boss_ShellshogunUpdateLinkedPartRotation
                cmpi.w  #$14,$58(a5)
                bmi.s   Boss_ShellshogunUpdateSlamAnimation
                addq.w  #2,4(a5)
                move.w  #$CEC0,$48(a5)
                move.w  $296(a5),$29C(a5)
                move.b  #$C0,$A41(a5)
                subi.w  #$50,(BossCombatCounter).w      ; 'P'
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.s   Boss_ShellshogunUpdateSlamAnimation
; End of function Boss_ShellshogunSlamAttackInit
; Updates the slam follow-through pose and linked-part rotation
Boss_ShellshogunSlamFollowThroughState:                 ; was: sub_39ABE
                bsr.s   Boss_ShellshogunUpdateSlamAnimation
                tst.w   $17C(a5)
                beq.s   Boss_ShellshogunUpdateSlamRotation
                cmpi.w  #$18,$58(a5)
                bne.s   Boss_ShellshogunUpdateSlamRotation
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #8,(PlaneAShakeLevel).w
                move.w  #8,(PlaneBShakeLevel).w
                clr.b   $A41(a5)
Boss_ShellshogunUpdateSlamRotation:                     ; was: loc_39AE8
                                        ; Boss_ShellshogunSlamFollowThroughState+E   j
                tst.w   $58(a5)
                bmi.w   Boss_ShellshogunReturnToDecisionState
                move.w  $29C(a5),d0
                beq.s   Boss_ShellshogunStoreSlamRotation
                addi.w  #$10,d0
                andi.w  #$1F0,d0
Boss_ShellshogunStoreSlamRotation:                      ; was: loc_39AFE
                move.w  d0,$29C(a5)
                rts
; End of function Boss_ShellshogunSlamFollowThroughState
; Advances and renders the slam pose stream
Boss_ShellshogunUpdateSlamAnimation:                    ; was: sub_39B04
                                        ; Boss_ShellshogunSlamAttackInit+52   j
                lea     Boss_ShellshogunSlamPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunRenderSprites
                move.l  #Boss_ShellshogunSpriteMapping01,$68(a5)
                rts
; End of function Boss_ShellshogunUpdateSlamAnimation
; Initializes the facing-dependent directional attack
Boss_ShellshogunInitDirectionalAttack:                  ; was: sub_39B1C
                                        ; Boss_ShellshogunDecisionState+5C   j
                move.w  #$1A,4(a5)
                move.w  #1,$11E(a5)
                move.w  #0,$29C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; End of function Boss_ShellshogunInitDirectionalAttack
; Advances the directional attack windup pose
Boss_ShellshogunDirectionalAttackWindupState:           ; was: sub_39B38
                tst.w   $11E(a5)
                bpl.s   Boss_ShellshogunUpdateDirectionalAttackWindup
                addq.w  #2,4(a5)
                clr.w   $11C(a5)
                move.b  #$C0,$A41(a5)
                subi.w  #$20,$29C(a5)                   ; ' '
                andi.w  #$1E0,$29C(a5)
Boss_ShellshogunUpdateDirectionalAttackWindup:          ; was: loc_39B58
                lea     Boss_ShellshogunDirectionalAttackPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunRenderSprites
                move.l  #Boss_ShellshogunSpriteMapping00,$68(a5)
                rts
; End of function Boss_ShellshogunDirectionalAttackWindupState
; Applies the facing-dependent horizontal motion and attack effects
Boss_ShellshogunDirectionalAttackMotionState:           ; was: sub_39B70
                tst.w   $58(a5)
                bpl.s   Boss_ShellshogunUpdateDirectionalAttackRotation
                clr.l   $18(a5)
                bra.w   Boss_ShellshogunReturnToDecisionState
; ---------------------------------------------------------------------------
Boss_ShellshogunUpdateDirectionalAttackRotation:        ; was: loc_39B7E
                tst.w   $29C(a5)
                beq.s   Boss_ShellshogunCheckDirectionalAttackLaunch
                subi.w  #$10,$29C(a5)
                andi.w  #$1E0,$29C(a5)
Boss_ShellshogunCheckDirectionalAttackLaunch:           ; was: loc_39B90
                tst.w   $17C(a5)
                beq.s   Boss_ShellshogunApplyDirectionalAttackVelocity
                cmpi.w  #$FFFD,$11E(a5)
                bne.s   Boss_ShellshogunApplyDirectionalAttackVelocity
                move.b  #$D0,d0
                jsr     (Sound_QueueSFXRequest).l
                subi.w  #$62,(BossCombatCounter).w      ; 'b'
                move.w  #3,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
                addq.w  #1,$11C(a5)
                move.l  #$FFFA4000,$18(a5)
                tst.w   $54(a5)
                bne.s   Boss_ShellshogunApplyDirectionalAttackVelocity
                neg.l   $18(a5)
Boss_ShellshogunApplyDirectionalAttackVelocity:         ; was: loc_39BD0
                                        ; Boss_ShellshogunDirectionalAttackMotionState+2C   j
                tst.w   $54(a5)
                beq.s   Boss_ShellshogunApplyNegativeDirectionalVelocity
                addi.l  #$4000,$18(a5)
                bmi.s   Boss_ShellshogunRenderDirectionalAttack
Boss_ShellshogunStopDirectionalAttackVelocity:          ; was: loc_39BE0
                clr.l   $18(a5)
                tst.w   $11C(a5)
                beq.s   Boss_ShellshogunRenderDirectionalAttack
                clr.b   $A41(a5)
                bra.s   Boss_ShellshogunRenderDirectionalAttack
; ---------------------------------------------------------------------------
Boss_ShellshogunApplyNegativeDirectionalVelocity:       ; was: loc_39BF0
                subi.l  #$4000,$18(a5)
                bmi.s   Boss_ShellshogunStopDirectionalAttackVelocity
Boss_ShellshogunRenderDirectionalAttack:                ; was: loc_39BFA
                                        ; Boss_ShellshogunDirectionalAttackMotionState+78   j
                lea     Boss_ShellshogunDirectionalAttackPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunRenderSprites
                move.l  #Boss_ShellshogunSpriteMapping01,$68(a5)
                bra.w   Boss_ShellshogunUpdateSpriteFlip
; End of function Boss_ShellshogunDirectionalAttackMotionState
; Initialize Shellshogun jump attack with position and animation setup
Boss_ShellshogunInitJumpAttack:                         ; was: sub_39C14
                move.w  #$1E,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CEC0,$4A(a5)
                move.w  #$148,$8B4(a5)
                move.w  #$C,$11E(a5)
                move.b  #$C0,$A41(a5)
                move.b  #8,$A40(a5)
                move.w  #0,$29C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
; End of function Boss_ShellshogunInitJumpAttack
; Advances the jump-attack windup pose
Boss_ShellshogunJumpAttackWindupState:                  ; was: sub_39C4C
                tst.w   $11E(a5)
                bmi.s   Boss_ShellshogunBeginJumpAttackAirState
                bsr.w   Boss_ShellshogunUpdateFacingPartFlags
                subi.w  #$10,$29C(a5)
                andi.w  #$1E0,$29C(a5)
                bne.s   Boss_ShellshogunSetJumpWindupPartFrame
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_ShellshogunSetJumpWindupPartFrame:                 ; was: loc_39C6E
                move.w  #$C860,$23E(a5)
                cmpi.w  #9,$58(a5)
                bmi.s   Boss_ShellshogunRenderJumpWindup
                move.w  #$CC80,$23E(a5)
Boss_ShellshogunRenderJumpWindup:                       ; was: loc_39C82
                lea     Boss_ShellshogunJumpWindupPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunRenderSprites
                move.l  #Boss_ShellshogunSpriteMapping01,$68(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunBeginJumpAttackAirState:                ; was: loc_39C9A
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$C860,$23E(a5)
; Shellshogun jump attack air phase with rotation
Boss_ShellshogunJumpAttackAirState:                     ; was: loc_39CAE
                subq.w  #1,(BossCombatCounter).w
                tst.w   $58(a5)
                bpl.s   Boss_ShellshogunUpdateJumpAirRotation
                move.b  #$C,$A40(a5)
                clr.b   $A41(a5)
                bra.w   Boss_ShellshogunReturnToDecisionState
; ---------------------------------------------------------------------------
Boss_ShellshogunUpdateJumpAirRotation:                  ; was: loc_39CC6
                subi.w  #$10,$29C(a5)
                andi.w  #$1E0,$29C(a5)
                bne.s   Boss_ShellshogunRenderJumpAir
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_ShellshogunRenderJumpAir:                          ; was: loc_39CDE
                lea     Boss_ShellshogunJumpAirPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bra.w   Boss_ShellshogunRenderSprites
; End of function Boss_ShellshogunJumpAttackWindupState
; Initializes the leap windup selected by the decision state
Boss_ShellshogunInitLeapAttack:                         ; was: sub_39CEC
                move.w  #$22,4(a5)                      ; '"'
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #2,$11E(a5)
; End of function Boss_ShellshogunInitLeapAttack
; Advances the leap windup before installing upward velocity
Boss_ShellshogunLeapWindupState:                        ; was: sub_39D02
                tst.w   $11E(a5)
                bmi.s   Boss_ShellshogunBeginLeapFlight
                lea     Boss_ShellshogunLeapPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bsr.w   Boss_ShellshogunUpdatePhysicsAndRender
                move.l  #Boss_ShellshogunSpriteMapping00,$68(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShellshogunBeginLeapFlight:                        ; was: loc_39D20
                addq.w  #2,4(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.l  #$FFFA4000,$1C(a5)
                move.w  #$18,$BE(a5)
                move.w  #3,$11C(a5)
                bsr.w   Boss_ShellshogunUpdateFacingPartFlags
; End of function Boss_ShellshogunLeapWindupState
; Applies leap-flight velocity until the landing threshold
Boss_ShellshogunLeapFlightState:                        ; was: sub_39D44
                subq.w  #1,$11C(a5)
                bne.s   Boss_ShellshogunUpdateLeapFlightRotation
                move.w  #3,(PlaneAShakeLevel).w
                move.w  #3,(PlaneBShakeLevel).w
                subi.w  #$7D,(BossCombatCounter).w      ; '}'
                moveq   #0,d0
                move.w  (RandomNumberState).w,d0
                asl.l   #1,d0
                addi.l  #$13000,d0
                move.l  d0,$18(a5)
                tst.w   $54(a5)
                beq.s   Boss_ShellshogunUpdateLeapFlightRotation
                neg.l   $18(a5)
Boss_ShellshogunUpdateLeapFlightRotation:               ; was: loc_39D78
                                        ; Boss_ShellshogunLeapFlightState+2E   j
                subq.w  #1,$BE(a5)
                bpl.s   Boss_ShellshogunApplyLeapFlightGravity
                cmpi.w  #$FFE0,$BE(a5)
                bmi.s   Boss_ShellshogunApplyLeapFlightGravity
                addi.w  #$10,$56(a5)
                andi.w  #$1F0,$56(a5)
Boss_ShellshogunApplyLeapFlightGravity:                 ; was: loc_39D92
                                        ; Boss_ShellshogunLeapFlightState+40   j
                addi.l  #$3000,$1C(a5)
                bmi.s   Boss_ShellshogunRenderLeapFlight
                cmpi.w  #$148,$8B4(a5)
                bpl.s   Boss_ShellshogunCompleteLeapLanding
Boss_ShellshogunRenderLeapFlight:                       ; was: loc_39DA4
                lea     Boss_ShellshogunLeapPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bra.w   Boss_ShellshogunUpdatePhysicsAndRender
; ---------------------------------------------------------------------------
Boss_ShellshogunCompleteLeapLanding:                    ; was: loc_39DB2
                addq.w  #2,4(a5)
                move.w  a5,$48(a5)
                move.w  #$CEC0,$4A(a5)
                move.w  #$148,$8B4(a5)
                clr.l   $1C(a5)
                move.w  #5,(PlaneAShakeLevel).w
                move.w  #5,(PlaneBShakeLevel).w
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.b  #$A1,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_ShellshogunLeapFlightState
; Decelerates horizontal velocity during the leap recovery pose
Boss_ShellshogunLeapRecoveryState:                      ; was: sub_39DEA
                tst.w   $18(a5)
                bpl.s   Boss_ShellshogunReducePositiveLeapRecoveryVelocity
                addi.l  #$1000,$18(a5)
                bmi.s   Boss_ShellshogunRenderLeapRecovery
Boss_ShellshogunStopLeapRecoveryVelocity:               ; was: loc_39DFA
                clr.l   $18(a5)
                bra.s   Boss_ShellshogunRenderLeapRecovery
; ---------------------------------------------------------------------------
Boss_ShellshogunReducePositiveLeapRecoveryVelocity:     ; was: loc_39E00
                subi.l  #$1000,$18(a5)
                bmi.s   Boss_ShellshogunStopLeapRecoveryVelocity
Boss_ShellshogunRenderLeapRecovery:                     ; was: loc_39E0A
                                        ; Boss_ShellshogunLeapRecoveryState+14   j
                tst.w   $58(a5)
                bmi.w   Boss_ShellshogunReturnToDecisionState
                lea     Boss_ShellshogunLeapRecoveryPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                bra.w   Boss_ShellshogunUpdatePhysicsAndRender
; End of function Boss_ShellshogunLeapRecoveryState
; Advances the shared entrance/pose-gate stream and linked-part fields
Boss_ShellshogunUpdateSharedPose:                       ; was: sub_39E20
                                        ; sub_396D2   p
                lea     Boss_ShellshogunSharedPoses(pc),a1
                nop
                bsr.w   Boss_ShellshogunUpdatePose
                move.w  #$148,$494(a5)
                move.w  #$CAA0,$48(a5)
                move.w  #$CAA0,$4A(a5)
                cmpi.w  #9,$58(a5)
                bpl.s   Boss_ShellshogunUpdateSharedPosePhysics
                move.w  #$148,$8B4(a5)
                move.w  #$CEC0,$48(a5)
                move.w  #$CEC0,$4A(a5)
Boss_ShellshogunUpdateSharedPosePhysics:                ; was: loc_39E56
                bra.w   *+4
; End of function Boss_ShellshogunUpdateSharedPose
; Updates Shellshogun physics before falling through to rendering
Boss_ShellshogunUpdatePhysicsAndRender:                 ; was: sub_39E5A
                                        ; Boss_ShellshogunDecisionState+7E   p
                bsr.w   Boss_ShellshogunUpdateLinkedPartRotation
; End of function Boss_ShellshogunUpdatePhysicsAndRender
; Renders boss metasprites and updates display
