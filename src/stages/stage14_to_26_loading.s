Stage_LoadStage14To16Assets:                            ; was: sub_11A5C
                                        ; ROM:00011752   o
                move.w  #4,(StageProcessTableOffset).w
                lea     Stage14To16AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage14To16Assets
; ---------------------------------------------------------------------------
Stage14To16AssetLoadList:   dc.w    7                   ; field_0  ; was: stru_11A6E
                dc.l    Stage14To16TileArt0000          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage14To16TileArt5F00          ; field_2
                dc.w    $5F00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage14To16MappingData6000      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage14To16MappingData4020      ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage14To16MappingData7800      ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 17 asset list
Stage_LoadStage17Assets:                                ; was: sub_11AB0
                move.w  #4,(StageProcessTableOffset).w
                lea     Stage17AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage17Assets
; ---------------------------------------------------------------------------
Stage17AssetLoadList:   dc.w    7                       ; field_0  ; was: stru_11AC2
                dc.l    Stage17TileArt0000              ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage17TileArt6000              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage17MappingData6000          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage17MappingData4000          ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 18 asset list
Stage_LoadStage18And19Assets:                           ; was: sub_11AF4
                                        ; ROM:0001175A   o
                move.w  #8,(StageProcessTableOffset).w
                lea     Stage18And19AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage18And19Assets
; ---------------------------------------------------------------------------
Stage18And19AssetLoadList:  dc.w    7                   ; field_0  ; was: stru_11B06
                dc.l    Stage18And19TileArt0000         ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage18And19TileArt2A00         ; field_2
                dc.w    $2A00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage18And19MappingData6000     ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage18And19MappingData6400     ; field_2
                dc.w    $6400                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage18And19MappingData4020     ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage18And19MappingData6800     ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage18And19MappingData2020     ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedStage18AndStage20MappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage18And19MappingData7800     ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage18And19TileArt8E00         ; field_2
                dc.w    $8E00                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Unreferenced loader for the alternate Stage 17 asset list
UnreferencedStage17AlternateAssetLoader:
                move.w  #8,(StageProcessTableOffset).w  ; was: sub_11B60
                lea     UnreferencedStage17AlternateAssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function UnreferencedStage17AlternateAssetLoader
; ---------------------------------------------------------------------------
UnreferencedStage17AlternateAssetLoadList:  dc.w    7   ; field_0  ; was: stru_11B72
                dc.l    UnreferencedStage17AlternateTileArt0000  ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    UnreferencedStage17AlternateMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    UnreferencedStage17AlternateMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedStage18AndStage20MappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 20 asset list
Stage_LoadStage20Assets:                                ; was: sub_11B9C
                move.w  #8,(StageProcessTableOffset).w
                lea     Stage20AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage20Assets
; ---------------------------------------------------------------------------
Stage20AssetLoadList:   dc.w    7                       ; field_0  ; was: stru_11BAE
                dc.l    Stage20TileArt0000              ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage20TileArt3000              ; field_2
                dc.w    $3000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage20MappingData6800          ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage20MappingData2020          ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage20MappingData6000          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage20MappingData6200          ; field_2
                dc.w    $6200                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage20MappingData6400          ; field_2
                dc.w    $6400                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage20MappingData4020          ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedStage18AndStage20MappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 23 asset list
Stage_LoadStage23Assets:                                ; was: sub_11C00
                move.w  #$C,(StageProcessTableOffset).w
                bset    #0,(PlayerModeFlags).w
                bset    #7,(CameraMotionLockFlags).w
                bra.s   Stage_SubmitStage21To23SharedAssetList
; End of function Stage_LoadStage23Assets
; Prepares resampled tiles and loads the shared Stages 21 to 23 asset list
Stage_LoadStage21And22Assets:                           ; was: sub_11C14
                                        ; ROM:00011760   o
                move.w  #$C,(StageProcessTableOffset).w
                bset    #0,(PlayerModeFlags).w
                bset    #7,(CameraMotionLockFlags).w
                bsr.w   Gfx_PrepareStage21And22ResampledTiles
Stage_SubmitStage21To23SharedAssetList:                 ; was: loc_11C2A
                lea     Stage21To23SharedAssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage21And22Assets
; ---------------------------------------------------------------------------
Stage21To23SharedAssetLoadList: dc.w    7               ; field_0  ; was: stru_11C36
                dc.l    Stage21To23TileArt              ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To23MappingData6000      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To23MappingData4020      ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To23MappingData5A00      ; field_2
                dc.w    $5A00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To26SharedMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To23MappingData7800      ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 24 asset list
Stage_LoadStage24Assets:                                ; was: sub_11C70
                move.w  #$C,(StageProcessTableOffset).w
                lea     Stage24AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage24Assets
; ---------------------------------------------------------------------------
Stage24AssetLoadList:   dc.w    7                       ; field_0  ; was: stru_11C82
                dc.l    Stage24TileArt0000              ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage24Tiles                    ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage24MappingData6000          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage24MappingData4020          ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To26SharedMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Unreferenced loader for the first late-stage variant asset list
UnreferencedLateStageVariantAAssetLoader:
                move.w  #$C,(StageProcessTableOffset).w  ; was: sub_11CB4
                lea     UnreferencedLateStageVariantAAssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function UnreferencedLateStageVariantAAssetLoader
; ---------------------------------------------------------------------------
UnreferencedLateStageVariantAAssetLoadList: dc.w    7   ; field_0  ; was: stru_11CC6
                dc.l    UnreferencedLateStageVariantATileArt0000  ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    UnreferencedLateStageVariantATileArt5800  ; field_2
                dc.w    $5800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    UnreferencedLateStageVariantAMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    UnreferencedLateStageVariantAMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To26SharedMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Unreferenced loader for the second late-stage variant asset list
UnreferencedLateStageVariantBAssetLoader:
                move.w  #$C,(StageProcessTableOffset).w  ; was: sub_11CF8
                lea     UnreferencedLateStageVariantBAssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function UnreferencedLateStageVariantBAssetLoader
; ---------------------------------------------------------------------------
UnreferencedLateStageVariantBAssetLoadList: dc.w    7   ; field_0  ; was: stru_11D0A
                dc.l    UnreferencedLateStageVariantBTileArt0000  ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    UnreferencedLateStageVariantBMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    UnreferencedLateStageVariantBMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To26SharedMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 25 asset list
Stage_LoadStage25Assets:                                ; was: sub_11D34
                move.w  #$C,(StageProcessTableOffset).w
                lea     Stage25AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage25Assets
; ---------------------------------------------------------------------------
Stage25AssetLoadList:   dc.w    7                       ; field_0  ; was: stru_11D46
                dc.l    Stage25TileArt0000              ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage25TileArt1800              ; field_2
                dc.w    $1800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage25MappingData6000          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage25MappingData4020          ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage25MappingData6800          ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage25ZLeoEntryMappingData2020  ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To26SharedMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage25MappingData7800          ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads the Stage 26 asset list
Stage_LoadStage26Assets:                                ; was: sub_11D90
                move.w  #$C,(StageProcessTableOffset).w
                bset    #0,(PlayerModeFlags).w
                lea     Stage26AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage26Assets
; ---------------------------------------------------------------------------
Stage26AssetLoadList:   dc.w    7                       ; field_0  ; was: stru_11DA8
                dc.l    Stage26ZLeoEndingTileArt0000    ; field_2
                dc.w    0                               ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage26ZLeoEndingMappingData6000  ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage26ZLeoEndingMappingData4020  ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage21To26SharedMappingData7000  ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Stage state machine dispatcher
