Terrain_StampObjectSpriteMapping:   dc.w    $FFEE, $FF  ; DATA XREF: ROM:Terrain_ObjectStampPattern   o  ; was: word_19C4A4
IndexedObjectSpriteMapping00:       dc.w    $8800, $500, $F4F8  ; DATA XREF: ROM:0019C4E2   o  ; was: word_19C4A8
                                        ; ROM:0019C4EA   o
IndexedObjectSpriteMapping01:   dc.w    $8804, $500, $F4F8  ; DATA XREF: ROM:0019C4E6   o  ; was: word_19C4AE
                                        ; ROM:0019C4FA   o
IndexedObjectSpriteMapping02:   dc.w    $8004, $500, $F4F8  ; DATA XREF: ROM:IndexedObjectSpriteAnimation00   o  ; was: word_19C4B4
                                        ; ROM:IndexedObjectSpriteAnimation01   o
IndexedObjectSpriteMapping03:   dc.w    $8808, $500, $F4F8  ; DATA XREF: ROM:IndexedObjectSpriteAnimation02   o  ; was: word_19C4BA
IndexedObjectSpriteMapping04:   dc.w    $880C, $500, $F4F8  ; DATA XREF: ROM:0019C50A   o  ; was: word_19C4C0
                                        ; ROM:0019C512   o
IndexedObjectSpriteMapping05:   dc.w    $8810, $400, $FCF8  ; DATA XREF: ROM:IndexedObjectSpriteAnimation03   o  ; was: word_19C4C6
                                        ; ROM:0019C536   o
IndexedObjectSpriteMapping06:   dc.w    $8812, $400, $FCF8  ; DATA XREF: ROM:0019C532   o  ; was: word_19C4CC
                                        ; ROM:0019C53A   o
IndexedObjectSpriteMapping07:   dc.w    $880C, $500, $F4F9  ; DATA XREF: ROM:0019C50E   o  ; was: word_19C4D2
                                        ; ROM:0019C51E   o
IndexedObjectSpriteMapping08:   dc.w    $880C, $500, $F4F7  ; DATA XREF: ROM:0019C516   o  ; was: word_19C4D8
                                        ; ROM:0019C526   o
IndexedObjectSpriteAnimation00: dc.w    IndexedObjectSpriteMapping02-*  ; DATA XREF: ROM:Object_IndexedSpriteAnimationPointers   o  ; was: off_19C4DE
                                        ; ROM:0019C4EE   o
                dc.w    6
                dc.w    IndexedObjectSpriteMapping00-*
                dc.w    6
                dc.w    IndexedObjectSpriteMapping01-*
                dc.w    6
                dc.w    IndexedObjectSpriteMapping00-*
                dc.w    6
                dc.w    IndexedObjectSpriteAnimation00-*
                dc.w    0
IndexedObjectSpriteAnimation01: dc.w    IndexedObjectSpriteMapping02-*  ; DATA XREF: ROM:0002A92C   o  ; was: off_19C4F2
                                        ; ROM:0019C502   o
                dc.w    $13
                dc.w    IndexedObjectSpriteMapping00-*
                dc.w    $13
                dc.w    IndexedObjectSpriteMapping01-*
                dc.w    $13
                dc.w    IndexedObjectSpriteMapping00-*
                dc.w    $13
                dc.w    IndexedObjectSpriteAnimation01-*
                dc.w    0
IndexedObjectSpriteAnimation02: dc.w    IndexedObjectSpriteMapping03-*  ; DATA XREF: ROM:0002A934   o  ; was: off_19C506
                                        ; ROM:0019C52A   o
                dc.w    $30
                dc.w    IndexedObjectSpriteMapping04-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping07-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping04-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping08-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping04-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping07-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping04-*
                dc.w    5
                dc.w    IndexedObjectSpriteMapping08-*
                dc.w    5
                dc.w    IndexedObjectSpriteAnimation02-*
                dc.w    0
IndexedObjectSpriteAnimation03: dc.w    IndexedObjectSpriteMapping05-*  ; DATA XREF: ROM:0002A93C   o  ; was: off_19C52E
                                        ; ROM:0019C542   o
                dc.w    $30
                dc.w    IndexedObjectSpriteMapping06-*
                dc.w    9
                dc.w    IndexedObjectSpriteMapping05-*
                dc.w    9
                dc.w    IndexedObjectSpriteMapping06-*
                dc.w    $30
                dc.w    IndexedObjectSpriteMapping05-*
                dc.w    9
                dc.w    IndexedObjectSpriteAnimation03-*
                dc.w    0
IndexedObjectSpriteMapping09:   dc.w    0, $700, $E0F0  ; DATA XREF: ROM:IndexedObjectSpriteAnimation04   o  ; was: word_19C546
                                        ; ROM:0019C566   o
                dc.w    $8800, $700, $E000
IndexedObjectSpriteMapping10:   dc.w    8, $700, $E0F0  ; DATA XREF: ROM:0019C562   o  ; was: word_19C552
                                        ; ROM:0019C56A   o
                dc.w    $8808, $700, $E000
IndexedObjectSpriteAnimation04: dc.w    IndexedObjectSpriteMapping09-*  ; DATA XREF: ROM:0002A944   o  ; was: off_19C55E
                                        ; ROM:0019C576   o
                dc.w    9
                dc.w    IndexedObjectSpriteMapping10-*
                dc.w    9
                dc.w    IndexedObjectSpriteMapping09-*
                dc.w    9
                dc.w    IndexedObjectSpriteMapping10-*
                dc.w    9
                dc.w    IndexedObjectSpriteMapping09-*
                dc.w    9
                dc.w    IndexedObjectSpriteMapping10-*
                dc.w    $30
                dc.w    IndexedObjectSpriteAnimation04-*
                dc.w    0
Stage8_FlyingNeoCompositeSpriteMapping: dc.w    $2810, $700, $D8E8  ; DATA XREF: ROM:Stage8_FlyingNeoCompositeSpriteAnimation   o  ; was: word_19C57A
                dc.w    $2800, $F00, $D8F8
                dc.w    $2828, $700, $F8E8
                dc.w    $2818, $F00, $F8F8
                dc.w    $283C, $600, $18E8
                dc.w    $A830, $E00, $18F8
Midgame_LightningSpriteMapping00:   dc.w    $86E, $700, $2808  ; DATA XREF: ROM:Midgame_LightningSpriteAnimation00   o  ; was: word_19C59E
                                        ; ROM:Midgame_LightningSpriteAnimation01   o
                dc.w    $85A, $700, $810
                dc.w    $84A, $F00, $E8F0
                dc.w    $8842, $700, $C8E0
Midgame_LightningSpriteMapping01:   dc.w    $86E, $700, $8D0  ; DATA XREF: ROM:0019C6A4   o  ; was: word_19C5B6
                                        ; ROM:0019C6C0   o
                dc.w    $85A, $700, $28F8
                dc.w    $862, $B00, $8E0
                dc.w    $85A, $700, $E8D8
                dc.w    $805A, $700, $C8D0
Midgame_LightningSpriteMapping02:   dc.w    $84A, $F00, $28F0  ; DATA XREF: ROM:0019C6A8   o  ; was: word_19C5D4
                                        ; ROM:0019C6CC   o
                dc.w    $86E, $700, $8F0
                dc.w    $876, 0, $E0D8
                dc.w    $884A, $F00, $E8E0
Midgame_LightningSpriteMapping03:   dc.w    $842, $700, $28D8  ; DATA XREF: ROM:0019C6AC   o  ; was: word_19C5EC
                                        ; ROM:0019C6D0   o
                dc.w    $86E, $700, $8D8
                dc.w    $885A, $700, $E8E0
Midgame_LightningSpriteMapping04:   dc.w    $876, 0, $E0  ; DATA XREF: ROM:0019C6B0   o  ; was: word_19C5FE
                                        ; ROM:0019C6DC   o
                dc.w    $4A, $F00, $8C8
                dc.w    $885A, $700, $28C8
Midgame_LightningSpriteMapping05:   dc.w    $62, $B00, $28D8  ; DATA XREF: ROM:0019C6B4   o  ; was: word_19C610
                                        ; ROM:0019C6E0   o
                dc.w    $806E, $700, $8E0
Midgame_LightningSpriteMapping06:   dc.w    $8842, $700, $28E0  ; DATA XREF: ROM:0019C6B8   o  ; was: word_19C61C
                                        ; ROM:0019C6EC   o
Midgame_LightningSpriteMapping07:   dc.w    $6E, $700, $28E8  ; DATA XREF: ROM:Midgame_LightningSpriteAnimation02   o  ; was: word_19C622
                dc.w    $5A, $700, $8E0
                dc.w    $62, $B00, $E8F0
                dc.w    $885A, $700, $C800
Midgame_LightningSpriteMapping08:   dc.w    $4A, $F00, $8F0  ; DATA XREF: ROM:0019C6F4   o  ; was: word_19C63A
                dc.w    $862, $B00, $2818
                dc.w    $85A, $700, $810
                dc.w    $84A, $F00, $E8F0
                dc.w    $886E, $700, $C8F0
Midgame_LightningSpriteMapping09:   dc.w    $862, $B00, $28F8  ; DATA XREF: ROM:0019C6F8   o  ; was: word_19C658
                dc.w    $86E, $700, $8F8
                dc.w    $5A, $700, $E800
                dc.w    $8842, $700, $C800
Midgame_LightningSpriteMapping10:   dc.w    $84A, $F00, $F8F8  ; DATA XREF: ROM:0019C6FC   o  ; was: word_19C670
                dc.w    $4A, $F00, $28E0
                dc.w    $842, $700, $8F0
                dc.w    $85A, $700, $E8E8
                dc.w    $8062, $B00, $C8E8
Midgame_LightningSpriteMapping11:   dc.b    0, $5A, 7   ; DATA XREF: ROM:0019C700   o  ; was: byte_19C68E
                dc.b    0, $28, $F8
                dc.b    $88, $62, $B
                dc.b    0, 8, $F0
Midgame_LightningSpriteMapping12:   dc.w    $8842, $700, $28F8  ; DATA XREF: ROM:0019C704   o  ; was: word_19C69A
Midgame_LightningSpriteAnimation00: dc.w    Midgame_LightningSpriteMapping00-*  ; DATA XREF: ROM:Midgame_RandomLightningMappingPointers   o  ; was: off_19C6A0
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping01-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping02-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping03-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping04-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping05-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping06-*
                dc.w    $FF
Midgame_LightningSpriteAnimation01: dc.w    Midgame_LightningSpriteMapping00-*  ; DATA XREF: ROM:0000D83E   o  ; was: off_19C6BC
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping01-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping00-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping01-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping02-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping03-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping02-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping03-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping04-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping05-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping04-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping05-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping06-*
                dc.w    $FF
Midgame_LightningSpriteAnimation02: dc.w    Midgame_LightningSpriteMapping07-*  ; DATA XREF: ROM:0000D842   o  ; was: off_19C6F0
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping08-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping09-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping10-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping11-*
                dc.w    3
                dc.w    Midgame_LightningSpriteMapping12-*
                dc.w    $FF
Midgame_LightningSpriteAnimation03: dc.w    Midgame_LightningSpriteMapping00-*  ; DATA XREF: ROM:0000D846   o  ; was: off_19C708
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping04-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping05-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping04-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping05-*
                dc.w    2
                dc.w    Midgame_LightningSpriteMapping06-*
                dc.w    $FF
Stage8_FlyingNeoCompositeSpriteAnimation:   dc.w    Stage8_FlyingNeoCompositeSpriteMapping-*  ; DATA XREF: Stage8_InitializeFlyingNeoComposite+12   o  ; was: off_19C720
                dc.w    $FF
Stage1To4MappingData7800:   dc.b    0, $2E, 0, 0, $5B, $82, $82, $25, 2, $5F, 0, 0, $5A, 0, 0, $40, $82, 0, $5F, 0, 0, $A0, $BF, $FC, $CC, $5F, 0, 0, $5F, 0, 0, $5F  ; was: byte_19C724
                                        ; DATA XREF: ROM:000117D0   o
                dc.b    0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $8E, $B8
Stage5To7MappingData7800:   dc.b    0, $28, 0, 0, $5F, $82, $82, $E8, $41, $5F, 0, 0, $5F, 0, 0, $F0, $83, $FC, $A2, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F  ; was: byte_19C754
                                        ; DATA XREF: ROM:0001187A   o
                dc.b    0, 0, $5F, 0, 0, $5F, 0, 0, $BA, $90
