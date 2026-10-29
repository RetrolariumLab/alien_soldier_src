Boss_Epsilon1StartOpeningFadeDelayState:                ; was: sub_461A6
                bsr.w   Boss_Epsilon1ApplyPaletteFade
                move.w  #$20,$48(a5)                    ; ' '
                move.b  #$21,(PlaneAScrollModeFlags).w  ; '!'
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1StartOpeningFadeDelayState
; Finishes the opening delay and seeds angle-history motion
Boss_Epsilon1OpeningFadeDelayState:                     ; was: sub_461BC
                bsr.w   Boss_Epsilon1ApplyPaletteFade
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1OpeningFadeDelayReturn
                move.w  #4,(SharedScratchLong4).w
                move.w  #4,(SharedScratchLong5+2).w
                move.w  #$E,$48(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1OpeningFadeDelayReturn:                    ; was: locret_461DC
                rts
; End of function Boss_Epsilon1OpeningFadeDelayState
; Unreferenced input helper for manually adjusting the shared battle center
Debug_Epsilon1AdjustBattleCenter:
                btst    #5,(ControllerHeldState).w      ; was: sub_461DE
                beq.s   Debug_Epsilon1AdjustBattleCenterReturn
                btst    #2,(ControllerHeldState).w
                beq.s   Debug_Epsilon1CheckMoveRight
                subq.w  #2,(SecondaryEntityXPos).w
Debug_Epsilon1CheckMoveRight:                           ; was: loc_461F2
                btst    #3,(ControllerHeldState).w
                beq.s   Debug_Epsilon1CheckMoveUp
                addq.w  #2,(SecondaryEntityXPos).w
Debug_Epsilon1CheckMoveUp:                              ; was: loc_461FE
                btst    #0,(ControllerHeldState).w
                beq.s   Debug_Epsilon1CheckMoveDown
                subq.w  #2,(SecondaryEntityYPos).w
Debug_Epsilon1CheckMoveDown:                            ; was: loc_4620A
                btst    #1,(ControllerHeldState).w
                beq.s   Debug_Epsilon1AdjustBattleCenterReturn
                addq.w  #2,(SecondaryEntityYPos).w
Debug_Epsilon1AdjustBattleCenterReturn:                 ; was: locret_46216
                                        ; Debug_Epsilon1AdjustBattleCenter+32   j
                rts
; End of function Debug_Epsilon1AdjustBattleCenter
; Advances the opening palette fade after shared readiness bits clear
Boss_Epsilon1FinishOpeningFadeState:                    ; was: sub_46218
                move.w  $48(a5),d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                jsr     (Gfx_ApplyPaletteFade).l
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_Epsilon1FinishOpeningFadeReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_Epsilon1FinishOpeningFadeReturn
                subq.w  #1,$48(a5)
                bge.s   Boss_Epsilon1FinishOpeningFadeReturn
                addq.w  #2,4(a5)
Boss_Epsilon1FinishOpeningFadeReturn:                   ; was: locret_46248
                                        ; Boss_Epsilon1FinishOpeningFadeState+24   j
                rts
; End of function Boss_Epsilon1FinishOpeningFadeState
; Requests the shared boss message for Epsilon 1 and advances
Boss_Epsilon1RequestBattleMessageState:                 ; was: sub_4624A
                move.w  #3,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
                move.b  #$8D,d0
                jsr     (Sound_QueueBGMRequest).l
                rts
; End of function Boss_Epsilon1RequestBattleMessageState
; Waits for the shared boss message to finish before enabling attack selection
Boss_Epsilon1WaitForBattleMessageState:                 ; was: sub_46264
                tst.w   (MessageSequenceState).w
                bne.s   Boss_Epsilon1WaitForBattleMessageReturn
                addq.w  #2,4(a5)
                clr.b   (BossColorEffectFlags).w
                move.w  #$40,$48(a5)                    ; '@'
Boss_Epsilon1WaitForBattleMessageReturn:                ; was: locret_46278
                rts
; End of function Boss_Epsilon1WaitForBattleMessageState
; Selects one of three attack branches when the ring controller is idle
Boss_Epsilon1SelectAttackState:                         ; was: sub_4627A
                clr.l   (SecondaryEntityXVel).w
                tst.w   (FifthEntityState).w
                bne.s   Boss_Epsilon1SelectAttackReturn
                tst.w   (Epsilon1ProximityFlag).w
                bne.s   Boss_Epsilon1SelectVerticalSweepAttack
                move.w  (RandomNumberState).w,d0
                andi.w  #1,d0
                beq.s   Boss_Epsilon1SelectRingCycleAttack
                move.w  #$14,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1SelectRingCycleAttack:                     ; was: loc_4629C
                move.w  #$26,4(a5)                      ; '&'
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1SelectVerticalSweepAttack:                 ; was: loc_462A4
                move.w  #$32,4(a5)                      ; '2'
Boss_Epsilon1SelectAttackReturn:                        ; was: locret_462AA
                rts
; End of function Boss_Epsilon1SelectAttackState
; Begins the spread-ring branch by accelerating the angle history
Boss_Epsilon1BeginSpreadRingAttackState:                ; was: sub_462AC
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  #8,(SharedScratchLong4).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1BeginSpreadRingAttackState
; Waits for the spread-ring angle to wrap below $60
Boss_Epsilon1WaitForSpreadAttackAngleWrapState:         ; was: sub_462BC
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FF,d0
                cmpi.w  #$60,d0                         ; '`'
                bcc.s   Boss_Epsilon1WaitForSpreadAttackAngleWrapReturn
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForSpreadAttackAngleWrapReturn:        ; was: locret_462D2
                rts
; End of function Boss_Epsilon1WaitForSpreadAttackAngleWrapState
; Stops at angle $80 and begins collapsing the spread ring
Boss_Epsilon1PrepareSpreadRingCollapseState:            ; was: sub_462D4
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FF,d0
                cmpi.w  #$80,d0
                bcs.s   Boss_Epsilon1PrepareSpreadRingCollapseReturn
                clr.w   (SharedScratchLong4).w
                move.w  #4,(SharedScratchLong5+2).w
                move.w  #1,(SecondaryEntityYVel).w
                addq.w  #2,4(a5)
Boss_Epsilon1PrepareSpreadRingCollapseReturn:           ; was: locret_462FA
                rts
; End of function Boss_Epsilon1PrepareSpreadRingCollapseState
; Collapses the spread ring until every delayed angle matches
Boss_Epsilon1CollapseSpreadRingState:                   ; was: sub_462FC
                addi.l  #-$400,(SecondaryEntityYVel).w
                bsr.w   Boss_Epsilon1CheckAngleHistoryAligned
                bne.s   Boss_Epsilon1CollapseSpreadRingReturn
                clr.l   (SecondaryEntityYVel).w
                move.w  #4,(SharedScratchLong5+2).w
                move.w  #4,(SharedScratchLong4).w
                addq.w  #2,4(a5)
Boss_Epsilon1CollapseSpreadRingReturn:                  ; was: locret_4631E
                rts
; End of function Boss_Epsilon1CollapseSpreadRingState
; Activates the ring controller for the spread branch
Boss_Epsilon1ActivateSpreadRingState:                   ; was: sub_46320
                tst.w   (FifthEntityState).w
                bne.s   Boss_Epsilon1ActivateSpreadRingReturn
                move.w  #0,(FifthEntityWork5E).w
                nop
                addq.w  #2,(FifthEntityState).w
                addq.w  #2,4(a5)
Boss_Epsilon1ActivateSpreadRingReturn:                  ; was: locret_46336
                rts
; End of function Boss_Epsilon1ActivateSpreadRingState
; Waits for ring-controller state $0A, then releases that controller
Boss_Epsilon1WaitForSpreadRingReadyState:               ; was: sub_46338
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                cmpi.w  #$A,(FifthEntityState).w
                bne.s   Boss_Epsilon1WaitForSpreadRingReadyReturn
                addq.w  #2,(FifthEntityState).w
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForSpreadRingReadyReturn:              ; was: locret_4634C
                rts
; End of function Boss_Epsilon1WaitForSpreadRingReadyState
; Reserves the first projectile slot used by the spread pair
Boss_Epsilon1ReserveFirstSpreadSlotState:               ; was: sub_4634E
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1ReserveFirstSpreadSlotReturn
                move.w  #$10,(a0)
                move.w  a0,(SharedScratchLong7).w
                addq.w  #2,4(a5)
Boss_Epsilon1ReserveFirstSpreadSlotReturn:              ; was: locret_46366
                rts
; End of function Boss_Epsilon1ReserveFirstSpreadSlotState
; Reserves the second projectile slot used by the spread pair
Boss_Epsilon1ReserveSecondSpreadSlotState:              ; was: sub_46368
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1ReserveSecondSpreadSlotReturn
                move.w  #$10,(a0)
                move.w  a0,(SharedScratchLong7+2).w
                addq.w  #2,4(a5)
Boss_Epsilon1ReserveSecondSpreadSlotReturn:             ; was: locret_46380
                rts
; End of function Boss_Epsilon1ReserveSecondSpreadSlotState
; Aims and launches the reserved spread-projectile pair
Boss_Epsilon1LaunchSpreadPairState:                     ; was: sub_46382
                movea.w (SharedScratchLong8).w,a0
                move.w  $10(a0),d0
                move.w  $14(a0),d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                move.w  $10(a5),d0
                addq.w  #8,d0
                move.w  $14(a5),d1
                movea.w (SharedScratchLong7).w,a0
                bsr.s   Projectile_PrepareEpsilon1ElevenStepSpread
                move.w  $10(a5),d0
                subq.w  #8,d0
                move.w  $14(a5),d1
                movea.w (SharedScratchLong7+2).w,a0
                bsr.s   Projectile_PrepareEpsilon1ElevenStepSpread
                tst.w   (FifthEntityState).w
                beq.s   Boss_Epsilon1FinishSpreadPair
                move.w  #$1E,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1FinishSpreadPair:                          ; was: loc_463CA
                move.w  #$12,4(a5)
                rts
; End of function Boss_Epsilon1LaunchSpreadPairState
; Selects the five-step spread callback before common projectile setup
Projectile_PrepareEpsilon1FiveStepSpread:               ; was: sub_463D2
                                        ; Boss_Epsilon1DescendAndReleaseRingState+46   p
                move.l  #Projectile_Epsilon1InitializeFivePartSpread,$48(a0)
                bra.s   Projectile_InitializeEpsilon1SpreadSlot
; End of function Projectile_PrepareEpsilon1FiveStepSpread
; Selects the eleven-step spread callback before common projectile setup
Projectile_PrepareEpsilon1ElevenStepSpread:             ; was: sub_463DC
                                        ; Boss_Epsilon1LaunchSpreadPairState+38   p
                move.l  #Projectile_Epsilon1InitializeElevenPartSpread,$48(a0)
Projectile_InitializeEpsilon1SpreadSlot:                ; was: loc_463E4
                move.l  (SecondaryEntityYVel).w,$1C(a0)
                move.w  d2,$58(a0)
                move.w  #$268,(a0)
                move.l  #Weapon_SharedShotInitialSpriteFrame,$54(a0)
                move.w  #$8C80,2(a0)
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                rts
; End of function Projectile_PrepareEpsilon1ElevenStepSpread
; Begins the ring-only attack branch by accelerating the angle history
Boss_Epsilon1BeginRingCycleAttackState:                 ; was: sub_4640A
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  #8,(SharedScratchLong4).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1BeginRingCycleAttackState
; Waits for the ring-cycle angle to wrap below $60
Boss_Epsilon1WaitForRingCycleAngleWrapState:            ; was: sub_4641A
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FF,d0
                cmpi.w  #$60,d0                         ; '`'
                bcc.s   Boss_Epsilon1WaitForRingCycleAngleWrapReturn
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForRingCycleAngleWrapReturn:           ; was: locret_46430
                rts
; End of function Boss_Epsilon1WaitForRingCycleAngleWrapState
; Stops at angle $80 and begins collapsing the ring-only branch
Boss_Epsilon1PrepareRingCycleCollapseState:             ; was: sub_46432
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FF,d0
                cmpi.w  #$80,d0
                bcs.s   Boss_Epsilon1PrepareRingCycleCollapseReturn
                clr.w   (SharedScratchLong4).w
                move.w  #4,(SharedScratchLong5+2).w
                move.w  #1,(SecondaryEntityYVel).w
                addq.w  #2,4(a5)
Boss_Epsilon1PrepareRingCycleCollapseReturn:            ; was: locret_46458
                rts
; End of function Boss_Epsilon1PrepareRingCycleCollapseState
; Collapses the ring-only branch until every delayed angle matches
Boss_Epsilon1CollapseRingCycleState:                    ; was: sub_4645A
                addi.l  #-$400,(SecondaryEntityYVel).w
                bsr.w   Boss_Epsilon1CheckAngleHistoryAligned
                bne.s   Boss_Epsilon1CollapseRingCycleReturn
                clr.l   (SecondaryEntityYVel).w
                move.w  #1,(SharedScratchLong5+2).w
                move.w  #8,(SharedScratchLong4).w
                addq.w  #2,4(a5)
Boss_Epsilon1CollapseRingCycleReturn:                   ; was: locret_4647C
                rts
; End of function Boss_Epsilon1CollapseRingCycleState
; Activates the ring controller with its alternate command flag
Boss_Epsilon1ActivateRingCycleState:                    ; was: sub_4647E
                tst.w   (FifthEntityState).w
                bne.s   Boss_Epsilon1ActivateRingCycleReturn
                move.w  #1,(FifthEntityWork5E).w
                nop
                addq.w  #2,(FifthEntityState).w
                addq.w  #2,4(a5)
Boss_Epsilon1ActivateRingCycleReturn:                   ; was: locret_46494
                rts
; End of function Boss_Epsilon1ActivateRingCycleState
; Waits for the ring controller to complete, then returns to attack selection
Boss_Epsilon1WaitForRingCycleCompleteState:             ; was: sub_46496
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                cmpi.w  #$C,(FifthEntityState).w
                bne.s   Boss_Epsilon1WaitForRingCycleCompleteReturn
                addq.w  #2,(FifthEntityState).w
                move.w  #$12,4(a5)
Boss_Epsilon1WaitForRingCycleCompleteReturn:            ; was: locret_464AC
                rts
; End of function Boss_Epsilon1WaitForRingCycleCompleteState
; Begins the vertical-sweep branch by accelerating the angle history
Boss_Epsilon1BeginVerticalSweepAttackState:             ; was: sub_464AE
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  #8,(SharedScratchLong4).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1BeginVerticalSweepAttackState
; Waits for the vertical-sweep angle to wrap below $60
Boss_Epsilon1WaitForVerticalSweepAngleWrapState:        ; was: sub_464BE
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FF,d0
                cmpi.w  #$60,d0                         ; '`'
                bcc.s   Boss_Epsilon1WaitForVerticalSweepAngleWrapReturn
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForVerticalSweepAngleWrapReturn:       ; was: locret_464D4
                rts
; End of function Boss_Epsilon1WaitForVerticalSweepAngleWrapState
; Stops at angle $80 and begins collapsing the vertical-sweep branch
Boss_Epsilon1PrepareVerticalSweepCollapseState:         ; was: sub_464D6
                bsr.w   Boss_Epsilon1UpdateBattleCenterMotion
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FF,d0
                cmpi.w  #$80,d0
                bcs.s   Boss_Epsilon1PrepareVerticalSweepCollapseReturn
                clr.w   (SharedScratchLong4).w
                move.w  #4,(SharedScratchLong5+2).w
                move.w  #1,(SecondaryEntityYVel).w
                addq.w  #2,4(a5)
Boss_Epsilon1PrepareVerticalSweepCollapseReturn:        ; was: locret_464FC
                rts
; End of function Boss_Epsilon1PrepareVerticalSweepCollapseState
; Collapses the vertical-sweep ring until every delayed angle matches
Boss_Epsilon1CollapseVerticalSweepRingState:            ; was: sub_464FE
                addi.l  #-$400,(SecondaryEntityYVel).w
                bsr.w   Boss_Epsilon1CheckAngleHistoryAligned
                bne.s   Boss_Epsilon1CollapseVerticalSweepRingReturn
                clr.l   (SecondaryEntityYVel).w
                move.w  #1,(SharedScratchLong5+2).w
                move.w  #$10,(SharedScratchLong4).w
                move.w  #0,$58(a5)
                bset    #4,$23(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1CollapseVerticalSweepRingReturn:           ; was: locret_4652C
                rts
; End of function Boss_Epsilon1CollapseVerticalSweepRingState
; Moves the shared battle center to the upper sweep height
Boss_Epsilon1MoveToUpperSweepHeightState:               ; was: sub_4652E
                bsr.w   Boss_Epsilon1ApplyDirectionalVerticalStep
                cmpi.w  #$40,(SecondaryEntityYPos).w    ; '@'
                bgt.s   Boss_Epsilon1MoveToUpperSweepHeightReturn
                clr.l   (SecondaryEntityYVel).w
                move.l  #$400000,(SecondaryEntityYPos).w
                move.w  #$60,(SharedScratchLong5).w     ; '`'
                move.w  #7,(SharedScratchLong5+2).w
                clr.w   (SharedScratchLong4).w
                clr.w   $48(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1MoveToUpperSweepHeightReturn:              ; was: locret_4655E
                rts
; End of function Boss_Epsilon1MoveToUpperSweepHeightState
; Reserves the two spread slots used after the vertical sweep
Boss_Epsilon1ReserveSweepSpreadSlotsState:              ; was: sub_46560
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1ReserveSweepSpreadSlotsReturn
                move.w  #$10,(a0)
                lea     (SharedScratchLong7).w,a1
                move.w  $48(a5),d0
                add.w   d0,d0
                move.w  a0,(a1,d0.w)
                addq.w  #1,$48(a5)
                cmpi.w  #2,$48(a5)
                bne.s   Boss_Epsilon1ReserveSweepSpreadSlotsReturn
                clr.w   $48(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1ReserveSweepSpreadSlotsReturn:             ; was: locret_4658E
                                        ; Boss_Epsilon1ReserveSweepSpreadSlotsState+24   j
                rts
; End of function Boss_Epsilon1ReserveSweepSpreadSlotsState
; Allocates one companion projectile for each of the twelve ring objects
Boss_Epsilon1AttachRingProjectilesState:                ; was: sub_46590
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1AttachRingProjectilesReturn
                move.w  $48(a5),d0
                add.w   d0,d0
                lea     Boss_Epsilon1RingObjectSlots(pc),a1
                nop
                movea.w (a1,d0.w),a1
                move.w  a0,$4E(a1)
                move.w  #$10,(a0)
                move.w  #$CC0,2(a0)
                move.w  #$4300,$E(a0)
                move.w  #$700,8(a0)
                move.w  #$F8F0,$A(a0)
                move.w  #4,$20(a0)
                addq.w  #1,$48(a5)
                cmpi.w  #$C,$48(a5)
                bne.s   Boss_Epsilon1AttachRingProjectilesReturn
                addq.w  #2,4(a5)
Boss_Epsilon1AttachRingProjectilesReturn:               ; was: locret_465DE
                                        ; Boss_Epsilon1AttachRingProjectilesState+48   j
                rts
; End of function Boss_Epsilon1AttachRingProjectilesState
; Waits until all twelve ring objects have returned to state zero
Boss_Epsilon1WaitForRingObjectsInactiveState:           ; was: sub_465E0
                clr.w   d0
                move.w  #5,d7
                lea     Boss_Epsilon1RingObjectSlots(pc),a2
                nop
Boss_Epsilon1CheckRingObjectPairsLoop:                  ; was: loc_465EC
                movea.w (a2,d0.w),a0
                movea.w $C(a2,d0.w),a1
                tst.w   4(a0)
                bne.w   Boss_Epsilon1WaitForRingObjectsInactiveReturn
                tst.w   4(a1)
                bne.w   Boss_Epsilon1WaitForRingObjectsInactiveReturn
                addq.w  #2,d0
                dbf     d7,Boss_Epsilon1CheckRingObjectPairsLoop
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForRingObjectsInactiveReturn:          ; was: locret_46614
                                        ; Boss_Epsilon1WaitForRingObjectsInactiveState+20   j
                rts
; End of function Boss_Epsilon1WaitForRingObjectsInactiveState
; ---------------------------------------------------------------------------
Boss_Epsilon1RingObjectSlots:   dc.w    $C800, $C860, $C8C0, $C920, $C980, $C9E0, $CA40, $CAA0, $CB00, $CB60, $CBC0, $CC20  ; was: word_46616
                                        ; Boss_Epsilon1WaitForRingObjectsInactiveState+6   o

; Waits for angle-history alignment, then starts the vertical sweep
Boss_Epsilon1StartAlignedVerticalSweepState:            ; was: sub_4662E
                bsr.w   Boss_Epsilon1CheckAngleHistoryAligned
                bne.s   Boss_Epsilon1StartAlignedVerticalSweepReturn
                addq.w  #2,4(a5)
                move.l  #$20000,(SecondaryEntityYVel).w
                move.l  #$4000,(Epsilon1VerticalAccel).w
                move.w  #$120,(SecondaryEntityXPos).w
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Boss_Epsilon1StartAlignedVerticalSweepReturn
                cmpi.w  #1,d0
                beq.s   Boss_Epsilon1StartAlignedVerticalSweepReturn
                cmpi.w  #2,d0
                beq.s   Boss_Epsilon1OffsetSweepStartRight
                addi.w  #-$40,(SecondaryEntityXPos).w
                bra.s   Boss_Epsilon1StartAlignedVerticalSweepReturn
; ---------------------------------------------------------------------------
Boss_Epsilon1OffsetSweepStartRight:                     ; was: loc_4666C
                addi.w  #$40,(SecondaryEntityXPos).w    ; '@'
Boss_Epsilon1StartAlignedVerticalSweepReturn:           ; was: locret_46672
                                        ; Boss_Epsilon1StartAlignedVerticalSweepState+28   j
                rts
; End of function Boss_Epsilon1StartAlignedVerticalSweepState
; Returns zero only when the current angle matches all six delayed samples
Boss_Epsilon1CheckAngleHistoryAligned:                  ; was: sub_46674
                                        ; Boss_Epsilon1CollapseRingCycleState+8   p
                                        ; Boss_Epsilon1CollapseVerticalSweepRingState+8   p
                                        ; Boss_Epsilon1StartAlignedVerticalSweepState   p
                                        ; Boss_Epsilon1PrepareSweepRecoveryState   p
                                        ; Boss_Epsilon1WaitForTransitionAngleAlignmentState   p
                move.w  (SharedScratchLong5).w,d0
                andi.w  #$1FE,d0
                lea     (SharedScratchLong0).w,a0
                move.w  #5,d7
Boss_Epsilon1CompareAngleHistoryLoop:                   ; was: loc_46684
                cmp.w   (a0)+,d0
                bne.s   Boss_Epsilon1ReturnAngleMismatchCount
                dbf     d7,Boss_Epsilon1CompareAngleHistoryLoop
Boss_Epsilon1ReturnAngleMismatchCount:                  ; was: loc_4668C
                addq.w  #1,d7
                move.w  d7,d0
                rts
; End of function Boss_Epsilon1CheckAngleHistoryAligned
; Applies the configured acceleration to shared vertical velocity
Boss_Epsilon1ApplyVerticalAcceleration:                 ; was: sub_46692
                                        ; Boss_Epsilon1RiseAfterRingReleaseState+A   p
                                        ; Boss_Epsilon1WaitForReleasedRingObjectsState   p
                                        ; Boss_Epsilon1RecoverBattleCenterState+6   p
                move.l  (Epsilon1VerticalAccel).w,d0
                add.l   d0,(SecondaryEntityYVel).w
                rts
; End of function Boss_Epsilon1ApplyVerticalAcceleration
; Descends to Y $90, reverses acceleration, and releases the ring objects
Boss_Epsilon1DescendAndReleaseRingState:                ; was: sub_4669C
                bsr.s   Boss_Epsilon1ApplyVerticalAcceleration
                cmpi.w  #$90,(SecondaryEntityYPos).w
                bcs.s   Boss_Epsilon1DescendAndReleaseRingReturn
                bclr    #4,$23(a5)
                move.l  #$FFFFC000,(Epsilon1VerticalAccel).w
                move.w  #6,(SharedScratchLong4).w
                move.w  $10(a5),d0
                addq.w  #8,d0
                move.w  $14(a5),d1
                movea.w (SharedScratchLong7).w,a0
                move.w  #$7C,d2                         ; '|'
                bsr.w   Projectile_PrepareEpsilon1FiveStepSpread
                move.w  $10(a5),d0
                subq.w  #8,d0
                move.w  $14(a5),d1
                movea.w (SharedScratchLong7+2).w,a0
                move.w  #$84,d2
                bsr.w   Projectile_PrepareEpsilon1FiveStepSpread
                clr.w   $48(a5)
                clr.w   d0
                move.w  #5,d7
                lea     Boss_Epsilon1RingObjectSlots(pc),a2
Boss_Epsilon1ReleaseRingObjectPairsLoop:                ; was: loc_466F4
                movea.w (a2,d0.w),a0
                movea.w $C(a2,d0.w),a1
                addq.w  #2,4(a0)
                addq.w  #2,4(a1)
                addq.w  #2,d0
                dbf     d7,Boss_Epsilon1ReleaseRingObjectPairsLoop
                addq.w  #2,4(a5)
Boss_Epsilon1DescendAndReleaseRingReturn:               ; was: locret_4670E
                rts
; End of function Boss_Epsilon1DescendAndReleaseRingState
; Applies reverse acceleration until the turn angle reaches $180
Boss_Epsilon1RiseAfterRingReleaseState:                 ; was: sub_46710
                cmpi.l  #$FFFE0000,(SecondaryEntityYVel).w
                blt.s   Boss_Epsilon1CheckRingReleaseTurnAngle
                bsr.w   Boss_Epsilon1ApplyVerticalAcceleration
Boss_Epsilon1CheckRingReleaseTurnAngle:                 ; was: loc_4671E
                cmpi.w  #$180,(SharedScratchLong5).w
                bcs.s   Boss_Epsilon1RiseAfterRingReleaseReturn
                move.w  #6,(SharedScratchLong5+2).w
                clr.w   (SharedScratchLong4).w
                move.l  #$800,(Epsilon1VerticalAccel).w
                addq.w  #2,4(a5)
Boss_Epsilon1RiseAfterRingReleaseReturn:                ; was: locret_4673C
                rts
; End of function Boss_Epsilon1RiseAfterRingReleaseState
; Applies acceleration until all released ring objects become inactive
Boss_Epsilon1WaitForReleasedRingObjectsState:           ; was: sub_4673E
                bsr.w   Boss_Epsilon1ApplyVerticalAcceleration
                clr.w   d0
                move.w  #5,d7
                lea     Boss_Epsilon1RingObjectSlots(pc),a0
Boss_Epsilon1CheckReleasedRingPairsLoop:                ; was: loc_4674C
                movea.w (a0,d0.w),a1
                movea.w $C(a0,d0.w),a2
                tst.w   4(a1)
                bne.s   Boss_Epsilon1WaitForReleasedRingObjectsReturn
                tst.w   4(a2)
                bne.s   Boss_Epsilon1WaitForReleasedRingObjectsReturn
                addq.w  #2,d0
                dbf     d7,Boss_Epsilon1CheckReleasedRingPairsLoop
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForReleasedRingObjectsReturn:          ; was: locret_4676A
                                        ; Boss_Epsilon1WaitForReleasedRingObjectsState+20   j
                rts
; End of function Boss_Epsilon1WaitForReleasedRingObjectsState
; Waits for angle alignment and seeds the sweep-recovery motion
Boss_Epsilon1PrepareSweepRecoveryState:                 ; was: sub_4676C
                bsr.w   Boss_Epsilon1CheckAngleHistoryAligned
                bne.s   Boss_Epsilon1PrepareSweepRecoveryReturn
                clr.l   (SecondaryEntityYVel).w
                move.w  #1,(SharedScratchLong5+2).w
                move.w  #$10,(SharedScratchLong4).w
                move.w  #0,$58(a5)
                move.l  #$3000,(Epsilon1VerticalAccel).w
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
Boss_Epsilon1PrepareSweepRecoveryReturn:                ; was: locret_4679A
                rts
; End of function Boss_Epsilon1PrepareSweepRecoveryState
; Applies recovery motion, then returns the battle center to Y $40
Boss_Epsilon1RecoverBattleCenterState:                  ; was: sub_4679C
                tst.w   $48(a5)
                bmi.s   Boss_Epsilon1MoveToRecoveryHeight
                bsr.w   Boss_Epsilon1ApplyVerticalAcceleration
                subq.w  #1,$48(a5)
                bpl.s   Boss_Epsilon1MoveToRecoveryHeight
                clr.l   (SecondaryEntityYVel).w
Boss_Epsilon1MoveToRecoveryHeight:                      ; was: loc_467B0
                                        ; Boss_Epsilon1RecoverBattleCenterState+E   j
                bsr.w   Boss_Epsilon1ApplyDirectionalVerticalStep
                cmpi.w  #$40,(SecondaryEntityYPos).w    ; '@'
                bgt.s   Boss_Epsilon1RecoverBattleCenterReturn
                move.w  #4,(SharedScratchLong5+2).w
                move.w  #4,(SharedScratchLong4).w
                clr.w   (Epsilon1ProximityFlag).w
                clr.w   (Epsilon1ProximityTimer).w
                move.w  #$12,4(a5)
Boss_Epsilon1RecoverBattleCenterReturn:                 ; was: locret_467D6
                rts
; End of function Boss_Epsilon1RecoverBattleCenterState
; Clears projectile pointers and initializes scrolling
