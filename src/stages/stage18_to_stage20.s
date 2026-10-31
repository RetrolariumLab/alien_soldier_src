Stage_LateGameStateReturn:                              ; was: nullsub_26
                                        ; Stage18_UpdateScrollToDestroyerMk2Approach+10   j
                rts
; End of function Stage_LateGameStateReturn
; Update Stage 18's initial scroll to camera X $820
Stage18_UpdateInitialScroll:                            ; was: sub_E4DE
                bset    #6,(PlayerRestrictionFlags).w
                jsr     (Stage18_UpdateScrollAndRenderTilemap).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$820,(PrimaryCameraXPosition).w
                bmi.s   Stage_LateGameStateReturn
                addq.w  #2,(StageStateOffset).w
Stage18And19_SharedReturn:                              ; was: locret_E4FA
                rts
; End of function Stage18_UpdateInitialScroll
; Update Stage 18 to the Destroyer-Mk2 approach boundary
Stage18_UpdateScrollToDestroyerMk2Approach:             ; was: sub_E4FC
                jsr     (Stage18_UpdateScrollAndRenderTilemap).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$BF0,(PrimaryCameraXPosition).w
                bmi.s   Stage_LateGameStateReturn
                bra.w   Stage_TransitionToNextPhase
; End of function Stage18_UpdateScrollToDestroyerMk2Approach
; Clamp Stage 18 and submit Destroyer-Mk2's asset set
Stage18_InitializeDestroyerMk2Encounter:                ; was: sub_E512
                jsr     (Stage18_UpdateDestroyerMk2Scroll).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$C70,(PrimaryCameraXPosition).w
                bmi.s   Stage_LateGameStateReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$C70,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                lea     (Boss_DestroyerMk2AssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage18_InitializeDestroyerMk2Encounter
; Wait for Destroyer-Mk2 to clear, then start the time bonus and preload
Stage18_UpdateDestroyerMk2Encounter:                    ; was: sub_E54E
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage18_UpdateDestroyerMk2Encounter_UpdateCamera
                bsr.w   Stage_StartTimeBonusAndPreloadNextPhase
Stage18_UpdateDestroyerMk2Encounter_UpdateCamera:       ; was: loc_E558
                jsr     (Camera_UpdateHorizontalTowardsPlayer).l
                bra.w   Stage18And19_UpdateHorizontalParallax
; End of function Stage18_UpdateDestroyerMk2Encounter
; Start the final Stage 18 post-Destroyer-Mk2 transition state
Stage18_StartPostDestroyerMk2Transition:                ; was: sub_E562
                bsr.w   Stage_StartNextPhaseBanner
                jsr     (Camera_UpdateHorizontalTowardsPlayer).l
                bra.w   Stage18And19_UpdateHorizontalParallax
; End of function Stage18_StartPostDestroyerMk2Transition
; Update Stage 19's initial scroll and submit its tile assets
Stage19_UpdateInitialScrollAndLoadTiles:                ; was: sub_E570
                jsr     (Stage18_UpdateScrollAndRenderTilemap).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$D80,(PrimaryCameraXPosition).w
                bmi.w   Stage_LateGameStateReturn
                addq.w  #2,(StageStateOffset).w
                lea     Stage19_InitialTileAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage19_UpdateInitialScrollAndLoadTiles
; ---------------------------------------------------------------------------
Stage19_InitialTileAssetLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_E594
                dc.l    Stage19InitialTileArt0000       ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage19InitialMappingData6000   ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage19InitialMappingData4020   ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage19InitialMappingData7800   ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    $FFFF

; Update Stage 19 to the first Jampan approach boundary
Stage19_UpdateScrollToJampanApproach:                   ; was: sub_E5B6
                jsr     (Camera_UpdateAndRenderStageTilemap).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$1120,(PrimaryCameraXPosition).w
                bmi.w   Stage_LateGameStateReturn
                addq.w  #2,(StageStateOffset).w
                rts
; End of function Stage19_UpdateScrollToJampanApproach
; Continue Stage 19 to Jampan's arena boundary
Stage19_UpdateScrollToJampanArena:                      ; was: sub_E5D0
                jsr     (Camera_UpdateAndRenderStageTilemap).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$1200,(PrimaryCameraXPosition).w
                bmi.w   Stage_LateGameStateReturn
                addq.w  #2,(StageStateOffset).w
                rts
; End of function Stage19_UpdateScrollToJampanArena
; Enter the shared phase transition at Jampan's arena boundary
Stage19_StartJampanEncounterTransition:                 ; was: sub_E5EA
                jsr     (Camera_UpdateAndRenderStageTilemap).l
                bsr.w   Stage18And19_UpdateHorizontalParallax
                cmpi.w  #$1200,(PrimaryCameraXPosition).w
                bmi.w   Stage_LateGameStateReturn
                bra.w   Stage_TransitionToNextPhase
; End of function Stage19_StartJampanEncounterTransition
; Clamp Stage 19 and submit Jampan's asset set
Stage19_InitializeJampanEncounter:                      ; was: sub_E602
                jsr     (Camera_UpdateBossApproachAndRenderTilemap).l
                cmpi.w  #$1280,(PrimaryCameraXPosition).w
                bmi.w   Stage_LateGameStateReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$1280,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_JampanAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function Stage19_InitializeJampanEncounter
; Update the Jampan encounter camera until its completion flag is set
Stage19_UpdateJampanEncounter:                          ; was: sub_E636
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage19_UpdateJampanEncounter_UpdateCamera
                addq.w  #2,(StageStateOffset).w
Stage19_UpdateJampanEncounter_UpdateCamera:             ; was: loc_E640
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage19_UpdateJampanEncounter
; Wait for the post-Jampan message, then initialize the next delay
Stage19_UpdatePostJampanMessage:                        ; was: sub_E644
                tst.w   (MessageSequenceState).w
                bne.s   Stage19_UpdatePostJampanMessage_Return
                addq.w  #2,(StageStateOffset).w
                move.w  #$32,(PlayerScriptStateOffset).w  ; '2'
Stage19_UpdatePostJampanMessage_Return:                 ; was: locret_E654
                rts
; End of function Stage19_UpdatePostJampanMessage
; Start the post-Jampan interstage transition when both gates clear
Stage19_StartPostJampanTransition:                      ; was: sub_E656
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                tst.w   (GameplayExitMode).w
                bne.s   Stage19_StartPostJampanTransition_Return
                tst.w   (ScriptedInputActive).w
                bne.s   Stage19_StartPostJampanTransition_Return
                move.b  #0,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; ---------------------------------------------------------------------------
Stage19_StartPostJampanTransition_Return:               ; was: locret_E678
                                        ; Stage19_StartPostJampanTransition+E   j
                rts
; End of function Stage19_StartPostJampanTransition
; Derive the shared Stage 18/19 horizontal parallax offset from camera X
Stage18And19_UpdateHorizontalParallax:                  ; was: sub_E67A
                                        ; Stage18_UpdateScrollToDestroyerMk2Approach+6   p
                move.w  (PrimaryCameraXPosition).w,d0
                asr.w   #3,d0
                move.w  d0,(SecondaryCameraXPos).w
                rts
; End of function Stage18And19_UpdateHorizontalParallax
; Unreferenced Stage 20 variant 1 entry using Jampan's asset set
UnreferencedStage20Variant1_InitializeJampanPhase:      ; was: sub_E686
                bsr.w   Stage_TransitionToNextPhase
                clr.b   (SceneSequenceFlags).w
                move.w  #$40,(CameraXLowerBound).w      ; '@'
                move.w  #$80,(CameraXUpperBound).w
                move.b  #1,(SoundFadeOutDelay).w
                lea     (Boss_JampanAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function UnreferencedStage20Variant1_InitializeJampanPhase
; Wait for the variant 1 completion flag while updating the camera
UnreferencedStage20Variant1_UpdateJampanPhase:          ; was: sub_E6AC
                tst.b   (SceneSequenceFlags).w
                beq.s   UnreferencedStage20Variant1_UpdateJampanPhase_Camera
                addq.w  #2,(StageStateOffset).w
UnreferencedStage20Variant1_UpdateJampanPhase_Camera:   ; was: loc_E6B6
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function UnreferencedStage20Variant1_UpdateJampanPhase
; Start the variant 1 transition after both shared gates clear
UnreferencedStage20Variant1_StartTransition:            ; was: sub_E6BA
                tst.w   (GameplayExitMode).w
                bne.w   Stage_LateGameStateReturn
                tst.w   (ScriptedInputActive).w
                bne.w   Stage_LateGameStateReturn
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; End of function UnreferencedStage20Variant1_StartTransition
; Unreferenced Stage 20 variant 2 entry using entity type $3EC
UnreferencedStage20Variant2_InitializeLambdaBunnyPhase:  ; was: sub_E6D6
                bsr.w   Stage_TransitionToNextPhase
                clr.b   (SceneSequenceFlags).w
                move.w  #$40,(CameraXLowerBound).w      ; '@'
                move.w  #$80,(CameraXUpperBound).w
                move.b  #1,(SoundFadeOutDelay).w
                lea     (Boss_LambdaBunnyAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function UnreferencedStage20Variant2_InitializeLambdaBunnyPhase
; Wait for the variant 2 completion flag while updating the camera
UnreferencedStage20Variant2_UpdateLambdaBunnyPhase:     ; was: sub_E6FC
                tst.b   (SceneSequenceFlags).w
                beq.s   UnreferencedStage20Variant2_UpdateLambdaBunnyPhase_Camera
                addq.w  #2,(StageStateOffset).w
UnreferencedStage20Variant2_UpdateLambdaBunnyPhase_Camera:  ; was: loc_E706
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function UnreferencedStage20Variant2_UpdateLambdaBunnyPhase
; Start the variant 2 transition after both shared gates clear
UnreferencedStage20Variant2_StartTransition:            ; was: sub_E70A
                tst.w   (GameplayExitMode).w
                bne.w   Stage_LateGameStateReturn
                tst.w   (ScriptedInputActive).w
                bne.w   Stage_LateGameStateReturn
                move.b  #$8F,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; End of function UnreferencedStage20Variant2_StartTransition
; Unreferenced Stage 20 variant 3 entry using entity type $3F0
UnreferencedStage20Variant3_InitializeEntity3F0Phase:   ; was: sub_E72C
                bsr.w   Stage_TransitionToNextPhase
                clr.b   (SceneSequenceFlags).w
                move.w  #$40,(CameraXLowerBound).w      ; '@'
                move.w  #$80,(CameraXUpperBound).w
                move.b  #1,(SoundFadeOutDelay).w
                lea     (EntityType3F0AssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function UnreferencedStage20Variant3_InitializeEntity3F0Phase
; Wait for the variant 3 completion flag while updating the camera
UnreferencedStage20Variant3_UpdateEntity3F0Phase:       ; was: sub_E752
                tst.b   (SceneSequenceFlags).w
                beq.s   UnreferencedStage20Variant3_UpdateEntity3F0Phase_Camera
                addq.w  #2,(StageStateOffset).w
UnreferencedStage20Variant3_UpdateEntity3F0Phase_Camera:  ; was: loc_E75C
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function UnreferencedStage20Variant3_UpdateEntity3F0Phase
; Start the variant 3 transition after both shared gates clear
UnreferencedStage20Variant3_StartTransition:            ; was: sub_E760
                tst.w   (GameplayExitMode).w
                bne.w   Stage_LateGameStateReturn
                tst.w   (ScriptedInputActive).w
                bne.w   Stage_LateGameStateReturn
                move.b  #$8F,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; End of function UnreferencedStage20Variant3_StartTransition
; Unreferenced Stage 20 variant 4 entry using entity type $3F4
UnreferencedStage20Variant4_InitializeEntity3F4Phase:   ; was: sub_E782
                bsr.w   Stage_TransitionToNextPhase
                clr.b   (SceneSequenceFlags).w
                move.w  #$40,(CameraXLowerBound).w      ; '@'
                move.w  #$80,(CameraXUpperBound).w
                move.b  #1,(SoundFadeOutDelay).w
                lea     (EntityType3F4AssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function UnreferencedStage20Variant4_InitializeEntity3F4Phase
; Wait for the variant 4 completion flag while updating the camera
UnreferencedStage20Variant4_UpdateEntity3F4Phase:       ; was: sub_E7A8
                tst.b   (SceneSequenceFlags).w
                beq.s   UnreferencedStage20Variant4_UpdateEntity3F4Phase_Camera
                addq.w  #2,(StageStateOffset).w
UnreferencedStage20Variant4_UpdateEntity3F4Phase_Camera:  ; was: loc_E7B2
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function UnreferencedStage20Variant4_UpdateEntity3F4Phase
; Start the variant 4 transition after both shared gates clear
UnreferencedStage20Variant4_StartTransition:            ; was: sub_E7B6
                tst.w   (GameplayExitMode).w
                bne.w   Stage_LateGameStateReturn
                tst.w   (ScriptedInputActive).w
                bne.w   Stage_LateGameStateReturn
                move.b  #$96,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; End of function UnreferencedStage20Variant4_StartTransition
; Stage 20 initialization
