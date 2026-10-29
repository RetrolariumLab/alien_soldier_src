; Metasprite definitions for Madam Barbar, Flying Neo, Joker,
; Back Stringer, and Sharpsteel
; Madam Barbar directional frames and metasprite definition
Boss_MadamBarbarRotationFramesA:    dc.l    Boss_MadamBarbarRotationSetAFrame07  ; was: off_34DB6
                                        ; ROM:00034E78   o
                dc.l    Boss_MadamBarbarRotationSetAFrame06
                dc.l    Boss_MadamBarbarRotationSetAFrame04
                dc.l    Boss_MadamBarbarRotationSetAFrame01
                dc.l    Boss_MadamBarbarRotationSetAFrame02
                dc.l    Boss_MadamBarbarRotationSetAFrame00
                dc.l    Boss_MadamBarbarRotationSetAFrame03
                dc.l    Boss_MadamBarbarRotationSetAFrame05
Boss_MadamBarbarRotationFramesB:    dc.l    Boss_MadamBarbarRotationSetAFrame05  ; was: off_34DD6
                                        ; ROM:00034E74   o
                dc.l    Boss_MadamBarbarRotationSetAFrame03
                dc.l    Boss_MadamBarbarRotationSetAFrame00
                dc.l    Boss_MadamBarbarRotationSetAFrame02
                dc.l    Boss_MadamBarbarRotationSetAFrame01
                dc.l    Boss_MadamBarbarRotationSetAFrame04
                dc.l    Boss_MadamBarbarRotationSetAFrame06
                dc.l    Boss_MadamBarbarRotationSetAFrame07
Boss_MadamBarbarRotationFramesC:    dc.l    Boss_MadamBarbarRotationSetBFrame00  ; was: off_34DF6
                                        ; ROM:00034E9C   o
                dc.l    Boss_MadamBarbarRotationSetBFrame01
                dc.l    Boss_MadamBarbarRotationSetBFrame02
                dc.l    Boss_MadamBarbarRotationSetBFrame03
                dc.l    Boss_MadamBarbarRotationSetBFrame04
                dc.l    Boss_MadamBarbarRotationSetBFrame05
                dc.l    Boss_MadamBarbarRotationSetBFrame06
                dc.l    Boss_MadamBarbarRotationSetBFrame07
Boss_MadamBarbarRotationFramesD:    dc.l    Boss_MadamBarbarRotationSetBFrame07  ; was: off_34E16
                                        ; ROM:00034E84   o
                dc.l    Boss_MadamBarbarRotationSetBFrame06
                dc.l    Boss_MadamBarbarRotationSetBFrame05
                dc.l    Boss_MadamBarbarRotationSetBFrame04
                dc.l    Boss_MadamBarbarRotationSetBFrame03
                dc.l    Boss_MadamBarbarRotationSetBFrame02
                dc.l    Boss_MadamBarbarRotationSetBFrame01
                dc.l    Boss_MadamBarbarRotationSetBFrame00
; Low-bit-tagged inline descriptors: words copied to child $E, $8, and $A
Boss_MadamBarbarInlineSpriteDescriptorA:    dc.w    $6390, $F00, $F0F0  ; was: word_34E36
                                        ; ROM:00034E70   o
Boss_MadamBarbarInlineSpriteDescriptorB:    dc.w    $63A0, $A00, $F4F4  ; was: word_34E3C
                                        ; ROM:00034E50   o
Boss_MadamBarbarInlineSpriteDescriptorC:    dc.w    $43C4, 0, $FCFC  ; was: word_34E42
                                        ; ROM:00034E8C   o
Boss_MadamBarbarMetaspriteDescriptors:  dc.l    0       ; was: dword_34E48
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorB+1
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorB+1
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorB+1
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorA+1
                dc.l    Boss_MadamBarbarRotationFramesB
                dc.l    Boss_MadamBarbarRotationFramesA+$18000000
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorB+1
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorB+1
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorB+1
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorA+1
                dc.l    Boss_MadamBarbarRotationFramesB
                dc.l    Boss_MadamBarbarRotationFramesA+$18000000
                dc.l    Boss_MadamBarbarRotationFramesD
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorC+1
                dc.l    Boss_MadamBarbarRotationFramesD
                dc.l    Boss_MadamBarbarRotationFramesD
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorC+1
                dc.l    Boss_MadamBarbarRotationFramesD
                dc.l    Boss_MadamBarbarRotationFramesC+$18000000
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorC+1
                dc.l    Boss_MadamBarbarRotationFramesC+$18000000
                dc.l    Boss_MadamBarbarRotationFramesC+$18000000
                dc.l    Boss_MadamBarbarInlineSpriteDescriptorC+1
                dc.l    Boss_MadamBarbarRotationFramesC+$18000000
                dc.l    0
                dc.l    0
                dc.l    0
                dc.l    0
Boss_MadamBarbarPartRadii:  dc.w    $10, $C10, $121C    ; was: word_34EBC
                dc.w    $1C10, $C10, $121C
                dc.w    $1C06, $608, $606
                dc.w    $806, $608, $606
                dc.w    $80D, $D0D, $D00
Boss_MadamBarbarPartLinks:  dc.w    $8000, $8007, $8066  ; was: word_34EDA
                dc.w    $80C5, $8124, $184
                dc.w    $184, $8007, $82A6
                dc.w    $8305, $8364, $3C4
                dc.w    $3C4, 7, $4E6
                dc.w    $546, 7, $606
                dc.w    $666, 7, $726
                dc.w    $786, 7, $846
                dc.w    $8A6, $540, $660
                dc.w    $780, $8A0
Boss_MadamBarbarNeutralPose:    dc.w    $8080, $80, $80  ; was: word_34F14
                dc.w    $80, $8080, $8080
; Flying Neo directional frames and metasprite definition
Boss_FlyingNeoRotationFrames:   dc.l    Boss_FlyingNeoRotationMapping0  ; was: off_34F20
                                        ; ROM:00034F52   o
                dc.l    Boss_FlyingNeoRotationMapping1
                dc.l    Boss_FlyingNeoRotationMapping2
                dc.l    Boss_FlyingNeoRotationMapping3
                dc.l    Boss_FlyingNeoRotationMapping4
                dc.l    Boss_FlyingNeoRotationMapping5
                dc.l    Boss_FlyingNeoRotationMapping6
                dc.l    Boss_FlyingNeoRotationMapping7
Boss_FlyingNeoInlineSpriteDescriptor:   dc.w    $6380, $600, $F8F4  ; was: word_34F40
                                        ; ROM:00034F5E   o
Boss_FlyingNeoMetaspriteDescriptors:    dc.l    0       ; was: dword_34F46
                dc.l    Boss_FlyingNeoRotationFrames+$18000000
                dc.l    Boss_FlyingNeoInlineSpriteDescriptor+1
                dc.l    Boss_FlyingNeoRotationFrames+$18000000
                dc.l    Boss_FlyingNeoAnchorPartMappingB+$8400000
                dc.l    Boss_FlyingNeoRotationFrames+$18000000
                dc.l    Boss_FlyingNeoInlineSpriteDescriptor+1
                dc.l    Boss_FlyingNeoRotationFrames+$18000000
                dc.l    Boss_FlyingNeoAnchorPartMappingB+$8400000
Boss_FlyingNeoPartRadii:    dc.w    8, $1810, $1F08     ; was: word_34F6A
                dc.w    $1810, $1F00
Boss_FlyingNeoPartLinks:    dc.w    0, $8065, $C064     ; was: word_34F74
                dc.w    $8124, $8123, $806B
                dc.w    $C06A, $82AA, $82A9
Boss_FlyingNeoNeutralPose:  dc.w    $A0A0, $A0A0        ; was: word_34F86
; Joker directional frames and metasprite definition
Boss_JokerRotationFramesA:  dc.l    Boss_JokerRotationMappingA0  ; was: off_34F8A
                                        ; ROM:00035086   o
                dc.l    Boss_JokerRotationMappingA1
                dc.l    Boss_JokerRotationMappingA2
                dc.l    Boss_JokerRotationMappingA3
                dc.l    Boss_JokerRotationMappingA4
                dc.l    Boss_JokerRotationMappingA5
                dc.l    Boss_JokerRotationMappingA6
                dc.l    Boss_JokerRotationMappingA7
Boss_JokerRotationFramesB:  dc.l    Boss_JokerRotationMappingA7  ; was: off_34FAA
                                        ; ROM:00035062   o
                dc.l    Boss_JokerRotationMappingA6
                dc.l    Boss_JokerRotationMappingA5
                dc.l    Boss_JokerRotationMappingA4
                dc.l    Boss_JokerRotationMappingA3
                dc.l    Boss_JokerRotationMappingA2
                dc.l    Boss_JokerRotationMappingA1
                dc.l    Boss_JokerRotationMappingA0
Boss_JokerRotationFramesC:  dc.l    Boss_JokerRotationMappingC0  ; was: off_34FCA
                                        ; ROM:00035096   o
                dc.l    Boss_JokerRotationMappingC1
                dc.l    Boss_JokerRotationMappingC2
                dc.l    Boss_JokerRotationMappingC3
                dc.l    Boss_JokerRotationMappingC4
                dc.l    Boss_JokerRotationMappingC5
                dc.l    Boss_JokerRotationMappingC6
                dc.l    Boss_JokerRotationMappingC7
Boss_JokerRotationFramesD:  dc.l    Boss_JokerRotationMappingC7  ; was: off_34FEA
                                        ; ROM:00035072   o
                dc.l    Boss_JokerRotationMappingC6
                dc.l    Boss_JokerRotationMappingC5
                dc.l    Boss_JokerRotationMappingC4
                dc.l    Boss_JokerRotationMappingC3
                dc.l    Boss_JokerRotationMappingC2
                dc.l    Boss_JokerRotationMappingC1
                dc.l    Boss_JokerRotationMappingC0
Boss_JokerRotationFramesE:  dc.l    Boss_JokerRotationMappingE0  ; was: off_3500A
                dc.l    Boss_JokerRotationMappingE1
                dc.l    Boss_JokerRotationMappingE2
                dc.l    Boss_JokerRotationMappingE3
                dc.l    Boss_JokerRotationMappingE4
                dc.l    Boss_JokerRotationMappingE5
                dc.l    Boss_JokerRotationMappingE6
                dc.l    Boss_JokerRotationMappingE7
Boss_JokerRotationFramesF:  dc.l    Boss_JokerRotationMappingE7  ; was: off_3502A
                dc.l    Boss_JokerRotationMappingE6
                dc.l    Boss_JokerRotationMappingE5
                dc.l    Boss_JokerRotationMappingE4
                dc.l    Boss_JokerRotationMappingE3
                dc.l    Boss_JokerRotationMappingE2
                dc.l    Boss_JokerRotationMappingE1
                dc.l    Boss_JokerRotationMappingE0
; Tagged inline child records: three words copied to fields $E, $8, and $A
Boss_JokerInlineSpriteDescriptorA:  dc.w    $636E, $500, $F8F8  ; was: word_3504A
                                        ; ROM:00035092   o
Boss_JokerInlineSpriteDescriptorB:  dc.w    $6366, $500, $F8F8  ; was: word_35050
                                        ; ROM:0003508A   o
Boss_JokerMetaspriteDescriptors:    dc.l    0           ; was: dword_35056
                dc.l    Boss_JokerRotationFramesB
                dc.l    0
                dc.l    Boss_JokerRotationFramesB
                dc.l    Boss_JokerInlineSpriteDescriptorB+1
                dc.l    Boss_JokerRotationFramesD
                dc.l    Boss_JokerInlineSpriteDescriptorA+1
                dc.l    Boss_JokerRotationFramesD
                dc.l    0
                dc.l    Boss_JokerRotationFramesF
                dc.l    Boss_JokerRotationFramesA+$18000000
                dc.l    0
                dc.l    Boss_JokerRotationFramesA+$18000000
                dc.l    Boss_JokerInlineSpriteDescriptorB+1+$8000000
                dc.l    Boss_JokerRotationFramesC+$18000000
                dc.l    Boss_JokerInlineSpriteDescriptorA+1+$8000000
                dc.l    Boss_JokerRotationFramesC+$18000000
                dc.l    0
                dc.l    Boss_JokerRotationFramesE+$18000000
Boss_JokerPartRadii:    dc.w    $84, $8888, $928C       ; was: word_350A2
                dc.w    $9990, $9B81, $8488
                dc.w    $8892, $8C99, $909B
                dc.w    $8100
Boss_JokerPartLinks:    dc.w    0, $728, $720           ; was: word_350B6
                dc.w    $C7, $C6, $788
                dc.w    $787, $248, $240
                dc.w    $309, $7E8, $7E0
                dc.w    $427, $426, $848
                dc.w    $847, $5A8, $5A0
                dc.w    $669
Boss_JokerNeutralPose:  dc.w    $80, $8080, $E080       ; was: word_350DC
                dc.w    $A0A0, $8060
; Back Stringer directional frames and dual-position segment-chain definition
Boss_BackStringerRotationFramesA:   dc.l    Boss_BackStringerRotationMappingA0  ; was: off_350E6
                                        ; ROM:00035198   o
                dc.l    Boss_BackStringerRotationMappingA1
                dc.l    Boss_BackStringerRotationMappingA2
                dc.l    Boss_BackStringerRotationMappingA3
                dc.l    Boss_BackStringerRotationMappingA4
                dc.l    Boss_BackStringerRotationMappingA5
                dc.l    Boss_BackStringerRotationMappingA6
                dc.l    Boss_BackStringerRotationMappingA7
Boss_BackStringerRotationFramesB:   dc.l    Boss_BackStringerRotationMappingA7  ; was: off_35106
                                        ; ROM:000351A4   o
                dc.l    Boss_BackStringerRotationMappingA6
                dc.l    Boss_BackStringerRotationMappingA5
                dc.l    Boss_BackStringerRotationMappingA4
                dc.l    Boss_BackStringerRotationMappingA3
                dc.l    Boss_BackStringerRotationMappingA2
                dc.l    Boss_BackStringerRotationMappingA1
                dc.l    Boss_BackStringerRotationMappingA0
Boss_BackStringerRotationFramesC:   dc.l    Boss_BackStringerRotationMappingC0  ; was: off_35126
                                        ; ROM:0003517C   o
                dc.l    Boss_BackStringerRotationMappingC1
                dc.l    Boss_BackStringerRotationMappingC2
                dc.l    Boss_BackStringerRotationMappingC3
                dc.l    Boss_BackStringerRotationMappingC4
                dc.l    Boss_BackStringerRotationMappingC5
                dc.l    Boss_BackStringerRotationMappingC6
                dc.l    Boss_BackStringerRotationMappingC7
Boss_BackStringerRotationFramesD:   dc.l    Boss_BackStringerRotationMappingC7  ; was: off_35146
                                        ; ROM:00035188   o
                dc.l    Boss_BackStringerRotationMappingC6
                dc.l    Boss_BackStringerRotationMappingC5
                dc.l    Boss_BackStringerRotationMappingC4
                dc.l    Boss_BackStringerRotationMappingC3
                dc.l    Boss_BackStringerRotationMappingC2
                dc.l    Boss_BackStringerRotationMappingC1
                dc.l    Boss_BackStringerRotationMappingC0
Boss_BackStringerInlineSpriteDescriptor:    dc.w    $63DE, $A00, $F4F4  ; was: word_35166
Boss_BackStringerMetaspriteDescriptors:     dc.l    Boss_BackStringerInlineSpriteDescriptor+1  ; was: off_3516C
                dc.l    0
                dc.l    0
                dc.l    Boss_BackStringerRotationFramesC+$18000000
                dc.l    Boss_BackStringerRotationFramesC+$18000000
                dc.l    Boss_BackStringerRotationFramesA+$18000000
                dc.l    Boss_BackStringerRotationFramesD
                dc.l    Boss_BackStringerRotationFramesD
                dc.l    Boss_BackStringerRotationFramesB
                dc.l    Boss_BackStringerRotationFramesC+$18000000
                dc.l    Boss_BackStringerRotationFramesC+$18000000
                dc.l    Boss_BackStringerRotationFramesA+$18000000
                dc.l    Boss_BackStringerRotationFramesD
                dc.l    Boss_BackStringerRotationFramesD
                dc.l    Boss_BackStringerRotationFramesB
                dc.l    Boss_BackStringerRotationFramesC+$18000000
                dc.l    Boss_BackStringerRotationFramesC+$18000000
                dc.l    Boss_BackStringerRotationFramesA+$18000000
                dc.l    Boss_BackStringerRotationFramesD
                dc.l    Boss_BackStringerRotationFramesD
                dc.l    Boss_BackStringerRotationFramesB
Boss_BackStringerPartRadii: dc.w    $98, $9F96, $8E8C   ; was: word_351C0
                dc.w    $968E, $8C92, $8A8C
                dc.w    $928A, $8C96, $8E8C
                dc.w    $968E, $8C00
Boss_BackStringerPartLinks: dc.w    5, 4, 4             ; was: word_351D6
                dc.w    6, $126, $186
                dc.w    6, $246, $2A6
                dc.w    6, $366, $3C6
                dc.w    6, $486, $4E6
                dc.w    6, $5A6, $606
                dc.w    6, $6C6, $726
Boss_BackStringerNeutralPose:   dc.w    $40C0, $80, $8080  ; was: word_35200
                dc.w    $8080, $80, $8080
                dc.w    $8080, $80, $8080
                dc.w    $8080
; Sharpsteel metasprite definition and neutral pose
; Tagged inline child records: three words copied to fields $E, $8, and $A
Boss_SharpsteelInlineSpriteDescriptorA: dc.w    $63F9, $A00, $F4F4  ; was: word_35214
                                        ; ROM:0003523C   o
Boss_SharpsteelInlineSpriteDescriptorB: dc.w    $6402, $500, $F8F8  ; was: word_3521A
                                        ; ROM:00035250   o
Boss_SharpsteelMetaspriteDescriptors:   dc.l    Boss_SharpsteelBladeGraphicsAMapping0+$400000  ; was: off_35220
                dc.l    Boss_SharpsteelBladeGraphicsAMapping1+$400000
                dc.l    Boss_SharpsteelBladeGraphicsAMapping2+$400000
                dc.l    Boss_SharpsteelBladeGraphicsAMapping3+$400000
                dc.l    Boss_SharpsteelBladeGraphicsAMapping4+$400000
                dc.l    Boss_SharpsteelBladeGraphicsAMapping5+$400000
                dc.l    Boss_SharpsteelInlineSpriteDescriptorA+1
                dc.l    Boss_SharpsteelInlineSpriteDescriptorA+1
                dc.l    Boss_SharpsteelInlineSpriteDescriptorB+1
                dc.l    Boss_SharpsteelCoreDirectionalMapping0+$400000
                dc.l    Boss_SharpsteelInlineSpriteDescriptorA+1
                dc.l    Boss_SharpsteelInlineSpriteDescriptorA+1
                dc.l    Boss_SharpsteelInlineSpriteDescriptorB+1
                dc.l    Boss_SharpsteelCoreDirectionalMapping0+$400000
                dc.l    0
                dc.l    0
                dc.l    0
                dc.l    0
Boss_SharpsteelPartRadii:   dc.w    $809C, $A098, $9894  ; was: word_35268
                dc.w    $9C90, $8E92, $9C90
                dc.w    $8E92, $A0A0, $C0C0
Boss_SharpsteelPartLinks:   dc.w    $8007, $8006, $8065  ; was: word_3527A
                dc.w    $8007, $8127, $8187
                dc.w    $8066, $246, $2A6
                dc.w    $8304, $8066, $3C6
                dc.w    $426, $8484, $360
                dc.w    $4E0, $360, $4E0
Boss_SharpsteelNeutralPose: dc.w    $8080, $8080, $8080, $8080  ; was: word_3529E
