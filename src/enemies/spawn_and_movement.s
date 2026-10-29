EnemySpawn_UpdateDirector:                              ; was: sub_2C33A
                tst.b   (GameplayControlFlags).w
                bmi.s   EnemySpawn_DirectorReturn
                movea.w #(PlayerObjectType-M68K_RAM),a5
                move.w  (EnemySpawnDirectorState).w,d0
                movea.w EnemySpawn_DirectorHandlers(pc,d0.w),a0
                adda.l  #EnemySpawn_ResetDirectorState,a0
                jmp     (a0)
; End of function EnemySpawn_UpdateDirector
; ---------------------------------------------------------------------------
EnemySpawn_DirectorHandlers:    dc.w    EnemySpawn_DirectorReturn-EnemySpawn_ResetDirectorState  ; was: off_2C354
                dc.w    EnemySpawn_StartDirectorTimer-EnemySpawn_ResetDirectorState
                dc.w    EnemySpawn_UpdateDirectorTimer-EnemySpawn_ResetDirectorState

; Resets the enemy-spawn director state
EnemySpawn_ResetDirectorState:                          ; was: sub_2C35A
                                        ; ROM:EnemySpawn_DirectorHandlers   o
                clr.w   (EnemySpawnDirectorState).w
EnemySpawn_DirectorReturn:                              ; was: locret_2C35E
                                        ; EnemySpawn_StartDirectorTimer+E   j
                rts
; End of function EnemySpawn_ResetDirectorState
; Starts a new randomized enemy-spawn delay
EnemySpawn_StartDirectorTimer:                          ; was: sub_2C360
                addq.w  #2,(EnemySpawnDirectorState).w
                move.w  #$A0,(EnemySpawnDelayTimer).w
; Counts down the spawn delay and creates an enemy when space permits
EnemySpawn_UpdateDirectorTimer:                         ; was: loc_2C36A
                subq.w  #1,(EnemySpawnDelayTimer).w
                bpl.w   EnemySpawn_DirectorReturn
                bsr.w   EnemySpawn_ResetDelay
                bsr.w   EnemySpawn_AllocateObjectSlot
                bne.w   EnemySpawn_DirectorReturn
                bsr.w   EnemySpawn_SelectSearchOriginY
                move.w  #$158,d1
                move.w  (RandomNumberState).w,(EnemySpawnSearchPass).w
                andi.w  #1,(EnemySpawnSearchPass).w
                bsr.w   EnemySpawn_FindTerrainPosition
                bne.w   EnemySpawn_DirectorReturn
                move.w  #$1C,(a0)
                move.b  #$B,$5F(a0)
                bra.w   EnemySpawn_InitializeObjectPosition
; End of function EnemySpawn_StartDirectorTimer
; No known static caller: clears the director timer and three unknown longs
Orphaned_EnemySpawnClearDirectorData:
                moveq   #0,d0                           ; was: sub_2C3A8
                move.l  d0,(EnemySpawnDelayTimer).w
                move.l  d0,(EnemySpawnClearedLongA).w
                move.l  d0,(EnemySpawnClearedLongB).w
                move.l  d0,(EnemySpawnClearedLongC).w
                rts
; End of function Orphaned_EnemySpawnClearDirectorData
; Chooses the next randomized spawn delay
EnemySpawn_ResetDelay:                                  ; was: sub_2C3BC
                move.w  (RandomNumberState).w,d0
                andi.w  #$7F,d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,(EnemySpawnDelayTimer).w
                rts
; End of function EnemySpawn_ResetDelay
; Selects the vertical origin for the terrain search
EnemySpawn_SelectSearchOriginY:                         ; was: sub_2C3CE
                move.w  #$1D0,d0
                tst.w   (DifficultyMode).w
                beq.s   EnemySpawn_SelectSearchOriginY_Return
                cmpi.w  #2,(CameraXDelta).w
                bpl.s   EnemySpawn_SelectSearchOriginY_Return
                cmpi.w  #$C0,(PlayerXPosition).w
                bmi.s   EnemySpawn_SelectSearchOriginY_Return
                move.b  (RandomNumberState).w,d1
                andi.w  #3,d1
                bne.s   EnemySpawn_SelectSearchOriginY_Return
                move.w  #$70,d0                         ; 'p'
EnemySpawn_SelectSearchOriginY_Return:                  ; was: locret_2C3F6
                                        ; EnemySpawn_SelectSearchOriginY+10   j
                rts
; End of function EnemySpawn_SelectSearchOriginY
; Allocates and clears one of the four enemy object slots
EnemySpawn_AllocateObjectSlot:                          ; was: sub_2C3F8
                movea.w #(TwentySecondEntityType-M68K_RAM),a0
                moveq   #3,d7
EnemySpawn_AllocateObjectSlot_Loop:                     ; was: loc_2C3FE
                tst.w   (a0)
                beq.s   EnemySpawn_AllocateObjectSlot_Initialize
                lea     $60(a0),a0
                dbf     d7,EnemySpawn_AllocateObjectSlot_Loop
                moveq   #1,d0
                rts
; ---------------------------------------------------------------------------
EnemySpawn_AllocateObjectSlot_Initialize:               ; was: loc_2C40E
                jsr     (Sys_Clear96ByteBlock).l
                suba.w  #$60,a0                         ; '`'
                moveq   #0,d0
                rts
; End of function EnemySpawn_AllocateObjectSlot
; Searches the terrain layout for a valid spawn position near the player
EnemySpawn_FindTerrainPosition:                         ; was: sub_2C41C
                lea     (M68K_RAM).l,a2
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFFF,d6
                move.w  d0,d2
                addi.w  #$10,d2
                bsr.w   EnemySpawn_CalculateLayoutOffset
                move.w  d2,d3
                move.w  d0,d2
                subi.w  #$10,d2
                bsr.w   EnemySpawn_CalculateLayoutOffset
                moveq   #$17,d7
EnemySpawn_FindTerrainPosition_Loop:                    ; was: loc_2C446
                move.w  (a2,d2.w),d4
                andi.w  #$7FF,d4
                move.b  (a1,d4.w),d4
                andi.b  #$FE,d4
                beq.s   EnemySpawn_FindTerrainPosition_CheckRun
                move.w  (a2,d3.w),d4
                andi.w  #$7FF,d4
                move.b  (a1,d4.w),d4
                andi.b  #$FE,d4
                beq.s   EnemySpawn_FindTerrainPosition_CheckRun
                moveq   #0,d6
                move.w  d1,d5
                bra.s   EnemySpawn_FindTerrainPosition_NextRow
; ---------------------------------------------------------------------------
EnemySpawn_FindTerrainPosition_CheckRun:                ; was: loc_2C470
                                        ; EnemySpawn_FindTerrainPosition+4C   j
                tst.w   d6
                bmi.s   EnemySpawn_FindTerrainPosition_NextRow
                addq.w  #1,d6
                cmpi.w  #7,d6
                bmi.s   EnemySpawn_FindTerrainPosition_NextRow
                subq.w  #1,(EnemySpawnSearchPass).w
                bmi.s   EnemySpawn_FindTerrainPosition_Found
                moveq   #$FFFFFFFF,d6
EnemySpawn_FindTerrainPosition_NextRow:                 ; was: loc_2C484
                                        ; EnemySpawn_FindTerrainPosition+56   j
                subq.w  #8,d1
                subi.w  #$80,d2
                andi.w  #$1FFE,d2
                subi.w  #$80,d3
                andi.w  #$1FFE,d3
                dbf     d7,EnemySpawn_FindTerrainPosition_Loop
                moveq   #1,d7
                rts
; ---------------------------------------------------------------------------
EnemySpawn_FindTerrainPosition_Found:                   ; was: loc_2C49E
                moveq   #0,d7
                rts
; End of function EnemySpawn_FindTerrainPosition
; Converts a player-relative coordinate into a terrain-layout offset
EnemySpawn_CalculateLayoutOffset:                       ; was: sub_2C4A2
                                        ; EnemySpawn_FindTerrainPosition+24   p
                sub.w   d7,d2
                add.w   (PrimaryCameraXPosition).w,d2
                asr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                move.w  d1,d4
                sub.w   d7,d4
                sub.w   (PrimaryCameraYPosition).w,d4
                asl.w   #4,d4
                andi.w  #$1F80,d4
                add.w   d4,d2
                rts
; End of function EnemySpawn_CalculateLayoutOffset
; Stores the chosen enemy position and marks left-side spawns
EnemySpawn_InitializeObjectPosition:                    ; was: sub_2C4C0
                move.w  d0,$10(a0)
                subi.w  #$20,d5                         ; ' '
                move.w  d5,$14(a0)
                cmpi.w  #$120,$10(a0)
                bpl.s   EnemySpawn_InitializeObjectPosition_Return
                bset    #7,$5F(a0)
EnemySpawn_InitializeObjectPosition_Return:             ; was: locret_2C4DA
                rts
; End of function EnemySpawn_InitializeObjectPosition
; Sets up shared sprite properties for the spawned enemy family
Enemy_SetupBehaviorSprite:                              ; was: sub_2C4DC
                                        ; Enemy_BeginDestructionDelay+6   p
                move.w  #$EF00,2(a5)
                move.w  (SpawnedEnemyTileAttr).w,d1
                or.w    (GlobalSpritePriorityBit).w,d1
                move.w  d1,$E(a5)
                btst    #7,$5F(a5)
                beq.s   Enemy_SetupBehaviorSprite_ApplyAttributes
                bclr    #3,$E(a5)
; Applies shared sprite attributes and variant parameters
Enemy_SetupBehaviorSprite_ApplyAttributes:              ; was: loc_2C4FC
                move.b  #$48,$20(a5)                    ; 'H'
                move.b  #$C0,$21(a5)
                move.l  #$F010F808,$2C(a5)
                move.l  #$E420E818,$28(a5)
                lea     Enemy_BehaviorSpriteParameters(pc),a0
                nop
                moveq   #0,d1
                move.b  (a0,d0.w),$27(a5)
                move.b  1(a0,d0.w),$25(a5)
                move.b  2(a0,d0.w),d1
                asl.w   #4,d1
                move.w  d1,$5A(a5)
                rts
; End of function Enemy_SetupBehaviorSprite
; ---------------------------------------------------------------------------
Enemy_BehaviorSpriteParameters: dc.b    $18, 4, $11, 0  ; was: byte_2C538

; Updates animation pointer based on current state index
Enemy_UpdateBehaviorAnimation:                          ; was: sub_2C53C
                                        ; Enemy_DestructionDelayController+2   j
                move.w  $5C(a5),d0
                beq.s   Enemy_UpdateBehaviorAnimation_Return
                subq.w  #4,d0
                move.l  Enemy_BehaviorSpriteAnimationPointers(pc,d0.w),8(a5)
                clr.w   $C(a5)
Enemy_UpdateBehaviorAnimation_Return:                   ; was: locret_2C54E
                rts
; End of function Enemy_UpdateBehaviorAnimation
; ---------------------------------------------------------------------------
Enemy_BehaviorSpriteAnimationPointers:  dc.l    Enemy_BehaviorWaitSpriteAnimation  ; was: off_2C550
                dc.l    Enemy_BehaviorMovementSpriteAnimation
                dc.l    Enemy_BehaviorGroundedSpriteAnimation
                dc.l    Enemy_BehaviorAttackCooldownSpriteAnimation
                dc.l    Enemy_BehaviorDefeatSpriteAnimation

; Applies horizontal acceleration with speed limits
Enemy_AccelerateHorizontal:                             ; was: sub_2C564
                btst    #3,$E(a5)
                bne.s   Enemy_AccelerateHorizontal_LeftFacing
                move.l  $18(a5),d0
                bmi.s   Enemy_AccelerateHorizontal_Right
                cmpi.l  #$20000,d0
                bmi.s   Enemy_AccelerateHorizontal_Right
                move.l  #$20000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_AccelerateHorizontal_Right:                       ; was: loc_2C584
                                        ; Enemy_AccelerateHorizontal+14   j
                addi.l  #$2000,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_AccelerateHorizontal_LeftFacing:                  ; was: loc_2C590
                move.l  $18(a5),d0
                bpl.s   Enemy_AccelerateHorizontal_Left
                cmpi.l  #$FFFE0000,d0
                bpl.s   Enemy_AccelerateHorizontal_Left
                move.l  #$FFFE0000,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_AccelerateHorizontal_Left:                        ; was: loc_2C5A8
                                        ; Enemy_AccelerateHorizontal+38   j
                subi.l  #$2000,d0
                move.l  d0,$18(a5)
                rts
; End of function Enemy_AccelerateHorizontal
; Applies horizontal deceleration and stops at threshold
Enemy_DecelerateHorizontal:                             ; was: sub_2C5B4
                                        ; Enemy_MainStateMachine+17E   j
                move.l  $18(a5),d0
                beq.s   Enemy_DecelerateHorizontal_Return
                bmi.s   Enemy_DecelerateHorizontal_Negative
                cmpi.l  #$3800,d0
                bmi.s   Enemy_DecelerateHorizontal_Stop
                subi.l  #$3800,d0
                move.l  d0,$18(a5)
Enemy_DecelerateHorizontal_Return:                      ; was: locret_2C5CE
                rts
; ---------------------------------------------------------------------------
Enemy_DecelerateHorizontal_Negative:                    ; was: loc_2C5D0
                cmpi.l  #$FFFFC800,d0
                bpl.s   Enemy_DecelerateHorizontal_Stop
                addi.l  #$3800,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_DecelerateHorizontal_Stop:                        ; was: loc_2C5E4
                                        ; Enemy_DecelerateHorizontal+22   j
                clr.l   $18(a5)
                rts
; End of function Enemy_DecelerateHorizontal
; Initializes homing projectile that tracks player with angle calculation
Enemy_SpawnTrackedProjectile:                           ; was: sub_2C5EA
                jsr     (Projectile_FindFreeSlotForward).l
                beq.s   Enemy_SpawnTrackedProjectile_Initialize
                rts
; ---------------------------------------------------------------------------
Enemy_SpawnTrackedProjectile_Initialize:                ; was: loc_2C5F4
                moveq   #$FFFFFFE8,d0
                moveq   #$FFFFFFFA,d1
                move.w  (GlobalSpritePriorityBit).w,d2
                move.b  $20(a5),d2
                subq.w  #4,d2
                move.w  #$100,d6
                btst    #3,$E(a5)
                bne.s   Enemy_SpawnTrackedProjectile_SetParameters
                moveq   #0,d6
                neg.w   d0
; Completes tracked-projectile parameters and difficulty selection
Enemy_SpawnTrackedProjectile_SetParameters:             ; was: loc_2C612
                move.w  (DifficultyMode).w,d7
                asr.w   #1,d7
                addi.w  #9,d7
                jmp     Projectile_InitializeTwoSpeedShot
; End of function Enemy_SpawnTrackedProjectile
; Converts a defeated enemy into the shared falling defeat object
Enemy_ConvertToDefeatProjectile:                        ; was: sub_2C622
                                        ; Enemy_BehaviorController+12   j
                move.w  #$1D4,(a5)
                clr.w   $24(a5)
                clr.b   $21(a5)
                clr.b   $22(a5)
                move.l  #Enemy_BehaviorDefeatSpriteAnimation,8(a5)
                clr.w   $C(a5)
                move.w  #$10,$48(a5)
                clr.w   $4A(a5)
                move.l  #$FFFB2000,$1C(a5)
                move.l  #$FFFEA000,$18(a5)
                btst    #3,$E(a5)
                beq.s   Enemy_ConvertToDefeatProjectile_Return
                neg.l   $18(a5)
Enemy_ConvertToDefeatProjectile_Return:                 ; was: locret_2C664
                rts
; End of function Enemy_ConvertToDefeatProjectile
; Updates a falling defeat object, then removes it or drops a pickup
Enemy_UpdateDefeatProjectile:                           ; was: sub_2C666
                addi.l  #$5C00,$1C(a5)
                subq.w  #1,$48(a5)
                bpl.s   Enemy_UpdateDefeatProjectile_ApplyBlink
                jsr     (Effect_SpawnExplosionA).l
                tst.w   $4A(a5)
                beq.w   Enemy_UpdateDefeatProjectile_DropPickup
                bset    #4,2(a5)
                rts
; ---------------------------------------------------------------------------
Enemy_UpdateDefeatProjectile_DropPickup:                ; was: loc_2C68A
                moveq   #7,d0
                jmp     Pickup_SpawnRandomFromCurrentObject
; ---------------------------------------------------------------------------
; Applies the falling object's blink phase
Enemy_UpdateDefeatProjectile_ApplyBlink:                ; was: loc_2C692
                bset    #7,2(a5)
                btst    #0,$49(a5)
                bne.s   Enemy_UpdateDefeatProjectile_Return
                bclr    #7,2(a5)
Enemy_UpdateDefeatProjectile_Return:                    ; was: locret_2C6A6
                rts
; End of function Enemy_UpdateDefeatProjectile
; Main AI controller for enemy behavior and state management
