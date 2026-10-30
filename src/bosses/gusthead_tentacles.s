Boss_GustheadDetachedSegmentInit:                       ; was: sub_40132
                addq.w  #2,4(a5)
                ori.w   #$100,2(a5)
                lea     (Math_SineTable).l,a1
                move.w  $4E(a5),d0
                andi.w  #$1FE,d0
                move.w  (a1,d0.w),d1
                move.w  -$80(a1,d0.w),d2
                ext.l   d1
                lsl.l   #2,d1
                move.l  d1,$18(a5)
                ext.l   d2
                lsl.l   #3,d2
                tst.l   d2
                bmi.s   Boss_GustheadStoreDetachedSegmentVerticalVelocity
                neg.l   d2
Boss_GustheadStoreDetachedSegmentVerticalVelocity:      ; was: loc_40164
                move.l  d2,$1C(a5)
                rts
; End of function Boss_GustheadDetachedSegmentInit
; Applies gravity to a detached segment and converts it to the shared effect below the arena
Boss_GustheadDetachedSegmentFallState:                  ; was: sub_4016A
                addi.l  #$1000,$1C(a5)
                cmpi.w  #$150,$14(a5)
                blt.s   Boss_GustheadDetachedSegmentFallReturn
                clr.l   $1C(a5)
                clr.l   $18(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                move.l  #SharedProjectileDuration4Animation,8(a5)
                move.w  #$4000,$E(a5)
Boss_GustheadDetachedSegmentFallReturn:                 ; was: locret_40196
                rts
; End of function Boss_GustheadDetachedSegmentFallState
Boss_GustheadDetachedSegmentInactiveState:              ; was: nullsub_81
                rts
; End of function Boss_GustheadDetachedSegmentInactiveState

; Spawns side debris while arena motion is active
Boss_GustheadSpawnScrollingDebris:                      ; was: sub_4019A
                                        ; Boss_GustheadWaitForMiddleJointZeroState+C   p
                tst.l   (SharedScratchLong10).w
                beq.w   Boss_GustheadUpdateSegmentPositionsReturn
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.w   Boss_GustheadUpdateSegmentPositionsReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.w   Boss_GustheadUpdateSegmentPositionsReturn
                move.w  (FrameCounter).w,d0
                andi.w  #$3F,d0                         ; '?'
                bne.s   Boss_GustheadSpawnScrollingDebrisObject
                move.w  #$D1,d0
                jsr     (Sound_QueueSFXRequest).l
Boss_GustheadSpawnScrollingDebrisObject:                ; was: loc_401CC
                move.w  #$1E4,(a0)
                move.l  #Effect_SpriteFrame35,8(a0)
                move.w  #$480,$E(a0)
                move.w  #$CC40,2(a0)
                move.b  #$7C,$20(a0)                    ; '|'
                move.w  #$100,$48(a0)
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                subi.w  #$80,d0
                addi.w  #$F0,d0
                move.w  d0,$14(a0)
                move.l  (SharedScratchLong10).w,d0
                add.l   d0,d0
                move.l  d0,$18(a0)
                move.l  #$FFFFF000,$1C(a0)
                btst    #7,(SharedScratchLong10).w
                beq.s   Boss_GustheadUseLeftDebrisSpawnX
                move.w  #$1C4,$10(a0)
                rts
; ---------------------------------------------------------------------------
Boss_GustheadUseLeftDebrisSpawnX:                       ; was: loc_40226
                move.w  #$7C,$10(a0)                    ; '|'
                rts
; End of function Boss_GustheadSpawnScrollingDebris
; Updates type-$1E4 debris spawned by the scrolling arena effect
Boss_GustheadUpdateScrollingDebris:                     ; was: sub_4022E
                subq.w  #1,$48(a5)
                bmi.s   Boss_GustheadDeactivateScrollingDebris
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcs.s   Boss_GustheadDeactivateScrollingDebris
                cmpi.w  #$1E0,$10(a5)
                bhi.s   Boss_GustheadDeactivateScrollingDebris
                cmpi.w  #$60,$14(a5)                    ; '`'
                bcs.s   Boss_GustheadDeactivateScrollingDebris
                cmpi.w  #$180,$14(a5)
                bhi.s   Boss_GustheadDeactivateScrollingDebris
                move.l  (SharedScratchLong10).w,d0
                beq.s   Boss_GustheadScrollingDebrisApplyStrongGravity
                addq.b  #1,$4A(a5)
                btst    #0,$4A(a5)
                beq.s   Boss_GustheadScrollingDebrisApplyDriftGravity
                add.l   d0,$18(a5)
Boss_GustheadScrollingDebrisApplyDriftGravity:          ; was: loc_4026A
                addi.l  #$400,$1C(a5)
                bra.s   Boss_GustheadScrollingDebrisIntegrateVerticalPosition
; ---------------------------------------------------------------------------
Boss_GustheadScrollingDebrisApplyStrongGravity:         ; was: loc_40274
                addi.l  #$2000,$1C(a5)
Boss_GustheadScrollingDebrisIntegrateVerticalPosition:  ; was: loc_4027C
                move.l  $1C(a5),d0
                add.l   d0,$14(a5)
                rts
; ---------------------------------------------------------------------------
Boss_GustheadDeactivateScrollingDebris:                 ; was: loc_40286
                                        ; Boss_GustheadUpdateScrollingDebris+C   j
                bset    #4,2(a5)
                rts
; End of function Boss_GustheadUpdateScrollingDebris
; Spawns a shrimp or a fish at the arena edge selected by scroll direction
Boss_GustheadSpawnEdgeDebris:                           ; was: sub_4028E
                move.w  (FrameCounter).w,d0
                andi.w  #$1F,d0
                bne.s   Boss_GustheadSpawnEdgeDebrisReturn
                tst.l   (StageMotionXDelta).w
                beq.s   Boss_GustheadSpawnEdgeDebrisReturn
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_GustheadSpawnEdgeDebrisReturn
                move.w  #$1E8,(a0)
                move.w  #$ED00,2(a0)
                bsr.w   Boss_GustheadAssignRandomDebrisMapping
                move.b  #$C0,$21(a0)
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #2,$24(a0)
                move.w  #8,$26(a0)
                move.b  #$10,$20(a0)
                move.w  #$F0,$14(a0)
                tst.l   (StageMotionXDelta).w
                bmi.s   Boss_GustheadUseRightDebrisSpawnX
                move.w  #$78,$10(a0)                    ; 'x'
Boss_GustheadSpawnEdgeDebrisReturn:                     ; was: locret_402EE
                                        ; Boss_GustheadSpawnEdgeDebris+E   j
                rts
; ---------------------------------------------------------------------------
Boss_GustheadUseRightDebrisSpawnX:                      ; was: loc_402F0
                move.w  #$1C8,$10(a0)
                rts
; End of function Boss_GustheadSpawnEdgeDebris
; Assigns one of four random mappings shared by edge and four-way debris
Boss_GustheadAssignRandomDebrisMapping:                 ; was: sub_402F8
                                        ; Boss_GustheadSpawnFourWayDebris+46   p
                jsr     (RandomNumber).l
                move.b  (RandomNumberState).w,d0
                andi.w  #3,d0
                add.w   d0,d0
                add.w   d0,d0
                move.l  Boss_GustheadShrimpAndFishAnimations(pc,d0.w),8(a0)
                move.w  #$8000,$E(a0)
                rts
; End of function Boss_GustheadAssignRandomDebrisMapping
; ---------------------------------------------------------------------------
Boss_GustheadShrimpAndFishAnimations:   dc.l    Enemy_ShrimpSlowAnimation  ; was: off_40318
                dc.l    Enemy_FishLoopAnimation
                dc.l    Enemy_ShrimpFastAnimation
                dc.l    Enemy_FishLoopAnimation

; Handles collision and state dispatch for type-$1E8 edge debris
Boss_GustheadEdgeDebrisMain:                            ; was: sub_40328
                tst.w   $24(a5)
                bmi.s   Boss_GustheadEdgeDebrisBeginPickupRelease
                bclr    #7,$22(a5)
                beq.s   Boss_GustheadEdgeDebrisDispatchState
                bclr    #4,$22(a5)
                beq.s   Boss_GustheadEdgeDebrisConvertToEffect
Boss_GustheadEdgeDebrisBeginPickupRelease:              ; was: loc_4033E
                bra.w   Boss_GustheadReleaseDebrisAsPickup
; ---------------------------------------------------------------------------
Boss_GustheadEdgeDebrisConvertToEffect:                 ; was: loc_40342
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #Effect_SpriteAnimation05,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Boss_GustheadEdgeDebrisDispatchState:                   ; was: loc_40358
                move.w  4(a5),d0
                lea     Boss_GustheadEdgeDebrisStates(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Boss_GustheadEdgeDebrisMain
; ---------------------------------------------------------------------------
Boss_GustheadEdgeDebrisStates:  dc.w    Boss_GustheadInitializeEdgeDebrisMotion-*  ; was: off_40364
                dc.w    Boss_GustheadUpdateEdgeDebrisPhysics-*
                dc.w    Boss_GustheadEdgeDebrisInactiveState-*

; Initializes type-$1E8 edge debris from arena motion and RNG
Boss_GustheadInitializeEdgeDebrisMotion:                ; was: sub_4036A
                addq.w  #2,4(a5)
                move.l  (StageMotionXDelta).w,d0
                add.l   d0,d0
                add.l   d0,d0
                tst.w   (DifficultyMode).w
                bne.s   Boss_GustheadStoreEdgeDebrisHorizontalVelocity
                add.l   d0,d0
Boss_GustheadStoreEdgeDebrisHorizontalVelocity:         ; was: loc_4037E
                move.l  d0,$18(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$FFF,d0
                subi.w  #$800,d0
                ext.l   d0
                move.l  d0,$4C(a5)
                rts
; End of function Boss_GustheadInitializeEdgeDebrisMotion
; Updates type-$1E8 edge-debris bounds, gravity, and floor conversion
Boss_GustheadUpdateEdgeDebrisPhysics:                   ; was: sub_40396
                bsr.w   Boss_GustheadUpdateDebrisVerticalFlip
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcs.s   Boss_GustheadDeactivateEdgeDebrisOutOfBounds
                cmpi.w  #$1E0,$10(a5)
                bhi.s   Boss_GustheadDeactivateEdgeDebrisOutOfBounds
                cmpi.w  #$60,$14(a5)                    ; '`'
                bcs.s   Boss_GustheadDeactivateEdgeDebrisOutOfBounds
                cmpi.w  #$180,$14(a5)
                bhi.s   Boss_GustheadDeactivateEdgeDebrisOutOfBounds
                move.l  $4C(a5),d0
                add.l   d0,$1C(a5)
                btst    #7,$1C(a5)
                beq.w   Boss_GustheadConvertDebrisToBouncingEffectAtFloor
                rts
; ---------------------------------------------------------------------------
Boss_GustheadDeactivateEdgeDebrisOutOfBounds:           ; was: loc_403CE
                                        ; Boss_GustheadUpdateEdgeDebrisPhysics+12   j
                bset    #4,2(a5)
                rts
; End of function Boss_GustheadUpdateEdgeDebrisPhysics
Boss_GustheadEdgeDebrisInactiveState:                   ; was: nullsub_82
                rts
; End of function Boss_GustheadEdgeDebrisInactiveState

; Selects the debris vertical flip from the sign of vertical velocity
Boss_GustheadUpdateDebrisVerticalFlip:                  ; was: sub_403D8
                                        ; sub_4046C:Boss_GustheadApplyFourWayDebrisPhysics   p
                btst    #7,$1C(a5)
                bne.s   Boss_GustheadClearDebrisVerticalFlip
                ori.w   #$1000,$E(a5)
                rts
; ---------------------------------------------------------------------------
Boss_GustheadClearDebrisVerticalFlip:                   ; was: loc_403E8
                andi.w  #$EFFF,$E(a5)
                rts
; End of function Boss_GustheadUpdateDebrisVerticalFlip
; Spawns 4 debris projectiles with trajectories from angle table
Boss_GustheadSpawnFourWayDebris:                        ; was: sub_403F0
                lea     (Math_SineTable).l,a1
                move.w  #3,d7
                move.w  #$120,d6
Boss_GustheadFourWayDebrisLoop:                         ; was: loc_403FE
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_GustheadFourWayDebrisReturn
                move.w  (a1,d6.w),d0
                ext.l   d0
                asl.l   #4,d0
                move.l  d0,$18(a0)
                move.l  #$FFFA0000,$1C(a0)
                move.w  #$214,(a0)
                move.w  #$ED40,2(a0)
                move.l  $10(a5),$10(a0)
                move.l  $14(a5),$14(a0)
                addi.w  #$10,$14(a0)
                bsr.w   Boss_GustheadAssignRandomDebrisMapping
                move.b  #$10,$20(a0)
                move.b  #$C0,$21(a0)
                move.l  #$FE02FE02,$2C(a0)
                move.l  #$F808F808,$28(a0)
                move.w  #2,$24(a0)
                move.w  #$10,$26(a0)
                addi.w  #$40,d6                         ; '@'
                dbf     d7,Boss_GustheadFourWayDebrisLoop
Boss_GustheadFourWayDebrisReturn:                       ; was: locret_4046A
                rts
; End of function Boss_GustheadSpawnFourWayDebris
; Updates type-$214 four-way debris collision, bounds, gravity, and floor conversion
Boss_GustheadUpdateFourWayDebris:                       ; was: sub_4046C
                tst.w   $24(a5)
                bmi.s   Boss_GustheadFourWayDebrisBeginPickupRelease
                bclr    #7,$22(a5)
                beq.s   Boss_GustheadApplyFourWayDebrisPhysics
                bclr    #4,$22(a5)
                beq.s   Boss_GustheadFourWayDebrisConvertToEffect
Boss_GustheadFourWayDebrisBeginPickupRelease:           ; was: loc_40482
                bra.w   Boss_GustheadReleaseDebrisAsPickup
; ---------------------------------------------------------------------------
Boss_GustheadFourWayDebrisConvertToEffect:              ; was: loc_40486
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #Effect_SpriteAnimation05,8(a5)
                jmp     Projectile_InitType88FromCurrent
; ---------------------------------------------------------------------------
Boss_GustheadApplyFourWayDebrisPhysics:                 ; was: loc_4049C
                bsr.w   Boss_GustheadUpdateDebrisVerticalFlip
                cmpi.w  #$60,$10(a5)                    ; '`'
                bcs.s   Boss_GustheadDeactivateFourWayDebrisOutOfBounds
                cmpi.w  #$1E0,$10(a5)
                bhi.s   Boss_GustheadDeactivateFourWayDebrisOutOfBounds
                cmpi.w  #$60,$14(a5)                    ; '`'
                bcs.s   Boss_GustheadDeactivateFourWayDebrisOutOfBounds
                cmpi.w  #$180,$14(a5)
                bhi.s   Boss_GustheadDeactivateFourWayDebrisOutOfBounds
                addi.l  #$2000,$1C(a5)
                btst    #7,$1C(a5)
                beq.w   Boss_GustheadConvertDebrisToBouncingEffectAtFloor
                rts
; ---------------------------------------------------------------------------
Boss_GustheadDeactivateFourWayDebrisOutOfBounds:        ; was: loc_404D4
                                        ; Boss_GustheadUpdateFourWayDebris+42   j
                bset    #4,2(a5)
                rts
; End of function Boss_GustheadUpdateFourWayDebris
; Unreferenced helper that converts current Gusthead debris to the type-$88 effect
Boss_GustheadConvertCurrentDebrisToEffect:              ; was: sub_404DC
                clr.l   $18(a5)
                clr.l   $1C(a5)
                move.l  #Effect_SpriteAnimation05,8(a5)
                jmp     Projectile_InitType88FromCurrent
; End of function Boss_GustheadConvertCurrentDebrisToEffect
; Converts edge or four-way debris at the floor to an upward type-$88 effect
Boss_GustheadConvertDebrisToBouncingEffectAtFloor:      ; was: sub_404F2
                                        ; Boss_GustheadUpdateFourWayDebris+62   j
                cmpi.w  #$150,$14(a5)
                blt.s   Boss_GustheadConvertDebrisToBouncingEffectAtFloor_Return
                move.l  #SharedProjectileDuration4Animation,8(a5)
                jsr     (Projectile_InitType88FromCurrent).l
                move.w  #$C000,$E(a5)
                move.l  #$FFFD8000,$1C(a5)
                clr.w   $18(a5)
Boss_GustheadConvertDebrisToBouncingEffectAtFloor_Return:  ; was: locret_4051A
                rts
; End of function Boss_GustheadConvertDebrisToBouncingEffectAtFloor
; Updates boss rotation animation
Boss_GustheadUpdateSegmentMapping:                      ; was: sub_4051C
                movea.w a5,a0
                clr.w   d0
                move.b  $20(a0),d0
                addi.w  #2,d0
                andi.w  #$7F,d0
                subi.w  #$20,d0                         ; ' '
                andi.w  #$3C,d0                         ; '<'
                move.l  Boss_GustheadSegmentMappings(pc,d0.w),8(a0)
                clr.w   $C(a0)
                lsr.w   #1,d0
                lea     (GustheadMappingCounts).w,a1
                addq.w  #1,(a1,d0.w)
                rts
; End of function Boss_GustheadUpdateSegmentMapping
; ---------------------------------------------------------------------------
Boss_GustheadSegmentMappings:   dc.l    Boss_GustheadSegmentMappingA  ; was: off_4054A
                dc.l    Boss_GustheadSegmentMappingA
                dc.l    Boss_GustheadSegmentMappingA
                dc.l    Boss_GustheadSegmentMappingB
                dc.l    Boss_GustheadSegmentMappingB
                dc.l    Boss_GustheadSegmentMappingC
                dc.l    Boss_GustheadSegmentMappingC
                dc.l    Boss_GustheadSegmentMappingD
                dc.l    Boss_GustheadSegmentMappingD
                dc.l    Boss_GustheadSegmentMappingE
                dc.l    Boss_GustheadSegmentMappingE
                dc.l    Boss_GustheadSegmentMappingF
                dc.l    Boss_GustheadSegmentMappingF
                dc.l    Boss_GustheadSegmentMappingG
                dc.l    Boss_GustheadSegmentMappingG
                dc.l    Boss_GustheadSegmentMappingG

; Derives arena scroll velocity from the active joint speed
Boss_GustheadUpdateArenaScrollVelocity:                 ; was: sub_4058A
                                        ; Boss_GustheadWaitForMiddleJointZeroState+8   p
                move.l  (SharedScratchLong3).w,d0
                bne.s   Boss_GustheadScaleArenaScrollVelocity
                move.l  (SharedScratchLong5).w,d0
                beq.s   Boss_GustheadStoreArenaScrollVelocity
Boss_GustheadScaleArenaScrollVelocity:                  ; was: loc_40596
                tst.w   (DifficultyMode).w
                bne.s   Boss_GustheadUseFullArenaScrollVelocity
                asr.l   #5,d0
                bra.s   Boss_GustheadStoreArenaScrollVelocity
; ---------------------------------------------------------------------------
Boss_GustheadUseFullArenaScrollVelocity:                ; was: loc_405A0
                asr.l   #4,d0
Boss_GustheadStoreArenaScrollVelocity:                  ; was: loc_405A2
                                        ; Boss_GustheadUpdateArenaScrollVelocity+14   j
                move.l  d0,(StageMotionXDelta).w
                rts
; End of function Boss_GustheadUpdateArenaScrollVelocity
; Advances the three shared fixed-point joint angles
Boss_GustheadAdvanceJointAngles:                        ; was: sub_405A8
                                        ; Boss_GustheadBattleStart+20   p
                tst.l   (SharedScratchLong3).w
                beq.s   Boss_GustheadAdvanceMiddleJoint
                move.l  (SharedScratchLong3).w,d0
                add.l   d0,(SharedScratchLong0).w
                andi.w  #$1FF,(SharedScratchLong0).w
Boss_GustheadAdvanceMiddleJoint:                        ; was: loc_405BC
                tst.l   (SharedScratchLong4).w
                beq.s   Boss_GustheadAdvanceInnerJoint
                move.l  (SharedScratchLong4).w,d0
                add.l   d0,(SharedScratchLong1).w
                andi.w  #$1FF,(SharedScratchLong1).w
Boss_GustheadAdvanceInnerJoint:                         ; was: loc_405D0
                tst.l   (SharedScratchLong5).w
                beq.s   Boss_GustheadAdvanceJointAnglesReturn
                move.l  (SharedScratchLong5).w,d0
                add.l   d0,(SharedScratchLong2).w
                andi.w  #$1FF,(SharedScratchLong2).w
Boss_GustheadAdvanceJointAnglesReturn:                  ; was: locret_405E4
                rts
; End of function Boss_GustheadAdvanceJointAngles
; Sets the first arm's four segment state words to zero
Boss_GustheadDisableFirstArmSegments:                   ; was: sub_405E6
                clr.w   d0
                bra.s   Boss_GustheadStoreFirstArmSegmentState
; End of function Boss_GustheadDisableFirstArmSegments
; Sets the first arm's four segment state words to two
Boss_GustheadEnableFirstArmSegments:                    ; was: sub_405EA
                move.w  #2,d0
Boss_GustheadStoreFirstArmSegmentState:                 ; was: loc_405EE
                move.w  #3,d7
                movea.l (Entity_ObjectPool).w,a0
                lea     $60(a0),a0
Boss_GustheadFirstArmSegmentStateLoop:                  ; was: loc_405FA
                move.w  d0,4(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_GustheadFirstArmSegmentStateLoop
                rts
; End of function Boss_GustheadEnableFirstArmSegments
; Seeds the first arm's segment joint-angle fields from the shared angles
Boss_GustheadSeedFirstArmJointAngles:                   ; was: sub_40608
                move.w  #3,d7
                movea.w (Entity_ObjectPool).w,a0
                lea     $60(a0),a0
Boss_GustheadSeedFirstArmJointAngleLoop:                ; was: loc_40614
                clr.w   d0
                move.b  $4B(a0),d0
                add.w   d0,d0
                add.w   (SharedScratchLong0).w,d0
                andi.w  #$1FF,d0
                move.w  d0,$4E(a0)
                clr.w   d0
                move.b  $4C(a0),d0
                add.w   d0,d0
                add.w   (SharedScratchLong1).w,d0
                andi.w  #$1FF,d0
                move.w  d0,$50(a0)
                clr.w   d0
                move.b  $4C(a0),d0
                add.w   d0,d0
                add.w   (SharedScratchLong2).w,d0
                andi.w  #$1FF,d0
                move.w  d0,$52(a0)
                lea     $60(a0),a0
                dbf     d7,Boss_GustheadSeedFirstArmJointAngleLoop
                rts
; End of function Boss_GustheadSeedFirstArmJointAngles
; Recomputes all four arms of four linked segment positions
Boss_GustheadUpdateSegmentPositions:                    ; was: sub_4065A
                                        ; Boss_GustheadBattleStart+24   p
                move.l  $10(a5),$670(a5)
                move.l  $14(a5),$674(a5)
                addi.w  #$1A,$670(a5)
                addi.w  #-6,$674(a5)
                move.w  #4,$5C(a5)
                movea.w a5,a0
                lea     $60(a0),a0
Boss_GustheadUpdateArmLoop:                             ; was: loc_4067E
                move.w  #3,d0
                movea.w a5,a1
Boss_GustheadUpdateSegmentLoop:                         ; was: loc_40684
                lea     (Math_SineTable).l,a2
                move.w  $48(a0),d4
                move.w  $4E(a0),d5
                move.w  $50(a0),d6
                move.w  $52(a0),d7
                andi.w  #$1FE,d5
                andi.w  #$1FE,d6
                andi.w  #$1FE,d7
                move.w  -$80(a2,d5.w),d1
                muls.w  d4,d1
                swap    d1
                add.w   d1,d1
                add.w   d1,d1
                move.w  (a2,d6.w),d2
                muls.w  d2,d1
                swap    d1
                add.w   d1,d1
                add.w   d1,d1
                asr.w   #2,d1
                cmpi.w  #$3F,d1                         ; '?'
                blt.s   Boss_GustheadClampSegmentFrameMinimum
                move.w  #$3F,d1                         ; '?'
                bra.s   Boss_GustheadStoreSegmentFrame
; ---------------------------------------------------------------------------
Boss_GustheadClampSegmentFrameMinimum:                  ; was: loc_406CC
                cmpi.w  #$FFC1,d1
                bgt.s   Boss_GustheadStoreSegmentFrame
                move.w  #$FFC1,d1
Boss_GustheadStoreSegmentFrame:                         ; was: loc_406D6
                                        ; Boss_GustheadUpdateSegmentPositions+76   j
                clr.w   d2
                move.b  $20(a1),d2
                add.w   d2,d1
                move.b  d1,$20(a0)
                move.w  (a2,d5.w),d1
                move.w  (a2,d7.w),d2
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                move.l  d2,d3
                move.w  -$80(a2,d5.w),d1
                move.w  -$80(a2,d6.w),d2
                muls.w  d1,d2
                swap    d2
                add.w   d2,d2
                add.w   d2,d2
                move.w  -$80(a2,d7.w),d1
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                sub.l   d2,d3
                swap    d3
                muls.w  d4,d3
                add.l   d3,d3
                add.l   d3,d3
                add.l   $10(a1),d3
                move.l  d3,$10(a0)
                move.w  (a2,d5.w),d1
                move.w  -$80(a2,d7.w),d2
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                move.l  d2,d3
                move.w  -$80(a2,d5.w),d1
                move.w  -$80(a2,d6.w),d2
                muls.w  d1,d2
                swap    d2
                add.w   d2,d2
                add.w   d2,d2
                move.w  (a2,d7.w),d1
                muls.w  d1,d2
                add.l   d2,d2
                add.l   d2,d2
                add.l   d2,d3
                swap    d3
                muls.w  d4,d3
                add.l   d3,d3
                add.l   d3,d3
                add.l   $14(a1),d3
                move.l  d3,$14(a0)
                lea     (a0),a1
                lea     $60(a0),a0
                dbf     d0,Boss_GustheadUpdateSegmentLoop
                subq.w  #1,$5C(a5)
                bne.w   Boss_GustheadUpdateArmLoop
Boss_GustheadUpdateSegmentPositionsReturn:              ; was: locret_4076C
                                        ; Boss_GustheadBeginOscillationPattern+56   j
                rts
; End of function Boss_GustheadUpdateSegmentPositions
; Converts Gusthead debris to a pickup, optionally spawning a shared effect
Boss_GustheadReleaseDebrisAsPickup:                     ; was: sub_4076E
                                        ; sub_4046C:Boss_GustheadFourWayDebrisBeginPickupRelease   j
                clr.l   $18(a5)
                clr.l   $1C(a5)
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Boss_GustheadSpawnPickupFromDebris
                jsr     (Projectile_InitType88).l
                move.l  #Effect_SpriteAnimation05,8(a0)
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
Boss_GustheadSpawnPickupFromDebris:                     ; was: loc_40798
                jmp     Pickup_SpawnSmallFromCurrentObject
; End of function Boss_GustheadReleaseDebrisAsPickup
; Main handler for Snake boss
