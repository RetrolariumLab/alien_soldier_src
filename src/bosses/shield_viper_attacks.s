; Apply or clear horizontal flip on the body from frame-counter bit 9
Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit:        ; CODE XREF: Boss_ShieldViperBeginOrbitShotBurstDelay+C   p  ; was: sub_4E5C0
                                        ; Boss_ShieldViperWaitOrbitShotBurstDelay+6   p
                moveq   #0,d0
                btst    #1,(FrameCounter+1).w
                bne.s   Gfx_ShieldViperApplyFrameSelectedHorizontalFlip
                move.w  #$2000,d0
Gfx_ShieldViperApplyFrameSelectedHorizontalFlip:        ; CODE XREF: Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit+8   j  ; was: loc_4E5CE
                move.w  #$18,d7
                movea.w a5,a0
Gfx_ShieldViperUpdateHorizontalFlipLoop:                ; CODE XREF: Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit+3C   j  ; was: loc_4E5D4
                andi.w  #$DFFF,$E(a0)
                or.w    d0,$E(a0)
                cmpi.w  #$370,(a0)
                bne.s   Gfx_ShieldViperAdvanceHorizontalFlipLoop
                tst.w   $5C(a0)
                beq.s   Gfx_ShieldViperAdvanceHorizontalFlipLoop
                movea.w $5C(a0),a1
                andi.w  #$DFFF,$E(a1)
                or.w    d0,$E(a1)
Gfx_ShieldViperAdvanceHorizontalFlipLoop:               ; CODE XREF: Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit+22   j  ; was: loc_4E5F8
                                        ; Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit+28   j
                lea     $60(a0),a0
                dbf     d7,Gfx_ShieldViperUpdateHorizontalFlipLoop
                rts
; End of function Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
; Force horizontal flip on the controller and its 24 body records
Gfx_ShieldViperForceHorizontalFlip:                     ; CODE XREF: Boss_ShieldViperEmitOrbitShotBurst+84   p  ; was: sub_4E602
                                        ; Boss_ShieldViperWaitForLinkedRecordActivation+A   p
                move.w  #$18,d7
                movea.w a5,a0
Gfx_ShieldViperForceHorizontalFlipLoop:                 ; CODE XREF: Gfx_ShieldViperForceHorizontalFlip+32   j  ; was: loc_4E608
                andi.w  #$DFFF,$E(a0)
                ori.w   #$2000,$E(a0)
                cmpi.w  #$370,(a0)
                bne.s   Gfx_ShieldViperAdvanceForcedHorizontalFlipLoop
                tst.w   $5C(a0)
                beq.s   Gfx_ShieldViperAdvanceForcedHorizontalFlipLoop
                movea.w $5C(a0),a1
                andi.w  #$DFFF,$E(a1)
                ori.w   #$2000,$E(a1)
Gfx_ShieldViperAdvanceForcedHorizontalFlipLoop:         ; CODE XREF: Gfx_ShieldViperForceHorizontalFlip+16   j  ; was: loc_4E630
                                        ; Gfx_ShieldViperForceHorizontalFlip+1C   j
                lea     $60(a0),a0
                dbf     d7,Gfx_ShieldViperForceHorizontalFlipLoop
                rts
; End of function Gfx_ShieldViperForceHorizontalFlip
; Convert linked-body positions into trail samples and advance
Boss_ShieldViperEnableTrailGeometryAndAdvance:          ; DATA XREF: ROM:0004E014   o  ; was: sub_4E63A
                bsr.w   Boss_ShieldViperEnableTrailGeometry
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperEnableTrailGeometryAndAdvance
; Advances state machine to next state
Boss_ShieldViperAdvanceState:                           ; DATA XREF: ROM:0004E016   o  ; was: sub_4E644
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceState
; Seed two eight-sample passes that steer rotation toward the player
Boss_ShieldViperBeginTwoPassPlayerTrackingCycle:        ; DATA XREF: ROM:0004E018   o  ; was: sub_4E64A
                move.w  #2,$4C(a5)
                clr.w   $4E(a5)
                addq.w  #2,4(a5)
; Seed one eight-sample player-tracking pass
Boss_ShieldViperBeginPlayerTrackingPass:                ; DATA XREF: ROM:0004E01A   o  ; was: loc_4E658
                move.w  #1,$48(a5)
                move.w  #8,$4A(a5)
                addq.w  #2,4(a5)
; Move continuously and update rotation toward the player every sixteen frames
Boss_ShieldViperUpdatePlayerTrackingPass:               ; DATA XREF: ROM:0004E01C   o  ; was: loc_4E668
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPlayerTrackingPassReturn
                subq.w  #1,$4A(a5)
                beq.s   Boss_ShieldViperFinishPlayerTrackingPass
                move.w  (PlayerCenterX).w,d0
                move.w  (PlayerCenterY).w,d1
                move.w  #$10,$48(a5)
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
Boss_ShieldViperPlayerTrackingPassReturn:               ; CODE XREF: Boss_ShieldViperBeginTwoPassPlayerTrackingCycle+26   j  ; was: locret_4E68A
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperFinishPlayerTrackingPass:               ; CODE XREF: Boss_ShieldViperBeginTwoPassPlayerTrackingCycle+2C   j  ; was: loc_4E68C
                subq.w  #1,$4C(a5)
                beq.s   Boss_ShieldViperSelectPostTrackingBranch
                move.w  #$34,4(a5)                      ; '4'
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperSelectPostTrackingBranch:               ; CODE XREF: Boss_ShieldViperBeginTwoPassPlayerTrackingCycle+46   j  ; was: loc_4E69A
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
Boss_ShieldViperAdvanceAfterPlayerTracking:             ; CODE XREF: Boss_ShieldViperBeginTwoPassPlayerTrackingCycle+5A   j  ; was: loc_4E6CE
                                        ; Boss_ShieldViperBeginTwoPassPlayerTrackingCycle+62   j
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginTwoPassPlayerTrackingCycle
; Randomly select the upper or lower vertical target at arena X $120
Boss_ShieldViperChooseRandomVerticalTarget:             ; DATA XREF: ROM:0004E01E   o  ; was: sub_4E6D4
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
Boss_ShieldViperSelectLowerVerticalTarget:              ; CODE XREF: Boss_ShieldViperChooseRandomVerticalTarget+12   j  ; was: loc_4E6F8
                move.w  #$180,$4A(a5)
                move.w  #$180,d1
                bsr.w   Boss_ShieldViperChooseRotationTowardTarget
                rts
; End of function Boss_ShieldViperChooseRandomVerticalTarget
; Rotate and move until the angle associated with the selected vertical target
Boss_ShieldViperRotateToSelectedVerticalTargetAngle:    ; DATA XREF: ROM:0004E020   o  ; was: sub_4E708
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmp.w   $4A(a5),d0
                bne.s   Boss_ShieldViperSelectedTargetAngleWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperSelectedTargetAngleWaitReturn:          ; CODE XREF: Boss_ShieldViperRotateToSelectedVerticalTargetAngle+10   j  ; was: locret_4E71E
                rts
; End of function Boss_ShieldViperRotateToSelectedVerticalTargetAngle
; Route to reentry or restart tracking after reaching the selected Y boundary
Boss_ShieldViperRouteAtSelectedVerticalBoundary:        ; DATA XREF: ROM:0004E022   o  ; was: sub_4E720
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$180,$4A(a5)
                beq.s   Boss_ShieldViperCheckLowerVerticalBoundary
                cmpi.w  #$60,$14(a5)                    ; '`'
                bgt.s   Boss_ShieldViperVerticalBoundaryCheckReturn
                move.w  #$3E,4(a5)                      ; '>'
                rts
; ---------------------------------------------------------------------------
Boss_ShieldViperCheckLowerVerticalBoundary:             ; CODE XREF: Boss_ShieldViperRouteAtSelectedVerticalBoundary+A   j  ; was: loc_4E73C
                cmpi.w  #$180,$14(a5)
                blt.s   Boss_ShieldViperVerticalBoundaryCheckReturn
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperVerticalBoundaryCheckReturn:            ; CODE XREF: Boss_ShieldViperRouteAtSelectedVerticalBoundary+12   j  ; was: locret_4E74A
                                        ; Boss_ShieldViperRouteAtSelectedVerticalBoundary+22   j
                rts
; End of function Boss_ShieldViperRouteAtSelectedVerticalBoundary
; Alternate the X side and angular step for the reentry arc
Boss_ShieldViperSelectAlternatingReentrySide:           ; DATA XREF: ROM:0004E024   o  ; was: sub_4E74C
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
Boss_ShieldViperConfigureRightReentry:                  ; CODE XREF: Boss_ShieldViperSelectAlternatingReentrySide+1A   j  ; was: loc_4E776
                move.w  #$1A0,$10(a5)
                move.w  #2,$4A(a5)
                rts
; End of function Boss_ShieldViperSelectAlternatingReentrySide
; Move radially to Y $D0, then apply the selected reentry angular step
Boss_ShieldViperMoveToReentryYThreshold:                ; DATA XREF: ROM:0004E026   o  ; was: sub_4E784
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$D0,$14(a5)
                blt.s   Boss_ShieldViperReentryMovementReturn
                move.w  $4A(a5),(SharedScratchLong0).w
                move.w  #2,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperReentryMovementReturn:                  ; CODE XREF: Boss_ShieldViperMoveToReentryYThreshold+A   j  ; was: locret_4E7A0
                rts
; End of function Boss_ShieldViperMoveToReentryYThreshold
; Double the angular step at successive half-turn boundaries
Boss_ShieldViperDoubleAngularStepAtHalfTurns:           ; DATA XREF: ROM:0004E028   o  ; was: sub_4E7A2
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
Boss_ShieldViperAngularStepDoublingReturn:              ; CODE XREF: Boss_ShieldViperDoubleAngularStepAtHalfTurns+C   j  ; was: locret_4E7C8
                                        ; Boss_ShieldViperDoubleAngularStepAtHalfTurns+1A   j
                rts
; End of function Boss_ShieldViperDoubleAngularStepAtHalfTurns
; Wait before the orbit-shot windup, then seed its sixteen-frame delay
Boss_ShieldViperWaitBeforeOrbitShotWindup:              ; DATA XREF: ROM:0004E02A   o  ; was: sub_4E7CA
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotPreWindupReturn
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotPreWindupReturn:               ; CODE XREF: Boss_ShieldViperWaitBeforeOrbitShotWindup+8   j  ; was: locret_4E7E2
                rts
; End of function Boss_ShieldViperWaitBeforeOrbitShotWindup
; Animate body flip during the windup, then seed the 128-frame shot stream
Boss_ShieldViperAnimateOrbitShotWindup:                 ; DATA XREF: ROM:0004E02C   o  ; was: sub_4E7E4
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotWindupReturn
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotWindupReturn:                  ; CODE XREF: Boss_ShieldViperAnimateOrbitShotWindup+C   j  ; was: locret_4E7FC
                rts
; End of function Boss_ShieldViperAnimateOrbitShotWindup
; Emit frame-gated orbit shots throughout the timed stream
Boss_ShieldViperEmitTimedOrbitShotStream:               ; DATA XREF: ROM:0004E02E   o  ; was: sub_4E7FE
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                bsr.w   Boss_ShieldViperEmitOrbitShotOnFrameGate
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperOrbitShotStreamReturn
                bsr.w   Boss_ShieldViperHideOrbitingRecordAndForceFlip
                addq.w  #2,4(a5)
Boss_ShieldViperOrbitShotStreamReturn:                  ; CODE XREF: Boss_ShieldViperEmitTimedOrbitShotStream+10   j  ; was: locret_4E818
                rts
; End of function Boss_ShieldViperEmitTimedOrbitShotStream
; Rotate and move to masked angle $180 after the orbit-shot stream
Boss_ShieldViperRotateToHalfTurnAfterOrbitShots:        ; DATA XREF: ROM:0004E030   o  ; was: sub_4E81A
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmpi.w  #$180,d0
                bne.s   Boss_ShieldViperPostOrbitHalfTurnWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperPostOrbitHalfTurnWaitReturn:            ; CODE XREF: Boss_ShieldViperRotateToHalfTurnAfterOrbitShots+10   j  ; was: locret_4E830
                rts
; End of function Boss_ShieldViperRotateToHalfTurnAfterOrbitShots
; Move to Y $180, then restart the two-pass tracking cycle
Boss_ShieldViperMoveToLowerBoundaryAndRestartTracking:  ; DATA XREF: ROM:0004E032   o  ; was: sub_4E832
                bsr.w   Boss_ShieldViperMoveRadially
                cmpi.w  #$180,$14(a5)
                blt.s   Boss_ShieldViperLowerBoundaryMovementReturn
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperLowerBoundaryMovementReturn:            ; CODE XREF: Boss_ShieldViperMoveToLowerBoundaryAndRestartTracking+A   j  ; was: locret_4E844
                rts
; End of function Boss_ShieldViperMoveToLowerBoundaryAndRestartTracking
; Double the angular step and seed a 128-frame movement delay
Boss_ShieldViperDoubleAngularStepAndBeginDelay:         ; DATA XREF: ROM:0004E034   o  ; was: sub_4E846
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
; Move throughout the delay, then seed a sixteen-frame flip wait
Boss_ShieldViperWaitAfterAngularStepDoubling:           ; DATA XREF: ROM:0004E036   o  ; was: loc_4E858
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperAngularStepDelayReturn
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperAngularStepDelayReturn:                 ; CODE XREF: Boss_ShieldViperDoubleAngularStepAndBeginDelay+1A   j  ; was: locret_4E86C
                rts
; End of function Boss_ShieldViperDoubleAngularStepAndBeginDelay
; Animate body flip through the final wait before linked-record allocation
Boss_ShieldViperWaitWithHorizontalFlipBeforeLinkedRecords:  ; DATA XREF: ROM:0004E038   o  ; was: sub_4E86E
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedRecordFlipWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedRecordFlipWaitReturn:             ; CODE XREF: Boss_ShieldViperWaitWithHorizontalFlipBeforeLinkedRecords+C   j  ; was: locret_4E880
                rts
; End of function Boss_ShieldViperWaitWithHorizontalFlipBeforeLinkedRecords
; Allocate up to 24 empty records and attach them to successive body records
Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords:     ; DATA XREF: ROM:0004E03A   o  ; was: sub_4E882
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                lea     $60(a5),a1
                move.w  #2,d6
                move.w  #$17,d7
Boss_ShieldViperAllocateLinkedBodyRecordLoop:           ; CODE XREF: Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords+2E   j  ; was: loc_4E892
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ShieldViperFinishLinkedBodyRecordAllocation
                move.w  #$10,(a0)
                move.w  a0,$5C(a1)
                move.w  d6,$48(a1)
                addq.w  #2,4(a1)
                addq.w  #2,d6
                lea     $60(a1),a1
                dbf     d7,Boss_ShieldViperAllocateLinkedBodyRecordLoop
Boss_ShieldViperFinishLinkedBodyRecordAllocation:       ; CODE XREF: Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords+16   j  ; was: loc_4E8B4
                move.w  d6,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAllocateLinkedBodyAuxiliaryRecords
; Wait for the staggered linked-record activation interval, then force flip
Boss_ShieldViperWaitForLinkedRecordActivation:          ; DATA XREF: ROM:0004E03C   o  ; was: sub_4E8BE
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedRecordActivationWaitReturn
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedRecordActivationWaitReturn:       ; CODE XREF: Boss_ShieldViperWaitForLinkedRecordActivation+8   j  ; was: locret_4E8D0
                rts
; End of function Boss_ShieldViperWaitForLinkedRecordActivation
; Build a randomized index order and spawn up to twelve type-$378 projectiles
Boss_ShieldViperSpawnPatternProjectileSet:              ; DATA XREF: ROM:0004E03E   o  ; was: sub_4E8D2
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Boss_ShieldViperBuildPatternProjectileIndexOrder
                lea     (SharedScratchLong8).w,a1
                lea     Boss_ShieldViperPatternProjectileRecords(pc),a2
                nop
                move.w  #$B,d7
                move.w  #$20,d6                         ; ' '
                moveq   #0,d5
Boss_ShieldViperSpawnPatternProjectileLoop:             ; CODE XREF: Boss_ShieldViperSpawnPatternProjectileSet+64   j  ; was: loc_4E8EE
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
Boss_ShieldViperFinishPatternProjectileSpawn:           ; CODE XREF: Boss_ShieldViperSpawnPatternProjectileSet+22   j  ; was: loc_4E93A
                move.w  d6,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperSpawnPatternProjectileSet
; ---------------------------------------------------------------------------
Boss_ShieldViperPatternProjectileRecords:   binclude "data/other/word_4E944.bin"  ; was: word_4E944
Boss_ShieldViperPatternProjectileRecordsEnd:            ; was: word_4E944_End

; Build sixteen group-selected indices and perform eight random swaps
Boss_ShieldViperBuildPatternProjectileIndexOrder:       ; CODE XREF: Boss_ShieldViperSpawnPatternProjectileSet+4   p  ; was: sub_4EAC4
                lea     (SharedScratchLong8).w,a0
                move.w  #9,d7
                moveq   #0,d6
Boss_ShieldViperBuildFirstPatternIndexGroupLoop:        ; CODE XREF: Boss_ShieldViperBuildPatternProjectileIndexOrder+22   j  ; was: loc_4EACE
                jsr     (RandomNumber).l
                move.w  d6,d0
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ShieldViperStoreFirstPatternIndex
                addi.w  #$A,d0
Boss_ShieldViperStoreFirstPatternIndex:                 ; CODE XREF: Boss_ShieldViperBuildPatternProjectileIndexOrder+18   j  ; was: loc_4EAE2
                move.w  d0,(a0)+
                addq.w  #1,d6
                dbf     d7,Boss_ShieldViperBuildFirstPatternIndexGroupLoop
                move.w  #5,d7
                move.w  #$14,d6
Boss_ShieldViperBuildSecondPatternIndexGroupLoop:       ; CODE XREF: Boss_ShieldViperBuildPatternProjectileIndexOrder+46   j  ; was: loc_4EAF2
                jsr     (RandomNumber).l
                move.w  d6,d0
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ShieldViperStoreSecondPatternIndex
                addi.w  #6,d0
Boss_ShieldViperStoreSecondPatternIndex:                ; CODE XREF: Boss_ShieldViperBuildPatternProjectileIndexOrder+3C   j  ; was: loc_4EB06
                move.w  d0,(a0)+
                addq.w  #1,d6
                dbf     d7,Boss_ShieldViperBuildSecondPatternIndexGroupLoop
                lea     (SharedScratchLong8).w,a0
                move.w  #7,d7
                moveq   #0,d6
Boss_ShieldViperShufflePatternIndexLoop:                ; CODE XREF: Boss_ShieldViperBuildPatternProjectileIndexOrder+74   j  ; was: loc_4EB18
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
Boss_ShieldViperWaitForPatternProjectileSequence:       ; DATA XREF: ROM:0004E040   o  ; was: sub_4EB3E
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPatternProjectileWaitReturn
                addq.w  #2,4(a5)
Boss_ShieldViperPatternProjectileWaitReturn:            ; CODE XREF: Boss_ShieldViperWaitForPatternProjectileSequence+8   j  ; was: locret_4EB4C
                rts
; End of function Boss_ShieldViperWaitForPatternProjectileSequence
; Move once and advance after the pattern-projectile sequence
Boss_ShieldViperAdvanceAfterPatternProjectileSequence:  ; DATA XREF: ROM:0004E042   o  ; was: sub_4EB4E
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceAfterPatternProjectileSequence
; Steer toward arena point ($120,$F0) and double the angular step at angle $80
Boss_ShieldViperSteerTowardCenterAndDoubleStepAtQuarterTurn:  ; DATA XREF: ROM:0004E044   o  ; was: sub_4EB58
                bsr.w   Boss_ShieldViperChooseRotationTowardArenaCenterEveryEightFrames
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                move.w  $56(a5),d0
                andi.w  #$1FC,d0
                cmpi.w  #$80,d0
                bne.s   Boss_ShieldViperCenterSteeringReturn
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
                addq.w  #2,4(a5)
Boss_ShieldViperCenterSteeringReturn:                   ; CODE XREF: Boss_ShieldViperSteerTowardCenterAndDoubleStepAtQuarterTurn+14   j  ; was: locret_4EB7A
                rts
; End of function Boss_ShieldViperSteerTowardCenterAndDoubleStepAtQuarterTurn
; Move and advance twice through the two fall-through state entries
Boss_ShieldViperAdvanceTwoStatesWhileMoving:            ; DATA XREF: ROM:0004E046   o  ; was: sub_4EB7C
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
; Perform the second movement and state advance
Boss_ShieldViperAdvanceSecondStateWhileMoving:          ; DATA XREF: ROM:0004E048   o  ; was: loc_4EB84
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceTwoStatesWhileMoving
; Move once and advance to the linked-record release sequence
Boss_ShieldViperAdvanceOneStateWhileMoving:             ; DATA XREF: ROM:0004E04A   o  ; was: sub_4EB8E
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperAdvanceOneStateWhileMoving
; Seed the 64-frame delay before sequential linked-record release
Boss_ShieldViperBeginLinkedRecordReleaseDelay:          ; DATA XREF: ROM:0004E04C   o  ; was: sub_4EB98
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_ShieldViperBeginLinkedRecordReleaseDelay
; After the delay, select the first of 24 body records for sequential release
Boss_ShieldViperPrepareSequentialLinkedRecordRelease:   ; DATA XREF: ROM:0004E04E   o  ; was: sub_4EBAC
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperLinkedRecordReleasePreparationReturn
                lea     $60(a5),a0
                move.w  a0,$4A(a5)
                move.w  #$18,$4C(a5)
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperLinkedRecordReleasePreparationReturn:   ; CODE XREF: Boss_ShieldViperPrepareSequentialLinkedRecordRelease+C   j  ; was: locret_4EBD2
                rts
; End of function Boss_ShieldViperPrepareSequentialLinkedRecordRelease
; Allocate and attach one empty record to each body record at eight-frame intervals
Boss_ShieldViperReleaseLinkedBodyRecordsSequentially:   ; DATA XREF: ROM:0004E050   o  ; was: sub_4EBD4
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
Boss_ShieldViperFinishSequentialLinkedRecordRelease:    ; CODE XREF: Boss_ShieldViperReleaseLinkedBodyRecordsSequentially+2A   j  ; was: loc_4EC10
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_ShieldViperSequentialLinkedRecordReleaseReturn:    ; CODE XREF: Boss_ShieldViperReleaseLinkedBodyRecordsSequentially+C   j  ; was: locret_4EC1A
                                        ; Boss_ShieldViperReleaseLinkedBodyRecordsSequentially+14   j
                rts
; End of function Boss_ShieldViperReleaseLinkedBodyRecordsSequentially
; Wait after release, force flip, double the angular step, and seed 64 frames
Boss_ShieldViperWaitAfterLinkedRecordReleaseAndDoubleAngularStep:  ; DATA XREF: ROM:0004E052   o  ; was: sub_4EC1C
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                bsr.w   Gfx_ShieldViperUpdateHorizontalFlipFromFrameBit
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperPostReleaseAngularStepReturn
                bsr.w   Gfx_ShieldViperForceHorizontalFlip
                move.w  (SharedScratchLong0).w,d0
                add.w   d0,(SharedScratchLong0).w
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_ShieldViperPostReleaseAngularStepReturn:           ; CODE XREF: Boss_ShieldViperWaitAfterLinkedRecordReleaseAndDoubleAngularStep+C   j  ; was: locret_4EC40
                rts
; End of function Boss_ShieldViperWaitAfterLinkedRecordReleaseAndDoubleAngularStep
; After the delay, halve the angular step and restart state $32 tracking
Boss_ShieldViperWaitThenHalveAngularStepAndRestartTracking:  ; DATA XREF: ROM:0004E054   o  ; was: sub_4EC42
                bsr.w   Boss_ShieldViperRotateAndMoveRadially
                subq.w  #1,$48(a5)
                bne.s   Boss_ShieldViperTrackingRestartDelayReturn
                move.w  (SharedScratchLong0).w,d0
                asr.w   #1,d0
                move.w  d0,(SharedScratchLong0).w
                move.w  #$32,4(a5)                      ; '2'
Boss_ShieldViperTrackingRestartDelayReturn:             ; CODE XREF: Boss_ShieldViperWaitThenHalveAngularStepAndRestartTracking+8   j  ; was: locret_4EC5C
                rts
; End of function Boss_ShieldViperWaitThenHalveAngularStepAndRestartTracking
