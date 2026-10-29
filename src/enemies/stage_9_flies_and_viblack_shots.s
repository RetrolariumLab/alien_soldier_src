Enemy_Stage9FlyController:                              ; was: sub_2D66C
                tst.w   4(a5)
                beq.s   Enemy_Stage9FlyController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ResetCirclingState
                bclr    #7,$22(a5)
                bne.w   Enemy_ResetCirclingState
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ResetCirclingState
                jsr     (RandomNumber).l
                clr.w   6(a5)
Enemy_Stage9FlyController_UpdateState:                  ; was: loc_2D696
                bsr.s   Enemy_DispatchStage9FlyState
                bra.w   Enemy_UpdateCirclingAnimation
; End of function Enemy_Stage9FlyController
; Dispatches one Stage 9 fly's orbit state
Enemy_DispatchStage9FlyState:                           ; was: sub_2D69C
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_Stage9FlyStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchStage9FlyState
; ---------------------------------------------------------------------------
Enemy_Stage9FlyStateOffsets:    dc.w    Enemy_Stage9FlyInit-*  ; was: off_2D6AC
                dc.w    Enemy_Stage9FlyOrbitState-*
                dc.w    Enemy_Stage9FlyNoOpState-*

; Initializes one Stage 9 fly and selects its orbit direction
Enemy_Stage9FlyInit:                                    ; was: sub_2D6B2
                moveq   #0,d0
                bsr.w   Enemy_InitCirclingSprite
                move.w  #4,$5C(a5)
                addq.w  #2,4(a5)
                move.w  #$10,$50(a5)
                move.w  #$180,$4C(a5)
                move.w  #$80,$4E(a5)
                tst.w   $58(a5)
                bne.s   Enemy_Stage9FlyInit_ReverseOrbit
                move.w  #8,$4A(a5)
                bra.s   Enemy_Stage9FlyOrbitState
; ---------------------------------------------------------------------------
Enemy_Stage9FlyInit_ReverseOrbit:                       ; was: loc_2D6E2
                move.w  #$FFF8,$4A(a5)
; Advances the fly around its current target angle and selects the next orbit phase
Enemy_Stage9FlyOrbitState:                              ; was: loc_2D6E8
                move.w  $4A(a5),d0
                add.w   d0,$4C(a5)
                andi.w  #$1FF,$4C(a5)
                bsr.w   Enemy_UpdateCirclingRotationSprite
                move.w  $50(a5),d2
                move.w  $50(a5),d3
                bsr.w   Enemy_UpdateCircularMotionAndFire
                move.w  $4E(a5),d0
                cmp.w   $4C(a5),d0
                bne.s   Enemy_Stage9FlyOrbitState_Return
                move.w  $48(a5),d0
                tst.w   $58(a5)
                bne.s   Enemy_Stage9FlyOrbitState_LoadReverseParameters
                move.w  Enemy_Stage9FlyForwardAngularSteps(pc,d0.w),$4A(a5)
                move.w  Enemy_Stage9FlyForwardTargetAngles(pc,d0.w),$4E(a5)
                move.w  Enemy_Stage9FlyForwardSpeedScales(pc,d0.w),$50(a5)
                bra.s   Enemy_Stage9FlyOrbitState_AdvancePhase
; ---------------------------------------------------------------------------
Enemy_Stage9FlyOrbitState_LoadReverseParameters:        ; was: loc_2D72E
                move.w  Enemy_Stage9FlyReverseAngularSteps(pc,d0.w),$4A(a5)
                move.w  Enemy_Stage9FlyReverseTargetAngles(pc,d0.w),$4E(a5)
                move.w  Enemy_Stage9FlyReverseSpeedScales(pc,d0.w),$50(a5)
Enemy_Stage9FlyOrbitState_AdvancePhase:                 ; was: loc_2D740
                addq.w  #2,$48(a5)
                cmpi.w  #8,$48(a5)
                bne.s   Enemy_Stage9FlyOrbitState_Return
                move.w  #$CF00,2(a5)
                addq.w  #2,4(a5)
Enemy_Stage9FlyOrbitState_Return:                       ; was: locret_2D756
                                        ; Enemy_Stage9FlyInit+98   j
                rts
; End of function Enemy_Stage9FlyInit
; ---------------------------------------------------------------------------
Enemy_Stage9FlyForwardAngularSteps: dc.w    2, 4, 2     ; was: word_2D758
Enemy_Stage9FlyForwardTargetAngles: dc.w    $100, $100, $160  ; was: word_2D75E
Enemy_Stage9FlyForwardSpeedScales:  dc.w    $10, 8, $10  ; was: word_2D764
Enemy_Stage9FlyReverseAngularSteps: dc.w    $FFFE, $FFFC, $FFFE  ; was: word_2D76A
Enemy_Stage9FlyReverseTargetAngles: dc.w    0, 0, $1A0  ; was: word_2D770
Enemy_Stage9FlyReverseSpeedScales:  dc.w    $10, 8, $10  ; was: word_2D776

Enemy_Stage9FlyNoOpState:                               ; was: nullsub_64
                rts
; End of function Enemy_Stage9FlyNoOpState

; Updates a Viblack side shot until it leaves combat or begins its final burst
Projectile_ViblackSideShotController:                   ; was: sub_2D77E
                tst.w   4(a5)
                beq.s   Projectile_ViblackSideShotController_UpdateState
                tst.w   $24(a5)
                bmi.w   Projectile_ViblackSideShotBeginBurst
                bclr    #7,$22(a5)
                bne.w   Projectile_ViblackSideShotBeginBurst
                tst.w   (StageSpawnCountdown).w
                bpl.w   Projectile_ViblackSideShotBeginBurst
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Dispatches the side-shot state and applies its current animation mapping
Projectile_ViblackSideShotController_UpdateState:       ; was: loc_2D7A8
                bsr.s   Projectile_DispatchViblackSideShotState
                bra.w   Enemy_UpdateCirclingAnimation
; End of function Projectile_ViblackSideShotController
; Dispatches the Viblack side shot's current state
Projectile_DispatchViblackSideShotState:                ; was: sub_2D7AE
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Projectile_ViblackSideShotStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_DispatchViblackSideShotState
; ---------------------------------------------------------------------------
Projectile_ViblackSideShotStateOffsets: dc.w    Projectile_ViblackSideShotInitState-*  ; was: off_2D7BE
                dc.w    Projectile_ViblackSideShotApproachState-*
                dc.w    Projectile_ViblackSideShotBeginTurnState-*
                dc.w    Projectile_ViblackSideShotTurnAndLaunchState-*
                dc.w    Projectile_ViblackSideShotTrackAltitudeState-*

; Initializes the side shot's sprite, downward entry motion, and turn direction
Projectile_ViblackSideShotInitState:                    ; was: sub_2D7C8
                moveq   #0,d0
                bsr.w   Enemy_InitCirclingSprite
                move.b  #2,$25(a5)
                move.w  #$80,$4C(a5)
                addq.w  #2,4(a5)
                bsr.w   Enemy_UpdateCirclingRotationSprite
                move.w  #2,$1C(a5)
                move.w  (PlayerCenterX).w,d0
                sub.w   $10(a5),d0
                bmi.s   Projectile_ViblackSideShotInitState_SetPositiveTurn
                move.w  #$FFF8,$4E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackSideShotInitState_SetPositiveTurn:    ; was: loc_2D7FA
                move.w  #8,$4E(a5)
                rts
; End of function Projectile_ViblackSideShotInitState
; Waits until the side shot sits at least $20 below the player centre
Projectile_ViblackSideShotApproachState:                ; was: sub_2D802
                move.w  $14(a5),d0
                sub.w   (PlayerCenterY).w,d0
                tst.w   d0
                bmi.s   Projectile_ViblackSideShotState_Return
                cmpi.w  #$20,d0                         ; ' '
                bcs.s   Projectile_ViblackSideShotState_Return
                clr.w   $50(a5)
                addq.w  #2,4(a5)
                rts
; End of function Projectile_ViblackSideShotApproachState
; Unreachable: would wait for the linked shot in $4A to settle before advancing
Orphaned_ViblackSideShotWaitForLinkedObject:
                movea.w $4A(a5),a1                      ; was: sub_2D81E
                tst.w   4(a1)
                beq.s   Projectile_ViblackSideShotState_Return
                tst.w   $1C(a1)
                bne.s   Projectile_ViblackSideShotState_Return
                addq.w  #2,4(a5)
Projectile_ViblackSideShotState_Return:                 ; was: locret_2D832
                                        ; Projectile_ViblackSideShotApproachState+10   j
                rts
; End of function Orphaned_ViblackSideShotWaitForLinkedObject
; Stops the entry motion and starts the turn timer
Projectile_ViblackSideShotBeginTurnState:               ; was: sub_2D834
                clr.w   $1C(a5)
                addq.w  #2,4(a5)
                move.w  #$10,$48(a5)
                rts
; End of function Projectile_ViblackSideShotBeginTurnState
; Rotates the shot for sixteen frames, then launches it horizontally
Projectile_ViblackSideShotTurnAndLaunchState:           ; was: sub_2D844
                move.w  $4E(a5),d0
                add.w   d0,$4C(a5)
                bsr.w   Enemy_UpdateCirclingRotationSprite
                subq.w  #1,$48(a5)
                bne.s   Projectile_ViblackSideShotTurnAndLaunchState_Return
                move.w  #$1C0,$48(a5)
                addq.w  #2,4(a5)
                move.w  #3,$18(a5)
                btst    #7,$4E(a5)
                bne.s   Projectile_ViblackSideShotTurnAndLaunchState_Return
                neg.w   $18(a5)
Projectile_ViblackSideShotTurnAndLaunchState_Return:    ; was: locret_2D872
                                        ; Projectile_ViblackSideShotTurnAndLaunchState+28   j
                rts
; End of function Projectile_ViblackSideShotTurnAndLaunchState
; Tracks the player altitude until the shot lifetime expires, then hides the shot
Projectile_ViblackSideShotTrackAltitudeState:           ; was: sub_2D874
                bsr.w   Projectile_ViblackSideShotSteerTowardPlayer
                subq.w  #1,$48(a5)
                bne.s   Projectile_ViblackSideShotTrackAltitudeState_Return
                bset    #4,2(a5)
Projectile_ViblackSideShotTrackAltitudeState_Return:    ; was: locret_2D884
                rts
; End of function Projectile_ViblackSideShotTrackAltitudeState
; Accelerates vertically toward the player centre, capped at two pixels a frame
Projectile_ViblackSideShotSteerTowardPlayer:            ; was: sub_2D886
                move.w  (PlayerCenterY).w,d0
                sub.w   $14(a5),d0
                beq.s   Projectile_ViblackSideShotSteerTowardPlayer_Return
                tst.w   d0
                bpl.s   Projectile_ViblackSideShotSteerTowardPlayer_AccelerateDown
                subi.l  #$2000,$1C(a5)
                cmpi.l  #$FFFE0000,$1C(a5)
                bgt.s   Projectile_ViblackSideShotSteerTowardPlayer_Return
                move.l  #$FFFE0000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
; Accelerates downward, capped at the positive vertical speed limit
Projectile_ViblackSideShotSteerTowardPlayer_AccelerateDown:  ; was: loc_2D8B0
                addi.l  #$2000,$1C(a5)
                cmpi.l  #$20000,$1C(a5)
                blt.s   Projectile_ViblackSideShotSteerTowardPlayer_Return
                move.l  #$20000,$1C(a5)
Projectile_ViblackSideShotSteerTowardPlayer_Return:     ; was: locret_2D8CA
                                        ; Projectile_ViblackSideShotSteerTowardPlayer+1E   j
                rts
; End of function Projectile_ViblackSideShotSteerTowardPlayer
; Clears the side shot's combat state and replaces it with the base projectile burst
Projectile_ViblackSideShotBeginBurst:                   ; was: sub_2D8CC
                                        ; Projectile_ViblackSideShotController+14   j
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                jmp     Enemy_SpawnQuadProjectiles
; End of function Projectile_ViblackSideShotBeginBurst
; Unreachable: a bare return with no reference of any kind
Orphaned_ViblackSideShotNoOp:                           ; was: nullsub_65
                rts
; End of function Orphaned_ViblackSideShotNoOp

; Controls allocation and activation of the two Stage 9 fly waves
Stage9_FlyFormationController:                          ; was: sub_2D8E8
                move.w  4(a5),d0
                lea     Stage9_FlyFormationStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage9_FlyFormationController
; ---------------------------------------------------------------------------
Stage9_FlyFormationStateOffsets:    dc.w    Stage9_FlyFormationInitState-*  ; was: off_2D8F4
                dc.w    Stage9_FlyFormationDelayState-*
                dc.w    Stage9_FlyFormationAllocateSlotsState-*
                dc.w    Stage9_FlyFormationActivateWaveState-*

; Positions the formation controller and starts its initial delay
Stage9_FlyFormationInitState:                           ; was: sub_2D8FC
                move.w  #$120,$10(a5)
                move.w  #$90,$14(a5)
                move.w  #$D00,2(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Stage9_FlyFormationInitState
; Waits before allocating the fly object slots
Stage9_FlyFormationDelayState:                          ; was: sub_2D91A
                subq.w  #1,$48(a5)
                bne.s   Stage9_FlyFormationDelayState_Return
                clr.w   $4A(a5)
                addq.w  #2,4(a5)
Stage9_FlyFormationDelayState_Return:                   ; was: locret_2D928
                rts
; End of function Stage9_FlyFormationDelayState
; Allocates eight dormant object slots for the next fly wave
Stage9_FlyFormationAllocateSlotsState:                  ; was: sub_2D92A
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Stage9_FlyFormationAllocateSlotsState_Return
                move.w  #$10,(a0)
                lea     $4C(a5),a1
                move.w  $48(a5),d0
                move.w  a0,(a1,d0.w)
                addq.w  #2,$48(a5)
                cmpi.w  #$10,$48(a5)
                bne.s   Stage9_FlyFormationAllocateSlotsState_Return
                addq.w  #2,4(a5)
Stage9_FlyFormationAllocateSlotsState_Return:           ; was: locret_2D952
                                        ; Stage9_FlyFormationAllocateSlotsState+22   j
                rts
; End of function Stage9_FlyFormationAllocateSlotsState
; Activates one staged fly at a time, then repeats from the alternate side
Stage9_FlyFormationActivateWaveState:                   ; was: sub_2D954
                move.w  (FrameCounter).w,d7
                andi.w  #$F,d7
                bne.s   Stage9_FlyFormationActivateWaveState_Return
                subq.w  #2,$48(a5)
                bmi.s   Stage9_FlyFormationActivateWaveState_CompleteWave
                lea     $4C(a5),a1
                move.w  $48(a5),d0
                movea.w (a1,d0.w),a0
                move.w  #$2A8,(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  $4A(a5),$58(a0)
                tst.w   $4A(a5)
                bne.s   Stage9_FlyFormationActivateWaveState_OffsetAlternateWave
                addi.w  #$100,$10(a0)
                rts
; ---------------------------------------------------------------------------
Stage9_FlyFormationActivateWaveState_OffsetAlternateWave:  ; was: loc_2D994
                subi.w  #$80,$10(a0)
Stage9_FlyFormationActivateWaveState_Return:            ; was: locret_2D99A
                rts
; ---------------------------------------------------------------------------
Stage9_FlyFormationActivateWaveState_CompleteWave:      ; was: loc_2D99C
                tst.w   $4A(a5)
                bne.s   Stage9_FlyFormationActivateWaveState_Finish
                addq.w  #1,$4A(a5)
                move.w  #4,4(a5)
                clr.w   $48(a5)
                rts
; ---------------------------------------------------------------------------
Stage9_FlyFormationActivateWaveState_Finish:            ; was: loc_2D9B2
                bset    #4,2(a5)
                rts
; End of function Stage9_FlyFormationActivateWaveState
; Initializes a Viblack side shot at the caller-selected horizontal position
Projectile_InitViblackSideShot:                         ; was: sub_2D9BA
                move.w  #$2F4,(a0)
                move.w  #$D80,2(a0)
                move.w  #$80,$14(a0)
                move.w  d0,$10(a0)
                rts
; End of function Projectile_InitViblackSideShot
; Dispatches a controller that creates four linked Viblack side shots in sequence
Projectile_ViblackSideShotSequenceController:           ; was: sub_2D9D0
                move.w  4(a5),d0
                lea     Projectile_ViblackSideShotSequenceStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_ViblackSideShotSequenceController
; ---------------------------------------------------------------------------
Projectile_ViblackSideShotSequenceStateOffsets: dc.w    Projectile_ViblackSideShotSequenceSpawnState-*  ; was: off_2D9DC
                dc.w    Projectile_ViblackSideShotSequenceWaitState-*

; Creates the next linked Viblack side shot and starts the inter-shot delay
Projectile_ViblackSideShotSequenceSpawnState:           ; was: sub_2D9E0
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_ViblackSideShotSequenceSpawnState_Return
                move.w  #$2F4,(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  $4A(a5),$4A(a0)
                move.w  $5E(a5),$5E(a0)
                move.w  #$10,$50(a0)
                move.w  a0,$4A(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Projectile_ViblackSideShotSequenceSpawnState_Return:    ; was: locret_2DA18
                rts
; End of function Projectile_ViblackSideShotSequenceSpawnState
; Waits between side shots and ends the sequence after four children
Projectile_ViblackSideShotSequenceWaitState:            ; was: sub_2DA1A
                subq.w  #1,$48(a5)
                bne.s   Projectile_ViblackSideShotSequenceWaitState_Return
                addq.w  #1,$5E(a5)
                cmpi.w  #4,$5E(a5)
                beq.s   Projectile_ViblackSideShotSequenceWaitState_Finish
                subq.w  #2,4(a5)
Projectile_ViblackSideShotSequenceWaitState_Return:     ; was: locret_2DA30
                rts
; ---------------------------------------------------------------------------
Projectile_ViblackSideShotSequenceWaitState_Finish:     ; was: loc_2DA32
                bset    #4,2(a5)
                rts
; End of function Projectile_ViblackSideShotSequenceWaitState
