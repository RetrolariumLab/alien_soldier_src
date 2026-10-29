Segment_MissirayMain:                                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_54458
                move.b  $50(a5),d0
                andi.w  #3,d0
                add.w   d0,d0
                move.w  d0,d0
                lea     Segment_MissirayModeStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Segment_MissirayMain
; ---------------------------------------------------------------------------
Segment_MissirayModeStates: dc.w    Segment_MissirayProjectileAttackDispatcher-*  ; DATA XREF: Segment_MissirayMain+C   o  ; was: off_5446C
                dc.w    Segment_MissirayOffsetTransitionDispatcher-*
                dc.w    Segment_MissirayDefeatDispatcher-*

; Dispatches the mode-one segment offset transition
Segment_MissirayOffsetTransitionDispatcher:             ; DATA XREF: ROM:0005446E   o  ; was: sub_54472
                move.w  4(a5),d0
                lea     Segment_MissirayOffsetTransitionStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Segment_MissirayOffsetTransitionDispatcher
; ---------------------------------------------------------------------------
Segment_MissirayOffsetTransitionStates: dc.w    Segment_MissirayInitializeOffsetTransition-*  ; DATA XREF: Segment_MissirayOffsetTransitionDispatcher+4   o  ; was: off_5447E
                dc.w    Segment_MissirayAdvanceOffsetArc-*
                dc.w    Segment_MissirayMoveOffsetToTarget-*

; Clears the segment busy byte while the offset transition is idle
Segment_MissirayInitializeOffsetTransition:             ; DATA XREF: ROM:Segment_MissirayOffsetTransitionStates   o  ; was: sub_54484
                clr.b   $52(a5)
                rts
; End of function Segment_MissirayInitializeOffsetTransition
; Advances the sine-derived offset arc and enters target movement at its end
Segment_MissirayAdvanceOffsetArc:                       ; DATA XREF: ROM:00054480   o  ; was: sub_5448A
                move.b  #1,$52(a5)
                cmpi.w  #$10,(PrimaryEntityState).w
                bcs.s   Segment_MissirayFinishOffsetArc
                addi.w  #$10,$48(a5)
                move.w  #$40,d0                         ; '@'
                bsr.w   Segment_MissirayCalculateSineOffset
                andi.w  #$3F0,$48(a5)
                cmpi.w  #$200,$48(a5)
                bne.s   Segment_MissirayOffsetArcReturn
Segment_MissirayFinishOffsetArc:                        ; CODE XREF: Segment_MissirayAdvanceOffsetArc+C   j  ; was: loc_544B4
                bset    #6,$21(a5)
                addq.w  #2,4(a5)
                move.b  #$57,d0                         ; 'W'
                jsr     (Sound_QueueSFXRequest).l
Segment_MissirayOffsetArcReturn:                        ; CODE XREF: Segment_MissirayAdvanceOffsetArc+28   j  ; was: locret_544C8
                rts
; End of function Segment_MissirayAdvanceOffsetArc
; Steps the current segment offset toward its mode-selected target
Segment_MissirayMoveOffsetToTarget:                     ; DATA XREF: ROM:00054482   o  ; was: sub_544CA
                bsr.s   Segment_MissirayStepOffsetTowardTarget
                cmpi.w  #$10,(PrimaryEntityState).w
                bcs.s   Segment_MissirayCheckOffsetTargetReached
                bsr.s   Segment_MissirayStepOffsetTowardTarget
                bsr.s   Segment_MissirayStepOffsetTowardTarget
                bsr.s   Segment_MissirayStepOffsetTowardTarget
Segment_MissirayCheckOffsetTargetReached:               ; CODE XREF: Segment_MissirayMoveOffsetToTarget+8   j  ; was: loc_544DA
                move.w  $4C(a5),d0
                cmp.w   $4E(a5),d0
                bne.s   Segment_MissirayMoveOffsetToTargetReturn
                bclr    #6,$21(a5)
                clr.w   $4E(a5)
                clr.w   4(a5)
Segment_MissirayMoveOffsetToTargetReturn:               ; CODE XREF: Segment_MissirayMoveOffsetToTarget+18   j  ; was: locret_544F2
                rts
; End of function Segment_MissirayMoveOffsetToTarget
; Moves field $4C by one unit toward target field $4E
Segment_MissirayStepOffsetTowardTarget:                 ; CODE XREF: Segment_MissirayMoveOffsetToTarget   p  ; was: sub_544F4
                                        ; Segment_MissirayMoveOffsetToTarget+A   p
                move.w  $4E(a5),d0
                sub.w   $4C(a5),d0
                beq.s   Segment_MissirayStepOffsetTowardTargetReturn
                tst.w   d0
                bpl.s   Segment_MissirayIncrementOffsetTowardTarget
                subq.w  #1,$4C(a5)
                rts
; ---------------------------------------------------------------------------
Segment_MissirayIncrementOffsetTowardTarget:            ; CODE XREF: Segment_MissirayStepOffsetTowardTarget+C   j  ; was: loc_54508
                addq.w  #1,$4C(a5)
Segment_MissirayStepOffsetTowardTargetReturn:           ; CODE XREF: Segment_MissirayStepOffsetTowardTarget+8   j  ; was: locret_5450C
                rts
; End of function Segment_MissirayStepOffsetTowardTarget
; Advances the 15-entry palette-wave index used by Missiray fades
Boss_MissirayAdvancePaletteWaveIndex:                   ; CODE XREF: Boss_MissirayShuffleSegmentActivationOrder   p  ; was: sub_5450E
                                        ; Boss_MissirayActivateNextShuffledSegment   p
                addq.w  #2,(SharedScratchLong4).w
                cmpi.w  #$1E,(SharedScratchLong4).w
                bne.s   Boss_MissirayStorePaletteWaveIndex
                clr.w   (SharedScratchLong4).w
Boss_MissirayStorePaletteWaveIndex:                     ; CODE XREF: Boss_MissirayAdvancePaletteWaveIndex+A   j  ; was: loc_5451E
                move.w  (SharedScratchLong4).w,d0
                move.w  Boss_MissirayPaletteWaveIndices(pc,d0.w),(SharedScratchLong3+2).w
; End of function Boss_MissirayAdvancePaletteWaveIndex
; Applies one Missiray palette step to the 15-color range at PaletteActiveColor48
Boss_MissirayApplyPaletteFadeStep:                      ; CODE XREF: Boss_MissirayInitializeSequentialSegmentAttack:Boss_MissirayFadeAndInitializeSegmentOrder   p  ; was: sub_54528
                                        ; Boss_MissirayFadePrimaryModePalette   p
                move.w  (SharedScratchLong3+2).w,d0
                andi.w  #$E,d0
                move.w  #$F,d5
                lea     (PaletteActiveColor48).w,a0
                move.w  (SharedScratchLong4+2).w,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function Boss_MissirayApplyPaletteFadeStep
; ---------------------------------------------------------------------------
Boss_MissirayPaletteWaveIndices:    dc.w    $E, $C, $A, 8, 6, 4, 2, 0, 2, 4, 6, 8, $A, $C, $E  ; was: word_54542
                                        ; DATA XREF: Boss_MissirayAdvancePaletteWaveIndex+14   r

; Dispatches the ordinary segment projectile sequence
Segment_MissirayProjectileAttackDispatcher:             ; DATA XREF: ROM:Segment_MissirayModeStates   o  ; was: sub_54560
                move.w  4(a5),d0
                lea     Segment_MissirayProjectileAttackStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Segment_MissirayProjectileAttackDispatcher
; ---------------------------------------------------------------------------
Segment_MissirayProjectileAttackStates: dc.w    Segment_MissirayProjectileAttackIdle-*  ; DATA XREF: Segment_MissirayProjectileAttackDispatcher+4   o  ; was: off_5456C
                dc.w    Segment_MissirayLaunchConfiguredProjectile-*
                dc.w    Segment_MissirayAdvanceLargeOffsetArc-*
                dc.w    Segment_MissirayAdvanceSmallOffsetArc-*
                dc.w    Segment_MissirayWaitBeforeProjectileAttackReset-*

; Publishes that the projectile sequence is idle
Segment_MissirayProjectileAttackIdle:                   ; DATA XREF: ROM:Segment_MissirayProjectileAttackStates   o  ; was: sub_54576
                clr.b   $52(a5)
                rts
; End of function Segment_MissirayProjectileAttackIdle
; Waits for the configured delay and initializes the reserved projectile
Segment_MissirayLaunchConfiguredProjectile:             ; DATA XREF: ROM:0005456E   o  ; was: sub_5457C
                move.b  #1,$52(a5)
                subq.w  #1,$48(a5)
                bpl.s   Segment_MissirayLaunchConfiguredProjectileReturn
                clr.w   $48(a5)
                addq.w  #2,4(a5)
                cmpi.b  #1,$51(a5)
                beq.s   Segment_MissirayLaunchAlternateProjectile
                movea.w $54(a5),a0
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                move.l  #$FFFF0000,d2
                move.l  #$FFFFE000,d3
                jsr     (Projectile_InitMissirayFallingShot).l
                rts
; ---------------------------------------------------------------------------
Segment_MissirayLaunchAlternateProjectile:              ; CODE XREF: Segment_MissirayLaunchConfiguredProjectile+1A   j  ; was: loc_545B8
                movea.w $54(a5),a0
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                move.l  #$2800,d2
                move.l  #$1000,d3
                jsr     (Projectile_InitMissirayBullet).l
Segment_MissirayLaunchConfiguredProjectileReturn:       ; CODE XREF: Segment_MissirayLaunchConfiguredProjectile+A   j  ; was: locret_545D6
                rts
; End of function Segment_MissirayLaunchConfiguredProjectile
; Advances the first sine-offset arc with amplitude $40
Segment_MissirayAdvanceLargeOffsetArc:                  ; DATA XREF: ROM:00054570   o  ; was: sub_545D8
                addi.w  #$10,$48(a5)
                move.w  #$40,d0                         ; '@'
                bsr.w   Segment_MissirayCalculateSineOffset
                andi.w  #$1F0,$48(a5)
                cmpi.w  #$100,$48(a5)
                bne.s   Segment_MissirayLargeOffsetArcReturn
                addq.w  #2,4(a5)
Segment_MissirayLargeOffsetArcReturn:                   ; CODE XREF: Segment_MissirayAdvanceLargeOffsetArc+1A   j  ; was: locret_545F8
                rts
; End of function Segment_MissirayAdvanceLargeOffsetArc
; Samples the sine table, scales it by d0, and stores the segment offset
Segment_MissirayCalculateSineOffset:                    ; CODE XREF: Segment_MissirayAdvanceOffsetArc+18   p  ; was: sub_545FA
                                        ; Segment_MissirayAdvanceLargeOffsetArc+A   p
                move.w  $48(a5),d1
                andi.w  #$1FE,d1
                lea     (Math_SineTable).l,a3
                move.w  Math_QuarterSineTable-Math_SineTable(a3,d1.w),d1
                muls.w  d0,d1
                swap    d1
                move.w  d1,$4C(a5)
                rts
; End of function Segment_MissirayCalculateSineOffset
; Advances the second sine-offset arc with amplitude $20
Segment_MissirayAdvanceSmallOffsetArc:                  ; DATA XREF: ROM:00054572   o  ; was: sub_54616
                addi.w  #$10,$48(a5)
                move.w  #$20,d0                         ; ' '
                bsr.w   Segment_MissirayCalculateSineOffset
                andi.w  #$1F0,$48(a5)
                cmpi.w  #0,$48(a5)
                bne.s   Segment_MissiraySmallOffsetArcReturn
                move.w  #$40,$48(a5)                    ; '@'
                addq.w  #2,4(a5)
Segment_MissiraySmallOffsetArcReturn:                   ; CODE XREF: Segment_MissirayAdvanceSmallOffsetArc+1A   j  ; was: locret_5463C
                rts
; End of function Segment_MissirayAdvanceSmallOffsetArc
; Holds the completed projectile sequence for $40 ticks before resetting
Segment_MissirayWaitBeforeProjectileAttackReset:        ; DATA XREF: ROM:00054574   o  ; was: sub_5463E
                subq.w  #1,$48(a5)
                bne.s   Segment_MissirayProjectileAttackResetWaitReturn
                clr.w   4(a5)
Segment_MissirayProjectileAttackResetWaitReturn:        ; CODE XREF: Segment_MissirayWaitBeforeProjectileAttackReset+4   j  ; was: locret_54648
                rts
; End of function Segment_MissirayWaitBeforeProjectileAttackReset
; Dispatches linked-segment defeat behavior
Segment_MissirayDefeatDispatcher:                       ; DATA XREF: ROM:00054470   o  ; was: sub_5464A
                move.w  4(a5),d0
                lea     Segment_MissirayDefeatStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Segment_MissirayDefeatDispatcher
; ---------------------------------------------------------------------------
Segment_MissirayDefeatStates:   dc.w    Segment_MissirayWaitForDefeatLaunch-*  ; DATA XREF: Segment_MissirayDefeatDispatcher+4   o  ; was: off_54656
                dc.w    Segment_MissirayUpdateDefeatFlight-*
                dc.w    Segment_MissirayDefeatNoOpState-*

; Waits for the per-segment defeat timer and optional shared motion gate
Segment_MissirayWaitForDefeatLaunch:                    ; DATA XREF: ROM:Segment_MissirayDefeatStates   o  ; was: sub_5465C
                subq.w  #1,$48(a5)
                bne.s   Segment_MissirayDefeatLaunchWaitReturn
                addq.w  #2,4(a5)
                tst.w   (SharedScratchLong1).w
                bne.s   Segment_MissirayDefeatLaunchWaitReturn
                tst.w   (SharedScratchLong2+2).w
                bne.s   Segment_MissirayDefeatLaunchWaitReturn
                move.l  #$FFFC0000,$1C(a5)
Segment_MissirayDefeatLaunchWaitReturn:                 ; CODE XREF: Segment_MissirayWaitForDefeatLaunch+4   j  ; was: locret_5467A
                                        ; Segment_MissirayWaitForDefeatLaunch+E   j
                rts
; End of function Segment_MissirayWaitForDefeatLaunch
; Integrates defeat velocity, emits particles, and retires below Y $180
Segment_MissirayUpdateDefeatFlight:                     ; DATA XREF: ROM:00054658   o  ; was: sub_5467C
                addi.l  #$1000,$1C(a5)
                cmpi.w  #$180,$14(a5)
                bgt.s   Segment_MissirayRetireAfterDefeatFlight
                subq.w  #1,$48(a5)
                bpl.s   Segment_MissirayDefeatFlightReturn
                bsr.w   Segment_MissiraySpawnDefeatParticle
                move.w  #6,$48(a5)
Segment_MissirayDefeatFlightReturn:                     ; CODE XREF: Segment_MissirayUpdateDefeatFlight+14   j  ; was: locret_5469C
                rts
; ---------------------------------------------------------------------------
Segment_MissirayRetireAfterDefeatFlight:                ; CODE XREF: Segment_MissirayUpdateDefeatFlight+E   j  ; was: loc_5469E
                move.w  #$1000,2(a5)
                rts
; End of function Segment_MissirayUpdateDefeatFlight
; Spawns a type-$160 defeat particle with a random animation pointer
Segment_MissiraySpawnDefeatParticle:                    ; CODE XREF: Segment_MissirayUpdateDefeatFlight+16   p  ; was: sub_546A6
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Segment_MissiraySpawnDefeatParticleReturn
                jsr     (RandomNumber).l
                jsr     (Sprite_InitType160).l
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                lsl.w   #2,d0
                move.l  Segment_MissirayDefeatParticleAnimations(pc,d0.w),8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                ori.w   #$8000,$E(a0)
Segment_MissiraySpawnDefeatParticleReturn:              ; CODE XREF: Segment_MissiraySpawnDefeatParticle+6   j  ; was: locret_546DC
                rts
; End of function Segment_MissiraySpawnDefeatParticle
; ---------------------------------------------------------------------------
Segment_MissirayDefeatParticleAnimations:   dc.l    SharedCombatSpriteAnimation00  ; DATA XREF: Segment_MissiraySpawnDefeatParticle+1E   r  ; was: off_546DE
                dc.l    SharedCombatSpriteAnimation03
                dc.l    SharedCombatSpriteAnimation05
                dc.l    SharedCombatSpriteAnimation18
                dc.l    SharedCombatSpriteAnimation00
                dc.l    SharedCombatSpriteAnimation19
                dc.l    SharedCombatSpriteAnimation05
                dc.l    SharedCombatSpriteAnimation20

Segment_MissirayDefeatNoOpState:                        ; DATA XREF: ROM:0005465A   o  ; was: nullsub_125
                rts
; End of function Segment_MissirayDefeatNoOpState

; Unreferenced helper that adjusts object Y while input modifier bit 6 is held
Orphaned_AdjustObjectVerticalPositionFromInput:
                btst    #6,(ControllerHeldState).w      ; was: sub_54700
                beq.s   Orphaned_ObjectVerticalPositionAdjustmentReturn
                btst    #0,(ControllerHeldState).w
                beq.s   Orphaned_CheckObjectVerticalPositionIncreaseInput
                subq.w  #2,$14(a5)
                move.w  $14(a5),$4E(a5)
Orphaned_CheckObjectVerticalPositionIncreaseInput:      ; CODE XREF: Orphaned_AdjustObjectVerticalPositionFromInput+E   j  ; was: loc_5471A
                btst    #1,(ControllerHeldState).w
                beq.s   Orphaned_ObjectVerticalPositionAdjustmentReturn
                addq.w  #2,$14(a5)
                move.w  $14(a5),$4E(a5)
Orphaned_ObjectVerticalPositionAdjustmentReturn:        ; CODE XREF: Orphaned_AdjustObjectVerticalPositionFromInput+6   j  ; was: locret_5472C
                                        ; Orphaned_AdjustObjectVerticalPositionFromInput+20   j
                rts
; End of function Orphaned_AdjustObjectVerticalPositionFromInput
; Advances a proximity-gated cooldown and spawns a pair of attached shots
Boss_MissirayTrySpawnProximityShotPair:                 ; CODE XREF: Boss_MissirayRunSelectedAttack   p  ; was: sub_5472E
                tst.w   (SharedScratchLong2+2).w
                bne.w   Boss_MissirayProximityShotPairReturn
                tst.w   (SharedScratchLong3).w
                bmi.s   Boss_MissirayPrepareProximityShotPair
                jsr     (Physics_GetPlayerDelta).l
                move.w  #$20,d1                         ; ' '
                tst.w   (DifficultyMode).w
                beq.s   Boss_MissirayCheckProximityThreshold
                add.w   d1,d1
Boss_MissirayCheckProximityThreshold:                   ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+1C   j  ; was: loc_5474E
                cmp.w   d1,d0
                bhi.w   Boss_MissirayProximityShotPairReturn
                subq.w  #1,(SharedScratchLong3).w
                rts
; ---------------------------------------------------------------------------
Boss_MissirayPrepareProximityShotPair:                  ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+C   j  ; was: loc_5475A
                tst.w   (SharedScratchLong1).w
                beq.s   Boss_MissirayUseLongProximityShotCooldown
                move.w  #$40,(SharedScratchLong3).w     ; '@'
                bra.s   Boss_MissirayConfigureFirstProximityShot
; ---------------------------------------------------------------------------
Boss_MissirayUseLongProximityShotCooldown:              ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+30   j  ; was: loc_54768
                move.w  #$80,(SharedScratchLong3).w
Boss_MissirayConfigureFirstProximityShot:               ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+38   j  ; was: loc_5476E
                move.w  #$C,d5
                add.w   $10(a5),d5
                move.l  #$F010F804,d3
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_MissirayConfigureAlternateFirstShotOffset
                move.w  #$FFE0,d6
                add.w   $14(a5),d6
                move.w  #$18,d4
                bra.s   Boss_MissiraySpawnFirstAndConfigureSecondShot
; ---------------------------------------------------------------------------
Boss_MissirayConfigureAlternateFirstShotOffset:         ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+52   j  ; was: loc_54790
                move.w  #$20,d6                         ; ' '
                add.w   $14(a5),d6
                move.w  #8,d4
Boss_MissiraySpawnFirstAndConfigureSecondShot:          ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+60   j  ; was: loc_5479C
                jsr     Boss_MissiraySpawnAttachedProximityShot(pc)  ; (pc)
                nop
                move.w  #$FFF4,d5
                add.w   $10(a5),d5
                move.l  #$F010FC08,d3
                tst.w   (SharedScratchLong1).w
                bne.s   Boss_MissirayConfigureAlternateSecondShotOffset
                move.w  #$FFE0,d6
                add.w   $14(a5),d6
                move.w  #$18,d4
                bra.s   Boss_MissiraySpawnSecondProximityShot
; ---------------------------------------------------------------------------
Boss_MissirayConfigureAlternateSecondShotOffset:        ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+86   j  ; was: loc_547C4
                move.w  #$20,d6                         ; ' '
                add.w   $14(a5),d6
                move.w  #8,d4
Boss_MissiraySpawnSecondProximityShot:                  ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+94   j  ; was: loc_547D0
                jsr     Boss_MissiraySpawnAttachedProximityShot(pc)  ; (pc)
                nop
Boss_MissirayProximityShotPairReturn:                   ; CODE XREF: Boss_MissirayTrySpawnProximityShotPair+4   j  ; was: locret_547D6
                                        ; Boss_MissirayTrySpawnProximityShotPair+22   j
                rts
; End of function Boss_MissirayTrySpawnProximityShotPair
; Allocates one type-$404 shot attached to Missiray for its initial delay
Boss_MissiraySpawnAttachedProximityShot:                ; CODE XREF: Boss_MissiraySpawnFirstAndConfigureSecondShot   p  ; was: sub_547D8
                                        ; Boss_MissiraySpawnSecondProximityShot   p
                                        ; DATA XREF:
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_MissiraySpawnAttachedProximityShotReturn
                move.w  #$404,(a0)
                move.w  #$EC00,2(a0)
                move.l  #SharedCombatSpriteAnimation12,8(a0)
                move.w  #$8480,$E(a0)
                move.w  d5,$10(a0)
                move.w  d6,$14(a0)
                clr.w   4(a0)
                move.w  #$20,$46(a0)                    ; ' '
                sub.w   $10(a5),d5
                move.w  d5,$4A(a0)
                sub.w   $14(a5),d6
                move.w  d6,$4C(a0)
                move.w  d4,$50(a0)
                move.l  d3,$54(a0)
                move.w  a5,$48(a0)
                move.b  #$CE,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_MissiraySpawnAttachedProximityShotReturn:          ; CODE XREF: Boss_MissiraySpawnAttachedProximityShot+6   j  ; was: locret_54830
                rts
; End of function Boss_MissiraySpawnAttachedProximityShot
; Dispatches the two proximity-shot states
Projectile_MissirayProximityShotMain:                   ; DATA XREF: ROM:Entity_UpdateHandlerTable   o  ; was: sub_54832
                move.w  4(a5),d0
                lea     Projectile_MissirayProximityShotStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_MissirayProximityShotMain
; ---------------------------------------------------------------------------
Projectile_MissirayProximityShotStates: dc.w    Projectile_MissirayProximityShotTrackOwnerAndLaunch-*  ; DATA XREF: Projectile_MissirayProximityShotMain+4   o  ; was: off_5483E
                dc.w    Projectile_MissirayProximityShotAccelerateVertically-*

; Tracks the owner for $20 ticks, then replaces the anchor with a moving shot
Projectile_MissirayProximityShotTrackOwnerAndLaunch:    ; DATA XREF: ROM:Projectile_MissirayProximityShotStates   o  ; was: sub_54842
                movea.w $48(a5),a4
                move.w  $10(a4),d0
                add.w   $4A(a5),d0
                move.w  d0,$10(a5)
                move.w  $14(a4),d0
                add.w   $4C(a5),d0
                move.w  d0,$14(a5)
                subq.w  #1,$46(a5)
                bne.s   Projectile_MissirayProximityShotTrackReturn
                move.w  #$1000,2(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_MissirayProximityShotTrackReturn
                move.w  #$404,(a0)
                move.w  #$8E00,2(a0)
                move.w  #2,4(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$4344,$E(a0)
                move.w  #$300,8(a0)
                move.w  #$FCF0,$A(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.l  $54(a5),$2C(a0)
                move.w  #$96,$26(a0)
                cmpi.w  #$18,$50(a5)
                beq.s   Projectile_MissirayProximityShotUseAlternateMotion
                move.l  #$4650,$1C(a0)
                move.l  #$2000,$48(a0)
                ori.w   #$1000,$E(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_MissirayProximityShotUseAlternateMotion:     ; CODE XREF: Projectile_MissirayProximityShotTrackOwnerAndLaunch+76   j  ; was: loc_548D2
                move.l  #$FFFFB9B0,$1C(a0)
                move.l  #$FFFFE000,$48(a0)
Projectile_MissirayProximityShotTrackReturn:            ; CODE XREF: Projectile_MissirayProximityShotTrackOwnerAndLaunch+20   j  ; was: locret_548E2
                                        ; Projectile_MissirayProximityShotTrackOwnerAndLaunch+2E   j
                rts
; End of function Projectile_MissirayProximityShotTrackOwnerAndLaunch
; Adds the configured acceleration to vertical velocity
Projectile_MissirayProximityShotAccelerateVertically:   ; DATA XREF: ROM:00054840   o  ; was: sub_548E4
                move.l  $48(a5),d0
                add.l   d0,$1C(a5)
                rts
; End of function Projectile_MissirayProximityShotAccelerateVertically
; Initializes 9 sub-entities at offset $360 with sprite and tile data
