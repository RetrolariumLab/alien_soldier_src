; Dispatches Love Penguin (entity type $1C0), the boss no stock loader selects;
; it is not the live Sunset Sting (docs/love_penguin.md)
Boss_LovePenguinInitDispatcher:                         ; was: sub_40CEE
                moveq   #4,d7
                jsr     (Gfx_ProcessDefaultColorFade).l
                move.w  4(a5),d0
                lea     Boss_LovePenguinEarlyFormStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_LovePenguinInitDispatcher
; ---------------------------------------------------------------------------
Boss_LovePenguinEarlyFormStates:
                dc.w    Boss_LovePenguinSetupArena-*    ; was: off_40D02
                dc.w    Boss_LovePenguinLoadGraphics-*
                dc.w    Boss_LovePenguinQueueIntroMessageState-*
                dc.w    Boss_LovePenguinWaitForIntroMessageState-*
                dc.w    Boss_LovePenguinIdleState-*
                dc.w    Boss_LovePenguinIncreaseSharedCounterState-*
                dc.w    Boss_LovePenguinDashAttack-*
                dc.w    Boss_LovePenguinDashAttack_MoveToward-*
                dc.w    Boss_LovePenguinDashAttack_MoveAway-*
                dc.w    Boss_LovePenguinDashAttack_MoveToward-*
                dc.w    Boss_LovePenguinDashAttack_MoveAway-*
                dc.w    Boss_LovePenguinResetForAttack-*
                dc.w    Boss_LovePenguinPrepareDive-*
                dc.w    Boss_LovePenguinTimerWait-*
                dc.w    Boss_LovePenguinSerpentineAttack-*
                dc.w    Boss_LovePenguinSerpentineAttack_MoveIn-*
                dc.w    Boss_LovePenguinSerpentineAttack_MoveOut-*
                dc.w    Boss_LovePenguinRotationDecelerate-*
                dc.w    Boss_LovePenguinWobbleRotation-*
                dc.w    Boss_LovePenguinScatterBodyPartsState-*
                dc.w    Boss_LovePenguinRiseAndSpawnProjectilesState-*
                dc.w    Boss_LovePenguinDefeatCleanupState-*
; REVIEWED DATA-001: five flagged pointers in the body-part table select this mapping
Boss_LovePenguinEarlyFormPartMapping:
                binclude "data/other/entity_type_1c0_early_form_part_mapping.bin"  ; was: unused_8

; Sets up battle arena parameters and clears sprite slots
Boss_LovePenguinSetupArena:                             ; was: sub_40D34
                move.b  #6,(BossColorEffectFlags).w
                move.w  #$1C0,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                addq.w  #2,4(a5)
                move.b  #$80,$4B(a5)
                clr.w   (LovePenguinAnimationProgress).w
                rts
; End of function Boss_LovePenguinSetupArena
; Loads boss sprites, palette, tiles and initializes position/velocity
Boss_LovePenguinLoadGraphics:                           ; was: sub_40D56
                tst.w   (DataLoaderControl).w
                bmi.w   Boss_LovePenguinLoadGraphicsReturn
                addq.w  #2,4(a5)
                movea.l #Boss_LovePenguinObjectInitTable,a1
                jsr     (Object_InitGroupFromTable).l
                moveq   #6,d7
                jsr     (Gfx_ResetDefaultColorFadeState).l
                move.w  (a5),-(sp)
                move.w  #$4300,$E(a5)
                lea     Boss_LovePenguinBodyPartInitTable(pc),a1
                lea     (a5),a4
                jsr     Boss_LovePenguinInitBodyParts(pc)  ; (pc)
                nop
                move.w  (sp)+,(a5)
                ori.w   #$D00,2(a5)
                move.l  #$2000000,$10(a5)
                move.l  #$1000000,$14(a5)
                move.l  #$FFFF0000,$18(a5)
                move.b  #0,$4A(a5)
                ori.w   #$800,$E(a5)
                movea.l #Boss_LovePenguinEarlyFormTileLoadCommands,a0
                jsr     (Tilemap_QueueIndexedRows).l
Boss_LovePenguinLoadGraphicsReturn:                     ; was: locret_40DC2
                rts
; End of function Boss_LovePenguinLoadGraphics
; ---------------------------------------------------------------------------
Boss_LovePenguinPrimaryTileAnimationOffsets:
                dc.w    $E, $20, $1E, $26, $1A, $22, $16, $14, $12  ; was: word_40DC4
Boss_LovePenguinEarlyFormTileLoadCommands:
                dc.w    $6100, $2000, $202, $494A, $4B4D, $4E4F, $5152, $FF, $6300, $2000, $101, $4D4E, $5152, $6300, $2000, $101  ; was: word_40DD6
                dc.w    $5455, $5658, $E, $10, $16, $1C, $12, 8, 6, 4, 2, $6100, $2000, $100, $494A, $6100
                dc.w    $2000, $100, $4C53, $6100, $2000, $100, $5057

; Queues the phase-intro message and advances to its movement state
Boss_LovePenguinQueueIntroMessageState:                 ; was: sub_40E24
                moveq   #5,d0
                jsr     (BossMessage_Start).l
                addq.w  #2,4(a5)
                bra.w   Boss_LovePenguinIntroUpdateMotion
; End of function Boss_LovePenguinQueueIntroMessageState
; Holds the intro flight pattern until the shared message timer expires
Boss_LovePenguinWaitForIntroMessageState:               ; was: sub_40E34
                tst.w   (MessageSequenceState).w
                bne.s   Boss_LovePenguinIntroUpdateMotion
                clr.b   (BossColorEffectFlags).w
                subi.w  #$A0,(CameraXLowerBound).w
                addq.w  #2,4(a5)
Boss_LovePenguinIntroUpdateMotion:                      ; was: loc_40E48
                                        ; Boss_LovePenguinWaitForIntroMessageState+4   j
                subq.b  #1,$4B(a5)
                bsr.w   Boss_LovePenguinCalculateVerticalVelocity
                cmpi.l  #$1600000,$10(a5)
                bhi.s   Boss_LovePenguinIntroRender
                clr.l   $18(a5)
Boss_LovePenguinIntroRender:                            ; was: loc_40E5E
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinWaitForIntroMessageState
; Resets attack state and adjusts based on boss health
Boss_LovePenguinResetForAttack:                         ; was: sub_40E62
                                        ; Boss_LovePenguinDashAttack+82   j
                move.w  #8,4(a5)
                move.b  #$40,$4B(a5)                    ; '@'
                clr.l   $18(a5)
                cmpi.w  #$100,(BossCombatCounter).w
                bgt.s   Boss_LovePenguinResetDisableCollision
                move.b  #$C0,$4B(a5)
                move.w  #$A,4(a5)
Boss_LovePenguinResetDisableCollision:                  ; was: loc_40E86
                bsr.w   Boss_LovePenguinDisableCollision
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinResetForAttack
; Increments the shared battle counter before the idle update
Boss_LovePenguinIncreaseSharedCounterState:             ; was: sub_40E8E
                addi.w  #2,(BossCombatCounter).w
                clr.w   d3
                bsr.w   Boss_LovePenguinCalculateAngleAndFlip
; End of function Boss_LovePenguinIncreaseSharedCounterState
; Handles idle behavior with animation and distance-based attack selection
Boss_LovePenguinIdleState:                              ; was: sub_40E9A
                subq.b  #1,$4B(a5)
                beq.w   Boss_LovePenguinChooseAttack
                bsr.w   Boss_LovePenguinCalculateVerticalVelocity
                move.b  #0,6(a5)
                bsr.w   Boss_LovePenguinInterpolateRotation
                move.b  #0,$4A(a5)
                btst    #4,$4B(a5)
                beq.w   Boss_LovePenguinUpdateGraphics
                move.b  #4,$4A(a5)
                bra.w   Boss_LovePenguinUpdateGraphics
; ---------------------------------------------------------------------------
Boss_LovePenguinChooseAttack:                           ; was: loc_40ECA
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$80,d0
                bcs.s   Boss_LovePenguinCloseRangeAttack
                lea     Boss_LovePenguinDistantAttackChoices(pc),a0
                jmp     Math_JumpToWeightedChoice
; End of function Boss_LovePenguinIdleState
; ---------------------------------------------------------------------------
Boss_LovePenguinDistantAttackChoices:
                dc.w    $7800                           ; was: word_40EE0
                dc.w    Boss_LovePenguinBeginSerpentineCycle-*
                dc.w    $7000
                dc.w    Boss_LovePenguinBeginDashCycle-*
                dc.w    $1000
                dc.w    Boss_LovePenguinBeginWobble-*
                dc.w    $800
                dc.w    Boss_LovePenguinBeginRotationRecovery-*

; Selects random attack pattern when player is close
Boss_LovePenguinCloseRangeAttack:                       ; was: sub_40EF0
                lea     Boss_LovePenguinCloseAttackChoices(pc),a0
                jmp     Math_JumpToWeightedChoice
; End of function Boss_LovePenguinCloseRangeAttack
; ---------------------------------------------------------------------------
Boss_LovePenguinCloseAttackChoices:
                dc.w    $A000                           ; was: word_40EFA
                dc.w    Boss_LovePenguinBeginRotationRecovery-*
                dc.w    $8000
                dc.w    Boss_LovePenguinBeginDiveWindup-*

; Calculates horizontal screen offset based on boss position and velocity direction
Boss_LovePenguinCalculateScreenOffset:                  ; was: sub_40F02
                                        ; Boss_LovePenguinDashAttack+7E   p
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                tst.w   $18(a5)
                bpl.s   Boss_LovePenguinMeasureRightBoundary
                subi.w  #$400,d0
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinMeasureRightBoundary:                   ; was: loc_40F16
                move.w  #$600,d1
                sub.w   d0,d1
                rts
; End of function Boss_LovePenguinCalculateScreenOffset
; Disables collision flag for all 5 boss body segments
Boss_LovePenguinDisableCollision:                       ; was: sub_40F1E
                andi.b  #$BF,$201(a5)
                andi.b  #$BF,$3E1(a5)
                andi.b  #$BF,$5C1(a5)
                andi.b  #$BF,$7A1(a5)
                andi.b  #$BF,$921(a5)
                rts
; End of function Boss_LovePenguinDisableCollision
; Enables collision flag for all 5 boss body segments
Boss_LovePenguinEnableCollision:                        ; was: sub_40F3E
                                        ; Boss_LovePenguinBeginDiveWindup+12   p
                ori.b   #$40,$201(a5)                   ; '@'
                ori.b   #$40,$3E1(a5)                   ; '@'
                ori.b   #$40,$5C1(a5)                   ; '@'
                ori.b   #$40,$7A1(a5)                   ; '@'
                ori.b   #$40,$921(a5)                   ; '@'
                rts
; End of function Boss_LovePenguinEnableCollision
; Starts the repeated dash cycle
Boss_LovePenguinBeginDashCycle:                         ; was: sub_40F5E
                move.w  #$C,4(a5)
                move.b  #$30,$4B(a5)                    ; '0'
                move.b  #4,$4A(a5)
                bsr.s   Boss_LovePenguinEnableCollision
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinBeginDashCycle
; Executes dashing movement pattern with trajectory calculations
Boss_LovePenguinDashAttack:                             ; was: sub_40F76
                move.w  #0,d3
                bsr.w   Boss_LovePenguinCalculateAngleAndFlip
                bsr.w   Boss_LovePenguinInterpolateRotation
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                move.b  #0,$4A(a5)
                addq.w  #2,4(a5)
                move.b  #$C,$4B(a5)
                clr.w   d0
                btst    #3,$E(a5)
                bne.s   Boss_LovePenguinDashStoreInitialAngle
                move.w  #$100,d0
Boss_LovePenguinDashStoreInitialAngle:                  ; was: loc_40FA8
                move.w  d0,6(a5)
; Move toward target using calculated trajectory
Boss_LovePenguinDashAttack_MoveToward:                  ; was: loc_40FAC
                                        ; ROM:00040D14   o
                move.w  #2,d2
                bsr.w   Boss_LovePenguinCalculateTrajectory
                add.l   d1,$18(a5)
                add.l   d0,$1C(a5)
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                move.b  #$C,$4B(a5)
                addq.w  #2,4(a5)
                move.b  #4,$4A(a5)
; Move away from target with screen boundary check
Boss_LovePenguinDashAttack_MoveAway:                    ; was: loc_40FD4
                                        ; ROM:00040D16   o
                move.w  #2,d2
                bsr.w   Boss_LovePenguinCalculateTrajectory
                sub.l   d1,$18(a5)
                sub.l   d0,$1C(a5)
                bsr.w   Boss_LovePenguinCalculateScreenOffset
                bcs.w   Boss_LovePenguinResetForAttack
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                bsr.w   Boss_LovePenguinCalculateScreenOffset
                bcs.w   Boss_LovePenguinResetForAttack
                move.b  #$C,$4B(a5)
                addq.w  #2,4(a5)
                move.b  #0,$4A(a5)
                subi.w  #$40,(BossCombatCounter).w      ; '@'
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinDashAttack
; Starts the dive windup state
Boss_LovePenguinBeginDiveWindup:                        ; was: sub_41016
                move.w  #$18,4(a5)
                move.b  #$30,$4B(a5)                    ; '0'
                move.b  #4,$4A(a5)
                bsr.w   Boss_LovePenguinEnableCollision
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinBeginDiveWindup
; Prepares boss dive attack by setting timer and adjusting screen offset
Boss_LovePenguinPrepareDive:                            ; was: sub_41030
                move.w  #$20,d3                         ; ' '
                bsr.w   Boss_LovePenguinCalculateAngleAndFlip
                bsr.w   Boss_LovePenguinInterpolateRotation
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                move.b  #6,$4A(a5)
                addq.w  #2,4(a5)
                move.b  #$30,$4B(a5)                    ; '0'
                subi.w  #$50,(BossCombatCounter).w      ; 'P'
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinPrepareDive
; Waits for timer countdown before resetting attack state
Boss_LovePenguinTimerWait:                              ; was: sub_4105E
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                bra.w   Boss_LovePenguinResetForAttack
; End of function Boss_LovePenguinTimerWait
; Starts the serpentine movement cycle
Boss_LovePenguinBeginSerpentineCycle:                   ; was: sub_4106A
                move.w  #$1C,4(a5)
                move.b  #$30,$4B(a5)                    ; '0'
                move.b  #8,$4A(a5)
                clr.l   $1C(a5)
                bsr.w   Boss_LovePenguinEnableCollision
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinBeginSerpentineCycle
; Performs serpentine movement pattern with trajectory reversals
Boss_LovePenguinSerpentineAttack:                       ; was: sub_41088
                move.w  #2,d2
                bsr.w   Boss_LovePenguinCalculateTrajectory
                neg.l   d1
                neg.l   d0
                move.l  d1,$18(a5)
                move.l  #$C00000,d0
                sub.l   $14(a5),d0
                asr.l   #2,d0
                move.l  d0,$1C(a5)
                move.w  #$40,d3                         ; '@'
                bsr.w   Boss_LovePenguinCalculateAngleAndFlip
                bsr.w   Boss_LovePenguinInterpolateRotation
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                addq.w  #2,4(a5)
                move.b  #$10,$4B(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
; Serpentine pattern movement toward target
Boss_LovePenguinSerpentineAttack_MoveIn:                ; was: loc_410CE
                move.w  #2,d2
                bsr.w   Boss_LovePenguinCalculateTrajectory
                add.l   d1,$18(a5)
                add.l   d0,$1C(a5)
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinSerpentineCheckBounds
                addq.w  #2,4(a5)
                move.b  #$10,$4B(a5)
                subi.w  #$140,(BossCombatCounter).w
; Serpentine pattern movement away from target
Boss_LovePenguinSerpentineAttack_MoveOut:               ; was: loc_410F6
                move.w  #2,d2
                bsr.w   Boss_LovePenguinCalculateTrajectory
                sub.l   d1,$18(a5)
                sub.l   d0,$1C(a5)
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinSerpentineCheckBounds
                bra.w   Boss_LovePenguinResetForAttack
; ---------------------------------------------------------------------------
Boss_LovePenguinSerpentineCheckBounds:                  ; was: loc_41112
                                        ; Boss_LovePenguinSerpentineAttack+82   j
                bsr.w   Boss_LovePenguinCalculateScreenOffset
                bcs.w   Boss_LovePenguinResetForAttack
                cmpi.w  #$110,$14(a5)
                bcs.w   Boss_LovePenguinUpdateGraphics
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                neg.l   $1C(a5)
                bra.w   *+4
; End of function Boss_LovePenguinSerpentineAttack
; Recovers from attack by setting state timer and enabling collision
Boss_LovePenguinBeginRotationRecovery:                  ; was: sub_41138
                                        ; Boss_LovePenguinWobbleRotation+1C   j
                move.w  #$22,4(a5)                      ; '"'
                move.b  #$38,$4B(a5)                    ; '8'
                move.b  #$A,$4A(a5)
                subi.w  #$148,(BossCombatCounter).w
                bsr.w   Boss_LovePenguinEnableCollision
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinBeginRotationRecovery
; Decelerates rotation angle and resets attack when timer expires
Boss_LovePenguinRotationDecelerate:                     ; was: sub_41158
                addi.w  #$C,$56(a5)
                subq.b  #1,$4B(a5)
                beq.w   Boss_LovePenguinResetForAttack
                move.l  $18(a5),d0
                asr.l   #4,d0
                sub.l   d0,$18(a5)
                bsr.w   Boss_LovePenguinCalculateVerticalVelocity
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinRotationDecelerate
; Starts the timed wobble state
Boss_LovePenguinBeginWobble:                            ; was: sub_41178
                move.w  #$24,4(a5)                      ; '$'
                move.b  #$60,$4B(a5)                    ; '`'
                move.b  #6,$4A(a5)
                clr.l   $1C(a5)
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinBeginWobble
; Applies wobbling rotation effect using sine wave pattern
Boss_LovePenguinWobbleRotation:                         ; was: sub_41192
                move.b  $4B(a5),d4
                lsr.w   #2,d4
                andi.w  #7,d4
                move.b  Boss_LovePenguinWobbleAngleDeltas(pc,d4.w),d4
                ext.w   d4
                add.w   d4,$56(a5)
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                bra.s   Boss_LovePenguinBeginRotationRecovery
; End of function Boss_LovePenguinWobbleRotation
; ---------------------------------------------------------------------------
Boss_LovePenguinWobbleAngleDeltas:
                dc.w    $FFFD, $FCFF, $103, $401, $49ED, $60, $363C, 4  ; was: word_411B0

; Spawns multiple projectile debris with randomized trajectories
Boss_LovePenguinSpawnDebris:                            ; was: sub_411C0
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_LovePenguinFinishDebrisSpawn
                move.w  #$1C4,(a0)
                ori.w   #$CD00,2(a0)
                jsr     (RandomNumber).l
                rol.l   #8,d0
                move.w  d0,d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                muls.w  #4,d1
                muls.w  #4,d0
                move.l  d1,$18(a0)
                move.l  d0,$1C(a0)
                jsr     (RandomNumber).l
                rol.l   #8,d0
                ext.w   d0
                asr.w   #3,d0
                move.w  d0,$5C(a0)
                clr.b   $21(a0)
                move.l  $10(a4),$10(a0)
                move.l  $14(a4),$14(a0)
                lea     $60(a4),a4
                dbf     d3,Boss_LovePenguinSpawnDebris
Boss_LovePenguinFinishDebrisSpawn:                      ; was: loc_41222
                bra.w   Boss_LovePenguinResetForAttack
; End of function Boss_LovePenguinSpawnDebris
; Calculates movement trajectory using sine/cosine lookup table
Boss_LovePenguinCalculateTrajectory:                    ; was: sub_41226
                                        ; Boss_LovePenguinDashAttack+62   p
                move.w  $56(a5),d1
                asr.w   #1,d1
                sub.w   $5A(a5),d1
                add.w   d1,d1
                andi.w  #$1FE,d1
                lea     (Math_SineTable).l,a2
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                btst    #3,$E(a5)
                beq.s   Boss_LovePenguinScaleTrajectory
                neg.w   d1
Boss_LovePenguinScaleTrajectory:                        ; was: loc_41250
                ext.l   d0
                ext.l   d1
                asl.l   d2,d0
                asl.l   d2,d1
                rts
; End of function Boss_LovePenguinCalculateTrajectory
; Checks distance to player and sets horizontal flip bit
Boss_LovePenguinCheckFlipDirection:
                andi.w  #$F7FF,$E(a5)                   ; was: sub_4125A
                jsr     (Physics_GetPlayerDelta).l
                tst.w   d1
                bpl.s   Boss_LovePenguinCheckFlipReturn
                ori.w   #$800,$E(a5)
Boss_LovePenguinCheckFlipReturn:                        ; was: locret_41270
                rts
; End of function Boss_LovePenguinCheckFlipDirection
; Calculates angle to player with flip flag
Boss_LovePenguinCalculateAngleAndFlip:                  ; was: sub_41272
                                        ; Boss_LovePenguinDashAttack+4   p
                andi.w  #$F7FF,$E(a5)
                movem.l d3,-(sp)
                lea     (PlayerObjectType).w,a4
                jsr     (Physics_CalculateAngleToTarget).l
                movem.l (sp)+,d3
                move.b  d0,d2
                bpl.s   Boss_LovePenguinStoreAimOffset
                ori.w   #$800,$E(a5)
                neg.b   d2
Boss_LovePenguinStoreAimOffset:                         ; was: loc_41296
                move.w  d3,$5A(a5)
; End of function Boss_LovePenguinCalculateAngleAndFlip
; Applies angle offset to boss orientation register
Boss_LovePenguinApplyAngleOffset:
                add.w   $5A(a5),d2                      ; was: sub_4129A
                move.w  d2,6(a5)
                rts
; End of function Boss_LovePenguinApplyAngleOffset
; Interpolates rotation angle towards target smoothly
Boss_LovePenguinInterpolateRotation:                    ; was: sub_412A4
                                        ; Boss_LovePenguinDashAttack+8   p
                move.w  $56(a5),d1
                lsr.w   #1,d1
                move.w  6(a5),d0
                sub.b   d1,d0
                asr.b   #2,d0
                ext.w   d0
                add.w   d0,$56(a5)
                rts
; End of function Boss_LovePenguinInterpolateRotation
; Calculates vertical velocity using sine wave for hovering
Boss_LovePenguinCalculateVerticalVelocity:              ; was: sub_412BA
                                        ; Boss_LovePenguinIdleState+8   p
                clr.w   d0
                move.b  $4B(a5),d0
                asl.w   #2,d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a0
                move.w  (a0,d0.w),d0
                ext.l   d0
                asl.l   #6,d0
                addi.l  #$1000000,d0
                sub.l   $14(a5),d0
                asr.l   #2,d0
                move.l  d0,$1C(a5)
                rts
; End of function Boss_LovePenguinCalculateVerticalVelocity
; Updates boss sprite graphics based on animation frame counter
Boss_LovePenguinUpdateGraphics:                         ; was: sub_412E6
                                        ; Boss_LovePenguinResetForAttack+28   j
                bsr.w   Boss_LovePenguinUpdatePartAngles
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_LovePenguinUpdateBodyGraphics
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_LovePenguinUpdateBodyGraphics
                tst.w   (BossHealth).w
                beq.w   Boss_LovePenguinBeginEarlyFormDefeatState
Boss_LovePenguinUpdateBodyGraphics:                     ; was: loc_41302
                                        ; Boss_LovePenguinUpdateGraphics+12   j
                lea     Boss_LovePenguinBodyPartInitTable(pc),a1
                jsr     Boss_LovePenguinUpdateBodyPartPositions(pc)  ; (pc)
                nop
                bsr.w   Boss_LovePenguinUpdateCameraOffset
                lea     Boss_LovePenguinPrimaryTileAnimationOffsets(pc),a0
                move.w  (LovePenguinAnimationProgress).w,d0
                lsr.w   #3,d0
                bsr.w   Boss_LovePenguinLoadTileTableEntry
                lea     Boss_LovePenguinEarlyFormTileLoadCommands+$24(pc),a0
                move.w  (LovePenguinAnimationProgress).w,d0
                lsr.w   #2,d0
                bsr.w   Boss_LovePenguinLoadTileTableEntry
                addq.w  #1,(LovePenguinAnimationProgress).w
                rts
; End of function Boss_LovePenguinUpdateGraphics
; Loads compressed tile data from indexed table entry
Boss_LovePenguinLoadTileTableEntry:                     ; was: sub_41332
                                        ; Boss_LovePenguinUpdateGraphics+42   p
                and.w   (a0)+,d0
                adda.w  d0,a0
                adda.w  (a0),a0
                jmp     Tilemap_QueueIndexedRows
; End of function Boss_LovePenguinLoadTileTableEntry
; Starts the early form's defeat transition when shared health reaches zero
Boss_LovePenguinBeginEarlyFormDefeatState:              ; was: sub_4133E
                move.b  #1,(SoundFadeOutDelay).w
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                jsr     (Sprite_ClearObjectFlags).l
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                move.b  #0,$4A(a5)
                move.w  #$26,4(a5)                      ; '&'
                move.b  #8,$4B(a5)
                clr.l   $18(a5)
                move.l  #$FFFF0000,$1C(a5)
                bra.w   Boss_LovePenguinUpdateGraphics
; End of function Boss_LovePenguinBeginEarlyFormDefeatState
; Converts the body parts to debris with randomized velocities
Boss_LovePenguinScatterBodyPartsState:                  ; was: sub_41384
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinUpdateGraphics
                addq.w  #2,4(a5)
                clr.b   $21(a5)
                move.w  (LovePenguinBodyPartCount).w,d4
                subq.w  #2,d4
                lea     $60(a5),a4
                lea     (Math_SineTable).l,a2
Boss_LovePenguinInitializeDebrisPart:                   ; was: loc_413A4
                move.w  #$1C4,(a4)
                move.w  #$CD40,2(a4)
                jsr     (RandomNumber).l
                rol.l   #8,d0
                move.w  d0,d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                muls.w  #4,d1
                muls.w  #4,d0
                move.l  d1,$18(a4)
                move.l  d0,$1C(a4)
                clr.b   $4B(a4)
                jsr     (RandomNumber).l
                rol.l   #8,d0
                ext.w   d0
                asr.w   #3,d0
                move.w  d0,$5C(a4)
                clr.b   $21(a4)
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinInitializeDebrisPart
; Spawn projectiles while rising until screen threshold
Boss_LovePenguinRiseAndSpawnProjectilesState:           ; was: loc_413F6
                addi.l  #$800,$1C(a5)
                cmpi.w  #$1C0,$14(a5)
                bhi.s   Boss_LovePenguinBeginStaggeredDebrisCleanup
                move.l  #$200020,d1
                bsr.w   Boss_LovePenguinSpawnRandomOffsetProjectile
                bsr.w   Boss_LovePenguinUpdateCameraOffset
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinBeginStaggeredDebrisCleanup:            ; was: loc_41416
                move.b  #$40,$4B(a5)                    ; '@'
                addq.w  #2,4(a5)
                move.w  #1,d5
                move.w  (LovePenguinBodyPartCount).w,d4
                subq.w  #2,d4
                lea     $60(a5),a4
Boss_LovePenguinSeedDebrisCleanupDelay:                 ; was: loc_4142E
                move.b  d5,$4B(a4)
                addq.w  #1,d5
                lea     $60(a4),a4
                dbf     d4,Boss_LovePenguinSeedDebrisCleanupDelay
                rts
; End of function Boss_LovePenguinScatterBodyPartsState
; Retires the controller after its defeat cleanup timer expires
Boss_LovePenguinDefeatCleanupState:                     ; was: sub_4143E
                move.w  #4,(PlaneAShakeLevel).w
                move.w  #4,(PlaneBShakeLevel).w
                subq.b  #1,$4B(a5)
                bne.w   Boss_LovePenguinFadeOutReturn
                clr.w   (a5)
Boss_LovePenguinFadeOutReturn:                          ; was: locret_41454
                rts
; End of function Boss_LovePenguinDefeatCleanupState
; Updates one body-part debris object and retires it after its delay
Boss_LovePenguinDebrisPartMain:                         ; was: sub_41456
                tst.b   $4B(a5)
                beq.s   Boss_LovePenguinDebrisPartUpdateAnimation
                subq.b  #1,$4B(a5)
                beq.s   Boss_LovePenguinDebrisPartRemove
Boss_LovePenguinDebrisPartUpdateAnimation:              ; was: loc_41462
                move.w  $5C(a5),d0
                add.w   d0,$56(a5)
                move.l  $50(a5),d0
                beq.s   Boss_LovePenguinDebrisPartReturn
                movea.l d0,a1
                move.w  $56(a5),d0
                lsr.w   #3,d0
                andi.w  #$1C,d0
                move.l  (a1,d0.w),8(a5)
Boss_LovePenguinDebrisPartReturn:                       ; was: locret_41482
                rts
; ---------------------------------------------------------------------------
Boss_LovePenguinDebrisPartRemove:                       ; was: loc_41484
                lea     (a5),a0
                jsr     (Effect_InitSharedExplosion).l
                clr.b   $21(a5)
                rts
; End of function Boss_LovePenguinDebrisPartMain
; Spawns projectile with randomized position offset
Boss_LovePenguinSpawnRandomOffsetProjectile:            ; was: sub_41492
                                        ; Boss_LovePenguinDescendAndActivateChainsState+E   p
                move.l  d1,-(sp)
                jsr     (Projectile_PrepareImpactSpawn).l
                bne.s   Boss_LovePenguinSpawnRandomOffsetProjectileReturn
                jsr     (Sprite_InitFromTable).l
                clr.b   $20(a0)
                move.l  $18(a5),$18(a0)
                move.l  $1C(a5),$1C(a0)
                neg.l   $18(a0)
                neg.l   $1C(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                move.w  (sp),d2
                add.w   d2,d2
                subq.w  #1,d2
                and.w   d2,d0
                sub.w   (sp),d0
                move.w  2(sp),d2
                add.w   d2,d2
                subq.w  #1,d2
                and.w   d2,d1
                sub.w   2(sp),d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_LovePenguinSpawnRandomOffsetProjectileReturn:      ; was: loc_414EA
                move.l  (sp)+,d1
                rts
; End of function Boss_LovePenguinSpawnRandomOffsetProjectile
; Calculates camera offset relative to boss position
Boss_LovePenguinUpdateCameraOffset:                     ; was: sub_414EE
                                        ; Boss_LovePenguinRiseAndSpawnProjectilesState+12   p
                move.w  #$A4,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  $14(a5),d0
                addi.w  #$4C,d0                         ; 'L'
                move.w  d0,(SecondaryCameraYPos).w
                jmp     Boss_ClampSharedScreenPosition
; End of function Boss_LovePenguinUpdateCameraOffset
; Updates animation angles for boss body parts
Boss_LovePenguinUpdatePartAngles:                       ; was: sub_4150C
                move.b  $4A(a5),d0
                andi.w  #$E,d0
                lea     Boss_LovePenguinBodyPartAngleSequences(pc),a1
                adda.w  d0,a1
                adda.w  (a1),a1
                lea     $60(a5),a4
Boss_LovePenguinReadAngleSequence:                      ; was: loc_41520
                move.w  (a1)+,d0
                beq.s   Boss_LovePenguinUpdatePartAnglesReturn
                lea     -2(a1,d0.w),a0
                move.w  (a0)+,d3
Boss_LovePenguinInterpolatePartAngle:                   ; was: loc_4152A
                move.w  (a0)+,d0
                bmi.s   Boss_LovePenguinAdvancePartAngleSlot
                ext.w   d0
                add.w   d0,d0
                sub.w   $56(a4),d0
                asr.w   #3,d0
                add.w   d0,$56(a4)
Boss_LovePenguinAdvancePartAngleSlot:                   ; was: loc_4153C
                lea     $60(a4),a4
                dbf     d3,Boss_LovePenguinInterpolatePartAngle
                bra.s   Boss_LovePenguinReadAngleSequence
; ---------------------------------------------------------------------------
Boss_LovePenguinUpdatePartAnglesReturn:                 ; was: locret_41546
                rts
; End of function Boss_LovePenguinUpdatePartAngles
; ---------------------------------------------------------------------------
Boss_LovePenguinPartAnimationMappings:
                dc.l    Boss_LovePenguinPartAnimationMapping0
                dc.l    Boss_LovePenguinPartAnimationMapping1
                dc.l    Boss_LovePenguinPartAnimationMapping2
                dc.l    Boss_LovePenguinPartAnimationMapping3
                dc.l    Boss_LovePenguinPartAnimationMapping4
                dc.l    Boss_LovePenguinPartAnimationMapping5
                dc.l    Boss_LovePenguinPartAnimationMapping6
                dc.l    Boss_LovePenguinPartAnimationMapping7
Boss_LovePenguinBodyPartInitTable:                      ; was: word_41568
                                        ; Boss_LovePenguinUpdateGraphics:Boss_LovePenguinUpdateBodyGraphics   o
; The constructor consumes longwords. High bits carry control flags; pointer
; payloads must remain symbolic so relocation adjusts the low 24 bits
                dc.l    Boss_LovePenguinPartAnimationMapping6
                dc.l    $800000
                dc.l    $80000001
                dc.l    $20000000+Boss_LovePenguinEarlyFormPartMapping
                dc.l    $830140
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $4300A0
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $4A0000
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $610060
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $600060
                dc.l    $80000000
                dc.l    $80000001
                dc.l    $20000000+Boss_LovePenguinEarlyFormPartMapping
                dc.l    $830160
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $430070
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $4A0000
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $610050
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $600050
                dc.l    $80000000
                dc.l    $80000001
                dc.l    $20000000+Boss_LovePenguinEarlyFormPartMapping
                dc.l    $830180
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $430060
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $4A0000
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $610060
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $600060
                dc.l    $80000000
                dc.l    $80000001
                dc.l    $20000000+Boss_LovePenguinEarlyFormPartMapping
                dc.l    $8301A0
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $430030
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $4A0000
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $610050
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $600050
                dc.l    $80000000
                dc.l    $80000001
                dc.l    $20000000+Boss_LovePenguinEarlyFormPartMapping
                dc.l    $A30020
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $43FFB0
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $4A0000
                dc.l    $60000000+Boss_LovePenguinPartAnimationMappings
                dc.l    $49FFA0
                dc.l    $80000000
                dc.l    $80000000
Boss_LovePenguinBodyPartAngleSequences:
                binclude "data/other/entity_type_1c0_body_part_angle_sequences.bin"  ; was: word_4165C
Boss_LovePenguinBodyPartAngleSequences_End:             ; was: word_4165C_End

; Initializes boss body part sprites from pointer table
Boss_LovePenguinInitBodyParts:                          ; was: sub_417D8
                                        ; Boss_LovePenguinSecondFormLoadGraphicsState+2E   p
                clr.w   d7
                movea.l a5,a3
                clr.l   -(sp)
                move.w  $E(a5),d5
Boss_LovePenguinReadBodyPartDescriptor:                 ; was: loc_417E2
                                        ; Boss_LovePenguinInitBodyParts+20   j
                move.l  (a1)+,d4
                bpl.s   Boss_LovePenguinInitializeBodyPart
                andi.l  #$7FFFFFFF,d4
                beq.s   Boss_LovePenguinFinishBodyPartChain
                move.l  a5,-(sp)
                bra.s   Boss_LovePenguinReadBodyPartDescriptor
; ---------------------------------------------------------------------------
Boss_LovePenguinFinishBodyPartChain:                    ; was: loc_417F2
                move.l  (sp)+,d0
                beq.s   Boss_LovePenguinFinishBodyPartInitialization
                movea.l d0,a5
                bra.s   Boss_LovePenguinReadBodyPartDescriptor
; ---------------------------------------------------------------------------
Boss_LovePenguinInitializeBodyPart:                     ; was: loc_417FA
                move.w  d5,$E(a4)
                move.b  #$C0,$20(a4)
                bclr    #$1E,d4
                bne.s   Boss_LovePenguinStorePartAnimationMappings
                move.l  d4,8(a4)
                clr.l   $50(a4)
                bra.s   Boss_LovePenguinConfigureBodyPart
; ---------------------------------------------------------------------------
Boss_LovePenguinStorePartAnimationMappings:             ; was: loc_41814
                move.l  d4,$50(a4)
Boss_LovePenguinConfigureBodyPart:                      ; was: loc_41818
                swap    d4
                andi.w  #$FF00,d4
                asl.w   #2,d4
                or.w    d4,$E(a4)
                move.w  #$C000,2(a4)
                move.w  (a1)+,$4C(a4)
                move.b  $4D(a4),d0
                andi.b  #3,d0
                asl.b   #2,d0
                add.b   d0,$20(a4)
                move.w  (a1)+,$56(a4)
                move.w  a5,$4E(a4)
                addq.w  #1,d7
                move.w  #$10,(a4)
                lea     (a4),a5
                lea     $60(a4),a4
                bra.s   Boss_LovePenguinReadBodyPartDescriptor
; ---------------------------------------------------------------------------
Boss_LovePenguinFinishBodyPartInitialization:           ; was: loc_41852
                move.w  d7,(LovePenguinBodyPartCount).w
                lea     (a3),a5
                clr.w   $4E(a5)
                rts
; End of function Boss_LovePenguinInitBodyParts
; Updates positions of all boss body parts using sine/cosine
Boss_LovePenguinUpdateBodyPartPositions:                ; was: sub_4185E
                                        ; Boss_LovePenguinSecondFormUpdate+78   p
                move.w  (LovePenguinBodyPartCount).w,d7
                subq.w  #1,d7
                lea     $60(a5),a4
                movea.l #Math_SineTable,a2
                movem.l a5,-(sp)
                btst    #3,$E(a5)
                lea     Boss_LovePenguinApplyParentOffset(pc),a5
                beq.s   Boss_LovePenguinUpdateBodyPart
                lea     Boss_LovePenguinFlipHorizontal(pc),a5
Boss_LovePenguinUpdateBodyPart:                         ; was: loc_41882
                                        ; Boss_LovePenguinApplyParentOffset+18   j
                andi.w  #$F7FF,$E(a4)
                move.w  $56(a4),d6
                lea     (a4),a0
Boss_LovePenguinAccumulateParentAngles:                 ; was: loc_4188E
                move.w  $4E(a0),d0
                beq.s   Boss_LovePenguinSelectPartMapping
                movea.w d0,a0
                add.w   $56(a0),d6
                bra.s   Boss_LovePenguinAccumulateParentAngles
; ---------------------------------------------------------------------------
Boss_LovePenguinSelectPartMapping:                      ; was: loc_4189C
                move.l  $50(a4),d0
                beq.s   Boss_LovePenguinCalculatePartPosition
                movea.l d0,a1
                move.w  d6,d1
                move.w  #$F8,d0
                sub.w   d1,d0
                lsr.w   #3,d0
                andi.w  #$1C,d0
                move.l  (a1,d0.w),8(a4)
Boss_LovePenguinCalculatePartPosition:                  ; was: loc_418B8
                move.w  d6,d1
                andi.w  #$1FE,d1
                move.w  (a2,d1.w),d0
                move.w  -$80(a2,d1.w),d1
                neg.w   d0
                muls.w  $4C(a4),d0
                muls.w  $4C(a4),d1
                jmp     (a5)
; End of function Boss_LovePenguinUpdateBodyPartPositions
; Negates values and flips horizontal sprite flag
Boss_LovePenguinFlipHorizontal:                         ; was: sub_418D2
                neg.l   d1
                eori.w  #$800,$E(a4)
; End of function Boss_LovePenguinFlipHorizontal
; Adds parent part position offsets to child body part
Boss_LovePenguinApplyParentOffset:                      ; was: sub_418DA
                movea.w $4E(a4),a3
                add.l   $10(a3),d1
                move.l  d1,$10(a4)
                add.l   $14(a3),d0
                move.l  d0,$14(a4)
                lea     $60(a4),a4
                dbf     d7,Boss_LovePenguinUpdateBodyPart
                movem.l (sp)+,a5
                rts
; End of function Boss_LovePenguinApplyParentOffset
