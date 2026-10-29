; Runs the simple wall check unless terrain collisions are disabled
Physics_WallCheckWrapper:                               ; was: sub_16CC8
                                        ; sub_152CA   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jmp     Physics_EntityWallCheck
; End of function Physics_WallCheckWrapper
; Runs the extended wall check unless terrain collisions are disabled
Physics_ExtendedWallCheckWrapper:                       ; was: sub_16CD8
                                        ; sub_15B8C   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jmp     Physics_EntityExtendedWallCheck
; End of function Physics_ExtendedWallCheckWrapper
; Checks moving platforms, then probes the entity's lower terrain boundary
Physics_LowerTerrainCheckWrapper:                       ; was: sub_16CE8
                                        ; Player_GroundCounterForceState+6   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jsr     (Collision_CheckPlayerPlatforms).l
                jmp     Physics_CheckLowerTerrain
; End of function Physics_LowerTerrainCheckWrapper
; Checks moving platforms, then resolves lower terrain while descending
Physics_DescendingTerrainCheckWrapper:                  ; was: sub_16CFE
                                        ; Player_DashKickState+E   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jsr     (Collision_CheckPlayerPlatforms).l
                jmp     Physics_CheckLowerTerrainWhenDescending
; End of function Physics_DescendingTerrainCheckWrapper
; Checks moving platforms, then probes the entity's upper terrain boundary
Physics_UpperTerrainCheckWrapper:                       ; was: sub_16D14
                                        ; Player_CeilingCounterForceState+6   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jsr     (Collision_CheckPlayerPlatforms).l
                jmp     Physics_CheckUpperTerrain
; End of function Physics_UpperTerrainCheckWrapper
; Checks moving platforms, then resolves upper terrain while rising
Physics_RisingTerrainCheckWrapper:                      ; was: sub_16D2A
                                        ; Player_HandleFallingState+5A   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jsr     (Collision_CheckPlayerPlatforms).l
                jmp     Physics_CheckUpperTerrainWhenRising
; End of function Physics_RisingTerrainCheckWrapper
; Selects the lower- or upper-boundary terrain probe from entity facing
Physics_FacingTerrainCheckWrapper:                      ; was: sub_16D40
                                        ; sub_159E0:Player_DashAttackState_Finish   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                jsr     (Collision_CheckPlayerPlatforms).l
                btst    #4,$E(a5)
                beq.w   Physics_CheckLowerTerrain
                jmp     Physics_CheckUpperTerrain
; End of function Physics_FacingTerrainCheckWrapper
; Runs the extended wall check with a facing-selected vertical probe offset
Physics_FacingExtendedWallCheckWrapper:                 ; was: sub_16D60
                                        ; Player_ApplyHorizontalMovement+4   p
                btst    #5,(PlayerRestrictionFlags).w
                bne.w   Physics_TerrainCheckWrappers_Return
                moveq   #$FFFFFFE8,d6
                btst    #4,$E(a5)
                beq.w   Physics_EntityExtendedWallCheck_Begin
                moveq   #$18,d6
                jmp     Physics_EntityExtendedWallCheck_Begin
; ---------------------------------------------------------------------------
Physics_TerrainCheckWrappers_Return:                    ; was: locret_16D7E
                                        ; Physics_ExtendedWallCheckWrapper+6   j
                rts
; End of function Physics_FacingExtendedWallCheckWrapper
; Processes D-pad input for character facing direction
Input_ProcessDirectionInput:                            ; was: sub_16D80
                                        ; Player_UpdateSevenForceBattle+6   p
                tst.w   (PlayerScriptStateOffset).w
                bne.w   Input_ProcessDirectionInput_Return
                move.b  $69(a5),d1
                move.w  (ShootingMode).w,d0
                beq.s   Input_ProcessDirectionInput_CheckAlternateGate
                btst    #4,$69(a5)
                bne.s   Input_ProcessDirectionInput_ApplyHorizontalInput
                rts
; ---------------------------------------------------------------------------
Input_ProcessDirectionInput_CheckAlternateGate:         ; was: loc_16D9C
                btst    #4,$6A(a5)
                bne.s   Input_ProcessDirectionInput_ApplyHorizontalInput
                rts
; ---------------------------------------------------------------------------
Input_ProcessDirectionInput_ApplyHorizontalInput:       ; was: loc_16DA6
                                        ; Input_ProcessDirectionInput+22   j
                btst    #2,d1
                beq.s   Input_ProcessDirectionInput_CheckRightInput
                bclr    #3,$E(a5)
                bclr    #3,d1
                bra.s   Input_ProcessDirectionInput_DecodeDirection
; ---------------------------------------------------------------------------
Input_ProcessDirectionInput_CheckRightInput:            ; was: loc_16DB8
                btst    #3,d1
                beq.s   Input_ProcessDirectionInput_DecodeDirection
                bset    #3,$E(a5)
                bclr    #2,d1
Input_ProcessDirectionInput_DecodeDirection:            ; was: loc_16DC8
                                        ; Input_ProcessDirectionInput+3C   j
                andi.w  #$F,d1
                bne.s   Input_ProcessDirectionInput_LookupDirection
                moveq   #4,d0
                btst    #3,$E(a5)
                beq.s   Input_StoreDirectionByte
                moveq   #0,d0
                bra.s   Input_StoreDirectionByte
; ---------------------------------------------------------------------------
Input_ProcessDirectionInput_LookupDirection:            ; was: loc_16DDC
                move.b  Input_DirectionIndexTable(pc,d1.w),d0
; Stores processed direction input byte to player entity
Input_StoreDirectionByte:                               ; was: loc_16DE0
                                        ; Input_ProcessDirectionInput+5A   j
                move.b  d0,$9E(a5)
Input_ProcessDirectionInput_Return:                     ; was: locret_16DE4
                rts
; End of function Input_ProcessDirectionInput
; ---------------------------------------------------------------------------
Input_DirectionIndexTable:  dc.b    0, 6, 2, 0, 4, 5, 3, 0, 0, 7, 1, 0, 0, 0, 0, 0  ; was: byte_16DE6

; Auto-flips player direction based on weapon aim angle constraints
Player_AutoFlipDirection:                               ; was: sub_16DF6
                                        ; Player_InitGroundCrouchState+2E   j
                tst.w   (ShootingMode).w
                bne.s   Player_AutoFlipDirection_Return
                btst    #4,$69(a5)
                beq.s   Player_AutoFlipDirection_Return
                move.b  $9E(a5),d0
                btst    #3,$E(a5)
                beq.s   Player_AutoFlipDirection_CheckLeftFacing
                cmpi.b  #3,d0
                bmi.s   Player_AutoFlipDirection_Return
                cmpi.b  #6,d0
                bmi.s   Player_AutoFlipDirection_Flip
                rts
; ---------------------------------------------------------------------------
Player_AutoFlipDirection_CheckLeftFacing:               ; was: loc_16E1E
                cmpi.b  #2,d0
                bmi.s   Player_AutoFlipDirection_Flip
                cmpi.b  #7,d0
                bpl.s   Player_AutoFlipDirection_Flip
                rts
; ---------------------------------------------------------------------------
Player_AutoFlipDirection_Flip:                          ; was: loc_16E2C
                                        ; Player_AutoFlipDirection+2C   j
                eori.w  #$800,$E(a5)
Player_AutoFlipDirection_Return:                        ; was: locret_16E32
                                        ; Player_AutoFlipDirection+C   j
                rts
; End of function Player_AutoFlipDirection
; Accelerates horizontal velocity toward the limit selected by facing
Physics_AccelerateHorizontalByFacing:                   ; was: sub_16E34
                                        ; sub_167EE:Player_CeilingMovementState_Accelerate   p
                btst    #3,$E(a5)
                bne.s   Physics_AccelerateHorizontalByFacing_AcceleratePositive
                move.l  $18(a5),d0
                bpl.s   Physics_AccelerateHorizontalByFacing_AccelerateNegative
                cmpi.l  #$FFFBE000,d0
                bmi.s   Physics_AccelerateHorizontalByFacing_Store
Physics_AccelerateHorizontalByFacing_AccelerateNegative:  ; was: loc_16E4A
                subi.l  #$A800,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Physics_AccelerateHorizontalByFacing_AcceleratePositive:  ; was: loc_16E56
                move.l  $18(a5),d0
                bmi.s   Physics_AccelerateHorizontalByFacing_AddStep
                cmpi.l  #$42000,d0
                bpl.s   Physics_AccelerateHorizontalByFacing_Store
Physics_AccelerateHorizontalByFacing_AddStep:           ; was: loc_16E64
                addi.l  #$A800,d0
Physics_AccelerateHorizontalByFacing_Store:             ; was: loc_16E6A
                                        ; Physics_AccelerateHorizontalByFacing+2E   j
                move.l  d0,$18(a5)
                rts
; End of function Physics_AccelerateHorizontalByFacing
; Accelerates horizontal velocity toward the negative limit
Physics_AccelerateHorizontalNegative:                   ; was: sub_16E70
                                        ; Player_CeilingAirControlState+56   j
                move.l  $18(a5),d0
                bpl.s   Physics_AccelerateHorizontalNegative_SubtractStep
                cmpi.l  #$FFFD6000,d0
                bmi.s   Physics_AccelerateHorizontalNegative_Store
Physics_AccelerateHorizontalNegative_SubtractStep:      ; was: loc_16E7E
                subi.l  #$A800,d0
Physics_AccelerateHorizontalNegative_Store:             ; was: loc_16E84
                move.l  d0,$18(a5)
                rts
; End of function Physics_AccelerateHorizontalNegative
; Accelerates horizontal velocity toward the positive limit
Physics_AccelerateHorizontalPositive:                   ; was: sub_16E8A
                                        ; Player_CeilingAirControlState+6E   j
                move.l  $18(a5),d0
                bmi.s   Physics_AccelerateHorizontalPositive_AddStep
                cmpi.l  #$2A000,d0
                bpl.s   Physics_AccelerateHorizontalPositive_Store
Physics_AccelerateHorizontalPositive_AddStep:           ; was: loc_16E98
                addi.l  #$A800,d0
Physics_AccelerateHorizontalPositive_Store:             ; was: loc_16E9E
                move.l  d0,$18(a5)
                rts
; End of function Physics_AccelerateHorizontalPositive
; Selects the faster horizontal deceleration step
Player_DecelerateHorizontalVelocityFast:                ; was: sub_16EA4
                                        ; Player_GroundDecelerateState+34   p
                move.l  #$C000,d1
; End of function Player_DecelerateHorizontalVelocityFast
; Decelerates horizontal velocity towards zero
Player_DecelerateHorizontalVelocity:                    ; was: sub_16EAA
                                        ; Player_UnreferencedCounterForceTerrainPath+22   p
                move.l  $18(a5),d0
                bmi.s   Player_DecelerateHorizontalVelocity_IncreaseNegative
                sub.l   d1,d0
                bpl.s   Physics_StoreHorizontalVelocity
                moveq   #0,d0
                move.l  d0,$18(a5)
                rts
; ---------------------------------------------------------------------------
Player_DecelerateHorizontalVelocity_IncreaseNegative:   ; was: loc_16EBC
                add.l   d1,d0
                bmi.s   Physics_StoreHorizontalVelocity
                moveq   #0,d0
; Stores final horizontal velocity to player entity after deceleration
Physics_StoreHorizontalVelocity:                        ; was: loc_16EC2
                                        ; Player_DecelerateHorizontalVelocity+14   j
                move.l  d0,$18(a5)
                rts
; End of function Player_DecelerateHorizontalVelocity
; Renders the player's unarmed idle frame with cycling offsets
Player_RenderIdleFrame:                                 ; was: sub_16EC8
                                        ; Player_GroundWeaponSelectState+1E   j
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #6,d0
                move.b  Player_IdleFrameOffsets(pc,d0.w),d5
                move.b  Player_IdleFrameOffsets+1(pc,d0.w),d6
                movea.l #Player_CommonPrimarySpriteMapping,a1
                movea.l #Player_IdleSecondarySpriteMapping,a2
                bra.w   Player_BuildSpritePieces
; End of function Player_RenderIdleFrame
; ---------------------------------------------------------------------------
Player_IdleFrameOffsets:    dc.b    1, $FE, 0, $FF, 0, 0, 0, $FF  ; was: byte_16EEA
                                        ; Player_RenderIdleFrame+E   r

; Renders the shared motion pose, cycling its offsets while the counter is negative
Player_RenderMotionPose:                                ; was: sub_16EF2
                                        ; Player_HandleLandingState+76   j
                tst.w   $48(a5)
                bpl.s   Player_RenderMotionPose_UseStaticOffsets
Player_RenderMotionPose_UseAnimatedOffsets:             ; was: loc_16EF8
                move.w  (FrameCounter).w,d0
                asr.w   #2,d0
                andi.w  #6,d0
                move.b  Player_MotionPoseFrameOffsets(pc,d0.w),d5
                move.b  Player_MotionPoseFrameOffsets+1(pc,d0.w),d6
                movea.l #Player_CommonPrimarySpriteMapping,a1
                movea.l #Player_MotionPoseSecondarySpriteMapping,a2
                bra.w   Player_BuildSpritePieces
; ---------------------------------------------------------------------------
; Uses one fixed offset pair once the animation counter is non-negative
Player_RenderMotionPose_UseStaticOffsets:               ; was: loc_16F1A
                moveq   #0,d5
                moveq   #8,d6
                movea.l #Player_CommonPrimarySpriteMapping,a1
                movea.l #Player_CommonMovementSecondarySpriteMapping,a2
                bra.w   Player_BuildSpritePieces
; End of function Player_RenderMotionPose
; ---------------------------------------------------------------------------
Player_MotionPoseFrameOffsets:  dc.b    1, $F, 0, $10, 0, $11, 0, $10  ; was: byte_16F2E
                                        ; Player_RenderMotionPose+14   r
