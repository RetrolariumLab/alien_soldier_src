; Handles type-$210 Viblack missiles through their currently inert update path
Projectile_ViblackMissileMain:                          ; was: sub_43930
                lea     (Entity_ObjectPool).w,a3
                lea     (SharedSceneDataBuffer).w,a4
                bsr.s   Projectile_ViblackMissileNoOp
                rts
; End of function Projectile_ViblackMissileMain
; ---------------------------------------------------------------------------
                dc.l    Projectile_ViblackMissileAnimationA
                dc.l    Projectile_ViblackMissileAnimationB

Projectile_ViblackMissileNoOp:                          ; was: nullsub_7
                rts
; End of function Projectile_ViblackMissileNoOp

; Dispatches the two equivalent states of the type-$210 missile spawner
Projectile_ViblackMissileSpawnerMain:
                movea.w 4(a5),a0                        ; was: sub_43946
                lea     Projectile_ViblackMissileSpawnerStates(pc,a0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_ViblackMissileSpawnerMain
; ---------------------------------------------------------------------------
Projectile_ViblackMissileSpawnerStates: dc.w    Projectile_SpawnViblackMissile-*  ; was: off_43952
                dc.w    Projectile_SpawnViblackMissile-*

; Spawns missile projectile at entity position
Projectile_SpawnViblackMissile:                         ; was: sub_43956
                                        ; ROM:00043954   o
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_SunsetStingReturn
                move.w  #$210,(a0)
                move.w  #$ED00,2(a0)
                move.w  #$6300,$E(a0)
                move.l  #Projectile_ViblackMissileAnimationB,8(a0)
                move.b  #$3C,$20(a0)                    ; '<'
                move.w  $10(a3),$10(a0)
                move.w  $14(a3),$14(a0)
                rts
; End of function Projectile_SpawnViblackMissile

; Main Viblack mini-boss handler
Boss_ViblackMain:                                       ; was: sub_4398C
                tst.w   4(a5)
                beq.w   Boss_ViblackStateDispatch
                addq.w  #1,$4E(a5)
                lea     Boss_ViblackPaletteCycleEntries(pc),a2
                nop
                jsr     (Gfx_UpdateBossPaletteColorFade).l
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   $10(a5),d0
                move.w  d0,$5E(a5)
                movea.w #(SecondaryEntityType-M68K_RAM),a4
                btst    #2,(BossColorEffectFlags).w
                bne.s   Boss_ViblackStateDispatch
                btst    #1,(BossColorEffectFlags).w
                bne.s   Boss_ViblackStateDispatch
                tst.w   (BossHealth).w
                beq.w   Boss_ViblackDefeatInit
; State machine dispatcher for Viblack boss
Boss_ViblackStateDispatch:                              ; was: loc_439CC
                                        ; Boss_ViblackMain+2E   j
                move.w  4(a5),d0
                movea.w Boss_ViblackStates(pc,d0.w),a0
                adda.l  #Boss_ViblackInit,a0
                jmp     (a0)
; End of function Boss_ViblackMain
; ---------------------------------------------------------------------------
Boss_ViblackStates: dc.w    Boss_ViblackInit-Boss_ViblackInit  ; was: off_439DC
                dc.w    Boss_ViblackIntroSetup-Boss_ViblackInit
                dc.w    Boss_ViblackEntranceDescentState-Boss_ViblackInit
                dc.w    Boss_ViblackFinishEntranceMotionState-Boss_ViblackInit
                dc.w    Boss_ViblackMoveToAttackTargetState-Boss_ViblackInit
                dc.w    Boss_ViblackChainAttackWaitState-Boss_ViblackInit
                dc.w    Boss_ViblackDefeatMoveToTargetState-Boss_ViblackInit
                dc.w    Boss_ViblackDefeatWaitState-Boss_ViblackInit
                dc.w    Boss_ViblackMoveToProjectileAttackTargetState-Boss_ViblackInit
                dc.w    Boss_ViblackRadialShotAttackState-Boss_ViblackInit
                dc.w    Boss_ViblackDefeatDescendState-Boss_ViblackInit
                dc.w    Boss_ViblackDefeatRiseState-Boss_ViblackInit
                dc.w    Boss_ViblackTransitionOscillationState-Boss_ViblackInit
                dc.w    Boss_ViblackTransitionTimerState-Boss_ViblackInit
                dc.w    Boss_ViblackStartFinalTransitionMotionState-Boss_ViblackInit
                dc.w    Boss_ViblackFinishTransitionState-Boss_ViblackInit

; Initializes Viblack mini-boss
Boss_ViblackInit:                                       ; was: sub_439FC
                                        ; ROM:Boss_ViblackStates   o
                addq.w  #2,4(a5)
                move.w  #$C2F8,(HUDDynamicStripTileAttr).w
                move.w  #$20,(HUDDynamicStripXOffset).w  ; ' '
                move.b  #4,(VDPReg11Shadow+1).w
                move.b  #8,(PlaneAScrollModeFlags).w
                move.b  #$20,(PlaneBScrollModeFlags).w  ; ' '
                move.w  #1,(PaletteEffectControl).w
                move.w  #$30,$48(a5)                    ; '0'
                move.b  #6,(BossColorEffectFlags).w
; Sets up intro graphics and position
Boss_ViblackIntroSetup:                                 ; was: loc_43A30
                subq.w  #1,$48(a5)
                bpl.w   Boss_ViblackStateReturn
                addq.w  #2,4(a5)
                move.w  #$D00,2(a5)
                move.w  #$5000,(BossHealth).w
                move.w  #$5000,(BossMaxHealth).w
                move.w  #$1C,$24(a5)
                move.b  #$10,$21(a5)
                move.b  #$80,$23(a5)
                move.l  #$F010F010,$28(a5)
                move.w  (PlayerXPosition).w,$10(a5)
                move.w  #$7C,$14(a5)                    ; '|'
                move.w  #8,$1C(a5)
                move.w  #$10,(a4)
                clr.w   2(a4)
                move.b  #$20,$21(a4)                    ; ' '
                move.w  #4,$46(a4)
                move.l  #$FF770088,$28(a4)
                lea     (Boss_ViblackIntroPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Boss_ViblackPaletteCycleEntries(pc),a2
                nop
                jsr     (Gfx_ClearColorFadeState).l
                lea     Boss_ViblackTileLoadCommand(pc),a0
                nop
                move.w  #$8000,d0
                jsr     (Gfx_AdjustSelectedTileBlocks).l
                movea.l #(LargeTilemapPage2+$520),a0
                move.w  #$2000,d0
                moveq   #$49,d7                         ; 'I'
                jsr     (Gfx_AdjustTileIndexRows).l
                lea     Boss_ViblackIndexedRowTransferDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
                bra.w   Boss_ViblackBuildScrollProfile
; End of function Boss_ViblackInit
; ---------------------------------------------------------------------------
Boss_ViblackTileLoadCommand:                dc.w    $4000, $8E8F, $9091, $9293, $9899, $9A9B, $9C9D, $A2FF  ; was: word_43AE0
Boss_ViblackIndexedRowTransferDescriptor:   dc.w    $6000, $4000, $901, $8E8F, $9091, $9293, $9899, $9A9B, 0, 0, $9C9D, 0, 0  ; was: word_43AF0
Boss_ViblackPaletteCycleEntries:            dc.w    $D, $E302, $E304, $E306, $E30C, $E30A, $E30C, $E30E, $E310, $E312, $E314, $E316, $E318, $E31A, $E31E  ; was: word_43B0A
                                        ; Boss_ViblackInit+A6   o

; Descends toward the stage-surface threshold and prepares the active arena
Boss_ViblackEntranceDescentState:                       ; was: sub_43B28
                bsr.w   Sound_ViblackPeriodic
                bsr.w   Boss_ViblackUpdateScrollAndCompanion
                subi.l  #$2000,$1C(a5)
                move.w  (PlayerYPosition).w,d0
                sub.w   $14(a5),d0
                cmpi.w  #$20,d0                         ; ' '
                bpl.s   Boss_ViblackEntranceDescentReturn
                addq.w  #2,4(a5)
                move.l  #$30000,$1C(a5)
                move.w  #$30,(PlayerScriptStateOffset).w  ; '0'
                bset    #5,(PlayerRestrictionFlags).w
                bset    #4,(PlayerSpriteAttributes).w
                jsr     (Sys_ClearObjectBlocks16).l
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.w  #4,(PlaneAShakeLevel).w
                move.b  #$DA,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.s   Boss_ViblackUpdateStageSurfaceReference
; ---------------------------------------------------------------------------
Boss_ViblackEntranceDescentReturn:                      ; was: locret_43B82
                rts
; End of function Boss_ViblackEntranceDescentState
; Continues entrance acceleration until the active battle state is ready
Boss_ViblackFinishEntranceMotionState:                  ; was: sub_43B84
                bsr.w   Sound_ViblackPeriodic
                bsr.w   Boss_ViblackUpdateScrollAndCompanion
                subi.l  #$2800,$1C(a5)
                bpl.s   Boss_ViblackUpdateStageSurfaceReference
                cmpi.w  #$FFFA,$1C(a5)
                bpl.s   Boss_ViblackUpdateStageSurfaceReference
                addq.w  #2,4(a5)
                addq.w  #2,(StageStateOffset).w
                move.w  #$C,$5A(a5)
                move.w  #$FFFF,$50(a5)
                move.w  #$780,$52(a5)
                move.w  #$C8,$54(a5)
                clr.b   (BossColorEffectFlags).w
                clr.w   (PlayerScriptStateOffset).w
                bclr    #5,(PlayerRestrictionFlags).w
                addq.w  #2,(PlayerStateOffset).w
Boss_ViblackUpdateStageSurfaceReference:                ; was: loc_43BD0
                                        ; Boss_ViblackFinishEntranceMotionState+10   j
                movea.w #(SecondaryEntityType-M68K_RAM),a4
                move.w  $14(a4),d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,(PlayerYPosition).w
                rts
; End of function Boss_ViblackFinishEntranceMotionState
; Moves to the next attack target and selects chain or radial-shot activity
Boss_ViblackMoveToAttackTargetState:                    ; was: sub_43BE2
                bsr.w   Boss_ViblackUpdateScrollAndCompanion
                bsr.w   Boss_ViblackSpawnSideShot
                bsr.w   Boss_ViblackMoveToTarget
                bne.s   Boss_ViblackStateReturn
                move.w  (RandomNumberState).w,d0
                subq.w  #1,$5A(a5)
                bpl.s   Boss_ViblackStartChainAttack
                move.w  #$10,4(a5)
                andi.w  #$F,d0
                addi.w  #8,d0
                move.w  d0,$5A(a5)
                move.w  #2,$50(a5)
                move.w  #$780,$52(a5)
                move.w  #$C8,$54(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ViblackStartChainAttack:                           ; was: loc_43C20
                addq.w  #2,4(a5)
                bsr.w   Boss_ViblackSpawnChain
                tst.w   (QuaternaryEntityType).w
                bne.s   Boss_ViblackSetRandomDelay
                move.w  #$60,$48(a5)                    ; '`'
                rts
; ---------------------------------------------------------------------------
; Sets random delay timer for actions
Boss_ViblackSetRandomDelay:                             ; was: loc_43C36
                move.w  (RandomNumberState).w,d0
                andi.w  #$40,d0                         ; '@'
                addq.w  #8,d0
                move.w  d0,$48(a5)
Boss_ViblackStateReturn:                                ; was: locret_43C44
                                        ; Boss_ViblackMoveToAttackTargetState+C   j
                rts
; End of function Boss_ViblackMoveToAttackTargetState
; Holds the chain-attack state until its delay expires
Boss_ViblackChainAttackWaitState:                       ; was: sub_43C46
                bsr.w   Boss_ViblackUpdateScrollAndCompanion
                bsr.w   Boss_ViblackSpawnSideShot
                subq.w  #1,$48(a5)
                bpl.s   Boss_ViblackChainAttackWaitReturn
Boss_ViblackSelectNextAttackTarget:                     ; was: loc_43C54
                move.w  #8,4(a5)
                bra.w   Boss_ViblackSetRandomTarget
; ---------------------------------------------------------------------------
Boss_ViblackChainAttackWaitReturn:                      ; was: locret_43C5E
                rts
; End of function Boss_ViblackChainAttackWaitState
; Moves to the fixed target used by the radial-shot phase
Boss_ViblackMoveToProjectileAttackTargetState:          ; was: sub_43C60
                bsr.w   Boss_ViblackUpdateScrollAndCompanion
                bsr.w   Boss_ViblackMoveToTarget
                bne.s   Boss_ViblackStateReturn
                addq.w  #2,4(a5)
                move.w  #$100,$48(a5)
                rts
; End of function Boss_ViblackMoveToProjectileAttackTargetState
; Emits mirrored shot pairs through the timer-indexed angle sequence
Boss_ViblackRadialShotAttackState:                      ; was: sub_43C76
                bsr.w   Boss_ViblackUpdateScrollAndCompanion
                subq.w  #1,$48(a5)
                bmi.w   Boss_ViblackSelectNextAttackTarget
                cmpi.w  #$20,$48(a5)                    ; ' '
                bmi.w   Boss_ViblackStateReturn
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_ViblackStateReturn
                lea     Boss_ViblackShotAngleSequence(pc),a1
                nop
                move.w  $48(a5),d0
                andi.w  #$F,d0
                moveq   #0,d6
                move.b  (a1,d0.w),d6
                asl.w   #1,d6
                moveq   #1,d5
Boss_ViblackSpawnShotPairLoop:                          ; was: loc_43CAE
                                        ; Boss_ViblackRadialShotAttackState+D6   j
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_ViblackStateReturn
                cmpi.w  #$A0,$48(a5)
                bpl.s   Boss_ViblackInitializeStandardRadialShot
                move.w  #$8008,d2
                moveq   #$24,d7                         ; '$'
                jsr     (Projectile_InitializeTwoSpeedShot).l
                bra.s   Boss_ViblackPositionRadialShot
; ---------------------------------------------------------------------------
Boss_ViblackInitializeStandardRadialShot:               ; was: loc_43CCE
                lea     (Boss_ViblackAndWolfGaropaShotSpriteFrames).l,a1
                jsr     (Sprite_InitFromTable).l
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d6.w),d0
                move.w  (a1,d6.w),d1
                ext.l   d0
                ext.l   d1
                asl.l   #3,d0
                asl.l   #3,d1
                move.l  d0,$1C(a0)
                move.l  d1,$18(a0)
Boss_ViblackPositionRadialShot:                         ; was: loc_43CF8
                move.w  $10(a5),d0
                tst.w   d5
                beq.s   Boss_ViblackPositionRightRadialShot
                subi.w  #$1C,d0
                move.w  d6,d1
                move.w  #$100,d6
                sub.w   d1,d6
                bra.s   Boss_ViblackPositionRadialShotOnSurface
; ---------------------------------------------------------------------------
Boss_ViblackPositionRightRadialShot:                    ; was: loc_43D0E
                addi.w  #$1C,d0
                bset    #3,$E(a0)
Boss_ViblackPositionRadialShotOnSurface:                ; was: loc_43D18
                move.w  d0,$10(a0)
                subi.w  #$80,d0
                bmi.s   Boss_ViblackDisableOutOfRangeRadialShot
                cmpi.w  #$140,d0
                bpl.s   Boss_ViblackDisableOutOfRangeRadialShot
                asr.w   #3,d0
                andi.w  #$FFFE,d0
                addi.w  #-$6B80,d0
                movea.w d0,a1
                move.w  (a1),d0
                neg.w   d0
                subi.w  #$160,d0
                move.w  d0,$14(a0)
                dbf     d5,Boss_ViblackSpawnShotPairLoop
                rts
; ---------------------------------------------------------------------------
Boss_ViblackDisableOutOfRangeRadialShot:                ; was: loc_43D46
                                        ; Boss_ViblackRadialShotAttackState+B0   j
                bset    #4,2(a0)
                dbf     d5,Boss_ViblackSpawnShotPairLoop
                rts
; End of function Boss_ViblackRadialShotAttackState
; ---------------------------------------------------------------------------
Boss_ViblackShotAngleSequence:  dc.b    $50, $4C, $48, $44, $40, $3C, $38, $34, $30, $34, $38, $3C, $40, $44, $48, $4C  ; was: byte_43D52

; Initializes defeat sequence
Boss_ViblackDefeatInit:                                 ; was: sub_43D62
                move.b  #1,(SoundFadeOutDelay).w
                move.w  #$C,4(a5)
                bset    #0,(StageTimerPauseFlag).w
                move.b  #2,(BossColorEffectFlags).w
                clr.b   $21(a5)
                move.w  #$80,(StageSpawnCountdown).w
                move.w  #$780,$52(a5)
                move.w  #$C8,$54(a5)
; Moves Viblack to the fixed defeat-transition target
Boss_ViblackDefeatMoveToTargetState:                    ; was: loc_43D90
                bsr.w   Boss_ViblackUpdateDefeatEffectsAndParticles
                bsr.w   Boss_ViblackMoveToTarget
                bne.s   Boss_ViblackDefeatMoveToTargetReturn
                addq.w  #2,4(a5)
                addq.w  #2,(StageStateOffset).w
                move.w  #$80,$48(a5)
Boss_ViblackDefeatMoveToTargetReturn:                   ; was: locret_43DA8
                rts
; End of function Boss_ViblackDefeatInit
; Waiting state with timer countdown
Boss_ViblackDefeatWaitState:                            ; was: sub_43DAA
                bsr.w   Boss_ViblackUpdateDefeatSoundAndParticles
                subq.w  #1,$48(a5)
                bpl.s   Boss_ViblackDefeatWaitReturn
                move.w  #$14,4(a5)
                clr.w   (HUDDynamicStripXOffset).w
Boss_ViblackDefeatWaitReturn:                           ; was: locret_43DBE
                rts
; End of function Boss_ViblackDefeatWaitState
; Accelerates downward until Viblack reaches Y $100
Boss_ViblackDefeatDescendState:                         ; was: sub_43DC0
                bsr.w   Boss_ViblackUpdateDefeatSoundAndParticles
                addi.l  #$3000,$1C(a5)
                cmpi.w  #$100,$14(a5)
                bmi.s   Boss_ViblackDefeatDescendReturn
                addq.w  #2,4(a5)
                addq.w  #2,(StageStateOffset).w
Boss_ViblackDefeatDescendReturn:                        ; was: locret_43DDC
                rts
; End of function Boss_ViblackDefeatDescendState
; Accelerates upward to Y $C8 and prepares the transition companion
Boss_ViblackDefeatRiseState:                            ; was: sub_43DDE
                bsr.w   Boss_ViblackUpdateDefeatSoundAndParticles
                subi.l  #$3000,$1C(a5)
                cmpi.w  #$C8,$14(a5)
                bpl.w   Boss_ViblackStateReturn
                addq.w  #2,4(a5)
                clr.l   $1C(a5)
                clr.w   $52(a5)
                move.w  #$FFF0,$54(a5)
                btst    #4,(PlayerSpriteAttributes).w
                beq.s   Boss_ViblackInitializeTransitionCompanion
                move.w  #$4C,(PlayerStateOffset).w      ; 'L'
                move.w  #$FFF8,(PlayerYVelocity).w
                jsr     (Sys_ClearObjectBlocks16).l
Boss_ViblackInitializeTransitionCompanion:              ; was: loc_43E20
                move.w  #$320,(SecondaryEntityType).w
                clr.w   (SecondaryEntityFlags).w
                move.w  #2,(SecondaryEntityWork46).w
                clr.l   (SecondaryEntityWork5C).w
                move.b  #2,(PlaneAScrollModeFlags).w
                move.b  #$4D,d0                         ; 'M'
                jmp     (Sound_QueueSFXRequest).l
; End of function Boss_ViblackDefeatRiseState
; Oscillates transition displacement and writes paired transition offsets
Boss_ViblackTransitionOscillationState:                 ; was: sub_43E44
                clr.w   $4E(a5)
                bsr.w   Boss_ViblackUpdateTransitionEffects
                move.w  $52(a5),d1
                move.w  $54(a5),d0
                beq.s   Boss_ViblackHandleSettledTransitionMotion
                bpl.s   Boss_ViblackClampPositiveTransitionTarget
Boss_ViblackClampNegativeTransitionTarget:              ; was: loc_43E58
                                        ; Boss_ViblackFinishTransitionState+16   j
                cmpi.w  #$FFF0,d0
                bpl.s   Boss_ViblackCompareNegativeTransitionDisplacement
                moveq   #$FFFFFFF0,d0
Boss_ViblackCompareNegativeTransitionDisplacement:      ; was: loc_43E60
                cmp.w   d1,d0
                beq.s   Boss_ViblackReverseNegativeTransitionMotion
                bpl.s   Boss_ViblackReverseNegativeTransitionMotion
                subq.w  #4,$52(a5)
                subq.w  #4,d1
                bra.s   Boss_ViblackWriteTransitionOffsetPairs
; ---------------------------------------------------------------------------
Boss_ViblackReverseNegativeTransitionMotion:            ; was: loc_43E6E
                                        ; Boss_ViblackTransitionOscillationState+20   j
                neg.w   $54(a5)
                subq.w  #2,$54(a5)
                bra.s   Boss_ViblackReloadTransitionDisplacement
; ---------------------------------------------------------------------------
Boss_ViblackClampPositiveTransitionTarget:              ; was: loc_43E78
                                        ; Boss_ViblackTransitionTimerState+6C   j
                cmpi.w  #$10,d0
                bmi.s   Boss_ViblackComparePositiveTransitionDisplacement
                moveq   #$10,d0
Boss_ViblackComparePositiveTransitionDisplacement:      ; was: loc_43E80
                cmp.w   d1,d0
                beq.s   Boss_ViblackReversePositiveTransitionMotion
                bmi.s   Boss_ViblackReversePositiveTransitionMotion
                addq.w  #4,$52(a5)
                addq.w  #4,d1
                bra.s   Boss_ViblackWriteTransitionOffsetPairs
; ---------------------------------------------------------------------------
Boss_ViblackReversePositiveTransitionMotion:            ; was: loc_43E8E
                                        ; Boss_ViblackTransitionOscillationState+40   j
                neg.w   $54(a5)
                addq.w  #2,$54(a5)
                bra.s   Boss_ViblackReloadTransitionDisplacement
; ---------------------------------------------------------------------------
Boss_ViblackHandleSettledTransitionMotion:              ; was: loc_43E98
                tst.w   d1
                bpl.s   Boss_ViblackAdvanceToTransitionTimer
                clr.w   $52(a5)
                moveq   #0,d1
                bra.s   Boss_ViblackWriteTransitionOffsetPairs
; ---------------------------------------------------------------------------
Boss_ViblackAdvanceToTransitionTimer:                   ; was: loc_43EA4
                addq.w  #2,4(a5)
                move.w  #$140,$48(a5)
                rts
; ---------------------------------------------------------------------------
Boss_ViblackReloadTransitionDisplacement:               ; was: loc_43EB0
                                        ; Boss_ViblackTransitionOscillationState+52   j
                move.w  $52(a5),d1
Boss_ViblackWriteTransitionOffsetPairs:                 ; was: loc_43EB4
                                        ; Boss_ViblackTransitionOscillationState+48   j
                asr.w   #1,d1
                addi.w  #$C7,d1
                move.w  d1,$14(a5)
                move.w  (PrimaryCameraYPosition).w,d0
                neg.w   d0
                moveq   #$18,d1
                move.w  $52(a5),d2
                neg.w   d2
                asl.w   #4,d2
                moveq   #9,d7
                movea.w #(VScrollPlaneAColumn9-M68K_RAM),a0
                movea.w #(VScrollPlaneAColumn10-M68K_RAM),a1
Boss_ViblackWriteTransitionOffsetPairsLoop:             ; was: loc_43ED8
                move.w  d2,d3
                ext.l   d3
                divs.w  d1,d3
                add.w   d0,d3
                move.w  d3,(a0)
                move.w  d3,(a1)
                subq.w  #4,a0
                addq.w  #4,a1
                addq.w  #3,d1
                dbf     d7,Boss_ViblackWriteTransitionOffsetPairsLoop
                rts
; End of function Boss_ViblackTransitionOscillationState
