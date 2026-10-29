; Apply or clear horizontal flip on the body from frame-counter bit 9
Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit:        ; was: sub_4E5C0
                                        ; Boss_ShieldViperWaitOrbitShotBurstDelay+6   p
                moveq   #0,d0
                btst    #1,(FrameCounter+1).w
                bne.s   Gfx_ShieldViperApplyFrameSelectedHorizontalFlip
                move.w  #$2000,d0
Gfx_ShieldViperApplyFrameSelectedHorizontalFlip:        ; was: loc_4E5CE
                move.w  #$18,d7
                movea.w a5,a0
Gfx_ShieldViperUpdateHorizontalFlipLoop:                ; was: loc_4E5D4
                andi.w  #$DFFF,$E(a0)
                or.w    d0,$E(a0)
                cmpi.w  #$370,(a0)
                bne.s   Gfx_ShieldViperAdvanceHorizontalFlipLoop
                tst.w   $5C(a0)
                beq.s   Gfx_ShieldViperAdvanceHorizontalFlipLoop
                movea.w $5C(a0),a1
                andi.w  #$DFFF,$E(a1)
                or.w    d0,$E(a1)
Gfx_ShieldViperAdvanceHorizontalFlipLoop:               ; was: loc_4E5F8
                                        ; Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit+28   j
                lea     $60(a0),a0
                dbf     d7,Gfx_ShieldViperUpdateHorizontalFlipLoop
                rts
; End of function Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
; Force horizontal flip on the controller and its 24 body records
Gfx_ShieldViperForceHorizontalFlip:                     ; was: sub_4E602
                                        ; Boss_ShieldViperWaitForLinkedRecordActivation+A   p
                move.w  #$18,d7
                movea.w a5,a0
Gfx_ShieldViperForceHorizontalFlipLoop:                 ; was: loc_4E608
                andi.w  #$DFFF,$E(a0)
                ori.w   #$2000,$E(a0)
                cmpi.w  #$370,(a0)
                bne.s   Gfx_ShieldViperAdvanceForcedHorizontalFlipLoop
                tst.w   $5C(a0)
                beq.s   Gfx_ShieldViperAdvanceForcedHorizontalFlipLoop
                movea.w $5C(a0),a1
                andi.w  #$DFFF,$E(a1)
                ori.w   #$2000,$E(a1)
Gfx_ShieldViperAdvanceForcedHorizontalFlipLoop:         ; was: loc_4E630
                                        ; Gfx_ShieldViperForceHorizontalFlip+1C   j
                lea     $60(a0),a0
                dbf     d7,Gfx_ShieldViperForceHorizontalFlipLoop
                rts
; End of function Gfx_ShieldViperForceHorizontalFlip
; Convert linked-body positions into trail samples and advance
Boss_ShieldViperEnableTrailGeometryAndAdvance:          ; was: sub_4E63A
                bsr.w   Boss_ShieldViperEnableTrailGeometry
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperEnableTrailGeometryAndAdvance
; Advances state machine to next state
Boss_ShieldViperAdvanceState:                           ; was: sub_4E644
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceState
; Seed two eight-sample passes that steer rotation toward the player
Boss_ShieldViperBeginTwoPassPlayerTrackingCycle:        ; was: sub_4E64A
                move.w  #2,$4C(a5)
                clr.w   $4E(a5)
                addq.w  #2,4(a5)
; Seed one eight-sample player-tracking pass
Boss_ShieldViperBeginPlayerTrackingPass:                ; was: loc_4E658
                move.w  #1,$48(a5)
                move.w  #8,$4A(a5)
                addq.w  #2,4(a5)
; Move continuously and update rotation toward the player every sixteen frames
Boss_ShieldViperUpdatePlayerTrackingPass:               ; was: loc_4E668
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPlayerTrackingPassReturn
                subq.w  #1,$4A(a5)
                beq.s   Boss_ShieldViperFinishPlayerTrackingPass
                move.w  (PlayerCenterX).w,d0
                move.w  (PlayerCenterY).w,d1
                move.w  #$10,$48(a5)
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
Boss_ShieldViperPlayerTrackingPassReturn:               ; was: locret_4E68A
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperFinishPlayerTrackingPass:               ; was: loc_4E68C
                subq.w  #1,$4C(a5)
                beq.s   Boss_ShieldViperSelectPostTrackingBranch
                move.w  #$34,4(a5)                      ; '4'
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperSelectPostTrackingBranch:               ; was: loc_4E69A
                addq.w  #1,(ShieldViperBranchParity).w
                andi.w  #1,(ShieldViperBranchParity).w
                beq.s   Boss_ShieldViperAdvanceAfterPlayerTracking
                cmpi.w  #$88,$10(a5)
                bcs.s   Boss_ShieldViperAdvanceAfterPlayerTracking
                cmpi.w  #$1B8,$10(a5)
                bhi.s   Boss_ShieldViperAdvanceAfterPlayerTracking
                cmpi.w  #$A8,$14(a5)
                bcs.s   Boss_ShieldViperAdvanceAfterPlayerTracking
                cmpi.w  #$158,$14(a5)
                bhi.s   Boss_ShieldViperAdvanceAfterPlayerTracking
                move.w  #$4E,4(a5)                      ; 'N'
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperAdvanceAfterPlayerTracking:             ; was: loc_4E6CE
                                        ; Boss_ShieldViperBeginTwoPassPlayerTrackingCycle+62   j
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginTwoPassPlayerTrackingCycle
; Randomly select the upper or lower vertical target at arena X $120
Boss_ShieldViperChooseRandomVerticalTarget:             ; was: sub_4E6D4
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                move.w  #$120,d0
                btst    #0,(RandomNumberState).w
                bne.s   Boss_ShieldViperSelectLowerVerticalTarget
                move.w  #$80,$4A(a5)
                move.w  #$80,d1
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperSelectLowerVerticalTarget:              ; was: loc_4E6F8
                move.w  #$180,$4A(a5)
                move.w  #$180,d1
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
                rts
; End of function Boss_ShieldViperChooseRandomVerticalTarget
; Rotate and move until the angle associated with the selected vertical target
Boss_ShieldViperRotateToSelectedVerticalTargetAngle:    ; was: sub_4E708
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmp.w   $4A(a5),d0
                bne.s   Boss_ShieldViperSelectedTargetAngleWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperSelectedTargetAngleWaitReturn:          ; was: locret_4E71E
                rts
; End of function Boss_ShieldViperRotateToSelectedVerticalTargetAngle
; Route to reentry or restart tracking after reaching the selected Y boundary
Boss_ShieldViperRouteAtSelectedVerticalBoundary:        ; was: sub_4E720
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$180,$4A(a5)
                beq.s   Boss_ShieldViperCheckLowerVerticalBoundary
                cmpi.w  #$60,$14(a5)                    ; '`'
                bgt.s   Boss_ShieldViperVerticalBoundaryCheckReturn
                move.w  #$3E,4(a5)                      ; '>'
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperCheckLowerVerticalBoundary:             ; was: loc_4E73C
                cmpi.w  #$180,$14(a5)
                blt.s   Boss_ShieldViperVerticalBoundaryCheckReturn
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperVerticalBoundaryCheckReturn:            ; was: locret_4E74A
                                        ; Boss_ShieldViperRouteAtSelectedVerticalBoundary+22   j
                rts
; End of function Boss_ShieldViperRouteAtSelectedVerticalBoundary
; Alternate the X side and angular step for the reentry arc
Boss_ShieldViperSelectAlternatingReentrySide:           ; was: sub_4E74C
                addq.w  #2,4(a5)
                move.w  #$60,$14(a5)                    ; '`'
                move.w  #$180,$56(a5)
                addq.b  #1,(SharedScratchLong5+2).w
                btst    #1,(SharedScratchLong5+2).w
                beq.s   Boss_ShieldViperConfigureRightReentry
                move.w  #$A0,$10(a5)
                move.w  #$FFFE,$4A(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperConfigureRightReentry:                  ; was: loc_4E776
                move.w  #$1A0,$10(a5)
                move.w  #2,$4A(a5)
                rts
; End of function Boss_ShieldViperSelectAlternatingReentrySide
; Move radially to Y $D0, then apply the selected reentry angular step
Boss_ShieldViperMoveToReentryYThreshold:                ; was: sub_4E784
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$D0,$14(a5)
                blt.s   Boss_ShieldViperReentryMovementReturn
                move.w  $4A(a5),(SharedScratchLong0).w
                move.w  #2,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperReentryMovementReturn:                  ; was: locret_4E7A0
                rts
; End of function Boss_ShieldViperMoveToReentryYThreshold
; Double the angular step at successive half-turn boundaries
Boss_ShieldViperDoubleAngularStepAtHalfTurns:           ; was: sub_4E7A2
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$FE,d0
                bne.s   Boss_ShieldViperAngularStepDoublingReturn
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperAngularStepDoublingReturn
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_ShieldViperAngularStepDoublingReturn:              ; was: locret_4E7C8
                                        ; Boss_ShieldViperDoubleAngularStepAtHalfTurns+1A   j
                rts
; End of function Boss_ShieldViperDoubleAngularStepAtHalfTurns
; Wait before the orbit-shot windup, then seed its sixteen-frame delay
Boss_ShieldViperWaitBeforeOrbitShotWindup:              ; was: sub_4E7CA
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotPreWindupReturn
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotPreWindupReturn:               ; was: locret_4E7E2
                rts
; End of function Boss_ShieldViperWaitBeforeOrbitShotWindup
; Animate body flip during the windup, then seed the 128-frame shot stream
Boss_ShieldViperAnimateOrbitShotWindup:                 ; was: sub_4E7E4
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotWindupReturn
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotWindupReturn:                  ; was: locret_4E7FC
                rts
; End of function Boss_ShieldViperAnimateOrbitShotWindup
; Emit frame-gated orbit shots throughout the timed stream
Boss_ShieldViperEmitTimedOrbitShotStream:               ; was: sub_4E7FE
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                bsr.w   Boss_ShieldViperEmitOrbitShotOnFrameGate
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotStreamReturn
                bsr.w   Boss_ShieldViperHideOrbitingRecordAndForceFlip
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotStreamReturn:                  ; was: locret_4E818
                rts
; End of function Boss_ShieldViperEmitTimedOrbitShotStream
; Rotate and move to masked angle $180 after the orbit-shot stream
Boss_ShieldViperRotateToHalfTurnAfterOrbitShots:        ; was: sub_4E81A
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmpi.w  #$180,d0
                bne.s   Boss_ShieldViperPostOrbitHalfTurnWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperPostOrbitHalfTurnWaitReturn:            ; was: locret_4E830
                rts
; End of function Boss_ShieldViperRotateToHalfTurnAfterOrbitShots
; Move to Y $180, then restart the two-pass tracking cycle
Boss_ShieldViperMoveToLowerBoundaryAndRestartTracking:  ; was: sub_4E832
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$180,$14(a5)
                blt.s   Boss_ShieldViperLowerBoundaryMovementReturn
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperLowerBoundaryMovementReturn:            ; was: locret_4E844
                rts
; End of function Boss_ShieldViperMoveToLowerBoundaryAndRestartTracking
; Double the angular step and seed a 128-frame movement delay
Boss_ShieldViperDoubleAngularStepAndBeginDelay:         ; was: sub_4E846
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
; Move throughout the delay, then seed a sixteen-frame flip wait
Boss_ShieldViperWaitAfterAngularStepDoubling:           ; was: loc_4E858
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperAngularStepDelayReturn
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperAngularStepDelayReturn:                 ; was: locret_4E86C
                rts
; End of function Boss_ShieldViperDoubleAngularStepAndBeginDelay
; Animate body flip through the final wait before linked-record allocation
Boss_ShieldViperWaitWithHorizontalFlipBeforeLinkedRecords:  ; was: sub_4E86E
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedRecordFlipWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedRecordFlipWaitReturn:             ; was: locret_4E880
                rts
; End of function Boss_ShieldViperWaitWithHorizontalFlipBeforeLinkedRecords
; Allocate up to 24 empty records and attach them to successive body records
Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords:     ; was: sub_4E882
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                lea     $60(a5),a1
                move.w  #2,d6
                move.w  #$17,d7
Boss_ShieldViperAllocateLinkedBodyRecordLoop:           ; was: loc_4E892
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperFinishLinkedBodyRecordAllocation
                move.w  #$10,(a0)
                move.w  a0,$5C(a1)
                move.w  d6,$48(a1)
                addq.w  #2,4(a1)
                addq.w  #2,d6
                lea     $60(a1),a1
                dbf     d7,Boss_ShieldViperAllocateLinkedBodyRecordLoop
Boss_ShieldViperFinishLinkedBodyRecordAllocation:       ; was: loc_4E8B4
                move.w  d6,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords
; Wait for the staggered linked-record activation interval, then force flip
Boss_ShieldViperWaitForLinkedRecordActivation:          ; was: sub_4E8BE
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedRecordActivationWaitReturn
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedRecordActivationWaitReturn:       ; was: locret_4E8D0
                rts
; End of function Boss_ShieldViperWaitForLinkedRecordActivation
; Build a randomized index order and spawn up to twelve type-$378 projectiles
Boss_ShieldViperSpawnPatternProjectileSet:              ; was: sub_4E8D2
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Boss_ShieldViperBuildPatternProjectileIndexOrder
                lea     (SharedScratchLong8).w,a1
                lea     Boss_ShieldViperPatternProjectileRecords(pc),a2
                nop
                move.w  #$B,d7
                move.w  #$20,d6                         ; ' '
                moveq   #0,d5
Boss_ShieldViperSpawnPatternProjectileLoop:             ; was: loc_4E8EE
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperFinishPatternProjectileSpawn
                move.w  #$378,(a0)
                move.w  #$4C80,2(a0)
                move.w  $6E(a5),$E(a0)
                move.l  $68(a5),8(a0)
                move.w  (a1)+,d0
                move.w  d0,d1
                lsl.w   #3,d1
                lsl.w   #2,d0
                add.w   d0,d1
                move.w  (a2,d1.w),$10(a0)
                move.w  2(a2,d1.w),$14(a0)
                move.w  4(a2,d1.w),$4C(a0)
                move.w  8(a2,d1.w),$50(a0)
                move.w  d6,$4A(a0)
                addi.w  #$20,d6                         ; ' '
                dbf     d7,Boss_ShieldViperSpawnPatternProjectileLoop
Boss_ShieldViperFinishPatternProjectileSpawn:           ; was: loc_4E93A
                move.w  d6,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperSpawnPatternProjectileSet
; ---------------------------------------------------------------------------
Boss_ShieldViperPatternProjectileRecords:   binclude "data/other/word_4E944.bin"  ; was: word_4E944
Boss_ShieldViperPatternProjectileRecordsEnd:            ; was: word_4E944_End

; Build sixteen group-selected indices and perform eight random swaps
Boss_ShieldViperBuildPatternProjectileIndexOrder:       ; was: sub_4EAC4
                lea     (SharedScratchLong8).w,a0
                move.w  #9,d7
                moveq   #0,d6
Boss_ShieldViperBuildFirstPatternIndexGroupLoop:        ; was: loc_4EACE
                jsr     (RandomNumber).l
                move.w  d6,d0
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ShieldViperStoreFirstPatternIndex
                addi.w  #$A,d0
Boss_ShieldViperStoreFirstPatternIndex:                 ; was: loc_4EAE2
                move.w  d0,(a0)+
                addq.w  #1,d6
                dbf     d7,Boss_ShieldViperBuildFirstPatternIndexGroupLoop
                move.w  #5,d7
                move.w  #$14,d6
Boss_ShieldViperBuildSecondPatternIndexGroupLoop:       ; was: loc_4EAF2
                jsr     (RandomNumber).l
                move.w  d6,d0
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ShieldViperStoreSecondPatternIndex
                addi.w  #6,d0
Boss_ShieldViperStoreSecondPatternIndex:                ; was: loc_4EB06
                move.w  d0,(a0)+
                addq.w  #1,d6
                dbf     d7,Boss_ShieldViperBuildSecondPatternIndexGroupLoop
                lea     (SharedScratchLong8).w,a0
                move.w  #7,d7
                moveq   #0,d6
Boss_ShieldViperShufflePatternIndexLoop:                ; was: loc_4EB18
                jsr     (RandomNumber).l
                move.w  (RandomNumberState).w,d1
                andi.w  #$F,d1
                add.w   d1,d1
                move.w  (a0,d6.w),d2
                move.w  (a0,d1.w),(a0,d6.w)
                move.w  d2,(a0,d1.w)
                addq.w  #2,d6
                dbf     d7,Boss_ShieldViperShufflePatternIndexLoop
                rts
; End of function Boss_ShieldViperBuildPatternProjectileIndexOrder
; Keep moving through the timer derived from the spawned projectile sequence
Boss_ShieldViperWaitForPatternProjectileSequence:       ; was: sub_4EB3E
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPatternProjectileWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperPatternProjectileWaitReturn:            ; was: locret_4EB4C
                rts
; End of function Boss_ShieldViperWaitForPatternProjectileSequence
; Move once and advance after the pattern-projectile sequence
Boss_ShieldViperAdvanceAfterPatternProjectileSequence:  ; was: sub_4EB4E
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceAfterPatternProjectileSequence
; Steer toward arena point ($120,$F0) and double the angular step at angle $80
Boss_ShieldViperSteerTowardCenterAndDoubleStepAtQuarterTurn:  ; was: sub_4EB58
                bsr.w   Boss_ShieldViperChooseRotationTowardArenaCenterEveryEightFrames
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmpi.w  #$80,d0
                bne.s   Boss_ShieldViperCenterSteeringReturn
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
                addq.w  #2,4(a5)
Boss_ShieldViperCenterSteeringReturn:                   ; was: locret_4EB7A
                rts
; End of function Boss_ShieldViperSteerTowardCenterAndDoubleStepAtQuarterTurn
; Move and advance twice through the two fall-through state entries
Boss_ShieldViperAdvanceTwoStatesWhileMoving:            ; was: sub_4EB7C
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
; Perform the second movement and state advance
Boss_ShieldViperAdvanceSecondStateWhileMoving:          ; was: loc_4EB84
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceTwoStatesWhileMoving
; Move once and advance to the linked-record release sequence
Boss_ShieldViperAdvanceOneStateWhileMoving:             ; was: sub_4EB8E
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceOneStateWhileMoving
; Seed the 64-frame delay before sequential linked-record release
Boss_ShieldViperBeginLinkedRecordReleaseDelay:          ; was: sub_4EB98
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginLinkedRecordReleaseDelay
; After the delay, select the first of 24 body records for sequential release
Boss_ShieldViperPrepareSequentialLinkedRecordRelease:   ; was: sub_4EBAC
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedRecordReleasePreparationReturn
                lea     $60(a5),a0
                move.w  a0,$4A(a5)
                move.w  #$18,$4C(a5)
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedRecordReleasePreparationReturn:   ; was: locret_4EBD2
                rts
; End of function Boss_ShieldViperPrepareSequentialLinkedRecordRelease
; Allocate and attach one empty record to each body record at eight-frame intervals
Boss_ShieldViperReleaseLinkedBodyRecordsSequentially:   ; was: sub_4EBD4
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bpl.s   Boss_ShieldViperSequentialLinkedRecordReleaseReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperSequentialLinkedRecordReleaseReturn
                move.w  #$10,(a0)
                movea.w $4A(a5),a1
                move.w  a0,$5C(a1)
                addq.w  #2,4(a1)
                subq.w  #1,$4C(a5)
                beq.s   Boss_ShieldViperFinishSequentialLinkedRecordRelease
                lea     $60(a1),a1
                move.w  a1,$4A(a5)
                move.w  #8,$48(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperFinishSequentialLinkedRecordRelease:    ; was: loc_4EC10
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperSequentialLinkedRecordReleaseReturn:    ; was: locret_4EC1A
                                        ; Boss_ShieldViperReleaseLinkedBodyRecordsSequentially+14   j
                rts
; End of function Boss_ShieldViperReleaseLinkedBodyRecordsSequentially
; Wait after release, force flip, double the angular step, and seed 64 frames
Boss_ShieldViperWaitAfterLinkedRecordReleaseAndDoubleAngularStep:  ; was: sub_4EC1C
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPostReleaseAngularStepReturn
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_ShieldViperPostReleaseAngularStepReturn:           ; was: locret_4EC40
                rts
; End of function Boss_ShieldViperWaitAfterLinkedRecordReleaseAndDoubleAngularStep
; After the delay, halve the angular step and restart state $32 tracking
Boss_ShieldViperWaitThenHalveAngularStepAndRestartTracking:  ; was: sub_4EC42
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperTrackingRestartDelayReturn
                move.w  (SharedScratchLong0).w,d0
                asr.w   #1,d0
                move.w  d0,(SharedScratchLong0).w
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperTrackingRestartDelayReturn:             ; was: locret_4EC5C
                rts
; End of function Boss_ShieldViperWaitThenHalveAngularStepAndRestartTracking
