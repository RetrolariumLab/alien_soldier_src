; Shared combat sprite frames followed by three Stage 15 fragment frames
; Numeric suffixes preserve ROM order without guessing a visual identity shared by unrelated users
; Known consumers and unresolved visual roles are recorded in docs/unknowns.md

Effect_SpriteFrame00:   dc.w    $5079, $A00, $E8        ; was: word_E907A
                                        ; ROM:000E9544   o
                dc.w    $5879, $A00, 0
                dc.w    $4079, $A00, $E8E8
                dc.w    $C879, $A00, $E800
Effect_SpriteFrame01:   dc.w    $5082, $A00, $E8        ; was: word_E9092
                                        ; ROM:000E956C   o
                dc.w    $4082, $A00, $E8E8
                dc.w    $5882, $A00, 0
                dc.w    $C882, $A00, $E800
Effect_SpriteFrame02:   dc.w    $C88B, $F00, $F0F0      ; was: word_E90AA
                                        ; ROM:000E9570   o
Effect_SpriteFrame03:   dc.w    $C89B, $F00, $F0F0      ; was: word_E90B0
                                        ; ROM:000E9574   o
Effect_SpriteFrame04:   dc.w    $C8AB, $F00, $F0F0      ; was: word_E90B6
                                        ; ROM:000E9578   o
Effect_SpriteFrame05:   dc.w    $C8BB, $F00, $F0F0      ; was: word_E90BC
                                        ; ROM:000E955C   o
Effect_SpriteFrame06:   dc.w    $C800, $A00, $F4F4      ; was: word_E90C2
                                        ; ROM:Effect_SpriteAnimation00   o
Effect_SpriteFrame07:   dc.w    $C8CB, $F00, $F0F0      ; was: word_E90C8
                                        ; ROM:000E9564   o
Effect_SpriteFrame08:   dc.w    $C8EC, $F00, $F0F0      ; was: word_E90CE
                                        ; ROM:000E960C   o
Effect_SpriteFrame09:   dc.w    $C8FC, $100, $F8FC      ; was: word_E90D4
                                        ; ROM:Effect_SpriteAnimation23   o
Effect_SpriteFrame10:   dc.w    $C8FE, $400, $FCF8      ; was: word_E90DA
                                        ; ROM:000E977C   o
Effect_SpriteFrame11:   dc.w    $C900, $500, $F8F8      ; was: word_E90E0
                                        ; ROM:000E9778   o
Effect_SpriteFrame12:   dc.w    $C100, $500, $F8F8      ; was: word_E90E6
                                        ; ROM:000E9780   o
Effect_SpriteFrame13:   dc.w    $C86C, 0, $FCFC         ; was: word_E90EC
Effect_SpriteFrame14:   dc.w    $C86D, $500, $F8F8      ; was: word_E90F2
Effect_SpriteFrame15:   dc.w    $C871, 0, $FCFC         ; was: word_E90F8
Effect_SpriteFrame16:   dc.w    $4873, 0, $FCFC         ; was: word_E90FE
                                        ; ROM:000E97B0   o
                dc.w    $50DB, 0, $F8
                dc.w    $58DB, 0, 0
                dc.w    $40DB, 0, $F8F8
                dc.w    $C8DB, 0, $F800
Effect_SpriteFrame17:   dc.w    $4840, $500, $F8F8      ; was: word_E911C
                                        ; ROM:000E97AC   o
                dc.w    $50DB, 0, $F8
                dc.w    $58DB, 0, 0
                dc.w    $40DB, 0, $F8F8
                dc.w    $C8DB, 0, $F800
Effect_SpriteFrame18:   dc.w    $50DB, 0, $F8           ; was: word_E913A
                dc.w    $58DB, 0, 0
                dc.w    $40DB, 0, $F8F8
                dc.w    $C8DB, 0, $F800
Effect_SpriteFrame19:   dc.w    $50DC, 0, $F8           ; was: word_E9152
                dc.w    $58DC, 0, 0
                dc.w    $40DC, 0, $F8F8
                dc.w    $C8DC, 0, $F800
Effect_SpriteFrame20:   dc.w    $4856, $A00, $F4F4      ; was: word_E916A
                dc.w    $50DB, 0, $F8
                dc.w    $58DB, 0, 0
                dc.w    $40DB, 0, $F8F8
                dc.w    $C8DB, 0, $F800
Effect_SpriteFrame21:   dc.w    $C82C, $500, $F8F8      ; was: word_E9188
                                        ; ROM:000E95C4   o
Effect_SpriteFrame22:   dc.w    $C830, $500, $F8F8      ; was: word_E918E
                                        ; ROM:000E95C8   o
Effect_SpriteFrame23:   dc.w    $C834, $500, $F8F8      ; was: word_E9194
                                        ; ROM:000E95CC   o
Effect_SpriteFrame24:   dc.w    $C838, $500, $F8F8      ; was: word_E919A
                                        ; ROM:000E95D0   o
Effect_SpriteFrame25:   dc.w    $C868, $500, $F8F8      ; was: word_E91A0
                                        ; ROM:000E95BC   o
Effect_SpriteFrame26:   dc.w    $C809, $A00, $F4F4      ; was: word_E91A6
                                        ; ROM:000E9614   o
Effect_SpriteFrame27:   dc.w    $C812, $A00, $F4F4      ; was: word_E91AC
                                        ; ROM:000E9618   o
Effect_SpriteFrame28:   dc.w    $C81B, $A00, $F4F4      ; was: word_E91B2
                                        ; ROM:000E961C   o
Effect_SpriteFrame29:   dc.w    $C824, $500, $F8F8      ; was: word_E91B8
                                        ; ROM:000E9620   o
Effect_SpriteFrame30:   dc.w    $C828, $500, $F8F8      ; was: word_E91BE
                                        ; ROM:000E9600   o
Effect_SpriteFrame31:   dc.w    $C83C, $500, $F8F8      ; was: word_E91C4
                                        ; ROM:Effect_SpriteAnimation09   o
Effect_SpriteFrame32:   dc.w    $C840, $500, $F8F8      ; was: word_E91CA
                                        ; ROM:000E9654   o
Effect_SpriteFrame33:   dc.w    $C873, 0, $FCFC         ; was: word_E91D0
                                        ; ROM:000E9650   o
Effect_SpriteFrame34:   dc.w    $C872, 0, $FCFC         ; was: word_E91D6
                                        ; ROM:000E9658   o
                dc.w    $4856, $A00, $F4F4
                dc.w    $50DB, 0, $F8
                dc.w    $58DB, 0, 0
                dc.w    $40DB, 0, $F8F8
                dc.w    $C8DB, 0, $F800
Effect_SpriteFrame35:   dc.w    $C874, 0, $FCFC         ; was: word_E91FA
                                        ; Boss_GustheadSpawnScrollingDebris+36   o
Effect_SpriteFrame36:   dc.w    $C875, 0, $FCFC         ; was: word_E9200
                                        ; ROM:000E9670   o
Effect_SpriteFrame37:   dc.w    $C856, $A00, $F4F4      ; was: word_E9206
                                        ; ROM:Effect_SpriteAnimation13   o
Effect_SpriteFrame38:   dc.w    $C85F, $A00, $F4F4      ; was: word_E920C
                                        ; ROM:000E9690   o
Effect_SpriteFrame39:   dc.w    $C844, $500, $F8F8      ; was: word_E9212
                                        ; ROM:000E96C8   o
Effect_SpriteFrame40:   dc.w    $C871, 0, $FCFC         ; was: word_E9218
                                        ; ROM:000E96C4   o
Effect_SpriteFrame41:   dc.w    $C876, 0, $FCFC         ; was: word_E921E
                                        ; ROM:000E96F4   o
Effect_SpriteFrame42:   dc.w    $C877, 0, $FCFC         ; was: word_E9224
                                        ; ROM:000E9754   o
Effect_SpriteFrame43:   dc.w    $4873, 0, $FCFC         ; was: word_E922A
                                        ; ROM:000E97CC   o
                dc.w    $50DC, 0, $F8
                dc.w    $58DC, 0, 0
                dc.w    $40DC, 0, $F8F8
                dc.w    $C8DC, 0, $F800
Effect_SpriteFrame44:   dc.w    $4840, $500, $F8F8      ; was: word_E9248
                                        ; ROM:000E97C8   o
                dc.w    $50DC, 0, $F8
                dc.w    $58DC, 0, 0
                dc.w    $40DC, 0, $F8F8
                dc.w    $C8DC, 0, $F800
Effect_SpriteFrame45:   dc.w    $4856, $A00, $F4F4      ; was: word_E9266
                dc.w    $50DC, 0, $F8
                dc.w    $58DC, 0, 0
                dc.w    $40DC, 0, $F8F8
                dc.w    $C8DC, 0, $F800
Effect_SpriteFrame46:   dc.w    $48E3, $A00, $FEFE      ; was: word_E9284
                dc.w    $D0E3, $A00, $EAEA
Effect_SpriteFrame47:   dc.w    $40E0, $800, $FCE8      ; was: word_E9290
                dc.w    $C8E0, $800, $FC00
Effect_SpriteFrame48:   dc.w    $58DD, $200, $E8FC      ; was: word_E929C
                dc.w    $C8DD, $200, $FC
                dc.w    $48E3, $A00, $EAEC
                dc.w    $50E3, $A00, $D6D8
                dc.w    $48E3, $A00, $1214
                dc.w    $D0E3, $A00, $FE00
                dc.w    $40E0, $800, $FCD0
                dc.w    $48E0, $800, $FCE8
                dc.w    $40E0, $800, $FC00
                dc.w    $C8E0, $800, $FC18
                dc.w    $58DD, $200, $FC
                dc.w    $48DD, $200, $18FC
                dc.w    $58DD, $200, $D0FC
                dc.w    $C8DD, $200, $E8FC
Effect_SpriteFrame49:   dc.w    $4809, $A00, $F409      ; was: word_E92F0
                dc.w    $4812, $A00, $F4F9
                dc.w    $481B, $A00, $F4EE
                dc.w    $4824, $500, $F8E7
                dc.w    $C828, $500, $F8DD
Effect_SpriteFrame50:   dc.w    $5809, $A00, $F409      ; was: word_E930E
                dc.w    $5812, $A00, $F4F9
                dc.w    $581B, $A00, $F4ED
                dc.w    $5824, $500, $F8E6
                dc.w    $D828, $500, $F8DD
Effect_SpriteFrame51:   dc.w    $5009, $A00, $F40A      ; was: word_E932C
                dc.w    $5012, $A00, $F4FA
                dc.w    $501B, $A00, $F4ED
                dc.w    $5024, $500, $F8E6
                dc.w    $D028, $500, $F8DC
Effect_SpriteFrame52:   dc.w    $4009, $A00, $F40A      ; was: word_E934A
                dc.w    $4012, $A00, $F4FA
                dc.w    $401B, $A00, $F4EE
                dc.w    $4024, $500, $F8E7
                dc.w    $C028, $500, $F8DC
Effect_SpriteFrame53:   dc.w    $48CB, $F00, $F0F0      ; was: word_E9368
                                        ; ROM:000E9858   o
                dc.w    $488B, $F00, $F0
                dc.w    $488B, $F00, $E0F0
                dc.w    $488B, $F00, $F000
                dc.w    $C88B, $F00, $F0E0
Effect_SpriteFrame54:   dc.w    $488B, $F00, $F0F0      ; was: word_E9386
                                        ; ROM:000E985C   o
                dc.w    $588B, $F00, $DCF0
                dc.w    $408B, $F00, $F0DC
                dc.w    $488B, $F00, $F004
                dc.w    $488B, $F00, $5F0
                dc.w    $489B, $F00, $E0
                dc.w    $409B, $F00, 0
                dc.w    $589B, $F00, $E0E0
                dc.w    $D09B, $F00, $E000
Effect_SpriteFrame55:   dc.w    $488B, $F00, $F0F0      ; was: word_E93BC
                                        ; ROM:000E9860   o
                dc.w    $409B, $F00, $F0D8
                dc.w    $589B, $F00, $D8F0
                dc.w    $489B, $F00, $F008
                dc.w    $489B, $F00, $8F0
                dc.w    $489B, $F00, $3DD
                dc.w    $409B, $F00, $303
                dc.w    $509B, $F00, $DD03
                dc.w    $D89B, $F00, $DDDD
Effect_SpriteFrame56:   dc.w    $C84C, $500, $F8F8      ; was: word_E93F2
                                        ; ROM:Effect_SpriteAnimation19   o
Effect_SpriteFrame57:   dc.w    $C850, $500, $F8F8      ; was: word_E93F8
                                        ; ROM:000E9714   o
Effect_SpriteFrame58:   dc.w    $C854, 0, $FCFC         ; was: word_E93FE
                                        ; ROM:000E9718   o
Effect_SpriteFrame59:   dc.w    $C855, 0, $FCFC         ; was: word_E9404
                                        ; ROM:000E970C   o
Effect_SpriteFrame60:   dc.w    $489B, $F00, $F0F0      ; was: word_E940A
                                        ; ROM:000E9864   o
                dc.w    $58AB, $F00, $D6F0
                dc.w    $40AB, $F00, $F00A
                dc.w    $48AB, $F00, $AF0
                dc.w    $48AB, $F00, $F0D6
                dc.w    $58AB, $F00, $DB05
                dc.w    $40AB, $F00, $5DB
                dc.w    $48AB, $F00, $505
                dc.w    $D0AB, $F00, $DBDB
Effect_SpriteFrame61:   dc.w    $48AB, $F00, $F0F0      ; was: word_E9440
                                        ; ROM:000E9868   o
                dc.w    $40BB, $F00, $F00C
                dc.w    $48BB, $F00, $CF0
                dc.w    $48BB, $F00, $F0D4
                dc.w    $58BB, $F00, $D4F0
                dc.w    $48BB, $F00, $DBDB
                dc.w    $40BB, $F00, $DB05
                dc.w    $58BB, $F00, $5DB
                dc.w    $D0BB, $F00, $505
Effect_SpriteFrame62:   dc.w    $48CB, $F00, $F0F0      ; was: word_E9476
                                        ; ROM:000E9898   o
                dc.w    $588B, $F00, $E2F0
                dc.w    $588B, $F00, $F0E4
                dc.w    $D08B, $F00, $F0FC
Effect_SpriteFrame63:   dc.w    $48CB, $F00, $F0F0      ; was: word_E948E
                                        ; ROM:000E989C   o
                dc.w    $588B, $F00, $DEF0
                dc.w    $588B, $F00, $F0DE
                dc.w    $D08B, $F00, $F002
Effect_SpriteFrame64:   dc.w    $588B, $F00, $F0F0      ; was: word_E94A6
                                        ; ROM:000E98A0   o
                dc.w    $589B, $F00, $F0D9
                dc.w    $509B, $F00, $F007
                dc.w    $509B, $F00, $DDE3
                dc.w    $D89B, $F00, $DDFD
Effect_SpriteFrame65:   dc.w    $589B, $F00, $F0F0      ; was: word_E94C4
                                        ; ROM:000E98A4   o
                dc.w    $58AB, $F00, $F0D2
                dc.w    $50AB, $F00, $F00E
                dc.w    $58AB, $F00, $D8E0
                dc.w    $D0AB, $F00, $D800
Effect_SpriteFrame66:   dc.w    $58AB, $F00, $F0F0      ; was: word_E94E2
                                        ; ROM:000E98A8   o
                dc.w    $58BB, $F00, $F00F
                dc.w    $50BB, $F00, $F0D1
                dc.w    $58BB, $F00, $D5DF
                dc.w    $D0BB, $F00, $D501
Effect_SpriteFrame67:   dc.w    $C878, 0, $FCFC         ; was: word_E9500
Effect_SpriteFrame68:   dc.w    $4874, 0, $F8F8         ; was: word_E9506
                                        ; ROM:000E976C   o
                dc.w    $C878, 0, $FCFC
                dc.w    $C874, 0, $F8F8
Effect_SpriteFrame69:   dc.w    $4872, 0, $F8F8         ; was: word_E9518
                dc.w    $C878, 0, $FCFC
                dc.w    $C872, 0, $F8F8
Projectile_FragmentSpriteFrame00:   dc.w    $C8DD, $200, $F4FC  ; was: word_E952A
                                        ; ROM:0003082C   o
Projectile_FragmentSpriteFrame01:   dc.w    $C8E0, $800, $FCF4  ; was: word_E9530
                                        ; ROM:00030824   o
Projectile_FragmentSpriteFrame02:   dc.w    $C8E3, $A00, $F4F4  ; was: word_E9536
                                        ; ROM:00030820   o
