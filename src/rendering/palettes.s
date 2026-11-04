; Loads multiple palettes from a pointer table sequentially
Gfx_LoadMultiplePalettes:                               ; was: sub_B900
                                        ; EndingSequence_Initialize+64   p
                moveq   #0,d0
                movea.w #(PaletteActiveBuffer-M68K_RAM),a0
                move.w  d0,(a0)
                move.w  d0,$80(a0)
                move.w  d0,$20(a0)
                move.w  d0,$A0(a0)
                move.w  d0,$40(a0)
                move.w  d0,$C0(a0)
                move.w  d0,$60(a0)
                move.w  d0,$E0(a0)
                lea     CommonPaletteCommand(pc),a0
                nop
                bsr.w   Gfx_LoadPaletteCommand
Gfx_LoadMultiplePalettes_NextOffset:                    ; was: loc_B92E
                move.w  (a4)+,d0
                bne.s   Gfx_LoadPaletteFromRelativeOffset
                rts
; ---------------------------------------------------------------------------
; Resolves one signed command offset relative to the preserving loader entry
Gfx_LoadPaletteFromRelativeOffset:                      ; was: loc_B934
                ext.l   d0
                addi.l  #Gfx_LoadPalettePreservingSharedColor,d0
                movea.l d0,a0
                bsr.w   Gfx_LoadPaletteCommand
                bra.s   Gfx_LoadMultiplePalettes_NextOffset
; End of function Gfx_LoadMultiplePalettes
; ---------------------------------------------------------------------------
StoryScreenPaletteOffsetList:   dc.w    (CreditsAndEarlyStagePaletteCommandBank+$82)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B944
                dc.w    0
OptionsScreenPaletteOffsetList: dc.w    FrontendPaletteCommands-Gfx_LoadPalettePreservingSharedColor  ; was: word_B948
                dc.w    (FrontendPaletteCommands+$82)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
StageStartPaletteOffsetList:    dc.w    (CreditsAndEarlyStagePaletteCommandBank+$102)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B94E
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$128)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
WeaponSetupControlTestPaletteOffsetList:    dc.w    (CreditsAndEarlyStagePaletteCommandBank+$148)-Gfx_LoadPalettePreservingSharedColor
; was: word_B954
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$14E)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
ContinueScreenPaletteOffsetLists:   dc.w    (StageReadyPaletteCommand+$6)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B95A
                dc.w    (StageReadyPaletteCommand+$C)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$12)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$18)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                dc.w    (StageReadyPaletteCommand+$6)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$C)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$12)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$18)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
ResultsScreenPaletteOffsetList: dc.w    (StageReadyPaletteCommand+$6)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B96E
                dc.w    (StageReadyPaletteCommand+$C)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$12)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (StageReadyPaletteCommand+$18)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
FrontendTransitionPaletteOffsetLists:   dc.w    (CreditsAndEarlyStagePaletteCommandBank+$E2)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B978
                dc.w    0
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$16E)-Gfx_LoadPalettePreservingSharedColor
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$1AE)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
CreditsAndPlanetPaletteOffsetList:  dc.w    (Boss_Epsilon1PaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B982
                dc.w    (Boss_Epsilon1PaletteCommands+$60)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; EndingPlanet_Initialize+20   o
EarlyStagePaletteOffsetList:    dc.w    (CreditsAndEarlyStagePaletteCommandBank+$1C4)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B988
                dc.w    0
                                        ; ROM:Stage2ConfigRecord   o
ShellshogunStagePaletteOffsetList:  dc.w    (CreditsAndEarlyStagePaletteCommandBank+$1C4)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B98C
                dc.w    (CreditsAndEarlyStagePaletteCommandBank+$206)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; ROM:Stage4ConfigRecord   o
Stage5To7PaletteOffsetList: dc.w    (CreditsAndEarlyStagePaletteCommandBank+$228)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B992
                dc.w    0
                                        ; ROM:Stage6ConfigRecord   o
                                        ; ROM:Stage7ConfigRecord   o
Stage8InitialPaletteOffsetList: dc.w    (CreditsAndEarlyStagePaletteCommandBank+$26A)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B996
                dc.w    0
XiTigerAndStage9PaletteOffsetList:  dc.w    (CreditsAndEarlyStagePaletteCommandBank+$26A)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B99A
                dc.w    (Boss_FlyingNeoPaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; ROM:Stage9ConfigRecord   o
XiTigerCutscenePaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$E)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9A0
                dc.w    0
Stage10To13PaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$4E)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9A4
                dc.w    0
                                        ; ROM:Stage11ConfigRecord   o
                                        ; ROM:Stage12ConfigRecord   o
                                        ; ROM:Stage13ConfigRecord   o
Stage14To16PaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$8E)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9A8
                dc.w    0
                                        ; ROM:Stage15ConfigRecord   o
                                        ; ROM:Stage16ConfigRecord   o
Stage17PaletteOffsetList:   dc.w    (FlyingNeoAndMidgamePaletteCommandBank+$CE)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9AC
                dc.w    0
Stage18And19PaletteOffsetList:  dc.w    (Stage17PaletteCommandBank+$20)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9B0
                dc.w    0
                                        ; ROM:Stage19ConfigRecord   o
UnreferencedStage20VariantPaletteOffsetList:    dc.w    (Stage17PaletteCommandBank+$60)-Gfx_LoadPalettePreservingSharedColor
; was: word_B9B4
                dc.w    0
                                        ; ROM:UnreferencedStage20Variant2ConfigRecord   o
                                        ; ROM:UnreferencedStage20Variant3ConfigRecord   o
                                        ; ROM:UnreferencedStage20Variant4ConfigRecord   o
Stage20PaletteOffsetLists:  dc.w    (Stage17PaletteCommandBank+$A0)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9B8
                dc.w    0
                dc.w    SevenForceArtemisTransitionPaletteCommand-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
SevenForceCutscenePaletteOffsetList:    dc.w    (SireneAndLateStagePaletteCommandBank+$1E)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9C0
                dc.w    (SireneAndLateStagePaletteCommandBank+$3E)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
Stage21And23PaletteOffsetList:  dc.w    (SireneAndLateStagePaletteCommandBank+$46)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9C6
                dc.w    (Stage15PaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
                                        ; ROM:Stage23ConfigRecord   o
Stage22PaletteOffsetList:   dc.w    (SireneAndLateStagePaletteCommandBank+$46)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9CC
                dc.w    DestroyerProtoIntroPaletteCommands-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
Stage24PaletteOffsetList:   dc.w    (SireneAndLateStagePaletteCommandBank+$86)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9D2
                dc.w    (DestroyerProtoIntroPaletteCommands+$20)-Gfx_LoadPalettePreservingSharedColor
                dc.w    0
UnreferencedFlaggedPaletteOffsetListA:  dc.w    $718, $E34, 0  ; was: word_B9D8
UnreferencedFlaggedPaletteOffsetListB:  dc.w    $738, 0  ; was: word_B9DE
Stage25PaletteOffsetList:               dc.w    (SireneAndLateStagePaletteCommandBank+$E6)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9E2
                dc.w    0
Stage26PaletteOffsetList:   dc.w    (SireneAndLateStagePaletteCommandBank+$126)-Gfx_LoadPalettePreservingSharedColor  ; was: word_B9E6
                dc.w    0
                                        ; ZLeoEnding_InitializeScene+24   o

; Loads a palette command while preserving the shared color at palette slot $36
Gfx_LoadPalettePreservingSharedColor:                   ; was: sub_B9EA
                                        ; Stage_LoadStage17Palettes+12   j
                move.w  (PaletteShadowColor54).w,(PaletteColorPair).w
                bsr.s   Gfx_LoadPaletteCommand
                move.w  (PaletteColorPair).w,(PaletteActiveColor54).w
                move.w  (PaletteColorPair).w,(PaletteShadowColor54).w
                rts
; End of function Gfx_LoadPalettePreservingSharedColor
; Command header: destination byte, inclusive word count, then CRAM words
; The destination byte selects matching target and shadow buffers $80 bytes apart
Gfx_LoadPaletteCommand:                                 ; was: LoadPalette
                                        ; StoryTitle_SetupLogoReveal+7E   p
                moveq   #0,d0
                move.b  (a0)+,d0
                addi.w  #-$1D00,d0
                move.w  d0,d1
                addi.w  #$80,d1
                movea.w d0,a1
                movea.w d1,a2
                moveq   #0,d0
                moveq   #0,d7
                move.b  (a0)+,d7
                move.w  d7,d1
                asl.w   #1,d1
                addq.w  #2,d1
                adda.l  d0,a0
; Copies palette data to both active and shadow palette buffers
Gfx_LoadPaletteCommand_CopyColors:                      ; was: loc_BA20
                move.w  (a0),(a1)+
                move.w  (a0)+,(a2)+
                dbf     d7,Gfx_LoadPaletteCommand_CopyColors
                rts
; End of function Gfx_LoadPaletteCommand
; ---------------------------------------------------------------------------
CommonPaletteCommand:       binclude "data/palettes/00BA2A.bin"  ; was: byte_BA2A
FrontendPaletteCommands:    binclude "data/palettes/00BA4A.bin"  ; was: byte_BA4A
                                        ; StoryTitle_SetupLogoReveal+78   o
StageReadyPaletteCommand:       binclude "data/palettes/00BAD2.bin"  ; was: byte_BAD2
PostStageFullPaletteCommand:    binclude "data/palettes/00BAF0.bin"  ; was: byte_BAF0
                                        ; Results_InitializeSecondaryOptionsReturn+50   o
CreditsAndEarlyStagePaletteCommandBank:     binclude "data/mappings/byte_BB72.bin"  ; was: byte_BB72
CreditsAndEarlyStagePaletteCommandBank_End:
FlyingNeoAndMidgamePaletteCommandBank:      binclude "data/other/byte_BE1E.bin"  ; was: byte_BE1E
FlyingNeoAndMidgamePaletteCommandBank_End:
Stage17PaletteCommandBank:                  binclude "data/palettes/00BF2C.bin"  ; was: byte_BF2C
SevenForceSylpheedTransitionPaletteCommand: binclude "data/palettes/00C00C.bin"  ; was: byte_C00C
SevenForceArtemisTransitionPaletteCommand:  binclude "data/palettes/00C01C.bin"  ; was: byte_C01C
SireneAndLateStagePaletteCommandBank:       binclude "data/other/byte_C05C.bin"  ; was: byte_C05C
SireneAndLateStagePaletteCommandBank_End:
SharedStagePaletteCommand:                  binclude "data/palettes/00C1A2.bin"  ; was: byte_C1A2
                                        ; sub_11EAA   o
XiTigerCutscenePaletteCommand:          binclude "data/palettes/00C1C2.bin"  ; was: byte_C1C2
Stage15PaletteCommands:                 binclude "data/palettes/00C1E2.bin"  ; was: byte_C1E2
DestroyerProtoIntroPaletteCommands:     binclude "data/palettes/00C212.bin"  ; was: byte_C212
Boss_JetsripperPaletteCommand:          binclude "data/palettes/00C252.bin"  ; was: byte_C252
Boss_AntroidPaletteCommand:             binclude "data/palettes/00C272.bin"  ; was: byte_C272
Boss_ShellshogunPaletteCommand:         binclude "data/palettes/00C292.bin"  ; was: byte_C292
Boss_SniperHoneyviperPaletteCommand:    binclude "data/palettes/00C2B2.bin"  ; was: byte_C2B2
Boss_MadamBarbarPaletteCommand:         binclude "data/palettes/00C2D2.bin"  ; was: byte_C2D2
Boss_JokerPaletteCommand:               binclude "data/palettes/00C2F2.bin"  ; was: byte_C2F2
Boss_TerobusterPaletteCommand:          binclude "data/palettes/00C312.bin"  ; was: byte_C312
Boss_FlyingNeoPaletteCommands:          binclude "data/palettes/00C330.bin"  ; was: byte_C330
Boss_XiTigerPaletteCommand:             binclude "data/palettes/00C370.bin"  ; was: byte_C370
Boss_DeepStriderPaletteCommand:         binclude "data/palettes/00C390.bin"  ; was: byte_C390
Boss_GustheadPaletteCommand:            binclude "data/palettes/00C3B0.bin"  ; was: byte_C3B0
Boss_SharpsteelPaletteCommand:          binclude "data/palettes/00C3D0.bin"  ; was: byte_C3D0
Boss_SnakePaletteCommand:               binclude "data/palettes/00C3F0.bin"  ; was: byte_C3F0
Boss_LovePenguinPaletteCommand:         binclude "data/palettes/00C404.bin"  ; was: byte_C404
Boss_VictorPaletteCommand:              binclude "data/palettes/00C424.bin"  ; was: byte_C424
Boss_SunsetStingPaletteCommand:         binclude "data/palettes/00C444.bin"  ; was: byte_C444
Boss_ViblackIntroPaletteCommand:        binclude "data/palettes/00C464.bin"  ; was: byte_C464
Boss_ViblackPostBattlePaletteCommand:   binclude "data/palettes/00C484.bin"  ; was: byte_C484
ViblackPostBattleScrollPaletteCommand:  binclude "data/palettes/00C4A4.bin"  ; was: byte_C4A4
Boss_BackStringerPaletteCommand:        binclude "data/palettes/00C4BE.bin"  ; was: byte_C4BE
Boss_Epsilon1PaletteCommands:           binclude "data/palettes/00C4DE.bin"  ; was: byte_C4DE
                                        ; Stage_LoadStage17Palettes+C   o
Boss_JampanPaletteCommand:  binclude "data/palettes/00C55E.bin"  ; was: byte_C55E
                                        ; Boss_JampanReinitializePostDefeatObjectsState+6   o
Boss_DestroyerMk2PaletteCommand:    binclude "data/palettes/00C57E.bin"  ; was: byte_C57E
Boss_BugmaxPaletteCommand:          binclude "data/palettes/00C59E.bin"  ; was: byte_C59E
Boss_LambdaBunnyPaletteCommand:     binclude "data/palettes/00C5BE.bin"  ; was: byte_C5BE
                                        ; Selected by the dormant Stage 18 late-phase path
EntityType3F0PaletteCommand:    binclude "data/palettes/00C5DE.bin"  ; was: byte_C5DE
                                        ; Selected by the dormant Stage 18 late-phase path
EntityType3F4PaletteCommands:   binclude "data/palettes/00C5FE.bin"  ; was: byte_C5FE
                                        ; Selected by the dormant Stage 18 late-phase path
EntityType3FCPaletteCommands:   binclude "data/palettes/00C63E.bin"  ; was: byte_C63E
                                        ; Identity beyond entity type $3FC is unproven
SevenForceValkiriePaletteCommand:       binclude "data/palettes/00C67E.bin"  ; was: byte_C67E
SevenForceMedusaPaletteCommand:         binclude "data/palettes/00C69E.bin"  ; was: byte_C69E
SevenForceSylpheedPaletteCommand:       binclude "data/palettes/00C6BE.bin"  ; was: byte_C6BE
SevenForceArtemisPaletteCommand:        binclude "data/palettes/00C6DE.bin"  ; was: byte_C6DE
SevenForceSirenePaletteCommand:         binclude "data/palettes/00C6FE.bin"  ; was: byte_C6FE
SevenForceSireneTimedPaletteCommandA:   binclude "data/palettes/00C71E.bin"  ; was: byte_C71E
SevenForceSireneTimedPaletteCommandB:   binclude "data/palettes/00C73E.bin"  ; was: byte_C73E
Boss_DestroyerProtoPaletteCommand:      binclude "data/palettes/00C75E.bin"  ; was: byte_C75E
Boss_ShieldViperPaletteCommand:         binclude "data/palettes/00C77E.bin"  ; was: byte_C77E
Boss_WolfGaropaPaletteCommand:          binclude "data/palettes/00C79E.bin"  ; was: byte_C79E
Boss_MissirayPaletteCommand:            binclude "data/palettes/00C7BE.bin"  ; was: byte_C7BE
Boss_ZLeoPaletteCommands:               binclude "data/palettes/00C7DE.bin"  ; was: byte_C7DE
SevenForceIntroPaletteCommand:          binclude "data/palettes/00C81E.bin"  ; was: byte_C81E

; Main stage dispatcher jump table
