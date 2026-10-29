Boss_Epsilon1BeginForcedTransitionState:                ; DATA XREF: ROM:00045D3E   o  ; was: sub_467D8
                clr.w   (SharedScratchLong4).w
                move.w  #0,(SharedScratchLong5+2).w
                addq.w  #2,4(a5)
                move.l  #$FFFF0000,(SecondaryEntityYVel).w
                bclr    #0,(CombatHitFlags).w
                bne.s   Boss_Epsilon1SetLeftwardTransitionVelocity
                move.w  #6,(SecondaryEntityXVel).w
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1SetLeftwardTransitionVelocity:             ; CODE XREF: Boss_Epsilon1BeginForcedTransitionState+1C   j  ; was: loc_467FE
                move.w  #$FFFA,(SecondaryEntityXVel).w
                rts
; End of function Boss_Epsilon1BeginForcedTransitionState
; Waits for all six delayed angles to align before resuming rotation
Boss_Epsilon1WaitForTransitionAngleAlignmentState:      ; DATA XREF: ROM:00045D40   o  ; was: sub_46806
                bsr.w   Boss_Epsilon1CheckAngleHistoryAligned
                bne.s   Boss_Epsilon1WaitForTransitionAngleAlignmentReturn
                move.w  #$14,(SharedScratchLong4).w
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForTransitionAngleAlignmentReturn:     ; CODE XREF: Boss_Epsilon1WaitForTransitionAngleAlignmentState+4   j  ; was: locret_46816
                rts
; End of function Boss_Epsilon1WaitForTransitionAngleAlignmentState
; Waits until screen-space X leaves the central interval, then reverses motion
Boss_Epsilon1WaitForHorizontalExitState:                ; DATA XREF: ROM:00045D42   o  ; was: sub_46818
                cmpi.w  #$180,$4E(a5)
                bhi.s   Boss_Epsilon1ReverseHorizontalTransition
                cmpi.w  #$C0,$4E(a5)
                bcs.s   Boss_Epsilon1ReverseHorizontalTransition
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1ReverseHorizontalTransition:               ; CODE XREF: Boss_Epsilon1WaitForHorizontalExitState+6   j  ; was: loc_4682A
                                        ; Boss_Epsilon1WaitForHorizontalExitState+E   j
                move.w  #8,(PlaneAShakeLevel).w
                move.l  (SecondaryEntityXVel).w,d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,(SecondaryEntityXVel).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1WaitForHorizontalExitState
; Accelerates the battle center downward to Y $100
Boss_Epsilon1DescendToLowerBoundaryState:               ; DATA XREF: ROM:00045D44   o  ; was: sub_46842
                addi.l  #$2000,(SecondaryEntityYVel).w
                cmpi.w  #$100,(SecondaryEntityYPos).w
                bcs.s   Boss_Epsilon1DescendToLowerBoundaryReturn
                clr.l   (SecondaryEntityYVel).w
                clr.l   (SecondaryEntityXVel).w
                move.w  #$60,$48(a5)                    ; '`'
                addq.w  #2,4(a5)
Boss_Epsilon1DescendToLowerBoundaryReturn:              ; CODE XREF: Boss_Epsilon1DescendToLowerBoundaryState+E   j  ; was: locret_46864
                rts
; End of function Boss_Epsilon1DescendToLowerBoundaryState
; Holds at the lower boundary before returning upward
Boss_Epsilon1LowerBoundaryDelayState:                   ; DATA XREF: ROM:00045D46   o  ; was: sub_46866
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1LowerBoundaryDelayReturn
                move.w  #0,$58(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1LowerBoundaryDelayReturn:                  ; CODE XREF: Boss_Epsilon1LowerBoundaryDelayState+4   j  ; was: locret_46876
                rts
; End of function Boss_Epsilon1LowerBoundaryDelayState
; Applies the directional step until battle-center Y crosses above $40
Boss_Epsilon1ReturnToUpperBoundaryState:                ; DATA XREF: ROM:00045D48   o  ; was: sub_46878
                bsr.w   Boss_Epsilon1ApplyDirectionalVerticalStep
                cmpi.w  #$40,(SecondaryEntityYPos).w    ; '@'
                bcc.w   Boss_Epsilon1ReturnToUpperBoundaryReturn
                addq.w  #2,4(a5)
Boss_Epsilon1ReturnToUpperBoundaryReturn:               ; CODE XREF: Boss_Epsilon1ReturnToUpperBoundaryState+A   j  ; was: locret_4688A
                rts
; End of function Boss_Epsilon1ReturnToUpperBoundaryState
; Clears the forced-transition flags and returns to attack selection
Boss_Epsilon1FinishForcedTransitionState:               ; DATA XREF: ROM:00045D4A   o  ; was: sub_4688C
                bclr    #2,(CombatHitFlags).w
                bclr    #2,$4C(a5)
                move.w  #$12,4(a5)
                rts
; End of function Boss_Epsilon1FinishForcedTransitionState
; Hides the controller and linked parts and starts the defeat delay
Boss_Epsilon1BeginDefeatState:                          ; DATA XREF: ROM:00045D4C   o  ; was: sub_468A0
                clr.b   $21(a5)
                clr.b   (TertiaryEntityStatus).w
                clr.b   (QuaternaryEntityStatus).w
                addq.w  #2,4(a5)
                move.w  #$80,$48(a5)
                move.b  #1,(SoundFadeOutDelay).w
                rts
; End of function Boss_Epsilon1BeginDefeatState
; Waits for both linked parts, then starts their destruction sequences
Boss_Epsilon1StartLinkedPartDestructionState:           ; DATA XREF: ROM:00045D4E   o  ; was: sub_468BE
                subq.w  #1,$48(a5)
                bpl.s   Boss_Epsilon1StartLinkedPartDestructionReturn
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                movea.w #(QuaternaryEntityType-M68K_RAM),a1
                cmpi.w  #6,4(a0)
                bne.s   Boss_Epsilon1StartLinkedPartDestructionReturn
                cmpi.w  #6,4(a1)
                bne.s   Boss_Epsilon1StartLinkedPartDestructionReturn
                move.b  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                move.w  d0,$48(a0)
                addq.w  #2,4(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$7F,d0
                move.w  d0,$48(a1)
                addq.w  #2,4(a1)
                addq.w  #2,4(a5)
                move.b  #$52,d0                         ; 'R'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$40,$48(a5)                    ; '@'
Boss_Epsilon1StartLinkedPartDestructionReturn:          ; CODE XREF: Boss_Epsilon1StartLinkedPartDestructionState+4   j  ; was: locret_46910
                                        ; Boss_Epsilon1StartLinkedPartDestructionState+14   j
                rts
; End of function Boss_Epsilon1StartLinkedPartDestructionState
; Falls while emitting debris, then clamps the controller at Y $140
Boss_Epsilon1FallWithDefeatDebrisState:                 ; DATA XREF: ROM:00045D50   o  ; was: sub_46912
                subq.w  #1,$48(a5)
                bpl.w   Boss_Epsilon1FallWithDefeatDebrisReturn
                addi.l  #$2000,$1C(a5)
                cmpi.w  #$148,$14(a5)
                bgt.s   Boss_Epsilon1FinishDefeatFall
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_Epsilon1FallWithDefeatDebrisReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1FallWithDefeatDebrisReturn
                jsr     (Projectile_InitType88).l
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$FFFF,$1C(a0)
                move.b  $20(a5),$20(a0)
Boss_Epsilon1FallWithDefeatDebrisReturn:                ; CODE XREF: Boss_Epsilon1FallWithDefeatDebrisState+4   j  ; was: locret_46962
                                        ; Boss_Epsilon1FallWithDefeatDebrisState+20   j
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1FinishDefeatFall:                          ; CODE XREF: Boss_Epsilon1FallWithDefeatDebrisState+16   j  ; was: loc_46964
                move.l  #$1400000,$14(a5)
                clr.l   $1C(a5)
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
                move.b  #$AC,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function Boss_Epsilon1FallWithDefeatDebrisState
; Converts the controller to explosion art and spawns the final explosion
Boss_Epsilon1TriggerFinalExplosionState:                ; DATA XREF: ROM:00045D52   o  ; was: sub_46986
                subq.w  #1,$48(a5)
                bpl.s   Boss_Epsilon1TriggerFinalExplosionReturn
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                move.w  #$480,$E(a5)
                move.w  #$EC80,2(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
                jsr     (Effect_SpawnExplosionB).l
Boss_Epsilon1TriggerFinalExplosionReturn:               ; CODE XREF: Boss_Epsilon1TriggerFinalExplosionState+4   j  ; was: locret_469AE
                rts
; End of function Boss_Epsilon1TriggerFinalExplosionState
; Restores the controller sprite after the explosion effect reaches $80
Boss_Epsilon1RestorePostExplosionSpriteState:           ; DATA XREF: ROM:00045D54   o  ; was: sub_469B0
                cmpi.w  #$80,$C(a5)
                bmi.s   Boss_Epsilon1RestorePostExplosionSpriteReturn
                move.w  #$C80,2(a5)
                move.w  (SecondaryEntityYPos).w,d0
                addi.w  #$10,d0
                move.w  d0,$14(a5)
                move.w  (SecondaryEntityXPos).w,$10(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1RestorePostExplosionSpriteReturn:          ; CODE XREF: Boss_Epsilon1RestorePostExplosionSpriteState+6   j  ; was: locret_469D4
                rts
; End of function Boss_Epsilon1RestorePostExplosionSpriteState
; Starts destruction with the final pair in the ring-object table
Boss_Epsilon1BeginRingDestructionState:                 ; DATA XREF: ROM:00045D56   o  ; was: sub_469D6
                move.w  #5,$4A(a5)
                addq.w  #2,4(a5)
; Waits for the selected ring pair to reach state $0C, then advances both
Boss_Epsilon1WaitForRingPairReadyState:                 ; DATA XREF: ROM:00045D58   o  ; was: loc_469E0
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                move.w  $4A(a5),d0
                add.w   d0,d0
                lea     Boss_Epsilon1DefeatRingObjectSlots(pc),a0
                nop
                movea.w (a0,d0.w),a1
                movea.w $C(a0,d0.w),a2
                cmpi.w  #$C,4(a1)
                bne.s   Boss_Epsilon1WaitForRingPairReadyReturn
                cmpi.w  #$C,4(a2)
                bne.s   Boss_Epsilon1WaitForRingPairReadyReturn
                addq.w  #2,4(a1)
                addq.w  #2,4(a2)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForRingPairReadyReturn:                ; CODE XREF: Boss_Epsilon1WaitForRingPairReadyState+2A   j  ; was: locret_46A1C
                                        ; Boss_Epsilon1WaitForRingPairReadyState+32   j
                rts
; End of function Boss_Epsilon1WaitForRingPairReadyState
; ---------------------------------------------------------------------------
Boss_Epsilon1DefeatRingObjectSlots: dc.w    $C800, $C860, $C8C0, $C920, $C980, $C9E0, $CA40, $CAA0, $CB00, $CB60, $CBC0, $CC20  ; was: word_46A1E
                                        ; DATA XREF: Boss_Epsilon1WaitForRingPairReadyState+16   o
                                        ; Boss_Epsilon1WaitForRingDestructionCompleteState+6   o

; Steps backward through the ring pairs, or advances after the first pair
Boss_Epsilon1AdvanceRingDestructionPairState:           ; DATA XREF: ROM:00045D5A   o  ; was: sub_46A36
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1AdvanceRingDestructionPairReturn
                subq.w  #1,$4A(a5)
                bmi.s   Boss_Epsilon1FinishRingDestruction
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1FinishRingDestruction:                     ; CODE XREF: Boss_Epsilon1AdvanceRingDestructionPairState+10   j  ; was: loc_46A4E
                addq.w  #2,4(a5)
Boss_Epsilon1AdvanceRingDestructionPairReturn:          ; CODE XREF: Boss_Epsilon1AdvanceRingDestructionPairState+A   j  ; was: locret_46A52
                rts
; End of function Boss_Epsilon1AdvanceRingDestructionPairState
; Waits until the two synchronized ring groups reach terminal state $12
Boss_Epsilon1WaitForRingDestructionCompleteState:       ; DATA XREF: ROM:00045D5C   o  ; was: sub_46A54
                jsr     (Gfx_UpdateRandomizedPaletteRange).l
                lea     Boss_Epsilon1DefeatRingObjectSlots(pc),a0
                movea.w (a0),a1
                movea.w $C(a0),a2
                cmpi.w  #$12,4(a1)
                bne.s   Boss_Epsilon1WaitForRingDestructionCompleteReturn
                cmpi.w  #$12,4(a2)
                bne.s   Boss_Epsilon1WaitForRingDestructionCompleteReturn
                move.w  #$C0,$48(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForRingDestructionCompleteReturn:      ; CODE XREF: Boss_Epsilon1WaitForRingDestructionCompleteState+16   j  ; was: locret_46A7E
                                        ; Boss_Epsilon1WaitForRingDestructionCompleteState+1E   j
                rts
; End of function Boss_Epsilon1WaitForRingDestructionCompleteState
; Emits defeat debris during the post-ring delay
Boss_Epsilon1DefeatDebrisDelayState:                    ; DATA XREF: ROM:00045D5E   o  ; was: sub_46A80
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1DefeatDebrisDelayReturn
                addq.w  #2,4(a5)
Boss_Epsilon1DefeatDebrisDelayReturn:                   ; CODE XREF: Boss_Epsilon1DefeatDebrisDelayState+A   j  ; was: locret_46A90
                rts
; End of function Boss_Epsilon1DefeatDebrisDelayState
; Emits debris and advances the fade selector once every four global ticks
Boss_Epsilon1AdvanceDefeatFadeState:                    ; DATA XREF: ROM:00045D60   o  ; was: sub_46A92
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                bsr.s   Boss_Epsilon1ApplyTimedPaletteFade
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_Epsilon1AdvanceDefeatFadeReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_Epsilon1AdvanceDefeatFadeReturn
                addq.w  #1,$48(a5)
                cmpi.w  #$F,$48(a5)
                bne.s   Boss_Epsilon1AdvanceDefeatFadeReturn
                addq.w  #2,4(a5)
Boss_Epsilon1AdvanceDefeatFadeReturn:                   ; CODE XREF: Boss_Epsilon1AdvanceDefeatFadeState+E   j  ; was: locret_46ABA
                                        ; Boss_Epsilon1AdvanceDefeatFadeState+16   j
                rts
; End of function Boss_Epsilon1AdvanceDefeatFadeState
; Applies a palette-fade step selected by the controller timer
Boss_Epsilon1ApplyTimedPaletteFade:                     ; CODE XREF: Boss_Epsilon1InitializeBattleObjectsState   p  ; was: sub_46ABC
                                        ; Boss_Epsilon1AdvanceDefeatFadeState+6   p
                move.w  $48(a5),d0
                andi.w  #$E,d0
                move.w  #$3F,d5                         ; '?'
                move.w  #$E000,d7
                lea     (PaletteActiveBuffer).w,a0
                jsr     (Gfx_ApplyPaletteFade).l
                rts
; End of function Boss_Epsilon1ApplyTimedPaletteFade
; Clears non-Epsilon objects after the fade completion gate opens
Boss_Epsilon1ClearObjectsAfterDefeatFadeState:          ; DATA XREF: ROM:00045D62   o  ; was: sub_46AD8
                bsr.s   Boss_Epsilon1ApplyTimedPaletteFade
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_Epsilon1ClearObjectsAfterDefeatFadeReturn
                move.w  #$264,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                addq.w  #2,4(a5)
Boss_Epsilon1ClearObjectsAfterDefeatFadeReturn:         ; CODE XREF: Boss_Epsilon1ClearObjectsAfterDefeatFadeState+6   j  ; was: locret_46AF0
                rts
; End of function Boss_Epsilon1ClearObjectsAfterDefeatFadeState
; Applies the final timed palette fade and decrements its timer every fourth tick
Boss_Epsilon1FinalDefeatFadeCountdownState:             ; DATA XREF: ROM:00045D64   o  ; was: sub_46AF2
                bsr.w   Boss_Epsilon1ApplyTimedPaletteFade
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_Epsilon1FinalDefeatFadeCountdownReturn
                btst    #1,(FrameCounter+1).w
                bne.s   Boss_Epsilon1FinalDefeatFadeCountdownReturn
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1FinalDefeatFadeCountdownReturn
                addq.w  #2,4(a5)
Boss_Epsilon1FinalDefeatFadeCountdownReturn:            ; CODE XREF: Boss_Epsilon1FinalDefeatFadeCountdownState+A   j  ; was: locret_46B10
                                        ; Boss_Epsilon1FinalDefeatFadeCountdownState+12   j
                rts
; End of function Boss_Epsilon1FinalDefeatFadeCountdownState
; Waits for the first post-battle stage gate
Boss_Epsilon1WaitForFirstPostBattleGateState:           ; DATA XREF: ROM:00045D66   o  ; was: sub_46B12
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_Epsilon1WaitForFirstPostBattleGateReturn
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForFirstPostBattleGateReturn:          ; CODE XREF: Boss_Epsilon1WaitForFirstPostBattleGateState+4   j  ; was: locret_46B1C
                rts
; End of function Boss_Epsilon1WaitForFirstPostBattleGateState
; Repeats the post-battle stage-gate wait in the following state
Boss_Epsilon1WaitForSecondPostBattleGateState:          ; DATA XREF: ROM:00045D68   o  ; was: sub_46B1E
                tst.b   (DataLoaderControl).w
                bmi.s   Boss_Epsilon1WaitForSecondPostBattleGateReturn
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForSecondPostBattleGateReturn:         ; CODE XREF: Boss_Epsilon1WaitForSecondPostBattleGateState+4   j  ; was: locret_46B28
                rts
; End of function Boss_Epsilon1WaitForSecondPostBattleGateState
; Starts the post-battle delay
Boss_Epsilon1StartPostBattleDelayState:                 ; DATA XREF: ROM:00045D6A   o  ; was: sub_46B2A
                move.b  #4,(PlaneAScrollModeFlags).w
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_Epsilon1StartPostBattleDelayState
; Publishes battle completion and starts the controller's final lifetime
Boss_Epsilon1PublishBattleCompletionState:              ; DATA XREF: ROM:00045D6C   o  ; was: sub_46B3C
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1PublishBattleCompletionReturn
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                move.b  #1,(AlternateTimeBonusSound).w
                move.w  #$1E0,$48(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1PublishBattleCompletionReturn:             ; CODE XREF: Boss_Epsilon1PublishBattleCompletionState+4   j  ; was: locret_46B58
                rts
; End of function Boss_Epsilon1PublishBattleCompletionState
; Removes the Epsilon 1 controller after its final lifetime expires
Boss_Epsilon1FinalDespawnState:                         ; DATA XREF: ROM:00045D6E   o  ; was: sub_46B5A
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1FinalDespawnReturn
                clr.w   (a5)
Boss_Epsilon1FinalDespawnReturn:                        ; CODE XREF: Boss_Epsilon1FinalDespawnState+4   j  ; was: locret_46B62
                rts
; End of function Boss_Epsilon1FinalDespawnState
; Updates the angle-derived body field and horizontal body-motion state
Boss_Epsilon1UpdateBodyPose:                            ; CODE XREF: Boss_Epsilon1Main+124   p  ; was: sub_46B64
                move.w  (SharedScratchLong5+2).w,d0
                add.w   d0,d0
                lea     (Epsilon1AngleHistory).w,a0
                move.w  (a0,d0.w),$56(a5)
                move.w  (SharedScratchLong6+2).w,d0
                lea     Boss_Epsilon1BodyPoseStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1UpdateBodyPose
; ---------------------------------------------------------------------------
Boss_Epsilon1BodyPoseStates:    dc.w    Boss_Epsilon1SelectBodyPoseState-*  ; DATA XREF: Boss_Epsilon1UpdateBodyPose+14   o  ; was: off_46B80
                dc.w    Boss_Epsilon1HoldAlternateBodyPoseState-*
                dc.w    Boss_Epsilon1IncrementBodyOffsetState-*
                dc.w    Boss_Epsilon1DecrementBodyOffsetState-*
                dc.w    Boss_Epsilon1ReturnBodyOffsetToCenterState-*

; Selects a rare alternate pose or begins a requested horizontal sway
Boss_Epsilon1SelectBodyPoseState:                       ; DATA XREF: ROM:Boss_Epsilon1BodyPoseStates   o  ; was: sub_46B8A
                bclr    #6,$22(a5)
                bne.s   Boss_Epsilon1StartHorizontalBodySway
                move.w  (FrameCounter).w,d0
Boss_Epsilon1CheckRandomBodyPoseTrigger:                ; was: loc_46B96
                move.w  d0,d1
                andi.w  #$FF,d0
                beq.s   Boss_Epsilon1UseAlternateBodyPose
                addi.w  #$10,d1
                andi.w  #$FF,d1
                beq.s   Boss_Epsilon1UseAlternateBodyPose
Boss_Epsilon1SelectBodyPoseReturn:                      ; CODE XREF: Boss_Epsilon1SelectBodyPoseState+3A   j  ; was: locret_46BA8
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1UseAlternateBodyPose:                      ; CODE XREF: Boss_Epsilon1SelectBodyPoseState+12   j  ; was: loc_46BAA
                                        ; Boss_Epsilon1SelectBodyPoseState+1C   j
                move.l  #Boss_Epsilon1AlternateBodyMapping,8(a5)
                move.w  #8,(SharedScratchLong8+2).w
                move.w  #2,(SharedScratchLong6+2).w
                cmpi.w  #$10,4(a5)
                bls.s   Boss_Epsilon1SelectBodyPoseReturn
                move.b  #$51,d0                         ; 'Q'
                jsr     (Sound_QueueSFXRequest).l
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1StartHorizontalBodySway:                   ; CODE XREF: Boss_Epsilon1SelectBodyPoseState+6   j  ; was: loc_46BD2
                move.l  #Boss_Epsilon1AlternateBodyMapping,8(a5)
                move.w  #2,(SharedScratchLong8+2).w
                move.w  #4,(SharedScratchLong6+2).w
                move.b  #$52,d0                         ; 'R'
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function Boss_Epsilon1SelectBodyPoseState
; Holds the alternate pose until its countdown expires
Boss_Epsilon1HoldAlternateBodyPoseState:                ; DATA XREF: ROM:00046B82   o  ; was: sub_46BF2
                subq.w  #1,(SharedScratchLong8+2).w
                bne.s   Boss_Epsilon1HoldAlternateBodyPoseReturn
                move.l  #Boss_Epsilon1PrimaryBodyMapping,8(a5)
                move.w  #0,(SharedScratchLong6+2).w
Boss_Epsilon1HoldAlternateBodyPoseReturn:               ; CODE XREF: Boss_Epsilon1HoldAlternateBodyPoseState+4   j  ; was: locret_46C06
                rts
; End of function Boss_Epsilon1HoldAlternateBodyPoseState
; Increments the horizontal body offset to eight pixels
Boss_Epsilon1IncrementBodyOffsetState:                  ; DATA XREF: ROM:00046B84   o  ; was: sub_46C08
                addq.w  #2,(SecondaryEntityWork4C).w
                cmpi.w  #8,(SecondaryEntityWork4C).w
                bne.s   Boss_Epsilon1IncrementBodyOffsetReturn
                addq.w  #2,(SharedScratchLong6+2).w
Boss_Epsilon1IncrementBodyOffsetReturn:                 ; CODE XREF: Boss_Epsilon1IncrementBodyOffsetState+A   j  ; was: locret_46C18
                rts
; End of function Boss_Epsilon1IncrementBodyOffsetState
; Decrements the horizontal body offset to minus eight pixels
Boss_Epsilon1DecrementBodyOffsetState:                  ; DATA XREF: ROM:00046B86   o  ; was: sub_46C1A
                subq.w  #2,(SecondaryEntityWork4C).w
                cmpi.w  #$FFF8,(SecondaryEntityWork4C).w
                bne.s   Boss_Epsilon1DecrementBodyOffsetReturn
                addq.w  #2,(SharedScratchLong6+2).w
Boss_Epsilon1DecrementBodyOffsetReturn:                 ; CODE XREF: Boss_Epsilon1DecrementBodyOffsetState+A   j  ; was: locret_46C2A
                rts
; End of function Boss_Epsilon1DecrementBodyOffsetState
; Returns the horizontal offset to zero and repeats or finishes the sway
Boss_Epsilon1ReturnBodyOffsetToCenterState:             ; DATA XREF: ROM:00046B88   o  ; was: sub_46C2C
                addq.w  #2,(SecondaryEntityWork4C).w
                cmpi.w  #0,(SecondaryEntityWork4C).w
                bne.s   Boss_Epsilon1ReturnBodyOffsetToCenterReturn
                subq.w  #1,(SharedScratchLong8+2).w
                beq.s   Boss_Epsilon1FinishHorizontalBodySway
                move.w  #4,(SharedScratchLong6+2).w
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1FinishHorizontalBodySway:                  ; CODE XREF: Boss_Epsilon1ReturnBodyOffsetToCenterState+10   j  ; was: loc_46C46
                move.l  #Boss_Epsilon1PrimaryBodyMapping,8(a5)
                bclr    #6,$22(a5)
                move.w  #0,(SharedScratchLong6+2).w
Boss_Epsilon1ReturnBodyOffsetToCenterReturn:            ; CODE XREF: Boss_Epsilon1ReturnBodyOffsetToCenterState+A   j  ; was: locret_46C5A
                rts
; End of function Boss_Epsilon1ReturnBodyOffsetToCenterState
; Updates one linked side part through extension, retraction, and destruction
Boss_Epsilon1UpdateLinkedPart:                          ; CODE XREF: Boss_Epsilon1Main+1CC   p  ; was: sub_46C5C
                                        ; Boss_Epsilon1Main+200   p
                btst    #0,(PrimaryEntityWork4C).w
                beq.s   Boss_Epsilon1DispatchLinkedPartState
                cmpi.w  #6,4(a1)
                bcc.s   Boss_Epsilon1DispatchLinkedPartState
                move.w  #6,4(a1)
Boss_Epsilon1DispatchLinkedPartState:                   ; CODE XREF: Boss_Epsilon1UpdateLinkedPart+6   j  ; was: loc_46C72
                                        ; Boss_Epsilon1UpdateLinkedPart+E   j
                move.w  4(a1),d0
                lea     Boss_Epsilon1LinkedPartStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1UpdateLinkedPart
; ---------------------------------------------------------------------------
Boss_Epsilon1LinkedPartStates:  dc.w    Boss_Epsilon1WaitToExtendLinkedPartState-*  ; DATA XREF: Boss_Epsilon1UpdateLinkedPart+1A   o  ; was: off_46C7E
                dc.w    Boss_Epsilon1ExtendLinkedPartState-*
                dc.w    Boss_Epsilon1RetractLinkedPartState-*
                dc.w    Boss_Epsilon1LinkedPartInactiveState-*
                dc.w    Boss_Epsilon1WaitToDestroyLinkedPartState-*
                dc.w    Boss_Epsilon1WaitForLinkedPartExplosionState-*
                dc.w    Boss_Epsilon1SpawnLinkedPartDebrisState-*
                dc.w    Boss_Epsilon1LinkedPartDebrisDelayState-*

; Waits for a random trigger or cleared render bit before extending the part
Boss_Epsilon1WaitToExtendLinkedPartState:               ; DATA XREF: ROM:Boss_Epsilon1LinkedPartStates   o  ; was: sub_46C8E
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                beq.s   Boss_Epsilon1BeginLinkedPartExtension
                bclr    #3,$22(a1)
                beq.s   Boss_Epsilon1WaitToExtendLinkedPartReturn
Boss_Epsilon1BeginLinkedPartExtension:                  ; CODE XREF: Boss_Epsilon1WaitToExtendLinkedPartState+8   j  ; was: loc_46CA0
                addq.w  #2,4(a1)
Boss_Epsilon1WaitToExtendLinkedPartReturn:              ; CODE XREF: Boss_Epsilon1WaitToExtendLinkedPartState+10   j  ; was: locret_46CA4
                rts
; End of function Boss_Epsilon1WaitToExtendLinkedPartState
; Extends the linked part to radial offset $20
Boss_Epsilon1ExtendLinkedPartState:                     ; DATA XREF: ROM:00046C80   o  ; was: sub_46CA6
                addq.w  #4,$50(a1)
                cmpi.w  #$20,$50(a1)                    ; ' '
                bne.s   Boss_Epsilon1ExtendLinkedPartReturn
                addq.w  #2,4(a1)
Boss_Epsilon1ExtendLinkedPartReturn:                    ; CODE XREF: Boss_Epsilon1ExtendLinkedPartState+A   j  ; was: locret_46CB6
                rts
; End of function Boss_Epsilon1ExtendLinkedPartState
; Retracts the linked part, then returns to the extension wait state
Boss_Epsilon1RetractLinkedPartState:                    ; DATA XREF: ROM:00046C82   o  ; was: sub_46CB8
                subq.w  #4,$50(a1)
                bne.s   Boss_Epsilon1RetractLinkedPartReturn
                bclr    #6,$22(a1)
                clr.w   4(a1)
Boss_Epsilon1RetractLinkedPartReturn:                   ; CODE XREF: Boss_Epsilon1RetractLinkedPartState+4   j  ; was: locret_46CC8
                rts
; End of function Boss_Epsilon1RetractLinkedPartState
Boss_Epsilon1LinkedPartInactiveState:                   ; DATA XREF: ROM:00046C84   o  ; was: nullsub_86
                rts
; End of function Boss_Epsilon1LinkedPartInactiveState

; Waits for the randomized destruction delay, then switches to explosion art
Boss_Epsilon1WaitToDestroyLinkedPartState:              ; DATA XREF: ROM:00046C86   o  ; was: sub_46CCC
                subq.w  #1,$48(a1)
                bpl.s   Boss_Epsilon1WaitToDestroyLinkedPartReturn
                move.w  #$EC80,2(a1)
                move.l  #SharedCombatSpriteAnimation00,8(a1)
                move.w  #$480,$E(a1)
                clr.w   $C(a1)
                addq.w  #2,4(a1)
Boss_Epsilon1WaitToDestroyLinkedPartReturn:             ; CODE XREF: Boss_Epsilon1WaitToDestroyLinkedPartState+4   j  ; was: locret_46CEE
                rts
; End of function Boss_Epsilon1WaitToDestroyLinkedPartState
; Waits until the linked part's explosion animation reaches frame $80
Boss_Epsilon1WaitForLinkedPartExplosionState:           ; DATA XREF: ROM:00046C88   o  ; was: sub_46CF0
                cmpi.w  #$80,$C(a1)
                bmi.s   Boss_Epsilon1WaitForLinkedPartExplosionReturn
                andi.w  #$7FFF,2(a1)
                addq.w  #2,4(a1)
Boss_Epsilon1WaitForLinkedPartExplosionReturn:          ; CODE XREF: Boss_Epsilon1WaitForLinkedPartExplosionState+6   j  ; was: locret_46D02
                rts
; End of function Boss_Epsilon1WaitForLinkedPartExplosionState
; Spawns one debris object from the part or battle center
Boss_Epsilon1SpawnLinkedPartDebrisState:                ; DATA XREF: ROM:00046C8A   o  ; was: sub_46D04
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1SpawnLinkedPartDebrisReturn
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (Projectile_InitType88).l
                move.b  (RandomNumberState).w,d0
                add.w   a5,d0
                andi.w  #3,d0
                subq.w  #2,d0
                move.w  d0,$18(a0)
                move.w  #2,$48(a1)
                addq.w  #2,4(a1)
                move.b  (RandomNumberState+1).w,d0
                add.w   a5,d0
                andi.w  #1,d0
                beq.s   Boss_Epsilon1UseBattleCenterForDebris
                move.w  $10(a1),$10(a0)
                move.w  $14(a1),$14(a0)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1UseBattleCenterForDebris:                  ; CODE XREF: Boss_Epsilon1SpawnLinkedPartDebrisState+3A   j  ; was: loc_46D4E
                move.w  (SecondaryEntityXPos).w,$10(a0)
                move.w  (SecondaryEntityYPos).w,$14(a0)
Boss_Epsilon1SpawnLinkedPartDebrisReturn:               ; CODE XREF: Boss_Epsilon1SpawnLinkedPartDebrisState+6   j  ; was: locret_46D5A
                rts
; End of function Boss_Epsilon1SpawnLinkedPartDebrisState
; Delays before requesting the next debris object
Boss_Epsilon1LinkedPartDebrisDelayState:                ; DATA XREF: ROM:00046C8C   o  ; was: sub_46D5C
                subq.w  #1,$48(a1)
                bne.s   Boss_Epsilon1LinkedPartDebrisDelayReturn
                subq.w  #2,4(a1)
Boss_Epsilon1LinkedPartDebrisDelayReturn:               ; CODE XREF: Boss_Epsilon1LinkedPartDebrisDelayState+4   j  ; was: locret_46D66
                rts
; End of function Boss_Epsilon1LinkedPartDebrisDelayState
; Boss intro main handler
