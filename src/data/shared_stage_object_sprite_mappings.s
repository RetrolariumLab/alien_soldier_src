; Shared projectile mappings

SharedProjectileSpriteMappingA: dc.w    $E8F9, $F00, $F0F0  ; DATA XREF: ROM:SharedProjectileDuration2Animation   o  ; was: word_1A0CA6
                                        ; ROM:SharedProjectileDuration4Animation   o
SharedProjectileSpriteMappingB: dc.w    $E909, $A00, $F4F4  ; DATA XREF: ROM:001A0E8A   o  ; was: word_1A0CAC
                                        ; ROM:001A0E9A   o
SharedProjectileSpriteMappingC: dc.w    $E912, $A00, $F4F4  ; DATA XREF: ROM:001A0E8E   o  ; was: word_1A0CB2
                                        ; ROM:001A0E9E   o
SharedProjectileSpriteMappingD: dc.w    $E91B, $A00, $F4F4  ; DATA XREF: ROM:001A0E92   o  ; was: word_1A0CB8
                                        ; ROM:001A0EA2   o
; Mappings shared by the Stage 12 floater, Gusthead debris, and a Sharpsteel projectile

SharedFloaterDebrisProjectileSpriteMappingA:    dc.w    $C950, $B00, $F0F4  ; DATA XREF: ROM:SharedFloaterDebrisProjectileAlternating5And4Animation   o  ; was: word_1A0CBE
                                        ; ROM:001A0F22   o
SharedFloaterDebrisProjectileSpriteMappingB:    dc.w    $C95C, $B00, $F0F4  ; DATA XREF: ROM:001A0F1E   o  ; was: word_1A0CC4
                                        ; ROM:001A0F32   o
SharedFloaterDebrisProjectileSpriteMappingC:    dc.w    $C15C, $B00, $F0F4  ; DATA XREF: ROM:001A0F26   o  ; was: word_1A0CCA
                                        ; ROM:001A0F3A   o
; Direct mappings for individual stage objects

Stage10And12_MovingPlatformSpriteMapping:   dc.w    $6170, $E00, $F8E0  ; DATA XREF: Object_MovingPlatform+36   o  ; was: word_1A0CD0
                dc.w    $E970, $E00, $F800
Enemy_Stage10BeetleSpriteMappingA:  dc.w    $C949, $800, $FCF4  ; DATA XREF: ROM:Enemy_Stage10BeetleLoopAnimation   o  ; was: word_1A0CDC
                                        ; ROM:001A0F4A   o
Enemy_Stage10BeetleSpriteMappingB:  dc.w    $D94C, $800, $FAF2  ; DATA XREF: ROM:001A0F46   o  ; was: word_1A0CE2
Enemy_Stage10BeetleSpriteMappingC:  dc.w    $C94C, $800, $FEF2  ; DATA XREF: ROM:001A0F4E   o  ; was: word_1A0CE8
; Stage 12 Teddy Bear mapping group

Stage12_TeddyBearSpriteMappingA:    dc.w    $497C, $900, $ECF2  ; DATA XREF: ROM:Stage12_TeddyBearDropAndPilotAnimation   o  ; was: word_1A0CEE
                                        ; ROM:Stage12_TeddyBearOverwrittenPilotAnimation   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingB:    dc.w    $497C, $900, $EDF1  ; DATA XREF: ROM:001A0EBA   o  ; was: word_1A0CFA
                                        ; ROM:001A0ECA   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingC:    dc.w    $4982, $500, $EDF4  ; DATA XREF: ROM:001A0EBE   o  ; was: word_1A0D06
                                        ; ROM:001A0EC6   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingD:    dc.w    $4982, $500, $EFF2  ; DATA XREF: ROM:001A0EC2   o  ; was: word_1A0D12
                                        ; ROM:001A0EE2   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingE:    dc.w    $4182, $500, $EBFF  ; DATA XREF: ROM:Stage12_TeddyBearAnimationVariantA   o  ; was: word_1A0D1E
                                        ; ROM:001A0F06   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingF:    dc.w    $4182, $500, $EC00  ; DATA XREF: ROM:001A0F0A   o  ; was: word_1A0D2A
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingG:    dc.w    $417C, $900, $EAF8  ; DATA XREF: ROM:001A0EEE   o  ; was: word_1A0D36
                                        ; ROM:001A0EF6   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingH:    dc.w    $417C, $900, $EBF9  ; DATA XREF: ROM:001A0EF2   o  ; was: word_1A0D42
                                        ; ROM:001A0F02   o
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingI:    dc.w    $C9AC, $B00, $F0F4  ; DATA XREF: ROM:Stage12_TeddyBearPilotReleasePoseAnimation   o  ; was: word_1A0D4E
; Three mappings reused by the Teddy Bear and Stage 15 hazard emitters

SharedTeddyHazardSpriteMappingA:    dc.w    $499F, $900, $F4  ; DATA XREF: ROM:Stage12_TeddyBearRescueAnimation   o  ; was: word_1A0D54
                                        ; ROM:SharedTeddyHazardLoopAnimation   o
                dc.w    $4999, $900, $F4EE
                dc.w    $49A5, 0, $80C
                dc.w    $C9B8, 0, 2
SharedTeddyHazardSpriteMappingB:    dc.w    $499F, $900, $F4  ; DATA XREF: ROM:001A0F66   o  ; was: word_1A0D6C
                                        ; ROM:001A0F6E   o
                dc.w    $4999, $900, $F5ED
                dc.w    $49A5, 0, $80C
                dc.w    $C9B8, 0, $FE01
SharedTeddyHazardSpriteMappingC:    dc.w    $499F, $900, $F4  ; DATA XREF: ROM:001A0F6A   o  ; was: word_1A0D84
                                        ; ROM:001A0F7E   o
                dc.w    $4999, $900, $F5EC
                dc.w    $49A5, 0, $80C
                dc.w    $C9B8, 0, $FE00
Stage12_TeddyBearSpriteMappingJ:    dc.w    $417C, $900, $E9F6  ; DATA XREF: ROM:Stage12_TeddyBearPreBoardingAnimation   o  ; was: word_1A0D9C
                                        ; ROM:Stage12_TeddyBearLandedAnimation   o
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingK:    dc.w    $417C, $900, $EAF7  ; DATA XREF: ROM:001A0F8E   o  ; was: word_1A0DBA
                                        ; ROM:001A0F9E   o
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingL:    dc.w    $4182, $500, $EBFB  ; DATA XREF: ROM:001A0F92   o  ; was: word_1A0DD8
                                        ; ROM:001A0F9A   o
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingM:    dc.w    $4182, $500, $EDFC  ; DATA XREF: ROM:001A0F96   o  ; was: word_1A0DF6
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingN:    dc.w    $497C, $900, $EAF2  ; DATA XREF: ROM:001A0FB6   o  ; was: word_1A0E14
                dc.w    $41AA, $100, $F8F0
                dc.w    $49AA, $100, $F808
                dc.w    $41A6, $300, $F0F8
                dc.w    $C9A6, $300, $F000
Stage12_TeddyBearSpriteMappingO:    dc.w    $4199, $900, $ECF7  ; DATA XREF: ROM:Stage12_TeddyBearAnimationVariantC   o  ; was: word_1A0E32
                dc.w    $C986, $A00, $F7F3
Stage12_TeddyBearSpriteMappingP:    dc.w    $4982, $500, $F6EF  ; DATA XREF: ROM:Stage12_TeddyBearAnimationVariantD   o  ; was: word_1A0E3E
                                        ; ROM:Stage12_TeddyBearInitialPoseAnimation   o
                dc.w    $499F, $900, $F4
                dc.w    $49A5, 0, $80C
                dc.w    $D9B8, 0, $502
Stage12_TeddyBearSpriteMappingQ:    dc.w    $4982, $500, $F6EF  ; DATA XREF: ROM:001A0FC2   o  ; was: word_1A0E56
                                        ; ROM:001A0FCA   o
                dc.w    $499F, $900, $F4
                dc.w    $49A5, 0, $80C
                dc.w    $D9B8, 0, $402
Stage12_TeddyBearSpriteMappingR:    dc.w    $4982, $500, $F6EE  ; DATA XREF: ROM:001A0FC6   o  ; was: word_1A0E6E
                dc.w    $499F, $900, $F4
                dc.w    $49A5, 0, $80C
                dc.w    $D9B8, 0, $301
; Animation streams

SharedProjectileDuration2Animation: dc.w    SharedProjectileSpriteMappingA-*  ; DATA XREF: ROM:00040BF0   o  ; was: off_1A0E86
                dc.w    2
                dc.w    SharedProjectileSpriteMappingB-*
                dc.w    2
                dc.w    SharedProjectileSpriteMappingC-*
                dc.w    2
                dc.w    SharedProjectileSpriteMappingD-*
                dc.w    $FF
SharedProjectileDuration4Animation: dc.w    SharedProjectileSpriteMappingA-*  ; DATA XREF: Projectile_SpawnFourDirectionalShots_Loop+10   o  ; was: off_1A0E96
                                        ; Projectile_SpawnType1A8AtAngle+12   o
                dc.w    4
                dc.w    SharedProjectileSpriteMappingB-*
                dc.w    4
                dc.w    SharedProjectileSpriteMappingC-*
                dc.w    4
                dc.w    SharedProjectileSpriteMappingD-*
                dc.w    $FF
SharedProjectileDuration8Animation: dc.w    SharedProjectileSpriteMappingA-*  ; DATA XREF: ROM:00040BF8   o  ; was: off_1A0EA6
                dc.w    8
                dc.w    SharedProjectileSpriteMappingB-*
                dc.w    8
                dc.w    SharedProjectileSpriteMappingC-*
                dc.w    8
                dc.w    SharedProjectileSpriteMappingD-*
                dc.w    $FF
Stage12_TeddyBearDropAndPilotAnimation: dc.w    Stage12_TeddyBearSpriteMappingA-*  ; DATA XREF: Stage12_TeddyBearBeginDrop+12   o  ; was: off_1A0EB6
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
Stage12_TeddyBearOverwrittenPilotAnimation: dc.w    Stage12_TeddyBearSpriteMappingA-*  ; DATA XREF: Stage12_TeddyBearPilotStart+10   o  ; was: off_1A0ED2
                                        ; ROM:001A0EDA   o
                dc.w    8
                dc.w    Stage12_TeddyBearSpriteMappingB-*
                dc.w    8
                dc.w    Stage12_TeddyBearOverwrittenPilotAnimation-*
                dc.w    0
Stage12_TeddyBearBoardingPilotLoopAnimation:    dc.w    Stage12_TeddyBearSpriteMappingC-*  ; DATA XREF: Stage12_TeddyBearFacePlayerDelay+56   o  ; was: off_1A0EDE
                                        ; Stage12_TeddyBearFacePlayerDelay+BC   o
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingD-*
                dc.w    3
                dc.w    Stage12_TeddyBearBoardingPilotLoopAnimation-*
                dc.w    0
Stage12_TeddyBearAnimationVariantA: dc.w    Stage12_TeddyBearSpriteMappingE-*  ; DATA XREF: ROM:001A0EFA   o  ; was: off_1A0EEA
                dc.w    4
                dc.w    Stage12_TeddyBearSpriteMappingG-*
                dc.w    1
                dc.w    Stage12_TeddyBearSpriteMappingH-*
                dc.w    3
                dc.w    Stage12_TeddyBearSpriteMappingG-*
                dc.w    1
                dc.w    Stage12_TeddyBearAnimationVariantA-*
                dc.w    0
Stage12_TeddyBearAnimationVariantB: dc.w    Stage12_TeddyBearSpriteMappingG-*  ; DATA XREF: ROM:001A0F16   o  ; was: off_1A0EFE
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
SharedFloaterDebrisProjectileAlternating5And4Animation: dc.w    SharedFloaterDebrisProjectileSpriteMappingA-*  ; DATA XREF: ROM:Enemy_Stage12FloatingAnimationMappings   o  ; was: off_1A0F1A
                                        ; ROM:Boss_GustheadRandomDebrisMappings   o
                dc.w    5
                dc.w    SharedFloaterDebrisProjectileSpriteMappingB-*
                dc.w    4
                dc.w    SharedFloaterDebrisProjectileSpriteMappingA-*
                dc.w    5
                dc.w    SharedFloaterDebrisProjectileSpriteMappingC-*
                dc.w    4
                dc.w    SharedFloaterDebrisProjectileAlternating5And4Animation-*
                dc.w    0
SharedFloaterDebrisProjectileAlternating3And2Animation: dc.w    SharedFloaterDebrisProjectileSpriteMappingA-*  ; DATA XREF: ROM:0002E324   o  ; was: off_1A0F2E
                                        ; ROM:00040320   o
                dc.w    3
                dc.w    SharedFloaterDebrisProjectileSpriteMappingB-*
                dc.w    2
                dc.w    SharedFloaterDebrisProjectileSpriteMappingA-*
                dc.w    3
                dc.w    SharedFloaterDebrisProjectileSpriteMappingC-*
                dc.w    2
                dc.w    SharedFloaterDebrisProjectileAlternating3And2Animation-*
                dc.w    0
Enemy_Stage10BeetleLoopAnimation:   dc.w    Enemy_Stage10BeetleSpriteMappingA-*  ; DATA XREF: Enemy_Stage10BeetleInit+4A   o  ; was: off_1A0F42
                                        ; Enemy_Stage10BeetleController+2C   o
                dc.w    2
                dc.w    Enemy_Stage10BeetleSpriteMappingB-*
                dc.w    3
                dc.w    Enemy_Stage10BeetleSpriteMappingA-*
                dc.w    2
                dc.w    Enemy_Stage10BeetleSpriteMappingC-*
                dc.w    3
                dc.w    Enemy_Stage10BeetleLoopAnimation-*
                dc.w    0
Stage12_TeddyBearAnimationVariantC: dc.w    Stage12_TeddyBearSpriteMappingO-*  ; DATA XREF: ROM:001A0F5E   o  ; was: off_1A0F56
                dc.w    9
                dc.w    Stage12_TeddyBearSpriteMappingA-*
                dc.w    9
                dc.w    Stage12_TeddyBearAnimationVariantC-*
                dc.w    0
; Both streams below select A/B/C/B; rescue uses 5/4 ticks, the shared loop 2/1
Stage12_TeddyBearRescueAnimation:   dc.w    SharedTeddyHazardSpriteMappingA-*  ; DATA XREF: Stage12_TeddyBearInit+68   o  ; was: off_1A0F62
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
SharedTeddyHazardLoopAnimation: dc.w    SharedTeddyHazardSpriteMappingA-*  ; DATA XREF: Stage12_TeddyBearInit+10   o  ; was: off_1A0F76
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
Stage12_TeddyBearPreBoardingAnimation:  dc.w    Stage12_TeddyBearSpriteMappingJ-*  ; DATA XREF: Stage12_TeddyBearFacePlayerDelay+14   o  ; was: off_1A0F8A
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
Stage12_TeddyBearLandedAnimation:   dc.w    Stage12_TeddyBearSpriteMappingJ-*  ; DATA XREF: Stage12_TeddyBearBeginDrop+44   o  ; was: off_1A0FA6
                                        ; ROM:001A0FAE   o
                dc.w    $B
                dc.w    Stage12_TeddyBearSpriteMappingK-*
                dc.w    $B
                dc.w    Stage12_TeddyBearLandedAnimation-*
                dc.w    0
Stage12_TeddyBearBoardingDelayAnimation:    dc.w    Stage12_TeddyBearSpriteMappingK-*  ; DATA XREF: Stage12_TeddyBearFacePlayerDelay+3C   o  ; was: off_1A0FB2
                                        ; ROM:001A0FBA   o
                dc.w    $10
                dc.w    Stage12_TeddyBearSpriteMappingN-*
                dc.w    $10
                dc.w    Stage12_TeddyBearBoardingDelayAnimation-*
                dc.w    0
Stage12_TeddyBearAnimationVariantD: dc.w    Stage12_TeddyBearSpriteMappingP-*  ; DATA XREF: ROM:001A0FCE   o  ; was: off_1A0FBE
                dc.w    7
                dc.w    Stage12_TeddyBearSpriteMappingQ-*
                dc.w    6
                dc.w    Stage12_TeddyBearSpriteMappingR-*
                dc.w    7
                dc.w    Stage12_TeddyBearSpriteMappingQ-*
                dc.w    6
                dc.w    Stage12_TeddyBearAnimationVariantD-*
                dc.w    0
Stage12_TeddyBearInitialPoseAnimation:  dc.w    Stage12_TeddyBearSpriteMappingP-*  ; DATA XREF: Stage12_TeddyBearInit+8E   o  ; was: off_1A0FD2
                dc.w    $FF
Stage12_TeddyBearPilotReleasePoseAnimation: dc.w    Stage12_TeddyBearSpriteMappingI-*  ; DATA XREF: Stage12_TeddyBearPilotRelease+4   o  ; was: off_1A0FD6
                dc.w    $FF
