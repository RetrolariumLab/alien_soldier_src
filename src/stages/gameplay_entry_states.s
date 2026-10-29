; Initialize a normal stage, stream its two tilemap planes, and enter gameplay
Stage_UpdateGameplayEntry:                              ; was: sub_1C3FA
                tst.b   (DataLoaderControl).w
                bmi.s   Stage_UpdateGameplayEntry_Return
                cmpi.w  #4,(GameSubstateIndex).w
                beq.w   Stage_StreamGameplayEntrySecondaryPlane
                move.w  (GameSubstateIndex).w,d0
                bne.s   Stage_StreamGameplayEntryPrimaryPlane
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                jsr     (Sys_ClearObjectAndSpriteState).l
                jsr     (Gfx_LoadGameVDPRegisterShadows).l
                jsr     (Stage_DispatchVisualAssetLoader).l
                jsr     (Sys_InitStageState).l
                addq.w  #2,(GameSubstateIndex).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  (PrimaryCameraXPosition).w,(TilemapRowXOrFillWord).w
                move.w  (PrimaryCameraYPosition).w,(TilemapRowYPosition).w
Stage_UpdateGameplayEntry_Return:                       ; was: locret_1C448
                                        ; Stage_UpdateGameplayEntry+8E   j
                rts
; ---------------------------------------------------------------------------
Stage_StreamGameplayEntryPrimaryPlane:                  ; was: loc_1C44A
                move.w  (StagePlaneAEntryMode).w,d0
                bne.s   Stage_StreamGameplayEntryPrimaryPlane_Rows
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$4000,(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextConstantRow).l
                jsr     (Tilemap_QueueNextConstantRow).l
                bmi.s   Stage_AdvanceGameplayEntryToSecondaryPlane
                rts
; ---------------------------------------------------------------------------
Stage_StreamGameplayEntryPrimaryPlane_Rows:             ; was: loc_1C46A
                bpl.s   Stage_StreamGameplayEntryPrimaryPlane_DirectRows
                andi.w  #$7FFF,d0
                lea     Stage_EntryPrimaryPlaneVRAMParameterPointers(pc),a0
                nop
                move.l  -4(a0,d0.w),(TilemapTransferBase).w
                jsr     (Tilemap_MirrorOffsetRowAndQueueScrollingRow).l
                jsr     (Tilemap_MirrorOffsetRowAndQueueScrollingRow).l
                bpl.w   Stage_UpdateGameplayEntry_Return
                bra.s   Stage_AdvanceGameplayEntryToSecondaryPlane
; ---------------------------------------------------------------------------
Stage_StreamGameplayEntryPrimaryPlane_DirectRows:       ; was: loc_1C48E
                lea     Stage_EntryPrimaryPlaneVRAMParameterPointers(pc),a0
                nop
                move.l  -4(a0,d0.w),(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.w   Stage_UpdateGameplayEntry_Return
Stage_AdvanceGameplayEntryToSecondaryPlane:             ; was: loc_1C4AA
                                        ; Stage_StreamGameplayEntryPrimaryPlane_Rows+92   j
                addq.w  #2,(GameSubstateIndex).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  (SecondaryCameraXPos).w,(TilemapRowXOrFillWord).w
                move.w  (SecondaryCameraYPos).w,(TilemapRowYPosition).w
                rts
; ---------------------------------------------------------------------------
Stage_StreamGameplayEntrySecondaryPlane:                ; was: loc_1C4C2
                move.w  (StagePlaneBEntryMode).w,d0
                bne.s   Stage_StreamGameplayEntrySecondaryPlane_Rows
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$6000,(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextConstantRow).l
                jsr     (Tilemap_QueueNextConstantRow).l
                bmi.s   Stage_FinishGameplayEntry
                rts
; ---------------------------------------------------------------------------
Stage_StreamGameplayEntrySecondaryPlane_Rows:           ; was: loc_1C4E2
                lea     Stage_EntrySecondaryPlaneVRAMParameterPointers(pc),a0
                nop
                move.l  -4(a0,d0.w),(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.w   Stage_UpdateGameplayEntry_Return
Stage_FinishGameplayEntry:                              ; was: loc_1C4FE
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                move.w  #$10,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                clr.b   (GameplayControlFlags).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
; Enter the selected stage-process handler after the normal setup completes
Stage_EnterSelectedGameplayProcess:                     ; was: loc_1C530
                jmp     Stage_DispatchSelectedProcess
; End of function Stage_UpdateGameplayEntry
; ---------------------------------------------------------------------------
Stage_EntryPrimaryPlaneVRAMParameterPointers:
                dc.l    Gfx_TitleAndZLeoVRAMTransferParameters  ; was: off_1C536
                                        ; Stage_StreamGameplayEntryPrimaryPlane_DirectRows   o
Stage_EntryPrimaryPlaneDefaultVRAMParameterPointer:
                dc.l    Gfx_DefaultVRAMTransferParameters  ; was: off_1C53A
Stage_EntrySecondaryPlaneVRAMParameterPointers:
                dc.l    Gfx_FrontendAlternateVRAMTransferParameters  ; was: off_1C53E
                                        ; XiTigerStage_StreamSecondaryPlane_Rows   o
                dc.l    Gfx_ScrollVRAMTransferParameters

; Initialize the Xi-Tiger stage path, stream both tilemap planes, and enter gameplay
XiTigerStage_UpdateGameplayEntry:                       ; was: sub_1C546
                tst.b   (DataLoaderControl).w
                bmi.s   XiTigerStage_UpdateGameplayEntry_Return
                cmpi.w  #4,(GameSubstateIndex).w
                beq.w   XiTigerStage_StreamSecondaryPlane
                move.w  (GameSubstateIndex).w,d0
                bne.s   XiTigerStage_StreamPrimaryPlane
                jsr     (Sys_ClearObjectAndSpriteState).l
                jsr     (Gfx_LoadGameVDPRegisterShadows).l
                jsr     (Stage_InitializeXiTigerState).l
                move.w  #$8004,(PaletteFadeMode).w
                move.w  #$10,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  (PrimaryCameraXPosition).w,(TilemapRowXOrFillWord).w
                move.w  (PrimaryCameraYPosition).w,(TilemapRowYPosition).w
XiTigerStage_UpdateGameplayEntry_Return:                ; was: locret_1C5A8
                                        ; XiTigerStage_UpdateGameplayEntry+9A   j
                rts
; ---------------------------------------------------------------------------
XiTigerStage_StreamPrimaryPlane:                        ; was: loc_1C5AA
                move.w  (StagePlaneAEntryMode).w,d0
                bne.s   XiTigerStage_StreamPrimaryPlane_Rows
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$4000,(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextConstantRow).l
                jsr     (Tilemap_QueueNextConstantRow).l
                bmi.s   XiTigerStage_AdvanceToSecondaryPlane
                rts
; ---------------------------------------------------------------------------
XiTigerStage_StreamPrimaryPlane_Rows:                   ; was: loc_1C5CA
                lea     Stage_EntryPrimaryPlaneVRAMParameterPointers(pc),a0
                move.l  Stage_EntryPrimaryPlaneVRAMParameterPointers-4-Stage_EntryPrimaryPlaneVRAMParameterPointers(a0,d0.w),(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.w   XiTigerStage_UpdateGameplayEntry_Return
XiTigerStage_AdvanceToSecondaryPlane:                   ; was: loc_1C5E4
                addq.w  #2,(GameSubstateIndex).w
                move.w  #$1F,(TilemapRowCountdown).w
                move.w  (SecondaryCameraXPos).w,(TilemapRowXOrFillWord).w
                move.w  (SecondaryCameraYPos).w,(TilemapRowYPosition).w
                rts
; ---------------------------------------------------------------------------
XiTigerStage_StreamSecondaryPlane:                      ; was: loc_1C5FC
                move.w  (StagePlaneBEntryMode).w,d0
                bne.s   XiTigerStage_StreamSecondaryPlane_Rows
                clr.w   (TilemapRowXOrFillWord).w
                move.w  #$6000,(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextConstantRow).l
                jsr     (Tilemap_QueueNextConstantRow).l
                bmi.s   XiTigerStage_FinishGameplayEntry
                rts
; ---------------------------------------------------------------------------
XiTigerStage_StreamSecondaryPlane_Rows:                 ; was: loc_1C61C
                lea     Stage_EntrySecondaryPlaneVRAMParameterPointers(pc),a0
                move.l  Stage_EntryPrimaryPlaneDefaultVRAMParameterPointer-Stage_EntrySecondaryPlaneVRAMParameterPointers(a0,d0.w),(TilemapTransferBase).w
                jsr     (Tilemap_QueueNextScrollingRow).l
                jsr     (Tilemap_QueueNextScrollingRow).l
                bpl.w   XiTigerStage_UpdateGameplayEntry_Return
XiTigerStage_FinishGameplayEntry:                       ; was: loc_1C636
                move.w  #$10,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                clr.b   (GameplayControlFlags).w
                move.w  #$8004,(PaletteFadeMode).w
                move.w  #$10,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jmp     Stage_DispatchSelectedProcess
; End of function XiTigerStage_UpdateGameplayEntry
