; Relative-offset animation streams for shared combat sprite frames
; ---------------------------------------------------------------------------
; Anim_ResolveTimedMappingFrame reads frame-relative offsets paired with timing words
; The ordinary Sprite_RenderObjectList draw path passes the mapping to Sprite_RenderMapping
SharedCombatSpriteAnimation00:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E953C
                                        ; ROM:Boss_ZLeoParticleSpritePointers   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame02-*
                dc.w    4
                dc.w    SharedCombatSpriteFrame03-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame04-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame05-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame05-*
                dc.w    $FF
SharedCombatSpriteAnimation01:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E9560
                                        ; sub_17678:Orphaned_PlayerSpawnRadialShotLoop   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame02-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame03-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame04-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame05-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame05-*
                dc.w    $FF
SharedCombatSpriteAnimation02:  dc.w    SharedCombatSpriteFrame07-*  ; was: off_E9584
                                        ; ROM:00022564   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame02-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame03-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame04-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame05-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame05-*
                dc.w    $FF
SharedCombatSpriteAnimation03:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E95A4
                                        ; ROM:0002256C   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame21-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame22-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame23-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame24-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame25-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame25-*
                dc.w    $FF
SharedCombatSpriteAnimation04:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E95C0
                                        ; ROM:00031E88   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame21-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame22-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame23-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame24-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame25-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame25-*
                dc.w    $FF
SharedCombatSpriteAnimation05:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E95DC
                                        ; Enemy_SpawnQuadProjectiles+2   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame08-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame06-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame26-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame27-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame28-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame29-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame30-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame30-*
                dc.w    $FF
SharedCombatSpriteAnimation06:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E9604
                                        ; ROM:Projectile_FixedAngleDelayedCollisionShotDescriptor   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame08-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame06-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame26-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame27-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame28-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame29-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame30-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame30-*
                dc.w    $FF
SharedCombatSpriteAnimation07:  dc.w    SharedCombatSpriteFrame31-*  ; was: off_E962C
                                        ; ROM:000E9634   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame32-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation07-*
                dc.w    0
SharedCombatSpriteAnimation08:  dc.w    SharedCombatSpriteFrame33-*  ; was: off_E9638
                                        ; ROM:000E9648   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame35-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame34-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame35-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation08-*
                dc.w    0
SharedCombatSpriteAnimation09:  dc.w    SharedCombatSpriteFrame31-*  ; was: off_E964C
                dc.w    1
                dc.w    SharedCombatSpriteFrame33-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame32-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame34-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation09-*
                dc.w    0
SharedCombatSpriteAnimation10:  dc.w    SharedCombatSpriteFrame35-*  ; was: off_E9660
                dc.w    1
                dc.w    SharedCombatSpriteFrame36-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation10-*
                dc.w    0
SharedCombatSpriteAnimation11:  dc.w    SharedCombatSpriteFrame35-*  ; was: off_E966C
                dc.w    1
                dc.w    SharedCombatSpriteFrame36-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation11-*
                dc.w    0
                dc.w    SharedCombatSpriteFrame36-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame35-*
                dc.w    $FF
SharedCombatSpriteAnimation12:  dc.w    SharedCombatSpriteFrame37-*  ; was: off_E9680
                                        ; Projectile_InitializeDifficultyScaledTwoSpeedShot+34   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame38-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation12-*
                dc.w    0
SharedCombatSpriteAnimation13:  dc.w    SharedCombatSpriteFrame37-*  ; was: off_E968C
                                        ; Projectile_SpawnFragmentCluster+10   o
                dc.w    2
                dc.w    SharedCombatSpriteFrame38-*
                dc.w    2
                dc.w    SharedCombatSpriteAnimation13-*
                dc.w    0
SharedCombatSpriteAnimation14:  dc.w    SharedCombatSpriteFrame37-*  ; was: off_E9698
                                        ; ROM:000E96A8   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame32-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame38-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame31-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation14-*
                dc.w    0
SharedCombatSpriteAnimation15:  dc.w    SharedCombatSpriteFrame37-*  ; was: off_E96AC
                dc.w    1
                dc.w    SharedCombatSpriteFrame21-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame38-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation15-*
                dc.w    0
                dc.w    SharedCombatSpriteFrame39-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame39-*
                dc.w    6
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    6
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame39-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    $FF
SharedCombatSpriteAnimation16:  dc.w    SharedCombatSpriteFrame40-*  ; was: off_E96E0
                                        ; ROM:Projectile_FixedAngleDelayedCollisionShotDescriptor   o
                dc.w    2
                dc.w    SharedCombatSpriteFrame42-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame41-*
                dc.w    2
                dc.w    SharedCombatSpriteAnimation16-*
                dc.w    0
SharedCombatSpriteAnimation17:  dc.w    SharedCombatSpriteFrame40-*  ; was: off_E96F0
                dc.w    2
                dc.w    SharedCombatSpriteFrame41-*
                dc.w    2
                dc.w    SharedCombatSpriteAnimation17-*
                dc.w    0
SharedCombatSpriteAnimation18:  dc.w    SharedCombatSpriteFrame56-*  ; was: off_E96FC
                                        ; Boss_ViblackSpawnTransitionDebris+4E   o
                dc.w    3
                dc.w    SharedCombatSpriteFrame57-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame58-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    3
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
SharedCombatSpriteAnimation19:  dc.w    SharedCombatSpriteFrame56-*  ; was: off_E9710
                dc.w    5
                dc.w    SharedCombatSpriteFrame57-*
                dc.w    5
                dc.w    SharedCombatSpriteFrame58-*
                dc.w    5
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    5
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
SharedCombatSpriteAnimation20:  dc.w    SharedCombatSpriteFrame56-*  ; was: off_E9724
                dc.w    1
                dc.w    SharedCombatSpriteFrame57-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame58-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
SharedCombatSpriteAnimation21:  dc.w    SharedCombatSpriteFrame06-*  ; was: off_E9738
                dc.w    1
                dc.w    SharedCombatSpriteFrame56-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame57-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame58-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame42-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame41-*
                dc.w    $FF
SharedCombatSpriteAnimation22:  dc.w    SharedCombatSpriteFrame67-*  ; was: off_E975C
                                        ; Projectile_SpawnTrailingArcHazardType1D0+28   o
                dc.w    $20
                dc.w    SharedCombatSpriteFrame40-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame68-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame69-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame68-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation22-*
                dc.w    0
SharedCombatSpriteAnimation23:  dc.w    SharedCombatSpriteFrame09-*  ; was: off_E9774
                dc.w    1
                dc.w    SharedCombatSpriteFrame11-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame10-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame12-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation23-*
                dc.w    0
SharedCombatSpriteAnimation24:  dc.w    SharedCombatSpriteFrame09-*  ; was: off_E9788
                                        ; Projectile_UpdateType254TwoSpeedShotCollision+3E   o
                dc.w    2
                dc.w    SharedCombatSpriteFrame11-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame10-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame12-*
                dc.w    2
                dc.w    SharedCombatSpriteAnimation24-*
                dc.w    0
SharedCombatSpriteAnimation25:  dc.w    SharedCombatSpriteFrame18-*  ; was: off_E979C
                dc.w    $18
                dc.w    SharedCombatSpriteFrame16-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame17-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame20-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame17-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame16-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation25-*
                dc.w    0
SharedCombatSpriteAnimation26:  dc.w    SharedCombatSpriteFrame19-*  ; was: off_E97B8
                                        ; ROM:000E97D0   o
                dc.w    $18
                dc.w    SharedCombatSpriteFrame43-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame44-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame45-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame44-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame43-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation26-*
                dc.w    0
SharedCombatSpriteAnimation27:  dc.w    SharedCombatSpriteFrame14-*  ; was: off_E97D4
                                        ; ROM:000E97DC   o
                dc.w    8
                dc.w    SharedCombatSpriteFrame56-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation27-*
                dc.w    0
SharedCombatSpriteAnimation28:  dc.w    SharedCombatSpriteFrame13-*  ; was: off_E97E0
                                        ; ROM:000E97E8   o
                dc.w    8
                dc.w    SharedCombatSpriteFrame15-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation28-*
                dc.w    0
SharedCombatSpriteAnimation29:  dc.w    SharedCombatSpriteFrame48-*  ; was: off_E97EC
                dc.w    1
                dc.w    SharedCombatSpriteFrame47-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame46-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame37-*
                dc.w    5
                dc.w    SharedCombatSpriteAnimation29-*
                dc.w    0
Player_CounterForceEffectAnimation: dc.w    SharedCombatSpriteFrame40-*  ; was: off_E9800
                dc.w    1
                dc.w    SharedCombatSpriteFrame06-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    $FF
SharedCombatSpriteAnimation31:  dc.w    SharedCombatSpriteFrame49-*  ; was: off_E9818
                dc.w    1
                dc.w    SharedCombatSpriteFrame50-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame51-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame52-*
                dc.w    1
                dc.w    SharedCombatSpriteAnimation31-*
                dc.w    0
                dc.w    SharedCombatSpriteFrame07-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame53-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame54-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame55-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame60-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame61-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
SharedCombatSpriteAnimation32:  dc.w    SharedCombatSpriteFrame01-*  ; was: off_E9850
                                        ; Projectile_ZLeoExpandingOrbitLaserMain+120   o
                dc.w    1
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame53-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame54-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame55-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame60-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame61-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
SharedCombatSpriteAnimation33:  dc.w    SharedCombatSpriteFrame00-*  ; was: off_E9870
                dc.w    1
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame62-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame63-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame64-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame65-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame66-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
                dc.w    SharedCombatSpriteFrame00-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame01-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame62-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame63-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame64-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame65-*
                dc.w    2
                dc.w    SharedCombatSpriteFrame66-*
                dc.w    1
                dc.w    SharedCombatSpriteFrame59-*
                dc.w    $FF
