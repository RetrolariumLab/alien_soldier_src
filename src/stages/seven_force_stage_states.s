Stage_SevenForceInitializeStage20:                      ; was: sub_E7D8
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                move.w  #$50,(MessageSequenceState).w   ; 'P'
                bset    #1,(PaletteFadeControlFlags).w
                move.w  #$36,(PlayerScriptStateOffset).w  ; '6'
                bsr.w   Gfx_FillStage20PlaneBuffers
                move.w  #$6A0,(PrimaryCameraXPosition).w
                move.w  (PrimaryCameraXPosition).w,(CameraXLowerBound).w
                move.w  (PrimaryCameraXPosition).w,(CameraXUpperBound).w
                move.w  (PrimaryCameraXPosition).w,(PreviousCameraXPosition).w
                movea.w #(Entity60Type-M68K_RAM),a0
                move.w  #$428,(a0)
                move.w  #2,4(a0)
                move.b  #2,(VDPReg11Shadow+1).w
                move.b  #4,(PlaneAScrollModeFlags).w
                move.b  #3,(PlaneBScrollModeFlags).w
                rts
; End of function Stage_SevenForceInitializeStage20
; Update the Stage 20 camera and parallax until the next transition is ready
Stage_SevenForceUpdateStage20Scroll:                    ; was: sub_E830
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceStage20UpdateCamera
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Stage_SevenForceStage20UpdateCamera:                    ; was: loc_E83E
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                bra.w   Gfx_UpdateSevenForceParallaxRows
; End of function Stage_SevenForceUpdateStage20Scroll
; Transition to Medusa form
Stage_SevenForceAdvanceToMedusa:                        ; was: sub_E846
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceUpdateMedusaCamera
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Stage_SevenForceUpdateMedusaCamera:                     ; was: loc_E854
                bra.w   Stage_SevenForceUpdateMedusaCameraAndParallax
; End of function Stage_SevenForceAdvanceToMedusa
; Brake the Medusa scroll before initializing the Sylpheed transition
Stage_SevenForceFinishMedusaScroll:                     ; was: sub_E858
                subi.l  #$1400,(SevenForceMedusaSpeed).w
                bpl.s   Stage_SevenForceApplyMedusaScroll
                addq.w  #2,(StageStateOffset).w
                clr.l   (SevenForceMedusaSpeed).w
Stage_SevenForceApplyMedusaScroll:                      ; was: loc_E86A
                move.l  (SevenForceMedusaSpeed).w,d0
                sub.l   d0,(PrimaryCameraXPosition).w
                bra.w   Stage_SevenForceWrapVerticalCamera
; End of function Stage_SevenForceFinishMedusaScroll
; Initialize the Sylpheed scroll velocities and plane modes
Stage_SevenForceInitializeSylpheedScroll:               ; was: sub_E876
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceInitializeSylpheedScrollReturn
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                clr.l   (SevenForcePlaneASpeed).w
                clr.l   (SevenForcePlaneBSpeed).w
                bsr.w   Gfx_ClearSylpheedPlaneModes
Stage_SevenForceInitializeSylpheedScrollReturn:         ; was: locret_E890
                rts
; End of function Stage_SevenForceInitializeSylpheedScroll
; Update both Sylpheed scrolling planes and wait for completion
Stage_SevenForceUpdateSylpheedScroll:                   ; was: sub_E892
                bsr.w   Stage_SevenForceUpdateSylpheedPrimaryPlane
                bsr.w   Stage_SevenForceUpdateSylpheedSecondaryPlane
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceUpdateSylpheedScrollReturn
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Stage_SevenForceUpdateSylpheedScrollReturn:             ; was: locret_E8A8
                rts
; End of function Stage_SevenForceUpdateSylpheedScroll
; Advance the Sylpheed scroll and continue its foreground update
Stage_SevenForceAdvanceSylpheedForeground:              ; was: sub_E8AA
                bsr.w   Stage_SevenForceUpdateSylpheedSecondaryPlane
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceUpdateSylpheedForeground
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Stage_SevenForceUpdateSylpheedForeground:               ; was: loc_E8BC
                                        ; Stage_SevenForceFinishSylpheedForeground+18   j
                bra.w   Stage_SevenForceUpdateSylpheedForegroundScroll
; End of function Stage_SevenForceAdvanceSylpheedForeground
; Finish the Sylpheed foreground transition or continue scrolling it
Stage_SevenForceFinishSylpheedForeground:               ; was: sub_E8C0
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceContinueSylpheedForeground
                addq.w  #2,(StageStateOffset).w
                move.w  #$20,(SevenForceTimer).w        ; ' '
                bra.w   Stage_SevenForceInitializeArtemisCameraAndAssets
; ---------------------------------------------------------------------------
Stage_SevenForceContinueSylpheedForeground:             ; was: loc_E8D4
                bsr.w   Stage_SevenForceAdvanceSylpheedSecondaryScroll
                bra.w   Stage_SevenForceUpdateSylpheedForeground
; End of function Stage_SevenForceFinishSylpheedForeground
; Transition to Artemis form
Stage_SevenForceBeginArtemisTransition:                 ; was: sub_E8DC
                bsr.w   Gfx_ArtemisInitializeTilemap
                bsr.w   Stage_SevenForceDampenHorizontalVelocity
                subq.w  #1,(SevenForceTimer).w
                bpl.s   Stage_SevenForceBeginArtemisTransitionReturn
                tst.w   (DataLoaderControl).w
                bmi.s   Stage_SevenForceBeginArtemisTransitionReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (StageMotionXDelta).w
Stage_SevenForceBeginArtemisTransitionReturn:           ; was: locret_E8F8
                                        ; Stage_SevenForceBeginArtemisTransition+12   j
                rts
; End of function Stage_SevenForceBeginArtemisTransition
; Wait for the Artemis background renderer to report completion
Stage_SevenForceWaitForArtemisBackground:               ; was: sub_E8FA
                bsr.w   Gfx_ArtemisUpdateBackground
                bpl.s   Stage_SevenForceWaitForArtemisBackgroundReturn
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Stage_SevenForceWaitForArtemisBackgroundReturn:         ; was: locret_E908
                rts
; End of function Stage_SevenForceWaitForArtemisBackground
; Wait for the shared trigger before advancing the Artemis transition
Stage_SevenForceWaitForArtemisTrigger:                  ; was: sub_E90A
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceWaitForArtemisTriggerReturn
                addq.w  #2,(StageStateOffset).w
Stage_SevenForceWaitForArtemisTriggerReturn:            ; was: locret_E914
                rts
; End of function Stage_SevenForceWaitForArtemisTrigger
; Scroll the Artemis background to its target position
Stage_SevenForceScrollArtemisBackground:                ; was: sub_E916
                bsr.w   Stage_SevenForceUpdateArtemisBackgroundPlane
                cmpi.w  #$E200,(PrimaryCameraYPosition).w
                bne.s   Stage_SevenForceScrollArtemisBackgroundReturn
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                clr.w   (ArtemisForegroundState).w
Stage_SevenForceScrollArtemisBackgroundReturn:          ; was: locret_E92E
                rts
; End of function Stage_SevenForceScrollArtemisBackground
; Scroll the Artemis foreground and prepare the Sirene transition
Stage_SevenForceScrollArtemisForeground:                ; was: sub_E930
                bsr.w   Stage_SevenForceUpdateArtemisForegroundMotion
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceScrollArtemisForegroundReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$40,(SevenForceTimer).w        ; '@'
                clr.l   (SevenForcePlaneASpeed).w
                clr.l   (SevenForcePlaneBSpeed).w
                move.b  #$F4,d0
                jsr     (Sound_QueueSFXRequest).l
Stage_SevenForceScrollArtemisForegroundReturn:          ; was: locret_E95A
                rts
; End of function Stage_SevenForceScrollArtemisForeground
; Begin the Sirene transition with its countdown, sound, and camera shake
Stage_SevenForceBeginSireneTransition:                  ; was: sub_E95C
                move.w  #2,(PlaneAShakeLevel).w
                subq.w  #1,(SevenForceTimer).w
                bpl.s   Stage_SevenForceUpdateSireneCamera
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                clr.l   (SevenForcePlaneASpeed).w
                move.b  #$F5,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$E400,(PrimaryCameraYPosition).w
                move.w  #$E400,(PreviousCameraYPosition).w
Stage_SevenForceUpdateSireneShake:                      ; was: loc_E98A
                                        ; Stage_SevenForceFinishSireneTransition:Stage_SevenForceFinishSireneShake   j
                move.w  (RandomNumberState).w,d0
                andi.w  #3,d0
                addq.w  #4,d0
                move.w  d0,(PlaneAShakeLevel).w
                move.w  #1,(PlaneBShakeLevel).w
Stage_SevenForceUpdateSireneCamera:                     ; was: loc_E99E
                                        ; Stage_SevenForceWaitBeforeVictory+14   j
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage_SevenForceBeginSireneTransition
; Center the Sirene camera and close its split offsets
Stage_SevenForceCenterSireneCamera:                     ; was: sub_E9A2
                                        ; Stage_SevenForceFinishSireneTransition   p
                move.w  #$60,d0                         ; '`'
                cmp.w   (PrimaryCameraXPosition).w,d0
                beq.s   Stage_SevenForceUpdateSireneSplitOffsets
                bpl.s   Stage_SevenForceMoveSireneCameraRight
                subq.w  #1,(PrimaryCameraXPosition).w
                bra.s   Stage_SevenForceUpdateSireneSplitOffsets
; ---------------------------------------------------------------------------
Stage_SevenForceMoveSireneCameraRight:                  ; was: loc_E9B4
                addq.w  #1,(PrimaryCameraXPosition).w
Stage_SevenForceUpdateSireneSplitOffsets:               ; was: loc_E9B8
                                        ; Stage_SevenForceCenterSireneCamera+10   j
                addq.w  #1,(CameraXLowerBound).w
                subq.w  #1,(CameraXUpperBound).w
                cmp.w   (CameraXLowerBound).w,d0
                bpl.s   Stage_SevenForceCenterSireneCameraReturn
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
Stage_SevenForceCenterSireneCameraReturn:               ; was: locret_E9CE
                rts
; End of function Stage_SevenForceCenterSireneCamera
; Advance the first Sirene scrolling phase and start its linked object
Stage_SevenForceAdvanceSireneTransition:                ; was: sub_E9D0
                bsr.s   Stage_SevenForceCenterSireneCamera
                bsr.w   Stage_SevenForceUpdateSireneSecondaryScroll
                bsr.w   Stage_SevenForceUpdateSirenePrimaryPlane
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceAdvanceSireneShake
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                move.b  #$F6,d0
                jsr     (Sound_QueueSFXRequest).l
                move.w  #$D0,(PlayerXPosition).w
                move.w  #$188,(PlayerYPosition).w
                addq.w  #2,(PrimaryEntityState).w
Stage_SevenForceAdvanceSireneShake:                     ; was: loc_EA02
                bra.w   Stage_SevenForceUpdateSireneShake
; End of function Stage_SevenForceAdvanceSireneTransition
; Finish the Sirene scrolling phase and install the pre-victory timer
Stage_SevenForceFinishSireneTransition:                 ; was: sub_EA06
                bsr.s   Stage_SevenForceCenterSireneCamera
                bsr.w   Stage_SevenForceUpdateSireneSecondaryScroll
                bsr.w   Stage_SevenForceRenderSireneSecondaryPlane
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceFinishSireneShake
                addq.w  #2,(StageStateOffset).w
                move.w  #$40,(SevenForceTimer).w        ; '@'
Stage_SevenForceFinishSireneShake:                      ; was: loc_EA20
                bra.w   Stage_SevenForceUpdateSireneShake
; End of function Stage_SevenForceFinishSireneTransition
; Count down the final Sirene hold before the victory sequence
Stage_SevenForceWaitBeforeVictory:                      ; was: sub_EA24
                subq.w  #1,(SevenForceTimer).w
                bpl.s   Stage_SevenForceWaitBeforeVictoryUpdateCamera
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Stage_SevenForceWaitBeforeVictoryUpdateCamera:          ; was: loc_EA32
                move.w  #2,(PlaneAShakeLevel).w
                bra.w   Stage_SevenForceUpdateSireneCamera
; Initialize the tilemap and timer for the Seven Force victory sequence
Stage_SevenForceInitializeVictoryTransition:            ; was: sub_EA3C
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                tst.b   (SceneSequenceFlags).w
                beq.s   Stage_SevenForceInitializeVictoryTransitionReturn
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                move.w  #$40,(SevenForceCloseSpan).w    ; '@'
                clr.w   (SecondaryCameraXPos).w
                movea.l #SharedTilemapWorkspace,a0
                move.w  #$A000,d0
                move.w  #0,d1
                moveq   #$7E,d7                         ; '~'
                jsr     (Gfx_UpdateTilemapIndices).l
                move.w  #$8000,(GlobalSpritePriorityBit).w
Stage_SevenForceInitializeVictoryTransitionReturn:      ; was: locret_EA74
                rts
; End of function Stage_SevenForceInitializeVictoryTransition
