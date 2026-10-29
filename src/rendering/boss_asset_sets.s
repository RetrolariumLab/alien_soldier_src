; Tilemap transfer descriptors are shared by direct transfers and queued rows/columns
Gfx_TitleAndZLeoVRAMTransferParameters: dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $14000  ; was: dword_11316
                                        ; DATA XREF: TitleScreen_Initialize+7E   o
                                        ; Tilemap_QueuePrimaryPlaneColumn   o
Gfx_DefaultVRAMTransferParameters:  dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $4000  ; was: dword_11326
                                        ; DATA XREF: EndingSequence_Initialize+4A   o
                                        ; EndingStarfield_FadeOutAndPreparePlanet+4A   o
Gfx_FrontendAlternateVRAMTransferParameters:    dc.l    $FFFF7000, $FFFF6800, $FFFF2000, $6000  ; was: dword_11336
                                        ; DATA XREF: TitleScreen_Initialize+96   o
                                        ; UI_InitOptionsScreen+56   o
Gfx_ScrollVRAMTransferParameters:   dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $6000  ; was: dword_11346
                                        ; DATA XREF: StoryScreen_FadeInAndStartScroll+1E   o
                                        ; ShipSequence_InitializePatternReveal+8C   o
; Four-longword transfer tuple; no source selector establishes its intended use
; UNKNOWN DATA-002: unselected transfer tuple; see docs/unknowns.md
Gfx_UnidentifiedVRAMTransferParameters: dc.l    $FFFF7400, $FFFF6800, $FFFF4000, $14000

; Each asset-set record stores an entity type, an optional LoadObjData list,
; and an optional palette command. Boss_LoadAssetSet consumes those fields
Boss_JetsripperAssetSet:    dc.w    $E4                 ; field_0  ; was: stru_11366
                                        ; DATA XREF: Stage1_InitializeJetsripperEncounter   o
                dc.l    Boss_JetsripperGraphicsLoadList  ; field_2
                dc.l    Boss_JetsripperPaletteCommand   ; field_6
Boss_JetsripperGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_11370
                                        ; DATA XREF: ROM:Boss_JetsripperAssetSet   o
                dc.l    Boss_JetsripperTileArt          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_AntroidAssetSet:   dc.w    $30                     ; field_0  ; was: stru_1137A
                                        ; DATA XREF: Stage2_InitializeAntroidEncounter   o
                dc.l    Boss_AntroidGraphicsLoadList    ; field_2
                dc.l    Boss_AntroidPaletteCommand      ; field_6
Boss_AntroidGraphicsLoadList:   dc.w    7               ; field_0  ; was: stru_11384
                                        ; DATA XREF: ROM:Boss_AntroidAssetSet   o
                dc.l    Boss_AntroidTileArt             ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_ShellshogunAssetSet:   dc.w    $F4                 ; field_0  ; was: stru_1138E
                                        ; DATA XREF: Stage3_InitializeShellshogunEncounter   o
                dc.l    Boss_ShellshogunGraphicsLoadList  ; field_2
                dc.l    Boss_ShellshogunPaletteCommand  ; field_6
Boss_ShellshogunGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_11398
                                        ; DATA XREF: ROM:Boss_ShellshogunAssetSet   o
                dc.l    Boss_ShellshogunTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_SniperHoneyviperAssetSet:  dc.w    $24             ; field_0  ; was: stru_113AA
                                        ; DATA XREF: Stage4_InitializeSniperHoneyviperEncounter   o
                dc.l    0                               ; field_2
                dc.l    Boss_SniperHoneyviperPaletteCommand  ; field_6
Boss_MadamBarbarAssetSet:   dc.w    $118                ; field_0  ; was: stru_113B4
                                        ; DATA XREF: Stage5_InitializeMadamBarbarEncounter   o
                dc.l    Boss_MadamBarbarGraphicsLoadList  ; field_2
                dc.l    Boss_MadamBarbarPaletteCommand  ; field_6
Boss_MadamBarbarGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_113BE
                                        ; DATA XREF: ROM:Boss_MadamBarbarAssetSet   o
                dc.l    Boss_MadamBarbarTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_JokerAssetSet: dc.w    $15C                        ; field_0  ; was: stru_113D0
                                        ; DATA XREF: Stage6_InitializeJokerEncounter   o
                dc.l    Boss_JokerGraphicsLoadList      ; field_2
                dc.l    Boss_JokerPaletteCommand        ; field_6
Boss_JokerGraphicsLoadList: dc.w    7                   ; field_0  ; was: stru_113DA
                                        ; DATA XREF: ROM:Boss_JokerAssetSet   o
                dc.l    Boss_JokerTileArt               ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_TerobusterAssetSet:    dc.w    $B4                 ; field_0  ; was: stru_113EC
                                        ; DATA XREF: Stage7_InitializeTerobusterEncounter   o
                dc.l    Boss_TerobusterGraphicsLoadList  ; field_2
                dc.l    Boss_TerobusterPaletteCommand   ; field_6
Boss_TerobusterGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_113F6
                                        ; DATA XREF: ROM:Boss_TerobusterAssetSet   o
                dc.l    Boss_TerobusterTileArt          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_FlyingNeoAssetSet: dc.w    $154                    ; field_0  ; was: stru_11408
                                        ; DATA XREF: Stage8_InitializeFlyingNeoEncounter   o
                dc.l    Boss_FlyingNeoGraphicsLoadList  ; field_2
                dc.l    0                               ; field_6
Boss_FlyingNeoGraphicsLoadList: dc.w    7               ; field_0  ; was: stru_11412
                                        ; DATA XREF: ROM:Boss_FlyingNeoAssetSet   o
                dc.l    Boss_FlyingNeoTileArt           ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_XiTigerAssetSet:   dc.w    $114                    ; field_0  ; was: stru_11424
                                        ; DATA XREF: Stage9_LoadXiTigerEncounterAssets   o
                dc.l    Boss_XiTigerGraphicsLoadList    ; field_2
                dc.l    Boss_XiTigerPaletteCommand      ; field_6
Boss_XiTigerGraphicsLoadList:   dc.w    7               ; field_0  ; was: stru_1142E
                                        ; DATA XREF: ROM:Boss_XiTigerAssetSet   o
                dc.l    Boss_XiTigerTileArt             ; field_2
                dc.w    $5000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_DeepStriderAssetSet:   dc.w    $19C                ; field_0  ; was: stru_11440
                                        ; DATA XREF: Stage10_InitializeDeepStriderEncounter   o
                dc.l    Boss_DeepStriderGraphicsLoadList  ; field_2
                dc.l    Boss_DeepStriderPaletteCommand  ; field_6
Boss_DeepStriderGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_1144A
                                        ; DATA XREF: ROM:Boss_DeepStriderAssetSet   o
                dc.l    Boss_DeepStriderTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_GustheadAssetSet:  dc.w    $1B0                    ; field_0  ; was: stru_11454
                                        ; DATA XREF: Stage11_InitializeGustheadEncounter   o
                dc.l    Boss_GustheadGraphicsLoadList   ; field_2
                dc.l    Boss_GustheadPaletteCommand     ; field_6
Boss_GustheadGraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_1145E
                                        ; DATA XREF: ROM:Boss_GustheadAssetSet   o
                dc.l    Boss_GustheadTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_SharpsteelAssetSet:    dc.w    $21C                ; field_0  ; was: stru_11468
                                        ; DATA XREF: Stage12_InitializeSharpsteelEncounter   o
                dc.l    Boss_SharpsteelGraphicsLoadList  ; field_2
                dc.l    Boss_SharpsteelPaletteCommand   ; field_6
Boss_SharpsteelGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_11472
                                        ; DATA XREF: ROM:Boss_SharpsteelAssetSet   o
                dc.l    Boss_SharpsteelTileArt          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_BugmaxAssetSet:    dc.w    $300                    ; field_0  ; was: stru_1147C
                                        ; DATA XREF: Stage13_InitializeBugmaxEncounter   o
                dc.l    Boss_BugmaxGraphicsLoadList     ; field_2
                dc.l    Boss_BugmaxPaletteCommand       ; field_6
Boss_BugmaxGraphicsLoadList:    dc.w    7               ; field_0  ; was: stru_11486
                                        ; DATA XREF: ROM:Boss_BugmaxAssetSet   o
                dc.l    Boss_BugmaxTileArt              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_VictorAssetSet:    dc.w    $3C0                    ; field_0  ; was: stru_11498
                                        ; DATA XREF: Stage14_InitializeVictorEncounter   o
                dc.l    Boss_VictorGraphicsLoadList     ; field_2
                dc.l    Boss_VictorPaletteCommand       ; field_6
Boss_VictorGraphicsLoadList:    dc.w    7               ; field_0  ; was: stru_114A2
                                        ; DATA XREF: ROM:Boss_VictorAssetSet   o
                dc.l    Boss_VictorTileArt              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_SunsetStingAssetSet:   dc.w    $1EC                ; field_0  ; was: stru_114B4
                                        ; DATA XREF: Stage15_InitializeSunsetStingEncounter   o
                dc.l    Boss_SunsetStingGraphicsLoadList  ; field_2
                dc.l    Boss_SunsetStingPaletteCommand  ; field_6
Boss_SunsetStingGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_114BE
                                        ; DATA XREF: ROM:Boss_SunsetStingAssetSet   o
                dc.l    Boss_SunsetStingTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_BackStringerAssetSet:  dc.w    $314                ; field_0  ; was: stru_114D0
                                        ; DATA XREF: Boss_ViblackTransitionTimerState   o
                dc.l    Boss_BackStringerGraphicsLoadList  ; field_2
                dc.l    Boss_BackStringerPaletteCommand  ; field_6
Boss_BackStringerGraphicsLoadList:  dc.w    7           ; field_0  ; was: stru_114DA
                                        ; DATA XREF: ROM:Boss_BackStringerAssetSet   o
                dc.l    Boss_BackStringerTileArt        ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_JampanAssetSet:    dc.w    $218                    ; field_0  ; was: stru_114E4
                                        ; DATA XREF: Stage19_InitializeJampanEncounter   o
                                        ; UnreferencedStage20Variant1_InitializeJampanPhase   o
                dc.l    Boss_JampanGraphicsLoadList     ; field_2
                dc.l    Boss_JampanPaletteCommand       ; field_6
Boss_JampanGraphicsLoadList:    dc.w    7               ; field_0  ; was: stru_114EE
                                        ; DATA XREF: ROM:Boss_JampanAssetSet   o
                dc.l    Boss_JampanTileArt              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_Epsilon1AssetSet:  dc.w    $264                    ; field_0  ; was: stru_11500
                                        ; DATA XREF: Stage17_InitializeEpsilon1Encounter   o
                dc.l    Boss_Epsilon1GraphicsLoadList   ; field_2
                dc.l    Boss_Epsilon1PaletteCommands    ; field_6
Boss_Epsilon1GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_1150A
                                        ; DATA XREF: ROM:Boss_Epsilon1AssetSet   o
                dc.l    Boss_Epsilon1TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_DestroyerMK2AssetSet:  dc.w    $240                ; field_0  ; was: stru_1151C
                                        ; DATA XREF: Stage18_InitializeDestroyerMk2Encounter   o
                dc.l    Boss_DestroyerMK2GraphicsLoadList  ; field_2
                dc.l    Boss_DestroyerMK2PaletteCommand  ; field_6
Boss_DestroyerMK2GraphicsLoadList:  dc.w    7           ; field_0  ; was: stru_11526
                                        ; DATA XREF: ROM:Boss_DestroyerMK2AssetSet   o
                dc.l    Boss_DestroyerMK2TileArt        ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; No static pointer names this asset-set start. Historical material associates
; the art with "Love Penguin", but the ROM record itself establishes only entity
; type $1C0, graphics, and palette fields; see docs/unknowns.md
EntityType1C0AssetSet:
                dc.w    $1C0                            ; entity type
                dc.l    EntityType1C0GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType1C0PaletteCommand     ; Palette data pointer
EntityType1C0GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_11542
                                        ; DATA XREF: ROM:EntityType1C0AssetSet   o
                dc.l    EntityType1C0TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_ShieldViperAssetSet:   dc.w    $34C                ; field_0  ; was: stru_11554
                                        ; DATA XREF: StageTransition_LoadShieldViperAssets   o
                dc.l    Boss_ShieldViperGraphicsLoadList  ; field_2
                dc.l    Boss_ShieldViperPaletteCommand  ; field_6
Boss_ShieldViperGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_1155E
                                        ; DATA XREF: ROM:Boss_ShieldViperAssetSet   o
                dc.l    Boss_ShieldViperTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_DestroyerProtoAssetSet:    dc.w    $3B8            ; field_0  ; was: stru_11568
                                        ; DATA XREF: StageTransition_LoadDestroyerProtoAssets   o
                dc.l    Boss_DestroyerProtoGraphicsLoadList  ; field_2
                dc.l    Boss_DestroyerProtoPaletteCommand  ; field_6
Boss_DestroyerProtoGraphicsLoadList:    dc.w    7       ; field_0  ; was: stru_11572
                                        ; DATA XREF: ROM:Boss_DestroyerProtoAssetSet   o
                dc.l    Boss_DestroyerProtoTileArt      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_WolfGaropaAssetSet:    dc.w    $3E8                ; field_0  ; was: stru_11584
                                        ; DATA XREF: StageTransition_LoadWolfGaropaAssets   o
                dc.l    Boss_WolfGaropaGraphicsLoadList  ; field_2
                dc.l    Boss_WolfGaropaPaletteCommand   ; field_6
Boss_WolfGaropaGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_1158E
                                        ; DATA XREF: ROM:Boss_WolfGaropaAssetSet   o
                dc.l    Boss_WolfGaropaTileArt0         ; field_2
                dc.w    $3C00                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Boss_WolfGaropaTileArt1         ; field_2
                dc.w    $5100                           ; field_6
                dc.w    6                               ; field_0
                dc.l    WolfGaropaMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this record. The ROM proves
; entity type $3EC and its assets, but not the imported "Lambda Bunny" identity
EntityType3ECAssetSet:  dc.w    $3EC                    ; entity type  ; was: stru_115A8
                                        ; DATA XREF: UnreferencedStage20Variant2_InitializeEntity3ECPhase   o
                dc.l    EntityType3ECGraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3ECPaletteCommand     ; Palette data pointer
EntityType3ECGraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_115B2
                                        ; DATA XREF: ROM:EntityType3ECAssetSet   o
                dc.l    EntityType3ECTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this identity-unknown record
EntityType3F0AssetSet:  dc.w    $3F0                    ; entity type  ; was: stru_115C4
                                        ; DATA XREF: UnreferencedStage20Variant3_InitializeEntity3F0Phase   o
                dc.l    EntityType3F0GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3F0PaletteCommand     ; Palette data pointer
EntityType3F0GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_115CE
                                        ; DATA XREF: ROM:EntityType3F0AssetSet   o
                dc.l    EntityType3F0TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this identity-unknown record
EntityType3F4AssetSet:  dc.w    $3F4                    ; entity type  ; was: stru_115E0
                                        ; DATA XREF: UnreferencedStage20Variant4_InitializeEntity3F4Phase   o
                dc.l    EntityType3F4GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3F4PaletteCommands    ; Palette data pointer
EntityType3F4GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_115EA
                                        ; DATA XREF: ROM:EntityType3F4AssetSet   o
                dc.l    EntityType3F4TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; No static pointer names this asset-set start. The ROM record establishes only
; entity type $3FC and its graphics/palette fields; the old "Dragon" attribution
; remains external and is not promoted to source truth
EntityType3FCAssetSet:
                dc.w    $3FC                            ; entity type
                dc.l    EntityType3FCGraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3FCPaletteCommands    ; Palette data pointer
EntityType3FCGraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_11606
                                        ; DATA XREF: ROM:EntityType3FCAssetSet   o
                dc.l    EntityType3FCTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_ZLeoAssetSet:  dc.w    $3F8                        ; field_0  ; was: stru_11618
                                        ; DATA XREF: StageTransition_LoadZLeoAssets   o
                dc.l    Boss_ZLeoGraphicsLoadList       ; field_2
                dc.l    Boss_ZLeoPaletteCommands        ; field_6
Boss_ZLeoGraphicsLoadList:  dc.w    7                   ; field_0  ; was: stru_11622
                                        ; DATA XREF: ROM:Boss_ZLeoAssetSet   o
                dc.l    Boss_ZLeoTileArt0               ; field_2
                dc.w    $5000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Boss_ZLeoTileArt1               ; field_2
                dc.w    $7000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    BossZLeoMappingData2020         ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_MissirayAssetSet:  dc.w    $3D0                    ; field_0  ; was: stru_1163C
                                        ; DATA XREF: StageTransition_LoadMissirayAssets   o
                dc.l    Boss_MissirayGraphicsLoadList   ; field_2
                dc.l    Boss_MissirayPaletteCommand     ; field_6
Boss_MissirayGraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_11646
                                        ; DATA XREF: ROM:Boss_MissirayAssetSet   o
                dc.l    Boss_MissirayTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
SevenForcesValkirieAssetSet:    dc.w    $42C            ; field_0  ; was: stru_11658
                                        ; DATA XREF: Entity_SevenForcesValkirieFadeInStateC   o
                dc.l    SevenForcesValkirieGraphicsLoadList  ; field_2
                dc.l    SevenForcesValkiriePaletteCommand  ; field_6
SevenForcesValkirieGraphicsLoadList:    dc.w    7       ; field_0  ; was: stru_11662
                                        ; DATA XREF: ROM:SevenForcesValkirieAssetSet   o
                                        ; SevenForcesSireneTimedAssetSetA   o
                                        ; ROM:SevenForcesSireneTimedAssetSetA   o
                dc.l    SevenForcesValkirieTileArt      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
SevenForcesMedusaAssetSet:  dc.w    $430                ; field_0  ; was: stru_1166C
                                        ; DATA XREF: Entity_SevenForcesUpdateMedusaEntranceState12   o
                dc.l    0                               ; field_2
                dc.l    SevenForcesMedusaPaletteCommand  ; field_6
SevenForcesSireneAssetSet:  dc.w    $434                ; field_0  ; was: stru_11676
                                        ; DATA XREF: Entity_SevenForcesSireneHoldState2E   o
                dc.l    0                               ; field_2
                dc.l    SevenForcesSirenePaletteCommand  ; field_6
SevenForcesArtemisAssetSet: dc.w    $438                ; field_0  ; was: stru_11680
                                        ; DATA XREF: Entity_SevenForcesUpdateArtemisEntranceState24   o
                dc.l    0                               ; field_2
                dc.l    SevenForcesArtemisPaletteCommand  ; field_6
SevenForcesSireneTimedAssetSetB:    dc.w    $43C        ; field_0  ; was: stru_1168A
                                        ; DATA XREF: Entity_SevenForcesSirenePaletteEventState34+1C   o
                dc.l    0                               ; field_2
                dc.l    SevenForcesSireneTimedPaletteCommandB  ; field_6
SevenForcesSireneTimedAssetSetA:    dc.w    $440        ; field_0  ; was: stru_11694
                                        ; DATA XREF: Entity_SevenForcesSirenePaletteEventState32+1C   o
                dc.l    SevenForcesValkirieGraphicsLoadList  ; field_2
                dc.l    SevenForcesSireneTimedPaletteCommandA  ; field_6
SevenForcesSylpheedAssetSet:    dc.w    $444            ; field_0  ; was: stru_1169E
                                        ; DATA XREF: Entity_SevenForcesUpdateSylpheedEntranceState1A   o
                dc.l    0                               ; field_2
                dc.l    SevenForcesSylpheedPaletteCommand  ; field_6

; Clears an object record, installs its entity type, loads graphics, then loads
; the optional palette command and resets the default color-fade state
Boss_LoadAssetSet:                                      ; CODE XREF: Stage_InitBossIntro+2E   j  ; was: sub_116A8
                                        ; Camera_TransitionToBossArena+2E   j
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
Boss_LoadAssetSetAtObject:                              ; CODE XREF: Boss_ViblackTransitionTimerState+1A   p  ; was: loc_116AC
                moveq   #0,d0
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.l  d0,(a0)+
                move.w  (a1)+,-$60(a0)
                movea.l (a1)+,a0
                move.l  (a1)+,(BossAssetPointerScratch).w
                move.b  #6,(BossColorEffectFlags).w
                bset    #7,(StageObjectSpawnCursor).w
                clr.w   (EnemySpawnDirectorState).w
                bset    #0,(StageTimerPauseFlag).w
                move.l  a0,d0
                beq.s   Boss_LoadAssetSet_LoadPalette
                jsr     (Data_ProcessPointer).l
Boss_LoadAssetSet_LoadPalette:                          ; CODE XREF: Boss_LoadAssetSet+58   j  ; was: loc_11708
                move.l  (BossAssetPointerScratch).w,(BossAssetPointerScratch).w
                beq.s   Boss_LoadAssetSet_Return
                movea.l (BossAssetPointerScratch).w,a0
                jsr     (Gfx_LoadPalettePreservingSharedColor).l
                jmp     (Gfx_ResetDefaultColorFadeState).l
; ---------------------------------------------------------------------------
Boss_LoadAssetSet_Return:                               ; CODE XREF: Boss_LoadAssetSet+66   j  ; was: locret_11720
                rts
; End of function Boss_LoadAssetSet
; Dispatches to stage-specific object data loader
