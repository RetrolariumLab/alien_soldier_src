; Initializes the Z-Leo ending scene's player, assets, palette, and scroll position
ZLeoEnding_InitializeScene:                             ; DATA XREF: ROM:0001E850   o  ; was: sub_1EDC2
                move.w  #$7FFF,(StageTimeRemaining).w
                jsr     (Player_InitializeStats).l
                move.w  #$5C,(PlayerStateOffset).w      ; '\'
                move.b  #0,(VDPReg18Shadow+1).w
                lea     ZLeoEnding_AssetLoadDescriptors(pc),a0
                nop
                jsr     (LoadObjData).l
                lea     (Stage26PaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                move.w  #$1000,(PrimaryCameraXPosition).w
                move.w  #$EC00,(PrimaryCameraYPosition).w
                jsr     (Tilemap_DirectTransferFromPrimaryCamera).l
                move.w  #$EC10,(PrimaryCameraYPosition).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                rts
; End of function ZLeoEnding_InitializeScene
; ---------------------------------------------------------------------------
ZLeoEnding_AssetLoadDescriptors:    dc.w    7           ; field_0  ; was: stru_1EE12
                                        ; DATA XREF: ZLeoEnding_InitializeScene+18   o
                dc.l    Stage3Phase7AndZLeoEndingTileArt0000  ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3Phase7AndZLeoEndingMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3Phase7AndZLeoEndingMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3SharedMappingData7000     ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Updates the player, Z-Leo ending controller, objects, projectiles, and tilemap
ZLeoEnding_UpdateScene:                                 ; DATA XREF: ROM:0001E866   o  ; was: sub_1EE3C
                jsr     (Player_Update).l
                jsr     (Boss_ZLeoMainController).l
                jsr     (Sys_UpdateObjectSpawner).l
                jsr     (Projectile_ProcessVisiblePool).l
                jmp     Tilemap_QueuePrimaryCameraColumnOffset158
; End of function ZLeoEnding_UpdateScene
; Enters the shared ending sequence from transition route four
EndingSequence_InitializeFromTransition:                ; DATA XREF: ROM:0001E852   o  ; was: sub_1EE5A
                move.b  #0,(VDPReg18Shadow+1).w
                jmp     (EndingSequence_Initialize).l
; End of function EndingSequence_InitializeFromTransition
; Updates the shared ending sequence or advances after it signals completion
EndingSequence_UpdateFromTransition:                    ; DATA XREF: ROM:0001E868   o  ; was: sub_1EE66
                tst.w   (EndingSequenceComplete).w
                bne.w   EndingSequence_AdvanceStage
                jmp     (EndingSequence_Dispatch).l
; ---------------------------------------------------------------------------
EndingSequence_AdvanceStage:                            ; CODE XREF: EndingSequence_UpdateFromTransition+4   j  ; was: loc_1EE74
                clr.w   (StatusDisplayModeOffset).w
                addq.w  #2,(StageTableIndex).w
                bclr    #7,(StageObjectSpawnCursor).w
                clr.b   (StageRouteFlags).w
                clr.b   (PlaneAScrollModeFlags).w
                clr.b   (PlaneBScrollModeFlags).w
                move.b  #$97,d0
                jsr     (Sound_QueueBGMRequest).l
                jmp     StageTransition_LoadStage
; End of function EndingSequence_UpdateFromTransition
; Initializes the weapon-setup screen and queues its font DMA
WeaponSetup_InitializeScreen:                           ; DATA XREF: Sys_DispatchGameState+C6   o  ; was: sub_1EE9E
                tst.w   (GameSubstateIndex).w
                bne.s   WeaponSetup_ActivateScreen
                clr.w   (SetupTransitionIndex).w
                clr.b   (MessageDisplayFlags).w
                move.w  #2,(ShootingMode).w
                jsr     (Sys_InitGameMode).l
                jsr     (Sys_ClearEntityObjectPool).l
                move.w  #4,(PaletteFadeMode).w
                move.w  #$FFF4,(PaletteFadeColorOffset).w
                move.w  #$E000,(PaletteFadeMaskStatus).w
                jsr     (Gfx_FadePaletteTransition).l
                bclr    #6,(VDPReg1Shadow+1).w
                clr.b   (PaletteDMAHIntEnabled).w
                addq.w  #2,(GameSubstateIndex).w
                jmp     Gfx_QueueLargeFontDMA
; ---------------------------------------------------------------------------
; Activates the weapon-setup screen and its interactive test arena
WeaponSetup_ActivateScreen:                             ; CODE XREF: WeaponSetup_InitializeScreen+4   j  ; was: loc_1EEEA
                addq.w  #4,(GameModeIndex).w
                clr.w   (GameSubstateIndex).w
                lea     WeaponSetup_AssetLoadDescriptors(pc),a0
                nop
                jsr     (LoadObjData).l
                move.b  #1,(WeaponSetupWriteFlag).l
                clr.w   d0
                clr.w   d1
                lea     (Gfx_DefaultVRAMTransferParameters).l,a0
                jsr     (Tilemap_TransferFullMapDirectToVRAM).l
                jsr     (Stage_InitializationNoOpHook).l
                bsr.w   WeaponSetup_ClearLoadoutAndRefillAmmo
                jsr     (Player_InitializeStats).l
                bsr.w   WeaponSetup_InitializeColorTables
                move.w  #$20,(RasterEffectIndex).w      ; ' '
                clr.w   (RasterEffectInitState).w
                move.w  #6,(RasterLayoutOffset).w
                move.b  #2,(PlaneAScrollModeFlags).w
                move.w  #$7000,d0
                move.w  d0,(BossHealth).w
                move.w  d0,(BossMaxHealth).w
                move.w  d0,(DisplayedBossHealth).w
                move.w  (PlayerHealth).w,(DisplayedPlayerHealth).w
                move.w  #$12,(PlayerScriptStateOffset).w
                move.w  #$DA,(PlayerXPosition).w
                move.w  #$130,(PlayerYPosition).w
                move.w  #$330,(StageTimeRemaining).w
                bset    #0,(StageTimerPauseFlag).w
                move.w  #$8000,(GlobalSpritePriorityBit).w
                lea     (StageStartPaletteOffsetList).l,a4
                jsr     (Gfx_LoadMultiplePalettes).l
                bsr.w   WeaponSetup_InitializeTextAndTiles
                jsr     (UI_QueueSelectedWeaponIconTransfer).l
                move.b  #$8E,d0
                jsr     (Sound_QueueBGMRequest).l
                move.l  #$1400000,(WeaponSetupBgPhase).w
                clr.w   (WeaponSetupHighlight).w
                bset    #6,(VDPReg1Shadow+1).w
                move.b  #$80,(PaletteDMAHIntEnabled).w
                jmp     (Gfx_FadePaletteTransition).l
; End of function WeaponSetup_InitializeScreen
; ---------------------------------------------------------------------------
WeaponSetup_AssetLoadDescriptors:   dc.w    3           ; field_0  ; was: stru_1EFB8
                                        ; DATA XREF: WeaponSetup_InitializeScreen+54   o
                dc.l    WeaponSetupType3Data5800        ; field_2
                dc.w    $5800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedFrontendAndTransitionTileArt  ; field_2
                dc.w    $E000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    WeaponSetupTileArtE300          ; field_2
                dc.w    $E300                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    StageEntryAndWeaponSetupTileArtDE00  ; field_2
                dc.w    $DE00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    WeaponSetupMappingData6000      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    WeaponSetupMappingData4020      ; field_2
                dc.w    $4020                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedGameplayTileArtD000       ; field_2
                dc.w    $D000                           ; field_6
                dc.w    3                               ; field_0 ; another compression type?
                dc.l    SharedMenuType3DataF680         ; field_2
                dc.w    $F680                           ; field_6
                dc.w    $FFFF

; Initializes the weapon-setup screen's three color lookup tables in RAM
WeaponSetup_InitializeColorTables:                      ; CODE XREF: WeaponSetup_InitializeScreen+88   p  ; was: sub_1F002
                lea     (PlaneTilemapRow26).l,a0
                lea     (PlaneTilemapRow27).l,a1
                lea     (PlaneTilemapRow28).l,a2
                move.w  #$FF,d1
                moveq   #$3F,d7                         ; '?'
WeaponSetup_InitializeColorTables_Loop:                 ; CODE XREF: WeaponSetup_InitializeColorTables+1E   j  ; was: loc_1F01A
                move.w  d1,(a0)+
                move.w  d1,(a1)+
                move.w  d1,(a2)+
                dbf     d7,WeaponSetup_InitializeColorTables_Loop
                move.b  #$82,(WeaponSetupTilemapMode).l
                rts
; End of function WeaponSetup_InitializeColorTables
; Initializes weapon-setup text and the six force-name tile regions
WeaponSetup_InitializeTextAndTiles:                     ; CODE XREF: WeaponSetup_InitializeScreen+E8   p  ; was: sub_1F02E
                bsr.w   WeaponSetup_RenderHeading
                bsr.w   WeaponSetup_FindControlTypeIndex
                bsr.w   WeaponSetup_RenderStatusAndControlType
                bsr.w   WeaponSetup_RenderExitText
                lea     WeaponSetup_ForceTextLayout(pc),a2
                nop
                moveq   #0,d7
WeaponSetup_InitializeForceTileLoop:                    ; CODE XREF: WeaponSetup_InitializeTextAndTiles+2C   j  ; was: loc_1F046
                move.w  (a2,d7.w),d3
                subq.w  #6,d3
                move.w  d7,d0
                jsr     (UI_QueueWeaponIconTileTransfer).l
                addq.w  #2,d7
                cmpi.w  #$C,d7
                bmi.s   WeaponSetup_InitializeForceTileLoop
WeaponSetup_StateWaitReturn:                            ; CODE XREF: WeaponSetup_HandleLoadoutState+C   j  ; was: locret_1F05C
                                        ; WeaponSetup_HandleControlTypeInput+C   j
                rts
; End of function WeaponSetup_InitializeTextAndTiles
; Clears all four loadout slots, then refills their runtime ammunition
WeaponSetup_ClearLoadoutAndRefillAmmo:                  ; CODE XREF: WeaponSetup_InitializeScreen+7E   p  ; was: sub_1F05E
                clr.w   (WeaponSlotOffset).w
                clr.w   (WeaponSlotConfig0).w
                clr.w   (WeaponSlotConfig1).w
                clr.w   (WeaponSlotConfig2).w
                clr.w   (WeaponSlotConfig3).w
; End of function WeaponSetup_ClearLoadoutAndRefillAmmo
; Refills the eight weapon-ammunition words used by the setup screen
WeaponSetup_RefillAmmo:                                 ; CODE XREF: WeaponSetup_HandleLoadoutState+16   p  ; was: sub_1F072
                                        ; WeaponSetup_HandleShootingModeInput+C   p
                movea.w #(WeaponSlotAmmo0-M68K_RAM),a0
                move.w  #$3E8,d0
                moveq   #7,d7
WeaponSetup_RefillAmmoLoop:                             ; CODE XREF: WeaponSetup_RefillAmmo+C   j  ; was: loc_1F07C
                move.w  d0,(a0)+
                dbf     d7,WeaponSetup_RefillAmmoLoop
                rts
; End of function WeaponSetup_RefillAmmo
; Updates the interactive weapon-setup screen, player, HUD, objects, and rendering
WeaponSetup_UpdateScreen:                               ; DATA XREF: Sys_DispatchGameState+CA   o  ; was: sub_1F084
                jsr     (Object_ApplyCameraMotion).l
                jsr     (Collision_UpdateSystem).l
                jsr     (Sprite_InitializePriorityBuckets).l
                jsr     (Sys_BeginVisibleObjectList).l
                jsr     (UI_BuildHUDSpriteList).l
                jsr     (UI_UpdateGameplayHUD).l
                jsr     (Player_Update).l
                jsr     (Weapon_UpdateStateAndAmmoRegen).l
                jsr     (Projectile_ProcessVisiblePool).l
                jsr     (Sys_ProcessVisibleObjects).l
                bsr.w   WeaponSetup_UpdateAndDispatchState
                jsr     (Sys_UpdateObjectCount).l
                jsr     (Sprite_RenderObjectList).l
                jsr     (Gfx_FadePaletteTransition).l
                jsr     (Scroll_PreparePlaneBuffersAndRegisterShadows).l
                addq.w  #1,(FrameCounter).w
                bclr    #0,(PaletteFadeMaskStatus).w
                beq.s   WeaponSetup_UpdateScreen_CheckExit
                addq.w  #2,(GameSubstateIndex).w
                rts
; ---------------------------------------------------------------------------
WeaponSetup_UpdateScreen_CheckExit:                     ; CODE XREF: WeaponSetup_UpdateScreen+62   j  ; was: loc_1F0EE
                bclr    #1,(PaletteFadeMaskStatus).w
                bne.s   WeaponSetup_UpdateScreen_HandleExit
                rts
; ---------------------------------------------------------------------------
WeaponSetup_UpdateScreen_HandleExit:                    ; CODE XREF: WeaponSetup_UpdateScreen+70   j  ; was: loc_1F0F8
                tst.w   (StageTableIndex).w
                bne.s   WeaponSetup_ExitToStageReady
                move.l  #StageTransitionMessageSequence_StageZero,(StageMessageCursor).w  ; text?
                move.w  #$34,(GameModeIndex).w          ; '4'
                clr.w   (GameSubstateIndex).w
                jsr     (Sound_QueueStageBGMOrStop).l
                jmp     Game_InitializeNewSession
; ---------------------------------------------------------------------------
; Leaves weapon setup through the nonzero-stage ready-screen route
WeaponSetup_ExitToStageReady:                           ; CODE XREF: WeaponSetup_UpdateScreen+78   j  ; was: loc_1F11C
                move.w  #$3C,(GameModeIndex).w          ; '<'
                clr.w   (GameSubstateIndex).w
                jmp     UI_ResetPaletteAndMessageMode_Clear
; End of function WeaponSetup_UpdateScreen
; Updates the setup background and dispatches the current setup-screen state
WeaponSetup_UpdateAndDispatchState:                     ; CODE XREF: WeaponSetup_UpdateScreen+3C   p  ; was: sub_1F12C
                bsr.w   WeaponSetup_UpdateBackgroundEffect
                move.w  (SetupTransitionIndex).w,d0
                movea.w WeaponSetup_StateHandlerOffsets(pc,d0.w),a0
                adda.l  #WeaponSetup_HandleLoadoutState,a0
                jmp     (a0)
; End of function WeaponSetup_UpdateAndDispatchState
; ---------------------------------------------------------------------------
WeaponSetup_StateHandlerOffsets:    dc.w    WeaponSetup_HandleLoadoutState-WeaponSetup_HandleLoadoutState  ; was: off_1F140
                                        ; DATA XREF: WeaponSetup_UpdateAndDispatchState+8   r
                dc.w    WeaponSetup_HandleControlTypeInput-WeaponSetup_HandleLoadoutState
                dc.w    WeaponSetup_HandleExitInput-WeaponSetup_HandleLoadoutState
                dc.w    WeaponSetup_UpdateExitTilemapFill-WeaponSetup_HandleLoadoutState
                dc.w    WeaponSetup_RenderControlTestRowsAndLoadPalette-WeaponSetup_HandleLoadoutState
                dc.w    WeaponSetup_WaitForConfirmInput-WeaponSetup_HandleLoadoutState
                dc.w    WeaponSetup_IdleState-WeaponSetup_HandleLoadoutState

; Handles the four-slot loadout-selection state
WeaponSetup_HandleLoadoutState:                         ; DATA XREF: WeaponSetup_UpdateAndDispatchState+C   o  ; was: sub_1F14E
                                        ; ROM:WeaponSetup_StateHandlerOffsets   o
                bsr.w   WeaponSetup_RenderSlotSprites
                bsr.w   WeaponSetup_UpdateHighlightPalette
                bsr.w   WeaponSetup_UpdateVerticalScroll
                bne.w   WeaponSetup_StateWaitReturn
                move.w  #$12,(PlayerScriptStateOffset).w
                bsr.w   WeaponSetup_RefillAmmo
                bsr.w   WeaponSetup_HandleLoadoutInput
                btst    #0,(VBlankFrameCounter+1).w
                bne.s   WeaponSetup_RenderSelectedForceCursor
                rts
; ---------------------------------------------------------------------------
; Renders the cursor at the selected force in the current loadout slot
WeaponSetup_RenderSelectedForceCursor:                  ; CODE XREF: WeaponSetup_HandleLoadoutState+24   j  ; was: loc_1F176
                movea.w #(SharedSpriteScratch-M68K_RAM),a0
                movea.w a0,a1
                move.w  (WeaponSetupForceIndex).w,d0
                move.w  WeaponSetup_ForceCursorYPositions(pc,d0.w),(a1)+
                move.w  #$B00,(a1)+
                move.w  #$C6F0,(a1)+
                move.w  WeaponSetup_ForceCursorXPositions(pc,d0.w),(a1)+
                move.w  #$FFFF,(a1)+
                jmp     (Sprite_AppendOAMEntries).l
; End of function WeaponSetup_HandleLoadoutState
; ---------------------------------------------------------------------------
WeaponSetup_ForceCursorXPositions:  dc.w    $97, $127, $97, $127, $97, $127  ; was: word_1F19A
                                        ; DATA XREF: WeaponSetup_HandleLoadoutState+3E   r
WeaponSetup_ForceCursorYPositions:  dc.w    $B8, $B8, $C8, $C8, $D8, $D8  ; was: word_1F1A6
                                        ; DATA XREF: WeaponSetup_HandleLoadoutState+32   r
