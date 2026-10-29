; Main segment handler
Boss_SunsetStingSegmentMain:                            ; was: sub_4333A
                lea     (Entity_ObjectPool).w,a3
                lea     (SunsetStingSharedState).w,a4
                bsr.s   Boss_SunsetStingSegmentDispatcher
                cmpi.w  #$C,4(a5)
                beq.w   Boss_SunsetStingReturn
                btst    #7,(a4)
                beq.s   Boss_SunsetStingSegmentApplyRotationDelta
                clr.b   $21(a5)
                move.w  #$C,4(a5)
Boss_SunsetStingSegmentApplyRotationDelta:              ; was: loc_4335E
                move.w  4(a4),d0
                add.w   d0,6(a5)
                rts
; End of function Boss_SunsetStingSegmentMain
; Segment state dispatcher
Boss_SunsetStingSegmentDispatcher:                      ; was: sub_43368
                movea.w 4(a5),a0
                lea     Boss_SunsetStingSegmentStates(pc,a0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_SunsetStingSegmentDispatcher
; ---------------------------------------------------------------------------
Boss_SunsetStingSegmentStates:
                dc.w    Boss_SunsetStingSegmentInitializeState-*  ; was: off_43374
                dc.w    Boss_SunsetStingSegmentAdvanceToOrbitState-*
                dc.w    Boss_SunsetStingSegmentOrbitState-*
                dc.w    Boss_SunsetStingSegmentFlightState-*
                dc.w    Boss_SunsetStingSegmentDestroyedFlightState-*
                dc.w    Boss_SunsetStingSegmentReattachState-*
                dc.w    Boss_SunsetStingSegmentConvertToDebrisState-*

; Initializes a primary segment
Boss_SunsetStingSegmentInitializeState:                 ; was: sub_43382
                move.w  #$CD00,2(a5)
                move.b  #$40,$20(a5)                    ; '@'
                addq.w  #2,4(a5)
; Advances the primary segment into its orbit state
Boss_SunsetStingSegmentAdvanceToOrbitState:             ; was: loc_43392
                addq.w  #2,4(a5)
; Updates a primary segment in the rotating ring and checks its release bit
Boss_SunsetStingSegmentOrbitState:                      ; was: loc_43396
                move.w  6(a5),d0
                move.w  $44(a5),d2
                cmpi.w  #$80,d2
                beq.s   Boss_SunsetStingSegmentOrbitUpdatePosition
                addq.w  #2,$44(a5)
Boss_SunsetStingSegmentOrbitUpdatePosition:             ; was: loc_433A8
                bsr.w   Math_GetScaledSinCos
                add.l   $10(a3),d0
                add.l   $14(a3),d1
                move.l  d0,$10(a5)
                move.l  d1,$14(a5)
                move.w  6(a5),d0
                lea     Boss_SunsetStingSegmentMappings(pc),a0
                bsr.w   Boss_SunsetStingSelectSegmentMapping
                move.w  $46(a5),d0
                move.w  2(a4),d1
                btst    d0,d1
                beq.w   Boss_SunsetStingReturn
                cmpi.w  #$FFFF,2(a4)
                beq.s   Boss_SunsetStingSegmentLaunchFromRing
                subi.w  #$F,(BossCombatCounter).w
Boss_SunsetStingSegmentLaunchFromRing:                  ; was: loc_433E4
                move.w  6(a5),d0
                moveq   #8,d2
                bsr.w   Math_GetScaledSinCos
                move.l  d0,$18(a5)
                asr.l   #1,d0
                move.l  d1,$1C(a5)
                move.l  #$1800,$58(a5)
                move.w  (DifficultyMode).w,d0
                lsr.w   #1,d0
                addq.w  #1,d0
                move.w  d0,$48(a5)
                move.b  #$C0,$21(a5)
                move.w  6(a5),$44(a5)
                clr.w   $4A(a5)
                move.w  #$10,$24(a5)
                addq.w  #2,4(a5)
                move.b  #$CC,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Boss_SunsetStingSegmentInitializeState
; Updates a released primary segment in flight
Boss_SunsetStingSegmentFlightState:                     ; was: sub_43430
                tst.w   $24(a5)
                bpl.s   Boss_SunsetStingSegmentFlightUpdate
                bsr.w   Physics_ClearVelocity
                move.b  d0,$21(a5)
                move.w  #8,4(a5)
                jsr     (Effect_SpawnExplosionA).l
                bclr    #4,$22(a5)
                beq.s   Boss_SunsetStingSegmentDestroyedReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_SunsetStingSegmentDestroyedReturn
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                jsr     (Pickup_SpawnLarge).l
Boss_SunsetStingSegmentDestroyedReturn:                 ; was: locret_4346C
                                        ; Boss_SunsetStingSegmentFlightState+28   j
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingSegmentFlightUpdate:                    ; was: loc_4346E
                move.l  $58(a5),d0
                add.l   d0,$1C(a5)
                move.w  $4A(a5),d0
                add.w   d0,$44(a5)
                move.w  $44(a5),d0
                lea     Boss_SunsetStingSegmentMappings(pc),a0
                bsr.w   Boss_SunsetStingSelectSegmentMapping
                tst.w   $48(a5)
                beq.s   Boss_SunsetStingSegmentFlightCheckBounds
                move.l  $1C(a5),d0
                bmi.s   Boss_SunsetStingSegmentFlightCheckBounds
                add.l   $14(a5),d0
                swap    d0
                addq.w  #8,d0
                cmpi.w  #$148,d0
                bcs.w   Boss_SunsetStingReturn
                moveq   #$30,d0                         ; '0'
                tst.w   $18(a5)
                bpl.s   Boss_SunsetStingSegmentSetBounceRotation
                neg.w   d0
Boss_SunsetStingSegmentSetBounceRotation:               ; was: loc_434B0
                move.w  d0,$4A(a5)
                move.l  $1C(a5),d0
                move.l  d0,d1
                asr.l   #3,d1
                sub.l   d1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                subq.w  #1,$48(a5)
Boss_SunsetStingSegmentFlightCheckBounds:               ; was: loc_434C8
                                        ; Boss_SunsetStingSegmentFlightState+64   j
                bsr.w   Boss_SunsetStingCheckWithinFlightBounds
                bne.w   Boss_SunsetStingReturn
                move.w  #$A,4(a5)
                rts
; End of function Boss_SunsetStingSegmentFlightState
; Continues a destroyed primary segment's flight until it leaves the bounds
Boss_SunsetStingSegmentDestroyedFlightState:            ; was: sub_434D8
                move.l  $58(a5),d0
                add.l   d0,$1C(a5)
                bra.s   Boss_SunsetStingSegmentFlightCheckBounds
; End of function Boss_SunsetStingSegmentDestroyedFlightState
; Resets a returned primary segment to its orbit state
Boss_SunsetStingSegmentReattachState:                   ; was: sub_434E2
                bsr.w   Physics_ClearVelocity
                move.w  d0,$44(a5)
                move.b  d0,$21(a5)
                move.w  #4,4(a5)
                rts
; End of function Boss_SunsetStingSegmentReattachState
; Converts a primary segment into generic defeat debris
Boss_SunsetStingSegmentConvertToDebrisState:            ; was: sub_434F6
                jsr     (Projectile_InitType88FromCurrent).l
                move.l  #SharedCombatSpriteAnimation05,8(a5)
                rts
; End of function Boss_SunsetStingSegmentConvertToDebrisState
; Secondary segment handler
Boss_SunsetStingSecondarySegmentMain:                   ; was: sub_43506
                lea     (Entity_ObjectPool).w,a3
                lea     (SunsetStingSharedState).w,a4
                bsr.s   Boss_SunsetStingSecondarySegmentDispatch
                cmpi.w  #$E,4(a5)
                beq.w   Boss_SunsetStingReturn
                btst    #7,(a4)
                beq.s   Boss_SunsetStingSecondarySegmentApplyRotationDelta
                move.w  6(a5),d0
                moveq   #8,d2
                bsr.w   Math_GetScaledSinCos
                move.l  d0,$18(a5)
                subq.w  #2,$1C(a5)
                move.l  #$1800,$58(a5)
                move.w  #$80,d1
                bpl.s   Boss_SunsetStingSecondarySegmentStoreDetachVelocity
                neg.w   d1
Boss_SunsetStingSecondarySegmentStoreDetachVelocity:    ; was: loc_43542
                move.w  6(a5),$48(a5)
                move.w  d1,$4A(a5)
                clr.b   $21(a5)
                move.w  #$CD00,2(a5)
                move.w  #$E,4(a5)
Boss_SunsetStingSecondarySegmentApplyRotationDelta:     ; was: loc_4355C
                move.w  4(a4),d0
                add.w   d0,6(a5)
                rts
; End of function Boss_SunsetStingSecondarySegmentMain
; Secondary-segment state dispatcher
Boss_SunsetStingSecondarySegmentDispatch:               ; was: sub_43566
                movea.w 4(a5),a0
                lea     Boss_SunsetStingSecondarySegmentStates(pc,a0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_SunsetStingSecondarySegmentDispatch
; ---------------------------------------------------------------------------
Boss_SunsetStingSecondarySegmentStates:
                dc.w    Boss_SunsetStingSecondarySegmentInitializeState-*  ; was: off_43572
                dc.w    Boss_SunsetStingSecondarySegmentAdvanceToOrbitState-*
                dc.w    Boss_SunsetStingSecondarySegmentOrbitState-*
                dc.w    Boss_SunsetStingSecondarySegmentFlightState-*
                dc.w    Boss_SunsetStingSecondarySegmentFallState-*
                dc.w    Boss_SunsetStingSegmentAttachedToPlayer-*
                dc.w    Boss_SunsetStingSecondarySegmentReattachState-*
                dc.w    Boss_SunsetStingSecondarySegmentDefeatFallState-*

; Initializes a secondary segment
Boss_SunsetStingSecondarySegmentInitializeState:        ; was: sub_43582
                move.w  #$C100,2(a5)
                move.b  #$40,$20(a5)                    ; '@'
                addq.w  #2,4(a5)
; Advances the secondary segment into its orbit state
Boss_SunsetStingSecondarySegmentAdvanceToOrbitState:    ; was: loc_43592
                addq.w  #2,4(a5)
; Updates a secondary segment in the rotating ring and checks its release bit
Boss_SunsetStingSecondarySegmentOrbitState:             ; was: loc_43596
                move.w  6(a5),d0
                move.w  $44(a5),d2
                cmpi.w  #$98,d2
                beq.s   Boss_SunsetStingSecondarySegmentOrbitUpdatePosition
                addq.w  #2,$44(a5)
Boss_SunsetStingSecondarySegmentOrbitUpdatePosition:    ; was: loc_435A8
                bsr.w   Math_GetScaledSinCos
                add.l   $10(a3),d0
                add.l   $14(a3),d1
                move.l  d0,$10(a5)
                move.l  d1,$14(a5)
                move.w  6(a5),d0
                lea     Boss_SunsetStingDestroyedSegmentMappings(pc),a0
                bsr.w   Boss_SunsetStingSelectSegmentMapping
                move.w  $46(a5),d0
                move.w  2(a4),d1
                btst    d0,d1
                beq.w   Boss_SunsetStingReturn
                cmpi.w  #$FFFF,2(a4)
                beq.s   Boss_SunsetStingSecondarySegmentLaunchFromRing
                move.w  6(a5),d0
                addi.w  #$20,d0                         ; ' '
                andi.w  #$3FF,d0
                cmpi.w  #$240,d0
                bcc.w   Boss_SunsetStingReturn
                subi.w  #$A,(BossCombatCounter).w
Boss_SunsetStingSecondarySegmentLaunchFromRing:         ; was: loc_435F8
                move.w  6(a5),$44(a5)
                move.w  #$230,$48(a5)
                move.b  #$40,$21(a5)                    ; '@'
                bclr    #7,$22(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_SunsetStingSecondarySegmentInitializeState
; ---------------------------------------------------------------------------
Boss_SunsetStingSecondarySegmentTimingMasks:
                dc.w    3, 1                            ; was: word_43616

; Updates a released secondary segment and tests for floor or player contact
Boss_SunsetStingSecondarySegmentFlightState:            ; was: sub_4361A
                move.w  (DifficultyMode).w,d2
                move.w  Boss_SunsetStingSecondarySegmentTimingMasks(pc,d2.w),d1
                move.b  $48(a5),d2
                ext.w   d2
                tst.b   $49(a5)
                beq.s   Boss_SunsetStingSecondarySegmentAdvanceFrame
                subq.b  #1,$49(a5)
                bne.s   Boss_SunsetStingSecondarySegmentUpdatePosition
                moveq   #$FFFFFFFC,d0
                tst.w   (DifficultyMode).w
                beq.s   Boss_SunsetStingSecondarySegmentStoreFrameStep
                add.b   d0,d0
Boss_SunsetStingSecondarySegmentStoreFrameStep:         ; was: loc_4363E
                move.b  d0,$48(a5)
Boss_SunsetStingSecondarySegmentAdvanceFrame:           ; was: loc_43642
                move.w  (FrameCounter).w,d0
                and.w   d1,d0
                bne.s   Boss_SunsetStingSecondarySegmentUpdatePosition
                addq.b  #1,$48(a5)
Boss_SunsetStingSecondarySegmentUpdatePosition:         ; was: loc_4364E
                                        ; Boss_SunsetStingSecondarySegmentFlightState+2E   j
                move.w  $44(a5),d0
                bsr.w   Math_GetScaledSinCos
                add.l   d0,$10(a5)
                add.l   d1,$14(a5)
                move.b  $2D(a5),d2
                ext.w   d2
                add.w   $14(a5),d2
                cmpi.w  #$148,d2
                bcs.s   Boss_SunsetStingSecondarySegmentCheckPlayer
Boss_SunsetStingSecondarySegmentBeginFall:              ; was: loc_4366E
                move.w  6(a5),$48(a5)
                asr.l   #1,d0
                tst.w   (DifficultyMode).w
                beq.s   Boss_SunsetStingSecondarySegmentReverseYVelocity
                move.l  d1,d2
                asr.l   #2,d2
                sub.l   d2,d1
Boss_SunsetStingSecondarySegmentReverseYVelocity:       ; was: loc_43682
                neg.l   d1
                move.l  d1,$1C(a5)
                move.l  #$1400,$58(a5)
                moveq   #$40,d1                         ; '@'
                move.l  d0,$18(a5)
                bpl.s   Boss_SunsetStingSecondarySegmentStoreRotationStep
                neg.w   d1
Boss_SunsetStingSecondarySegmentStoreRotationStep:      ; was: loc_4369A
                move.w  d1,$4A(a5)
                clr.b   $21(a5)
                move.w  #$CD00,2(a5)
                move.w  #8,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_SunsetStingSecondarySegmentCheckPlayer:            ; was: loc_436B0
                lea     (PlayerObjectType).w,a0
                bclr    #7,$22(a5)
                beq.w   Boss_SunsetStingSecondarySegmentCheckBounds
                bclr    #4,$22(a5)
                beq.s   Boss_SunsetStingSecondarySegmentCheckAttach
                tst.l   d0
                bpl.s   Boss_SunsetStingSecondarySegmentOrientXVelocity
                neg.l   d0
Boss_SunsetStingSecondarySegmentOrientXVelocity:        ; was: loc_436CC
                btst    #3,$E(a0)
                bne.s   Boss_SunsetStingSecondarySegmentStoreXVelocity
                neg.l   d0
Boss_SunsetStingSecondarySegmentStoreXVelocity:         ; was: loc_436D6
                move.l  d0,$18(a5)
                bra.s   Boss_SunsetStingSecondarySegmentBeginFall
; ---------------------------------------------------------------------------
Boss_SunsetStingSecondarySegmentCheckAttach:            ; was: loc_436DC
                move.w  $14(a5),d0
                sub.w   $14(a0),d0
                cmpi.w  #$18,d0
                bgt.s   Boss_SunsetStingSecondarySegmentCheckBounds
                btst    #1,(PlayerActionStateFlags).w
                beq.s   Boss_SunsetStingSecondarySegmentStoreAttachY
                subi.b  #$14,d0
                bmi.s   Boss_SunsetStingSecondarySegmentStoreAttachY
                addi.b  #$14,d0
                add.w   d0,d0
                subi.w  #$18,d0
Boss_SunsetStingSecondarySegmentStoreAttachY:           ; was: loc_43702
                                        ; Boss_SunsetStingSecondarySegmentFlightState+DC   j
                move.b  d0,$49(a5)
                move.w  $10(a5),d0
                sub.w   $10(a0),d0
                btst    #3,$E(a0)
                bne.s   Boss_SunsetStingSecondarySegmentStoreAttachX
                neg.w   d0
Boss_SunsetStingSecondarySegmentStoreAttachX:           ; was: loc_43718
                move.b  d0,$48(a5)
                move.b  $E(a0),d0
                andi.w  #8,d0
                move.b  d0,$4A(a5)
                bsr.w   Physics_ClearVelocity
                move.b  d0,$21(a5)
                move.w  #$A,4(a5)
                rts
; End of function Boss_SunsetStingSecondarySegmentFlightState
; Applies falling motion until the released segment leaves the flight bounds
Boss_SunsetStingSecondarySegmentFallState:              ; was: sub_43738
                addi.l  #$4000,$1C(a5)
                move.w  $4A(a5),d0
                add.w   d0,$48(a5)
                move.w  $48(a5),d0
                lea     Boss_SunsetStingDestroyedSegmentMappings(pc),a0
                bsr.w   Boss_SunsetStingSelectSegmentMapping
Boss_SunsetStingSecondarySegmentCheckBounds:            ; was: loc_43754
                                        ; Boss_SunsetStingSecondarySegmentFlightState+CE   j
                bsr.w   Boss_SunsetStingCheckWithinFlightBounds
                bne.w   Boss_SunsetStingReturn
                move.w  #$C,4(a5)
                rts
; End of function Boss_SunsetStingSecondarySegmentFallState
; Updates a detached segment while it is attached to the player
Boss_SunsetStingSegmentAttachedToPlayer:                ; was: sub_43764
                addq.b  #1,$4B(a5)
                andi.b  #$F,$4B(a5)
                bne.s   Boss_SunsetStingAttachedSegmentUpdate
                bsr.w   Projectile_SpawnSunsetStingSegmentShot
Boss_SunsetStingAttachedSegmentUpdate:                  ; was: loc_43774
                move.w  $4A(a5),d0
                andi.w  #7,d0
                bne.s   Boss_SunsetStingAttachedSegmentReadPlayer
                clr.b   $21(a5)
                subq.w  #1,(PlayerHealth).w
Boss_SunsetStingAttachedSegmentReadPlayer:              ; was: loc_43786
                lea     (PlayerObjectType).w,a0
                move.b  $48(a5),d0
                ext.w   d0
                move.b  $E(a0),d1
                andi.w  #8,d1
                bne.s   Boss_SunsetStingAttachedSegmentOrientXOffset
                neg.w   d0
Boss_SunsetStingAttachedSegmentOrientXOffset:           ; was: loc_4379C
                cmp.b   $4A(a5),d1
                beq.s   Boss_SunsetStingAttachedSegmentStoreX
                bchg    #3,$E(a5)
                move.b  d1,$4A(a5)
Boss_SunsetStingAttachedSegmentStoreX:                  ; was: loc_437AC
                add.w   $10(a0),d0
                move.w  d0,$10(a5)
                move.w  $48(a5),d0
                ext.w   d0
                btst    #1,(PlayerActionStateFlags).w
                beq.s   Boss_SunsetStingAttachedSegmentStoreY
                cmpi.w  #$FFF8,d0
                bpl.s   Boss_SunsetStingAttachedSegmentAdjustY
                addi.w  #$18,d0
                bra.s   Boss_SunsetStingAttachedSegmentStoreY
; ---------------------------------------------------------------------------
Boss_SunsetStingAttachedSegmentAdjustY:                 ; was: loc_437CE
                moveq   #$18,d1
                sub.w   d0,d1
                lsr.w   #1,d1
                add.w   d1,d0
Boss_SunsetStingAttachedSegmentStoreY:                  ; was: loc_437D6
                                        ; Boss_SunsetStingSegmentAttachedToPlayer+68   j
                add.w   $14(a0),d0
                move.w  d0,$14(a5)
                btst    #4,(PlayerActionStateFlags).w
                beq.w   Boss_SunsetStingReturn
                subq.w  #2,$1C(a5)
                move.l  #$1800,$58(a5)
                moveq   #$20,d0                         ; ' '
                btst    #3,$E(a0)
                beq.s   Boss_SunsetStingAttachedSegmentRelease
                neg.w   d0
Boss_SunsetStingAttachedSegmentRelease:                 ; was: loc_43800
                move.w  d0,$4A(a5)
                clr.b   $21(a5)
                move.w  #$CD00,2(a5)
                move.w  #8,4(a5)
                rts
; End of function Boss_SunsetStingSegmentAttachedToPlayer
; Resets a returned secondary segment to its orbit state
Boss_SunsetStingSecondarySegmentReattachState:          ; was: sub_43816
                bsr.w   Physics_ClearVelocity
                move.w  d0,$44(a5)
                move.b  d0,$21(a5)
                move.w  #$C100,2(a5)
                move.w  #4,4(a5)
                rts
; End of function Boss_SunsetStingSecondarySegmentReattachState
; Drops a secondary segment during the global defeat sequence
Boss_SunsetStingSecondarySegmentDefeatFallState:        ; was: sub_43830
                move.l  $58(a5),d0
                add.l   d0,$1C(a5)
                move.w  $4A(a5),d0
                add.w   d0,$48(a5)
                move.w  $48(a5),d0
                lea     Boss_SunsetStingDestroyedSegmentMappings(pc),a0
                bsr.w   Boss_SunsetStingSelectSegmentMapping
                bsr.w   Boss_SunsetStingCheckWithinFlightBounds
                bne.w   Boss_SunsetStingReturn
                clr.w   (a5)
                rts
; End of function Boss_SunsetStingSecondarySegmentDefeatFallState
; Visible-core handler used during the defeat sequence
Boss_SunsetStingDefeatCoreMain:                         ; was: sub_43858
                lea     (Entity_ObjectPool).w,a3
                lea     (SunsetStingSharedState).w,a4
                bsr.s   Boss_SunsetStingDefeatCoreDispatch
                btst    #7,(a4)
                beq.s   Boss_SunsetStingDefeatCoreAnimate
                clr.b   $21(a5)
Boss_SunsetStingDefeatCoreAnimate:                      ; was: loc_4386C
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Boss_SunsetStingDefeatCoreReturn
                addq.w  #4,6(a5)
                cmpi.w  #$C,6(a5)
                bne.s   Boss_SunsetStingDefeatCoreSelectMapping
                clr.w   6(a5)
Boss_SunsetStingDefeatCoreSelectMapping:                ; was: loc_43886
                move.w  6(a5),d0
                move.l  Boss_SunsetStingDefeatCoreMappings(pc,d0.w),8(a5)
Boss_SunsetStingDefeatCoreReturn:                       ; was: locret_43890
                rts
; End of function Boss_SunsetStingDefeatCoreMain
; ---------------------------------------------------------------------------
Boss_SunsetStingDefeatCoreMappings:
                dc.l    Boss_SunsetStingDefeatCoreMappingA  ; was: off_43892
                dc.l    Boss_SunsetStingDefeatCoreMappingB
                dc.l    Boss_SunsetStingDefeatCoreMappingC

; Dispatches the visible core's defeat states
Boss_SunsetStingDefeatCoreDispatch:                     ; was: sub_4389E
                movea.w 4(a5),a0
                lea     Boss_SunsetStingDefeatCoreStates(pc,a0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_SunsetStingDefeatCoreDispatch
; ---------------------------------------------------------------------------
Boss_SunsetStingDefeatCoreStates:
                dc.w    Boss_SunsetStingDefeatCoreInitializeState-*  ; was: off_438AA
                dc.w    Boss_SunsetStingDefeatCoreReturn-*

; Initializes the visible core for its final defeat animation
Boss_SunsetStingDefeatCoreInitializeState:              ; was: sub_438AE
                move.w  #$CD00,2(a5)
                move.l  #Boss_SunsetStingDefeatCoreMappingC,8(a5)
                move.b  #$40,$20(a5)                    ; '@'
                move.l  #$E008F010,$2C(a5)
                bra.w   Boss_SunsetStingIncrementState
; End of function Boss_SunsetStingDefeatCoreInitializeState
; Applies gravity and disables after timer expires
Projectile_SunsetStingSegmentShotFallAndDisable:        ; was: sub_438CE
                move.l  $58(a5),d0
                add.l   d0,$1C(a5)
                subq.w  #1,$48(a5)
                bne.w   Boss_SunsetStingReturn
                bset    #4,2(a5)
                rts
; End of function Projectile_SunsetStingSegmentShotFallAndDisable
; Spawns a projectile from the attached segment with upward velocity
Projectile_SpawnSunsetStingSegmentShot:                 ; was: sub_438E6
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_SunsetStingReturn
                move.w  #$1F8,(a0)
                move.w  #$CD00,2(a0)
                move.w  #$8480,d0
                or.w    (GlobalSpritePriorityBit).w,d0
                move.w  d0,$E(a0)
                move.l  #SharedCombatSpriteFrame35,8(a0)
                move.b  #4,$20(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #$3000,$58(a0)
                move.w  #$18,$48(a0)
                rts
; End of function Projectile_SpawnSunsetStingSegmentShot
