; Sprite mappings of the type-$1C and type-$44 stage enemies
Enemy_BehaviorSpriteMapping00:  dc.w    $6863, $500, $10EE  ; was: word_E9C2E
                                        ; ROM:Enemy_BehaviorGroundedSpriteAnimation   o
                dc.w    $6845, $C00, $EF1
                dc.w    $6839, $E00, $F6F1
                dc.w    $6871, $500, $10FD
                dc.w    $E800, $D00, $E6F1
Enemy_BehaviorSpriteMapping01:  dc.w    $6863, $500, $10EE  ; was: word_E9C4C
                                        ; ROM:000E9E38   o
                dc.w    $6829, $F00, $F8F3
                dc.w    $6871, $500, $10FD
                dc.w    $E800, $D00, $E8F3
Enemy_BehaviorSpriteMapping02:  dc.w    $6863, $500, $10EE  ; was: word_E9C64
                                        ; ROM:000E9E34   o
                dc.w    $6819, $F00, $FAF3
                dc.w    $6871, $500, $10FD
                dc.w    $E800, $D00, $EAF3
Enemy_BehaviorSpriteMapping03:  dc.w    $6808, $D00, $EBF2  ; was: word_E9C7C
                                        ; ROM:000E9E30   o
                dc.w    $686B, 0, $1CFB
                dc.w    $6867, $500, $14EB
                dc.w    $6819, $F00, $FBF2
                dc.w    $6875, 0, $1C0A
                dc.w    $E876, $500, $14FA
Enemy_BehaviorSpriteMapping04:  dc.w    $6808, $D00, $EEF0  ; was: word_E9CA0
                                        ; ROM:000E9E50   o
                dc.w    $686B, 0, $1CFB
                dc.w    $6867, $500, $14EB
                dc.w    $6819, $F00, $FEF0
                dc.w    $6875, 0, $1C0A
                dc.w    $E876, $500, $14FA
Enemy_BehaviorSpriteMapping05:  dc.w    $6808, $D00, $E6F2  ; was: word_E9CC4
                dc.w    $6863, $500, $DEB
                dc.w    $6839, $E00, $F6F2
                dc.w    $6845, $C00, $EF2
                dc.w    $687A, $800, $18FF
                dc.w    $E87D, $400, $10F7
Enemy_BehaviorSpriteMapping06:  dc.w    $6808, $D00, $E4F4  ; was: word_E9CE8
                dc.w    $6867, $500, $CEE
                dc.w    $6829, $F00, $F4F4
                dc.w    $686B, 0, $16FC
                dc.w    $E871, $500, $10F9
Enemy_BehaviorSpriteMapping07:  dc.w    $686F, $400, $10EE  ; was: word_E9D06
                dc.w    $686C, $800, $18F6
                dc.w    $6819, $F00, $F6EF
                dc.w    $6871, $500, $EF0
                dc.w    $E800, $D00, $E6EF
Enemy_BehaviorSpriteMapping08:  dc.w    $6863, $500, $10EE  ; was: word_E9D24
                dc.w    $6829, $F00, $F4F4
                dc.w    $6875, 0, $1508
                dc.w    $6876, $500, $DF8
                dc.w    $E800, $D00, $E4F4
Enemy_BehaviorSpriteMapping09:  dc.w    $6800, $D00, $E7F0  ; was: word_E9D42
                                        ; ROM:000E9E7C   o
                dc.w    $6857, $E00, $F7F0
                dc.w    $6863, $500, $10EE
                dc.w    $6845, $C00, $FEF
                dc.w    $E871, $500, $10FD
Enemy_BehaviorSpriteMapping10:  dc.w    $6808, $D00, $E6F2  ; was: word_E9D60
                                        ; ROM:000E9E78   o
                dc.w    $6857, $E00, $F6F2
                dc.w    $6863, $500, $10EE
                dc.w    $6845, $C00, $EF1
                dc.w    $E871, $500, $10FD
Enemy_BehaviorSpriteMapping11:  dc.w    $6818, 0, $F013  ; was: word_E9D7E
                dc.w    $6810, $D00, $E7F3
                dc.w    $6849, $100, $F613
                dc.w    $684B, $E00, $F6F3
                dc.w    $6863, $500, $10EE
                dc.w    $6845, $C00, $EF3
                dc.w    $E871, $500, $10FD
Enemy_BehaviorSpriteMapping12:  dc.w    $6875, 0, $140B  ; was: word_E9DA8
                dc.w    $6863, $500, $10ED
                dc.w    $6845, $C00, $CF1
                dc.w    $6876, $500, $CFB
                dc.w    $6839, $E00, $F4F1
                dc.w    $E808, $D00, $E4F2
Enemy_BehaviorSpriteMapping13:  dc.w    $686B, 0, $14FE  ; was: word_E9DCC
                dc.w    $6867, $500, $CEE
                dc.w    $6808, $D00, $E4F2
                dc.w    $6845, $C00, $CF1
                dc.w    $6839, $E00, $F4F1
                dc.w    $E871, $500, $10FD
Enemy_BehaviorSpriteMapping14:  dc.w    $6863, $500, $CEF  ; was: word_E9DF0
                                        ; ROM:000E9E8C   o
                dc.w    $6829, $F00, $F4F1
                dc.w    $6808, $D00, $E4F2
                dc.w    $E871, $500, $CFD
; Four 4-tick mappings, then a zero-timer relative jump back to this stream
Enemy_BehaviorMovementSpriteAnimation:  dc.w    Enemy_BehaviorSpriteMapping05-*  ; was: off_E9E08
                                        ; ROM:000E9E18   o
                dc.w    4
                dc.w    Enemy_BehaviorSpriteMapping06-*
                dc.w    4
                dc.w    Enemy_BehaviorSpriteMapping07-*
                dc.w    4
                dc.w    Enemy_BehaviorSpriteMapping08-*
                dc.w    4
                dc.w    Enemy_BehaviorMovementSpriteAnimation-*
                dc.w    0
Enemy_BehaviorWaitSpriteAnimation:  dc.w    Enemy_BehaviorSpriteMapping00-*  ; was: off_E9E1C
                                        ; ROM:000E9E3C   o
                dc.w    6
                dc.w    Enemy_BehaviorSpriteMapping01-*
                dc.w    5
                dc.w    Enemy_BehaviorSpriteMapping02-*
                dc.w    4
                dc.w    Enemy_BehaviorSpriteMapping03-*
                dc.w    5
                dc.w    Enemy_BehaviorSpriteMapping04-*
                dc.w    6
                dc.w    Enemy_BehaviorSpriteMapping03-*
                dc.w    5
                dc.w    Enemy_BehaviorSpriteMapping02-*
                dc.w    4
                dc.w    Enemy_BehaviorSpriteMapping01-*
                dc.w    5
                dc.w    Enemy_BehaviorWaitSpriteAnimation-*
                dc.w    0
Enemy_BehaviorGroundedSpriteAnimation:  dc.w    Enemy_BehaviorSpriteMapping00-*  ; was: off_E9E40
                dc.w    1
                dc.w    Enemy_BehaviorSpriteMapping01-*
                dc.w    1
                dc.w    Enemy_BehaviorSpriteMapping02-*
                dc.w    2
                dc.w    Enemy_BehaviorSpriteMapping03-*
                dc.w    3
                dc.w    Enemy_BehaviorSpriteMapping04-*
                dc.w    4
                dc.w    Enemy_BehaviorSpriteMapping04-*
                dc.w    3
                dc.w    Enemy_BehaviorSpriteMapping03-*
                dc.w    2
                dc.w    Enemy_BehaviorSpriteMapping02-*
                dc.w    1
                dc.w    Enemy_BehaviorSpriteMapping01-*
                dc.w    1
                dc.w    Enemy_BehaviorSpriteMapping00-*
                dc.w    $FF
; Attack-cooldown frames end in a $FF timer that holds the final mapping
Enemy_BehaviorAttackCooldownSpriteAnimation:    dc.w    Enemy_BehaviorSpriteMapping00-*  ; was: off_E9E68
                dc.w    3
                dc.w    Enemy_BehaviorSpriteMapping09-*
                dc.w    6
                dc.w    Enemy_BehaviorSpriteMapping10-*
                dc.w    8
                dc.w    Enemy_BehaviorSpriteMapping11-*
                dc.w    $10
                dc.w    Enemy_BehaviorSpriteMapping10-*
                dc.w    8
                dc.w    Enemy_BehaviorSpriteMapping09-*
                dc.w    $FF
; Defeat frames return to the first mapping through a zero-timer jump
Enemy_BehaviorDefeatSpriteAnimation:    dc.w    Enemy_BehaviorSpriteMapping12-*  ; was: off_E9E80
                                        ; Enemy_ConvertToDefeatProjectile+10   o
                dc.w    3
                dc.w    Enemy_BehaviorSpriteMapping14-*
                dc.w    2
                dc.w    Enemy_BehaviorSpriteMapping13-*
                dc.w    3
                dc.w    Enemy_BehaviorSpriteMapping14-*
                dc.w    2
                dc.w    Enemy_BehaviorDefeatSpriteAnimation-*
                dc.w    0
PeriodicShotEnemySpriteMapping00:   dc.w    $606F, $500, $6E8  ; was: word_E9E94
                                        ; ROM:000EA02A   o
                dc.w    $686F, $500, $608
                dc.w    $6865, $100, $D2FC
                dc.w    $6000, $A00, $E0E8
                dc.w    $602D, $F00, $F8E0
                dc.w    $605D, $C00, $18E0
                dc.w    $685D, $C00, $1800
                dc.w    $682D, $F00, $F800
                dc.w    $E800, $A00, $E000
PeriodicShotEnemySpriteMapping01:   dc.w    $606B, $500, $8DE  ; was: word_E9ECA
                                        ; ROM:000EA026   o
                dc.w    $686B, $500, $812
                dc.w    $6861, $500, $D2F8
                dc.w    $605D, $C00, $18E0
                dc.w    $685D, $C00, $1800
                dc.w    $6009, $A00, $E0E8
                dc.w    $603D, $F00, $F8E0
                dc.w    $683D, $F00, $F800
                dc.w    $E809, $A00, $E000
PeriodicShotEnemySpriteMapping02:   dc.w    $685D, $C00, $1800  ; was: word_E9F00
                                        ; ROM:000EA022   o
                dc.w    $605D, $C00, $18E0
                dc.w    $6067, $500, $BDA
                dc.w    $6867, $500, $B16
                dc.w    $6861, $500, $D4F8
                dc.w    $604D, $F00, $F9E0
                dc.w    $684D, $F00, $F900
                dc.w    $6012, $A00, $E1E8
                dc.w    $E812, $A00, $E100
PeriodicShotEnemySpriteMapping03:   dc.w    $606F, $500, $4EA  ; was: word_E9F36
                                        ; ROM:000EA02E   o
                dc.w    $686F, $500, $406
                dc.w    $6865, $100, $D1FC
                dc.w    $6000, $A00, $E0E8
                dc.w    $602D, $F00, $F8E0
                dc.w    $605D, $C00, $18E0
                dc.w    $685D, $C00, $1800
                dc.w    $682D, $F00, $F800
                dc.w    $E800, $A00, $E000
PeriodicShotEnemySpriteMapping04:   dc.w    $685D, $C00, $1800  ; was: word_E9F6C
                dc.w    $605D, $C00, $18E0
                dc.w    $6067, $500, $DD8
                dc.w    $6867, $500, $D18
                dc.w    $6861, $500, $D5F8
                dc.w    $604D, $F00, $F9E0
                dc.w    $684D, $F00, $F900
                dc.w    $6012, $A00, $E1E8
                dc.w    $E812, $A00, $E100
PeriodicShotEnemySpriteMapping05:   dc.w    $606F, $500, $4EA  ; was: word_E9FA2
                                        ; ROM:000EA042   o
                dc.w    $686F, $500, $406
                dc.w    $603D, $F00, $F8E0
                dc.w    $683D, $F00, $F800
                dc.w    $6861, $500, $D2F8
                dc.w    $601B, $A00, $E0E8
                dc.w    $681B, $A00, $E000
                dc.w    $605D, $C00, $18E0
                dc.w    $E85D, $C00, $1800
PeriodicShotEnemySpriteMapping06:   dc.w    $685D, $C00, $1800  ; was: word_E9FD8
                dc.w    $605D, $C00, $18E0
                dc.w    $686F, $500, $FE03
                dc.w    $606F, $500, $FEED
                dc.w    $602D, $F00, $F9E0
                dc.w    $682D, $F00, $F900
                dc.w    $6024, $A00, $E1E8
                dc.w    $6824, $A00, $E100
                dc.w    $E861, $500, $D4F9
PeriodicShotEnemyWaitSpriteAnimation:   dc.w    PeriodicShotEnemySpriteMapping03-*  ; was: off_EA00E
                                        ; ROM:000EA032   o
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping00-*
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping01-*
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping02-*
                dc.w    3
                dc.w    PeriodicShotEnemySpriteMapping04-*
                dc.w    2
                dc.w    PeriodicShotEnemySpriteMapping02-*
                dc.w    3
                dc.w    PeriodicShotEnemySpriteMapping01-*
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping00-*
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping03-*
                dc.w    4
                dc.w    PeriodicShotEnemyWaitSpriteAnimation-*
                dc.w    0
PeriodicShotEnemyAttackSpriteAnimation: dc.w    PeriodicShotEnemySpriteMapping00-*  ; was: off_EA036
                                        ; ROM:000EA046   o
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping05-*
                dc.w    5
                dc.w    PeriodicShotEnemySpriteMapping06-*
                dc.w    6
                dc.w    PeriodicShotEnemySpriteMapping05-*
                dc.w    5
                dc.w    PeriodicShotEnemyAttackSpriteAnimation-*
                dc.w    0
PeriodicShotEnemyTransitionSpriteAnimation: dc.w    PeriodicShotEnemySpriteMapping00-*  ; was: off_EA04A
                                        ; ROM:000EA056   o
                dc.w    4
                dc.w    PeriodicShotEnemySpriteMapping05-*
                dc.w    3
                dc.w    PeriodicShotEnemySpriteMapping03-*
                dc.w    2
                dc.w    PeriodicShotEnemyTransitionSpriteAnimation-*
                dc.w    0
