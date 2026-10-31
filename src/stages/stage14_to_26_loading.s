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
Stage14To16AssetLoadList:   dc.w    7                   ; command: LZSS to VRAM  ; was: stru_11A6E
                dc.l    Stage14To16TileArt0000          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage14To16TileArt5F00          ; source
                dc.w    $5F00                           ; destination: VRAM $5F00
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage14To16MappingData6000      ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage14To16MappingData4020      ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage14To16MappingData7800      ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage17AssetLoadList:   dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11AC2
                dc.l    Stage17TileArt0000              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage17TileArt6000              ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage17MappingData6000          ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage17MappingData4000          ; source
                dc.w    $4000                           ; destination: RAM $FF4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage18And19AssetLoadList:  dc.w    7                   ; command: LZSS to VRAM  ; was: stru_11B06
                dc.l    Stage18And19TileArt0000         ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage18And19TileArt2A00         ; source
                dc.w    $2A00                           ; destination: VRAM $2A00
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage18And19MappingData6000     ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage18And19MappingData6400     ; source
                dc.w    $6400                           ; destination: RAM $FF6400
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage18And19MappingData4020     ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage18And19MappingData6800     ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage18And19MappingData2020     ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedStage18AndStage20MappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage18And19MappingData7800     ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage18And19TileArt8E00         ; source
                dc.w    $8E00                           ; destination: VRAM $8E00
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
UnreferencedStage17AlternateAssetLoadList:  dc.w    7   ; command: LZSS to VRAM  ; was: stru_11B72
                dc.l    UnreferencedStage17AlternateTileArt0000  ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    UnreferencedStage17AlternateMappingData6000  ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    UnreferencedStage17AlternateMappingData4020  ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedStage18AndStage20MappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage20AssetLoadList:   dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11BAE
                dc.l    Stage20TileArt0000              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage20TileArt3000              ; source
                dc.w    $3000                           ; destination: VRAM $3000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage20MappingData6800          ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage20MappingData2020          ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage20MappingData6000          ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage20MappingData6200          ; source
                dc.w    $6200                           ; destination: RAM $FF6200
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage20MappingData6400          ; source
                dc.w    $6400                           ; destination: RAM $FF6400
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage20MappingData4020          ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedStage18AndStage20MappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage21To23SharedAssetLoadList: dc.w    7               ; command: LZSS to VRAM  ; was: stru_11C36
                dc.l    Stage21To23TileArt              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To23MappingData6000      ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To23MappingData4020      ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To23MappingData5A00      ; source
                dc.w    $5A00                           ; destination: RAM $FF5A00
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To26SharedMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To23MappingData7800      ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage24AssetLoadList:   dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11C82
                dc.l    Stage24TileArt0000              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage24Tiles                    ; source
                dc.w    $4000                           ; destination: VRAM $4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage24MappingData6000          ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage24MappingData4020          ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To26SharedMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
UnreferencedLateStageVariantAAssetLoadList: dc.w    7   ; command: LZSS to VRAM  ; was: stru_11CC6
                dc.l    UnreferencedLateStageVariantATileArt0000  ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    UnreferencedLateStageVariantATileArt5800  ; source
                dc.w    $5800                           ; destination: VRAM $5800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    UnreferencedLateStageVariantAMappingData6000  ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    UnreferencedLateStageVariantAMappingData4020  ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To26SharedMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
UnreferencedLateStageVariantBAssetLoadList: dc.w    7   ; command: LZSS to VRAM  ; was: stru_11D0A
                dc.l    UnreferencedLateStageVariantBTileArt0000  ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    UnreferencedLateStageVariantBMappingData6000  ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    UnreferencedLateStageVariantBMappingData4020  ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To26SharedMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage25AssetLoadList:   dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11D46
                dc.l    Stage25TileArt0000              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage25TileArt1800              ; source
                dc.w    $1800                           ; destination: VRAM $1800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage25MappingData6000          ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage25MappingData4020          ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage25MappingData6800          ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage25ZLeoEntryMappingData2020  ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To26SharedMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage25MappingData7800          ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
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
Stage26AssetLoadList:   dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11DA8
                dc.l    Stage26ZLeoEndingTileArt0000    ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage26ZLeoEndingMappingData6000  ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage26ZLeoEndingMappingData4020  ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage21To26SharedMappingData7000  ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF

; Stage state machine dispatcher
