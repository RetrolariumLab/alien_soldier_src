; Shared type-$3C4 Missiray falling shots and delayed rising-wave members
Projectile_InitMissirayFallingShot:                     ; was: sub_33956
                                        ; Segment_MissirayLaunchConfiguredProjectile+34   p
                move.b  #0,$47(a0)
                move.l  #Projectile_MissirayVerticalShotSpriteMapping00,8(a0)
                move.l  #$F010FE02,$2C(a0)
                move.l  #$F010F808,$28(a0)
                bra.s   Projectile_InitMissirayAndRisingShotCommon
; End of function Projectile_InitMissirayFallingShot
; Initializes a delayed rising-wave member
Projectile_InitRisingShotWaveMember:                    ; was: sub_33976
                                        ; Orphaned_RisingShotPairLaunch+22   p
                move.b  #1,$47(a0)
                move.l  #Projectile_MissirayVerticalShotSpriteMapping03,8(a0)
                move.l  #$E020FE02,$2C(a0)
                move.l  #$E020F808,$28(a0)
                move.w  d4,$48(a0)
Projectile_InitMissirayAndRisingShotCommon:             ; was: loc_33998
                move.w  #$3C4,(a0)
                move.w  #$400,$E(a0)
                cmpi.w  #$3E0,(Entity57Type).w
                bne.s   Projectile_InitMissirayAndRisingShotFinish
                ori.w   #$4000,$E(a0)
Projectile_InitMissirayAndRisingShotFinish:             ; was: loc_339B0
                move.w  #$CC00,2(a0)
                move.w  #$28,$24(a0)                    ; '('
                move.w  #$64,$26(a0)                    ; 'd'
                move.b  #$40,$20(a0)                    ; '@'
                clr.w   $C(a0)
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.l  d2,$58(a0)
                move.l  d3,$5C(a0)
                rts
; End of function Projectile_InitRisingShotWaveMember
; Handles collision and dispatches the shared type-$3C4 projectile states
Projectile_MissirayAndRisingShotMain:                   ; was: sub_339DE
                tst.w   4(a5)
                beq.s   Projectile_MissirayAndRisingShotDispatchState
                cmpi.w  #$E,4(a5)
                bcc.s   Projectile_MissirayAndRisingShotDispatchState
                cmpi.w  #$3E0,(Entity57Type).w
                bne.s   Projectile_MissirayAndRisingShotCheckCollision
                btst    #1,(BossColorEffectFlags).w
                bne.w   Projectile_MissirayAndRisingShotBeginImpact
                moveq   #0,d0
                move.b  $2C(a5),d0
                ext.w   d0
                add.w   $14(a5),d0
                cmp.w   (Entity57YPos).w,d0
                bgt.s   Projectile_MissirayAndRisingShotCheckCollision
                bset    #6,(Entity57CollisionFlags).w
                move.w  #$12,4(a5)
                clr.b   $21(a5)
                bra.s   Projectile_MissirayAndRisingShotDispatchState
; ---------------------------------------------------------------------------
Projectile_MissirayAndRisingShotCheckCollision:         ; was: loc_33A22
                                        ; Projectile_MissirayAndRisingShotMain+30   j
                bclr    #7,$22(a5)
                bne.s   Projectile_MissirayAndRisingShotBeginImpact
                tst.w   $24(a5)
                bpl.s   Projectile_MissirayAndRisingShotDispatchState
Projectile_MissirayAndRisingShotBeginImpact:            ; was: loc_33A30
                                        ; Projectile_MissirayAndRisingShotMain+4A   j
                move.b  #$30,d0                         ; '0'
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$E,4(a5)
                clr.b   $21(a5)
Projectile_MissirayAndRisingShotDispatchState:          ; was: loc_33A44
                                        ; Projectile_MissirayAndRisingShotMain+C   j
                move.w  4(a5),d0
                lea     Projectile_MissirayAndRisingShotStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_MissirayAndRisingShotMain
; ---------------------------------------------------------------------------
Projectile_MissirayAndRisingShotStates: dc.w    Projectile_MissirayAndRisingShotSelectVariant-*  ; was: off_33A50
                dc.w    Projectile_MissirayFallingShotInitMotion-*
                dc.w    Projectile_MissirayFallingShotApplyGravity-*
                dc.w    Projectile_MissirayFallingShotDescend-*
                dc.w    Projectile_MissirayFallingShotDecelerate-*
                dc.w    Projectile_RisingShotWait-*
                dc.w    Projectile_RisingShotRiseAndEmit-*
                dc.w    Projectile_Stage24RisingShotInitArc-*
                dc.w    Projectile_Stage24RisingShotUpdateArc-*
                dc.w    Projectile_Stage24RisingShotBeginTopEdgeBurst-*
                dc.w    Projectile_Stage24RisingShotEmitTopEdgeTrail-*

; Selects the falling-shot or rising-wave state path
Projectile_MissirayAndRisingShotSelectVariant:          ; was: sub_33A66
                tst.b   $47(a5)
                bne.s   Projectile_MissirayAndRisingShotSelectRisingWave
                addq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_MissirayAndRisingShotSelectRisingWave:       ; was: loc_33A72
                move.w  #$A,4(a5)
                rts
; End of function Projectile_MissirayAndRisingShotSelectVariant
; Initializes falling state with velocity and collision parameters
Projectile_MissirayFallingShotInitMotion:               ; was: sub_33A7A
                move.b  #$C0,$21(a5)
                move.b  #8,$23(a5)
                move.w  #$FFFC,$1C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Projectile_MissirayFallingShotInitMotion
; Applies gravity until the falling shot reaches its transition velocity
Projectile_MissirayFallingShotApplyGravity:             ; was: sub_33A92
                addi.l  #$1800,$1C(a5)
                btst    #7,$1C(a5)
                bne.s   Projectile_MissirayFallingShotGravityReturn
                cmpi.w  #2,$1C(a5)
                bcs.s   Projectile_MissirayFallingShotGravityReturn
                clr.l   $1C(a5)
                move.l  #Projectile_MissirayFallingShotSpriteAnimation,8(a5)
                clr.w   $C(a5)
                ori.w   #$2000,2(a5)
                move.l  #$E020FE02,$2C(a5)
                move.l  #$E020F808,$28(a5)
                move.w  #$18,$48(a5)
                addq.w  #2,4(a5)
                bsr.w   Projectile_RisingShotEmitShot
Projectile_MissirayFallingShotGravityReturn:            ; was: locret_33ADE
                                        ; Projectile_MissirayFallingShotApplyGravity+16   j
                rts
; End of function Projectile_MissirayFallingShotApplyGravity
; Emits a type-$88 child every fourth frame
Projectile_RisingShotEmitOnInterval:                    ; was: sub_33AE0
                                        ; Projectile_MissirayFallingShotDecelerate   p
                move.w  (FrameCounter).w,d7
                andi.w  #3,d7
                beq.s   Projectile_RisingShotEmitShot
                rts
; End of function Projectile_RisingShotEmitOnInterval
; Unreferenced alternate emitter that strengthens the spawned shot's collision box
Orphaned_RisingShotEmitHomingShot:                      ; was: sub_33AEC
                move.w  (FrameCounter).w,d7
                andi.w  #3,d7
                bne.s   Orphaned_RisingShotEmitHomingReturn
                bsr.s   Projectile_RisingShotEmitShot
                cmpi.w  #$88,(a0)
                bne.s   Orphaned_RisingShotEmitHomingReturn
                move.l  #$FE02F40C,$2C(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.w  #$32,$26(a0)                    ; '2'
Orphaned_RisingShotEmitHomingReturn:                    ; was: locret_33B12
                                        ; Orphaned_RisingShotEmitHomingShot+10   j
                rts
; End of function Orphaned_RisingShotEmitHomingShot
; Spawns a type-$88 child at the current object's position
Projectile_RisingShotEmitShot:                          ; was: sub_33B14
                                        ; Projectile_RisingShotEmitOnInterval+8   j
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_RisingShotEmitReturn
                jsr     (Projectile_InitType88).l
                andi.w  #$FEFF,2(a0)
                move.b  $20(a5),$20(a0)
                addq.b  #4,$20(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.b  $29(a5),d0
                andi.w  #$FF,d0
                add.w   d0,$14(a0)
Projectile_RisingShotEmitReturn:                        ; was: locret_33B52
                rts
; End of function Projectile_RisingShotEmitShot
; Descends while emitting shots, then switches mapping and state
Projectile_MissirayFallingShotDescend:                  ; was: sub_33B54
                bsr.w   Projectile_RisingShotEmitOnInterval
                addi.l  #$3000,$1C(a5)
                cmpi.w  #$80,$C(a5)
                bcs.s   Projectile_MissirayFallingShotDescendReturn
                move.l  #Projectile_MissirayVerticalShotSpriteMapping03,8(a5)
                clr.w   $C(a5)
                andi.w  #$DFFF,2(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
Projectile_MissirayFallingShotDescendReturn:            ; was: locret_33B84
                rts
; End of function Projectile_MissirayFallingShotDescend
; Decelerates, then restores the saved vertical velocity
Projectile_MissirayFallingShotDecelerate:               ; was: sub_33B86
                bsr.w   Projectile_RisingShotEmitOnInterval
                addi.l  #-$800,$1C(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_MissirayFallingShotDecelerateReturn
                move.l  $58(a5),$1C(a5)
                addq.w  #4,4(a5)
Projectile_MissirayFallingShotDecelerateReturn:         ; was: locret_33BA2
                rts
; End of function Projectile_MissirayFallingShotDecelerate
; Waits for a rising-wave member's launch delay
Projectile_RisingShotWait:                              ; was: sub_33BA4
                subq.w  #1,$48(a5)
                bmi.s   Projectile_RisingShotLaunch
                rts
; ---------------------------------------------------------------------------
Projectile_RisingShotLaunch:                            ; was: loc_33BAC
                clr.w   $48(a5)
                move.b  #$C0,$21(a5)
                move.b  #8,$23(a5)
                move.l  $58(a5),$1C(a5)
                addq.w  #2,4(a5)
                move.b  #$57,d0                         ; 'W'
                jsr     (Sound_QueueSFXRequest).l
; End of function Projectile_RisingShotWait
; Moves a rising-wave member upward while emitting shots
Projectile_RisingShotRiseAndEmit:                       ; was: sub_33BD0
                move.l  $5C(a5),d0
                add.l   d0,$1C(a5)
                bsr.w   Projectile_RisingShotEmitOnInterval
                cmpi.w  #$80,$14(a5)
                bgt.s   Projectile_RisingShotRiseReturn
                move.w  #$1000,2(a5)
Projectile_RisingShotRiseReturn:                        ; was: locret_33BEA
                rts
; End of function Projectile_RisingShotRiseAndEmit
; Initializes the Stage 24 arc selected by the global direction bit
Projectile_Stage24RisingShotInitArc:                    ; was: sub_33BEC
                clr.l   $1C(a5)
                btst    #3,(PlayerSpriteAttributes).w
                bne.s   Projectile_Stage24RisingShotMoveRight
                move.w  #$FFFE,$18(a5)
                bra.s   Projectile_Stage24RisingShotFinishArcInit
; ---------------------------------------------------------------------------
Projectile_Stage24RisingShotMoveRight:                  ; was: loc_33C00
                move.w  #2,$18(a5)
Projectile_Stage24RisingShotFinishArcInit:              ; was: loc_33C06
                addq.w  #2,4(a5)
                move.w  #$18,$48(a5)
                move.l  #$FFFE8000,$1C(a5)
                move.l  #$2000,$5C(a5)
                rts
; End of function Projectile_Stage24RisingShotInitArc
; Advances the Stage 24 arc and converts it to a type-$160 effect on expiry
Projectile_Stage24RisingShotUpdateArc:                  ; was: sub_33C22
                eori.w  #$8000,2(a5)
                bsr.w   Projectile_RisingShotEmitOnInterval
                move.l  $5C(a5),d0
                add.l   d0,$1C(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_Stage24RisingShotArcReturn
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                jmp     Sprite_InitType160FromCurrent
; ---------------------------------------------------------------------------
Projectile_Stage24RisingShotArcReturn:                  ; was: locret_33C48
                rts
; End of function Projectile_Stage24RisingShotUpdateArc
; Begins the radial burst when a Stage 24 rising shot crosses the camera top edge
Projectile_Stage24RisingShotBeginTopEdgeBurst:          ; was: sub_33C4A
                bclr    #7,2(a5)
                move.w  (Entity57YPos).w,$14(a5)
                bsr.w   Projectile_Stage24RisingShotSpawnRadialBurst
                move.w  #4,$48(a5)
                move.w  #$20,$4A(a5)                    ; ' '
                move.w  #4,$4C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Projectile_Stage24RisingShotBeginTopEdgeBurst
; Emits a short vertical trail before converting the rising shot to a type-$160 effect
Projectile_Stage24RisingShotEmitTopEdgeTrail:           ; was: sub_33C72
                move.w  (Entity57YPos).w,$14(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_Stage24RisingShotTrailReturn
                subq.w  #1,$4C(a5)
                beq.s   Projectile_Stage24RisingShotFinishTopEdgeBurst
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_Stage24RisingShotResetTrailDelay
                move.w  #$10,(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (Sprite_InitType160).l
                move.b  #$60,$20(a0)                    ; '`'
                move.l  #$FE02F40C,$2C(a0)
                move.b  #$40,$21(a0)                    ; '@'
                move.w  #$32,$26(a0)                    ; '2'
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),d0
                sub.w   $4A(a5),d0
                move.w  d0,$14(a0)
                addi.w  #8,$4A(a5)
Projectile_Stage24RisingShotResetTrailDelay:            ; was: loc_33CD0
                move.w  #4,$48(a5)
Projectile_Stage24RisingShotTrailReturn:                ; was: locret_33CD6
                rts
; ---------------------------------------------------------------------------
Projectile_Stage24RisingShotFinishTopEdgeBurst:         ; was: loc_33CD8
                move.w  $4A(a5),d0
                sub.w   d0,$14(a5)
                move.l  #SharedCombatSpriteAnimation00,8(a5)
                jmp     Sprite_InitType160FromCurrent
; End of function Projectile_Stage24RisingShotEmitTopEdgeTrail
; Spawns three radial particles and plays the burst sound
Projectile_Stage24RisingShotSpawnRadialBurst:           ; was: sub_33CEE
                move.w  #2,d7
                move.w  #$40,d6                         ; '@'
                lea     (Math_SineTable).l,a3
Projectile_Stage24RisingShotSpawnNextRadialParticle:    ; was: loc_33CFC
                move.w  d6,d5
                move.w  (a3,d5.w),d2
                move.w  -$80(a3,d5.w),d3
                ext.l   d2
                ext.l   d3
                asl.l   #3,d2
                asl.l   #3,d3
                bsr.w   Projectile_Stage24RisingShotSpawnBurstParticle
                addi.w  #$40,d6                         ; '@'
                dbf     d7,Projectile_Stage24RisingShotSpawnNextRadialParticle
                move.b  #$BB,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function Projectile_Stage24RisingShotSpawnRadialBurst
; Spawns one radial type-$160 burst particle with the supplied velocity
Projectile_Stage24RisingShotSpawnBurstParticle:         ; was: sub_33D26
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_Stage24RisingShotSpawnBurstParticleReturn
                jsr     (Sprite_InitType160).l
                move.b  #$60,$20(a0)                    ; '`'
                move.l  #SharedCombatSpriteAnimation00,8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  d2,$18(a0)
                move.l  d3,$1C(a0)
Projectile_Stage24RisingShotSpawnBurstParticleReturn:   ; was: locret_33D56
                rts
; End of function Projectile_Stage24RisingShotSpawnBurstParticle
; Initializes Missiray bullet projectile with graphics and parameters
Projectile_InitMissirayBullet:                          ; was: sub_33D58
                                        ; Segment_MissirayLaunchConfiguredProjectile+54   p
                move.w  #$3CC,(a0)
                move.l  #Projectile_MissirayBulletInitialSpriteAnimation,8(a0)
                clr.w   $C(a0)
                move.l  #$FC04FC04,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #$EC00,2(a0)
                move.w  #$300,$E(a0)
                move.b  #$C0,$21(a0)
                move.b  #8,$23(a0)
                move.w  #$28,$24(a0)                    ; '('
                move.w  #$50,$26(a0)                    ; 'P'
                move.b  #$60,$20(a0)                    ; '`'
                move.w  d0,$10(a0)
                move.w  d1,$14(a0)
                move.l  d2,$58(a0)
                rts
; End of function Projectile_InitMissirayBullet
; Type-$3CC Missiray bullet state machine
Projectile_MissirayBulletMain:                          ; was: sub_33DB0
                tst.w   4(a5)
                beq.s   Projectile_MissirayBulletDispatchState
                bclr    #7,$22(a5)
                bne.s   Projectile_MissirayBulletBeginImpact
                btst    #1,(BossColorEffectFlags).w
                bne.s   Projectile_MissirayBulletBeginImpact
                tst.w   $24(a5)
                bpl.s   Projectile_MissirayBulletDispatchState
Projectile_MissirayBulletBeginImpact:                   ; was: loc_33DCC
                                        ; Projectile_MissirayBulletMain+14   j
                cmpi.w  #$C,4(a5)
                bcc.s   Projectile_MissirayBulletDispatchState
                move.w  #$C,4(a5)
                clr.b   $21(a5)
Projectile_MissirayBulletDispatchState:                 ; was: loc_33DDE
                                        ; Projectile_MissirayBulletMain+1A   j
                move.w  4(a5),d0
                lea     Projectile_MissirayBulletStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_MissirayBulletMain
; ---------------------------------------------------------------------------
Projectile_MissirayBulletStates:    dc.w    Projectile_MissirayBulletBeginFall-*  ; was: off_33DEA
                dc.w    Projectile_MissirayBulletDecelerateFall-*
                dc.w    Projectile_MissirayBulletBeginTransformDelay-*
                dc.w    Projectile_MissirayBulletTransform-*
                dc.w    Projectile_MissirayBulletWaitForTransformFrame-*
                dc.w    Projectile_MissirayBulletAccelerateDownward-*
                dc.w    Projectile_MissirayBulletBeginImpactBurst-*
                dc.w    Projectile_MissirayBulletEmitImpactBurst-*

; Begins the bullet's downward fall and deceleration timer
Projectile_MissirayBulletBeginFall:                     ; was: sub_33DFA
                move.l  #$40000,$1C(a5)
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Projectile_MissirayBulletBeginFall
; Decelerates the initial fall to a stop
Projectile_MissirayBulletDecelerateFall:                ; was: sub_33E0E
                subi.l  #$3800,$1C(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_MissirayBulletDecelerationReturn
                clr.l   $1C(a5)
                addq.w  #2,4(a5)
Projectile_MissirayBulletDecelerationReturn:            ; was: locret_33E24
                rts
; End of function Projectile_MissirayBulletDecelerateFall
; Starts the delay before changing bullet form
Projectile_MissirayBulletBeginTransformDelay:           ; was: sub_33E26
                move.w  #$10,$48(a5)
                addq.w  #2,4(a5)
                rts
; End of function Projectile_MissirayBulletBeginTransformDelay
; Changes graphics and restores the constructor-provided vertical velocity
Projectile_MissirayBulletTransform:                     ; was: sub_33E32
                subq.w  #1,$48(a5)
                bne.s   Projectile_MissirayBulletTransformDelayReturn
                move.l  #Projectile_MissirayBulletTransformSpriteAnimation,8(a5)
                clr.w   $C(a5)
                move.l  #$FF01D62A,$2C(a5)
                move.l  #$F808D030,$28(a5)
                move.b  #$10,$23(a5)
                move.l  $58(a5),$1C(a5)
                addq.w  #2,4(a5)
Projectile_MissirayBulletTransformDelayReturn:          ; was: locret_33E64
                rts
; End of function Projectile_MissirayBulletTransform
; Waits for the transformed animation to reach its next phase
Projectile_MissirayBulletWaitForTransformFrame:         ; was: sub_33E66
                cmpi.w  #$80,$C(a5)
                bcs.s   Projectile_MissirayBulletTransformFrameReturn
                move.l  #Projectile_MissirayBulletLoopSpriteAnimation,8(a5)
                clr.w   $C(a5)
                addq.w  #2,4(a5)
Projectile_MissirayBulletTransformFrameReturn:          ; was: locret_33E7E
                rts
; End of function Projectile_MissirayBulletWaitForTransformFrame
; Accelerates downward and removes the bullet below the arena
Projectile_MissirayBulletAccelerateDownward:            ; was: sub_33E80
                cmpi.l  #$1C000,$1C(a5)
                bge.s   Projectile_MissirayBulletCheckExit
                addi.l  #$800,$1C(a5)
Projectile_MissirayBulletCheckExit:                     ; was: loc_33E92
                cmpi.w  #$180,$14(a5)
                blt.s   Projectile_MissirayBulletUpdateReturn
                move.w  #$1000,2(a5)
Projectile_MissirayBulletUpdateReturn:                  ; was: locret_33EA0
                rts
; End of function Projectile_MissirayBulletAccelerateDownward
; Initializes the symmetric impact-particle burst
Projectile_MissirayBulletBeginImpactBurst:              ; was: sub_33EA2
                clr.l   $1C(a5)
                move.w  #2,$48(a5)
                move.w  #4,$4A(a5)
                move.w  #8,$4C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Projectile_MissirayBulletBeginImpactBurst
; Emits four pairs of type-$160 impact particles at widening X offsets
Projectile_MissirayBulletEmitImpactBurst:               ; was: sub_33EBE
                eori.w  #$8000,2(a5)
                subq.w  #1,$48(a5)
                bne.s   Projectile_MissirayBulletImpactBurstReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_MissirayBulletAdvanceImpactBurst
                move.w  $4C(a5),d0
                bsr.w   Projectile_MissirayBulletSpawnImpactParticle
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Projectile_MissirayBulletAdvanceImpactBurst
                move.w  $4C(a5),d0
                neg.w   d0
                bsr.w   Projectile_MissirayBulletSpawnImpactParticle
Projectile_MissirayBulletAdvanceImpactBurst:            ; was: loc_33EEC
                                        ; Projectile_MissirayBulletEmitImpactBurst+22   j
                subq.w  #1,$4A(a5)
                beq.s   Projectile_MissirayBulletFinishImpactBurst
                addq.w  #8,$4C(a5)
                move.w  #2,$48(a5)
Projectile_MissirayBulletImpactBurstReturn:             ; was: locret_33EFC
                rts
; ---------------------------------------------------------------------------
Projectile_MissirayBulletFinishImpactBurst:             ; was: loc_33EFE
                move.w  #$1000,2(a5)
                rts
; End of function Projectile_MissirayBulletEmitImpactBurst
; Converts an allocated slot to an impact particle at the supplied X offset
Projectile_MissirayBulletSpawnImpactParticle:           ; was: sub_33F06
                                        ; Projectile_MissirayBulletEmitImpactBurst+2A   p
                add.w   $10(a5),d0
                move.w  d0,$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #SharedCombatSpriteAnimation05,8(a0)
                jsr     (Sprite_InitType160).l
                move.b  #$60,$20(a0)                    ; '`'
                andi.w  #$FEFF,2(a0)
                rts
; End of function Projectile_MissirayBulletSpawnImpactParticle
