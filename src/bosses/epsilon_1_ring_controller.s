Boss_Epsilon1RingController:                            ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_46D68
                btst    #0,(PrimaryEntityWork4C).w
                bne.s   Boss_Epsilon1DeactivateRingController
                btst    #2,(PrimaryEntityWork4C).w
                beq.s   Boss_Epsilon1DispatchRingMode
Boss_Epsilon1DeactivateRingController:                  ; CODE XREF: Boss_Epsilon1RingController+6   j  ; was: loc_46D78
                andi.w  #$7FFF,2(a5)
                clr.w   4(a5)
                tst.w   (SharedScratchLong8).w
                beq.s   Boss_Epsilon1DispatchRingMode
                movea.w (SharedScratchLong8).w,a0
                bset    #4,2(a0)
                clr.w   (SharedScratchLong8).w
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1DispatchRingMode:                          ; CODE XREF: Boss_Epsilon1RingController+E   j  ; was: loc_46D98
                                        ; Boss_Epsilon1RingController+1E   j
                tst.w   $5E(a5)
                bne.w   Boss_Epsilon1DispatchBarrageRingState
                move.w  4(a5),d0
                lea     Boss_Epsilon1TrackingRingStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1RingController
; ---------------------------------------------------------------------------
Boss_Epsilon1TrackingRingStates:                        ; was: off_46DAC
                dc.w    Boss_Epsilon1TrackingRingInactiveState-*  ; DATA XREF: Boss_Epsilon1RingController+3C   o
                dc.w    Boss_Epsilon1InitializeTrackingRingState-*
                dc.w    Boss_Epsilon1TrackPlayerWithRingState-*
                dc.w    Boss_Epsilon1CreateSpreadAimMarkerState-*
                dc.w    Boss_Epsilon1FinishTrackingRingPassState-*
                dc.w    Boss_Epsilon1TrackingRingPauseState-*
                dc.w    Boss_Epsilon1RepeatOrDeactivateTrackingRingState-*

Boss_Epsilon1TrackingRingInactiveState:                 ; DATA XREF: ROM:Boss_Epsilon1TrackingRingStates   o  ; was: nullsub_87
                rts
; End of function Boss_Epsilon1TrackingRingInactiveState

; Initializes a tracking pass at the first entity-pool object's position
Boss_Epsilon1InitializeTrackingRingState:               ; DATA XREF: ROM:00046DAE   o  ; was: sub_46DBC
                addq.w  #2,4(a5)
                ori.w   #$8000,2(a5)
                move.w  (PrimaryEntityXPos).w,$10(a5)
                move.w  (PrimaryEntityYPos).w,$14(a5)
                move.w  #4,$4A(a5)
                move.w  #$FFFF,$4E(a5)
                move.w  #$40,$48(a5)                    ; '@'
                rts
; End of function Boss_Epsilon1InitializeTrackingRingState
; Steers toward the player until close enough or the tracking timeout expires
Boss_Epsilon1TrackPlayerWithRingState:                  ; DATA XREF: ROM:00046DB0   o  ; was: sub_46DE6
                bsr.w   Boss_Epsilon1SteerRingTowardPlayer
                move.w  (PlayerCenterX).w,d0
                sub.w   $10(a5),d0
                bpl.s   Boss_Epsilon1UseAbsoluteRingTrackingXDelta
                neg.w   d0
Boss_Epsilon1UseAbsoluteRingTrackingXDelta:             ; CODE XREF: Boss_Epsilon1TrackPlayerWithRingState+C   j  ; was: loc_46DF6
                cmpi.w  #$10,d0
                bcc.s   Boss_Epsilon1TickRingTrackingTimeout
                move.w  (PlayerCenterY).w,d0
                sub.w   $14(a5),d0
                bpl.s   Boss_Epsilon1UseAbsoluteRingTrackingYDelta
                neg.w   d0
Boss_Epsilon1UseAbsoluteRingTrackingYDelta:             ; CODE XREF: Boss_Epsilon1TrackPlayerWithRingState+1E   j  ; was: loc_46E08
                cmpi.w  #$18,d0
                bcc.s   Boss_Epsilon1TickRingTrackingTimeout
                bra.s   Boss_Epsilon1StopRingAtTarget
; ---------------------------------------------------------------------------
Boss_Epsilon1TickRingTrackingTimeout:                   ; CODE XREF: Boss_Epsilon1TrackPlayerWithRingState+14   j  ; was: loc_46E10
                                        ; Boss_Epsilon1TrackPlayerWithRingState+26   j
                subq.w  #1,$48(a5)
                bpl.s   Boss_Epsilon1TrackPlayerWithRingReturn
Boss_Epsilon1StopRingAtTarget:                          ; CODE XREF: Boss_Epsilon1TrackPlayerWithRingState+28   j  ; was: loc_46E16
                tst.w   (SharedScratchLong8).w
                bne.s   Boss_Epsilon1TrackPlayerWithRingReturn
                move.w  #$10,$48(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1TrackPlayerWithRingReturn:                 ; CODE XREF: Boss_Epsilon1TrackPlayerWithRingState+2E   j  ; was: locret_46E2E
                                        ; Boss_Epsilon1TrackPlayerWithRingState+34   j
                rts
; End of function Boss_Epsilon1TrackPlayerWithRingState
; Turns the controller toward the player and derives fixed-point velocity
Boss_Epsilon1SteerRingTowardPlayer:                     ; CODE XREF: Boss_Epsilon1TrackPlayerWithRingState   p  ; was: sub_46E30
                                        ; Boss_Epsilon1FinishTrackingRingPassState   p
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_Epsilon1ApplyRingSteeringVelocity
                jsr     (Math_CalculateAngleToPlayer).l
                tst.w   $4E(a5)
                bpl.s   Boss_Epsilon1ChooseRingTurnDirection
                move.w  d2,$4E(a5)
                bra.s   Boss_Epsilon1ApplyRingSteeringVelocity
; ---------------------------------------------------------------------------
Boss_Epsilon1ChooseRingTurnDirection:                   ; CODE XREF: Boss_Epsilon1SteerRingTowardPlayer+14   j  ; was: loc_46E4C
                move.w  $4E(a5),d1
                sub.w   d2,d1
                andi.w  #$1FF,d1
                beq.s   Boss_Epsilon1ApplyRingSteeringVelocity
                cmpi.w  #$100,d1
                bcs.s   Boss_Epsilon1SetNegativeRingTurnStep
                move.w  #$10,$4C(a5)
                bra.s   Boss_Epsilon1ApplyRingSteeringVelocity
; ---------------------------------------------------------------------------
Boss_Epsilon1SetNegativeRingTurnStep:                   ; CODE XREF: Boss_Epsilon1SteerRingTowardPlayer+2C   j  ; was: loc_46E66
                move.w  #$FFF0,$4C(a5)
Boss_Epsilon1ApplyRingSteeringVelocity:                 ; CODE XREF: Boss_Epsilon1SteerRingTowardPlayer+8   j  ; was: loc_46E6C
                                        ; Boss_Epsilon1SteerRingTowardPlayer+1A   j
                move.w  $4C(a5),d0
                add.w   d0,$4E(a5)
                andi.w  #$1FF,$4E(a5)
                move.w  $4E(a5),d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a2
                move.w  Math_QuarterSineTable-Math_SineTable(a2,d0.w),d1
                move.w  (a2,d0.w),d0
                ext.l   d0
                ext.l   d1
                asl.l   #4,d0
                asl.l   #4,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                rts
; End of function Boss_Epsilon1SteerRingTowardPlayer
; Reserves an inert object at the tracked position for the boss attack controller
Boss_Epsilon1CreateSpreadAimMarkerState:                ; DATA XREF: ROM:00046DB2   o  ; was: sub_46EA2
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bpl.w   Boss_Epsilon1CreateSpreadAimMarkerReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1CreateSpreadAimMarkerReturn
                move.w  a0,(SharedScratchLong8).w
                move.w  #$10,(a0)
                move.w  #$C3C9,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.w  #$8080,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                addq.w  #2,4(a5)
                tst.w   (Epsilon1ProximityFlag).w
                bne.s   Boss_Epsilon1ClearTrackingRingAttributeBit
                subq.w  #1,$4A(a5)
                beq.w   Boss_Epsilon1ClearTrackingRingAttributeBit
                clr.w   $4C(a5)
                ori.w   #$8000,2(a5)
                bra.s   Boss_Epsilon1SelectTrackingRingFinishDelay
; ---------------------------------------------------------------------------
Boss_Epsilon1ClearTrackingRingAttributeBit:             ; CODE XREF: Boss_Epsilon1CreateSpreadAimMarkerState+4A   j  ; was: loc_46F02
                                        ; Boss_Epsilon1CreateSpreadAimMarkerState+50   j
                andi.w  #$7FFF,2(a5)
Boss_Epsilon1SelectTrackingRingFinishDelay:             ; CODE XREF: Boss_Epsilon1CreateSpreadAimMarkerState+5E   j  ; was: loc_46F08
                tst.w   (DifficultyMode).w
                bne.s   Boss_Epsilon1UseShortTrackingRingFinishDelay
                move.w  #$10,$48(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1UseShortTrackingRingFinishDelay:           ; CODE XREF: Boss_Epsilon1CreateSpreadAimMarkerState+6A   j  ; was: loc_46F16
                move.w  #8,$48(a5)
Boss_Epsilon1CreateSpreadAimMarkerReturn:               ; CODE XREF: Boss_Epsilon1CreateSpreadAimMarkerState+A   j  ; was: locret_46F1C
                                        ; Boss_Epsilon1CreateSpreadAimMarkerState+14   j
                rts
; End of function Boss_Epsilon1CreateSpreadAimMarkerState
; Keeps steering during the post-marker delay, then stops the controller
Boss_Epsilon1FinishTrackingRingPassState:               ; DATA XREF: ROM:00046DB4   o  ; was: sub_46F1E
                bsr.w   Boss_Epsilon1SteerRingTowardPlayer
                subq.w  #1,$48(a5)
                bpl.w   Boss_Epsilon1FinishTrackingRingPassReturn
                clr.l   $18(a5)
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1FinishTrackingRingPassReturn:              ; CODE XREF: Boss_Epsilon1FinishTrackingRingPassState+8   j  ; was: locret_46F36
                rts
; End of function Boss_Epsilon1FinishTrackingRingPassState
Boss_Epsilon1TrackingRingPauseState:                    ; DATA XREF: ROM:00046DB6   o  ; was: nullsub_88
                rts
; End of function Boss_Epsilon1TrackingRingPauseState

; Repeats the tracking pass or deactivates the controller
Boss_Epsilon1RepeatOrDeactivateTrackingRingState:       ; DATA XREF: ROM:00046DB8   o  ; was: sub_46F3A
                tst.w   (Epsilon1ProximityFlag).w
                bne.s   Boss_Epsilon1DeactivateTrackingRingCycle
                tst.w   $4A(a5)
                beq.w   Boss_Epsilon1DeactivateTrackingRingCycle
                move.w  #$40,$48(a5)                    ; '@'
                move.w  #4,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1DeactivateTrackingRingCycle:               ; CODE XREF: Boss_Epsilon1RepeatOrDeactivateTrackingRingState+4   j  ; was: loc_46F56
                                        ; Boss_Epsilon1RepeatOrDeactivateTrackingRingState+A   j
                bclr    #7,2(a5)
                clr.w   4(a5)
                rts
; End of function Boss_Epsilon1RepeatOrDeactivateTrackingRingState
; Dispatches the randomized barrage mode selected by field $5E
Boss_Epsilon1DispatchBarrageRingState:                  ; CODE XREF: Boss_Epsilon1RingController+34   j  ; was: sub_46F62
                move.w  4(a5),d0
                lea     Boss_Epsilon1BarrageRingStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1DispatchBarrageRingState
; ---------------------------------------------------------------------------
Boss_Epsilon1BarrageRingStates:                         ; was: off_46F6E
                dc.w    Boss_Epsilon1BarrageRingInactiveState-*  ; DATA XREF: Boss_Epsilon1DispatchBarrageRingState+4   o
                dc.w    Boss_Epsilon1InitializeBarrageRingOrderState-*
                dc.w    Boss_Epsilon1ShuffleBarrageRingOrderState-*
                dc.w    Boss_Epsilon1ReserveBarrageEmitterState-*
                dc.w    Boss_Epsilon1PositionBarrageRingState-*
                dc.w    Boss_Epsilon1ActivateReservedBarrageEmitterState-*
                dc.w    Boss_Epsilon1BarrageRingHoldState-*
                dc.w    Boss_Epsilon1ResetBarrageRingState-*

Boss_Epsilon1BarrageRingInactiveState:                  ; DATA XREF: ROM:Boss_Epsilon1BarrageRingStates   o  ; was: nullsub_89
                rts
; End of function Boss_Epsilon1BarrageRingInactiveState

; Initializes the order array with indices zero through seven
Boss_Epsilon1InitializeBarrageRingOrderState:           ; DATA XREF: ROM:00046F70   o  ; was: sub_46F80
                move.w  #8,$4A(a5)
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
                move.w  #7,d7
                moveq   #0,d0
                lea     $50(a5),a0
Boss_Epsilon1FillBarrageRingOrderLoop:                  ; CODE XREF: Boss_Epsilon1InitializeBarrageRingOrderState+1E   j  ; was: loc_46F9A
                move.b  d0,(a0)+
                addq.b  #1,d0
                dbf     d7,Boss_Epsilon1FillBarrageRingOrderLoop
; End of function Boss_Epsilon1InitializeBarrageRingOrderState

; Randomizes the barrage order with eight successful pair swaps
Boss_Epsilon1ShuffleBarrageRingOrderState:              ; DATA XREF: ROM:00046F72   o  ; was: loc_46FA2
                lea     $50(a5),a0
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #7,d0
                andi.w  #7,d1
                cmp.w   d0,d1
                beq.s   Boss_Epsilon1ShuffleBarrageRingOrderReturn
                move.b  (a0,d0.w),d2
                move.b  (a0,d1.w),(a0,d0.w)
                move.b  d2,(a0,d1.w)
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1ShuffleBarrageRingOrderReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                move.w  d0,$4E(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1ShuffleBarrageRingOrderReturn:             ; CODE XREF: Boss_Epsilon1ShuffleBarrageRingOrderState+38   j  ; was: locret_46FDE
                                        ; Boss_Epsilon1ShuffleBarrageRingOrderState+4C   j
                rts
; End of function Boss_Epsilon1ShuffleBarrageRingOrderState
; Reserves an inert projectile slot for the next barrage position
Boss_Epsilon1ReserveBarrageEmitterState:                ; DATA XREF: ROM:00046F74   o  ; was: sub_46FE0
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Projectile_Epsilon1SpreadOrBarrageReturn
                move.w  #$10,(a0)
                move.w  a0,$4C(a5)
                addq.w  #2,4(a5)
                tst.w   (DifficultyMode).w
                bne.s   Boss_Epsilon1UseShortBarrageRingSetupDelay
                move.w  #$28,$48(a5)                    ; '('
                bra.s   Boss_Epsilon1PositionBarrageRingState
; ---------------------------------------------------------------------------
Boss_Epsilon1UseShortBarrageRingSetupDelay:             ; CODE XREF: Boss_Epsilon1ReserveBarrageEmitterState+1A   j  ; was: loc_47004
                move.w  #$20,$48(a5)                    ; ' '
; Positions the barrage controller after its setup delay
Boss_Epsilon1PositionBarrageRingState:                  ; CODE XREF: Boss_Epsilon1ReserveBarrageEmitterState+22   j  ; was: loc_4700A
                                        ; DATA XREF: ROM:00046F76   o
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1PositionBarrageRingReturn
                ori.w   #$8000,2(a5)
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
                move.w  $4A(a5),d0
                subq.w  #1,d0
                lea     $50(a5),a0
                move.b  (a0,d0.w),d0
                andi.w  #$F,d0
                add.w   d0,d0
                move.w  Boss_Epsilon1BarrageRingHorizontalOffsets(pc,d0.w),d0
                addi.w  #$120,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                add.w   $4E(a5),d0
                move.w  d0,$10(a5)
                move.w  (PlayerCenterY).w,$14(a5)
Boss_Epsilon1PositionBarrageRingReturn:                 ; CODE XREF: Boss_Epsilon1ReserveBarrageEmitterState+2E   j  ; was: locret_4704E
                rts
; End of function Boss_Epsilon1ReserveBarrageEmitterState
; ---------------------------------------------------------------------------
Boss_Epsilon1BarrageRingHorizontalOffsets:              ; was: word_47050
                dc.w    $FF80, $FFA0, $FFC0, $FFE0, 0, $20, $40, $60, $C0, $E0, $100, $120
                                        ; DATA XREF: Boss_Epsilon1ReserveBarrageEmitterState+54   r

; Activates the reserved slot as a type-$2E8 barrage emitter
Boss_Epsilon1ActivateReservedBarrageEmitterState:       ; DATA XREF: ROM:00046F78   o  ; was: sub_47068
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1ActivateReservedBarrageEmitterReturn
                andi.w  #$7FFF,2(a5)
                movea.w $4C(a5),a0
                move.w  #$2E8,(a0)
                move.w  #$C3C9,$E(a0)
                move.w  #$A00,8(a0)
                move.w  #$F4F4,$A(a0)
                move.w  #$8080,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                tst.w   (Epsilon1ProximityFlag).w
                bne.s   Boss_Epsilon1FinishBarrageRingSequence
                subq.w  #1,$4A(a5)
                beq.s   Boss_Epsilon1FinishBarrageRingSequence
                move.w  #6,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1FinishBarrageRingSequence:                 ; CODE XREF: Boss_Epsilon1ActivateReservedBarrageEmitterState+3C   j  ; was: loc_470B4
                                        ; Boss_Epsilon1ActivateReservedBarrageEmitterState+42   j
                addq.w  #2,4(a5)
Boss_Epsilon1ActivateReservedBarrageEmitterReturn:      ; CODE XREF: Boss_Epsilon1ActivateReservedBarrageEmitterState+4   j  ; was: locret_470B8
                rts
; End of function Boss_Epsilon1ActivateReservedBarrageEmitterState
Boss_Epsilon1BarrageRingHoldState:                      ; DATA XREF: ROM:00046F7A   o  ; was: nullsub_90
                rts
; End of function Boss_Epsilon1BarrageRingHoldState

; Returns the barrage controller to its inactive state
Boss_Epsilon1ResetBarrageRingState:                     ; DATA XREF: ROM:00046F7C   o  ; was: sub_470BC
                clr.w   4(a5)
                rts
; End of function Boss_Epsilon1ResetBarrageRingState
; Spread shot initialization
