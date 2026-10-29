; Shared initial segment mapping, followed by two additional head-table frames
Boss_JetsripperSharedSegmentBaseFrame:  dc.w    $6804, $E00, $F3EE  ; was: word_EB654
                                        ; Boss_JetsripperDeathInit+36   o
                dc.w    $E800, $500, $F90E
Boss_JetsripperHeadFrame01: dc.w    $6832, $900, $BF4   ; was: word_EB660
                                        ; ROM:00035F76   o
                dc.w    $6826, $E00, $F3ED
                dc.w    $E820, $600, $F70D
Boss_JetsripperHeadFrame02: dc.w    $6050, $B00, $FDE8  ; was: word_EB672
                dc.w    $6850, $B00, $FD00
                dc.w    $E838, $D00, $EDF0
; Quantized body-direction table draws from two ROM-separated runs below
Boss_JetsripperBodyDirectionFrame00:    dc.w    $E86C, $D00, $F8F0  ; was: word_EB684
                                        ; ROM:00035F9A   o
Boss_JetsripperBodyDirectionFrame01:    dc.w    $E874, $E00, $F2F0  ; was: word_EB68A
                                        ; ROM:00035FB2   o
Boss_JetsripperBodyDirectionFrame02:    dc.w    $E88C, $F00, $EFF1  ; was: word_EB690
; Direct controller mapping during dive windup
Boss_JetsripperDiveWindupFrame: dc.w    $605C, $F00, $FDE0  ; was: word_EB696
                dc.w    $685C, $F00, $FD00
                dc.w    $E838, $D00, $EDF0
; Tail segment's four-slot table uses these three mappings
Boss_JetsripperTailFrame00: dc.w    $E89C, $D00, $F7E9  ; was: word_EB6A8
Boss_JetsripperTailFrame01: dc.w    $E8A4, $E00, $EFEA  ; was: word_EB6AE
                                        ; ROM:00035FC6   o
Boss_JetsripperTailFrame02:             dc.w    $E8B0, $B00, $E7F4  ; was: word_EB6B4
Boss_JetsripperBodyDirectionFrame03:    dc.w    $E8D8, $E00, $F2F1  ; was: word_EB6BA
                                        ; ROM:00035FB6   o
Boss_JetsripperBodyDirectionFrame04:    dc.w    $E8C8, $F00, $F2EF  ; was: word_EB6C0
                                        ; ROM:00035FAE   o
Boss_JetsripperBodyDirectionFrame05:    dc.w    $E8BC, $E00, $F4F1  ; was: word_EB6C6
                                        ; ROM:00035F96   o
Boss_JetsripperBodyDirectionFrame06:    dc.w    $E880, $E00, $F4F0  ; was: word_EB6CC
                                        ; ROM:00035F92   o
Boss_JetsripperBodyDirectionFrame07:    dc.w    $E840, $F00, $EDEF  ; was: word_EB6D2
                                        ; ROM:00035F8E   o
Boss_JetsripperBodyDirectionFrame08:    dc.w    $E810, $F00, $EFF0  ; was: word_EB6D8
                dc.w    $68FE, $400, $13ED
                dc.w    $68F2, $B00, $F3ED
                dc.w    $68F0, $400, $B05
                dc.w    $E8E4, $E00, $F305
; Two-frame movement cycle selected from FrameCounter bit 2
Boss_JetsripperMovementFrame00: dc.w    $68FE, $400, $19F4  ; was: word_EB6F6
                dc.w    $68F2, $B00, $F9F4
                dc.w    $68F0, $400, $110C
                dc.w    $E8E4, $E00, $F90C
Boss_JetsripperMovementFrame01: dc.w    $6832, $900, $10FA  ; was: word_EB70E
                dc.w    $6826, $E00, $F8F3
                dc.w    $E820, $600, $FC13
