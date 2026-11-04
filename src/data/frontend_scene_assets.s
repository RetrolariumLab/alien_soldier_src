; Repeated source pattern used by the message-display fill DMAs
MessageDisplay_FontPatternFillSource:   dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8  ; was: unknown_2
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
                dc.w    $C7F8, $C7F8, $C7F8, $C7F8, $C7F8, $C7F8
; Six-word font-base patterns restored to the three message-display destinations
MessageDisplay_FontBasePattern0:    dc.w    $C7CC, $C7CD, $C7CE, $C7CF, $C7D0, $C7BF  ; was: unlabeled_180060
MessageDisplay_FontBasePattern1:    dc.w    $C7F8, $C7DC, $C7DD, $C7DE, $C7DF, $C7BF  ; was: unlabeled_18006C
MessageDisplay_FontBasePattern2:    dc.w    $C7F8, $C7EC, $C7ED, $C7EE, $C7EF, $C7BF  ; was: unlabeled_180078
FrontendUnreferencedMappingData:    binclude "data/mappings/unused.bin"
FrontendUnreferencedMappingData_End:
FrontendUnreferencedTileArt:        binclude "data/artcomp/tiles_180F84.bin"  ; was: tiles_180F84
FrontendUnreferencedTileArt_End:                        ; was: tiles_180F84_End
SharedFrontendAndTransitionTileArt: binclude "data/artcomp/18140E.bin"  ; was: byte_18140E
                                        ; ROM:0001CF04   o
FrontendTitleTileArt3000:       binclude "data/artcomp/tiles_1814D4.bin"  ; was: tiles_1814D4
FrontendTitleTileArt3000_End:                           ; was: tiles_1814D4_End
FrontendTitleMappingData6000:   dc.b    0, $44, $26, 0, $17, 2, 3, 4, 5, 6, 7, 8, 9, $C, $D, $E, $F, $10, $11, $12, $13, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $80, $1F, $20  ; was: byte_182C9C
                dc.b    $20, 1, $21, $22, $80, 3, $84, $27, 0, $23, $80, $2B, 0, $24, $80, $2E, 2, $25, $26, $27, $32, 0, 1, $A, $B, $90, $49, 1, $14, $15, $90, $51
                dc.b    1, $1E, $1F, $51, 0, 0
FrontendTitleMappingData4000:               binclude "data/mappings/byte_182CE2.bin"  ; was: byte_182CE2
FrontendTitleMappingData4000_End:                       ; was: byte_182CE2_End
SharedTitleAndOptionsType3DataA:            binclude "data/other/byte_182F24.bin"  ; was: byte_182F24
SharedTitleAndOptionsType3DataA_End:                    ; was: byte_182F24_End
SharedTitleAndOptionsType3DataB:            binclude "data/other/byte_184378.bin"  ; was: byte_184378
SharedTitleAndOptionsType3DataB_End:                    ; was: byte_184378_End
SharedFrontendAndTransitionMappingData7000: dc.b    0, $41, $A, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $FF, $35, 0, $84, $20, 0, 0, $88, $21, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F  ; was: byte_18454C
                                        ; ROM:0000A218   o
                dc.b    0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0
                dc.b    $5B, 0, 0, $FF
SharedFrontendAndTransitionMappingDataA:                ; was: byte_184590
                dc.b    0, $F5, $1F, 0, $30, $31, $32, $33, $34, $35, $36, $41, $38, $39, $3A, $3B, $3C, $3D, $3E, $43, 4, 5, 6, 7, $C, $D, $E, 3, 8, 9, $A, $B
                                        ; ROM:0000A208   o
                dc.b    $10, $11, $12, $F, $1E, $1F, $20, $21, $22, $23, $24, $25, 0, $27, $28, $29, $2A, $2B, $2C, $2D, $20, 0, 5, $14, $15, $16, $17, $18, $19, $26, 0, 0
                dc.b    $37, $94, 8, 1, $3F, $40, $90, $11, 1, $F, 1, $90, $19, 1, $13, 2, $90, $21, 1, $26, $2F, $90, $29, 0, $2E, $39, 0, 1, $45, $46, $88, $4D
                dc.b    2, $47, $48, $49, $8C, $54, 4, $4C, $4D, $4E, $4F, $52, $84, $5E, 3, $50, $51, $53, $54, $88, $65, 2, $55, $56, $4A, $AC, $3B, 5, $57, $58, $59, $5A
                dc.b    $5B, $5C, $5F, 0, 0, $C0, $90, 2, $5D, $5E, $5F, $E4, $A5, $FC, $77, $58, 0, 0, $60, 0, $92, $70, $F, $71, $72, $7A, $7B, $7C, 0, $73, $74, $75
                dc.b    $76, 0, $7D, $7E, 0, $77, $78, $81, $62, 0, $91, $62, 0, $80, $79, 0, 0, 1, $82, $83, $89, $67, 3, $94, 0, $85, $86, $81, $77, 0, $95, $81
                dc.b    $7A, 3, $88, $89, $8A, $93, $81, $80, 4, $8C, $8D, $8E, $8F, $90, $B9, $4E, 0, $7F, $95, $90, 0, $81, $80, $50, $8D, $9A, 0, $84, $95, $A0, 0, $87
                dc.b    $95, $A8, 0, $8B, $84, $38, $90, $6F, $F9, $87, 2, $4B, $44, $42, $8D, $DC, $FD, $7F, $5F, 0, 0, $86, $44, $FF
SharedFrontendAndTransitionMappingDataB:    binclude "data/mappings/byte_184688.bin"  ; was: byte_184688
SharedFrontendAndTransitionMappingDataB_End:            ; was: byte_184688_End
ResultsPostStageCompletionTileArt2000:      binclude "data/artcomp/tiles_1850C6.bin"  ; was: tiles_1850C6
ResultsPostStageCompletionTileArt2000_End:              ; was: tiles_1850C6_End
ResultsPostStageCompletionMappingData2020:  dc.b    0, $9F, $22, 0, $21, 1, 0, 2, $8C, 7, 2, $1E, 1, $1F, $2E, 0, $60, 1, 3, 4, $84, $21, 0, 5, $60, 1, $20, $21, $84, $29, 0, $22  ; was: byte_185268
                dc.b    $BC, $1F, 0, 6, $65, 1, 7, 8, 9, $23, $24, $25, $26, $30, 0, $61, 1, $A, $B, $C, $84, $65, 0, $27, $60, 1, $28, $29, $BC, $5F, 0, $D
                dc.b    $65, 1, $E, $F, $10, $2A, $2B, $2C, $2D, $C4, $3F, 0, $11, $60, 1, $12, $13, $84, $A5, 0, $2E, $60, 1, $2F, $30, $BC, $9F, 0, $14, $60, 1, $15
                dc.b    $16, 1, 9, $16, $61, 1, $31, $32, $33, 1, 9, $33, $BC, $BF, 0, $17, $65, 1, $18, $10, 5, $34, $35, $36, $22, $C4, $BF, 0, $19, $84, $3D, 0
                dc.b    $1A, $84, $BF, 0, $37, $80, $3D, 1, 1, $38, $BC, $FF, 0, $1B, $60, 1, $1C, $1D, $85, $23, 0, $39, $60, 1, $3A, $3B, $FC, $9D, $56, 0, 0, 0
                dc.b    0, $FF
StoryScreenTileArt0000:             binclude "data/artcomp/tiles_18530A.bin"  ; was: tiles_18530A
StoryScreenTileArt0000_End:                             ; was: tiles_18530A_End
StoryScreenMappingData4000:         binclude "data/mappings/byte_1885A4.bin"  ; was: byte_1885A4
StoryScreenMappingData4000_End:                         ; was: byte_1885A4_End
StoryScreenMappingData6000:         binclude "data/mappings/byte_1889B0.bin"  ; was: byte_1889B0
UnreferencedIntroSceneSpriteArt:    binclude "data/mappings/byte_188A16.bin"  ; second archive at original ROM $188A16
StoryScreenMappingData6000_End:                         ; was: byte_1889B0_End
