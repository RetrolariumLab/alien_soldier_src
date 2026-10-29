; Metasprite definitions for Antroid, Terobuster, Shellshogun, and Xi-Tiger
; Antroid directional frames, child descriptors, radii, links, and neutral pose
Boss_AntroidPrimaryRotationFrames:  dc.l    Boss_AntroidPrimaryRotationFrame07  ; was: off_3494C
                                        ; ROM:000349D2   o
                dc.l    Boss_AntroidPrimaryRotationFrame06
                dc.l    Boss_AntroidPrimaryRotationFrame05
                dc.l    Boss_AntroidPrimaryRotationFrame04
                dc.l    Boss_AntroidPrimaryRotationFrame03
                dc.l    Boss_AntroidPrimaryRotationFrame02
                dc.l    Boss_AntroidPrimaryRotationFrame01
                dc.l    Boss_AntroidPrimaryRotationFrame00
Boss_AntroidSecondaryRotationFrames:    dc.l    Boss_AntroidSecondaryRotationFrame00  ; was: off_3496C
                                        ; ROM:000349EE   o
                dc.l    Boss_AntroidSecondaryRotationFrame01
                dc.l    Boss_AntroidSecondaryRotationFrame02
                dc.l    Boss_AntroidSecondaryRotationFrame03
                dc.l    Boss_AntroidSecondaryRotationFrame04
                dc.l    Boss_AntroidSecondaryRotationFrame05
                dc.l    Boss_AntroidSecondaryRotationFrame06
                dc.l    Boss_AntroidSecondaryRotationFrame07
; Tagged inline child records: three words copied to fields $E, $8, and $A
Boss_AntroidInlineSpriteDescriptorA:        dc.w    $305, $F00, $F0F0  ; was: word_3498C
Boss_AntroidInlineSpriteDescriptorB:        dc.w    $325, $A00, $F4F4  ; was: word_34992
Boss_AntroidInlineSpriteDescriptorC:        dc.w    $315, $F00, $F0F0  ; was: word_34998
Boss_AntroidInlineSpriteDescriptorD:        dc.w    $337, $A00, $F4F4  ; was: word_3499E
Boss_AntroidInlineSpriteDescriptorE:        dc.w    $32E, $A00, $F4F4  ; was: word_349A4
Boss_AntroidInlineSpriteDescriptorF:        dc.w    $300, $500, $F8F8  ; was: word_349AA
Boss_AntroidInlineSpriteDescriptorG:        dc.w    $304, 0, $FCFC  ; was: word_349B0
Boss_AntroidPrimaryMetaspriteDescriptors:   dc.l    Boss_AntroidInlineSpriteDescriptorB+1  ; was: off_349B6
                dc.l    Boss_AntroidInlineSpriteDescriptorA+1
                dc.l    Boss_AntroidBlinkDefaultMapping+$400000
                dc.l    Boss_AntroidInlineSpriteDescriptorC+1
Boss_AntroidSecondaryMetaspriteDescriptors: dc.l    Boss_AntroidInlineSpriteDescriptorD+1  ; was: off_349C6
                dc.l    Boss_AntroidPrimaryRotationFrames
                dc.l    Boss_AntroidInlineSpriteDescriptorF+1
                dc.l    Boss_AntroidPrimaryRotationFrames
                dc.l    Boss_AntroidSecondaryRotationFrames+$8000000
                dc.l    0
                dc.l    Boss_AntroidPrimaryRotationFrames
                dc.l    Boss_AntroidInlineSpriteDescriptorE+1
                dc.l    Boss_AntroidPrimaryRotationFrames
                dc.l    Boss_AntroidInlineSpriteDescriptorG+1
                dc.l    Boss_AntroidSecondaryRotationFrames-$18000000
Boss_AntroidPrimaryPartRadii:   dc.b    $00, $12, $14, $13  ; was: off_349F2
Boss_AntroidSecondaryPartRadii: dc.w    $80C, $D0C, $1A06  ; was: word_349F6
                dc.w    $101E, $1222, $600
Boss_AntroidPrimaryPartLinks:   dc.w    $C009, $C008, $4067  ; was: word_34A02
                dc.w    $C009, $C064, $4185
                dc.w    $C1E4, $4245, $4244
                dc.w    $120, $4366, $C365
                dc.w    $4425, $C426, $44E5
Boss_AntroidSecondaryPartLinks: dc.w    $C069, $45AA, $C609  ; was: word_34A20
                dc.w    $466A, $4669, $120
                dc.w    $478A, $C789, $4849
                dc.w    $C84A, $4909
Boss_AntroidNeutralPose:    dc.w    $8080, $C080, $E090  ; was: word_34A36
                dc.w    $80E0, $9080, $8080
                dc.w    $8080, $8000
; Terobuster directional frames and metasprite definition
Boss_TerobusterPrimaryRotationFrames:   dc.l    Boss_TerobusterPrimaryRotationFrame07  ; was: off_34A46
                                        ; ROM:00034A98   o
                dc.l    Boss_TerobusterPrimaryRotationFrame06
                dc.l    Boss_TerobusterPrimaryRotationFrame05
                dc.l    Boss_TerobusterPrimaryRotationFrame04
                dc.l    Boss_TerobusterPrimaryRotationFrame03
                dc.l    Boss_TerobusterPrimaryRotationFrame02
                dc.l    Boss_TerobusterPrimaryRotationFrame01
                dc.l    Boss_TerobusterPrimaryRotationFrame00
Boss_TerobusterSecondaryRotationFrames: dc.l    Boss_TerobusterSecondaryRotationFrame00  ; was: off_34A66
                                        ; ROM:00034AB4   o
                dc.l    Boss_TerobusterSecondaryRotationFrame01
                dc.l    Boss_TerobusterSecondaryRotationFrame02
                dc.l    Boss_TerobusterSecondaryRotationFrame03
                dc.l    Boss_TerobusterSecondaryRotationFrame04
                dc.l    Boss_TerobusterSecondaryRotationFrame05
                dc.l    Boss_TerobusterSecondaryRotationFrame06
                dc.l    Boss_TerobusterSecondaryRotationFrame07
Boss_TerobusterInlineSpriteDescriptor:  dc.w    $E35E, $F00, $F0F0  ; was: word_34A86
                                        ; ROM:00034AA8   o
Boss_TerobusterMetaspriteDescriptors:   dc.l    0       ; was: dword_34A8C
                dc.l    Boss_TerobusterPrimaryRotationFrames
                dc.l    Boss_TerobusterInlineSpriteDescriptor+1
                dc.l    Boss_TerobusterPrimaryRotationFrames
                dc.l    0
                dc.l    Boss_TerobusterSecondaryRotationFrames-$30000000
                dc.l    Boss_TerobusterPrimaryRotationFrames
                dc.l    Boss_TerobusterInlineSpriteDescriptor+1
                dc.l    Boss_TerobusterPrimaryRotationFrames
                dc.l    0
                dc.l    Boss_TerobusterSecondaryRotationFrames-$30000000
Boss_TerobusterPartRadii:   dc.w    $90, $A898, $A484   ; was: word_34AB8
                dc.w    $1028, $1824, $400
Boss_TerobusterPartLinks:   dc.w    5, 3, 1             ; was: word_34AC4
                dc.w    $C3, $C0, $182
                dc.w    7, 5, $2A7
                dc.w    $2A0, $366
Boss_TerobusterNeutralPose: dc.w    $A080, $80A0, $8080  ; was: word_34ADA
; Shellshogun directional frames and metasprite definition
Boss_ShellshogunRotationFramesA:    dc.l    Boss_ShellshogunSpriteMapping26  ; was: off_34AE0
                                        ; ROM:00034BEC   o
                dc.l    Boss_ShellshogunSpriteMapping25
                dc.l    Boss_ShellshogunSpriteMapping24
                dc.l    Boss_ShellshogunSpriteMapping23
                dc.l    Boss_ShellshogunSpriteMapping22
                dc.l    Boss_ShellshogunSpriteMapping21
                dc.l    Boss_ShellshogunSpriteMapping20
                dc.l    Boss_ShellshogunSpriteMapping19
Boss_ShellshogunRotationFramesB:    dc.l    Boss_ShellshogunSpriteMapping10  ; was: off_34B00
                dc.l    Boss_ShellshogunSpriteMapping09
                dc.l    Boss_ShellshogunSpriteMapping08
                dc.l    Boss_ShellshogunSpriteMapping07
                dc.l    Boss_ShellshogunSpriteMapping06
                dc.l    Boss_ShellshogunSpriteMapping05
                dc.l    Boss_ShellshogunSpriteMapping04
                dc.l    Boss_ShellshogunSpriteMapping03
Boss_ShellshogunRotationFramesC:    dc.l    Boss_ShellshogunSpriteMapping18  ; was: off_34B20
                dc.l    Boss_ShellshogunSpriteMapping17
                dc.l    Boss_ShellshogunSpriteMapping16
                dc.l    Boss_ShellshogunSpriteMapping15
                dc.l    Boss_ShellshogunSpriteMapping14
                dc.l    Boss_ShellshogunSpriteMapping13
                dc.l    Boss_ShellshogunSpriteMapping12
                dc.l    Boss_ShellshogunSpriteMapping11
Boss_ShellshogunRotationFramesD:    dc.l    Boss_ShellshogunSpriteMapping19  ; was: off_34B40
                                        ; ROM:00034BC0   o
                dc.l    Boss_ShellshogunSpriteMapping20
                dc.l    Boss_ShellshogunSpriteMapping21
                dc.l    Boss_ShellshogunSpriteMapping22
                dc.l    Boss_ShellshogunSpriteMapping23
                dc.l    Boss_ShellshogunSpriteMapping24
                dc.l    Boss_ShellshogunSpriteMapping25
                dc.l    Boss_ShellshogunSpriteMapping26
Boss_ShellshogunRotationFramesE:    dc.l    Boss_ShellshogunSpriteMapping03  ; was: off_34B60
                dc.l    Boss_ShellshogunSpriteMapping04
                dc.l    Boss_ShellshogunSpriteMapping05
                dc.l    Boss_ShellshogunSpriteMapping06
                dc.l    Boss_ShellshogunSpriteMapping07
                dc.l    Boss_ShellshogunSpriteMapping08
                dc.l    Boss_ShellshogunSpriteMapping09
                dc.l    Boss_ShellshogunSpriteMapping10
Boss_ShellshogunRotationFramesF:    dc.l    Boss_ShellshogunSpriteMapping11  ; was: off_34B80
                                        ; sub_39EE4   o
                dc.l    Boss_ShellshogunSpriteMapping12
                dc.l    Boss_ShellshogunSpriteMapping13
                dc.l    Boss_ShellshogunSpriteMapping14
                dc.l    Boss_ShellshogunSpriteMapping15
                dc.l    Boss_ShellshogunSpriteMapping16
                dc.l    Boss_ShellshogunSpriteMapping17
                dc.l    Boss_ShellshogunSpriteMapping18
; Tagged inline child records: three words copied to fields $E, $8, and $A
Boss_ShellshogunInlineSpriteDescriptorA:    dc.w    $6457, $A00, $F4F4  ; was: word_34BA0
                                        ; ROM:00034BFC   o
Boss_ShellshogunInlineSpriteDescriptorB:    dc.w    $6460, $500, $F8F8  ; was: word_34BA6
                                        ; ROM:00034BD8   o
Boss_ShellshogunMetaspriteDescriptors:  dc.l    0       ; was: dword_34BAC
                dc.l    Boss_ShellshogunSpriteMapping00+$400000
                dc.l    Boss_ShellshogunSpriteMapping02+$400000
                dc.l    Boss_ShellshogunRotationFramesD+$48000000
                dc.l    Boss_ShellshogunInlineSpriteDescriptorB+1
                dc.l    Boss_ShellshogunRotationFramesD+$48000000
                dc.l    Boss_ShellshogunRotationFramesF+$48000000
                dc.l    0
                dc.l    Boss_ShellshogunRotationFramesD+$48000000
                dc.l    Boss_ShellshogunInlineSpriteDescriptorA+1
                dc.l    Boss_ShellshogunRotationFramesD+$48000000
                dc.l    Boss_ShellshogunInlineSpriteDescriptorB+1
                dc.l    Boss_ShellshogunRotationFramesE+$48000000
                dc.l    Boss_ShellshogunSpriteMapping02+$400000
                dc.l    Boss_ShellshogunRotationFramesA-$30000000
                dc.l    Boss_ShellshogunInlineSpriteDescriptorB+1
                dc.l    Boss_ShellshogunRotationFramesA-$30000000
                dc.l    Boss_ShellshogunRotationFramesC-$30000000
                dc.l    0
                dc.l    Boss_ShellshogunRotationFramesA-$30000000
                dc.l    Boss_ShellshogunInlineSpriteDescriptorA+1
                dc.l    Boss_ShellshogunRotationFramesA-$30000000
                dc.l    Boss_ShellshogunInlineSpriteDescriptorB+1
                dc.l    Boss_ShellshogunRotationFramesB-$30000000
Boss_ShellshogunPartRadii:  dc.w    $22, $260C, $1A0C   ; was: word_34C0C
                dc.w    $1C18, $101E, $101C
                dc.w    $826, $C1A, $C1C
                dc.w    $1810, $1E10, $1C08
Boss_ShellshogunPartLinks:  dc.w    4, 4, 4             ; was: word_34C24
                dc.w    $C7, $C6, $185
                dc.w    $183, 4, $2AB
                dc.w    $2AA, $36A, $36B
                dc.w    $42B, 7, $4EA
                dc.w    $4E9, $5A8, $5A3
                dc.w    4, $6CD, $6CC
                dc.w    $78C, $78D, $84D
Boss_ShellshogunNeutralPose:    dc.w    $40, $6070, $40E0  ; was: word_34C54
                dc.w    $8000, $4000, $7080
                dc.w    $E080, $A000
; Xi-Tiger directional frames and metasprite definition
Boss_XiTigerRotationFramesA:    dc.l    Boss_XiTigerRotationSetAFrame00  ; was: off_34C64
                                        ; ROM:00034D1E   o
                dc.l    Boss_XiTigerRotationSetAFrame01
                dc.l    Boss_XiTigerRotationSetAFrame02
                dc.l    Boss_XiTigerRotationSetAFrame03
                dc.l    Boss_XiTigerRotationSetAFrame04
                dc.l    Boss_XiTigerRotationSetAFrame05
                dc.l    Boss_XiTigerRotationSetAFrame06
                dc.l    Boss_XiTigerRotationSetAFrame07
Boss_XiTigerRotationFramesB:    dc.l    Boss_XiTigerRotationSetBFrame00  ; was: off_34C84
                dc.l    Boss_XiTigerRotationSetBFrame01
                dc.l    Boss_XiTigerRotationSetBFrame02
                dc.l    Boss_XiTigerRotationSetBFrame03
                dc.l    Boss_XiTigerRotationSetBFrame04
                dc.l    Boss_XiTigerRotationSetBFrame05
                dc.l    Boss_XiTigerRotationSetBFrame06
                dc.l    Boss_XiTigerRotationSetBFrame07
Boss_XiTigerRotationFramesC:    dc.l    Boss_XiTigerRotationSetAFrame07  ; was: off_34CA4
                                        ; ROM:00034D0A   o
                dc.l    Boss_XiTigerRotationSetAFrame06
                dc.l    Boss_XiTigerRotationSetAFrame05
                dc.l    Boss_XiTigerRotationSetAFrame04
                dc.l    Boss_XiTigerRotationSetAFrame03
                dc.l    Boss_XiTigerRotationSetAFrame02
                dc.l    Boss_XiTigerRotationSetAFrame01
                dc.l    Boss_XiTigerRotationSetAFrame00
Boss_XiTigerRotationFramesD:    dc.l    Boss_XiTigerRotationSetBFrame07  ; was: off_34CC4
                dc.l    Boss_XiTigerRotationSetBFrame06
                dc.l    Boss_XiTigerRotationSetBFrame05
                dc.l    Boss_XiTigerRotationSetBFrame04
                dc.l    Boss_XiTigerRotationSetBFrame03
                dc.l    Boss_XiTigerRotationSetBFrame02
                dc.l    Boss_XiTigerRotationSetBFrame01
                dc.l    Boss_XiTigerRotationSetBFrame00
; Tagged inline child records: three words copied to fields $E, $8, and $A
Boss_XiTigerInlineSpriteDescriptorA:    dc.w    $62D4, $500, $F8F8  ; was: word_34CE4
                                        ; ROM:00034D52   o
Boss_XiTigerInlineSpriteDescriptorB:    dc.w    $62D8, $A00, $F4F4  ; was: word_34CEA
                                        ; ROM:00034D1A   o
Boss_XiTigerInlineSpriteDescriptorC:    dc.w    $62E1, $A00, $F4F4  ; was: word_34CF0
                                        ; ROM:00034D4A   o
Boss_XiTigerMetaspriteDescriptors:  dc.l    0           ; was: dword_34CF6
                dc.l    Boss_XiTigerGroundedBodyMapping+$400000
                dc.l    Boss_XiTigerDirectDescriptorFrame00+$400000
                dc.l    Boss_XiTigerRotationFramesC
                dc.l    Boss_XiTigerInlineSpriteDescriptorB+1
                dc.l    Boss_XiTigerRotationFramesC
                dc.l    0
                dc.l    Boss_XiTigerDirectDescriptorFrame00-$7C00000
                dc.l    Boss_XiTigerRotationFramesA+$18000000
                dc.l    Boss_XiTigerInlineSpriteDescriptorB+1-$8000000
                dc.l    Boss_XiTigerRotationFramesA+$18000000
                dc.l    0
                dc.l    Boss_XiTigerDirectDescriptorFrame01+$400000
                dc.l    0
                dc.l    Boss_XiTigerRotationFramesA+$18000000
                dc.l    Boss_XiTigerInlineSpriteDescriptorC+1
                dc.l    Boss_XiTigerRotationFramesC
                dc.l    Boss_XiTigerInlineSpriteDescriptorA+1
                dc.l    Boss_XiTigerRotationFramesB+$18000000
                dc.l    0
                dc.l    Boss_XiTigerRotationFramesA+$18000000
                dc.l    Boss_XiTigerInlineSpriteDescriptorC+1+$8000000
                dc.l    Boss_XiTigerRotationFramesA+$8000000
                dc.l    Boss_XiTigerInlineSpriteDescriptorA+1+$8000000
                dc.l    Boss_XiTigerRotationFramesD
Boss_XiTigerPartRadii:  dc.w    $E, $2E14, $2410        ; was: word_34D5A
                dc.w    $222C, $1424, $1022
                dc.w    $3214, $A1C, $E1C
                dc.w    $714, $A1C, $E1C
                dc.w    $700
Boss_XiTigerPartLinks:  dc.w    $8000, $8005, $8005     ; was: word_34D74
                dc.w    $80C5, $80C5, $8184
                dc.w    $8180, $8005, $82A5
                dc.w    $82A5, $8364, $8360
                dc.w    $8009, $8488, $84E7
                dc.w    $84E6, $85A7, $85A7
                dc.w    $8667, $8488, $8727
                dc.w    $8726, $87E7, $87E7
                dc.w    $88A7
Boss_XiTigerNeutralPose:    dc.w    $2060, $70C0, $80A0  ; was: word_34DA6
                dc.w    $9080, $4000, $8000
                dc.w    $E040, $4080
