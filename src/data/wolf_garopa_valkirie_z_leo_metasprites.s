; Metasprite definitions for Wolf Garopa, Valkirie, and Z-Leo
; Wolf Garopa directional frames and metasprite definition
; Each rotation table contains eight mapping pointers selected by the descriptor array
Boss_WolfGaropaRotationFramesA: dc.l    Boss_WolfGaropaRotationMappingA0  ; DATA XREF: ROM:00035320   o  ; was: off_352A6
                                        ; ROM:00035334   o
                dc.l    Boss_WolfGaropaRotationMappingA1
                dc.l    Boss_WolfGaropaRotationMappingA2
                dc.l    Boss_WolfGaropaRotationMappingA3
                dc.l    Boss_WolfGaropaRotationMappingA4
                dc.l    Boss_WolfGaropaRotationMappingA5
                dc.l    Boss_WolfGaropaRotationMappingA6
                dc.l    Boss_WolfGaropaRotationMappingA7
Boss_WolfGaropaRotationFramesB: dc.l    Boss_WolfGaropaRotationMappingB0  ; DATA XREF: ROM:00035348   o  ; was: off_352C6
                                        ; ROM:0003535C   o
                dc.l    Boss_WolfGaropaRotationMappingB1
                dc.l    Boss_WolfGaropaRotationMappingB2
                dc.l    Boss_WolfGaropaRotationMappingB3
                dc.l    Boss_WolfGaropaRotationMappingB4
                dc.l    Boss_WolfGaropaRotationMappingB5
                dc.l    Boss_WolfGaropaRotationMappingB6
                dc.l    Boss_WolfGaropaRotationMappingB7
Boss_WolfGaropaRotationFramesC: dc.l    Boss_WolfGaropaRotationMappingC0  ; DATA XREF: ROM:00035328   o  ; was: off_352E6
                                        ; ROM:0003533C   o
                dc.l    Boss_WolfGaropaRotationMappingC1
                dc.l    Boss_WolfGaropaRotationMappingC2
                dc.l    Boss_WolfGaropaRotationMappingC3
                dc.l    Boss_WolfGaropaRotationMappingC4
                dc.l    Boss_WolfGaropaRotationMappingC5
                dc.l    Boss_WolfGaropaRotationMappingC6
                dc.l    Boss_WolfGaropaRotationMappingC7
Boss_WolfGaropaInlineSpriteDescriptor:  dc.w    $63DE, $500, $F8F8  ; DATA XREF: ROM:00035324   o  ; was: word_35306
                                        ; ROM:0003532C   o
Boss_WolfGaropaMetaspriteDescriptors:   dc.l    0       ; DATA XREF: Boss_WolfGaropaInitialize+1E   o  ; was: dword_3530C
                dc.l    0
                dc.l    0
                dc.l    0
                dc.l    0
                dc.l    Boss_WolfGaropaRotationFramesA+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaRotationFramesC+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaPoseAngleOutsideRangeMapping+$8400000
                dc.l    Boss_WolfGaropaRotationFramesA+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaRotationFramesC+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaPoseAngleOutsideRangeMapping+$8400000
                dc.l    Boss_WolfGaropaRotationFramesB+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaRotationFramesC+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaPoseAngleOutsideRangeMapping+$8400000
                dc.l    Boss_WolfGaropaRotationFramesB+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaRotationFramesC+$18000000
                dc.l    Boss_WolfGaropaInlineSpriteDescriptor+1
                dc.l    Boss_WolfGaropaPoseAngleOutsideRangeMapping+$8400000
Boss_WolfGaropaPartRadii:   dc.w    $2C, $2612, $1891   ; DATA XREF: Boss_WolfGaropaInitialize+24   o  ; was: word_35370
                dc.w    $A290, $9F88, $1122
                dc.w    $F1F, $893, $A694
                dc.w    $A688, $1326, $1426
                dc.w    $800
Boss_WolfGaropaPartLinks:   dc.w    0, 0, 0             ; DATA XREF: Boss_WolfGaropaInitialize+2A   o  ; was: word_3538A
                dc.w    0, 0, $4063
                dc.w    $64, $4243, $244
                dc.w    $4303, $40C8, $C9
                dc.w    $4428, $429, $44E8
                dc.w    $4123, $124, $4603
                dc.w    $604, $46C3, $4188
                dc.w    $189, $47E8, $7E9
                dc.w    $48A8
; Valkirie directional frames and primary metasprite definition
; Three eight-pointer rotation tables; C is selected without A/B's high-bit flags
Boss_ValkirieRotationFramesA:   dc.l    Boss_ValkirieRotationAMapping0  ; DATA XREF: ROM:00035438   o  ; was: off_353BC
                                        ; ROM:0003544C   o
                dc.l    Boss_ValkirieRotationAMapping1
                dc.l    Boss_ValkirieRotationAMapping2
                dc.l    Boss_ValkirieRotationAMapping3
                dc.l    Boss_ValkirieRotationAMapping4
                dc.l    Boss_ValkirieRotationAMapping5
                dc.l    Boss_ValkirieRotationAMapping6
                dc.l    Boss_ValkirieRotationAMapping7
Boss_ValkirieRotationFramesB:   dc.l    Boss_ValkirieRotationBMapping0  ; DATA XREF: ROM:0003542C   o  ; was: off_353DC
                                        ; ROM:00035434   o
                dc.l    Boss_ValkirieRotationBMapping1
                dc.l    Boss_ValkirieRotationBMapping2
                dc.l    Boss_ValkirieRotationBMapping3
                dc.l    Boss_ValkirieRotationBMapping4
                dc.l    Boss_ValkirieRotationBMapping5
                dc.l    Boss_ValkirieRotationBMapping6
                dc.l    Boss_ValkirieRotationBMapping7
Boss_ValkirieRotationFramesC:   dc.l    Boss_ValkirieSharedRotationCMappingA  ; DATA XREF: ROM:00035454   o  ; was: off_353FC
                                        ; ROM:00035464   o
                dc.l    Boss_ValkirieSharedRotationCMappingB
                dc.l    Boss_ValkirieSharedRotationCMappingB
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingA
Boss_ValkirieMetaspriteDescriptors: dc.l    Boss_ValkirieMetaspriteMappingB+$400000  ; DATA XREF: Debug_LambdaBunnyViewerInitialize+18   o  ; was: off_3541C
                dc.l    0
                dc.l    Boss_ValkiriePackedSpriteMappings+$400000
                dc.l    0
                dc.l    Boss_ValkirieRotationFramesB+$18000000
                dc.l    Boss_ValkirieMetaspriteMappingC+$400000
                dc.l    Boss_ValkirieRotationFramesB+$18000000
                dc.l    Boss_ValkirieRotationFramesA+$18000000
                dc.l    0
                dc.l    Boss_ValkirieRotationFramesB+$18000000
                dc.l    Boss_ValkirieMetaspriteMappingC+$400000
                dc.l    Boss_ValkirieRotationFramesB+$18000000
                dc.l    Boss_ValkirieRotationFramesA+$18000000
                dc.l    0
                dc.l    Boss_ValkirieRotationFramesC
                dc.l    Boss_ValkirieMetaspriteMappingD+$400000
                dc.l    Boss_ValkirieMetaspriteMappingA+$400000
                dc.l    0
                dc.l    Boss_ValkirieRotationFramesC
                dc.l    Boss_ValkirieMetaspriteMappingD+$400000
                dc.l    Boss_ValkirieMetaspriteMappingA+$400000
Boss_ValkiriePartRadii: dc.w    0, $A, $8A95            ; DATA XREF: Debug_LambdaBunnyViewerInitialize+1E   o  ; was: word_35470
                dc.w    $909D, $A0A, $1510
                dc.w    $1D0A, $E1C, $100A
                dc.w    $E1C, $1000
Boss_ValkiriePartLinks: dc.w    $8009, 0, $8007         ; DATA XREF: Debug_LambdaBunnyViewerInitialize+24   o  ; was: word_35486
                dc.w    $60, $8124, $8123
                dc.w    $81E4, $81E3, $60
                dc.w    $830F, $830E, $83CF
                dc.w    $83CF, $C0, $84EA
                dc.w    $84E9, $85A8, $C0
                dc.w    $866C, $866B, $872A
; Alternate Valkirie data reused as rotation frames and interpolation pose bytes
Boss_ValkirieAlternateRotationFramesAndNeutralPose: dc.l    Boss_ValkirieRotationAMapping0  ; DATA XREF: ROM:0003552C   o  ; was: off_354B0
                                        ; ROM:00035540   o
                dc.l    Boss_ValkirieRotationAMapping1
                dc.l    Boss_ValkirieRotationAMapping2
                dc.l    Boss_ValkirieRotationAMapping3
                dc.l    Boss_ValkirieRotationAMapping4
                dc.l    Boss_ValkirieRotationAMapping5
                dc.l    Boss_ValkirieRotationAMapping6
                dc.l    Boss_ValkirieRotationAMapping7
Boss_ValkirieAlternateRotationFramesB:  dc.l    Boss_ValkirieRotationBMapping0  ; DATA XREF: ROM:00035520   o  ; was: off_354D0
                                        ; ROM:00035528   o
                dc.l    Boss_ValkirieRotationBMapping1
                dc.l    Boss_ValkirieRotationBMapping2
                dc.l    Boss_ValkirieRotationBMapping3
                dc.l    Boss_ValkirieRotationBMapping4
                dc.l    Boss_ValkirieRotationBMapping5
                dc.l    Boss_ValkirieRotationBMapping6
                dc.l    Boss_ValkirieRotationBMapping7
Boss_ValkirieAlternateRotationFramesC:  dc.l    Boss_ValkirieSharedRotationCMappingA  ; DATA XREF: ROM:00035548   o  ; was: off_354F0
                                        ; ROM:00035558   o
                dc.l    Boss_ValkirieSharedRotationCMappingB
                dc.l    Boss_ValkirieSharedRotationCMappingB
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingC
                dc.l    Boss_ValkirieSharedRotationCMappingA
                dc.l    Boss_ValkirieMetaspriteMappingB+$400000
                dc.l    0
                dc.l    Boss_ValkiriePackedSpriteMappings+$400000
                dc.l    0
                dc.l    Boss_ValkirieAlternateRotationFramesB+$18000000
                dc.l    Boss_ValkirieMetaspriteMappingC+$400000
                dc.l    Boss_ValkirieAlternateRotationFramesB+$18000000
                dc.l    Boss_ValkirieAlternateRotationFramesAndNeutralPose+$18000000
                dc.l    0
                dc.l    Boss_ValkirieAlternateRotationFramesB+$18000000
                dc.l    Boss_ValkirieMetaspriteMappingC+$400000
                dc.l    Boss_ValkirieAlternateRotationFramesB+$18000000
                dc.l    Boss_ValkirieAlternateRotationFramesAndNeutralPose+$18000000
                dc.l    0
                dc.l    Boss_ValkirieAlternateRotationFramesC
                dc.l    Boss_ValkirieMetaspriteMappingD+$400000
                dc.l    Boss_ValkirieMetaspriteMappingA+$400000
                dc.l    0
                dc.l    Boss_ValkirieAlternateRotationFramesC
                dc.l    Boss_ValkirieMetaspriteMappingD+$400000
                dc.l    Boss_ValkirieMetaspriteMappingA+$400000
                dc.w    0, $A, $8A95
                dc.w    $909D, $A0A, $1510
                dc.w    $1D0A, $E1C, $100A
                dc.w    $E1C, $1000, $8009
                dc.w    0, $8007, $60
                dc.w    $8124, $8123, $81E4
                dc.w    $81E3, $60, $830F
                dc.w    $830E, $83CF, $83CF
                dc.w    $C0, $84EA, $84E9
                dc.w    $85A8, $C0, $866C
                dc.w    $866B, $872A
; Z-Leo definition also reused by Valkirie Force as setup and interpolation data
Boss_ZLeoValkirieForceSharedMetaspriteData: dc.l    0   ; DATA XREF: Boss_ZLeoIntroInit+22   o  ; was: dword_355A4
                                        ; Boss_ValkirieForceInit+10   o
                dc.l    0
                dc.l    0
                dc.l    Boss_ZLeoValkirieForceSharedMappingA+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingB+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingA+$400000
                dc.l    Boss_ZLeoBladeDirectionMapping2+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingA+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingB+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingC+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingB+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingC+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingD+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingC+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingD+$400000
                dc.l    Boss_ZLeoValkirieForceSharedMappingE+$400000
Boss_ZLeoPartRadii: dc.w    $38, $3818, $1818           ; DATA XREF: Boss_ZLeoIntroInit+28   o  ; was: word_355E4
                dc.w    $1E18, $280C, $1C10
                dc.w    $200C, $1C1A
Boss_ZLeoPartLinks: dc.w    $8000, 0, $8000             ; DATA XREF: Boss_ZLeoIntroInit+2E   o  ; was: word_355F4
                dc.w    $806B, $812A, $8189
                dc.w    $81E9, $80CF, $80CE
                dc.w    $830D, $830C, $83CB
                dc.w    $83CA, $8489, $8488
                dc.w    $8547
