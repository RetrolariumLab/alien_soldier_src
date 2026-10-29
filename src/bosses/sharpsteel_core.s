; Sharpsteel main controller, entrance, attack selection, and movement states
Boss_SharpsteelMain:                                    ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_47C1C
                tst.w   4(a5)
                beq.w   Boss_SharpsteelDispatchState
                tst.w   8(a5)
                beq.s   Boss_SharpsteelDispatchState
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_SharpsteelUpdatePaletteAndCore
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_SharpsteelUpdatePaletteAndCore
                tst.w   (BossHealth).w
                beq.w   Boss_SharpsteelBeginDefeatFragmentBurst
Boss_SharpsteelUpdatePaletteAndCore:                    ; CODE XREF: Boss_SharpsteelMain+14   j
                                        ; Boss_SharpsteelMain+1C   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                bsr.w   Boss_SharpsteelShiftBladeTargetHistory
Boss_SharpsteelDispatchState:                           ; CODE XREF: Boss_SharpsteelMain+4   j
                                        ; Boss_SharpsteelMain+C   j
                move.w  4(a5),d0
                movea.w Boss_SharpsteelStates(pc,d0.w),a0
                adda.l  #Boss_SharpsteelStateReturn,a0
                jmp     (a0)
; End of function Boss_SharpsteelMain
; ---------------------------------------------------------------------------
Boss_SharpsteelStates:  dc.w    Boss_SharpsteelWaitForPlayerReadyState-Boss_SharpsteelStateReturn
                                        ; DATA XREF: Boss_SharpsteelMain+34   r
                dc.w    Boss_SharpsteelInitializeState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelManualControlState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelOpeningVerticalTurnState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelMoveBladeAssemblyToThresholdState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelBladeAssemblySweepState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelRunBladeEntranceDelayState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelWaitForPlayerAfterBladeEntranceState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelAdvanceBladePartOffsetState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelAccelerateBladeAssemblyState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelBladeAssemblyDelayState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelWaitForTwoBladeTriggersState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelWaitForSevenBladeTriggersState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelWaitForRotationSweepState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelAttackSelectionDelayState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelDefeatFadeAndRemovalState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelFarRangeBladeAttackState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelDiveAttackState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelPostDiveDelayState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelFallingShotCycleState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelWaitBeforeAttackSelectionState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelSelectDistanceAttackState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelWaitForComplexAlignmentState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelAccelerateComplexMotionState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelComplexOscillationState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelBladeShotBurstState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelComplexExitFallState-Boss_SharpsteelStateReturn
                dc.w    Boss_SharpsteelCloseRangeBladeAttackState-Boss_SharpsteelStateReturn

Boss_SharpsteelStateReturn:                             ; CODE XREF: Boss_SharpsteelPostDiveDelayState+4   j
                                        ; DATA XREF: Boss_SharpsteelMain+38   o
                rts
; End of function Boss_SharpsteelStateReturn

; Waits for the shared player-ready word before initializing the encounter
Boss_SharpsteelWaitForPlayerReadyState:                 ; DATA XREF: ROM:Boss_SharpsteelStates   o  ; was: sub_47C96
                tst.w   (MessageSequenceState).w
                bne.s   Boss_SharpsteelWaitForPlayerReadyReturn
                addq.w  #2,4(a5)
                clr.w   8(a5)
Boss_SharpsteelWaitForPlayerReadyReturn:                ; CODE XREF: Boss_SharpsteelWaitForPlayerReadyState+4   j
                rts
; End of function Boss_SharpsteelWaitForPlayerReadyState
; Creates the eighteen-part metasprite and initializes the blade encounter
Boss_SharpsteelInitializeState:                         ; DATA XREF: ROM:00047C5E   o  ; was: sub_47CA6
                addq.w  #1,8(a5)
                movea.w a5,a4
                move.w  #$8300,(MetaspriteBaseTileWord).w
                moveq   #$11,d7
                movea.l #Boss_SharpsteelMetaspriteDescriptors,a0
                movea.l #Boss_SharpsteelPartRadii,a1
                movea.l #Boss_SharpsteelPartLinks,a2
                jsr     (Sprite_InitializeLinkedMetaspriteParts).l
                move.w  #$C300,$36E(a5)
                move.w  #$C300,$4EE(a5)
                move.w  #$21C,(a5)
                move.w  #$CC00,2(a5)
                clr.w   6(a5)
                move.w  #$CC00,$C2(a5)
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetA
                movea.l #Boss_SharpsteelObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                move.w  #2,$1DE(a5)
                bra.w   Boss_SharpsteelInitializeBladeEntrance
; End of function Boss_SharpsteelInitializeState
; Alternate entry that initializes the otherwise unreferenced manual-control state
Boss_SharpsteelInitializeManualControl:
                move.w  #4,4(a5)                        ; was: sub_47D06
                move.w  #$120,$10(a5)
                move.w  #$100,$14(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                clr.b   (BossColorEffectFlags).w
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                moveq   #4,d0
                bsr.w   Boss_SharpsteelSetInnerBladeGroupSizes
; End of function Boss_SharpsteelInitializeManualControl
; Development-style manual controls for core mode and blade angle
Boss_SharpsteelManualControlState:                      ; DATA XREF: ROM:00047C60   o  ; was: sub_47D3C
                btst    #5,(ControllerPressedState).w
                beq.s   Boss_SharpsteelCheckManualCoreActivationInput
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetA
Boss_SharpsteelCheckManualCoreActivationInput:          ; CODE XREF: Boss_SharpsteelManualControlState+6   j
                btst    #4,(ControllerPressedState).w
                beq.s   Boss_SharpsteelCheckManualAngleIncreaseInput
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetB
Boss_SharpsteelCheckManualAngleIncreaseInput:           ; CODE XREF: Boss_SharpsteelManualControlState+12   j
                btst    #2,(ControllerHeldState).w
                beq.s   Boss_SharpsteelCheckManualAngleDecreaseInput
                addq.w  #2,$56(a5)
Boss_SharpsteelCheckManualAngleDecreaseInput:           ; CODE XREF: Boss_SharpsteelManualControlState+1E   j
                btst    #3,(ControllerHeldState).w
                beq.s   Boss_SharpsteelApplyManualAngle
                subq.w  #2,$56(a5)
Boss_SharpsteelApplyManualAngle:                        ; CODE XREF: Boss_SharpsteelManualControlState+2A   j
                andi.w  #$1FE,$56(a5)
                lea     Boss_SharpsteelManualControlPoseCommands(pc),a1
                nop
                bsr.w   Boss_SharpsteelRunBladePoseCommands
                bra.w   Boss_SharpsteelUpdateBladePresentation
; End of function Boss_SharpsteelManualControlState
; Updates the final fade and removes the controller when its timer expires
Boss_SharpsteelDefeatFadeAndRemovalState:               ; DATA XREF: ROM:00047C7A   o  ; was: sub_47D80
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$48(a5)
                bpl.s   Boss_SharpsteelDefeatFadeAndRemovalReturn
                bset    #4,2(a5)
Boss_SharpsteelDefeatFadeAndRemovalReturn:              ; CODE XREF: Boss_SharpsteelDefeatFadeAndRemovalState+A   j
                rts
; End of function Boss_SharpsteelDefeatFadeAndRemovalState
; Initializes the blade entrance sequence and shared encounter parameters
Boss_SharpsteelInitializeBladeEntrance:                 ; CODE XREF: Boss_SharpsteelInitializeState+5C   j  ; was: sub_47D94
                move.w  #$C,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                bset    #3,$182(a5)
                move.w  #$FFE0,$190(a5)
                move.w  #$168,$3D4(a5)
                move.w  #$C7A0,$48(a5)
                move.w  #$C9E0,$4A(a5)
                move.w  #$80,$56(a5)
                move.w  #1,$11C(a5)
                move.w  #$120,$11E(a5)
                move.w  #$A0,$17C(a5)
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetA
                bsr.w   Boss_SharpsteelSetBladePartPriorityBits
                moveq   #$C,d0
                bsr.w   Boss_SharpsteelSetInnerBladeGroupSizes
; End of function Boss_SharpsteelInitializeBladeEntrance
; Runs horizontal/blade motion during the entrance delay
Boss_SharpsteelRunBladeEntranceDelayState:              ; DATA XREF: ROM:00047C68   o  ; was: sub_47DE8
                subq.w  #1,$17C(a5)
                bmi.s   Boss_SharpsteelFinishBladeEntranceDelay
                bsr.w   Boss_SharpsteelUpdateHorizontalAttackMotion
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishBladeEntranceDelay:                ; CODE XREF: Boss_SharpsteelRunBladeEntranceDelayState+4   j
                addq.w  #2,4(a5)
                moveq   #4,d0
                jsr     (BossMessage_Start).l
; End of function Boss_SharpsteelRunBladeEntranceDelayState
; Continues entrance motion until the shared player-ready word clears
Boss_SharpsteelWaitForPlayerAfterBladeEntranceState:    ; DATA XREF: ROM:00047C6A   o  ; was: sub_47E02
                tst.w   (MessageSequenceState).w
                beq.s   Boss_SharpsteelAdvanceFromBladeEntrance
                bsr.w   Boss_SharpsteelUpdateHorizontalAttackMotion
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelAdvanceFromBladeEntrance:                ; CODE XREF: Boss_SharpsteelWaitForPlayerAfterBladeEntranceState+4   j
                addq.w  #2,4(a5)
; Advances one blade-part offset to its entrance threshold
Boss_SharpsteelAdvanceBladePartOffsetState:             ; DATA XREF: ROM:00047C6C   o  ; was: loc_47E14
                addq.w  #1,$3D4(a5)
                cmpi.w  #$1C0,$3D4(a5)
                bpl.s   Boss_SharpsteelFinishBladePartOffsetAdvance
                bsr.w   Boss_SharpsteelUpdateHorizontalAttackMotion
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishBladePartOffsetAdvance:            ; CODE XREF: Boss_SharpsteelWaitForPlayerAfterBladeEntranceState+1C   j
                bclr    #3,$182(a5)
                addq.w  #2,4(a5)
                bsr.w   Boss_SharpsteelInitializeFallingShotCycle
; End of function Boss_SharpsteelWaitForPlayerAfterBladeEntranceState
; Accelerates the blade assembly while its fixed-point travel value remains nonnegative
Boss_SharpsteelAccelerateBladeAssemblyState:            ; DATA XREF: ROM:00047C6E   o  ; was: sub_47E36
                subi.l  #$22000,$2FC(a5)
                bmi.s   Boss_SharpsteelFinishBladeAssemblyAcceleration
                move.w  (SharpsteelTargetTrail).w,$190(a5)
                bsr.w   Boss_SharpsteelUpdateBladeTargetVelocity
                lea     Boss_SharpsteelAssemblyDelayPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishBladeAssemblyAcceleration:         ; CODE XREF: Boss_SharpsteelAccelerateBladeAssemblyState+8   j
                addq.w  #2,4(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                move.b  #$10,$E1(a5)
; Holds the blade assembly for the configured post-acceleration delay
Boss_SharpsteelBladeAssemblyDelayState:                 ; DATA XREF: ROM:00047C70   o  ; was: loc_47E64
                subq.w  #1,$11C(a5)
                bmi.s   Boss_SharpsteelFinishBladeAssemblyDelay
                move.w  (SharpsteelTargetTrail).w,$190(a5)
                bsr.w   Boss_SharpsteelUpdateBladeTargetVelocity
                lea     Boss_SharpsteelAssemblyDelayPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishBladeAssemblyDelay:                ; CODE XREF: Boss_SharpsteelAccelerateBladeAssemblyState+32   j
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $29C(a5)
                bsr.w   Boss_SharpsteelSetBladeGroupBPriorityBits
                bsr.w   Boss_SharpsteelSetBladeGroupAPriorityBits
; End of function Boss_SharpsteelAccelerateBladeAssemblyState
; Runs blade assembly motion until two trigger events have completed
Boss_SharpsteelWaitForTwoBladeTriggersState:            ; DATA XREF: ROM:00047C72   o  ; was: sub_47E98
                cmpi.w  #2,$29C(a5)
                bpl.s   Boss_SharpsteelBeginSevenBladeTriggerWait
Boss_SharpsteelUpdateBladeAssemblyMotion:               ; CODE XREF: Boss_SharpsteelWaitForTwoBladeTriggersState+30   j
                                        ; Boss_SharpsteelWaitForTwoBladeTriggersState+50   j
                move.w  (SharpsteelTargetTrail).w,$190(a5)
                bsr.w   Boss_SharpsteelUpdateBladeTargetVelocity
                lea     Boss_SharpsteelAssemblyTriggerPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelBeginSevenBladeTriggerWait:              ; CODE XREF: Boss_SharpsteelWaitForTwoBladeTriggersState+6   j
                addq.w  #2,4(a5)
                addq.w  #2,(Entity59State).w
; Continues blade assembly motion until seven trigger events have completed
Boss_SharpsteelWaitForSevenBladeTriggersState:          ; DATA XREF: ROM:00047C74   o  ; was: loc_47EBC
                cmpi.w  #7,$29C(a5)
                bpl.s   Boss_SharpsteelBeginRotationSweep
                bsr.w   Boss_SharpsteelPublishBladePartTargets
                bra.s   Boss_SharpsteelUpdateBladeAssemblyMotion
; ---------------------------------------------------------------------------
Boss_SharpsteelBeginRotationSweep:                      ; CODE XREF: Boss_SharpsteelWaitForTwoBladeTriggersState+2A   j
                addq.w  #2,4(a5)
                addq.w  #2,(Entity59State).w
                move.l  #$FFFD8000,(Entity59XVel).w
                move.l  #$FFFD0000,(Entity59YVel).w
; Waits for the signed rotation-sweep completion flag
Boss_SharpsteelWaitForRotationSweepState:               ; DATA XREF: ROM:00047C76   o  ; was: loc_47EE2
                tst.w   $58(a5)
                bmi.s   Boss_SharpsteelFinishRotationSweep
                bra.s   Boss_SharpsteelUpdateBladeAssemblyMotion
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishRotationSweep:                     ; CODE XREF: Boss_SharpsteelWaitForTwoBladeTriggersState+4E   j
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                bsr.w   Boss_SharpsteelFillBladeTargetHistory
; End of function Boss_SharpsteelWaitForTwoBladeTriggersState
; Holds the pre-selection delay while updating the blade pose
Boss_SharpsteelAttackSelectionDelayState:               ; DATA XREF: ROM:00047C78   o  ; was: sub_47F02
                subq.w  #1,$11C(a5)
                bpl.s   Boss_SharpsteelUpdateAttackSelectionDelayPose
                clr.b   (BossColorEffectFlags).w
                move.w  #$B,$35C(a5)
                bra.w   Boss_SharpsteelAdvanceAttackSelection
; ---------------------------------------------------------------------------
Boss_SharpsteelUpdateAttackSelectionDelayPose:          ; CODE XREF: Boss_SharpsteelAttackSelectionDelayState+4   j
                bsr.w   Boss_SharpsteelLoadBladeTargetHistoryTail
                lea     Boss_SharpsteelAssemblyDelayPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; End of function Boss_SharpsteelAttackSelectionDelayState
; Publishes two blade-part coordinates to the shared target words
Boss_SharpsteelPublishBladePartTargets:                 ; CODE XREF: Boss_SharpsteelWaitForTwoBladeTriggersState+2C   p  ; was: sub_47F24
                move.w  $370(a5),d0
                addi.w  #0,d0
                move.w  d0,(Entity59XPos).w
                move.w  $374(a5),d0
                addi.w  #-$10,d0
                move.w  d0,(Entity59YPos).w
                rts
; End of function Boss_SharpsteelPublishBladePartTargets
; Initializes the vertical opening and later ten-shot falling-projectile cycle
Boss_SharpsteelInitializeFallingShotCycle:              ; CODE XREF: Boss_SharpsteelWaitForPlayerAfterBladeEntranceState+30   p  ; was: sub_47F3E
                                        ; Boss_SharpsteelOpeningVerticalTurnState+F0   p
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$C7A0,$48(a5)
                move.w  #$C7A0,$4A(a5)
                move.w  #$120,$194(a5)
                move.w  #$120,$190(a5)
                move.b  #$10,(PlayerOAMBucketOffset).w
                move.l  #$E00000,$2FC(a5)
                bsr.w   Boss_SharpsteelDisableCoreSegmentCollision
                move.w  #$FFD8,$35E(a5)
                move.w  #0,$3BC(a5)
                move.w  #1,$3BE(a5)
                clr.w   $56(a5)
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetB
                bsr.w   Boss_SharpsteelClearBladePartPriorityBits
                moveq   #$18,d0
                bsr.w   Boss_SharpsteelSetInnerBladeGroupSizes
                moveq   #$18,d0
                bra.w   Boss_SharpsteelSelectOuterBladeGroup
; End of function Boss_SharpsteelInitializeFallingShotCycle
; Loads the sixth blade-target history sample into the active target field
Boss_SharpsteelLoadBladeTargetHistoryTail:              ; CODE XREF: Boss_SharpsteelAttackSelectionDelayState:Boss_SharpsteelUpdateAttackSelectionDelayPose   p  ; was: sub_47F9C
                                        ; Boss_SharpsteelInitializeAttackSelection+10   p
                move.w  (SharpsteelTargetTail).w,$190(a5)
; End of function Boss_SharpsteelLoadBladeTargetHistoryTail
; Derives the blade target velocity from shared motion and the travel accumulator
Boss_SharpsteelUpdateBladeTargetVelocity:               ; CODE XREF: Boss_SharpsteelAccelerateBladeAssemblyState+10   p  ; was: sub_47FA2
                                        ; Boss_SharpsteelAccelerateBladeAssemblyState+3A   p
                move.w  (Entity57YPos).w,d0
                add.w   $2FC(a5),d0
                addi.w  #-$C,d0
                move.w  d0,$194(a5)
                rts
; End of function Boss_SharpsteelUpdateBladeTargetVelocity
; Fills all six blade-target history samples with the current shared target
Boss_SharpsteelFillBladeTargetHistory:                  ; CODE XREF: Boss_SharpsteelWaitForTwoBladeTriggersState+66   p  ; was: sub_47FB4
                movea.w #(SharpsteelTargetTrail-M68K_RAM),a0
                move.w  (Entity57XPos).w,d1
                addi.w  #$74,d1                         ; 't'
                moveq   #5,d7
Boss_SharpsteelFillBladeTargetHistoryLoop:              ; CODE XREF: Boss_SharpsteelFillBladeTargetHistory+10   j
                move.w  d1,(a0)+
                dbf     d7,Boss_SharpsteelFillBladeTargetHistoryLoop
                rts
; End of function Boss_SharpsteelFillBladeTargetHistory
; Shifts a new shared target through the six-sample blade history
Boss_SharpsteelShiftBladeTargetHistory:                 ; CODE XREF: Boss_SharpsteelMain+2C   p  ; was: sub_47FCA
                movea.w #(SharpsteelTargetTrail-M68K_RAM),a0
                move.w  (Entity57XPos).w,d1
                addi.w  #$74,d1                         ; 't'
                moveq   #5,d7
Boss_SharpsteelShiftBladeTargetHistoryLoop:             ; CODE XREF: Boss_SharpsteelShiftBladeTargetHistory+14   j
                move.w  (a0),d0
                move.w  d1,(a0)+
                move.w  d0,d1
                dbf     d7,Boss_SharpsteelShiftBladeTargetHistoryLoop
                rts
; End of function Boss_SharpsteelShiftBladeTargetHistory
; Selects alternating horizontal targets, accelerates toward them, and updates blade pose
Boss_SharpsteelUpdateHorizontalAttackMotion:            ; CODE XREF: Boss_SharpsteelRunBladeEntranceDelayState+6   p  ; was: sub_47FE4
                                        ; Boss_SharpsteelWaitForPlayerAfterBladeEntranceState+6   p
                btst    #0,$23E(a5)
                beq.s   Boss_SharpsteelUpdateHorizontalTargetAndVelocity
                moveq   #2,d7
                move.w  $2B0(a5),d5
                bsr.w   Boss_SharpsteelSpawnRandomAngleShots
Boss_SharpsteelUpdateHorizontalTargetAndVelocity:       ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+6   j
                move.w  $10(a5),d0
                move.l  $198(a5),d1
                tst.w   $11C(a5)
                bmi.s   Boss_SharpsteelHandleLeftwardTarget
                cmp.w   $11E(a5),d0
                bmi.s   Boss_SharpsteelAccelerateHorizontalMotionRight
                move.w  #$FFFF,$11C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addq.w  #8,d0
                neg.w   d0
                add.w   $10(a5),d0
                move.w  d0,$11E(a5)
                cmpi.w  #$B0,d0
                bpl.s   Boss_SharpsteelStoreLeftwardVelocity
                move.w  #$B0,$11E(a5)
                bra.s   Boss_SharpsteelStoreLeftwardVelocity
; ---------------------------------------------------------------------------
Boss_SharpsteelAccelerateHorizontalMotionRight:         ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+24   j
                tst.l   d1
                bmi.s   Boss_SharpsteelStoreRightwardVelocity
                cmpi.l  #$10000,d1
                bpl.s   Boss_SharpsteelUseHighSpeedBladePose
Boss_SharpsteelStoreRightwardVelocity:                  ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+50   j
                                        ; Boss_SharpsteelUpdateHorizontalAttackMotion+8E   j
                addi.l  #$E00,d1
                move.l  d1,$198(a5)
                lea     Boss_SharpsteelRightwardPoseCommands(pc),a1
                nop
                rts
; ---------------------------------------------------------------------------
Boss_SharpsteelHandleLeftwardTarget:                    ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+1E   j
                cmp.w   $11E(a5),d0
                bpl.s   Boss_SharpsteelAccelerateHorizontalMotionLeft
                move.w  #1,$11C(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$3F,d0                         ; '?'
                addq.w  #8,d0
                add.w   $10(a5),d0
                move.w  d0,$11E(a5)
                cmpi.w  #$160,d0
                bmi.s   Boss_SharpsteelStoreRightwardVelocity
                move.w  #$160,$11E(a5)
                bra.s   Boss_SharpsteelStoreRightwardVelocity
; ---------------------------------------------------------------------------
Boss_SharpsteelAccelerateHorizontalMotionLeft:          ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+70   j
                tst.l   d1
                bpl.s   Boss_SharpsteelStoreLeftwardVelocity
                cmpi.l  #$FFFE2000,d1
                bmi.s   Boss_SharpsteelUseHighSpeedBladePose
Boss_SharpsteelStoreLeftwardVelocity:                   ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+44   j
                                        ; Boss_SharpsteelUpdateHorizontalAttackMotion+4C   j
                subi.l  #$2000,d1
                move.l  d1,$198(a5)
Boss_SharpsteelUseHighSpeedBladePose:                   ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+58   j
                                        ; Boss_SharpsteelUpdateHorizontalAttackMotion+A2   j
                lea     Boss_SharpsteelHighSpeedPoseCommands(pc),a1
                nop
                rts
; End of function Boss_SharpsteelUpdateHorizontalAttackMotion
; Emits the requested count of generic shots at randomized angles
Boss_SharpsteelSpawnRandomAngleShots:                   ; CODE XREF: Boss_SharpsteelUpdateHorizontalAttackMotion+E   p  ; was: sub_4809A
                move.w  #$150,d6
                movea.w #(RandomNumberState-M68K_RAM),a4
Boss_SharpsteelSpawnRandomAngleShotsLoop:               ; CODE XREF: Boss_SharpsteelSpawnRandomAngleShots+1A   j
                move.b  (a4)+,d4
                andi.w  #$3E,d4                         ; '>'
                addi.w  #$120,d4
                jsr     (Projectile_SpawnType1A8AtAngle).l
                bne.s   Boss_SharpsteelFinishRandomAngleShotEmission
                dbf     d7,Boss_SharpsteelSpawnRandomAngleShotsLoop
Boss_SharpsteelFinishRandomAngleShotEmission:           ; CODE XREF: Boss_SharpsteelSpawnRandomAngleShots+18   j
                move.b  #$4C,d0                         ; 'L'
                jmp     (Sound_QueueSFXRequest).l
; End of function Boss_SharpsteelSpawnRandomAngleShots
; Enters the distance-based attack selector after the inter-cycle delay
Boss_SharpsteelInitializeAttackSelection:               ; CODE XREF: Boss_SharpsteelFallingShotCycleState+38   j  ; was: sub_480C2
                move.w  #$2A,4(a5)                      ; '*'
                clr.w   $23E(a5)
; Chooses another attack cycle or updates the idle selection pose
Boss_SharpsteelSelectDistanceAttackState:               ; DATA XREF: ROM:00047C86   o  ; was: loc_480CC
                tst.w   $23E(a5)
                bne.s   Boss_SharpsteelAdvanceAttackSelection
                bsr.w   Boss_SharpsteelLoadBladeTargetHistoryTail
                lea     Boss_SharpsteelAssemblyDelayPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelAdvanceAttackSelection:                  ; CODE XREF: Boss_SharpsteelAttackSelectionDelayState+10   j
                                        ; Boss_SharpsteelInitializeAttackSelection+E   j
                subq.w  #1,$35C(a5)
                bpl.s   Boss_SharpsteelChooseAttackByPlayerDistance
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,$11C(a5)
                move.b  (RandomNumberState).w,d0
                andi.w  #1,d0
                addq.w  #1,d0
                move.w  d0,$35C(a5)
                bra.w   Boss_SharpsteelInitializeDiveAttack
; ---------------------------------------------------------------------------
Boss_SharpsteelChooseAttackByPlayerDistance:            ; CODE XREF: Boss_SharpsteelInitializeAttackSelection+22   j
                jsr     (Physics_GetPlayerDelta).l
                move.b  (RandomNumberState).w,d2
                clr.w   $54(a5)
                tst.w   d1
                bmi.w   Boss_SharpsteelCheckPlayerHorizontalDistance
                move.w  #$100,$54(a5)
Boss_SharpsteelCheckPlayerHorizontalDistance:           ; CODE XREF: Boss_SharpsteelInitializeAttackSelection+56   j
                cmpi.w  #$3C,d0                         ; '<'
                bpl.s   Boss_SharpsteelSelectFarRangeBladeAttack
                bra.w   Boss_SharpsteelInitializeCloseRangeBladeAttack
; ---------------------------------------------------------------------------
Boss_SharpsteelSelectFarRangeBladeAttack:               ; CODE XREF: Boss_SharpsteelInitializeAttackSelection+64   j
                bra.w   *+4
; ---------------------------------------------------------------------------
Boss_SharpsteelInitializeFarRangeBladeAttack:           ; CODE XREF: Boss_SharpsteelInitializeAttackSelection:Boss_SharpsteelSelectFarRangeBladeAttack   j
                move.w  #$20,4(a5)                      ; ' '
                clr.w   $58(a5)
                clr.w   $23E(a5)
                move.w  #$FFFF,$C(a5)
                bsr.w   Boss_SharpsteelClearBladePartPriorityBits
                moveq   #$40,d0                         ; '@'
                bsr.w   Boss_SharpsteelSetInnerBladeGroupSizes
; End of function Boss_SharpsteelInitializeAttackSelection
; Runs the far-range blade attack and its animation-triggered hitbox/flash events
Boss_SharpsteelFarRangeBladeAttackState:                ; DATA XREF: ROM:00047C7C   o  ; was: sub_4814E
                tst.w   $58(a5)
                bmi.w   Boss_SharpsteelAdvanceAttackSelection
                btst    #0,$23E(a5)
                beq.s   Boss_SharpsteelTriggerFarRangeBladeHitbox
                bsr.w   Boss_SharpsteelSetBladeGroupAPriorityBits
                move.w  #$A7,d1
                bsr.w   Boss_SharpsteelEnableInnerBladeHitboxes
                move.b  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_SharpsteelTriggerFarRangeBladeHitbox:              ; CODE XREF: Boss_SharpsteelFarRangeBladeAttackState+E   j
                btst    #1,$23E(a5)
                beq.s   Boss_SharpsteelUpdateFarRangeBladePose
                bsr.w   Boss_SharpsteelDisableInnerBladeHitboxes
Boss_SharpsteelUpdateFarRangeBladePose:                 ; CODE XREF: Boss_SharpsteelFarRangeBladeAttackState+2C   j
                bsr.w   Boss_SharpsteelLoadBladeTargetHistoryTail
                lea     Boss_SharpsteelFarRangeAttackPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelInitializeCloseRangeBladeAttack:         ; CODE XREF: Boss_SharpsteelInitializeAttackSelection+66   j
                move.w  #$36,4(a5)                      ; '6'
                clr.w   $58(a5)
                clr.w   $23E(a5)
                move.w  #$FFFF,$C(a5)
                bsr.w   Boss_SharpsteelClearBladePartPriorityBits
                moveq   #$10,d0
                bsr.w   Boss_SharpsteelSetInnerBladeGroupSizes
; End of function Boss_SharpsteelFarRangeBladeAttackState
; Runs the close-range blade attack and its animation-triggered hitbox/flash events
Boss_SharpsteelCloseRangeBladeAttackState:              ; DATA XREF: ROM:00047C92   o  ; was: sub_481AC
                tst.w   $58(a5)
                bmi.w   Boss_SharpsteelAdvanceAttackSelection
                btst    #0,$23E(a5)
                beq.s   Boss_SharpsteelTriggerCloseRangeBladeHitbox
                bsr.w   Boss_SharpsteelSetBladeGroupAPriorityBits
                move.w  #$82,d1
                bsr.w   Boss_SharpsteelEnableInnerBladeHitboxes
                move.b  #$DC,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_SharpsteelTriggerCloseRangeBladeHitbox:            ; CODE XREF: Boss_SharpsteelCloseRangeBladeAttackState+E   j
                btst    #1,$23E(a5)
                beq.s   Boss_SharpsteelUpdateCloseRangeBladePose
                bsr.w   Boss_SharpsteelDisableInnerBladeHitboxes
                bsr.w   Boss_SharpsteelSetOuterBladeGroupSizes
Boss_SharpsteelUpdateCloseRangeBladePose:               ; CODE XREF: Boss_SharpsteelCloseRangeBladeAttackState+2C   j
                bsr.w   Boss_SharpsteelLoadBladeTargetHistoryTail
                lea     Boss_SharpsteelCloseRangeAttackPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; End of function Boss_SharpsteelCloseRangeBladeAttackState
; Initializes the vertical dive attack, blade pose, collision, and palette state
Boss_SharpsteelInitializeDiveAttack:                    ; CODE XREF: Boss_SharpsteelInitializeAttackSelection+42   j  ; was: sub_481F0
                move.w  #$22,4(a5)                      ; '"'
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $11E(a5)
                clr.w   $54(a5)
                move.w  #6,$35E(a5)
                move.w  #0,$3BC(a5)
                move.w  #2,$3BE(a5)
                move.w  #$C6E0,$48(a5)
                move.w  #$C6E0,$4A(a5)
                clr.l   $D8(a5)
                move.l  #$FFFDC000,$DC(a5)
                bsr.w   Boss_SharpsteelDisableCoreSegmentCollision
                bsr.w   Boss_SharpsteelClearBladeGroupAPriorityBits
                bsr.w   Boss_SharpsteelClearBladeGroupBPriorityBits
                bsr.w   Boss_SharpsteelClearBladePartPriorityBits
                bsr.w   Boss_SharpsteelSetOuterBladeGroupSizes
; End of function Boss_SharpsteelInitializeDiveAttack
; Advances the vertical dive, spawning its one-shot effect after crossing Y $160
Boss_SharpsteelDiveAttackState:                         ; DATA XREF: ROM:00047C7E   o  ; was: sub_48246
                cmpi.w  #$200,$14(a5)
                bpl.w   Boss_SharpsteelStopAfterDive
                addi.l  #$4000,$DC(a5)
                tst.w   $11E(a5)
                bne.s   Boss_SharpsteelUpdateDiveAttackPose
                cmpi.w  #$160,$14(a5)
                bmi.s   Boss_SharpsteelUpdateDiveAttackPose
                addq.w  #1,$11E(a5)
                move.w  $10(a5),d5
                move.w  #$150,d6
                moveq   #$60,d3                         ; '`'
                clr.w   (GlobalSpritePriorityBit).w
                jsr     (Projectile_SpawnFourDirectionalShotsWithSubtypeInD3).l
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.b  #$4D,d0                         ; 'M'
                jsr     (Sound_QueueSFXRequest).l
Boss_SharpsteelUpdateDiveAttackPose:                    ; CODE XREF: Boss_SharpsteelDiveAttackState+16   j
                                        ; Boss_SharpsteelDiveAttackState+1E   j
                lea     Boss_SharpsteelDivePoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; End of function Boss_SharpsteelDiveAttackState
; Stops vertical motion and initializes the fixed post-dive delay
Boss_SharpsteelInitializePostDiveDelay:                 ; CODE XREF: Boss_SharpsteelOpeningVerticalTurnState+DC   j  ; was: sub_48298
                move.w  (RandomNumberState).w,d0
                move.w  #$F,d0
                addi.w  #$10,d0
                move.w  d0,$11C(a5)
Boss_SharpsteelStopAfterDive:                           ; CODE XREF: Boss_SharpsteelDiveAttackState+6   j
                move.w  #$24,4(a5)                      ; '$'
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                bsr.w   Boss_SharpsteelDisableCoreSegmentCollision
; End of function Boss_SharpsteelInitializePostDiveDelay
; Waits after the dive, then selects a falling-shot cycle or the next phase
Boss_SharpsteelPostDiveDelayState:                      ; DATA XREF: ROM:00047C80   o  ; was: sub_482C2
                subq.w  #1,$11C(a5)
                bpl.w   Boss_SharpsteelStateReturn
Boss_SharpsteelSelectPostDiveCycle:                     ; CODE XREF: Boss_SharpsteelWaitForComplexAlignmentState+112   j
                subq.w  #1,$35C(a5)
                bpl.s   Boss_SharpsteelInitializeFallingShotCycleFromDelay
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                addq.w  #6,d0
                move.w  d0,$35C(a5)
                bra.w   Boss_SharpsteelInitializeFallingShotCycleFromSelection
; ---------------------------------------------------------------------------
Boss_SharpsteelInitializeFallingShotCycleFromDelay:     ; CODE XREF: Boss_SharpsteelPostDiveDelayState+C   j
                move.w  #6,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$120,$D0(a5)
                move.w  #$190,$D4(a5)
                clr.w   $56(a5)
                move.w  #$C6E0,$48(a5)
                move.w  #$C6E0,$4A(a5)
                clr.l   $D8(a5)
                move.l  #$FFF80000,$DC(a5)
                move.w  #$FFE4,$35E(a5)
                move.w  #1,$3BC(a5)
                move.w  #1,$3BE(a5)
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetB
                bsr.w   Boss_SharpsteelClearBladePartPriorityBits
                bsr.w   Boss_SharpsteelSetOuterBladeGroupSizes
                bsr.w   Boss_SharpsteelSpawnTenFallingShots
                move.b  #$4C,d0                         ; 'L'
                jsr     (Sound_QueueSFXRequest).l
; End of function Boss_SharpsteelPostDiveDelayState
; Turns the opening vertical motion before the blade-assembly sweep
Boss_SharpsteelOpeningVerticalTurnState:                ; DATA XREF: ROM:00047C62   o  ; was: sub_48346
                addi.l  #$1400,$DC(a5)
                bpl.s   Boss_SharpsteelFinishOpeningVerticalTurn
                lea     Boss_SharpsteelOpeningTurnPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishOpeningVerticalTurn:               ; CODE XREF: Boss_SharpsteelOpeningVerticalTurnState+8   j
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  #$100,$56(a5)
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetB
                bsr.w   Boss_SharpsteelSetBladePartPriorityBits
                bsr.w   Boss_SharpsteelEnableCoreSegmentCollision
; Moves the blade assembly to the shared vertical threshold
Boss_SharpsteelMoveBladeAssemblyToThresholdState:       ; DATA XREF: ROM:00047C64   o  ; was: loc_4837A
                addi.l  #$2000,$DC(a5)
                move.w  (Entity57YPos).w,d0
                subi.w  #$20,d0                         ; ' '
                cmp.w   $D4(a5),d0
                bmi.s   Boss_SharpsteelBeginBladeAssemblySweep
                lea     Boss_SharpsteelAssemblyThresholdPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelBeginBladeAssemblySweep:                 ; CODE XREF: Boss_SharpsteelOpeningVerticalTurnState+48   j
                addq.w  #2,4(a5)
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                clr.w   $11E(a5)
                move.w  #8,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.b  #$2F,d0                         ; '/'
                jsr     (Sound_QueueSFXRequest).l
                move.l  #$20000,(Entity57YVel).w
                move.w  #2,(Entity57Work58).w
                moveq   #0,d0
                move.w  #$B0,d0
                sub.w   (Entity57XPos).w,d0
                swap    d0
                asr.l   #5,d0
                move.l  d0,$D8(a5)
                move.l  #$FFFD8000,$DC(a5)
; Sweeps the blade assembly through the player-height trigger and lower bound
Boss_SharpsteelBladeAssemblySweepState:                 ; DATA XREF: ROM:00047C66   o  ; was: loc_483EA
                addi.l  #$3A00,$DC(a5)
                tst.w   $11E(a5)
                bne.s   Boss_SharpsteelUpdateBladeAssemblySweepPose
                cmpi.w  #$160,$D4(a5)
                bmi.s   Boss_SharpsteelUpdateBladeAssemblySweepPose
                addq.w  #1,$11E(a5)
                move.w  $10(a5),d5
                move.w  #$150,d6
                jsr     (Projectile_SpawnFourDirectionalShots).l
                move.b  #$4C,d0                         ; 'L'
                jsr     (Sound_QueueSFXRequest).l
Boss_SharpsteelUpdateBladeAssemblySweepPose:            ; CODE XREF: Boss_SharpsteelOpeningVerticalTurnState+B0   j
                                        ; Boss_SharpsteelOpeningVerticalTurnState+B8   j
                cmpi.w  #$240,$D4(a5)
                bpl.w   Boss_SharpsteelInitializePostDiveDelay
                lea     Boss_SharpsteelAssemblySweepPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelInitializeFallingShotCycleFromSelection:  ; CODE XREF: Boss_SharpsteelPostDiveDelayState+1C   j
                move.w  #$26,4(a5)                      ; '&'
                bsr.w   Boss_SharpsteelInitializeFallingShotCycle
; End of function Boss_SharpsteelOpeningVerticalTurnState
; Runs the falling-shot cycle until its fixed-point travel accumulator expires
Boss_SharpsteelFallingShotCycleState:                   ; DATA XREF: ROM:00047C82   o  ; was: sub_4843A
                subi.l  #$22000,$2FC(a5)
                bmi.s   Boss_SharpsteelFinishFallingShotCycle
                cmpi.w  #$60,$2FC(a5)                   ; '`'
                bmi.s   Boss_SharpsteelUpdateFallingShotCyclePose
                bsr.w   Boss_SharpsteelFallingShotCycleThresholdHook
Boss_SharpsteelUpdateFallingShotCyclePose:              ; CODE XREF: Boss_SharpsteelFallingShotCycleState+10   j
                bsr.w   Boss_SharpsteelLoadBladeTargetHistoryTail
                lea     Boss_SharpsteelAssemblyDelayPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; ---------------------------------------------------------------------------
Boss_SharpsteelFinishFallingShotCycle:                  ; CODE XREF: Boss_SharpsteelFallingShotCycleState+8   j
                addq.w  #2,4(a5)
                move.w  #$20,$11C(a5)                   ; ' '
                move.b  #$10,$E1(a5)
; Waits before entering the distance-based attack selector
Boss_SharpsteelWaitBeforeAttackSelectionState:          ; DATA XREF: ROM:00047C84   o  ; was: loc_4846E
                subq.w  #1,$11C(a5)
                bmi.w   Boss_SharpsteelInitializeAttackSelection
                bsr.w   Boss_SharpsteelLoadBladeTargetHistoryTail
                lea     Boss_SharpsteelAssemblyDelayPoses(pc),a1
                nop
                bra.w   Boss_SharpsteelUpdateBladeAssembly
; End of function Boss_SharpsteelFallingShotCycleState
Boss_SharpsteelFallingShotCycleThresholdHook:           ; CODE XREF: Boss_SharpsteelFallingShotCycleState+12   p
                rts
; End of function Boss_SharpsteelFallingShotCycleThresholdHook

; Initializes state $2C and its position, velocity, hitboxes, and animation data
Boss_SharpsteelInitializeComplexPhase:
                move.w  #$2C,4(a5)                      ; ','  ; was: sub_48486
                clr.w   $58(a5)
                move.w  #$FFFF,$C(a5)
                move.w  (Entity57XPos).w,d0
                addi.w  #$74,d0                         ; 't'
                move.w  d0,$10(a5)
                move.w  #$200,$14(a5)
                clr.w   $56(a5)
                move.w  a5,$48(a5)
                move.w  a5,$4A(a5)
                clr.l   $18(a5)
                move.l  #$FFFD0000,$1C(a5)
                bsr.w   Boss_SharpsteelConfigureBladeGraphicsSetB
                bsr.w   Boss_SharpsteelSetBladePartPriorityBits
                movea.l #Boss_SharpsteelComplexPhaseInitialPose,a0
                bsr.w   Boss_SharpsteelInitializeBladePoseChannels
                move.w  #$FFD8,$35E(a5)
                move.w  #0,$3BC(a5)
                move.w  #1,$3BE(a5)
; End of function Boss_SharpsteelInitializeComplexPhase
