Stage_LoadAssetsForCurrentTableIndex:                   ; was: sub_11722
                                        ; RetryPrompt_Initialize+10   p
                bsr.w   Stage_LoadSharedMappings
                move.w  (StageTableIndex).w,d0
                movea.w Stage_AssetLoaderOffsets(pc,d0.w),a0
                adda.l  #Stage_LoadSharedMappings,a0
                jmp     (a0)
; End of function Stage_LoadAssetsForCurrentTableIndex
; ---------------------------------------------------------------------------
Stage_AssetLoaderOffsets:   dc.w    Stage_LoadStage1To4Assets-Stage_LoadSharedMappings  ; was: off_11736
                dc.w    Stage_LoadStage1To4Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage1To4Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage4Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage5To7Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage5To7Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage5To7Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage8Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage9Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage10To12Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage10To12Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage10To12Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage13Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage14To16Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage14To16Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage14To16Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage17Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage18And19Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage18And19Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage20Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage21And22Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage21And22Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage23Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage24Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage25Assets-Stage_LoadSharedMappings
                dc.w    Stage_LoadStage26Assets-Stage_LoadSharedMappings

; Loads the shared type-7 mappings record used by every table-index entry
Stage_LoadSharedMappings:                               ; was: sub_1176A
                lea     Stage_SharedMappingsLoadList(pc),a0
                nop
                jmp     (LoadObjData).l
; End of function Stage_LoadSharedMappings
; ---------------------------------------------------------------------------
Stage_SharedMappingsLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_11776
                dc.l    SharedGameplayTileArtD000       ; source
                dc.w    $D000                           ; destination: VRAM $D000
                dc.w    $FFFF

; Loads the base Stage 1 (Xi-Tiger) asset list
Stage_LoadStage1To4Assets:                              ; was: sub_11780
                clr.w   (StageProcessTableOffset).w
                lea     Stage1To4AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage1To4Assets
; ---------------------------------------------------------------------------
Stage1To4AssetLoadList: dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11790
                dc.l    Stage1To4TileArt0               ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage1To4TileArt1               ; source
                dc.w    $2B80                           ; destination: VRAM $2B80
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage1AndShellshogunSharedTileArt  ; source
                dc.w    $5AC0                           ; destination: VRAM $5AC0
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage1To4MappingData6000        ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage1To4MappingData4000        ; source
                dc.w    $4000                           ; destination: RAM $FF4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage1To4MappingData6800        ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage1To4MappingData2000        ; source
                dc.w    $2000                           ; destination: RAM $FF2000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage1To4MappingData7800        ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF

; Loads initial object set for Stage 4
Stage_LoadStage4Assets:                                 ; was: sub_117E2
                clr.w   (StageProcessTableOffset).w
                bsr.w   Stage_LoadStage1To4Assets
                lea     Stage4AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage4Assets
; ---------------------------------------------------------------------------
Stage4AssetLoadList:    dc.w    7                       ; command: LZSS to VRAM  ; was: stru_117F6
                dc.l    Stage3And4TileArt               ; source
                dc.w    $2B80                           ; destination: VRAM $2B80
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage1AndShellshogunSharedTileArt  ; source
                dc.w    $5AC0                           ; destination: VRAM $5AC0
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage3And4MappingData6800       ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage3And4MappingData2000       ; source
                dc.w    $2000                           ; destination: RAM $FF2000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF
Boss_ShellshogunAssetLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_11820
                dc.l    Stage3And4TileArt               ; source
                dc.w    $2B80                           ; destination: VRAM $2B80
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage1AndShellshogunSharedTileArt  ; source
                dc.w    $5AC0                           ; destination: VRAM $5AC0
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage3And4MappingData6800       ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage3And4MappingData2000       ; source
                dc.w    $2000                           ; destination: RAM $FF2000
                dc.w    $FFFF

; Loads object set for Stages 5 to 7
Stage_LoadStage5To7Assets:                              ; was: sub_11842
                                        ; ROM:00011740   o
                clr.w   (StageProcessTableOffset).w
                lea     Stage5To7AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage5To7Assets
; ---------------------------------------------------------------------------
Stage5To7AssetLoadList: dc.w    7                       ; command: LZSS to VRAM  ; was: stru_11852
                dc.l    Stage5To7TileArt0               ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage5To7TileArt1               ; source
                dc.w    $5BE0                           ; destination: VRAM $5BE0
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage5To7MappingData6000        ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage5To7MappingData4000        ; source
                dc.w    $4000                           ; destination: RAM $FF4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage5To7MappingData7800        ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF

; Loads assets for Stage 8 (train/Flying-Neo)
Stage_LoadStage8Assets:                                 ; was: sub_1188C
                clr.w   (StageProcessTableOffset).w
                lea     Stage8AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage8Assets
; ---------------------------------------------------------------------------
Stage8AssetLoadList:    dc.w    7                       ; command: LZSS to VRAM  ; was: stru_1189C
                dc.l    Stage8And9TileArt0              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage8And9TileArt1              ; source
                dc.w    $3AC0                           ; destination: VRAM $3AC0
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage8And9TileArt2              ; source
                dc.w    $3D00                           ; destination: VRAM $3D00
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage8And9MappingData6000       ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage8And9MappingData4000       ; source
                dc.w    $4000                           ; destination: RAM $FF4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF

; Loads object set for Stage 9
Stage_LoadStage9Assets:                                 ; was: sub_118D6
                clr.w   (StageProcessTableOffset).w
                lea     Stage9AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage9Assets
; ---------------------------------------------------------------------------
Stage9AssetLoadList:    dc.w    7                       ; command: LZSS to VRAM  ; was: stru_118E6
                dc.l    Stage8And9TileArt0              ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage8And9TileArt1              ; source
                dc.w    $3AC0                           ; destination: VRAM $3AC0
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage8And9TileArt2              ; source
                dc.w    $3D00                           ; destination: VRAM $3D00
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage8And9MappingData6000       ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage8And9MappingData4000       ; source
                dc.w    $4000                           ; destination: RAM $FF4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage9MappingData6800           ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage9MappingData2020           ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage8And9TileArt1              ; source
                dc.w    $9600                           ; destination: RAM $FF9600
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF

; Loads Stage 10 enemy configuration
Stage_LoadStage10To12Assets:                            ; was: sub_11938
                                        ; ROM:0001174A   o
                move.w  #4,(StageProcessTableOffset).w
                lea     Stage10To12AssetLoadList(pc),a0
                nop
                jsr     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
                nop
                lea     Stage10To12TileBlockAdjustmentDescriptor(pc),a0
                nop
                move.w  #$A000,d0
                jmp     Gfx_AdjustSelectedTileBlocks
; End of function Stage_LoadStage10To12Assets
; ---------------------------------------------------------------------------
Stage10To12AssetLoadList:   dc.w    7                   ; command: LZSS to VRAM  ; was: stru_1195A
                dc.l    Stage10To13TileArt0000          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage10To13TileArt4000          ; source
                dc.w    $4000                           ; destination: VRAM $4000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage10To12TileArt0             ; source
                dc.w    $3720                           ; destination: VRAM $3720
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage10To12TileArt1             ; source
                dc.w    $1840                           ; destination: VRAM $1840
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10To12MappingData6000      ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10To12MappingData4020      ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10To13MappingData6800      ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10To13MappingData2020      ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7400                           ; destination: RAM $FF7400
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10TeleportSharedAssetData  ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF
Stage10To12TileBlockAdjustmentDescriptor:   dc.b    $40, 0, $D1, $D2, $D3, $D5, $D6, $D7, $DC, $E4  ; was: byte_119BC
                dc.b    $FF, 0

; Loads the teleport-scene asset list and initializes its tile-loop parameters
Stage_LoadStage13Assets:                                ; was: sub_119C8
                move.w  #4,(StageProcessTableOffset).w
                lea     TeleportAssetLoadList(pc),a0
                nop
                jsr     (LoadObjData).l
                movea.w #(SharedScratchLong0-M68K_RAM),a0
                movea.w #(TileInterpSourceB-M68K_RAM),a1
                move.w  #$6000,(TileInterpVRAM).w
                move.w  #$F,(TileInterpStepsLeft).w
                move.w  #1,(TileInterpSpanStep).w
                jmp     Gfx_LoadTilesLoop
; End of function Stage_LoadStage13Assets
; ---------------------------------------------------------------------------
TeleportAssetLoadList:  dc.w    7                       ; command: LZSS to VRAM  ; was: stru_119FA
                dc.l    Stage10To13TileArt0000          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage12And13TileArt0000         ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Stage10To13TileArt4000          ; source
                dc.w    $4000                           ; destination: VRAM $4000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage13MappingData6000          ; source
                dc.w    $6000                           ; destination: RAM $FF6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage13MappingData4020          ; source
                dc.w    $4020                           ; destination: RAM $FF4020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7000                           ; destination: RAM $FF7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10To13MappingData6800      ; source
                dc.w    $6800                           ; destination: RAM $FF6800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10To13MappingData2020      ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedMappingData7000           ; source
                dc.w    $7400                           ; destination: RAM $FF7400
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage10TeleportSharedAssetData  ; source
                dc.w    $7800                           ; destination: RAM $FF7800
                dc.w    6                               ; command: LZSS to RAM
                dc.l    Stage13TileArt                  ; source
                dc.w    $9600                           ; destination: RAM $FF9600
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    SharedSceneAndStageTileArt9000  ; source
                dc.w    $9000                           ; destination: VRAM $9000
                dc.w    $FFFF

; Loads object data for stage 16/17 (Sylpheed)
