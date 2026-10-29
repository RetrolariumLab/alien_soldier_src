; Victor launched-part, split-shot, defeat, and component handlers
; Resets eight orbiting parts and initializes the formation scale cycle
Boss_VictorPreparePartLaunch:                           ; was: sub_329A6
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                lea     (FifthEntityType).w,a4
                move.w  #7,d6
Boss_VictorResetNextOrbitingPart:                       ; was: loc_329B6
                move.w  #4,4(a4)
                adda.w  #$60,a4                         ; '`'
                dbf     d6,Boss_VictorResetNextOrbitingPart
                lea     (TwentyFirstEntityType).w,a4
                move.w  a4,(SharedScratchLong5).w
                move.l  #$80000,(SharedScratchLong3+2).w
                move.w  #4,(SharedScratchLong4+2).w
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorPreparePartLaunch
; Contracts the formation scale and launches a part at the outer threshold
Boss_VictorContractPartFormation:                       ; was: sub_329E0
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                subi.l  #$10000,(SharedScratchLong3+2).w
                cmpi.l  #$FFF00000,(SharedScratchLong3+2).w
                bne.w   Entity_UpdateReturn
                bsr.w   Boss_VictorLaunchOrbitingPart
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorContractPartFormation
; Expands the formation, launching parts at two scale thresholds
Boss_VictorExpandPartFormation:                         ; was: sub_32A06
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                addi.l  #$10000,(SharedScratchLong3+2).w
                cmpi.l  #$80000,(SharedScratchLong3+2).w
                beq.s   Boss_VictorFinishPartLaunchCycles
                cmpi.l  #$100000,(SharedScratchLong3+2).w
                bne.w   Entity_UpdateReturn
                bsr.w   Boss_VictorLaunchOrbitingPart
                subq.w  #2,4(a5)
                rts
; ---------------------------------------------------------------------------
Boss_VictorFinishPartLaunchCycles:                      ; was: loc_32A36
                subq.w  #1,(SharedScratchLong4+2).w
                bne.w   Entity_UpdateReturn
                lea     (FifthEntityType).w,a4
                move.w  #7,d6
Boss_VictorReactivateNextOrbitingPart:                  ; was: loc_32A46
                move.w  #0,4(a4)
                adda.w  #$60,a4                         ; '`'
                dbf     d6,Boss_VictorReactivateNextOrbitingPart
                move.w  #$60,$4A(a5)                    ; '`'
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorExpandPartFormation
; Launches the next orbiting part with a side-dependent vertical offset
Boss_VictorLaunchOrbitingPart:                          ; was: sub_32A60
                                        ; Boss_VictorExpandPartFormation+26   p
                move.b  #$CC,d0
                jsr     (Sound_QueueSFXRequest).l
                movea.w (SharedScratchLong5).w,a4
                addi.w  #$60,(SharedScratchLong5).w     ; '`'
                bsr.w   Boss_VictorInitPart
                move.w  #$A,$48(a4)
                move.w  #$500,8(a4)
                move.w  #$F8F8,$A(a4)
                move.w  #$6334,$E(a4)
                move.w  $10(a5),$10(a4)
                move.w  $14(a5),$14(a4)
                bsr.w   Boss_VictorSetLaunchedPartDirection
                cmpi.w  #$12,4(a5)
                beq.s   Boss_VictorChooseLaunchedPartVerticalOffset
                cmpi.w  #$120,$10(a5)
                bcs.w   Boss_VictorOffsetLaunchedPartUp
Boss_VictorOffsetLaunchedPartDown:                      ; was: loc_32AB2
                addi.w  #$28,$14(a4)                    ; '('
                rts
; ---------------------------------------------------------------------------
Boss_VictorChooseLaunchedPartVerticalOffset:            ; was: loc_32ABA
                cmpi.w  #$120,$10(a5)
                bcs.w   Boss_VictorOffsetLaunchedPartDown
Boss_VictorOffsetLaunchedPartUp:                        ; was: loc_32AC4
                subi.w  #$28,$14(a4)                    ; '('
                rts
; End of function Boss_VictorLaunchOrbitingPart
; Sets the launched part's horizontal direction from Victor's side of the arena
Boss_VictorSetLaunchedPartDirection:                    ; was: sub_32ACC
                cmpi.w  #$120,$10(a5)
                bcs.w   Boss_VictorLaunchPartRight
                move.w  #$FFFD,$18(a4)
                rts
; ---------------------------------------------------------------------------
Boss_VictorLaunchPartRight:                             ; was: loc_32ADE
                move.w  #3,$18(a4)
                rts
; End of function Boss_VictorSetLaunchedPartDirection
; Waits after the launched-part cycle before choosing another attack
Boss_VictorWaitAfterPartLaunch:                         ; was: sub_32AE6
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #6,4(a5)
                rts
; End of function Boss_VictorWaitAfterPartLaunch
; Starts the delay before Victor's split-shot wave
Boss_VictorBeginSplitShotCountdown:                     ; was: sub_32AFE
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                move.w  #$200,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorBeginSplitShotCountdown
; Updates the split-shot countdown and emits its two timed waves
Boss_VictorUpdateSplitShotCountdown:                    ; was: sub_32B12
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                bsr.w   Boss_VictorSpawnSplitShotWave
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$40,$4A(a5)                    ; '@'
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorUpdateSplitShotCountdown
; Emits one three-shot half of the split-shot pattern every 128 ticks
Boss_VictorSpawnSplitShotWave:                          ; was: sub_32B32
                move.w  $4A(a5),d0
                andi.w  #$7F,d0
                bne.w   Entity_UpdateReturn
                lea     Projectile_VictorSplitShotXOffsetTable(pc),a1
                nop
                lea     Projectile_VictorSplitShotYOffsetTable(pc),a2
                nop
                move.w  $4A(a5),d0
                andi.w  #$80,d0
                bne.s   Boss_VictorPrepareLowerSplitShots
                clr.w   d6
Boss_VictorSpawnUpperSplitShots:                        ; was: loc_32B56
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                bsr.w   Projectile_InitSharedHitReactiveShot
                bsr.w   Projectile_VictorInitSplitShot
                addq.w  #2,d6
                cmpi.w  #6,d6
                bne.s   Boss_VictorSpawnUpperSplitShots
                rts
; ---------------------------------------------------------------------------
Boss_VictorPrepareLowerSplitShots:                      ; was: loc_32B72
                move.w  #4,d6
Boss_VictorSpawnLowerSplitShots:                        ; was: loc_32B76
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.w   Entity_UpdateReturn
                bsr.w   Projectile_InitSharedHitReactiveShot
                bsr.w   Projectile_VictorInitSplitShot
                addq.w  #2,d6
                cmpi.w  #$A,d6
                bne.s   Boss_VictorSpawnLowerSplitShots
                rts
; End of function Boss_VictorSpawnSplitShotWave
; Initializes one Victor split shot from a table-selected offset
Projectile_VictorInitSplitShot:                         ; was: sub_32B92
                                        ; Boss_VictorSpawnSplitShotWave+52   p
                move.w  #$3B8,(a0)
                move.w  $14(a5),d0
                add.w   Projectile_VictorSplitShotYOffsetTable(pc,d6.w),d0
                move.w  d0,$14(a0)
                move.w  $10(a5),d0
                cmpi.w  #$120,$10(a5)
                bcs.s   Projectile_VictorPlaceRightwardSplitShot
                sub.w   Projectile_VictorSplitShotXOffsetTable(pc,d6.w),d0
                move.w  d0,$10(a0)
                move.w  #$FFFE,$18(a0)
                rts
; ---------------------------------------------------------------------------
Projectile_VictorPlaceRightwardSplitShot:               ; was: loc_32BBE
                add.w   Projectile_VictorSplitShotXOffsetTable(pc,d6.w),d0
                move.w  d0,$10(a0)
                move.w  #2,$18(a0)
                rts
; End of function Projectile_VictorInitSplitShot
; ---------------------------------------------------------------------------
Projectile_VictorSplitShotXOffsetTable: dc.w    0, $22, $30, $22, 0  ; was: word_32BCE
                                        ; Projectile_VictorInitSplitShot+1C   r
Projectile_VictorSplitShotYOffsetTable: dc.w    $FFD0, $FFDE, 0, $22, $30  ; was: word_32BD8
                                        ; Projectile_VictorInitSplitShot+8   r

; Waits after both split-shot waves before choosing another attack
Boss_VictorWaitAfterSplitShots:                         ; was: sub_32BE2
                bsr.w   Boss_VictorUpdateViewportOffset
                bsr.w   Boss_VictorUpdateAnimation
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #6,4(a5)
                rts
; End of function Boss_VictorWaitAfterSplitShots
; Disables Victor's collision byte and begins the final explosion delay
Boss_VictorBeginDefeatDelay:                            ; was: sub_32BFA
                clr.b   $21(a5)
                move.w  #$100,$4A(a5)
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorBeginDefeatDelay
; Spawns explosion debris during boss death sequence and loads new graphics
Boss_VictorUpdateDefeatExplosion:                       ; was: sub_32C0A
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$20,(PaletteRGBChannelMask).w  ; ' '
                move.b  #8,(PaletteRGBAdjustStep).w
                jsr     (Boss_UpdateDefeatExplosionAndSpawnDebris).l
                cmpi.w  #$88,(a0)
                bne.s   Boss_VictorWaitForDefeatExplosion
                ori.w   #$8000,$E(a0)
Boss_VictorWaitForDefeatExplosion:                      ; was: loc_32C2E
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$E0,(PaletteRGBAdjustLevel).w
                move.b  #$20,(PaletteRGBChannelMask).w  ; ' '
                move.b  #8,(PaletteRGBAdjustStep).w
                movea.l #Boss_VictorDefeatGraphicsLoadDescriptor,a0
                jsr     (Tilemap_QueueIndexedRows).l
                move.w  #$1000,2(a5)
                rts
; End of function Boss_VictorUpdateDefeatExplosion
; ---------------------------------------------------------------------------
Boss_VictorDefeatGraphicsLoadDescriptor:    dc.w    $6000, $2000, $202, 0, 0, 0, 0, $FF  ; was: word_32C5C

; Points an orbiting part at the player and updates its parent-relative position
Boss_VictorOrbitingPartAimAtPlayer:                     ; was: sub_32C6C
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                movea.w a5,a4
                lea     (Entity_ObjectPool).w,a5
                jsr     (Math_CalculateAngleToPlayer).l
                movea.w a4,a5
                move.w  d2,$40(a5)
                bra.w   Entity_UpdatePolarPositionFromParent
; End of function Boss_VictorOrbitingPartAimAtPlayer
; Smoothly tracks the player with an orbiting part
Boss_VictorOrbitingPartTrackPlayer:                     ; was: sub_32C86
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                bsr.w   Boss_VictorTurnPartTowardPlayer
                andi.w  #$1FE,$40(a5)
                bra.w   Entity_UpdatePolarPositionFromParent
; End of function Boss_VictorOrbitingPartTrackPlayer
; Turns an orbiting part toward the player by at most two angle units
Boss_VictorTurnPartTowardPlayer:                        ; was: sub_32C98
                movea.w a5,a4
                lea     (Entity_ObjectPool).w,a5
                jsr     (Math_CalculateAngleToPlayer).l
                movea.w a4,a5
                move.w  $40(a5),d0
                sub.w   d0,d2
                andi.w  #$1FE,d2
                cmpi.w  #8,d2
                bcs.w   Entity_UpdateReturn
                cmpi.w  #$1F8,d2
                bcc.w   Entity_UpdateReturn
                cmpi.w  #$100,d2
                bcc.s   Boss_VictorTurnPartCounterclockwise
                addq.w  #2,$40(a5)
                rts
; ---------------------------------------------------------------------------
Boss_VictorTurnPartCounterclockwise:                    ; was: loc_32CCC
                subq.w  #2,$40(a5)
                rts
; End of function Boss_VictorTurnPartTowardPlayer
; Updates an orbiting part through its radius state
Boss_VictorOrbitingPartRadialMain:                      ; was: sub_32CD2
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                bsr.w   Boss_VictorDispatchOrbitRadiusState
                andi.w  #$1FE,$40(a5)
                bra.w   Entity_UpdatePolarPositionFromParent
; End of function Boss_VictorOrbitingPartRadialMain
; Dispatches the orbit-radius state stored at offset $04
Boss_VictorDispatchOrbitRadiusState:                    ; was: sub_32CE4
                move.w  4(a5),d0
                lea     Boss_VictorOrbitRadiusStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_VictorDispatchOrbitRadiusState
; ---------------------------------------------------------------------------
Boss_VictorOrbitRadiusStates:   dc.w    Boss_VictorRetractOrbitRadius-*  ; was: off_32CF0
                dc.w    Boss_VictorExpandOrbitRadius-*
                dc.w    Boss_VictorExpandOrbitRadiusClamped-*

; Contracts an orbiting part to radius $80
Boss_VictorRetractOrbitRadius:                          ; was: sub_32CF6
                move.w  (SharedScratchLong3+2).w,d0
                add.w   d0,$40(a5)
                subq.w  #1,$42(a5)
                cmpi.w  #$80,$42(a5)
                bne.w   Entity_UpdateReturn
                addq.w  #2,4(a5)
                rts
; End of function Boss_VictorRetractOrbitRadius
; Expands an orbiting part to radius $A8
Boss_VictorExpandOrbitRadius:                           ; was: sub_32D12
                move.w  (SharedScratchLong3+2).w,d0
                add.w   d0,$40(a5)
                addq.w  #1,$42(a5)
                cmpi.w  #$A8,$42(a5)
                bne.w   Entity_UpdateReturn
                subq.w  #2,4(a5)
                rts
; End of function Boss_VictorExpandOrbitRadius
; Rotates an orbiting part while expanding its radius toward $A8
Boss_VictorExpandOrbitRadiusClamped:                    ; was: sub_32D2E
                move.w  (SharedScratchLong3+2).w,d0
                add.w   d0,$40(a5)
                cmpi.w  #$A8,$42(a5)
                beq.w   Entity_UpdateReturn
                addq.w  #1,$42(a5)
                rts
; End of function Boss_VictorExpandOrbitRadiusClamped
; Dispatches a launched part's orbit, contraction, and expiration states
Boss_VictorDetachedPartMain:                            ; was: sub_32D46
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                move.w  4(a5),d0
                lea     Boss_VictorDetachedPartStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_VictorDetachedPartMain
; ---------------------------------------------------------------------------
Boss_VictorDetachedPartStates:  dc.w    Boss_VictorDetachedPartExtendRadius-*  ; was: off_32D56
                dc.w    Boss_VictorDetachedPartContractRadius-*
                dc.w    Boss_VictorDetachedPartRetractAndExpire-*

; Grows a detached part's parent-relative radius by its per-part step
Boss_VictorDetachedPartExtendRadius:                    ; was: sub_32D5C
                move.w  $4C(a5),d0
                add.w   d0,$42(a5)
                bra.w   Entity_UpdatePolarPositionFromParent
; End of function Boss_VictorDetachedPartExtendRadius
; Shrinks a detached part's radius unless it is the thirty-second entity slot
Boss_VictorDetachedPartContractRadius:                  ; was: sub_32D68
                cmpa.l  #ThirtySecondEntityType,a5
                beq.w   Entity_UpdateReturn
                andi.w  #$1FE,$40(a5)
                subq.w  #1,$42(a5)
                bra.w   Entity_UpdatePolarPositionFromParent
; End of function Boss_VictorDetachedPartContractRadius
; Reverses the radial step and removes a detached part when its timer expires
Boss_VictorDetachedPartRetractAndExpire:                ; was: sub_32D80
                move.w  $4C(a5),d0
                sub.w   d0,$42(a5)
                bsr.w   Entity_UpdatePolarPositionFromParent
                subq.w  #1,$4A(a5)
                bne.w   Entity_UpdateReturn
                move.w  #$1000,2(a5)
                rts
; End of function Boss_VictorDetachedPartRetractAndExpire
; Handles part collision effects and horizontal arena removal
Boss_VictorOrbitingPartCollisionMain:                   ; was: sub_32D9C
                bclr    #7,$22(a5)
                beq.s   Boss_VictorPartCheckHorizontalBounds
                bclr    #4,$22(a5)
                beq.w   Projectile_HitReactiveShotSpawnImpact
Boss_VictorPartCheckHorizontalBounds:                   ; was: loc_32DAE
                bsr.w   Entity_RemoveWithExplosionWhenEnabled
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcs.s   Boss_VictorRemovePartOutsideArena
                cmpi.w  #$1E0,$10(a5)
                bcc.s   Boss_VictorRemovePartOutsideArena
                rts
; ---------------------------------------------------------------------------
Boss_VictorRemovePartOutsideArena:                      ; was: loc_32DC4
                                        ; Boss_VictorOrbitingPartCollisionMain+24   j
                move.w  #$1000,2(a5)
                rts
; End of function Boss_VictorOrbitingPartCollisionMain
; Removes an entity with a type-$160 explosion while the effect gate is active
Entity_RemoveWithExplosionWhenEnabled:                  ; was: sub_32DCC
                                        ; sub_32382   p
                tst.w   (SharedScratchLong5+2).w
                beq.w   Entity_UpdateReturn
                jsr     (Projectile_FindFreeSlotReverse).l
                bne.s   Entity_RemoveAfterExplosionAttempt
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.l  #Effect_SpriteAnimation01,8(a0)
                jsr     (Sprite_InitType160).l
Entity_RemoveAfterExplosionAttempt:                     ; was: loc_32DF6
                move.w  #$1000,2(a5)
                rts
; End of function Entity_RemoveWithExplosionWhenEnabled
; Idle state handler
