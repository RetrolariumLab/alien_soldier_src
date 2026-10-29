; Initializes stage transition fade
Sys_TransitionToStageInit:                              ; was: sub_1E76C
                tst.w   (GameSubstateIndex).w
                bne.s   StageTransition_BeginSelectedRoute
                jsr     (Sys_InitGameMode).l
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                clr.b   (PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMA
; ---------------------------------------------------------------------------
StageTransition_BeginSelectedRoute:                     ; was: loc_1E7A8
                addq.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                bset    #0,(StageRouteFlags).w
                moveq   #0,d0
                move.l  d0,(SceneScratchLong0).w
                move.l  d0,(SceneScratchLong1).w
                move.l  d0,(SceneScratchLong2).w
                move.l  d0,(SceneScratchLong3).w
                bsr.w   StageTransition_DispatchInitialize
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                jmp     (Gfx_FadePaletteTransition).l
; End of function Sys_TransitionToStageInit
; Updates stage transition
Sys_StageTransitionUpdate:                              ; was: sub_1E7DE
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                jsr     (Sys_ProcessVisibleObjects).l
                bsr.w   StageTransition_DispatchUpdate
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                addq.w  #1,(FrameCounter).w
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   StageTransition_CheckCompletionFlags
                addq.w  #2,(GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
StageTransition_CheckCompletionFlags:                   ; was: loc_1E824
                bclr    #1,(PaletteFadeMaskStatus).w
                beq.s   StageTransition_Return
                move.w  #$C,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                jmp     Stage_LoadAssetsForCurrentTableIndex
; ---------------------------------------------------------------------------
StageTransition_Return:                                 ; was: locret_1E83C
                rts
; End of function Sys_StageTransitionUpdate

; Dispatches initialization for the selected transition route
StageTransition_DispatchInitialize:                     ; was: sub_1E83E
                move.w  (SetupTransitionIndex).w,d0
                movea.w StageTransition_InitializeHandlerTable(pc,d0.w),a0
                adda.l  #StageTransition_DispatchUpdate,a0
                jmp     (a0)
; End of function StageTransition_DispatchInitialize
; ---------------------------------------------------------------------------
StageTransition_InitializeHandlerTable: dc.w    XiTigerCutscene_LoadAssets-StageTransition_DispatchUpdate  ; was: off_1E84E
                dc.w    ZLeoEnding_InitializeScene-StageTransition_DispatchUpdate
                dc.w    EndingSequence_InitializeFromTransition-StageTransition_DispatchUpdate

; Dispatches the per-frame handler for the selected transition route
StageTransition_DispatchUpdate:                         ; was: sub_1E854
                move.w  (SetupTransitionIndex).w,d0
                movea.w StageTransition_UpdateHandlerTable(pc,d0.w),a0
                adda.l  #XiTigerCutscene_LoadAssets,a0
                jmp     (a0)
; End of function StageTransition_DispatchUpdate
; ---------------------------------------------------------------------------
StageTransition_UpdateHandlerTable: dc.w    XiTigerCutscene_Update-XiTigerCutscene_LoadAssets  ; was: off_1E864
                dc.w    ZLeoEnding_UpdateScene-XiTigerCutscene_LoadAssets
                dc.w    EndingSequence_UpdateFromTransition-XiTigerCutscene_LoadAssets
