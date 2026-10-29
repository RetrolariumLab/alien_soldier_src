; Stage 12 yacht controller and the rescued teddy-bear pilot
; Pinned TAS evidence: controller entry at frame 23660, pilot entry at 23676

Stage12_YachtControllerMain:                            ; was: sub_2F5C0
                move.l  $54(a5),d0
                add.l   d0,(SecondaryCameraXPos).w
                move.w  4(a5),d0
                movea.w Stage12_YachtControllerStateTable(pc,d0.w),a0
                adda.l  #Stage12_YachtControllerInit,a0
                jmp     (a0)
; End of function Stage12_YachtControllerMain
; ---------------------------------------------------------------------------
Stage12_YachtControllerStateTable:  dc.w    Stage12_YachtControllerInit-Stage12_YachtControllerInit
                dc.w    Stage12_YachtControllerIdle-Stage12_YachtControllerInit
                dc.w    Stage12_YachtRevealPan-Stage12_YachtControllerInit
                dc.w    Stage12_YachtBeginMotion-Stage12_YachtControllerInit
                dc.w    Stage12_YachtActiveState-Stage12_YachtControllerInit
                dc.w    Stage12_YachtRecoveryState-Stage12_YachtControllerInit
                dc.w    Stage12_YachtPostSignalState-Stage12_YachtControllerInit
                dc.w    Stage12_YachtDestructionState-Stage12_YachtControllerInit

; Initializes the invisible Stage 12 yacht controller
Stage12_YachtControllerInit:                            ; was: sub_2F5E8
                                        ; ROM:Stage12_YachtControllerStateTable   o
                addq.w  #2,4(a5)
                move.w  #$8D00,2(a5)
                move.w  #1,$24(a5)
                clr.w   $50(a5)
                clr.l   $54(a5)
                clr.w   $58(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.b  #$20,$21(a5)                    ; ' '
                move.w  #2,$46(a5)
                move.l  #$FFFC00F0,$28(a5)
                move.w  $10(a5),$4C(a5)
                move.w  $14(a5),$4E(a5)
; Idle state used until the stage script advances the controller
Stage12_YachtControllerIdle:                            ; was: locret_2F62C
                rts
; End of function Stage12_YachtControllerInit
; Reveals the yacht by rendering with a temporary camera offset
Stage12_YachtRevealPan:                                 ; was: sub_2F62E
                move.l  (PrimaryCameraXPosition).w,-(sp)
                move.w  $50(a5),d0
                add.w   d0,(PrimaryCameraXPosition).w
                jsr     (Tilemap_QueuePrimaryCameraColumnOffset158).l
                move.l  (sp)+,(PrimaryCameraXPosition).w
                addq.w  #8,$50(a5)
                cmpi.w  #$90,$50(a5)
                bmi.w   Stage12_YachtControllerReturn
                move.w  #$38,(RasterEffectIndex).w      ; '8'
                move.b  #3,(PlaneAScrollModeFlags).w
                bset    #7,(StageObjectSpawnCursor).w
                addq.w  #2,4(a5)
                move.b  #$8B,d0
                jmp     Sound_QueueBGMOrStop
; End of function Stage12_YachtRevealPan
; Starts the yacht's active vertical-motion phase
Stage12_YachtBeginMotion:                               ; was: sub_2F672
                move.b  #$55,d0                         ; 'U'
                jsr     (Sound_QueueSFXRequest).l
Stage12_YachtBeginVerticalBob:
                move.w  #2,$58(a5)
                move.l  #$22000,$1C(a5)
                move.w  #8,4(a5)
; Active yacht state: reacts to stage signals and updates motion and scroll
Stage12_YachtActiveState:                               ; was: loc_2F690
                tst.w   $24(a5)
                bmi.w   Stage12_YachtBeginDestruction
                bclr    #1,$5A(a5)
                bne.s   Stage12_YachtBeginRecovery
                bclr    #0,$5A(a5)
                bne.s   Stage12_YachtAdvancePastSignal
                bsr.w   Stage12_YachtUpdateVerticalBob
                bsr.w   Stage12_YachtAccelerateScroll
                bsr.w   Stage12_YachtApplySteering
                bsr.w   Stage12_YachtUpdateScrollPreset
                bra.w   Stage12_YachtUpdatePlaneOffsets
; ---------------------------------------------------------------------------
Stage12_YachtBeginRecovery:
                                        ; Stage12_YachtBeginMotion+80   j
                move.w  #$A,4(a5)
                move.l  #$FFFEF000,$1C(a5)
; Applies the signalled vertical recovery motion
Stage12_YachtRecoveryState:                             ; was: loc_2F6CA
                addi.l  #$210,$1C(a5)
                bmi.s   Stage12_YachtUpdateRecovery
                cmpi.w  #$12C,$14(a5)
                bpl.s   Stage12_YachtBeginVerticalBob
Stage12_YachtUpdateRecovery:
                bsr.w   Stage12_YachtAccelerateScroll
                bsr.w   Stage12_YachtUpdateScrollPreset
                bra.w   Stage12_YachtUpdatePlaneOffsets
; ---------------------------------------------------------------------------
Stage12_YachtAdvancePastSignal:
                addq.w  #4,4(a5)
; Post-signal state retaining yacht motion and plane-offset updates
Stage12_YachtPostSignalState:                           ; was: loc_2F6EC
                bclr    #1,$5A(a5)
                bne.s   Stage12_YachtBeginRecovery
                bsr.w   Stage12_YachtAccelerateScroll
                bsr.w   Stage12_YachtUpdateScrollPreset
                bra.w   Stage12_YachtUpdatePlaneOffsets
; ---------------------------------------------------------------------------
Stage12_YachtBeginDestruction:
                move.w  #$E,4(a5)
; Destruction state: palette cycling, debris, motion and plane offsets
Stage12_YachtDestructionState:                          ; was: loc_2F706
                lea     Stage12_YachtDestructionPaletteCycle(pc),a4
                nop
                jsr     (Gfx_UpdateRandomizedPaletteEntryList).l
                bsr.w   Stage12_YachtClampHorizontalVelocity
                bsr.w   Stage12_YachtSpawnDestructionDebris
                bsr.w   Stage12_YachtUpdateVerticalBob
                bsr.w   Stage12_YachtAccelerateScroll
                bra.w   Stage12_YachtUpdatePlaneOffsets
; End of function Stage12_YachtBeginMotion
; ---------------------------------------------------------------------------
Stage12_YachtDestructionPaletteCycle:   dc.w    $A, $E322, $E324, $E326, $E328, $E32A, $E32C, $E32E, $E332, $E334, $E336, $E338

; Oscillates the yacht vertically between its two waterline limits
Stage12_YachtUpdateVerticalBob:                         ; was: sub_2F73E
                                        ; Stage12_YachtBeginMotion+A8   p
                tst.w   $58(a5)
                bne.s   Stage12_YachtDescendingPhase
                cmpi.w  #$12E,$14(a5)
                bmi.s   Stage12_YachtReverseVerticalDirection
                move.l  $1C(a5),d0
                bpl.s   Stage12_YachtAccelerateUp
                cmpi.l  #$FFFF0000,d0
                bmi.s   Stage12_YachtVerticalMotionReturn
Stage12_YachtAccelerateUp:
                subi.l  #$2000,d0
                move.l  d0,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Stage12_YachtDescendingPhase:
                cmpi.w  #$13C,$14(a5)
                bpl.s   Stage12_YachtReverseVerticalDirection
                move.l  $1C(a5),d0
                bmi.s   Stage12_YachtAccelerateDown
                cmpi.l  #$10000,d0
                bpl.s   Stage12_YachtVerticalMotionReturn
Stage12_YachtAccelerateDown:
                addi.l  #$2000,d0
                move.l  d0,$1C(a5)
                rts
; ---------------------------------------------------------------------------
Stage12_YachtReverseVerticalDirection:
                                        ; Stage12_YachtUpdateVerticalBob+2E   j
                eori.w  #2,$58(a5)
Stage12_YachtVerticalMotionReturn:
                                        ; Stage12_YachtUpdateVerticalBob+3C   j
                rts
; End of function Stage12_YachtUpdateVerticalBob
; Accelerates the stage scroll and derives camera compensation
Stage12_YachtAccelerateScroll:                          ; was: sub_2F790
                                        ; sub_2F672:Stage12_YachtUpdateRecovery   p
                cmpi.l  #$C000,(StageMotionYDelta).w
                bpl.s   Stage12_YachtApplyScrollCompensation
                addi.l  #$100,(StageMotionYDelta).w
Stage12_YachtApplyScrollCompensation:
                clr.l   (StageMotionXDelta).w
                btst    #5,(PlayerActionStateFlags).w
                bne.s   Stage12_YachtSetScrollCompensation
                btst    #0,(PlayerActionStateFlags).w
                beq.s   Stage12_YachtAccelerateScrollRate
Stage12_YachtSetScrollCompensation:
                move.l  $54(a5),d0
                neg.l   d0
                asr.l   #2,d0
                move.l  d0,(StageMotionXDelta).w
Stage12_YachtAccelerateScrollRate:
                cmpi.l  #$B0000,$54(a5)
                bpl.s   Stage12_YachtScrollAccelerationReturn
                addi.l  #$400,$54(a5)
Stage12_YachtScrollAccelerationReturn:
                rts
; End of function Stage12_YachtAccelerateScroll
; Applies player-directed horizontal yacht steering
Stage12_YachtApplySteering:                             ; was: sub_2F7D6
                tst.w   (PlayerDefeatPhase).w
                bne.w   Stage12_YachtClampHorizontalVelocity
                btst    #0,(PlayerActionStateFlags).w
                bne.s   Stage12_YachtClampHorizontalVelocity
                btst    #2,(ControllerHeldState).w
                beq.s   Stage12_YachtCheckSteerRight
                cmpi.w  #$70,$10(a5)                    ; 'p'
                bmi.s   Stage12_YachtEaseHorizontalVelocity
Stage12_YachtSteerLeft:
                cmpi.l  #$FFFD0000,$18(a5)
                bmi.s   Stage12_YachtSteeringReturn
                subi.l  #$2000,$18(a5)
Stage12_YachtSteeringReturn:
                                        ; Stage12_YachtApplySteering+4C   j
                rts
; ---------------------------------------------------------------------------
Stage12_YachtCheckSteerRight:
                btst    #3,(ControllerHeldState).w
                beq.s   Stage12_YachtClampHorizontalVelocity
                cmpi.w  #$100,$10(a5)
                bpl.s   Stage12_YachtEaseHorizontalVelocity
Stage12_YachtSteerRight:
                cmpi.l  #$30000,$18(a5)
                bpl.s   Stage12_YachtSteeringReturn
                addi.l  #$2000,$18(a5)
                rts
; End of function Stage12_YachtApplySteering
; Eases or reverses yacht velocity at the horizontal limits
Stage12_YachtClampHorizontalVelocity:                   ; was: sub_2F82E
                                        ; Stage12_YachtApplySteering+4   j
                move.w  $10(a5),d0
                subi.w  #$B0,d0
                bmi.s   Stage12_YachtCheckLeftBoundary
                cmpi.w  #$10,d0
                bmi.s   Stage12_YachtEaseHorizontalVelocity
                bra.s   Stage12_YachtSteerLeft
; ---------------------------------------------------------------------------
Stage12_YachtCheckLeftBoundary:
                cmpi.w  #$FFF0,d0
                bpl.s   Stage12_YachtEaseHorizontalVelocity
                bra.s   Stage12_YachtSteerRight
; ---------------------------------------------------------------------------
Stage12_YachtEaseHorizontalVelocity:
                                        ; Stage12_YachtApplySteering+42   j
                move.l  $18(a5),d0
                bpl.s   Stage12_YachtEasePositiveVelocity
                addi.l  #$1800,d0
                bmi.s   Stage12_YachtStoreHorizontalVelocity
                bra.s   Stage12_YachtZeroHorizontalVelocity
; ---------------------------------------------------------------------------
Stage12_YachtEasePositiveVelocity:
                subi.l  #$1800,d0
                bpl.s   Stage12_YachtStoreHorizontalVelocity
Stage12_YachtZeroHorizontalVelocity:
                moveq   #0,d0
Stage12_YachtStoreHorizontalVelocity:
                                        ; Stage12_YachtClampHorizontalVelocity+30   j
                move.l  d0,$18(a5)
                rts
; End of function Stage12_YachtClampHorizontalVelocity
; Alternates between two stage-scroll presets on selected frames
Stage12_YachtUpdateScrollPreset:                        ; was: sub_2F868
                                        ; Stage12_YachtBeginMotion+6E   p
                btst    #0,(FrameCounter+1).w
                beq.s   Stage12_YachtScrollPresetReturn
                btst    #1,(FrameCounter+1).w
                beq.s   Stage12_YachtUseAlternateScrollPreset
                move.l  #$4C705B01,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
Stage12_YachtScrollPresetReturn:
                rts
; ---------------------------------------------------------------------------
Stage12_YachtUseAlternateScrollPreset:
                move.l  #$4C705CA1,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                rts
; End of function Stage12_YachtUpdateScrollPreset
; Projects yacht position into the two scrolling-plane offsets
Stage12_YachtUpdatePlaneOffsets:                        ; was: sub_2F894
                                        ; Stage12_YachtBeginMotion+72   j
                move.w  #$40,d0                         ; '@'
                sub.w   $10(a5),d0
                neg.w   d0
                move.w  d0,(HScrollBuffer).w
                move.w  $14(a5),d0
                addi.w  #-$30,d0
                neg.w   d0
                move.w  (PlaneAShakeOffset).w,d1
                add.w   d1,d0
                move.w  d0,(VScrollBuffer).w
Stage12_YachtControllerReturn:
                rts
; End of function Stage12_YachtUpdatePlaneOffsets
; Spawns debris projectile with random offset
Stage12_YachtSpawnDestructionDebris:                    ; was: sub_2F8B8
                jsr     (Projectile_PrepareImpactSpawnAfterDelay).l
                bne.s   Stage12_YachtDestructionDebrisReturn
                jsr     (Sprite_InitFromTable).l
                move.b  #0,$20(a0)
                move.w  #$FFFD,$1C(a0)
                move.w  (RandomNumberState+2).w,$1E(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$3F,d0                         ; '?'
                andi.w  #$3F,d1                         ; '?'
                subi.w  #$10,d0
                subi.w  #$18,d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #2,d0
                move.l  d0,$18(a0)
Stage12_YachtDestructionDebrisReturn:
                rts
; End of function Stage12_YachtSpawnDestructionDebris
; Main state dispatcher for the Stage 12 teddy bear
Stage12_TeddyBearMain:                                  ; was: sub_2F90E
                move.w  4(a5),d0
                movea.w Stage12_TeddyBearStateTable(pc,d0.w),a0
                adda.l  #Stage12_TeddyBearInit,a0
                jmp     (a0)
; End of function Stage12_TeddyBearMain
; ---------------------------------------------------------------------------
Stage12_TeddyBearStateTable:    dc.w    Stage12_TeddyBearInit-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearReturn-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearWaitForRescue-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearBeginDrop-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearLand-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearFacePlayerDelay-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearWaitBeforeBoarding-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearBoardingDelay-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearBoardingJump-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotAttachDelay-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotStart-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotTrackOamBucket-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotPrepareShot-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotFire-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotRelease-Stage12_TeddyBearInit
                dc.w    Stage12_TeddyBearPilotFall-Stage12_TeddyBearInit

; Initializes the captive teddy bear and its collision state
Stage12_TeddyBearInit:                                  ; was: sub_2F93E
                                        ; ROM:Stage12_TeddyBearStateTable   o
                addq.w  #4,4(a5)
                move.w  #$ED00,2(a5)
                move.w  #$8000,$E(a5)
                move.l  #SharedTeddyHazardLoopAnimation,8(a5)
                clr.w   $C(a5)
                move.b  #$3C,$20(a5)                    ; '<'
                move.w  #$800,$24(a5)
                move.b  #$80,$21(a5)
                move.l  #$F60AF40C,$28(a5)
                move.w  #$120,$14(a5)
; Waits for camera position to reach threshold before activation
Stage12_TeddyBearWaitForRescue:                         ; was: loc_2F97A
                cmpi.w  #$17A0,(PrimaryCameraXPosition).w
                bmi.s   Stage12_TeddyBearRemainCaptive
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
Stage12_TeddyBearScanObjects:
                cmpi.w  #$36C,(a0)
                beq.s   Stage12_TeddyBearRemainCaptive
                lea     $60(a0),a0
                cmpa.w  #$DB20,a0
                bmi.s   Stage12_TeddyBearScanObjects
                bset    #0,(StageTimerPauseFlag).w
                addq.w  #2,4(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.l  #Stage12_TeddyBearRescueAnimation,8(a5)
                clr.w   $C(a5)
                clr.b   $21(a5)
                rts
; ---------------------------------------------------------------------------
Stage12_TeddyBearRemainCaptive:
                                        ; Stage12_TeddyBearInit+4C   j
                tst.w   $24(a5)
                bmi.s   Stage12_TeddyBearDisableCollision
                bra.w   Stage12_TeddyBearFireDownwardShot
; ---------------------------------------------------------------------------
Stage12_TeddyBearDisableCollision:
                clr.b   $21(a5)
                move.w  #2,4(a5)
                move.l  #Stage12_TeddyBearInitialPoseAnimation,8(a5)
                clr.w   $C(a5)
                bclr    #0,(StageTimerPauseFlag).w
                rts
; End of function Stage12_TeddyBearInit
; Shared no-op state and early return for teddy-bear timing states
Stage12_TeddyBearReturn:                                ; was: nullsub_71
                                        ; Stage12_TeddyBearBeginDrop+26   j
                rts
; End of function Stage12_TeddyBearReturn
; Begins the teddy bear's drop to the floor
Stage12_TeddyBearBeginDrop:                             ; was: sub_2F9E2
                subq.w  #1,$48(a5)
                bpl.s   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                move.l  #$FFFD8000,$1C(a5)
                move.l  #Stage12_TeddyBearDropAndPilotAnimation,8(a5)
                clr.w   $C(a5)
; Applies gravity until the teddy bear reaches floor position Y=$120
Stage12_TeddyBearLand:                                  ; was: loc_2FA00
                addi.l  #$3800,$1C(a5)
                bmi.s   Stage12_TeddyBearReturn
                cmpi.w  #$120,$14(a5)
                bmi.s   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
                move.w  #$120,$14(a5)
                clr.l   $1C(a5)
                move.l  #Stage12_TeddyBearLandedAnimation,8(a5)
                clr.w   $C(a5)
                btst    #0,(StageRouteFlags).w
                bne.w   Stage12_TeddyBearBeginBoardingJump
                rts
; End of function Stage12_TeddyBearBeginDrop
; Faces the player during the delay before boarding
Stage12_TeddyBearFacePlayerDelay:                       ; was: sub_2FA3E
                bsr.w   Stage12_TeddyBearFacePlayer
                subq.w  #1,$48(a5)
                bpl.s   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                move.w  #$A0,$48(a5)
                move.l  #Stage12_TeddyBearPreBoardingAnimation,8(a5)
                clr.w   $C(a5)
; Continues facing the player, then selects the boarding animation
Stage12_TeddyBearWaitBeforeBoarding:                    ; was: loc_2FA5E
                bsr.w   Stage12_TeddyBearFacePlayer
                subq.w  #1,$48(a5)
                bpl.w   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                bclr    #3,$E(a5)
                move.w  #$40,$48(a5)                    ; '@'
                move.l  #Stage12_TeddyBearBoardingDelayAnimation,8(a5)
                clr.w   $C(a5)
; Waits before the teddy bear's boarding jump
Stage12_TeddyBearBoardingDelay:                         ; was: loc_2FA86
                subq.w  #1,$48(a5)
                bpl.w   Stage12_TeddyBearReturn
Stage12_TeddyBearBeginBoardingJump:
                move.w  #$10,4(a5)
                move.l  #Stage12_TeddyBearBoardingPilotLoopAnimation,8(a5)
                clr.w   $C(a5)
                move.b  (PlayerOAMBucketOffset).w,$20(a5)
                move.l  #$FFFF5000,$18(a5)
                move.l  #$FFFA0000,$1C(a5)
; Applies the teddy bear's boarding-jump arc
Stage12_TeddyBearBoardingJump:                          ; was: loc_2FAB6
                addi.l  #$4000,$1C(a5)
                bmi.w   Stage12_TeddyBearReturn
                bclr    #7,$E(a5)
                cmpi.l  #$54000,$1C(a5)
                bmi.w   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
                move.w  #$E000,2(a5)
; Attaches the teddy bear to the yacht after the boarding delay
Stage12_TeddyBearPilotAttachDelay:                      ; was: loc_2FAE4
                bsr.w   Stage12_TeddyBearAttachToYacht
                subq.w  #1,$48(a5)
                bpl.w   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                move.w  #$20,$48(a5)                    ; ' '
                move.l  #Stage12_TeddyBearBoardingPilotLoopAnimation,8(a5)
                clr.w   $C(a5)
                move.b  #$18,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Stage12_TeddyBearFacePlayerDelay
; Starts the teddy bear's piloting animation while attached to the yacht
Stage12_TeddyBearPilotStart:                            ; was: sub_2FB10
                bsr.w   Stage12_TeddyBearAttachToYacht
                subq.w  #1,$48(a5)
                bpl.w   Stage12_TeddyBearReturn
                addq.w  #2,4(a5)
                move.l  #Stage12_TeddyBearOverwrittenPilotAnimation,8(a5)
                clr.w   $C(a5)
                addq.w  #2,(StageStateOffset).w
                addq.w  #2,(Entity57State).w
                move.w  #$F,(SpecialTargetCount).w
                bclr    #0,(StageTimerPauseFlag).w
                move.l  #Stage12_TeddyBearDropAndPilotAnimation,8(a5)
                rts
; End of function Stage12_TeddyBearPilotStart
; Tracks the player's OAM draw bucket while attached to the yacht
Stage12_TeddyBearPilotTrackOamBucket:                   ; was: sub_2FB4A
                move.b  (PlayerOAMBucketOffset).w,$20(a5)
                bra.w   Stage12_TeddyBearAttachToYacht
; End of function Stage12_TeddyBearPilotTrackOamBucket
; Selects the attached firing animation
Stage12_TeddyBearPilotPrepareShot:                      ; was: sub_2FB54
                addq.w  #2,4(a5)
                move.l  #Stage12_TeddyBearBoardingPilotLoopAnimation,8(a5)
                clr.w   $C(a5)
; Runs the teddy bear's periodic downward-shot helper
Stage12_TeddyBearPilotFire:                             ; was: loc_2FB64
                bra.w   Stage12_TeddyBearFireDownwardShot
; End of function Stage12_TeddyBearPilotPrepareShot
; Releases the teddy bear from the yacht attachment
Stage12_TeddyBearPilotRelease:                          ; was: sub_2FB68
                addq.w  #2,4(a5)
                move.l  #Stage12_TeddyBearPilotReleasePoseAnimation,8(a5)
                clr.w   $C(a5)
                move.w  #$EE00,2(a5)
; Applies downward acceleration after release
Stage12_TeddyBearPilotFall:                             ; was: loc_2FB7E
                addi.l  #$2000,$1C(a5)
                rts
; End of function Stage12_TeddyBearPilotRelease
; Periodically fires downward projectiles with sound effect
Stage12_TeddyBearFireDownwardShot:                      ; was: sub_2FB88
                                        ; sub_2FB54:loc_2FB64   j
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Stage12_TeddyBearShotReturn
                move.b  #$2C,d0                         ; ','
                jsr     (Sound_QueueSFXRequest).l
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage12_TeddyBearShotReturn
                move.w  #$188,(a0)
                move.w  #$8500,2(a0)
                move.w  #$C168,$E(a0)
                move.w  #$D00,8(a0)
                move.w  #$F0F8,$A(a0)
                move.b  $20(a5),$20(a0)
                subq.b  #4,$20(a0)
                move.w  #$FFFF,$1C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                subi.w  #$10,$14(a0)
                move.w  #$18,$48(a0)
Stage12_TeddyBearShotReturn:
                                        ; Stage12_TeddyBearFireDownwardShot+1A   j
                rts
; End of function Stage12_TeddyBearFireDownwardShot
; Anchors the teddy bear to the yacht controller's position
Stage12_TeddyBearAttachToYacht:                         ; was: sub_2FBEA
                                        ; sub_2FB10   p
                bset    #3,$E(a5)
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  $10(a0),d0
                addi.w  #$44,d0                         ; 'D'
                move.w  d0,$10(a5)
                move.w  $14(a0),d0
                subi.w  #$27,d0                         ; '''
                move.w  d0,$14(a5)
                rts
; End of function Stage12_TeddyBearAttachToYacht
; Updates horizontal sprite flip based on player X position
Stage12_TeddyBearFacePlayer:                            ; was: sub_2FC0E
                                        ; sub_2FA3E:loc_2FA5E   p
                bclr    #3,$E(a5)
                move.w  (PlayerXPosition).w,d0
                sub.w   $10(a5),d0
                bpl.s   Stage12_TeddyBearFacePlayerReturn
                bset    #3,$E(a5)
Stage12_TeddyBearFacePlayerReturn:
                rts
; End of function Stage12_TeddyBearFacePlayer
