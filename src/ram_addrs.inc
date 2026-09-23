; ---------- ram names -------------
M68K_RAM                        equ     $FFFF0000
M68K_RAM_PHYSICAL               equ     $00FF0000
M68K_RAM_END_PHYSICAL           equ     $00FFFFFF
ShipPatternMaskBuffer           equ     $FFFF0020       ; was: dword_FF0020
PlanetPatternFillBuffer         equ     $FFFF0040       ; was: word_FF0040
ShipPatternFillBuffer           equ     $FFFF0060       ; was: word_FF0060
PlanetPatternRowBuffer          equ     $FFFF0080       ; was: word_FF0080
ShipPatternRowBuffer            equ     $FFFF00A0       ; was: word_FF00A0
PatternVDPCommand               equ     $FFFF00C0       ; was: dword_FF00C0
PlanetPatternWriteOnly          equ     $FFFF00C4       ; was: word_FF00C4
PatternDissolveStep             equ     $FFFF00C6       ; was: word_FF00C6
PatternFrameMask                equ     $FFFF00C8       ; was: word_FF00C8
ShipPatternVDPCommand           equ     $FFFF00CA       ; was: dword_FF00CA
ShipPatternWriteOnly            equ     $FFFF00CE       ; was: word_FF00CE
ShipPatternStep                 equ     $FFFF00D0       ; was: word_FF00D0
ShipPatternFrameMask            equ     $FFFF00D2       ; was: word_FF00D2
SpriteGridCenterY               equ     $FFFF00D4       ; was: word_FF00D4
SpriteGridCenterX               equ     $FFFF00D6       ; was: word_FF00D6
SpriteGridRowLimit              equ     $FFFF00D8       ; was: word_FF00D8
SpriteGridColumnLimit           equ     $FFFF00DA       ; was: word_FF00DA
SpriteGridFirstTile             equ     $FFFF00DC       ; was: word_FF00DC
ShipGridCenterY                 equ     $FFFF00DE       ; was: word_FF00DE
ShipGridCenterX                 equ     $FFFF00E0       ; was: word_FF00E0
ShipGridRowLimit                equ     $FFFF00E2       ; was: word_FF00E2
ShipGridColumnLimit             equ     $FFFF00E4       ; was: word_FF00E4
ShipGridFirstTile               equ     $FFFF00E6       ; was: word_FF00E6
StarRowSeparation               equ     $FFFF00E8       ; was: word_FF00E8
StarRowState                    equ     $FFFF00EA       ; was: word_FF00EA
SharedSequenceState             equ     $FFFF00EC       ; was: word_FF00EC
PlanetGridState                 equ     $FFFF00EE       ; was: word_FF00EE
ShipGridState                   equ     $FFFF00F0       ; was: word_FF00F0
PlanetGridTimer                 equ     $FFFF00F2       ; was: word_FF00F2
ShipGridTimer                   equ     $FFFF00F4       ; was: word_FF00F4
StoryTextVRAMAddress            equ     $FFFF00F6       ; was: word_FF00F6
SharedSequenceCursor            equ     $FFFF00F8       ; was: dword_FF00F8
SharedSequenceTimer             equ     $FFFF00FC       ; was: word_FF00FC
StarRowTimer                    equ     $FFFF00FE       ; was: word_FF00FE
StoryTitleGlyphCursor           equ     $FFFF0100       ; was: dword_FF0100
CutsceneTimer                   equ     $FFFF0106       ; was: word_FF0106
StoryTitleExpandSpan            equ     $FFFF0108       ; was: word_FF0108
StoryTitleGlyphsLeft            equ     $FFFF010A       ; was: word_FF010A
CutscenePaletteStep             equ     $FFFF010C       ; was: word_FF010C
EndingInitWriteOnlyFlag         equ     $FFFF010E       ; was: word_FF010E
EndingScrollPhase               equ     $FFFF0110       ; was: dword_FF0110
EndingScrollRate                equ     $FFFF0114       ; was: dword_FF0114
PlanetZoomFrameIndex            equ     $FFFF0118       ; was: word_FF0118
PlanetZoomAngle                 equ     $FFFF011A       ; was: word_FF011A
PlanetZoomRadius                equ     $FFFF011C       ; was: dword_FF011C
StoryFontGlyphCursor            equ     $FFFF0120       ; was: dword_FF0120
StoryFontState                  equ     $FFFF0126       ; was: word_FF0126
ShipPieceScriptCursor           equ     $FFFF0128       ; was: dword_FF0128
ShipDebrisCursor                equ     $FFFF012C       ; was: dword_FF012C
ShipSequenceFrame               equ     $FFFF0130       ; was: word_FF0130
ShipSequenceState               equ     $FFFF0132       ; was: word_FF0132
ShipVerticalPosition            equ     $FFFF0134       ; was: dword_FF0134
ShipVerticalVelocity            equ     $FFFF0138       ; was: dword_FF0138
ShipTileLoadTimer               equ     $FFFF013C       ; was: word_FF013C
ShipRowRevealProgress           equ     $FFFF0140       ; was: word_FF0140
ShipRevealFrame                 equ     $FFFF0164       ; was: word_FF0164
ShipMainFadeStep                equ     $FFFF0166       ; was: word_FF0166
ShipAccentFadeStep              equ     $FFFF0168       ; was: word_FF0168
ShipFlashState                  equ     $FFFF016A       ; was: word_FF016A
ShipFlashTimer                  equ     $FFFF016C       ; was: word_FF016C
ShipJitterState                 equ     $FFFF016E       ; was: word_FF016E
ShipJitterTimer                 equ     $FFFF0170       ; was: word_FF0170
StoryTextAccentCursor           equ     $FFFF0172       ; was: dword_FF0172
ScenePaletteFadeOffset          equ     $FFFF0176       ; was: word_FF0176
StoryTextState                  equ     $FFFF0178       ; was: word_FF0178
CreditsSceneState               equ     $FFFF017C       ; was: word_FF017C
CreditsClearedSceneWord         equ     $FFFF017E       ; was: word_FF017E
StoryFontScrollY                equ     $FFFF0180       ; was: word_FF0180
StoryFontNextGlyphY             equ     $FFFF0182       ; was: word_FF0182
StoryFontVRAMAddress            equ     $FFFF0184       ; was: word_FF0184
StoryHBlankDelayCounter         equ     $FFFF0186       ; was: word_FF0186
CreditsMasterCountdown          equ     $FFFF0188       ; was: word_FF0188
CreditsSceneDataCursor          equ     $FFFF018A       ; was: dword_FF018A
CreditsSceneTimer               equ     $FFFF018E       ; was: word_FF018E
CreditsPaletteTarget            equ     $FFFF0190       ; was: dword_FF0190
CreditsPaletteFadeIndex         equ     $FFFF0194       ; was: word_FF0194
CutsceneFrameSourceBuffer       equ     $FFFF0400
PlaneTilemapRow9                equ     $FFFF0480       ; was: word_FF0480
PlaneTilemapRow10               equ     $FFFF0500       ; was: word_FF0500
PlaneTilemapRow22               equ     $FFFF0B00       ; was: word_FF0B00
PlaneTilemapRow24               equ     $FFFF0C00       ; was: word_FF0C00
PlaneTilemapRow25               equ     $FFFF0C80       ; was: word_FF0C80
PlaneTilemapRow26               equ     $FFFF0D00       ; was: word_FF0D00
PlaneTilemapRow27               equ     $FFFF0D80       ; was: word_FF0D80
PlaneTilemapRow28               equ     $FFFF0E00       ; was: word_FF0E00
PlaneTilemapRow29               equ     $FFFF0E80       ; was: word_FF0E80
CutsceneWorkBuffer              equ     $FFFF1000       ; was: word_FF1000
EndingStarYPositions            equ     $FFFF1400       ; was: word_FF1400
StoryTitleLeftOrigin            equ     $FFFF14C3       ; was: off_FF14C3
StoryTitleRightOrigin           equ     $FFFF1500       ; was: word_FF1500
EndingStarDepthValues           equ     $FFFF1800       ; was: dword_FF1800
EndingStarXVelocities           equ     $FFFF1C00       ; was: dword_FF1C00
EndingStarYVelocities           equ     $FFFF2000       ; was: dword_FF2000
SharedTilemapWorkspace          equ     $FFFF2020       ; was: word_FF2020
ShipArrivalTilemap              equ     SharedTilemapWorkspace
SharedGraphicsOverlay           equ     $FFFF2080       ; was: byte_FF2080
StoryTitleLogoPixels            equ     SharedGraphicsOverlay
ZLeoPriorityFirstRow            equ     SharedGraphicsOverlay
ZLeoPriorityLastRow             equ     $FFFF20E0       ; was: word_FF20E0
ZLeoPriorityLastCol2            equ     $FFFF20E4       ; was: word_FF20E4
StoryTitleMirroredGlyph         equ     $FFFF2380       ; was: byte_FF2380
StoryTitleGlyphReadBase         equ     $FFFF2384       ; was: byte_FF2384
LargeTilemapBuffer              equ     $FFFF4000       ; was: dword_FF4000
FlyingNeoTileAttrRangeA         equ     $FFFF4020       ; was: word_FF4020
FlyingNeoTileAttrRangeC         equ     $FFFF4360       ; was: word_FF4360
FlyingNeoTileAttrRangeD         equ     $FFFF4400       ; was: word_FF4400
FlyingNeoTileAttrRangeB         equ     $FFFF4AC0       ; was: word_FF4AC0
LargeTilemapPage2               equ     $FFFF5000       ; was: word_FF5000
CreditsXiTigerTilemap           equ     $FFFF5180       ; was: dword_FF5180
Stage3ResampleBuffer            equ     $FFFF6000
Stage8StridedControl            equ     $FFFF615D       ; was: byte_FF615D
XiTigerCreditsFineTable         equ     $FFFF6180       ; was: dword_FF6180
XiTigerCreditsPatch0            equ     $FFFF6194       ; was: dword_FF6194
XiTigerCreditsPatch1            equ     $FFFF619C       ; was: dword_FF619C
XiTigerCreditsPatch2            equ     $FFFF61A4       ; was: dword_FF61A4
TerobusterIntroPalette          equ     $FFFF644A       ; was: byte_FF644A
WeaponSetupWriteFlag            equ     $FFFF7001       ; was: byte_FF7001
TerrainCollisionBuffer          equ     $FFFF7800       ; was: dword_FF7800
Stage8TilemapMode               equ     $FFFF780C       ; was: byte_FF780C
Stage9TilemapMode               equ     $FFFF780D       ; was: byte_FF780D
WeaponSetupTilemapMode          equ     $FFFF78FF       ; was: byte_FF78FF
Stage20PlaneMode0               equ     $FFFF7981       ; was: byte_FF7981
Stage20PlaneMode1               equ     $FFFF7982       ; was: byte_FF7982
Stage20PlaneMode2               equ     $FFFF7983       ; was: byte_FF7983
Stage17TilemapMode              equ     $FFFF7AFF       ; was: byte_FF7AFF
SevenForcesTilemapMode          equ     $FFFF7B00       ; was: byte_FF7B00
GameplayStateBuffer             equ     $FFFF8000       ; was: dword_FF8000
ResultsFirstColorOffset         equ     $FFFF8014       ; was: word_FF8014
ResultsOtherColorOffset         equ     $FFFF8016       ; was: word_FF8016
WeaponTargetOrFrame             equ     $FFFF801C       ; was: word_FF801C
WeaponIconFrameTile             equ     $FFFF801E       ; was: word_FF801E
WeaponAnimationDataPtr          equ     $FFFF8020       ; was: dword_FF8020
WeaponYMotionParameter          equ     $FFFF8024       ; was: dword_FF8024
WeaponXMotionParameter          equ     $FFFF8028       ; was: dword_FF8028
WeaponModeParameter             equ     $FFFF802C       ; was: dword_FF802C
WeaponMenuRadius                equ     $FFFF8030       ; was: word_FF8030
WeaponMenuSpawnXOffset          equ     $FFFF8032       ; was: word_FF8032
WeaponMenuSpawnYOffset          equ     $FFFF8034       ; was: word_FF8034
WeaponMenuAngle                 equ     $FFFF8036       ; was: word_FF8036
WeaponStateCooldown             equ     $FFFF8038       ; was: word_FF8038
WeaponMenuAngularStep           equ     $FFFF803A       ; was: word_FF803A
WeaponMenuSlotOffset            equ     $FFFF803C       ; was: word_FF803C
SharedRuntimeWorkLong0          equ     $FFFF8040       ; was: dword_FF8040
SharedRuntimeWorkLong1          equ     $FFFF8044       ; was: dword_FF8044
SharedRuntimeWorkWord0          equ     $FFFF8048       ; was: word_FF8048
SharedRuntimeWorkWord1          equ     $FFFF804A       ; was: word_FF804A
DMASourceEncoding               equ     SharedRuntimeWorkLong0
PoseCommandWord                 equ     SharedRuntimeWorkLong0
PoseDurationByte                equ     SharedRuntimeWorkLong0
MetaspriteBaseTileWord          equ     SharedRuntimeWorkLong0
MetaspriteParentPtr             equ     SharedRuntimeWorkLong0+2
MetaspritePartCountM1           equ     SharedRuntimeWorkLong0
MetaspriteSineScratch           equ     SharedRuntimeWorkWord0
MetaspriteCosScratch            equ     SharedRuntimeWorkWord1
CircleAttackOffsetX             equ     SharedRuntimeWorkLong0
CircleAttackOffsetY             equ     SharedRuntimeWorkLong1
CircleAttackTargetDX            equ     SharedRuntimeWorkWord0
CircleAttackTargetDY            equ     SharedRuntimeWorkWord1
BCDIncrementScratch             equ     SharedRuntimeWorkWord0
BCDIncrementEnd                 equ     SharedRuntimeWorkWord1
CutsceneRowSource               equ     SharedRuntimeWorkLong0
CutsceneRowVRAM                 equ     SharedRuntimeWorkLong0+2
WaveStateTimer                  equ     SharedRuntimeWorkLong0
TileInterpSpan                  equ     SharedRuntimeWorkLong0
TileInterpReadBaseA             equ     SharedRuntimeWorkLong0+2
TileInterpReadBaseB             equ     SharedRuntimeWorkLong1
TileInterpSpanStep              equ     SharedRuntimeWorkLong1+2
TileInterpVRAM                  equ     SharedRuntimeWorkWord0
TileInterpStepsLeft             equ     SharedRuntimeWorkWord1
Stage3PackedTilePtr             equ     SharedRuntimeWorkLong0
Stage3ResampleGroupsM1          equ     SharedRuntimeWorkWord0
Stage3ResamplePassesM1          equ     SharedRuntimeWorkWord1
MessageGlyphHiNibbleScratch     equ     SharedRuntimeWorkLong0
MessageGlyphLoNibbleScratch     equ     SharedRuntimeWorkLong1
PaletteColorPair                equ     SharedRuntimeWorkLong0
BossHealthPairScratch           equ     SharedRuntimeWorkLong0
BossAssetPointerScratch         equ     SharedRuntimeWorkLong0
WeaponSetupCursorOffset         equ     SharedRuntimeWorkLong0
HUDGlyphWordScratch             equ     SharedRuntimeWorkLong0
SeekingAngleScratch             equ     SharedRuntimeWorkLong0
EnemySpawnSearchPass            equ     SharedRuntimeWorkLong0
TrigSavedObjectPtr              equ     SharedRuntimeWorkLong0
HitboxMirrorScratchA            equ     SharedRuntimeWorkLong0
HitboxMirrorScratchB            equ     SharedRuntimeWorkLong1
Stage9CameraXSnapshot           equ     SharedRuntimeWorkLong0
Stage9SecondaryXCopy            equ     SharedRuntimeWorkWord0
AntroidPoseOffsetTemp           equ     SharedRuntimeWorkLong0
AntroidPoseTimerTemp            equ     SharedRuntimeWorkLong0+2
MadamWobbleX                    equ     SharedRuntimeWorkLong0
MadamWobbleY                    equ     SharedRuntimeWorkLong0+2
SharedTransferWorkLong0         equ     $FFFF8058       ; was: dword_FF8058
SharedTransferWorkWord0         equ     $FFFF805C       ; was: word_FF805C
SharedTransferWorkLong1         equ     $FFFF805E       ; was: dword_FF805E
TileCoarseLookupOffset          equ     SharedTransferWorkLong0
TileFineLookupOffset            equ     SharedTransferWorkLong0+2
TilePatternOffset               equ     SharedTransferWorkWord0
TilePlaneBufferOffset           equ     SharedTransferWorkLong1
IndexedDMACommand               equ     SharedTransferWorkLong0
IndexedDMALowByte               equ     SharedTransferWorkLong0+3
IndexedStagingStart             equ     SharedTransferWorkWord0
IndexedGroupStride              equ     SharedTransferWorkLong1
Stage3ScaleTablePtr             equ     SharedTransferWorkLong0
Stage7ExitDelay                 equ     SharedTransferWorkLong0
Stage9RevealColumn              equ     SharedTransferWorkLong0
PasswordDifficulty              equ     SharedTransferWorkWord0
PasswordStageNumber             equ     SharedTransferWorkLong1
OptionsSelection                equ     SharedTransferWorkLong1
OptionsCursorMoving             equ     SharedTransferWorkLong1+2
OptionsBGMIndex                 equ     SharedTransferWorkLong1+3
SharedControlWorkLong0          equ     $FFFF8062       ; was: dword_FF8062
SharedControlWorkLong1          equ     $FFFF8066       ; was: dword_FF8066
SharedControlWorkLong2          equ     $FFFF806A       ; was: dword_FF806A
AsteroidVScrollSpeed            equ     SharedControlWorkLong0
AsteroidVScrollPos              equ     SharedControlWorkLong1
BackdropLineSpeed               equ     SharedControlWorkLong0
BackdropLinePosition            equ     SharedControlWorkLong1
BackdropTailPosition            equ     SharedControlWorkLong2
WolfGaropaScrollSpeed           equ     SharedControlWorkLong0
Stage24VScrollSpeed             equ     SharedControlWorkLong1+2
ArtemisForegroundState          equ     SharedControlWorkLong1
TerobusterIntroTimer            equ     SharedControlWorkLong0
TerobusterProjectileY           equ     SharedControlWorkLong0+2
TerobusterTileRowIndex          equ     SharedControlWorkLong1
LightningEffectTimer            equ     SharedControlWorkLong0
XiTigerEntranceTimer            equ     SharedControlWorkLong0
Stage12TeleportFade             equ     SharedControlWorkLong2+2
TeleportSnakeScrollVel          equ     SharedControlWorkLong1+2
MidgameFadeLevel                equ     SharedControlWorkLong1+2
Stage16CameraSnapshot           equ     SharedControlWorkLong2+2
PostViblackVScrollVel           equ     SharedControlWorkLong0+2
PostViblackPalettePos           equ     SharedControlWorkLong2
PostViblackPaletteDelay         equ     SharedControlWorkLong1+2
ContinueCountdownValue          equ     SharedControlWorkLong1+2
TitleMenuSelection              equ     SharedControlWorkLong1+2
OptionsHandlerOffset            equ     SharedControlWorkLong0
OptionsCursorFlashTimer         equ     SharedControlWorkLong0+2
OptionsSFXIndex                 equ     SharedControlWorkLong1
OptionsRepeatTimer              equ     SharedControlWorkLong1+2
OptionsPressedCopy              equ     SharedControlWorkLong2
OptionsHeldCopy                 equ     SharedControlWorkLong2+1
OptionsVoiceIndex               equ     SharedControlWorkLong2+2
PasswordCursorFlash             equ     SharedControlWorkLong0+2
PasswordCursorOffset            equ     SharedControlWorkLong1+2
PasswordHeldNibble              equ     SharedControlWorkLong2
PasswordRepeatTimer             equ     SharedControlWorkLong2+2
SharedSceneControl              equ     $FFFF806E       ; was: word_FF806E
PasswordCursorMoveFlag          equ     SharedSceneControl
StageEventTimer                 equ     SharedSceneControl
PaletteTestSelector             equ     SharedSceneControl
TransitionModeOffset            equ     $FFFF807A       ; was: word_FF807A
TransitionProgress              equ     $FFFF807C       ; was: word_FF807C
GameOverLandscapeAngle          equ     TransitionProgress
TransitionOriginXY              equ     $FFFF807E       ; was: dword_FF807E
GameOverLandscapeDepth          equ     TransitionOriginXY
TransitionMaskStep              equ     $FFFF8082       ; was: word_FF8082
GameOverViewOffset              equ     TransitionMaskStep
SpriteShakeYOffset              equ     $FFFF8086       ; was: word_FF8086
PlaneBShakeWriteOnly            equ     $FFFF8088       ; was: word_FF8088
GlobalSpritePriorityBit         equ     $FFFF808A       ; was: word_FF808A
StageSpawnCountdown             equ     $FFFF808C       ; was: word_FF808C
RasterLayoutOffset              equ     $FFFF8090       ; was: word_FF8090
GlobalSpriteFlipBits            equ     $FFFF8092       ; was: word_FF8092
VBlankFrameDivider              equ     $FFFF8096       ; was: word_FF8096
CombatPercentTimer              equ     $FFFF809A       ; was: word_FF809A
DashActiveWriteOnly             equ     $FFFF809C       ; was: word_FF809C
ExplosionSoundDelay             equ     $FFFF809E       ; was: word_FF809E
TransitionEdgeSpan              equ     $FFFF80A0       ; was: dword_FF80A0
MessageSequenceFlags            equ     $FFFF80A8       ; was: byte_FF80A8
StagePlaneAEntryMode            equ     $FFFF80AA       ; was: word_FF80AA
StagePlaneBEntryMode            equ     $FFFF80AC       ; was: word_FF80AC
MessageSequenceState            equ     $FFFF80C2       ; was: word_FF80C2
MessageWorkWord0                equ     $FFFF80C4       ; was: word_FF80C4
MessageGlyphVRAMCursor          equ     MessageWorkWord0
ResultsTimeBonusX0              equ     MessageWorkWord0
MessageWaitTimer                equ     MessageWorkWord0
LinearSpriteX                   equ     MessageWorkWord0
MessageWorkWord1                equ     $FFFF80C6       ; was: word_FF80C6
BattleBannerTimer               equ     MessageWorkWord1
MessageGlyphDelay               equ     MessageWorkWord1
MessageTileChunkIndex           equ     MessageWorkWord1
StageIntroBannerX               equ     MessageWorkWord1
ResultsTimeBonusAngle           equ     MessageWorkWord1
RadialTextAngle                 equ     MessageWorkWord1
MessageWorkLong0                equ     $FFFF80C8       ; was: dword_FF80C8
MessageScriptCursor             equ     MessageWorkLong0
BattleBannerVelocity            equ     MessageWorkLong0
ResultsTimeBonusTimer           equ     MessageWorkLong0
StageIntroSoundRequest          equ     MessageWorkLong0
MessageHoldTimer                equ     MessageWorkLong0
MessageWorkWord2                equ     $FFFF80CC       ; was: word_FF80CC
MessageTilemapVRAMPos           equ     MessageWorkWord2
ResultsTimeBonusRadialY         equ     MessageWorkWord2
RadialTextCenterY               equ     MessageWorkWord2
MessageWorkLong1                equ     $FFFF80CE       ; was: dword_FF80CE
MessageGlyphSourcePtr           equ     MessageWorkLong1
BattleBannerOffset              equ     MessageWorkLong1
BattleBannerDelay               equ     MessageWorkLong1
StageIntroPostDelay             equ     MessageWorkLong1
ResultsTimeBonusRadius          equ     MessageWorkLong1
RadialTextRadius                equ     MessageWorkLong1
MessageScriptEndTimer           equ     MessageWorkLong1
MessageWorkWord3                equ     $FFFF80D2       ; was: word_FF80D2
MessageGlyphTileWord            equ     MessageWorkWord3
MessageWorkWord4                equ     $FFFF80D4       ; was: word_FF80D4
MessageTilemapAttrs             equ     MessageWorkWord4
StageIntroBannerTimer           equ     MessageWorkWord4
MessageSpriteY                  equ     MessageWorkWord4
MessageWorkWord5                equ     $FFFF80D6       ; was: word_FF80D6
ResultsTimeBonusX1              equ     MessageWorkWord5
PlayerDefeatPhase               equ     $FFFF80E6       ; was: word_FF80E6
BossColorEffectFlags            equ     $FFFF80EC       ; was: byte_FF80EC
ColorFadePhase                  equ     $FFFF80EE       ; was: word_FF80EE
PaletteFadeColorOffset          equ     $FFFF80F0       ; was: word_FF80F0
PaletteFadeMode                 equ     $FFFF80F2       ; was: word_FF80F2
PaletteFadeMaskStatus           equ     $FFFF80F4       ; was: word_FF80F4
PaletteFadeControlFlags         equ     $FFFF80F8       ; was: byte_FF80F8
AlternateTimeBonusSound         equ     $FFFF80FA       ; was: byte_FF80FA
SharedTransitionControl         equ     $FFFF8100       ; was: word_FF8100
FrontendHoldTimer               equ     SharedTransitionControl
WaveControlWord                 equ     SharedTransitionControl
WaveParameterIndex              equ     $FFFF8102       ; was: word_FF8102
WaveStateOffset                 equ     $FFFF8104       ; was: word_FF8104
HUDDynamicStripTileAttr         equ     $FFFF8110       ; was: word_FF8110
HUDDynamicStripXOffset          equ     $FFFF8112       ; was: word_FF8112
EnemySpawnDirectorState         equ     $FFFF8114       ; was: word_FF8114
EnemySpawnDelayTimer            equ     $FFFF8116       ; was: dword_FF8116
EnemySpawnClearedLongA          equ     $FFFF811A       ; was: dword_FF811A
EnemySpawnClearedLongB          equ     $FFFF811E       ; was: dword_FF811E
EnemySpawnClearedLongC          equ     $FFFF8122       ; was: dword_FF8122
ActivePickupCountMinus1         equ     $FFFF8126       ; was: word_FF8126
SceneScratchLong0               equ     $FFFF8128       ; was: dword_FF8128
WeaponSetupForceIndex           equ     SceneScratchLong0
StageTransitionTimer            equ     SceneScratchLong0
Epsilon1TransitionY             equ     SceneScratchLong0
XiTigerStateOffset              equ     SceneScratchLong0
EndingSequenceComplete          equ     SceneScratchLong0
GameOverLandscapeIndex          equ     SceneScratchLong0
WeaponSetupVScrollTarget        equ     SceneScratchLong0+2
XiTigerPhaseCounter             equ     SceneScratchLong0+2
EndingSequenceState             equ     SceneScratchLong0+2
SceneScratchLong1               equ     $FFFF812C       ; was: dword_FF812C
WeaponSetupControlIndex         equ     SceneScratchLong1
Epsilon1ParallaxPos             equ     SceneScratchLong1
XiTigerMotionStep               equ     SceneScratchLong1
SceneScratchLong2               equ     $FFFF8130       ; was: dword_FF8130
WeaponSetupBgPhase              equ     SceneScratchLong2
Epsilon1ParallaxStep            equ     SceneScratchLong2
XiTigerStateCounter             equ     SceneScratchLong2
XiTigerPaletteLevel             equ     SceneScratchLong2+2
SceneScratchLong3               equ     $FFFF8134       ; was: dword_FF8134
WeaponSetupHighlight            equ     SceneScratchLong3
Epsilon1VScrollValue            equ     SceneScratchLong3
XiTigerWavePhase                equ     SceneScratchLong3
XiTigerSpriteXOffset            equ     SceneScratchLong3+2
Stage15SunsetStingAssetDelay    equ     SceneScratchLong3+2
ScriptedInputActive             equ     $FFFF8138       ; was: word_FF8138
ScriptedInputTimeout            equ     $FFFF813A       ; was: word_FF813A
FrameFreezeTimer                equ     $FFFF813C       ; was: word_FF813C
FrameControlFlags               equ     $FFFF813E       ; was: byte_FF813E
PaletteRGBAdjustLevel           equ     $FFFF8140       ; was: word_FF8140
PaletteRGBChannelMask           equ     $FFFF8142       ; was: byte_FF8142
PaletteRGBAdjustStep            equ     $FFFF8143       ; was: byte_FF8143
PlayerModeFlags                 equ     $FFFF8144       ; was: byte_FF8144
FontTileDMAVRAMAddress          equ     $FFFF8146       ; was: word_FF8146
FontTileDMACounter              equ     $FFFF8148       ; was: word_FF8148
FontTileDMASourceOffset         equ     $FFFF814A       ; was: word_FF814A
XiTigerConfigIndex              equ     $FFFF814C       ; was: word_FF814C
BossHealth                      equ     $FFFF8200       ; was: word_FF8200
BossMaxHealth                   equ     $FFFF8202       ; was: word_FF8202
StageTimerFrameCounter          equ     $FFFF8204       ; was: byte_FF8204
DisplayedBossHealth             equ     $FFFF8206       ; was: word_FF8206
DisplayedPlayerHealth           equ     $FFFF820A       ; was: word_FF820A
StatusDisplayModeOffset         equ     $FFFF820C       ; was: word_FF820C
CombatPercentIndex              equ     $FFFF8210       ; was: word_FF8210
PaletteEffectControl            equ     $FFFF8218       ; was: word_FF8218
PaletteEntryLists               equ     $FFFF821A       ; was: dword_FF821A
MidgameLightningMode            equ     $FFFF821E       ; was: word_FF821E
PalettePrimaryIndex             equ     $FFFF8220       ; was: word_FF8220
PaletteSecondaryIndex           equ     $FFFF8222       ; was: word_FF8222
PlayerAirMoveUsedFlags          equ     $FFFF8224       ; was: word_FF8224
PlayerAirDashUsedFlag           equ     PlayerAirMoveUsedFlags
PlayerAirShotUsedFlag           equ     PlayerAirMoveUsedFlags+1
DebugMenuStateOffset            equ     $FFFF8226       ; was: word_FF8226
DebugSoundRequestId             equ     $FFFF8228       ; was: word_FF8228
DebugResourceRefill             equ     $FFFF822A       ; was: word_FF822A
ResultsTimeBonusBCD             equ     $FFFF822C       ; was: word_FF822C
GameplayExitMode                equ     $FFFF8230       ; was: word_FF8230
StageNumberBCD                  equ     $FFFF8232       ; was: byte_FF8232
BossCombatCounter               equ     $FFFF8234       ; was: word_FF8234
BossCombatCounterMax            equ     $FFFF8236       ; was: word_FF8236
WeaponFireCooldown              equ     $FFFF8238       ; was: word_FF8238
StageMotionXDelta               equ     $FFFF8240       ; was: dword_FF8240
PlayerActionStateFlags          equ     $FFFF8244       ; was: byte_FF8244
PlayerRestrictionFlags          equ     $FFFF8245       ; was: byte_FF8245
ColorFadeTriggerState           equ     $FFFF8246       ; was: word_FF8246
PlayerCenterX                   equ     $FFFF8248       ; was: word_FF8248
PlayerCenterY                   equ     $FFFF824A       ; was: word_FF824A
ForcedPositionTimer             equ     $FFFF824E       ; was: word_FF824E
ForcedPositionX                 equ     $FFFF8250       ; was: word_FF8250
ForcedPositionY                 equ     $FFFF8252       ; was: word_FF8252
ForcedPositionFlags             equ     $FFFF825C       ; was: byte_FF825C
ContactDamageCooldown           equ     $FFFF825D       ; was: byte_FF825D
BossCounterMaxFlag              equ     $FFFF8260       ; was: byte_FF8260
HealthDeltaDisplayValue         equ     $FFFF8262       ; was: word_FF8262
TransientValueScreenX           equ     $FFFF8264       ; was: word_FF8264
TransientValueScreenY           equ     $FFFF8266       ; was: word_FF8266
HealthDeltaDisplayTimer         equ     $FFFF8268       ; was: word_FF8268
CounterForceInputTimer          equ     $FFFF826A       ; was: word_FF826A
CounterForceTriggerFlag         equ     $FFFF826C       ; was: byte_FF826C
SpawnedEnemyTileAttr            equ     $FFFF826E       ; was: word_FF826E
StandardEnemyTileAttr           equ     $FFFF8270       ; was: word_FF8270
EnemyProjectileTileAttr         equ     $FFFF8272       ; was: word_FF8272
BirdEnemyTileAttr               equ     $FFFF8274       ; was: word_FF8274
PhaseEnemyTileAttr              equ     $FFFF8276       ; was: word_FF8276
Stage10WaspTileAttr             equ     $FFFF8278       ; was: word_FF8278
CirclingEnemyTileAttr           equ     $FFFF827A       ; was: word_FF827A
SpecialTargetCount              equ     $FFFF829E       ; was: word_FF829E
StageAssetCommandBuffer         equ     $FFFF82A0       ; was: byte_FF82A0
PlayerKnockbackXVel             equ     $FFFF8300       ; was: dword_FF8300
PhoenixAttackStatus             equ     $FFFF8304       ; was: word_FF8304
LowTimeWarningTimer             equ     $FFFF8306       ; was: word_FF8306
CombatHitFlags                  equ     $FFFF8308       ; was: byte_FF8308
StageMotionYDelta               equ     $FFFF830A       ; was: dword_FF830A
SoundFadeOutDelay               equ     $FFFF830E       ; was: byte_FF830E
PlayerInputMask                 equ     $FFFF830F       ; was: byte_FF830F
MessageAdvanceButtons           equ     $FFFF8310       ; was: byte_FF8310
PlayerDashStopFlag              equ     $FFFF8311       ; was: byte_FF8311
WeaponIconDMABuffer             equ     $FFFF8478       ; was: byte_FF8478
WeaponIconDMABufferEnd          equ     $FFFF8488       ; was: byte_FF8488
PrimaryHUDDMABuffer             equ     $FFFF84A0       ; was: dword_FF84A0
PrimaryHUDTileBuffer            equ     $FFFF84B0       ; was: byte_FF84B0
WeaponDebugDMABuffer            equ     $FFFF8500       ; was: dword_FF8500
WeaponDebugTileBuffer           equ     $FFFF8510       ; was: byte_FF8510
DebugHealthCursorTile           equ     $FFFF8512       ; was: word_FF8512
DebugHealthHighTile             equ     $FFFF851E       ; was: word_FF851E
DebugHealthLowTile              equ     $FFFF8520       ; was: word_FF8520
BossClearCursorTile             equ     $FFFF8522       ; was: word_FF8522
PaletteEntryCursorTile          equ     $FFFF8532       ; was: word_FF8532
PalettePreviewBuffer            equ     $FFFF8534       ; was: byte_FF8534
ColorEditCursorTile             equ     $FFFF8554       ; was: word_FF8554
BossDebugDMABuffer              equ     $FFFF8560       ; was: dword_FF8560
BossDebugTileBuffer             equ     $FFFF8570       ; was: byte_FF8570
DebugSoundCursorTile            equ     $FFFF8572       ; was: word_FF8572
DebugSoundHighTile              equ     $FFFF857E       ; was: word_FF857E
DebugSoundLowTile               equ     $FFFF8580       ; was: word_FF8580
PaletteLineCursorTile           equ     $FFFF8582       ; was: word_FF8582
PaletteLineNumberTile           equ     $FFFF858A       ; was: word_FF858A
StageTimerTileBuffer            equ     $FFFF85A8       ; was: byte_FF85A8
DebugColorRedTile               equ     $FFFF85B6       ; was: word_FF85B6
DebugColorGreenTile             equ     $FFFF85B8       ; was: word_FF85B8
DebugColorBlueTile              equ     $FFFF85BA       ; was: word_FF85BA
ScrollPlaneBufferOffset         equ     $FFFF8640       ; was: word_FF8640
TargetReticleScanDelay          equ     $FFFF8642       ; was: word_FF8642
ScriptedInputStepTimer          equ     $FFFF8644       ; was: word_FF8644
ScriptedInputTargetX            equ     $FFFF8646       ; was: word_FF8646
ScriptedInputDelay              equ     $FFFF8648       ; was: word_FF8648
ScriptedPlayerWorldX            equ     $FFFF8652       ; was: word_FF8652
DebugMenuPageOffset             equ     $FFFF8660       ; was: word_FF8660
DebugPaletteLineOffset          equ     $FFFF8662       ; was: word_FF8662
DebugPaletteEntryOffset         equ     $FFFF8664       ; was: word_FF8664
DebugColorEditActive            equ     $FFFF8666       ; was: word_FF8666
DebugColorChannelOffset         equ     $FFFF8668       ; was: word_FF8668
DebugMenuPreviousInput          equ     $FFFF866A       ; was: byte_FF866A
DebugHealthSelection            equ     $FFFF866B       ; was: byte_FF866B
DebugMenuRepeatTimer            equ     $FFFF866C       ; was: word_FF866C
PlayerSpritePieceBuffer         equ     $FFFF8780       ; was: byte_FF8780
HorizontalScrollProfile         equ     $FFFF8800       ; was: byte_FF8800
VerticalScrollProfile           equ     $FFFF8A00       ; was: dword_FF8A00
MidgameParallaxValue0           equ     $FFFF8A04       ; was: word_FF8A04
MidgameParallaxValue1           equ     $FFFF8A08       ; was: word_FF8A08
MidgameParallaxValue2           equ     $FFFF8A0C       ; was: word_FF8A0C
MidgameParallaxValue3           equ     $FFFF8A10       ; was: word_FF8A10
PrimaryListCountMinus1          equ     $FFFF8D76       ; was: word_FF8D76
TargetListCountMinus1           equ     $FFFF8D78       ; was: word_FF8D78
LockOnListCountMinus1           equ     $FFFF8D7A       ; was: word_FF8D7A
PlatformListCountMinus1         equ     $FFFF8D7C       ; was: word_FF8D7C
WeaponListCountMinus1           equ     $FFFF8D7E       ; was: word_FF8D7E
PrimaryCollisionList            equ     $FFFF8D80       ; was: byte_FF8D80
CollisionTargetList             equ     $FFFF8E00       ; was: byte_FF8E00
LockOnTargetList                equ     $FFFF8E80       ; was: byte_FF8E80
MovingPlatformList              equ     $FFFF8F00       ; was: byte_FF8F00
PlayerWeaponList                equ     $FFFF8F80       ; was: byte_FF8F80
GameOverRasterBuffer            equ     $FFFF9000       ; was: byte_FF9000
SharedPatternRow0Long0          equ     $FFFF9400       ; was: dword_FF9400
SharedPatternRow0Long1          equ     $FFFF9404       ; was: dword_FF9404
SharedPatternRow0Long2          equ     $FFFF9408       ; was: dword_FF9408
SharedPatternRow0Long3          equ     $FFFF940C       ; was: dword_FF940C
SharedPatternRow0Long4          equ     $FFFF9410       ; was: dword_FF9410
SharedPatternRow0Long5          equ     $FFFF9414       ; was: dword_FF9414
SharedPatternRow0Long6          equ     $FFFF9418       ; was: dword_FF9418
SharedPatternRow0Long7          equ     $FFFF941C       ; was: dword_FF941C
SharedPatternRow1Long0          equ     $FFFF9420       ; was: dword_FF9420
SharedPatternRow1Long1          equ     $FFFF9424       ; was: dword_FF9424
SharedPatternRow1Long2          equ     $FFFF9428       ; was: dword_FF9428
SharedPatternRow1Long3          equ     $FFFF942C       ; was: dword_FF942C
SharedPatternRow1Long4          equ     $FFFF9430       ; was: dword_FF9430
SharedPatternRow1Long5          equ     $FFFF9434       ; was: dword_FF9434
SharedPatternRow1Long6          equ     $FFFF9438       ; was: dword_FF9438
SharedPatternRow1Long7          equ     $FFFF943C       ; was: dword_FF943C
TransitionPatternBuffer         equ     SharedPatternRow0Long0
TransitionPatternRow0           equ     SharedPatternRow0Long0
TransitionPatternRow1           equ     SharedPatternRow1Long0
SharedPatternWorkBuffer         equ     $FFFF9440       ; was: word_FF9440
SharedPatternWorkWord1          equ     $FFFF9442       ; was: word_FF9442
SharedPatternWorkWord2          equ     $FFFF9444       ; was: word_FF9444
TransitionPatternRow2           equ     SharedPatternWorkBuffer
ShieldViperBranchParity         equ     SharedPatternWorkBuffer
ResultsLayoutModeCopy           equ     SharedPatternWorkWord1
ResultsDisplayState             equ     SharedPatternRow0Long0
ResultsRenderedRowCount         equ     SharedPatternRow0Long0+2
ResultsRowTileOffset            equ     SharedPatternRow0Long1
ResultsRowBufferOffset          equ     SharedPatternRow0Long1+2
ResultsHighlightPalette         equ     SharedPatternRow0Long1+2
ResultsScrollTargetY            equ     SharedPatternRow0Long2
ResultsStageTimeScratch         equ     SharedPatternRow0Long2+2
ResultsPhaseTimeScratch         equ     SharedPatternRow0Long3
ResultsEndTimeScratch           equ     SharedPatternRow0Long3+2
ResultsBCDEndTime               equ     SharedPatternRow0Long4
ResultsBCDStartTime             equ     SharedPatternRow0Long4+2
ResultsViewportRow              equ     SharedPatternRow0Long5
ResultsSelectedRowData          equ     SharedPatternRow0Long5+2
ResultsSelectedRowTile          equ     SharedPatternRow0Long6
ResultsHorizontalStep           equ     SharedPatternRow0Long6+2
ResultsVerticalStep             equ     SharedPatternRow0Long7
ResultsDetailTextOffset         equ     SharedPatternRow0Long7+2
ResultsSelectedTextPos          equ     SharedPatternRow1Long0
ResultsCurrentRowPtr            equ     SharedPatternRow1Long0+2
ResultsMusicQueuedFlag          equ     SharedPatternRow1Long1
ResultsTotalTimeBCD             equ     SharedPatternRow1Long2
ResultsTotalClearBCD            equ     SharedPatternRow1Long3
ResultsTotalVisitsBCD           equ     SharedPatternRow1Long4
ResultsLimitTimeSeconds         equ     SharedPatternRow1Long5
ResultsClearTimeSeconds         equ     SharedPatternRow1Long5+2
ResultsTotalVisitCount          equ     SharedPatternRow1Long6
ResultsHorizontalActive         equ     SharedPatternRow1Long6+2
ResultsLowerScrollBound         equ     SharedPatternRow1Long7
ResultsLastScrollRow            equ     SharedPatternRow1Long7+2
Epsilon1TileBandIndex           equ     SharedPatternWorkWord2
Epsilon1TileDMARecord           equ     $FFFF9446       ; was: word_FF9446
SharedPatternStateLong0         equ     $FFFF944E       ; was: dword_FF944E
SharedPatternStateLong1         equ     $FFFF9452       ; was: dword_FF9452
SharedPatternStateLong2         equ     $FFFF9456       ; was: dword_FF9456
SharedPatternStateWord0         equ     $FFFF945C       ; was: word_FF945C
SharedPatternStateWord1         equ     $FFFF945E       ; was: word_FF945E
SharedPatternStateWord2         equ     $FFFF9460       ; was: word_FF9460
SharedPatternStateLong3         equ     $FFFF9466       ; was: dword_FF9466
SharedPatternStateLong4         equ     $FFFF946A       ; was: dword_FF946A
SharedPatternStateLong5         equ     $FFFF946E       ; was: dword_FF946E
Epsilon1RingPhaseTable          equ     SharedPatternStateLong0
ResultsStageRowBuffer           equ     SharedPatternStateLong0+2
ShieldViperEffectStepA          equ     SharedPatternStateLong0+2
ShieldViperEffectStepB          equ     SharedPatternStateLong1+2
ShieldViperEffectStepC          equ     SharedPatternStateLong2+2
ShieldViperEffectPhaseA         equ     SharedPatternStateWord0
ShieldViperEffectPhaseB         equ     SharedPatternStateWord1
ShieldViperEffectPhaseC         equ     SharedPatternStateWord2
Epsilon1RowOffsetTable          equ     SharedPatternStateLong3
Epsilon1ProximityTimer          equ     $FFFF9472       ; was: word_FF9472
Epsilon1ProximityFlag           equ     $FFFF9474       ; was: word_FF9474
Epsilon1VerticalAccel           equ     $FFFF9478       ; was: dword_FF9478
SharedProfileBuffer             equ     $FFFF9480       ; was: word_FF9480
TransitionRampBuffer            equ     SharedProfileBuffer
Epsilon1AngleHistory            equ     SharedProfileBuffer
ViblackScrollSamples            equ     SharedProfileBuffer
ShieldViperTrailAngles          equ     $FFFF94A0       ; was: word_FF94A0
SharedSceneOverlayBase          equ     $FFFF9500       ; was: word_FF9500
TransitionWorkingBuffer         equ     SharedSceneOverlayBase
FlyingNeoRasterBuffer           equ     SharedSceneOverlayBase
SniperHoneyviperCosineTable     equ     SharedSceneOverlayBase
SirenePatternBuffer             equ     SharedSceneOverlayBase
ZLeoDropProjectileFlag          equ     SharedSceneOverlayBase
SharedPatternOverlay            equ     $FFFF9502       ; was: word_FF9502
GustheadMappingCounts           equ     SharedPatternOverlay
SirenePatternAltB               equ     SharedPatternOverlay
FlyingNeoVScrollRamp            equ     $FFFF9506       ; was: byte_FF9506
SirenePatternNormalA            equ     $FFFF9508       ; was: word_FF9508
SirenePatternAltA               equ     $FFFF9510       ; was: word_FF9510
SirenePatternNormalB            equ     $FFFF951A       ; was: word_FF951A
BossPerspectiveRows             equ     $FFFF9520       ; was: byte_FF9520
BugmaxPositionHistory           equ     $FFFF95E0       ; was: word_FF95E0
SharedSceneWorkspace            equ     $FFFF9600       ; was: word_FF9600
TransitionVScrollBuffer         equ     SharedSceneWorkspace
BugmaxAngleHistoryRows          equ     SharedSceneWorkspace
BackStringerPoseBuffer          equ     SharedSceneWorkspace
SevenForcesPattern              equ     SharedSceneWorkspace
JokerTileWordGroupA             equ     SharedSceneWorkspace
ZLeoTileScrollIndex             equ     SharedSceneWorkspace
SharpssteelTargetTrail          equ     SharedSceneWorkspace
FlyCorridorTilemap              equ     SharedSceneWorkspace
TileInterpSourceB               equ     SharedSceneWorkspace
SharedCameraPatternWord         equ     $FFFF9602       ; was: word_FF9602
ZLeoPreviousCameraY             equ     SharedCameraPatternWord
SevenForcesAltPatchB            equ     SharedCameraPatternWord
ZLeoTileDMARecord               equ     $FFFF9604       ; was: byte_FF9604
SharedPosePatternBase           equ     $FFFF9608       ; was: word_FF9608
BackStringerPoseGroup           equ     SharedPosePatternBase
SevenForcesPatchA               equ     SharedPosePatternBase
SharpssteelTargetTail           equ     $FFFF960A       ; was: word_FF960A
SharedScrollPatternLong         equ     $FFFF9610       ; was: dword_FF9610
SevenForcesMedusaSpeed          equ     SharedScrollPatternLong
SevenForcesAltPatchA            equ     SharedScrollPatternLong
JokerTileWordGroupB             equ     SharedScrollPatternLong
SharedPoseTileLong              equ     $FFFF9614       ; was: dword_FF9614
SevenForcesPlaneASpeed          equ     SharedPoseTileLong
SevenForcesPatchB               equ     $FFFF961A       ; was: word_FF961A
SevenForcesPlaneBSpeed          equ     $FFFF961C       ; was: dword_FF961C
SharedWordWorkspace             equ     $FFFF9620       ; was: word_FF9620
DestroyerMK2RowSpeeds           equ     SharedWordWorkspace
ShieldViperAngleDelay           equ     SharedWordWorkspace
SevenForcesFadeValue            equ     SharedWordWorkspace
SevenForcesAltPatchD            equ     $FFFF9622       ; was: word_FF9622
SevenForcesPatchC               equ     $FFFF9628       ; was: word_FF9628
SevenForcesAltPatchC            equ     $FFFF9630       ; was: word_FF9630
SevenForcesPatchD               equ     $FFFF963A       ; was: word_FF963A
BugmaxAuxAngleHistory           equ     $FFFF9680       ; was: word_FF9680
ShieldViperPoseHistory          equ     $FFFF9700       ; was: dword_FF9700
SharedSceneDataBuffer           equ     $FFFF9800       ; was: word_FF9800
TileInterpolationBlockA         equ     SharedSceneDataBuffer
TransitionHScrollBuffer         equ     SharedSceneDataBuffer
GameOverRowWorkBuffer           equ     SharedSceneDataBuffer
CaterpillarPhaseTable           equ     SharedSceneDataBuffer
FlyingNeoAngleHistory           equ     SharedSceneDataBuffer
JetsripperAngleHistory          equ     SharedSceneDataBuffer
PasswordDigitTextBuffer         equ     SharedSceneDataBuffer
MadamBarbarWorkObject           equ     SharedSceneDataBuffer
MedusaSequenceOffset            equ     SharedSceneDataBuffer
SunsetStingSharedState          equ     SharedSceneDataBuffer
SirenePoseHistory               equ     SharedSceneDataBuffer
Stage3ScaleStepTable            equ     SharedSceneDataBuffer
CRAMWriteEffectBuffer           equ     SharedSceneDataBuffer
WaveOutputBuffer                equ     SharedSceneDataBuffer
MedusaSpawnSequenceFlag         equ     $FFFF9804       ; was: word_FF9804
FlyingNeoAngleTapBase           equ     $FFFF9806       ; was: byte_FF9806
JetsripperAngleTapBase          equ     $FFFF9808       ; was: byte_FF9808
SunsetStingWaveTable            equ     $FFFF9810       ; was: word_FF9810
BossBackdropBandBufferA         equ     $FFFF981E       ; was: byte_FF981E
DestroyerMK2ScrollRows          equ     $FFFF9820       ; was: word_FF9820
ResultsSummaryRowBuffer         equ     $FFFF9852       ; was: word_FF9852
TileInterpolationBlockB         equ     $FFFF9880       ; was: word_FF9880
DestroyerMK2ScrollTable         equ     $FFFF98B0       ; was: word_FF98B0
SharedSceneOverlayWord          equ     $FFFF9900       ; was: word_FF9900
TileInterpolationBlockC         equ     SharedSceneOverlayWord
PasswordPrimaryBuffer           equ     SharedSceneOverlayWord
FlyingNeoSineTable              equ     SharedSceneOverlayWord
PasswordStageTensGlyph          equ     $FFFF9906       ; was: byte_FF9906
PasswordStageOnesGlyph          equ     $FFFF9907       ; was: byte_FF9907
PasswordSecondaryBuffer         equ     $FFFF9980       ; was: byte_FF9980
SunsetStingWaveTableEnd         equ     $FFFF99A0       ; was: dword_FF99A0
SharedGeometryWorkspace         equ     $FFFF9A00       ; was: dword_FF9A00
TransitionRasterWork            equ     SharedGeometryWorkspace
GameOverRasterSource            equ     SharedGeometryWorkspace
BossBackdropWorkBuffer          equ     SharedGeometryWorkspace
FlyingNeoCosineTable            equ     SharedGeometryWorkspace
SniperHoneyviperRotationHistory equ     SharedGeometryWorkspace
ShieldViperOffsetTable          equ     SharedGeometryWorkspace
TransitionEdgeCenter4           equ     $FFFF9A80       ; was: byte_FF9A80
SharedTransitionBuffer          equ     $FFFF9B00       ; was: byte_FF9B00
TransitionEdgeCenter1           equ     SharedTransitionBuffer
BossBackdropCopySource          equ     SharedTransitionBuffer
BossBackdropBandBufferB         equ     $FFFF9B1E       ; was: byte_FF9B1E
ShieldViperBackdropRow          equ     $FFFF9B80       ; was: byte_FF9B80
RasterStagingBuffer             equ     $FFFF9C00       ; was: word_FF9C00
FlyCorridorRasterBuffer         equ     RasterStagingBuffer
ShieldViperXferBuffer           equ     RasterStagingBuffer
RasterVScrollPairBuffer         equ     $FFFF9C04       ; was: byte_FF9C04
WeaponSetupRasterLines          equ     $FFFF9C1E       ; was: byte_FF9C1E
WeaponSetupOffsetCenter         equ     $FFFF9C80       ; was: byte_FF9C80
SharedLineOffsetBuffer          equ     $FFFF9CE0       ; was: word_FF9CE0
StoryTitleScrollOffsets         equ     SharedLineOffsetBuffer
SunsetStingWaveOffsets          equ     SharedLineOffsetBuffer
SharedPatternBuffer             equ     $FFFF9D80       ; was: byte_FF9D80
BackdropScrollPattern           equ     SharedPatternBuffer
ShieldViperEffectBuffer         equ     SharedPatternBuffer
BackdropRasterSpan              equ     $FFFF9D90       ; was: dword_FF9D90
BackdropBandOffset              equ     $FFFF9D94       ; was: word_FF9D94
BackdropLinePhase               equ     $FFFF9D96       ; was: dword_FF9D96
BackdropVelocityB               equ     $FFFF9D9E       ; was: dword_FF9D9E
BackdropVelocityA               equ     $FFFF9DA2       ; was: dword_FF9DA2
BackdropPositionB               equ     $FFFF9DA6       ; was: dword_FF9DA6
BackdropPositionA               equ     $FFFF9DAA       ; was: dword_FF9DAA
BossBackdropFadeLevel           equ     $FFFF9DAE       ; was: word_FF9DAE
StageSceneDelayTimer            equ     $FFFF9DB0       ; was: word_FF9DB0
BackdropCameraYPos              equ     $FFFF9DB2       ; was: dword_FF9DB2
WolfGaropaBackdropYVel          equ     $FFFF9DB6       ; was: dword_FF9DB6
WolfGaropaEffectActive          equ     $FFFF9DBA       ; was: byte_FF9DBA
ShieldViperRowVRAMPos           equ     $FFFF9DFC       ; was: word_FF9DFC
ShieldViperRowIndex             equ     $FFFF9DFE       ; was: word_FF9DFE
ActiveRasterBuffer              equ     $FFFF9E00       ; was: word_FF9E00
ZLeoRasterBuildBuffer           equ     ActiveRasterBuffer
SniperHoneyviperRasterControl   equ     $FFFF9E02       ; was: word_FF9E02
BossBackdropLeadBands           equ     $FFFF9E0E       ; was: byte_FF9E0E
BossTransitionRaster            equ     $FFFF9E1E       ; was: byte_FF9E1E
RasterSecondaryBuffer           equ     $FFFF9E40       ; was: word_FF9E40
ZLeoRasterCommands              equ     RasterSecondaryBuffer
BossBackdropBandSource          equ     RasterSecondaryBuffer
SharedRasterSplitPoint          equ     $FFFF9F00       ; was: byte_FF9F00
BackdropLineOffsetsEnd          equ     SharedRasterSplitPoint
WaveSineTableCenter             equ     SharedRasterSplitPoint
CutsceneScaleStep               equ     $FFFF9F08       ; was: dword_FF9F08
CutsceneScaleSnapshot           equ     $FFFF9F0C       ; was: dword_FF9F0C
CutsceneOffsetCenter            equ     $FFFF9F10       ; was: word_FF9F10
CutsceneRowLoopLimit            equ     $FFFF9F12       ; was: word_FF9F12
CutsceneVerticalOffset          equ     $FFFF9F14       ; was: word_FF9F14
CutsceneLineOffsetTable         equ     $FFFF9F80       ; was: byte_FF9F80
XiTigerVScrollBuffer            equ     $FFFF9FC0       ; was: word_FF9FC0
Stage10HBlankScrollData         equ     $FFFF9FF8       ; was: byte_FF9FF8
FrameCounter                    equ     $FFFFA000       ; was: word_FFA000
ScoreAddendPrefixByte           equ     $FFFFA005       ; was: byte_FFA005
ScoreAddendBCD                  equ     $FFFFA006       ; was: dword_FFA006
P2DebugCoarseXValue             equ     $FFFFA00A       ; was: word_FFA00A
P2DebugCoarseYValue             equ     $FFFFA00C       ; was: word_FFA00C
P2DebugFineYValue               equ     $FFFFA00E       ; was: word_FFA00E
PlaneAShakeLevel                equ     $FFFFA010       ; was: word_FFA010
PlaneAShakeOffset               equ     $FFFFA012       ; was: word_FFA012
PlaneBShakeLevel                equ     $FFFFA014       ; was: word_FFA014
PlaneBShakeOffset               equ     $FFFFA016       ; was: word_FFA016
PlayerScriptStateOffset         equ     $FFFFA02A       ; was: word_FFA02A
SharedSpriteScratch             equ     $FFFFA100       ; was: dword_FFA100
SpriteScratchTileWord0          equ     $FFFFA104       ; was: byte_FFA104
SpriteScratchEntry1             equ     $FFFFA108       ; was: byte_FFA108
RadialSpriteYBackward           equ     $FFFFA120       ; was: byte_FFA120
RadialSpriteXBackward           equ     $FFFFA126       ; was: byte_FFA126
RadialSpriteYForward            equ     $FFFFA128       ; was: byte_FFA128
RadialSpriteXForward            equ     $FFFFA12E       ; was: byte_FFA12E
LinearSpriteYStart              equ     $FFFFA150       ; was: byte_FFA150
LinearSpriteXStart              equ     $FFFFA156       ; was: byte_FFA156
TimeDigitTileWordStart          equ     $FFFFA17C       ; was: byte_FFA17C
GameplayStateBlock              equ     $FFFFA200       ; was: dword_FFA200
StageTableIndex                 equ     $FFFFA204       ; was: word_FFA204
StageProcessTableOffset         equ     $FFFFA206       ; was: word_FFA206
StageRouteFlags                 equ     $FFFFA209       ; was: byte_FFA209
StageObjectSpawnCursor          equ     $FFFFA20E       ; was: dword_FFA20E
ScoreValueBCD                   equ     $FFFFA212       ; was: dword_FFA212
PlayerHealth                    equ     $FFFFA216       ; was: word_FFA216
PlayerMaxHealth                 equ     $FFFFA218       ; was: word_FFA218
WeaponStateIndex                equ     $FFFFA21C       ; was: word_FFA21C
WeaponIconTransferState         equ     $FFFFA21E       ; was: word_FFA21E
WeaponSavedSlotOffset           equ     $FFFFA220       ; was: word_FFA220
ContinueCreditsBCD              equ     $FFFFA228       ; was: word_FFA228
ShootingMode                    equ     $FFFFA22A       ; was: word_FFA22A
StageMessageCursor              equ     $FFFFA22C       ; was: dword_FFA22C
PendingStageBGMRequest          equ     $FFFFA230       ; was: byte_FFA230
WeaponSlotOffset                equ     $FFFFA24E       ; was: word_FFA24E
WeaponSlotConfig0               equ     $FFFFA250       ; was: word_FFA250
WeaponSlotConfig1               equ     $FFFFA252       ; was: word_FFA252
WeaponSlotConfig2               equ     $FFFFA254       ; was: word_FFA254
WeaponSlotConfig3               equ     $FFFFA256       ; was: word_FFA256
WeaponAmmoRegenTimers           equ     $FFFFA258       ; was: byte_FFA258
WeaponSlotAmmo0                 equ     $FFFFA260       ; was: word_FFA260
WeaponSlotAmmo1                 equ     $FFFFA262       ; was: word_FFA262
WeaponSlotAmmo2                 equ     $FFFFA264       ; was: word_FFA264
WeaponSlotAmmo3                 equ     $FFFFA266       ; was: word_FFA266
WeaponSlotAmmoMax0              equ     $FFFFA268       ; was: word_FFA268
WeaponSlotAmmoMax1              equ     $FFFFA26A       ; was: word_FFA26A
WeaponSlotAmmoMax2              equ     $FFFFA26C       ; was: word_FFA26C
WeaponSlotAmmoMax3              equ     $FFFFA26E       ; was: word_FFA26E
StageTimeRemaining              equ     $FFFFA270       ; was: word_FFA270
StageTimerPauseFlag             equ     $FFFFA272       ; was: byte_FFA272
VBlankFrameCounter              equ     $FFFFA280       ; was: word_FFA280
VBlankCountdown                 equ     $FFFFA282       ; was: word_FFA282
GameModeIndex                   equ     $FFFFA284       ; was: word_FFA284
GameSubstateIndex               equ     $FFFFA286       ; was: word_FFA286
SetupTransitionIndex            equ     $FFFFA29C       ; was: word_FFA29C
MessageGlyphTileBuffer          equ     $FFFFA300       ; was: byte_FFA300
SnakeScrollAccumulators         equ     $FFFFA3E0       ; was: byte_FFA3E0
PlayerObjectType                equ     $FFFFA400       ; was: word_FFA400
PlayerObjectFlags               equ     $FFFFA402       ; was: word_FFA402
PlayerStateOffset               equ     $FFFFA404       ; was: word_FFA404
PlayerWallContactFlags          equ     $FFFFA407       ; was: byte_FFA407
PlayerSpriteMapping             equ     $FFFFA408       ; was: dword_FFA408
PlayerAnimationTimer            equ     $FFFFA40C       ; was: word_FFA40C
PlayerSpriteAttributes          equ     $FFFFA40E       ; was: word_FFA40E
PlayerXPosition                 equ     $FFFFA410       ; was: dword_FFA410
PlayerYPosition                 equ     $FFFFA414       ; was: dword_FFA414
PlayerXVelocity                 equ     $FFFFA418       ; was: dword_FFA418
PlayerYVelocity                 equ     $FFFFA41C       ; was: dword_FFA41C
PlayerOAMBucketOffset           equ     $FFFFA420       ; was: byte_FFA420
PlayerStateWorkHighWord         equ     $FFFFA448       ; was: word_FFA448
PlayerInvulnTimer               equ     $FFFFA45E       ; was: word_FFA45E
PlayerPressedInput              equ     $FFFFA46A       ; was: byte_FFA46A
ObjectBufferSecondHalf          equ     $FFFFA600       ; was: dword_FFA600
OrphanedObjectType              equ     $FFFFA800       ; was: word_FFA800
OrphanedObjectFlags             equ     $FFFFA802       ; was: word_FFA802
OrphanedObjectSpriteMap         equ     $FFFFA808       ; was: dword_FFA808
OrphanedObjectAnimTimer         equ     $FFFFA80C       ; was: word_FFA80C
OrphanedObjectAttr              equ     $FFFFA80E       ; was: word_FFA80E
OrphanedObjectXPosition         equ     $FFFFA810       ; was: word_FFA810
OrphanedObjectXFraction         equ     $FFFFA812       ; was: word_FFA812
OrphanedObjectYPosition         equ     $FFFFA814       ; was: word_FFA814
OrphanedObjectYFraction         equ     $FFFFA816       ; was: word_FFA816
OrphanedObjectXVelocity         equ     $FFFFA818       ; was: dword_FFA818
OrphanedObjectYVelocity         equ     $FFFFA81C       ; was: dword_FFA81C
PrimaryCameraXPosition          equ     $FFFFA900       ; was: dword_FFA900
PrimaryCameraYPosition          equ     $FFFFA904       ; was: dword_FFA904
SecondaryCameraXPos             equ     $FFFFA908       ; was: dword_FFA908
SecondaryCameraYPos             equ     $FFFFA90C       ; was: dword_FFA90C
CameraXDelta                    equ     $FFFFA910       ; was: dword_FFA910
CameraYDelta                    equ     $FFFFA914       ; was: word_FFA914
Stage9RasterScrollPhase         equ     $FFFFA918       ; was: dword_FFA918
StageCameraYVelocity            equ     $FFFFA91C       ; was: dword_FFA91C
PreviousCameraXPosition         equ     $FFFFA928       ; was: word_FFA928
PreviousCameraYPosition         equ     $FFFFA92C       ; was: word_FFA92C
CameraDeltaLowerLimit           equ     $FFFFA930       ; was: dword_FFA930
PhysicsXVelocityLimit           equ     $FFFFA938       ; was: dword_FFA938
PhysicsYVelocityLimit           equ     $FFFFA93C       ; was: dword_FFA93C
TilemapTransferBase             equ     $FFFFA940       ; was: dword_FFA940
TilemapRowCountdown             equ     $FFFFA944       ; was: word_FFA944
TilemapRowXOrFillWord           equ     $FFFFA946       ; was: word_FFA946
TilemapRowYPosition             equ     $FFFFA948       ; was: word_FFA948
StageStateOffset                equ     $FFFFA950       ; was: word_FFA950
SceneSequenceFlags              equ     $FFFFA958       ; was: byte_FFA958
CameraMotionLockFlags           equ     $FFFFA959       ; was: byte_FFA959
PlaneAScrollModeFlags           equ     $FFFFA95A       ; was: byte_FFA95A
PlaneBScrollModeFlags           equ     $FFFFA95B       ; was: byte_FFA95B
StageSceneWorkLong0             equ     $FFFFA960       ; was: dword_FFA960
StageSceneWorkWord0             equ     StageSceneWorkLong0
GustheadArenaVelocity           equ     StageSceneWorkLong0
AsteroidFieldVelocity           equ     StageSceneWorkLong0
MidgameVerticalPhase            equ     StageSceneWorkLong0
SevenForcesTimer                equ     StageSceneWorkLong0
MissirayParallaxSpeed           equ     StageSceneWorkLong0
StageSceneWorkWord1             equ     StageSceneWorkLong0+2
Stage8ApproachTimer             equ     StageSceneWorkLong0+2
SevenForcesCloseSpan            equ     StageSceneWorkLong0+2
Stage9FlyCorridorY              equ     StageSceneWorkLong0+2
StageSceneWorkLong1             equ     $FFFFA964       ; was: dword_FFA964
AsteroidFieldPosition           equ     StageSceneWorkLong1
FlyingNeoYVelocity              equ     StageSceneWorkLong1
StageSceneWorkWord2             equ     $FFFFA968       ; was: word_FFA968
AsteroidBoundaryPhase           equ     StageSceneWorkWord2
GustheadFinalPhaseFlag          equ     StageSceneWorkWord2
AsteroidBoundaryFlag            equ     $FFFFA96A       ; was: byte_FFA96A
CameraXLowerBound               equ     $FFFFA970       ; was: word_FFA970
CameraXUpperBound               equ     $FFFFA974       ; was: word_FFA974
DebugJumpInput                  equ     $FFFFA980       ; was: word_FFA980
DebugAttackInput                equ     $FFFFA9C0       ; was: word_FFA9C0
DebugInputXDirection            equ     $FFFFA9D0       ; was: dword_FFA9D0
DebugInputYDirection            equ     $FFFFA9D4       ; was: dword_FFA9D4
StagePhaseSplitTimes            equ     $FFFFAA00       ; was: word_FFAA00
StageCompletionTimes            equ     $FFFFAA80       ; was: word_FFAA80
StageResultVisits               equ     $FFFFAB00       ; was: word_FFAB00
ClearedWorkBuffer512            equ     $FFFFB200       ; was: dword_FFB200
GraphicsStagingBuffer           equ     $FFFFB400       ; was: dword_FFB400
TileDecodeBufferEnd             equ     $FFFFB480       ; was: dword_FFB480
TileDMABatchBuffer              equ     $FFFFB600       ; was: dword_FFB600
ClearedWorkBuffer192            equ     $FFFFB800       ; was: dword_FFB800
SpriteOAMEntryCount             equ     $FFFFBE00       ; was: byte_FFBE00
SpriteOAMFreeSlots              equ     $FFFFBE01       ; was: byte_FFBE01
SpriteOAMWritePointer           equ     $FFFFBE02       ; was: word_FFBE02
SpritePriorityBuckets           equ     $FFFFBE04       ; was: dword_FFBE04
SharedEffectObjectPool          equ     $FFFFBFC0       ; was: dword_FFBFC0
EffectCollisionOddStart         equ     $FFFFC020       ; was: byte_FFC020
PlayerEffectObjectPool          equ     $FFFFC2C0       ; was: byte_FFC2C0
PlayerEffectAllocStart          equ     $FFFFC320       ; was: byte_FFC320
PlayerSpecialObjectSlot         equ     $FFFFC5C0       ; was: word_FFC5C0
Entity_ObjectPool               equ     $FFFFC620       ; was: word_FFC620
PrimaryEntityFlags              equ     $FFFFC622       ; was: word_FFC622
PrimaryEntityState              equ     $FFFFC624       ; was: word_FFC624
PrimaryEntityMapping            equ     $FFFFC628       ; was: dword_FFC628
PrimaryEntitySpriteAttr         equ     $FFFFC62E       ; was: word_FFC62E
PrimaryEntityXPos               equ     $FFFFC630       ; was: dword_FFC630
PrimaryEntityYPos               equ     $FFFFC634       ; was: dword_FFC634
PrimaryEntityXVelocity          equ     $FFFFC638       ; was: dword_FFC638
PrimaryEntityAngle              equ     $FFFFC640       ; was: byte_FFC640
PrimaryEntityStatus             equ     $FFFFC641       ; was: byte_FFC641
PrimaryEntityWork4A             equ     $FFFFC66A       ; was: byte_FFC66A
PrimaryEntityWork4B             equ     $FFFFC66B       ; was: byte_FFC66B
PrimaryEntityWork4C             equ     $FFFFC66C       ; was: word_FFC66C
PrimaryEntityWork58             equ     $FFFFC678       ; was: word_FFC678
PrimaryEntityWork5A             equ     $FFFFC67A       ; was: word_FFC67A
PrimaryEntityWork5C             equ     $FFFFC67C       ; was: word_FFC67C
PrimaryEntityWork5E             equ     $FFFFC67E       ; was: word_FFC67E
EntityType1C0ChainRootOffset    equ     PrimaryEntityWork58
EntityType1C0PartYReference     equ     PrimaryEntityWork5A
EntityType1C0BodyPartCount      equ     PrimaryEntityWork5C
EntityType1C0AnimationProgress  equ     PrimaryEntityWork5E
SecondaryEntityType             equ     $FFFFC680       ; was: word_FFC680
SecondaryEntityFlags            equ     $FFFFC682       ; was: word_FFC682
SecondaryEntityState            equ     $FFFFC684       ; was: word_FFC684
SecondaryEntityXPos             equ     $FFFFC690       ; was: dword_FFC690
SecondaryEntityYPos             equ     $FFFFC694       ; was: dword_FFC694
SecondaryEntityXVel             equ     $FFFFC698       ; was: dword_FFC698
SecondaryEntityYVel             equ     $FFFFC69C       ; was: dword_FFC69C
SecondaryEntityStatus           equ     $FFFFC6A1       ; was: byte_FFC6A1
SecondaryEntityWork40           equ     $FFFFC6C0       ; was: word_FFC6C0
SecondaryEntityWork46           equ     $FFFFC6C6       ; was: word_FFC6C6
SecondaryEntityWork4C           equ     $FFFFC6CC       ; was: word_FFC6CC
SecondaryEntityWork52           equ     $FFFFC6D2       ; was: word_FFC6D2
SecondaryEntityWork58           equ     $FFFFC6D8       ; was: dword_FFC6D8
SecondaryEntityWork5C           equ     $FFFFC6DC       ; was: dword_FFC6DC
EntityType1C0OscillationPhase   equ     SecondaryEntityWork58
TertiaryEntityType              equ     $FFFFC6E0       ; was: word_FFC6E0
TertiaryEntityFlags             equ     $FFFFC6E2       ; was: word_FFC6E2
TertiaryEntityAttr              equ     $FFFFC6EE       ; was: word_FFC6EE
TertiaryEntityXPos              equ     $FFFFC6F0       ; was: dword_FFC6F0
TertiaryEntityYPos              equ     $FFFFC6F4       ; was: dword_FFC6F4
TertiaryEntityStatus            equ     $FFFFC701       ; was: byte_FFC701
TertiaryEntityWork40            equ     $FFFFC720       ; was: word_FFC720
TertiaryEntityWork4C            equ     $FFFFC72C       ; was: word_FFC72C
TertiaryEntityWork50            equ     $FFFFC730       ; was: word_FFC730
TertiaryEntityWork52            equ     $FFFFC732       ; was: word_FFC732
EntityType1C0TrailSpan          equ     $FFFFC738       ; was: word_FFC738
EntityType1C0TrailStep          equ     $FFFFC73C       ; was: word_FFC73C
EntityType1C0AimAngle           equ     $FFFFC73E       ; was: byte_FFC73E
QuaternaryEntityType            equ     $FFFFC740       ; was: word_FFC740
QuaternaryEntityFlags           equ     $FFFFC742       ; was: word_FFC742
QuaternaryEntityState           equ     $FFFFC744       ; was: word_FFC744
QuaternaryEntityStatus          equ     $FFFFC761       ; was: byte_FFC761
QuaternaryEntityWork40          equ     $FFFFC780       ; was: word_FFC780
QuaternaryEntityWork46          equ     $FFFFC786       ; was: word_FFC786
QuaternaryEntityWork52          equ     $FFFFC792       ; was: word_FFC792
EntityType1C0ChainPeriod        equ     $FFFFC79C       ; was: byte_FFC79C
FifthEntityType                 equ     $FFFFC7A0       ; was: word_FFC7A0
FifthEntityFlags                equ     $FFFFC7A2       ; was: word_FFC7A2
FifthEntityState                equ     $FFFFC7A4       ; was: word_FFC7A4
FifthEntityWork40               equ     $FFFFC7E0       ; was: word_FFC7E0
FifthEntityWork52               equ     $FFFFC7F2       ; was: word_FFC7F2
EntityType1C0ChainCycle         equ     $FFFFC7F8       ; was: word_FFC7F8
FifthEntityWork5C               equ     $FFFFC7FC       ; was: byte_FFC7FC
EntityType1C0PoseRadius         equ     $FFFFC7FD       ; was: byte_FFC7FD
EntityType1C0TurnControl        equ     FifthEntityWork5C
FifthEntityWork5E               equ     $FFFFC7FE       ; was: word_FFC7FE
SixthEntityType                 equ     $FFFFC800       ; was: word_FFC800
SixthEntityFlags                equ     $FFFFC802       ; was: word_FFC802
SixthEntityState                equ     $FFFFC804       ; was: word_FFC804
SixthEntityWork40               equ     $FFFFC840       ; was: word_FFC840
SixthEntityWork52               equ     $FFFFC852       ; was: word_FFC852
SixthEntityWork56               equ     $FFFFC856       ; was: byte_FFC856
SeventhEntityType               equ     $FFFFC860       ; was: word_FFC860
SeventhEntityFlags              equ     $FFFFC862       ; was: word_FFC862
SeventhEntityState              equ     $FFFFC864       ; was: word_FFC864
SeventhEntityXPos               equ     $FFFFC870       ; was: dword_FFC870
SeventhEntityYPos               equ     $FFFFC874       ; was: dword_FFC874
SeventhEntityXVel               equ     $FFFFC878       ; was: dword_FFC878
SeventhEntityYVel               equ     $FFFFC87C       ; was: dword_FFC87C
SeventhEntityWork40             equ     $FFFFC8A0       ; was: word_FFC8A0
SeventhEntityWork46             equ     $FFFFC8A6       ; was: word_FFC8A6
SeventhEntityWork4A             equ     $FFFFC8AA       ; was: word_FFC8AA
SeventhEntityWork4C             equ     $FFFFC8AC       ; was: word_FFC8AC
SeventhEntityWork4E             equ     $FFFFC8AE       ; was: word_FFC8AE
SeventhEntityWork52             equ     $FFFFC8B2       ; was: word_FFC8B2
EighthEntityType                equ     $FFFFC8C0       ; was: word_FFC8C0
EighthEntityFlags               equ     $FFFFC8C2       ; was: word_FFC8C2
EighthEntityState               equ     $FFFFC8C4       ; was: word_FFC8C4
NinthEntityType                 equ     $FFFFC920       ; was: word_FFC920
NinthEntityFlags                equ     $FFFFC922       ; was: word_FFC922
TenthEntityType                 equ     $FFFFC980       ; was: word_FFC980
TenthEntityFlags                equ     $FFFFC982       ; was: word_FFC982
ValkirieAuxFlags                equ     $FFFFC9DE       ; was: byte_FFC9DE
EleventhEntityType              equ     $FFFFC9E0       ; was: word_FFC9E0
EleventhEntityFlags             equ     $FFFFC9E2       ; was: word_FFC9E2
EleventhEntityXPos              equ     $FFFFC9F0       ; was: word_FFC9F0
EleventhEntityYPos              equ     $FFFFC9F4       ; was: word_FFC9F4
EleventhEntityXVel              equ     $FFFFC9F8       ; was: dword_FFC9F8
EleventhEntityYVel              equ     $FFFFC9FC       ; was: dword_FFC9FC
TwelfthEntityType               equ     $FFFFCA40       ; was: word_FFCA40
TwelfthEntityFlags              equ     $FFFFCA42       ; was: word_FFCA42
TwelfthEntityXPos               equ     $FFFFCA50       ; was: word_FFCA50
TwelfthEntityYPos               equ     $FFFFCA54       ; was: word_FFCA54
TwelfthEntityXVel               equ     $FFFFCA58       ; was: dword_FFCA58
TwelfthEntityYVel               equ     $FFFFCA5C       ; was: dword_FFCA5C
ThirteenthEntityType            equ     $FFFFCAA0       ; was: byte_FFCAA0
FourteenthEntityType            equ     $FFFFCB00       ; was: byte_FFCB00
FourteenthEntityXPos            equ     $FFFFCB10       ; was: word_FFCB10
FourteenthEntityYPos            equ     $FFFFCB14       ; was: word_FFCB14
FifteenthEntityType             equ     $FFFFCB60       ; was: byte_FFCB60
SixteenthEntityType             equ     $FFFFCBC0       ; was: byte_FFCBC0
SixteenthEntityWork56           equ     $FFFFCC16       ; was: byte_FFCC16
SeventeenthEntityType           equ     $FFFFCC20       ; was: byte_FFCC20
EighteenthEntityType            equ     $FFFFCC80       ; was: byte_FFCC80
NineteenthEntityType            equ     $FFFFCCE0       ; was: byte_FFCCE0
TwentiethEntityType             equ     $FFFFCD40       ; was: word_FFCD40
TwentyFirstEntityType           equ     $FFFFCDA0       ; was: word_FFCDA0
TwentyFirstEntityWork4C         equ     $FFFFCDEC       ; was: word_FFCDEC
TwentySecondEntityType          equ     $FFFFCE00       ; was: byte_FFCE00
TwentyThirdEntityType           equ     $FFFFCE60       ; was: byte_FFCE60
TwentyThirdEntityAttr           equ     $FFFFCE6E       ; was: word_FFCE6E
TwentyThirdEntityStatus         equ     $FFFFCE81       ; was: byte_FFCE81
TwentyThirdEntityWork26         equ     $FFFFCE86       ; was: word_FFCE86
TwentyThirdEntityWork2C         equ     $FFFFCE8C       ; was: dword_FFCE8C
TwentyFourthEntityType          equ     $FFFFCEC0       ; was: word_FFCEC0
TwentyFourthEntityFlags         equ     $FFFFCEC2       ; was: word_FFCEC2
TwentyFifthEntityType           equ     $FFFFCF20       ; was: byte_FFCF20
TwentySixthEntityType           equ     $FFFFCF80       ; was: word_FFCF80
TwentySixthEntityWork56         equ     $FFFFCFD6       ; was: byte_FFCFD6
TwentySeventhEntityType         equ     $FFFFCFE0       ; was: byte_FFCFE0
TwentyEighthEntityType          equ     $FFFFD040       ; was: byte_FFD040
TwentyEighthEntityAttr          equ     $FFFFD04E       ; was: word_FFD04E
JampanShieldWork20              equ     $FFFFD060       ; was: byte_FFD060
TwentyNinthEntityType           equ     $FFFFD0A0       ; was: byte_FFD0A0
TwentyNinthEntityFlags          equ     $FFFFD0A2       ; was: byte_FFD0A2
TwentyNinthEntityXPos           equ     $FFFFD0B0       ; was: word_FFD0B0
TwentyNinthEntityYPos           equ     $FFFFD0B4       ; was: word_FFD0B4
TwentyNinthEntityYVel           equ     $FFFFD0BC       ; was: dword_FFD0BC
ThirtiethEntityType             equ     $FFFFD100       ; was: byte_FFD100
ThirtiethEntityXPos             equ     $FFFFD110       ; was: word_FFD110
ThirtiethEntityYPos             equ     $FFFFD114       ; was: word_FFD114
ThirtyFirstEntityType           equ     $FFFFD160       ; was: byte_FFD160
ThirtySecondEntityType          equ     $FFFFD1C0       ; was: word_FFD1C0
VictorRingEndMapping            equ     $FFFFD1C8       ; was: dword_FFD1C8
ThirtySecondEntityXPos          equ     $FFFFD1D0       ; was: word_FFD1D0
ThirtySecondEntityYPos          equ     $FFFFD1D4       ; was: word_FFD1D4
ThirtyThirdEntityType           equ     $FFFFD220       ; was: byte_FFD220
ThirtyFourthEntityType          equ     $FFFFD280       ; was: byte_FFD280
ThirtyEighthEntityType          equ     $FFFFD400       ; was: byte_FFD400
FortySixthEntityType            equ     $FFFFD700       ; was: byte_FFD700
EndingPlanetDebrisType          equ     $FFFFD820       ; was: word_FFD820
EndingPlanetDebrisFlags         equ     $FFFFD822       ; was: word_FFD822
EndingPlanetDebrisXVel          equ     $FFFFD838       ; was: dword_FFD838
FiftiethEntityType              equ     $FFFFD880       ; was: byte_FFD880
AmbientParticlePool             equ     $FFFFD8E0       ; was: byte_FFD8E0
FiftyThirdEntityType            equ     $FFFFD9A0       ; was: byte_FFD9A0
Entity57Type                    equ     $FFFFDB20       ; was: word_FFDB20
Entity57Flags                   equ     $FFFFDB22       ; was: word_FFDB22
Entity57State                   equ     $FFFFDB24       ; was: word_FFDB24
Entity57XPos                    equ     $FFFFDB30       ; was: dword_FFDB30
Entity57YPos                    equ     $FFFFDB34       ; was: dword_FFDB34
Entity57XVel                    equ     $FFFFDB38       ; was: dword_FFDB38
Entity57YVel                    equ     $FFFFDB3C       ; was: dword_FFDB3C
Entity57Status                  equ     $FFFFDB41       ; was: byte_FFDB41
Entity57CollisionFlags          equ     $FFFFDB42       ; was: byte_FFDB42
Entity57Work24                  equ     $FFFFDB44       ; was: word_FFDB44
Entity57Work56                  equ     $FFFFDB76       ; was: byte_FFDB76
Entity57Work58                  equ     $FFFFDB78       ; was: word_FFDB78
Entity57Work5A                  equ     $FFFFDB7A       ; was: byte_FFDB7A
Entity58Type                    equ     $FFFFDB80       ; was: byte_FFDB80
Entity58YPos                    equ     $FFFFDB94       ; was: word_FFDB94
Entity59Type                    equ     $FFFFDBE0       ; was: word_FFDBE0
Entity59State                   equ     $FFFFDBE4       ; was: word_FFDBE4
Entity59XPos                    equ     $FFFFDBF0       ; was: word_FFDBF0
Entity59YPos                    equ     $FFFFDBF4       ; was: word_FFDBF4
Entity59XVel                    equ     $FFFFDBF8       ; was: dword_FFDBF8
Entity59YVel                    equ     $FFFFDBFC       ; was: dword_FFDBFC
Entity60Type                    equ     $FFFFDC40       ; was: word_FFDC40
Entity60XPos                    equ     $FFFFDC50       ; was: word_FFDC50
Entity60XVel                    equ     $FFFFDC58       ; was: dword_FFDC58
Entity60YVel                    equ     $FFFFDC5C       ; was: dword_FFDC5C
SpriteOAMBuffer                 equ     $FFFFE000       ; was: dword_FFE000
PaletteActiveBuffer             equ     $FFFFE300       ; was: word_FFE300
PaletteActiveColor01            equ     $FFFFE302       ; was: word_FFE302
PaletteActiveColor02            equ     $FFFFE304       ; was: word_FFE304
PaletteActiveColor03            equ     $FFFFE306       ; was: word_FFE306
PaletteActiveColor06            equ     $FFFFE30C       ; was: word_FFE30C
PaletteActiveColor08            equ     $FFFFE310       ; was: word_FFE310
PaletteActiveColor10            equ     $FFFFE314       ; was: word_FFE314
PaletteActiveColor11            equ     $FFFFE316       ; was: word_FFE316
PaletteActiveColor12            equ     $FFFFE318       ; was: word_FFE318
PaletteActiveColor14            equ     $FFFFE31C       ; was: word_FFE31C
PaletteActiveColor15            equ     $FFFFE31E       ; was: word_FFE31E
PaletteActiveColor16            equ     $FFFFE320       ; was: word_FFE320
PaletteActiveColor17Hi          equ     $FFFFE322       ; was: byte_FFE322
PaletteActiveColor18            equ     $FFFFE324       ; was: word_FFE324
PaletteActiveColor19            equ     $FFFFE326       ; was: word_FFE326
PaletteActiveColor20            equ     $FFFFE328       ; was: word_FFE328
PaletteActiveColor21            equ     $FFFFE32A       ; was: word_FFE32A
PaletteActiveColor22            equ     $FFFFE32C       ; was: word_FFE32C
PaletteActiveColor29            equ     $FFFFE33A       ; was: word_FFE33A
PaletteActiveColor30            equ     $FFFFE33C       ; was: word_FFE33C
PaletteActiveColor31            equ     $FFFFE33E       ; was: word_FFE33E
PaletteActiveColor32            equ     $FFFFE340       ; was: word_FFE340
PaletteActiveColor33            equ     $FFFFE342       ; was: word_FFE342
PaletteActiveColor34            equ     $FFFFE344       ; was: word_FFE344
PaletteActiveColor41Hi          equ     $FFFFE352       ; was: byte_FFE352
PaletteActiveColor46            equ     $FFFFE35C       ; was: word_FFE35C
PaletteActiveColor48            equ     $FFFFE360       ; was: word_FFE360
PaletteActiveColor49            equ     $FFFFE362       ; was: word_FFE362
PaletteActiveColor50            equ     $FFFFE364       ; was: word_FFE364
PaletteActiveColor51            equ     $FFFFE366       ; was: word_FFE366
PaletteActiveColor52            equ     $FFFFE368       ; was: word_FFE368
PaletteActiveColor54            equ     $FFFFE36C       ; was: word_FFE36C
PaletteActiveColor56Hi          equ     $FFFFE370       ; was: byte_FFE370
PaletteActiveColor58Hi          equ     $FFFFE374       ; was: byte_FFE374
PaletteActiveColor59            equ     $FFFFE376       ; was: word_FFE376
PaletteActiveColor60            equ     $FFFFE378       ; was: word_FFE378
PaletteActiveColor61            equ     $FFFFE37A       ; was: word_FFE37A
PaletteActiveColor62            equ     $FFFFE37C       ; was: word_FFE37C
PaletteActiveColor63            equ     $FFFFE37E       ; was: word_FFE37E
PaletteShadowBuffer             equ     $FFFFE380       ; was: word_FFE380
PaletteShadowColor01            equ     $FFFFE382       ; was: word_FFE382
PaletteShadowColor03            equ     $FFFFE386       ; was: word_FFE386
PaletteShadowPair16             equ     $FFFFE3A0       ; was: dword_FFE3A0
PaletteShadowColor20            equ     $FFFFE3A8       ; was: word_FFE3A8
PaletteShadowColor21            equ     $FFFFE3AA       ; was: word_FFE3AA
PaletteShadowColor22            equ     $FFFFE3AC       ; was: word_FFE3AC
PaletteShadowColor29            equ     $FFFFE3BA       ; was: word_FFE3BA
PaletteShadowColor30            equ     $FFFFE3BC       ; was: word_FFE3BC
PaletteShadowColor32Hi          equ     $FFFFE3C0       ; was: byte_FFE3C0
PaletteShadowPair33             equ     $FFFFE3C2       ; was: dword_FFE3C2
PaletteShadowPair41             equ     $FFFFE3D2       ; was: dword_FFE3D2
PaletteShadowPair47             equ     $FFFFE3DE       ; was: dword_FFE3DE
PaletteShadowColor49            equ     $FFFFE3E2       ; was: word_FFE3E2
PaletteShadowColor50            equ     $FFFFE3E4       ; was: word_FFE3E4
PaletteShadowColor54            equ     $FFFFE3EC       ; was: word_FFE3EC
PaletteShadowColor61            equ     $FFFFE3FA       ; was: word_FFE3FA
PaletteShadowColor62            equ     $FFFFE3FC       ; was: word_FFE3FC
PaletteShadowColor63            equ     $FFFFE3FE       ; was: word_FFE3FE
HScrollBuffer                   equ     $FFFFE400       ; was: word_FFE400
HScrollPlaneBRow0               equ     $FFFFE402       ; was: word_FFE402
HScrollPlaneBRow2               equ     $FFFFE40A       ; was: byte_FFE40A
HScrollPlaneBRow4               equ     $FFFFE412       ; was: byte_FFE412
HScrollPlaneARow32              equ     $FFFFE480       ; was: word_FFE480
HScrollPlaneBRow32              equ     $FFFFE482       ; was: byte_FFE482
HScrollPlaneARow72              equ     $FFFFE520       ; was: word_FFE520
HScrollPlaneARow75              equ     $FFFFE52C       ; was: word_FFE52C
HScrollPlaneARow96              equ     $FFFFE580       ; was: byte_FFE580
HScrollPlaneARow104             equ     $FFFFE5A0       ; was: word_FFE5A0
HScrollPlaneBRow104             equ     $FFFFE5A2       ; was: word_FFE5A2
HScrollPlaneARow112             equ     $FFFFE5C0       ; was: word_FFE5C0
HScrollPlaneBRow112             equ     $FFFFE5C2       ; was: word_FFE5C2
HScrollPlaneBRow128             equ     $FFFFE602       ; was: byte_FFE602
HScrollPlaneARow184             equ     $FFFFE6E0       ; was: word_FFE6E0
HScrollPlaneARow200             equ     $FFFFE720       ; was: word_FFE720
HScrollAuxBuffer                equ     $FFFFE800       ; was: byte_FFE800
VScrollBuffer                   equ     $FFFFEC00       ; was: word_FFEC00
VScrollPlaneBColumn0            equ     $FFFFEC02       ; was: word_FFEC02
VScrollPlaneAColumn1            equ     $FFFFEC04       ; was: word_FFEC04
VScrollPlaneAColumn2            equ     $FFFFEC08       ; was: word_FFEC08
VScrollPlaneAColumn3            equ     $FFFFEC0C       ; was: word_FFEC0C
VScrollPlaneAColumn4            equ     $FFFFEC10       ; was: word_FFEC10
VScrollPlaneBColumn4            equ     $FFFFEC12       ; was: byte_FFEC12
VScrollPlaneAColumn5            equ     $FFFFEC14       ; was: word_FFEC14
VScrollPlaneAColumn6            equ     $FFFFEC18       ; was: word_FFEC18
VScrollPlaneAColumn7            equ     $FFFFEC1C       ; was: word_FFEC1C
VScrollPlaneAColumn8            equ     $FFFFEC20       ; was: word_FFEC20
VScrollPlaneBColumn8            equ     $FFFFEC22       ; was: word_FFEC22
VScrollPlaneAColumn9            equ     $FFFFEC24       ; was: word_FFEC24
VScrollPlaneBColumn9            equ     $FFFFEC26       ; was: word_FFEC26
VScrollPlaneAColumn10           equ     $FFFFEC28       ; was: word_FFEC28
VScrollPlaneBColumn10           equ     $FFFFEC2A       ; was: word_FFEC2A
VScrollPlaneAColumn11           equ     $FFFFEC2C       ; was: word_FFEC2C
VScrollPlaneAColumn12           equ     $FFFFEC30       ; was: word_FFEC30
VScrollPlaneAColumn13           equ     $FFFFEC34       ; was: word_FFEC34
VScrollPlaneAColumn14           equ     $FFFFEC38       ; was: word_FFEC38
VScrollPlaneAColumn15           equ     $FFFFEC3C       ; was: word_FFEC3C
VScrollPlaneAColumn16           equ     $FFFFEC40       ; was: word_FFEC40
VScrollPlaneAColumn17           equ     $FFFFEC44       ; was: word_FFEC44
VScrollPlaneAColumn18           equ     $FFFFEC48       ; was: word_FFEC48
VScrollPlaneAColumn19           equ     $FFFFEC4C       ; was: word_FFEC4C
VScrollAuxBuffer                equ     $FFFFEC50       ; was: byte_FFEC50
VisibleObjectList               equ     $FFFFED00       ; was: word_FFED00
HBlankRAMCode                   equ     $FFFFEE00       ; was: word_FFEE00
SpriteVDPStagingBuffer          equ     $FFFFF000       ; was: dword_FFF000
VDPQueueStagingBoundary         equ     $FFFFF400       ; was: word_FFF400
VDPCommand                      equ     $FFFFF700
VBlankUpdateReady               equ     $FFFFF704       ; was: byte_FFF704
GameplayControlFlags            equ     $FFFFF705       ; was: byte_FFF705
ControllerHeldState             equ     $FFFFF706       ; was: word_FFF706
ControllerPressedState          equ     $FFFFF708       ; was: word_FFF708
ControllerReleasedState         equ     $FFFFF70A       ; was: word_FFF70A
VDPCommandQueueHead             equ     $FFFFF70C       ; was: word_FFF70C
VDPStagingDataCursor            equ     $FFFFF70E       ; was: word_FFF70E
HScrollDMASource                equ     $FFFFF710       ; was: dword_FFF710
VScrollDMASource                equ     $FFFFF714       ; was: dword_FFF714
DataLoaderControl               equ     $FFFFF720       ; was: word_FFF720
DataLoaderLength                equ     $FFFFF722       ; was: word_FFF722
DataLoaderRecordPtr             equ     $FFFFF724       ; was: dword_FFF724
DataLoaderSourcePtr             equ     $FFFFF728       ; was: dword_FFF728
DataLoaderDestination           equ     $FFFFF72C       ; was: dword_FFF72C
DataLoaderCodecState            equ     $FFFFF730       ; was: dword_FFF730
SpriteOAMBuildActive            equ     $FFFFF744       ; was: byte_FFF744
SoundUpdateBusy                 equ     $FFFFF745       ; was: byte_FFF745
FrameTimingDebugFlag            equ     $FFFFF746       ; was: byte_FFF746
RasterEffectIndex               equ     $FFFFF74A       ; was: word_FFF74A
RasterEffectInitState           equ     $FFFFF74E       ; was: word_FFF74E
VDPTransferPending              equ     $FFFFF754       ; was: byte_FFF754
PaletteDMAHIntEnabled           equ     $FFFFF755       ; was: byte_FFF755
SpriteOAMStartCount             equ     $FFFFF756       ; was: word_FFF756
VisibleObjectListCursor         equ     $FFFFF758       ; was: word_FFF758
VisibleObjectCount              equ     $FFFFF75A       ; was: word_FFF75A
PaletteFadeStep                 equ     $FFFFF75C       ; was: word_FFF75C
PaletteFadeProgress             equ     $FFFFF75E       ; was: word_FFF75E
VBlankSoundRequestDelay         equ     $FFFFF762       ; was: word_FFF762
VBlankPendingSound              equ     $FFFFF764       ; was: byte_FFF764
VDPReg0Shadow                   equ     $FFFFF7D0       ; was: word_FFF7D0
VDPReg1Shadow                   equ     $FFFFF7D2       ; was: word_FFF7D2
VDPReg2Shadow                   equ     $FFFFF7D4       ; was: word_FFF7D4
VDPReg3Shadow                   equ     $FFFFF7D6       ; was: word_FFF7D6
VDPReg4Shadow                   equ     $FFFFF7D8       ; was: word_FFF7D8
VDPReg5Shadow                   equ     $FFFFF7DA       ; was: word_FFF7DA
VDPReg7Shadow                   equ     $FFFFF7DE       ; was: word_FFF7DE
VDPReg10Shadow                  equ     $FFFFF7E4       ; was: word_FFF7E4
VDPReg11Shadow                  equ     $FFFFF7E6       ; was: word_FFF7E6
VDPReg12Shadow                  equ     $FFFFF7E8       ; was: word_FFF7E8
VDPReg13Shadow                  equ     $FFFFF7EA       ; was: word_FFF7EA
VDPReg15Shadow                  equ     $FFFFF7EE       ; was: word_FFF7EE
VDPReg16Shadow                  equ     $FFFFF7F0       ; was: word_FFF7F0
VDPReg17Shadow                  equ     $FFFFF7F2       ; was: word_FFF7F2
VDPReg18Shadow                  equ     $FFFFF7F4       ; was: word_FFF7F4
SoundCurrentPriority            equ     $FFFFF800       ; was: byte_FFF800
SoundTempoCounter               equ     $FFFFF801       ; was: byte_FFF801
SoundTempoReload                equ     $FFFFF802       ; was: byte_FFF802
SoundCommunicationByte          equ     $FFFFF803       ; was: byte_FFF803
SoundFadeStepsRemaining         equ     $FFFFF804       ; was: byte_FFF804
SoundFadeTickCounter            equ     $FFFFF806       ; was: byte_FFF806
SoundPauseState                 equ     $FFFFF807       ; was: byte_FFF807
SoundPCMEventFlag               equ     $FFFFF808       ; was: byte_FFF808
SoundSelectedRequest            equ     $FFFFF809       ; was: byte_FFF809
SoundRequestQueue               equ     $FFFFF80A       ; was: dword_FFF80A
SoundChannelGroupFlags          equ     $FFFFF80E       ; was: byte_FFF80E
SoundFM3SpecialMode             equ     $FFFFF80F       ; was: byte_FFF80F
SoundBGMFM3Offsets              equ     $FFFFF810       ; was: word_FFF810
SoundSFXFM3Offsets              equ     $FFFFF818       ; was: word_FFF818
SoundBGMDataPtr                 equ     $FFFFF820       ; was: dword_FFF820
SoundSpecialSFXDataPtr          equ     $FFFFF824       ; was: dword_FFF824
SoundManualVolumeState          equ     $FFFFF828       ; was: byte_FFF828
SoundFMVolumeStep               equ     $FFFFF829       ; was: byte_FFF829
SoundPSGVolumeStep              equ     $FFFFF82A       ; was: byte_FFF82A
SoundVoiceDuckingState          equ     $FFFFF82B       ; was: byte_FFF82B
SoundVoiceSlotToggle            equ     $FFFFF82C       ; was: byte_FFF82C
SoundPCMChannelRecord           equ     $FFFFF840       ; was: byte_FFF840
SoundBGMFMChannels              equ     $FFFFF870       ; was: word_FFF870
SoundBGMFMChannel3              equ     $FFFFF900       ; was: byte_FFF900
SoundBGMPSGChannels             equ     $FFFFF990       ; was: byte_FFF990
SoundBGMPSGChannel2             equ     $FFFFF9F0       ; was: byte_FFF9F0
SoundSFXFMChannels              equ     $FFFFFA20       ; was: byte_FFFA20
SoundSFXFMChannel1              equ     $FFFFFA50       ; was: byte_FFFA50
SoundSFXPSGChannel2             equ     $FFFFFB10       ; was: byte_FFFB10
SoundSpecialSFXFM               equ     $FFFFFB40       ; was: word_FFFB40
SoundSpecialSFXPSG              equ     $FFFFFB70       ; was: word_FFFB70
SoundFMShadowIndexBase          equ     $FFFFFBA0       ; was: byte_FFFBA0
SoundFMPort1IndexBase           equ     $FFFFFBB0       ; was: byte_FFFBB0
SoundFMLevelShadows             equ     $FFFFFBE0       ; was: dword_FFFBE0
SoundFMShadowsEnd               equ     $FFFFFC00       ; was: dword_FFFC00
SystemStateBlock                equ     $FFFFFF00       ; was: dword_FFFF00
Controller1TypeID               equ     $FFFFFF06       ; was: byte_FFFF06
Controller2TypeID               equ     $FFFFFF07       ; was: byte_FFFF07
RandomNumberState               equ     $FFFFFF08       ; was: dword_FFFF08
DifficultyMode                  equ     $FFFFFF0E       ; was: word_FFFF0E
DeveloperSignatureTREA          equ     $FFFFFF10       ; was: dword_FFFF10
DeveloperSignatureSURE          equ     $FFFFFF14       ; was: dword_FFFF14
P1ButtonASourceBit              equ     $FFFFFF20       ; was: byte_FFFF20
P2ButtonASourceBit              equ     $FFFFFF21       ; was: byte_FFFF21
P1ButtonBSourceBit              equ     $FFFFFF22       ; was: byte_FFFF22
P2ButtonBSourceBit              equ     $FFFFFF23       ; was: byte_FFFF23
P1ButtonCSourceBit              equ     $FFFFFF24       ; was: byte_FFFF24
P2ButtonCSourceBit              equ     $FFFFFF25       ; was: byte_FFFF25
ConsoleVersionFlags             equ     $FFFFFF26       ; was: byte_FFFF26
PaletteFillColor                equ     $FFFFFF28       ; was: word_FFFF28
MessageMode                     equ     $FFFFFF2A       ; was: word_FFFF2A
HighScoreBCD                    equ     $FFFFFF2C       ; was: dword_FFFF2C
ControlLayoutFlags              equ     $FFFFFF30       ; was: byte_FFFF30
MessageDisplayFlags             equ     $FFFFFF31       ; was: byte_FFFF31
BootInitializedWord             equ     $FFFFFF36       ; was: word_FFFF36
SoundDisableFlags               equ     $FFFFFF38       ; was: word_FFFF38
PasswordDigits                  equ     $FFFFFF3A       ; was: dword_FFFF3A
FrameSkipLevel                  equ     $FFFFFF3E       ; was: word_FFFF3E
PostStageEntryCountBCD          equ     $FFFFFF40       ; was: word_FFFF40
DestroyedEnemyCountBCD          equ     $FFFFFF42       ; was: word_FFFF42
PlayerDamageBCD                 equ     $FFFFFF44       ; was: word_FFFF44
ResultsExtendedLayout           equ     $FFFFFF46       ; was: word_FFFF46
DemoCurrentInputWord            equ     $FFFFFF48       ; was: word_FFFF48
DemoInputRunFrames              equ     $FFFFFF4A       ; was: word_FFFF4A
DemoInputStreamPtr              equ     $FFFFFF4C       ; was: dword_FFFF4C
DemoRecordingOffset             equ     $FFFFFF50       ; was: word_FFFF50
DemoPlaybackInputWord           equ     $FFFFFF52       ; was: word_FFFF52
DemoRecordingMode               equ     $FFFFFF56       ; was: word_FFFF56
DemoFramesRemaining             equ     $FFFFFF58       ; was: word_FFFF58
DemoPlaybackActive              equ     $FFFFFF5A       ; was: word_FFFF5A
DemoPlaybackState               equ     $FFFFFF5C       ; was: word_FFFF5C
SavedDifficultyMode             equ     $FFFFFF5E       ; was: word_FFFF5E
SavedSoundDisableFlags          equ     $FFFFFF60       ; was: word_FFFF60
DemoRotationIndex               equ     $FFFFFF62       ; was: word_FFFF62
DemoStageTableIndex             equ     $FFFFFF64       ; was: word_FFFF64
SavedControlLayoutFlags         equ     $FFFFFF66       ; was: byte_FFFF66
PALSoundCompensationCounter     equ     $FFFFFF68
M68K_RAM_LAST_BYTE              equ     $FFFFFFFF       ; was: byte_FFFFFF
Z80_RAM                         equ     $A00000
PauseMenuZ80SpriteData          equ     $A00C00         ; was: byte_A00C00
Z80DriverBusy                   equ     $A01F2A         ; was: byte_A01F2A
Z80VoiceSlotADesc0              equ     $A01F80         ; was: byte_A01F80
Z80VoiceSlotADesc1              equ     $A01F81         ; was: byte_A01F81
Z80VoiceSlotAHeader0            equ     $A01F82         ; was: byte_A01F82
Z80VoiceSlotAHeader1            equ     $A01F83         ; was: byte_A01F83
Z80VoiceSlotAHeader2            equ     $A01F84         ; was: byte_A01F84
Z80VoiceSlotAHeader3            equ     $A01F85         ; was: byte_A01F85
Z80VoiceSlotAActive             equ     $A01F86         ; was: byte_A01F86
Z80VoiceSlotAFlags              equ     $A01F87         ; was: byte_A01F87
Z80VoiceSlotBDesc0              equ     $A01FA0         ; was: byte_A01FA0
Z80VoiceSlotBDesc1              equ     $A01FA1         ; was: byte_A01FA1
Z80VoiceSlotBHeader0            equ     $A01FA2         ; was: byte_A01FA2
Z80VoiceSlotBHeader1            equ     $A01FA3         ; was: byte_A01FA3
Z80VoiceSlotBHeader2            equ     $A01FA4         ; was: byte_A01FA4
Z80VoiceSlotBHeader3            equ     $A01FA5         ; was: byte_A01FA5
Z80VoiceSlotBActive             equ     $A01FA6         ; was: byte_A01FA6
Z80VoiceSlotBFlags              equ     $A01FA7         ; was: byte_A01FA7
Z80DACCommandByte2              equ     $A01FE6         ; was: byte_A01FE6
Z80DACCommandByte3              equ     $A01FE7         ; was: byte_A01FE7
Z80DACCommandByte0              equ     $A01FE8         ; was: byte_A01FE8
Z80DACCommandByte1              equ     $A01FE9         ; was: byte_A01FE9
Z80DACPanningUpdate             equ     $A01FF8         ; was: byte_A01FF8
Z80DACPanning                   equ     $A01FF9         ; was: byte_A01FF9
Z80DACCommandByte6              equ     $A01FFA         ; was: byte_A01FFA
Z80DACCommandByte5              equ     $A01FFB         ; was: byte_A01FFB
Z80DACStatus                    equ     $A01FFC         ; was: byte_A01FFC
Z80DACRequestState              equ     $A01FFD         ; was: byte_A01FFD
Z80DACCommandByte4              equ     $A01FFE         ; was: byte_A01FFE
Z80VBlankActive                 equ     $A01FFF         ; was: byte_A01FFF
Z80_YM2612                      equ     $A04000
; ----------------------------------
