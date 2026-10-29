; Shield Viper sprite mappings
; Shield Viper frames are named by their selector tables; suffixes do not guess poses

Boss_ShieldViperBodyAngleFrame00:   dc.w    $C84E, $F00, $F0F0  ; DATA XREF: ROM:Boss_ShieldViperBodyInitializationRecords   o  ; was: word_ECF76
                                        ; ROM:0004E1E8   o
Boss_ShieldViperBodyAngleFrame01:   dc.w    $C85E, $F00, $EEF2  ; DATA XREF: ROM:0004F5A0   o  ; was: word_ECF7C
                                        ; ROM:0004F5C0   o
Boss_ShieldViperBodyAngleFrame02:   dc.w    $C86E, $F00, $F0F0  ; DATA XREF: ROM:0004F5A8   o  ; was: word_ECF82
                                        ; ROM:0004F5C8   o
Boss_ShieldViperBodyAngleFrame03:   dc.w    $C87E, $F00, $EEEE  ; DATA XREF: ROM:0004F5B0   o  ; was: word_ECF88
                                        ; ROM:0004F5D0   o

Boss_ShieldViperControllerAngleFrame00: dc.w    $5800, $500, 8  ; DATA XREF: Boss_ShieldViperInitialize+4E   o  ; was: word_ECF8E
                                        ; ROM:Boss_ShieldViperControllerAngularMappingRecords   o
                dc.w    $5804, $E00, $E8
                dc.w    $4804, $E00, $E8E8
                dc.w    $C800, $500, $F008
Boss_ShieldViperControllerAngleFrame01: dc.w    $4824, $200, $F10F  ; DATA XREF: ROM:0004F560   o  ; was: word_ECFA6
                                        ; ROM:0004F580   o
                dc.w    $4820, $C00, $E9F7
                dc.w    $C810, $F00, $F1EF
Boss_ShieldViperControllerAngleFrame02: dc.w    $402B, $B00, $F8E8  ; DATA XREF: ROM:0004F568   o  ; was: word_ECFB8
                                        ; ROM:0004F588   o
                dc.w    $4027, $500, $E8F0
                dc.w    $4827, $500, $E800
                dc.w    $C82B, $B00, $F800
Boss_ShieldViperControllerAngleFrame03: dc.w    $484B, $200, $F1E9  ; DATA XREF: ROM:0004F570   o  ; was: word_ECFD0
                                        ; ROM:0004F590   o
                dc.w    $4847, $C00, $E9E9
                dc.w    $C837, $F00, $F1F1
Boss_ShieldViperBodyInitTailFrame00:    dc.w    $C88E, $500, $F8F8  ; DATA XREF: ROM:0004E270   o  ; was: word_ECFE2
                                        ; ROM:0004E278   o
Boss_ShieldViperBodyInitTailFrame01:    dc.w    $C892, $500, $F8F8  ; DATA XREF: ROM:0004E280   o  ; was: word_ECFE8
                                        ; ROM:0004E288   o
Boss_ShieldViperBodyInitTailFrame02:    dc.w    $C896, $500, $F8F8  ; DATA XREF: ROM:0004E290   o  ; was: word_ECFEE
                                        ; ROM:0004E298   o
Projectile_ShieldViperOrbitShotFrame00: dc.w    $C89A, 0, $FCFC  ; DATA XREF: Projectile_InitShieldViperOrbitShot+18   o  ; was: word_ECFF4
                                        ; ROM:Projectile_ShieldViperOrbitShotAnimationRecords   o
Projectile_ShieldViperOrbitShotFrame01: dc.w    $C89B, $500, $F8F8  ; DATA XREF: Boss_ShieldViperInitialize+124   o  ; was: word_ECFFA
                                        ; ROM:0004F166   o
Projectile_ShieldViperOrbitShotFrame02: dc.w    $C89F, $A00, $F4F4  ; DATA XREF: ROM:0004F16E   o  ; was: word_ED000
Projectile_ShieldViperOrbitShotFrame03: dc.w    $C8A8, $F00, $F0F0  ; DATA XREF: ROM:0004F176   o  ; was: word_ED006
Projectile_ShieldViperOrbitShotFrame04: dc.w    $C8B8, $F00, $F0F0  ; DATA XREF: ROM:0004F17E   o  ; was: word_ED00C
Projectile_ShieldViperOrbitShotFrame05: dc.w    $C8C8, $F00, $F0F0  ; DATA XREF: ROM:0004F186   o  ; was: word_ED012
Projectile_ShieldViperOrbitShotFrame06: dc.w    $C8D8, $F00, $F0F0  ; DATA XREF: ROM:0004F18E   o  ; was: word_ED018
Projectile_ShieldViperOrbitShotFrame07: dc.w    $C8E8, $F00, $F0F0  ; DATA XREF: ROM:0004F196   o  ; was: word_ED01E
                                        ; ROM:0004F19E   o
