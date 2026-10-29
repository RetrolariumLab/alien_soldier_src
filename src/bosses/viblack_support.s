Boss_ViblackTransitionTimerState:                       ; was: sub_43EF0
                subq.w  #1,$48(a5)
                bpl.s   Boss_ViblackUpdateTransitionTimerMotion
                addq.w  #2,4(a5)
                bclr    #1,(PaletteFadeControlFlags).w
                movea.w #(TertiaryEntityType-M68K_RAM),a0
                lea     (Boss_BackStringerAssetSet).l,a1
                jsr     (Boss_LoadAssetSetAtObject).l
Boss_ViblackUpdateTransitionTimerMotion:                ; was: loc_43F10
                move.w  $48(a5),d0
                cmpi.w  #$100,d0
                bne.s   Boss_ViblackCheckTransitionTimerThresholds
                jsr     (Stage_TransitionToNextPhase).l
                subq.w  #2,(StageStateOffset).w
                move.w  #$FFF0,$54(a5)
                bra.s   Boss_ViblackUpdateTransitionMotion
; ---------------------------------------------------------------------------
Boss_ViblackCheckTransitionTimerThresholds:             ; was: loc_43F2C
                bpl.s   Boss_ViblackResetTransitionScrollPhase
                cmpi.w  #$E0,d0
                bpl.s   Boss_ViblackUpdateTransitionMotion
                cmpi.w  #$80,d0
                bne.s   Boss_ViblackCheckTransitionScrollReset
                move.w  #$FFE8,$54(a5)
                bra.s   Boss_ViblackUpdateTransitionMotion
; ---------------------------------------------------------------------------
Boss_ViblackCheckTransitionScrollReset:                 ; was: loc_43F42
                bpl.s   Boss_ViblackResetTransitionScrollPhase
                cmpi.w  #$40,d0                         ; '@'
                bpl.s   Boss_ViblackUpdateTransitionMotion
Boss_ViblackResetTransitionScrollPhase:                 ; was: loc_43F4A
                                        ; Boss_ViblackTransitionTimerState:Boss_ViblackCheckTransitionScrollReset   j
                clr.w   $4E(a5)
Boss_ViblackUpdateTransitionMotion:                     ; was: loc_43F4E
                                        ; Boss_ViblackTransitionTimerState+42   j
                bsr.w   Boss_ViblackUpdateTransitionEffects
                move.w  $52(a5),d1
                move.w  $54(a5),d0
                beq.s   Boss_ViblackTransitionTimerReturn
                bpl.w   Boss_ViblackClampPositiveTransitionTarget
                bra.w   Boss_ViblackClampNegativeTransitionTarget
; ---------------------------------------------------------------------------
Boss_ViblackTransitionTimerReturn:                      ; was: locret_43F64
                rts
; End of function Boss_ViblackTransitionTimerState
; Seeds the final transition motion
Boss_ViblackStartFinalTransitionMotionState:            ; was: sub_43F66
                move.w  #$FFB4,$54(a5)
                clr.w   $4E(a5)
                bra.w   Boss_ViblackUpdateTransitionEffects
; End of function Boss_ViblackStartFinalTransitionMotionState
; Emits debris until the motion settles, then restores stage state
Boss_ViblackFinishTransitionState:                      ; was: sub_43F74
                bsr.w   Boss_ViblackSpawnTransitionDebris
                bsr.w   Boss_ViblackUpdateScrollAndPalette
                move.w  $52(a5),d1
                move.w  $54(a5),d0
                beq.s   Boss_ViblackCompleteStageTransition
                bpl.w   Boss_ViblackClampPositiveTransitionTarget
                bra.w   Boss_ViblackClampNegativeTransitionTarget
; ---------------------------------------------------------------------------
Boss_ViblackCompleteStageTransition:                    ; was: loc_43F8E
                bsr.w   Boss_ViblackWriteTransitionOffsetPairs
                move.w  #$1000,2(a5)
                move.l  #$60A45441,d0
                jsr     (Tilemap_QueueFourRowsFromPackedCommand).l
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                lea     (Boss_ViblackPostBattlePaletteCommand).l,a0
                jmp     Gfx_LoadPaletteCommand
; End of function Boss_ViblackFinishTransitionState
; Plays the periodic effect sound and emits a defeat particle
Boss_ViblackUpdateDefeatSoundAndParticles:              ; was: sub_43FBC
                                        ; Boss_ViblackDefeatDescendState   p
                bsr.w   Sound_ViblackPeriodic
                bsr.w   Boss_ViblackSpawnDefeatParticle
; End of function Boss_ViblackUpdateDefeatSoundAndParticles
; Updates the scroll-linked object, palette effect, and nearby particles
Boss_ViblackUpdateDefeatEffectsAndParticles:            ; was: sub_43FC4
                bsr.s   Boss_ViblackUpdateScrollAndCompanion
                lea     Boss_ViblackPaletteCycleEntries(pc),a4
                jsr     (Gfx_UpdateRandomizedPaletteEntryList).l
                bra.w   Boss_ViblackSpawnNearbyDefeatParticle
; End of function Boss_ViblackUpdateDefeatEffectsAndParticles
; Emits a wide particle, updates scroll state, and applies the palette effect
Boss_ViblackUpdateTransitionEffects:                    ; was: sub_43FD4
                                        ; Boss_ViblackTransitionTimerState:Boss_ViblackUpdateTransitionMotion   p
                bsr.w   Boss_ViblackSpawnWideDefeatParticle
Boss_ViblackUpdateScrollAndPalette:                     ; was: loc_43FD8
                bsr.s   Boss_ViblackUpdateScrollAndCompanion
                lea     Boss_ViblackPaletteCycleEntries(pc),a4
                jmp     (Gfx_UpdateRandomizedPaletteEntryList).l
; End of function Boss_ViblackUpdateTransitionEffects
; Rebuilds the scroll profile and positions the companion object on it
Boss_ViblackUpdateScrollAndCompanion:                   ; was: sub_43FE4
                                        ; Boss_ViblackFinishEntranceMotionState+4   p
                bsr.s   Boss_ViblackBuildScrollProfile
                bra.w   Boss_ViblackPositionCompanionOnScrollProfile
; End of function Boss_ViblackUpdateScrollAndCompanion
; Shifts the prior vertical-scroll samples and builds the next clipped profile
Boss_ViblackBuildScrollProfile:                         ; was: sub_43FEA
                                        ; Boss_ViblackUpdateScrollAndCompanion   p
                movea.w #(ViblackScrollSamples-M68K_RAM),a0
                movea.w #(VerticalScrollProfile-M68K_RAM),a1
                moveq   #9,d7
Boss_ViblackCopyPreviousScrollSamplesLoop:              ; was: loc_43FF4
                move.l  (a0)+,(a1)+
                dbf     d7,Boss_ViblackCopyPreviousScrollSamplesLoop
                movea.w #(ViblackScrollSamples-M68K_RAM),a0
                move.w  #0,d0
                moveq   #$13,d7
Boss_ViblackClearNextScrollSamplesLoop:                 ; was: loc_44004
                move.w  d0,(a0)+
                dbf     d7,Boss_ViblackClearNextScrollSamplesLoop
                moveq   #0,d0
                move.w  #$120,d0
                sub.w   $10(a5),d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  #$168,d0
                add.w   $14(a5),d0
                move.w  d0,(SecondaryCameraYPos).w
                neg.w   d0
                movea.w #(SharedScratchLong4-M68K_RAM),a0
                movea.w #(SharedScratchLong6-M68K_RAM),a1
                lea     Boss_ViblackScrollProfileSteps(pc),a2
                nop
                move.w  $4E(a5),d1
                asl.w   #2,d1
                andi.w  #$1C,d1
                move.l  (a2,d1.w),d1
                moveq   #7,d7
Boss_ViblackBuildUpperScrollProfileLoop:                ; was: loc_44044
                swap    d0
                add.l   d1,d0
                swap    d0
                move.w  d0,-(a0)
                move.w  d0,(a1)+
                dbf     d7,Boss_ViblackBuildUpperScrollProfileLoop
                movea.w #(SharedScratchLong4-M68K_RAM),a0
                movea.w #(SharedScratchLong6-M68K_RAM),a1
                moveq   #0,d0
                move.w  (SecondaryCameraYPos).w,d0
                neg.w   d0
                moveq   #1,d7
Boss_ViblackBuildLowerScrollProfileLoop:                ; was: loc_44064
                swap    d0
                sub.l   d1,d0
                swap    d0
                move.w  d0,(a0)+
                move.w  d0,-(a1)
                dbf     d7,Boss_ViblackBuildLowerScrollProfileLoop
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                movea.w #(ViblackScrollSamples-M68K_RAM),a1
                moveq   #$13,d7
                move.w  (SecondaryCameraXPos).w,d0
                addi.w  #$F,d0
                move.w  d0,d1
                asr.w   #4,d1
                bpl.s   Boss_ViblackClipScrollProfileRight
                add.w   d1,d7
                bmi.s   Boss_ViblackBuildScrollProfileReturn
                move.w  d0,d1
                asr.w   #3,d1
                andi.w  #$FFFE,d1
                suba.w  d1,a1
                bra.s   Boss_ViblackCopyVisibleScrollProfile
; ---------------------------------------------------------------------------
Boss_ViblackClipScrollProfileRight:                     ; was: loc_4409A
                sub.w   d1,d7
                bmi.s   Boss_ViblackBuildScrollProfileReturn
                move.w  d0,d1
                asr.w   #3,d1
                andi.w  #$FFFE,d1
                adda.w  d1,a0
; Copies the visible section of the generated profile into the next scroll buffer
Boss_ViblackCopyVisibleScrollProfile:                   ; was: loc_440A8
                                        ; Boss_ViblackBuildScrollProfile+C0   j
                move.w  (a0)+,(a1)+
                dbf     d7,Boss_ViblackCopyVisibleScrollProfile
Boss_ViblackBuildScrollProfileReturn:                   ; was: locret_440AE
                                        ; Boss_ViblackBuildScrollProfile+B2   j
                rts
; End of function Boss_ViblackBuildScrollProfile
; ---------------------------------------------------------------------------
Boss_ViblackScrollProfileSteps: dc.l    0, $FFFE8000, $FFFE0000, $FFFF0000  ; was: dword_440B0
                dc.l    0, $18000, $20000, $10000

; Positions the companion object on the generated vertical-scroll profile
Boss_ViblackPositionCompanionOnScrollProfile:           ; was: sub_440D0
                move.w  $10(a5),$10(a4)
                move.w  (PlayerXPosition).w,d0
                subi.w  #$80,d0
                bmi.s   Boss_ViblackPositionCompanionReturn
                cmpi.w  #$140,d0
                bpl.s   Boss_ViblackPositionCompanionReturn
                asr.w   #3,d0
                andi.w  #$FFFE,d0
                addi.w  #-$6B80,d0
                movea.w d0,a0
                move.w  (a0),d0
                neg.w   d0
                subi.w  #$168,d0
                move.w  d0,$14(a4)
Boss_ViblackPositionCompanionReturn:                    ; was: locret_440FE
                                        ; Boss_ViblackPositionCompanionOnScrollProfile+14   j
                rts
; End of function Boss_ViblackPositionCompanionOnScrollProfile
; Sets random target position
Boss_ViblackSetRandomTarget:                            ; was: sub_44100
                move.w  #2,$50(a5)
                move.b  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addi.w  #$740,d0
                move.w  d0,$52(a5)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$1F,d0
                addi.w  #$E0,d0
                move.w  d0,$54(a5)
                rts
; End of function Boss_ViblackSetRandomTarget
; Emits a type-$88 defeat particle near Viblack
Boss_ViblackSpawnNearbyDefeatParticle:                  ; was: sub_44128
                btst    #0,(FrameCounter+1).w
                bne.s   Boss_ViblackSpawnNearbyDefeatParticleReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ViblackSpawnNearbyDefeatParticleReturn
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                addq.w  #8,d0
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$1F,d0
                subi.w  #$10,d0
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.l  #Effect_SpriteAnimation05,8(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Boss_ViblackInitializeNearbyDefeatParticle
                move.l  #Effect_SpriteAnimation00,8(a0)
Boss_ViblackInitializeNearbyDefeatParticle:             ; was: loc_44178
                jsr     (Projectile_InitType88).l
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                addq.w  #5,d0
                move.w  d0,$1C(a0)
Boss_ViblackSpawnNearbyDefeatParticleReturn:            ; was: locret_4418C
                                        ; Boss_ViblackSpawnNearbyDefeatParticle+E   j
                rts
; End of function Boss_ViblackSpawnNearbyDefeatParticle
; Emits a type-$88 defeat particle across a wider horizontal range
Boss_ViblackSpawnWideDefeatParticle:                    ; was: sub_4418E
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_ViblackSpawnWideDefeatParticleReturn
                move.b  (RandomNumberState).w,d0
                andi.w  #$F,d0
                subq.w  #8,d0
                add.w   $14(a5),d0
                move.w  d0,$14(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.l  #Effect_SpriteAnimation18,8(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                beq.s   Boss_ViblackSelectWideDefeatParticleVelocity
                move.l  #Effect_SpriteAnimation04,8(a0)
Boss_ViblackSelectWideDefeatParticleVelocity:           ; was: loc_441D6
                move.w  (RandomNumberState).w,d0
                andi.w  #1,d0
                subq.w  #3,d0
                move.w  d0,$1C(a0)
                jmp     Projectile_InitType88
; ---------------------------------------------------------------------------
Boss_ViblackSpawnWideDefeatParticleReturn:              ; was: locret_441EA
                rts
; End of function Boss_ViblackSpawnWideDefeatParticle
; Emits transition debris or a type-$88 particle near Viblack
Boss_ViblackSpawnTransitionDebris:                      ; was: sub_441EC
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_ViblackSpawnTransitionDebrisReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Boss_ViblackSpawnTransitionDebrisReturn
                move.w  (RandomNumberState).w,d0
                andi.w  #7,d0
                bne.s   Boss_ViblackInitializeTransitionParticle
                jsr     (Effect_InitDebrisSprite).l
                bra.w   Boss_ViblackPositionTransitionDebris
; ---------------------------------------------------------------------------
Boss_ViblackInitializeTransitionParticle:               ; was: loc_44212
                jsr     (Projectile_InitType88).l
                move.w  (RandomNumberState).w,d0
                ext.l   d0
                asl.l   #3,d0
                move.l  d0,$18(a0)
                move.l  #Effect_SpriteAnimation00,8(a0)
                move.w  #$FFFD,$1C(a0)
                btst    #0,(RandomNumberState).w
                beq.s   Boss_ViblackPositionTransitionDebris
                move.l  #Effect_SpriteAnimation18,8(a0)
                clr.w   $1C(a0)
Boss_ViblackPositionTransitionDebris:                   ; was: loc_44246
                                        ; Boss_ViblackSpawnTransitionDebris+4C   j
                move.b  (RandomNumberState+2).w,d0
                andi.w  #8,d0
                addi.w  #$C,d0
                move.b  d0,$20(a0)
                move.b  (RandomNumberState).w,d0
                move.b  (RandomNumberState+1).w,d1
                andi.w  #$F,d0
                andi.w  #7,d1
                subq.w  #8,d0
                subq.w  #8,d1
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
Boss_ViblackSpawnTransitionDebrisReturn:                ; was: locret_4427A
                                        ; Boss_ViblackSpawnTransitionDebris+10   j
                rts
; End of function Boss_ViblackSpawnTransitionDebris
; Emits one defeat sprite at a random screen position
Boss_ViblackSpawnDefeatParticle:                        ; was: sub_4427C
                btst    #0,(FrameCounter+1).w
                bne.w   Boss_ViblackStateReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_ViblackStateReturn
                move.b  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                addi.w  #$A0,d0
                move.w  d0,$10(a0)
                move.b  (RandomNumberState+1).w,d0
                andi.w  #$3F,d0                         ; '?'
                addi.w  #$A0,d0
                move.w  d0,$14(a0)
                lea     (Effect_SharedBurstParticleSpriteFrames).l,a1
                move.w  #9,$1C(a0)
                jmp     Sprite_InitFromTable
; End of function Boss_ViblackSpawnDefeatParticle
; Calculates movement toward target using arctan2
Boss_ViblackMoveToTarget:                               ; was: sub_442C2
                                        ; Boss_ViblackMoveToProjectileAttackTargetState+4   p
                move.w  $52(a5),d0
                move.w  $54(a5),d1
                sub.w   $5E(a5),d0
                sub.w   $14(a5),d1
                jsr     (Math_Arctan2Lookup).l
                asr.w   #7,d2
                andi.w  #$1FE,d2
                move.w  $50(a5),d3
                bmi.s   Boss_ViblackAccelerateTowardTarget
                cmpi.w  #6,d3
                bpl.s   Boss_ViblackCalculateTargetVelocity
Boss_ViblackAccelerateTowardTarget:                     ; was: loc_442EA
                addq.w  #2,d3
                move.w  d3,$50(a5)
Boss_ViblackCalculateTargetVelocity:                    ; was: loc_442F0
                lea     (Math_SineTable).l,a0
                move.w  Math_QuarterSineTable-Math_SineTable(a0,d2.w),d0
                move.w  (a0,d2.w),d1
                muls.w  d3,d0
                muls.w  d3,d1
                move.l  d0,$1C(a5)
                move.l  d1,$18(a5)
                move.w  $5E(a5),d2
                sub.w   $52(a5),d2
                bpl.s   Boss_ViblackCompareTargetXDistance
                neg.w   d2
Boss_ViblackCompareTargetXDistance:                     ; was: loc_44316
                cmpi.w  #2,d2
                beq.s   Boss_ViblackMeasureTargetYDistance
                bpl.s   Boss_ViblackMoveToTargetInProgress
Boss_ViblackMeasureTargetYDistance:                     ; was: loc_4431E
                move.w  $14(a5),d2
                sub.w   $54(a5),d2
                bpl.s   Boss_ViblackCompareTargetYDistance
                neg.w   d2
Boss_ViblackCompareTargetYDistance:                     ; was: loc_4432A
                cmpi.w  #2,d2
                beq.s   Boss_ViblackSnapToTarget
                bpl.s   Boss_ViblackMoveToTargetInProgress
Boss_ViblackSnapToTarget:                               ; was: loc_44332
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  $52(a5),d0
                sub.w   (PrimaryCameraXPosition).w,d0
                move.w  d0,$10(a5)
                move.w  $54(a5),$14(a5)
                moveq   #0,d0
                rts
; ---------------------------------------------------------------------------
Boss_ViblackMoveToTargetInProgress:                     ; was: loc_44350
                                        ; Boss_ViblackMoveToTarget+6E   j
                moveq   #1,d0
Boss_ViblackMoveToTargetReturn:                         ; was: locret_44352
                rts
; End of function Boss_ViblackMoveToTarget
; Plays Viblack sound effect every 4 frames
Sound_ViblackPeriodic:                                  ; was: sub_44354
                                        ; Boss_ViblackFinishEntranceMotionState   p
                move.w  (FrameCounter).w,d0
                andi.w  #3,d0
                bne.s   Boss_ViblackMoveToTargetReturn
                move.b  #$CD,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Sound_ViblackPeriodic
; Periodically spawns side shots from alternating horizontal positions
Boss_ViblackSpawnSideShot:                              ; was: sub_44368
                                        ; Boss_ViblackChainAttackWaitState+4   p
                move.w  (FrameCounter).w,d0
                andi.w  #$FF,d0
                cmpi.w  #$2F,d0                         ; '/'
                bpl.w   Boss_ViblackStateReturn
                andi.w  #$F,d0
                bne.w   Boss_ViblackStateReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_ViblackStateReturn
                move.w  #$6F0,d0
                btst    #0,(FrameCounter).w
                bne.s   Boss_ViblackSpawnSideShotAtSelectedX
                move.w  #$810,d0
Boss_ViblackSpawnSideShotAtSelectedX:                   ; was: loc_4439A
                sub.w   (PrimaryCameraXPosition).w,d0
                jmp     Projectile_InitViblackSideShot
; End of function Boss_ViblackSpawnSideShot
