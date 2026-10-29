; Missiray bullet frames and relative-offset animation streams
Projectile_MissirayBulletSpriteFrame00: dc.w    $6038, $500, $FA00  ; DATA XREF: ROM:Projectile_MissirayBulletInitialSpriteAnimation   o  ; was: word_ED024
                                        ; ROM:Projectile_MissirayBulletTransformSpriteAnimation   o
                dc.w    $E838, $500, $FAF0
Projectile_MissirayBulletSpriteFrame01: dc.w    $483C, $D00, $FBD0  ; DATA XREF: ROM:Projectile_MissirayBulletLoopSpriteAnimation   o  ; was: word_ED030
                dc.w    $483C, $D00, $FBF0
                dc.w    $483C, $D00, $FB10
                dc.w    $6038, $500, $FA30
                dc.w    $E838, $500, $FAC0
Projectile_MissirayBulletSpriteFrame02: dc.w    $583C, $D00, $F5D0  ; DATA XREF: ROM:000ED142   o  ; was: word_ED04E
                dc.w    $583C, $D00, $F6F0
                dc.w    $583C, $D00, $F510
                dc.w    $6038, $500, $FA30
                dc.w    $E838, $500, $FAC0
Projectile_MissirayBulletSpriteFrame03: dc.w    $403C, $D00, $FBD0  ; DATA XREF: ROM:000ED14A   o  ; was: word_ED06C
                dc.w    $403C, $D00, $FBF0
                dc.w    $403C, $D00, $FB10
                dc.w    $6038, $500, $FA30
                dc.w    $E838, $500, $FAC0
Projectile_MissirayBulletSpriteFrame04: dc.w    $503C, $D00, $F6D0  ; DATA XREF: ROM:000ED146   o  ; was: word_ED08A
                dc.w    $503C, $D00, $F7F0
                dc.w    $503C, $D00, $F610
                dc.w    $6038, $500, $FA30
                dc.w    $E838, $500, $FAC0
Projectile_MissirayBulletSpriteFrame05: dc.w    $6838, $500, $FAE4  ; DATA XREF: ROM:000ED15E   o  ; was: word_ED0A8
                dc.w    $6038, $500, $FA0C
                dc.w    $C83C, $D00, $FAF0
Projectile_MissirayBulletSpriteFrame06: dc.w    $6838, $500, $FADC  ; DATA XREF: ROM:000ED162   o  ; was: word_ED0BA
                dc.w    $403C, $D00, $FAE6
                dc.w    $6038, $500, $FA14
                dc.w    $C83C, $D00, $FAFA
Projectile_MissirayBulletSpriteFrame07: dc.w    $6838, $500, $FAD4  ; DATA XREF: ROM:000ED166   o  ; was: word_ED0D2
                dc.w    $483C, $D00, $FAE0
                dc.w    $6038, $500, $FA1C
                dc.w    $C03C, $D00, $FA00
Projectile_MissirayBulletSpriteFrame08: dc.w    $483C, $D00, $FAF0  ; DATA XREF: ROM:000ED16A   o  ; was: word_ED0EA
                dc.w    $6838, $500, $FACC
                dc.w    $483C, $D00, $FAD7
                dc.w    $6038, $500, $FA24
                dc.w    $C03C, $D00, $FA09
Projectile_MissirayBulletSpriteFrame09: dc.w    $583C, $D00, $F5F0  ; DATA XREF: ROM:000ED16E   o  ; was: word_ED108
                dc.w    $6838, $500, $FAC4
                dc.w    $403C, $D00, $FAD0
                dc.w    $6038, $500, $FA2C
                dc.w    $C83C, $D00, $FA10
Projectile_MissirayBulletSpriteFrame10: dc.w    $6838, $500, $FAEB  ; DATA XREF: ROM:000ED15A   o  ; was: word_ED126
                dc.w    $6038, $500, $FA05
                dc.w    $C83C, $D00, $FAF0
                dc.w    $E837, 0, $1FFF
Projectile_MissirayBulletLoopSpriteAnimation:   dc.w    Projectile_MissirayBulletSpriteFrame01-*  ; DATA XREF: Projectile_MissirayBulletWaitForTransformFrame+8   o  ; was: off_ED13E
                                        ; ROM:000ED14E   o
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame02-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame04-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame03-*
                dc.w    1
                dc.w    Projectile_MissirayBulletLoopSpriteAnimation-*
                dc.w    0
Projectile_MissirayBulletInitialSpriteAnimation:    dc.w    Projectile_MissirayBulletSpriteFrame00-*  ; DATA XREF: Projectile_InitMissirayBullet+4   o  ; was: off_ED152
                dc.w    $FF
Projectile_MissirayBulletTransformSpriteAnimation:  dc.w    Projectile_MissirayBulletSpriteFrame00-*  ; DATA XREF: Projectile_MissirayBulletTransform+6   o  ; was: off_ED156
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame10-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame05-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame06-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame07-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame08-*
                dc.w    1
                dc.w    Projectile_MissirayBulletSpriteFrame09-*
                dc.w    $FF
