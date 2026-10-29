Collision_PlayerWeaponVsEnemy:                          ; was: sub_14190
                movea.w #(PlayerWeaponList-M68K_RAM),a5
                move.w  (WeaponListCountMinus1).w,d7
                bmi.w   Collision_PlayerWeaponVsEnemy_Return
                moveq   #4,d5
Collision_PlayerWeaponVsEnemy_WeaponLoop:               ; was: loc_1419E
                movea.w (a5)+,a3
                moveq   #$FFFFFFF8,d0
                add.w   $10(a3),d0
                moveq   #8,d1
                add.w   $10(a3),d1
                moveq   #$FFFFFFF8,d2
                add.w   $14(a3),d2
                moveq   #8,d3
                add.w   $14(a3),d3
                movea.w #(CollisionTargetList-M68K_RAM),a4
                move.w  (TargetListCountMinus1).w,d6
                bmi.w   Collision_PlayerWeaponVsEnemy_Return
Collision_PlayerWeaponVsEnemy_TargetLoop:               ; was: loc_141C4
                movea.w (a4)+,a2
                cmp.w   $34(a2),d1
                bmi.s   Collision_PlayerWeaponVsEnemy_NextTarget
                cmp.w   $36(a2),d0
                bpl.s   Collision_PlayerWeaponVsEnemy_NextTarget
                cmp.w   $32(a2),d2
                bpl.s   Collision_PlayerWeaponVsEnemy_NextTarget
                cmp.w   $30(a2),d3
                bmi.s   Collision_PlayerWeaponVsEnemy_NextTarget
                btst    d5,$21(a2)
                bne.s   Collision_PlayerWeaponVsEnemy_ResolveFlaggedTarget
                beq.w   Collision_PlayerWeaponVsEnemy_ApplyStandardDamage
Collision_PlayerWeaponVsEnemy_NextTarget:               ; was: loc_141E8
                                        ; Collision_PlayerWeaponVsEnemy+40   j
                dbf     d6,Collision_PlayerWeaponVsEnemy_TargetLoop
                dbf     d7,Collision_PlayerWeaponVsEnemy_WeaponLoop
Collision_PlayerWeaponVsEnemy_Return:                   ; was: locret_141F0
                                        ; Collision_PlayerWeaponVsEnemy+30   j
                rts
; ---------------------------------------------------------------------------
Collision_PlayerWeaponVsEnemy_ResolveFlaggedTarget:     ; was: loc_141F2
                btst    #2,(BossColorEffectFlags).w
                bne.s   Collision_PlayerWeaponVsEnemy_ApplyFlaggedDamage
                tst.w   (BossHealth).w
                beq.w   Collision_PlayerWeaponVsEnemy_NextTarget
Collision_PlayerWeaponVsEnemy_ApplyFlaggedDamage:       ; was: loc_14202
                bset    #7,$22(a3)
                btst    #1,(BossColorEffectFlags).w
                bne.s   Collision_PlayerWeaponVsEnemy_NextTarget
                btst    #4,$23(a2)
                bne.s   Collision_PlayerWeaponVsEnemy_NextTarget
                movem.l d0,-(sp)
                move.b  #$AE,d0
                jsr     (Sound_QueueSFXRequest).l
                movem.l (sp)+,d0
                ori.b   #$40,(CombatHitFlags).w         ; '@'
                bset    #0,(BossColorEffectFlags).w
                move.b  $21(a3),d4
                or.b    d4,$22(a2)
                move.w  $26(a3),d4
                move.w  $24(a2),(CombatPercentIndex).w
                move.w  #$20,(CombatPercentTimer).w     ; ' '
                mulu.w  $24(a2),d4
                sub.w   d4,(BossHealth).w
                bpl.s   Collision_PlayerWeaponVsEnemy_NextTarget
                clr.w   (BossHealth).w
                clr.w   (BossMaxHealth).w
                clr.b   (BossColorEffectFlags).w
                clr.w   (BossCombatCounter).w
                clr.w   (BossCombatCounterMax).w
                clr.b   (BossCounterMaxFlag).w
                bsr.w   Results_IncrementDestroyedEnemyCountBCD
                bra.w   Collision_PlayerWeaponVsEnemy_NextTarget
; ---------------------------------------------------------------------------
Collision_PlayerWeaponVsEnemy_ApplyStandardDamage:      ; was: loc_14278
                tst.w   $24(a2)
                bmi.w   Collision_PlayerWeaponVsEnemy_NextTarget
                bset    #7,$22(a3)
                btst    #4,$23(a2)
                bne.w   Collision_PlayerWeaponVsEnemy_NextTarget
                ori.b   #$40,$22(a2)                    ; '@'
                movem.l d0,-(sp)
                move.b  #$AE,d0
                jsr     (Sound_QueueSFXRequest).l
                movem.l (sp)+,d0
                move.w  $26(a3),d4
                sub.w   d4,$24(a2)
                bpl.w   Collision_PlayerWeaponVsEnemy_NextTarget
                btst    #6,$23(a2)
                beq.s   Collision_PlayerWeaponVsEnemy_FinishStandardDefeat
                subq.w  #1,(SpecialTargetCount).w
                bpl.s   Collision_PlayerWeaponVsEnemy_FinishStandardDefeat
                clr.w   (SpecialTargetCount).w
Collision_PlayerWeaponVsEnemy_FinishStandardDefeat:     ; was: loc_142C6
                                        ; Collision_PlayerWeaponVsEnemy+130   j
                btst    #7,$23(a2)
                bne.w   Collision_PlayerWeaponVsEnemy_NextTarget
                bsr.w   Results_IncrementDestroyedEnemyCountBCD
                bra.w   Collision_PlayerWeaponVsEnemy_NextTarget
; End of function Collision_PlayerWeaponVsEnemy
; Checks the player against objects registered as moving platforms
Collision_CheckPlayerPlatforms:                         ; was: sub_142D8
                                        ; Physics_DescendingTerrainCheckWrapper+A   p
                movea.w #(MovingPlatformList-M68K_RAM),a4
                move.w  (PlatformListCountMinus1).w,d7
                bmi.s   Collision_CheckPlayerPlatforms_Return
; Processes one entry in the moving-platform collision list
Collision_PlayerPlatformLoop:                           ; was: loc_142E2
                movea.w (a4)+,a2
                bsr.s   Collision_DispatchPlatformContact
                dbf     d7,Collision_PlayerPlatformLoop
Collision_CheckPlayerPlatforms_Return:                  ; was: locret_142EA
                rts
; End of function Collision_CheckPlayerPlatforms
; Dispatches the platform contact mode stored in the object
Collision_DispatchPlatformContact:                      ; was: sub_142EC
                move.w  $46(a2),d0
                movea.w Collision_PlatformHandlerOffsets(pc,d0.w),a0
                adda.l  #Collision_PlayerLandOnPlatform,a0
                jmp     (a0)
; End of function Collision_DispatchPlatformContact
; ---------------------------------------------------------------------------
Collision_PlatformHandlerOffsets:   dc.w    Collision_CheckPlayerPlatforms_Return-Collision_PlayerLandOnPlatform  ; was: off_142FC
                dc.w    Collision_PlayerLandOnPlatform-Collision_PlayerLandOnPlatform
                dc.w    Collision_PlayerHitPlatformUnderside-Collision_PlayerLandOnPlatform
                dc.w    Collision_PlayerClampToPlatformTop-Collision_PlayerLandOnPlatform

; Lands the player on top of a moving platform
Collision_PlayerLandOnPlatform:                         ; was: sub_14304
                                        ; ROM:Collision_PlatformHandlerOffsets   o
                tst.w   $1C(a5)
                bmi.w   Collision_PlayerLandOnPlatform_Return
                move.w  $28(a2),d0
                add.w   $48(a2),d0
                move.w  $10(a5),d1
                addq.w  #8,d1
                cmp.w   d1,d0
                bpl.w   Collision_PlayerLandOnPlatform_Return
                move.w  $2A(a2),d0
                add.w   $48(a2),d0
                move.w  $10(a5),d1
                subq.w  #8,d1
                cmp.w   d1,d0
                bmi.s   Collision_PlayerLandOnPlatform_Return
                move.w  $4A(a2),d0
                subq.w  #6,d0
                move.w  $14(a5),d1
                addi.w  #$26,d1                         ; '&'
                cmp.w   d1,d0
                bpl.s   Collision_PlayerLandOnPlatform_Return
                move.w  $4A(a2),d0
                addq.w  #6,d0
                move.w  $14(a5),d1
                addi.w  #-$1A,d1
                cmp.w   d1,d0
                bmi.s   Collision_PlayerLandOnPlatform_Return
                clr.l   $1C(a5)
                bset    #0,6(a5)
                bset    #0,6(a2)
                move.w  $4C(a2),d5
                sub.w   $48(a2),d5
                neg.w   d5
                add.w   (CameraXDelta).w,d5
                add.w   d5,$10(a5)
                move.w  $4A(a2),d0
                subi.w  #$20,d0                         ; ' '
                move.w  d0,$14(a5)
Collision_PlayerLandOnPlatform_Return:                  ; was: locret_14384
                                        ; Collision_PlayerLandOnPlatform+18   j
                rts
; End of function Collision_PlayerLandOnPlatform
; Clamps the player to a platform top for either vertical direction
Collision_PlayerClampToPlatformTop:                     ; was: sub_14386
                move.w  $28(a2),d0
                add.w   $48(a2),d0
                move.w  $10(a5),d1
                addq.w  #8,d1
                cmp.w   d1,d0
                bpl.w   Collision_PlayerClampToPlatformTop_Return
                move.w  $2A(a2),d0
                add.w   $48(a2),d0
                move.w  $10(a5),d1
                subq.w  #8,d1
                cmp.w   d1,d0
                bmi.s   Collision_PlayerClampToPlatformTop_Return
                move.w  $4A(a2),d0
                subq.w  #6,d0
                move.w  $14(a5),d1
                addi.w  #$26,d1                         ; '&'
                cmp.w   d1,d0
                bpl.s   Collision_PlayerClampToPlatformTop_Return
                move.w  $4A(a2),d0
                addq.w  #6,d0
                move.w  $14(a5),d1
                addi.w  #-$1A,d1
                cmp.w   d1,d0
                bmi.s   Collision_PlayerClampToPlatformTop_Return
                tst.w   $1C(a5)
                bpl.s   Collision_PlayerClampToPlatformTop_Attach
                move.w  $4A(a2),d0
                subi.w  #$20,d0                         ; ' '
                cmp.w   $14(a5),d0
                bpl.s   Collision_PlayerClampToPlatformTop_Return
                move.w  d0,$14(a5)
                rts
; ---------------------------------------------------------------------------
Collision_PlayerClampToPlatformTop_Attach:              ; was: loc_143EA
                move.w  $4A(a2),d0
                subi.w  #$20,d0                         ; ' '
                move.w  d0,$14(a5)
                clr.l   $1C(a5)
                bset    #0,6(a5)
                bset    #0,6(a2)
                move.w  $4C(a2),d5
                sub.w   $48(a2),d5
                neg.w   d5
                add.w   d5,$10(a5)
Collision_PlayerClampToPlatformTop_Return:              ; was: locret_14414
                                        ; Collision_PlayerClampToPlatformTop+24   j
                rts
; End of function Collision_PlayerClampToPlatformTop
; Resolves contact with the underside of a moving platform
Collision_PlayerHitPlatformUnderside:                   ; was: sub_14416
                clr.w   6(a2)
                tst.l   $1C(a5)
                beq.s   Collision_PlayerHitPlatformUnderside_CheckBounds
                bpl.w   Collision_PlayerHitPlatformUnderside_Return
Collision_PlayerHitPlatformUnderside_CheckBounds:       ; was: loc_14424
                move.w  $28(a2),d0
                add.w   $48(a2),d0
                move.w  $10(a5),d1
                addq.w  #8,d1
                cmp.w   d1,d0
                bpl.w   Collision_PlayerHitPlatformUnderside_Return
                move.w  $2A(a2),d0
                add.w   $48(a2),d0
                move.w  $10(a5),d1
                subq.w  #8,d1
                cmp.w   d1,d0
                bmi.s   Collision_PlayerHitPlatformUnderside_Return
                move.w  $4A(a2),d0
                subq.w  #6,d0
                move.w  $14(a5),d1
                addi.w  #$26,d1                         ; '&'
                cmp.w   d1,d0
                bpl.s   Collision_PlayerHitPlatformUnderside_Return
                btst    #4,$E(a5)
                bne.s   Collision_PlayerHitPlatformUnderside_Attach
                move.w  $4A(a2),d0
                addq.w  #6,d0
                move.w  $14(a5),d1
                addi.w  #-$1A,d1
                cmp.w   d1,d0
                bmi.s   Collision_PlayerHitPlatformUnderside_Return
Collision_PlayerHitPlatformUnderside_Attach:            ; was: loc_14476
                clr.l   $1C(a5)
                bset    #1,6(a5)
                bset    #1,6(a2)
                move.w  $4C(a2),d5
                sub.w   $48(a2),d5
                neg.w   d5
                add.w   (CameraXDelta).w,d5
                add.w   d5,$10(a5)
                move.w  $4A(a2),d0
                addi.w  #$20,d0                         ; ' '
                move.w  d0,$14(a5)
Collision_PlayerHitPlatformUnderside_Return:            ; was: locret_144A4
                                        ; Collision_PlayerHitPlatformUnderside+1E   j
                rts
; End of function Collision_PlayerHitPlatformUnderside
; Increments the destroyed-enemy BCD counter, saturating at 9999
Results_IncrementDestroyedEnemyCountBCD:                ; was: sub_144A6
                                        ; Collision_CheckWeaponProjectilesAgainstEnemies+196   p
                movem.l d1/a3-a4,-(sp)
                movea.w #(DestroyedEnemyCountBCD+2-M68K_RAM),a3
                movea.w #(BCDIncrementEnd-M68K_RAM),a4
                move.w  #1,(BCDIncrementScratch).w
                sub.w   d1,d1
                abcd    -(a4),-(a3)
                abcd    -(a4),-(a3)
                bcc.s   Results_IncrementDestroyedEnemyCountBCD_Return
                move.w  #$9999,(DestroyedEnemyCountBCD).w
Results_IncrementDestroyedEnemyCountBCD_Return:         ; was: loc_144C6
                movem.l (sp)+,d1/a3-a4
                rts
; End of function Results_IncrementDestroyedEnemyCountBCD
; Gets entity position coordinates for collision detection
Collision_GetEntityPosition:                            ; was: sub_144CC
                                        ; Projectile_UpdateGravityBounceType84:Projectile_UpdateGravityBounceType84_CheckTerrain   p
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                bra.s   Collision_CheckTerrainTile
; End of function Collision_GetEntityPosition
; Unreachable: would return zero tile data above screen Y $A0, else probe terrain
Orphaned_CollisionCheckScreenBounds:
                add.w   $10(a5),d0                      ; was: sub_144D6
                add.w   $14(a5),d1
                cmpi.w  #$A0,d1
                bpl.s   Collision_CheckTerrainTile
                moveq   #0,d2
                moveq   #0,d3
                rts
; End of function Orphaned_CollisionCheckScreenBounds
; Adds offset to entity position for collision coordinate calculation
Physics_AddEntityOffset:                                ; was: sub_144EA
                                        ; UI_DebugSpritePositionEditor+68   p
                add.w   $10(a5),d0
                add.w   $14(a5),d1
; End of function Physics_AddEntityOffset
; Checks collision with terrain by reading tilemap and height data
Collision_CheckTerrainTile:                             ; was: sub_144F2
                                        ; Orphaned_CollisionCheckScreenBounds+C   j
                movea.l #M68K_RAM,a0
                movea.l #TerrainCollisionBuffer,a1
                move.w  d0,d2
                subi.w  #$80,d2
                add.w   (PrimaryCameraXPosition).w,d2
                asr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                move.w  d1,d3
                subi.w  #$80,d3
                sub.w   (PrimaryCameraYPosition).w,d3
                asl.w   #4,d3
                andi.w  #$1F80,d3
                add.w   d3,d2
                move.w  (a0,d2.w),d2
                move.w  d2,d3
                andi.w  #$7FF,d2
                move.b  (a1,d2.w),d2
                andi.w  #$FE,d2
                rts
; End of function Collision_CheckTerrainTile
; Aligns entity Y position to terrain surface clearing velocity
Physics_AlignToTerrain:                                 ; was: sub_14534
                                        ; Enemy_EyePodAirborneState+52   p
                move.w  d1,d4
                sub.w   (PrimaryCameraYPosition).w,d4
                andi.w  #7,d4
                sub.w   d4,$14(a5)
                clr.l   $1C(a5)
                rts
; End of function Physics_AlignToTerrain
; Aligns entity to terrain surface from above
Physics_AlignToTerrainTop:                              ; was: sub_14548
                move.w  d1,d4
                sub.w   (PrimaryCameraYPosition).w,d4
                neg.w   d4
                subq.w  #1,d4
                andi.w  #7,d4
                add.w   d4,$14(a5)
                clr.l   $1C(a5)
                rts
; End of function Physics_AlignToTerrainTop
; Unreachable: would snap the entity to the eight-pixel wall grid by travel direction
Orphaned_PhysicsAlignToWallSurface:
                tst.w   $18(a5)                         ; was: sub_14560
                bmi.s   Orphaned_PhysicsAlignToWallSurfaceAdjustOpposite
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                andi.w  #7,d4
                sub.w   d4,$10(a5)
                rts
; ---------------------------------------------------------------------------
Orphaned_PhysicsAlignToWallSurfaceAdjustOpposite:       ; was: loc_14576
                move.w  d0,d4
                add.w   (PrimaryCameraXPosition).w,d4
                neg.w   d4
                subq.w  #1,d4
                andi.w  #7,d4
                add.w   d4,$10(a5)
                rts
; End of function Orphaned_PhysicsAlignToWallSurface
; Initializes collision buffer pointers
Collision_InitBufferPointers:                           ; was: sub_1458A
                                        ; Enemy_UpdateBouncingDebrisSpawner+22   p
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
; End of function Collision_InitBufferPointers
; Gets terrain tile data at specified position with screen offset
Physics_GetTerrainTileData:                             ; was: sub_1459A
                                        ; Physics_EntityWallCheck+2C   p
                add.w   $10(a5),d0
                add.w   $14(a5),d1
                cmpi.w  #$A0,d1
                bpl.s   Physics_GetTerrainTileData_ReadTile
                moveq   #0,d2
                moveq   #0,d3
                rts
; ---------------------------------------------------------------------------
Physics_GetTerrainTileData_ReadTile:                    ; was: loc_145AE
                move.w  d0,d2
                sub.w   d7,d2
                add.w   (PrimaryCameraXPosition).w,d2
                asr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                move.w  d1,d3
                sub.w   d7,d3
                sub.w   (PrimaryCameraYPosition).w,d3
                asl.w   #4,d3
                andi.w  #$1F80,d3
                add.w   d3,d2
                move.w  (a0,d2.w),d2
                move.w  d2,d3
                andi.w  #$7FF,d2
                move.b  (a1,d2.w),d2
                andi.w  #$FE,d2
                beq.s   Physics_GetTerrainTileData_Return
                btst    #$B,d3
                beq.s   Physics_GetTerrainTileData_CheckSecondTileFlag
                addq.w  #8,d2
Physics_GetTerrainTileData_CheckSecondTileFlag:         ; was: loc_145E8
                btst    #$C,d3
                beq.s   Physics_GetTerrainTileData_Return
                addi.w  #$40,d2                         ; '@'
Physics_GetTerrainTileData_Return:                      ; was: locret_145F2
                                        ; Physics_GetTerrainTileData+52   j
                rts
; End of function Physics_GetTerrainTileData
; Checks projectile collision with terrain tile map
Collision_CheckProjectileTile:                          ; was: sub_145F4
                                        ; sub_2B3E4:Projectile_CheckType254TwoSpeedShotTerrain   p
                move.w  $10(a5),d0
                move.w  $14(a5),d1
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  d0,d2
                subi.w  #$80,d2
                add.w   (PrimaryCameraXPosition).w,d2
                asr.w   #2,d2
                andi.w  #$7E,d2                         ; '~'
                move.w  d1,d3
                subi.w  #$80,d3
                sub.w   (PrimaryCameraYPosition).w,d3
                asl.w   #4,d3
                andi.w  #$1F80,d3
                add.w   d3,d2
                move.w  (a0,d2.w),d2
                move.w  d2,d3
                andi.w  #$7FF,d2
                move.b  (a1,d2.w),d2
                andi.w  #$FE,d2
                beq.s   Collision_CheckProjectileTile_Return
                cmpi.w  #$80,d2
                bpl.s   Collision_CheckProjectileTile_Return
                moveq   #0,d2
Collision_CheckProjectileTile_Return:                   ; was: locret_14646
                                        ; Collision_CheckProjectileTile+4E   j
                rts
; End of function Collision_CheckProjectileTile
; Entity wall collision detection checking left and right sides
Physics_EntityWallCheck:                                ; was: sub_14648
                                        ; sub_2CC34:loc_2CC54   p
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFF8,d0
                moveq   #0,d1
                bsr.w   Physics_GetTerrainTileData
                cmpi.w  #$80,d2
                bmi.s   Physics_EntityWallCheck_CheckRight
                bset    #2,7(a5)
                bsr.w   Physics_ResolveLeftWallCollision
Physics_EntityWallCheck_CheckRight:                     ; was: loc_14670
                moveq   #8,d0
                moveq   #0,d1
                bsr.w   Physics_GetTerrainTileData
                cmpi.w  #$80,d2
                bmi.s   Physics_EntityWallCheck_Return
                bset    #3,7(a5)
                bsr.w   Physics_ResolveRightWallCollision
Physics_EntityWallCheck_Return:                         ; was: locret_14688
                rts
; End of function Physics_EntityWallCheck
; Extended entity wall check with velocity-dependent vertical probe offsets
Physics_EntityExtendedWallCheck:                        ; was: sub_1468A
                                        ; sub_2C71E:loc_2C850   p
                moveq   #$18,d6
                tst.w   $1C(a5)
                bmi.s   Physics_EntityExtendedWallCheck_Begin
                moveq   #$FFFFFFE8,d6
Physics_EntityExtendedWallCheck_Begin:                  ; was: loc_14694
                                        ; Physics_FacingExtendedWallCheckWrapper+12   j
                lea     (M68K_RAM).l,a0
                lea     (TerrainCollisionBuffer).l,a1
                move.w  #$80,d7
                moveq   #$FFFFFFF8,d0
                moveq   #0,d1
                bsr.w   Physics_GetTerrainTileData
                cmpi.w  #$80,d2
                bmi.s   Physics_EntityExtendedWallCheck_CheckOffsetLeft
                bset    #2,7(a5)
                bsr.w   Physics_ResolveLeftWallCollision
                bra.s   Physics_EntityExtendedWallCheck_CheckRight
; ---------------------------------------------------------------------------
Physics_EntityExtendedWallCheck_CheckOffsetLeft:        ; was: loc_146BE
                moveq   #$FFFFFFF8,d0
                move.w  d6,d1
                bsr.w   Physics_GetTerrainTileData
                cmpi.w  #$80,d2
                bmi.s   Physics_EntityExtendedWallCheck_CheckRight
                bsr.w   Physics_ResolveLeftWallCollision
Physics_EntityExtendedWallCheck_CheckRight:             ; was: loc_146D0
                                        ; Physics_EntityExtendedWallCheck+40   j
                moveq   #8,d0
                moveq   #0,d1
                bsr.w   Physics_GetTerrainTileData
                cmpi.w  #$80,d2
                bmi.s   Physics_EntityExtendedWallCheck_CheckOffsetRight
                bset    #3,7(a5)
                bra.w   Physics_ResolveRightWallCollision
; ---------------------------------------------------------------------------
Physics_EntityExtendedWallCheck_CheckOffsetRight:       ; was: loc_146E8
                moveq   #8,d0
                move.w  d6,d1
                bsr.w   Physics_GetTerrainTileData
                cmpi.w  #$80,d2
                bmi.s   Physics_EntityExtendedWallCheck_Return
                bra.w   Physics_ResolveRightWallCollision
; ---------------------------------------------------------------------------
Physics_EntityExtendedWallCheck_Return:                 ; was: locret_146FA
                rts
; End of function Physics_EntityExtendedWallCheck
