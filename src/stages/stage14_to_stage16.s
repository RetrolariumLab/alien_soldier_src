Stage14_InitializeVictorApproach:                       ; DATA XREF: ROM:0000D99C   o  ; was: sub_DE44
                addq.w  #2,(StageStateOffset).w
                move.w  #$50,(MessageSequenceState).w   ; 'P'
; Update Stage 14 scroll to the Victor approach boundary
Stage14_UpdateScrollToVictor:                           ; DATA XREF: ROM:0000D99E   o  ; was: loc_DE4E
                bsr.w   Camera_UpdateAndRenderStageTilemap
                cmpi.w  #$400,(PrimaryCameraXPosition).w
                bmi.w   Stage_MidgameStateReturn
                bra.w   Stage_TransitionToNextPhase
; End of function Stage14_InitializeVictorApproach
; Clamp the Stage 14 camera and submit Victor's asset set
Stage14_InitializeVictorEncounter:                      ; DATA XREF: ROM:0000D9A0   o  ; was: sub_DE60
                bsr.w   Camera_UpdateBossApproachAndRenderTilemap
                move.w  #$480,d0
                cmp.w   (PrimaryCameraXPosition).w,d0
                bpl.w   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                clr.l   (CameraXDelta).w
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d0,(CameraXLowerBound).w
                move.w  d0,(CameraXUpperBound).w
                lea     (Boss_VictorAssetSet).l,a1
                bra.w   Boss_LoadAssetSet
; End of function Stage14_InitializeVictorEncounter
; Wait for Victor to clear, then begin the post-boss delay and preload
Stage14_UpdateVictorEncounter:                          ; DATA XREF: ROM:0000D9A2   o  ; was: sub_DE8E
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage14_UpdateVictorEncounter_Return
                bsr.w   Stage_StartPostBannerDelayAndPreloadNextPhase
                clr.w   (SecondaryCameraXPos).w
                clr.w   (SecondaryCameraYPos).w
Stage14_UpdateVictorEncounter_Return:                   ; CODE XREF: Stage14_UpdateVictorEncounter+4   j  ; was: locret_DEA0
                rts
; End of function Stage14_UpdateVictorEncounter
; Start the final Stage 14 post-Victor transition state
Stage14_StartPostVictorTransition:                      ; DATA XREF: ROM:0000D9A4   o  ; was: sub_DEA2
                bsr.w   Stage_StartNextPhaseBanner
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage14_StartPostVictorTransition
; Scroll Stage 15 to the Sunset Sting approach boundary
Stage15_UpdateScrollToSunsetSting:                      ; DATA XREF: ROM:0000D9A6   o  ; was: sub_DEAA
                bsr.w   Camera_UpdateAndRenderStageTilemap
                cmpi.w  #$660,(PrimaryCameraXPosition).w
                bmi.w   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                move.w  #$660,(PrimaryCameraXPosition).w
                bset    #6,(PlayerRestrictionFlags).w
                rts
; End of function Stage15_UpdateScrollToSunsetSting
; Advance the Stage 15 Sylpheed backdrop to the encounter transition
Stage15_UpdateSunsetStingApproach:                      ; DATA XREF: ROM:0000D9A8   o  ; was: sub_DECA
                bsr.w   Scroll_UpdateAndRenderSylpheedBackdrop
                cmpi.w  #$E3E8,(PrimaryCameraYPosition).w
                bmi.w   Stage_MidgameStateReturn
                if      BuildProfileEU
                clr.w   (Stage15SunsetStingAssetDelay).w
                endif
                bclr    #0,(PaletteFadeControlFlags).w
                move.w  #$FFE4,(MidgameFadeLevel).w
                move.w  #6,(PaletteSecondaryIndex).w
                bra.w   Stage_TransitionToNextPhase
; End of function Stage15_UpdateSunsetStingApproach
; Clamp Stage 15 and submit Sunset Sting's asset set
Stage15_InitializeSunsetStingEncounter:                 ; DATA XREF: ROM:0000D9AA   o  ; was: sub_DEEE
                if      BuildProfileEU
                tst.w   (Stage15SunsetStingAssetDelay).w
                beq.s   Stage15_ClampSunsetStingEncounter
                subq.w  #1,(Stage15SunsetStingAssetDelay).w
                bne.w   Stage_MidgameStateReturn
                addq.w  #2,(StageStateOffset).w
                lea     (Boss_SunsetStingAssetSet).l,a1
                bra.w   Boss_LoadAssetSet
Stage15_ClampSunsetStingEncounter:
                endif
                bsr.w   Scroll_AdvanceVerticalAndRenderSylpheedBackdrop
                move.w  #$E420,d0
                cmp.w   (PrimaryCameraYPosition).w,d0
                bpl.w   Stage_MidgameStateReturn
                if      BuildProfileJP
                addq.w  #2,(StageStateOffset).w
                endif
                move.w  d0,(PrimaryCameraYPosition).w
                move.w  #$660,(CameraXLowerBound).w
                move.w  #$660,(CameraXUpperBound).w
                if      BuildProfileEU
                move.w  #$20,(Stage15SunsetStingAssetDelay).w
                move.b  #1,(SoundFadeOutDelay).w
                endif
                moveq   #0,d0
                moveq   #0,d1
                if      BuildProfileEU
                jmp     (Object_ClearEntityRecordsExceptTwoTypes).l
                else
                jsr     (Object_ClearEntityRecordsExceptTwoTypes).l
                lea     (Boss_SunsetStingAssetSet).l,a1
                bra.w   Boss_LoadAssetSet
                endif
; End of function Stage15_InitializeSunsetStingEncounter
; Wait for Sunset Sting to clear, then start the time bonus and preload
Stage15_UpdateSunsetStingEncounter:                     ; DATA XREF: ROM:0000D9AC   o  ; was: sub_DF26
                tst.w   (Entity_ObjectPool).w
                bne.s   Stage15_UpdateSunsetStingEncounter_FollowPlayer
                bsr.w   Stage_StartTimeBonusAndPreloadNextPhase
Stage15_UpdateSunsetStingEncounter_FollowPlayer:        ; CODE XREF: Stage15_UpdateSunsetStingEncounter+4   j  ; was: loc_DF30
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage15_UpdateSunsetStingEncounter
; Start the final Stage 15 post-Sunset-Sting transition state
Stage15_StartPostSunsetStingTransition:                 ; DATA XREF: ROM:0000D9AE   o  ; was: sub_DF34
                bsr.w   Stage_StartNextPhaseBanner
                bra.w   Camera_UpdateHorizontalTowardsPlayer
; End of function Stage15_StartPostSunsetStingTransition
; Scroll Stage 16 vertically to the Viblack encounter boundary
Stage16_UpdateScrollToViblack:                          ; DATA XREF: ROM:0000D9B0   o  ; was: sub_DF3C
                cmpi.w  #$E440,(PrimaryCameraYPosition).w
                bpl.s   Stage16_BeginViblackEncounter
                move.l  (PrimaryCameraXPosition).w,(Stage16CameraSnapshot).w
                move.w  #$660,(PrimaryCameraXPosition).w
                bsr.w   Scroll_AdvanceVerticalAndRenderSylpheedBackdrop
                move.l  (Stage16CameraSnapshot).w,(PrimaryCameraXPosition).w
                bra.w   Camera_FollowPlayerFromFixedHorizontalAnchor
; End of function Stage16_UpdateScrollToViblack
; Start Viblack's BGM and fall through to object creation
Stage16_BeginViblackEncounter:                          ; CODE XREF: Stage16_UpdateScrollToViblack+6   j  ; was: sub_DF5E
                addq.w  #2,(StageStateOffset).w
                move.b  #$8B,d0
                jsr     (Sound_QueueBGMOrStop).l
; Create Viblack and initialize the Stage 16 encounter fields
Stage16_CreateViblackEncounter:                         ; DATA XREF: ROM:0000D9B2   o  ; was: sub_DF6C
                addq.w  #2,(StageStateOffset).w
                move.w  #$2B8,(Entity_ObjectPool).w
                clr.w   (PrimaryEntityState).w
                clr.l   (PostViblackVScrollVel).w
                clr.w   (PostViblackPalettePos).w
                move.b  #$80,(CameraMotionLockFlags).w
                move.w  #$2E,(PlayerScriptStateOffset).w  ; '.'
; End of function Stage16_BeginViblackEncounter
; Attributes: thunk
; Keep the Stage 16 encounter camera on the fixed horizontal anchor
Stage16_UpdateViblackEncounterCamera:                   ; DATA XREF: ROM:0000D9B4   o  ; was: sub_DF8E
                bra.w   Camera_FollowPlayerFromFixedHorizontalAnchor
; End of function Stage16_UpdateViblackEncounterCamera
; Accelerate the Stage 16 vertical scroll after Viblack
Stage16_StartPostViblackTransition:                     ; DATA XREF: ROM:0000D9B6   o  ; was: sub_DF92
                cmpi.w  #5,(PostViblackVScrollVel).w
                bpl.s   Stage16_StartPostViblackTransition_ApplyVerticalVelocity
                addi.l  #$C00,(PostViblackVScrollVel).w
Stage16_StartPostViblackTransition_ApplyVerticalVelocity:  ; CODE XREF: Stage16_StartPostViblackTransition+6   j  ; was: loc_DFA2
                move.l  (PostViblackVScrollVel).w,d0
                add.l   d0,(PrimaryCameraYPosition).w
                move.l  (PrimaryCameraXPosition).w,(Stage16CameraSnapshot).w
                move.w  #$660,(PrimaryCameraXPosition).w
                bsr.w   Tilemap_QueuePrimaryCameraRowOffset60
                move.l  (Stage16CameraSnapshot).w,(PrimaryCameraXPosition).w
                bsr.w   Camera_FollowPlayerFromFixedHorizontalAnchor
                cmpi.w  #$E620,(PrimaryCameraYPosition).w
                bmi.s   Stage16_StartPostViblackTransition_Return
                addq.w  #2,(StageStateOffset).w
Stage16_StartPostViblackTransition_Return:              ; CODE XREF: Stage16_StartPostViblackTransition+38   j  ; was: locret_DFD0
                rts
; End of function Stage16_StartPostViblackTransition
; Continue the Stage 16 vertical scroll after Viblack
Stage16_ContinuePostViblackVerticalScroll:              ; DATA XREF: ROM:0000D9B8   o  ; was: sub_DFD2
                move.l  (PostViblackVScrollVel).w,d0
                add.l   d0,(PrimaryCameraYPosition).w
                bra.w   Camera_FollowPlayerFromFixedHorizontalAnchor
; End of function Stage16_ContinuePostViblackVerticalScroll
; Center the Stage 16 camera while advancing the post-Viblack palette effect
Stage16_UpdatePostViblackCameraAndPalette:              ; DATA XREF: ROM:0000D9BA   o  ; was: sub_DFDE
                bset    #1,(PaletteFadeControlFlags).w
                move.l  (PostViblackVScrollVel).w,d0
                add.l   d0,(PrimaryCameraYPosition).w
                move.w  #5,(PaletteEffectControl).w
                subq.w  #1,(PostViblackPalettePos).w
                cmpi.w  #$FFF2,(PostViblackPalettePos).w
                bpl.s   Stage16_UpdatePostViblackCameraAndPalette_ApplyFade
                move.w  #$FFF2,(PostViblackPalettePos).w
                cmpi.w  #$660,(PrimaryCameraXPosition).w
                bne.s   Stage16_UpdatePostViblackCameraAndPalette_ApplyFade
                addq.w  #2,(StageStateOffset).w
                move.w  #$660,(CameraXLowerBound).w
                move.w  #$660,(CameraXUpperBound).w
                lea     (ViblackPostBattleScrollPaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
Stage16_UpdatePostViblackCameraAndPalette_ApplyFade:    ; CODE XREF: Stage16_UpdatePostViblackCameraAndPalette+1E   j  ; was: loc_E028
                                        ; Stage16_UpdatePostViblackCameraAndPalette+2C   j
                move.w  (PostViblackPalettePos).w,d0
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a0
                moveq   #$E,d5
                move.w  #$E000,d7
                jsr     (Gfx_ApplyPaletteFade).l
                clr.w   (PrimaryCameraXPosition+2).w
                cmpi.w  #$660,(PrimaryCameraXPosition).w
                beq.s   Stage16_UpdatePostViblackCameraAndPalette_Return
                bpl.s   Stage16_UpdatePostViblackCameraAndPalette_MoveCameraLeft
                addq.w  #1,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Stage16_UpdatePostViblackCameraAndPalette_MoveCameraLeft:  ; CODE XREF: Stage16_UpdatePostViblackCameraAndPalette+6A   j  ; was: loc_E050
                subq.w  #1,(PrimaryCameraXPosition).w
Stage16_UpdatePostViblackCameraAndPalette_Return:       ; CODE XREF: Stage16_UpdatePostViblackCameraAndPalette+68   j  ; was: locret_E054
                rts
; End of function Stage16_UpdatePostViblackCameraAndPalette
; Initialize the post-Viblack tilemap-row stream
Stage16_InitializePostViblackTilemapStreaming:          ; DATA XREF: ROM:0000D9BC   o  ; was: sub_E056
                addq.w  #2,(StageStateOffset).w
                move.w  #$FF80,d0
                move.w  d0,(PrimaryCameraYPosition).w
                move.w  d0,(PreviousCameraYPosition).w
                clr.w   (CameraYDelta).w
                move.l  #Gfx_DefaultVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #$1000,(TilemapRowXOrFillWord).w
                move.w  #0,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
; Queue post-Viblack tilemap rows until the stream counter expires
Stage16_UpdatePostViblackTilemapStreaming:              ; DATA XREF: ROM:0000D9BE   o  ; was: loc_E084
                jsr     (Tilemap_QueueNextScrollingRow).l
                tst.w   (TilemapRowCountdown).w
                bpl.s   Stage16_UpdatePostViblackTilemapStreaming_Return
                addq.w  #2,(StageStateOffset).w
                clr.w   (PostViblackPalettePos).w
Stage16_UpdatePostViblackTilemapStreaming_Return:       ; CODE XREF: Stage16_InitializePostViblackTilemapStreaming+38   j  ; was: locret_E098
                rts
; End of function Stage16_InitializePostViblackTilemapStreaming
; Hold the post-Viblack vertical offset at 20
Stage16_HoldPostViblackVerticalOffset:                  ; DATA XREF: ROM:0000D9C0   o  ; was: sub_E09A
                move.w  #$14,(PostViblackPaletteDelay).w
                rts
; End of function Stage16_HoldPostViblackVerticalOffset
; Step the post-Viblack palette toward its target after the delay expires
Stage16_UpdatePostViblackPaletteTransition:             ; DATA XREF: ROM:0000D9C2   o  ; was: sub_E0A2
                subq.w  #1,(PostViblackPaletteDelay).w
                bmi.s   Stage16_UpdatePostViblackPaletteTransition_BeginStep
                rts
; ---------------------------------------------------------------------------
Stage16_UpdatePostViblackPaletteTransition_BeginStep:   ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+4   j  ; was: loc_E0AA
                bsr.w   Stage16_DeceleratePostViblackVerticalScroll
                movea.w #(PaletteActiveColor17Hi-M68K_RAM),a0
                movea.w #(PaletteShadowPair16+2-M68K_RAM),a1
                move.w  (PostViblackPalettePos).w,d0
                asr.w   #1,d0
                andi.w  #$1E,d0
                cmpi.w  #$1E,d0
                beq.s   Stage16_UpdatePostViblackPaletteTransition_UpdateWords
                addq.w  #2,(PostViblackPalettePos).w
                move.w  #$4000,(a0,d0.w)
Stage16_UpdatePostViblackPaletteTransition_UpdateWords:  ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+22   j  ; was: loc_E0D0
                moveq   #0,d5
                moveq   #0,d6
                moveq   #$B,d7
Stage16_UpdatePostViblackPaletteTransition_Loop:        ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+58   j  ; was: loc_E0D6
                move.w  (a0,d5.w),d0
                beq.s   Stage16_UpdatePostViblackPaletteTransition_NextWord
                cmp.w   (a1,d5.w),d0
                beq.s   Stage16_UpdatePostViblackPaletteTransition_CountMatch
                subi.w  #$300,d0
                bpl.s   Stage16_UpdatePostViblackPaletteTransition_StoreWord
                move.w  (a1,d5.w),(a0,d5.w)
                bra.s   Stage16_UpdatePostViblackPaletteTransition_NextWord
; ---------------------------------------------------------------------------
Stage16_UpdatePostViblackPaletteTransition_StoreWord:   ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+44   j  ; was: loc_E0F0
                move.w  d0,(a0,d5.w)
                bra.s   Stage16_UpdatePostViblackPaletteTransition_NextWord
; ---------------------------------------------------------------------------
Stage16_UpdatePostViblackPaletteTransition_CountMatch:  ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+3E   j  ; was: loc_E0F6
                addq.w  #1,d6
Stage16_UpdatePostViblackPaletteTransition_NextWord:    ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+38   j  ; was: loc_E0F8
                                        ; Stage16_UpdatePostViblackPaletteTransition+4C   j
                addq.w  #2,d5
                dbf     d7,Stage16_UpdatePostViblackPaletteTransition_Loop
                cmpi.w  #$C,d6
                bmi.s   Stage16_UpdatePostViblackPaletteTransition_Return
                addq.w  #2,(StageStateOffset).w
                move.b  #$18,(PlayerOAMBucketOffset).w
Stage16_UpdatePostViblackPaletteTransition_Return:      ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition+60   j  ; was: locret_E10E
                rts
; End of function Stage16_UpdatePostViblackPaletteTransition
; Decelerate the post-Viblack vertical scroll toward zero
Stage16_DeceleratePostViblackVerticalScroll:            ; CODE XREF: Stage16_UpdatePostViblackPaletteTransition_BeginStep   p  ; was: sub_E110
                                        ; DATA XREF: ROM:0000D9C4   o
                tst.w   (PrimaryCameraYPosition).w
                beq.s   Stage16_DeceleratePostViblackVerticalScroll_Return
                addq.w  #8,(PrimaryCameraYPosition).w
Stage16_DeceleratePostViblackVerticalScroll_Return:     ; CODE XREF: Stage16_DeceleratePostViblackVerticalScroll+4   j  ; was: locret_E11A
                rts
; End of function Stage16_DeceleratePostViblackVerticalScroll
; Stage initialization and transition
