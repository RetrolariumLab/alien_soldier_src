Terrain_StampObjectSpriteMapping:   dc.w    $FFEE, $FF  ; was: word_19C4A4
Enemy_RisingAlienSpriteMapping00:   dc.w    $8800, $500, $F4F8  ; was: word_19C4A8
                                        ; ROM:0019C4EA   o
Enemy_RisingAlienSpriteMapping01:   dc.w    $8804, $500, $F4F8  ; was: word_19C4AE
                                        ; ROM:0019C4FA   o
Enemy_RisingAlienSpriteMapping02:   dc.w    $8004, $500, $F4F8  ; was: word_19C4B4
                                        ; ROM:Enemy_RisingAlienSpriteAnimation01   o
Enemy_RisingAlienSpriteMapping03:   dc.w    $8808, $500, $F4F8  ; was: word_19C4BA
Enemy_RisingAlienSpriteMapping04:   dc.w    $880C, $500, $F4F8  ; was: word_19C4C0
                                        ; ROM:0019C512   o
Enemy_RisingAlienSpriteMapping05:   dc.w    $8810, $400, $FCF8  ; was: word_19C4C6
                                        ; ROM:0019C536   o
Enemy_RisingAlienSpriteMapping06:   dc.w    $8812, $400, $FCF8  ; was: word_19C4CC
                                        ; ROM:0019C53A   o
Enemy_RisingAlienSpriteMapping07:   dc.w    $880C, $500, $F4F9  ; was: word_19C4D2
                                        ; ROM:0019C51E   o
Enemy_RisingAlienSpriteMapping08:   dc.w    $880C, $500, $F4F7  ; was: word_19C4D8
                                        ; ROM:0019C526   o
Enemy_RisingAlienSpriteAnimation00: dc.w    Enemy_RisingAlienSpriteMapping02-*  ; was: off_19C4DE
                                        ; ROM:0019C4EE   o
                dc.w    6
                dc.w    Enemy_RisingAlienSpriteMapping00-*
                dc.w    6
                dc.w    Enemy_RisingAlienSpriteMapping01-*
                dc.w    6
                dc.w    Enemy_RisingAlienSpriteMapping00-*
                dc.w    6
                dc.w    Enemy_RisingAlienSpriteAnimation00-*
                dc.w    0
Enemy_RisingAlienSpriteAnimation01: dc.w    Enemy_RisingAlienSpriteMapping02-*  ; was: off_19C4F2
                                        ; ROM:0019C502   o
                dc.w    $13
                dc.w    Enemy_RisingAlienSpriteMapping00-*
                dc.w    $13
                dc.w    Enemy_RisingAlienSpriteMapping01-*
                dc.w    $13
                dc.w    Enemy_RisingAlienSpriteMapping00-*
                dc.w    $13
                dc.w    Enemy_RisingAlienSpriteAnimation01-*
                dc.w    0
Enemy_RisingAlienSpriteAnimation02: dc.w    Enemy_RisingAlienSpriteMapping03-*  ; was: off_19C506
                                        ; ROM:0019C52A   o
                dc.w    $30
                dc.w    Enemy_RisingAlienSpriteMapping04-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping07-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping04-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping08-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping04-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping07-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping04-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteMapping08-*
                dc.w    5
                dc.w    Enemy_RisingAlienSpriteAnimation02-*
                dc.w    0
Enemy_RisingAlienSpriteAnimation03: dc.w    Enemy_RisingAlienSpriteMapping05-*  ; was: off_19C52E
                                        ; ROM:0019C542   o
                dc.w    $30
                dc.w    Enemy_RisingAlienSpriteMapping06-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping05-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping06-*
                dc.w    $30
                dc.w    Enemy_RisingAlienSpriteMapping05-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteAnimation03-*
                dc.w    0
Enemy_RisingAlienSpriteMapping09:   dc.w    0, $700, $E0F0  ; was: word_19C546
                                        ; ROM:0019C566   o
                dc.w    $8800, $700, $E000
Enemy_RisingAlienSpriteMapping10:   dc.w    8, $700, $E0F0  ; was: word_19C552
                                        ; ROM:0019C56A   o
                dc.w    $8808, $700, $E000
Enemy_RisingAlienSpriteAnimation04: dc.w    Enemy_RisingAlienSpriteMapping09-*  ; was: off_19C55E
                                        ; ROM:0019C576   o
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping10-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping09-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping10-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping09-*
                dc.w    9
                dc.w    Enemy_RisingAlienSpriteMapping10-*
                dc.w    $30
                dc.w    Enemy_RisingAlienSpriteAnimation04-*
                dc.w    0
Stage8_FlyingNeoCompositeSpriteMapping: dc.w    $2810, $700, $D8E8  ; was: word_19C57A
                dc.w    $2800, $F00, $D8F8
                dc.w    $2828, $700, $F8E8
                dc.w    $2818, $F00, $F8F8
                dc.w    $283C, $600, $18E8
                dc.w    $A830, $E00, $18F8
Midgame_LightningSpriteMapping00:   dc.w    $86E, $700, $2808  ; was: word_19C59E
                                        ; ROM:Midgame_LightningSpriteAnimation01   o
                dc.w    $85A, $700, $810
                dc.w    $84A, $F00, $E8F0
                dc.w    $8842, $700, $C8E0
Midgame_LightningSpriteMapping01:   dc.w    $86E, $700, $8D0  ; was: word_19C5B6
                                        ; ROM:0019C6C0   o
                dc.w    $85A, $700, $28F8
                dc.w    $862, $B00, $8E0
                dc.w    $85A, $700, $E8D8
                dc.w    $805A, $700, $C8D0
Midgame_LightningSpriteMapping02:   dc.w    $84A, $F00, $28F0  ; was: word_19C5D4
                                        ; ROM:0019C6CC   o
                dc.w    $86E, $700, $8F0
                dc.w    $876, 0, $E0D8
                dc.w    $884A, $F00, $E8E0
Midgame_LightningSpriteMapping03:   dc.w    $842, $700, $28D8  ; was: word_19C5EC
                                        ; ROM:0019C6D0   o
                dc.w    $86E, $700, $8D8
                dc.w    $885A, $700, $E8E0
Midgame_LightningSpriteMapping04:   dc.w    $876, 0, $E0  ; was: word_19C5FE
                                        ; ROM:0019C6DC   o
                dc.w    $4A, $F00, $8C8
                dc.w    $885A, $700, $28C8
Midgame_LightningSpriteMapping05:   dc.w    $62, $B00, $28D8  ; was: word_19C610
                                        ; ROM:0019C6E0   o
                dc.w    $806E, $700, $8E0
Midgame_LightningSpriteMapping06:   dc.w    $8842, $700, $28E0  ; was: word_19C61C
                                        ; ROM:0019C6EC   o
Midgame_LightningSpriteMapping07:   dc.w    $6E, $700, $28E8  ; was: word_19C622
                dc.w    $5A, $700, $8E0
                dc.w    $62, $B00, $E8F0
                dc.w    $885A, $700, $C800
Midgame_LightningSpriteMapping08:   dc.w    $4A, $F00, $8F0  ; was: word_19C63A
                dc.w    $862, $B00, $2818
                dc.w    $85A, $700, $810
                dc.w    $84A, $F00, $E8F0
                dc.w    $886E, $700, $C8F0
Midgame_LightningSpriteMapping09:   dc.w    $862, $B00, $28F8  ; was: word_19C658
                dc.w    $86E, $700, $8F8
                dc.w    $5A, $700, $E800
                dc.w    $8842, $700, $C800
Midgame_LightningSpriteMapping10:   dc.w    $84A, $F00, $F8F8  ; was: word_19C670
                dc.w    $4A, $F00, $28E0
                dc.w    $842, $700, $8F0
                dc.w    $85A, $700, $E8E8
                dc.w    $8062, $B00, $C8E8
Midgame_LightningSpriteMapping11:   dc.b    0, $5A, 7   ; was: byte_19C68E
                dc.b    0, $28, $F8
                dc.b    $88, $62, $B
                dc.b    0, 8, $F0
Midgame_LightningSpriteMapping12:   dc.w    $8842, $700, $28F8  ; was: word_19C69A
Midgame_LightningSpriteAnimation00: dc.w    Midgame_LightningSpriteMapping00-*  ; was: off_19C6A0
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
Midgame_LightningSpriteAnimation01: dc.w    Midgame_LightningSpriteMapping00-*  ; was: off_19C6BC
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
Midgame_LightningSpriteAnimation02: dc.w    Midgame_LightningSpriteMapping07-*  ; was: off_19C6F0
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
Midgame_LightningSpriteAnimation03: dc.w    Midgame_LightningSpriteMapping00-*  ; was: off_19C708
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
Stage8_FlyingNeoCompositeSpriteAnimation:   dc.w    Stage8_FlyingNeoCompositeSpriteMapping-*  ; was: off_19C720
                dc.w    $FF
Stage1To4MappingData7800:   dc.b    0, $2E, 0, 0, $5B, $82, $82, $25, 2, $5F, 0, 0, $5A, 0, 0, $40, $82, 0, $5F, 0, 0, $A0, $BF, $FC, $CC, $5F, 0, 0, $5F, 0, 0, $5F  ; was: byte_19C724
                dc.b    0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $8E, $B8
Stage5To7MappingData7800:   dc.b    0, $28, 0, 0, $5F, $82, $82, $E8, $41, $5F, 0, 0, $5F, 0, 0, $F0, $83, $FC, $A2, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F, 0, 0, $5F  ; was: byte_19C754
                dc.b    0, 0, $5F, 0, 0, $5F, 0, 0, $BA, $90
