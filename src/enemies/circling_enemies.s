; Initializes sprite and collision parameters for circling enemy families
Enemy_InitCirclingSprite:                               ; was: sub_2D27C
                                        ; Enemy_Stage9FlyInit+2   p
                move.w  #$ED00,2(a5)
                move.w  (CirclingEnemyTileAttr).w,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.l  #$FF01FF01,$2C(a5)
                move.l  #$F808F808,$28(a5)
                lea     Enemy_CirclingSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_InitCirclingSprite
; ---------------------------------------------------------------------------
Enemy_CirclingSpriteParameters: dc.w    $1802, $1100, $1802, $1100  ; was: word_2D2CA

; Updates the current circling-enemy animation mapping
Enemy_UpdateCirclingAnimation:                          ; was: sub_2D2D2
                                        ; Enemy_Stage9FlyController+2C   j
                move.w  $5C(a5),d0
                beq.s   Enemy_UpdateCirclingAnimation_Return
                move.w  #$ED00,2(a5)
                subq.w  #4,d0
                move.l  Enemy_BeeMappings(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_UpdateCirclingAnimation_Return:                   ; was: locret_2D2EA
                rts
; End of function Enemy_UpdateCirclingAnimation
; ---------------------------------------------------------------------------
Enemy_BeeMappings:  dc.l    Enemy_BeeLoopAnimation      ; was: off_2D2EC

; Selects sprite mapping and attributes from the current rotation angle
Enemy_UpdateFlySprite:                                  ; was: sub_2D2F0
                                        ; Enemy_CirclingExitOrbitState+C   p
                move.w  $4C(a5),d0
                addi.w  #$10,d0
                andi.w  #$1E0,d0
                lsr.w   #3,d0
                move.l  Enemy_FlyMappings(pc,d0.w),8(a5)
                clr.w   $C(a5)
                lsr.w   #1,d0
                move.w  (CirclingEnemyTileAttr).w,d1
                andi.w  #$F7FF,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                or.w    Enemy_FlyAttributes(pc,d0.w),d1
                move.w  d1,$E(a5)
                move.w  #$CD00,2(a5)
                rts
; End of function Enemy_UpdateFlySprite
; ---------------------------------------------------------------------------
Enemy_FlyMappings:  dc.l    Enemy_FlySpriteMapping0     ; was: off_2D326
                dc.l    Enemy_FlySpriteMapping1
                dc.l    Enemy_FlySpriteMapping2
                dc.l    Enemy_FlySpriteMapping3
                dc.l    Enemy_FlySpriteMapping4
                dc.l    Enemy_FlySpriteMapping3
                dc.l    Enemy_FlySpriteMapping2
                dc.l    Enemy_FlySpriteMapping1
                dc.l    Enemy_FlySpriteMapping0
                dc.l    Enemy_FlySpriteMapping1
                dc.l    Enemy_FlySpriteMapping2
                dc.l    Enemy_FlySpriteMapping3
                dc.l    Enemy_FlySpriteMapping4
                dc.l    Enemy_FlySpriteMapping3
                dc.l    Enemy_FlySpriteMapping2
                dc.l    Enemy_FlySpriteMapping1
Enemy_FlyAttributes:
                dc.w    $800, $1800, $1800, $1800, $1800, $1000, $1000, $1000  ; was: word_2D366
                dc.w    0, 0, 0, 0, $800, $800, $800, $800

; Updates circular velocity and periodically launches a homing projectile
Enemy_UpdateCircularMotionAndFire:                      ; was: sub_2D386
                                        ; Enemy_CirclingExitOrbitState+18   p
                move.w  $4C(a5),d0
                andi.w  #$1FE,d0
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d0.w),d1
                move.w  (a1,d0.w),d0
                muls.w  d2,d0
                muls.w  d3,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                move.w  (FrameCounter).w,d0
                add.w   a5,d0
                andi.w  #$7F,d0
                bne.s   Enemy_UpdateCircularMotionAndFire_Return
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$20,d0                         ; ' '
                bcs.s   Enemy_UpdateCircularMotionAndFire_Return
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_UpdateCircularMotionAndFire_Return
                move.w  a0,$56(a5)
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  d2,d6
                clr.w   d0
                clr.w   d1
                move.w  #$8004,d2
                movea.w $56(a5),a0
                jsr     (Projectile_InitializeDifficultyScaledTwoSpeedShot).l
Enemy_UpdateCircularMotionAndFire_Return:               ; was: locret_2D3E6
                                        ; Enemy_UpdateCircularMotionAndFire+38   j
                rts
; End of function Enemy_UpdateCircularMotionAndFire

Enemy_CirclingController:                               ; was: sub_2D3E8
                tst.w   4(a5)
                beq.s   Enemy_CirclingController_UpdateState
                tst.w   $24(a5)
                bmi.w   Enemy_ResetCirclingState
                bclr    #7,$22(a5)
                bne.w   Enemy_ResetCirclingState
                tst.w   (StageSpawnCountdown).w
                bpl.w   Enemy_ResetCirclingState
                jsr     (RandomNumber).l
                clr.w   6(a5)
; Executes circular movement pattern and updates sprite
Enemy_CirclingController_UpdateState:                   ; was: loc_2D412
                bsr.s   Enemy_DispatchCirclingState
                bra.w   Enemy_UpdateCirclingAnimation
; End of function Enemy_CirclingController
; Dispatches to circle enemy state handlers
Enemy_DispatchCirclingState:                            ; was: sub_2D418
                clr.w   $5C(a5)
                move.w  4(a5),d0
                lea     Enemy_CirclingStateOffsets(pc,d0.w),a0
                adda.w  (a0),a0
                jmp     (a0)
; End of function Enemy_DispatchCirclingState
; ---------------------------------------------------------------------------
Enemy_CirclingStateOffsets: dc.w    Enemy_CirclingApproachState-*  ; was: off_2D428
                dc.w    Enemy_CirclingApproachState_CheckDistance-*
                dc.w    Enemy_CirclingOrbitState-*
                dc.w    Enemy_CirclingExitOrbitState-*
                dc.w    Enemy_CirclingNoOpState-*

; Approach player until within distance threshold
Enemy_CirclingApproachState:                            ; was: sub_2D432
                moveq   #0,d0
                bsr.w   Enemy_InitCirclingSprite
                move.w  #4,$5C(a5)
                bsr.w   Enemy_CirclingInitApproachVelocity
                addq.w  #2,4(a5)
; Calculate distance to player and determine next action
Enemy_CirclingApproachState_CheckDistance:              ; was: loc_2D446
                jsr     (Physics_GetPlayerDelta).l
                cmpi.w  #$60,d0                         ; '`'
                bcs.s   Enemy_CirclingApproachState_BeginOrbit
                bra.w   Enemy_CirclingSteerTowardTarget
; ---------------------------------------------------------------------------
Enemy_CirclingApproachState_BeginOrbit:                 ; was: loc_2D456
                move.w  #$180,$4C(a5)
                move.w  #$10,$4A(a5)
                move.w  #$10,$48(a5)
                move.w  #$100,$50(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_CirclingApproachState
; Calculates velocity vector from random angle toward player
Enemy_CirclingInitApproachVelocity:                     ; was: sub_2D474
                move.w  $10(a5),$52(a5)
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   d0,$52(a5)
                move.w  $14(a5),$54(a5)
                move.w  (RandomNumberState).w,d0
                andi.w  #$FF,d0
                add.w   d0,d0
                lea     (Math_SineTable).l,a1
                move.w  Math_QuarterSineTable-Math_SineTable(a1,d0.w),d1
                move.w  (a1,d0.w),d0
                ext.l   d0
                ext.l   d1
                asl.l   #3,d0
                asl.l   #3,d1
                move.l  d0,$18(a5)
                move.l  d1,$1C(a5)
                rts
; End of function Enemy_CirclingInitApproachVelocity
; Steers toward a randomized point around the stored target position
Enemy_CirclingSteerTowardTarget:                        ; was: sub_2D4B2
                move.w  $52(a5),d0
                move.b  (RandomNumberState).w,d7
                andi.w  #$3F,d7                         ; '?'
                subi.w  #$20,d7                         ; ' '
                add.w   d7,d0
                move.w  $10(a5),d1
                add.w   (PrimaryCameraXPosition).w,d1
                sub.w   d1,d0
                beq.s   Enemy_CirclingSteerTowardTarget_UpdateVertical
                tst.w   d0
                bpl.s   Enemy_CirclingSteerTowardTarget_AccelerateRight
                subi.l  #$4000,$18(a5)
                cmpi.l  #$FFFE0000,$18(a5)
                bge.s   Enemy_CirclingSteerTowardTarget_UpdateVertical
                move.l  #$FFFE0000,$18(a5)
                bra.s   Enemy_CirclingSteerTowardTarget_UpdateVertical
; ---------------------------------------------------------------------------
Enemy_CirclingSteerTowardTarget_AccelerateRight:        ; was: loc_2D4F0
                addi.l  #$4000,$18(a5)
                cmpi.l  #$20000,$18(a5)
                ble.s   Enemy_CirclingSteerTowardTarget_UpdateVertical
                move.l  #$20000,$18(a5)
Enemy_CirclingSteerTowardTarget_UpdateVertical:         ; was: loc_2D50A
                                        ; Enemy_CirclingSteerTowardTarget+32   j
                move.w  $54(a5),d0
                move.b  (RandomNumberState+1).w,d7
                andi.w  #$3F,d7                         ; '?'
                subi.w  #$20,d7                         ; ' '
                add.w   d7,d0
                sub.w   $14(a5),d0
                beq.s   Enemy_CirclingSteerTowardTarget_Return
                tst.w   d0
                bpl.s   Enemy_CirclingSteerTowardLowerTarget
                subi.l  #$4000,$1C(a5)
                cmpi.l  #$FFFE0000,$1C(a5)
                bge.s   Enemy_CirclingSteerTowardTarget_Return
                move.l  #$FFFE0000,$1C(a5)
                rts
; ---------------------------------------------------------------------------
; Accelerates downward toward a lower target, capped at the positive speed limit
Enemy_CirclingSteerTowardLowerTarget:                   ; was: loc_2D542
                addi.l  #$4000,$1C(a5)
                cmpi.l  #$20000,$1C(a5)
                ble.s   Enemy_CirclingSteerTowardTarget_Return
                move.l  #$20000,$1C(a5)
Enemy_CirclingSteerTowardTarget_Return:                 ; was: locret_2D55C
                                        ; Enemy_CirclingSteerTowardTarget+84   j
                rts
; End of function Enemy_CirclingSteerTowardTarget
; Circles player with adaptive rotation speed
Enemy_CirclingOrbitState:                               ; was: sub_2D55E
                move.w  $4A(a5),d0
                add.w   d0,$4C(a5)
                andi.w  #$1FF,$4C(a5)
                bsr.w   Enemy_UpdateFlySprite
                move.w  #$10,d2
                move.w  #$10,d3
                bsr.w   Enemy_UpdateCircularMotionAndFire
                subq.w  #1,$48(a5)
                bpl.s   Enemy_CirclingOrbitState_UpdateLifetime
                addq.w  #1,$4E(a5)
                move.w  $4E(a5),d0
                andi.w  #3,d0
                bne.s   Enemy_CirclingOrbitState_AdjustRotation
                move.w  #$10,$4A(a5)
                move.w  #$10,$48(a5)
                bra.s   Enemy_CirclingOrbitState_UpdateLifetime
; ---------------------------------------------------------------------------
Enemy_CirclingOrbitState_AdjustRotation:                ; was: loc_2D59E
                move.b  (RandomNumberState).w,d0
                andi.w  #$1F,d0
                move.w  d0,$48(a5)
                jsr     (Math_CalculateAngleToPlayer).l
                move.w  $4C(a5),d0
                sub.w   d2,d0
                andi.w  #$1FF,d0
                cmpi.w  #$100,d0
                bcs.s   Enemy_CirclingOrbitState_RotateReverse
                move.w  #8,$4A(a5)
                bra.s   Enemy_CirclingOrbitState_UpdateLifetime
; ---------------------------------------------------------------------------
Enemy_CirclingOrbitState_RotateReverse:                 ; was: loc_2D5C8
                move.w  #$FFF8,$4A(a5)
Enemy_CirclingOrbitState_UpdateLifetime:                ; was: loc_2D5CE
                                        ; Enemy_CirclingOrbitState+3E   j
                subq.w  #1,$50(a5)
                beq.s   Enemy_CirclingOrbitState_BeginExit
                cmpi.w  #$140,$14(a5)
                bcc.s   Enemy_CirclingOrbitState_BeginExit
                rts
; ---------------------------------------------------------------------------
Enemy_CirclingOrbitState_BeginExit:                     ; was: loc_2D5DE
                                        ; Enemy_CirclingOrbitState+7C   j
                move.w  #$CF00,2(a5)
                andi.w  #$1F0,$4C(a5)
                addq.w  #2,4(a5)
                rts
; End of function Enemy_CirclingOrbitState
; Drives the orbit angle to $1C0 at a fixed rate, then hands over to the no-op state
Enemy_CirclingExitOrbitState:                           ; was: sub_2D5F0
                addi.w  #$10,$4C(a5)
                andi.w  #$1FF,$4C(a5)
                bsr.w   Enemy_UpdateFlySprite
                move.w  #$10,d2
                move.w  #$10,d3
                bsr.w   Enemy_UpdateCircularMotionAndFire
                cmpi.w  #$1C0,$4C(a5)
                bne.s   Enemy_CirclingExitOrbitState_Return
                addq.w  #2,4(a5)
Enemy_CirclingExitOrbitState_Return:                    ; was: locret_2D618
                rts
; End of function Enemy_CirclingExitOrbitState
Enemy_CirclingNoOpState:                                ; was: nullsub_62
                rts
; End of function Enemy_CirclingNoOpState

; Recycles the record as type $2A4 with its state, health and velocities cleared
Enemy_ResetCirclingState:                               ; was: sub_2D61C
                                        ; Enemy_CirclingController+14   j
                clr.w   4(a5)
                move.w  #$2A4,(a5)
                move.w  #$40,$48(a5)                    ; '@'
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                clr.l   $18(a5)
                clr.l   $1C(a5)
                rts
; End of function Enemy_ResetCirclingState
; Adds one directional projectile above the base difficulty, then fires the base pattern
Enemy_SpawnDifficultyProjectilePattern:                 ; was: sub_2D640
                tst.w   (DifficultyMode).w
                beq.s   Enemy_SpawnDifficultyProjectilePattern_Base
                jsr     (Projectile_FindFreeSlotForward).l
                bne.s   Enemy_SpawnDifficultyProjectilePattern_Base
                move.w  $10(a5),$10(a0)
                move.w  $14(a5),$14(a0)
                move.w  #$8004,d2
                jsr     (Projectile_InitializeAimedDelayedCollisionShot).l
; Fires the base four-projectile pattern on every difficulty
Enemy_SpawnDifficultyProjectilePattern_Base:            ; was: loc_2D664
                                        ; Enemy_SpawnDifficultyProjectilePattern+C   j
                jmp     Enemy_SpawnQuadProjectiles
; End of function Enemy_SpawnDifficultyProjectilePattern
Orphaned_EnemyDifficultyProjectileNoOp:                 ; was: nullsub_63
                rts
; End of function Orphaned_EnemyDifficultyProjectileNoOp
