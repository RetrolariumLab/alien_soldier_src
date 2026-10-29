Data_Copy32Bytes:                                       ; was: sub_214B6
                                        ; Credits_LoadNextScene+18   p
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts
; End of function Data_Copy32Bytes
; ---------------------------------------------------------------------------
Credits_SceneDataPointers:  dc.l    Credits_Scene01Palette  ; was: off_214C8
                dc.l    Credits_Scene01AssetLoadList
                dc.l    Credits_Scene02Palette
                dc.l    Credits_Scene02AssetLoadList
                dc.l    Credits_Scene03Palette
                dc.l    Credits_Scene03AssetLoadList
                dc.l    Credits_Scene04Palette
                dc.l    Credits_Scene04AssetLoadList
                dc.l    Credits_Scene05Palette
                dc.l    Credits_Scene05AssetLoadList
                dc.l    Credits_Scene06Palette
                dc.l    Credits_Scene06AssetLoadList
                dc.l    Credits_Scene07Palette
                dc.l    Credits_Scene07AssetLoadList
                dc.l    Credits_Scene08Palette
                dc.l    Credits_Scene08AssetLoadList
                dc.l    Credits_Scene09Palette
                dc.l    Credits_Scene09AssetLoadList
                dc.l    Credits_Scene10Palette
                dc.l    Credits_Scene10AssetLoadList
                dc.l    Credits_Scene11Palette
                dc.l    Credits_Scene11AssetLoadList
                dc.l    Credits_Scene12Palette
                dc.l    Credits_Scene12AssetLoadList
                dc.l    Credits_Scene13Palette
                dc.l    Credits_Scene13AssetLoadList
                dc.l    Credits_Scene14Palette
                dc.l    Credits_Scene14AssetLoadList
                dc.l    Credits_Scene15Palette
                dc.l    Credits_Scene15AssetLoadList
                dc.l    Credits_Scene16Palette
                dc.l    Credits_Scene16AssetLoadList
                dc.l    Credits_Scene17Palette
                dc.l    Credits_Scene17AssetLoadList
                dc.l    Credits_Scene18Palette
                dc.l    Credits_Scene18AssetLoadList
                dc.l    Credits_Scene19Palette
                dc.l    Credits_Scene19AssetLoadList
                dc.l    Credits_Scene20Palette
                dc.l    Credits_Scene20AssetLoadList
                dc.l    $FFFFFFFF
Credits_InitialPalette:         dc.w    0, 0, $EEE, $EE, $AE, $6E, $E, 4, $48, $C88, $EAA, $ECC, $EEE, $600, $840, $C84  ; was: word_2156C
Credits_InitialAssetLoadList:   dc.w    7               ; field_0  ; was: stru_2158C
                dc.l    SharedCreditsTileArtB000        ; field_2
                dc.w    $B000                           ; field_6
                dc.w    $FFFF
Credits_Scene06Palette:         dc.w    0, $202, $404, $626, $848, $A6A, $EEE, $C8C, $EAE, $22, $EEE, $46, $28A, $6CE, $E, 0  ; was: word_21596
Credits_Scene06AssetLoadList:   dc.w    7               ; field_0  ; was: stru_215B6
                dc.l    Credits_Scene06TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene06MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene07Palette:         dc.w    0, 0, $EEE, $ECC, $AA8, $884, $EEE, $206, $42C, $A8E, $440, $28A, $6CC, $224, $248, $68C  ; was: word_215C8
Credits_Scene07AssetLoadList:   dc.w    7               ; field_0  ; was: stru_215E8
                dc.l    Credits_Scene07TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene07MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene14Palette:         dc.w    0, 0, $EEE, $FFFF, $FFFF, $FFFF, $FFFF, $CCA, $AA6, $A64, $642, $46E, $2A, 6, $2AC, $46  ; was: word_215FA
Credits_Scene14AssetLoadList:   dc.w    7               ; field_0  ; was: stru_2161A
                dc.l    Credits_Scene14TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene14MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene05Palette:         dc.w    0, 0, $EEE, $ECC, $EAA, $E88, $FFFF, $422, $644, $C68, $206, $42C, $88E, $42, $284, $2CA  ; was: word_2162C
Credits_Scene05AssetLoadList:   dc.w    7               ; field_0  ; was: stru_2164C
                dc.l    Credits_Scene05TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene05MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene01Palette:         dc.w    0, 0, $EEE, $ECC, $CAA, $A88, $FFFF, 4, $26, $4A, $6C, $2AE, $222, $444, $2A, $46E  ; was: word_2165E
Credits_Scene01AssetLoadList:   dc.w    7               ; field_0  ; was: stru_2167E
                dc.l    Credits_Scene01TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene01MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene09Palette:         dc.w    0, 0, $EEE, $ECC, $EAA, $E88, $FFFF, $204, $208, $20C, $44E, $88E, $24, $46, $6A, $2AE  ; was: word_21690
Credits_Scene09AssetLoadList:   dc.w    7               ; field_0  ; was: stru_216B0
                dc.l    Credits_Scene09TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene09MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene02Palette:         dc.w    0, $200, $CEE, $226, $88A, $24, $FFFF, $46, $28A, $6CE, $4C, 8, 4, $FFFF, $668, $AAC  ; was: word_216C2
Credits_Scene02AssetLoadList:   dc.w    7               ; field_0  ; was: stru_216E2
                dc.l    Credits_Scene02TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene02MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene03Palette:         dc.w    0, 0, $EEE, $6E4, $80, $28, $FFFF, $6C, $AE, $422, $446, $488, $8CC, 6, $20C, $66E  ; was: word_216F4
Credits_Scene03AssetLoadList:   dc.w    7               ; field_0  ; was: stru_21714
                dc.l    Credits_Scene03TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene03MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene10Palette:         dc.w    0, 0, $EEE, $6E4, $80, $28, $FFFF, $6C, $AE, $422, $446, $488, $8CC, 6, $20C, $66E  ; was: word_21726
Credits_Scene10AssetLoadList:   dc.w    7               ; field_0  ; was: stru_21746
                dc.l    Credits_Scene10TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene10MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene04Palette:         dc.w    0, 0, $EEE, $6AC, $48A, $268, $FFFF, $246, $24, $206, $22A, $26C, 0, $202, $624, $868  ; was: word_21758
Credits_Scene04AssetLoadList:   dc.w    7               ; field_0  ; was: stru_21778
                dc.l    Credits_Scene04TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene04MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene08Palette:         dc.w    0, 0, $EEE, $FFFF, $FFFF, $FFFF, $FFFF, $8C, $6A, $48, $26, $46E, $2A, 6, $888, $444  ; was: word_2178A
Credits_Scene08AssetLoadList:   dc.w    7               ; field_0  ; was: stru_217AA
                dc.l    Credits_Scene08TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene08MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene11Palette:         dc.w    0, 0, $EEE, $ECC, $EAA, $E88, $FFFF, $E02, $420, $A44, 6, $2A, $46E, $24, $268, $4AC  ; was: word_217BC
Credits_Scene11AssetLoadList:   dc.w    7               ; field_0  ; was: stru_217DC
                dc.l    Credits_Scene11TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene11MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene12Palette:         dc.w    0, 0, $EEE, $ECC, $EAA, $E88, $FFFF, 6, $2A, $46E, $22, $244, $288, $26, $48, $8C  ; was: word_217EE
Credits_Scene12AssetLoadList:   dc.w    7               ; field_0  ; was: stru_2180E
                dc.l    Credits_Scene12TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene12MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene13Palette:         dc.w    0, 0, $EEE, $ECC, $A88, $866, $FFFF, $644, $422, $26, $4A, $8E, $400, $A42, $E86, 8  ; was: word_21820
Credits_Scene13AssetLoadList:   dc.w    7               ; field_0  ; was: stru_21840
                dc.l    Credits_Scene13TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene13MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene15Palette:         dc.w    0, $204, $EEE, $ACA, $466, $44, $EEE, $2CE, $8C, $8E, $4C, $2A, $208, $68, $6AE, $AEE  ; was: word_21852
Credits_Scene15AssetLoadList:   dc.w    7               ; field_0  ; was: stru_21872
                dc.l    Credits_Scene15TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene15MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene16Palette:         dc.w    0, $600, $EEE, $666, $444, $442, $EEE, $AAA, $866, $E48, $C26, $A24, $802, $26, $8C, $EAC  ; was: word_21884
Credits_Scene16AssetLoadList:   dc.w    7               ; field_0  ; was: stru_218A4
                dc.l    Credits_Scene16TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene16MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene17Palette:         dc.w    0, $220, $EEE, $28C, $46, $242, $EEE, $C8, $84, $4C6, $284, $62, $42, $40, $6C, $4EA  ; was: word_218B6
Credits_Scene17AssetLoadList:   dc.w    7               ; field_0  ; was: stru_218D6
                dc.l    Credits_Scene17TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene17MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene18Palette:         dc.w    0, $402, $EEE, $66C, $448, $224, $EEE, $A8A, $668, $CCA, $A88, $866, $222, $28, $6E, $CCC  ; was: word_218E8
Credits_Scene18AssetLoadList:   dc.w    7               ; field_0  ; was: stru_21908
                dc.l    Credits_Scene18TileArt          ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene18MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_Scene19Palette:         dc.w    0, $202, $EEE, $6EE, $28A, $222, $EEE, $EA8, $A64, $EA8, $E62, $C22, $802, $402, $484, $EEC  ; was: word_2191A
Credits_Scene19AssetLoadList:   dc.w    7               ; field_0  ; was: stru_2193A
                dc.l    Credits_Scene19TileArt          ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene19MappingData      ; field_2
                dc.w    $C000                           ; field_6
                dc.w    $FFFF
Credits_Scene20Palette:         dc.w    0, 0, $EEE, $E88, $844, $422, 0, $200, 2, 4, $24, $46, $268, $4AC, $6CE, $AE  ; was: word_2194C
Credits_Scene20AssetLoadList:   dc.w    7               ; field_0  ; was: stru_2196C
                dc.l    Credits_Scene20TileArt          ; field_2
                dc.w    $2000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_Scene20MappingData      ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_TreasurePaletteData:    dc.w    0, $EEE, $EEC, $ECA, $CA8, $A86, $864, $642, $420, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE, $EEE  ; was: word_2197E
                dc.w    0, $200, $400, $600, $802, $A04, $C06, $E08, $E2A, $E4C, $E6E, $E8E, $EAE, $ECE, $EEE, $EEE
                dc.w    0, $EEE, $EEE, 2, 4, 6, $28, $4A, $6C, $8E, $AE, $CE, $2EE, $6EE, $AEE, $EEE
Credits_TreasureAssetLoadList:  dc.w    7               ; field_0  ; was: stru_219DE
                dc.l    Credits_TreasureTileArt0        ; field_2
                dc.w    0                               ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_TreasureTileArt1        ; field_2
                dc.w    $8000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_TreasureMappingData0    ; field_2
                dc.w    $C000                           ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_TreasureMappingData1    ; field_2
                dc.w    $E000                           ; field_6
                dc.w    $FFFF
Credits_SegaPalette:        dc.w    0, $EEE, $EC0, $EA0, $E80, $E60, $E40, $E20, $E00, $C00, $A00, $800, $E00, $E00, $E00, $EEE  ; was: word_21A00
Credits_SegaAssetLoadList:  dc.w    7                   ; field_0  ; was: stru_21A20
                dc.l    Credits_SegaTileArt             ; field_2
                dc.w    $800                            ; field_6
                dc.w    7                               ; field_0
                dc.l    Credits_SegaMappingData         ; field_2
                dc.w    $C61C                           ; field_6
                dc.w    $FFFF
Credits_XiTigerSpriteFrame: dc.w    $580, $F0F, $A0F0   ; was: word_21A32
                                        ; Credits_InitXiTiger+158   o
                dc.w    $580, $F0F, $C0F0
                dc.w    $580, $F0F, $E0F0
                dc.w    $580, $F0F, $F0
                dc.w    $580, $F0F, $20F0
                dc.w    $580, $F0F, $40F0
                dc.w    $8580, $F0F, $60F0

; Dispatcher for selection menu state machine
