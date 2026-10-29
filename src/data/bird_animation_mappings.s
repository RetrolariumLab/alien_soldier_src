Enemy_BirdSpriteMapping00:  dc.w    $6870, 0, $1AE8     ; was: word_EA6B4
                                        ; ROM:Enemy_BirdAnimation01   o
                dc.w    $686C, $500, $AE8
                dc.w    $681F, $400, $DCEA
                dc.w    $6813, $B00, $E4EA
                dc.w    $6810, $200, $10D
                dc.w    $E800, $F00, $F9ED
Enemy_BirdSpriteMapping01:  dc.w    $6870, 0, $19E8     ; was: word_EA6D8
                                        ; ROM:000EA80C   o
                dc.w    $686C, $500, $9E8
                dc.w    $682A, $400, $E5EA
                dc.w    $6821, $A00, $EDEA
                dc.w    $6810, $200, $10D
                dc.w    $E800, $F00, $F9ED
Enemy_BirdSpriteMapping02:  dc.w    $682C, $A00, $EDEA  ; was: word_EA6FC
                                        ; ROM:000EA808   o
                dc.w    $6871, $800, $CDF
                dc.w    $6810, $200, $D
                dc.w    $E800, $F00, $F8ED
Enemy_BirdSpriteMapping03:  dc.w    $6835, $800, $FEEB  ; was: word_EA714
                                        ; ROM:000EA804   o
                dc.w    $6871, $800, $CDF
                dc.w    $6810, $200, $D
                dc.w    $E800, $F00, $F8ED
Enemy_BirdSpriteMapping04:  dc.w    $7835, $800, $EC    ; was: word_EA72C
                                        ; ROM:000EA800   o
                dc.w    $6871, $800, $BDF
                dc.w    $6810, $200, $FF0D
                dc.w    $E800, $F00, $F7ED
Enemy_BirdSpriteMapping05:  dc.w    $6838, $A00, $2EE   ; was: word_EA744
                                        ; ROM:000EA7FC   o
                dc.w    $6871, $800, $BDF
                dc.w    $6810, $200, $FF0D
                dc.w    $E800, $F00, $F7ED
Enemy_BirdSpriteMapping06:  dc.w    $684A, $400, $19F0  ; was: word_EA75C
                                        ; ROM:000EA82C   o
                dc.w    $6841, $A00, $1F0
                dc.w    $6871, $800, $ADF
                dc.w    $6810, $200, $FE0D
                dc.w    $E800, $F00, $F6ED
Enemy_BirdSpriteMapping07:  dc.w    $684C, $A00, $4F6   ; was: word_EA77A
                                        ; ROM:000EA864   o
                dc.w    $6862, $500, $10EB
                dc.w    $6810, $200, $50D
                dc.w    $E800, $F00, $FDED
Enemy_BirdSpriteMapping08:  dc.w    $684C, $A00, $5F7   ; was: word_EA792
                                        ; ROM:000EA854   o
                dc.w    $6866, $500, $10EB
                dc.w    $6810, $200, $70F
                dc.w    $E800, $F00, $FFEF
Enemy_BirdSpriteMapping09:  dc.w    $6857, $D00, $8F4   ; was: word_EA7AA
                                        ; ROM:Enemy_BirdAnimation03   o
                dc.w    $686A, $400, $18EB
                dc.w    $6810, $200, $90E
                dc.w    $E800, $F00, $1EE
Enemy_BirdSpriteMapping10:  dc.w    $684C, $A00, $3F4   ; was: word_EA7C2
                dc.w    $6870, 0, $1BE8
                dc.w    $686C, $500, $BE8
                dc.w    $6810, $200, $30D
                dc.w    $E800, $F00, $FBED
Enemy_BirdAnimation00:  dc.w    Enemy_BirdSpriteMapping00-*  ; was: off_EA7E0
                                        ; ROM:000EA810   o
                dc.w    4
                dc.w    Enemy_BirdSpriteMapping01-*
                dc.w    3
                dc.w    Enemy_BirdSpriteMapping02-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping03-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping04-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping05-*
                dc.w    3
                dc.w    Enemy_BirdSpriteMapping06-*
                dc.w    4
                dc.w    Enemy_BirdSpriteMapping05-*
                dc.w    3
                dc.w    Enemy_BirdSpriteMapping04-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping03-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping02-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping01-*
                dc.w    3
                dc.w    Enemy_BirdAnimation00-*
                dc.w    0
Enemy_BirdAnimation01:  dc.w    Enemy_BirdSpriteMapping00-*  ; was: off_EA814
                                        ; ROM:000EA844   o
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping01-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping02-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping03-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping04-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping05-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping06-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping05-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping04-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping03-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping02-*
                dc.w    1
                dc.w    Enemy_BirdSpriteMapping01-*
                dc.w    1
                dc.w    Enemy_BirdAnimation01-*
                dc.w    0
Enemy_BirdAnimation02:  dc.w    Enemy_BirdSpriteMapping07-*  ; was: off_EA848
                                        ; ROM:000EA858   o
                dc.w    6
                dc.w    Enemy_BirdSpriteMapping08-*
                dc.w    4
                dc.w    Enemy_BirdSpriteMapping09-*
                dc.w    6
                dc.w    Enemy_BirdSpriteMapping08-*
                dc.w    4
                dc.w    Enemy_BirdAnimation02-*
                dc.w    0
Enemy_BirdAnimation03:  dc.w    Enemy_BirdSpriteMapping09-*  ; was: off_EA85C
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping08-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping07-*
                dc.w    2
                dc.w    Enemy_BirdSpriteMapping10-*
                dc.w    $FF
