Boss_CaterpillarHomingProjectileSegmentMapping: dc.w    $211A, $700, $F0F1  ; was: word_EB5E6
                dc.w    $A91A, $700, $F001
Boss_CaterpillarFourPhaseSegmentMappingC:   dc.w    $2134, $600, $7F1  ; was: word_EB5F2
                dc.w    $2934, $600, $701
                dc.w    $2122, $600, $EFF1
                dc.w    $A922, $600, $EF01
Boss_CaterpillarTwoPhaseSegmentMappingA:    dc.w    $2142, $700, $EFF1  ; was: word_EB60A
                dc.w    $A942, $700, $EF01
Boss_CaterpillarTwoPhaseSegmentMappingB:    dc.w    $214A, $700, $EFF1  ; was: word_EB616
                dc.w    $A94A, $700, $EF01
Boss_CaterpillarShipTransitionSegmentMapping:   dc.w    $2152, $700, $EFF1  ; was: word_EB622
                dc.w    $A952, $700, $EF01
Boss_CaterpillarShipTrailMappingA:  dc.w    $A95A, $A00, $F5F5  ; was: word_EB62E
                                        ; ROM:Boss_CaterpillarShipTrailAnimation   o
Boss_CaterpillarShipTrailMappingB:  dc.w    $A963, $A00, $F7F3  ; was: word_EB634
                                        ; ROM:000EB64C   o
Boss_CaterpillarShipTrailMappingC:  dc.w    $A96C, $500, $F8F8  ; was: word_EB63A
Boss_CaterpillarShipTrailAnimation: dc.w    Boss_CaterpillarShipTrailMappingA-*  ; was: off_EB640
                dc.w    8
                dc.w    Boss_CaterpillarShipTrailMappingB-*
                dc.w    4
                dc.w    Boss_CaterpillarShipTrailMappingC-*
                dc.w    6
                dc.w    Boss_CaterpillarShipTrailMappingB-*
                dc.w    4
                dc.w    Boss_CaterpillarShipTrailAnimation-*
                dc.w    0
