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
Credits_InitialPalette:         binclude "data/palettes/02156C.bin"  ; was: word_2156C
Credits_InitialAssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2158C
                dc.l    SharedCreditsTileArtB000        ; source
                dc.w    $B000                           ; destination: VRAM $B000
                dc.w    $FFFF
Credits_Scene06Palette:         binclude "data/palettes/021596.bin"  ; was: word_21596
Credits_Scene06AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_215B6
                dc.l    Credits_Scene06TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene06MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene07Palette:         binclude "data/palettes/0215C8.bin"  ; was: word_215C8
Credits_Scene07AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_215E8
                dc.l    Credits_Scene07TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene07MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene14Palette:         binclude "data/palettes/0215FA.bin"  ; was: word_215FA
Credits_Scene14AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2161A
                dc.l    Credits_Scene14TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene14MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene05Palette:         binclude "data/palettes/02162C.bin"  ; was: word_2162C
Credits_Scene05AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2164C
                dc.l    Credits_Scene05TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene05MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene01Palette:         binclude "data/palettes/02165E.bin"  ; was: word_2165E
Credits_Scene01AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2167E
                dc.l    Credits_Scene01TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene01MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene09Palette:         binclude "data/palettes/021690.bin"  ; was: word_21690
Credits_Scene09AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_216B0
                dc.l    Credits_Scene09TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene09MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene02Palette:         binclude "data/palettes/0216C2.bin"  ; was: word_216C2
Credits_Scene02AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_216E2
                dc.l    Credits_Scene02TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene02MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene03Palette:         binclude "data/palettes/0216F4.bin"  ; was: word_216F4
Credits_Scene03AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_21714
                dc.l    Credits_Scene03TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene03MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene10Palette:         binclude "data/palettes/021726.bin"  ; was: word_21726
Credits_Scene10AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_21746
                dc.l    Credits_Scene10TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene10MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene04Palette:         binclude "data/palettes/021758.bin"  ; was: word_21758
Credits_Scene04AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_21778
                dc.l    Credits_Scene04TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene04MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene08Palette:         binclude "data/palettes/02178A.bin"  ; was: word_2178A
Credits_Scene08AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_217AA
                dc.l    Credits_Scene08TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene08MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene11Palette:         binclude "data/palettes/0217BC.bin"  ; was: word_217BC
Credits_Scene11AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_217DC
                dc.l    Credits_Scene11TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene11MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene12Palette:         binclude "data/palettes/0217EE.bin"  ; was: word_217EE
Credits_Scene12AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2180E
                dc.l    Credits_Scene12TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene12MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene13Palette:         binclude "data/palettes/021820.bin"  ; was: word_21820
Credits_Scene13AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_21840
                dc.l    Credits_Scene13TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene13MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene15Palette:         binclude "data/palettes/021852.bin"  ; was: word_21852
Credits_Scene15AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_21872
                dc.l    Credits_Scene15TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene15MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene16Palette:         binclude "data/palettes/021884.bin"  ; was: word_21884
Credits_Scene16AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_218A4
                dc.l    Credits_Scene16TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene16MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene17Palette:         binclude "data/palettes/0218B6.bin"  ; was: word_218B6
Credits_Scene17AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_218D6
                dc.l    Credits_Scene17TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene17MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene18Palette:         binclude "data/palettes/0218E8.bin"  ; was: word_218E8
Credits_Scene18AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_21908
                dc.l    Credits_Scene18TileArt          ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene18MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_Scene19Palette:         binclude "data/palettes/02191A.bin"  ; was: word_2191A
Credits_Scene19AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2193A
                dc.l    Credits_Scene19TileArt          ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene19MappingData      ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    $FFFF
Credits_Scene20Palette:         binclude "data/palettes/02194C.bin"  ; was: word_2194C
Credits_Scene20AssetLoadList:   dc.w    7               ; command: LZSS to VRAM  ; was: stru_2196C
                dc.l    Credits_Scene20TileArt          ; source
                dc.w    $2000                           ; destination: VRAM $2000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_Scene20MappingData      ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_TreasurePaletteData:    binclude "data/palettes/02197E.bin"  ; was: word_2197E
Credits_TreasureAssetLoadList:  dc.w    7               ; command: LZSS to VRAM  ; was: stru_219DE
                dc.l    Credits_TreasureTileArt0        ; source
                dc.w    0                               ; destination: VRAM $0000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_TreasureTileArt1        ; source
                dc.w    $8000                           ; destination: VRAM $8000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_TreasureMappingData0    ; source
                dc.w    $C000                           ; destination: VRAM $C000
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_TreasureMappingData1    ; source
                dc.w    $E000                           ; destination: VRAM $E000
                dc.w    $FFFF
Credits_SegaPalette:        binclude "data/palettes/021A00.bin"  ; was: word_21A00
Credits_SegaAssetLoadList:  dc.w    7                   ; command: LZSS to VRAM  ; was: stru_21A20
                dc.l    Credits_SegaTileArt             ; source
                dc.w    $800                            ; destination: VRAM $0800
                dc.w    7                               ; command: LZSS to VRAM
                dc.l    Credits_SegaMappingData         ; source
                dc.w    $C61C                           ; destination: VRAM $C61C
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
