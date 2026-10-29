; Epsilon 1 spread, barrage-emitter, barrage-row, and fixed-ring objects
Projectile_Epsilon1InitializeFivePartSpread:            ; was: sub_470C2
                movea.w a5,a0
                move.w  #5,$4A(a0)
                bra.s   Projectile_Epsilon1InitializeSpreadCommon
; End of function Projectile_Epsilon1InitializeFivePartSpread
; Initializes the eleven-clone spread used by the longer attack sequence
Projectile_Epsilon1InitializeElevenPartSpread:          ; was: sub_470CC
                movea.w a5,a0
                move.w  #$B,$4A(a0)
Projectile_Epsilon1InitializeSpreadCommon:
                move.w  #$27C,(a0)
                move.w  #$44F1,$E(a0)
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
                move.w  #$8C80,2(a0)
                move.w  #$C8,$26(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  #$FC04FC04,$2C(a0)
                move.w  #2,$48(a0)
                lea     (Math_SineTable).l,a2
                move.w  $58(a0),d0
                andi.w  #$1FE,d0
                move.w  -$80(a2,d0.w),d1
                move.w  (a2,d0.w),d0
                ext.l   d0
                ext.l   d1
                asl.l   #6,d0
                asl.l   #6,d1
                move.l  d0,$18(a0)
                move.l  d1,$1C(a0)
                neg.l   d0
                neg.l   d1
                move.l  d0,$4C(a0)
                move.l  d1,$50(a0)
                move.l  d0,$54(a0)
                move.l  d1,$58(a0)
                rts
; End of function Projectile_Epsilon1InitializeElevenPartSpread
; Type-$27C spread projectile: emits its reserved clones, then animates in flight
Projectile_Epsilon1SpreadProjectileMain:                ; was: sub_47146
                bsr.w   Projectile_Epsilon1ConvertOnGlobalMode
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$5C(a5)
                cmpi.w  #$150,$14(a5)
                bcc.w   Projectile_Epsilon1ConvertSpreadProjectileToDebris
                cmpi.w  #$20,$14(a5)                    ; ' '
                bls.w   Projectile_Epsilon1MarkSpreadProjectileOutOfBounds
                cmpi.w  #$1D0,$5C(a5)
                bhi.w   Projectile_Epsilon1MarkSpreadProjectileOutOfBounds
                cmpi.w  #$70,$5C(a5)                    ; 'p'
                bcs.w   Projectile_Epsilon1MarkSpreadProjectileOutOfBounds
                tst.w   $5E(a5)
                beq.w   Projectile_Epsilon1DispatchSpreadProjectileState
                move.w  #4,4(a5)
Projectile_Epsilon1DispatchSpreadProjectileState:
                move.w  4(a5),d0
                lea     Projectile_Epsilon1SpreadProjectileStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_Epsilon1SpreadProjectileMain
; ---------------------------------------------------------------------------
Projectile_Epsilon1SpreadProjectileStates:  dc.w    Projectile_Epsilon1SpreadProjectileDelayState-*
                dc.w    Projectile_Epsilon1EmitSpreadCloneState-*
                dc.w    Projectile_Epsilon1AnimateSpreadProjectileState-*

; Delays the parent spread projectile before clone emission
Projectile_Epsilon1SpreadProjectileDelayState:          ; was: sub_4719E
                subq.w  #1,$48(a5)
                bne.s   Projectile_Epsilon1SpreadProjectileDelayReturn
                addq.w  #2,4(a5)
Projectile_Epsilon1SpreadProjectileDelayReturn:
                rts
; End of function Projectile_Epsilon1SpreadProjectileDelayState
; Emits one clone at the current spread offset and advances that offset
Projectile_Epsilon1EmitSpreadCloneState:                ; was: sub_471AA
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_Epsilon1EmitSpreadCloneReturn
                move.w  #1,$5E(a0)
                move.w  #$27C,(a0)
                move.w  #$44F1,$E(a0)
                move.w  #0,8(a0)
                move.w  #$FCFC,$A(a0)
                move.w  #$8CC0,2(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  $18(a5),$18(a0)
                move.l  $1C(a5),$1C(a0)
                move.l  $4C(a5),d0
                add.l   d0,$10(a0)
                move.l  $50(a5),d1
                add.l   d1,$14(a0)
                move.l  $54(a5),d0
                add.l   d0,$4C(a5)
                move.l  $58(a5),d1
                add.l   d1,$50(a5)
                subq.w  #1,$4A(a5)
                bne.s   Projectile_Epsilon1EmitSpreadCloneReturn
                addq.w  #2,4(a5)
Projectile_Epsilon1EmitSpreadCloneReturn:
                                        ; Projectile_Epsilon1EmitSpreadCloneState+6E   j
                rts
; End of function Projectile_Epsilon1EmitSpreadCloneState
; Selects the spread projectile art from the global animation phase
Projectile_Epsilon1AnimateSpreadProjectileState:        ; was: sub_47220
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                beq.s   Projectile_Epsilon1AnimateSpreadProjectileReturn
                cmpi.w  #1,d0
                beq.s   Projectile_Epsilon1UseSpreadProjectileFrame44F1
                cmpi.w  #2,d0
                beq.s   Projectile_Epsilon1UseSpreadProjectileFrame44F6
                move.w  #$44F7,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_Epsilon1UseSpreadProjectileFrame44F6:
                move.w  #$44F6,$E(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_Epsilon1UseSpreadProjectileFrame44F1:
                move.w  #$44F1,$E(a5)
Projectile_Epsilon1AnimateSpreadProjectileReturn:
                rts
; End of function Projectile_Epsilon1AnimateSpreadProjectileState
; Converts a spread projectile to type-$88 debris after it crosses the lower bound
Projectile_Epsilon1ConvertSpreadProjectileToDebris:     ; was: sub_4724E
                clr.b   $21(a5)
                move.l  #Effect_SpriteAnimation05,8(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                clr.l   $18(a5)
                move.w  $1C(a5),d0
                neg.w   d0
                asr.w   #1,d0
                move.w  d0,$1C(a5)
                move.w  (RandomNumberState).w,d0
                add.w   a5,d0
                andi.w  #7,d0
                subq.w  #4,d0
                add.w   d0,$18(a5)
                bsr.s   Projectile_Epsilon1ReleaseSpreadAimMarker
                tst.w   $5E(a5)
                bne.s   Projectile_Epsilon1ConvertSpreadProjectileToDebrisReturn
                addq.w  #2,(PlaneAShakeLevel).w
                tst.w   $5E(a5)
                bne.w   Projectile_Epsilon1ConvertSpreadProjectileToDebrisReturn
                move.b  #$E1,d0
                jsr     (Sound_QueueSFXRequest).l
Projectile_Epsilon1ConvertSpreadProjectileToDebrisReturn:
                                        ; Projectile_Epsilon1ConvertSpreadProjectileToDebris+42   j
                rts
; End of function Projectile_Epsilon1ConvertSpreadProjectileToDebris
; Marks an out-of-bounds spread projectile for removal and releases its aim marker
Projectile_Epsilon1MarkSpreadProjectileOutOfBounds:     ; was: sub_472A0
                                        ; Projectile_Epsilon1SpreadProjectileMain+2A   j
                move.w  #$1000,2(a5)
                bsr.s   Projectile_Epsilon1ReleaseSpreadAimMarker
Projectile_Epsilon1SpreadOrBarrageReturn:
                rts
; End of function Projectile_Epsilon1MarkSpreadProjectileOutOfBounds
; Signals the saved aim-marker entity, then clears the shared marker pointer
Projectile_Epsilon1ReleaseSpreadAimMarker:              ; was: sub_472AA
                                        ; Projectile_Epsilon1MarkSpreadProjectileOutOfBounds+6   p
                tst.w   (SharedScratchLong8).w
                beq.s   Projectile_Epsilon1ReleaseSpreadAimMarkerReturn
                movea.w (SharedScratchLong8).w,a0
                bset    #4,2(a0)
                clr.w   (SharedScratchLong8).w
Projectile_Epsilon1ReleaseSpreadAimMarkerReturn:
                rts
; End of function Projectile_Epsilon1ReleaseSpreadAimMarker
; Type-$2E8 barrage emitter reserved and activated by the Epsilon 1 ring controller
Projectile_Epsilon1BarrageEmitterMain:                  ; was: sub_472C0
                bsr.w   Projectile_Epsilon1ConvertOnGlobalMode
                move.w  4(a5),d0
                lea     Projectile_Epsilon1BarrageEmitterStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_Epsilon1BarrageEmitterMain
; ---------------------------------------------------------------------------
Projectile_Epsilon1BarrageEmitterStates:    dc.w    Projectile_Epsilon1InitializeBarrageEmitterDelayState-*
                dc.w    Projectile_Epsilon1WaitForBarrageEmitterDelayState-*
                dc.w    Projectile_Epsilon1EmitBarrageRowState-*
                dc.w    Projectile_Epsilon1BarrageEmitterRemovalDelayState-*

; Initializes the barrage-emitter startup delay
Projectile_Epsilon1InitializeBarrageEmitterDelayState:  ; was: sub_472D8
                move.w  #$20,$48(a5)                    ; ' '
                addq.w  #2,4(a5)
                rts
; End of function Projectile_Epsilon1InitializeBarrageEmitterDelayState
; Waits for the barrage-emitter startup delay
Projectile_Epsilon1WaitForBarrageEmitterDelayState:     ; was: sub_472E4
                subq.w  #1,$48(a5)
                bne.s   Projectile_Epsilon1WaitForBarrageEmitterDelayReturn
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
Projectile_Epsilon1WaitForBarrageEmitterDelayReturn:
                rts
; End of function Projectile_Epsilon1WaitForBarrageEmitterDelayState
; Emits a vertical row of eight type-$280 projectiles
Projectile_Epsilon1EmitBarrageRowState:                 ; was: sub_472F6
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_Epsilon1EmitBarrageRowReturn
                move.w  #7,d7
                move.w  #$60,d6                         ; '`'
                clr.w   d5
Projectile_Epsilon1EmitBarrageRowLoop:
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_Epsilon1FinishBarrageRowEmission
                bsr.s   Projectile_Epsilon1InitializeBarrageRowProjectile
                move.w  $10(a5),$10(a0)
                move.w  d6,$14(a0)
                move.w  d5,$5E(a0)
                addq.w  #1,d5
                subi.w  #$20,d6                         ; ' '
                dbf     d7,Projectile_Epsilon1EmitBarrageRowLoop
Projectile_Epsilon1FinishBarrageRowEmission:
                move.w  #$10,$48(a5)
                ori.w   #$8000,2(a5)
                addq.w  #2,4(a5)
                move.b  #$AB,d0
                jsr     (Sound_QueueSFXRequest).l
Projectile_Epsilon1EmitBarrageRowReturn:
                rts
; End of function Projectile_Epsilon1EmitBarrageRowState
; Initializes one barrage-row projectile
Projectile_Epsilon1InitializeBarrageRowProjectile:      ; was: sub_4734A
                move.w  #$280,(a0)
                move.w  #$8D80,2(a0)
                move.w  #$43D2,$E(a0)
                move.w  #$300,8(a0)
                move.w  #$FCF0,$A(a0)
                move.w  #$C,$1C(a0)
                move.w  #$14,$48(a0)
                rts
; End of function Projectile_Epsilon1InitializeBarrageRowProjectile
; Removes the barrage emitter after its post-emission delay
Projectile_Epsilon1BarrageEmitterRemovalDelayState:     ; was: sub_47374
                subq.w  #1,$48(a5)
                bne.s   Projectile_Epsilon1BarrageEmitterRemovalDelayReturn
                bset    #4,2(a5)
Projectile_Epsilon1BarrageEmitterRemovalDelayReturn:
                rts
; End of function Projectile_Epsilon1BarrageEmitterRemovalDelayState
; Type-$280 barrage-row projectile: delays, expands, then falls
Projectile_Epsilon1BarrageRowProjectileMain:            ; was: sub_47382
                cmpi.w  #$150,$14(a5)
                bgt.w   Projectile_Epsilon1ConvertBarrageRowProjectileToDebris
                move.w  4(a5),d0
                lea     Projectile_Epsilon1BarrageRowProjectileStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_Epsilon1BarrageRowProjectileMain
; ---------------------------------------------------------------------------
Projectile_Epsilon1BarrageRowProjectileStates:  dc.w    Projectile_Epsilon1BarrageRowLaunchDelayState-*
                dc.w    Projectile_Epsilon1AnimateBarrageRowExpansionState-*
                dc.w    Projectile_Epsilon1BarrageRowFlightState-*

; Waits before stopping the initial descent and enabling collision
Projectile_Epsilon1BarrageRowLaunchDelayState:          ; was: sub_4739E
                subq.w  #1,$48(a5)
                bne.s   Projectile_Epsilon1BarrageRowLaunchDelayReturn
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
                move.w  #4,$48(a5)
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #$F808F010,$2C(a5)
                move.w  #$C8,$26(a5)
Projectile_Epsilon1BarrageRowLaunchDelayReturn:
                rts
; End of function Projectile_Epsilon1BarrageRowLaunchDelayState
; Expands the barrage-row projectile through its nine-frame table
Projectile_Epsilon1AnimateBarrageRowExpansionState:     ; was: sub_473C8
                subq.w  #1,$48(a5)
                bne.s   Projectile_Epsilon1AnimateBarrageRowExpansionReturn
                move.w  #2,$48(a5)
                addq.w  #2,$5C(a5)
                cmpi.w  #$10,$5C(a5)
                bls.s   Projectile_Epsilon1ApplyBarrageRowExpansionFrame
                clr.b   $21(a5)
                move.w  #$10,$1C(a5)
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_Epsilon1ApplyBarrageRowExpansionFrame:
                move.w  $5C(a5),d0
                move.w  Projectile_Epsilon1BarrageRowFrameTileAttributes(pc,d0.w),$E(a5)
                move.w  Projectile_Epsilon1BarrageRowFrameWord8Values(pc,d0.w),8(a5)
                move.w  Projectile_Epsilon1BarrageRowFrameWordAValues(pc,d0.w),$A(a5)
Projectile_Epsilon1AnimateBarrageRowExpansionReturn:
                rts
; End of function Projectile_Epsilon1AnimateBarrageRowExpansionState
; ---------------------------------------------------------------------------
Projectile_Epsilon1BarrageRowFrameTileAttributes:   dc.w    $43D2, $43D6, $43DA, $43EA, $43E2, $43EA, $43DA, $43D6, $43D2
Projectile_Epsilon1BarrageRowFrameWord8Values:      dc.w    $300, $300, $700, $700, $700, $700, $700, $300, $300
Projectile_Epsilon1BarrageRowFrameWordAValues:      dc.w    $FCF0, $FCF0, $F8F0, $F8F0, $F8F0, $F8F0, $F8F0, $FCF0, $FCF0

Projectile_Epsilon1BarrageRowFlightState:
                rts
; End of function Projectile_Epsilon1BarrageRowFlightState

; Converts a barrage-row projectile to type-$88 debris below the playfield
Projectile_Epsilon1ConvertBarrageRowProjectileToDebris:  ; was: sub_47440
                move.l  #Effect_SpriteAnimation05,8(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                clr.l   $18(a5)
                move.w  $1C(a5),d0
                neg.w   d0
                asr.w   #1,d0
                move.w  d0,$1C(a5)
                move.w  (RandomNumberState).w,d0
                add.w   a5,d0
                andi.w  #7,d0
                subq.w  #4,d0
                add.w   d0,$18(a5)
                tst.w   $5E(a5)
                bne.s   Projectile_Epsilon1ConvertBarrageRowProjectileToDebrisReturn
                move.w  #2,(PlaneAShakeLevel).w
                move.b  #$E1,d0
                jsr     (Sound_QueueSFXRequest).l
Projectile_Epsilon1ConvertBarrageRowProjectileToDebrisReturn:
                rts
; End of function Projectile_Epsilon1ConvertBarrageRowProjectileToDebris
; Type-$284 fixed ring object created with the twelve-object Epsilon 1 ring
Boss_Epsilon1RingObjectMain:                            ; was: sub_47486
                btst    #0,(PrimaryEntityWork4C).w
                bne.s   Boss_Epsilon1ForceRingObjectDefeatHold
                btst    #2,(PrimaryEntityWork4C).w
                beq.s   Boss_Epsilon1DispatchRingObjectState
                clr.w   4(a5)
                bra.s   Boss_Epsilon1DeactivateRingObjectAndLink
; ---------------------------------------------------------------------------
Boss_Epsilon1ForceRingObjectDefeatHold:
                cmpi.w  #$C,4(a5)
                bcc.s   Boss_Epsilon1DispatchRingObjectState
                move.w  #$C,4(a5)
Boss_Epsilon1DeactivateRingObjectAndLink:
                andi.w  #$7FFF,2(a5)
                tst.w   $4E(a5)
                movea.w $4E(a5),a0
                beq.s   Boss_Epsilon1DispatchRingObjectState
                jsr     (Projectile_InitType88).l
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  2(a5),d0
                andi.w  #$8000,d0
                andi.w  #$7FFF,2(a0)
                or.w    d0,2(a0)
Boss_Epsilon1DispatchRingObjectState:
                                        ; Boss_Epsilon1RingObjectMain+1C   j
                move.w  4(a5),d0
                lea     Boss_Epsilon1RingObjectStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_Epsilon1RingObjectMain
; ---------------------------------------------------------------------------
Boss_Epsilon1RingObjectStates:  dc.w    Boss_Epsilon1RingObjectInactiveState-*
                dc.w    Boss_Epsilon1WaitForRingAngleThresholdState-*
                dc.w    Boss_Epsilon1WaitForRingLaunchWindowState-*
                dc.w    Boss_Epsilon1LaunchRingObjectState-*
                dc.w    Boss_Epsilon1UpdateReleasedRingObjectState-*
                dc.w    Boss_Epsilon1ResetReleasedRingObjectState-*
                dc.w    Boss_Epsilon1RingObjectDefeatHoldState-*
                dc.w    Boss_Epsilon1UpdateRingObjectDefeatFallState-*
                dc.w    Boss_Epsilon1ExplodeRingObjectState-*
                dc.w    Boss_Epsilon1DespawnRingObjectState-*

Boss_Epsilon1RingObjectInactiveState:
                rts
; End of function Boss_Epsilon1RingObjectInactiveState

; Waits for the assigned ring-angle sample to reach the first threshold
Boss_Epsilon1WaitForRingAngleThresholdState:            ; was: sub_47508
                move.w  $4A(a5),d0
                cmpi.w  #6,d0
                bcs.s   Boss_Epsilon1SelectRingAngleSample
                subq.w  #6,d0
Boss_Epsilon1SelectRingAngleSample:
                add.w   d0,d0
                lea     (SharedScratchLong0).w,a0
                move.w  (a0,d0.w),d1
                cmpi.w  #$80,d1
                bcs.s   Boss_Epsilon1WaitForRingAngleThresholdReturn
                move.w  #$80,d0
                bsr.w   Boss_Epsilon1StoreRingObjectPhaseValue
                addq.w  #2,4(a5)
Boss_Epsilon1WaitForRingAngleThresholdReturn:
                rts
; End of function Boss_Epsilon1WaitForRingAngleThresholdState
; Waits for the ring-angle launch window and creates the two side effects
Boss_Epsilon1WaitForRingLaunchWindowState:              ; was: sub_47532
                move.w  $4A(a5),d0
                cmpi.w  #6,d0
                bcs.s   Boss_Epsilon1SelectRingLaunchAngleSample
                subq.w  #6,d0
Boss_Epsilon1SelectRingLaunchAngleSample:
                add.w   d0,d0
                lea     (SharedScratchLong0).w,a0
                move.w  (a0,d0.w),d1
                cmpi.w  #$120,d1
                bcs.w   Boss_Epsilon1WaitForRingLaunchWindowReturn
                cmpi.w  #$180,d1
                bcc.w   Boss_Epsilon1WaitForRingLaunchWindowReturn
                move.w  #2,$48(a5)
                addq.w  #2,4(a5)
                bsr.w   Boss_Epsilon1PositionRingObjectFromSamples
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1WaitForRingLaunchWindowReturn
                jsr     (Sprite_InitType160).l
                move.l  #Effect_SpriteAnimation04,8(a0)
                move.w  #$480,$E(a0)
                move.w  $10(a5),$10(a0)
                addi.w  #8,$10(a0)
                move.w  $14(a5),$14(a0)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1WaitForRingLaunchWindowReturn
                jsr     (Sprite_InitType160).l
                move.l  #Effect_SpriteAnimation04,8(a0)
                move.w  #$480,$E(a0)
                move.w  $10(a5),$10(a0)
                addi.w  #-8,$10(a0)
                move.w  $14(a5),$14(a0)
Boss_Epsilon1WaitForRingLaunchWindowReturn:
                                        ; Boss_Epsilon1WaitForRingLaunchWindowState+22   j
                rts
; End of function Boss_Epsilon1WaitForRingLaunchWindowState
; Positions a fixed ring object from the shared center and vertical samples
Boss_Epsilon1PositionRingObjectFromSamples:             ; was: sub_475C4
                                        ; Boss_Epsilon1LaunchRingObjectState+6   p
                move.w  $4A(a5),d0
                add.w   d0,d0
                lea     (SharedScratchLong11).w,a1
                move.w  (a1,d0.w),d0
                move.w  (SecondaryEntityXPos).w,d0
                add.w   $4C(a5),d0
                move.w  d0,$10(a5)
                move.w  $4A(a5),d0
                add.w   d0,d0
                lea     (SharedScratchLong11).w,a0
                move.w  #$1E0,d1
                sub.w   (a0,d0.w),d1
                subi.w  #$20,d1                         ; ' '
                move.w  d1,$14(a5)
                rts
; End of function Boss_Epsilon1PositionRingObjectFromSamples
; Releases a ring object and synchronizes its linked projectile
Boss_Epsilon1LaunchRingObjectState:                     ; was: sub_475FA
                subq.w  #1,$48(a5)
                bne.s   Boss_Epsilon1LaunchRingObjectReturn
                bsr.w   Boss_Epsilon1PositionRingObjectFromSamples
                move.w  #9,$1C(a5)
                ori.w   #$8000,2(a5)
                move.b  #$40,$21(a5)                    ; '@'
                clr.w   $50(a5)
                movea.w $4E(a5),a0
                ori.w   #$8000,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                move.b  #$50,d0                         ; 'P'
                jsr     (Sound_QueueSFXRequest).l
Boss_Epsilon1LaunchRingObjectReturn:
                rts
; End of function Boss_Epsilon1LaunchRingObjectState
; Returns a released ring object to inactive state and removes its linked projectile
Boss_Epsilon1ResetRingObjectAndLinkedProjectile:
                movea.w $4E(a5),a0                      ; was: sub_47646
                bset    #4,2(a0)
                andi.w  #$7FFF,2(a5)
                clr.w   4(a5)
; End of function Boss_Epsilon1ResetRingObjectAndLinkedProjectile
; Clears this ring object's entry in the shared phase table
Boss_Epsilon1ClearRingObjectPhaseValue:                 ; was: sub_4765A
                moveq   #0,d0
; End of function Boss_Epsilon1ClearRingObjectPhaseValue
; Stores this ring object's value in the shared phase table
Boss_Epsilon1StoreRingObjectPhaseValue:                 ; was: sub_4765C
                                        ; Boss_Epsilon1UpdateReleasedRingObjectState+C   p
                lea     (Epsilon1RingPhaseTable).w,a1
                move.w  $4A(a5),d1
                add.w   d1,d1
                move.w  d0,(a1,d1.w)
                rts
; End of function Boss_Epsilon1StoreRingObjectPhaseValue
; Advances a released ring object and keeps its linked projectile aligned
Boss_Epsilon1UpdateReleasedRingObjectState:             ; was: sub_4766C
                cmpi.w  #$120,$48(a5)
                beq.s   Boss_Epsilon1AdvanceReleasedRingObjectLinkOffset
                move.w  $48(a5),d0
                bsr.w   Boss_Epsilon1StoreRingObjectPhaseValue
                addi.w  #$10,$48(a5)
Boss_Epsilon1AdvanceReleasedRingObjectLinkOffset:
                cmpi.w  #$20,$50(a5)                    ; ' '
                beq.s   Boss_Epsilon1PositionReleasedRingObjectLink
                addq.w  #4,$50(a5)
Boss_Epsilon1PositionReleasedRingObjectLink:
                movea.w $4E(a5),a0
                ori.w   #$8000,2(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  $50(a5),d0
                sub.w   d0,$14(a0)
                cmpi.w  #$150,$14(a5)
                bcs.w   Boss_Epsilon1UpdateReleasedRingObjectReturn
                andi.w  #$7FFF,2(a5)
                clr.b   $21(a5)
                movea.w $4E(a5),a0
                jsr     (Projectile_InitType88).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.w  $1C(a5),d0
                neg.w   d0
                asr.w   #2,d0
                move.w  d0,$1C(a0)
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
Boss_Epsilon1UpdateReleasedRingObjectReturn:
                rts
; End of function Boss_Epsilon1UpdateReleasedRingObjectState
; Clears the ring object's phase entry and returns it to inactive state
Boss_Epsilon1ResetReleasedRingObjectState:              ; was: sub_476F4
                bsr.w   Boss_Epsilon1ClearRingObjectPhaseValue
                clr.w   4(a5)
                rts
; End of function Boss_Epsilon1ResetReleasedRingObjectState
Boss_Epsilon1RingObjectDefeatHoldState:
                rts
; End of function Boss_Epsilon1RingObjectDefeatHoldState

; Advances a defeated ring object and periodically emits type-$88 debris
Boss_Epsilon1UpdateRingObjectDefeatFallState:           ; was: sub_47700
                bsr.s   Boss_Epsilon1AdvanceRingObjectDefeatPosition
                cmpi.w  #$140,$14(a5)
                blt.s   Boss_Epsilon1SpawnRingObjectDefeatDebris
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_Epsilon1SpawnRingObjectDefeatDebris:
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_Epsilon1UpdateRingObjectDefeatFallReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_Epsilon1UpdateRingObjectDefeatFallReturn
                jsr     (Projectile_InitType88).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$FFFE,$1C(a0)
                move.w  (RandomNumberState).w,d0
                add.w   a5,d0
                andi.w  #3,d0
                subq.w  #2,d0
                move.w  d0,$18(a0)
                move.l  #Effect_SpriteAnimation05,8(a0)
Boss_Epsilon1UpdateRingObjectDefeatFallReturn:
                                        ; Boss_Epsilon1UpdateRingObjectDefeatFallState+20   j
                rts
; End of function Boss_Epsilon1UpdateRingObjectDefeatFallState
; Updates a defeated ring object's sampled position and shared offset slot
Boss_Epsilon1AdvanceRingObjectDefeatPosition:           ; was: sub_47754
                addi.w  #$20,$50(a5)                    ; ' '
                move.w  $50(a5),d0
                bsr.w   Boss_Epsilon1StoreRingObjectPhaseValue
                move.w  (SecondaryEntityXPos).w,d0
                add.w   $4C(a5),d0
                move.w  d0,$10(a5)
                move.w  $4A(a5),d0
                add.w   d0,d0
                lea     (SharedScratchLong11).w,a0
                move.w  #$1E0,d1
                sub.w   (a0,d0.w),d1
                subi.w  #$20,d1                         ; ' '
                move.w  d1,$14(a5)
                cmpi.w  #$C,d0
                bcs.s   Boss_Epsilon1SelectRingObjectDefeatOffsetSlot
                subi.w  #$C,d0
Boss_Epsilon1SelectRingObjectDefeatOffsetSlot:
                lea     (Epsilon1RowOffsetTable).w,a1
                addi.w  #-2,(a1,d0.w)
                rts
; End of function Boss_Epsilon1AdvanceRingObjectDefeatPosition
; Explodes a defeated ring object and converts it to type-$88 debris
Boss_Epsilon1ExplodeRingObjectState:                    ; was: sub_4779E
                jsr     (Effect_SpawnExplosionA).l
                move.w  $4A(a5),d0
                add.w   d0,d0
                lea     (Epsilon1RowOffsetTable).w,a1
                move.w  #$FF00,(a1,d0.w)
                addq.w  #2,4(a5)
                move.l  #Effect_SpriteAnimation00,8(a5)
                move.w  #$FFFF,$1C(a5)
                jmp     Projectile_InitType88FromCurrent
; End of function Boss_Epsilon1ExplodeRingObjectState
Boss_Epsilon1RingObjectStandaloneReturn:
                rts
; End of function Boss_Epsilon1RingObjectStandaloneReturn

; Despawns a ring object and clears its active flag
Boss_Epsilon1DespawnRingObjectState:                    ; was: sub_477CE
                clr.w   (a5)
                bclr    #4,2(a5)
                rts
; End of function Boss_Epsilon1DespawnRingObjectState
