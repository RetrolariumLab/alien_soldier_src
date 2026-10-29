; Stage initialization
StageTransition_InitializeMissirayEntryScene:           ; was: sub_F7FA
                addq.w  #2,(StageStateOffset).w
                move.l  #$FFFE0000,(MissirayParallaxSpeed).w
                move.b  #4,(VDPReg11Shadow+1).w
                move.b  #2,(PlaneAScrollModeFlags).w
                move.b  #8,(PlaneBScrollModeFlags).w
                move.w  #$200,(StageSceneDelayTimer).w
                movea.w #(Entity57Type-M68K_RAM),a0
                movea.w #(Entity58Type-M68K_RAM),a1
                move.w  #$3E0,(a0)
                move.w  #$C400,2(a0)
                move.l  #MissirayEntryPrimarySpriteMapping,8(a0)
                move.w  #$8200,$E(a0)
                move.b  #$20,$21(a0)                    ; ' '
                move.w  #2,$46(a0)
                move.l  #$FF000100,$28(a0)
                move.w  #$150,d6
                move.w  #$120,d7
                move.w  d6,$10(a0)
                move.w  d7,$14(a0)
                move.w  d6,$4C(a0)
                move.w  d7,$4E(a0)
                clr.w   $56(a0)
                move.w  #$3E0,(a1)
                move.w  #1,$56(a1)
                move.w  #$C400,2(a1)
                move.l  #MissirayEntrySecondarySpriteMapping,8(a1)
                move.w  #$8200,$E(a1)
                move.w  #$D0,$10(a1)
                move.w  d7,$14(a1)
                move.w  #$3C8,(Entity59Type).w
; Updates the Missiray entry parallax until the scene delay expires
StageTransition_UpdateMissirayEntryDelay:               ; was: loc_F89C
                bsr.w   StageTransition_UpdateMissirayParallax
                subq.w  #1,(StageSceneDelayTimer).w
                bpl.w   StageTransition_SharedReturn
                move.w  #$80,(StageSceneDelayTimer).w
                jmp     Stage_TransitionToNextPhase
; End of function StageTransition_InitializeMissirayEntryScene
; Waits for the entry delay, then starts loading the Missiray asset set
StageTransition_LoadMissirayAssets:                     ; was: sub_F8B4
                bsr.w   StageTransition_UpdateMissirayParallax
                subq.w  #1,(StageSceneDelayTimer).w
                bpl.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                lea     (Boss_MissirayAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function StageTransition_LoadMissirayAssets
; Waits for the first object slot to clear before starting the Missiray message
StageTransition_WaitForMissirayObjectClear:             ; was: sub_F8D0
                tst.w   (Entity_ObjectPool).w
                bne.s   StageTransition_UpdateMissirayEntryScene
                addq.w  #2,(StageStateOffset).w
                move.w  #$2E,(MessageSequenceState).w   ; '.'
                move.b  #1,(SoundFadeOutDelay).w
StageTransition_UpdateMissirayEntryScene:               ; was: loc_F8E6
                bra.w   StageTransition_UpdateMissirayParallax
; End of function StageTransition_WaitForMissirayObjectClear
; Waits for the Missiray message and shared activity signals before leaving the scene
StageTransition_WaitForMissirayExitSignals:             ; was: sub_F8EA
                bsr.w   StageTransition_UpdateMissirayParallax
                tst.w   (MessageSequenceState).w
                bne.s   StageTransition_MissirayExitWaitReturn
                tst.w   (GameplayExitMode).w
                bne.s   StageTransition_MissirayExitWaitReturn
                tst.w   (ScriptedInputActive).w
                bne.s   StageTransition_MissirayExitWaitReturn
                move.b  #$9F,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; ---------------------------------------------------------------------------
StageTransition_MissirayExitWaitReturn:                 ; was: locret_F912
                                        ; StageTransition_WaitForMissirayExitSignals+E   j
                rts
; End of function StageTransition_WaitForMissirayExitSignals
; Applies the Missiray scene's full-, half-, and quarter-speed vertical parallax
StageTransition_UpdateMissirayParallax:                 ; was: sub_F914
                                        ; StageTransition_LoadMissirayAssets   p
                move.l  (MissirayParallaxSpeed).w,d0
                sub.l   d0,(PrimaryCameraYPosition).w
                move.w  (PrimaryCameraYPosition).w,d0
                move.w  d0,d1
                move.w  d0,d2
                asr.w   #1,d1
                asr.w   #2,d2
                move.w  d0,(VScrollBuffer).w
                move.w  d0,(VScrollPlaneAColumn1).w
                move.w  d0,(VScrollPlaneAColumn18).w
                move.w  d0,(VScrollPlaneAColumn19).w
                move.w  d1,(VScrollPlaneAColumn2).w
                move.w  d1,(VScrollPlaneAColumn17).w
                movea.w #(VScrollPlaneAColumn3-M68K_RAM),a0
                moveq   #$D,d7
StageTransition_FillMissirayQuarterSpeedVScroll:        ; was: loc_F946
                move.w  d2,(a0)
                addq.w  #4,a0
                dbf     d7,StageTransition_FillMissirayQuarterSpeedVScroll
                rts
; End of function StageTransition_UpdateMissirayParallax
; Updates either member of the linked Missiray scene-object pair
StageTransition_UpdateMissiraySceneObject:              ; was: sub_F950
                move.b  (PlayerOAMBucketOffset).w,$20(a5)
                subq.b  #4,$20(a5)
                tst.w   $56(a5)
                bne.s   StageTransition_MissiraySceneObjectReturn
                bclr    #0,6(a5)
                beq.s   StageTransition_SyncMissiraySceneObjectHeight
                tst.w   (ShootingMode).w
                beq.s   StageTransition_CheckMissiraySceneUpInput
                btst    #2,(PlayerActionStateFlags).w
                bne.s   StageTransition_SyncMissiraySceneObjectHeight
StageTransition_CheckMissiraySceneUpInput:              ; was: loc_F976
                btst    #0,(ControllerHeldState).w
                beq.s   StageTransition_CheckMissiraySceneDownInput
                subq.w  #1,$14(a5)
                cmpi.w  #$D0,$14(a5)
                bpl.s   StageTransition_SyncMissiraySceneObjectHeight
                move.w  #$D0,$14(a5)
StageTransition_CheckMissiraySceneDownInput:            ; was: loc_F990
                btst    #1,(ControllerHeldState).w
                beq.s   StageTransition_SyncMissiraySceneObjectHeight
                addq.w  #1,$14(a5)
                cmpi.w  #$160,$14(a5)
                bmi.s   StageTransition_SyncMissiraySceneObjectHeight
                move.w  #$160,$14(a5)
StageTransition_SyncMissiraySceneObjectHeight:          ; was: loc_F9AA
                                        ; StageTransition_UpdateMissiraySceneObject+24   j
                movea.w #(Entity58Type-M68K_RAM),a0
                move.w  $14(a5),$14(a0)
StageTransition_MissiraySceneObjectReturn:              ; was: locret_F9B4
                rts
; End of function StageTransition_UpdateMissiraySceneObject
; Initializes the Stage 24 scene objects, vertical range, and sound
StageTransition_InitializeStage24SceneObjects:          ; was: sub_F9B6
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                movea.w #(Entity57Type-M68K_RAM),a0
                move.w  #$410,(a0)
                move.w  #$256,$10(a0)
                move.w  #$60,$14(a0)                    ; '`'
                movea.w #(Entity58Type-M68K_RAM),a0
                move.w  #$10,(a0)
                move.w  #$C500,2(a0)
                move.w  #$AC0,$E(a0)
                move.b  #$10,$20(a0)
                move.l  #Stage24SceneObjectSpriteMapping,8(a0)
                move.w  #0,(CameraXLowerBound).w
                move.w  #$C0,(CameraXUpperBound).w
                clr.l   (Stage24VScrollSpeed).w
                move.b  #$C9,d0
                jsr     (Sound_QueueSFXRequest).l
; End of function StageTransition_InitializeStage24SceneObjects
; Accelerates the Stage 24 vertical scroll until coordinate $C0
StageTransition_AccelerateStage24VerticalScroll:        ; was: sub_FA0E
                cmpi.w  #2,(Stage24VScrollSpeed).w
                bpl.s   StageTransition_ApplyStage24VerticalScroll
                addi.l  #$1000,(Stage24VScrollSpeed).w
StageTransition_ApplyStage24VerticalScroll:             ; was: loc_FA1E
                move.l  (Stage24VScrollSpeed).w,d0
                add.l   d0,(PrimaryCameraXPosition).w
                cmpi.w  #$C0,(PrimaryCameraXPosition).w
                bmi.s   StageTransition_Stage24VerticalScrollReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$C0,(PrimaryCameraXPosition).w
StageTransition_Stage24VerticalScrollReturn:            ; was: locret_FA38
                rts
; End of function StageTransition_AccelerateStage24VerticalScroll
; Derives and clamps the Stage 24 vertical offset from the first scene object
StageTransition_UpdateStage24VerticalOffset:            ; was: sub_FA3A
                move.w  #$100,d0
                sub.w   (Entity57YPos).w,d0
                bmi.s   StageTransition_CheckStage24VerticalOffsetLimit
                moveq   #0,d0
StageTransition_CheckStage24VerticalOffsetLimit:        ; was: loc_FA46
                cmpi.w  #$FFE0,d0
                bpl.s   StageTransition_StoreStage24VerticalOffset
                addq.w  #2,(StageStateOffset).w
                move.w  #$FFE0,d0
StageTransition_StoreStage24VerticalOffset:             ; was: loc_FA54
                move.w  d0,(PrimaryCameraYPosition).w
                rts
; End of function StageTransition_UpdateStage24VerticalOffset
; Waits for Stage 24 completion and shared activity signals before advancing
StageTransition_WaitForStage24CompletionSignals:        ; was: sub_FA5A
                tst.b   (SceneSequenceFlags).w
                beq.s   StageTransition_Stage24CompletionWaitReturn
                tst.w   (GameplayExitMode).w
                bne.s   StageTransition_Stage24CompletionWaitReturn
                tst.w   (ScriptedInputActive).w
                bne.s   StageTransition_Stage24CompletionWaitReturn
                addq.w  #2,(StageTableIndex).w
                move.b  #$8F,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; ---------------------------------------------------------------------------
StageTransition_Stage24CompletionWaitReturn:            ; was: locret_FA82
                                        ; StageTransition_WaitForStage24CompletionSignals+A   j
                rts
; End of function StageTransition_WaitForStage24CompletionSignals
; Advances the global transition state when invoked by its controller object
StageTransition_AdvanceStateFromObject:                 ; was: sub_FA84
                                        ; ROM:0000F15E   o
                addq.w  #2,(StageStateOffset).w
; Shared inert transition state and return after advancing the state
StageTransition_StateAdvanceReturn:                     ; was: locret_FA88
                rts
; End of function StageTransition_AdvanceStateFromObject
StageTransition_InitializeZLeoApproach:                 ; was: sub_FA8A
                addq.w  #2,(StageStateOffset).w
                move.w  #$20,(SecondaryCameraYPos).w    ; ' '
; Updates the Z-Leo approach until the stage position reaches $480
StageTransition_UpdateZLeoApproach:                     ; was: loc_FA94
                bsr.w   Camera_UpdateAndRenderStageTilemap
                bsr.w   StageTransition_UpdateZLeoDerivedScroll
                cmpi.w  #$480,(PrimaryCameraXPosition).w
                bmi.w   StageTransition_SharedReturn
                bra.w   Stage_TransitionToNextPhase
; End of function StageTransition_InitializeZLeoApproach
; Loads the Z-Leo assets after the stage position reaches $500
StageTransition_LoadZLeoAssets:                         ; was: sub_FAAA
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                bsr.w   StageTransition_UpdateZLeoDerivedScroll
                cmpi.w  #$500,(PrimaryCameraXPosition).w
                bmi.w   StageTransition_SharedReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  #$500,d0
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_ZLeoAssetSet).l,a1
                jmp     Boss_LoadAssetSet
; End of function StageTransition_LoadZLeoAssets
; Waits for the object-pool head to clear before triggering the next phase
StageTransition_WaitForZLeoObjectClear:                 ; was: sub_FAE0
                tst.w   (Entity_ObjectPool).w
                bne.s   StageTransition_ZLeoObjectClearWaitReturn
                bsr.w   Stage_StartTimeBonusAndPreloadNextPhase
StageTransition_ZLeoObjectClearWaitReturn:              ; was: locret_FAEA
                rts
; End of function StageTransition_WaitForZLeoObjectClear
; Attributes: thunk
; Updates the derived scroll value for the Z-Leo transition
StageTransition_UpdateZLeoCamera:                       ; was: sub_FAEC
                bra.w   StageTransition_UpdateZLeoDerivedScroll
; End of function StageTransition_UpdateZLeoCamera
; Unreferenced section-change and camera update entry
UnreferencedInitializeSectionAndZLeoCamera:
                bsr.w   Stage_StartNextPhaseBanner      ; was: sub_FAF0
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
; End of function UnreferencedInitializeSectionAndZLeoCamera
; Derives the Z-Leo transition's secondary scroll value from the stage position
StageTransition_UpdateZLeoDerivedScroll:                ; was: sub_FAF8
                                        ; StageTransition_LoadZLeoAssets+4   p
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$300,d0
                asr.w   #4,d0
                move.w  d0,(SecondaryCameraXPos).w
                rts
; End of function StageTransition_UpdateZLeoDerivedScroll
; Transfers control to the Xi-Tiger credits initializer
StageTransition_StartXiTigerCredits:                    ; was: sub_FB08
                move.w  #$8C,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                rts
; End of function StageTransition_StartXiTigerCredits
; Unreferenced helper that advances the transition and seeds vertical scroll
UnreferencedAdvanceTransitionAndSetVerticalScroll:
                addq.w  #2,(StageStateOffset).w         ; was: sub_FB14
                move.w  #$20,(PrimaryCameraYPosition).w  ; ' '
; End of function UnreferencedAdvanceTransitionAndSetVerticalScroll
; Runs the standard scroll update for transition-table state $8C
StageTransition_UpdateStandardScroll:                   ; was: sub_FB1E
                bsr.w   Camera_UpdateAndRenderStageTilemap
                rts
; End of function StageTransition_UpdateStandardScroll
; Renders the asteroid field after updating its scroll state
