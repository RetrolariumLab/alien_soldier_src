; Wolf Garopa controller and top-level state dispatcher
Boss_WolfGaropaUpdate:                                  ; was: sub_4F8F0
                tst.w   4(a5)
                beq.w   Boss_WolfGaropaDispatchState
                tst.w   8(a5)
                beq.s   Boss_WolfGaropaDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_WolfGaropaRunDefeatEffects
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_WolfGaropaRunDefeatEffects
                tst.w   (BossHealth).w
                beq.w   Boss_WolfGaropaBeginDefeatTransition
Boss_WolfGaropaRunDefeatEffects:                        ; was: loc_4F916
                                        ; Boss_WolfGaropaUpdate+1C   j
                bsr.w   Boss_WolfGaropaUpdateDefeatTransition
                jsr     (Gfx_ProcessDefaultColorFade).l
Boss_WolfGaropaDispatchState:                           ; was: loc_4F920
                                        ; Boss_WolfGaropaUpdate+C   j
                move.w  4(a5),d0
                movea.w Boss_WolfGaropaStateTable(pc,d0.w),a0
                adda.l  #Boss_WolfGaropaInitialize,a0
                jmp     (a0)
; ---------------------------------------------------------------------------
Boss_WolfGaropaStateTable:  dc.w    Boss_WolfGaropaInitialize-Boss_WolfGaropaInitialize  ; was: off_4F930
                dc.w    Boss_WolfGaropaUpdateInitialPose-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdateLeftEntry-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdateBattleStartWait-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdateOrbAttackCycle-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdateUpperType424Sequence-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdateUpperSequenceCooldown-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdateLowerType424Sequence-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaBeginPostDefeatDelay-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaUpdatePostDefeatDelay-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaApproachInitialOrbAngle140-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaWaitBeforeOrbSweep-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaApproachOrbAngleC0AndExplode-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaApproachOrbAngle140-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaApproachOrbAngle180-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaSelectType424Sequence-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaInactiveState20-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaEmptyState-Boss_WolfGaropaInitialize
                dc.w    Boss_WolfGaropaEmptyState-Boss_WolfGaropaInitialize
; End of function Boss_WolfGaropaUpdate
; Build the composite boss object and initialize its auxiliary orb records
Boss_WolfGaropaInitialize:                              ; was: sub_4F956
                                        ; sub_4F8F0:Boss_WolfGaropaStateTable   o
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_WolfGaropaReturn
                move.b  #$18,(PlayerOAMBucketOffset).w
                move.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$288,(MetaspriteBaseTileWord).w
                moveq   #$18,d7
                movea.l #Boss_WolfGaropaMetaspriteDescriptors,a0
                movea.l #Boss_WolfGaropaPartRadii,a1
                movea.l #Boss_WolfGaropaPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$3E8,(a5)
                move.w  #$C00,2(a5)
                move.w  #$1F8,$B6(a5)
                move.w  #$1F8,$116(a5)
                move.w  #$120,$176(a5)
                move.w  #$120,$1D6(a5)
                moveq   #3,d0
                bset    d0,$36E(a5)
                bset    d0,$54E(a5)
                bset    d0,$72E(a5)
                bset    d0,$90E(a5)
                move.w  #$10,d0
                move.w  #$C000,d1
                move.w  #$AA88,d2
                moveq   #$18,d3
                move.w  d0,$960(a5)
                clr.w   $962(a5)
                move.w  d0,$9C0(a5)
                move.w  d1,$9C2(a5)
                move.w  d2,$9CE(a5)
                move.b  d3,$9E0(a5)
                addq.b  #4,$9E0(a5)
                move.l  #Boss_WolfGaropaInitialPartMapping,$9C8(a5)
                move.w  d0,$A20(a5)
                move.w  d1,$A22(a5)
                move.w  d2,$A2E(a5)
                move.b  #8,$A40(a5)
                move.l  #Boss_WolfGaropaOrbDirectionMapping0,$A28(a5)
                move.w  #$2A88,d2
                move.w  d0,$A80(a5)
                move.w  d1,$A82(a5)
                move.w  d2,$A8E(a5)
                move.b  d3,$AA0(a5)
                addq.b  #4,$AA0(a5)
                move.l  #Boss_WolfGaropaNearPlayerMapping,$A88(a5)
                move.w  d0,$AE0(a5)
                move.w  d1,$AE2(a5)
                move.w  d2,$AEE(a5)
                move.b  d3,$B00(a5)
                move.l  #Boss_WolfGaropaOrbAlternateMapping,$AE8(a5)
                move.w  #$10,$B40(a5)
                move.w  #$8000,$B42(a5)
                move.w  #0,$B50(a5)
                move.w  #$500,$B48(a5)
                movea.l #Boss_WolfGaropaObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                movea.l #SharedTilemapWorkspace,a0
                move.w  #$E000,d0
                move.w  #$1E0,d1
                moveq   #$10,d7
                jsr     (Gfx_UpdateTilemapIndices).l
                lea     Boss_WolfGaropaInitialTileLoad(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #2,$1DE(a5)
                bra.w   Boss_WolfGaropaBeginLeftEntry
; ---------------------------------------------------------------------------
Boss_WolfGaropaReturn:                                  ; was: locret_4FA94
                rts
; End of function Boss_WolfGaropaInitialize
; ---------------------------------------------------------------------------
Boss_WolfGaropaInitialTileLoad: dc.w    $6220, $2000, $302, 1, $200, $304, $506, $708, $90A  ; was: word_4FA96

; Unreferenced initializer for state 2 at fixed position ($100,$100)
Boss_WolfGaropaInitializeAtPosition100:                 ; was: sub_4FAA8
                move.w  #2,4(a5)
                move.w  #$100,$10(a5)
                move.w  #$100,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                bsr.w   Boss_WolfGaropaInitializeMovementSequence
; End of function Boss_WolfGaropaInitializeAtPosition100
; Advance the opening pose script and update the composite frame
Boss_WolfGaropaUpdateInitialPose:                       ; was: sub_4FAD8
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                lea     Boss_WolfGaropaLaunchPoses(pc),a1
                nop
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; End of function Boss_WolfGaropaUpdateInitialPose
; Start the left-side entry motion and its pose sequence
Boss_WolfGaropaBeginLeftEntry:                          ; was: sub_4FAEE
                move.w  #4,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$10,$10(a5)
                move.w  #$110,$14(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                move.w  #$E0,$47C(a5)
                bsr.w   Boss_WolfGaropaInitializeMovementSequence
; End of function Boss_WolfGaropaBeginLeftEntry
; Continue the left-side entry until its pose event advances the state
Boss_WolfGaropaUpdateLeftEntry:                         ; was: sub_4FB1C
                btst    #0,$41C(a5)
                beq.s   Boss_WolfGaropaUpdateMovementAndOrbTarget
                btst    #3,$23E(a5)
                beq.s   Boss_WolfGaropaUpdateMovementAndOrbTarget
                addq.w  #2,4(a5)
                moveq   #0,d0
                jsr     (BossMessage_Start).l
                bra.s   Boss_WolfGaropaUpdateMovementAndOrbTarget
; End of function Boss_WolfGaropaUpdateLeftEntry
; Wait for the battle-ready flag, then begin the orb attack cycle
Boss_WolfGaropaUpdateBattleStartWait:                   ; was: sub_4FB3A
                tst.w   (MessageSequenceState).w
                bne.s   Boss_WolfGaropaUpdateMovementAndOrbTarget
                addq.w  #2,4(a5)
                clr.b   (BossColorEffectFlags).w
                bra.w   Boss_WolfGaropaBeginOrbAttackCycle
; ---------------------------------------------------------------------------
Boss_WolfGaropaUpdateMovementAndOrbTarget:              ; was: loc_4FB4C
                                        ; Boss_WolfGaropaUpdateLeftEntry+E   j
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
Boss_WolfGaropaUpdateOrbTarget:                         ; was: loc_4FB50
                                        ; Boss_WolfGaropaUpdateUpperType424Sequence+2E   j
                btst    #2,$23E(a5)
                beq.s   Boss_WolfGaropaChooseRandomOrbAngleTarget
                move.w  #$1C,$53C(a5)
Boss_WolfGaropaChooseRandomOrbAngleTarget:              ; was: loc_4FB5E
                move.b  (RandomNumberState).w,d2
                andi.w  #$E,d2
                addi.w  #$1A0,d2
                move.w  d2,$53E(a5)
                move.w  (RandomNumberState).w,d2
                andi.w  #$E,d2
                addi.w  #$170,d2
                moveq   #0,d3
                moveq   #4,d7
                bra.w   Boss_WolfGaropaApproachOrbAngle
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginOrbAttackCycle:                     ; was: loc_4FB82
                                        ; Boss_WolfGaropaUpdateUpperType424Sequence+46   j
                move.w  (RandomNumberState).w,d0
                andi.w  #$1C0,d0
                addi.w  #$100,d0
                move.w  d0,$11C(a5)
                move.w  #$80,$4DC(a5)
                move.w  #8,4(a5)
                clr.w   $11E(a5)
; Maintain the timed orb attack cycle and its emitted projectile pair
Boss_WolfGaropaUpdateOrbAttackCycle:                    ; was: loc_4FBA2
                tst.w   (BossHealth).w
                beq.s   Boss_WolfGaropaUpdateOrbCycleMotion
                subq.w  #1,$11C(a5)
                bpl.s   Boss_WolfGaropaUpdateOrbCycleMotion
                tst.w   $4DE(a5)
                bpl.s   Boss_WolfGaropaUpdateOrbCycleMotion
                tst.w   $6BC(a5)
                bne.s   Boss_WolfGaropaUpdateOrbCycleMotion
                clr.b   $65E(a5)
                clr.w   $6BC(a5)
                bra.w   Boss_WolfGaropaBeginOrbSweepSequence
; ---------------------------------------------------------------------------
Boss_WolfGaropaUpdateOrbCycleMotion:                    ; was: loc_4FBC6
                                        ; Boss_WolfGaropaUpdateBattleStartWait+72   j
                subq.w  #1,$11E(a5)
                bpl.s   Boss_WolfGaropaUpdateOrbCycleEffects
                move.b  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                move.w  d0,$11E(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$C8,d0
                move.w  d0,$47C(a5)
Boss_WolfGaropaUpdateOrbCycleEffects:                   ; was: loc_4FBE8
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bsr.w   Boss_WolfGaropaUpdateOrbFacingFlag
                tst.w   (BossHealth).w
                beq.w   Boss_WolfGaropaUpdateOrbTarget
                bsr.w   Boss_WolfGaropaSteerOrbAngleTowardPlayer
                move.w  $A76(a5),d0
                addi.w  #$100,d0
                andi.w  #$1FE,d0
                move.w  d0,$53E(a5)
                tst.w   $4DC(a5)
                bmi.s   Boss_WolfGaropaUpdateOrbShotCountdown
                subq.w  #1,$4DC(a5)
                bpl.s   Boss_WolfGaropaUpdateOrbChargeEffects
                move.w  #$14,$4DE(a5)
Boss_WolfGaropaReturnFromOrbAttackCycle:                ; was: locret_4FC1E
                                        ; Boss_WolfGaropaUpdateBattleStartWait+12C   j
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaUpdateOrbChargeEffects:                  ; was: loc_4FC20
                cmpi.w  #$40,$4DC(a5)                   ; '@'
                bmi.w   Boss_WolfGaropaSpawnOrbitStar
                bne.s   Boss_WolfGaropaReturnFromOrbAttackCycle
                move.w  #$18,$5FE(a5)
                move.w  #$2000,$65C(a5)
                move.b  #8,$65E(a5)
                move.b  #$ED,d0
                jmp     (Sound_QueueSFXRequest).l
; ---------------------------------------------------------------------------
Boss_WolfGaropaUpdateOrbShotCountdown:                  ; was: loc_4FC48
                cmpi.w  #$14,$4DE(a5)
                bne.s   Boss_WolfGaropaTickOrbShotCountdown
                tst.w   d3
                beq.w   Boss_WolfGaropaSpawnOrbitStar
                clr.b   $65E(a5)
                clr.w   $6BC(a5)
Boss_WolfGaropaTickOrbShotCountdown:                    ; was: loc_4FC5E
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_WolfGaropaReturnFromOrbAttackCycle
                subq.w  #1,$4DE(a5)
                bpl.w   Boss_WolfGaropaSpawnOrbProjectilePair
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$80,d0
                move.w  d0,$4DC(a5)
                move.w  #$3F,$5FC(a5)                   ; '?'
                rts
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginOrbSweepSequence:                   ; was: loc_4FC88
                move.w  #$14,4(a5)
                bset    #3,$9CE(a5)
                move.w  #$12C,$47C(a5)
; Approach the first fixed orb angle in the sweep sequence
Boss_WolfGaropaApproachInitialOrbAngle140:              ; was: loc_4FC9A
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                move.w  #$140,d2
                moveq   #0,d3
                moveq   #8,d7
                bsr.w   Boss_WolfGaropaApproachOrbAngle
                tst.w   d3
                beq.s   Boss_WolfGaropaReturnFromInitialOrbApproach
                addq.w  #2,4(a5)
                move.w  #$20,$11E(a5)                   ; ' '
Boss_WolfGaropaReturnFromInitialOrbApproach:            ; was: locret_4FCB8
                rts
; End of function Boss_WolfGaropaUpdateBattleStartWait
; Hold the movement sequence for a short delay before the orb sweep
Boss_WolfGaropaWaitBeforeOrbSweep:                      ; was: sub_4FCBA
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                subq.w  #1,$11E(a5)
                bpl.s   Boss_WolfGaropaReturnFromOrbSweepWait
                addq.w  #2,4(a5)
                move.w  #1,$11E(a5)
Boss_WolfGaropaReturnFromOrbSweepWait:                  ; was: locret_4FCCE
                rts
; End of function Boss_WolfGaropaWaitBeforeOrbSweep
; Approach orb angle $C0 and emit the orbit-centered explosion effect
Boss_WolfGaropaApproachOrbAngleC0AndExplode:            ; was: sub_4FCD0
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                move.w  #$C0,d2
                moveq   #0,d3
                moveq   #$16,d7
                bsr.w   Boss_WolfGaropaApproachOrbAngle
                tst.w   d3
                beq.s   Boss_WolfGaropaReturnFromOrbAngleC0
                move.b  #$35,d0                         ; '5'
                jsr     (Sound_QueueSFXRequest).l
                jsr     Boss_WolfGaropaSpawnOrbExplosion(pc)  ; (pc)
                nop
                subq.w  #1,$11E(a5)
                bpl.s   Boss_WolfGaropaAdvanceOrbSweep
                addq.w  #4,4(a5)
                bclr    #3,$AEE(a5)
                bra.w   Boss_WolfGaropaSelectOrbNeutralMapping
; ---------------------------------------------------------------------------
Boss_WolfGaropaAdvanceOrbSweep:                         ; was: loc_4FD08
                addq.w  #2,4(a5)
Boss_WolfGaropaReturnFromOrbAngleC0:                    ; was: locret_4FD0C
                rts
; End of function Boss_WolfGaropaApproachOrbAngleC0AndExplode
; Return the orb toward angle $140 during the repeated sweep
Boss_WolfGaropaApproachOrbAngle140:                     ; was: sub_4FD0E
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bsr.w   Boss_WolfGaropaSelectOrbNeutralMapping
                move.w  #$140,d2
                moveq   #0,d3
                moveq   #$10,d7
                bsr.w   Boss_WolfGaropaApproachOrbAngle
                tst.w   d3
                beq.s   Boss_WolfGaropaReturnFromOrbAngle140
                subq.w  #2,4(a5)
Boss_WolfGaropaReturnFromOrbAngle140:                   ; was: locret_4FD2A
                rts
; End of function Boss_WolfGaropaApproachOrbAngle140
; Finish the orb sweep by approaching angle $180
Boss_WolfGaropaApproachOrbAngle180:                     ; was: sub_4FD2C
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bsr.w   Boss_WolfGaropaSelectOrbNeutralMapping
                move.w  #$180,d2
                moveq   #0,d3
                moveq   #$C,d7
                bsr.w   Boss_WolfGaropaApproachOrbAngle
                tst.w   d3
                beq.s   Boss_WolfGaropaReturnFromOrbAngle180
                addq.w  #2,4(a5)
                move.w  #$30,$11E(a5)                   ; '0'
Boss_WolfGaropaReturnFromOrbAngle180:                   ; was: locret_4FD4E
                rts
; End of function Boss_WolfGaropaApproachOrbAngle180
; After a delay, randomly select the upper or lower type-$424 sequence
Boss_WolfGaropaSelectType424Sequence:                   ; was: sub_4FD50
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bsr.w   Boss_WolfGaropaSelectOrbNeutralMapping
                subq.w  #1,$11E(a5)
                bpl.s   Boss_WolfGaropaInactiveState20
                bset    #3,$AEE(a5)
                btst    #0,(RandomNumberState+1).w
                bne.w   Boss_WolfGaropaBeginLowerType424Sequence
                bra.w   Boss_WolfGaropaBeginUpperType424Sequence
; ---------------------------------------------------------------------------
; Inactive state-table entry following the type-$424 selector
Boss_WolfGaropaInactiveState20:                         ; was: locret_4FD72
                rts
; End of function Boss_WolfGaropaSelectType424Sequence
; Empty Wolf Garopa boss movement state
Boss_WolfGaropaEmptyState:                              ; was: nullsub_118
                                        ; Boss_WolfGaropaUpdate+64   o
                rts
; End of function Boss_WolfGaropaEmptyState
; Select the neutral orb mapping pointer
Boss_WolfGaropaSelectOrbNeutralMapping:                 ; was: sub_4FD76
                                        ; Boss_WolfGaropaApproachOrbAngle140+4   p
                move.l  #Boss_WolfGaropaOrbNeutralMapping,$AE8(a5)
                rts
; End of function Boss_WolfGaropaSelectOrbNeutralMapping
; Optionally place a type-$424 record at Y=$C8 and configure the upper sequence
Boss_WolfGaropaBeginUpperType424Sequence:               ; was: sub_4FD80
                tst.w   (DifficultyMode).w
                bne.s   Boss_WolfGaropaConfigureUpperType424Sequence
                jsr     (Projectile_SpawnWolfGaropaType424).l
                bne.s   Boss_WolfGaropaConfigureUpperType424Sequence
                move.w  #$1A8,$10(a0)
                move.w  #$C8,$14(a0)
Boss_WolfGaropaConfigureUpperType424Sequence:           ; was: loc_4FD9A
                                        ; Boss_WolfGaropaBeginUpperType424Sequence+C   j
                move.w  #$A,4(a5)
                bset    #1,$41C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #2,d0
                addq.w  #1,d0
                move.w  d0,$11C(a5)
                move.w  #$40,$11E(a5)                   ; '@'
                move.w  #$140,$47C(a5)
                bset    #3,$9CE(a5)
; End of function Boss_WolfGaropaBeginUpperType424Sequence
; Run the upper type-$424 sequence and lazily initialize attack effect B
Boss_WolfGaropaUpdateUpperType424Sequence:              ; was: sub_4FDC6
                tst.b   (WolfGaropaEffectActive).w
                bne.s   Boss_WolfGaropaUpdateUpperSequenceMotion
                tst.w   $11C(a5)
                bmi.w   Boss_WolfGaropaFinishUpperType424Sequence
                subq.w  #1,$11E(a5)
                bpl.s   Boss_WolfGaropaUpdateUpperSequenceMotion
                tst.w   (BossHealth).w
                beq.w   Boss_WolfGaropaFinishUpperType424Sequence
                bsr.w   Boss_WolfGaropaTryLoadAttackEffectB
                tst.b   (WolfGaropaEffectActive).w
                beq.s   Boss_WolfGaropaUpdateUpperSequenceMotion
                subq.w  #1,$11C(a5)
Boss_WolfGaropaUpdateUpperSequenceMotion:               ; was: loc_4FDF0
                                        ; Boss_WolfGaropaUpdateUpperType424Sequence+12   j
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bra.w   Boss_WolfGaropaUpdateOrbTarget
; ---------------------------------------------------------------------------
Boss_WolfGaropaFinishUpperType424Sequence:              ; was: loc_4FDF8
                                        ; Boss_WolfGaropaUpdateUpperType424Sequence+18   j
                addq.w  #2,4(a5)
                bclr    #1,$41C(a5)
                move.w  #$40,$11C(a5)                   ; '@'
; Cool down after the upper type-$424 sequence
Boss_WolfGaropaUpdateUpperSequenceCooldown:             ; was: loc_4FE08
                subq.w  #1,$11C(a5)
                bmi.w   Boss_WolfGaropaBeginOrbAttackCycle
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bra.w   Boss_WolfGaropaUpdateOrbTarget
; End of function Boss_WolfGaropaUpdateUpperType424Sequence
; Optionally place a type-$424 record at Y=$130 and configure the lower sequence
Boss_WolfGaropaBeginLowerType424Sequence:               ; was: sub_4FE18
                tst.w   (DifficultyMode).w
                bne.s   Boss_WolfGaropaConfigureLowerType424Sequence
                jsr     (Projectile_SpawnWolfGaropaType424).l
                bne.s   Boss_WolfGaropaConfigureLowerType424Sequence
                move.w  #$1A8,$10(a0)
                move.w  #$130,$14(a0)
Boss_WolfGaropaConfigureLowerType424Sequence:           ; was: loc_4FE32
                                        ; Boss_WolfGaropaBeginLowerType424Sequence+C   j
                move.w  #$E,4(a5)
                bset    #2,$41C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                move.w  d0,$11C(a5)
                bset    #3,$9CE(a5)
; End of function Boss_WolfGaropaBeginLowerType424Sequence
; Run the lower type-$424 sequence until its pose-control flag clears
Boss_WolfGaropaUpdateLowerType424Sequence:              ; was: sub_4FE50
                btst    #2,$41C(a5)
                beq.w   Boss_WolfGaropaBeginOrbAttackCycle
                bsr.w   Boss_WolfGaropaDispatchMovementSequence
                bra.w   Boss_WolfGaropaUpdateOrbTarget
; End of function Boss_WolfGaropaUpdateLowerType424Sequence
; Dispatch the nested movement/pose sequence selected by offset $35C
Boss_WolfGaropaDispatchMovementSequence:                ; was: sub_4FE62
                                        ; sub_4FB3A:Boss_WolfGaropaUpdateOrbCycleEffects   p
                move.w  $35C(a5),d0
                movea.w Boss_WolfGaropaMovementSequenceTable(pc,d0.w),a0
                adda.l  #Boss_WolfGaropaInitializeMovementSequence,a0
                jmp     (a0)
; End of function Boss_WolfGaropaDispatchMovementSequence
; ---------------------------------------------------------------------------
Boss_WolfGaropaMovementSequenceTable:   dc.w    Boss_WolfGaropaReturn-Boss_WolfGaropaInitializeMovementSequence  ; was: off_4FE72
                dc.w    Boss_WolfGaropaUpdateHorizontalTargetMotion-Boss_WolfGaropaInitializeMovementSequence
                dc.w    Boss_WolfGaropaUpdateBallisticTransitionA-Boss_WolfGaropaInitializeMovementSequence
                dc.w    Boss_WolfGaropaUpdateBallisticTransitionB-Boss_WolfGaropaInitializeMovementSequence
                dc.w    Boss_WolfGaropaUpdateHorizontalAirborneMotion-Boss_WolfGaropaInitializeMovementSequence
                dc.w    Boss_WolfGaropaUpdateFinalBallisticMotion-Boss_WolfGaropaInitializeMovementSequence
                dc.w    Boss_WolfGaropaWaitForLaunchContact-Boss_WolfGaropaInitializeMovementSequence
                dc.w    Boss_WolfGaropaUpdateLaunchMotion-Boss_WolfGaropaInitializeMovementSequence

; Reset the nested sequence to its horizontal-targeting state
Boss_WolfGaropaInitializeMovementSequence:              ; was: sub_4FE82
                                        ; Boss_WolfGaropaBeginLeftEntry+2A   p
                move.w  #2,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                rts
; End of function Boss_WolfGaropaInitializeMovementSequence
; Steer horizontal velocity toward target X while advancing a pose script
Boss_WolfGaropaUpdateHorizontalTargetMotion:            ; was: sub_4FE94
                bclr    #0,$41C(a5)
                move.w  $47C(a5),d0
                sub.w   $10(a5),d0
                bpl.s   Boss_WolfGaropaCheckRightTargetDistance
                cmpi.w  #$FFFC,d0
                bmi.s   Boss_WolfGaropaAccelerateTowardLeftTarget
                bset    #0,$41C(a5)
                lea     Boss_WolfGaropaHorizontalMotionAPoses(pc),a1
                nop
                bra.s   Boss_WolfGaropaApplyLeftAcceleration
; ---------------------------------------------------------------------------
Boss_WolfGaropaAccelerateTowardLeftTarget:              ; was: loc_4FEB8
                lea     Boss_WolfGaropaHorizontalMotionPoseB(pc),a1
                nop
                tst.l   $18(a5)
                bpl.s   Boss_WolfGaropaApplyLeftAcceleration
                cmpi.l  #$FFFFA000,$18(a5)
                bmi.s   Boss_WolfGaropaAdvanceHorizontalMotionPose
Boss_WolfGaropaApplyLeftAcceleration:                   ; was: loc_4FECE
                                        ; Boss_WolfGaropaUpdateHorizontalTargetMotion+2E   j
                subi.l  #$1000,$18(a5)
                bra.s   Boss_WolfGaropaAdvanceHorizontalMotionPose
; ---------------------------------------------------------------------------
Boss_WolfGaropaCheckRightTargetDistance:                ; was: loc_4FED8
                cmpi.w  #4,d0
                bpl.s   Boss_WolfGaropaAccelerateTowardRightTarget
                bset    #0,$41C(a5)
                lea     Boss_WolfGaropaHorizontalMotionAPoses(pc),a1
                nop
                bra.s   Boss_WolfGaropaApplyLeftAcceleration
; ---------------------------------------------------------------------------
Boss_WolfGaropaAccelerateTowardRightTarget:             ; was: loc_4FEEC
                lea     Boss_WolfGaropaHorizontalMotionAPoses(pc),a1
                nop
                tst.l   $18(a5)
                bmi.s   Boss_WolfGaropaApplyRightAcceleration
                cmpi.l  #$4000,$18(a5)
                bpl.s   Boss_WolfGaropaAdvanceHorizontalMotionPose
Boss_WolfGaropaApplyRightAcceleration:                  ; was: loc_4FF02
                addi.l  #$1000,$18(a5)
Boss_WolfGaropaAdvanceHorizontalMotionPose:             ; was: loc_4FF0A
                                        ; Boss_WolfGaropaUpdateHorizontalTargetMotion+42   j
                move.l  a1,$2FC(a5)
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                btst    #2,$23E(a5)
                beq.w   Boss_WolfGaropaSelectPoseLinkedRecord
                move.w  a5,$4A(a5)
                btst    #1,$41C(a5)
                bne.s   Boss_WolfGaropaBeginLongBallisticTransition
                addq.w  #2,$35C(a5)
                addi.l  #$C000,$18(a5)
                move.l  #$FFFD0000,$1C(a5)
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginLongBallisticTransition:            ; was: loc_4FF40
                move.w  #6,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                addi.l  #$10000,$18(a5)
                move.l  #$FFFFE800,$1C(a5)
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; ---------------------------------------------------------------------------
Boss_WolfGaropaSelectPoseLinkedRecord:                  ; was: loc_4FF64
                btst    #3,$23E(a5)
                beq.s   Boss_WolfGaropaSetCurrentPoseLinkedRecordY
Boss_WolfGaropaSelectIndexedPoseLinkedRecord:           ; was: loc_4FF6C
                                        ; Boss_WolfGaropaWaitForLaunchContact+1C   j
                move.b  $23E(a5),d0
                andi.w  #3,d0
                asl.w   #1,d0
                movea.w Boss_WolfGaropaPoseLinkedRecordTable(pc,d0.w),a0
Boss_WolfGaropaSetPoseLinkedRecordY:                    ; was: loc_4FF7A
                                        ; Boss_WolfGaropaUpdateBallisticTransitionA+50   j
                move.w  a0,$4A(a5)
                move.w  #$148,$14(a0)
                btst    #7,$23E(a5)
                beq.s   Boss_WolfGaropaSetCurrentPoseLinkedRecordY
                move.b  #$CF,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; ---------------------------------------------------------------------------
Boss_WolfGaropaSetCurrentPoseLinkedRecordY:             ; was: loc_4FF9A
                                        ; Boss_WolfGaropaUpdateHorizontalTargetMotion+F6   j
                movea.w $4A(a5),a0
                move.w  #$148,$14(a0)
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; End of function Boss_WolfGaropaUpdateHorizontalTargetMotion
; ---------------------------------------------------------------------------
Boss_WolfGaropaPoseLinkedRecordTable:   dc.w    $CF20, $CD40, $CB60, $C980  ; was: word_4FFA8

; Apply the first gravity transition until its pose script ends
Boss_WolfGaropaUpdateBallisticTransitionA:              ; was: sub_4FFB0
                subi.l  #$800,$18(a5)
                addi.l  #$3800,$1C(a5)
                movea.l $2FC(a5),a1
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                tst.w   $58(a5)
                bpl.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bset    #7,$23E(a5)
                movea.w #(TwentyFifthEntityType-M68K_RAM),a0
                btst    #2,$41C(a5)
                bne.s   Boss_WolfGaropaContinueAfterBallisticTransitionA
                move.w  #2,$35C(a5)
                bra.w   Boss_WolfGaropaSetPoseLinkedRecordY
; ---------------------------------------------------------------------------
Boss_WolfGaropaContinueAfterBallisticTransitionA:       ; was: loc_4FFF6
                move.w  #$C,$35C(a5)
                clr.w   $11E(a5)
                bra.w   Boss_WolfGaropaSetPoseLinkedRecordY
; End of function Boss_WolfGaropaUpdateBallisticTransitionA
; Apply the second gravity transition and react to pose-script events
Boss_WolfGaropaUpdateBallisticTransitionB:              ; was: sub_50004
                subi.l  #$400,$18(a5)
                addi.l  #$4000,$1C(a5)
                tst.w   $58(a5)
                bmi.s   Boss_WolfGaropaBeginHorizontalAirborneMotion
                bclr    #6,$23E(a5)
                beq.s   Boss_WolfGaropaAdvanceBallisticTransitionPose
                move.b  #$EE,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_WolfGaropaAdvanceBallisticTransitionPose:          ; was: loc_5002C
                lea     Boss_WolfGaropaBallisticTransitionBPoses(pc),a1
                nop
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginHorizontalAirborneMotion:           ; was: loc_5003A
                addq.w  #2,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$CD40,$4A(a5)
                move.w  #$148,$734(a5)
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
; Track the target X during the intermediate airborne pose sequence
Boss_WolfGaropaUpdateHorizontalAirborneMotion:          ; was: loc_50060
                move.w  $47C(a5),d0
                sub.w   $10(a5),d0
                bpl.s   Boss_WolfGaropaCheckAirborneRightTarget
                cmpi.w  #$FFFC,d0
                bpl.s   Boss_WolfGaropaAdvanceAirbornePose
                tst.l   $18(a5)
                bpl.s   Boss_WolfGaropaApplyAirborneLeftAcceleration
                cmpi.l  #$FFFF0000,$18(a5)
                bmi.s   Boss_WolfGaropaAdvanceAirbornePose
Boss_WolfGaropaApplyAirborneLeftAcceleration:           ; was: loc_50080
                subi.l  #$1400,$18(a5)
                bra.s   Boss_WolfGaropaAdvanceAirbornePose
; ---------------------------------------------------------------------------
Boss_WolfGaropaCheckAirborneRightTarget:                ; was: loc_5008A
                cmpi.w  #4,d0
                bmi.s   Boss_WolfGaropaAdvanceAirbornePose
                tst.l   $18(a5)
                bmi.s   Boss_WolfGaropaApplyAirborneRightAcceleration
                cmpi.l  #$E000,$18(a5)
                bpl.s   Boss_WolfGaropaAdvanceAirbornePose
Boss_WolfGaropaApplyAirborneRightAcceleration:          ; was: loc_500A0
                addi.l  #$1400,$18(a5)
Boss_WolfGaropaAdvanceAirbornePose:                     ; was: loc_500A8
                                        ; Boss_WolfGaropaUpdateBallisticTransitionB+7A   j
                lea     Boss_WolfGaropaHorizontalAirbornePoses(pc),a1
                nop
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                btst    #3,$23E(a5)
                beq.w   Boss_WolfGaropaUpdateAirbornePoseLinkedRecord
                move.b  $23E(a5),d0
                andi.w  #3,d0
                move.l  #$4000,d1
                cmpi.w  #2,d0
                bpl.s   Boss_WolfGaropaApplyPoseEventHorizontalImpulse
                move.l  #$2000,d1
Boss_WolfGaropaApplyPoseEventHorizontalImpulse:         ; was: loc_500D6
                add.l   d1,$18(a5)
                cmpi.w  #2,d0
                bne.s   Boss_WolfGaropaUpdateAirbornePoseLinkedRecord
                btst    #1,$41C(a5)
                beq.s   Boss_WolfGaropaBeginFinalBallisticMotion
Boss_WolfGaropaUpdateAirbornePoseLinkedRecord:          ; was: loc_500E8
                                        ; Boss_WolfGaropaUpdateBallisticTransitionB+DA   j
                btst    #3,$23E(a5)
                beq.w   Boss_WolfGaropaSetCurrentPoseLinkedRecordY
                bra.w   Boss_WolfGaropaSelectIndexedPoseLinkedRecord
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginFinalBallisticMotion:               ; was: loc_500F6
                addq.w  #2,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                addi.l  #$10000,$18(a5)
                move.l  #$FFFA0000,$1C(a5)
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; End of function Boss_WolfGaropaUpdateBallisticTransitionB
; Apply the final gravity transition, then restart horizontal targeting
Boss_WolfGaropaUpdateFinalBallisticMotion:              ; was: sub_50120
                subi.l  #$800,$18(a5)
                addi.l  #$3800,$1C(a5)
                lea     Boss_WolfGaropaFinalBallisticPoses(pc),a1
                nop
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                tst.w   $58(a5)
                bpl.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
                move.w  #2,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bset    #7,$23E(a5)
                movea.w #(TwentyFifthEntityType-M68K_RAM),a0
                bra.w   Boss_WolfGaropaSetPoseLinkedRecordY
; End of function Boss_WolfGaropaUpdateFinalBallisticMotion
; Wait for the scripted launch event, then install launch velocity
Boss_WolfGaropaWaitForLaunchContact:                    ; was: sub_50160
                lea     Boss_WolfGaropaLaunchPoses(pc),a1
                nop
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                btst    #6,$23E(a5)
                bne.s   Boss_WolfGaropaBeginLaunchMotion
                btst    #3,$23E(a5)
                beq.w   Boss_WolfGaropaSetCurrentPoseLinkedRecordY
                bra.w   Boss_WolfGaropaSelectIndexedPoseLinkedRecord
; ---------------------------------------------------------------------------
Boss_WolfGaropaBeginLaunchMotion:                       ; was: loc_50180
                addq.w  #2,$35C(a5)
                move.w  a5,$4A(a5)
                move.l  #$14000,$18(a5)
                move.l  #$FFF80000,$1C(a5)
                move.b  #$2A,d0                         ; '*'
                jsr     (Sound_QueueSFXRequest).l
                bra.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
; End of function Boss_WolfGaropaWaitForLaunchContact
; Update launch motion, the linked record, and the optional attack effect
Boss_WolfGaropaUpdateLaunchMotion:                      ; was: sub_501A6
                tst.w   $11E(a5)
                bne.s   Boss_WolfGaropaAdvanceLaunchPose
                bsr.w   Boss_WolfGaropaTryLoadAttackEffectA
                tst.b   (WolfGaropaEffectActive).w
                beq.s   Boss_WolfGaropaAdvanceLaunchPose
                addq.w  #1,$11E(a5)
Boss_WolfGaropaAdvanceLaunchPose:                       ; was: loc_501BA
                                        ; Boss_WolfGaropaUpdateLaunchMotion+E   j
                movea.w $48(a5),a0
                subi.l  #$800,$18(a0)
                addi.l  #$6800,$1C(a5)
                lea     Boss_WolfGaropaLaunchPoses(pc),a1
                nop
                bsr.w   Boss_WolfGaropaAdvancePoseScript
                tst.w   $58(a5)
                bpl.w   Boss_WolfGaropaUpdateMetaspriteAndOrb
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                tst.w   (BossHealth).w
                beq.s   Boss_WolfGaropaClearLowerSequenceFlag
                subq.w  #1,$11C(a5)
                bpl.s   Boss_WolfGaropaResetMovementSequence
Boss_WolfGaropaClearLowerSequenceFlag:                  ; was: loc_501F8
                bclr    #2,$41C(a5)
Boss_WolfGaropaResetMovementSequence:                   ; was: loc_501FE
                move.w  #2,$35C(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bset    #7,$23E(a5)
                movea.w #(TwentyFifthEntityType-M68K_RAM),a0
                bra.w   Boss_WolfGaropaSetPoseLinkedRecordY
; End of function Boss_WolfGaropaUpdateLaunchMotion
; Advance only the current pose script
Boss_WolfGaropaAdvanceCurrentPoseScript:                ; was: sub_5021C
                bsr.w   Boss_WolfGaropaAdvancePoseScript
; End of function Boss_WolfGaropaAdvanceCurrentPoseScript
