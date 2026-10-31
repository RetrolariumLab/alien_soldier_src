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
Boss_JetsripperAssetSet:    dc.w    $E4                 ; entity type  ; was: stru_11366
                dc.l    Boss_JetsripperGraphicsLoadList  ; graphics load list
                dc.l    Boss_JetsripperPaletteCommand   ; palette command
Boss_JetsripperGraphicsLoadList:    dc.w    7           ; command: LZSS to VRAM  ; was: stru_11370
                dc.l    Boss_JetsripperTileArt          ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_AntroidAssetSet:   dc.w    $30                     ; entity type  ; was: stru_1137A
                dc.l    Boss_AntroidGraphicsLoadList    ; graphics load list
                dc.l    Boss_AntroidPaletteCommand      ; palette command
Boss_AntroidGraphicsLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_11384
                dc.l    Boss_AntroidTileArt             ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_ShellshogunAssetSet:   dc.w    $F4                 ; entity type  ; was: stru_1138E
                dc.l    Boss_ShellshogunGraphicsLoadList  ; graphics load list
                dc.l    Boss_ShellshogunPaletteCommand  ; palette command
Boss_ShellshogunGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_11398
                dc.l    Boss_ShellshogunTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_SniperHoneyviperAssetSet:  dc.w    $24             ; entity type  ; was: stru_113AA
                dc.l    0                               ; graphics load list
                dc.l    Boss_SniperHoneyviperPaletteCommand  ; palette command
Boss_MadamBarbarAssetSet:   dc.w    $118                ; entity type  ; was: stru_113B4
                dc.l    Boss_MadamBarbarGraphicsLoadList  ; graphics load list
                dc.l    Boss_MadamBarbarPaletteCommand  ; palette command
Boss_MadamBarbarGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_113BE
                dc.l    Boss_MadamBarbarTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_JokerAssetSet: dc.w    $15C                        ; entity type  ; was: stru_113D0
                dc.l    Boss_JokerGraphicsLoadList      ; graphics load list
                dc.l    Boss_JokerPaletteCommand        ; palette command
Boss_JokerGraphicsLoadList: dc.w    7                   ; command: LZSS to VRAM  ; was: stru_113DA
                dc.l    Boss_JokerTileArt               ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_TerobusterAssetSet:    dc.w    $B4                 ; entity type  ; was: stru_113EC
                dc.l    Boss_TerobusterGraphicsLoadList  ; graphics load list
                dc.l    Boss_TerobusterPaletteCommand   ; palette command
Boss_TerobusterGraphicsLoadList:    dc.w    7           ; command: LZSS to VRAM  ; was: stru_113F6
                dc.l    Boss_TerobusterTileArt          ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_FlyingNeoAssetSet: dc.w    $154                    ; entity type  ; was: stru_11408
                dc.l    Boss_FlyingNeoGraphicsLoadList  ; graphics load list
                dc.l    0                               ; palette command
Boss_FlyingNeoGraphicsLoadList: dc.w    7               ; command: LZSS to VRAM  ; was: stru_11412
                dc.l    Boss_FlyingNeoTileArt           ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_XiTigerAssetSet:   dc.w    $114                    ; entity type  ; was: stru_11424
                dc.l    Boss_XiTigerGraphicsLoadList    ; graphics load list
                dc.l    Boss_XiTigerPaletteCommand      ; palette command
Boss_XiTigerGraphicsLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_1142E
                dc.l    Boss_XiTigerTileArt             ; source
                dc.w    $5000                           ; destination: VRAM $5000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_DeepStriderAssetSet:   dc.w    $19C                ; entity type  ; was: stru_11440
                dc.l    Boss_DeepStriderGraphicsLoadList  ; graphics load list
                dc.l    Boss_DeepStriderPaletteCommand  ; palette command
Boss_DeepStriderGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_1144A
                dc.l    Boss_DeepStriderTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_GustheadAssetSet:  dc.w    $1B0                    ; entity type  ; was: stru_11454
                dc.l    Boss_GustheadGraphicsLoadList   ; graphics load list
                dc.l    Boss_GustheadPaletteCommand     ; palette command
Boss_GustheadGraphicsLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_1145E
                dc.l    Boss_GustheadTileArt            ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_SharpsteelAssetSet:    dc.w    $21C                ; entity type  ; was: stru_11468
                dc.l    Boss_SharpsteelGraphicsLoadList  ; graphics load list
                dc.l    Boss_SharpsteelPaletteCommand   ; palette command
Boss_SharpsteelGraphicsLoadList:    dc.w    7           ; command: LZSS to VRAM  ; was: stru_11472
                dc.l    Boss_SharpsteelTileArt          ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_BugmaxAssetSet:    dc.w    $300                    ; entity type  ; was: stru_1147C
                dc.l    Boss_BugmaxGraphicsLoadList     ; graphics load list
                dc.l    Boss_BugmaxPaletteCommand       ; palette command
Boss_BugmaxGraphicsLoadList:    dc.w    7               ; command: LZSS to VRAM  ; was: stru_11486
                dc.l    Boss_BugmaxTileArt              ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_VictorAssetSet:    dc.w    $3C0                    ; entity type  ; was: stru_11498
                dc.l    Boss_VictorGraphicsLoadList     ; graphics load list
                dc.l    Boss_VictorPaletteCommand       ; palette command
Boss_VictorGraphicsLoadList:    dc.w    7               ; command: LZSS to VRAM  ; was: stru_114A2
                dc.l    Boss_VictorTileArt              ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_SunsetStingAssetSet:   dc.w    $1EC                ; entity type  ; was: stru_114B4
                dc.l    Boss_SunsetStingGraphicsLoadList  ; graphics load list
                dc.l    Boss_SunsetStingPaletteCommand  ; palette command
Boss_SunsetStingGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_114BE
                dc.l    Boss_SunsetStingTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_BackStringerAssetSet:  dc.w    $314                ; entity type  ; was: stru_114D0
                dc.l    Boss_BackStringerGraphicsLoadList  ; graphics load list
                dc.l    Boss_BackStringerPaletteCommand  ; palette command
Boss_BackStringerGraphicsLoadList:  dc.w    7           ; command: LZSS to VRAM  ; was: stru_114DA
                dc.l    Boss_BackStringerTileArt        ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_JampanAssetSet:    dc.w    $218                    ; field_0  ; was: stru_114E4
                                        ; UnreferencedStage20Variant1_InitializeJampanPhase   o
                dc.l    Boss_JampanGraphicsLoadList     ; field_2
                dc.l    Boss_JampanPaletteCommand       ; field_6
Boss_JampanGraphicsLoadList:    dc.w    7               ; command: LZSS to VRAM  ; was: stru_114EE
                dc.l    Boss_JampanTileArt              ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_Epsilon1AssetSet:  dc.w    $264                    ; entity type  ; was: stru_11500
                dc.l    Boss_Epsilon1GraphicsLoadList   ; graphics load list
                dc.l    Boss_Epsilon1PaletteCommands    ; palette command
Boss_Epsilon1GraphicsLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_1150A
                dc.l    Boss_Epsilon1TileArt            ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_DestroyerMk2AssetSet:  dc.w    $240                ; entity type  ; was: stru_1151C
                dc.l    Boss_DestroyerMk2GraphicsLoadList  ; graphics load list
                dc.l    Boss_DestroyerMk2PaletteCommand  ; palette command
Boss_DestroyerMk2GraphicsLoadList:  dc.w    7           ; command: LZSS to VRAM  ; was: stru_11526
                dc.l    Boss_DestroyerMk2TileArt        ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
; Love Penguin's asset set (entity type $1C0). No static pointer names it; put
; in place of Bugmax's set, it draws the boss (docs/love_penguin.md)
Boss_LovePenguinAssetSet:
                dc.w    $1C0                            ; entity type
                dc.l    Boss_LovePenguinGraphicsLoadList  ; Graphics structure pointer
                dc.l    Boss_LovePenguinPaletteCommand  ; Palette data pointer
Boss_LovePenguinGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_11542
                dc.l    Boss_LovePenguinTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedBossMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_ShieldViperAssetSet:   dc.w    $34C                ; entity type  ; was: stru_11554
                dc.l    Boss_ShieldViperGraphicsLoadList  ; graphics load list
                dc.l    Boss_ShieldViperPaletteCommand  ; palette command
Boss_ShieldViperGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_1155E
                dc.l    Boss_ShieldViperTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    $FFFF
Boss_DestroyerProtoAssetSet:    dc.w    $3B8            ; entity type  ; was: stru_11568
                dc.l    Boss_DestroyerProtoGraphicsLoadList  ; graphics load list
                dc.l    Boss_DestroyerProtoPaletteCommand  ; palette command
Boss_DestroyerProtoGraphicsLoadList:    dc.w    7       ; command: LZSS to VRAM  ; was: stru_11572
                dc.l    Boss_DestroyerProtoTileArt      ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedLateBossMappingData2020   ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_WolfGaropaAssetSet:    dc.w    $3E8                ; entity type  ; was: stru_11584
                dc.l    Boss_WolfGaropaGraphicsLoadList  ; graphics load list
                dc.l    Boss_WolfGaropaPaletteCommand   ; palette command
Boss_WolfGaropaGraphicsLoadList:    dc.w    7           ; command: LZSS to VRAM  ; was: stru_1158E
                dc.l    Boss_WolfGaropaTileArt0         ; source
                dc.w    $3C00                           ; destination: VRAM $3C00
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Boss_WolfGaropaTileArt1         ; source
                dc.w    $5100                           ; destination: VRAM $5100
                dc.w    6                               ; command: LZSS to RAM
                dc.l    WolfGaropaMappingData2020       ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
; Lambda Bunny's asset set (entity type $3EC), referenced by Stage 18's dormant
; late-phase table; its art is the head and ears the pose viewer draws
Boss_LambdaBunnyAssetSet:   dc.w    $3EC                ; entity type  ; was: stru_115A8
                dc.l    Boss_LambdaBunnyGraphicsLoadList  ; Graphics structure pointer
                dc.l    Boss_LambdaBunnyPaletteCommand  ; Palette data pointer
Boss_LambdaBunnyGraphicsLoadList:   dc.w    7           ; command: LZSS to VRAM  ; was: stru_115B2
                dc.l    Boss_LambdaBunnyTileArt         ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedLateBossMappingData2020   ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this identity-unknown record
EntityType3F0AssetSet:  dc.w    $3F0                    ; entity type  ; was: stru_115C4
                dc.l    EntityType3F0GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3F0PaletteCommand     ; Palette data pointer
EntityType3F0GraphicsLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_115CE
                dc.l    EntityType3F0TileArt            ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedLateBossMappingData2020   ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
; Stage 18's dormant late-phase table references this identity-unknown record
EntityType3F4AssetSet:  dc.w    $3F4                    ; entity type  ; was: stru_115E0
                dc.l    EntityType3F4GraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3F4PaletteCommands    ; Palette data pointer
EntityType3F4GraphicsLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_115EA
                dc.l    EntityType3F4TileArt            ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedLateBossMappingData2020   ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
; No static pointer names this asset-set start. The ROM record establishes only
; entity type $3FC and its graphics/palette fields; the old "Dragon" attribution
; remains external and is not promoted to source truth
EntityType3FCAssetSet:
                dc.w    $3FC                            ; entity type
                dc.l    EntityType3FCGraphicsLoadList   ; Graphics structure pointer
                dc.l    EntityType3FCPaletteCommands    ; Palette data pointer
EntityType3FCGraphicsLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_11606
                dc.l    EntityType3FCTileArt            ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedLateBossMappingData2020   ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_ZLeoAssetSet:  dc.w    $3F8                        ; entity type  ; was: stru_11618
                dc.l    Boss_ZLeoGraphicsLoadList       ; graphics load list
                dc.l    Boss_ZLeoPaletteCommands        ; palette command
Boss_ZLeoGraphicsLoadList:  dc.w    7                   ; command: LZSS to VRAM  ; was: stru_11622
                dc.l    Boss_ZLeoTileArt0               ; source
                dc.w    $5000                           ; destination: VRAM $5000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Boss_ZLeoTileArt1               ; source
                dc.w    $7000                           ; destination: VRAM $7000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    BossZLeoMappingData2020         ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
Boss_MissirayAssetSet:  dc.w    $3D0                    ; entity type  ; was: stru_1163C
                dc.l    Boss_MissirayGraphicsLoadList   ; graphics load list
                dc.l    Boss_MissirayPaletteCommand     ; palette command
Boss_MissirayGraphicsLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_11646
                dc.l    Boss_MissirayTileArt            ; source
                dc.w    $6000                           ; destination: VRAM $6000
                dc.w    6                               ; command: LZSS to RAM
                dc.l    SharedLateBossMappingData2020   ; source
                dc.w    $2020                           ; destination: RAM $FF2020
                dc.w    $FFFF
SevenForceValkirieAssetSet: dc.w    $42C                ; entity type  ; was: stru_11658
                dc.l    SevenForceValkirieGraphicsLoadList  ; graphics load list
                dc.l    SevenForceValkiriePaletteCommand  ; palette command
SevenForceValkirieGraphicsLoadList: dc.w    7           ; field_0  ; was: stru_11662
                                        ; SevenForceSireneTimedAssetSetA   o
                                        ; ROM:SevenForceSireneTimedAssetSetA   o
                dc.l    SevenForceValkirieTileArt       ; field_2
                dc.w    $6000                           ; field_6
                dc.w    $FFFF
SevenForceMedusaAssetSet:   dc.w    $430                ; entity type  ; was: stru_1166C
                dc.l    0                               ; graphics load list
                dc.l    SevenForceMedusaPaletteCommand  ; palette command
SevenForceSireneAssetSet:   dc.w    $434                ; entity type  ; was: stru_11676
                dc.l    0                               ; graphics load list
                dc.l    SevenForceSirenePaletteCommand  ; palette command
SevenForceArtemisAssetSet:  dc.w    $438                ; entity type  ; was: stru_11680
                dc.l    0                               ; graphics load list
                dc.l    SevenForceArtemisPaletteCommand  ; palette command
SevenForceSireneTimedAssetSetB: dc.w    $43C            ; entity type  ; was: stru_1168A
                dc.l    0                               ; graphics load list
                dc.l    SevenForceSireneTimedPaletteCommandB  ; palette command
SevenForceSireneTimedAssetSetA: dc.w    $440            ; entity type  ; was: stru_11694
                dc.l    SevenForceValkirieGraphicsLoadList  ; graphics load list
                dc.l    SevenForceSireneTimedPaletteCommandA  ; palette command
SevenForceSylpheedAssetSet: dc.w    $444                ; entity type  ; was: stru_1169E
                dc.l    0                               ; graphics load list
                dc.l    SevenForceSylpheedPaletteCommand  ; palette command

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
