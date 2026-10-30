; Z-Leo intro, blade-direction, shared metasprite, and projectile mappings
Projectile_ZLeoScrollingLaserMapping:   dc.w    $10, $B00, $ECE8  ; was: word_ED382
                dc.w    $8810, $B00, $EC00
                dc.w    $881C, $500, $F8F8
Boss_ZLeoIntroFarSidePartMapping:   dc.w    $A820, $200, $F4FC  ; was: word_ED394
                                        ; Boss_ZLeoIntroInit+16C   o
Boss_ZLeoIntroSidePartMapping:  dc.w    $2837, $200, $8E8  ; was: word_ED39A
                                        ; Boss_ZLeoIntroInit+164   o
                dc.w    $2833, $300, $F0
                dc.w    $A823, $700, $F0F8
Boss_ZLeoCoreMappingE:  dc.w    $284A, $500, $8F8       ; was: word_ED3AC
                dc.w    $A83A, $F00, $E8F0
Boss_ZLeoIntroPartRowMapping:   dc.w    $A84E, $200, $F3FC  ; was: word_ED3B8
Boss_ZLeoIntroLowerPartMapping: dc.w    $A851, $100, $F8FC  ; was: word_ED3BE
Boss_ZLeoCoreMappingA:          dc.w    $2867, 0, $CEC  ; was: word_ED3C4
                                        ; ROM:000355B8   o
                dc.w    $2868, $C00, $CF4
                dc.w    $2863, $300, $ECEC
                dc.w    $A853, $F00, $ECF4
Boss_ZLeoCoreMappingB:  dc.w    $386C, $D00, $F0        ; was: word_ED3DC
                                        ; ROM:000355C4   o
                dc.w    $A86C, $D00, $F0F0
Boss_ZLeoCoreMappingD:  dc.w    $A874, $A00, $F4F4      ; was: word_ED3E8
                                        ; ROM:000355DC   o
Boss_ZLeoCoreMappingC:  dc.w    $A87D, $500, $F8F8      ; was: word_ED3EE
                                        ; ROM:000355D0   o
Boss_ZLeoBladeDirectionMapping0:    dc.w    $3889, $D00, $E0  ; was: word_ED3F4
                dc.w    $3881, $D00, 0
                dc.w    $2889, $D00, $F0E0
                dc.w    $A881, $D00, $F000
Boss_ZLeoBladeDirectionMapping1:    dc.w    $28A4, $F00, $FCE4  ; was: word_ED40C
                dc.w    $289E, $900, $FC04
                dc.w    $289D, 0, $F4F4
                dc.w    $A891, $E00, $E4FC
Boss_ZLeoBladeDirectionMapping2:    dc.w    $20BC, $700, $F0  ; was: word_ED424
                                        ; ROM:000528D0   o
                dc.w    $20B4, $700, $E0F0
                dc.w    $28BC, $700, 0
                dc.w    $A8B4, $700, $E000
Boss_ZLeoBladeDirectionMapping3:    dc.w    $20A4, $F00, $FCFC  ; was: word_ED43C
                dc.w    $209E, $900, $FCE4
                dc.w    $209D, 0, $F404
                dc.w    $A091, $E00, $E4E4
                dc.w    $A8C4, $800, $FCF4
                dc.w    $28C9, $500, $FAF2
                dc.w    $A8C7, $100, $F202
                dc.w    $A8CD, $200, $F4FD
                dc.w    $20C9, $500, $F9FF
                dc.w    $A0C7, $100, $F1F7
Boss_ZLeoIntroOuterPartMapping: dc.w    $A82B, $700, $F0F8  ; was: word_ED478
                                        ; Boss_ZLeoIntroInit+15C   o
Projectile_ZLeoVerticalBeamMapping: dc.w    $80C, $300, $70FC  ; was: word_ED47E
                                        ; Boss_ZLeoSpawnDropAttackPair+3C   o
                dc.w    $808, $300, $50FC
                dc.w    $808, $300, $30FC
                dc.w    $808, $300, $10FC
                dc.w    $808, $300, $F0FC
                dc.w    $808, $300, $D0FC
                dc.w    $808, $300, $B0FC
                dc.w    0, $700, $90F0
                dc.w    $8800, $700, $9000
