Stage15_FragmentEmitterWaveMain:                        ; was: sub_304E4
                move.w  4(a5),d0
                lea     Stage15_FragmentEmitterWaveStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage15_FragmentEmitterWaveMain
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterWaveStates:
                dc.w    Stage15_FragmentEmitterWaveInit-*
                dc.w    Stage15_FragmentEmitterWaveWaitForScroll-*

; Initializes the Stage 15 scroll-triggered fragment-emitter wave
Stage15_FragmentEmitterWaveInit:                        ; was: sub_304F4
                move.w  #$6000,2(a5)
                move.w  #$8000,$E(a5)
                move.l  #SharedTeddyHazardLoopAnimation,8(a5)
                move.l  #Stage15_FragmentEmitterSchedule,$40(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage15_FragmentEmitterWaveInit

; Waits until the camera reaches the next emitter entry
Stage15_FragmentEmitterWaveWaitForScroll:               ; was: sub_30516
                move.w  (PrimaryCameraYPosition).w,d0
                movea.l $40(a5),a4
; End of function Stage15_FragmentEmitterWaveWaitForScroll

; Creates a type-$3A0 side emitter from the current schedule entry
Stage15_FragmentEmitterWaveSpawn:                       ; was: sub_3051E
                cmp.w   (a4),d0
Stage15_FragmentEmitterWaveCheckThreshold:              ; was: loc_30520
                bcs.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   Stage15_FragmentEmitterWaveSkipEntry
                move.w  #$CD00,2(a0)
                move.w  #$3A0,(a0)
                move.w  (a4)+,d0
                sub.w   (PrimaryCameraYPosition).w,d0
                neg.w   d0
                addi.w  #$C0,d0
                move.w  d0,$14(a0)
                move.w  (a4)+,$10(a0)
                clr.w   4(a0)
                move.l  a4,$40(a5)
                rts
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterWaveSkipEntry:
                addq.w  #4,a4
                move.l  a4,$40(a5)
                rts
; End of function Stage15_FragmentEmitterWaveSpawn
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterSchedule:
                dc.w    $E190, $200, $E1F0, $40, $E230, $200, $E290, $40
                dc.w    $E2E0, $40, $E320, $200, $E360, $200, $FFFF

Stage15_FragmentEmitterMain:                            ; was: sub_3057A
                move.w  4(a5),d0
                lea     Stage15_FragmentEmitterStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage15_FragmentEmitterMain
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterStates:
                dc.w    Stage15_FragmentEmitterInit-*
                dc.w    Stage15_FragmentEmitterWaitForPass-*
                dc.w    Stage15_FragmentEmitterRunPass-*
                dc.w    Stage15_FragmentEmitterRetreat-*

; Initializes a Stage 15 side emitter
Stage15_FragmentEmitterInit:                            ; was: sub_3058E
                move.w  #$CD00,2(a5)
                move.w  #$A300,$E(a5)
                move.l  #Stage15_FragmentEmitterSpriteMapping,8(a5)
                move.b  #$3C,$20(a5)                    ; '<'
                move.w  #$64,$24(a5)                    ; 'd'
                move.b  #$40,$21(a5)                    ; '@'
                move.l  #$FC04FC04,$2C(a5)
                move.l  #$F010F010,$28(a5)
                move.w  #$28,$26(a5)                    ; '('
                move.w  #$80,$40(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage15_FragmentEmitterInit
; Wait for timer then move horizontally based on position
Stage15_FragmentEmitterWaitForPass:                     ; was: sub_305D6
                cmpi.w  #$100,$14(a5)
                bcs.w   Entity_UpdateReturn
                tst.w   $40(a5)
                beq.s   Stage15_FragmentEmitterBeginPass
                subq.w  #1,$40(a5)
                rts
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterBeginPass:
                move.l  #$12000,$18(a5)
                cmpi.w  #$120,$10(a5)
                bcs.s   Stage15_FragmentEmitterArmPass
                ori.w   #$800,$E(a5)
                neg.l   $18(a5)
Stage15_FragmentEmitterArmPass:
                move.w  #$50,$40(a5)                    ; 'P'
                addq.w  #2,4(a5)
                rts
; End of function Stage15_FragmentEmitterWaitForPass
; Move weapon and spawn projectiles before reversing direction
Stage15_FragmentEmitterRunPass:                         ; was: sub_30612
                subq.w  #1,$40(a5)
                beq.s   Stage15_FragmentEmitterReversePass
                cmpi.w  #$10,$40(a5)
                bne.w   Entity_UpdateReturn
                move.w  $10(a5),d5
                move.w  $14(a5),d6
                move.w  #4,d3
                cmpi.w  #$120,$10(a5)
                bcc.s   Stage15_FragmentEmitterSpawnFromRight
                addi.w  #$20,d5                         ; ' '
                clr.w   d4
                bsr.w   Projectile_SpawnFragmentCluster
                rts
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterSpawnFromRight:
                subi.w  #$20,d5                         ; ' '
                move.w  #$10,d4
                bsr.w   Projectile_SpawnFragmentCluster
                rts
; ---------------------------------------------------------------------------
Stage15_FragmentEmitterReversePass:
                neg.l   $18(a5)
                move.w  #$60,$40(a5)                    ; '`'
                addq.w  #2,4(a5)
                rts
; End of function Stage15_FragmentEmitterRunPass
; Wait for timer countdown then destroy weapon entity
Stage15_FragmentEmitterRetreat:                         ; was: sub_30660
                subq.w  #1,$40(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$1000,2(a5)
                rts
; End of function Stage15_FragmentEmitterRetreat
; Spawn projectile with directional offset and sound effect
Projectile_SpawnFragmentCluster:                        ; was: sub_30670
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                move.w  #$ED00,2(a0)
                move.l  #Effect_SpriteAnimation13,8(a0)
                move.w  #$3A4,(a0)
                move.w  d3,$4E(a0)
                move.w  d4,$50(a0)
                move.w  a5,$48(a0)
                move.w  d5,$10(a0)
                sub.w   $10(a5),d5
                move.w  d5,$4A(a0)
                move.w  d6,$14(a0)
                sub.w   $14(a5),d6
                move.w  d6,$4C(a0)
                move.b  #0,$20(a0)
                move.w  d4,d0
                lsr.w   #1,d0
                move.w  #$480,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                lea     Projectile_FragmentOrientationAttributes(pc),a1
                nop
                or.w    (a1,d0.w),d1
                move.w  d1,$E(a0)
                move.w  #$3A4,(a0)
                clr.w   4(a0)
                move.w  #$10,$46(a0)
                move.b  #$CE,d0
                jsr     (Sound_QueueSFXRequest).l
                rts
; End of function Projectile_SpawnFragmentCluster
; Projectile state dispatcher using jump table for behavior selection
Projectile_FragmentClusterMain:                         ; was: sub_306EA
                move.w  4(a5),d0
                lea     Projectile_FragmentClusterStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Projectile_FragmentClusterMain
; ---------------------------------------------------------------------------
Projectile_FragmentClusterStates:
                dc.w    Projectile_FragmentClusterTrackAndSplit-*
                dc.w    Projectile_FragmentDelayLaunch-*
                dc.w    Projectile_FragmentClusterHandleImpact-*
                dc.w    Projectile_FragmentUpdateHitAndLifetime-*
                dc.w    Projectile_FragmentImpactAnimation-*
                dc.w    Projectile_FragmentFallAndExpire-*

; Track parent entity position then split into fragment spread
Projectile_FragmentClusterTrackAndSplit:                ; was: sub_30702
                movea.w $48(a5),a4
                move.w  $10(a4),d0
                add.w   $4A(a5),d0
                move.w  d0,$10(a5)
                move.w  $14(a4),d0
                add.w   $4C(a5),d0
                move.w  d0,$14(a5)
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.w  2(a5),d5
                andi.w  #$DFFF,d5
                move.w  #$1000,2(a5)
                lea     $54(a5),a3
                move.w  $50(a5),d4
                move.w  $4E(a5),d3
Projectile_FragmentClusterCreateLoop:
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                move.w  d5,2(a0)
                move.l  #$FF01FF01,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  d4,$50(a0)
                move.b  #0,$20(a0)
                move.w  $E(a5),$E(a0)
                move.w  #$3A4,(a0)
                move.w  #2,4(a0)
                move.w  d3,d0
                lsl.w   #1,d0
                move.w  d0,d1
                lsl.w   #1,d0
                add.w   d1,d0
                addq.w  #1,d0
                move.w  d0,$46(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  d4,d0
                move.l  Projectile_FragmentSpriteFrames(pc,d0.w),8(a0)
                move.l  Projectile_FragmentVelocityX(pc,d0.w),$48(a0)
                move.l  Projectile_FragmentVelocityY(pc,d0.w),$4C(a0)
                move.l  $48(a0),d0
                move.l  d0,d1
                lsl.l   #1,d0
                add.l   d1,d0
                swap    d0
                add.w   d0,$10(a0)
                move.l  $4C(a0),d0
                move.l  d0,d1
                lsl.l   #1,d0
                add.l   d1,d0
                swap    d0
                add.w   d0,$14(a0)
                move.w  a0,(a3)+
                dbf     d3,Projectile_FragmentClusterCreateLoop
                bsr.w   Projectile_FragmentClusterCopyLinks
                rts
; End of function Projectile_FragmentClusterTrackAndSplit
; ---------------------------------------------------------------------------
Projectile_FragmentVelocityX:
                dc.l    $40000, $2D414
                dc.l    0, $FFFD2BEC
                dc.l    $FFFC0000, $FFFD2BEC
                dc.l    0, $2D414
Projectile_FragmentVelocityY:
                dc.l    0, $2D414
                dc.l    $40000, $2D414
                dc.l    0, $FFFD2BEC
                dc.l    $FFFC0000, $FFFD2BEC
Projectile_FragmentSpriteFrames:
                dc.l    Projectile_FragmentSpriteFrame01
                dc.l    Projectile_FragmentSpriteFrame02
                dc.l    Projectile_FragmentSpriteFrame00
                dc.l    Projectile_FragmentSpriteFrame02
                dc.l    Projectile_FragmentSpriteFrame01
                dc.l    Projectile_FragmentSpriteFrame02
                dc.l    Projectile_FragmentSpriteFrame00
                dc.l    Projectile_FragmentSpriteFrame02
Projectile_FragmentOrientationAttributes:
                dc.w    $800, $1800, $1800, $1000, 0, 0, $800, $800

; Copy fragment entity references between parent and child
Projectile_FragmentClusterCopyLinks:                    ; was: sub_30844
                move.b  #$40,$21(a0)                    ; '@'
                move.w  #$28,$26(a0)                    ; '('
                lea     $54(a5),a3
                lea     $54(a0),a4
                move.w  $4E(a5),d3
                move.w  d3,$52(a0)
Projectile_FragmentClusterCopyLinksLoop:
                move.w  (a3)+,(a4)+
                dbf     d3,Projectile_FragmentClusterCopyLinksLoop
                rts
; End of function Projectile_FragmentClusterCopyLinks
; Calculate 8-way directional index from player position flags
Projectile_SelectFragmentImpactDirection:               ; was: sub_30868
                btst    #3,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionPrimaryBranch
                btst    #3,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionSecondaryBranch
                btst    #0,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionDown
                btst    #1,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionUp
                move.w  (PlayerSpriteAttributes).w,d0
                andi.w  #$800,d0
                bne.s   Projectile_SelectFragmentDirectionLeft
                bra.s   Projectile_SelectFragmentDirectionRight
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionPrimaryBranch:
                btst    #0,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionDownLeft
                btst    #1,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionUpLeft
                bra.s   Projectile_SelectFragmentDirectionLeft
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionSecondaryBranch:
                btst    #0,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionDownRight
                btst    #1,(ControllerHeldState).w
                bne.s   Projectile_SelectFragmentDirectionUpRight
                bra.s   Projectile_SelectFragmentDirectionRight
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionLeft:
                move.w  #$10,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionUpLeft:
                move.w  #$14,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionUp:
                move.w  #$18,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionUpRight:
                move.w  #$1C,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionRight:
                move.w  #0,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionDownRight:
                move.w  #4,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionDown:
                move.w  #8,d4
                rts
; ---------------------------------------------------------------------------
Projectile_SelectFragmentDirectionDownLeft:
                move.w  #$C,d4
                rts
; End of function Projectile_SelectFragmentImpactDirection
; Wait for timer then apply stored velocity to fragment
Projectile_FragmentDelayLaunch:                         ; was: sub_308E8
                subq.w  #1,$46(a5)
                bne.w   Entity_UpdateReturn
                move.l  $48(a5),$18(a5)
                move.l  $4C(a5),$1C(a5)
                move.w  #$40,$46(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Projectile_FragmentDelayLaunch
; Spawn circular spread of fragments when hit by player
Projectile_FragmentClusterHandleImpact:                 ; was: sub_30908
                subq.w  #1,$46(a5)
                beq.w   Projectile_FragmentRemove
                bclr    #7,$22(a5)
                beq.w   Entity_UpdateReturn
                bclr    #4,$22(a5)
                beq.w   Entity_UpdateReturn
                move.w  2(a5),d5
                lea     $54(a5),a3
                move.w  $52(a5),d3
Projectile_FragmentClusterHideLinksLoop:
                movea.w (a3)+,a4
                move.w  #$1000,2(a4)
                dbf     d3,Projectile_FragmentClusterHideLinksLoop
                bsr.w   Projectile_SelectFragmentImpactDirection
                move.w  $52(a5),d3
Projectile_FragmentClusterResponseLoop:
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                move.w  d5,2(a0)
                clr.b   $22(a0)
                move.b  #1,$21(a0)
                bsr.w   Projectile_SetNewFragmentHealth
                move.w  #$3A4,(a0)
                move.b  #0,$20(a0)
                move.w  #6,4(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  d3,d0
                lsl.w   #4,d0
                move.w  d4,d1
                lsr.w   #1,d1
                add.w   d1,d0
                move.w  Projectile_FragmentResponseDirections(pc,d0.w),d0
                lea     Projectile_FragmentSpriteFrames(pc),a1
                move.l  (a1,d0.w),8(a0)
                lea     Projectile_FragmentVelocityX(pc),a1
                move.l  (a1,d0.w),$18(a0)
                lea     Projectile_FragmentVelocityY(pc),a1
                move.l  (a1,d0.w),$1C(a0)
                lsr.w   #1,d0
                move.w  #$480,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                lea     Projectile_FragmentOrientationAttributes(pc),a1
                or.w    (a1,d0.w),d1
                move.w  d1,$E(a0)
                move.l  $18(a0),d0
                move.l  d0,d1
                lsl.l   #1,d0
                add.l   d1,d0
                swap    d0
                add.w   d0,$10(a0)
                move.l  $1C(a0),d0
                move.l  d0,d1
                lsl.l   #1,d0
                add.l   d1,d0
                swap    d0
                add.w   d0,$14(a0)
                move.w  #$40,$46(a0)                    ; '@'
                dbf     d3,Projectile_FragmentClusterResponseLoop
                rts
; ---------------------------------------------------------------------------
Projectile_FragmentRemove:
                move.w  #$1000,2(a5)
                rts
; End of function Projectile_FragmentClusterHandleImpact
; ---------------------------------------------------------------------------
Projectile_FragmentResponseDirections:
                dc.w    $10, $14, $18, $1C, 0, 4, 8, $C, $14, $18, $1C, 0, 4, 8, $C, $10, $C
                dc.w    $10, $14, $18, $1C, 0, 4, 8, $18, $1C, 0, 4, 8, $C, $10, $14, 8, $C
                dc.w    $10, $14, $18, $1C, 0, 4

; Handle fragment collision and destroy after timer expires
Projectile_FragmentUpdateHitAndLifetime:                ; was: sub_30A42
                bsr.w   Projectile_FragmentConvertToImpact
                subq.w  #1,$46(a5)
                beq.s   Projectile_FragmentRemove
                rts
; End of function Projectile_FragmentUpdateHitAndLifetime
; Checks if animation frame counter exceeds threshold for state change
Projectile_FragmentImpactAnimation:                     ; was: sub_30A4E
                cmpi.w  #$80,$C(a5)
                bcs.w   Entity_UpdateReturn
                move.w  #$1000,2(a5)
                rts
; End of function Projectile_FragmentImpactAnimation
; Applies gravity to projectile with hit detection and lifetime check
Projectile_FragmentFallAndExpire:                       ; was: sub_30A60
                addi.l  #$2000,$1C(a5)
                bsr.w   Projectile_FragmentConvertToImpact
                subq.w  #1,$46(a5)
                beq.w   Projectile_FragmentRemove
                rts
; End of function Projectile_FragmentFallAndExpire
; Handles projectile hit changing sprite state and clearing collision flags
Projectile_FragmentConvertToImpact:                     ; was: sub_30A76
                bclr    #7,$22(a5)
                beq.w   Entity_UpdateReturn
                clr.b   $22(a5)
                move.w  #$8480,$E(a5)
                move.w  #$EC00,2(a5)
                move.l  #Effect_SpriteAnimation32,8(a5)
                clr.w   $C(a5)
                clr.b   $21(a5)
                move.b  #$BC,d0
                jsr     (Sound_QueueSFXRequest).l
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.w  #8,4(a5)
                rts
; End of function Projectile_FragmentConvertToImpact
; Handles projectile deflection and bounce with directional velocity
Projectile_FragmentBeginDeflectedFall:                  ; was: sub_30ABA
                clr.b   $22(a5)
                move.w  #$3A4,(a5)
                move.w  #$80,$46(a5)
                move.w  #$A,4(a5)
                move.b  #1,$21(a5)
                bsr.w   Projectile_SetCurrentFragmentHealth
                move.l  #$FFFE0000,$1C(a5)
                btst    #3,(ControllerHeldState).w
                bne.s   Projectile_FragmentDeflectRight
                btst    #3,(ControllerHeldState).w
                bne.s   Projectile_FragmentDeflectLeft
                move.w  (PlayerSpriteAttributes).w,d0
                andi.w  #$800,d0
                bne.s   Projectile_FragmentDeflectRight
Projectile_FragmentDeflectLeft:
                move.l  #$FFFA0000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Projectile_FragmentDeflectRight:
                move.l  #$60000,$18(a5)
                rts
; End of function Projectile_FragmentBeginDeflectedFall
; Set entity HP value based on difficulty level check
Projectile_SetCurrentFragmentHealth:                    ; was: sub_30B0E
                tst.w   (DifficultyMode).w
                beq.s   Projectile_SetCurrentFragmentHighHealth
                move.w  #$64,$26(a5)                    ; 'd'
                rts
; ---------------------------------------------------------------------------
Projectile_SetCurrentFragmentHighHealth:
                move.w  #$C8,$26(a5)
                rts
; End of function Projectile_SetCurrentFragmentHealth
; Set entity HP value based on difficulty level check
Projectile_SetNewFragmentHealth:                        ; was: sub_30B24
                tst.w   (DifficultyMode).w
                beq.s   Projectile_SetNewFragmentHighHealth
                move.w  #$64,$26(a0)                    ; 'd'
                rts
; ---------------------------------------------------------------------------
Projectile_SetNewFragmentHighHealth:
                move.w  #$C8,$26(a0)
                rts
; End of function Projectile_SetNewFragmentHealth
; Scroll-driven wave of the falling rocks seen in Stage 15
Stage15_FallingRockWaveMain:                            ; was: sub_30B3A
                move.w  4(a5),d0
                lea     Stage15_FallingRockWaveStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage15_FallingRockWaveMain
; ---------------------------------------------------------------------------
Stage15_FallingRockWaveStates:
                dc.w    Stage15_FallingRockWaveInit-*
                dc.w    Stage15_FallingRockWaveUpdate-*

; Selects the Stage 15 falling-rock schedule for the current difficulty
Stage15_FallingRockWaveInit:                            ; was: sub_30B4A
                move.w  #$6000,2(a5)
                move.w  #$8000,$E(a5)
                move.l  #SharedTeddyHazardLoopAnimation,8(a5)
                addq.w  #2,4(a5)
                tst.w   (DifficultyMode).w
                bne.w   Stage15_FallingRockWaveUseAlternateSchedule
                move.l  #Stage15_FallingRockSchedulePrimary,$40(a5)
                rts
; ---------------------------------------------------------------------------
Stage15_FallingRockWaveUseAlternateSchedule:
                move.l  #Stage15_FallingRockScheduleAlternate,$40(a5)
                rts
; End of function Stage15_FallingRockWaveInit

; Creates each group of type-$384 rocks when its scroll threshold is reached
Stage15_FallingRockWaveUpdate:                          ; was: sub_30B7E
                tst.l   (PlayerYVelocity).w
                bne.w   Entity_UpdateReturn
                move.w  (PrimaryCameraYPosition).w,d0
                sub.w   (PlayerYPosition).w,d0
                movea.l $40(a5),a4
                cmp.w   (a4)+,d0
                bcs.w   Entity_UpdateReturn
Stage15_FallingRockWaveSpawnGroup:
                jsr     (Projectile_FindFreeOrClearReusableSlot).l
                bne.s   Stage15_FallingRockWaveSkipGroup
                move.w  #$384,(a0)
                move.w  (a4)+,$10(a0)
                move.w  (a4)+,$14(a0)
                clr.w   4(a0)
                tst.w   (a4)
                bpl.s   Stage15_FallingRockWaveSpawnGroup
                move.l  a4,$40(a5)
Entity_UpdateReturn:                                    ; was: locret_30BB8
                rts
; ---------------------------------------------------------------------------
Stage15_FallingRockWaveSkipGroup:
                addq.w  #4,a4
                tst.w   (a4)
                bpl.s   Stage15_FallingRockWaveSkipGroup
                move.l  a4,$40(a5)
                rts
; End of function Stage15_FallingRockWaveUpdate
; ---------------------------------------------------------------------------
Stage15_FallingRockScheduleAlternate:
                dc.w    $E080, $90, $70, $1B0, $68
                dc.w    $E0D0, $C0, $68, $150, $70
                dc.w    $180, $60, $E120, $90, $60
                dc.w    $F0, $68, $150, $58, $E170
                dc.w    $F0, $68, $120, $50, $150
                dc.w    $58, $1B0, $70, $E1C0, $90
                dc.w    $70, $C0, $58, $150, $50
                dc.w    $180, $68, $E210, $C0, $48
                dc.w    $120, $60, $180, $70, $1B0
                dc.w    $58, $E260, $90, $70, $F0
                dc.w    $60, $120, $68, $150, $58
                dc.w    $1B0, $50, $E2B0, $90, $58
                dc.w    $C0, $40, $F0, $68, $150
                dc.w    $50, $180, $70, $1B0, $60
                dc.w    $FFFF
Stage15_FallingRockSchedulePrimary:
                dc.w    $E080, $90, $70, $1B0, $68
                dc.w    $E0D0, $C0, $68, $180, $60
                dc.w    $E120, $C0, $68, $150, $58
                dc.w    $E170, $F0, $68, $180, $70
                dc.w    $E1C0, $90, $70, $180, $50
                dc.w    $1B0, $68, $E210, $90, $48
                dc.w    $C0, $60, $F0, $70, $1B0
                dc.w    $58, $E260, $F0, $60, $120
                dc.w    $68, $150, $58, $E2B0, $90
                dc.w    $58, $C0, $40, $180, $70
                dc.w    $1B0, $60, $FFFF

Stage15_FallingRockMain:                                ; was: sub_30CBE
                move.w  4(a5),d0
                lea     Stage15_FallingRockStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Stage15_FallingRockMain
; ---------------------------------------------------------------------------
Stage15_FallingRockStates:
                dc.w    Stage15_FallingRockInit-*
                dc.w    Stage15_FallingRockBounce-*

; Initializes one falling rock from the Stage 15 wave
Stage15_FallingRockInit:                                ; was: sub_30CCE
                move.w  #$CD00,2(a5)
                move.w  #$A300,$E(a5)
                move.l  #Stage15_FallingRockSpriteMapping,8(a5)
                move.b  #0,$20(a5)
                move.w  #$800,$24(a5)
                move.b  #$C0,$21(a5)
                move.l  #$F40CF40C,$2C(a5)
                move.l  #$E817E818,$28(a5)
                move.b  #$10,$23(a5)
                move.w  #$28,$26(a5)
                clr.w   $44(a5)
                move.w  #$FFFF,$46(a5)
                addq.w  #2,4(a5)
                rts
; End of function Stage15_FallingRockInit

; Applies gravity and bounces the rock from terrain until it leaves the screen
Stage15_FallingRockBounce:                              ; was: sub_30D20
                addi.l  #$4000,$1C(a5)
                tst.w   $44(a5)
                beq.s   Stage15_FallingRockCheckTerrain
                subq.w  #1,$44(a5)
                rts
; ---------------------------------------------------------------------------
Stage15_FallingRockCheckTerrain:
                clr.w   d0
                move.w  #$18,d1
                jsr     (Physics_AddEntityOffset).l
                bne.s   Stage15_FallingRockBounceFromTerrain
                cmpi.w  #$180,$14(a5)
                bcs.w   Entity_UpdateReturn
                move.w  #$1000,2(a5)
                rts
; ---------------------------------------------------------------------------
Stage15_FallingRockBounceFromTerrain:
                move.w  #3,(PlaneAShakeLevel).w
                move.b  #$53,d0
                jsr     (Sound_QueueSFXRequest).l
                move.l  $1C(a5),$40(a5)
                jsr     (Physics_AlignToTerrain).l
                move.l  $40(a5),d0
                asr.l   #1,d0
                neg.l   d0
                move.l  d0,$1C(a5)
                tst.w   $46(a5)
                bmi.s   Stage15_FallingRockEnableBounceDelay
                move.w  #$18,$44(a5)
                rts
; ---------------------------------------------------------------------------
Stage15_FallingRockEnableBounceDelay:
                clr.w   $46(a5)
                rts
; End of function Stage15_FallingRockBounce
