; Alternate an object's graphics word on successive global frames
Object_SelectAlternatingGraphicsFrame:                  ; was: sub_59D2C
                move.w  #$C4D6,$E(a5)
                btst    #0,(FrameCounter+1).w
                beq.s   Object_SelectAlternatingGraphicsFrameReturn
                move.w  #$C4DF,$E(a5)
Object_SelectAlternatingGraphicsFrameReturn:            ; CODE XREF: Object_SelectAlternatingGraphicsFrame+C   j  ; was: locret_59D40
                rts
; End of function Object_SelectAlternatingGraphicsFrame
; ---------------------------------------------------------------------------
; Nine labelled eight-direction frame-table bases used by Seven Force parts
; Table1 has an extra unlabelled eight-pointer run after its first eight slots
SevenForceRotationFrameTable0:  dc.l    SevenForceRotationSpriteFrame00  ; DATA XREF: ROM:00059EB8   o  ; was: off_59D42
                                        ; ROM:00059EE4   o
                dc.l    SevenForceRotationSpriteFrame01
                dc.l    SevenForceRotationSpriteFrame02
                dc.l    SevenForceRotationSpriteFrame03
                dc.l    SevenForceRotationSpriteFrame04
                dc.l    SevenForceRotationSpriteFrame05
                dc.l    SevenForceRotationSpriteFrame06
                dc.l    SevenForceRotationSpriteFrame07
SevenForceRotationFrameTable1:  dc.l    SevenForceRotationSpriteFrame07  ; DATA XREF: ROM:00059EA4   o  ; was: off_59D62
                                        ; ROM:00059ECC   o
                dc.l    SevenForceRotationSpriteFrame06
                dc.l    SevenForceRotationSpriteFrame05
                dc.l    SevenForceRotationSpriteFrame04
                dc.l    SevenForceRotationSpriteFrame03
                dc.l    SevenForceRotationSpriteFrame02
                dc.l    SevenForceRotationSpriteFrame01
                dc.l    SevenForceRotationSpriteFrame00
; The masked eight-slot index from Table1 cannot select this following run
                dc.l    SevenForceRotationSpriteFrame08
                dc.l    SevenForceRotationSpriteFrame09
                dc.l    SevenForceRotationSpriteFrame10
                dc.l    SevenForceRotationSpriteFrame11
                dc.l    SevenForceRotationSpriteFrame12
                dc.l    SevenForceRotationSpriteFrame13
                dc.l    SevenForceRotationSpriteFrame14
                dc.l    SevenForceRotationSpriteFrame15
SevenForceRotationFrameTable2:  dc.l    SevenForceRotationSpriteFrame15  ; DATA XREF: ROM:00059EA0   o  ; was: off_59DA2
                                        ; ROM:0005A034   o
                dc.l    SevenForceRotationSpriteFrame14
                dc.l    SevenForceRotationSpriteFrame13
                dc.l    SevenForceRotationSpriteFrame12
                dc.l    SevenForceRotationSpriteFrame11
                dc.l    SevenForceRotationSpriteFrame10
                dc.l    SevenForceRotationSpriteFrame09
                dc.l    SevenForceRotationSpriteFrame08
SevenForceRotationFrameTable3:  dc.l    SevenForceRotationSpriteFrame16  ; DATA XREF: ROM:00059EF4   o  ; was: off_59DC2
                                        ; ROM:00059F6E   o
                dc.l    SevenForceRotationSpriteFrame17
                dc.l    SevenForceRotationSpriteFrame18
                dc.l    SevenForceRotationSpriteFrame19
                dc.l    SevenForceRotationSpriteFrame20
                dc.l    SevenForceRotationSpriteFrame21
                dc.l    SevenForceRotationSpriteFrame22
                dc.l    SevenForceRotationSpriteFrame23
SevenForceRotationFrameTable4:  dc.l    SevenForceRotationSpriteFrame23  ; DATA XREF: ROM:00059EDC   o  ; was: off_59DE2
                                        ; ROM:00059F66   o
                dc.l    SevenForceRotationSpriteFrame22
                dc.l    SevenForceRotationSpriteFrame21
                dc.l    SevenForceRotationSpriteFrame20
                dc.l    SevenForceRotationSpriteFrame19
                dc.l    SevenForceRotationSpriteFrame18
                dc.l    SevenForceRotationSpriteFrame17
                dc.l    SevenForceRotationSpriteFrame16
SevenForceRotationFrameTable5:  dc.l    SevenForceRotationSpriteFrame24  ; DATA XREF: ROM:00059EC4   o  ; was: off_59E02
                                        ; ROM:00059EEC   o
                dc.l    SevenForceRotationSpriteFrame25
                dc.l    SevenForceRotationSpriteFrame26
                dc.l    SevenForceRotationSpriteFrame27
                dc.l    SevenForceRotationSpriteFrame28
                dc.l    SevenForceRotationSpriteFrame29
                dc.l    SevenForceRotationSpriteFrame30
                dc.l    SevenForceRotationSpriteFrame31
SevenForceRotationFrameTable6:  dc.l    SevenForceRotationSpriteFrame31  ; DATA XREF: ROM:00059EB0   o  ; was: off_59E22
                                        ; ROM:00059ED4   o
                dc.l    SevenForceRotationSpriteFrame30
                dc.l    SevenForceRotationSpriteFrame29
                dc.l    SevenForceRotationSpriteFrame28
                dc.l    SevenForceRotationSpriteFrame27
                dc.l    SevenForceRotationSpriteFrame26
                dc.l    SevenForceRotationSpriteFrame25
                dc.l    SevenForceRotationSpriteFrame24
SevenForceRotationFrameTable7:  dc.l    SevenForceRotationSpriteFrame32  ; DATA XREF: ROM:00059EB4   o  ; was: off_59E42
                dc.l    SevenForceRotationSpriteFrame33
                dc.l    SevenForceRotationSpriteFrame34
                dc.l    SevenForceRotationSpriteFrame35
                dc.l    SevenForceRotationSpriteFrame36
                dc.l    SevenForceRotationSpriteFrame37
                dc.l    SevenForceRotationSpriteFrame38
                dc.l    SevenForceRotationSpriteFrame39
SevenForceRotationFrameTable8:  dc.l    SevenForceRotationSpriteFrame39  ; DATA XREF: ROM:00059EC8   o  ; was: off_59E62
                dc.l    SevenForceRotationSpriteFrame38
                dc.l    SevenForceRotationSpriteFrame37
                dc.l    SevenForceRotationSpriteFrame36
                dc.l    SevenForceRotationSpriteFrame35
                dc.l    SevenForceRotationSpriteFrame34
                dc.l    SevenForceRotationSpriteFrame33
                dc.l    SevenForceRotationSpriteFrame32
; Low-bit-tagged inline descriptors: words copied to child $E, $8, and $A
SevenForceInlinePartDescriptor0:    dc.w    $42D, $F00, $F0F0  ; DATA XREF: ROM:00059E98   o  ; was: word_59E82
                                        ; ROM:0005A038   o
SevenForceInlinePartDescriptor1:    dc.w    $43D, $A00, $F4F4  ; DATA XREF: ROM:00059E9C   o  ; was: word_59E88
                                        ; ROM:Boss_ValkirieAuxiliaryMetaspritePartDescriptors   o
SevenForceInlinePartDescriptor2:    dc.w    $446, $500, $F8F8  ; DATA XREF: ROM:00059EAC   o  ; was: word_59E8E
                                        ; ROM:00059EC0   o
; Primary Valkirie metasprite initialization and neutral-pose data
Boss_ValkirieMetaspritePartDescriptors: dc.l    Boss_ValkirieMetaspriteFrame+$400000  ; DATA XREF: Entity_InitValkirieBattleState0+10   o  ; was: off_59E94
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable2-$40000000
                dc.l    SevenForceRotationFrameTable1
                dc.l    0
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable6
                dc.l    SevenForceRotationFrameTable7+$8000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    0
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceRotationFrameTable8
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable6
                dc.l    0
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    0
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
Boss_ValkirieMetaspriteInitialAngles:   dc.w    $12, $E15, $1F09  ; DATA XREF: Entity_InitValkirieBattleState0+16   o  ; was: word_59EFC
                dc.w    $1212, $251F, $912
                dc.w    $1225, $192C, $1426
                dc.w    $E04, $192C, $1426
                dc.w    $E04
Boss_ValkirieMetaspritePartLinks:   dc.w    $C004, $C004, $C064  ; was: word_59F16
                                        ; DATA XREF: Entity_InitValkirieBattleState0+1C   o
                dc.w    $C002, $C002, $C182
                dc.w    $C182, $C241, $C240
                dc.w    $C002, $C362, $C362
                dc.w    $C421, $C420, $C0C6
                dc.w    $C0C6, $C5A6, $C5A5
                dc.w    $C664, $C665, $C0C6
                dc.w    $C0C6, $C7E6, $C7E5
                dc.w    $C8A4, $C8A5
Boss_ValkirieMetaspritePoseAngles:  dc.w    $C080, $4000, $8080  ; was: word_59F4A
                                        ; DATA XREF: Entity_InitValkirieBattleState0+28   o
                dc.w    $8080, $80E0, $8080
                dc.w    $80A0, $8080, $8080
                dc.w    $8080
; Six-part auxiliary group created by Valkirie's movement initializer
Boss_ValkirieAuxiliaryMetaspritePartDescriptors:    dc.l    SevenForceInlinePartDescriptor1+1  ; DATA XREF: Entity_InitValkirieAuxiliaryGroup+1E   o  ; was: off_59F5E
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    0
Boss_ValkirieAuxiliaryMetaspriteInitialAngles:  dc.w    $14, $2C14, $2C18  ; DATA XREF: Entity_InitValkirieAuxiliaryGroup+24   o  ; was: word_59F76
Boss_ValkirieAuxiliaryMetaspritePartLinks:      dc.w    $C000, $C001, $C001  ; was: word_59F7C
                                        ; DATA XREF: Entity_InitValkirieAuxiliaryGroup+2A   o
                dc.w    $C001, $C001, 0
; Medusa metasprite initialization and neutral-pose data
Boss_MedusaMetaspritePartDescriptors:   dc.l    Boss_ValkirieMetaspriteFrame+$400000  ; DATA XREF: Boss_InitMedusaState0+1C   o  ; was: off_59F88
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
Boss_MedusaMetaspriteInitialAngles: dc.w    $18, $1010, $100F  ; DATA XREF: Boss_InitMedusaState0+22   o  ; was: word_59FDC
                dc.w    $1810, $1010, $F18
                dc.w    $1010, $100F, $1810
                dc.w    $1010, $F00
Boss_MedusaMetaspritePartLinks: dc.w    $C005, $C003, $C064  ; was: word_59FF2
                                        ; DATA XREF: Boss_InitMedusaState0+28   o
                dc.w    $C0C4, $C124, $C184
                dc.w    $C003, $C244, $C2A4
                dc.w    $C304, $C364, $C003
                dc.w    $C424, $C484, $C4E4
                dc.w    $C544, $C003, $C604
                dc.w    $C664, $C6C4, $C724
Boss_MedusaMetaspritePoseAngles:    dc.w    $8080, $8080, $8080  ; was: word_5A01C
                                        ; DATA XREF: Boss_InitMedusaState0+34   o
                dc.w    $8000
; Sylpheed metasprite initialization and neutral-pose data
Boss_SylpheedMetaspritePartDescriptors: dc.l    Boss_ValkirieMetaspriteFrame+$400000  ; DATA XREF: Boss_SylpheedBattleStart+10   o  ; was: off_5A024
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable2
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable6
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable6
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable0-$68000000
                dc.l    SevenForceRotationFrameTable0-$68000000
                dc.l    SevenForceRotationFrameTable0-$68000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable0+$18000000
Boss_SylpheedMetaspriteInitialAngles:   dc.w    $1A, $E0E, $E18  ; DATA XREF: Boss_SylpheedBattleStart+16   o  ; was: word_5A090
                dc.w    $1613, $1318, $1416
                dc.w    $121D, $1212, $1212
                dc.w    $1216, $121D, $1212
                dc.w    $1212, $1200
Boss_SylpheedMetaspritePartLinks:   dc.w    $C00A, $C009, $C068  ; was: word_5A0AC
                                        ; DATA XREF: Boss_SylpheedBattleStart+1C   o
                dc.w    $C0C8, $C128, $C00A
                dc.w    $C1EA, $C24A, $C2AA
                dc.w    $C309, $C36B, $C007
                dc.w    $C426, $C485, $C4E4
                dc.w    $C543, $C5A2, $C602
                dc.w    $C4E6, $C00D, $C72C
                dc.w    $C78D, $C7ED, $C84D
                dc.w    $C8AD, $C90D, $C7ED
Boss_SylpheedMetaspritePoseAngles:  dc.w    $80, $C080, $4040  ; DATA XREF: Boss_SylpheedBattleStart+28   o  ; was: word_5A0E2
                dc.w    $80C0, $8080, $8080
; Artemis metasprite initialization and neutral-pose data
Boss_ArtemisMetaspritePartDescriptors:  dc.l    SevenForceInlinePartDescriptor0+1  ; DATA XREF: Boss_InitArtemisState0+10   o  ; was: off_5A0EE
                dc.l    Boss_ValkirieMetaspriteFrame+$400000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable2
                dc.l    SevenForceRotationFrameTable0-$38000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    0
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable3-$68000000
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable3-$68000000
                dc.l    SevenForceRotationFrameTable6
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceRotationFrameTable3+$18000000
Boss_ArtemisMetaspriteInitialAngles:    dc.w    $1C, $141A, $120A  ; DATA XREF: Boss_InitArtemisState0+16   o  ; was: word_5A166
                dc.w    $1020, $1020, $808
                dc.w    $1020, $1020, $810
                dc.w    $1010, $2208, $1010
                dc.w    $1022, $812, $1212
Boss_ArtemisMetaspritePartLinks:    dc.w    $C008, $C007, $C007  ; was: word_5A184
                                        ; DATA XREF: Boss_InitArtemisState0+1C   o
                dc.w    $C067, $C126, $C061
                dc.w    $C1E3, $C1E2, $C2A3
                dc.w    $C2A1, $C361, $C060
                dc.w    $C429, $C42A, $C4E9
                dc.w    $C4E8, $C5A8, $C0C6
                dc.w    $C666, $C6C6, $C6C4
                dc.w    $C784, $C0CB, $C84C
                dc.w    $C8AB, $C8AA, $C96A
                dc.w    $C0C8, $CA27, $CA87
Boss_ArtemisMetaspritePoseAngles:   dc.w    $80, $C0, $C080  ; DATA XREF: Boss_InitArtemisState0+28   o  ; was: word_5A1C0
                dc.w    $80C0, $C080, $80A0
                dc.w    $8080, $A080, $8080
                dc.w    $80F0
; Sirene metasprite initialization and neutral-pose data
Boss_SireneMetaspritePartDescriptors:   dc.l    Boss_ValkirieMetaspriteFrame+$400000  ; DATA XREF: Boss_InitSireneMetasprite+10   o  ; was: off_5A1D4
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable2-$40000000
                dc.l    0
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    0
                dc.l    SevenForceRotationFrameTable0+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    0
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
Boss_SireneMetaspriteInitialAngles: dc.w    $8098, $9598, $8494  ; was: word_5A244
                                        ; DATA XREF: Boss_InitSireneMetasprite+16   o
                dc.w    $9090, $9097, $9797
                dc.w    $9798, $8494, $9090
                dc.w    $9097, $9797, $9794
                dc.w    $8EA0, $9898
Boss_SireneMetaspritePartLinks: dc.w    $C008, $C008, $C007  ; was: word_5A260
                                        ; DATA XREF: Boss_InitSireneMetasprite+1C   o
                dc.w    $C000, $C125, $C124
                dc.w    $C1E4, $C244, $C2A2
                dc.w    $C303, $C303, $C303
                dc.w    $C303, $C000, $C4E5
                dc.w    $C4E4, $C5A4, $C604
                dc.w    $C662, $C6C3, $C6C3
                dc.w    $C6C3, $C6C3, $C068
                dc.w    $68, $C908, $C968
                dc.w    $C9C8
Boss_SireneMetaspritePoseAngles:    dc.w    $2080, $60, $8080  ; DATA XREF: Boss_InitSireneMetasprite+28   o  ; was: word_5A298
                dc.w    $C080, $4080
; Alternate Valkirie metasprite initialization and neutral-pose data
Boss_ValkirieAlternateMetaspritePartDescriptors:    dc.l    Boss_ValkirieMetaspriteFrame+$400000  ; DATA XREF: Boss_ValkirieAlternateInit+10   o  ; was: off_5A2A2
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceRotationFrameTable6
                dc.l    SevenForceRotationFrameTable1+$10000000
                dc.l    SevenForceRotationFrameTable1+$10000000
                dc.l    SevenForceRotationFrameTable1+$10000000
                dc.l    SevenForceRotationFrameTable1+$10000000
                dc.l    SevenForceRotationFrameTable4+$10000000
                dc.l    SevenForceRotationFrameTable0+$8000000
                dc.l    SevenForceRotationFrameTable0+$8000000
                dc.l    SevenForceRotationFrameTable0+$8000000
                dc.l    SevenForceRotationFrameTable0+$8000000
                dc.l    SevenForceRotationFrameTable3+$8000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable6
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable4
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceRotationFrameTable3+$18000000
Boss_ValkirieAlternateMetaspriteInitialAngles:  dc.w    $1A, $1814, $1D15  ; DATA XREF: Boss_ValkirieAlternateInit+16   o  ; was: word_5A302
                dc.w    $1515, $151D, $1515
                dc.w    $1515, $1428, $1014
                dc.w    $2810, $1412, $1412
Boss_ValkirieAlternateMetaspritePartLinks:  dc.w    $C002, $C003, $C001  ; was: word_5A31A
                                        ; DATA XREF: Boss_ValkirieAlternateInit+1C   o
                dc.w    $C068, $C002, $C182
                dc.w    $C1E2, $C242, $C2A2
                dc.w    $C002, $C362, $C3C2
                dc.w    $C422, $C482, $C063
                dc.w    $C063, $C5A2, $C063
                dc.w    $C063, $C6C2, $C004
                dc.w    $C784, $C004, $C844
Boss_ValkirieAlternateMetaspritePoseAngles: dc.w    0, 0, $C0  ; DATA XREF: Boss_ValkirieAlternateInit+28   o  ; was: word_5A34A
                dc.w    $E0C0, $20C0, $8080
; Unidentified Seven Force metasprite initialization and neutral-pose data
Boss_UnidentifiedSevenForceMetaspritePartDescriptors:   dc.l    Boss_ValkirieMetaspriteFrame+$400000  ; DATA XREF: Boss_UnidentifiedSevenForceInit+10   o  ; was: off_5A356
                dc.l    SevenForceInlinePartDescriptor0+1
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable2
                dc.l    SevenForceRotationFrameTable0-$38000000
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceRotationFrameTable3-$48000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    0
                dc.l    SevenForceInlinePartDescriptor1+1
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceRotationFrameTable3-$48000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable3-$68000000
                dc.l    SevenForceRotationFrameTable1-$80000000
                dc.l    SevenForceRotationFrameTable3+$18000000
                dc.l    SevenForceRotationFrameTable5+$18000000
                dc.l    SevenForceInlinePartDescriptor2+1
                dc.l    SevenForceRotationFrameTable3-$68000000
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceRotationFrameTable1
                dc.l    SevenForceRotationFrameTable3+$28000000
Boss_UnidentifiedSevenForceMetaspriteInitialAngles: dc.w    $1C, $141A, $120A  ; DATA XREF: Boss_UnidentifiedSevenForceInit+16   o  ; was: word_5A3CE
                dc.w    $1020, $1020, $808
                dc.w    $1020, $1020, $810
                dc.w    $1010, $2008, $1010
                dc.w    $1020, $812, $1212
Boss_UnidentifiedSevenForceMetaspritePartLinks: dc.w    $C007, $C008, $C067  ; was: word_5A3EC
                                        ; DATA XREF: Boss_UnidentifiedSevenForceInit+1C   o
                dc.w    $C007, $C126, $C001
                dc.w    $C1E3, $C1E2, $C2A3
                dc.w    $C2A1, $C361, $C000
                dc.w    $C429, $C42A, $C4E9
                dc.w    $C4E8, $C5A8, $C0C6
                dc.w    $C665, $C6C6, $C6C4
                dc.w    $C784, $C0CB, $C84C
                dc.w    $C8AB, $C8AA, $C96A
                dc.w    $C0C7, $CA27, $CA87
Boss_UnidentifiedSevenForceMetaspritePoseAngles:    dc.w    $8080, $C0, $8080  ; DATA XREF: Boss_UnidentifiedSevenForceInit+28   o  ; was: word_5A428
                dc.w    $80C0, $8080, $80A0
                dc.w    $8080, $A080, $8080
                dc.w    $8080
