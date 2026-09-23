; Runs the two-phase title-screen initialization selected by GameSubstateIndex
TitleScreen_Initialize:                                 ; DATA XREF: Sys_DispatchGameState+6A   o  ; was: sub_9322
                tst.w   (GameSubstateIndex).w
                bne.s   TitleScreen_FinalizeInitialization
                jsr     (Sys_InitGameMode).l
                jsr     (Sys_ClearEntityObjectPool).l
                lea     Frontend_TitleAssetLoadDescriptors(pc),a0
                nop
                jsr     (LoadObjData).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMACommand81
; ---------------------------------------------------------------------------
; Builds the title planes, queues the menu copy, and enables the display
TitleScreen_FinalizeInitialization:                     ; CODE XREF: TitleScreen_Initialize+4   j  ; was: loc_936C
                move.w  #$18,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                movea.l #FlyingNeoTileAttrRangeA,a0
                move.w  #$C180,d0
                moveq   #$26,d7                         ; '&'
                jsr     (Gfx_AdjustTileIndexRows).l
                movea.l #SharedTilemapWorkspace,a0
                move.w  #$6000,d0
                move.w  #$FF00,d1
                move.w  #$BF,d7
                jsr     (Gfx_UpdateTilemapIndices).l
                lea     (Gfx_TitleAndZLeoVRAMTransferParameters).l,a0
                moveq   #0,d0
                moveq   #0,d1
                move.w  d0,(PrimaryCameraXPosition).w
                move.w  d1,(PrimaryCameraYPosition).w
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                lea     (Gfx_FrontendAlternateVRAMTransferParameters).l,a0
                move.w  #$600,d0
                move.w  #0,d1
                move.w  d0,(SecondaryCameraXPos).w
                move.w  d1,(SecondaryCameraYPos).w
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                if      BuildProfileEU
                move.w  #$FFF0,(PrimaryCameraYPosition).w
                endif
                move.b  #0,(VDPReg18Shadow+1).w
                move.w  #2,(TitleMenuSelection).w
                move.b  #$91,d0
                jsr     (Sound_QueueRequest).l
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                if      BuildProfileJP
                lea     (Text_TitleFeatureList).l,a0
                move.w  #$A300,d0
                move.w  #$4086,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_MegaDriveTagline).l,a0
                move.w  #$A300,d0
                move.w  #$4202,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                endif
                lea     (Text_ForMegaDriversCustom).l,a0
                move.w  #$8300,d0
                move.w  #$4892,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (Text_SegaCopyright1995).l,a0
                move.w  #$A300,d0
                move.w  #$4C0C,d4
                jsr     (Text_QueueDoubleHeightStringWrapped).l
                lea     (FrontendPaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                jmp     (Gfx_FadePaletteTransition).l
; End of function TitleScreen_Initialize
; ---------------------------------------------------------------------------
; Preserved 26-byte block with no static source reference or established role
TitleScreen_UnreferencedData:   binclude "data/other/title_screen_unreferenced.bin"  ; was: unused_1

; Handles title navigation, the attract-demo trigger, confirmation, and rendering
TitleScreen_Update:                                     ; DATA XREF: Sys_DispatchGameState+6E   o  ; was: sub_9478
                tst.w   (PaletteFadeColorOffset).w
                bne.w   TitleScreen_UpdateAndRender
                move.b  (ControllerPressedState).w,d0
                andi.b  #$C,d0
                beq.s   TitleScreen_ReadSelection
                move.b  #$DB,d0
                jsr     (Sound_QueueRequest).l
TitleScreen_ReadSelection:                              ; CODE XREF: TitleScreen_Update+10   j  ; was: loc_9494
                move.w  (TitleMenuSelection).w,d0
                btst    #2,(ControllerPressedState).w
                beq.s   TitleScreen_CheckMoveDown
                subq.w  #2,d0
                bpl.s   TitleScreen_StoreSelection
                moveq   #0,d0
TitleScreen_CheckMoveDown:                              ; CODE XREF: TitleScreen_Update+26   j  ; was: loc_94A6
                btst    #3,(ControllerPressedState).w
                beq.s   TitleScreen_StoreSelection
                addq.w  #2,d0
                cmpi.w  #6,d0
                bmi.s   TitleScreen_StoreSelection
                moveq   #4,d0
TitleScreen_StoreSelection:                             ; CODE XREF: TitleScreen_Update+2A   j  ; was: loc_94B8
                                        ; TitleScreen_Update+34   j
                andi.w  #6,d0
                move.w  d0,(TitleMenuSelection).w
                ; The first comparison has no consumer; the following one
                ; controls the preserved attract-demo trigger at frame $700
                cmpi.w  #$780,(FrameCounter).w
                cmpi.w  #$700,(FrameCounter).w
                bne.s   TitleScreen_CheckConfirm
                move.w  #1,(DemoPlaybackActive).w
                clr.w   (DemoPlaybackState).w
                rts
; ---------------------------------------------------------------------------
TitleScreen_CheckConfirm:                               ; CODE XREF: TitleScreen_Update+54   j  ; was: loc_94DA
                btst    #7,(ControllerPressedState).w
                beq.s   TitleScreen_UpdateAndRender
                move.b  #2,(SoundFadeOutDelay).w
                move.b  #$C4,d0
                jsr     (Sound_QueueRequest).l
                clr.w   (GameSubstateIndex).w
                tst.w   (DemoPlaybackActive).w
                beq.s   TitleScreen_DispatchSelection
                move.w  #$70,(GameModeIndex).w          ; 'p'
                jsr     (Game_InitializeNewSession).l
                move.w  (DemoStageTableIndex).w,(StageTableIndex).w
                rts
; ---------------------------------------------------------------------------
TitleScreen_DispatchSelection:                          ; CODE XREF: TitleScreen_Update+82   j  ; was: loc_9510
                move.w  (TitleMenuSelection).w,d0
                beq.s   TitleScreen_OpenPassword
                ; Duplicate zero test is unreachable but byte-significant
                beq.s   TitleScreen_UpdateAndRender
                subq.w  #2,d0
                beq.s   TitleScreen_StartGame
                move.w  #$1C,(GameModeIndex).w
                rts
; ---------------------------------------------------------------------------
TitleScreen_OpenPassword:                               ; CODE XREF: TitleScreen_Update+9C   j  ; was: loc_9524
                move.w  #$44,(GameModeIndex).w          ; 'D'
                rts
; ---------------------------------------------------------------------------
TitleScreen_StartGame:                                  ; CODE XREF: TitleScreen_Update+A2   j  ; was: loc_952C
                move.w  #$70,(GameModeIndex).w          ; 'p'
                jmp     Game_InitializeNewSession
; ---------------------------------------------------------------------------
TitleScreen_UpdateAndRender:                            ; CODE XREF: TitleScreen_Update+4   j  ; was: loc_9538
                                        ; TitleScreen_Update+68   j
                addq.w  #1,(FrameCounter).w
                cmpi.w  #$200,(FrameCounter).w
                bne.s   TitleScreen_RenderMenu
                move.b  #$10,d0
                jsr     (Sound_QueueRequest).l
TitleScreen_RenderMenu:                                 ; CODE XREF: TitleScreen_Update+CA   j  ; was: loc_954E
                move.w  #$A300,d0
                cmpi.w  #2,(TitleMenuSelection).w
                beq.s   TitleScreen_DrawGameStart
                move.w  #$C300,d0
TitleScreen_DrawGameStart:                              ; CODE XREF: TitleScreen_Update+E0   j  ; was: loc_955E
                bsr.w   TitleScreen_QueueGameStart
                move.w  #$A300,d0
                cmpi.w  #4,(TitleMenuSelection).w
                beq.s   TitleScreen_DrawOptions
                move.w  #$C300,d0
TitleScreen_DrawOptions:                                ; CODE XREF: TitleScreen_Update+F4   j  ; was: loc_9572
                bsr.w   TitleScreen_QueueOptions
                move.w  #$A300,d0
                tst.w   (TitleMenuSelection).w
                beq.s   TitleScreen_DrawPassword
                move.w  #$C300,d0
TitleScreen_DrawPassword:                               ; CODE XREF: TitleScreen_Update+106   j  ; was: loc_9584
                bsr.w   TitleScreen_QueuePassword
                jsr     Frontend_AnimateMenuPalette(pc)  ; (pc)
                nop
                jsr     (Gfx_FadePaletteTransition).l
                jmp     Scroll_PreparePlaneBuffersAndRegisterShadows
; End of function TitleScreen_Update
; Queues the GAME START string with the tile attributes already selected in d0
TitleScreen_QueueGameStart:                             ; CODE XREF: TitleScreen_Update:TitleScreen_DrawGameStart   p  ; was: sub_959A
                movea.l #Text_GameStart,a0
                move.w  #$4A9E,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function TitleScreen_QueueGameStart
; Queues the OPTIONS string with the tile attributes already selected in d0
TitleScreen_QueueOptions:                               ; CODE XREF: TitleScreen_Update:TitleScreen_DrawOptions   p  ; was: sub_95AA
                movea.l #Text_Options,a0
                move.w  #$4ABA,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function TitleScreen_QueueOptions
; Queues the PASSWORD string with the tile attributes already selected in d0
TitleScreen_QueuePassword:                              ; CODE XREF: TitleScreen_Update:TitleScreen_DrawPassword   p  ; was: sub_95BA
                movea.l #Text_Password,a0
                move.w  #$4A86,d4
                jmp     (Text_QueueDoubleHeightStringWrapped).l
; End of function TitleScreen_QueuePassword
