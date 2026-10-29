Stage_DispatchVisualAssetLoader:                        ; was: sub_11DD2
                                        ; Stage_StartTimeBonusAndPreloadNextPhase+12   p
                clr.b   (PendingStageBGMRequest).w
                move.w  (StageTableIndex).w,d0
                movea.w Stage_VisualAssetLoaderOffsets(pc,d0.w),a0
                adda.l  #Stage_ExpandAndSubmitTileAssetCommands,a0
                jmp     (a0)
; End of function Stage_DispatchVisualAssetLoader
; ---------------------------------------------------------------------------
Stage_VisualAssetLoaderOffsets: dc.w    Stage_LoadStage1VisualAssets-Stage_ExpandAndSubmitTileAssetCommands  ; was: off_11DE6
                dc.w    Stage_LoadStage2VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage3VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage4VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage5VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage6VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage7VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage8TrainVisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage9FliesVisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage10VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage11VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage12VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage13Palette-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage14VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage15VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage16VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage17Palettes-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage18VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage19VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage20VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage21VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage22VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage23VisualAssetNoOp-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage_LoadStage24VisualAssets-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage25VisualAssetNoOp-Stage_ExpandAndSubmitTileAssetCommands
                dc.w    Stage26VisualAssetNoOp-Stage_ExpandAndSubmitTileAssetCommands

; Expands compact tile commands into load records and submits the resulting list
Stage_ExpandAndSubmitTileAssetCommands:                 ; was: sub_11E1A
                                        ; Stage_LoadStage2VisualAssets+12   j
                movea.w #(StageAssetCommandBuffer-M68K_RAM),a1
                movea.w #(SpawnedEnemyTileAttr-M68K_RAM),a2
                lea     Stage_SharedTileSourceTable(pc),a3
                nop
Stage_ReadNextTileAssetCommand:                         ; was: loc_11E28
                                        ; Stage_ExpandAndSubmitTileAssetCommands+3E   j
                move.w  (a0)+,d0
                bmi.s   Stage_TerminateAndSubmitExpandedAssetList
                btst    #0,d0
                beq.s   Stage_ExpandIndexedTileAssetCommand
                move.w  d0,(a1)+
                move.l  (a0)+,(a1)+
                move.w  (a0)+,(a1)+
                bra.w   Stage_ReadNextTileAssetCommand
; ---------------------------------------------------------------------------
Stage_ExpandIndexedTileAssetCommand:                    ; was: loc_11E3C
                move.w  d0,d1
                asl.w   #1,d1
                move.w  (a0)+,d2
                move.w  #7,(a1)+
                move.l  (a3,d1.w),(a1)+
                move.w  d2,(a1)+
                lsr.w   #5,d2
                move.w  d2,(a2,d0.w)
                ori.w   #$800,(a2,d0.w)
                bra.w   Stage_ReadNextTileAssetCommand
; ---------------------------------------------------------------------------
; Terminates the expanded record list and submits it to the pointer processor
Stage_TerminateAndSubmitExpandedAssetList:              ; was: loc_11E5C
                move.w  #$FFFF,(a1)
                movea.w #(StageAssetCommandBuffer-M68K_RAM),a0
                jmp     (Data_ProcessPointer).l
; End of function Stage_ExpandAndSubmitTileAssetCommands
; ---------------------------------------------------------------------------
Stage_SharedTileSourceTable:    dc.l    StageSharedTileArtSource00  ; was: off_11E6A
                dc.l    StageSharedTileArtSource02
                dc.l    StageSharedTileArtSource04
                dc.l    StageSharedTileArtSource06
                dc.l    StageSharedTileArtSource08
                dc.l    StageSharedTileArtSource0A
                dc.l    StageSharedTileArtSource0C

; Loads the shared palette and compact tile commands for Stage 1
Stage_LoadStage1VisualAssets:                           ; was: sub_11E86
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage1TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage1VisualAssets
; ---------------------------------------------------------------------------
Stage1TileAssetCommands:    dc.w    0, $6000, 2, $7000, 4, $8000, $FFFF  ; was: word_11E9C

; Loads the shared palette and compact tile commands for Stage 2
Stage_LoadStage2VisualAssets:                           ; was: sub_11EAA
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage2TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage2VisualAssets
; ---------------------------------------------------------------------------
Stage2TileAssetCommands:    dc.w    0, $6000, 2, $7000, $C, $8000, $FFFF  ; was: word_11EC0

; Loads the shared palette and compact tile commands for Stage 3
Stage_LoadStage3VisualAssets:                           ; was: sub_11ECE
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage3TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage3VisualAssets
; ---------------------------------------------------------------------------
Stage3TileAssetCommands:    dc.w    0, $7000, 8, $8000, $FFFF  ; was: word_11EE4

; Loads the shared palette and compact tile commands for Stage 4
Stage_LoadStage4VisualAssets:                           ; was: sub_11EEE
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage4TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage4VisualAssets
; ---------------------------------------------------------------------------
Stage4TileAssetCommands:    dc.w    0, $7000, 8, $8000, $FFFF  ; was: word_11F04

; Loads the shared palette and compact tile commands for Stage 5
Stage_LoadStage5VisualAssets:                           ; was: sub_11F0E
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage5TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage5VisualAssets
; ---------------------------------------------------------------------------
Stage5TileAssetCommands:    dc.w    0, $6000, 2, $7000, 6, $8000, $FFFF  ; was: word_11F24

; Loads the shared palette and compact tile commands for Stage 6
Stage_LoadStage6VisualAssets:                           ; was: sub_11F32
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage6TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage6VisualAssets
; ---------------------------------------------------------------------------
Stage6TileAssetCommands:    dc.w    0, $6000, 2, $7000, 4, $8000, $FFFF  ; was: word_11F48

; Loads the shared palette and compact tile commands for Stage 7
Stage_LoadStage7VisualAssets:                           ; was: sub_11F56
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage7TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage7VisualAssets
; ---------------------------------------------------------------------------
Stage7TileAssetCommands:    dc.w    0, $6000, 4, $7000, 7  ; was: word_11F6C
                dc.l    Stage15TileArt2
                dc.w    $8000, $FFFF

; Loads the shared palette and compact tile commands for the Stage 8 train
Stage_LoadStage8TrainVisualAssets:                      ; was: sub_11F7E
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage8TrainTileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage8TrainVisualAssets
; ---------------------------------------------------------------------------
Stage8TrainTileAssetCommands:   dc.w    0, $6000, 7     ; was: word_11F94
                dc.l    Stage9XiTigerEntranceTileArt
                dc.w    $8000, $FFFF

; Loads the shared palette and compact tile commands for the Stage 9 flies
Stage_LoadStage9FliesVisualAssets:                      ; was: sub_11FA2
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage9FliesTileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage9FliesVisualAssets
; ---------------------------------------------------------------------------
Stage9FliesTileAssetCommands:   dc.w    $C, $8000, $FFFF  ; was: word_11FB8

; Loads the shared palette and compact tile commands for Stage 10
Stage_LoadStage10VisualAssets:                          ; was: sub_11FBE
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage10TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage10VisualAssets
; ---------------------------------------------------------------------------
Stage10TileAssetCommands:   dc.w    0, $6000, 6, $7000, $A, $8000, $FFFF  ; was: word_11FD4

; Loads the shared palette and compact tile commands for Stage 11
Stage_LoadStage11VisualAssets:                          ; was: sub_11FE2
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage11TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage11VisualAssets
; ---------------------------------------------------------------------------
Stage11TileAssetCommands:   dc.w    0, $6000, 6, $7000, 4, $8000, $FFFF  ; was: word_11FF8

; Loads the shared palette and compact tile commands for Stage 12
Stage_LoadStage12VisualAssets:                          ; was: sub_12006
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage12TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage12VisualAssets
; ---------------------------------------------------------------------------
Stage12TileAssetCommands:   dc.w    0, $6000, 6, $7000, $A, $8000, $FFFF  ; was: word_1201C

; Loads the Stage 13 palette command
Stage_LoadStage13Palette:                               ; was: sub_1202A
                lea     (Boss_SnakePaletteCommand).l,a0
                jmp     Gfx_LoadPaletteCommand
; End of function Stage_LoadStage13Palette
; Unreferenced compact command loader for shared tile source zero at $6000
UnreferencedLoadSharedTileSource0To6000:
                lea     UnreferencedSharedTileSource0To6000Command(pc),a0  ; was: sub_12036
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function UnreferencedLoadSharedTileSource0To6000
; ---------------------------------------------------------------------------
UnreferencedSharedTileSource0To6000Command: dc.w    0, $6000, $FFFF  ; was: word_12040

; Loads the shared palette and compact tile commands for Stage 14
Stage_LoadStage14VisualAssets:                          ; was: sub_12046
                bset    #0,(PaletteFadeControlFlags).w
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage14TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage14VisualAssets
; ---------------------------------------------------------------------------
Stage14TileAssetCommands:   dc.w    0, $6000, $FFFF     ; was: word_12062

; Loads the Stage 15 palette and direct tile-asset list
Stage_LoadStage15VisualAssets:                          ; was: sub_12068
                bset    #0,(PaletteFadeControlFlags).w
                lea     (Stage15PaletteCommands).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage15VisualAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_LoadStage15VisualAssets
; ---------------------------------------------------------------------------
Stage15VisualAssetLoadList: dc.w    7                   ; field_0  ; was: stru_12086
                dc.l    Stage15TileArt                  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF

; Loads the shared palette and compact tile commands for Stage 16
Stage_LoadStage16VisualAssets:                          ; was: sub_12090
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage16TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage16VisualAssets
; ---------------------------------------------------------------------------
Stage16TileAssetCommands:   dc.w    $C, $6000, 7        ; was: word_120A6
                dc.l    Boss_BackStringerTileArt2
                dc.w    $7000, $FFFF

; Loads palettes for stage 17
Stage_LoadStage17Palettes:                              ; was: sub_120B4
                lea     (Stage17PaletteCommandBank).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     (Boss_Epsilon1PaletteCommands).l,a0
                jmp     Gfx_LoadPalettePreservingSharedColor
; End of function Stage_LoadStage17Palettes
; Loads the shared palette and compact tile commands for Stage 18
Stage_LoadStage18VisualAssets:                          ; was: sub_120CC
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage18TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage18VisualAssets
; ---------------------------------------------------------------------------
Stage18TileAssetCommands:   dc.w    $C, $6000, 7        ; was: word_120E2
                dc.l    Stage18WormTileArt
                dc.w    $7000, $FFFF

; Loads the shared palette and compact tile commands for Stage 19
Stage_LoadStage19VisualAssets:                          ; was: sub_120F0
                lea     (SharedStagePaletteCommand).l,a0
                jsr     (Gfx_LoadPaletteCommand).l
                lea     Stage19TileAssetCommands(pc),a0
                nop
                bra.w   Stage_ExpandAndSubmitTileAssetCommands
; End of function Stage_LoadStage19VisualAssets
; ---------------------------------------------------------------------------
Stage19TileAssetCommands:   dc.w    6, $6000, $C, $7000, $FFFF  ; was: word_12106

UnreferencedVisualAssetNoOpBeforeStage20:               ; was: nullsub_138
                rts
; End of function UnreferencedVisualAssetNoOpBeforeStage20

; Loads the direct tile-asset list for Stage 20
Stage_LoadStage20VisualAssets:                          ; was: sub_12112
                lea     Stage20VisualAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_LoadStage20VisualAssets
; ---------------------------------------------------------------------------
Stage20VisualAssetLoadList: dc.w    7                   ; field_0  ; was: stru_1211E
                dc.l    Stage20TileArt                  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF

; Loads the direct tile-asset list for Stage 21
Stage_LoadStage21VisualAssets:                          ; was: sub_12128
                lea     Stage21VisualAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_LoadStage21VisualAssets
; ---------------------------------------------------------------------------
Stage21VisualAssetLoadList: dc.w    7                   ; field_0  ; was: stru_12134
                dc.l    Stage21TileArt8000              ; field_2
                dc.w    $8000                           ; field_6
                dc.w    $FFFF

; Loads the direct tile-asset list for Stage 22
Stage_LoadStage22VisualAssets:                          ; was: sub_1213E
                lea     Stage22VisualAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_LoadStage22VisualAssets
; ---------------------------------------------------------------------------
Stage22VisualAssetLoadList: dc.w    7                   ; field_0  ; was: stru_1214A
                dc.l    Stage22And24TileArt             ; field_2
                dc.w    $8000                           ; field_6
                dc.w    $FFFF

; Deliberate no-op visual loader for Stage 23
Stage23VisualAssetNoOp:                                 ; was: nullsub_30
                rts
; End of function Stage23VisualAssetNoOp
; Loads the direct tile-asset list for Stage 24
Stage_LoadStage24VisualAssets:                          ; was: sub_12156
                lea     Stage24VisualAssetLoadList(pc),a0
                nop
                jmp     (Data_ProcessPointer).l
; End of function Stage_LoadStage24VisualAssets
; ---------------------------------------------------------------------------
Stage24VisualAssetLoadList: dc.w    7                   ; field_0  ; was: stru_12162
                dc.l    Stage22And24TileArt             ; field_2
                dc.w    $8000                           ; field_6
                dc.w    $FFFF

; Unreferenced duplicate loader for the Stage 20 tile asset
UnreferencedReloadStage20TileAsset:
                lea     UnreferencedStage20TileReloadList(pc),a0  ; was: sub_1216C
                nop
                jmp     (Data_ProcessPointer).l
; End of function UnreferencedReloadStage20TileAsset
; ---------------------------------------------------------------------------
UnreferencedStage20TileReloadList:  dc.w    7           ; field_0  ; was: stru_12178
                dc.l    Stage20TileArt                  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF

UnreferencedVisualAssetNoOpBeforeSecondaryLoader:       ; was: nullsub_33
                rts
; End of function UnreferencedVisualAssetNoOpBeforeSecondaryLoader

; Deliberate no-op visual loader for Stage 25
Stage25VisualAssetNoOp:                                 ; was: nullsub_31
                rts
; End of function Stage25VisualAssetNoOp
; Deliberate no-op visual loader for Stage 26
Stage26VisualAssetNoOp:                                 ; was: nullsub_32
                rts
; End of function Stage26VisualAssetNoOp
; Unreferenced direct loader for one shared gameplay tile asset
UnreferencedLoadSharedGameplayTileAsset:
                lea     UnreferencedSharedGameplayTileAssetLoadList(pc),a0  ; was: sub_12188
                nop
                jmp     (Data_ProcessPointer).l
; End of function UnreferencedLoadSharedGameplayTileAsset
; ---------------------------------------------------------------------------
UnreferencedSharedGameplayTileAssetLoadList:    dc.w    7  ; field_0  ; was: stru_12194
                dc.l    UnreferencedSharedGameplayTileArt  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF

; Initializes Xi-Tiger stage RAM, configuration, weapon selection, and player state
Stage_InitializeXiTigerState:                           ; was: sub_1219E
                clr.w   (TransitionModeOffset).w
                jsr     (Stage_InitializationNoOpHook).l
                bsr.w   Weapon_ClearAmmoRegenTimers
                clr.w   (FrameSkipLevel).w
                move.w  (WeaponStateIndex).w,d0
                beq.s   Stage_ResetXiTigerWeaponSelection
                cmpi.w  #$10,d0
                bpl.s   Stage_ResetXiTigerWeaponSelection
                asl.w   #1,d0
                move.w  d0,(WeaponIconTransferState).w
                bra.s   Stage_ApplyXiTigerConfigurationAndInitializePlayer
; ---------------------------------------------------------------------------
Stage_ResetXiTigerWeaponSelection:                      ; was: loc_121C4
                                        ; Stage_InitializeXiTigerState+1C   j
                move.w  #2,(WeaponStateIndex).w
                move.w  #4,(WeaponIconTransferState).w
Stage_ApplyXiTigerConfigurationAndInitializePlayer:     ; was: loc_121D0
                bsr.s   Stage_DispatchXiTigerConfiguration
                jsr     (UI_QueueAllWeaponIconTransfers).l
                jmp     Player_InitializeStats
; End of function Stage_InitializeXiTigerState
; Dispatches the Xi-Tiger configuration selected by XiTigerConfigIndex
Stage_DispatchXiTigerConfiguration:                     ; was: sub_121DE
                move.w  (XiTigerConfigIndex).w,d0
                movea.w Stage_XiTigerConfigurationOffsets(pc,d0.w),a0
                adda.l  #Stage_ApplyXiTigerConfiguration,a0
                jmp     (a0)
; End of function Stage_DispatchXiTigerConfiguration
; ---------------------------------------------------------------------------
Stage_XiTigerConfigurationOffsets:  dc.w    Stage_ApplyXiTigerConfiguration-Stage_ApplyXiTigerConfiguration  ; was: off_121EE

; Applies the Xi-Tiger stage record and enters the shared color-table initializer
Stage_ApplyXiTigerConfiguration:                        ; was: sub_121F0
                                        ; ROM:Stage_XiTigerConfigurationOffsets   o
                lea     XiTigerStageConfigRecord(pc),a0
                nop
                bsr.w   Stage_ApplyConfigurationRecord
                bra.w   Stage_ClearPaletteHighBitsBeforeFourRangeFill
; End of function Stage_ApplyXiTigerConfiguration
; ---------------------------------------------------------------------------
XiTigerStageConfigRecord:   dc.w    $76                 ; StageStateOffset  ; was: stru_121FE
                dc.l    $80000000                       ; StageObjectSpawnCursor
                dc.w    0                               ; EnemySpawnDirectorState
                dc.b    0                               ; PalettePrimaryIndex+1
                dc.b    0                               ; PaletteSecondaryIndex+1
                dc.w    $8000                           ; GlobalSpritePriorityBit
                dc.w    $800                            ; word at PrimaryCameraXPosition
                dc.w    0                               ; word at PrimaryCameraYPosition
                dc.w    0                               ; word at SecondaryCameraXPos
                dc.w    0                               ; word at SecondaryCameraYPos
                dc.w    8                               ; StagePlaneAEntryMode
                dc.w    0                               ; StagePlaneBEntryMode
                dc.b    $F0                             ; byte biased by $80 -> word at PlayerXPosition
                dc.b    $A8                             ; byte biased by $80 -> word at PlayerYPosition
                dc.l    XiTigerAndStage9PaletteOffsetList  ; palette offset list pointer

; Initializes stage state including RAM clear and player stats
