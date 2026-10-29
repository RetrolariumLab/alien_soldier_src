; Transitions into the story-screen state
Frontend_EnterStoryScreen:                              ; was: sub_1D3C8
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #$24,(GameModeIndex).w          ; '$'
                clr.w   (GameSubstateIndex).w
FrontendTransition_Return:                              ; was: locret_1D3D8
                                        ; Frontend_WaitAfterSegaPatternErase+4   j
                rts
; End of function Frontend_EnterStoryScreen
; Initializes the intermediate transition scene in the frontend opening sequence
Frontend_InitializeTransitionScene:                     ; was: sub_1D3DA
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                movea.l #FrontendTransitionAssetLoadList,a0
                jsr     (LoadObjData).l
                movea.l #FrontendTransitionPaletteOffsetLists,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                move.w  #$400,d0
                move.w  #0,d1
                jsr     (Tilemap_DirectTransferWithPrimaryDescriptor).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function Frontend_InitializeTransitionScene
; ---------------------------------------------------------------------------
FrontendTransitionAssetLoadList:    dc.w    7           ; field_0  ; was: stru_1D420
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $D000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingDataA  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingDataB  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedFrontendAndTransitionMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    $FFFF

; Attributes: thunk
; Frontend opening-state thunk that refreshes both scroll-plane buffers
Frontend_PrepareTransitionScrollPlanes:                 ; was: sub_1D44A
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function Frontend_PrepareTransitionScrollPlanes
; Initializes cutscene with data loading
Cutscene_InitializeScene:                               ; was: sub_1D450
                clr.w   (PrimaryCameraXPosition).w
                clr.w   (PrimaryCameraYPosition).w
                clr.b   (VDPReg17Shadow+1).w
                clr.b   (VDPReg18Shadow+1).w
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                movea.l #CutsceneSceneAssetLoadList,a0
                jsr     (LoadObjData).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jsr     (CutsceneProjection_Initialize).l
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function Cutscene_InitializeScene
; ---------------------------------------------------------------------------
CutsceneSceneAssetLoadList: dc.w    7                   ; field_0  ; was: stru_1D492
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $C000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $D000                           ; field_6
                dc.w    $FFFF

; Updates the cutscene-frame selector from horizontal input and loads that frame
Cutscene_UpdateFrameSelectionFromInput:                 ; was: sub_1D4B4
                btst    #0,(ControllerHeldState).w
                beq.s   Cutscene_UpdateFrameSelectionFromInput_CheckDecrease
                addi.l  #$1000,(SharedScratchLong2).w
Cutscene_UpdateFrameSelectionFromInput_CheckDecrease:   ; was: loc_1D4C4
                btst    #1,(ControllerHeldState).w
                beq.s   Cutscene_UpdateFrameSelectionFromInput_ClampUpperBound
                subi.l  #$1000,(SharedScratchLong2).w
Cutscene_UpdateFrameSelectionFromInput_ClampUpperBound:  ; was: loc_1D4D4
                move.l  (SharedScratchLong2).w,d0
                cmpi.l  #$20000,d0
                bmi.s   Cutscene_UpdateFrameSelectionFromInput_WrapNegative
                move.l  #$20000,d0
Cutscene_UpdateFrameSelectionFromInput_WrapNegative:    ; was: loc_1D4E6
                tst.l   d0
                bpl.s   Cutscene_UpdateFrameSelectionFromInput_SelectCodeWord
                move.l  #$20000,d0
Cutscene_UpdateFrameSelectionFromInput_SelectCodeWord:  ; was: loc_1D4F0
                move.l  d0,(SharedScratchLong2).w
                asr.l   #8,d0
                asr.w   #4,d0
                andi.w  #$C,d0
                move.l  Cutscene_ScrollAndPlaneUpdateCode(pc,d0.w),(SharedScratchLong0).w
                jmp     CutsceneProjection_BuildFrame
; End of function Cutscene_UpdateFrameSelectionFromInput

; The frame selector above also reads four longwords from this routine's code
Cutscene_ScrollAndPlaneUpdateCode:                      ; was: sub_1D508
                bsr.w   Cutscene_AdvanceScrollAndQueueColumn
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function Cutscene_ScrollAndPlaneUpdateCode

; Advances wrapped cutscene scroll and queues its next primary-plane column
Cutscene_AdvanceScrollAndQueueColumn:                   ; was: sub_1D512
                cmpi.w  #$E00,(PrimaryCameraXPosition).w
                bmi.s   Cutscene_AdvanceScrollAndQueueColumn_Advance
                subi.w  #$D00,(PrimaryCameraXPosition).w
Cutscene_AdvanceScrollAndQueueColumn_Advance:           ; was: loc_1D520
                addi.l  #$10000,(PrimaryCameraXPosition).w
                move.w  (PrimaryCameraXPosition).w,d0
                asr.w   #2,d0
                move.w  d0,(SecondaryCameraXPos).w
                move.w  (PrimaryCameraXPosition).w,d0
                addi.w  #$180,d0
                move.w  (PrimaryCameraYPosition).w,d1
                jmp     Tilemap_QueuePrimaryPlaneColumn
; End of function Cutscene_AdvanceScrollAndQueueColumn
; ---------------------------------------------------------------------------
UnreferencedOpeningTransitionData:      binclude "data/other/unreferenced_opening_transition_data.bin"  ; was: unused_4
FrontendFinalOpeningSpriteGridMapping:  dc.w    $316, $100, $B8, $32C, $100, $C4, $326, $100  ; was: word_1D5E0
                dc.w    $D0, $31E, $100, $DC, $330, $100, $E8, $33A
                dc.w    $100, 0, $332, $100, $C, $32C, $100, $18
                dc.w    $31C, $100, $24, $326, $100, $30, $31E, $100
                dc.w    $3C, $8338, $100, $48

; Initializes stage select screen with graphics setup
