; Tilemap transfer descriptors are shared by direct transfers and queued rows/columns
Gfx_TitleAndZLeoVRAMTransferParameters: dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $14000  ; was: dword_11316
                                        ; Tilemap_QueuePrimaryPlaneColumn   o
Gfx_DefaultVRAMTransferParameters:  dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $4000  ; was: dword_11326
                                        ; EndingStarfield_FadeOutAndPreparePlanet+4A   o
Gfx_FrontendAlternateVRAMTransferParameters:    dc.l    $FFFF7000, $FFFF6800, $FFFF2000, $6000  ; was: dword_11336
                                        ; UI_InitOptionsScreen+56   o
Gfx_ScrollVRAMTransferParameters:   dc.l    $FFFF7000, $FFFF6000, $FFFF4000, $6000  ; was: dword_11346
                                        ; ShipSequence_InitializePatternReveal+8C   o
; Four-longword transfer tuple; no source selector establishes its intended use
; UNKNOWN DATA-002: unselected transfer tuple; see docs/unknowns.md
Gfx_UnidentifiedVRAMTransferParameters: dc.l    $FFFF7400, $FFFF6800, $FFFF4000, $14000

; Each asset-set record stores an entity type, an optional LoadObjData list,
; and an optional palette command. Boss_LoadAssetSet consumes those fields
Boss_JetsripperAssetSet:    dc.w    $E4                 ; field_0  ; was: stru_11366
                dc.l    Boss_JetsripperGraphicsLoadList  ; field_2
                dc.l    Boss_JetsripperPaletteCommand   ; field_6
Boss_JetsripperGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_11370
                dc.l    Boss_JetsripperTileArt          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_AntroidAssetSet:   dc.w    $30                     ; field_0  ; was: stru_1137A
                dc.l    Boss_AntroidGraphicsLoadList    ; field_2
                dc.l    Boss_AntroidPaletteCommand      ; field_6
Boss_AntroidGraphicsLoadList:   dc.w    7               ; field_0  ; was: stru_11384
                dc.l    Boss_AntroidTileArt             ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_ShellshogunAssetSet:   dc.w    $F4                 ; field_0  ; was: stru_1138E
                dc.l    Boss_ShellshogunGraphicsLoadList  ; field_2
                dc.l    Boss_ShellshogunPaletteCommand  ; field_6
Boss_ShellshogunGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_11398
                dc.l    Boss_ShellshogunTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_SniperHoneyviperAssetSet:  dc.w    $24             ; field_0  ; was: stru_113AA
                dc.l    0                               ; field_2
                dc.l    Boss_SniperHoneyviperPaletteCommand  ; field_6
Boss_MadamBarbarAssetSet:   dc.w    $118                ; field_0  ; was: stru_113B4
                dc.l    Boss_MadamBarbarGraphicsLoadList  ; field_2
                dc.l    Boss_MadamBarbarPaletteCommand  ; field_6
Boss_MadamBarbarGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_113BE
                dc.l    Boss_MadamBarbarTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_JokerAssetSet: dc.w    $15C                        ; field_0  ; was: stru_113D0
                dc.l    Boss_JokerGraphicsLoadList      ; field_2
                dc.l    Boss_JokerPaletteCommand        ; field_6
Boss_JokerGraphicsLoadList: dc.w    7                   ; field_0  ; was: stru_113DA
                dc.l    Boss_JokerTileArt               ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_TerobusterAssetSet:    dc.w    $B4                 ; field_0  ; was: stru_113EC
                dc.l    Boss_TerobusterGraphicsLoadList  ; field_2
                dc.l    Boss_TerobusterPaletteCommand   ; field_6
Boss_TerobusterGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_113F6
                dc.l    Boss_TerobusterTileArt          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_FlyingNeoAssetSet: dc.w    $154                    ; field_0  ; was: stru_11408
                dc.l    Boss_FlyingNeoGraphicsLoadList  ; field_2
                dc.l    0                               ; field_6
Boss_FlyingNeoGraphicsLoadList: dc.w    7               ; field_0  ; was: stru_11412
                dc.l    Boss_FlyingNeoTileArt           ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_XiTigerAssetSet:   dc.w    $114                    ; field_0  ; was: stru_11424
                dc.l    Boss_XiTigerGraphicsLoadList    ; field_2
                dc.l    Boss_XiTigerPaletteCommand      ; field_6
Boss_XiTigerGraphicsLoadList:   dc.w    7               ; field_0  ; was: stru_1142E
                dc.l    Boss_XiTigerTileArt             ; field_2
                dc.w    $5000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_DeepStriderAssetSet:   dc.w    $19C                ; field_0  ; was: stru_11440
                dc.l    Boss_DeepStriderGraphicsLoadList  ; field_2
                dc.l    Boss_DeepStriderPaletteCommand  ; field_6
Boss_DeepStriderGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_1144A
                dc.l    Boss_DeepStriderTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_GustheadAssetSet:  dc.w    $1B0                    ; field_0  ; was: stru_11454
                dc.l    Boss_GustheadGraphicsLoadList   ; field_2
                dc.l    Boss_GustheadPaletteCommand     ; field_6
Boss_GustheadGraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_1145E
                dc.l    Boss_GustheadTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_SharpsteelAssetSet:    dc.w    $21C                ; field_0  ; was: stru_11468
                dc.l    Boss_SharpsteelGraphicsLoadList  ; field_2
                dc.l    Boss_SharpsteelPaletteCommand   ; field_6
Boss_SharpsteelGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_11472
                dc.l    Boss_SharpsteelTileArt          ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_BugmaxAssetSet:    dc.w    $300                    ; field_0  ; was: stru_1147C
                dc.l    Boss_BugmaxGraphicsLoadList     ; field_2
                dc.l    Boss_BugmaxPaletteCommand       ; field_6
Boss_BugmaxGraphicsLoadList:    dc.w    7               ; field_0  ; was: stru_11486
                dc.l    Boss_BugmaxTileArt              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_VictorAssetSet:    dc.w    $3C0                    ; field_0  ; was: stru_11498
                dc.l    Boss_VictorGraphicsLoadList     ; field_2
                dc.l    Boss_VictorPaletteCommand       ; field_6
Boss_VictorGraphicsLoadList:    dc.w    7               ; field_0  ; was: stru_114A2
                dc.l    Boss_VictorTileArt              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_SunsetStingAssetSet:   dc.w    $1EC                ; field_0  ; was: stru_114B4
                dc.l    Boss_SunsetStingGraphicsLoadList  ; field_2
                dc.l    Boss_SunsetStingPaletteCommand  ; field_6
Boss_SunsetStingGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_114BE
                dc.l    Boss_SunsetStingTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_BackStringerAssetSet:  dc.w    $314                ; field_0  ; was: stru_114D0
                dc.l    Boss_BackStringerGraphicsLoadList  ; field_2
                dc.l    Boss_BackStringerPaletteCommand  ; field_6
Boss_BackStringerGraphicsLoadList:  dc.w    7           ; field_0  ; was: stru_114DA
                dc.l    Boss_BackStringerTileArt        ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_JampanAssetSet:    dc.w    $218                    ; field_0  ; was: stru_114E4
                                        ; UnreferencedStage20Variant1_InitializeJampanPhase   o
                dc.l    Boss_JampanGraphicsLoadList     ; field_2
                dc.l    Boss_JampanPaletteCommand       ; field_6
Boss_JampanGraphicsLoadList:    dc.w    7               ; field_0  ; was: stru_114EE
                dc.l    Boss_JampanTileArt              ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_Epsilon1AssetSet:  dc.w    $264                    ; field_0  ; was: stru_11500
                dc.l    Boss_Epsilon1GraphicsLoadList   ; field_2
                dc.l    Boss_Epsilon1PaletteCommands    ; field_6
Boss_Epsilon1GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_1150A
                dc.l    Boss_Epsilon1TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_DestroyerMk2AssetSet:  dc.w    $240                ; field_0  ; was: stru_1151C
                dc.l    Boss_DestroyerMk2GraphicsLoadList  ; field_2
                dc.l    Boss_DestroyerMk2PaletteCommand  ; field_6
Boss_DestroyerMk2GraphicsLoadList:  dc.w    7           ; field_0  ; was: stru_11526
                dc.l    Boss_DestroyerMk2TileArt        ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Love Penguin's asset set (entity type $1C0). No static pointer names it; put
; in place of Bugmax's set, it draws the boss (docs/love_penguin.md)
Boss_LovePenguinAssetSet:
                dc.w    $1C0                            ; entity type
                dc.l    Boss_LovePenguinGraphicsLoadList  ; Graphics structure pointer
                dc.l    Boss_LovePenguinPaletteCommand  ; Palette data pointer
Boss_LovePenguinGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_11542
                dc.l    Boss_LovePenguinTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedBossMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_ShieldViperAssetSet:   dc.w    $34C                ; field_0  ; was: stru_11554
                dc.l    Boss_ShieldViperGraphicsLoadList  ; field_2
                dc.l    Boss_ShieldViperPaletteCommand  ; field_6
Boss_ShieldViperGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_1155E
                dc.l    Boss_ShieldViperTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
Boss_DestroyerProtoAssetSet:    dc.w    $3B8            ; field_0  ; was: stru_11568
                dc.l    Boss_DestroyerProtoGraphicsLoadList  ; field_2
                dc.l    Boss_DestroyerProtoPaletteCommand  ; field_6
Boss_DestroyerProtoGraphicsLoadList:    dc.w    7       ; field_0  ; was: stru_11572
                dc.l    Boss_DestroyerProtoTileArt      ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_WolfGaropaAssetSet:    dc.w    $3E8                ; field_0  ; was: stru_11584
                dc.l    Boss_WolfGaropaGraphicsLoadList  ; field_2
                dc.l    Boss_WolfGaropaPaletteCommand   ; field_6
Boss_WolfGaropaGraphicsLoadList:    dc.w    7           ; field_0  ; was: stru_1158E
                dc.l    Boss_WolfGaropaTileArt0         ; field_2
                dc.w    $3C00                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Boss_WolfGaropaTileArt1         ; field_2
                dc.w    $5100                           ; field_6
                dc.w    6                               ; field_0
                dc.l    WolfGaropaMappingData2020       ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Lambda Bunny's asset set (entity type $3EC), referenced by Stage 18's dormant
; late-phase table; its art is the head and ears the pose viewer draws
Boss_LambdaBunnyAssetSet:   dc.w    $3EC                ; entity type  ; was: stru_115A8
                dc.l    Boss_LambdaBunnyGraphicsLoadList  ; Graphics structure pointer
                dc.l    Boss_LambdaBunnyPaletteCommand  ; Palette data pointer
Boss_LambdaBunnyGraphicsLoadList:   dc.w    7           ; field_0  ; was: stru_115B2
                dc.l    Boss_LambdaBunnyTileArt         ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this identity-unknown record
EntityType3F0AssetSet:  dc.w    $3F0                    ; entity type  ; was: stru_115C4
                dc.l    EntityType3F0GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3F0PaletteCommand     ; Palette data pointer
EntityType3F0GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_115CE
                dc.l    EntityType3F0TileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this identity-unknown record
EntityType3F4AssetSet:  dc.w    $3F4                    ; entity type  ; was: stru_115E0
                dc.l    EntityType3F4GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3F4PaletteCommands    ; Palette data pointer
EntityType3F4GraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_115EA
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
                dc.l    EntityType3FCTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
Boss_ZLeoAssetSet:  dc.w    $3F8                        ; field_0  ; was: stru_11618
                dc.l    Boss_ZLeoGraphicsLoadList       ; field_2
                dc.l    Boss_ZLeoPaletteCommands        ; field_6
Boss_ZLeoGraphicsLoadList:  dc.w    7                   ; field_0  ; was: stru_11622
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
                dc.l    Boss_MissirayGraphicsLoadList   ; field_2
                dc.l    Boss_MissirayPaletteCommand     ; field_6
Boss_MissirayGraphicsLoadList:  dc.w    7               ; field_0  ; was: stru_11646
                dc.l    Boss_MissirayTileArt            ; field_2
                dc.w    $6000                           ; field_6
                dc.w    6                               ; field_0
                dc.l    SharedLateBossMappingData2020   ; field_2
                dc.w    $2020                           ; field_6
                dc.w    $FFFF
SevenForceValkirieAssetSet: dc.w    $42C                ; field_0  ; was: stru_11658
                dc.l    SevenForceValkirieGraphicsLoadList  ; field_2
                dc.l    SevenForceValkiriePaletteCommand  ; field_6
SevenForceValkirieGraphicsLoadList: dc.w    7           ; field_0  ; was: stru_11662
                                        ; SevenForceSireneTimedAssetSetA   o
                                        ; ROM:SevenForceSireneTimedAssetSetA   o
                dc.l    SevenForceValkirieTileArt       ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
SevenForceMedusaAssetSet:   dc.w    $430                ; field_0  ; was: stru_1166C
                dc.l    0                               ; field_2
                dc.l    SevenForceMedusaPaletteCommand  ; field_6
SevenForceSireneAssetSet:   dc.w    $434                ; field_0  ; was: stru_11676
                dc.l    0                               ; field_2
                dc.l    SevenForceSirenePaletteCommand  ; field_6
SevenForceArtemisAssetSet:  dc.w    $438                ; field_0  ; was: stru_11680
                dc.l    0                               ; field_2
                dc.l    SevenForceArtemisPaletteCommand  ; field_6
SevenForceSireneTimedAssetSetB: dc.w    $43C            ; field_0  ; was: stru_1168A
                dc.l    0                               ; field_2
                dc.l    SevenForceSireneTimedPaletteCommandB  ; field_6
SevenForceSireneTimedAssetSetA: dc.w    $440            ; field_0  ; was: stru_11694
                dc.l    SevenForceValkirieGraphicsLoadList  ; field_2
                dc.l    SevenForceSireneTimedPaletteCommandA  ; field_6
SevenForceSylpheedAssetSet: dc.w    $444                ; field_0  ; was: stru_1169E
                dc.l    0                               ; field_2
                dc.l    SevenForceSylpheedPaletteCommand  ; field_6

; Clears an object record, installs its entity type, loads graphics, then loads
; the optional palette command and resets the default color-fade state
Boss_LoadAssetSet:                                      ; was: sub_116A8
                                        ; Camera_TransitionToBossArena+2E   j
                movea.w #(Entity_ObjectPool-M68K_RAM),a0
Boss_LoadAssetSetAtObject:                              ; was: loc_116AC
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
Boss_LoadAssetSet_LoadPalette:                          ; was: loc_11708
                move.l  (BossAssetPointerScratch).w,(BossAssetPointerScratch).w
                beq.s   Boss_LoadAssetSet_Return
                movea.l (BossAssetPointerScratch).w,a0
                jsr     (Gfx_LoadPalettePreservingSharedColor).l
                jmp     (Gfx_ResetDefaultColorFadeState).l
; ---------------------------------------------------------------------------
Boss_LoadAssetSet_Return:                               ; was: locret_11720
                rts
; End of function Boss_LoadAssetSet
; Dispatches to stage-specific object data loader
