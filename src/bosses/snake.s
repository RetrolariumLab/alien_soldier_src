; REVIEWED VIS-002: pinned TAS frame 28000 shows Snake head type $298; see docs/unknowns.md
Boss_SnakeMain:                                         ; was: sub_4079E
                tst.w   4(a5)
                beq.w   Boss_SnakeStateDispatch
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$4E(a5)
                btst    #1,$4C(a5)
                bne.s   Boss_SnakeUpdateBody
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_SnakeUpdateBody
                tst.w   (BossHealth).w
                bne.s   Boss_SnakeUpdateBody
                move.b  #2,(BossColorEffectFlags).w
                move.w  #$A,4(a5)
Boss_SnakeUpdateBody:                                   ; was: loc_407D4
                                        ; Boss_SnakeMain+22   j
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  $10(a5),d0
                add.w   (PrimaryCameraXPosition).w,d0
                swap    d0
                move.w  $14(a5),d0
                lea     (SharedScratchLong8).w,a0
                move.w  #$16,d7
Boss_SnakeShiftTrailRowLoop:                            ; was: loc_407F0
                move.w  (SharedScratchLong3+2).w,d6
                subq.w  #1,d6
Boss_SnakeShiftTrailSampleLoop:                         ; was: loc_407F6
                move.l  (a0),d1
                move.l  d0,(a0)+
                move.l  d1,d0
                dbf     d6,Boss_SnakeShiftTrailSampleLoop
                dbf     d7,Boss_SnakeShiftTrailRowLoop
                move.w  #$16,d7
                lea     $60(a5),a0
                lea     (SharedScratchLong8).w,a1
                move.w  (SharedScratchLong3+2).w,d6
                add.w   d6,d6
                add.w   d6,d6
Boss_SnakePlaceSegmentLoop:                             ; was: loc_40818
                lea     (a1,d6.w),a1
                move.w  (a1),d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a0)
                move.w  2(a1),$14(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_SnakePlaceSegmentLoop
                bsr.w   Boss_SnakeAdvanceAnimation
; State machine dispatcher for Snake boss
Boss_SnakeStateDispatch:                                ; was: loc_40838
                move.w  4(a5),d0
                lea     Boss_SnakeStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_SnakeMain
; ---------------------------------------------------------------------------
Boss_SnakeStates:   dc.w    Boss_SnakeInit-*            ; was: off_40844
                dc.w    Boss_SnakeBeginEncounterState-*
                dc.w    Boss_SnakeBattleState-*
                dc.w    Boss_SnakeDepartureArcState-*
                dc.w    Boss_SnakeExitDownwardState-*
                dc.w    Boss_SnakeBeginDefeatState-*
                dc.w    Boss_SnakeDestroySegmentsState-*
                dc.w    Boss_SnakeInactiveState-*

; Initializes Snake boss with 23 segments
Boss_SnakeInit:                                         ; was: sub_40854
                tst.b   (DataLoaderControl).w
                bmi.w   Boss_SnakeInitReturn
                addq.w  #2,4(a5)
                move.b  #4,(PlayerOAMBucketOffset).w
                move.w  #4,(SharedScratchLong3+2).w
                move.w  #$10,(SharedScratchLong2+2).w
                move.w  #$10,(SharedScratchLong3).w
                move.w  #$4000,(BossMaxHealth).w
                move.w  #$4000,(BossHealth).w
                move.w  #$E300,$E(a5)
                move.w  #$CD00,2(a5)
                move.l  #Sprite_SharedGraphicsFrameTable,8(a5)
                clr.w   $C(a5)
                clr.w   $54(a5)
                move.b  #$10,$20(a5)
                move.b  #$50,$21(a5)                    ; 'P'
                move.l  #$FE02FE02,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$28,$24(a5)                    ; '('
                move.w  #$80,$26(a5)
                move.b  #6,(BossColorEffectFlags).w
                move.b  #$80,$23(a5)
                move.w  #$16,d7
                clr.w   d6
                lea     $60(a5),a0
Boss_SnakeSetupSegmentLoop:                             ; was: loc_408DE
                move.w  #$29C,(a0)
                move.l  #Sprite_SharedGraphicsFrameTable,8(a0)
                clr.w   $C(a0)
                move.w  #$E300,$E(a0)
                move.w  #$CD00,2(a0)
                move.w  #$80,$26(a0)
                move.b  #$10,$20(a0)
                move.w  #$14,$24(a0)
                btst    #0,d7
                bne.s   Boss_SnakeStoreSegmentAnimationPhase
                move.b  #$50,$21(a0)                    ; 'P'
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F010F010,$28(a0)
                addi.w  #4,d6
                cmpi.w  #$1E,d6
                bls.s   Boss_SnakeStoreSegmentAnimationPhase
                clr.w   d6
; Stores the phase offset used by each segment's animation cycle
Boss_SnakeStoreSegmentAnimationPhase:                   ; was: loc_40934
                                        ; Boss_SnakeInit+DC   j
                move.w  d6,$54(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_SnakeSetupSegmentLoop
Boss_SnakeInitReturn:                                   ; was: locret_40940
                rts
; End of function Boss_SnakeInit
; Initializes Snake's target-following encounter motion
Boss_SnakeBeginEncounterState:                          ; was: sub_40942
                bsr.w   Boss_SnakeSteerTowardTarget
                clr.b   (BossColorEffectFlags).w
                clr.w   $4A(a5)
                move.w  (PrimaryCameraXPosition).w,(SharedScratchLong1+2).w
                addi.w  #$120,(SharedScratchLong1+2).w
                move.w  #$100,(SharedScratchLong2).w
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_SnakeBeginEncounterState
; Runs the attackable encounter until the player sequence reaches state $56
Boss_SnakeBattleState:                                  ; was: sub_4096C
                bsr.w   Boss_SnakeSteerTowardTarget
                bsr.w   Boss_SnakeSelectTargetPosition
                bsr.w   Boss_SnakeRandomizeMotionAmplitudes
                cmpi.w  #$56,(MessageSequenceState).w   ; 'V'
                bcs.s   Boss_SnakeBattleStateReturn
                move.w  #$80,$48(a5)
                addq.w  #2,4(a5)
Boss_SnakeBattleStateReturn:                            ; was: locret_4098A
                rts
; End of function Boss_SnakeBattleState
; Periodically advances the head-target pattern
Boss_SnakeSelectTargetPosition:                         ; was: sub_4098C
                move.w  (FrameCounter).w,d0
                andi.w  #$7F,d0
                bne.s   Boss_SnakeLoadTargetPosition
                addq.w  #1,$52(a5)
; Loads the selected target X offset and absolute Y position
Boss_SnakeLoadTargetPosition:                           ; was: loc_4099A
                move.w  $52(a5),d0
                andi.w  #$F,d0
                add.w   d0,d0
                move.w  Boss_SnakeTargetPatternOffsets(pc,d0.w),d1
                move.w  (PrimaryCameraXPosition).w,d2
                add.w   Boss_SnakeTargetXOffsets(pc,d1.w),d2
                move.w  d2,(SharedScratchLong1+2).w
                move.w  Boss_SnakeTargetYPositions(pc,d1.w),(SharedScratchLong2).w
                rts
; End of function Boss_SnakeSelectTargetPosition
; ---------------------------------------------------------------------------
Boss_SnakeTargetPatternOffsets: dc.w    2, 4, 2, 4, 8, 2, 4, 2, 6, 4, 0, 8, 0, 2, 4, 2  ; was: word_409BC
Boss_SnakeTargetXOffsets:       dc.w    $C0, $120, $180, $C0, $180  ; was: word_409DC
Boss_SnakeTargetYPositions:     dc.w    $150, $140, $150, $140, $F0  ; was: word_409E6

; Randomizes the horizontal and vertical movement amplitudes
Boss_SnakeRandomizeMotionAmplitudes:                    ; was: sub_409F0
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Boss_SnakeRandomizeMotionAmplitudesReturn
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                addi.w  #$10,d0
                move.w  d0,(SharedScratchLong2+2).w
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                addi.w  #$10,d0
                move.w  d0,(SharedScratchLong3).w
Boss_SnakeRandomizeMotionAmplitudesReturn:              ; was: locret_40A1E
                rts
; End of function Boss_SnakeRandomizeMotionAmplitudes
; Moves through the first timed departure target
Boss_SnakeDepartureArcState:                            ; was: sub_40A20
                move.w  (PrimaryCameraXPosition).w,(SharedScratchLong1+2).w
                addi.w  #$160,(SharedScratchLong1+2).w
                move.w  #$140,(SharedScratchLong2).w
                bsr.w   Boss_SnakeSteerTowardTarget
                subq.w  #1,$48(a5)
                bne.s   Boss_SnakeDepartureArcReturn
                move.w  #$100,$48(a5)
                addq.w  #2,4(a5)
Boss_SnakeDepartureArcReturn:                           ; was: locret_40A46
                rts
; Moves below the arena, then retires the encounter object
Boss_SnakeExitDownwardState:                            ; was: sub_40A48
                move.w  (PrimaryCameraXPosition).w,(SharedScratchLong1+2).w
                addi.w  #$120,(SharedScratchLong1+2).w
                move.w  #$200,(SharedScratchLong2).w
                bsr.w   Boss_SnakeSteerTowardTarget
                subq.w  #1,$48(a5)
                bne.s   Boss_SnakeExitDownwardReturn
                clr.w   (a5)
                move.w  #$1000,2(a5)
Boss_SnakeExitDownwardReturn:                           ; was: locret_40A6C
                rts
; Starts the defeat explosion and sequential segment destruction
Boss_SnakeBeginDefeatState:                             ; was: sub_40A6E
                bsr.w   Boss_SnakeSteerTowardTarget
                jsr     (Effect_SpawnExplosionB).l
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                andi.w  #$7FFF,2(a5)
                move.w  #$10,$48(a5)
                move.w  a5,$4A(a5)
                clr.b   $21(a5)
                addq.w  #2,4(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_SnakeBeginDefeatReturn
                moveq   #3,d0
                jsr     (Pickup_SelectRandomSize).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
Boss_SnakeBeginDefeatReturn:                            ; was: locret_40AB6
                rts
; End of function Boss_SnakeBeginDefeatState
; Destroys snake segments sequentially
Boss_SnakeDestroySegmentsState:                         ; was: sub_40AB8
                bsr.w   Boss_SnakeSteerTowardTarget
                subq.w  #1,$48(a5)
                bne.s   Boss_SnakeDestroySegmentsReturn
                movea.w $4A(a5),a0
                lea     $60(a0),a0
                clr.b   $21(a0)
                move.w  #1,$5E(a0)
                lea     $8A0(a5),a1
                cmpa.w  a1,a0
                bhi.s   Boss_SnakeFinishSegmentDestruction
                move.w  a0,$4A(a5)
                move.w  #8,$48(a5)
Boss_SnakeDestroySegmentsReturn:                        ; was: locret_40AE6
                rts
; ---------------------------------------------------------------------------
Boss_SnakeFinishSegmentDestruction:                     ; was: loc_40AE8
                move.w  #$1000,2(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_SnakeDestroySegmentsState
Boss_SnakeInactiveState:                                ; was: nullsub_83
                rts
; End of function Boss_SnakeInactiveState

; Main handler for Snake segment
; REVIEWED VIS-002: pinned TAS frame 28000 shows 23 Snake segments type $29C; see docs/unknowns.md
Boss_SnakeSegmentMain:                                  ; was: sub_40AF6
                bsr.w   Boss_SnakeAdvanceAnimation
                tst.b   $21(a5)
                beq.s   Boss_SnakeCheckSegmentDestruction
                tst.w   (BossHealth).w
                bne.s   Boss_SnakeCheckSegmentDestruction
                clr.b   $21(a5)
Boss_SnakeCheckSegmentDestruction:                      ; was: loc_40B0A
                                        ; Boss_SnakeSegmentMain+E   j
                cmpi.w  #4,4(a5)
                bcc.s   Boss_SnakeSegmentDispatch
                tst.w   $5E(a5)
                beq.s   Boss_SnakeSegmentDispatch
                move.w  #4,4(a5)
                jsr     (Effect_SpawnExplosionB).l
                andi.w  #$7FFF,2(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_SnakeSegmentDispatch
                moveq   #3,d0
                jsr     (Pickup_SelectRandomSize).l
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
; State dispatcher for snake segments
Boss_SnakeSegmentDispatch:                              ; was: loc_40B46
                                        ; Boss_SnakeSegmentMain+20   j
                move.w  4(a5),d0
                lea     Boss_SnakeSegmentStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_SnakeSegmentMain
; ---------------------------------------------------------------------------
Boss_SnakeSegmentStates:    dc.w    Boss_SnakeSegmentFireState-*  ; was: off_40B52
                dc.w    Boss_SnakeSegmentCooldownState-*
                dc.w    Boss_SnakeSegmentInactiveState-*

; Fires when the segment crosses the central vertical band
Boss_SnakeSegmentFireState:                             ; was: sub_40B58
                cmpi.w  #$140,$14(a5)
                blt.s   Boss_SnakeSegmentFireReturn
                cmpi.w  #$160,$14(a5)
                bgt.s   Boss_SnakeSegmentFireReturn
                lea     (TwentySixthEntityType).w,a0
                jsr     (Projectile_FindFreeSlotForward8).l
                bne.s   Boss_SnakeSegmentFireReturn
                jsr     (Projectile_InitType88).l
                bsr.s   Boss_SnakeConfigureShot
                move.w  #8,$48(a5)
                addq.w  #2,4(a5)
                move.w  (FrameCounter).w,d7
                andi.w  #7,d7
                bne.s   Boss_SnakeSegmentFireReturn
                move.b  #$4C,d0                         ; 'L'
                jsr     (Sound_QueueSFXRequest).l
Boss_SnakeSegmentFireReturn:                            ; was: locret_40B9A
                                        ; Boss_SnakeSegmentFireState+E   j
                rts
; End of function Boss_SnakeSegmentFireState
; Enforces an eight-frame delay between segment shots
Boss_SnakeSegmentCooldownState:                         ; was: sub_40B9C
                subq.w  #1,$48(a5)
                bne.s   Boss_SnakeSegmentCooldownReturn
                subq.w  #2,4(a5)
Boss_SnakeSegmentCooldownReturn:                        ; was: locret_40BA6
                rts
; End of function Boss_SnakeSegmentCooldownState
Boss_SnakeSegmentInactiveState:                         ; was: nullsub_84
                rts
; End of function Boss_SnakeSegmentInactiveState

; Configures a segment shot's position, velocity, and mapping stream
Boss_SnakeConfigureShot:                                ; was: sub_40BAA
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #3,d0
                subq.w  #4,d0
                move.w  d0,$18(a0)
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                neg.w   d0
                move.w  d0,$1C(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Boss_SnakeShotMappingChoices(pc,d0.w),8(a0)
                move.w  #$C000,$E(a0)
                rts
; End of function Boss_SnakeConfigureShot
; ---------------------------------------------------------------------------
Boss_SnakeShotMappingChoices:   dc.l    SharedProjectileDuration4Animation  ; was: off_40BEC
                dc.l    SharedProjectileDuration2Animation
                dc.l    SharedProjectileDuration4Animation
                dc.l    SharedProjectileDuration8Animation

; Turns toward the target and derives signed axis velocities
Boss_SnakeSteerTowardTarget:                            ; was: sub_40BFC
                                        ; Boss_SnakeBattleState   p
                move.w  (FrameCounter).w,d0
                andi.w  #$F,d0
                bne.s   Boss_SnakeApplyTurnAndVelocity
                move.w  (SharedScratchLong1+2).w,d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  (SharedScratchLong2).w,d1
                sub.w   $10(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_CalculateDirectionIndex).l
                move.w  (SharedScratchLong0).w,d1
                addi.w  #$100,d1
                sub.w   d2,d1
                andi.w  #$1FF,d1
                cmpi.w  #$100,d1
                beq.s   Boss_SnakeApplyTurnAndVelocity
                cmpi.w  #$100,d1
                bcs.s   Boss_SnakeUseNegativeTurnSpeed
                move.w  #8,(SharedScratchLong0+2).w
                bra.s   Boss_SnakeApplyTurnAndVelocity
; ---------------------------------------------------------------------------
Boss_SnakeUseNegativeTurnSpeed:                         ; was: loc_40C42
                move.w  #$FFF8,(SharedScratchLong0+2).w
Boss_SnakeApplyTurnAndVelocity:                         ; was: loc_40C48
                                        ; Boss_SnakeSteerTowardTarget+36   j
                move.w  (SharedScratchLong0+2).w,d0
                add.w   d0,(SharedScratchLong0).w
                andi.w  #$1FF,(SharedScratchLong0).w
                move.w  (SharedScratchLong0).w,d0
                addi.w  #$100,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d0.w),d1
                move.w  (a1,d0.w),d0
                muls.w  (SharedScratchLong2+2).w,d0
                muls.w  (SharedScratchLong3).w,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                rts
; End of function Boss_SnakeSteerTowardTarget
; Advances the shared thirty-step segment animation
Boss_SnakeAdvanceAnimation:                             ; was: sub_40C82
                                        ; Boss_SnakeSegmentMain   p
                move.w  (FrameCounter).w,d7
                andi.w  #1,d7
                bne.s   Boss_SnakeAdvanceAnimationReturn
                addq.w  #1,$54(a5)
                cmpi.w  #$1E,$54(a5)
                bne.s   Boss_SnakeApplyAnimationFrame
                clr.w   $54(a5)
; Applies the forward-and-reverse frame selected by the phase counter
Boss_SnakeApplyAnimationFrame:                          ; was: loc_40C9C
                move.w  $54(a5),d0
                add.w   d0,d0
                move.w  Boss_SnakeAnimationFrameSequence(pc,d0.w),d1
                add.w   d1,d1
                jsr     (Sprite_SelectSharedGraphicsFrame).l
Boss_SnakeAdvanceAnimationReturn:                       ; was: locret_40CAE
                rts
; End of function Boss_SnakeAdvanceAnimation
; ---------------------------------------------------------------------------
Boss_SnakeAnimationFrameSequence:   dc.w    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $A, $B, $C, $D, $E  ; was: word_40CB0
                dc.w    $F, $E, $D, $C, $B, $A, 9, 8, 7, 6, 5, 4, 3, 2, 1

; UNKNOWN CODE-001: no static entry path; see docs/unknowns.md
Boss_SnakeUnreferencedReturn:                           ; was: nullsub_85
                rts
; End of function Boss_SnakeUnreferencedReturn
