; Shared projectile mappings

SharedProjectileSpriteMappingA: dc.w    $E8F9, $F00, $F0F0  ; was: word_1A0CA6
                                        ; ROM:SharedProjectileDuration4Animation   o
SharedProjectileSpriteMappingB: dc.w    $E909, $A00, $F4F4  ; was: word_1A0CAC
                                        ; ROM:001A0E9A   o
SharedProjectileSpriteMappingC: dc.w    $E912, $A00, $F4F4  ; was: word_1A0CB2
                                        ; ROM:001A0E9E   o
SharedProjectileSpriteMappingD: dc.w    $E91B, $A00, $F4F4  ; was: word_1A0CB8
                                        ; ROM:001A0EA2   o
; Mappings shared by the Stage 12 floater, Gusthead debris, and a Sharpsteel projectile

Enemy_ShrimpSpriteMappingA: dc.w    $C950, $B00, $F0F4  ; was: word_1A0CBE
                                        ; ROM:001A0F22   o
Enemy_ShrimpSpriteMappingB: dc.w    $C95C, $B00, $F0F4  ; was: word_1A0CC4
                                        ; ROM:001A0F32   o
Enemy_ShrimpSpriteMappingC: dc.w    $C15C, $B00, $F0F4  ; was: word_1A0CCA
                                        ; ROM:001A0F3A   o
; Direct mappings for individual stage objects

Stage10And12_MovingPlatformSpriteMapping:   dc.w    $6170, $E00, $F8E0  ; was: word_1A0CD0
                dc.w    $E970, $E00, $F800
Enemy_FishSpriteMappingA:   dc.w    $C949, $800, $FCF4  ; was: word_1A0CDC
                                        ; ROM:001A0F4A   o
Enemy_FishSpriteMappingB:   dc.w    $D94C, $800, $FAF2  ; was: word_1A0CE2
Enemy_FishSpriteMappingC:   dc.w    $C94C, $800, $FEF2  ; was: word_1A0CE8
; Stage 12 Teddy Bear mapping group

Stage12_TeddyBearSpriteMappingA:    dc.w    $497C, $900, $ECF2  ; was: word_1A0CEE
                                        ; ROM:Stage12_TeddyBearOverwrittenPilotAnimation   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingB:    dc.w    $497C, $900, $EDF1  ; was: word_1A0CFA
                                        ; ROM:001A0ECA   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingC:    dc.w    $4982, $500, $EDF4  ; was: word_1A0D06
                                        ; ROM:001A0EC6   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingD:    dc.w    $4982, $500, $EFF2  ; was: word_1A0D12
                                        ; ROM:001A0EE2   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingE:    dc.w    $4182, $500, $EBFF  ; was: word_1A0D1E
                                        ; ROM:001A0F06   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingF:    dc.w    $4182, $500, $EC00  ; was: word_1A0D2A
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingG:    dc.w    $417C, $900, $EAF8  ; was: word_1A0D36
                                        ; ROM:001A0EF6   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingH:    dc.w    $417C, $900, $EBF9  ; was: word_1A0D42
                                        ; ROM:001A0F02   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingI:    dc.w    $C9AC, $B00, $F0F4  ; was: word_1A0D4E
; Three mappings reused by the Teddy Bear and Stage 15 hazard emitters

SharedTeddyHazardSpriteMappingA:    dc.w    $499F, $900, $F4  ; was: word_1A0D54
                                        ; ROM:SharedTeddyHazardLoopAnimation   o
                dc.w    $4999, $900, $F4EE
                dc.w    $49A5, 0, $80C
                dc.w    $C9B8, 0, 2
SharedTeddyHazardSpriteMappingB:    dc.w    $499F, $900, $F4  ; was: word_1A0D6C
                                        ; ROM:001A0F6E   o
                dc.w    $4999, $900, $F5ED
                dc.w    $49A5, 0, $80C
                dc.w    $C9B8, 0, $FE01
SharedTeddyHazardSpriteMappingC:    dc.w    $499F, $900, $F4  ; was: word_1A0D84
                                        ; ROM:001A0F7E   o
                dc.w    $4999, $900, $F5EC
                dc.w    $49A5, 0, $80C
                dc.w    $C9B8, 0, $FE00
Stage12_TeddyBearSpriteMappingJ:    dc.w    $417C, $900, $E9F6  ; was: word_1A0D9C
                                        ; ROM:Stage12_TeddyBearLandedAnimation   o
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingK:    dc.w    $417C, $900, $EAF7  ; was: word_1A0DBA
                                        ; ROM:001A0F9E   o
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingL:    dc.w    $4182, $500, $EBFB  ; was: word_1A0DD8
                                        ; ROM:001A0F9A   o
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingM:    dc.w    $4182, $500, $EDFC  ; was: word_1A0DF6
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingN:    dc.w    $497C, $900, $EAF2  ; was: word_1A0E14
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingO:    dc.w    $4199, $900, $ECF7  ; was: word_1A0E32
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingP:    dc.w    $4982, $500, $F6EF  ; was: word_1A0E3E
                                        ; ROM:Stage12_TeddyBearInitialPoseAnimation   o
                dc.w    $499F, $900, $F4
                dc.w    $49A5, 0, $80C
                dc.w    $D9B8, 0, $502
Stage12_TeddyBearSpriteMappingQ:    dc.w    $4982, $500, $F6EF  ; was: word_1A0E56
                                        ; ROM:001A0FCA   o
                dc.w    $499F, $900, $F4
                dc.w    $49A5, 0, $80C
                dc.w    $D9B8, 0, $402
Stage12_TeddyBearSpriteMappingR:    dc.w    $4982, $500, $F6EE  ; was: word_1A0E6E
                dc.w    $499F, $900, $F4
                dc.w    $49A5, 0, $80C
                dc.w    $D9B8, 0, $301
; Animation streams

SharedProjectileDuration2Animation: dc.w    SharedProjectileSpriteMappingA-*  ; was: off_1A0E86
                dc.w    2
                dc.w    SharedProjectileSpriteMappingB-*
                dc.w    2
                dc.w    SharedProjectileSpriteMappingC-*
                dc.w    2
                dc.w    SharedProjectileSpriteMappingD-*
                dc.w    $FF
SharedProjectileDuration4Animation: dc.w    SharedProjectileSpriteMappingA-*  ; was: off_1A0E96
                                        ; Projectile_SpawnType1A8AtAngle+12   o
                dc.w    4
                dc.w    SharedProjectileSpriteMappingB-*
                dc.w    4
                dc.w    SharedProjectileSpriteMappingC-*
                dc.w    4
                dc.w    SharedProjectileSpriteMappingD-*
                dc.w    $FF
SharedProjectileDuration8Animation: dc.w    SharedProjectileSpriteMappingA-*  ; was: off_1A0EA6
                dc.w    8
                dc.w    SharedProjectileSpriteMappingB-*
                dc.w    8
                dc.w    SharedProjectileSpriteMappingC-*
                dc.w    8
                dc.w    SharedProjectileSpriteMappingD-*
                dc.w    $FF
Stage12_TeddyBearDropAndPilotAnimation: dc.w    Stage12_TeddyBearSpriteMappingA-*  ; was: off_1A0EB6
                                        ; Stage12_TeddyBearPilotStart+30   o
                dc.w    6
                dc.w    Stage12_TeddyBearSpriteMappingB-*
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingC-*
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingD-*
                dc.w    8
                dc.w    Stage12_TeddyBearSpriteMappingC-*
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingB-*
                dc.w    3
                dc.w    Stage12_TeddyBearDropAndPilotAnimation-*
                dc.w    0
Stage12_TeddyBearOverwrittenPilotAnimation: dc.w    Stage12_TeddyBearSpriteMappingA-*  ; was: off_1A0ED2
                                        ; ROM:001A0EDA   o
                dc.w    8
                dc.w    Stage12_TeddyBearSpriteMappingB-*
                dc.w    8
                dc.w    Stage12_TeddyBearOverwrittenPilotAnimation-*
                dc.w    0
Stage12_TeddyBearBoardingPilotLoopAnimation:    dc.w    Stage12_TeddyBearSpriteMappingC-*  ; was: off_1A0EDE
                                        ; Stage12_TeddyBearFacePlayerDelay+BC   o
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingD-*
                dc.w    3
                dc.w    Stage12_TeddyBearBoardingPilotLoopAnimation-*
                dc.w    0
Stage12_TeddyBearAnimationVariantA: dc.w    Stage12_TeddyBearSpriteMappingE-*  ; was: off_1A0EEA
                dc.w    4
                dc.w    Stage12_TeddyBearSpriteMappingG-*
                dc.w    1
                dc.w    Stage12_TeddyBearSpriteMappingH-*
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingG-*
                dc.w    1
                dc.w    Stage12_TeddyBearAnimationVariantA-*
                dc.w    0
Stage12_TeddyBearAnimationVariantB: dc.w    Stage12_TeddyBearSpriteMappingG-*  ; was: off_1A0EFE
                dc.w    4
                dc.w    Stage12_TeddyBearSpriteMappingH-*
                dc.w    2
                dc.w    Stage12_TeddyBearSpriteMappingE-*
                dc.w    2
                dc.w    Stage12_TeddyBearSpriteMappingF-*
                dc.w    4
                dc.w    Stage12_TeddyBearSpriteMappingE-*
                dc.w    2
                dc.w    Stage12_TeddyBearSpriteMappingH-*
                dc.w    2
                dc.w    Stage12_TeddyBearAnimationVariantB-*
                dc.w    0
Enemy_ShrimpSlowAnimation:  dc.w    Enemy_ShrimpSpriteMappingA-*  ; was: off_1A0F1A
                                        ; ROM:Boss_GustheadShrimpAndFishAnimations   o
                dc.w    5
                dc.w    Enemy_ShrimpSpriteMappingB-*
                dc.w    4
                dc.w    Enemy_ShrimpSpriteMappingA-*
                dc.w    5
                dc.w    Enemy_ShrimpSpriteMappingC-*
                dc.w    4
                dc.w    Enemy_ShrimpSlowAnimation-*
                dc.w    0
Enemy_ShrimpFastAnimation:  dc.w    Enemy_ShrimpSpriteMappingA-*  ; was: off_1A0F2E
                                        ; ROM:00040320   o
                dc.w    3
                dc.w    Enemy_ShrimpSpriteMappingB-*
                dc.w    2
                dc.w    Enemy_ShrimpSpriteMappingA-*
                dc.w    3
                dc.w    Enemy_ShrimpSpriteMappingC-*
                dc.w    2
                dc.w    Enemy_ShrimpFastAnimation-*
                dc.w    0
Enemy_FishLoopAnimation:    dc.w    Enemy_FishSpriteMappingA-*  ; was: off_1A0F42
                                        ; Enemy_FishController+2C   o
                dc.w    2
                dc.w    Enemy_FishSpriteMappingB-*
                dc.w    3
                dc.w    Enemy_FishSpriteMappingA-*
                dc.w    2
                dc.w    Enemy_FishSpriteMappingC-*
                dc.w    3
                dc.w    Enemy_FishLoopAnimation-*
                dc.w    0
Stage12_TeddyBearAnimationVariantC: dc.w    Stage12_TeddyBearSpriteMappingO-*  ; was: off_1A0F56
                dc.w    9
                dc.w    Stage12_TeddyBearSpriteMappingA-*
                dc.w    9
                dc.w    Stage12_TeddyBearAnimationVariantC-*
                dc.w    0
; Both streams below select A/B/C/B; rescue uses 5/4 ticks, the shared loop 2/1
Stage12_TeddyBearRescueAnimation:   dc.w    SharedTeddyHazardSpriteMappingA-*  ; was: off_1A0F62
                                        ; ROM:001A0F72   o
                dc.w    5
                dc.w    SharedTeddyHazardSpriteMappingB-*
                dc.w    4
                dc.w    SharedTeddyHazardSpriteMappingC-*
                dc.w    5
                dc.w    SharedTeddyHazardSpriteMappingB-*
                dc.w    4
                dc.w    Stage12_TeddyBearRescueAnimation-*
                dc.w    0
SharedTeddyHazardLoopAnimation: dc.w    SharedTeddyHazardSpriteMappingA-*  ; was: off_1A0F76
                                        ; Stage15_FragmentEmitterWaveInit+C   o
                                        ; Stage15_FallingRockWaveInit+C   o
                dc.w    2
                dc.w    SharedTeddyHazardSpriteMappingB-*
                dc.w    1
                dc.w    SharedTeddyHazardSpriteMappingC-*
                dc.w    2
                dc.w    SharedTeddyHazardSpriteMappingB-*
                dc.w    1
                dc.w    SharedTeddyHazardLoopAnimation-*
                dc.w    0
Stage12_TeddyBearPreBoardingAnimation:  dc.w    Stage12_TeddyBearSpriteMappingJ-*  ; was: off_1A0F8A
                                        ; ROM:001A0FA2   o
                dc.w    8
                dc.w    Stage12_TeddyBearSpriteMappingK-*
                dc.w    4
                dc.w    Stage12_TeddyBearSpriteMappingL-*
                dc.w    4
                dc.w    Stage12_TeddyBearSpriteMappingM-*
                dc.w    $C
                dc.w    Stage12_TeddyBearSpriteMappingL-*
                dc.w    2
                dc.w    Stage12_TeddyBearSpriteMappingK-*
                dc.w    2
                dc.w    Stage12_TeddyBearPreBoardingAnimation-*
                dc.w    0
Stage12_TeddyBearLandedAnimation:   dc.w    Stage12_TeddyBearSpriteMappingJ-*  ; was: off_1A0FA6
                                        ; ROM:001A0FAE   o
                dc.w    $B
                dc.w    Stage12_TeddyBearSpriteMappingK-*
                dc.w    $B
                dc.w    Stage12_TeddyBearLandedAnimation-*
                dc.w    0
Stage12_TeddyBearBoardingDelayAnimation:    dc.w    Stage12_TeddyBearSpriteMappingK-*  ; was: off_1A0FB2
                                        ; ROM:001A0FBA   o
                dc.w    $10
                dc.w    Stage12_TeddyBearSpriteMappingN-*
                dc.w    $10
                dc.w    Stage12_TeddyBearBoardingDelayAnimation-*
                dc.w    0
Stage12_TeddyBearAnimationVariantD: dc.w    Stage12_TeddyBearSpriteMappingP-*  ; was: off_1A0FBE
                dc.w    7
                dc.w    Stage12_TeddyBearSpriteMappingQ-*
                dc.w    6
                dc.w    Stage12_TeddyBearSpriteMappingR-*
                dc.w    7
                dc.w    Stage12_TeddyBearSpriteMappingQ-*
                dc.w    6
                dc.w    Stage12_TeddyBearAnimationVariantD-*
                dc.w    0
Stage12_TeddyBearInitialPoseAnimation:  dc.w    Stage12_TeddyBearSpriteMappingP-*  ; was: off_1A0FD2
                dc.w    $FF
Stage12_TeddyBearPilotReleasePoseAnimation: dc.w    Stage12_TeddyBearSpriteMappingI-*  ; was: off_1A0FD6
                dc.w    $FF
