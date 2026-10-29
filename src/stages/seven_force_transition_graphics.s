; Seven Forces victory cutscene states and transition rendering helpers
Cutscene_SevenForceVictoryState0:                      ; DATA XREF: ROM:0000E4CC   o  ; was: sub_EA76
                bsr.w   Cutscene_SevenForceCamera2
                bsr.w   Cutscene_SevenForceCamera1
                tst.b   (SceneSequenceFlags).w
                beq.s   Cutscene_SevenForceUpdateClosingOffsets
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Cutscene_SevenForceUpdateClosingOffsets:               ; CODE XREF: Cutscene_SevenForcesVictoryState0+C   j  ; was: loc_EA8C
                                        ; Cutscene_SevenForcesVictoryState1:Cutscene_SevenForcesVictoryState1Update   j
                tst.w   (SevenForceCloseSpan).w
                beq.s   Cutscene_SevenForceUpdateCamera
                subq.w  #8,(SevenForceCloseSpan).w
                addq.w  #8,(CameraXLowerBound).w
                subq.w  #8,(CameraXUpperBound).w
Cutscene_SevenForceUpdateCamera:                       ; CODE XREF: Cutscene_SevenForcesVictoryState0+1A   j  ; was: loc_EA9E
                bsr.w   Camera_UpdateHorizontalTowardsPlayer
                rts
; End of function Cutscene_SevenForcesVictoryState0
; Cutscene state handler 1
Cutscene_SevenForceVictoryState1:                      ; DATA XREF: ROM:0000E4CE   o  ; was: sub_EAA4
                bsr.w   Cutscene_SevenForceCamera2
                tst.b   (SceneSequenceFlags).w
                beq.s   Cutscene_SevenForceVictoryState1Update
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Cutscene_SevenForceVictoryState1Update:                ; CODE XREF: Cutscene_SevenForcesVictoryState1+8   j  ; was: loc_EAB6
                bra.w   Cutscene_SevenForceUpdateClosingOffsets
; End of function Cutscene_SevenForcesVictoryState1
; Cutscene state handler 2
Cutscene_SevenForceVictoryState2:                      ; DATA XREF: ROM:0000E4D0   o  ; was: sub_EABA
                addi.l  #$78000,(SecondaryCameraYPos).w
                bsr.w   Cutscene_SevenForceUpdateClosingOffsets
                tst.b   (SceneSequenceFlags).w
                beq.s   Cutscene_SevenForceVictoryState2Return
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
                bsr.w   Cutscene_SevenForceLoadGraphics
Cutscene_SevenForceVictoryState2Return:                ; CODE XREF: Cutscene_SevenForcesVictoryState2+10   j  ; was: locret_EAD8
                rts
; End of function Cutscene_SevenForcesVictoryState2
; Cutscene state handler 3
Cutscene_SevenForceVictoryState3:                      ; DATA XREF: ROM:0000E4D2   o  ; was: sub_EADA
                addi.l  #$78000,(SecondaryCameraYPos).w
                bsr.w   Cutscene_SevenForceUpdateClosingOffsets
                bsr.w   Gfx_InitializeSevenForceCutsceneTilemap
                bmi.s   Cutscene_SevenForceVictoryState3Return
                addq.w  #2,(StageStateOffset).w
Cutscene_SevenForceVictoryState3Return:                ; CODE XREF: Cutscene_SevenForcesVictoryState3+10   j  ; was: locret_EAF0
                rts
; End of function Cutscene_SevenForcesVictoryState3
; Cutscene state handler 4
Cutscene_SevenForceVictoryState4:                      ; DATA XREF: ROM:0000E4D4   o  ; was: sub_EAF2
                addi.l  #$78000,(SecondaryCameraYPos).w
                bsr.w   Cutscene_SevenForceUpdateClosingOffsets
                bsr.w   Gfx_CheckSevenForceCutsceneBackgroundComplete
                bpl.s   Cutscene_SevenForceVictoryState4Return
                addq.w  #2,(StageStateOffset).w
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (PreviousCameraXPosition).w
                clr.w   (PrimaryCameraYPosition).w
                clr.w   (PreviousCameraYPosition).w
Cutscene_SevenForceVictoryState4Return:                ; CODE XREF: Cutscene_SevenForcesVictoryState4+10   j  ; was: locret_EB18
                rts
; End of function Cutscene_SevenForcesVictoryState4
; Cutscene state handler 5
Cutscene_SevenForceVictoryState5:                      ; DATA XREF: ROM:0000E4D6   o  ; was: sub_EB1A
                andi.w  #$1FF,(SecondaryCameraYPos).w
                addi.l  #$78000,(SecondaryCameraYPos).w
                cmpi.w  #$200,(SecondaryCameraYPos).w
                bmi.s   Cutscene_SevenForceVictoryState5Idle
                andi.w  #$1FF,(SecondaryCameraYPos).w
                addi.w  #-$1C00,(SecondaryCameraYPos).w
                addq.w  #2,(StageStateOffset).w
                clr.b   (SceneSequenceFlags).w
Cutscene_SevenForceVictoryState5Idle:                  ; CODE XREF: Cutscene_SevenForcesVictoryState5+14   j  ; was: loc_EB44
                bra.w   Cutscene_SevenForceVictoryIdleState
; End of function Cutscene_SevenForcesVictoryState5
; Cutscene state handler 6
Cutscene_SevenForceVictoryState6:                      ; DATA XREF: ROM:0000E4D8   o  ; was: sub_EB48
                bsr.w   Cutscene_SevenForceVictoryIdleState
                bsr.w   Cutscene_SevenForceCamera3
                tst.b   (SceneSequenceFlags).w
                beq.s   Cutscene_SevenForceVictoryState6Return
                addq.w  #2,(StageStateOffset).w
Cutscene_SevenForceVictoryState6Return:                ; CODE XREF: Cutscene_SevenForcesVictoryState6+C   j  ; was: locret_EB5A
                rts
; End of function Cutscene_SevenForcesVictoryState6
; Empty cutscene state for Seven Forces sequence
Cutscene_SevenForceVictoryIdleState:                   ; CODE XREF: Cutscene_SevenForcesVictoryState5:Cutscene_SevenForcesVictoryState5Idle   j  ; was: nullsub_27
                                        ; Cutscene_SevenForcesVictoryState6   p
                                        ; DATA XREF:
                rts
; End of function Cutscene_SevenForcesVictoryIdleState
; Updates camera position and calculates scroll
UnreferencedSevenForceCameraScrollUpdate:
                bsr.w   Camera_UpdateHorizontalTowardsPlayer  ; was: sub_EB5E
                bsr.w   Scroll_UpdateQuarterHorizontalPosition
                move.w  (SecondaryCameraXPos).w,d0
                addi.w  #$40,d0                         ; '@'
                neg.w   d0
                move.w  d0,(HScrollBuffer).w
                move.w  (PrimaryCameraXPosition).w,(SecondaryCameraXPos).w
                rts
; End of function UnreferencedSevenForcesCameraScrollUpdate
; Checks boss defeat and triggers stage transition
UnreferencedSevenForceBossTransitionCheck:
                tst.w   (GameplayExitMode).w            ; was: sub_EB7C
                bne.w   Stage_LateGameStateReturn
                tst.w   (ScriptedInputActive).w
                bne.w   Stage_LateGameStateReturn
                move.b  #$93,(PendingStageBGMRequest).w
                move.l  #StageTransitionMessageSequence_Shared,(StageMessageCursor).w
                bra.w   Stage_StartInterstageTransition
; End of function UnreferencedSevenForcesBossTransitionCheck
; Camera control for Medusa
Stage_SevenForceUpdateMedusaCameraAndParallax:         ; CODE XREF: Stage_SevenForcesAdvanceToMedusa:Stage_SevenForcesUpdateMedusaCamera   j  ; was: sub_EB9E
                addi.l  #$200,(SevenForceMedusaSpeed).w
                cmpi.w  #2,(SevenForceMedusaSpeed).w
                bmi.s   Stage_SevenForceStoreMedusaCameraVelocity
                move.l  #$20000,(SevenForceMedusaSpeed).w
Stage_SevenForceStoreMedusaCameraVelocity:             ; CODE XREF: Stage_SevenForcesUpdateMedusaCameraAndParallax+E   j  ; was: loc_EBB6
                move.l  (SevenForceMedusaSpeed).w,d0
                sub.l   d0,(PrimaryCameraXPosition).w
Stage_SevenForceWrapVerticalCamera:                    ; CODE XREF: Stage_SevenForcesFinishMedusaScroll+1A   j  ; was: loc_EBBE
                bpl.s   Stage_SevenForcePrepareMedusaPrimaryPlaneOrigin
                addi.w  #$800,(PrimaryCameraXPosition).w
                addi.w  #$800,(PreviousCameraXPosition).w
                move.w  #1,(MedusaSpawnSequenceFlag).w
Stage_SevenForcePrepareMedusaPrimaryPlaneOrigin:       ; CODE XREF: Stage_SevenForcesWrapVerticalCamera   j  ; was: loc_EBD2
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$10,d0
                bpl.s   Stage_SevenForceRenderMedusaPrimaryPlane
                addi.w  #$800,d0
Stage_SevenForceRenderMedusaPrimaryPlane:              ; CODE XREF: Stage_SevenForcesUpdateMedusaCameraAndParallax+3C   j  ; was: loc_EBE0
                move.w  (PrimaryCameraYPosition).w,d1
                jsr     (Tilemap_QueuePrimaryPlaneColumn).l
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$10,d0
                bpl.s   Stage_SevenForceRenderMedusaSecondaryPlane
                addi.w  #$800,d0
Stage_SevenForceRenderMedusaSecondaryPlane:            ; CODE XREF: Stage_SevenForcesUpdateMedusaCameraAndParallax+54   j  ; was: loc_EBF8
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$C00,d1
                jsr     (Tilemap_PopulateUnqueuedColumnFromDescriptor).l
Gfx_UpdateSevenForceParallaxRows:                      ; CODE XREF: Stage_SevenForcesUpdateStage20Scroll+12   j  ; was: loc_EC06
                move.w  (PrimaryCameraXPosition).w,d0
                neg.w   d0
                asr.w   #1,d0
                move.w  d0,d1
                asr.w   #1,d1
                movea.w #(HScrollPlaneBRow32-M68K_RAM),a0
                moveq   #$20,d6                         ; ' '
                moveq   #6,d7
Gfx_WriteSevenForcePrimaryParallaxRowsA:               ; CODE XREF: Stage_SevenForcesUpdateMedusaCameraAndParallax+80   j  ; was: loc_EC1A
                move.w  d0,(a0)
                adda.w  d6,a0
                dbf     d7,Gfx_WriteSevenForcePrimaryParallaxRowsA
                moveq   #7,d7
Gfx_WriteSevenForceSecondaryParallaxRows:              ; CODE XREF: Stage_SevenForcesUpdateMedusaCameraAndParallax+8A   j  ; was: loc_EC24
                move.w  d1,(a0)
                adda.w  d6,a0
                dbf     d7,Gfx_WriteSevenForceSecondaryParallaxRows
                moveq   #8,d7
Gfx_WriteSevenForcePrimaryParallaxRowsB:               ; CODE XREF: Stage_SevenForcesUpdateMedusaCameraAndParallax+94   j  ; was: loc_EC2E
                move.w  d0,(a0)
                adda.w  d6,a0
                dbf     d7,Gfx_WriteSevenForcePrimaryParallaxRowsB
                rts
; End of function Stage_SevenForcesUpdateMedusaCameraAndParallax
; Camera lock handler
Stage_SevenForceUpdateSylpheedPrimaryPlane:            ; CODE XREF: Stage_SevenForcesUpdateSylpheedScroll   p  ; was: sub_EC38
                move.l  (SevenForcePlaneASpeed).w,d0
                subi.l  #$2000,d0
                cmpi.l  #$FFF88000,d0
                bpl.s   Stage_SevenForceStoreSylpheedPrimaryVelocity
                move.l  #$FFF88000,d0
Stage_SevenForceStoreSylpheedPrimaryVelocity:          ; CODE XREF: Stage_SevenForcesUpdateSylpheedPrimaryPlane+10   j  ; was: loc_EC50
                move.l  d0,(SevenForcePlaneASpeed).w
                add.l   d0,(PrimaryCameraYPosition).w
                cmpi.w  #$F600,(PrimaryCameraYPosition).w
                bpl.s   Stage_SevenForcePrepareSylpheedPrimaryOrigin
                move.b  #1,(SceneSequenceFlags).w
Stage_SevenForcePrepareSylpheedPrimaryOrigin:          ; CODE XREF: Stage_SevenForcesUpdateSylpheedPrimaryPlane+26   j  ; was: loc_EC66
                move.w  (PrimaryCameraXPosition).w,d0
                subi.w  #$60,d0                         ; '`'
                bpl.s   Stage_SevenForceRenderSylpheedPrimaryPlane
                addi.w  #$800,d0
Stage_SevenForceRenderSylpheedPrimaryPlane:            ; CODE XREF: Stage_SevenForcesUpdateSylpheedPrimaryPlane+36   j  ; was: loc_EC74
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$F8,d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Stage_SevenForcesUpdateSylpheedPrimaryPlane
; Loads Sylpheed tiles
Stage_SevenForceUpdateSylpheedSecondaryPlane:          ; CODE XREF: Stage_SevenForcesUpdateSylpheedScroll+4   p  ; was: sub_EC86
                                        ; sub_E8AA   p
                bsr.s   Stage_SevenForceAdvanceSylpheedSecondaryScroll
                cmpi.w  #$F400,(SecondaryCameraYPos).w
                bpl.s   Stage_SevenForceRenderSylpheedSecondaryPlane
                move.b  #1,(SceneSequenceFlags).w
Stage_SevenForceRenderSylpheedSecondaryPlane:          ; CODE XREF: Stage_SevenForcesUpdateSylpheedSecondaryPlane+8   j  ; was: loc_EC96
                moveq   #0,d0
                move.w  (SecondaryCameraYPos).w,d1
                subi.w  #$F8,d1
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Stage_SevenForcesUpdateSylpheedSecondaryPlane
; Loads Sylpheed palette
Stage_SevenForceAdvanceSylpheedSecondaryScroll:        ; CODE XREF: Stage_SevenForcesFinishSylpheedForeground:Stage_SevenForcesContinueSylpheedForeground   p  ; was: sub_ECAA
                                        ; sub_EC86   p
                move.l  (SevenForcePlaneBSpeed).w,d0
                subi.l  #$1000,d0
                cmpi.l  #$FFF88000,d0
                bpl.s   Stage_SevenForceApplySylpheedSecondaryVelocity
                move.l  #$FFF88000,d0
Stage_SevenForceApplySylpheedSecondaryVelocity:        ; CODE XREF: Stage_SevenForcesAdvanceSylpheedSecondaryScroll+10   j  ; was: loc_ECC2
                move.l  d0,(SevenForcePlaneBSpeed).w
                add.l   d0,(SecondaryCameraYPos).w
                rts
; End of function Stage_SevenForcesAdvanceSylpheedSecondaryScroll
; Advances and renders the Artemis background plane
Stage_SevenForceUpdateArtemisBackgroundPlane:          ; CODE XREF: Stage_SevenForcesScrollArtemisBackground   p  ; was: sub_ECCC
                subi.w  #6,(PrimaryCameraYPosition).w
                cmpi.w  #$E200,(PrimaryCameraYPosition).w
                bpl.s   Stage_SevenForceRenderArtemisBackgroundPlane
                move.w  #$E200,(PrimaryCameraYPosition).w
Stage_SevenForceRenderArtemisBackgroundPlane:          ; CODE XREF: Stage_SevenForcesUpdateArtemisBackgroundPlane+C   j  ; was: loc_ECE0
                moveq   #0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                addi.w  #$100,d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Stage_SevenForcesUpdateArtemisBackgroundPlane
; Advances the Artemis foreground motion
Stage_SevenForceUpdateArtemisForegroundMotion:         ; CODE XREF: Stage_SevenForcesScrollArtemisForeground   p  ; was: sub_ECF4
                tst.w   (ArtemisForegroundState).w
                bne.s   Stage_SevenForceAdvanceArtemisForegroundMotion
                subi.l  #$E00,(PrimaryCameraYPosition).w
                cmpi.w  #$E1F8,(PrimaryCameraYPosition).w
                bpl.s   Stage_SevenForceArtemisForegroundMotionReturn
                move.w  #2,(ArtemisForegroundState).w
Stage_SevenForceArtemisForegroundMotionReturn:         ; CODE XREF: Stage_SevenForcesUpdateArtemisForegroundMotion+14   j  ; was: locret_ED10
                                        ; Stage_SevenForcesUpdateArtemisForegroundMotion+36   j
                rts
; ---------------------------------------------------------------------------
Stage_SevenForceAdvanceArtemisForegroundMotion:        ; CODE XREF: Stage_SevenForcesUpdateArtemisForegroundMotion+4   j  ; was: loc_ED12
                bpl.s   Stage_SevenForceCheckArtemisForegroundLimit
                addi.l  #$12000,(PrimaryCameraYPosition).w
Stage_SevenForceCheckArtemisForegroundLimit:           ; CODE XREF: Stage_SevenForcesAdvanceArtemisForegroundMotion   j  ; was: loc_ED1C
                addi.l  #$E00,(PrimaryCameraYPosition).w
                cmpi.w  #$E206,(PrimaryCameraYPosition).w
                bmi.s   Stage_SevenForceArtemisForegroundMotionReturn
                clr.w   (ArtemisForegroundState).w
                rts
; End of function Stage_SevenForcesUpdateArtemisForegroundMotion
; Advances and renders the Sirene primary plane
Stage_SevenForceUpdateSirenePrimaryPlane:              ; CODE XREF: Stage_SevenForcesAdvanceSireneTransition+6   p  ; was: sub_ED32
                move.l  (SevenForcePlaneASpeed).w,d0
                addi.l  #$200,d0
                cmpi.l  #$8000,d0
                bmi.s   Stage_SevenForceStoreSirenePrimaryVelocity
                move.l  #$8000,d0
Stage_SevenForceStoreSirenePrimaryVelocity:            ; CODE XREF: Stage_SevenForcesUpdateSirenePrimaryPlane+10   j  ; was: loc_ED4A
                move.l  d0,(SevenForcePlaneASpeed).w
                add.l   d0,(PrimaryCameraYPosition).w
                cmpi.w  #$E4C0,(PrimaryCameraYPosition).w
                bmi.s   Stage_SevenForceRenderSirenePrimaryPlane
                move.b  #1,(SceneSequenceFlags).w
                move.w  #8,(PlaneAShakeLevel).w
                bsr.w   Gfx_ClearSevenForceTilemapMode
Stage_SevenForceRenderSirenePrimaryPlane:              ; CODE XREF: Stage_SevenForcesUpdateSirenePrimaryPlane+26   j  ; was: loc_ED6A
                moveq   #0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                addi.w  #$100,d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Stage_SevenForcesUpdateSirenePrimaryPlane
; Advances and renders the Sirene secondary plane
Stage_SevenForceRenderSireneSecondaryPlane:            ; CODE XREF: Stage_SevenForcesFinishSireneTransition+6   p  ; was: sub_ED7E
                move.l  (SevenForcePlaneBSpeed).w,d0
                add.l   d0,(PrimaryCameraYPosition).w
                moveq   #0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                subi.w  #$100,d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Stage_SevenForcesRenderSireneSecondaryPlane
; Advances the Sirene secondary scroll
Stage_SevenForceUpdateSireneSecondaryScroll:           ; CODE XREF: Stage_SevenForcesAdvanceSireneTransition+2   p  ; was: sub_ED9A
                                        ; Stage_SevenForcesFinishSireneTransition+2   p
                move.l  (SevenForcePlaneBSpeed).w,d0
                subi.l  #$100,d0
                cmpi.l  #$FFFFC000,d0
                bpl.s   Stage_SevenForceStoreSireneSecondaryVelocity
                move.l  #$FFFFC000,d0
Stage_SevenForceStoreSireneSecondaryVelocity:          ; CODE XREF: Stage_SevenForcesUpdateSireneSecondaryScroll+10   j  ; was: loc_EDB2
                move.l  d0,(SevenForcePlaneBSpeed).w
                add.l   d0,(SecondaryCameraYPos).w
                cmpi.w  #$E340,(SecondaryCameraYPos).w
                bpl.s   Stage_SevenForceRenderSireneSecondaryScroll
                move.b  #1,(SceneSequenceFlags).w
Stage_SevenForceRenderSireneSecondaryScroll:           ; CODE XREF: Stage_SevenForcesUpdateSireneSecondaryScroll+26   j  ; was: loc_EDC8
                move.w  #$200,d0
                move.w  (SecondaryCameraYPos).w,d1
                subi.w  #$100,d1
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Stage_SevenForcesUpdateSireneSecondaryScroll
UnreferencedSevenForceEmptyHandler:                    ; was: nullsub_28
                rts
; End of function UnreferencedSevenForcesEmptyHandler

; Camera scroll handler 1
Cutscene_SevenForceCamera1:                            ; CODE XREF: Cutscene_SevenForcesVictoryState0+4   p  ; was: sub_EDE0
                addi.l  #$78000,(PrimaryCameraYPosition).w
                cmpi.w  #$E520,(PrimaryCameraYPosition).w
                bmi.s   Cutscene_SevenForceCamera1Render
                move.b  #1,(SceneSequenceFlags).w
Cutscene_SevenForceCamera1Render:                      ; CODE XREF: Cutscene_SevenForcesCamera1+E   j  ; was: loc_EDF6
                moveq   #0,d0
                move.w  (PrimaryCameraYPosition).w,d1
                addi.w  #$F8,d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Cutscene_SevenForcesCamera1
; Camera scroll handler 2
Cutscene_SevenForceCamera2:                            ; CODE XREF: Cutscene_SevenForcesVictoryState0   p  ; was: sub_EE0A
                                        ; Cutscene_SevenForcesVictoryState1   p
                addi.l  #$78000,(SecondaryCameraYPos).w
                cmpi.w  #$E4F8,(SecondaryCameraYPos).w
                bmi.s   Cutscene_SevenForceCamera2Render
                move.b  #1,(SceneSequenceFlags).w
Cutscene_SevenForceCamera2Render:                      ; CODE XREF: Cutscene_SevenForcesCamera2+E   j  ; was: loc_EE20
                move.w  #$200,d0
                move.w  (SecondaryCameraYPos).w,d1
                addi.w  #$F8,d1
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Cutscene_SevenForcesCamera2
; Camera scroll handler 3
Cutscene_SevenForceCamera3:                            ; CODE XREF: Cutscene_SevenForcesVictoryState6+4   p  ; was: sub_EE36
                addi.l  #$78000,(SecondaryCameraYPos).w
                cmpi.w  #$E700,(SecondaryCameraYPos).w
                bmi.s   Cutscene_SevenForceCamera3Render
                move.b  #1,(SceneSequenceFlags).w
Cutscene_SevenForceCamera3Render:                      ; CODE XREF: Cutscene_SevenForcesCamera3+E   j  ; was: loc_EE4C
                move.w  #$200,d0
                move.w  (SecondaryCameraYPos).w,d1
                addi.w  #$F8,d1
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                bra.w   Tilemap_QueueRowFromDescriptor
; End of function Cutscene_SevenForcesCamera3
; Initializes the Artemis camera, tilemap, and graphics transfers
Stage_SevenForceInitializeArtemisCameraAndAssets:      ; CODE XREF: Stage_SevenForcesFinishSylpheedForeground+10   j  ; was: sub_EE62
                bsr.w   Gfx_InitializeArtemisTilemapRow
                bset    #6,(PlayerRestrictionFlags).w
                move.w  #$60,(PrimaryCameraXPosition).w  ; '`'
                move.w  #$60,(PreviousCameraXPosition).w  ; '`'
                move.w  #$E300,(PrimaryCameraYPosition).w
                move.w  #$E300,(PreviousCameraYPosition).w
                clr.w   (SecondaryCameraXPos).w
                move.w  #$E400,(SecondaryCameraYPos).w
                move.w  (PrimaryCameraXPosition).w,(CameraXLowerBound).w
                move.w  (PrimaryCameraXPosition).w,(CameraXUpperBound).w
                lea     Gfx_ArtemisInitialAssetTransfers(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_SevenForcesInitializeArtemisCameraAndAssets
; ---------------------------------------------------------------------------
Gfx_ArtemisInitialAssetTransfers:   dc.w    7           ; field_0 ; was: stru_EEA6
                                        ; DATA XREF: Stage_SevenForcesInitializeArtemisCameraAndAssets+38   o
                dc.l    SevenForceArtemisTileArt0000   ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    SevenForceArtemisTileArt1F00   ; field_2
                dc.w    $1F00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SevenForceArtemisMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SevenForceArtemisMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SevenForceArtemisMappingData6800  ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SevenForceArtemisMappingData2020  ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF

; Initializes the Artemis tilemap transfer
Gfx_ArtemisInitializeTilemap:                           ; CODE XREF: Stage_SevenForcesBeginArtemisTransition   p  ; was: sub_EED8
                tst.w   (DataLoaderControl).w
                bmi.s   Gfx_ArtemisTilemapInitReturn
                movea.l #FlyingNeoTileAttrRangeA,a0
                move.w  #0,d0
                move.w  #$F8,d1
                moveq   #$47,d7                         ; 'G'
                jsr     (Gfx_UpdateTilemapIndices).l
                movea.l #(LargeTilemapBuffer+$920),a0
                move.w  #$A000,d0
                move.w  #$F8,d1
                moveq   #1,d7
                jsr     (Gfx_UpdateTilemapIndices).l
                move.l  #Gfx_FrontendAlternateVRAMTransferParameters,(TilemapTransferBase).w
                move.w  #$200,(TilemapRowXOrFillWord).w
                move.w  #$E400,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                moveq   #1,d0
Gfx_ArtemisTilemapInitReturn:                           ; CODE XREF: Gfx_ArtemisInitializeTilemap+4   j  ; was: locret_EF26
                rts
; End of function Gfx_ArtemisInitializeTilemap
; Advances the Artemis scrolling-background renderer
Gfx_ArtemisUpdateBackground:                            ; CODE XREF: Stage_SevenForcesWaitForArtemisBackground   p  ; was: sub_EF28
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.s   Gfx_ArtemisBackgroundUpdateReturn
                move.l  #Gfx_DefaultVRAMTransferParameters,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$E400,(TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                moveq   #$FFFFFFFF,d0
Gfx_ArtemisBackgroundUpdateReturn:                      ; CODE XREF: Gfx_ArtemisUpdateBackground+6   j  ; was: locret_EF4A
                rts
; End of function Gfx_ArtemisUpdateBackground
; Queues the Artemis indexed tilemap rows
Gfx_QueueArtemisIndexedRows:                            ; CODE XREF: Entity_SevenForcesArtemisFadeOutState28+20   p  ; was: sub_EF4C
                lea     Gfx_ArtemisIndexedRowTransferDescriptor(pc),a0
                nop
                jmp     Tilemap_QueueIndexedRows
; End of function Gfx_QueueArtemisIndexedRows
; ---------------------------------------------------------------------------
Gfx_ArtemisIndexedRowTransferDescriptor:    dc.w    $6C00, $4000, $F00, $494A, $494A, $494A, $494A, $494A, $494A, $494A, $494A  ; was: word_EF58
                                        ; DATA XREF: Gfx_QueueArtemisIndexedRows   o

; Checks whether the Seven Forces background render completed
Gfx_CheckSevenForceBackgroundRender:
                jsr     (Tilemap_QueueNextScrollingRow).l  ; was: sub_EF6E
                bpl.s   Gfx_SevenForceBackgroundCheckReturn
                moveq   #$FFFFFFFF,d0
Gfx_SevenForceBackgroundCheckReturn:                   ; CODE XREF: Gfx_CheckSevenForcesBackgroundRender+6   j  ; was: locret_EF78
                rts
; End of function Gfx_CheckSevenForcesBackgroundRender
; Loads cutscene graphics
Cutscene_SevenForceLoadGraphics:                       ; CODE XREF: Cutscene_SevenForcesVictoryState2+1A   p  ; was: sub_EF7A
                lea     (SevenForceCutscenePaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                lea     Gfx_SevenForceCutsceneAssetTransfers(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Cutscene_SevenForcesLoadGraphics
; ---------------------------------------------------------------------------
Gfx_SevenForceCutsceneAssetTransfers:  dc.w    7       ; field_0 ; was: stru_EF92
                                        ; DATA XREF: Cutscene_SevenForcesLoadGraphics+C   o
                dc.l    SevenForceVictoryCutsceneTileArt1F00  ; field_2
                dc.w    $1F00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SevenForceVictoryCutsceneMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SevenForceVictoryCutsceneMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    $FFFF

; Initializes tilemap update with scroll parameters
Gfx_InitializeSevenForceCutsceneTilemap:               ; CODE XREF: Cutscene_SevenForcesVictoryState3+C   p  ; was: sub_EFAC
                tst.w   (DataLoaderControl).w
                bmi.s   Gfx_SevenForceCutsceneTilemapInitReturn
                movea.l #FlyingNeoTileAttrRangeA,a0
                move.w  #0,d0
                move.w  #$F8,d1
                moveq   #$7E,d7                         ; '~'
                jsr     (Gfx_UpdateTilemapIndices).l
                move.l  #Gfx_DefaultVRAMTransferParameters,(TilemapTransferBase).w
                clr.w   (TilemapRowXOrFillWord).w
                clr.w   (TilemapRowYPosition).w
                move.w  #$1F,(TilemapRowCountdown).w
                moveq   #1,d0
Gfx_SevenForceCutsceneTilemapInitReturn:               ; CODE XREF: Gfx_InitializeSevenForcesCutsceneTilemap+4   j  ; was: locret_EFE0
                rts
; End of function Gfx_InitializeSevenForcesCutsceneTilemap
; Attributes: thunk
; Checks cutscene completion
Gfx_CheckSevenForceCutsceneBackgroundComplete:         ; CODE XREF: Cutscene_SevenForcesVictoryState4+C   p  ; was: sub_EFE2
                jmp     Tilemap_QueueNextScrollingRow
; End of function Gfx_CheckSevenForcesCutsceneBackgroundComplete
; Fills the four Stage 20 plane buffers
Gfx_FillStage20PlaneBuffers:                            ; CODE XREF: Stage_SevenForcesInitializeStage20+1A   p  ; was: sub_EFE8
                move.b  #$82,(Stage20PlaneMode0).l
                move.b  #$90,(Stage20PlaneMode1).l
                move.b  #$92,(Stage20PlaneMode2).l
                lea     (PlaneTilemapRow25).l,a0
                lea     (PlaneTilemapRow26).l,a1
                lea     (PlaneTilemapRow27).l,a2
                lea     (PlaneTilemapRow28).l,a3
                move.w  #$181,d1
                moveq   #$3F,d7                         ; '?'
Gfx_FillStage20PlaneBuffersLoop:                        ; CODE XREF: Gfx_FillStage20PlaneBuffers+3E   j  ; was: loc_F01E
                move.w  d1,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a2)+
                move.w  d1,(a3)+
                dbf     d7,Gfx_FillStage20PlaneBuffersLoop
                rts
; End of function Gfx_FillStage20PlaneBuffers
; Background graphics setup
Gfx_ClearSylpheedPlaneModes:                            ; CODE XREF: Stage_SevenForcesInitializeSylpheedScroll+16   p  ; was: sub_F02C
                clr.b   (Stage20PlaneMode0).l
                clr.b   (Stage20PlaneMode1).l
                clr.b   (Stage20PlaneMode2).l
                rts
; End of function Gfx_ClearSylpheedPlaneModes
; Initializes the Artemis tilemap row
Gfx_InitializeArtemisTilemapRow:                        ; CODE XREF: Stage_SevenForcesInitializeArtemisCameraAndAssets   p  ; was: sub_F040
                move.b  #2,(SevenForceTilemapMode).l
                lea     (PlaneTilemapRow22).l,a0
                move.w  #$300,d1
                moveq   #$3F,d7                         ; '?'
Gfx_FillArtemisTilemapRowLoop:                          ; CODE XREF: Gfx_InitializeArtemisTilemapRow+16   j  ; was: loc_F054
                move.w  d1,(a0)+
                dbf     d7,Gfx_FillArtemisTilemapRowLoop
                rts
; End of function Gfx_InitializeArtemisTilemapRow
; Clears byte flag at FF7B00
Gfx_ClearSevenForceTilemapMode:                        ; CODE XREF: Stage_SevenForcesUpdateSirenePrimaryPlane+34   p  ; was: sub_F05C
                clr.b   (SevenForceTilemapMode).l
                rts
; End of function Gfx_ClearSevenForcesTilemapMode
; Unreferenced helper that clamps and applies a palette fade
UnreferencedClampAndApplyPaletteFade:
                move.w  (SevenForceFadeValue).w,d0     ; was: sub_F064
                bpl.s   UnreferencedClampPaletteFadePositive
                cmpi.w  #$FFE4,d0
                bpl.s   UnreferencedApplyClampedPaletteFade
                moveq   #$FFFFFFE4,d0
                bra.s   UnreferencedApplyClampedPaletteFade
; ---------------------------------------------------------------------------
UnreferencedClampPaletteFadePositive:                   ; CODE XREF: UnreferencedClampAndApplyPaletteFade+4   j  ; was: loc_F074
                beq.s   UnreferencedApplyClampedPaletteFade
                moveq   #0,d0
UnreferencedApplyClampedPaletteFade:                    ; CODE XREF: UnreferencedClampAndApplyPaletteFade+A   j  ; was: loc_F078
                                        ; UnreferencedClampAndApplyPaletteFade+E   j
                move.w  d0,(SevenForceFadeValue).w
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                moveq   #$1F,d5
                move.w  #$E000,d7
                jmp     (Gfx_ApplyPaletteFade).l
; End of function UnreferencedClampAndApplyPaletteFade
; Dampens the shared horizontal velocity toward zero
Stage_SevenForceDampenHorizontalVelocity:              ; CODE XREF: Stage_SevenForcesBeginArtemisTransition+4   p  ; was: sub_F08C
                tst.l   (StageMotionXDelta).w
                beq.s   Stage_SevenForceHorizontalVelocityDampingReturn
                bpl.s   Stage_SevenForceDampenPositiveHorizontalVelocity
                addi.l  #$800,(StageMotionXDelta).w
                bmi.s   Stage_SevenForceHorizontalVelocityDampingReturn
                clr.l   (StageMotionXDelta).w
                rts
; ---------------------------------------------------------------------------
Stage_SevenForceDampenPositiveHorizontalVelocity:      ; CODE XREF: Stage_SevenForcesDampenHorizontalVelocity+6   j  ; was: loc_F0A4
                subi.l  #$800,(StageMotionXDelta).w
                bpl.s   Stage_SevenForceHorizontalVelocityDampingReturn
                clr.l   (StageMotionXDelta).w
Stage_SevenForceHorizontalVelocityDampingReturn:       ; CODE XREF: Stage_SevenForcesDampenHorizontalVelocity+4   j  ; was: locret_F0B2
                                        ; Stage_SevenForcesDampenHorizontalVelocity+10   j
                rts
; End of function Stage_SevenForcesDampenHorizontalVelocity
; Updates the Sylpheed foreground scroll velocity and position
Stage_SevenForceUpdateSylpheedForegroundScroll:        ; CODE XREF: Stage_SevenForcesAdvanceSylpheedForeground:Stage_SevenForcesUpdateSylpheedForeground   j  ; was: sub_F0B4
                btst    #3,(PlayerSpriteAttributes).w
                bne.s   Stage_SevenForceIncreaseSylpheedForegroundVelocity
                subi.l  #$1000,(StageMotionXDelta).w
                bpl.s   Stage_SevenForceApplySylpheedForegroundVelocity
                clr.l   (StageMotionXDelta).w
                bra.s   Stage_SevenForceApplySylpheedForegroundVelocity
; ---------------------------------------------------------------------------
Stage_SevenForceIncreaseSylpheedForegroundVelocity:    ; CODE XREF: Stage_SevenForcesUpdateSylpheedForegroundScroll+6   j  ; was: loc_F0CC
                addi.l  #$2000,(StageMotionXDelta).w
                cmpi.w  #4,(StageMotionXDelta).w
                bmi.s   Stage_SevenForceApplySylpheedForegroundVelocity
                move.l  #$40000,(StageMotionXDelta).w
Stage_SevenForceApplySylpheedForegroundVelocity:       ; CODE XREF: Stage_SevenForcesUpdateSylpheedForegroundScroll+10   j  ; was: loc_F0E4
                                        ; Stage_SevenForcesUpdateSylpheedForegroundScroll+16   j
                move.l  (StageMotionXDelta).w,d0
                asl.l   #1,d0
                add.l   d0,(SecondaryCameraXPos).w
                rts
; End of function Stage_SevenForcesUpdateSylpheedForegroundScroll
