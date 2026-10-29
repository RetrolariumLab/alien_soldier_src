Stage_LoadAssetsForCurrentTableIndex:                   ; CODE XREF: StageReady_Initialize+16   p  ; was: sub_11722
                                        ; RetryPrompt_Initialize+10   p
                bsr.w   Stage_LoadSharedMappings
                move.w  (StageTableIndex).w,d0
                movea.w Stage_AssetLoaderOffsets(pc,d0.w),a0
                adda.l  #Stage_LoadSharedMappings,a0
                jmp     (a0)
; End of function Stage_LoadAssetsForCurrentTableIndex
; ---------------------------------------------------------------------------
Stage_AssetLoaderOffsets:   dc.w    Stage_LoadStage1To4Assets-Stage_LoadSharedMappings  ; was: off_11736
                                        ; DATA XREF: Stage_LoadAssetsForCurrentTableIndex+8   r
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
Stage_LoadSharedMappings:                               ; CODE XREF: Stage_LoadAssetsForCurrentTableIndex   p  ; was: sub_1176A
                                        ; DATA XREF: Stage_LoadAssetsForCurrentTableIndex+C   o
                lea     Stage_SharedMappingsLoadList(pc),a0
                nop
                jmp     (LoadObjData).l
; End of function Stage_LoadSharedMappings
; ---------------------------------------------------------------------------
Stage_SharedMappingsLoadList:   dc.w    7               ; field_0  ; was: stru_11776
                                        ; DATA XREF: Stage_LoadSharedMappings   o
                dc.l    SharedGameplayTileArtD000       ; field_2
                dc.w    $D000                           ; field_6
                dc.w    $FFFF

; Loads the base Stage 1 (Xi-Tiger) asset list
Stage_LoadStage1To4Assets:                              ; CODE XREF: Stage_LoadStage4Assets+4   p  ; was: sub_11780
                                        ; DATA XREF: ROM:Stage_AssetLoaderOffsets   o
                clr.w   (StageProcessTableOffset).w
                lea     Stage1To4AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage1To4Assets
; ---------------------------------------------------------------------------
Stage1To4AssetLoadList: dc.w    7                       ; field_0  ; was: stru_11790
                                        ; DATA XREF: Stage_LoadStage1To4Assets+4   o
                dc.l    Stage1To4TileArt0               ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage1To4TileArt1               ; field_2
                dc.w    $2B80                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage1AndShellshogunSharedTileArt  ; field_2
                dc.w    $5AC0                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage1To4MappingData6000        ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage1To4MappingData4000        ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage1To4MappingData6800        ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage1To4MappingData2000        ; field_2
                dc.w    $2000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage1To4MappingData7800        ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads initial object set for Stage 4
Stage_LoadStage4Assets:                                 ; DATA XREF: ROM:0001173C   o  ; was: sub_117E2
                clr.w   (StageProcessTableOffset).w
                bsr.w   Stage_LoadStage1To4Assets
                lea     Stage4AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage4Assets
; ---------------------------------------------------------------------------
Stage4AssetLoadList:    dc.w    7                       ; field_0  ; was: stru_117F6
                                        ; DATA XREF: Stage_LoadStage4Assets+8   o
                dc.l    Stage3And4TileArt               ; field_2
                dc.w    $2B80                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage1AndShellshogunSharedTileArt  ; field_2
                dc.w    $5AC0                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3And4MappingData6800       ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3And4MappingData2000       ; field_2
                dc.w    $2000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF
Boss_ShellshogunAssetLoadList:  dc.w    7               ; field_0  ; was: stru_11820
                                        ; DATA XREF: Camera_ShellshogunBossInit+26   o
                dc.l    Stage3And4TileArt               ; field_2
                dc.w    $2B80                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage1AndShellshogunSharedTileArt  ; field_2
                dc.w    $5AC0                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3And4MappingData6800       ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage3And4MappingData2000       ; field_2
                dc.w    $2000                           ; field_6
                dc.w    $FFFF

; Loads object set for Stages 5 to 7
Stage_LoadStage5To7Assets:                              ; DATA XREF: ROM:0001173E   o  ; was: sub_11842
                                        ; ROM:00011740   o
                clr.w   (StageProcessTableOffset).w
                lea     Stage5To7AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage5To7Assets
; ---------------------------------------------------------------------------
Stage5To7AssetLoadList: dc.w    7                       ; field_0  ; was: stru_11852
                                        ; DATA XREF: Stage_LoadStage5To7Assets+4   o
                dc.l    Stage5To7TileArt0               ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage5To7TileArt1               ; field_2
                dc.w    $5BE0                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage5To7MappingData6000        ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage5To7MappingData4000        ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage5To7MappingData7800        ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads assets for Stage 8 (train/Flying-Neo)
Stage_LoadStage8Assets:                                 ; DATA XREF: ROM:00011744   o  ; was: sub_1188C
                clr.w   (StageProcessTableOffset).w
                lea     Stage8AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage8Assets
; ---------------------------------------------------------------------------
Stage8AssetLoadList:    dc.w    7                       ; field_0  ; was: stru_1189C
                                        ; DATA XREF: Stage_LoadStage8Assets+4   o
                dc.l    Stage8And9TileArt0              ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage8And9TileArt1              ; field_2
                dc.w    $3AC0                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage8And9TileArt2              ; field_2
                dc.w    $3D00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage8And9MappingData6000       ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage8And9MappingData4000       ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads object set for Stage 9
Stage_LoadStage9Assets:                                 ; DATA XREF: ROM:00011746   o  ; was: sub_118D6
                clr.w   (StageProcessTableOffset).w
                lea     Stage9AssetLoadList(pc),a0
                nop
                jmp     Stage_DispatchAssetListLoaderByGameMode(pc)  ; (pc)
; ---------------------------------------------------------------------------
                nop
; End of function Stage_LoadStage9Assets
; ---------------------------------------------------------------------------
Stage9AssetLoadList:    dc.w    7                       ; field_0  ; was: stru_118E6
                                        ; DATA XREF: Stage_LoadStage9Assets+4   o
                dc.l    Stage8And9TileArt0              ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage8And9TileArt1              ; field_2
                dc.w    $3AC0                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage8And9TileArt2              ; field_2
                dc.w    $3D00                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage8And9MappingData6000       ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage8And9MappingData4000       ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage9MappingData6800           ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage9MappingData2020           ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage8And9TileArt1              ; field_2
                dc.w    $9600                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads Stage 10 enemy configuration
Stage_LoadStage10To12Assets:                            ; DATA XREF: ROM:00011748   o  ; was: sub_11938
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
Stage10To12AssetLoadList:   dc.w    7                   ; field_0  ; was: stru_1195A
                                        ; DATA XREF: Stage_LoadStage10To12Assets+6   o
                dc.l    Stage10To13TileArt0000          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage10To13TileArt4000          ; field_2
                dc.w    $4000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage10To12TileArt0             ; field_2
                dc.w    $3720                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage10To12TileArt1             ; field_2
                dc.w    $1840                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10To12MappingData6000      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10To12MappingData4020      ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10To13MappingData6800      ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10To13MappingData2020      ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7400                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10TeleportSharedAssetData  ; field_2
                dc.w    $7800                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF
Stage10To12TileBlockAdjustmentDescriptor:   dc.b    $40, 0, $D1, $D2, $D3, $D5, $D6, $D7, $DC, $E4  ; was: byte_119BC
                                        ; DATA XREF: Stage_LoadStage10To12Assets+12   o
                dc.b    $FF, 0

; Loads the teleport-scene asset list and initializes its tile-loop parameters
Stage_LoadStage13Assets:                                ; CODE XREF: Stage12To13_UpdateTeleportFadeIn+64   p  ; was: sub_119C8
                                        ; DATA XREF: ROM:0001174E   o
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
TeleportAssetLoadList:  dc.w    7                       ; field_0  ; was: stru_119FA
                                        ; DATA XREF: Stage_LoadStage13Assets+6   o
                dc.l    Stage10To13TileArt0000          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage12And13TileArt0000         ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Stage10To13TileArt4000          ; field_2
                dc.w    $4000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage13MappingData6000          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage13MappingData4020          ; field_2
                dc.w    $4020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10To13MappingData6800      ; field_2
                dc.w    $6800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10To13MappingData2020      ; field_2
                dc.w    $2020                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedMappingData7000           ; field_2
                dc.w    $7400                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage10TeleportSharedAssetData  ; field_2
                dc.w    $7800                           ; field_6
                dc.w    6                               ; field_0
                dc.l    Stage13TileArt                  ; field_2
                dc.w    $9600                           ; field_6
                dc.w    7                               ; field_0
                dc.l    SharedSceneAndStageTileArt9000  ; field_2
                dc.w    $9000                           ; field_6
                dc.w    $FFFF

; Loads object data for stage 16/17 (Sylpheed)
