; Loop-animation mappings and angle-selected mappings used by the circling-enemy handlers

Enemy_BeeSpriteMappingA:    dc.w    $E800, $E00, $F7F0  ; was: word_EB2E4
Enemy_BeeSpriteMappingB:    dc.w    $E80C, $E00, $F6F0  ; was: word_EB2EA
Enemy_BeeSpriteMappingC:    dc.w    $E818, $E00, $F6F0  ; was: word_EB2F0
Enemy_BeeSpriteMappingD:    dc.w    $E824, $E00, $F5F0  ; was: word_EB2F6
Enemy_BeeSpriteMappingE:    dc.w    $E830, $E00, $F6F0  ; was: word_EB2FC
Enemy_FlySpriteMapping4:    dc.w    $E83C, $B00, $EEF4  ; was: word_EB302
                                        ; ROM:0002D356   o
Enemy_FlySpriteMapping3:    dc.w    $E848, $B00, $F0F5  ; was: word_EB308
                                        ; ROM:0002D33A   o
Enemy_FlySpriteMapping2:    dc.w    $E854, $F00, $F0F0  ; was: word_EB30E
                                        ; ROM:0002D33E   o
Enemy_FlySpriteMapping1:    dc.w    $E864, $E00, $F5F0  ; was: word_EB314
                                        ; ROM:0002D342   o
Enemy_FlySpriteMapping0:    dc.w    $E870, $E00, $F4EF  ; was: word_EB31A
                                        ; ROM:0002D346   o
Enemy_BeeLoopAnimation: dc.w    Enemy_BeeSpriteMappingA-*  ; was: off_EB320
                                        ; ROM:000EB334   o
                dc.w    2
                dc.w    Enemy_BeeSpriteMappingB-*
                dc.w    2
                dc.w    Enemy_BeeSpriteMappingC-*
                dc.w    2
                dc.w    Enemy_BeeSpriteMappingD-*
                dc.w    2
                dc.w    Enemy_BeeSpriteMappingE-*
                dc.w    2
                dc.w    Enemy_BeeLoopAnimation-*
                dc.w    0
