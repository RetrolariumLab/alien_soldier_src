; Initialize the Stage 9 fly corridor, its raster layout, and camera state
Stage9_InitializeFlyCorridor:                           ; was: sub_D0B4
                move.w  #0,(PrimaryCameraXPosition).w
                move.w  #0,(PrimaryCameraYPosition).w
                move.w  #0,(SecondaryCameraXPos).w
                move.w  #0,(SecondaryCameraYPos).w
                move.w  (PrimaryCameraXPosition).w,(PreviousCameraXPosition).w
                move.w  (PrimaryCameraYPosition).w,(PreviousCameraYPosition).w
                bsr.w   Midgame_LoadFlyingNeoPaletteCommands
                move.w  #$2AC,(Entity_ObjectPool).w
                clr.w   (PrimaryEntityState).w
                move.l  #$FFFEE000,(StageMotionXDelta).w
                addq.w  #2,(StageStateOffset).w
                move.w  #1,(MidgameLightningMode).w
                clr.w   (Stage9RevealColumn).w
                clr.w   (MidgameVerticalPhase).w
                move.l  #$180000,(Stage9FlyCorridorY).w
                clr.w   (CameraXLowerBound).w
                move.w  #$A0,(CameraXUpperBound).w
                move.b  #3,(VDPReg11Shadow+1).w
                move.b  #4,(PlaneAScrollModeFlags).w
                move.b  #$30,(PlaneBScrollModeFlags).w  ; '0'
                move.w  #$2C,(RasterEffectIndex).w      ; ','
                clr.w   (RasterEffectInitState).w
                move.w  #8,(RasterLayoutOffset).w
                clr.b   (Stage8TilemapMode).l
                jmp     Stage_PrepareFourWordRangesWithD
; End of function Stage9_InitializeFlyCorridor
; Update the corridor until its vertical position reaches the ship transition
Stage9_UpdateFlyCorridor:                               ; was: sub_D140
                cmpi.w  #$B0,(Stage9FlyCorridorY).w
                bmi.s   Stage9_UpdateFlyCorridorScroll
                lea     Stage9_CaterpillarTileAssetLoadList(pc),a0
                nop
                jsr     (Data_ProcessPointer).l
                addq.w  #2,(StageStateOffset).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                clr.w   (RasterLayoutOffset).w
                bra.s   Stage9_InitializeCaterpillarCamera
; End of function Stage9_UpdateFlyCorridor
; Build the corridor raster offsets while advancing the camera and reveal columns
Stage9_UpdateFlyCorridorScroll:                         ; was: sub_D166
                move.l  #Stage9_FlyCorridorLightningPaletteEntryLists,(PaletteEntryLists).w
                bsr.w   Midgame_UpdateRandomLightningEffect
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                bsr.w   Stage9_WriteVerticalRasterOffsets
                bsr.w   Midgame_UpdateTrainAndFlyCorridorParallaxRows
                cmpi.w  #$60,(Stage9FlyCorridorY).w     ; '`'
                bmi.s   Stage9_FlyCorridor_AdvanceVerticalPosition
                bsr.w   Stage9_UpdateFlyCorridorRevealColumns
Stage9_FlyCorridor_AdvanceVerticalPosition:             ; was: loc_D18E
                addi.l  #$4000,(Stage9FlyCorridorY).w
                movea.w #(FlyCorridorRasterBuffer-M68K_RAM),a0
                moveq   #$60,d0                         ; '`'
                moveq   #$16,d7
Stage9_FlyCorridor_WriteAlternatingRowOffsets:          ; was: loc_D19E
                neg.w   d0
                move.w  d0,(a0)+
                neg.w   d0
                addq.w  #8,d0
                dbf     d7,Stage9_FlyCorridor_WriteAlternatingRowOffsets
                moveq   #3,d7
Stage9_FlyCorridor_ClearTrailingRowOffsets:             ; was: loc_D1AC
                move.w  #0,(a0)+
                dbf     d7,Stage9_FlyCorridor_ClearTrailingRowOffsets
                movea.w #(FlyCorridorRasterBuffer-M68K_RAM),a0
                move.w  (Stage9FlyCorridorY).w,d0
                move.w  d0,d1
                addi.w  #$50,d0                         ; 'P'
Stage9_FlyCorridor_CheckVisibleRowOffset:               ; was: loc_D1C2
                subq.w  #8,d1
                bpl.s   Stage9_FlyCorridor_WriteVisibleRowOffset
                rts
; ---------------------------------------------------------------------------
Stage9_FlyCorridor_WriteVisibleRowOffset:               ; was: loc_D1C8
                neg.w   d0
                move.w  d0,(a0)+
                neg.w   d0
                bra.s   Stage9_FlyCorridor_CheckVisibleRowOffset
; End of function Stage9_UpdateFlyCorridorScroll
; ---------------------------------------------------------------------------
Stage9_CaterpillarTileAssetLoadList:    dc.w    7       ; command: LZSS to VRAM  ; was: stru_D1D0
                dc.l    Stage9CaterpillarTileArt        ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF

; Seed the secondary camera used by the Caterpillar ship traversal
Stage9_InitializeCaterpillarCamera:                     ; was: sub_D1DA
                move.w  (PrimaryCameraXPosition).w,(SecondaryCameraXPos).w
                move.w  #$F900,(SecondaryCameraYPos).w
                bra.w   Stage9_InitializeCaterpillarEncounter
; End of function Stage9_InitializeCaterpillarCamera
; Unreferenced alternate entry into the Caterpillar scrolling path
UnreferencedStage9_UpdateCaterpillarScroll:
                move.l  #Stage9_FlyCorridorLightningPaletteEntryLists,(PaletteEntryLists).w  ; was: sub_D1EA
                bsr.w   Midgame_UpdateRandomLightningEffect
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Stage9_UpdateCaterpillarCameraAndScroll
; End of function UnreferencedStage9_UpdateCaterpillarScroll
; Reveal one column of the fly-corridor tilemap every eight frames
Stage9_UpdateFlyCorridorRevealColumns:                  ; was: sub_D1FE
                cmpi.w  #$20,(Stage9RevealColumn).w     ; ' '
                bne.s   Stage9_RevealNextFlyCorridorColumn
                clr.l   (StageMotionXDelta).w
                rts
; ---------------------------------------------------------------------------
Stage9_RevealNextFlyCorridorColumn:                     ; was: loc_D20C
                movea.w #(FlyCorridorTilemap-M68K_RAM),a0
                move.w  (Stage9RevealColumn).w,d0
                moveq   #$16,d7
Stage9_ClearFlyCorridorColumnRows:                      ; was: loc_D216
                move.b  #0,(a0,d0.w)
                adda.w  #$20,a0                         ; ' '
                dbf     d7,Stage9_ClearFlyCorridorColumnRows
                movea.w (VDPCommandQueueHead).w,a4
                move.w  #$80,-(a4)
                move.w  #$7AC0,-(a4)
                move.w  #$9500,-(a4)
                move.w  #$96CB,-(a4)
                move.l  #$8F02977F,-(a4)
                move.l  #$94019310,-(a4)
                move.w  a4,(VDPCommandQueueHead).w
                addi.l  #$200,(StageMotionXDelta).w
                bmi.s   Stage9_UpdateFlyCorridorRevealTimer
                clr.l   (StageMotionXDelta).w
Stage9_UpdateFlyCorridorRevealTimer:                    ; was: loc_D256
                move.w  (FrameCounter).w,d0
                andi.w  #7,d0
                bne.s   Stage9_UpdateFlyCorridorRevealColumns_Return
                addq.w  #1,(Stage9RevealColumn).w
Stage9_UpdateFlyCorridorRevealColumns_Return:           ; was: locret_D264
                rts
; End of function Stage9_UpdateFlyCorridorRevealColumns
; ---------------------------------------------------------------------------
; Unreferenced 32-byte permutation containing each index from 0 through 31 once
UnreferencedStage9IndexPermutation: binclude "data/other/unreferenced_stage_9_index_permutation.bin"  ; was: unused_2

; Initialize the Caterpillar encounter and enter its scrolling update path
Stage9_InitializeCaterpillarEncounter:                  ; was: sub_D286
                addq.w  #2,(StageStateOffset).w
                clr.w   (MidgameLightningMode).w
                clr.l   (StageCameraYVelocity).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.w  #$128,(Entity_ObjectPool).w
                move.w  #$C470,(HUDDynamicStripTileAttr).w
                clr.w   (HUDDynamicStripXOffset).w
                move.b  #9,(PlaneAScrollModeFlags).w
                move.b  #$24,(PlaneBScrollModeFlags).w  ; '$'
                bra.s   Stage9_UpdateCaterpillarShipTraversal_Camera
; End of function Stage9_InitializeCaterpillarEncounter
; Follow the player across the Caterpillar ship and stream its tilemap columns
Stage9_UpdateCaterpillarShipTraversal:                  ; was: sub_D2B6
                move.b  #6,(VDPReg11Shadow+1).w
Stage9_UpdateCaterpillarShipTraversal_Camera:           ; was: loc_D2BC
                tst.b   (DataLoaderControl).w
                bmi.s   Stage9_UpdateCaterpillarShipTraversal_Position
                cmpi.w  #$20,(HUDDynamicStripXOffset).w  ; ' '
                bpl.s   Stage9_UpdateCaterpillarShipTraversal_Position
                addq.w  #2,(HUDDynamicStripXOffset).w
Stage9_UpdateCaterpillarShipTraversal_Position:         ; was: loc_D2CE
                                        ; Stage9_UpdateCaterpillarShipTraversal+12   j
                move.l  (PrimaryCameraXPosition).w,(Stage9CameraXSnapshot).w
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                move.l  (PrimaryCameraXPosition).w,d7
                sub.l   (Stage9CameraXSnapshot).w,d7
                addi.l  #$12000,d7
                add.l   d7,(SecondaryCameraXPos).w
                move.w  (SecondaryCameraXPos).w,d0
                addi.w  #$158,d0
                tst.l   d7
                bpl.s   Stage9_StreamCaterpillarShipColumn
                move.w  (SecondaryCameraXPos).w,d0
                subi.w  #$58,d0                         ; 'X'
Stage9_StreamCaterpillarShipColumn:                     ; was: loc_D2FE
                move.w  (SecondaryCameraYPos).w,d1
                lea     Stage9_CaterpillarShipColumnTransferDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueColumnFromDescriptor).l
                move.w  (SecondaryCameraXPos).w,(Stage9SecondaryXCopy).w
                bsr.w   Stage9_UpdateCaterpillarOscillationAndRasterRows
                move.w  (Stage9SecondaryXCopy).w,(SecondaryCameraXPos).w
                move.w  (SecondaryCameraXPos).w,d5
                add.w   (PrimaryCameraXPosition).w,d5
                cmpi.w  #$9F0,d5
                bmi.s   Stage9_CheckCaterpillarShipTransition
                move.b  #1,(SoundFadeOutDelay).w
Stage9_CheckCaterpillarShipTransition:                  ; was: loc_D332
                cmpi.w  #$A00,d5
                bmi.s   Stage9_UpdateCaterpillarShipTraversal_Return
                bsr.w   Stage_TransitionToNextPhase
                move.b  #2,(VDPReg11Shadow+1).w
                move.b  #$10,(PlaneAScrollModeFlags).w
                move.b  #3,(PlaneBScrollModeFlags).w
                clr.w   (SecondaryCameraYPos).w
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  #0,(TilemapRowXOrFillWord).w
                lea     Stage9_XiTigerEntranceTileAssetLoadList(pc),a0
                nop
                jsr     (Data_ProcessPointer).l
                move.w  #$460,(Entity_ObjectPool).w
                clr.w   (PrimaryEntityState).w
                move.w  #$60,(StageTransitionTimer).w   ; '`'
Stage9_UpdateCaterpillarShipTraversal_Return:           ; was: locret_D38A
                rts
; End of function Stage9_UpdateCaterpillarShipTraversal
; ---------------------------------------------------------------------------
Stage9_CaterpillarShipColumnTransferDescriptor: dc.w    $FFFF, $7000, $FFFF, $6800, $FFFF, $2000, 0, $6000  ; was: word_D38C
Stage9_XiTigerEntranceTileAssetLoadList:        dc.w    7  ; command: LZSS to VRAM  ; was: stru_D39C
                dc.l    Stage9XiTigerEntranceTileArt    ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    $FFFF

; Scroll the Caterpillar ship out, then select the Xi-Tiger transition route
Stage9_UpdateCaterpillarShipExit:                       ; was: sub_D3A6
                subq.w  #1,(HUDDynamicStripXOffset).w
                jsr     (Tilemap_QueueNextConstantRow).l
                addi.l  #-$10000,(PrimaryCameraXPosition).w
                bsr.w   Stage9_UpdateCaterpillarOscillationAndRasterRows
                tst.w   (PrimaryCameraXPosition).w
                bpl.s   Stage9_UpdateCaterpillarShipExit_Return
                clr.w   (PrimaryCameraXPosition).w
                clr.l   (CameraXDelta).w
                tst.w   (MessageSequenceState).w
                bne.s   Stage9_UpdateCaterpillarShipExit_Return
                tst.w   (TilemapRowCountdown).w
                bpl.s   Stage9_UpdateCaterpillarShipExit_Return
                subq.w  #1,(StageTransitionTimer).w
                bpl.s   Stage9_UpdateCaterpillarShipExit_Return
                addq.w  #2,(StageStateOffset).w
                clr.w   (CameraXLowerBound).w
                clr.w   (CameraXUpperBound).w
                move.w  #$8002,(PaletteFadeMode).w
                clr.w   (PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                move.b  #$80,(GameplayControlFlags).w
                tst.b   (StageRouteFlags).w
                beq.s   Stage9_SelectXiTigerTransitionRoute
                move.b  #$82,d0
                jsr     (Sound_QueueBGMRequest).l
                bra.w   Stage9_LoadXiTigerEncounterAssets
; ---------------------------------------------------------------------------
Stage9_SelectXiTigerTransitionRoute:                    ; was: loc_D412
                move.w  #0,(SetupTransitionIndex).w
                move.w  #4,(GameplayExitMode).w
Stage9_UpdateCaterpillarShipExit_Return:                ; was: locret_D41E
                                        ; Stage9_UpdateCaterpillarShipExit+28   j
                rts
; End of function Stage9_UpdateCaterpillarShipExit
; Return while the Xi-Tiger entrance delay remains active
Stage9_XiTigerEntranceDelay_Return:                     ; was: nullsub_23
                rts
; End of function Stage9_XiTigerEntranceDelay_Return
; Initialize health, display state, and assets for the Xi-Tiger encounter
Stage9_InitializeXiTigerEncounter:                      ; was: sub_D422
                bsr.w   Stage_InitializeBossHealthAndCounter
                move.w  (BossHealth).w,(DisplayedBossHealth).w
                move.w  (PlayerHealth).w,(DisplayedPlayerHealth).w
                move.b  #$10,(PlaneAScrollModeFlags).w
                move.b  #$40,(GameplayControlFlags).w   ; '@'
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.w  #$20,(PlayerScriptStateOffset).w  ; ' '
                move.w  #$40,(ScriptedInputStepTimer).w  ; '@'
Stage9_LoadXiTigerEncounterAssets:                      ; was: loc_D450
                move.w  #$70,(StageStateOffset).w       ; 'p'
                move.w  #$10,(XiTigerEntranceTimer).w
                lea     (Boss_XiTigerAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage9_InitializeXiTigerEncounter
; Count down before entering the Xi-Tiger entrance-object wait
Stage9_UpdateXiTigerEntranceDelay:                      ; was: sub_D468
                move.w  #$8004,(PaletteFadeMode).w
                move.w  #$10,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                subq.w  #1,(XiTigerEntranceTimer).w
                bpl.w   Stage9_XiTigerEntranceDelay_Return
                move.b  #$41,(GameplayControlFlags).w   ; 'A'
                addq.w  #2,(StageStateOffset).w
                move.b  #2,(VDPReg11Shadow+1).w
                move.b  #1,(PlaneAScrollModeFlags).w
                move.b  #4,(PlaneBScrollModeFlags).w
; Wait until the Xi-Tiger entrance object leaves the primary object slot
Stage9_WaitForXiTigerEntranceObject:                    ; was: loc_D49E
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage9_UpdateCaterpillarCameraAndScroll
                addq.w  #2,(StageStateOffset).w
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                move.b  #1,(AlternateTimeBonusSound).w
                move.w  #$1C0,(StageEventTimer).w
Stage9_UpdateCaterpillarCameraAndScroll:                ; was: loc_D4BA
                                        ; Stage9_UpdateXiTigerEntranceDelay+3A   j
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage9_UpdateXiTigerEntranceDelay
; Oscillate the vertical camera offset and write the Stage 9 raster rows
Stage9_UpdateCaterpillarOscillationAndRasterRows:       ; was: sub_D4BE
                                        ; Stage9_UpdateCaterpillarShipExit+12   p
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                move.l  #Stage9_FlyCorridorLightningPaletteEntryLists,(PaletteEntryLists).w
                bsr.w   Midgame_UpdateRandomLightningEffect
                tst.w   (MidgameVerticalPhase).w
                bmi.s   Stage9_CheckCaterpillarVerticalBounce
                bne.s   Stage9_RaiseCaterpillarVerticalOffset
                subi.l  #$1000,(PrimaryCameraYPosition).w
                bpl.s   Stage9_CheckCaterpillarVerticalBounce
                addq.w  #1,(MidgameVerticalPhase).w
                bra.s   Stage9_CheckCaterpillarVerticalBounce
; ---------------------------------------------------------------------------
Stage9_RaiseCaterpillarVerticalOffset:                  ; was: loc_D4E6
                addi.l  #$1000,(PrimaryCameraYPosition).w
                cmpi.w  #$10,(PrimaryCameraYPosition).w
                bmi.s   Stage9_CheckCaterpillarVerticalBounce
                clr.w   (MidgameVerticalPhase).w
Stage9_CheckCaterpillarVerticalBounce:                  ; was: loc_D4FA
                                        ; Stage9_UpdateCaterpillarOscillationAndRasterRows+20   j
                tst.w   (MidgameVerticalPhase).w
                bpl.s   Stage9_WriteVerticalRasterOffsets
                move.l  (StageCameraYVelocity).w,d0
                bpl.s   Stage9_AccelerateCaterpillarVerticalBounce
                cmpi.l  #$FFFF8000,d0
                bmi.s   Stage9_ApplyCaterpillarVerticalBounce
Stage9_AccelerateCaterpillarVerticalBounce:             ; was: loc_D50E
                subi.l  #$800,d0
Stage9_ApplyCaterpillarVerticalBounce:                  ; was: loc_D514
                move.l  d0,(StageCameraYVelocity).w
                add.l   d0,(PrimaryCameraYPosition).w
                bpl.s   Stage9_ClampCaterpillarVerticalOffset
                clr.l   (StageCameraYVelocity).w
                clr.l   (PrimaryCameraYPosition).w
                clr.w   (MidgameVerticalPhase).w
Stage9_ClampCaterpillarVerticalOffset:                  ; was: loc_D52A
                cmpi.w  #$18,(PrimaryCameraYPosition).w
                bmi.s   Stage9_WriteVerticalRasterOffsets
                move.w  #$18,(PrimaryCameraYPosition).w
; End of function Stage9_UpdateCaterpillarOscillationAndRasterRows
; Write either sparse or dense Stage 9 vertical raster offsets
Stage9_WriteVerticalRasterOffsets:                      ; was: sub_D538
                                        ; Stage9_UpdateCaterpillarOscillationAndRasterRows+40   j
                movea.w #(HScrollPlaneARow32-M68K_RAM),a0
                addi.l  #$8000,(Stage9RasterScrollPhase).w
                move.l  (SecondaryCameraXPos).w,d0
                add.l   (Stage9RasterScrollPhase).w,d0
                swap    d0
                neg.w   d0
                cmpi.b  #3,(VDPReg11Shadow+1).w
                beq.s   Stage9_WriteDenseForegroundRasterOffsets
                moveq   #$20,d1                         ; ' '
                moveq   #$12,d7
Stage9_WriteSparseForegroundRasterOffsets:              ; was: loc_D55C
                move.w  d0,(a0)
                adda.w  d1,a0
                dbf     d7,Stage9_WriteSparseForegroundRasterOffsets
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
                moveq   #4,d7
Stage9_WriteSparseCameraRasterOffsets:                  ; was: loc_D56C
                move.w  d0,(a0)
                adda.w  d1,a0
                dbf     d7,Stage9_WriteSparseCameraRasterOffsets
                rts
; ---------------------------------------------------------------------------
Stage9_WriteDenseForegroundRasterOffsets:               ; was: loc_D576
                move.w  #$97,d7
Stage9_WriteDenseForegroundRasterOffsets_Loop:          ; was: loc_D57A
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Stage9_WriteDenseForegroundRasterOffsets_Loop
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
                moveq   #$27,d7                         ; '''
Stage9_WriteDenseCameraRasterOffsets:                   ; was: loc_D58A
                move.w  d0,(a0)
                addq.w  #4,a0
                dbf     d7,Stage9_WriteDenseCameraRasterOffsets
                rts
; End of function Stage9_WriteVerticalRasterOffsets
; Wait for the post-Xi-Tiger delay and start the interstage message sequence
Stage9_UpdatePostXiTigerTransition:                     ; was: sub_D594
                bsr.w   Stage9_UpdateCaterpillarCameraAndScroll
                subq.w  #1,(StageEventTimer).w
                bpl.s   Stage9_UpdatePostXiTigerTransition_Return
                tst.w   (GameplayExitMode).w
                bne.s   Stage9_UpdatePostXiTigerTransition_Return
                move.b  #$86,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                tst.w   (MessageSequenceState).w
                beq.w   Stage_StartInterstageTransition
Stage9_UpdatePostXiTigerTransition_Return:              ; was: locret_D5BA
                                        ; Stage9_UpdatePostXiTigerTransition+E   j
                rts
; End of function Stage9_UpdatePostXiTigerTransition
; Initializes projectile spawn position for Terobuster intro
