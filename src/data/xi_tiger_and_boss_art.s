XiTigerCutscene_DisplayObjectSpriteMapping: dc.w    $4818, $300, $F3EB  ; DATA XREF: XiTigerCutscene_InitializeDisplayObject+10   o  ; was: word_1198D2
                dc.w    $4810, $D00, $3F3
                dc.w    $C800, $F00, $E3F3
XiTigerCutsceneTileArt: binclude "data/artcomp/tiles_1198E4.bin"  ; was: tiles_1198E4
XiTigerCutsceneTileArt_End:                             ; was: tiles_1198E4_End
; Type-6 compressed byte indices for the direct tilemap transfer's second source
XiTigerCutsceneTilemapBlockIndices: dc.b    0, $27, $31, 0, 1, $12, $13, $84, $14, $12, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $20, 1, 2
                                        ; was: byte_11A61A
                                        ; DATA XREF: ROM:0001E8B4   o
                dc.b    $27, $28, $29, $84, $2F, $80, 7, $A4, $34, $FF
; Type-6 compressed words for the direct tilemap transfer's third source
XiTigerCutsceneTilemapWordSource:   binclude "data/mappings/byte_11A644.bin"  ; was: byte_11A644
XiTigerCutsceneTilemapWordSource_End:                   ; was: byte_11A644_End
Boss_LovePenguinTileArt:            binclude "data/artcomp/tiles_11A8FC.bin"  ; entity type $1C0 art  ; was: tiles_11A8FC
                                        ; Referenced by Boss_LovePenguinGraphicsLoadList
Boss_LovePenguinTileArt_End:                            ; was: tiles_11A8FC_End
Boss_DeepStriderTileArt:    binclude "data/artcomp/tiles_11B542.bin"  ; was: tiles_11B542
Boss_DeepStriderTileArt_End:                            ; was: tiles_11B542_End
Boss_SunsetStingTileArt:    binclude "data/artcomp/tiles_11D002.bin"  ; was: tiles_11D002
Boss_SunsetStingTileArt_End:                            ; was: tiles_11D002_End
Boss_GustheadTileArt:       binclude "data/artcomp/tiles_11E5E0.bin"  ; was: tiles_11E5E0
Boss_GustheadTileArt_End:                               ; was: tiles_11E5E0_End
Boss_SharpsteelTileArt:     binclude "data/artcomp/tiles_11F310.bin"  ; was: tiles_11F310
Boss_SharpsteelTileArt_End:                             ; was: tiles_11F310_End
TeleportTileArt:            binclude "data/artcomp/tiles_120E1C.bin"  ; was: tiles_120E1C
TeleportTileArt_End:                                    ; was: tiles_120E1C_End
Boss_VictorTileArt:         binclude "data/artcomp/tiles_120FF8.bin"  ; was: tiles_120FF8
Boss_VictorTileArt_End:                                 ; was: tiles_120FF8_End
Boss_BackStringerTileArt:   binclude "data/artcomp/tiles_121932.bin"  ; was: tiles_121932
Boss_BackStringerTileArt2:  binclude "data/artcomp/tiles_123172.bin"  ; second archive at original ROM $123172
Boss_BackStringerTileArt_End:                           ; was: tiles_121932_End
Boss_Epsilon1TileArt:       binclude "data/artcomp/tiles_1233B4.bin"  ; was: tiles_1233B4
Boss_Epsilon1TileArt_End:                               ; was: tiles_1233B4_End
Boss_JampanTileArt:         binclude "data/artcomp/tiles_12453E.bin"  ; was: tiles_12453E
Boss_JampanTileArt_End:                                 ; was: tiles_12453E_End
Boss_DestroyerMk2TileArt:   binclude "data/artcomp/tiles_124CCE.bin"  ; was: tiles_124CCE
Boss_DestroyerMk2TileArt_End:                           ; was: tiles_124CCE_End
Boss_LambdaBunnyTileArt:    binclude "data/artcomp/tiles_125902.bin"  ; entity type $3EC art  ; was: tiles_125902
                                        ; Referenced by Boss_LambdaBunnyGraphicsLoadList
Boss_LambdaBunnyTileArt_End:                            ; was: tiles_125902_End
EntityType3F0TileArt:   binclude "data/artcomp/tiles_12772E.bin"  ; entity type $3F0 art  ; was: tiles_12772E
                                        ; Referenced by EntityType3F0GraphicsLoadList
UnreferencedEntityType3F0TileArt2:  binclude "data/artcomp/tiles_1291DE.bin"  ; second archive at original ROM $1291DE
EntityType3F0TileArt_End:                               ; was: tiles_12772E_End
Boss_BugmaxTileArt:                 binclude "data/artcomp/tiles_12AB8C.bin"  ; was: tiles_12AB8C
Boss_BugmaxTileArt_End:                                 ; was: tiles_12AB8C_End
EntityType3FCTileArt:               binclude "data/artcomp/tiles_12D012.bin"  ; entity type $3FC art  ; was: tiles_12D012
                                        ; Referenced by EntityType3FCGraphicsLoadList
EntityType3FCTileArt_End:                               ; was: tiles_12D012_End
EntityType3F4TileArt:   binclude "data/artcomp/tiles_12E96C.bin"  ; entity type $3F4 art  ; was: tiles_12E96C
                                        ; Referenced by EntityType3F4GraphicsLoadList
EntityType3F4TileArt_End:                               ; was: tiles_12E96C_End
SevenForceValkirieTileArt:      binclude "data/artcomp/tiles_130B4E.bin"  ; was: tiles_130B4E
SevenForceValkirieTileArt_End:                          ; was: tiles_130B4E_End
Stage20TileArt:                 binclude "data/artcomp/tiles_132E9A.bin"  ; was: tiles_132E9A
Stage20TileArt_End:                                     ; was: tiles_132E9A_End
Boss_ShieldViperTileArt:        binclude "data/artcomp/tiles_1338F2.bin"  ; was: tiles_1338F2
Boss_ShieldViperTileArt_End:                            ; was: tiles_1338F2_End
Boss_MissirayTileArt:           binclude "data/artcomp/tiles_134F02.bin"  ; was: tiles_134F02
Boss_MissirayTileArt_End:                               ; was: tiles_134F02_End
Boss_WolfGaropaTileArt0:        binclude "data/artcomp/tiles_1355D6.bin"  ; was: tiles_1355D6
Boss_WolfGaropaTileArt0_End:                            ; was: tiles_1355D6_End
Boss_WolfGaropaTileArt1:        binclude "data/artcomp/tiles_136512.bin"  ; was: tiles_136512
UnreferencedWolfGaropaTileArt2: binclude "data/artcomp/tiles_138EE4.bin"  ; second archive at original ROM $138EE4
Boss_WolfGaropaTileArt1_End:                            ; was: tiles_136512_End
Boss_DestroyerProtoTileArt:     binclude "data/artcomp/tiles_13963E.bin"  ; was: tiles_13963E
Boss_DestroyerProtoTileArt_End:                         ; was: tiles_13963E_End
Boss_ZLeoTileArt0:              binclude "data/artcomp/tiles_13A92A.bin"  ; was: tiles_13A92A
Boss_ZLeoTileArt0_End:                                  ; was: tiles_13A92A_End
Boss_ZLeoTileArt1:              binclude "data/artcomp/tiles_13C166.bin"  ; was: tiles_13C166
UnreferencedZLeoTileArt2:       binclude "data/artcomp/tiles_13D42A.bin"  ; second archive at original ROM $13D42A
Boss_ZLeoTileArt1_End:                                  ; was: tiles_13C166_End
