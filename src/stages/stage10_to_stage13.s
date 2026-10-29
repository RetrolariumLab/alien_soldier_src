; Dispatch the shared midgame state selected by the configuration-seeded offset
Stage_DispatchMidgameState:                             ; DATA XREF: ROM:0000FF3A   o  ; was: sub_D90E
                cmpi.w  #$40,(StageStateOffset).w       ; '@'
                bpl.s   Stage_DispatchMidgameState_Handler
                btst    #0,(FrameCounter+1).w
                bne.s   Stage_DispatchMidgameState_Handler
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                movea.w a0,a1
                move.w  #$148,(a1)+
                move.w  #$300,(a1)+
                move.w  #0,(a1)+
                move.w  #1,(a1)+
                move.w  #$148,(a1)+
                move.w  #$300,(a1)+
                move.w  #0,(a1)+
                clr.w   (a1)+
                move.w  #$FFFF,(a1)
                jsr     (Sprite_AppendOAMEntries).l
; Dispatch the selected state after the early-state diagnostic OAM marker
Stage_DispatchMidgameState_Handler:                     ; CODE XREF: Stage_DispatchMidgameState+6   j  ; was: loc_D94C
                                        ; Stage_DispatchMidgameState+E   j
                move.w  (StageStateOffset).w,d0
                movea.w Stage_MidgameStateHandlerOffsets(pc,d0.w),a0
                adda.l  #Stage10_Initialize,a0
                jmp     (a0)
; End of function Stage_DispatchMidgameState
; ---------------------------------------------------------------------------
Stage_MidgameStateHandlerOffsets:
                dc.w    Stage10_Initialize-Stage10_Initialize  ; was: off_D95C
                dc.w    Stage10_UpdateScrollToDeepStrider-Stage10_Initialize
                dc.w    Stage10_InitializeDeepStriderEncounter-Stage10_Initialize
                dc.w    Stage10_UpdateDeepStriderEncounter-Stage10_Initialize
                dc.w    Stage10_StartPostDeepStriderTransition-Stage10_Initialize
                dc.w    Stage11_Initialize-Stage10_Initialize
                dc.w    Stage11_UpdateScrollToGusthead-Stage10_Initialize
                dc.w    Stage11_InitializeGustheadEncounter-Stage10_Initialize
                dc.w    Stage11_UpdatePostGusthead-Stage10_Initialize
                dc.w    Stage11_StartPostGustheadTransition-Stage10_Initialize
                dc.w    Stage12_InitializeScroll-Stage10_Initialize
                dc.w    Stage12_UpdateScrollToExit-Stage10_Initialize
                dc.w    Stage12_UpdateScrollToExitTiles-Stage10_Initialize
                dc.w    Stage12_UpdateScrollToSharpsteel-Stage10_Initialize
                dc.w    Stage12_InitializeSharpsteelArena-Stage10_Initialize
                dc.w    Stage12_EmptyState1E-Stage10_Initialize
                dc.w    Stage12_InitializeSharpsteelEncounter-Stage10_Initialize
                dc.w    Stage12_UpdatePostSharpsteel-Stage10_Initialize
                dc.w    Stage12_StartTeleportTransitionToStage13-Stage10_Initialize
                dc.w    Stage12To13_UpdateTeleportFadeIn-Stage10_Initialize
                dc.w    Stage12To13_UpdateTeleportFadeOut-Stage10_Initialize
                dc.w    Stage12To13_AdvanceTeleportScroll-Stage10_Initialize
                dc.w    Stage13_UpdateSnakeIntroTransition-Stage10_Initialize
                dc.w    Stage_MidgameStateReturn-Stage10_Initialize
                dc.w    Stage_MidgameStateReturn-Stage10_Initialize
                dc.w    Stage_MidgameStateReturn-Stage10_Initialize
                dc.w    Stage13_InitializeSnakeEncounter-Stage10_Initialize
                dc.w    Stage13_UpdateSnakeEncounterTransition-Stage10_Initialize
                dc.w    Stage13_InitializeBugmaxApproach-Stage10_Initialize
                dc.w    Stage13_UpdateBugmaxApproach-Stage10_Initialize
                dc.w    Stage13_UpdateBugmaxEncounter-Stage10_Initialize
                dc.w    Stage13_StartPostBugmaxTransition-Stage10_Initialize
                dc.w    Stage14_InitializeVictorApproach-Stage10_Initialize
                dc.w    Stage14_UpdateScrollToVictor-Stage10_Initialize
                dc.w    Stage14_InitializeVictorEncounter-Stage10_Initialize
                dc.w    Stage14_UpdateVictorEncounter-Stage10_Initialize
                dc.w    Stage14_StartPostVictorTransition-Stage10_Initialize
                dc.w    Stage15_UpdateScrollToSunsetSting-Stage10_Initialize
                dc.w    Stage15_UpdateSunsetStingApproach-Stage10_Initialize
                dc.w    Stage15_InitializeSunsetStingEncounter-Stage10_Initialize
                dc.w    Stage15_UpdateSunsetStingEncounter-Stage10_Initialize
                dc.w    Stage15_StartPostSunsetStingTransition-Stage10_Initialize
                dc.w    Stage16_UpdateScrollToViblack-Stage10_Initialize
                dc.w    Stage16_CreateViblackEncounter-Stage10_Initialize
                dc.w    Stage16_UpdateViblackEncounterCamera-Stage10_Initialize
                dc.w    Stage16_StartPostViblackTransition-Stage10_Initialize
                dc.w    Stage16_ContinuePostViblackVerticalScroll-Stage10_Initialize
                dc.w    Stage16_UpdatePostViblackCameraAndPalette-Stage10_Initialize
                dc.w    Stage16_InitializePostViblackTilemapStreaming-Stage10_Initialize
                dc.w    Stage16_UpdatePostViblackTilemapStreaming-Stage10_Initialize
                dc.w    Stage16_HoldPostViblackVerticalOffset-Stage10_Initialize
                dc.w    Stage16_UpdatePostViblackPaletteTransition-Stage10_Initialize
                dc.w    Stage16_DeceleratePostViblackVerticalScroll-Stage10_Initialize
                dc.w    Stage17_InitializeEpsilon1Transition-Stage10_Initialize
                dc.w    Stage17_UpdatePreEpsilon1Transition-Stage10_Initialize
                dc.w    Stage17_UpdatePreEpsilon1Transition-Stage10_Initialize
                dc.w    Stage17_InitializeEpsilon1Encounter-Stage10_Initialize
                dc.w    Stage17_UpdateEpsilon1Encounter-Stage10_Initialize
                dc.w    Stage17_StartPlanetTransition-Stage10_Initialize

; Initialize Stage 10's message, raster effect, and ambient particles
Stage10_Initialize:                                     ; DATA XREF: Stage_DispatchMidgameState+46   o  ; was: sub_D9D2
                                        ; ROM:Stage_MidgameStateHandlerOffsets   o
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                bsr.w   Midgame_InitializeRasterAndAmbientEffects
; End of function Stage10_Initialize
; Scroll Stage 10 to the Deep Strider approach boundary
Stage10_UpdateScrollToDeepStrider:                      ; DATA XREF: ROM:0000D95E   o  ; was: sub_D9DC
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                cmpi.w  #$730,(PrimaryCameraXPosition).w
                bmi.s   Stage_MidgameStateReturn
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage_MidgameStateReturn:                               ; CODE XREF: Stage10_UpdateScrollToDeepStrider+E   j  ; was: locret_D9F0
                                        ; Stage10_InitializeDeepStriderEncounter+10   j
                rts
; End of function Stage10_UpdateScrollToDeepStrider
; Clamp the arena and submit the Deep Strider asset set
Stage10_InitializeDeepStriderEncounter:                 ; DATA XREF: ROM:0000D960   o  ; was: sub_D9F2
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                move.w  #$7B0,d0
                cmp.w   (PrimaryCameraXPosition).w,d0
                bpl.s   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_DeepStriderAssetSet).l,a1
                bra.w   Boss_LoadAssetSet
; End of function Stage10_InitializeDeepStriderEncounter
; Track the Deep Strider encounter and start its post-boss bonus when cleared
Stage10_UpdateDeepStriderEncounter:                     ; DATA XREF: ROM:0000D962   o  ; was: sub_DA22
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage10_UpdateDeepStriderCameraAndScroll
                bsr.w   Stage_StartTimeBonusAndPreloadNextPhase
Stage10_UpdateDeepStriderCameraAndScroll:               ; CODE XREF: Stage10_UpdateDeepStriderEncounter+4   j  ; was: loc_DA2C
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_AccumulateQuarterHorizontalDelta
; End of function Stage10_UpdateDeepStriderEncounter
; Start the post-Deep-Strider banner while keeping camera and scroll current
Stage10_StartPostDeepStriderTransition:                 ; DATA XREF: ROM:0000D964   o  ; was: sub_DA34
                bsr.w   Stage_StartNextPhaseBanner
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_AccumulateQuarterHorizontalDelta
; End of function Stage10_StartPostDeepStriderTransition
; Initialize Stage 11's raster effect and shared ambient particles
Stage11_Initialize:                                     ; DATA XREF: ROM:0000D966   o  ; was: sub_DA40
                bsr.w   Midgame_InitializeRasterAndAmbientEffects
; End of function Stage11_Initialize
; Scroll Stage 11 to the Gusthead approach boundary
Stage11_UpdateScrollToGusthead:                         ; DATA XREF: ROM:0000D968   o  ; was: sub_DA44
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                cmpi.w  #$1040,(PrimaryCameraXPosition).w
                bmi.s   Stage11_UpdateScrollToGusthead_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage11_UpdateScrollToGusthead_Return:                  ; CODE XREF: Stage11_UpdateScrollToGusthead+E   j  ; was: locret_DA58
                rts
; End of function Stage11_UpdateScrollToGusthead
; Clamp the arena and submit the Gusthead asset set
Stage11_InitializeGustheadEncounter:                    ; DATA XREF: ROM:0000D96A   o  ; was: sub_DA5A
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                move.w  #$10C0,d0
                cmp.w   (PrimaryCameraXPosition).w,d0
                bpl.s   Stage11_InitializeGustheadEncounter_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_GustheadAssetSet).l,a1
                bsr.w   Boss_LoadAssetSet
                clr.l   (GustheadArenaVelocity).w
                clr.w   (GustheadFinalPhaseFlag).w
Stage11_InitializeGustheadEncounter_Return:             ; CODE XREF: Stage11_InitializeGustheadEncounter+10   j  ; was: locret_DA92
                rts
; End of function Stage11_InitializeGustheadEncounter
; Track Gusthead's removal and begin the post-boss bonus
Stage11_UpdatePostGusthead:                             ; DATA XREF: ROM:0000D96C   o  ; was: sub_DA94
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage11_UpdatePostGustheadScroll
                jsr     (Stage_StartTimeBonusAndPreloadNextPhase).l
Stage11_UpdatePostGustheadScroll:                       ; CODE XREF: Stage11_UpdatePostGusthead+4   j  ; was: loc_DAA0
                bra.w   Stage11_UpdateGustheadExitScroll
; End of function Stage11_UpdatePostGusthead
; Start the final Stage 11 banner while preserving its exit scrolling
Stage11_StartPostGustheadTransition:                    ; DATA XREF: ROM:0000D96E   o  ; was: sub_DAA4
                bsr.w   Stage_StartNextPhaseBanner
Stage11_UpdateGustheadExitScroll:                       ; CODE XREF: Stage11_UpdatePostGusthead:Stage11_UpdatePostGustheadScroll   j  ; was: loc_DAA8
                tst.w   (GustheadFinalPhaseFlag).w
                beq.s   Stage11_UpdateGustheadExitCamera
                bsr.w   Stage11_ApplyExitScrollVelocity
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                cmpi.w  #$14,(StageTableIndex).w
                beq.s   Stage11_UpdateGustheadExitScroll_Return
                tst.w   (GustheadFinalPhaseFlag).w
                beq.s   Stage11_UpdateGustheadExitScroll_Return
                move.w  (PrimaryCameraXPosition).w,d0
                move.w  d0,d1
                andi.w  #$FF,d0
                andi.w  #$100,d1
                addi.w  #$1000,d0
                sub.w   d1,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(PreviousCameraXPosition).w
Stage11_UpdateGustheadExitScroll_Return:                ; CODE XREF: Stage11_UpdateGustheadExitScroll+18   j  ; was: locret_DAE0
                                        ; Stage11_UpdateGustheadExitScroll+1E   j
                rts
; ---------------------------------------------------------------------------
Stage11_UpdateGustheadExitCamera:                       ; CODE XREF: Stage11_UpdateGustheadExitScroll+8   j  ; was: loc_DAE2
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_AccumulateQuarterHorizontalDelta
; End of function Stage11_StartPostGustheadTransition
; Apply the signed Stage 11 exit velocity to horizontal camera position
Stage11_ApplyExitScrollVelocity:                        ; CODE XREF: Stage11_UpdateGustheadExitScroll+A   p  ; was: sub_DAEA
                move.l  (GustheadArenaVelocity).w,d0
                add.l   d0,(PrimaryCameraXPosition).w
                rts
; End of function Stage11_ApplyExitScrollVelocity
; Initialize Stage 12 raster state and continue into its first scroll state
Stage12_InitializeScroll:                               ; DATA XREF: ROM:0000D970   o  ; was: sub_DAF4
                move.b  #$40,(PlayerOAMBucketOffset).w  ; '@'
                move.w  #$30,(RasterEffectIndex).w      ; '0'
                clr.w   (RasterEffectInitState).w
; Scroll Stage 12 to the first exit threshold at camera X $1580
Stage12_UpdateScrollToExit:                             ; DATA XREF: ROM:0000D972   o  ; was: loc_DB04
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                cmpi.w  #$1580,(PrimaryCameraXPosition).w
                bmi.w   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$80,(StageEventTimer).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                move.b  #1,(SoundFadeOutDelay).w
                rts
; End of function Stage12_InitializeScroll
; Continue Stage 12 to the tile-asset handoff at camera X $15E0
Stage12_UpdateScrollToExitTiles:                        ; DATA XREF: ROM:0000D974   o  ; was: sub_DB2E
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                bsr.w   Stage12_DecrementExitTimer
                cmpi.w  #$15E0,(PrimaryCameraXPosition).w
                bmi.w   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                jsr     (Stage_ClearSharedStateBuffer).l
                lea     Stage12_ExitTileAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage12_UpdateScrollToExitTiles
; ---------------------------------------------------------------------------
Stage12_ExitTileAssetLoadList:  dc.w    7               ; field_0  ; was: stru_DB5A
                                        ; DATA XREF: Stage12_UpdateScrollToExitTiles+20   o
                dc.l    Stage12And13TileArt0000         ; field_2
                dc.w    0                               ; field_6
                dc.w    $FFFF

; Continue Stage 12 from the tile handoff to the Sharpsteel approach
Stage12_UpdateScrollToSharpsteel:                       ; DATA XREF: ROM:0000D976   o  ; was: sub_DB64
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                bsr.w   Stage12_DecrementExitTimer
                cmpi.w  #$1760,(PrimaryCameraXPosition).w
                bmi.s   Stage12_UpdateScrollToSharpsteel_Return
                addq.w  #2,(StageStateOffset).w
Stage12_UpdateScrollToSharpsteel_Return:                ; CODE XREF: Stage12_UpdateScrollToSharpsteel+12   j  ; was: locret_DB7C
                rts
; End of function Stage12_UpdateScrollToSharpsteel
; Clamp the Stage 12 camera at the Sharpsteel arena boundary
Stage12_InitializeSharpsteelArena:                      ; DATA XREF: ROM:0000D978   o  ; was: sub_DB7E
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_AccumulateQuarterHorizontalDelta
                move.w  #$17A0,d0
                cmp.w   (PrimaryCameraXPosition).w,d0
                bpl.s   Stage12_InitializeSharpsteelArena_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  d0,(PrimaryCameraXPosition).w
Stage12_InitializeSharpsteelArena_Return:               ; CODE XREF: Stage12_InitializeSharpsteelArena+10   j  ; was: locret_DB9C
                rts
; End of function Stage12_InitializeSharpsteelArena
; Empty Stage 12 state at table offset $1E
Stage12_EmptyState1E:                                   ; DATA XREF: ROM:0000D97A   o  ; was: nullsub_24
                rts
; End of function Stage12_EmptyState1E
; Submit the Sharpsteel asset set when its external trigger clears
Stage12_InitializeSharpsteelEncounter:                  ; DATA XREF: ROM:0000D97C   o  ; was: sub_DBA0
                tst.w   (SpecialTargetCount).w
                bne.w   Stage_MidgameStateReturn
                move.w  #9,(StageSpawnCountdown).w
                bsr.w   Stage_TransitionToNextPhase
                lea     (Boss_SharpsteelAssetSet).l,a1
                bra.w   Boss_LoadAssetSet
; End of function Stage12_InitializeSharpsteelEncounter
; Track Sharpsteel's removal and begin the post-boss bonus
Stage12_UpdatePostSharpsteel:                           ; DATA XREF: ROM:0000D97E   o  ; was: sub_DBBC
                tst.w   (Entity_ObjectPool).w
                bne.w   Stage_MidgameStateReturn
                move.w  #$FFFF,(Entity57Work24).w
                bra.w   Stage_StartTimeBonusAndPreloadNextPhase
; End of function Stage12_UpdatePostSharpsteel
; Leave Stage 12 and start the teleport transition into Stage 13
Stage12_StartTeleportTransitionToStage13:               ; DATA XREF: ROM:0000D980   o  ; was: sub_DBCE
                tst.w   (MessageSequenceState).w
                bne.w   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                clr.w   (StatusDisplayModeOffset).w
                addq.w  #2,(StageTableIndex).w
                clr.b   (StageRouteFlags).w
                clr.w   (Stage12TeleportFade).w
                move.b  #$CA,d0
                jmp     (Sound_QueueSFXRequest).l
; End of function Stage12_StartTeleportTransitionToStage13
; Delay, initialize, and apply the first Stage 12-to-13 teleport fade
Stage12To13_UpdateTeleportFadeIn:                       ; DATA XREF: ROM:0000D982   o  ; was: sub_DBF4
                tst.w   (PlayerDefeatPhase).w
                beq.s   Stage12To13_AdvanceTeleportFadeDelay
                bpl.s   Stage12To13_ApplyTeleportFadeLevel
Stage12To13_AdvanceTeleportFadeDelay:                   ; CODE XREF: Stage12To13_UpdateTeleportFadeIn+4   j  ; was: loc_DBFC
                addq.w  #1,(Stage12TeleportFade).w
                cmpi.w  #$3C,(Stage12TeleportFade).w    ; '<'
                bne.s   Stage12To13_ApplyTeleportFadeLevel
                addq.w  #2,(StageStateOffset).w
                move.w  #$FCE0,(PrimaryCameraXPosition).w
                clr.w   (PrimaryCameraYPosition).w
                move.w  #$1C,(Stage12TeleportFade).w
                move.l  #$C0000,(TeleportSnakeScrollVel).w
                clr.b   (PlaneAScrollModeFlags).w
                moveq   #0,d0
                moveq   #0,d1
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                bset    #6,(CameraMotionLockFlags).w
                move.w  #$50,(PlayerStateOffset).w      ; 'P'
                clr.l   (StageMotionXDelta).w
                clr.l   (StageMotionYDelta).w
                move.w  #$4000,(TilemapTransferBase).w
                move.w  #0,(TilemapRowXOrFillWord).w
                jsr     (Tilemap_FillPlaneDirectToVRAM).l
                jsr     (Stage_LoadStage13Assets).l
Stage12To13_ApplyTeleportFadeLevel:                     ; CODE XREF: Stage12To13_UpdateTeleportFadeIn+6   j  ; was: loc_DC5E
                                        ; Stage12To13_UpdateTeleportFadeIn+12   j
                move.w  (Stage12TeleportFade).w,d0
                cmpi.w  #$1C,d0
                bmi.s   Stage12To13_ClampAndApplyTeleportFadeLevel
                moveq   #$1C,d0
Stage12To13_ClampAndApplyTeleportFadeLevel:             ; CODE XREF: Stage12To13_UpdateTeleportFadeIn+72   j  ; was: loc_DC6A
                jmp     (Gfx_ApplyFullActivePaletteFade).l
; End of function Stage12To13_UpdateTeleportFadeIn
; Decrease the teleport fade level while advancing the transition scroll
Stage12To13_UpdateTeleportFadeOut:                      ; DATA XREF: ROM:0000D984   o  ; was: sub_DC70
                move.w  (Stage12TeleportFade).w,d0
                jsr     (Gfx_ApplyFullActivePaletteFade).l
                addq.w  #6,(PrimaryCameraXPosition).w
                subq.w  #1,(Stage12TeleportFade).w
                bpl.s   Stage12To13_UpdateTeleportScroll
                addq.w  #2,(StageStateOffset).w
; Continue the teleport scroll until its signed position crosses zero
Stage12To13_AdvanceTeleportScroll:                      ; DATA XREF: ROM:0000D986   o  ; was: loc_DC88
                addq.w  #6,(PrimaryCameraXPosition).w
                bmi.s   Stage12To13_UpdateTeleportScroll
                addq.w  #2,(StageStateOffset).w
                move.w  #$60,(Stage12TeleportFade).w    ; '`'
                clr.w   (PrimaryCameraXPosition).w
                bclr    #6,(CameraMotionLockFlags).w
                move.w  #1,(PlayerStateWorkHighWord).w
Stage12To13_UpdateTeleportScroll:                       ; CODE XREF: Stage12To13_UpdateTeleportFadeOut+12   j  ; was: loc_DCA8
                                        ; Stage12To13_UpdateTeleportFadeOut+1C   j
                bsr.w   Stage12To13_UpdateTeleportAndSnakeScroll
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$158,d0
                bpl.s   Stage12To13_QueueTeleportColumn
                rts
; ---------------------------------------------------------------------------
Stage12To13_QueueTeleportColumn:                        ; CODE XREF: Stage12To13_UpdateTeleportFadeOut+44   j  ; was: loc_DCB8
                moveq   #0,d1
                jmp     Tilemap_QueuePrimaryPlaneColumn
; End of function Stage12To13_UpdateTeleportFadeOut
; Finish the Stage 13 Snake-intro scroll and enter its configured state offset
Stage13_UpdateSnakeIntroTransition:                     ; DATA XREF: ROM:0000D988   o  ; was: sub_DCC0
                subi.l  #$4000,(TeleportSnakeScrollVel).w
                bpl.s   Stage13_UpdateSnakeIntroTransition_Scroll
                clr.l   (TeleportSnakeScrollVel).w
Stage13_UpdateSnakeIntroTransition_Scroll:              ; CODE XREF: Stage13_UpdateSnakeIntroTransition+8   j  ; was: loc_DCCE
                bsr.w   Stage12To13_UpdateTeleportAndSnakeScroll
                subq.w  #1,(Stage12TeleportFade).w
                bpl.w   Stage_MidgameStateReturn
Stage13_BeginSnakeSequence:
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                move.b  #$89,d0
                jsr     (Sound_QueueBGMOrStop).l
                bra.w   Stage13_InitializeSnakeEncounter
; End of function Stage13_UpdateSnakeIntroTransition
; Update the shared teleport/Snake background and secondary scroll velocity
Stage12To13_UpdateTeleportAndSnakeScroll:               ; CODE XREF: Stage12To13_UpdateTeleportFadeOut:Stage12To13_UpdateTeleportScroll   p  ; was: sub_DCEE
                                        ; Stage13_UpdateSnakeIntroTransition:Stage13_UpdateSnakeIntroTransition_Scroll   p
                bsr.w   Scroll_UpdateSnakeBackground
                move.l  (TeleportSnakeScrollVel).w,d0
                add.l   d0,(SecondaryCameraXPos).w
                rts
; End of function Stage12To13_UpdateTeleportAndSnakeScroll
; Decrement the Stage 12 exit timer when it is active
Stage12_DecrementExitTimer:                             ; CODE XREF: Stage12_UpdateScrollToExitTiles+8   p  ; was: sub_DCFC
                                        ; Stage12_UpdateScrollToSharpsteel+8   p
                tst.w   (StageEventTimer).w
                bmi.w   Stage_MidgameStateReturn
                subq.w  #1,(StageEventTimer).w
                bne.w   Stage_MidgameStateReturn
                rts
; End of function Stage12_DecrementExitTimer
; Initialize Stage 13's Snake object, raster effect, and state offset $36
Stage13_InitializeSnakeEncounter:                       ; CODE XREF: Stage13_UpdateSnakeIntroTransition+2A   j  ; was: sub_DD0E
                                        ; DATA XREF: ROM:0000D990   o
                move.w  #$36,(StageStateOffset).w       ; '6'
                move.w  #$298,(Entity_ObjectPool).w
                clr.w   (PrimaryEntityState).w
                move.w  #$30,(RasterEffectIndex).w      ; '0'
                clr.w   (RasterEffectInitState).w
                jsr     (Stage_ClearSharedStateBuffer).l
; End of function Stage13_InitializeSnakeEncounter
; Advance the Snake encounter to the next state while preserving its health
Stage13_UpdateSnakeEncounterTransition:                 ; DATA XREF: ROM:0000D992   o  ; was: sub_DD2E
                bsr.w   Scroll_UpdateSnakeBackground
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                cmpi.w  #$3E0,(PrimaryCameraXPosition).w
                bmi.w   Stage_MidgameStateReturn
                move.w  (BossHealth).w,(BossHealthPairScratch).w
                move.w  (BossMaxHealth).w,(BossHealthPairScratch+2).w
                bsr.w   Stage_TransitionToNextPhase
                move.w  (BossHealthPairScratch).w,(BossHealth).w
                move.w  (BossHealthPairScratch+2).w,(BossMaxHealth).w
                rts
; End of function Stage13_UpdateSnakeEncounterTransition
; Clamp the Stage 13 camera and prepare the Bugmax approach rows and timer
Stage13_InitializeBugmaxApproach:                       ; DATA XREF: ROM:0000D994   o  ; was: sub_DD5E
                bsr.w   Scroll_UpdateSnakeBackground
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                move.w  #$460,d0
                cmp.w   (PrimaryCameraXPosition).w,d0
                bpl.w   Stage_MidgameStateReturn
                move.w  #$100,(StageEventTimer).w
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                clr.w   (RasterEffectIndex).w
                clr.w   (RasterEffectInitState).w
                move.w  #$1F,(TilemapRowCountdown).w
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$6000,(TilemapTransferBase).w
                rts
; End of function Stage13_InitializeBugmaxApproach
; Fill the approach rows, wait for the timer/object gate, and initialize Bugmax
Stage13_UpdateBugmaxApproach:                           ; DATA XREF: ROM:0000D996   o  ; was: sub_DDA6
                bsr.w   Scroll_UpdateSnakeBackground
                jsr     (Tilemap_QueueNextConstantRow).l
                bpl.w   Stage_MidgameStateReturn
                subq.w  #1,(StageEventTimer).w
                bmi.s   Stage13_InitializeBugmaxEncounter
                tst.w   (Entity_ObjectPool).w
                bne.w   Stage_MidgameStateReturn
Stage13_InitializeBugmaxEncounter:                      ; CODE XREF: Stage13_UpdateBugmaxApproach+12   j  ; was: loc_DDC2
                addq.w  #2,(StageStateOffset).w
                move.w  #$7000,(BossHealth).w
                move.w  #$7000,(BossMaxHealth).w
                move.w  #$1E0,(BossCombatCounter).w
                move.w  #$1E0,(BossCombatCounterMax).w
                lea     (Boss_BugmaxAssetSet).l,a1
                bra.w   Boss_LoadAssetSet
; End of function Stage13_UpdateBugmaxApproach
; Track the Bugmax encounter and advance after the boss object clears
Stage13_UpdateBugmaxEncounter:                          ; DATA XREF: ROM:0000D998   o  ; was: sub_DDE8
                bsr.w   Scroll_UpdateSnakeBackground
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage13_UpdateBugmaxEncounterCamera
                addq.w  #2,(StageStateOffset).w
                move.w  #$22,(PlayerScriptStateOffset).w  ; '"'
Stage13_UpdateBugmaxEncounterCamera:                    ; CODE XREF: Stage13_UpdateBugmaxEncounter+8   j  ; was: loc_DDFC
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage13_UpdateBugmaxEncounter
; Wait for post-Bugmax gates, then start the interstage transition
Stage13_StartPostBugmaxTransition:                      ; DATA XREF: ROM:0000D99A   o  ; was: sub_DE00
                bsr.w   Scroll_UpdateSnakeBackground
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                tst.w   (GameplayExitMode).w
                bne.w   Stage_MidgameStateReturn
                tst.w   (ScriptedInputActive).w
                bne.w   Stage_MidgameStateReturn
                move.b  #$92,d0
                jsr     (Sound_QueueBGMOrStop).l
                move.l  #StageTransitionMessageSequence_TrainAndBugmax,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; End of function Stage13_StartPostBugmaxTransition
; Initialize the shared Stage 10/11 raster and ambient-particle effects
Midgame_InitializeRasterAndAmbientEffects:              ; CODE XREF: Stage10_Initialize+6   p  ; was: sub_DE2E
                                        ; Stage11_Initialize   p
                move.w  #$30,(RasterEffectIndex).w      ; '0'
                clr.w   (RasterEffectInitState).w
                jsr     (Midgame_InitializeAmbientParticles).l
                addq.w  #2,(StageStateOffset).w
                rts
; End of function Midgame_InitializeRasterAndAmbientEffects
; Stage 14 scroll handler
