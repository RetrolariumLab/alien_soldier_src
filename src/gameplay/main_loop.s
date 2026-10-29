Sys_GameplayMainLoop:                                   ; was: sub_1C65C
                bsr.w   Sys_GameplayPreUpdateNoOp
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateCamera
                move.w  #$C7F0,(HUDDynamicStripTileAttr).w
                move.w  #$20,(HUDDynamicStripXOffset).w  ; ' '
Sys_GameplayMainLoop_UpdateCamera:                      ; was: loc_1C672
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_ApplyCameraMotion
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$822,(VDP_DATA).l
Sys_GameplayMainLoop_ApplyCameraMotion:                 ; was: loc_1C68A
                bsr.w   Object_ApplyCameraMotion
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateCollision
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$EEE,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateCollision:                   ; was: loc_1C6A6
                jsr     (Collision_UpdateSystem).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdatePrimaryEffects
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$E,(VDP_DATA).l
Sys_GameplayMainLoop_UpdatePrimaryEffects:              ; was: loc_1C6C4
                jsr     (Sprite_InitializePriorityBuckets).l
                bsr.w   Sys_BeginVisibleObjectList
                bsr.w   UI_UpdateStageNumberBCD
                jsr     (Palette_UpdatePrimaryEffect).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_BuildHUDSprites
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$E00,(VDP_DATA).l
Sys_GameplayMainLoop_BuildHUDSprites:                   ; was: loc_1C6F0
                jsr     (UI_BuildHUDSpriteList).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdatePlayer
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$E0,(VDP_DATA).l
Sys_GameplayMainLoop_UpdatePlayer:                      ; was: loc_1C70E
                jsr     (Player_Update).l
                jsr     (Weapon_UpdateStateAndAmmoRegen).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateSpawner
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$E,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateSpawner:                     ; was: loc_1C732
                jsr     (Sys_UpdateObjectSpawner).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateProjectiles
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$E00,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateProjectiles:                 ; was: loc_1C750
                jsr     (Projectile_ProcessVisiblePool).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateStageEffects
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateStageEffects:                ; was: loc_1C76E
                jsr     (EnemySpawn_UpdateDirector).l
                jsr     (TransitionEffect_UpdateBuffers).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateStage
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateStage:                       ; was: loc_1C792
                jsr     (Stage_DispatchSelectedProcess).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateSecondaryEffects
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$EEE,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateSecondaryEffects:            ; was: loc_1C7B0
                jsr     (Palette_UpdateSecondaryEffect).l
                bsr.w   Sys_UpdateObjectCount
                jsr     (MessageSequence_Dispatch).l
                jsr     (UI_UpdateGameplayHUD).l
                bsr.w   Effect_ScreenShakeUpdate
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_ProcessObjects
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #$E,(VDP_DATA).l
Sys_GameplayMainLoop_ProcessObjects:                    ; was: loc_1C7E2
                jsr     (Sprite_RenderObjectList).l
                tst.b   (FrameTimingDebugFlag).w
                bpl.s   Sys_GameplayMainLoop_UpdateFade
                move.l  #$C0420000,(VDP_CTRL).l
                move.w  #0,(VDP_DATA).l
Sys_GameplayMainLoop_UpdateFade:                        ; was: loc_1C800
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   Sys_GameplayMainLoop_HandleTransition
Sys_GameplayMainLoop_RequestExit:                       ; was: loc_1C80E
                move.b  #$41,(GameplayControlFlags).w   ; 'A'
                bra.s   Sys_GameplayMainLoop_UpdateFrameTiming
; ---------------------------------------------------------------------------
Sys_GameplayMainLoop_HandleTransition:                  ; was: loc_1C816
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   Sys_GameplayMainLoop_UpdateFrameTiming
                move.w  (GameplayExitMode).w,d0
                beq.s   Sys_GameplayMainLoop_RequestExit
                clr.w   (WeaponIconTransferState).w
                cmpi.w  #1,d0
                bne.s   Sys_GameplayMainLoop_SelectMode34
                move.w  #$2C,(GameModeIndex).w          ; ','
                clr.w   (GameSubstateIndex).w
                move.b  #4,d0
                jsr     (Sound_QueueSFXRequest).l
                bra.s   Sys_GameplayMainLoop_UpdateFrameTiming
; ---------------------------------------------------------------------------
Sys_GameplayMainLoop_SelectMode34:                      ; was: loc_1C844
                cmpi.w  #3,d0
                bne.s   Sys_GameplayMainLoop_SelectMode68
                move.w  #$34,(GameModeIndex).w          ; '4'
                clr.w   (GameSubstateIndex).w
                bra.s   Sys_GameplayMainLoop_UpdateFrameTiming
; ---------------------------------------------------------------------------
Sys_GameplayMainLoop_SelectMode68:                      ; was: loc_1C856
                move.w  #$68,(GameModeIndex).w          ; 'h'
                clr.w   (GameSubstateIndex).w
Sys_GameplayMainLoop_UpdateFrameTiming:                 ; was: loc_1C860
                                        ; Sys_GameplayMainLoop+1C0   j
                tst.b   (GameplayControlFlags).w
                bmi.s   Sys_GameplayMainLoop_FinishFrame
                addq.w  #1,(FrameCounter).w
                subq.w  #1,(FrameFreezeTimer).w
                bpl.s   Sys_GameplayMainLoop_SetFrozenFrame
                move.w  #$FFFF,(FrameFreezeTimer).w
                move.b  #0,d0
                bra.s   Sys_GameplayMainLoop_StoreFrameFlag
; ---------------------------------------------------------------------------
Sys_GameplayMainLoop_SetFrozenFrame:                    ; was: loc_1C87C
                move.b  #$80,d0
Sys_GameplayMainLoop_StoreFrameFlag:                    ; was: loc_1C880
                move.b  d0,(FrameControlFlags).w
Sys_GameplayMainLoop_FinishFrame:                       ; was: loc_1C884
                move.b  (GameplayControlFlags).w,d0
                or.b    d0,(FrameControlFlags).w
                jmp     (Gfx_CycleBackdropColorIndices).l
; End of function Sys_GameplayMainLoop
; Set game state to $40
Sys_SetState40:
                move.w  #$40,(GameModeIndex).w          ; '@'  ; was: sub_1C892
                clr.w   (GameSubstateIndex).w
                rts
; End of function Sys_SetState40
; Set game state to $3C with input
Sys_SetState3CWithInput:
                move.w  #$3C,(GameModeIndex).w          ; '<'  ; was: sub_1C89E
                clr.w   (GameSubstateIndex).w
                move.b  #1,d0
                jmp     (Sound_QueueRequest).l
; End of function Sys_SetState3CWithInput
; Converts the stage table index to the BCD stage number used by results
UI_UpdateStageNumberBCD:                                ; was: sub_1C8B2
                move.w  (StageTableIndex).w,d0
                asr.w   #1,d0
                move.b  UI_StageNumberBcdTable(pc,d0.w),(StageNumberBCD).w
                rts
; End of function UI_UpdateStageNumberBCD
; ---------------------------------------------------------------------------
UI_StageNumberBcdTable: dc.b    1, 2, 3, 4, 5, 6, 7, 8, 9, $10  ; was: byte_1C8C0
                dc.b    $11, $12, $13, $14, $15, $16, $17, $18, $19, $20
                dc.b    $21, $22, $23, $24, $25, $26, $27, $28, $29, $30
                dc.b    $31, $32, $33, $34, $35, $36, $37, $38, $39, $40
                dc.b    $41, $42, $43, $44, $45, $46, $47, $48, $49, $50

; Initializes the visible-object list cursor when frame processing is active
Sys_BeginVisibleObjectList:                             ; was: sub_1C8F2
                                        ; UI_UpdateOptionsScreen+52   p
                tst.b   (FrameControlFlags).w
                bmi.w   Sys_BeginVisibleObjectList_Return
                move.w  #$ED00,(VisibleObjectListCursor).w
Sys_BeginVisibleObjectList_Return:                      ; was: locret_1C900
                rts
; End of function Sys_BeginVisibleObjectList
; Calculates number of active visible objects from list pointer
Sys_UpdateObjectCount:                                  ; was: sub_1C902
                                        ; UI_UpdateOptionsScreen+62   p
                tst.b   (FrameControlFlags).w
                bmi.w   Sys_UpdateObjectCount_Return
                move.w  (VisibleObjectListCursor).w,d0
                subi.w  #$ED00,d0
                lsr.w   #1,d0
                move.w  d0,(VisibleObjectCount).w
Sys_UpdateObjectCount_Return:                           ; was: locret_1C918
                rts
; End of function Sys_UpdateObjectCount
; Display pause menu graphics
UI_DisplayPauseGraphics:
                move.b  (GameplayControlFlags).w,d0     ; was: sub_1C91A
                bpl.w   UI_DisplayPauseGraphics_Return
                btst    #6,d0
                beq.w   UI_DisplayPauseGraphics_Return
                move.b  (ControllerHeldState).w,d0
                or.b    (ControllerHeldState+1).w,d0
                andi.b  #$40,d0                         ; '@'
                bne.w   UI_DisplayPauseGraphics_Return
                btst    #4,(VBlankFrameCounter+1).w
                bne.w   UI_DisplayPauseGraphics_Render
UI_DisplayPauseGraphics_Return:                         ; was: locret_1C944
                                        ; UI_DisplayPauseGraphics+C   j
                rts
; ---------------------------------------------------------------------------
UI_DisplayPauseGraphics_Render:                         ; was: loc_1C946
                lea     (SharedSpriteScratch).w,a0
                movea.w a0,a1
                move.l  #PauseMenuZ80SpriteData,(a1)+
                move.w  #$C7EB,(a1)+
                move.w  #$C0,(a1)+
                move.l  #Z80_RAM,(a1)+
                move.w  #$C7EF,(a1)+
                move.w  #$E0,(a1)+
                move.w  #$FFFF,(a1)
                jmp     (Sprite_AppendOAMEntries).l
; End of function UI_DisplayPauseGraphics
; ---------------------------------------------------------------------------
; Attribute-bit combinations for the four horizontal/vertical flip phases
SpriteFlipBitsTable:    dc.w    0, $800, $1800, $1000   ; was: word_1C972
                                        ; Pickup_Update+7C   o

; Publishes cyclic sprite flip bits and applies camera deltas to active objects
Object_ApplyCameraMotion:                               ; was: sub_1C97A
                                        ; UI_UpdateOptionsScreen+46   p
                tst.b   (FrameControlFlags).w
                bpl.s   Object_ApplyCameraMotion_Begin
                rts
; ---------------------------------------------------------------------------
Object_ApplyCameraMotion_Begin:                         ; was: loc_1C982
                movea.l #SpriteFlipBitsTable,a0
                move.w  (FrameCounter).w,d0
                asl.w   #1,d0
                andi.w  #6,d0
                move.w  (a0,d0.w),(GlobalSpriteFlipBits).w
                move.w  (PrimaryCameraXPosition).w,d0
                sub.w   (PreviousCameraXPosition).w,d0
                move.w  (PrimaryCameraYPosition).w,d1
                sub.w   (PreviousCameraYPosition).w,d1
                move.w  d0,(CameraXDelta).w
                move.w  d1,(CameraYDelta).w
                move.w  (PrimaryCameraXPosition).w,(PreviousCameraXPosition).w
                move.w  (PrimaryCameraYPosition).w,(PreviousCameraYPosition).w
                btst    #6,(CameraMotionLockFlags).w
                beq.s   Object_ApplyCameraMotion_CheckVerticalDelta
                moveq   #0,d0
Object_ApplyCameraMotion_CheckVerticalDelta:            ; was: loc_1C9C6
                btst    #7,(CameraMotionLockFlags).w
                beq.s   Object_ApplyCameraMotion_CheckMotion
                moveq   #0,d1
Object_ApplyCameraMotion_CheckMotion:                   ; was: loc_1C9D0
                tst.w   d0
                bne.s   Object_ApplyCameraMotion_WithCameraDelta
                tst.w   d1
                beq.w   Object_ApplyCameraMotion_WithoutCameraDelta
Object_ApplyCameraMotion_WithCameraDelta:               ; was: loc_1C9DA
                move.b  #3,d5
                move.b  #2,d6
                move.b  #0,d7
                lea     (PlayerObjectType).w,a5
                move.b  PlayerObjectFlags-PlayerObjectType(a5),d2
                beq.s   Object_ApplyCameraMotion_ScanVisible
                bsr.w   Physics_ApplyVelocityWithBounds
                bsr.w   Physics_ApplyPositionOffset
                bsr.w   Object_ClampToPlayfield
Object_ApplyCameraMotion_ScanVisible:                   ; was: loc_1C9FC
                move.w  (VisibleObjectCount).w,d4
                beq.s   Object_ApplyCameraMotion_ReturnWithDelta
                subq.w  #1,d4
                lea     (VisibleObjectList).w,a4
Object_ApplyCameraMotion_VisibleLoop:                   ; was: loc_1CA08
                movea.w (a4)+,a5
                move.b  2(a5),d2
                beq.s   Object_ApplyCameraMotion_NextVisible
                btst    d5,d2
                beq.s   Object_ApplyCameraMotion_ProcessVerticalVelocity
                move.l  $18(a5),d3
                add.l   d3,$10(a5)
Object_ApplyCameraMotion_ProcessVerticalVelocity:       ; was: loc_1CA1C
                btst    d6,d2
                beq.s   Object_ApplyCameraMotion_ProcessCameraDelta
                move.l  $1C(a5),d3
                add.l   d3,$14(a5)
Object_ApplyCameraMotion_ProcessCameraDelta:            ; was: loc_1CA28
                btst    d7,d2
                beq.s   Object_ApplyCameraMotion_NextVisible
                sub.w   d0,$10(a5)
                add.w   d1,$14(a5)
Object_ApplyCameraMotion_NextVisible:                   ; was: loc_1CA34
                                        ; Object_ApplyCameraMotion+B0   j
                dbf     d4,Object_ApplyCameraMotion_VisibleLoop
Object_ApplyCameraMotion_ReturnWithDelta:               ; was: locret_1CA38
                rts
; ---------------------------------------------------------------------------
Object_ApplyCameraMotion_WithoutCameraDelta:            ; was: loc_1CA3A
                move.b  #3,d5
                move.b  #2,d6
                lea     (PlayerObjectType).w,a5
                move.b  PlayerObjectFlags-PlayerObjectType(a5),d2
                beq.s   Object_ApplyCameraMotion_ScanStationary
                bsr.w   Physics_ApplyVelocityWithBounds
                bsr.w   Object_ClampToPlayfield
Object_ApplyCameraMotion_ScanStationary:                ; was: loc_1CA54
                move.w  (VisibleObjectCount).w,d4
                beq.s   Object_ApplyCameraMotion_Return
                subq.w  #1,d4
                lea     (VisibleObjectList).w,a4
Object_ApplyCameraMotion_StationaryLoop:                ; was: loc_1CA60
                movea.w (a4)+,a5
                move.b  2(a5),d2
                beq.s   Object_ApplyCameraMotion_NextStationary
                btst    d5,d2
                beq.s   Object_ApplyCameraMotion_ProcessStationaryVertical
                move.l  $18(a5),d3
                add.l   d3,$10(a5)
Object_ApplyCameraMotion_ProcessStationaryVertical:     ; was: loc_1CA74
                btst    d6,d2
                beq.s   Object_ApplyCameraMotion_NextStationary
                move.l  $1C(a5),d3
                add.l   d3,$14(a5)
Object_ApplyCameraMotion_NextStationary:                ; was: loc_1CA80
                                        ; Object_ApplyCameraMotion+FC   j
                dbf     d4,Object_ApplyCameraMotion_StationaryLoop
Object_ApplyCameraMotion_Return:                        ; was: locret_1CA84
                rts
; End of function Object_ApplyCameraMotion
; Applies velocity with boundary clamping
Physics_ApplyVelocityWithBounds:                        ; was: sub_1CA86
                                        ; Object_ApplyCameraMotion+D2   p
                btst    d5,d2
                beq.s   Physics_ApplyVelocityWithBounds_ProcessVertical
                move.l  $18(a5),d3
                move.l  (StageMotionXDelta).w,d4
                btst    #1,(PlayerActionStateFlags).w
                beq.s   Physics_ApplyVelocityWithBounds_AddHorizontalBias
                asr.l   #2,d4
Physics_ApplyVelocityWithBounds_AddHorizontalBias:      ; was: loc_1CA9C
                add.l   d4,d3
                move.l  (PhysicsXVelocityLimit).w,d4
                tst.l   d3
                bmi.s   Physics_ApplyVelocityWithBounds_ClampNegativeHorizontal
                cmp.l   d4,d3
                bmi.s   Physics_ApplyVelocityWithBounds_ApplyHorizontal
                move.l  d4,d3
                bra.s   Physics_ApplyVelocityWithBounds_ApplyHorizontal
; ---------------------------------------------------------------------------
Physics_ApplyVelocityWithBounds_ClampNegativeHorizontal:  ; was: loc_1CAAE
                neg.l   d4
                cmp.l   d4,d3
                bpl.s   Physics_ApplyVelocityWithBounds_ApplyHorizontal
                move.l  d4,d3
Physics_ApplyVelocityWithBounds_ApplyHorizontal:        ; was: loc_1CAB6
                                        ; Physics_ApplyVelocityWithBounds+26   j
                add.l   d3,$10(a5)
Physics_ApplyVelocityWithBounds_ProcessVertical:        ; was: loc_1CABA
                btst    d6,d2
                beq.s   Physics_ApplyVelocityWithBounds_Return
                move.l  $1C(a5),d3
                add.l   (StageMotionYDelta).w,d3
                move.l  (PhysicsYVelocityLimit).w,d4
                tst.l   d3
                bmi.s   Physics_ApplyVelocityWithBounds_ClampNegativeVertical
                cmp.l   d4,d3
                bmi.s   Physics_ApplyVelocityWithBounds_ApplyVertical
                move.l  d4,d3
                bra.s   Physics_ApplyVelocityWithBounds_ApplyVertical
; ---------------------------------------------------------------------------
Physics_ApplyVelocityWithBounds_ClampNegativeVertical:  ; was: loc_1CAD6
                neg.l   d4
                cmp.l   d4,d3
                bpl.s   Physics_ApplyVelocityWithBounds_ApplyVertical
                move.l  d4,d3
Physics_ApplyVelocityWithBounds_ApplyVertical:          ; was: loc_1CADE
                                        ; Physics_ApplyVelocityWithBounds+4E   j
                add.l   d3,$14(a5)
Physics_ApplyVelocityWithBounds_Return:                 ; was: locret_1CAE2
                rts
; End of function Physics_ApplyVelocityWithBounds
; Applies the camera delta to an object whose flag bit 0 makes it follow the camera
Physics_ApplyPositionOffset:                            ; was: sub_1CAE4
                btst    d7,d2
                beq.s   Physics_ApplyPositionOffset_Return
                sub.w   d0,$10(a5)
                add.w   d1,$14(a5)
Physics_ApplyPositionOffset_Return:                     ; was: locret_1CAF0
                rts
; End of function Physics_ApplyPositionOffset
; Clamps an object's position to the enabled playfield bounds
Object_ClampToPlayfield:                                ; was: sub_1CAF2
                                        ; Object_ApplyCameraMotion+D6   p
                btst    #1,(PlayerRestrictionFlags).w
                bne.s   Object_ClampToPlayfield_CheckTop
                cmpi.w  #$90,$10(a5)
                bpl.s   Object_ClampToPlayfield_CheckRight
                move.w  #$90,$10(a5)
                bra.s   Object_ClampToPlayfield_CheckTop
; ---------------------------------------------------------------------------
Object_ClampToPlayfield_CheckRight:                     ; was: loc_1CB0A
                cmpi.w  #$1B0,$10(a5)
                bmi.s   Object_ClampToPlayfield_CheckTop
                move.w  #$1AF,$10(a5)
Object_ClampToPlayfield_CheckTop:                       ; was: loc_1CB18
                                        ; Object_ClampToPlayfield+16   j
                btst    #2,(PlayerRestrictionFlags).w
                bne.s   Object_ClampToPlayfield_Return
                cmpi.w  #$98,$14(a5)
                bpl.s   Object_ClampToPlayfield_Return
                move.w  #$98,$14(a5)
Object_ClampToPlayfield_Return:                         ; was: locret_1CB2E
                                        ; Object_ClampToPlayfield+34   j
                rts
; End of function Object_ClampToPlayfield
Sys_GameplayPreUpdateNoOp:                              ; was: nullsub_2
                rts
; End of function Sys_GameplayPreUpdateNoOp
