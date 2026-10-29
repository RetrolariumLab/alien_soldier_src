; Two direct mappings selected by the blink renderer and several state paths
Boss_AntroidBlinkAlternateMapping:  dc.w    $4847, $600, $EF03  ; was: word_EB720
                                        ; Boss_AntroidJumpSlamAttack+1EC   o
                dc.w    $484D, $400, $7FB
                dc.w    $C84F, $500, $F7F3
Boss_AntroidBlinkDefaultMapping:    dc.w    $4840, $500, $EF0B  ; was: word_EB732
                                        ; Boss_AntroidJumpSlamAttack+198   o
                dc.w    $4844, $200, $EF03
                dc.w    $484D, $400, $7FB
                dc.w    $C84F, $500, $F7F3
; Primary rotation table points through the following frames in reverse ROM order
Boss_AntroidPrimaryRotationFrame00: dc.w    $C074, $D00, $F8F0  ; was: word_EB74A
Boss_AntroidPrimaryRotationFrame01: dc.w    $C06C, $D00, $F8F0  ; was: word_EB750
Boss_AntroidPrimaryRotationFrame02: dc.w    $C063, $A00, $F4F4  ; was: word_EB756
Boss_AntroidPrimaryRotationFrame03: dc.w    $C05B, $700, $F0F9  ; was: word_EB75C
Boss_AntroidPrimaryRotationFrame04: dc.w    $C853, $700, $F0F8  ; was: word_EB762
Boss_AntroidPrimaryRotationFrame05: dc.w    $C85B, $700, $EFF8  ; was: word_EB768
Boss_AntroidPrimaryRotationFrame06: dc.w    $C863, $A00, $F3F4  ; was: word_EB76E
Boss_AntroidPrimaryRotationFrame07: dc.w    $C86C, $D00, $F7F1  ; was: word_EB774
                                        ; RAM:00FFC808   o
; Secondary rotation table points through the following frames in ROM order
Boss_AntroidSecondaryRotationFrame00:   dc.w    $C07C, $D00, $FAEB  ; was: word_EB77A
                                        ; Boss_AntroidReturnToNeutral+42   o
Boss_AntroidSecondaryRotationFrame01:   dc.w    $58B8, $500, $1EF  ; was: word_EB780
                dc.w    $D8BC, $900, $F9F7
Boss_AntroidSecondaryRotationFrame02:   dc.w    $58B0, $600, $FAF4  ; was: word_EB78C
                dc.w    $D8B6, $400, $FA04
Boss_AntroidSecondaryRotationFrame03:   dc.w    $58AF, 0, $F609  ; was: word_EB798
                dc.w    $D8A7, $700, $F6F9
Boss_AntroidSecondaryRotationFrame04:   dc.w    $D89F, $700, $F5FB  ; was: word_EB7A4
Boss_AntroidSecondaryRotationFrame05:   dc.w    $589B, $500, $F1FA  ; was: word_EB7AA
                dc.w    $D895, $900, $1FA
Boss_AntroidSecondaryRotationFrame06:   dc.w    $588D, $900, $FDFB  ; was: word_EB7B6
                dc.w    $D893, $400, $F5FB
Boss_AntroidSecondaryRotationFrame07:   dc.w    $588C, 0, $F0F6  ; was: word_EB7C2
                dc.w    $D884, $D00, $F8F8
