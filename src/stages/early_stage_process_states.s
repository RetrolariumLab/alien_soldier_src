Stage_DispatchEarlyStageState:                          ; was: sub_C83E
                                        ; ROM:0000FF46   o
                movea.w EarlyStage_StateHandlerOffsets(pc,d0.w),a0
                adda.l  #Stage1_InitializeScrollState,a0
                jmp     (a0)
; End of function Stage_DispatchEarlyStageState
; ---------------------------------------------------------------------------
EarlyStage_StateHandlerOffsets: dc.w    Stage1_InitializeScrollState-Stage1_InitializeScrollState  ; was: off_C84A
                dc.w    Stage1_UpdateScrollToJetsripper-Stage1_InitializeScrollState
                dc.w    Stage1_InitializeJetsripperEncounter-Stage1_InitializeScrollState
                dc.w    Stage1_UpdateJetsripperEncounter-Stage1_InitializeScrollState
                dc.w    Stage1_StartPostJetsripperTransition-Stage1_InitializeScrollState
                dc.w    Stage2_UpdateScrollToAntroid-Stage1_InitializeScrollState
                dc.w    Stage2_InitializeAntroidEncounter-Stage1_InitializeScrollState
                dc.w    Stage2_UpdateAntroidEncounter-Stage1_InitializeScrollState
                dc.w    Stage2_StartPostAntroidTransition-Stage1_InitializeScrollState
                dc.w    Stage3_InitializeIntroProjectileSlots-Stage1_InitializeScrollState
                dc.w    Stage3_UpdateScrollToIntroProjectile-Stage1_InitializeScrollState
                dc.w    Stage3_WaitForIntroProjectile-Stage1_InitializeScrollState
                dc.w    Stage3_UpdateScrollToShellshogun-Stage1_InitializeScrollState
                dc.w    Stage3_InitializeShellshogunEncounter-Stage1_InitializeScrollState
                dc.w    Stage3_InitializePostShellshogunTransition-Stage1_InitializeScrollState
                dc.w    Stage3_WaitForPostShellshogunRows-Stage1_InitializeScrollState
                dc.w    Stage3_EnterStage4-Stage1_InitializeScrollState
                dc.w    Stage4_UpdateScrollToSniperHoneyviper-Stage1_InitializeScrollState
                dc.w    Stage4_InitializeSniperHoneyviperEncounter-Stage1_InitializeScrollState
                dc.w    Stage4_InitializeSniperHoneyviperRasterRows-Stage1_InitializeScrollState
                dc.w    Stage4_UpdateSniperHoneyviperEncounter-Stage1_InitializeScrollState
                dc.w    Stage4_WaitForSniperHoneyviperMessage-Stage1_InitializeScrollState
                dc.w    Stage4_CheckSniperHoneyviperTransitionReady-Stage1_InitializeScrollState
                dc.w    Stage5_InitializeScrollState-Stage1_InitializeScrollState
                dc.w    Stage5_UpdateScrollToMadamBarbar-Stage1_InitializeScrollState
                dc.w    Stage5_InitializeMadamBarbarEncounter-Stage1_InitializeScrollState
                dc.w    Stage5_UpdatePostMadamBarbar-Stage1_InitializeScrollState
                dc.w    Stage5_StartPostMadamBarbarTransition-Stage1_InitializeScrollState
                dc.w    Stage6_UpdateScrollToJoker-Stage1_InitializeScrollState
                dc.w    Stage6_InitializeJokerEncounter-Stage1_InitializeScrollState
                dc.w    Stage6_UpdatePostJoker-Stage1_InitializeScrollState
                dc.w    Stage6_StartPostJokerTransition-Stage1_InitializeScrollState
                dc.w    Stage7_InitializeScrollState-Stage1_InitializeScrollState
                dc.w    Stage7_UpdateScrollToTerobuster-Stage1_InitializeScrollState
                dc.w    Stage7_InitializeTerobusterEncounter-Stage1_InitializeScrollState
                dc.w    Stage7_UpdatePostTerobusterIntro-Stage1_InitializeScrollState
                dc.w    Stage7_UpdatePostTerobusterTransition-Stage1_InitializeScrollState
                dc.w    Stage7_UpdateScrollToStage8-Stage1_InitializeScrollState
                dc.w    Stage7_WaitForPlayerStage8Trigger-Stage1_InitializeScrollState
                dc.w    Stage7_StartTransitionToStage8-Stage1_InitializeScrollState
                dc.w    Stage8_InitializeTrainSequence-Stage1_InitializeScrollState
                dc.w    Stage8_UpdateTrainSequence-Stage1_InitializeScrollState
                dc.w    Stage8_InitializeFlyingNeoApproach-Stage1_InitializeScrollState
                dc.w    Stage8_UpdateFlyingNeoApproachDelay-Stage1_InitializeScrollState
                dc.w    Stage8_AccelerateFlyingNeoVerticalScroll-Stage1_InitializeScrollState
                dc.w    Stage8_DecelerateFlyingNeoVerticalScroll-Stage1_InitializeScrollState
                dc.w    Stage8_InitializeFlyingNeoEncounter-Stage1_InitializeScrollState
                dc.w    Stage8_UpdateFlyingNeoEncounter-Stage1_InitializeScrollState
                dc.w    Stage8_StartPostFlyingNeoTransition-Stage1_InitializeScrollState
                dc.w    Stage9_InitializeFlyCorridor-Stage1_InitializeScrollState
                dc.w    Stage9_UpdateFlyCorridor-Stage1_InitializeScrollState
                dc.w    Stage9_InitializeCaterpillarCamera-Stage1_InitializeScrollState
                dc.w    Stage9_InitializeCaterpillarEncounter-Stage1_InitializeScrollState
                dc.w    Stage9_UpdateCaterpillarShipTraversal-Stage1_InitializeScrollState
                dc.w    Stage9_UpdateCaterpillarShipExit-Stage1_InitializeScrollState
                dc.w    Stage9_XiTigerEntranceDelay_Return-Stage1_InitializeScrollState
                dc.w    Stage9_UpdateXiTigerEntranceDelay-Stage1_InitializeScrollState
                dc.w    Stage9_WaitForXiTigerEntranceObject-Stage1_InitializeScrollState
                dc.w    Stage9_UpdatePostXiTigerTransition-Stage1_InitializeScrollState
                dc.w    Stage9_InitializeXiTigerEncounter-Stage1_InitializeScrollState

; Updates stage logic and scroll
Stage1_InitializeScrollState:                           ; was: sub_C8C2
                                        ; ROM:EarlyStage_StateHandlerOffsets   o
                addq.w  #2,(StageStateOffset).w
; Updates stage scroll position and checks for phase transition at specific coordinate
Stage1_UpdateScrollToJetsripper:                        ; was: loc_C8C6
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$668,(PrimaryCameraXPosition).w
                bmi.s   Stage1_UpdateScrollToJetsripper_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage1_UpdateScrollToJetsripper_Return:                 ; was: locret_C8DA
                                        ; Stage_InitBossIntro+E   j
                rts
; End of function Stage1_InitializeScrollState
; Initializes boss introduction sequence
Stage1_InitializeJetsripperEncounter:                   ; was: sub_C8DC
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$6E8,(PrimaryCameraXPosition).w
                bmi.s   Stage1_UpdateScrollToJetsripper_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$6E8,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_JetsripperAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage1_InitializeJetsripperEncounter
; Camera handler checking boss presence
Stage1_UpdateJetsripperEncounter:                       ; was: sub_C910
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage1_UpdateJetsripperCamera
                bsr.w   Stage_StartTimeBonusAndPreloadNextPhase
; Updates camera position during boss battle phase
Stage1_UpdateJetsripperCamera:                          ; was: loc_C91A
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_UpdateQuarterHorizontalPosition
; End of function Stage1_UpdateJetsripperEncounter
; Stage 2 camera with transition check
Stage1_StartPostJetsripperTransition:                   ; was: sub_C922
                bsr.w   Stage_StartNextPhaseBanner
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_UpdateQuarterHorizontalPosition
; End of function Stage1_StartPostJetsripperTransition
; Camera with auto-scroll and phase transition
Stage2_UpdateScrollToAntroid:                           ; was: sub_C92E
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$B40,(PrimaryCameraXPosition).w
                bmi.s   Stage2_UpdateScrollToAntroid_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage2_UpdateScrollToAntroid_Return:                    ; was: locret_C942
                                        ; Camera_TransitionToBossArena+E   j
                rts
; End of function Stage2_UpdateScrollToAntroid
; Transitions camera to boss arena with position lock
Stage2_InitializeAntroidEncounter:                      ; was: sub_C944
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$BC0,(PrimaryCameraXPosition).w
                bmi.s   Stage2_UpdateScrollToAntroid_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$BC0,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_AntroidAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage2_InitializeAntroidEncounter
; Initializes camera for Antroid boss fight
Stage2_UpdateAntroidEncounter:                          ; was: sub_C978
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage2_UpdateAntroidCamera
                clr.w   (SecondaryCameraYPos).w
                bsr.w   Stage_StartPostBannerDelayAndPreloadNextPhase
; Updates camera for Antroid boss with score timer initialization
Stage2_UpdateAntroidCamera:                             ; was: loc_C986
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_UpdateQuarterHorizontalPosition
; End of function Stage2_UpdateAntroidEncounter
; Stage 3 camera with section transition
Stage2_StartPostAntroidTransition:                      ; was: sub_C98E
                bsr.w   Stage_StartNextPhaseBanner
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Scroll_UpdateQuarterHorizontalPosition
; End of function Stage2_StartPostAntroidTransition
; Stage 3 camera with scroll update and position limit
Stage3_InitializeIntroProjectileSlots:                  ; was: sub_C99A
                addq.w  #2,(StageStateOffset).w
                movea.w #(SecondaryEntityType-M68K_RAM),a0
                moveq   #7,d7
Stage3_InitializeIntroProjectileSlots_Loop:             ; was: loc_C9A4
                move.w  #$10,(a0)
                lea     $60(a0),a0
                dbf     d7,Stage3_InitializeIntroProjectileSlots_Loop
; Updates scroll and camera transitions at position $FC0
Stage3_UpdateScrollToIntroProjectile:                   ; was: loc_C9B0
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$FC0,(PrimaryCameraXPosition).w
                bmi.w   Stage3_UpdateScrollToIntroProjectile_Return
                addq.w  #2,(StageStateOffset).w
                move.w  #$FC0,(PrimaryCameraXPosition).w
                move.w  #$190,(Entity_ObjectPool).w
Stage3_UpdateScrollToIntroProjectile_Return:            ; was: locret_C9D2
                rts
; End of function Stage3_InitializeIntroProjectileSlots
; Sets up camera for Stage 3 boss encounter
Stage3_WaitForIntroProjectile:                          ; was: sub_C9D4
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage3_WaitForIntroProjectile_Return
                addq.w  #2,(StageStateOffset).w
Stage3_WaitForIntroProjectile_Return:                   ; was: locret_C9DE
                rts
; End of function Stage3_WaitForIntroProjectile
; Updates camera position during boss fight
Stage3_UpdateScrollToShellshogun:                       ; was: sub_C9E0
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$1168,(PrimaryCameraXPosition).w
                bmi.w   Stage3_UpdateScrollToShellshogun_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage3_UpdateScrollToShellshogun_Return:                ; was: locret_C9F6
                                        ; Camera_LockToBossArena+E   j
                rts
; End of function Stage3_UpdateScrollToShellshogun
; Locks camera to boss arena boundaries
Stage3_InitializeShellshogunEncounter:                  ; was: sub_C9F8
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$11E8,(PrimaryCameraXPosition).w
                bmi.s   Stage3_UpdateScrollToShellshogun_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$11E8,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_ShellshogunAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage3_InitializeShellshogunEncounter
; Initializes camera for Shellshogun boss fight
Stage3_InitializePostShellshogunTransition:             ; was: sub_CA2C
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage3_InitializePostShellshogunTransition_UpdateCamera
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                addq.w  #2,(StageStateOffset).w
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                clr.w   (SecondaryCameraYPos).w
                lea     (Boss_ShellshogunAssetLoadList).l,a0
                jsr     (Data_ProcessPointer).l
                move.w  #4,(PalettePrimaryIndex).w
                lea     (ShellshogunStagePaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                move.l  #Stage3_PostShellshogunRowSourceData,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                clr.w   (TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
Stage3_InitializePostShellshogunTransition_UpdateCamera:  ; was: loc_CA86
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage3_InitializePostShellshogunTransition
; ---------------------------------------------------------------------------
Stage3_PostShellshogunRowSourceData:    dc.l    $FFFF7000, $FFFF6800, $FFFF2000, $6000  ; was: dword_CA8A

; Locks camera to fixed position
Stage3_WaitForPostShellshogunRows:                      ; was: sub_CA9A
                tst.w   (DataLoaderControl).w
                bmi.s   Stage3_WaitForPostShellshogunRows_UpdateCamera
                tst.w   (TilemapRowCountdown).w
                bmi.s   Stage3_StartPostShellshogunBanner
                bsr.w   Tilemap_QueueNextScrollingRow
                bra.s   Stage3_WaitForPostShellshogunRows_UpdateCamera
; ---------------------------------------------------------------------------
Stage3_StartPostShellshogunBanner:                      ; was: loc_CAAC
                bsr.w   Stage_StartNextPhaseBanner
Stage3_WaitForPostShellshogunRows_UpdateCamera:         ; was: loc_CAB0
                                        ; Camera_LockPosition+10   j
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage3_WaitForPostShellshogunRows
; Updates camera with smooth interpolation
Stage3_EnterStage4:                                     ; was: sub_CAB4
                move.b  #$81,d0
                jsr     (Sound_QueueBGMRequest).l
                addq.w  #2,(StageStateOffset).w
                jsr     (Stage_DispatchVisualAssetLoader).l
                bra.w   *+4
; ---------------------------------------------------------------------------
; Updates smooth scrolling camera transitions at $1A78
Stage4_UpdateScrollToSniperHoneyviper:                  ; was: loc_CACC
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$1A78,(PrimaryCameraXPosition).w
                bmi.s   Stage4_UpdateScrollToSniperHoneyviper_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage4_UpdateScrollToSniperHoneyviper_Return:           ; was: locret_CAE0
                rts
; End of function Stage3_EnterStage4
; Camera following target with offset
Stage4_InitializeSniperHoneyviperEncounter:             ; was: sub_CAE2
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                cmpi.w  #$1AF8,(PrimaryCameraXPosition).w
                bmi.s   Stage4_InitializeSniperHoneyviperEncounter_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$1AF8,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                move.b  #$10,(PlaneAScrollModeFlags).w
                move.b  #4,(PlaneBScrollModeFlags).w
                lea     (Boss_SniperHoneyviperAssetSet).l,a1
                jsr     (Boss_LoadAssetSet).l
                bsr.s   Stage4_FillSniperHoneyviperHorizontalRasterOffsets
Stage4_InitializeSniperHoneyviperEncounter_Return:      ; was: locret_CB24
                rts
; End of function Stage4_InitializeSniperHoneyviperEncounter
; Sets camera boundary limits
Stage4_InitializeSniperHoneyviperRasterRows:            ; was: sub_CB26
                move.b  #3,(VDPReg11Shadow+1).w
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                bra.s   Stage4_FillSniperHoneyviperHorizontalRasterOffsets
; End of function Stage4_InitializeSniperHoneyviperRasterRows
; Handles camera logic during stage transition checking boss state
Stage4_UpdateSniperHoneyviperEncounter:                 ; was: sub_CB32
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage4_UpdateSniperHoneyviperEncounterCamera
                addq.w  #2,(StageStateOffset).w
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                bra.s   Stage4_WaitForSniperHoneyviperMessage
; ---------------------------------------------------------------------------
Stage4_UpdateSniperHoneyviperEncounterCamera:           ; was: loc_CB44
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                bsr.s   Stage4_FillSniperHoneyviperHorizontalRasterOffsets
                move.w  #$C0,(SecondaryCameraXPos).w
                rts
; End of function Stage4_UpdateSniperHoneyviperEncounter
; Clamps camera position to boundaries
Stage4_FillSniperHoneyviperHorizontalRasterOffsets:     ; was: sub_CB56
                                        ; Camera_SetBounds+A   j
                movea.w #(HorizontalScrollProfile-M68K_RAM),a0
                move.w  (SecondaryCameraXPos).w,d0
                neg.w   d0
                moveq   #$7F,d7
Stage4_FillSniperHoneyviperSecondaryRasterOffsets:      ; was: loc_CB62
                move.w  d0,(a0)+
                dbf     d7,Stage4_FillSniperHoneyviperSecondaryRasterOffsets
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
                moveq   #$47,d7                         ; 'G'
Stage4_FillSniperHoneyviperPrimaryRasterOffsets:        ; was: loc_CB70
                move.w  d0,(a0)+
                dbf     d7,Stage4_FillSniperHoneyviperPrimaryRasterOffsets
                rts
; End of function Stage4_FillSniperHoneyviperHorizontalRasterOffsets
; Waits for scroll position then advances stage phase
Stage4_WaitForSniperHoneyviperMessage:                  ; was: sub_CB78
                bsr.s   Stage4_UpdateSniperHoneyviperCameraAndRasterRows
                tst.w   (MessageSequenceState).w
                bne.s   Stage4_WaitForSniperHoneyviperMessage_Return
                addq.w  #2,(StageStateOffset).w
                move.w  #2,(PlayerScriptStateOffset).w
Stage4_WaitForSniperHoneyviperMessage_Return:           ; was: locret_CB8A
                rts
; End of function Stage4_WaitForSniperHoneyviperMessage
; Updates camera position and calculates scroll registers
Stage4_UpdateSniperHoneyviperCameraAndRasterRows:       ; was: sub_CB8C
                                        ; sub_CB9E   p
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                bsr.s   Stage4_FillSniperHoneyviperHorizontalRasterOffsets
                move.w  #$C0,(SecondaryCameraXPos).w
                rts
; End of function Stage4_UpdateSniperHoneyviperCameraAndRasterRows
; Checks if stage transition is ready based on enemy and boss state
Stage4_CheckSniperHoneyviperTransitionReady:            ; was: sub_CB9E
                bsr.s   Stage4_UpdateSniperHoneyviperCameraAndRasterRows
                tst.w   (GameplayExitMode).w
                bne.s   Stage4_CheckSniperHoneyviperTransitionReady_Return
                tst.w   (ScriptedInputActive).w
                bne.s   Stage4_CheckSniperHoneyviperTransitionReady_Return
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; ---------------------------------------------------------------------------
Stage4_CheckSniperHoneyviperTransitionReady_Return:     ; was: locret_CBB8
                                        ; Stage_CheckTransitionReady+C   j
                rts
; End of function Stage4_CheckSniperHoneyviperTransitionReady
; Updates automatic stage scrolling and checks for phase transition
Stage5_InitializeScrollState:                           ; was: sub_CBBA
                addq.w  #2,(StageStateOffset).w
; Updates automatic scrolling and checks for transition
Stage5_UpdateScrollToMadamBarbar:                       ; was: loc_CBBE
                bsr.w   Camera_UpdateAndRenderStageTilemap
                cmpi.w  #$400,(PrimaryCameraXPosition).w
                bmi.s   Stage5_UpdateScrollToMadamBarbar_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage5_UpdateScrollToMadamBarbar_Return:                ; was: locret_CBCE
                                        ; Boss_MadamBarbarScrollInit+A   j
                rts
; End of function Stage5_InitializeScrollState
; Initializes Madam Barbar boss scroll position and palette
Stage5_InitializeMadamBarbarEncounter:                  ; was: sub_CBD0
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                cmpi.w  #$480,(PrimaryCameraXPosition).w
                bmi.s   Stage5_UpdateScrollToMadamBarbar_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$480,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                lea     (Boss_MadamBarbarAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage5_InitializeMadamBarbarEncounter
; Initializes stage after boss defeat with score timer and camera
Stage5_UpdatePostMadamBarbar:                           ; was: sub_CC06
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage5_UpdatePostMadamBarbarCamera
                clr.w   (SecondaryCameraYPos).w
                move.l  #PostBossRuntimeSpawnList,(StageObjectSpawnCursor).w
                bsr.w   Stage_StartPostBannerDelayAndPreloadNextPhase
Stage5_UpdatePostMadamBarbarCamera:                     ; was: loc_CC1C
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage5_UpdatePostMadamBarbar
; Start a section change and request the default BGM when no delay is active
Stage5_StartPostMadamBarbarTransition:                  ; was: sub_CC20
                tst.w   (MessageSequenceState).w
                bne.s   Stage5_StartPostMadamBarbarTransition_Continue
                move.b  #$81,d0
                jsr     (Sound_QueueBGMRequest).l
Stage5_StartPostMadamBarbarTransition_Continue:         ; was: loc_CC30
                clr.w   (GlobalSpritePriorityBit).w
                bsr.w   Stage_StartNextPhaseBanner
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage5_StartPostMadamBarbarTransition
; Checks scroll position for stage phase transition trigger
Stage6_UpdateScrollToJoker:                             ; was: sub_CC3C
                bsr.w   Camera_UpdateAndRenderStageTilemap
                cmpi.w  #$9E0,(PrimaryCameraXPosition).w
                bmi.s   Stage6_UpdateScrollToJoker_Return
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage6_UpdateScrollToJoker_Return:                      ; was: locret_CC4C
                                        ; Stage_InitJokerBoss+A   j
                rts
; End of function Stage6_UpdateScrollToJoker
; Initializes Joker boss fight with scroll check and palette update
Stage6_InitializeJokerEncounter:                        ; was: sub_CC4E
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                cmpi.w  #$A60,(PrimaryCameraXPosition).w
                bmi.s   Stage6_UpdateScrollToJoker_Return
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$A60,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                lea     (Boss_JokerAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage6_InitializeJokerEncounter
; Post-boss initialization triggering stage phase transition
Stage6_UpdatePostJoker:                                 ; was: sub_CC84
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage6_UpdatePostJokerCamera
                clr.w   (SecondaryCameraYPos).w
                bsr.w   Stage_StartTimeBonusAndPreloadNextPhase
Stage6_UpdatePostJokerCamera:                           ; was: loc_CC92
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage6_UpdatePostJoker
; Post-Joker transition clearing flags and updating camera
Stage6_StartPostJokerTransition:                        ; was: sub_CC96
                clr.w   (GlobalSpritePriorityBit).w
                bsr.w   Stage_StartNextPhaseBanner
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage6_StartPostJokerTransition
; Initializes Stage 7 with scroll setup and palette loading
Stage7_InitializeScrollState:                           ; was: sub_CCA2
                tst.w   (DataLoaderControl).w
                bmi.s   Stage7_UpdateScrollToTerobuster
                bsr.w   Stage7_InitializeTerobusterIntroProjectiles
                addq.w  #2,(StageStateOffset).w
                lea     Stage7_InitialTileAssetLoadList(pc),a0
                nop
                jsr     (Data_ProcessPointer).l
                bra.s   Stage7_UpdateScrollToTerobuster
; End of function Stage7_InitializeScrollState
; ---------------------------------------------------------------------------
Stage7_InitialTileAssetLoadList:    dc.w    7           ; command: LZSS to VRAM  ; was: stru_CCBE
                dc.l    Stage7InitialTileArt            ; source
                dc.w    $5BE0                           ; destination: VRAM $5BE0
                dc.w    $FFFF

; Updates Stage 7 scroll checking transition boundaries
Stage7_UpdateScrollToTerobuster:                        ; was: sub_CCC8
                                        ; Stage_InitStage7+1A   j
                bsr.w   Camera_UpdateAndRenderStageTilemap
                move.w  (PrimaryCameraXPosition).w,d0
                add.w   (PlayerXPosition).w,d0
                cmpi.w  #$1098,(PrimaryCameraXPosition).w
                bpl.s   Stage7_BeginTerobusterApproach
                cmpi.w  #$1116,d0
                bmi.s   Stage7_CheckIntroProjectileTrigger
Stage7_BeginTerobusterApproach:                         ; was: loc_CCE2
                move.w  #$6000,(TilemapTransferBase).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  #0,(TilemapRowXOrFillWord).w
                move.w  #$C0,(TerobusterIntroTimer).w
                bra.w   Stage_TransitionToNextPhase
; ---------------------------------------------------------------------------
Stage7_UpdateScrollToTerobuster_Return:                 ; was: locret_CCFE
                                        ; Stage_InitTerobusterBoss+2A   j
                rts
; ---------------------------------------------------------------------------
Stage7_CheckIntroProjectileTrigger:                     ; was: loc_CD00
                cmpi.w  #$10B6,d0
                bmi.s   Stage7_UpdateScrollToTerobuster_Return
                bra.w   Stage7_SpawnTerobusterIntroProjectile
; End of function Stage7_UpdateScrollToTerobuster
; Initializes Terobuster boss with scroll and graphics loading
Stage7_InitializeTerobusterEncounter:                   ; was: sub_CD0A
                bsr.w   Stage7_SpawnTerobusterIntroProjectile
                subq.w  #1,(TerobusterIntroTimer).w
                bsr.w   Stage7_UpdateTerobusterIntroFade
                bsr.w   Stage7_UpdateTerobusterIntroTileRows
                jsr     (Tilemap_QueueNextConstantRow).l
                addi.l  #$C000,(PrimaryCameraXPosition).w
                jsr     (Tilemap_QueuePrimaryCameraColumnOffset158).l
                cmpi.w  #$10A0,(PrimaryCameraXPosition).w
                bmi.s   Stage7_UpdateScrollToTerobuster_Return
                clr.l   (CameraXDelta).w
                move.w  #$10A0,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                tst.w   (TerobusterIntroTimer).w
                bpl.s   Stage7_UpdateScrollToTerobuster_Return
                addq.w  #2,(StageStateOffset).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                lea     (Boss_TerobusterAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage7_InitializeTerobusterEncounter
; Updates stage scroll offset with directional calculation
Stage7_UpdateTerobusterIntroFade:                       ; was: sub_CD66
                move.w  (TerobusterIntroTimer).w,d0
                bmi.s   Stage7_UpdateScrollToTerobuster_Return
                bne.s   Stage7_CalculateTerobusterFadeParameters
                moveq   #0,d2
                bra.s   Stage7_ApplyTerobusterFadeParameters
; ---------------------------------------------------------------------------
Stage7_CalculateTerobusterFadeParameters:               ; was: loc_CD72
                moveq   #2,d2
                asr.w   #1,d0
                andi.w  #$E,d0
                sub.w   d0,d2
Stage7_ApplyTerobusterFadeParameters:                   ; was: loc_CD7C
                move.w  d2,d3
                lea     (PaletteFade_StageScrollEntryOffsets).l,a2
                moveq   #0,d1
                asl.w   #4,d2
                asl.w   #8,d3
                jmp     (Gfx_ApplyRGBDeltaToPaletteEntries_LoadEntryCount).l
; End of function Stage7_UpdateTerobusterIntroFade
; Post-intro transition clearing flags and advancing phase
Stage7_UpdatePostTerobusterIntro:                       ; was: sub_CD90
                bsr.w   Stage7_SpawnTerobusterIntroProjectile
                bsr.w   Stage7_UpdateTerobusterIntroTileRows
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage7_UpdatePostTerobusterIntroCamera
                clr.b   (VDPReg11Shadow+1).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                addq.w  #2,(StageStateOffset).w
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                clr.w   (SecondaryCameraYPos).w
Stage7_UpdatePostTerobusterIntroCamera:                 ; was: loc_CDB8
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage7_UpdatePostTerobusterIntro
; Post-Terobuster transition clearing flags and advancing
Stage7_UpdatePostTerobusterTransition:                  ; was: sub_CDBC
                tst.w   (MessageSequenceState).w
                bne.s   Stage7_UpdatePostTerobusterTransitionCamera
                move.b  #1,(SoundFadeOutDelay).w
                move.w  #4,(PlayerScriptStateOffset).w
                addq.w  #2,(StageStateOffset).w
                lea     Stage7_TerobusterIndexedRowCommandF0F1(pc),a0
                nop
                jsr     (Tilemap_QueueIndexedRows).l
Stage7_UpdatePostTerobusterTransitionCamera:            ; was: loc_CDDE
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage7_UpdatePostTerobusterTransition
; Stage 7 to 8 transition with scroll boundary check
Stage7_UpdateScrollToStage8:                            ; was: sub_CDE2
                bsr.w   Camera_UpdateAndRenderStageTilemap
                cmpi.w  #$1200,(PrimaryCameraXPosition).w
                bmi.s   Stage7_UpdateScrollToStage8_Return
                addq.w  #2,(StageStateOffset).w
                move.w  #$1200,(PrimaryCameraXPosition).w
Stage7_UpdateScrollToStage8_Return:                     ; was: locret_CDF8
                rts
; End of function Stage7_UpdateScrollToStage8
; Checks player X position to trigger stage transition
