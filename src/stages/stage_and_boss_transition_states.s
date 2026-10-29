; Dispatches the current stage-transition state
Stage_DispatchTransitionState:                          ; was: sub_F0F0
                movea.w Stage_TransitionStateOffsets(pc,d0.w),a0
                adda.l  #StageTransition_InitializeAsteroidField,a0
                jmp     (a0)
; End of function Stage_DispatchTransitionState
; ---------------------------------------------------------------------------
Stage_TransitionStateOffsets:   dc.w    StageTransition_InitializeAsteroidField-StageTransition_InitializeAsteroidField  ; was: off_F0FC
                dc.w    StageTransition_UpdateAsteroidFieldEntry-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_StartAsteroidFieldScroll-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_FinishAsteroidFieldScroll-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_LoadDestroyerProtoAssets-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_InitializeDestroyerProtoBackdrop-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateDestroyerProtoBackdropFade-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdatePostDestroyerProtoScroll-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForShieldViperEntry-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_LoadShieldViperAssets-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateShieldViperBackdrop-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_BeginShieldViperFade-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_CompleteShieldViperFade-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForShieldViperVramTransfer-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForShieldViperExit-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateWolfGaropaApproach-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateWolfGaropaBackdropApproach-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_RenderWolfGaropaBackdrop-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_FinalizeWolfGaropaBackdrop-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_AdvanceAfterWolfGaropaBackdrop-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_LoadWolfGaropaAssets-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForWolfGaropaObjectClear-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_RestartDestroyerProtoBackdrop-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_RestartWolfGaropaBackdropFinalize-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForWolfGaropaTransitionTrigger-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateWolfGaropaScroll-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_InitializeMissirayEntryScene-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateMissirayEntryDelay-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_LoadMissirayAssets-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForMissirayObjectClear-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForMissirayExitSignals-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_InitializeStage24SceneObjects-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_AccelerateStage24VerticalScroll-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateStage24VerticalOffset-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForStage24CompletionSignals-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_AdvanceStateFromObject-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_StateAdvanceReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_InitializeZLeoApproach-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateZLeoApproach-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_LoadZLeoAssets-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_WaitForZLeoObjectClear-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateZLeoCamera-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_StartXiTigerCredits-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_UpdateStandardScroll-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField
                dc.w    StageTransition_SharedReturn-StageTransition_InitializeAsteroidField

; Transition graphics handler
StageTransition_InitializeAsteroidField:                ; was: sub_F19A
                                        ; ROM:Stage_TransitionStateOffsets   o
                addq.w  #2,(StageStateOffset).w
                move.b  #$80,(SceneSequenceFlags).w
                clr.l   (AsteroidFieldPosition).w
                clr.w   (AsteroidBoundaryPhase).w
                clr.b   (AsteroidBoundaryFlag).w
                move.l  #$10000,(AsteroidVScrollSpeed).w
                move.l  #$10000,(AsteroidFieldVelocity).w
                move.l  #$7000,(BackdropVelocityB).w
                move.l  #$C000,(BackdropVelocityA).w
                move.b  #3,(VDPReg11Shadow+1).w
                move.b  #1,(PlaneAScrollModeFlags).w
                move.b  #1,(PlaneBScrollModeFlags).w
                move.w  #$3AC,(Entity_ObjectPool).w
                clr.w   (PrimaryEntityState).w
; Handles graphics transition with scroll updates
StageTransition_UpdateAsteroidFieldEntry:               ; was: loc_F1EC
                bsr.w   StageTransition_FillAsteroidFieldVScroll
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll
                subi.l  #$100,(AsteroidVScrollSpeed).w
                subi.l  #$80,(AsteroidFieldVelocity).w
                cmpi.w  #$FFFC,(AsteroidFieldVelocity).w
                bpl.w   StageTransition_UpdateAsteroidFieldScroll
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                rts
; End of function StageTransition_InitializeAsteroidField
; Transition to asteroids
StageTransition_StartAsteroidFieldScroll:               ; was: sub_F218
                bsr.w   StageTransition_FillAsteroidFieldVScroll
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll
                tst.b   (AsteroidBoundaryFlag).w
                beq.w   StageTransition_UpdateAsteroidFieldScroll
                addq.w  #2,(StageStateOffset).w
                move.b  #$40,(SceneSequenceFlags).w     ; '@'
                andi.w  #$FF,(PrimaryCameraYPosition).w
                addi.w  #-$900,(PrimaryCameraYPosition).w
                bra.w   StageTransition_RenderAsteroidField
; End of function StageTransition_StartAsteroidFieldScroll
; Asteroids scroll handler
StageTransition_FinishAsteroidFieldScroll:              ; was: sub_F242
                bsr.w   StageTransition_FillAsteroidFieldVScroll
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll
                cmpi.w  #$F600,(PrimaryCameraYPosition).w
                bpl.w   StageTransition_RenderAsteroidField
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.b  #$80,(SceneSequenceFlags).w
                move.w  #$80,(StageSceneDelayTimer).w
                jmp     Stage_TransitionToNextPhase
; End of function StageTransition_FinishAsteroidFieldScroll
; Transition to boss
StageTransition_LoadDestroyerProtoAssets:               ; was: sub_F26C
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll
                subq.w  #1,(StageSceneDelayTimer).w
                bpl.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                lea     (Boss_DestroyerProtoAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function StageTransition_LoadDestroyerProtoAssets
; Initializes the Destroyer Proto transition backdrop
StageTransition_InitializeDestroyerProtoBackdrop:       ; was: sub_F288
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll
                tst.w   (Entity_ObjectPool).w
                bne.w   StageTransition_SharedReturn
                move.w  #$1C,(BossBackdropFadeLevel).w
                bsr.w   StageTransition_UpdateBossBackdropPaletteFade
                jsr     (Stage_StartPostBannerDelayAndPreloadNextPhase).l
                lea     (DestroyerProtoIntroPaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
StageTransition_ConfigureDestroyerProtoBackdrop:        ; was: loc_F2B0
                clr.b   (SceneSequenceFlags).w
                move.w  #$50,(RasterEffectIndex).w      ; 'P'
                clr.w   (RasterEffectInitState).w
                move.w  #$16,(RasterLayoutOffset).w
                move.w  #$60,(BackdropBandOffset).w     ; '`'
                move.l  #$4000,(BackdropVelocityB).w
                move.l  #$8000,(BackdropVelocityA).w
                move.l  #$2000000,(BackdropPositionA).w
                move.l  #$1E80000,(BackdropCameraYPos).w
                move.l  #Gfx_DefaultVRAMTransferParameters,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$F500,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                rts
; End of function StageTransition_InitializeDestroyerProtoBackdrop
; Restarts the Destroyer Proto transition backdrop
StageTransition_RestartDestroyerProtoBackdrop:          ; was: sub_F304
                move.w  #$C,(StageStateOffset).w
                clr.w   (MessageSequenceState).w
                clr.w   (BossBackdropFadeLevel).w
                move.b  #3,(VDPReg11Shadow+1).w
                bra.w   StageTransition_ConfigureDestroyerProtoBackdrop
; End of function StageTransition_RestartDestroyerProtoBackdrop
; Updates the Destroyer Proto backdrop fade
StageTransition_UpdateDestroyerProtoBackdropFade:       ; was: sub_F31C
                move.l  #$2000000,(BackdropPositionA).w
                bsr.w   StageTransition_UpdateBossBackdropPaletteFade
                bsr.w   StageTransition_ApplySegmentedBackdropMotion
                bsr.w   StageTransition_BuildBossBackdropRasterBuffers
                tst.w   (TilemapRowCountdown).w
                bmi.s   StageTransition_CompleteDestroyerProtoBackdropFade
                jsr     (Tilemap_QueueNextScrollingRow).l
                bra.s   StageTransition_DestroyerProtoBackdropFadeReturn
; ---------------------------------------------------------------------------
StageTransition_CompleteDestroyerProtoBackdropFade:     ; was: loc_F33E
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                clr.w   (StatusDisplayModeOffset).w
                clr.b   (StageRouteFlags).w
StageTransition_DestroyerProtoBackdropFadeReturn:       ; was: locret_F34E
                rts
; End of function StageTransition_UpdateDestroyerProtoBackdropFade
; Updates the post-Destroyer Proto scroll transition
StageTransition_UpdatePostDestroyerProtoScroll:         ; was: sub_F350
                bsr.w   StageTransition_UpdateBossBackdropPaletteFade
                bsr.w   StageTransition_ApplySegmentedBackdropMotion
                bsr.w   StageTransition_BuildBossBackdropRasterBuffers
                move.w  (BackdropPositionA).w,d0
                addi.w  #$60,d0                         ; '`'
                move.w  d0,(BackdropRasterSpan).w
                tst.b   (SceneSequenceFlags).w
                bne.s   StageTransition_AdvancePostDestroyerProtoScroll
                moveq   #0,d7
                cmpi.l  #$FFFF8000,(BackdropVelocityB).w
                beq.s   StageTransition_CheckPostDestroyerProtoSecondarySpeed
                subi.l  #$80,(BackdropVelocityB).w
                addq.w  #1,d7
StageTransition_CheckPostDestroyerProtoSecondarySpeed:  ; was: loc_F384
                cmpi.l  #$FFFF8000,(BackdropVelocityA).w
                beq.s   StageTransition_CheckPostDestroyerProtoSpeedsComplete
                subi.l  #$80,(BackdropVelocityA).w
                addq.w  #1,d7
StageTransition_CheckPostDestroyerProtoSpeedsComplete:  ; was: loc_F398
                tst.w   d7
                bne.s   StageTransition_PostDestroyerProtoScrollReturn
                move.b  #1,(SceneSequenceFlags).w
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                move.w  #$2A,(StageTableIndex).w        ; '*'
                move.w  #$166,(BackdropLinePhase).w
                move.l  #$2000000,(BackdropPositionA).w
                move.w  #$3C8,(Entity57Type).w
StageTransition_AdvancePostDestroyerProtoScroll:        ; was: loc_F3C2
                addi.l  #$10,(BackdropVelocityA).w
                tst.w   (BackdropPositionA).w
                bne.s   StageTransition_PostDestroyerProtoScrollReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (BackdropVelocityA).w
                move.w  #$E0,(PrimaryCameraYPosition).w
StageTransition_PostDestroyerProtoScrollReturn:         ; was: locret_F3DE
                                        ; StageTransition_UpdatePostDestroyerProtoScroll+7E   j
                rts
; End of function StageTransition_UpdatePostDestroyerProtoScroll
; Transition to boss
StageTransition_WaitForShieldViperEntry:                ; was: sub_F3E0
                bsr.w   StageTransition_ApplySegmentedBackdropMotion
                bsr.w   StageTransition_BuildBossBackdropRasterBuffers
                cmpi.w  #$FF80,(BackdropLinePhase).w
                bpl.s   StageTransition_ShieldViperEntryWaitReturn
                addq.w  #2,(StageStateOffset).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                clr.w   (RasterLayoutOffset).w
StageTransition_ShieldViperEntryWaitReturn:             ; was: locret_F400
                rts
; End of function StageTransition_WaitForShieldViperEntry
; Loads the Shield Viper encounter assets
StageTransition_LoadShieldViperAssets:                  ; was: sub_F402
                bsr.w   StageTransition_ApplySegmentedBackdropMotion
                bsr.w   StageTransition_UpdateShieldViperVScroll
                move.b  #0,(SceneSequenceFlags).w
                jsr     (Stage_TransitionToNextPhase).l
                lea     (Boss_ShieldViperAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
                clr.w   (ShieldViperRowVRAMPos).w
                clr.w   (ShieldViperRowIndex).w
                rts
; End of function StageTransition_LoadShieldViperAssets
; Builds the Shield Viper transition backdrop
StageTransition_UpdateShieldViperBackdrop:              ; was: sub_F42C
                bsr.w   StageTransition_ApplySegmentedBackdropMotion
                bsr.w   StageTransition_UpdateShieldViperVScroll
                bsr.w   StageTransition_QueueShieldViperBackdropRow
                cmpi.w  #$C,(ShieldViperRowIndex).w
                bmi.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                rts
; End of function StageTransition_UpdateShieldViperBackdrop
; Begins the Shield Viper transition fade
StageTransition_BeginShieldViperFade:                   ; was: sub_F448
                bsr.w   StageTransition_ApplySegmentedBackdropMotion
                bsr.w   StageTransition_UpdateShieldViperVScroll
                tst.w   (Entity_ObjectPool).w
                bne.w   StageTransition_SharedReturn
                move.b  #1,(SoundFadeOutDelay).w
                addq.w  #2,(StageStateOffset).w
                move.l  #Gfx_DefaultVRAMTransferParameters,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$F100,(TilemapRowYPosition).w
                move.w  #$10,(TilemapRowCountdown).w
                move.w  #$E,(BossBackdropFadeLevel).w
                bra.w   StageTransition_ApplyBossBackdropPaletteFade
; End of function StageTransition_BeginShieldViperFade
; Completes the Shield Viper transition fade
StageTransition_CompleteShieldViperFade:                ; was: sub_F484
                bsr.w   StageTransition_ApplyBossBackdropPaletteFade
                jsr     (Tilemap_QueueNextScrollingRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$20,(StageTransitionTimer).w   ; ' '
                move.l  #Gfx_ScrollVRAMTransferParameters,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$F400,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.b  #4,(PlaneBScrollModeFlags).w
                move.w  #$A000,d0
                bra.w   Gfx_AdjustTransitionTileIndexRows
; End of function StageTransition_CompleteShieldViperFade
; Waits for the Shield Viper transition VRAM transfer
StageTransition_WaitForShieldViperVramTransfer:         ; was: sub_F4C6
                bsr.w   StageTransition_ApplyBossBackdropPaletteFade
                subq.w  #1,(StageTransitionTimer).w
                bmi.s   StageTransition_UpdateShieldViperVramTransfer
                rts
; ---------------------------------------------------------------------------
StageTransition_UpdateShieldViperVramTransfer:          ; was: loc_F4D2
                cmpi.w  #$1B,(TilemapRowCountdown).w
                bmi.s   StageTransition_CompleteShieldViperVramTransfer
                jmp     Tilemap_QueueNextScrollingRow
; End of function StageTransition_WaitForShieldViperVramTransfer
; Completes the Shield Viper transition VRAM transfer
StageTransition_CompleteShieldViperVramTransfer:        ; was: sub_F4E0
                move.w  #$6000,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                jsr     (Tilemap_QueueNextConstantRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.w   StageTransition_SharedReturn
                move.w  #$50,(RasterEffectIndex).w      ; 'P'
                clr.w   (RasterEffectInitState).w
                move.w  #$16,(RasterLayoutOffset).w
                clr.l   (BackdropLinePosition).w
                move.l  #$600000,(BackdropRasterSpan).w
                clr.l   (BackdropPositionA).w
                clr.w   (SecondaryCameraXPos).w
                move.w  #$F4E2,(SecondaryCameraYPos).w
                jmp     Stage_StartTimeBonusAndPreloadNextPhase
; End of function StageTransition_CompleteShieldViperVramTransfer
; Waits for the Shield Viper exit conditions
StageTransition_WaitForShieldViperExit:                 ; was: sub_F528
                bsr.w   StageTransition_ApplyBossBackdropPaletteFade
                bsr.w   StageTransition_BuildBossBackdropRasterBuffers
                tst.w   (BossBackdropFadeLevel).w
                bmi.s   StageTransition_CheckShieldViperMessageComplete
                beq.s   StageTransition_CheckShieldViperMessageComplete
                subq.w  #1,(BossBackdropFadeLevel).w
                rts
; ---------------------------------------------------------------------------
StageTransition_CheckShieldViperMessageComplete:        ; was: loc_F53E
                                        ; StageTransition_WaitForShieldViperExit+E   j
                tst.w   (MessageSequenceState).w
                bne.s   StageTransition_ShieldViperExitWaitReturn
                move.b  #$89,d0
                jsr     (Sound_QueueBGMOrStop).l
                addq.w  #2,(StageStateOffset).w
                addq.w  #2,(StageTableIndex).w
                move.l  #$10000,(WolfGaropaBackdropYVel).w
StageTransition_ShieldViperExitWaitReturn:              ; was: locret_F55E
                rts
; End of function StageTransition_WaitForShieldViperExit
; Transition to boss
StageTransition_UpdateWolfGaropaApproach:               ; was: sub_F560
                bsr.w   StageTransition_UpdateWolfGaropaBackdropCoordinates
                bsr.w   StageTransition_BuildBossBackdropRasterBuffers
                subi.l  #$8000,(BackdropPositionA).w
                subi.l  #$8000,(BackdropRasterSpan).w
                bpl.s   StageTransition_WolfGaropaApproachReturn
                addq.w  #2,(StageStateOffset).w
                clr.w   (SecondaryCameraYPos+2).w
                move.w  #$12,(PalettePrimaryIndex).w
                bsr.w   StageTransition_InitializeWolfGaropaArenaBoundaries
StageTransition_WolfGaropaApproachReturn:               ; was: locret_F58C
                rts
; End of function StageTransition_UpdateWolfGaropaApproach
; Updates the Wolf Garopa backdrop approach
StageTransition_UpdateWolfGaropaBackdropApproach:       ; was: sub_F58E
                bsr.w   StageTransition_UpdateWolfGaropaBackdropCoordinates
                move.w  (SecondaryCameraYPos).w,(PrimaryCameraYPosition).w
                cmpi.w  #$F400,(SecondaryCameraYPos).w
                bpl.s   StageTransition_CheckWolfGaropaBackdropPosition
                subi.l  #$400,(WolfGaropaBackdropYVel).w
StageTransition_CheckWolfGaropaBackdropPosition:        ; was: loc_F5A8
                cmpi.w  #$F3E0,(SecondaryCameraYPos).w
                bpl.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                clr.w   (RasterLayoutOffset).w
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                move.l  #Gfx_DefaultVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #$1F,(TilemapRowCountdown).w
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$F400,(TilemapRowYPosition).w
                move.w  #$2000,d0
                bra.w   Gfx_AdjustTransitionTileIndexRows
; End of function StageTransition_UpdateWolfGaropaBackdropApproach
; Renders the Wolf Garopa transition backdrop
StageTransition_RenderWolfGaropaBackdrop:               ; was: sub_F5EE
                move.l  (WolfGaropaScrollSpeed).w,d0
                sub.l   d0,(SecondaryCameraXPos).w
                move.w  (SecondaryCameraXPos).w,(PrimaryCameraXPosition).w
                move.w  (SecondaryCameraYPos).w,(PrimaryCameraYPosition).w
                jsr     (Tilemap_QueueNextScrollingRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.s   StageTransition_WolfGaropaBackdropRenderReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #$1F,(TilemapRowCountdown).w
                clr.w   (TilemapRowXOrFillWord).w
StageTransition_WolfGaropaBackdropRenderReturn:         ; was: locret_F622
                rts
; End of function StageTransition_RenderWolfGaropaBackdrop
; Finalizes the Wolf Garopa transition backdrop
StageTransition_FinalizeWolfGaropaBackdrop:             ; was: sub_F624
                bsr.w   StageTransition_UpdateWolfGaropaHorizontalScroll
                move.w  (PrimaryCameraXPosition).w,(SecondaryCameraXPos).w
                move.w  (PrimaryCameraYPosition).w,(SecondaryCameraYPos).w
                jsr     (Tilemap_QueueNextConstantRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.s   StageTransition_WolfGaropaBackdropFinalizeReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                clr.b   (StageRouteFlags).w
                move.w  #$494,(Entity57Type).w
                clr.w   (Entity57State).w
                clr.w   (Entity57Flags).w
                clr.b   (Entity57Status).w
StageTransition_WolfGaropaBackdropFinalizeReturn:       ; was: locret_F660
                rts
; End of function StageTransition_FinalizeWolfGaropaBackdrop
; Restarts Wolf Garopa backdrop finalization
StageTransition_RestartWolfGaropaBackdropFinalize:      ; was: sub_F662
                move.w  #$24,(StageStateOffset).w       ; '$'
                move.l  #$FFF88000,(WolfGaropaScrollSpeed).w
                bsr.w   StageTransition_InitializeWolfGaropaArenaBoundaries
                bset    #0,(StageRouteFlags).w
                rts
; End of function StageTransition_RestartWolfGaropaBackdropFinalize
; Advances after the Wolf Garopa backdrop
StageTransition_AdvanceAfterWolfGaropaBackdrop:         ; was: sub_F67C
                bsr.w   StageTransition_UpdateWolfGaropaHorizontalScroll
                jmp     Stage_TransitionToNextPhase
; End of function StageTransition_AdvanceAfterWolfGaropaBackdrop
; Loads the Wolf Garopa encounter assets
StageTransition_LoadWolfGaropaAssets:                   ; was: sub_F686
                bsr.w   StageTransition_DecelerateWolfGaropaScroll
                tst.w   (MessageSequenceState).w
                bne.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                clr.b   (WolfGaropaEffectActive).w
                lea     (Boss_WolfGaropaAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function StageTransition_LoadWolfGaropaAssets
; Waits for the Wolf Garopa object slots to clear
StageTransition_WaitForWolfGaropaObjectClear:           ; was: sub_F6A6
                bsr.w   StageTransition_UpdateWolfGaropaHorizontalScroll
                tst.w   (Entity_ObjectPool).w
                bne.s   StageTransition_WolfGaropaObjectClearWaitReturn
                move.w  #$30,(StageStateOffset).w       ; '0'
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                move.w  #$80,(StageTransitionTimer).w
StageTransition_WolfGaropaObjectClearWaitReturn:        ; was: locret_F6C2
                rts
; End of function StageTransition_WaitForWolfGaropaObjectClear
; Waits for the Wolf Garopa transition trigger
StageTransition_WaitForWolfGaropaTransitionTrigger:     ; was: sub_F6C4
                bsr.w   StageTransition_UpdateWolfGaropaHorizontalScroll
                tst.w   (MessageSequenceState).w
                bne.s   StageTransition_WolfGaropaTriggerWaitReturn
                subq.w  #1,(StageTransitionTimer).w
                bpl.s   StageTransition_WolfGaropaTriggerWaitReturn
                tst.w   (GameplayExitMode).w
                bne.s   StageTransition_WolfGaropaTriggerWaitReturn
                tst.w   (ScriptedInputActive).w
                bne.s   StageTransition_WolfGaropaTriggerWaitReturn
                move.b  #$8F,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; ---------------------------------------------------------------------------
StageTransition_WolfGaropaTriggerWaitReturn:            ; was: locret_F6F2
                                        ; StageTransition_WaitForWolfGaropaTransitionTrigger+E   j
                rts
; End of function StageTransition_WaitForWolfGaropaTransitionTrigger
; Updates the Wolf Garopa transition scroll
StageTransition_UpdateWolfGaropaScroll:                 ; was: sub_F6F4
                bsr.w   StageTransition_UpdateWolfGaropaHorizontalScroll
                rts
; End of function StageTransition_UpdateWolfGaropaScroll
; Decelerates the Wolf Garopa transition scroll
StageTransition_DecelerateWolfGaropaScroll:             ; was: sub_F6FA
                cmpi.l  #$FFFF0000,(StageMotionXDelta).w
                beq.s   StageTransition_UpdateWolfGaropaCameraPosition
                subi.l  #$800,(StageMotionXDelta).w
StageTransition_UpdateWolfGaropaCameraPosition:         ; was: loc_F70C
                move.l  (WolfGaropaScrollSpeed).w,d0
                cmpi.l  #$FFF60000,d0
                bmi.s   StageTransition_UpdateWolfGaropaHorizontalScroll
                beq.s   StageTransition_UpdateWolfGaropaHorizontalScroll
                subi.l  #$800,d0
                move.l  d0,(WolfGaropaScrollSpeed).w
; End of function StageTransition_DecelerateWolfGaropaScroll
; Updates the Wolf Garopa horizontal transition scroll
StageTransition_UpdateWolfGaropaHorizontalScroll:       ; was: sub_F724
                                        ; StageTransition_AdvanceAfterWolfGaropaBackdrop   p
                move.l  (WolfGaropaScrollSpeed).w,d0
                sub.l   d0,(PrimaryCameraXPosition).w
                tst.b   (WolfGaropaEffectActive).w
                beq.s   StageTransition_ClampWolfGaropaHorizontalScroll
                bmi.s   StageTransition_WolfGaropaHorizontalScrollReturn
                tst.w   (PrimaryCameraXPosition).w
                bmi.s   StageTransition_WolfGaropaHorizontalScrollReturn
                cmpi.w  #$200,(PrimaryCameraXPosition).w
                bmi.s   StageTransition_WolfGaropaHorizontalScrollReturn
                clr.b   (WolfGaropaEffectActive).w
                bsr.w   Gfx_LoadWolfGaropaTransitionTiles
StageTransition_ClampWolfGaropaHorizontalScroll:        ; was: loc_F74A
                andi.w  #$3F,(PrimaryCameraXPosition).w  ; '?'
StageTransition_WolfGaropaHorizontalScrollReturn:       ; was: locret_F750
                                        ; StageTransition_UpdateWolfGaropaHorizontalScroll+14   j
                rts
; End of function StageTransition_UpdateWolfGaropaHorizontalScroll
; Loads the Wolf Garopa transition tiles
Gfx_LoadWolfGaropaTransitionTiles:                      ; was: sub_F752
                                        ; Effect_WolfGaropaBoundaryMain+28   p
                lea     Gfx_WolfGaropaTransitionTileDmaDescriptor(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedColumns).l
                lea     Gfx_WolfGaropaTransitionIndexedRowDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_LoadWolfGaropaTransitionTiles
; ---------------------------------------------------------------------------
Gfx_WolfGaropaTransitionTileDmaDescriptor:  dc.b    $44, $58, $40, 0, 1, 3, $1F  ; was: byte_F76A
                dc.b    $1E, $21, $20, $23, $22, $25, $24
Gfx_WolfGaropaTransitionIndexedRowDescriptor:   dc.b    $4C, $50, $40, 0, 4, 1, $26, $27  ; was: byte_F778
                dc.b    $26, $27, $26, $28, $29, $28, $29, $28

; Updates the Wolf Garopa transition backdrop coordinates
StageTransition_UpdateWolfGaropaBackdropCoordinates:    ; was: sub_F788
                                        ; StageTransition_UpdateWolfGaropaBackdropApproach   p
                move.l  (WolfGaropaBackdropYVel).w,d0
                sub.l   d0,(SecondaryCameraYPos).w
                move.l  (WolfGaropaScrollSpeed).w,d0
                sub.l   d0,(SecondaryCameraXPos).w
                moveq   #0,d0
                move.w  (SecondaryCameraYPos).w,d1
                subi.w  #$F8,d1
                lea     (Gfx_ScrollVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function StageTransition_UpdateWolfGaropaBackdropCoordinates
; Adjusts tile indices in the stage-transition rows
Gfx_AdjustTransitionTileIndexRows:                      ; was: sub_F7AC
                                        ; StageTransition_UpdateWolfGaropaBackdropApproach+5C   j
                movea.l #(LargeTilemapBuffer+$300),a0
                moveq   #$30,d7                         ; '0'
                jmp     Gfx_AdjustTileIndexRows
; End of function Gfx_AdjustTransitionTileIndexRows
; Unreferenced transition-scroll initializer
UnreferencedInitializeTransitionScroll:
                addq.w  #2,(StageStateOffset).w         ; was: sub_F7BA
                move.b  #$40,(SceneSequenceFlags).w     ; '@'
                move.w  #$FFFE,(AsteroidFieldVelocity).w
                clr.b   (VDPReg11Shadow+1).w
                rts
; End of function UnreferencedInitializeTransitionScroll
; Unreferenced asteroid-scroll target updater
UnreferencedUpdateAsteroidScrollToTarget:
                bsr.w   StageTransition_UpdateSegmentedBackdropScroll  ; was: sub_F7D0
                bsr.w   StageTransition_RenderAsteroidField
                cmpi.w  #$F3E0,(PrimaryCameraYPosition).w
                bpl.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                move.b  #0,(SceneSequenceFlags).w
                move.w  #$F3E0,(PrimaryCameraYPosition).w
                clr.l   (AsteroidFieldVelocity).w
                rts
; End of function UnreferencedUpdateAsteroidScrollToTarget
UnreferencedEmptyTransitionHandler:
                ; was: nullsub_29
                rts
; End of function UnreferencedEmptyTransitionHandler
