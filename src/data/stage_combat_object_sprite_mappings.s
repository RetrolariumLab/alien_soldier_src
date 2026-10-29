; Damageable terminal and ordinary-segment mappings for Gusthead's linked chain
EntityType390_TerminalMapping:  dc.w    $6010, $F00, $E0  ; was: word_EB338
                dc.w    $6000, $F00, $E0E0
                dc.w    $6810, $F00, 0
                dc.w    $E800, $F00, $E000
EntityType390_SegmentMapping:               dc.w    $E820, $A00, $F4F4  ; was: word_EB350
Stage11_RisingHazardLauncherSpriteMapping:  dc.w    $6816, $700, $F4EA  ; was: word_EB356
                dc.w    $6806, $F00, $F4FA
                dc.w    $6802, $C00, $ECF4
                dc.w    $E800, $400, $E402
Stage15_FallingRockSpriteMapping:   dc.w    $4009, $A00, $E8  ; was: word_EB36E
                dc.w    $4809, $A00, 0
                dc.w    $4000, $A00, $E8E8
                dc.w    $C800, $A00, $E800
Stage15_FragmentEmitterSpriteMapping:   dc.w    $4812, $E00, $F600  ; was: word_EB386
                dc.w    $C81E, $F00, $F0E0
Enemy_FormationWaveSpriteMapping00: dc.w    $6804, $D00, $F0  ; was: word_EB392
                dc.w    $6000, $500, $F0F0
                dc.w    $E800, $500, $F000
Enemy_FormationWaveSpriteMapping01: dc.w    $680C, $D00, $F0  ; was: word_EB3A4
                dc.w    $6000, $500, $F0F0
                dc.w    $E800, $500, $F000
Enemy_FormationWaveSpriteMapping02: dc.w    $6814, $D00, $F0  ; was: word_EB3B6
                dc.w    $6000, $500, $F0F0
                dc.w    $E800, $500, $F000
Enemy_FormationWaveSpriteAnimation: dc.w    Enemy_FormationWaveSpriteMapping00-*  ; was: off_EB3C8
                                        ; ROM:000EB3D4   o
                dc.w    3
                dc.w    Enemy_FormationWaveSpriteMapping01-*
                dc.w    3
                dc.w    Enemy_FormationWaveSpriteMapping02-*
                dc.w    3
                dc.w    Enemy_FormationWaveSpriteAnimation-*
                dc.w    0
Projectile_MissirayVerticalShotSpriteMapping00: dc.w    $6800, $700, $E5F8  ; was: word_EB3D8
                                        ; ROM:Projectile_MissirayFallingShotSpriteAnimation   o
                dc.w    $E808, $700, $FAF8
Projectile_MissirayVerticalShotSpriteMapping01: dc.w    $6800, $700, $E3F8  ; was: word_EB3E4
                dc.w    $E808, $700, $FCF8
Projectile_MissirayVerticalShotSpriteMapping02: dc.w    $6800, $700, $E1F8  ; was: word_EB3F0
                dc.w    $E808, $700, $FEF8
Projectile_MissirayVerticalShotSpriteMapping03: dc.w    $6800, $700, $E0F8  ; was: word_EB3FC
                                        ; Projectile_MissirayFallingShotDescend+14   o
                dc.w    $E808, $700, $FFF8
Enemy_Stage11FishSpriteMapping00:   dc.w    $6842, $D00, $5EF  ; was: word_EB408
                                        ; Enemy_Stage11FishWaitForInnerEdgeState_Finish   o
                dc.w    $6810, $F00, $F600
                dc.w    $684A, $100, $5E7
                dc.w    $6820, $E00, $F6E0
                dc.w    $683A, $100, $E6DF
                dc.w    $682C, $400, $EEF
                dc.w    $E82E, $E00, $DEE7
Enemy_Stage11FishSpriteMapping01:   dc.w    $683A, $100, $E6DF  ; was: word_EB432
                                        ; Enemy_Stage11FishBrakeInwardMotionState_Finish   o
                dc.w    $6852, $700, $5EF
                dc.w    $684C, $600, $5FF
                dc.w    $6820, $E00, $F6E0
                dc.w    $6810, $F00, $F600
                dc.w    $682C, $400, $EEF
                dc.w    $E82E, $E00, $DEE7
Enemy_Stage11FishSpriteMapping02:   dc.w    $6860, $600, $F4ED  ; was: word_EB45C
                dc.w    $685A, $600, $FCFD
                dc.w    $6820, $E00, $F6E0
                dc.w    $6810, $F00, $F600
                dc.w    $683A, $100, $E6DF
                dc.w    $682C, $400, $EEF
                dc.w    $E82E, $E00, $DEE7
Enemy_Stage11FishSpriteMapping03:   dc.w    $683C, $C00, $F6  ; was: word_EB486
                dc.w    $E840, $400, $F8F6
Projectile_MissirayFallingShotSpriteAnimation:  dc.w    Projectile_MissirayVerticalShotSpriteMapping00-*  ; was: off_EB492
                dc.w    1
                dc.w    Projectile_MissirayVerticalShotSpriteMapping01-*
                dc.w    1
                dc.w    Projectile_MissirayVerticalShotSpriteMapping02-*
                dc.w    1
                dc.w    Projectile_MissirayVerticalShotSpriteMapping03-*
                dc.w    1
                dc.w    Projectile_MissirayVerticalShotSpriteMapping03-*
                dc.w    $FF
Stage18_SegmentedWormSpriteMapping00:   dc.w    $603A, $600, $F4F0  ; was: word_EB4A6
                                        ; ROM:Stage18_SegmentedWormDirectionFramesA   o
                dc.w    $E800, $A00, $F400
Stage18_SegmentedWormSpriteMapping01:   dc.w    $6809, 0, $F313  ; was: word_EB4B2
                                        ; ROM:00030098   o
                dc.w    $6819, 0, $BFB
                dc.w    $6816, $800, $3F3
                dc.w    $E80A, $E00, $EBF3
Stage18_SegmentedWormSpriteMapping02:   dc.w    $7823, $900, $F6  ; was: word_EB4CA
                                        ; ROM:00030094   o
                dc.w    $E81A, $A00, $E8F6
Stage18_SegmentedWormSpriteMapping03:   dc.w    $6838, 0, $FBED  ; was: word_EB4D6
                                        ; ROM:00030090   o
                dc.w    $6839, 0, $1305
                dc.w    $6835, $200, $F3F5
                dc.w    $E829, $B00, $F3FD
Stage18_SegmentedWormSpriteMapping04:   dc.w    $603A, $600, $F4F0  ; was: word_EB4EE
                                        ; ROM:00030030   o
                dc.w    $E83A, $600, $F400
Stage18_SegmentedWormSpriteMapping05:   dc.w    $6848, $800, $3F3  ; was: word_EB4FA
                                        ; ROM:000300D8   o
                dc.w    $E840, $D00, $F3F3
Stage18_SegmentedWormSpriteMapping06:   dc.w    $7823, $900, $F6  ; was: word_EB506
                                        ; ROM:000300D4   o
                dc.w    $E823, $900, $F0F6
Stage18_SegmentedWormSpriteMapping07:   dc.w    $6048, $800, $4F6  ; was: word_EB512
                                        ; ROM:000300D0   o
                dc.w    $E040, $D00, $F4EE
Stage18_SegmentedWormSpriteMapping08:   dc.w    $685D, 0, $F0F4  ; was: word_EB51E
                                        ; ROM:Stage18_SegmentedWormDirectionFramesC   o
                dc.w    $E855, $D00, $F8EC
Stage18_SegmentedWormSpriteMapping09:   dc.w    $6866, 0, $BF7  ; was: word_EB52A
                                        ; ROM:00030118   o
                dc.w    $6867, $200, $FBEF
                dc.w    $6864, $400, $3F7
                dc.w    $E85E, $900, $F3F7
Stage18_SegmentedWormSpriteMapping10:   dc.w    $6854, 0, $2F0  ; was: word_EB542
                                        ; ROM:00030114   o
                dc.w    $E84C, $700, $F2F8
Stage18_SegmentedWormSpriteMapping11:   dc.w    $6872, 0, $F6ED  ; was: word_EB54E
                                        ; ROM:00030110   o
                dc.w    $6873, $800, $EEED
                dc.w    $6870, $100, $F6F5
                dc.w    $E86A, $600, $F6FD
Stage18_SegmentedWormParticleSpriteAnimation:   dc.w    Stage18_SegmentedWormParticleSpriteMapping01-*  ; was: off_EB566
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping00-*
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping01-*
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping00-*
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping01-*
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping00-*
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping01-*
                dc.w    4
                dc.w    Stage18_SegmentedWormParticleSpriteMapping01-*
                dc.w    $FF
Stage18_SegmentedWormParticleSpriteMapping00:   dc.w    $8876, $500, $F8F8  ; was: word_EB586
                                        ; ROM:000EB572   o
Stage18_SegmentedWormParticleSpriteMapping01:   dc.w    $887A, 0, $FCFC  ; was: word_EB58C
                                        ; ROM:000EB56E   o
Boss_Stage3OrbitingFormationSpriteMapping00:    dc.w    $6812, $400, $FCE0  ; was: word_EB592
                dc.w    $780C, $600, $F0
                dc.w    $680C, $600, $E8F0
                dc.w    $7800, $E00, 0
                dc.w    $E800, $E00, $E800
Boss_Stage3OrbitingFormationSpriteMapping01:    dc.w    $E814, $A00, $F4F4  ; was: word_EB5B0
Boss_CaterpillarFourPhaseSegmentMappingA:       dc.w    $2128, $600, $7F1  ; was: word_EB5B6
                dc.w    $2928, $600, $701
                dc.w    $2122, $600, $EFF1
                dc.w    $A922, $600, $EF01
Boss_CaterpillarFourPhaseSegmentMappingB:   dc.w    $212E, $600, $7F1  ; was: word_EB5CE
                                        ; ROM:0003D386   o
                dc.w    $292E, $600, $701
                dc.w    $2122, $600, $EFF1
                dc.w    $A922, $600, $EF01
