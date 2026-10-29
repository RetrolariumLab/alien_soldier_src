; Relative-offset animation streams for shared combat sprite frames
; ---------------------------------------------------------------------------
; Anim_ResolveTimedMappingFrame reads frame-relative offsets paired with timing words
; The ordinary Sprite_RenderObjectList draw path passes the mapping to Sprite_RenderMapping
Effect_SpriteAnimation00:   dc.w    Effect_SpriteFrame06-*  ; was: off_E953C
                                        ; ROM:Boss_ZLeoParticleSpritePointers   o
                dc.w    1
                dc.w    Effect_SpriteFrame07-*
                dc.w    1
                dc.w    Effect_SpriteFrame00-*
                dc.w    2
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame02-*
                dc.w    4
                dc.w    Effect_SpriteFrame03-*
                dc.w    3
                dc.w    Effect_SpriteFrame04-*
                dc.w    2
                dc.w    Effect_SpriteFrame05-*
                dc.w    2
                dc.w    Effect_SpriteFrame05-*
                dc.w    $FF
Effect_SpriteAnimation01:   dc.w    Effect_SpriteFrame06-*  ; was: off_E9560
                                        ; sub_17678:Orphaned_PlayerSpawnRadialShotLoop   o
                dc.w    1
                dc.w    Effect_SpriteFrame07-*
                dc.w    1
                dc.w    Effect_SpriteFrame00-*
                dc.w    2
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame02-*
                dc.w    3
                dc.w    Effect_SpriteFrame03-*
                dc.w    2
                dc.w    Effect_SpriteFrame04-*
                dc.w    1
                dc.w    Effect_SpriteFrame05-*
                dc.w    1
                dc.w    Effect_SpriteFrame05-*
                dc.w    $FF
Effect_SpriteAnimation02:   dc.w    Effect_SpriteFrame07-*  ; was: off_E9584
                                        ; ROM:00022564   o
                dc.w    1
                dc.w    Effect_SpriteFrame00-*
                dc.w    1
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame02-*
                dc.w    2
                dc.w    Effect_SpriteFrame03-*
                dc.w    1
                dc.w    Effect_SpriteFrame04-*
                dc.w    1
                dc.w    Effect_SpriteFrame05-*
                dc.w    1
                dc.w    Effect_SpriteFrame05-*
                dc.w    $FF
Effect_SpriteAnimation03:   dc.w    Effect_SpriteFrame06-*  ; was: off_E95A4
                                        ; ROM:0002256C   o
                dc.w    1
                dc.w    Effect_SpriteFrame21-*
                dc.w    3
                dc.w    Effect_SpriteFrame22-*
                dc.w    3
                dc.w    Effect_SpriteFrame23-*
                dc.w    3
                dc.w    Effect_SpriteFrame24-*
                dc.w    3
                dc.w    Effect_SpriteFrame25-*
                dc.w    2
                dc.w    Effect_SpriteFrame25-*
                dc.w    $FF
Effect_SpriteAnimation04:   dc.w    Effect_SpriteFrame06-*  ; was: off_E95C0
                                        ; ROM:00031E88   o
                dc.w    1
                dc.w    Effect_SpriteFrame21-*
                dc.w    2
                dc.w    Effect_SpriteFrame22-*
                dc.w    2
                dc.w    Effect_SpriteFrame23-*
                dc.w    2
                dc.w    Effect_SpriteFrame24-*
                dc.w    2
                dc.w    Effect_SpriteFrame25-*
                dc.w    1
                dc.w    Effect_SpriteFrame25-*
                dc.w    $FF
Effect_SpriteAnimation05:   dc.w    Effect_SpriteFrame06-*  ; was: off_E95DC
                                        ; Enemy_SpawnQuadProjectiles+2   o
                dc.w    1
                dc.w    Effect_SpriteFrame07-*
                dc.w    1
                dc.w    Effect_SpriteFrame08-*
                dc.w    1
                dc.w    Effect_SpriteFrame06-*
                dc.w    1
                dc.w    Effect_SpriteFrame26-*
                dc.w    2
                dc.w    Effect_SpriteFrame27-*
                dc.w    3
                dc.w    Effect_SpriteFrame28-*
                dc.w    3
                dc.w    Effect_SpriteFrame29-*
                dc.w    3
                dc.w    Effect_SpriteFrame30-*
                dc.w    2
                dc.w    Effect_SpriteFrame30-*
                dc.w    $FF
Effect_SpriteAnimation06:   dc.w    Effect_SpriteFrame06-*  ; was: off_E9604
                                        ; ROM:Projectile_FixedAngleDelayedCollisionShotDescriptor   o
                dc.w    1
                dc.w    Effect_SpriteFrame07-*
                dc.w    1
                dc.w    Effect_SpriteFrame08-*
                dc.w    1
                dc.w    Effect_SpriteFrame06-*
                dc.w    1
                dc.w    Effect_SpriteFrame26-*
                dc.w    1
                dc.w    Effect_SpriteFrame27-*
                dc.w    2
                dc.w    Effect_SpriteFrame28-*
                dc.w    2
                dc.w    Effect_SpriteFrame29-*
                dc.w    2
                dc.w    Effect_SpriteFrame30-*
                dc.w    1
                dc.w    Effect_SpriteFrame30-*
                dc.w    $FF
Effect_SpriteAnimation07:   dc.w    Effect_SpriteFrame31-*  ; was: off_E962C
                                        ; ROM:000E9634   o
                dc.w    1
                dc.w    Effect_SpriteFrame32-*
                dc.w    1
                dc.w    Effect_SpriteAnimation07-*
                dc.w    0
Effect_SpriteAnimation08:   dc.w    Effect_SpriteFrame33-*  ; was: off_E9638
                                        ; ROM:000E9648   o
                dc.w    1
                dc.w    Effect_SpriteFrame35-*
                dc.w    1
                dc.w    Effect_SpriteFrame34-*
                dc.w    1
                dc.w    Effect_SpriteFrame35-*
                dc.w    1
                dc.w    Effect_SpriteAnimation08-*
                dc.w    0
Effect_SpriteAnimation09:   dc.w    Effect_SpriteFrame31-*  ; was: off_E964C
                dc.w    1
                dc.w    Effect_SpriteFrame33-*
                dc.w    1
                dc.w    Effect_SpriteFrame32-*
                dc.w    1
                dc.w    Effect_SpriteFrame34-*
                dc.w    1
                dc.w    Effect_SpriteAnimation09-*
                dc.w    0
Effect_SpriteAnimation10:   dc.w    Effect_SpriteFrame35-*  ; was: off_E9660
                dc.w    1
                dc.w    Effect_SpriteFrame36-*
                dc.w    1
                dc.w    Effect_SpriteAnimation10-*
                dc.w    0
Effect_SpriteAnimation11:   dc.w    Effect_SpriteFrame35-*  ; was: off_E966C
                dc.w    1
                dc.w    Effect_SpriteFrame36-*
                dc.w    1
                dc.w    Effect_SpriteAnimation11-*
                dc.w    0
                dc.w    Effect_SpriteFrame36-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame35-*
                dc.w    $FF
Effect_SpriteAnimation12:   dc.w    Effect_SpriteFrame37-*  ; was: off_E9680
                                        ; Projectile_InitializeDifficultyScaledTwoSpeedShot+34   o
                dc.w    1
                dc.w    Effect_SpriteFrame38-*
                dc.w    1
                dc.w    Effect_SpriteAnimation12-*
                dc.w    0
Effect_SpriteAnimation13:   dc.w    Effect_SpriteFrame37-*  ; was: off_E968C
                                        ; Projectile_SpawnFragmentCluster+10   o
                dc.w    2
                dc.w    Effect_SpriteFrame38-*
                dc.w    2
                dc.w    Effect_SpriteAnimation13-*
                dc.w    0
Effect_SpriteAnimation14:   dc.w    Effect_SpriteFrame37-*  ; was: off_E9698
                                        ; ROM:000E96A8   o
                dc.w    1
                dc.w    Effect_SpriteFrame32-*
                dc.w    1
                dc.w    Effect_SpriteFrame38-*
                dc.w    1
                dc.w    Effect_SpriteFrame31-*
                dc.w    1
                dc.w    Effect_SpriteAnimation14-*
                dc.w    0
Effect_SpriteAnimation15:   dc.w    Effect_SpriteFrame37-*  ; was: off_E96AC
                dc.w    1
                dc.w    Effect_SpriteFrame21-*
                dc.w    1
                dc.w    Effect_SpriteFrame38-*
                dc.w    1
                dc.w    Effect_SpriteAnimation15-*
                dc.w    0
                dc.w    Effect_SpriteFrame39-*
                dc.w    3
                dc.w    Effect_SpriteFrame40-*
                dc.w    3
                dc.w    Effect_SpriteFrame40-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame39-*
                dc.w    6
                dc.w    Effect_SpriteFrame40-*
                dc.w    6
                dc.w    Effect_SpriteFrame40-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame39-*
                dc.w    1
                dc.w    Effect_SpriteFrame40-*
                dc.w    1
                dc.w    Effect_SpriteFrame40-*
                dc.w    $FF
Effect_SpriteAnimation16:   dc.w    Effect_SpriteFrame40-*  ; was: off_E96E0
                                        ; ROM:Projectile_FixedAngleDelayedCollisionShotDescriptor   o
                dc.w    2
                dc.w    Effect_SpriteFrame42-*
                dc.w    2
                dc.w    Effect_SpriteFrame41-*
                dc.w    2
                dc.w    Effect_SpriteAnimation16-*
                dc.w    0
Effect_SpriteAnimation17:   dc.w    Effect_SpriteFrame40-*  ; was: off_E96F0
                dc.w    2
                dc.w    Effect_SpriteFrame41-*
                dc.w    2
                dc.w    Effect_SpriteAnimation17-*
                dc.w    0
Effect_SpriteAnimation18:   dc.w    Effect_SpriteFrame56-*  ; was: off_E96FC
                                        ; Boss_ViblackSpawnTransitionDebris+4E   o
                dc.w    3
                dc.w    Effect_SpriteFrame57-*
                dc.w    3
                dc.w    Effect_SpriteFrame58-*
                dc.w    3
                dc.w    Effect_SpriteFrame59-*
                dc.w    3
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
Effect_SpriteAnimation19:   dc.w    Effect_SpriteFrame56-*  ; was: off_E9710
                dc.w    5
                dc.w    Effect_SpriteFrame57-*
                dc.w    5
                dc.w    Effect_SpriteFrame58-*
                dc.w    5
                dc.w    Effect_SpriteFrame59-*
                dc.w    5
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
Effect_SpriteAnimation20:   dc.w    Effect_SpriteFrame56-*  ; was: off_E9724
                dc.w    1
                dc.w    Effect_SpriteFrame57-*
                dc.w    1
                dc.w    Effect_SpriteFrame58-*
                dc.w    1
                dc.w    Effect_SpriteFrame59-*
                dc.w    1
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
Effect_SpriteAnimation21:   dc.w    Effect_SpriteFrame06-*  ; was: off_E9738
                dc.w    1
                dc.w    Effect_SpriteFrame56-*
                dc.w    2
                dc.w    Effect_SpriteFrame57-*
                dc.w    2
                dc.w    Effect_SpriteFrame58-*
                dc.w    2
                dc.w    Effect_SpriteFrame59-*
                dc.w    2
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame40-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame42-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame41-*
                dc.w    $FF
Effect_SpriteAnimation22:   dc.w    Effect_SpriteFrame67-*  ; was: off_E975C
                                        ; Projectile_SpawnTrailingArcHazardType1D0+28   o
                dc.w    $20
                dc.w    Effect_SpriteFrame40-*
                dc.w    1
                dc.w    Effect_SpriteFrame68-*
                dc.w    1
                dc.w    Effect_SpriteFrame69-*
                dc.w    1
                dc.w    Effect_SpriteFrame68-*
                dc.w    1
                dc.w    Effect_SpriteAnimation22-*
                dc.w    0
Effect_SpriteAnimation23:   dc.w    Effect_SpriteFrame09-*  ; was: off_E9774
                dc.w    1
                dc.w    Effect_SpriteFrame11-*
                dc.w    1
                dc.w    Effect_SpriteFrame10-*
                dc.w    1
                dc.w    Effect_SpriteFrame12-*
                dc.w    1
                dc.w    Effect_SpriteAnimation23-*
                dc.w    0
Effect_SpriteAnimation24:   dc.w    Effect_SpriteFrame09-*  ; was: off_E9788
                                        ; Projectile_UpdateType254TwoSpeedShotCollision+3E   o
                dc.w    2
                dc.w    Effect_SpriteFrame11-*
                dc.w    2
                dc.w    Effect_SpriteFrame10-*
                dc.w    2
                dc.w    Effect_SpriteFrame12-*
                dc.w    2
                dc.w    Effect_SpriteAnimation24-*
                dc.w    0
Effect_SpriteAnimation25:   dc.w    Effect_SpriteFrame18-*  ; was: off_E979C
                dc.w    $18
                dc.w    Effect_SpriteFrame16-*
                dc.w    1
                dc.w    Effect_SpriteFrame17-*
                dc.w    1
                dc.w    Effect_SpriteFrame20-*
                dc.w    1
                dc.w    Effect_SpriteFrame17-*
                dc.w    1
                dc.w    Effect_SpriteFrame16-*
                dc.w    1
                dc.w    Effect_SpriteAnimation25-*
                dc.w    0
Effect_SpriteAnimation26:   dc.w    Effect_SpriteFrame19-*  ; was: off_E97B8
                                        ; ROM:000E97D0   o
                dc.w    $18
                dc.w    Effect_SpriteFrame43-*
                dc.w    1
                dc.w    Effect_SpriteFrame44-*
                dc.w    1
                dc.w    Effect_SpriteFrame45-*
                dc.w    1
                dc.w    Effect_SpriteFrame44-*
                dc.w    1
                dc.w    Effect_SpriteFrame43-*
                dc.w    1
                dc.w    Effect_SpriteAnimation26-*
                dc.w    0
Effect_SpriteAnimation27:   dc.w    Effect_SpriteFrame14-*  ; was: off_E97D4
                                        ; ROM:000E97DC   o
                dc.w    8
                dc.w    Effect_SpriteFrame56-*
                dc.w    1
                dc.w    Effect_SpriteAnimation27-*
                dc.w    0
Effect_SpriteAnimation28:   dc.w    Effect_SpriteFrame13-*  ; was: off_E97E0
                                        ; ROM:000E97E8   o
                dc.w    8
                dc.w    Effect_SpriteFrame15-*
                dc.w    1
                dc.w    Effect_SpriteAnimation28-*
                dc.w    0
Effect_SpriteAnimation29:   dc.w    Effect_SpriteFrame48-*  ; was: off_E97EC
                dc.w    1
                dc.w    Effect_SpriteFrame47-*
                dc.w    1
                dc.w    Effect_SpriteFrame46-*
                dc.w    1
                dc.w    Effect_SpriteFrame37-*
                dc.w    5
                dc.w    Effect_SpriteAnimation29-*
                dc.w    0
Player_CounterForceEffectAnimation: dc.w    Effect_SpriteFrame40-*  ; was: off_E9800
                dc.w    1
                dc.w    Effect_SpriteFrame06-*
                dc.w    1
                dc.w    Effect_SpriteFrame07-*
                dc.w    2
                dc.w    Effect_SpriteFrame00-*
                dc.w    2
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame07-*
                dc.w    $FF
Effect_SpriteAnimation31:   dc.w    Effect_SpriteFrame49-*  ; was: off_E9818
                dc.w    1
                dc.w    Effect_SpriteFrame50-*
                dc.w    1
                dc.w    Effect_SpriteFrame51-*
                dc.w    1
                dc.w    Effect_SpriteFrame52-*
                dc.w    1
                dc.w    Effect_SpriteAnimation31-*
                dc.w    0
                dc.w    Effect_SpriteFrame07-*
                dc.w    1
                dc.w    Effect_SpriteFrame00-*
                dc.w    1
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame53-*
                dc.w    2
                dc.w    Effect_SpriteFrame54-*
                dc.w    2
                dc.w    Effect_SpriteFrame55-*
                dc.w    2
                dc.w    Effect_SpriteFrame60-*
                dc.w    2
                dc.w    Effect_SpriteFrame61-*
                dc.w    2
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
Effect_SpriteAnimation32:   dc.w    Effect_SpriteFrame01-*  ; was: off_E9850
                                        ; Projectile_ZLeoExpandingOrbitLaserMain+120   o
                dc.w    1
                dc.w    Effect_SpriteFrame00-*
                dc.w    1
                dc.w    Effect_SpriteFrame53-*
                dc.w    1
                dc.w    Effect_SpriteFrame54-*
                dc.w    1
                dc.w    Effect_SpriteFrame55-*
                dc.w    2
                dc.w    Effect_SpriteFrame60-*
                dc.w    1
                dc.w    Effect_SpriteFrame61-*
                dc.w    1
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
Effect_SpriteAnimation33:   dc.w    Effect_SpriteFrame00-*  ; was: off_E9870
                dc.w    1
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame62-*
                dc.w    1
                dc.w    Effect_SpriteFrame63-*
                dc.w    1
                dc.w    Effect_SpriteFrame64-*
                dc.w    2
                dc.w    Effect_SpriteFrame65-*
                dc.w    2
                dc.w    Effect_SpriteFrame66-*
                dc.w    2
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
                dc.w    Effect_SpriteFrame00-*
                dc.w    1
                dc.w    Effect_SpriteFrame01-*
                dc.w    1
                dc.w    Effect_SpriteFrame62-*
                dc.w    1
                dc.w    Effect_SpriteFrame63-*
                dc.w    1
                dc.w    Effect_SpriteFrame64-*
                dc.w    1
                dc.w    Effect_SpriteFrame65-*
                dc.w    2
                dc.w    Effect_SpriteFrame66-*
                dc.w    1
                dc.w    Effect_SpriteFrame59-*
                dc.w    $FF
