Projectile_SpawnSpriteFrames:   dc.l    $1454B, $F00F0F0  ; DATA XREF: Projectile_UpdateDirectionalSpawner+24   o  ; was: dword_2ABF0
                                        ; Projectile_UpdateDirectionalSpawner+A4   o
                dc.l    $1456C, $F00F0F0                ; make offsets?
                dc.l    $14480, $A00F4F4
                dc.l    $34489, $A00F4F4
                dc.l    $34492, $A00F4F4
                dc.l    $3449B, $A00F4F4
                dc.l    $244A4, $500F8F8
                dc.l    $144A8, $500F8F8
                dc.w    $FFFF
Projectile_ArtemisReflectedShotSpriteFrames:    dc.l    $1454B, $F00F0F0  ; DATA XREF: Projectile_SpawnArtemisReflectedShot+10   o  ; was: dword_2AC32
                dc.l    $1456C, $F00F0F0
                dc.l    $24480, $A00F4F4
                dc.l    $24489, $A00F4F4
                dc.l    $24492, $A00F4F4
                dc.l    $2449B, $A00F4F4
                dc.l    $144A4, $500F8F8
                dc.l    $144A8, $500F8F8
                dc.w    $FFFF
Effect_ParticleLoopSpriteFrames:    dc.l    $24480, $A00F4F4  ; DATA XREF: Effect_SpawnParticleLoop+22   o  ; was: dword_2AC74
                dc.l    $24489, $A00F4F4
                dc.l    $24492, $A00F4F4
                dc.l    $2449B, $A00F4F4
                dc.l    $244A4, $500F8F8
                dc.l    $244A8, $500F8F8
                dc.w    $FFFF
Weapon_ImpactSpriteFrames:  dc.l    $244AC, $500F8F8    ; DATA XREF: Weapon_HandleProjectileHit+20   o  ; was: dword_2ACA6
                                        ; Weapon_HandleExplosiveImpact+72   o
                dc.l    $244B0, $500F8F8
                dc.l    $244B4, $500F8F8
                dc.l    $244B8, $500F8F8
                dc.l    $144E8, $500F8F8
                dc.w    $FFFF
Projectile_TerobusterGravityShotSpriteFrames:   dc.l    $244F6, $FCFC  ; DATA XREF: Projectile_InitializeTerobusterGravityShot+A   o  ; was: dword_2ACD0
                dc.l    $244F7, $FCFC
                dc.l    $244F8, $FCFC
                dc.l    $24CF7, $FCFC
                dc.l    $24CF6, $FCFC
                dc.l    $25CF7, $FCFC
                dc.l    $254F8, $FCFC
                dc.l    $254F7, $FCFC
                dc.l    $FFFF0002
                dc.w    Projectile_TerobusterGravityShotSpriteFrames-$20000
Effect_KnockbackImpactSpriteFrames: dc.l    $244AC, $500F8F8  ; DATA XREF: Effect_UpdateKnockbackParticle+70   o  ; was: dword_2AD16
                                        ; Projectile_UpdateEightDirectionShotCollision+A0   o
                dc.l    $244C4, $500F8F8
                dc.w    $FFFF
Boss_TerobusterProjectileSpriteFrames:  dc.l    $364CC, $500F8F8  ; DATA XREF: Boss_TerobusterDefeatDebrisState+4A   o  ; was: dword_2AD28
                                        ; Boss_TerobusterSpawnProjectile+12   o
                dc.l    $264D0, $500F8F8
                dc.l    $264D4, $FCFC
                dc.l    $264D5, $FCFC
                dc.w    $FFFF
Boss_ViblackAndWolfGaropaShotSpriteFrames:  dc.l    $344CC, $500F8F8  ; DATA XREF: Boss_ViblackRadialShotAttackState:Boss_ViblackInitializeStandardRadialShot   o  ; was: dword_2AD4A
                                        ; Boss_WolfGaropaSpawnOrbitSpark+20   o
                dc.l    $244D0, $500F8F8
                dc.l    $244D4, $FCFC
                dc.l    $244D5, $FCFC
                dc.w    $FFFF
Projectile_HomingAndRockSpriteFrames:   dc.l    $24480, $A00F4F4  ; DATA XREF: Projectile_TerobusterHomingMissileUpdate+80   o  ; was: dword_2AD6C
                                        ; Boss_TerobusterSpawnFallingRock+40   o
                dc.l    $244CC, $500F8F8
                dc.l    $244D0, $500F8F8
                dc.l    $144D4, $FCFC
                dc.l    $144D5, $FCFC
                dc.w    $FFFF
                dc.l    $244FA, $FCFC
                dc.l    $244FB, $FCFC
                dc.l    $244FA, $FCFC
                dc.l    $244FB, $FCFC
                dc.l    $144FC, $FCFC
                dc.l    $144FD, $FCFC
                dc.w    $FFFF
Weapon_SharedShotInitialSpriteFrame:    dc.l    $24480, $A00F4F4  ; DATA XREF: Weapon_InitSpreadShot+16   o  ; was: dword_2ADC8
                                        ; Projectile_InitializeEpsilon1SpreadSlot+16   o
Weapon_ProjectileSpriteFrames:  dc.l    $244D6, $A00F4F4  ; DATA XREF: Weapon_FireProjectile+70   o  ; was: dword_2ADD0
                dc.l    $244DF, $A00F4F4
                dc.l    $244D6, $A00F4F4
                dc.l    $244BC, $500F8F8
                dc.l    $244C0, $500F8F8
                dc.w    $FFFF
Effect_DashTrailPrimarySpriteFrames:    dc.l    $24562, $FCFC  ; DATA XREF: Effect_CreateDashTrail+80   o  ; was: dword_2ADFA
                dc.l    $34561, $400F8FC
                dc.l    $44560, $800F4FC
                dc.w    $FFFF
Effect_DashTrailSecondarySpriteFrames:  dc.l    $24D62, $FCFC  ; DATA XREF: Effect_CreateDashTrail+92   o  ; was: dword_2AE14
                dc.l    $34D61, $400F8FC
                dc.l    $44D60, $800F4FC
                dc.w    $FFFF
Effect_SharedBurstParticleSpriteFrames: dc.l    $4455D, $200FCF4  ; DATA XREF: XiTigerCutscene_SpawnRandomParticle+2A   o  ; was: dword_2AE2E
                                        ; Boss_ViblackSpawnDefeatParticle+34   o
                dc.l    $4455E, $100FCF8
                dc.l    $4455F, $FCFC
                dc.w    $FFFF
XiTigerCutscene_MarkerSpriteFrames: dc.l    $244D6, $A00F4F4  ; DATA XREF: XiTigerCutscene_SpawnMarker+14   o  ; was: dword_2AE48
                dc.l    $244DF, $A00F4F4
Effect_SharedParticleSpriteFrames:  dc.l    $244BC, $500F8F8  ; DATA XREF: Effect_SpawnParticle+1E   o  ; was: dword_2AE58
                                        ; Player_SpawnPhoenixParticles+3E   o
                dc.l    $244C0, $500F8F8
                dc.l    $144F2, $FCFC
                dc.l    $244F3, $FCFC
                dc.l    $144F4, $FCFC
                dc.l    $144F5, $FCFC
                dc.w    $FFFF
Effect_KnockbackParticleSpriteFrames:   dc.l    $1454B, $F00F0F0  ; DATA XREF: Effect_UpdateKnockbackParticle+3E   o  ; was: dword_2AE8A
                dc.l    $1456C, $F00F0F0
                dc.l    $24480, $A00F4F4
                dc.l    $24489, $A00F4F4
                dc.l    $14492, $A00F4F4
                dc.l    $1449B, $A00F4F4
                dc.l    $144A4, $500F8F8
                dc.l    $144A8, $500F8F8
                dc.w    $FFFF
Projectile_CollisionSpriteFrames:   dc.l    $144D6, $A00F4F4  ; DATA XREF: Weapon_HandleSeekingProjectileCollision+E   o  ; was: dword_2AECC
                dc.l    $244DF, $A00F4F4
                dc.l    $244D6, $A00F4F4
                dc.l    $244DF, $A00F4F4
                dc.l    $144BC, $500F8F8
                dc.l    $144C0, $500F8F8
                dc.l    $144BC, $500F8F8
                dc.l    $144C0, $500F8F8
                dc.l    $144F2, $FCFC
                dc.l    $144F3, $FCFC
                dc.w    $FFFF
Projectile_BombAndRadialSpriteFrames:   dc.l    $244D6, $A00F4F4  ; DATA XREF: Weapon_UpdateBombProjectile+10   o  ; was: dword_2AF1E
                                        ; Projectile_SpawnArtemisRadialShot+12   o
                dc.l    $244DF, $A00F4F4
                dc.l    $144BC, $500F8F8
                dc.l    $144C0, $500F8F8
                dc.l    $144F3, $FCFC
                dc.w    $FFFF
Effect_StarParticleSpriteFrames:    dc.l    $844F4, $FCFC  ; DATA XREF: ShipSequence_SpawnStarParticle+A   o  ; was: dword_2AF48
                                        ; sub_18F58   o
                dc.l    $844F5, $FCFC
                dc.w    $FFFF
Effect_ParticlePrimarySpriteFrames: dc.l    $24480, $A00F4F4  ; DATA XREF: Effect_UpdateImpactParticleSpawner+26   o  ; was: dword_2AF5A
                dc.l    $24489, $A00F4F4
                dc.l    $24492, $A00F4F4
                dc.l    $2449B, $A00F4F4
                dc.l    $244A4, $500F8F8
                dc.l    $144A8, $500F8F8
                dc.w    $FFFF
Effect_ParticleSecondarySpriteFrames:   dc.l    $24480, $A00F4F4  ; DATA XREF: Effect_UpdateImpactParticleSpawner+34   o  ; was: dword_2AF8C
                dc.l    $34489, $A00F4F4
                dc.l    $34492, $A00F4F4
                dc.l    $2449B, $A00F4F4
                dc.l    $244A4, $500F8F8
                dc.l    $144A8, $500F8F8
                dc.w    $FFFF
