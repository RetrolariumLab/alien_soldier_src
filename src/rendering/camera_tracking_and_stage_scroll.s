; Updates Stage 18 scroll and renders both tilemap passes
Stage18_UpdateScrollAndRenderTilemap:                   ; CODE XREF: Stage18_UpdateInitialScroll+6   p  ; was: sub_10026
                                        ; sub_E4FC   p
                bsr.w   Camera_FollowPlayerBeyondHorizontalThreshold
Stage18_RenderLockedTilemap:                            ; CODE XREF: Stage18_UpdateDestroyerMk2Scroll+1A   j  ; was: loc_1002A
                bsr.w   Tilemap_PopulateStage18UnqueuedColumn
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$158,d0
                move.w  (PrimaryCameraYPosition).w,d1
                lea     Gfx_DefaultVRAMTransferParameters(pc),a0
                nop
                bra.w   Tilemap_QueueColumnFromDescriptor
; End of function Stage18_UpdateScrollAndRenderTilemap
; Advances the Destroyer-Mk2 approach scroll and renders the Stage 18 tilemap
Stage18_UpdateDestroyerMk2Scroll:                       ; CODE XREF: Stage18_InitializeDestroyerMk2Encounter   p  ; was: sub_10044
                cmpi.w  #$91,(PlayerXPosition).w
                bpl.s   Stage18_AdvanceDestroyerMk2Scroll
                btst    #1,(PlayerWallContactFlags).w
                beq.s   Stage18_AdvanceDestroyerMk2Scroll
                rts
; ---------------------------------------------------------------------------
Stage18_AdvanceDestroyerMk2Scroll:                      ; CODE XREF: Stage18_UpdateDestroyerMk2Scroll+6   j  ; was: loc_10056
                                        ; Stage18_UpdateDestroyerMk2Scroll+E   j
                addi.l  #$10000,(PrimaryCameraXPosition).w
                bra.s   Stage18_RenderLockedTilemap
; End of function Stage18_UpdateDestroyerMk2Scroll
; Updates horizontal camera follow and renders the stage tilemap
Camera_UpdateAndRenderStageTilemap:                     ; CODE XREF: Stage_UpdateLogic:Stage1_UpdateScrollToJetsripper   p  ; was: sub_10060
                                        ; sub_C92E   p
                bsr.w   Camera_FollowPlayerBeyondHorizontalThreshold
                bra.w   Tilemap_QueuePrimaryCameraColumnOffset158
; End of function Camera_UpdateAndRenderStageTilemap
; Advances boss-approach scroll when allowed and renders the stage tilemap
Camera_UpdateBossApproachAndRenderTilemap:              ; CODE XREF: Stage_InitBossIntro   p  ; was: sub_10068
                                        ; sub_C944   p
                cmpi.w  #$91,(PlayerXPosition).w
                bpl.s   Camera_AdvanceBossApproachScroll
                btst    #1,(PlayerWallContactFlags).w
                beq.s   Camera_AdvanceBossApproachScroll
                rts
; ---------------------------------------------------------------------------
Camera_AdvanceBossApproachScroll:                       ; CODE XREF: Camera_UpdateBossApproachAndRenderTilemap+6   j  ; was: loc_1007A
                                        ; Camera_UpdateBossApproachAndRenderTilemap+E   j
                addi.l  #$10000,(PrimaryCameraXPosition).w
                bra.w   Tilemap_QueuePrimaryCameraColumnOffset158
; End of function Camera_UpdateBossApproachAndRenderTilemap
; Updates the horizontal camera position towards the player
Camera_UpdateHorizontalTowardsPlayer:                   ; CODE XREF: Camera_BossPhaseHandler:Stage1_UpdateJetsripperCamera   p  ; was: sub_10086
                                        ; Camera_Stage2PhaseHandler+4   p
                btst    #5,(PlayerActionStateFlags).w
                bne.w   Camera_HorizontalUpdateReturn
                tst.w   (a5)
                beq.w   Camera_HorizontalUpdateReturn
                moveq   #0,d0
                move.l  (PrimaryCameraXPosition).w,d6
                bra.w   Camera_SmoothHorizontalFollowPlayer
; End of function Camera_UpdateHorizontalTowardsPlayer
; Unreferenced horizontal follow variant with explicit camera bounds
UnreferencedCameraFollowWithinHorizontalBounds:
                move.w  $10(a5),d0                      ; was: sub_100A0
                subi.w  #$130,d0
                bmi.s   UnreferencedCameraCheckNegativeBoundedDelta
                swap    d0
                asr.l   #4,d0
                cmpi.l  #$60000,d0
                bmi.s   UnreferencedCameraApplyPositiveBoundedDelta
                move.l  #$60000,d0
UnreferencedCameraApplyPositiveBoundedDelta:            ; CODE XREF: UnreferencedCameraFollowWithinHorizontalBounds+14   j  ; was: loc_100BC
                add.l   d0,d6
                moveq   #0,d0
                move.w  (CameraXUpperBound).w,d0
                swap    d0
                cmp.l   d6,d0
                beq.s   UnreferencedCameraClampToUpperHorizontalBound
                bmi.s   UnreferencedCameraClampToUpperHorizontalBound
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
UnreferencedCameraClampToUpperHorizontalBound:          ; CODE XREF: UnreferencedCameraFollowWithinHorizontalBounds+28   j  ; was: loc_100D2
                                        ; UnreferencedCameraFollowWithinHorizontalBounds+2A   j
                move.l  d0,d6
                move.l  d6,(PrimaryCameraXPosition).w
UnreferencedCameraBoundedFollowReturn:                  ; CODE XREF: UnreferencedCameraFollowWithinHorizontalBounds+42   j  ; was: locret_100D8
                rts
; ---------------------------------------------------------------------------
UnreferencedCameraCheckNegativeBoundedDelta:            ; CODE XREF: UnreferencedCameraFollowWithinHorizontalBounds+8   j  ; was: loc_100DA
                move.w  $10(a5),d0
                subi.w  #$110,d0
                bpl.s   UnreferencedCameraBoundedFollowReturn
                swap    d0
                asr.l   #4,d0
                cmpi.l  #$FFFA0000,d0
                bpl.s   UnreferencedCameraApplyNegativeBoundedDelta
                move.l  #$FFFA0000,d0
UnreferencedCameraApplyNegativeBoundedDelta:            ; CODE XREF: UnreferencedCameraFollowWithinHorizontalBounds+4E   j  ; was: loc_100F6
                add.l   d0,d6
                moveq   #0,d0
                move.w  (CameraXLowerBound).w,d0
                swap    d0
                cmp.l   d6,d0
                beq.s   UnreferencedCameraClampToLowerHorizontalBound
                bpl.s   UnreferencedCameraClampToLowerHorizontalBound
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
UnreferencedCameraClampToLowerHorizontalBound:          ; CODE XREF: UnreferencedCameraFollowWithinHorizontalBounds+62   j  ; was: loc_1010C
                                        ; UnreferencedCameraFollowWithinHorizontalBounds+64   j
                move.l  d0,d6
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; End of function UnreferencedCameraFollowWithinHorizontalBounds
; Smoothly follows the player horizontally with speed and camera bounds
Camera_SmoothHorizontalFollowPlayer:                    ; CODE XREF: Camera_UpdateHorizontalTowardsPlayer+16   j  ; was: sub_10114
                moveq   #3,d1
                btst    #3,$E(a5)
                beq.s   Camera_SelectAlternateHorizontalAnchor
                move.w  #$C8,d0
                sub.w   $10(a5),d0
                bpl.s   Camera_ApplyNegativeFollowDelta
                moveq   #4,d1
Camera_ApplyPositiveFollowDelta:                        ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+50   j  ; was: loc_1012A
                neg.w   d0
                swap    d0
                asr.l   d1,d0
                cmpi.l  #$60000,d0
                bmi.s   Camera_ApplyPositiveFollowWithinBounds
                move.l  #$60000,d0
Camera_ApplyPositiveFollowWithinBounds:                 ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+22   j  ; was: loc_1013E
                add.l   d0,d6
                moveq   #0,d0
                move.w  (CameraXUpperBound).w,d0
                swap    d0
                cmp.l   d6,d0
                beq.s   Camera_ClampFollowToUpperHorizontalBound
                bmi.s   Camera_ClampFollowToUpperHorizontalBound
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Camera_ClampFollowToUpperHorizontalBound:               ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+36   j  ; was: loc_10154
                                        ; Camera_SmoothHorizontalFollowPlayer+38   j
                move.l  d0,d6
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Camera_SelectAlternateHorizontalAnchor:                 ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+8   j  ; was: loc_1015C
                move.w  #$178,d0
                sub.w   $10(a5),d0
                bmi.s   Camera_ApplyPositiveFollowDelta
                moveq   #4,d1
Camera_ApplyNegativeFollowDelta:                        ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+12   j  ; was: loc_10168
                neg.w   d0
                swap    d0
                asr.l   d1,d0
                cmpi.l  #$FFFA0000,d0
                bpl.s   Camera_ApplyNegativeFollowWithinBounds
                move.l  #$FFFA0000,d0
Camera_ApplyNegativeFollowWithinBounds:                 ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+60   j  ; was: loc_1017C
                add.l   d0,d6
                moveq   #0,d0
                move.w  (CameraXLowerBound).w,d0
                swap    d0
                cmp.l   d6,d0
                beq.s   Camera_ClampFollowToLowerHorizontalBound
                bpl.s   Camera_ClampFollowToLowerHorizontalBound
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Camera_ClampFollowToLowerHorizontalBound:               ; CODE XREF: Camera_SmoothHorizontalFollowPlayer+74   j  ; was: loc_10192
                                        ; Camera_SmoothHorizontalFollowPlayer+76   j
                move.l  d0,d6
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; End of function Camera_SmoothHorizontalFollowPlayer
; Follows the player from a fixed horizontal anchor within camera bounds
Camera_FollowPlayerFromFixedHorizontalAnchor:           ; CODE XREF: Stage16_UpdateScrollToViblack+1E   j  ; was: sub_1019A
                                        ; sub_DF8E   j
                btst    #5,(PlayerActionStateFlags).w
                bne.w   Camera_HorizontalUpdateReturn
                tst.w   (a5)
                beq.w   Camera_HorizontalUpdateReturn
                moveq   #0,d0
                move.l  (PrimaryCameraXPosition).w,d6
                moveq   #3,d1
                btst    #3,$E(a5)
                beq.s   Camera_FixedAnchorCheckNegativeDelta
                move.w  #$120,d0
                sub.w   $10(a5),d0
                bpl.s   Camera_FixedAnchorApplyNegativeDelta
                moveq   #4,d1
Camera_FixedAnchorApplyPositiveDelta:                   ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+66   j  ; was: loc_101C6
                neg.w   d0
                swap    d0
                asr.l   d1,d0
                cmpi.l  #$60000,d0
                bmi.s   Camera_FixedAnchorApplyPositiveWithinBounds
                move.l  #$60000,d0
Camera_FixedAnchorApplyPositiveWithinBounds:            ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+38   j  ; was: loc_101DA
                add.l   d0,d6
                moveq   #0,d0
                move.w  (CameraXUpperBound).w,d0
                swap    d0
                cmp.l   d6,d0
                beq.s   Camera_FixedAnchorClampToUpperBound
                bmi.s   Camera_FixedAnchorClampToUpperBound
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Camera_FixedAnchorClampToUpperBound:                    ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+4C   j  ; was: loc_101F0
                                        ; Camera_FollowPlayerFromFixedHorizontalAnchor+4E   j
                move.l  d0,d6
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Camera_FixedAnchorCheckNegativeDelta:                   ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+1E   j  ; was: loc_101F8
                move.w  #$120,d0
                sub.w   $10(a5),d0
                bmi.s   Camera_FixedAnchorApplyPositiveDelta
                moveq   #4,d1
Camera_FixedAnchorApplyNegativeDelta:                   ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+28   j  ; was: loc_10204
                neg.w   d0
                swap    d0
                asr.l   d1,d0
                cmpi.l  #$FFFA0000,d0
                bpl.s   Camera_FixedAnchorApplyNegativeWithinBounds
                move.l  #$FFFA0000,d0
Camera_FixedAnchorApplyNegativeWithinBounds:            ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+76   j  ; was: loc_10218
                add.l   d0,d6
                moveq   #0,d0
                move.w  (CameraXLowerBound).w,d0
                swap    d0
                cmp.l   d6,d0
                beq.s   Camera_FixedAnchorClampToLowerBound
                bpl.s   Camera_FixedAnchorClampToLowerBound
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; ---------------------------------------------------------------------------
Camera_FixedAnchorClampToLowerBound:                    ; CODE XREF: Camera_FollowPlayerFromFixedHorizontalAnchor+8A   j  ; was: loc_1022E
                                        ; Camera_FollowPlayerFromFixedHorizontalAnchor+8C   j
                move.l  d0,d6
                move.l  d6,(PrimaryCameraXPosition).w
                rts
; End of function Camera_FollowPlayerFromFixedHorizontalAnchor
; Unreferenced camera adjustment selected by player-state flags
UnreferencedCameraAdjustForPlayerState:
                btst    #5,(PlayerActionStateFlags).w   ; was: sub_10236
                bne.w   Camera_HorizontalUpdateReturn
                tst.w   (a5)
                beq.s   UnreferencedCameraPlayerStateReturn
                moveq   #0,d0
                move.b  $69(a5),d0
                btst    #2,d0
                beq.s   UnreferencedCameraCheckPrimaryStateAnchor
                btst    #4,d0
                bne.s   UnreferencedCameraCheckSecondaryStateAnchor
UnreferencedCameraCheckPrimaryStateAnchor:              ; CODE XREF: UnreferencedCameraAdjustForPlayerState+18   j  ; was: loc_10256
                move.w  $10(a5),d0
                subi.w  #$130,d0
                bpl.s   UnreferencedCameraPlayerStateReturn
                swap    d0
                asr.l   #3,d0
UnreferencedCameraClampPlayerStateDelta:                ; CODE XREF: UnreferencedCameraAdjustForPlayerState+4E   j  ; was: loc_10264
                cmp.l   (CameraDeltaLowerLimit).w,d0
                bpl.s   UnreferencedCameraApplyPlayerStateDelta
                move.l  (CameraDeltaLowerLimit).w,d0
UnreferencedCameraApplyPlayerStateDelta:                ; CODE XREF: UnreferencedCameraAdjustForPlayerState+32   j  ; was: loc_1026E
                add.l   d0,(PrimaryCameraXPosition).w
UnreferencedCameraPlayerStateReturn:                    ; CODE XREF: UnreferencedCameraAdjustForPlayerState+C   j  ; was: locret_10272
                                        ; UnreferencedCameraAdjustForPlayerState+28   j
                rts
; ---------------------------------------------------------------------------
UnreferencedCameraCheckSecondaryStateAnchor:            ; CODE XREF: UnreferencedCameraAdjustForPlayerState+1E   j  ; was: loc_10274
                move.w  #$160,d0
                sub.w   $10(a5),d0
                bmi.s   UnreferencedCameraPlayerStateReturn
                neg.w   d0
                swap    d0
                asr.l   #5,d0
                bra.s   UnreferencedCameraClampPlayerStateDelta
; End of function UnreferencedCameraAdjustForPlayerState
; Updates the Stage 8 train scroll and renders its tilemap
Stage8_UpdateTrainScrollAndTilemap:                     ; CODE XREF: Stage8_UpdateTrainSequence_UpdateScroll   p  ; was: sub_10286
                bsr.w   Camera_FollowPlayerBeyondHorizontalThreshold
Scroll_SynchronizePlanesAndRenderTrainTilemap:          ; CODE XREF: Scroll_AdvanceTrainHorizontalAndRenderTilemap+8   j  ; was: loc_1028A
                move.w  (PrimaryCameraXPosition).w,(SecondaryCameraXPos).w
                move.w  (PrimaryCameraYPosition).w,(SecondaryCameraYPos).w
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$158,d0
                move.w  #$F700,d1
                lea     Gfx_ScrollVRAMTransferParameters(pc),a0
                nop
                jmp     Tilemap_QueueColumnFromDescriptor(pc)  ; (pc)
; End of function Stage8_UpdateTrainScrollAndTilemap
; Unreferenced alternate entry that executes a NOP before the following operation
UnreferencedAdvanceTrainScrollWithNop:
                nop                                     ; was: sub_102AC
; End of function UnreferencedAdvanceTrainScrollWithNop
; Advances train-scene horizontal scroll by one pixel and renders the tilemap
Scroll_AdvanceTrainHorizontalAndRenderTilemap:          ; CODE XREF: Stage8_InitializeFlyingNeoApproach   p  ; was: sub_102AE
                addi.l  #$10000,(PrimaryCameraXPosition).w
                bra.s   Scroll_SynchronizePlanesAndRenderTrainTilemap
; End of function Scroll_AdvanceTrainHorizontalAndRenderTilemap
; Synchronizes the Flying Neo transition scroll and renders its tilemap
Stage8_UpdateFlyingNeoScrollAndTilemap:                 ; CODE XREF: Stage8_UpdateFlyingNeoVerticalScrollAndEffects+2A   p  ; was: sub_102B8
                move.w  (PrimaryCameraXPosition).w,(SecondaryCameraXPos).w
                move.w  (PrimaryCameraYPosition).w,(SecondaryCameraYPos).w
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$60,d0                         ; '`'
                move.w  (PrimaryCameraYPosition).w,d1
                addi.w  #-$910,d1
                lea     Gfx_ScrollVRAMTransferParameters(pc),a0
                nop
                jmp     Tilemap_QueueRowFromDescriptor(pc)  ; (pc)
; End of function Stage8_UpdateFlyingNeoScrollAndTilemap
; Unreferenced alternate entry that executes a NOP before the following operation
UnreferencedUpdateQuarterScrollWithNop:
                nop                                     ; was: sub_102DE
; End of function UnreferencedUpdateQuarterScrollWithNop
; Stores one quarter of the primary horizontal scroll position
Scroll_UpdateQuarterHorizontalPosition:                 ; CODE XREF: Stage_UpdateLogic+8   p  ; was: sub_102E0
                                        ; Stage_InitBossIntro+4   p
                move.w  (PrimaryCameraXPosition).w,d0
                asr.w   #2,d0
                move.w  d0,(SecondaryCameraXPos).w
                rts
; End of function Scroll_UpdateQuarterHorizontalPosition
; Accumulates one quarter of the signed horizontal scroll delta
Scroll_AccumulateQuarterHorizontalDelta:                ; CODE XREF: Stage10_UpdateScrollToDeepStrider+4   p  ; was: sub_102EC
                                        ; Stage10_InitializeDeepStriderEncounter+4   p
                moveq   #0,d0
                move.w  (CameraXDelta).w,d0
                swap    d0
                asr.l   #2,d0
                add.l   d0,(SecondaryCameraXPos).w
                rts
; End of function Scroll_AccumulateQuarterHorizontalDelta
; Follows the player beyond horizontal threshold $F0 at up to six pixels per update
Camera_FollowPlayerBeyondHorizontalThreshold:           ; CODE XREF: Stage18_UpdateScrollAndRenderTilemap   p  ; was: sub_102FC
                                        ; sub_10060   p
                btst    #5,(PlayerActionStateFlags).w
                bne.w   Camera_HorizontalUpdateReturn
                tst.w   (a5)
                beq.s   Camera_HorizontalUpdateReturn
                moveq   #0,d0
                move.w  $10(a5),d0
                subi.w  #$F0,d0
                bmi.s   Camera_HorizontalUpdateReturn
                swap    d0
                asr.l   #3,d0
                cmpi.l  #$60000,d0
                bmi.s   Camera_ApplyThresholdFollowDelta
                move.l  #$60000,d0
Camera_ApplyThresholdFollowDelta:                       ; CODE XREF: Camera_FollowPlayerBeyondHorizontalThreshold+24   j  ; was: loc_10328
                add.l   d0,(PrimaryCameraXPosition).w
Camera_HorizontalUpdateReturn:                          ; CODE XREF: Camera_UpdateHorizontalTowardsPlayer+6   j  ; was: locret_1032C
                                        ; Camera_UpdateHorizontalTowardsPlayer+C   j
                rts
; End of function Camera_FollowPlayerBeyondHorizontalThreshold
; Unreferenced slower follow variant for player positions beyond $C0
UnreferencedCameraFollowRightEdge:
                move.w  #$C0,d0                         ; was: sub_1032E
                sub.w   $10(a5),d0
                bpl.s   Camera_HorizontalUpdateReturn
                neg.w   d0
                swap    d0
                asr.l   #5,d0
                cmpi.l  #$60000,d0
                bmi.s   UnreferencedCameraApplyRightEdgeDelta
                move.l  #$60000,d0
UnreferencedCameraApplyRightEdgeDelta:                  ; CODE XREF: UnreferencedCameraFollowRightEdge+16   j  ; was: loc_1034C
                add.l   d0,(PrimaryCameraXPosition).w
                rts
; End of function UnreferencedCameraFollowRightEdge
; Updates the vertical camera and renders the shared Sylpheed backdrop
Scroll_UpdateAndRenderSylpheedBackdrop:                 ; CODE XREF: Stage15_UpdateSunsetStingApproach   p  ; was: sub_10352
                bsr.w   Camera_FollowPlayerAboveVerticalThreshold
                bra.w   Tilemap_QueuePrimaryCameraRowOffset60
; End of function Scroll_UpdateAndRenderSylpheedBackdrop
; Advances vertical scroll by half a pixel and renders the shared Sylpheed backdrop
Scroll_AdvanceVerticalAndRenderSylpheedBackdrop:        ; CODE XREF: Stage15_InitializeSunsetStingEncounter   p  ; was: sub_1035A
                                        ; Stage16_UpdateScrollToViblack+14   p
                addi.l  #$8000,(PrimaryCameraYPosition).w
                bra.w   Tilemap_QueuePrimaryCameraRowOffset60
; End of function Scroll_AdvanceVerticalAndRenderSylpheedBackdrop
; Follows the player when above vertical threshold $108
Camera_FollowPlayerAboveVerticalThreshold:              ; CODE XREF: Scroll_UpdateAndRenderSylpheedBackdrop   p  ; was: sub_10366
                tst.w   (a5)
                beq.s   Camera_VerticalThresholdReturn
                moveq   #0,d0
                move.w  $14(a5),d0
                subi.w  #$108,d0
                bpl.s   Camera_VerticalThresholdReturn
                neg.w   d0
                swap    d0
                asr.l   #3,d0
                cmpi.l  #$60000,d0
                bmi.s   Camera_ApplyVerticalThresholdDelta
                move.l  #$60000,d0
Camera_ApplyVerticalThresholdDelta:                     ; CODE XREF: Camera_FollowPlayerAboveVerticalThreshold+1C   j  ; was: loc_1038A
                add.l   d0,(PrimaryCameraYPosition).w
Camera_VerticalThresholdReturn:                         ; CODE XREF: Camera_FollowPlayerAboveVerticalThreshold+2   j  ; was: locret_1038E
                                        ; Camera_FollowPlayerAboveVerticalThreshold+E   j
                rts
; End of function Camera_FollowPlayerAboveVerticalThreshold
