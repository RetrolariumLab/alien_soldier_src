; Primary rotation table points through these eight frames in reverse ROM order
Boss_TerobusterPrimaryRotationFrame00:  dc.w    $E86E, $D00, $F8F1  ; was: word_EB7CE
Boss_TerobusterPrimaryRotationFrame01:  dc.w    $E876, $E00, $F4F0  ; was: word_EB7D4
Boss_TerobusterPrimaryRotationFrame02:  dc.w    $E882, $F00, $EFF0  ; was: word_EB7DA
Boss_TerobusterPrimaryRotationFrame03:  dc.w    $E892, $B00, $F0F6  ; was: word_EB7E0
Boss_TerobusterPrimaryRotationFrame04:  dc.w    $F09E, $700, $F0F8  ; was: word_EB7E6
Boss_TerobusterPrimaryRotationFrame05:  dc.w    $F0A6, $B00, $F0F4  ; was: word_EB7EC
Boss_TerobusterPrimaryRotationFrame06:  dc.w    $F0B2, $F00, $F0F0  ; was: word_EB7F2
Boss_TerobusterPrimaryRotationFrame07:  dc.w    $F0C2, $E00, $F2F1  ; was: word_EB7F8
; Secondary rotation table uses ROM order; its first frame is also assigned directly
Boss_TerobusterSecondaryRotationFrame00:    dc.w    $60D6, $500, $F806  ; was: word_EB7FE
                                        ; Boss_TerobusterDecisionState+2A0   o
                dc.w    $E0CE, $D00, $F8E6
Boss_TerobusterSecondaryRotationFrame01:    dc.w    $60E2, $600, $F805  ; was: word_EB80A
                dc.w    $E0DA, $D00, $F8E5
Boss_TerobusterSecondaryRotationFrame02:    dc.w    $60F0, $900, $F8  ; was: word_EB816
                dc.w    $E0E8, $D00, $F0E8
Boss_TerobusterSecondaryRotationFrame03:    dc.w    $60FF, $A00, $1F5  ; was: word_EB822
                dc.w    $E0F6, $A00, $E9ED
Boss_TerobusterSecondaryRotationFrame04:    dc.w    $6110, $500, $4F6  ; was: word_EB82E
                dc.w    $E108, $700, $E4F6
Boss_TerobusterSecondaryRotationFrame05:    dc.w    $611C, $900, $2EE  ; was: word_EB83A
                dc.w    $E114, $700, $E2F6
Boss_TerobusterSecondaryRotationFrame06:    dc.w    $6126, $E00, $F7EA  ; was: word_EB846
                dc.w    $E122, $500, $E7FF
Boss_TerobusterSecondaryRotationFrame07:    dc.w    $613A, $600, $E705  ; was: word_EB852
                dc.w    $E132, $D00, $F8E5
                dc.w    $694C, $D00, $6F8
                dc.w    $E940, $E00, $EEF0
Boss_TerobusterSetupSpriteMapping:  dc.w    $695A, $E00, $F2EB  ; was: word_EB86A
                dc.w    $E954, $600, $FA0B
